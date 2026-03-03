const express = require('express');
const router = express.Router();

const Exam = require('../models/Exam');
const Question = require('../models/Question');
const Result = require('../models/Result');
const { verifyToken } = require('../middleware/auth');

router.post('/:examId/submit', verifyToken, async (req, res) => {
  try {
    const { examId } = req.params;
    const { answers } = req.body;

    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ message: 'Exam not found' });

    const now = new Date();
    if (exam.schedule?.startTime && now < exam.schedule.startTime)
      return res.status(400).json({ message: 'Exam not started' });

    if (exam.schedule?.endTime && now > exam.schedule.endTime)
      return res.status(400).json({ message: 'Exam ended' });

    const attemptCount = await Result.countDocuments({
      examId,
      studentId: req.user.id
    });

    if (attemptCount >= exam.maxAttempts)
      return res.status(403).json({ message: 'Max attempts reached' });

    let totalScore = 0;
    let correctCount = 0;
    let incorrectCount = 0;
    let unattemptedCount = 0;

    const evaluatedAnswers = [];

    for (const ans of answers) {
      const question = await Question.findById(ans.questionId);
      if (!question) continue;

      const selected = ans.selectedOption || [];
      const correct = question.correct || [];

      let isCorrect = false;
      let marksAwarded = 0;

      if (question.type === 'MCQ') {
        if (selected.length === 0) {
          unattemptedCount++;
          marksAwarded = exam.markingScheme.unattempted;
        } else if (selected[0] === correct[0]) {
          isCorrect = true;
          correctCount++;
          marksAwarded = exam.markingScheme.correct;
        } else {
          incorrectCount++;
          marksAwarded = exam.markingScheme.incorrect;
        }
      }

      if (question.type === 'MSQ') {
        if (selected.length === 0) {
          unattemptedCount++;
          marksAwarded = exam.markingScheme.unattempted;
        } else if (exam.markingScheme.msqMode === 'ALL_OR_NOTHING') {
          const match =
            selected.length === correct.length &&
            selected.every(val => correct.includes(val));
          if (match) {
            isCorrect = true;
            correctCount++;
            marksAwarded = exam.markingScheme.correct;
          } else {
            incorrectCount++;
            marksAwarded = 0;
          }
        } else {
          // PARTIAL_NEGATIVE
          let score = 0;
          selected.forEach(opt => {
            if (correct.includes(opt)) score += exam.markingScheme.correct / correct.length;
            else score += exam.markingScheme.incorrect / selected.length;
          });
          if (score < 0) score = 0;
          marksAwarded = score;
          if (score === exam.markingScheme.correct) correctCount++;
          else incorrectCount++;
        }
      }

      totalScore += marksAwarded;

      evaluatedAnswers.push({
        questionId: question._id,
        selectedOption: selected,
        isCorrect,
        marksAwarded
      });
    }

    const result = await Result.create({
      examId,
      studentId: req.user.id,
      answers: evaluatedAnswers,
      score: totalScore,
      correctCount,
      incorrectCount,
      unattemptedCount,
      attemptNumber: attemptCount + 1
    });

    // Rank recalculation
    const allResults = await Result.find({ examId }).sort({ score: -1 });

    for (let i = 0; i < allResults.length; i++) {
      allResults[i].rank = i + 1;
      await allResults[i].save();
    }

    res.json({
      message: 'Exam submitted successfully',
      score: totalScore,
      correctCount,
      incorrectCount,
      unattemptedCount,
      rank: result.rank
    });

  } catch (err) {
    res.status(500).json({ message: 'Submission error', error: err.message });
  }
});

module.exports = router;
