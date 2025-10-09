function ShowNotification(message, type)
    type = type or "info"
    
    local colors = {
        success = {10, 185, 129},
        error = {239, 68, 68},
        warning = {245, 158, 11},
        info = {59, 130, 246}
    }
    
    local color = colors[type] or colors.info
    
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    SetNotificationMessage("CHAR_DEFAULT", "CHAR_DEFAULT", true, 1, "Notification", "")
    SetNotificationBackgroundColor(color[1])
    DrawNotification(false, true)
end

function GetClosestVehicle(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    
    return closestVehicle, closestDistance
end

function GetClosestPlayer(coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closestDistance = -1
    local closestPlayer = -1
    local players = GetActivePlayers()
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(targetCoords - coords)
                
                if closestDistance == -1 or distance < closestDistance then
                    closestPlayer = player
                    closestDistance = distance
                end
            end
        end
    end
    
    return closestPlayer, closestDistance
end

-- Fonction pour dessiner du texte 3D
function Draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - coords)
    
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
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
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
