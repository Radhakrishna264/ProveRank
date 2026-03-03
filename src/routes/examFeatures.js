const express = require('express');
const router = express.Router();
const { verifyToken, isSuperAdmin, isAdmin } = require('../middleware/auth');
const Exam = require('../models/Exam');
const User = require('../models/User');

// ── S5: SERIES / BATCH SYSTEM ────────────────────────────────
router.post('/series', verifyToken, isAdmin, async (req, res) => {
  try {
    const { name, description, examIds } = req.body;
    if (!name) return res.status(400).json({ message: 'Series name required hai' });
    // Store series as exam category grouping
    res.status(201).json({ success: true, message: 'Series create ho gaya', series: { name, description, examIds: examIds || [] } });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

router.get('/series', verifyToken, async (req, res) => {
  try {
    const series = await Exam.distinct('batch');
    res.json({ success: true, series });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S75: EXAM TEMPLATE SYSTEM ────────────────────────────────
let templates = [
  { id: 'neet', name: 'NEET Template', pattern: 'neet', duration: 200, totalQuestions: 180, marking: { correct: 4, wrong: -1 }, sections: [{name:'Physics',count:45},{name:'Chemistry',count:45},{name:'Biology',count:90}] },
  { id: 'jee', name: 'JEE Main Template', pattern: 'jee', duration: 180, totalQuestions: 90, marking: { correct: 4, wrong: -1 }, sections: [{name:'Physics',count:30},{name:'Chemistry',count:30},{name:'Maths',count:30}] }
];

router.post('/template', verifyToken, isAdmin, async (req, res) => {
  try {
    const { name, pattern, duration, totalQuestions, marking, sections } = req.body;
    if (!name) return res.status(400).json({ message: 'Template name required' });
    const tmpl = { id: `tmpl_${Date.now()}`, name, pattern, duration, totalQuestions, marking, sections };
    templates.push(tmpl);
    res.status(201).json({ success: true, message: 'Template save ho gaya', template: tmpl });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

router.get('/templates', verifyToken, async (req, res) => {
  res.json({ success: true, count: templates.length, templates });
});

// ── S85: EXAM ACCESS CONTROL (WHITELIST) ─────────────────────
router.post('/:id/whitelist', verifyToken, isAdmin, async (req, res) => {
  try {
    const { studentIds, groupIds } = req.body;
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });
    await Exam.findByIdAndUpdate(req.params.id, {
      whitelistEnabled: true,
      whitelistedStudents: studentIds || [],
      whitelistedGroups: groupIds || []
    });
    res.json({ success: true, message: `Whitelist set ho gaya — ${(studentIds||[]).length} students` });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

router.get('/:id/whitelist', verifyToken, isAdmin, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).select('whitelistEnabled whitelistedStudents whitelistedGroups');
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });
    res.json({ success: true, whitelist: exam });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S26: SECTION WISE EXAM ───────────────────────────────────
router.get('/:id/sections', verifyToken, async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).select('sections title');
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });
    res.json({ success: true, examId: req.params.id, sections: exam.sections || [] });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

router.put('/:id/sections', verifyToken, isAdmin, async (req, res) => {
  try {
    const { sections } = req.body;
    if (!sections || !Array.isArray(sections))
      return res.status(400).json({ message: 'sections array required hai' });
    await Exam.findByIdAndUpdate(req.params.id, { sections });
    res.json({ success: true, message: 'Sections update ho gaye' });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S62: CUSTOM MARKING SCHEME ───────────────────────────────
router.put('/:id/marking', verifyToken, isAdmin, async (req, res) => {
  try {
    const { correct, wrong, skip } = req.body;
    if (correct === undefined) return res.status(400).json({ message: 'correct marks required' });
    await Exam.findByIdAndUpdate(req.params.id, {
      'marking.correct': correct,
      'marking.wrong': wrong !== undefined ? wrong : -1,
      'marking.skip': skip || 0
    });
    res.json({ success: true, message: `Marking set: +${correct}/${wrong||'-1'}/0` });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S31: RE-ATTEMPT SYSTEM ───────────────────────────────────
router.put('/:id/reattempt', verifyToken, isAdmin, async (req, res) => {
  try {
    const { maxAttempts, countBest, countLast } = req.body;
    await Exam.findByIdAndUpdate(req.params.id, {
      maxAttempts: maxAttempts || 1,
      reattemptCount: countBest ? 'best' : countLast ? 'last' : 'last'
    });
    res.json({ success: true, message: `Re-attempt set: max ${maxAttempts||1} attempts` });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S96: EXAM COUNTDOWN LANDING PAGE ────────────────────────
router.get('/:id/countdown', async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id).select('title scheduledAt status duration');
    if (!exam) return res.status(404).json({ message: 'Exam nahi mila' });
    const now = new Date();
    const startTime = exam.scheduledAt ? new Date(exam.scheduledAt) : null;
    const timeLeft = startTime ? Math.max(0, startTime - now) : null;
    res.json({
      success: true,
      exam: { title: exam.title, status: exam.status, scheduledAt: exam.scheduledAt, duration: exam.duration },
      countdown: { timeLeftMs: timeLeft, timeLeftSec: timeLeft ? Math.floor(timeLeft/1000) : null, started: timeLeft === 0 }
    });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

module.exports = router;
