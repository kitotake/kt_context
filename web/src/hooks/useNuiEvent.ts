import { useEffect, useRef } from 'react'

type NuiHandler<T> = (data: T) => void

export function useNuiEvent<T = unknown>(event: string, handler: NuiHandler<T>): void {
  const handlerRef = useRef<NuiHandler<T>>(handler)
  handlerRef.current = handler

  useEffect(() => {
    const listener = (e: MessageEvent) => {
      if (e.data?.type === event) {
        handlerRef.current(e.data.data as T)
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [event])
}