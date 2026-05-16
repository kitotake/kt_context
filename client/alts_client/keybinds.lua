-- =============================================
-- KEYBINDS
-- =============================================

local KeyBinds = { registered = {}, active = true }

function KeyBinds:Register(id, key, control, callback, description)
    if self.registered[id] then return false end
    self.registered[id] = {
        id          = id,
        key         = key,
        control     = control,
        callback    = callback,
        description = description or '',
        enabled     = true,
    }
    if RegisterKeyMapping then
        RegisterKeyMapping(id, description or id, 'keyboard', key)
    end
    return true
end

function KeyBinds:Toggle(id, state)
    if self.registered[id] then self.registered[id].enabled = state end
end

function KeyBinds:ToggleAll(state)
    self.active = state
end

-- Thread de lecture des keybinds
Citizen.CreateThread(function()
    while true do
        local sleep = 100
        if KeyBinds.active then
            sleep = 0
            for _, bind in pairs(KeyBinds.registered) do
                if bind.enabled and IsControlJustPressed(0, bind.control) then
                    if bind.callback then bind.callback() end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Enregistrement des keybinds par défaut (après 1s)
Citizen.CreateThread(function()
    Wait(1000)

    KeyBinds:Register('kt_menu_emotes', 'X', 73, function()
        local sw, sh = GetActiveScreenResolution()
        OpenContextMenu(sw/2, sh/2, {
            { id = 'wave',     label = 'Saluer',            icon = 'Hand'       },
            { id = 'sit',      label = "S'asseoir",         icon = 'Armchair'   },
            { id = 'lay',      label = "S'allonger",        icon = 'BedDouble'  },
            { id = 'dance',    label = 'Danser',            icon = 'Music'      },
            { id = 'stopanim', label = 'Arrêter animation', icon = 'StopCircle' },
        }, '😊 Émotes')
    end, 'Menu Émotes')

    KeyBinds:Register('kt_quick_lock', 'L', 182, function()
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= 0 then
            local locked = GetVehicleDoorLockStatus(veh)
            SetVehicleDoorsLocked(veh, locked == 1 and 2 or 1)
            ShowNotification(locked == 1 and L('vehicle_locked') or L('vehicle_unlocked'), 'info')
        else
            ShowNotification(L('no_vehicle'), 'warning')
        end
    end, 'Verrouiller véhicule')

    print('[KT Context] Keybinds enregistrés')
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────
exports('RegisterKeybind',   function(id, key, ctrl, cb, desc) return KeyBinds:Register(id, key, ctrl, cb, desc) end)
exports('ToggleKeybind',     function(id, state) KeyBinds:Toggle(id, state) end)
exports('ToggleAllKeybinds', function(state) KeyBinds:ToggleAll(state) end)