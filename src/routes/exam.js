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
    const { category, status } = req.query;
    const filter = {};
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
