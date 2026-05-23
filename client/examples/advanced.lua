-- =============================================
-- EXEMPLES D'UTILISATION AVANCÉE — v3.2
-- =============================================

-- ── Exemple 1 : Menu joueur ───────────────────────────────────────────────────
function OpenPlayerInteractionMenu(targetId, targetName)
    local sw, sh = GetActiveScreenResolution()
    local items  = {
        { id='player_info',  label="Voir l'identité",    icon='User',      disabled=true, description=targetName },
        { id='player_trade', label='Proposer un échange', icon='Handshake' },
        {
            id='player_money', label='Transactions', icon='Banknote',
            submenu = {
                { id='give_50',     label='Donner 50$',     icon='DollarSign' },
                { id='give_100',    label='Donner 100$',    icon='DollarSign' },
                { id='give_500',    label='Donner 500$',    icon='DollarSign' },
                { id='give_custom', label='Montant libre…', icon='PenLine'    },
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

    if IsPlayerAdmin() then
        table.insert(items, {
            id='player_admin', label='Actions Admin', icon='ShieldAlert',
            badge='admin', badgeColor='#f59e0b',
            submenu = {
                { id='adm_tp_to',   label='Se TP vers lui',    icon='ArrowRight'                          },
                { id='adm_tp_here', label='TP lui vers moi',   icon='ArrowLeft'                           },
                { id='adm_kick',    label='Expulser',          icon='UserX',    variant='danger' },
                { id='adm_heal_t',  label='Soigner le joueur', icon='Heart',    variant='success' },
            }
        })
    end

    OpenContextMenu(sw/2, sh/2, items, '👤 ' .. targetName)
end

-- ── Exemple 2 : Menu overlay (usage externe) ─────────────────────────────────
function OpenOverlayMenuExample()
    local sw, sh = GetActiveScreenResolution()
    OpenContextMenu(sw/2, sh/2, BuildOverlayMenu(), '👁️ Affichages')
end

-- ── Exemple 3 : Zone interactive ─────────────────────────────────────────────
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

-- ── Commandes de test ─────────────────────────────────────────────────────────
RegisterCommand('vmenu', function()
    local sw, sh = GetActiveScreenResolution()
    OpenGeneralContextMenu(sw/2, sh/2)
end, false)

RegisterCommand('ovmenu', function()
    local sw, sh = GetActiveScreenResolution()
    OpenContextMenu(sw/2, sh/2, BuildOverlayMenu(), '👁️ Affichages')
end, false)

RegisterKeyMapping('vmenu', 'Ouvrir le menu général', 'keyboard', 'RMENU')