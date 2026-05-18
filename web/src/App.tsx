import { useEffect, type FC } from 'react'
import ContextMenu from './components/ContextMenu'
import { useContextMenu } from './hooks/useContextMenu'
import { isEnvBrowser } from './utils/nui'
import type { MenuItem } from './types/menu.types'

/* ── Items de démonstration (mode navigateur seulement) ─────────────────── */
const DEV_ITEMS: MenuItem[] = [
  {
    id: 'player_actions',
    label: 'Actions joueur',
    icon: 'User2',
    submenu: [
      { id: 'wave',     label: 'Saluer',       icon: 'Hand'       },
      { id: 'sit',      label: "S'asseoir",    icon: 'Armchair'   },
      { id: 'lay',      label: "S'allonger",   icon: 'BedDouble'  },
      { id: 'stopanim', label: 'Arrêter anim', icon: 'StopCircle' },
    ],
  },
  {
    id: 'vehicle',
    label: 'Véhicule',
    icon: 'Car',
    submenu: [
      { id: 'veh_lock',   label: 'Verrouiller', icon: 'Lock' },
      { id: 'veh_engine', label: 'Moteur',       icon: 'Zap'  },
      {
        id: 'veh_doors',
        label: 'Portes',
        icon: 'DoorOpen',
        submenu: [
          { id: 'door_fl',    label: 'Avant gauche',   icon: 'SquareDot' },
          { id: 'door_fr',    label: 'Avant droite',   icon: 'SquareDot' },
          { id: 'door_rl',    label: 'Arrière gauche', icon: 'SquareDot' },
          { id: 'door_rr',    label: 'Arrière droite', icon: 'SquareDot' },
          { id: 'door_hood',  label: 'Capot',          icon: 'SquareDot' },
          { id: 'door_trunk', label: 'Coffre',         icon: 'SquareDot' },
        ],
      },
    ],
  },
  {
    id: 'inventory',
    label: 'Inventaire',
    icon: 'Backpack',
    description: 'Voir mes objets',
  },
  { id: 'phone', label: 'Téléphone', icon: 'Phone' },
  { id: '_div1', divider: true, label: '' },
  {
    id: 'admin_section',
    label: '⚡ Options Admin',
    icon: 'ShieldAlert',
    badge: 'admin',
    badgeColor: '#f59e0b',
    submenu: [
      { id: 'adm_coords_self', label: 'Mes coordonnées',    icon: 'MapPin'     },
      { id: 'adm_tp_waypoint', label: 'TP Waypoint',        icon: 'Navigation' },
      { id: 'adm_noclip',      label: 'NoClip',             icon: 'Ghost'      },
      { id: 'adm_god',         label: 'God Mode',           icon: 'Shield',   checked: false },
      { id: 'adm_heal_self',   label: 'Se soigner',         icon: 'Heart',   variant: 'success' as const },
      { id: 'adm_delete_veh',  label: 'Supprimer véhicule', icon: 'Trash2',  variant: 'danger'  as const },
    ],
  },
  { id: 'disabled_opt', label: 'Option désactivée', icon: 'Ban', disabled: true },
]

/* ── App ────────────────────────────────────────────────────────────────── */
const App: FC = () => {
  const { state, openMenu, closeMenu } = useContextMenu()

  /* En mode FiveM, le body est masqué par défaut; visible seulement via NUI */
  useEffect(() => {
    if (isEnvBrowser()) {
      document.body.style.visibility = 'visible'
    }
  }, [])

  /* Mode dev : clic droit pour ouvrir un menu de test */
  const handleContextMenu = (e: React.MouseEvent) => {
    if (!isEnvBrowser()) return
    e.preventDefault()
    openMenu(e.clientX, e.clientY, DEV_ITEMS, '🌍 Menu Contextuel — Dev')
  }

  return (
    <>
      {/* Zone de démonstration (navigateur uniquement) */}
      {isEnvBrowser() && (
        <div
          onContextMenu={handleContextMenu}
          style={{
            position: 'fixed',
            inset: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexDirection: 'column',
            gap: 12,
            background:
              'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%)',
            pointerEvents: 'all',
            cursor: 'context-menu',
          }}
        >
          <h1
            style={{
              color: '#f1f5f9',
              fontSize: 32,
              fontWeight: 800,
              letterSpacing: -1,
            }}
          >
            KT Context Menu <span style={{ color: '#3b82f6' }}>v2</span>
          </h1>
          <p style={{ color: '#64748b', fontSize: 15 }}>
            Clic droit n'importe où pour ouvrir le menu (mode dev)
          </p>
          <p style={{ color: '#475569', fontSize: 13, marginTop: 8 }}>
            En jeu : maintenez{' '}
            <kbd
              style={{
                background: '#1e293b',
                color: '#94a3b8',
                padding: '2px 6px',
                borderRadius: 4,
                border: '1px solid #334155',
              }}
            >
              ALT
            </kbd>{' '}
            puis cliquez sur une entité
          </p>
        </div>
      )}

      {/* Menu contextuel */}
      <ContextMenu
        visible={state.visible}
        position={state.position}
        items={state.items}
        title={state.title}
        onClose={closeMenu}
        theme={state.theme}
        animate={state.animate}
      />
    </>
  )
}

export default App