const Attempt = require('../models/Attempt');
const Exam = require('../models/Exam');

async function generateOMRData(attemptId) {
  const attempt = await Attempt.findById(attemptId);
  if (!attempt) throw new Error('Attempt not found');

  const exam = await Exam.findById(attempt.examId);
  if (!exam) throw new Error('Exam not found');

  const questions = exam.questionSnapshot || [];
  const ormRows = [];

  for (const q of questions) {
    const qId = q._id ? q._id.toString() : q.questionId?.toString();
    const correctAnswers = (q.correct || []).map(Number);
    const ans = attempt.answers.find(
      a => a.questionId?.toString() === qId
    );
    const selected = ans ? ans.selectedOption : null;
    const isUnattempted = selected === null || selected === undefined;

    let status = 'unattempted';
    if (!isUnattempted) {
      const selectedArr = Array.isArray(selected)
        ? selected.map(Number)
        : [Number(selected)];
      const isCorrect = selectedArr.every(
        s => correctAnswers.includes(s)
      ) && selectedArr.length === correctAnswers.length;
      status = isCorrect ? 'correct' : 'incorrect';
    }

    ormRows.push({
      questionId: qId,
      subject: q.subject || 'General',
      selected,
      correct: correctAnswers,
      status
    });
  }

  attempt.ormSheetData = {
    rows: ormRows,
    generatedAt: new Date()
  };
  await attempt.save();

  return ormRows;
}

module.exports = { generateOMRData };
