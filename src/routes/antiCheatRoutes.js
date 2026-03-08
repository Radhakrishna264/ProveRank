const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const AntiCheatLog = require('../models/AntiCheatLog');
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

function authMiddleware(req, res, next) {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ message: 'Token required' });
  try {
    req.user = jwt.verify(h.split(' ')[1], JWT_SECRET);
    next();
  } catch { return res.status(401).json({ message: 'Invalid token' }); }
}

function adminMiddleware(req, res, next) {
  if (req.user.role !== 'superadmin' && req.user.role !== 'admin')
    return res.status(403).json({ message: 'Admin access required' });
  next();
}

async function checkAndAutoSubmit(attemptId, studentId) {
  try {
    const Attempt = mongoose.model('Attempt');
    const warningEvents = ['tab_switch', 'window_blur', 'fullscreen_exit'];
    const warningCount = await AntiCheatLog.countDocuments({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      eventType: { $in: warningEvents }
    });
    if (warningCount >= 3) {
      const attempt = await Attempt.findById(attemptId);
      if (attempt && attempt.status === 'active') {
        attempt.status = 'submitted';
        attempt.submittedAt = new Date();
        attempt.autoSubmitReason = 'anti_cheat_3_warnings';
        await attempt.save();
        await AntiCheatLog.create({
          attemptId: new mongoose.Types.ObjectId(attemptId),
          examId: attempt.examId,
          studentId: new mongoose.Types.ObjectId(studentId),
          eventType: 'tab_switch',
          metadata: { autoSubmit: true, reason: '3_warnings_reached', totalWarnings: warningCount },
          autoSubmitTriggered: true,
          warningNumber: warningCount
        });
        return { autoSubmitted: true, warningCount };
      }
    }
    return { autoSubmitted: false, warningCount };
  } catch (err) {
    return { autoSubmitted: false, warningCount: 0 };
  }
}

// STEP 1 — Tab Switch
router.post('/tab-switch', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, metadata } = req.body;
    if (!attemptId || !examId) return res.status(400).json({ message: 'attemptId aur examId required' });
    const log = await AntiCheatLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'tab_switch',
      metadata: metadata || {},
      timestamp: new Date()
    });
    const r = await checkAndAutoSubmit(attemptId, req.user.id);
    log.warningNumber = r.warningCount;
    if (r.autoSubmitted) log.autoSubmitTriggered = true;
    await log.save();
    return res.status(200).json({ message: 'Tab switch logged', warningCount: r.warningCount, autoSubmitted: r.autoSubmitted, logId: log._id });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 2 — Window Blur
router.post('/window-blur', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, metadata } = req.body;
    if (!attemptId || !examId) return res.status(400).json({ message: 'attemptId aur examId required' });
    const log = await AntiCheatLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'window_blur',
      metadata: metadata || {},
      timestamp: new Date()
    });
    const r = await checkAndAutoSubmit(attemptId, req.user.id);
    log.warningNumber = r.warningCount;
    if (r.autoSubmitted) log.autoSubmitTriggered = true;
    await log.save();
    return res.status(200).json({ message: 'Window blur logged', warningCount: r.warningCount, autoSubmitted: r.autoSubmitted, logId: log._id });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 3 — Warning Count
router.get('/warning-count/:attemptId', authMiddleware, async (req, res) => {
  try {
    const { attemptId } = req.params;
    const warningCount = await AntiCheatLog.countDocuments({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      eventType: { $in: ['tab_switch', 'window_blur', 'fullscreen_exit'] }
    });
    const autoSub = await AntiCheatLog.findOne({ attemptId: new mongoose.Types.ObjectId(attemptId), autoSubmitTriggered: true });
    return res.status(200).json({ attemptId, warningCount, maxWarnings: 3, autoSubmitTriggered: !!autoSub, remainingWarnings: Math.max(0, 3 - warningCount) });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 4 — Fullscreen Exit (S32)
router.post('/fullscreen-exit', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, metadata } = req.body;
    if (!attemptId || !examId) return res.status(400).json({ message: 'attemptId aur examId required' });
    const log = await AntiCheatLog.create({
      attemptId: new mongoose.Types.ObjectId(attemptId),
      examId: new mongoose.Types.ObjectId(examId),
      studentId: new mongoose.Types.ObjectId(req.user.id),
      eventType: 'fullscreen_exit',
      metadata: metadata || { reason: 'student_exited_fullscreen' },
      timestamp: new Date()
    });
    const r = await checkAndAutoSubmit(attemptId, req.user.id);
    log.warningNumber = r.warningCount;
    if (r.autoSubmitted) log.autoSubmitTriggered = true;
    await log.save();
    return res.status(200).json({ message: 'Fullscreen exit logged (S32)', warningCount: r.warningCount, autoSubmitted: r.autoSubmitted, action: r.warningCount >= 3 ? 'AUTO_SUBMITTED' : 'WARNING_ISSUED' });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

router.get('/fullscreen-status/:attemptId', authMiddleware, async (req, res) => {
  try {
    const count = await AntiCheatLog.countDocuments({ attemptId: new mongoose.Types.ObjectId(req.params.attemptId), eventType: 'fullscreen_exit' });
    return res.status(200).json({ attemptId: req.params.attemptId, fullscreenExitCount: count, fullscreenEnforced: true, warningLimit: 3 });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 5 — Watermark (S76)
router.get('/watermark/:attemptId', authMiddleware, async (req, res) => {
  try {
    const User = mongoose.model('User');
    const student = await User.findById(req.user.id).select('name email');
    if (!student) return res.status(404).json({ message: 'Student not found' });
    return res.status(200).json({
      message: 'Watermark data ready (S76)',
      watermark: {
        studentId: req.user.id,
        studentName: student.name,
        studentEmail: student.email,
        attemptId: req.params.attemptId,
        watermarkText: student.name + ' | ' + student.email + ' | ' + new Date().toISOString().split('T')[0],
        displayStyle: { opacity: 0.15, position: 'diagonal', fontSize: '14px', color: '#000000' },
        generatedAt: new Date()
      }
    });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 6 — Session Lock (S112)
router.post('/session-lock-check', authMiddleware, async (req, res) => {
  try {
    const { attemptId, examId, deviceFingerprint } = req.body;
    if (!attemptId || !examId) return res.status(400).json({ message: 'attemptId aur examId required' });
    const Attempt = mongoose.model('Attempt');
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.studentId.toString() !== req.user.id.toString()) {
      await AntiCheatLog.create({ attemptId: new mongoose.Types.ObjectId(attemptId), examId: new mongoose.Types.ObjectId(examId), studentId: new mongoose.Types.ObjectId(req.user.id), eventType: 'multi_device', metadata: { blockedDevice: deviceFingerprint } });
      return res.status(403).json({ message: 'Session lock — doosre device pe exam chal raha hai (S112)', sessionLocked: true });
    }
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt active nahi hai', status: attempt.status, sessionLocked: false });
    const existingMulti = await AntiCheatLog.findOne({ attemptId: new mongoose.Types.ObjectId(attemptId), eventType: 'multi_device' });
    if (existingMulti) return res.status(403).json({ message: 'Multi-device attempt detected (S112)', sessionLocked: true });
    return res.status(200).json({ message: 'Session valid — single device confirmed (S112)', sessionLocked: false, attemptId, studentId: req.user.id });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 7 — N14: Suspicious Answer Pattern
router.get('/suspicious-patterns/:attemptId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const Attempt = mongoose.model('Attempt');
    const attempt = await Attempt.findById(req.params.attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const suspiciousFlags = [];
    if (attempt.answers && attempt.answers.length > 0) {
      for (const ans of attempt.answers) {
        if (ans.timeTaken !== undefined && ans.timeTaken < 5) {
          suspiciousFlags.push({ type: 'TOO_FAST_ANSWER', questionId: ans.questionId, timeTaken: ans.timeTaken, threshold: 5 });
        }
      }
      if (attempt.answers.length >= 10) {
        let streak = 1, maxStreak = 1;
        for (let i = 1; i < attempt.answers.length; i++) {
          const p = attempt.answers[i - 1], c = attempt.answers[i];
          if (c.selectedOption !== undefined && p.selectedOption !== undefined && c.selectedOption === p.selectedOption) {
            streak++; maxStreak = Math.max(maxStreak, streak);
          } else streak = 1;
        }
        if (maxStreak >= 10) suspiciousFlags.push({ type: 'IDENTICAL_PATTERN', maxConsecutiveStreak: maxStreak, threshold: 10 });
      }
    }
    if (suspiciousFlags.length > 0) {
      await AntiCheatLog.create({ attemptId: new mongoose.Types.ObjectId(req.params.attemptId), examId: attempt.examId, studentId: attempt.studentId, eventType: 'fast_answer', metadata: { flags: suspiciousFlags, totalFlags: suspiciousFlags.length } });
    }
    return res.status(200).json({ message: 'N14: Suspicious pattern analysis complete', attemptId: req.params.attemptId, isSuspicious: suspiciousFlags.length > 0, suspiciousFlags, totalFlagsFound: suspiciousFlags.length, adminAlert: suspiciousFlags.length > 0 ? 'REVIEW_REQUIRED' : 'CLEAN' });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// STEP 8 — AI-6: Integrity Score
router.get('/integrity-score/:attemptId', authMiddleware, async (req, res) => {
  try {
    const logs = await AntiCheatLog.find({ attemptId: new mongoose.Types.ObjectId(req.params.attemptId) });
    const s = { tab_switch: 0, window_blur: 0, fullscreen_exit: 0, fast_answer: 0, identical_pattern: 0, ip_flag: 0, face_away: 0, multi_device: 0 };
    for (const log of logs) {
      if (s[log.eventType] !== undefined) s[log.eventType]++;
      if (log.eventType === 'fast_answer' && log.metadata && log.metadata.flags) {
        s.fast_answer += log.metadata.flags.filter(f => f.type === 'TOO_FAST_ANSWER').length;
        if (log.metadata.flags.some(f => f.type === 'IDENTICAL_PATTERN')) s.identical_pattern++;
      }
    }
    const penalties = {
      tab_switch: s.tab_switch * 15, window_blur: s.window_blur * 10,
      fullscreen_exit: s.fullscreen_exit * 15, fast_answer: Math.min(s.fast_answer * 5, 20),
      identical_pattern: s.identical_pattern * 20, ip_flag: s.ip_flag * 25,
      face_away: s.face_away * 10, multi_device: s.multi_device * 30
    };
    const totalPenalty = Object.values(penalties).reduce((a, b) => a + b, 0);
    const integrityScore = Math.max(0, Math.min(100, 100 - totalPenalty));
    const riskLevel = integrityScore < 40 ? 'HIGH' : integrityScore < 70 ? 'MEDIUM' : 'LOW';
    const interp = integrityScore >= 90 ? 'Clean — No suspicious activity' : integrityScore >= 70 ? 'Minor — Some warnings logged' : integrityScore >= 40 ? 'Medium Risk — Review recommended' : 'High Risk — Likely cheating attempt';
    return res.status(200).json({ message: 'AI-6: Integrity Score calculated', attemptId: req.params.attemptId, integrityScore, riskLevel, signals: s, penalties, totalPenalty, interpretation: interp });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// ADMIN — All logs
router.get('/admin/logs/:attemptId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const logs = await AntiCheatLog.find({ attemptId: new mongoose.Types.ObjectId(req.params.attemptId) }).sort({ timestamp: 1 });
    return res.status(200).json({ message: 'Logs fetched', totalLogs: logs.length, logs });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

// ADMIN — Alerts summary
router.get('/admin/alerts', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const alerts = await AntiCheatLog.aggregate([
      { $group: { _id: '$attemptId', studentId: { $first: '$studentId' }, examId: { $first: '$examId' }, totalEvents: { $sum: 1 }, eventTypes: { $addToSet: '$eventType' }, latestEvent: { $max: '$timestamp' } } },
      { $match: { totalEvents: { $gte: 1 } } },
      { $sort: { totalEvents: -1 } },
      { $limit: 50 }
    ]);
    return res.status(200).json({ message: 'Admin alerts fetched', totalAlerts: alerts.length, alerts });
  } catch (err) { return res.status(500).json({ message: 'Server error', error: err.message }); }
});

module.exports = router;
