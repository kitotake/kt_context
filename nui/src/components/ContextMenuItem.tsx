import React, { useState, useRef } from 'react';
import { ChevronRight } from 'lucide-react';
import type { MenuItem } from '../types/menu.types';
import { sendNUICallback } from '../utils/nui.utils';

interface ContextMenuItemProps {
  item: MenuItem;
  onClose: () => void;
  depth?: number;
}

export const ContextMenuItem: React.FC<ContextMenuItemProps> = ({
  item,
  onClose,
  depth = 0,
}) => {
  const [showSubmenu, setShowSubmenu] = useState(false);
  const itemRef = useRef<HTMLDivElement>(null);

  const handleClick = async () => {
    if (item.disabled) return;

    if (item.submenu) {
      setShowSubmenu(!showSubmenu);
    } else {
      if (item.action) {
        item.action();
      }

      await sendNUICallback('menuAction', { id: item.id });

      onClose();
    }
  };

  return (
    <div className="context-menu-item-wrapper">
      <div
        ref={itemRef}
        onClick={handleClick}
        className={`context-menu-item ${item.disabled ? 'disabled' : ''}`}
        style={item.color ? { borderLeftColor: item.color } : undefined}
      >
        <div className="context-menu-item__content">
          {item.icon && (
            <div className="context-menu-item__icon">{item.icon}</div>
          )}
          <div className="context-menu-item__text">
            <span className="context-menu-item__label">{item.label}</span>
            {item.description && (
              <span className="context-menu-item__description">
                {item.description}
              </span>
            )}
          </div>
        </div>

        {item.submenu && (
          <ChevronRight className="context-menu-item__arrow" />
        )}
      </div>

      {/* Sous-menu */}
      {item.submenu && showSubmenu && (
        <div className="context-menu-submenu">
          {item.submenu.map((subItem) => (
            <ContextMenuItem
              key={subItem.id}
              item={subItem}
              onClose={onClose}
              depth={depth + 1}
            />
          ))}
        </div>
      )}
    </div>
  );
};
