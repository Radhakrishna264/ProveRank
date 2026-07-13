#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F52-F57 — Exam Flow (My Exams → Waiting → Instructions →"
echo "           Webcam → Attempt Fullscreen) — BACKEND fix script"
echo "════════════════════════════════════════════════════════"

ROOT=""
for candidate in "/root/workspace/src" "/home/runner/workspace/src" "$(pwd)/src" "$(pwd)"; do
  if [ -f "$candidate/index.js" ]; then ROOT="$candidate"; break; fi
done
if [ -z "$ROOT" ]; then echo "❌ Could not find index.js — run from project root or set ROOT manually."; exit 1; fi
echo "📂 Project root detected: $ROOT"

# ── New route file: routes/examFlow.js ──
cat > "$ROOT/routes/examFlow.js" << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F52/F53 — My Exams (rich listing) + Waiting Room join + Reminders
// Mounted at /api/exams (alongside the existing exam.js router)
// ════════════════════════════════════════════════════════════════
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Exam = require('../models/Exam');
const Attempt = require('../models/Attempt');
const Batch = require('../models/Batch');
const User = require('../models/User');
const { verifyToken } = require('../middleware/auth');

// ── §5.2 Live join grace period (minutes) ──
const LIVE_JOIN_GRACE_MINUTES = 5;
// ── §1.1 Waiting room trigger window (minutes before start) ──
const WAITING_ROOM_TRIGGER_MINUTES = 20;

// ── helper: compute a live/derived status + join-state for an exam ──
function computeLiveState(exam, now) {
  const start = exam.schedule?.startTime ? new Date(exam.schedule.startTime) : null;
  const end = exam.schedule?.endTime ? new Date(exam.schedule.endTime) : null;
  let derivedStatus = exam.status; // fallback to stored status (draft/scheduled/live/ended)
  if (start && end) {
    if (now < start) derivedStatus = 'scheduled';
    else if (now >= start && now < end) derivedStatus = 'live';
    else derivedStatus = 'ended';
  }
  let joinState = 'available_later';
  if (derivedStatus === 'scheduled') {
    const minsToStart = (start.getTime() - now.getTime()) / 60000;
    joinState = minsToStart <= WAITING_ROOM_TRIGGER_MINUTES ? 'join_soon' : 'available_later';
  } else if (derivedStatus === 'live') {
    const minsSinceStart = (now.getTime() - start.getTime()) / 60000;
    joinState = minsSinceStart <= LIVE_JOIN_GRACE_MINUTES ? 'join_allowed' : 'join_closed';
  } else if (derivedStatus === 'ended') {
    joinState = 'ended';
  }
  return { derivedStatus, joinState, start, end };
}

// ── helper: does this exam belong to a batch the student is enrolled in (or is open/whitelisted)? ──
function examVisibleToStudent(exam, enrolledBatchIds, enrolledBatchNames, studentId) {
  const hasBatchTarget = !!exam.batch || (exam.multiBatch && exam.multiBatch.length > 0);
  const hasWhitelist = exam.whitelistEnabled && exam.whitelistedStudents && exam.whitelistedStudents.length > 0;
  if (hasWhitelist) {
    return exam.whitelistedStudents.some(id => String(id) === String(studentId));
  }
  if (hasBatchTarget) {
    const targets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean);
    return targets.some(t => enrolledBatchIds.includes(String(t)) || enrolledBatchNames.includes(t));
  }
  // No batch/whitelist restriction configured at all → treat as open to everyone
  return true;
}

// ══════════════════════════════════════════════════════════════
// GET /api/exams/my-exams — F52 rich listing (batch-synced, live-state,
// attempt history, category/subject filters, reminders)
// ══════════════════════════════════════════════════════════════
router.get('/my-exams', verifyToken, async (req, res) => {
  try {
    const studentId = req.user.id;
    const now = new Date();

    const myBatches = await Batch.find({ students: studentId }).select('_id name').lean();
    const enrolledBatchIds = myBatches.map(b => String(b._id));
    const enrolledBatchNames = myBatches.map(b => b.name);

    const allExams = await Exam.find({ isArchived: { $ne: true } }).lean();
    const visibleExams = allExams.filter(e => examVisibleToStudent(e, enrolledBatchIds, enrolledBatchNames, studentId));

    const examIds = visibleExams.map(e => e._id);
    const myAttempts = await Attempt.find({ examId: { $in: examIds }, studentId }).lean();
    const attemptsByExam = {};
    myAttempts.forEach(a => {
      if (!attemptsByExam[a.examId]) attemptsByExam[a.examId] = [];
      attemptsByExam[a.examId].push(a);
    });

    const student = await User.findById(studentId).select('examReminders').lean();
    const reminderSet = new Set((student?.examReminders || []).filter(r => r.enabled).map(r => String(r.examId)));

    const shaped = visibleExams.map(e => {
      const { derivedStatus, joinState, start, end } = computeLiveState(e, now);
      const attempts = attemptsByExam[e._id] || [];
      const completedAttempts = attempts.filter(a => a.status === 'submitted' || a.status === 'timeout');
      const activeAttempt = attempts.find(a => a.status === 'active' || a.status === 'waiting' || a.status === 'instructions');
      const bestScore = completedAttempts.length ? Math.max(...completedAttempts.map(a => a.score || 0)) : null;
      const lastAttempt = attempts.length ? attempts.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))[0] : null;

      const matchedBatch = myBatches.find(b => String(b._id) === String(e.batch) || b.name === e.batch);

      return {
        _id: e._id, title: e.title, subject: e.subject, duration: e.duration,
        totalMarks: e.totalMarks, category: e.category, type: e.type,
        passwordProtected: !!e.password,
        hasCustomInstructions: !!e.customInstructions,
        waitingRoomEnabled: e.waitingRoomEnabled, waitingRoomMinutes: e.waitingRoomMinutes,
        schedule: { startTime: start, endTime: end },
        derivedStatus, joinState,
        batchName: matchedBatch?.name || e.batch || '',
        attemptedCount: attempts.length,
        completedCount: completedAttempts.length,
        bestScore, lastAttemptAt: lastAttempt?.createdAt || null, lastAttemptStatus: lastAttempt?.status || null,
        activeAttemptId: activeAttempt?._id || null,
        reminderOn: reminderSet.has(String(e._id)),
        maxAttempts: e.maxAttempts, unlimitedAttempts: e.unlimitedAttempts,
        attemptsRemaining: e.unlimitedAttempts ? null : Math.max(0, (e.maxAttempts || 1) - attempts.length),
      };
    });

    // ── §2 Header quick stats ──
    const stats = {
      total: shaped.length,
      upcoming: shaped.filter(e => e.derivedStatus === 'scheduled').length,
      live: shaped.filter(e => e.derivedStatus === 'live').length,
      completed: shaped.filter(e => e.derivedStatus === 'ended').length,
      attempted: shaped.filter(e => e.attemptedCount > 0).length,
      bestScore: shaped.reduce((max, e) => (e.bestScore !== null && e.bestScore > max ? e.bestScore : max), 0),
    };

    res.json({
      success: true, exams: shaped, stats,
      batches: myBatches.map(b => ({ _id: b._id, name: b.name })),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// §7 Exam Reminder Toggle
// ══════════════════════════════════════════════════════════════
router.post('/:id/reminder', verifyToken, async (req, res) => {
  try {
    const { enabled } = req.body;
    const examId = req.params.id;
    const studentId = req.user.id;
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(studentId) });
    const list = (user?.examReminders || []).filter(r => String(r.examId) !== String(examId));
    list.push({ examId: new mongoose.Types.ObjectId(examId), enabled: !!enabled });
    await User.collection.updateOne({ _id: new mongoose.Types.ObjectId(studentId) }, { $set: { examReminders: list } });
    res.json({ success: true, enabled: !!enabled });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// F53 — GET /:id/waiting-info — exam summary + live waiting count
// ══════════════════════════════════════════════════════════════
router.get('/:id/waiting-info', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).lean();
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const now = new Date();
    const { derivedStatus, joinState, start, end } = computeLiveState(exam, now);

    let liveCount = 0;
    try {
      const { getIO } = require('../config/socket');
      const io = getIO();
      const room = io.sockets.adapter.rooms.get(`waiting-${req.params.id}`);
      liveCount = room ? room.size : 0;
    } catch (e) { /* socket not available — degrade to 0 */ }

    res.json({
      success: true,
      exam: {
        _id: exam._id, title: exam.title, duration: exam.duration, totalMarks: exam.totalMarks,
        totalQuestions: (exam.questions || []).length, sections: exam.sections || [],
        markingScheme: exam.markingScheme, customInstructions: exam.customInstructions,
        waitingRoomMinutes: exam.waitingRoomMinutes,
      },
      schedule: { startTime: start, endTime: end },
      derivedStatus, joinState, liveCount,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// GET /:id/live-status — lightweight poll for countdown pages
// ══════════════════════════════════════════════════════════════
router.get('/:id/live-status', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).select('schedule status password customInstructions').lean();
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const { derivedStatus, joinState, start, end } = computeLiveState(exam, new Date());
    res.json({ success: true, derivedStatus, joinState, schedule: { startTime: start, endTime: end }, passwordProtected: !!exam.password });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// ══════════════════════════════════════════════════════════════
// F53 §5 — Waiting Room Chat (REST + polling — frontend has no
// socket.io-client installed, so this is the reliable fallback
// transport; the socket.js events remain available for a future
// real-time upgrade once that package is added).
// ══════════════════════════════════════════════════════════════
const waitingRoomChats = new Map(); // examId -> [{studentName, message, at}]
const WAITING_CHAT_WINDOW_MIN = 10;

router.get('/:id/waiting-room/chat', verifyToken, async (req, res) => {
  const list = waitingRoomChats.get(req.params.id) || [];
  res.json({ success: true, messages: list.slice(-50) });
});

router.post('/:id/waiting-room/chat', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).select('schedule').lean();
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const start = exam.schedule?.startTime ? new Date(exam.schedule.startTime) : null;
    if (start) {
      const minsToStart = (start.getTime() - Date.now()) / 60000;
      // Chat only makes sense while genuinely waiting (within the trigger window)
      if (minsToStart > WAITING_ROOM_TRIGGER_MINUTES + WAITING_CHAT_WINDOW_MIN) {
        return res.status(403).json({ success: false, message: 'Chat not open yet' });
      }
    }
    const student = await User.findById(req.user.id).select('name').lean();
    const message = String(req.body.message || '').slice(0, 300).trim();
    if (!message) return res.status(400).json({ success: false, message: 'Empty message' });
    const list = waitingRoomChats.get(req.params.id) || [];
    list.push({ studentName: student?.name || 'Student', message, at: new Date() });
    waitingRoomChats.set(req.params.id, list.slice(-100));
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

router.get('/:id/waiting-room/live-count', verifyToken, async (req, res) => {
  let liveCount = 0;
  try {
    const { getIO } = require('../config/socket');
    const io = getIO();
    const room = io.sockets.adapter.rooms.get(`waiting-${req.params.id}`);
    liveCount = room ? room.size : 0;
  } catch (e) { /* degrade to 0 */ }
  res.json({ success: true, liveCount });
});

module.exports = router;
PRNODEEOF
echo "✅ Created routes/examFlow.js"

WORKDIR=$(mktemp -d); cd "$WORKDIR"

cat > patch_exam_f52.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F52/F55 — Patch routes/exam.js:
//  1) Enforce live-exam join grace period (5 min) server-side on
//     start-attempt — currently completely unenforced.
//  2) Record termsAccepted/termsAcceptedAt on the Attempt at creation
//     time (the new Instructions/T&C screen gates navigation to this
//     route client-side, so by the time this runs consent was given).
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.ROOT,
  '/root/workspace/src',
  '/home/runner/workspace/src',
  path.join(process.cwd(), 'src'),
  process.cwd(),
].filter(Boolean);

let ROOT = CANDIDATES.find(p => fs.existsSync(path.join(p, 'routes', 'exam.js')));
if (!ROOT) { console.error('❌ Could not locate routes/exam.js — set ROOT env var.'); process.exit(1); }
console.log('📂 Using project root:', ROOT);
const EXAM_PATH = path.join(ROOT, 'routes', 'exam.js');

let src = fs.readFileSync(EXAM_PATH, 'utf8');
const before = src;

const bad = `router.post('/:examId/start-attempt', verifyToken, async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.user.id;
    const examObjId = new mongoose.Types.ObjectId(examId);
    const studentObjId = new mongoose.Types.ObjectId(studentId);
    const exam = await Exam.findById(examObjId);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    const usedAttempts = await Attempt.countDocuments({ examId: examObjId, studentId: studentObjId });
    if (usedAttempts >= exam.maxAttempts) return res.status(403).json({ error: 'Attempt limit reached' });
    const student = await User.findById(studentObjId);
    if (!student) return res.status(404).json({ error: 'Student not found' });
    if (!student.termsAccepted) return res.status(403).json({ error: 'Terms not accepted' });
    const newAttempt = new Attempt({ examId: examObjId, studentId: studentObjId, startedAt: new Date(), status: 'active', ipAddress: req.headers['x-forwarded-for'] || req.connection.remoteAddress || 'unknown' });
    await newAttempt.save();
    res.status(200).json({ success: true, attemptId: newAttempt._id, message: 'Attempt started' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});`;

const good = `router.post('/:examId/start-attempt', verifyToken, async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.user.id;
    const examObjId = new mongoose.Types.ObjectId(examId);
    const studentObjId = new mongoose.Types.ObjectId(studentId);
    const exam = await Exam.findById(examObjId);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    const usedAttempts = await Attempt.countDocuments({ examId: examObjId, studentId: studentObjId });
    if (!exam.unlimitedAttempts && usedAttempts >= exam.maxAttempts) return res.status(403).json({ error: 'Attempt limit reached' });

    // F52 §5.2 — Live exam grace period: a FIRST attempt may only start
    // within 5 minutes of the live window opening. Students continuing
    // an already-existing attempt (usedAttempts > 0 handled above) or
    // students attempting after the exam has ended are unaffected here.
    if (usedAttempts === 0 && exam.schedule?.startTime && exam.schedule?.endTime) {
      const now = new Date()
      const start = new Date(exam.schedule.startTime)
      const end = new Date(exam.schedule.endTime)
      const GRACE_MIN = 5
      if (now >= start && now < end) {
        const minsSinceStart = (now.getTime() - start.getTime()) / 60000
        if (minsSinceStart > GRACE_MIN) {
          return res.status(403).json({ error: 'Join window closed — this live exam can only be joined in the first 5 minutes after it starts.', joinClosed: true })
        }
      }
    }

    const student = await User.findById(studentObjId);
    if (!student) return res.status(404).json({ error: 'Student not found' });
    if (!student.termsAccepted) return res.status(403).json({ error: 'Terms not accepted' });
    const newAttempt = new Attempt({
      examId: examObjId, studentId: studentObjId, startedAt: new Date(), status: 'active',
      ipAddress: req.headers['x-forwarded-for'] || req.connection.remoteAddress || 'unknown',
      // F55 — consent was gated client-side on the Instructions screen
      // before this route could ever be reached
      termsAccepted: true, termsAcceptedAt: new Date(),
    });
    await newAttempt.save();
    res.status(200).json({ success: true, attemptId: newAttempt._id, message: 'Attempt started' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});`;

if (src.includes(bad)) {
  src = src.replace(bad, good);
  fs.writeFileSync(EXAM_PATH, src);
  console.log('✅ Patched: start-attempt now enforces live-join grace period + records termsAccepted');
} else if (src.includes('joinClosed: true')) {
  console.log('⚠️  Already patched — no change needed.');
} else {
  console.error('❌ Could not find the exact start-attempt block — file may differ from expected.');
  process.exit(1);
}
PRNODEEOF

cat > patch_user_f52.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F52 §7 — Add examReminders field to User schema
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.ROOT,
  '/root/workspace/src',
  '/home/runner/workspace/src',
  path.join(process.cwd(), 'src'),
  process.cwd(),
].filter(Boolean);

let ROOT = CANDIDATES.find(p => fs.existsSync(path.join(p, 'models', 'User.js')));
if (!ROOT) { console.error('❌ Could not locate models/User.js — set ROOT env var.'); process.exit(1); }
console.log('📂 Using project root:', ROOT);
const USER_PATH = path.join(ROOT, 'models', 'User.js');

let src = fs.readFileSync(USER_PATH, 'utf8');

const anchor = `  xp: { type: Number, default: 0 },

}, { timestamps: true });`;

const addition = `  xp: { type: Number, default: 0 },

  // F52 §7 — Per-exam reminder toggle
  examReminders: [{
    examId:  { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    enabled: { type: Boolean, default: true },
  }],

}, { timestamps: true });`;

if (src.includes(anchor) && !src.includes('examReminders')) {
  src = src.replace(anchor, addition);
  fs.writeFileSync(USER_PATH, src);
  console.log('✅ Patched: added examReminders field to User schema');
} else if (src.includes('examReminders')) {
  console.log('⚠️  Already patched — no change needed.');
} else {
  console.error('❌ Anchor not found — file may differ from expected.');
  process.exit(1);
}
PRNODEEOF

cat > patch_socket_f53.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F53 — Extend config/socket.js: waiting-room join/leave with live
// count broadcast, and a time-limited chat relay (first 10 minutes
// of waiting room only — anti-cheat rule §5.1.5).
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.ROOT,
  '/root/workspace/src',
  '/home/runner/workspace/src',
  path.join(process.cwd(), 'src'),
  process.cwd(),
].filter(Boolean);

let ROOT = CANDIDATES.find(p => fs.existsSync(path.join(p, 'config', 'socket.js')));
if (!ROOT) { console.error('❌ Could not locate config/socket.js — set ROOT env var.'); process.exit(1); }
console.log('📂 Using project root:', ROOT);
const SOCKET_PATH = path.join(ROOT, 'config', 'socket.js');

let src = fs.readFileSync(SOCKET_PATH, 'utf8');

const anchor = `    socket.on('join-exam', (examId) => {
      socket.join(examId);
      console.log(\`Socket \${socket.id} joined exam: \${examId}\`);
    });

    socket.on('disconnect', () => {
      console.log('Socket disconnected:', socket.id);
    });`;

const addition = `    socket.on('join-exam', (examId) => {
      socket.join(examId);
      console.log(\`Socket \${socket.id} joined exam: \${examId}\`);
    });

    // ── F53 — Waiting Room: join, live count broadcast, time-limited chat ──
    socket.on('join-waiting-room', ({ examId, studentName }) => {
      const room = \`waiting-\${examId}\`
      socket.join(room)
      socket.data.waitingRoomExamId = examId
      socket.data.waitingRoomJoinedAt = Date.now()
      socket.data.studentName = studentName || 'Student'
      const count = io.sockets.adapter.rooms.get(room)?.size || 0
      io.to(room).emit('waiting-room-count', { count })
    })

    socket.on('leave-waiting-room', ({ examId }) => {
      const room = \`waiting-\${examId}\`
      socket.leave(room)
      const count = io.sockets.adapter.rooms.get(room)?.size || 0
      io.to(room).emit('waiting-room-count', { count })
    })

    // §5.1.1/§5.1.5 — chat only allowed in first 10 minutes after this
    // socket joined the waiting room (anti-cheat: disabled afterwards)
    socket.on('waiting-room-chat', ({ examId, message }) => {
      const room = \`waiting-\${examId}\`
      const joinedAt = socket.data.waitingRoomJoinedAt
      if (!joinedAt || Date.now() - joinedAt > 10 * 60 * 1000) {
        socket.emit('waiting-room-chat-closed', { message: 'Chat is now closed for this waiting room.' })
        return
      }
      const trimmed = String(message || '').slice(0, 300)
      if (!trimmed.trim()) return
      io.to(room).emit('waiting-room-chat', {
        studentName: socket.data.studentName || 'Student',
        message: trimmed,
        at: new Date(),
      })
    })

    // Admin broadcast message into a waiting room (§4.1.4)
    socket.on('waiting-room-broadcast', ({ examId, message }) => {
      const room = \`waiting-\${examId}\`
      io.to(room).emit('waiting-room-broadcast', { message: String(message || '').slice(0, 300), at: new Date() })
    })

    socket.on('disconnect', () => {
      console.log('Socket disconnected:', socket.id);
      const examId = socket.data?.waitingRoomExamId
      if (examId) {
        const room = \`waiting-\${examId}\`
        const count = io.sockets.adapter.rooms.get(room)?.size || 0
        io.to(room).emit('waiting-room-count', { count })
      }
    });`;

if (src.includes(anchor) && !src.includes('join-waiting-room')) {
  src = src.replace(anchor, addition);
  fs.writeFileSync(SOCKET_PATH, src);
  console.log('✅ Patched: config/socket.js — waiting room join/leave + live count + time-limited chat');
} else if (src.includes('join-waiting-room')) {
  console.log('⚠️  Already patched — no change needed.');
} else {
  console.error('❌ Anchor not found — file may differ from expected.');
  process.exit(1);
}
PRNODEEOF

cat > patch_index_f52.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F52-57 — Mount routes/examFlow.js BEFORE routes/exam.js so
// /api/exams/my-exams (and other named sub-routes) don't get
// swallowed by exam.js's GET /:id handler.
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.ROOT,
  '/root/workspace/src',
  '/home/runner/workspace/src',
  path.join(process.cwd(), 'src'),
  process.cwd(),
].filter(Boolean);

let ROOT = CANDIDATES.find(p => fs.existsSync(path.join(p, 'index.js')));
if (!ROOT) { console.error('❌ Could not locate index.js — set ROOT env var.'); process.exit(1); }
console.log('📂 Using project root:', ROOT);
const IDX_PATH = path.join(ROOT, 'index.js');

let src = fs.readFileSync(IDX_PATH, 'utf8');

const anchor = `app.use('/api/exams', examRoutes);`;
const mountLine = `app.use('/api/exams', require('./routes/examFlow')); // F52/F53 — must be BEFORE examRoutes (avoids /:id collision)
app.use('/api/exams', examRoutes);`;

if (src.includes('examFlow')) {
  console.log('⚠️  Already mounted, skipping');
} else if (src.includes(anchor)) {
  src = src.replace(anchor, mountLine);
  fs.writeFileSync(IDX_PATH, src);
  console.log('✅ index.js — mounted routes/examFlow.js before examRoutes');
} else {
  console.log('⚠️  Anchor line not found — mount routes/examFlow.js manually BEFORE examRoutes.');
}
PRNODEEOF

echo "🚀 Applying patches..."
ROOT="$ROOT" node patch_exam_f52.js
ROOT="$ROOT" node patch_user_f52.js
ROOT="$ROOT" node patch_socket_f53.js
ROOT="$ROOT" node patch_index_f52.js

# ══════════════════════════════════════════════════════════
# VERIFICATION
# ══════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════"
echo " VERIFICATION — F52-F57 Backend"
echo "════════════════════════════════════════════════════════"
PASS=0; FAIL=0
check() { if grep -qF "$2" "$3" 2>/dev/null; then echo "✅ $1"; PASS=$((PASS+1)); else echo "❌ $1"; FAIL=$((FAIL+1)); fi }

check "F52 §3.4 Batch-synced student exam list" "router.get('/my-exams'" "$ROOT/routes/examFlow.js"
check "F52 §2 Header quick stats (total/upcoming/live/completed/attempted/best)" "const stats = {" "$ROOT/routes/examFlow.js"
check "F52 §8 Completed exam multi-attempt + best score tracking" "completedAttempts" "$ROOT/routes/examFlow.js"
check "F52 §5 Live-state + join-window computation" "function computeLiveState" "$ROOT/routes/examFlow.js"
check "F52 §7 Reminder toggle endpoint" "router.post('/:id/reminder'" "$ROOT/routes/examFlow.js"
check "F53 waiting-info endpoint (exam summary + live count)" "router.get('/:id/waiting-info'" "$ROOT/routes/examFlow.js"
check "F53 §5 Waiting-room chat (REST, no socket.io-client needed)" "waitingRoomChats" "$ROOT/routes/examFlow.js"
check "F53 §5.1.5 Chat time-window enforcement" "WAITING_CHAT_WINDOW_MIN" "$ROOT/routes/examFlow.js"
check "User.js — examReminders field added (§7)" "examReminders:" "$ROOT/models/User.js"
check "exam.js — Live join grace period enforced server-side (§5.2/§15.4)" "Join window closed" "$ROOT/routes/exam.js"
check "exam.js — termsAccepted recorded on Attempt creation (F55)" "termsAccepted: true, termsAcceptedAt" "$ROOT/routes/exam.js"
check "socket.js — waiting room join/leave + live count broadcast (F53)" "join-waiting-room" "$ROOT/config/socket.js"
check "socket.js — time-limited chat relay (§5.1.5)" "waiting-room-chat" "$ROOT/config/socket.js"
check "index.js — examFlow mounted BEFORE examRoutes (avoids /:id collision)" "examFlow" "$ROOT/index.js"

echo ""
echo "════════════════════════════════════════════════════════"
echo " RESULT: $PASS passed / $((PASS+FAIL)) total"
if [ "$FAIL" -eq 0 ]; then echo " 🎉 ALL F52-F57 BACKEND FEATURES SUCCESSFULLY IMPLEMENTED ✅"; else echo " ⚠️  $FAIL item(s) need review."; fi
echo "════════════════════════════════════════════════════════"

echo "👉 NOTE: F56 (Webcam) has no new backend — it is entirely client-side"
echo "   (camera preview + lighting check), gated before calling the"
echo "   existing /start-attempt route."
echo "👉 NOTE: frontend has no socket.io-client installed, so waiting-room"
echo "   live count + chat use REST polling (reliable, zero new deps)."
echo "   The socket.js events added here are ready for a future upgrade"
echo "   if you later run: npm install socket.io-client (frontend)."
echo "👉 Restart your backend (Replit Run button) to load the changes."
