-- =============================================
-- MENU CONTEXTUEL — PRINCIPAL
-- =============================================

local isMenuOpen    = false
local menuHistory   = {}   -- pile pour la navigation "retour"

-- ─── Ouverture ──────────────────────────────────────────────────────────────
---@param x        number   Position X écran (px)
---@param y        number   Position Y écran (px)
---@param items    table    Liste d'items (voir types NUI)
---@param title    string?  Titre affiché dans le header
---@param options  table?   {theme, animate, noHistory}
function OpenContextMenu(x, y, items, title, options)
    if isMenuOpen then
        CloseContextMenu()
    end

    if not items or #items == 0 then
        print('[KT Context] OpenContextMenu — aucun item fourni')
        return
    end

    options = options or {}

    -- Validation légère
    local ok, reason = Validators.MenuItems(items)
    if not ok then
        print('[KT Context] Items invalides: ' .. reason)
        return
    end

    isMenuOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        type = 'openContextMenu',
        data = {
            x       = x       or 500,
            y       = y       or 300,
            items   = items,
            title   = title   or 'Menu',
            theme   = options.theme   or 'dark',
            animate = options.animate ~= false,
        }
    })

    TriggerServerEvent('kt_context:logMenuOpen', title or 'unknown')
end

-- ─── Fermeture ──────────────────────────────────────────────────────────────
function CloseContextMenu()
    if not isMenuOpen then return end
    isMenuOpen = false
    menuHistory = {}
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeContextMenu' })
end

-- ─── Statut ─────────────────────────────────────────────────────────────────
function IsMenuOpen()
    return isMenuOpen
end

-- ─── Sécurité : reset au respawn / stop ressource ───────────────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and isMenuOpen then
        isMenuOpen = false
        menuHistory = {}
        SetNuiFocus(false, false)
    end
end)

AddEventHandler('playerSpawned', function()
    if isMenuOpen then
        isMenuOpen = false
        menuHistory = {}
        SetNuiFocus(false, false)
        SendNUIMessage({ type = 'closeContextMenu' })
    end
end)

-- ─── Gestionnaires d'actions ─────────────────────────────────────────────────
local actionHandlers = {

    -- Inventaire
    inventory = function()
        if GetResourceState('kt_inventory') == 'started' then
            TriggerEvent('kt_inventory:openInventory')
        end
    end,

    phone = function()
        TriggerEvent('kt_phone:open')
    end,

    -- Animations joueur
    wave = function()
        local ped = PlayerPedId()
        RequestAnimDict('gestures@m@standing@casual')
        while not HasAnimDictLoaded('gestures@m@standing@casual') do Wait(10) end
        TaskPlayAnim(ped, 'gestures@m@standing@casual', 'gesture_hello', 8.0, -8.0, -1, 0, 0, false, false, false)
    end,

    handsup = function()
        local ped = PlayerPedId()
        RequestAnimDict('random@mugging3')
        while not HasAnimDictLoaded('random@mugging3') do Wait(10) end
        TaskPlayAnim(ped, 'random@mugging3', 'handsup_standing_base', 8.0, -8.0, -1, 50, 0, false, false, false)
    end,

    sit = function()
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_PICNIC', 0, true)
    end,

    lay = function()
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_SUNBATHE_BACK', 0, true)
    end,

    dance = function()
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_PARTYING', 0, true)
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
            ShowNotification(locked == 1 and L('vehicle_locked') or L('vehicle_unlocked'), locked == 1 and 'success' or 'info')
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

    -- Admin
    adm_coords_self = function()
        local coords = GetEntityCoords(PlayerPedId())
        ShowNotification(('📍 %s'):format(FormatCoords(coords)), 'info')
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
        local ped = PlayerPedId()
        local inv = GetPlayerInvincible(PlayerId())
        SetEntityInvincible(ped, not inv)
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
        if not IsPlayerAdmin() then return end
        local ped = PlayerPedId()
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ShowNotification('❤️ Santé restaurée', 'success')
        TriggerServerEvent('kt_context:logAdminAction', 'heal_self', nil, 'Self heal')
    end,

    adm_armor_self = function()
        if not IsPlayerAdmin() then return end
        SetPedArmour(PlayerPedId(), 100)
        ShowNotification('🛡️ Armure restaurée', 'success')
        TriggerServerEvent('kt_context:logAdminAction', 'armor_self', nil, 'Self armor')
    end,

    adm_repair = function()
        if not IsPlayerAdmin() then return end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleFixed(veh)
            SetVehicleDeformationFixed(veh)
            SetVehicleUndriveable(veh, false)
            SetVehicleEngineOn(veh, true, false)
            SetVehicleDirtLevel(veh, 0.0)
            ShowNotification('🔧 Véhicule réparé', 'success')
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
            ShowNotification('🗑️ Véhicule supprimé', 'success')
            TriggerServerEvent('kt_context:logAdminAction', 'delete_vehicle', nil, 'Delete')
        else
            ShowNotification('Aucun véhicule proche', 'warning')
        end
    end,

    adm_refuel = function()
        if not IsPlayerAdmin() then return end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleFuelLevel(veh, 100.0)
            ShowNotification('⛽ Réservoir rempli', 'success')
        end
    end,
}

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────
RegisterNUICallback('menuAction', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        cb('error')
        return
    end

    local handler = actionHandlers[data.id]
    if handler then
        handler()
    else
        -- Événement générique pour les handlers externes
        TriggerEvent('kt_context:action', data.id, data)
    end
    cb('ok')
end)

RegisterNUICallback('menuClosed', function(_, cb)
    isMenuOpen = false
    menuHistory = {}
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ─── Blocage des contrôles quand le menu est ouvert ──────────────────────────
local BLOCKED_CONTROLS = { 1, 2, 24, 25, 142, 18, 322, 106, 68 }

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
exports('OpenContextMenu',  OpenContextMenu)
exports('CloseContextMenu', CloseContextMenu)
exports('IsMenuOpen',       function() return isMenuOpen end)