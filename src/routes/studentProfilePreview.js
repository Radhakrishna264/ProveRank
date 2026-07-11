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
