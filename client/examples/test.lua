-- client/test.lua

local model = `prop_mp_cone_02`

RegisterCommand('testGizmo', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)

    local spawnCoords = coords + forward * 3.0

    lib.requestModel(model)

    local obj = CreateObject(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)

    SetEntityAsMissionEntity(obj, true, true)
    PlaceObjectOnGroundProperly(obj)

    -- ❌ IMPORTANT: DO NOT FREEZE
    -- FreezeEntityPosition(obj, true)

    local data = exports['kt_context']:useGizmo(obj)

    print(json.encode(data or {}, { indent = true }))

    SetModelAsNoLongerNeeded(model)

    -- optional cleanup AFTER gizmo if needed
    -- DeleteEntity(obj)
end)