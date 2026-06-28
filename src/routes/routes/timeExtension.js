// Feature 32 — Per-Student Time Extension (All Sub-Features)
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

// ── Auth Middleware ────────────────────────────────────────────
function authAdmin(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token missing' });
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (!['admin', 'superadmin'].includes(decoded.role))
      return res.status(403).json({ error: 'Admin access required' });
    req.user = decoded;
    next();
  } catch(e) { return res.status(401).json({ error: 'Invalid token' }); }
}

// ──────────────────────────────────────────────────────────────
// 32.1 / 32.10 — GET active students in a live exam
// GET /api/time-extension/active-students/:examId
// ──────────────────────────────────────────────────────────────
router.get('/active-students/:examId', authAdmin, async (req, res) => {
  try {
    const Attempt       = require('../models/Attempt');
    const Exam          = require('../models/Exam');
    const User          = require('../models/User');
    const TimeExtension = require('../models/TimeExtension');

    const exam = await Exam.findById(req.params.examId).select('title duration');
    if (!exam) return res.status(404).json({ error: 'Exam not found' });

    const activeAttempts = await Attempt.find({
      examId: req.params.examId,
      status: 'active'
    }).lean();

    const studentIds = activeAttempts.map(a => a.studentId);
    const students   = await User.find({ _id: { $in: studentIds } }).select('name email rollNumber').lean();
    const studMap    = {};
    students.forEach(s => { studMap[s._id.toString()] = s; });

    // Calculate remaining time including extensions (32.10)
    const baseDurSec = (exam.duration || 200) * 60;
    const now        = Date.now();

    const result = await Promise.all(activeAttempts.map(async (a) => {
      const exts     = await TimeExtension.find({ attemptId: a._id, isUndone: false });
      const extMin   = exts.reduce((s, e) => s + e.extraMinutes, 0);
      const totalSec = baseDurSec + extMin * 60;
      const elapsed  = Math.floor((now - new Date(a.startedAt).getTime()) / 1000);
      const remaining= Math.max(0, totalSec - elapsed);
      const stud     = studMap[a.studentId?.toString()] || {};
      return {
        attemptId:      a._id,
        studentId:      a.studentId,
        studentName:    stud.name    || 'Unknown',
        studentEmail:   stud.email   || '',
        rollNumber:     stud.rollNumber || '',
        startedAt:      a.startedAt,
        remainingSec:   remaining,
        remainingMin:   Math.ceil(remaining / 60),
        totalExtMin:    extMin,
        extensionCount: exts.length,
        isPaused:       a.isPaused || false,
        answeredCount:  (a.answers || []).filter(ans => ans.selectedOption != null).length,
      };
    }));

    res.json({ success: true, examTitle: exam.title, count: result.length, students: result });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.2/32.3/32.4/32.6/32.7/32.9/32.11/32.13 — Give Extra Time
// POST /api/time-extension/give
// ──────────────────────────────────────────────────────────────
router.post('/give', authAdmin, async (req, res) => {
  try {
    const { attemptId, examId, studentId, extraMinutes, reason, studentName } = req.body;

    if (!attemptId || !extraMinutes)
      return res.status(400).json({ error: 'attemptId and extraMinutes required' });

    const mins = parseInt(extraMinutes);
    if (isNaN(mins) || mins < 1 || mins > 120)
      return res.status(400).json({ error: 'extraMinutes must be between 1 and 120' });

    const Attempt       = require('../models/Attempt');
    const User          = require('../models/User');
    const TimeExtension = require('../models/TimeExtension');

    const attempt = await Attempt.findById(attemptId);
    if (!attempt || attempt.status !== 'active')
      return res.status(404).json({ error: 'Active attempt not found' });

    // 32.7 — Multiple extensions: calculate previous total
    const prevExts    = await TimeExtension.find({ attemptId, isUndone: false });
    const prevTotalMin= prevExts.reduce((s, e) => s + e.extraMinutes, 0);
    const newTotal    = prevTotalMin + mins;

    // 32.11 — Warn if exceeds 30 min
    const warning = newTotal > 30
      ? `⚠️ Warning: Total extensions for this student = ${newTotal} min (exceeds recommended 30 min)`
      : null;

    const admin     = await User.findById(req.user.id).select('name email');
    const adminName = admin?.name || admin?.email || 'Admin';

    // 32.6 — Save extension log
    const ext = await TimeExtension.create({
      examId:      examId || attempt.examId,
      attemptId,
      studentId:   studentId || attempt.studentId,
      adminId:     req.user.id,
      adminName,
      studentName: studentName || 'Student',
      extraMinutes: mins,
      reason:      reason || 'Other',
      isGlobal:    false,
    });

    // 32.4 / 32.5 / 32.13 — Real-time socket push to student
    const io = req.app.get('io');
    if (io) {
      const payload = {
        attemptId,
        extraMinutes:   mins,
        reason:         reason || 'Other',
        adminName,
        message:        `Admin has given you +${mins} minutes extra time`, // 32.13
        totalExtension: newTotal,
        extensionId:    ext._id,
        timestamp:      new Date(),
        isUndo:         false,
      };
      // Push to student's personal room + attempt room (32.4/32.5)
      io.to(`student:${attempt.studentId}`).emit('time:extend', payload);
      io.to(`attempt:${attemptId}`).emit('time:extend', payload);
      // Notify all admin monitors
      io.emit('admin:extension_given', {
        ...payload,
        studentName: studentName || 'Student',
        examId:      examId || attempt.examId,
      });
    }

    res.json({
      success:     true,
      message:     `+${mins} min given to ${studentName || 'student'}`,
      extensionId: ext._id,
      totalExtMin: newTotal,
      warning,       // 32.11
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.8 — Global Extend: All active students at once
// POST /api/time-extension/global
// ──────────────────────────────────────────────────────────────
router.post('/global', authAdmin, async (req, res) => {
  try {
    const { examId, extraMinutes, reason } = req.body;
    if (!examId || !extraMinutes)
      return res.status(400).json({ error: 'examId and extraMinutes required' });

    const mins = parseInt(extraMinutes);
    if (isNaN(mins) || mins < 1 || mins > 120)
      return res.status(400).json({ error: 'extraMinutes must be 1-120' });

    const Attempt       = require('../models/Attempt');
    const User          = require('../models/User');
    const TimeExtension = require('../models/TimeExtension');

    const admin     = await User.findById(req.user.id).select('name email');
    const adminName = admin?.name || admin?.email || 'Admin';

    const activeAttempts = await Attempt.find({ examId, status: 'active' }).lean();
    if (!activeAttempts.length)
      return res.status(404).json({ error: 'No active attempts found for this exam' });

    // Bulk create extension logs for all students (32.6)
    const bulkDocs = activeAttempts.map(a => ({
      examId,
      attemptId:   a._id,
      studentId:   a.studentId,
      adminId:     req.user.id,
      adminName,
      studentName: 'All Students (Global)',
      extraMinutes: mins,
      reason:      reason || 'Technical Issue',
      isGlobal:    true,
    }));
    await TimeExtension.insertMany(bulkDocs);

    // 32.4 — Emit to every active student
    const io = req.app.get('io');
    if (io) {
      for (const a of activeAttempts) {
        const payload = {
          attemptId:    a._id,
          extraMinutes: mins,
          reason:       reason || 'Technical Issue',
          adminName,
          message:      `Admin has extended exam time by +${mins} minutes for all students`,
          isGlobal:     true,
          timestamp:    new Date(),
        };
        io.to(`student:${a.studentId}`).emit('time:extend', payload);
        io.to(`attempt:${a._id}`).emit('time:extend', payload);
      }
      io.emit('admin:global_extension', {
        examId, extraMinutes: mins, reason,
        adminName, studentsAffected: activeAttempts.length,
      });
    }

    res.json({
      success:          true,
      message:          `+${mins} min given to all ${activeAttempts.length} active students`,
      studentsAffected: activeAttempts.length,
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.6 / 32.19 — Extension Log for an exam
// GET /api/time-extension/log/:examId
// ──────────────────────────────────────────────────────────────
router.get('/log/:examId', authAdmin, async (req, res) => {
  try {
    const TimeExtension = require('../models/TimeExtension');
    const logs = await TimeExtension.find({ examId: req.params.examId })
      .sort({ createdAt: -1 })
      .populate('studentId', 'name email')
      .populate('adminId', 'name email')
      .lean();
    res.json({ success: true, count: logs.length, logs });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.10 — Current time remaining for a specific student
// GET /api/time-extension/remaining/:attemptId
// ──────────────────────────────────────────────────────────────
router.get('/remaining/:attemptId', authAdmin, async (req, res) => {
  try {
    const Attempt       = require('../models/Attempt');
    const Exam          = require('../models/Exam');
    const TimeExtension = require('../models/TimeExtension');

    const attempt = await Attempt.findById(req.params.attemptId);
    if (!attempt) return res.status(404).json({ error: 'Attempt not found' });

    const exam         = await Exam.findById(attempt.examId);
    const baseDurSec   = (exam?.duration || 200) * 60;
    const exts         = await TimeExtension.find({ attemptId: req.params.attemptId, isUndone: false });
    const totalExtMin  = exts.reduce((s, e) => s + e.extraMinutes, 0);
    const totalDurSec  = baseDurSec + totalExtMin * 60;
    const elapsedSec   = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    const remainingSec = Math.max(0, totalDurSec - elapsedSec);

    res.json({
      success:        true,
      remainingSec,
      remainingMin:   Math.ceil(remainingSec / 60),
      totalExtMin,
      baseDurationMin: exam?.duration || 200,
      elapsedSec,
      extensionCount: exts.length,
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.12 — Undo Extension (within 5 minutes)
// DELETE /api/time-extension/:logId/undo
// ──────────────────────────────────────────────────────────────
router.delete('/:logId/undo', authAdmin, async (req, res) => {
  try {
    const TimeExtension = require('../models/TimeExtension');
    const ext = await TimeExtension.findById(req.params.logId);
    if (!ext) return res.status(404).json({ error: 'Extension log not found' });
    if (ext.isUndone) return res.status(400).json({ error: 'Already undone' });

    // 32.12 — 5 minute window check
    const minsElapsed = (Date.now() - new Date(ext.createdAt).getTime()) / 60000;
    if (minsElapsed > 5)
      return res.status(400).json({
        error: `Cannot undo — 5 minute window has passed (${minsElapsed.toFixed(1)} min ago)`
      });

    ext.isUndone = true;
    ext.undoneAt  = new Date();
    ext.undoneBy  = req.user.id;
    await ext.save();

    // Emit undo event to student (reverse the extension)
    const io = req.app.get('io');
    if (io) {
      const payload = {
        attemptId:    ext.attemptId,
        extraMinutes: -ext.extraMinutes,  // negative = reduce time back
        message:      `Admin has cancelled a +${ext.extraMinutes} min extension`,
        isUndo:       true,
        timestamp:    new Date(),
      };
      io.to(`student:${ext.studentId}`).emit('time:extend', payload);
      io.to(`attempt:${ext.attemptId}`).emit('time:extend', payload);
      io.emit('admin:extension_undone', { ...payload, logId: ext._id });
    }

    res.json({ success: true, message: `Extension of +${ext.extraMinutes} min has been undone`, undoneMinutes: ext.extraMinutes });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.14 — Download PDF Report of all extensions
// GET /api/time-extension/report/:examId
// ──────────────────────────────────────────────────────────────
router.get('/report/:examId', authAdmin, async (req, res) => {
  try {
    const TimeExtension = require('../models/TimeExtension');
    const Exam          = require('../models/Exam');
    const PDFDocument   = require('pdfkit');

    const exam = await Exam.findById(req.params.examId).select('title duration');
    const logs = await TimeExtension.find({ examId: req.params.examId })
      .populate('studentId', 'name email rollNumber')
      .populate('adminId', 'name email')
      .sort({ createdAt: 1 })
      .lean();

    const doc = new PDFDocument({ margin: 50 });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="TimeExtensions_${req.params.examId}.pdf"`);
    doc.pipe(res);

    // Title
    doc.fontSize(20).fillColor('#1B3A6B')
      .text('ProveRank — Time Extension Report', { align: 'center' });
    doc.fontSize(12).fillColor('#374151')
      .text(`Exam: ${exam?.title || req.params.examId}`, { align: 'center' });
    doc.text(`Generated: ${new Date().toLocaleString()}`, { align: 'center' });
    doc.moveDown(1.5);

    // Summary
    const active = logs.filter(l => !l.isUndone);
    const totalMin = active.reduce((s, l) => s + l.extraMinutes, 0);
    doc.fontSize(12).fillColor('#0F766E').text('Summary', { underline: true });
    doc.moveDown(0.3);
    doc.fontSize(11).fillColor('#1F2937')
      .text(`Total Extensions Given: ${logs.length}`)
      .text(`Active Extensions: ${active.length}`)
      .text(`Undone Extensions: ${logs.length - active.length}`)
      .text(`Total Extra Minutes Granted: ${totalMin} min`);
    doc.moveDown(1);

    // Log table
    doc.fontSize(12).fillColor('#0F766E').text('Extension Log', { underline: true });
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke('#D1D5DB');
    doc.moveDown(0.5);

    if (!logs.length) {
      doc.fontSize(11).fillColor('#6B7280').text('No extensions were given for this exam.');
    } else {
      logs.forEach((log, i) => {
        const sName   = log.studentId?.name  || log.studentName  || 'Unknown';
        const sEmail  = log.studentId?.email || '';
        const aName   = log.adminId?.name    || log.adminName    || 'Admin';
        const status  = log.isUndone ? ' [UNDONE]' : '';
        const time    = new Date(log.createdAt).toLocaleString();
        const color   = log.isUndone ? '#9CA3AF' : '#1F2937';

        doc.fontSize(10).fillColor(color)
          .text(`${i + 1}. ${sName} (${sEmail}) — +${log.extraMinutes} min — ${log.reason}${log.isGlobal ? ' [GLOBAL]' : ''}`)
          .text(`    By: ${aName} | At: ${time}${status}`);
        doc.moveDown(0.4);
      });
    }

    doc.moveDown();
    doc.fontSize(10).fillColor('#6B7280')
      .text(`Generated by ProveRank Admin | ${new Date().toLocaleString()}`, { align: 'center' });

    doc.end();
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
