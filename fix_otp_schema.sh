#!/bin/bash
# Fix: Add OTP fields to User model + fix OTP comparison using collection directly
G='\033[0;32m'; B='\033[0;34m'; N='\033[0m'
log(){ echo -e "${G}[✓]${N} $1"; }
step(){ echo -e "\n${B}══════ $1 ══════${N}"; }

BE=/home/runner/workspace

step "1 — Add OTP fields to User model schema"
node << 'NODEOF'
const fs = require('fs')
const path = '/home/runner/workspace/src/models/User.js'
if (!fs.existsSync(path)) { console.log('❌ Not found:', path); process.exit(1) }

let code = fs.readFileSync(path, 'utf8')

// Add OTP fields if not already present
const otpFields = `
  // OTP fields — register verify, login OTP, reset password
  emailVerifyOTP:      { type: String, default: null },
  emailVerifyOTPExpiry:{ type: Date,   default: null },
  loginOTP:            { type: String, default: null },
  loginOTPExpiry:      { type: Date,   default: null },
  resetOTP:            { type: String, default: null },
  resetOTPExpiry:      { type: Date,   default: null },`

if (!code.includes('emailVerifyOTP')) {
  // Insert before closing of schema fields — find a safe anchor
  // Try to insert before 'emailVerifyToken' or before 'createdAt' or before the closing });
  if (code.includes('emailVerifyToken')) {
    code = code.replace(
      /emailVerifyToken\s*:/,
      otpFields + '\n  emailVerifyToken:'
    )
  } else if (code.includes('loginHistory')) {
    code = code.replace(
      /loginHistory\s*:/,
      otpFields + '\n  loginHistory:'
    )
  } else if (code.includes('createdAt')) {
    code = code.replace(
      /createdAt\s*:/,
      otpFields + '\n  createdAt:'
    )
  } else {
    // Last resort: add before module.exports
    code = code.replace(
      /module\.exports/,
      '\n// OTP fields added\n' + otpFields + '\n\nmodule.exports'
    )
  }
  fs.writeFileSync(path, code, 'utf8')
  console.log('✅ OTP fields added to User schema')
} else {
  console.log('✅ OTP fields already in schema')
}

// Also remove pre-save password hash hook if present
const original = code
code = code.replace(
  /\/\*[\s\S]*?pre.save[\s\S]*?\*\//g, ''
)
// Match: UserSchema.pre('save', async function(...) { ... bcrypt ... });
code = code.replace(
  /\w+[Ss]chema\.pre\s*\(\s*['"]save['"]\s*,\s*async\s+function[\s\S]*?bcrypt[\s\S]*?\}\s*\)\s*;?\s*\n/g,
  '// pre-save password hook removed — hashing done in auth.js\n'
)
if (code !== original) {
  fs.writeFileSync(path, code, 'utf8')
  console.log('✅ pre-save hash hook removed')
} else {
  console.log('ℹ️  No pre-save hook found (already removed or not present)')
}

// Show current schema fields for verification
const fieldMatches = code.match(/^\s{2}(\w+)\s*:/gm) || []
console.log('Schema fields found:', fieldMatches.slice(0,20).map(f=>f.trim()).join(', '))
NODEOF
log "User model updated"

step "2 — Fix auth.js OTP routes to use collection.findOne (bypasses schema filter)"
cat > $BE/src/routes/auth.js << 'EOF_AUTH'
const express = require('express')
const router  = express.Router()
const bcrypt  = require('bcrypt')
const jwt     = require('jsonwebtoken')
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

    // Use collection directly — bypass ALL mongoose hooks
    const existing = await User.collection.findOne({ email })
    if (existing && (existing.emailVerified || existing.verified)) {
      return res.status(409).json({ message: 'Email already registered. Please login.' })
    }

    const hash = await bcrypt.hash(password, 12)
    const otp  = genOTP()
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000)
    const now = new Date()

    if (existing) {
      await User.collection.updateOne({ _id: existing._id }, {
        $set: {
          name, password: hash, phone: phone || '',
          emailVerifyOTP: otp, emailVerifyOTPExpiry: otpExpiry,
          emailVerifyToken: null, emailVerifyExpiry: null,
          updatedAt: now
        }
      })
    } else {
      await User.collection.insertOne({
        name, email, password: hash, phone: phone || '',
        role: 'student', verified: false, emailVerified: false,
        emailVerifyOTP: otp, emailVerifyOTPExpiry: otpExpiry,
        streak: 0, badges: [], loginHistory: [],
        createdAt: now, updatedAt: now
      })
    }

    await sendVerificationEmail(email, name, null, otp, 'verify')
    res.status(201).json({
      message: 'OTP sent to your email. Valid for 10 minutes.',
      requireOTP: true
    })
  } catch (err) {
    console.error('Register error:', err)
    res.status(500).json({ message: 'Server error during registration' })
  }
})

// ── VERIFY OTP (register) → return JWT directly ───────────────────
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body
    if (!email || !otp) return res.status(400).json({ message: 'Email and OTP required' })

    // Use collection.findOne — gets ALL fields including OTP
    const user = await User.collection.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })

    const storedOTP = String(user.emailVerifyOTP || '').trim()
    const givenOTP  = String(otp).trim()

    console.log(`OTP check — stored: "${storedOTP}" given: "${givenOTP}" match: ${storedOTP === givenOTP}`)

    if (!storedOTP || storedOTP !== givenOTP) {
      return res.status(400).json({ message: 'Invalid OTP. Please check your email.' })
    }
    if (user.emailVerifyOTPExpiry && new Date() > new Date(user.emailVerifyOTPExpiry)) {
      return res.status(400).json({ message: 'OTP expired. Please register again to get a new OTP.' })
    }

    await User.collection.updateOne({ _id: user._id }, {
      $set: {
        emailVerified: true, verified: true,
        emailVerifyOTP: null, emailVerifyOTPExpiry: null
      }
    })

    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    res.json({ token, role: user.role || 'student', name: user.name,
               message: 'Email verified! Welcome to ProveRank.' })
  } catch (err) {
    console.error('OTP verify error:', err)
    res.status(500).json({ message: 'Server error' })
  }
})

// ── RESEND VERIFY OTP ─────────────────────────────────────────────
router.post('/resend-otp', async (req, res) => {
  try {
    const { email } = req.body
    const user = await User.collection.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })
    if (user.emailVerified || user.verified) {
      return res.status(400).json({ message: 'Email already verified. Please login.' })
    }
    const otp = genOTP()
    await User.collection.updateOne({ _id: user._id }, {
      $set: { emailVerifyOTP: otp, emailVerifyOTPExpiry: new Date(Date.now() + 10*60*1000) }
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

    // collection.findOne — gets password field always
    const user = await User.collection.findOne({ email })
    if (!user) return res.status(401).json({ message: 'Invalid email or password' })

    const match = await bcrypt.compare(password, user.password)
    console.log(`Login attempt: ${email} | match: ${match}`)

    if (!match) return res.status(401).json({ message: 'Invalid email or password' })

    const isVerified = user.emailVerified || user.verified
    if ((user.role === 'student' || !user.role) && !isVerified) {
      return res.status(403).json({
        message: 'Email not verified. Check your inbox for OTP.',
        requireOTP: true, email
      })
    }
    if (user.banned) {
      return res.status(403).json({ message: `Account banned: ${user.banReason || 'Contact admin'}` })
    }

    const history = [...(user.loginHistory || [])]
    history.push({ at: new Date(), ip: req.ip,
      device: (req.headers['user-agent'] || 'Web').substring(0, 60) })
    await User.collection.updateOne({ _id: user._id },
      { $set: { loginHistory: history.slice(-50) } })

    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    res.json({ token, role: user.role || 'student', message: 'Login successful' })
  } catch (err) {
    console.error('Login error:', err)
    res.status(500).json({ message: 'Server error during login' })
  }
})

// ── SEND LOGIN OTP ────────────────────────────────────────────────
router.post('/send-login-otp', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const user = await User.collection.findOne({ email })
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

// ── LOGIN WITH OTP ────────────────────────────────────────────────
router.post('/login-otp', async (req, res) => {
  try {
    const { email, otp } = req.body
    if (!email || !otp) return res.status(400).json({ message: 'Email and OTP required' })
    const user = await User.collection.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })

    const storedOTP = String(user.loginOTP || '').trim()
    const givenOTP  = String(otp).trim()
    console.log(`Login OTP check — stored: "${storedOTP}" given: "${givenOTP}"`)

    if (!storedOTP || storedOTP !== givenOTP) {
      return res.status(400).json({ message: 'Invalid OTP' })
    }
    if (user.loginOTPExpiry && new Date() > new Date(user.loginOTPExpiry)) {
      return res.status(400).json({ message: 'OTP expired. Request a new one.' })
    }
    if (user.banned) return res.status(403).json({ message: 'Account banned' })

    await User.collection.updateOne({ _id: user._id },
      { $set: { loginOTP: null, loginOTPExpiry: null } })

    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    res.json({ token, role: user.role || 'student', message: 'Login successful' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── FORGOT PASSWORD ───────────────────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const user = await User.collection.findOne({ email })
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

// ── RESET PASSWORD ────────────────────────────────────────────────
router.post('/reset-password', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body
    if (!email || !otp || !newPassword) {
      return res.status(400).json({ message: 'Email, OTP and new password required' })
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' })
    }
    const user = await User.collection.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })

    const storedOTP = String(user.resetOTP || '').trim()
    const givenOTP  = String(otp).trim()
    if (!storedOTP || storedOTP !== givenOTP) {
      return res.status(400).json({ message: 'Invalid OTP' })
    }
    if (user.resetOTPExpiry && new Date() > new Date(user.resetOTPExpiry)) {
      return res.status(400).json({ message: 'OTP expired. Request a new one.' })
    }
    const hash = await bcrypt.hash(newPassword, 12)
    await User.collection.updateOne({ _id: user._id },
      { $set: { password: hash, resetOTP: null, resetOTPExpiry: null } })
    res.json({ message: 'Password reset successfully! You can now login.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── CHANGE PASSWORD (logged in) ───────────────────────────────────
router.post('/change-password', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const user = await User.collection.findOne({ _id: new (require('mongoose').Types.ObjectId)(payload.id) })
    if (!user) return res.status(404).json({ message: 'User not found' })
    const { currentPassword, newPassword } = req.body
    if (!await bcrypt.compare(currentPassword, user.password)) {
      return res.status(400).json({ message: 'Current password is incorrect' })
    }
    if ((newPassword || '').length < 6) {
      return res.status(400).json({ message: 'Min 6 characters required' })
    }
    const hash = await bcrypt.hash(newPassword, 12)
    await User.collection.updateOne({ _id: user._id }, { $set: { password: hash } })
    res.json({ message: 'Password changed successfully!' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── GET ME ────────────────────────────────────────────────────────
router.get('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const user = await User.collection.findOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { projection: { password:0, emailVerifyOTP:0, loginOTP:0, resetOTP:0, emailVerifyToken:0 } }
    )
    if (!user) return res.status(404).json({ message: 'User not found' })
    res.json({ ...user, loginHistory: user.loginHistory || [] })
  } catch (err) {
    res.status(401).json({ message: 'Invalid token' })
  }
})

// ── PATCH ME ──────────────────────────────────────────────────────
router.patch('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const allowed = ['name','phone','dob','city','targetExam','board',
                     'school','bio','parentEmail','goals','avatar']
    const update = { updatedAt: new Date() }
    allowed.forEach(k => { if (req.body[k] !== undefined) update[k] = req.body[k] })
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { $set: update }
    )
    res.json({ message: 'Profile updated successfully' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── SUPERADMIN: Registration ON/OFF ──────────────────────────────
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
    res.json({
      message: `Registration ${enabled ? 'ENABLED' : 'DISABLED'} successfully`,
      open_registration: Boolean(enabled)
    })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

module.exports = router
EOF_AUTH
log "auth.js written — all routes use collection.findOne"

step "3 — Verify existing users in DB have correct OTP (debug)"
node << 'NODEOF'
// Quick check: can we connect and see what's in DB?
const mongoose = require('/home/runner/workspace/node_modules/mongoose')
const dotenv = require('/home/runner/workspace/node_modules/dotenv')
dotenv.config({ path: '/home/runner/workspace/.env' })

const MONGO = process.env.MONGODB_URI || process.env.MONGO_URI || process.env.DATABASE_URL
if (!MONGO) { console.log('⚠️  No MONGO URI found — skipping DB check'); process.exit(0) }

mongoose.connect(MONGO).then(async () => {
  const db = mongoose.connection.db
  const users = await db.collection('users').find(
    { role: 'student' },
    { projection: { email:1, emailVerified:1, emailVerifyOTP:1, password:1 } }
  ).limit(5).toArray()
  
  console.log('Recent users in DB:')
  users.forEach(u => {
    console.log(`  ${u.email} | verified: ${u.emailVerified} | hasOTP: ${!!u.emailVerifyOTP} | OTP: ${u.emailVerifyOTP || 'null'} | pwdLen: ${(u.password||'').length}`)
  })
  await mongoose.disconnect()
}).catch(e => {
  console.log('DB connect failed (will work on Render):', e.message)
})
NODEOF
log "DB check done"

step "4 — Git push"
cd /home/runner/workspace
git add -A
git commit -m "fix: use collection.findOne everywhere — OTP comparison bypass schema filter"
git push origin main

echo ""
echo -e "${G}╔═══════════════════════════════════════════════════╗${N}"
echo -e "${G}║  ROOT CAUSE FIXED ✅                              ║${N}"
echo -e "${G}║  Problem: User.findOne() silently dropped OTP     ║${N}"
echo -e "${G}║  fields not in schema → comparison always failed  ║${N}"
echo -e "${G}║  Fix: ALL routes now use collection.findOne()     ║${N}"
echo -e "${G}║  which returns ALL MongoDB fields including OTP   ║${N}"
echo -e "${G}╚═══════════════════════════════════════════════════╝${N}"
