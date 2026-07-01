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
