import React, { useEffect, useRef } from 'react';
import { X } from 'lucide-react';
import { ContextMenuProps } from '../types/menu.types';
import { ContextMenuItem } from './ContextMenuItem';
import { sendNUICallback } from '../utils/nui.utils';
import './ContextMenu.scss';

export const ContextMenu: React.FC<ContextMenuProps> = ({
  visible,
  position,
  items,
  onClose,
  title,
}) => {
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        handleClose();
      }
    };

    if (visible) {
      window.addEventListener('keydown', handleKeyDown);
      return () => window.removeEventListener('keydown', handleKeyDown);
    }
  }, [visible]);

  useEffect(() => {
    if (visible && menuRef.current) {
      const rect = menuRef.current.getBoundingClientRect();
      const x = Math.min(position.x, window.innerWidth - rect.width - 10);
      const y = Math.min(position.y, window.innerHeight - rect.height - 10);

      menuRef.current.style.left = `${Math.max(10, x)}px`;
      menuRef.current.style.top = `${Math.max(10, y)}px`;
    }
  }, [visible, position]);

  const handleClose = () => {
    onClose();
    sendNUICallback('menuClosed', {});
  };

  if (!visible) return null;

  return (
    <>
      <div className="context-menu-overlay" onClick={handleClose} />

      <div
        ref={menuRef}
        className="context-menu"
        style={{ left: position.x, top: position.y }}
      >
        {title && (
          <div className="context-menu__header">
            <h3 className="context-menu__title">{title}</h3>
            <button onClick={handleClose} className="context-menu__close">
              <X className="context-menu__close-icon" />
            </button>
          </div>
        )}

        <div className="context-menu__items">
          {items.length > 0 ? (
            items.map((item) => (
              <ContextMenuItem
                key={item.id}
                item={item}
                onClose={handleClose}
              />
            ))
          ) : (
            <div className="context-menu__empty">Aucune option disponible</div>
          )}
        </div>

        <div className="context-menu__footer">
          <span className="context-menu__footer-text">
            Échap pour fermer
          </span>
        </div>
      </div>
    </>
  );
};
