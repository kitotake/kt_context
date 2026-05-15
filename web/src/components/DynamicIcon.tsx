import { type FC } from 'react'
import * as LucideIcons from 'lucide-react'

interface DynamicIconProps {
  name: string
  size?: number
  className?: string
}

/**
 * Résout dynamiquement un nom d'icône Lucide en composant React.
 * Si le nom n'existe pas, retourne une icône de substitution (Circle).
 */
const DynamicIcon: FC<DynamicIconProps> = ({ name, size = 17, className }) => {
  const icons = LucideIcons as unknown as Record<
    string,
    FC<{ size?: number; className?: string }>
  >
  const Icon = icons[name] ?? icons['Circle']
  return <Icon size={size} className={className} />
}

export default DynamicIcon