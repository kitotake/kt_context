-- =============================================
-- MENU CONTEXTUEL PRINCIPAL
-- =============================================

local isMenuOpen = false

-- ─── Ouverture ──────────────────────────────────────────────────────────────
function OpenContextMenu(x, y, items, title, options)
    if isMenuOpen then
        print("[KT Context] Menu déjà ouvert, fermeture forcée avant réouverture")
        CloseContextMenu()
    end

    if not items or #items == 0 then
        print("[KT Context] Aucun item fourni")
        return
    end

    options = options or {}
    isMenuOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        type = "openContextMenu",
        data = {
            x       = x       or 500,
            y       = y       or 300,
            items   = items,
            title   = title   or "Menu",
            theme   = options.theme   or "dark",
            animate = options.animate ~= false,
        }
    })

    TriggerServerEvent("kt_context:logMenuOpen", title or "unknown")
end

-- ─── Fermeture ──────────────────────────────────────────────────────────────
function CloseContextMenu()
    if not isMenuOpen then return end
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "closeContextMenu" })
end

-- ─── Statut ─────────────────────────────────────────────────────────────────
function IsMenuOpen()
    return isMenuOpen
end

-- ─── Réinitialisation de sécurité au respawn / reload resource ───────────────
-- Évite que isMenuOpen reste bloqué sur true si la NUI se recharge
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isMenuOpen then
            isMenuOpen = false
            SetNuiFocus(false, false)
        end
    end
end)

AddEventHandler('playerSpawned', function()
    if isMenuOpen then
        isMenuOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "closeContextMenu" })
    end
end)

-- ─── Gestionnaires d'actions ─────────────────────────────────────────────────
local actionHandlers = {

    -- Inventaire
    inventory = function()
        if GetResourceState('kt_inventory') == 'started' then
            TriggerEvent("kt_inventory:openInventory")
        end
    end,

    -- Animations joueur
    wave = function()
        local ped = PlayerPedId()
        RequestAnimDict("gestures@m@standing@casual")
        while not HasAnimDictLoaded("gestures@m@standing@casual") do Wait(10) end
        TaskPlayAnim(ped, "gestures@m@standing@casual", "gesture_hello", 8.0, -8.0, -1, 0, 0, false, false, false)
    end,

    handsup = function()
        local ped = PlayerPedId()
        RequestAnimDict("random@mugging3")
        while not HasAnimDictLoaded("random@mugging3") do Wait(10) end
        TaskPlayAnim(ped, "random@mugging3", "handsup_standing_base", 8.0, -8.0, -1, 50, 0, false, false, false)
    end,

    sit = function()
        TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_PICNIC", 0, true)
    end,

    lay = function()
        TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_SUNBATHE_BACK", 0, true)
    end,

    stopanim = function()
        ClearPedTasks(PlayerPedId())
    end,

    -- Véhicule
    veh_lock = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            local locked = GetVehicleDoorLockStatus(veh)
            SetVehicleDoorsLocked(veh, locked == 1 and 2 or 1)
            ShowNotification(locked == 1 and L('vehicle_locked') or L('vehicle_unlocked'), locked == 1 and "success" or "info")
        end
    end,

    veh_engine = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleEngineOn(veh, not GetIsVehicleEngineRunning(veh), false, true)
        end
    end,

    door_fl    = function() ToggleVehicleDoor(0) end,
    door_fr    = function() ToggleVehicleDoor(1) end,
    door_rl    = function() ToggleVehicleDoor(2) end,
    door_rr    = function() ToggleVehicleDoor(3) end,
    door_hood  = function() ToggleVehicleDoor(4) end,
    door_trunk = function() ToggleVehicleDoor(5) end,

    win_up = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then for i = 0, 3 do RollUpWindow(veh, i) end end
    end,

    win_down = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then for i = 0, 3 do RollDownWindow(veh, i) end end
    end,

    -- Admin général
    adm_coords_self = function()
        local coords = GetEntityCoords(PlayerPedId())
        ShowNotification(string.format("📍 X:%.2f Y:%.2f Z:%.2f", coords.x, coords.y, coords.z), "info")
    end,

    adm_tp_waypoint = function()
        if not IsPlayerAceAllowed(PlayerId(), "admin") then return end
        local waypoint = GetFirstBlipInfoId(8)
        if DoesBlipExist(waypoint) then
            local coords = GetBlipInfoIdCoord(waypoint)
            local ped    = PlayerPedId()
            local veh    = GetVehiclePedIsIn(ped, false)
            local found, gz = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
            local z = found and gz or coords.z
            if veh ~= 0 then
                SetEntityCoords(veh, coords.x, coords.y, z + 1.0)
            else
                SetEntityCoords(ped, coords.x, coords.y, z + 1.0)
            end
            ShowNotification("📍 Téléporté au waypoint", "success")
        else
            ShowNotification("Aucun waypoint placé", "warning")
        end
    end,

    adm_god = function()
        if not IsPlayerAceAllowed(PlayerId(), "admin") then return end
        local ped = PlayerPedId()
        local inv = GetPlayerInvincible(PlayerId())
        SetEntityInvincible(ped, not inv)
        ShowNotification(inv and "God Mode désactivé" or "God Mode activé", "info")
    end,

    adm_invisible = function()
        if not IsPlayerAceAllowed(PlayerId(), "admin") then return end
        local ped = PlayerPedId()
        local vis = IsEntityVisible(ped)
        SetEntityVisible(ped, not vis, false)
        ShowNotification(vis and "Invisible activé" or "Visible", "info")
    end,

    adm_heal_self = function()
        if not IsPlayerAceAllowed(PlayerId(), "admin") then return end
        local ped = PlayerPedId()
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ShowNotification("❤️ Santé restaurée", "success")
    end,

    adm_armor_self = function()
        if not IsPlayerAceAllowed(PlayerId(), "admin") then return end
        SetPedArmour(PlayerPedId(), 100)
        ShowNotification("🛡️ Armure restaurée", "success")
    end,

    adm_delete = function()
        ShowNotification("Action admin: supprimer entité", "warning")
    end,

    adm_repair = function()
        if not IsPlayerAceAllowed(PlayerId(), "admin") then return end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleFixed(veh)
            SetVehicleDeformationFixed(veh)
            SetVehicleUndriveable(veh, false)
            SetVehicleEngineOn(veh, true, false)
            SetVehicleDirtLevel(veh, 0.0)
            ShowNotification("🔧 Véhicule réparé", "success")
        end
    end,

    adm_refuel = function()
        if not IsPlayerAceAllowed(PlayerId(), "admin") then return end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleFuelLevel(veh, 100.0)
            ShowNotification("⛽ Réservoir rempli", "success")
        end
    end,

    phone = function()
        TriggerEvent("kt_phone:open")
    end,
}

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────
RegisterNUICallback("menuAction", function(data, cb)
    local handler = actionHandlers[data.id]
    if handler then
        handler()
    else
        print("[KT Context] Action non gérée: " .. tostring(data.id))
        TriggerEvent("kt_context:action", data.id, data)
    end
    cb("ok")
end)

RegisterNUICallback("menuClosed", function(_, cb)
    CloseContextMenu()
    cb("ok")
end)

-- ─── Désactivation contrôles quand menu ouvert ────────────────────────────────
-- Cohérent avec cursor.lua pour éviter les doublons / oublis
local BLOCKED_CONTROLS = {
    1,    -- LookLeftRight
    2,    -- LookUpDown
    24,   -- Attack (clic gauche)
    25,   -- Aim
    142,  -- MeleeAttackAlternate
    18,   -- Enter
    322,  -- Backspace / ESC menu pause
    106,  -- VehicleMouseControlOverride
    68,   -- VehicleExit
}

Citizen.CreateThread(function()
    while true do
        if isMenuOpen then
            for _, ctrl in ipairs(BLOCKED_CONTROLS) do
                DisableControlAction(0, ctrl, true)
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────
exports("OpenContextMenu",  OpenContextMenu)
exports("CloseContextMenu", CloseContextMenu)
exports("IsMenuOpen",       function() return isMenuOpen end)