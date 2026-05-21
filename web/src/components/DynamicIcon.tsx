import { type FC } from 'react'
import * as LucideIcons from 'lucide-react'

interface DynamicIconProps {
  name: string
  size?: number
  className?: string
}

// FIX : certains noms d'icônes ont changé entre versions de lucide-react.
// Cette map fournit des aliases pour la version 0.400.0 utilisée ici.
const ICON_ALIASES: Record<string, string> = {
  // 'Move3d' n'existe pas en 0.400.0 → 'Move3D' (PascalCase exact)
  Move3d:          'Move3D',
  move3d:          'Move3D',
  // Aliases courants pour éviter les erreurs si Lua envoie des noms légèrement différents
  ArrowLeftRight:  'ArrowLeftRight',
  ArrowUpDown:     'ArrowUpDown',
  RotateCcw:       'RotateCcw',
  RotateCw:        'RotateCw',
  RefreshCcw:      'RefreshCcw',
  RefreshCw:       'RefreshCw',
  StopCircle:      'StopCircle',
  DoorOpen:        'DoorOpen',
  DoorClosed:      'DoorClosed',
  BedDouble:       'BedDouble',
  MessageCircle:   'MessageCircle',
  ShieldAlert:     'ShieldAlert',
  LockOpen:        'LockOpen',
  ClipboardCopy:   'ClipboardCopy',
  ScanSearch:      'ScanSearch',
  HandCoins:       'HandCoins',
}

/**
 * Résout dynamiquement un nom d'icône Lucide en composant React.
 * Gère les aliases inter-versions et retourne Circle en fallback.
 */
const DynamicIcon: FC<DynamicIconProps> = ({ name, size = 17, className }) => {
  const icons = LucideIcons as unknown as Record<
    string,
    FC<{ size?: number; className?: string }>
  >

  // Résolution : nom brut → alias → fallback Circle
  const resolved = ICON_ALIASES[name] ?? name
  const Icon = icons[resolved] ?? icons[name] ?? icons['Circle']

  return <Icon size={size} className={className} />
}

export default DynamicIcon