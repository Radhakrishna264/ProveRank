#!/bin/bash
set -e
echo "=== ProveRank F52 (My Exams) — Fix Script ==="

# ---- 1) Backend: src/routes/exam.js (your uploaded exam_1.js) ----
cat > ~/workspace/src/routes/exam.js << 'FILEEOF1'
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Exam = require('../models/Exam');
const User = require('../models/User');
const Attempt = require('../models/Attempt');
const { verifyToken, isAdmin } = require('../middleware/auth');

// CREATE EXAM
router.post('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.create({ ...req.body, createdBy: req.user.id });
    if (Array.isArray(exam.questions) && exam.questions.length > 0) {
      const Question = require('../models/Question');
      await Question.updateMany({ _id: { $in: exam.questions } }, { $inc: { usageCount: 1 } });
    }
    res.status(201).json({ message: 'Exam created', exam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// GET ALL EXAMS
router.get('/', verifyToken, async (req, res) => {
  try {
    const { batch, category, status } = req.query;
    const filter = {};
    if (batch) filter.batch = batch;
    if (category) filter.category = category;
    if (status) filter.status = status;
    const exams = await Exam.find(filter).populate('createdBy', 'name email');
    res.json({ exams });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// GET SINGLE EXAM
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    // SECURITY FIX (F52) — plaintext exam.password must NEVER reach a student
    // client. Only admin/superadmin get the real value (needed for edit forms).
    const isPrivileged = req.user && (req.user.role === 'admin' || req.user.role === 'superadmin');
    const examOut = exam.toObject();
    if (!isPrivileged) {
      examOut.passwordProtected = !!examOut.password;
      delete examOut.password;
    }
    res.json({ exam: examOut });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// VERIFY EXAM PASSWORD — server-side check, never exposes the real password (F52 security fix)
router.post('/:id/verify-password', verifyToken, async (req, res) => {
  try {
    const { password } = req.body || {};
    const exam = await Exam.findById(req.params.id).select('password');
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    if (!exam.password) return res.json({ valid: true }); // not password protected
    const valid = typeof password === 'string' && password === exam.password;
    res.json({ valid });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE EXAM
router.put('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ message: 'Exam updated', exam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// DELETE EXAM
router.delete('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    await Exam.findByIdAndDelete(req.params.id);
    res.json({ message: 'Exam deleted' });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// GET attempt by ID - Phase 4.1 Step 7+8
router.get('/attempt/:attemptId', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const obj = attempt.toObject();
    return res.status(200).json({
      ...obj,
      ipAddress: obj.ipAddress || null,
      startTime: obj.startedAt || null
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── QsBank -> Exam Integration: Add multiple questions to existing exam (Feature 1.3a) ──
router.patch('/:id/questions', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionIds } = req.body;
    if (!Array.isArray(questionIds) || questionIds.length === 0) {
      return res.status(400).json({ message: 'questionIds array required' });
    }
    const objIds = questionIds.map(id => new mongoose.Types.ObjectId(id));
    const exam = await Exam.findByIdAndUpdate(
      req.params.id,
      { $addToSet: { questions: { $each: objIds } } },
      { new: true }
    );
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    const Question = require('../models/Question');
    await Question.updateMany({ _id: { $in: objIds } }, { $inc: { usageCount: 1 } });
    res.json({ success: true, message: questionIds.length + ' questions added to exam', exam });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// START ATTEMPT — Phase 4.1
router.post('/:examId/start-attempt', verifyToken, async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.user.id;
    const examObjId = new mongoose.Types.ObjectId(examId);
    const studentObjId = new mongoose.Types.ObjectId(studentId);
    const exam = await Exam.findById(examObjId);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });

    // Rule 1.15.9 — defense-in-depth: block NEW attempt creation once the live
    // join grace period (5 min) has passed while exam is still 'live'. Once the
    // exam's schedule.endTime passes (or status flips to 'ended'), this no
    // longer applies and the exam becomes attemptable again (frontend then
    // skips Waiting Room entirely and goes straight to Instructions).
    if (exam.status === 'live' && exam.schedule && exam.schedule.startTime) {
      const startMs = new Date(exam.schedule.startTime).getTime();
      const endMs = exam.schedule.endTime ? new Date(exam.schedule.endTime).getTime() : null;
      const graceMs = 5 * 60 * 1000;
      const nowMs = Date.now();
      const pastGrace = nowMs > startMs + graceMs;
      const stillWithinLiveWindow = endMs ? nowMs <= endMs : true;
      if (pastGrace && stillWithinLiveWindow) {
        return res.status(403).json({
          error: 'Live join window has closed for this exam. You can try again after the exam ends.',
          code: 'JOIN_WINDOW_CLOSED'
        });
      }
    }

    const usedAttempts = await Attempt.countDocuments({ examId: examObjId, studentId: studentObjId, status: { $in: ['submitted', 'timeout'] } });
    const maxAttempts = exam.unlimitedAttempts ? Infinity : exam.maxAttempts;
    if (usedAttempts >= maxAttempts) return res.status(403).json({ error: 'Attempt limit reached' });

    const student = await User.findById(studentObjId);
    if (!student) return res.status(404).json({ error: 'Student not found' });
    if (!student.termsAccepted) return res.status(403).json({ error: 'Terms not accepted' });

    const newAttempt = new Attempt({
      examId: examObjId,
      studentId: studentObjId,
      startedAt: new Date(),
      status: 'active',
      attemptNumber: usedAttempts + 1,
      termsAccepted: true,
      termsAcceptedAt: new Date(),
      ipAddress: req.headers['x-forwarded-for'] || req.connection.remoteAddress || 'unknown'
    });
    await newAttempt.save();

    // Rule 1.15.10 — once attempt is active, waiting room is no longer valid for this exam.
    // (Waiting-room join record is intentionally left as-is for history; the frontend/backend
    //  guard is enforced via GET /api/exams/my-exams -> activeAttemptId on the waiting/instructions pages.)

    res.status(200).json({ success: true, attemptId: newAttempt._id, message: 'Attempt started' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Test Generator Route (Phase 9.1)
router.post('/generate', verifyToken, async (req, res) => {
  try {
    const { subject, difficulty, count = 10 } = req.body;
    const Question = require('../models/Question');
    const query = {};
    if (subject) query.subject = subject;
    if (difficulty) query.difficulty = difficulty;
    const questions = await Question.aggregate([{ $match: query }, { $sample: { size: parseInt(count) } }]);
    res.json({ success: true, questions, total: questions.length });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Exam Clone Route (Phase 9.1)
router.post('/:examId/clone', verifyToken, async (req, res) => {
  try {
    const Exam = require('../models/Exam');
    const original = await Exam.findById(req.params.examId).lean();
    if (!original) return res.status(404).json({ message: 'Exam not found' });
    delete original._id;
    original.title = original.title + ' (Clone)';
    original.createdAt = new Date();
    original.updatedAt = new Date();
    const cloned = await Exam.create(original);
    res.status(201).json({ success: true, exam: cloned });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Add Question to Exam (Step 08)
router.post('/:examId/questions', verifyToken, async (req, res) => {
  try {
    const Exam = require('../models/Exam');
    const { questionId } = req.body;
    const exam = await Exam.findByIdAndUpdate(
      req.params.examId,
      { $addToSet: { questions: questionId } },
      { new: true }
    );
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    res.json({ success: true, exam });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
FILEEOF1
echo "exam.js updated ✅"

# ---- 2) Backend: src/routes/examFlow.js ----
cat > ~/workspace/src/routes/examFlow.js << 'FILEEOF2'
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Exam = require('../models/Exam');
const User = require('../models/User');
const Attempt = require('../models/Attempt');
const Batch = require('../models/Batch');
let TestSeries;
try { TestSeries = require('../models/TestSeries'); } catch (e) { TestSeries = null; }
const { verifyToken } = require('../middleware/auth');

const TERMS_VERSION = '1.0';
const GRACE_MS = 5 * 60 * 1000; // live-join grace period

// ── In-memory waiting-room chat store (ephemeral, resets on restart — ──
// ── acceptable for exam-day chat; last 100 msgs per exam kept) ────────
const chatStore = new Map();
function pushChat(examId, msg) {
  const key = String(examId);
  const arr = chatStore.get(key) || [];
  arr.push(msg);
  if (arr.length > 100) arr.shift();
  chatStore.set(key, arr);
}

// ══ Helper: read a student's real enrollment (Rule fix — was reading
// Batch.students which is NEVER populated by the actual enroll flow;
// real source of truth is User.enrolledBatches, populated via raw
// collection driver same as studentBatches.js / myBatches.js) ══
async function getEnrollment(studentId) {
  const userDoc = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(studentId) });
  const ids = (userDoc && userDoc.enrolledBatches) || [];
  const [batches, series] = await Promise.all([
    Batch.find({ _id: { $in: ids } }).select('_id name').lean(),
    TestSeries ? TestSeries.find({ _id: { $in: ids } }).select('_id title name').lean() : Promise.resolve([])
  ]);
  return {
    userDoc,
    batchIds: batches.map(b => String(b._id)),
    batchNames: batches.map(b => b.name).filter(Boolean),
    seriesIds: series.map(s => String(s._id)),
    seriesNames: series.map(s => s.title || s.name).filter(Boolean)
  };
}

// ══ Helper: does this student have visibility on this exam? ══
function canSeeExam(exam, studentId, student, enrollment) {
  if (exam.isArchived) return false;

  if (exam.whitelistEnabled) {
    const inStudentList = (exam.whitelistedStudents || []).some(id => String(id) === String(studentId));
    const inGroupList = student && student.group && (exam.whitelistedGroups || []).includes(student.group);
    return !!(inStudentList || inGroupList);
  }
  if (Array.isArray(exam.whitelist) && exam.whitelist.length > 0) {
    return exam.whitelist.some(id => String(id) === String(studentId));
  }
  // F54 FIX — an exam can be linked to BOTH a series and a batch at once.
  // Previously assignmentType==='series' short-circuited and skipped the
  // batch check entirely, hiding the exam from batch-only-enrolled students.
  // Now check series AND batch independently — visible if EITHER matches.
  if (exam.testSeriesId && enrollment.seriesIds.includes(String(exam.testSeriesId))) {
    return true;
  }
  const hasBatchTarget = !!exam.batch || (exam.multiBatch && exam.multiBatch.length > 0);
  if (hasBatchTarget) {
    const targets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean).map(String);
    if (targets.some(t => enrollment.batchIds.includes(t) || enrollment.batchNames.includes(t))) {
      return true;
    }
  }
  return false; // F52/F54 — not linked to any enrolled batch or series, so must NOT show on My Exams
}

// ══ Helper: compute full exam state (status, join window, waiting-room ══
// ══ window, Rule 1.15.9 skip logic, next-available-attempt time)      ══
function computeExamState(exam, now, usedAttempts) {
  const start = exam.schedule && exam.schedule.startTime ? new Date(exam.schedule.startTime) : null;
  const end = exam.schedule && exam.schedule.endTime ? new Date(exam.schedule.endTime) : null;
  const waitMins = typeof exam.waitingRoomMinutes === 'number' ? exam.waitingRoomMinutes : 20;
  const chatMins = typeof exam.waitingChatMinutes === 'number' ? exam.waitingChatMinutes : 10;
  const bufferMins = typeof exam.waitingAutoCloseBufferMinutes === 'number' ? exam.waitingAutoCloseBufferMinutes : 8;

  let derivedStatus = exam.status;
  const minsToStart = start ? (start.getTime() - now.getTime()) / 60000 : null;
  const secsToStart = start ? Math.round((start.getTime() - now.getTime()) / 1000) : null;

  let joinState = 'not_applicable';
  let waitingRoomWindowOpen = false;
  let skipWaitingRoom = false;
  let nextAvailableAttemptTime = null;

  const maxAttempts = exam.unlimitedAttempts ? Infinity : (exam.maxAttempts || 1);
  const attemptsLeft = maxAttempts === Infinity ? Infinity : Math.max(0, maxAttempts - usedAttempts);

  if (derivedStatus === 'scheduled' && start) {
    if (minsToStart <= waitMins && minsToStart > 0) {
      waitingRoomWindowOpen = true;
      joinState = 'waiting_room_open';
    } else if (minsToStart <= 0) {
      derivedStatus = 'live'; // start time passed but cron/admin hasn't flipped status yet
    } else {
      joinState = 'available_later';
    }
  }

  if (derivedStatus === 'live' && start) {
    const nowMs = now.getTime();
    const startMs = start.getTime();
    if (nowMs <= startMs + GRACE_MS) {
      joinState = 'join_open';
      // Rule 1.15.5 — inside live grace window, waiting room already closed by now
      // (its own auto-close buffer fired earlier); nothing further needed here.
    } else if (end && nowMs > end.getTime()) {
      derivedStatus = 'ended';
    } else {
      joinState = 'join_closed';
      nextAvailableAttemptTime = end || null; // Rule 1.15.9 — must wait till exam ends
    }
  }

  if (derivedStatus === 'ended') {
    if (attemptsLeft > 0) {
      joinState = 'available_again';
      skipWaitingRoom = true; // Rule 1.15.9 — waiting room skipped entirely once ended
    } else {
      joinState = 'locked';
    }
  }

  return {
    derivedStatus, minsToStart, secsToStart, joinState, waitingRoomWindowOpen,
    skipWaitingRoom, attemptsLeft: attemptsLeft === Infinity ? -1 : attemptsLeft,
    nextAvailableAttemptTime, waitMins, chatMins, bufferMins
  };
}

// ══ Helper: performance summary chips (F52 §10.6 — avg score + rank trend) ══
async function getPerformanceSummary(examId, studentId) {
  const attempts = await Attempt.find({ examId, studentId, status: 'submitted' })
    .sort({ submittedAt: 1 }).select('score rank submittedAt').lean();
  if (!attempts.length) return null;
  const scores = attempts.map(a => a.score).filter(s => typeof s === 'number');
  const ranks = attempts.map(a => a.rank).filter(r => typeof r === 'number');
  const best = scores.length ? Math.max(...scores) : null;
  const avg = scores.length ? Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 100) / 100 : null;
  let rankTrend = 'flat';
  if (ranks.length >= 2) {
    const first = ranks[0], last = ranks[ranks.length - 1];
    rankTrend = last < first ? 'up' : (last > first ? 'down' : 'flat'); // lower rank number = better
  }
  return {
    attemptCount: attempts.length,
    bestScore: best,
    avgScore: avg,
    lastAttemptAt: attempts[attempts.length - 1].submittedAt,
    rankTrend,
    latestRank: ranks.length ? ranks[ranks.length - 1] : null
  };
}

// ════════════════════════════════════════════════════════════
// F52 — GET /api/exams/my-exams
// ════════════════════════════════════════════════════════════
router.get('/my-exams', verifyToken, async (req, res) => {
  try {
    const studentId = req.user.id;
    const now = new Date();
    const [enrollment, student] = await Promise.all([
      getEnrollment(studentId),
      User.findById(studentId).select('group').lean()
    ]);

    const exams = await Exam.find({ isArchived: { $ne: true }, status: { $in: ['scheduled', 'live', 'ended'] } }).lean();
    const visible = exams.filter(e => canSeeExam(e, studentId, student, enrollment));
    const examIds = visible.map(e => e._id);

    const [activeAttempts, allAttempts] = await Promise.all([
      Attempt.find({ examId: { $in: examIds }, studentId, status: { $in: ['waiting', 'instructions', 'active'] } }).select('examId').lean(),
      Attempt.find({ examId: { $in: examIds }, studentId }).select('examId status').lean()
    ]);
    const activeByExam = {};
    activeAttempts.forEach(a => { activeByExam[String(a.examId)] = a; });
    const joinedSet = new Set(((enrollment.userDoc && enrollment.userDoc.waitingRoomJoins) || []).map(j => String(j.examId)));
    const reminderMap = {};
    ((enrollment.userDoc && enrollment.userDoc.examReminders) || []).forEach(r => { reminderMap[String(r.examId)] = r.enabled; });

    const result = await Promise.all(visible.map(async e => {
      const eid = String(e._id);
      const usedAttempts = allAttempts.filter(a => String(a.examId) === eid && (a.status === 'submitted' || a.status === 'timeout')).length;
      const state = computeExamState(e, now, usedAttempts);
      const perf = (state.derivedStatus === 'ended' || usedAttempts > 0) ? await getPerformanceSummary(e._id, studentId) : null;
      return {
        _id: e._id,
        title: e.title,
        subject: e.subject,
        duration: e.duration,
        totalMarks: e.totalMarks,
        category: e.category,
        assignmentType: e.assignmentType || 'individual',
        batch: e.batch,
        multiBatch: e.multiBatch,
        testSeriesId: e.testSeriesId || null,
        seriesName: e.seriesName || '',
        schedule: e.schedule,
        passwordProtected: !!e.password,
        status: e.status,
        activeAttemptId: activeByExam[eid] ? activeByExam[eid]._id : null,
        hasJoinedWaitingRoom: joinedSet.has(eid),
        reminderEnabled: reminderMap[eid] !== undefined ? reminderMap[eid] : true,
        performance: perf,
        ...state
      };
    }));

    res.json({
      success: true,
      exams: result,
      syncedBatches: enrollment.batchNames,
      syncedSeries: enrollment.seriesNames
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// F53 — GET /api/exams/:id/waiting-info
// ════════════════════════════════════════════════════════════
router.get('/:id/waiting-info', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).lean();
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    const now = new Date();
    const usedAttempts = await Attempt.countDocuments({ examId: exam._id, studentId: req.user.id, status: { $in: ['submitted', 'timeout'] } });
    const state = computeExamState(exam, now, usedAttempts);

    const userDoc = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const joinRec = ((userDoc && userDoc.waitingRoomJoins) || []).find(j => String(j.examId) === String(exam._id));
    const activeAttempt = await Attempt.findOne({ examId: exam._id, studentId: req.user.id, status: { $in: ['waiting', 'instructions', 'active'] } }).select('_id').lean();

    let liveCount = 0;
    try {
      const { getIO } = require('../config/socket');
      const room = getIO().sockets.adapter.rooms.get(`waiting-${exam._id}`);
      liveCount = room ? room.size : 0;
    } catch (e) { /* socket not initialized — non-fatal */ }

    res.json({
      success: true,
      exam: {
        _id: exam._id, title: exam.title, duration: exam.duration, totalMarks: exam.totalMarks,
        totalQuestions: (exam.questions || []).length, schedule: exam.schedule,
        customInstructions: exam.customInstructions
      },
      hasJoinedWaitingRoom: !!joinRec,
      joinedAt: joinRec ? joinRec.joinedAt : null,
      activeAttemptId: activeAttempt ? activeAttempt._id : null,
      liveCount,
      config: { waitingRoomMinutes: state.waitMins, chatMinutes: state.chatMins, autoCloseBufferMinutes: state.bufferMins },
      state
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// Rule 1.15.7 — POST /api/exams/:id/join-waiting-room
// Waiting room NEVER opens automatically — this is the only way
// hasJoinedWaitingRoom becomes true, and it's called only from an
// explicit student click.
// ════════════════════════════════════════════════════════════
router.post('/:id/join-waiting-room', verifyToken, async (req, res) => {
  try {
    const examId = new mongoose.Types.ObjectId(req.params.id);
    const studentObjId = new mongoose.Types.ObjectId(req.user.id);
    const exam = await Exam.findById(examId).lean();
    if (!exam) return res.status(404).json({ error: 'Exam not found' });

    // Rule 1.15.10 — cannot (re)join waiting room if an attempt is already active
    const activeAttempt = await Attempt.findOne({ examId, studentId: req.user.id, status: { $in: ['waiting', 'instructions', 'active'] } }).lean();
    if (activeAttempt) {
      return res.status(409).json({ error: 'Exam attempt already in progress', activeAttemptId: activeAttempt._id });
    }

    const userDoc = await User.collection.findOne({ _id: studentObjId });
    const already = ((userDoc && userDoc.waitingRoomJoins) || []).find(j => String(j.examId) === String(examId));
    if (!already) {
      await User.collection.updateOne({ _id: studentObjId }, { $push: { waitingRoomJoins: { examId, joinedAt: new Date() } } });
    }
    res.json({ success: true, joined: true, alreadyJoined: !!already, joinedAt: already ? already.joinedAt : new Date() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── F53 §5 — Waiting room chat (10-min window, per-student, checked server-side) ──
router.get('/:id/waiting-room/chat', verifyToken, async (req, res) => {
  res.json({ success: true, messages: chatStore.get(String(req.params.id)) || [] });
});

router.post('/:id/waiting-room/chat', verifyToken, async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) return res.status(400).json({ error: 'Message required' });
    const exam = await Exam.findById(req.params.id).lean();
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    const state = computeExamState(exam, new Date(), 0);

    const userDoc = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const joinRec = ((userDoc && userDoc.waitingRoomJoins) || []).find(j => String(j.examId) === String(req.params.id));
    if (!joinRec) return res.status(403).json({ error: 'Join the waiting room first' });

    const minsSinceJoin = (Date.now() - new Date(joinRec.joinedAt).getTime()) / 60000;
    if (minsSinceJoin > state.chatMins) {
      return res.status(403).json({ error: 'Chat window has closed for anti-cheat', chatClosed: true });
    }

    const msg = { name: (userDoc && userDoc.name ? userDoc.name.split(' ')[0] : 'Student'), text: text.trim().slice(0, 300), at: new Date(), isAdmin: false };
    pushChat(req.params.id, msg);
    try { const { getIO } = require('../config/socket'); getIO().to(`waiting-${req.params.id}`).emit('waiting-chat-message', msg); } catch (e) {}
    res.json({ success: true, message: msg, minutesLeftInChat: Math.max(0, Math.round(state.chatMins - minsSinceJoin)) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// F55 — Per-exam T&C consent (DB persisted, version-tracked)
// ════════════════════════════════════════════════════════════
router.post('/:id/accept-terms', verifyToken, async (req, res) => {
  try {
    const studentObjId = new mongoose.Types.ObjectId(req.user.id);
    const examObjId = new mongoose.Types.ObjectId(req.params.id);
    const entry = { examId: examObjId, version: TERMS_VERSION, acceptedAt: new Date() };
    await User.collection.updateOne({ _id: studentObjId }, { $pull: { examConsents: { examId: examObjId } } });
    await User.collection.updateOne({ _id: studentObjId }, {
      $push: { examConsents: entry },
      $set: { termsAccepted: true, termsAcceptedAt: new Date(), termsVersion: TERMS_VERSION }
    });
    res.json({ success: true, accepted: true, version: TERMS_VERSION, acceptedAt: entry.acceptedAt });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id/consent-status', verifyToken, async (req, res) => {
  try {
    const userDoc = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const entry = ((userDoc && userDoc.examConsents) || []).find(c => String(c.examId) === String(req.params.id));
    res.json({
      success: true,
      accepted: !!entry && entry.version === TERMS_VERSION,
      currentVersion: TERMS_VERSION,
      acceptedVersion: entry ? entry.version : null,
      acceptedAt: entry ? entry.acceptedAt : null
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── F52 §7 — Per-exam reminder toggle (server persisted) ──
router.post('/:id/reminder', verifyToken, async (req, res) => {
  try {
    const { enabled } = req.body;
    const studentObjId = new mongoose.Types.ObjectId(req.user.id);
    const examObjId = new mongoose.Types.ObjectId(req.params.id);
    await User.collection.updateOne({ _id: studentObjId }, { $pull: { examReminders: { examId: examObjId } } });
    await User.collection.updateOne({ _id: studentObjId }, { $push: { examReminders: { examId: examObjId, enabled: !!enabled, updatedAt: new Date() } } });
    res.json({ success: true, examId: req.params.id, enabled: !!enabled });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── F53 §4.1.4 — Admin broadcast messages visible in waiting room (best-effort; ──
// ── gracefully no-ops if an Announcement model isn't present in this codebase) ──
router.get('/:id/broadcasts', verifyToken, async (req, res) => {
  try {
    let items = [];
    try {
      const Announcement = require('../models/Announcement');
      items = await Announcement.find({ $or: [{ examId: req.params.id }, { examId: null }, { examId: { $exists: false } }] })
        .sort({ createdAt: -1 }).limit(5).lean();
    } catch (e) { /* model not present — non-fatal */ }
    res.json({ success: true, broadcasts: items });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ════════════════════════════════════════════════════════════
// F58 — GET /api/exams/:examId/questions
// Serves the full question set (medium-aware, image-aware, subject-
// tagged) to a student for the Exam Attempt screen. SECURITY: only
// callable when the student has an ACTIVE attempt on this exam — the
// correct-answer key and all admin/internal fields are stripped from
// the response so answers can never leak to the client.
// ════════════════════════════════════════════════════════════
router.get('/:examId/questions', verifyToken, async (req, res) => {
  try {
    const examObjId = new mongoose.Types.ObjectId(req.params.examId);
    const studentObjId = new mongoose.Types.ObjectId(req.user.id);

    const activeAttempt = await Attempt.findOne({
      examId: examObjId,
      studentId: studentObjId,
      status: 'active'
    }).select('_id').lean();

    if (!activeAttempt) {
      return res.status(403).json({
        success: false,
        message: 'No active attempt found for this exam. Start the attempt first.',
        code: 'NO_ACTIVE_ATTEMPT'
      });
    }

    const exam = await Exam.findById(examObjId)
      .populate({
        path: 'questions',
        select: '-correct -versionHistory -reports -approvalStatus -approvedBy -approvedAt -rejectionReason -similarityScore -similarQuestionId -createdBy -isDeleted -deletedAt -deletedBy -deleteReason -archivedAt -archivedBy -isArchived'
      })
      .lean();

    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });

    return res.status(200).json({
      success: true,
      questions: exam.questions || [],
      total: (exam.questions || []).length,
      sections: exam.sections || [],
      markingScheme: exam.markingScheme || { correct: 4, incorrect: -1, unattempted: 0, msqMode: 'ALL_OR_NOTHING' },
      duration: exam.duration,
      title: exam.title,
      status: exam.status,
      attemptId: activeAttempt._id
    });
  } catch (err) {
    console.error('exam questions fetch error:', err);
    return res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

module.exports = router;
FILEEOF2
echo "examFlow.js updated ✅"

# ---- 3) Frontend: frontend/app/my-exams/page.tsx ----
cat > ~/workspace/frontend/app/my-exams/page.tsx << 'FILEEOF3'
'use client'
import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function fmtTime(d: any) {
  if (!d) return ''
  const dt = new Date(d)
  return dt.toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
}
function dayLabel(d: any) {
  if (!d) return ''
  const dt = new Date(d); const now = new Date()
  const diffDays = Math.floor((new Date(dt.toDateString()).getTime() - new Date(now.toDateString()).getTime()) / 86400000)
  if (diffDays === 0) return 'Today'
  if (diffDays === 1) return 'Tomorrow'
  if (diffDays < 0) return 'Past'
  return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })
}

function MyExamsContent() {
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const toast = shell?.toast
  const lang = shell?.lang || 'en'
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  // F52 v4 fix #1 — theme-reactive colors (were static C.* before, which never
  // switches with light/dark and caused invisible text in light mode)
  const text = theme.text
  const sub = theme.sub
  const primary = theme.primary
  const border = theme.border
  const card = theme.isDark ? C.card : C.cardL
  const inputBg = theme.isDark ? 'rgba(255,255,255,0.06)' : '#FFFFFF'
  const chipBg = theme.chipBg || (theme.isDark ? 'rgba(255,255,255,0.06)' : 'rgba(37,99,235,0.06)')

  const [exams, setExams] = useState<any[]>([])
  const [synced, setSynced] = useState<{ batches: string[]; series: string[] }>({ batches: [], series: [] })
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [subjectFilter, setSubjectFilter] = useState('all')
  const [batchFilter, setBatchFilter] = useState('all') // holds a batch name OR a series name
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [previewExam, setPreviewExam] = useState<any>(null)
  const [pwModal, setPwModal] = useState<any>(null)
  const [pwInput, setPwInput] = useState('')
  const [pwErr, setPwErr] = useState('')
  const [now, setNow] = useState(Date.now())
  const [joining, setJoining] = useState<string | null>(null)

  useEffect(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('pr_myexams_filters') || '{}')
      if (saved.statusFilter) setStatusFilter(saved.statusFilter)
      if (saved.subjectFilter) setSubjectFilter(saved.subjectFilter)
      if (saved.batchFilter) setBatchFilter(saved.batchFilter)
      if (saved.categoryFilter) setCategoryFilter(saved.categoryFilter)
      if (saved.search) setSearch(saved.search)
    } catch (e) {}
  }, [])
  useEffect(() => {
    localStorage.setItem('pr_myexams_filters', JSON.stringify({ statusFilter, subjectFilter, batchFilter, categoryFilter, search }))
  }, [statusFilter, subjectFilter, batchFilter, categoryFilter, search])

  const load = () => {
    if (!token) return
    fetch(`${API}/api/exams/my-exams`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        if (d?.success) {
          setExams(d.exams || [])
          setSynced({ batches: d.syncedBatches || [], series: d.syncedSeries || [] })
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }
  useEffect(() => { load(); const iv = setInterval(load, 30000); return () => clearInterval(iv) }, [token])
  useEffect(() => { const iv = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(iv) }, [])

  const filtered = useMemo(() => {
    return exams.filter(e => {
      if (search && !e.title?.toLowerCase().includes(search.toLowerCase())) return false
      if (statusFilter === 'upcoming' && e.derivedStatus !== 'scheduled') return false
      if (statusFilter === 'live' && e.derivedStatus !== 'live') return false
      if (statusFilter === 'completed' && !(e.derivedStatus === 'ended' || (e.activeAttemptId === null && e.performance))) return false
      if (subjectFilter !== 'all' && e.subject !== subjectFilter) return false
      if (categoryFilter !== 'all' && e.category !== categoryFilter) return false
      // F52 v4 fix #2 — batchFilter now matches EITHER a batch name/multiBatch OR a series name
      if (batchFilter !== 'all') {
        const matchesBatch = e.batch === batchFilter || (e.multiBatch || []).includes(batchFilter)
        const matchesSeries = e.seriesName === batchFilter
        if (!matchesBatch && !matchesSeries) return false
      }
      return true
    })
  }, [exams, search, statusFilter, subjectFilter, batchFilter, categoryFilter])

  const stats = useMemo(() => ({
    total: exams.length,
    upcoming: exams.filter(e => e.derivedStatus === 'scheduled').length,
    live: exams.filter(e => e.derivedStatus === 'live').length,
    completed: exams.filter(e => e.derivedStatus === 'ended').length,
    attempted: exams.filter(e => e.performance).length,
    bestScore: Math.max(0, ...exams.filter(e => e.performance).map(e => e.performance.bestScore || 0))
  }), [exams])

  const timeline = useMemo(() => {
    return exams
      .filter(e => e.derivedStatus === 'scheduled' && e.schedule?.startTime)
      .sort((a, b) => new Date(a.schedule.startTime).getTime() - new Date(b.schedule.startTime).getTime())
      .slice(0, 8)
  }, [exams])

  async function doJoinWaitingRoom(e: any) {
    setJoining(e._id)
    try {
      await fetch(`${API}/api/exams/${e._id}/join-waiting-room`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      router.push(`/exam/${e._id}/waiting`)
    } catch (err) {
      toast?.(t('Could not join waiting room, try again', 'Waiting room join nahi ho paya, dobara try karo'), 'e')
    } finally { setJoining(null) }
  }

  const go = (e: any) => {
    if (e.passwordProtected && !e.activeAttemptId) { setPwModal(e); setPwErr(''); setPwInput(''); return }
    if (e.activeAttemptId) { router.push(`/exam/${e._id}/attempt`); return }

    if (e.derivedStatus === 'scheduled' && e.waitingRoomWindowOpen) { doJoinWaitingRoom(e); return }
    if (e.derivedStatus === 'scheduled') {
      toast?.(t('Waiting room will open ' + e.waitMins + ' minutes before start', 'Waiting room shuru se ' + e.waitMins + ' minute pehle khulega'), 'w')
      return
    }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') {
      toast?.(t('Join window has closed. Available again: ' + fmtTime(e.nextAvailableAttemptTime), 'Join window band ho gayi. Dobara available: ' + fmtTime(e.nextAvailableAttemptTime)), 'e')
      return
    }
    if (e.joinState === 'locked') { toast?.(t('No attempts left for this exam', 'Is exam ke liye attempts khatam ho gaye'), 'e'); return }

    router.push(`/exam/${e._id}/instructions`)
  }

  const submitPassword = () => {
    if (!pwInput.trim()) { setPwErr(t('Enter password', 'Password daalo')); return }
    // F52 security fix — verified server-side now; plaintext password never sent to client
    fetch(`${API}/api/exams/${pwModal._id}/verify-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ password: pwInput })
    })
      .then(r => r.json())
      .then(d => {
        if (!d?.valid) { setPwErr(t('Incorrect password', 'Galat password')); return }
        const e = pwModal; setPwModal(null)
        if (e.derivedStatus === 'scheduled' && e.waitingRoomWindowOpen) { doJoinWaitingRoom(e); return }
        router.push(`/exam/${e._id}/instructions`)
      })
      .catch(() => setPwErr(t('Error verifying password', 'Password verify karne me error')))
  }

  const toggleReminder = (e: any) => {
    const next = !e.reminderEnabled
    setExams(prev => prev.map(x => x._id === e._id ? { ...x, reminderEnabled: next } : x))
    fetch(`${API}/api/exams/${e._id}/reminder`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ enabled: next }) }).catch(() => {})
  }

  function startBtn(e: any) {
    if (e.activeAttemptId) return { label: t('Continue Attempt', 'Jaari Rakhein'), col: C.gold, icon: '▶️', disabled: false }
    if (e.passwordProtected && !e.activeAttemptId) return { label: t('Password Required', 'Password Chahiye'), col: C.purple, icon: '🔒', disabled: false }
    if (e.derivedStatus === 'scheduled' && e.waitingRoomWindowOpen) {
      return e.hasJoinedWaitingRoom
        ? { label: t('Resume Waiting Room', 'Waiting Room Resume Karo'), col: primary, icon: '🔁', disabled: false }
        : { label: t('Join Waiting Room', 'Waiting Room Join Karo'), col: primary, icon: '🚪', disabled: false }
    }
    if (e.derivedStatus === 'scheduled') return { label: t('Available Later', 'Baad Me Available'), col: '#888', icon: '⏳', disabled: true }
    if (e.derivedStatus === 'live' && e.joinState === 'join_open') return { label: t('Start Now', 'Abhi Shuru Karo'), col: C.success, icon: '🔴', disabled: false }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') return { label: t('Join Closed', 'Join Band'), col: '#888', icon: '🚫', disabled: true }
    if (e.joinState === 'available_again') return { label: t('Start Exam', 'Exam Shuru Karo'), col: C.success, icon: '▶️', disabled: false }
    if (e.joinState === 'locked') return { label: t('Locked', 'Locked'), col: '#888', icon: '🔒', disabled: true }
    return { label: t('View', 'Dekho'), col: C.gold, icon: '👁️', disabled: false }
  }

  const subjects = useMemo(() => Array.from(new Set(exams.map(e => e.subject).filter(Boolean))), [exams])
  // F52 v4 fix #2 — merged Batches + Test Series into one synced list for the dropdown
  const batchesAndSeries = useMemo(() => Array.from(new Set([
    ...synced.batches,
    ...synced.series,
    ...exams.map(e => e.batch).filter(Boolean),
    ...exams.map(e => e.seriesName).filter(Boolean)
  ])), [exams, synced])
  const categories = useMemo(() => Array.from(new Set(exams.map(e => e.category).filter(Boolean))), [exams])

  const selectStyle: any = { padding: 10, borderRadius: 10, border: `1px solid ${border}`, background: inputBg, color: text }

  return (
    <div style={{ padding: 16, maxWidth: 1100, margin: '0 auto' }}>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, marginBottom: 14 }}>
        {[
          ['📚', stats.total, t('Total', 'Total')],
          ['⏳', stats.upcoming, t('Upcoming', 'Upcoming')],
          ['🔴', stats.live, t('Live', 'Live')],
          ['✅', stats.completed, t('Completed', 'Completed')],
          ['🎯', stats.attempted, t('Attempted', 'Attempted')],
          ['🏆', stats.bestScore, t('Best Score', 'Best Score')]
        ].map(([icon, val, label]: any, i) => (
          <div key={i} style={{ flex: '1 1 100px', background: card, border: `1px solid ${border}`, borderRadius: 12, padding: '10px 12px', textAlign: 'center' }}>
            <div style={{ fontSize: 18 }}>{icon}</div>
            <div style={{ fontSize: 20, fontWeight: 800, color: text }}>{val}</div>
            <div style={{ fontSize: 11, color: sub }}>{label}</div>
          </div>
        ))}
      </div>

      {timeline.length > 0 && (
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 8, marginBottom: 14 }}>
          {timeline.map(e => (
            <div key={e._id} onClick={() => setPreviewExam(e)} style={{ cursor: 'pointer', minWidth: 130, background: card, border: `1px solid ${e.derivedStatus === 'live' ? C.success : border}`, borderRadius: 10, padding: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 700, color: C.gold }}>{dayLabel(e.schedule?.startTime)}</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.title}</div>
              <div style={{ fontSize: 10, color: sub }}>{fmtTime(e.schedule?.startTime)}</div>
            </div>
          ))}
        </div>
      )}

      <div style={{ marginBottom: 14 }}>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('Search exam title...', 'Exam title search karo...')}
          style={{ width: '100%', padding: '10px 12px', borderRadius: 10, border: `1px solid ${border}`, background: inputBg, color: text, marginBottom: 8, boxSizing: 'border-box' }} />
        {/* F52 §12.1.3 — horizontal scroll strip on mobile; wraps naturally on wide desktop screens */}
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4, WebkitOverflowScrolling: 'touch' }}>
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All', 'All')}</option>
            <option value="upcoming">{t('Upcoming', 'Upcoming')}</option>
            <option value="live">{t('Live', 'Live')}</option>
            <option value="completed">{t('Completed', 'Completed')}</option>
          </select>
          <select value={subjectFilter} onChange={e => setSubjectFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All Subjects', 'All Subjects')}</option>
            {subjects.map(s => <option key={s} value={s}>{s}</option>)}
          </select>
          {/* F52 v4 fix #2 — renamed + merged Batches/Test Series dropdown */}
          <select value={batchFilter} onChange={e => setBatchFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All Batches/Test Series', 'All Batches/Test Series')}</option>
            {batchesAndSeries.map(b => <option key={b} value={b}>{b}</option>)}
          </select>
          <select value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All Categories', 'All Categories')}</option>
            {categories.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: sub }}>{t('Loading exams...', 'Exams load ho rahe hai...')}</div>
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, color: sub }}>
          <div style={{ fontSize: 40 }}>📭</div>
          <div style={{ marginTop: 8 }}>{exams.length === 0 ? t('No exams scheduled yet', 'Abhi koi exam schedule nahi hai') : t('No exams match your filters', 'Filters se koi exam match nahi hua')}</div>
          {exams.length > 0 && <button onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setBatchFilter('all'); setCategoryFilter('all') }} style={{ marginTop: 10, padding: '8px 16px', borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer' }}>{t('Reset Filters', 'Filters Reset Karo')}</button>}
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 12 }}>
          {filtered.map(e => {
            const btn = startBtn(e)
            const minsToStart = e.schedule?.startTime ? Math.round((new Date(e.schedule.startTime).getTime() - now) / 60000) : null
            return (
              <div key={e._id} style={{ background: card, border: `1px solid ${e.derivedStatus === 'live' ? C.success : border}`, borderRadius: 14, padding: 14, position: 'relative' }}>
                {e.derivedStatus === 'live' && e.joinState === 'join_open' && (
                  <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 10, fontWeight: 800, color: '#fff', background: C.success, padding: '3px 8px', borderRadius: 20 }}>🔴 LIVE</span>
                )}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ fontWeight: 800, fontSize: 15, color: text, maxWidth: '80%' }}>{e.title}</div>
                  <button onClick={() => setPreviewExam(e)} title={t('Quick preview', 'Quick preview')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontSize: 14 }}>ℹ️</button>
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, margin: '8px 0' }}>
                  <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.subject}</span>
                  <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.duration} min</span>
                  <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.totalMarks} marks</span>
                  {e.category && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.category}</span>}
                  {e.assignmentType && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.assignmentType === 'mini_test' ? t('Mini Test', 'Mini Test') : e.assignmentType === 'series' ? t('Series', 'Series') : e.assignmentType === 'batch' ? t('Batch', 'Batch') : t('Individual', 'Individual')}</span>}
                  {e.batch && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{e.batch}</span>}
                  {e.seriesName && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>📚 {e.seriesName}</span>}
                </div>
                <div style={{ fontSize: 11, color: sub, marginBottom: 8 }}>{fmtTime(e.schedule?.startTime)}</div>

                {e.derivedStatus === 'scheduled' && !e.waitingRoomWindowOpen && minsToStart != null && minsToStart > 0 && (
                  <div style={{ fontSize: 12, color: C.gold, marginBottom: 8 }}>⏱ {t('Starts in', 'Shuru hoga')} {minsToStart > 60 ? Math.floor(minsToStart / 60) + 'h ' + (minsToStart % 60) + 'm' : minsToStart + 'm'}</div>
                )}
                {e.joinState === 'join_closed' && (
                  <div style={{ fontSize: 11, color: C.danger, marginBottom: 8 }}>⚠️ {t('Join closed. Available again:', 'Join band. Dobara available:')} {fmtTime(e.nextAvailableAttemptTime)}</div>
                )}

                {e.performance && (
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{t('Best', 'Best')}: {e.performance.bestScore}</span>
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{t('Avg', 'Avg')}: {e.performance.avgScore}</span>
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{t('Attempts', 'Attempts')}: {e.performance.attemptCount}</span>
                    {e.performance.lastAttemptAt && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{t('Last', 'Last')}: {fmtTime(e.performance.lastAttemptAt)}</span>}
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: e.performance.rankTrend === 'up' ? C.success : e.performance.rankTrend === 'down' ? C.danger : sub }}>
                      {e.performance.rankTrend === 'up' ? '📈' : e.performance.rankTrend === 'down' ? '📉' : '➖'} {t('Rank', 'Rank')} {e.performance.rankTrend}
                    </span>
                  </div>
                )}

                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <button disabled={btn.disabled || joining === e._id} onClick={() => go(e)} style={{ flex: 1, padding: '10px 14px', borderRadius: 10, border: 'none', background: btn.disabled ? '#444' : btn.col, color: '#fff', fontWeight: 700, cursor: btn.disabled ? 'not-allowed' : 'pointer', opacity: joining === e._id ? 0.6 : 1 }}>
                    {btn.icon} {joining === e._id ? t('Joining...', 'Join ho raha hai...') : btn.label}
                  </button>
                  {e.derivedStatus === 'scheduled' && (
                    <button onClick={() => toggleReminder(e)} title={t('Reminder', 'Reminder')} style={{ padding: '10px 12px', borderRadius: 10, border: `1px solid ${border}`, background: e.reminderEnabled ? C.gold : 'transparent', color: e.reminderEnabled ? '#000' : text, cursor: 'pointer' }}>
                      {e.reminderEnabled ? '🔔' : '🔕'}
                    </button>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {previewExam && (
        <div onClick={() => setPreviewExam(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, border: `1px solid ${border}`, borderRadius: 16, padding: 20, maxWidth: 340, width: '90%' }}>
            <div style={{ fontWeight: 800, fontSize: 16, color: text, marginBottom: 8 }}>{previewExam.title}</div>
            <div style={{ fontSize: 13, color: sub, lineHeight: 1.8 }}>
              <div>⏱ {t('Duration', 'Duration')}: {previewExam.duration} min</div>
              <div>🎯 {t('Marks', 'Marks')}: {previewExam.totalMarks}</div>
              <div>📚 {t('Subject', 'Subject')}: {previewExam.subject}</div>
              <div>🏷 {t('Category', 'Category')}: {previewExam.category || '-'}</div>
              {previewExam.seriesName && <div>📖 {t('Test Series', 'Test Series')}: {previewExam.seriesName}</div>}
              <div>📅 {fmtTime(previewExam.schedule?.startTime)}</div>
              <div>📍 {t('Status', 'Status')}: {previewExam.derivedStatus} / {previewExam.joinState}</div>
            </div>
            <button onClick={() => { const e = previewExam; setPreviewExam(null); go(e) }} style={{ marginTop: 14, width: '100%', padding: 10, borderRadius: 10, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>{t('Open', 'Kholo')}</button>
          </div>
        </div>
      )}

      {pwModal && (
        <div onClick={() => setPwModal(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, border: `1px solid ${border}`, borderRadius: 16, padding: 20, maxWidth: 320, width: '90%' }}>
            <div style={{ fontWeight: 800, color: text, marginBottom: 10 }}>🔒 {t('Enter Exam Password', 'Exam Password Daalo')}</div>
            <input type="password" value={pwInput} onChange={e => setPwInput(e.target.value)} placeholder={t('Password', 'Password')}
              style={{ width: '100%', padding: 10, borderRadius: 8, border: `1px solid ${border}`, background: inputBg, color: text, marginBottom: 8 }} />
            {pwErr && <div style={{ color: C.danger, fontSize: 12, marginBottom: 8 }}>{pwErr}</div>}
            <button onClick={submitPassword} style={{ width: '100%', padding: 10, borderRadius: 8, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>{t('Submit', 'Submit')}</button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function MyExamsPage() {
  return <StudentShell pageKey="my-exams"><MyExamsContent /></StudentShell>
}
FILEEOF3
echo "my-exams/page.tsx updated ✅"

echo ""
echo "=== DONE — Now: pkill -f node 2>/dev/null; cd ~/workspace && node src/index.js ==="
