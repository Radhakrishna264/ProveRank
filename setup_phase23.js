const fs = require('fs');
const path = require('path');

const files = {};

// ─────────────────────────────────────────
// FILE 1: src/routes/upload.js
// ─────────────────────────────────────────
files['src/routes/upload.js'] = `
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const {
  uploadExcelQuestions,
  uploadExcelStudents,
  uploadPDFQuestions,
  copyPasteQuestions
} = require('../controllers/uploadController');

// Multer config
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads/';
    if (!require('fs').existsSync(dir)) require('fs').mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  const allowed = ['.xlsx', '.xls', '.pdf'];
  if (allowed.includes(ext)) cb(null, true);
  else cb(new Error('Only .xlsx, .xls, .pdf files allowed'), false);
};

const upload = multer({ storage, fileFilter, limits: { fileSize: 10 * 1024 * 1024 } });

// STEP 1+2+3+4+5: Excel Questions Upload
router.post('/excel/questions', verifyToken, isSuperAdmin, upload.single('file'), uploadExcelQuestions);

// STEP 6: Excel Students Bulk Import (S8)
router.post('/excel/students', verifyToken, isSuperAdmin, upload.single('file'), uploadExcelStudents);

// STEP 7+8+9+10: PDF Question Parser
router.post('/pdf/questions', verifyToken, isSuperAdmin, upload.single('file'), uploadPDFQuestions);

// STEP 11+12+13+14: Copy-Paste System
router.post('/copypaste/questions', verifyToken, isSuperAdmin, copyPasteQuestions);

module.exports = router;
`;

// ─────────────────────────────────────────
// FILE 2: src/controllers/uploadController.js
// ─────────────────────────────────────────
files['src/controllers/uploadController.js'] = `
const XLSX = require('xlsx');
const pdfParse = require('pdf-parse');
const fs = require('fs');
const Question = require('../models/Question');
const User = require('../models/User');
const bcrypt = require('bcrypt');

// ══════════════════════════════════════════
// STEP 1-5: EXCEL QUESTION UPLOAD
// ══════════════════════════════════════════
exports.uploadExcelQuestions = async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'File required' });

  const errors = [];
  const inserted = [];

  try {
    // STEP 2: Parse Excel
    const workbook = XLSX.readFile(req.file.path);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet);

    if (rows.length === 0) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ success: false, message: 'Excel file empty hai' });
    }

    // STEP 3+4: Parse + Validate each row
    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const rowNum = i + 2; // Excel row number

      // Required fields check
      if (!row.text && !row.question) {
        errors.push({ row: rowNum, error: 'Question text missing' });
        continue;
      }
      if (!row.correct && row.correct !== 0) {
        errors.push({ row: rowNum, error: 'Correct answer missing' });
        continue;
      }
      if (!row.subject) {
        errors.push({ row: rowNum, error: 'Subject missing' });
        continue;
      }

      // Options build karo
      const options = [];
      ['optionA','optionB','optionC','optionD','option1','option2','option3','option4'].forEach(k => {
        if (row[k]) options.push(String(row[k]));
      });

      const type = row.type || 'SCQ';
      if (type === 'Integer' && options.length === 0) {
        options.push(String(row.correct));
      }

      if (type !== 'Integer' && options.length < 2) {
        errors.push({ row: rowNum, error: 'At least 2 options required' });
        continue;
      }

      // Correct answer index
      let correctArr = [];
      const correctVal = String(row.correct).trim();
      if (correctVal.includes(',')) {
        correctArr = correctVal.split(',').map(v => parseInt(v.trim())).filter(v => !isNaN(v));
      } else if (!isNaN(parseInt(correctVal))) {
        correctArr = [parseInt(correctVal)];
      } else {
        // A/B/C/D format
        const map = { A:0, B:1, C:2, D:3, a:0, b:1, c:2, d:3 };
        if (map[correctVal] !== undefined) correctArr = [map[correctVal]];
        else { errors.push({ row: rowNum, error: 'Invalid correct answer format' }); continue; }
      }

      // Duplicate check
      const existing = await Question.findOne({ text: String(row.text || row.question).trim() });
      if (existing) {
        errors.push({ row: rowNum, error: 'Duplicate question — already exists', question: String(row.text || row.question).substring(0, 50) });
        continue;
      }

      // STEP 5: Build question object
      const validTypes = ['SCQ','MSQ','Integer','Assertion','Other'];
      const qData = {
        text: String(row.text || row.question).trim(),
        hindiText: row.hindiText || row.hindi || '',
        options,
        correct: correctArr,
        subject: String(row.subject).trim(),
        chapter: String(row.chapter || '').trim(),
        topic: String(row.topic || '').trim(),
        difficulty: ['Easy','Medium','Hard'].includes(row.difficulty) ? row.difficulty : 'Untagged',
        type: validTypes.includes(type) ? type : 'SCQ',
        explanation: row.explanation || '',
        tags: row.tags ? String(row.tags).split(',').map(t => t.trim()) : [],
        createdBy: req.user.id,
        usageCount: 0,
        version: 1,
        versionHistory: [],
        isActive: true
      };

      inserted.push(qData);
    }

    // Bulk insert
    let savedCount = 0;
    if (inserted.length > 0) {
      const saved = await Question.insertMany(inserted, { ordered: false });
      savedCount = saved.length;
    }

    // Cleanup uploaded file
    fs.unlinkSync(req.file.path);

    // STEP 7: Error report
    return res.json({
      success: true,
      message: \`Excel upload complete!\`,
      inserted: savedCount,
      errors: errors.length,
      errorDetails: errors,
      total: rows.length
    });

  } catch (err) {
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ══════════════════════════════════════════
// STEP 6: EXCEL STUDENT BULK IMPORT (S8)
// ══════════════════════════════════════════
exports.uploadExcelStudents = async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'File required' });

  const errors = [];
  const inserted = [];

  try {
    const workbook = XLSX.readFile(req.file.path);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet);

    if (rows.length === 0) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ success: false, message: 'Excel file empty hai' });
    }

    const defaultPassword = await bcrypt.hash('ProveRank@123', 12);

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const rowNum = i + 2;

      if (!row.name && !row.Name) { errors.push({ row: rowNum, error: 'Name missing' }); continue; }
      if (!row.email && !row.Email) { errors.push({ row: rowNum, error: 'Email missing' }); continue; }

      const email = String(row.email || row.Email).trim().toLowerCase();

      // Email already exists check
      const existing = await User.findOne({ email });
      if (existing) { errors.push({ row: rowNum, error: 'Email already registered', email }); continue; }

      inserted.push({
        name: String(row.name || row.Name).trim(),
        email,
        phone: String(row.phone || row.Phone || '').trim(),
        password: defaultPassword,
        role: 'student',
        group: row.group || row.batch || 'General',
        verified: true,
        isActive: true
      });
    }

    let savedCount = 0;
    if (inserted.length > 0) {
      const saved = await User.insertMany(inserted, { ordered: false });
      savedCount = saved.length;
    }

    fs.unlinkSync(req.file.path);

    return res.json({
      success: true,
      message: \`Student import complete! Default password: ProveRank@123\`,
      inserted: savedCount,
      errors: errors.length,
      errorDetails: errors,
      total: rows.length
    });

  } catch (err) {
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ══════════════════════════════════════════
// STEP 7-10: PDF QUESTION PARSER
// ══════════════════════════════════════════
exports.uploadPDFQuestions = async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'PDF file required' });

  try {
    // STEP 8: Extract text
    const dataBuffer = fs.readFileSync(req.file.path);
    const pdfData = await pdfParse(dataBuffer);
    const text = pdfData.text;

    if (!text || text.trim().length < 10) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ success: false, message: 'PDF se text extract nahi hua — scanned image ho sakta hai' });
    }

    // STEP 9: Pattern detection — question blocks split
    const lines = text.split('\\n').map(l => l.trim()).filter(l => l.length > 0);
    const questions = [];
    const errors = [];

    let currentQ = null;
    let questionNum = 0;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // Question start detect: "1." or "Q1." or "Q.1" or "(1)"
      const qMatch = line.match(/^(?:Q\\.?\\s*)?([0-9]+)[.)\\]:]\\s*(.+)/i);
      if (qMatch) {
        if (currentQ && currentQ.options.length >= 2) questions.push(currentQ);
        else if (currentQ) errors.push({ question: questionNum, error: 'Options kam hain — skip' });

        questionNum++;
        currentQ = {
          num: parseInt(qMatch[1]),
          text: qMatch[2].trim(),
          options: [],
          correct: [],
          subject: req.body.subject || 'General',
          chapter: req.body.chapter || '',
          topic: req.body.topic || '',
          difficulty: req.body.difficulty || 'Untagged',
          type: 'SCQ'
        };
        continue;
      }

      // Option detect: (A) or (a) or A. or a)
      const optMatch = line.match(/^[\\(\\[]?([A-Da-d])[)\\].:]\\s*(.+)/);
      if (optMatch && currentQ) {
        currentQ.options.push(optMatch[2].trim());
        continue;
      }

      // Answer key detect: "Ans: A" or "Answer: 1" or "Key: B"
      const ansMatch = line.match(/^(?:ans(?:wer)?|key|sol(?:ution)?)[.:\\s]+([A-D1-4a-d])/i);
      if (ansMatch && currentQ) {
        const ansVal = ansMatch[1].toUpperCase();
        const map = { A:0, B:1, C:2, D:3, '1':0, '2':1, '3':2, '4':3 };
        if (map[ansVal] !== undefined) currentQ.correct = [map[ansVal]];
        continue;
      }

      // Multi-line question text
      if (currentQ && currentQ.options.length === 0 && line.length > 3) {
        currentQ.text += ' ' + line;
      }
    }

    // Last question
    if (currentQ && currentQ.options.length >= 2) questions.push(currentQ);

    // STEP 10+11: Answer key sync + store metadata
    const pdfMeta = {
      filename: req.file.originalname,
      pages: pdfData.numpages,
      parsedAt: new Date(),
      questionsFound: questions.length,
      uploadedBy: req.user.id
    };

    // STEP 12: Save to DB
    const toInsert = questions.map(q => ({
      text: q.text,
      options: q.options,
      correct: q.correct.length > 0 ? q.correct : [0],
      subject: q.subject,
      chapter: q.chapter,
      topic: q.topic,
      difficulty: q.difficulty,
      type: q.type,
      tags: ['pdf-import'],
      sourceExam: req.body.examTitle || '',
      createdBy: req.user.id,
      usageCount: 0,
      version: 1,
      versionHistory: [],
      isActive: true
    }));

    let savedCount = 0;
    if (toInsert.length > 0) {
      const saved = await Question.insertMany(toInsert, { ordered: false });
      savedCount = saved.length;
    }

    fs.unlinkSync(req.file.path);

    // STEP 13: Error log + preview
    return res.json({
      success: true,
      message: 'PDF parsing complete!',
      pdfMeta,
      inserted: savedCount,
      errors: errors.length,
      errorDetails: errors,
      preview: questions.slice(0, 3).map(q => ({
        num: q.num,
        text: q.text.substring(0, 80) + '...',
        optionsCount: q.options.length,
        hasAnswer: q.correct.length > 0
      }))
    });

  } catch (err) {
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ══════════════════════════════════════════
// STEP 14-20: COPY-PASTE QUESTION SYSTEM
// ══════════════════════════════════════════
exports.copyPasteQuestions = async (req, res) => {
  const { questionsText, answerKeyText, subject, chapter, topic, difficulty, preview } = req.body;

  if (!questionsText) return res.status(400).json({ success: false, message: 'Questions text required' });

  try {
    // STEP 14+15: Parse question text
    const lines = questionsText.split('\\n').map(l => l.trim()).filter(l => l.length > 0);
    const questions = [];
    const errors = [];
    let currentQ = null;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      const qMatch = line.match(/^(?:Q\\.?\\s*)?([0-9]+)[.)\\]:]\\s*(.+)/i);
      if (qMatch) {
        if (currentQ && currentQ.options.length >= 2) questions.push(currentQ);
        currentQ = {
          num: parseInt(qMatch[1]),
          text: qMatch[2].trim(),
          options: [],
          correct: []
        };
        continue;
      }

      const optMatch = line.match(/^[\\(\\[]?([A-Da-d])[)\\].:]\\s*(.+)/);
      if (optMatch && currentQ) {
        currentQ.options.push(optMatch[2].trim());
        continue;
      }

      if (currentQ && currentQ.options.length === 0) {
        currentQ.text += ' ' + line;
      }
    }
    if (currentQ && currentQ.options.length >= 2) questions.push(currentQ);

    // STEP 16+17: Answer key parse + sync
    if (answerKeyText) {
      const ansLines = answerKeyText.split('\\n').map(l => l.trim()).filter(l => l.length > 0);
      const ansMap = {};

      ansLines.forEach(line => {
        // Format: "1-A" or "1. A" or "1) B" or "1:C"
        const match = line.match(/([0-9]+)[-.):\\s]+([A-D1-4a-d])/i);
        if (match) {
          const num = parseInt(match[1]);
          const ans = match[2].toUpperCase();
          const map = { A:0, B:1, C:2, D:3, '1':0, '2':1, '3':2, '4':3 };
          if (map[ans] !== undefined) ansMap[num] = [map[ans]];
        }
      });

      // Sync answers with questions
      questions.forEach(q => {
        if (ansMap[q.num]) q.correct = ansMap[q.num];
      });
    }

    // STEP 18: Preview mode — dont save, just return
    if (preview === true || preview === 'true') {
      return res.json({
        success: true,
        message: 'Preview mode — save karne ke liye preview:false bhejo',
        questionsFound: questions.length,
        errors: errors.length,
        preview: questions.map(q => ({
          num: q.num,
          text: q.text.substring(0, 100),
          optionsCount: q.options.length,
          options: q.options,
          correct: q.correct,
          hasAnswer: q.correct.length > 0
        }))
      });
    }

    // STEP 19+20: Validate + Save
    const validTypes = ['SCQ','MSQ','Integer','Assertion','Other'];
    const toInsert = questions
      .filter(q => q.options.length >= 2)
      .map(q => ({
        text: q.text,
        options: q.options,
        correct: q.correct.length > 0 ? q.correct : [0],
        subject: subject || 'General',
        chapter: chapter || '',
        topic: topic || '',
        difficulty: ['Easy','Medium','Hard'].includes(difficulty) ? difficulty : 'Untagged',
        type: 'SCQ',
        tags: ['copy-paste'],
        createdBy: req.user.id,
        usageCount: 0,
        version: 1,
        versionHistory: [],
        isActive: true
      }));

    let savedCount = 0;
    if (toInsert.length > 0) {
      const saved = await Question.insertMany(toInsert, { ordered: false });
      savedCount = saved.length;
    }

    const skipped = questions.length - toInsert.length;

    return res.json({
      success: true,
      message: 'Copy-paste questions saved!',
      inserted: savedCount,
      skipped,
      errors: errors.length,
      total: questions.length
    });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};
`;

// Write all files
Object.entries(files).forEach(([filePath, content]) => {
  const fullPath = require('path').join('/home/runner/workspace', filePath);
  const dir = require('path').dirname(fullPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(fullPath, content.trim());
  console.log('✅ Created: ' + filePath);
});

console.log('\n✅ Phase 2.3 — All files created!');
console.log('Ab route register karna baaki hai src/index.js mein');
