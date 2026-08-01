#!/bin/bash
set -e
echo "=== ProveRank F53-F57 MEGA FIX — Waiting Room, Instructions, T&C, Webcam AI, Fullscreen, Dead Code Cleanup ==="

# ---- 1) Backend: src/routes/exam.js ----
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
    // F54 §2.1.5 — real subject-wise question count breakdown for Instructions screen
    try {
      const Question = require('../models/Question');
      const qDocs = await Question.find({ _id: { $in: exam.questions || [] } }).select('subject').lean();
      const bySubject = {};
      qDocs.forEach(q => { const s = q.subject || 'Other'; bySubject[s] = (bySubject[s] || 0) + 1; });
      examOut.subjectBreakdown = bySubject;
      examOut.totalQuestionsCount = qDocs.length;
    } catch (e) { examOut.subjectBreakdown = {}; examOut.totalQuestionsCount = (exam.questions || []).length; }
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
    const reminderOffsetMap = {};
    ((enrollment.userDoc && enrollment.userDoc.examReminders) || []).forEach(r => { reminderMap[String(r.examId)] = r.enabled; reminderOffsetMap[String(r.examId)] = r.offsetMinutes; });

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
        type: e.type || 'NEET',
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
        reminderOffsetMinutes: reminderOffsetMap[eid] !== undefined ? reminderOffsetMap[eid] : 60,
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
    const { enabled, offsetMinutes } = req.body;
    const studentObjId = new mongoose.Types.ObjectId(req.user.id);
    const examObjId = new mongoose.Types.ObjectId(req.params.id);
    const safeOffset = [15, 30, 60, 180, 1440].includes(Number(offsetMinutes)) ? Number(offsetMinutes) : 60;
    await User.collection.updateOne({ _id: studentObjId }, { $pull: { examReminders: { examId: examObjId } } });
    await User.collection.updateOne({ _id: studentObjId }, { $push: { examReminders: { examId: examObjId, enabled: !!enabled, offsetMinutes: safeOffset, updatedAt: new Date() } } });
    res.json({ success: true, examId: req.params.id, enabled: !!enabled, offsetMinutes: safeOffset });
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

# ---- 3) Backend: src/routes/exam_patch.js (dead legacy routes removed) ----
cat > ~/workspace/src/routes/exam_patch.js << 'FILEEOF3'
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
FILEEOF3
echo "exam_patch.js cleaned ✅"

# ---- 4) Frontend: My Exams page ----
cat > ~/workspace/frontend/app/my-exams/page.tsx << 'FILEEOF4'
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
    fetch(`${API}/api/exams/${e._id}/reminder`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ enabled: next, offsetMinutes: e.reminderOffsetMinutes || 60 }) }).catch(() => {})
  }

  // F52 §7.2.3 — custom "notify X minutes before" option
  const setReminderOffset = (e: any, minutes: number) => {
    setExams(prev => prev.map(x => x._id === e._id ? { ...x, reminderOffsetMinutes: minutes } : x))
    fetch(`${API}/api/exams/${e._id}/reminder`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ enabled: true, offsetMinutes: minutes }) }).catch(() => {})
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

      {(synced.batches.length > 0 || synced.series.length > 0) && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: sub, background: chipBg, border: `1px solid ${border}`, borderRadius: 10, padding: '8px 12px', marginBottom: 14 }}>
          <span style={{ color: C.success }}>✅</span>
          <span>
            {t('Synced', 'Synced')}: {synced.batches.length > 0 && `${synced.batches.length} ${t('Batch(es)', 'Batch(es)')}`}
            {synced.batches.length > 0 && synced.series.length > 0 && ' · '}
            {synced.series.length > 0 && `${synced.series.length} ${t('Test Series', 'Test Series')}`}
          </span>
        </div>
      )}

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
        {(search || statusFilter !== 'all' || subjectFilter !== 'all' || batchFilter !== 'all' || categoryFilter !== 'all') && (
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 8 }}>
            {search && <span onClick={() => setSearch('')} style={{ cursor: 'pointer', fontSize: 11, background: chipBg, border: `1px solid ${border}`, padding: '3px 8px', borderRadius: 20, color: text }}>"{search}" ✕</span>}
            {statusFilter !== 'all' && <span onClick={() => setStatusFilter('all')} style={{ cursor: 'pointer', fontSize: 11, background: chipBg, border: `1px solid ${border}`, padding: '3px 8px', borderRadius: 20, color: text }}>{statusFilter} ✕</span>}
            {subjectFilter !== 'all' && <span onClick={() => setSubjectFilter('all')} style={{ cursor: 'pointer', fontSize: 11, background: chipBg, border: `1px solid ${border}`, padding: '3px 8px', borderRadius: 20, color: text }}>{subjectFilter} ✕</span>}
            {batchFilter !== 'all' && <span onClick={() => setBatchFilter('all')} style={{ cursor: 'pointer', fontSize: 11, background: chipBg, border: `1px solid ${border}`, padding: '3px 8px', borderRadius: 20, color: text }}>{batchFilter} ✕</span>}
            {categoryFilter !== 'all' && <span onClick={() => setCategoryFilter('all')} style={{ cursor: 'pointer', fontSize: 11, background: chipBg, border: `1px solid ${border}`, padding: '3px 8px', borderRadius: 20, color: text }}>{categoryFilter} ✕</span>}
            <span onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setBatchFilter('all'); setCategoryFilter('all') }} style={{ cursor: 'pointer', fontSize: 11, color: C.danger, padding: '3px 4px' }}>{t('Clear all', 'Sab clear karo')}</span>
          </div>
        )}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: sub }}>{t('Loading exams...', 'Exams load ho rahe hai...')}</div>
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, color: sub }}>
          <svg width="72" height="72" viewBox="0 0 24 24" fill="none" style={{ margin: '0 auto', opacity: 0.5 }}>
            <path d="M3 8l9 6 9-6M4 5h16a1 1 0 011 1v12a1 1 0 01-1 1H4a1 1 0 01-1-1V6a1 1 0 011-1z" stroke={sub} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          <div style={{ marginTop: 8 }}>{exams.length === 0 ? t('No exams scheduled yet', 'Abhi koi exam schedule nahi hai') : t('No exams match your filters', 'Filters se koi exam match nahi hua')}</div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 10 }}>
            {exams.length > 0 && <button onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setBatchFilter('all'); setCategoryFilter('all') }} style={{ padding: '8px 16px', borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer' }}>{t('Reset Filters', 'Filters Reset Karo')}</button>}
            <button onClick={() => { setLoading(true); load() }} style={{ padding: '8px 16px', borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer' }}>{t('↻ Refresh', '↻ Refresh')}</button>
          </div>
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
                  {e.type && <span style={{ fontSize: 11, background: primary, padding: '3px 8px', borderRadius: 20, color: '#fff', fontWeight: 700 }}>{e.type}</span>}
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
                  {e.derivedStatus === 'scheduled' && e.reminderEnabled && (
                    <select value={e.reminderOffsetMinutes || 60} onChange={ev => setReminderOffset(e, Number(ev.target.value))} title={t('Notify me before', 'Kitni der pehle batao')}
                      style={{ padding: '10px 8px', borderRadius: 10, border: `1px solid ${border}`, background: inputBg, color: text, fontSize: 12 }}>
                      <option value={15}>{t('15 min before', '15 min pehle')}</option>
                      <option value={30}>{t('30 min before', '30 min pehle')}</option>
                      <option value={60}>{t('1 hr before', '1 hr pehle')}</option>
                      <option value={180}>{t('3 hr before', '3 hr pehle')}</option>
                      <option value={1440}>{t('1 day before', '1 din pehle')}</option>
                    </select>
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
FILEEOF4
echo "my-exams/page.tsx updated ✅"

# ---- 5) Frontend: Waiting Room page (F53) ----
mkdir -p ~/workspace/frontend/app/exam/\[examId\]/waiting-room
cat > ~/workspace/frontend/app/exam/\[examId\]/waiting-room/page.tsx << 'FILEEOF5'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const TIPS = [
  { text: 'Keep your ID card ready for admit card verification.', severity: 'info' },
  { text: 'Ensure stable internet connection before exam starts.', severity: 'high' },
  { text: 'Camera must stay on throughout the exam — compulsory.', severity: 'high' },
  { text: 'Do not switch tabs during the exam — 3 warnings = auto submit.', severity: 'critical' },
  { text: 'Attempt easy questions first, mark tough ones for review.', severity: 'info' },
  { text: 'Sit in a well-lit, quiet room for best proctoring accuracy.', severity: 'medium' },
]
const SEV_COLOR: any = { info: '#5b9bff', medium: '#f2b134', high: '#ff9f43', critical: '#ff5555' }

function fmtSecs(s: number) {
  const m = Math.floor(s / 60), sec = s % 60
  return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
}

function WaitingRoomContent() {
  const { examId } = useParams() as any
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const lang = shell?.lang || 'en'
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const text = theme.text, sub = theme.sub, border = theme.border
  const card = theme.isDark ? C.card : C.cardL
  const inputBg = theme.isDark ? 'rgba(255,255,255,0.06)' : '#FFFFFF'

  const [info, setInfo] = useState<any>(null)
  const [entered, setEntered] = useState(false)
  const [secsLeft, setSecsLeft] = useState<number | null>(null)
  const [liveCount, setLiveCount] = useState(0)
  const [tipIdx, setTipIdx] = useState(0)
  const [musicOn, setMusicOn] = useState(false)
  const [chatMsgs, setChatMsgs] = useState<any[]>([])
  const [chatInput, setChatInput] = useState('')
  const [chatOpen, setChatOpen] = useState(true)
  const [chatMinsLeft, setChatMinsLeft] = useState<number | null>(null)
  const [chatReminderShown, setChatReminderShown] = useState(false)
  const [broadcasts, setBroadcasts] = useState<any[]>([])
  const [activityLog, setActivityLog] = useState<string[]>([])
  const socketRef = useRef<any>(null)
  const transitionedRef = useRef(false)
  const audioCtxRef = useRef<any>(null)
  const audioNodesRef = useRef<any>(null)

  const toggleMusic = () => {
    if (musicOn) {
      try { audioNodesRef.current?.osc1?.stop(); audioNodesRef.current?.osc2?.stop(); audioCtxRef.current?.close() } catch (e) {}
      audioCtxRef.current = null; audioNodesRef.current = null
      setMusicOn(false)
      return
    }
    try {
      const AC = (window as any).AudioContext || (window as any).webkitAudioContext
      const ctx = new AC()
      const gain = ctx.createGain(); gain.gain.value = 0.035; gain.connect(ctx.destination)
      const osc1 = ctx.createOscillator(); osc1.type = 'sine'; osc1.frequency.value = 220
      const osc2 = ctx.createOscillator(); osc2.type = 'sine'; osc2.frequency.value = 330
      osc1.connect(gain); osc2.connect(gain)
      osc1.start(); osc2.start()
      audioCtxRef.current = ctx; audioNodesRef.current = { osc1, osc2 }
      setMusicOn(true)
    } catch (e) { /* Web Audio not available — no-op */ }
  }
  useEffect(() => () => { try { audioNodesRef.current?.osc1?.stop(); audioNodesRef.current?.osc2?.stop(); audioCtxRef.current?.close() } catch (e) {} }, [])

  const logActivity = (msg: string) => setActivityLog(l => [`${new Date().toLocaleTimeString()} — ${msg}`, ...l].slice(0, 8))

  const loadInfo = () => {
    if (!token) return
    fetch(`${API}/api/exams/${examId}/waiting-info`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        if (!d?.success) return
        setInfo(d)
        setLiveCount(d.liveCount || 0)
        if (d.activeAttemptId) { router.replace(`/exam/${examId}/attempt`); return }
        if (d.hasJoinedWaitingRoom) setEntered(true)
        if (d.exam?.schedule?.startTime) {
          const secs = Math.round((new Date(d.exam.schedule.startTime).getTime() - Date.now()) / 1000)
          setSecsLeft(secs)
        }
      })
      .catch(() => {})
  }
  const loadBroadcasts = () => {
    if (!token) return
    fetch(`${API}/api/exams/${examId}/broadcasts`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => { if (d?.success) setBroadcasts(d.broadcasts || []) })
      .catch(() => {})
  }
  useEffect(() => { loadInfo(); loadBroadcasts() }, [examId, token])

  const joinNow = () => {
    fetch(`${API}/api/exams/${examId}/join-waiting-room`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => { if (d?.success) { setEntered(true); logActivity(t('Joined waiting room', 'Waiting room join kiya')) } })
      .catch(() => {})
  }

  useEffect(() => {
    if (!entered || secsLeft == null) return
    const iv = setInterval(() => {
      setSecsLeft(s => { if (s == null) return s; if (s <= 1) { clearInterval(iv); return 0 }; return s - 1 })
    }, 1000)
    return () => clearInterval(iv)
  }, [entered, secsLeft != null])

  useEffect(() => {
    if (!entered || secsLeft == null || !info) return
    const bufferSecs = (info.config?.autoCloseBufferMinutes ?? 8) * 60
    if (secsLeft <= bufferSecs && !transitionedRef.current) {
      transitionedRef.current = true
      logActivity(t('Auto-moving to Instructions screen', 'Instructions screen par ja rahe hai'))
      setTimeout(() => router.push(`/exam/${examId}/instructions`), 1200)
    }
  }, [secsLeft, entered, info])

  useEffect(() => {
    if (!entered) return
    let socket: any
    try {
      const { io } = require('socket.io-client')
      socket = io(API)
      socket.emit('join-waiting-room', examId)
      socket.on('waiting-room-count', (d: any) => { if (String(d.examId) === String(examId)) setLiveCount(d.count) })
      socket.on('waiting-chat-message', (msg: any) => setChatMsgs(m => [...m, msg]))
      socketRef.current = socket
    } catch (e) {}
    const poll = setInterval(() => { loadInfo(); loadBroadcasts() }, 15000)
    return () => { clearInterval(poll); if (socket) { socket.emit('leave-waiting-room', examId); socket.disconnect() } }
  }, [entered, examId])

  useEffect(() => {
    if (!entered) return
    fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json()).then(d => { if (d?.success) setChatMsgs(d.messages || []) }).catch(() => {})
  }, [entered])

  useEffect(() => {
    if (!entered || !info?.joinedAt) return
    const chatMins = info.config?.chatMinutes ?? 10
    const iv = setInterval(() => {
      const minsSince = (Date.now() - new Date(info.joinedAt).getTime()) / 60000
      const left = Math.max(0, chatMins - minsSince)
      setChatMinsLeft(left)
      if (left <= 0 && chatOpen) { setChatOpen(false); logActivity(t('Chat closed for anti-cheat', 'Anti-cheat ke liye chat band')) }
      else if (left <= 2 && left > 0 && !chatReminderShown) { setChatReminderShown(true); logActivity(t('Chat closing soon', 'Chat jaldi band hoga')) }
    }, 5000)
    return () => clearInterval(iv)
  }, [entered, info?.joinedAt, chatOpen])

  useEffect(() => { const iv = setInterval(() => setTipIdx(i => (i + 1) % TIPS.length), 30000); return () => clearInterval(iv) }, [])

  const sendChat = () => {
    if (!chatInput.trim() || !chatOpen) return
    fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ text: chatInput }) })
      .then(r => r.json()).then(d => { if (d?.success) { setChatMsgs(m => [...m, d.message]); setChatInput('') } else if (d?.chatClosed) setChatOpen(false) })
      .catch(() => {})
  }

  if (!info) return <div style={{ padding: 40, textAlign: 'center', color: sub }}>{t('Loading...', 'Load ho raha hai...')}</div>

  return (
    <div style={{ padding: 16 }} className="pr-wr-wrap">
      <style>{`.pr-wr-wrap{max-width:640px;margin:0 auto} @media(min-width:900px){.pr-wr-wrap{max-width:980px;display:grid;grid-template-columns:1fr 300px;gap:20px;align-items:start}}`}</style>
      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 24, textAlign: 'center' }}>
        <div style={{ fontSize: 18, fontWeight: 800, color: text }}>{info.exam.title}</div>
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 8, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: sub }}>⏱ {info.exam.duration} min</span>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: sub }}>🎯 {info.exam.totalMarks} marks</span>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: sub }}>❓ {info.exam.totalQuestions} Qs</span>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: C.gold }}>👥 {liveCount} {t('waiting', 'waiting')}</span>
        </div>

        {!entered ? (
          <div style={{ marginTop: 24 }}>
            <div style={{ fontSize: 40 }}>⏳</div>
            <div style={{ color: sub, margin: '10px 0' }}>{t('Click below to officially join the waiting room', 'Waiting room officially join karne ke liye niche click karo')}</div>
            <button onClick={joinNow} style={{ padding: '12px 28px', borderRadius: 12, border: 'none', background: C.gold, color: '#000', fontWeight: 800, cursor: 'pointer' }}>🚪 {t('Join Waiting Room', 'Waiting Room Join Karo')}</button>
          </div>
        ) : (
          <>
            <div style={{ fontSize: 28, animation: 'pr-float 2s ease-in-out infinite' }}>⏳</div>
            <style>{`@keyframes pr-float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-6px)} }`}</style>
            <div style={{ fontSize: 48, fontWeight: 900, color: secsLeft != null && secsLeft < 120 ? C.danger : C.gold, margin: '4px 0 6px' }}>
              {secsLeft != null && secsLeft > 0 ? fmtSecs(secsLeft) : t('Starting...', 'Shuru ho raha hai...')}
            </div>
            <div style={{ height: 6, background: theme.chipBg, borderRadius: 6, overflow: 'hidden', margin: '0 0 20px' }}>
              <div style={{ height: '100%', width: secsLeft != null && info.config?.waitingRoomMinutes ? `${100 - Math.min(100, (secsLeft / (info.config.waitingRoomMinutes * 60)) * 100)}%` : '0%', background: C.gold, transition: 'width 1s linear' }} />
            </div>

            <div style={{ background: theme.chipBg, borderRadius: 10, padding: 10, marginBottom: 10, borderLeft: `4px solid ${SEV_COLOR[TIPS[tipIdx].severity]}`, textAlign: 'left' }}>
              <span style={{ fontSize: 10, fontWeight: 800, color: SEV_COLOR[TIPS[tipIdx].severity], textTransform: 'uppercase' }}>{TIPS[tipIdx].severity}</span>
              <div style={{ fontSize: 13, color: text }}>💡 {TIPS[tipIdx].text}</div>
            </div>

            {broadcasts.length > 0 && broadcasts.map((b, i) => (
              <div key={i} style={{ background: '#3a2a00', borderRadius: 10, padding: 10, marginBottom: 10, textAlign: 'left' }}>📢 <b>{t('Admin', 'Admin')}:</b> {b.message || b.text}</div>
            ))}

            <button onClick={toggleMusic} style={{ background: 'transparent', border: `1px solid ${border}`, color: sub, borderRadius: 20, padding: '4px 12px', fontSize: 12, cursor: 'pointer', marginBottom: 14 }}>
              {musicOn ? '🔊' : '🔇'} {t('Background Music', 'Background Music')}
            </button>

            <div style={{ textAlign: 'left', background: theme.chipBg, borderRadius: 10, padding: 10, maxHeight: 160, overflowY: 'auto', marginBottom: 8 }}>
              {chatMsgs.length === 0 ? <div style={{ color: sub, fontSize: 12 }}>{t('No messages yet', 'Abhi koi message nahi')}</div> :
                chatMsgs.map((m, i) => <div key={i} style={{ fontSize: 12, color: text, marginBottom: 4 }}><b>{m.name}:</b> {m.text}</div>)}
            </div>
            {chatOpen && chatMinsLeft != null && chatMinsLeft <= 2 && (
              <div style={{ background: '#3a2a00', border: '1px solid #f2b134', borderRadius: 8, padding: '8px 10px', marginBottom: 8, fontSize: 12, color: '#f2d38a', textAlign: 'left' }}>
                ⏰ {t('Chat will close in', 'Chat band ho jayega')} {Math.ceil(chatMinsLeft)} {t('min for anti-cheat', 'min me anti-cheat ke liye')}
              </div>
            )}
            {chatOpen ? (
              <div style={{ display: 'flex', gap: 6 }}>
                <input value={chatInput} onChange={e => setChatInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && sendChat()} placeholder={t('Type a message...', 'Message likho...')}
                  style={{ flex: 1, padding: 8, borderRadius: 8, border: `1px solid ${border}`, background: inputBg, color: text }} />
                <button onClick={sendChat} style={{ padding: '8px 14px', borderRadius: 8, border: 'none', background: theme.primary, color: '#fff', cursor: 'pointer' }}>{t('Send', 'Bhejo')}</button>
              </div>
            ) : (
              <div style={{ fontSize: 11, color: sub }}>💬 {t('Chat closed for anti-cheat', 'Anti-cheat ke liye chat band ho gayi')}</div>
            )}
            {chatOpen && chatMinsLeft != null && <div style={{ fontSize: 10, color: sub, marginTop: 4 }}>{t('Chat closes in', 'Chat band hogi')} {Math.ceil(chatMinsLeft)} {t('min', 'min')}</div>}

            {activityLog.length > 0 && (
              <div style={{ textAlign: 'left', marginTop: 14, fontSize: 10, color: sub }}>
                <div style={{ fontWeight: 700, marginBottom: 4 }}>{t('Activity', 'Activity')}</div>
                {activityLog.map((a, i) => <div key={i}>{a}</div>)}
              </div>
            )}
          </>
        )}
      </div>

      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 18, marginTop: 16 }}>
        <div style={{ fontSize: 13, fontWeight: 800, color: text, marginBottom: 10 }}>{t('Exam Details', 'Exam Details')}</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, fontSize: 12, color: sub }}>
          <div>⏱ {t('Duration', 'Duration')}: <b style={{ color: text }}>{info.exam.duration} min</b></div>
          <div>🎯 {t('Marks', 'Marks')}: <b style={{ color: text }}>{info.exam.totalMarks}</b></div>
          <div>❓ {t('Questions', 'Questions')}: <b style={{ color: text }}>{info.exam.totalQuestions}</b></div>
          <div>👥 {t('Live in room', 'Live in room')}: <b style={{ color: C.gold }}>{liveCount}</b></div>
        </div>
        {broadcasts.length > 0 && (
          <div style={{ marginTop: 12 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: text, marginBottom: 6 }}>📢 {t('Broadcasts', 'Broadcasts')}</div>
            {broadcasts.slice(0, 3).map((b, i) => (
              <div key={i} style={{ fontSize: 11, color: sub, marginBottom: 4 }}>{b.message || b.text}</div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default function WaitingRoomPage() {
  return <StudentShell pageKey="my-exams"><WaitingRoomContent /></StudentShell>
}
FILEEOF5
echo "waiting-room/page.tsx updated ✅"

# ---- 6) Frontend: Instructions page (F54/F55) ----
mkdir -p ~/workspace/frontend/app/exam/\[examId\]/instructions
cat > ~/workspace/frontend/app/exam/\[examId\]/instructions/page.tsx << 'FILEEOF6'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const DEFAULT_POINTS_EN = [
  'Exam name and duration will be shown on top of the screen.',
  'Total marks are fixed as per the marking scheme.',
  'Marking scheme: +4 correct, -1 wrong, 0 unattempted (unless customized).',
  'Total number of questions is fixed — cannot be changed mid-exam.',
  'Subject-wise question counts are shown before you start.',
  'Webcam is compulsory throughout the exam.',
  'Right-click and copy-paste are disabled during the exam.',
  '3 tab switches will auto-submit your exam.',
  'Fullscreen mode is enforced — exiting will trigger a warning.'
]
const DEFAULT_POINTS_HI = [
  'Exam ka naam aur duration screen ke upar dikhega.',
  'Total marks marking scheme ke hisaab se fixed hai.',
  'Marking scheme: +4 sahi, -1 galat, 0 attempt na karne par (jab tak customize na ho).',
  'Total questions fixed hai — exam ke beech me change nahi honge.',
  'Subject-wise questions count shuru se pehle dikhega.',
  'Webcam poore exam me compulsory hai.',
  'Right-click aur copy-paste exam ke dauraan disabled rahega.',
  '3 baar tab switch karne par exam auto-submit ho jayega.',
  'Fullscreen mode enforce hoga — bahar nikalne par warning aayegi.'
]
const TC_TEXT_EN = `By proceeding, you agree to follow all ProveRank exam rules: no impersonation, no external help, no unfair means, webcam must remain on, and any violation may result in disqualification, result cancellation, or account ban. This consent is recorded against your account and exam attempt for audit purposes.`
const TC_TEXT_HI = `Aage badhne se aap ProveRank ke saare exam rules maanne ke liye sehmat hai: koi impersonation nahi, koi bahar ki madad nahi, koi unfair means nahi, webcam poore samay on rehna chahiye, aur kisi bhi violation par disqualification, result cancel, ya account ban ho sakta hai. Ye consent aapke account aur exam attempt ke against record kiya jaata hai audit ke liye.`

function InstructionsContent() {
  const { examId } = useParams() as any
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const [lang, setLang] = useState(shell?.lang || 'en')
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const text = theme.text, sub = theme.sub, border = theme.border
  const card = theme.isDark ? C.card : C.cardL

  const [exam, setExam] = useState<any>(null)
  const [checked, setChecked] = useState(false)
  const [tcModal, setTcModal] = useState(false)
  const [scrolledToBottom, setScrolledToBottom] = useState(false)
  const [consentAlready, setConsentAlready] = useState(false)
  const [consentAcceptedAt, setConsentAcceptedAt] = useState<string | null>(null)
  const [needsReaccept, setNeedsReaccept] = useState(false)
  const tcBodyRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!token) return
    fetch(`${API}/api/exams/my-exams`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        const e = (d?.exams || []).find((x: any) => String(x._id) === String(examId))
        if (e?.activeAttemptId) { router.replace(`/exam/${examId}/attempt`); return }
      }).catch(() => {})

    fetch(`${API}/api/exams/${examId}`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json()).then(d => setExam(d?.exam || null)).catch(() => {})

    fetch(`${API}/api/exams/${examId}/consent-status`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json()).then(d => {
        if (!d?.success) return
        setConsentAlready(!!d.accepted)
        setConsentAcceptedAt(d.acceptedAt || null)
        setNeedsReaccept(!!d.acceptedVersion && d.acceptedVersion !== d.currentVersion)
      }).catch(() => {})
  }, [examId, token])

  const onTcScroll = () => {
    const el = tcBodyRef.current
    if (!el) return
    if (el.scrollHeight - el.scrollTop - el.clientHeight < 20) setScrolledToBottom(true)
  }

  // F53-d FIX: if T&C text already fits without overflow, no 'scroll'
  // event ever fires, so scrolledToBottom stayed stuck at false forever
  // and "I Agree" was permanently disabled. Check once when modal opens.
  useEffect(() => {
    if (!tcModal) return
    setScrolledToBottom(false)
    const tId = setTimeout(() => onTcScroll(), 50)
    return () => clearTimeout(tId)
  }, [tcModal])

  const proceed = async () => {
    if (!checked) return
    try {
      const r = await fetch(`${API}/api/exams/${examId}/accept-terms`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      const d = await r.json()
      if (!d?.success) { alert(t('Could not record consent, please retry', 'Consent record nahi ho paya, dobara try karo')); return }
      sessionStorage.setItem(`pr_tc_${examId}`, JSON.stringify({ accepted: true, version: d.version, at: d.acceptedAt }))
      router.push(`/exam/${examId}/webcam`)
    } catch (e) {
      alert(t('Network error — please retry', 'Network error — dobara try karo'))
    }
  }

  const marking = exam?.marking || { correct: 4, incorrect: -1, unattempted: 0 }
  const subjectBreakdown = exam?.subjectBreakdown || {}
  const subjectLine = Object.keys(subjectBreakdown).length
    ? Object.entries(subjectBreakdown).map(([s, c]) => `${s}: ${c}`).join(', ')
    : t('will be shown on exam start', 'exam shuru hone par dikhega')

  // F54 §2.1 — dynamic instruction points built from real exam data (was static generic text before)
  const dynamicPoints = lang === 'hi' ? [
    `Exam "${exam?.title || ''}" ki duration ${exam?.duration || '--'} minute hai.`,
    `Total marks ${exam?.totalMarks || '--'} hai marking scheme ke hisaab se.`,
    `Marking scheme: +${marking.correct} sahi, ${marking.incorrect} galat, ${marking.unattempted} attempt na karne par.`,
    `Total questions: ${exam?.totalQuestionsCount ?? '--'} — exam ke beech me change nahi honge.`,
    `Subject-wise questions: ${subjectLine}.`,
    'Webcam poore exam me compulsory hai.',
    'Right-click aur copy-paste exam ke dauraan disabled rahega.',
    '3 baar tab switch karne par exam auto-submit ho jayega.',
    'Fullscreen mode enforce hoga — bahar nikalne par warning aayegi.'
  ] : [
    `Exam "${exam?.title || ''}" duration is ${exam?.duration || '--'} minutes.`,
    `Total marks are ${exam?.totalMarks || '--'} as per the marking scheme.`,
    `Marking scheme: +${marking.correct} correct, ${marking.incorrect} wrong, ${marking.unattempted} unattempted.`,
    `Total questions: ${exam?.totalQuestionsCount ?? '--'} — cannot be changed mid-exam.`,
    `Subject-wise questions: ${subjectLine}.`,
    'Webcam is compulsory throughout the exam.',
    'Right-click and copy-paste are disabled during the exam.',
    '3 tab switches will auto-submit your exam.',
    'Fullscreen mode is enforced — exiting will trigger a warning.'
  ]
  const points = dynamicPoints

  return (
    <div style={{ padding: 16, maxWidth: 640, margin: '0 auto' }}>
      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 22 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 800, color: text }}>{exam?.title || t('Exam Instructions', 'Exam Instructions')}</div>
            <div style={{ fontSize: 12, color: sub }}>{t('Please read carefully before proceeding', 'Aage badhne se pehle dhyan se padho')}</div>
          </div>
          <button onClick={() => setLang(l => l === 'hi' ? 'en' : 'hi')} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer', fontSize: 12 }}>
            {lang === 'hi' ? 'EN' : 'हिं'}
          </button>
        </div>

        {/* F54 §5.1 — instruction progress indicator / readiness steps */}
        <div style={{ display: 'flex', gap: 8, margin: '14px 0' }}>
          <div style={{ flex: 1, textAlign: 'center', padding: '8px 4px', borderRadius: 8, background: theme.chipBg || 'rgba(255,255,255,0.06)', border: `1px solid ${border}` }}>
            <div style={{ fontSize: 11, color: text, fontWeight: 700 }}>1. {t('Read Instructions', 'Instructions Padho')}</div>
          </div>
          <div style={{ flex: 1, textAlign: 'center', padding: '8px 4px', borderRadius: 8, background: checked ? '#123b1e' : (theme.chipBg || 'rgba(255,255,255,0.06)'), border: `1px solid ${checked ? '#1e5c3a' : border}` }}>
            <div style={{ fontSize: 11, color: checked ? '#7CFC9C' : text, fontWeight: 700 }}>2. {checked ? '✓ ' : ''}{t('Accept T&C', 'T&C Accept Karo')}</div>
          </div>
          <div style={{ flex: 1, textAlign: 'center', padding: '8px 4px', borderRadius: 8, background: theme.chipBg || 'rgba(255,255,255,0.06)', border: `1px solid ${border}` }}>
            <div style={{ fontSize: 11, color: sub, fontWeight: 700 }}>3. {t('Webcam Check', 'Webcam Check')}</div>
          </div>
        </div>

        {needsReaccept && (
          <div style={{ background: '#3a2a00', color: '#f2d38a', borderRadius: 10, padding: 8, fontSize: 12, margin: '12px 0' }}>
            🔄 {t('Terms have been updated since your last acceptance. Please read and accept again.', 'Terms update ho gaye hai aapki pichli acceptance ke baad. Dobara padhke accept karo.')}
          </div>
        )}
        {consentAlready && !needsReaccept && (
          <div style={{ background: '#123b1e', color: '#7CFC9C', borderRadius: 10, padding: 8, fontSize: 12, margin: '12px 0' }}>
            ✅ {t('You already accepted these terms for this exam.', 'Aapne is exam ke liye ye terms pehle hi accept kar liye hai.')}
            {consentAcceptedAt && <span style={{ opacity: 0.8 }}> ({new Date(consentAcceptedAt).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })})</span>}
          </div>
        )}

        {/* F54 §5.4 — custom admin instructions pinned at top of the content, above default points */}
        {exam?.customInstructions && (
          <div style={{ background: '#3a2a00', borderLeft: '4px solid #f2b134', borderRadius: 8, padding: 12, margin: '14px 0', color: '#f2d38a', fontSize: 12 }}>
            ⚠️ <b>{t('Additional Instructions', 'Additional Instructions')}:</b> {exam.customInstructions}
          </div>
        )}

        <ol style={{ padding: '16px 0 0 20px', color: text, fontSize: 13, lineHeight: 1.9 }}>
          {points.map((p, i) => <li key={i}>{p}</li>)}
        </ol>

        {/* F54 §5.5 — permission checklist preview before navigating to webcam/fullscreen */}
        <div style={{ background: theme.chipBg || 'rgba(255,255,255,0.06)', borderRadius: 10, padding: 12, margin: '14px 0', fontSize: 12, color: sub }}>
          <div style={{ fontWeight: 700, color: text, marginBottom: 6 }}>{t('You will be asked for', 'Aapse ye maanga jayega')}:</div>
          <div>📷 {t('Camera permission (compulsory)', 'Camera permission (compulsory)')}</div>
          <div>🖥️ {t('Fullscreen mode (auto-enforced)', 'Fullscreen mode (auto-enforced)')}</div>
          <div>🚫 {t('Right-click / copy-paste disabled', 'Right-click / copy-paste disabled')}</div>
        </div>

        <div style={{ background: '#0e2418', border: '1px solid #1e5c3a', borderRadius: 10, padding: 12, marginTop: 16 }}>
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer' }}>
            <input type="checkbox" checked={checked} onChange={e => { if (!e.target.checked) { setChecked(false); return } setTcModal(true) }} style={{ marginTop: 3 }} />
            <span style={{ fontSize: 13, color: '#dff5e6' }}>
              {t('I have read and agree to all instructions', 'Maine saari instructions padh li hai aur maanta/maanti hoon')}
              {' '}<a onClick={(e) => { e.preventDefault(); setTcModal(true) }} style={{ color: C.gold, cursor: 'pointer', textDecoration: 'underline' }}>({t('read full terms', 'poore terms padho')})</a>
            </span>
          </label>
        </div>

        <button disabled={!checked} onClick={proceed} style={{ width: '100%', marginTop: 18, padding: 14, borderRadius: 12, border: 'none', background: checked ? `linear-gradient(90deg, ${theme.primary}, ${C.gold})` : '#444', color: '#fff', fontWeight: 800, cursor: checked ? 'pointer' : 'not-allowed', transition: 'all .3s' }}>
          {t('Proceed to AI Webcam Check', 'AI Webcam Check Par Jao')} →
        </button>
      </div>

      {tcModal && (
        <div onClick={() => setTcModal(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 300, padding: 16 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, borderRadius: 16, padding: 20, maxWidth: 480, width: '100%', maxHeight: '80vh', display: 'flex', flexDirection: 'column' }}>
            <div style={{ fontWeight: 800, color: text, marginBottom: 10 }}>{t('Terms & Conditions', 'Terms & Conditions')}</div>
            <div ref={tcBodyRef} onScroll={onTcScroll} style={{ overflowY: 'auto', fontSize: 13, color: sub, lineHeight: 1.7, flex: 1, paddingRight: 4 }}>
              {lang === 'hi' ? TC_TEXT_HI : TC_TEXT_EN}
            </div>
            {!scrolledToBottom && <div style={{ fontSize: 11, color: C.gold, marginTop: 8 }}>{t('Scroll to the bottom to continue', 'Continue karne ke liye niche scroll karo')}</div>}
            <button disabled={!scrolledToBottom} onClick={() => { setChecked(true); setTcModal(false) }} style={{ marginTop: 12, padding: 12, borderRadius: 10, border: 'none', background: scrolledToBottom ? C.gold : '#444', color: '#000', fontWeight: 800, cursor: scrolledToBottom ? 'pointer' : 'not-allowed' }}>
              {t('I Agree', 'Main Sehmat Hoon')}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function InstructionsPage() {
  return <StudentShell pageKey="my-exams"><InstructionsContent /></StudentShell>
}
FILEEOF6
echo "instructions/page.tsx updated ✅"

# ---- 7) Frontend: Webcam Check page (F56 — real face detection) ----
mkdir -p ~/workspace/frontend/app/exam/\[examId\]/webcam
cat > ~/workspace/frontend/app/exam/\[examId\]/webcam/page.tsx << 'FILEEOF7'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

// F56 §1.5/§2.6-2.9 — real face detection via TensorFlow.js Blazeface,
// loaded on-demand from CDN (no package.json change needed). Previously
// faceOk was hardcoded `true` and multiFace was never set — both fake.
const TF_URL = 'https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.20.0/dist/tf.min.js'
const BLAZEFACE_URL = 'https://cdn.jsdelivr.net/npm/@tensorflow-models/blazeface@0.1.0/dist/blazeface.min.js'

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) { resolve(); return }
    const s = document.createElement('script')
    s.src = src; s.async = true
    s.onload = () => resolve()
    s.onerror = () => reject(new Error('script load failed: ' + src))
    document.body.appendChild(s)
  })
}

function WebcamCheckContent() {
  const { examId } = useParams() as any
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const lang = shell?.lang || 'en'
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const text = theme.text, sub = theme.sub, border = theme.border
  const card = theme.isDark ? C.card : C.cardL

  const videoRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const audioStreamRef = useRef<MediaStream | null>(null)
  const modelRef = useRef<any>(null)
  const detectTimerRef = useRef<any>(null)

  const [status, setStatus] = useState<'idle' | 'requesting' | 'live' | 'denied' | 'error'>('idle')
  const [failureReason, setFailureReason] = useState('')
  const [faceOk, setFaceOk] = useState<boolean | null>(null)
  const [noFace, setNoFace] = useState(false)
  const [multiFace, setMultiFace] = useState(false)
  const [lightingOk, setLightingOk] = useState<boolean | null>(null)
  const [vbgSuspicious, setVbgSuspicious] = useState(false)
  const [modelReady, setModelReady] = useState(false)
  const [modelLoadFailed, setModelLoadFailed] = useState(false)
  const [audioOn, setAudioOn] = useState(false)
  const [devices, setDevices] = useState<MediaDeviceInfo[]>([])
  const [selectedDeviceId, setSelectedDeviceId] = useState<string>('')
  const [historyLog, setHistoryLog] = useState<{ at: string; event: string }[]>([])
  const [compactMode, setCompactMode] = useState(false)

  const logHistory = (event: string) => setHistoryLog(h => [{ at: new Date().toLocaleTimeString(), event }, ...h].slice(0, 10))

  // Load TF.js + Blazeface model once, in background — camera works even if this is still loading/fails
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        await loadScript(TF_URL)
        await loadScript(BLAZEFACE_URL)
        const bf = (window as any).blazeface
        if (!bf) throw new Error('blazeface not on window')
        const model = await bf.load()
        if (cancelled) return
        modelRef.current = model
        setModelReady(true)
        logHistory(t('Face detection model loaded', 'Face detection model load ho gaya'))
      } catch (e) {
        if (cancelled) return
        setModelLoadFailed(true)
        logHistory(t('Face detection model failed to load — camera still works', 'Face detection model load nahi hua — camera phir bhi kaam karega'))
      }
    })()
    return () => { cancelled = true }
  }, [])

  useEffect(() => {
    navigator.mediaDevices?.enumerateDevices?.().then(list => {
      setDevices(list.filter(d => d.kind === 'videoinput'))
    }).catch(() => {})
  }, [])

  const requestCamera = async (deviceId?: string) => {
    setStatus('requesting'); setFailureReason('')
    try {
      const constraints: MediaStreamConstraints = {
        video: deviceId ? { deviceId: { exact: deviceId }, width: 480, height: 360 } : { width: 480, height: 360 }
      }
      const stream = await navigator.mediaDevices.getUserMedia(constraints)
      streamRef.current = stream
      if (videoRef.current) videoRef.current.srcObject = stream
      setStatus('live')
      logHistory(t('Camera permission granted', 'Camera permission mil gayi'))
      setTimeout(() => checkLighting(), 800)
    } catch (err: any) {
      setStatus('denied')
      const reason = err?.name === 'NotAllowedError' ? t('Permission denied by user/browser', 'User/browser ne permission deny ki')
        : err?.name === 'NotFoundError' ? t('No camera device found', 'Koi camera device nahi mila')
        : t('Unknown camera error', 'Unknown camera error')
      setFailureReason(reason)
      logHistory(t('Camera permission denied — ', 'Camera permission denied — ') + reason)
    }
  }

  // F56 §1.8 — optional audio permission (separate from compulsory camera)
  const requestAudio = async () => {
    try {
      const s = await navigator.mediaDevices.getUserMedia({ audio: true })
      audioStreamRef.current = s
      setAudioOn(true)
      logHistory(t('Optional mic permission granted', 'Optional mic permission mil gayi'))
    } catch (e) {
      logHistory(t('Mic permission skipped/denied', 'Mic permission skip/deny hui'))
    }
  }

  const checkLighting = () => {
    try {
      const video = videoRef.current
      if (!video) return
      const canvas = document.createElement('canvas')
      canvas.width = 40; canvas.height = 30
      const ctx = canvas.getContext('2d')
      if (!ctx) return
      ctx.drawImage(video, 0, 0, 40, 30)
      const data = ctx.getImageData(0, 0, 40, 30).data
      let sum = 0
      for (let i = 0; i < data.length; i += 4) sum += (data[i] + data[i + 1] + data[i + 2]) / 3
      const avg = sum / (data.length / 4)
      setLightingOk(avg > 40)
      logHistory(avg > 40 ? t('Lighting OK', 'Lighting theek hai') : t('Low lighting detected', 'Kam lighting detect hui'))
    } catch (e) {}
  }

  // F56 §1.6 — lightweight heuristic virtual-background check: sample a strip
  // of pixels away from the detected face box; an unnaturally flat/uniform
  // background (very low pixel variance) is flagged as suspicious. This is a
  // heuristic signal, not a certified anti-spoofing verdict.
  const checkVirtualBackground = (faceBox: number[] | null) => {
    try {
      const video = videoRef.current
      if (!video) return
      const canvas = document.createElement('canvas')
      canvas.width = 80; canvas.height = 60
      const ctx = canvas.getContext('2d')
      if (!ctx) return
      ctx.drawImage(video, 0, 0, 80, 60)
      const data = ctx.getImageData(0, 0, 80, 60).data
      // sample the top strip (usually background, above a centered face)
      let sum = 0, sumSq = 0, n = 0
      for (let y = 0; y < 12; y++) {
        for (let x = 0; x < 80; x++) {
          const i = (y * 80 + x) * 4
          const lum = (data[i] + data[i + 1] + data[i + 2]) / 3
          sum += lum; sumSq += lum * lum; n++
        }
      }
      const mean = sum / n
      const variance = sumSq / n - mean * mean
      setVbgSuspicious(variance < 4) // near-flat single-color band = suspicious
    } catch (e) {}
  }

  // Real detection loop — replaces the old hardcoded setFaceOk(true)
  useEffect(() => {
    if (status !== 'live' || !modelReady) return
    detectTimerRef.current = setInterval(async () => {
      try {
        const model = modelRef.current
        const video = videoRef.current
        if (!model || !video) return
        const predictions = await model.estimateFaces(video, false)
        const count = predictions?.length || 0
        setFaceOk(count === 1)
        setNoFace(count === 0)
        setMultiFace(count > 1)
        if (count === 1) checkVirtualBackground(predictions[0]?.topLeft || null)
      } catch (e) {}
    }, 1200)
    return () => clearInterval(detectTimerRef.current)
  }, [status, modelReady])

  // Fallback: if the model failed to load, don't fake success — mark as "unverified" (null) not "confirmed"
  useEffect(() => {
    if (status === 'live' && modelLoadFailed) {
      setFaceOk(null)
      logHistory(t('Face check unavailable — proceeding on camera-live signal only', 'Face check available nahi — sirf camera-live signal use ho raha hai'))
    }
  }, [status, modelLoadFailed])

  useEffect(() => () => {
    streamRef.current?.getTracks().forEach(tr => tr.stop())
    audioStreamRef.current?.getTracks().forEach(tr => tr.stop())
    if (detectTimerRef.current) clearInterval(detectTimerRef.current)
  }, [])

  const readinessScore = [status === 'live', faceOk === true, lightingOk !== false, !multiFace, !vbgSuspicious].filter(Boolean).length
  const cameraHealthLabel = readinessScore >= 5 ? t('Excellent', 'Excellent') : readinessScore >= 3 ? t('Fair', 'Theek-thaak') : t('Poor', 'Kharab')

  // F56 §1.3 — exam stays blocked while there's a real problem: no face / multiple faces.
  // (Lighting/VBG remain warnings, not hard blocks, to avoid false-positive lockouts.)
  const canStart = status === 'live' && !multiFace && !noFace

  const proceedToExam = () => {
    if (!canStart) return
    streamRef.current?.getTracks().forEach(tr => tr.stop())
    audioStreamRef.current?.getTracks().forEach(tr => tr.stop())
    router.push(`/exam/${examId}/attempt`)
  }

  return (
    <div style={{ padding: 16, maxWidth: 640, margin: '0 auto' }}>
      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 22 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: text }}>📷 {t('Webcam Check', 'Webcam Check')}</div>
          <button onClick={() => setCompactMode(m => !m)} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, border: `1px solid ${border}`, background: 'transparent', color: sub, cursor: 'pointer' }}>
            {compactMode ? t('Full View', 'Full View') : t('Compact', 'Compact')}
          </button>
        </div>

        {devices.length > 1 && status !== 'live' && (
          <select value={selectedDeviceId} onChange={e => setSelectedDeviceId(e.target.value)} style={{ width: '100%', padding: 8, borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, marginBottom: 10, fontSize: 12 }}>
            <option value="">{t('Default Camera', 'Default Camera')}</option>
            {devices.map(d => <option key={d.deviceId} value={d.deviceId}>{d.label || t('Camera', 'Camera')}</option>)}
          </select>
        )}

        <div style={{ position: 'relative', background: '#000', borderRadius: 14, overflow: 'hidden', aspectRatio: compactMode ? '16/9' : '4/3', maxHeight: compactMode ? 180 : 360 }}>
          <video ref={videoRef} autoPlay playsInline muted style={{ width: '100%', height: '100%', objectFit: 'cover', transform: 'scaleX(-1)' }} />
          {status === 'live' && <span style={{ position: 'absolute', top: 8, left: 8, fontSize: 10, fontWeight: 800, color: '#fff', background: '#e53935', padding: '3px 8px', borderRadius: 20 }}>🔴 LIVE</span>}
          {status !== 'live' && (
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#888' }}>{t('Camera preview', 'Camera preview')}</div>
          )}
        </div>

        {status === 'live' && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 12 }}>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: readinessScore >= 3 ? '#123b1e' : '#3a1414', color: readinessScore >= 3 ? '#7CFC9C' : '#ff8080' }}>✅ {t('Camera Health', 'Camera Health')}: {cameraHealthLabel}</span>
            {!modelReady && !modelLoadFailed && <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: '#2a2a3a', color: '#b0b0ff' }}>⏳ {t('Loading face check...', 'Face check load ho raha...')}</span>}
            {modelReady && (
              <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: faceOk ? '#123b1e' : '#3a1414', color: faceOk ? '#7CFC9C' : '#ff8080' }}>
                {faceOk ? '✅' : noFace ? '❌' : '⚠️'} {noFace ? t('No Face Detected', 'Face Detect Nahi Hua') : multiFace ? t('Multiple Faces!', 'Multiple Faces!') : t('Face Visible', 'Face Visible')}
              </span>
            )}
            {modelLoadFailed && <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: '#3a2a00', color: '#f2d38a' }}>⚠️ {t('Face check unavailable', 'Face check unavailable')}</span>}
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: lightingOk === false ? '#3a2a00' : '#123b1e', color: lightingOk === false ? '#f2d38a' : '#7CFC9C' }}>{lightingOk === false ? '⚠️' : '✅'} {t('Lighting', 'Lighting')}</span>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: vbgSuspicious ? '#3a2a00' : '#123b1e', color: vbgSuspicious ? '#f2d38a' : '#7CFC9C' }}>{vbgSuspicious ? '⚠️' : '✅'} {t('Background Check', 'Background Check')}</span>
          </div>
        )}

        {status === 'live' && multiFace && (
          <div style={{ background: '#3a1414', borderRadius: 10, padding: 10, marginTop: 10, fontSize: 12, color: '#ff8080' }}>
            🚫 {t('Multiple faces detected — only you should be in frame. Exam cannot start until this is resolved.', 'Multiple faces detect hui — sirf aap frame me hone chahiye. Ye theek hue bina exam shuru nahi hoga.')}
          </div>
        )}
        {status === 'live' && noFace && !multiFace && (
          <div style={{ background: '#3a2a00', borderRadius: 10, padding: 10, marginTop: 10, fontSize: 12, color: '#f2d38a' }}>
            ⚠️ {t('No face detected — please face the camera clearly.', 'Face detect nahi hua — camera ki taraf saaf dekho.')}
          </div>
        )}
        {status === 'live' && vbgSuspicious && (
          <div style={{ background: '#3a2a00', borderRadius: 10, padding: 10, marginTop: 10, fontSize: 12, color: '#f2d38a' }}>
            ⚠️ {t('Background looks unusually uniform — please sit in a real, plain room (virtual backgrounds are not allowed).', 'Background asamanya roop se flat lag raha hai — real room me baitho (virtual background allowed nahi hai).')}
          </div>
        )}

        {status === 'live' && !audioOn && (
          <button onClick={requestAudio} style={{ marginTop: 10, fontSize: 11, padding: '6px 12px', borderRadius: 20, border: `1px solid ${border}`, background: 'transparent', color: sub, cursor: 'pointer' }}>
            🎙️ {t('Enable Optional Mic Monitoring', 'Optional Mic Monitoring On Karo')}
          </button>
        )}

        {status === 'denied' && (
          <div style={{ background: '#3a1414', borderRadius: 10, padding: 12, marginTop: 12 }}>
            <div style={{ color: '#ff8080', fontWeight: 700, fontSize: 13 }}>❌ {t('Camera Permission Denied', 'Camera Permission Denied')}</div>
            <div style={{ color: '#f2b8b8', fontSize: 12, marginTop: 4 }}>{t('Reason', 'Reason')}: {failureReason}</div>
            <button onClick={() => requestCamera(selectedDeviceId || undefined)} style={{ marginTop: 10, padding: '8px 16px', borderRadius: 8, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>🔄 {t('Retry Camera Permission', 'Camera Permission Dobara Try Karo')}</button>
          </div>
        )}

        {status === 'idle' && (
          <button onClick={() => requestCamera(selectedDeviceId || undefined)} style={{ width: '100%', marginTop: 16, padding: 14, borderRadius: 12, border: 'none', background: C.gold, color: '#000', fontWeight: 800, cursor: 'pointer' }}>
            📷 {t('Allow Camera & Start Exam', 'Camera Allow Karo & Exam Shuru Karo')}
          </button>
        )}
        {status === 'live' && (
          <button onClick={proceedToExam} disabled={!canStart} style={{ width: '100%', marginTop: 16, padding: 14, borderRadius: 12, border: 'none', background: canStart ? `linear-gradient(90deg, ${theme.primary}, ${C.gold})` : '#444', color: '#fff', fontWeight: 800, cursor: canStart ? 'pointer' : 'not-allowed' }}>
            ✅ {t('Start Exam', 'Exam Shuru Karo')}
          </button>
        )}

        {historyLog.length > 0 && (
          <div style={{ marginTop: 16, fontSize: 11, color: sub }}>
            <div style={{ fontWeight: 700, marginBottom: 4 }}>{t('Permission History', 'Permission History')}</div>
            {historyLog.map((h, i) => <div key={i}>{h.at} — {h.event}</div>)}
          </div>
        )}
      </div>
    </div>
  )
}

export default function WebcamCheckPage() {
  return <StudentShell pageKey="my-exams"><WebcamCheckContent /></StudentShell>
}
FILEEOF7
echo "webcam/page.tsx updated ✅"

# ---- 8) Frontend: Exam Attempt page (F57 — fullscreenForce respected) ----
cat > ~/workspace/frontend/app/exam/\[examId\]/attempt/page.tsx << 'FILEEOF8'
'use client'
import { useState, useEffect, useCallback, useRef, useMemo } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useAuth } from '@/lib/useAuth'
import { renderLatex } from '@/lib/renderLatex'

const API = process.env.NEXT_PUBLIC_API_URL || ''

// ── F58 §6.2 — deterministic color-per-subject palette (multi-exam safe: ──
// ── works for ANY subject name of ANY competitive exam, not just NEET) ──
const SUBJECT_PALETTE = ['#4D9FFF', '#00C48C', '#FFA502', '#A855F7', '#FF4757', '#FFD700', '#22D3EE', '#F472B6']
function subjectColor(name?: string) {
  if (!name) return SUBJECT_PALETTE[0]
  let h = 0
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0
  return SUBJECT_PALETTE[h % SUBJECT_PALETTE.length]
}

const OPT_LETTERS = ['A', 'B', 'C', 'D']

export default function ExamAttempt() {
  const { user, loading } = useAuth('student')
  const params   = useParams()
  const router   = useRouter()
  const examId   = params?.examId as string

  // ── Core UI state ──────────────────────────────────────────
  const [lang, setLang]       = useState<'en'|'hi'>('en')
  const [dark, setDark]       = useState(true)
  const [fontSize, setFontSize] = useState(16) // §14 Text Accessibility
  const [mounted, setMounted] = useState(false)

  // ── Attempt / question state ───────────────────────────────
  const [attempt, setAttempt]     = useState<any>(null)
  const [questions, setQuestions] = useState<any[]>([])
  const [examMeta, setExamMeta]   = useState<any>({ sections: [], markingScheme: { correct: 4, incorrect: -1, unattempted: 0 }, duration: 200, title: '', status: '', fullscreenForce: true })
  const [current, setCurrent]     = useState(0)
  const [answers, setAnswers]     = useState<Record<string, any>>({})
  const [flagged, setFlagged]     = useState<Set<string>>(new Set())
  const [visited, setVisited]     = useState<Set<string>>(new Set())
  const [selectedSubject, setSelectedSubject] = useState('All') // §11 Section Tabs
  const [errorState, setErrorState] = useState<{ code: string; message: string } | null>(null)
  const [initializing, setInitializing] = useState(true)

  // ── Timer ───────────────────────────────────────────────────
  const [timeLeft, setTimeLeft]   = useState(0)
  const [totalDurationSec, setTotalDurationSec] = useState(12000)
  const [timeExtNotif, setTimeExtNotif] = useState<string | null>(null) // Feature 32

  // ── Submit flow ─────────────────────────────────────────────
  const [submitting, setSubmitting] = useState(false)
  const [showSubmit, setShowSubmit] = useState(false)

  // ── Anti-cheat (unchanged behaviour, refs fixed) ────────────
  const [warnings, setWarnings] = useState(0)
  const [showFSWarning, setShowFSWarning] = useState(false)
  const [fsCompliant, setFsCompliant] = useState(true)
  const fsExitTimerRef = useRef<any>(null)
  const [focusLocked, setFocusLocked] = useState(true)
  const [warningHistory, setWarningHistory] = useState<{ type: string; at: string }[]>([])
  const integrityImpact = warnings === 0 ? 'none' : warnings === 1 ? 'low' : warnings === 2 ? 'medium' : 'high'

  // ── §15 Image zoom / lightbox ────────────────────────────────
  const [zoomImg, setZoomImg] = useState<string | null>(null)

  // ── §17 Question reporting ──────────────────────────────────
  const [showReportModal, setShowReportModal] = useState(false)
  const [reportReason, setReportReason] = useState('')
  const [reportMsg, setReportMsg] = useState<string | null>(null)
  const [reportSubmitting, setReportSubmitting] = useState(false)

  // ── §16 Per-question time tracking ──────────────────────────
  const [timeSpent, setTimeSpent] = useState<Record<string, number>>({})
  const questionEnterRef = useRef<number>(Date.now())

  // ── Mobile responsive nav drawer (§20) ──────────────────────
  const [showMobileNav, setShowMobileNav] = useState(false)

  // ── §2.5 Mini webcam preview (fixed at bottom of side panel) ────
  const videoRef = useRef<HTMLVideoElement>(null)
  const camStreamRef = useRef<MediaStream | null>(null)
  const [camReady, setCamReady] = useState(false)

  // ── F59 §8.5 Confidence tags, §5/§13.2 submit-lock, §8.1/§8.12 offline ──
  // ── retry queue, §6.5 saved-flash confirmation, §6.4 integer validation ──
  const [confidence, setConfidence] = useState<Record<string, 'high' | 'medium' | 'low' | null>>({})
  const [locked, setLocked] = useState(false)
  const [isOnline, setIsOnline] = useState(true)
  const [queuedCount, setQueuedCount] = useState(0)
  const [savedFlash, setSavedFlash] = useState<string | null>(null)
  const [integerError, setIntegerError] = useState<Record<string, string>>({})
  const retryQueueRef = useRef<Record<string, { selectedOption: any; timeTaken: number; confidence: any }>>({})

  // ── Socket (Feature 32 — time extension push; fixed & guarded) ──
  const socketRef = useRef<any>(null)

  const t = lang === 'en' ? {
    submit: 'Submit Exam', confirm: 'Confirm Submission',
    answered: 'Answered', unanswered: 'Not Answered', flagged: 'Marked', notVisited: 'Not Visited',
    saveNext: 'Save & Next', markReview: 'Mark for Review', unmarkReview: 'Unmark Review', clearResp: 'Clear Response',
    timeLeft: 'Time Remaining', question: 'Question',
    subWarn: 'You have unanswered questions. Submit anyway?',
    cancelSub: 'Cancel', confirmSub: 'Yes, Submit',
    all: 'All', report: 'Report', reportTitle: 'Report this question',
    reportPlaceholder: 'Describe the issue with this question (typo, wrong option, unclear image, etc.)',
    reportSubmit: 'Submit Report', reportSent: 'Question reported. Admin will review it.',
    avgTime: 'Avg/Q', integerHint: 'Enter your numeric answer',
    live: 'LIVE', practice: 'Practice', prev: 'Previous', next: 'Next',
    loadingExam: 'Loading exam...', errTitle: 'Could not start exam',
    backToExams: 'Back to My Exams', retry: 'Retry',
    fontSmaller: 'A−', fontBigger: 'A+',
    optionsSelected: 'Options Selected', integerInvalid: 'Enter a valid whole number',
    confidenceHigh: 'High', confidenceMed: 'Medium', confidenceLow: 'Low', confidenceLabel: 'Confidence',
    saved: 'Saved', queued: 'Offline — will sync', offline: 'Offline', online: 'Online',
    lockedTitle: 'Attempt Locked', lockedMsg: 'This exam attempt has already been submitted or locked. No further changes can be made.',
    viewResults: 'View Results / Back',
  } : {
    submit: 'परीक्षा जमा करें', confirm: 'जमा करने की पुष्टि',
    answered: 'उत्तर दिया', unanswered: 'उत्तर नहीं दिया', flagged: 'चिह्नित', notVisited: 'नहीं देखा',
    saveNext: 'सहेजें और आगे', markReview: 'समीक्षा के लिए', unmarkReview: 'समीक्षा हटाएं', clearResp: 'साफ करें',
    timeLeft: 'शेष समय', question: 'प्रश्न',
    subWarn: 'कुछ प्रश्नों का उत्तर नहीं दिया। क्या फिर भी जमा करें?',
    cancelSub: 'रद्द करें', confirmSub: 'हाँ, जमा करें',
    all: 'सभी', report: 'रिपोर्ट', reportTitle: 'इस प्रश्न को रिपोर्ट करें',
    reportPlaceholder: 'इस प्रश्न की समस्या बताएं (गलती, गलत विकल्प, अस्पष्ट इमेज आदि)',
    reportSubmit: 'रिपोर्ट भेजें', reportSent: 'प्रश्न रिपोर्ट हो गया। एडमिन इसे देखेगा।',
    avgTime: 'औसत/प्रश्न', integerHint: 'अपना संख्यात्मक उत्तर लिखें',
    live: 'लाइव', practice: 'अभ्यास', prev: 'पिछला', next: 'आगे',
    loadingExam: 'परीक्षा लोड हो रही है...', errTitle: 'परीक्षा शुरू नहीं हो पाई',
    backToExams: 'मेरी परीक्षाओं पर वापस जाएं', retry: 'दोबारा कोशिश करें',
    fontSmaller: 'A−', fontBigger: 'A+',
    optionsSelected: 'विकल्प चुने गए', integerInvalid: 'एक सही पूर्णांक लिखें',
    confidenceHigh: 'उच्च', confidenceMed: 'मध्यम', confidenceLow: 'कम', confidenceLabel: 'विश्वास',
    saved: 'सहेजा गया', queued: 'ऑफलाइन — बाद में सिंक होगा', offline: 'ऑफलाइन', online: 'ऑनलाइन',
    lockedTitle: 'प्रयास लॉक हो गया', lockedMsg: 'यह परीक्षा प्रयास पहले ही जमा/लॉक हो चुका है। अब कोई बदलाव संभव नहीं है।',
    viewResults: 'परिणाम देखें / वापस जाएं',
  }

  // ── §2.7 — genuinely distinct Mobile vs Desktop UI (not just a squeeze) ──
  const [isMobile, setIsMobile] = useState(false)
  const [showMobileTools, setShowMobileTools] = useState(false)

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if (sl) setLang(sl)
    const st = localStorage.getItem('pr_theme'); if (st === 'light') setDark(false)
    const checkMobile = () => setIsMobile(window.innerWidth <= 820)
    checkMobile()
    window.addEventListener('resize', checkMobile)
    return () => window.removeEventListener('resize', checkMobile)
  }, [])

  const toggleLang = () => { const n = lang === 'en' ? 'hi' : 'en'; setLang(n); localStorage.setItem('pr_lang', n) }
  const toggleTheme = () => { const n = !dark; setDark(n); localStorage.setItem('pr_theme', n ? 'dark' : 'light') }

  // ── §1 Exam Availability & §24 State Preservation / §26 Persistence ──
  // Resume an existing active attempt if one exists (via /my-exams,
  // exactly like Instructions/Waiting-Room already do) instead of blindly
  // creating a brand-new Attempt document on every page load/refresh —
  // that previously burned an extra attempt slot on every reload.
  const initAttempt = useCallback(async () => {
    if (!user || !examId) return
    setInitializing(true)
    setErrorState(null)
    try {
      const h = { 'Content-Type': 'application/json', Authorization: `Bearer ${user!.token}` }

      let attemptId: string | null = null
      try {
        const mr = await fetch(`${API}/api/exams/my-exams`, { headers: h })
        const md = await mr.json()
        const mine = (md?.exams || []).find((x: any) => String(x._id) === String(examId))
        if (mine?.activeAttemptId) attemptId = mine.activeAttemptId
      } catch { /* non-fatal — fall through to start-attempt */ }

      if (!attemptId) {
        const r = await fetch(`${API}/api/exams/${examId}/start-attempt`, { method: 'POST', headers: h })
        const d = await r.json()
        if (!r.ok) {
          setErrorState({ code: d?.code || 'START_FAILED', message: d?.error || d?.message || t.errTitle })
          setInitializing(false)
          return
        }
        attemptId = d.attemptId
      }

      // Hydrate the authoritative attempt record (answers, flags) — §24/§26
      const ar = await fetch(`${API}/api/attempts/${attemptId}`, { headers: h })
      const ad = await ar.json()
      const attemptObj = ad?.attempt || ad
      setAttempt(attemptObj)

      const hydratedAnswers: Record<string, any> = {}
      const hydratedFlags = new Set<string>()
      const hydratedVisited = new Set<string>()
      const hydratedConfidence: Record<string, any> = {}
      ;(attemptObj?.answers || []).forEach((a: any) => {
        const qid = String(a.questionId)
        if (a.selectedOption !== null && a.selectedOption !== undefined) hydratedAnswers[qid] = a.selectedOption
        if (a.isMarkedForReview) hydratedFlags.add(qid)
        if (a.confidence) hydratedConfidence[qid] = a.confidence
        hydratedVisited.add(qid)
      })
      setAnswers(hydratedAnswers)
      setFlagged(hydratedFlags)
      setVisited(hydratedVisited)
      setConfidence(hydratedConfidence)

      // Questions (medium-aware, image-aware, subject-tagged) — §26
      const qr = await fetch(`${API}/api/exams/${examId}/questions`, { headers: h })
      const qd = await qr.json()
      if (!qr.ok) {
        setErrorState({ code: qd?.code || 'QUESTIONS_FAILED', message: qd?.message || t.errTitle })
        setInitializing(false)
        return
      }
      setQuestions(qd.questions || [])
      // F57 §1.7 — fetch per-exam fullscreenForce setting so admin can actually disable it (was ignored before, always forced)
      let fullscreenForce = true
      try {
        const fr = await fetch(`${API}/api/exams/${examId}`, { headers: h })
        const fd = await fr.json()
        if (typeof fd?.exam?.fullscreenForce === 'boolean') fullscreenForce = fd.exam.fullscreenForce
      } catch (e) { /* fail-safe: keep enforcement ON if this fetch fails */ }
      setExamMeta({
        sections: qd.sections || [],
        markingScheme: qd.markingScheme || { correct: 4, incorrect: -1, unattempted: 0 },
        duration: qd.duration || 200,
        title: qd.title || '',
        status: qd.status || '',
        fullscreenForce
      })

      // Accurate authoritative timer — §16 / avoids hardcoded 200-min default
      try {
        const tr = await fetch(`${API}/api/attempts/${attemptId}/timer`, { headers: h })
        const td = await tr.json()
        if (tr.ok) {
          setTimeLeft(typeof td.remainingSec === 'number' ? td.remainingSec : (qd.duration || 200) * 60)
          setTotalDurationSec(typeof td.totalDurationSec === 'number' ? td.totalDurationSec : (qd.duration || 200) * 60)
        } else {
          setTotalDurationSec((qd.duration || 200) * 60)
          setTimeLeft((qd.duration || 200) * 60)
        }
      } catch {
        setTotalDurationSec((qd.duration || 200) * 60)
        setTimeLeft((qd.duration || 200) * 60)
      }

      setInitializing(false)
    } catch (e: any) {
      setErrorState({ code: 'NETWORK', message: e?.message || t.errTitle })
      setInitializing(false)
    }
  }, [user, examId])

  useEffect(() => { if (user && examId) initAttempt() }, [user, examId])

  // ── §2.5 Mini webcam preview — reuses the permission already granted ──
  // ── on the Webcam Check page (Phase 5.2). If denied/unavailable, this ──
  // ── silently hides itself and never blocks the exam screen. ──────────
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 240, height: 180 }, audio: false })
        if (cancelled) { stream.getTracks().forEach(tr => tr.stop()); return }
        camStreamRef.current = stream
        if (videoRef.current) videoRef.current.srcObject = stream
        setCamReady(true)
      } catch (e) { setCamReady(false) }
    })()
    return () => {
      cancelled = true
      camStreamRef.current?.getTracks().forEach(tr => tr.stop())
      camStreamRef.current = null
    }
  }, [])

  // ── Anti-cheat: tab switch + window blur + fullscreen enforcement ──
  useEffect(() => {
    const logWarning = (type: string) => setWarningHistory(h => [{ type, at: new Date().toLocaleTimeString() }, ...h].slice(0, 15))

    const onVis = () => {
      if (document.hidden && attempt) {
        logWarning('Tab Switch')
        if (user && attempt?._id) {
          fetch(`${API}/api/anticheat/tab-switch`, {
            method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
            body: JSON.stringify({ attemptId: attempt._id, examId })
          }).then(r => r.json()).then(d => {
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit(true)
          }).catch(() => {
            setWarnings(w => { const next = w + 1; if (next >= 3) autoSubmit(true); return next })
          })
        }
      }
    }

    const onBlur = () => {
      if (attempt) {
        logWarning('Window Blur')
        if (user && attempt?._id) {
          fetch(`${API}/api/anticheat/window-blur`, {
            method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
            body: JSON.stringify({ attemptId: attempt._id, examId })
          }).then(r => r.json()).then(d => {
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit(true)
          }).catch(() => {})
        }
      }
    }

    const requestFS = () => { try { document.documentElement.requestFullscreen?.() } catch (e) {} }
    const onFsChange = () => {
      if (examMeta.fullscreenForce === false) return // F57 §1.7 — admin disabled fullscreen enforcement for this exam
      const isFs = !!document.fullscreenElement
      setFsCompliant(isFs)
      setFocusLocked(isFs)
      if (!isFs && attempt) {
        setShowFSWarning(true)
        logWarning('Fullscreen Exit')
        fsExitTimerRef.current = setTimeout(() => {
          if (user && attempt?._id) {
            fetch(`${API}/api/anticheat/fullscreen-exit`, {
              method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
              body: JSON.stringify({ attemptId: attempt._id, examId })
            }).then(r => r.json()).then(d => {
              if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
              if (d?.autoSubmitted) autoSubmit(true)
            }).catch(() => {})
          }
        }, 5000)
      } else {
        setShowFSWarning(false)
        if (fsExitTimerRef.current) { clearTimeout(fsExitTimerRef.current); fsExitTimerRef.current = null }
      }
    }

    if (examMeta.fullscreenForce !== false) requestFS()
    document.addEventListener('fullscreenchange', onFsChange)
    window.addEventListener('blur', onBlur)
    document.addEventListener('visibilitychange', onVis)
    return () => {
      document.removeEventListener('visibilitychange', onVis)
      document.removeEventListener('fullscreenchange', onFsChange)
      window.removeEventListener('blur', onBlur)
      if (fsExitTimerRef.current) clearTimeout(fsExitTimerRef.current)
    }
  }, [attempt, user, examId, examMeta.fullscreenForce])

  // ── Timer countdown (now driven by authoritative totalDurationSec) ──
  useEffect(() => {
    if (!attempt || locked) return
    const iv = setInterval(() => {
      setTimeLeft(tl => {
        if (tl <= 1) { clearInterval(iv); autoSubmit(true); return 0 }
        return tl - 1
      })
    }, 1000)
    return () => clearInterval(iv)
  }, [attempt, locked])

  // ── Auto-save every 30s (§ Auto-Save Answers) ──────────────
  const autoSave = useCallback(async () => {
    if (!attempt?._id || !user || locked) return
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/auto-save`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({
          answers: Object.entries(answers).map(([questionId, selectedOption]) => ({
            questionId, selectedOption, timeTaken: timeSpent[questionId] || 0, confidence: confidence[questionId] ?? null
          }))
        })
      })
      if (!r.ok) {
        const d = await r.json().catch(() => ({}))
        if (r.status === 403 && d?.code === 'ATTEMPT_LOCKED') setLocked(true)
      }
    } catch {}
  }, [attempt, answers, user, timeSpent, confidence, locked])

  useEffect(() => {
    if (!attempt || locked) return
    const iv = setInterval(() => autoSave(), 30000)
    return () => clearInterval(iv)
  }, [attempt, answers, autoSave])

  // ── §16 per-question time tracking: measure dwell time on each index ──
  useEffect(() => {
    questionEnterRef.current = Date.now()
    const enteredQ = questions[current]
    return () => {
      if (enteredQ) {
        const elapsed = Math.round((Date.now() - questionEnterRef.current) / 1000)
        if (elapsed > 0) setTimeSpent(ts => ({ ...ts, [enteredQ._id]: (ts[enteredQ._id] || 0) + elapsed }))
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [current, questions.length])

  // ── F59 §1/§8.1/§8.12 — reliable save: instant local UI update, then ──
  // ── network save. On failure (offline/network error) the answer is  ──
  // ── queued and auto-retried (flushQueue effect below) so nothing is ──
  // ── ever lost. On a 403 ATTEMPT_LOCKED response (§5/§13.2) the whole ──
  // ── screen locks immediately so the student can't keep "editing" an ──
  // ── attempt that the server has already closed. Uses `questionId` — ──
  // ── the verified real backend field name (attemptRoutes.js), not    ──
  // ── the shorthand `qId` used loosely in some spec text. ─────────────
  const persistAnswer = useCallback(async (qId: string, selectedOption: any, confidenceVal?: 'high' | 'medium' | 'low' | null) => {
    setVisited(v => new Set([...v, qId]))
    if (!attempt?._id || !user || locked) return
    const elapsedNow = Math.round((Date.now() - questionEnterRef.current) / 1000)
    const conf = confidenceVal !== undefined ? confidenceVal : (confidence[qId] ?? null)
    const payload = { selectedOption, timeTaken: elapsedNow, confidence: conf }
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/save-answer`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ questionId: qId, ...payload })
      })
      if (r.ok) {
        delete retryQueueRef.current[qId]
        setQueuedCount(Object.keys(retryQueueRef.current).length)
        setSavedFlash(qId)
        setTimeout(() => setSavedFlash(f => (f === qId ? null : f)), 900)
      } else {
        const d = await r.json().catch(() => ({}))
        if (r.status === 403 && d?.code === 'ATTEMPT_LOCKED') {
          setLocked(true)
          retryQueueRef.current = {}
          setQueuedCount(0)
        } else {
          retryQueueRef.current[qId] = payload
          setQueuedCount(Object.keys(retryQueueRef.current).length)
        }
      }
    } catch {
      // Network unreachable — queue for auto-retry, never lose the answer
      retryQueueRef.current[qId] = payload
      setQueuedCount(Object.keys(retryQueueRef.current).length)
    }
  }, [attempt, user, locked, confidence])

  // ── F59 §8.1/§8.12 — background flush of the offline/retry queue ──
  const flushQueue = useCallback(async () => {
    if (!attempt?._id || !user || locked) return
    const entries = Object.entries(retryQueueRef.current)
    if (entries.length === 0) return
    for (const [qId, payload] of entries) {
      try {
        const r = await fetch(`${API}/api/attempts/${attempt._id}/save-answer`, {
          method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
          body: JSON.stringify({ questionId: qId, ...payload })
        })
        if (r.ok) {
          delete retryQueueRef.current[qId]
        } else if (r.status === 403) {
          const d = await r.json().catch(() => ({}))
          if (d?.code === 'ATTEMPT_LOCKED') { setLocked(true); retryQueueRef.current = {} }
        }
      } catch { /* still offline — will retry next cycle */ }
    }
    setQueuedCount(Object.keys(retryQueueRef.current).length)
  }, [attempt, user, locked])

  useEffect(() => {
    const iv = setInterval(flushQueue, 5000)
    const onOnline = () => { setIsOnline(true); flushQueue() }
    const onOffline = () => setIsOnline(false)
    setIsOnline(typeof navigator !== 'undefined' ? navigator.onLine : true)
    window.addEventListener('online', onOnline)
    window.addEventListener('offline', onOffline)
    return () => {
      clearInterval(iv)
      window.removeEventListener('online', onOnline)
      window.removeEventListener('offline', onOffline)
    }
  }, [flushQueue])

  const selectOption = (question: any, letter: string) => {
    if (!question || locked) return
    const qId = question._id
    const prev = answers[qId]
    let nextVal: any
    if (question.type === 'MSQ') {
      const arr = Array.isArray(prev) ? [...prev] : []
      const idx = arr.indexOf(letter)
      if (idx >= 0) arr.splice(idx, 1); else arr.push(letter)
      nextVal = arr
    } else {
      // §8.4 Quick Change Answer — a new SCQ choice automatically replaces the old one
      nextVal = letter
    }
    setAnswers(a => ({ ...a, [qId]: nextVal }))
    persistAnswer(qId, nextVal)
  }

  // §6.1 Double-click deselect (SCQ only, optional accessibility behavior)
  const doubleClickDeselect = (question: any, letter: string) => {
    if (!question || locked || question.type === 'MSQ') return
    if (answers[question._id] === letter) clearResponse(question)
  }

  // §6.4 Integer validation — numeric-only input, inline error, blocked save until valid
  const setIntegerAnswer = (question: any, value: string) => {
    if (!question || locked) return
    const cleaned = value.replace(/(?!^-)[^0-9]/g, '')
    setAnswers(a => ({ ...a, [question._id]: cleaned }))
    if (cleaned && !/^-?\d+$/.test(cleaned)) {
      setIntegerError(e => ({ ...e, [question._id]: t.integerInvalid }))
    } else {
      setIntegerError(e => { const n = { ...e }; delete n[question._id]; return n })
    }
  }
  const commitIntegerAnswer = (question: any) => {
    if (!question || locked) return
    const val = answers[question._id]
    if (val !== undefined && val !== null && val !== '' && !/^-?\d+$/.test(String(val))) return
    persistAnswer(question._id, val === '' ? null : val)
  }

  const clearResponse = (question: any) => {
    if (!question || locked) return
    setAnswers(a => { const n = { ...a }; delete n[question._id]; return n })
    setIntegerError(e => { const n = { ...e }; delete n[question._id]; return n })
    persistAnswer(question._id, null)
  }

  // §8.5 Confidence Tag — toggle High/Medium/Low; preserves the existing answer untouched
  const setConfidenceTag = (question: any, level: 'high' | 'medium' | 'low') => {
    if (!question || locked) return
    const qId = question._id
    const newVal = confidence[qId] === level ? null : level
    setConfidence(c => ({ ...c, [qId]: newVal }))
    persistAnswer(qId, answers[qId] ?? null, newVal)
  }

  const toggleFlag = async (question: any) => {
    if (!question || locked) return
    const qId = question._id
    setFlagged(f => { const n = new Set(f); n.has(qId) ? n.delete(qId) : n.add(qId); return n })
    if (!attempt?._id || !user) return
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/bookmark`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ questionId: qId })
      })
      const d = await r.json().catch(() => ({}))
      if (r.ok && typeof d?.isMarkedForReview === 'boolean') {
        // reconcile with server truth in case of a race
        setFlagged(f => { const n = new Set(f); d.isMarkedForReview ? n.add(qId) : n.delete(qId); return n })
      } else if (r.status === 403 && d?.code === 'ATTEMPT_LOCKED') {
        setLocked(true)
      }
    } catch {}
  }

  const autoSubmit = async (isAuto: boolean = false) => {
    if (submitting) return
    setSubmitting(true)
    if (!attempt?._id || !user) { setSubmitting(false); return }
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/submit`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user!.token}` },
        body: JSON.stringify({ isAutoSubmit: isAuto })
      })
      const d = await r.json()
      if (r.ok) router.push(`/exam/${examId}/result?attemptId=${attempt._id}`)
    } catch {}
    finally { setSubmitting(false) }
  }

  // ── §17 Question Reporting (student-facing, does not touch answer state) ──
  const submitReport = async () => {
    const q = questions[current]
    if (!q || !reportReason.trim() || !user) return
    setReportSubmitting(true)
    try {
      const r = await fetch(`${API}/api/questions/${q._id}/report`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ reason: reportReason.trim() })
      })
      const d = await r.json()
      setReportMsg(r.ok ? t.reportSent : (d?.message || 'Error'))
    } catch {
      setReportMsg('Network error')
    } finally {
      setReportSubmitting(false)
      setShowReportModal(false)
      setReportReason('')
      setTimeout(() => setReportMsg(null), 4000)
    }
  }

  // ── §10 status derivation — generalized for MSQ arrays. §4.3/§7.4 ──
  // ── keeps "answered + flagged" as its OWN distinct state instead of ──
  // ── collapsing to just "flagged" (which used to hide the fact that ──
  // ── the question was actually answered). ──────────────────────────
  const getStatus = (qId: string): 'answered' | 'answered-flagged' | 'flagged' | 'unanswered' | 'unvisited' => {
    const ans = answers[qId]
    const hasAns = Array.isArray(ans) ? ans.length > 0 : (ans !== undefined && ans !== null && ans !== '')
    const isFlagged = flagged.has(qId)
    if (hasAns && isFlagged) return 'answered-flagged'
    if (hasAns) return 'answered'
    if (isFlagged) return 'flagged'
    if (visited.has(qId)) return 'unanswered'
    return 'unvisited'
  }

  // §6.2/§8.7 — colorblind-safe status icons shown alongside color
  const STATUS_ICON: Record<string, string> = { answered: '✓', 'answered-flagged': '✓⚑', flagged: '⚑', unanswered: '!', unvisited: '' }

  const goTo = (idx: number) => {
    setCurrent(idx)
    const qq = questions[idx]
    if (qq) setVisited(v => new Set([...v, qq._id]))
  }

  // ── §11 dynamic subject/section tabs — works for ANY competitive exam ──
  const subjects = useMemo(() => {
    const set = new Set<string>()
    questions.forEach(q => { if (q?.subject) set.add(q.subject) })
    return Array.from(set)
  }, [questions])

  const filteredIndices = useMemo(() => {
    if (selectedSubject === 'All') return questions.map((_, i) => i)
    return questions.map((q, i) => ({ q, i })).filter(x => x.q?.subject === selectedSubject).map(x => x.i)
  }, [questions, selectedSubject])

  const goRelative = (dir: 1 | -1) => {
    const pos = filteredIndices.indexOf(current)
    if (pos === -1) { goTo(Math.max(0, Math.min(questions.length - 1, current + dir))); return }
    const nextPos = pos + dir
    if (nextPos >= 0 && nextPos < filteredIndices.length) goTo(filteredIndices[nextPos])
  }

  const h = Math.floor(timeLeft / 3600), m = Math.floor((timeLeft % 3600) / 60), s = timeLeft % 60
  const fmt = (n: number) => String(n).padStart(2, '0')
  const timerPct = totalDurationSec ? (timeLeft / totalDurationSec) * 100 : 100
  const timerClass = timerPct > 33 ? 'timer-safe' : timerPct > 10 ? 'timer-warning' : 'timer-danger'

  const q = questions[current]
  const isMSQ = q?.type === 'MSQ'
  const isInteger = q?.type === 'Integer'
  const opts = (!isInteger && q) ? OPT_LETTERS : []

  const answeredCount = Object.values(answers).filter(v => Array.isArray(v) ? v.length > 0 : (v !== undefined && v !== null && v !== '')).length
  const totalTimeSpent = Object.values(timeSpent).reduce((a, b) => a + b, 0)
  const avgTimeSec = answeredCount > 0 ? Math.round(totalTimeSpent / Math.max(1, Object.keys(timeSpent).length)) : 0

  // ── Feature 32: Time Extension Socket Listener (fixed — was referencing ──
  // ── an undefined `socket`/`attemptIdRef`, which crashed this entire page ──
  // ── on every render. Now a real, guarded, self-contained connection. ──
  useEffect(() => {
    if (!attempt?._id || !user?.token) return
    let cancelled = false
    ;(async () => {
      try {
        const { io } = await import('socket.io-client')
        if (cancelled) return
        const sock = io(API || undefined, { auth: { token: user.token }, transports: ['websocket', 'polling'] })
        socketRef.current = sock
        const studentId = attempt?.studentId || user?.id || user?._id
        sock.on('connect', () => {
          if (studentId) sock.emit('join', `student:${studentId}`)
          if (attempt?._id) sock.emit('join', `attempt:${attempt._id}`)
        })
        sock.on('time:extend', (data: any) => {
          const extraSec = (data?.extraMinutes || 0) * 60
          if (data?.isUndo) {
            setTimeLeft(prev => Math.max(0, prev - Math.abs(extraSec)))
            setTotalDurationSec(prev => Math.max(0, prev - Math.abs(extraSec)))
            setTimeExtNotif(`Admin cancelled a time extension (${data.extraMinutes} min removed)`)
          } else {
            setTimeLeft(prev => prev + extraSec)
            setTotalDurationSec(prev => prev + extraSec)
            setTimeExtNotif(data?.message || `Admin has given you +${data?.extraMinutes} minutes`)
          }
          setTimeout(() => setTimeExtNotif(null), 8000)
        })
      } catch (e) { /* socket.io-client unavailable — feature degrades silently, page still works */ }
    })()
    return () => {
      cancelled = true
      try { socketRef.current?.disconnect() } catch {}
      socketRef.current = null
    }
  }, [attempt?._id, user?.token])

  if (loading || !mounted) {
    return <div style={{ minHeight: '100vh', background: '#000A18', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4D9FFF', fontFamily: 'Inter,sans-serif' }}>{t.loadingExam}</div>
  }

  if (initializing) {
    return <div style={{ minHeight: '100vh', background: '#000A18', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4D9FFF', fontFamily: 'Inter,sans-serif' }}>{t.loadingExam}</div>
  }

  if (errorState) {
    return (
      <div style={{ minHeight: '100vh', background: '#000A18', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
        <div style={{ maxWidth: 420, textAlign: 'center', color: '#E8F4FF', fontFamily: 'Inter,sans-serif' }}>
          <div style={{ fontSize: 44, marginBottom: 12 }}>⚠️</div>
          <div style={{ fontSize: 18, fontWeight: 800, marginBottom: 8 }}>{t.errTitle}</div>
          <div style={{ fontSize: 13, color: '#6B8BAF', marginBottom: 20 }}>{errorState.message}</div>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center' }}>
            <button onClick={() => router.push('/my-exams')} style={{ padding: '10px 18px', borderRadius: 10, border: '1px solid rgba(77,159,255,0.3)', background: 'transparent', color: '#E8F4FF', cursor: 'pointer' }}>{t.backToExams}</button>
            <button onClick={initAttempt} style={{ padding: '10px 18px', borderRadius: 10, border: 'none', background: 'linear-gradient(135deg,#4D9FFF,#0055CC)', color: '#fff', fontWeight: 700, cursor: 'pointer' }}>{t.retry}</button>
          </div>
        </div>
      </div>
    )
  }

  // ── theme colors — self-contained (this screen intentionally does not ──
  // ── depend on StudentShell so it stays reliable during a locked exam) ──
  const tm   = dark ? '#E8F4FF' : '#0F172A'
  const ts   = dark ? '#6B8BAF' : '#51607A'
  const card = dark ? 'rgba(0,22,40,0.85)' : 'rgba(255,255,255,0.92)'
  const bord = dark ? 'rgba(77,159,255,0.2)' : 'rgba(37,99,235,0.28)'
  const pageBg = dark ? '#000A18' : '#F4F7FB'
  const asideBg = dark ? 'rgba(0,10,24,0.9)' : 'rgba(255,255,255,0.96)'
  const headerBg = dark ? 'rgba(0,10,24,0.95)' : 'rgba(255,255,255,0.97)'

  return (
    <div style={{ minHeight: '100vh', background: pageBg, color: tm, fontFamily: 'Inter,sans-serif', display: 'flex', flexDirection: 'column' }}
      onContextMenu={e => e.preventDefault()}>
      <style>{`
        @keyframes pulse{0%,100%{opacity:.4}50%{opacity:1}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;}
        .tbtn.active{background:rgba(77,159,255,0.25);border-color:#4D9FFF;}
        .lb{padding:12px 24px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:14px;font-weight:700;cursor:pointer;transition:all 0.3s;}
        .lb:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(77,159,255,0.4);}
        select option{background:#001628;}
        .examAside{ transition:transform .3s ease; }
        .examMobileNavBtn{ display:none; }
        .imgZoomBtn{ position:absolute; top:6px; right:6px; background:rgba(0,0,0,0.6); color:#fff; border:none; border-radius:6px; padding:4px 8px; font-size:12px; cursor:pointer; }
        .examOption:not(.selected):hover{ border-color:#7db8ff !important; }
        @media (max-width:820px){
          .examAside{ position:fixed !important; top:62px; bottom:0; left:0; width:78vw; max-width:300px; transform:translateX(-105%); z-index:150; box-shadow:8px 0 30px rgba(0,0,0,.5); }
          .examAside.open{ transform:translateX(0); }
          .examMobileNavBtn{ display:flex; position:fixed; bottom:78px; right:18px; z-index:140; width:50px; height:50px; border-radius:50%; align-items:center; justify-content:center; background:linear-gradient(135deg,#4D9FFF,#0055CC); color:#fff; border:none; font-size:19px; box-shadow:0 6px 20px rgba(0,0,0,.4); cursor:pointer; }
          .examHeaderRow{ flex-wrap:wrap; height:auto !important; padding:8px 0 !important; gap:8px !important; }
        }
      `}</style>

      {/* Watermark — §12: opacity ~0.04, diagonal, tiled, non-selectable */}
      <div className="exam-watermark" style={{ color: dark ? 'rgba(77,159,255,0.04)' : 'rgba(37,99,235,0.05)', display: 'flex', flexWrap: 'wrap', alignContent: 'center', gap: '18vw 10vw', fontSize: 'clamp(10px,2vw,16px)' }}>
        {Array.from({ length: 9 }).map((_, i) => (
          <span key={i}>ProveRank • {lang === 'en' ? 'Student' : 'छात्र'}</span>
        ))}
      </div>

      {/* Mobile question-nav floating button */}
      <button className="examMobileNavBtn" onClick={() => setShowMobileNav(v => !v)}>🔢</button>
      {showMobileNav && <div onClick={() => setShowMobileNav(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 140 }} />}

      {/* ── HEADER — Desktop: full inline bar. Mobile: compact bar + ── */}
      {/* ── expandable tools panel (a distinct mobile-first design). ── */}
      <header style={{ background: headerBg, borderBottom: `1px solid ${bord}`, padding: '0 16px', position: 'sticky', top: 0, zIndex: 100, display: 'flex', flexDirection: 'column' }}>
        {!isMobile ? (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 56, gap: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <svg width={24} height={24} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_, i) => { const a = (Math.PI / 180) * (60 * i - 30); return `${32 + 26 * Math.cos(a)},${32 + 26 * Math.sin(a)}` }).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2" /><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
              <span style={{ fontFamily: 'Playfair Display,serif', fontWeight: 700, color: '#4D9FFF', fontSize: 15 }}>{examMeta.title || 'ProveRank'}</span>
              {examMeta.status && (
                <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: examMeta.status === 'live' ? '#3a1414' : '#123b1e', color: examMeta.status === 'live' ? '#ff8080' : '#7CFC9C' }}>
                  {examMeta.status === 'live' ? `🔴 ${t.live}` : `🕓 ${t.practice}`}
                </span>
              )}
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'rgba(77,159,255,0.08)', border: `1px solid ${bord}`, borderRadius: 10, padding: '8px 16px' }}>
              <span style={{ fontSize: 14 }}>⏱</span>
              <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: timerPct < 10 ? '#FF4757' : timerPct < 33 ? '#FFA502' : '#4D9FFF' }}>
                {fmt(h)}:{fmt(m)}:{fmt(s)}
              </span>
              <span style={{ color: ts, fontSize: 12 }}>{t.timeLeft}</span>
            </div>

            <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
              <button onClick={toggleLang} style={{ padding: '5px 10px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, cursor: 'pointer', fontSize: 11 }}>{lang === 'hi' ? 'EN' : 'हिं'}</button>
              <button onClick={toggleTheme} style={{ padding: '5px 10px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, cursor: 'pointer', fontSize: 12 }}>{dark ? '☀️' : '🌙'}</button>
              {warnings > 0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}
              {!isOnline && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: '#3a1414', color: '#ff8080' }}>📡 {t.offline}</span>}
              {queuedCount > 0 && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: '#3a2a00', color: '#f2d38a' }}>⏳ {queuedCount}</span>}
              <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: integrityImpact === 'none' ? '#123b1e' : integrityImpact === 'low' ? '#3a2a00' : integrityImpact === 'medium' ? '#3a2200' : '#3a1414', color: integrityImpact === 'none' ? '#7CFC9C' : integrityImpact === 'low' ? '#f2d38a' : integrityImpact === 'medium' ? '#ffb066' : '#ff8080' }}>
                🛡️ {integrityImpact}
              </span>
              <button className="lb" style={{ background: 'linear-gradient(135deg,#FF4757,#CC2233)', boxShadow: '0 4px 15px rgba(255,71,87,0.3)' }} onClick={() => setShowSubmit(true)}>
                {t.submit}
              </button>
            </div>
          </div>
        ) : (
          <>
            {/* ── Mobile header: compact single row — logo · timer · ⚙ · submit ── */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 54, gap: 8 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, minWidth: 0 }}>
                <svg width={22} height={22} viewBox="0 0 64 64" style={{ flexShrink: 0 }}><polygon points={[...Array(6)].map((_, i) => { const a = (Math.PI / 180) * (60 * i - 30); return `${32 + 26 * Math.cos(a)},${32 + 26 * Math.sin(a)}` }).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2" /><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
                {examMeta.status && (
                  <span style={{ fontSize: 9, padding: '2px 6px', borderRadius: 20, background: examMeta.status === 'live' ? '#3a1414' : '#123b1e', color: examMeta.status === 'live' ? '#ff8080' : '#7CFC9C', flexShrink: 0 }}>
                    {examMeta.status === 'live' ? '🔴' : '🕓'}
                  </span>
                )}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5, background: 'rgba(77,159,255,0.08)', border: `1px solid ${bord}`, borderRadius: 8, padding: '5px 10px', flexShrink: 0 }}>
                <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 15, fontWeight: 700, color: timerPct < 10 ? '#FF4757' : timerPct < 33 ? '#FFA502' : '#4D9FFF' }}>
                  {fmt(h)}:{fmt(m)}:{fmt(s)}
                </span>
              </div>
              <button onClick={() => setShowMobileTools(v => !v)} style={{ width: 34, height: 34, borderRadius: 10, border: `1px solid ${bord}`, background: showMobileTools ? 'rgba(77,159,255,0.15)' : 'transparent', color: tm, fontSize: 15, flexShrink: 0 }}>⚙</button>
              <button style={{ padding: '7px 12px', borderRadius: 10, border: 'none', background: 'linear-gradient(135deg,#FF4757,#CC2233)', color: '#fff', fontWeight: 700, fontSize: 12, flexShrink: 0 }} onClick={() => setShowSubmit(true)}>
                {t.submit}
              </button>
            </div>
            {/* ── Mobile expandable tools panel ── */}
            {showMobileTools && (
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 0 12px' }}>
                <button onClick={toggleLang} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 12 }}>{lang === 'hi' ? 'EN' : 'हिं'}</button>
                <button onClick={toggleTheme} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 13 }}>{dark ? '☀️' : '🌙'}</button>
                <button onClick={() => setFontSize(f => Math.max(13, f - 1))} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 12 }}>A−</button>
                <button onClick={() => setFontSize(f => Math.min(22, f + 1))} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 12 }}>A+</button>
                {warnings > 0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}
                {!isOnline && <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: '#3a1414', color: '#ff8080' }}>📡 {t.offline}</span>}
                {queuedCount > 0 && <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: '#3a2a00', color: '#f2d38a' }}>⏳ {queuedCount}</span>}
                <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: focusLocked ? '#123b1e' : '#3a1414', color: focusLocked ? '#7CFC9C' : '#ff8080' }}>
                  {focusLocked ? '🔒 Locked' : '🔓 Lost'}
                </span>
                <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: integrityImpact === 'none' ? '#123b1e' : integrityImpact === 'low' ? '#3a2a00' : integrityImpact === 'medium' ? '#3a2200' : '#3a1414', color: integrityImpact === 'none' ? '#7CFC9C' : integrityImpact === 'low' ? '#f2d38a' : integrityImpact === 'medium' ? '#ffb066' : '#ff8080' }}>
                  🛡️ {integrityImpact}
                </span>
              </div>
            )}
          </>
        )}
        <div style={{ height: 4, background: 'rgba(77,159,255,0.1)' }}>
          <div className={timerClass} style={{ height: '100%', width: `${Math.max(0, Math.min(100, timerPct))}%`, borderRadius: 2, transition: 'width 1s linear' }} />
        </div>
      </header>

      {/* ── BODY ────────────────────────────────────────────────── */}
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* LEFT: Section tabs + legend + Nav Grid (5-column, §10) */}
        <aside className={`examAside ${showMobileNav ? 'open' : ''}`} style={{ width: 240, background: asideBg, borderRight: `1px solid ${bord}`, flexShrink: 0, display: 'flex', flexDirection: 'column' }}>
          {/* Scrollable section: tabs, legend, counter, nav grid — §1.9 §1.11 §1.12 */}
          <div style={{ flex: 1, overflowY: 'auto', padding: '16px 12px', minHeight: 0 }}>
            <div style={{ display: 'flex', gap: 6, marginBottom: 16, flexWrap: 'wrap' }}>
              <button className={`tbtn ${selectedSubject === 'All' ? 'active' : ''}`} style={{ fontSize: 11, padding: '4px 8px' }} onClick={() => setSelectedSubject('All')}>{t.all}</button>
              {subjects.map(sub => (
                <button key={sub} className={`tbtn ${selectedSubject === sub ? 'active' : ''}`} style={{ fontSize: 11, padding: '4px 8px', borderColor: subjectColor(sub) }} onClick={() => setSelectedSubject(sub)}>{sub}</button>
              ))}
            </div>

            {/* §1.9 — explicit question counter in side panel */}
            <div style={{ fontFamily: 'Playfair Display,serif', fontWeight: 700, fontSize: 14, color: tm, marginBottom: 12, textAlign: 'center', padding: '6px 0', border: `1px solid ${bord}`, borderRadius: 8 }}>
              {t.question} {current + 1} / {questions.length || 0}
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 16 }}>
              {[['answered', '#00C48C', t.answered, '✓'], ['unanswered', '#FF4757', t.unanswered, '!'], ['flagged', '#A855F7', t.flagged, '⚑'], ['answered-flagged', 'linear-gradient(135deg,#00C48C 50%,#A855F7 50%)', `${t.answered} + ${t.flagged}`, '✓⚑'], ['unvisited', 'rgba(77,159,255,0.1)', t.notVisited, '']].map(([cls, clr, lbl, ic]) => (
                <div key={String(cls)} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: ts }}>
                  <div style={{ width: 12, height: 12, borderRadius: 3, background: String(clr), display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 7, color: '#fff' }}>{ic}</div>
                  {lbl}
                </div>
              ))}
            </div>

            <div style={{ fontSize: 11, color: ts, marginBottom: 8 }}>{t.avgTime}: {avgTimeSec}s</div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 4 }}>
              {questions.map((q2: any, i: number) => {
                const st2 = getStatus(q2._id)
                const isCombined = st2 === 'answered-flagged'
                return (
                  <div key={q2._id || i}
                    className={`qnum ${isCombined ? '' : st2} ${i === current ? 'current' : ''}`}
                    style={isCombined && i !== current ? { background: 'linear-gradient(135deg,#00C48C 50%,#A855F7 50%)', color: '#fff', position: 'relative' } : { position: 'relative' }}
                    onClick={() => { goTo(i); setShowMobileNav(false) }} title={`${q2.subject || ''} — ${st2}`}>
                    {i + 1}
                    {STATUS_ICON[st2] && i !== current && (
                      <span style={{ position: 'absolute', top: -4, right: -4, fontSize: 8, background: '#00121F', border: '1px solid rgba(255,255,255,0.4)', borderRadius: '50%', width: 13, height: 13, display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 1, color: '#fff' }}>
                        {STATUS_ICON[st2]}
                      </span>
                    )}
                  </div>
                )
              })}
            </div>
          </div>

          {/* §2.5 §18.5 — Mini webcam, fixed at bottom of side panel, non-scrolling */}
          <div style={{ padding: 10, borderTop: `1px solid ${bord}`, flexShrink: 0 }}>
            <div style={{ position: 'relative', borderRadius: 10, overflow: 'hidden', border: `1px solid ${bord}`, background: '#000', height: 90 }}>
              <video ref={videoRef} autoPlay muted playsInline style={{ width: '100%', height: '100%', objectFit: 'cover', display: camReady ? 'block' : 'none' }} />
              {!camReady && (
                <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#556', fontSize: 20 }}>📷</div>
              )}
              <span style={{ position: 'absolute', top: 6, left: 6, display: 'flex', alignItems: 'center', gap: 4, fontSize: 9, fontWeight: 700, color: '#fff', background: 'rgba(0,0,0,0.55)', padding: '2px 7px', borderRadius: 20 }}>
                <span style={{ width: 6, height: 6, borderRadius: '50%', background: camReady ? '#FF4757' : '#666', animation: camReady ? 'pulse 1.4s infinite' : 'none' }} />
                {camReady ? 'REC' : 'OFF'}
              </span>
              {!isOnline && (
                <span style={{ position: 'absolute', bottom: 6, left: 6, fontSize: 9, fontWeight: 700, color: '#fff', background: 'rgba(255,71,87,0.85)', padding: '2px 7px', borderRadius: 20 }}>📡 {t.offline}</span>
              )}
              {queuedCount > 0 && (
                <span style={{ position: 'absolute', bottom: 6, right: 6, fontSize: 9, fontWeight: 700, color: '#fff', background: 'rgba(255,165,2,0.85)', padding: '2px 7px', borderRadius: 20 }}>⏳ {queuedCount}</span>
              )}
            </div>
          </div>
        </aside>

        {/* RIGHT: Question + Options */}
        <main className="examMain" style={{ flex: 1, overflowY: 'auto', padding: isMobile ? '14px 14px 100px' : '24px' }}>
          {/* ── Mobile-only: horizontal-scroll subject strip (desktop uses the sidebar tabs) ── */}
          {isMobile && subjects.length > 0 && (
            <div style={{ display: 'flex', gap: 6, overflowX: 'auto', marginBottom: 14, paddingBottom: 4, WebkitOverflowScrolling: 'touch' }}>
              <button className={`tbtn ${selectedSubject === 'All' ? 'active' : ''}`} style={{ fontSize: 12, padding: '6px 12px', flexShrink: 0 }} onClick={() => setSelectedSubject('All')}>{t.all}</button>
              {subjects.map(sub => (
                <button key={sub} className={`tbtn ${selectedSubject === sub ? 'active' : ''}`} style={{ fontSize: 12, padding: '6px 12px', flexShrink: 0, borderColor: subjectColor(sub) }} onClick={() => setSelectedSubject(sub)}>{sub}</button>
              ))}
            </div>
          )}

          {!isMobile && (
            <div style={{ display: 'flex', gap: 8, marginBottom: 16, flexWrap: 'wrap', alignItems: 'center' }}>
              <span style={{ fontSize: 11, color: ts }}>{t.fontSmaller}</span>
              <button onClick={() => setFontSize(f => Math.max(13, f - 1))} className="tbtn" style={{ padding: '2px 10px', fontSize: 12 }}>A−</button>
              <button onClick={() => setFontSize(f => Math.min(22, f + 1))} className="tbtn" style={{ padding: '2px 10px', fontSize: 12 }}>A+</button>
              <span style={{ fontSize: 11, color: ts }}>{fontSize}px</span>
            </div>
          )}

          {/* Question Card */}
          <div style={{ background: card, border: `1px solid ${bord}`, borderRadius: isMobile ? 14 : 16, padding: isMobile ? '18px' : '28px', marginBottom: isMobile ? 14 : 20, minHeight: isMobile ? 120 : 200, backdropFilter: 'blur(12px)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: isMobile ? 10 : 16, flexWrap: 'wrap', gap: 8 }}>
              <span style={{ color: '#4D9FFF', fontWeight: 700, fontSize: isMobile ? 12 : 14 }}>{t.question} {current + 1} / {questions.length}</span>
              {q?.subject && (
                <span style={{ fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 20, background: `${subjectColor(q.subject)}22`, color: subjectColor(q.subject) }}>{q.subject}</span>
              )}
              <span className="badge badge-blue">+{examMeta.markingScheme?.correct ?? 4} / {examMeta.markingScheme?.incorrect ?? -1}</span>
            </div>

            {q ? (
              <div
                style={{ fontSize, lineHeight: 1.7, color: tm, fontFamily: 'Inter,sans-serif' }}
                dangerouslySetInnerHTML={{ __html: renderLatex(lang === 'hi' && q.hindiText ? q.hindiText : q.text) }}
              />
            ) : (
              <div style={{ color: ts }}>—</div>
            )}

            {q && (q.image || q.imageUrl) && (
              <div style={{ position: 'relative', display: 'inline-block', marginTop: 16 }}>
                <img src={q.image || q.imageUrl} alt="Question" style={{ maxWidth: '100%', borderRadius: 8, display: 'block' }} />
                <button className="imgZoomBtn" onClick={(e) => { e.stopPropagation(); setZoomImg(q.image || q.imageUrl) }}>🔍</button>
              </div>
            )}
          </div>

          {isMobile && (
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginBottom: 10 }}>
              <button onClick={() => setFontSize(f => Math.max(13, f - 1))} className="tbtn" style={{ padding: '4px 12px', fontSize: 13 }}>A−</button>
              <button onClick={() => setFontSize(f => Math.min(22, f + 1))} className="tbtn" style={{ padding: '4px 12px', fontSize: 13 }}>A+</button>
            </div>
          )}

          {/* §6.5/§8.1 Save status strip — Saved / Queued (offline) / Offline indicator */}
          {q && (savedFlash === q._id || retryQueueRef.current[q._id] || !isOnline) && (
            <div style={{ display: 'flex', gap: 8, marginBottom: 8, fontSize: 11, fontWeight: 700 }}>
              {savedFlash === q._id && <span style={{ color: '#00C48C' }}>✓ {t.saved}</span>}
              {retryQueueRef.current[q._id] && <span style={{ color: '#FFA502' }}>⏳ {t.queued}</span>}
              {!isOnline && <span style={{ color: '#FF4757' }}>📡 {t.offline}</span>}
            </div>
          )}

          {/* §5 Locked banner — attempt already submitted/closed server-side */}
          {locked && (
            <div style={{ background: 'rgba(255,71,87,0.12)', border: '1px solid rgba(255,71,87,0.4)', borderRadius: 10, padding: '12px 16px', marginBottom: 14, fontSize: 12, color: '#FF8080', fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, flexWrap: 'wrap' }}>
              <span>🔒 {t.lockedMsg}</span>
              <button onClick={() => router.push(`/exam/${examId}/result?attemptId=${attempt?._id || ''}`)} style={{ padding: '6px 14px', borderRadius: 8, border: '1px solid rgba(255,71,87,0.5)', background: 'rgba(255,71,87,0.15)', color: '#FF8080', fontWeight: 700, fontSize: 11, cursor: 'pointer', flexShrink: 0 }}>
                {t.viewResults}
              </button>
            </div>
          )}

          {/* Options — SCQ/MSQ (OMR bubble, bigger touch targets on mobile) or Integer input */}
          {isInteger ? (
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 13, color: ts, marginBottom: 8 }}>{t.integerHint}</div>
              <input
                type="text"
                inputMode="numeric"
                disabled={locked}
                value={q ? (answers[q._id] ?? '') : ''}
                onChange={e => setIntegerAnswer(q, e.target.value)}
                onBlur={() => commitIntegerAnswer(q)}
                style={{ width: '100%', maxWidth: isMobile ? '100%' : 260, padding: isMobile ? '16px 18px' : '12px 16px', borderRadius: 10, border: `1.5px solid ${(q && integerError[q._id]) ? '#FF4757' : bord}`, background: dark ? 'rgba(0,22,40,0.5)' : '#fff', color: tm, fontSize: 17, opacity: locked ? 0.6 : 1 }}
              />
              {q && integerError[q._id] && <div style={{ color: '#FF4757', fontSize: 11, marginTop: 6 }}>⚠ {integerError[q._id]}</div>}
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: isMobile ? 10 : 12, marginBottom: 20, opacity: locked ? 0.6 : 1, pointerEvents: locked ? 'none' : 'auto' }}>
              {isMSQ && (
                <div style={{ fontSize: 12, fontWeight: 700, color: '#4D9FFF' }}>
                  {Array.isArray(answers[q?._id]) ? answers[q._id].length : 0} {t.optionsSelected}
                </div>
              )}
              {opts.map(opt => {
                const optIdx = OPT_LETTERS.indexOf(opt)
                const optText = (lang === 'hi' && q?.hindiOptions && q.hindiOptions[optIdx]) ? q.hindiOptions[optIdx] : ((q?.options && q.options[optIdx]) || `Option ${opt}`)
                const optImg = q?.optionImages && q.optionImages[optIdx]
                const curAns = q ? answers[q._id] : undefined
                const isSelected = q && (Array.isArray(curAns) ? curAns.includes(opt) : curAns === opt)
                return (
                  <div key={opt}
                    className={`examOption ${isSelected ? 'selected' : ''}`}
                    onClick={() => q && selectOption(q, opt)}
                    onDoubleClick={() => q && doubleClickDeselect(q, opt)}
                    style={{ display: 'flex', alignItems: 'center', gap: 14, padding: isMobile ? '18px 18px' : '14px 20px', minHeight: isMobile ? 30 : undefined, borderRadius: 12, border: `1.5px solid ${isSelected ? '#4D9FFF' : bord}`, background: isSelected ? 'rgba(77,159,255,0.1)' : (dark ? 'rgba(0,22,40,0.5)' : '#fff'), cursor: locked ? 'default' : 'pointer', transition: 'all .2s' }}>
                    <div className={`omr-bubble ${isSelected ? 'selected' : ''}`} style={{ borderColor: isSelected ? '#4D9FFF' : bord, color: isSelected ? '#fff' : ts, flexShrink: 0, width: isMobile ? 34 : undefined, height: isMobile ? 34 : undefined }}>
                      {opt}
                    </div>
                    <span style={{ color: isSelected ? tm : ts, fontSize: isMobile ? 16 : 15, flex: 1 }} dangerouslySetInnerHTML={{ __html: renderLatex(optText) }} />
                    {optImg && (
                      <div style={{ position: 'relative', flexShrink: 0 }}>
                        <img src={optImg} alt={`Option ${opt}`} style={{ width: 70, height: 70, objectFit: 'cover', borderRadius: 8 }} />
                        <button className="imgZoomBtn" style={{ top: 2, right: 2, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); setZoomImg(optImg) }}>🔍</button>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}

          {/* §8.5 Confidence Tag — optional, does not affect scoring, purely self-reported */}
          {q && !locked && (answers[q._id] !== undefined && answers[q._id] !== null && answers[q._id] !== '') && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 11, color: ts }}>{t.confidenceLabel}:</span>
              {(['low', 'medium', 'high'] as const).map(lvl => (
                <button key={lvl} onClick={() => setConfidenceTag(q, lvl)}
                  style={{ padding: '4px 12px', borderRadius: 20, fontSize: 11, fontWeight: 700, cursor: 'pointer', border: `1px solid ${confidence[q._id] === lvl ? (lvl === 'high' ? '#00C48C' : lvl === 'medium' ? '#FFA502' : '#FF4757') : bord}`, background: confidence[q._id] === lvl ? (lvl === 'high' ? 'rgba(0,196,140,0.15)' : lvl === 'medium' ? 'rgba(255,165,2,0.15)' : 'rgba(255,71,87,0.15)') : 'transparent', color: confidence[q._id] === lvl ? (lvl === 'high' ? '#00C48C' : lvl === 'medium' ? '#FFA502' : '#FF4757') : ts }}>
                  {lvl === 'high' ? t.confidenceHigh : lvl === 'medium' ? t.confidenceMed : t.confidenceLow}
                </button>
              ))}
            </div>
          )}

          {/* Action Buttons — Desktop: inline row. Mobile: report/report-only here, ── */}
          {/* Prev/Next/Mark/Clear move to the fixed bottom bar for one-thumb reach. ── */}
          {!isMobile ? (
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <button className="tbtn" disabled={locked} style={{ color: '#A855F7', borderColor: 'rgba(168,85,247,0.4)', opacity: locked ? 0.5 : 1 }} onClick={() => toggleFlag(q)}>
                🔖 {q && flagged.has(q._id) ? t.unmarkReview : t.markReview}
              </button>
              <button className="tbtn" disabled={locked} style={{ opacity: locked ? 0.5 : 1 }} onClick={() => clearResponse(q)}>🗑 {t.clearResp}</button>
              <button className="tbtn" style={{ color: '#FFA502', borderColor: 'rgba(255,165,2,0.4)' }} onClick={() => setShowReportModal(true)}>🚩 {t.report}</button>
              <div style={{ flex: 1 }} />
              <button className="tbtn" onClick={() => goRelative(-1)} disabled={current === 0}>← {t.prev}</button>
              <button className="lb" disabled={locked} style={{ opacity: locked ? 0.6 : 1 }} onClick={() => goRelative(1)}>{t.saveNext} →</button>
            </div>
          ) : (
            <button className="tbtn" style={{ color: '#FFA502', borderColor: 'rgba(255,165,2,0.4)', width: '100%' }} onClick={() => setShowReportModal(true)}>🚩 {t.report}</button>
          )}
        </main>

        {/* ── §2.7 Mobile-only sticky bottom action bar — one-thumb reachable ── */}
        {isMobile && q && (
          <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, background: headerBg, borderTop: `1px solid ${bord}`, display: 'flex', alignItems: 'center', padding: '10px 12px', gap: 8, zIndex: 130, boxShadow: '0 -8px 24px rgba(0,0,0,0.35)' }}>
            <button onClick={() => toggleFlag(q)} disabled={locked} style={{ width: 46, height: 46, borderRadius: 12, border: `1.5px solid rgba(168,85,247,0.5)`, background: flagged.has(q._id) ? 'rgba(168,85,247,0.2)' : 'transparent', color: '#A855F7', fontSize: 18, flexShrink: 0, opacity: locked ? 0.5 : 1 }}>🔖</button>
            <button onClick={() => clearResponse(q)} disabled={locked} style={{ width: 46, height: 46, borderRadius: 12, border: `1.5px solid ${bord}`, background: 'transparent', color: tm, fontSize: 17, flexShrink: 0, opacity: locked ? 0.5 : 1 }}>🗑</button>
            <button onClick={() => goRelative(-1)} disabled={current === 0} style={{ flex: 1, height: 46, borderRadius: 12, border: `1.5px solid ${bord}`, background: 'transparent', color: tm, fontWeight: 700, fontSize: 13, opacity: current === 0 ? 0.4 : 1 }}>← {t.prev}</button>
            <button onClick={() => goRelative(1)} disabled={locked} style={{ flex: 1.6, height: 46, borderRadius: 12, border: 'none', background: 'linear-gradient(135deg,#4D9FFF,#0055CC)', color: '#fff', fontWeight: 700, fontSize: 13, opacity: locked ? 0.6 : 1 }}>{t.saveNext} →</button>
          </div>
        )}
      </div>

      {/* ── Submit Modal ─────────────────────────────────────────── */}
      {showSubmit && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200, backdropFilter: 'blur(4px)' }}>
          <div style={{ background: 'rgba(0,22,40,0.95)', border: `1px solid ${bord}`, borderRadius: 20, padding: '36px', maxWidth: 440, width: '90%', textAlign: 'center' }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>📤</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, marginBottom: 12, color: '#fff' }}>{t.confirm}</h2>
            <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginBottom: 20 }}>
              <div><div style={{ fontFamily: 'Playfair Display,serif', fontSize: 28, fontWeight: 800, color: '#00C48C' }}>{answeredCount}</div><div style={{ color: '#8DA2C0', fontSize: 12 }}>{t.answered}</div></div>
              <div><div style={{ fontFamily: 'Playfair Display,serif', fontSize: 28, fontWeight: 800, color: '#FF4757' }}>{questions.length - answeredCount}</div><div style={{ color: '#8DA2C0', fontSize: 12 }}>{t.unanswered}</div></div>
              <div><div style={{ fontFamily: 'Playfair Display,serif', fontSize: 28, fontWeight: 800, color: '#A855F7' }}>{flagged.size}</div><div style={{ color: '#8DA2C0', fontSize: 12 }}>{t.flagged}</div></div>
            </div>
            <p style={{ color: '#8DA2C0', fontSize: 14, marginBottom: 24 }}>{t.subWarn}</p>
            <div style={{ display: 'flex', gap: 12 }}>
              <button onClick={() => setShowSubmit(false)} style={{ flex: 1, padding: 14, borderRadius: 10, border: `1px solid ${bord}`, background: 'transparent', color: '#8DA2C0', cursor: 'pointer', fontFamily: 'Inter,sans-serif', fontSize: 14 }}>{t.cancelSub}</button>
              <button className="lb" disabled={submitting} onClick={() => autoSubmit(false)} style={{ flex: 1, background: 'linear-gradient(135deg,#FF4757,#CC2233)' }}>
                {submitting ? '◌ ...' : `✓ ${t.confirmSub}`}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Fullscreen Exit Warning Modal ── */}
      {showFSWarning && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 300, backdropFilter: 'blur(4px)' }}>
          <div style={{ background: 'rgba(30,5,5,0.97)', border: '1px solid #FF4757', borderRadius: 20, padding: '32px', maxWidth: 400, width: '90%', textAlign: 'center' }}>
            <div style={{ fontSize: 44, marginBottom: 12 }}>⚠️</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 19, fontWeight: 700, color: '#FF4757', marginBottom: 10 }}>{lang === 'en' ? 'Fullscreen Exited!' : 'फुलस्क्रीन बंद हो गया!'}</h2>
            <p style={{ color: '#ddd', fontSize: 13, marginBottom: 20 }}>{lang === 'en' ? 'You must stay in fullscreen during the exam. Return now to avoid a warning.' : 'परीक्षा के दौरान फुलस्क्रीन में रहना अनिवार्य है। चेतावनी से बचने के लिए तुरंत वापस लौटें।'}</p>
            <button onClick={() => document.documentElement.requestFullscreen?.()} style={{ width: '100%', padding: 14, borderRadius: 10, border: 'none', background: 'linear-gradient(135deg,#4D9FFF,#0055CC)', color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer' }}>
              {lang === 'en' ? '↩ Return to Fullscreen' : '↩ फुलस्क्रीन पर लौटें'}
            </button>
          </div>
        </div>
      )}

      {/* ── Feature 32: Time Extension Notification ── */}
      {timeExtNotif && (
        <div style={{ position: 'fixed', top: 20, right: 20, zIndex: 9999, background: 'linear-gradient(135deg,rgba(22,35,56,0.98),rgba(15,23,42,0.98))', border: '1px solid rgba(167,139,250,0.6)', borderRadius: 14, padding: '14px 20px', maxWidth: 320, boxShadow: '0 0 30px rgba(167,139,250,0.25)', animation: 'slideInRight 0.3s ease' }}>
          <div style={{ fontWeight: 700, fontSize: 13, color: '#a78bfa', marginBottom: 4 }}>⏱️ Extra Time Granted</div>
          <div style={{ fontSize: 12, color: '#e2e8f0' }}>{timeExtNotif}</div>
          <style>{'@keyframes slideInRight{from{transform:translateX(120%);opacity:0}to{transform:translateX(0);opacity:1}}'}</style>
        </div>
      )}

      {/* ── §17 Report Modal ── */}
      {showReportModal && (
        <div onClick={() => setShowReportModal(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 250, padding: 16 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, border: `1px solid ${bord}`, borderRadius: 16, padding: 22, maxWidth: 420, width: '100%' }}>
            <div style={{ fontWeight: 800, color: tm, marginBottom: 10 }}>🚩 {t.reportTitle}</div>
            <textarea value={reportReason} onChange={e => setReportReason(e.target.value)} placeholder={t.reportPlaceholder}
              style={{ width: '100%', minHeight: 100, padding: 12, borderRadius: 10, border: `1px solid ${bord}`, background: dark ? 'rgba(0,22,40,0.5)' : '#fff', color: tm, fontSize: 13, resize: 'vertical' }} />
            <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
              <button onClick={() => setShowReportModal(false)} style={{ flex: 1, padding: 12, borderRadius: 10, border: `1px solid ${bord}`, background: 'transparent', color: ts, cursor: 'pointer' }}>{t.cancelSub}</button>
              <button disabled={!reportReason.trim() || reportSubmitting} onClick={submitReport} className="lb" style={{ flex: 1, opacity: (!reportReason.trim() || reportSubmitting) ? 0.5 : 1 }}>{t.reportSubmit}</button>
            </div>
          </div>
        </div>
      )}
      {reportMsg && (
        <div style={{ position: 'fixed', bottom: 20, left: '50%', transform: 'translateX(-50%)', background: '#123b1e', color: '#7CFC9C', padding: '10px 20px', borderRadius: 20, fontSize: 13, zIndex: 9999 }}>{reportMsg}</div>
      )}

      {/* ── §15 Image Zoom / Lightbox ── */}
      {zoomImg && (
        <div onClick={() => setZoomImg(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.9)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 400, padding: 20, cursor: 'zoom-out' }}>
          <img src={zoomImg} alt="Zoomed" style={{ maxWidth: '95%', maxHeight: '90%', borderRadius: 8 }} />
          <button onClick={() => setZoomImg(null)} style={{ position: 'absolute', top: 20, right: 20, background: 'rgba(255,255,255,0.15)', color: '#fff', border: 'none', borderRadius: '50%', width: 40, height: 40, fontSize: 18, cursor: 'pointer' }}>✕</button>
        </div>
      )}
    </div>
  )
}
FILEEOF8
echo "attempt/page.tsx updated ✅"

echo ""
echo "=== DONE — Now: pkill -f node 2>/dev/null; cd ~/workspace && node src/index.js ==="
echo "=== Then: cd ~/workspace/frontend && rm -rf .next && npm run build (or npm run dev) ==="
