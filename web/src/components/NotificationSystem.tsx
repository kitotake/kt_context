import { useState, useEffect, useCallback, type FC } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { CheckCircle, AlertTriangle, XCircle, Info, X } from 'lucide-react'
import { useNuiEvent } from '../hooks/useNuiEvent'

interface Notification {
  id:       string
  message:  string
  type:     'info' | 'success' | 'warning' | 'error'
  duration: number
}

const ICONS = {
  info:    <Info    size={14} />,
  success: <CheckCircle   size={14} />,
  warning: <AlertTriangle size={14} />,
  error:   <XCircle       size={14} />,
}

const COLORS: Record<string, { bg: string; border: string; icon: string; text: string }> = {
  info:    { bg: 'rgba(79,142,247,0.12)',  border: 'rgba(79,142,247,0.3)',  icon: '#4f8ef7', text: '#93c5fd' },
  success: { bg: 'rgba(52,211,153,0.12)',  border: 'rgba(52,211,153,0.3)',  icon: '#34d399', text: '#6ee7b7' },
  warning: { bg: 'rgba(251,191,36,0.12)',  border: 'rgba(251,191,36,0.3)',  icon: '#fbbf24', text: '#fcd34d' },
  error:   { bg: 'rgba(248,113,113,0.12)', border: 'rgba(248,113,113,0.3)', icon: '#f87171', text: '#fca5a5' },
}

let _notifId = 0

const NotificationSystem: FC = () => {
  const [notifs, setNotifs] = useState<Notification[]>([])

  const add = useCallback((data: Omit<Notification, 'id'>) => {
    const id = String(++_notifId)
    setNotifs(prev => [...prev.slice(-4), { ...data, id }])
    setTimeout(() => {
      setNotifs(prev => prev.filter(n => n.id !== id))
    }, data.duration ?? 3000)
  }, [])

  const remove = useCallback((id: string) => {
    setNotifs(prev => prev.filter(n => n.id !== id))
  }, [])

  useNuiEvent<{ message: string; type?: string; duration?: number }>('notification', data => {
    add({
      message:  data.message,
      type:     (data.type as Notification['type']) ?? 'info',
      duration: data.duration ?? 3000,
    })
  })

  return (
    <div style={{
      position:      'fixed',
      bottom:        72,
      right:         20,
      zIndex:        9500,
      display:       'flex',
      flexDirection: 'column',
      gap:           8,
      pointerEvents: 'none',
      maxWidth:      320,
    }}>
      <AnimatePresence initial={false}>
        {notifs.map(n => {
          const c = COLORS[n.type] ?? COLORS.info
          return (
            <motion.div
              key={n.id}
              initial={{ opacity: 0, x: 40, scale: 0.94 }}
              animate={{ opacity: 1, x: 0,  scale: 1,    transition: { duration: 0.2, ease: [0.16, 1, 0.3, 1] } }}
              exit={{    opacity: 0, x: 30, scale: 0.96,  transition: { duration: 0.15 } }}
              style={{
                background:    c.bg,
                border:        `1px solid ${c.border}`,
                borderRadius:  6,
                padding:       '8px 10px',
                display:       'flex',
                alignItems:    'flex-start',
                gap:           8,
                pointerEvents: 'all',
                cursor:        'default',
                fontFamily:    "'JetBrains Mono', monospace",
                backdropFilter: 'blur(4px)',
              }}
            >
              <span style={{ color: c.icon, flexShrink: 0, marginTop: 1 }}>
                {ICONS[n.type]}
              </span>
              <span style={{ color: c.text, fontSize: 12, lineHeight: 1.4, flex: 1 }}>
                {n.message}
              </span>
              <button
                onClick={() => remove(n.id)}
                style={{
                  background: 'none',
                  border:     'none',
                  cursor:     'pointer',
                  color:      c.icon,
                  padding:    0,
                  flexShrink: 0,
                  opacity:    0.6,
                  lineHeight: 0,
                }}
              >
                <X size={12} />
              </button>
            </motion.div>
          )
        })}
      </AnimatePresence>
    </div>
  )
}

export default NotificationSystem
