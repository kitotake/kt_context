-- =============================================
-- CURSEUR CONTEXTUEL — v3.2
-- =============================================

local CURSOR_KEY    = Config and Config.CursorKey or 19
local RAYCAST_FLAGS = 511

local cursorActive = false
local lastVehCheck = 0
local _cachedVeh   = -1
local _cachedDist  = math.huge

function IsCursorActive()
    return cursorActive
end

local function _GetClosestVeh(coords)
    local veh = GetClosestVehicle(
        coords.x, coords.y, coords.z,
        Config.InteractionDistance or 5.0, 0, 70
    )
    if veh and veh ~= 0 then
        return veh, #(coords - GetEntityCoords(veh))
    end
    return -1, math.huge
end

local function RaycastFromScreen(nx, ny)
    local camCoords = GetGameplayCamCoords()
    local camRot    = GetGameplayCamRot(2)
    local dir       = RotationToDirection(camRot)

    local fov    = GetGameplayCamFov()
    local sw, sh = GetActiveScreenResolution()
    local aspect = sw / sh

    local halfFovV = math.rad(fov * 0.5)
    local halfFovH = math.atan(math.tan(halfFovV) * aspect)

    local offsetX = (nx - 0.5) * 2.0
    local offsetY = (ny - 0.5) * 2.0

    local rotRight = vector3(
         math.cos(math.rad(camRot.z)),
         math.sin(math.rad(camRot.z)),
         0.0
    )

    local rayDir = vector3(
        dir.x + rotRight.x * math.tan(halfFovH) * offsetX,
        dir.y + rotRight.y * math.tan(halfFovH) * offsetX,
        dir.z - math.tan(halfFovV) * offsetY
    )

    local len = math.sqrt(rayDir.x^2 + rayDir.y^2 + rayDir.z^2)
    rayDir = vector3(rayDir.x/len, rayDir.y/len, rayDir.z/len)

    local dist = 100.0
    local ray  = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        camCoords.x + rayDir.x * dist,
        camCoords.y + rayDir.y * dist,
        camCoords.z + rayDir.z * dist,
        RAYCAST_FLAGS,
        PlayerPedId(),
        0
    )

    local _, hit, hitCoords, _, entity = GetShapeTestResult(ray)

    if hit == 1 and entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity, hitCoords
    end
    return nil, nil
end

-- ─── Thread curseur ───────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local sleep = 100

        if IsControlPressed(0, CURSOR_KEY) then
            sleep = 0

            if not cursorActive then
                cursorActive = true
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(true)
                SendNUIMessage({ type = 'cursorShow', data = { visible = true } })
            end

            DisableControlAction(0, 1,   true)
            DisableControlAction(0, 2,   true)
            DisableControlAction(0, 25,  true)
            DisableControlAction(0, 69,  true)
            DisableControlAction(0, 142, true)

        elseif cursorActive then
            cursorActive = false

            if IsMenuOpen() then CloseContextMenu() end

            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ type = 'cursorShow', data = { visible = false } })
        end

        Wait(sleep)
    end
end)

-- ─── NUI Callback clic ───────────────────────────────────────────────────────
RegisterNUICallback('cursorClick', function(data, cb)
    if IsMenuOpen() then cb('ok') return end

    local px = tonumber(data.x) or 0
    local py = tonumber(data.y) or 0

    local sw, sh = GetActiveScreenResolution()
    local nx = px / sw
    local ny = py / sh

    local entity, _ = RaycastFromScreen(nx, ny)

    if entity then
        if DebugTarget_OnEntityClick then DebugTarget_OnEntityClick(entity) end
        OpenContextForEntity(entity, GetEntityType(entity), px, py)
    else
        ClearDebugEntity()
        OpenGeneralContextMenu(px, py)
    end

    cb('ok')
end)

-- ─── Dispatch entité ─────────────────────────────────────────────────────────
function OpenContextForEntity(entity, entityType, x, y)
    local isAdmin = IsPlayerAdmin()
    local role    = GetAdminRole()
    local items   = {}

    if entityType == 1 then
        if IsPedAPlayer(entity) then
            local localId = NetworkGetPlayerIndexFromPed(entity)
            if localId ~= -1 then
                items = BuildPlayerMenu(
                    GetPlayerServerId(localId),
                    GetPlayerName(localId) or 'Joueur',
                    isAdmin
                )
            else
                items = BuildNpcMenu(entity, isAdmin)
            end
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

    if isAdmin and role then
        table.insert(items, { id = '_admin_div', divider = true, label = '' })
        table.insert(items, {
            id         = 'admin',
            label      = '⚡ Admin [' .. role .. ']',
            icon       = 'ShieldAlert',
            badge      = role,
            badgeColor = '#f59e0b',
            submenu    = BuildAdminEntityMenu(entity, entityType),
        })
    end

    OpenContextMenu(x, y, items, GetEntityMenuTitle(entityType, entity))
end

function GetEntityMenuTitle(entityType, entity)
    if entityType == 1 then return IsPedAPlayer(entity) and '👤 Joueur' or '🤖 PNJ' end
    if entityType == 2 then return '🚗 Véhicule' end
    if entityType == 3 then return '📦 Objet' end
    return '🌍 Interaction'
end

-- ─── Menu général (clic dans le vide) ────────────────────────────────────────
function OpenGeneralContextMenu(x, y)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local items  = {}

    if GetGameTimer() - lastVehCheck > 500 then
        _cachedVeh, _cachedDist = _GetClosestVeh(coords)
        lastVehCheck = GetGameTimer()
    end

    if _cachedVeh ~= -1 and _cachedDist < (Config.InteractionDistance or 5.0) then
        local locked = GetVehicleDoorLockStatus(_cachedVeh) ~= 1
        table.insert(items, {
            id      = 'near_vehicle',
            label   = ('Véhicule (%.1fm)'):format(_cachedDist),
            icon    = 'Car',
            submenu = BuildVehicleMenu(_cachedVeh, locked, IsPlayerAdmin()),
        })
    end

    table.insert(items, {
        id      = 'player_actions',
        label   = 'Actions joueur',
        icon    = 'User2',
        submenu = {
            { id = 'handsup',  label = "Mains en l'air", icon = 'Hand'       },
            { id = 'sit',      label = "S'asseoir",      icon = 'Armchair'   },
            { id = 'lay',      label = "S'allonger",     icon = 'BedDouble'  },
            { id = 'dance',    label = 'Danser',         icon = 'Music'      },
            { id = 'stopanim', label = 'Stop anim',      icon = 'StopCircle' },
        },
    })

    -- ── Overlays (checkboxes) ──────────────────────────────────────────────
    table.insert(items, {
        id      = 'overlays',
        label   = 'Affichages',
        icon    = 'Eye',
        submenu = BuildOverlayMenu(),
    })

    table.insert(items, { id = 'inventory', label = 'Inventaire', icon = 'Backpack' })

    if IsPlayerAdmin() then
        table.insert(items, {
            id         = 'admin_global',
            label      = '⚡ Admin',
            icon       = 'Shield',
            badge      = GetAdminRole(),
            badgeColor = '#f59e0b',
            submenu    = {
                { id = 'adm_tp_waypoint', label = 'TP waypoint',     icon = 'Navigation' },
                { id = 'adm_god',         label = 'God mode',        icon = 'Shield'     },
                { id = 'adm_heal_self',   label = 'Heal',            icon = 'Heart'      },
                { id = 'adm_delete',      label = 'Delete véhicule', icon = 'Trash2'     },
                { id = 'adm_invisible',   label = 'Invisible',       icon = 'EyeOff'     },
            },
        })
    end

    OpenContextMenu(x, y, items, '🌍 Interaction')
end