const express = require('express');
const router = express.Router();
const Question = require('../models/Question');
const { verifyToken, isAdmin } = require('../middleware/auth');

// ── Background Auto-Translate (non-blocking, runs after save) ──
async function autoTranslate(questionId, text, options, explanation) {
  try {
    const { translateQuestionToHindi } = require('../services/aiTranslationService');
    const result = await translateQuestionToHindi(
      text || '',
      Array.isArray(options) ? options : [],
      explanation || ''
    );
    await Question.findByIdAndUpdate(questionId, {
      hindiText:        result.hindiText        || '',
      hindiOptions:     result.hindiOptions     || [],
      hindiExplanation: result.hindiExplanation || '',
      translatedBy:     'AI-Auto',
      translatedAt:     new Date()
    });
    console.log('[AutoTranslate] ✅ ' + questionId);
  } catch (e) {
    console.log('[AutoTranslate] ⚠️  ' + questionId + ': ' + e.message);
  }
}

// ── POST — Add Question (with auto-translate) ──
router.post('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = new Question({ ...req.body, createdBy: req.user.id });
    await question.save();
    // Fire-and-forget background translation
    if (question.text && !question.hindiText) {
      autoTranslate(question._id, question.text, question.options, question.explanation).catch(() => {});
    }
    res.json({ success: true, message: 'Question added! Hindi translation in progress...', question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── GET — Fetch Questions ──
router.get('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const { subject, chapter, topic, difficulty, type, search } = req.query;
    let filter = {};
    if (subject)    filter.subject    = subject;
    if (chapter)    filter.chapter    = chapter;
    if (topic)      filter.topic      = topic;
    if (difficulty) filter.difficulty = difficulty;
    if (type)       filter.type       = type;
    if (search)     filter.text       = { $regex: search, $options: 'i' };
    const questions = await Question.find(filter).sort({ createdAt: 1 });
    res.json({ success: true, count: questions.length, questions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── PUT — Edit Question (with re-translate if English text changed) ──
router.put('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    // Version history
    if (!question.versionHistory) question.versionHistory = [];
    question.versionHistory.push({
      version:  question.version || 1,
      text:     question.text,
      options:  question.options,
      correct:  question.correct,
      editedAt: new Date()
    });
    question.version = (question.version || 1) + 1;

    const textChanged = req.body.text && req.body.text !== question.text;

    const allowedFields = [
      'text', 'hindiText', 'options', 'hindiOptions', 'correct',
      'subject', 'chapter', 'topic', 'difficulty', 'type', 'image',
      'explanation', 'hindiExplanation', 'videoLink', 'tags', 'approvalStatus'
    ];
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) question[field] = req.body[field];
    });
    await question.save();

    // Re-translate in background if English text changed
    if (textChanged && !req.body.hindiText) {
      const newText    = req.body.text;
      const newOptions = req.body.options || question.options;
      const newExp     = req.body.explanation || question.explanation;
      autoTranslate(question._id, newText, newOptions, newExp).catch(() => {});
    }

    res.json({ success: true, message: 'Question updated!', question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── DELETE ──
router.delete('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findByIdAndDelete(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Question deleted successfully!' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── Manual Retranslate (trigger for existing questions) ──
router.post('/:id/retranslate', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Translation triggered in background...', questionId: req.params.id });
    autoTranslate(question._id, question.text, question.options, question.explanation).catch(() => {});
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── Bulk Retranslate (all untranslated) ──
router.post('/bulk-retranslate', verifyToken, isAdmin, async (req, res) => {
  try {
    const questions = await Question.find({
      $or: [{ hindiText: { $exists: false } }, { hindiText: '' }, { hindiText: null }]
    }).select('_id text options explanation').limit(100);

    res.json({ success: true, message: questions.length + ' questions queued for translation...', count: questions.length });

    // Background translate all (staggered to avoid rate limits)
    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      setTimeout(() => {
        autoTranslate(q._id, q.text, q.options, q.explanation).catch(() => {});
      }, i * 1500); // 1.5s gap between each
    }
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── AI Tag Difficulty (kept from original) ──
router.put('/:id/difficulty', verifyToken, isAdmin, async (req, res) => {
  try {
    const { difficulty } = req.body;
    if (!['Easy', 'Medium', 'Hard'].includes(difficulty)) {
      return res.status(400).json({ success: false, message: 'Difficulty must be Easy, Medium, or Hard' });
    }
    const question = await Question.findByIdAndUpdate(req.params.id, { difficulty }, { new: true });
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Difficulty set to ' + difficulty, question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/:id/ai-tag-difficulty', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    const text = (question.text || '').toLowerCase();
    let hardScore = 0, easyScore = 0;
    const hardKeywords = ['calculate','derive','numerically','evaluate','complex','advanced','mechanism','exception','assertion','reason','गणना','व्युत्पन्न','कठिन','जटिल','अभिक्रिया','अपवाद','अभिकथन','कारण','मूल्यांकन'];
    const easyKeywords = ['define','what is','name the','which organ','full form','identify','परिभाषा','क्या है','नाम बताओ','कौन सा','कौन सी','पहचानो','पूर्ण रूप'];
    hardKeywords.forEach(kw => { if (text.includes(kw)) hardScore++; });
    easyKeywords.forEach(kw => { if (text.includes(kw)) easyScore++; });
    if (question.options && question.options.length > 4) hardScore++;
    if (text.length > 300) hardScore++;
    if (text.length < 80) easyScore++;
    let suggestedDifficulty = hardScore >= 2 ? 'Hard' : easyScore >= 2 ? 'Easy' : 'Medium';
    question.difficulty = suggestedDifficulty;
    question.aiDifficultyTagged = true;
    await question.save();
    res.json({ success: true, message: 'AI tagged difficulty as: ' + suggestedDifficulty, suggestedDifficulty, hardScore, easyScore });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/:id/ai-classify', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    const text = (question.text + ' ' + (question.hindiText || '')).toLowerCase();
    const subjectMap = {
      Physics:   ['velocity','acceleration','force','energy','momentum','wave','electric','magnetic','current','resistance','lens','mirror','photon','nucleus','entropy','pressure','गति','बल','ऊर्जा','तरंग','विद्युत','चुंबक','दर्पण','दाब','प्रकाश','ताप'],
      Chemistry: ['atom','molecule','bond','reaction','acid','base','salt','element','compound','oxidation','reduction','organic','inorganic','polymer','catalyst','equilibrium','परमाणु','अणु','बंध','अभिक्रिया','अम्ल','क्षार','लवण','तत्व','यौगिक','उत्प्रेरक'],
      Biology:   ['cell','dna','rna','protein','chromosome','mitosis','meiosis','photosynthesis','respiration','enzyme','hormone','organ','tissue','ecosystem','evolution','genetics','कोशिका','डीएनए','प्रोटीन','गुणसूत्र','प्रकाश संश्लेषण','श्वसन','हार्मोन','एंजाइम','अंग','ऊतक','पारिस्थितिकी','विकास','आनुवंशिकी']
    };
    let detectedSubject = question.subject || '', maxScore = 0;
    Object.entries(subjectMap).forEach(([subject, keywords]) => {
      let score = 0;
      keywords.forEach(kw => { if (text.includes(kw)) score++; });
      if (score > maxScore) { maxScore = score; detectedSubject = subject; }
    });
    if (maxScore > 0) question.subject = detectedSubject;
    question.aiClassified = true;
    await question.save();
    res.json({ success: true, message: 'AI classification complete!', detectedSubject: maxScore > 0 ? detectedSubject : 'Could not detect', subjectConfidence: maxScore });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
