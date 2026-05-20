-- =============================================
-- CURSEUR CONTEXTUEL — FIXED v4
-- =============================================
-- Flow correct :
--
--   1. ALT maintenu → SetNuiFocus(true,true) → curseur Chromium visible
--      Le joueur bouge sa souris normalement dans le NUI.
--
--   2. Clic gauche → React (mousedown) capture e.clientX/Y (coords pixel réels)
--      → envoie via NUI callback "cursorClick" { x=px, y=py }
--
--   3. Lua reçoit les coords pixel → les normalise [0..1]
--      → construit un rayon depuis cette position écran précise
--      → GetShapeTestResult → entité 3D sous le curseur
--
--   4. Lua renvoie openContextMenu { x=px, y=py, items=... }
--      → le menu s'affiche exactement là où le joueur a cliqué
--
-- ─────────────────────────────────────────────────────────────────────────────
-- Pourquoi PAS GetScreenCoordFromWorldCoord ?
--   → C'est la transformation inverse (3D→2D). On l'utiliserait pour placer
--     un marqueur sur un objet déjà connu. Ici on PART du 2D (clic souris)
--     pour trouver le 3D (entité), donc on utilise un raycast 2D→3D.
--
-- Pourquoi PAS IsDisabledControlJustReleased(0, 24) pour le clic ?
--   → Cette native détecte le clic côté moteur GTA, pas côté NUI.
--     En mode NUI focus, le clic est consommé par Chromium et les coords
--     ne sont pas disponibles côté Lua. Il faut passer par React.
-- =============================================

local CURSOR_KEY    = Config and Config.CursorKey or 19
local RAYCAST_FLAGS = 511  -- tous les types d'entités

local cursorActive = false
local lastVehCheck = 0
local _cachedVeh   = -1
local _cachedDist  = math.huge

-- ─── API publique ─────────────────────────────────────────────────────────────
function IsCursorActive()
    return cursorActive
end

-- ─── Véhicule le plus proche (local, évite conflit avec utils.lua) ────────────
local function _GetClosestVeh(coords)
    local veh = GetClosestVehicle(
        coords.x, coords.y, coords.z,
        Config.InteractionDistance or 5.0, 0, 70
    )
    if veh and veh ~= 0 then
        return veh, #(coords - GetEntityCoords(veh))
    end
    return -1, math.huge
end

-- ─── Rayon depuis une position écran normalisée ────────────────────────────────
-- nx, ny ∈ [0..1] (normalisé depuis les pixels React)
-- Retourne l'entité touchée et les coordonnées monde du hit (ou nil).
local function RaycastFromScreen(nx, ny)
    -- MAP_SCENE_TO_WORLD_COORDS : construit le rayon depuis une position écran
    local camCoords = GetGameplayCamCoords()
    local camRot    = GetGameplayCamRot(2)
    local dir       = RotationToDirection(camRot)

    -- Décalage horizontal/vertical depuis le centre caméra
    -- en fonction de la position normalisée du clic
    local fov = GetGameplayCamFov()
    local sw, sh = GetActiveScreenResolution()
    local aspect = sw / sh

    -- Angle depuis le centre (en radians)
    local halfFovV = math.rad(fov * 0.5)
    local halfFovH = math.atan(math.tan(halfFovV) * aspect)

    local offsetX = (nx - 0.5) * 2.0   -- [-1..1]
    local offsetY = (ny - 0.5) * 2.0   -- [-1..1]

    -- Vecteurs orthogonaux à la direction caméra
    local rotRight = vector3(
         math.cos(math.rad(camRot.z)),
         math.sin(math.rad(camRot.z)),
         0.0
    )
    local rotUp = vector3(0.0, 0.0, 1.0)

    local rayDir = vector3(
        dir.x + rotRight.x * math.tan(halfFovH) * offsetX,
        dir.y + rotRight.y * math.tan(halfFovH) * offsetX,
        dir.z - math.tan(halfFovV) * offsetY
    )

    -- Normaliser
    local len = math.sqrt(rayDir.x^2 + rayDir.y^2 + rayDir.z^2)
    rayDir = vector3(rayDir.x/len, rayDir.y/len, rayDir.z/len)

    local dist = 100.0
    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        camCoords.x + rayDir.x * dist,
        camCoords.y + rayDir.y * dist,
        camCoords.z + rayDir.z * dist,
        RAYCAST_FLAGS,
        PlayerPedId(),
        0
    )

    local _, hit, hitCoords, _, entity = GetShapeTestResult(ray)

    if hit == 1 and entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity, hitCoords
    end
    return nil, nil
end

-- ─── Thread : gestion ALT (activer/désactiver le mode curseur) ───────────────
Citizen.CreateThread(function()
    while true do
        local sleep = 100

        if IsControlPressed(0, CURSOR_KEY) then
            sleep = 0

            if not cursorActive then
                cursorActive = true
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(true)
                SendNUIMessage({ type = "cursorShow", data = { visible = true } })
            end

            -- Bloquer les contrôles caméra/mouvement pendant le mode curseur
            DisableControlAction(0, 1,   true)
            DisableControlAction(0, 2,   true)
            DisableControlAction(0, 25,  true)
            DisableControlAction(0, 69,  true)
            DisableControlAction(0, 142, true)
            -- Note : on ne bloque PAS le 24 (Attack/clic gauche) ici —
            -- Chromium en SetNuiFocus(true,true) le consomme déjà en mousedown,
            -- React l'intercepte et envoie cursorClick avec les vraies coords.

        elseif cursorActive then
            cursorActive = false

            if IsMenuOpen() then
                CloseContextMenu()
            end

            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ type = "cursorShow", data = { visible = false } })
        end

        Wait(sleep)
    end
end)

-- ─── NUI Callback : React envoie les coords pixel du mousedown ────────────────
-- x, y = pixels absolus (e.clientX, e.clientY depuis React)
RegisterNUICallback('cursorClick', function(data, cb)
    -- Si le menu est déjà ouvert, on ignore (React gère la fermeture)
    if IsMenuOpen() then cb('ok') return end

    local px = tonumber(data.x) or 0
    local py = tonumber(data.y) or 0

    -- Normaliser en [0..1] pour le raycast
    local sw, sh = GetActiveScreenResolution()
    local nx = px / sw
    local ny = py / sh

    local entity, _ = RaycastFromScreen(nx, ny)

    if entity then
        if DebugTarget_OnEntityClick then
            DebugTarget_OnEntityClick(entity)
        end
        -- On utilise les coords pixel d'origine pour positionner le menu
        OpenContextForEntity(entity, GetEntityType(entity), px, py)
    else
        ClearDebugEntity()
        -- Clic dans le vide : menu général à la position du clic
        OpenGeneralContextMenu(px, py)
    end

    cb('ok')
end)

-- ─── Dispatch selon le type d'entité ─────────────────────────────────────────
function OpenContextForEntity(entity, entityType, x, y)
    local isAdmin = IsPlayerAdmin()
    local role    = GetAdminRole()
    local items   = {}

    if entityType == 1 then
        if IsPedAPlayer(entity) then
            local localId = NetworkGetPlayerIndexFromPed(entity)
            if localId ~= -1 then
                items = BuildPlayerMenu(
                    GetPlayerServerId(localId),
                    GetPlayerName(localId) or "Joueur",
                    isAdmin
                )
            else
                items = BuildNpcMenu(entity, isAdmin)
            end
        else
            items = BuildNpcMenu(entity, isAdmin)
        end

    elseif entityType == 2 then
        local locked = GetVehicleDoorLockStatus(entity) ~= 1
        items = BuildVehicleMenu(entity, locked, isAdmin)

    elseif entityType == 3 then
        items = BuildPropMenu(entity, isAdmin)

    else
        OpenGeneralContextMenu(x, y)
        return
    end

    if isAdmin and role then
        table.insert(items, { id = "_admin_div", divider = true, label = "" })
        table.insert(items, {
            id         = "admin",
            label      = "⚡ Admin [" .. role .. "]",
            icon       = "ShieldAlert",
            badge      = role,
            badgeColor = "#f59e0b",
            submenu    = BuildAdminEntityMenu(entity, entityType),
        })
    end

    OpenContextMenu(x, y, items, GetEntityMenuTitle(entityType, entity))
end

-- ─── Titre du menu ────────────────────────────────────────────────────────────
function GetEntityMenuTitle(entityType, entity)
    if entityType == 1 then return IsPedAPlayer(entity) and "👤 Joueur" or "🤖 PNJ" end
    if entityType == 2 then return "🚗 Véhicule" end
    if entityType == 3 then return "📦 Objet" end
    return "🌍 Interaction"
end

-- ─── Menu général (clic dans le vide) ────────────────────────────────────────
function OpenGeneralContextMenu(x, y)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local items  = {}

    if GetGameTimer() - lastVehCheck > 500 then
        _cachedVeh, _cachedDist = _GetClosestVeh(coords)
        lastVehCheck = GetGameTimer()
    end

    if _cachedVeh ~= -1 and _cachedDist < (Config.InteractionDistance or 5.0) then
        local locked = GetVehicleDoorLockStatus(_cachedVeh) ~= 1
        table.insert(items, {
            id      = "near_vehicle",
            label   = ("Véhicule (%.1fm)"):format(_cachedDist),
            icon    = "Car",
            submenu = BuildVehicleMenu(_cachedVeh, locked, IsPlayerAdmin()),
        })
    end

    table.insert(items, {
        id      = "player_actions",
        label   = "Actions joueur",
        icon    = "User2",
        submenu = {
            { id = "handsup",  label = "Mains en l'air", icon = "Hand"       },
            { id = "sit",      label = "S'asseoir",      icon = "Armchair"   },
            { id = "lay",      label = "S'allonger",     icon = "BedDouble"  },
            { id = "dance",    label = "Danser",         icon = "Music"      },
            { id = "stopanim", label = "Stop anim",      icon = "StopCircle" },
        },
    })

    table.insert(items, { id = "inventory", label = "Inventaire", icon = "Backpack" })

    if IsPlayerAdmin() then
        table.insert(items, {
            id         = "admin_global",
            label      = "⚡ Admin",
            icon       = "Shield",
            badge      = GetAdminRole(),
            badgeColor = "#f59e0b",
            submenu    = {
                { id = "adm_tp_waypoint", label = "TP waypoint",     icon = "Navigation" },
                { id = "adm_god",         label = "God mode",        icon = "Shield"     },
                { id = "adm_heal_self",   label = "Heal",            icon = "Heart"      },
                { id = "adm_delete",      label = "Delete véhicule", icon = "Trash2"     },
                { id = "adm_invisible",   label = "Invisible",       icon = "EyeOff"     },
            },
        })
    end

    OpenContextMenu(x, y, items, "🌍 Interaction")
end
