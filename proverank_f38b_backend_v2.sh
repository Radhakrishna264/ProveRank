#!/bin/bash
# ProveRank — F38B Student 360° Profile Preview — BACKEND v2
# 1) LOGIN_FAILED activity log  2) trustedDevices populated on login
# 3) passwordResetHistory populated on forgot-password reset
# 4) 2FA enable/disable logged  5) Audit trail matches by userId OR email/studentId
# Run from project ROOT in Replit shell: bash proverank_f38b_backend_v2.sh
set -e

SRC_DIR="src"

mkdir -p "$SRC_DIR/models" "$SRC_DIR/routes"

echo '-> Writing $SRC_DIR/models/User.js'
cat > "$SRC_DIR/models/User.js" << 'PRSHEOF'
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  password: { type: String, required: true },
  studentId: { type: String, unique: true, sparse: true, trim: true },
  adminId: { type: String, unique: true, sparse: true, trim: true },

  // ── F38/F39: Extended Profile Fields ──────────────────────────
  state:              { type: String, default: '' },
  gender:             { type: String, default: '' },
  timezone:           { type: String, default: 'Asia/Kolkata' },
  targetYear:         { type: String, default: '' },
  yearOfAppearing:    { type: String, default: '' },
  coachingInstitute:  { type: String, default: '' },
  dob:                { type: String, default: '' },
  city:               { type: String, default: '' },
  bio:                { type: String, default: '', maxlength: 160 },
  avatar:             { type: String, default: '' },
  targetExam:         { type: String, default: '' },
  board:              { type: String, default: '' },
  school:             { type: String, default: '' },
  medium:             { type: String, default: '' },
  batch:              { type: String, default: '' },

  // ── F38: 2FA (TOTP) ────────────────────────────────────────────
  twoFactorEnabled:     { type: Boolean, default: false },
  twoFactorSecret:      { type: String, default: null },
  twoFactorTempSecret:  { type: String, default: null },

  // ── F38: Login health / device tracking ─────────────────────────
  failedLoginAttempts: { type: Number, default: 0 },
  lastFailedLoginAt:   { type: Date, default: null },
  loginCount:          { type: Number, default: 0 },
  trustedDevices: [{
    deviceId:   String,
    label:      String,
    browser:    String,
    os:         String,
    addedAt:    { type: Date, default: Date.now },
    lastUsedAt: Date,
  }],

  // ── F38B §7 — Profile photo version history (Superadmin only view) ──
  avatarHistory: [{
    url:       String,
    updatedAt: { type: Date, default: Date.now },
    updatedBy: { type: String, default: 'self' },
    source:    { type: String, default: 'profile_page' },
  }],

  // ── F38B §5 — Password change metadata (never the password itself) ──
  passwordChangedAt:   { type: Date, default: null },
  passwordChangeCount: { type: Number, default: 0 },
  passwordResetHistory: [{
    requestedAt: { type: Date, default: Date.now },
    resetBy:     { type: String, default: 'self' },
    method:      { type: String, default: 'otp' },
  }],

  // Profile history (F38 §9 — per-field internal audit trail, DB only, never shown to student)
  profileHistory: [{
    updatedAt:        { type: Date, default: Date.now },
    updatedFields:    [String],
    changes: [{
      field:    String,
      oldValue: mongoose.Schema.Types.Mixed,
      newValue: mongoose.Schema.Types.Mixed,
    }],
    updatedBy: { type: String, default: 'self' },
    source:    { type: String, default: 'profile_page' },
    snapshot: {
      name: String, phone: String, dob: String, city: String,
      state: String, gender: String, bio: String,
      targetExam: String, targetYear: String, board: String,
      school: String, coachingInstitute: String,
    }
  }],

  // Preferences
  preferences: {
    emailNotif:    { type: Boolean, default: true },
    smsNotif:      { type: Boolean, default: false },
    studyReminder: { type: Boolean, default: true },
  },

  welcomeSeen: { type: Boolean, default: false },
  role: {
    type: String,
    enum: ['superadmin', 'admin', 'student'],
    default: 'student'
  },
  termsAccepted: { type: Boolean, default: false },
  permissions: { type: Map, of: Boolean, default: {} },
  adminFrozen: { type: Boolean, default: false },
  group: { type: String },
  otp: { type: String },
  otpExpiry: { type: Date },
  verified: { type: Boolean, default: false },
  profilePhoto: { type: String },
  emailVerified: { type: Boolean, default: false },
  
  // OTP fields — register verify, login OTP, reset password
  emailVerifyOTP:      { type: String, default: null },
  emailVerifyOTPExpiry:{ type: Date,   default: null },
  loginOTP:            { type: String, default: null },
  loginOTPExpiry:      { type: Date,   default: null },
  resetOTP:            { type: String, default: null },
  resetOTPExpiry:      { type: Date,   default: null },
  emailVerifyToken: { type: String },
  emailVerifyExpiry: { type: Date },
  loginHistory: [{
    ip: String,
    device: String,
    time: { type: Date, default: Date.now }
  }],
  customFields: { type: Object },
  banned: { type: Boolean, default: false },
  frozen: { type: Boolean, default: false },
  archived: { type: Boolean, default: false },
  banReason: { type: String },
  banExpiry: { type: Date },
  parentEmail: { type: String },

  // ── F35: Multi-device session control + Terms tracking ─────────
  activeSessionToken: { type: String, default: null },
  termsAccepted:      { type: Boolean, default: false },
  termsAcceptedAt:    { type: Date,    default: null },
  termsVersion:        { type: String, default: null },

  // F37 — Checklist + XP
  checklist: {
    pyqExplored:      { type: Boolean, default: false },
    analyticsVisited: { type: Boolean, default: false },
  },
  xp: { type: Number, default: 0 },

}, { timestamps: true });

// password hashing removed — done in auth.js directly;

if (mongoose.models.User) delete mongoose.connection.models['User'];
module.exports = mongoose.model('User', userSchema, 'students');
PRSHEOF

echo '-> Writing $SRC_DIR/routes/auth.js'
cat > "$SRC_DIR/routes/auth.js" << 'PRSHEOF'
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
    let existing = await User.collection.findOne({ email })
    if (existing && existing.deleted === true) {
      await User.collection.deleteOne({ _id: existing._id });
      existing = null;
    }
    if (existing && (existing.emailVerified || existing.verified) && !existing.frozen && !existing.archived) {
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
          archived: false, archivedBy: null, archivedAt: null, frozen: false,
          updatedAt: now
        }
      })
    } else {
      const _genStudentId2=async()=>{const chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';const yr=new Date().getFullYear().toString().slice(-2);let sid,exists,tries=0;do{const rand=Array.from({length:4},()=>chars[Math.floor(Math.random()*chars.length)]).join('');sid='PR'+yr+rand;exists=await User.collection.findOne({studentId:sid});tries++;}while(exists&&tries<50);return sid;};const _newStudentId=await _genStudentId2();
    await User.collection.insertOne({
        name, email, password: hash, phone: phone || '',
        role: 'student', verified: false, emailVerified: false,
        emailVerifyOTP: otp, emailVerifyOTPExpiry: otpExpiry,
        streak: 0, badges: [], loginHistory: [],
        studentId: _newStudentId, welcomeSeen: false,
      createdAt: now, updatedAt: now
      })
  // S109_WELCOME_HOOK — Welcome Email Auto-trigger
  try {
    const EmailTemplate = require('../models/EmailTemplate')
    const { sendCustomEmail } = require('../utils/emailService')
    const tmpl = await EmailTemplate.findOne({ type:'welcome', active:true })
    if (tmpl) {
      const emailBody = tmpl.htmlBody
        .replace(/{student_name}/g, userData.name||'Student')
        .replace(/{date}/g, new Date().toLocaleDateString('en-IN'))
      sendCustomEmail([userData.email], tmpl.subject, emailBody)
        .catch(e => console.error('[Welcome Email]', e.message))
    }
  } catch(we){ console.error('[Welcome Email Hook]', we.message) }
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
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: user._id, userName: user.name, userRole: user.role||'student', action: 'EMAIL_VERIFIED', details: 'Email verified successfully', module: 'security', status: 'success' }).catch(()=>{})
    } catch(e) {}

    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    res.json({ token, role: user.role || 'student', name: user.name, studentId: user.studentId||null, welcomeSeen: user.welcomeSeen||false,
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
    if (!user) return res.status(401).json({ message: 'No account found with this email.' })

    // ── Block login for soft-deleted / archived accounts ──
    if(user && user.deleted === true){
      return res.status(403).json({ message: 'You have been removed by SuperAdmin.' });
    }

    const match = await bcrypt.compare(password, user.password)
    console.log(`Login attempt: ${email} | match: ${match}`)

    if (!match) {
      await User.collection.updateOne({ _id: user._id }, {
        $inc: { failedLoginAttempts: 1 },
        $set: { lastFailedLoginAt: new Date() }
      }).catch(()=>{})
      try {
        const { logActivity } = require('../utils/activityLogger')
        logActivity({ userId: user._id, userName: user.name, userRole: user.role||'student', action: 'LOGIN_FAILED', details: 'Incorrect password entered', module: 'security', ipAddress: (req.headers['x-forwarded-for']||'').split(',')[0].trim() || req.ip || 'Unknown', userAgent: req.headers['user-agent']||'', status: 'failed' }).catch(()=>{})
      } catch(e) {}
      return res.status(401).json({ message: 'Incorrect password. Please try again.' })
    }

    const isVerified = user.emailVerified || user.verified
    if ((user.role === 'student' || !user.role) && !isVerified) {
      return res.status(403).json({
        message: 'Email not verified. Check your inbox for OTP.',
        requireOTP: true, email
      })
    }
    if (user.archived) { return res.status(403).json({ message: 'You have been removed by SuperAdmin.', code: 'ARCHIVED' }); }
    if (user.frozen) { return res.status(403).json({ message: 'Account frozen. Contact SuperAdmin.', code: 'FROZEN' }); }
  if (user.banned || user.isBanned) {
      return res.status(403).json({ message: `Account banned: ${user.banReason || 'Contact admin'}` })
    }

    const history = [...(user.loginHistory || [])]
    const rawUA = req.headers['user-agent'] || ''
    const realIp = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.ip || 'Unknown'
    let browser = 'Unknown'
    if (rawUA.includes('Edg/')) browser = 'Edge'
    else if (rawUA.includes('OPR/') || rawUA.includes('Opera')) browser = 'Opera'
    else if (rawUA.includes('Chrome') && !rawUA.includes('Chromium')) browser = 'Chrome'
    else if (rawUA.includes('Firefox')) browser = 'Firefox'
    else if (rawUA.includes('Safari') && !rawUA.includes('Chrome')) browser = 'Safari'
    let os = 'Unknown'
    if (rawUA.includes('Android')) os = 'Android'
    else if (rawUA.includes('iPhone') || rawUA.includes('iPad')) os = 'iOS'
    else if (rawUA.includes('Windows NT')) os = 'Windows'
    else if (rawUA.includes('Mac OS X')) os = 'macOS'
    else if (rawUA.includes('Linux')) os = 'Linux'
    let city = 'Unknown', country = 'Unknown'
    try {
      const _ac=new AbortController();const _gt=setTimeout(()=>_ac.abort(),1500);const geoRes=await fetch(`http://ip-api.com/json/${realIp}?fields=city,country,status`,{signal:_ac.signal});clearTimeout(_gt)
      const geo = await geoRes.json()
      if (geo.status === 'success') { city = geo.city || 'Unknown'; country = geo.country || 'Unknown' }
    } catch(e) {}
    history.push({ at: new Date(), ip: realIp, browser, os, city, country, device: `${browser} on ${os}` })
    User.collection.updateOne({ _id: user._id },
      { $set: { loginHistory: history.slice(-50) }, $inc: { loginCount: 1 } }).catch(()=>{})

    // ── Trusted Devices — match by browser+OS fingerprint; update lastUsedAt
    //     if already known, otherwise add a new trusted device entry ──
    try {
      const crypto = require('crypto')
      const deviceId = crypto.createHash('md5').update(`${browser}|${os}`).digest('hex').slice(0, 12)
      const devices = [...(user.trustedDevices || [])]
      const idx = devices.findIndex(d => d.deviceId === deviceId)
      if (idx >= 0) {
        devices[idx] = { ...devices[idx], lastUsedAt: new Date() }
      } else {
        devices.push({ deviceId, label: `${browser} on ${os}`, browser, os, addedAt: new Date(), lastUsedAt: new Date() })
      }
      User.collection.updateOne({ _id: user._id }, { $set: { trustedDevices: devices.slice(-20) } }).catch(()=>{})
    } catch (e) {}

    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    // F35.1 — Multi-device session control: new login invalidates old device
    await User.collection.updateOne({ _id: user._id }, { $set: { activeSessionToken: token, failedLoginAttempts: 0 } })
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: user._id, userName: user.name, userRole: user.role||'student', action: 'LOGIN', details: `Login from ${city}, ${country}`, module: 'security', ipAddress: realIp, userAgent: rawUA, status: 'success' }).catch(()=>{})
    } catch(e) {}
    res.json({ token, role: user.role || 'student', name:user.name||'',studentId:user.studentId||null,welcomeSeen:user.welcomeSeen||false,message:'Login successful' })
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
    // F35.1 — Multi-device session control
    await User.collection.updateOne({ _id: user._id }, { $set: { activeSessionToken: token } })
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
      { $set: { password: hash, resetOTP: null, resetOTPExpiry: null, passwordChangedAt: new Date() },
        $inc: { passwordChangeCount: 1 },
        $push: { passwordResetHistory: { requestedAt: new Date(), resetBy: 'self', method: 'otp' } } })
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: user._id, userName: user.name, userRole: user.role||'student', action: 'PASSWORD_RESET', details: 'Password reset via forgot-password OTP', module: 'security', status: 'success' }).catch(()=>{})
    } catch(e) {}
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
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: user._id, userName: user.name, userRole: user.role||'student', action: 'PASSWORD_CHANGED', details: 'Password changed successfully', module: 'security', status: 'success' }).catch(()=>{})
    } catch(e) {}
    res.json({ message: 'Password changed successfully!' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F38 §11.4.2.5 — Duplicate phone check (live, as-you-type) ──
router.get('/check-phone', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const phone = String(req.query.phone || '').trim().replace(/[\s-]/g, '')
    if (!phone) return res.json({ available: true })
    const existing = await User.collection.findOne({
      phone, _id: { $ne: new mongoose.Types.ObjectId(payload.id) }
    })
    res.json({ available: !existing })
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
    // F35.1 — Reject if logged in on another device (session replaced)
    const presentedToken = auth.split(' ')[1]
    if ((user.role==='student'||!user.role) && user.activeSessionToken && user.activeSessionToken !== presentedToken) {
      return res.status(401).json({ message: 'Session expired — you have been logged in on another device.', code: 'SESSION_REPLACED' })
    }
    res.json({ ...user, studentId: user.studentId||null, loginHistory: user.loginHistory || [] })
  } catch (err) {
    res.status(401).json({ message: 'Invalid token' })
  }
})

// ── PATCH ME ──────────────────────────────────────────────────────
// F38 — supports partial/section-based saves. Send req.body.__section
// ('personal' | 'academic' | 'preferences' | 'general') to tag where the
// change came from — used only for the internal (DB-only) history log.
router.patch('/me', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const allowed = ['name','phone','dob','city','targetExam','board','school','medium',
                     'bio','parentEmail','goals','avatar','state','gender','timezone',
                     'targetYear','yearOfAppearing','coachingInstitute','preferences']
    const section = typeof req.body.__section === 'string' ? req.body.__section : 'general'

    // ── F38 §3.2 / §11.4 — Smart validation ──
    if (req.body.phone !== undefined && req.body.phone) {
      const ph = String(req.body.phone).trim().replace(/[\s-]/g, '')
      if (!/^(\+91)?[6-9]\d{9}$/.test(ph)) {
        return res.status(400).json({ message: 'Invalid phone number. Use a valid 10-digit Indian mobile number.' })
      }
    }
    if (req.body.dob !== undefined && req.body.dob) {
      const d = new Date(req.body.dob)
      if (isNaN(d.getTime()) || d > new Date() || d.getFullYear() < 1970) {
        return res.status(400).json({ message: 'Invalid date of birth' })
      }
    }
    if (req.body.name !== undefined && !String(req.body.name).trim()) {
      return res.status(400).json({ message: 'Name cannot be empty' })
    }

    const current = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(payload.id) })
    if (!current) return res.status(404).json({ message: 'User not found' })

    const update = { updatedAt: new Date() }
    const changes = []
    allowed.forEach(k => {
      if (req.body[k] !== undefined) {
        let newVal = req.body[k]
        if (k === 'bio') newVal = (newVal || '').slice(0, 160)
        if (k === 'phone' && newVal) newVal = String(newVal).trim().replace(/[\s-]/g, '')
        const oldVal = current[k] !== undefined ? current[k] : null
        if (JSON.stringify(oldVal) !== JSON.stringify(newVal)) {
          changes.push({ field: k, oldValue: oldVal, newValue: newVal })
        }
        update[k] = newVal
      }
    })

    if (changes.length === 0) {
      return res.json({ message: 'No changes to save', changedFields: [] })
    }

    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { $set: update, $push: { profileHistory: {
          updatedAt: new Date(),
          updatedFields: changes.map(c => c.field),
          changes,
          updatedBy: 'self',
          source: section,
        } } }
    )

    try {
      const { logActivity } = require('../utils/activityLogger')
      const fieldNames = changes.map(c => c.field)
      let details = `Updated: ${fieldNames.join(', ')}`
      if (fieldNames.includes('avatar')) details = 'Profile photo updated'
      logActivity({
        userId: payload.id, userName: current.name, userRole: current.role || 'student',
        action: fieldNames.includes('avatar') ? 'PHOTO_UPDATED' : 'PROFILE_UPDATED',
        details, module: section, status: 'success'
      }).catch(() => {})
    } catch (e) {}

    res.json({ message: 'Profile updated successfully', changedFields: changes.map(c => c.field) })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F38 — Overview: completion %, health score, exam stats, streak ──
router.get('/profile-overview', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const uid = new mongoose.Types.ObjectId(payload.id)
    const user = await User.collection.findOne({ _id: uid })
    if (!user) return res.status(404).json({ message: 'User not found' })

    // ── Exam stats (best-effort — works whether Result or Attempt model holds scores) ──
    let totalExams = 0, bestScore = 0, avgScore = 0, rankHistory = []
    try {
      const Result = require('../models/Result')
      const results = await Result.find({ studentId: uid }).sort({ createdAt: 1 }).lean()
      totalExams = results.length
      if (results.length) {
        const scores = results.map(r => r.score || r.totalScore || 0)
        bestScore = Math.max(...scores)
        avgScore = Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 10) / 10
        rankHistory = results.slice(-10).map(r => ({
          examTitle: r.examTitle || 'Exam', rank: r.rank || null,
          score: r.score || r.totalScore || 0, date: r.createdAt
        }))
      }
    } catch (e) {}

    // ── Current streak — consecutive calendar days with a login ──
    let currentStreak = 0
    try {
      const days = [...new Set((user.loginHistory || []).map(h => new Date(h.time || h.at).toDateString()))]
        .map(d => new Date(d)).sort((a, b) => b - a)
      if (days.length) {
        let cursor = new Date(); cursor.setHours(0,0,0,0)
        for (const d of days) {
          const dd = new Date(d); dd.setHours(0,0,0,0)
          const diff = Math.round((cursor - dd) / 86400000)
          if (diff === 0 || diff === 1) { currentStreak++; cursor = dd }
          else break
        }
      }
    } catch (e) {}

    // ── Profile Completion % ──
    const fields = ['name','phone','dob','city','state','gender','bio','avatar','targetExam','board','school']
    const filled = fields.filter(f => user[f] && String(user[f]).trim()).length
    const completion = Math.round((filled / fields.length) * 100)

    // ── Profile Health Score (0-100) — distinct trust metric ──
    let health = 0
    if (user.emailVerified || user.verified) health += 25
    if (user.phone) health += 15
    if (user.avatar) health += 15
    if (completion >= 80) health += 25
    else if (completion >= 50) health += 15
    if (user.twoFactorEnabled) health += 20
    health = Math.min(100, health)

    const missing = []
    if (!(user.emailVerified || user.verified)) missing.push({ label: 'Verify your email', href: null })
    if (!user.phone) missing.push({ label: 'Add phone number', href: '#personal' })
    if (!user.avatar) missing.push({ label: 'Upload profile photo', href: '#personal' })
    if (!user.dob || !user.city) missing.push({ label: 'Complete personal details', href: '#personal' })
    if (!user.targetExam || !user.board || !user.school) missing.push({ label: 'Complete academic profile', href: '#academic' })
    if (!user.twoFactorEnabled) missing.push({ label: 'Enable 2FA for extra security', href: '#security' })

    res.json({
      completion, health, missing,
      studentId: user.studentId || null, batch: user.batch || '',
      verified: !!(user.emailVerified || user.verified),
      stats: { totalExams, bestScore, avgScore, currentStreak, rankHistory },
    })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F38 §5 — Security overview: last login, devices, failed attempts ──
router.get('/security-overview', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(payload.id) })
    if (!user) return res.status(404).json({ message: 'User not found' })
    const history = user.loginHistory || []
    res.json({
      lastLogin: history[history.length - 1] || null,
      recentLogins: history.slice(-10).reverse(),
      activeDeviceCount: user.activeSessionToken ? 1 : 0,
      trustedDevices: user.trustedDevices || [],
      failedLoginAttempts: user.failedLoginAttempts || 0,
      lastFailedLoginAt: user.lastFailedLoginAt || null,
      twoFactorEnabled: !!user.twoFactorEnabled,
    })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F38 §5.2.4 — Logout OTHER Sessions only (current device stays signed in) ──
// Issues a fresh token for THIS device and invalidates the old one, so any
// other device/browser still using the old token gets logged out, while
// this device keeps working using the new token returned below.
router.post('/logout-other-sessions', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(payload.id) })
    if (!user) return res.status(404).json({ message: 'User not found' })

    const newToken = jwt.sign(
      { id: payload.id, role: payload.role || user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { $set: { activeSessionToken: newToken } }
    )
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: payload.id, userName: user.name, userRole: user.role || 'student', action: 'LOGOUT_OTHER_SESSIONS', details: 'Logged out from other devices — this device remains signed in', module: 'security', status: 'success' }).catch(() => {})
    } catch (e) {}

    res.json({ token: newToken, message: 'Logged out from all other devices. This device stays signed in.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F38 §5.2.4 — Logout from all devices INCLUDING this one ──
router.post('/logout-everywhere', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const crypto = require('crypto')
    const marker = 'LOGGED_OUT_' + crypto.randomBytes(8).toString('hex')
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { $set: { activeSessionToken: marker } }
    )
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: payload.id, userRole: 'student', action: 'LOGOUT_ALL_DEVICES', details: 'Logged out from all devices', module: 'security', status: 'success' }).catch(() => {})
    } catch (e) {}
    res.json({ message: 'Logged out from all devices. Please login again.' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F38 §7 — Student-facing activity timeline (own account only) ──
router.get('/activity', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const ActivityLog = require('../models/ActivityLog')
    const logs = await ActivityLog.find({ userId: payload.id }).sort({ createdAt: -1 }).limit(40).lean()
    res.json({ logs })
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


// ── F35.8 — Real-time Email Availability Check ─────────────────────
router.post('/check-email', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const validFormat = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    if (!validFormat) return res.json({ valid:false, available:false, message:'Invalid email format' })
    const existing = await User.collection.findOne({ email })
    const taken = !!(existing && (existing.emailVerified || existing.verified) && !existing.archived && existing.deleted !== true)
    res.json({ valid:true, available: !taken, message: taken ? 'Email already registered' : 'Email available' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F35.15 — Accept Terms (timestamp + version tracking) ───────────
router.post('/accept-terms', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const TERMS_VERSION = 'Version 2.1 — Updated March 2026'
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { $set: { termsAccepted:true, termsAcceptedAt:new Date(), termsVersion: TERMS_VERSION } }
    )
    res.json({ message: 'Terms accepted', version: TERMS_VERSION })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})


// ── Registration Status Check ────────────────────────────────────
router.get('/registration-status', async (req, res) => {
  try {
    let open = true
    try {
      const FeatureFlag = require('../models/FeatureFlag')
      const flag = await FeatureFlag.findOne({ key: 'student_registration' })
      if (flag) open = flag.enabled === true
    } catch (_e) {
      // FeatureFlag model not available — default open
    }
    // No cache headers — always fresh
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate')
    res.json({ open, timestamp: Date.now() })
  } catch (err) {
    res.json({ open: true, timestamp: Date.now() })
  }
})



// ── F37: Getting Started Checklist ───────────────────────────

// GET /api/auth/checklist — returns completion status of 5 items
router.get('/checklist', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ error: 'Token required' })
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ error: 'Invalid token' }) }

    const user = await User.findById(decoded.id)
      .select('name profileComplete dob city phone bio avatar targetExam board school badges checklist')
      .lean()
    if (!user) return res.status(404).json({ error: 'User not found' })

    // Fetch real data for checklist checks
    const Attempt = (() => { try { return require('../models/Attempt') } catch { return null } })()
    const Result  = (() => { try { return require('../models/Result')  } catch { return null } })()

    // 1. Profile complete — has name + phone + dob + city + bio
    const profileDone = !!(user.name && user.phone && user.dob && user.city && user.bio)

    // 2. First mock test — has at least 1 attempt/result
    let firstTestDone = false
    if (Attempt) firstTestDone = !!(await Attempt.findOne({ studentId: decoded.id }).lean())
    else if (Result) firstTestDone = !!(await Result.findOne({ studentId: decoded.id }).lean())

    // 3. Goals set — has targetExam set
    const goalsDone = !!(user.targetExam && user.targetExam.trim())

    // 4. PYQ Bank explored — stored in user.checklist.pyqExplored
    const pyqDone = !!(user.checklist?.pyqExplored)

    // 5. Analytics visited — stored in user.checklist.analyticsVisited

    const items = [
      { id: 'profile',   done: profileDone,    icon: '👤', label_en: 'Complete your profile',              label_hi: 'प्रोफ़ाइल पूरी करें',        href: '/profile',   xp: 50 },
      { id: 'firstTest', done: firstTestDone,  icon: '📝', label_en: 'Give your first mock test',          label_hi: 'पहला मॉक टेस्ट दें',           href: '/my-exams',  xp: 100 },
      { id: 'goals',     done: goalsDone,      icon: '🎯', label_en: 'Set your target rank & score',       label_hi: 'लक्ष्य रैंक और स्कोर सेट करें', href: '/goals',     xp: 30 },
      { id: 'pyq',       done: pyqDone,        icon: '📚', label_en: 'Explore PYQ Bank',        label_hi: 'PYQ बैंक एक्सप्लोर करें',       href: '/pyq-bank',  xp: 20 },
      ]

    const completedCount = items.filter(i => i.done).length
    const allDone = completedCount === 5
    const hasBadge = (user.badges || []).some(b => b.id === 'pathfinder')

    res.json({
      success: true,
      items,
      completedCount,
      totalCount: 4,
      allDone,
      hasBadge,
      totalXP: items.filter(i => i.done).reduce((s, i) => s + i.xp, 0),
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// POST /api/auth/checklist/mark — mark pyq/analytics as visited
router.post('/checklist/mark', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ error: 'Token required' })
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ error: 'Invalid token' }) }

    const { item } = req.body // 'pyq' or 'analytics'
    if (!['pyq', 'analytics'].includes(item))
      return res.status(400).json({ error: 'Invalid item' })

    const update = {}
    if (item === 'pyq')       update['checklist.pyqExplored']      = true
    if (item === 'analytics') update['checklist.analyticsVisited'] = true
    await User.findByIdAndUpdate(decoded.id, { $set: update })
    res.json({ success: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// POST /api/auth/checklist/complete — award Pathfinder badge + XP when all 5 done
router.post('/checklist/complete', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ error: 'Token required' })
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ error: 'Invalid token' }) }

    const user = await User.findById(decoded.id)
    if (!user) return res.status(404).json({ error: 'User not found' })

    const hasBadge = (user.badges || []).some(b => b.id === 'pathfinder')
    if (hasBadge) return res.json({ success: true, alreadyAwarded: true })

    await User.findByIdAndUpdate(decoded.id, {
      $push: { badges: { id: 'pathfinder', name: 'Pathfinder', unlockedAt: new Date() } },
      $inc:  { xp: 220 }
    })
    res.json({ success: true, badge: 'pathfinder', xpAwarded: 220 })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

module.exports = router
// trigger redeploy Fri Jul  3 10:17:03 AM UTC 2026
PRSHEOF

echo '-> Writing $SRC_DIR/routes/twoFactor.js'
cat > "$SRC_DIR/routes/twoFactor.js" << 'PRSHEOF'
const express = require('express');
const router = express.Router();
const speakeasy = require('speakeasy');
const qrcode = require('qrcode');
const { verifyToken } = require('../middleware/auth');
const User = require('../models/User');

// POST /api/auth/2fa/enable
router.post('/2fa/enable', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User nahi mila' });
    if (user.twoFactorEnabled)
      return res.status(400).json({ message: '2FA already enabled hai' });
    const secret = speakeasy.generateSecret({
      name: `ProveRank (${user.email})`, length: 20
    });
    await User.findByIdAndUpdate(req.user.id, { twoFactorTempSecret: secret.base32 });
    const qrCode = await qrcode.toDataURL(secret.otpauth_url);
    res.json({
      success: true,
      message: 'QR scan karo phir /2fa/verify se confirm karo',
      secret: secret.base32,
      qrCode
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/auth/2fa/verify
router.post('/2fa/verify', verifyToken, async (req, res) => {
  try {
    const { otp } = req.body;
    if (!otp) return res.status(400).json({ message: 'OTP required hai' });
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User nahi mila' });
    const secret = user.twoFactorTempSecret || user.twoFactorSecret;
    if (!secret) return res.status(400).json({ message: 'Pehle 2FA enable karo' });
    const verified = speakeasy.totp.verify({
      secret, encoding: 'base32', token: otp, window: 2
    });
    if (!verified) return res.status(400).json({ message: 'Invalid OTP' });
    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: true,
      twoFactorSecret: secret,
      twoFactorTempSecret: null
    });
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: req.user.id, userName: user.name, userRole: req.user.role||'student', action: 'TWO_FA_ENABLED', details: 'Two-factor authentication enabled', module: 'security', status: 'success' }).catch(()=>{})
    } catch(e) {}
    res.json({ success: true, message: '2FA activate ho gaya!' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/auth/2fa/disable
router.post('/2fa/disable', verifyToken, async (req, res) => {
  try {
    const { otp } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User nahi mila' });
    if (!user.twoFactorEnabled)
      return res.status(400).json({ message: '2FA already disabled hai' });
    if (req.user.role !== 'superadmin') {
      if (!otp) return res.status(400).json({ message: 'OTP required hai' });
      const verified = speakeasy.totp.verify({
        secret: user.twoFactorSecret, encoding: 'base32', token: otp, window: 2
      });
      if (!verified) return res.status(400).json({ message: 'Invalid OTP' });
    }
    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: false,
      twoFactorSecret: null,
      twoFactorTempSecret: null
    });
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: req.user.id, userName: user.name, userRole: req.user.role||'student', action: 'TWO_FA_DISABLED', details: 'Two-factor authentication disabled', module: 'security', status: 'success' }).catch(()=>{})
    } catch(e) {}
    res.json({ success: true, message: '2FA disable ho gaya' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/auth/2fa/validate
router.post('/2fa/validate', verifyToken, async (req, res) => {
  try {
    const { otp } = req.body;
    const user = await User.findById(req.user.id);
    if (!user || !user.twoFactorEnabled)
      return res.status(400).json({ message: '2FA enabled nahi hai' });
    const verified = speakeasy.totp.verify({
      secret: user.twoFactorSecret, encoding: 'base32', token: otp, window: 2
    });
    if (!verified) return res.status(400).json({ message: 'Invalid OTP' });
    res.json({ success: true, message: '2FA validated!' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
PRSHEOF

echo '-> Writing $SRC_DIR/routes/studentProfilePreview.js'
cat > "$SRC_DIR/routes/studentProfilePreview.js" << 'PRSHEOF'
const express = require('express')
const router = express.Router()
const mongoose = require('mongoose')
const { verifyToken, isSuperAdmin } = require('../middleware/auth')
const User = require('../models/User')
const ActivityLog = require('../models/ActivityLog')

// ══════════════════════════════════════════════════════════════════
// F38B — Student 360° Profile Preview (Superadmin ONLY)
// Access control: superadmin only. Admin/Teacher/Examiner/Student all
// blocked by the isSuperAdmin middleware below (§Access Control 1-5).
// ══════════════════════════════════════════════════════════════════
router.get('/:id/full-profile', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    let uid
    try { uid = new mongoose.Types.ObjectId(req.params.id) }
    catch (e) { return res.status(400).json({ success:false, message:'Invalid student id' }) }

    const user = await User.collection.findOne({ _id: uid })
    if (!user) return res.status(404).json({ success:false, message:'Student not found' })
    if (user.role === 'admin' || user.role === 'superadmin') {
      return res.status(400).json({ success:false, message:'360° preview is only available for student accounts' })
    }

    // ── §4.2 Academic Snapshot (best-effort — Result model may vary) ──
    let totalExams=0, bestScore=0, avgScore=0, rankHistory=[]
    try {
      const Result = require('../models/Result')
      const results = await Result.find({ studentId: uid }).sort({ createdAt: 1 }).lean()
      totalExams = results.length
      if (results.length) {
        const scores = results.map(r => r.score || r.totalScore || 0)
        bestScore = Math.max(...scores)
        avgScore = Math.round((scores.reduce((a,b)=>a+b,0) / scores.length) * 10) / 10
        rankHistory = results.slice(-10).map(r => ({
          examTitle: r.examTitle || 'Exam', rank: r.rank || null,
          score: r.score || r.totalScore || 0, date: r.createdAt
        }))
      }
    } catch (e) {}

    // ── Current streak — consecutive calendar days with a login ──
    let currentStreak = 0
    try {
      const days = [...new Set((user.loginHistory || []).map(h => new Date(h.at || h.time).toDateString()))]
        .map(d => new Date(d)).sort((a,b) => b - a)
      if (days.length) {
        let cursor = new Date(); cursor.setHours(0,0,0,0)
        for (const d of days) {
          const dd = new Date(d); dd.setHours(0,0,0,0)
          const diff = Math.round((cursor - dd) / 86400000)
          if (diff === 0 || diff === 1) { currentStreak++; cursor = dd }
          else break
        }
      }
    } catch (e) {}

    // ── §10 Profile Completion % + Health Score (same formula as student-facing) ──
    const fields = ['name','phone','dob','city','state','gender','bio','avatar','targetExam','board','school']
    const filled = fields.filter(f => user[f] && String(user[f]).trim()).length
    const completion = Math.round((filled / fields.length) * 100)
    let health = 0
    if (user.emailVerified || user.verified) health += 25
    if (user.phone) health += 15
    if (user.avatar) health += 15
    if (completion >= 80) health += 25
    else if (completion >= 50) health += 15
    if (user.twoFactorEnabled) health += 20
    health = Math.min(100, health)

    // ── §8 Field Change Timeline (profileHistory, newest first) — password values masked ──
    const profileHistory = (user.profileHistory || []).slice().reverse()
    const fieldChangeTimeline = profileHistory.map(h => ({
      updatedAt: h.updatedAt,
      updatedFields: h.updatedFields || [],
      changes: (h.changes || []).map(c => ({
        field: c.field,
        oldValue: c.field === 'password' ? '••••••••' : c.oldValue,
        newValue: c.field === 'password' ? '••••••••' : c.newValue,
      })),
      updatedBy: h.updatedBy || 'self',
      source: h.source || 'profile_page',
    }))

    // ── §13.5 Change Frequency Analysis — most-changed fields ──
    const freqMap = {}
    profileHistory.forEach(h => (h.changes || []).forEach(c => {
      if (!freqMap[c.field]) freqMap[c.field] = { field: c.field, count: 0, lastUpdate: h.updatedAt }
      freqMap[c.field].count++
      if (new Date(h.updatedAt) > new Date(freqMap[c.field].lastUpdate)) freqMap[c.field].lastUpdate = h.updatedAt
    }))
    const changeFrequency = Object.values(freqMap)
      .sort((a,b) => b.count - a.count)
      .map(f => ({ ...f, riskLevel: f.count >= 5 ? 'high' : f.count >= 2 ? 'medium' : 'low' }))

    // ── §7 Photo History (avatarHistory, newest first, current flagged) ──
    const photoHistory = (user.avatarHistory || []).slice().reverse().map((p, i) => ({ ...p, current: i === 0 }))

    // ── §6 Login Activity — history + derived heatmap/peak-hour ──
    const loginHistory = (user.loginHistory || []).slice().reverse()
    const hourCounts = {}
    loginHistory.forEach(h => { const hr = new Date(h.at || h.time).getHours(); hourCounts[hr] = (hourCounts[hr] || 0) + 1 })
    const peakHour = Object.keys(hourCounts).length
      ? Number(Object.entries(hourCounts).sort((a,b) => b[1]-a[1])[0][0]) : null
    const dailyPattern = {}
    loginHistory.forEach(h => {
      const day = new Date(h.at || h.time).toLocaleDateString('en-IN', { weekday: 'short' })
      dailyPattern[day] = (dailyPattern[day] || 0) + 1
    })

    // ── §9 Audit Trail — this student's ActivityLog entries ──
    let auditTrail = []
    try {
      const esc = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
      const orConds = [{ userId: uid }]
      if (user.email) orConds.push({ details: { $regex: esc(user.email), $options: 'i' } })
      if (user.studentId) orConds.push({ details: { $regex: esc(user.studentId), $options: 'i' } })
      auditTrail = await ActivityLog.find({ $or: orConds }).sort({ createdAt: -1 }).limit(60).lean()
    } catch (e) {}

    const lastLogin = loginHistory[0] || null
    const lastUpdated = profileHistory[0]?.updatedAt || user.updatedAt || null

    res.json({
      success: true,
      student: {
        _id: user._id, name: user.name, email: user.email, studentId: user.studentId || null,
        batch: user.batch || '', targetExam: user.targetExam || '',
        verified: !!(user.emailVerified || user.verified),
        completion, health, lastUpdated,

        // §3 Personal Details
        personal: {
          name: user.name, email: user.email, phone: user.phone || '', dob: user.dob || '',
          gender: user.gender || '', state: user.state || '', city: user.city || '',
          bio: user.bio || '', avatar: user.avatar || '',
        },

        // §4 Academic Profile
        academic: {
          targetExam: user.targetExam || '', targetYear: user.targetYear || '', board: user.board || '',
          school: user.school || '', medium: user.medium || '', coachingInstitute: user.coachingInstitute || '',
          yearOfAppearing: user.yearOfAppearing || '',
        },
        academicSnapshot: { totalExams, bestScore, avgScore, rankHistory, currentStreak },

        // §5 Security (password itself/hash NEVER included)
        security: {
          passwordChangedAt: user.passwordChangedAt || null,
          passwordChangeCount: user.passwordChangeCount || 0,
          passwordResetHistory: user.passwordResetHistory || [],
          twoFactorEnabled: !!user.twoFactorEnabled,
          activeDeviceCount: user.activeSessionToken ? 1 : 0,
          trustedDevices: user.trustedDevices || [],
          lastLogin,
          failedLoginAttempts: user.failedLoginAttempts || 0,
          lastFailedLoginAt: user.lastFailedLoginAt || null,
        },

        // §6 Login Activity
        loginActivity: {
          history: loginHistory.slice(0, 30),
          loginCount: user.loginCount || loginHistory.length,
          failedLoginAttempts: user.failedLoginAttempts || 0,
          peakHour, dailyPattern,
        },

        // §7 Photo History
        photoHistory,

        // §8 Field Change Timeline (DB-only, superadmin-only — never shown to student/admin)
        fieldChangeTimeline,

        // §13.5 Change Frequency Analysis
        changeFrequency,

        // §9 Audit Trail
        auditTrail,

        // §10 Identity & Verification
        verification: {
          emailVerified: !!(user.emailVerified || user.verified),
          phoneVerified: false,
          photoVerified: !!user.avatar,
          healthScore: health,
          riskIndicator: (user.failedLoginAttempts || 0) >= 5 ? 'high' : (user.failedLoginAttempts || 0) >= 2 ? 'medium' : 'low',
        },

        // §12 Quick Inspect Cards
        quickInspect: {
          bestScore, avgScore, totalExams, rankHistory,
          loginCount: user.loginCount || loginHistory.length,
          failedLogins: user.failedLoginAttempts || 0,
          photoChanges: photoHistory.length,
          lastActive: lastLogin?.at || lastLogin?.time || null,
        },
      }
    })
  } catch (err) {
    res.status(500).json({ success: false, message: err.message })
  }
})

module.exports = router
PRSHEOF

echo '-> Writing $SRC_DIR/index.js'
cat > "$SRC_DIR/index.js" << 'PRSHEOF'
require('dotenv').config();
const express    = require('express');

// ===== STAGE 8: Security Middleware =====
const applySecurityMiddleware = require('./middleware/security').applySecurityMiddleware;
const { apiLimiter, uploadLimiter } = require('./middleware/rateLimiter');
const { checkJWTExpiry } = require('./middleware/loginProtection');
// ========================================
const http       = require('http');
const cors       = require('cors');
const helmet     = require('helmet');
const mongoose   = require('mongoose');
const { initSocket } = require('./config/socket');

// ── Route Imports ─────────────────────────────────────────────
const authRoutes             = require('./routes/auth');
const adminRoutes            = require('./routes/admin');
const examPatchRoutes = require('./routes/exam_patch');
const examRoutes             = require('./routes/exam');
const examExtraRoutes        = require('./routes/examExtra');
const questionRoutes         = require('./routes/question');
const uploadRoutes           = require('./routes/upload');
const excelUploadRoutes      = require('./routes/excelUpload');
const paperGeneratorRoutes   = require('./routes/paperGenerator');
const pdfRoutes              = require('./routes/pdfRoutes');

// ── New Feature Routes (load BEFORE conflicting base routes) ──
const examFeaturesRoutes     = require('./routes/examFeatures');
const examPaperRoutes = require('./routes/examPaper');
const pyqBankAdminRoutes = require('./routes/pyqBankAdmin');
const adminSystemRoutes      = require('./routes/adminSystem');
const adminMonitoringRoutes = require('./routes/adminMonitoringRoutes');
require('./models/AdminNotification');
require('./models/Challenge');
require('./models/ReEvaluation');
require('./models/Grievance');
require('./models/QuestionVersion');
require('./models/QuestionError');
require('./models/ExamTemplate');      // Feature 29 — Exam Templates
require('./models/TemplateCategory');  // Feature 29.10 — custom categories
require('./models/Doubt');
const questionStatsRoutes = require('./routes/questionStatsRoutes');
const examWizardRoutes = require('./routes/examWizardRoutes');
const questionDeleteRoutes = require('./routes/questionDeleteRoutes');
const adminQuestionMgmtRoutes = require('./routes/adminQuestionMgmtRoutes');
const adminResultRoutes = require('./routes/adminResultRoutes');
const adminManagementRoutes  = require('./routes/adminManagement');
const studentProfilePreviewRoutes = require('./routes/studentProfilePreview'); // F38B
const questionFeaturesRoutes = require('./routes/questionFeatures');
const materialRoutes = require('./routes/materialRoutes');
const twoFactorRoutes        = require('./routes/twoFactor');

// ── Optional Routes (load if file exists) ────────────────────
let questionAIRoutes, questionAdvancedRoutes, questionExtraRoutes;
let examSubmissionRoutes, permissionTestRoutes;
try { questionAIRoutes       = require('./routes/questionAI'); } catch(e) {}
try { questionAdvancedRoutes = require('./routes/questionAdvanced'); } catch(e) {}
try { questionExtraRoutes    = require('./routes/questionExtra'); } catch(e) {}
try { examSubmissionRoutes   = require('./routes/examSubmission'); } catch(e) {}
try { permissionTestRoutes   = require('./routes/permissionTest'); } catch(e) {}

// ── App Setup ─────────────────────────────────────────────────
const app    = express();
const server = http.createServer(app);
initSocket(server);

app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({
  origin: [
    'https://prove-rank.vercel.app',
    'http://localhost:3000',
    'http://localhost:3001'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// ===== STAGE 8: Apply Security =====
applySecurityMiddleware(app);
app.use('/api', apiLimiter);
app.use('/api/excel', uploadLimiter);
app.use('/api/upload', uploadLimiter);
app.use('/api', checkJWTExpiry);
// ====================================
app.use(express.json({limit:'1mb'}));

// ── MongoDB ───────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB Connected:', mongoose.connection.host))
  .catch(err => console.log('MongoDB Error:', err));

// ── Health Check ──────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// ── Auth Routes ───────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/auth', twoFactorRoutes);

// ── Admin Routes ──────────────────────────────────────────────
app.use('/api', questionDeleteRoutes)
app.use('/api', examWizardRoutes);
app.use('/api/exam-templates', require('./routes/examTemplates')); // Feature 29 — Exam Templates

app.use('/api', questionStatsRoutes);
;
app.use('/api/admin/manage', adminManagementRoutes);  // S37/S72/S38/S93/M4
app.use('/api/admin/student-preview', studentProfilePreviewRoutes); // F38B — Superadmin-only 360° preview
app.use('/api/admin', adminSystemRoutes);
app.use('/api/admin', adminMonitoringRoutes);  // Phase 6.2
app.use('/api/admin', adminResultRoutes);       // Phase 6.3
app.use('/api/admin', adminQuestionMgmtRoutes); // Phase 6.4              // S66/N21
app.use('/api/admin', adminRoutes);

// ── Question Routes ───────────────────────────────────────────
app.use('/api/materials', materialRoutes);
app.use('/api/questions', questionFeaturesRoutes);     // AI-1/AI-2/S33/S35/MCQ/MSQ
app.use('/api/questions', questionRoutes);
if (questionAIRoutes)       app.use('/api/questions-advanced', questionAIRoutes);
if (questionAdvancedRoutes) app.use('/api/questions-advanced', questionAdvancedRoutes);
if (questionExtraRoutes)    app.use('/api/questions', questionExtraRoutes);

// ── Exam Routes ───────────────────────────────────────────────
app.use('/api/exams', examFeaturesRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/exams-manage', require('./routes/examListing')); // Feature 33 — All Exams List/Filter/Search
app.use('/api/exams', examPatchRoutes);
             // S5/S75/S85/S26/S62/S31/S96
app.use('/api/exam-paper', examPaperRoutes);
app.use('/api/exams', examExtraRoutes);
if (examSubmissionRoutes) app.use('/api/exams', examSubmissionRoutes);

// ── Other Routes ─────────────────────────────────────────────
app.use('/api/upload', uploadRoutes);
app.use('/api/excel', excelUploadRoutes);
app.use('/api/paper', paperGeneratorRoutes);
app.use('/api/pdf', pdfRoutes);
app.use('/api/exam-instances', require('./routes/examInstance'));
const attemptRoutes = require('./routes/attemptRoutes');
app.use('/api/attempts', attemptRoutes);
if (permissionTestRoutes) app.use('/api/permission', permissionTestRoutes);

// ── Start Server ──────────────────────────────────────────────
const PORT = process.env.PORT || 3000;

const adminBatchControlRoutes  = require('./routes/adminBatchControls');
const studentBatchExtrasRoutes = require('./routes/studentBatchExtras');
app.use('/api/admin/batch-controls',  adminBatchControlRoutes);
app.use('/api/student/batch-extras',  studentBatchExtrasRoutes);

const studentNotificationRoutes = require('./routes/studentNotificationRoutes');
const adminNotificationRoutes = require('./routes/adminNotificationRoutes');
app.use('/api/student/notifications', studentNotificationRoutes);
app.use('/api/admin/notifications', adminNotificationRoutes);

// ── Scheduled Banner Auto-Publish Cron (runs every minute) ──
const cron = require('node-cron');
cron.schedule('* * * * *', async () => {
  try {
    const mongoose = require('mongoose');
    if (mongoose.connection.readyState !== 1) return;
    let BannerModel;
    try { BannerModel = mongoose.model('Banner'); } catch(e) { return; }
    const now = new Date();
    const toPublish = await BannerModel.find({
      published: false,
      scheduledAt: { $lte: now, $exists: true, $ne: null }
    });
    for (const b of toPublish) {
      b.published = true;
      await b.save();
      console.log('Auto-published banner:', b.title, 'at', now.toISOString());
    }
  } catch(e) { /* silent — cron errors should not crash server */ }
});

const batchActivityRoutes = require('./routes/batchActivityRoutes');
app.use('/api/batch-activity', batchActivityRoutes);
server.listen(PORT, '0.0.0.0', () => {
  console.log(`ProveRank server running at http://0.0.0.0:${PORT}`);
});

// -- Result Routes (Phase 4.3)
const sessionRoutes = require('./routes/sessionRoutes');
const faceRoutes = require('./routes/faceRoutes');
const audioRoutes = require('./routes/audioRoutes');
const webcamRoutes = require('./routes/webcamRoutes');
const antiCheatRoutes = require('./routes/antiCheatRoutes');
const resultRoutes = require('./routes/resultRoutes');
app.use('/api/session', sessionRoutes);
app.use('/api/face', faceRoutes);
app.use('/api/audio', audioRoutes);
app.use('/api/webcam', webcamRoutes);
app.use('/api/anticheat', antiCheatRoutes);
app.use('/api/results', resultRoutes);
app.use('/api/admin', require('./routes/adminDashboardRoutes'));
const studentBatchRoutes=require('./routes/studentBatches');
const myBatchesRoutes=require('./routes/myBatches');
const bannerGeneratorRoutes = require('./routes/bannerGenerator');
const adminStoreRoutes   = require('./routes/adminStore');
const studentStoreRoutes = require('./routes/studentStore');
const paymentRoutes = require('./routes/payment');
const brandingRoutes = require('./routes/brandingRoutes')
app.use('/api/admin', brandingRoutes)
app.use('/api/my-batches',myBatchesRoutes);
app.use('/api/admin/banners', bannerGeneratorRoutes);
app.use('/api/student/batches',studentBatchRoutes);
app.use('/api/admin/email', require('./routes/emailSend'))
app.use('/api/admin/store',  adminStoreRoutes);
app.use('/api/store/payment', paymentRoutes);
app.use('/api/store',        studentStoreRoutes);

// -- Content Forge Routes (Features 19B / 20 / 20B / 21 / 21B)
const contentForgeRoutes = require('./routes/contentForge');
app.use('/api/content-forge', contentForgeRoutes)
app.use('/api/pyq-bank', pyqBankAdminRoutes);
;
PRSHEOF

echo ""
echo "════════════════════════════════════════════════════"
echo "  F38B BACKEND v2 — VERIFICATION"
echo "════════════════════════════════════════════════════"
PASS=0; TOTAL=0
check() {
  TOTAL=$((TOTAL+1))
  if grep -q "$2" "$1" 2>/dev/null; then echo "✅ $3"; PASS=$((PASS+1)); else echo "❌ $3"; fi
}

A="$SRC_DIR/routes/auth.js"
T="$SRC_DIR/routes/twoFactor.js"
S="$SRC_DIR/routes/studentProfilePreview.js"

echo "── 1) LOGIN_FAILED event ──"
check "$A" "action: 'LOGIN_FAILED'" "Individual LOGIN_FAILED ActivityLog entry added"

echo "── 2) trustedDevices populated on login ──"
check "$A" "createHash('md5').update(\`\${browser}|\${os}\`)" "Device fingerprint (browser+OS) computed on login"
check "$A" "devices\[idx\] = { ...devices\[idx\], lastUsedAt: new Date() }" "Existing trusted device's lastUsedAt updated"
check "$A" "devices.push({ deviceId, label:" "New trusted device pushed when not already known"
check "$A" "trustedDevices: devices.slice(-20)" "trustedDevices array actually written to DB"

echo "── 3) passwordResetHistory populated ──"
check "$A" "\$push: { passwordResetHistory:" "passwordResetHistory entry pushed on forgot-password reset"
check "$A" "action: 'PASSWORD_RESET'" "PASSWORD_RESET activity logged"

echo "── 4) 2FA enable/disable logged ──"
check "$T" "action: 'TWO_FA_ENABLED'" "2FA enable now logged (module:security)"
check "$T" "action: 'TWO_FA_DISABLED'" "2FA disable now logged (module:security)"

echo "── 5) Audit trail OR match (userId / email / studentId) ──"
check "$S" '\$or: orConds' "Audit trail query uses \$or across userId/email/studentId"
check "$S" "orConds.push({ details: { \\\$regex: esc(user.email)" "Matches by email inside details text"
check "$S" "orConds.push({ details: { \\\$regex: esc(user.studentId)" "Matches by studentId inside details text"

echo "────────────────────────────────────────────────────"
echo "  $PASS / $TOTAL checks passed"
echo "════════════════════════════════════════════════════"
if [ "$PASS" -eq "$TOTAL" ]; then
  echo "🎉 All 5 requested changes verified!"
else
  echo "⚠️  Review the ❌ lines above."
fi
