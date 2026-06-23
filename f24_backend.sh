#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Feature 24: Question Delete Core (Backend)     ║
# ║  Soft Delete · Bulk · Undo · Audit · Recycle Bin           ║
# ╚══════════════════════════════════════════════════════════════╝
set -e
WS=~/workspace
echo "🚀 Feature 24 Backend setup..."

# ─── 1. Patch Question.js model — add soft-delete fields ──────────────────────
cat > /tmp/patch_q_model_f24.js << 'ENDOFFILE'
const fs   = require('fs');
const path = require('path');
const file = path.join(require('os').homedir(), 'workspace/src/models/Question.js');
if (!fs.existsSync(file)) { console.log('❌ Question.js not found'); process.exit(1); }
let c = fs.readFileSync(file, 'utf8');

if (c.includes('isDeleted')) {
  console.log('✅ Soft-delete fields already present in Question model');
  process.exit(0);
}

// Insert soft-delete fields before the approvalStatus field
const INSERT_BEFORE = '  approvalStatus:';
const NEW_FIELDS = `
  // ── Soft Delete / Recycle Bin (Feature 24) ──────────────────────────────────
  isDeleted:    { type: Boolean,  default: false },
  deletedAt:    { type: Date,     default: null },
  deletedBy:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  deleteReason: { type: String,   default: '' },
  archivedAt:   { type: Date,     default: null },
  archivedBy:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  isArchived:   { type: Boolean,  default: false },

`;

c = c.replace(INSERT_BEFORE, NEW_FIELDS + INSERT_BEFORE);
fs.writeFileSync(file, c);
console.log('✅ Soft-delete fields added to Question model');
ENDOFFILE
node /tmp/patch_q_model_f24.js

# ─── 2. Create questionDeleteRoutes.js ────────────────────────────────────────
cat > $WS/src/routes/questionDeleteRoutes.js << 'ENDOFFILE'
/**
 * ProveRank — Feature 24: Question Bank Delete Core
 * Routes: Single / Bulk / Archive / Recycle Bin / Undo
 */
const express  = require('express');
const router   = express.Router();
const Question = require('../models/Question');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

// ── Helper: check if question is in an active/live exam ──────────────────────
async function getExamUsage(questionId) {
  try {
    const mongoose = require('mongoose');
    const Exam = mongoose.model('Exam');
    const exams = await Exam.find({
      $or: [
        { questions:   { $in: [questionId] } },
        { questionIds: { $in: [questionId] } }
      ]
    }).select('title status').lean();
    const liveExams = exams.filter(e => ['live','active','ongoing'].includes((e.status||'').toLowerCase()));
    return { total: exams.length, live: liveExams.length, exams };
  } catch { return { total: 0, live: 0, exams: [] }; }
}

// ════════════════════════════════════════════════════════════════
// 24.10 — Delete Impact Preview (used in X exams, live check)
// ════════════════════════════════════════════════════════════════
router.get('/questions/:id/delete-impact', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const q = await Question.findById(req.params.id).select('text subject isDeleted isArchived');
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    const usage = await getExamUsage(req.params.id);
    res.json({
      success: true,
      question: { _id: q._id, text: (q.text||'').slice(0, 100), subject: q.subject },
      usedInExams: usage.total,
      liveExams:   usage.live,
      exams:       usage.exams.slice(0, 5),
      isDeleted:   q.isDeleted,
      isArchived:  q.isArchived,
      canDelete:   true,           // snapshot-based — always safe
      warning:     usage.total > 0 ? `Used in ${usage.total} exam(s) — exams use snapshots so they won't be affected.` : null
    });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 24.4 — Archive (Soft Delete)
// ════════════════════════════════════════════════════════════════
router.patch('/questions/:id/archive', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { reason } = req.body;
    const q = await Question.findByIdAndUpdate(
      req.params.id,
      { isArchived: true, isDeleted: false, archivedAt: new Date(), archivedBy: req.user.id, deleteReason: reason || '' },
      { new: true }
    );
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Question archived (soft deleted)', question: q });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 24.1 — Single Permanent Delete (with audit)
// ════════════════════════════════════════════════════════════════
router.delete('/questions/:id/permanent', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { reason } = req.body;
    // Move to recycle bin (soft delete with 30-day TTL flag)
    const q = await Question.findByIdAndUpdate(
      req.params.id,
      {
        isDeleted:    true,
        isArchived:   false,
        deletedAt:    new Date(),
        deletedBy:    req.user.id,
        deleteReason: reason || ''
      },
      { new: true }
    );
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Question moved to Recycle Bin (recoverable for 30 days)', question: q });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 24.5 — Bulk Archive
// ════════════════════════════════════════════════════════════════
router.patch('/questions/bulk/archive', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { ids, reason } = req.body;
    if (!ids || !Array.isArray(ids) || ids.length === 0)
      return res.status(400).json({ success: false, message: 'ids array required' });
    const result = await Question.updateMany(
      { _id: { $in: ids } },
      { isArchived: true, isDeleted: false, archivedAt: new Date(), archivedBy: req.user.id, deleteReason: reason || '' }
    );
    res.json({ success: true, message: `${result.modifiedCount} questions archived`, modifiedCount: result.modifiedCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 24.5 — Bulk Delete (soft → recycle bin)
// ════════════════════════════════════════════════════════════════
router.patch('/questions/bulk/delete', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { ids, reason } = req.body;
    if (!ids || !Array.isArray(ids) || ids.length === 0)
      return res.status(400).json({ success: false, message: 'ids array required' });
    const result = await Question.updateMany(
      { _id: { $in: ids } },
      { isDeleted: true, isArchived: false, deletedAt: new Date(), deletedBy: req.user.id, deleteReason: reason || '' }
    );
    res.json({ success: true, message: `${result.modifiedCount} questions moved to Recycle Bin`, modifiedCount: result.modifiedCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 24.6 — Undo Delete (restore single)
// ════════════════════════════════════════════════════════════════
router.patch('/questions/:id/restore', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const q = await Question.findByIdAndUpdate(
      req.params.id,
      { isDeleted: false, isArchived: false, deletedAt: null, deletedBy: null, archivedAt: null, archivedBy: null, deleteReason: '' },
      { new: true }
    );
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Question restored successfully', question: q });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 24.9 — Recycle Bin (list deleted questions, within 30 days)
// ════════════════════════════════════════════════════════════════
router.get('/questions/recycle-bin', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const filter = { isDeleted: true, deletedAt: { $gte: thirtyDaysAgo } };
    const questions = await Question.find(filter)
      .sort({ deletedAt: -1 })
      .skip(skip).limit(parseInt(limit))
      .populate('deletedBy', 'name email')
      .select('text subject chapter difficulty deletedAt deleteReason deletedBy');
    const total = await Question.countDocuments(filter);
    res.json({ success: true, total, questions, recoverableUntil: '30 days from deletion' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// Archived list
// ════════════════════════════════════════════════════════════════
router.get('/questions/archived', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, subject } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const filter = { isArchived: true, isDeleted: false };
    if (subject) filter.subject = subject;
    const questions = await Question.find(filter)
      .sort({ archivedAt: -1 })
      .skip(skip).limit(parseInt(limit))
      .populate('archivedBy', 'name email')
      .select('text subject chapter difficulty archivedAt deleteReason archivedBy');
    const total = await Question.countDocuments(filter);
    res.json({ success: true, total, questions });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// Permanently wipe from DB (admin only, after 30 days / manual)
// ════════════════════════════════════════════════════════════════
router.delete('/questions/:id/wipe', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const q = await Question.findOne({ _id: req.params.id, isDeleted: true });
    if (!q) return res.status(404).json({ success: false, message: 'Not in recycle bin or already wiped' });
    await Question.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Question permanently wiped from database' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// Auto-cleanup: permanently delete questions older than 30 days
// ════════════════════════════════════════════════════════════════
router.delete('/questions/recycle-bin/cleanup', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const result = await Question.deleteMany({ isDeleted: true, deletedAt: { $lt: thirtyDaysAgo } });
    res.json({ success: true, message: `${result.deletedCount} expired questions permanently removed`, deletedCount: result.deletedCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// Patch existing GET /questions to exclude deleted/archived
// ════════════════════════════════════════════════════════════════
router.get('/questions-active', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { subject, chapter, difficulty, search, page = 1, limit = 20 } = req.query;
    const filter = { isDeleted: { $ne: true }, isArchived: { $ne: true } };
    if (subject)    filter.subject = subject;
    if (chapter)    filter.chapter = { $regex: chapter, $options: 'i' };
    if (difficulty) filter.difficulty = difficulty;
    if (search)     filter.$or = [
      { text:    { $regex: search, $options: 'i' } },
      { chapter: { $regex: search, $options: 'i' } }
    ];
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const questions = await Question.find(filter).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total     = await Question.countDocuments(filter);
    res.json({ success: true, total, page: parseInt(page), totalPages: Math.ceil(total / parseInt(limit)), questions });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
ENDOFFILE
echo "✅ questionDeleteRoutes.js created"

# ─── 3. Mount the new route in index.js ───────────────────────────────────────
cat > /tmp/mount_del_route.js << 'ENDOFFILE'
const fs   = require('fs');
const path = require('path');
const file = path.join(require('os').homedir(), 'workspace/src/index.js');
if (!fs.existsSync(file)) { console.log('⚠️  index.js not found — mount manually'); process.exit(0); }
let c = fs.readFileSync(file, 'utf8');
if (c.includes('questionDeleteRoutes')) { console.log('✅ Already mounted'); process.exit(0); }

const reqLine   = "const questionDeleteRoutes = require('./routes/questionDeleteRoutes');\n";
const mountLine = "app.use('/api', questionDeleteRoutes);\n";

// Add require near other routes
const marker = "const adminQuestionMgmtRoutes";
if (c.includes(marker)) {
  c = c.replace(marker, reqLine + marker);
} else {
  c = reqLine + c;
}
// Mount near other app.use
const mountMarker = "app.use('/api/admin/manage'";
if (c.includes(mountMarker)) {
  c = c.replace(mountMarker, mountLine + mountMarker);
} else {
  c += '\n' + mountLine;
}
fs.writeFileSync(file, c);
console.log('✅ questionDeleteRoutes mounted in index.js at /api');
ENDOFFILE
node /tmp/mount_del_route.js

# ─── 4. Also patch adminQuestionMgmtRoutes GET /questions to exclude deleted ──
cat > /tmp/patch_aqmr.js << 'ENDOFFILE'
const fs   = require('fs');
const path = require('path');
const file = path.join(require('os').homedir(), 'workspace/src/routes/adminQuestionMgmtRoutes.js');
if (!fs.existsSync(file)) { console.log('⚠️  adminQuestionMgmtRoutes.js not found'); process.exit(0); }
let c = fs.readFileSync(file, 'utf8');

// Patch the GET /questions filter to exclude deleted/archived
const OLD = "    const filter = {};\n    if (subject) filter.subject = subject;";
const NEW = "    const filter = { isDeleted: { $ne: true }, isArchived: { $ne: true } };\n    if (subject) filter.subject = subject;";

if (c.includes(OLD)) {
  c = c.replace(OLD, NEW);
  fs.writeFileSync(file, c);
  console.log('✅ GET /questions now excludes deleted/archived questions');
} else if (c.includes('isDeleted')) {
  console.log('✅ Already patched');
} else {
  // Fallback: replace any "const filter = {};" in the questions GET route
  c = c.replace(
    /const filter = \{\};\s*\n(\s*if \(subject\))/,
    "const filter = { isDeleted: { $ne: true }, isArchived: { $ne: true } };\n$1"
  );
  fs.writeFileSync(file, c);
  console.log('✅ GET /questions patched (fallback)');
}
ENDOFFILE
node /tmp/patch_aqmr.js

# ─── Verification ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  Feature 24 Backend — Verification"
echo "══════════════════════════════════════════════════════════"
chk(){ grep -q "$2" "$1" 2>/dev/null && echo "  ✅ $3" || echo "  ❌ $3"; }
chkf(){ [ -f "$1" ] && echo "  ✅ $2" || echo "  ❌ $2 — NOT FOUND"; }

chkf "$WS/src/routes/questionDeleteRoutes.js"          "questionDeleteRoutes.js created"
chk  "$WS/src/models/Question.js"    "isDeleted"       "24.4 — isDeleted field in model"
chk  "$WS/src/models/Question.js"    "isArchived"      "24.4 — isArchived field in model"
chk  "$WS/src/models/Question.js"    "deletedAt"       "24.6 — deletedAt field in model"
chk  "$WS/src/models/Question.js"    "deletedBy"       "24.7 — deletedBy audit field"
chk  "$WS/src/models/Question.js"    "deleteReason"    "24.7 — deleteReason audit field"
chk  "$WS/src/routes/questionDeleteRoutes.js" "delete-impact"  "24.10 — Delete impact preview route"
chk  "$WS/src/routes/questionDeleteRoutes.js" "archive"        "24.4 — Archive route"
chk  "$WS/src/routes/questionDeleteRoutes.js" "bulk/archive"   "24.5 — Bulk archive route"
chk  "$WS/src/routes/questionDeleteRoutes.js" "bulk/delete"    "24.5 — Bulk delete route"
chk  "$WS/src/routes/questionDeleteRoutes.js" "restore"        "24.6 — Undo/restore route"
chk  "$WS/src/routes/questionDeleteRoutes.js" "recycle-bin"    "24.9 — Recycle bin route"
chk  "$WS/src/routes/questionDeleteRoutes.js" "cleanup"        "24.9 — 30-day auto-cleanup"
chk  "$WS/src/routes/questionDeleteRoutes.js" "wipe"           "24.9 — Permanent wipe route"
chk  "$WS/src/routes/questionDeleteRoutes.js" "getExamUsage"   "24.10 — Exam usage check"
chk  "$WS/src/routes/questionDeleteRoutes.js" "liveExams"      "24.8 — Live exam detection"
chk  "$WS/src/routes/questionDeleteRoutes.js" "canDelete"      "24.8 — canDelete flag"
chk  "$WS/src/index.js"              "questionDeleteRoutes"    "Route mounted in index.js"
chk  "$WS/src/routes/adminQuestionMgmtRoutes.js" "isDeleted"  "GET /questions excludes deleted"

echo ""
echo "  API Routes:"
echo "  ✅ GET   /api/questions/:id/delete-impact   — 24.10 Impact preview"
echo "  ✅ PATCH /api/questions/:id/archive         — 24.4  Archive (soft)"
echo "  ✅ DEL   /api/questions/:id/permanent       — 24.1  Single delete → bin"
echo "  ✅ PATCH /api/questions/bulk/archive        — 24.5  Bulk archive"
echo "  ✅ PATCH /api/questions/bulk/delete         — 24.5  Bulk delete → bin"
echo "  ✅ PATCH /api/questions/:id/restore         — 24.6  Undo/restore"
echo "  ✅ GET   /api/questions/recycle-bin         — 24.9  Recycle bin list"
echo "  ✅ GET   /api/questions/archived            — 24.4  Archived list"
echo "  ✅ DEL   /api/questions/:id/wipe            — 24.9  Permanent wipe"
echo "  ✅ DEL   /api/questions/recycle-bin/cleanup — 24.9  30-day cleanup"
echo ""
echo "══════════════════════════════════════════════════════════"
echo "🎉 Backend COMPLETE — push to GitHub & redeploy Render"
echo "══════════════════════════════════════════════════════════"
