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

