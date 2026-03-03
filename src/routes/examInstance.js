const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const ExamInstance = require('../models/ExamInstance');
const Exam = require('../models/Exam');
const Question = require('../models/Question');
const User = require('../models/User');
const { verifyToken, isAdmin } = require('../middleware/auth');

async function getAdminId(userId) {
  const user = await User.findById(userId).select('_id role');
  if (!user || !['admin', 'superadmin'].includes(user.role)) throw new Error('Unauthorized');
  return user._id;
}

// POST /api/exam-instances/create
router.post('/create', verifyToken, isAdmin, async (req, res) => {
  try {
    const adminId = await getAdminId(req.user.id);
    const { examId, setLabel, batchId, sectionTimers } = req.body;
    if (!examId) return res.status(400).json({ message: 'examId required' });

    const exam = await Exam.findById(examId).lean();
    if (!exam) return res.status(404).json({ message: 'Exam not found' });

    // questionSnapshot se IDs nikalo
    const snapshots = exam.questionSnapshot || [];
    if (!snapshots.length) {
      return res.status(400).json({ message: 'Exam has no questions. Add questions first.' });
    }

    // IDs extract karo (questionId ya direct _id)
    const qIds = snapshots.map(s => s.questionId || s).filter(Boolean);

    const questions = await Question.find(
      { _id: { $in: qIds } },
      '_id subject'
    ).lean();

    if (!questions.length) {
      return res.status(400).json({ message: 'Questions not found in DB.' });
    }

    const questionSnapshot = questions.map((q, idx) => ({
      questionId: q._id,
      subject: q.subject || 'General',
      order: idx + 1
    }));

    const defaultSectionTimers = [
      { sectionName: 'Physics', subject: 'Physics', durationMinutes: 60 },
      { sectionName: 'Chemistry', subject: 'Chemistry', durationMinutes: 60 },
      { sectionName: 'Biology', subject: 'Biology', durationMinutes: 80 }
    ];

    // Generate codes
    const ts = Date.now().toString(36).toUpperCase();
    const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
    const vCode = `PRV-${ts}-${rand}`;
    const instance = new ExamInstance({
      examId,
      versionCode: vCode,
      socketRoomId: `exam_room_${examId}_${vCode}`,
      setLabel: setLabel || 'Default',
      batchId: batchId || null,
      questionSnapshot,
      totalQuestions: questionSnapshot.length,
      sectionTimers: sectionTimers || defaultSectionTimers,
      createdBy: adminId
    });

    await instance.save();
    res.status(201).json({
      message: '✅ Exam Instance created successfully',
      instance: {
        _id: instance._id,
        versionCode: instance.versionCode,
        setLabel: instance.setLabel,
        totalQuestions: instance.totalQuestions,
        socketRoomId: instance.socketRoomId,
        isPublished: instance.isPublished,
        isLocked: instance.isLocked
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/exam-instances/:id/publish
router.put('/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const instance = await ExamInstance.findById(req.params.id);
    if (!instance) return res.status(404).json({ message: 'Instance not found' });
    if (instance.isLocked) {
      return res.status(400).json({ message: `Instance already locked. Reason: ${instance.lockReason}` });
    }
    instance.isPublished = true;
    instance.publishedAt = new Date();
    instance.isLocked = true;
    instance.lockedAt = new Date();
    instance.lockReason = 'published';
    await instance.save();
    const io = req.app.get('io');
    if (io) {
      io.to(instance.socketRoomId).emit('instance_published', {
        instanceId: instance._id,
        versionCode: instance.versionCode,
        message: 'Exam instance published and locked'
      });
    }
    res.json({
      message: '✅ Instance published & locked.',
      versionCode: instance.versionCode,
      socketRoomId: instance.socketRoomId,
      lockedAt: instance.lockedAt
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/exam-instances/exam/:examId
router.get('/exam/:examId', verifyToken, isAdmin, async (req, res) => {
  try {
    const instances = await ExamInstance.find({ examId: req.params.examId })
      .select('versionCode setLabel totalQuestions isPublished isLocked lockReason createdAt socketRoomId');
    res.json({ total: instances.length, instances });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/exam-instances/:id
router.get('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const instance = await ExamInstance.findById(req.params.id)
      .populate('examId', 'title duration')
      .populate('questionSnapshot.questionId', 'text subject difficulty type');
    if (!instance) return res.status(404).json({ message: 'Instance not found' });
    res.json(instance);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/exam-instances/:id/lock-attempt
router.put('/:id/lock-attempt', verifyToken, isAdmin, async (req, res) => {
  try {
    const instance = await ExamInstance.findById(req.params.id);
    if (!instance) return res.status(404).json({ message: 'Instance not found' });
    if (!instance.attemptStarted) {
      instance.attemptStarted = true;
      instance.firstAttemptAt = new Date();
    }
    if (!instance.isLocked) {
      instance.isLocked = true;
      instance.lockedAt = new Date();
      instance.lockReason = 'attempt_started';
    }
    await instance.save();
    res.json({ message: '🔒 Instance locked — student attempt started', instance });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/exam-instances/:id/lock-section
router.put('/:id/lock-section', verifyToken, isAdmin, async (req, res) => {
  try {
    const { sectionName } = req.body;
    if (!sectionName) return res.status(400).json({ message: 'sectionName required' });
    const instance = await ExamInstance.findById(req.params.id);
    if (!instance) return res.status(404).json({ message: 'Instance not found' });
    const section = instance.sectionTimers.find(s => s.sectionName === sectionName);
    if (!section) return res.status(404).json({ message: `Section '${sectionName}' not found` });
    section.isLocked = true;
    section.lockedAt = new Date();
    await instance.save();
    const io = req.app.get('io');
    if (io) {
      io.to(instance.socketRoomId).emit('section_locked', {
        sectionName,
        message: `Section '${sectionName}' is now locked.`
      });
    }
    res.json({ message: `🔒 Section '${sectionName}' locked`, lockedAt: section.lockedAt });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/exam-instances/:id/socket-room
router.get('/:id/socket-room', verifyToken, async (req, res) => {
  try {
    const instance = await ExamInstance.findById(req.params.id).select('socketRoomId versionCode examId');
    if (!instance) return res.status(404).json({ message: 'Instance not found' });
    res.json({ socketRoomId: instance.socketRoomId, versionCode: instance.versionCode });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/exam-instances/:id/watermark
router.get('/:id/watermark', verifyToken, async (req, res) => {
  try {
    const instance = await ExamInstance.findById(req.params.id).select('versionCode examId');
    if (!instance) return res.status(404).json({ message: 'Instance not found' });
    const user = await User.findById(req.user.id).select('name email rollNumber');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json({
      watermark: {
        studentName: user.name,
        studentEmail: user.email,
        rollNumber: user.rollNumber || 'N/A',
        versionCode: instance.versionCode,
        timestamp: new Date().toISOString(),
        displayText: `${user.name} | ${user.email} | ${instance.versionCode}`
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
// placeholder - already defined above
