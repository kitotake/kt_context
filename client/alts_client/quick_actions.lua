local QuickActions = {}

QuickActions.Vehicle = {
    ToggleLock = function()
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
            
            TriggerServerEvent("kt_context:logVehicleAction", "lock", {
                vehicle = vehicle,
                locked = locked == 1
            })
        else
            ShowNotification("Aucun véhicule à proximité", "error")
        end
    end,
    
    ToggleEngine = function()
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
            
            TriggerServerEvent("kt_context:logVehicleAction", "engine", {
                vehicle = vehicle,
                engineOn = not engineOn
            })
        else
            ShowNotification("Vous devez être le conducteur", "warning")
        end
    end,
    
    OpenAllDoors = function()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, true)
        
        if vehicle ~= 0 then
            for i = 0, 5 do
                SetVehicleDoorOpen(vehicle, i, false, false)
            end
            ShowNotification("Toutes les portes ouvertes", "success")
            TriggerServerEvent("kt_context:logVehicleAction", "doors_open_all", {vehicle = vehicle})
        end
    end,
    
    CloseAllDoors = function()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, true)
        
        if vehicle ~= 0 then
            for i = 0, 5 do
                SetVehicleDoorShut(vehicle, i, false)
            end
            ShowNotification("Toutes les portes fermées", "success")
            TriggerServerEvent("kt_context:logVehicleAction", "doors_close_all", {vehicle = vehicle})
        end
    end,
    
    OpenAllWindows = function()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            for i = 0, 3 do
                RollDownWindow(vehicle, i)
            end
            ShowNotification("Toutes les vitres baissées", "info")
        end
    end,
    
    CloseAllWindows = function()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            for i = 0, 3 do
                RollUpWindow(vehicle, i)
            end
            ShowNotification("Toutes les vitres remontées", "info")
        end
    end,
    
    ToggleLights = function()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            local lightsOn, highBeamsOn = GetVehicleLightsState(vehicle)
            SetVehicleLights(vehicle, lightsOn == 1 and 0 or 2)
            ShowNotification(lightsOn == 1 and "Lumières éteintes" or "Lumières allumées", "info")
        end
    end,
    
    Honk = function()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            StartVehicleHorn(vehicle, 1000, GetHashKey("HELDDOWN"), false)
        end
    end,
    
    ToggleSeatbelt = function()
        TriggerEvent("seatbelt:toggle")
        ShowNotification("Ceinture toggle", "info")
    end
}

QuickActions.Player = {
    HandsUp = function()
        local ped = PlayerPedId()
        
        if not IsPedInAnyVehicle(ped, false) then
            RequestAnimDict("random@mugging3")
            while not HasAnimDictLoaded("random@mugging3") do Wait(10) end
            
            if not IsEntityPlayingAnim(ped, "random@mugging3", "handsup_standing_base", 3) then
                TaskPlayAnim(ped, "random@mugging3", "handsup_standing_base", 8.0, -8.0, -1, 50, 0, false, false, false)
                ShowNotification("🙌 Mains en l'air", "info")
                TriggerServerEvent("kt_context:logPlayerAction", "handsup", nil)
            else
                ClearPedTasks(ped)
                ShowNotification("Animation arrêtée", "info")
            end
        end
    end,

    SitGround = function()
        local ped = PlayerPedId()
        
        if not IsPedInAnyVehicle(ped, false) then
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_PICNIC", 0, true)
            ShowNotification("Vous vous êtes assis", "info")
            TriggerServerEvent("kt_context:logPlayerAction", "sit", nil)
        end
    end,
    
    LayDown = function()
        local ped = PlayerPedId()
        
        if not IsPedInAnyVehicle(ped, false) then
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SUNBATHE_BACK", 0, true)
            ShowNotification("Vous vous êtes allongé", "info")
            TriggerServerEvent("kt_context:logPlayerAction", "laydown", nil)
        end
    end,
    
    StopAnim = function()
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        ShowNotification("Animation arrêtée", "info")
    end,
    
    Crouch = function()
        local ped = PlayerPedId()
        
        if not IsPedInAnyVehicle(ped, false) then
            RequestAnimSet("move_ped_crouched")
            while not HasAnimSetLoaded("move_ped_crouched") do Wait(10) end
            
            if not IsPedUsingActionMode(ped) then
                SetPedMovementClipset(ped, "move_ped_crouched", 0.25)
                SetPedStrafeClipset(ped, "move_ped_crouched_strafing")
                ShowNotification("Mode accroupi activé", "info")
            else
                ResetPedMovementClipset(ped, 0.25)
                ResetPedStrafeClipset(ped)
                ShowNotification("Mode accroupi désactivé", "info")
            end
        end
    end,
    
    Pointing = function()
        local ped = PlayerPedId()
        TriggerEvent("gestures:pointing")
        ShowNotification("👉 Pointer activé", "info")
    end,
    
    Ragdoll = function()
        local ped = PlayerPedId()
        SetPedToRagdoll(ped, 5000, 5000, 0, true, true, false)
        ShowNotification("Ragdoll activé", "info")
    end
}

QuickActions.General = {
    ShowCoords = function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        ShowNotification(
            string.format("📍 X: %.2f | Y: %.2f | Z: %.2f | H: %.2f", 
                coords.x, coords.y, coords.z, heading),
            "info"
        )
        
        local coordStr = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", 
            coords.x, coords.y, coords.z, heading)
        
        TriggerEvent('chat:addMessage', {
            color = {59, 130, 246},
            args = {"[Coords]", coordStr}
        })
        
        print(coordStr)
    end,

    ToggleHUD = function()
        local currentState = IsHudHidden()
        DisplayHud(currentState)
        DisplayRadar(currentState)
        ShowNotification(currentState and "HUD activé" or "HUD désactivé", "info")
    end,

    ToggleUI = function()
        local currentState = not IsMinimapRendering()
        DisplayRadar(not currentState)
        ShowNotification(currentState and "Minimap activée" or "Minimap désactivée", "info")
    end,
    
    CleanScreenshot = function()
        DisplayHud(false)
        DisplayRadar(false)
        ShowNotification("📸 Mode photo activé (5s)", "success")
        
        SetTimeout(5000, function()
            DisplayHud(true)
            DisplayRadar(true)
            ShowNotification("Mode normal rétabli", "info")
        end)
    end,
    
    CopyCoords = function()
        QuickActions.General.ShowCoords()
    end
}

QuickActions.Admin = {
    Heal = function()
        if IsPlayerAceAllowed(PlayerId(), "admin") then
            local ped = PlayerPedId()
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
            ShowNotification("❤️ Santé restaurée", "success")
            TriggerServerEvent("kt_context:logAdminAction", "heal", nil, "Self heal")
        else
            ShowNotification("Accès refusé", "error")
        end
    end,
    
    GiveArmor = function()
        if IsPlayerAceAllowed(PlayerId(), "admin") then
            local ped = PlayerPedId()
            SetPedArmour(ped, 100)
            ShowNotification("🛡️ Armure restaurée", "success")
            TriggerServerEvent("kt_context:logAdminAction", "armor", nil, "Self armor")
        else
            ShowNotification("Accès refusé", "error")
        end
    end,
    
    RepairVehicle = function()
        if IsPlayerAceAllowed(PlayerId(), "admin") then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle ~= 0 then
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleUndriveable(vehicle, false)
                SetVehicleEngineOn(vehicle, true, false)
                SetVehicleDirtLevel(vehicle, 0.0)
                ShowNotification("🔧 Véhicule réparé", "success")
                TriggerServerEvent("kt_context:logAdminAction", "repair_vehicle", nil, "Vehicle repair")
            else
                ShowNotification("Vous devez être dans un véhicule", "warning")
            end
        else
            ShowNotification("Accès refusé", "error")
        end
    end,

    DeleteVehicle = function()
        if IsPlayerAceAllowed(PlayerId(), "admin") then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, true)
            
            if vehicle ~= 0 then
                SetEntityAsMissionEntity(vehicle, true, true)
                DeleteVehicle(vehicle)
                ShowNotification("🗑️ Véhicule supprimé", "success")
                TriggerServerEvent("kt_context:logAdminAction", "delete_vehicle", nil, "Vehicle deleted")
            else
                ShowNotification("Aucun véhicule proche", "warning")
            end
        else
            ShowNotification("Accès refusé", "error")
        end
    end,
    
    TeleportToWaypoint = function()
        if IsPlayerAceAllowed(PlayerId(), "admin") then
            local waypoint = GetFirstBlipInfoId(8)
            
            if DoesBlipExist(waypoint) then
                local coords = GetBlipInfoIdCoord(waypoint)
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
                local z = found and groundZ or coords.z
                
                if vehicle ~= 0 then
                    SetEntityCoords(vehicle, coords.x, coords.y, z + 1.0)
                else
                    SetEntityCoords(ped, coords.x, coords.y, z + 1.0)
                end
                
                ShowNotification("📍 Téléporté au waypoint", "success")
                TriggerServerEvent("kt_context:logAdminAction", "tp_waypoint", nil, "Teleport to waypoint")
            else
                ShowNotification("Aucun waypoint placé", "warning")
            end
        else
            ShowNotification("Accès refusé", "error")
        end
    end,
    
    ToggleGodMode = function()
        if IsPlayerAceAllowed(PlayerId(), "admin") then
            local ped = PlayerPedId()
            local invincible = GetPlayerInvincible(PlayerId())
            SetEntityInvincible(ped, not invincible)
            ShowNotification(invincible and "God Mode désactivé" or "God Mode activé", "info")
            TriggerServerEvent("kt_context:logAdminAction", "god_mode", nil, "God mode toggle")
        else
            ShowNotification("Accès refusé", "error")
        end
    end,
    
    ToggleInvisible = function()
        if IsPlayerAceAllowed(PlayerId(), "admin") then
            local ped = PlayerPedId()
            local visible = IsEntityVisible(ped)
            SetEntityVisible(ped, not visible, false)
            ShowNotification(visible and "Invisible activé" or "Visible", "info")
            TriggerServerEvent("kt_context:logAdminAction", "invisible", nil, "Invisible toggle")
        else
            ShowNotification("Accès refusé", "error")
        end
    end
}

RegisterCommand("handsup", QuickActions.Player.HandsUp, false)
RegisterCommand("sit", QuickActions.Player.SitGround, false)
RegisterCommand("lay", QuickActions.Player.LayDown, false)
RegisterCommand("stopanim", QuickActions.Player.StopAnim, false)
RegisterCommand("crouch", QuickActions.Player.Crouch, false)
RegisterCommand("coords", QuickActions.General.ShowCoords, false)
RegisterCommand("screenshot", QuickActions.General.CleanScreenshot, false)
RegisterCommand("togglehud", QuickActions.General.ToggleHUD, false)

RegisterCommand("heal", QuickActions.Admin.Heal, false)
RegisterCommand("armor", QuickActions.Admin.GiveArmor, false)
RegisterCommand("fix", QuickActions.Admin.RepairVehicle, false)
RegisterCommand("dv", QuickActions.Admin.DeleteVehicle, false)
RegisterCommand("tpw", QuickActions.Admin.TeleportToWaypoint, false)
RegisterCommand("god", QuickActions.Admin.ToggleGodMode, false)
RegisterCommand("invis", QuickActions.Admin.ToggleInvisible, false)


_G.QuickActions = QuickActions