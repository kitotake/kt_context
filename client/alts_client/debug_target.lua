-- =============================================
-- DEBUG : CERCLE AUTOUR ENTITÉ CIBLÉE (ALT)
-- FIX: debugActive commence à false (pas d'entité au départ)
--      Intégration auto avec le clic curseur via hook
-- =============================================

local debugEntity = nil
local debugActive = false  -- FIX: était true, causait un loop inutile au démarrage

-- =============================================
-- API PUBLIQUE
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
-- HOOK AUTOMATIQUE : s'active quand cursor.lua détecte une entité
-- Appelé depuis cursor.lua dans HandleCursorClickAtScreenPos
-- =============================================

function DebugTarget_OnEntityClick(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetDebugEntity(entity)
        -- Auto-clear après 3 secondes
        Citizen.SetTimeout(3000, function()
            if debugEntity == entity then
                ClearDebugEntity()
            end
        end)
    else
        ClearDebugEntity()
    end
end

-- =============================================
-- DRAW THREAD
-- FIX: sleep 300ms quand inactif au lieu de 0 (économie CPU)
--      Vérification DoesEntityExist avant chaque draw
-- =============================================

Citizen.CreateThread(function()
    while true do

        if debugActive and debugEntity then
            -- FIX: re-vérifier l'existence à chaque frame (l'entité peut être supprimée)
            if not DoesEntityExist(debugEntity) then
                ClearDebugEntity()
                Wait(300)
                goto continue
            end

            local coords = GetEntityCoords(debugEntity)

            -- Cercle principal au sol
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

            -- Point centre entité
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

-- =============================================
-- EXPORTS
-- =============================================

exports("SetDebugEntity",      SetDebugEntity)
exports("ClearDebugEntity",    ClearDebugEntity)
exports("DebugTarget_OnEntityClick", DebugTarget_OnEntityClick)