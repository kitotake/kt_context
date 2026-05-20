// web/src/utils/nui.utils.ts
// FIX : ContextMenuItem.tsx importait 'nui.utils' qui n'existait pas.
// Ce fichier réexporte les fonctions de nui.ts pour compatibilité.

export { sendNui, isEnvBrowser, RESOURCE_NAME } from './nui'

/**
 * @deprecated Utilisez sendNui() directement depuis './nui'
 */
export const sendNUICallback = async (event: string, data: unknown = {}): Promise<void> => {
  const { sendNui: _send } = await import('./nui')
  return _send(event, data)
}