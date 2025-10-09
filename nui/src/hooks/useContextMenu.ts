
import { useState, useEffect } from 'react';
import type { ContextMenuState, MenuItem } from '../types/menu.types';

export const useContextMenu = () => {
  const [menuState, setMenuState] = useState<ContextMenuState>({
    visible: false,
    position: { x: 0, y: 0 },
    items: [],
  });

  const openMenu = (
    x: number,
    y: number,
    items: MenuItem[],
    title?: string
  ) => {
    setMenuState({
      visible: true,
      position: { x, y },
      items,
      title,
    });
  };

  const closeMenu = () => {
    setMenuState((prev) => ({ ...prev, visible: false }));
  };

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { type, data } = event.data;

      switch (type) {
        case 'openContextMenu':
          openMenu(data.x, data.y, data.items, data.title);
          break;
        case 'closeContextMenu':
          closeMenu();
          break;
        default:
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  return { menuState, openMenu, closeMenu };
};
