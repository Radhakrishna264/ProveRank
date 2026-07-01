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
