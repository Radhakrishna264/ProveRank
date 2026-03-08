const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

// ─── Step 1: Publish Results API ────────────────────────────────────────────
router.post('/results/:examId/publish', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Exam = mongoose.model('Exam');
    const exam = await Exam.findByIdAndUpdate(
      req.params.examId,
      { resultPublished: true, resultPublishedAt: new Date(), resultDelayed: false },
      { new: true }
    );
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const io = req.app.get('io');
    if (io) io.to(`exam_${req.params.examId}`).emit('result_published', { examId: req.params.examId });
    res.json({ success: true, message: 'Results published', exam });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 2: Delay Results API ───────────────────────────────────────────────
router.post('/results/:examId/delay', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Exam = mongoose.model('Exam');
    const { delayUntil, reason } = req.body;
    const exam = await Exam.findByIdAndUpdate(
      req.params.examId,
      { resultPublished: false, resultDelayed: true, resultDelayUntil: delayUntil ? new Date(delayUntil) : null, resultDelayReason: reason || '' },
      { new: true }
    );
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: 'Result delayed', delayUntil, exam });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 3: Manual Score Override API ──────────────────────────────────────
router.patch('/results/:attemptId/score-override', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Result = mongoose.model('Result');
    const { newScore, reason } = req.body;
    if (newScore === undefined) return res.status(400).json({ success: false, message: 'newScore required' });
    const result = await Result.findOneAndUpdate(
      { attemptId: new mongoose.Types.ObjectId(req.params.attemptId) },
      { $set: { score: newScore, manualOverride: true, overrideReason: reason || '', overrideAt: new Date() } },
      { new: true }
    );
    if (!result) return res.status(404).json({ success: false, message: 'Result not found' });
    res.json({ success: true, message: 'Score overridden', result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 4: Rank List Generation API ───────────────────────────────────────
router.get('/results/:examId/rank-list', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Result = mongoose.model('Result');
    const results = await Result.find({ examId: new mongoose.Types.ObjectId(req.params.examId) })
      .populate('studentId', 'name email')
      .sort({ score: -1, totalTimeTaken: 1 });

    const rankList = results.map((r, i) => ({
      rank: i + 1,
      student: r.studentId,
      score: r.score,
      totalCorrect: r.totalCorrect,
      totalIncorrect: r.totalIncorrect,
      percentile: r.percentile,
      timeTaken: r.totalTimeTaken
    }));

    res.json({ success: true, examId: req.params.examId, total: rankList.length, rankList });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 5: Leaderboard API (S15) ──────────────────────────────────────────
router.get('/results/:examId/leaderboard', async (req, res) => {
  try {
    const Result = mongoose.model('Result');
    const { limit = 10 } = req.query;
    const results = await Result.find({ examId: new mongoose.Types.ObjectId(req.params.examId) })
      .populate('studentId', 'name email')
      .sort({ score: -1 })
      .limit(parseInt(limit));

    const leaderboard = results.map((r, i) => ({
      rank: i + 1,
      name: r.studentId?.name || 'Unknown',
      score: r.score,
      percentile: r.percentile
    }));

    res.json({ success: true, examId: req.params.examId, leaderboard });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 6: Percentile Publish API (S60) ───────────────────────────────────
router.post('/results/:examId/publish-percentile', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Result = mongoose.model('Result');
    const results = await Result.find({ examId: new mongoose.Types.ObjectId(req.params.examId) })
      .sort({ score: -1 });

    const total = results.length;
    if (total === 0) return res.status(404).json({ success: false, message: 'No results found' });

    for (let i = 0; i < total; i++) {
      const percentile = ((total - i - 1) / total) * 100;
      await Result.findByIdAndUpdate(results[i]._id, { percentile: parseFloat(percentile.toFixed(2)), percentilePublished: true });
    }

    res.json({ success: true, message: `Percentile calculated for ${total} students`, total });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 7: Topper Solution PDF Publish Control (S61) ──────────────────────
router.patch('/results/:examId/topper-solution', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Exam = mongoose.model('Exam');
    const { publish, topperSolutionUrl } = req.body;
    const exam = await Exam.findByIdAndUpdate(
      req.params.examId,
      { topperSolutionPublished: publish, topperSolutionUrl: topperSolutionUrl || '' },
      { new: true }
    );
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: publish ? 'Topper solution published' : 'Topper solution hidden', exam });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 8: Student Performance Report PDF (S14) ───────────────────────────
router.get('/results/:studentId/performance-report', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Result = mongoose.model('Result');
    const User = require('../models/User');

    const student = await User.findById(req.params.studentId).select('name email');
    if (!student) return res.status(404).json({ success: false, message: 'Student not found' });

    const results = await Result.find({ studentId: new mongoose.Types.ObjectId(req.params.studentId) })
      .populate('examId', 'title')
      .sort({ createdAt: -1 });

    const totalExams = results.length;
    const avgScore = totalExams > 0 ? (results.reduce((s, r) => s + (r.score || 0), 0) / totalExams).toFixed(2) : 0;
    const bestScore = totalExams > 0 ? Math.max(...results.map(r => r.score || 0)) : 0;

    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument();
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="report_${req.params.studentId}.pdf"`);
    doc.pipe(res);

    doc.fontSize(20).text('ProveRank - Student Performance Report', { align: 'center' });
    doc.moveDown();
    doc.fontSize(14).text(`Student: ${student.name}`);
    doc.text(`Email: ${student.email}`);
    doc.text(`Total Exams: ${totalExams}`);
    doc.text(`Average Score: ${avgScore}`);
    doc.text(`Best Score: ${bestScore}`);
    doc.moveDown();
    doc.fontSize(12).text('Exam-wise Performance:', { underline: true });
    doc.moveDown(0.5);

    results.forEach((r, i) => {
      doc.text(`${i + 1}. ${r.examId?.title || 'Unknown Exam'} - Score: ${r.score || 0} | Rank: ${r.rank || 'N/A'}`);
    });

    doc.end();
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 9: Result Export Excel/PDF (S68) ───────────────────────────────────
router.get('/results/:examId/export', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Result = mongoose.model('Result');
    const { format = 'json' } = req.query;

    const results = await Result.find({ examId: new mongoose.Types.ObjectId(req.params.examId) })
      .populate('studentId', 'name email')
      .sort({ score: -1 });

    const exportData = results.map((r, i) => ({
      rank: i + 1,
      name: r.studentId?.name || '',
      email: r.studentId?.email || '',
      score: r.score || 0,
      totalCorrect: r.totalCorrect || 0,
      totalIncorrect: r.totalIncorrect || 0,
      percentile: r.percentile || 0
    }));

    if (format === 'csv') {
      const csv = ['Rank,Name,Email,Score,Correct,Incorrect,Percentile',
        ...exportData.map(r => `${r.rank},${r.name},${r.email},${r.score},${r.totalCorrect},${r.totalIncorrect},${r.percentile}`)
      ].join('\n');
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="results_${req.params.examId}.csv"`);
      return res.send(csv);
    }

    res.json({ success: true, total: exportData.length, data: exportData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 10: Student Export Excel (S67) ────────────────────────────────────
router.get('/students/export', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('../models/User');
    const students = await User.find({ role: 'student' })
      .select('name email phone createdAt isBanned');

    const csv = ['Name,Email,Phone,Joined,Status',
      ...students.map(s => `${s.name},${s.email},${s.phone || ''},${s.createdAt?.toISOString().split('T')[0] || ''},${s.isBanned ? 'Banned' : 'Active'}`)
    ].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="students_export.csv"');
    res.send(csv);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 11: Answer Key Challenge (S69) ────────────────────────────────────
router.get('/challenges', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Challenge = mongoose.model('Challenge');
    const { status, examId, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (status) filter.status = status;
    if (examId) filter.examId = new mongoose.Types.ObjectId(examId);
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const challenges = await Challenge.find(filter)
      .populate('studentId', 'name email')
      .populate('examId', 'title')
      .sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total = await Challenge.countDocuments(filter);
    res.json({ success: true, total, challenges });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/challenges/:id/review', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Challenge = mongoose.model('Challenge');
    const { status, adminNote } = req.body;
    const challenge = await Challenge.findByIdAndUpdate(
      req.params.id,
      { status, adminNote, reviewedAt: new Date(), reviewedBy: req.user.id },
      { new: true }
    );
    if (!challenge) return res.status(404).json({ success: false, message: 'Challenge not found' });
    res.json({ success: true, message: 'Challenge reviewed', challenge });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 12: Re-Evaluation Request (S71) ────────────────────────────────────
router.get('/re-evaluations', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const ReEvaluation = mongoose.model('ReEvaluation');
    const { status, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (status) filter.status = status;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const requests = await ReEvaluation.find(filter)
      .populate('studentId', 'name email')
      .populate('examId', 'title')
      .sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total = await ReEvaluation.countDocuments(filter);
    res.json({ success: true, total, requests });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/re-evaluations/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const ReEvaluation = mongoose.model('ReEvaluation');
    const { status, adminNote } = req.body;
    const request = await ReEvaluation.findByIdAndUpdate(
      req.params.id,
      { status, adminNote, resolvedAt: new Date() },
      { new: true }
    );
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });
    res.json({ success: true, message: 'Re-evaluation updated', request });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 13: Grievance/Complaint Management (S92) ───────────────────────────
router.get('/grievances', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Grievance = mongoose.model('Grievance');
    const { status, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (status) filter.status = status;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const grievances = await Grievance.find(filter)
      .populate('studentId', 'name email')
      .sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit));
    const total = await Grievance.countDocuments(filter);
    res.json({ success: true, total, grievances });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/grievances/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Grievance = mongoose.model('Grievance');
    const { status, adminReply } = req.body;
    const grievance = await Grievance.findByIdAndUpdate(
      req.params.id,
      { status, adminReply, resolvedAt: new Date() },
      { new: true }
    );
    if (!grievance) return res.status(404).json({ success: false, message: 'Grievance not found' });
    res.json({ success: true, message: 'Grievance updated', grievance });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 14: Exam Transparency Report (S70) ─────────────────────────────────
router.get('/results/:examId/transparency', async (req, res) => {
  try {
    const Result = mongoose.model('Result');
    const Attempt = mongoose.model('Attempt');

    const results = await Result.find({ examId: new mongoose.Types.ObjectId(req.params.examId) });
    const totalAttempts = await Attempt.countDocuments({ examId: new mongoose.Types.ObjectId(req.params.examId) });

    if (results.length === 0) return res.json({ success: true, message: 'No results yet', examId: req.params.examId });

    const scores = results.map(r => r.score || 0);
    const avgScore = (scores.reduce((a, b) => a + b, 0) / scores.length).toFixed(2);
    const highestScore = Math.max(...scores);
    const lowestScore = Math.min(...scores);
    const passCount = scores.filter(s => s >= 360).length;
    const passRate = ((passCount / scores.length) * 100).toFixed(1);

    res.json({
      success: true,
      examId: req.params.examId,
      totalAttempts,
      totalResults: results.length,
      avgScore: parseFloat(avgScore),
      highestScore,
      lowestScore,
      passCount,
      passRate: parseFloat(passRate)
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
