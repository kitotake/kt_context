import type { ReactNode } from 'react'

export interface MenuItem {
  id: string
  label: string
  icon?: string           // Nom d'icône Lucide
  iconNode?: ReactNode    // Nœud React custom
  disabled?: boolean
  action?: () => void | Promise<void>
  submenu?: MenuItem[]
  description?: string
  color?: string          // Couleur de l'accent gauche
  badge?: string          // Badge texte (ex: rôle admin)
  badgeColor?: string
  variant?: 'default' | 'success' | 'warning' | 'danger'
  divider?: boolean       // Séparateur visuel
}

export interface MenuPosition {
  x: number
  y: number
}

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

export interface CursorState {
  visible: boolean
  x: number   // 0..1 normalisé
  y: number
}
