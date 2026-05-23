import { type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import type { CursorState } from '../types/menu.types'

interface Props { cursor: CursorState }

const Cursor: FC<Props> = ({ cursor }) => (
  <AnimatePresence>
    {cursor.visible && (
      <motion.div
        style={{
          position: 'fixed', bottom: 32, left: '50%',
          transform: 'translateX(-50%)',
          pointerEvents: 'none', zIndex: 8999,
          display: 'flex', alignItems: 'center', gap: 7,
          background: 'rgba(9, 11, 17, 0.92)',
          border: '1px solid rgba(255,255,255,0.07)',
          borderRadius: 5, padding: '5px 10px',
          fontFamily: "'JetBrains Mono', monospace",
        }}
        initial={{ opacity: 0, y: 6 }}
        animate={{ opacity: 1, y: 0, transition: { duration: 0.2 } }}
        exit={{ opacity: 0, y: 4, transition: { duration: 0.12 } }}
      >
        <motion.div
          style={{ width: 5, height: 5, borderRadius: '50%', background: '#4f8ef7' }}
          animate={{ opacity: [1, 0.3, 1] }}
          transition={{ repeat: Infinity, duration: 1.6, ease: 'easeInOut' }}
        />
        <span style={{
          fontSize: 10, color: '#475569',
          letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 500,
        }}>
          Mode curseur — clic pour interagir
        </span>
      </motion.div>
    )}
  </AnimatePresence>
)

export default Cursor