import { useEffect, useRef, useCallback, type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'
import type { ContextMenuProps } from '../types/menu.types'
import MenuItemRow from './MenuItemRow'
import { sendNui } from '../utils/nui'

const MENU_VARIANTS = {
  hidden: {
    opacity: 0,
    scale: 0.94,
    y: -6,
    filter: 'blur(3px)',
  },
  visible: {
    opacity: 1,
    scale: 1,
    y: 0,
    filter: 'blur(0px)',
    transition: { duration: 0.2, ease: [0.16, 1, 0.3, 1] },
  },
  exit: {
    opacity: 0,
    scale: 0.96,
    y: -3,
    filter: 'blur(2px)',
    transition: { duration: 0.12 },
  },
}

const OVERLAY_VARIANTS = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { duration: 0.15 } },
  exit: { opacity: 0, transition: { duration: 0.12 } },
}

const MARGIN = 12

function clampPosition(x: number, y: number, width: number, height: number) {
  return {
    x: Math.max(MARGIN, Math.min(x, window.innerWidth - width - MARGIN)),
    y: Math.max(MARGIN, Math.min(y, window.innerHeight - height - MARGIN)),
  }
}

const ContextMenu: FC<ContextMenuProps> = ({
  visible,
  position,
  items,
  title,
  onClose,
}) => {
  const menuRef = useRef<HTMLDivElement>(null)

  const handleClose = useCallback(async () => {
    onClose()
    await sendNui('menuClosed', {})
  }, [onClose])

  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [visible, handleClose])

  // Correction de position après premier paint
  useEffect(() => {
    if (!visible || !menuRef.current) return
    const rect = menuRef.current.getBoundingClientRect()
    const { x, y } = clampPosition(position.x, position.y, rect.width, rect.height)
    menuRef.current.style.left = `${x}px`
    menuRef.current.style.top = `${y}px`
  }, [visible, position])

  return (
    <AnimatePresence>
      {visible && (
        <>
          <motion.div
            className="cm-overlay"
            variants={OVERLAY_VARIANTS}
            initial="hidden"
            animate="visible"
            exit="exit"
            onClick={handleClose}
          />

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
            {title && (
              <div className="cm__header">
                <h3 className="cm__title">{title}</h3>
                <button className="cm__close" onClick={handleClose} aria-label="Fermer">
                  <X />
                </button>
              </div>
            )}

            {/* overflow-x: visible ici est géré dans le SCSS — indispensable */}
            <div className="cm__body">
              {items.length > 0 ? (
                items.map(item =>
                  item.divider ? (
                    <div key={item.id} className="cm-divider" />
                  ) : (
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