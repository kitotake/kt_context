import React, { useState, useRef } from 'react';

interface TooltipProps {
  content: string;
  position?: 'top' | 'bottom' | 'left' | 'right';
  children: React.ReactNode;
}

export const Tooltip: React.FC<TooltipProps> = ({
  content,
  position = 'top',
  children,
}) => {
  const [isVisible, setIsVisible] = useState(false);
  const tooltipRef = useRef<HTMLDivElement>(null);

  return (
    <div
      className="relative inline-block"
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
    >
      {children}
      {isVisible && (
        <div
          ref={tooltipRef}
          className={`tooltip tooltip--${position}`}
          style={{
            [position === 'top' || position === 'bottom' ? 'left' : 'top']: '50%',
            [position === 'top' ? 'bottom' : position === 'bottom' ? 'top' : position]: '100%',
            transform:
              position === 'top' || position === 'bottom'
                ? 'translateX(-50%)'
                : 'translateY(-50%)',
            marginTop: position === 'bottom' ? '8px' : position === 'top' ? '-8px' : '0',
            marginLeft: position === 'right' ? '8px' : position === 'left' ? '-8px' : '0',
          }}
        >
          {content}
        </div>
      )}
    </div>
  );
};