const fs = require('fs');
const file = '/home/runner/workspace/src/controllers/uploadController.js';
let code = fs.readFileSync(file, 'utf8');

const oldStr = `return res.json({
      success: true,
      message: 'Copy-paste questions saved!',
      inserted: savedCount,
      skipped,
      errors: errors.length,
      total: questions.length
    });`;

const newStr = `// Phase 2.4 Step 5 - Auto-link to exam if examId provided
    let examLink = null;
    if (req.body.examId) {
      try {
        const Exam = require('../models/Exam');
        const exam = await Exam.findById(req.body.examId);
        if (exam) examLink = { examId: exam._id, examTitle: exam.title, linked: true };
        else examLink = { examId: req.body.examId, linked: false, message: 'Exam nahi mila' };
      } catch(e) { examLink = { linked: false, error: e.message }; }
    }
    return res.json({
      success: true,
      message: 'Copy-paste questions saved!',
      inserted: savedCount,
      skipped,
      errors: errors.length,
      total: questions.length,
      examLink: examLink,
      savedToExam: examLink?.linked || false
    });`;

if (code.includes(oldStr)) {
  code = code.replace(oldStr, newStr);
  fs.writeFileSync(file, code);
  console.log('✅ FIX 1 done: examLink added to copyPasteQuestions');
} else {
  console.log('❌ Pattern not found - spaces/quotes mismatch ho sakta hai');
  // Debug: show actual text around that area
  const idx = code.indexOf("'Copy-paste questions saved!'");
  if (idx > -1) console.log('Found at idx:', idx, '\nContext:', code.substring(idx-100, idx+200));
}
