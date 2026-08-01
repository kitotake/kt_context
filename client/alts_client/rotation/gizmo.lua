-- =============================================
-- GIZMO ROTATION — v3.2
-- Suppression dépendances ox_lib → FiveM vanilla
-- =============================================

local dataview       = dataView
local enableScale    = false
local isCursorActive = false
local gizmoEnabled   = false
local currentMode    = 'translate'
local isRelative     = false
local currentEntity  = nil

local function _playerId() return PlayerId() end
local function _ped()      return PlayerPedId() end

local _hintLines  = {}
local _hintActive = false

local function _setTextUI(text)
    _hintLines  = {}
    _hintActive = (text ~= nil and text ~= '')
    if text then
        for line in text:gmatch('[^\n]+') do
            _hintLines[#_hintLines + 1] = line
        end
    end
end

Citizen.CreateThread(function()
    while true do
        if _hintActive and #_hintLines > 0 then
            local y = 0.05
            for _, line in ipairs(_hintLines) do
                SetTextFont(4)
                SetTextProportional(true)
                SetTextScale(0.0, 0.38)
                SetTextColour(255, 255, 255, 200)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextDropShadow()
                SetTextOutline()
                SetTextEntry('STRING')
                AddTextComponentString(line)
                DrawText(0.015, y)
                y = y + 0.026
            end
            Wait(0)
        else
            Wait(200)
        end
    end
end)

local function normalize(x, y, z)
    local length = math.sqrt(x*x + y*y + z*z)
    if length == 0 then return 0, 0, 0 end
    return x/length, y/length, z/length
end

local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    if not dataview then
        print('[KT Gizmo] ERREUR: dataview non chargé')
        return nil
    end
    local view = dataview.ArrayBuffer(64)
    view:SetFloat32(0,  r[1]):SetFloat32(4,  r[2]):SetFloat32(8,  r[3]):SetFloat32(12, 0)
        :SetFloat32(16, f[1]):SetFloat32(20, f[2]):SetFloat32(24, f[3]):SetFloat32(28, 0)
        :SetFloat32(32, u[1]):SetFloat32(36, u[2]):SetFloat32(40, u[3]):SetFloat32(44, 0)
        :SetFloat32(48, a[1]):SetFloat32(52, a[2]):SetFloat32(56, a[3]):SetFloat32(60, 1)
    return view
end

local function applyEntityMatrix(entity, view)
    local x1,y1,z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2,y2,z2 = view:GetFloat32(0),  view:GetFloat32(4),  view:GetFloat32(8)
    local x3,y3,z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx,ty,tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)
    if not enableScale then
        x1,y1,z1 = normalize(x1,y1,z1)
        x2,y2,z2 = normalize(x2,y2,z2)
        x3,y3,z3 = normalize(x3,y3,z3)
    end
    SetEntityMatrix(entity, x1,y1,z1, x2,y2,z2, x3,y3,z3, tx,ty,tz)
end

local function GetVectorText(vectorType)
    if not currentEntity then return 'ERR_NO_ENTITY' end
    local label = (vectorType == 'coords') and 'Pos' or 'Rot'
    local vec   = (vectorType == 'coords')
        and GetEntityCoords(currentEntity)
        or  GetEntityRotation(currentEntity)
    return ('%s: %.1f, %.1f, %.1f'):format(label, vec.x, vec.y, vec.z)
end

local function buildHintText()
    local scaleText = enableScale and '[S] Scale\n' or ''
    return ('Mode: %s | %s\n%s\n%s\n[G] Curseur: %s\n[W] Translation\n[R] Rotation\n%s[Q] Rel/Monde\n[LALT] Sol\n[ENTREE] Terminer'):format(
        currentMode,
        isRelative and 'Relatif' or 'Monde',
        GetVectorText('coords'),
        GetVectorText('rotation'),
        isCursorActive and 'ON' or 'OFF',
        scaleText
    )
end

local function gizmoLoop(entity)
    if not gizmoEnabled then
        LeaveCursorMode()
        return
    end

    EnterCursorMode()
    isCursorActive = true

    if IsEntityAPed(entity) then
        SetEntityAlpha(entity, 200)
    else
        SetEntityDrawOutline(entity, true)
    end

    while gizmoEnabled and DoesEntityExist(entity) do
        Wait(0)

        if IsControlJustPressed(0, 47) then
            if isCursorActive then
                LeaveCursorMode()
                isCursorActive = false
            else
                EnterCursorMode()
                isCursorActive = true
            end
        end

        DisableControlAction(0, 24,  true)
        DisableControlAction(0, 25,  true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(_playerId(), true)

        _setTextUI(buildHintText())

        local matrixBuffer = makeEntityMatrix(entity)
        if matrixBuffer then
            local changed = Citizen.InvokeNative(
                0xEB2EDCA2, matrixBuffer:Buffer(), 'Editor1',
                Citizen.ReturnResultAnyway()
            )
            if changed then applyEntityMatrix(entity, matrixBuffer) end
        end
    end

    _setTextUI(nil)
    if isCursorActive then LeaveCursorMode() end
    isCursorActive = false

    if DoesEntityExist(entity) then
        if IsEntityAPed(entity) then SetEntityAlpha(entity, 255) end
        SetEntityDrawOutline(entity, false)
    end

    gizmoEnabled  = false
    currentEntity = nil
end

local function useGizmo(entity)
    if not entity or not DoesEntityExist(entity) then
        print('[KT Gizmo] useGizmo: entité invalide')
        return nil
    end
    gizmoEnabled  = true
    currentEntity = entity
    gizmoLoop(entity)
    return {
        handle   = entity,
        position = GetEntityCoords(entity),
        rotation = GetEntityRotation(entity),
    }
end

exports('useGizmo', useGizmo)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if gizmoEnabled then
            if IsControlJustPressed(0, 18) then gizmoEnabled = false end
            if IsControlJustPressed(0, 44) then
                currentMode = 'Translate'
                ExecuteCommand('+gizmoTranslation'); Wait(100); ExecuteCommand('-gizmoTranslation')
            end
            if IsControlJustPressed(0, 45) then
                currentMode = 'Rotate'
                ExecuteCommand('+gizmoRotation'); Wait(100); ExecuteCommand('-gizmoRotation')
            end
            if IsControlJustPressed(0, 36) then
                isRelative = not isRelative
                ExecuteCommand('+gizmoLocal'); Wait(100); ExecuteCommand('-gizmoLocal')
            end
            if IsControlJustPressed(0, 19) then
                if currentEntity and DoesEntityExist(currentEntity) then
                    PlaceObjectOnGroundProperly_2(currentEntity)
                end
            end
            if enableScale and IsControlJustPressed(0, 33) then
                currentMode = 'Scale'
                ExecuteCommand('+gizmoScale'); Wait(100); ExecuteCommand('-gizmoScale')
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if gizmoEnabled then
            if IsDisabledControlJustPressed(0, 24)  then ExecuteCommand('+gizmoSelect') end
            if IsDisabledControlJustReleased(0, 24) then ExecuteCommand('-gizmoSelect') end
        end
    end
end)
