-- =============================================
-- EXEMPLES D'UTILISATION AVANCÉE
-- =============================================

-- ── Exemple 1 : Menu d'interaction joueur ────────────────────────────────────
function OpenPlayerInteractionMenu(targetId, targetName)
    local sw, sh = GetActiveScreenResolution()
    local items  = {
        { id='player_info',  label='Voir l\'identité',    icon='User',      description=targetName },
        { id='player_trade', label='Proposer un échange', icon='Handshake' },
        {
            id='player_money', label='Transactions', icon='Banknote',
            submenu = {
                { id='give_50',     label='Donner 50$',    icon='DollarSign' },
                { id='give_100',    label='Donner 100$',   icon='DollarSign' },
                { id='give_500',    label='Donner 500$',   icon='DollarSign' },
                { id='give_custom', label='Montant libre…', icon='PenLine'   },
            }
        },
        {
            id='player_emotes', label='Interactions sociales', icon='Smile',
            submenu = {
                { id='handshake', label='Serrer la main',     icon='Handshake' },
                { id='hug',       label='Câlin',              icon='Heart'     },
                { id='high_five', label='Taper dans la main', icon='Star'      },
            }
        },
    }

    -- Options admin conditionnelles (utilise IsPlayerAdmin() de sync.lua)
    if IsPlayerAdmin() then
        table.insert(items, {
            id='player_admin', label='Actions Admin', icon='ShieldAlert',
            badge='admin', badgeColor='#f59e0b',
            submenu = {
                { id='adm_tp_to',   label='Se TP vers lui',    icon='ArrowRight' },
                { id='adm_tp_here', label='TP lui vers moi',   icon='ArrowLeft'  },
                { id='adm_kick',    label='Expulser',          icon='UserX',    variant='danger'  },
                { id='adm_ban',     label='Bannir',            icon='ShieldOff',variant='danger'  },
                { id='adm_heal_t',  label='Soigner le joueur', icon='Heart',    variant='success' },
            }
        })
    end

    OpenContextMenu(sw / 2, sh / 2, items, '👤 ' .. targetName)
end

-- ── Exemple 2 : Menu véhicule complet ────────────────────────────────────────
function OpenAdvancedVehicleMenu()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then veh = GetVehiclePedIsIn(ped, true) end

    if veh == 0 then
        ShowNotification(L('no_vehicle'), 'error')
        return
    end

    local isDriver   = GetPedInVehicleSeat(veh, -1) == ped
    local locked     = GetVehicleDoorLockStatus(veh) == 2
    local engineOn   = GetIsVehicleEngineRunning(veh)
    local fuelLevel  = GetVehicleFuelLevel(veh)
    local engHealth  = GetVehicleEngineHealth(veh)
    local bodyHealth = GetVehicleBodyHealth(veh)

    local items = {
        {
            id='veh_info', label='Informations', icon='Info',
            description=string.format('Moteur %.0f%% | Carrosserie %.0f%% | Essence %.0f%%',
                engHealth/10, bodyHealth/10, fuelLevel)
        },
        {
            id='veh_lock',
            label=locked and 'Déverrouiller' or 'Verrouiller',
            icon=locked and 'LockOpen' or 'Lock',
        },
        {
            id='veh_engine', label='Gestion moteur', icon='Zap',
            disabled=not isDriver,
            submenu = {
                { id='engine_toggle', label=engineOn and 'Éteindre' or 'Allumer', icon='Power' },
                { id='engine_boost',  label='Mode sport', icon='Gauge', description='Meilleures performances' },
            }
        },
        {
            id='veh_doors', label='Portes', icon='DoorOpen',
            submenu = {
                { id='door_fl',    label='Avant gauche',   icon='SquareDot' },
                { id='door_fr',    label='Avant droite',   icon='SquareDot' },
                { id='door_rl',    label='Arrière gauche', icon='SquareDot' },
                { id='door_rr',    label='Arrière droite', icon='SquareDot' },
                { id='door_hood',  label='Capot',          icon='SquareDot' },
                { id='door_trunk', label='Coffre',         icon='SquareDot' },
                { id='_divd', divider=true, label='' },
                { id='door_all_close', label='Tout fermer', icon='Lock' },
            }
        },
        {
            id='veh_windows', label='Vitres', icon='Maximize2',
            submenu = {
                { id='win_up',   label='Toutes monter',    icon='ArrowUp'   },
                { id='win_down', label='Toutes descendre', icon='ArrowDown' },
            }
        },
    }

    -- Options admin
    if IsPlayerAdmin() then
        table.insert(items, { id='_divadm', divider=true, label='' })
        table.insert(items, {
            id='veh_admin', label='Admin Véhicule', icon='ShieldAlert',
            badge=GetAdminRole(), badgeColor='#f59e0b',
            submenu = {
                { id='adm_repair',  label='Réparer complètement', icon='Wrench', variant='success' },
                { id='adm_refuel',  label='Remplir le réservoir', icon='Fuel',   variant='success' },
                { id='adm_upgrade', label='Améliorer au max',     icon='Star'    },
                { id='adm_delete',  label='Supprimer',            icon='Trash2', variant='danger'  },
            }
        })
    end

    local sw, sh = GetActiveScreenResolution()
    OpenContextMenu(sw / 2, sh / 2, items, '🚗 Menu Véhicule')
end

-- ── Exemple 3 : Zones interactives ───────────────────────────────────────────
Citizen.CreateThread(function()
    Wait(2000)

    -- Zone mécanique
    RegisterMenuZone({
        id     = 'zone_meca',
        coords = vector3( ),
        radius = 3.5,
        shape  = 'circle',
        title  = '🔧 Atelier Mécanique',
        hint   = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder à l\'atelier',
        marker = { type=2, color={r=59,g=130,b=246,a=130}, size=vector3(3.5,3.5,0.3) },
        items  = {
            { id='repair_veh',   label='Réparer le véhicule',   icon='Wrench'  },
            { id='upgrade_veh',  label='Améliorer le véhicule', icon='Star'    },
            { id='change_color', label='Changer la couleur',    icon='Palette' },
        },
    })

    -- Zone banque
    RegisterMenuZone({
        id     = 'zone_bank',
        coords = vector3(150.15, -1040.9, 29.37),
        radius = 4.0,
        shape  = 'circle',
        title  = '🏦 Banque',
        hint   = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder à la banque',
        marker = { type=2, color={r=16,g=185,b=129,a=130}, size=vector3(4.0,4.0,0.3) },
        items  = {
            { id='bank_deposit',  label='Déposer',    icon='ArrowUpFromLine' },
            { id='bank_withdraw', label='Retirer',    icon='ArrowDownToLine' },
            { id='bank_balance',  label='Voir solde', icon='Wallet'          },
        },
    })

    -- Zone police (conditionnelle — utilise IsPlayerAdmin ou ton propre check)
    RegisterMenuZone({
        id     = 'zone_police',
        coords = vector3(441.43, -982.14, 30.69),
        radius = 5.0,
        shape  = 'circle',
        title  = '👮 Commissariat',
        hint   = 'Appuyez sur ~INPUT_CONTEXT~ pour les services de police',
        marker = { type=2, color={r=239,g=68,b=68,a=110}, size=vector3(5.0,5.0,0.3) },
        -- Retire la condition ou mets la tienne (ex: vérifier un job)
        items  = {
            { id='police_duty',   label='Prise de service',      icon='Shield' },
            { id='police_armory', label='Armurerie',             icon='Swords' },
            { id='police_garage', label='Garage',                icon='Car'    },
            { id='police_jail',   label='Gérer les prisonniers', icon='Lock'   },
        },
    })
end)

-- ── Commandes de test ─────────────────────────────────────────────────────────
RegisterCommand('vmenu', OpenAdvancedVehicleMenu, false)

RegisterCommand('cmenu', function()
    local sw, sh = GetActiveScreenResolution()
    OpenGeneralContextMenu(sw / 2, sh / 2)
end, false)

RegisterCommand('testzone', function()
    RegisterMenuZone({
        id     = 'zone_test_' .. GetGameTimer(),
        coords = GetEntityCoords(PlayerPedId()),
        radius = 3.0,
        title  = '🧪 Zone Test',
        hint   = 'Test de zone – ~INPUT_CONTEXT~',
        marker = { type=2, color={r=245,g=158,b=11,a=150}, size=vector3(3.0,3.0,0.3) },
        items  = {
            { id='test_1', label='Action 1', icon='Zap'   },
            { id='test_2', label='Action 2', icon='Star'  },
            { id='test_3', label='Action 3', icon='Heart' },
        },
    })
    ShowNotification('Zone test créée à votre position', 'success')
end, false)

RegisterKeyMapping('cmenu', 'Ouvrir le menu contextuel général', 'keyboard', 'RMENU')