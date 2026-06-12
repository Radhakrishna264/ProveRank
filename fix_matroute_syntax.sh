#!/bin/bash
# Fix: Rewrite material generate route correctly

node << 'JSEOF'
const fs = require('fs');
const f = '/home/runner/workspace/src/routes/materialRoutes.js';
let c = fs.readFileSync(f, 'utf8');

// Find and replace the broken generate route
const startMarker = '// POST /api/materials/generate';
const startIdx = c.indexOf(startMarker);
if (startIdx === -1) { console.log('❌ marker not found'); process.exit(1); }

const newRoute = `// POST /api/materials/generate — generate questions from material using 20-layer AI
router.post('/generate', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const { materialId, count, difficulty, examLevel, formats } = req.body;
    const mat = await Material.findOne({ _id: materialId, adminId: user.id || user._id });
    if (!mat) return res.status(404).json({ message: 'Material not found' });
    const { callGroqAI } = require('../utils/groqAI');
    const n = Math.min(parseInt(count) || 5, 30);
    const diff = (difficulty || 'medium').toLowerCase();
    const lvl = examLevel || 'NEET';
    const fmts = (Array.isArray(formats) && formats.length > 0) ? formats : ['Random'];
    const seed = Date.now() + '-' + Math.floor(Math.random() * 999999);
    const matTitle = (mat.title || '').replace(/'/g, ' ');
    const matContent = (mat.content || '').substring(0, 5000).replace(/\\/g, '\\\\').replace(/'/g, "\\'");

    const lines = [
      'You are a senior question setter. Generate EXACTLY ' + n + ' MCQ questions from the content below.',
      'SEED: ' + seed,
      'Difficulty: ' + diff + ' | Exam: ' + lvl + ' | Formats: ' + fmts.join(', '),
      '',
      'CONTENT:',
      '---',
      mat.content.substring(0, 5000),
      '---',
      '',
      'RULES: Use ONLY the content above. Return ONLY valid JSON array:',
      '[{"text":"q","options":["A. a","B. b","C. c","D. d"],"correct":[0],"correctAnswer":"A","type":"SCQ","difficulty":"' + diff + '","chapter":"' + matTitle + '","explanation":"reason"}]'
    ];
    const prompt = lines.join('\n');

    const questions = await callGroqAI(prompt);
    if (!questions || questions.length === 0) {
      return res.status(500).json({ message: 'AI could not generate questions. Try again.' });
    }
    res.json(questions);
  } catch(e) {
    res.status(500).json({ message: e.message || 'Generation failed' });
  }
});
`;

c = c.substring(0, startIdx) + newRoute;
fs.writeFileSync(f, c);
console.log('✅ Generate route fixed. Lines: ' + c.split('\n').length);
JSEOF

echo ""
node -c /home/runner/workspace/src/routes/materialRoutes.js && echo "✅ Syntax OK"
