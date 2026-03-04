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

// M6 - Step 2: Waiting Room
router.get('/:examId/waiting-room', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId).select('title startTime duration status');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const now = new Date();
    const start = new Date(exam.startTime);
    const opens = new Date(start.getTime() - 10 * 60 * 1000);
    if (now < opens) return res.status(403).json({ success: false, message: 'Waiting room 10 min pehle khulta hai', opensAt: opens });
    const countdown = Math.max(0, Math.floor((start - now) / 1000));
    res.json({ success: true, exam, countdown, serverTime: now });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// Step 3: Instructions Page
router.get('/:examId/instructions', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId).select('title duration totalQuestions totalMarks negativeMarking instructions');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, instructions: {
      title: exam.title, duration: exam.duration,
      totalQuestions: exam.totalQuestions,
      totalMarks: exam.totalMarks,
      negativeMarking: exam.negativeMarking,
      custom: exam.instructions || 'Sabhi questions dhyan se padho.',
      rules: ['Exam pause nahi hoga', 'Fullscreen compulsory hai', '3 warnings = auto submit']
    }});
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// S91 - Step 4: T&C Accept/Reject
router.post('/:examId/accept-terms', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    if (!req.body.accepted) return res.status(403).json({ success: false, message: 'Terms reject. Entry blocked.' });
    await User.findByIdAndUpdate(req.user.id, { termsAccepted: true });
    res.json({ success: true, message: 'Terms accepted. Aage badho.' });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// S31 - Step 5: Attempt Limit Check
router.get('/:examId/attempt-limit', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId).select('maxAttempts');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const count = await Attempt.countDocuments({ examId: req.params.examId, studentId: req.user.id, status: 'completed' });
    const max = exam.maxAttempts || 1;
    res.json({ success: true, allowed: count < max, attemptCount: count, maxAttempts: max });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// Steps 6+7+8: Start Attempt + IP + Timestamp
router.post('/:examId/start-attempt', verifyToken, async (req, res) => {
  try {
    const examObjId = new mongoose.Types.ObjectId(req.params.examId);
    const studentObjId = new mongoose.Types.ObjectId(req.user.id);
    const exam = await Exam.findById(examObjId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const usedAttempts = await Attempt.countDocuments({ examId: examObjId, studentId: studentObjId, status: 'completed' });
    if (usedAttempts >= (exam.maxAttempts || 1)) return res.status(403).json({ success: false, message: 'Attempt limit reached' });
    const ipAddress = req.headers['x-forwarded-for'] || req.ip || 'unknown';
    const newAttempt = new Attempt({
      examId: examObjId,
      studentId: studentObjId,
      startedAt: new Date(),
      status: 'active',
      ipAddress: ipAddress
    });
    await newAttempt.save();
    res.json({ success: true, message: 'Attempt started', attemptId: newAttempt._id, startedAt: newAttempt.startedAt, ipAddress: newAttempt.ipAddress });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// Steps 7+8: GET Attempt by ID — startTime + ipAddress verify
router.get('/attempt/:attemptId', verifyToken, async (req, res) => {
  try {
    const attempt = await Attempt.findById(req.params.attemptId);
    if (!attempt) return res.status(404).json({ success: false, message: 'Attempt not found' });
    res.json({
      success: true,
      attempt,
      startTime: attempt.startedAt,
      ipAddress: attempt.ipAddress
    });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// S85 - Step 9: Exam Access Whitelist
router.get('/:examId/whitelist-check', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId).select('whitelistEnabled accessWhitelist');
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

// S32 - Step 11: Fullscreen Force
router.get('/:examId/fullscreen-setting', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId).select('fullscreenForce fullscreenWarnings');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, fullscreenForce: exam.fullscreenForce || false, maxWarnings: exam.fullscreenWarnings || 3 });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
