-- =============================================
-- DEBUG : CERCLE AUTOUR ENTITÉ CIBLÉE (ALT)
-- =============================================

local debugEntity = nil
local debugActive = false

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

function DebugTarget_OnEntityClick(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetDebugEntity(entity)
        Citizen.SetTimeout(3000, function()
            if debugEntity == entity then ClearDebugEntity() end
        end)
    else
        ClearDebugEntity()
    end
end

Citizen.CreateThread(function()
    while true do
        if debugActive and debugEntity then
            if not DoesEntityExist(debugEntity) then
                ClearDebugEntity()
                Wait(300)
                goto continue
            end

            local coords = GetEntityCoords(debugEntity)

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

        ::continue::
    end
end)

exports('SetDebugEntity',           SetDebugEntity)
exports('ClearDebugEntity',         ClearDebugEntity)
exports('DebugTarget_OnEntityClick', DebugTarget_OnEntityClick)