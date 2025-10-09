import { useEffect } from 'react';

export const useNuiEvent = <T = any>(
  action: string,
  handler: (data: T) => void
) => {
  useEffect(() => {
    const eventListener = (event: MessageEvent) => {
      const { type, data } = event.data;

      if (type === action) {
        handler(data);
      }
    };

    window.addEventListener('message', eventListener);

    return () => window.removeEventListener('message', eventListener);
  }, [action, handler]);
};
