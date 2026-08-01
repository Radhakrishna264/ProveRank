const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Exam = require('../models/Exam');
const Attempt = require('../models/Attempt');
const User = require('../models/User');
const { verifyToken, isAdmin } = require('../middleware/auth');

// S97 - Step 1: Rank Prediction
router.get('/:examId/rank-prediction', verifyToken, async (req, res) => {
  try {
    const past = await Attempt.find({
      studentId: req.user.id, status: 'completed'
    }).sort({ createdAt: -1 }).limit(5);
    let predictedRank = 'N/A';
    if (past.length > 0) {
      const avg = past.reduce((s, a) => s + (a.totalScore || 0), 0) / past.length;
      const total = await User.countDocuments({ role: 'student' });
      predictedRank = Math.max(1, Math.round(total * (1 - avg / 720)));
    }
    res.json({ success: true, predictedRank });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// [REMOVED — DEAD CODE] Legacy /:examId/waiting-room (hardcoded 10-min window,
// wrong field names for current Exam schema, missing `return` after 403 causing
// a double-response crash). No frontend page calls this anymore — the real,
// active implementation is GET /:id/waiting-info in routes/examFlow.js (F53).

// [REMOVED — DEAD CODE] Legacy /:examId/instructions (referenced exam.totalQuestions,
// exam.negativeMarking, exam.instructions — none of which exist on the current
// Exam schema; would have returned undefined values). No frontend page calls
// this — the real Instructions screen (F54) builds its data from GET /:id
// + GET /my-exams directly in app/exam/[examId]/instructions/page.tsx.

// [REMOVED — DEAD CODE] Legacy /:examId/accept-terms (set a global termsAccepted
// flag with no version tracking or per-exam consent log). This path is also
// shadowed by the modern, version-tracked F55 implementation already mounted
// earlier in index.js at routes/examFlow.js, so it was unreachable anyway.

// S31 - Step 5: Attempt Limit Check
router.get('/:examId/attempt-limit', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(new mongoose.Types.ObjectId(req.params.examId)).select('maxAttempts');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const count = await Attempt.countDocuments({ examId: req.params.examId, studentId: req.user.id, status: 'completed' });
    const max = exam.maxAttempts || 1;
    res.json({ success: true, allowed: count < max, attemptCount: count, maxAttempts: max });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// S85 - Step 9: Exam Access Whitelist
router.get('/:examId/whitelist-check', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(new mongoose.Types.ObjectId(req.params.examId)).select('whitelistEnabled accessWhitelist');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    if (!exam.whitelistEnabled) return res.json({ success: true, allowed: true, message: 'Whitelist off - sabko access' });
    const allowed = (exam.accessWhitelist || []).some(id => id.toString() === req.user.id.toString());
    res.json({ success: true, allowed, message: allowed ? 'Access allowed' : 'Access denied' });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// S106 - Step 10: Admit Card QR Verify
router.post('/:examId/verify-admit-card', verifyToken, async (req, res) => {
  try {
    const { qrToken } = req.body;
    if (!qrToken) return res.json({ success: true, message: 'Admit card verified (no QR required)', verified: true });
    let decoded;
    try { decoded = Buffer.from(qrToken, 'base64').toString('utf8'); }
    catch (e) { return res.status(400).json({ success: false, message: 'Invalid QR format' }); }
    const parts = decoded.split('_');
    if (parts[0] !== req.params.examId || parts[1] !== req.user.id.toString())
      return res.status(403).json({ success: false, message: 'Invalid admit card. Blocked.' });
    res.json({ success: true, message: 'Admit card verified!' });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// [REMOVED — DEAD CODE] Legacy /:examId/fullscreen-setting. F57's fullscreenForce
// check is now read directly from GET /api/exams/:id (routes/exam.js) inside
// app/exam/[examId]/attempt/page.tsx, so this separate endpoint is unused.

module.exports = router;
