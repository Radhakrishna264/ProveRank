const express = require('express');
const { callGroqAI, buildPrompt } = require('../utils/groqAI');
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
    // ✅ Real AI Translation via aiTranslationService
    const question = questionId ? await Question.findById(questionId) : null;
    const optionsArr = question?.options || [];
    const explanation = question?.explanation || '';

    const { translateQuestionToHindi } = require('../services/aiTranslationService');
    const result = await translateQuestionToHindi(text, optionsArr, explanation);

    // Save to DB if questionId provided
    if (question) {
      question.hindiText        = result.hindiText        || '';
      question.hindiOptions     = result.hindiOptions     || [];
      question.hindiExplanation = result.hindiExplanation || '';
      question.translatedBy     = 'AI-8-Groq';
      question.translatedAt     = new Date();
      await question.save();
    }

    res.json({
      success:          true,
      original:         text.slice(0, 100),
      translated:       result.hindiText || '',
      hindiText:        result.hindiText || '',
      hindiOptions:     result.hindiOptions || [],
      hindiExplanation: result.hindiExplanation || '',
      targetLanguage:   targetLang || 'hindi',
    });
  } catch(err) { res.status(500).json({ message: err.message }); }
});


// ── AI-8b: Per-Question Translate (/api/questions/:id/translate) ──
router.post('/:id/translate', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    const { translateQuestionToHindi } = require('../services/aiTranslationService');
    const result = await translateQuestionToHindi(
      question.text || '',
      Array.isArray(question.options) ? question.options : [],
      question.explanation || ''
    );
    question.hindiText        = result.hindiText        || question.hindiText || '';
    question.hindiOptions     = result.hindiOptions     || question.hindiOptions || [];
    question.hindiExplanation = result.hindiExplanation || question.hindiExplanation || '';
    question.translatedBy     = 'AI-8-Groq-Mistral';
    question.translatedAt     = new Date();
    await question.save();
    res.json({
      success: true, message: 'AI Hindi translation complete!',
      hindiText: question.hindiText,
      hindiOptions: question.hindiOptions,
      hindiExplanation: question.hindiExplanation, question
    });
  } catch (err) { res.status(500).json({ success: false, message: 'Translation failed: ' + err.message }); }
});


// ── AI-10: AUTO EXPLANATION GENERATOR (Feature 18 — Real groqAI) ──────────────

function buildExplPrompt(opts) {
  var text = opts.text, options = opts.options||[], correctIdx = opts.correctIdx||0, mode = opts.mode||'paragraph', lang = opts.lang||'english';
  var correctLetter = ['A','B','C','D'][correctIdx] || 'A';
  var optText = options.map(function(o,i){ return ['A','B','C','D'][i]+') '+o; }).join('\n');
  var langNote = lang === 'hindi' ? 'IMPORTANT: Write the explanation in Hindi (Devanagari script).' : 'Write explanation in English.';
  var modeNote = mode === 'steps'
    ? 'Give explanation as numbered step-by-step points. Each step on a new line starting with Step N:'
    : 'Give a clear, concise explanation in paragraph form.';
  return 'You are an expert NEET/JEE exam tutor. Generate a high-quality explanation for this question.\n\nQuestion: '+text+'\n\nOptions:\n'+optText+'\n\nCorrect Answer: Option '+correctLetter+'\n\n'+modeNote+'\n'+langNote+'\nAlso self-rate the quality of your explanation from 1-5 (5=best).\n\nRespond ONLY in this JSON format (no markdown, no code blocks):\n{"explanation":"your explanation here","qualityScore":4,"steps":["step1","step2"]}';
}

// ── 18.1 Single question explanation
router.post('/ai/explanation', verifyToken, isAdmin, async function(req, res) {
  try {
    var questionId = req.body.questionId, mode = req.body.mode||'paragraph', lang = req.body.lang||'english';
    if (!questionId) return res.status(400).json({ success:false, message:'questionId required' });
    var question = await Question.findById(questionId);
    if (!question) return res.status(404).json({ success:false, message:'Question not found' });
    var correctIdx = Array.isArray(question.correct) && question.correct.length > 0 ? question.correct[0] : 0;
    var prompt = buildExplPrompt({ text:question.text, options:question.options||[], correctIdx:correctIdx, mode:mode, lang:lang });
    var raw = await callGroqAI(prompt);
    var parsed = { explanation:raw, qualityScore:3, steps:[] };
    try {
      var clean = raw.replace(/```json/g,'').replace(/```/g,'').trim();
      var j = JSON.parse(clean);
      parsed = { explanation:j.explanation||raw, qualityScore:j.qualityScore||3, steps:j.steps||[] };
    } catch(_) {}
    return res.json({ success:true, questionId:questionId, questionText:question.text.slice(0,120), explanation:parsed.explanation, qualityScore:parsed.qualityScore, steps:parsed.steps, mode:mode, lang:lang });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── 18.2 Bulk explanation generate
router.post('/ai/explanation/bulk', verifyToken, isAdmin, async function(req, res) {
  try {
    var questionIds = req.body.questionIds, mode = req.body.mode||'paragraph', lang = req.body.lang||'english', autoSave = req.body.autoSave||false;
    if (!questionIds || questionIds.length === 0) return res.status(400).json({ success:false, message:'questionIds array required' });
    var results = [];
    for (var k=0; k<questionIds.length; k++) {
      var qId = questionIds[k];
      try {
        var question = await Question.findById(qId);
        if (!question) { results.push({ questionId:qId, success:false, message:'Not found' }); continue; }
        var correctIdx = Array.isArray(question.correct)&&question.correct.length>0 ? question.correct[0] : 0;
        var prompt = buildExplPrompt({ text:question.text, options:question.options||[], correctIdx:correctIdx, mode:mode, lang:lang });
        var raw = await callGroqAI(prompt);
        var parsed = { explanation:raw, qualityScore:3, steps:[] };
        try { var clean=raw.replace(/```json/g,'').replace(/```/g,'').trim(); var j=JSON.parse(clean); parsed={explanation:j.explanation||raw,qualityScore:j.qualityScore||3,steps:j.steps||[]}; } catch(_){}
        if (autoSave) {
          var upd = lang==='hindi' ? { hindiExplanation:parsed.explanation } : { explanation:parsed.explanation };
          await Question.findByIdAndUpdate(qId, upd);
        }
        results.push({ questionId:qId, success:true, explanation:parsed.explanation, qualityScore:parsed.qualityScore, steps:parsed.steps, questionText:question.text.slice(0,80) });
      } catch(e) { results.push({ questionId:qId, success:false, message:e.message }); }
    }
    var done = results.filter(function(r){return r.success;}).length;
    return res.json({ success:true, message:done+'/'+questionIds.length+' explanations generated', results:results, done:done, total:questionIds.length });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── 18.6 Hindi explanation generate
router.post('/ai/explanation/hindi', verifyToken, isAdmin, async function(req, res) {
  try {
    var questionId = req.body.questionId, mode = req.body.mode||'paragraph';
    if (!questionId) return res.status(400).json({ success:false, message:'questionId required' });
    var question = await Question.findById(questionId);
    if (!question) return res.status(404).json({ success:false, message:'Not found' });
    var correctIdx = Array.isArray(question.correct)&&question.correct.length>0 ? question.correct[0] : 0;
    var prompt = buildExplPrompt({ text:question.text, options:question.options||[], correctIdx:correctIdx, mode:mode, lang:'hindi' });
    var raw = await callGroqAI(prompt);
    var parsed = { explanation:raw, qualityScore:3, steps:[] };
    try { var clean=raw.replace(/```json/g,'').replace(/```/g,'').trim(); var j=JSON.parse(clean); parsed={explanation:j.explanation||raw,qualityScore:j.qualityScore||3,steps:j.steps||[]}; } catch(_){}
    return res.json({ success:true, questionId:questionId, hindiExplanation:parsed.explanation, qualityScore:parsed.qualityScore, steps:parsed.steps });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── 18.9 Save / Approve explanation
router.put('/:id/explanation/save', verifyToken, isAdmin, async function(req, res) {
  try {
    var explanation = req.body.explanation, hindiExplanation = req.body.hindiExplanation, action = req.body.action;
    if (action === 'reject') return res.json({ success:true, message:'Explanation rejected' });
    var update = {};
    if (explanation)      update.explanation      = explanation;
    if (hindiExplanation) update.hindiExplanation = hindiExplanation;
    await Question.findByIdAndUpdate(req.params.id, update);
    return res.json({ success:true, message:'Explanation saved!' });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── 18.12 Pending explanations queue
router.get('/ai/explanation/queue', verifyToken, isAdmin, async function(req, res) {
  try {
    var subject = req.query.subject, limit = parseInt(req.query.limit)||50;
    var filter = { $or:[{explanation:{$exists:false}},{explanation:''},{explanation:null}] };
    if (subject && subject !== 'all') filter.subject = subject;
    var questions = await Question.find(filter).select('text subject chapter difficulty type options correct explanation hindiExplanation').limit(limit).sort({ createdAt:-1 });
    var totalNoExp = await Question.countDocuments(filter);
    var totalAll   = await Question.countDocuments({});
    return res.json({ success:true, questions:questions, totalNoExp:totalNoExp, totalAll:totalAll, withExp:totalAll-totalNoExp });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
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


// ── AI GENERATE QUESTIONS ──────────────────────────────────
router.post('/generate', verifyToken, isAdmin, async (req, res) => {
  try {
    const {
      subject, chapter, topic, count, difficulty, type,
      examLevel, formats, imageUrl
    } = req.body;

if (!subject || !topic) {
      return res.status(400).json({
        success: false,
        message: 'Subject and Topic are required'
      });
    }

    const n = Math.min(parseInt(count) || 5, 30);

    const prompt = buildPrompt({
      subject: subject || 'Physics',
      chapter: chapter || topic,
      topic,
      count: n,
      difficulty: difficulty || 'medium',
      type: type || 'SCQ',
      examLevel: examLevel || 'NEET',
      formats: Array.isArray(formats) && formats.length > 0 ? formats : ['Random'],
      imageUrl: imageUrl || ''
    });

    const rawQuestions = await callGroqAI(prompt);

    if (!Array.isArray(rawQuestions) || rawQuestions.length === 0) {
      return res.status(500).json({ success: false, message: 'AI returned no questions. Please retry.' });
    }

    // ── FORMAT COMPLIANCE FILTER ──
    const requestedFormats = Array.isArray(formats) && formats.length > 0 ? formats : ['Random'];
    const filterByFormat = requestedFormats.length === 1 && requestedFormats[0] !== 'Random';
    
    const filteredRaw = filterByFormat ? rawQuestions.filter(q => {
      const fmt = requestedFormats[0];
      const txt = (q.text || '').toLowerCase();
      if (fmt === 'Assertion_Reason') return txt.includes('assertion') && txt.includes('reason');
      if (fmt === 'True_False') return (txt.includes('true') && txt.includes('false')) || txt.includes('t, f') || txt.includes('t,f');
      if (fmt === 'Statement_Based') return txt.includes('statement') || (txt.includes('i.') && txt.includes('ii.')) || txt.includes('1.') && txt.includes('2.');
      if (fmt === 'Passage_Based') return txt.length > 200;
      if (fmt === 'Sequence_Based') return txt.includes('sequence') || txt.includes('order') || txt.includes('correct order');
      if (fmt === 'Match_Column') return txt.includes('column') || txt.includes('match');
      if (fmt === 'Fill_Blanks') return txt.includes('___') || txt.includes('blank');
      return true;
    }) : rawQuestions;

    const validRaw = filteredRaw.length > 0 ? filteredRaw : rawQuestions; // fallback if filter too strict

    // Normalize & validate each question
    const questions = validRaw.slice(0, n).map((q, idx) => {
      let opts = Array.isArray(q.options) ? q.options : [];
      let corr = Array.isArray(q.correct) ? q.correct : [0];
      const qType = q.type || type || 'SCQ';

      // Integer type: no options
      if (qType === 'Integer') {
        opts = [];
        corr = typeof corr[0] === 'number' ? corr : [0];
      }
      // SCQ: exactly 1 correct
      if (qType === 'SCQ' && corr.length > 1) corr = [corr[0]];
      // MSQ: 2-3 correct
      if (qType === 'MSQ') {
        if (corr.length < 2) corr = [0, 2];
        if (corr.length > 3) corr = corr.slice(0, 3);
      }
      // Bounds check
      corr = corr.filter(x => typeof x === 'number' && x >= 0 && (qType === 'Integer' || x < opts.length));

      return {
        text: q.text || ('Question ' + (idx + 1)),
        hindiText: q.hindiText || '',
        options: opts,
        correct: corr.length > 0 ? corr : [0],
        type: qType,
        difficulty: q.difficulty || difficulty || 'medium',
        subject: q.subject || subject,
        chapter: q.chapter || chapter || '',
        topic: q.topic || topic,
        explanation: q.explanation || '',
        format: q.format || (Array.isArray(formats) ? formats[0] : 'Random'),
        examLevel: q.examLevel || examLevel || 'NEET',
        imageUrl: q.imageUrl || imageUrl || '',
        approvalStatus: 'pending'
      };
    });

    res.json({ success: true, questions, count: questions.length });

  } catch (err) {
    console.error('Gemini Generate Error:', err.message);
    res.status(500).json({
      success: false,
      message: 'AI generation failed: ' + err.message
    });
  }
});



// ── Per-Question Usage Stats: exams used in, attempts, success rate (Feature 2) ──
router.get('/:id/usage-stats', verifyToken, async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const Exam = require('../models/Exam');
    const Attempt = require('../models/Attempt');
    const qId = new mongoose.Types.ObjectId(req.params.id);
    const question = await Question.findById(qId).select('text usageCount correct type');
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    const examsUsedIn = await Exam.countDocuments({ questions: qId });

    const attempts = await Attempt.find({ 'answers.questionId': qId }).select('answers');
    let timesAttempted = 0, correctCount = 0;
    attempts.forEach(a => {
      (a.answers || []).forEach(ans => {
        if (String(ans.questionId) === String(qId) && ans.selectedOption !== null && ans.selectedOption !== undefined) {
          timesAttempted++;
          const correct = Array.isArray(question.correct) ? question.correct : [question.correct];
          const sel = ans.selectedOption;
          const selArr = Array.isArray(sel) ? sel : [sel];
          const isCorrect = correct.length === selArr.length && correct.every(cv => selArr.includes(cv));
          if (isCorrect) correctCount++;
        }
      });
    });
    const successRate = timesAttempted > 0 ? Math.round((correctCount / timesAttempted) * 100) : 0;

    res.json({
      success: true,
      questionId: req.params.id,
      usageCount: question.usageCount || 0,
      examsUsedIn,
      timesAttempted,
      successRate
    });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ── BULK SAVE QUESTIONS ────────────────────────────────────
router.post('/bulk-save', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questions } = req.body
    if (!questions || !Array.isArray(questions) || questions.length === 0) {
      return res.status(400).json({ success: false, message: 'questions array required' })
    }
    const Question = require('../models/Question')
    const userId = req.user._id || req.user.id
    const toSave = questions.map(q => ({
      text: q.text || 'Question',
      subject: q.subject || 'General',
      chapter: q.chapter || '',
      topic: q.topic || '',
      difficulty: q.difficulty || 'medium',
      type: q.type || 'SCQ',
      options: q.options || [],
      correct: q.correct || [0],
      correctAnswer: q.correctAnswer || 'A',
      explanation: q.explanation || '',
      approvalStatus: q.approvalStatus || 'pending',
      createdBy: userId
    }))
    const saved = await Question.insertMany(toSave)
    res.json({ success: true, message: saved.length + ' questions saved!', count: saved.length })
  } catch (err) {
    res.status(500).json({ success: false, message: err.message })
  }
})

module.exports = router;

// Step 14 — Version History (S87)
router.get('/:id/versions', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id).select('versionHistory text');
    if (!question) return res.status(404).json({ message: 'Question not found' });
    res.json({ success: true, versions: question.versionHistory || [], currentText: question.text });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Step 18 — Error Reporting (S84)
router.post('/:id/report', verifyToken, async (req, res) => {
  try {
    const { reason } = req.body;
    if (!reason) return res.status(400).json({ message: 'Reason required' });
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ message: 'Question not found' });
    if (!question.reports) question.reports = [];
    question.reports.push({
      reason,
      reportedBy: req.user.id,
      reportedAt: new Date(),
      status: 'pending'
    });
    await question.save();
    res.json({ success: true, message: 'Question reported successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});


// ══ Feature 19 — Bulk Paste Save ════════════════════════════════
// POST /api/questions/bulk-paste-save
router.post('/bulk-paste-save', verifyToken, isAdmin, async function(req, res) {
  try {
    var questions = req.body.questions;
    var target    = req.body.target || 'qs_bank'; // 'qs_bank' | 'pyq_bank'
    var defaultSubject    = req.body.subject    || 'General';
    var defaultChapter    = req.body.chapter    || '';
    var defaultDifficulty = req.body.difficulty || 'Medium';
    var defaultType       = req.body.type       || 'SCQ';

    if (!questions || !questions.length)
      return res.status(400).json({ success:false, message:'No questions provided' });

    var saved = [], errors = [];

    for (var i=0; i<questions.length; i++) {
      try {
        var q = questions[i];
        var doc = new Question({
          text:             q.text             || '',
          hindiText:        q.hindiText        || '',
          options:          q.options          || [],
          hindiOptions:     q.hindiOptions     || [],
          correct:          q.correct          || [0],
          explanation:      q.explanation      || '',
          hindiExplanation: q.hindiExplanation || '',
          subject:          q.subject          || defaultSubject,
          chapter:          q.chapter          || defaultChapter,
          difficulty:       q.difficulty       || defaultDifficulty,
          type:             q.type             || defaultType,
          format:           q.format           || '',
          isPYQ:            target === 'pyq_bank',
          source:           'paste',
          usageCount:       0,
          createdBy:        req.user.id
        });
        await doc.save();
        saved.push(doc._id);
      } catch(e) {
        errors.push({ index:i, message:e.message });
      }
    }

    return res.json({
      success: true,
      message: saved.length+' questions saved to '+(target==='pyq_bank'?'PYQ Bank':'Question Bank'),
      saved:   saved.length,
      errors:  errors,
      target:  target
    });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── Feature 19 — Parse Preview (server-side validation only)
router.post('/bulk-paste-validate', verifyToken, isAdmin, async function(req, res) {
  try {
    var questions = req.body.questions || [];
    var valid   = questions.filter(function(q){return q.text&&q.options&&q.options.length>=2&&q.correct&&q.correct.length>0;}).length;
    var invalid = questions.length - valid;
    return res.json({ success:true, total:questions.length, valid:valid, invalid:invalid });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});


module.exports = router;