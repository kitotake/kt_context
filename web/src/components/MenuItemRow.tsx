import { useState, useRef, useCallback, useEffect, type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { ChevronRight } from 'lucide-react'
import type { MenuItem } from '../types/menu.types'
import DynamicIcon from './DynamicIcon'
import { sendNui } from '../utils/nui'

interface Props {
  item: MenuItem
  onClose: () => void
  depth?: number
}

const SUBMENU_VARIANTS = {
  hidden: { opacity: 0, x: -10, scale: 0.96 },
  visible: {
    opacity: 1,
    x: 0,
    scale: 1,
    transition: { duration: 0.18, ease: [0.16, 1, 0.3, 1] },
  },
  exit: { opacity: 0, x: -6, scale: 0.97, transition: { duration: 0.12 } },
}

const MenuItemRow: FC<Props> = ({ item, onClose, depth = 0 }) => {
  const [open, setOpen] = useState(false)
  // Détermine si le sous-menu doit s'ouvrir à gauche (near right edge)
  const [openLeft, setOpenLeft] = useState(false)
  const wrapperRef = useRef<HTMLDivElement>(null)

  // Classe variante CSS
  const variantClass =
    item.variant && item.variant !== 'default' ? `cm-item--${item.variant}` : ''

  // Couleur badge personnalisée
  const badgeStyle = item.badgeColor
    ? {
        background: `${item.badgeColor}22`,
        color: item.badgeColor,
        borderColor: `${item.badgeColor}55`,
      }
    : undefined

  // Couleur de la bordure gauche (custom override)
  const itemStyle = item.color ? { borderLeftColor: item.color } : undefined

  /**
   * Détecte si le sous-menu déborderait sur le bord droit de l'écran.
   * Si oui, on l'ouvre vers la gauche.
   */
  useEffect(() => {
    if (!open || !wrapperRef.current) return
    const rect = wrapperRef.current.getBoundingClientRect()
    const SUB_WIDTH = 260 // min-width du sous-menu
    const wouldOverflow = rect.right + SUB_WIDTH + 12 > window.innerWidth
    setOpenLeft(wouldOverflow)
  }, [open])

  const handleClick = useCallback(async () => {
    if (item.disabled) return

    if (item.submenu && item.submenu.length > 0) {
      setOpen(prev => !prev)
      return
    }

    // Action locale optionnelle
    if (item.action) {
      try {
        await item.action()
      } catch (e) {
        console.error('[MenuItemRow] action error:', e)
      }
    }

    // Callback NUI → Lua
    await sendNui('menuAction', { id: item.id })
    onClose()
  }, [item, onClose])

  const handleMouseEnter = () => {
    if (item.submenu && item.submenu.length > 0) setOpen(true)
  }

  const handleMouseLeave = (e: React.MouseEvent) => {
    if (item.submenu && item.submenu.length > 0) {
      const related = e.relatedTarget as Node | null
      if (wrapperRef.current?.contains(related)) return
      setOpen(false)
    }
  }

  // Positionnement du sous-menu (gauche ou droite)
  const subStyle: React.CSSProperties = openLeft
    ? { right: 'calc(100% + 6px)', left: 'auto' }
    : { left: 'calc(100% + 6px)' }

  return (
    <div
      ref={wrapperRef}
      className="cm-item-wrapper"
      style={{ position: 'relative' }}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      {/* ── Ligne principale ──────────────────────────────────────── */}
      <div
        role="menuitem"
        tabIndex={item.disabled ? -1 : 0}
        aria-disabled={item.disabled}
        aria-haspopup={item.submenu ? 'menu' : undefined}
        aria-expanded={item.submenu ? open : undefined}
        className={`cm-item ${variantClass} ${item.disabled ? 'cm-item--disabled' : ''}`}
        style={itemStyle}
        onClick={handleClick}
        onKeyDown={e => {
          if (e.key === 'Enter' || e.key === ' ') handleClick()
        }}
      >
        {/* Gauche */}
        <div className="cm-item__left">
          {/* Icône */}
          {(item.icon || item.iconNode) && (
            <span className="cm-item__icon">
              {item.iconNode ?? <DynamicIcon name={item.icon!} />}
            </span>
          )}

          {/* Texte */}
          <div className="cm-item__text">
            <span className="cm-item__label">{item.label}</span>
            {item.description && (
              <span className="cm-item__desc">{item.description}</span>
            )}
          </div>
        </div>

        {/* Droite */}
        <div className="cm-item__right">
          {item.badge && (
            <span className="cm-item__badge" style={badgeStyle}>
              {item.badge}
            </span>
          )}
          {item.submenu && item.submenu.length > 0 && (
            <span className="cm-item__arrow">
              <ChevronRight size={14} />
            </span>
          )}
        </div>
      </div>

      {/* ── Sous-menu (hover/click) ───────────────────────────────── */}
      {item.submenu && item.submenu.length > 0 && depth < 6 && (
        <AnimatePresence>
          {open && (
            <motion.div
              className="cm-sub"
              role="menu"
              style={subStyle}
              variants={SUBMENU_VARIANTS}
              initial="hidden"
              animate="visible"
              exit="exit"
            >
              {item.submenu.map(sub =>
                sub.divider ? (
                  <div key={sub.id} className="cm-divider" />
                ) : (
                  <MenuItemRow
                    key={sub.id}
                    item={sub}
                    onClose={onClose}
                    depth={depth + 1}
                  />
                )
              )}
            </motion.div>
          )}
        </AnimatePresence>
      )}
    </div>
  )
}

export default MenuItemRow