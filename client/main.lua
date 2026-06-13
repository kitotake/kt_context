-- =============================================
-- MENU CONTEXTUEL - PRINCIPAL - v3.2
-- =============================================

local isMenuOpen      = false
local menuHistory     = {}
local _menuOpenCoords = nil

-- ─── Ouverture ──────────────────────────────────────────────────────────────
function OpenContextMenu(x, y, items, title, options)
    if isMenuOpen then CloseContextMenu() end

    if not items or #items == 0 then
        print('[KT Context] OpenContextMenu - aucun item fourni')
        return
    end

    options = options or {}

    local ok, reason = Validators.MenuItems(items)
    if not ok then
        print('[KT Context] Items invalides: ' .. reason)
        return
    end

    isMenuOpen      = true
    _menuOpenCoords = GetEntityCoords(PlayerPedId())

    if not IsCursorActive() then
        SetNuiFocus(true, true)
    end

    SendNUIMessage({
        type = 'openContextMenu',
        data = {
            x       = x     or 500,
            y       = y     or 300,
            items   = items,
            title   = title or 'Menu',
            theme   = options.theme   or 'dark',
            animate = options.animate ~= false,
        }
    })

    TriggerServerEvent('kt_context:logMenuOpen', title or 'unknown')
end

-- ─── Fermeture ──────────────────────────────────────────────────────────────
function CloseContextMenu()
    if not isMenuOpen then return end
    isMenuOpen      = false
    menuHistory     = {}
    _menuOpenCoords = nil

    SendNUIMessage({ type = 'closeContextMenu' })

    if not IsCursorActive() then
        SetNuiFocus(false, false)
    end
end

function IsMenuOpen()
    return isMenuOpen
end

-- ─── Check distance depuis ouverture ─────────────────────────────────────────
local function _checkMenuDistance()
    if not _menuOpenCoords then return true end
    local maxDist = Config.Limits and Config.Limits.MaxInteractMoveDistance or 3.0
    if #(GetEntityCoords(PlayerPedId()) - _menuOpenCoords) > maxDist then
        ShowNotification(L('too_far'), 'warning')
        CloseContextMenu()
        return false
    end
    return true
end

-- ─── Helpers animations ──────────────────────────────────────────────────────
local function _checkAnimCooldown()
    if HasCooldown('anim_global') then
        ShowNotification(L('cooldown_wait'), 'warning')
        return false
    end
    if Config.Limits and Config.Limits.AnimBlockInVehicle then
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            ShowNotification(L('anim_vehicle'), 'warning')
            return false
        end
    end
    return true
end

local function _playAnimHandler(dict, clip, flags)
    if not _checkAnimCooldown() then return end
    SetCooldown('anim_global', Config.Limits and Config.Limits.AnimCooldown or 2000)
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10); t = t + 10
        if t > 5000 then return end
    end
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, flags or 0, 0, false, false, false)
end

-- ─── Sécurité resource stop ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and isMenuOpen then
        isMenuOpen      = false
        menuHistory     = {}
        _menuOpenCoords = nil
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)

AddEventHandler('playerSpawned', function()
    if isMenuOpen then
        isMenuOpen      = false
        menuHistory     = {}
        _menuOpenCoords = nil
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ type = 'closeContextMenu' })
    end
end)

-- ─── Handlers d'actions statiques ────────────────────────────────────────────
local actionHandlers = {

    inventory = function()
        if GetResourceState('kt_inventory') == 'started' then
            TriggerEvent('kt_inventory:openInventory')
        end
    end,

    phone = function() TriggerEvent('kt_phone:open') end,

    -- ── Animations ───────────────────────────────────────────────────────────
    wave    = function() _playAnimHandler('gestures@m@standing@casual', 'gesture_hello', 0) end,
    handsup = function() _playAnimHandler('random@mugging3', 'handsup_standing_base', 50) end,

    crossarms = function()
    _playAnimHandler(
        'amb@world_human_hang_out_street@female_arms_crossed@idle_a',
        'idle_b',
        49
    )
end,

    sit = function()
        if not _checkAnimCooldown() then return end
        SetCooldown('anim_global', Config.Limits and Config.Limits.AnimCooldown or 2000)
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_PICNIC', 0, true)
    end,   

    lay = function()
        if not _checkAnimCooldown() then return end
        SetCooldown('anim_global', Config.Limits and Config.Limits.AnimCooldown or 2000)
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_SUNBATHE_BACK', 0, true)
    end,

    dance = function()
        if not _checkAnimCooldown() then return end
        SetCooldown('anim_global', Config.Limits and Config.Limits.AnimCooldown or 2000)
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_PARTYING', 0, true)
    end,

    stopanim = function() ClearPedTasks(PlayerPedId()) end,
    stop     = function() ClearPedTasks(PlayerPedId()) end,

    -- ── Véhicule ─────────────────────────────────────────────────────────────
    veh_lock = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            local locked = GetVehicleDoorLockStatus(veh)
            SetVehicleDoorsLocked(veh, locked == 1 and 2 or 1)
            ShowNotification(
                locked == 1 and L('vehicle_locked') or L('vehicle_unlocked'),
                locked == 1 and 'success' or 'info'
            )
        end
    end,

    veh_engine = function()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            SetVehicleEngineOn(veh, not GetIsVehicleEngineRunning(veh), false, true)
        end
    end,

    veh_lights = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            local on, _ = GetVehicleLightsState(veh)
            SetVehicleLights(veh, on == 1 and 0 or 2)
            ShowNotification(on == 1 and 'Lumières éteintes' or 'Lumières allumées', 'info')
        end
    end,

    door_fl        = function() ToggleVehicleDoor(0) end,
    door_fr        = function() ToggleVehicleDoor(1) end,
    door_rl        = function() ToggleVehicleDoor(2) end,
    door_rr        = function() ToggleVehicleDoor(3) end,
    door_hood      = function() ToggleVehicleDoor(4) end,
    door_trunk     = function() ToggleVehicleDoor(5) end,

    door_all_open = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            for i = 0, 5 do SetVehicleDoorOpen(veh, i, false, false) end
            ShowNotification('Toutes les portes ouvertes', 'success')
        end
    end,

    door_all_close = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            for i = 0, 5 do SetVehicleDoorShut(veh, i, false) end
            ShowNotification('Toutes les portes fermées', 'success')
        end
    end,

    win_up = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            for i = 0, 3 do RollUpWindow(veh, i) end
        else
            ShowNotification('Vous devez être dans un véhicule', 'warning')
        end
    end,

    win_down = function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            for i = 0, 3 do RollDownWindow(veh, i) end
        else
            ShowNotification('Vous devez être dans un véhicule', 'warning')
        end
    end,

    -- ── Admin ────────────────────────────────────────────────────────────────
    adm_coords_self = function()
        ShowNotification(('📍 %s'):format(FormatCoords(GetEntityCoords(PlayerPedId()))), 'info')
    end,

    adm_tp_waypoint = function()
        if not IsPlayerAdmin() then return end
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
            ShowNotification('📍 Téléporté au waypoint', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'tp_waypoint', nil, 'TP waypoint')
        else
            ShowNotification('Aucun waypoint placé', 'warning')
        end
    end,

    adm_god = function()
        if not IsPlayerAdmin() then return end
        local inv = GetPlayerInvincible(PlayerId())
        SetEntityInvincible(PlayerPedId(), not inv)
        ShowNotification(inv and 'God Mode désactivé' or 'God Mode activé', 'info')
        TriggerServerEvent('kt_context:logAdminAction', 'god_mode', nil, 'Toggle')
    end,

    adm_invisible = function()
        if not IsPlayerAdmin() then return end
        local ped = PlayerPedId()
        local vis = IsEntityVisible(ped)
        SetEntityVisible(ped, not vis, false)
        ShowNotification(vis and 'Invisible activé' or 'Visible', 'info')
        TriggerServerEvent('kt_context:logAdminAction', 'invisible', nil, 'Toggle')
    end,

    adm_heal_self = function()
        if not IsPlayerAdmin() and not IsPlayerStaff() then return end
        local ped = PlayerPedId()
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ShowNotification('Santé restaurée', 'success')
        TriggerServerEvent('kt_context:logAdminAction', 'heal_self', nil, 'Self heal')
    end,

    adm_armor_self = function()
        if not IsPlayerAdmin() and not IsPlayerStaff() then return end
        SetPedArmour(PlayerPedId(), 100)
        ShowNotification('Armure restaurée', 'success')
        TriggerServerEvent('kt_context:logAdminAction', 'armor_self', nil, 'Self armor')
    end,

    adm_repair = function()
        if not IsPlayerAdmin() and not IsPlayerStaff() then return end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleFixed(veh)
            SetVehicleDeformationFixed(veh)
            SetVehicleUndriveable(veh, false)
            SetVehicleEngineOn(veh, true, false)
            SetVehicleDirtLevel(veh, 0.0)
            ShowNotification('Véhicule réparé', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'repair_vehicle', nil, 'Repair')
        else
            ShowNotification('Pas dans un véhicule', 'warning')
        end
    end,

    adm_delete = function()
        if not IsPlayerAdmin() then return end
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh)
            ShowNotification('Véhicule supprimé', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'delete_vehicle', nil, 'Delete')
        else
            ShowNotification('Aucun véhicule proche', 'warning')
        end
    end,

    adm_refuel = function()
        if not IsPlayerAdmin() and not IsPlayerStaff() then return end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleFuelLevel(veh, 100.0)
            ShowNotification('Réservoir rempli', 'success')
        end
    end,

    -- ── Props ────────────────────────────────────────────────────────────────
    placeprop = function()
        if PropManager then PropManager:Place(Config.Rotation.DefaultPropName) end
    end,

    propmenu = function()
        if PropManager and PropManager.active and DoesEntityExist(PropManager.active) then
            PropManager:OpenMenu()
        else
            ShowNotification('Aucun objet actif', 'warning')
        end
    end,

    -- ── Overlay checkboxes ────────────────────────────────────────────────────
    -- Ces actions sont dispatché vers overlay.lua via kt_context:action
    -- (voir client/alts_client/overlay.lua)
}

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────
RegisterNUICallback('menuAction', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        cb('error')
        return
    end

    if not _checkMenuDistance() then
        cb('ok')
        return
    end

    -- Priorité 1 : actions dynamiques (Build*Menu)
    if ExecutePendingAction and ExecutePendingAction(data.id) then
        cb('ok')
        return
    end

    -- Priorité 2 : handlers statiques
    local handler = actionHandlers[data.id]
    if handler then
        handler()
        cb('ok')
        return
    end

    -- Priorité 3 : fallback event générique
    TriggerEvent('kt_context:action', data.id, data)
    cb('ok')
end)

-- Callback checkbox : envoyé quand l'utilisateur coche/décoche
RegisterNUICallback('checkboxAction', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        cb('error')
        return
    end
    -- Dispatch vers l'event overlay ou autre handler
    TriggerEvent('kt_context:checkboxAction', data.id, data.checked, data)
    cb('ok')
end)

RegisterNUICallback('menuClosed', function(_, cb)
    isMenuOpen      = false
    menuHistory     = {}
    _menuOpenCoords = nil
    if not IsCursorActive() then
        SetNuiFocus(false, false)
    end
    cb('ok')
end)

-- ─── Blocage des contrôles menu ouvert ────────────────────────────────────────
local BLOCKED_CONTROLS = { 24, 25, 142, 18, 322, 106, 68 }

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

-- ─── Fermeture auto si joueur trop loin ───────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        if isMenuOpen and _menuOpenCoords then
            local maxDist = Config.Limits and Config.Limits.MaxInteractMoveDistance or 3.0
            if #(GetEntityCoords(PlayerPedId()) - _menuOpenCoords) > maxDist then
                ShowNotification(L('too_far'), 'warning')
                CloseContextMenu()
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────
exports('OpenContextMenu',  OpenContextMenu)
exports('CloseContextMenu', CloseContextMenu)
exports('IsMenuOpen',       function() return isMenuOpen end)
