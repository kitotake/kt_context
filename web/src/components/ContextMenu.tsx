import { useEffect, useRef, useCallback, type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'
import type { ContextMenuProps } from '../types/menu.types'
import MenuItemRow from './MenuItemRow'
import { sendNui } from '../utils/nui'

/* ── Variantes Framer Motion ─────────────────────────────────────────────── */
const MENU_VARIANTS = {
  hidden: {
    opacity: 0,
    scale: 0.93,
    y: -8,
    filter: 'blur(4px)',
  },
  visible: {
    opacity: 1,
    scale: 1,
    y: 0,
    filter: 'blur(0px)',
    transition: { duration: 0.22, ease: [0.16, 1, 0.3, 1] },
  },
  exit: {
    opacity: 0,
    scale: 0.95,
    y: -4,
    filter: 'blur(2px)',
    transition: { duration: 0.14 },
  },
}

const OVERLAY_VARIANTS = {
  hidden:  { opacity: 0 },
  visible: { opacity: 1, transition: { duration: 0.18 } },
  exit:    { opacity: 0, transition: { duration: 0.14 } },
}

/* ── Composant ───────────────────────────────────────────────────────────── */
const ContextMenu: FC<ContextMenuProps> = ({
  visible,
  position,
  items,
  title,
  onClose,
}) => {
  const menuRef = useRef<HTMLDivElement>(null)

  /* Fermeture */
  const handleClose = useCallback(async () => {
    onClose()
    await sendNui('menuClosed', {})
  }, [onClose])

  /* ESC pour fermer */
  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [visible, handleClose])

  /* Repositionnement pour rester dans l'écran */
  useEffect(() => {
    if (!visible || !menuRef.current) return
    const rect = menuRef.current.getBoundingClientRect()
    const margin = 12

    let x = position.x
    let y = position.y

    if (x + rect.width > window.innerWidth - margin)
      x = window.innerWidth - rect.width - margin
    if (y + rect.height > window.innerHeight - margin)
      y = window.innerHeight - rect.height - margin

    x = Math.max(margin, x)
    y = Math.max(margin, y)

    menuRef.current.style.left = `${x}px`
    menuRef.current.style.top  = `${y}px`
  }, [visible, position])

  return (
    <AnimatePresence>
      {visible && (
        <>
          {/* ── Overlay ─────────────────────────────────────────────── */}
          <motion.div
            className="cm-overlay"
            variants={OVERLAY_VARIANTS}
            initial="hidden"
            animate="visible"
            exit="exit"
            onClick={handleClose}
          />

          {/* ── Menu ────────────────────────────────────────────────── */}
          <motion.div
            ref={menuRef}
            className="cm"
            role="menu"
            aria-label={title ?? 'Menu contextuel'}
            style={{ left: position.x, top: position.y }}
            variants={MENU_VARIANTS}
            initial="hidden"
            animate="visible"
            exit="exit"
          >
            {/* Header */}
            {title && (
              <div className="cm__header">
                <h3 className="cm__title">{title}</h3>
                <button
                  className="cm__close"
                  onClick={handleClose}
                  aria-label="Fermer"
                >
                  <X />
                </button>
              </div>
            )}

            {/* Items */}
            <div className="cm__body">
              {items.length > 0 ? (
                items.map(item =>
                  item.divider
                    ? <div key={item.id} className="cm-divider" />
                    : (
                      <MenuItemRow
                        key={item.id}
                        item={item}
                        onClose={handleClose}
                        depth={0}
                      />
                    )
                )
              ) : (
                <p className="cm__empty">Aucune option disponible</p>
              )}
            </div>

            {/* Footer */}
            <div className="cm__footer">
              <span>Échap pour fermer</span>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

export default ContextMenu
