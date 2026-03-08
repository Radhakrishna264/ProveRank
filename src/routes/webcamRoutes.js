const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const WebcamLog = require('../models/WebcamLog');
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

// STEP 1 — Camera Permission Log
// POST /api/webcam/permission
router.post('/permission', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, permissionStatus, metadata } = req.body;
    if (!attemptId || !examId || !permissionStatus)
      return res.status(400).json({ message: 'attemptId, examId, permissionStatus required' });
    if (!['granted', 'denied'].includes(permissionStatus))
      return res.status(400).json({ message: 'permissionStatus must be granted or denied' });

    const log = await WebcamLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: permissionStatus === 'granted' ? 'permission_granted' : 'permission_denied',
      cheatingFlag: permissionStatus === 'denied',
      flagReason: permissionStatus === 'denied' ? 'Camera permission denied by student' : null,
      metadata: metadata || {},
      timestamp: new Date()
    });

    return res.status(200).json({
      message: 'Camera permission logged',
      permissionStatus,
      cheatingFlag: log.cheatingFlag,
      logId: log._id
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 2 — Block Exam if Camera Denied
// POST /api/webcam/block-exam
router.post('/block-exam', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId } = req.body;
    if (!attemptId || !examId)
      return res.status(400).json({ message: 'attemptId aur examId required' });

    const deniedLog = await WebcamLog.findOne({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      eventType: 'permission_denied'
    });

    if (deniedLog) {
      await WebcamLog.create({
        attemptId: new mongoose.Types.ObjectId(attemptId),
        examId: new mongoose.Types.ObjectId(examId),
        studentId: new mongoose.Types.ObjectId(req.user.id),
        eventType: 'exam_blocked',
        cheatingFlag: true,
        flagReason: 'Exam blocked — camera permission not granted',
        metadata: { blockedAt: new Date() }
      });
      return res.status(403).json({
        message: 'Exam blocked — camera compulsory hai. Permission do aur dobara try karo.',
        examBlocked: true,
        reason: 'camera_permission_denied'
      });
    }

    return res.status(200).json({
      message: 'Camera OK — exam proceed kar sakte ho',
      examBlocked: false
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 3 & 4 — Snapshot Upload + MongoDB Storage
// POST /api/webcam/snapshot
router.post('/snapshot', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, snapshotBase64, metadata } = req.body;
    if (!attemptId || !examId)
      return res.status(400).json({ message: 'attemptId aur examId required' });

    const snapshotData = snapshotBase64 || null;
    const snapshotSize = snapshotBase64 ? Buffer.byteLength(snapshotBase64, 'base64') : 0;

    if (snapshotSize > 500000) {
      return res.status(400).json({ message: 'Snapshot too large — max 500KB allowed' });
    }

    const log = await WebcamLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'snapshot',
      snapshotData,
      snapshotSize,
      cheatingFlag: false,
      metadata: {
        capturedAt: new Date(),
        intervalSeconds: 30,
        ...(metadata || {})
      },
      timestamp: new Date()
    });

    return res.status(200).json({
      message: 'Snapshot saved successfully',
      snapshotId: log._id,
      sizeBytes: snapshotSize,
      timestamp: log.timestamp
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 5 — Cheating Flag with Snapshot
// POST /api/webcam/flag-snapshot
router.post('/flag-snapshot', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, flagReason, snapshotBase64, metadata } = req.body;
    if (!attemptId || !examId || !flagReason)
      return res.status(400).json({ message: 'attemptId, examId, flagReason required' });

    const log = await WebcamLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'face_flag',
      snapshotData: snapshotBase64 || null,
      snapshotSize: snapshotBase64 ? Buffer.byteLength(snapshotBase64, 'base64') : 0,
      cheatingFlag: true,
      flagReason,
      metadata: {
        flaggedAt: new Date(),
        ...(metadata || {})
      },
      timestamp: new Date()
    });

    return res.status(200).json({
      message: 'Cheating flag saved with snapshot',
      flagId: log._id,
      flagReason,
      cheatingFlag: true,
      timestamp: log.timestamp
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 6 — Virtual Background Detection (S74)
// POST /api/webcam/virtual-bg-flag
router.post('/virtual-bg-flag', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, confidence, metadata } = req.body;
    if (!attemptId || !examId)
      return res.status(400).json({ message: 'attemptId aur examId required' });

    const log = await WebcamLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'virtual_bg_detected',
      cheatingFlag: true,
      flagReason: 'Virtual/fake background detected (S74)',
      metadata: {
        confidence: confidence || 'high',
        detectedAt: new Date(),
        ...(metadata || {})
      },
      timestamp: new Date()
    });

    return res.status(200).json({
      message: 'Virtual background flagged (S74)',
      flagId: log._id,
      cheatingFlag: true,
      action: 'ADMIN_ALERT_SENT',
      confidence: confidence || 'high'
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// ADMIN — Get all snapshots for attempt
router.get('/admin/snapshots/:attemptId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const logs = await WebcamLog.find({
      attemptId: new mongoose.Types.ObjectId(req.params.attemptId)
    }).select('-snapshotData').sort({ timestamp: 1 });

    const flagged = logs.filter(l => l.cheatingFlag);

    return res.status(200).json({
      message: 'Webcam logs fetched',
      attemptId: req.params.attemptId,
      totalLogs: logs.length,
      totalFlagged: flagged.length,
      logs
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// ADMIN — All flagged students
router.get('/admin/flagged', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const flagged = await WebcamLog.find({ cheatingFlag: true })
      .select('-snapshotData')
      .sort({ timestamp: -1 })
      .limit(100);

    return res.status(200).json({
      message: 'Flagged webcam events fetched',
      totalFlagged: flagged.length,
      flagged
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

module.exports = router;
