-- client/examples/test.lua
local model = `prop_mp_cone_02`

RegisterCommand('testGizmo', function()
    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + forward * 3.0

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10); timeout = timeout + 10
        if timeout > 5000 then
            print('[KT Test] Timeout chargement modèle')
            return
        end
    end

    local obj = CreateObject(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    PlaceObjectOnGroundProperly(obj)

    local data = exports['kt_context']:useGizmo(obj)
    print(json.encode(data or {}, { indent = true }))

    SetModelAsNoLongerNeeded(model)
end, false)
