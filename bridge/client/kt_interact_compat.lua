-- =============================================
-- BRIDGE CLIENT : kt_context ↔ kt_interact
-- =============================================
--
-- Ce fichier est chargé par kt_context UNIQUEMENT.
-- Il permet à kt_context d'afficher et de déclencher
-- les interactions kt_interact via son menu contextuel.
--
-- Fonctionnalités :
--   • Affichage des interactions kt_interact dans le menu
--     contextuel kt_context (clic entité / clic vide)
--   • Déclenchement via TriggerServerEvent kt_interact
--   • Intégration dans BuildEntityMenu et OpenGeneralContextMenu
--   • Filtrage par distance, type, conditions ACE
--   • Menu "Interactions disponibles" dans le menu radial
-- =============================================

local INTERACT_RESOURCE = 'kt_interact'

-- ─── Helper disponibilité ────────────────────────────────────────────────────
local function interactAvailable()
    return GetResourceState(INTERACT_RESOURCE) == 'started'
end

-- ─── Cache des interactions (synchronisé depuis kt_interact) ─────────────────
-- On écoute kt_interact_data:loadAll et les events live pour maintenir
-- une copie locale sans requête SQL supplémentaire.

local _interactCache = {}   -- [id] = interaction

local function _cacheSet(interaction)
    if interaction and interaction.id then
        _interactCache[interaction.id] = interaction
    end
end

local function _cacheRemove(id)
    _interactCache[id] = nil
end

local function _cacheClear()
    _interactCache = {}
end

-- Écoute les events de kt_interact pour maintenir le cache à jour
AddEventHandler('kt_interact_data:loadAll', function(interactions)
    _cacheClear()
    if type(interactions) ~= 'table' then return end
    for _, data in ipairs(interactions) do
        _cacheSet(data)
    end
    print(('[KT Bridge] Cache interactions synchronisé : %d entrée(s)'):format(
        (function() local n=0; for _ in pairs(_interactCache) do n=n+1 end; return n end)()
    ))
end)

AddEventHandler('kt_interact_data:added', function(data)
    _cacheSet(data)
end)

AddEventHandler('kt_interact_data:updated', function(data)
    _cacheSet(data)
end)

AddEventHandler('kt_interact_data:removed', function(id)
    _cacheRemove(id)
end)

-- ─── Helpers coords ──────────────────────────────────────────────────────────
local function _toV3(c)
    if not c then return nil end
    if type(c) == 'table' and c.x then
        return vector3(c.x, c.y, c.z)
    end
    return nil
end

local function _distanceTo(coords)
    if not coords then return math.huge end
    local ped = GetEntityCoords(PlayerPedId())
    return #(ped - coords)
end

-- ─── Filtrage des interactions selon le contexte ──────────────────────────────
-- Retourne les interactions pertinentes pour un contexte donné.
-- context = { type = 'entity'|'general'|'vehicle'|'ped', entity = handle, coords = vector3 }

local function _getRelevantInteractions(context)
    if not interactAvailable() then return {} end

    local result    = {}
    local myCoords  = GetEntityCoords(PlayerPedId())
    local maxDist   = 20.0  -- Distance max pour afficher une interaction

    for id, interaction in pairs(_interactCache) do
        local relevant = false
        local itype    = interaction.type

        -- ── Zone sphere / box / poly ─────────────────────────────────────
        if itype == 'zone' then
            local icoords = _toV3(interaction.coords)
            if icoords then
                local dist = #(myCoords - icoords)
                local radius = interaction.radius or 1.5
                -- Affiche si on est dans 2× le rayon (pour anticiper)
                if dist <= math.max(radius * 2, interaction.distance or 3.0) then
                    relevant = true
                    interaction._dist = dist
                end
            end

        -- ── Modèle ────────────────────────────────────────────────────────
        elseif itype == 'model' then
            if context.entity and context.entity ~= 0 then
                local entityModel = GetEntityModel(context.entity)
                local interactHash = interaction.model_hash
                -- Compare hash (string hex ou number)
                local interactNum = tonumber(interactHash) or
                    (type(interactHash) == 'string' and
                     tonumber(interactHash, 16)) or 0
                if entityModel == interactNum then
                    relevant = true
                end
            end

        -- ── Entité réseau ─────────────────────────────────────────────────
        elseif itype == 'entity' then
            if context.entity and interaction.net_id then
                if NetworkGetEntityIsNetworked(context.entity) then
                    local netId = NetworkGetNetworkIdFromEntity(context.entity)
                    if netId == interaction.net_id then
                        relevant = true
                    end
                end
            end

        -- ── Globaux ───────────────────────────────────────────────────────
        elseif itype == 'globalPed' then
            if context.type == 'ped' then relevant = true end

        elseif itype == 'globalVehicle' then
            if context.type == 'vehicle' then relevant = true end

        elseif itype == 'globalObject' then
            if context.type == 'object' then relevant = true end

        elseif itype == 'globalPlayer' then
            if context.type == 'ped' and context.isPlayer then relevant = true end
        end

        -- ── Vérification distance générale ───────────────────────────────
        if relevant then
            local dist = interaction._dist
            if not dist then
                -- Pour les non-zones, vérifie la distance interaction.distance
                local targetDist = _distanceTo(_toV3(interaction.coords))
                dist = targetDist
                interaction._dist = dist
            end

            if dist > (interaction.distance or 3.0) + maxDist then
                relevant = false
            end
        end

        if relevant then
            result[#result + 1] = interaction
        end
    end

    -- Tri par distance
    table.sort(result, function(a, b)
        return (a._dist or 0) < (b._dist or 0)
    end)

    return result
end

-- ─── Construction des items menu depuis les interactions ──────────────────────
local function _buildMenuItemsFromInteractions(interactions)
    if not interactions or #interactions == 0 then return nil end

    local items = {}

    for _, interaction in ipairs(interactions) do
        local dist = interaction._dist or 0
        local label = interaction.label or 'Interaction'

        -- Icône : conversion fas fa-xxx → nom Lucide (approximatif)
        -- kt_context utilise Lucide, kt_interact utilise FontAwesome
        -- On mappe les icônes courantes
        local iconMap = {
            ['fas fa-hand-pointer'] = 'HandPointing',
            ['fas fa-box']          = 'Package',
            ['fas fa-car']          = 'Car',
            ['fas fa-person']       = 'User',
            ['fas fa-door-open']    = 'DoorOpen',
            ['fas fa-key']          = 'Key',
            ['fas fa-shopping-cart']= 'ShoppingCart',
            ['fas fa-wrench']       = 'Wrench',
            ['fas fa-bolt']         = 'Zap',
            ['fas fa-star']         = 'Star',
            ['fas fa-heart']        = 'Heart',
            ['fas fa-trash']        = 'Trash2',
            ['fas fa-edit']         = 'Edit',
            ['fas fa-info']         = 'Info',
            ['fas fa-cog']          = 'Settings',
            ['fas fa-map-marker']   = 'MapPin',
            ['fas fa-user']         = 'User',
            ['fas fa-users']        = 'Users',
            ['fas fa-building']     = 'Building',
            ['fas fa-phone']        = 'Phone',
            ['fas fa-envelope']     = 'Mail',
            ['fas fa-lock']         = 'Lock',
            ['fas fa-unlock']       = 'LockOpen',
            ['fas fa-money-bill']   = 'Banknote',
            ['fas fa-tools']        = 'Wrench',
            ['fas fa-clipboard']    = 'Clipboard',
            ['fas fa-suitcase']     = 'Briefcase',
            ['fas fa-hospital']     = 'Cross',
            ['fas fa-ambulance']    = 'Truck',
            ['fas fa-shield']       = 'Shield',
        }

        local lucideIcon = 'Zap'  -- fallback
        if interaction.icon then
            lucideIcon = iconMap[interaction.icon] or 'Zap'
        end

        -- Description avec distance
        local desc = ('%.1fm'):format(dist)
        if interaction.zone_type then
            desc = interaction.zone_type .. ' · ' .. desc
        end

        -- Badge selon le type d'event
        local badge = nil
        local badgeColor = nil
        if interaction.event_type == 'serverEvent' then
            badge = 'srv'
            badgeColor = '#6366f1'
        elseif interaction.event_type == 'command' then
            badge = 'cmd'
            badgeColor = '#f59e0b'
        elseif interaction.event_type == 'export' then
            badge = 'exp'
            badgeColor = '#10b981'
        end

        -- Couleur depuis icon_color si disponible
        local color = interaction.icon_color or nil

        local item = {
            id          = 'ki_' .. interaction.id,
            label       = label,
            icon        = lucideIcon,
            description = desc,
            badge       = badge,
            badgeColor  = badgeColor,
            color       = color,
            -- Stocke l'ID kt_interact pour le déclenchement
            _interactId = interaction.id,
        }

        items[#items + 1] = item
    end

    return items
end

-- ─── Déclenchement d'une interaction kt_interact ─────────────────────────────
local function _triggerInteraction(interactionId)
    if not interactAvailable() then
        ShowNotification('kt_interact non disponible', 'error')
        return
    end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    TriggerServerEvent('kt_interact_data:triggerEvent', interactionId, {
        x = coords.x,
        y = coords.y,
        z = coords.z,
    })

    print(('[KT Bridge] Trigger interaction kt_interact: %s'):format(interactionId))
end

-- ─── Handler d'action menu pour les items kt_interact ────────────────────────
-- Intercepte les actions menuAction dont l'id commence par 'ki_'
AddEventHandler('kt_context:action', function(id, data)
    if not id then return end
    local interactId = id:match('^ki_(.+)$')
    if interactId then
        _triggerInteraction(interactId)
    end
end)

-- ─── Réponse aux refus kt_interact (affiche dans kt_context) ─────────────────
RegisterNetEvent('kt_interact:triggerDenied', function(data)
    if not data then return end

    local reason = data.reason
    local msg    = 'Action refusée'

    if reason == 'cooldown' then
        local secs = data.remaining or 0
        if secs >= 60 then
            msg = ('Disponible dans %dm %ds'):format(math.floor(secs/60), secs%60)
        else
            msg = ('Disponible dans %ds'):format(secs)
        end
        ShowNotification(msg, 'warning')

    elseif reason == 'condition_failed' then
        local cond = data.condition or ''
        if cond:find('min_job_grade:') then
            msg = 'Grade insuffisant pour cette action'
        elseif cond:find('group_required:') then
            msg = 'Groupe requis pour cette action'
        elseif cond:find('item_required:') then
            msg = 'Item manquant dans votre inventaire'
        elseif cond:find('time_range:') then
            msg = 'Action indisponible à cette heure'
        elseif cond:find('server_flag:') then
            msg = 'Interaction temporairement désactivée'
        elseif cond:find('max_uses_total:') then
            msg = 'Limite globale d\'utilisations atteinte'
        elseif cond:find('max_uses_player:') then
            msg = 'Vous avez atteint votre limite d\'utilisations'
        else
            msg = 'Condition non remplie'
        end
        ShowNotification(msg, 'error')

    elseif reason == 'access_denied' then
        ShowNotification('Accès refusé', 'error')

    else
        ShowNotification(msg, 'warning')
    end
end)

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Retourne les items de menu kt_interact pour un contexte donné
-- context = { type, entity, coords, isPlayer }
function KtInteract_GetMenuItems(context)
    if not interactAvailable() then return nil end
    local interactions = _getRelevantInteractions(context)
    if #interactions == 0 then return nil end
    return _buildMenuItemsFromInteractions(interactions)
end

-- Retourne tous les items pour le menu général (zones à portée)
function KtInteract_GetGeneralMenuItems()
    local myCoords = GetEntityCoords(PlayerPedId())
    return KtInteract_GetMenuItems({
        type   = 'general',
        coords = myCoords,
    })
end

-- Déclenche manuellement une interaction par son ID kt_interact
function KtInteract_Trigger(interactionId)
    _triggerInteraction(interactionId)
end

-- Compte des interactions en cache
function KtInteract_GetCacheCount()
    local n = 0
    for _ in pairs(_interactCache) do n = n + 1 end
    return n
end

-- ─── Exports ─────────────────────────────────────────────────────────────────
exports('KtInteract_GetMenuItems',        KtInteract_GetMenuItems)
exports('KtInteract_GetGeneralMenuItems', KtInteract_GetGeneralMenuItems)
exports('KtInteract_Trigger',             KtInteract_Trigger)
exports('KtInteract_GetCacheCount',       KtInteract_GetCacheCount)

print(('[KT Bridge] kt_interact_compat client chargé (kt_interact actif: %s)'):format(
    tostring(interactAvailable())
))
