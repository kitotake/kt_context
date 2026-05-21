-- =============================================
-- MODULE : MENUS ENTITÉS — v3.1 (fixed)
--
-- FIXES :
--   • _pendingActions déclaré local (plus de global implicite)
--   • Cooldown NPC (Config.Limits.NpcCooldown)
--   • Vérification distance portée PNJ (Config.Limits.NpcMaxDistance)
--   • Cooldown animations (Config.Limits.AnimCooldown)
--   • Bloc animations en véhicule (Config.Limits.AnimBlockInVehicle)
--   • Confirmation avant suppression d'entité admin
-- =============================================

-- FIX: local — plus de pollution globale
local _pendingActions = {}

local function registerAction(id, fn)
    _pendingActions[id] = fn
    return id
end

local function clearPendingActions()
    _pendingActions = {}
end

-- FIX: exposé proprement pour main.lua
function ExecutePendingAction(id)
    local fn = _pendingActions[id]
    if fn then fn(); return true end
    return false
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function _checkNpcDistance(npcEntity)
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(npcEntity))
    if dist > (Config.Limits.NpcMaxDistance or 3.0) then
        ShowNotification(L('npc_too_far'), 'warning')
        return false
    end
    return true
end

local function _checkAnimCooldown()
    if HasCooldown('anim_global') then
        ShowNotification(L('cooldown_wait'), 'warning')
        return false
    end
    if Config.Limits.AnimBlockInVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
        ShowNotification(L('anim_vehicle'), 'warning')
        return false
    end
    return true
end

local function _playAnim(dict, clip, flags)
    if not _checkAnimCooldown() then return end
    SetCooldown('anim_global', Config.Limits.AnimCooldown or 2000)
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10); t = t + 10
        if t > 5000 then return end
    end
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, flags or 0, 0, false, false, false)
end

-- ─── Véhicule ─────────────────────────────────────────────────────────────────
function BuildVehicleMenu(veh, locked, isAdmin)
    clearPendingActions()
    local items = {}

    local engHealth  = math.floor(GetVehicleEngineHealth(veh)  / 10)
    local bodyHealth = math.floor(GetVehicleBodyHealth(veh)    / 10)
    local fuel       = math.floor(GetVehicleFuelLevel(veh))
    local plateText  = GetVehicleNumberPlateText(veh)

    table.insert(items, {
        id          = 'veh_info',
        label       = 'Informations',
        icon        = 'Info',
        disabled    = true,
        description = ('Moteur %d%% | Carrosserie %d%% | Essence %d%%'):format(engHealth, bodyHealth, fuel),
    })

    if plateText and #plateText > 0 then
        table.insert(items, {
            id       = 'veh_plate',
            label    = 'Plaque : ' .. plateText,
            icon     = 'SquareDot',
            disabled = true,
        })
    end

    table.insert(items, { id = '_div_veh1', divider = true, label = '' })
    table.insert(items, {
        id    = 'veh_lock',
        label = locked and 'Déverrouiller' or 'Verrouiller',
        icon  = locked and 'LockOpen' or 'Lock',
    })

    local ped      = PlayerPedId()
    local isDriver = GetPedInVehicleSeat(veh, -1) == ped
    local engineOn = GetIsVehicleEngineRunning(veh)

    table.insert(items, {
        id       = 'veh_engine',
        label    = engineOn and 'Éteindre le moteur' or 'Allumer le moteur',
        icon     = 'Zap',
        disabled = not isDriver,
    })

    registerAction('veh_lights', function()
        local v = GetVehiclePedIsIn(PlayerPedId(), false)
        if v ~= 0 then
            local on, _ = GetVehicleLightsState(v)
            SetVehicleLights(v, on == 1 and 0 or 2)
            ShowNotification(on == 1 and 'Lumières éteintes' or 'Lumières allumées', 'info')
        end
    end)
    table.insert(items, { id = 'veh_lights', label = 'Lumières', icon = 'Lightbulb' })

    table.insert(items, {
        id      = 'veh_doors',
        label   = 'Portes',
        icon    = 'DoorOpen',
        submenu = {
            { id = 'door_fl',        label = 'Avant gauche',   icon = 'SquareDot'  },
            { id = 'door_fr',        label = 'Avant droite',   icon = 'SquareDot'  },
            { id = 'door_rl',        label = 'Arrière gauche', icon = 'SquareDot'  },
            { id = 'door_rr',        label = 'Arrière droite', icon = 'SquareDot'  },
            { id = 'door_hood',      label = 'Capot',          icon = 'SquareDot'  },
            { id = 'door_trunk',     label = 'Coffre',         icon = 'SquareDot'  },
            { id = '_div_doors',     divider = true, label = '' },
            { id = 'door_all_open',  label = 'Toutes ouvrir',  icon = 'DoorOpen'   },
            { id = 'door_all_close', label = 'Toutes fermer',  icon = 'DoorClosed' },
        },
    })

    table.insert(items, {
        id      = 'veh_windows',
        label   = 'Vitres',
        icon    = 'Maximize2',
        submenu = {
            { id = 'win_down', label = 'Toutes descendre', icon = 'ArrowDown' },
            { id = 'win_up',   label = 'Toutes monter',    icon = 'ArrowUp'   },
        },
    })

    return items
end

-- ─── PNJ ──────────────────────────────────────────────────────────────────────
function BuildNpcMenu(npcEntity, isAdmin)
    clearPendingActions()
    local hp   = math.max(0, math.floor(GetEntityHealth(npcEntity) - 100))
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(npcEntity))

    registerAction('npc_drag', function()
        if HasCooldown('npc_interact') then ShowNotification(L('cooldown_wait'), 'warning'); return end
        if not _checkNpcDistance(npcEntity) then return end
        SetCooldown('npc_interact', Config.Limits.NpcCooldown or 5000)
        ShowNotification('🫳 Vous traînez le PNJ', 'info')
    end)

    registerAction('npc_interact', function()
        if HasCooldown('npc_interact') then ShowNotification(L('cooldown_wait'), 'warning'); return end
        if not _checkNpcDistance(npcEntity) then return end
        SetCooldown('npc_interact', Config.Limits.NpcCooldown or 5000)
        ShowNotification('💬 Interaction avec le PNJ', 'info')
    end)

    return {
        {
            id          = 'npc_info',
            label       = 'PNJ',
            icon        = 'Bot',
            disabled    = true,
            description = ('Santé : %d%%  |  Portée : %.1fm'):format(hp, dist),
        },
        { id = '_div_npc1', divider = true, label = '' },
        { id = 'npc_drag',     label = 'Traîner',   icon = 'Hand',          description = 'Cooldown 5s' },
        { id = 'npc_interact', label = 'Interagir', icon = 'MessageCircle', description = 'Cooldown 5s' },
    }
end

-- ─── Joueur ───────────────────────────────────────────────────────────────────
function BuildPlayerMenu(serverId, name, isAdmin)
    clearPendingActions()

    registerAction('pl_tp_to', function()
        if not isAdmin then ShowNotification(L('access_denied'), 'error'); return end
        local playerId = GetPlayerFromServerId(serverId)
        if playerId ~= -1 then
            local c = GetEntityCoords(GetPlayerPed(playerId))
            SetEntityCoords(PlayerPedId(), c.x + 1.5, c.y, c.z)
            ShowNotification('Téléporté vers ' .. name, 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'tp_to_player', serverId, 'TP to player')
        else
            ShowNotification('Joueur introuvable', 'error')
        end
    end)

    registerAction('pl_wave', function()
        _playAnim('gestures@m@standing@casual', 'gesture_hello', 0)
    end)

    return {
        {
            id          = 'pl_info',
            label       = name,
            icon        = 'User',
            disabled    = true,
            description = ('ID Serveur : %d'):format(serverId),
        },
        { id = '_div_pl1', divider = true, label = '' },
        { id = 'pl_trade', label = 'Proposer un échange', icon = 'Handshake' },
        {
            id      = 'pl_money',
            label   = "Donner de l'argent",
            icon    = 'Banknote',
            submenu = {
                { id = 'give_50',     label = 'Donner 50$',     icon = 'DollarSign' },
                { id = 'give_100',    label = 'Donner 100$',    icon = 'DollarSign' },
                { id = 'give_500',    label = 'Donner 500$',    icon = 'DollarSign' },
                { id = 'give_custom', label = 'Montant libre…', icon = 'PenLine'    },
            },
        },
        {
            id      = 'pl_emotes',
            label   = 'Interactions sociales',
            icon    = 'Smile',
            submenu = {
                { id = 'pl_wave',      label = 'Saluer (cooldown 2s)',      icon = 'Hand'      },
                { id = 'pl_handshake', label = 'Serrer la main (cooldown)', icon = 'Handshake' },
                { id = 'pl_hug',       label = 'Câlin (cooldown)',          icon = 'Heart'     },
            },
        },
    }
end

-- ─── Objet / Prop ─────────────────────────────────────────────────────────────
function BuildPropMenu(prop, isAdmin)
    clearPendingActions()
    local heading  = GetEntityHeading(prop)
    local coords   = GetEntityCoords(prop)
    local myCoords = GetEntityCoords(PlayerPedId())
    local dist     = #(myCoords - coords)

    return {
        {
            id          = 'prop_info',
            label       = 'Objet',
            icon        = 'Package',
            disabled    = true,
            description = ('Heading : %.1f°  |  Distance : %.1fm'):format(heading, dist),
        },
        { id = '_div_prop1', divider = true, label = '' },
        { id = 'prop_examine', label = 'Examiner', icon = 'ScanSearch' },
        { id = 'prop_pickup',  label = 'Ramasser', icon = 'HandCoins'  },
    }
end

-- ─── Admin — menu entité ──────────────────────────────────────────────────────
function BuildAdminEntityMenu(entity, entityType)
    local items = {}

    registerAction('adm_coords_entity', function()
        ShowNotification('📍 ' .. FormatCoords(GetEntityCoords(entity)), 'info')
    end)
    table.insert(items, { id = 'adm_coords_entity', label = 'Coordonnées', icon = 'MapPin' })

    registerAction('adm_freeze_entity', function()
        local frozen = IsEntityPositionFrozen(entity)
        FreezeEntityPosition(entity, not frozen)
        ShowNotification(frozen and 'Entité dégelée' or 'Entité gelée', 'info')
        TriggerServerEvent('kt_context:logAdminAction', 'freeze_entity', nil, frozen and 'unfreeze' or 'freeze')
    end)
    table.insert(items, { id = 'adm_freeze_entity', label = 'Geler / Dégeler', icon = 'Snowflake' })

    registerAction('adm_delete_entity', function()
        if Config.Limits.AdminConfirmDelete then
            local sw, sh = GetActiveScreenResolution()
            OpenContextMenu(sw / 2, sh / 2, {
                {
                    id          = 'adm_delete_confirm',
                    label       = '⚠️ Confirmer la suppression',
                    icon        = 'Trash2',
                    variant     = 'danger',
                    description = 'Cette action est irréversible',
                },
                { id = 'adm_delete_cancel', label = 'Annuler', icon = 'X' },
            }, '🗑️ Confirmation')

            _pendingActions['adm_delete_confirm'] = function()
                if DoesEntityExist(entity) then
                    SetEntityAsMissionEntity(entity, true, true)
                    DeleteEntity(entity)
                    ShowNotification('Entité supprimée', 'success')
                    TriggerServerEvent('kt_context:logAdminAction', 'delete_entity', nil, 'Delete entity')
                end
            end
            _pendingActions['adm_delete_cancel'] = function()
                ShowNotification('Suppression annulée', 'info')
            end
        else
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
            ShowNotification('Entité supprimée', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'delete_entity', nil, 'Delete entity')
        end
    end)
    table.insert(items, {
        id          = 'adm_delete_entity',
        label       = 'Supprimer',
        icon        = 'Trash2',
        variant     = 'danger',
        description = Config.Limits.AdminConfirmDelete and 'Demande confirmation' or nil,
    })

    if entityType == 2 then
        table.insert(items, { id = '_div_adm_veh', divider = true, label = '' })
        table.insert(items, { id = 'adm_repair', label = 'Réparer',           icon = 'Wrench', variant = 'success' })
        table.insert(items, { id = 'adm_refuel', label = 'Remplir réservoir', icon = 'Fuel'   })

        registerAction('adm_copy_plate', function()
            local plate = GetVehicleNumberPlateText(entity)
            ShowNotification('Plaque : ' .. (plate or '?'), 'info')
        end)
        table.insert(items, { id = 'adm_copy_plate', label = 'Copier la plaque', icon = 'ClipboardCopy' })
    end

    if entityType == 1 and IsPedAPlayer(entity) then
        local localId = NetworkGetPlayerIndexFromPed(entity)
        if localId ~= -1 then
            local serverId = GetPlayerServerId(localId)
            table.insert(items, { id = '_div_adm_pl', divider = true, label = '' })

            registerAction('adm_tp_to_player', function()
                local c = GetEntityCoords(entity)
                SetEntityCoords(PlayerPedId(), c.x + 1.5, c.y, c.z)
                ShowNotification('Téléporté', 'success')
                TriggerServerEvent('kt_context:logAdminAction', 'tp_to_player', serverId, 'TP to player')
            end)
            table.insert(items, { id = 'adm_tp_to_player', label = 'TP vers ce joueur', icon = 'ArrowRight' })

            if IsPlayerAdmin() then
                registerAction('adm_kick_player', function()
                    local sw, sh = GetActiveScreenResolution()
                    OpenContextMenu(sw / 2, sh / 2, {
                        {
                            id          = 'adm_kick_confirm',
                            label       = "⚠️ Confirmer l'expulsion",
                            icon        = 'UserX',
                            variant     = 'danger',
                            description = ('Joueur ID: %d'):format(serverId),
                        },
                        { id = 'adm_kick_cancel', label = 'Annuler', icon = 'X' },
                    }, '👢 Expulsion')

                    _pendingActions['adm_kick_confirm'] = function()
                        TriggerServerEvent('kt_context:admin:kick', serverId, 'Expulsé par un administrateur')
                    end
                    _pendingActions['adm_kick_cancel'] = function()
                        ShowNotification('Expulsion annulée', 'info')
                    end
                end)
                table.insert(items, {
                    id         = 'adm_kick_player',
                    label      = 'Expulser',
                    icon       = 'UserX',
                    variant    = 'danger',
                    badge      = 'admin',
                    badgeColor = '#ef4444',
                })
            end
        end
    end

    return items
end