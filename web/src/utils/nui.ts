/** Nom de la ressource FiveM */
export const RESOURCE_NAME = 'kt_context'

/** Détecte si on est dans un vrai navigateur (mode dev) */
export const isEnvBrowser = (): boolean =>
  !(window as unknown as { invokeNative?: unknown }).invokeNative

/** Envoie un callback NUI vers le client Lua */
export const sendNui = async (
  event: string,
  data: unknown = {}
): Promise<void> => {
  try {
    await fetch(`https://${RESOURCE_NAME}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })
  } catch (err) {
    if (isEnvBrowser()) {
      console.debug(`[NUI mock] ${event}`, data)
    }
  }
}
