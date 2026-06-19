#!/bin/bash
set -e
echo "=================================================="
echo "ProveRank Backend Installer v2 — Patch: 20.14/20.15/20.17"
echo "=================================================="

cd ~/workspace || { echo "ERROR: ~/workspace not found"; exit 1; }

echo "[1/3] Backing up files that will be modified..."
mkdir -p .backup_contentforge_patch2_$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=$(ls -d .backup_contentforge_patch2_* | tail -1)
cp src/routes/contentForge.js "$BACKUP_DIR/contentForge.js.bak" 2>/dev/null || true
echo "Backup saved to $BACKUP_DIR"

echo "[2/3] Writing files..."
mkdir -p $(dirname "src/models/Exam.js")
cat > "src/models/Exam.js" << 'CONTENTFORGE_EOF_MARKER'
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
    startTime: Date,
    endTime:   Date
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

CONTENTFORGE_EOF_MARKER
echo "  -> wrote src/models/Exam.js"

mkdir -p $(dirname "src/models/Question.js")
cat > "src/models/Question.js" << 'CONTENTFORGE_EOF_MARKER'
const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
  text: { type: String, required: true, trim: true },
  hindiText: { type: String, default: '' },
  hindiOptions: { type: [String], default: [] },
  hindiExplanation: { type: String, default: '' },

  options: {
    type: [String],
    required: true,
    validate: {
      validator: function(v) { return this.type === 'Integer' || v.length >= 2; }, // FIX: Integer-type Qs legitimately have 0 options (19B.2.5/20.1.2.11/21B.5.5) — pre-existing bug, was blocking ALL Integer question creation system-wide
      message: 'At least 2 options required'
    }
  },

  correct: { type: [Number], required: true },

  subject: { type: String, default: 'General' },
  difficulty: { type: String, default: 'Untagged' },

  type: {
    type: String,
    enum: ['SCQ', 'MSQ', 'Integer'],
    default: 'SCQ'
  },

  chapter: { type: String, default: '' },
  topic: { type: String, default: '' },
  explanation: { type: String, default: '' },
  videoLink: { type: String, default: '' },
  tags: [{ type: String }],
  image: { type: String, default: '' },

  usageCount: { type: Number, default: 0 },
  sourceExam: { type: String, default: '' },
  examLevel: { type: String, default: 'NEET' },
  format: { type: String, default: '' },
  imageUrl: { type: String, default: '' },
  optionImages: { type: [String], default: [] },

  similarityScore: { type: Number, default: 0 },
  similarQuestionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question',
    default: null
  },

  isPYQ: { type: Boolean, default: false },
  pyqYear: { type: Number, default: null },

  approvalStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'approved'
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  approvedAt: { type: Date, default: null },
  rejectionReason: { type: String, default: null },

  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  versionHistory: [
    {
      version: { type: Number },
      text: { type: String },
      editedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      editedAt: { type: Date, default: Date.now },
      changes: { type: String }
    }
  ],

  reports: [
    {
      reason: { type: String },
      reportedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      reportedAt: { type: Date, default: Date.now },
      status: { type: String, enum: ['pending', 'resolved'], default: 'pending' }
    }
  ]

}, { timestamps: true });

const { runAIPipeline } = require('../services/ai');

questionSchema.pre('save', async function () {
  if (this.isModified('text') && !this.isNew) {
    if (!this.versionHistory) this.versionHistory = [];
    this.versionHistory.push({
      version: this.versionHistory.length + 1,
      text: this.text,
      editedAt: new Date(),
      changes: 'text updated'
    });
  }
  if (this.isModified('text') || this.isNew) {
    const _userDiff = (this.difficulty && this.difficulty !== 'Untagged') ? this.difficulty : null;
    const _userSubj = (this.subject && this.subject !== 'General') ? this.subject : null;
    await runAIPipeline(this);
    // Restore user-set values — AI must NOT override manual selection
    if (_userDiff) this.difficulty = _userDiff;
    if (_userSubj) this.subject = _userSubj;
  }
});

module.exports = mongoose.model('Question', questionSchema);

CONTENTFORGE_EOF_MARKER
echo "  -> wrote src/models/Question.js"

mkdir -p $(dirname "src/models/ContentForgeImportLog.js")
cat > "src/models/ContentForgeImportLog.js" << 'CONTENTFORGE_EOF_MARKER'
const mongoose = require('mongoose');

// F20.15 / F21.x — Import history log for the NEW upgraded content-forge flow
// (separate from the legacy ExcelUploadLog used by the old /api/excel routes,
// so this is purely additive — does not touch existing log/history behaviour).
const contentForgeImportLogSchema = new mongoose.Schema({
  sourceType: { type: String, enum: ['excel', 'pdf'], required: true },
  target:     { type: String, enum: ['qs_bank', 'pyq_bank', 'exam'], required: true },
  fileName:   { type: String, default: '' },
  imported:   { type: Number, default: 0 },
  skipped:    { type: Number, default: 0 },
  errorCount: { type: Number, default: 0 },
  errorDetails: [{ row: mongoose.Schema.Types.Mixed, message: String }],
  createdBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('ContentForgeImportLog', contentForgeImportLogSchema);

CONTENTFORGE_EOF_MARKER
echo "  -> wrote src/models/ContentForgeImportLog.js"

mkdir -p $(dirname "src/utils/excelParser.js")
cat > "src/utils/excelParser.js" << 'CONTENTFORGE_EOF_MARKER'
const XLSX = require('xlsx');

// ══════════════════════════════════════════════════════════════
// Feature 20 / 20B — Excel/CSV Question Parser (UPGRADED ENGINE)
// Fixes: old engine produced options:[{text,isCorrect}] which did
// NOT match Question schema (options:[String], correct:[Number]).
// This engine outputs the CORRECT shape everywhere. (F20 root-fix)
// ══════════════════════════════════════════════════════════════

// F20.13 / F20B.9 — Auto column-detect: normalize header text so
// many real-world header spellings map to our canonical field names.
function normalizeHeader(h) {
  return String(h || '').trim().toLowerCase().replace(/[\s_\-\.]+/g, '');
}

const HEADER_SYNONYMS = {
  qno:            'Q_No',
  questionno:     'Q_No',
  qnum:           'Q_No',
  questiontext:   'Question_Text',
  question:       'Question_Text',
  qtext:          'Question_Text',
  englishtext:    'Question_Text',
  hinditext:      'Hindi_Text',
  hindiquestion:  'Hindi_Text',
  optiona:        'Option_A',
  optionb:        'Option_B',
  optionc:        'Option_C',
  optiond:        'Option_D',
  hindia:         'Hindi_A',
  hindib:         'Hindi_B',
  hindic:         'Hindi_C',
  hindid:         'Hindi_D',
  correctanswer:  'Correct_Answer',
  answer:         'Correct_Answer',
  correct:        'Correct_Answer',
  subject:        'Subject',
  chapter:        'Chapter',
  topic:          'Topic',
  difficulty:     'Difficulty',
  type:           'Type',
  questiontype:   'Type',
  explanation:    'Explanation',
  imageurl:       'Image_URL',
  questionimage:  'Image_URL',
  mainimageurl:   'Image_URL',
  optionsimageurl:'OptionsImage_URL',
  optionimageurl: 'OptionsImage_URL',
  tags:           'Tags',
};

// F20.3 / F20B.9 — Build a header map (file header -> canonical) either
// from an explicit columnMap (manual mapping UI) or by auto-detection.
function resolveHeaderMap(rawHeaders, columnMap) {
  const map = {}; // rawHeader -> canonicalName
  rawHeaders.forEach(h => {
    if (columnMap && columnMap[h]) { map[h] = columnMap[h]; return; }
    const norm = normalizeHeader(h);
    if (HEADER_SYNONYMS[norm]) { map[h] = HEADER_SYNONYMS[norm]; return; }
    map[h] = h; // exact canonical name already used in file (e.g. "Question_Text")
  });
  return map;
}

function remapRow(row, headerMap) {
  const out = {};
  Object.keys(row).forEach(h => { out[headerMap[h] || h] = row[h]; });
  return out;
}

// F20.18 / F20B.17 — lightweight rule-based Subject classifier (no extra AI round-trip for bulk rows)
function guessSubject(text) {
  const t = String(text || '').toLowerCase();
  if (t.match(/newton|force|velocity|acceleration|current|voltage|resistance|wave|optics|thermodynamics|capacitor|magnet/)) return 'Physics';
  if (t.match(/carbon|hydrogen|molecule|reaction|acid|base|bond|element|compound|periodic|organic|inorganic/)) return 'Chemistry';
  if (t.match(/cell|dna|rna|photosynthesis|respiration|enzyme|protein|genetics|evolution|tissue|organ/)) return 'Biology';
  if (t.match(/integral|derivative|matrix|probability|trigonometry|algebra|geometry/)) return 'Math';
  return 'General';
}

// F20.18 / F20B.17 — lightweight rule-based Difficulty tagger
function guessDifficulty(text) {
  const t = String(text || '').toLowerCase();
  if (t.match(/calculate|derive|prove|evaluate|analyse|mechanism|complex/)) return 'Hard';
  if (t.match(/define|what is|name|which|identify|state/)) return 'Easy';
  return 'Medium';
}

// F20.3.4/3.5/3.6 — F20B.3.4/3.5/3.6 — Correct_Answer parser: SCQ / MSQ / Integer
function parseCorrectAnswer(raw, type, options) {
  const val = String(raw || '').trim();
  if (!val) return { correct: [], error: 'Correct_Answer missing' };

  if (type === 'Integer') {
    const num = parseFloat(val);
    if (isNaN(num)) return { correct: [], error: 'Correct_Answer must be numeric for Integer type' };
    return { correct: [num], error: null };
  }

  const letters = val.toUpperCase().match(/[A-D]/g) || [];
  if (letters.length === 0) return { correct: [], error: 'Correct_Answer must be A/B/C/D (or combination for MSQ)' };

  const idxMap = { A: 0, B: 1, C: 2, D: 3 };
  const correct = [...new Set(letters.map(l => idxMap[l]))].filter(i => i < options.length);

  if (type === 'MSQ' && correct.length < 1) return { correct: [], error: 'MSQ requires at least 1 correct option' };
  if (type !== 'MSQ' && correct.length > 1) return { correct: [correct[0]], error: null };

  return { correct, error: null };
}

// F20.4b / F20B.1.2.14 — Options image url parser: "url1,url2,url3,url4" -> [url1,url2,url3,url4]
function parseOptionImages(raw) {
  if (!raw) return [];
  return String(raw).split(',').map(s => s.trim()).filter(Boolean);
}

// Shared per-row processor (used by both file-based and CSV-string parsing so logic stays in sync)
function processRows(rows, answerSheetMap, explSheetMap) {
  answerSheetMap = answerSheetMap || {};
  explSheetMap = explSheetMap || {};
  const questions = [], errors = [];
  const seenInFile = new Set(); // F20.6 — within-file duplicate detection

  rows.forEach((row, index) => {
    const rowNum = index + 2; // +2 because row 1 = header
    const qNo = row.Q_No !== undefined && row.Q_No !== '' ? String(row.Q_No) : String(rowNum - 1);
    const qText = row.Question_Text ? String(row.Question_Text).trim() : '';
    const rawType = (row.Type ? String(row.Type).trim().toUpperCase() : 'SCQ');
    const type = rawType === 'MSQ' ? 'MSQ' : rawType === 'INTEGER' ? 'Integer' : 'SCQ';

    // F20.4 / F20B.3.3 — Hard required fields
    const rowErrors = [];
    if (!qText) rowErrors.push('Question_Text missing');

    let options = [];
    if (type !== 'Integer') {
      const oA = row.Option_A, oB = row.Option_B, oC = row.Option_C, oD = row.Option_D;
      if (!oA || !oB || !oC || !oD) rowErrors.push('Option_A/B/C/D required (all 4)');
      else options = [String(oA).trim(), String(oB).trim(), String(oC).trim(), String(oD).trim()];
    }

    const subject = row.Subject ? String(row.Subject).trim() : '';
    if (!subject) rowErrors.push('Subject missing');

    const ansRaw = (row.Correct_Answer !== undefined && row.Correct_Answer !== '') ? row.Correct_Answer : (answerSheetMap[qNo] || '');
    let correct = [];
    if (rowErrors.length === 0) {
      const parsed = parseCorrectAnswer(ansRaw, type, options);
      correct = parsed.correct;
      if (parsed.error) rowErrors.push(parsed.error);
    }

    // F20.6 — Duplicate within same file (exact text match, case-insensitive)
    const dedupKey = qText.toLowerCase();
    const isDupInFile = !!(qText && seenInFile.has(dedupKey));
    if (qText) seenInFile.add(dedupKey);

    if (rowErrors.length > 0) {
      errors.push({ row: rowNum, qNo, message: rowErrors.join('; ') });
      return;
    }

    // Soft-required (default + warning only, never blocks import) — Chapter / Difficulty
    const chapter    = row.Chapter    ? String(row.Chapter).trim()    : '';
    const difficulty = row.Difficulty ? String(row.Difficulty).trim() : guessDifficulty(qText); // F20.18

    questions.push({
      qNo,
      text:             qText,
      hindiText:        row.Hindi_Text ? String(row.Hindi_Text).trim() : '',
      options,
      hindiOptions:     (row.Hindi_A || row.Hindi_B || row.Hindi_C || row.Hindi_D)
                          ? [row.Hindi_A, row.Hindi_B, row.Hindi_C, row.Hindi_D].map(v => v ? String(v).trim() : '')
                          : [],
      correct,
      subject:          subject || guessSubject(qText), // F20.17
      chapter,
      topic:            row.Topic ? String(row.Topic).trim() : '',
      difficulty,
      type,
      explanation:      row.Explanation ? String(row.Explanation).trim() : (explSheetMap[qNo] || ''),
      imageUrl:         row.Image_URL ? String(row.Image_URL).trim() : '',          // F20.4b optional
      optionImages:     parseOptionImages(row.OptionsImage_URL),                     // F20.4b optional
      tags:             row.Tags ? String(row.Tags).split(',').map(t => t.trim()) : [],
      isDuplicateInFile: isDupInFile, // F20.6 — flagged, not blocked (admin decides in preview)
    });
  });

  return { questions, errors };
}

/**
 * Core file-based parser — used by BOTH Feature 20 (save to QB/PYQ) and Feature 20B (create exam)
 * @param {string} filePath
 * @param {object} opts { columnMap }
 */
function parseQuestionExcel(filePath, opts) {
  opts = opts || {};
  const workbook = XLSX.readFile(filePath);
  const sheetNames = workbook.SheetNames;
  let rows = XLSX.utils.sheet_to_json(workbook.Sheets[sheetNames[0]], { defval: '' });

  if (rows.length === 0) return { questions: [], errors: [{ row: '-', message: 'File is empty or has no data rows' }], sheetNames };

  const rawHeaders = Object.keys(rows[0]);
  const headerMap = resolveHeaderMap(rawHeaders, opts.columnMap);
  rows = rows.map(r => remapRow(r, headerMap));

  // F20.11 / F20B.12 — Multi-sheet support: a sheet named like "AnswerKey" / "Explanations" merges in by Q_No
  let answerSheetMap = {}, explSheetMap = {};
  sheetNames.forEach(name => {
    if (name === sheetNames[0]) return;
    const lower = name.toLowerCase();
    if (lower.includes('answer')) {
      XLSX.utils.sheet_to_json(workbook.Sheets[name], { defval: '' }).forEach(r => {
        const qno = r.Q_No || r.QNo || r['Q No'] || r['Question No'];
        if (qno !== undefined && qno !== '') answerSheetMap[String(qno)] = r.Correct_Answer || r.Answer || r.Correct || '';
      });
    }
    if (lower.includes('explan')) {
      XLSX.utils.sheet_to_json(workbook.Sheets[name], { defval: '' }).forEach(r => {
        const qno = r.Q_No || r.QNo || r['Q No'] || r['Question No'];
        if (qno !== undefined && qno !== '') explSheetMap[String(qno)] = r.Explanation || r.Explanations || '';
      });
    }
  });

  const result = processRows(rows, answerSheetMap, explSheetMap);
  return { questions: result.questions, errors: result.errors, sheetNames, rawHeaders };
}

const parseStudentExcel = (filePath) => {
  const workbook = XLSX.readFile(filePath);
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(sheet, { defval: '' });

  const students = [];
  const errors = [];

  rows.forEach((row, index) => {
    const rowNum = index + 2;
    if (!row['Name'])  { errors.push({ row: rowNum, message: 'Name missing' });  return; }
    if (!row['Email']) { errors.push({ row: rowNum, message: 'Email missing' }); return; }
    if (!row['Phone']) { errors.push({ row: rowNum, message: 'Phone missing' }); return; }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(row['Email'])) { errors.push({ row: rowNum, message: 'Invalid email format' }); return; }
    students.push({
      name:  String(row['Name']).trim(),
      email: String(row['Email']).trim().toLowerCase(),
      phone: String(row['Phone']).trim(),
      group: row['Group'] ? String(row['Group']).trim() : 'General'
    });
  });

  return { students, errors };
};

// F20.12 / F20B.11 — Parse a raw CSV string (used for Google Sheets public URL import)
function parseQuestionCSVString(csvText, opts) {
  opts = opts || {};
  const workbook = XLSX.read(csvText, { type: 'string' });
  let rows = XLSX.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]], { defval: '' });
  if (rows.length === 0) return { questions: [], errors: [{ row: '-', message: 'Sheet is empty' }] };
  const rawHeaders = Object.keys(rows[0]);
  const headerMap = resolveHeaderMap(rawHeaders, opts.columnMap);
  rows = rows.map(r => remapRow(r, headerMap));
  const result = processRows(rows);
  return { questions: result.questions, errors: result.errors, rawHeaders };
}

// F20.2 — Generate downloadable Excel template with sample rows
function generateTemplateBuffer() {
  const headers = ['Q_No','Question_Text','Hindi_Text','Option_A','Option_B','Option_C','Option_D','Hindi_A','Hindi_B','Hindi_C','Hindi_D','Correct_Answer','Subject','Chapter','Topic','Difficulty','Type','Explanation','Image_URL','OptionsImage_URL'];
  const sample = [
    { Q_No:1, Question_Text:'What is the SI unit of force?', Hindi_Text:'बल की SI इकाई क्या है?', Option_A:'Newton', Option_B:'Joule', Option_C:'Watt', Option_D:'Pascal', Hindi_A:'न्यूटन', Hindi_B:'जूल', Hindi_C:'वाट', Hindi_D:'पास्कल', Correct_Answer:'A', Subject:'Physics', Chapter:'Mechanics', Topic:'Force', Difficulty:'Easy', Type:'SCQ', Explanation:'Force is measured in Newton (N).', Image_URL:'', OptionsImage_URL:'' },
    { Q_No:2, Question_Text:'Which of the following are noble gases? (Select all)', Hindi_Text:'', Option_A:'Helium', Option_B:'Neon', Option_C:'Oxygen', Option_D:'Argon', Hindi_A:'', Hindi_B:'', Hindi_C:'', Hindi_D:'', Correct_Answer:'A,B,D', Subject:'Chemistry', Chapter:'Periodic Table', Topic:'Noble Gases', Difficulty:'Medium', Type:'MSQ', Explanation:'He, Ne, Ar are noble gases; O2 is not.', Image_URL:'', OptionsImage_URL:'' },
    { Q_No:3, Question_Text:'Calculate the value of 12 x 8.', Hindi_Text:'', Option_A:'', Option_B:'', Option_C:'', Option_D:'', Hindi_A:'', Hindi_B:'', Hindi_C:'', Hindi_D:'', Correct_Answer:'96', Subject:'Math', Chapter:'Arithmetic', Topic:'Multiplication', Difficulty:'Easy', Type:'Integer', Explanation:'12 x 8 = 96', Image_URL:'', OptionsImage_URL:'' },
  ];
  const ws = XLSX.utils.json_to_sheet(sample, { header: headers });
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Questions');
  return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
}

module.exports = {
  parseQuestionExcel,
  parseStudentExcel,
  parseQuestionCSVString,
  generateTemplateBuffer,
  guessSubject,
  guessDifficulty,
};

CONTENTFORGE_EOF_MARKER
echo "  -> wrote src/utils/excelParser.js"

mkdir -p $(dirname "src/utils/pdfQuestionParser.js")
cat > "src/utils/pdfQuestionParser.js" << 'CONTENTFORGE_EOF_MARKER'
const fs = require('fs');
const pdfParse = require('pdf-parse');

// ══════════════════════════════════════════════════════════════
// Feature 21 / 21B — PDF Question Parsing Engine (NEW, self-contained)
// Does NOT touch any existing controller/route. Pure utility module.
// ══════════════════════════════════════════════════════════════

// F21.2.1 / F21B.2.1 — Extract text PAGE-BY-PAGE (needed to strip
// repeating headers/footers and to give page-level error references)
async function extractPagesText(filePath) {
  const buffer = fs.readFileSync(filePath);
  const pages = [];
  try {
    await pdfParse(buffer, {
      pagerender: function (pageData) {
        return pageData.getTextContent().then(function (textContent) {
          let text = '';
          let lastY = null;
          textContent.items.forEach(function (item) {
            if (lastY !== null && Math.abs(lastY - item.transform[5]) > 2) text += '\n';
            text += item.str;
            lastY = item.transform[5];
          });
          pages.push(text);
          return text;
        });
      }
    });
    if (pages.length > 0) return pages; // per-page granularity succeeded
  } catch (e) { /* fall through to plain-text fallback below */ }

  // F21.6 — Graceful fallback: some PDFs (unusual encoders/XRef layouts) fail the
  // per-page pagerender path. Fall back to a single combined-text extraction so the
  // feature still works (header-strip & page-number error refs are simply skipped).
  const data = await pdfParse(buffer);
  return [data.text || ''];
}

// F21.2.1 — Identify lines that repeat (institute name / running header / page no.)
// and strip them out so they don't pollute question text. Counts TOTAL occurrences
// across all pages combined (not just page-presence) so this also catches short
// PDFs where a header repeats more than once on the very same physical page —
// while carefully NOT stripping legitimate repeated option text (True/False/
// None of the above etc., which genuinely repeat across many questions).
function stripRepeatingLines(pages) {
  const optionLikePattern = /^\(?[A-Da-d][\)\.\:\-]/i;
  const commonOptionPhrase = /^(true|false|yes|no|none of (the )?above|all of (the )?above|cannot be determined|none of these|both \w+ and \w+)\.?$/i;
  const questionLikePattern = /^Q?\s*\d+[\.\)\:\-]/i;

  const lineTotalCounts = {};
  const linePageCounts = {};
  pages.forEach(p => {
    const lines = p.split('\n').map(l => l.trim()).filter(Boolean);
    lines.forEach(l => { lineTotalCounts[l] = (lineTotalCounts[l] || 0) + 1; });
    new Set(lines).forEach(l => { linePageCounts[l] = (linePageCounts[l] || 0) + 1; });
  });

  const pageThreshold = Math.max(2, Math.ceil(pages.length * 0.5));
  const repeating = new Set(
    Object.keys(lineTotalCounts).filter(l => {
      if (l.length >= 120 || questionLikePattern.test(l) || optionLikePattern.test(l) || commonOptionPhrase.test(l)) return false;
      const wordCount = l.split(/\s+/).length;
      const repeatsAcrossPages = linePageCounts[l] >= pageThreshold;
      const repeatsOnFewPages = pages.length <= 2 && lineTotalCounts[l] >= 2 && wordCount >= 2; // short-doc safety net
      return repeatsAcrossPages || repeatsOnFewPages;
    })
  );
  const cleanedPages = pages.map(p =>
    p.split('\n').filter(l => !repeating.has(l.trim())).join('\n')
  );
  return { cleanedPages, repeatingLines: [...repeating] };
}

// F21.3.8 — Language detection (Devanagari unicode block = Hindi)
function detectLanguage(text) {
  const hindiChars = (text.match(/[\u0900-\u097F]/g) || []).length;
  const engChars   = (text.match(/[A-Za-z]/g) || []).length;
  if (hindiChars > 20 && engChars > 20) return 'Bilingual';
  if (hindiChars > engChars) return 'Hindi';
  return 'English';
}

// F21.1.7 / F21.1.7B / F21.1.7C — Subject range map parser. Supports:
//   "Q1. Physics" / "Q1 Physics" / "Q1) Physics"   (per-question)
//   "Q1-Q45 Physics; Q46-Q90 Chemistry"             (range list, ; or \n separated)
function parseSubjectRangeMap(mapText) {
  const perQuestion = {}; // qNum -> subject
  const ranges = [];      // [{from,to,subject}]
  if (!mapText || !mapText.trim()) return { perQuestion, ranges };

  const chunks = mapText.split(/[;\n]+/).map(s => s.trim()).filter(Boolean);
  chunks.forEach(chunk => {
    const rangeMatch = chunk.match(/Q?\s*(\d+)\s*-\s*Q?\s*(\d+)\s+([A-Za-z\s]+)/i);
    if (rangeMatch) {
      const from = parseInt(rangeMatch[1]), to = parseInt(rangeMatch[2]), subject = rangeMatch[3].trim();
      ranges.push({ from, to, subject });
      for (let i = from; i <= to; i++) perQuestion[i] = subject;
      return;
    }
    const singleMatch = chunk.match(/Q?\s*(\d+)[\.\)\:\-\s]+([A-Za-z\s]+)/i);
    if (singleMatch) {
      const qn = parseInt(singleMatch[1]), subject = singleMatch[2].trim();
      perQuestion[qn] = subject;
    }
  });
  return { perQuestion, ranges };
}

function subjectForQNum(qNum, subjectMap) {
  if (subjectMap.perQuestion[qNum]) return subjectMap.perQuestion[qNum];
  const r = subjectMap.ranges.find(r => qNum >= r.from && qNum <= r.to);
  return r ? r.subject : '';
}

// F21.3.6 — Answer key section detector
function extractAnswerKeySection(text) {
  const m = text.match(/(?:answer\s*key|answers?\s*:|solutions?\s*:)([\s\S]*)/i);
  return m ? m[1] : text;
}

// F21.3.7 — Explanation/Solution section detector
function extractExplanationSection(text) {
  const m = text.match(/(?:explanations?\s*:|solutions?\s*:|detailed\s*solutions?\s*:)([\s\S]*)/i);
  return m ? m[1] : text;
}

// F21.5.1-5.6 — Answer key parser (same multi-format logic family as Feature 19 paste engine)
function parseAnswerKey(text) {
  const map = {};
  if (!text || !text.trim()) return map;
  const cleaned = extractAnswerKeySection(text);
  const lines = cleaned.trim().split('\n').map(l => l.trim()).filter(Boolean);

  const matches = cleaned.matchAll(/Q?\s*(\d+)\s*[\-\.\)\:]\s*\(?([A-Da-d,\s]+|\-?\d+\.?\d*)\)?/g);
  let foundAny = false;
  for (const m of matches) {
    foundAny = true;
    const qNum = parseInt(m[1]);
    const raw = m[2].trim();
    if (/^[A-Da-d,\s]+$/.test(raw)) {
      const letters = [...new Set((raw.toUpperCase().match(/[A-D]/g) || []))];
      map[qNum] = { letters };
    } else {
      map[qNum] = { numeric: parseFloat(raw) };
    }
  }
  if (foundAny) return map;

  if (lines.length > 0 && lines.every(l => /^[A-Da-d]$/.test(l))) {
    lines.forEach((l, i) => { map[i + 1] = { letters: [l.toUpperCase()] }; });
    return map;
  }
  if (lines.length === 1 && /^[A-Da-d]+$/.test(lines[0])) {
    lines[0].split('').forEach((ch, i) => { map[i + 1] = { letters: [ch.toUpperCase()] }; });
  }
  return map;
}

// F21.5.7-5.9 — Explanation/Solution parser
function parseExplanations(text) {
  const map = {};
  if (!text || !text.trim()) return map;
  const cleaned = extractExplanationSection(text);
  const blocks = cleaned.split(/(?=(?:^|\n)\s*Q?\d+[\.\)\:\-\s])/im);
  blocks.forEach(block => {
    const m = block.trim().match(/^Q?\s*(\d+)[\.\)\:\-\s]+([\s\S]+)/);
    if (m) map[parseInt(m[1])] = m[2].trim();
  });
  return map;
}

// F21B.3.1-3.5 — Question block splitter: numbered / Q-number / Roman numerals
function splitIntoBlocks(text, customDelim) {
  if (customDelim && text.includes(customDelim)) {
    return text.split(customDelim).map(s => s.trim()).filter(Boolean);
  }
  const patterns = [
    { re: /(?=(?:^|\n)\s*Q\s*\.?\s*\d+[\s\.\)\:\-])/im, name: 'Q-number' },
    { re: /(?=(?:^|\n)\s*\d+[\.\)\:\-\s])/m,            name: 'numbered' },
    { re: /(?=(?:^|\n)\s*[IVXLC]+[\.\)\:\-\s])/m,       name: 'roman' },
  ];
  for (const p of patterns) {
    if (p.re.test(text)) {
      const blocks = text.split(p.re).map(s => s.trim()).filter(Boolean);
      if (blocks.length > 1) return blocks;
    }
  }
  return text.split(/\n{2,}/).map(s => s.trim()).filter(Boolean);
}

// F21B.3.5 — Option format detect & block parse
function parseOneBlock(block, idx, pageHint) {
  const lines = block.split('\n').map(l => l.trim()).filter(Boolean);
  const numMatch = lines[0] && lines[0].match(/^Q?\s*(\d+)[\s\.\)\:\-]/i);
  const qNum = numMatch ? parseInt(numMatch[1]) : idx + 1;

  let qText = lines[0] ? lines[0].replace(/^Q?\s*\d+[\s\.\)\:\-]\s*/i, '').trim() : '';
  let i = 1;
  const optionLineRe = /^(?:Option\s*)?[\(\[]?\s*([A-Da-d])\s*[\)\]\.\:\-\s]+(.+)/i;
  while (i < lines.length && !optionLineRe.test(lines[i])) {
    qText += ' ' + lines[i];
    i++;
  }
  const options = [];
  while (i < lines.length) {
    const m = lines[i].match(optionLineRe);
    if (m) options.push(m[2].trim());
    i++;
  }

  const errors = [];
  if (!qText) errors.push('Question text empty');
  if (options.length < 2) errors.push('Options not detected (<2) — Page ' + (pageHint || '?'));

  return { num: qNum, text: qText.trim(), options, hasParseError: errors.length > 0, parseError: errors.join('; ') };
}

/**
 * F21B Main orchestrator — extract + parse + sync answer key + explanation.
 */
async function buildQuestionsFromPDFs(args) {
  const { questionsPdfPath, answerKeyPdfPath, explanationPdfPath, subjectMapText, pageFrom, pageTo, customDelimiter } = args;

  if (!questionsPdfPath) throw new Error('Question paper PDF is required');
  if (!answerKeyPdfPath) throw new Error('Answer key PDF is required');

  const qPagesRaw = await extractPagesText(questionsPdfPath);
  const { cleanedPages: qPagesClean, repeatingLines } = stripRepeatingLines(qPagesRaw); // F21.2.1

  const from = pageFrom && pageFrom > 0 ? pageFrom - 1 : 0;
  const to   = pageTo && pageTo <= qPagesClean.length ? pageTo : qPagesClean.length;
  const selectedPages = qPagesClean.slice(from, to);

  let pageBoundaries = [];
  let cum = 0;
  selectedPages.forEach(p => { cum += p.length + 1; pageBoundaries.push(cum); });
  const fullQuestionText = selectedPages.join('\n');

  const language = detectLanguage(fullQuestionText); // F21.3.8

  const ansPages = await extractPagesText(answerKeyPdfPath);
  const fullAnswerText = ansPages.join('\n');
  const answerMap = parseAnswerKey(fullAnswerText); // F21.5

  let explanationMap = {};
  if (explanationPdfPath) {
    const explPages = await extractPagesText(explanationPdfPath);
    explanationMap = parseExplanations(explPages.join('\n')); // F21.5.7-5.9
  }

  const subjectMap = parseSubjectRangeMap(subjectMapText); // F21.1.7

  const blocks = splitIntoBlocks(fullQuestionText, customDelimiter); // F21B.3/3.4
  let runningOffset = 0;
  const questions = [];
  const errors = [];
  const seenText = new Set(); // F21.7.6 duplicate-in-this-paper detection

  blocks.forEach((block, idx) => {
    const blockStartOffset = fullQuestionText.indexOf(block, runningOffset);
    const pageNum = pageBoundaries.findIndex(b => blockStartOffset < b) + 1;
    runningOffset = blockStartOffset >= 0 ? blockStartOffset + block.length : runningOffset;

    const parsed = parseOneBlock(block, idx, pageNum || '?');
    const ans = answerMap[parsed.num];
    const correct = ans ? (ans.letters ? ans.letters.map(l => ['A','B','C','D'].indexOf(l)).filter(i => i >= 0) : (ans.numeric !== undefined ? [ans.numeric] : [])) : [];
    const type = ans && ans.numeric !== undefined ? 'Integer' : (ans && ans.letters && ans.letters.length > 1 ? 'MSQ' : 'SCQ');

    const dedupKey = parsed.text.toLowerCase().slice(0, 80);
    const isDuplicate = !!(parsed.text && seenText.has(dedupKey));
    if (parsed.text) seenText.add(dedupKey);

    const rowErrors = [];
    if (parsed.hasParseError) rowErrors.push(parsed.parseError);
    if (correct.length === 0) rowErrors.push('Answer not found for Q' + parsed.num + ' — Page ' + (pageNum || '?'));

    const subject = subjectForQNum(parsed.num, subjectMap);
    const looksLikeDiagram = /diagram|figure|graph shown|image shown/i.test(block); // F21.15

    questions.push({
      num: parsed.num,
      text: parsed.text,
      options: parsed.options,
      correct,
      type,
      subject: subject || '',
      explanation: explanationMap[parsed.num] || '',
      hasError: rowErrors.length > 0,
      error: rowErrors.join('; '),
      needsReview: rowErrors.length > 0 || looksLikeDiagram,        // F21.7.7
      confidencePct: rowErrors.length === 0 ? (looksLikeDiagram ? 60 : 90) : 40, // F21.20
      isDuplicate,
      page: pageNum || null,
      imageFlag: looksLikeDiagram,                                  // F21.15
    });

    if (rowErrors.length > 0) errors.push({ qNum: parsed.num, page: pageNum || null, message: rowErrors.join('; ') });
  });

  return {
    questions,
    errors,
    pageCount: qPagesRaw.length,
    selectedPageRange: { from: from + 1, to },
    language,
    repeatingLinesRemoved: repeatingLines,
    rawTextPreview: fullQuestionText.slice(0, 2000), // F21.2.3
  };
}

// F21.16 OCR fallback scaffold — only attempted if explicitly requested; fails gracefully
// if tesseract.js / system deps are unavailable in the deploy environment (kept optional & safe).
async function ocrFallback(filePath) {
  try {
    const Tesseract = require('tesseract.js');
    const result = await Tesseract.recognize(filePath, 'eng');
    return { success: true, text: result.data.text };
  } catch (e) {
    return { success: false, message: 'OCR not available in this environment: ' + e.message };
  }
}

module.exports = {
  extractPagesText,
  stripRepeatingLines,
  detectLanguage,
  parseSubjectRangeMap,
  subjectForQNum,
  parseAnswerKey,
  parseExplanations,
  splitIntoBlocks,
  parseOneBlock,
  buildQuestionsFromPDFs,
  ocrFallback,
};

CONTENTFORGE_EOF_MARKER
echo "  -> wrote src/utils/pdfQuestionParser.js"

mkdir -p $(dirname "src/utils/examBuilder.js")
cat > "src/utils/examBuilder.js" << 'CONTENTFORGE_EOF_MARKER'
const Question = require('../models/Question');
const Exam = require('../models/Exam');
const Batch = require('../models/Batch');
const StudentNotification = require('../models/StudentNotification');
const User = require('../models/User');

// ══════════════════════════════════════════════════════════════
// Shared "Create Exam from parsed questions" engine — used by
// Feature 19B (paste), 20B (excel), 21B (pdf). Mirrors the proven
// useAsExam() pattern already used elsewhere in this codebase.
// ══════════════════════════════════════════════════════════════

// F19B.5.4 / F20B.5.4 / F21B.8.4 — auto-select N out of M parsed questions,
// honouring subject-wise distribution if provided (F19B.5.5/F20B.5.5/F21B.8.5)
function selectQuestions(parsedList, totalRequested, subjectWiseCount) {
  if (!totalRequested || totalRequested >= parsedList.length) return parsedList;

  if (Array.isArray(subjectWiseCount) && subjectWiseCount.length > 0) {
    const out = [];
    subjectWiseCount.forEach(({ subject, count }) => {
      const pool = parsedList.filter(q => (q.subject || '').toLowerCase() === String(subject || '').toLowerCase());
      out.push(...pool.slice(0, count));
    });
    if (out.length > 0) return out;
  }
  return parsedList.slice(0, totalRequested);
}

// F19B.5.21 / F20B.5.21 / F21B.8.21 — order questions by subject so the live exam
// shows "Q.No X to Y => Subject Z" as continuous ranges, and build `sections[]`.
function orderAndBuildSections(list) {
  const bySubject = {};
  const order = [];
  list.forEach(q => {
    const subj = q.subject || 'General';
    if (!bySubject[subj]) { bySubject[subj] = []; order.push(subj); }
    bySubject[subj].push(q);
  });
  const ordered = [];
  const sections = [];
  let cursor = 1;
  order.forEach(subj => {
    const group = bySubject[subj];
    const from = cursor;
    const to = cursor + group.length - 1;
    sections.push({ name: subj, subject: subj, questionCount: group.length, timeLimit: 0, marks: 0, fromQNo: from, toQNo: to });
    ordered.push(...group);
    cursor = to + 1;
  });
  return { ordered, sections };
}

/**
 * Inserts parsed questions as real Question documents (so they're searchable
 * in QsBank too, per F19B.7.1/F19B.7.4), then creates the Exam linked to them,
 * with a tamper-proof questionSnapshot (same convention as paperGenerator.useAsExam).
 *
 * @param {object} p
 *   parsedQuestions   - array of { text, hindiText, options, hindiOptions, correct, subject,
 *                        chapter, topic, difficulty, type, explanation, hindiExplanation,
 *                        imageUrl, optionImages, tags }
 *   examDetails       - { title, subject, category, type, duration, totalMarks, markingScheme,
 *                          schedule, customInstructions, password, whitelistEnabled, waitingRoomEnabled,
 *                          waitingRoomMinutes, reattemptCount, unlimitedAttempts, reviewWindow,
 *                          watermark, totalQuestionsRequested, subjectWiseCount }
 *   assignment        - { assignmentType, batch, multiBatch, seriesName, notifyStudents }
 *   postCreate         - { scheduledPublish, isTemplate, status }
 *   sourceMeta        - { sourceType, fileName, uploadedAt, pageCount, totalParsed, totalErrors, totalDuplicates }
 *   createdBy         - user id
 */
async function createExamFromQuestions({ parsedQuestions, examDetails, assignment, postCreate, sourceMeta, createdBy }) {
  if (!Array.isArray(parsedQuestions) || parsedQuestions.length === 0) {
    throw new Error('No questions to create exam with');
  }

  // F19B.5.4/20B.5.4/21B.8.4 + F19B.5.5/20B.5.5/21B.8.5
  const selected = selectQuestions(parsedQuestions, examDetails.totalQuestionsRequested, examDetails.subjectWiseCount);
  const { ordered, sections } = orderAndBuildSections(selected); // F19B.5.21/20B.5.21/21B.8.21

  // Insert as real Question docs (F19B.7.1 "creates exam with questions[]")
  const docs = ordered.map(q => ({
    text: q.text,
    hindiText: q.hindiText || '',
    options: q.options,
    hindiOptions: q.hindiOptions || [],
    correct: q.correct,
    subject: q.subject || 'General',
    chapter: q.chapter || '',
    topic: q.topic || '',
    difficulty: q.difficulty || 'Medium',
    type: q.type || 'SCQ',
    explanation: q.explanation || '',
    hindiExplanation: q.hindiExplanation || '',
    imageUrl: q.imageUrl || '',
    optionImages: q.optionImages || [],
    tags: q.tags || [],
    isPYQ: false,
    sourceExam: examDetails.title || '',
    createdBy,
  }));

  const inserted = await Question.insertMany(docs);

  // questionSnapshot — tamper-proof copy shown live (same convention as paperGenerator.useAsExam)
  const questionSnapshot = inserted.map((doc, i) => ({
    _id: doc._id,
    text: doc.text,
    hindiText: doc.hindiText,
    options: doc.options,
    hindiOptions: doc.hindiOptions,
    correct: doc.correct,
    subject: doc.subject,
    type: doc.type,
    explanation: doc.explanation,
    hindiExplanation: doc.hindiExplanation,
    imageUrl: doc.imageUrl,
    optionImages: doc.optionImages,
  }));

  const totalMarks = examDetails.totalMarks || (ordered.length * (examDetails.markingScheme?.correct || 4));

  // F19B.6 / F20B.6 / F21B.9 — Assignment Type resolution
  const assignmentType = assignment.assignmentType || 'individual';
  let category = examDetails.category || 'Full Mock';
  if (assignmentType === 'mini_test') category = 'Mini Test'; // F19B.6.3/20B.6.3/21B.9.3

  // F19B.5.16 / F20B.5.16 / F21B.8.16 — Unlimited attempts -> large maxAttempts (no other code needs to change)
  const maxAttempts = examDetails.unlimitedAttempts ? 99999 : (examDetails.maxAttempts || 1);

  const exam = await Exam.create({
    title: examDetails.title,
    subject: examDetails.subject || sections[0]?.subject || 'NEET',
    duration: examDetails.duration, // F19B.5.7/20B.5.7/21B.8.7 ⚠️ field name "duration", NOT totalDurationSec
    totalMarks,
    questions: inserted.map(d => d._id),
    sections,
    markingScheme: examDetails.markingScheme || { correct: 4, incorrect: -1, unattempted: 0 },
    password: examDetails.password || '',
    schedule: examDetails.schedule || {},
    category,
    batch: assignmentType === 'batch' || assignmentType === 'series' ? (assignment.batch || '') : '',
    multiBatch: assignment.multiBatch || [],
    assignmentType,
    seriesName: assignment.seriesName || '',
    watermark: examDetails.watermark !== false,
    customInstructions: examDetails.customInstructions || '',
    reviewWindow: examDetails.reviewWindow || { enabled: false, durationMinutes: 0 },
    type: examDetails.type || 'NEET',
    waitingRoomEnabled: !!examDetails.waitingRoomEnabled,
    waitingRoomMinutes: examDetails.waitingRoomMinutes || 10,
    maxAttempts,
    unlimitedAttempts: !!examDetails.unlimitedAttempts,
    reattemptCount: examDetails.reattemptCount || 'last',
    questionSnapshot,
    whitelistEnabled: !!examDetails.whitelistEnabled,
    whitelistedStudents: examDetails.whitelistedStudents || [],
    whitelistedGroups: examDetails.whitelistedGroups || [],
    subjectWiseCount: examDetails.subjectWiseCount || [],
    totalQuestionsRequested: examDetails.totalQuestionsRequested || 0,
    scheduledPublish: postCreate?.scheduledPublish || { enabled: false, publishAt: null },
    notifyStudents: !!assignment.notifyStudents,
    isTemplate: !!postCreate?.isTemplate,
    sourceMeta: sourceMeta || {},
    createdBy,
    // F19B.7.3 — Do NOT send `status`; schema default 'draft' applies UNLESS explicit publish-now requested
    ...(postCreate?.status ? { status: postCreate.status } : {})
  });

  await Question.updateMany({ _id: { $in: inserted.map(d => d._id) } }, { $inc: { usageCount: 1 } }).catch(() => {});

  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle
  let notifiedCount = 0;
  if (assignment.notifyStudents && assignment.batch) {
    try {
      const students = await User.find({ batch: assignment.batch, role: 'student' }).select('_id');
      const notifs = students.map(s => ({
        userId: s._id,
        batchId: assignment.batch,
        type: 'batch_update', // reuse existing enum value (no model changes needed)
        title: 'New Exam Published',
        message: `A new exam "${exam.title}" has been added to your batch.`,
        link: `/exam/${exam._id}`,
      }));
      if (notifs.length > 0) { await StudentNotification.insertMany(notifs); notifiedCount = notifs.length; }
    } catch (e) { /* notification failure should never block exam creation */ }
  }

  return { exam, questionsCreated: inserted.length, notifiedCount };
}

module.exports = { createExamFromQuestions, selectQuestions, orderAndBuildSections };

CONTENTFORGE_EOF_MARKER
echo "  -> wrote src/utils/examBuilder.js"

mkdir -p $(dirname "src/routes/contentForge.js")
cat > "src/routes/contentForge.js" << 'CONTENTFORGE_EOF_MARKER'
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

CONTENTFORGE_EOF_MARKER
echo "  -> wrote src/routes/contentForge.js"

echo ""
echo "[3/3] Syntax check..."
ALL_OK=1
node --check "src/models/Exam.js" && echo "  [OK] src/models/Exam.js" || { echo "  [FAIL] src/models/Exam.js"; ALL_OK=0; }
node --check "src/models/Question.js" && echo "  [OK] src/models/Question.js" || { echo "  [FAIL] src/models/Question.js"; ALL_OK=0; }
node --check "src/models/ContentForgeImportLog.js" && echo "  [OK] src/models/ContentForgeImportLog.js" || { echo "  [FAIL] src/models/ContentForgeImportLog.js"; ALL_OK=0; }
node --check "src/utils/excelParser.js" && echo "  [OK] src/utils/excelParser.js" || { echo "  [FAIL] src/utils/excelParser.js"; ALL_OK=0; }
node --check "src/utils/pdfQuestionParser.js" && echo "  [OK] src/utils/pdfQuestionParser.js" || { echo "  [FAIL] src/utils/pdfQuestionParser.js"; ALL_OK=0; }
node --check "src/utils/examBuilder.js" && echo "  [OK] src/utils/examBuilder.js" || { echo "  [FAIL] src/utils/examBuilder.js"; ALL_OK=0; }
node --check "src/routes/contentForge.js" && echo "  [OK] src/routes/contentForge.js" || { echo "  [FAIL] src/routes/contentForge.js"; ALL_OK=0; }

echo ""
if [ $ALL_OK -eq 1 ]; then
  echo "✅ PATCH INSTALL COMPLETE — Import History (20.15) backend ready"
else
  echo "⚠️  SOME FILES FAILED SYNTAX CHECK"
fi
echo "NOTE: Restart your server for changes to take effect."