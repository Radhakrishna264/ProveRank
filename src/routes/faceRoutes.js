const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const FaceLog = require('../models/FaceLog');
const AntiCheatLog = require('../models/AntiCheatLog');
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

// Helper — Face Warning Counter
async function getFaceWarningCount(attemptId) {
  return await FaceLog.countDocuments({
    attemptId: new mongoose.Types.ObjectId(attemptId),
    warningIssued: true
  });
}

// Helper — Update Integrity Score signal
async function saveFaceSignalToAntiCheat(attemptId, examId, studentId) {
  try {
    await AntiCheatLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(studentId),
      eventType: 'face_away',
      metadata: { source: 'face_detection', triggeredAt: new Date() }
    });
  } catch (err) {
    console.error('AntiCheat face signal error:', err.message);
  }
}

// STEP 1 & 2 — Face Detection Model Status
// GET /api/face/model-status
router.get('/model-status', authMiddleware, async (req, res) => {
  try {
    let tfAvailable = false;
    try {
      require('@tensorflow/tfjs-node');
      tfAvailable = true;
    } catch {
      try {
        require('@tensorflow/tfjs');
        tfAvailable = true;
      } catch { tfAvailable = false; }
    }

    return res.status(200).json({
      message: 'Face detection model status',
      tensorflowAvailable: tfAvailable,
      modelReady: true,
      supportedDetections: [
        'single_face',
        'multiple_faces',
        'no_face',
        'eye_tracking',
        'head_pose'
      ],
      note: 'Frontend TensorFlow.js model loads in browser — backend stores flags'
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// STEP 3 — Single Face OK
// POST /api/face/single-face
router.post('/single-face', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, confidence, metadata } = req.body;
    if (!attemptId || !examId)
      return res.status(400).json({ message: 'attemptId aur examId required' });

    const log = await FaceLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'single_face_ok',
      faceCount: 1,
      warningIssued: false,
      metadata: {
        confidence: confidence || 0.95,
        verifiedAt: new Date(),
        ...(metadata || {})
      }
    });

    return res.status(200).json({
      message: 'Single face verified — OK',
      faceCount: 1,
      warningIssued: false,
      logId: log._id
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 4 — Multiple Faces Detected
// POST /api/face/multiple-faces
router.post('/multiple-faces', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, faceCount, metadata } = req.body;
    if (!attemptId || !examId)
      return res.status(400).json({ message: 'attemptId aur examId required' });

    const detectedCount = faceCount || 2;

    const log = await FaceLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'multiple_faces',
      faceCount: detectedCount,
      warningIssued: true,
      flagReason: detectedCount + ' faces detected — only 1 allowed',
      metadata: {
        detectedAt: new Date(),
        ...(metadata || {})
      }
    });

    await saveFaceSignalToAntiCheat(attemptId, examId, req.user.id);
    const warningCount = await getFaceWarningCount(attemptId);

    return res.status(200).json({
      message: 'Multiple faces detected — alert issued',
      faceCount: detectedCount,
      warningIssued: true,
      totalFaceWarnings: warningCount,
      action: 'ADMIN_ALERT',
      logId: log._id
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 5 — No Face Detected
// POST /api/face/no-face
router.post('/no-face', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, duration, metadata } = req.body;
    if (!attemptId || !examId)
      return res.status(400).json({ message: 'attemptId aur examId required' });

    const log = await FaceLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'no_face',
      faceCount: 0,
      warningIssued: true,
      flagReason: 'No face detected — student may have left',
      metadata: {
        durationSeconds: duration || 0,
        detectedAt: new Date(),
        ...(metadata || {})
      }
    });

    await saveFaceSignalToAntiCheat(attemptId, examId, req.user.id);
    const warningCount = await getFaceWarningCount(attemptId);

    return res.status(200).json({
      message: 'No face detected — alert issued',
      faceCount: 0,
      warningIssued: true,
      totalFaceWarnings: warningCount,
      action: 'ADMIN_ALERT',
      logId: log._id
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 6 — Face Warning Counter
// GET /api/face/warning-count/:attemptId
router.get('/warning-count/:attemptId', authMiddleware, async (req, res) => {
  try {
    const { attemptId } = req.params;

    const totalWarnings = await getFaceWarningCount(attemptId);
    const breakdown = await FaceLog.aggregate([
      { $match: { attemptId: new mongoose.Types.ObjectId(attemptId), warningIssued: true } },
      { $group: { _id: '$eventType', count: { $sum: 1 } } }
    ]);

    const breakdownMap = {};
    breakdown.forEach(b => { breakdownMap[b._id] = b.count; });

    return res.status(200).json({
      attemptId,
      totalFaceWarnings: totalWarnings,
      breakdown: breakdownMap,
      riskLevel: totalWarnings >= 5 ? 'HIGH' : totalWarnings >= 2 ? 'MEDIUM' : 'LOW'
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 7 — Eye Tracking Detection (S-ET)
// POST /api/face/eye-tracking
router.post('/eye-tracking', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, gazeDirection, duration, metadata } = req.body;
    if (!attemptId || !examId || !gazeDirection)
      return res.status(400).json({ message: 'attemptId, examId, gazeDirection required' });

    const suspiciousDirections = ['down', 'left', 'right', 'away'];
    const isSuspicious = suspiciousDirections.includes(gazeDirection.toLowerCase());

    const log = await FaceLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'eye_tracking_flag',
      faceCount: 1,
      warningIssued: isSuspicious,
      flagReason: isSuspicious ? 'Eye gaze away from screen: ' + gazeDirection : null,
      eyeTrackingData: {
        gazeDirection,
        durationSeconds: duration || 0,
        threshold: 3,
        isSuspicious
      },
      metadata: {
        detectedAt: new Date(),
        ...(metadata || {})
      }
    });

    if (isSuspicious) {
      await saveFaceSignalToAntiCheat(attemptId, examId, req.user.id);
    }

    const warningCount = await getFaceWarningCount(attemptId);

    return res.status(200).json({
      message: 'Eye tracking logged (S-ET)',
      gazeDirection,
      isSuspicious,
      warningIssued: isSuspicious,
      totalFaceWarnings: warningCount,
      logId: log._id
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 8 — Head Pose Detection (S73)
// POST /api/face/head-pose
router.post('/head-pose', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, poseAngle, poseDirection, duration, metadata } = req.body;
    if (!attemptId || !examId || !poseDirection)
      return res.status(400).json({ message: 'attemptId, examId, poseDirection required' });

    const suspiciousPoses = ['left', 'right', 'down', 'extreme_up'];
    const angle = poseAngle || 0;
    const isSuspicious = suspiciousPoses.includes(poseDirection.toLowerCase()) || Math.abs(angle) > 30;

    const log = await FaceLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'head_pose_flag',
      faceCount: 1,
      warningIssued: isSuspicious,
      flagReason: isSuspicious ? 'Head turned: ' + poseDirection + ' (angle: ' + angle + 'deg)' : null,
      headPoseData: {
        poseDirection,
        poseAngle: angle,
        durationSeconds: duration || 0,
        threshold: 30,
        isSuspicious
      },
      metadata: {
        detectedAt: new Date(),
        ...(metadata || {})
      }
    });

    if (isSuspicious) {
      await saveFaceSignalToAntiCheat(attemptId, examId, req.user.id);
    }

    const warningCount = await getFaceWarningCount(attemptId);

    return res.status(200).json({
      message: 'Head pose logged (S73)',
      poseDirection,
      poseAngle: angle,
      isSuspicious,
      warningIssued: isSuspicious,
      totalFaceWarnings: warningCount,
      logId: log._id
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// ADMIN — All face logs for attempt
router.get('/admin/logs/:attemptId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const logs = await FaceLog.find({
      attemptId: new mongoose.Types.ObjectId(req.params.attemptId)
    }).sort({ timestamp: 1 });

    return res.status(200).json({
      message: 'Face logs fetched',
      totalLogs: logs.length,
      totalWarnings: logs.filter(l => l.warningIssued).length,
      logs
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

module.exports = router;
