const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt');
const { verifyToken, isSuperAdmin, isAdmin } = require('../middleware/auth');
const Question = require('../models/Question');
const User = require('../models/User');
const ExcelUploadLog = require('../models/ExcelUpload');
const { parseQuestionExcel, parseStudentExcel } = require('../utils/excelParser');

// Multer storage setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const fileFilter = (req, file, cb) => {
  const allowed = ['.xlsx', '.xls'];
  const ext = path.extname(file.originalname).toLowerCase();
  if (allowed.includes(ext)) cb(null, true);
  else cb(new Error('Only Excel files allowed (.xlsx, .xls)'), false);
};

const upload = multer({ storage, fileFilter, limits: { fileSize: 10 * 1024 * 1024 } });

// Step 2,3,4,5 — Excel Question Upload + Parse + Validate + Bulk Insert
router.post('/questions', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'Excel file required' });

    const { questions, errors } = parseQuestionExcel(req.file.path);

    let successCount = 0;
    const insertErrors = [...errors];

    for (const q of questions) {
      try {
        // Duplicate check (S18)
        const existing = await Question.findOne({ text: q.text });
        if (existing) {
          insertErrors.push({ row: '-', message: `Duplicate: "${q.text.substring(0, 40)}..."` });
          continue;
        }
        await Question.create({
          ...q,
          approvalStatus: 'approved',
          createdBy: req.user.id
        });
        successCount++;
      } catch (err) {
        insertErrors.push({ row: '-', message: err.message });
      }
    }

    // Save upload log
    await ExcelUploadLog.create({
      uploadedBy: req.user.id,
      type: 'questions',
      totalRows: questions.length + errors.length,
      successCount,
      errorCount: insertErrors.length,
      errors: insertErrors
    });

    // Cleanup uploaded file
    fs.unlinkSync(req.file.path);

    res.json({
      success: true,
      message: `Upload complete`,
      successCount,
      errorCount: insertErrors.length,
      errors: insertErrors
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Step 6 — Bulk Student Import via Excel (S8)
router.post('/students', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'Excel file required' });

    const { students, errors } = parseStudentExcel(req.file.path);

    let successCount = 0;
    const insertErrors = [...errors];

    for (const s of students) {
      try {
        const existing = await User.findOne({ email: s.email });
        if (existing) {
          insertErrors.push({ row: '-', message: `Duplicate email: ${s.email}` });
          continue;
        }
        const hashedPassword = await bcrypt.hash('ProveRank@123', 12);
        await User.create({
          name: s.name,
          email: s.email,
          phone: s.phone,
          password: hashedPassword,
          role: 'student',
          group: s.group,
          verified: true,
          isActive: true
        });
        successCount++;
      } catch (err) {
        insertErrors.push({ row: '-', message: err.message });
      }
    }

    await ExcelUploadLog.create({
      uploadedBy: req.user.id,
      type: 'students',
      totalRows: students.length + errors.length,
      successCount,
      errorCount: insertErrors.length,
      errors: insertErrors
    });

    fs.unlinkSync(req.file.path);

    res.json({
      success: true,
      message: `Student import complete`,
      successCount,
      errorCount: insertErrors.length,
      errors: insertErrors,
      defaultPassword: 'ProveRank@123'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Step 7 — Error Report — upload logs fetch karo
router.get('/logs', verifyToken, isAdmin, async (req, res) => {
  try {
    const logs = await ExcelUploadLog.find()
      .populate('uploadedBy', 'name email')
      .sort({ uploadedAt: -1 })
      .limit(20);
    res.json({ success: true, logs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
