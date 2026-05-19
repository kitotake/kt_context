-- =============================================
-- DEBUG : CERCLE AUTOUR ENTITÉ CIBLÉE (ALT)
-- =============================================

local debugEntity = nil
local debugActive = true

-- =============================================
-- ACTIVATE FROM OUTSIDE
-- =============================================

function SetDebugEntity(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        debugEntity = entity
        debugActive = true
    else
        debugEntity = nil
        debugActive = false
    end
end

function ClearDebugEntity()
    debugEntity = nil
    debugActive = false
end

-- =============================================
-- DRAW THREAD
-- =============================================

Citizen.CreateThread(function()
    while true do

        if debugActive and debugEntity and DoesEntityExist(debugEntity) then

            local coords = GetEntityCoords(debugEntity)

            -- cercle principal au sol
            DrawMarker(
                1,
                coords.x, coords.y, coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.6, 1.6, 0.6,
                0, 150, 255, 160,
                false, true, 2,
                false, nil, nil, false
            )

            -- point centre entité
            DrawMarker(
                2,
                coords.x, coords.y, coords.z + 0.5,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.18, 0.18, 0.18,
                255, 255, 255, 200,
                false, true, 2,
                false, nil, nil, false
            )

            Wait(0)
        else
            Wait(300)
        end
    end
end)

-- =============================================
-- EXPORT (OPTIONNEL POUR AUTRES SCRIPTS)
-- =============================================

exports("SetDebugEntity", SetDebugEntity)
exports("ClearDebugEntity", ClearDebugEntity)