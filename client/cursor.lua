-- =============================================
-- SYSTÈME CURSEUR CONTEXTUEL (ALT GAUCHE)
-- VERSION STABLE / CLEAN
-- =============================================

local CURSOR_KEY = Config and Config.CursorKey or 19

local cursorActive = false

-- =============================================
-- HELPERS
-- =============================================

function IsCursorActive()
    return cursorActive
end

local function SafeIsMenuOpen()
    if IsMenuOpen then
        return IsMenuOpen()
    end

    return false
end

local function GetClosestVehicleData(coords)
    local interactionDistance = Config.InteractionDistance or 5.0

    local vehicle = GetClosestVehicle(
        coords.x,
        coords.y,
        coords.z,
        interactionDistance,
        0,
        70
    )

    if vehicle and vehicle ~= 0 then
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(coords - vehCoords)

        return vehicle, dist
    end

    return -1, math.huge
end

-- =============================================
-- THREAD PRINCIPAL CURSEUR
-- =============================================

Citizen.CreateThread(function()
    while true do
        local sleep = 100

        if IsControlPressed(0, CURSOR_KEY) and not SafeIsMenuOpen() then
            sleep = 0

            if not cursorActive then
                cursorActive = true

                -- Affiche le curseur réel
                SetNuiFocus(true, true)

                SendNUIMessage({
                    type = 'cursorShow',
                    data = {
                        visible = true
                    }
                })
            end

            -- Désactive caméra / tir
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)

            DisableControlAction(0, 18, true)
            DisableControlAction(0, 142, true)

            -- Clic
            if IsControlJustReleased(0, 24) then
                local sw, sh = GetActiveScreenResolution()
                
                -- Récupère la position EXACTE de la souris en pixels
                local mouseX, mouseY = GetNuiCursorPosition()
                
                -- Convertit en coordonnées normalisées (0-1)
                local normalizedX = mouseX / sw
                local normalizedY = mouseY / sh

                HandleCursorClick(mouseX, mouseY, normalizedX, normalizedY)
            end

        elseif cursorActive then
            cursorActive = false

            -- Désactive le curseur réel
            SetNuiFocus(false, false)

            SendNUIMessage({
                type = 'cursorShow',
                data = {
                    visible = false
                }
            })
        end

        Wait(sleep)
    end
end)

-- =============================================
-- GESTION DU CLIC
-- =============================================

function HandleCursorClick(nx, ny)
    local sw, sh = GetActiveScreenResolution()

    local camCoords = GetGameplayCamCoords()
    local camRot = GetGameplayCamRot(2)

    local direction = RotationToDirection(camRot)

    local startCoord = camCoords
    local endCoord = startCoord + (direction * 100.0)

    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        startCoord.x,
        startCoord.y,
        startCoord.z,
        endCoord.x,
        endCoord.y,
        endCoord.z,
        511,
        PlayerPedId(),
        7
    )

    local _, hit, _, _, hitEntity = GetShapeTestResult(ray)

    local menuX = sw * 0.5
    local menuY = sh * 0.5

    if hit == 1 and hitEntity ~= 0 then
        local entityType = GetEntityType(hitEntity)

        OpenContextForEntity(
            hitEntity,
            entityType,
            menuX,
            menuY
        )
    else
        OpenGeneralContextMenu(menuX, menuY)
    end
end

-- =============================================
-- MENU SELON ENTITÉ
-- =============================================

function OpenContextForEntity(entity, entityType, x, y)
    local isAdmin = IsPlayerAdmin()
    local adminRole = GetAdminRole()

    local items = {}

    -- PED
    if entityType == 1 then
        if IsPedAPlayer(entity) then
            local playerId = NetworkGetPlayerIndexFromPed(entity)

            if playerId ~= -1 then
                local playerName = GetPlayerName(playerId) or 'Joueur'
                local serverId = GetPlayerServerId(playerId)

                items = BuildPlayerMenu(
                    serverId,
                    playerName,
                    isAdmin
                )
            else
                items = BuildNpcMenu(entity, isAdmin)
            end
        else
            items = BuildNpcMenu(entity, isAdmin)
        end

    -- VEHICULE
    elseif entityType == 2 then
        local locked = GetVehicleDoorLockStatus(entity) ~= 1

        items = BuildVehicleMenu(
            entity,
            locked,
            isAdmin
        )

    -- OBJET
    elseif entityType == 3 then
        items = BuildPropMenu(entity, isAdmin)

    else
        OpenGeneralContextMenu(x, y)
        return
    end

    -- Section admin
    if isAdmin and adminRole then
        table.insert(items, {
            id = '_div_admin',
            divider = true,
            label = ''
        })

        table.insert(items, {
            id = 'admin_section',
            label = '⚡ ' .. L('admin_options') .. ' [' .. adminRole .. ']',
            icon = 'ShieldAlert',
            badge = adminRole,
            badgeColor = '#f59e0b',
            submenu = BuildAdminEntityMenu(entity, entityType)
        })
    end

    OpenContextMenu(
        x,
        y,
        items,
        GetEntityMenuTitle(entityType, entity)
    )
end

-- =============================================
-- TITRE MENU
-- =============================================

function GetEntityMenuTitle(entityType, entity)
    if entityType == 1 then
        return IsPedAPlayer(entity)
            and '👤 Joueur'
            or '🤖 PNJ'
    elseif entityType == 2 then
        return '🚗 Véhicule'
    elseif entityType == 3 then
        return '📦 Objet'
    end

    return '🌍 Interaction'
end

-- =============================================
-- MENU GÉNÉRAL
-- =============================================

function OpenGeneralContextMenu(x, y)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local items = {}

    -- Véhicule proche
    local veh, vehDist = GetClosestVehicleData(coords)

    if veh ~= -1 and vehDist < (Config.InteractionDistance or 5.0) then
        table.insert(items, {
            id = 'nearby_vehicle',
            label = ('Véhicule (%.1fm)'):format(vehDist),
            icon = 'Car',

            submenu = BuildVehicleMenu(
                veh,
                GetVehicleDoorLockStatus(veh) ~= 1,
                IsPlayerAdmin()
            )
        })
    end

    -- Actions joueur
    table.insert(items, {
        id = 'player_actions',
        label = 'Actions joueur',
        icon = 'User2',

        submenu = {
            {
                id = 'handsup',
                label = "Mains en l'air",
                icon = 'HandMetal'
            },
            {
                id = 'sit',
                label = "S'asseoir",
                icon = 'Armchair'
            },
            {
                id = 'lay',
                label = "S'allonger",
                icon = 'BedDouble'
            },
            {
                id = 'dance',
                label = 'Danser',
                icon = 'Music'
            },
            {
                id = 'stopanim',
                label = 'Arrêter anim',
                icon = 'StopCircle'
            }
        }
    })

    table.insert(items, {
        id = 'inventory',
        label = 'Inventaire',
        icon = 'Backpack',
        description = 'Voir mes objets'
    })

    table.insert(items, {
        id = 'phone',
        label = 'Téléphone',
        icon = 'Phone'
    })

    -- Admin
    if IsPlayerAdmin() then
        local role = GetAdminRole()

        table.insert(items, {
            id = '_div',
            divider = true,
            label = ''
        })

        table.insert(items, {
            id = 'admin_general',
            label = '⚡ Options Admin',
            icon = 'ShieldAlert',
            badge = role,
            badgeColor = '#f59e0b',

            submenu = {
                {
                    id = 'adm_coords_self',
                    label = 'Mes coordonnées',
                    icon = 'MapPin',
                    description = FormatCoords(coords),
                    disabled = true
                },
                {
                    id = 'adm_tp_waypoint',
                    label = 'TP Waypoint',
                    icon = 'Navigation'
                },
                {
                    id = 'adm_god',
                    label = 'God Mode',
                    icon = 'Shield'
                },
                {
                    id = 'adm_invisible',
                    label = 'Invisible',
                    icon = 'EyeOff'
                },
                {
                    id = 'adm_heal_self',
                    label = 'Se soigner',
                    icon = 'Heart',
                    color = '#10b981'
                },
                {
                    id = 'adm_armor_self',
                    label = 'Armure',
                    icon = 'ShieldCheck',
                    color = '#3b82f6'
                },
                {
                    id = 'adm_delete',
                    label = 'Suppr. véhicule',
                    icon = 'Trash2',
                    color = '#ef4444'
                },
                {
                    id = 'adm_repair',
                    label = 'Réparer véhicule',
                    icon = 'Wrench',
                    color = '#10b981'
                }
            }
        })
    end

    OpenContextMenu(x, y, items, '🌍 Interaction')
end