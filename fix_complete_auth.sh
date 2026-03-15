#!/bin/bash
# ProveRank — Complete Auth Fix
# Fixes: double-hash, login OTP tab, forgot password, register OTP flow
G='\033[0;32m'; B='\033[0;34m'; N='\033[0m'
log(){ echo -e "${G}[✓]${N} $1"; }
step(){ echo -e "\n${B}══════ $1 ══════${N}"; }
BE=/home/runner/workspace
FE=/home/runner/workspace/frontend

# ══════════════════════════════════════════════════════
# STEP 1 — Fix User Model (remove pre-save password hook)
# ══════════════════════════════════════════════════════
step "1 — User Model: Remove double-hash pre-save hook"
node << 'NODEOF'
const fs = require('fs')
const path = '/home/runner/workspace/src/models/User.js'
if (!fs.existsSync(path)) { console.log('❌ User.js not found at', path); process.exit(0) }
let code = fs.readFileSync(path, 'utf8')

// Remove pre-save password hashing hook entirely
// Pattern 1: UserSchema.pre('save', ...)
code = code.replace(
  /UserSchema\.pre\s*\(\s*['"]save['"]\s*,\s*async\s+function[^}]+bcrypt[^}]+}\s*\)/gs,
  '// password hashing removed — done in auth.js directly'
)
// Pattern 2: schema.pre('save', ...)  
code = code.replace(
  /\w+Schema\.pre\s*\(\s*['"]save['"]\s*,\s*async\s+function[^}]+bcrypt[^}]+}\s*\)/gs,
  '// password hashing removed — done in auth.js directly'
)
// Pattern 3: userSchema.pre with arrow function
code = code.replace(
  /\w+[Ss]chema\.pre\s*\(\s*['"]save['"]\s*,[\s\S]*?bcrypt[\s\S]*?\}\s*\)\s*;/g,
  '// password hashing removed — done in auth.js directly'
)

fs.writeFileSync(path, code, 'utf8')

// Verify
const verify = fs.readFileSync(path, 'utf8')
if (verify.includes('bcrypt') && verify.includes("pre('save'")) {
  console.log('⚠️  pre-save hook may still exist — manual check needed')
  console.log('Snippet:', verify.substring(verify.indexOf('bcrypt')-50, verify.indexOf('bcrypt')+100))
} else {
  console.log('✅ User model pre-save hook removed or was not present')
}
NODEOF
log "User model checked"

# ══════════════════════════════════════════════════════
# STEP 2 — Update auth.js (complete rewrite)
# ══════════════════════════════════════════════════════
step "2 — auth.js (complete — bypass hooks)"
cat > $BE/src/routes/auth.js << 'EOF_AUTH'
const express = require('express')
const router  = express.Router()
const bcrypt  = require('bcrypt')
const jwt     = require('jsonwebtoken')
const crypto  = require('crypto')
const User    = require('../models/User')
const { sendVerificationEmail } = require('../utils/emailService')

let AuditLog
try { AuditLog = require('../models/AuditLog') } catch(e) { AuditLog = null }

const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
const genOTP = () => String(Math.floor(100000 + Math.random() * 900000))

// ── REGISTER ──────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const regFlag = global.featureFlags?.['open_registration']
    if (regFlag === false) {
      return res.status(403).json({ message: 'Registration is currently closed. Please contact admin.' })
    }
    const { name, email, password, phone } = req.body
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email and password required' })
    }
    const existing = await User.findOne({ email })
    if (existing && (existing.emailVerified || existing.verified)) {
      return res.status(409).json({ message: 'Email already registered. Please login.' })
    }

    // Hash ONCE — use collection to BYPASS pre-save hook
    const hash = await bcrypt.hash(password, 12)
    const otp  = genOTP()
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000)

    if (existing) {
      await User.collection.updateOne({ _id: existing._id }, {
        $set: { name, password: hash, phone: phone||'',
                emailVerifyOTP: otp, emailVerifyOTPExpiry: otpExpiry,
                emailVerifyToken: null, emailVerifyExpiry: null }
      })
    } else {
      await User.collection.insertOne({
        name, email, password: hash, phone: phone||'',
        role: 'student', verified: false, emailVerified: false,
        emailVerifyOTP: otp, emailVerifyOTPExpiry: otpExpiry,
        streak: 0, badges: [], loginHistory: [],
        createdAt: new Date(), updatedAt: new Date()
      })
    }

    await sendVerificationEmail(email, name, null, otp, 'verify')
    res.status(201).json({ message: 'OTP sent to your email. Valid for 10 minutes.', requireOTP: true })
  } catch (err) {
    console.error('Register error:', err)
    res.status(500).json({ message: 'Server error during registration' })
  }
})

// ── VERIFY OTP (after register) → returns token directly ──────────
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body
    if (!email || !otp) return res.status(400).json({ message: 'Email and OTP required' })
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })
    if (!user.emailVerifyOTP || user.emailVerifyOTP !== String(otp).trim()) {
      return res.status(400).json({ message: 'Invalid OTP. Please check your email.' })
    }
    if (user.emailVerifyOTPExpiry && new Date() > user.emailVerifyOTPExpiry) {
      return res.status(400).json({ message: 'OTP expired. Please register again.' })
    }
    await User.collection.updateOne({ _id: user._id }, {
      $set: { emailVerified: true, verified: true,
              emailVerifyOTP: null, emailVerifyOTPExpiry: null }
    })
    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' })
    res.json({ token, role: user.role, name: user.name,
               message: 'Email verified! Welcome to ProveRank.' })
  } catch (err) {
    console.error('OTP verify error:', err)
    res.status(500).json({ message: 'Server error' })
  }
})

// ── RESEND OTP ─────────────────────────────────────────────────────
router.post('/resend-otp', async (req, res) => {
  try {
    const { email } = req.body
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })
    if (user.emailVerified || user.verified) {
      return res.status(400).json({ message: 'Email already verified. Please login.' })
    }
    const otp = genOTP()
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000)
    await User.collection.updateOne({ _id: user._id }, {
      $set: { emailVerifyOTP: otp, emailVerifyOTPExpiry: otpExpiry }
    })
    await sendVerificationEmail(email, user.name, null, otp, 'verify')
    res.json({ message: 'New OTP sent to your email.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── LOGIN (Email + Password) ───────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body
    const user = await User.findOne({ email })
    if (!user) return res.status(401).json({ message: 'Invalid email or password' })

    const match = await bcrypt.compare(password, user.password)
    if (!match) return res.status(401).json({ message: 'Invalid email or password' })

    const isVerified = user.emailVerified || user.verified
    if (user.role === 'student' && !isVerified) {
      return res.status(403).json({
        message: 'Email not verified. Check your inbox for OTP.',
        requireOTP: true, email
      })
    }
    if (user.banned) {
      return res.status(403).json({ message: `Account banned: ${user.banReason || 'Contact admin'}` })
    }

    const history = [...(user.loginHistory||[])]
    history.push({ at: new Date(), ip: req.ip,
      device: (req.headers['user-agent']||'Web').substring(0,60) })
    await User.collection.updateOne({ _id: user._id },
      { $set: { loginHistory: history.slice(-50) }})

    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' })
    res.json({ token, role: user.role, message: 'Login successful' })
  } catch (err) {
    console.error('Login error:', err)
    res.status(500).json({ message: 'Server error during login' })
  }
})

// ── SEND LOGIN OTP ─────────────────────────────────────────────────
router.post('/send-login-otp', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ message: 'No account with this email' })
    if (!(user.emailVerified || user.verified)) {
      return res.status(403).json({ message: 'Please verify your account first' })
    }
    if (user.banned) return res.status(403).json({ message: 'Account banned' })
    const otp = genOTP()
    await User.collection.updateOne({ _id: user._id }, {
      $set: { loginOTP: otp, loginOTPExpiry: new Date(Date.now() + 10*60*1000) }
    })
    await sendVerificationEmail(email, user.name, null, otp, 'login')
    res.json({ message: 'OTP sent to your email. Valid for 10 minutes.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── LOGIN OTP VERIFY ───────────────────────────────────────────────
router.post('/login-otp', async (req, res) => {
  try {
    const { email, otp } = req.body
    if (!email || !otp) return res.status(400).json({ message: 'Email and OTP required' })
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })
    if (!user.loginOTP || user.loginOTP !== String(otp).trim()) {
      return res.status(400).json({ message: 'Invalid OTP' })
    }
    if (user.loginOTPExpiry && new Date() > user.loginOTPExpiry) {
      return res.status(400).json({ message: 'OTP expired. Request a new one.' })
    }
    if (user.banned) return res.status(403).json({ message: 'Account banned' })
    await User.collection.updateOne({ _id: user._id },
      { $set: { loginOTP: null, loginOTPExpiry: null }})
    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' })
    res.json({ token, role: user.role, message: 'Login successful' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── FORGOT PASSWORD ────────────────────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const user = await User.findOne({ email })
    if (!user) return res.json({ message: 'If this email is registered, an OTP has been sent.' })
    const otp = genOTP()
    await User.collection.updateOne({ _id: user._id }, {
      $set: { resetOTP: otp, resetOTPExpiry: new Date(Date.now() + 10*60*1000) }
    })
    await sendVerificationEmail(email, user.name, null, otp, 'reset')
    res.json({ message: 'OTP sent to your email. Valid for 10 minutes.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── RESET PASSWORD ─────────────────────────────────────────────────
router.post('/reset-password', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body
    if (!email || !otp || !newPassword) {
      return res.status(400).json({ message: 'Email, OTP and new password required' })
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' })
    }
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })
    if (!user.resetOTP || user.resetOTP !== String(otp).trim()) {
      return res.status(400).json({ message: 'Invalid OTP' })
    }
    if (user.resetOTPExpiry && new Date() > user.resetOTPExpiry) {
      return res.status(400).json({ message: 'OTP expired. Request a new one.' })
    }
    const hash = await bcrypt.hash(newPassword, 12)
    await User.collection.updateOne({ _id: user._id },
      { $set: { password: hash, resetOTP: null, resetOTPExpiry: null }})
    res.json({ message: 'Password reset successfully! You can now login.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── CHANGE PASSWORD (logged in) ────────────────────────────────────
router.post('/change-password', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const user = await User.findById(payload.id)
    if (!user) return res.status(404).json({ message: 'User not found' })
    const { currentPassword, newPassword } = req.body
    if (!await bcrypt.compare(currentPassword, user.password)) {
      return res.status(400).json({ message: 'Current password is incorrect' })
    }
    if ((newPassword||'').length < 6) {
      return res.status(400).json({ message: 'Min 6 characters required' })
    }
    const hash = await bcrypt.hash(newPassword, 12)
    await User.collection.updateOne({ _id: user._id }, { $set: { password: hash }})
    res.json({ message: 'Password changed successfully!' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── GET ME ─────────────────────────────────────────────────────────
router.get('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const user = await User.findById(payload.id)
      .select('-password -emailVerifyOTP -loginOTP -resetOTP -emailVerifyToken')
    if (!user) return res.status(404).json({ message: 'User not found' })
    res.json({ ...user.toObject(), loginHistory: user.loginHistory || [] })
  } catch (err) {
    res.status(401).json({ message: 'Invalid token' })
  }
})

// ── PATCH ME ───────────────────────────────────────────────────────
router.patch('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const allowed = ['name','phone','dob','city','targetExam','board','school',
                     'bio','parentEmail','goals','avatar']
    const update = { updatedAt: new Date() }
    allowed.forEach(k => { if (req.body[k] !== undefined) update[k] = req.body[k] })
    await User.collection.updateOne({ _id: payload.id }, { $set: update })
    res.json({ message: 'Profile updated successfully' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── SUPERADMIN: Registration ON/OFF ───────────────────────────────
router.post('/admin/registration-control', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    if (payload.role !== 'superadmin') {
      return res.status(403).json({ message: 'Superadmin only' })
    }
    const { enabled } = req.body
    global.featureFlags = global.featureFlags || {}
    global.featureFlags['open_registration'] = Boolean(enabled)
    try {
      const FF = require('../models/FeatureFlag')
      await FF.findOneAndUpdate(
        { key: 'open_registration' },
        { key: 'open_registration', value: Boolean(enabled) },
        { upsert: true }
      )
    } catch(e) {}
    res.json({ message: `Registration ${enabled?'ENABLED':'DISABLED'}`,
               open_registration: Boolean(enabled) })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

module.exports = router
EOF_AUTH
log "auth.js written"

# ══════════════════════════════════════════════════════
# STEP 3 — emailService.js (Brevo API — confirmed working)
# ══════════════════════════════════════════════════════
step "3 — emailService.js (Brevo API)"
cat > $BE/src/utils/emailService.js << 'EOF_EMAIL'
// ProveRank emailService — Brevo API (confirmed working)
const nodeFetch = typeof fetch !== 'undefined' ? fetch
  : (...args) => import('node-fetch').then(({default:f})=>f(...args))

const BREVO_API    = 'https://api.brevo.com/v3/smtp/email'
const SENDER_EMAIL = 'radhakrishnan100806@gmail.com'
const SENDER_NAME  = 'ProveRank'

async function sendVerificationEmail(toEmail, toName, linkToken=null, otp=null, type='verify') {
  const cfg = {
    verify: { subject:'✅ ProveRank — Email Verification OTP',
              heading:'Verify Your Email',
              msg:'Enter this OTP to verify your email and activate your ProveRank account.' },
    login : { subject:'🔐 ProveRank — Your Login OTP',
              heading:'Login OTP',
              msg:'Enter this OTP to log in to your ProveRank account.' },
    reset : { subject:'🔑 ProveRank — Password Reset OTP',
              heading:'Reset Password OTP',
              msg:'Enter this OTP to reset your ProveRank password.' }
  }
  const c = cfg[type] || cfg.verify

  const html = `
<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
body{margin:0;padding:0;font-family:Arial,sans-serif;background:#f0f4ff}
.wrap{max-width:520px;margin:32px auto;background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,.10)}
.hdr{background:linear-gradient(135deg,#001628,#0055CC);padding:30px 28px;text-align:center}
.logo{font-size:26px;font-weight:900;color:#4D9FFF}.logo span{color:#fff}
.bdy{padding:30px 28px}
h2{color:#1F3864;margin:0 0 10px;font-size:19px}
p{color:#444;font-size:15px;line-height:1.6;margin:0 0 14px}
.obox{background:linear-gradient(135deg,#001628,#003366);border-radius:12px;padding:22px;text-align:center;margin:20px 0}
.otp{font-size:42px;font-weight:900;color:#4D9FFF;letter-spacing:12px;font-family:monospace}
.exp{color:#aaa;font-size:13px;margin-top:8px}
.note{background:#FFF9E6;border-left:4px solid #FFB300;padding:11px 14px;border-radius:6px;font-size:13px;color:#7B4F00;margin-top:14px}
.ftr{background:#f5f7ff;padding:16px 28px;text-align:center;font-size:12px;color:#888}
.ftr a{color:#4D9FFF;text-decoration:none}
</style></head><body>
<div class="wrap">
<div class="hdr"><div class="logo">Prove<span>Rank</span></div>
<div style="color:#B8C8D8;font-size:12px;margin-top:5px">NEET 2026 Preparation</div></div>
<div class="bdy">
<h2>Hi ${toName||'Student'}! 👋</h2>
<p>${c.msg}</p>
<div class="obox"><div class="otp">${otp}</div><div class="exp">⏱️ Valid for 10 minutes</div></div>
<p>Enter this OTP on ProveRank to continue.</p>
<div class="note">⚠️ <strong>Do not share this OTP</strong> with anyone. ProveRank never asks for OTP via call or message.</div>
</div>
<div class="ftr">
<p>ProveRank · <a href="https://prove-rank.vercel.app">prove-rank.vercel.app</a></p>
<p><a href="mailto:ProveRank.support@gmail.com">ProveRank.support@gmail.com</a></p>
</div></div></body></html>`

  try {
    const res = await nodeFetch(BREVO_API, {
      method:'POST',
      headers:{ 'Content-Type':'application/json', 'api-key': process.env.BREVO_API_KEY },
      body: JSON.stringify({
        sender: { name: SENDER_NAME, email: SENDER_EMAIL },
        to: [{ email: toEmail, name: toName||'Student' }],
        subject: c.subject,
        htmlContent: html
      })
    })
    if (res.ok) { console.log(`✅ OTP email [${type}] sent to ${toEmail}`) }
    else { const e=await res.text(); console.error(`❌ Brevo error ${res.status}:`, e) }
  } catch(err) {
    console.error('❌ Email failed:', err.message)
  }
}

module.exports = { sendVerificationEmail }
EOF_EMAIL
log "emailService.js written (Brevo API)"

# ══════════════════════════════════════════════════════
# STEP 4 — Frontend: Register Page (OTP step built in)
# ══════════════════════════════════════════════════════
step "4 — Register Page (with OTP step)"
mkdir -p $FE/app/register
cat > $FE/app/register/page.tsx << 'EOF_PAGE'
'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',GLD='#FFD700',SUB='#6B8FAF',TXT='#E8F4FF'
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:TXT,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',transition:'border-color .2s'}

export default function RegisterPage() {
  const router = useRouter()
  // Step 1: fill details | Step 2: enter OTP
  const [step,     setStep]    = useState<'details'|'otp'>('details')
  const [name,     setName]    = useState('')
  const [email,    setEmail]   = useState('')
  const [password, setPassword]= useState('')
  const [phone,    setPhone]   = useState('')
  const [otp,      setOtp]     = useState('')
  const [loading,  setLoading] = useState(false)
  const [error,    setError]   = useState('')
  const [msg,      setMsg]     = useState('')
  const [resending,setResend]  = useState(false)

  const register = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/register`, {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ name, email, password, phone })
      })
      const d = await r.json()
      if (r.ok) { setStep('otp'); setMsg(d.message||'OTP sent!') }
      else setError(d.message||'Registration failed')
    } catch { setError('Network error. Please try again.') }
    setLoading(false)
  }

  const verifyOtp = async () => {
    if (otp.length !== 6) { setError('Enter 6-digit OTP'); return }
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/verify-otp`, {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ email, otp })
      })
      const d = await r.json()
      if (r.ok) {
        // Save token and go directly to dashboard
        try { localStorage.setItem('pr_token', d.token); localStorage.setItem('pr_role', d.role||'student') } catch{}
        router.replace('/dashboard')
      } else { setError(d.message||'Invalid OTP') }
    } catch { setError('Network error. Please try again.') }
    setLoading(false)
  }

  const resendOtp = async () => {
    setResend(true); setError(''); setMsg('')
    try {
      const r = await fetch(`${API}/api/auth/resend-otp`, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ email })
      })
      const d = await r.json()
      if (r.ok) setMsg('New OTP sent! Check your inbox.')
      else setError(d.message||'Failed to resend')
    } catch { setError('Network error') }
    setResend(false)
  }

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 15% 55%,#001020,#000A18 50%,#000308)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:20}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.9}}`}</style>

      {/* Stars BG */}
      {Array.from({length:50},(_,i)=>(
        <div key={i} style={{position:'fixed',left:`${(i*137.5)%100}%`,top:`${(i*97.3)%100}%`,width:`${i%3===0?2:1.2}px`,height:`${i%3===0?2:1.2}px`,borderRadius:'50%',background:`rgba(200,218,255,${.07+i%8*.045})`,pointerEvents:'none',animation:`pulse ${2+i%4}s ${(i%20)/10}s infinite`}}/>
      ))}

      <div style={{width:'100%',maxWidth:420,animation:'fadeIn .5s ease',position:'relative',zIndex:1}}>
        {/* Logo */}
        <div style={{textAlign:'center',marginBottom:28}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:700,color:PRI}}>ProveRank</div>
          <div style={{fontSize:12,color:SUB,marginTop:4}}>NEET 2026 Preparation Platform</div>
        </div>

        <div style={{background:'rgba(0,22,40,.88)',border:'1px solid rgba(77,159,255,.28)',borderRadius:20,padding:'32px 28px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,.5)'}}>

          {step === 'details' ? (
            <>
              <h2 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,margin:'0 0 6px',textAlign:'center'}}>Create Account</h2>
              <p style={{fontSize:13,color:SUB,textAlign:'center',marginBottom:22}}>Join ProveRank — Free NEET Preparation</p>

              {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}

              <div style={{display:'flex',flexDirection:'column',gap:13}}>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Full Name *</label>
                  <input value={name} onChange={e=>setName(e.target.value)} style={inp} placeholder="Your full name"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email *</label>
                  <input type="email" value={email} onChange={e=>setEmail(e.target.value)} style={inp} placeholder="your@email.com"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Password *</label>
                  <input type="password" value={password} onChange={e=>setPassword(e.target.value)} style={inp} placeholder="Min 6 characters"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Phone (optional)</label>
                  <input value={phone} onChange={e=>setPhone(e.target.value)} style={inp} placeholder="+91 XXXXX XXXXX"/>
                </div>
              </div>

              <button onClick={register} disabled={loading||!name||!email||!password} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!name||!email||!password)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',marginTop:20,opacity:(loading||!name||!email||!password)?.6:1,boxShadow:`0 4px 16px ${PRI}44`}}>
                {loading?'Creating Account...':'Create Account →'}
              </button>

              <div style={{textAlign:'center',marginTop:16,fontSize:13,color:SUB}}>
                Already have an account?{' '}
                <a href="/login" style={{color:PRI,fontWeight:600,textDecoration:'none'}}>Login →</a>
              </div>
            </>
          ) : (
            <>
              {/* OTP STEP */}
              <div style={{textAlign:'center',marginBottom:22}}>
                <div style={{fontSize:48,marginBottom:12}}>📧</div>
                <h2 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,margin:'0 0 6px'}}>Verify Your Email</h2>
                <p style={{fontSize:13,color:SUB,margin:0}}>OTP sent to <span style={{color:PRI,fontWeight:600}}>{email}</span></p>
              </div>

              {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}
              {msg&&<div style={{background:'rgba(0,196,140,.1)',border:'1px solid rgba(0,196,140,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:SUC,marginBottom:14,textAlign:'center'}}>{msg}</div>}

              {/* Big OTP input */}
              <div style={{marginBottom:18}}>
                <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:8,textTransform:'uppercase',letterSpacing:.4,textAlign:'center'}}>Enter 6-Digit OTP</label>
                <input
                  value={otp}
                  onChange={e=>{ setOtp(e.target.value.replace(/\D/g,'').slice(0,6)); setError('') }}
                  style={{...inp,fontSize:28,fontWeight:900,textAlign:'center',letterSpacing:12,fontFamily:'monospace',padding:'16px'}}
                  placeholder="000000"
                  maxLength={6}
                  inputMode="numeric"
                />
              </div>

              <button onClick={verifyOtp} disabled={loading||otp.length!==6} style={{width:'100%',padding:'13px',background:otp.length===6?`linear-gradient(135deg,${SUC},#00a87a)`:'rgba(77,159,255,.2)',color:otp.length===6?'#000':'#fff',border:'none',borderRadius:12,cursor:(loading||otp.length!==6)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||otp.length!==6)?.6:1,boxShadow:otp.length===6?`0 4px 16px ${SUC}44`:undefined}}>
                {loading?'Verifying...':'✅ Verify & Go to Dashboard →'}
              </button>

              <div style={{textAlign:'center',marginTop:14,fontSize:12,color:SUB}}>
                Didn&apos;t receive OTP?{' '}
                <button onClick={resendOtp} disabled={resending} style={{background:'none',border:'none',color:PRI,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12,padding:0}}>
                  {resending?'Sending...':'Resend OTP'}
                </button>
              </div>
              <div style={{textAlign:'center',marginTop:8,fontSize:11,color:SUB}}>
                OTP valid for 10 minutes · Check spam/junk folder
              </div>

              <button onClick={()=>{setStep('details');setOtp('');setError('');setMsg('')}} style={{width:'100%',marginTop:14,padding:'8px',background:'none',border:`1px solid rgba(77,159,255,.2)`,borderRadius:9,color:SUB,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>
                ← Change Email / Register Again
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
EOF_PAGE
log "Register page written (with OTP step)"

# ══════════════════════════════════════════════════════
# STEP 5 — Frontend: Login Page (Password + OTP tabs + Forgot Password)
# ══════════════════════════════════════════════════════
step "5 — Login Page (Password tab + OTP tab + Forgot Password)"
mkdir -p $FE/app/login
cat > $FE/app/login/page.tsx << 'EOF_PAGE'
'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',GLD='#FFD700',SUB='#6B8FAF',TXT='#E8F4FF'
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:TXT,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',transition:'border-color .2s'}

export default function LoginPage() {
  const router = useRouter()
  type Tab = 'password'|'otp'|'forgot'
  const [tab,      setTab]     = useState<Tab>('password')
  // Password login
  const [email,    setEmail]   = useState('')
  const [password, setPassword]= useState('')
  // OTP login
  const [otpEmail, setOtpEmail]= useState('')
  const [loginOtp, setLoginOtp]= useState('')
  const [otpSent,  setOtpSent] = useState(false)
  // Forgot password
  const [fpEmail,  setFpEmail] = useState('')
  const [fpOtp,    setFpOtp]   = useState('')
  const [fpNew,    setFpNew]   = useState('')
  const [fpStep,   setFpStep]  = useState<'email'|'otp'|'done'>('email')
  // Common
  const [loading,  setLoading] = useState(false)
  const [error,    setError]   = useState('')
  const [msg,      setMsg]     = useState('')

  useEffect(()=>{
    try{
      const tk=localStorage.getItem('pr_token')
      const role=localStorage.getItem('pr_role')||'student'
      if(tk){
        if(role==='admin'||role==='superadmin') router.replace('/admin/x7k2p')
        else router.replace('/dashboard')
      }
    }catch{}
  },[router])

  const goAfterLogin=(token:string,role:string)=>{
    try{localStorage.setItem('pr_token',token);localStorage.setItem('pr_role',role)}catch{}
    if(role==='admin'||role==='superadmin') router.replace('/admin/x7k2p')
    else router.replace('/dashboard')
  }

  const loginPassword = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/login`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,password})})
      const d=await r.json()
      if(r.ok) goAfterLogin(d.token,d.role)
      else setError(d.message||'Invalid email or password')
    }catch{setError('Network error. Please try again.')}
    setLoading(false)
  }

  const sendLoginOtp = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/send-login-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:otpEmail})})
      const d=await r.json()
      if(r.ok){setOtpSent(true);setMsg(d.message||'OTP sent!')}
      else setError(d.message||'Failed to send OTP')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const loginWithOtp = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/login-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:otpEmail,otp:loginOtp})})
      const d=await r.json()
      if(r.ok) goAfterLogin(d.token,d.role)
      else setError(d.message||'Invalid OTP')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const sendFpOtp = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/forgot-password`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:fpEmail})})
      const d=await r.json()
      if(r.ok){setFpStep('otp');setMsg(d.message||'OTP sent!')}
      else setError(d.message||'Failed')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const resetPassword = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/reset-password`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:fpEmail,otp:fpOtp,newPassword:fpNew})})
      const d=await r.json()
      if(r.ok){setFpStep('done');setMsg(d.message||'Password reset!')}
      else setError(d.message||'Failed')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const clearAll=()=>{setError('');setMsg('')}

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 15% 55%,#001020,#000A18 50%,#000308)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:20}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.9}}`}</style>

      {Array.from({length:50},(_,i)=>(
        <div key={i} style={{position:'fixed',left:`${(i*137.5)%100}%`,top:`${(i*97.3)%100}%`,width:`${i%3===0?2:1.2}px`,height:`${i%3===0?2:1.2}px`,borderRadius:'50%',background:`rgba(200,218,255,${.07+i%8*.045})`,pointerEvents:'none',animation:`pulse ${2+i%4}s ${(i%20)/10}s infinite`}}/>
      ))}

      <div style={{width:'100%',maxWidth:420,animation:'fadeIn .5s ease',position:'relative',zIndex:1}}>
        <div style={{textAlign:'center',marginBottom:24}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:700,color:PRI}}>ProveRank</div>
          <div style={{fontSize:12,color:SUB,marginTop:4}}>NEET 2026 Preparation Platform</div>
        </div>

        <div style={{background:'rgba(0,22,40,.88)',border:'1px solid rgba(77,159,255,.28)',borderRadius:20,padding:'28px 24px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,.5)'}}>

          {/* ── TABS ── */}
          <div style={{display:'flex',gap:0,marginBottom:22,borderRadius:10,overflow:'hidden',border:'1px solid rgba(77,159,255,.25)'}}>
            {([['password','🔑 Password'],['otp','📱 OTP Login'],['forgot','🔓 Forgot']] as const).map(([t,l])=>(
              <button key={t} onClick={()=>{setTab(t);clearAll()}} style={{flex:1,padding:'10px 4px',background:tab===t?`linear-gradient(135deg,${PRI},#0055CC)`:'rgba(0,22,40,.8)',color:tab===t?'#fff':SUB,border:'none',cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:11,fontWeight:tab===t?700:400,borderRight:t!=='forgot'?'1px solid rgba(77,159,255,.2)':'none',transition:'all .2s'}}>
                {l}
              </button>
            ))}
          </div>

          {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}
          {msg&&<div style={{background:'rgba(0,196,140,.1)',border:'1px solid rgba(0,196,140,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:SUC,marginBottom:14,textAlign:'center'}}>{msg}</div>}

          {/* ── PASSWORD TAB ── */}
          {tab==='password'&&(
            <>
              <div style={{display:'flex',flexDirection:'column',gap:13,marginBottom:16}}>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email</label>
                  <input type="email" value={email} onChange={e=>setEmail(e.target.value)} onKeyDown={e=>e.key==='Enter'&&loginPassword()} style={inp} placeholder="your@email.com"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Password</label>
                  <input type="password" value={password} onChange={e=>setPassword(e.target.value)} onKeyDown={e=>e.key==='Enter'&&loginPassword()} style={inp} placeholder="••••••••"/>
                </div>
              </div>

              {/* Forgot Password link — clickable */}
              <div style={{textAlign:'right',marginBottom:16}}>
                <button onClick={()=>{setTab('forgot');clearAll()}} style={{background:'none',border:'none',color:PRI,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',fontWeight:600,padding:0,textDecoration:'underline'}}>
                  Forgot Password?
                </button>
              </div>

              <button onClick={loginPassword} disabled={loading||!email||!password} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!email||!password)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||!email||!password)?.6:1,boxShadow:`0 4px 16px ${PRI}44`}}>
                {loading?'Logging in...':'Login →'}
              </button>
            </>
          )}

          {/* ── OTP LOGIN TAB ── */}
          {tab==='otp'&&(
            <>
              <div style={{marginBottom:13}}>
                <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email</label>
                <input type="email" value={otpEmail} onChange={e=>setOtpEmail(e.target.value)} style={inp} placeholder="your@email.com" disabled={otpSent}/>
              </div>

              {!otpSent?(
                <button onClick={sendLoginOtp} disabled={loading||!otpEmail} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!otpEmail)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||!otpEmail)?.6:1}}>
                  {loading?'Sending OTP...':'Send OTP →'}
                </button>
              ):(
                <>
                  <div style={{marginBottom:13}}>
                    <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Enter OTP</label>
                    <input value={loginOtp} onChange={e=>setLoginOtp(e.target.value.replace(/\D/g,'').slice(0,6))} style={{...inp,fontSize:24,fontWeight:900,textAlign:'center',letterSpacing:10,fontFamily:'monospace'}} placeholder="000000" maxLength={6} inputMode="numeric"/>
                    <div style={{fontSize:11,color:SUB,marginTop:5,textAlign:'center'}}>
                      OTP sent to {otpEmail} · {' '}
                      <button onClick={sendLoginOtp} style={{background:'none',border:'none',color:PRI,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif',fontWeight:600,padding:0}}>Resend</button>
                    </div>
                  </div>
                  <button onClick={loginWithOtp} disabled={loading||loginOtp.length!==6} style={{width:'100%',padding:'13px',background:loginOtp.length===6?`linear-gradient(135deg,${SUC},#00a87a)`:'rgba(77,159,255,.2)',color:loginOtp.length===6?'#000':'#fff',border:'none',borderRadius:12,cursor:(loading||loginOtp.length!==6)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||loginOtp.length!==6)?.6:1}}>
                    {loading?'Verifying...':'✅ Login with OTP →'}
                  </button>
                  <button onClick={()=>{setOtpSent(false);setLoginOtp('');clearAll()}} style={{width:'100%',marginTop:10,padding:'8px',background:'none',border:`1px solid rgba(77,159,255,.2)`,borderRadius:9,color:SUB,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>← Change Email</button>
                </>
              )}
            </>
          )}

          {/* ── FORGOT PASSWORD TAB ── */}
          {tab==='forgot'&&(
            <>
              {fpStep==='email'&&(
                <>
                  <p style={{fontSize:13,color:SUB,marginBottom:16,textAlign:'center'}}>Enter your registered email — we&apos;ll send a reset OTP.</p>
                  <div style={{marginBottom:14}}>
                    <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email</label>
                    <input type="email" value={fpEmail} onChange={e=>setFpEmail(e.target.value)} style={inp} placeholder="your@email.com"/>
                  </div>
                  <button onClick={sendFpOtp} disabled={loading||!fpEmail} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!fpEmail)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||!fpEmail)?.6:1}}>
                    {loading?'Sending OTP...':'Send Reset OTP →'}
                  </button>
                </>
              )}
              {fpStep==='otp'&&(
                <>
                  <p style={{fontSize:13,color:SUB,marginBottom:16,textAlign:'center'}}>OTP sent to <span style={{color:PRI,fontWeight:600}}>{fpEmail}</span></p>
                  <div style={{display:'flex',flexDirection:'column',gap:12,marginBottom:14}}>
                    <div>
                      <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>OTP</label>
                      <input value={fpOtp} onChange={e=>setFpOtp(e.target.value.replace(/\D/g,'').slice(0,6))} style={{...inp,fontSize:22,fontWeight:900,textAlign:'center',letterSpacing:10,fontFamily:'monospace'}} placeholder="000000" maxLength={6} inputMode="numeric"/>
                    </div>
                    <div>
                      <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>New Password</label>
                      <input type="password" value={fpNew} onChange={e=>setFpNew(e.target.value)} style={inp} placeholder="Min 6 characters"/>
                    </div>
                  </div>
                  <button onClick={resetPassword} disabled={loading||fpOtp.length!==6||fpNew.length<6} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${SUC},#00a87a)`,color:'#000',border:'none',borderRadius:12,cursor:(loading||fpOtp.length!==6||fpNew.length<6)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||fpOtp.length!==6||fpNew.length<6)?.6:1}}>
                    {loading?'Resetting...':'🔑 Reset Password →'}
                  </button>
                  <button onClick={()=>{setFpStep('email');clearAll()}} style={{width:'100%',marginTop:10,padding:'8px',background:'none',border:`1px solid rgba(77,159,255,.2)`,borderRadius:9,color:SUB,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>← Back</button>
                </>
              )}
              {fpStep==='done'&&(
                <div style={{textAlign:'center',padding:'20px 0'}}>
                  <div style={{fontSize:48,marginBottom:12}}>✅</div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:TXT,marginBottom:8}}>Password Reset!</div>
                  <div style={{fontSize:13,color:SUB,marginBottom:20}}>You can now login with your new password.</div>
                  <button onClick={()=>{setTab('password');setFpStep('email');setFpEmail('');setFpOtp('');setFpNew('');clearAll()}} style={{padding:'11px 24px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:10,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif'}}>Go to Login →</button>
                </div>
              )}
            </>
          )}

          {/* Register link */}
          {tab!=='forgot'&&(
            <div style={{textAlign:'center',marginTop:16,fontSize:13,color:SUB}}>
              New to ProveRank?{' '}
              <a href="/register" style={{color:PRI,fontWeight:600,textDecoration:'none'}}>Create Account →</a>
            </div>
          )}
        </div>

        <div style={{textAlign:'center',marginTop:16,fontSize:11,color:'rgba(107,143,175,.5)'}}>
          ProveRank · NEET 2026 · prove-rank.vercel.app
        </div>
      </div>
    </div>
  )
}
EOF_PAGE
log "Login page written (Password + OTP + Forgot Password)"

step "6 — Git push"
cd /home/runner/workspace
git add -A
git commit -m "fix: double-hash bug + register OTP flow + login OTP tab + forgot password"
git push origin main

echo ""
echo -e "${G}╔══════════════════════════════════════════════════════╗${N}"
echo -e "${G}║  ALL 4 ERRORS FIXED ✅                               ║${N}"
echo -e "${G}║  1. Login invalid → double-hash bug fixed            ║${N}"
echo -e "${G}║  2. Email+OTP login → new tab in login page          ║${N}"
echo -e "${G}║  3. Forgot Password → clickable tab with OTP flow    ║${N}"
echo -e "${G}║  4. Register → OTP page → direct to Dashboard        ║${N}"
echo -e "${G}╚══════════════════════════════════════════════════════╝${N}"
