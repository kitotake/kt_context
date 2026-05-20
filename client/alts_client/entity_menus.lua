-- =============================================
-- MODULE : MENUS ENTITÉS
-- Fournit BuildNpcMenu, BuildVehicleMenu,
-- BuildPropMenu, BuildAdminEntityMenu
--
-- FIX CRITIQUE : les champs `action = function()`
-- ne peuvent PAS être sérialisés en JSON par SendNUIMessage.
-- Solution : registre local _pendingActions[id] = fn
-- Les items passent uniquement des strings en JSON.
-- Le handler menuAction dans main.lua consulte ce registre.
-- =============================================

-- ─── Registre d'actions dynamiques ───────────────────────────────────────────
-- Peuplé par Build*Menu, vidé à chaque ouverture de menu.
_pendingActions = {}

local function registerAction(id, fn)
    _pendingActions[id] = fn
    return id   -- retourne l'id pour pouvoir l'utiliser inline
end

local function clearPendingActions()
    _pendingActions = {}
end

-- Appelé par main.lua depuis RegisterNUICallback('menuAction')
-- pour exécuter une action dynamique si elle existe.
function ExecutePendingAction(id)
    local fn = _pendingActions[id]
    if fn then
        fn()
        return true
    end
    return false
end

-- ─── Véhicule ─────────────────────────────────────────────────────────────────
function BuildVehicleMenu(veh, locked, isAdmin)
    clearPendingActions()
    local items = {}

    local engHealth  = math.floor(GetVehicleEngineHealth(veh)  / 10)
    local bodyHealth = math.floor(GetVehicleBodyHealth(veh)    / 10)
    local fuel       = math.floor(GetVehicleFuelLevel(veh))
    local plateText  = GetVehicleNumberPlateText(veh)

    table.insert(items, {
        id          = "veh_info",
        label       = "Informations",
        icon        = "Info",
        disabled    = true,
        description = ("Moteur %d%% | Carrosserie %d%% | Essence %d%%"):format(
                        engHealth, bodyHealth, fuel),
    })

    if plateText and #plateText > 0 then
        table.insert(items, {
            id          = "veh_plate",
            label       = "Plaque : " .. plateText,
            icon        = "SquareDot",
            disabled    = true,
        })
    end

    table.insert(items, { id = "_div_veh1", divider = true, label = "" })

    table.insert(items, {
        id    = "veh_lock",
        label = locked and "Déverrouiller" or "Verrouiller",
        icon  = locked and "LockOpen" or "Lock",
    })

    local ped      = PlayerPedId()
    local isDriver = GetPedInVehicleSeat(veh, -1) == ped
    local engineOn = GetIsVehicleEngineRunning(veh)

    table.insert(items, {
        id       = "veh_engine",
        label    = engineOn and "Éteindre le moteur" or "Allumer le moteur",
        icon     = "Zap",
        disabled = not isDriver,
    })

    -- Lumières : action enregistrée dans le registre, pas dans l'item
    registerAction("veh_lights", function()
        local v = GetVehiclePedIsIn(PlayerPedId(), false)
        if v ~= 0 then
            local on, _ = GetVehicleLightsState(v)
            SetVehicleLights(v, on == 1 and 0 or 2)
            ShowNotification(on == 1 and "Lumières éteintes" or "Lumières allumées", 'info')
        end
    end)
    table.insert(items, { id = "veh_lights", label = "Lumières", icon = "Lightbulb" })

    table.insert(items, {
        id      = "veh_doors",
        label   = "Portes",
        icon    = "DoorOpen",
        submenu = {
            { id = "door_fl",        label = "Avant gauche",   icon = "SquareDot"  },
            { id = "door_fr",        label = "Avant droite",   icon = "SquareDot"  },
            { id = "door_rl",        label = "Arrière gauche", icon = "SquareDot"  },
            { id = "door_rr",        label = "Arrière droite", icon = "SquareDot"  },
            { id = "door_hood",      label = "Capot",          icon = "SquareDot"  },
            { id = "door_trunk",     label = "Coffre",         icon = "SquareDot"  },
            { id = "_div_doors",     divider = true, label = "" },
            { id = "door_all_open",  label = "Toutes ouvrir",  icon = "DoorOpen"   },
            { id = "door_all_close", label = "Toutes fermer",  icon = "DoorClosed" },
        },
    })

    table.insert(items, {
        id      = "veh_windows",
        label   = "Vitres",
        icon    = "Maximize2",
        submenu = {
            { id = "win_down", label = "Toutes descendre", icon = "ArrowDown" },
            { id = "win_up",   label = "Toutes monter",    icon = "ArrowUp"   },
        },
    })

    return items
end

-- ─── PNJ ──────────────────────────────────────────────────────────────────────
function BuildNpcMenu(ped, isAdmin)
    clearPendingActions()
    local hp = math.max(0, math.floor(GetEntityHealth(ped) - 100))
    return {
        {
            id          = "npc_info",
            label       = "PNJ",
            icon        = "Bot",
            disabled    = true,
            description = ("Santé : %d%%"):format(hp),
        },
        { id = "_div_npc1", divider = true, label = "" },
        { id = "npc_drag",    label = "Traîner",   icon = "Hand"          },
        { id = "npc_interact",label = "Interagir", icon = "MessageCircle" },
    }
end

-- ─── Joueur ───────────────────────────────────────────────────────────────────
function BuildPlayerMenu(serverId, name, isAdmin)
    clearPendingActions()

    -- Actions joueur spécifiques : enregistrées dans le registre avec l'id serveur capturé
    registerAction("pl_tp_to", function()
        local playerId = GetPlayerFromServerId(serverId)
        if playerId ~= -1 then
            local targetPed = GetPlayerPed(playerId)
            local c = GetEntityCoords(targetPed)
            SetEntityCoords(PlayerPedId(), c.x + 1.5, c.y, c.z)
            ShowNotification("Téléporté vers " .. name, 'success')
        else
            ShowNotification("Joueur introuvable", 'error')
        end
    end)

    return {
        {
            id          = "pl_info",
            label       = name,
            icon        = "User",
            disabled    = true,
            description = ("ID Serveur : %d"):format(serverId),
        },
        { id = "_div_pl1", divider = true, label = "" },
        { id = "pl_trade", label = "Proposer un échange", icon = "Handshake" },
        {
            id      = "pl_money",
            label   = "Donner de l'argent",
            icon    = "Banknote",
            submenu = {
                { id = "give_50",     label = "Donner 50$",     icon = "DollarSign" },
                { id = "give_100",    label = "Donner 100$",    icon = "DollarSign" },
                { id = "give_500",    label = "Donner 500$",    icon = "DollarSign" },
                { id = "give_custom", label = "Montant libre…", icon = "PenLine"    },
            },
        },
        {
            id      = "pl_emotes",
            label   = "Interactions sociales",
            icon    = "Smile",
            submenu = {
                { id = "pl_wave",      label = "Saluer",         icon = "Hand"      },
                { id = "pl_handshake", label = "Serrer la main", icon = "Handshake" },
                { id = "pl_hug",       label = "Câlin",          icon = "Heart"     },
            },
        },
    }
end

-- ─── Objet / Prop ─────────────────────────────────────────────────────────────
function BuildPropMenu(prop, isAdmin)
    clearPendingActions()
    local heading = GetEntityHeading(prop)
    return {
        {
            id          = "prop_info",
            label       = "Objet",
            icon        = "Package",
            disabled    = true,
            description = ("Heading : %.1f°"):format(heading),
        },
        { id = "_div_prop1", divider = true, label = "" },
        { id = "prop_examine", label = "Examiner",  icon = "ScanSearch" },
        { id = "prop_pickup",  label = "Ramasser",  icon = "HandCoins"  },
    }
end

-- ─── Admin — menu entité ──────────────────────────────────────────────────────
function BuildAdminEntityMenu(entity, entityType)
    -- Note : on N'appelle PAS clearPendingActions() ici car cette fonction
    -- est appelée APRÈS Build*Menu — on ajoute au registre existant.

    local items = {}

    -- Coordonnées : enregistrée dans le registre (capture entity)
    registerAction("adm_coords_entity", function()
        ShowNotification("📍 " .. FormatCoords(GetEntityCoords(entity)), 'info')
    end)
    table.insert(items, { id = "adm_coords_entity", label = "Coordonnées", icon = "MapPin" })

    -- Geler / Dégeler
    registerAction("adm_freeze_entity", function()
        local frozen = IsEntityPositionFrozen(entity)
        FreezeEntityPosition(entity, not frozen)
        ShowNotification(frozen and "Entité dégelée" or "Entité gelée", 'info')
    end)
    table.insert(items, { id = "adm_freeze_entity", label = "Geler / Dégeler", icon = "Snowflake" })

    -- Supprimer
    registerAction("adm_delete_entity", function()
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
        ShowNotification("Entité supprimée", 'success')
        TriggerServerEvent('kt_context:logAdminAction', 'delete_entity', nil, 'Delete entity')
    end)
    table.insert(items, {
        id      = "adm_delete_entity",
        label   = "Supprimer",
        icon    = "Trash2",
        variant = "danger",
    })

    -- Véhicule
    if entityType == 2 then
        table.insert(items, { id = "_div_adm_veh", divider = true, label = "" })
        table.insert(items, { id = "adm_repair", label = "Réparer",           icon = "Wrench", variant = "success" })
        table.insert(items, { id = "adm_refuel", label = "Remplir réservoir", icon = "Fuel"   })

        registerAction("adm_copy_plate", function()
            local plate = GetVehicleNumberPlateText(entity)
            ShowNotification("Plaque : " .. (plate or "?"), 'info')
        end)
        table.insert(items, { id = "adm_copy_plate", label = "Copier la plaque", icon = "ClipboardCopy" })
    end

    -- Joueur
    if entityType == 1 and IsPedAPlayer(entity) then
        local localId = NetworkGetPlayerIndexFromPed(entity)
        if localId ~= -1 then
            local serverId = GetPlayerServerId(localId)
            table.insert(items, { id = "_div_adm_pl", divider = true, label = "" })

            registerAction("adm_tp_to_player", function()
                local c = GetEntityCoords(entity)
                SetEntityCoords(PlayerPedId(), c.x + 1.5, c.y, c.z)
                ShowNotification("Téléporté", 'success')
                TriggerServerEvent('kt_context:logAdminAction', 'tp_to_player', serverId, 'TP to player')
            end)
            table.insert(items, { id = "adm_tp_to_player", label = "TP vers ce joueur", icon = "ArrowRight" })

            registerAction("adm_kick_player", function()
                TriggerServerEvent('kt_context:admin:kick', serverId, "Expulsé par un administrateur")
            end)
            table.insert(items, {
                id      = "adm_kick_player",
                label   = "Expulser",
                icon    = "UserX",
                variant = "danger",
            })
        end
    end

    return items
end