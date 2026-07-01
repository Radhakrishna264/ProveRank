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
