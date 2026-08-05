'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { Mail, Lock, ShieldCheck } from 'lucide-react'
import PremiumAuthShell from '@/components/auth/PremiumAuthShell'
import GlassCard from '@/components/auth/GlassCard'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

export default function LoginPage() {
  const router = useRouter()
  type Tab = 'password' | 'otp'
  const [tab, setTab] = useState<Tab>('password')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [rememberMe, setRememberMe] = useState(true)
  const [otpEmail, setOtpEmail] = useState('')
  const [loginOtp, setLoginOtp] = useState('')
  const [otpSent, setOtpSent] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')

  useEffect(() => {
    try {
      const tk = localStorage.getItem('pr_token')
      const role = localStorage.getItem('pr_role') || 'student'
      if (tk) window.location.href = (role === 'superadmin' || role === 'admin') ? '/admin/x7k2p' : '/dashboard'
    } catch {}
  }, [router])

  const clearAll = () => { setError(''); setMsg('') }

  const goAfterLogin = (token: string, role: string, data: any) => {
    try {
      localStorage.setItem('pr_token', token)
      localStorage.setItem('pr_role', role)
      localStorage.setItem('pr_email', data?.user?.email || data?.email || email || otpEmail || '')
      sessionStorage.removeItem('pr_admin_tab')
      sessionStorage.setItem('pr_just_logged_in', '1')
    } catch {}
    window.location.href = (role === 'superadmin' || role === 'admin') ? '/admin/x7k2p' : '/dashboard'
  }

  const loginPassword = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) })
      const d = await r.json()
      if (r.ok) goAfterLogin(d.token, d.role, d)
      else if (d.code === 'SESSION_REPLACED') setError('You were logged in from another device. Please login again.')
      else setError(d.message || 'Login failed. Please try again.')
    } catch { setError('Network error. Please try again.') }
    setLoading(false)
  }

  const sendLoginOtp = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/send-login-otp`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: otpEmail }) })
      const d = await r.json()
      if (r.ok) { setOtpSent(true); setMsg(d.message || 'OTP sent!') } else setError(d.message || 'Failed to send OTP')
    } catch { setError('Network error') }
    setLoading(false)
  }

  const loginWithOtp = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/login-otp`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: otpEmail, otp: loginOtp }) })
      const d = await r.json()
      if (r.ok) goAfterLogin(d.token, d.role, d)
      else setError(d.message || 'Invalid OTP')
    } catch { setError('Network error') }
    setLoading(false)
  }

  const emailValid = !email || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)

  return (
    <PremiumAuthShell>
      <div className="mb-7 text-center">
        <h1 className="text-[26px] font-bold tracking-tight text-[#E8F4FF]">Welcome back</h1>
        <p className="mt-1.5 text-sm text-[#6B8BAF]">Login to continue your exam journey</p>
      </div>

      <GlassCard>
        <div className="mb-6 flex gap-1 rounded-xl border border-white/10 bg-white/[0.02] p-1">
          {([['password', 'Password'], ['otp', 'OTP']] as const).map(([t, l]) => (
            <button
              key={t}
              onClick={() => { setTab(t); clearAll() }}
              className={`flex-1 rounded-lg py-2.5 text-[13px] font-semibold transition-all duration-200 ${
                tab === t ? 'bg-gradient-to-r from-[#4D9FFF] to-[#00D4FF] text-[#00101F] shadow-[0_2px_12px_rgba(77,159,255,0.4)]' : 'text-[#6B8BAF] hover:text-[#9CC5FF]'
              }`}
            >{l}</button>
          ))}
        </div>

        <AnimatePresence>
          {error && (
            <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mb-4 rounded-lg border border-[#FF4757]/30 bg-[#FF4757]/10 px-3.5 py-2.5 text-[13px] text-[#FF8A94]">
              {error}
            </motion.div>
          )}
          {msg && (
            <motion.div initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="mb-4 rounded-lg border border-[#00C48C]/30 bg-[#00C48C]/10 px-3.5 py-2.5 text-[13px] text-[#5EEAD4]">
              {msg}
            </motion.div>
          )}
        </AnimatePresence>

        {tab === 'password' && (
          <div className="flex flex-col gap-4">
            <Input label="Email" type="email" icon={<Mail className="h-4 w-4" />} value={email} onChange={e => setEmail(e.target.value)} onKeyDown={e => e.key === 'Enter' && loginPassword()} error={!emailValid ? 'Invalid email format' : undefined} />
            <Input label="Password" isPassword icon={<Lock className="h-4 w-4" />} value={password} onChange={e => setPassword(e.target.value)} onKeyDown={e => e.key === 'Enter' && loginPassword()} />

            <div className="flex items-center justify-between">
              <label className="flex cursor-pointer items-center gap-2 text-[13px] text-[#8FA8C4]">
                <input type="checkbox" checked={rememberMe} onChange={e => setRememberMe(e.target.checked)} className="h-4 w-4 rounded border-white/20 bg-white/5 accent-[#4D9FFF]" />
                Remember me
              </label>
              <a href="/forgot-password" className="text-[13px] font-semibold text-[#4D9FFF] hover:text-[#00D4FF]">Forgot password?</a>
            </div>

            <Button onClick={loginPassword} loading={loading} disabled={!email || !password} className="w-full mt-1">
              {loading ? 'Logging in...' : 'Login'}
            </Button>
          </div>
        )}

        {tab === 'otp' && (
          <div className="flex flex-col gap-4">
            <Input label="Email" type="email" icon={<Mail className="h-4 w-4" />} value={otpEmail} onChange={e => setOtpEmail(e.target.value)} disabled={otpSent} />
            {!otpSent ? (
              <Button onClick={sendLoginOtp} loading={loading} disabled={!otpEmail} className="w-full">Send OTP</Button>
            ) : (
              <>
                <div>
                  <Input label="Enter OTP" value={loginOtp} onChange={e => setLoginOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} maxLength={6} inputMode="numeric" className="text-center text-xl tracking-[0.4em] font-bold" icon={<ShieldCheck className="h-4 w-4" />} />
                  <div className="mt-2 text-center text-xs text-[#6B8BAF]">
                    Sent to {otpEmail} · <button onClick={sendLoginOtp} className="font-semibold text-[#4D9FFF] hover:text-[#00D4FF]">Resend</button>
                  </div>
                </div>
                <Button onClick={loginWithOtp} loading={loading} disabled={loginOtp.length !== 6} className="w-full">Verify & Login</Button>
                <Button variant="outline" onClick={() => { setOtpSent(false); setLoginOtp(''); clearAll() }} className="w-full">Change Email</Button>
              </>
            )}
          </div>
        )}

        <div className="my-6 flex items-center gap-3">
          <div className="h-px flex-1 bg-white/10" />
          <span className="text-xs text-[#6B8BAF]">Continue with</span>
          <div className="h-px flex-1 bg-white/10" />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Button variant="social" disabled title="Coming soon" className="w-full">
            <svg className="h-4 w-4" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.99.66-2.26 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.85A10.99 10.99 0 0012 23z"/><path fill="#FBBC05" d="M5.84 14.1a6.6 6.6 0 010-4.2V7.05H2.18a11 11 0 000 9.9z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1a10.99 10.99 0 00-9.82 6.05l3.66 2.85c.87-2.6 3.3-4.52 6.16-4.52z"/></svg>
            Google
          </Button>
          <Button variant="social" disabled title="Coming soon" className="w-full">
            <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 .3a12 12 0 00-3.8 23.4c.6.1.8-.3.8-.6v-2.2c-3.3.7-4-1.6-4-1.6-.6-1.4-1.4-1.8-1.4-1.8-1-.7.1-.7.1-.7 1.2 0 1.8 1.2 1.8 1.2 1.1 1.9 2.8 1.3 3.5 1 .1-.8.4-1.3.7-1.6-2.6-.3-5.4-1.4-5.4-6a4.7 4.7 0 011.2-3.2 4.3 4.3 0 01.1-3.2s1-.3 3.4 1.2a11.5 11.5 0 016 0c2.3-1.5 3.3-1.2 3.3-1.2a4.3 4.3 0 01.2 3.2 4.7 4.7 0 011.2 3.2c0 4.6-2.8 5.7-5.5 6 .5.4.9 1.1.9 2.3v3.3c0 .3.2.7.8.6A12 12 0 0012 .3z"/></svg>
            GitHub
          </Button>
        </div>

        <p className="mt-6 text-center text-[13px] text-[#6B8BAF]">
          New to ProveRank?{' '}
          <a href="/register" className="font-semibold text-[#4D9FFF] hover:text-[#00D4FF]">Create Account</a>
        </p>
      </GlassCard>

      <p className="mt-5 text-center text-xs text-[#4A6280]">🔒 Your data is encrypted and never shared with third parties</p>
    </PremiumAuthShell>
  )
}
