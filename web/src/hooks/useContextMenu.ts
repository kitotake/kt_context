import { useState, useCallback } from 'react'
import type { ContextMenuState, MenuItem } from '../types/menu.types'
import { useNuiEvent } from './useNuiEvent'

const INITIAL: ContextMenuState = {
  visible: false,
  position: { x: 0, y: 0 },
  items: [],
  title: undefined,
  theme: 'dark',
  animate: true,
}

export function useContextMenu() {
  const [state, setState] = useState<ContextMenuState>(INITIAL)

  const openMenu = useCallback(
    (x: number, y: number, items: MenuItem[], title?: string) => {
      setState({ visible: true, position: { x, y }, items, title, theme: 'dark', animate: true })
    },
    []
  )

  const closeMenu = useCallback(() => {
    setState(prev => ({ ...prev, visible: false }))
  }, [])

  useNuiEvent<{
    x: number; y: number; items: MenuItem[]
    title?: string; theme?: 'dark' | 'light'; animate?: boolean
  }>('openContextMenu', data => {
    setState({
      visible: true,
      position: { x: data.x, y: data.y },
      items: data.items,
      title: data.title,
      theme: data.theme ?? 'dark',
      animate: data.animate ?? true,
    })
    document.body.style.visibility = 'visible'
  })

  useNuiEvent('closeContextMenu', () => closeMenu())

  return { state, openMenu, closeMenu }
}