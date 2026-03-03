const fs = require('fs');

// ── FIX 1: copyPasteQuestions - examLink add to response ──
const upFile = '/home/runner/workspace/src/controllers/uploadController.js';
let up = fs.readFileSync(upFile, 'utf8');

// Find the return statement in copyPasteQuestions and add examLink
const oldReturn = `return res.json({
      success: true,
      message: \`\${inserted} questions saved`;
const newReturn = `// Auto-link to exam if examId provided
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
      examLink: examLink,
      message: \`\${inserted} questions saved`;

if (up.includes(oldReturn)) {
  up = up.replace(oldReturn, newReturn);
  fs.writeFileSync(upFile, up);
  console.log('✅ FIX 1 done: copyPasteQuestions examLink added');
} else {
  console.log('⚠️ FIX 1: Pattern not found - checking alternate...');
  // Try alternate pattern
  const alt = `return res.json({\n      success: true,\n      message: \`\${inserted}`;
  if (up.includes('inserted') && up.includes('copyPasteQuestions')) {
    console.log('  → Manual check needed for uploadController');
  }
}

// ── FIX 2: paperGenerator - add savedAsExam to response ──
const pgFile = '/home/runner/workspace/src/controllers/paperGenerator.js';
let pg = fs.readFileSync(pgFile, 'utf8');

const oldPgReturn = `return res.json({
      success: true,
      message:`;
const newPgReturn = `// One-click exam ready - mark as savedAsExam
    const savedAsExam = generatedSets.length > 0;
    return res.json({
      success: true,
      savedAsExam: savedAsExam,
      examReady: savedAsExam,
      totalSets: generatedSets.length,
      message:`;

if (pg.includes(oldPgReturn)) {
  pg = pg.replace(oldPgReturn, newPgReturn);
  fs.writeFileSync(pgFile, pg);
  console.log('✅ FIX 2 done: paperGenerator savedAsExam added');
} else {
  // Try to find the actual return
  const match = pg.match(/return res\.json\(\{[\s\S]{0,50}success: true/);
  if (match) {
    console.log('⚠️ FIX 2: Found return at different pattern:', match[0].substring(0,80));
  } else {
    console.log('⚠️ FIX 2: No return res.json found - manual check needed');
  }
}

console.log('\n✅ Fix script done. Restart server now.');
