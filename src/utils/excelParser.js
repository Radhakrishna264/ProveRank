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

