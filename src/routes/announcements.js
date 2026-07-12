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
