import type { ReactNode } from 'react'

export interface MenuItem {
  id: string
  label: string
  icon?: string
  iconNode?: ReactNode
  disabled?: boolean
  action?: () => void | Promise<void>
  submenu?: MenuItem[]
  description?: string
  color?: string
  badge?: string
  badgeColor?: string
  variant?: 'default' | 'success' | 'warning' | 'danger'
  divider?: boolean
  cooldown?: number
  hidden?: boolean
  // Checkbox
  type?: 'default' | 'checkbox'
  checked?: boolean
  onChange?: (checked: boolean) => void
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
  x: number
  y: number
}

export interface NotificationData {
  message: string
  type?: 'info' | 'success' | 'warning' | 'error'
  duration?: number
}

export interface ZoneChangeData {
  inZone: boolean
  zoneId?: string
  title?: string
}