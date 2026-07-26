#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F52-F57 v2 — Exam Flow — BACKEND fix script (COMPLETE)"
echo " Fixes all gaps found in v1 verification + new Rule 1.15.x"
echo "════════════════════════════════════════════════════════"

BACKEND="${BACKEND:-}"
for candidate in "/root/workspace" "/home/runner/workspace" "$(pwd)"; do
  if [ -d "$candidate/routes" ] && [ -d "$candidate/models" ]; then BACKEND="$candidate"; break; fi
done
if [ -z "$BACKEND" ]; then echo "❌ Could not find backend root (needs /routes + /models). Set BACKEND env var and re-run."; exit 1; fi
cd "$BACKEND"
echo "📂 Backend root: $BACKEND"
mkdir -p models routes config

ts=$(date +%s)

# ══════════════════════════════════════════════════════════
# STEP 1 — models/User.js (full rewrite)
# Adds: waitingRoomJoins (Rule 1.15.3/1.15.4 resume tracking)
#       examConsents (F55 §1.5/§2.5/§3.1 per-exam T&C DB log)
#       examReminders (F52 §7 server-persisted reminder toggle)
# ══════════════════════════════════════════════════════════
[ -f models/User.js ] && cp models/User.js "models/User.js.bak_$ts"
cat > models/User.js << 'USER_EOF'
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  password: { type: String, required: true },
  studentId: { type: String, unique: true, sparse: true, trim: true },
  adminId: { type: String, unique: true, sparse: true, trim: true },

  // ── F38/F39: Extended Profile Fields ──────────────────────────
  state:              { type: String, default: '' },
  gender:             { type: String, default: '' },
  timezone:           { type: String, default: 'Asia/Kolkata' },
  targetYear:         { type: String, default: '' },
  yearOfAppearing:    { type: String, default: '' },
  coachingInstitute:  { type: String, default: '' },
  dob:                { type: String, default: '' },
  city:               { type: String, default: '' },
  bio:                { type: String, default: '', maxlength: 160 },
  avatar:             { type: String, default: '' },
  targetExam:         { type: String, default: '' },
  board:              { type: String, default: '' },
  school:             { type: String, default: '' },
  medium:             { type: String, default: '' },
  batch:              { type: String, default: '' },

  // ── F38: 2FA (TOTP) ────────────────────────────────────────────
  twoFactorEnabled:     { type: Boolean, default: false },
  twoFactorSecret:      { type: String, default: null },
  twoFactorTempSecret:  { type: String, default: null },

  // ── F38: Login health / device tracking ─────────────────────────
  failedLoginAttempts: { type: Number, default: 0 },
  lastFailedLoginAt:   { type: Date, default: null },
  loginCount:          { type: Number, default: 0 },
  trustedDevices: [{
    deviceId:   String,
    label:      String,
    browser:    String,
    os:         String,
    addedAt:    { type: Date, default: Date.now },
    lastUsedAt: Date,
  }],

  // ── F38B §7 — Profile photo version history (Superadmin only view) ──
  avatarHistory: [{
    url:       String,
    updatedAt: { type: Date, default: Date.now },
    updatedBy: { type: String, default: 'self' },
    source:    { type: String, default: 'profile_page' },
  }],

  // ── F38B §5 — Password change metadata (never the password itself) ──
  passwordChangedAt:   { type: Date, default: null },
  passwordChangeCount: { type: Number, default: 0 },
  passwordResetHistory: [{
    requestedAt: { type: Date, default: Date.now },
    resetBy:     { type: String, default: 'self' },
    method:      { type: String, default: 'otp' },
  }],

  // Profile history (F38 §9 — per-field internal audit trail, DB only, never shown to student)
  profileHistory: [{
    updatedAt:        { type: Date, default: Date.now },
    updatedFields:    [String],
    changes: [{
      field:    String,
      oldValue: mongoose.Schema.Types.Mixed,
      newValue: mongoose.Schema.Types.Mixed,
    }],
    updatedBy: { type: String, default: 'self' },
    source:    { type: String, default: 'profile_page' },
    snapshot: {
      name: String, phone: String, dob: String, city: String,
      state: String, gender: String, bio: String,
      targetExam: String, targetYear: String, board: String,
      school: String, coachingInstitute: String,
    }
  }],

  // Preferences
  preferences: {
    emailNotif:    { type: Boolean, default: true },
    smsNotif:      { type: Boolean, default: false },
    studyReminder: { type: Boolean, default: true },
  },

  welcomeSeen: { type: Boolean, default: false },
  role: {
    type: String,
    enum: ['superadmin', 'admin', 'student'],
    default: 'student'
  },
  termsAccepted: { type: Boolean, default: false },
  permissions: { type: Map, of: Boolean, default: {} },
  adminFrozen: { type: Boolean, default: false },
  group: { type: String },
  otp: { type: String },
  otpExpiry: { type: Date },
  verified: { type: Boolean, default: false },
  profilePhoto: { type: String },
  emailVerified: { type: Boolean, default: false },

  // OTP fields — register verify, login OTP, reset password
  emailVerifyOTP:      { type: String, default: null },
  emailVerifyOTPExpiry:{ type: Date,   default: null },
  loginOTP:            { type: String, default: null },
  loginOTPExpiry:      { type: Date,   default: null },
  resetOTP:            { type: String, default: null },
  resetOTPExpiry:      { type: Date,   default: null },
  emailVerifyToken: { type: String },
  emailVerifyExpiry: { type: Date },
  loginHistory: [{
    ip: String,
    device: String,
    time: { type: Date, default: Date.now }
  }],
  customFields: { type: Object },
  banned: { type: Boolean, default: false },
  frozen: { type: Boolean, default: false },
  archived: { type: Boolean, default: false },
  banReason: { type: String },
  banExpiry: { type: Date },
  parentEmail: { type: String },

  // ── F35: Multi-device session control + Terms tracking ─────────
  activeSessionToken: { type: String, default: null },
  termsAcceptedAt:    { type: Date,    default: null },
  termsVersion:        { type: String, default: null },

  // F37 — Checklist + XP
  checklist: {
    pyqExplored:      { type: Boolean, default: false },
    analyticsVisited: { type: Boolean, default: false },
  },
  xp: { type: Number, default: 0 },

  // ══════════════════════════════════════════════════════════
  // F52-F57 v2 — Waiting Room resume tracking (Rule 1.15.3/1.15.4)
  // NOTE: read/write via User.collection.findOne/updateOne (raw driver)
  // to match project convention (see D-36/D-37 in Brief) — same
  // pattern already used for enrolledBatches/enrolledBatchesMeta.
  // ══════════════════════════════════════════════════════════
  waitingRoomJoins: [{
    examId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    joinedAt: { type: Date, default: Date.now }
  }],

  // F52-F57 v2 — Per-exam T&C consent log (F55 §1.5/§2.5/§3.1)
  examConsents: [{
    examId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    version:    { type: String, default: '1.0' },
    acceptedAt: { type: Date, default: Date.now }
  }],

  // F52 §7 — Per-exam reminder toggle (server-persisted)
  examReminders: [{
    examId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    enabled:   { type: Boolean, default: true },
    updatedAt: { type: Date, default: Date.now }
  }],

}, { timestamps: true });

// password hashing removed — done in auth.js directly;

if (mongoose.models.User) delete mongoose.connection.models['User'];
module.exports = mongoose.model('User', userSchema, 'students');
USER_EOF
echo "✅ models/User.js rewritten (waitingRoomJoins + examConsents + examReminders added)"

# ══════════════════════════════════════════════════════════
# STEP 2 — models/Exam.js (full rewrite)
# Adds: waitingChatMinutes, waitingAutoCloseBufferMinutes
# Changes: waitingRoomMinutes default 10 -> 20 (Rule 1.15.1)
# ══════════════════════════════════════════════════════════
[ -f models/Exam.js ] && cp models/Exam.js "models/Exam.js.bak_$ts"
cat > models/Exam.js << 'EXAM_EOF'
const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  title:        { type: String, required: true, trim: true },
  subject:      { type: String, default: 'NEET' },
  duration:     { type: Number, required: true },
  totalMarks:   { type: Number, default: 720 },
  questions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }], // QsBank Integration

  sections: [{
    name:          String,
    subject:       String,
    questionCount: Number,
    timeLimit:     Number,
    marks:         Number,
    fromQNo:       Number,
    toQNo:         Number
  }],

  markingScheme: {
    correct:     { type: Number, default: 4 },
    incorrect:   { type: Number, default: -1 },
    unattempted: { type: Number, default: 0 },
    msqMode:     { type: String, enum: ['ALL_OR_NOTHING', 'PARTIAL_NEGATIVE'], default: 'ALL_OR_NOTHING' }
  },

  password:   { type: String, default: '' },

  schedule: {
    startTime:  Date,
    endTime:    Date,
    resultTime: Date
  },

  audioMonitoringEnabled: { type: Boolean, default: false },
  status: { type: String, enum: ['draft', 'scheduled', 'live', 'ended'], default: 'draft' },

  batch:    { type: String, default: '' },
  multiBatch: [{ type: String, default: [] }],

  assignmentType: { type: String, enum: ['batch', 'series', 'mini_test', 'individual'], default: 'individual' },
  seriesName: { type: String, default: '' },
  testSeriesId: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries', default: null },

  category: { type: String, enum: ['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test', 'Mini Test'], default: 'Full Mock' },

  whitelist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  watermark:          { type: Boolean, default: true },
  customInstructions: { type: String, default: '' },

  reviewWindow: {
    enabled:         { type: Boolean, default: false },
    durationMinutes: { type: Number, default: 0 },
  fullscreenForce: { type: Boolean, default: false },
  fullscreenWarnings: { type: Number, default: 0 }
  },

  template:   { type: String, default: '' },
  difficulty: { type: String, default: 'Mixed' },
  type:       { type: String, default: 'NEET' },

  waitingRoomEnabled: { type: Boolean, default: false },
  // Rule 1.15.1 — default waiting-room window is 20 min before exam start (admin-configurable per exam)
  waitingRoomMinutes: { type: Number, default: 20 },
  // Rule 1.15.6 — admin-configurable chat duration inside waiting room (minutes from join)
  waitingChatMinutes: { type: Number, default: 10 },
  // Rule 1.15.5/1.15.6 — admin-configurable auto-close buffer: waiting room force-closes
  // to Instructions screen this many minutes before exam start
  waitingAutoCloseBufferMinutes: { type: Number, default: 8 },

  maxAttempts:    { type: Number, default: 1 },
  reattemptCount: { type: String, enum: ['best', 'last'], default: 'last' },
  unlimitedAttempts: { type: Boolean, default: false },
  questionSnapshot:  { type: Array, default: [] },
  snapshotLocked:    { type: Boolean, default: false },
  snapshotLockedAt:  { type: Date, default: null },

  whitelistEnabled:    { type: Boolean, default: false },
  whitelistedStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  whitelistedGroups:   [{ type: String }],

  subjectWiseCount: [{ subject: String, count: Number }],
  totalQuestionsRequested: { type: Number, default: 0 },

  scheduledPublish: {
    enabled:   { type: Boolean, default: false },
    publishAt: { type: Date, default: null }
  },
  notifyStudents: { type: Boolean, default: false },
  isTemplate: { type: Boolean, default: false },

  sourceMeta: {
    sourceType:     { type: String, enum: ['paste', 'excel', 'pdf', 'manual', ''], default: '' },
    fileName:        { type: String, default: '' },
    uploadedAt:      { type: Date, default: null },
    pageCount:       { type: Number, default: 0 },
    totalParsed:     { type: Number, default: 0 },
    totalErrors:     { type: Number, default: 0 },
    totalDuplicates: { type: Number, default: 0 }
  },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  isPinned: { type: Boolean, default: false },
  clonedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', default: null },

  isArchived:  { type: Boolean, default: false },
  archivedAt:  { type: Date, default: null },
  archivedBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }

}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);
EXAM_EOF
echo "✅ models/Exam.js rewritten (waitingChatMinutes + waitingAutoCloseBufferMinutes added, waitingRoomMinutes default now 20)"

# ══════════════════════════════════════════════════════════
# STEP 3 — config/socket.js (full rewrite)
# Adds: waiting-room room join/leave + live presence count + chat relay
# ══════════════════════════════════════════════════════════
[ -f config/socket.js ] && cp config/socket.js "config/socket.js.bak_$ts"
cat > config/socket.js << 'SOCK_EOF'
const socketIO = require('socket.io');

let io;

const initSocket = (server) => {
  io = socketIO(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    }
  });

  io.on('connection', (socket) => {
    console.log('Socket connected:', socket.id);

    socket.on('join-exam', (examId) => {
      socket.join(examId);
      console.log(`Socket ${socket.id} joined exam: ${examId}`);
    });

    // F52-F57 v2 — Waiting Room live presence (F53 §2.1.6 live count, Rule 1.15.3 re-entry)
    socket.on('join-waiting-room', (examId) => {
      if (!examId) return;
      socket.join(`waiting-${examId}`);
      socket.data.waitingExamId = examId;
      const room = io.sockets.adapter.rooms.get(`waiting-${examId}`);
      const count = room ? room.size : 0;
      io.to(`waiting-${examId}`).emit('waiting-room-count', { examId, count });
    });

    socket.on('leave-waiting-room', (examId) => {
      if (!examId) return;
      socket.leave(`waiting-${examId}`);
      const room = io.sockets.adapter.rooms.get(`waiting-${examId}`);
      const count = room ? room.size : 0;
      io.to(`waiting-${examId}`).emit('waiting-room-count', { examId, count });
    });

    // F53 §5 — Waiting room chat relay (server also validates window via REST route)
    socket.on('waiting-room-chat', (payload) => {
      if (!payload || !payload.examId) return;
      io.to(`waiting-${payload.examId}`).emit('waiting-chat-message', payload.message);
    });

    socket.on('disconnect', () => {
      const examId = socket.data && socket.data.waitingExamId;
      if (examId) {
        const room = io.sockets.adapter.rooms.get(`waiting-${examId}`);
        const count = room ? room.size : 0;
        io.to(`waiting-${examId}`).emit('waiting-room-count', { examId, count });
      }
      console.log('Socket disconnected:', socket.id);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) throw new Error('Socket not initialized');
  return io;
};

module.exports = { initSocket, getIO };
SOCK_EOF
echo "✅ config/socket.js rewritten (waiting-room presence + chat relay added)"

# ══════════════════════════════════════════════════════════
# STEP 4 — routes/exam.js (full rewrite)
# Adds: live-join-closed defense-in-depth block (Rule 1.15.9)
#       termsAccepted/termsAcceptedAt/attemptNumber set on new Attempt
#       module.exports moved to true end of file (was mid-file before)
# ══════════════════════════════════════════════════════════
[ -f routes/exam.js ] && cp routes/exam.js "routes/exam.js.bak_$ts"
cat > routes/exam.js << 'EXAMROUTE_EOF'
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
    res.json({ exam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
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
EXAMROUTE_EOF
echo "✅ routes/exam.js rewritten (live-join-closed guard + termsAccepted-on-Attempt fix + module.exports moved to end)"

# ══════════════════════════════════════════════════════════
# STEP 5 — routes/examFlow.js (new, comprehensive)
# Implements F52 (My Exams) + F53 (Waiting Room) + F55 (T&C DB
# persistence) backend, fixing the Batch/TestSeries enrollment
# bug + all Rule 1.15.x waiting-room rules.
# ══════════════════════════════════════════════════════════
[ -f routes/examFlow.js ] && cp routes/examFlow.js "routes/examFlow.js.bak_$ts"
cat > routes/examFlow.js << 'FLOW_EOF'
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
  return true; // no restriction configured -> open to all (mini_test/individual w/o whitelist)
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

module.exports = router;
FLOW_EOF
echo "✅ routes/examFlow.js created (my-exams fixed batch/testseries bug + waiting-room + T&C DB persistence + reminders)"

# ══════════════════════════════════════════════════════════
# STEP 6 — index.js mount check (manual — per Brief rule F3,
# examFlow route MUST mount BEFORE examRoutes to avoid /:id
# catch-all conflicts eating /my-exams etc.)
# ══════════════════════════════════════════════════════════
IDXFILE=""
for f in index.js src/index.js server.js; do
  [ -f "$f" ] && IDXFILE="$f" && break
done

if [ -n "$IDXFILE" ]; then
  if grep -qF "examFlow" "$IDXFILE"; then
    echo "ℹ️  '$IDXFILE' already references examFlow — verify manually that it is mounted"
    echo "    at app.use('/api/exams', require('./routes/examFlow')) BEFORE examRoutes."
  else
    echo "⚠️  MANUAL STEP REQUIRED — '$IDXFILE' me ye line add karo (examRoutes ke mount se PEHLE):"
    echo "    app.use('/api/exams', require('./routes/examFlow'));"
    echo "    (Phir uske baad: app.use('/api/exams', require('./routes/exam')); — dono same prefix pe rahenge,"
    echo "     Express match order se defined-path routes (examFlow) generic /:id routes (exam.js) se pehle try honge.)"
  fi
else
  echo "⚠️  index.js/server.js auto-detect nahi ho paya — manually mount karna:"
  echo "    app.use('/api/exams', require('./routes/examFlow'));   // BEFORE"
  echo "    app.use('/api/exams', require('./routes/exam'));"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo " 🎉 Backend v2 patch complete"
echo "════════════════════════════════════════════════════════"
echo "Fixed in this v2:"
echo "  ✅ Batch/TestSeries enrollment now read from User.enrolledBatches (was broken: Batch.students never populated)"
echo "  ✅ TestSeries enrollment now included (was completely ignored)"
echo "  ✅ F55 T&C acceptance now persisted to DB with version tracking (was sessionStorage-only)"
echo "  ✅ Rule 1.15.1 — waitingRoomMinutes now admin-configurable per exam (was hardcoded 20)"
echo "  ✅ Rule 1.15.3/1.15.4 — waitingRoomJoins tracked -> Resume Waiting Room now possible"
echo "  ✅ Rule 1.15.6 — waitingChatMinutes + waitingAutoCloseBufferMinutes now configurable"
echo "  ✅ Rule 1.15.7 — join-waiting-room only via explicit POST, never automatic"
echo "  ✅ Rule 1.15.9 — live-join-closed now blocked server-side; ended-exam attempts skip waiting room"
echo "  ✅ Rule 1.15.10 — join-waiting-room blocked once an attempt is already active"
echo "  ✅ F52 §10.6 — avgScore + rankTrend added to performance summary"
echo "  ✅ F52 §10.8.4 — nextAvailableAttemptTime added"
echo "  ✅ F52 §7 — reminder toggle now server-persisted"
echo "  ✅ Attempt.termsAccepted/termsAcceptedAt/attemptNumber now actually set on creation"
echo ""
echo "Test with:"
echo "  curl -s -X GET \"http://localhost:3000/api/exams/my-exams\" -H \"Authorization: Bearer \$TOKEN\" | head -c 500"
