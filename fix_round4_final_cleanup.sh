#!/bin/bash
set -e
echo "=== Fix: Checklist goals-item removed + allDone bug fixed, Dashboard dynamic totalCount + delete OMR View/Performance Report/Onboarding pages ==="

cat > ~/workspace/src/routes/auth.js << 'FILEEOF1'
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

    // 3. PYQ Bank explored — stored in user.checklist.pyqExplored
    const pyqDone = !!(user.checklist?.pyqExplored)

    const items = [
      { id: 'profile',   done: profileDone,    icon: '👤', label_en: 'Complete your profile',              label_hi: 'प्रोफ़ाइल पूरी करें',        href: '/profile',   xp: 50 },
      { id: 'firstTest', done: firstTestDone,  icon: '📝', label_en: 'Give your first mock test',          label_hi: 'पहला मॉक टेस्ट दें',           href: '/my-exams',  xp: 100 },
      { id: 'pyq',       done: pyqDone,        icon: '📚', label_en: 'Explore PYQ Bank',        label_hi: 'PYQ बैंक एक्सप्लोर करें',       href: '/pyq-bank',  xp: 20 },
      ]

    const completedCount = items.filter(i => i.done).length
    // FIX — was `=== 5` for only 4 (now 3) items, so allDone/Pathfinder badge could never trigger
    const allDone = completedCount === items.length
    const hasBadge = (user.badges || []).some(b => b.id === 'pathfinder')

    res.json({
      success: true,
      items,
      completedCount,
      totalCount: items.length,
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
FILEEOF1
echo "auth.js updated ✅"

cat > ~/workspace/frontend/app/dashboard/page.tsx << 'FILEEOF2'
'use client'
import WelcomeBanner from '../../components/WelcomeBanner'
import React, { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// Animated Rocket SVG
function RocketSVG() {
  return (
    <svg width="90" height="120" viewBox="0 0 90 120" fill="none" style={{animation:'float 4s ease-in-out infinite'}}>
      <defs><linearGradient id="rg" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stopColor="#4D9FFF"/><stop offset="100%" stopColor="#0055CC"/></linearGradient></defs>
      {/* Rocket body */}
      <path d="M45 10 C45 10 25 35 20 65 L70 65 C65 35 45 10 45 10Z" fill="url(#rg)"/>
      {/* Window */}
      <circle cx="45" cy="45" r="10" fill="rgba(255,255,255,0.25)" stroke="rgba(255,255,255,0.5)" strokeWidth="1.5"/>
      <circle cx="45" cy="45" r="6" fill="rgba(255,255,255,0.4)"/>
      {/* Fins */}
      <path d="M20 65 L8 80 L25 72Z" fill="#0055CC"/>
      <path d="M70 65 L82 80 L65 72Z" fill="#0055CC"/>
      {/* Flame */}
      <path d="M35 65 Q45 95 45 95 Q45 95 55 65Z" fill="#FFB84D" style={{animation:'pulse 0.5s ease-in-out infinite'}}/>
      <path d="M38 65 Q45 85 45 85 Q45 85 52 65Z" fill="#FFD700" style={{animation:'pulse 0.5s ease-in-out infinite 0.1s'}}/>
      {/* Stars around */}
      <circle cx="10" cy="30" r="2" fill="#FFD700" style={{animation:'pulse 2s infinite'}}/>
      <circle cx="80" cy="20" r="1.5" fill="#fff" style={{animation:'pulse 1.5s infinite'}}/>
      <circle cx="15" cy="55" r="1" fill="#4D9FFF" style={{animation:'pulse 2.5s infinite'}}/>
      <circle cx="78" cy="55" r="2" fill="#FFD700" style={{animation:'pulse 1.8s infinite'}}/>
    </svg>
  )
}

// Animated DNA SVG
function DNASVG() {
  return (
    <svg width="60" height="120" viewBox="0 0 60 120" fill="none" style={{animation:'floatR 5s ease-in-out infinite'}}>
      {Array.from({length:8},(_,i)=>{
        const y=i*16+8; const progress=i/8; const offset=Math.sin(progress*Math.PI*2)*20
        return (
          <g key={i}>
            <line x1={30-offset} y1={y} x2={30+offset} y2={y} stroke={i%2===0?'#4D9FFF':'#00C48C'} strokeWidth="2" strokeLinecap="round"/>
            <circle cx={30-offset} cy={y} r="3" fill={i%2===0?'#4D9FFF':'#00C48C'}/>
            <circle cx={30+offset} cy={y} r="3" fill={i%2===0?'#0055CC':'#00a87a'}/>
          </g>
        )
      })}
      <path d="M10 8 Q10 60 10 112" stroke="rgba(77,159,255,0.3)" strokeWidth="1.5" fill="none"/>
      <path d="M50 8 Q50 60 50 112" stroke="rgba(77,159,255,0.3)" strokeWidth="1.5" fill="none"/>
    </svg>
  )
}

function StatCard({icon,label,value,col,dm,sub}:{icon:string;label:string;value:any;col:string;dm:boolean;sub?:string}) {
  return (
    <div className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:'18px 12px',flex:1,minWidth:130,backdropFilter:'blur(14px)',position:'relative',overflow:'hidden',transition:'all .25s',textAlign:'center',boxShadow:'0 4px 16px rgba(0,0,0,.2)'}}>
      <div style={{position:'absolute',right:-8,bottom:-8,fontSize:48,opacity:.07,filter:'blur(2px)'}}>{icon}</div>
      <div style={{fontSize:26,marginBottom:8,display:'block'}}>{icon}</div>
      <div style={{fontSize:26,fontWeight:800,color:col,fontFamily:'Inter,sans-serif',lineHeight:1,textShadow:`0 0 20px ${col}44`}}>{value??'—'}</div>
      <div style={{fontSize:10,color:C.sub,marginTop:4,fontWeight:600,letterSpacing:.3}}>{label}</div>
      {sub&&<div style={{fontSize:9,color:col,marginTop:2,opacity:.85}}>{sub}</div>}
    </div>
  )
}


// ── F37: Confetti burst ───────────────────────────────────────
function ChecklistConfetti() {
  const colors = ['#4D9FFF','#00C48C','#FFD700','#FF6B9D','#7B4DFF','#00D4FF']
  return (
    <div style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:999,overflow:'hidden'}}>
      {Array.from({length:50}).map((_,i)=>(
        <div key={i} style={{
          position:'absolute',top:'-10px',
          left:Math.random()*100+'%',
          width:i%3===0?8:5,height:i%3===0?8:5,
          borderRadius:i%2===0?'50%':2,
          background:colors[i%colors.length],
          animation:'confettiFall '+(1.2+Math.random()*1.5)+'s ease-in forwards',
          animationDelay:Math.random()*0.6+'s'
        }}/>
      ))}
      <style>{'@keyframes confettiFall{from{transform:translateY(-10px) rotate(0deg);opacity:1}to{transform:translateY(100vh) rotate(720deg);opacity:0}}'}</style>
    </div>
  )
}

// ── F37: Badge Unlocked Modal ─────────────────────────────────
function BadgeModal({onClose}:{onClose:()=>void}) {
  const C2 = C
  return (
    <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={onClose}>
      <div onClick={e=>e.stopPropagation()} style={{background:'rgba(0,18,40,0.98)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:22,padding:'36px 28px',maxWidth:340,width:'100%',textAlign:'center',boxShadow:'0 0 60px rgba(77,159,255,0.2)',animation:'fadeIn .4s ease'}}>
        <div style={{fontSize:64,marginBottom:12,animation:'bounce 1s ease-in-out 3'}}>🏅</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:'#E8F4FF',marginBottom:8}}>Badge Unlocked!</div>
        <div style={{fontSize:14,color:'#4D9FFF',fontWeight:700,marginBottom:8}}>"Pathfinder" 🗺️</div>
        <div style={{fontSize:12,color:'#6B8FAF',marginBottom:20,lineHeight:1.6}}>You completed all 5 Getting Started tasks! +220 XP earned.</div>
        <button onClick={onClose} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:10,padding:'10px 28px',color:'#fff',fontSize:13,fontWeight:700,cursor:'pointer'}}>
          Awesome! 🚀
        </button>
      </div>
    </div>
  )
}

// ── F37: Welcome Banner trigger ───────────────────────────────
function ChecklistWidget({token,toast,lang}:{token:string;toast:(m:string,t?:'s'|'e'|'w')=>void;lang:'en'|'hi'}) {
  const API2 = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
  const t2 = (en:string,hi:string) => lang==='en'?en:hi
  const [items,    setItems]    = React.useState<any[]>([])
  const [count,    setCount]    = React.useState(0)
  const [totalCount, setTotalCount] = React.useState(3)
  const [allDone,  setAllDone]  = React.useState(false)
  const [confetti, setConfetti] = React.useState(false)
  const [badgeModal,setBadgeModal] = React.useState(false)
  const [hasBadge, setHasBadge]= React.useState(false)
  const [loading,  setLoading]  = React.useState(true)
  const [showBanner,setShowBanner] = React.useState(false)

  React.useEffect(()=>{
    if(!token) return
    fetch(API2+'/api/auth/checklist',{headers:{Authorization:'Bearer '+token}})
      .then(r=>r.json())
      .then(d=>{
        if(d.success){
          setItems(d.items||[])
          setCount(d.completedCount||0)
          setTotalCount(d.totalCount||3)
          setAllDone(d.allDone||false)
          setHasBadge(d.hasBadge||false)
        }
        setLoading(false)
      })
      .catch(()=>setLoading(false))
  },[token])

  // Award badge when all done
  React.useEffect(()=>{
    if(allDone && !hasBadge && !loading){
      setConfetti(true)
      setBadgeModal(true)
      setTimeout(()=>setConfetti(false),4000)
      fetch(API2+'/api/auth/checklist/complete',{method:'POST',headers:{Authorization:'Bearer '+token}})
        .then(r=>r.json())
        .then(d=>{ if(d.success&&!d.alreadyAwarded) toast('🏅 Pathfinder badge unlocked! +220 XP','s') })
        .catch(()=>{})
    }
  },[allDone,hasBadge,loading])

  // 37.3 — on item click: show welcome banner first time
  const handleItemClick = (href:string, itemId:string) => {
    const key = 'pr_checklist_clicked_'+itemId
    const firstTime = !localStorage.getItem(key)
    if(firstTime){
      localStorage.setItem(key,'1')
      setShowBanner(true)
      setTimeout(()=>{ setShowBanner(false); window.location.href=href },2000)
    } else {
      window.location.href = href
    }
    // Mark pyq/analytics as visited
    if(itemId==='pyq'){
      fetch(API2+'/api/auth/checklist/mark',{
        method:'POST',
        headers:{Authorization:'Bearer '+token,'Content-Type':'application/json'},
        body:JSON.stringify({item:itemId})
      }).catch(()=>{})
    }
  }

  if(loading) return null
  // Hide widget if all done AND badge already given (seen before)
  if(allDone && hasBadge) return null

  const pct = Math.round((count/totalCount)*100)

  return (
    <>
      {confetti && <ChecklistConfetti/>}
      {badgeModal && <BadgeModal onClose={()=>setBadgeModal(false)}/>}

      {/* 37.3 — Welcome banner overlay */}
      {showBanner && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.75)',zIndex:990,display:'flex',alignItems:'center',justifyContent:'center'}}>
          <div style={{background:'rgba(0,18,36,0.98)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:20,padding:'32px 24px',textAlign:'center',maxWidth:340,animation:'fadeIn .4s ease'}}>
            <div style={{fontSize:48,marginBottom:10}}>🎉</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#E8F4FF',marginBottom:6}}>
              {t2("Let's Go!","चलते हैं!")}
            </div>
            <div style={{fontSize:12,color:'#6B8FAF'}}>
              {t2("Taking you there now...","अभी ले जा रहे हैं...")}
            </div>
          </div>
        </div>
      )}

      {/* 37.8 — Checklist Card */}
      <div style={{
        background:'linear-gradient(135deg,rgba(0,35,80,0.85),rgba(0,22,50,0.9))',
        border:'1px solid rgba(77,159,255,0.25)',
        borderRadius:18, padding:20, marginBottom:20,
        backdropFilter:'blur(16px)',
        boxShadow:'0 4px 28px rgba(0,0,0,0.2)'
      }}>
        {/* Header */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#E8F4FF',marginBottom:2}}>
              🚀 {t2('Getting Started','शुरुआत करें')}
            </div>
            <div style={{fontSize:11,color:'#6B8FAF'}}>
              {t2('Complete tasks to unlock your Pathfinder badge','Pathfinder बैज अनलॉक करें')}
            </div>
          </div>
          <div style={{textAlign:'right'}}>
            <div style={{fontSize:18,fontWeight:800,color:'#4D9FFF'}}>{count}/{totalCount}</div>
            <div style={{fontSize:9,color:'#6B8FAF'}}>{t2('Complete','पूर्ण')}</div>
          </div>
        </div>

        {/* 37.2 Progress bar */}
        <div style={{background:'rgba(255,255,255,0.06)',borderRadius:6,height:6,overflow:'hidden',marginBottom:16}}>
          <div style={{
            height:'100%',
            width:pct+'%',
            background:'linear-gradient(90deg,#4D9FFF,#00C48C)',
            borderRadius:6,
            transition:'width 0.8s ease'
          }}/>
        </div>

        {/* 37.1 — 5 items */}
        {allDone ? (
          /* 37.7 — All done state */
          <div style={{textAlign:'center',padding:'20px 0'}}>
            <div style={{fontSize:40,marginBottom:8}}>🎉</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#00C48C',marginBottom:4}}>
              {t2('All done!','सब पूरा!')}
            </div>
            <div style={{fontSize:12,color:'#6B8FAF'}}>
              {t2("You're a Pathfinder! 🏅 +220 XP earned","आप Pathfinder हैं! 🏅 +220 XP मिला")}
            </div>
          </div>
        ) : (
          <div>
            {items.map((item,i)=>(
              <div key={item.id}
                onClick={()=>!item.done&&handleItemClick(item.href,item.id)}
                style={{
                  display:'flex', alignItems:'center', gap:12,
                  padding:'11px 0',
                  borderBottom: i<4 ? '1px solid rgba(77,159,255,0.08)' : 'none',
                  cursor: item.done ? 'default' : 'pointer',
                  transition:'all .2s',
                }}>
                {/* Icon */}
                <div style={{fontSize:20,flexShrink:0,width:32,textAlign:'center'}}>{item.icon}</div>

                {/* Text */}
                <div style={{flex:1}}>
                  {/* 37.9 — strikethrough on done */}
                  <div style={{
                    fontSize:13, fontWeight:600,
                    color: item.done ? '#4B6A8A' : '#E8F4FF',
                    textDecoration: item.done ? 'line-through' : 'none',
                    transition:'all .4s',
                    lineHeight:1.3,
                  }}>
                    {lang==='en' ? item.label_en : item.label_hi}
                  </div>
                  <div style={{fontSize:10,color:'#4B6A8A',marginTop:2}}>
                    +{item.xp} XP
                  </div>
                </div>

                {/* Status */}
                {item.done ? (
                  /* 37.9 — green tick */
                  <div style={{
                    width:24,height:24,borderRadius:'50%',
                    background:'rgba(0,196,140,0.15)',
                    border:'2px solid #00C48C',
                    display:'flex',alignItems:'center',justifyContent:'center',
                    flexShrink:0,
                    animation:'fadeIn .3s ease',
                  }}>
                    <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                      <polyline points="2,6 5,9 10,3" stroke="#00C48C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                ) : (
                  /* Arrow */
                  <div style={{color:'rgba(77,159,255,0.4)',fontSize:16,flexShrink:0}}>→</div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  )
}

function DashboardContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [exams,   setExams]   = useState<any[]>([])
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [showWelcome, setShowWelcome] = useState(false)
  const [welcomeData, setWelcomeData] = useState<{name:string,studentId:string,email:string}|null>(null)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
  const _cw=async()=>{
    try{
      const isNew=localStorage.getItem('pr_new_student')
      if(isNew!=='true')return
      const tok=localStorage.getItem('pr_token')
      if(!tok)return
      const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'
      const rr=await fetch(API+'/api/auth/me',{headers:{Authorization:'Bearer '+tok}})
      const dd=await rr.json()
      if(dd&&(dd.name||dd.email)){
        setWelcomeData({name:dd.name||'Student',studentId:dd.studentId||'',email:dd.email||''})
        setShowWelcome(true)
        localStorage.removeItem('pr_new_student')
      }
    }catch(e){}
  }
  _cw()
},[])
useEffect(()=>{
    if(!token) return
    const h={Authorization:`Bearer ${token}`}
    Promise.all([
      fetch(`${API}/api/exams`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([e,r])=>{
      setExams(Array.isArray(e)?e:[])
      setResults(Array.isArray(r)?r:[])
      setLoading(false)
    })
  },[token])

  const name=user?.name||t('Student','छात्र')
  const bestScore=results.length?Math.max(...results.map((r:any)=>r.score||0)):null
  const bestRank=results.length?Math.min(...results.map((r:any)=>r.rank||99999)):null
  const daysLeft=Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/86400000))
  const upcoming=exams.filter((e:any)=>new Date(e.scheduledAt)>new Date())
  const avgScore=results.length?Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length):null

  return (
    <div>
      {showWelcome&&welcomeData&&<WelcomeBanner student={welcomeData} onClose={()=>setShowWelcome(false)}/> }
      {/* F37 — Getting Started Checklist */}
      <ChecklistWidget token={token} toast={toast} lang={lang}/>

      {/* Hero Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.2),rgba(77,159,255,.08),rgba(0,0,0,0))',border:'1px solid rgba(77,159,255,.25)',borderRadius:22,padding:'24px 20px',marginBottom:24,position:'relative',overflow:'hidden',boxShadow:'0 4px 32px rgba(0,0,0,.25)'}}>
        {/* Animated BG hexagons */}
        <div style={{position:'absolute',right:-30,top:-20,fontSize:180,color:'rgba(77,159,255,.05)',lineHeight:1,animation:'spinSlow 30s linear infinite',userSelect:'none'}}>⬡</div>
        <div style={{position:'absolute',right:80,bottom:-20,fontSize:100,color:'rgba(77,159,255,.04)',lineHeight:1,animation:'spinSlow 20s linear infinite reverse',userSelect:'none'}}>⬡</div>

        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:16}}>
          <div style={{flex:1,minWidth:260}}>
            <div style={{fontSize:12,color:C.primary,fontWeight:600,marginBottom:6,display:'flex',alignItems:'center',gap:6}}>
              <span style={{animation:'pulse 2s infinite'}}>☀️</span> {t('Good Morning','शुभ प्रभात')}
            </div>
            <h1 style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,color:dm?C.text:C.textL,margin:'0 0 8px'}}>
              {t('Welcome back,','वापसी पर स्वागत,')} <span style={{color:C.primary,textShadow:`0 0 20px ${C.primary}66`}}>{name}</span> 👋
            </h1>
            <p style={{fontSize:12,color:C.sub,marginBottom:16,lineHeight:1.6}}>{t('Your NEET preparation dashboard — Stay focused, stay ranked.','आपका NEET डैशबोर्ड — केंद्रित रहें, रैंक पाएं।')}</p>

            {/* Motivational Quote SVG */}
            <div style={{background:'rgba(77,159,255,.07)',border:'1px solid rgba(77,159,255,.15)',borderRadius:12,padding:'12px 16px',marginBottom:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',left:0,top:0,bottom:0,width:3,background:`linear-gradient(180deg,${C.primary},#0055CC)`}}/>
              <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600,paddingLeft:8}}>
                {t('"Success is not given, it is earned — one test at a time."','"सफलता दी नहीं जाती, कमाई जाती है — एक परीक्षा एक कदम।"')}
              </div>
            </div>

            {/* Quick links */}
            <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
              {[[t('📝 My Exams','📝 परीक्षाएं'),'/my-exams',C.primary],[t('📚 PYQ Bank','📚 PYQ बैंक'),'/pyq-bank',C.gold],[t('📢 Announcements','📢 घोषणाएं'),'/announcements',C.success]].map(([l,h,c]:any)=>(
                <a key={h} href={h} style={{padding:'7px 14px',background:`${c}18`,border:`1px solid ${c}44`,color:c,borderRadius:20,textDecoration:'none',fontSize:12,fontWeight:600,transition:'all .2s'}}>{l}</a>
              ))}
            </div>
          </div>

          {/* Animated Rocket */}
          <div style={{flexShrink:0,opacity:.85}}><RocketSVG/></div>
        </div>
      </div>

      {/* Stats Row 1 */}
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:14}}>
        <StatCard dm={dm} icon="🏆" label={t('Best Rank','सर्वश्रेष्ठ रैंक')} value={bestRank&&bestRank<99999?`#${bestRank}`:'—'} col={C.gold}/>
        <StatCard dm={dm} icon="📊" label={t('Best Score','सर्वश्रेष्ठ स्कोर')} value={bestScore?`${bestScore}/720`:'—'} col={C.primary}/>
        <StatCard dm={dm} icon="📈" label={t('Avg Score','औसत स्कोर')} value={avgScore?`${avgScore}/720`:'—'} col={C.success}/>
        <StatCard dm={dm} icon="⏳" label={t('Days to NEET','NEET तक दिन')} value={daysLeft} col={C.warn} sub="NEET"/>
      </div>
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:24}}>
        <StatCard dm={dm} icon="📝" label={t('Tests Given','दिए टेस्ट')} value={results.length} col={C.primary}/>
        <StatCard dm={dm} icon="📅" label={t('Upcoming','आगामी')} value={upcoming.length} col={C.pink}/>
        <StatCard dm={dm} icon="🔥" label={t('Streak','स्ट्रीक')} value={String(Math.floor(Number(user?.streak)||0))+"d"} col={C.danger} sub={t('Keep going!','जारी रखें!')}/>
        <StatCard dm={dm} icon="🎖️" label={t('Badges','बैज')} value={user?.badges?.length||0} col={C.purple}/>
      </div>

      {/* Subject Performance */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:18,padding:20,marginBottom:20,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:16}}>
          <DNASVG/>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:dm?C.text:C.textL}}>{t('Subject Performance','विषय प्रदर्शन')}</div>
            <div style={{fontSize:11,color:C.sub,marginTop:2}}>{t('Based on your latest test','नवीनतम टेस्ट के आधार पर')}</div>
          </div>
        </div>
        {[
          {n:t('Physics','भौतिकी'),icon:'⚛️',sc:results[0]?.subjectScores?.physics,tot:180,col:'#00B4FF'},
          {n:t('Chemistry','रसायन'),icon:'🧪',sc:results[0]?.subjectScores?.chemistry,tot:180,col:'#FF6B9D'},
          {n:t('Biology','जीव विज्ञान'),icon:'🧬',sc:results[0]?.subjectScores?.biology,tot:360,col:'#00E5A0'},
        ].map(s=>{
          const p=s.sc!=null?Math.round((s.sc/s.tot)*100):0
          return (
            <div key={s.n} style={{marginBottom:14}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:6,fontSize:12}}>
                <span style={{fontWeight:700,color:s.col,display:'flex',alignItems:'center',gap:5}}>{s.icon} {s.n}</span>
                <span style={{color:C.sub}}>{s.sc!=null?(s.sc+'/'+s.tot):'—'} <span style={{color:s.col,fontWeight:700}}>({p}%)</span></span>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:8,height:11,overflow:'hidden',position:'relative'}}>
                <div style={{height:'100%',width:`${p}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:8,transition:'width .9s ease',boxShadow:`0 0 8px ${s.col}44`}}/>
                {p===0&&<div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',paddingLeft:8,fontSize:9,color:C.sub}}>{t('No data yet','अभी कोई डेटा नहीं')}</div>}
              </div>
            </div>
          )
        })}
      </div>

      {/* 2-col grid */}
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
        {/* Upcoming Exams */}
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>📅 {t('Upcoming','आगामी')}</div>
            <a href="/my-exams" style={{fontSize:10,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('All →','सब →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'14px 0',fontSize:12,animation:'pulse 1.5s infinite'}}>⟳</div>:
            upcoming.length===0?(
              <div style={{textAlign:'center',padding:'20px 0',color:C.sub}}>
                {/* Calendar SVG */}
                <svg width="50" height="50" viewBox="0 0 50 50" style={{display:'block',margin:'0 auto 8px'}} fill="none">
                  <rect x="5" y="10" width="40" height="34" rx="4" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                  <path d="M5 20h40" stroke="#4D9FFF" strokeWidth="1"/>
                  <circle cx="17" cy="14" r="3" fill="#4D9FFF"/>
                  <circle cx="33" cy="14" r="3" fill="#4D9FFF"/>
                  <circle cx="17" cy="30" r="2" fill="rgba(77,159,255,0.4)"/>
                  <circle cx="25" cy="30" r="2" fill="rgba(77,159,255,0.4)"/>
                  <circle cx="33" cy="30" r="2" fill="rgba(77,159,255,0.4)"/>
                </svg>
                <div style={{fontSize:11}}>{t('No upcoming exams','कोई परीक्षा नहीं')}</div>
              </div>
            ):upcoming.slice(0,3).map((e:any)=>(
              <div key={e._id} style={{padding:'8px 0',borderBottom:`1px solid ${C.border}`}}>
                <div style={{fontWeight:600,fontSize:12,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{e.title}</div>
                <div style={{color:C.sub,fontSize:10,marginTop:1}}>{new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})} · {e.duration}m</div>
                <a href={`/exam/${e._id}`} style={{display:'inline-block',marginTop:4,padding:'2px 9px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:5,fontSize:9,textDecoration:'none',fontWeight:600}}>{t('Start →','शुरू →')}</a>
              </div>
            ))
          }
        </div>

        {/* Recent Results */}
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>🏅 {t('Results','परिणाम')}</div>
            <a href="/results" style={{fontSize:10,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('All →','सब →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'14px 0',fontSize:12,animation:'pulse 1.5s infinite'}}>⟳</div>:
            results.length===0?(
              <div style={{textAlign:'center',padding:'20px 0',color:C.sub}}>
                {/* Star SVG */}
                <svg width="50" height="50" viewBox="0 0 50 50" style={{display:'block',margin:'0 auto 8px'}} fill="none">
                  <path d="M25 5L29 18H43L32 26L36 39L25 31L14 39L18 26L7 18H21Z" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
                  <path d="M25 12L28 20H36L30 25L32 33L25 28L18 33L20 25L14 20H22Z" fill="rgba(255,215,0,0.2)"/>
                </svg>
                <div style={{fontSize:11}}>{t('No results yet','अभी कोई परिणाम नहीं')}</div>
              </div>
            ):results.slice(0,3).map((r:any)=>(
              <div key={r._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'7px 0',borderBottom:`1px solid ${C.border}`}}>
                <div style={{fontSize:11,flex:1,overflow:'hidden'}}>
                  <div style={{fontWeight:600,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{r.examTitle||'—'}</div>
                  <div style={{color:C.sub,fontSize:9,marginTop:1}}>#{r.rank||'—'} · {r.percentile||'—'}%ile</div>
                </div>
                <div style={{textAlign:'right',flexShrink:0,marginLeft:8}}>
                  <div style={{fontWeight:800,fontSize:16,color:C.primary}}>{r.score}</div>
                  <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                </div>
              </div>
            ))
          }
        </div>
      </div>

      {/* NEET Countdown Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.1),rgba(0,85,204,.15))',border:'1px solid rgba(255,215,0,.22)',borderRadius:20,padding:'22px 20px',marginBottom:20,position:'relative',overflow:'hidden',boxShadow:'0 4px 24px rgba(0,0,0,.2)'}}>
        {/* Animated orbit circles */}
        <div style={{position:'absolute',right:20,top:'50%',transform:'translateY(-50%)',width:80,height:80,borderRadius:'50%',border:'1px dashed rgba(255,215,0,.2)',animation:'spinSlow 20s linear infinite',pointerEvents:'none'}}/>
        <div style={{position:'absolute',right:30,top:'50%',transform:'translateY(-50%)',width:55,height:55,borderRadius:'50%',border:'1px dashed rgba(255,215,0,.3)',animation:'spinSlow 12s linear infinite reverse',pointerEvents:'none'}}/>
        <div style={{fontSize:13,color:C.gold,fontWeight:700,marginBottom:4}}>🏆 NEET</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:dm?C.text:C.textL,marginBottom:4}}>
          <span style={{color:C.gold,textShadow:`0 0 20px ${C.gold}44`}}>{daysLeft}</span> {t('Days Remaining','दिन शेष')}
        </div>
        <div style={{fontSize:12,color:C.sub,marginBottom:14}}>{t('NEET · 180 Questions · 720 Marks','NEET · 180 प्रश्न · 720 अंक')}</div>
        {/* Progress bar */}
        <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:8,overflow:'hidden',marginBottom:12}}>
          <div style={{height:'100%',width:`${Math.max(5,100-Math.round(daysLeft/365*100))}%`,background:`linear-gradient(90deg,${C.gold},#FF8C00)`,borderRadius:6,transition:'width .8s'}}/>
        </div>
        <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
          <a href="/my-exams" style={{padding:'8px 16px',background:`${C.gold}20`,border:`1px solid ${C.gold}44`,color:C.gold,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('📝 Practice Tests','📝 अभ्यास टेस्ट')}</a>
          <a href="/pyq-bank" style={{padding:'8px 16px',background:`${C.primary}20`,border:`1px solid ${C.primary}44`,color:C.primary,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('📚 PYQ Bank','📚 PYQ बैंक')}</a>
        </div>
      </div>

      {/* Quick Access Grid */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(14px)',marginBottom:20}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:14}}>⚡ {t('Quick Access','त्वरित एक्सेस')}</div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(120px,1fr))',gap:10}}>
          {[['📝',t('My Exams','परीक्षाएं'),'/my-exams',C.primary],['📚',t('PYQ Bank','PYQ बैंक'),'/pyq-bank',C.gold],['🕐',t('Attempt History','परीक्षा इतिहास'),'/attempt-history',C.purple]].map(([ic,label,href,col])=>(
            <a key={href as string} href={href as string} style={{display:'flex',flexDirection:'column',alignItems:'center',gap:6,padding:'14px 10px',background:`${col}0f`,border:`1px solid ${col}22`,borderRadius:12,textDecoration:'none',color:dm?C.text:C.textL,fontSize:11,fontWeight:600,transition:'all .2s',textAlign:'center'}}>
              <span style={{fontSize:22}}>{ic}</span>
              <span style={{color:col as string,fontSize:10}}>{label}</span>
            </a>
          ))}
        </div>
      </div>

      {/* Motivational Footer */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.14),rgba(77,159,255,.05))',border:'1px solid rgba(77,159,255,.15)',borderRadius:20,padding:'26px 20px',textAlign:'center',position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',opacity:.04,overflow:'hidden'}}>
          <svg width="600" height="80" viewBox="0 0 600 80"><text x="50%" y="65" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="52" fontWeight="700" fill="#4D9FFF">PROVE YOUR RANK</text></svg>
        </div>
        <div style={{fontSize:20,color:C.primary,fontFamily:'Playfair Display,serif',fontWeight:700,marginBottom:6,textShadow:`0 0 30px ${C.primary}44`}}>
          {t("You're on the right path! 🚀","आप सही रास्ते पर हैं! 🚀")}
        </div>
        <div style={{fontSize:13,color:C.sub}}>{t(daysLeft+' days remaining — Make every day count!',''+daysLeft+' दिन शेष — हर दिन सार्थक बनाएं!')}</div>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  return <StudentShell pageKey="dashboard"><DashboardContent/></StudentShell>
}
FILEEOF2
echo "dashboard/page.tsx updated ✅"

rm -rf ~/workspace/frontend/app/omr-view
rm -rf ~/workspace/frontend/app/performance-report
rm -rf ~/workspace/frontend/app/onboarding
echo "omr-view, performance-report, onboarding folders deleted ✅"

cd ~/workspace
git add -A
git commit -m "delete: OMR View, Performance Report, Onboarding orphaned pages; fix checklist goals-item + allDone bug + dynamic totalCount"
git push
