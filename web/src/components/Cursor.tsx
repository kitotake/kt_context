import { type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import type { CursorState } from '../types/menu.types'

interface Props {
  cursor: CursorState
}

const CURSOR_VARIANTS = {
  hidden:  { opacity: 0, scale: 0.4 },
  visible: { opacity: 1, scale: 1, transition: { duration: 0.18, ease: [0.34, 1.56, 0.64, 1] } },
  exit:    { opacity: 0, scale: 0.5, transition: { duration: 0.12 } },
}

const Cursor: FC<Props> = ({ cursor }) => {
  const x = `${cursor.x * 100}vw`
  const y = `${cursor.y * 100}vh`

  return (
    <AnimatePresence>
      {cursor.visible && (
        <motion.div
          className="kt-cursor"
          style={{ left: x, top: y }}
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
