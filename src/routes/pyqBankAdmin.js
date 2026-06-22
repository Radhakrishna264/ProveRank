const express = require('express');
const router  = express.Router();
const mongoose = require('mongoose');
const multer  = require('multer');
const XLSX    = require('xlsx');
const pdfParse = require('pdf-parse');
const { verifyToken, isAdmin } = require('../middleware/auth');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });

// ── Default exam cards (always shown) ──────────────────────────────────────────
const DEFAULT_CARDS = [
  { name:'NEET',           icon:'🩺', color:'#00C48C', desc:'National Eligibility cum Entrance Test',              isDefault:true, order:1 },
  { name:'JEE Main',       icon:'⚙️', color:'#4D9FFF', desc:'Joint Entrance Examination - Main',                   isDefault:true, order:2 },
  { name:'JEE Advanced',   icon:'🚀', color:'#A78BFA', desc:'Joint Entrance Examination - Advanced',               isDefault:true, order:3 },
  { name:'CUET UG',        icon:'🎓', color:'#FFD700', desc:'Common University Entrance Test - UG',                isDefault:true, order:4 },
  { name:'RPSC 1st Grade', icon:'🏛️', color:'#FF6B6B', desc:'Rajasthan Public Service Commission - 1st Grade',    isDefault:true, order:5 },
  { name:'RPSC 2nd Grade', icon:'🏫', color:'#FF9F43', desc:'Rajasthan Public Service Commission - 2nd Grade',    isDefault:true, order:6 },
  { name:'RBSE Class X',   icon:'📗', color:'#00D2D3', desc:'Rajasthan Board of Secondary Education - Class 10',  isDefault:true, order:7 },
  { name:'RBSE Class XI-XII', icon:'📘', color:'#5F27CD', desc:'Rajasthan Board - Class 11 & 12',                 isDefault:true, order:8 },
  { name:'CBSE Class X-XII',  icon:'📕', color:'#ee5a24', desc:'Central Board of Secondary Education - Class 10, 11, 12', isDefault:true, order:9 },
];

// ── Helper: get stats for an exam name ──────────────────────────────────────────
async function getExamStats(examName) {
  const Question    = mongoose.model('Question');
  const PYQYearCard = mongoose.model('PYQYearCard');
  const years  = await PYQYearCard.find({ examName }).sort({ year: -1 });
  const totalQ = await Question.countDocuments({ isPYQ: true, pyqExam: examName });
  const solved = await Question.countDocuments({ isPYQ: true, pyqExam: examName, 'usageCount': { $gt: 0 } });
  const lastDoc = await Question.findOne({ isPYQ: true, pyqExam: examName }).sort({ updatedAt: -1 }).select('updatedAt');
  return {
    totalYears:    years.length,
    totalPapers:   years.reduce((s, y) => s + (y.paperCount || 0), 0),
    totalQuestions: totalQ,
    solvedCount:   solved,
    lastUpdated:   lastDoc ? lastDoc.updatedAt : null,
    years
  };
}

// ════════════════════ EXAM CARD ROUTES ══════════════════════════════════════════

// GET all exam cards (default + custom) + stats
router.get('/exam-cards', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQExamCard = mongoose.model('PYQExamCard');
    const Question    = mongoose.model('Question');
    const PYQYearCard = mongoose.model('PYQYearCard');
    // Seed defaults if not present
    for (const dc of DEFAULT_CARDS) {
      await PYQExamCard.findOneAndUpdate({ name: dc.name }, { $setOnInsert: dc }, { upsert: true, new: true });
    }
    const cards = await PYQExamCard.find().sort({ order: 1, createdAt: 1 });
    // Attach stats to each card
    const statsPromises = cards.map(async c => {
      const totalQ = await Question.countDocuments({ isPYQ: true, pyqExam: c.name });
      const years  = await PYQYearCard.countDocuments({ examName: c.name });
      const lastDoc = await Question.findOne({ isPYQ: true, pyqExam: c.name }).sort({ updatedAt: -1 }).select('updatedAt');
      return {
        _id: c._id, name: c.name, icon: c.icon, color: c.color, desc: c.desc,
        isDefault: c.isDefault, order: c.order,
        stats: { totalYears: years, totalQuestions: totalQ, lastUpdated: lastDoc ? lastDoc.updatedAt : null }
      };
    });
    const examCards = await Promise.all(statsPromises);
    res.json({ success: true, examCards });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// POST create new exam card
router.post('/exam-cards', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQExamCard = mongoose.model('PYQExamCard');
    const { name, icon, color, desc } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ success: false, message: 'Name required' });
    const exists = await PYQExamCard.findOne({ name: name.trim() });
    if (exists) return res.status(400).json({ success: false, message: 'Exam card already exists' });
    const card = await PYQExamCard.create({ name: name.trim(), icon: icon || '📚', color: color || '#4D9FFF', desc: desc || '', createdBy: req.user.id });
    res.json({ success: true, message: 'Exam card created', card });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// PUT update exam card
router.put('/exam-cards/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQExamCard = mongoose.model('PYQExamCard');
    const { name, icon, color, desc } = req.body;
    const card = await PYQExamCard.findByIdAndUpdate(req.params.id, { name, icon, color, desc }, { new: true });
    if (!card) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, message: 'Updated', card });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// DELETE exam card + its year cards + questions
router.delete('/exam-cards/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQExamCard = mongoose.model('PYQExamCard');
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const card = await PYQExamCard.findById(req.params.id);
    if (!card) return res.status(404).json({ success: false, message: 'Not found' });
    if (card.isDefault) return res.status(400).json({ success: false, message: 'Cannot delete default exam card. Edit it instead.' });
    await PYQYearCard.deleteMany({ examName: card.name });
    const qDel = await Question.deleteMany({ isPYQ: true, pyqExam: card.name });
    await PYQExamCard.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: `Deleted "${card.name}" — ${qDel.deletedCount} questions removed`, deletedQuestions: qDel.deletedCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// GET stats for one exam card
router.get('/exam-cards/:examName/stats', verifyToken, isAdmin, async (req, res) => {
  try {
    const stats = await getExamStats(decodeURIComponent(req.params.examName));
    res.json({ success: true, ...stats });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════ YEAR CARD ROUTES ══════════════════════════════════════════

// GET year cards for an exam
router.get('/exam-cards/:examName/years', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const examName = decodeURIComponent(req.params.examName);
    const years = await PYQYearCard.find({ examName }).sort({ year: -1 });
    // Attach question counts
    const withCounts = await Promise.all(years.map(async y => {
      const qCount = await Question.countDocuments({ isPYQ: true, pyqExam: examName, pyqYear: y.year });
      return { ...y.toObject(), questionCount: qCount };
    }));
    res.json({ success: true, yearCards: withCounts });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// POST create year card
router.post('/exam-cards/:examName/years', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const examName = decodeURIComponent(req.params.examName);
    const { year, status, notes } = req.body;
    if (!year) return res.status(400).json({ success: false, message: 'Year required' });
    const exists = await PYQYearCard.findOne({ examName, year: parseInt(year) });
    if (exists) return res.status(400).json({ success: false, message: `Year ${year} already exists for ${examName}` });
    const yc = await PYQYearCard.create({ examName, year: parseInt(year), status: status || 'Empty', notes: notes || '', createdBy: req.user.id });
    res.json({ success: true, message: 'Year card created', yearCard: yc });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// PUT update year card
router.put('/years/:yearId', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const { status, notes, paperCount } = req.body;
    const yc = await PYQYearCard.findByIdAndUpdate(req.params.yearId, { status, notes, paperCount }, { new: true });
    if (!yc) return res.status(404).json({ success: false, message: 'Year card not found' });
    res.json({ success: true, message: 'Updated', yearCard: yc });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// DELETE year card + its questions
router.delete('/years/:yearId', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const yc = await PYQYearCard.findById(req.params.yearId);
    if (!yc) return res.status(404).json({ success: false, message: 'Year card not found' });
    const qDel = await Question.deleteMany({ isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year });
    await PYQYearCard.findByIdAndDelete(req.params.yearId);
    res.json({ success: true, message: `Year ${yc.year} deleted — ${qDel.deletedCount} questions removed`, deletedQuestions: qDel.deletedCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════ QUESTION ROUTES ══════════════════════════════════════════

// GET questions for a year card (with filters)
router.get('/years/:yearId/questions', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const yc = await PYQYearCard.findById(req.params.yearId);
    if (!yc) return res.status(404).json({ success: false, message: 'Year card not found' });
    const { subject, chapter, difficulty, search, page = 1, limit = 50 } = req.query;
    const filter = { isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year };
    if (subject)    filter.subject = subject;
    if (chapter)    filter.chapter = { $regex: chapter, $options: 'i' };
    if (difficulty) filter.difficulty = difficulty;
    if (search)     filter.$or = [{ text: { $regex: search, $options: 'i' } }, { hindiText: { $regex: search, $options: 'i' } }];
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const questions = await Question.find(filter).skip(skip).limit(parseInt(limit)).sort({ subject: 1, createdAt: 1 });
    const total     = await Question.countDocuments(filter);
    const subjects  = await Question.distinct('subject', { isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year });
    const chapters  = await Question.distinct('chapter',  { isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year });
    res.json({ success: true, total, questions, availableSubjects: subjects, availableChapters: chapters.filter(Boolean), yearCard: yc });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// POST manual add single question
router.post('/years/:yearId/questions', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const yc = await PYQYearCard.findById(req.params.yearId);
    if (!yc) return res.status(404).json({ success: false, message: 'Year card not found' });
    const { text, hindiText, options, correct, subject, chapter, difficulty, explanation, hindiExplanation } = req.body;
    if (!text || !text.trim()) return res.status(400).json({ success: false, message: 'Question text required' });
    if (!options || options.length < 2) return res.status(400).json({ success: false, message: 'At least 2 options required' });
    const q = await Question.create({
      text: text.trim(), hindiText: hindiText || '', options, correct: correct || [0],
      subject: subject || 'General', chapter: chapter || '', difficulty: difficulty || 'Medium',
      explanation: explanation || '', hindiExplanation: hindiExplanation || '',
      isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year,
      pyqYearCardId: yc._id, createdBy: req.user.id,
      tags: ['PYQ', yc.examName, String(yc.year)]
    });
    // Update year card status to at least Partial
    if (yc.status === 'Empty') await PYQYearCard.findByIdAndUpdate(yc._id, { status: 'Partial' });
    res.json({ success: true, message: 'Question added', question: q });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════ UPLOAD ROUTES ══════════════════════════════════════════

// ── Copy-Paste Upload ──────────────────────────────────────────────────────────
router.post('/years/:yearId/upload/copypaste', verifyToken, isAdmin, async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const yc = await PYQYearCard.findById(req.params.yearId);
    if (!yc) return res.status(404).json({ success: false, message: 'Year card not found' });
    const { questionsText, answerKeyText } = req.body;
    if (!questionsText || !questionsText.trim()) return res.status(400).json({ success: false, message: 'Questions text required' });

    // Parse answer key
    const answerMap = {};
    if (answerKeyText) {
      answerKeyText.split('\n').forEach(line => {
        const m = line.match(/^(\d+)[.\-\)]\s*([A-Da-d1-4])/);
        if (m) {
          const num = parseInt(m[1]);
          const ans = m[2].toUpperCase();
          answerMap[num] = ['A','B','C','D'].indexOf(ans) !== -1 ? ['A','B','C','D'].indexOf(ans) : (parseInt(ans) - 1);
        }
      });
    }

    // Parse questions
    const blocks = questionsText.split(/\n(?=\d+[\.\)]\s)/);
    const parsed = [];
    blocks.forEach((block, idx) => {
      const lines = block.trim().split('\n').filter(l => l.trim());
      if (lines.length < 2) return;
      const qNumMatch = lines[0].match(/^(\d+)[\.\)]\s*(.*)/);
      if (!qNumMatch) return;
      const qNum  = parseInt(qNumMatch[1]);
      let qText   = qNumMatch[2].trim();
      const opts  = [];
      let explanation = '';
      lines.slice(1).forEach(line => {
        const optMatch = line.match(/^([A-Da-d][\.\)]\s*)(.*)/);
        if (optMatch) { opts.push(optMatch[2].trim()); }
        else if (/^(ans|answer|sol|solution|exp|explanation)[:\s]/i.test(line)) { explanation = line.replace(/^[^:]+:\s*/i, ''); }
        else if (opts.length === 0) { qText += ' ' + line.trim(); }
      });
      if (qText && opts.length >= 2) {
        const correct = answerMap[qNum] !== undefined ? answerMap[qNum] : 0;
        parsed.push({ qNum, text: qText.trim(), options: opts, correct: [correct], explanation });
      }
    });

    if (parsed.length === 0) return res.status(400).json({ success: false, message: 'No questions could be parsed. Check format.' });

    let saved = 0;
    for (const p of parsed) {
      try {
        await Question.create({
          text: p.text, options: p.options, correct: p.correct,
          explanation: p.explanation, subject: 'General', chapter: '', difficulty: 'Medium',
          isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year,
          pyqYearCardId: yc._id, createdBy: req.user.id,
          tags: ['PYQ', yc.examName, String(yc.year)]
        });
        saved++;
      } catch (e) { /* skip duplicates */ }
    }
    if (yc.status === 'Empty' && saved > 0) await PYQYearCard.findByIdAndUpdate(yc._id, { status: 'Partial' });
    res.json({ success: true, message: `${saved} questions uploaded from copy-paste`, saved, parsed: parsed.length, failed: parsed.length - saved });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ── Excel Upload ───────────────────────────────────────────────────────────────
router.post('/years/:yearId/upload/excel', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const yc = await PYQYearCard.findById(req.params.yearId);
    if (!yc) return res.status(404).json({ success: false, message: 'Year card not found' });
    if (!req.file)  return res.status(400).json({ success: false, message: 'Excel file required' });
    const wb   = XLSX.read(req.file.buffer, { type: 'buffer' });
    const ws   = wb.Sheets[wb.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(ws, { defval: '' });
    if (rows.length === 0) return res.status(400).json({ success: false, message: 'Empty Excel file' });

    let saved = 0, failed = 0, errors = [];
    for (const row of rows) {
      const text = row['Question'] || row['question'] || row['Q'] || '';
      if (!text.toString().trim()) { failed++; continue; }
      const optA = row['Option A'] || row['option_a'] || row['A'] || '';
      const optB = row['Option B'] || row['option_b'] || row['B'] || '';
      const optC = row['Option C'] || row['option_c'] || row['C'] || '';
      const optD = row['Option D'] || row['option_d'] || row['D'] || '';
      const correctRaw = (row['Correct Answer'] || row['correct'] || row['Answer'] || 'A').toString().toUpperCase().trim();
      const correctIdx = ['A','B','C','D'].indexOf(correctRaw);
      const options = [optA, optB, optC, optD].map(o => o.toString().trim()).filter(o => o);
      if (options.length < 2) { failed++; errors.push(`Row: "${text.toString().substring(0,40)}..." - Not enough options`); continue; }
      try {
        await Question.create({
          text: text.toString().trim(),
          options, correct: [correctIdx >= 0 ? correctIdx : 0],
          subject:     (row['Subject']     || row['subject']     || 'General').toString().trim(),
          chapter:     (row['Chapter']     || row['chapter']     || '').toString().trim(),
          difficulty:  (row['Difficulty']  || row['difficulty']  || 'Medium').toString().trim(),
          explanation: (row['Explanation'] || row['explanation'] || '').toString().trim(),
          hindiText:   (row['Hindi Question'] || row['hindi_text'] || '').toString().trim(),
          isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year,
          pyqYearCardId: yc._id, createdBy: req.user.id,
          tags: ['PYQ', yc.examName, String(yc.year)]
        });
        saved++;
      } catch (e) { failed++; errors.push(e.message); }
    }
    if (yc.status === 'Empty' && saved > 0) await PYQYearCard.findByIdAndUpdate(yc._id, { status: 'Partial' });
    res.json({ success: true, message: `${saved} questions uploaded from Excel`, saved, failed, errors: errors.slice(0, 5) });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ── PDF Upload ─────────────────────────────────────────────────────────────────
router.post('/years/:yearId/upload/pdf', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    const PYQYearCard = mongoose.model('PYQYearCard');
    const Question    = mongoose.model('Question');
    const yc = await PYQYearCard.findById(req.params.yearId);
    if (!yc) return res.status(404).json({ success: false, message: 'Year card not found' });
    if (!req.file) return res.status(400).json({ success: false, message: 'PDF file required' });
    const pdfData = await pdfParse(req.file.buffer);
    const text    = pdfData.text || '';
    if (!text.trim()) return res.status(400).json({ success: false, message: 'Could not extract text from PDF. Ensure it is not a scanned image.' });

    // Split on question numbers
    const blocks = text.split(/\n(?=\d+[\.\)]\s)/);
    const parsed = [];
    blocks.forEach(block => {
      const lines = block.trim().split('\n').filter(l => l.trim());
      if (lines.length < 2) return;
      const qNumMatch = lines[0].match(/^(\d+)[\.\)]\s*(.*)/);
      if (!qNumMatch) return;
      let qText = qNumMatch[2].trim();
      const opts = [];
      lines.slice(1).forEach(line => {
        const optMatch = line.match(/^([A-Da-d][\.\)]\s*)(.*)/);
        if (optMatch) opts.push(optMatch[2].trim());
        else if (opts.length === 0) qText += ' ' + line.trim();
      });
      if (qText && opts.length >= 2) parsed.push({ text: qText.trim(), options: opts, correct: [0] });
    });

    if (parsed.length === 0) return res.status(400).json({ success: false, message: 'No questions found in PDF. Ensure format: "1. Question text\\nA. option..."' });

    let saved = 0;
    for (const p of parsed) {
      try {
        await Question.create({
          text: p.text, options: p.options, correct: p.correct,
          subject: 'General', chapter: '', difficulty: 'Medium',
          isPYQ: true, pyqExam: yc.examName, pyqYear: yc.year,
          pyqYearCardId: yc._id, createdBy: req.user.id,
          tags: ['PYQ', yc.examName, String(yc.year)]
        });
        saved++;
      } catch (e) { /* skip */ }
    }
    if (yc.status === 'Empty' && saved > 0) await PYQYearCard.findByIdAndUpdate(yc._id, { status: 'Partial' });
    res.json({ success: true, message: `${saved} questions extracted from PDF`, saved, parsed: parsed.length, failed: parsed.length - saved, pages: pdfData.numpages });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
