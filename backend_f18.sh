#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — Feature 18: AI Explanation Generator
# BACKEND SCRIPT
# ═══════════════════════════════════════════════════════════════
set -e
echo "🚀 Feature 18 Backend starting..."

cat > /tmp/f18_backend.js << 'JSEOF'
const fs = require('fs'), p = require('path');
const fpath = p.join(process.env.HOME,'workspace/src/routes/questionFeatures.js');
let c = fs.readFileSync(fpath,'utf8');

// ── 1. Replace stub /ai/explanation with real groqAI (18.1 / 18.3 / 18.10 / 18.11)
const OLD_STUB = `// ── AI-10: AUTO EXPLANATION GENERATOR ───────────────────────
router.post('/ai/explanation', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionId, questionText, correctAnswer } = req.body;
    const question = questionId ? await Question.findById(questionId) : null;
    const text = questionText || question?.text;
    if (!text) return res.status(400).json({ message: 'questionId ya questionText required' });
    res.json({
      success: true,
      questionText: text.slice(0, 100),
      generatedExplanation: \`Explanation for: "\${text.slice(0,80)}..." — The correct answer is based on the fundamental concept. [Connect Hugging Face API for real AI explanation]\`,
      note: 'Hugging Face free API se connect karo for real explanations'
    });
  } catch(err) { res.status(500).json({ message: err.message }); }
});`;

const NEW_EXPLANATION = `// ── AI-10: AUTO EXPLANATION GENERATOR (Feature 18 — Real AI) ─
const { callGroqAI } = require('../utils/groqAI');

// Helper: build explanation prompt
function buildExplPrompt({ text, options, correctIdx, mode, lang }) {
  const correctLetter = ['A','B','C','D'][correctIdx] || 'A';
  const optText = (options||[]).map((o,i)=>\`\${['A','B','C','D'][i]}) \${o}\`).join('\\n');
  const langNote = lang === 'hindi' ? 'IMPORTANT: Write the explanation in Hindi (Devanagari script).' : 'Write explanation in English.';
  const modeNote = mode === 'steps'
    ? 'Give explanation as numbered step-by-step points (not a paragraph). Each step on a new line.'
    : 'Give a clear, concise explanation in paragraph form.';
  return \`You are an expert NEET/JEE exam tutor. Generate a high-quality explanation for this question.

Question: \${text}

Options:
\${optText}

Correct Answer: Option \${correctLetter}

\${modeNote}
\${langNote}
Also self-rate the quality of your explanation from 1-5 (5=best).

Respond ONLY in this JSON format (no markdown):
{"explanation":"...your explanation here...","qualityScore":4,"steps":["step1","step2"]}\`;
}

// ── 18.1 Single question explanation
router.post('/ai/explanation', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionId, mode, lang } = req.body; // mode: 'paragraph'|'steps', lang: 'english'|'hindi'
    if (!questionId) return res.status(400).json({ success:false, message:'questionId required' });
    const question = await Question.findById(questionId);
    if (!question) return res.status(404).json({ success:false, message:'Question not found' });

    const correctIdx = Array.isArray(question.correct) && question.correct.length > 0
      ? question.correct[0] : 0;
    const prompt = buildExplPrompt({
      text: question.text,
      options: question.options || [],
      correctIdx,
      mode: mode || 'paragraph',
      lang: lang || 'english'
    });

    const raw = await callGroqAI(prompt);
    let parsed = { explanation: raw, qualityScore: 3, steps: [] };
    try {
      const clean = raw.replace(/\`\`\`json|\`\`\`/g,'').trim();
      const j = JSON.parse(clean);
      parsed = { explanation: j.explanation || raw, qualityScore: j.qualityScore || 3, steps: j.steps || [] };
    } catch(_) {}

    return res.json({
      success: true,
      questionId,
      questionText: question.text.slice(0,120),
      explanation:  parsed.explanation,
      qualityScore: parsed.qualityScore,
      steps:        parsed.steps,
      mode:         mode || 'paragraph',
      lang:         lang || 'english'
    });
  } catch(err) { return res.status(500).json({ success:false, message: err.message }); }
});

// ── 18.2 Bulk explanation generate
router.post('/ai/explanation/bulk', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionIds, mode, lang, autoSave } = req.body;
    if (!questionIds || questionIds.length === 0)
      return res.status(400).json({ success:false, message:'questionIds array required' });

    const results = [];
    for (const qId of questionIds) {
      try {
        const question = await Question.findById(qId);
        if (!question) { results.push({ questionId:qId, success:false, message:'Not found' }); continue; }
        const correctIdx = Array.isArray(question.correct) && question.correct.length > 0 ? question.correct[0] : 0;
        const prompt = buildExplPrompt({ text:question.text, options:question.options||[], correctIdx, mode:mode||'paragraph', lang:lang||'english' });
        const raw = await callGroqAI(prompt);
        let parsed = { explanation:raw, qualityScore:3, steps:[] };
        try { const j=JSON.parse(raw.replace(/\`\`\`json|\`\`\`/g,'').trim()); parsed={explanation:j.explanation||raw,qualityScore:j.qualityScore||3,steps:j.steps||[]}; } catch(_){}

        // 18.9 Auto-save if requested
        if (autoSave) {
          const update = lang === 'hindi'
            ? { hindiExplanation: parsed.explanation }
            : { explanation: parsed.explanation };
          await Question.findByIdAndUpdate(qId, update);
        }
        results.push({ questionId:qId, success:true, explanation:parsed.explanation, qualityScore:parsed.qualityScore, steps:parsed.steps, questionText:question.text.slice(0,80) });
      } catch(e) { results.push({ questionId:qId, success:false, message:e.message }); }
    }

    const done = results.filter(r=>r.success).length;
    return res.json({ success:true, message:\`\${done}/\${questionIds.length} explanations generated\`, results, done, total:questionIds.length });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── 18.6 Hindi explanation
router.post('/ai/explanation/hindi', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionId, mode } = req.body;
    if (!questionId) return res.status(400).json({ success:false, message:'questionId required' });
    const question = await Question.findById(questionId);
    if (!question) return res.status(404).json({ success:false, message:'Not found' });
    const correctIdx = Array.isArray(question.correct)&&question.correct.length>0?question.correct[0]:0;
    const prompt = buildExplPrompt({ text:question.text, options:question.options||[], correctIdx, mode:mode||'paragraph', lang:'hindi' });
    const raw = await callGroqAI(prompt);
    let parsed = { explanation:raw, qualityScore:3, steps:[] };
    try { const j=JSON.parse(raw.replace(/\`\`\`json|\`\`\`/g,'').trim()); parsed={explanation:j.explanation||raw,qualityScore:j.qualityScore||3,steps:j.steps||[]}; } catch(_){}
    return res.json({ success:true, questionId, hindiExplanation:parsed.explanation, qualityScore:parsed.qualityScore, steps:parsed.steps });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── 18.9 Save / Approve explanation
router.put('/:id/explanation/save', verifyToken, isAdmin, async (req, res) => {
  try {
    const { explanation, hindiExplanation, action } = req.body; // action: 'approve'|'reject'
    if (action === 'reject') {
      return res.json({ success:true, message:'Explanation rejected — not saved' });
    }
    const update = {};
    if (explanation)      update.explanation      = explanation;
    if (hindiExplanation) update.hindiExplanation = hindiExplanation;
    await Question.findByIdAndUpdate(req.params.id, update);
    return res.json({ success:true, message:'Explanation saved ✅' });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── 18.12 Pending explanations queue
router.get('/ai/explanation/queue', verifyToken, isAdmin, async (req, res) => {
  try {
    const { subject, limit } = req.query;
    const filter = { $or:[{explanation:{$exists:false}},{explanation:''},{explanation:null}] };
    if (subject && subject !== 'all') filter.subject = subject;
    const questions = await Question.find(filter)
      .select('text subject chapter difficulty type options correct explanation hindiExplanation')
      .limit(parseInt(limit as string)||50)
      .sort({ createdAt:-1 });
    const totalNoExp = await Question.countDocuments(filter);
    const totalAll   = await Question.countDocuments({});
    return res.json({ success:true, questions, totalNoExp, totalAll, withExp:totalAll-totalNoExp });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});`;

if (c.includes(OLD_STUB)) {
  c = c.replace(OLD_STUB, NEW_EXPLANATION);
  console.log('✅ Stub replaced with real AI explanation routes');
} else {
  console.log('⚠️ Stub not found exactly — appending after last route');
  // Find a safe insertion point — before module.exports or at end
  const insertBefore = '// ── N7: QUESTION APPROVAL WORKFLOW';
  if (c.includes(insertBefore)) {
    c = c.replace(insertBefore, NEW_EXPLANATION + '\n\n' + insertBefore);
    console.log('✅ New routes inserted before N7');
  } else {
    c += '\n\n' + NEW_EXPLANATION;
    console.log('✅ New routes appended');
  }
}

fs.writeFileSync(fpath, c,'utf8');

// Verify
const final = fs.readFileSync(fpath,'utf8');
const checks = [
  ['18.1  Single explanation route',    final.includes("router.post('/ai/explanation', verifyToken")],
  ['18.2  Bulk explanation route',      final.includes("router.post('/ai/explanation/bulk'")],
  ['18.6  Hindi explanation route',     final.includes("router.post('/ai/explanation/hindi'")],
  ['18.9  Save/approve route',          final.includes("router.put('/:id/explanation/save'")],
  ['18.10 Quality score in prompt',     final.includes('qualityScore')],
  ['18.11 Step-by-step mode',           final.includes("mode === 'steps'")],
  ['18.12 Queue route',                 final.includes("router.get('/ai/explanation/queue'")],
  ['Real AI (callGroqAI)',              final.includes('callGroqAI')],
  ['Auto-save (18.9)',                  final.includes('autoSave')],
];
console.log('\n── Backend Verification ──');
checks.forEach(([l,ok]) => console.log(\`  \${ok?'✅':'❌'} \${l}\`));
JSEOF

node /tmp/f18_backend.js

echo ""
echo "✅ Backend Feature 18 done!"
