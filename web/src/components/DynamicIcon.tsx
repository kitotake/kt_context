import { type FC } from 'react'
import * as LucideIcons from 'lucide-react'

interface DynamicIconProps {
  name: string
  size?: number
  className?: string
}

const ICON_ALIASES: Record<string, string> = {
  Move3d:        'Move3D',
  move3d:        'Move3D',
  ArrowLeftRight:'ArrowLeftRight',
  ArrowUpDown:   'ArrowUpDown',
  RotateCcw:     'RotateCcw',
  RotateCw:      'RotateCw',
  RefreshCcw:    'RefreshCcw',
  RefreshCw:     'RefreshCw',
  StopCircle:    'StopCircle',
  DoorOpen:      'DoorOpen',
  DoorClosed:    'DoorClosed',
  BedDouble:     'BedDouble',
  MessageCircle: 'MessageCircle',
  ShieldAlert:   'ShieldAlert',
  LockOpen:      'LockOpen',
  ClipboardCopy: 'ClipboardCopy',
  ScanSearch:    'ScanSearch',
  HandCoins:     'HandCoins',
  CircleDot:     'CircleDot',
}

const DynamicIcon: FC<DynamicIconProps> = ({ name, size = 17, className }) => {
  const icons = LucideIcons as unknown as Record<
    string,
    FC<{ size?: number; className?: string }>
  >
  const resolved = ICON_ALIASES[name] ?? name
  const Icon = icons[resolved] ?? icons[name] ?? icons['Circle']
  return <Icon size={size} className={className} />
}

export default DynamicIcon