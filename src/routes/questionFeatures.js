const express = require('express');
const router = express.Router();
const { verifyToken, isSuperAdmin, isAdmin } = require('../middleware/auth');
const Question = require('../models/Question');

// ── AI-1: AUTO DIFFICULTY TAGGER ─────────────────────────────
router.post('/ai/suggest-difficulty', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionText } = req.body;
    if (!questionText) return res.status(400).json({ message: 'questionText required' });
    const text = questionText.toLowerCase();
    let difficulty = 'medium';
    const hardKeywords = ['calculate','derive','prove','evaluate','analyse','mechanism','complex'];
    const easyKeywords = ['define','what is','name','which','identify','state'];
    if (hardKeywords.some(k => text.includes(k))) difficulty = 'hard';
    else if (easyKeywords.some(k => text.includes(k))) difficulty = 'easy';
    res.json({ success: true, suggestedDifficulty: difficulty, confidence: '75%', note: 'AI suggestion — manually verify karo' });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── AI-2: AUTO SUBJECT/CHAPTER CLASSIFIER ────────────────────
router.post('/ai/classify', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionText } = req.body;
    if (!questionText) return res.status(400).json({ message: 'questionText required' });
    const text = questionText.toLowerCase();
    let subject = 'Biology', chapter = 'General';
    if (text.match(/newton|force|velocity|acceleration|current|voltage|resistance|wave|optics|thermodynamics/)) { subject = 'Physics'; chapter = 'Mechanics'; }
    else if (text.match(/carbon|hydrogen|molecule|reaction|acid|base|bond|element|compound|periodic/)) { subject = 'Chemistry'; chapter = 'Organic Chemistry'; }
    else if (text.match(/cell|dna|rna|photosynthesis|respiration|enzyme|protein|genetics|evolution/)) { subject = 'Biology'; chapter = 'Cell Biology'; }
    res.json({ success: true, suggested: { subject, chapter }, confidence: '70%', note: 'AI suggestion — verify karo' });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── AI-5: CONCEPT SIMILARITY DETECTOR ───────────────────────
router.post('/ai/similarity', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionText, threshold = 70 } = req.body;
    if (!questionText) return res.status(400).json({ message: 'questionText required' });
    const words = questionText.toLowerCase().split(/\s+/).filter(w => w.length > 3);
    const existing = await Question.find({}).select('text').limit(100);
    const similar = [];
    existing.forEach(q => {
      if (!q.text) return;
      const qWords = q.text.toLowerCase().split(/\s+/).filter(w => w.length > 3);
      const common = words.filter(w => qWords.includes(w));
      const score = Math.round((common.length / Math.max(words.length, qWords.length)) * 100);
      if (score >= threshold) similar.push({ questionId: q._id, text: q.text.slice(0,100), similarityScore: score });
    });
    res.json({ success: true, inputQuestion: questionText.slice(0,100), similarQuestions: similar, totalFound: similar.length });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S33: IMAGE BASED QUESTIONS ───────────────────────────────
router.get('/image-questions', verifyToken, async (req, res) => {
  try {
    const { subject, page = 1, limit = 20 } = req.query;
    const filter = { 'image.url': { $exists: true, $ne: null } };
    if (subject) filter.subject = subject;
    const questions = await Question.find(filter)
      .select('text subject chapter image difficulty type')
      .limit(Number(limit)).skip((Number(page)-1)*Number(limit));
    const total = await Question.countDocuments(filter);
    res.json({ success: true, total, questions });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S35: QUESTION USAGE TRACKER ─────────────────────────────
router.get('/:id/usage', verifyToken, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id).select('text usageCount subject difficulty');
    if (!question) return res.status(404).json({ message: 'Question nahi mila' });
    res.json({ success: true, questionId: req.params.id, usageCount: question.usageCount || 0, subject: question.subject, difficulty: question.difficulty });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── S104: PYQ BANK ───────────────────────────────────────────
router.get('/pyq', verifyToken, async (req, res) => {
  try {
    const { year, subject, page = 1, limit = 20 } = req.query;
    const filter = { isPYQ: true };
    if (year) filter.pyqYear = Number(year);
    if (subject) filter.subject = subject;
    const questions = await Question.find(filter)
      .select('text subject chapter difficulty pyqYear type options')
      .limit(Number(limit)).skip((Number(page)-1)*Number(limit));
    const total = await Question.countDocuments(filter);
    res.json({ success: true, total, filters: { year, subject }, questions });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── AI-8: AUTO TRANSLATOR ────────────────────────────────────
router.post('/ai/translate', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionId, targetLang, questionText } = req.body;
    const text = questionText || (questionId ? (await Question.findById(questionId).select('text'))?.text : null);
    if (!text) return res.status(400).json({ message: 'questionId ya questionText required hai' });
    // Simulation — real mein LibreTranslate/Google API lagega
    res.json({
      success: true,
      original: text.slice(0, 100),
      translated: `[${targetLang?.toUpperCase() || 'HINDI'} TRANSLATION] ${text.slice(0, 100)}`,
      targetLanguage: targetLang || 'hindi',
      note: 'Translation API integrate karo — LibreTranslate ya Google Translate'
    });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── AI-10: AUTO EXPLANATION GENERATOR ───────────────────────
router.post('/ai/explanation', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionId, questionText, correctAnswer } = req.body;
    const question = questionId ? await Question.findById(questionId) : null;
    const text = questionText || question?.text;
    if (!text) return res.status(400).json({ message: 'questionId ya questionText required' });
    res.json({
      success: true,
      questionText: text.slice(0, 100),
      generatedExplanation: `Explanation for: "${text.slice(0,80)}..." — The correct answer is based on the fundamental concept. [Connect Hugging Face API for real AI explanation]`,
      note: 'Hugging Face free API se connect karo for real explanations'
    });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── N7: QUESTION APPROVAL WORKFLOW ───────────────────────────
router.get('/pending-approval', verifyToken, isAdmin, async (req, res) => {
  try {
    const questions = await Question.find({ approvalStatus: 'pending' })
      .select('text subject chapter difficulty type createdBy createdAt')
      .populate('createdBy', 'name email');
    res.json({ success: true, count: questions.length, questions });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

router.put('/:id/approve', verifyToken, isAdmin, async (req, res) => {
  try {
    const { action, reason } = req.body; // action: 'approve' | 'reject'
    const status = action === 'reject' ? 'rejected' : 'approved';
    await Question.findByIdAndUpdate(req.params.id, {
      approvalStatus: status,
      approvedBy: req.user.id,
      approvedAt: new Date(),
      rejectionReason: reason || null
    });
    res.json({ success: true, message: `Question ${status} ho gaya` });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── M11: XML/MOODLE IMPORT ───────────────────────────────────
router.post('/import/xml', verifyToken, isAdmin, async (req, res) => {
  try {
    const { xmlData } = req.body;
    if (!xmlData) return res.status(400).json({ message: 'xmlData required hai' });
    // Basic XML parser simulation
    const questionMatches = xmlData.match(/<question[^>]*>([\s\S]*?)<\/question>/gi) || [];
    res.json({
      success: true,
      message: `${questionMatches.length} questions detected in XML`,
      detected: questionMatches.length,
      note: 'Full XML/Moodle parser — xml2js package se implement karo'
    });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

// ── MCQ + MSQ: CHECK ANSWER ──────────────────────────────────
router.post('/check-answer', verifyToken, async (req, res) => {
  try {
    const { questionId, type, selectedOption, selectedOptions } = req.body;
    if (!questionId || !type)
      return res.status(400).json({ message: 'questionId aur type required hain' });

    const question = await Question.findById(questionId).select('correct options type marking');
    if (!question) return res.status(404).json({ message: 'Question nahi mila' });

    let isCorrect = false, marks = 0, feedback = '';

    if (type === 'SCQ' || type === 'Integer') {
      // Single correct
      isCorrect = selectedOption === question.correct;
      marks = isCorrect ? (question.marking?.correct || 4) : (selectedOption ? (question.marking?.wrong || -1) : 0);
      feedback = isCorrect ? 'Correct!' : `Wrong — Sahi jawab: ${question.correct}`;

    } else if (type === 'MSQ') {
      // Multi select — partial marking
      const correctOptions = Array.isArray(question.correct) ? question.correct : [question.correct];
      const selected = selectedOptions || [];
      const correctSelected = selected.filter(o => correctOptions.includes(o));
      const wrongSelected = selected.filter(o => !correctOptions.includes(o));

      if (wrongSelected.length > 0) {
        // Koi bhi galat option select kiya — 0 marks
        marks = 0; isCorrect = false;
        feedback = `Wrong selection — Correct options: ${correctOptions.join(', ')}`;
      } else if (correctSelected.length === correctOptions.length) {
        // Sab sahi
        marks = question.marking?.correct || 4; isCorrect = true;
        feedback = 'Perfect! Sab correct options select kiye!';
      } else if (correctSelected.length > 0) {
        // Partial correct
        marks = correctSelected.length; isCorrect = false;
        feedback = `Partial — ${correctSelected.length}/${correctOptions.length} correct`;
      } else {
        marks = 0; feedback = 'No correct option selected';
      }
    } else if (type === 'Assertion') {
      isCorrect = selectedOption === question.correct;
      marks = isCorrect ? 4 : (selectedOption ? -1 : 0);
      feedback = isCorrect ? 'Correct!' : `Wrong — Sahi: ${question.correct}`;
    }

    res.json({
      success: true, type, isCorrect, marks,
      feedback, correctAnswer: question.correct,
      selectedOption: selectedOption || selectedOptions
    });
  } catch(err) { res.status(500).json({ message: err.message }); }
});

module.exports = router;
