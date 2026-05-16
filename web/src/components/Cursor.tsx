import { type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import type { CursorState } from '../types/menu.types'

interface Props {
  cursor: CursorState
}

const CURSOR_VARIANTS = {
  hidden: { opacity: 0, scale: 0.4 },
  visible: {
    opacity: 1,
    scale: 1,
    transition: { duration: 0.18, ease: [0.34, 1.56, 0.64, 1] },
  },
  exit: { opacity: 0, scale: 0.5, transition: { duration: 0.12 } },
}

const Cursor: FC<Props> = ({ cursor }) => {
  // Conversion normalisé (0..1) → pixels réels
  // On utilise window.innerWidth/Height et non vw/vh pour éviter
  // le glissement causé par la taille du curseur lui-même
  const x = Math.round(cursor.x * window.innerWidth)
  const y = Math.round(cursor.y * window.innerHeight)

  return (
    <AnimatePresence>
      {cursor.visible && (
        <motion.div
          className="kt-cursor"
          style={{
            position: 'fixed',
            left: x,
            top: y,
            // translate fixe depuis le centre du curseur, indépendant de la position
            transform: 'translate(-50%, -50%)',
            pointerEvents: 'none',
            zIndex: 9999,
          }}
          variants={CURSOR_VARIANTS}
          initial="hidden"
          animate="visible"
          exit="exit"
        >
          <div className="kt-cursor__ring" />
          <span className="kt-cursor__hint">Clic gauche pour interagir</span>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

export default Cursor