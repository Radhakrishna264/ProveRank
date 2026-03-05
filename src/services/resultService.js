const Attempt = require('../models/Attempt');
const Exam = require('../models/Exam');
const Question = require('../models/Question');

async function calculateResult(attemptId) {
  const attempt = await Attempt.findById(attemptId);
  if (!attempt) throw new Error('Attempt not found');

  const exam = await Exam.findById(attempt.examId);
  if (!exam) throw new Error('Exam not found');

  const marking = exam.markingScheme || { correct: 4, incorrect: -1, unattempted: 0 };
  const questions = exam.questionSnapshot || [];

  let totalScore = 0;
  let totalCorrect = 0;
  let totalIncorrect = 0;
  let totalUnattempted = 0;
  const subjectStats = {};
  const sectionStats = {};

  for (const q of questions) {
    const qId = q._id ? q._id.toString() : q.questionId?.toString();
    const qSubject = q.subject || 'General';
    const qSection = q.section || 'Default';
    const qType = q.type || 'SCQ';
    const correctAnswers = q.correct || [];

    if (!subjectStats[qSubject]) {
      subjectStats[qSubject] = { correct: 0, incorrect: 0, unattempted: 0, score: 0 };
    }
    if (!sectionStats[qSection]) {
      sectionStats[qSection] = { correct: 0, incorrect: 0, unattempted: 0, score: 0 };
    }

    const ans = attempt.answers.find(a => a.questionId?.toString() === qId);
    const selected = ans ? ans.selectedOption : null;
    const isUnattempted = selected === null || selected === undefined;

    let qScore = 0;

    if (isUnattempted) {
      qScore = marking.unattempted || 0;
      totalUnattempted++;
      subjectStats[qSubject].unattempted++;
      sectionStats[qSection].unattempted++;
    } else if (qType === 'MSQ') {
      const selectedArr = Array.isArray(selected) ? selected : [selected];
      const correctArr = correctAnswers.map(Number);
      const isFullCorrect = selectedArr.length === correctArr.length &&
        selectedArr.every(s => correctArr.includes(Number(s)));
      const isPartial = selectedArr.some(s => correctArr.includes(Number(s))) && !isFullCorrect;
      const hasWrong = selectedArr.some(s => !correctArr.includes(Number(s)));

      if (isFullCorrect) {
        qScore = marking.correct || 4;
        totalCorrect++;
        subjectStats[qSubject].correct++;
        sectionStats[qSection].correct++;
      } else if (exam.markingScheme?.msqMode === 'PARTIAL_NEGATIVE' && hasWrong) {
        qScore = marking.incorrect || -1;
        totalIncorrect++;
        subjectStats[qSubject].incorrect++;
        sectionStats[qSection].incorrect++;
      } else if (isPartial) {
        qScore = 0;
        totalIncorrect++;
        subjectStats[qSubject].incorrect++;
        sectionStats[qSection].incorrect++;
      } else {
        qScore = marking.incorrect || -1;
        totalIncorrect++;
        subjectStats[qSubject].incorrect++;
        sectionStats[qSection].incorrect++;
      }
    } else {
      const selectedNum = Number(selected);
      const isCorrect = correctAnswers.map(Number).includes(selectedNum);
      if (isCorrect) {
        qScore = marking.correct || 4;
        totalCorrect++;
        subjectStats[qSubject].correct++;
        sectionStats[qSection].correct++;
      } else {
        qScore = marking.incorrect || -1;
        totalIncorrect++;
        subjectStats[qSubject].incorrect++;
        sectionStats[qSection].incorrect++;
      }
    }

    totalScore += qScore;
    subjectStats[qSubject].score += qScore;
    sectionStats[qSection].score += qScore;
  }

  attempt.score = totalScore;
  attempt.totalCorrect = totalCorrect;
  attempt.totalIncorrect = totalIncorrect;
  attempt.totalUnattempted = totalUnattempted;
  attempt.subjectStats = subjectStats;
  attempt.sectionStats = sectionStats;
  attempt.resultCalculated = true;
  attempt.resultCalculatedAt = new Date();
  await attempt.save();

  return attempt;
}

module.exports = { calculateResult };
