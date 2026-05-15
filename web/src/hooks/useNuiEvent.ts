import { useEffect, useRef } from 'react'

type NuiHandler<T> = (data: T) => void

/**
 * Écoute les messages NUI envoyés depuis Lua via SendNUIMessage.
 * Utilise une ref pour stabiliser le handler et éviter les re-abonnements.
 */
export function useNuiEvent<T = unknown>(
  event: string,
  handler: NuiHandler<T>
): void {
  // Stocker le handler dans une ref pour éviter de recréer le listener
  // à chaque render, même si handler change (closure capturant le state courant)
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
    // On ne dépend que de `event` — le handler est stable via la ref
  }, [event])
}