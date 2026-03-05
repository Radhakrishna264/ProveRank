const Attempt = require('../models/Attempt');
const Exam = require('../models/Exam');

async function checkDifficultyFlag(examId) {
  const exam = await Exam.findById(examId);
  if (!exam) return;

  const attempts = await Attempt.find({
    examId,
    status: { $in: ['submitted', 'timeout'] },
    resultCalculated: true
  }).select('totalCorrect totalIncorrect totalUnattempted');

  if (attempts.length < 5) return;

  const questions = exam.questionSnapshot || [];
  const totalQ = questions.length || 1;

  let totalWrong = 0;
  for (const a of attempts) {
    totalWrong += (a.totalIncorrect || 0) + (a.totalUnattempted || 0);
  }

  const avgWrongPercent = (totalWrong / (attempts.length * totalQ)) * 100;

  if (avgWrongPercent >= 90) {
    console.log(`⚠️ Exam ${examId} flagged — ${avgWrongPercent.toFixed(1)}% wrong/unattempted`);
    return { flagged: true, avgWrongPercent };
  }

  return { flagged: false, avgWrongPercent };
}

module.exports = { checkDifficultyFlag };
