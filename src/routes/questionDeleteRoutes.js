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
