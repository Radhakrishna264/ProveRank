const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const AudioLog = require('../models/AudioLog');
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

function authMiddleware(req, res, next) {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ message: 'Token required' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT_SECRET); next(); }
  catch { return res.status(401).json({ message: 'Invalid token' }); }
}

function adminMiddleware(req, res, next) {
  if (req.user.role !== 'superadmin' && req.user.role !== 'admin')
    return res.status(403).json({ message: 'Admin access required' });
  next();
}

// STEP 1 — Mic Permission Log
// POST /api/audio/permission
router.post('/permission', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, permissionStatus, metadata } = req.body;
    if (!attemptId || !examId || !permissionStatus)
      return res.status(400).json({ message: 'attemptId, examId, permissionStatus required' });
    if (!['granted', 'denied'].includes(permissionStatus))
      return res.status(400).json({ message: 'permissionStatus must be granted or denied' });

    const log = await AudioLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: permissionStatus === 'granted' ? 'permission_granted' : 'permission_denied',
      audioFlag: false,
      metadata: {
        permissionStatus,
        optional: true,
        studentChoice: permissionStatus,
        ...(metadata || {})
      },
      timestamp: new Date()
    });

    return res.status(200).json({
      message: 'Mic permission logged (optional — student choice)',
      permissionStatus,
      logId: log._id,
      note: 'Audio monitoring is optional for students'
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 2 — Noise / Whisper Detection Flag
// POST /api/audio/noise-flag
router.post('/noise-flag', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, noiseType, noiseLevel, metadata } = req.body;
    if (!attemptId || !examId || !noiseType)
      return res.status(400).json({ message: 'attemptId, examId, noiseType required' });

    const validTypes = ['noise_detected', 'whisper_detected'];
    if (!validTypes.includes(noiseType))
      return res.status(400).json({ message: 'noiseType must be noise_detected or whisper_detected' });

    const NOISE_THRESHOLD = 70;
    const level = noiseLevel || 0;
    const isSuspicious = level > NOISE_THRESHOLD || noiseType === 'whisper_detected';

    const log = await AudioLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: noiseType,
      audioFlag: isSuspicious,
      flagReason: isSuspicious
        ? (noiseType === 'whisper_detected' ? 'Whispering detected during exam' : 'Unusual noise level detected')
        : null,
      noiseLevel: level,
      metadata: {
        threshold: NOISE_THRESHOLD,
        detectedAt: new Date(),
        ...(metadata || {})
      },
      timestamp: new Date()
    });

    return res.status(200).json({
      message: 'Noise event logged',
      noiseType,
      noiseLevel: level,
      audioFlag: isSuspicious,
      flagReason: log.flagReason,
      logId: log._id
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 3 — Save Audio Flag
// POST /api/audio/flag
router.post('/flag', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, flagReason, noiseLevel, metadata } = req.body;
    if (!attemptId || !examId || !flagReason)
      return res.status(400).json({ message: 'attemptId, examId, flagReason required' });

    const log = await AudioLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'audio_flag',
      audioFlag: true,
      flagReason,
      noiseLevel: noiseLevel || 0,
      metadata: {
        flaggedAt: new Date(),
        ...(metadata || {})
      },
      timestamp: new Date()
    });

    return res.status(200).json({
      message: 'Audio flag saved to backend',
      flagId: log._id,
      audioFlag: true,
      flagReason,
      timestamp: log.timestamp
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 4 — Admin Per-Exam Audio Toggle (S57)
// POST /api/audio/admin/toggle/:examId
router.post('/admin/toggle/:examId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { examId } = req.params;
    const { enabled } = req.body;
    if (enabled === undefined)
      return res.status(400).json({ message: 'enabled (true/false) required' });

    const Exam = mongoose.model('Exam');
    const exam = await Exam.findByIdAndUpdate(
      examId,
      { $set: { audioMonitoringEnabled: enabled } },
      { new: true, runValidators: false }
    );
    if (!exam) return res.status(404).json({ message: 'Exam not found' });

    return res.status(200).json({
      message: 'Audio monitoring toggled (S57)',
      examId,
      audioMonitoringEnabled: enabled,
      note: enabled ? 'Audio monitoring ON for this exam' : 'Audio monitoring OFF for this exam'
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// GET — Audio monitoring status for exam
router.get('/admin/status/:examId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const Exam = mongoose.model('Exam');
    const exam = await Exam.findById(req.params.examId).select('title audioMonitoringEnabled');
    if (!exam) return res.status(404).json({ message: 'Exam not found' });

    return res.status(200).json({
      examId: req.params.examId,
      examTitle: exam.title,
      audioMonitoringEnabled: exam.audioMonitoringEnabled || false
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// ADMIN — All audio flags for attempt
router.get('/admin/logs/:attemptId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const logs = await AudioLog.find({
      attemptId: new mongoose.Types.ObjectId(req.params.attemptId)
    }).sort({ timestamp: 1 });

    const flagged = logs.filter(l => l.audioFlag);

    return res.status(200).json({
      message: 'Audio logs fetched',
      attemptId: req.params.attemptId,
      totalLogs: logs.length,
      totalFlagged: flagged.length,
      logs
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

module.exports = router;
