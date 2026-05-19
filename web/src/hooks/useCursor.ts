import { useState } from 'react'
import type { CursorState } from '../types/menu.types'
import { useNuiEvent } from './useNuiEvent'

// Le curseur système est géré par SetNuiFocus(true, true) côté Lua.
// On ne track plus la position — c'est le navigateur qui gère ça nativement.
export function useCursor() {
  const [cursor, setCursor] = useState<CursorState>({
    visible: false,
    x: 0.5,
    y: 0.5,
  })

  // Affiche / cache l'indicateur "mode curseur"
  useNuiEvent<{ visible: boolean }>('cursorShow', data => {
    setCursor(prev => ({ ...prev, visible: data.visible }))
  })

  // cursorMove n'est plus nécessaire — la position est native
  // Gardé pour compatibilité au cas où d'autres scripts l'envoient
  useNuiEvent<{ x: number; y: number }>('cursorMove', data => {
    setCursor(prev => ({
      ...prev,
      x: typeof data.x === 'number' ? data.x : prev.x,
      y: typeof data.y === 'number' ? data.y : prev.y,
    }))
  })

  return { cursor }
}

export default useCursor