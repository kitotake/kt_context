export const RESOURCE_NAME = 'kt_context'

export const isEnvBrowser = (): boolean =>
  !(window as unknown as { invokeNative?: unknown }).invokeNative

export const sendNui = async (event: string, data: unknown = {}): Promise<void> => {
  try {
    await fetch(`https://${RESOURCE_NAME}/${event}`, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify(data),
    })
  } catch {
    if (isEnvBrowser()) {
      console.debug(`[NUI mock] ${event}`, data)
    }
  }
}
