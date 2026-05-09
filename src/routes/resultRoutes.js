const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Attempt = require('../models/Attempt');
const { calculateResult } = require('../services/resultService');
const { calculateRankAndPercentile, broadcastLiveRank } = require('../services/rankService');
const { checkDifficultyFlag } = require('../services/difficultyService');
const { generateOMRData } = require('../services/ormService');
const { generateShareCard } = require('../services/shareCardService');
const { generateReceiptPDF } = require('../services/receiptService');
const { verifyToken } = require('../middleware/auth');

// POST /api/results/:attemptId/calculate
router.post('/:attemptId/calculate', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await calculateResult(attemptId);
    const { rank, percentile, totalStudents } = await calculateRankAndPercentile(attemptId);
    await broadcastLiveRank(
      attempt.examId, attempt.studentId,
      rank, attempt.score, percentile
    );
    const diffResult = await checkDifficultyFlag(attempt.examId);
    await generateOMRData(attemptId);
    await generateShareCard(attemptId);

    // S109_RESULT_HOOK — Result Email Auto-trigger (CORRECT position)
    try {
      const EmailTemplate = require('../models/EmailTemplate')
      const { sendCustomEmail } = require('../utils/emailService')
      const tmpl = await EmailTemplate.findOne({ type: 'result', active: true })
      if (tmpl) {
        const User = require('../models/User')
        const { ObjectId } = require('mongodb')
        const sid = attempt.studentId || attempt.userId
        const student = await User.collection.findOne({
          _id: typeof sid === 'string' ? new ObjectId(sid) : sid
        })
        if (student && student.email) {
          const emailBody = tmpl.htmlBody
            .replace(/{student_name}/g, student.name || 'Student')
            .replace(/{score}/g, attempt.score || 0)
            .replace(/{rank}/g, attempt.rank || '-')
            .replace(/{percentile}/g, attempt.percentile || 0)
            .replace(/{exam_title}/g, attempt.examTitle || 'Exam')
            .replace(/{date}/g, new Date().toLocaleDateString('en-IN'))
          sendCustomEmail([student.email], tmpl.subject, emailBody)
            .catch(e => console.error('[Result Email]', e.message))
        }
      }
    } catch(re) { console.error('[S109 Result]', re.message) }

    return res.status(200).json({
      message: 'Result calculated successfully',
      score: attempt.score,
      totalCorrect: attempt.totalCorrect,
      totalIncorrect: attempt.totalIncorrect,
      totalUnattempted: attempt.totalUnattempted,
      rank, percentile, totalStudents,
      subjectStats: attempt.subjectStats,
      sectionStats: attempt.sectionStats,
      difficultyFlag: diffResult
    });
  } catch (err) {
    console.error('calculate-result error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/results/:attemptId
router.get('/:attemptId', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    return res.status(200).json({
      score: attempt.score,
      totalCorrect: attempt.totalCorrect,
      totalIncorrect: attempt.totalIncorrect,
      totalUnattempted: attempt.totalUnattempted,
      rank: attempt.rank,
      percentile: attempt.percentile,
      subjectStats: attempt.subjectStats,
      sectionStats: attempt.sectionStats,
      resultCalculated: attempt.resultCalculated
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/results/:attemptId/omrsheet
router.get('/:attemptId/omrsheet', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const rows = await generateOMRData(attemptId);
    return res.status(200).json({ ormSheet: rows });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/results/:attemptId/share-card
router.get('/:attemptId/share-card', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const shareData = await generateShareCard(attemptId);
    return res.status(200).json({ shareCard: shareData });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/results/:attemptId/receipt
router.get('/:attemptId/receipt', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId).populate('studentId', 'name email');
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const exam = await (require('../models/Exam')).findById(attempt.examId);
    const receiptData = {
      studentName: attempt.studentId?.name || 'Student',
      examTitle: exam?.title || 'Exam',
      attemptId: attemptId.toString(),
      submittedAt: attempt.submittedAt,
      score: attempt.score,
      totalMarks: exam?.totalMarks || 720,
      rank: attempt.rank,
      percentile: attempt.percentile,
      totalCorrect: attempt.totalCorrect,
      totalIncorrect: attempt.totalIncorrect,
      totalUnattempted: attempt.totalUnattempted,
      subjectStats: attempt.subjectStats
    };
    await generateReceiptPDF(receiptData, res);
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
