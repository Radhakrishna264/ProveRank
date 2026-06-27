#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
#  ProveRank — Feature 33: All Exams — List, Filter, Search
#  BACKEND fix / upgrade script  (run on the BACKEND Replit project root)
#  Also fixes 2 pre-existing bugs found while building this feature:
#   1) Exam schedule (start/end date+time) was sent under non-existent flat
#      fields and silently dropped — broke date-range filter + countdown chips.
#   2) seriesName was never populated — broke series-based filtering.
#  No python used — pure bash + node (per project rules).
# ════════════════════════════════════════════════════════════════════════════
set -e

echo "════════════════════════════════════════════════"
echo " Feature 33 — All Exams — BACKEND setup"
echo "════════════════════════════════════════════════"

# ── locate backend project root (the index.js that requires examWizardRoutes) ─
INDEX_FILE=$(grep -rl "require('./routes/examWizardRoutes')" --include="index.js" . 2>/dev/null | head -1)
if [ -z "$INDEX_FILE" ]; then
  echo "❌ index.js (jisme examWizardRoutes required ho) nahi mila."
  echo "   Ye script apne BACKEND project ke root folder se chalao."
  exit 1
fi
BASE_DIR=$(dirname "$INDEX_FILE")
echo "✓ Backend root mila: $BASE_DIR"

EXAM_MODEL="$BASE_DIR/models/Exam.js"
WIZARD_ROUTES="$BASE_DIR/routes/examWizardRoutes.js"

if [ ! -f "$EXAM_MODEL" ]; then
  echo "❌ models/Exam.js expected yahan tha par nahi mila: $EXAM_MODEL"
  exit 1
fi
if [ ! -f "$WIZARD_ROUTES" ]; then
  echo "❌ routes/examWizardRoutes.js expected yahan tha par nahi mila: $WIZARD_ROUTES"
  exit 1
fi

mkdir -p "$BASE_DIR/routes"

# ── backup everything before any overwrite ────────────────────────────────────
cp "$INDEX_FILE" "$INDEX_FILE.bak_feat33"
cp "$EXAM_MODEL" "$EXAM_MODEL.bak_feat33"
cp "$WIZARD_ROUTES" "$WIZARD_ROUTES.bak_feat33"
echo "✓ Backups bana diye (.bak_feat33)"
echo ""
# ── 1) routes/examListing.js — NEW FILE (Feature 33 main endpoints) ─────────
echo "→ Writing routes/examListing.js ..."
cat > "$BASE_DIR/routes/examListing.js" << '__PRRANK_EOF_LISTING__'
/**
 * ProveRank — Feature 33: All Exams — List, Filter, Search
 * Mounted at /api/exams-manage (deliberately a DIFFERENT prefix from /api/exams,
 * which is already shared by 6 other routers — exam.js, examFeatures.js,
 * examPatchRoutes, examPaperRoutes, examExtraRoutes, examSubmissionRoutes —
 * to avoid any risk of an existing GET /:id style route silently shadowing
 * these new endpoints depending on mount order).
 *
 * Delete (33.9) and Clone (33.9) reuse the EXISTING, already-working
 * DELETE /api/exams/:id and POST /api/exams/:examId/clone — not duplicated here.
 *
 * Status mapping note: the real Exam schema enum is
 *   draft / scheduled / live / ended
 * which the UI shows as: Draft / Upcoming / Active / Completed.
 *
 *  33.1  GET  /list             paginated/filtered/sorted exam list + stats bar counts
 *  33.2  search query param     SMART search by title
 *  33.3  status query param     filter by draft/scheduled/live/ended
 *  33.4  category/subject       filter by category + subject
 *  33.5  batch/series           filter by batch + seriesName
 *  33.6  startDate/endDate      filter by schedule.startTime range
 *  33.7  studentCount           computed per exam via Attempt aggregation
 *  33.8  sort query param       newest/oldest/dateAsc/dateDesc
 *  33.9  (reuses existing)      Edit→quick-edit below, Clone/Delete reuse routes/exam.js
 *  33.10 page/limit             pagination
 *  33.11 PATCH /:id/publish     quick status toggle (Draft → Scheduled/Live)
 *  33.12 mine/createdBy         "My Created Exams" + superadmin admin-picker
 *  33.14 GET /:id/analytics     attempts, avg score, pass%, leaderboard, distribution
 *  33.17 GET /export            CSV/XLSX export of the filtered list
 *  33.18 needsAttention         filter — no batch assigned OR 0 questions
 *  33.20 PATCH /:id/pin         pin toggle
 *  33.27 POST /bulk-delete,
 *        POST /bulk-publish     bulk actions
 */
const express = require('express')
const router  = express.Router()
const { verifyToken, isAdmin } = require('../middleware/auth')
const Exam = require('../models/Exam')

// ── 29-style helper: who can see what (33.12) ─────────────────────────────────
function visibilityFilter(req) {
  const f = {}
  if (req.user.role !== 'superadmin') {
    f.createdBy = req.user.id // admins always see only their own
  } else {
    if (req.query.mine === 'true') f.createdBy = req.user.id
    else if (req.query.createdBy) f.createdBy = req.query.createdBy
    // else: superadmin sees everyone's exams
  }
  return f
}

function buildFilter(req) {
  const { search, status, category, subject, batch, series, startDate, endDate, needsAttention } = req.query
  const filter = visibilityFilter(req)
  if (search && String(search).trim()) filter.title = new RegExp(String(search).trim(), 'i')
  if (status) {
    const statuses = String(status).split(',').map(s => s.trim()).filter(Boolean)
    if (statuses.length) filter.status = { $in: statuses }
  }
  if (category) filter.category = category
  if (subject) filter.subject = subject
  if (batch) filter.batch = batch
  if (series) filter.seriesName = series
  if (startDate || endDate) {
    filter['schedule.startTime'] = {}
    if (startDate) filter['schedule.startTime'].$gte = new Date(startDate)
    if (endDate) filter['schedule.startTime'].$lte = new Date(endDate)
  }
  if (needsAttention === 'true') {
    filter.$or = [{ batch: '' }, { batch: null }, { questions: { $size: 0 } }]
  }
  return filter
}

// ════════════════════════════════════════════════════════════════
// 33.4 / 33.5 — FILTER OPTIONS (dynamic distinct values — always matches real data)
// ════════════════════════════════════════════════════════════════
router.get('/filter-options', verifyToken, isAdmin, async (req, res) => {
  try {
    const filter = req.user.role === 'superadmin' ? {} : { createdBy: req.user.id }
    const [categories, subjects, batches, series] = await Promise.all([
      Exam.distinct('category', filter),
      Exam.distinct('subject', filter),
      Exam.distinct('batch', filter),
      Exam.distinct('seriesName', filter)
    ])
    res.json({
      success: true,
      categories: categories.filter(Boolean),
      subjects: subjects.filter(Boolean),
      batches: batches.filter(Boolean),
      series: series.filter(Boolean)
    })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.12 — ADMINS LIST (superadmin "view by admin" picker)
// ════════════════════════════════════════════════════════════════
router.get('/admins', verifyToken, isAdmin, async (req, res) => {
  try {
    if (req.user.role !== 'superadmin') return res.status(403).json({ success: false, message: 'Superadmin access required hai' })
    const User = require('../models/User')
    const creatorIds = await Exam.distinct('createdBy')
    const admins = await User.find({ _id: { $in: creatorIds } }).select('name email role')
    const counts = await Exam.aggregate([{ $group: { _id: '$createdBy', count: { $sum: 1 } } }])
    const countMap = {}
    counts.forEach(c => { countMap[String(c._id)] = c.count })
    const result = admins.map(a => ({ _id: a._id, name: a.name, email: a.email, role: a.role, examCount: countMap[String(a._id)] || 0 }))
    res.json({ success: true, admins: result })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.1 — MAIN LIST (filters + sort + pagination + stats bar)
// ════════════════════════════════════════════════════════════════
router.get('/list', verifyToken, isAdmin, async (req, res) => {
  try {
    const filter = buildFilter(req)

    let sortSpec = { createdAt: -1 } // newest (default)
    if (req.query.sort === 'oldest') sortSpec = { createdAt: 1 }
    else if (req.query.sort === 'dateAsc') sortSpec = { 'schedule.startTime': 1 }
    else if (req.query.sort === 'dateDesc') sortSpec = { 'schedule.startTime': -1 }
    const finalSort = { isPinned: -1, ...sortSpec } // pinned always first — 33.20

    const page = Math.max(1, parseInt(req.query.page) || 1)
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20))
    const skip = (page - 1) * limit

    const total = await Exam.countDocuments(filter)
    const exams = await Exam.find(filter)
      .select('title category subject type duration totalMarks status batch seriesName schedule createdAt isPinned questions createdBy markingScheme assignmentType')
      .sort(finalSort).skip(skip).limit(limit)
      .populate('createdBy', 'name email')
      .lean()

    // 33.7 — student count per exam (distinct attempters), single batched aggregation
    const Attempt = require('../models/Attempt')
    const examIds = exams.map(e => e._id)
    const counts = examIds.length ? await Attempt.aggregate([
      { $match: { examId: { $in: examIds } } },
      { $group: { _id: '$examId', students: { $addToSet: '$studentId' } } }
    ]) : []
    const countMap = {}
    counts.forEach(c => { countMap[String(c._id)] = (c.students || []).length })
    exams.forEach(e => {
      e.studentCount = countMap[String(e._id)] || 0
      e.questionCount = (e.questions || []).length
      delete e.questions // not needed on the list view, keeps payload light
    })

    // 33.21 — stats bar counts, scoped to the same visibility (not the other filters)
    const statsBase = visibilityFilter(req)
    const [totalAll, draftC, scheduledC, liveC, endedC] = await Promise.all([
      Exam.countDocuments(statsBase),
      Exam.countDocuments({ ...statsBase, status: 'draft' }),
      Exam.countDocuments({ ...statsBase, status: 'scheduled' }),
      Exam.countDocuments({ ...statsBase, status: 'live' }),
      Exam.countDocuments({ ...statsBase, status: 'ended' })
    ])

    res.json({
      success: true,
      exams,
      total, page, totalPages: Math.max(1, Math.ceil(total / limit)),
      stats: { total: totalAll, draft: draftC, scheduled: scheduledC, live: liveC, ended: endedC }
    })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.14 — ANALYTICS QUICK VIEW (side panel)
// ════════════════════════════════════════════════════════════════
router.get('/:id/analytics', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).select('title totalMarks duration category subject type status schedule questions')
    if (!exam) return res.status(404).json({ success: false, message: 'Exam nahi mila' })
    const Attempt = require('../models/Attempt')
    const tm = exam.totalMarks || 720
    const passMark = tm * 0.5

    const summaryAgg = await Attempt.aggregate([
      { $match: { examId: exam._id, status: { $in: ['submitted', 'auto_submitted'] } } },
      { $group: {
          _id: null,
          totalAttempts: { $sum: 1 },
          avgScore: { $avg: '$score' },
          maxScore: { $max: '$score' },
          minScore: { $min: '$score' },
          passed: { $sum: { $cond: [{ $gte: ['$score', passMark] }, 1, 0] } }
      } }
    ])
    const s = summaryAgg[0] || { totalAttempts: 0, avgScore: 0, maxScore: 0, minScore: 0, passed: 0 }
    const passRate = s.totalAttempts ? (s.passed / s.totalAttempts) * 100 : 0
    const startedCount = await Attempt.countDocuments({ examId: exam._id })
    const completionRate = startedCount ? (s.totalAttempts / startedCount) * 100 : 0

    const leaderboard = await Attempt.aggregate([
      { $match: { examId: exam._id, status: { $in: ['submitted', 'auto_submitted'] } } },
      { $sort: { score: -1 } },
      { $limit: 10 },
      { $lookup: { from: 'users', localField: 'studentId', foreignField: '_id', as: 'student' } },
      { $unwind: { path: '$student', preserveNullAndEmptyArrays: true } },
      { $project: { score: 1, studentName: '$student.name', studentEmail: '$student.email', createdAt: 1 } }
    ])

    const bucketSize = tm > 0 ? tm / 5 : 1
    const scoreDistribution = await Attempt.aggregate([
      { $match: { examId: exam._id, status: { $in: ['submitted', 'auto_submitted'] } } },
      { $bucket: {
          groupBy: '$score',
          boundaries: [0, bucketSize, bucketSize * 2, bucketSize * 3, bucketSize * 4, tm + 1],
          default: 'other',
          output: { count: { $sum: 1 } }
      } }
    ])

    res.json({
      success: true,
      exam: {
        title: exam.title, totalMarks: exam.totalMarks, duration: exam.duration,
        category: exam.category, subject: exam.subject, type: exam.type, status: exam.status,
        schedule: exam.schedule, questionCount: (exam.questions || []).length
      },
      totalAttempts: s.totalAttempts,
      startedCount,
      completionRate: Math.round(completionRate * 10) / 10,
      avgScore: s.avgScore ? Math.round(s.avgScore * 10) / 10 : 0,
      maxScore: s.maxScore || 0,
      minScore: s.minScore || 0,
      passCount: s.passed,
      passRate: Math.round(passRate * 10) / 10,
      leaderboard,
      scoreDistribution
    })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.11 — QUICK STATUS TOGGLE (Draft ↔ Scheduled/Live)
// ════════════════════════════════════════════════════════════════
router.patch('/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id)
    if (!exam) return res.status(404).json({ success: false, message: 'Exam nahi mila' })
    if (exam.status === 'draft') {
      const now = new Date()
      exam.status = (exam.schedule && exam.schedule.startTime && new Date(exam.schedule.startTime) > now) ? 'scheduled' : 'live'
    } else {
      exam.status = 'draft'
    }
    await exam.save()
    res.json({ success: true, status: exam.status, message: `Exam status: ${exam.status}` })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.20 — PIN TOGGLE
// ════════════════════════════════════════════════════════════════
router.patch('/:id/pin', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id)
    if (!exam) return res.status(404).json({ success: false, message: 'Exam nahi mila' })
    exam.isPinned = !exam.isPinned
    await exam.save()
    res.json({ success: true, isPinned: exam.isPinned })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.9 — QUICK EDIT (core fields, without re-running the whole wizard)
// ════════════════════════════════════════════════════════════════
router.put('/:id/quick-edit', verifyToken, isAdmin, async (req, res) => {
  try {
    const b = req.body
    const exam = await Exam.findById(req.params.id)
    if (!exam) return res.status(404).json({ success: false, message: 'Exam nahi mila' })

    if (b.title !== undefined) exam.title = b.title
    if (b.category !== undefined) exam.category = b.category
    if (b.subject !== undefined) exam.subject = b.subject
    if (b.type !== undefined) exam.type = b.type
    if (b.duration !== undefined) exam.duration = parseInt(b.duration) || exam.duration
    if (b.totalMarks !== undefined) exam.totalMarks = parseInt(b.totalMarks) || exam.totalMarks
    if (b.batch !== undefined) exam.batch = b.batch
    if (b.seriesName !== undefined) exam.seriesName = b.seriesName
    if (b.watermark !== undefined) exam.watermark = !!b.watermark
    if (b.customInstructions !== undefined) exam.customInstructions = b.customInstructions
    if (b.status !== undefined) exam.status = b.status

    if (b.correctMarks !== undefined || b.incorrectMarks !== undefined) {
      exam.markingScheme = exam.markingScheme || {}
      if (b.correctMarks !== undefined) exam.markingScheme.correct = parseFloat(b.correctMarks)
      if (b.incorrectMarks !== undefined) exam.markingScheme.incorrect = parseFloat(b.incorrectMarks)
      exam.markModified('markingScheme')
    }
    if (b.startTime !== undefined || b.endTime !== undefined) {
      exam.schedule = exam.schedule || {}
      if (b.startTime !== undefined) exam.schedule.startTime = b.startTime ? new Date(b.startTime) : null
      if (b.endTime !== undefined) exam.schedule.endTime = b.endTime ? new Date(b.endTime) : null
      exam.markModified('schedule')
    }

    await exam.save()
    res.json({ success: true, message: 'Exam update ho gaya ✅', exam })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.27 — BULK ACTIONS
// ════════════════════════════════════════════════════════════════
router.post('/bulk-delete', verifyToken, isAdmin, async (req, res) => {
  try {
    const { ids } = req.body
    if (!Array.isArray(ids) || !ids.length) return res.status(400).json({ success: false, message: 'ids array required hai' })
    const filter = { _id: { $in: ids } }
    if (req.user.role !== 'superadmin') filter.createdBy = req.user.id
    const result = await Exam.deleteMany(filter)
    res.json({ success: true, message: `${result.deletedCount} exam(s) delete ho gaye`, deletedCount: result.deletedCount })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

router.post('/bulk-publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const { ids } = req.body
    if (!Array.isArray(ids) || !ids.length) return res.status(400).json({ success: false, message: 'ids array required hai' })
    const filter = { _id: { $in: ids }, status: 'draft' }
    if (req.user.role !== 'superadmin') filter.createdBy = req.user.id
    const list = await Exam.find(filter)
    const now = new Date()
    let updated = 0
    for (const exam of list) {
      exam.status = (exam.schedule && exam.schedule.startTime && new Date(exam.schedule.startTime) > now) ? 'scheduled' : 'live'
      await exam.save()
      updated++
    }
    res.json({ success: true, message: `${updated} exam(s) published`, updated })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 33.17 — EXPORT (CSV / XLSX) — same filters as /list
// ════════════════════════════════════════════════════════════════
router.get('/export', verifyToken, isAdmin, async (req, res) => {
  try {
    const filter = buildFilter(req)
    const exams = await Exam.find(filter)
      .select('title category subject type duration totalMarks status batch seriesName schedule createdAt isPinned questions')
      .lean()

    const rows = exams.map(e => ({
      Title: e.title,
      Category: e.category,
      Subject: e.subject,
      Type: e.type,
      'Duration (min)': e.duration,
      'Total Marks': e.totalMarks,
      Status: e.status,
      Batch: e.batch,
      Series: e.seriesName,
      'Start Time': e.schedule && e.schedule.startTime ? new Date(e.schedule.startTime).toLocaleString() : '',
      'End Time': e.schedule && e.schedule.endTime ? new Date(e.schedule.endTime).toLocaleString() : '',
      Questions: (e.questions || []).length,
      'Created At': e.createdAt ? new Date(e.createdAt).toLocaleString() : '',
      Pinned: e.isPinned ? 'Yes' : 'No'
    }))

    const format = (req.query.format || 'xlsx').toLowerCase()

    if (format === 'csv') {
      const headers = Object.keys(rows[0] || { Title: '' })
      const esc = v => `"${String(v == null ? '' : v).replace(/"/g, '""')}"`
      const csv = [headers.join(','), ...rows.map(r => headers.map(h => esc(r[h])).join(','))].join('\n')
      res.setHeader('Content-Type', 'text/csv')
      res.setHeader('Content-Disposition', 'attachment; filename="ProveRank_Exams.csv"')
      return res.send(csv)
    }

    const XLSX = require('xlsx')
    const ws = XLSX.utils.json_to_sheet(rows)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Exams')
    const buf = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' })
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    res.setHeader('Content-Disposition', 'attachment; filename="ProveRank_Exams.xlsx"')
    res.send(buf)
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

module.exports = router
__PRRANK_EOF_LISTING__

# ── 2) models/Exam.js — FULL REWRITE (adds isPinned field, 33.20) ───────────
echo "→ Rewriting $EXAM_MODEL ..."
cat > "$EXAM_MODEL" << '__PRRANK_EOF_EXAMMODEL__'
const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  title:        { type: String, required: true, trim: true },
  subject:      { type: String, default: 'NEET' },
  duration:     { type: Number, required: true },
  totalMarks:   { type: Number, default: 720 },
  questions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }], // QsBank Integration

  sections: [{
    name:          String,
    subject:       String,
    questionCount: Number,
    timeLimit:     Number,
    marks:         Number,
    fromQNo:       Number, // F19B.5.21 / F20B.5.21 / F21B.8.21 — subject Q-no range start
    toQNo:         Number  // F19B.5.21 / F20B.5.21 / F21B.8.21 — subject Q-no range end
  }],

  markingScheme: {
    correct:     { type: Number, default: 4 },
    incorrect:   { type: Number, default: -1 },
    unattempted: { type: Number, default: 0 },
    msqMode:     { type: String, enum: ['ALL_OR_NOTHING', 'PARTIAL_NEGATIVE'], default: 'ALL_OR_NOTHING' }
  },

  password:   { type: String, default: '' },

  schedule: {
    startTime:  Date,
    endTime:    Date,
    resultTime: Date  // when result/scorecard becomes visible to students
  },

  audioMonitoringEnabled: { type: Boolean, default: false },
  status: { type: String, enum: ['draft', 'scheduled', 'live', 'ended'], default: 'draft' },

  batch:    { type: String, default: '' },

  // F19B.6.8 / F20B.6.8 / F21B.9.7 — Multi-batch assign toggle (additional batch IDs besides primary `batch`)
  multiBatch: [{ type: String, default: [] }],

  // F19B.6 / F20B.6 / F21B.9 — Assignment Type selector
  assignmentType: { type: String, enum: ['batch', 'series', 'mini_test', 'individual'], default: 'individual' },

  // F19B.6.2/6.3 / F20B.6.2/6.3 / F21B.9.2/9.3 — Test Series / Mini Test Series label (grouping, also used for Step-8 "exam series/group")
  seriesName: { type: String, default: '' },

  category: { type: String, enum: ['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test', 'Mini Test'], default: 'Full Mock' },

  whitelist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  watermark:          { type: Boolean, default: true },
  customInstructions: { type: String, default: '' },

  reviewWindow: {
    enabled:         { type: Boolean, default: false },
    durationMinutes: { type: Number, default: 0 },
  fullscreenForce: { type: Boolean, default: false },
  fullscreenWarnings: { type: Number, default: 0 }
  },

  template:   { type: String, default: '' },
  difficulty: { type: String, default: 'Mixed' },
  type:       { type: String, default: 'NEET' },

  waitingRoomEnabled: { type: Boolean, default: false },
  waitingRoomMinutes: { type: Number, default: 10 },

  maxAttempts:    { type: Number, default: 1 },
  reattemptCount: { type: String, enum: ['best', 'last'], default: 'last' },
  // F19B.5.16 / F20B.5.16 / F21B.8.16 — Unlimited attempt option (maxAttempts auto-set to a large number when true)
  unlimitedAttempts: { type: Boolean, default: false },
  questionSnapshot:  { type: Array, default: [] },
  snapshotLocked:    { type: Boolean, default: false },
  snapshotLockedAt:  { type: Date, default: null },

  whitelistEnabled:    { type: Boolean, default: false },
  whitelistedStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  whitelistedGroups:   [{ type: String }],

  // F19B.5.5 / F20B.5.5 / F21B.8.5 — Subject wise Qs count input
  subjectWiseCount: [{ subject: String, count: Number }],
  // F19B.5.4 / F20B.5.4 / F21B.8.4 — Total Questions requested (auto-select N out of M parsed)
  totalQuestionsRequested: { type: Number, default: 0 },

  // F19B.8.1 / F20B.8.1 / F21B.11.1 — Scheduled auto-publish
  scheduledPublish: {
    enabled:   { type: Boolean, default: false },
    publishAt: { type: Date, default: null }
  },
  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle
  notifyStudents: { type: Boolean, default: false },
  // F19B.8.4 / F20B.8.4 / F21B.11.4 — Save as Template
  isTemplate: { type: Boolean, default: false },

  // F19B.7 / F20B / F21B — source tracking (which method created this exam + parse stats)
  sourceMeta: {
    sourceType:     { type: String, enum: ['paste', 'excel', 'pdf', 'manual', ''], default: '' },
    fileName:        { type: String, default: '' },
    uploadedAt:      { type: Date, default: null },
    pageCount:       { type: Number, default: 0 },
    totalParsed:     { type: Number, default: 0 },
    totalErrors:     { type: Number, default: 0 },
    totalDuplicates: { type: Number, default: 0 }
  },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  // Feature 33.20 — Pinned exams (important exams shown at top of All Exams list)
  isPinned: { type: Boolean, default: false }

}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);

__PRRANK_EOF_EXAMMODEL__

# ── 3) routes/examWizardRoutes.js — FULL REWRITE (schedule + seriesName fix) ─
echo "→ Rewriting $WIZARD_ROUTES ..."
cat > "$WIZARD_ROUTES" << '__PRRANK_EOF_WIZARDROUTES__'
/**
 * ProveRank — Features 26+27+28: Create Exam Wizard Routes
 * Handles: Template load, Draft create, Questions import,
 *          Smart suggest, Multi-set, Publish, Schedule, Clone, Notify
 */
const express   = require('express');
const router    = express.Router();
const mongoose  = require('mongoose');
const multer    = require('multer');
const XLSX      = require('xlsx');
const pdfParse  = require('pdf-parse');
const { verifyToken, isAdmin } = require('../middleware/auth');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });

// ── Helpers ───────────────────────────────────────────────────────────────────
const getExam     = () => mongoose.model('Exam');
const getQuestion = () => mongoose.model('Question');
const getUser     = () => mongoose.model('User');

function parseAnswerKey(text = '') {
  const map = {};
  text.split('\n').forEach(line => {
    const m = line.match(/^(\d+)[.\-\)]\s*([A-Da-d1-4])/);
    if (m) {
      const n = parseInt(m[1]), a = m[2].toUpperCase();
      map[n] = ['A','B','C','D'].indexOf(a) !== -1 ? ['A','B','C','D'].indexOf(a) : parseInt(a) - 1;
    }
  });
  return map;
}

function parseCopyPaste(text = '', answerKey = {}) {
  const blocks = text.split(/\n(?=\d+[\.\)]\s)/);
  const parsed = [];
  blocks.forEach((block, idx) => {
    const lines = block.trim().split('\n').filter(l => l.trim());
    if (lines.length < 2) return;
    const qm = lines[0].match(/^(\d+)[\.\)]\s*(.*)/);
    if (!qm) return;
    const qNum = parseInt(qm[1]);
    let qText  = qm[2].trim();
    const opts = [];
    let explanation = '';
    lines.slice(1).forEach(line => {
      const om = line.match(/^([A-Da-d][\.\)]\s*)(.*)/);
      if (om) opts.push(om[2].trim());
      else if (/^(exp|explanation|sol)[:\s]/i.test(line)) explanation = line.replace(/^[^:]+:\s*/i, '');
      else if (!opts.length) qText += ' ' + line.trim();
    });
    if (qText && opts.length >= 2) {
      const correct = answerKey[qNum] !== undefined ? answerKey[qNum] : 0;
      parsed.push({ qNum, text: qText.trim(), options: opts, correct: [correct], explanation });
    }
  });
  return parsed;
}

// ════════════════════════════════════════════════════════════════
// Templates (26 — pre-configured exam templates)
// ════════════════════════════════════════════════════════════════
router.get('/exam-wizard/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    const defaults = [
      { id: 'neet_full',     name: 'NEET Full Mock',      icon: '🎯', subject: 'Full Mock', category: 'Full Mock',    totalQs: 180, subjectQs: { Physics: 45, Chemistry: 45, Biology: 90 }, duration: 200, totalMarks: 720, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_chapter',  name: 'NEET Chapter Test',   icon: '📖', subject: 'Physics',   category: 'Chapter Test', totalQs: 45,  subjectQs: { Physics: 45 }, duration: 60, totalMarks: 180, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_part',     name: 'NEET Part Test',      icon: '⚡', subject: 'Full Mock', category: 'Part Test',    totalQs: 90,  subjectQs: { Physics: 45, Chemistry: 45 }, duration: 100, totalMarks: 360, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_grand',    name: 'Grand Test',           icon: '🏆', subject: 'Full Mock', category: 'Grand Test',   totalQs: 180, subjectQs: { Physics: 45, Chemistry: 45, Biology: 90 }, duration: 200, totalMarks: 720, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_mini',     name: 'Mini Test',            icon: '⚡', subject: 'Full Mock', category: 'Mini Test',    totalQs: 30,  subjectQs: { Physics: 10, Chemistry: 10, Biology: 10 }, duration: 30,  totalMarks: 120, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'jee_main',      name: 'JEE Main Mock',       icon: '⚙️', subject: 'Full Mock', category: 'Full Mock',    totalQs: 90,  subjectQs: { Physics: 30, Chemistry: 30, Math: 30 }, duration: 180, totalMarks: 300, correctMarks: 4, negativeMarks: 1, examType: 'JEE', examLevel: 'JEE_MAINS' },
      { id: 'pyq_test',      name: 'PYQ Practice',        icon: '📅', subject: 'Full Mock', category: 'PYQ',          totalQs: 50,  subjectQs: { Physics: 17, Chemistry: 17, Biology: 16 }, duration: 70,  totalMarks: 200, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'custom',        name: 'Custom Exam',         icon: '✏️', subject: 'Custom',    category: 'Chapter Test', totalQs: 30,  subjectQs: {},  duration: 45, totalMarks: 120, correctMarks: 4, negativeMarks: 1, examType: 'Custom', examLevel: 'NEET' },
    ];
    // Also get any saved custom templates from DB
    let dbTemplates = [];
    try {
      const ExamTemplate = mongoose.model('ExamTemplate');
      dbTemplates = await ExamTemplate.find({ createdBy: req.user.id }).sort({ createdAt: -1 }).limit(10);
    } catch {}
    res.json({ success: true, templates: [...defaults, ...dbTemplates.map((t) => ({ ...t.toObject(), isCustom: true }))] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.4 — Save as Template
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    let ExamTemplate;
    try {
      ExamTemplate = mongoose.model('ExamTemplate');
    } catch {
      const s = new mongoose.Schema({ name: String, icon: { type: String, default: '📋' }, subject: String, category: String, totalQs: Number, subjectQs: Object, duration: Number, totalMarks: Number, correctMarks: Number, negativeMarks: Number, examType: String, markingScheme: Object, instructions: String, createdBy: mongoose.Schema.Types.ObjectId }, { timestamps: true });
      ExamTemplate = mongoose.model('ExamTemplate', s);
    }
    const t = await ExamTemplate.create({ ...req.body, createdBy: req.user.id });
    res.json({ success: true, message: 'Template saved!', template: t });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 26 — Create Exam (Step 1 — full wizard payload)
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/create', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const {
      title, subject, category, totalQs, subjectQs, examType, duration,
      totalMarks, correctMarks, negativeMarks, startDate, endDate,
      instructions, passwordEnabled, password,
      whitelist, waitingRoom, waitingMinutes,
      reattempt, reattemptUnlimited, reviewWindow, sectionWise, watermark,
      liveQsRange, assignType, batchId, testSeriesId, miniSeriesId, multiBatches,
      status
    } = req.body;

    if (!title || !title.trim())   return res.status(400).json({ success: false, message: 'Exam title is required' });
    if (!duration || duration < 1) return res.status(400).json({ success: false, message: 'Duration is required' });

    const examData = {
      title: title.trim(),
      subject: subject || 'NEET',
      type: examType || 'NEET',
      category: category || 'Full Mock',
      totalQs: parseInt(totalQs) || 180,
      subjectQs: subjectQs || {},
      duration: parseInt(duration),
      totalMarks: parseInt(totalMarks) || 720,
      correctMarks: parseFloat(correctMarks) || 4,
      negativeMarks: parseFloat(negativeMarks) || 1,
      schedule: {
        startTime: startDate ? new Date(startDate) : null,
        endTime: endDate ? new Date(endDate) : null
      },
      customInstructions: instructions || '',
      password: passwordEnabled ? (password || '') : '',
      whitelist: whitelist || false,
      waitingRoom: waitingRoom || false,
      waitingMinutes: parseInt(waitingMinutes) || 0,
      reattempt: reattemptUnlimited ? -1 : (parseInt(reattempt) || 1),
      reviewWindow: reviewWindow !== false,
      sectionWise: sectionWise || false,
      watermark: watermark || false,
      liveQsRange: liveQsRange || [],
      batch: batchId || '',
      batches: multiBatches || [],
      testSeriesId: testSeriesId || null,
      miniSeriesId: miniSeriesId || null,
      seriesName: testSeriesId || miniSeriesId || '', // Feature 33.5 — real schema field for series-based filtering
      assignType: assignType || 'open',
      status: status || 'draft',
      questions: [],
      createdBy: req.user.id,
    };

    const exam = await Exam.create(examData);
    res.status(201).json({ success: true, message: 'Exam created!', exam, examId: exam._id });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.1 — Import questions from Question Bank
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/bank', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { questionIds } = req.body;
    if (!questionIds || !questionIds.length) return res.status(400).json({ success: false, message: 'No question IDs provided' });
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const existing = new Set((exam.questions || []).map((q) => String(q)));
    const toAdd = questionIds.filter((id) => !existing.has(String(id)));
    await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: toAdd } } });
    res.json({ success: true, message: `${toAdd.length} questions added`, added: toAdd.length, skipped: questionIds.length - toAdd.length });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.3 — Copy-Paste Upload
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/copypaste', verifyToken, isAdmin, async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const { questionsText, answerKeyText, subject, difficulty } = req.body;
    if (!questionsText) return res.status(400).json({ success: false, message: 'Questions text required' });
    const answerKey = parseAnswerKey(answerKeyText || '');
    const parsed    = parseCopyPaste(questionsText, answerKey);
    if (!parsed.length) return res.status(400).json({ success: false, message: 'No questions parsed. Check format.' });
    let saved = 0; const qIds = [];
    for (const p of parsed) {
      try {
        const q = await Question.create({ text: p.text, options: p.options, correct: p.correct, explanation: p.explanation, subject: subject || 'General', difficulty: difficulty || 'Medium', type: 'SCQ', createdBy: req.user.id, isPYQ: false });
        qIds.push(q._id); saved++;
      } catch {}
    }
    if (qIds.length) await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: qIds } } });
    res.json({ success: true, saved, failed: parsed.length - saved, message: `${saved} questions uploaded` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.4 — Excel Upload
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/excel', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam || !req.file) return res.status(400).json({ success: false, message: !exam ? 'Exam not found' : 'File required' });
    const wb   = XLSX.read(req.file.buffer, { type: 'buffer' });
    const rows = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], { defval: '' });
    let saved = 0; const qIds = []; const errors = [];
    for (const row of rows) {
      const text = String(row['Question'] || row['question'] || '').trim();
      if (!text) continue;
      const opts = ['A','B','C','D'].map(l => String(row[`Option ${l}`] || row[`option_${l.toLowerCase()}`] || row[l] || '').trim()).filter(Boolean);
      if (opts.length < 2) { errors.push(`"${text.slice(0,40)}" — not enough options`); continue; }
      const ca   = String(row['Correct Answer'] || row['correct'] || 'A').toUpperCase().trim();
      const ci   = ['A','B','C','D'].indexOf(ca);
      try {
        const q = await Question.create({ text, options: opts, correct: [ci >= 0 ? ci : 0], subject: String(row['Subject'] || 'General').trim(), chapter: String(row['Chapter'] || '').trim(), difficulty: String(row['Difficulty'] || 'Medium').trim(), explanation: String(row['Explanation'] || '').trim(), hindiText: String(row['Hindi Question'] || '').trim(), type: 'SCQ', createdBy: req.user.id });
        qIds.push(q._id); saved++;
      } catch (e) { errors.push(e.message); }
    }
    if (qIds.length) await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: qIds } } });
    res.json({ success: true, saved, failed: rows.length - saved, errors: errors.slice(0, 5), message: `${saved} questions from Excel` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.4 — PDF Upload
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/pdf', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam || !req.file) return res.status(400).json({ success: false, message: !exam ? 'Exam not found' : 'File required' });
    const pdfData = await pdfParse(req.file.buffer);
    const parsed  = parseCopyPaste(pdfData.text || '', {});
    if (!parsed.length) return res.status(400).json({ success: false, message: 'No questions found in PDF' });
    let saved = 0; const qIds = [];
    for (const p of parsed) {
      try {
        const q = await Question.create({ text: p.text, options: p.options, correct: p.correct, subject: String(req.body.subject || 'General'), difficulty: 'Medium', type: 'SCQ', createdBy: req.user.id });
        qIds.push(q._id); saved++;
      } catch {}
    }
    if (qIds.length) await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: qIds } } });
    res.json({ success: true, saved, failed: parsed.length - saved, pages: pdfData.numpages, message: `${saved} questions from PDF` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.14 — Smart Suggest / Auto-select from Bank
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/smart-suggest', verifyToken, isAdmin, async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const { subjectQs = {}, examLevel = 'NEET', existingIds = [] } = req.body;
    const existingSet = new Set(existingIds.map(String));
    const suggested = [];
    const baseFilter = { isDeleted: { $ne: true }, isArchived: { $ne: true }, approvalStatus: 'approved', _id: { $nin: existingIds } };
    for (const [subj, count] of Object.entries(subjectQs)) {
      if (!count || count <= 0) continue;
      const qs = await Question.find({ ...baseFilter, subject: subj, examLevel: { $in: [examLevel, 'NEET', ''] } }).sort({ usageCount: 1, similarityScore: -1 }).limit(parseInt(count)).select('_id text subject chapter difficulty type');
      suggested.push(...qs);
    }
    // Fallback if not enough
    const needed = Object.values(subjectQs).reduce((s, v) => s + parseInt(v), 0);
    if (suggested.length < needed) {
      const more = await Question.find({ ...baseFilter, _id: { $nin: [...existingIds, ...suggested.map(q => q._id)] } }).limit(needed - suggested.length).select('_id text subject chapter difficulty type');
      suggested.push(...more);
    }
    res.json({ success: true, questions: suggested, total: suggested.length, message: `${suggested.length} questions suggested` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.16 — Duplicate detector
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/duplicate-check', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { questionIds } = req.body;
    if (!questionIds || !questionIds.length) return res.json({ success: true, duplicates: {} });
    const exams = await Exam.find({ questions: { $in: questionIds }, status: { $ne: 'deleted' } }).select('title questions status');
    const map = {};
    questionIds.forEach((id) => {
      const inExams = exams.filter(e => (e.questions || []).some(q => String(q) === String(id)));
      if (inExams.length > 0) map[String(id)] = inExams.map(e => ({ title: e.title, status: e.status }));
    });
    res.json({ success: true, duplicates: map });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.18+27.19 — Multi-set generate (Set A/B/C auto-shuffle)
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/generate-sets', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findById(req.params.id).populate('questions');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const { setCount = 2 } = req.body;
    const count = Math.min(parseInt(setCount) || 2, 6);
    const baseQs = exam.questions || [];
    const sets = [];
    for (let i = 0; i < count; i++) {
      const shuffled = [...baseQs].sort(() => Math.random() - 0.5);
      const setLabel = String.fromCharCode(65 + i); // A, B, C...
      sets.push({
        setLabel,
        questions: shuffled.map(q => ({ _id: q._id, text: q.text, options: q.options, correct: q.correct, explanation: q.explanation, subject: q.subject, chapter: q.chapter, difficulty: q.difficulty }))
      });
    }
    await Exam.findByIdAndUpdate(req.params.id, { multiSets: sets, setCount: count, multiSetEnabled: true });
    res.json({ success: true, sets, setCount: count, message: `${count} sets generated (A–${String.fromCharCode(64 + count)})` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28 — Get full exam details for Review step
// ════════════════════════════════════════════════════════════════
router.get('/exam-wizard/:id/review', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findById(req.params.id).populate('questions', 'text subject chapter difficulty type options correct explanation image').lean();
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    // Student count if batch assigned
    let studentCount = 0;
    try {
      if (exam.batch) { const User = getUser(); studentCount = await User.countDocuments({ role: 'student', batch: exam.batch }); }
    } catch {}
    res.json({ success: true, exam, studentCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.2 — Publish Now
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'published', publishedAt: new Date() }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: 'Exam published!', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.3 — Save as Draft
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/draft', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'draft' }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: 'Saved as draft', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.1 — Schedule auto-publish
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/schedule-publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { publishAt } = req.body;
    if (!publishAt) return res.status(400).json({ success: false, message: 'publishAt date required' });
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'scheduled', scheduledPublishAt: new Date(publishAt) }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: `Exam scheduled to publish at ${new Date(publishAt).toLocaleString()}`, exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.6 — Notify Students
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/notify-students', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    // Check if notification service exists
    try {
      const Notification = mongoose.model('Notification');
      const User = getUser();
      const filter = exam.batch ? { role: 'student', batch: exam.batch } : { role: 'student' };
      const students = await User.find(filter).select('_id');
      const notifs = students.map(s => ({ user: s._id, title: `New Exam: ${exam.title}`, message: `A new exam "${exam.title}" has been scheduled. Duration: ${exam.duration} min.`, type: 'exam', examId: exam._id }));
      if (notifs.length) await Notification.insertMany(notifs, { ordered: false });
      res.json({ success: true, message: `${students.length} students notified`, count: students.length });
    } catch {
      res.json({ success: true, message: 'Notification service not available. Students will see exam on next login.' });
    }
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.11 — Clone Exam
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/clone', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const orig = await Exam.findById(req.params.id).lean();
    if (!orig) return res.status(404).json({ success: false, message: 'Exam not found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    const clone = await Exam.create({ ...orig, title: `${orig.title} (Copy)`, status: 'draft', publishedAt: null, scheduledPublishAt: null, createdBy: req.user.id });
    res.json({ success: true, message: 'Exam cloned!', exam: clone, examId: clone._id });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// Reorder questions in exam
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/questions/reorder', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { orderedIds } = req.body;
    if (!orderedIds || !Array.isArray(orderedIds)) return res.status(400).json({ success: false, message: 'orderedIds required' });
    await Exam.findByIdAndUpdate(req.params.id, { questions: orderedIds });
    res.json({ success: true, message: 'Questions reordered' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// Remove one question from exam
router.delete('/exam-wizard/:id/questions/:qid', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    await Exam.findByIdAndUpdate(req.params.id, { $pull: { questions: req.params.qid } });
    res.json({ success: true, message: 'Question removed from exam' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
__PRRANK_EOF_WIZARDROUTES__

# ── 4) index.js — FULL REWRITE (new route mount added) ──────────────────────
echo "→ Rewriting $INDEX_FILE ..."
cat > "$INDEX_FILE" << '__PRRANK_EOF_INDEX__'
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
__PRRANK_EOF_INDEX__

echo ""
echo "── Syntax check (node --check) ──"
SYN_OK=1
node --check "$BASE_DIR/routes/examListing.js" 2>&1 && echo "✅ routes/examListing.js syntax OK" || SYN_OK=0
node --check "$EXAM_MODEL" 2>&1 && echo "✅ models/Exam.js syntax OK" || SYN_OK=0
node --check "$WIZARD_ROUTES" 2>&1 && echo "✅ routes/examWizardRoutes.js syntax OK" || SYN_OK=0
node --check "$INDEX_FILE" 2>&1 && echo "✅ index.js syntax OK" || SYN_OK=0

if [ "$SYN_OK" -eq 0 ]; then
  echo "❌ Syntax error mila — upar dekhein. Backups yahan hain: *.bak_feat33"
  exit 1
fi

echo ""
echo "── Feature 33 verification (Backend) ──"
pass=0; total=0
chk(){ total=$((total+1)); if grep -q "$1" "$2" 2>/dev/null; then echo "✅ $3"; pass=$((pass+1)); else echo "❌ $3"; fi }

chk "isPinned"                          "$EXAM_MODEL"             "33.20 isPinned field added to Exam model"
chk "router.get('/list'"                "$BASE_DIR/routes/examListing.js" "33.1  main list endpoint (filters+sort+pagination)"
chk "router.get('/filter-options'"      "$BASE_DIR/routes/examListing.js" "33.4-33.5 dynamic filter options endpoint"
chk "router.get('/admins'"              "$BASE_DIR/routes/examListing.js" "33.12 superadmin admin-picker endpoint"
chk "router.get('/:id/analytics'"       "$BASE_DIR/routes/examListing.js" "33.14 analytics endpoint"
chk "router.patch('/:id/publish'"       "$BASE_DIR/routes/examListing.js" "33.11 quick status toggle endpoint"
chk "router.patch('/:id/pin'"           "$BASE_DIR/routes/examListing.js" "33.20 pin toggle endpoint"
chk "router.put('/:id/quick-edit'"      "$BASE_DIR/routes/examListing.js" "33.9  quick-edit endpoint"
chk "router.post('/bulk-delete'"        "$BASE_DIR/routes/examListing.js" "33.27 bulk delete endpoint"
chk "router.post('/bulk-publish'"       "$BASE_DIR/routes/examListing.js" "33.27 bulk publish endpoint"
chk "router.get('/export'"              "$BASE_DIR/routes/examListing.js" "33.17 export endpoint"
chk "require('./routes/examListing')"   "$INDEX_FILE"             "33    route mounted at /api/exams-manage"
chk "schedule: {"                       "$WIZARD_ROUTES"          "BUGFIX schedule.startTime/endTime now correctly saved"
chk "seriesName: testSeriesId"          "$WIZARD_ROUTES"          "BUGFIX seriesName now populated for series filtering"

echo ""
echo "Backend checks passed: $pass / $total"
if [ "$pass" -eq "$total" ]; then
  echo "✅ BACKEND — Feature 33 backend pieces fully implemented."
else
  echo "⚠️  Kuch backend checks fail hue — upar dekhein, kuch reh gaya ho sakta hai."
fi

echo ""
echo "Important notes:"
echo "  • Naya prefix /api/exams-manage istemal kiya hai (na ki /api/exams) — taaki"
echo "    6 alag-alag existing exam-related route files se koi clash na ho."
echo "  • Delete + Clone actions purane, already-working /api/exams/:id (DELETE) aur"
echo "    /api/exams/:examId/clone (POST) endpoints reuse karte hain — unhe touch nahi kiya."
echo "  • Discovered (not fixed, out of this feature's scope): kai aur fields bhi"
echo "    Create-Exam-Wizard se silently drop ho rahe hain (totalQs, subjectQs,"
echo "    correctMarks/negativeMarks ko markingScheme me map nahi kiya gaya, waiting"
echo "    room/reattempt/sectionWise/multiBatch/assignType). Agar chaho to isey"
echo "    alag feature/fix ke roop me karwa sakte ho."
echo "  • Wizard ke apne CATEGORIES dropdown me 'PYQ' aur 'Custom' options hain jo"
echo "    Exam model ke category enum me valid NAHI hain — unhe select karne par"
echo "    bhi exam creation fail ho sakta hai (Feature 29 ke 'NEET' bug jaisa hi)."
echo ""
echo "Ab: server restart karo (npm start / Replit Run) taaki naye routes + fixes load ho jayein."
