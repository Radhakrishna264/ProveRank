const express = require('express');
const router = express.Router();
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const {
  generateCertificate,
  generateOMRSheet,
  generateResultReport
} = require('../utils/pdfGenerator');
const path = require('path');

// POST /api/pdf/certificate
router.post('/certificate', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { studentName, score, date, uniqueId } = req.body;
    if (!studentName || !score || !date || !uniqueId) {
      return res.status(400).json({ message: 'studentName, score, date, uniqueId required' });
    }
    const filePath = await generateCertificate({ studentName, score, date, uniqueId });
    res.download(filePath);
  } catch (err) {
    console.error('Certificate Error:', err);
    res.status(500).json({ message: 'Certificate generation failed', error: err.message });
  }
});

// POST /api/pdf/omr
router.post('/omr', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { studentName, examTitle, totalQuestions, uniqueId } = req.body;
    if (!studentName || !examTitle || !uniqueId) {
      return res.status(400).json({ message: 'studentName, examTitle, uniqueId required' });
    }
    const filePath = await generateOMRSheet({ studentName, examTitle, totalQuestions, uniqueId });
    res.download(filePath);
  } catch (err) {
    console.error('OMR Error:', err);
    res.status(500).json({ message: 'OMR generation failed', error: err.message });
  }
});

// POST /api/pdf/result
router.post('/result', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { studentName, examTitle, score, totalMarks, correct, wrong, skipped, subject_scores, rank, uniqueId } = req.body;
    if (!studentName || !examTitle || !uniqueId) {
      return res.status(400).json({ message: 'studentName, examTitle, uniqueId required' });
    }
    const filePath = await generateResultReport({
      studentName, examTitle, score, totalMarks,
      correct, wrong, skipped, subject_scores, rank, uniqueId
    });
    res.download(filePath);
  } catch (err) {
    console.error('Result Report Error:', err);
    res.status(500).json({ message: 'Result report generation failed', error: err.message });
  }
});

module.exports = router;
