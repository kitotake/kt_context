import { useState, type FC } from 'react'
import { motion } from 'framer-motion'
import { Check } from 'lucide-react'
import { sendNui } from '../utils/nui'

interface CheckboxItemProps {
  id: string
  label: string
  checked?: boolean
  disabled?: boolean
  description?: string
  icon?: string
  onChange?: (checked: boolean) => void
}

const CheckboxItem: FC<CheckboxItemProps> = ({
  id,
  label,
  checked: initialChecked = false,
  disabled = false,
  description,
  onChange,
}) => {
  const [checked, setChecked] = useState(initialChecked)

  const handleToggle = async () => {
    if (disabled) return
    const next = !checked
    setChecked(next)
    onChange?.(next)
    await sendNui('menuAction', { id, checked: next, type: 'checkbox' })
  }

  return (
    <div
      role="checkbox"
      aria-checked={checked}
      aria-disabled={disabled}
      tabIndex={disabled ? -1 : 0}
      className={`cm-item cm-checkbox ${disabled ? 'cm-item--disabled' : ''} ${checked ? 'cm-checkbox--checked' : ''}`}
      onClick={handleToggle}
      onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') handleToggle() }}
    >
      <div className="cm-item__left">
        {/* Box */}
        <span className="cm-checkbox__box">
          <motion.span
            className="cm-checkbox__tick"
            initial={false}
            animate={checked ? { scale: 1, opacity: 1 } : { scale: 0.4, opacity: 0 }}
            transition={{ duration: 0.14, ease: [0.34, 1.56, 0.64, 1] }}
          >
            <Check size={10} strokeWidth={3} />
          </motion.span>
        </span>

        <div className="cm-item__text">
          <span className="cm-item__label">{label}</span>
          {description && <span className="cm-item__desc">{description}</span>}
        </div>
      </div>
    </div>
  )
}

export default CheckboxItem
