-- =============================================
-- CURSEUR CONTEXTUEL RP CLEAN V4
-- ALT GAUCHE + MENU POSITIONNÉ + RAYCAST PROPRE
-- =============================================

local CURSOR_KEY = Config and Config.CursorKey or 19

local cursorActive = false
local lastVehCheck = 0
local cachedVeh, cachedDist = -1, math.huge

-- =============================================
-- UTILS
-- =============================================

function IsCursorActive()
    return cursorActive
end

local function SafeIsMenuOpen()
    if IsMenuOpen then
        return IsMenuOpen()
    end
    return false
end

local function GetClosestVehicleData(coords)
    local veh = GetClosestVehicle(
        coords.x, coords.y, coords.z,
        Config.InteractionDistance or 5.0,
        0, 70
    )

    if veh and veh ~= 0 then
        local vcoords = GetEntityCoords(veh)
        return veh, #(coords - vcoords)
    end

    return -1, math.huge
end

-- =============================================
-- CURSEUR SYSTEM
-- =============================================

Citizen.CreateThread(function()
    while true do
        local sleep = 100

        if IsControlPressed(0, CURSOR_KEY) and not SafeIsMenuOpen() then
            sleep = 0

            if not cursorActive then
                cursorActive = true

               SetNuiFocus(true, true)
               SetNuiFocusKeepInput(true)

                SendNUIMessage({
                    type = "cursorShow",
                    data = { visible = true }
                })
            end

            -- blocage contrôles
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 142, true)

            -- clic
            if IsDisabledControlJustReleased(0, 24) then
                local x, y = GetNuiCursorPosition()
                HandleCursorClickAtScreenPos(x, y)
            end

        elseif cursorActive then cursorActive = false 
            SetNuiFocus(false, false) 
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ type = 'cursorShow',
            data = { visible = false } }) 
        end 
        Wait(sleep)
     end 
end)

-- =============================================
-- RAYCAST PROPRE
-- =============================================

function HandleCursorClickAtScreenPos(screenX, screenY)
    local sw, sh = GetActiveScreenResolution()

    local nx = screenX / sw
    local ny = screenY / sh

    local camCoords = GetGameplayCamCoords()
    local camRot = GetGameplayCamRot(2)

    local direction = RotationToDirection(camRot)

    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        camCoords.x + direction.x * 100.0,
        camCoords.y + direction.y * 100.0,
        camCoords.z + direction.z * 100.0,
        511,
        PlayerPedId(),
        0
    )

    local _, hit, _, _, entity = GetShapeTestResult(ray)

    local menuX, menuY = screenX, screenY

    if hit == 1 and entity ~= 0 then
        OpenContextForEntity(entity, GetEntityType(entity), menuX, menuY)
    else
        OpenGeneralContextMenu(menuX, menuY)
    end
end

-- =============================================
-- MENU ENTITY
-- =============================================

function OpenContextForEntity(entity, entityType, x, y)
    local isAdmin = IsPlayerAdmin()
    local role = GetAdminRole()
    local items = {}

    -- PED
    if entityType == 1 then
        if IsPedAPlayer(entity) then
            local playerId = NetworkGetPlayerIndexFromPed(entity)

            if playerId ~= -1 then
                local serverId = GetPlayerServerId(playerId)
                local name = GetPlayerName(playerId) or "Joueur"

                items = BuildPlayerMenu(serverId, name, isAdmin)
            else
                items = BuildNpcMenu(entity, isAdmin)
            end
        else
            items = BuildNpcMenu(entity, isAdmin)
        end

    -- VEHICULE
    elseif entityType == 2 then
        local locked = GetVehicleDoorLockStatus(entity) ~= 1
        items = BuildVehicleMenu(entity, locked, isAdmin)

    -- PROP
    elseif entityType == 3 then
        items = BuildPropMenu(entity, isAdmin)

    else
        OpenGeneralContextMenu(x, y)
        return
    end

    -- ADMIN
    if isAdmin and role then
        table.insert(items, {
            id = "_admin_div",
            divider = true,
            label = ""
        })

        table.insert(items, {
            id = "admin",
            label = "⚡ Admin [" .. role .. "]",
            icon = "ShieldAlert",
            submenu = BuildAdminEntityMenu(entity, entityType)
        })
    end

    OpenContextMenu(x, y, items, GetEntityMenuTitle(entityType, entity))
end

-- =============================================
-- TITRE MENU
-- =============================================

function GetEntityMenuTitle(entityType, entity)
    if entityType == 1 then
        return IsPedAPlayer(entity) and "👤 Joueur" or "🤖 PNJ"
    elseif entityType == 2 then
        return "🚗 Véhicule"
    elseif entityType == 3 then
        return "📦 Objet"
    end
    return "🌍 Interaction"
end

-- =============================================
-- MENU GENERAL
-- =============================================

function OpenGeneralContextMenu(x, y)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local items = {}

    -- VEH CACHE PERF
    if GetGameTimer() - lastVehCheck > 500 then
        cachedVeh, cachedDist = GetClosestVehicleData(coords)
        lastVehCheck = GetGameTimer()
    end

    if cachedVeh ~= -1 and cachedDist < (Config.InteractionDistance or 5.0) then
        table.insert(items, {
            id = "near_vehicle",
            label = ("Véhicule (%.1fm)"):format(cachedDist),
            icon = "Car",
            submenu = BuildVehicleMenu(
                cachedVeh,
                GetVehicleDoorLockStatus(cachedVeh) ~= 1,
                IsPlayerAdmin()
            )
        })
    end

    table.insert(items, {
        id = "player_actions",
        label = "Actions joueur",
        icon = "User2",
        submenu = {
            { id = "handsup", label = "Mains en l'air", icon = "Hand" },
            { id = "sit", label = "S'asseoir", icon = "Armchair" },
            { id = "lay", label = "S'allonger", icon = "BedDouble" },
            { id = "dance", label = "Danser", icon = "Music" },
            { id = "stop", label = "Stop anim", icon = "StopCircle" }
        }
    })

    table.insert(items, {
        id = "inventory",
        label = "Inventaire",
        icon = "Backpack"
    })

    if IsPlayerAdmin() then
        table.insert(items, {
            id = "admin_global",
            label = "⚡ Admin",
            icon = "Shield",
            submenu = {
                { id = "tp", label = "TP waypoint", icon = "Navigation" },
                { id = "god", label = "God mode", icon = "Shield" },
                { id = "heal", label = "Heal", icon = "Heart" },
                { id = "deleteveh", label = "Delete véhicule", icon = "Trash2" }
            }
        })
    end

    OpenContextMenu(x, y, items, "Interaction")
end