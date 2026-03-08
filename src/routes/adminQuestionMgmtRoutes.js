const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

// ─── Step 1: Question Bank CRUD + Search + Filter ───────────────────────────
router.get('/questions', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const { subject, chapter, difficulty, search, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (subject) filter.subject = subject;
    if (chapter) filter.chapter = { $regex: chapter, $options: 'i' };
    if (difficulty) filter.difficulty = difficulty;
    if (search) filter.$or = [
      { questionText: { $regex: search, $options: 'i' } },
      { chapter: { $regex: search, $options: 'i' } }
    ];
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const questions = await Question.find(filter)
      .sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total = await Question.countDocuments(filter);
    res.json({ success: true, total, page: parseInt(page), totalPages: Math.ceil(total / parseInt(limit)), questions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/questions/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const q = await Question.findById(req.params.id);
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, question: q });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/questions', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const q = await Question.create({ ...req.body, createdBy: req.user.id });
    res.status(201).json({ success: true, message: 'Question created', question: q });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/questions/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const QuestionVersion = mongoose.model('QuestionVersion');
    const existing = await Question.findById(req.params.id);
    if (!existing) return res.status(404).json({ success: false, message: 'Question not found' });
    // Save version before update (S87)
    await QuestionVersion.create({
      questionId: existing._id,
      versionData: existing.toObject(),
      editedBy: req.user.id
    });
    const updated = await Question.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ success: true, message: 'Question updated', question: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/questions/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const q = await Question.findByIdAndDelete(req.params.id);
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Question deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 2: Question Preview Before Publish (S17) ──────────────────────────
router.get('/questions/:id/preview', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const q = await Question.findById(req.params.id)
      .select('questionText options subject chapter difficulty imageUrl explanation');
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({
      success: true,
      preview: {
        questionText: q.questionText,
        options: q.options,
        subject: q.subject,
        chapter: q.chapter,
        difficulty: q.difficulty,
        imageUrl: q.imageUrl || null,
        explanation: q.explanation || null,
        previewMode: true
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 3: Question Version History (S87) ──────────────────────────────────
router.get('/questions/:id/versions', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const QuestionVersion = mongoose.model('QuestionVersion');
    const versions = await QuestionVersion.find({ questionId: new mongoose.Types.ObjectId(req.params.id) })
      .populate('editedBy', 'name email')
      .sort({ createdAt: -1 });
    res.json({ success: true, total: versions.length, versions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/questions/:id/rollback/:versionId', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const QuestionVersion = mongoose.model('QuestionVersion');
    const version = await QuestionVersion.findById(req.params.versionId);
    if (!version) return res.status(404).json({ success: false, message: 'Version not found' });
    const { _id, __v, ...versionData } = version.versionData;
    await Question.findByIdAndUpdate(req.params.id, versionData);
    res.json({ success: true, message: 'Question rolled back to selected version' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 4: Duplicate Question Detector (S18) ───────────────────────────────
router.post('/questions/check-duplicate', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const { questionText } = req.body;
    if (!questionText) return res.status(400).json({ success: false, message: 'questionText required' });
    const exact = await Question.findOne({ questionText: questionText.trim() });
    if (exact) {
      return res.json({ success: true, isDuplicate: true, message: 'Exact duplicate found!', existingQuestion: exact });
    }
    // Similar check (first 50 chars)
    const prefix = questionText.trim().substring(0, 50);
    const similar = await Question.find({ questionText: { $regex: prefix, $options: 'i' } }).limit(3);
    res.json({
      success: true,
      isDuplicate: false,
      hasSimilar: similar.length > 0,
      similarCount: similar.length,
      similarQuestions: similar
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 5: Question Error Reporting Management (S84) ───────────────────────
router.get('/question-errors', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const QuestionError = mongoose.model('QuestionError');
    const { status, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (status) filter.status = status;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const errors = await QuestionError.find(filter)
      .populate('questionId', 'questionText subject')
      .populate('reportedBy', 'name email')
      .sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total = await QuestionError.countDocuments(filter);
    res.json({ success: true, total, errors });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/question-errors/:id/resolve', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const QuestionError = mongoose.model('QuestionError');
    const { status, adminNote } = req.body;
    const error = await QuestionError.findByIdAndUpdate(
      req.params.id,
      { status: status || 'resolved', adminNote, resolvedAt: new Date(), resolvedBy: req.user.id },
      { new: true }
    );
    if (!error) return res.status(404).json({ success: false, message: 'Error report not found' });
    res.json({ success: true, message: 'Error report resolved', error });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 6: Smart Question Paper Generator (S101) ───────────────────────────
router.post('/generate-paper', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const {
      totalQuestions = 180,
      physics = 45, chemistry = 45, biology = 90,
      difficulty = 'mixed', examTitle
    } = req.body;

    const getQuestions = async (subject, count, diff) => {
      const filter = { subject };
      if (diff && diff !== 'mixed') filter.difficulty = diff;
      return await Question.aggregate([
        { $match: filter },
        { $sample: { size: count } }
      ]);
    };

    const [physicsQs, chemistryQs, biologyQs] = await Promise.all([
      getQuestions('Physics', physics, difficulty),
      getQuestions('Chemistry', chemistry, difficulty),
      getQuestions('Biology', biology, difficulty)
    ]);

    const allQuestions = [...physicsQs, ...chemistryQs, ...biologyQs];

    res.json({
      success: true,
      examTitle: examTitle || 'Auto Generated NEET Paper',
      totalGenerated: allQuestions.length,
      breakdown: {
        physics: physicsQs.length,
        chemistry: chemistryQs.length,
        biology: biologyQs.length
      },
      questions: allQuestions,
      note: allQuestions.length < totalQuestions ? `Only ${allQuestions.length} questions available in DB` : 'Paper ready'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 7: PYQ Bank Management (S104) ──────────────────────────────────────
router.get('/pyq', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const { year, subject, page = 1, limit = 20 } = req.query;
    const filter = { isPYQ: true };
    if (year) filter.pyqYear = parseInt(year);
    if (subject) filter.subject = subject;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const questions = await Question.find(filter)
      .sort({ pyqYear: -1 }).skip(skip).limit(parseInt(limit));
    const total = await Question.countDocuments(filter);
    const years = await Question.distinct('pyqYear', { isPYQ: true });
    res.json({ success: true, total, availableYears: years.sort((a,b) => b-a), questions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/questions/:id/mark-pyq', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const { year, source } = req.body;
    const q = await Question.findByIdAndUpdate(
      req.params.id,
      { isPYQ: true, pyqYear: year, pyqSource: source || 'NEET' },
      { new: true }
    );
    if (!q) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: `Marked as PYQ ${year}`, question: q });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 8: Chapter/Topic Mini Tests (S103) ─────────────────────────────────
router.post('/mini-test/generate', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Question = mongoose.model('Question');
    const { subject, chapter, count = 20, difficulty } = req.body;
    if (!subject || !chapter) return res.status(400).json({ success: false, message: 'subject and chapter required' });
    const filter = { subject, chapter: { $regex: chapter, $options: 'i' } };
    if (difficulty) filter.difficulty = difficulty;
    const questions = await Question.aggregate([
      { $match: filter },
      { $sample: { size: parseInt(count) } }
    ]);
    res.json({
      success: true,
      miniTest: {
        title: `${subject} - ${chapter} Mini Test`,
        subject, chapter,
        totalQuestions: questions.length,
        duration: Math.ceil(questions.length * 1.5) + ' minutes',
        questions
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 9: Doubt/Query System Management (S63) ─────────────────────────────
router.get('/doubts', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Doubt = mongoose.model('Doubt');
    const { status, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (status) filter.status = status;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const doubts = await Doubt.find(filter)
      .populate('studentId', 'name email')
      .populate('questionId', 'questionText subject')
      .sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total = await Doubt.countDocuments(filter);
    res.json({ success: true, total, doubts });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/doubts/:id/reply', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Doubt = mongoose.model('Doubt');
    const { reply } = req.body;
    if (!reply) return res.status(400).json({ success: false, message: 'reply required' });
    const doubt = await Doubt.findByIdAndUpdate(
      req.params.id,
      { adminReply: reply, status: 'resolved', repliedAt: new Date(), repliedBy: req.user.id },
      { new: true }
    );
    if (!doubt) return res.status(404).json({ success: false, message: 'Doubt not found' });
    res.json({ success: true, message: 'Reply sent', doubt });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 10: Bulk Exam Creator (N8) ─────────────────────────────────────────
router.post('/exams/bulk-create', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Exam = mongoose.model('Exam');
    const { exams } = req.body;
    if (!exams || !Array.isArray(exams) || exams.length === 0) {
      return res.status(400).json({ success: false, message: 'exams array required' });
    }
    const created = [];
    const failed = [];
    for (const examData of exams) {
      try {
        const exam = await Exam.create({ ...examData, createdBy: req.user.id });
        created.push({ id: exam._id, title: exam.title });
      } catch (e) {
        failed.push({ title: examData.title, error: e.message });
      }
    }
    res.json({
      success: true,
      message: `${created.length} exams created`,
      totalRequested: exams.length,
      created,
      failed
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 11: Batch vs Batch Comparison (M8) ─────────────────────────────────
router.get('/batches/compare', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('../models/User');
    const Result = mongoose.model('Result');
    const { batch1, batch2, examId } = req.query;
    if (!batch1 || !batch2) return res.status(400).json({ success: false, message: 'batch1 and batch2 required' });

    const getStats = async (batchName) => {
      const students = await User.find({ role: 'student', batch: batchName }).select('_id');
      const ids = students.map(s => s._id);
      const filter = { studentId: { $in: ids } };
      if (examId) filter.examId = new mongoose.Types.ObjectId(examId);
      const results = await Result.find(filter);
      const scores = results.map(r => r.score || 0);
      return {
        batch: batchName,
        studentCount: students.length,
        attemptCount: results.length,
        avgScore: scores.length ? (scores.reduce((a,b)=>a+b,0)/scores.length).toFixed(2) : 0,
        highestScore: scores.length ? Math.max(...scores) : 0,
        lowestScore: scores.length ? Math.min(...scores) : 0
      };
    };

    const [stats1, stats2] = await Promise.all([getStats(batch1), getStats(batch2)]);
    res.json({ success: true, comparison: { batch1: stats1, batch2: stats2 } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 12: Batch Transfer System (M3) ─────────────────────────────────────
router.post('/batches/transfer', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('../models/User');
    const { studentIds, fromBatch, toBatch } = req.body;
    if (!toBatch) return res.status(400).json({ success: false, message: 'toBatch required' });

    let filter = { role: 'student' };
    if (studentIds && studentIds.length > 0) {
      filter._id = { $in: studentIds.map(id => new mongoose.Types.ObjectId(id)) };
    } else if (fromBatch) {
      filter.batch = fromBatch;
    } else {
      return res.status(400).json({ success: false, message: 'studentIds or fromBatch required' });
    }

    const result = await User.updateMany(filter, { $set: { batch: toBatch } });
    res.json({
      success: true,
      message: `${result.modifiedCount} students transferred to ${toBatch}`,
      modifiedCount: result.modifiedCount
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
