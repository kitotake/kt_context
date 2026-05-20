-- =============================================
-- ACTIONS RAPIDES — v3.1 (fixed)
-- FIXES :
--   - Cooldown animations via HasCooldown / SetCooldown
--   - IsPlayerStaff() pour heal/armor (pas seulement admin)
--   - Verification vehicule proche pour lock
-- =============================================

local QuickActions = {}

-- ── Vehicule ──────────────────────────────────────────────────────────────────
QuickActions.Vehicle = {

    ToggleLock = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            local locked = GetVehicleDoorLockStatus(veh)
            SetVehicleDoorsLocked(veh, locked == 1 and 2 or 1)
            ShowNotification(locked == 1 and L('vehicle_locked') or L('vehicle_unlocked'), 'info')
            TriggerServerEvent('kt_context:logVehicleAction', 'lock_toggle', { locked = locked == 1 })
        else
            ShowNotification(L('no_vehicle'), 'error')
        end
    end,

    ToggleEngine = function()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local on = GetIsVehicleEngineRunning(veh)
            SetVehicleEngineOn(veh, not on, false, true)
            ShowNotification(on and 'Moteur eteint' or 'Moteur allume', 'info')
        else
            ShowNotification('Vous devez etre conducteur', 'warning')
        end
    end,

    OpenAllDoors = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            for i = 0, 5 do SetVehicleDoorOpen(veh, i, false, false) end
            ShowNotification('Toutes les portes ouvertes', 'success')
        end
    end,

    CloseAllDoors = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            for i = 0, 5 do SetVehicleDoorShut(veh, i, false) end
            ShowNotification('Toutes les portes fermees', 'success')
        end
    end,

    ToggleLights = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            local lightsOn = GetVehicleLightsState(veh)
            SetVehicleLights(veh, lightsOn == 1 and 0 or 2)
            ShowNotification(lightsOn == 1 and 'Lumieres eteintes' or 'Lumieres allumees', 'info')
        end
    end,
}

-- ── Joueur ────────────────────────────────────────────────────────────────────
QuickActions.Player = {

    HandsUp = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            ShowNotification(L('anim_vehicle'), 'warning')
            return
        end
        if HasCooldown('anim_global') then
            ShowNotification(L('cooldown_wait'), 'warning')
            return
        end
        SetCooldown('anim_global', Config.Limits.AnimCooldown or 2000)
        RequestAnimDict('random@mugging3')
        while not HasAnimDictLoaded('random@mugging3') do Wait(10) end
        if not IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3) then
            TaskPlayAnim(ped, 'random@mugging3', 'handsup_standing_base', 8.0, -8.0, -1, 50, 0, false, false, false)
        else
            ClearPedTasks(ped)
        end
    end,

    SitGround = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then ShowNotification(L('anim_vehicle'), 'warning'); return end
        if HasCooldown('anim_global') then ShowNotification(L('cooldown_wait'), 'warning'); return end
        SetCooldown('anim_global', Config.Limits.AnimCooldown or 2000)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_PICNIC', 0, true)
    end,

    LayDown = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then ShowNotification(L('anim_vehicle'), 'warning'); return end
        if HasCooldown('anim_global') then ShowNotification(L('cooldown_wait'), 'warning'); return end
        SetCooldown('anim_global', Config.Limits.AnimCooldown or 2000)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_SUNBATHE_BACK', 0, true)
    end,

    StopAnim = function()
        ClearPedTasks(PlayerPedId())
        ShowNotification('Animation arretee', 'info')
    end,

    Dance = function()
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then ShowNotification(L('anim_vehicle'), 'warning'); return end
        if HasCooldown('anim_global') then ShowNotification(L('cooldown_wait'), 'warning'); return end
        SetCooldown('anim_global', Config.Limits.AnimCooldown or 2000)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_PARTYING', 0, true)
        ShowNotification('Danse', 'info')
    end,
}

-- ── Admin / Staff ─────────────────────────────────────────────────────────────
QuickActions.Admin = {

    Heal = function()
        if not IsPlayerAdmin() and not IsPlayerStaff() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        local ped = PlayerPedId()
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ShowNotification('Sante restauree', 'success')
        TriggerServerEvent('kt_context:logAdminAction', 'heal_self', nil, 'Self heal')
    end,

    GiveArmor = function()
        if not IsPlayerAdmin() and not IsPlayerStaff() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        SetPedArmour(PlayerPedId(), 100)
        ShowNotification('Armure restauree', 'success')
        TriggerServerEvent('kt_context:logAdminAction', 'armor_self', nil, 'Self armor')
    end,

    RepairVehicle = function()
        if not IsPlayerAdmin() and not IsPlayerStaff() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleFixed(veh)
            SetVehicleDeformationFixed(veh)
            SetVehicleUndriveable(veh, false)
            SetVehicleEngineOn(veh, true, false)
            SetVehicleDirtLevel(veh, 0.0)
            ShowNotification('Vehicule repare', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'repair_vehicle', nil, 'Repair')
        else
            ShowNotification('Pas dans un vehicule', 'warning')
        end
    end,

    DeleteVehicle = function()
        -- Suppression vehicule = admin uniquement (pas staff)
        if not IsPlayerAdmin() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh)
            ShowNotification('Vehicule supprime', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'delete_vehicle', nil, 'Delete')
        else
            ShowNotification('Aucun vehicule proche', 'warning')
        end
    end,

    TeleportToWaypoint = function()
        if not IsPlayerAdmin() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        local wp = GetFirstBlipInfoId(8)
        if DoesBlipExist(wp) then
            local coords = GetBlipInfoIdCoord(wp)
            local ped    = PlayerPedId()
            local veh    = GetVehiclePedIsIn(ped, false)
            local found, gz = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
            local z = found and gz or coords.z
            if veh ~= 0 then
                SetEntityCoords(veh, coords.x, coords.y, z + 1.0)
            else
                SetEntityCoords(ped, coords.x, coords.y, z + 1.0)
            end
            ShowNotification('Teleporte', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'tp_waypoint', nil, 'TP waypoint')
        else
            ShowNotification('Aucun waypoint place', 'warning')
        end
    end,

    ToggleGodMode = function()
        if not IsPlayerAdmin() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        local ped = PlayerPedId()
        local inv = GetPlayerInvincible(PlayerId())
        SetEntityInvincible(ped, not inv)
        ShowNotification(inv and 'God Mode desactive' or 'God Mode active', 'info')
        TriggerServerEvent('kt_context:logAdminAction', 'god_mode', nil, 'Toggle')
    end,

    ToggleInvisible = function()
        if not IsPlayerAdmin() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        local ped = PlayerPedId()
        local vis = IsEntityVisible(ped)
        SetEntityVisible(ped, not vis, false)
        ShowNotification(vis and 'Invisible active' or 'Visible', 'info')
        TriggerServerEvent('kt_context:logAdminAction', 'invisible', nil, 'Toggle')
    end,

    -- Seulement founder peut utiliser ces actions sensibles
    PlaceProp = function()
        if not IsPlayerAdmin() then
            ShowNotification(L('access_denied'), 'error')
            return
        end
        if PropManager then
            PropManager:Place(Config.Rotation.DefaultPropName)
        end
    end,
}

-- ── Commandes console ─────────────────────────────────────────────────────────
RegisterCommand('handsup',  QuickActions.Player.HandsUp,           false)
RegisterCommand('sit',      QuickActions.Player.SitGround,         false)
RegisterCommand('lay',      QuickActions.Player.LayDown,           false)
RegisterCommand('stopanim', QuickActions.Player.StopAnim,          false)
RegisterCommand('heal',     QuickActions.Admin.Heal,               false)
RegisterCommand('armor',    QuickActions.Admin.GiveArmor,          false)
RegisterCommand('fix',      QuickActions.Admin.RepairVehicle,      false)
RegisterCommand('dv',       QuickActions.Admin.DeleteVehicle,      false)
RegisterCommand('tpw',      QuickActions.Admin.TeleportToWaypoint, false)
RegisterCommand('god',      QuickActions.Admin.ToggleGodMode,      false)
RegisterCommand('invis',    QuickActions.Admin.ToggleInvisible,    false)

_G.QuickActions = QuickActions
