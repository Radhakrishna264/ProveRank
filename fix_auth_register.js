/**
 * ProveRank — Auth Fix Script
 * Root Cause: Double-hashing — auth.js manually hashes, then
 *             User model pre('save') hook hashes again → bcrypt.compare() fails
 * Fix: Use User.collection.updateOne / insertOne to BYPASS Mongoose hooks
 * Run in Replit: node fix_auth_register.js
 */
const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'src', 'routes', 'auth.js');
if (!fs.existsSync(filePath)) {
  console.error('❌ src/routes/auth.js not found. Run from workspace root.');
  process.exit(1);
}

const newAuthJs = `const express = require('express')
const router = express.Router()
const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken')
const crypto = require('crypto')
const User = require('../models/User')
const { sendVerificationEmail } = require('../utils/emailService')

let AuditLog
try { AuditLog = require('../models/AuditLog') } catch(e) { AuditLog = null }

const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'

// Helper: generate 6-digit OTP
const genOTP = () => String(Math.floor(100000 + Math.random() * 900000))

// ── REGISTER ──────────────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const regFlag = global.featureFlags && global.featureFlags['open_registration']
    if (regFlag === false) {
      return res.status(403).json({ message: 'Registration is currently closed. Please contact admin.' })
    }

    const { name, email, password, phone } = req.body
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email and password required' })
    }

    const existing = await User.findOne({ email })
    if (existing && (existing.emailVerified || existing.verified)) {
      return res.status(409).json({ message: 'Email already registered' })
    }

    // Hash once here — use collection.updateOne/insertOne to BYPASS pre-save hook
    const hash = await bcrypt.hash(password, 12)
    const otp = genOTP()
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000) // 10 min

    if (existing && !existing.emailVerified && !existing.verified) {
      // Update existing unverified user — bypass hooks
      await User.collection.updateOne(
        { _id: existing._id },
        { $set: {
          name,
          password: hash,
          phone: phone || existing.phone || '',
          emailVerifyOTP: otp,
          emailVerifyOTPExpiry: otpExpiry,
          emailVerifyToken: undefined,
          emailVerifyExpiry: undefined
        }}
      )
    } else {
      // Insert new user — bypass hooks
      await User.collection.insertOne({
        name,
        email,
        password: hash,
        phone: phone || '',
        role: 'student',
        verified: false,
        emailVerified: false,
        emailVerifyOTP: otp,
        emailVerifyOTPExpiry: otpExpiry,
        createdAt: new Date(),
        updatedAt: new Date(),
        loginHistory: [],
        streak: 0,
        badges: []
      })
    }

    // Send OTP email (free — just email)
    await sendVerificationEmail(email, name, null, otp)

    res.status(201).json({
      message: 'Account created! OTP sent to your email.',
      requireOTP: true
    })
  } catch (err) {
    console.error('Register error:', err)
    res.status(500).json({ message: 'Server error during registration' })
  }
})

// ── VERIFY EMAIL OTP → direct token (no redirect to login) ─────────────
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body
    if (!email || !otp) return res.status(400).json({ message: 'Email and OTP required' })

    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ message: 'User not found' })

    if (!user.emailVerifyOTP || user.emailVerifyOTP !== String(otp).trim()) {
      return res.status(400).json({ message: 'Invalid OTP' })
    }
    if (user.emailVerifyOTPExpiry && new Date() > user.emailVerifyOTPExpiry) {
      return res.status(400).json({ message: 'OTP expired. Please register again.' })
    }

    // Mark verified — bypass hooks
    await User.collection.updateOne(
      { _id: user._id },
      { $set: {
        emailVerified: true,
        verified: true,
        emailVerifyOTP: null,
        emailVerifyOTPExpiry: null
      }}
    )

    // Return JWT directly → frontend goes to dashboard immediately
    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' })
    res.json({
      token,
      role: user.role,
      message: 'Email verified! Welcome to ProveRank.'
    })
  } catch (err) {
    console.error('OTP verify error:', err)
    res.status(500).json({ message: 'Server error' })
  }
})

// ── VERIFY EMAIL LINK (backward compat) ─────────────────────────────
router.get('/verify-email', async (req, res) => {
  try {
    const { token } = req.query
    if (!token) return res.status(400).json({ message: 'Token missing' })
    const user = await User.findOne({
      emailVerifyToken: token,
      emailVerifyExpiry: { $gt: new Date() }
    })
    if (!user) return res.status(400).json({ message: 'Invalid or expired verification link' })
    await User.collection.updateOne(
      { _id: user._id },
      { $set: { emailVerified: true, verified: true, emailVerifyToken: null, emailVerifyExpiry: null }}
    )
    const jwtToken = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' })
    // Redirect to frontend with token
    const frontendURL = process.env.FRONTEND_URL || 'https://prove-rank.vercel.app'
    res.redirect(\`\${frontendURL}/verify-success?token=\${jwtToken}&role=\${user.role}\`)
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── LOGIN (Email + Password) ──────────────────────────────────────────
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
        message: 'Please verify your email. Check inbox for OTP.',
        requireOTP: true,
        email
      })
    }
    if (user.banned) {
      return res.status(403).json({ message: \`Account banned: \${user.banReason || 'Contact admin'}\` })
    }

    // Login history — bypass hooks
    const history = user.loginHistory || []
    history.push({ at: new Date(), ip: req.ip, device: req.headers['user-agent']?.substring(0,50)||'Web' })
    await User.collection.updateOne(
      { _id: user._id },
      { $set: { loginHistory: history.slice(-50) }}
    )

    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' })
    res.json({ token, role: user.role, message: 'Login successful' })
  } catch (err) {
    console.error('Login error:', err)
    res.status(500).json({ message: 'Server error during login' })
  }
})

// ── LOGIN via OTP (Email + OTP) ───────────────────────────────────────
router.post('/send-login-otp', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ message: 'No account found with this email' })
    const isVerified = user.emailVerified || user.verified
    if (!isVerified) return res.status(403).json({ message: 'Please verify your account first' })
    if (user.banned) return res.status(403).json({ message: 'Account banned' })

    const otp = genOTP()
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000)
    await User.collection.updateOne(
      { _id: user._id },
      { $set: { loginOTP: otp, loginOTPExpiry: otpExpiry }}
    )
    await sendVerificationEmail(email, user.name, null, otp, 'login')
    res.json({ message: 'OTP sent to your email. Valid for 10 minutes.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

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

    await User.collection.updateOne(
      { _id: user._id },
      { $set: { loginOTP: null, loginOTPExpiry: null }}
    )
    const history = user.loginHistory || []
    history.push({ at: new Date(), ip: req.ip, device: 'OTP Login' })
    await User.collection.updateOne({ _id: user._id }, { $set: { loginHistory: history.slice(-50) }})

    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' })
    res.json({ token, role: user.role, message: 'Login successful' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── FORGOT PASSWORD (via Email OTP) ──────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const user = await User.findOne({ email })
    // Don't reveal if email exists or not (security)
    if (!user) return res.json({ message: 'If this email is registered, you will receive an OTP.' })

    const otp = genOTP()
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000)
    await User.collection.updateOne(
      { _id: user._id },
      { $set: { resetOTP: otp, resetOTPExpiry: otpExpiry }}
    )
    await sendVerificationEmail(email, user.name, null, otp, 'reset')
    res.json({ message: 'OTP sent to your email. Valid for 10 minutes.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

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

    // Hash and save — bypass hooks
    const hash = await bcrypt.hash(newPassword, 12)
    await User.collection.updateOne(
      { _id: user._id },
      { $set: { password: hash, resetOTP: null, resetOTPExpiry: null }}
    )
    res.json({ message: 'Password reset successfully! You can now login.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── CHANGE PASSWORD (logged in) ───────────────────────────────────────
router.post('/change-password', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const token = auth.split(' ')[1]
    const payload = jwt.verify(token, JWT_SECRET)
    const user = await User.findById(payload.id)
    if (!user) return res.status(404).json({ message: 'User not found' })

    const { currentPassword, newPassword } = req.body
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Both passwords required' })
    }
    const match = await bcrypt.compare(currentPassword, user.password)
    if (!match) return res.status(400).json({ message: 'Current password is incorrect' })
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'New password must be at least 6 characters' })
    }
    const hash = await bcrypt.hash(newPassword, 12)
    // Bypass hooks
    await User.collection.updateOne({ _id: user._id }, { $set: { password: hash }})
    res.json({ message: 'Password changed successfully!' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── GET ME ────────────────────────────────────────────────────────────
router.get('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const token = auth.split(' ')[1]
    const payload = jwt.verify(token, JWT_SECRET)
    const user = await User.findById(payload.id).select('-password -emailVerifyOTP -loginOTP -resetOTP')
    if (!user) return res.status(404).json({ message: 'User not found' })
    res.json({ ...user.toObject(), loginHistory: user.loginHistory || [] })
  } catch (err) {
    res.status(401).json({ message: 'Invalid token' })
  }
})

// ── PATCH ME (profile update) ─────────────────────────────────────────
router.patch('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const token = auth.split(' ')[1]
    const payload = jwt.verify(token, JWT_SECRET)
    const allowed = ['name','phone','dob','city','targetExam','board','school','bio','parentEmail','goals','avatar']
    const update = {}
    allowed.forEach(k => { if (req.body[k] !== undefined) update[k] = req.body[k] })
    update.updatedAt = new Date()
    await User.collection.updateOne({ _id: payload.id }, { $set: update })
    res.json({ message: 'Profile updated successfully' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── REGISTRATION CONTROL (Superadmin) ────────────────────────────────
router.post('/admin/registration-control', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const token = auth.split(' ')[1]
    const payload = jwt.verify(token, JWT_SECRET)
    if (payload.role !== 'superadmin') {
      return res.status(403).json({ message: 'Superadmin only' })
    }
    const { enabled } = req.body
    global.featureFlags = global.featureFlags || {}
    global.featureFlags['open_registration'] = Boolean(enabled)
    // Persist to DB if FeatureFlag model exists
    try {
      const FeatureFlag = require('../models/FeatureFlag')
      await FeatureFlag.findOneAndUpdate(
        { key: 'open_registration' },
        { key: 'open_registration', value: Boolean(enabled) },
        { upsert: true, new: true }
      )
    } catch(e) {}
    res.json({
      message: \`Registration \${enabled ? 'ENABLED' : 'DISABLED'} successfully\`,
      open_registration: Boolean(enabled)
    })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

module.exports = router
`

fs.writeFileSync(filePath, newAuthJs, 'utf8');
console.log('✅ auth.js updated successfully!');
console.log('');
console.log('📋 Changes made:');
console.log('  1. ✅ FIXED: Double-hash bug → using collection.updateOne/insertOne (bypasses pre-save hook)');
console.log('  2. ✅ ADDED: OTP-based email verification (register → OTP → direct dashboard)');
console.log('  3. ✅ ADDED: Email+OTP login option (send-login-otp + login-otp)');
console.log('  4. ✅ ADDED: Forgot Password via OTP (forgot-password + reset-password)');
console.log('  5. ✅ ADDED: Registration Control (Superadmin) → /admin/registration-control');
console.log('  6. ✅ FIXED: change-password also bypasses hooks');
console.log('  7. ✅ ADDED: PATCH /me for profile updates (bypass hooks)');
console.log('');
console.log('⚠️  Next: Update emailService.js to handle OTP emails');
console.log('⚠️  Next: Update frontend register page for OTP flow');
