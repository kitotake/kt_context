export const GetParentResourceName = (): string => {
    return 'kt_context'; 
  };
  
  export const sendNUICallback = async (
    callback: string,
    data: any
  ): Promise<void> => {
    try {
      await fetch(`https://${GetParentResourceName()}/${callback}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
    } catch (error) {
      console.error(`[NUI] Erreur lors de l'envoi du callback ${callback}:`, error);
    }
  };
  
  export const isEnvBrowser = (): boolean => {
    return !(window as any).invokeNative;
  };