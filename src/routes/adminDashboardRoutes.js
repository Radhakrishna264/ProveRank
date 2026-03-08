const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const os = require('os');

const User = require('../models/User');
const Exam = require('../models/Exam');
const Attempt = require('../models/Attempt');
const AntiCheatLog = require('../models/AntiCheatLog');
const WebcamLog = require('../models/WebcamLog');
const AudioLog = require('../models/AudioLog');
const Question = require('../models/Question');

const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

function authAdmin(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token missing' });
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (!['admin', 'superadmin'].includes(decoded.role)) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    req.user = decoded;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// STEP 1 — Total Users Count
router.get('/stats/users', authAdmin, async (req, res) => {
  try {
    const total = await User.countDocuments();
    const students = await User.countDocuments({ role: 'student' });
    const admins = await User.countDocuments({ role: { $in: ['admin', 'superadmin'] } });
    const today = new Date(); today.setHours(0,0,0,0);
    const newToday = await User.countDocuments({ createdAt: { $gte: today } });
    res.json({ success: true, step: 'S1', total, students, admins, newToday });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 2 — Total Exams Count
router.get('/stats/exams', authAdmin, async (req, res) => {
  try {
    const total = await Exam.countDocuments();
    const published = await Exam.countDocuments({ status: 'published' });
    const draft = await Exam.countDocuments({ status: 'draft' });
    const today = new Date(); today.setHours(0,0,0,0);
    const newToday = await Exam.countDocuments({ createdAt: { $gte: today } });
    res.json({ success: true, step: 'S2', total, published, draft, newToday });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 3 — Active Attempts Live Count via Socket.io
router.get('/stats/active-attempts', authAdmin, async (req, res) => {
  try {
    const active = await Attempt.countDocuments({ status: 'active' });
    const submitted = await Attempt.countDocuments({ status: 'submitted' });
    const autoSubmitted = await Attempt.countDocuments({ status: 'auto_submitted' });
    const totalToday = (() => { const d = new Date(); d.setHours(0,0,0,0); return d; })();
    const todayAttempts = await Attempt.countDocuments({ createdAt: { $gte: totalToday } });

    const io = req.app.get('io');
    if (io) {
      io.emit('admin:active-attempts', { active, submitted, autoSubmitted, todayAttempts });
    }

    res.json({ success: true, step: 'S3', active, submitted, autoSubmitted, todayAttempts, socketBroadcast: !!io });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 4 — Cheating Alerts Summary
router.get('/stats/cheating-alerts', authAdmin, async (req, res) => {
  try {
    const total = await AntiCheatLog.countDocuments();
    const autoSubmits = await AntiCheatLog.countDocuments({ autoSubmitTriggered: true });
    const byType = await AntiCheatLog.aggregate([
      { $group: { _id: '$eventType', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    const webcamFlags = await WebcamLog.countDocuments({ cheatingFlag: true });
    const audioFlags = await AudioLog.countDocuments({ audioFlag: true });
    const last24h = new Date(Date.now() - 24*60*60*1000);
    const recent = await AntiCheatLog.countDocuments({ createdAt: { $gte: last24h } });

    res.json({ success: true, step: 'S4', total, autoSubmits, byType, webcamFlags, audioFlags, last24hAlerts: recent });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 5 — S13: Admin Analytics Dashboard — exam wise avg score, pass/fail ratio
router.get('/analytics/exam-dashboard', authAdmin, async (req, res) => {
  try {
    const examStats = await Attempt.aggregate([
      { $match: { status: { $in: ['submitted', 'auto_submitted'] } } },
      {
        $group: {
          _id: '$examId',
          totalAttempts: { $sum: 1 },
          avgScore: { $avg: '$score' },
          maxScore: { $max: '$score' },
          minScore: { $min: '$score' },
          passed: {
            $sum: { $cond: [{ $gte: ['$score', 360] }, 1, 0] }
          }
        }
      },
      {
        $addFields: {
          passRate: { $multiply: [{ $divide: ['$passed', '$totalAttempts'] }, 100] },
          failCount: { $subtract: ['$totalAttempts', '$passed'] }
        }
      },
      { $sort: { totalAttempts: -1 } },
      { $limit: 20 }
    ]);

    await Attempt.populate(examStats, { path: '_id', model: 'Exam', select: 'title totalMarks', localField: '_id', foreignField: '_id', as: 'examInfo' });

    res.json({ success: true, step: 'S5-S13', tag: 'S13', examStats });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 6 — S53: Platform Analytics — traffic, peak time, server health
router.get('/analytics/platform', authAdmin, async (req, res) => {
  try {
    const last7days = new Date(Date.now() - 7*24*60*60*1000);
    const dailyAttempts = await Attempt.aggregate([
      { $match: { createdAt: { $gte: last7days } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    const hourlyAttempts = await Attempt.aggregate([
      { $match: { createdAt: { $gte: last7days } } },
      {
        $group: {
          _id: { $hour: '$createdAt' },
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);

    const peakHour = hourlyAttempts[0] || null;

    const serverHealth = {
      uptime: Math.floor(process.uptime()),
      uptimeHours: (process.uptime() / 3600).toFixed(2),
      memoryUsed: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      memoryTotal: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
      cpuLoad: os.loadavg()[0].toFixed(2),
      platform: os.platform(),
      nodeVersion: process.version
    };

    const totalUsers = await User.countDocuments();
    const totalAttempts = await Attempt.countDocuments();

    res.json({
      success: true, step: 'S6-S53', tag: 'S53',
      dailyAttempts, peakHour, serverHealth, totalUsers, totalAttempts
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 7 — S108: Exam Attempt Heatmap — day/hour wise
router.get('/analytics/heatmap', authAdmin, async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 30;
    const since = new Date(Date.now() - days*24*60*60*1000);

    const heatmap = await Attempt.aggregate([
      { $match: { createdAt: { $gte: since } } },
      {
        $group: {
          _id: {
            day: { $dayOfWeek: '$createdAt' },
            hour: { $hour: '$createdAt' }
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { '_id.day': 1, '_id.hour': 1 } }
    ]);

    const dayNames = ['', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const formatted = heatmap.map(h => ({
      day: dayNames[h._id.day],
      dayNum: h._id.day,
      hour: h._id.hour,
      label: `${h._id.hour}:00`,
      count: h.count
    }));

    const maxCount = Math.max(...formatted.map(h => h.count), 0);
    res.json({ success: true, step: 'S7-S108', tag: 'S108', days, heatmap: formatted, maxCount });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 8 — S110: Student Retention Analytics — inactive students tracking
router.get('/analytics/retention', authAdmin, async (req, res) => {
  try {
    const now = new Date();
    const day7 = new Date(now - 7*24*60*60*1000);
    const day30 = new Date(now - 30*24*60*60*1000);
    const day90 = new Date(now - 90*24*60*60*1000);

    const totalStudents = await User.countDocuments({ role: 'student' });

    const activeStudentIds7 = await Attempt.distinct('studentId', { createdAt: { $gte: day7 } });
    const activeStudentIds30 = await Attempt.distinct('studentId', { createdAt: { $gte: day30 } });

    const inactive7 = totalStudents - activeStudentIds7.length;
    const inactive30 = totalStudents - activeStudentIds30.length;

    const neverAttempted = await User.aggregate([
      { $match: { role: 'student' } },
      {
        $lookup: {
          from: 'attempts',
          localField: '_id',
          foreignField: 'studentId',
          as: 'attempts'
        }
      },
      { $match: { attempts: { $size: 0 } } },
      { $count: 'count' }
    ]);

    const newStudents30 = await User.countDocuments({ role: 'student', createdAt: { $gte: day30 } });

    res.json({
      success: true, step: 'S8-S110', tag: 'S110',
      totalStudents,
      activeLastWeek: activeStudentIds7.length,
      activeLastMonth: activeStudentIds30.length,
      inactiveLast7Days: inactive7,
      inactiveLast30Days: inactive30,
      neverAttempted: neverAttempted[0]?.count || 0,
      newStudentsLast30Days: newStudents30,
      retentionRate7d: totalStudents > 0 ? ((activeStudentIds7.length / totalStudents) * 100).toFixed(1) : 0,
      retentionRate30d: totalStudents > 0 ? ((activeStudentIds30.length / totalStudents) * 100).toFixed(1) : 0
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 9 — N9: Exam Series Analytics
router.get('/analytics/series/:seriesId', authAdmin, async (req, res) => {
  try {
    const { seriesId } = req.params;

    const seriesExams = await Exam.find({ seriesId: seriesId }).select('_id title totalMarks createdAt');
    if (!seriesExams.length) {
      return res.json({ success: true, step: 'S9-N9', tag: 'N9', message: 'No exams found for this series', seriesId });
    }

    const examIds = seriesExams.map(e => e._id);
    const seriesStats = await Attempt.aggregate([
      { $match: { examId: { $in: examIds }, status: { $in: ['submitted', 'auto_submitted'] } } },
      {
        $group: {
          _id: '$examId',
          attempts: { $sum: 1 },
          avgScore: { $avg: '$score' },
          topScore: { $max: '$score' },
          passed: { $sum: { $cond: [{ $gte: ['$score', 360] }, 1, 0] } }
        }
      }
    ]);

    const uniqueParticipants = await Attempt.distinct('studentId', { examId: { $in: examIds } });
    const overallAvg = seriesStats.reduce((s, e) => s + e.avgScore, 0) / (seriesStats.length || 1);

    res.json({
      success: true, step: 'S9-N9', tag: 'N9',
      seriesId, totalExamsInSeries: seriesExams.length,
      uniqueParticipants: uniqueParticipants.length,
      overallAvgScore: overallAvg.toFixed(2),
      examBreakdown: seriesStats
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 9b — N9 all series list (no seriesId)
router.get('/analytics/series', authAdmin, async (req, res) => {
  try {
    const seriesList = await Exam.aggregate([
      { $match: { seriesId: { $exists: true, $ne: null } } },
      { $group: { _id: '$seriesId', examCount: { $sum: 1 } } }
    ]);
    res.json({ success: true, tag: 'N9', seriesList });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 10 — M9: Question Bank Statistics Dashboard
router.get('/analytics/question-bank', authAdmin, async (req, res) => {
  try {
    const totalQuestions = await Question.countDocuments();

    const bySubject = await Question.aggregate([
      { $group: { _id: '$subject', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);

    const byDifficulty = await Question.aggregate([
      { $group: { _id: '$difficulty', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);

    const byType = await Question.aggregate([
      { $group: { _id: '$type', count: { $sum: 1 } } }
    ]);

    const withImages = await Question.countDocuments({ 'image': { $exists: true, $ne: null } });
    const recentlyAdded = await Question.countDocuments({
      createdAt: { $gte: new Date(Date.now() - 30*24*60*60*1000) }
    });

    res.json({
      success: true, step: 'S10-M9', tag: 'M9',
      totalQuestions, bySubject, byDifficulty, byType,
      withImages, recentlyAdded30Days: recentlyAdded
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// STEP 11 — N19: Institute Report Card PDF (monthly auto generator)
router.get('/reports/institute-report-card', authAdmin, async (req, res) => {
  try {
    const PDFDocument = require('pdfkit');
    const month = req.query.month || new Date().toISOString().slice(0, 7);
    const [y, m] = month.split('-').map(Number);
    const startDate = new Date(y, m-1, 1);
    const endDate = new Date(y, m, 0, 23, 59, 59);

    const totalStudents = await User.countDocuments({ role: 'student' });
    const newStudents = await User.countDocuments({ role: 'student', createdAt: { $gte: startDate, $lte: endDate } });
    const totalExams = await Exam.countDocuments();
    const examsThisMonth = await Exam.countDocuments({ createdAt: { $gte: startDate, $lte: endDate } });
    const monthAttempts = await Attempt.countDocuments({ createdAt: { $gte: startDate, $lte: endDate } });
    const cheatingThisMonth = await AntiCheatLog.countDocuments({ createdAt: { $gte: startDate, $lte: endDate } });
    const autoSubmitsMonth = await AntiCheatLog.countDocuments({ createdAt: { $gte: startDate, $lte: endDate }, autoSubmitTriggered: true });
    const scoreStats = await Attempt.aggregate([
      { $match: { status: { $in: ['submitted','auto_submitted'] }, createdAt: { $gte: startDate, $lte: endDate } } },
      { $group: { _id: null, avg: { $avg: '$score' }, max: { $max: '$score' }, min: { $min: '$score' } } }
    ]);
    const scores = scoreStats[0] || { avg: 0, max: 0, min: 0 };

    const doc = new PDFDocument({ margin: 50 });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="ProveRank_Report_${month}.pdf"`);
    doc.pipe(res);

    doc.fontSize(22).fillColor('#1B3A6B').text('ProveRank Institute Report Card', { align: 'center' });
    doc.fontSize(13).fillColor('#374151').text(`Month: ${month}`, { align: 'center' });
    doc.moveDown(2);

    doc.fontSize(15).fillColor('#0F766E').text('Student Overview');
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke('#D1D5DB'); doc.moveDown(0.5);
    doc.fontSize(12).fillColor('#374151');
    doc.text(`Total Students: ${totalStudents}`);
    doc.text(`New Registrations This Month: ${newStudents}`);
    doc.moveDown();

    doc.fontSize(15).fillColor('#0F766E').text('Exam Overview');
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke('#D1D5DB'); doc.moveDown(0.5);
    doc.fontSize(12).fillColor('#374151');
    doc.text(`Total Exams: ${totalExams}`);
    doc.text(`Exams Created This Month: ${examsThisMonth}`);
    doc.text(`Total Attempts This Month: ${monthAttempts}`);
    doc.moveDown();

    doc.fontSize(15).fillColor('#0F766E').text('Score Statistics');
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke('#D1D5DB'); doc.moveDown(0.5);
    doc.fontSize(12).fillColor('#374151');
    doc.text(`Average Score: ${scores.avg ? scores.avg.toFixed(1) : 'N/A'}`);
    doc.text(`Highest Score: ${scores.max || 'N/A'}`);
    doc.text(`Lowest Score: ${scores.min || 'N/A'}`);
    doc.moveDown();

    doc.fontSize(15).fillColor('#0F766E').text('Proctoring Summary');
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke('#D1D5DB'); doc.moveDown(0.5);
    doc.fontSize(12).fillColor('#374151');
    doc.text(`Total Anti-Cheat Events: ${cheatingThisMonth}`);
    doc.text(`Auto-Submissions Due to Violations: ${autoSubmitsMonth}`);
    doc.moveDown(2);

    doc.fontSize(10).fillColor('#6B7280').text(`Generated: ${new Date().toLocaleString()} | ProveRank Platform`, { align: 'center' });
    doc.end();
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
