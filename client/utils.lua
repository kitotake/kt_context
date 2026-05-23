-- =============================================
-- UTILS CLIENT — v3.2
-- =============================================

-- ─── Cooldown système ─────────────────────────────────────────────────────────
local _cooldowns = {}

function HasCooldown(key)
    local t = _cooldowns[key]
    if not t then return false end
    if GetGameTimer() < t then return true end
    _cooldowns[key] = nil
    return false
end

function SetCooldown(key, ms)
    _cooldowns[key] = GetGameTimer() + (ms or 2000)
end

function ClearCooldown(key)
    _cooldowns[key] = nil
end

-- ─── Notification ─────────────────────────────────────────────────────────────
function ShowNotification(message, notifType)
    notifType = notifType or 'info'
    if SendNUIMessage then
        SendNUIMessage({
            type = 'notification',
            data = { message = message, type = notifType, duration = 3000 }
        })
    end
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

-- ─── Distance ────────────────────────────────────────────────────────────────
function IsWithinDistance(coords1, coords2, maxDist)
    return #(coords1 - coords2) <= maxDist
end

-- ─── Véhicule le plus proche ──────────────────────────────────────────────────
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

-- ─── Joueur le plus proche ────────────────────────────────────────────────────
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

-- ─── Texte 3D ────────────────────────────────────────────────────────────────
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

-- ─── Toggle porte véhicule ────────────────────────────────────────────────────
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

-- ─── Direction caméra depuis rotation ────────────────────────────────────────
function RotationToDirection(rot)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    return vector3(
        -math.sin(rz) * math.abs(math.cos(rx)),
         math.cos(rz) * math.abs(math.cos(rx)),
         math.sin(rx)
    )
end

-- ─── Format coordonnées ──────────────────────────────────────────────────────
function FormatCoords(coords)
    return ('X:%.1f Y:%.1f Z:%.1f'):format(coords.x, coords.y, coords.z)
end

-- ─── Permissions — ALIAS sécurisés (sync.lua les écrase définitivement) ───────
if not IsPlayerAdmin then
    function IsPlayerAdmin()
        if Permissions and Permissions.group then
            local h = { user=1, staff=2, moderator=3, admin=4, founder=5 }
            return (h[Permissions.group] or 0) >= h['admin']
        end
        return IsPlayerAceAllowed(PlayerId(), 'admin')
    end
end

if not GetAdminRole then
    function GetAdminRole()
        if Permissions and Permissions.group and Permissions.group ~= 'user' then
            return Permissions.group
        end
        if IsPlayerAceAllowed(PlayerId(), 'founder')   then return 'founder'   end
        if IsPlayerAceAllowed(PlayerId(), 'admin')     then return 'admin'     end
        if IsPlayerAceAllowed(PlayerId(), 'moderator') then return 'moderator' end
        if IsPlayerAceAllowed(PlayerId(), 'staff')     then return 'staff'     end
        return nil
    end
end

if not IsPlayerStaff then
    function IsPlayerStaff()
        if Permissions and Permissions.group then
            local h = { user=1, staff=2, moderator=3, admin=4, founder=5 }
            return (h[Permissions.group] or 0) >= h['staff']
        end
        return IsPlayerAceAllowed(PlayerId(), 'staff')
            or IsPlayerAceAllowed(PlayerId(), 'admin')
    end
end