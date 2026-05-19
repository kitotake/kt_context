import { useState, useRef, useCallback, useEffect, type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { ChevronRight } from 'lucide-react'
import type { MenuItem } from '../types/menu.types'
import DynamicIcon from './DynamicIcon'
import CheckboxItem from './CheckboxItem'
import { sendNui } from '../utils/nui'

interface Props {
  item: MenuItem
  onClose: () => void
  depth?: number
}

const SUBMENU_VARIANTS = {
  hidden:  { opacity: 0, x: -8,  scale: 0.97 },
  visible: { opacity: 1, x: 0,   scale: 1,   transition: { duration: 0.16, ease: [0.16, 1, 0.3, 1] as const } },
  exit:    { opacity: 0, x: -5,  scale: 0.98, transition: { duration: 0.1 } },
}

// Délai suffisant pour traverser le gap entre item et sous-menu
const CLOSE_DELAY = 200

const MenuItemRow: FC<Props> = ({ item, onClose, depth = 0 }) => {
  const [open,     setOpen]     = useState(false)
  const [openLeft, setOpenLeft] = useState(false)
  const wrapperRef    = useRef<HTMLDivElement>(null)
  const closeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const variantClass = item.variant && item.variant !== 'default'
    ? `cm-item--${item.variant}` : ''

  const badgeStyle = item.badgeColor
    ? { background: `${item.badgeColor}22`, color: item.badgeColor, borderColor: `${item.badgeColor}55` }
    : undefined

  const itemStyle = item.color ? { borderLeftColor: item.color } : undefined

  useEffect(() => {
    if (!open || !wrapperRef.current) return
    const rect = wrapperRef.current.getBoundingClientRect()
    setOpenLeft(rect.right + 270 > window.innerWidth)
  }, [open])

  const cancelClose = useCallback(() => {
    if (closeTimerRef.current) {
      clearTimeout(closeTimerRef.current)
      closeTimerRef.current = null
    }
  }, [])

  const scheduleClose = useCallback(() => {
    cancelClose()
    closeTimerRef.current = setTimeout(() => setOpen(false), CLOSE_DELAY)
  }, [cancelClose])

  useEffect(() => () => {
    if (closeTimerRef.current) clearTimeout(closeTimerRef.current)
  }, [])

  const handleClick = useCallback(async () => {
    if (item.disabled) return
    if (item.submenu && item.submenu.length > 0) {
      setOpen(p => !p)
      return
    }
    if (item.action) {
      try { await item.action() } catch (e) { console.error(e) }
    }
    await sendNui('menuAction', { id: item.id })
    onClose()
  }, [item, onClose])

  const handleMouseEnter = useCallback(() => {
    if (item.submenu?.length) {
      cancelClose()
      setOpen(true)
    }
  }, [item.submenu, cancelClose])

  const handleMouseLeave = useCallback(() => {
    if (item.submenu?.length) scheduleClose()
  }, [item.submenu, scheduleClose])

  // Position du sous-menu
  const subLeft  = openLeft ? 'auto' : 'calc(100% + 2px)'
  const subRight = openLeft ? 'calc(100% + 2px)' : 'auto'

  const subStyle: React.CSSProperties = {
    left:  subLeft,
    right: subRight,
    top:   '-4px',
  }

  // FIX: Bridge invisible qui couvre le gap entre .cm-item et .cm-sub
  // Empêche le mouseLeave de se déclencher quand on traverse ce gap
  const bridgeStyle: React.CSSProperties = {
    position: 'absolute',
    top:      0,
    bottom:   0,
    width:    '8px', // couvre le gap de 2px + marge de sécurité
    zIndex:   99,
    // À gauche ou à droite selon l'ouverture
    ...(openLeft
      ? { right: 'calc(100% + 2px)', left: 'auto' }
      : { left:  'calc(100% + 2px)', right: 'auto' }
    ),
  }

  if ('checked' in item) {
    return (
      <CheckboxItem
        id={item.id}
        label={item.label}
        checked={item.checked ?? false}
        disabled={item.disabled ?? false}
        description={item.description}
        onChange={item.onChange}
      />
    )
  }

  return (
    <div
      ref={wrapperRef}
      className="cm-item-wrapper"
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      <div
        role="menuitem"
        tabIndex={item.disabled ? -1 : 0}
        aria-disabled={item.disabled}
        aria-haspopup={item.submenu ? 'menu' : undefined}
        aria-expanded={item.submenu ? open : undefined}
        className={`cm-item ${variantClass} ${item.disabled ? 'cm-item--disabled' : ''}`.trim()}
        style={itemStyle}
        onClick={handleClick}
        onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleClick() }}
      >
        <div className="cm-item__left">
          {(item.icon || item.iconNode) && (
            <span className="cm-item__icon">
              {item.iconNode ?? <DynamicIcon name={item.icon!} />}
            </span>
          )}
          <div className="cm-item__text">
            <span className="cm-item__label">{item.label}</span>
            {item.description && <span className="cm-item__desc">{item.description}</span>}
          </div>
        </div>

        <div className="cm-item__right">
          {item.badge && (
            <span className="cm-item__badge" style={badgeStyle}>{item.badge}</span>
          )}
          {item.submenu && item.submenu.length > 0 && (
            <span className={`cm-item__arrow${open ? ' cm-item__arrow--open' : ''}`}>
              <ChevronRight size={14} />
            </span>
          )}
        </div>
      </div>

      {/* FIX: Bridge invisible pour combler le gap item → sous-menu */}
      {item.submenu && item.submenu.length > 0 && open && (
        <div
          style={bridgeStyle}
          onMouseEnter={cancelClose}
          onMouseLeave={scheduleClose}
        />
      )}

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
              onMouseEnter={cancelClose}
              onMouseLeave={scheduleClose}
            >
              {item.submenu.map(sub =>
                sub.divider
                  ? <div key={sub.id} className="cm-divider" />
                  : <MenuItemRow key={sub.id} item={sub} onClose={onClose} depth={depth + 1} />
              )}
            </motion.div>
          )}
        </AnimatePresence>
      )}
    </div>
  )
}

export default MenuItemRow