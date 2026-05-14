import { useState, useCallback } from 'react'
import type { CursorState } from '../types/menu.types'
import { useNuiEvent } from './useNuiEvent'

export function useCursor() {
  const [cursor, setCursor] = useState<CursorState>({
    visible: false,
    x: 0.5,
    y: 0.5,
  })

  useNuiEvent<{ visible: boolean }>('cursorShow', data => {
    setCursor(prev => ({ ...prev, visible: data.visible }))
    document.body.style.visibility = 'visible'
  })

  useNuiEvent<{ x: number; y: number }>('cursorMove', data => {
    setCursor(prev => ({ ...prev, x: data.x, y: data.y }))
  })

  const hide = useCallback(() => {
    setCursor(prev => ({ ...prev, visible: false }))
  }, [])

  return { cursor, hide }
}
