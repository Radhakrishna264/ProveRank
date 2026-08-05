'use client'
import { motion } from 'framer-motion'

export function getStrength(pw: string) {
  let score = 0
  if (pw.length >= 6) score++
  if (pw.length >= 10) score++
  if (/[A-Z]/.test(pw)) score++
  if (/[0-9]/.test(pw)) score++
  if (/[^A-Za-z0-9]/.test(pw)) score++
  return Math.min(score, 4)
}

const LABELS = ['Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong']
const COLORS = ['#FF4757', '#FF8C42', '#FFA502', '#4D9FFF', '#00C48C']

export default function PasswordStrength({ password }: { password: string }) {
  if (!password) return null
  const strength = getStrength(password)
  return (
    <div className="mt-2">
      <div className="flex gap-1">
        {[0, 1, 2, 3].map(i => (
          <motion.div
            key={i}
            initial={{ scaleX: 0 }}
            animate={{ scaleX: i < strength ? 1 : 0.15 }}
            transition={{ duration: 0.25 }}
            className="h-1 flex-1 origin-left rounded-full"
            style={{ background: i < strength ? COLORS[strength] : 'rgba(255,255,255,0.1)' }}
          />
        ))}
      </div>
      <p className="mt-1 text-[11px] font-medium" style={{ color: COLORS[strength] }}>{LABELS[strength]}</p>
    </div>
  )
}
