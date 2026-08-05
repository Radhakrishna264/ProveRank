#!/bin/bash
# ProveRank — Auth Pages Ultra Premium Redesign (Neon Blue theme, multi-exam signature)
# Run from Replit shell: cd ~/workspace && bash proverank_auth_redesign_v1.sh
set -e

cd ~/workspace/frontend 2>/dev/null || cd ~/workspace 2>/dev/null || { echo "❌ workspace not found — run this from ~/workspace"; exit 1; }

echo "🔎 Locating files via grep..."
AUTHSHELL=$(grep -rl "export default function AuthShell" --include="*.tsx" . 2>/dev/null | head -1)
LOGINPAGE=$(grep -rl "loginPassword" --include="*.tsx" . 2>/dev/null | head -1)
FORGOTPAGE=$(grep -rl "resetPassword" --include="*.tsx" . 2>/dev/null | grep -v -i "AuthShell" | head -1)
REGISTERPAGE=$(grep -rl "verifyOtp" --include="*.tsx" . 2>/dev/null | head -1)

echo "AuthShell     : ${AUTHSHELL:-NOT FOUND}"
echo "Login page    : ${LOGINPAGE:-NOT FOUND}"
echo "Forgot page   : ${FORGOTPAGE:-NOT FOUND}"
echo "Register page : ${REGISTERPAGE:-NOT FOUND}"

if [ -z "$AUTHSHELL" ] || [ -z "$LOGINPAGE" ] || [ -z "$FORGOTPAGE" ] || [ -z "$REGISTERPAGE" ]; then
  echo "❌ One or more files not found. Aborting — no changes made. Please share correct paths."
  exit 1
fi

TS=$(date +%s)
cp "$AUTHSHELL" "${AUTHSHELL}.bak_${TS}"
cp "$LOGINPAGE" "${LOGINPAGE}.bak_${TS}"
cp "$FORGOTPAGE" "${FORGOTPAGE}.bak_${TS}"
cp "$REGISTERPAGE" "${REGISTERPAGE}.bak_${TS}"
echo "✅ Backups created (.bak_${TS})"

# ── 1) AuthShell.tsx ──────────────────────────────────────────────
cat > "$AUTHSHELL" << 'EOF_AUTHSHELL'
'use client'
import PRLogo from '@/components/PRLogo'
import { ReactNode } from 'react'

// ── Design Tokens — Ultra Premium Neon Blue (matches globals.css --primary #4D9FFF / --bg-dark #000A18) ──
export const T = {
  bg: 'linear-gradient(165deg,#000A18 0%,#020F22 45%,#00050D 100%)',
  panel: 'linear-gradient(180deg, rgba(0,20,38,0.95), rgba(0,8,18,0.98))',
  pri: '#4D9FFF',
  priDark: '#0066CC',
  cyan: '#00D4FF',
  card: 'rgba(0,20,38,0.72)',
  cardBorder: 'rgba(77,159,255,0.22)',
  txt: '#E8F4FF',
  sub: '#6B8BAF',
  dark: '#031320',
  success: '#00C48C',
  danger: '#FF4757',
  inputBg: 'rgba(0,14,28,0.85)',
  inputBorder: '#002D55',
}

export const inp: any = {
  width: '100%', padding: '12px 14px', background: T.inputBg,
  border: `1.5px solid ${T.inputBorder}`, borderRadius: 10, color: T.txt,
  fontSize: 14, fontFamily: 'Inter,sans-serif', outline: 'none',
  boxSizing: 'border-box', transition: 'border-color .2s, box-shadow .2s',
}

export function inpErr(hasError: boolean): any {
  return { ...inp, border: hasError ? `1.5px solid ${T.danger}` : inp.border }
}

const EXAM_BADGES = ['NEET', 'JEE', 'CUET', 'SSC', 'CLAT', 'BANK']

interface Step { label: string }
interface Props { steps?: Step[]; current?: number; children: ReactNode }

export default function AuthShell({ steps = [], current = 0, children }: Props) {
  const hasSteps = steps.length > 1
  return (
    <div style={{ minHeight: '100vh', background: T.bg, fontFamily: 'Inter,sans-serif', position: 'relative', overflowX: 'hidden' }}>
      <style>{`
        @keyframes glowPulse{0%,100%{filter:drop-shadow(0 0 6px #4D9FFF66)}50%{filter:drop-shadow(0 0 18px #00D4FFaa)}}
        @keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @keyframes confettiFall{0%{transform:translateY(-20px) rotate(0deg);opacity:1}100%{transform:translateY(420px) rotate(360deg);opacity:0}}
        @keyframes radarSpin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes bgPulse{0%,100%{opacity:.55;transform:scale(1)}50%{opacity:.85;transform:scale(1.08)}}
        @keyframes badgeFade{from{opacity:0;transform:scale(.6)}to{opacity:1;transform:scale(1)}}
        *{box-sizing:border-box}
        .pr-input:focus{border-color:${T.pri} !important;box-shadow:0 0 0 3px rgba(77,159,255,0.16)}
        .pr-btn{transition:transform .18s ease, box-shadow .18s ease, filter .18s ease}
        .pr-btn:hover:not(:disabled){transform:translateY(-1px);filter:brightness(1.07)}
        .pr-btn:active:not(:disabled){transform:translateY(0)}
        a:focus-visible, button:focus-visible{outline:2px solid ${T.cyan};outline-offset:2px}
        .auth-mobile-bar{display:none}
        @media (max-width: 860px){
          .auth-left-panel, .auth-step-rail{display:none !important}
          .auth-mobile-bar{display:flex !important}
          .auth-row{flex-direction:column !important}
          .auth-form-area{padding:20px 16px 48px !important}
        }
        @media (prefers-reduced-motion: reduce){
          *{animation:none !important;transition:none !important}
        }
      `}</style>

      {/* ── Ambient background: OMR bubble-grid texture + soft glow blobs (fixed, decorative) ── */}
      <div aria-hidden style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none', opacity: 0.55, backgroundImage: 'radial-gradient(rgba(77,159,255,0.14) 1px, transparent 1.5px)', backgroundSize: '26px 26px' }} />
      <div aria-hidden style={{ position: 'fixed', top: '-12%', left: '-10%', width: '48%', height: '48%', borderRadius: '50%', background: 'radial-gradient(circle, rgba(77,159,255,0.20), transparent 70%)', filter: 'blur(60px)', zIndex: 0, pointerEvents: 'none', animation: 'bgPulse 9s ease-in-out infinite' }} />
      <div aria-hidden style={{ position: 'fixed', bottom: '-16%', right: '-10%', width: '52%', height: '52%', borderRadius: '50%', background: 'radial-gradient(circle, rgba(0,212,255,0.16), transparent 70%)', filter: 'blur(70px)', zIndex: 0, pointerEvents: 'none', animation: 'bgPulse 9s ease-in-out infinite 3s' }} />

      {/* Mobile sticky top bar — logo + step dots */}
      <div className="auth-mobile-bar" style={{ position: 'sticky', top: 0, zIndex: 30, height: 54, alignItems: 'center', justifyContent: 'space-between', padding: '0 16px', background: 'rgba(0,8,16,0.92)', backdropFilter: 'blur(16px)', borderBottom: `1px solid ${T.cardBorder}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ animation: 'glowPulse 3s ease-in-out infinite' }}><PRLogo size={24} /></div>
          <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 14, fontWeight: 700, color: T.pri }}>ProveRank</span>
        </div>
        {hasSteps && (
          <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
            {steps.map((_, i) => (
              <div key={i} style={{ width: i === current ? 16 : 6, height: 6, borderRadius: 3, background: i <= current ? `linear-gradient(90deg,${T.pri},${T.cyan})` : 'rgba(107,139,175,0.28)', transition: 'all .3s' }} />
            ))}
          </div>
        )}
      </div>

      {/* Desktop: 3-column row — branding | step rail | form */}
      <div className="auth-row" style={{ display: 'flex', minHeight: '100vh', position: 'relative', zIndex: 1 }}>

        <div className="auth-left-panel" style={{ width: 236, flexShrink: 0, background: T.panel, borderRight: `1px solid ${T.cardBorder}`, padding: '38px 22px', display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div style={{ animation: 'glowPulse 3s ease-in-out infinite', width: 'fit-content' }}>
            <PRLogo size={38} />
          </div>
          <div>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 21, fontWeight: 700, color: T.txt, lineHeight: 1.25, letterSpacing: 0.2 }}>ProveRank</div>
            <div style={{ fontSize: 11, color: T.pri, marginTop: 3, fontWeight: 600, letterSpacing: 0.5 }}>Rise to the Top</div>
          </div>

          {/* Eyebrow — multi-exam positioning */}
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, width: 'fit-content', padding: '4px 10px', borderRadius: 20, background: 'rgba(0,212,255,0.08)', border: '1px solid rgba(0,212,255,0.3)' }}>
            <span style={{ width: 5, height: 5, borderRadius: '50%', background: T.cyan, boxShadow: `0 0 6px ${T.cyan}` }} />
            <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: 0.8, color: T.cyan, textTransform: 'uppercase' }}>Multi-Exam Platform</span>
          </div>

          {/* Signature — radar ring of competitive exams */}
          <div style={{ position: 'relative', width: 132, height: 132, margin: '6px auto 2px' }}>
            <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'conic-gradient(from 0deg, rgba(0,212,255,0.4), transparent 28%, transparent 100%)', animation: 'radarSpin 7s linear infinite', filter: 'blur(1px)' }} />
            <div style={{ position: 'absolute', inset: 14, borderRadius: '50%', border: '1px dashed rgba(77,159,255,0.3)' }} />
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', animation: 'glowPulse 3s ease-in-out infinite' }}>
              <PRLogo size={26} />
            </div>
            {EXAM_BADGES.map((b, i) => {
              const angle = -90 + i * 60
              return (
                <div key={b} style={{
                  position: 'absolute', top: '50%', left: '50%',
                  transform: `rotate(${angle}deg) translate(52px) rotate(${-angle}deg) translate(-50%,-50%)`,
                  fontSize: 8.5, fontWeight: 800, letterSpacing: 0.3, padding: '3px 6px', borderRadius: 20,
                  background: 'rgba(0,10,22,0.92)', border: '1px solid rgba(77,159,255,0.4)', color: '#8FC3FF',
                  whiteSpace: 'nowrap', animation: `badgeFade .5s ease ${i * 0.08}s backwards`,
                }}>{b}</div>
              )
            })}
          </div>

          <div style={{ height: 1, background: T.cardBorder, margin: '2px 0' }} />
          {[
            ['🎯', 'Multi Exam Platform'],
            ['🤖', 'AI Proctoring'],
            ['👨‍🏫', 'Designed By Experts'],
            ['📊', 'Deep AI Analytics'],
            ['🏆', 'All India Ranking'],
            ['⚡', 'Instant Results'],
            ['📱', 'Mobile Friendly'],
          ].map(([ic, l]) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ width: 24, height: 24, borderRadius: 7, background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.22)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, flexShrink: 0 }}>{ic}</span>
              <span style={{ fontSize: 11, color: T.txt, fontWeight: 500 }}>{l}</span>
            </div>
          ))}
        </div>

        {hasSteps && (
          <div className="auth-step-rail" style={{ width: 168, flexShrink: 0, padding: '38px 16px', display: 'flex', flexDirection: 'column', gap: 4, borderRight: `1px solid ${T.cardBorder}` }}>
            {steps.map((s, i) => {
              const active = i === current, done = i < current
              return (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '9px 8px', borderRadius: 10, background: active ? 'rgba(77,159,255,0.1)' : 'transparent' }}>
                  <div style={{
                    width: 22, height: 22, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, flexShrink: 0,
                    background: done ? `linear-gradient(135deg,${T.pri},${T.cyan})` : active ? 'rgba(77,159,255,0.2)' : 'rgba(107,139,175,0.1)',
                    color: done ? T.dark : active ? T.pri : T.sub,
                    border: active ? `1.5px solid ${T.pri}` : '1px solid rgba(107,139,175,0.25)',
                  }}>
                    {done ? '✓' : i + 1}
                  </div>
                  <span style={{ fontSize: 11, color: active ? T.txt : T.sub, fontWeight: active ? 700 : 400 }}>{s.label}</span>
                </div>
              )
            })}
          </div>
        )}

        <div className="auth-form-area" style={{ flex: 1, display: 'flex', justifyContent: 'center', padding: '44px 20px', overflowY: 'auto' }}>
          <div style={{ width: '100%', maxWidth: 420, animation: 'fadeIn .5s ease' }}>
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
EOF_AUTHSHELL
echo "✅ AuthShell.tsx updated: $AUTHSHELL"

# ── 2) Login page.tsx ────────────────────────────────────────────
cat > "$LOGINPAGE" << 'EOF_LOGIN'
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
      <div style={{ textAlign: 'center', marginBottom: 22 }}>
        <div style={{ display: 'inline-block', padding: '3px 12px', borderRadius: 20, background: 'rgba(0,212,255,0.08)', border: '1px solid rgba(0,212,255,0.3)', fontSize: 9, fontWeight: 700, letterSpacing: 1, color: T.cyan, textTransform: 'uppercase', marginBottom: 10 }}>Secure Access</div>
        <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 25, fontWeight: 700, color: T.txt, marginBottom: 4, letterSpacing: 0.2 }}>Welcome Back</div>
        <div style={{ fontSize: 12, color: T.sub }}>Login to continue your exam journey</div>
      </div>

      <div style={{ position: 'relative', overflow: 'hidden', background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 22, padding: '30px 24px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 20px 60px rgba(0,6,16,0.6)' }}>
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg,${T.pri},${T.cyan})` }} />

        {/* F35.2 + F35.4 — 2-Tab pill system */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 22, borderRadius: 14, padding: 4, background: 'rgba(0,10,20,0.6)', border: `1px solid ${T.cardBorder}` }}>
          {([['password', '🔑 Password'], ['otp', '📱 OTP']] as const).map(([t, l]) => (
            <button key={t} onClick={() => { setTab(t); clearAll() }} className="pr-btn" style={{
              flex: 1, padding: '10px 4px', borderRadius: 10, border: 'none', cursor: 'pointer',
              fontFamily: 'Inter,sans-serif', fontSize: 13, fontWeight: tab === t ? 700 : 500,
              background: tab === t ? `linear-gradient(135deg,${T.pri},${T.cyan})` : 'transparent',
              color: tab === t ? T.dark : T.sub,
              boxShadow: tab === t ? '0 4px 14px rgba(77,159,255,0.35)' : 'none',
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
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} onKeyDown={e => e.key === 'Enter' && loginPassword()} style={inpErr(!emailValid)} className="pr-input" placeholder="your@email.com" />
              </div>
              <div>
                <label style={lbl}>Password</label>
                {/* F35.10 — Show/Hide password eye icon */}
                <div style={{ position: 'relative' }}>
                  <input type={showPass ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} onKeyDown={e => e.key === 'Enter' && loginPassword()} style={{ ...inp, paddingRight: 42 }} className="pr-input" placeholder="••••••••" />
                  <button type="button" onClick={() => setShowPass(p => !p)} style={eyeBtn}>{showPass ? '🙈' : '👁️'}</button>
                </div>
              </div>
            </div>
            {/* F35.3 + F35.17 + F35.18 — Forgot Password link → separate page */}
            <div style={{ textAlign: 'right', marginBottom: 16 }}>
              <a href="/forgot-password" style={{ color: T.pri, fontSize: 12, fontWeight: 600, textDecoration: 'underline' }}>Forgot Password? →</a>
            </div>
            <button onClick={loginPassword} disabled={loading || !email || !password} className="pr-btn" style={btnPri(loading || !email || !password)}>{loading ? 'Logging in...' : 'Login →'}</button>
          </>
        )}

        {tab === 'otp' && (
          <>
            <div style={{ marginBottom: 13 }}>
              <label style={lbl}>Email</label>
              <input type="email" value={otpEmail} onChange={e => setOtpEmail(e.target.value)} style={inp} className="pr-input" placeholder="your@email.com" disabled={otpSent} />
            </div>
            {!otpSent ? (
              <button onClick={sendLoginOtp} disabled={loading || !otpEmail} className="pr-btn" style={btnPri(loading || !otpEmail)}>{loading ? 'Sending OTP...' : 'Send OTP →'}</button>
            ) : (
              <>
                <div style={{ marginBottom: 13 }}>
                  <label style={lbl}>Enter OTP</label>
                  <input value={loginOtp} onChange={e => setLoginOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} style={{ ...inp, fontSize: 24, fontWeight: 900, textAlign: 'center', letterSpacing: 10, fontFamily: 'monospace' }} className="pr-input" placeholder="000000" maxLength={6} inputMode="numeric" />
                  <div style={{ fontSize: 11, color: T.sub, marginTop: 5, textAlign: 'center' }}>OTP sent to {otpEmail} · <button onClick={sendLoginOtp} style={linkBtn}>Resend</button></div>
                </div>
                <button onClick={loginWithOtp} disabled={loading || loginOtp.length !== 6} className="pr-btn" style={btnSuc(loading || loginOtp.length !== 6)}>{loading ? 'Verifying...' : '✅ Login with OTP →'}</button>
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
const errBox: any = { background: 'rgba(255,71,87,.12)', border: `1px solid rgba(255,71,87,.3)`, borderRadius: 9, padding: '10px 14px', fontSize: 13, color: T.danger, marginBottom: 14, textAlign: 'center' }
const okBox: any = { background: 'rgba(0,196,140,.1)', border: `1px solid rgba(0,196,140,.3)`, borderRadius: 9, padding: '10px 14px', fontSize: 13, color: T.success, marginBottom: 14, textAlign: 'center' }
function btnPri(disabled: boolean): any { return { width: '100%', padding: '13px', background: `linear-gradient(135deg,${T.pri},${T.cyan})`, color: T.dark, border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1, boxShadow: '0 4px 16px rgba(77,159,255,0.35)' } }
function btnSuc(disabled: boolean): any { return { width: '100%', padding: '13px', background: disabled ? 'rgba(107,139,175,.15)' : `linear-gradient(135deg,${T.success},#00a87a)`, color: disabled ? T.sub : T.dark, border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1 } }
EOF_LOGIN
echo "✅ Login page updated: $LOGINPAGE"

# ── 3) Forgot Password page ──────────────────────────────────────
cat > "$FORGOTPAGE" << 'EOF_FORGOT'
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
      <div style={{ textAlign: 'center', marginBottom: 22 }}>
        <div style={{ display: 'inline-block', padding: '3px 12px', borderRadius: 20, background: 'rgba(0,212,255,0.08)', border: '1px solid rgba(0,212,255,0.3)', fontSize: 9, fontWeight: 700, letterSpacing: 1, color: T.cyan, textTransform: 'uppercase', marginBottom: 10 }}>Account Recovery</div>
        <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 23, fontWeight: 700, color: T.txt, letterSpacing: 0.2 }}>Reset Password</div>
        <div style={{ fontSize: 12, color: T.sub, marginTop: 4 }}>We&apos;ll help you get back in</div>
      </div>

      <div style={{ position: 'relative', overflow: 'hidden', background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 22, padding: '30px 24px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 20px 60px rgba(0,6,16,0.6)' }}>
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg,${T.pri},${T.cyan})` }} />

        {error && <div style={errBox}>{error}</div>}
        {msg && step !== 'done' && <div style={okBox}>{msg}</div>}

        {step === 'email' && (
          <>
            <p style={{ fontSize: 13, color: T.sub, marginBottom: 16, textAlign: 'center' }}>Enter your registered email — we&apos;ll send a reset OTP.</p>
            <div style={{ marginBottom: 16 }}>
              <label style={lbl}>Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} style={inp} className="pr-input" placeholder="your@email.com" />
            </div>
            <button onClick={sendOtp} disabled={loading || !email} className="pr-btn" style={btnPri(loading || !email)}>{loading ? 'Sending OTP...' : 'Send Reset OTP →'}</button>
          </>
        )}

        {step === 'otp' && (
          <>
            <p style={{ fontSize: 13, color: T.sub, marginBottom: 16, textAlign: 'center' }}>OTP sent to <span style={{ color: T.pri, fontWeight: 600 }}>{email}</span></p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 6 }}>
              <div>
                <label style={lbl}>OTP</label>
                <input value={otp} onChange={e => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} style={{ ...inp, fontSize: 22, fontWeight: 900, textAlign: 'center', letterSpacing: 10, fontFamily: 'monospace' }} className="pr-input" placeholder="000000" maxLength={6} inputMode="numeric" />
              </div>
              <div>
                <label style={lbl}>New Password</label>
                <div style={{ position: 'relative' }}>
                  <input type={showPass ? 'text' : 'password'} value={newPass} onChange={e => setNewPass(e.target.value)} style={{ ...inp, paddingRight: 42 }} className="pr-input" placeholder="Min 6 characters" />
                  <button type="button" onClick={() => setShowPass(p => !p)} style={eyeBtn}>{showPass ? '🙈' : '👁️'}</button>
                </div>
              </div>
              <div>
                <label style={lbl}>Confirm Password</label>
                <input type={showPass ? 'text' : 'password'} value={confirmPass} onChange={e => setConfirmPass(e.target.value)} style={inpErr(!passMatch)} className="pr-input" placeholder="Re-enter password" />
                {!passMatch && <div style={{ fontSize: 11, color: T.danger, marginTop: 5 }}>Passwords do not match</div>}
                {confirmPass && passMatch && newPass.length >= 6 && <div style={{ fontSize: 11, color: T.success, marginTop: 5 }}>✅ Passwords match</div>}
              </div>
            </div>
            <button onClick={resetPassword} disabled={loading || otp.length !== 6 || newPass.length < 6 || !passMatch} className="pr-btn" style={btnSuc(loading || otp.length !== 6 || newPass.length < 6 || !passMatch)}>{loading ? 'Resetting...' : '🔑 Reset Password →'}</button>
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
const errBox: any = { background: 'rgba(255,71,87,.12)', border: `1px solid rgba(255,71,87,.3)`, borderRadius: 9, padding: '10px 14px', fontSize: 13, color: T.danger, marginBottom: 14, textAlign: 'center' }
const okBox: any = { background: 'rgba(0,196,140,.1)', border: `1px solid rgba(0,196,140,.3)`, borderRadius: 9, padding: '10px 14px', fontSize: 13, color: T.success, marginBottom: 14, textAlign: 'center' }
function btnPri(disabled: boolean): any { return { width: '100%', padding: '13px', background: `linear-gradient(135deg,${T.pri},${T.cyan})`, color: T.dark, border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1, boxShadow: '0 4px 16px rgba(77,159,255,0.35)' } }
function btnSuc(disabled: boolean): any { return { width: '100%', padding: '13px', background: disabled ? 'rgba(107,139,175,.15)' : `linear-gradient(135deg,${T.success},#00a87a)`, color: disabled ? T.sub : T.dark, border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1 } }
EOF_FORGOT
echo "✅ Forgot Password page updated: $FORGOTPAGE"

# ── 4) Register page ─────────────────────────────────────────────
cat > "$REGISTERPAGE" << 'EOF_REGISTER'
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
  const [showTermsModal, setShowTermsModal] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')
  const [resending, setResend] = useState(false)
  const [resendCooldown, setResendCooldown] = useState(0)
  const [regClosed, setRegClosed] = useState(false)

  // Registration status check on mount
  useEffect(() => {
    fetch(`${API}/api/auth/registration-status`)
      .then(r => r.json())
      .then(d => { if (!d.open) setRegClosed(true) })
      .catch(() => {})
  }, [])

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

      {/* Reg Closed Banner */}
      {regClosed && step === 'details' && (
        <div style={{ position: 'relative', background: 'rgba(8,3,3,0.97)', border: `2px solid rgba(255,71,87,0.35)`, borderRadius: 20, padding: '38px 22px', textAlign: 'center', backdropFilter: 'blur(20px)', boxShadow: '0 20px 60px rgba(0,0,0,0.7)', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg,${T.danger},#FF8C42)` }} />
          <div style={{ fontSize: 52, marginBottom: 12 }}>🔒</div>
          <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: '#FF8FA0', margin: '0 0 10px' }}>Registration Temporarily Closed</h2>
          <div style={{ background: 'rgba(255,71,87,0.08)', border: `1px solid rgba(255,71,87,0.25)`, borderRadius: 10, padding: '12px 16px', marginBottom: 16 }}>
            <p style={{ fontSize: 13, color: '#FFB3BD', fontWeight: 600, margin: 0, lineHeight: 1.6 }}>
              📢 Registration is currently closed. We&apos;ll be back soon. Please contact Admin for access.
            </p>
          </div>
          <p style={{ fontSize: 13, color: 'rgba(232,244,255,0.45)', marginBottom: 22, lineHeight: 1.65 }}>
            New student registrations are temporarily paused.<br />Existing students can still login normally.
          </p>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center', flexWrap: 'wrap' }}>
            <a href="/login" className="pr-btn" style={{ padding: '11px 24px', background: `linear-gradient(135deg,${T.pri},${T.cyan})`, color: T.dark, borderRadius: 11, fontWeight: 700, fontSize: 13, textDecoration: 'none', display: 'inline-block' }}>Login →</a>
            <a href="mailto:admin@proverank.com" style={{ padding: '11px 20px', background: 'rgba(255,71,87,0.12)', border: `1px solid rgba(255,71,87,0.3)`, color: '#FF9FAC', borderRadius: 11, fontWeight: 600, fontSize: 13, textDecoration: 'none', display: 'inline-block' }}>📧 Contact Admin</a>
          </div>
        </div>
      )}

      {!regClosed && step === 'details' && (
        <div style={{ position: 'relative', overflow: 'hidden', background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 22, padding: '32px 26px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 20px 60px rgba(0,6,16,0.6)' }}>
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg,${T.pri},${T.cyan})` }} />
          <div style={{ textAlign: 'center', marginBottom: 22 }}>
            <div style={{ display: 'inline-block', padding: '3px 12px', borderRadius: 20, background: 'rgba(0,212,255,0.08)', border: '1px solid rgba(0,212,255,0.3)', fontSize: 9, fontWeight: 700, letterSpacing: 1, color: T.cyan, textTransform: 'uppercase', marginBottom: 10 }}>New Student</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.txt, margin: '0 0 6px', letterSpacing: 0.2 }}>Create Account</h2>
            <p style={{ fontSize: 13, color: T.sub, margin: 0 }}>Join ProveRank — Rise to the Top</p>
          </div>
          {error && <div style={errBox}>{error}</div>}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 13 }}>
            <div>
              <label style={lbl}>Full Name *</label>
              <input value={name} onChange={e => setName(e.target.value)} style={inp} className="pr-input" placeholder="Your full name" />
            </div>
            <div>
              <label style={lbl}>Email *</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} style={inpErr(!emailValid)} className="pr-input" placeholder="your@email.com" />
              {email && emailValid && (
                <div style={{ fontSize: 11, marginTop: 5, color: emailCheck.checking ? T.sub : emailCheck.available === false ? T.danger : emailCheck.available === true ? T.success : T.sub }}>
                  {emailCheck.checking ? 'Checking availability...' : emailCheck.available === false ? '❌ ' + (emailCheck.msg || 'Already registered') : emailCheck.available === true ? '✅ Email available' : ''}
                </div>
              )}
              {email && !emailValid && <div style={{ fontSize: 11, color: T.danger, marginTop: 5 }}>Invalid email format</div>}
            </div>
            <div>
              <label style={lbl}>Password *</label>
              <div style={{ position: 'relative' }}>
                <input type={showPass ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} style={{ ...inp, paddingRight: 42 }} className="pr-input" placeholder="Min 6 characters" />
                <button type="button" onClick={() => setShowPass(p => !p)} style={eyeBtn}>{showPass ? '🙈' : '👁️'}</button>
              </div>
            </div>
            <div>
              <label style={lbl}>Phone (optional)</label>
              <input value={phone} onChange={e => setPhone(e.target.value)} style={inpErr(!phoneValid)} className="pr-input" placeholder="+91 XXXXXXXXXX" />
              {phone && !phoneValid && <div style={{ fontSize: 11, color: T.danger, marginTop: 5 }}>Format: +91 followed by 10 digits</div>}
            </div>
          </div>

          {/* F35.12 — T&C checkbox — must read terms first */}
          <div style={{ marginTop: 18, padding: '12px 14px', background: 'rgba(0,10,20,0.6)', border: `1px solid ${agreedTnc ? T.pri : T.cardBorder}`, borderRadius: 10, transition: 'border-color .3s' }}>
            {!agreedTnc ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 18 }}>📋</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, color: T.txt, marginBottom: 4 }}>You must read Terms &amp; Conditions before proceeding</div>
                  <button
                    onClick={() => setShowTermsModal(true)}
                    style={{ background: 'none', border: 'none', color: T.pri, fontSize: 12, fontWeight: 700, textDecoration: 'underline', cursor: 'pointer', padding: 0, fontFamily: 'Inter,sans-serif' }}
                  >
                    📖 Read Terms &amp; Conditions →
                  </button>
                </div>
              </div>
            ) : (
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
                <div style={{ width: 20, height: 20, borderRadius: 5, background: `linear-gradient(135deg,${T.pri},${T.cyan})`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <span style={{ color: T.dark, fontSize: 12, fontWeight: 900 }}>✓</span>
                </div>
                <span style={{ fontSize: 12, color: T.txt, fontWeight: 600 }}>✅ Terms &amp; Conditions read and accepted</span>
                <button onClick={() => setAgreedTnc(false)} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: T.danger, fontSize: 11, cursor: 'pointer', fontFamily: 'Inter,sans-serif' }}>Undo</button>
              </label>
            )}
          </div>

          <button onClick={register} disabled={loading || !canSubmit} className="pr-btn" style={{ ...btnPri(loading || !canSubmit), marginTop: 20 }}>{loading ? 'Creating Account...' : 'Create Account →'}</button>
          <div style={{ textAlign: 'center', marginTop: 16, fontSize: 13, color: T.sub }}>Already have an account?{' '}<a href="/login" style={{ color: T.pri, fontWeight: 600, textDecoration: 'none' }}>Login →</a></div>
        </div>
      )}

      {step === 'otp' && (
        <div style={{ position: 'relative', overflow: 'hidden', background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 22, padding: '32px 26px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 20px 60px rgba(0,6,16,0.6)' }}>
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg,${T.pri},${T.cyan})` }} />
          <div style={{ textAlign: 'center', marginBottom: 22 }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>📧</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.txt, margin: '0 0 6px' }}>Verify Your Email</h2>
            <p style={{ fontSize: 13, color: T.sub, margin: 0 }}>OTP sent to <span style={{ color: T.pri, fontWeight: 600 }}>{email}</span></p>
          </div>
          {error && <div style={errBox}>{error}</div>}
          {msg && <div style={okBox}>{msg}</div>}
          <div style={{ marginBottom: 18 }}>
            <label style={{ ...lbl, textAlign: 'center' }}>Enter 6-Digit OTP</label>
            <input value={otp} onChange={e => { setOtp(e.target.value.replace(/\D/g, '').slice(0, 6)); setError('') }} style={{ ...inp, fontSize: 28, fontWeight: 900, textAlign: 'center', letterSpacing: 12, fontFamily: 'monospace', padding: '16px' }} className="pr-input" placeholder="000000" maxLength={6} inputMode="numeric" />
          </div>
          <button onClick={verifyOtp} disabled={loading || otp.length !== 6} className="pr-btn" style={btnSuc(loading || otp.length !== 6)}>{loading ? 'Verifying...' : '✅ Verify & Continue →'}</button>
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
        <div style={{ background: T.card, border: `1px solid ${T.cardBorder}`, borderRadius: 22, padding: '40px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 20px 60px rgba(0,6,16,0.6)', textAlign: 'center', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg,${T.pri},${T.cyan})` }} />
          {/* F35.14 — confetti burst */}
          {Array.from({ length: 24 }).map((_, i) => (
            <div key={i} style={{ position: 'absolute', top: -10, left: `${Math.random() * 100}%`, width: 7, height: 7, borderRadius: i % 2 === 0 ? '50%' : 2, background: [T.pri, T.cyan, T.success, '#fff'][i % 4], animation: `confettiFall ${1.4 + Math.random() * 1.2}s ease-in forwards`, animationDelay: `${Math.random() * 0.4}s` }} />
          ))}
          <div style={{ fontSize: 56, marginBottom: 14 }}>🎉</div>
          <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.txt, marginBottom: 8 }}>Welcome to ProveRank!</h2>
          <p style={{ fontSize: 13, color: T.sub }}>Redirecting to your dashboard...</p>
        </div>
      )}


      {/* ── Terms Modal ── */}
      {showTermsModal && (
        <div onClick={() => setShowTermsModal(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,2,6,0.88)', zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: 'rgba(0,12,24,0.98)', border: `1px solid ${T.cardBorder}`, borderRadius: 20, width: '100%', maxWidth: 520, maxHeight: '82vh', display: 'flex', flexDirection: 'column', backdropFilter: 'blur(24px)', boxShadow: '0 24px 70px rgba(0,0,0,0.75)', overflow: 'hidden' }}>
            <div style={{ height: 3, background: `linear-gradient(90deg,${T.pri},${T.cyan})`, flexShrink: 0 }} />
            {/* Header */}
            <div style={{ padding: '16px 20px', borderBottom: `1px solid ${T.cardBorder}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0 }}>
              <div>
                <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, color: T.txt }}>Terms &amp; Conditions</div>
                <div style={{ fontSize: 10, color: T.pri, marginTop: 2 }}>Version 2.1 — Updated March 2026</div>
              </div>
              <button onClick={() => setShowTermsModal(false)} style={{ background: 'none', border: 'none', color: T.sub, cursor: 'pointer', fontSize: 22, lineHeight: 1, padding: 4 }}>✕</button>
            </div>
            {/* Scrollable content */}
            <div style={{ overflowY: 'auto', padding: '14px 20px', flex: 1 }}>
              {[
                ['1. Exam Rules & Conduct', 'Students must attempt exams in a quiet, well-lit environment. Any form of cheating, including using external resources, sharing questions, or impersonating another student, will result in immediate disqualification and permanent account ban.'],
                ['2. Privacy Policy', 'We collect your name, email, and exam data solely for platform operation. Webcam snapshots during proctoring are used only for AI-based monitoring and automatically deleted within 24 hours. We never share your data with third parties.'],
                ['3. Proctoring Policy', 'By starting any exam you consent to: (a) webcam access for AI facial monitoring, (b) tab-switch tracking, (c) IP logging. Three warnings result in automatic exam submission.'],
                ['4. Result & Ranking Policy', 'All India Ranks are based on score then time. Results are final unless an Answer Key Challenge is filed within 48 hours. Re-evaluation processed within 7 working days.'],
                ['5. Account & Access Policy', 'Each account is for individual use only. New device login automatically signs out previous device. Sharing credentials is prohibited.'],
                ['6. Refund & Payment Policy', 'All purchases are non-refundable once access is granted. Technical failure credits added to account. Disputes must be raised within 7 days.'],
                ['7. Data Security & AI Monitoring', 'All data is encrypted. Our AI analyses video in real-time without storing identity beyond the exam session. We never sell data to advertisers.'],
                ['8. Grievance Redressal', 'Contact support@proverank.com for complaints. We respond within 48 hours and resolve within 7 working days.'],
              ].map(([title, body]) => (
                <div key={title} style={{ marginBottom: 12, padding: '10px 14px', background: 'rgba(0,10,20,0.6)', borderRadius: 10, border: `1px solid ${T.cardBorder}` }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: T.txt, marginBottom: 5 }}>{title}</div>
                  <div style={{ fontSize: 11, color: T.sub, lineHeight: 1.7 }}>{body}</div>
                </div>
              ))}
            </div>
            {/* Accept button */}
            <div style={{ padding: '14px 20px', borderTop: `1px solid ${T.cardBorder}`, flexShrink: 0, display: 'flex', gap: 10 }}>
              <button onClick={() => { setAgreedTnc(true); setShowTermsModal(false); /* Bug3: session-only */ }}
                className="pr-btn"
                style={{ flex: 1, padding: '12px', background: `linear-gradient(135deg,${T.pri},${T.cyan})`, color: T.dark, border: 'none', borderRadius: 10, fontWeight: 700, fontSize: 13, cursor: 'pointer', fontFamily: 'Inter,sans-serif', boxShadow: '0 4px 16px rgba(77,159,255,0.35)' }}>
                ✓ I Accept All Terms
              </button>
              <button onClick={() => setShowTermsModal(false)}
                style={{ padding: '12px 18px', background: 'transparent', border: `1px solid ${T.cardBorder}`, color: T.sub, borderRadius: 10, cursor: 'pointer', fontSize: 13, fontFamily: 'Inter,sans-serif' }}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </AuthShell>
  )
}

const lbl: any = { fontSize: 11, color: T.pri, fontWeight: 600, display: 'block', marginBottom: 5, textTransform: 'uppercase', letterSpacing: .4 }
const eyeBtn: any = { position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, padding: 4 }
const linkBtn: any = { background: 'none', border: 'none', color: T.pri, fontSize: 11, cursor: 'pointer', fontFamily: 'Inter,sans-serif', fontWeight: 600, padding: 0 }
const backBtn: any = { width: '100%', marginTop: 14, padding: '8px', background: 'none', border: `1px solid ${T.cardBorder}`, borderRadius: 9, color: T.sub, cursor: 'pointer', fontSize: 12, fontFamily: 'Inter,sans-serif' }
const errBox: any = { background: 'rgba(255,71,87,.12)', border: `1px solid rgba(255,71,87,.3)`, borderRadius: 9, padding: '10px 14px', fontSize: 13, color: T.danger, marginBottom: 14, textAlign: 'center' }
const okBox: any = { background: 'rgba(0,196,140,.1)', border: `1px solid rgba(0,196,140,.3)`, borderRadius: 9, padding: '10px 14px', fontSize: 13, color: T.success, marginBottom: 14, textAlign: 'center' }
function btnPri(disabled: boolean): any { return { width: '100%', padding: '13px', background: `linear-gradient(135deg,${T.pri},${T.cyan})`, color: T.dark, border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1, boxShadow: '0 4px 16px rgba(77,159,255,0.35)' } }
function btnSuc(disabled: boolean): any { return { width: '100%', padding: '13px', background: disabled ? 'rgba(107,139,175,.15)' : `linear-gradient(135deg,${T.success},#00a87a)`, color: disabled ? T.sub : T.dark, border: 'none', borderRadius: 12, cursor: disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 14, fontFamily: 'Inter,sans-serif', opacity: disabled ? .6 : 1 } }
EOF_REGISTER
echo "✅ Register page updated: $REGISTERPAGE"

echo ""
echo "🎨 ProveRank Auth Redesign Applied — Ultra Premium Neon Blue theme"
echo "   Theme now matches globals.css design tokens (--primary #4D9FFF)"
echo "   Signature: multi-exam radar ring (NEET/JEE/CUET/SSC/CLAT/BANK) on left panel"
echo "   No logic/API/state changed — visuals + copy only."
echo ""
echo "▶ Next: cd ~/workspace/frontend && npm run dev   (then check /login /register /forgot-password)"
