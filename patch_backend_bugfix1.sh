#!/bin/bash
set -e
echo "=================================================="
echo "ProveRank Backend Patch — Bug fixes (resultTime + template auth)"
echo "=================================================="
cd ~/workspace || { echo "ERROR: ~/workspace not found"; exit 1; }
mkdir -p .backup_bugfix1_$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=$(ls -d .backup_bugfix1_* | tail -1)
cp "src/models/Exam.js" "$BACKUP_DIR/$(basename src/models/Exam.js).bak" 2>/dev/null || true
cp "src/routes/contentForge.js" "$BACKUP_DIR/$(basename src/routes/contentForge.js).bak" 2>/dev/null || true
echo "Backup: $BACKUP_DIR"
mkdir -p $(dirname "src/models/Exam.js")
cat > "src/models/Exam.js" << 'BUGFIX_EOF'
const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  title:        { type: String, required: true, trim: true },
  subject:      { type: String, default: 'NEET' },
  duration:     { type: Number, required: true },
  totalMarks:   { type: Number, default: 720 },
  questions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }], // QsBank Integration

  sections: [{
    name:          String,
    subject:       String,
    questionCount: Number,
    timeLimit:     Number,
    marks:         Number,
    fromQNo:       Number, // F19B.5.21 / F20B.5.21 / F21B.8.21 — subject Q-no range start
    toQNo:         Number  // F19B.5.21 / F20B.5.21 / F21B.8.21 — subject Q-no range end
  }],

  markingScheme: {
    correct:     { type: Number, default: 4 },
    incorrect:   { type: Number, default: -1 },
    unattempted: { type: Number, default: 0 },
    msqMode:     { type: String, enum: ['ALL_OR_NOTHING', 'PARTIAL_NEGATIVE'], default: 'ALL_OR_NOTHING' }
  },

  password:   { type: String, default: '' },

  schedule: {
    startTime:  Date,
    endTime:    Date,
    resultTime: Date  // when result/scorecard becomes visible to students
  },

  audioMonitoringEnabled: { type: Boolean, default: false },
  status: { type: String, enum: ['draft', 'scheduled', 'live', 'ended'], default: 'draft' },

  batch:    { type: String, default: '' },

  // F19B.6.8 / F20B.6.8 / F21B.9.7 — Multi-batch assign toggle (additional batch IDs besides primary `batch`)
  multiBatch: [{ type: String, default: [] }],

  // F19B.6 / F20B.6 / F21B.9 — Assignment Type selector
  assignmentType: { type: String, enum: ['batch', 'series', 'mini_test', 'individual'], default: 'individual' },

  // F19B.6.2/6.3 / F20B.6.2/6.3 / F21B.9.2/9.3 — Test Series / Mini Test Series label (grouping, also used for Step-8 "exam series/group")
  seriesName: { type: String, default: '' },

  category: { type: String, enum: ['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test', 'Mini Test'], default: 'Full Mock' },

  whitelist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  watermark:          { type: Boolean, default: true },
  customInstructions: { type: String, default: '' },

  reviewWindow: {
    enabled:         { type: Boolean, default: false },
    durationMinutes: { type: Number, default: 0 },
  fullscreenForce: { type: Boolean, default: false },
  fullscreenWarnings: { type: Number, default: 0 }
  },

  template:   { type: String, default: '' },
  difficulty: { type: String, default: 'Mixed' },
  type:       { type: String, default: 'NEET' },

  waitingRoomEnabled: { type: Boolean, default: false },
  waitingRoomMinutes: { type: Number, default: 10 },

  maxAttempts:    { type: Number, default: 1 },
  reattemptCount: { type: String, enum: ['best', 'last'], default: 'last' },
  // F19B.5.16 / F20B.5.16 / F21B.8.16 — Unlimited attempt option (maxAttempts auto-set to a large number when true)
  unlimitedAttempts: { type: Boolean, default: false },
  questionSnapshot:  { type: Array, default: [] },
  snapshotLocked:    { type: Boolean, default: false },
  snapshotLockedAt:  { type: Date, default: null },

  whitelistEnabled:    { type: Boolean, default: false },
  whitelistedStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  whitelistedGroups:   [{ type: String }],

  // F19B.5.5 / F20B.5.5 / F21B.8.5 — Subject wise Qs count input
  subjectWiseCount: [{ subject: String, count: Number }],
  // F19B.5.4 / F20B.5.4 / F21B.8.4 — Total Questions requested (auto-select N out of M parsed)
  totalQuestionsRequested: { type: Number, default: 0 },

  // F19B.8.1 / F20B.8.1 / F21B.11.1 — Scheduled auto-publish
  scheduledPublish: {
    enabled:   { type: Boolean, default: false },
    publishAt: { type: Date, default: null }
  },
  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle
  notifyStudents: { type: Boolean, default: false },
  // F19B.8.4 / F20B.8.4 / F21B.11.4 — Save as Template
  isTemplate: { type: Boolean, default: false },

  // F19B.7 / F20B / F21B — source tracking (which method created this exam + parse stats)
  sourceMeta: {
    sourceType:     { type: String, enum: ['paste', 'excel', 'pdf', 'manual', ''], default: '' },
    fileName:        { type: String, default: '' },
    uploadedAt:      { type: Date, default: null },
    pageCount:       { type: Number, default: 0 },
    totalParsed:     { type: Number, default: 0 },
    totalErrors:     { type: Number, default: 0 },
    totalDuplicates: { type: Number, default: 0 }
  },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }

}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);

BUGFIX_EOF
echo "  -> wrote src/models/Exam.js"
mkdir -p $(dirname "src/routes/contentForge.js")
cat > "src/routes/contentForge.js" << 'BUGFIX_EOF'
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { verifyToken, isAdmin } = require('../middleware/auth');

const Question = require('../models/Question');
const Exam = require('../models/Exam');
const ContentForgeImportLog = require('../models/ContentForgeImportLog'); // F20.15 import history

const { parseQuestionExcel, parseQuestionCSVString, generateTemplateBuffer } = require('../utils/excelParser');
const { buildQuestionsFromPDFs } = require('../utils/pdfQuestionParser');
const { createExamFromQuestions } = require('../utils/examBuilder');

// ══════════════════════════════════════════════════════════════
// Multer setup — same convention as excelUpload.js (uploads/ dir, 10MB)
// ══════════════════════════════════════════════════════════════
const uploadDir = path.join(__dirname, '../../uploads');
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => cb(null, Date.now() + '-' + Math.round(Math.random() * 1e6) + '-' + file.originalname),
});

// F20.1 — Excel (.xlsx) + CSV file upload support
const excelFileFilter = (req, file, cb) => {
  const allowed = ['.xlsx', '.xls', '.csv'];
  if (allowed.includes(path.extname(file.originalname).toLowerCase())) cb(null, true);
  else cb(new Error('Only Excel/CSV files allowed (.xlsx, .xls, .csv)'), false);
};
const uploadExcel = multer({ storage, fileFilter: excelFileFilter, limits: { fileSize: 10 * 1024 * 1024 } }); // F20.2.1 10MB

// F21.1.1 — PDF only
const pdfFileFilter = (req, file, cb) => {
  if (path.extname(file.originalname).toLowerCase() === '.pdf') cb(null, true);
  else cb(new Error('Only PDF files allowed'), false);
};
const uploadPdf = multer({ storage, fileFilter: pdfFileFilter, limits: { fileSize: 10 * 1024 * 1024 } }); // F21.1.3 10MB

function cleanupFiles(files) {
  Object.values(files || {}).flat().forEach(f => { try { fs.unlinkSync(f.path); } catch (e) {} });
}

// ══════════════════════════════════════════════════════════════
// FEATURE 20 (upgraded) + FEATURE 20B — EXCEL/CSV
// ══════════════════════════════════════════════════════════════

// F20.2 — Download Excel Template
router.get('/excel/template', (req, res) => { // public: window.open() can't send auth headers; template has no sensitive data
  try {
    const buf = generateTemplateBuffer();
    res.setHeader('Content-Disposition', 'attachment; filename=ProveRank_Question_Template.xlsx');
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.send(buf);
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// F20.3/20.5/20.6/20.7/20.9 + F20B.3/20B.4 — Parse & validate (NO save)
router.post('/excel/parse', verifyToken, isAdmin, uploadExcel.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'Excel/CSV file required' });
    const columnMap = req.body.columnMap ? JSON.parse(req.body.columnMap) : null; // F20.3/20B.9

    const { questions, errors, sheetNames, rawHeaders } = parseQuestionExcel(req.file.path, { columnMap });

    const texts = questions.map(q => q.text);
    const existing = texts.length ? await Question.find({ text: { $in: texts } }).select('text') : [];
    const existingSet = new Set(existing.map(e => e.text));
    const enriched = questions.map(q => ({ ...q, isDuplicateInDB: existingSet.has(q.text) }));

    try { fs.unlinkSync(req.file.path); } catch (e) {}

    res.json({
      success: true,
      questions: enriched,
      errors, sheetNames, rawHeaders,
      summary: {
        valid: enriched.filter(q => !q.isDuplicateInDB && !q.isDuplicateInFile).length,
        duplicates: enriched.filter(q => q.isDuplicateInDB || q.isDuplicateInFile).length,
        errors: errors.length,
      }
    });
  } catch (err) {
    try { if (req.file) fs.unlinkSync(req.file.path); } catch (e) {}
    res.status(500).json({ success: false, message: 'Could not parse this file — ' + err.message });
  }
});

// F20.12/20B.11 — Google Sheets URL paste import
router.post('/excel/google-sheet', verifyToken, isAdmin, async (req, res) => {
  try {
    const { url, columnMap } = req.body;
    if (!url) return res.status(400).json({ success: false, message: 'Google Sheet URL required' });
    let csvUrl = url;
    const m = url.match(/\/spreadsheets\/d\/([a-zA-Z0-9-_]+)/);
    if (m) csvUrl = `https://docs.google.com/spreadsheets/d/${m[1]}/export?format=csv`;
    const resp = await fetch(csvUrl);
    if (!resp.ok) return res.status(400).json({ success: false, message: 'Could not fetch sheet — make sure it is shared as "Anyone with link can view"' });
    const csvText = await resp.text();
    const { questions, errors } = parseQuestionCSVString(csvText, { columnMap: columnMap ? JSON.parse(columnMap) : null });
    res.json({ success: true, questions, errors });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// F20 (upgraded) — Save parsed+edited Excel questions to QsBank / PYQ Bank
router.post('/excel/save-to-bank', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questions, target } = req.body; // target: 'qs_bank' | 'pyq_bank'  F20.23
    if (!Array.isArray(questions) || questions.length === 0) return res.status(400).json({ success: false, message: 'No questions to import' });

    let imported = 0, skipped = 0;
    const reportErrors = [];
    for (const q of questions) {
      if (q.isDuplicateInDB || q.isDuplicateInFile) { skipped++; continue; } // F20.8
      try {
        await Question.create({
          text: q.text, hindiText: q.hindiText || '',
          options: q.options, hindiOptions: q.hindiOptions || [],
          correct: q.correct, subject: q.subject, chapter: q.chapter || '',
          topic: q.topic || '', difficulty: q.difficulty || 'Medium', type: q.type || 'SCQ',
          explanation: q.explanation || '', imageUrl: q.imageUrl || '', optionImages: q.optionImages || [],
          tags: q.tags || [], isPYQ: target === 'pyq_bank',
          approvalStatus: 'approved', createdBy: req.user.id,
        });
        imported++;
      } catch (e) { skipped++; reportErrors.push({ text: q.text?.slice(0, 40), message: e.message }); }
    }
    res.json({ success: true, imported, skipped, errors: reportErrors }); // F20.9
    ContentForgeImportLog.create({ sourceType: 'excel', target, fileName: req.body.fileName || '', imported, skipped, errorCount: reportErrors.length, errorDetails: reportErrors.slice(0, 20), createdBy: req.user.id }).catch(() => {}); // F20.15
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// F20B — Create Exam via Excel/CSV
router.post('/excel/create-exam', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questions, examDetails, assignment, postCreate, sourceMeta } = req.body;
    if (!Array.isArray(questions) || questions.length === 0) return res.status(400).json({ success: false, message: 'No questions to build exam' });
    const usable = questions.filter(q => (!q.isDuplicateInDB && !q.isDuplicateInFile) || req.body.includeDuplicates);
    const { exam, questionsCreated, notifiedCount } = await createExamFromQuestions({
      parsedQuestions: usable, examDetails, assignment, postCreate,
      sourceMeta: { ...sourceMeta, sourceType: 'excel' },
      createdBy: req.user.id,
    });
    res.json({ success: true, message: 'Exam created', exam, examId: exam._id, questionsCreated, notifiedCount }); // F20B.7.2 exam._id
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ══════════════════════════════════════════════════════════════
// FEATURE 21 (upgraded) + FEATURE 21B — PDF PARSING
// ══════════════════════════════════════════════════════════════

const pdfUploadFields = uploadPdf.fields([
  { name: 'questionsPdf', maxCount: 1 },
  { name: 'answerKeyPdf', maxCount: 1 },
  { name: 'explanationPdf', maxCount: 1 },
]);

// F21.2-21.7 / F21B.2-21B.7 — Extract + parse + sync answer key + explanation (NO save)
router.post('/pdf/parse', verifyToken, isAdmin, pdfUploadFields, async (req, res) => {
  try {
    const qFile = req.files?.questionsPdf?.[0];
    const aFile = req.files?.answerKeyPdf?.[0];
    const eFile = req.files?.explanationPdf?.[0];
    if (!qFile) return res.status(400).json({ success: false, message: 'Question paper PDF required' });
    if (!aFile) return res.status(400).json({ success: false, message: 'Answer key PDF required' });

    const pageFrom = req.body.pageFrom ? parseInt(req.body.pageFrom) : undefined; // F21.16
    const pageTo = req.body.pageTo ? parseInt(req.body.pageTo) : undefined;

    const result = await buildQuestionsFromPDFs({
      questionsPdfPath: qFile.path,
      answerKeyPdfPath: aFile.path,
      explanationPdfPath: eFile ? eFile.path : null,
      subjectMapText: req.body.subjectMapText || '',
      pageFrom, pageTo,
      customDelimiter: req.body.customDelimiter || null,
    });

    const texts = result.questions.map(q => q.text);
    const existing = texts.length ? await Question.find({ text: { $in: texts } }).select('text') : [];
    const existingSet = new Set(existing.map(e => e.text));
    result.questions = result.questions.map(q => ({ ...q, isDuplicateInDB: existingSet.has(q.text) }));

    [qFile, aFile, eFile].filter(Boolean).forEach(f => { try { fs.unlinkSync(f.path); } catch (e) {} });

    res.json({
      success: true,
      ...result,
      summary: { parsed: result.questions.length, errors: result.errors.length, duplicates: result.questions.filter(q => q.isDuplicateInDB || q.isDuplicate).length },
    });
  } catch (err) {
    [req.files?.questionsPdf?.[0], req.files?.answerKeyPdf?.[0], req.files?.explanationPdf?.[0]].filter(Boolean).forEach(f => { try { fs.unlinkSync(f.path); } catch (e) {} });
    res.status(500).json({ success: false, message: 'Could not parse PDF — file may be scanned/corrupted/password-protected. ' + err.message });
  }
});

// F21 (upgraded) — Save parsed+edited PDF questions to QsBank / PYQ Bank
router.post('/pdf/save-to-bank', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questions, target, sourceMeta } = req.body;
    if (!Array.isArray(questions) || questions.length === 0) return res.status(400).json({ success: false, message: 'No questions to import' });
    let imported = 0, skipped = 0;
    const reportErrors = [];
    for (const q of questions) {
      if (q.isDuplicateInDB || q.isDuplicate || q.hasError) { skipped++; continue; }
      try {
        await Question.create({
          text: q.text, options: q.options, correct: q.correct, subject: q.subject || 'General',
          type: q.type || 'SCQ', explanation: q.explanation || '', isPYQ: target === 'pyq_bank',
          approvalStatus: 'approved', createdBy: req.user.id,
          sourceExam: sourceMeta?.fileName || '',
        });
        imported++;
      } catch (e) { skipped++; reportErrors.push({ text: q.text?.slice(0, 40), message: e.message }); }
    }
    res.json({ success: true, imported, skipped, errors: reportErrors });
    ContentForgeImportLog.create({ sourceType: 'pdf', target, fileName: sourceMeta?.fileName || '', imported, skipped, errorCount: reportErrors.length, errorDetails: reportErrors.slice(0, 20), createdBy: req.user.id }).catch(() => {}); // F20.15 (also covers PDF flow)
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// F21B — Create Exam via PDF Parsing
router.post('/pdf/create-exam', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questions, examDetails, assignment, postCreate, sourceMeta } = req.body;
    if (!Array.isArray(questions) || questions.length === 0) return res.status(400).json({ success: false, message: 'No questions to build exam' });
    const usable = questions.filter(q => !q.hasError);
    const { exam, questionsCreated, notifiedCount } = await createExamFromQuestions({
      parsedQuestions: usable, examDetails, assignment, postCreate,
      sourceMeta: { ...sourceMeta, sourceType: 'pdf' },
      createdBy: req.user.id,
    });
    res.json({ success: true, message: 'Exam created', exam, examId: exam._id, questionsCreated, notifiedCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ══════════════════════════════════════════════════════════════
// FEATURE 19B — Create Exam via Copy-Paste
// ══════════════════════════════════════════════════════════════
router.post('/paste/create-exam', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questions, examDetails, assignment, postCreate } = req.body;
    if (!Array.isArray(questions) || questions.length === 0) return res.status(400).json({ success: false, message: 'No questions to build exam' });
    const { exam, questionsCreated, notifiedCount } = await createExamFromQuestions({
      parsedQuestions: questions, examDetails, assignment, postCreate,
      sourceMeta: { sourceType: 'paste', uploadedAt: new Date(), totalParsed: questions.length },
      createdBy: req.user.id,
    });
    res.json({ success: true, message: 'Exam created', exam, examId: exam._id, questionsCreated, notifiedCount }); // F19B.7.2
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ══════════════════════════════════════════════════════════════
// SHARED HELPERS — used across 19B / 20B / 21B
// ══════════════════════════════════════════════════════════════

router.post('/check-duplicates', verifyToken, isAdmin, async (req, res) => {
  try {
    const { texts, batch } = req.body;
    if (!Array.isArray(texts) || texts.length === 0) return res.json({ success: true, duplicates: [] });
    const existing = await Question.find({ text: { $in: texts } }).select('text sourceExam');
    let sameBatchExamIds = new Set();
    if (batch) {
      const exams = await Exam.find({ $or: [{ batch }, { multiBatch: batch }] }).select('_id');
      sameBatchExamIds = new Set(exams.map(e => String(e._id)));
    }
    const duplicates = existing.map(e => ({ text: e.text, inSameBatch: sameBatchExamIds.has(String(e.sourceExam)) }));
    res.json({ success: true, duplicates });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.get('/series', verifyToken, isAdmin, async (req, res) => {
  try {
    const series = await Exam.distinct('seriesName', { seriesName: { $ne: '' } });
    res.json({ success: true, series });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.get('/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    const templates = await Exam.find({ isTemplate: true }).select('title subject category duration totalMarks markingScheme type customInstructions watermark reviewWindow waitingRoomEnabled waitingRoomMinutes').sort({ createdAt: -1 }).limit(50);
    res.json({ success: true, templates });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// F20.15 — Import history log (new upgraded flow)
router.get('/import-history', verifyToken, isAdmin, async (req, res) => {
  try {
    const logs = await ContentForgeImportLog.find({}).sort({ createdAt: -1 }).limit(30);
    res.json({ success: true, logs });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.post('/exam/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const now = new Date();
    const startsInFuture = exam.schedule?.startTime && new Date(exam.schedule.startTime) > now;
    exam.status = startsInFuture ? 'scheduled' : 'live';
    await exam.save();
    res.json({ success: true, message: 'Exam published', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;

BUGFIX_EOF
echo "  -> wrote src/routes/contentForge.js"
ALL_OK=1
node --check "src/models/Exam.js" && echo "  [OK] src/models/Exam.js" || { echo "  [FAIL] src/models/Exam.js"; ALL_OK=0; }
node --check "src/routes/contentForge.js" && echo "  [OK] src/routes/contentForge.js" || { echo "  [FAIL] src/routes/contentForge.js"; ALL_OK=0; }
if [ $ALL_OK -eq 1 ]; then echo "✅ BACKEND BUGFIX PATCH COMPLETE"; else echo "⚠️ SYNTAX CHECK FAILED"; fi
echo "Restart server to apply."