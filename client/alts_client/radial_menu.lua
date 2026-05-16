-- =============================================
-- MENU RADIAL (touche Z)
-- =============================================

local RadialMenu = { isOpen = false, currentMenu = nil }

local RadialMenus = {
    main = {
        title = 'Menu Principal',
        items = {
            { id = 'vehicle',  label = 'Véhicule',  icon = '🚗', submenu = 'vehicle'  },
            { id = 'player',   label = 'Joueur',    icon = '👤', submenu = 'player'   },
            { id = 'emotes',   label = 'Émotes',    icon = '😊', submenu = 'emotes'   },
            { id = 'phone',    label = 'Téléphone', icon = '📱',
              action = function() TriggerEvent('kt_phone:open') end },
            { id = 'admin',    label = 'Admin',     icon = '🛡️', submenu = 'admin',
              condition = function() return IsPlayerAdmin() end },
        }
    },

    vehicle = {
        title = 'Véhicule', parent = 'main',
        items = {
            { id = 'lock',   label = 'Verrouiller', icon = '🔒',
              action = function() if QuickActions then QuickActions.Vehicle.ToggleLock() end end },
            { id = 'engine', label = 'Moteur',      icon = '🔌',
              action = function() if QuickActions then QuickActions.Vehicle.ToggleEngine() end end },
            { id = 'lights', label = 'Lumières',    icon = '💡',
              action = function() if QuickActions then QuickActions.Vehicle.ToggleLights() end end },
            { id = 'doors',  label = 'Portes',      icon = '🚪', submenu = 'vehicle_doors' },
        }
    },

    vehicle_doors = {
        title = 'Portes', parent = 'vehicle',
        items = {
            { id = 'fl',    label = 'Avant G',   icon = '🚪', action = function() ToggleVehicleDoor(0) end },
            { id = 'fr',    label = 'Avant D',   icon = '🚪', action = function() ToggleVehicleDoor(1) end },
            { id = 'rl',    label = 'Arrière G', icon = '🚪', action = function() ToggleVehicleDoor(2) end },
            { id = 'rr',    label = 'Arrière D', icon = '🚪', action = function() ToggleVehicleDoor(3) end },
            { id = 'hood',  label = 'Capot',     icon = '🔩', action = function() ToggleVehicleDoor(4) end },
            { id = 'trunk', label = 'Coffre',    icon = '📦', action = function() ToggleVehicleDoor(5) end },
        }
    },

    player = {
        title = 'Actions Joueur', parent = 'main',
        items = {
            { id = 'handsup',  label = "Mains en l'air", icon = '🙌',
              action = function() if QuickActions then QuickActions.Player.HandsUp() end end },
            { id = 'sit',      label = "S'asseoir",      icon = '🪑',
              action = function() if QuickActions then QuickActions.Player.SitGround() end end },
            { id = 'lay',      label = "S'allonger",     icon = '😴',
              action = function() if QuickActions then QuickActions.Player.LayDown() end end },
            { id = 'stopanim', label = 'Arrêter anim',   icon = '⏹️',
              action = function() if QuickActions then QuickActions.Player.StopAnim() end end },
        }
    },

    emotes = {
        title = 'Émotes', parent = 'main',
        items = {
            { id = 'wave',  label = 'Saluer',    icon = '👋',
              action = function()
                local ped = PlayerPedId()
                RequestAnimDict('gestures@m@standing@casual')
                while not HasAnimDictLoaded('gestures@m@standing@casual') do Wait(10) end
                TaskPlayAnim(ped, 'gestures@m@standing@casual', 'gesture_hello', 8.0, -8.0, -1, 0, 0, false, false, false)
              end },
            { id = 'dance', label = 'Danser',    icon = '💃',
              action = function() TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_PARTYING', 0, true) end },
            { id = 'clap',  label = 'Applaudir', icon = '👏',
              action = function()
                local ped = PlayerPedId()
                RequestAnimDict('anim@mp_player_intcelebrationfemale@slow_clap')
                while not HasAnimDictLoaded('anim@mp_player_intcelebrationfemale@slow_clap') do Wait(10) end
                TaskPlayAnim(ped, 'anim@mp_player_intcelebrationfemale@slow_clap', 'slow_clap', 8.0, -8.0, -1, 0, 0, false, false, false)
              end },
        }
    },

    admin = {
        title = 'Admin', parent = 'main',
        items = {
            { id = 'heal',  label = 'Se soigner',       icon = '❤️',
              action = function() if QuickActions then QuickActions.Admin.Heal() end end },
            { id = 'armor', label = 'Armure',            icon = '🛡️',
              action = function() if QuickActions then QuickActions.Admin.GiveArmor() end end },
            { id = 'fix',   label = 'Réparer véhicule',  icon = '🔧',
              action = function() if QuickActions then QuickActions.Admin.RepairVehicle() end end },
            { id = 'dv',    label = 'Suppr. véhicule',   icon = '🗑️',
              action = function() if QuickActions then QuickActions.Admin.DeleteVehicle() end end },
            { id = 'tpw',   label = 'TP Waypoint',       icon = '📍',
              action = function() if QuickActions then QuickActions.Admin.TeleportToWaypoint() end end },
            { id = 'god',   label = 'God Mode',           icon = '👻',
              action = function() if QuickActions then QuickActions.Admin.ToggleGodMode() end end },
        }
    },
}

function RadialMenu:Open(menuId)
    menuId = menuId or 'main'
    local menu = RadialMenus[menuId]
    if not menu then return end

    local filteredItems = {}
    for _, item in ipairs(menu.items) do
        if not item.condition or item.condition() then
            table.insert(filteredItems, item)
        end
    end

    self.isOpen      = true
    self.currentMenu = menuId

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openRadialMenu',
        data = { title = menu.title, items = filteredItems, parent = menu.parent }
    })
end

function RadialMenu:Close()
    if not self.isOpen then return end
    self.isOpen      = false
    self.currentMenu = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeRadialMenu' })
end

function RadialMenu:GoBack()
    local current = RadialMenus[self.currentMenu]
    if current and current.parent then
        self:Close()
        Wait(80)
        self:Open(current.parent)
    else
        self:Close()
    end
end

-- NUI Callbacks
RegisterNUICallback('radialMenuAction', function(data, cb)
    if data.action == 'back' then
        RadialMenu:GoBack()
    elseif data.action == 'close' then
        RadialMenu:Close()
    elseif data.action == 'item' then
        local menu = RadialMenus[data.menuId]
        if menu then
            for _, item in ipairs(menu.items) do
                if item.id == data.itemId then
                    if item.submenu then
                        RadialMenu:Close()
                        Wait(80)
                        RadialMenu:Open(item.submenu)
                    elseif item.action then
                        item.action()
                        RadialMenu:Close()
                    end
                    break
                end
            end
        end
    end
    cb('ok')
end)

-- Commande + keybind Z
RegisterCommand('+radialmenu', function()
    if not RadialMenu.isOpen then RadialMenu:Open('main') end
end, false)

RegisterCommand('-radialmenu', function()
    if RadialMenu.isOpen then RadialMenu:Close() end
end, false)

RegisterKeyMapping('+radialmenu', 'Ouvrir le menu radial', 'keyboard', 'Z')

exports('OpenRadialMenu',  function(menuId) RadialMenu:Open(menuId) end)
exports('CloseRadialMenu', function() RadialMenu:Close() end)

_G.RadialMenu = RadialMenu