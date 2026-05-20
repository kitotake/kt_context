import { useEffect, useRef, type FC } from 'react'
import ContextMenu from './components/ContextMenu'
import Cursor from './components/Cursor'
import { useContextMenu } from './hooks/useContextMenu'
import { useCursor } from './hooks/useCursor'
import { isEnvBrowser, sendNui } from './utils/nui'
import type { MenuItem } from './types/menu.types'

const DEV_ITEMS: MenuItem[] = [
  {
    id: 'player_actions', label: 'Actions joueur', icon: 'User2',
    submenu: [
      { id: 'wave',     label: 'Saluer',       icon: 'Hand'       },
      { id: 'sit',      label: "S'asseoir",    icon: 'Armchair'   },
      { id: 'lay',      label: "S'allonger",   icon: 'BedDouble'  },
      { id: 'stopanim', label: 'Arrêter anim', icon: 'StopCircle' },
    ],
  },
  {
    id: 'vehicle', label: 'Véhicule', icon: 'Car',
    submenu: [
      { id: 'veh_lock',   label: 'Verrouiller', icon: 'Lock' },
      { id: 'veh_engine', label: 'Moteur',       icon: 'Zap'  },
      {
        id: 'veh_doors', label: 'Portes', icon: 'DoorOpen',
        submenu: [
          { id: 'door_fl',        label: 'Avant gauche',   icon: 'SquareDot'  },
          { id: 'door_fr',        label: 'Avant droite',   icon: 'SquareDot'  },
          { id: 'door_rl',        label: 'Arrière gauche', icon: 'SquareDot'  },
          { id: 'door_rr',        label: 'Arrière droite', icon: 'SquareDot'  },
          { id: 'door_hood',      label: 'Capot',          icon: 'SquareDot'  },
          { id: 'door_trunk',     label: 'Coffre',          icon: 'SquareDot'  },
          { id: '_div_doors',     divider: true, label: '' },
          { id: 'door_all_open',  label: 'Toutes ouvrir',  icon: 'DoorOpen'   },
          { id: 'door_all_close', label: 'Toutes fermer',  icon: 'DoorClosed' },
        ],
      },
    ],
  },
  { id: 'inventory', label: 'Inventaire', icon: 'Backpack', description: 'Voir mes objets' },
  { id: 'phone',     label: 'Téléphone',  icon: 'Phone' },
  { id: '_div1', divider: true, label: '' },
  {
    id: 'admin_section', label: 'Options Admin', icon: 'ShieldAlert',
    badge: 'admin', badgeColor: '#fbbf24',
    submenu: [
      { id: 'adm_tp_waypoint', label: 'TP Waypoint',        icon: 'Navigation'                  },
      { id: 'adm_god',         label: 'God Mode',           icon: 'Shield'                      },
      { id: 'adm_heal_self',   label: 'Se soigner',         icon: 'Heart',  variant: 'success'  },
      { id: 'adm_delete',      label: 'Supprimer véhicule', icon: 'Trash2', variant: 'danger'   },
    ],
  },
  { id: 'disabled_opt', label: 'Option désactivée', icon: 'Ban', disabled: true },
]

const App: FC = () => {
  const { state, openMenu, closeMenu } = useContextMenu()
  const { cursor } = useCursor()

  // Ref pour savoir si le curseur Lua est actif (évite d'intercepter des clics normaux)
  const cursorActiveRef = useRef(false)

  useEffect(() => {
    document.body.style.visibility = 'visible'
  }, [])

  useEffect(() => {
    // Sync l'état curseur depuis les messages NUI
    const handler = (e: MessageEvent) => {
      if (e.data?.type === 'cursorShow') {
        cursorActiveRef.current = e.data.data?.visible ?? false
      }
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  useEffect(() => {
    if (isEnvBrowser()) return // En dev, on utilise onContextMenu à la place

    // ── FiveM build ──────────────────────────────────────────────────────────
    // Quand le curseur Lua est actif (ALT maintenu), chaque mousedown gauche
    // envoie les coords pixel réels à Lua via NUI callback "cursorClick".
    // Lua fait le raycast avec ces coords (converties en normalisé) pour
    // identifier l'entité 3D, puis répond avec openContextMenu { x, y, items }.
    // Le menu s'affiche exactement à ces mêmes coordonnées pixel.
    const onMouseDown = (e: MouseEvent) => {
      if (e.button !== 0) return               // clic gauche uniquement
      if (!cursorActiveRef.current) return     // seulement en mode curseur ALT
      if (state.visible) return                // menu déjà ouvert → laisser React gérer

      e.preventDefault()
      // Envoyer les coords pixel exactes à Lua
      sendNui('cursorClick', { x: e.clientX, y: e.clientY })
    }

    window.addEventListener('mousedown', onMouseDown)
    return () => window.removeEventListener('mousedown', onMouseDown)
  }, [state.visible])

  // ── DEV : clic droit pour tester à la position exacte ───────────────────
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault()
    openMenu(e.clientX, e.clientY, DEV_ITEMS, 'Menu Contextuel')
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
          <div style={{ fontSize: 22, color: '#e2e8f0', fontWeight: 300 }}>v3.0</div>
          <div style={{ marginTop: 16, fontSize: 11, color: '#334155', display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ background: '#0d1017', border: '1px solid rgba(255,255,255,0.08)', padding: '2px 6px', borderRadius: 3, fontSize: 10, color: '#4f8ef7' }}>
              CLIC DROIT
            </span>
            <span>pour tester — le menu s'ouvre à la position du clic</span>
          </div>
        </div>
      )}

      <Cursor cursor={cursor} />

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