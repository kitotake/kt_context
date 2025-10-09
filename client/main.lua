local isMenuOpen = false

function OpenContextMenu(x, y, items, title)
    if isMenuOpen then return end
    
    isMenuOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "openContextMenu",
        data = {
            x = x or 500,
            y = y or 300,
            items = items or {},
            title = title or "Menu"
        }
    })
end

function CloseContextMenu()
    if not isMenuOpen then return end
    
    isMenuOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        type = "closeContextMenu"
    })
end

RegisterNUICallback("menuAction", function(data, cb)
    print("Action cliquée: " .. data.id)
    
    if data.id == "inventory" then
        TriggerEvent("inventory:open")
    elseif data.id == "wave" then
        TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_CHEERING", 0, true)
        Wait(3000)
        ClearPedTasks(PlayerPedId())
    elseif data.id == "dance" then
        TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_PARTYING", 0, true)
    elseif data.id == "lock" then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
        if vehicle ~= 0 then
            SetVehicleDoorsLocked(vehicle, 2)
            TriggerEvent("chat:addMessage", {
                args = {"Véhicule verrouillé"}
            })
        end
    end
    
    cb("ok")
end)

RegisterNUICallback("menuClosed", function(data, cb)
    CloseContextMenu()
    cb("ok")
end)

RegisterCommand("menu", function()
    local items = {
        {
            id = "inventory",
            label = "Inventaire",
            description = "Voir mes objets",
            icon = "🎒"
        },
        {
            id = "actions",
            label = "Actions",
            icon = "⚡",
            submenu = {
                {
                    id = "wave",
                    label = "Saluer",
                    icon = "👋"
                },
                {
                    id = "dance",
                    label = "Danser",
                    icon = "💃"
                }
            }
        },
        {
            id = "vehicle",
            label = "Véhicule",
            icon = "🚗",
            disabled = not IsPedInAnyVehicle(PlayerPedId(), false),
            submenu = {
                {
                    id = "lock",
                    label = "Verrouiller"
                },
                {
                    id = "engine",
                    label = "Moteur On/Off"
                }
            }
        }
    }
    
    OpenContextMenu(500, 300, items, "Menu Principal")
end, false)

RegisterNetEvent("kt_context:playerMenu")
AddEventHandler("kt_context:playerMenu", function(targetId, targetName)
    local items = {
        {
            id = "trade",
            label = "Échanger",
            description = "Proposer un échange",
            icon = "🤝"
        },
        {
            id = "give_money",
            label = "Donner de l'argent",
            icon = "💵",
            submenu = {
                {
                    id = "give_100",
                    label = "100$"
                },
                {
                    id = "give_500",
                    label = "500$"
                },
                {
                    id = "give_1000",
                    label = "1000$"
                },
                {
                    id = "give_custom",
                    label = "Montant personnalisé"
                }
            }
        },
        {
            id = "view_id",
            label = "Voir l'identité",
            icon = "📋"
        }
    }
    
    OpenContextMenu(nil, nil, items, targetName)
end)

RegisterCommand("vmenu", function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        vehicle = GetVehiclePedIsIn(ped, true)
    end
    
    if vehicle == 0 then
        TriggerEvent("chat:addMessage", {
            args = {"Aucun véhicule à proximité"}
        })
        return
    end
    
    local isInVehicle = IsPedInAnyVehicle(ped, false)
    local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
    
    local items = {
        {
            id = "lock_vehicle",
            label = isInVehicle and "Verrouiller" or "Déverrouiller",
            description = "Contrôler les portes",
            icon = "🔒"
        },
        {
            id = "engine",
            label = "Moteur",
            icon = "🔧",
            disabled = not isDriver,
            submenu = {
                {
                    id = "engine_toggle",
                    label = "Allumer/Éteindre"
                },
                {
                    id = "engine_repair",
                    label = "Réparer (Admin)",
                    disabled = not IsPlayerAceAllowed(PlayerId(), "admin")
                }
            }
        },
        {
            id = "doors",
            label = "Portes",
            icon = "🚪",
            submenu = {
                {
                    id = "door_front_left",
                    label = "Avant gauche"
                },
                {
                    id = "door_front_right",
                    label = "Avant droite"
                },
                {
                    id = "door_rear_left",
                    label = "Arrière gauche"
                },
                {
                    id = "door_rear_right",
                    label = "Arrière droite"
                },
                {
                    id = "door_hood",
                    label = "Capot"
                },
                {
                    id = "door_trunk",
                    label = "Coffre"
                }
            }
        },
        {
            id = "windows",
            label = "Vitres",
            icon = "🪟",
            disabled = not isInVehicle,
            submenu = {
                {
                    id = "window_up_all",
                    label = "Monter toutes"
                },
                {
                    id = "window_down_all",
                    label = "Descendre toutes"
                }
            }
        }
    }
    
    OpenContextMenu(nil, nil, items, "Menu Véhicule")
end, false)

Citizen.CreateThread(function()
    local menuZones = {
        {
            coords = vector3(0.0, 0.0, 0.0),
            title = "Armurerie",
            items = {
                {
                    id = "buy_pistol",
                    label = "Pistolet",
                    description = "500$",
                    icon = "🔫"
                },
                {
                    id = "buy_rifle",
                    label = "Fusil d'assault",
                    description = "2500$",
                    icon = "🔫"
                },
                {
                    id = "buy_ammo",
                    label = "Munitions",
                    icon = "📦",
                    submenu = {
                        {
                            id = "ammo_pistol",
                            label = "Munitions pistolet - 50$"
                        },
                        {
                            id = "ammo_rifle",
                            label = "Munitions fusil - 100$"
                        }
                    }
                }
            }
        }
    }
    
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        for _, zone in ipairs(menuZones) do
            local distance = #(coords - zone.coords)
            
            if distance < 2.0 then
                DrawMarker(2, zone.coords.x, zone.coords.y, zone.coords.z + 1.0, 
                    0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 
                    255, 255, 255, 200, 
                    false, true, 2, false, nil, nil, false)
                
                if distance < 1.5 then
                    SetTextComponentFormat("STRING")
                    AddTextComponentString("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu")
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    
                    if IsControlJustReleased(0, 38) then 
                        OpenContextMenu(nil, nil, zone.items, zone.title)
                    end
                end
            end
        end
    end
end)


local actionHandlers = {

    inventory = function()
        TriggerEvent("ox_inventory:openInventory") 
    end,
    
    wave = function()
        local ped = PlayerPedId()
        RequestAnimDict("gestures@m@standing@casual")
        while not HasAnimDictLoaded("gestures@m@standing@casual") do
            Wait(10)
        end
        TaskPlayAnim(ped, "gestures@m@standing@casual", "gesture_hello", 8.0, -8.0, -1, 0, 0, false, false, false)
    end,
    
    dance = function()
        local ped = PlayerPedId()
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_PARTYING", 0, true)
    end,
    
    lock_vehicle = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
        if vehicle ~= 0 then
            local locked = GetVehicleDoorLockStatus(vehicle)
            SetVehicleDoorsLocked(vehicle, locked == 1 and 2 or 1)
            
            TriggerEvent("chat:addMessage", {
                color = {59, 130, 246},
                args = {locked == 1 and "🔒 Véhicule verrouillé" or "🔓 Véhicule déverrouillé"}
            })
        end
    end,
    
    engine_toggle = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            local engineOn = GetIsVehicleEngineRunning(vehicle)
            SetVehicleEngineOn(vehicle, not engineOn, false, true)
        end
    end,
    
    door_front_left = function()
        ToggleVehicleDoor(0)
    end,
    door_front_right = function()
        ToggleVehicleDoor(1)
    end,
    door_rear_left = function()
        ToggleVehicleDoor(2)
    end,
    door_rear_right = function()
        ToggleVehicleDoor(3)
    end,
    door_hood = function()
        ToggleVehicleDoor(4)
    end,
    door_trunk = function()
        ToggleVehicleDoor(5)
    end,

    window_up_all = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            for i = 0, 3 do
                RollUpWindow(vehicle, i)
            end
        end
    end,
    
    window_down_all = function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            for i = 0, 3 do
                RollDownWindow(vehicle, i)
            end
        end
    end
}

function ToggleVehicleDoor(doorIndex)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if vehicle ~= 0 then
        local doorAngle = GetVehicleDoorAngleRatio(vehicle, doorIndex)
        if doorAngle > 0 then
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
        print("Action non gérée: " .. data.id)
    end
    
    cb("ok")
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        
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
exports("IsMenuOpen", function()
    return isMenuOpen
end)

