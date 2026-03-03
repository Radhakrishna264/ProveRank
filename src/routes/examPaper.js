// ============================================
// Phase 3.1 Routes:
// Step 5: Snapshot Lock
// Step 6: S58 Randomized Paper per Student
// Step 7: S36 Question Import from other Exam
// ============================================

const express  = require('express');
const router   = express.Router();
const Exam     = require('../models/Exam');
const Question = require('../models/Question');
const { verifyToken, isAdmin }   = require('../middleware/auth');
const {
  generateNEETPaper,
  lockQuestionSnapshot,
  randomizeForStudent,
  NEET_DISTRIBUTION,
  DEFAULT_DIFFICULTY_WEIGHTS
} = require('../utils/randomSelector');


// ─────────────────────────────────────────────
// POST /api/exam-paper/:id/generate
// Admin: Random questions select karo + Snapshot lock karo
// Step 4 + Step 5
// ─────────────────────────────────────────────
router.post('/:id/generate', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });

    if (exam.snapshotLocked) {
      return res.status(400).json({
        message: 'Paper already locked hai. Unlock karne ke liye /unlock endpoint use karo.'
      });
    }

    // Custom distribution ya NEET default
    const customDistribution  = req.body.distribution    || null;
    const difficultyWeights   = req.body.difficultyWeights || null;

    const result = await generateNEETPaper(customDistribution, difficultyWeights);

    if (!result.success) {
      return res.status(400).json({ message: result.error });
    }

    // Step 5: Snapshot lock karo
    const snapshot = await lockQuestionSnapshot(req.params.id, result.questions);

    res.json({
      message     : `✅ Paper generate + lock ho gaya! ${snapshot.length} questions locked.`,
      totalQuestions : snapshot.length,
      distribution: {
        Physics  : snapshot.filter(q => q.subject === 'Physics').length,
        Chemistry: snapshot.filter(q => q.subject === 'Chemistry').length,
        Biology  : snapshot.filter(q => q.subject === 'Biology').length
      },
      lockedAt    : new Date()
    });

  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


// ─────────────────────────────────────────────
// GET /api/exam-paper/:id/paper/:studentId
// Step 6: S58 — Student ke liye randomized order
// ─────────────────────────────────────────────
router.get('/:id/paper/:studentId', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });

    if (!exam.snapshotLocked || !exam.questionSnapshot || exam.questionSnapshot.length === 0) {
      return res.status(400).json({
        message: 'Paper abhi generate nahi hua. Admin se generate karwao pehle.'
      });
    }

    // Student ke liye randomized order
    const randomized = randomizeForStudent(
      exam.questionSnapshot,
      req.params.studentId,
      req.params.id
    );

    // Correct answer hide karo (security)
    const safeQuestions = randomized.map(q => ({
      questionId  : q.questionId,
      displayOrder: q.displayOrder,
      text        : q.text,
      hindiText   : q.hindiText,
      options     : q.options,
      subject     : q.subject,
      chapter     : q.chapter,
      difficulty  : q.difficulty,
      type        : q.type,
      image       : q.image
      // correct field NAHI bheja — security
    }));

    res.json({
      examId        : exam._id,
      examTitle     : exam.title,
      totalQuestions: safeQuestions.length,
      duration      : exam.duration,
      questions     : safeQuestions
    });

  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


// ─────────────────────────────────────────────
// DELETE /api/exam-paper/:id/unlock
// Admin: Snapshot unlock karo (paper regenerate ke liye)
// ─────────────────────────────────────────────
router.delete('/:id/unlock', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });

    await Exam.findByIdAndUpdate(req.params.id, {
      questionSnapshot : [],
      snapshotLocked   : false,
      snapshotLockedAt : null
    });

    res.json({ message: '🔓 Snapshot unlock ho gaya. Ab dobara /generate kar sakte ho.' });

  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


// ─────────────────────────────────────────────
// GET /api/exam-paper/:id/snapshot
// Admin: Locked snapshot dekho (with correct answers)
// ─────────────────────────────────────────────
router.get('/:id/snapshot', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });

    if (!exam.snapshotLocked) {
      return res.status(400).json({ message: 'Paper abhi lock nahi hua' });
    }

    res.json({
      locked   : exam.snapshotLocked,
      lockedAt : exam.snapshotLockedAt,
      total    : exam.questionSnapshot.length,
      snapshot : exam.questionSnapshot
    });

  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


// ─────────────────────────────────────────────
// POST /api/exam-paper/:examId/import-questions
// Step 7: S36 — Doosre exam se questions import karo
// ─────────────────────────────────────────────
router.post('/:examId/import-questions', verifyToken, isAdmin, async (req, res) => {
  try {
    const { sourceExamId } = req.body;

    if (!sourceExamId) {
      return res.status(400).json({ message: 'sourceExamId required hai body mein' });
    }

    const [targetExam, sourceExam] = await Promise.all([
      Exam.findById(req.params.examId),
      Exam.findById(sourceExamId)
    ]);

    if (!targetExam) return res.status(404).json({ message: 'Target exam nahi mila' });
    if (!sourceExam) return res.status(404).json({ message: 'Source exam nahi mila' });

    if (!sourceExam.snapshotLocked || !sourceExam.questionSnapshot?.length) {
      return res.status(400).json({
        message: 'Source exam mein locked snapshot nahi hai. Pehle source exam ka paper generate karo.'
      });
    }

    if (targetExam.snapshotLocked) {
      return res.status(400).json({
        message: 'Target exam already locked hai. Pehle unlock karo.'
      });
    }

    // Source exam ke questions copy karo (fresh snapshot as new)
    const copiedSnapshot = sourceExam.questionSnapshot.map((q, idx) => ({
      ...q,
      order: idx + 1
    }));

    await Exam.findByIdAndUpdate(req.params.examId, {
      questionSnapshot : copiedSnapshot,
      snapshotLocked   : true,
      snapshotLockedAt : new Date()
    });

    res.json({
      message         : `✅ ${copiedSnapshot.length} questions import ho gaye "${sourceExam.title}" se!`,
      totalImported   : copiedSnapshot.length,
      sourceExam      : sourceExam.title,
      targetExam      : targetExam.title
    });

  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


module.exports = router;
