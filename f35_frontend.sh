#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — F35 Frontend: Auth Pages Ultra Redesign        ║
# ║  Neon Teal Theme · Split Panel + Step Rail Layout           ║
# ╚══════════════════════════════════════════════════════════════╝
set -e
FE=/home/runner/workspace/frontend
echo "🚀 F35 Frontend setup..."
mkdir -p "$FE/src/components" "$FE/app/forgot-password"

# ═══════════════════════════════════════════════════════════════
# 1. AuthShell.tsx — shared layout (Split Panel + Step Rail)
# ═══════════════════════════════════════════════════════════════
cat > "$FE/src/components/AuthShell.tsx" << 'ENDOFFILE'
'use client'
import PRLogo from '@/components/PRLogo'
import { ReactNode } from 'react'

export const T = {
  bg: 'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)',
  panel: 'rgba(0,50,44,0.9)',
  pri: '#2DD4BF',
  card: 'rgba(0,35,30,0.78)',
  cardBorder: 'rgba(0,200,160,0.22)',
  txt: '#CCFBF1',
  sub: '#5EEAD4',
  inputBg: 'rgba(0,20,18,0.8)',
  inputBorder: 'rgba(0,200,160,0.3)',
}

export const inp: any = {
  width: '100%', padding: '12px 14px', background: T.inputBg,
  border: `1.5px solid ${T.inputBorder}`, borderRadius: 10, color: T.txt,
  fontSize: 14, fontFamily: 'Inter,sans-serif', outline: 'none',
  boxSizing: 'border-box', transition: 'border-color .2s',
}

export function inpErr(hasError: boolean): any {
  return { ...inp, border: hasError ? '1.5px solid #FF4D4D' : inp.border }
}

interface Step { label: string }
interface Props { steps?: Step[]; current?: number; children: ReactNode }

export default function AuthShell({ steps = [], current = 0, children }: Props) {
  const hasSteps = steps.length > 1
  return (
    <div style={{ minHeight: '100vh', background: T.bg, fontFamily: 'Inter,sans-serif' }}>
      <style>{`
        @keyframes glowTeal{0%,100%{filter:drop-shadow(0 0 6px #2DD4BF66)}50%{filter:drop-shadow(0 0 20px #2DD4BFaa)}}
        @keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @keyframes confettiFall{0%{transform:translateY(-20px) rotate(0deg);opacity:1}100%{transform:translateY(420px) rotate(360deg);opacity:0}}
        *{box-sizing:border-box}
        .auth-mobile-bar{display:none}
        @media (max-width: 860px){
          .auth-left-panel, .auth-step-rail{display:none !important}
          .auth-mobile-bar{display:flex !important}
          .auth-row{flex-direction:column !important}
          .auth-form-area{padding:20px 16px 48px !important}
        }
      `}</style>

      {/* Mobile sticky top bar — logo + step dots (35.27) */}
      <div className="auth-mobile-bar" style={{ position: 'sticky', top: 0, zIndex: 30, height: 52, alignItems: 'center', justifyContent: 'space-between', padding: '0 16px', background: 'rgba(0,18,16,0.94)', backdropFilter: 'blur(14px)', borderBottom: `1px solid ${T.cardBorder}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ animation: 'glowTeal 3s ease-in-out infinite' }}><PRLogo size={24} /></div>
          <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 14, fontWeight: 700, color: T.pri }}>ProveRank</span>
        </div>
        {hasSteps && (
          <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
            {steps.map((_, i) => (
              <div key={i} style={{ width: i === current ? 16 : 6, height: 6, borderRadius: 3, background: i <= current ? T.pri : 'rgba(94,234,212,0.22)', transition: 'all .3s' }} />
            ))}
          </div>
        )}
      </div>

      {/* Desktop: 3-column row — branding | step rail | form (35.27) */}
      <div className="auth-row" style={{ display: 'flex', minHeight: '100vh' }}>

        <div className="auth-left-panel" style={{ width: 220, flexShrink: 0, background: T.panel, padding: '40px 22px', display: 'flex', flexDirection: 'column', gap: 22 }}>
          <div style={{ animation: 'glowTeal 3s ease-in-out infinite', width: 'fit-content' }}>
            <PRLogo size={40} />
          </div>
          <div>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: T.pri, lineHeight: 1.3 }}>ProveRank</div>
            <div style={{ fontSize: 11, color: T.sub, marginTop: 4, fontWeight: 600, letterSpacing: 0.4 }}>Rise to the Top</div>
          </div>
          <div style={{ height: 1, background: T.cardBorder }} />
          {[['🎯', 'NEET Pattern Tests'], ['📊', 'AI Analytics'], ['🏆', 'All India Ranking']].map(([ic, l]) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 17 }}>{ic}</span>
              <span style={{ fontSize: 12, color: T.txt, fontWeight: 500 }}>{l}</span>
            </div>
          ))}
        </div>

        {hasSteps && (
          <div className="auth-step-rail" style={{ width: 160, flexShrink: 0, padding: '40px 16px', display: 'flex', flexDirection: 'column', gap: 4 }}>
            {steps.map((s, i) => {
              const active = i === current, done = i < current
              return (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '9px 8px', borderRadius: 10, background: active ? 'rgba(45,212,191,0.1)' : 'transparent' }}>
                  <div style={{ width: 22, height: 22, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, flexShrink: 0, background: done ? T.pri : active ? 'rgba(45,212,191,0.2)' : 'rgba(94,234,212,0.08)', color: done ? '#001A1A' : active ? T.pri : T.sub, border: active ? `1.5px solid ${T.pri}` : '1px solid rgba(94,234,212,0.2)' }}>
                    {done ? '✓' : i + 1}
                  </div>
                  <span style={{ fontSize: 11, color: active ? T.txt : T.sub, fontWeight: active ? 700 : 400 }}>{s.label}</span>
                </div>
              )
            })}
          </div>
        )}

        <div className="auth-form-area" style={{ flex: 1, display: 'flex', justifyContent: 'center', padding: '40px 20px', overflowY: 'auto' }}>
          <div style={{ width: '100%', maxWidth: 420, animation: 'fadeIn .5s ease' }}>
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
ENDOFFILE
echo "✅ AuthShell.tsx created"

# ═══════════════════════════════════════════════════════════════
# 2. login/page.tsx — full rewrite (2-tab pill, eye toggle, no canvas)
# ═══════════════════════════════════════════════════════════════
cat > "$FE/app/login/page.tsx" << 'ENDOFFILE'
'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import AuthShell, { T, inp, inpErr } from '@/src/components/AuthShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

export default function LoginPage() {
  const router = useRouter()
  type Tab = 'password' | 'otp'
  const [tab, setTab] = useState<Tab>('password')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
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
      if (tk) { window.location.href = (role === 'superadmin' || role === 'admin') ? '/admin/x7k2p' : '/dashboard' }
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

  // ── F35: Password login (preserved logic) ──────────────────────
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
    <AuthShell>
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 24, fontWeight: 700, color: T.pri, marginBottom: 2 }}>Welcome Back</div>
        <div style={{ fontSize: 12, color: T.sub }}>Login to continue your NEET journey</div>
      </div>

      <div style={{ background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 20, padding: '28px 24px', backdropFilter: 'blur(24px)', boxShadow: '0 8px 40px rgba(0,0,0,.5)' }}>

        {/* F35.2 + F35.4 — 2-Tab pill system */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 22, borderRadius: 14, padding: 4, background: 'rgba(0,15,13,0.6)', border: `1px solid ${T.cardBorder}` }}>
          {([['password', '🔑 Password'], ['otp', '📱 OTP']] as const).map(([t, l]) => (
            <button key={t} onClick={() => { setTab(t); clearAll() }} style={{
              flex: 1, padding: '10px 4px', borderRadius: 10, border: 'none', cursor: 'pointer',
              fontFamily: 'Inter,sans-serif', fontSize: 13, fontWeight: tab === t ? 700 : 500,
              background: tab === t ? `linear-gradient(135deg,${T.pri},#0D9488)` : 'transparent',
              color: tab === t ? '#001A1A' : T.sub,
              boxShadow: tab === t ? '0 4px 14px rgba(45,212,191,0.4)' : 'none',
              transition: 'all .25s',
            }}>{l}</button>
          ))}
        </div>

        {error && <div style={errBox}>{error}</div>}
        {msg && <div style={okBox}>{msg}</div>}

        {tab === 'password' && (
          <>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 13, marginBottom: 16 }}>
              <div>
                <label style={lbl}>Email</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} onKeyDown={e => e.key === 'Enter' && loginPassword()} style={inpErr(!emailValid)} placeholder="your@email.com" />
              </div>
              <div>
                <label style={lbl}>Password</label>
                {/* F35.10 — Show/Hide password eye icon */}
                <div style={{ position: 'relative' }}>
                  <input type={showPass ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} onKeyDown={e => e.key === 'Enter' && loginPassword()} style={{ ...inp, paddingRight: 42 }} placeholder="••••••••" />
                  <button type="button" onClick={() => setShowPass(p => !p)} style={eyeBtn}>{showPass ? '🙈' : '👁️'}</button>
                </div>
              </div>
            </div>
            {/* F35.3 + F35.17 + F35.18 — Forgot Password link → separate page */}
            <div style={{ textAlign: 'right', marginBottom: 16 }}>
              <a href="/forgot-password" style={{ color: T.pri, fontSize: 12, fontWeight: 600, textDecoration: 'underline' }}>Forgot Password? →</a>
            </div>
            <button onClick={loginPassword} disabled={loading || !email || !password} style={btnPri(loading || !email || !password)}>{loading ? 'Logging in...' : 'Login →'}</button>
          </>
        )}

        {tab === 'otp' && (
          <>
            <div style={{ marginBottom: 13 }}>
              <label style={lbl}>Email</label>
              <input type="email" value={otpEmail} onChange={e => setOtpEmail(e.target.value)} style={inp} placeholder="your@email.com" disabled={otpSent} />
            </div>
            {!otpSent ? (
              <button onClick={sendLoginOtp} disabled={loading || !otpEmail} style={btnPri(loading || !otpEmail)}>{loading ? 'Sending OTP...' : 'Send OTP →'}</button>
            ) : (
              <>
                <div style={{ marginBottom: 13 }}>
                  <label style={lbl}>Enter OTP</label>
                  <input value={loginOtp} onChange={e => setLoginOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} style={{ ...inp, fontSize: 24, fontWeight: 900, textAlign: 'center', letterSpacing: 10, fontFamily: 'monospace' }} placeholder="000000" maxLength={6} inputMode="numeric" />
                  <div style={{ fontSize: 11, color: T.sub, marginTop: 5, textAlign: 'center' }}>OTP sent to {otpEmail} · <button onClick={sendLoginOtp} style={linkBtn}>Resend</button></div>
                </div>
                <button onClick={loginWithOtp} disabled={loading || loginOtp.length !== 6} style={btnSuc(loading || loginOtp.length !== 6)}>{loading ? 'Verifying...' : '✅ Login with OTP →'}</button>
                <button onClick={() => { setOtpSent(false); setLoginOtp(''); clearAll() }} style={backBtn}>← Change Email</button>
              </>
            )}
          </>
        )}

        <div style={{ textAlign: 'center', marginTop: 16, fontSize: 13, color: T.sub }}>New to ProveRank?{' '}<a href="/register" style={{ color: T.pri, fontWeight: 600, textDecoration: 'none' }}>Create Account →</a></div>
      </div>
    </AuthShell>
  )
}

const lbl: any = { fontSize: 11, color: T.pri, fontWeight: 600, display: 'block', marginBottom: 5, textTransform: 'uppercase', letterSpacing: .4 }
const eyeBtn: any = { position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, padding: 4 }
const linkBtn: any = { background: 'none', border: 'none', color: T.pri, fontSize: 11, cursor: 'pointer', fontFamily: 'Inter,sans-serif', fontWeight: 600, padding: 0 }
const backBtn: any = { width: '100%', marginTop: 10, padding: '8px', background: 'none', border: `1px solid ${T.cardBorder}`, borderRadius: 9, color: T.sub, cursor: 'pointer', fontSize: 12, fontFamily: 'Inter,sans-serif' }
const errBox: any = { background: 'rgba(255,77,77,.12)', border: '1px solid rgba(255,77,77,.3)', borderRadius: 9, padding: '10px 14px', fontSize: 13, color: '#FF4D4D', marginBottom: 14, textAlign: 'center' }
const okBox: any = { background: 'rgba(0,196,140,.1)', border: '1px solid rgba(0,196,140,.3)', borderRadius: 9, padding: '10px 14px', fontSize: 13, color: '#00C48C', marginBottom: 14, textAlign: 'center' }
function btnPri(disabled: boolean): any { return { width: '100%', padding: '13px', background: `linear-gradient(135deg,${T.pri},#0D9488)`, color: '#001A1A', border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1, boxShadow: '0 4px 16px rgba(45,212,191,0.4)' } }
function btnSuc(disabled: boolean): any { return { width: '100%', padding: '13px', background: disabled ? 'rgba(94,234,212,.15)' : 'linear-gradient(135deg,#00C48C,#00a87a)', color: disabled ? T.sub : '#001A1A', border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1 } }
ENDOFFILE
echo "✅ login/page.tsx rewritten"

# ═══════════════════════════════════════════════════════════════
# 3. register/page.tsx — full rewrite (stepper, validation, confetti)
# ═══════════════════════════════════════════════════════════════
cat > "$FE/app/register/page.tsx" << 'ENDOFFILE'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import AuthShell, { T, inp, inpErr } from '@/src/components/AuthShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const PHONE_RE = /^\+91[\s]?[6-9]\d{9}$/

export default function RegisterPage() {
  const router = useRouter()
  const [step, setStep] = useState<'details' | 'otp' | 'done'>('details')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [phone, setPhone] = useState('')
  const [otp, setOtp] = useState('')
  const [agreedTnc, setAgreedTnc] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')
  const [resending, setResend] = useState(false)
  const [resendCooldown, setResendCooldown] = useState(0)

  // F35.8 — Email availability check (debounced 500ms) / Real-time format validation
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

  // F35.9 — OTP resend countdown
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
        setStep('done') // F35.14 — confetti success before redirect
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

  // F35.13 — Registration progress stepper
  const steps = [{ label: 'Email & Details' }, { label: 'Verify OTP' }, { label: 'Done' }]
  const currentStepIdx = step === 'details' ? 0 : step === 'otp' ? 1 : 2

  return (
    <AuthShell steps={steps} current={currentStepIdx}>

      {step === 'details' && (
        <div style={{ background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 20, padding: '30px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 8px 40px rgba(0,0,0,.5)' }}>
          <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.txt, margin: '0 0 6px', textAlign: 'center' }}>Create Account</h2>
          <p style={{ fontSize: 13, color: T.sub, textAlign: 'center', marginBottom: 22 }}>Join ProveRank — Rise to the Top</p>
          {error && <div style={errBox}>{error}</div>}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 13 }}>
            <div>
              <label style={lbl}>Full Name *</label>
              <input value={name} onChange={e => setName(e.target.value)} style={inp} placeholder="Your full name" />
            </div>
            <div>
              <label style={lbl}>Email *</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} style={inpErr(!emailValid)} placeholder="your@email.com" />
              {email && emailValid && (
                <div style={{ fontSize: 11, marginTop: 5, color: emailCheck.checking ? T.sub : emailCheck.available === false ? '#FF4D4D' : emailCheck.available === true ? '#00C48C' : T.sub }}>
                  {emailCheck.checking ? 'Checking availability...' : emailCheck.available === false ? '❌ ' + (emailCheck.msg || 'Already registered') : emailCheck.available === true ? '✅ Email available' : ''}
                </div>
              )}
              {email && !emailValid && <div style={{ fontSize: 11, color: '#FF4D4D', marginTop: 5 }}>Invalid email format</div>}
            </div>
            <div>
              <label style={lbl}>Password *</label>
              <div style={{ position: 'relative' }}>
                <input type={showPass ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} style={{ ...inp, paddingRight: 42 }} placeholder="Min 6 characters" />
                <button type="button" onClick={() => setShowPass(p => !p)} style={eyeBtn}>{showPass ? '🙈' : '👁️'}</button>
              </div>
            </div>
            <div>
              <label style={lbl}>Phone (optional)</label>
              <input value={phone} onChange={e => setPhone(e.target.value)} style={inpErr(!phoneValid)} placeholder="+91 XXXXXXXXXX" />
              {phone && !phoneValid && <div style={{ fontSize: 11, color: '#FF4D4D', marginTop: 5 }}>Format: +91 followed by 10 digits</div>}
            </div>
          </div>

          {/* F35.12 — T&C checkbox required */}
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 8, marginTop: 18, cursor: 'pointer' }}>
            <input type="checkbox" checked={agreedTnc} onChange={e => setAgreedTnc(e.target.checked)} style={{ marginTop: 2, accentColor: T.pri, width: 16, height: 16, flexShrink: 0 }} />
            <span style={{ fontSize: 12, color: T.sub, lineHeight: 1.5 }}>I agree to the <a href="/terms" target="_blank" style={{ color: T.pri, fontWeight: 600 }}>Terms &amp; Conditions</a> and Privacy Policy</span>
          </label>

          <button onClick={register} disabled={loading || !canSubmit} style={{ ...btnPri(loading || !canSubmit), marginTop: 20 }}>{loading ? 'Creating Account...' : 'Create Account →'}</button>
          <div style={{ textAlign: 'center', marginTop: 16, fontSize: 13, color: T.sub }}>Already have an account?{' '}<a href="/login" style={{ color: T.pri, fontWeight: 600, textDecoration: 'none' }}>Login →</a></div>
        </div>
      )}

      {step === 'otp' && (
        <div style={{ background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 20, padding: '30px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 8px 40px rgba(0,0,0,.5)' }}>
          <div style={{ textAlign: 'center', marginBottom: 22 }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>📧</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.txt, margin: '0 0 6px' }}>Verify Your Email</h2>
            <p style={{ fontSize: 13, color: T.sub, margin: 0 }}>OTP sent to <span style={{ color: T.pri, fontWeight: 600 }}>{email}</span></p>
          </div>
          {error && <div style={errBox}>{error}</div>}
          {msg && <div style={okBox}>{msg}</div>}
          <div style={{ marginBottom: 18 }}>
            <label style={{ ...lbl, textAlign: 'center' }}>Enter 6-Digit OTP</label>
            <input value={otp} onChange={e => { setOtp(e.target.value.replace(/\D/g, '').slice(0, 6)); setError('') }} style={{ ...inp, fontSize: 28, fontWeight: 900, textAlign: 'center', letterSpacing: 12, fontFamily: 'monospace', padding: '16px' }} placeholder="000000" maxLength={6} inputMode="numeric" />
          </div>
          <button onClick={verifyOtp} disabled={loading || otp.length !== 6} style={btnSuc(loading || otp.length !== 6)}>{loading ? 'Verifying...' : '✅ Verify & Continue →'}</button>
          {/* F35.9 — Resend countdown */}
          <div style={{ textAlign: 'center', marginTop: 14, fontSize: 12, color: T.sub }}>
            Didn&apos;t receive OTP?{' '}
            {resendCooldown > 0
              ? <span style={{ color: T.sub }}>Resend in 0:{resendCooldown < 10 ? '0' + resendCooldown : resendCooldown}</span>
              : <button onClick={resendOtp} disabled={resending} style={linkBtn}>{resending ? 'Sending...' : 'Resend OTP'}</button>}
          </div>
          <div style={{ textAlign: 'center', marginTop: 8, fontSize: 11, color: T.sub }}>OTP valid for 10 minutes · Check spam/junk folder</div>
          <button onClick={() => { setStep('details'); setOtp(''); setError(''); setMsg('') }} style={backBtn}>← Change Email / Register Again</button>
        </div>
      )}

      {step === 'done' && (
        <div style={{ background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 20, padding: '40px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 8px 40px rgba(0,0,0,.5)', textAlign: 'center', position: 'relative', overflow: 'hidden' }}>
          {/* F35.14 — confetti burst */}
          {Array.from({ length: 24 }).map((_, i) => (
            <div key={i} style={{ position: 'absolute', top: -10, left: `${Math.random() * 100}%`, width: 7, height: 7, borderRadius: i % 2 === 0 ? '50%' : 2, background: [T.pri, '#00C48C', '#FFD700', '#fff'][i % 4], animation: `confettiFall ${1.4 + Math.random() * 1.2}s ease-in forwards`, animationDelay: `${Math.random() * 0.4}s` }} />
          ))}
          <div style={{ fontSize: 56, marginBottom: 14 }}>🎉</div>
          <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.txt, marginBottom: 8 }}>Welcome to ProveRank!</h2>
          <p style={{ fontSize: 13, color: T.sub }}>Redirecting to your dashboard...</p>
        </div>
      )}

    </AuthShell>
  )
}

const lbl: any = { fontSize: 11, color: T.pri, fontWeight: 600, display: 'block', marginBottom: 5, textTransform: 'uppercase', letterSpacing: .4 }
const eyeBtn: any = { position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, padding: 4 }
const linkBtn: any = { background: 'none', border: 'none', color: T.pri, fontSize: 11, cursor: 'pointer', fontFamily: 'Inter,sans-serif', fontWeight: 600, padding: 0 }
const backBtn: any = { width: '100%', marginTop: 14, padding: '8px', background: 'none', border: `1px solid ${T.cardBorder}`, borderRadius: 9, color: T.sub, cursor: 'pointer', fontSize: 12, fontFamily: 'Inter,sans-serif' }
const errBox: any = { background: 'rgba(255,77,77,.12)', border: '1px solid rgba(255,77,77,.3)', borderRadius: 9, padding: '10px 14px', fontSize: 13, color: '#FF4D4D', marginBottom: 14, textAlign: 'center' }
const okBox: any = { background: 'rgba(0,196,140,.1)', border: '1px solid rgba(0,196,140,.3)', borderRadius: 9, padding: '10px 14px', fontSize: 13, color: '#00C48C', marginBottom: 14, textAlign: 'center' }
function btnPri(disabled: boolean): any { return { width: '100%', padding: '13px', background: `linear-gradient(135deg,${T.pri},#0D9488)`, color: '#001A1A', border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1, boxShadow: '0 4px 16px rgba(45,212,191,0.4)' } }
function btnSuc(disabled: boolean): any { return { width: '100%', padding: '13px', background: disabled ? 'rgba(94,234,212,.15)' : 'linear-gradient(135deg,#00C48C,#00a87a)', color: disabled ? T.sub : '#001A1A', border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1 } }
ENDOFFILE
echo "✅ register/page.tsx rewritten"

# ═══════════════════════════════════════════════════════════════
# 4. forgot-password/page.tsx — NEW separate page
# ═══════════════════════════════════════════════════════════════
cat > "$FE/app/forgot-password/page.tsx" << 'ENDOFFILE'
'use client'
import { useState } from 'react'
import AuthShell, { T, inp, inpErr } from '@/src/components/AuthShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

export default function ForgotPasswordPage() {
  const [step, setStep] = useState<'email' | 'otp' | 'done'>('email')
  const [email, setEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [newPass, setNewPass] = useState('')
  const [confirmPass, setConfirmPass] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')

  // F35.19 — Step 1: Email + Send OTP
  const sendOtp = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/forgot-password`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email }) })
      const d = await r.json()
      if (r.ok) { setStep('otp'); setMsg(d.message || 'OTP sent!') } else setError(d.message || 'Failed')
    } catch { setError('Network error') }
    setLoading(false)
  }

  // F35.22 — Live password match validation
  const passMatch = !confirmPass || newPass === confirmPass

  // F35.20 — Step 2: OTP verification + new password
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
    <AuthShell steps={steps} current={currentIdx}>
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.pri }}>Reset Password</div>
        <div style={{ fontSize: 12, color: T.sub, marginTop: 4 }}>We&apos;ll help you get back in</div>
      </div>

      <div style={{ background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 20, padding: '28px 24px', backdropFilter: 'blur(24px)', boxShadow: '0 8px 40px rgba(0,0,0,.5)' }}>

        {error && <div style={errBox}>{error}</div>}
        {msg && step !== 'done' && <div style={okBox}>{msg}</div>}

        {step === 'email' && (
          <>
            <p style={{ fontSize: 13, color: T.sub, marginBottom: 16, textAlign: 'center' }}>Enter your registered email — we&apos;ll send a reset OTP.</p>
            <div style={{ marginBottom: 16 }}>
              <label style={lbl}>Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} style={inp} placeholder="your@email.com" />
            </div>
            <button onClick={sendOtp} disabled={loading || !email} style={btnPri(loading || !email)}>{loading ? 'Sending OTP...' : 'Send Reset OTP →'}</button>
          </>
        )}

        {step === 'otp' && (
          <>
            <p style={{ fontSize: 13, color: T.sub, marginBottom: 16, textAlign: 'center' }}>OTP sent to <span style={{ color: T.pri, fontWeight: 600 }}>{email}</span></p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 6 }}>
              <div>
                <label style={lbl}>OTP</label>
                <input value={otp} onChange={e => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} style={{ ...inp, fontSize: 22, fontWeight: 900, textAlign: 'center', letterSpacing: 10, fontFamily: 'monospace' }} placeholder="000000" maxLength={6} inputMode="numeric" />
              </div>
              <div>
                <label style={lbl}>New Password</label>
                <div style={{ position: 'relative' }}>
                  <input type={showPass ? 'text' : 'password'} value={newPass} onChange={e => setNewPass(e.target.value)} style={{ ...inp, paddingRight: 42 }} placeholder="Min 6 characters" />
                  <button type="button" onClick={() => setShowPass(p => !p)} style={eyeBtn}>{showPass ? '🙈' : '👁️'}</button>
                </div>
              </div>
              <div>
                <label style={lbl}>Confirm Password</label>
                <input type={showPass ? 'text' : 'password'} value={confirmPass} onChange={e => setConfirmPass(e.target.value)} style={inpErr(!passMatch)} placeholder="Re-enter password" />
                {!passMatch && <div style={{ fontSize: 11, color: '#FF4D4D', marginTop: 5 }}>Passwords do not match</div>}
                {confirmPass && passMatch && newPass.length >= 6 && <div style={{ fontSize: 11, color: '#00C48C', marginTop: 5 }}>✅ Passwords match</div>}
              </div>
            </div>
            <button onClick={resetPassword} disabled={loading || otp.length !== 6 || newPass.length < 6 || !passMatch} style={btnSuc(loading || otp.length !== 6 || newPass.length < 6 || !passMatch)}>{loading ? 'Resetting...' : '🔑 Reset Password →'}</button>
            <button onClick={() => { setStep('email'); setError(''); setMsg('') }} style={backBtn}>← Back</button>
          </>
        )}

        {step === 'done' && (
          // F35.21 — Step 3: Success screen
          <div style={{ textAlign: 'center', padding: '10px 0' }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>✅</div>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 18, fontWeight: 700, color: T.txt, marginBottom: 8 }}>Password Reset!</div>
            <div style={{ fontSize: 13, color: T.sub, marginBottom: 20 }}>You can now login with your new password.</div>
          </div>
        )}

        {/* F35.23 — Back to Login link */}
        <div style={{ textAlign: 'center', marginTop: 18, fontSize: 13, color: T.sub }}><a href="/login" style={{ color: T.pri, fontWeight: 600, textDecoration: 'none' }}>← Back to Login</a></div>
      </div>
    </AuthShell>
  )
}

const lbl: any = { fontSize: 11, color: T.pri, fontWeight: 600, display: 'block', marginBottom: 5, textTransform: 'uppercase', letterSpacing: .4 }
const eyeBtn: any = { position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, padding: 4 }
const backBtn: any = { width: '100%', marginTop: 10, padding: '8px', background: 'none', border: `1px solid ${T.cardBorder}`, borderRadius: 9, color: T.sub, cursor: 'pointer', fontSize: 12, fontFamily: 'Inter,sans-serif' }
const errBox: any = { background: 'rgba(255,77,77,.12)', border: '1px solid rgba(255,77,77,.3)', borderRadius: 9, padding: '10px 14px', fontSize: 13, color: '#FF4D4D', marginBottom: 14, textAlign: 'center' }
const okBox: any = { background: 'rgba(0,196,140,.1)', border: '1px solid rgba(0,196,140,.3)', borderRadius: 9, padding: '10px 14px', fontSize: 13, color: '#00C48C', marginBottom: 14, textAlign: 'center' }
function btnPri(disabled: boolean): any { return { width: '100%', padding: '13px', background: `linear-gradient(135deg,${T.pri},#0D9488)`, color: '#001A1A', border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1, boxShadow: '0 4px 16px rgba(45,212,191,0.4)' } }
function btnSuc(disabled: boolean): any { return { width: '100%', padding: '13px', background: disabled ? 'rgba(94,234,212,.15)' : 'linear-gradient(135deg,#00C48C,#00a87a)', color: disabled ? T.sub : '#001A1A', border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1 } }
ENDOFFILE
echo "✅ forgot-password/page.tsx created"

# ═══════════════════════════════════════════════════════════════
# 5. terms/page.tsx — full rewrite (scroll enforce, sections edit)
# ═══════════════════════════════════════════════════════════════
cat > "$FE/app/terms/page.tsx" << 'ENDOFFILE'
'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import PRLogo from '@/components/PRLogo'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const TERMS_VERSION = 'Version 2.1 — Updated March 2026'
const PRI = '#2DD4BF', SUB = '#5EEAD4', TXT = '#CCFBF1'
const CARD = 'rgba(0,35,30,0.78)', BORD = 'rgba(0,200,160,0.22)'

const SECTIONS_EN = [
  { title: '1. Exam Rules & Conduct', content: 'Students must attempt exams in a quiet, well-lit environment. Any form of cheating, including using external resources, sharing questions, or impersonating another student, will result in immediate disqualification and permanent account ban. All exam sessions are monitored by AI-powered proctoring including face detection, tab tracking, and IP verification.' },
  { title: '2. Privacy Policy', content: 'ProveRank collects your name, email, and exam performance data solely for platform operation and analytics. We do not share your personal data with third parties. Webcam snapshots captured during proctoring are used solely for AI-based exam monitoring purposes and are automatically deleted from our database within 24 hours. You may request data deletion at support@proverank.com.' },
  { title: '3. Proctoring Policy', content: 'By starting any exam, you consent to: (a) webcam access for AI-based facial monitoring, (b) tab-switch and window-blur tracking, (c) IP address logging. Disabling your webcam mid-exam or switching tabs will trigger warnings. Three warnings result in automatic exam submission.' },
  { title: '4. Result & Ranking Policy', content: 'All India Ranks are calculated based on score, then time taken. Percentiles follow NEET standard formula. Results are final unless a successful Answer Key Challenge is filed within 48 hours of publication. Re-evaluation requests are processed within 7 working days.' },
  { title: '5. Account & Access Policy', content: 'Each student account is for individual use only. Sharing login credentials is strictly prohibited. Logging in on a new device automatically signs you out of your previous device for security. ProveRank reserves the right to suspend or permanently ban accounts found in violation of any policy.' },
  { title: '6. Refund & Payment Policy', content: 'All purchases (premium plans, test series access) are non-refundable once access has been granted. In case of verified technical failures on our end, credit will be added to your account. Disputes must be raised within 7 days of the transaction.' },
  { title: '7. Data Security & AI Monitoring', content: 'All data is encrypted in transit and at rest. Our AI proctoring system analyses video feed in real-time and does not perform facial recognition for identity storage beyond the active exam session. We never sell or rent your data to advertisers or external companies.' },
  { title: '8. Grievance Redressal', content: 'For any complaints, disputes, or concerns regarding your account, exam results, or data privacy, please contact support@proverank.com. We aim to respond to all grievances within 48 hours and resolve them within 7 working days.' },
]

const SECTIONS_HI = [
  { title: '1. परीक्षा नियम और आचरण', content: 'छात्रों को शांत, अच्छी रोशनी वाले वातावरण में परीक्षा देनी चाहिए। किसी भी प्रकार की नकल, जिसमें बाहरी संसाधनों का उपयोग, प्रश्न साझा करना, या दूसरे छात्र की नकल करना शामिल है, तत्काल अयोग्यता और स्थायी खाता प्रतिबंध का कारण बनेगा।' },
  { title: '2. गोपनीयता नीति', content: 'ProveRank आपका नाम, ईमेल और परीक्षा प्रदर्शन डेटा केवल प्लेटफॉर्म संचालन के लिए एकत्र करता है। हम आपका व्यक्तिगत डेटा तृतीय पक्षों के साथ साझा नहीं करते। प्रोक्टरिंग के दौरान लिए गए वेबकैम स्नैपशॉट केवल AI-आधारित निगरानी हेतु उपयोग होते हैं और हमारे डेटाबेस से 24 घंटों के भीतर स्वचालित रूप से हटा दिए जाते हैं।' },
  { title: '3. प्रोक्टरिंग नीति', content: 'किसी भी परीक्षा को शुरू करके, आप सहमति देते हैं: (a) AI-आधारित चेहरे की निगरानी के लिए वेबकैम एक्सेस, (b) टैब-स्विच ट्रैकिंग, (c) IP एड्रेस लॉगिंग। तीन चेतावनियों के बाद स्वचालित रूप से परीक्षा जमा हो जाती है।' },
  { title: '4. परिणाम और रैंकिंग नीति', content: 'अखिल भारत रैंक स्कोर के आधार पर गणना की जाती है, फिर लिए गए समय के आधार पर। परिणाम प्रकाशन के 48 घंटों के भीतर उत्तर कुंजी चुनौती दायर की जा सकती है। पुनर्मूल्यांकन अनुरोध 7 कार्य दिवसों में संसाधित किए जाते हैं।' },
  { title: '5. खाता और एक्सेस नीति', content: 'प्रत्येक छात्र खाता केवल व्यक्तिगत उपयोग के लिए है। लॉगिन क्रेडेंशियल साझा करना सख्त मना है। नए डिवाइस पर लॉगिन करने से सुरक्षा हेतु आपका पिछला डिवाइस स्वतः लॉगआउट हो जाता है।' },
  { title: '6. रिफंड और भुगतान नीति', content: 'एक्सेस दिए जाने के बाद सभी खरीद अप्रतिदेय हैं। हमारी तकनीकी विफलता के मामले में, क्रेडिट आपके खाते में जोड़ा जाएगा। विवाद लेनदेन के 7 दिनों के भीतर उठाए जाने चाहिए।' },
  { title: '7. डेटा सुरक्षा और AI निगरानी', content: 'सभी डेटा एन्क्रिप्टेड रहता है। हमारा AI प्रोक्टरिंग सिस्टम रीयल-टाइम में वीडियो का विश्लेषण करता है और सक्रिय परीक्षा सत्र के बाद पहचान भंडारण के लिए चेहरा पहचान नहीं करता। हम आपका डेटा कभी भी विज्ञापनदाताओं को नहीं बेचते।' },
  { title: '8. शिकायत निवारण', content: 'अपने खाते, परीक्षा परिणाम, या डेटा गोपनीयता से संबंधित किसी भी शिकायत के लिए कृपया support@proverank.com पर संपर्क करें। हम 48 घंटों के भीतर जवाब देने का प्रयास करते हैं।' },
]

export default function TermsPage() {
  const router = useRouter()
  const [lang, setLang] = useState<'en' | 'hi'>('en')
  const [open, setOpen] = useState<number[]>([])
  const [mounted, setMounted] = useState(false)
  const [scrollPct, setScrollPct] = useState(0)
  const [canAccept, setCanAccept] = useState(false)
  const [accepting, setAccepting] = useState(false)

  useEffect(() => {
    setMounted(true)
    try { const sl = localStorage.getItem('pr_lang') as 'en' | 'hi'; if (sl) setLang(sl) } catch {}
  }, [])

  // F35.15 — Scroll-to-bottom enforcement + progress bar
  useEffect(() => {
    const onScroll = () => {
      const doc = document.documentElement
      const scrollTop = doc.scrollTop || document.body.scrollTop
      const scrollHeight = doc.scrollHeight - doc.clientHeight
      const pct = scrollHeight > 0 ? Math.min(100, (scrollTop / scrollHeight) * 100) : 100
      setScrollPct(pct)
      if (pct >= 92) setCanAccept(true)
    }
    window.addEventListener('scroll', onScroll)
    onScroll()
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const toggleLang = () => { const n = lang === 'en' ? 'hi' : 'en'; setLang(n); try { localStorage.setItem('pr_lang', n) } catch {} }
  const toggle = (i: number) => setOpen(o => o.includes(i) ? o.filter(x => x !== i) : [...o, i])
  const sections = lang === 'en' ? SECTIONS_EN : SECTIONS_HI

  // F35.15 — Timestamp + version saved on accept
  const handleAccept = async () => {
    if (!canAccept) return
    setAccepting(true)
    try { localStorage.setItem('pr_terms_accepted', 'true') } catch {}
    try {
      const tk = localStorage.getItem('pr_token')
      if (tk) await fetch(`${API}/api/auth/accept-terms`, { method: 'POST', headers: { Authorization: `Bearer ${tk}` } })
    } catch {}
    const back = new URLSearchParams(window.location.search).get('back')
    if (back) router.push(back); else router.push('/dashboard')
  }

  if (!mounted) return null

  return (
    <div style={{ minHeight: '100vh', background: 'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)', color: TXT, fontFamily: 'Inter,sans-serif' }}>
      <style>{`
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes glowTeal{0%,100%{filter:drop-shadow(0 0 6px #2DD4BF66)}50%{filter:drop-shadow(0 0 20px #2DD4BFaa)}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(0,200,160,.35);background:rgba(0,20,18,.6);color:${TXT};font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}
        .tbtn:hover{border-color:${PRI};background:rgba(45,212,191,0.15);}
        .lb{width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,${PRI},#0D9488);color:#001A1A;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(45,212,191,0.4);transition:all 0.3s;}
        .lb:hover:not(:disabled){transform:translateY(-2px);}
        .lb:disabled{opacity:.4;cursor:not-allowed;box-shadow:none}
      `}</style>

      {/* F35.15 — Scroll progress bar */}
      <div style={{ position: 'fixed', top: 0, left: 0, height: 3, width: `${scrollPct}%`, background: `linear-gradient(90deg,${PRI},#00C48C)`, zIndex: 60, transition: 'width .1s linear' }} />

      <div style={{ borderBottom: `1px solid ${BORD}`, padding: '18px 5%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'sticky', top: 0, background: 'rgba(0,12,11,0.92)', backdropFilter: 'blur(20px)', zIndex: 50 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <button onClick={() => router.back()} style={{ background: 'none', border: 'none', color: PRI, cursor: 'pointer', fontSize: 20 }}>←</button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ animation: 'glowTeal 3s ease-in-out infinite' }}><PRLogo size={26} /></div>
            <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 17, fontWeight: 700, color: PRI }}>ProveRank</span>
          </div>
        </div>
        <button className="tbtn" onClick={toggleLang}>{lang === 'en' ? '🇮🇳 EN' : '🌐 हिंदी'}</button>
      </div>

      <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 5% 60px' }}>
        <div style={{ textAlign: 'center', marginBottom: 40, animation: 'fadeUp 0.6s ease forwards' }}>
          <h1 style={{ fontFamily: 'Playfair Display,serif', fontSize: 'clamp(1.8rem,4vw,2.6rem)', fontWeight: 700, marginBottom: 10, color: TXT }}>
            {lang === 'en' ? 'Terms & Conditions' : 'नियम और शर्तें'}
          </h1>
          {/* F35.15 — Version tracking */}
          <p style={{ color: PRI, fontSize: 12, fontWeight: 700, letterSpacing: 0.5 }}>{TERMS_VERSION}</p>
          <p style={{ color: SUB, fontSize: 15, marginTop: 14, maxWidth: 520, margin: '14px auto 0' }}>
            {lang === 'en' ? 'Please scroll through and read all terms carefully before accepting.' : 'स्वीकार करने से पहले कृपया सभी नियम ध्यान से पढ़ें।'}
          </p>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 36 }}>
          {sections.map((s, i) => (
            <div key={i} style={{ background: CARD, border: `1px solid ${open.includes(i) ? 'rgba(45,212,191,0.45)' : BORD}`, borderRadius: 14, overflow: 'hidden', transition: 'all 0.3s', backdropFilter: 'blur(20px)' }}>
              <button onClick={() => toggle(i)} style={{ width: '100%', padding: '18px 22px', background: 'none', border: 'none', color: TXT, display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: 'pointer', fontWeight: 600, fontSize: 15, textAlign: 'left', fontFamily: 'Inter,sans-serif' }}>
                {s.title}
                <span style={{ color: PRI, fontSize: 20, fontWeight: 300, transition: 'transform 0.3s', transform: open.includes(i) ? 'rotate(45deg)' : 'none', display: 'inline-block' }}>+</span>
              </button>
              {open.includes(i) && (
                <div style={{ padding: '0 22px 18px', color: SUB, fontSize: 14, lineHeight: 1.8, borderTop: `1px solid ${BORD}`, paddingTop: 14 }}>
                  {s.content}
                </div>
              )}
            </div>
          ))}
        </div>

        {!canAccept && (
          <div style={{ textAlign: 'center', fontSize: 12, color: SUB, marginBottom: 14 }}>
            ⬇ {lang === 'en' ? 'Scroll to the bottom to enable Accept' : 'स्वीकार करने हेतु नीचे स्क्रॉल करें'} ({Math.round(scrollPct)}%)
          </div>
        )}

        <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
          <button className="lb" onClick={handleAccept} disabled={!canAccept || accepting} style={{ flex: 1, minWidth: 200 }}>
            {accepting ? '...' : `✓ ${lang === 'en' ? 'I Accept All Terms' : 'मैं सभी शर्तें स्वीकार करता/करती हूं'}`}
          </button>
          <button onClick={() => router.back()} style={{ flex: 1, minWidth: 200, padding: 15, borderRadius: 10, border: `1.5px solid ${BORD}`, background: 'transparent', color: SUB, fontSize: 16, fontWeight: 600, cursor: 'pointer', fontFamily: 'Inter,sans-serif' }}>
            {lang === 'en' ? 'Decline' : 'अस्वीकार करें'}
          </button>
        </div>
      </div>
    </div>
  )
}
ENDOFFILE
echo "✅ terms/page.tsx rewritten"

# ═══════════════════════════════════════════════════════════════
# 6. Patch admin page.tsx — F35.6 gate login history to SuperAdmin
# ═══════════════════════════════════════════════════════════════
node << 'EOF'
const fs = require('fs');
const f  = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
if (!fs.existsSync(f)) { console.log('❌ admin page.tsx not found'); process.exit(0); }
let c = fs.readFileSync(f, 'utf8');

const OLD = `{selStudent.loginHistory&&selStudent.loginHistory.length>0&&(`;
const NEW = `{role==='superadmin'&&selStudent.loginHistory&&selStudent.loginHistory.length>0&&(`;

if (c.includes(NEW)) {
  console.log('✅ Already gated to SuperAdmin only');
} else if (c.includes(OLD)) {
  c = c.replace(OLD, NEW);
  fs.writeFileSync(f, c);
  console.log('✅ F35.6: Login activity gated to SuperAdmin only');
} else {
  console.log('⚠️  Anchor not found — check admin page manually');
}
EOF

# ─── Verification ───────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  F35 Frontend — Verification"
echo "══════════════════════════════════════════════════════════"
L="$FE/app/login/page.tsx"
R="$FE/app/register/page.tsx"
FP="$FE/app/forgot-password/page.tsx"
TR="$FE/app/terms/page.tsx"
AS="$FE/src/components/AuthShell.tsx"
AD="$FE/app/admin/x7k2p/page.tsx"

chk(){ grep -q "$2" "$1" 2>/dev/null && echo "  ✅ $3" || echo "  ❌ $3"; }

chk "$AD" "role==='superadmin'&&selStudent.loginHistory" "35.6  Login activity — SuperAdmin only gate"
chk "$L"  "'password'.*'otp'"                              "35.2  2-Tab system (Password/OTP)"
chk "$L"  "Forgot Password? →"                              "35.3  Forgot Password link → page"
chk "$AS" "pri: '#2DD4BF'"                                  "35.4/35.26 Neon Teal theme colors"
chk "$AS" "Rise to the Top"                                 "35.5  Logo subtitle updated"
chk "$R"  "format validation"                                "35.7  Email format validation"
chk "$R"  "check-email"                                      "35.8  Email availability check (debounced)"
chk "$R"  "resendCooldown"                                   "35.9  OTP resend countdown"
chk "$L"  "showPass"                                          "35.10 Show/Hide password (login)"
chk "$R"  "PHONE_RE"                                          "35.11 Phone format validation"
chk "$R"  "agreedTnc"                                         "35.12 T&C checkbox required"
chk "$R"  "Registration progress stepper"                     "35.13 Registration stepper"
chk "$R"  "confettiFall"                                      "35.14 Confetti success animation"
chk "$TR" "scrollPct"                                         "35.15 Scroll enforcement + progress bar"
chk "$TR" "accept-terms"                                      "35.15 Timestamp + version save (API call)"
chk "$TR" "TERMS_VERSION"                                     "35.15 Version tracking display"
chk "$TR" "AI Monitoring"                                     "35.16 New section added"
chk "$TR" "Grievance Redressal"                               "35.16 New section added (2nd)"
chk "$TR" "deleted from our database within 24 hours"        "35.16 Webcam clause modified (24hr)"
chk "$FP" "export default function ForgotPasswordPage"        "35.17 Separate /forgot-password page"
chk "$L"  'href="/forgot-password"'                           "35.18 Login links to forgot page"
chk "$FP" "Send Reset OTP"                                    "35.19 Step 1: Email + Send OTP"
chk "$FP" "Reset Password →"                                  "35.20 Step 2: OTP + new password"
chk "$FP" "Password Reset!"                                   "35.21 Step 3: Success screen"
chk "$FP" "passMatch"                                          "35.22 Live password match validation"
chk "$FP" "Back to Login"                                     "35.23 Back to Login link"
chk "$AS" "glowTeal"                                           "35.25/35.28 Teal glow (no canvas/SVG)"
chk "$AS" "linear-gradient(145deg,#001A1A"                    "35.26 Neon Teal background"
chk "$AS" "auth-step-rail"                                     "35.27 Split panel + step rail layout"
chk "$AS" "auth-mobile-bar"                                     "35.27 Mobile top navbar"

echo ""
echo "══════════════════════════════════════════════════════════"
echo "🎉 git add . && git commit -m 'feat: F35 — Auth pages Neon Teal redesign' && git push"
echo "══════════════════════════════════════════════════════════"
