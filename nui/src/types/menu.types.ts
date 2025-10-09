export interface MenuItem {
    id: string;
    label: string;
    icon?: React.ReactNode;
    disabled?: boolean;
    action?: () => void;
    submenu?: MenuItem[];
    description?: string;
    color?: string; 
  }
  
  export interface ContextMenuProps {
    visible: boolean;
    position: { x: number; y: number };
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