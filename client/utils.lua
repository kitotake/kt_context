-- =============================================
-- UTILS CLIENT
-- FIX : IsPlayerAdmin() et GetAdminRole() sont
--       définis dans sync.lua (DB) et dans client/utils.lua (ACE).
--       On conserve uniquement la version ACE ici
--       ET on la rend compatible avec sync.lua :
--       si Permissions est chargé → on l'utilise en priorité.
-- =============================================

-- Notification visuelle
function ShowNotification(message, notifType)
    notifType = notifType or 'info'
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

-- Véhicule le plus proche (usage général, signature différente de la version locale de cursor.lua)
function GetClosestVehicleNearby(coords, maxDist)
    coords  = coords  or GetEntityCoords(PlayerPedId())
    maxDist = maxDist or (Config.InteractionDistance or 5.0)
    local vehicles    = GetGamePool('CVehicle')
    local closestDist = maxDist + 1
    local closestVeh  = -1
    for _, veh in ipairs(vehicles) do
        local d = #(GetEntityCoords(veh) - coords)
        if d < closestDist then
            closestVeh  = veh
            closestDist = d
        end
    end
    if closestVeh ~= -1 and closestDist <= maxDist then
        return closestVeh, closestDist
    end
    return -1, math.huge
end

-- Joueur le plus proche
function GetClosestPlayer(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closestDist, closestPlayer = -1, -1
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local d = #(GetEntityCoords(ped) - coords)
                if closestDist == -1 or d < closestDist then
                    closestPlayer, closestDist = player, d
                end
            end
        end
    end
    return closestPlayer, closestDist
end

-- Texte 3D dans le monde
function Draw3DText(coords, text)
    local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist  = #(vector3(px, py, pz) - coords)
    local scale = (1 / dist) * 2
    local fov   = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(sx, sy)
    end
end

-- Toggle porte véhicule
function ToggleVehicleDoor(doorIndex)
    local veh = GetVehiclePedIsIn(PlayerPedId(), true)
    if veh ~= 0 then
        if GetVehicleDoorAngleRatio(veh, doorIndex) > 0 then
            SetVehicleDoorShut(veh, doorIndex, false)
        else
            SetVehicleDoorOpen(veh, doorIndex, false, false)
        end
    end
end

-- ─── Permissions ──────────────────────────────────────────────────────────────
-- FIX : sync.lua charge les permissions depuis la DB (via oxmysql).
--       utils.lua avait sa propre version basée sur IsPlayerAceAllowed.
--       On unifie : on utilise Permissions (sync.lua) si disponible,
--       sinon on fallback sur les ACE. Ainsi les deux systèmes coexistent
--       sans conflit quelle que soit l'ordre de chargement.

function IsPlayerAdmin()
    -- Priorité 1 : groupe DB synchronisé par sync.lua
    if Permissions and Permissions.group then
        local h = { user = 1, moderator = 2, admin = 3, founder = 4 }
        return (h[Permissions.group] or 0) >= h['admin']
    end
    -- Fallback : ACE Allowlist
    for _, ace in pairs(Config.AdminGroups or Config.AdminAces or {}) do
        if IsPlayerAceAllowed(PlayerId(), ace) then return true end
    end
    return false
end

function GetAdminRole()
    -- Priorité 1 : groupe DB
    if Permissions and Permissions.group and Permissions.group ~= 'user' then
        return Permissions.group
    end
    -- Fallback ACE
    if IsPlayerAceAllowed(PlayerId(), 'founder')   then return 'founder'   end
    if IsPlayerAceAllowed(PlayerId(), 'admin')     then return 'admin'     end
    if IsPlayerAceAllowed(PlayerId(), 'moderator') then return 'moderator' end
    return nil
end

-- Format coordonnées
function FormatCoords(coords)
    return ('X:%.1f Y:%.1f Z:%.1f'):format(coords.x, coords.y, coords.z)
end

-- Direction caméra depuis rotation
function RotationToDirection(rot)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    return vector3(
        -math.sin(rz) * math.abs(math.cos(rx)),
         math.cos(rz) * math.abs(math.cos(rx)),
         math.sin(rx)
    )
end