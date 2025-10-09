local KeyBinds = {
    registered = {},
    active = true
}

local DefaultKeys = {
    mainMenu = { key = "F1", control = 288, description = "Ouvrir le menu principal" },
    vehicleMenu = { key = "F2", control = 289, description = "Menu véhicule" },
    inventoryMenu = { key = "F3", control = 170, description = "Inventaire" },
    phoneMenu = { key = "F4", control = 289, description = "Téléphone" },
    
    quickEmote = { key = "X", control = 73, description = "Menu émotes" },
    quickVehicleLock = { key = "L", control = 182, description = "Verrouiller véhicule" },
    quickEngine = { key = "Y", control = 246, description = "Moteur on/off" },
    
    contextMenu = { key = "F1", control = 288, description = "Menu contextuel" },
    closeMenu = { key = "ESC", control = 322, description = "Fermer le menu" },
    
    
    adminMenu = { key = "F6", control = 167, description = "Menu admin" },
    noclip = { key = "F7", control = 168, description = "Noclip" }
}

function KeyBinds:Register(id, key, control, callback, description)
    if self.registered[id] then
        print("[KT Context] Keybind déjà enregistré: " .. id)
        return false
    end
    
    self.registered[id] = {
        id = id,
        key = key,
        control = control,
        callback = callback,
        description = description or "Aucune description",
        enabled = true
    }
    
    if RegisterKeyMapping then
        RegisterKeyMapping(id, description or id, "keyboard", key)
    end
    
    return true
end

function KeyBinds:Unregister(id)
    if self.registered[id] then
        self.registered[id] = nil
        return true
    end
    return false
end

function KeyBinds:Toggle(id, state)
    if self.registered[id] then
        self.registered[id].enabled = state
        return true
    end
    return false
end

function KeyBinds:ToggleAll(state)
    self.active = state
end

function KeyBinds:IsPressed(control)
    if not self.active then return false end
    return IsControlJustPressed(0, control)
end

Citizen.CreateThread(function()
    while true do
        local sleep = 100
        
        if KeyBinds.active then
            sleep = 0
            
            for id, bind in pairs(KeyBinds.registered) do
                if bind.enabled and KeyBinds:IsPressed(bind.control) then
                    if bind.callback then
                        bind.callback()
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

function RegisterDefaultKeybinds()
    KeyBinds:Register(
        "kt_menu_main",
        DefaultKeys.mainMenu.key,
        DefaultKeys.mainMenu.control,
        function()
            if not isMenuOpen then
                OpenContextualMenu()
            end
        end,
        DefaultKeys.mainMenu.description
    )
    
    KeyBinds:Register(
        "kt_menu_vehicle",
        DefaultKeys.vehicleMenu.key,
        DefaultKeys.vehicleMenu.control,
        function()
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                OpenAdvancedVehicleMenu()
            else
                ShowNotification("Vous devez être dans un véhicule", "warning")
            end
        end,
        DefaultKeys.vehicleMenu.description
    )
    
    KeyBinds:Register(
        "kt_menu_inventory",
        DefaultKeys.inventoryMenu.key,
        DefaultKeys.inventoryMenu.control,
        function()
            TriggerEvent("ox_inventory:openInventory")
        end,
        DefaultKeys.inventoryMenu.description
    )
    
    KeyBinds:Register(
        "kt_menu_phone",
        DefaultKeys.phoneMenu.key,
        DefaultKeys.phoneMenu.control,
        function()
            OpenPhoneMenu()
        end,
        DefaultKeys.phoneMenu.description
    )
    
    KeyBinds:Register(
        "kt_quick_lock",
        DefaultKeys.quickVehicleLock.key,
        DefaultKeys.quickVehicleLock.control,
        function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, true)
            
            if vehicle ~= 0 then
                local locked = GetVehicleDoorLockStatus(vehicle)
                SetVehicleDoorsLocked(vehicle, locked == 1 and 2 or 1)
                
                if locked == 1 then
                    ShowNotification("🔒 Véhicule verrouillé", "info")
                    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
                else
                    ShowNotification("🔓 Véhicule déverrouillé", "info")
                    PlaySoundFrontend(-1, "CANCEL", "HUD_MINI_GAME_SOUNDSET", true)
                end
            else
                ShowNotification("Aucun véhicule à proximité", "error")
            end
        end,
        DefaultKeys.quickVehicleLock.description
    )
    
    KeyBinds:Register(
        "kt_quick_engine",
        DefaultKeys.quickEngine.key,
        DefaultKeys.quickEngine.control,
        function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local engineOn = GetIsVehicleEngineRunning(vehicle)
                SetVehicleEngineOn(vehicle, not engineOn, false, true)
                
                if engineOn then
                    ShowNotification("Moteur éteint", "info")
                else
                    ShowNotification("Moteur allumé", "success")
                end
            end
        end,
        DefaultKeys.quickEngine.description
    )
    
   
    KeyBinds:Register(
        "kt_quick_emotes",
        DefaultKeys.quickEmote.key,
        DefaultKeys.quickEmote.control,
        function()
            local items = {
                { id = "wave", label = "Saluer", icon = "👋" },
                { id = "dance", label = "Danser", icon = "💃" },
                { id = "sit", label = "S'asseoir", icon = "🪑" },
                { id = "lean", label = "S'adosser", icon = "🧍" },
                { id = "smoke", label = "Fumer", icon = "🚬" }
            }
            OpenContextMenu(nil, nil, items, "⚡ Émotes Rapides")
        end,
        DefaultKeys.quickEmote.description
    )
end

Citizen.CreateThread(function()
    Wait(1000)
    RegisterDefaultKeybinds()
    print("[KT Context] Keybinds enregistrés avec succès")
end)

-- Exports
exports("RegisterKeybind", function(id, key, control, callback, description)
    return KeyBinds:Register(id, key, control, callback, description)
end)

exports("UnregisterKeybind", function(id)
    return KeyBinds:Unregister(id)
end)

exports("ToggleKeybind", function(id, state)
    return KeyBinds:Toggle(id, state)
end)

exports("ToggleAllKeybinds", function(state)
    KeyBinds:ToggleAll(state)
end)