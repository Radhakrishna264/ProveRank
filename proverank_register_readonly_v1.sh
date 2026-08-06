#!/bin/bash
# ProveRank — Register page: show fields in read-only mode + closed banner when registration is off
set -e

cd ~/workspace/frontend 2>/dev/null || cd ~/workspace 2>/dev/null || { echo "❌ workspace not found — run this from ~/workspace"; exit 1; }

echo "🔎 Locating register page via grep..."
REGISTERPAGE=$(grep -rl "verifyOtp" --include="*.tsx" . 2>/dev/null | head -1)
echo "Register page : ${REGISTERPAGE:-NOT FOUND}"

if [ -z "$REGISTERPAGE" ]; then
  echo "❌ Register page not found. Aborting — no changes made."
  exit 1
fi

TS=$(date +%s)
cp "$REGISTERPAGE" "${REGISTERPAGE}.bak_${TS}"
echo "✅ Backup created (.bak_${TS})"

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

      {step === 'details' && (
        <div style={{ position: 'relative', overflow: 'hidden', background: T.card, border: `1px solid ${regClosed ? 'rgba(255,71,87,0.3)' : T.cardBorder}`, borderRadius: 22, padding: '0 26px 26px', backdropFilter: 'blur(24px)', boxShadow: '0 20px 60px rgba(0,6,16,0.6)' }}>
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: regClosed ? `linear-gradient(90deg,${T.danger},#FF8C42)` : `linear-gradient(90deg,${T.pri},${T.cyan})` }} />

          {/* Registration Closed banner — sits above the (read-only) form, form stays visible */}
          {regClosed && (
            <div style={{ margin: '20px 0 22px', padding: '14px 16px', borderRadius: 14, background: 'rgba(255,71,87,0.08)', border: '1px solid rgba(255,71,87,0.28)' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                <span style={{ fontSize: 20, lineHeight: 1 }}>🔒</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700, color: '#FF8FA0', marginBottom: 3 }}>Registration Temporarily Closed</div>
                  <div style={{ fontSize: 12, color: '#FFB3BD', lineHeight: 1.55 }}>New student registrations are paused — form below is view-only. Existing students can still <a href="/login" style={{ color: '#FFB3BD', fontWeight: 700, textDecoration: 'underline' }}>login</a>, or <a href="mailto:admin@proverank.com" style={{ color: '#FFB3BD', fontWeight: 700, textDecoration: 'underline' }}>contact Admin</a> for access.</div>
                </div>
              </div>
            </div>
          )}

          <div style={{ textAlign: 'center', marginBottom: 22, paddingTop: regClosed ? 0 : 32 }}>
            <div style={{ display: 'inline-block', padding: '3px 12px', borderRadius: 20, background: 'rgba(0,212,255,0.08)', border: '1px solid rgba(0,212,255,0.3)', fontSize: 9, fontWeight: 700, letterSpacing: 1, color: T.cyan, textTransform: 'uppercase', marginBottom: 10 }}>New Student</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.txt, margin: '0 0 6px', letterSpacing: 0.2 }}>Create Account</h2>
            <p style={{ fontSize: 13, color: T.sub, margin: 0 }}>Join ProveRank — Rise to the Top</p>
          </div>
          {error && <div style={errBox}>{error}</div>}

          {/* Fields — disabled/read-only whenever registration is closed */}
          <fieldset disabled={regClosed} style={{ border: 'none', margin: 0, padding: 0, opacity: regClosed ? 0.5 : 1, transition: 'opacity .25s' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 13 }}>
              <div>
                <label style={lbl}>Full Name *</label>
                <input value={name} onChange={e => setName(e.target.value)} style={{ ...inp, cursor: regClosed ? 'not-allowed' : 'text' }} className="pr-input" placeholder="Your full name" readOnly={regClosed} />
              </div>
              <div>
                <label style={lbl}>Email *</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} style={{ ...inpErr(!emailValid), cursor: regClosed ? 'not-allowed' : 'text' }} className="pr-input" placeholder="your@email.com" readOnly={regClosed} />
                {!regClosed && email && emailValid && (
                  <div style={{ fontSize: 11, marginTop: 5, color: emailCheck.checking ? T.sub : emailCheck.available === false ? T.danger : emailCheck.available === true ? T.success : T.sub }}>
                    {emailCheck.checking ? 'Checking availability...' : emailCheck.available === false ? '❌ ' + (emailCheck.msg || 'Already registered') : emailCheck.available === true ? '✅ Email available' : ''}
                  </div>
                )}
                {!regClosed && email && !emailValid && <div style={{ fontSize: 11, color: T.danger, marginTop: 5 }}>Invalid email format</div>}
              </div>
              <div>
                <label style={lbl}>Password *</label>
                <div style={{ position: 'relative' }}>
                  <input type={showPass ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} style={{ ...inp, paddingRight: 42, cursor: regClosed ? 'not-allowed' : 'text' }} className="pr-input" placeholder="Min 6 characters" readOnly={regClosed} />
                  <button type="button" onClick={() => setShowPass(p => !p)} style={eyeBtn} disabled={regClosed}>{showPass ? '🙈' : '👁️'}</button>
                </div>
              </div>
              <div>
                <label style={lbl}>Phone (optional)</label>
                <input value={phone} onChange={e => setPhone(e.target.value)} style={{ ...inpErr(!phoneValid), cursor: regClosed ? 'not-allowed' : 'text' }} className="pr-input" placeholder="+91 XXXXXXXXXX" readOnly={regClosed} />
                {!regClosed && phone && !phoneValid && <div style={{ fontSize: 11, color: T.danger, marginTop: 5 }}>Format: +91 followed by 10 digits</div>}
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
                      disabled={regClosed}
                      style={{ background: 'none', border: 'none', color: T.pri, fontSize: 12, fontWeight: 700, textDecoration: 'underline', cursor: regClosed ? 'not-allowed' : 'pointer', padding: 0, fontFamily: 'Inter,sans-serif' }}
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
          </fieldset>

          <button onClick={register} disabled={loading || !canSubmit || regClosed} className="pr-btn" style={{ ...btnPri(loading || !canSubmit || regClosed), marginTop: 20 }}>{regClosed ? '🔒 Registration Closed' : loading ? 'Creating Account...' : 'Create Account →'}</button>
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
echo "   → When registration is OFF: all fields visible but read-only/disabled, red closed-banner on top."
echo "   → When registration is ON: form works exactly as before — no logic changed."
echo ""
echo "▶ Next: cd ~/workspace/frontend && npm run dev   (then check /register)"
