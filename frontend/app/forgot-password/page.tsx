'use client'
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Mail, Lock, ShieldCheck, CheckCircle2 } from 'lucide-react'
import PremiumAuthShell from '@/components/auth/PremiumAuthShell'
import GlassCard from '@/components/auth/GlassCard'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

export default function ForgotPasswordPage() {
  const [step, setStep] = useState<'email' | 'otp' | 'done'>('email')
  const [email, setEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [newPass, setNewPass] = useState('')
  const [confirmPass, setConfirmPass] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')

  const sendOtp = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/forgot-password`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email }) })
      const d = await r.json()
      if (r.ok) { setStep('otp'); setMsg(d.message || 'OTP sent!') } else setError(d.message || 'Failed')
    } catch { setError('Network error') }
    setLoading(false)
  }

  const passMatch = !confirmPass || newPass === confirmPass

  const resetPassword = async () => {
    if (newPass !== confirmPass) { setError('Passwords do not match'); return }
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/reset-password`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, otp, newPassword: newPass }) })
      const d = await r.json()
      if (r.ok) { setStep('done'); setMsg(d.message || 'Password reset!') } else setError(d.message || 'Failed')
    } catch { setError('Network error') }
    setLoading(false)
  }

  const steps = [{ label: 'Enter Email' }, { label: 'Verify & Reset' }, { label: 'Done' }]
  const currentIdx = step === 'email' ? 0 : step === 'otp' ? 1 : 2

  return (
    <PremiumAuthShell steps={steps} current={currentIdx}>
      <div className="mb-7 text-center">
        <h1 className="text-[26px] font-bold tracking-tight text-[#E8F4FF]">Reset password</h1>
        <p className="mt-1.5 text-sm text-[#6B8BAF]">We'll help you get back in</p>
      </div>

      <GlassCard>
        <AnimatePresence>
          {error && (
            <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mb-4 rounded-lg border border-[#FF4757]/30 bg-[#FF4757]/10 px-3.5 py-2.5 text-[13px] text-[#FF8A94]">
              {error}
            </motion.div>
          )}
          {msg && step !== 'done' && (
            <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mb-4 rounded-lg border border-[#00C48C]/30 bg-[#00C48C]/10 px-3.5 py-2.5 text-[13px] text-[#5EEAD4]">
              {msg}
            </motion.div>
          )}
        </AnimatePresence>

        {step === 'email' && (
          <div className="flex flex-col gap-4">
            <p className="text-center text-[13px] text-[#8FA8C4]">Enter your registered email — we'll send a reset OTP.</p>
            <Input label="Email" type="email" icon={<Mail className="h-4 w-4" />} value={email} onChange={e => setEmail(e.target.value)} onKeyDown={e => e.key === 'Enter' && sendOtp()} />
            <Button onClick={sendOtp} loading={loading} disabled={!email} className="w-full">Send Reset OTP</Button>
          </div>
        )}

        {step === 'otp' && (
          <div className="flex flex-col gap-4">
            <p className="text-center text-[13px] text-[#8FA8C4]">
              OTP sent to <span className="font-semibold text-[#4D9FFF]">{email}</span>
            </p>
            <Input label="OTP" value={otp} onChange={e => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} maxLength={6} inputMode="numeric" className="text-center text-xl tracking-[0.4em] font-bold" icon={<ShieldCheck className="h-4 w-4" />} />
            <Input label="New Password" isPassword icon={<Lock className="h-4 w-4" />} value={newPass} onChange={e => setNewPass(e.target.value)} />
            <div>
              <Input label="Confirm Password" isPassword icon={<Lock className="h-4 w-4" />} value={confirmPass} onChange={e => setConfirmPass(e.target.value)} error={!passMatch ? 'Passwords do not match' : undefined} success={!!confirmPass && passMatch && newPass.length >= 6} />
              {confirmPass && passMatch && newPass.length >= 6 && (
                <p className="mt-1.5 flex items-center gap-1 text-xs text-[#00C48C]"><CheckCircle2 className="h-3 w-3" /> Passwords match</p>
              )}
            </div>
            <Button onClick={resetPassword} loading={loading} disabled={otp.length !== 6 || newPass.length < 6 || !passMatch} className="w-full">Reset Password</Button>
            <Button variant="outline" onClick={() => { setStep('email'); setError(''); setMsg('') }} className="w-full">Back</Button>
          </div>
        )}

        {step === 'done' && (
          <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="py-4 text-center">
            <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ type: 'spring', stiffness: 200, damping: 12 }} className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[#00C48C]/15">
              <CheckCircle2 className="h-8 w-8 text-[#00C48C]" />
            </motion.div>
            <h2 className="text-lg font-bold text-[#E8F4FF]">Password Reset!</h2>
            <p className="mt-1.5 text-[13px] text-[#6B8BAF]">You can now login with your new password.</p>
          </motion.div>
        )}

        <p className="mt-6 text-center text-[13px] text-[#6B8BAF]">
          <a href="/login" className="font-semibold text-[#4D9FFF] hover:text-[#00D4FF]">← Back to Login</a>
        </p>
      </GlassCard>
    </PremiumAuthShell>
  )
}
