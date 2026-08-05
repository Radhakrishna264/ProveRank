'use client'
import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { User, Mail, Lock, Phone, ShieldCheck, PartyPopper, Lock as LockIcon, Mail as MailIcon } from 'lucide-react'
import PremiumAuthShell from '@/components/auth/PremiumAuthShell'
import GlassCard from '@/components/auth/GlassCard'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import PasswordStrength from '@/components/auth/PasswordStrength'
import TermsModal from '@/components/auth/TermsModal'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const PHONE_RE = /^\+91[\s]?[6-9]\d{9}$/

export default function RegisterPage() {
  const router = useRouter()
  const [step, setStep] = useState<'details' | 'otp' | 'done'>('details')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [phone, setPhone] = useState('')
  const [otp, setOtp] = useState('')
  const [agreedTnc, setAgreedTnc] = useState(false)
  const [showTermsModal, setShowTermsModal] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')
  const [resending, setResend] = useState(false)
  const [resendCooldown, setResendCooldown] = useState(0)
  const [regClosed, setRegClosed] = useState(false)

  useEffect(() => {
    fetch(`${API}/api/auth/registration-status`).then(r => r.json()).then(d => { if (!d.open) setRegClosed(true) }).catch(() => {})
  }, [])

  const [emailCheck, setEmailCheck] = useState<{ checking: boolean; available: boolean | null; msg: string }>({ checking: false, available: null, msg: '' })
  const emailDebounce = useRef<any>(null)

  useEffect(() => {
    if (!email || !EMAIL_RE.test(email)) { setEmailCheck({ checking: false, available: null, msg: '' }); return }
    setEmailCheck(p => ({ ...p, checking: true }))
    clearTimeout(emailDebounce.current)
    emailDebounce.current = setTimeout(async () => {
      try {
        const r = await fetch(`${API}/api/auth/check-email`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email }) })
        const d = await r.json()
        setEmailCheck({ checking: false, available: d.available, msg: d.message || '' })
      } catch { setEmailCheck({ checking: false, available: null, msg: '' }) }
    }, 500)
    return () => clearTimeout(emailDebounce.current)
  }, [email])

  useEffect(() => { if (step === 'otp') setResendCooldown(60) }, [step])
  useEffect(() => {
    if (resendCooldown <= 0) return
    const t = setTimeout(() => setResendCooldown(c => c - 1), 1000)
    return () => clearTimeout(t)
  }, [resendCooldown])

  const emailValid = !email || EMAIL_RE.test(email)
  const phoneValid = !phone || PHONE_RE.test(phone)
  const canSubmit = !!name && !!email && emailValid && password.length >= 6 && phoneValid && agreedTnc && emailCheck.available !== false

  const register = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/register`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, email, password, phone }) })
      const d = await r.json()
      if (r.ok) { setStep('otp'); setMsg(d.message || 'OTP sent!') } else setError(d.message || 'Registration failed')
    } catch { setError('Network error. Please try again.') }
    setLoading(false)
  }

  const verifyOtp = async () => {
    if (otp.length !== 6) { setError('Enter 6-digit OTP'); return }
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/verify-otp`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, otp }) })
      const d = await r.json()
      if (r.ok) {
        try { localStorage.setItem('pr_token', d.token); localStorage.setItem('pr_role', d.role || 'student'); localStorage.setItem('pr_new_student', 'true') } catch {}
        setStep('done')
        setTimeout(() => router.replace('/dashboard'), 2200)
      } else setError(d.message || 'Invalid OTP')
    } catch { setError('Network error. Please try again.') }
    setLoading(false)
  }

  const resendOtp = async () => {
    if (resendCooldown > 0) return
    setResend(true); setError(''); setMsg('')
    try {
      const r = await fetch(`${API}/api/auth/resend-otp`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email }) })
      const d = await r.json()
      if (r.ok) { setMsg('New OTP sent! Check your inbox.'); setResendCooldown(60) } else setError(d.message || 'Failed to resend')
    } catch { setError('Network error') }
    setResend(false)
  }

  const steps = [{ label: 'Email & Details' }, { label: 'Verify OTP' }, { label: 'Done' }]
  const currentStepIdx = step === 'details' ? 0 : step === 'otp' ? 1 : 2

  return (
    <PremiumAuthShell steps={steps} current={currentStepIdx}>
      {regClosed && step === 'details' && (
        <GlassCard className="border-[#FF4757]/25 text-center">
          <div className="mb-3 text-5xl">🔒</div>
          <h2 className="mb-2 text-lg font-bold text-[#FF8080]">Registration Temporarily Closed</h2>
          <div className="mb-4 rounded-lg border border-[#FF4757]/25 bg-[#FF4757]/10 px-4 py-3">
            <p className="text-[13px] font-medium text-[#FFAAAA]">📢 Registration is currently closed. We'll be back soon. Please contact Admin for access.</p>
          </div>
          <p className="mb-5 text-[13px] text-[#8FA8C4]">New student registrations are temporarily paused.<br />Existing students can still login normally.</p>
          <div className="flex flex-wrap justify-center gap-2.5">
            <a href="/login"><Button>Login</Button></a>
            <a href="mailto:admin@proverank.com"><Button variant="outline">📧 Contact Admin</Button></a>
          </div>
        </GlassCard>
      )}

      {!regClosed && step === 'details' && (
        <GlassCard>
          <div className="mb-6 text-center">
            <h2 className="text-[22px] font-bold text-[#E8F4FF]">Create Account</h2>
            <p className="mt-1 text-[13px] text-[#6B8BAF]">Join ProveRank — Rise to the Top</p>
          </div>

          <AnimatePresence>
            {error && (
              <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mb-4 rounded-lg border border-[#FF4757]/30 bg-[#FF4757]/10 px-3.5 py-2.5 text-[13px] text-[#FF8A94]">
                {error}
              </motion.div>
            )}
          </AnimatePresence>

          <div className="flex flex-col gap-4">
            <Input label="Full Name" icon={<User className="h-4 w-4" />} value={name} onChange={e => setName(e.target.value)} />
            <div>
              <Input label="Email" type="email" icon={<Mail className="h-4 w-4" />} value={email} onChange={e => setEmail(e.target.value)} error={email && !emailValid ? 'Invalid email format' : undefined} success={emailCheck.available === true} />
              {email && emailValid && (
                <p className={`mt-1.5 text-[11px] ${emailCheck.checking ? 'text-[#6B8BAF]' : emailCheck.available === false ? 'text-[#FF6B7A]' : 'text-[#00C48C]'}`}>
                  {emailCheck.checking ? 'Checking availability...' : emailCheck.available === false ? '❌ ' + (emailCheck.msg || 'Already registered') : emailCheck.available === true ? '✅ Email available' : ''}
                </p>
              )}
            </div>
            <div>
              <Input label="Password" isPassword icon={<Lock className="h-4 w-4" />} value={password} onChange={e => setPassword(e.target.value)} />
              <PasswordStrength password={password} />
            </div>
            <Input label="Phone (optional)" icon={<Phone className="h-4 w-4" />} value={phone} onChange={e => setPhone(e.target.value)} error={phone && !phoneValid ? 'Format: +91 followed by 10 digits' : undefined} />
          </div>

          <div className={`mt-5 rounded-xl border px-4 py-3 transition-colors ${agreedTnc ? 'border-[#4D9FFF]/40' : 'border-white/10'} bg-white/[0.02]`}>
            {!agreedTnc ? (
              <div className="flex items-center gap-3">
                <span className="text-lg">📋</span>
                <div className="flex-1">
                  <div className="mb-1 text-xs text-[#E8F4FF]">You must read Terms &amp; Conditions before proceeding</div>
                  <button onClick={() => setShowTermsModal(true)} className="text-xs font-bold text-[#4D9FFF] underline hover:text-[#00D4FF]">📖 Read Terms &amp; Conditions →</button>
                </div>
              </div>
            ) : (
              <label className="flex cursor-pointer items-center gap-3">
                <div className="flex h-5 w-5 flex-shrink-0 items-center justify-center rounded bg-[#4D9FFF]">
                  <span className="text-[10px] font-black text-[#00101F]">✓</span>
                </div>
                <span className="text-xs font-semibold text-[#E8F4FF]">✅ Terms &amp; Conditions read and accepted</span>
                <button onClick={() => setAgreedTnc(false)} className="ml-auto text-[11px] text-[#FF6B7A] hover:text-[#FF8A94]">Undo</button>
              </label>
            )}
          </div>

          <Button onClick={register} loading={loading} disabled={!canSubmit} className="mt-5 w-full">Create Account</Button>
          <p className="mt-4 text-center text-[13px] text-[#6B8BAF]">
            Already have an account?{' '}<a href="/login" className="font-semibold text-[#4D9FFF] hover:text-[#00D4FF]">Login</a>
          </p>
        </GlassCard>
      )}

      {step === 'otp' && (
        <GlassCard>
          <div className="mb-5 text-center">
            <MailIcon className="mx-auto mb-3 h-10 w-10 text-[#4D9FFF]" />
            <h2 className="text-lg font-bold text-[#E8F4FF]">Verify Your Email</h2>
            <p className="mt-1 text-[13px] text-[#6B8BAF]">OTP sent to <span className="font-semibold text-[#4D9FFF]">{email}</span></p>
          </div>
          <AnimatePresence>
            {error && <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mb-4 rounded-lg border border-[#FF4757]/30 bg-[#FF4757]/10 px-3.5 py-2.5 text-[13px] text-[#FF8A94]">{error}</motion.div>}
            {msg && <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mb-4 rounded-lg border border-[#00C48C]/30 bg-[#00C48C]/10 px-3.5 py-2.5 text-[13px] text-[#5EEAD4]">{msg}</motion.div>}
          </AnimatePresence>
          <Input label="Enter 6-Digit OTP" value={otp} onChange={e => { setOtp(e.target.value.replace(/\D/g, '').slice(0, 6)); setError('') }} maxLength={6} inputMode="numeric" className="text-center text-2xl tracking-[0.5em] font-bold" icon={<ShieldCheck className="h-4 w-4" />} />
          <Button onClick={verifyOtp} loading={loading} disabled={otp.length !== 6} className="mt-4 w-full">Verify & Continue</Button>
          <div className="mt-3.5 text-center text-xs text-[#6B8BAF]">
            Didn't receive OTP?{' '}
            {resendCooldown > 0 ? <span>Resend in 0:{resendCooldown < 10 ? '0' + resendCooldown : resendCooldown}</span> : <button onClick={resendOtp} disabled={resending} className="font-semibold text-[#4D9FFF] hover:text-[#00D4FF]">{resending ? 'Sending...' : 'Resend OTP'}</button>}
          </div>
          <p className="mt-2 text-center text-[11px] text-[#6B8BAF]">OTP valid for 10 minutes · Check spam/junk folder</p>
          <Button variant="outline" onClick={() => { setStep('details'); setOtp(''); setError(''); setMsg('') }} className="mt-3.5 w-full">Change Email / Register Again</Button>
        </GlassCard>
      )}

      {step === 'done' && (
        <GlassCard className="relative overflow-hidden text-center">
          {Array.from({ length: 24 }).map((_, i) => (
            <motion.div
              key={i}
              initial={{ y: -10, opacity: 1, rotate: 0 }}
              animate={{ y: 420, opacity: 0, rotate: 360 }}
              transition={{ duration: 1.4 + (i % 5) * 0.2, delay: i * 0.03, ease: 'easeIn' }}
              className="absolute top-0 h-1.5 w-1.5"
              style={{ left: `${(i * 37) % 100}%`, background: ['#4D9FFF', '#00D4FF', '#FFD700', '#fff'][i % 4], borderRadius: i % 2 === 0 ? '50%' : 2 }}
            />
          ))}
          <PartyPopper className="mx-auto mb-3 h-12 w-12 text-[#4D9FFF]" />
          <h2 className="text-lg font-bold text-[#E8F4FF]">Welcome to ProveRank!</h2>
          <p className="mt-1.5 text-[13px] text-[#6B8BAF]">Redirecting to your dashboard...</p>
        </GlassCard>
      )}

      <TermsModal open={showTermsModal} onClose={() => setShowTermsModal(false)} onAccept={() => { setAgreedTnc(true); setShowTermsModal(false) }} />
    </PremiumAuthShell>
  )
}
