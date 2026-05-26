import { useEffect, useRef, type FC } from 'react'
import ContextMenu from './components/ContextMenu'
import Cursor from './components/Cursor'
import NotificationSystem from './components/NotificationSystem'
import { useContextMenu } from './hooks/useContextMenu'
import { useCursor } from './hooks/useCursor'
import { isEnvBrowser, sendNui } from './utils/nui'
import type { MenuItem } from './types/menu.types'

// ── Items de démo (navigateur) ────────────────────────────────────────────────
const DEV_ITEMS: MenuItem[] = [
  {
    id: 'player_actions', label: 'Actions joueur', icon: 'User2',
    submenu: [
      { id: 'wave',     label: 'Saluer (cooldown 2s)', icon: 'Hand'       },
      { id: 'sit',      label: "S'asseoir",            icon: 'Armchair'   },
      { id: 'lay',      label: "S'allonger",           icon: 'BedDouble'  },
      { id: 'stopanim', label: 'Arrêter anim',         icon: 'StopCircle' },
    ],
  },
  {
    id: 'vehicle', label: 'Véhicule', icon: 'Car',
    submenu: [
      { id: 'veh_lock',   label: 'Verrouiller', icon: 'Lock' },
      { id: 'veh_engine', label: 'Moteur',      icon: 'Zap'  },
      {
        id: 'veh_doors', label: 'Portes', icon: 'DoorOpen',
        submenu: [
          { id: 'door_fl',        label: 'Avant gauche',  icon: 'SquareDot' },
          { id: 'door_fr',        label: 'Avant droite',  icon: 'SquareDot' },
          { id: 'door_all_open',  label: 'Toutes ouvrir', icon: 'DoorOpen'  },
          { id: 'door_all_close', label: 'Toutes fermer', icon: 'DoorClosed'},
        ],
      },
    ],
  },
  // ── Overlays avec checkboxes ────────────────────────────────────────────────
  {
    id: 'overlays', label: 'Affichages', icon: 'Eye',
    submenu: [
      {
        id: 'overlay_player_names', label: 'Noms des joueurs',
        icon: 'Users', type: 'checkbox', checked: false,
        description: 'Distance max : 30m',
      },
      {
        id: 'overlay_player_blips', label: 'Blips joueurs sur carte',
        icon: 'MapPin', type: 'checkbox', checked: false,
        description: 'Portée : 200m',
      },
      {
        id: 'overlay_range_circle', label: 'Cercle de portée',
        icon: 'CircleDot', type: 'checkbox', checked: false,
        description: 'Rayon : 50m',
      },
      {
        id: 'overlay_vehicle_info', label: 'Infos véhicules',
        icon: 'Car', type: 'checkbox', checked: false,
        description: 'Portée : 15m',
      },
    ],
  },
  {
    id: 'prop_menu', label: 'Gestion Objets', icon: 'Package',
    submenu: [
      { id: 'rot_z_p',     label: 'Yaw +15',        icon: 'RotateCw'                    },
      { id: 'rot_z_m',     label: 'Yaw -15',        icon: 'RotateCcw'                   },
      { id: 'rot_reset',   label: 'Reset rotation', icon: 'RefreshCw', variant: 'warning' as const },
      { id: 'prop_freeze', label: 'Geler/Dégeler',  icon: 'Snowflake'                   },
      { id: '_divprop',    divider: true, label: ''                                      },
      { id: 'prop_delete', label: 'Supprimer',      icon: 'Trash2',    variant: 'danger' as const  },
    ],
  },
  { id: 'inventory', label: 'Inventaire', icon: 'Backpack', description: 'Voir mes objets' },
  { id: '_div1', divider: true, label: '' },
  {
    id: 'admin_section', label: 'Options Admin', icon: 'ShieldAlert',
    badge: 'admin', badgeColor: '#fbbf24',
    submenu: [
      { id: 'adm_tp_waypoint', label: 'TP Waypoint',        icon: 'Navigation'                         },
      { id: 'adm_god',         label: 'God Mode',           icon: 'Shield'                             },
      { id: 'adm_heal_self',   label: 'Se soigner',         icon: 'Heart',  variant: 'success' as const },
      { id: 'adm_delete',      label: 'Supprimer véhicule', icon: 'Trash2', variant: 'danger'  as const },
    ],
  },
  { id: 'disabled_opt', label: 'Option désactivée', icon: 'Ban', disabled: true },
]

const App: FC = () => {
  const { state, openMenu, closeMenu } = useContextMenu()
  const { cursor } = useCursor()
  const cursorActiveRef = useRef(false)

  useEffect(() => {
    document.body.style.visibility = 'visible'
  }, [])

  useEffect(() => {
    const handler = (e: MessageEvent) => {
      if (e.data?.type === 'cursorShow') {
        cursorActiveRef.current = e.data.data?.visible ?? false
      }
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  useEffect(() => {
    if (isEnvBrowser()) return
    const onMouseDown = (e: MouseEvent) => {
      if (e.button !== 0) return
      if (!cursorActiveRef.current) return
      if (state.visible) return
      e.preventDefault()
      sendNui('cursorClick', { x: e.clientX, y: e.clientY })
    }
    window.addEventListener('mousedown', onMouseDown)
    return () => window.removeEventListener('mousedown', onMouseDown)
  }, [state.visible])

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault()
    openMenu(e.clientX, e.clientY, DEV_ITEMS, '🌍 Interaction')
  }

  return (
    <>
      {isEnvBrowser() && (
        <div
          onContextMenu={handleContextMenu}
          style={{
            position: 'fixed', inset: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexDirection: 'column', gap: 10,
            background: '#060810', pointerEvents: 'all', cursor: 'context-menu',
            fontFamily: "'JetBrains Mono', monospace",
          }}
        >
          <div style={{ fontSize: 11, letterSpacing: '0.14em', color: '#334155', textTransform: 'uppercase', fontWeight: 600 }}>
            KT Context Menu
          </div>
          <div style={{ fontSize: 22, color: '#e2e8f0', fontWeight: 300 }}>v3.2</div>
          <div style={{ marginTop: 16, fontSize: 11, color: '#334155', display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ background: '#0d1017', border: '1px solid rgba(255,255,255,0.08)', padding: '2px 6px', borderRadius: 3, fontSize: 10, color: '#4f8ef7' }}>
              CLIC DROIT
            </span>
            <span>pour tester — checkboxes dans Affichages</span>
          </div>
        </div>
      )}

      <Cursor cursor={cursor} />
      <NotificationSystem />

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
