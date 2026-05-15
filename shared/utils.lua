Utils = {}

-- =============================================
-- Notifications
-- =============================================

function Utils.ShowNotification(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

-- =============================================
-- Draw 3D Text
-- =============================================

function Utils.Draw3DText(coords, text)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z)

    if not onScreen then
        return
    end

    local camCoords = GetGameplayCamCoords()
    local distance = #(camCoords - coords)

    if distance < 0.1 then
        distance = 0.1
    end

    local scale = (1 / distance) * 2
    scale = scale * ((1 / GetGameplayCamFov()) * 100)

    SetTextScale(0.35 * scale, 0.35 * scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextOutline()

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(screenX, screenY)
end

-- =============================================
-- Table helper
-- =============================================

function Utils.TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end