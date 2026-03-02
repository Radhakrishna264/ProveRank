const express = require('express');
const router = express.Router();
const Exam = require('../models/Exam');
const { verifyToken, isAdmin } = require('../middleware/auth');

// EXAM SCHEDULING - Auto status update
router.post('/schedule/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const { startTime, endTime } = req.body;
    const exam = await Exam.findByIdAndUpdate(
      req.params.id,
      { schedule: { startTime, endTime }, status: 'scheduled' },
      { new: true }
    );
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    res.json({ message: 'Exam scheduled', exam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// AUTO STATUS CHECK
router.get('/check-status', verifyToken, isAdmin, async (req, res) => {
  try {
    const now = new Date();
    await Exam.updateMany(
      { 'schedule.startTime': { $lte: now }, status: 'scheduled' },
      { status: 'live' }
    );
    await Exam.updateMany(
      { 'schedule.endTime': { $lte: now }, status: 'live' },
      { status: 'ended' }
    );
    res.json({ message: 'Exam statuses updated', time: now });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// SET EXAM PASSWORD
router.post('/set-password/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const { password } = req.body;
    const exam = await Exam.findByIdAndUpdate(
      req.params.id,
      { password },
      { new: true }
    );
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    res.json({ message: 'Password set successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// VERIFY EXAM PASSWORD
router.post('/verify-password/:id', verifyToken, async (req, res) => {
  try {
    const { password } = req.body;
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    if (exam.password && exam.password !== password) {
      return res.status(403).json({ message: 'Wrong exam password' });
    }
    res.json({ message: 'Password correct', verified: true });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// CLONE EXAM
router.post('/clone/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const original = await Exam.findById(req.params.id);
    if (!original) return res.status(404).json({ message: 'Exam not found' });
    const cloned = original.toObject();
    delete cloned._id;
    delete cloned.createdAt;
    delete cloned.updatedAt;
    cloned.title = cloned.title + ' (Copy)';
    cloned.status = 'draft';
    cloned.createdBy = req.user.id;
    const newExam = await Exam.create(cloned);
    res.status(201).json({ message: 'Exam cloned', exam: newExam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

module.exports = router;
