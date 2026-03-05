const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Attempt = require('../models/Attempt');
const Exam = require('../models/Exam');
const { verifyToken } = require('../middleware/auth');

// ─────────────────────────────────────────────
// STEP 1 & 2: Save Answer + Auto-Save
// PATCH /api/attempts/:attemptId/save-answer
// ─────────────────────────────────────────────
router.patch('/:attemptId/save-answer', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { questionId, selectedOption, timeTaken } = req.body;
    if (!questionId) return res.status(400).json({ message: 'questionId required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    const qObjId = new mongoose.Types.ObjectId(questionId);
    const existingIndex = attempt.answers.findIndex(a => a.questionId.toString() === qObjId.toString());
    if (existingIndex >= 0) {
      attempt.answers[existingIndex].selectedOption = selectedOption;
      attempt.answers[existingIndex].timeTaken = timeTaken || attempt.answers[existingIndex].timeTaken;
      attempt.answers[existingIndex].savedAt = new Date();
    } else {
      attempt.answers.push({ questionId: qObjId, selectedOption, timeTaken: timeTaken || 0, isMarkedForReview: false, savedAt: new Date() });
    }
    await attempt.save();
    return res.status(200).json({ message: 'Answer saved', totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('save-answer error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// PATCH /api/attempts/:attemptId/auto-save
router.patch('/:attemptId/auto-save', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { answers } = req.body;
    if (!answers || !Array.isArray(answers)) return res.status(400).json({ message: 'answers array required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    for (const ans of answers) {
      const qObjId = new mongoose.Types.ObjectId(ans.questionId);
      const existingIndex = attempt.answers.findIndex(a => a.questionId.toString() === qObjId.toString());
      if (existingIndex >= 0) {
        attempt.answers[existingIndex].selectedOption = ans.selectedOption;
        attempt.answers[existingIndex].timeTaken = ans.timeTaken || 0;
        attempt.answers[existingIndex].savedAt = new Date();
      } else {
        attempt.answers.push({ questionId: qObjId, selectedOption: ans.selectedOption, timeTaken: ans.timeTaken || 0, isMarkedForReview: false, savedAt: new Date() });
      }
    }
    await attempt.save();
    return res.status(200).json({ message: 'Auto-save complete', savedAt: new Date(), totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('auto-save error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 3: Timer Logic
// GET /api/attempts/:attemptId/timer
// ─────────────────────────────────────────────
router.get('/:attemptId/timer', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const exam = await Exam.findById(attempt.examId);
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    const totalDurationSec = (exam.duration || 200) * 60;
    const elapsedSec = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    const remainingSec = Math.max(0, totalDurationSec - elapsedSec);
    return res.status(200).json({ 
    startedAt: attempt.startedAt, 
    totalDurationSec, elapsedSec, remainingSec,
    timeRemaining: remainingSec,
    elapsed: elapsedSec,
    timeLeft: remainingSec,
    remainingTime: remainingSec,
    isExpired: remainingSec <= 0 
  });
  } catch (err) {
    console.error('timer error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 4: Submit + Auto-Submit on Timeout
// POST /api/attempts/:attemptId/submit
// ─────────────────────────────────────────────
router.post('/:attemptId/submit', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { isAutoSubmit } = req.body;
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status === 'submitted') return res.status(400).json({ message: 'Already submitted' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    const exam = await Exam.findById(attempt.examId);
    const totalDurationSec = (exam ? exam.duration || 200 : 200) * 60;
    const elapsedSec = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    attempt.status = elapsedSec > totalDurationSec + 30 ? 'timeout' : 'submitted';
    attempt.submittedAt = new Date();
    attempt.deviceSessionId = null;
    await attempt.save();
    return res.status(200).json({ message: isAutoSubmit ? 'Auto-submitted on timeout' : 'Exam submitted successfully', status: attempt.status, submittedAt: attempt.submittedAt, totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('submit error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 5: Bookmark / Flag Toggle (S1)
// PATCH /api/attempts/:attemptId/bookmark
// ─────────────────────────────────────────────
router.patch('/:attemptId/bookmark', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { questionId } = req.body;
    if (!questionId) return res.status(400).json({ message: 'questionId required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    const qObjId = new mongoose.Types.ObjectId(questionId);
    const existingIndex = attempt.answers.findIndex(a => a.questionId.toString() === qObjId.toString());
    let isMarkedForReview = false;
    if (existingIndex >= 0) {
      attempt.answers[existingIndex].isMarkedForReview = !attempt.answers[existingIndex].isMarkedForReview;
      isMarkedForReview = attempt.answers[existingIndex].isMarkedForReview;
    } else {
      attempt.answers.push({ questionId: qObjId, selectedOption: null, timeTaken: 0, isMarkedForReview: true, savedAt: new Date() });
      isMarkedForReview = true;
    }
    await attempt.save();
    return res.status(200).json({ message: isMarkedForReview ? 'Question bookmarked' : 'Bookmark removed', isMarkedForReview });
  } catch (err) {
    console.error('bookmark error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 6: Navigation Panel - Color Coded (S2)
// GET /api/attempts/:attemptId/navigation
// ─────────────────────────────────────────────
router.get('/:attemptId/navigation', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const exam = await Exam.findById(attempt.examId).populate({path: "questions", strictPopulate: false});
    if (!exam) return res.status(404).json({ message: 'Exam not found' });

    const answerMap = {};
    for (const ans of attempt.answers) {
      answerMap[ans.questionId.toString()] = ans;
    }

    const navigation = (exam.questions || []).map((q, index) => {
      const qId = q._id.toString();
      const ans = answerMap[qId];
      let status = 'not-visited'; // grey
      if (ans) {
        if (ans.isMarkedForReview && ans.selectedOption !== null && ans.selectedOption !== undefined) {
          status = 'answered-flagged'; // purple+green
        } else if (ans.isMarkedForReview) {
          status = 'flagged'; // purple
        } else if (ans.selectedOption !== null && ans.selectedOption !== undefined) {
          status = 'answered'; // green
        } else {
          status = 'visited'; // red (visited but not answered)
        }
      }
      return { index: index + 1, questionId: qId, status };
    });

    const summary = {
      answered: navigation.filter(n => n.status === 'answered').length,
      unanswered: navigation.filter(n => n.status === 'visited').length,
      flagged: navigation.filter(n => n.status === 'flagged' || n.status === 'answered-flagged').length,
      notVisited: navigation.filter(n => n.status === 'not-visited').length,
      total: navigation.length
    };

    return res.status(200).json({ navigation, summary });
  } catch (err) {
    console.error('navigation error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 7: Connection Lost Protection (S51)
// PATCH /api/attempts/:attemptId/pause
// PATCH /api/attempts/:attemptId/resume
// ─────────────────────────────────────────────
router.patch('/:attemptId/pause', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    attempt.isPaused = true;
    attempt.pausedAt = new Date();
    await attempt.save();
    return res.status(200).json({ message: 'Exam paused - answers saved', pausedAt: attempt.pausedAt });
  } catch (err) {
    console.error('pause error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.patch('/:attemptId/resume', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    attempt.isPaused = false;
    attempt.pausedAt = null;
    await attempt.save();
    return res.status(200).json({ message: 'Exam resumed', resumedAt: new Date(), totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('resume error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 8: Multi-Device Session Control (S112)
// POST /api/attempts/:attemptId/register-device
// ─────────────────────────────────────────────
router.post('/:attemptId/register-device', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { deviceSessionId } = req.body;
    if (!deviceSessionId) return res.status(400).json({ message: 'deviceSessionId required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });

    // If another device already registered
    if (attempt.deviceSessionId && attempt.deviceSessionId !== deviceSessionId) {
      return res.status(403).json({
        message: 'Exam already open on another device. Close it first.',
        blocked: true
      });
    }

    attempt.deviceSessionId = deviceSessionId;
    await attempt.save();
    return res.status(200).json({ message: 'Device registered successfully', deviceSessionId });
  } catch (err) {
    console.error('register-device error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 9: Exam Paper Encryption Key (N23)
// GET /api/attempts/:attemptId/paper-key
// ─────────────────────────────────────────────
router.get('/:attemptId/paper-key', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });

    // Generate a session-bound encryption key
    // Key = hash of attemptId + studentId + secret
    const crypto = require('crypto');
    const secret = process.env.JWT_SECRET || 'proverank_secret';
    const raw = `${attempt._id}:${attempt.studentId}:${secret}`;
    const encryptionKey = crypto.createHash('sha256').update(raw).digest('hex').substring(0, 32);

    return res.status(200).json({
      message: 'Paper key issued',
      key: encryptionKey,
      expiresIn: '200m'
    });
  } catch (err) {
    console.error('paper-key error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/attempts/:attemptId — existing route (Phase 4.1)
router.get('/:attemptId', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    return res.status(200).json({ attempt });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
