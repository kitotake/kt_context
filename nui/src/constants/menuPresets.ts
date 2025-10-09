import type { MenuItem } from '../types/menu.types';

export const MENU_PRESETS = {
  player: (targetId: number, _targetName: string): MenuItem[] => [
    {
      id: 'view_id',
      label: 'Voir identité',
      icon: '👤',
      description: `ID: ${targetId}`,
    },
    {
      id: 'trade',
      label: 'Échanger',
      icon: '🤝',
    },
    {
      id: 'give_money',
      label: 'Donner argent',
      icon: '💵',
    },
  ],

  vehicle: (locked: boolean, engineOn: boolean): MenuItem[] => [
    {
      id: 'lock',
      label: locked ? 'Déverrouiller' : 'Verrouiller',
      icon: locked ? '🔓' : '🔒',
    },
    {
      id: 'engine',
      label: engineOn ? 'Éteindre moteur' : 'Allumer moteur',
      icon: '🔌',
    },
    {
      id: 'doors',
      label: 'Portes',
      icon: '🚪',
      submenu: [
        { id: 'door_fl', label: 'Avant gauche' },
        { id: 'door_fr', label: 'Avant droite' },
        { id: 'door_rl', label: 'Arrière gauche' },
        { id: 'door_rr', label: 'Arrière droite' },
      ],
    },
  ],

  admin: (_targetId: number): MenuItem[] => [
    {
      id: 'admin_tp',
      label: 'Téléporter',
      icon: '📍',
    },
    {
      id: 'admin_spectate',
      label: 'Spectater',
      icon: '👁️',
    },
    {
      id: 'admin_kick',
      label: 'Kick',
      icon: '❌',
    },
    {
      id: 'admin_ban',
      label: 'Ban',
      icon: '🚫',
    },
  ],
};