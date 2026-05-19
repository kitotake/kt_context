import { useEffect, type FC } from 'react'
import ContextMenu from './components/ContextMenu'
import Cursor from './components/Cursor'
import { useContextMenu } from './hooks/useContextMenu'
import { useCursor } from './hooks/useCursor'
import { isEnvBrowser, sendNui } from './utils/nui'
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
    label: 'Options Admin',
    icon: 'ShieldAlert',
    badge: 'admin',
    badgeColor: '#fbbf24',
    submenu: [
      { id: 'adm_tp_waypoint', label: 'TP Waypoint',        icon: 'Navigation' },
      { id: 'adm_god',         label: 'God Mode',           icon: 'Shield'     },
      { id: 'adm_heal_self',   label: 'Se soigner',         icon: 'Heart',   variant: 'success' as const },
      { id: 'adm_delete_veh',  label: 'Supprimer véhicule', icon: 'Trash2',  variant: 'danger'  as const },
    ],
  },
  { id: 'disabled_opt', label: 'Option désactivée', icon: 'Ban', disabled: true },
]

/* ── App ────────────────────────────────────────────────────────────────── */
const App: FC = () => {
  const { state, openMenu, closeMenu } = useContextMenu()
  const { cursor } = useCursor()

  useEffect(() => {
    if (isEnvBrowser()) {
      document.body.style.visibility = 'visible'
    }
  }, [])

  // ── Gestion du clic dans l'overlay NUI (FiveM) ───────────────────────────
  // Quand le joueur est en mode curseur (ALT), chaque clic gauche est capturé
  // et envoyé à Lua avec les coordonnées EXACTES du clic
  useEffect(() => {
    const handleWindowClick = (e: MouseEvent) => {
      // En mode FiveM avec focus NUI, on transmet le clic à Lua
      if (!isEnvBrowser() && cursor.visible) {
        e.preventDefault()
        sendNui('cursorClick', { x: e.clientX, y: e.clientY })
      }
    }

    window.addEventListener('click', handleWindowClick)
    return () => window.removeEventListener('click', handleWindowClick)
  }, [cursor.visible])

  /* Mode dev : clic droit pour ouvrir un menu de test */
  const handleContextMenu = (e: React.MouseEvent) => {
    if (!isEnvBrowser()) return
    e.preventDefault()
    // Position exacte du clic droit
    openMenu(e.clientX, e.clientY, DEV_ITEMS, 'Menu Contextuel')
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
            gap: 10,
            background: '#060810',
            pointerEvents: 'all',
            cursor: 'context-menu',
            fontFamily: "'JetBrains Mono', monospace",
          }}
        >
          <div style={{
            fontSize: 11,
            letterSpacing: '0.14em',
            color: '#334155',
            textTransform: 'uppercase',
            fontWeight: 600,
          }}>
            KT Context Menu
          </div>
          <div style={{
            fontSize: 22,
            color: '#e2e8f0',
            fontWeight: 300,
            letterSpacing: '-0.02em',
          }}>
            v3.0
          </div>
          <div style={{
            marginTop: 16,
            fontSize: 11,
            color: '#334155',
            display: 'flex',
            alignItems: 'center',
            gap: 8,
          }}>
            <span style={{
              background: '#0d1017',
              border: '1px solid rgba(255,255,255,0.08)',
              padding: '2px 6px',
              borderRadius: 3,
              fontSize: 10,
              color: '#4f8ef7',
              letterSpacing: '0.08em',
            }}>
              CLIC DROIT
            </span>
            <span>pour tester le menu</span>
          </div>
        </div>
      )}

      {/* Curseur (affiché uniquement si cursor.visible — piloté par Lua) */}
      <Cursor cursor={cursor} />

      {/* Menu contextuel — s'ouvre à la position exacte du clic */}
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