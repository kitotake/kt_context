import { useEffect } from 'react'

type NuiHandler<T> = (data: T) => void

export function useNuiEvent<T = unknown>(
  event: string,
  handler: NuiHandler<T>
): void {
  useEffect(() => {
    const listener = (e: MessageEvent) => {
      if (e.data?.type === event) {
        handler(e.data.data as T)
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [event, handler])
}
