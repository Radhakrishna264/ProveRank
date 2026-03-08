const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

// ─── Step 1: View Student Attempts API (with filters) ───────────────────────
router.get('/attempts', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Attempt = mongoose.model('Attempt');
    const { examId, studentId, status, page = 1, limit = 20 } = req.query;

    const filter = {};
    if (examId) filter.examId = new mongoose.Types.ObjectId(examId);
    if (studentId) filter.studentId = new mongoose.Types.ObjectId(studentId);
    if (status) filter.status = status;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const attempts = await Attempt.find(filter)
      .populate('studentId', 'name email')
      .populate('examId', 'title')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Attempt.countDocuments(filter);

    res.json({
      success: true,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
      attempts
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 2: View Cheating Logs API ─────────────────────────────────────────
router.get('/cheat-logs', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const CheatingLog = mongoose.model('AntiCheatLog');
    const { examId, studentId, type, page = 1, limit = 20 } = req.query;

    const filter = {};
    if (examId) filter.examId = new mongoose.Types.ObjectId(examId);
    if (studentId) filter.studentId = new mongoose.Types.ObjectId(studentId);
    if (type) filter.eventType = type;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const logs = await CheatingLog.find(filter)
      .populate('studentId', 'name email')
      .populate('examId', 'title')
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await CheatingLog.countDocuments(filter);

    res.json({ success: true, total, page: parseInt(page), logs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 3: View Webcam Snapshots API ──────────────────────────────────────
router.get('/snapshots', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const WebcamLog = mongoose.model('WebcamLog');
    const { examId, studentId, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (examId) filter.examId = new mongoose.Types.ObjectId(examId);
    if (studentId) filter.studentId = new mongoose.Types.ObjectId(studentId);

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const snapshots = await WebcamLog.find(filter)
      .populate('studentId', 'name email')
      .populate('examId', 'title')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await WebcamLog.countDocuments(filter);

    res.json({ success: true, total, snapshots });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 4: Audio Flags Review API (S57) ───────────────────────────────────
router.get('/audio-flags', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const AudioLog = mongoose.model('AudioLog');
    const { examId, studentId, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (examId) filter.examId = new mongoose.Types.ObjectId(examId);
    if (studentId) filter.studentId = new mongoose.Types.ObjectId(studentId);

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const audioFlags = await AudioLog.find(filter)
      .populate('studentId', 'name email')
      .populate('examId', 'title')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await AudioLog.countDocuments(filter);

    res.json({ success: true, total, audioFlags });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 5: Live Exam Control Panel (S83) ──────────────────────────────────
// GET: Live exam status
router.get('/exam-control/:examId', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Attempt = mongoose.model('Attempt');
    const { examId } = req.params;

    const liveStudents = await Attempt.find({
      examId: new mongoose.Types.ObjectId(examId),
      status: 'active'
    }).populate('studentId', 'name email');

    res.json({
      success: true,
      examId,
      liveCount: liveStudents.length,
      students: liveStudents
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST: Control action (pause/stop/eject/extend)
router.post('/exam-control/:examId/action', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Attempt = mongoose.model('Attempt');
    const Exam = mongoose.model('Exam');
    const { action, studentId, extraMinutes, reason } = req.body;
    const { examId } = req.params;

    // Get io from app
    const io = req.app.get('io');

    if (action === 'pause') {
      await Exam.findByIdAndUpdate(examId, { isPaused: true, pauseReason: reason || 'Admin paused exam' });
      if (io) io.to(`exam_${examId}`).emit('exam_paused', { reason: reason || 'Admin paused exam' });
      return res.json({ success: true, message: 'Exam paused & students notified' });
    }

    if (action === 'resume') {
      await Exam.findByIdAndUpdate(examId, { isPaused: false, pauseReason: null });
      if (io) io.to(`exam_${examId}`).emit('exam_resumed', { message: 'Exam resumed by admin' });
      return res.json({ success: true, message: 'Exam resumed' });
    }

    if (action === 'stop') {
      await Attempt.updateMany(
        { examId: new mongoose.Types.ObjectId(examId), status: 'active' },
        { status: 'submitted', submittedAt: new Date(), autoSubmitted: true, autoSubmitReason: 'Admin force stopped' }
      );
      if (io) io.to(`exam_${examId}`).emit('exam_force_stopped', { reason: reason || 'Exam stopped by admin' });
      return res.json({ success: true, message: 'All active attempts stopped' });
    }

    if (action === 'eject' && studentId) {
      await Attempt.findOneAndUpdate(
        { examId: new mongoose.Types.ObjectId(examId), studentId: new mongoose.Types.ObjectId(studentId), status: 'active' },
        { status: 'submitted', submittedAt: new Date(), autoSubmitted: true, autoSubmitReason: `Ejected by admin: ${reason || ''}` }
      );
      if (io) io.to(`student_${studentId}`).emit('student_ejected', { reason: reason || 'Removed by admin' });
      return res.json({ success: true, message: 'Student ejected from exam' });
    }

    res.status(400).json({ success: false, message: 'Invalid action' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 6: Per-Student Time Extension (M7) ────────────────────────────────
router.post('/time-extension', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Attempt = mongoose.model('Attempt');
    const { examId, studentId, extraMinutes, reason } = req.body;

    if (!examId || !studentId || !extraMinutes) {
      return res.status(400).json({ success: false, message: 'examId, studentId, extraMinutes required' });
    }

    const attempt = await Attempt.findOneAndUpdate(
      {
        examId: new mongoose.Types.ObjectId(examId),
        studentId: new mongoose.Types.ObjectId(studentId),
        status: 'active'
      },
      {
        $inc: { totalDurationSec: parseInt(extraMinutes) * 60 },
        $push: {
          timeExtensions: {
            addedMinutes: parseInt(extraMinutes),
            reason: reason || 'Admin granted extra time',
            addedAt: new Date()
          }
        }
      },
      { new: true }
    );

    if (!attempt) {
      return res.status(404).json({ success: false, message: 'Active attempt not found for this student' });
    }

    const io = req.app.get('io');
    if (io) {
      io.to(`student_${studentId}`).emit('time_extended', {
        extraMinutes: parseInt(extraMinutes),
        newTotalSec: attempt.totalDurationSec,
        reason: reason || 'Admin granted extra time'
      });
    }

    res.json({
      success: true,
      message: `+${extraMinutes} min added for student`,
      newTotalDurationSec: attempt.totalDurationSec
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 7: Admin Notification Center (S86) ─────────────────────────────────
router.get('/notifications', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const AdminNotification = mongoose.model('AdminNotification');
    const { read, page = 1, limit = 30 } = req.query;
    const filter = {};
    if (read !== undefined) filter.isRead = read === 'true';

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const notifications = await AdminNotification.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const unreadCount = await AdminNotification.countDocuments({ isRead: false });

    res.json({ success: true, unreadCount, notifications });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/notifications/:id/read', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const AdminNotification = mongoose.model('AdminNotification');
    await AdminNotification.findByIdAndUpdate(req.params.id, { isRead: true, readAt: new Date() });
    res.json({ success: true, message: 'Notification marked as read' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/notifications/mark-all-read', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const AdminNotification = mongoose.model('AdminNotification');
    await AdminNotification.updateMany({ isRead: false }, { isRead: true, readAt: new Date() });
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 8: SuperAdmin Permission Control API (S72) ─────────────────────────
router.get('/permissions', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('../models/User');
    const admins = await User.find({ role: { $in: ['admin', 'moderator'] } })
      .select('name email role permissions isActive');
    res.json({ success: true, admins });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/permissions/:adminId', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('../models/User');
    const { permissions, isActive } = req.body;
    const updateData = {};
    if (permissions !== undefined) updateData.permissions = permissions;
    if (isActive !== undefined) updateData.isActive = isActive;

    const admin = await User.findByIdAndUpdate(req.params.adminId, updateData, { new: true })
      .select('name email role permissions isActive');

    if (!admin) return res.status(404).json({ success: false, message: 'Admin not found' });

    res.json({ success: true, message: 'Permissions updated', admin });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 9: Admin Activity Logs API (S38) ────────────────────────────────────
router.get('/admin-logs', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const AdminLog = mongoose.model('ActivityLog');
    const { adminId, action, page = 1, limit = 20 } = req.query;

    const filter = {};
    if (adminId) filter.adminId = new mongoose.Types.ObjectId(adminId);
    if (action) filter.action = { $regex: action, $options: 'i' };

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const logs = await AdminLog.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await AdminLog.countDocuments(filter);

    res.json({ success: true, total, page: parseInt(page), logs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 10: Platform Activity Audit Trail API (S93) ────────────────────────
router.get('/audit-trail', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const AuditLog = mongoose.model('AuditLog');
    const { userId, role, action, from, to, page = 1, limit = 20 } = req.query;

    const filter = {};
    if (userId) filter.userId = new mongoose.Types.ObjectId(userId);
    if (role) filter.userRole = role;
    if (action) filter.action = { $regex: action, $options: 'i' };
    if (from || to) {
      filter.createdAt = {};
      if (from) filter.createdAt.$gte = new Date(from);
      if (to) filter.createdAt.$lte = new Date(to);
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const logs = await AuditLog.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await AuditLog.countDocuments(filter);

    res.json({ success: true, total, page: parseInt(page), logs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Step 11: Login Activity Monitor API (S48) ────────────────────────────────
router.get('/login-activity', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('../models/User');
    const { studentId, suspicious, page = 1, limit = 20 } = req.query;

    const filter = { role: 'student' };
    if (studentId) filter._id = new mongoose.Types.ObjectId(studentId);

    const skip = (parseInt(page) - 1) * parseInt(limit);

    let query = User.find(filter)
      .select('name email loginHistory isBanned')
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const users = await query;

    // suspicious = multiple cities ya diff IPs in 1 hour
    const result = users.map(u => {
      const history = u.loginHistory || [];
      const recentLogins = history.slice(-10);
      const cities = [...new Set(recentLogins.map(l => l.city).filter(Boolean))];
      const isSuspicious = cities.length > 2;
      return {
        _id: u._id,
        name: u.name,
        email: u.email,
        isBanned: u.isBanned,
        loginCount: history.length,
        recentLogins,
        isSuspicious
      };
    });

    const filteredResult = suspicious === 'true' ? result.filter(r => r.isSuspicious) : result;

    res.json({ success: true, total: filteredResult.length, students: filteredResult });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
