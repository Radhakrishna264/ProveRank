const express = require('express')
const router = express.Router()
const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken')
const crypto = require('crypto')
const User = require('../models/User')
const { sendVerificationEmail } = require('../utils/emailService')

const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'

// ── REGISTER ──
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

    const hash = await bcrypt.hash(password, 12)
    const verifyToken = crypto.randomBytes(32).toString('hex')
    const verifyExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000)

    if (existing && !existing.emailVerified && !existing.verified) {
      existing.name = name
      existing.password = hash
      existing.phone = phone || existing.phone || ''
      existing.emailVerifyToken = verifyToken
      existing.emailVerifyExpiry = verifyExpiry
      await existing.save()
    } else {
      await User.create({
        name, email,
        password: hash,
        phone: phone || '',
        role: 'student',
        verified: false,
        emailVerified: false,
        emailVerifyToken: verifyToken,
        emailVerifyExpiry: verifyExpiry
      })
    }

    await sendVerificationEmail(email, name, verifyToken)

    res.status(201).json({
      message: 'Account created! Please check your email to verify your account.'
    })
  } catch (err) {
    console.error('Register error:', err)
    res.status(500).json({ message: 'Server error during registration' })
  }
})

// ── VERIFY EMAIL ──
router.get('/verify-email', async (req, res) => {
  try {
    const { token } = req.query
    if (!token) return res.status(400).json({ message: 'Token missing' })

    const user = await User.findOne({
      emailVerifyToken: token,
      emailVerifyExpiry: { $gt: new Date() }
    })

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired verification link' })
    }

    // BOTH fields set — login dono check karega
    user.emailVerified = true
    user.verified = true
    user.emailVerifyToken = undefined
    user.emailVerifyExpiry = undefined
    await user.save()

    res.json({ message: 'Email verified successfully! You can now login.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── LOGIN ──
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body
    const user = await User.findOne({ email })
    if (!user) return res.status(401).json({ message: 'Invalid email or password' })

    const match = await bcrypt.compare(password, user.password)
    if (!match) return res.status(401).json({ message: 'Invalid email or password' })

    // Check BOTH verified fields — backward compatible
    const isVerified = user.emailVerified || user.verified
    if (user.role === 'student' && !isVerified) {
      return res.status(403).json({ message: 'Please verify your email before logging in.' })
    }

    if (user.banned) {
      return res.status(403).json({ message: `Account banned: ${user.banReason || 'Contact admin'}` })
    }

    user.loginHistory = user.loginHistory || []
    user.loginHistory.push({ at: new Date(), ip: req.ip })
    if (user.loginHistory.length > 50) user.loginHistory = user.loginHistory.slice(-50)
    await user.save()

    const token = jwt.sign(
      { id: user._id, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    )

    res.json({ token, role: user.role, message: 'Login successful' })
  } catch (err) {
    console.error('Login error:', err)
    res.status(500).json({ message: 'Server error during login' })
  }
})

// ── GET ME ──
router.get('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const token = auth.split(' ')[1]
    const payload = jwt.verify(token, JWT_SECRET)
    const user = await User.findById(payload.id).select('-password')
    if (!user) return res.status(404).json({ message: 'User not found' })
    res.json({ ...user.toObject(), loginHistory: user.loginHistory || [] })
  } catch (err) {
    res.status(401).json({ message: 'Invalid token' })
  }
})

module.exports = router
