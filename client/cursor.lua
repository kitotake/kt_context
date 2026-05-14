-- =============================================
-- SYSTÈME DE CURSEUR (ALT GAUCHE)
-- =============================================

local cursorActive  = false
local cursorX, cursorY = 0.5, 0.5   -- Coordonnées normalisées (0..1)

-- Vitesse de déplacement du curseur (sensibilité)
local CURSOR_SPEED  = 0.002

-- Expose le statut
function IsCursorActive()
    return cursorActive
end

-- ─── Thread principal de gestion curseur ────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local sleep = 100

        -- ALT GAUCHE maintenu (control 19)
        if IsControlPressed(0, Config.CursorKey) and not IsMenuOpen() then
            sleep = 0

            if not cursorActive then
                -- Activation du curseur
                cursorActive = true
                SetNuiFocus(false, false)   -- le NUI écoute souris mais pas focus clavier
                SendNUIMessage({ type = 'cursorShow', data = { visible = true } })
            end

            -- Désactivation des contrôles gênants pendant le curseur
            DisableControlAction(0, 1,   true)   -- LookLeftRight
            DisableControlAction(0, 2,   true)   -- LookUpDown
            DisableControlAction(0, 142, true)   -- MeleeAttackAlternate
            DisableControlAction(0, 18,  true)   -- Enter
            DisableControlAction(0, 24,  true)   -- Attack
            DisableControlAction(0, 25,  true)   -- Aim
            DisableControlAction(0, 68,  true)   -- VehicleExit
            DisableControlAction(0, 69,  true)   -- Enter

            -- Déplacement du curseur via souris
            local dx = GetDisabledControlNormal(0, 239)  -- MouseX
            local dy = GetDisabledControlNormal(0, 240)  -- MouseY
            cursorX = math.min(math.max(cursorX + dx * CURSOR_SPEED, 0.0), 1.0)
            cursorY = math.min(math.max(cursorY + dy * CURSOR_SPEED, 0.0), 1.0)

            -- Mise à jour position curseur dans la NUI
            SendNUIMessage({
                type = 'cursorMove',
                data = { x = cursorX, y = cursorY }
            })

            -- Clic gauche → détection entité + ouverture menu
            if IsDisabledControlJustPressed(0, 24) then  -- Attack (clic G)
                HandleCursorClick(cursorX, cursorY)
            end

        elseif cursorActive then
            -- Désactivation du curseur (ALT relâché)
            cursorActive = false
            SendNUIMessage({ type = 'cursorShow', data = { visible = false } })
        end

        Wait(sleep)
    end
end)

-- ─── Gestion du clic curseur ────────────────────────────────────────────────
function HandleCursorClick(nx, ny)
    -- Convertir coordonnées normalisées en pixels écran
    local sw, sh = GetActiveScreenResolution()
    local screenX = nx * sw
    local screenY = ny * sh

    -- Calculer la direction du rayon depuis la caméra
    local camCoords = GetGameplayCamCoords()
    local camRot    = GetGameplayCamRot(2)
    local camFwd    = RotationToDirection(camRot)

    -- Ajustement pour le décalage curseur vs centre
    local fovH = GetGameplayCamFov()
    local fovV = fovH * (sh / sw)
    local offsetX = math.tan(math.rad(fovH / 2)) * (nx * 2 - 1)
    local offsetY = math.tan(math.rad(fovV / 2)) * (1 - ny * 2)

    -- Raycast depuis la caméra vers le monde
    local dir = vector3(
        camFwd.x + offsetX * math.cos(math.rad(camRot.z)) - offsetY * math.sin(math.rad(camRot.z)),
        camFwd.y + offsetX * math.sin(math.rad(camRot.z)) + offsetY * math.cos(math.rad(camRot.z)),
        camFwd.z + offsetY
    )
    -- Normaliser
    local len = math.sqrt(dir.x^2 + dir.y^2 + dir.z^2)
    dir = vector3(dir.x/len, dir.y/len, dir.z/len)

    local startCoord  = camCoords
    local endCoord    = startCoord + dir * 50.0

    -- Raycast (type 87 = tout sauf eau)
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        startCoord.x, startCoord.y, startCoord.z,
        endCoord.x,   endCoord.y,   endCoord.z,
        87, PlayerPedId(), 4
    )
    local retval, hit, hitCoords, surfaceNormal, hitEntity = GetShapeTestResult(ray)

    -- Calculer la position NUI du menu (pixels → ratio écran)
    local menuX = nx * sw
    local menuY = ny * sh

    if hit == 1 and hitEntity ~= 0 then
        local entityType = GetEntityType(hitEntity)  -- 1=ped, 2=vehicle, 3=object
        OpenContextForEntity(hitEntity, entityType, menuX, menuY)
    else
        -- Clic sur terrain / air → menu général
        OpenGeneralContextMenu(menuX, menuY)
    end
end

-- ─── Rotation → direction ────────────────────────────────────────────────────
function RotationToDirection(rot)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    return vector3(
        -math.sin(rz) * math.abs(math.cos(rx)),
         math.cos(rz) * math.abs(math.cos(rx)),
         math.sin(rx)
    )
end

-- ─── Menu selon type d'entité ─────────────────────────────────────────────────
function OpenContextForEntity(entity, entityType, x, y)
    local isAdmin   = IsPlayerAdmin()
    local adminRole = GetAdminRole()
    local items     = {}

    if entityType == 1 then
        -- PED
        local isPlayer = IsPedAPlayer(entity)
        if isPlayer then
            local serverId  = NetworkGetPlayerIndexFromPed(entity)
            local playerName = GetPlayerName(GetPlayerFromPed(entity)) or "Joueur"
            items = BuildPlayerMenu(serverId, playerName, isAdmin)
        else
            items = BuildNpcMenu(entity, isAdmin)
        end

    elseif entityType == 2 then
        -- VEHICLE
        local model  = GetEntityModel(entity)
        local locked = GetVehicleDoorLockStatus(entity) ~= 1
        items = BuildVehicleMenu(entity, locked, isAdmin)

    elseif entityType == 3 then
        -- OBJECT / PROP
        items = BuildPropMenu(entity, isAdmin)

    else
        OpenGeneralContextMenu(x, y)
        return
    end

    -- Injecter les options admin en bas si admin
    if isAdmin and adminRole then
        table.insert(items, { id = '_div_admin', divider = true })
        table.insert(items, {
            id       = 'admin_section',
            label    = '⚡ ' .. L('admin_options') .. ' [' .. adminRole .. ']',
            icon     = 'ShieldAlert',
            badge    = adminRole,
            badgeColor = '#f59e0b',
            submenu  = BuildAdminEntityMenu(entity, entityType),
        })
    end

    OpenContextMenu(x, y, items, GetEntityMenuTitle(entityType, entity))
end

function GetEntityMenuTitle(entityType, entity)
    if entityType == 1 then
        if IsPedAPlayer(entity) then
            return '👤 Joueur'
        end
        return '🤖 PNJ'
    elseif entityType == 2 then
        return '🚗 Véhicule'
    elseif entityType == 3 then
        return '📦 Objet'
    end
    return '🌍 Interaction'
end

-- ─── Menus par type ──────────────────────────────────────────────────────────
function BuildPlayerMenu(serverId, playerName, isAdmin)
    return {
        { id = 'player_info',  label = 'Voir l\'identité',      icon = 'User',        description = playerName },
        { id = 'player_trade', label = 'Proposer un échange',    icon = 'Handshake' },
        {
            id    = 'player_money',
            label = 'Transactions',
            icon  = 'Banknote',
            submenu = {
                { id = 'give_50',     label = 'Donner 50$',   icon = 'DollarSign' },
                { id = 'give_100',    label = 'Donner 100$',  icon = 'DollarSign' },
                { id = 'give_500',    label = 'Donner 500$',  icon = 'DollarSign' },
                { id = 'give_custom', label = 'Montant libre…',icon = 'PenLine'    },
            }
        },
        {
            id    = 'player_emotes',
            label = 'Interactions sociales',
            icon  = 'Smile',
            submenu = {
                { id = 'wave',       label = 'Saluer',            icon = 'Hand'  },
                { id = 'hug',        label = 'Câlin',             icon = 'Heart' },
                { id = 'high_five',  label = 'Taper dans la main',icon = 'Star'  },
            }
        },
    }
end

function BuildNpcMenu(entity, isAdmin)
    return {
        { id = 'npc_talk',   label = 'Parler',         icon = 'MessageCircle' },
        { id = 'npc_follow', label = 'Suivre',          icon = 'MapPin'        },
        { id = 'npc_stop',   label = 'Arrêter',         icon = 'StopCircle', color = '#ef4444' },
    }
end

function BuildVehicleMenu(entity, locked, isAdmin)
    local engineOn = GetIsVehicleEngineRunning(entity)
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
                { id = 'door_fl',   label = 'Avant gauche',   icon = 'SquareDot' },
                { id = 'door_fr',   label = 'Avant droite',   icon = 'SquareDot' },
                { id = 'door_rl',   label = 'Arrière gauche', icon = 'SquareDot' },
                { id = 'door_rr',   label = 'Arrière droite', icon = 'SquareDot' },
                { id = 'door_hood', label = 'Capot',          icon = 'SquareDot' },
                { id = 'door_trunk',label = 'Coffre',         icon = 'SquareDot' },
            }
        },
        {
            id    = 'veh_windows',
            label = 'Vitres',
            icon  = 'Maximize2',
            submenu = {
                { id = 'win_up',   label = 'Monter toutes',   icon = 'ArrowUp'   },
                { id = 'win_down', label = 'Descendre toutes',icon = 'ArrowDown' },
            }
        },
        {
            id    = 'veh_info',
            label = 'Informations',
            icon  = 'Info',
            description = string.format('Moteur: %.0f%% | Carrosserie: %.0f%%',
                GetVehicleEngineHealth(entity)/10,
                GetVehicleBodyHealth(entity)/10
            ),
        },
    }
end

function BuildPropMenu(entity, isAdmin)
    return {
        { id = 'prop_info',   label = 'Inspecter',    icon = 'Search'  },
        { id = 'prop_use',    label = 'Utiliser',     icon = 'Zap'     },
        { id = 'prop_grab',   label = 'Prendre',      icon = 'Package' },
    }
end

function BuildAdminEntityMenu(entity, entityType)
    local items = {
        { id = 'adm_coords',   label = 'Coordonnées',    icon = 'MapPin', description = FormatCoords(GetEntityCoords(entity)) },
        { id = 'adm_delete',   label = 'Supprimer',      icon = 'Trash2', color = '#ef4444' },
        { id = 'adm_freeze',   label = 'Geler / Dégeler',icon = 'Pause'  },
    }
    if entityType == 1 then
        table.insert(items, { id = 'adm_kick',   label = 'Expulser',  icon = 'UserX',    color = '#ef4444' })
        table.insert(items, { id = 'adm_ban',    label = 'Bannir',    icon = 'ShieldOff',color = '#dc2626' })
        table.insert(items, { id = 'adm_heal',   label = 'Soigner',   icon = 'Heart',    color = '#10b981' })
        table.insert(items, {
            id    = 'adm_teleport',
            label = 'Téléportation',
            icon  = 'Navigation',
            submenu = {
                { id = 'adm_tp_to',   label = 'Me TP vers lui',  icon = 'ArrowRight' },
                { id = 'adm_tp_here', label = 'TP lui vers moi', icon = 'ArrowLeft'  },
            }
        })
    elseif entityType == 2 then
        table.insert(items, { id = 'adm_repair', label = 'Réparer',   icon = 'Wrench',   color = '#10b981' })
        table.insert(items, { id = 'adm_refuel', label = 'Remplir essence', icon = 'Fuel' })
    end
    return items
end

function FormatCoords(coords)
    return string.format('X:%.1f Y:%.1f Z:%.1f', coords.x, coords.y, coords.z)
end

-- ─── Menu général (clic sol) ────────────────────────────────────────────────
function OpenGeneralContextMenu(x, y)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local items  = {}

    -- Véhicule proche ?
    local veh, vehDist = GetClosestVehicle(coords)
    if veh ~= -1 and vehDist < Config.InteractionDistance then
        table.insert(items, {
            id    = 'nearby_vehicle',
            label = string.format('Véhicule (%.1fm)', vehDist),
            icon  = 'Car',
            submenu = BuildVehicleMenu(veh, GetVehicleDoorLockStatus(veh) ~= 1, IsPlayerAdmin()),
        })
    end

    -- Actions joueur
    table.insert(items, {
        id    = 'player_actions',
        label = 'Actions joueur',
        icon  = 'User2',
        submenu = {
            { id = 'handsup',   label = 'Mains en l\'air', icon = 'HandMetal'  },
            { id = 'sit',       label = 'S\'asseoir',       icon = 'Armchair'   },
            { id = 'lay',       label = 'S\'allonger',      icon = 'BedDouble'  },
            { id = 'stopanim',  label = 'Arrêter anim',     icon = 'StopCircle' },
        }
    })

    table.insert(items, {
        id    = 'inventory',
        label = 'Inventaire',
        icon  = 'Backpack',
        description = 'Voir mes objets',
    })

    table.insert(items, {
        id    = 'phone',
        label = 'Téléphone',
        icon  = 'Phone',
    })

    -- Options admin
    if IsPlayerAdmin() then
        table.insert(items, { id = '_div', divider = true })
        table.insert(items, {
            id    = 'admin_general',
            label = '⚡ Options Admin',
            icon  = 'ShieldAlert',
            badge = GetAdminRole(),
            badgeColor = '#f59e0b',
            submenu = {
                { id = 'adm_coords_self', label = 'Mes coordonnées',    icon = 'MapPin', description = FormatCoords(coords) },
                { id = 'adm_tp_waypoint',label = 'TP Waypoint',         icon = 'Navigation' },
                { id = 'adm_noclip',     label = 'NoClip',              icon = 'Ghost'  },
                { id = 'adm_god',        label = 'God Mode',            icon = 'Shield' },
                { id = 'adm_invisible',  label = 'Invisible',           icon = 'EyeOff' },
                { id = 'adm_heal_self',  label = 'Se soigner',          icon = 'Heart', color = '#10b981' },
                { id = 'adm_armor_self', label = 'Armure',              icon = 'ShieldCheck', color = '#3b82f6' },
            }
        })
    end

    OpenContextMenu(x, y, items, '🌍 Interaction')
end
