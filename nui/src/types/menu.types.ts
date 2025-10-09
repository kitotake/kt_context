export interface MenuItem {
  id: string;
  label: string;
  icon?: React.ReactNode | string;
  disabled?: boolean;
  action?: () => void | Promise<void>;
  submenu?: MenuItem[];
  description?: string;
  color?: string;
  variant?: 'default' | 'success' | 'warning' | 'danger';
}

export interface MenuPosition {
  x: number;
  y: number;
}

export interface ContextMenuProps {
  visible: boolean;
  position: MenuPosition;
  items: MenuItem[];
  onClose: () => void;
  title?: string;
}

export interface ContextMenuState {
  visible: boolean;
  position: { x: number; y: number };
  items: MenuItem[];
  title?: string;
}