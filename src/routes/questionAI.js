const express = require('express');
const router = express.Router();
const Question = require('../models/Question');
const { verifyToken, isAdmin } = require('../middleware/auth');
const https = require('https');

// ✅ STEP 19 - AI-8: Hindi-English Auto Translator
router.post('/:id/translate', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    const { direction } = req.body;

    // Simple word-by-word dictionary translation (free, no API needed)
    const enToHi = {
      'what': 'क्या', 'is': 'है', 'the': '', 'of': 'का', 'in': 'में',
      'and': 'और', 'to': 'को', 'a': 'एक', 'an': 'एक', 'are': 'हैं',
      'which': 'कौन सा', 'how': 'कैसे', 'why': 'क्यों', 'when': 'कब',
      'where': 'कहाँ', 'who': 'कौन', 'main': 'मुख्य', 'function': 'कार्य',
      'cell': 'कोशिका', 'nucleus': 'केन्द्रक', 'energy': 'ऊर्जा',
      'production': 'उत्पादन', 'called': 'कहलाता है', 'name': 'नाम',
      'define': 'परिभाषित करो', 'calculate': 'गणना करो',
      'find': 'ज्ञात करो', 'write': 'लिखो', 'explain': 'समझाओ',
      'give': 'दो', 'example': 'उदाहरण', 'correct': 'सही',
      'wrong': 'गलत', 'option': 'विकल्प', 'answer': 'उत्तर',
      'question': 'प्रश्न', 'following': 'निम्नलिखित',
      'photosynthesis': 'प्रकाश संश्लेषण', 'respiration': 'श्वसन',
      'atom': 'परमाणु', 'molecule': 'अणु', 'force': 'बल',
      'velocity': 'वेग', 'acceleration': 'त्वरण', 'mass': 'द्रव्यमान',
      'temperature': 'तापमान', 'pressure': 'दाब', 'volume': 'आयतन',
      'acid': 'अम्ल', 'base': 'क्षार', 'salt': 'लवण',
      'protein': 'प्रोटीन', 'gene': 'जीन', 'dna': 'डीएनए',
      'mitochondria': 'माइटोकॉन्ड्रिया', 'chromosome': 'गुणसूत्र'
    };

    let translatedText = '';
    let sourceText = '';

    if (direction === 'en-to-hi' || !direction) {
      sourceText = question.text || '';
      const words = sourceText.toLowerCase().split(/\s+/);
      const translated = words.map(w => enToHi[w] || w).filter(w => w !== '');
      translatedText = translated.join(' ');
      question.hindiText = translatedText;
    } else {
      sourceText = question.hindiText || '';
      translatedText = sourceText;
    }

    question.translatedBy = 'AI-8-Dictionary';
    await question.save();

    res.json({
      success: true,
      message: 'Translation complete! (Dictionary-based AI)',
      direction: direction || 'en-to-hi',
      sourceText: sourceText.substring(0, 100),
      translatedText: translatedText.substring(0, 100),
      note: 'For better translation, connect Google Translate API or LibreTranslate in production',
      question
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Bulk translate all untranslated questions
router.post('/translate-bulk', verifyToken, isAdmin, async (req, res) => {
  try {
    const questions = await Question.find({
      $or: [{ hindiText: { $exists: false } }, { hindiText: '' }, { hindiText: null }]
    }).limit(50);

    const enToHi = {
      'what': 'क्या', 'is': 'है', 'the': '', 'of': 'का', 'in': 'में',
      'and': 'और', 'which': 'कौन सा', 'how': 'कैसे', 'calculate': 'गणना करो',
      'find': 'ज्ञात करो', 'define': 'परिभाषित करो', 'explain': 'समझाओ',
      'cell': 'कोशिका', 'energy': 'ऊर्जा', 'function': 'कार्य',
      'atom': 'परमाणु', 'force': 'बल', 'velocity': 'वेग'
    };

    let translated = 0;
    for (const q of questions) {
      if (q.text) {
        const words = q.text.toLowerCase().split(/\s+/);
        q.hindiText = words.map(w => enToHi[w] || w).filter(w => w).join(' ');
        q.translatedBy = 'AI-8-Bulk';
        await q.save();
        translated++;
      }
    }

    res.json({
      success: true,
      message: translated + ' questions translated!',
      translatedCount: translated
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 20 - AI-10: Auto Explanation Generator
router.post('/:id/generate-explanation', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    const text = (question.text || '').toLowerCase();
    const subject = question.subject || '';
    const correct = question.correct || [0];
    const correctOption = question.options ? question.options[correct[0]] : '';

    // AI explanation templates based on subject and question type
    let explanation = '';

    if (subject === 'Biology') {
      if (text.includes('mitochondria') || text.includes('माइटोकॉन्ड्रिया')) {
        explanation = `Mitochondria ko "Cell ka Powerhouse" kaha jaata hai kyunki yahan ATP (Adenosine Triphosphate) ka utpadan hota hai. Sahi answer: "${correctOption}". Mitochondria mein Krebs cycle aur Electron Transport Chain hoti hai jo cellular respiration ke zariye energy banati hai.`;
      } else if (text.includes('photosynthesis') || text.includes('प्रकाश संश्लेषण')) {
        explanation = `Prakaash Sanshleshan (Photosynthesis) ek aisa process hai jisme plants sunlight, CO2 aur paani ka upyog karke glucose banate hain. Sahi answer: "${correctOption}". Samikaran: 6CO2 + 6H2O + Light → C6H12O6 + 6O2`;
      } else if (text.includes('dna') || text.includes('डीएनए')) {
        explanation = `DNA (Deoxyribonucleic Acid) genetic information ka carrier hai. Sahi answer: "${correctOption}". DNA double helix structure mein hota hai jise Watson aur Crick ne 1953 mein discover kiya tha.`;
      } else {
        explanation = `Biology question ka sahi answer "${correctOption}" hai. Yeh concept NEET exam ke liye bahut important hai. Ise achhe se yaad karein aur related topics bhi padhen.`;
      }
    } else if (subject === 'Physics') {
      if (text.includes('velocity') || text.includes('वेग')) {
        explanation = `Veg (Velocity) ek vector quantity hai. Sahi answer: "${correctOption}". Speed aur direction dono milke velocity banate hain. SI unit: m/s. Formula: v = displacement/time`;
      } else if (text.includes('force') || text.includes('बल')) {
        explanation = `Bal (Force) Newton ke doosre niyam se: F = ma. Sahi answer: "${correctOption}". Force ek vector quantity hai. SI unit: Newton (N). 1N = 1 kg⋅m/s²`;
      } else if (text.includes('energy') || text.includes('ऊर्जा')) {
        explanation = `Urja (Energy) kaam karne ki kshamata hai. Sahi answer: "${correctOption}". Energy conservation ka niyam: Urja na banti hai na naash hoti hai, sirf ek roop se doosre roop mein badal sakti hai.`;
      } else {
        explanation = `Physics question ka sahi answer "${correctOption}" hai. Concepts ko formula ke saath yaad rakhein aur numerical practice zaroor karein.`;
      }
    } else if (subject === 'Chemistry') {
      if (text.includes('acid') || text.includes('अम्ल')) {
        explanation = `Aml (Acid) wo padarth hai jo H+ ions deta hai (Arrhenius theory). Sahi answer: "${correctOption}". pH scale pe acid ka pH 7 se kam hota hai. Strong acids: HCl, H2SO4, HNO3.`;
      } else if (text.includes('atom') || text.includes('परमाणु')) {
        explanation = `Paramanu (Atom) padarth ki sabse chhoti ikaai hai. Sahi answer: "${correctOption}". Atom mein proton aur neutron nucleus mein hote hain aur electrons bahar chakkar lagate hain.`;
      } else {
        explanation = `Chemistry question ka sahi answer "${correctOption}" hai. Reactions aur equations ko balance karke samjhein. Practice se concepts clear honge.`;
      }
    } else {
      explanation = `Is question ka sahi answer "${correctOption}" hai. Yeh concept exam ke nazar se important hai. Related topics bhi achhe se taiyar karein.`;
    }

    // Hindi version
    const hindiExplanation = `सही उत्तर: "${correctOption}". ${explanation}`;

    question.explanation = explanation;
    question.aiExplanationGenerated = true;
    await question.save();

    res.json({
      success: true,
      message: 'AI Explanation generated!',
      explanation,
      hindiExplanation,
      subject,
      correctOption,
      note: 'Admin can edit this explanation before publishing'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 21 - N7: Question Approval Workflow
router.post('/:id/submit-for-approval', verifyToken, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    question.approvalStatus = 'Pending';
    question.submittedForApproval = new Date();
    question.submittedBy = req.user._id;
    await question.save();
    res.json({ success: true, message: 'Question submitted for SuperAdmin approval!', approvalStatus: 'Pending' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/approval-queue', verifyToken, isAdmin, async (req, res) => {
  try {
    const pending = await Question.find({ approvalStatus: 'Pending' })
      .populate('submittedBy', 'name email')
      .sort({ submittedForApproval: 1 });
    res.json({
      success: true,
      pendingCount: pending.length,
      message: pending.length > 0 ? pending.length + ' questions waiting for approval' : 'No pending questions',
      questions: pending
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id/approve', verifyToken, isAdmin, async (req, res) => {
  try {
    const { action, rejectReason } = req.body;
    if (!['Approved', 'Rejected'].includes(action)) {
      return res.status(400).json({ success: false, message: 'Action must be Approved or Rejected' });
    }
    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });
    question.approvalStatus = action;
    question.approvedBy = req.user._id;
    question.approvedAt = new Date();
    if (action === 'Rejected') question.rejectionReason = rejectReason || 'Not specified';
    question.isActive = action === 'Approved';
    await question.save();
    res.json({
      success: true,
      message: 'Question ' + action + ' successfully!',
      approvalStatus: action,
      isActive: question.isActive
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 22 - M11: Question Bank Import XML/Moodle
router.post('/import-moodle', verifyToken, isAdmin, async (req, res) => {
  try {
    const { xmlData } = req.body;
    if (!xmlData) return res.status(400).json({ success: false, message: 'XML data required' });

    // Simple XML parser for Moodle format
    const questions = [];
    const questionBlocks = xmlData.match(/<question[^>]*>([\s\S]*?)<\/question>/gi) || [];

    questionBlocks.forEach((block, index) => {
      try {
        const nameMatch = block.match(/<name>[\s\S]*?<text>([\s\S]*?)<\/text>/i);
        const textMatch = block.match(/<questiontext[^>]*>[\s\S]*?<text>([\s\S]*?)<\/text>/i);

        if (!textMatch) return;

        const qText = textMatch[1].replace(/<[^>]*>/g, '').trim();
        const qName = nameMatch ? nameMatch[1].replace(/<[^>]*>/g, '').trim() : '';

        const answerMatches = block.match(/<answer[^>]*fraction="([^"]*)"[^>]*>[\s\S]*?<text>([\s\S]*?)<\/text>/gi) || [];
        const options = [];
        const correct = [];

        answerMatches.forEach((ans, i) => {
          const fracMatch = ans.match(/fraction="([^"]*)"/);
          const textM = ans.match(/<text>([\s\S]*?)<\/text>/i);
          if (textM) {
            options.push(textM[1].replace(/<[^>]*>/g, '').trim());
            if (fracMatch && parseFloat(fracMatch[1]) > 0) correct.push(i);
          }
        });

        if (qText && options.length > 0) {
          questions.push({
            text: qText,
            options: options.length > 0 ? options : ['A', 'B', 'C', 'D'],
            correct: correct.length > 0 ? correct : [0],
            type: correct.length > 1 ? 'MSQ' : 'SCQ',
            subject: 'General',
            difficulty: 'Medium',
            importedFrom: 'Moodle',
            approvalStatus: 'Pending'
          });
        }
      } catch (e) {}
    });

    // Save parsed questions
    const saved = [];
    for (const q of questions) {
      try {
        const newQ = new Question({ ...q, createdBy: req.user._id });
        await newQ.save();
        saved.push(newQ._id);
      } catch (e) {}
    }

    res.json({
      success: true,
      message: saved.length + ' questions imported from Moodle XML!',
      totalParsed: questions.length,
      totalSaved: saved.length,
      note: 'All imported questions are in Pending approval status',
      savedIds: saved
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Simple text format import (Q1. ... A) ... B) ... Answer: A)
router.post('/import-text', verifyToken, isAdmin, async (req, res) => {
  try {
    const { textData, subject, chapter, difficulty } = req.body;
    if (!textData) return res.status(400).json({ success: false, message: 'Text data required' });

    const lines = textData.split('\n').map(l => l.trim()).filter(l => l);
    const questions = [];
    let current = null;

    lines.forEach(line => {
      if (/^Q?\d+[\.\)]\s/.test(line)) {
        if (current && current.text) questions.push(current);
        current = { text: line.replace(/^Q?\d+[\.\)]\s*/, ''), options: [], correct: [0], subject: subject || 'General', chapter: chapter || '', difficulty: difficulty || 'Medium', type: 'SCQ', approvalStatus: 'Pending' };
      } else if (/^[A-D][\.\)]\s/.test(line) && current) {
        current.options.push(line.replace(/^[A-D][\.\)]\s*/, ''));
      } else if (/^(Answer|Ans|ANS|ANSWER)\s*[:=]\s*[A-D]/i.test(line) && current) {
        const ans = line.match(/[A-D]/);
        if (ans) current.correct = ['A','B','C','D'].indexOf(ans[0]);
        current.correct = [Math.max(0, current.correct)];
      }
    });
    if (current && current.text) questions.push(current);

    const saved = [];
    for (const q of questions) {
      if (q.options.length === 0) q.options = ['Option A', 'Option B', 'Option C', 'Option D'];
      try {
        const newQ = new Question({ ...q, createdBy: req.user._id });
        await newQ.save();
        saved.push(newQ._id);
      } catch (e) {}
    }

    res.json({
      success: true,
      message: saved.length + ' questions imported from text!',
      totalParsed: questions.length,
      totalSaved: saved.length,
      savedIds: saved
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
