#!/bin/bash
# ProveRank — Completely remove the 2FA (Two-Factor Authentication) feature
# from backend + frontend.
#   1) src/models/User.js  — removed twoFactorEnabled, twoFactorSecret,
#      twoFactorTempSecret schema fields.
#   2) src/routes/auth.js  — removed the 2FA health-score bonus and the
#      "Enable 2FA for extra security" Overview prompt (profile-overview
#      route), removed twoFactorEnabled from security-overview response.
#      NOTE: /api/auth/2fa/enable, /verify, /disable routes were NOT found
#      anywhere in the auth.js you shared — the frontend was calling
#      endpoints that may not exist in the backend at all. If they live in
#      a different route file, share it and I'll remove those too.
#   3) app/profile/page.tsx — removed the entire 2FA UI card, its state,
#      and its 3 handler functions (enable2FA/verify2FA/disable2FA).
# Change Password, Device & Login Health, Sessions — all untouched.
set -e

cd ~/workspace 2>/dev/null || { echo "❌ ~/workspace not found"; exit 1; }

echo "🔎 Locating files via grep..."
USERJS=$(grep -rl "mongoose.model('User'" --include="*.js" . 2>/dev/null | grep -v node_modules | head -1)
AUTHJS=$(grep -rl "registration-status" --include="*.js" . 2>/dev/null | grep -v node_modules | head -1)
PROFILEPAGE=$(grep -rl "security-overview" --include="*.tsx" . 2>/dev/null | grep -v node_modules | head -1)

echo "User.js       : ${USERJS:-NOT FOUND}"
echo "auth.js       : ${AUTHJS:-NOT FOUND}"
echo "Profile page  : ${PROFILEPAGE:-NOT FOUND}"

if [ -z "$USERJS" ] || [ -z "$AUTHJS" ] || [ -z "$PROFILEPAGE" ]; then
  echo "❌ One or more files not found. Aborting — no changes made."
  exit 1
fi

TS=$(date +%s)
cp "$USERJS" "${USERJS}.bak_${TS}"
cp "$AUTHJS" "${AUTHJS}.bak_${TS}"
cp "$PROFILEPAGE" "${PROFILEPAGE}.bak_${TS}"
echo "✅ Backups created (.bak_${TS})"

cat > "$USERJS" << 'EOF_USERJS2'
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
  termsAcceptedAt:    { type: Date,    default: null },
  termsVersion:        { type: String, default: null },

  // ══════════════════════════════════════════════════════════
  // F52-F57 v2 — Waiting Room resume tracking (Rule 1.15.3/1.15.4)
  // NOTE: read/write via User.collection.findOne/updateOne (raw driver)
  // to match project convention (see D-36/D-37 in Brief) — same
  // pattern already used for enrolledBatches/enrolledBatchesMeta.
  // ══════════════════════════════════════════════════════════
  waitingRoomJoins: [{
    examId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    joinedAt: { type: Date, default: Date.now }
  }],

  // F52-F57 v2 — Per-exam T&C consent log (F55 §1.5/§2.5/§3.1)
  examConsents: [{
    examId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    version:    { type: String, default: '1.0' },
    acceptedAt: { type: Date, default: Date.now }
  }],

  // F52 §7 — Per-exam reminder toggle (server-persisted)
  examReminders: [{
    examId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    enabled:   { type: Boolean, default: true },
    updatedAt: { type: Date, default: Date.now }
  }],

}, { timestamps: true });

// password hashing removed — done in auth.js directly;

if (mongoose.models.User) delete mongoose.connection.models['User'];
module.exports = mongoose.model('User', userSchema, 'students');
EOF_USERJS2
echo "✅ User.js updated: $USERJS"

cat > "$AUTHJS" << 'EOF_AUTHJS3'
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
    // F-REG-FIX: check in-memory flag first; if not set yet (e.g. right after a
    // Render free-tier spin-down restart, before /admin/features has repopulated
    // global.featureFlags), fall back to the DB so a closed registration can't
    // silently reopen after a server restart.
    let regFlag = global.featureFlags?.['open_registration']
    if (regFlag === undefined) {
      try {
        const FeatureFlag = require('../models/FeatureFlag')
        const dbFlag = await FeatureFlag.findOne({ key: 'open_registration' })
        regFlag = dbFlag ? dbFlag.enabled === true : true
      } catch (_e) { regFlag = true }
    }
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
        streak: 0, loginHistory: [],
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

    const pushOps = { profileHistory: {
        updatedAt: new Date(),
        updatedFields: changes.map(c => c.field),
        changes,
        updatedBy: 'self',
        source: section,
      } }

    // F38B §7 — keep a version history of every profile photo change
    // (restored — this was accidentally dropped in the v2 rewrite)
    const avatarChange = changes.find(c => c.field === 'avatar')
    if (avatarChange) {
      pushOps.avatarHistory = {
        url: avatarChange.newValue,
        updatedAt: new Date(),
        updatedBy: 'self',
        source: section,
      }
    }

    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { $set: update, $push: pushOps }
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
    health = Math.min(100, health)

    const missing = []
    if (!(user.emailVerified || user.verified)) missing.push({ label: 'Verify your email', href: null })
    if (!user.phone) missing.push({ label: 'Add phone number', href: '#personal' })
    if (!user.avatar) missing.push({ label: 'Upload profile photo', href: '#personal' })
    if (!user.dob || !user.city) missing.push({ label: 'Complete personal details', href: '#personal' })
    if (!user.targetExam || !user.board || !user.school) missing.push({ label: 'Complete academic profile', href: '#academic' })

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
      // F-REG-FIX: correct field name is `enabled` (per FeatureFlag schema),
      // and $set/$setOnInsert instead of a bare replacement object — a bare
      // object here would REPLACE the whole document and silently drop
      // enabled/label/description on every call.
      await FF.findOneAndUpdate(
        { key: 'open_registration' },
        {
          $set: { enabled: Boolean(enabled), updatedAt: new Date() },
          $setOnInsert: { key: 'open_registration', label: 'Student Registration', description: 'Allow new student registrations. Toggle OFF to close (Superadmin only)' },
        },
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
      // F-REG-FIX: key must match what N21 panel + registration-control route
      // actually write ('open_registration'). It was 'student_registration'
      // here, a key nothing else ever wrote to — so this always read a
      // stale/non-existent document instead of the real toggle state.
      const flag = await FeatureFlag.findOne({ key: 'open_registration' })
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



module.exports = router
// trigger redeploy Fri Jul  3 10:17:03 AM UTC 2026
EOF_AUTHJS3
echo "✅ auth.js updated: $AUTHJS"

cat > "$PROFILEPAGE" << 'EOF_PROFILEPAGE2'
'use client'
import CopyBtn from '@/components/CopyBtn'
import { useState, useEffect, useRef, useMemo } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ══════════════════════════════════════════════════════════════
// F38 — Static option lists (per spec §4.2 / §4.3 / §4.4)
// ══════════════════════════════════════════════════════════════
const STATES = ['Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal','Delhi','Jammu & Kashmir','Ladakh','Chandigarh','Puducherry','Other']
const CITY_MAP: Record<string,string[]> = {
  'Delhi':['New Delhi','Dwarka','Rohini','Karol Bagh'],
  'Maharashtra':['Mumbai','Pune','Nagpur','Nashik','Thane'],
  'Karnataka':['Bengaluru','Mysuru','Hubli'],
  'Rajasthan':['Jaipur','Jodhpur','Udaipur','Kota'],
  'Uttar Pradesh':['Lucknow','Kanpur','Noida','Ghaziabad','Varanasi'],
  'Tamil Nadu':['Chennai','Coimbatore','Madurai'],
  'West Bengal':['Kolkata','Howrah','Siliguri'],
  'Gujarat':['Ahmedabad','Surat','Vadodara'],
  'Bihar':['Patna','Gaya'],
  'Telangana':['Hyderabad','Warangal'],
  'Punjab':['Ludhiana','Amritsar','Chandigarh'],
  'Madhya Pradesh':['Bhopal','Indore','Gwalior'],
  'Haryana':['Gurugram','Faridabad','Panipat'],
}
const TARGET_EXAMS = ['NEET UG','NEET PG','JEE Main','JEE Advanced','CUET UG','CUET PG','SSC','IIT JAM','Other']
const TARGET_YEARS = ['2025','2026','2027','2028','2029']
const BOARDS   = ['CBSE','Rajasthan','ICSE','UP Board','Maharashtra','Others']
const MEDIUMS  = ['English','Hindi','Other']
const YEAR_APPEAR = ['Class 11','Class 12','Dropper','Graduated']
const GENDERS  = ['Male','Female','Non-binary','Prefer not to say']
const TIMEZONES = ['Asia/Kolkata','Asia/Colombo','Asia/Dhaka','Asia/Kathmandu','UTC']

const PHONE_RX = /^(\+91)?[6-9]\d{9}$/

// ══════════════════════════════════════════════════════════════
// Small shared pieces
// ══════════════════════════════════════════════════════════════
function CompletionRing({ pct, size=96, color }: { pct:number; size?:number; color?:string }) {
  const r = (size-8)/2, circ = 2*Math.PI*r, dash = (pct/100)*circ
  const col = color || (pct>=80?'#00C48C':pct>=50?'#4D9FFF':'#FFD700')
  return (
    <svg width={size} height={size} style={{position:'absolute',top:0,left:0,transform:'rotate(-90deg)'}}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(120,140,170,0.18)" strokeWidth="4"/>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={col} strokeWidth="4"
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round" style={{transition:'stroke-dasharray .6s ease'}}/>
    </svg>
  )
}
function EyeBtn({show,toggle,sub}:{show:boolean;toggle:()=>void;sub:string}) {
  return (
    <button type="button" onClick={toggle} style={{position:'absolute',right:12,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',cursor:'pointer',color:sub,padding:0,display:'flex',alignItems:'center'}}>
      {show
        ? <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
        : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>}
    </button>
  )
}
function SectionCard({title,icon,children,theme}:{title?:string;icon?:string;children:any;theme:any}) {
  return (
    <div style={{background: theme.isDark?'rgba(255,255,255,0.03)':'rgba(37,99,235,0.02)', border:`1px solid ${theme.border}`, borderRadius:16, padding:'18px 16px', marginBottom:14}}>
      {title && <div style={{fontSize:13.5,fontWeight:700,color:theme.primary,marginBottom:14,display:'flex',alignItems:'center',gap:7}}>{icon}{title}</div>}
      {children}
    </div>
  )
}
function Field({label,children,theme}:{label:string;children:any;theme:any}) {
  return (<div style={{marginBottom:14}}><label style={{display:'block',fontSize:11,fontWeight:700,color:theme.sub,marginBottom:6,letterSpacing:'.02em'}}>{label}</label>{children}</div>)
}
function Toggle({on,onClick,dm,prim}:{on:boolean;onClick:()=>void;dm:boolean;prim:string}) {
  return (
    <button onClick={onClick} style={{width:44,height:24,borderRadius:99,border:'none',cursor:'pointer',background:on?prim:(dm?'rgba(255,255,255,.15)':'rgba(0,0,0,.15)'),position:'relative',transition:'background .2s',flexShrink:0}}>
      <div style={{position:'absolute',top:2,left:on?22:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left .2s'}}/>
    </button>
  )
}

function ProfileContent() {
  const { lang, darkMode:dm, user, toast, token, theme, setColorTheme } = useShell()
  const t = (en:string, hi:string) => lang==='en' ? en : hi
  const bdr = theme.border, txt = theme.text, sub = theme.sub, prim = theme.primary

  const inp:any = { width:'100%',padding:'11px 14px', background: dm?'rgba(0,22,40,.7)':'rgba(255,255,255,.9)',
    border:`1.5px solid ${bdr}`, borderRadius:11, color:txt, fontSize:13,
    fontFamily:'Inter,sans-serif', outline:'none', boxSizing:'border-box', transition:'border-color .2s' }
  const sel:any = { ...inp, cursor:'pointer' }
  const btnP:any = { background:`linear-gradient(135deg,${prim},${dm?'#0055CC':'#1D4ED8'})`, color:'#fff', border:'none', borderRadius:10, padding:'11px 22px', cursor:'pointer', fontWeight:700, fontSize:13, fontFamily:'Inter,sans-serif' }
  const btnGhost:any = { background:'transparent', border:`1.5px solid ${bdr}`, color:txt, borderRadius:10, padding:'10px 20px', cursor:'pointer', fontWeight:600, fontSize:13, fontFamily:'Inter,sans-serif' }

  const SECTIONS = [
    {id:'overview',  en:'Overview',          hi:'अवलोकन',        icon:'🏠'},
    {id:'personal',  en:'Personal Details',  hi:'व्यक्तिगत विवरण', icon:'👤'},
    {id:'academic',  en:'Academic Profile',  hi:'शैक्षणिक प्रोफ़ाइल', icon:'🎓'},
    {id:'security',  en:'Security',          hi:'सुरक्षा',        icon:'🔒'},
    {id:'preferences',en:'Preferences',      hi:'प्राथमिकताएं',   icon:'⚙️'},
  ]
  const [section, setSection] = useState('overview')
  const [pendingSection, setPendingSection] = useState<string|null>(null)
  const [isMobile, setIsMobile] = useState(true)
  const [idCardOpen, setIdCardOpen] = useState(false)
  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 900)
    check(); window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  // ── Core "me" state (own copy — refreshed after saves) ──
  const [me, setMe] = useState<any>(user || null)
  const loadMe = async () => {
    try { const r = await fetch(`${API}/api/auth/me`, { headers:{Authorization:`Bearer ${token}`} }); const d = await r.json(); if (d?._id) setMe(d) } catch {}
  }
  useEffect(() => { if (user) setMe(user) }, [user])
  useEffect(() => { if (token) loadMe() }, [token])

  // ── Overview data ──
  const [ov, setOv] = useState<any>(null)
  const loadOverview = async () => {
    try { const r = await fetch(`${API}/api/auth/profile-overview`, { headers:{Authorization:`Bearer ${token}`} }); const d = await r.json(); setOv(d) } catch {}
  }
  useEffect(() => { if (token) loadOverview() }, [token])

  // ── Security overview data ──
  const [sec, setSec] = useState<any>(null)
  const loadSecurity = async () => {
    try { const r = await fetch(`${API}/api/auth/security-overview`, { headers:{Authorization:`Bearer ${token}`} }); const d = await r.json(); setSec(d) } catch {}
  }
  useEffect(() => { if (token && section==='security') loadSecurity() }, [token, section])

  // ── Personal fields ──
  const [name,setName]=useState(''); const [phone,setPhone]=useState(''); const [dob,setDob]=useState('')
  const [city,setCity]=useState(''); const [state,setState2]=useState(''); const [gender,setGender]=useState('')
  const [bio,setBio]=useState(''); const [avatar,setAvatar]=useState(''); const [timezone,setTimezone]=useState('Asia/Kolkata')
  const [savingPersonal,setSavingPersonal]=useState(false); const [dirtyPersonal,setDirtyPersonal]=useState(false)
  const [editPersonal,setEditPersonal]=useState(false)

  // ── Academic fields ──
  const [targetExam,setTargetExam]=useState(''); const [targetYear,setTargetYear]=useState('')
  const [yearAppearing,setYearAppearing]=useState(''); const [board,setBoard]=useState('')
  const [school,setSchool]=useState(''); const [medium,setMedium]=useState(''); const [coaching,setCoaching]=useState('')
  const [savingAcademic,setSavingAcademic]=useState(false); const [dirtyAcademic,setDirtyAcademic]=useState(false)
  const [editAcademic,setEditAcademic]=useState(false)

  // ── Security — password fields ──
  const [cp,setCp]=useState(''); const [np,setNp]=useState(''); const [cnp,setCnp]=useState('')
  const [showCp,setShowCp]=useState(false); const [showNp,setShowNp]=useState(false); const [showCnp,setShowCnp]=useState(false)
  const [passSaving,setPassSaving]=useState(false)
  const [pwConfirmOpen,setPwConfirmOpen]=useState(false)

  // ── Preferences ──
  const [notifEmail,setNotifEmail]=useState(true); const [notifSms,setNotifSms]=useState(false); const [notifStudy,setNotifStudy]=useState(true)
  const [savingPrefs,setSavingPrefs]=useState(false); const [dirtyPrefs,setDirtyPrefs]=useState(false)
  const [editPrefs,setEditPrefs]=useState(false)
  const [photoViewerOpen,setPhotoViewerOpen]=useState(false)

  const initial = useRef<any>({})
  const [loaded, setLoaded] = useState(false)

  useEffect(() => {
    if (!me) return
    const tz = me.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Kolkata'
    setName(me.name||''); setPhone(me.phone||''); setDob(me.dob||''); setCity(me.city||'')
    setState2(me.state||''); setGender(me.gender||''); setBio(me.bio||''); setAvatar(me.avatar||'')
    setTimezone(tz)
    setTargetExam(me.targetExam||''); setTargetYear(me.targetYear||''); setYearAppearing(me.yearOfAppearing||'')
    setBoard(me.board||''); setSchool(me.school||''); setMedium(me.medium||''); setCoaching(me.coachingInstitute||'')
    if (me.preferences) { setNotifEmail(me.preferences.emailNotif ?? true); setNotifSms(me.preferences.smsNotif ?? false); setNotifStudy(me.preferences.studyReminder ?? true) }
    initial.current = {
      name:me.name||'', phone:me.phone||'', dob:me.dob||'', city:me.city||'', state:me.state||'', gender:me.gender||'', bio:me.bio||'', avatar:me.avatar||'', timezone:tz,
      targetExam:me.targetExam||'', targetYear:me.targetYear||'', yearAppearing:me.yearOfAppearing||'', board:me.board||'', school:me.school||'', medium:me.medium||'', coaching:me.coachingInstitute||'',
      notifEmail: me.preferences?.emailNotif ?? true, notifSms: me.preferences?.smsNotif ?? false, notifStudy: me.preferences?.studyReminder ?? true,
    }
    setLoaded(true)
  }, [me])

  // Dirty checks are guarded by `loaded` — prevents a false "unsaved changes"
  // prompt from firing before the initial snapshot has actually been set.
  useEffect(()=>{ if(!loaded) return; const i=initial.current; setDirtyPersonal(name!==i.name||phone!==i.phone||dob!==i.dob||city!==i.city||state!==i.state||gender!==i.gender||bio!==i.bio||avatar!==i.avatar||timezone!==i.timezone) },[loaded,name,phone,dob,city,state,gender,bio,avatar,timezone])
  useEffect(()=>{ if(!loaded) return; const i=initial.current; setDirtyAcademic(targetExam!==i.targetExam||targetYear!==i.targetYear||yearAppearing!==i.yearAppearing||board!==i.board||school!==i.school||medium!==i.medium||coaching!==i.coaching) },[loaded,targetExam,targetYear,yearAppearing,board,school,medium,coaching])
  useEffect(()=>{ if(!loaded) return; const i=initial.current; setDirtyPrefs(notifEmail!==i.notifEmail||notifSms!==i.notifSms||notifStudy!==i.notifStudy) },[loaded,notifEmail,notifSms,notifStudy])

  // ── F38 §11.4 — Live inline validation (as-you-type) ──
  const phoneWarning = useMemo(() => {
    if (!phone) return ''
    return PHONE_RX.test(phone.replace(/[\s-]/g,'')) ? '' : t('Enter a valid 10-digit Indian mobile number (e.g. +919876543210)','एक मान्य 10 अंकों का मोबाइल नंबर दर्ज करें')
  }, [phone])
  const dobWarning = useMemo(() => {
    if (!dob) return ''
    const d = new Date(dob)
    if (isNaN(d.getTime())) return t('Invalid date','अमान्य तिथि')
    if (d > new Date()) return t('Date of birth cannot be in the future','जन्म तिथि भविष्य में नहीं हो सकती')
    const age = new Date().getFullYear() - d.getFullYear()
    if (age < 5 || age > 100) return t('Please enter a realistic date of birth','कृपया एक सही जन्म तिथि दर्ज करें')
    return ''
  }, [dob])
  const cityWarning = useMemo(() => {
    if (state && !city) return t('Please select/enter your city','कृपया अपना शहर चुनें/दर्ज करें')
    return ''
  }, [state, city])

  // ── F38 §11.4.2.5 — Duplicate phone check (debounced, live) ──
  const [phoneDupWarning, setPhoneDupWarning] = useState('')
  const [phoneChecking, setPhoneChecking] = useState(false)
  useEffect(() => {
    if (!phone || phoneWarning) { setPhoneDupWarning(''); return }
    if (phone === initial.current.phone) { setPhoneDupWarning(''); return }
    setPhoneChecking(true)
    const h = setTimeout(async () => {
      try {
        const r = await fetch(`${API}/api/auth/check-phone?phone=${encodeURIComponent(phone.replace(/[\s-]/g,''))}`, { headers:{Authorization:`Bearer ${token}`} })
        const d = await r.json()
        setPhoneDupWarning(d.available ? '' : t('This phone number is already registered with another account','यह फ़ोन नंबर पहले से किसी अन्य खाते से पंजीकृत है'))
      } catch {} finally { setPhoneChecking(false) }
    }, 600)
    return () => clearTimeout(h)
  }, [phone, token, phoneWarning])

  const anyDirty = dirtyPersonal || dirtyAcademic || dirtyPrefs
  const goSection = (id:string) => {
    if (anyDirty && id !== section) {
      setPendingSection(id)
      return
    }
    setSection(id)
  }
  // Discard unsaved edits back to the last-saved snapshot, so the warning
  // doesn't fire again on the next section switch (bug fix: was repeating).
  const discardAndLeave = () => {
    const i = initial.current
    setName(i.name??''); setPhone(i.phone??''); setDob(i.dob??''); setCity(i.city??''); setState2(i.state??'')
    setGender(i.gender??''); setBio(i.bio??''); setAvatar(i.avatar??''); setTimezone(i.timezone??'')
    setTargetExam(i.targetExam??''); setTargetYear(i.targetYear??''); setYearAppearing(i.yearAppearing??'')
    setBoard(i.board??''); setSchool(i.school??''); setMedium(i.medium??''); setCoaching(i.coaching??'')
    setNotifEmail(i.notifEmail??true); setNotifSms(i.notifSms??false); setNotifStudy(i.notifStudy??true)
    setDirtyPersonal(false); setDirtyAcademic(false); setDirtyPrefs(false)
    setEditPersonal(false); setEditAcademic(false); setEditPrefs(false)
    if (pendingSection) setSection(pendingSection)
    setPendingSection(null)
  }
  const cancelLeave = () => setPendingSection(null)

  // ── Avatar upload (client-side resize → base64, then auto-save) ──
  // Clicking the avatar itself never opens the file picker directly anymore —
  // it only opens the Photo Viewer modal (large view). Uploading/removing a
  // photo happens only via the explicit buttons inside that modal.
  const fileRef = useRef<HTMLInputElement>(null)
  const [avatarBusy,setAvatarBusy]=useState(false)
  const onPickPhoto = () => fileRef.current?.click()
  const onPhotoChange = (e:any) => {
    const file = e.target.files?.[0]; if (!file) return
    if (!file.type.startsWith('image/')) { toast?.(t('Please select an image file','कृपया इमेज फ़ाइल चुनें'),'e'); return }
    setAvatarBusy(true)
    const prevAvatar = avatar
    const img = new Image()
    const reader = new FileReader()
    reader.onload = (ev:any) => {
      img.onload = async () => {
        // Fit the WHOLE photo inside a square canvas (no cropping/zooming) —
        // letterbox with a neutral fill so nothing gets cut off. Kept small
        // (220px, moderate quality) so the upload never gets silently
        // rejected/truncated by a request body-size limit.
        const size = 220
        const canvas = document.createElement('canvas'); canvas.width = size; canvas.height = size
        const ctx = canvas.getContext('2d')!
        const scale = Math.max(size/img.width, size/img.height)
        const w = img.width*scale, h = img.height*scale
        ctx.drawImage(img, (size-w)/2, (size-h)/2, w, h)
        const dataUrl = canvas.toDataURL('image/jpeg', 0.7)
        setAvatar(dataUrl)
        const ok = await saveSection({avatar:dataUrl}, 'personal')
        if (ok) {
          initial.current = { ...initial.current, avatar:dataUrl }
          setDirtyPersonal(false)
        } else {
          // Server rejected the save — revert so the page never shows a
          // photo that isn't actually persisted (was causing the
          // large-view-vs-small-view mismatch after a reload).
          setAvatar(prevAvatar)
          toast?.(t('Photo could not be saved. Please try a smaller image.','फोटो सहेजा नहीं जा सका। कृपया छोटी इमेज आज़माएं।'),'e')
        }
        setAvatarBusy(false)
      }
      img.src = ev.target.result
    }
    reader.readAsDataURL(file)
  }
  const removePhoto = async () => {
    setAvatarBusy(true)
    const prevAvatar = avatar
    setAvatar('')
    const ok = await saveSection({avatar:''}, 'personal')
    if (ok) { initial.current = { ...initial.current, avatar:'' }; setDirtyPersonal(false) }
    else setAvatar(prevAvatar)
    setAvatarBusy(false)
    setPhotoViewerOpen(false)
  }

  // ── Generic section save ──
  const saveSection = async (body:any, section_:string, onDone?:()=>void) => {
    try {
      const r = await fetch(`${API}/api/auth/me`, { method:'PATCH', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`}, body: JSON.stringify({ ...body, __section: section_ }) })
      const d = await r.json()
      if (!r.ok) { toast?.(d.message||t('Save failed','सहेजने में विफल'),'e'); return false }
      toast?.(t('Saved successfully!','सफलतापूर्वक सहेजा गया!'),'s')
      await loadMe(); await loadOverview()
      onDone?.()
      return true
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e'); return false }
  }

  const savePersonal = async () => {
    if (phone && !PHONE_RX.test(phone.replace(/[\s-]/g,''))) { toast?.(t('Invalid phone number','अमान्य फ़ोन नंबर'),'e'); return }
    if (phoneDupWarning) { toast?.(phoneDupWarning,'e'); return }
    if (dobWarning) { toast?.(dobWarning,'e'); return }
    if (dob) { const d=new Date(dob); if (isNaN(d.getTime())||d>new Date()) { toast?.(t('Invalid date of birth','अमान्य जन्म तिथि'),'e'); return } }
    setSavingPersonal(true)
    const ok = await saveSection({name,phone,dob,city,state,gender,bio,avatar,timezone}, 'personal')
    if (ok) {
      initial.current = { ...initial.current, name,phone,dob,city,state,gender,bio,avatar,timezone }
      setDirtyPersonal(false)
      setEditPersonal(false)
    }
    setSavingPersonal(false)
  }
  const saveAcademic = async () => {
    setSavingAcademic(true)
    const ok = await saveSection({targetExam,targetYear,yearOfAppearing:yearAppearing,board,school,medium,coachingInstitute:coaching}, 'academic')
    if (ok) {
      initial.current = { ...initial.current, targetExam,targetYear,yearAppearing,board,school,medium,coaching }
      setDirtyAcademic(false)
      setEditAcademic(false)
    }
    setSavingAcademic(false)
  }
  const savePrefs = async () => {
    setSavingPrefs(true)
    const ok = await saveSection({preferences:{emailNotif:notifEmail,smsNotif:notifSms,studyReminder:notifStudy}}, 'preferences')
    if (ok) {
      initial.current = { ...initial.current, notifEmail,notifSms,notifStudy }
      setDirtyPrefs(false)
      setEditPrefs(false)
    }
    setSavingPrefs(false)
  }
  const doChangePassword = async () => {
    if (!cp || !np || !cnp) { toast?.(t('Fill all password fields','सभी पासवर्ड फ़ील्ड भरें'),'e'); return }
    if (np.length < 6) { toast?.(t('New password min 6 characters','नया पासवर्ड कम से कम 6 अक्षर'),'e'); return }
    if (np !== cnp) { toast?.(t('Passwords do not match','पासवर्ड मेल नहीं खाते'),'e'); return }
    setPassSaving(true)
    try {
      const r = await fetch(`${API}/api/auth/change-password`, { method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`}, body: JSON.stringify({currentPassword:cp,newPassword:np}) })
      const d = await r.json()
      if (!r.ok) toast?.(d.message||t('Failed','विफल'),'e')
      else { toast?.(t('Password changed!','पासवर्ड बदल गया!'),'s'); setCp('');setNp('');setCnp(''); loadSecurity() }
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e') }
    setPassSaving(false)
    setPwConfirmOpen(false)
  }

  const logoutOtherSessions = async () => {
    const ok = window.confirm(t('This will sign you out from every other device. This device stays logged in. Continue?','यह आपको अन्य सभी डिवाइस से लॉगआउट कर देगा। यह डिवाइस लॉगिन रहेगा। जारी रखें?'))
    if (!ok) return
    try {
      const r = await fetch(`${API}/api/auth/logout-other-sessions`, { method:'POST', headers:{Authorization:`Bearer ${token}`} })
      const d = await r.json()
      if (!r.ok) { toast?.(d.message||t('Failed','विफल'),'e'); return }
      try { if (d.token) localStorage.setItem('pr_token', d.token) } catch {}
      toast?.(t('Logged out from other devices. This device stays signed in.','अन्य डिवाइस से लॉगआउट हो गया। यह डिवाइस लॉगिन है।'),'s')
      loadSecurity()
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e') }
  }

  const cancelEditPersonal = () => {
    const i = initial.current
    setName(i.name??''); setPhone(i.phone??''); setDob(i.dob??''); setCity(i.city??''); setState2(i.state??'')
    setGender(i.gender??''); setBio(i.bio??''); setAvatar(i.avatar??''); setTimezone(i.timezone??'')
    setDirtyPersonal(false); setEditPersonal(false)
  }
  const cancelEditAcademic = () => {
    const i = initial.current
    setTargetExam(i.targetExam??''); setTargetYear(i.targetYear??''); setYearAppearing(i.yearAppearing??'')
    setBoard(i.board??''); setSchool(i.school??''); setMedium(i.medium??''); setCoaching(i.coaching??'')
    setDirtyAcademic(false); setEditAcademic(false)
  }
  const cancelEditPrefs = () => {
    const i = initial.current
    setNotifEmail(i.notifEmail??true); setNotifSms(i.notifSms??false); setNotifStudy(i.notifStudy??true)
    setDirtyPrefs(false); setEditPrefs(false)
  }

  const cityOptions = state && CITY_MAP[state] ? CITY_MAP[state] : []
  const initials = (name||me?.name||'S').trim().charAt(0).toUpperCase()

  // ── Hero card (persistent, per spec §2.1 / §13.2) ──
  const heroEl = (
    <SectionCard theme={theme}>
      <div style={{display:'flex',gap:16,alignItems:'center',flexWrap:'wrap'}}>
        <div style={{position:'relative',width:84,height:84,flexShrink:0}}>
          <CompletionRing pct={ov?.completion ?? 0} size={84}/>
          <div onClick={()=>setPhotoViewerOpen(true)} style={{position:'absolute',top:6,left:6,width:72,height:72,borderRadius:'50%',background: avatar?'transparent':`linear-gradient(135deg,${prim},#00D4FF)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:26,fontWeight:800,color:'#fff',cursor:'pointer',overflow:'hidden'}}>
            {avatar ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover',display:'block'}}/> : initials}
            <div style={{position:'absolute',inset:0,background:'rgba(0,0,0,0.35)',opacity:0,transition:'opacity .2s',display:'flex',alignItems:'center',justifyContent:'center',fontSize:16}} className="avatar-hover">📷</div>
          </div>
          {avatarBusy && <div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,color:'#fff'}}>...</div>}
          <input ref={fileRef} type="file" accept="image/*" onChange={onPhotoChange} style={{display:'none'}}/>
        </div>
        <div style={{flex:1,minWidth:160}}>
          <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
            <div style={{fontSize:18,fontWeight:800,color:txt}}>{me?.name || '—'}</div>
            {ov?.verified && <span style={{fontSize:10,fontWeight:700,color:'#00C48C',background:'rgba(0,196,140,0.12)',padding:'2px 8px',borderRadius:99}}>✓ {t('Verified','सत्यापित')}</span>}
          </div>
          <div style={{display:'flex',alignItems:'center',gap:6,marginTop:4,flexWrap:'wrap'}}>
            <span style={{fontSize:11,color:sub}}>ID: {me?.studentId || '—'}</span>
            {me?.studentId && <CopyBtn text={me.studentId}/>}
          </div>
          <div style={{display:'flex',gap:6,marginTop:8,flexWrap:'wrap'}}>
            {ov?.batch && <span style={{fontSize:10,fontWeight:700,color:prim,background:theme.chipBg,padding:'3px 9px',borderRadius:99}}>📚 {ov.batch}</span>}
            {targetExam && <span style={{fontSize:10,fontWeight:700,color:'#FFD700',background:'rgba(255,215,0,0.1)',padding:'3px 9px',borderRadius:99}}>🎯 {targetExam}</span>}
          </div>
        </div>
        <button onClick={()=>goSection('personal')} style={btnGhost}>✏️ {t('Quick Edit','त्वरित संपादन')}</button>
      </div>
    </SectionCard>
  )

  // ══════════════════════════════════════════════════════════
  // OVERVIEW SECTION
  // ══════════════════════════════════════════════════════════
  const overviewEl = (
    <>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(130px,1fr))',gap:10,marginBottom:14}}>
        {[
          {lbl:t('Completion','पूर्णता'), val:`${ov?.completion ?? 0}%`, ico:'📊', col:'#4D9FFF'},
          {lbl:t('Health Score','स्वास्थ्य स्कोर'), val:`${ov?.health ?? 0}/100`, ico:'💚', col:'#00C48C'},
          {lbl:t('Total Exams','कुल परीक्षाएं'), val: ov?.stats?.totalExams ?? 0, ico:'📝', col:'#A855F7'},
          {lbl:t('Best Score','सर्वश्रेष्ठ स्कोर'), val: ov?.stats?.bestScore ?? 0, ico:'🏆', col:'#FFD700'},
          {lbl:t('Avg Score','औसत स्कोर'), val: ov?.stats?.avgScore ?? 0, ico:'📈', col:'#FF6B9D'},
          {lbl:t('Current Streak','वर्तमान लकीर'), val:`${ov?.stats?.currentStreak ?? 0}d`, ico:'🔥', col:'#FFA502'},
        ].map((s,i)=>(
          <div key={i} style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:14,padding:'14px 10px',textAlign:'center'}}>
            <div style={{fontSize:18}}>{s.ico}</div>
            <div style={{fontSize:16,fontWeight:800,color:s.col,marginTop:4}}>{s.val}</div>
            <div style={{fontSize:9.5,color:sub,marginTop:2,fontWeight:600}}>{s.lbl}</div>
          </div>
        ))}
      </div>

      {!!(ov?.missing?.length) && (
        <SectionCard theme={theme} title={t('Complete Your Profile','अपनी प्रोफ़ाइल पूरी करें')} icon="✅">
          {ov.missing.map((m:any,i:number)=>(
            <div key={i} onClick={()=> m.href && goSection(m.href.replace('#',''))} style={{display:'flex',alignItems:'center',gap:8,padding:'8px 4px',cursor:m.href?'pointer':'default',borderBottom: i<ov.missing.length-1?`1px solid ${bdr}`:'none'}}>
              <span style={{width:18,height:18,borderRadius:'50%',border:`1.5px solid ${prim}`,flexShrink:0}}/>
              <span style={{fontSize:12.5,color:txt}}>{m.label}</span>
              {m.href && <span style={{marginLeft:'auto',fontSize:11,color:prim}}>→</span>}
            </div>
          ))}
        </SectionCard>
      )}

      <SectionCard theme={theme} title={t('Quick Actions','त्वरित कार्रवाई')} icon="⚡">
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:10}}>
          {[
            {lbl:t('Edit Profile','प्रोफ़ाइल संपादित करें'),ico:'✏️',fn:()=>goSection('personal')},
            {lbl:t('Upload Photo','फोटो अपलोड करें'),ico:'📷',fn:onPickPhoto},
            {lbl:t('Change Password','पासवर्ड बदलें'),ico:'🔑',fn:()=>goSection('security')},
            {lbl:t('Manage Devices','डिवाइस प्रबंधित करें'),ico:'📱',fn:()=>goSection('security')},
            {lbl:t('Academic Snapshot','शैक्षणिक स्नैपशॉट'),ico:'🎓',fn:()=>goSection('academic')},
            {lbl:t('View ID Card','आईडी कार्ड देखें'),ico:'🪪',fn:()=>setIdCardOpen(true)},
          ].map((a,i)=>(
            <button key={i} onClick={a.fn} style={{...btnGhost,display:'flex',alignItems:'center',gap:8,justifyContent:'flex-start'}}>{a.ico} {a.lbl}</button>
          ))}
        </div>
      </SectionCard>

      <SectionCard theme={theme}>
        <button onClick={()=>setIdCardOpen(true)} style={{...btnGhost,width:'100%',display:'flex',alignItems:'center',justifyContent:'center',gap:8}}>🪪 {t('View Digital Student ID Card','डिजिटल छात्र आईडी कार्ड देखें')}</button>
      </SectionCard>
    </>
  )

  // ── Digital Student ID Card visual (used inline preview + modal) — §11.3 ──
  const idCardVisualEl = (
    <div style={{display:'flex',gap:16,alignItems:'center',flexWrap:'wrap',background: dm?'linear-gradient(135deg,#020816,#001830)':'linear-gradient(135deg,#EEF4FF,#DCEBFF)', borderRadius:14, padding:16, border:`1px solid ${bdr}`}}>
      <div style={{width:56,height:56,borderRadius:'50%',background: avatar?'transparent':`linear-gradient(135deg,${prim},#00D4FF)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:800,color:'#fff',flexShrink:0,overflow:'hidden'}}>{avatar ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover',display:'block'}}/> : initials}</div>
      <div style={{flex:1,minWidth:140}}>
        <div style={{fontWeight:800,fontSize:14,color: dm?'#F1F6FC':'#0F172A'}}>{me?.name}</div>
        <div style={{fontSize:11,color: dm?'#8DA2C0':'#51607A'}}>ID: {me?.studentId||'—'} {ov?.batch?`· ${ov.batch}`:''}</div>
        <div style={{fontSize:11,color: dm?'#8DA2C0':'#51607A'}}>{t('Target','लक्ष्य')}: {targetExam||'—'}</div>
        {ov?.verified && <span style={{fontSize:9,fontWeight:700,color:'#00C48C'}}>✓ {t('Verified','सत्यापित')}</span>}
      </div>
      {me?.studentId && <img alt="QR" width={72} height={72} style={{borderRadius:8,background:'#fff',padding:4}} src={`https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=${encodeURIComponent(me.studentId)}`}/>}
    </div>
  )


  // ══════════════════════════════════════════════════════════
  // PERSONAL SECTION
  // ══════════════════════════════════════════════════════════
  const personalEl = (
    <SectionCard theme={theme}>
      <div style={{display:'flex',justifyContent:'flex-end',marginBottom:12}}>
        {!editPersonal && <button style={btnGhost} onClick={()=>setEditPersonal(true)}>✏️ {t('Edit','संपादित करें')}</button>}
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:0}}>
        <Field label={t('FULL NAME','पूरा नाम')} theme={theme}><input style={{...inp,opacity:editPersonal?1:.65,cursor:editPersonal?'text':'not-allowed'}} disabled={!editPersonal} value={name} onChange={e=>setName(e.target.value)} placeholder={t('Your name','आपका नाम')}/></Field>
        <Field label={t('EMAIL (read-only)','ईमेल (केवल पढ़ने योग्य)')} theme={theme}><input style={{...inp,opacity:.6,cursor:'not-allowed'}} value={me?.email||''} disabled/></Field>
        <Field label={t('PHONE NUMBER','फ़ोन नंबर')} theme={theme}>
          <input style={{...inp, opacity:editPersonal?1:.65,cursor:editPersonal?'text':'not-allowed', borderColor: (phoneWarning||phoneDupWarning)?'#FF4757':bdr}} disabled={!editPersonal} value={phone} onChange={e=>setPhone(e.target.value)} placeholder="+91XXXXXXXXXX"/>
          {editPersonal && phoneChecking && <div style={{fontSize:10.5,color:sub,marginTop:4}}>{t('Checking availability...','उपलब्धता जांची जा रही है...')}</div>}
          {editPersonal && !phoneChecking && phoneWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {phoneWarning}</div>}
          {editPersonal && !phoneChecking && !phoneWarning && phoneDupWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {phoneDupWarning}</div>}
          {editPersonal && !phoneChecking && !phoneWarning && !phoneDupWarning && phone && phone!==initial.current.phone && <div style={{fontSize:10.5,color:'#00C48C',marginTop:4}}>✓ {t('Available','उपलब्ध')}</div>}
        </Field>
        <Field label={t('DATE OF BIRTH','जन्म तिथि')} theme={theme}>
          <input type="date" style={{...inp, opacity:editPersonal?1:.65,cursor:editPersonal?'text':'not-allowed', borderColor: dobWarning?'#FF4757':bdr}} disabled={!editPersonal} value={dob} onChange={e=>setDob(e.target.value)} max={new Date().toISOString().split('T')[0]}/>
          {editPersonal && dobWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {dobWarning}</div>}
        </Field>
        <Field label={t('GENDER','लिंग')} theme={theme}>
          <select style={{...sel,opacity:editPersonal?1:.65,cursor:editPersonal?'pointer':'not-allowed'}} disabled={!editPersonal} value={gender} onChange={e=>setGender(e.target.value)}><option value="">{t('Select','चुनें')}</option>{GENDERS.map(g=><option key={g} value={g}>{g}</option>)}</select>
        </Field>
        <Field label={t('STATE','राज्य')} theme={theme}>
          <select style={{...sel,opacity:editPersonal?1:.65,cursor:editPersonal?'pointer':'not-allowed'}} disabled={!editPersonal} value={state} onChange={e=>{setState2(e.target.value); setCity('')}}><option value="">{t('Select','चुनें')}</option>{STATES.map(s=><option key={s} value={s}>{s}</option>)}</select>
        </Field>
        <Field label={t('CITY','शहर')} theme={theme}>
          <input style={{...inp, opacity:editPersonal?1:.65,cursor:editPersonal?'text':'not-allowed', borderColor: cityWarning?'#FF4757':bdr}} disabled={!editPersonal} list="city-suggest" value={city} onChange={e=>setCity(e.target.value)} placeholder={t('Your city','आपका शहर')}/>
          <datalist id="city-suggest">{cityOptions.map(c=><option key={c} value={c}/>)}</datalist>
          {editPersonal && cityWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {cityWarning}</div>}
        </Field>
        <Field label={t('TIMEZONE','समय क्षेत्र')} theme={theme}>
          <select style={{...sel,opacity:editPersonal?1:.65,cursor:editPersonal?'pointer':'not-allowed'}} disabled={!editPersonal} value={timezone} onChange={e=>setTimezone(e.target.value)}>{TIMEZONES.map(z=><option key={z} value={z}>{z}</option>)}</select>
        </Field>
      </div>
      <Field label={`${t('SHORT BIO','संक्षिप्त परिचय')} (${bio.length}/160)`} theme={theme}>
        <textarea style={{...inp,minHeight:70,resize:'vertical',opacity:editPersonal?1:.65,cursor:editPersonal?'text':'not-allowed'}} disabled={!editPersonal} value={bio} maxLength={160} onChange={e=>setBio(e.target.value)} placeholder={t('Tell us about yourself...','अपने बारे में बताएं...')}/>
      </Field>
      {editPersonal && (
        <div style={{display:'flex',gap:10,marginTop:6}}>
          <button style={{...btnP,opacity:dirtyPersonal?1:.5,cursor:dirtyPersonal?'pointer':'not-allowed'}} disabled={!dirtyPersonal||savingPersonal} onClick={savePersonal}>{savingPersonal?t('Saving...','सहेज रहे हैं...'):t('Save Personal Details','व्यक्तिगत विवरण सहेजें')}</button>
          <button style={btnGhost} onClick={cancelEditPersonal}>{t('Cancel','रद्द करें')}</button>
        </div>
      )}
    </SectionCard>
  )

  // ══════════════════════════════════════════════════════════
  // ACADEMIC SECTION
  // ══════════════════════════════════════════════════════════
  const academicEl = (
    <>
      <SectionCard theme={theme}>
        <div style={{display:'flex',justifyContent:'flex-end',marginBottom:12}}>
          {!editAcademic && <button style={btnGhost} onClick={()=>setEditAcademic(true)}>✏️ {t('Edit','संपादित करें')}</button>}
        </div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:0}}>
          <Field label={t('TARGET EXAM','लक्षित परीक्षा')} theme={theme}><select style={{...sel,opacity:editAcademic?1:.65,cursor:editAcademic?'pointer':'not-allowed'}} disabled={!editAcademic} value={targetExam} onChange={e=>setTargetExam(e.target.value)}><option value="">{t('Select','चुनें')}</option>{TARGET_EXAMS.map(x=><option key={x} value={x}>{x}</option>)}</select></Field>
          <Field label={t('TARGET YEAR','लक्षित वर्ष')} theme={theme}><select style={{...sel,opacity:editAcademic?1:.65,cursor:editAcademic?'pointer':'not-allowed'}} disabled={!editAcademic} value={targetYear} onChange={e=>setTargetYear(e.target.value)}><option value="">{t('Select','चुनें')}</option>{TARGET_YEARS.map(y=><option key={y} value={y}>{y}</option>)}</select></Field>
          <Field label={t('BOARD','बोर्ड')} theme={theme}><select style={{...sel,opacity:editAcademic?1:.65,cursor:editAcademic?'pointer':'not-allowed'}} disabled={!editAcademic} value={board} onChange={e=>setBoard(e.target.value)}><option value="">{t('Select','चुनें')}</option>{BOARDS.map(b=><option key={b} value={b}>{b}</option>)}</select></Field>
          <Field label={t('MEDIUM','माध्यम')} theme={theme}><select style={{...sel,opacity:editAcademic?1:.65,cursor:editAcademic?'pointer':'not-allowed'}} disabled={!editAcademic} value={medium} onChange={e=>setMedium(e.target.value)}><option value="">{t('Select','चुनें')}</option>{MEDIUMS.map(m=><option key={m} value={m}>{m}</option>)}</select></Field>
          <Field label={t('YEAR OF APPEARING','उपस्थित होने का वर्ष')} theme={theme}><select style={{...sel,opacity:editAcademic?1:.65,cursor:editAcademic?'pointer':'not-allowed'}} disabled={!editAcademic} value={yearAppearing} onChange={e=>setYearAppearing(e.target.value)}><option value="">{t('Select','चुनें')}</option>{YEAR_APPEAR.map(y=><option key={y} value={y}>{y}</option>)}</select></Field>
          <Field label={t('SCHOOL / COLLEGE NAME','स्कूल/कॉलेज का नाम')} theme={theme}><input style={{...inp,opacity:editAcademic?1:.65,cursor:editAcademic?'text':'not-allowed'}} disabled={!editAcademic} value={school} onChange={e=>setSchool(e.target.value)} placeholder={t('e.g. DPS RK Puram','जैसे DPS RK Puram')}/></Field>
          <Field label={t('COACHING INSTITUTE (optional)','कोचिंग संस्थान (वैकल्पिक)')} theme={theme}><input style={{...inp,opacity:editAcademic?1:.65,cursor:editAcademic?'text':'not-allowed'}} disabled={!editAcademic} value={coaching} onChange={e=>setCoaching(e.target.value)} placeholder={t('Optional','वैकल्पिक')}/></Field>
        </div>
        {editAcademic && (
          <div style={{display:'flex',gap:10,marginTop:6}}>
            <button style={{...btnP,opacity:dirtyAcademic?1:.5,cursor:dirtyAcademic?'pointer':'not-allowed'}} disabled={!dirtyAcademic||savingAcademic} onClick={saveAcademic}>{savingAcademic?t('Saving...','सहेज रहे हैं...'):t('Save Academic Profile','शैक्षणिक प्रोफ़ाइल सहेजें')}</button>
            <button style={btnGhost} onClick={cancelEditAcademic}>{t('Cancel','रद्द करें')}</button>
          </div>
        )}
      </SectionCard>

      <SectionCard theme={theme} title={t('Academic Snapshot','शैक्षणिक स्नैपशॉट')} icon="📊">
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(120px,1fr))',gap:10}}>
          {[
            {lbl:t('Total Exams','कुल परीक्षाएं'),val:ov?.stats?.totalExams??0,col:'#A855F7'},
            {lbl:t('Best Score','सर्वश्रेष्ठ स्कोर'),val:ov?.stats?.bestScore??0,col:'#FFD700'},
            {lbl:t('Average Score','औसत स्कोर'),val:ov?.stats?.avgScore??0,col:'#4D9FFF'},
            {lbl:t('Current Streak','वर्तमान लकीर'),val:`${ov?.stats?.currentStreak??0}d`,col:'#FFA502'},
          ].map((s,i)=>(
            <div key={i} style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'12px 8px',textAlign:'center'}}>
              <div style={{fontSize:16,fontWeight:800,color:s.col}}>{s.val}</div>
              <div style={{fontSize:9.5,color:sub,marginTop:2,fontWeight:600}}>{s.lbl}</div>
            </div>
          ))}
        </div>
        {!!(ov?.stats?.rankHistory?.length) && (
          <div style={{marginTop:14}}>
            <div style={{fontSize:11,fontWeight:700,color:sub,marginBottom:8}}>{t('Rank History','रैंक इतिहास')}</div>
            {ov.stats.rankHistory.map((r:any,i:number)=>(
              <div key={i} style={{display:'flex',justifyContent:'space-between',fontSize:12,padding:'6px 0',borderBottom: i<ov.stats.rankHistory.length-1?`1px solid ${bdr}`:'none',color:txt}}>
                <span>{r.examTitle}</span><span style={{color:prim,fontWeight:700}}>{r.rank?`#${r.rank}`:'—'} · {r.score}</span>
              </div>
            ))}
          </div>
        )}
      </SectionCard>
    </>
  )

  // ══════════════════════════════════════════════════════════
  // SECURITY SECTION
  // ══════════════════════════════════════════════════════════
  const securityEl = (
    <>
      <SectionCard theme={theme} title={t('Change Password','पासवर्ड बदलें')} icon="🔑">
        <Field label={t('CURRENT PASSWORD','वर्तमान पासवर्ड')} theme={theme}><div style={{position:'relative'}}><input type={showCp?'text':'password'} style={inp} value={cp} onChange={e=>setCp(e.target.value)}/><EyeBtn show={showCp} toggle={()=>setShowCp(!showCp)} sub={sub}/></div></Field>
        <Field label={t('NEW PASSWORD','नया पासवर्ड')} theme={theme}><div style={{position:'relative'}}><input type={showNp?'text':'password'} style={inp} value={np} onChange={e=>setNp(e.target.value)}/><EyeBtn show={showNp} toggle={()=>setShowNp(!showNp)} sub={sub}/></div></Field>
        <Field label={t('CONFIRM PASSWORD','पासवर्ड की पुष्टि करें')} theme={theme}><div style={{position:'relative'}}><input type={showCnp?'text':'password'} style={inp} value={cnp} onChange={e=>setCnp(e.target.value)}/><EyeBtn show={showCnp} toggle={()=>setShowCnp(!showCnp)} sub={sub}/></div></Field>
        <button style={btnP} disabled={passSaving} onClick={()=>setPwConfirmOpen(true)}>{passSaving?t('Saving...','सहेज रहे हैं...'):t('Change Password','पासवर्ड बदलें')}</button>
        {pwConfirmOpen && (
          <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,.6)',zIndex:200,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setPwConfirmOpen(false)}>
            <div onClick={e=>e.stopPropagation()} style={{background: dm?'#0A0E17':'#fff', border:`1px solid ${bdr}`, borderRadius:16, padding:24, maxWidth:340, width:'100%'}}>
              <div style={{fontWeight:800,fontSize:15,color:txt,marginBottom:8}}>⚠️ {t('Confirm Password Change','पासवर्ड परिवर्तन की पुष्टि करें')}</div>
              <div style={{fontSize:12.5,color:sub,marginBottom:18}}>{t('Are you sure you want to change your password?','क्या आप वाकई अपना पासवर्ड बदलना चाहते हैं?')}</div>
              <div style={{display:'flex',gap:10}}>
                <button style={btnP} onClick={doChangePassword}>{t('Yes, Change It','हां, बदलें')}</button>
                <button style={btnGhost} onClick={()=>setPwConfirmOpen(false)}>{t('Cancel','रद्द करें')}</button>
              </div>
            </div>
          </div>
        )}
      </SectionCard>

      <SectionCard theme={theme} title={t('Device & Login Health','डिवाइस और लॉगिन स्वास्थ्य')} icon="📱">
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:10,marginBottom:14}}>
          <div style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'10px 12px'}}>
            <div style={{fontSize:9.5,color:sub,fontWeight:700}}>{t('LAST LOGIN','अंतिम लॉगिन')}</div>
            <div style={{fontSize:12,color:txt,marginTop:3}}>{sec?.lastLogin ? new Date(sec.lastLogin.at||sec.lastLogin.time).toLocaleString() : '—'}</div>
            <div style={{fontSize:10.5,color:sub}}>{sec?.lastLogin?.city ? `${sec.lastLogin.city}, ${sec.lastLogin.country}` : ''}</div>
          </div>
          <div style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'10px 12px'}}>
            <div style={{fontSize:9.5,color:sub,fontWeight:700}}>{t('ACTIVE DEVICES','सक्रिय डिवाइस')}</div>
            <div style={{fontSize:16,color:'#00C48C',fontWeight:800}}>{sec?.activeDeviceCount ?? 0}</div>
          </div>
          <div style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'10px 12px'}}>
            <div style={{fontSize:9.5,color:sub,fontWeight:700}}>{t('FAILED ATTEMPTS','असफल प्रयास')}</div>
            <div style={{fontSize:16,fontWeight:800,color: (sec?.failedLoginAttempts||0)>3?'#FF4757':txt}}>{sec?.failedLoginAttempts ?? 0}</div>
          </div>
        </div>
        <button style={{...btnGhost,borderColor:'rgba(255,71,87,0.4)',color:'#FF6B6B'}} onClick={logoutOtherSessions}>🚪 {t('Logout from Other Devices','अन्य डिवाइस से लॉगआउट करें')}</button>
      </SectionCard>
    </>
  )

  // ══════════════════════════════════════════════════════════
  // PREFERENCES SECTION
  // ══════════════════════════════════════════════════════════
  const preferencesEl = (
    <SectionCard theme={theme}>
      <div style={{display:'flex',justifyContent:'flex-end',marginBottom:4}}>
        {!editPrefs && <button style={btnGhost} onClick={()=>setEditPrefs(true)}>✏️ {t('Edit','संपादित करें')}</button>}
      </div>
      {[
        {lbl:t('Email Notifications','ईमेल सूचनाएं'),val:notifEmail,fn:()=>setNotifEmail(!notifEmail)},
        {lbl:t('SMS Notifications','SMS सूचनाएं'),val:notifSms,fn:()=>setNotifSms(!notifSms)},
        {lbl:t('Study Reminders','अध्ययन अनुस्मारक'),val:notifStudy,fn:()=>setNotifStudy(!notifStudy)},
      ].map((p,i)=>(
        <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'12px 4px',borderBottom:`1px solid ${bdr}`,opacity:editPrefs?1:.65}}>
          <span style={{fontSize:13,color:txt,fontWeight:600}}>{p.lbl}</span><Toggle on={p.val} onClick={editPrefs?p.fn:()=>{}} dm={dm} prim={prim}/>
        </div>
      ))}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'12px 4px',borderBottom:`1px solid ${bdr}`}}>
        <span style={{fontSize:13,color:txt,fontWeight:600}}>{t('Theme','थीम')}</span>
        <button onClick={()=>setColorTheme(dm?'light':'dark')} style={{display:'flex',alignItems:'center',gap:6,background:theme.chipBg,border:`1.5px solid ${bdr}`,borderRadius:99,padding:'6px 14px',cursor:'pointer',fontSize:12,fontWeight:700,color:prim}}>
          {dm?'🌙':'☀️'} {dm?t('Dark','डार्क'):t('Light','लाइट')}
        </button>
      </div>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'12px 4px'}}>
        <span style={{fontSize:13,color:txt,fontWeight:600}}>{t('Language','भाषा')}</span>
        <span style={{fontSize:12,color:sub}}>{lang==='en'?'English':'हिन्दी'}</span>
      </div>
      {editPrefs && (
        <div style={{display:'flex',gap:10,marginTop:14}}>
          <button style={{...btnP,opacity:dirtyPrefs?1:.5,cursor:dirtyPrefs?'pointer':'not-allowed'}} disabled={!dirtyPrefs||savingPrefs} onClick={savePrefs}>{savingPrefs?t('Saving...','सहेज रहे हैं...'):t('Save Preferences','प्राथमिकताएं सहेजें')}</button>
          <button style={btnGhost} onClick={cancelEditPrefs}>{t('Cancel','रद्द करें')}</button>
        </div>
      )}
    </SectionCard>
  )

  return (
    <div style={{maxWidth: isMobile?880:1040, margin:'0 auto'}}>
      <div style={{fontSize:20,fontWeight:800,marginBottom:4,color:txt}}>👤 {t('My Profile','मेरी प्रोफ़ाइल')}</div>
      <div style={{fontSize:12.5,color:sub,marginBottom:18}}>{t('Manage your personal, academic, and security settings','अपनी व्यक्तिगत, शैक्षणिक और सुरक्षा सेटिंग्स प्रबंधित करें')}</div>

      {heroEl}

      {isMobile ? (
        <>
          {/* ── Mobile: swipe-friendly horizontal chips (§1.2.2 / §13.1.3) ── */}
          <div style={{display:'flex',gap:8,overflowX:'auto',marginBottom:16,paddingBottom:4,WebkitOverflowScrolling:'touch'}}>
            {SECTIONS.map(s=>{
              const active = section===s.id
              return (
                <button key={s.id} onClick={()=>goSection(s.id)} style={{flexShrink:0,display:'flex',alignItems:'center',gap:6,padding:'9px 16px',borderRadius:99,border:`1.5px solid ${active?prim:bdr}`,background: active?theme.navActive:'transparent',color: active?prim:txt,fontWeight:active?700:600,fontSize:12.5,cursor:'pointer',whiteSpace:'nowrap'}}>
                  {s.icon} {lang==='en'?s.en:s.hi}
                </button>
              )
            })}
          </div>
          {section==='overview' && overviewEl}
          {section==='personal' && personalEl}
          {section==='academic' && academicEl}
          {section==='security' && securityEl}
          {section==='preferences' && preferencesEl}
        </>
      ) : (
        <div style={{display:'flex',gap:22,alignItems:'flex-start'}}>
          {/* ── Desktop: real left section rail (§1.2.1 / §12.1.1) ── */}
          <div style={{width:210,flexShrink:0,position:'sticky',top:76,background: theme.isDark?'rgba(255,255,255,0.03)':'rgba(37,99,235,0.02)',border:`1px solid ${bdr}`,borderRadius:16,padding:10}}>
            {SECTIONS.map(s=>{
              const active = section===s.id
              return (
                <button key={s.id} onClick={()=>goSection(s.id)} style={{width:'100%',display:'flex',alignItems:'center',gap:10,padding:'11px 14px',borderRadius:11,border:'none',background: active?theme.navActive:'transparent',color: active?prim:txt,fontWeight:active?700:600,fontSize:13,cursor:'pointer',marginBottom:3,textAlign:'left'}}>
                  <span style={{fontSize:16}}>{s.icon}</span> {lang==='en'?s.en:s.hi}
                  {active && <span style={{marginLeft:'auto',width:6,height:6,borderRadius:'50%',background:prim}}/>}
                </button>
              )
            })}
          </div>
          <div style={{flex:1,minWidth:0}}>
            {section==='overview' && overviewEl}
            {section==='personal' && personalEl}
            {section==='academic' && academicEl}
            {section==='security' && securityEl}
            {section==='preferences' && preferencesEl}
          </div>
        </div>
      )}

      {/* ── Photo Viewer modal — large view + explicit Upload/Remove actions ── */}
      {photoViewerOpen && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,.75)',zIndex:280,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setPhotoViewerOpen(false)}>
          <div onClick={e=>e.stopPropagation()} style={{maxWidth:300,width:'100%',textAlign:'center'}}>
            <div style={{width:200,height:200,borderRadius:'50%',margin:'0 auto 22px',background: avatar?'transparent':`linear-gradient(135deg,${prim},#00D4FF)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:60,fontWeight:800,color:'#fff',border:'4px solid rgba(255,255,255,0.2)',overflow:'hidden'}}>
              {avatar ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover',display:'block'}}/> : initials}
              {avatarBusy && <div style={{position:'absolute'}}>...</div>}
            </div>
            <div style={{display:'flex',gap:10,justifyContent:'center',flexWrap:'wrap'}}>
              <button style={btnP} disabled={avatarBusy} onClick={onPickPhoto}>📤 {t('Upload New Photo','नई फोटो अपलोड करें')}</button>
              {avatar && <button style={{...btnGhost,borderColor:'rgba(255,71,87,.4)',color:'#FF6B6B'}} disabled={avatarBusy} onClick={removePhoto}>🗑️ {t('Remove Photo','फोटो हटाएं')}</button>}
            </div>
            <button onClick={()=>setPhotoViewerOpen(false)} style={{marginTop:18,background:'rgba(255,255,255,.15)',border:'none',borderRadius:8,padding:'8px 22px',color:'#fff',cursor:'pointer',fontSize:12}}>{t('Close','बंद करें')}</button>
          </div>
        </div>
      )}

      {/* ── Custom "Unsaved Changes" modal (replaces native browser confirm) ── */}
      {pendingSection && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,.6)',zIndex:250,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={cancelLeave}>
          <div onClick={e=>e.stopPropagation()} style={{background: dm?'#0A0E17':'#fff', border:`1px solid ${bdr}`, borderRadius:16, padding:24, maxWidth:340, width:'100%'}}>
            <div style={{fontWeight:800,fontSize:15,color:txt,marginBottom:8}}>⚠️ {t('Unsaved Changes','असहेजे गए बदलाव')}</div>
            <div style={{fontSize:12.5,color:sub,marginBottom:18}}>{t('You have unsaved changes in this section. Leave anyway? Your edits will be discarded.','इस सेक्शन में असहेजे गए बदलाव हैं। फिर भी छोड़ें? आपके बदलाव मिट जाएंगे।')}</div>
            <div style={{display:'flex',gap:10}}>
              <button style={btnP} onClick={discardAndLeave}>{t('Leave Without Saving','बिना सहेजे छोड़ें')}</button>
              <button style={btnGhost} onClick={cancelLeave}>{t('Cancel','रद्द करें')}</button>
            </div>
          </div>
        </div>
      )}

      {/* ── §11.3 — Digital Student ID Card modal ── */}
      {idCardOpen && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,.65)',zIndex:300,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setIdCardOpen(false)}>
          <div onClick={e=>e.stopPropagation()} style={{maxWidth:380,width:'100%'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:10}}>
              <span style={{color:'#fff',fontWeight:700,fontSize:14}}>🪪 {t('Digital Student ID Card','डिजिटल छात्र आईडी कार्ड')}</span>
              <button onClick={()=>setIdCardOpen(false)} style={{background:'rgba(255,255,255,.15)',border:'none',borderRadius:8,width:32,height:32,color:'#fff',cursor:'pointer',fontSize:16}}>✕</button>
            </div>
            {idCardVisualEl}
          </div>
        </div>
      )}
    </div>
  )
}

export default function ProfilePage() {
  return <StudentShell pageKey="profile"><ProfileContent/></StudentShell>
}
EOF_PROFILEPAGE2
echo "✅ Profile page updated: $PROFILEPAGE"

echo ""
echo "🧹 2FA fully removed (schema, backend logic, frontend UI+handlers)."
echo "⚠️  Check: if you have a separate 2fa route file (setup/verify/disable),"
echo "   share it so I can remove those too."
echo ""
echo "▶ Restart backend: cd ~/workspace && node src/index.js"
echo "▶ Then: cd ~/workspace/frontend && npm run dev   (check /profile → Security tab)"
