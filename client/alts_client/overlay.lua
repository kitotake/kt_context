-- =============================================
-- OVERLAY SYSTÈME — v3.2 (NOUVEAU)
--
-- Fournit des overlays activables via checkboxes dans le menu contextuel :
--   • Noms des joueurs au-dessus de leur tête (3D)
--   • Blips joueurs sur la minimap
--   • Cercle de portée autour du joueur local
--   • Infos véhicules proches (plaque, vitesse…)
--
-- Utilisation dans le menu :
--   BuildOverlayMenu() → retourne les items avec checkboxes
--
-- Chaque checkbox envoie 'kt_context:checkboxAction' avec l'ID et l'état.
-- =============================================

-- ─── État local des overlays ─────────────────────────────────────────────────
local OverlayState = {
    playerNames  = Config.Overlay.PlayerNames.Enabled,
    playerBlips  = Config.Overlay.PlayerBlips.Enabled,
    rangeCircle  = Config.Overlay.RangeCircle.Enabled,
    vehicleInfo  = Config.Overlay.VehicleInfo.Enabled,
}

-- Blips créés dynamiquement (joueurs)
local _playerBlips = {}

-- ─── Écoute des checkboxes depuis le menu ────────────────────────────────────
AddEventHandler('kt_context:checkboxAction', function(id, checked, data)
    if     id == 'overlay_player_names'  then OverlayState.playerNames  = checked
    elseif id == 'overlay_player_blips'  then
        OverlayState.playerBlips = checked
        if not checked then _clearPlayerBlips() end
    elseif id == 'overlay_range_circle'  then OverlayState.rangeCircle  = checked
    elseif id == 'overlay_vehicle_info'  then OverlayState.vehicleInfo  = checked
    end

    local msg = checked and L('overlay_enabled') or L('overlay_disabled')
    ShowNotification(msg, checked and 'success' or 'info')
end)

-- ─── Builder de menu overlay (items avec checked) ─────────────────────────────
function BuildOverlayMenu()
    return {
        {
            id          = 'overlay_info',
            label       = 'Affichages & Overlays',
            icon        = 'Eye',
            disabled    = true,
            description = 'Activez les éléments visuels',
        },
        { id = '_div_overlay', divider = true, label = '' },
        {
            id          = 'overlay_player_names',
            label       = L('overlay_player_names'),
            icon        = 'Users',
            type        = 'checkbox',
            checked     = OverlayState.playerNames,
            description = ('Distance max : %.0fm'):format(Config.Overlay.PlayerNames.MaxDistance),
        },
        {
            id          = 'overlay_player_blips',
            label       = L('overlay_player_blips'),
            icon        = 'MapPin',
            type        = 'checkbox',
            checked     = OverlayState.playerBlips,
            description = ('Portée : %.0fm'):format(Config.Overlay.PlayerBlips.MaxDistance),
        },
        {
            id          = 'overlay_range_circle',
            label       = L('overlay_range_circle'),
            icon        = 'CircleDot',
            type        = 'checkbox',
            checked     = OverlayState.rangeCircle,
            description = ('Rayon : %.0fm'):format(Config.Overlay.RangeCircle.Radius),
        },
        {
            id          = 'overlay_vehicle_info',
            label       = L('overlay_vehicle_info'),
            icon        = 'Car',
            type        = 'checkbox',
            checked     = OverlayState.vehicleInfo,
            description = ('Portée : %.0fm'):format(Config.Overlay.VehicleInfo.MaxDistance),
        },
    }
end

-- ─── Getters d'état ──────────────────────────────────────────────────────────
function IsOverlayActive(key)
    return OverlayState[key] == true
end

-- ─── Blips joueurs ───────────────────────────────────────────────────────────
local function _clearPlayerBlips()
    for _, blip in pairs(_playerBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    _playerBlips = {}
end

local function _updatePlayerBlips()
    local myCoords = GetEntityCoords(PlayerPedId())
    local maxDist  = Config.Overlay.PlayerBlips.MaxDistance

    -- Supprimer les blips dont le joueur n'est plus proche
    for serverId, blip in pairs(_playerBlips) do
        local player = GetPlayerFromServerId(serverId)
        if player == -1 or not DoesBlipExist(blip) then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            _playerBlips[serverId] = nil
        end
    end

    -- Créer/mettre à jour les blips pour les joueurs proches
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped   = GetPlayerPed(player)
            local sid   = GetPlayerServerId(player)
            if DoesEntityExist(ped) then
                local dist = #(GetEntityCoords(ped) - myCoords)
                if dist <= maxDist then
                    if not _playerBlips[sid] or not DoesBlipExist(_playerBlips[sid]) then
                        local blip = AddBlipForEntity(ped)
                        SetBlipSprite(blip,  Config.Overlay.PlayerBlips.Sprite)
                        SetBlipColour(blip,  Config.Overlay.PlayerBlips.Color)
                        SetBlipScale(blip,   Config.Overlay.PlayerBlips.Scale)
                        SetBlipNameToPlayerName(blip, player)
                        ShowHeadingIndicatorOnBlip(blip, false)
                        _playerBlips[sid] = blip
                    end
                else
                    if _playerBlips[sid] and DoesBlipExist(_playerBlips[sid]) then
                        RemoveBlip(_playerBlips[sid])
                        _playerBlips[sid] = nil
                    end
                end
            end
        end
    end
end

-- ─── Draw noms joueurs (3D texte) ────────────────────────────────────────────
local function _drawPlayerNames()
    local cfg      = Config.Overlay.PlayerNames
    local myCoords = GetEntityCoords(PlayerPedId())
    local maxDist  = cfg.MaxDistance

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local pedCoords = GetEntityCoords(ped)
                local dist      = #(pedCoords - myCoords)
                if dist <= maxDist then
                    -- Texte flottant au-dessus de la tête
                    local nameCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.15)
                    local onScreen, sx, sy = World3dToScreen2d(nameCoords.x, nameCoords.y, nameCoords.z)

                    if onScreen then
                        local alpha = math.floor(math.max(0, math.min(255,
                            255 * (1.0 - (dist / maxDist) ^ 1.5)
                        )))

                        -- Nom du joueur
                        local name = GetPlayerName(player) or '?'
                        if cfg.ShowId then
                            name = ('[%d] %s'):format(GetPlayerServerId(player), name)
                        end
                        if cfg.ShowDistance then
                            name = name .. (' (%.0fm)'):format(dist)
                        end

                        -- Couleur selon le rôle
                        local c = cfg.FriendlyColor
                        SetTextScale(0.0, cfg.TextScale)
                        SetTextFont(4)
                        SetTextProportional(true)
                        SetTextColour(c.r, c.g, c.b, math.min(c.a, alpha))
                        SetTextDropShadow()
                        SetTextOutline()
                        SetTextEntry('STRING')
                        SetTextCentre(true)
                        AddTextComponentString(name)
                        DrawText(sx, sy)

                        -- Barre de santé optionnelle
                        if cfg.ShowHealth then
                            local hp      = GetEntityHealth(ped) - 100
                            local maxHp   = 100
                            local pct     = math.max(0, hp / maxHp)
                            local barW    = 0.04
                            local barH    = 0.005
                            local barX    = sx - barW * 0.5
                            local barY    = sy + 0.018
                            -- fond
                            DrawRect(barX + barW * 0.5, barY, barW, barH, 0, 0, 0, 180)
                            -- remplissage
                            local gr = math.floor(255 * pct)
                            local rd = math.floor(255 * (1 - pct))
                            DrawRect(barX + (barW * pct) * 0.5, barY, barW * pct, barH, rd, gr, 0, 200)
                        end
                    end
                end
            end
        end
    end
end

-- ─── Draw cercle de portée ───────────────────────────────────────────────────
local function _drawRangeCircle()
    local cfg    = Config.Overlay.RangeCircle
    local coords = GetEntityCoords(PlayerPedId())
    local c      = cfg.Color
    DrawMarker(
        1,
        coords.x, coords.y, coords.z - 0.95,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        cfg.Radius * 2, cfg.Radius * 2, 0.5,
        c.r, c.g, c.b, c.a,
        false, false, 2,
        false, nil, nil, false
    )
end

-- ─── Draw infos véhicules ────────────────────────────────────────────────────
local function _drawVehicleInfo()
    local cfg      = Config.Overlay.VehicleInfo
    local myCoords = GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool('CVehicle')

    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vCoords = GetEntityCoords(veh)
            local dist    = #(vCoords - myCoords)
            if dist <= cfg.MaxDistance then
                local onScreen, sx, sy = World3dToScreen2d(vCoords.x, vCoords.y, vCoords.z + 0.8)
                if onScreen then
                    local lines = {}

                    if cfg.ShowPlate then
                        local plate = GetVehicleNumberPlateText(veh)
                        if plate and #plate > 0 then
                            table.insert(lines, 'plate : ' .. plate)
                        end
                    end
                    if cfg.ShowSpeed then
                        local spd = math.floor(GetEntitySpeed(veh) * 3.6)
                        table.insert(lines, spd .. ' km/h')
                    end
                    if cfg.ShowHealth then
                        local hp = math.floor(GetVehicleEngineHealth(veh) / 10)
                        table.insert(lines, 'Moteur ' .. hp .. '%')
                    end

                    local alpha = math.floor(math.max(0, math.min(220,
                        220 * (1.0 - (dist / cfg.MaxDistance) ^ 1.5)
                    )))

                    local offsetY = sy - 0.01
                    for _, line in ipairs(lines) do
                        SetTextScale(0.0, 0.28)
                        SetTextFont(4)
                        SetTextProportional(true)
                        SetTextColour(220, 220, 220, alpha)
                        SetTextDropShadow()
                        SetTextOutline()
                        SetTextEntry('STRING')
                        SetTextCentre(true)
                        AddTextComponentString(line)
                        DrawText(sx, offsetY)
                        offsetY = offsetY + 0.016
                    end
                end
            end
        end
    end
end

-- ─── Thread principal overlays ────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local anyActive = OverlayState.playerNames
            or OverlayState.playerBlips
            or OverlayState.rangeCircle
            or OverlayState.vehicleInfo

        if anyActive then
            if OverlayState.playerNames  then _drawPlayerNames()  end
            if OverlayState.rangeCircle  then _drawRangeCircle()  end
            if OverlayState.vehicleInfo  then _drawVehicleInfo()  end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ─── Thread blips (mise à jour moins fréquente) ───────────────────────────────
Citizen.CreateThread(function()
    while true do
        if OverlayState.playerBlips then
            _updatePlayerBlips()
            Wait(2000)
        else
            _clearPlayerBlips()
            Wait(1000)
        end
    end
end)

-- ─── Cleanup ─────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        _clearPlayerBlips()
    end
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────
exports('BuildOverlayMenu', BuildOverlayMenu)
exports('IsOverlayActive',  IsOverlayActive)
_G.OverlayState = OverlayState