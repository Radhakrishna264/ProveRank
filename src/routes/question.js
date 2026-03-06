const express = require('express');
const router = express.Router();
const Question = require('../models/Question');
const { verifyToken, isAdmin } = require('../middleware/auth');

router.post('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = new Question({ ...req.body, createdBy: req.user.id });
    await question.save();
    res.json({ success: true, message: 'Question added successfully!', question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const { subject, chapter, topic, difficulty, type, search } = req.query;
    let filter = {};
    if (subject) filter.subject = subject;
    if (chapter) filter.chapter = chapter;
    if (topic) filter.topic = topic;
    if (difficulty) filter.difficulty = difficulty;
    if (type) filter.type = type;
    if (search) filter.text = { $regex: search, $options: 'i' };
    const questions = await Question.find(filter).sort({ createdAt: -1 });
    res.json({ success: true, count: questions.length, questions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    if (!question.versionHistory) question.versionHistory = [];
    question.versionHistory.push({
      version: question.version || 1,
      text: question.text,
      options: question.options,
      correct: question.correct,
      editedAt: new Date()
    });
    question.version = (question.version || 1) + 1;
    const allowedFields = ['text','hindiText','options','correct','subject','chapter','topic',
      'difficulty','type','image','explanation','videoLink','tags','approvalStatus'];
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) question[field] = req.body[field];
    });
    await question.save();
    res.json({ success: true, message: 'Question updated successfully!', question });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findByIdAndDelete(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    res.json({ success: true, message: 'Question deleted successfully!' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

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
    const hardKeywords = [
      'calculate','derive','numerically','evaluate','complex','advanced','mechanism','exception','assertion','reason',
      'गणना','व्युत्पन्न','कठिन','जटिल','अभिक्रिया','अपवाद','अभिकथन','कारण','मूल्यांकन'
    ];
    const easyKeywords = [
      'define','what is','name the','which organ','full form','identify',
      'परिभाषा','क्या है','नाम बताओ','कौन सा','कौन सी','पहचानो','पूर्ण रूप'
    ];
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
      Physics: [
        'velocity','acceleration','force','energy','momentum','wave','electric','magnetic',
        'current','resistance','lens','mirror','photon','nucleus','entropy','pressure',
        'गति','बल','ऊर्जा','तरंग','विद्युत','चुंबक','दर्पण','दाब','प्रकाश','ताप'
      ],
      Chemistry: [
        'atom','molecule','bond','reaction','acid','base','salt','element','compound',
        'oxidation','reduction','organic','inorganic','polymer','catalyst','equilibrium',
        'परमाणु','अणु','बंध','अभिक्रिया','अम्ल','क्षार','लवण','तत्व','यौगिक','उत्प्रेरक'
      ],
      Biology: [
        'cell','dna','rna','protein','chromosome','mitosis','meiosis','photosynthesis',
        'respiration','enzyme','hormone','organ','tissue','ecosystem','evolution','genetics',
        'कोशिका','डीएनए','प्रोटीन','गुणसूत्र','प्रकाश संश्लेषण','श्वसन','हार्मोन',
        'एंजाइम','अंग','ऊतक','पारिस्थितिकी','विकास','आनुवंशिकी'
      ]
    };
    const chapterMap = {
      'Cell Biology': [
        'cell wall','cell membrane','mitochondria','nucleus','ribosome','golgi',
        'कोशिका भित्ति','कोशिका झिल्ली','माइटोकॉन्ड्रिया','केन्द्रक','राइबोसोम','गॉल्जी'
      ],
      'DNA Storage': [
        'dna','rna','replication','transcription','translation','codon',
        'डीएनए','आरएनए','प्रतिकृति','अनुलेखन','अनुवाद','कोडोन'
      ],
      'Cell Division': [
        'mitosis','meiosis','prophase','metaphase','anaphase','telophase',
        'समसूत्री','अर्धसूत्री','पूर्वावस्था','मध्यावस्था','पश्चावस्था','अंत्यावस्था'
      ],
      'Mechanics': [
        'velocity','acceleration','force','newton','momentum',
        'गति','वेग','त्वरण','बल','न्यूटन','संवेग'
      ],
      'Thermodynamics': [
        'heat','temperature','entropy','carnot',
        'ऊष्मा','तापमान','एन्ट्रॉपी','कार्नो'
      ],
      'Organic Chemistry': [
        'organic','carbon','alkane','alkene','benzene',
        'कार्बनिक','कार्बन','एल्केन','एल्कीन','बेंजीन'
      ],
      'Electrochemistry': [
        'electrolysis','galvanic','cathode','anode',
        'विद्युत अपघटन','गैल्वेनिक','कैथोड','एनोड'
      ],
      'Genetics': [
        'gene','allele','dominant','recessive','mendel',
        'जीन','एलील','प्रभावी','अप्रभावी','मेंडल','आनुवंशिकी'
      ],
      'Plant Physiology': [
        'photosynthesis','transpiration','chlorophyll',
        'प्रकाश संश्लेषण','वाष्पोत्सर्जन','क्लोरोफिल','पर्णहरित'
      ]
    };
    let detectedSubject = question.subject || '', maxScore = 0;
    Object.entries(subjectMap).forEach(([subject, keywords]) => {
      let score = 0;
      keywords.forEach(kw => { if (text.includes(kw)) score++; });
      if (score > maxScore) { maxScore = score; detectedSubject = subject; }
    });
    let detectedChapter = question.chapter || '', chapterScore = 0;
    Object.entries(chapterMap).forEach(([chapter, keywords]) => {
      let score = 0;
      keywords.forEach(kw => { if (text.includes(kw)) score++; });
      if (score > chapterScore) { chapterScore = score; detectedChapter = chapter; }
    });
    if (maxScore > 0) question.subject = detectedSubject;
    if (chapterScore > 0) question.chapter = detectedChapter;
    question.aiClassified = true;
    await question.save();
    res.json({
      success: true,
      message: 'AI classification complete!',
      detectedSubject: maxScore > 0 ? detectedSubject : 'Could not detect (add manually)',
      detectedChapter: chapterScore > 0 ? detectedChapter : 'Could not detect (add manually)',
      subjectConfidence: maxScore,
      chapterConfidence: chapterScore
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
