local RadialMenu = {
    isOpen = false,
    currentMenu = nil
}

local RadialMenus = {
    main = {
        title = "Menu Principal",
        items = {
            {
                id = "vehicle",
                label = "Véhicule",
                icon = "🚗",
                submenu = "vehicle"
            },
            {
                id = "player",
                label = "Joueur",
                icon = "👤",
                submenu = "player"
            },
            {
                id = "emotes",
                label = "Émotes",
                icon = "😊",
                submenu = "emotes"
            },
            {
                id = "items",
                label = "Objets",
                icon = "🎒",
                submenu = "items"
            },
            {
                id = "phone",
                label = "Téléphone",
                icon = "📱",
                action = function() OpenPhoneMenu() end
            },
            {
                id = "admin",
                label = "Admin",
                icon = "🛡️",
                submenu = "admin",
                condition = function()
                    return IsPlayerAceAllowed(PlayerId(), "admin")
                end
            }
        }
    },
    
    items = {
        title = "Objets Rapides",
        parent = "main",
        items = {
            {
                id = "water",
                label = "Boire de l'eau",
                icon = "💧",
                action = function()
                    ShowNotification("Vous buvez de l'eau", "info")
                end
            },
            {
                id = "eat",
                label = "Manger",
                icon = "🍔",
                action = function()
                    ShowNotification("Vous mangez", "info")
                end
            },
            {
                id = "medkit",
                label = "Kit médical",
                icon = "🏥",
                action = function()
                    ShowNotification("Vous utilisez un kit médical", "success")
                end
            }
        }
    },
    
    admin = {
        title = "Admin",
        parent = "main",
        items = {
            {
                id = "heal",
                label = "Se soigner",
                icon = "❤️",
                action = function() QuickActions.Admin.Heal() end
            },
            {
                id = "armor",
                label = "Armure",
                icon = "🛡️",
                action = function() QuickActions.Admin.GiveArmor() end
            },
            {
                id = "fix",
                label = "Réparer Véhicule",
                icon = "🔧",
                action = function() QuickActions.Admin.RepairVehicle() end
            },
            {
                id = "dv",
                label = "Supprimer Véhicule",
                icon = "🗑️",
                action = function() QuickActions.Admin.DeleteVehicle() end
            },
            {
                id = "tpw",
                label = "TP Waypoint",
                icon = "📍",
                action = function() QuickActions.Admin.TeleportToWaypoint() end
            },
            {
                id = "noclip",
                label = "NoClip",
                icon = "👻",
                action = function()
                    TriggerEvent("kt_admin:toggleNoclip")
                end
            }
        }
    }
}

function RadialMenu:Open(menuId)
    menuId = menuId or "main"
    local menu = RadialMenus[menuId]
    
    if not menu then
        print("[KT Context] Menu radial introuvable: " .. menuId)
        return
    end
    
    local filteredItems = {}
    for _, item in ipairs(menu.items) do
        if not item.condition or item.condition() then
            table.insert(filteredItems, item)
        end
    end
    
    self.isOpen = true
    self.currentMenu = menuId
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openRadialMenu",
        data = {
            title = menu.title,
            items = filteredItems,
            parent = menu.parent
        }
    })
end

function RadialMenu:Close()
    if not self.isOpen then return end
    
    self.isOpen = false
    self.currentMenu = nil
    
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "closeRadialMenu" })
end

function RadialMenu:OpenSubmenu(submenuId)
    self:Close()
    Wait(100)
    self:Open(submenuId)
end

function RadialMenu:GoBack()
    local currentMenu = RadialMenus[self.currentMenu]
    
    if currentMenu and currentMenu.parent then
        self:Close()
        Wait(100)
        self:Open(currentMenu.parent)
    else
        self:Close()
    end
end

RegisterNUICallback("radialMenuAction", function(data, cb)
    local action = data.action
    local menuId = data.menuId
    
    if action == "back" then
        RadialMenu:GoBack()
    elseif action == "close" then
        RadialMenu:Close()
    elseif action == "submenu" then
        RadialMenu:OpenSubmenu(data.submenuId)
    elseif action == "item" then
        local menu = RadialMenus[menuId]
        if menu then
            for _, item in ipairs(menu.items) do
                if item.id == data.itemId then
                    if item.submenu then
                        RadialMenu:OpenSubmenu(item.submenu)
                    elseif item.action then
                        item.action()
                        RadialMenu:Close()
                    end
                    break
                end
            end
        end
    end
    
    cb("ok")
end)

RegisterCommand("+radialmenu", function()
    if not RadialMenu.isOpen then
        RadialMenu:Open("main")
    end
end, false)

RegisterCommand("-radialmenu", function()
    if RadialMenu.isOpen then
        RadialMenu:Close()
    end
end, false)

RegisterKeyMapping("+radialmenu", "Ouvrir le menu radial", "keyboard", "Z")

exports("OpenRadialMenu", function(menuId)
    RadialMenu:Open(menuId)
end)

exports("CloseRadialMenu", function()
    RadialMenu:Close()
end)

_G.RadialMenu = RadialMenu,
    
    vehicle = {
        title = "Véhicule",
        parent = "main",
        items = {
            {
                id = "lock",
                label = "Verrouiller",
                icon = "🔒",
                action = function() QuickActions.Vehicle.ToggleLock() end
            },
            {
                id = "engine",
                label = "Moteur",
                icon = "🔌",
                action = function()
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 then
                        SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
                    end
                end
            },
            {
                id = "doors",
                label = "Portes",
                icon = "🚪",
                submenu = "vehicle_doors"
            },
            {
                id = "windows",
                label = "Vitres",
                icon = "🪟",
                submenu = "vehicle_windows"
            },
            {
                id = "trunk",
                label = "Coffre",
                icon = "📦",
                action = function()
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
                    if vehicle ~= 0 then
                        if GetVehicleDoorAngleRatio(vehicle, 5) > 0 then
                            SetVehicleDoorShut(vehicle, 5, false)
                        else
                            SetVehicleDoorOpen(vehicle, 5, false, false)
                        end
                    end
                end
            },
            {
                id = "hood",
                label = "Capot",
                icon = "🔩",
                action = function()
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
                    if vehicle ~= 0 then
                        if GetVehicleDoorAngleRatio(vehicle, 4) > 0 then
                            SetVehicleDoorShut(vehicle, 4, false)
                        else
                            SetVehicleDoorOpen(vehicle, 4, false, false)
                        end
                    end
                end
            }
        }
    },
    
    vehicle_doors = {
        title = "Portes",
        parent = "vehicle",
        items = {
            {
                id = "fl",
                label = "Avant Gauche",
                icon = "🚪",
                action = function() ToggleVehicleDoor(0) end
            },
            {
                id = "fr",
                label = "Avant Droite",
                icon = "🚪",
                action = function() ToggleVehicleDoor(1) end
            },
            {
                id = "rl",
                label = "Arrière Gauche",
                icon = "🚪",
                action = function() ToggleVehicleDoor(2) end
            },
            {
                id = "rr",
                label = "Arrière Droite",
                icon = "🚪",
                action = function() ToggleVehicleDoor(3) end
            },
            {
                id = "close_all",
                label = "Tout Fermer",
                icon = "🔒",
                action = function() QuickActions.Vehicle.CloseAllDoors() end
            }
        }
    },
    
    vehicle_windows = {
        title = "Vitres",
        parent = "vehicle",
        items = {
            {
                id = "up_all",
                label = "Toutes Monter",
                icon = "⬆️",
                action = function() QuickActions.Vehicle.CloseAllWindows() end
            },
            {
                id = "down_all",
                label = "Toutes Descendre",
                icon = "⬇️",
                action = function() QuickActions.Vehicle.OpenAllWindows() end
            }
        }
    },
    
    player = {
        title = "Actions Joueur",
        parent = "main",
        items = {
            {
                id = "handsup",
                label = "Mains en l'air",
                icon = "🙌",
                action = function() QuickActions.Player.HandsUp() end
            },
            {
                id = "sit",
                label = "S'asseoir",
                icon = "🪑",
                action = function() QuickActions.Player.SitGround() end
            },
            {
                id = "lay",
                label = "S'allonger",
                icon = "😴",
                action = function() QuickActions.Player.LayDown() end
            },
            {
                id = "crouch",
                label = "S'accroupir",
                icon = "🧍",
                action = function() QuickActions.Player.Crouch() end
            },
            {
                id = "stopanim",
                label = "Arrêter Animation",
                icon = "⏹️",
                action = function() QuickActions.Player.StopAnim() end
            }
        }
    },
    
    emotes = {
        title = "Émotes",
        parent = "main",
        items = {
            {
                id = "wave",
                label = "Saluer",
                icon = "👋",
                action = function()
                    local ped = PlayerPedId()
                    RequestAnimDict("gestures@m@standing@casual")
                    while not HasAnimDictLoaded("gestures@m@standing@casual") do Wait(10) end
                    TaskPlayAnim(ped, "gestures@m@standing@casual", "gesture_hello", 8.0, -8.0, -1, 0, 0, false, false, false)
                end
            },
            {
                id = "dance",
                label = "Danser",
                icon = "💃",
                action = function()
                    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_PARTYING", 0, true)
                end
            },
            {
                id = "clap",
                label = "Applaudir",
                icon = "👏",
                action = function()
                    local ped = PlayerPedId()
                    RequestAnimDict("anim@mp_player_intcelebrationfemale@slow_clap")
                    while not HasAnimDictLoaded("anim@mp_player_intcelebrationfemale@slow_clap") do Wait(10) end
                    TaskPlayAnim(ped, "anim@mp_player_intcelebrationfemale@slow_clap", "slow_clap", 8.0, -8.0, -1, 0, 0, false, false, false)
                end
            },
            {
                id = "facepalm",
                label = "Facepalm",
                icon = "🤦",
                action = function()
                    local ped = PlayerPedId()
                    RequestAnimDict("anim@mp_player_intcelebrationfemale@face_palm")
                    while not HasAnimDictLoaded("anim@mp_player_intcelebrationfemale@face_palm") do Wait(10) end
                    TaskPlayAnim(ped, "anim@mp_player_intcelebrationfemale@face_palm", "face_palm", 8.0, -8.0, -1, 0, 0, false, false, false)
                end
            },
            {
                id = "think",
                label = "Réfléchir",
                icon = "🤔",
                action = function()
                    local ped = PlayerPedId()
                    RequestAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a")
                    while not HasAnimDictLoaded("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a") do Wait(10) end
                    TaskPlayAnim(ped, "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 8.0, -8.0, -1, 50, 0, false, false, false)
                end
            }
        }