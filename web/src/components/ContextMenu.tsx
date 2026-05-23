import { useEffect, useRef, useCallback, type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'
import type { ContextMenuProps } from '../types/menu.types'
import MenuItemRow from './MenuItemRow'
import { sendNui } from '../utils/nui'

const MENU_VARIANTS = {
  hidden:  { opacity: 0, scale: 0.95, y: -6 },
  visible: { opacity: 1, scale: 1,    y: 0,  transition: { duration: 0.18, ease: [0.16, 1, 0.3, 1] } },
  exit:    { opacity: 0, scale: 0.97, y: -3, transition: { duration: 0.12 } },
}

const MARGIN = 10

function clampPosition(x: number, y: number, w: number, h: number) {
  return {
    x: Math.max(MARGIN, Math.min(x, window.innerWidth  - w - MARGIN)),
    y: Math.max(MARGIN, Math.min(y, window.innerHeight - h - MARGIN)),
  }
}

const ContextMenu: FC<ContextMenuProps> = ({ visible, position, items, title, onClose }) => {
  const menuRef = useRef<HTMLDivElement>(null)

  const handleClose = useCallback(async () => {
    onClose()
    await sendNui('menuClosed', {})
  }, [onClose])

  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') handleClose() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [visible, handleClose])

  useEffect(() => {
    if (!visible || !menuRef.current) return
    const rect = menuRef.current.getBoundingClientRect()
    const { x, y } = clampPosition(position.x, position.y, rect.width, rect.height)
    menuRef.current.style.left = `${x}px`
    menuRef.current.style.top  = `${y}px`
  }, [visible, position])

  return (
    <AnimatePresence>
      {visible && (
        <>
          <div className="cm-overlay" onClick={handleClose} />

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

            <div className="cm__body">
              {items.length > 0 ? (
                items.map(item =>
                  item.divider
                    ? <div key={item.id} className="cm-divider" />
                    : <MenuItemRow key={item.id} item={item} onClose={handleClose} depth={0} />
                )
              ) : (
                <p className="cm__empty">Aucune option disponible</p>
              )}
            </div>

            <div className="cm__footer">
              <span>fermer</span>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

export default ContextMenu