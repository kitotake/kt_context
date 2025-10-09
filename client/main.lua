local isMenuOpen = false

function OpenContextMenu(x, y, items, title)
    if isMenuOpen then
        print("[KT Context] Menu déjà ouvert")
        return
    end

    if not items or #items == 0 then
        print("[KT Context] Aucun item fourni")
        return
    end

    isMenuOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        type = "openContextMenu",
        data = {
            x = x or 500,
            y = y or 300,
            items = items,
            title = title or "Menu"
        }
    })
end

function CloseContextMenu()
    if not isMenuOpen then return end

    isMenuOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({ type = "closeContextMenu" })
end

local actionHandlers = {
    inventory = function() 
        if GetResourceState('ox_inventory') == 'started' then
            TriggerEvent("ox_inventory:openInventory")
        else
            print("[KT Context] ox_inventory n'est pas démarré")
        end
    end,

    wave = function()
        local ped = PlayerPedId()
        RequestAnimDict("gestures@m@standing@casual")
        while not HasAnimDictLoaded("gestures@m@standing@casual") do Wait(10) end
        TaskPlayAnim(ped, "gestures@m@standing@casual", "gesture_hello", 8.0, -8.0, -1, 0, 0, false, false, false)
    end,

    dance = function()
        TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_PARTYING", 0, true)
    end,

    lock_vehicle = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
        if vehicle ~= 0 then
            local locked = GetVehicleDoorLockStatus(vehicle)
            SetVehicleDoorsLocked(vehicle, locked == 1 and 2 or 1)
            ShowNotification(locked == 1 and "Véhicule verrouillé" or "Véhicule déverrouillé", locked == 1 and "success" or "info")
        end
    end,

    engine_toggle = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
        end
    end,

    door_fl = function() ToggleVehicleDoor(0) end,
    door_fr = function() ToggleVehicleDoor(1) end,
    door_rl = function() ToggleVehicleDoor(2) end,
    door_rr = function() ToggleVehicleDoor(3) end,
    door_hood = function() ToggleVehicleDoor(4) end,
    door_trunk = function() ToggleVehicleDoor(5) end,

    window_all_up = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then 
            for i = 0, 3 do RollUpWindow(vehicle, i) end 
        end
    end,

    window_all_down = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then 
            for i = 0, 3 do RollDownWindow(vehicle, i) end 
        end
    end
}

function ToggleVehicleDoor(doorIndex)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if vehicle ~= 0 then
        if GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0 then
            SetVehicleDoorShut(vehicle, doorIndex, false)
        else
            SetVehicleDoorOpen(vehicle, doorIndex, false, false)
        end
    end
end

RegisterNUICallback("menuAction", function(data, cb)
    local handler = actionHandlers[data.id]
    if handler then
        handler()
    else
        print("[KT Context] Action non gérée: " .. tostring(data.id))
    end
    cb("ok")
end)

RegisterNUICallback("menuClosed", function(_, cb)
    CloseContextMenu()
    cb("ok")
end)

RegisterCommand("menu", function()
    local items = {
        { id = "inventory", label = "Inventaire", description = "Voir mes objets", icon = "🎒" },
        { id = "actions", label = "Actions", icon = "⚡", submenu = {
            { id = "wave", label = "Saluer", icon = "👋" },
            { id = "dance", label = "Danser", icon = "💃" }
        }},
        { id = "vehicle", label = "Véhicule", icon = "🚗", disabled = not IsPedInAnyVehicle(PlayerPedId(), false), submenu = {
            { id = "lock_vehicle", label = "Verrouiller", icon = "🔒" },
            { id = "engine_toggle", label = "Moteur On/Off", icon = "🔌" }
        }}
    }
    OpenContextMenu(nil, nil, items, "Menu Principal")
end)

Citizen.CreateThread(function()
    local menuZones = Config.MenuZones or {}

    if #menuZones == 0 then return end

    while true do
        local waitTime = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, zone in ipairs(menuZones) do
            local distance = #(coords - zone.coords)
            if distance < (zone.distance or 2.0) then
                waitTime = 0
                
                if zone.marker then
                    DrawMarker(
                        zone.marker.type or 2,
                        zone.coords.x, zone.coords.y, zone.coords.z + 1.0,
                        0, 0, 0, 0, 0, 0,
                        zone.marker.size.x or 0.3,
                        zone.marker.size.y or 0.3,
                        zone.marker.size.z or 0.3,
                        zone.marker.color.r or 255,
                        zone.marker.color.g or 255,
                        zone.marker.color.b or 255,
                        zone.marker.color.a or 200,
                        false, true, 2, false, nil, nil, false
                    )
                end
                
                if distance < 1.5 then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    if IsControlJustReleased(0, 38) then 
                        OpenContextMenu(nil, nil, zone.items, zone.title)
                    end
                end
            end
        end

        Wait(waitTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(isMenuOpen and 0 or 500)
        if isMenuOpen then
          
            DisableControlAction(0, 1, true)    
            DisableControlAction(0, 2, true)    
            DisableControlAction(0, 142, true) 
            DisableControlAction(0, 18, true)  
            DisableControlAction(0, 322, true) 
            DisableControlAction(0, 106, true) 
        end
    end
end)

exports("OpenContextMenu", OpenContextMenu)
exports("CloseContextMenu", CloseContextMenu)
exports("IsMenuOpen", function() return isMenuOpen end)