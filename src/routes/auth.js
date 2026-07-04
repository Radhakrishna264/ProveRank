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

    if (!match) return res.status(401).json({ message: 'Incorrect password. Please try again.' })

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

    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    // F35.1 — Multi-device session control: new login invalidates old device
    await User.collection.updateOne({ _id: user._id }, { $set: { activeSessionToken: token } })
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
