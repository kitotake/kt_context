import type { ReactNode } from 'react'

// ─── Item de menu ─────────────────────────────────────────────────────────────
export interface MenuItem {
  id: string
  label: string
  icon?: string           // Nom icône Lucide
  iconNode?: ReactNode    // Nœud React custom
  disabled?: boolean
  action?: () => void | Promise<void>
  submenu?: MenuItem[]
  description?: string
  color?: string          // Couleur accent gauche
  badge?: string
  badgeColor?: string
  variant?: 'default' | 'success' | 'warning' | 'danger'
  divider?: boolean
  cooldown?: number       // ms — délai avant re-sélection (inspiré kt_target)
  hidden?: boolean        // masqué mais conservé dans le DOM
  checked?: boolean       // Pour les checkbox items
  onChange?: (checked: boolean) => void  // Callback pour checkbox items
}

// ─── Position ─────────────────────────────────────────────────────────────────
export interface MenuPosition {
  x: number
  y: number
}

// ─── État du menu contextuel ──────────────────────────────────────────────────
export interface ContextMenuState {
  visible: boolean
  position: MenuPosition
  items: MenuItem[]
  title?: string
  theme?: 'dark' | 'light'
  animate?: boolean
}

export interface ContextMenuProps extends ContextMenuState {
  onClose: () => void
}

// ─── Curseur ─────────────────────────────────────────────────────────────────
export interface CursorState {
  visible: boolean
  x: number   // 0..1 normalisé
  y: number
  theme?: 'default' | 'interact' | 'grab' | 'pointer'
}

// ─── Menu radial ─────────────────────────────────────────────────────────────
export interface RadialItem {
  id: string
  label: string
  icon: string
  submenu?: string
  action?: string
}

export interface RadialMenuData {
  title: string
  items: RadialItem[]
  parent?: string
}

// ─── Zone NUI ─────────────────────────────────────────────────────────────────
export interface ZoneChangeData {
  inZone: boolean
  zoneId?: string
  title?: string
}

// ─── Notification (nouveau) ────────────────────────────────────────────────────
export interface NotificationData {
  message: string
  type?: 'info' | 'success' | 'warning' | 'error'
  duration?: number
}