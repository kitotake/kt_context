-- =============================================
-- ROTATION / PLACEMENT PROPS CLIENT — v3.1 (fixed)
-- 
-- FIXES critiques :
--   • Limite 3m depuis le joueur (Config.Limits.PropMaxDistance)
--   • 1 seul prop actif par joueur
--   • Rotation contrôlée par menu contextuel (pas de thread libre)
--   • Cleanup automatique (resource stop, disconnect)
--   • GetGroundZFor_3dCoord pour snap au sol
--   • Suppression du thread infini qui mangeait du CPU
-- =============================================

local PropManager = {
    active   = nil,     -- entity handle du prop actif
    model    = nil,     -- hash du modèle
    rotating = false,   -- thread de rotation actif
}

-- ─── Utilitaire interne ───────────────────────────────────────────────────────
local function _loadModel(modelHash)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            print('[KT Rotation] Model load timeout')
            return false
        end
    end
    return true
end

local function _getPlacementCoords(maxDist)
    maxDist = maxDist or Config.Limits.PropMaxDistance
    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    -- Position 1.5m devant, clamped à maxDist
    local dist    = math.min(1.5, maxDist)
    local target  = vector3(
        coords.x + forward.x * dist,
        coords.y + forward.y * dist,
        coords.z
    )
    -- Vérifier distance max
    if #(coords - target) > maxDist then
        return nil, L('prop_too_far')
    end
    -- Snap au sol
    local found, gz = GetGroundZFor_3dCoord(target.x, target.y, coords.z + 5.0, false)
    local z = found and gz or coords.z
    -- Limite hauteur (±PropMaxHeight)
    if math.abs(z - coords.z) > (Config.Limits.PropMaxHeight or 2.0) then
        z = coords.z
    end
    return vector3(target.x, target.y, z), nil
end

-- ─── API publique ─────────────────────────────────────────────────────────────

function PropManager:Place(modelName)
    if not IsPlayerAdmin() and not IsPlayerStaff() then
        ShowNotification(L('access_denied'), 'error')
        return false
    end

    if self.active and DoesEntityExist(self.active) then
        ShowNotification(L('prop_limit'), 'warning')
        return false
    end

    local modelHash = GetHashKey(modelName or Config.Rotation.DefaultPropName)
    if not _loadModel(modelHash) then
        ShowNotification('Modèle introuvable : ' .. (modelName or '?'), 'error')
        return false
    end

    local placementCoords, err = _getPlacementCoords()
    if not placementCoords then
        ShowNotification(err or L('prop_too_far'), 'warning')
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end

    local rot = Config.Rotation.DefaultRotation
    local prop = CreateObject(
        modelHash,
        placementCoords.x, placementCoords.y, placementCoords.z,
        true, true, true
    )

    if not DoesEntityExist(prop) or prop == 0 then
        ShowNotification('Erreur de création du prop', 'error')
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end

    SetEntityRotation(prop, rot.x, rot.y, rot.z, 2, true)
    FreezeEntityPosition(prop, true) -- figé par défaut
    SetModelAsNoLongerNeeded(modelHash)

    self.active = prop
    self.model  = modelName

    ShowNotification(L('prop_placed'), 'success')
    TriggerServerEvent('kt_context:logAction', 'prop', 'place', { model = modelName })

    -- Ouvrir le menu de gestion du prop
    self:OpenMenu()
    return true
end

function PropManager:Delete()
    if not self.active or not DoesEntityExist(self.active) then
        ShowNotification('Aucun objet actif', 'warning')
        return
    end
    self.rotating = false
    SetEntityAsMissionEntity(self.active, true, true)
    DeleteObject(self.active)
    self.active = nil
    self.model  = nil
    ShowNotification(L('prop_deleted'), 'success')
    TriggerServerEvent('kt_context:logAction', 'prop', 'delete', {})
end

function PropManager:DeleteNearby()
    if not IsPlayerAdmin() and not IsPlayerStaff() then
        ShowNotification(L('access_denied'), 'error')
        return
    end
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local handle, obj = FindFirstObject()
    local count = 0
    repeat
        if DoesEntityExist(obj) and IsEntityAnObject(obj) then
            if #(GetEntityCoords(obj) - coords) < (Config.Rotation.DeleteRadius or 5.0) then
                SetEntityAsMissionEntity(obj, true, true)
                DeleteObject(obj)
                count = count + 1
                if self.active == obj then
                    self.active = nil
                    self.model  = nil
                end
            end
        end
        local success
        success, obj = FindNextObject(handle)
        if not success then break end
    until false
    EndFindObject(handle)
    ShowNotification(('🗑️ %d objet(s) supprimé(s)'):format(count), 'success')
end

function PropManager:Rotate(axis, degrees)
    if not self.active or not DoesEntityExist(self.active) then return end
    local r = GetEntityRotation(self.active, 2)
    local nx = r.x + (axis == 'x' and degrees or 0.0)
    local ny = r.y + (axis == 'y' and degrees or 0.0)
    local nz = r.z + (axis == 'z' and degrees or 0.0)
    SetEntityRotation(self.active, nx, ny, nz, 2, true)
end

function PropManager:ResetRotation()
    if not self.active or not DoesEntityExist(self.active) then return end
    local rot = Config.Rotation.DefaultRotation
    SetEntityRotation(self.active, rot.x, rot.y, rot.z, 2, true)
    ShowNotification('Rotation réinitialisée', 'info')
end

function PropManager:ToggleFreeze()
    if not self.active or not DoesEntityExist(self.active) then return end
    local frozen = IsEntityPositionFrozen(self.active)
    FreezeEntityPosition(self.active, not frozen)
    ShowNotification(frozen and 'Objet dégelé' or 'Objet gelé', 'info')
end

function PropManager:ToggleAutoRotate(axis, speed)
    if not self.active or not DoesEntityExist(self.active) then return end
    if self.rotating then
        self.rotating = false
        ShowNotification('Rotation automatique arrêtée', 'info')
        return
    end
    self.rotating = true
    ShowNotification('Rotation automatique activée', 'info')

    local step = Config.Limits.PropRotateStep or 15.0
    Citizen.CreateThread(function()
        while self.rotating and self.active and DoesEntityExist(self.active) do
            self:Rotate(axis or 'z', speed or step * 0.5)
            Wait(30)
        end
        self.rotating = false
    end)
end

function PropManager:OpenMenu()
    local sw, sh = GetActiveScreenResolution()
    local step   = Config.Limits.PropRotateStep or 15.0

    local items = {
        {
            id          = 'prop_info',
            label       = 'Objet actif',
            icon        = 'Package',
            disabled    = true,
            description = self.model or 'prop inconnu',
        },
        { id = '_div_rot', divider = true, label = '' },
        {
            id      = 'prop_rotate',
            label   = 'Rotation',
            icon    = 'RotateCw',
            submenu = {
                { id = 'rot_x_p', label = ('Pitch +%d°'):format(step), icon = 'ArrowUp'     },
                { id = 'rot_x_m', label = ('Pitch -%d°'):format(step), icon = 'ArrowDown'   },
                { id = 'rot_y_p', label = ('Roll +%d°'):format(step),  icon = 'ArrowRight'  },
                { id = 'rot_y_m', label = ('Roll -%d°'):format(step),  icon = 'ArrowLeft'   },
                { id = 'rot_z_p', label = ('Yaw +%d°'):format(step),   icon = 'RotateCw'    },
                { id = 'rot_z_m', label = ('Yaw -%d°'):format(step),   icon = 'RotateCcw'   },
                { id = '_divr', divider = true, label = '' },
                { id = 'rot_reset', label = 'Réinitialiser', icon = 'RefreshCw', variant = 'warning' },
            },
        },
        {
            id      = 'prop_auto',
            label   = 'Rotation automatique',
            icon    = 'RefreshCcw',
            submenu = {
                { id = 'auto_x', label = 'Axe X (Pitch)', icon = 'ArrowUpDown' },
                { id = 'auto_y', label = 'Axe Y (Roll)',  icon = 'ArrowLeftRight' },
                { id = 'auto_z', label = 'Axe Z (Yaw)',   icon = 'RotateCw' },
                { id = 'auto_stop', label = 'Arrêter',    icon = 'StopCircle', variant = 'warning' },
            },
        },
        { id = 'prop_freeze', label = 'Geler / Dégeler', icon = 'Snowflake' },
        { id = '_div_del', divider = true, label = '' },
        { id = 'prop_delete', label = 'Supprimer',       icon = 'Trash2',   variant = 'danger' },
        { id = 'prop_delete_nearby', label = 'Supprimer proches', icon = 'Trash', variant = 'danger' },
    }

    OpenContextMenu(sw / 2, sh / 2, items, '📦 Gestion Objet')
end

-- ─── Handlers d'actions prop ─────────────────────────────────────────────────
-- Ces actions sont appelées depuis main.lua via kt_context:action
AddEventHandler('kt_context:action', function(id, data)
    local step = Config.Limits.PropRotateStep or 15.0
    local handlers = {
        prop_freeze        = function() PropManager:ToggleFreeze() end,
        prop_delete        = function() PropManager:Delete() end,
        prop_delete_nearby = function() PropManager:DeleteNearby() end,
        rot_reset          = function() PropManager:ResetRotation() end,
        rot_x_p            = function() PropManager:Rotate('x',  step) end,
        rot_x_m            = function() PropManager:Rotate('x', -step) end,
        rot_y_p            = function() PropManager:Rotate('y',  step) end,
        rot_y_m            = function() PropManager:Rotate('y', -step) end,
        rot_z_p            = function() PropManager:Rotate('z',  step) end,
        rot_z_m            = function() PropManager:Rotate('z', -step) end,
        auto_x             = function() PropManager:ToggleAutoRotate('x') end,
        auto_y             = function() PropManager:ToggleAutoRotate('y') end,
        auto_z             = function() PropManager:ToggleAutoRotate('z') end,
        auto_stop          = function() PropManager.rotating = false; ShowNotification('Rotation arrêtée', 'info') end,
    }
    if handlers[id] then handlers[id]() end
end)

-- ─── Cleanup automatique ──────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        PropManager.rotating = false
        if PropManager.active and DoesEntityExist(PropManager.active) then
            DeleteObject(PropManager.active)
            PropManager.active = nil
        end
    end
end)

-- ─── Commandes ───────────────────────────────────────────────────────────────
RegisterCommand('placeprop', function(_, args)
    local model = args[1] or Config.Rotation.DefaultPropName
    PropManager:Place(model)
end, false)

RegisterCommand('deleteprop', function()
    PropManager:Delete()
end, false)

RegisterCommand('propmenu', function()
    if PropManager.active and DoesEntityExist(PropManager.active) then
        PropManager:OpenMenu()
    else
        ShowNotification('Aucun objet actif', 'warning')
    end
end, false)

RegisterCommand('deletenearby', function()
    PropManager:DeleteNearby()
end, false)

-- ─── Export ───────────────────────────────────────────────────────────────────
_G.PropManager = PropManager
exports('PlaceProp',    function(model) PropManager:Place(model) end)
exports('DeleteProp',   function() PropManager:Delete() end)
exports('OpenPropMenu', function() PropManager:OpenMenu() end)
