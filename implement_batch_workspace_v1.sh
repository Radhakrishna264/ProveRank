#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — Batch / Test Series Workspace — IMPLEMENTATION SCRIPT
# Covers: Overview, Exams (same launch flow as My Exams), Announcements,
# Resources (no videos), Leaderboard, Progress, Activity, Batch Info,
# FAQ/Help, Quick Actions, State persistence (resume), Desktop rail +
# Mobile chips layout, Light/Dark theme auto-adapt.
#
# Safe by design:
#  - Every file write is additive/new OR a full-file rewrite of a file
#    you already control (no sed on backend route logic).
#  - index.js mount is done via an idempotent Node.js patcher that
#    takes a timestamped backup and skips if already applied.
#  - The My Batches list patch only touches 2 exact, verified lines
#    (the "Workspace coming soon" placeholders) — nothing else.
#  - Run this from ~/workspace on Replit.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace || { echo "❌ Run this from ~/workspace"; exit 1; }

echo "════════════════════════════════════════════"
echo "STEP 0 — Locating project paths"
echo "════════════════════════════════════════════"

BACKEND_ROOT="$(pwd)"
if [ -f "src/index.js" ]; then BACKEND_ENTRY="src/index.js"; elif [ -f "index.js" ]; then BACKEND_ENTRY="index.js"; else
  echo "❌ Could not find src/index.js or index.js in $(pwd)"; exit 1
fi
echo "✔ Backend entry: $BACKEND_ENTRY"

ROUTES_DIR="src/routes"
MODELS_DIR="src/models"
[ -d "$ROUTES_DIR" ] || ROUTES_DIR="routes"
[ -d "$MODELS_DIR" ] || MODELS_DIR="models"
if [ ! -d "$ROUTES_DIR" ] || [ ! -d "$MODELS_DIR" ]; then
  echo "❌ Could not find routes/models folders. Expected src/routes + src/models."
  echo "   Found instead:"; find . -maxdepth 3 -iname "routes" -o -iname "models" 2>/dev/null
  exit 1
fi
echo "✔ Routes dir: $ROUTES_DIR"
echo "✔ Models dir: $MODELS_DIR"

FRONTEND_DIR="frontend"
if [ ! -d "$FRONTEND_DIR" ]; then echo "❌ frontend/ folder not found"; exit 1; fi
MYBATCHES_PAGE="$FRONTEND_DIR/app/dashboard/my-batches/page.tsx"
if [ ! -f "$MYBATCHES_PAGE" ]; then
  echo "⚠️  Expected file not found: $MYBATCHES_PAGE"
  echo "   Searching for the actual My Batches page..."
  FOUND=$(find "$FRONTEND_DIR" -path "*my-batches*page.tsx" 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then MYBATCHES_PAGE="$FOUND"; echo "✔ Using: $MYBATCHES_PAGE"; else
    echo "❌ Could not locate My Batches page.tsx anywhere under $FRONTEND_DIR — aborting frontend patch step only."
    MYBATCHES_PAGE=""
  fi
fi

echo ""
echo "════════════════════════════════════════════"
echo "STEP 1 — Backend: new Workspace route file"
echo "════════════════════════════════════════════"
cat > "$ROUTES_DIR/studentBatchWorkspace.js" << 'PRWORKSPACEEOF'
// ══════════════════════════════════════════════════════════════════
// STUDENT BATCH / TEST SERIES WORKSPACE — Backend API
// Mounted at: /api/student/batch-workspace
// One dedicated hub per enrolled Batch / Test Series:
// Overview · Exams · Announcements · Resources · Leaderboard ·
// Progress · Activity · Batch Info · FAQ · Quick Actions · State
// ══════════════════════════════════════════════════════════════════
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const Batch    = require('../models/Batch');
let TestSeries;   try { TestSeries   = require('../models/TestSeries');   } catch (e) { TestSeries   = null; }
let BatchNote;    try { BatchNote    = require('../models/BatchNote');    } catch (e) { BatchNote    = null; }
let BatchActivity;try { BatchActivity= require('../models/BatchActivity');} catch (e) { BatchActivity= null; }
let Announcement; try { Announcement= require('../models/Announcement'); } catch (e) { Announcement= null; }
let Exam;         try { Exam        = require('../models/Exam');         } catch (e) { Exam         = null; }
let Attempt;      try { Attempt     = require('../models/Attempt');      } catch (e) { Attempt      = null; }
const User = require('../models/User');
const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};

// ──────────────────────────────────────────────────────────────────
// Shared helpers
// ──────────────────────────────────────────────────────────────────
function normalizeSeries(s) {
  return {
    ...s,
    _kind: 'series',
    batchType: s.seriesType || 'Recorded',
    enrolledCount: s.enrolledCount || (s.students ? s.students.length : 0) || 0,
    validity: s.validity || 365
  };
}

async function findEnrolledDoc(id) {
  let doc = await Batch.findById(id).lean();
  if (doc) return { doc, kind: 'batch' };
  if (TestSeries) {
    doc = await TestSeries.findById(id).lean();
    if (doc) return { doc: normalizeSeries(doc), kind: 'series' };
  }
  return { doc: null, kind: null };
}

// Guard: student must actually be enrolled in this batch/series to open its workspace
async function requireEnrolled(req, res, next) {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const user = await User.collection.findOne({ _id: userId });
    const ids = (user && user.enrolledBatches) || [];
    const isEnrolled = ids.some(x => String(x) === String(req.params.id));
    if (!isEnrolled) return res.status(403).json({ error: 'You are not enrolled in this batch / test series' });
    req._userDoc = user;
    next();
  } catch (e) { res.status(500).json({ error: e.message }); }
}

function getMeta(userDoc, batchId) {
  const meta = (userDoc && userDoc.enrolledBatchesMeta) || [];
  return meta.find(m => m.batchId && String(m.batchId) === String(batchId)) || {};
}

function buildEnriched(b, m, now) {
  const enrolledAt = m.enrolledAt ? new Date(m.enrolledAt) : new Date();
  const validityDays = b.validity || 365;
  const expiresAt = m.expiresAt ? new Date(m.expiresAt) : (b.endDate ? new Date(b.endDate) : new Date(enrolledAt.getTime() + validityDays * 86400000));
  const daysLeft = Math.max(0, Math.ceil((expiresAt - now) / 86400000));
  const testsCompleted = m.testsCompleted || 0;
  const totalTests = b.totalTests || 0;
  const progress = totalTests > 0 ? Math.round((testsCompleted / totalTests) * 100) : 0;
  const lastAccessedAt = m.lastAccessedAt ? new Date(m.lastAccessedAt) : enrolledAt;
  return {
    enrolledAt, expiresAt, daysLeft, testsCompleted, totalTests, progress,
    lastAccessedAt, streak: m.streak || 0, avgScore: m.avgScore || 0, bestRank: m.bestRank || null,
    isExpired: daysLeft === 0, isCompleted: progress >= 100,
    renewalState: daysLeft === 0 ? 'expired' : daysLeft <= 7 ? 'expiring_soon' : 'active'
  };
}

// ══ Exam-state helpers (mirrors My Exams page logic — Rule: same launch flow) ══
const GRACE_MS = 5 * 60 * 1000;
function computeExamState(exam, now, usedAttempts) {
  const start = exam.schedule && exam.schedule.startTime ? new Date(exam.schedule.startTime) : null;
  const end = exam.schedule && exam.schedule.endTime ? new Date(exam.schedule.endTime) : null;
  const waitMins = typeof exam.waitingRoomMinutes === 'number' ? exam.waitingRoomMinutes : 20;

  let derivedStatus = exam.status;
  const minsToStart = start ? (start.getTime() - now.getTime()) / 60000 : null;
  const secsToStart = start ? Math.round((start.getTime() - now.getTime()) / 1000) : null;

  let joinState = 'not_applicable';
  let waitingRoomWindowOpen = false;
  let skipWaitingRoom = false;

  const maxAttempts = exam.unlimitedAttempts ? Infinity : (exam.maxAttempts || 1);
  const attemptsLeft = maxAttempts === Infinity ? Infinity : Math.max(0, maxAttempts - usedAttempts);

  if (derivedStatus === 'scheduled' && start) {
    if (minsToStart <= waitMins && minsToStart > 0) {
      waitingRoomWindowOpen = true;
      joinState = 'waiting_room_open';
    } else if (minsToStart <= 0) {
      derivedStatus = 'live';
    } else {
      joinState = 'available_later';
    }
  }

  if (derivedStatus === 'live' && start) {
    const nowMs = now.getTime();
    const startMs = start.getTime();
    if (nowMs <= startMs + GRACE_MS) {
      joinState = 'join_open';
    } else if (end && nowMs > end.getTime()) {
      derivedStatus = 'ended';
    } else {
      joinState = 'join_closed';
    }
  }

  if (derivedStatus === 'ended') {
    if (attemptsLeft > 0) {
      joinState = 'available_again';
      skipWaitingRoom = true;
    } else {
      joinState = 'locked';
    }
  }

  return {
    derivedStatus, minsToStart, secsToStart, joinState,
    waitingRoomWindowOpen, skipWaitingRoom,
    attemptsLeft: attemptsLeft === Infinity ? -1 : attemptsLeft
  };
}

function canSeeExamInWorkspace(exam, studentId, student) {
  if (exam.isArchived) return false;
  if (exam.whitelistEnabled) {
    const inStudentList = (exam.whitelistedStudents || []).some(id => String(id) === String(studentId));
    const inGroupList = student && student.group && (exam.whitelistedGroups || []).includes(student.group);
    return !!(inStudentList || inGroupList);
  }
  if (Array.isArray(exam.whitelist) && exam.whitelist.length > 0) {
    return exam.whitelist.some(id => String(id) === String(studentId));
  }
  return true; // batch/series target match already guarantees visibility scope
}

async function getPerformanceSummary(examId, studentId) {
  if (!Attempt) return null;
  try {
    const attempts = await Attempt.find({ examId, studentId, status: 'submitted' })
      .sort({ submittedAt: 1 }).select('score rank submittedAt').lean();
    if (!attempts.length) return null;
    const scores = attempts.map(a => a.score).filter(s => typeof s === 'number');
    const best = scores.length ? Math.max(...scores) : null;
    const avg = scores.length ? Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 100) / 100 : null;
    return { attemptCount: attempts.length, bestScore: best, avgScore: avg, lastAttemptAt: attempts[attempts.length - 1].submittedAt };
  } catch (e) { return null; }
}

// Fetch exam ids that belong to this batch/series (used by Exams + Activity + Progress)
async function getBatchExamIds(batchOrSeriesId) {
  if (!Exam) return [];
  const exams = await Exam.find({
    isArchived: { $ne: true },
    $or: [{ batch: batchOrSeriesId }, { multiBatch: batchOrSeriesId }, { testSeriesId: batchOrSeriesId }]
  }).select('_id').lean();
  return exams.map(e => e._id);
}

// ══════════════════════════════════════════════════════════════════
// 1) OVERVIEW  — GET /:id/overview
// ══════════════════════════════════════════════════════════════════
router.get('/:id/overview', auth, requireEnrolled, async (req, res) => {
  try {
    const { doc, kind } = await findEnrolledDoc(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Batch / Test Series not found' });
    const now = new Date();
    const meta = getMeta(req._userDoc, req.params.id);
    const enriched = buildEnriched(doc, meta, now);

    // Next test countdown
    let nextTest = null;
    if (Exam) {
      const examIds = await getBatchExamIds(req.params.id);
      const upcoming = await Exam.find({
        _id: { $in: examIds }, isArchived: { $ne: true },
        status: { $in: ['scheduled', 'live'] }, 'schedule.startTime': { $gte: now }
      }).sort({ 'schedule.startTime': 1 }).limit(1).lean();
      if (upcoming.length) {
        nextTest = { _id: upcoming[0]._id, title: upcoming[0].title, startTime: upcoming[0].schedule.startTime };
      }
    }

    // Current rank (latest live/ended attempt in this batch)
    let currentRank = meta.bestRank || null;

    // Latest announcement
    let latestAnnouncement = null;
    if (Announcement) {
      const ann = await Announcement.findOne({
        status: 'sent',
        $and: [
          { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] },
          { $or: [
              { 'audience.mode': 'all' },
              { 'audience.mode': 'batch', 'audience.batchIds': req.params.id },
              { 'audience.mode': 'testseries', 'audience.testSeriesIds': req.params.id }
          ] }
        ]
      }).sort({ createdAt: -1 }).lean();
      if (ann) latestAnnouncement = { _id: ann._id, title: ann.title, type: ann.type, createdAt: ann.createdAt };
    }

    // Latest activity
    let latestActivity = null;
    if (BatchActivity) {
      const act = await BatchActivity.findOne({ batchId: req.params.id, isActive: true }).sort({ createdAt: -1 }).lean();
      if (act) latestActivity = { title: act.title, message: act.message, icon: act.icon, createdAt: act.createdAt };
    }

    const wishlist = (req._userDoc.wishlistBatches || []).map(x => String(x));

    res.json({
      workspace: {
        _id: doc._id, name: doc.name, examType: doc.examType, thumbnail: doc.thumbnail,
        colorIcon: doc.colorIcon, kind,
        ...enriched,
        testsAttempted: meta.testsCompleted || 0,
        currentRank,
        nextTest,
        latestAnnouncement,
        latestActivity,
        isFavorite: wishlist.includes(String(req.params.id))
      }
    });
  } catch (e) { console.error(e); res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 2) EXAMS  — GET /:id/exams  (SAME launch-flow fields as My Exams page)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/exams', auth, requireEnrolled, async (req, res) => {
  try {
    if (!Exam) return res.json({ exams: [] });
    const { search, subject, category, status } = req.query;
    const now = new Date();
    const studentId = req.user.id;
    const student = await User.findById(studentId).select('group').lean();

    const filter = {
      isArchived: { $ne: true },
      status: { $in: ['scheduled', 'live', 'ended'] },
      $or: [{ batch: req.params.id }, { multiBatch: req.params.id }, { testSeriesId: req.params.id }]
    };
    if (subject) filter.subject = subject;
    if (category) filter.category = category;
    if (search) filter.title = { $regex: search, $options: 'i' };

    let exams = await Exam.find(filter).lean();
    exams = exams.filter(e => canSeeExamInWorkspace(e, studentId, student));
    const examIds = exams.map(e => e._id);

    const [activeAttempts, allAttempts] = await Promise.all([
      Attempt ? Attempt.find({ examId: { $in: examIds }, studentId, status: { $in: ['waiting', 'instructions', 'active'] } }).select('examId').lean() : [],
      Attempt ? Attempt.find({ examId: { $in: examIds }, studentId }).select('examId status').lean() : []
    ]);
    const activeByExam = {};
    activeAttempts.forEach(a => { activeByExam[String(a.examId)] = a; });

    const userDoc = req._userDoc;
    const joinedSet = new Set(((userDoc && userDoc.waitingRoomJoins) || []).map(j => String(j.examId)));
    const reminderMap = {};
    ((userDoc && userDoc.examReminders) || []).forEach(r => { reminderMap[String(r.examId)] = r.enabled; });

    let result = await Promise.all(exams.map(async e => {
      const eid = String(e._id);
      const usedAttempts = allAttempts.filter(a => String(a.examId) === eid && (a.status === 'submitted' || a.status === 'timeout')).length;
      const state = computeExamState(e, now, usedAttempts);
      const perf = (state.derivedStatus === 'ended' || usedAttempts > 0) ? await getPerformanceSummary(e._id, studentId) : null;
      return {
        _id: e._id, title: e.title, subject: e.subject, duration: e.duration,
        totalMarks: e.totalMarks, category: e.category, schedule: e.schedule,
        passwordProtected: !!e.password, status: e.status,
        activeAttemptId: activeByExam[eid] ? activeByExam[eid]._id : null,
        hasJoinedWaitingRoom: joinedSet.has(eid),
        reminderEnabled: reminderMap[eid] !== undefined ? reminderMap[eid] : true,
        performance: perf,
        ...state
      };
    }));

    if (status === 'upcoming') result = result.filter(x => x.derivedStatus === 'scheduled');
    else if (status === 'live') result = result.filter(x => x.derivedStatus === 'live');
    else if (status === 'completed') result = result.filter(x => x.derivedStatus === 'ended');

    result.sort((a, b) => {
      const at = a.schedule && a.schedule.startTime ? new Date(a.schedule.startTime).getTime() : 0;
      const bt = b.schedule && b.schedule.startTime ? new Date(b.schedule.startTime).getTime() : 0;
      return bt - at;
    });

    res.json({ exams: result, total: result.length });
  } catch (e) { console.error(e); res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 3) ANNOUNCEMENTS  — GET /:id/announcements, POST read / read-all
// ══════════════════════════════════════════════════════════════════
router.get('/:id/announcements', auth, requireEnrolled, async (req, res) => {
  try {
    if (!Announcement) return res.json({ announcements: [] });
    const uid = new mongoose.Types.ObjectId(req.user.id);
    const now = new Date();
    const list = await Announcement.find({
      status: 'sent',
      $and: [
        { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] },
        { $or: [
            { 'audience.mode': 'all' },
            { 'audience.mode': 'batch', 'audience.batchIds': req.params.id },
            { 'audience.mode': 'testseries', 'audience.testSeriesIds': req.params.id }
        ] }
      ]
    }).sort({ pinned: -1, createdAt: -1 }).limit(100).lean();

    const out = list.map(a => ({
      _id: a._id, title: a.title, titleHi: a.titleHi, message: a.message, messageHi: a.messageHi,
      type: a.type, pinned: a.pinned, imageUrl: a.imageUrl, expiryDate: a.expiryDate, createdAt: a.createdAt,
      isRead: (a.readBy || []).some(r => String(r.userId) === String(uid)),
      isAcked: (a.ackBy || []).some(r => String(r.userId) === String(uid))
    }));
    res.json({ announcements: out });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/announcements/:annId/read', auth, requireEnrolled, async (req, res) => {
  try {
    if (!Announcement) return res.json({ success: true });
    const ann = await Announcement.findById(req.params.annId);
    if (!ann) return res.status(404).json({ error: 'Not found' });
    const already = (ann.readBy || []).some(r => String(r.userId) === String(req.user.id));
    if (!already) { ann.readBy.push({ userId: req.user.id, readAt: new Date() }); await ann.save(); }
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/announcements/read-all', auth, requireEnrolled, async (req, res) => {
  try {
    if (!Announcement) return res.json({ success: true });
    const uid = new mongoose.Types.ObjectId(req.user.id);
    const now = new Date();
    await Announcement.updateMany({
      status: 'sent',
      'readBy.userId': { $ne: uid },
      $and: [
        { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] },
        { $or: [
            { 'audience.mode': 'all' },
            { 'audience.mode': 'batch', 'audience.batchIds': req.params.id },
            { 'audience.mode': 'testseries', 'audience.testSeriesIds': req.params.id }
        ] }
      ]
    }, { $push: { readBy: { userId: uid, readAt: now } } });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 4) RESOURCES — GET /:id/resources, POST view, POST pin (student-personal)
//    Rule: NO recorded videos in workspace resources
// ══════════════════════════════════════════════════════════════════
router.get('/:id/resources', auth, requireEnrolled, async (req, res) => {
  try {
    if (!BatchNote) return res.json({ resources: [] });
    const { search, category, sort } = req.query;
    const filter = { batch: req.params.id, type: { $ne: 'video' } };
    if (category && category !== 'all') filter.type = category === 'video' ? '__none__' : category;
    if (search) filter.title = { $regex: search, $options: 'i' };

    let notes = await BatchNote.find(filter).lean();
    const now = new Date();
    const uid = String(req.user.id);
    const state = getWorkspaceStateSync(req._userDoc, req.params.id);
    const pinnedByStudent = new Set((state.pinnedResources || []).map(String));

    let out = notes.map(n => ({
      _id: n._id, title: n.title, description: n.description, url: n.url,
      type: n.type, subject: n.subject, adminPinned: !!n.pinned,
      studentPinned: pinnedByStudent.has(String(n._id)),
      recentlyAdded: (now - new Date(n.createdAt)) < 7 * 86400000,
      viewed: (n.viewedBy || []).some(v => String(v.studentId) === uid),
      createdAt: n.createdAt
    }));

    if (sort === 'popular') out.sort((a, b) => (b.viewed ? 1 : 0) - (a.viewed ? 1 : 0));
    else out.sort((a, b) => (b.studentPinned - a.studentPinned) || (b.adminPinned - a.adminPinned) || (new Date(b.createdAt) - new Date(a.createdAt)));

    res.json({ resources: out });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/resources/:noteId/view', auth, requireEnrolled, async (req, res) => {
  try {
    if (!BatchNote) return res.json({ success: true });
    const note = await BatchNote.findById(req.params.noteId);
    if (!note) return res.status(404).json({ error: 'Resource not found' });
    note.viewedBy = note.viewedBy || [];
    const already = note.viewedBy.some(v => String(v.studentId) === String(req.user.id));
    if (!already) { note.viewedBy.push({ studentId: req.user.id, viewedAt: new Date() }); await note.save(); }
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/resources/:noteId/pin', auth, requireEnrolled, async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const user = await User.collection.findOne({ _id: userId });
    let ws = (user && user.batchWorkspaceState) || [];
    let idx = ws.findIndex(w => String(w.batchId) === String(req.params.id));
    if (idx < 0) { ws.push({ batchId: req.params.id, pinnedResources: [] }); idx = ws.length - 1; }
    ws[idx].pinnedResources = ws[idx].pinnedResources || [];
    const has = ws[idx].pinnedResources.some(r => String(r) === String(req.params.noteId));
    if (has) ws[idx].pinnedResources = ws[idx].pinnedResources.filter(r => String(r) !== String(req.params.noteId));
    else ws[idx].pinnedResources.push(req.params.noteId);
    await User.collection.updateOne({ _id: userId }, { $set: { batchWorkspaceState: ws } });
    res.json({ success: true, pinned: !has });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 5) LEADERBOARD — GET /:id/leaderboard?scope=top10|top50|full&search=
// ══════════════════════════════════════════════════════════════════
router.get('/:id/leaderboard', auth, requireEnrolled, async (req, res) => {
  try {
    const { scope = 'top10', search } = req.query;
    const users = await User.collection.find({
      'enrolledBatchesMeta.batchId': new mongoose.Types.ObjectId(req.params.id)
    }).toArray();

    let lb = users.map(u => {
      const meta = (u.enrolledBatchesMeta || []).find(m => m.batchId && String(m.batchId) === String(req.params.id));
      return {
        userId: u._id, name: u.name || 'Student',
        testsCompleted: meta ? (meta.testsCompleted || 0) : 0,
        avgScore: meta ? (meta.avgScore || 0) : 0,
        streak: meta ? (meta.streak || 0) : 0,
        bestRank: meta ? (meta.bestRank || null) : null
      };
    }).sort((a, b) => b.testsCompleted - a.testsCompleted || b.avgScore - a.avgScore);

    const myIdx = lb.findIndex(x => String(x.userId) === String(req.user.id));
    const total = lb.length;
    const myRank = myIdx + 1;
    const percentile = total > 0 && myIdx >= 0 ? Math.round(((total - myRank) / total) * 100) : null;
    const topper = lb.length ? lb[0] : null;

    let visible = lb;
    if (search) {
      const rx = new RegExp(String(search).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      visible = visible.filter(x => rx.test(x.name));
    }
    if (scope === 'top10') visible = visible.slice(0, 10);
    else if (scope === 'top50') visible = visible.slice(0, 50);

    res.json({
      leaderboard: visible.map(x => ({ name: x.name, testsCompleted: x.testsCompleted, avgScore: x.avgScore, streak: x.streak, bestRank: x.bestRank })),
      myRank: myIdx >= 0 ? myRank : null, total, percentile, topper: topper ? { name: topper.name, avgScore: topper.avgScore } : null
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 6) PROGRESS — GET /:id/progress
// ══════════════════════════════════════════════════════════════════
router.get('/:id/progress', auth, requireEnrolled, async (req, res) => {
  try {
    const { doc } = await findEnrolledDoc(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Batch / Test Series not found' });
    const meta = getMeta(req._userDoc, req.params.id);
    const totalTests = doc.totalTests || 0;
    const testsCompleted = meta.testsCompleted || 0;
    const completionPct = totalTests > 0 ? Math.round((testsCompleted / totalTests) * 100) : 0;

    let questionsAttempted = 0, accuracy = 0, weakSubjects = [], strongSubjects = [];
    try {
      if (Attempt) {
        const examIds = await getBatchExamIds(req.params.id);
        const attempts = await Attempt.find({ examId: { $in: examIds }, studentId: req.user.id, status: 'submitted' }).lean();
        const subjectStats = {};
        attempts.forEach(a => {
          questionsAttempted += (a.totalQuestions || (a.answers ? Object.keys(a.answers).length : 0)) || 0;
          if (Array.isArray(a.subjectScores)) {
            a.subjectScores.forEach(s => {
              if (!subjectStats[s.subject]) subjectStats[s.subject] = { correct: 0, total: 0 };
              subjectStats[s.subject].correct += s.correct || 0;
              subjectStats[s.subject].total += s.total || 0;
            });
          }
        });
        const subjEntries = Object.keys(subjectStats).map(k => ({
          subject: k, accuracy: subjectStats[k].total > 0 ? Math.round((subjectStats[k].correct / subjectStats[k].total) * 100) : 0
        }));
        subjEntries.sort((a, b) => a.accuracy - b.accuracy);
        weakSubjects = subjEntries.slice(0, 2).filter(s => s.accuracy < 60);
        strongSubjects = subjEntries.slice(-2).filter(s => s.accuracy >= 70).reverse();
        if (attempts.length) {
          const totalCorrect = Object.values(subjectStats).reduce((s, x) => s + x.correct, 0);
          const totalQs = Object.values(subjectStats).reduce((s, x) => s + x.total, 0);
          accuracy = totalQs > 0 ? Math.round((totalCorrect / totalQs) * 100) : 0;
        }
      }
    } catch (e) { /* attempt schema fields optional — degrade gracefully */ }

    res.json({
      testsAttempted: testsCompleted, totalTests, questionsAttempted, accuracy,
      avgScore: meta.avgScore || 0, bestScore: meta.bestScoreValue || null,
      completionPct, weakSubjects, strongSubjects
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 7) ACTIVITY — GET /:id/activity  (admin activity + personal events + milestones)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/activity', auth, requireEnrolled, async (req, res) => {
  try {
    const meta = getMeta(req._userDoc, req.params.id);
    let timeline = [];

    if (BatchActivity) {
      const acts = await BatchActivity.find({ batchId: req.params.id, isActive: true }).sort({ createdAt: -1 }).limit(20).lean();
      timeline = timeline.concat(acts.map(a => ({ type: a.type, title: a.title, message: a.message, icon: a.icon, at: a.createdAt })));
    }

    if (Attempt) {
      try {
        const examIds = await getBatchExamIds(req.params.id);
        const attempts = await Attempt.find({ examId: { $in: examIds }, studentId: req.user.id, status: { $in: ['submitted', 'timeout'] } })
          .sort({ submittedAt: -1 }).limit(10).select('examId score submittedAt').lean();
        const examTitles = {};
        if (Exam && attempts.length) {
          const exs = await Exam.find({ _id: { $in: attempts.map(a => a.examId) } }).select('title').lean();
          exs.forEach(e => { examTitles[String(e._id)] = e.title; });
        }
        timeline = timeline.concat(attempts.map(a => ({
          type: 'attempted_test', title: `Attempted: ${examTitles[String(a.examId)] || 'Test'}`,
          message: typeof a.score === 'number' ? `Score: ${a.score}` : '', icon: '📝', at: a.submittedAt
        })));
      } catch (e) { /* non-fatal */ }
    }

    if (meta.streak) timeline.push({ type: 'streak', title: `🔥 ${meta.streak}-day streak`, message: '', icon: '🔥', at: meta.streakLastDate || meta.lastAccessedAt || new Date() });

    timeline.sort((a, b) => new Date(b.at || 0) - new Date(a.at || 0));
    timeline = timeline.slice(0, 30);

    const { doc } = await findEnrolledDoc(req.params.id);
    const totalTests = (doc && doc.totalTests) || 0;
    const testsCompleted = meta.testsCompleted || 0;
    const progress = totalTests > 0 ? Math.round((testsCompleted / totalTests) * 100) : 0;
    const milestones = [
      { label: 'First Test', achieved: testsCompleted >= 1 },
      { label: '25% Complete', achieved: progress >= 25 },
      { label: '50% Complete', achieved: progress >= 50 },
      { label: '75% Complete', achieved: progress >= 75 },
      { label: '7-Day Streak', achieved: (meta.streak || 0) >= 7 },
      { label: 'Completed', achieved: progress >= 100 }
    ];

    res.json({ activity: timeline, milestones, lastAccessedAt: meta.lastAccessedAt || null });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 8) BATCH INFO — GET /:id/info
// ══════════════════════════════════════════════════════════════════
router.get('/:id/info', auth, requireEnrolled, async (req, res) => {
  try {
    const { doc, kind } = await findEnrolledDoc(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Batch / Test Series not found' });
    const meta = getMeta(req._userDoc, req.params.id);
    const now = new Date();
    const enriched = buildEnriched(doc, meta, now);
    res.json({
      info: {
        _id: doc._id, name: doc.name, batchCode: doc.batchCode || '', kind,
        teacherAssigned: doc.teacherAssigned || '', subject: doc.subject || 'All Subjects',
        startDate: doc.startDate || null, endDate: doc.endDate || null, validity: doc.validity || 365,
        totalTests: doc.totalTests || 0, enrolledAt: enriched.enrolledAt, expiresAt: enriched.expiresAt,
        language: doc.language || 'Hindi + English', batchType: doc.batchType || 'Recorded',
        accessStatus: enriched.renewalState, isFree: !!doc.isFree,
        price: doc.isFree ? 0 : (doc.discountPrice || doc.price || 0)
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 9) FAQ / HELP — GET /:id/faq?search=
// ══════════════════════════════════════════════════════════════════
router.get('/:id/faq', auth, requireEnrolled, async (req, res) => {
  try {
    const { doc } = await findEnrolledDoc(req.params.id);
    const faqs = [
      { q: 'How do I access exams in this batch / test series?', a: 'Open the Exams section — upcoming, live and completed exams for this batch are listed there with one-tap launch.', category: 'exams' },
      { q: 'How do I download study resources?', a: 'Open Resources section, tap any PDF / notes / PYQ sheet card to preview or download it.', category: 'resources' },
      { q: 'How do I set an exam reminder?', a: 'On any upcoming exam card, tap the reminder bell toggle to get notified before it starts.', category: 'exams' },
      { q: 'Where can I see my rank?', a: 'Open the Leaderboard section for your current rank, percentile and top performers in this batch.', category: 'leaderboard' },
      { q: 'Facing a technical issue?', a: 'Use the Support page from the sidebar, or raise a Grievance / Doubt query for help.', category: 'technical' }
    ];
    if (doc && doc.totalTests > 0) faqs.push({ q: 'Do I get a certificate?', a: 'Yes, once you complete all tests in this batch / test series.', category: 'general' });
    let out = faqs;
    if (req.query.search) {
      const rx = new RegExp(String(req.query.search).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      out = faqs.filter(f => rx.test(f.q) || rx.test(f.a));
    }
    res.json({ faqs: out });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 10) WORKSPACE STATE — persist last section, filters, resume point etc.
// ══════════════════════════════════════════════════════════════════
function getWorkspaceStateSync(userDoc, batchId) {
  const ws = (userDoc && userDoc.batchWorkspaceState) || [];
  return ws.find(w => String(w.batchId) === String(batchId)) || {};
}

router.get('/:id/state', auth, requireEnrolled, async (req, res) => {
  try {
    const state = getWorkspaceStateSync(req._userDoc, req.params.id);
    res.json({
      state: {
        lastSection: state.lastSection || 'overview',
        searchTerm: state.searchTerm || '',
        filterState: state.filterState || {},
        progressView: state.progressView || 'ring',
        pinnedResources: state.pinnedResources || [],
        resumePoint: state.resumePoint || null
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/state', auth, requireEnrolled, async (req, res) => {
  try {
    const allowed = ['lastSection', 'searchTerm', 'filterState', 'progressView', 'resumePoint'];
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const user = await User.collection.findOne({ _id: userId });
    let ws = (user && user.batchWorkspaceState) || [];
    let idx = ws.findIndex(w => String(w.batchId) === String(req.params.id));
    if (idx < 0) { ws.push({ batchId: req.params.id }); idx = ws.length - 1; }
    allowed.forEach(k => { if (req.body[k] !== undefined) ws[idx][k] = req.body[k]; });
    ws[idx].updatedAt = new Date();
    await User.collection.updateOne({ _id: userId }, { $set: { batchWorkspaceState: ws } });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;

PRWORKSPACEEOF
node --check "$ROUTES_DIR/studentBatchWorkspace.js" && echo "✔ studentBatchWorkspace.js syntax OK"

echo ""
echo "════════════════════════════════════════════"
echo "STEP 2 — Backend: BatchNote model (+ viewedBy tracking, additive)"
echo "════════════════════════════════════════════"
if [ -f "$MODELS_DIR/BatchNote.js" ]; then
  cp "$MODELS_DIR/BatchNote.js" "$MODELS_DIR/BatchNote.js.bak.$(date +%s)"
  echo "✔ Backed up existing BatchNote.js"
fi
cat > "$MODELS_DIR/BatchNote.js" << 'PRBATCHNOTEEOF'
const mongoose=require('mongoose');
const BatchNoteSchema=new mongoose.Schema({
  batch:{type:mongoose.Schema.Types.ObjectId,ref:'Batch',required:true},
  title:{type:String,required:true,trim:true},
  description:{type:String,default:''},
  url:{type:String,default:''},
  type:{type:String,enum:['pdf','video','doc','link','image','other'],default:'link'},
  subject:{type:String,default:'General'},
  createdBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
  pinned:{type:Boolean,default:false},
  expiryDate:{type:Date,default:null},
  version:{type:Number,default:1},
  // ── Batch Workspace (student read-tracking) — additive, non-breaking ──
  viewedBy:[{
    studentId:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
    viewedAt:{type:Date,default:Date.now}
  }],
},{timestamps:true});
module.exports=mongoose.model('BatchNote',BatchNoteSchema);

PRBATCHNOTEEOF
node --check "$MODELS_DIR/BatchNote.js" && echo "✔ BatchNote.js syntax OK"

echo ""
echo "════════════════════════════════════════════"
echo "STEP 3 — Backend: mount route in $BACKEND_ENTRY (idempotent)"
echo "════════════════════════════════════════════"
cat > /tmp/pr_patch_index.js << 'PRPATCHEREOF'
// ══════════════════════════════════════════════════════════════════
// Idempotent patcher — mounts studentBatchWorkspace route in index.js
// Safe: takes a timestamped backup, checks for existing mount before
// writing, never touches any other route's logic.
// ══════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  path.join(process.env.HOME || '/home/runner/workspace', 'src', 'index.js'),
  path.join(process.cwd(), 'src', 'index.js'),
  path.join(process.cwd(), 'index.js'),
];

let target = null;
for (const p of CANDIDATES) { if (fs.existsSync(p)) { target = p; break; } }
if (!target) {
  console.error('❌ Could not locate src/index.js automatically.');
  console.error('   Checked: ' + CANDIDATES.join(', '));
  console.error('   Run this from ~/workspace, or edit CANDIDATES in this script.');
  process.exit(1);
}

let src = fs.readFileSync(target, 'utf8');

if (src.includes('studentBatchWorkspace')) {
  console.log('✅ Already mounted — no changes needed: ' + target);
  process.exit(0);
}

const backupPath = target + '.bak.' + Date.now();
fs.writeFileSync(backupPath, src);
console.log('🗂  Backup saved: ' + backupPath);

const REQUIRE_LINE = "const studentBatchWorkspaceRoutes = require('./routes/studentBatchWorkspace');";
const USE_LINE = "app.use('/api/student/batch-workspace', studentBatchWorkspaceRoutes);";

// Insert require: right after an existing similar require line if found, else after last require(...) line
let lines = src.split('\n');
let reqAnchor = lines.findIndex(l => l.includes("require('./routes/studentBatches')") || l.includes('require("./routes/studentBatches")'));
if (reqAnchor === -1) {
  for (let i = lines.length - 1; i >= 0; i--) {
    if (/^\s*(const|let|var)\s+.*require\(/.test(lines[i])) { reqAnchor = i; break; }
  }
}
if (reqAnchor === -1) reqAnchor = 0;
lines.splice(reqAnchor + 1, 0, REQUIRE_LINE);

// Insert app.use: right after an existing similar app.use line if found, else before app.listen(
let useAnchor = lines.findIndex(l => l.includes("app.use('/api/student/batches'") || l.includes('app.use("/api/student/batches"'));
if (useAnchor === -1) {
  useAnchor = lines.findIndex(l => l.includes('app.listen('));
  if (useAnchor === -1) useAnchor = lines.length - 1;
  lines.splice(useAnchor, 0, USE_LINE);
} else {
  lines.splice(useAnchor + 1, 0, USE_LINE);
}

fs.writeFileSync(target, lines.join('\n'));
console.log('✅ Patched: ' + target);
console.log('   + ' + REQUIRE_LINE);
console.log('   + ' + USE_LINE);
console.log('👉 Verify with: grep -n "studentBatchWorkspace" ' + target);

PRPATCHEREOF
node /tmp/pr_patch_index.js
grep -n "studentBatchWorkspace" "$BACKEND_ENTRY" || echo "⚠️  Mount line not found — check manually."

echo ""
echo "════════════════════════════════════════════"
echo "STEP 4 — Frontend: new Workspace page"
echo "════════════════════════════════════════════"
WORKSPACE_DIR="$FRONTEND_DIR/app/dashboard/my-batches/[id]"
mkdir -p "$WORKSPACE_DIR"
cat > "$WORKSPACE_DIR/page.tsx" << 'PRWSPAGEEOF'
'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter, useParams } from 'next/navigation'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ══════════════════════════════════════════════════════════════════
// ⚠️ ROUTE MAP — verify these match your actual My Exams page routes.
// Confirmed from waiting-room page: /exam/:id/waiting-room, /exam/:id/instructions, /exam/:id/attempt
// "View Result" path below is a best-effort guess — tell me the real
// path (grep your My Exams page for router.push to a results page) and
// I will correct this in one line.
// ══════════════════════════════════════════════════════════════════
const EXAM_ROUTES = {
  waitingRoom: (id: string) => `/exam/${id}/waiting-room`,
  instructions: (id: string) => `/exam/${id}/instructions`,
  attempt: (id: string) => `/exam/${id}/attempt`,
  result: (id: string) => `/exam/${id}/result`,          // ⚠️ VERIFY
}

// ── Theme system (same pattern as My Batches page) ──
type PageTheme = 'light' | 'dark'
function usePageTheme(): PageTheme {
  const [theme, setTheme] = useState<PageTheme>('dark')
  useEffect(() => {
    const read = () => { try { setTheme((localStorage.getItem('pr_color_theme') as PageTheme) || 'dark') } catch { setTheme('dark') } }
    read()
    const onStorage = (e: StorageEvent) => { if (!e.key || e.key === 'pr_color_theme') read() }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])
  return theme
}
const THEME_VARS: Record<PageTheme, Record<string, string>> = {
  dark: { '--pr-bg': 'radial-gradient(ellipse at 20% 0%,#0C1220 0%,#070A12 55%,#040609 100%)', '--pr-card-rgb': '4,12,30', '--pr-sub-rgb': '160,200,240', '--pr-text': '#F1F6FC' },
  light: { '--pr-bg': 'radial-gradient(ellipse at 15% 0%,#FFFFFF 0%,#F3F7FF 55%,#E9F1FF 100%)', '--pr-card-rgb': '255,255,255', '--pr-sub-rgb': '71,85,105', '--pr-text': '#0F172A' },
}

function useIsDesktop() {
  const [isDesktop, setIsDesktop] = useState(false)
  useEffect(() => {
    const mq = window.matchMedia('(min-width: 900px)')
    const update = () => setIsDesktop(mq.matches)
    update()
    mq.addEventListener ? mq.addEventListener('change', update) : mq.addListener(update)
    return () => { mq.removeEventListener ? mq.removeEventListener('change', update) : mq.removeListener(update) }
  }, [])
  return isDesktop
}

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', 'NEET UG': '#4D9FFF', JEE: '#9B59B6', 'JEE MAINS': '#9B59B6', 'JEE ADVANCE': '#7D3C98',
  CUET: '#27AE60', 'CUET UG': '#27AE60', 'CUET PG': '#1E8449', 'SSC CGL': '#E67E22', 'IIT JAM': '#00D4FF',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C', Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}

const SECTIONS = [
  { key: 'overview', label: 'Overview', icon: '🏠' },
  { key: 'exams', label: 'Exams', icon: '📝' },
  { key: 'announcements', label: 'Announcements', icon: '📢' },
  { key: 'resources', label: 'Resources', icon: '📚' },
  { key: 'leaderboard', label: 'Leaderboard', icon: '🏆' },
  { key: 'progress', label: 'Progress', icon: '📈' },
  { key: 'activity', label: 'Activity', icon: '🕐' },
  { key: 'info', label: 'Batch Info', icon: 'ℹ️' },
  { key: 'faq', label: 'FAQ / Help', icon: '❓' },
] as const
type SectionKey = typeof SECTIONS[number]['key']

function fmtDate(d: any) { try { return new Date(d).toLocaleDateString() } catch { return '' } }
function fmtCountdown(secs: number) {
  if (secs <= 0) return '00:00:00'
  const h = Math.floor(secs / 3600), m = Math.floor((secs % 3600) / 60), s = Math.floor(secs % 60)
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

// ── Exam CTA resolver — mirrors My Exams page launch rules exactly ──
function examCTA(e: any) {
  if (e.derivedStatus === 'ended') {
    if (e.joinState === 'available_again') return { label: 'Attempt / Continue', mode: 'attempt' }
    if (e.performance) return { label: 'View Result', mode: 'result' }
    return { label: 'Locked', mode: 'locked' }
  }
  if (e.activeAttemptId) return { label: 'Resume', mode: 'attempt' }
  if (e.derivedStatus === 'live') {
    if (e.joinState === 'join_open') return { label: 'Join Exam', mode: 'attempt' }
    return { label: 'Join Closed', mode: 'locked' }
  }
  if (e.derivedStatus === 'scheduled') {
    if (e.joinState === 'waiting_room_open') {
      return { label: e.hasJoinedWaitingRoom ? 'Resume Waiting Room' : 'Join Waiting Room', mode: 'waiting' }
    }
    return { label: 'Countdown to Exam', mode: 'countdown' }
  }
  return { label: 'Unavailable', mode: 'locked' }
}

export default function BatchWorkspacePage() {
  const router = useRouter()
  const params = useParams() as any
  const batchId = params?.id as string
  const pageTheme = usePageTheme()
  const vars = THEME_VARS[pageTheme]
  const isDesktop = useIsDesktop()

  const [tok, setTok] = useState('')
  const [section, setSection] = useState<SectionKey>('overview')
  const [restored, setRestored] = useState(false)
  const [overview, setOverview] = useState<any>(null)
  const [exams, setExams] = useState<any[]>([])
  const [announcements, setAnnouncements] = useState<any[]>([])
  const [resources, setResources] = useState<any[]>([])
  const [leaderboard, setLeaderboard] = useState<any>(null)
  const [progress, setProgress] = useState<any>(null)
  const [activity, setActivity] = useState<any>(null)
  const [info, setInfo] = useState<any>(null)
  const [faqs, setFaqs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [toast, setToast] = useState<string | null>(null)
  const [faqSearch, setFaqSearch] = useState('')
  const loadedSections = useRef<Set<string>>(new Set())
  const saveTimer = useRef<ReturnType<typeof setTimeout>>()

  const BG = 'var(--pr-bg)'
  const CARD = 'rgba(var(--pr-card-rgb),0.95)'
  const BORDER = 'rgba(var(--pr-sub-rgb),0.14)'
  const TEXT = 'var(--pr-text)'
  const SUB = 'rgba(var(--pr-sub-rgb),0.76)'
  const ec = (overview && ECOLS[overview.examType]) || '#4D9FFF'

  const showToast = (m: string) => { setToast(m); setTimeout(() => setToast(null), 2600) }

  // ── init: token + restore last section ──
  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t)
    if (!t || !batchId) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/state`, { headers: { Authorization: `Bearer ${t}` } })
      .then(r => r.json()).then(d => { if (d?.state?.lastSection) setSection(d.state.lastSection) })
      .catch(() => {}).finally(() => setRestored(true))
    fetch(`${API}/api/my-batches/${batchId}/access`, { method: 'POST', headers: { Authorization: `Bearer ${t}` } }).catch(() => {})
  }, [batchId])

  // ── persist section changes (debounced) ──
  useEffect(() => {
    if (!restored || !tok || !batchId) return
    if (saveTimer.current) clearTimeout(saveTimer.current)
    saveTimer.current = setTimeout(() => {
      fetch(`${API}/api/student/batch-workspace/${batchId}/state`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` },
        body: JSON.stringify({ lastSection: section })
      }).catch(() => {})
    }, 500)
  }, [section, restored, tok, batchId])

  // ── overview always loads first (drives hero banner) ──
  useEffect(() => {
    if (!tok || !batchId) return
    setLoading(true)
    fetch(`${API}/api/student/batch-workspace/${batchId}/overview`, { headers: { Authorization: `Bearer ${tok}` } })
      .then(r => r.json()).then(d => setOverview(d.workspace || null)).catch(() => {}).finally(() => setLoading(false))
  }, [tok, batchId])

  // ── lazy-load each section on first visit ──
  const loadSection = useCallback((key: SectionKey) => {
    if (!tok || !batchId || loadedSections.current.has(key)) return
    loadedSections.current.add(key)
    const H = { Authorization: `Bearer ${tok}` }
    if (key === 'exams') fetch(`${API}/api/student/batch-workspace/${batchId}/exams`, { headers: H }).then(r => r.json()).then(d => setExams(d.exams || [])).catch(() => {})
    if (key === 'announcements') fetch(`${API}/api/student/batch-workspace/${batchId}/announcements`, { headers: H }).then(r => r.json()).then(d => setAnnouncements(d.announcements || [])).catch(() => {})
    if (key === 'resources') fetch(`${API}/api/student/batch-workspace/${batchId}/resources`, { headers: H }).then(r => r.json()).then(d => setResources(d.resources || [])).catch(() => {})
    if (key === 'leaderboard') fetch(`${API}/api/student/batch-workspace/${batchId}/leaderboard?scope=top50`, { headers: H }).then(r => r.json()).then(d => setLeaderboard(d)).catch(() => {})
    if (key === 'progress') fetch(`${API}/api/student/batch-workspace/${batchId}/progress`, { headers: H }).then(r => r.json()).then(d => setProgress(d)).catch(() => {})
    if (key === 'activity') fetch(`${API}/api/student/batch-workspace/${batchId}/activity`, { headers: H }).then(r => r.json()).then(d => setActivity(d)).catch(() => {})
    if (key === 'info') fetch(`${API}/api/student/batch-workspace/${batchId}/info`, { headers: H }).then(r => r.json()).then(d => setInfo(d.info || null)).catch(() => {})
    if (key === 'faq') fetch(`${API}/api/student/batch-workspace/${batchId}/faq`, { headers: H }).then(r => r.json()).then(d => setFaqs(d.faqs || [])).catch(() => {})
  }, [tok, batchId])

  useEffect(() => { if (restored) loadSection(section) }, [section, restored, loadSection])

  // ── actions ──
  const goSection = (k: SectionKey) => setSection(k)

  const toggleFavorite = async () => {
    if (!tok || !overview) return
    try {
      const r = await fetch(`${API}/api/student/batches/${batchId}/wishlist`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      setOverview((o: any) => ({ ...o, isFavorite: d.isWishlisted }))
      showToast(d.isWishlisted ? '❤️ Added to favorites' : 'Removed from favorites')
    } catch { showToast('Could not update favorite') }
  }

  const shareBatch = async () => {
    const url = typeof window !== 'undefined' ? window.location.href : ''
    const title = overview?.name || 'ProveRank Batch'
    try {
      if (navigator.share) await navigator.share({ title, url })
      else { await navigator.clipboard.writeText(url); showToast('🔗 Link copied to clipboard') }
    } catch {}
  }

  const toggleReminder = async (examId: string, enabled: boolean) => {
    if (!tok) return
    try {
      await fetch(`${API}/api/exams/${examId}/reminder`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` }, body: JSON.stringify({ enabled })
      })
      setExams(list => list.map(e => e._id === examId ? { ...e, reminderEnabled: enabled } : e))
      showToast(enabled ? '🔔 Reminder set' : 'Reminder removed')
    } catch {}
  }

  const launchExam = async (e: any) => {
    const cta = examCTA(e)
    if (cta.mode === 'locked' || cta.mode === 'countdown') return
    if (cta.mode === 'result') { router.push(EXAM_ROUTES.result(e._id)); return }
    if (cta.mode === 'attempt') {
      if (e.activeAttemptId || e.skipWaitingRoom || e.derivedStatus === 'ended' || e.derivedStatus === 'live') {
        router.push(EXAM_ROUTES.attempt(e._id)); return
      }
    }
    if (cta.mode === 'waiting') {
      if (e.hasJoinedWaitingRoom) { router.push(EXAM_ROUTES.waitingRoom(e._id)); return }
      try {
        await fetch(`${API}/api/exams/${e._id}/join-waiting-room`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      } catch {}
      router.push(EXAM_ROUTES.waitingRoom(e._id))
    }
  }

  const markResourceViewed = (noteId: string) => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/resources/${noteId}/view`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } }).catch(() => {})
    setResources(list => list.map(r => r._id === noteId ? { ...r, viewed: true } : r))
  }

  const togglePinResource = (noteId: string) => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/resources/${noteId}/pin`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      .then(r => r.json()).then(d => setResources(list => list.map(r => r._id === noteId ? { ...r, studentPinned: d.pinned } : r))).catch(() => {})
  }

  const markAnnRead = (annId: string) => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/announcements/${annId}/read`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } }).catch(() => {})
    setAnnouncements(list => list.map(a => a._id === annId ? { ...a, isRead: true } : a))
  }

  const markAllAnnRead = () => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/announcements/read-all`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } }).catch(() => {})
    setAnnouncements(list => list.map(a => ({ ...a, isRead: true })))
    showToast('✅ All marked as read')
  }

  // ── quick actions (context-aware) ──
  const quickActions = [
    { label: '▶️ Continue', onClick: () => goSection('exams') },
    { label: '📝 My Exams', onClick: () => goSection('exams') },
    { label: '🏆 Leaderboard', onClick: () => goSection('leaderboard') },
    { label: '📚 Resources', onClick: () => goSection('resources') },
    { label: '📈 Progress', onClick: () => goSection('progress') },
    { label: overview?.isFavorite ? '💔 Unfavorite' : '❤️ Favorite', onClick: toggleFavorite },
    { label: '🔗 Share', onClick: shareBatch },
    { label: '❓ FAQ', onClick: () => goSection('faq') },
  ]

  const inp = { padding: '8px 12px', background: 'rgba(var(--pr-sub-rgb),0.08)', border: `1px solid ${BORDER}`, borderRadius: 10, color: TEXT, fontSize: 12, outline: 'none' as const, width: '100%' }
  const sectionCard = { background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 16, backdropFilter: 'blur(16px)' as const, marginBottom: 12 }

  return (
    <StudentShell pageKey="my-batches">
      <div style={{ minHeight: '100vh', color: TEXT, fontFamily: 'Inter,sans-serif', position: 'relative', overflowX: 'hidden', background: BG, ...(vars as any) }}>
        <style>{`
          @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700;800&display=swap');
          *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
          @keyframes slideUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
        `}</style>

        <div style={{ position: 'relative', zIndex: 2, maxWidth: 1180, margin: '0 auto', padding: '14px 14px 100px', display: isDesktop ? 'grid' : 'block', gridTemplateColumns: isDesktop ? '220px 1fr 260px' : undefined, gap: isDesktop ? 18 : 0 }}>

          {/* ── DESKTOP LEFT RAIL ── */}
          {isDesktop && (
            <div style={{ position: 'sticky', top: 14, alignSelf: 'start' }}>
              <button onClick={() => router.push('/dashboard/my-batches')} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '7px 12px', color: SUB, fontSize: 11, cursor: 'pointer', marginBottom: 14 }}>← My Batches</button>
              <div style={sectionCard}>
                {SECTIONS.map(s => (
                  <button key={s.key} onClick={() => goSection(s.key)}
                    style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', textAlign: 'left', padding: '9px 10px', borderRadius: 10, marginBottom: 4, background: section === s.key ? `${ec}18` : 'transparent', border: 'none', color: section === s.key ? ec : SUB, fontWeight: section === s.key ? 700 : 500, cursor: 'pointer', fontSize: 12.5 }}>
                    <span>{s.icon}</span>{s.label}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* ── MOBILE TOP BAR + CHIPS ── */}
          {!isDesktop && (
            <>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
                <button onClick={() => router.push('/dashboard/my-batches')} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '7px 10px', color: SUB, fontSize: 13, cursor: 'pointer' }}>←</button>
                <div style={{ fontSize: 14, fontWeight: 700, color: TEXT, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{overview?.name || 'Workspace'}</div>
              </div>
              <div style={{ display: 'flex', gap: 6, overflowX: 'auto', marginBottom: 12, paddingBottom: 4 }}>
                {SECTIONS.map(s => (
                  <button key={s.key} onClick={() => goSection(s.key)}
                    style={{ flexShrink: 0, padding: '7px 12px', borderRadius: 20, fontSize: 11, whiteSpace: 'nowrap', cursor: 'pointer', background: section === s.key ? `${ec}20` : CARD, border: `1px solid ${section === s.key ? ec + '50' : BORDER}`, color: section === s.key ? ec : SUB, fontWeight: section === s.key ? 700 : 500 }}>
                    {s.icon} {s.label}
                  </button>
                ))}
              </div>
            </>
          )}

          {/* ── CENTER CONTENT ── */}
          <div>
            {/* HERO SUMMARY BANNER */}
            {overview && (
              <div style={{ ...sectionCard, border: `1px solid ${ec}28`, animation: 'slideUp 0.3s ease' }}>
                <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
                  <div style={{ width: 52, height: 52, borderRadius: 14, background: `${ec}18`, border: `1px solid ${ec}30`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, flexShrink: 0 }}>{overview.colorIcon || '📦'}</div>
                  <div style={{ flex: 1, minWidth: 180 }}>
                    <div style={{ fontFamily: 'Playfair Display,serif', fontSize: isDesktop ? 20 : 16, fontWeight: 700, color: TEXT }}>{overview.name}</div>
                    <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>
                      {overview.examType} · {overview.testsAttempted}/{overview.totalTests} tests · {overview.progress}% complete · {overview.daysLeft}d left
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button onClick={toggleFavorite} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '8px 10px', color: overview.isFavorite ? '#FF6B6B' : SUB, cursor: 'pointer', fontSize: 15 }}>{overview.isFavorite ? '❤️' : '🤍'}</button>
                    <button onClick={shareBatch} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '8px 10px', color: SUB, cursor: 'pointer', fontSize: 15 }}>🔗</button>
                  </div>
                </div>
              </div>
            )}

            {loading && !overview && <div style={{ textAlign: 'center', padding: 40, color: SUB }}>Loading workspace…</div>}

            {/* ═══ OVERVIEW ═══ */}
            {section === 'overview' && overview && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(110px,1fr))', gap: 8, marginBottom: 12 }}>
                  {[
                    { l: 'Tests Completed', v: overview.testsAttempted, i: '✅' },
                    { l: 'Total Planned', v: overview.totalTests, i: '📋' },
                    { l: 'Current Rank', v: overview.currentRank ? `#${overview.currentRank}` : '—', i: '🏅' },
                    { l: 'Days Left', v: overview.daysLeft, i: '⏳' },
                  ].map((s, i) => (
                    <div key={i} style={{ ...sectionCard, textAlign: 'center', marginBottom: 0, padding: 12 }}>
                      <div style={{ fontSize: 16 }}>{s.i}</div>
                      <div style={{ fontSize: 18, fontWeight: 800, color: ec }}>{s.v}</div>
                      <div style={{ fontSize: 9, color: SUB }}>{s.l}</div>
                    </div>
                  ))}
                </div>

                {overview.nextTest && (
                  <div style={sectionCard}>
                    <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 6 }}>⏰ Next Test</div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{overview.nextTest.title}</div>
                    <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>{fmtDate(overview.nextTest.startTime)}</div>
                  </div>
                )}

                {overview.latestAnnouncement && (
                  <div style={sectionCard}>
                    <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 6 }}>📢 Latest Announcement</div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{overview.latestAnnouncement.title}</div>
                    <button onClick={() => goSection('announcements')} style={{ marginTop: 6, background: 'transparent', border: `1px solid ${ec}40`, borderRadius: 8, padding: '4px 10px', color: ec, fontSize: 10, cursor: 'pointer' }}>View all →</button>
                  </div>
                )}

                {overview.latestActivity && (
                  <div style={sectionCard}>
                    <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 6 }}>🕐 Latest Activity</div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{overview.latestActivity.icon} {overview.latestActivity.title}</div>
                  </div>
                )}

                <div style={sectionCard}>
                  <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 10 }}>⚡ Quick Actions</div>
                  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                    {quickActions.map((a, i) => (
                      <button key={i} onClick={a.onClick} style={{ padding: '8px 12px', borderRadius: 10, background: `${ec}14`, border: `1px solid ${ec}28`, color: ec, fontSize: 11, fontWeight: 700, cursor: 'pointer' }}>{a.label}</button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ═══ EXAMS ═══ */}
            {section === 'exams' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {exams.length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}>
                    <div style={{ fontSize: 40, marginBottom: 8 }}>📭</div>
                    <div style={{ fontSize: 13, color: SUB }}>No exams scheduled yet in this batch.</div>
                  </div>
                ) : exams.map(e => {
                  const cta = examCTA(e)
                  const isLive = e.derivedStatus === 'live'
                  return (
                    <div key={e._id} style={{ ...sectionCard, position: 'relative' }}>
                      {isLive && <div style={{ position: 'absolute', top: 10, right: 12, background: 'rgba(231,76,60,0.16)', color: '#E74C3C', fontSize: 9, fontWeight: 800, padding: '2px 8px', borderRadius: 20, animation: 'slideUp 0.3s ease' }}>🔴 LIVE</div>}
                      <div style={{ fontSize: 13, fontWeight: 700 }}>{e.title}</div>
                      <div style={{ fontSize: 10, color: SUB, marginTop: 3 }}>{e.subject || 'General'} · {e.duration}min · {e.totalMarks} marks</div>
                      {e.schedule?.startTime && <div style={{ fontSize: 10, color: SUB, marginTop: 2 }}>📅 {fmtDate(e.schedule.startTime)}</div>}
                      {e.performance?.bestScore != null && <div style={{ fontSize: 10, color: '#27AE60', marginTop: 2 }}>Best: {e.performance.bestScore}</div>}
                      <div style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap' }}>
                        <button disabled={cta.mode === 'locked' || cta.mode === 'countdown'} onClick={() => launchExam(e)}
                          style={{ flex: 1, minWidth: 140, padding: '9px', borderRadius: 10, border: 'none', color: (cta.mode === 'locked' || cta.mode === 'countdown') ? SUB : '#fff', background: (cta.mode === 'locked' || cta.mode === 'countdown') ? 'rgba(255,255,255,0.06)' : `linear-gradient(135deg,${ec},${ec}BB)`, fontWeight: 700, fontSize: 11, cursor: (cta.mode === 'locked' || cta.mode === 'countdown') ? 'default' : 'pointer' }}>
                          {cta.mode === 'countdown' && e.secsToStart != null ? `⏳ ${fmtCountdown(e.secsToStart)}` : cta.label}
                        </button>
                        {cta.mode === 'countdown' && (
                          <button onClick={() => toggleReminder(e._id, !e.reminderEnabled)} style={{ padding: '9px 12px', borderRadius: 10, background: e.reminderEnabled ? `${ec}18` : 'rgba(255,255,255,0.06)', border: `1px solid ${ec}30`, color: ec, fontSize: 13, cursor: 'pointer' }}>{e.reminderEnabled ? '🔔' : '🔕'}</button>
                        )}
                      </div>
                    </div>
                  )
                })}
              </div>
            )}

            {/* ═══ ANNOUNCEMENTS ═══ */}
            {section === 'announcements' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {announcements.length > 0 && (
                  <button onClick={markAllAnnRead} style={{ marginBottom: 10, background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '7px 12px', color: SUB, fontSize: 11, cursor: 'pointer' }}>✓ Mark all as read</button>
                )}
                {announcements.length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}><div style={{ fontSize: 40, marginBottom: 8 }}>📪</div><div style={{ fontSize: 13, color: SUB }}>No announcements yet.</div></div>
                ) : announcements.map(a => (
                  <div key={a._id} onClick={() => !a.isRead && markAnnRead(a._id)} style={{ ...sectionCard, cursor: a.isRead ? 'default' : 'pointer', opacity: a.isRead ? 0.75 : 1 }}>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 4 }}>
                      {a.pinned && <span style={{ fontSize: 10 }}>📌</span>}
                      {!a.isRead && <span style={{ width: 7, height: 7, borderRadius: '50%', background: ec, display: 'inline-block' }} />}
                      <span style={{ fontSize: 9, background: `${ec}16`, color: ec, padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>{a.type}</span>
                    </div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{a.title}</div>
                    <div style={{ fontSize: 11, color: SUB, marginTop: 4 }} dangerouslySetInnerHTML={{ __html: a.message }} />
                    <div style={{ fontSize: 9, color: SUB, marginTop: 6 }}>{fmtDate(a.createdAt)}</div>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ RESOURCES ═══ */}
            {section === 'resources' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {resources.length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}><div style={{ fontSize: 40, marginBottom: 8 }}>📁</div><div style={{ fontSize: 13, color: SUB }}>No resources added yet for this batch.</div></div>
                ) : resources.map(r => (
                  <div key={r._id} style={sectionCard}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginBottom: 4, flexWrap: 'wrap' }}>
                          <span style={{ fontSize: 9, background: `${ec}16`, color: ec, padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>{r.type}</span>
                          {r.recentlyAdded && <span style={{ fontSize: 9, background: 'rgba(39,174,96,0.14)', color: '#27AE60', padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>NEW</span>}
                          {r.viewed && <span style={{ fontSize: 9, color: SUB }}>✓ Viewed</span>}
                        </div>
                        <div style={{ fontSize: 13, fontWeight: 700 }}>{r.title}</div>
                        {r.description && <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>{r.description}</div>}
                      </div>
                      <button onClick={() => togglePinResource(r._id)} style={{ background: 'transparent', border: 'none', color: r.studentPinned ? '#FFD700' : SUB, cursor: 'pointer', fontSize: 15, flexShrink: 0 }}>📌</button>
                    </div>
                    <a href={r.url} target="_blank" rel="noreferrer" onClick={() => markResourceViewed(r._id)}
                      style={{ display: 'inline-block', marginTop: 10, padding: '8px 14px', borderRadius: 10, background: `linear-gradient(135deg,${ec},${ec}BB)`, color: '#fff', fontWeight: 700, fontSize: 11, textDecoration: 'none' }}>Open →</a>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ LEADERBOARD ═══ */}
            {section === 'leaderboard' && leaderboard && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {leaderboard.myRank && (
                  <div style={{ ...sectionCard, border: `1px solid ${ec}30` }}>
                    <div style={{ fontSize: 12, color: SUB }}>Your Rank</div>
                    <div style={{ fontSize: 22, fontWeight: 900, color: ec }}>#{leaderboard.myRank} <span style={{ fontSize: 12, color: SUB, fontWeight: 400 }}>of {leaderboard.total}</span></div>
                    {leaderboard.percentile != null && <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>Top {100 - leaderboard.percentile}% percentile</div>}
                    {leaderboard.topper && <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>🥇 Topper: {leaderboard.topper.name} ({leaderboard.topper.avgScore.toFixed(1)}% avg)</div>}
                  </div>
                )}
                <div style={sectionCard}>
                  {(leaderboard.leaderboard || []).map((l: any, i: number) => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                      <div style={{ width: 26, height: 26, borderRadius: '50%', background: i === 0 ? 'linear-gradient(135deg,#FFD700,#FFA000)' : i === 1 ? 'linear-gradient(135deg,#C0C0C0,#9E9E9E)' : i === 2 ? 'linear-gradient(135deg,#CD7F32,#A0522D)' : 'rgba(77,159,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: i < 3 ? 13 : 10, fontWeight: 900, color: i < 3 ? '#000' : SUB }}>{i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : i + 1}</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 12, fontWeight: 700 }}>{l.name}</div>
                        <div style={{ fontSize: 10, color: SUB }}>📝 {l.testsCompleted} tests · ⭐ {l.avgScore.toFixed(1)}% avg · 🔥 {l.streak}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ═══ PROGRESS ═══ */}
            {section === 'progress' && progress && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(110px,1fr))', gap: 8, marginBottom: 12 }}>
                  {[
                    { l: 'Tests Attempted', v: progress.testsAttempted, i: '📝' },
                    { l: 'Accuracy', v: `${progress.accuracy}%`, i: '🎯' },
                    { l: 'Avg Score', v: progress.avgScore, i: '📊' },
                    { l: 'Completion', v: `${progress.completionPct}%`, i: '✅' },
                  ].map((s, i) => (
                    <div key={i} style={{ ...sectionCard, textAlign: 'center', marginBottom: 0, padding: 12 }}>
                      <div style={{ fontSize: 16 }}>{s.i}</div>
                      <div style={{ fontSize: 18, fontWeight: 800, color: ec }}>{s.v}</div>
                      <div style={{ fontSize: 9, color: SUB }}>{s.l}</div>
                    </div>
                  ))}
                </div>
                {progress.weakSubjects?.length > 0 && (
                  <div style={sectionCard}><div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>⚠️ Weak Subjects</div>
                    {progress.weakSubjects.map((w: any, i: number) => <div key={i} style={{ fontSize: 12, marginBottom: 4 }}>{w.subject}: <span style={{ color: '#E74C3C', fontWeight: 700 }}>{w.accuracy}%</span></div>)}
                  </div>
                )}
                {progress.strongSubjects?.length > 0 && (
                  <div style={sectionCard}><div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>💪 Strong Subjects</div>
                    {progress.strongSubjects.map((w: any, i: number) => <div key={i} style={{ fontSize: 12, marginBottom: 4 }}>{w.subject}: <span style={{ color: '#27AE60', fontWeight: 700 }}>{w.accuracy}%</span></div>)}
                  </div>
                )}
              </div>
            )}

            {/* ═══ ACTIVITY ═══ */}
            {section === 'activity' && activity && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <div style={sectionCard}>
                  <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>🏅 Milestones</div>
                  <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
                    {(activity.milestones || []).map((m: any, i: number) => (
                      <span key={i} style={{ fontSize: 9, padding: '2px 8px', borderRadius: 20, fontWeight: 700, background: m.achieved ? 'rgba(39,174,96,0.14)' : 'rgba(var(--pr-sub-rgb),0.08)', color: m.achieved ? '#27AE60' : SUB }}>{m.achieved ? '✓' : '○'} {m.label}</span>
                    ))}
                  </div>
                </div>
                {(activity.activity || []).length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}><div style={{ fontSize: 13, color: SUB }}>No activity yet.</div></div>
                ) : (activity.activity || []).map((a: any, i: number) => (
                  <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start', padding: '9px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                    <span style={{ fontSize: 18, flexShrink: 0 }}>{a.icon}</span>
                    <div><div style={{ fontSize: 12, fontWeight: 700 }}>{a.title}</div>{a.message && <div style={{ fontSize: 10, color: SUB, marginTop: 2 }}>{a.message}</div>}<div style={{ fontSize: 9, color: SUB, marginTop: 3 }}>{fmtDate(a.at)}</div></div>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ BATCH INFO ═══ */}
            {section === 'info' && info && (
              <div style={{ ...sectionCard, animation: 'slideUp 0.3s ease' }}>
                {[
                  ['Name', info.name], ['Code', info.batchCode || '—'], ['Faculty', info.teacherAssigned || '—'],
                  ['Subject', info.subject], ['Type', info.batchType], ['Language', info.language],
                  ['Start Date', info.startDate ? fmtDate(info.startDate) : '—'], ['End Date', info.endDate ? fmtDate(info.endDate) : '—'],
                  ['Enrolled', fmtDate(info.enrolledAt)], ['Expires', fmtDate(info.expiresAt)],
                  ['Total Tests', info.totalTests], ['Access Status', info.accessStatus],
                ].map(([l, v], i) => (
                  <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                    <span style={{ fontSize: 11, color: SUB }}>{l}</span><span style={{ fontSize: 12, fontWeight: 700 }}>{String(v)}</span>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ FAQ ═══ */}
            {section === 'faq' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <input value={faqSearch} onChange={e => setFaqSearch(e.target.value)} placeholder="🔎 Search FAQ…" style={{ ...inp, marginBottom: 10 }} />
                {faqs.filter(f => !faqSearch || f.q.toLowerCase().includes(faqSearch.toLowerCase()) || f.a.toLowerCase().includes(faqSearch.toLowerCase())).map((f, i) => (
                  <div key={i} style={sectionCard}>
                    <div style={{ fontSize: 12, fontWeight: 700, marginBottom: 5 }}>❓ {f.q}</div>
                    <div style={{ fontSize: 11, color: SUB }}>{f.a}</div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* ── DESKTOP RIGHT: STICKY QUICK ACTIONS ── */}
          {isDesktop && (
            <div style={{ position: 'sticky', top: 14, alignSelf: 'start' }}>
              <div style={sectionCard}>
                <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 10 }}>⚡ Quick Actions</div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 7 }}>
                  {quickActions.map((a, i) => (
                    <button key={i} onClick={a.onClick} style={{ textAlign: 'left', padding: '9px 12px', borderRadius: 10, background: `${ec}14`, border: `1px solid ${ec}28`, color: ec, fontSize: 12, fontWeight: 700, cursor: 'pointer' }}>{a.label}</button>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* ── MOBILE BOTTOM QUICK ACTIONS ── */}
        {!isDesktop && (
          <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 50, background: 'rgba(var(--pr-card-rgb),0.98)', borderTop: `1px solid ${BORDER}`, padding: '8px 10px', display: 'flex', gap: 6, overflowX: 'auto', backdropFilter: 'blur(20px)' }}>
            {quickActions.map((a, i) => (
              <button key={i} onClick={a.onClick} style={{ flexShrink: 0, padding: '8px 12px', borderRadius: 20, background: `${ec}16`, border: `1px solid ${ec}30`, color: ec, fontSize: 11, fontWeight: 700, cursor: 'pointer', whiteSpace: 'nowrap' }}>{a.label}</button>
            ))}
          </div>
        )}

        {toast && <div style={{ position: 'fixed', bottom: isDesktop ? 24 : 66, left: '50%', transform: 'translateX(-50%)', zIndex: 2000, background: 'rgba(20,20,35,0.95)', border: '1px solid rgba(77,159,255,0.35)', borderRadius: 12, padding: '10px 18px', fontSize: 12, color: '#fff', fontWeight: 600, boxShadow: '0 10px 30px rgba(0,0,0,0.4)', whiteSpace: 'nowrap' }}>{toast}</div>}
      </div>
    </StudentShell>
  )
}

PRWSPAGEEOF
echo "✔ Created: $WORKSPACE_DIR/page.tsx"

echo ""
echo "════════════════════════════════════════════"
echo "STEP 5 — Frontend: wire 'Continue' / 'Resume' buttons to the Workspace"
echo "════════════════════════════════════════════"
if [ -n "$MYBATCHES_PAGE" ]; then
  cp "$MYBATCHES_PAGE" "$MYBATCHES_PAGE.bak.$(date +%s)"
  echo "✔ Backed up: $MYBATCHES_PAGE"

  COUNT_BEFORE=$(grep -c "Workspace is coming soon" "$MYBATCHES_PAGE" || true)
  if [ "$COUNT_BEFORE" != "2" ]; then
    echo "⚠️  Expected exactly 2 'coming soon' placeholders, found $COUNT_BEFORE."
    echo "   Skipping this patch to avoid touching the wrong lines — apply it manually or share the current file so I can adjust."
  else
    perl -0777 -pi -e '
      s/onClick=\{\(\)=>\{accessBatch\(lastAccessed\._id\);setWsMsg\(`📚 \$\{lastAccessed\._kind===.series.\?.Test Series.:.Batch.\} Workspace is coming soon!`\);setTimeout\(\(\)=>setWsMsg\(null\),3000\)\}\}/onClick={()=>{accessBatch(lastAccessed._id);router.push(`\/dashboard\/my-batches\/\${lastAccessed._id}`)}}/;
      s/onClick=\{\(\)=>\{accessBatch\(b\._id\);setWsMsg\(`📚 \$\{b\._kind===.series.\?.Test Series.:.Batch.\} Workspace is coming soon!`\);setTimeout\(\(\)=>setWsMsg\(null\),3000\)\}\}/onClick={()=>{accessBatch(b._id);router.push(`\/dashboard\/my-batches\/\${b._id}`)}}/;
    ' "$MYBATCHES_PAGE"

    COUNT_AFTER=$(grep -c "Workspace is coming soon" "$MYBATCHES_PAGE" || true)
    COUNT_NEW=$(grep -c "router.push(\`/dashboard/my-batches/" "$MYBATCHES_PAGE" || true)
    if [ "$COUNT_AFTER" = "0" ] && [ "$COUNT_NEW" -ge "2" ]; then
      echo "✔ Both Continue/Resume buttons now open the Workspace ($COUNT_NEW push call(s) added)"
    else
      echo "❌ Patch did not apply cleanly — restoring backup automatically."
      cp "$MYBATCHES_PAGE.bak."* "$MYBATCHES_PAGE" 2>/dev/null || true
      echo "   Restored original file. Please share the current page.tsx again so I can fix the exact match."
    fi
  fi
else
  echo "⏭  Skipped (file not found earlier)."
fi

echo ""
echo "════════════════════════════════════════════"
echo "✅ DONE — Summary"
echo "════════════════════════════════════════════"
echo "New:      $ROUTES_DIR/studentBatchWorkspace.js"
echo "Updated:  $MODELS_DIR/BatchNote.js (+viewedBy field)"
echo "Patched:  $BACKEND_ENTRY (mounted /api/student/batch-workspace)"
echo "New:      $WORKSPACE_DIR/page.tsx"
echo "Patched:  $MYBATCHES_PAGE (Continue/Resume → open Workspace)"
echo ""
echo "⚠️  VERIFY BEFORE TESTING:"
echo "  1) In the new Workspace page.tsx, check the EXAM_ROUTES constant —"
echo "     'result' path is a best-guess (/exam/:id/result). Tell me the"
echo "     real route from your My Exams page if it's different."
echo "  2) Restart backend: pkill -f node; cd ~/workspace && node src/index.js"
echo "  3) Test flow: My Batches → Continue → Workspace opens → switch all"
echo "     9 sections → refresh page → confirm it restores the last section."
