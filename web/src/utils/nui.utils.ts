// web/src/utils/nui.utils.ts
// FIX : import statique au lieu du dynamic import async inutile
// ContextMenuItem.tsx l'importe encore → on garde la compatibilité

export { sendNui, isEnvBrowser, RESOURCE_NAME } from './nui'

/**
 * @deprecated Utilisez sendNui() directement depuis './nui'
 */
export const sendNUICallback = (event: string, data: unknown = {}): Promise<void> => {
  return import('./nui').then(({ sendNui: _send }) => _send(event, data))
}