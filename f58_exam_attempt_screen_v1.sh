#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════
# F58 — Exam Attempt: Question Display & Navigation Core
# ProveRank | Full implementation + critical bug fixes
# Run from: ~/workspace
# ═══════════════════════════════════════════════════════════════════════

echo "=================================================="
echo "F58 — Exam Attempt Screen — Implementation Starting"
echo "=================================================="

# ── Safety backups (Rule H1 — never lose existing code) ─────────────────
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p backups/f58_$TS
cp src/routes/examFlow.js backups/f58_$TS/examFlow.js.bak 2>/dev/null || echo "  (examFlow.js not found at src/routes — verify path before continuing)"
cp "frontend/app/exam/[examId]/attempt/page.tsx" backups/f58_$TS/attempt_page.tsx.bak 2>/dev/null || echo "  (attempt page.tsx not found — verify path before continuing)"
echo "Backups saved to backups/f58_$TS/"

# ── 1) BACKEND — add GET /api/exams/:examId/questions (full file rewrite) ──
cat > src/routes/examFlow.js << 'BACKENDEOF'
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
  if (exam.assignmentType === 'series' && exam.testSeriesId) {
    return enrollment.seriesIds.includes(String(exam.testSeriesId));
  }
  const hasBatchTarget = !!exam.batch || (exam.multiBatch && exam.multiBatch.length > 0);
  if (hasBatchTarget) {
    const targets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean).map(String);
    return targets.some(t => enrollment.batchIds.includes(t) || enrollment.batchNames.includes(t));
  }
  return false; // F52 fix — no restriction configured means NOT linked to any enrolled batch/series, so it must NOT show on My Exams (only enrolled-batch/series exams are visible)
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
BACKENDEOF

echo "Backend: src/routes/examFlow.js rewritten."
node -c src/routes/examFlow.js && echo "Backend syntax OK" || (echo "BACKEND SYNTAX ERROR — restoring backup"; cp backups/f58_$TS/examFlow.js.bak src/routes/examFlow.js; exit 1)

# ── 2) FRONTEND — full rewrite of the exam attempt screen ───────────────
mkdir -p "frontend/app/exam/[examId]/attempt"
cat > "frontend/app/exam/[examId]/attempt/page.tsx" << 'FRONTENDEOF'
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
  const [examMeta, setExamMeta]   = useState<any>({ sections: [], markingScheme: { correct: 4, incorrect: -1, unattempted: 0 }, duration: 200, title: '', status: '' })
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
  }

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if (sl) setLang(sl)
    const st = localStorage.getItem('pr_theme'); if (st === 'light') setDark(false)
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
      ;(attemptObj?.answers || []).forEach((a: any) => {
        const qid = String(a.questionId)
        if (a.selectedOption !== null && a.selectedOption !== undefined) hydratedAnswers[qid] = a.selectedOption
        if (a.isMarkedForReview) hydratedFlags.add(qid)
        hydratedVisited.add(qid)
      })
      setAnswers(hydratedAnswers)
      setFlagged(hydratedFlags)
      setVisited(hydratedVisited)

      // Questions (medium-aware, image-aware, subject-tagged) — §26
      const qr = await fetch(`${API}/api/exams/${examId}/questions`, { headers: h })
      const qd = await qr.json()
      if (!qr.ok) {
        setErrorState({ code: qd?.code || 'QUESTIONS_FAILED', message: qd?.message || t.errTitle })
        setInitializing(false)
        return
      }
      setQuestions(qd.questions || [])
      setExamMeta({
        sections: qd.sections || [],
        markingScheme: qd.markingScheme || { correct: 4, incorrect: -1, unattempted: 0 },
        duration: qd.duration || 200,
        title: qd.title || '',
        status: qd.status || ''
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

    requestFS()
    document.addEventListener('fullscreenchange', onFsChange)
    window.addEventListener('blur', onBlur)
    document.addEventListener('visibilitychange', onVis)
    return () => {
      document.removeEventListener('visibilitychange', onVis)
      document.removeEventListener('fullscreenchange', onFsChange)
      window.removeEventListener('blur', onBlur)
      if (fsExitTimerRef.current) clearTimeout(fsExitTimerRef.current)
    }
  }, [attempt, user, examId])

  // ── Timer countdown (now driven by authoritative totalDurationSec) ──
  useEffect(() => {
    if (!attempt) return
    const iv = setInterval(() => {
      setTimeLeft(tl => {
        if (tl <= 1) { clearInterval(iv); autoSubmit(true); return 0 }
        return tl - 1
      })
    }, 1000)
    return () => clearInterval(iv)
  }, [attempt])

  // ── Auto-save every 30s (§ Auto-Save Answers) ──────────────
  const autoSave = useCallback(async () => {
    if (!attempt?._id || !user) return
    try {
      await fetch(`${API}/api/attempts/${attempt._id}/auto-save`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({
          answers: Object.entries(answers).map(([questionId, selectedOption]) => ({
            questionId, selectedOption, timeTaken: timeSpent[questionId] || 0
          }))
        })
      })
    } catch {}
  }, [attempt, answers, user, timeSpent])

  useEffect(() => {
    if (!attempt) return
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

  // ── FIXED: save-answer / auto-save previously sent `qId` while the ──
  // ── backend expects `questionId` — answers were silently NEVER   ──
  // ── being saved. Fixed here + `timeTaken` now actually populated. ──
  const persistAnswer = useCallback(async (qId: string, selectedOption: any) => {
    setVisited(v => new Set([...v, qId]))
    if (!attempt?._id || !user) return
    const elapsedNow = Math.round((Date.now() - questionEnterRef.current) / 1000)
    try {
      await fetch(`${API}/api/attempts/${attempt._id}/save-answer`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ questionId: qId, selectedOption, timeTaken: elapsedNow })
      })
    } catch {}
  }, [attempt, user])

  const selectOption = (question: any, letter: string) => {
    if (!question) return
    const qId = question._id
    const prev = answers[qId]
    let nextVal: any
    if (question.type === 'MSQ') {
      const arr = Array.isArray(prev) ? [...prev] : []
      const idx = arr.indexOf(letter)
      if (idx >= 0) arr.splice(idx, 1); else arr.push(letter)
      nextVal = arr
    } else {
      nextVal = letter
    }
    setAnswers(a => ({ ...a, [qId]: nextVal }))
    persistAnswer(qId, nextVal)
  }

  const setIntegerAnswer = (question: any, value: string) => {
    if (!question) return
    setAnswers(a => ({ ...a, [question._id]: value }))
  }
  const commitIntegerAnswer = (question: any) => {
    if (!question) return
    persistAnswer(question._id, answers[question._id] ?? null)
  }

  const clearResponse = (question: any) => {
    if (!question) return
    setAnswers(a => { const n = { ...a }; delete n[question._id]; return n })
    persistAnswer(question._id, null)
  }

  const toggleFlag = async (question: any) => {
    if (!question) return
    const qId = question._id
    setFlagged(f => { const n = new Set(f); n.has(qId) ? n.delete(qId) : n.add(qId); return n })
    if (!attempt?._id || !user) return
    try {
      await fetch(`${API}/api/attempts/${attempt._id}/bookmark`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ questionId: qId })
      })
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

  // ── §10 status derivation — generalized for MSQ arrays ──────
  const getStatus = (qId: string) => {
    const ans = answers[qId]
    const hasAns = Array.isArray(ans) ? ans.length > 0 : (ans !== undefined && ans !== null && ans !== '')
    if (hasAns) return flagged.has(qId) ? 'flagged' : 'answered'
    if (flagged.has(qId)) return 'flagged'
    if (visited.has(qId)) return 'unanswered'
    return 'unvisited'
  }

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
            <button onClick={() => router.push('/dashboard/exams')} style={{ padding: '10px 18px', borderRadius: 10, border: '1px solid rgba(77,159,255,0.3)', background: 'transparent', color: '#E8F4FF', cursor: 'pointer' }}>{t.backToExams}</button>
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
        @media (max-width:820px){
          .examAside{ position:fixed !important; top:104px; bottom:0; left:0; width:78vw; max-width:300px; transform:translateX(-105%); z-index:150; box-shadow:8px 0 30px rgba(0,0,0,.5); }
          .examAside.open{ transform:translateX(0); }
          .examMobileNavBtn{ display:flex; position:fixed; bottom:18px; right:18px; z-index:140; width:52px; height:52px; border-radius:50%; align-items:center; justify-content:center; background:linear-gradient(135deg,#4D9FFF,#0055CC); color:#fff; border:none; font-size:20px; box-shadow:0 6px 20px rgba(0,0,0,.4); cursor:pointer; }
          .examMain{ padding:14px !important; }
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

      {/* ── HEADER ──────────────────────────────────────────────── */}
      <header style={{ background: headerBg, borderBottom: `1px solid ${bord}`, padding: '0 16px', position: 'sticky', top: 0, zIndex: 100, display: 'flex', flexDirection: 'column' }}>
        <div className="examHeaderRow" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 56, gap: 12 }}>
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
            <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: focusLocked ? '#123b1e' : '#3a1414', color: focusLocked ? '#7CFC9C' : '#ff8080' }}>
              {focusLocked ? '🔒 Focus Locked' : '🔓 Focus Lost'}
            </span>
            <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: integrityImpact === 'none' ? '#123b1e' : integrityImpact === 'low' ? '#3a2a00' : integrityImpact === 'medium' ? '#3a2200' : '#3a1414', color: integrityImpact === 'none' ? '#7CFC9C' : integrityImpact === 'low' ? '#f2d38a' : integrityImpact === 'medium' ? '#ffb066' : '#ff8080' }}>
              🛡️ {integrityImpact}
            </span>
            <button className="lb" style={{ background: 'linear-gradient(135deg,#FF4757,#CC2233)', boxShadow: '0 4px 15px rgba(255,71,87,0.3)' }} onClick={() => setShowSubmit(true)}>
              {t.submit}
            </button>
          </div>
        </div>
        <div style={{ height: 4, background: 'rgba(77,159,255,0.1)' }}>
          <div className={timerClass} style={{ height: '100%', width: `${Math.max(0, Math.min(100, timerPct))}%`, borderRadius: 2, transition: 'width 1s linear' }} />
        </div>
      </header>

      {/* ── BODY ────────────────────────────────────────────────── */}
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* LEFT: Section tabs + legend + Nav Grid (5-column, §10) */}
        <aside className={`examAside ${showMobileNav ? 'open' : ''}`} style={{ width: 240, background: asideBg, borderRight: `1px solid ${bord}`, padding: '16px 12px', overflowY: 'auto', flexShrink: 0 }}>
          <div style={{ display: 'flex', gap: 6, marginBottom: 16, flexWrap: 'wrap' }}>
            <button className={`tbtn ${selectedSubject === 'All' ? 'active' : ''}`} style={{ fontSize: 11, padding: '4px 8px' }} onClick={() => setSelectedSubject('All')}>{t.all}</button>
            {subjects.map(sub => (
              <button key={sub} className={`tbtn ${selectedSubject === sub ? 'active' : ''}`} style={{ fontSize: 11, padding: '4px 8px', borderColor: subjectColor(sub) }} onClick={() => setSelectedSubject(sub)}>{sub}</button>
            ))}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 16 }}>
            {[['answered', '#00C48C', t.answered], ['unanswered', '#FF4757', t.unanswered], ['flagged', '#A855F7', t.flagged], ['unvisited', 'rgba(77,159,255,0.1)', t.notVisited]].map(([cls, clr, lbl]) => (
              <div key={String(cls)} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: ts }}>
                <div style={{ width: 12, height: 12, borderRadius: 3, background: String(clr) }} />
                {lbl}
              </div>
            ))}
          </div>

          <div style={{ fontSize: 11, color: ts, marginBottom: 8 }}>{t.avgTime}: {avgTimeSec}s</div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 4 }}>
            {questions.map((q2: any, i: number) => {
              const st2 = getStatus(q2._id)
              return (
                <div key={q2._id || i} className={`qnum ${st2} ${i === current ? 'current' : ''}`}
                  onClick={() => { goTo(i); setShowMobileNav(false) }} title={q2.subject || ''}>
                  {i + 1}
                </div>
              )
            })}
          </div>
        </aside>

        {/* RIGHT: Question + Options */}
        <main className="examMain" style={{ flex: 1, overflowY: 'auto', padding: '24px' }}>
          <div style={{ display: 'flex', gap: 8, marginBottom: 16, flexWrap: 'wrap', alignItems: 'center' }}>
            <span style={{ fontSize: 11, color: ts }}>{t.fontSmaller}</span>
            <button onClick={() => setFontSize(f => Math.max(13, f - 1))} className="tbtn" style={{ padding: '2px 10px', fontSize: 12 }}>A−</button>
            <button onClick={() => setFontSize(f => Math.min(22, f + 1))} className="tbtn" style={{ padding: '2px 10px', fontSize: 12 }}>A+</button>
            <span style={{ fontSize: 11, color: ts }}>{fontSize}px</span>
          </div>

          {/* Question Card */}
          <div style={{ background: card, border: `1px solid ${bord}`, borderRadius: 16, padding: '28px', marginBottom: 20, minHeight: 200, backdropFilter: 'blur(12px)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
              <span style={{ color: '#4D9FFF', fontWeight: 700, fontSize: 14 }}>{t.question} {current + 1} / {questions.length}</span>
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

          {/* Options — SCQ/MSQ (OMR bubble) or Integer input */}
          {isInteger ? (
            <div style={{ marginBottom: 28 }}>
              <div style={{ fontSize: 13, color: ts, marginBottom: 8 }}>{t.integerHint}</div>
              <input
                type="number"
                value={q ? (answers[q._id] ?? '') : ''}
                onChange={e => setIntegerAnswer(q, e.target.value)}
                onBlur={() => commitIntegerAnswer(q)}
                style={{ width: '100%', maxWidth: 260, padding: '12px 16px', borderRadius: 10, border: `1.5px solid ${bord}`, background: dark ? 'rgba(0,22,40,0.5)' : '#fff', color: tm, fontSize: 16 }}
              />
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 28 }}>
              {opts.map(opt => {
                const optIdx = OPT_LETTERS.indexOf(opt)
                const optText = (lang === 'hi' && q?.hindiOptions && q.hindiOptions[optIdx]) ? q.hindiOptions[optIdx] : ((q?.options && q.options[optIdx]) || `Option ${opt}`)
                const optImg = q?.optionImages && q.optionImages[optIdx]
                const curAns = q ? answers[q._id] : undefined
                const isSelected = q && (Array.isArray(curAns) ? curAns.includes(opt) : curAns === opt)
                return (
                  <div key={opt} onClick={() => q && selectOption(q, opt)}
                    style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 20px', borderRadius: 12, border: `1.5px solid ${isSelected ? '#4D9FFF' : bord}`, background: isSelected ? 'rgba(77,159,255,0.1)' : (dark ? 'rgba(0,22,40,0.5)' : '#fff'), cursor: 'pointer', transition: 'all .2s' }}>
                    <div className={`omr-bubble ${isSelected ? 'selected' : ''}`} style={{ borderColor: isSelected ? '#4D9FFF' : bord, color: isSelected ? '#fff' : ts, flexShrink: 0 }}>
                      {opt}
                    </div>
                    <span style={{ color: isSelected ? tm : ts, fontSize: 15, flex: 1 }} dangerouslySetInnerHTML={{ __html: renderLatex(optText) }} />
                    {optImg && (
                      <div style={{ position: 'relative', flexShrink: 0 }}>
                        <img src={optImg} alt={`Option ${opt}`} style={{ width: 70, height: 70, objectFit: 'cover', borderRadius: 8 }} />
                        <button className="imgZoomBtn" style={{ top: 2, right: 2, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); setZoomImg(optImg) }}>🔍</button>
                      </div>
                    )}
                  </div>
                )
              })}
              {isMSQ && <div style={{ fontSize: 11, color: ts }}>({lang === 'hi' ? 'एक से अधिक विकल्प चुने जा सकते हैं' : 'More than one option may be correct'})</div>}
            </div>
          )}

          {/* Action Buttons */}
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <button className="tbtn" style={{ color: '#A855F7', borderColor: 'rgba(168,85,247,0.4)' }} onClick={() => toggleFlag(q)}>
              🔖 {q && flagged.has(q._id) ? t.unmarkReview : t.markReview}
            </button>
            <button className="tbtn" onClick={() => clearResponse(q)}>🗑 {t.clearResp}</button>
            <button className="tbtn" style={{ color: '#FFA502', borderColor: 'rgba(255,165,2,0.4)' }} onClick={() => setShowReportModal(true)}>🚩 {t.report}</button>
            <div style={{ flex: 1 }} />
            <button className="tbtn" onClick={() => goRelative(-1)} disabled={current === 0}>← {t.prev}</button>
            <button className="lb" onClick={() => goRelative(1)}>{t.saveNext} →</button>
          </div>
        </main>
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
FRONTENDEOF

echo "Frontend: exam attempt page.tsx rewritten."

echo "=================================================="
echo "F58 DONE. Restart backend + frontend and test."
echo "Server: cd ~/workspace && node src/index.js"
echo "Frontend: cd ~/workspace/frontend && npm run dev"
echo "=================================================="
