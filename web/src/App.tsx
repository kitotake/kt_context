import React, { useEffect } from 'react';
import { ContextMenu } from './components/ContextMenu';
import type { MenuItem } from './types/menu.types';
import { useContextMenu } from './hooks/useContextMenu';
import { isEnvBrowser } from './utils/nui.utils';


export default function App() {
  const { menuState, openMenu, closeMenu } = useContextMenu();

  const exampleItems: MenuItem[] = [
    {
      id: 'inventory',
      label: 'Inventaire',
      icon: <span>🎒</span>,
      description: 'Voir mes objets',
      action: () => console.log('Ouvrir inventaire'),
    },
    {
      id: 'actions',
      label: 'Actions',
      icon: <span>⚡</span>,
      submenu: [
        {
          id: 'wave',
          label: 'Saluer',
          icon: <span>👋</span>,
          action: () => console.log('Saluer'),
        },
        {
          id: 'dance',
          label: 'Danser',
          icon: <span>💃</span>,
          action: () => console.log('Danser'),
        },
      ],
    },
    {
      id: 'vehicle',
      label: 'Véhicule',
      icon: <span>🚗</span>,
      submenu: [
        {
          id: 'lock',
          label: 'Verrouiller',
          action: () => console.log('Verrouiller'),
        },
        {
          id: 'engine',
          label: 'Moteur On/Off',
          action: () => console.log('Toggle moteur'),
        },
      ],
    },
    {
      id: 'disabled',
      label: 'Option désactivée',
      icon: <span>🚫</span>,
      disabled: true,
    },
  ];

  // Mode développement navigateur uniquement
  const handleContextMenu = (e: React.MouseEvent) => {
    if (isEnvBrowser()) {
      e.preventDefault();
      openMenu(e.clientX, e.clientY, exampleItems, 'Menu Principal');
    }
  };

  // Cacher le curseur NUI si pas visible
  useEffect(() => {
    if (!isEnvBrowser()) {
      document.body.style.visibility = menuState.visible ? 'visible' : 'hidden';
    }
  }, [menuState.visible]);

  return (
    <div className="app">
      {/* Mode dev uniquement */}
      {isEnvBrowser() && (
        <div onContextMenu={handleContextMenu} className="app__demo-area">
          <div className="app__content">
            <h1 className="app__title">KT Context Menu</h1>
            <p className="app__subtitle">
              Clic droit pour ouvrir le menu (Mode développement)
            </p>
          </div>
        </div>
      )}

      {/* Le menu contextuel */}
      <ContextMenu
        visible={menuState.visible}
        position={menuState.position}
        items={menuState.items}
        onClose={closeMenu}
        title={menuState.title}
      />
    </div>
  );
}

// ========================================
// EXEMPLE D'UTILISATION DANS App.tsx
// ========================================

/*
import { ToastContainer } from './components/ToastContainer';
import { useNuiEvent } from './hooks/useNuiEvent';

function App() {
  useNuiEvent('showNotification', (data: { message: string; type: string }) => {
    (window as any).showToast(data.message, data.type);
  });

  return (
    <>
      <YourMainComponent />
      <ToastContainer />
    </>
  );
}
*/