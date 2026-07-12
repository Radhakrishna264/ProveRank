#!/bin/bash
# ProveRank — F42A/F42B Announcements — BACKEND v2
# 1) 5 types (exam/update/result/maintenance/urgent)
# 2) 4 audience modes (all/batch/testseries/students)
# 3) Chunked (50/batch, parallel) email sending w/ personalization
# 4) Duplicate-as-draft ADDED (separate from Resend)
# Run from project ROOT in Replit shell: bash proverank_f42_backend_v2.sh
set -e

SRC_DIR="src"

mkdir -p "$SRC_DIR/models" "$SRC_DIR/routes"

echo '-> Writing $SRC_DIR/models/Announcement.js'
cat > "$SRC_DIR/models/Announcement.js" << 'PRSHEOF'
const mongoose = require('mongoose')

// ══════════════════════════════════════════════════════════════
// F42 — Announcement model
// Backs F42A (Admin Panel — Announcements) and F42B (Student Panel —
// Announcements). One collection, targeted per-audience, with full
// read/ack tracking, scheduling, drafts, and email delivery stats.
// ══════════════════════════════════════════════════════════════
const AnnouncementSchema = new mongoose.Schema({
  title:      { type: String, required: true },
  titleHi:    { type: String, default: '' },          // F42A §2.1.7 / F42B §3.5 bilingual
  message:    { type: String, required: true },        // sanitized HTML (bold/italic/link) — F42A §2.1.5
  messageHi:  { type: String, default: '' },

  type: { type: String, enum: ['exam', 'update', 'result', 'maintenance', 'urgent'], default: 'update' }, // F42A §2.1.1 (v2: +maintenance)

  audience: {
    mode:         { type: String, enum: ['all', 'batch', 'testseries', 'students'], default: 'all' }, // F42A §1.2.2 / §2.1.9 (v2: +testseries)
    batchIds:     [{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],   // multi-select batches
    testSeriesIds:[{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],   // multi-select test series (same underlying collection, tracked separately)
    studentIds:   [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],    // specific students
  },

  sendVia: { type: String, enum: ['in-app', 'email', 'both'], default: 'in-app' }, // F42A §1.2.3

  pinned:     { type: Boolean, default: false },  // F42A §2.1.2 / F42B §2
  imageUrl:   { type: String, default: '' },      // F42A §2.1.6 / F42B §3.4
  scheduledAt:{ type: Date, default: null },      // F42A §2.1.3
  expiryDate: { type: Date, default: null },      // F42A §2.1.8 / F42B §3.9

  status: { type: String, enum: ['sent', 'scheduled', 'draft'], default: 'sent' }, // F42A §2.2.5

  createdBy:    { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  templateName: { type: String, default: '' },    // F42A §2.4.1
  targetCount:  { type: Number, default: 0 },      // total resolved recipients at send time

  // F42B §4 read tracking (per-student) — used for F42A §2.2.2 read-receipt stats
  readBy: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    readAt: { type: Date, default: Date.now },
  }],
  // F42B §6.5 — explicit "👍 Got it" acknowledgement (separate from passive read tracking)
  ackBy: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    ackAt:  { type: Date, default: Date.now },
  }],

  // F42A §2.3.2 per-batch/email delivery status
  emailStats: {
    sent:      { type: Number, default: 0 },
    delivered: { type: Number, default: 0 },
    failed:    { type: Number, default: 0 },
  },
}, { timestamps: true })

AnnouncementSchema.index({ status: 1, createdAt: -1 })
AnnouncementSchema.index({ 'audience.batchIds': 1 })
AnnouncementSchema.index({ 'audience.studentIds': 1 })

module.exports = mongoose.model('Announcement', AnnouncementSchema)
PRSHEOF

echo '-> Writing $SRC_DIR/routes/announcements.js'
cat > "$SRC_DIR/routes/announcements.js" << 'PRSHEOF'
const express = require('express')
const studentRouter = express.Router()
const adminRouter = express.Router()
const mongoose = require('mongoose')
const { verifyToken } = require('../middleware/auth')
const Announcement = require('../models/Announcement')
const User = require('../models/User')
const Batch = require('../models/Batch')

// ══════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════

// F42A §2.4.2 — flips due scheduled announcements to 'sent' (poor-man's
// scheduler — runs opportunistically on every list fetch, student or admin).
async function promoteScheduled() {
  try {
    await Announcement.updateMany(
      { status: 'scheduled', scheduledAt: { $lte: new Date() } },
      { $set: { status: 'sent' } }
    )
  } catch (e) {}
}

// Resolves an audience descriptor into the list of student User docs
// {_id, name, email} who should receive the announcement.
async function resolveAudience(audience) {
  if (!audience || audience.mode === 'all') {
    return User.find({ role: 'student', banned: { $ne: true } }, 'name email').lean()
  }
  if (audience.mode === 'batch' || audience.mode === 'testseries') {
    const ids = (audience.mode === 'batch' ? audience.batchIds : audience.testSeriesIds || audience.batchIds) || []
    const filtered = ids.filter(Boolean)
    if (!filtered.length) return []
    const batches = await Batch.find({ _id: { $in: filtered } }, 'students').lean()
    const studentIds = [...new Set(batches.flatMap(b => (b.students || []).map(String)))]
    if (!studentIds.length) return []
    return User.find({ _id: { $in: studentIds }, role: 'student', banned: { $ne: true } }, 'name email').lean()
  }
  if (audience.mode === 'students') {
    const ids = (audience.studentIds || []).filter(Boolean)
    if (!ids.length) return []
    return User.find({ _id: { $in: ids }, role: 'student' }, 'name email').lean()
  }
  return []
}

// F42A §2.1.5 — lightweight allow-list HTML sanitizer (bold/italic/link/etc only).
// No external dependency required; strips everything not explicitly allowed.
function sanitizeHtml(html) {
  if (!html) return ''
  let s = String(html)
  s = s.replace(/<script[\s\S]*?<\/script>/gi, '')
  s = s.replace(/<style[\s\S]*?<\/style>/gi, '')
  // Only allow a small safe tag set
  s = s.replace(/<(?!\/?(b|strong|i|em|u|br|p|a)(\s|>|\/))[^>]*>/gi, '')
  // Strip inline event handlers and javascript: hrefs from whatever remains
  s = s.replace(/\son\w+\s*=\s*"[^"]*"/gi, '').replace(/\son\w+\s*=\s*'[^']*'/gi, '')
  s = s.replace(/href\s*=\s*["']\s*javascript:[^"']*["']/gi, 'href="#"')
  return s
}

function toObjectId(id) {
  try { return new mongoose.Types.ObjectId(id) } catch (e) { return null }
}

// v2 — Chunked email dispatch: processes recipients in batches of 50 IN
// PARALLEL (Promise.allSettled per chunk), sequential across chunks. Fast
// and scalable for large audiences while still fully personalizing each
// email via {student_name}.
async function sendChunkedEmails(recipients, subject, rawMessage) {
  const { sendCustomEmail } = require('../utils/emailService')
  const CHUNK_SIZE = 50
  let sent = 0, failed = 0
  for (let i = 0; i < recipients.length; i += CHUNK_SIZE) {
    const chunk = recipients.slice(i, i + CHUNK_SIZE)
    const results = await Promise.allSettled(chunk.map(r => {
      if (!r.email || r.email.includes('@proverank.com')) return Promise.resolve('skip')
      const personalized = rawMessage.replace(/{student_name}/g, r.name || 'Student')
      return sendCustomEmail([r.email], subject, personalized)
    }))
    results.forEach(res => {
      if (res.status === 'fulfilled' && res.value !== 'skip') sent++
      else if (res.status === 'fulfilled' && res.value === 'skip') { /* not counted either way */ }
      else failed++
    })
  }
  return { sent, delivered: sent, failed }
}

// ══════════════════════════════════════════════════════════════
// STUDENT ROUTES — mounted at /api/announcements  (F42B)
// ══════════════════════════════════════════════════════════════

// GET / — list announcements visible to the logged-in student
studentRouter.get('/', verifyToken, async (req, res) => {
  try {
    await promoteScheduled()
    const uid = toObjectId(req.user.id)
    if (!uid) return res.status(400).json({ message: 'Invalid user' })

    const myBatches = await Batch.find({ students: uid }, '_id').lean()
    const myBatchIds = myBatches.map(b => b._id)
    const now = new Date()

    const list = await Announcement.find({
      status: 'sent',
      $and: [
        { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] }, // F42B §3.9 expiry check
        { $or: [
            { 'audience.mode': 'all' },
            { 'audience.mode': 'batch', 'audience.batchIds': { $in: myBatchIds } },
            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { $in: myBatchIds } },
            { 'audience.mode': 'students', 'audience.studentIds': uid },
        ] },
      ],
    }).sort({ pinned: -1, createdAt: -1 }).limit(150).lean()

    const out = list.map(a => ({
      _id: a._id, title: a.title, titleHi: a.titleHi, message: a.message, messageHi: a.messageHi,
      type: a.type, pinned: a.pinned, imageUrl: a.imageUrl, expiryDate: a.expiryDate,
      createdAt: a.createdAt,
      isRead: (a.readBy || []).some(r => String(r.userId) === String(uid)),
      isAcked: (a.ackBy || []).some(r => String(r.userId) === String(uid)),
    }))
    res.json(out)
  } catch (err) {
    res.status(500).json({ message: err.message })
  }
})

// GET /unread-count — v2 §6.2: lightweight endpoint StudentShell polls every
// 60s from ANY page (not just the Announcements page) so the bell badge is
// always accurate, not dependent on the student having visited that page.
studentRouter.get('/unread-count', verifyToken, async (req, res) => {
  try {
    await promoteScheduled()
    const uid = toObjectId(req.user.id)
    if (!uid) return res.status(400).json({ count: 0 })
    const myBatches = await Batch.find({ students: uid }, '_id').lean()
    const myBatchIds = myBatches.map(b => b._id)
    const now = new Date()
    const count = await Announcement.countDocuments({
      status: 'sent',
      'readBy.userId': { $ne: uid },
      $and: [
        { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] },
        { $or: [
            { 'audience.mode': 'all' },
            { 'audience.mode': 'batch', 'audience.batchIds': { $in: myBatchIds } },
            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { $in: myBatchIds } },
            { 'audience.mode': 'students', 'audience.studentIds': uid },
        ] },
      ],
    })
    res.json({ count })
  } catch (err) { res.status(500).json({ count: 0 }) }
})

// POST /:id/read — mark a single announcement as read (F42B §4.1)
studentRouter.post('/:id/read', verifyToken, async (req, res) => {
  try {
    const ann = await Announcement.findById(req.params.id)
    if (!ann) return res.status(404).json({ message: 'Not found' })
    const already = (ann.readBy || []).some(r => String(r.userId) === String(req.user.id))
    if (!already) { ann.readBy.push({ userId: req.user.id, readAt: new Date() }); await ann.save() }
    res.json({ success: true })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// POST /read-all — F42B §6.3 "Mark all as read"
studentRouter.post('/read-all', verifyToken, async (req, res) => {
  try {
    const uid = toObjectId(req.user.id)
    if (!uid) return res.status(400).json({ message: 'Invalid user' })
    const myBatches = await Batch.find({ students: uid }, '_id').lean()
    const myBatchIds = myBatches.map(b => b._id)
    const now = new Date()
    await Announcement.updateMany({
      status: 'sent',
      'readBy.userId': { $ne: uid },
      $and: [
        { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] },
        { $or: [
            { 'audience.mode': 'all' },
            { 'audience.mode': 'batch', 'audience.batchIds': { $in: myBatchIds } },
            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { $in: myBatchIds } },
            { 'audience.mode': 'students', 'audience.studentIds': uid },
        ] },
      ],
    }, { $push: { readBy: { userId: uid, readAt: now } } })
    res.json({ success: true })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// POST /:id/ack — F42B §6.5 explicit "👍 Got it" acknowledgement
studentRouter.post('/:id/ack', verifyToken, async (req, res) => {
  try {
    const ann = await Announcement.findById(req.params.id)
    if (!ann) return res.status(404).json({ message: 'Not found' })
    const already = (ann.ackBy || []).some(r => String(r.userId) === String(req.user.id))
    if (!already) { ann.ackBy.push({ userId: req.user.id, ackAt: new Date() }); await ann.save() }
    res.json({ success: true })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// ══════════════════════════════════════════════════════════════
// ADMIN ROUTES — mounted at /api/admin/announcements  (F42A)
// ══════════════════════════════════════════════════════════════
function requireAdminOrSuper(req, res, next) {
  if (!req.user || (req.user.role !== 'admin' && req.user.role !== 'superadmin')) {
    return res.status(403).json({ message: 'Admin access required' })
  }
  next()
}

// GET /batches — audience picker: batches/test series with live student counts (F42A §1.2.2 / §3.1.2)
adminRouter.get('/batches', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const batches = await Batch.find({ status: { $ne: 'inactive' } }, 'name examType students').lean()
    res.json(batches.map(b => ({ _id: b._id, name: b.name, examType: b.examType, studentCount: (b.students || []).length })))
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// GET /students-search?q=... — smart search for "Specific Students" audience (F42A §1.2.2.2)
adminRouter.get('/students-search', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const q = String(req.query.q || '').trim()
    if (!q) return res.json([])
    const rx = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i')
    const students = await User.find({ role: 'student', $or: [{ name: rx }, { email: rx }, { studentId: rx }] }, 'name email studentId').limit(20).lean()
    res.json(students)
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// GET /templates — F42A §2.4.1 pre-built templates
adminRouter.get('/templates', verifyToken, requireAdminOrSuper, (req, res) => {
  res.json([
    { name: 'Exam Reminder', type: 'exam', title: 'Upcoming Exam Reminder', message: 'Your exam is scheduled soon. Make sure you are fully prepared and review your syllabus!' },
    { name: 'Result Published', type: 'result', title: 'Results Declared!', message: 'Your exam results are now available. Check your dashboard to view your score, rank, and detailed analysis.' },
    { name: 'Maintenance Notice', type: 'urgent', title: 'Scheduled Maintenance', message: 'The platform will undergo scheduled maintenance shortly. Some features may be temporarily unavailable. We apologize for the inconvenience.' },
  ])
})

// GET /stats — F42A §3.4.1 stats bar
adminRouter.get('/stats', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const totalSent = await Announcement.countDocuments({ status: 'sent' })
    const weekAgo = new Date(Date.now() - 7 * 86400000)
    const thisWeek = await Announcement.countDocuments({ status: 'sent', createdAt: { $gte: weekAgo } })
    const scheduled = await Announcement.countDocuments({ status: 'scheduled' })
    const sentAnns = await Announcement.find({ status: 'sent', targetCount: { $gt: 0 } }, 'readBy targetCount').lean()
    let sumRate = 0
    sentAnns.forEach(a => { sumRate += (a.readBy || []).length / a.targetCount })
    const avgReadRate = sentAnns.length ? Math.round((sumRate / sentAnns.length) * 100) : 0
    res.json({ totalSent, thisWeek, avgReadRate, scheduled })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// GET / — F42A §2.2.1/§2.2.3 sent history list with search/filter
adminRouter.get('/', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    await promoteScheduled()
    const { search, type, audienceMode, dateFrom, dateTo, status } = req.query
    const q = {}
    if (status) q.status = status
    if (type) q.type = type
    if (audienceMode) q['audience.mode'] = audienceMode
    if (search) {
      const rx = new RegExp(String(search).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i')
      q.$or = [{ title: rx }, { message: rx }]
    }
    if (dateFrom || dateTo) {
      q.createdAt = {}
      if (dateFrom) q.createdAt.$gte = new Date(dateFrom)
      if (dateTo) q.createdAt.$lte = new Date(dateTo + 'T23:59:59')
    }
    const list = await Announcement.find(q).populate('audience.batchIds', 'name').sort({ createdAt: -1 }).limit(200).lean()
    const out = list.map(a => ({
      ...a,
      readCount: (a.readBy || []).length,
      ackCount: (a.ackBy || []).length,
    }))
    res.json(out)
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// GET /:id/delivery — F42A §2.3.2 per-batch delivery status detail
adminRouter.get('/:id/delivery', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const ann = await Announcement.findById(req.params.id).lean()
    if (!ann) return res.status(404).json({ message: 'Not found' })
    res.json({
      emailStats: ann.emailStats, readCount: (ann.readBy || []).length,
      ackCount: (ann.ackBy || []).length, targetCount: ann.targetCount,
    })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// POST / — F42A §1.2.5 send / §2.1.3 schedule / §2.2.5 save draft (the core compose action)
adminRouter.post('/', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const { title, titleHi, message, messageHi, type, sendVia, pinned, imageUrl, scheduledAt, expiryDate, saveAsDraft, templateName } = req.body
    if (!title || !message) return res.status(400).json({ message: 'Title and message are required' })

    // Legacy-compat: existing BatchDetailOverlay widget & old compose form
    // send { batch: 'all' | batchId } instead of a full audience object.
    let audience = req.body.audience
    if (!audience && req.body.batch !== undefined) {
      audience = req.body.batch === 'all' || !req.body.batch ? { mode: 'all' } : { mode: 'batch', batchIds: [req.body.batch] }
    }
    if (!audience || !audience.mode) audience = { mode: 'all' }

    let status = 'sent'
    if (saveAsDraft) status = 'draft'
    else if (scheduledAt && new Date(scheduledAt) > new Date()) status = 'scheduled'

    const cleanMessage = sanitizeHtml(message)
    const cleanMessageHi = sanitizeHtml(messageHi || '')
    const recipients = status === 'draft' ? [] : await resolveAudience(audience)

    const doc = await Announcement.create({
      title, titleHi: titleHi || '', message: cleanMessage, messageHi: cleanMessageHi,
      type: type || 'update', audience, sendVia: sendVia || 'in-app',
      pinned: !!pinned, imageUrl: imageUrl || '',
      scheduledAt: status === 'scheduled' ? new Date(scheduledAt) : null,
      status, expiryDate: expiryDate ? new Date(expiryDate) : null,
      createdBy: req.user.id, templateName: templateName || '',
      targetCount: recipients.length,
    })

    if (status === 'sent' && (sendVia === 'email' || sendVia === 'both') && recipients.length) {
      doc.emailStats = await sendChunkedEmails(recipients, title, cleanMessage)
      await doc.save()
    }

    try {
      const { logActivity } = require('../utils/activityLogger')
      const action = status === 'draft' ? 'ANNOUNCEMENT_DRAFTED' : status === 'scheduled' ? 'ANNOUNCEMENT_SCHEDULED' : 'ANNOUNCEMENT_SENT'
      logActivity({ userId: req.user.id, userRole: req.user.role, action, details: `"${title}" — ${status} (${recipients.length} recipients)`, module: 'announcements', status: 'success' }).catch(() => {})
    } catch (e) {}

    res.json({
      success: true, announcement: doc,
      message: status === 'draft' ? 'Saved as draft' : status === 'scheduled' ? 'Scheduled successfully' : 'Announcement sent successfully',
    })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// PUT /:id — F42A §2.2.1 Edit action
adminRouter.put('/:id', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const allowed = ['title', 'titleHi', 'message', 'messageHi', 'type', 'audience', 'sendVia', 'pinned', 'imageUrl', 'expiryDate', 'scheduledAt']
    const update = {}
    allowed.forEach(k => {
      if (req.body[k] !== undefined) update[k] = (k === 'message' || k === 'messageHi') ? sanitizeHtml(req.body[k]) : req.body[k]
    })
    const doc = await Announcement.findByIdAndUpdate(req.params.id, update, { new: true })
    if (!doc) return res.status(404).json({ message: 'Not found' })
    res.json({ success: true, announcement: doc })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// DELETE /:id — F42A §2.2.1 Delete action
adminRouter.delete('/:id', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    await Announcement.findByIdAndDelete(req.params.id)
    res.json({ success: true })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// POST /:id/resend — F42A §2.2.4 Duplicate/Resend
adminRouter.post('/:id/resend', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const orig = await Announcement.findById(req.params.id).lean()
    if (!orig) return res.status(404).json({ message: 'Not found' })
    const recipients = await resolveAudience(orig.audience)
    const doc = await Announcement.create({
      title: orig.title, titleHi: orig.titleHi, message: orig.message, messageHi: orig.messageHi,
      type: orig.type, audience: orig.audience, sendVia: orig.sendVia, pinned: orig.pinned,
      imageUrl: orig.imageUrl, status: 'sent', expiryDate: orig.expiryDate,
      createdBy: req.user.id, targetCount: recipients.length,
    })
    if ((orig.sendVia === 'email' || orig.sendVia === 'both') && recipients.length) {
      doc.emailStats = await sendChunkedEmails(recipients, doc.title, doc.message)
      await doc.save()
    }
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: req.user.id, userRole: req.user.role, action: 'ANNOUNCEMENT_RESENT', details: `Resent "${doc.title}"`, module: 'announcements', status: 'success' }).catch(() => {})
    } catch (e) {}
    res.json({ success: true, announcement: doc, message: 'Resent successfully' })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

// POST /:id/duplicate — v2 §4: Duplicate-as-DRAFT (does NOT send anything —
// creates an editable copy for the admin to review/tweak before sending,
// distinct from Resend which sends immediately).
adminRouter.post('/:id/duplicate', verifyToken, requireAdminOrSuper, async (req, res) => {
  try {
    const orig = await Announcement.findById(req.params.id).lean()
    if (!orig) return res.status(404).json({ message: 'Not found' })
    const doc = await Announcement.create({
      title: `${orig.title} (Copy)`, titleHi: orig.titleHi, message: orig.message, messageHi: orig.messageHi,
      type: orig.type, audience: orig.audience, sendVia: orig.sendVia, pinned: orig.pinned,
      imageUrl: orig.imageUrl, status: 'draft', expiryDate: orig.expiryDate,
      createdBy: req.user.id, targetCount: 0,
    })
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: req.user.id, userRole: req.user.role, action: 'ANNOUNCEMENT_DUPLICATED', details: `Duplicated "${orig.title}" as draft`, module: 'announcements', status: 'success' }).catch(() => {})
    } catch (e) {}
    res.json({ success: true, announcement: doc, message: 'Duplicated as draft — edit and send whenever ready' })
  } catch (err) { res.status(500).json({ message: err.message }) }
})

module.exports = { studentAnnouncementRoutes: studentRouter, adminAnnouncementRoutes: adminRouter, resolveAudience, sanitizeHtml, promoteScheduled }
PRSHEOF

echo '-> Writing $SRC_DIR/routes/adminSystem.js'
cat > "$SRC_DIR/routes/adminSystem.js" << 'PRSHEOF'
const express = require('express');
const router = express.Router();
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

// In-memory store (MongoDB mein save karna ho toh model banao)
// Maintenance state ab MongoDB mein save hoga
let featureFlags = {
  darkMode: true, liveRank: true, webcam: true,
  twoFactor: true, aiFeatures: true, pyqBank: true,
  bulkImport: true, pdfExport: true, emailNotifications: false
};

// ── S66: MAINTENANCE MODE ────────────────────────────────────
router.post('/maintenance', verifyToken, isSuperAdmin, async (req, res) => {
  const { enabled, message, allowedEmails } = req.body;
  const mongoose = require('mongoose')
  await mongoose.connection.db.collection('settings').updateOne(
    { key: 'maintenance' },
    { $set: { enabled: enabled === true, message: message || 'Site under maintenance. We will be back shortly.', allowedEmails: Array.isArray(allowedEmails) ? allowedEmails : [], updatedAt: new Date() } },
    { upsert: true }
  )
  const saved = await mongoose.connection.db.collection('settings').findOne({ key: 'maintenance' })
  // F42A §2.4.2 — auto-announcement trigger on maintenance mode toggle
  try {
    const Announcement = require('../models/Announcement')
    const User = require('../models/User')
    const targetCount = await User.countDocuments({ role: 'student', banned: { $ne: true } })
    await Announcement.create({
      title: enabled ? 'Scheduled Maintenance' : 'Maintenance Complete',
      message: enabled
        ? (message || 'The platform will undergo scheduled maintenance shortly. Some features may be temporarily unavailable.')
        : 'Maintenance is complete — the platform is back to normal. Thank you for your patience!',
      type: 'maintenance', audience: { mode: 'all' }, sendVia: 'in-app',
      pinned: enabled, status: 'sent', createdBy: req.user.id,
      templateName: 'Maintenance Notice (auto)', targetCount,
    })
  } catch (e) { console.error('[F42A auto-announcement] maintenance trigger failed:', e.message) }
  res.json({ success: true, message: `Maintenance mode ${enabled ? 'ON' : 'OFF'} ho gaya`, state: saved });
});

router.get('/maintenance', async (req, res) => {
  const mongoose = require('mongoose')
  const state = await mongoose.connection.db.collection('settings').findOne({ key: 'maintenance' })
  res.json({ success: true, maintenance: state || { enabled: false, message: '' } });
});

// ── N21: FEATURE FLAG SYSTEM ─────────────────────────────────
router.get('/feature-flags', verifyToken, isSuperAdmin, (req, res) => {
  res.json({ success: true, flags: featureFlags });
});

router.put('/feature-flags', verifyToken, isSuperAdmin, (req, res) => {
  const { feature, enabled } = req.body;
  if (!feature) return res.status(400).json({ message: 'feature name required' });
  featureFlags[feature] = enabled === true;
  res.json({ success: true, message: `Feature '${feature}' ${enabled ? 'ON' : 'OFF'} ho gaya`, flags: featureFlags });
});

router.put('/feature-flags/bulk', verifyToken, isSuperAdmin, (req, res) => {
  const { flags } = req.body;
  if (!flags || typeof flags !== 'object')
    return res.status(400).json({ message: 'flags object required' });
  Object.assign(featureFlags, flags);
  res.json({ success: true, message: 'Bulk flags update ho gaye', flags: featureFlags });
});


// ── N21: FEATURE FLAGS - MongoDB Persistent (/features) ──────
const FeatureFlag = require('../models/FeatureFlag');
const DEFAULT_FLAGS = [
  {key:'open_registration',label:'Student Registration',description:'Allow new student registrations. Toggle OFF to close (Superadmin only)',enabled:true},
  {key:'webcam',label:'Webcam Proctoring',description:'Camera compulsory during exams (Phase 5.2)',enabled:true},
  {key:'audio',label:'Audio Monitoring',description:'Microphone noise detection (S57)',enabled:false},
  {key:'eyeTracking',label:'Eye Tracking AI',description:'Detect looking away from screen (S-ET)',enabled:false},
  {key:'faceDetection',label:'Face Detection TF.js',description:'Multi/no-face detection (Phase 5.4)',enabled:false},
  {key:'headPose',label:'Head Pose Detection',description:'Head angle tracking (S73)',enabled:false},
  {key:'virtualBg',label:'Virtual Background Block',description:'Detect and block fake backgrounds (S74)',enabled:false},
  {key:'vpnBlock',label:'VPN/Proxy Block',description:'Block VPN users from attempting (S20)',enabled:false},
  {key:'liveRank',label:'Live Rank Updates',description:'Socket.io real-time ranking (S107)',enabled:true},
  {key:'socialShare',label:'Social Share Results',description:'WhatsApp/Instagram result card (S99)',enabled:true},
  {key:'parentPortal',label:'Parent Portal',description:'Read-only child progress access (N17)',enabled:false},
  {key:'pyqBank',label:'PYQ Bank Access',description:'NEET 2015-2024 questions (S104)',enabled:true},
  {key:'maintenance',label:'Maintenance Mode',description:'Block students, keep admin accessible (S66)',enabled:false},
  {key:'sms',label:'SMS Notifications',description:'Result SMS via Textlocal/2SMS (M19)',enabled:false},
  {key:'whatsapp',label:'WhatsApp Alerts',description:'Exam reminders via WhatsApp (S65)',enabled:false},
  {key:'twoFactor',label:'Two Factor Auth',description:'Admin mandatory 2FA (Phase 1.1)',enabled:true},
  {key:'aiFeatures',label:'AI Features',description:'AI tagging, difficulty, classifier',enabled:true},
  {key:'bulkImport',label:'Bulk Import',description:'Excel/PDF/Copy-paste upload',enabled:true},
  {key:'pdfExport',label:'PDF Export',description:'Result/report PDF download',enabled:true},
  {key:'emailNotifications',label:'Email Notifications',description:'Email templates active (S109)',enabled:false},
  {key:'antiCheat',label:'Anti-Cheat System',description:'Full proctoring system active',enabled:true},
  {key:'reAttempt',label:'Re-Attempt System',description:'Admin can allow re-attempts (S31)',enabled:true},
  {key:'leaderboard',label:'Leaderboard',description:'Public rank leaderboard visible',enabled:true},
  {key:'questionAI',label:'Question AI Generator',description:'AI question generation (S101)',enabled:true},
  {key:'admitCard',label:'Admit Card',description:'Digital admit card system (S106)',enabled:true},
  {key:'grievance',label:'Grievance System',description:'Student grievance submission (S92)',enabled:true},
  {key:'darkMode',label:'Dark Mode',description:'Platform dark theme default',enabled:true}
];
async function seedDefaultFlags(){
  try{
    for(const f of DEFAULT_FLAGS){
      await FeatureFlag.findOneAndUpdate({key:f.key},{$setOnInsert:{key:f.key,label:f.label,description:f.description,enabled:f.enabled}},{upsert:true,new:false});
    }
  }catch(e){console.log('Flag seed error:',e.message);}
}
setTimeout(()=>seedDefaultFlags(),3000);

router.get('/features', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    let flags = await FeatureFlag.find({}).lean();
    if(!flags||flags.length===0){ await seedDefaultFlags(); flags=await FeatureFlag.find({}).lean(); }
    const flagsObj={};
    flags.forEach(f=>{flagsObj[f.key]=f.enabled;});
    global.featureFlags=flagsObj;
    res.json(flags);
  } catch(e){ res.status(500).json({success:false,message:e.message}); }
});

router.post('/features', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const {key,enabled}=req.body;
    if(!key) return res.status(400).json({message:'key required'});
    const flag=await FeatureFlag.findOneAndUpdate(
      {key},
      {enabled:enabled===true,updatedAt:new Date()},
      {upsert:true,new:true}
    );
    if(!global.featureFlags) global.featureFlags={};
    global.featureFlags[key]=enabled===true;
    res.json({success:true,message:key+' '+(enabled?'enabled':'disabled'),flag});
  } catch(e){ res.status(500).json({success:false,message:e.message}); }
});


// ── S109: Admin Email Send (POST /api/admin/email/send) ──────────
router.post('/email/send', verifyToken, async (req, res) => {
  try {
    const { type, subject, body } = req.body
    if (!subject || !body) return res.status(400).json({success:false,message:'Subject aur body required hai'})
    const { sendCustomEmail } = require('../utils/emailService')
    const User = require('../models/User')
    let recipients = []
        let recipientObjs = []
    if (type==='broadcast'||type==='reminder'||type==='result'||type==='announcement'||type==='welcome'||type==='custom'||true) {
      const students = await User.collection.find(
        {role:'student',banned:{$ne:true}},{projection:{email:1}}
      ).toArray()
          recipientObjs = students.filter(s=>s.email&&!s.email.includes('@proverank.com')).map(s=>({email:s.email,name:s.name||'Student'}))
          recipients = recipientObjs.map(r=>r.email)
    }
          // admin email removed
          // admin fallback removed
    // Send individually with name personalization
        let sentCount = 0
        for(const r of recipientObjs){
          try{
            const personalBody = body.replace(/{student_name}/g, r.name).replace(/{date}/g, new Date().toLocaleDateString('en-IN'))
            await sendCustomEmail([r.email], subject, personalBody)
            sentCount++
          }catch(e){console.error('Failed:',r.email,e.message)}
        }
        const result = {success:true, message:'Sent to '+sentCount+' students!'}
    if (!result.success) return res.status(500).json({success:false,message:'Email failed: '+(result.error||'Unknown')})
    res.json({success:true,message:`Email sent to ${recipients.length} recipient(s)`})
  } catch(e){
    console.error('[S109]',e.message)
    res.status(500).json({success:false,message:e.message})
  }
})


// ── S109 Option B: Email Template Routes ─────────────────────────
const EmailTemplate = require('../models/EmailTemplate')

// Save template to MongoDB
router.post('/email/template/save', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { type, subject, body } = req.body
    if (!type || !subject || !body)
      return res.status(400).json({ success:false, message:'type, subject, body required' })
    const template = await EmailTemplate.findOneAndUpdate(
      { type },
      { type, subject, htmlBody:body, active:true, updatedBy:req.user.email, updatedAt:new Date() },
      { upsert:true, new:true }
    )
    res.json({ success:true, message:`${type} template saved & activated!`, template })
  } catch(e) { res.status(500).json({ success:false, message:e.message }) }
})

// Get saved template by type
router.get('/email/template/:type', verifyToken, async (req, res) => {
  try {
    const template = await EmailTemplate.findOne({ type: req.params.type })
    if (!template) return res.json({ success:false, message:'Template not saved yet' })
    res.json({ success:true, template })
  } catch(e) { res.status(500).json({ success:false, message:e.message }) }
})

// Get all templates
router.get('/email/templates', verifyToken, async (req, res) => {
  try {
    const templates = await EmailTemplate.find({})
    res.json({ success:true, templates })
  } catch(e) { res.status(500).json({ success:false, message:e.message }) }
})

// Broadcast — Manual send to all students
router.post('/email/send', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { type, subject, body } = req.body
    if (!subject || !body)
      return res.status(400).json({ success:false, message:'Subject aur body required' })
    const { sendCustomEmail } = require('../utils/emailService')
    const User = require('../models/User')
    const students = await User.collection.find(
      { role:'student', banned:{ $ne:true } },
      { projection:{ email:1 } }
    ).toArray()
    let recipientObjs = students.map(s=>({email:s.email,name:s.name||'Student'})).filter(r=>r.email)
        let recipients = recipientObjs.map(r=>r.email)
    const adminEmail = req.user?.email || 'admin@proverank.com'
    // adminEmail unshift removed — only student emails
    if (recipients.length===0) recipients = [adminEmail]
    const result = await sendCustomEmail(recipients, subject, body)
    if (!result.success) return res.status(500).json({ success:false, message:result.error })
    res.json({ success:true, message:`Broadcast sent to ${recipients.length} students!` })
  } catch(e) { res.status(500).json({ success:false, message:e.message }) }
})

module.exports = router

// GLOBAL SEARCH API (M12)
router.get('/global-search', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { q = '' } = req.query
    if (!q || q.length < 2) return res.json({ success: true, results: { students: [], admins: [], exams: [], questions: [], batches: [] } })
    const rx = new RegExp(q, 'i')
    const db = req.app.locals.db || router.db
    const col = (name) => require('mongoose').connection.db.collection(name)
    const [students, admins, exams, questions, batches] = await Promise.all([
      col('students').find({ role: 'student', $or: [{ name: rx }, { email: rx }, { studentId: rx }] }).limit(8).project({ name: 1, email: 1, studentId: 1 }).toArray(),
      col('students').find({ role: { $in: ['admin', 'superadmin'] }, $or: [{ name: rx }, { email: rx }, { adminId: rx }] }).limit(6).project({ name: 1, email: 1, adminId: 1, role: 1 }).toArray(),
      col('exams').find({ $or: [{ title: rx }, { status: rx }] }).limit(8).project({ title: 1, status: 1, createdAt: 1 }).toArray(),
      col('questions').find({ $or: [{ text: rx }, { subject: rx }, { chapter: rx }] }).limit(8).project({ text: 1, subject: 1, chapter: 1, difficulty: 1 }).toArray(),
      col('batches').find({ name: rx }).limit(6).project({ name: 1, description: 1 }).toArray()
    ])
    res.json({ success: true, results: { students, admins, exams, questions, batches } })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// Global search for admin role too
router.get('/global-search-admin', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { q = '' } = req.query
    if (!q || q.length < 2) return res.json({ success: true, results: { students: [], admins: [], exams: [], questions: [], batches: [] } })
    const rx = new RegExp(q, 'i')
    const col = (name) => require('mongoose').connection.db.collection(name)
    const [students, exams, questions, batches] = await Promise.all([
      col('students').find({ role: 'student', $or: [{ name: rx }, { email: rx }, { studentId: rx }] }).limit(8).project({ name: 1, email: 1, studentId: 1 }).toArray(),
      col('exams').find({ $or: [{ title: rx }, { status: rx }] }).limit(8).project({ title: 1, status: 1 }).toArray(),
      col('questions').find({ $or: [{ text: rx }, { subject: rx }, { chapter: rx }] }).limit(8).project({ text: 1, subject: 1, chapter: 1, difficulty: 1 }).toArray(),
      col('batches').find({ name: rx }).limit(6).project({ name: 1, description: 1 }).toArray()
    ])
    res.json({ success: true, results: { students, admins: [], exams, questions, batches } })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})
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
const { studentAnnouncementRoutes, adminAnnouncementRoutes } = require('./routes/announcements'); // F42A/F42B
app.use('/api/admin/batch-controls',  adminBatchControlRoutes);
app.use('/api/student/batch-extras',  studentBatchExtrasRoutes);
app.use('/api/announcements', studentAnnouncementRoutes);          // F42B — student-facing
app.use('/api/admin/announcements', adminAnnouncementRoutes);      // F42A — admin-facing

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
echo "  F42A/F42B BACKEND v2 — VERIFICATION"
echo "════════════════════════════════════════════════════"
PASS=0; TOTAL=0
check() {
  TOTAL=$((TOTAL+1))
  if grep -q "$2" "$1" 2>/dev/null; then echo "✅ $3"; PASS=$((PASS+1)); else echo "❌ $3"; fi
}

M="$SRC_DIR/models/Announcement.js"
R="$SRC_DIR/routes/announcements.js"
S="$SRC_DIR/routes/adminSystem.js"

echo "── 1) 5 types ──"
check "$M" "enum: \['exam', 'update', 'result', 'maintenance', 'urgent'\]" "Type enum expanded to 5 (added maintenance)"
check "$S" "type: 'maintenance'" "Maintenance auto-trigger now uses dedicated 'maintenance' type"

echo "── 2) 4 audience modes ──"
check "$M" "enum: \['all', 'batch', 'testseries', 'students'\]" "Audience mode enum expanded to 4 (added testseries)"
check "$M" "testSeriesIds:" "Separate testSeriesIds field added"
check "$R" "audience.mode === 'batch' || audience.mode === 'testseries'" "resolveAudience handles testseries mode"
check "$R" "'audience.mode': 'testseries', 'audience.testSeriesIds'" "Student list query matches testseries audience"

echo "── 3) Chunked email sending ──"
check "$R" "function sendChunkedEmails" "Chunked email helper added"
check "$R" "CHUNK_SIZE = 50" "Chunk size = 50 recipients per batch"
check "$R" "Promise.allSettled(chunk.map" "Chunk processed in parallel"
check "$R" "rawMessage.replace(/{student_name}/g" "Per-recipient {student_name} personalization preserved"
check "$R" "doc.emailStats = await sendChunkedEmails" "POST / uses chunked sender"

echo "── 4) Duplicate vs Resend ──"
check "$R" "adminRouter.post('/:id/resend'" "Resend endpoint still present (sends immediately)"
check "$R" "adminRouter.post('/:id/duplicate'" "NEW Duplicate endpoint added (creates draft, does not send)"
check "$R" "status: 'draft', expiryDate: orig.expiryDate," "Duplicate creates a draft copy (not sent)"
check "$R" "targetCount: 0," "Duplicate has 0 recipients resolved (never sent)"

echo "── Unread-count endpoint (supports frontend v2 fix) ──"
check "$R" "studentRouter.get('/unread-count'" "New lightweight unread-count endpoint for bell polling"

echo "────────────────────────────────────────────────────"
echo "  $PASS / $TOTAL backend checks passed"
echo "════════════════════════════════════════════════════"
if [ "$PASS" -eq "$TOTAL" ]; then
  echo "🎉 All 4 backend changes verified!"
else
  echo "⚠️  Review the ❌ lines above."
fi
