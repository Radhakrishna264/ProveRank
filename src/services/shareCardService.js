const Attempt = require('../models/Attempt');
const Exam = require('../models/Exam');

async function generateShareCard(attemptId) {
  const attempt = await Attempt.findById(attemptId)
    .populate('studentId', 'name email');
  if (!attempt) throw new Error('Attempt not found');

  const exam = await Exam.findById(attempt.examId);
  if (!exam) throw new Error('Exam not found');

  const shareData = {
    studentName: attempt.studentId?.name || 'Student',
    examTitle: exam.title || 'Exam',
    score: attempt.score || 0,
    totalMarks: exam.totalMarks || 720,
    rank: attempt.rank || '-',
    percentile: attempt.percentile || 0,
    totalCorrect: attempt.totalCorrect || 0,
    totalIncorrect: attempt.totalIncorrect || 0,
    totalUnattempted: attempt.totalUnattempted || 0,
    subjectStats: attempt.subjectStats || {},
    attemptId: attemptId.toString(),
    generatedAt: new Date()
  };

  attempt.shareCardData = shareData;
  await attempt.save();

  return shareData;
}

module.exports = { generateShareCard };
