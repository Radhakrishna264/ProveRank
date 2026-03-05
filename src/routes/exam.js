const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Exam = require('../models/Exam');
const User = require('../models/User');
const Attempt = require('../models/Attempt');
const { verifyToken, isAdmin } = require('../middleware/auth');

// CREATE EXAM
router.post('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.create({ ...req.body, createdBy: req.user.id });
    res.status(201).json({ message: 'Exam created', exam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// GET ALL EXAMS
router.get('/', verifyToken, async (req, res) => {
  try {
    const { batch, category, status } = req.query;
    const filter = {};
    if (batch) filter.batch = batch;
    if (category) filter.category = category;
    if (status) filter.status = status;
    const exams = await Exam.find(filter).populate('createdBy', 'name email');
    res.json({ exams });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// GET SINGLE EXAM
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    res.json({ exam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// UPDATE EXAM
router.put('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ message: 'Exam updated', exam });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// DELETE EXAM
router.delete('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    await Exam.findByIdAndDelete(req.params.id);
    res.json({ message: 'Exam deleted' });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});


// GET attempt by ID - Phase 4.1 Step 7+8
router.get('/attempt/:attemptId', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const obj = attempt.toObject();
    return res.status(200).json({
      ...obj,
      ipAddress: obj.ipAddress || null,
      startTime: obj.startedAt || null
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;

router.post('/:examId/start-attempt', verifyToken, async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.user.id;
    const examObjId = new mongoose.Types.ObjectId(examId);
    const studentObjId = new mongoose.Types.ObjectId(studentId);
    const exam = await Exam.findById(examObjId);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    const usedAttempts = await Attempt.countDocuments({ examId: examObjId, studentId: studentObjId });
    if (usedAttempts >= exam.maxAttempts) return res.status(403).json({ error: 'Attempt limit reached' });
    const student = await User.findById(studentObjId);
    if (!student) return res.status(404).json({ error: 'Student not found' });
    if (!student.termsAccepted) return res.status(403).json({ error: 'Terms not accepted' });
    const newAttempt = new Attempt({ examId: examObjId, studentId: studentObjId, startedAt: new Date(), status: 'active', ipAddress: req.headers['x-forwarded-for'] || req.connection.remoteAddress || 'unknown' });
    await newAttempt.save();
    res.status(200).json({ success: true, attemptId: newAttempt._id, message: 'Attempt started' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
