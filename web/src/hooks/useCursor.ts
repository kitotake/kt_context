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
    setCursor(prev => ({
      ...prev,
      visible: data.visible,
    }))

    document.body.style.visibility = data.visible ? 'visible' : 'hidden'
  })

  useNuiEvent<{ x: number; y: number }>('cursorMove', data => {
    setCursor(prev => ({
      ...prev,
      x: typeof data.x === 'number' ? data.x : prev.x,
      y: typeof data.y === 'number' ? data.y : prev.y,
    }))
  })

  const hide = useCallback(() => {
    setCursor(prev => ({ ...prev, visible: false }))
    document.body.style.visibility = 'hidden'
  }, [])

  const reset = useCallback(() => {
    setCursor({ visible: false, x: 0.5, y: 0.5 })
  }, [])

  return { cursor, hide, reset }
}