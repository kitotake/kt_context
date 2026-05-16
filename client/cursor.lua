-- =============================================
-- SYSTÈME DE CURSEUR (ALT GAUCHE)
-- =============================================

local CURSOR_KEY   = Config and Config.CursorKey or 19
local CURSOR_SPEED = 0.002

local cursorActive    = false
local cursorX, cursorY = 0.5, 0.5

function IsCursorActive()
    return cursorActive
end

-- ─── Thread principal curseur ────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local sleep = 100

        if IsControlPressed(0, CURSOR_KEY) and not IsMenuOpen() then
            sleep = 0

            if not cursorActive then
                cursorActive = true
                SetNuiFocus(false, false)
                SendNUIMessage({ type = 'cursorShow', data = { visible = true } })
            end

            DisableControlAction(0, 1,   true)
            DisableControlAction(0, 2,   true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18,  true)
            DisableControlAction(0, 24,  true)
            DisableControlAction(0, 25,  true)
            DisableControlAction(0, 68,  true)
            DisableControlAction(0, 69,  true)

            local dx = GetDisabledControlNormal(0, 239)
            local dy = GetDisabledControlNormal(0, 240)
            cursorX = math.min(math.max(cursorX + dx * CURSOR_SPEED, 0.0), 1.0)
            cursorY = math.min(math.max(cursorY + dy * CURSOR_SPEED, 0.0), 1.0)

            SendNUIMessage({
                type = 'cursorMove',
                data = { x = cursorX, y = cursorY }
            })

            if IsDisabledControlJustPressed(0, 24) then
                HandleCursorClick(cursorX, cursorY)
            end

        elseif cursorActive then
            cursorActive = false
            SendNUIMessage({ type = 'cursorShow', data = { visible = false } })
        end

        Wait(sleep)
    end
end)

-- ─── Gestion du clic curseur ────────────────────────────────────────────────
function HandleCursorClick(nx, ny)
    local sw, sh = GetActiveScreenResolution()
    local camCoords = GetGameplayCamCoords()
    local camRot    = GetGameplayCamRot(2)
    local camFov    = GetGameplayCamFov()

    local halfFovH = math.rad(camFov / 2)
    local halfFovV = math.rad(camFov * (sh / sw) / 2)

    local offsetH = (nx - 0.5) * 2 * math.tan(halfFovH)
    local offsetV = (0.5 - ny) * 2 * math.tan(halfFovV)

    local fwd = RotationToDirection(camRot)

    local rx = math.rad(camRot.x)
    local rz = math.rad(camRot.z)
    local right = vector3(math.cos(rz), math.sin(rz), 0.0)
    local up    = vector3(
        -math.sin(rz) * math.sin(rx),
         math.cos(rz) * math.sin(rx),
         math.cos(rx)
    )

    local dir = vector3(
        fwd.x + right.x * offsetH + up.x * offsetV,
        fwd.y + right.y * offsetH + up.y * offsetV,
        fwd.z + right.z * offsetH + up.z * offsetV
    )
    local len = math.sqrt(dir.x^2 + dir.y^2 + dir.z^2)
    if len == 0 then return end
    dir = vector3(dir.x/len, dir.y/len, dir.z/len)

    local startCoord = camCoords
    local endCoord   = startCoord + dir * 50.0

    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        startCoord.x, startCoord.y, startCoord.z,
        endCoord.x,   endCoord.y,   endCoord.z,
        87, PlayerPedId(), 4
    )
    local _, hit, _, _, hitEntity = GetShapeTestResult(ray)

    local menuX = nx * sw
    local menuY = ny * sh

    if hit == 1 and hitEntity ~= 0 then
        local entityType = GetEntityType(hitEntity)
        OpenContextForEntity(hitEntity, entityType, menuX, menuY)
    else
        OpenGeneralContextMenu(menuX, menuY)
    end
end

-- ─── Menu selon type d'entité ─────────────────────────────────────────────────
function OpenContextForEntity(entity, entityType, x, y)
    local isAdmin   = IsPlayerAdmin()
    local adminRole = GetAdminRole()
    local items     = {}

    if entityType == 1 then
        local isPlayer = IsPedAPlayer(entity)
        if isPlayer then
            local playerName = GetPlayerName(GetPlayerFromPed(entity)) or 'Joueur'
            local serverId   = NetworkGetPlayerIndexFromPed(entity)
            items = BuildPlayerMenu(serverId, playerName, isAdmin)
        else
            items = BuildNpcMenu(entity, isAdmin)
        end
    elseif entityType == 2 then
        local locked = GetVehicleDoorLockStatus(entity) ~= 1
        items = BuildVehicleMenu(entity, locked, isAdmin)
    elseif entityType == 3 then
        items = BuildPropMenu(entity, isAdmin)
    else
        OpenGeneralContextMenu(x, y)
        return
    end

    if isAdmin and adminRole then
        table.insert(items, { id = '_div_admin', divider = true, label = '' })
        table.insert(items, {
            id         = 'admin_section',
            label      = '⚡ ' .. L('admin_options') .. ' [' .. adminRole .. ']',
            icon       = 'ShieldAlert',
            badge      = adminRole,
            badgeColor = '#f59e0b',
            submenu    = BuildAdminEntityMenu(entity, entityType),
        })
    end

    local title = GetEntityMenuTitle(entityType, entity)
    OpenContextMenu(x, y, items, title)
end

function GetEntityMenuTitle(entityType, entity)
    if entityType == 1 then
        return IsPedAPlayer(entity) and '👤 Joueur' or '🤖 PNJ'
    elseif entityType == 2 then
        return '🚗 Véhicule'
    elseif entityType == 3 then
        return '📦 Objet'
    end
    return '🌍 Interaction'
end

-- ─── Constructeurs de menus ───────────────────────────────────────────────────
function BuildPlayerMenu(serverId, playerName, isAdmin)
    return {
        { id = 'player_info',  label = "Voir l'identité",    icon = 'User',      description = playerName },
        { id = 'player_trade', label = 'Proposer un échange', icon = 'Handshake' },
        {
            id    = 'player_money',
            label = 'Transactions',
            icon  = 'Banknote',
            submenu = {
                { id = 'give_50',     label = 'Donner 50$',    icon = 'DollarSign' },
                { id = 'give_100',    label = 'Donner 100$',   icon = 'DollarSign' },
                { id = 'give_500',    label = 'Donner 500$',   icon = 'DollarSign' },
                { id = 'give_custom', label = 'Montant libre…', icon = 'PenLine'   },
            }
        },
        {
            id    = 'player_emotes',
            label = 'Interactions sociales',
            icon  = 'Smile',
            submenu = {
                { id = 'wave',      label = 'Saluer',             icon = 'Hand'  },
                { id = 'hug',       label = 'Câlin',              icon = 'Heart' },
                { id = 'high_five', label = 'Taper dans la main', icon = 'Star'  },
            }
        },
    }
end

function BuildNpcMenu(entity, isAdmin)
    return {
        { id = 'npc_talk',   label = 'Parler',  icon = 'MessageCircle' },
        { id = 'npc_follow', label = 'Suivre',  icon = 'MapPin'        },
        { id = 'npc_stop',   label = 'Arrêter', icon = 'StopCircle',   color = '#ef4444' },
    }
end

function BuildVehicleMenu(entity, locked, isAdmin)
    local engineOn   = GetIsVehicleEngineRunning(entity)
    local engHealth  = math.floor(GetVehicleEngineHealth(entity) / 10)
    local bodyHealth = math.floor(GetVehicleBodyHealth(entity) / 10)
    return {
        {
            id    = 'veh_lock',
            label = locked and 'Déverrouiller' or 'Verrouiller',
            icon  = locked and 'LockOpen' or 'Lock',
        },
        {
            id    = 'veh_engine',
            label = engineOn and 'Éteindre moteur' or 'Allumer moteur',
            icon  = 'Zap',
        },
        {
            id    = 'veh_doors',
            label = 'Portes',
            icon  = 'DoorOpen',
            submenu = {
                { id = 'door_fl',    label = 'Avant gauche',   icon = 'SquareDot' },
                { id = 'door_fr',    label = 'Avant droite',   icon = 'SquareDot' },
                { id = 'door_rl',    label = 'Arrière gauche', icon = 'SquareDot' },
                { id = 'door_rr',    label = 'Arrière droite', icon = 'SquareDot' },
                { id = 'door_hood',  label = 'Capot',          icon = 'SquareDot' },
                { id = 'door_trunk', label = 'Coffre',         icon = 'SquareDot' },
            }
        },
        {
            id    = 'veh_windows',
            label = 'Vitres',
            icon  = 'Maximize2',
            submenu = {
                { id = 'win_up',   label = 'Monter toutes',    icon = 'ArrowUp'   },
                { id = 'win_down', label = 'Descendre toutes', icon = 'ArrowDown' },
            }
        },
        {
            id          = 'veh_info',
            label       = 'Informations',
            icon        = 'Info',
            description = ('Moteur: %d%% | Carrosserie: %d%%'):format(engHealth, bodyHealth),
            disabled    = true,
        },
    }
end

function BuildPropMenu(entity, isAdmin)
    return {
        { id = 'prop_info', label = 'Inspecter', icon = 'Search'  },
        { id = 'prop_use',  label = 'Utiliser',  icon = 'Zap'     },
        { id = 'prop_grab', label = 'Prendre',   icon = 'Package' },
    }
end

function BuildAdminEntityMenu(entity, entityType)
    local items = {
        { id = 'adm_coords', label = 'Coordonnées', icon = 'MapPin',
          description = FormatCoords(GetEntityCoords(entity)), disabled = true },
        { id = 'adm_delete', label = 'Supprimer',       icon = 'Trash2',  color = '#ef4444' },
        { id = 'adm_freeze', label = 'Geler / Dégeler', icon = 'Pause'   },
    }
    if entityType == 2 then
        table.insert(items, { id = 'adm_repair',  label = 'Réparer',            icon = 'Wrench', color = '#10b981' })
        table.insert(items, { id = 'adm_refuel',  label = 'Remplir le réservoir', icon = 'Fuel'   })
    end
    return items
end

-- ─── Menu général (clic dans le vide) ────────────────────────────────────────
function OpenGeneralContextMenu(x, y)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local items  = {}

    local veh, vehDist = GetClosestVehicle(coords)
    if veh ~= -1 and vehDist < Config.InteractionDistance then
        table.insert(items, {
            id    = 'nearby_vehicle',
            label = ('Véhicule (%.1fm)'):format(vehDist),
            icon  = 'Car',
            submenu = BuildVehicleMenu(veh, GetVehicleDoorLockStatus(veh) ~= 1, IsPlayerAdmin()),
        })
    end

    table.insert(items, {
        id    = 'player_actions',
        label = 'Actions joueur',
        icon  = 'User2',
        submenu = {
            { id = 'handsup',  label = "Mains en l'air", icon = 'HandMetal'  },
            { id = 'sit',      label = "S'asseoir",       icon = 'Armchair'   },
            { id = 'lay',      label = "S'allonger",      icon = 'BedDouble'  },
            { id = 'dance',    label = 'Danser',          icon = 'Music'      },
            { id = 'stopanim', label = 'Arrêter anim',    icon = 'StopCircle' },
        }
    })

    table.insert(items, { id = 'inventory', label = 'Inventaire', icon = 'Backpack', description = 'Voir mes objets' })
    table.insert(items, { id = 'phone',     label = 'Téléphone',  icon = 'Phone' })

    if IsPlayerAdmin() then
        local role = GetAdminRole()
        table.insert(items, { id = '_div', divider = true, label = '' })
        table.insert(items, {
            id         = 'admin_general',
            label      = '⚡ Options Admin',
            icon       = 'ShieldAlert',
            badge      = role,
            badgeColor = '#f59e0b',
            submenu = {
                { id = 'adm_coords_self', label = 'Mes coordonnées', icon = 'MapPin',
                  description = FormatCoords(coords), disabled = true },
                { id = 'adm_tp_waypoint', label = 'TP Waypoint',      icon = 'Navigation' },
                { id = 'adm_god',         label = 'God Mode',         icon = 'Shield'     },
                { id = 'adm_invisible',   label = 'Invisible',        icon = 'EyeOff'     },
                { id = 'adm_heal_self',   label = 'Se soigner',       icon = 'Heart',   color = '#10b981' },
                { id = 'adm_armor_self',  label = 'Armure',           icon = 'ShieldCheck', color = '#3b82f6' },
                { id = 'adm_delete',      label = 'Suppr. véhicule',  icon = 'Trash2',  color = '#ef4444' },
                { id = 'adm_repair',      label = 'Réparer véhicule', icon = 'Wrench',  color = '#10b981' },
            }
        })
    end

    OpenContextMenu(x, y, items, '🌍 Interaction')
end