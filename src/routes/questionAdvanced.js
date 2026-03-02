const express = require('express');
const router = express.Router();
const Question = require('../models/Question');
const { verifyToken, isAdmin } = require('../middleware/auth');

// ✅ STEP 14 - Version History Rollback (S87)
router.get('/:id/versions', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id).select('text versionHistory version');
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({
      success: true,
      currentVersion: question.version || 1,
      currentText: question.text,
      totalVersions: (question.versionHistory || []).length,
      versionHistory: question.versionHistory || []
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/:id/rollback/:versionNum', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    const vNum = parseInt(req.params.versionNum);
    const oldVersion = (question.versionHistory || []).find(v => v.version === vNum);
    if (!oldVersion) return res.status(404).json({ success: false, message: 'Version not found' });
    question.versionHistory.push({
      version: question.version,
      text: question.text,
      options: question.options,
      correct: question.correct,
      editedAt: new Date()
    });
    question.text = oldVersion.text;
    question.options = oldVersion.options;
    question.correct = oldVersion.correct;
    question.version = (question.version || 1) + 1;
    await question.save();
    res.json({ success: true, message: 'Rolled back to version ' + vNum + ' successfully!', question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 15 - Multi-Select Questions MSQ (S90)
router.post('/msq/validate', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionId, selectedOptions } = req.body;
    const question = await Question.findById(questionId);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    if (question.type !== 'MSQ') return res.status(400).json({ success: false, message: 'Not an MSQ question' });

    const correctSet = new Set(question.correct);
    const selectedSet = new Set(selectedOptions);
    const correctAnswers = question.correct.length;
    const selectedCorrect = selectedOptions.filter(o => correctSet.has(o)).length;
    const selectedWrong = selectedOptions.filter(o => !correctSet.has(o)).length;

    let marks = 0;
    let result = '';
    if (selectedWrong === 0 && selectedCorrect === correctAnswers) {
      marks = 4; result = 'Full Marks';
    } else if (selectedWrong === 0 && selectedCorrect > 0) {
      marks = Math.round((selectedCorrect / correctAnswers) * 4 * 10) / 10;
      result = 'Partial Marks';
    } else {
      marks = -2; result = 'Wrong - Negative Marking';
    }

    res.json({
      success: true,
      questionType: 'MSQ',
      correctOptions: question.correct,
      selectedOptions,
      selectedCorrect,
      selectedWrong,
      marksAwarded: marks,
      result
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 16 - Integer Type Questions
router.post('/integer/validate', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionId, answer } = req.body;
    const question = await Question.findById(questionId);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    if (question.type !== 'Integer') return res.status(400).json({ success: false, message: 'Not an Integer type question' });

    const correctAnswer = question.correct[0];
    const isCorrect = parseInt(answer) === parseInt(correctAnswer);

    res.json({
      success: true,
      questionType: 'Integer',
      submittedAnswer: parseInt(answer),
      correctAnswer: parseInt(correctAnswer),
      isCorrect,
      marksAwarded: isCorrect ? 4 : -1,
      result: isCorrect ? '✅ Correct! +4 marks' : '❌ Wrong! -1 mark'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 17 - PYQ Bank (S104)
router.post('/pyq/add', verifyToken, isAdmin, async (req, res) => {
  try {
    const { text, hindiText, options, correct, subject, chapter, topic, difficulty, year, exam } = req.body;
    if (!year) return res.status(400).json({ success: false, message: 'Year required for PYQ' });

    const question = new Question({
      text, hindiText, options, correct, subject, chapter, topic, difficulty,
      type: 'SCQ',
      isPYQ: true,
      pyqYear: year,
      pyqExam: exam || 'NEET',
      createdBy: req.user._id,
      tags: ['PYQ', exam || 'NEET', year.toString()]
    });
    await question.save();
    res.json({ success: true, message: 'PYQ added successfully!', question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/pyq/list', verifyToken, isAdmin, async (req, res) => {
  try {
    const { year, subject, exam } = req.query;
    let filter = { isPYQ: true };
    if (year) filter.pyqYear = parseInt(year);
    if (subject) filter.subject = subject;
    if (exam) filter.pyqExam = exam;

    const pyqs = await Question.find(filter).sort({ pyqYear: -1 });
    const yearWise = {};
    pyqs.forEach(q => {
      const y = q.pyqYear || 'Unknown';
      if (!yearWise[y]) yearWise[y] = 0;
      yearWise[y]++;
    });

    res.json({
      success: true,
      total: pyqs.length,
      yearWiseCount: yearWise,
      questions: pyqs
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 18 - Question Error Reporting (S84)
router.post('/:id/report-error', verifyToken, async (req, res) => {
  try {
    const { errorType, description } = req.body;
    if (!errorType) return res.status(400).json({ success: false, message: 'Error type required' });

    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    if (!question.errorReports) question.errorReports = [];
    question.errorReports.push({
      reportedBy: req.user._id,
      errorType,
      description: description || '',
      reportedAt: new Date(),
      status: 'Pending'
    });
    question.hasUnresolvedError = true;
    await question.save();

    res.json({
      success: true,
      message: '⚠️ Error reported! Admin will review it.',
      errorType,
      totalReports: question.errorReports.length
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/error-reports', verifyToken, isAdmin, async (req, res) => {
  try {
    const questions = await Question.find({ hasUnresolvedError: true })
      .select('text subject errorReports hasUnresolvedError');
    res.json({
      success: true,
      totalWithErrors: questions.length,
      questions: questions.map(q => ({
        _id: q._id,
        text: q.text ? q.text.substring(0, 80) : '',
        subject: q.subject,
        pendingReports: (q.errorReports || []).filter(r => r.status === 'Pending').length,
        errorReports: q.errorReports
      }))
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id/resolve-error/:reportIndex', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    const idx = parseInt(req.params.reportIndex);
    if (!question.errorReports[idx]) return res.status(404).json({ success: false, message: 'Report not found' });
    question.errorReports[idx].status = 'Resolved';
    question.errorReports[idx].resolvedAt = new Date();
    const pending = question.errorReports.filter(r => r.status === 'Pending');
    question.hasUnresolvedError = pending.length > 0;
    await question.save();
    res.json({ success: true, message: 'Error report resolved!', question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
