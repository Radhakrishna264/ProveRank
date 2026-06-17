const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { verifyToken, isAdmin } = require('../middleware/auth');

const Question = require('../models/Question');
const Exam = require('../models/Exam');

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
router.get('/excel/template', verifyToken, isAdmin, (req, res) => {
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

