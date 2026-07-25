#!/bin/bash
set -e
cd ~/workspace

echo "🔎 Step 0 — Verifying target files exist..."
for f in src/controllers/paperGenerator.js frontend/app/admin/x7k2p/SmartPaperGen.tsx frontend/app/admin/x7k2p/page.tsx; do
  if [ ! -f "$f" ]; then echo "❌ Missing: $f — abort"; exit 1; fi
done
echo "✅ All target files found"

echo "🗄️  Step 1 — Backups..."
mkdir -p .fix_backups
ts=$(date +%Y%m%d_%H%M%S)
cp src/controllers/paperGenerator.js ".fix_backups/paperGenerator.js.bak_$ts"
cp frontend/app/admin/x7k2p/SmartPaperGen.tsx ".fix_backups/SmartPaperGen.tsx.bak_$ts"
cp frontend/app/admin/x7k2p/page.tsx ".fix_backups/page.tsx.bak_$ts"
echo "✅ Backups saved in .fix_backups/"

echo "🛠️  Step 2 — Patching src/controllers/paperGenerator.js (useAsExam function)..."
cat > /tmp/patch_papergen_ctrl.js << 'NODEEOF'
const fs = require('fs');
const file = 'src/controllers/paperGenerator.js';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

// 1) Add Batch/TestSeries requires
must(
`const Question = require('../models/Question');
const Exam     = require('../models/Exam');`,
`const Question = require('../models/Question');
const Exam     = require('../models/Exam');
const Batch      = require('../models/Batch');
const TestSeries = require('../models/TestSeries');`,
'add Batch/TestSeries requires'
);

// 2) Replace the entire useAsExam function with fixed assign logic + back-link
const oldBlock = `exports.useAsExam = async (req, res) => {
  try {
    const { sets, meta, answerKey, examTitle, batch, type, targetType, selectedSetLabel } = req.body;

    if (!sets || sets.length === 0)
      return res.status(400).json({ success: false, message: 'No sets provided' });

    const primarySet = sets.find(s => s.setLabel === (selectedSetLabel || 'A')) || sets[0];

    // 17.14 — questionSnapshot includes correct answers (server-side only, never sent to students via attempt API)
    const questionSnapshot = primarySet.questions.map(q => ({
      questionId:      q.questionId,
      set:             primarySet.setLabel,
      serialNo:        q.serialNo,
      text:            q.text,
      hindiText:       q.hindiText        || '', // 17.27
      options:         q.options,
      hindiOptions:    q.hindiOptions     || [], // 17.28
      optionImages:    q.optionImages     || [], // 17.28
      imageUrl:        q.imageUrl         || '', // 17.27
      correct:         q.correct,
      explanation:     q.explanation      || '',
      hindiExplanation: q.hindiExplanation || '', // 17.30
      subject:         q.subject,
      chapter:         q.chapter          || '',
      difficulty:      q.difficulty,
      type:            q.type             || 'SCQ',
      format:          q.format           || '',
      isPYQ:           q.isPYQ            || false
    }));

    // Build sections from subject distribution
    const secMap = {};
    primarySet.questions.forEach(q => {
      if (!secMap[q.subject]) secMap[q.subject] = 0;
      secMap[q.subject]++;
    });
    const sections = Object.entries(secMap).map(([subject, count]) => ({
      name:          subject,
      subject,
      questionCount: count,
      marks:         count * ((meta.markingScheme && meta.markingScheme.correct) || 4)
    }));

    const exam = await Exam.create({
      title:      examTitle || meta.examTitle || 'Smart Generated Exam',
      duration:   meta.duration || 200,
      totalMarks: meta.totalMarks || primarySet.questions.length * 4,
      questions:  primarySet.questions.map(q => q.questionId),
      questionSnapshot,
      sections,
      markingScheme: {
        correct:     (meta.markingScheme && meta.markingScheme.correct)     || 4,
        incorrect:   (meta.markingScheme && meta.markingScheme.incorrect)   || -1,
        unattempted: (meta.markingScheme && meta.markingScheme.unattempted) || 0
      },
      batch:      batch    || '',
      category:   type     || 'Full Mock',
      type:       (meta.mode || 'Custom').toUpperCase(),
      status:     'draft',
      medium:     req.body.medium || 'bilingual', // 17.30
      createdBy:  req.user.id
    });

    // Update usageCount for selected questions
    const qIds = primarySet.questions.map(q => q.questionId);
    await Question.updateMany({ _id: { $in: qIds } }, { $inc: { usageCount: 1 } });

    return res.json({ success: true, message: 'Exam created! ✅', exam: { _id: exam._id, title: exam.title }, examId: exam._id });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};`;

const newBlock = `exports.useAsExam = async (req, res) => {
  try {
    const { sets, meta, answerKey, examTitle, assignType, batchId, testSeriesId, type, targetType, selectedSetLabel } = req.body;

    if (!sets || sets.length === 0)
      return res.status(400).json({ success: false, message: 'No sets provided' });

    const primarySet = sets.find(s => s.setLabel === (selectedSetLabel || 'A')) || sets[0];

    // 17.14 — questionSnapshot includes correct answers (server-side only, never sent to students via attempt API)
    const questionSnapshot = primarySet.questions.map(q => ({
      questionId:      q.questionId,
      set:             primarySet.setLabel,
      serialNo:        q.serialNo,
      text:            q.text,
      hindiText:       q.hindiText        || '', // 17.27
      options:         q.options,
      hindiOptions:    q.hindiOptions     || [], // 17.28
      optionImages:    q.optionImages     || [], // 17.28
      imageUrl:        q.imageUrl         || '', // 17.27
      correct:         q.correct,
      explanation:     q.explanation      || '',
      hindiExplanation: q.hindiExplanation || '', // 17.30
      subject:         q.subject,
      chapter:         q.chapter          || '',
      difficulty:      q.difficulty,
      type:            q.type             || 'SCQ',
      format:          q.format           || '',
      isPYQ:           q.isPYQ            || false
    }));

    // Build sections from subject distribution
    const secMap = {};
    primarySet.questions.forEach(q => {
      if (!secMap[q.subject]) secMap[q.subject] = 0;
      secMap[q.subject]++;
    });
    const sections = Object.entries(secMap).map(([subject, count]) => ({
      name:          subject,
      subject,
      questionCount: count,
      marks:         count * ((meta.markingScheme && meta.markingScheme.correct) || 4)
    }));

    // 🔧 FIX (Assign System) — resolve real Test Series name instead of storing raw ID
    let resolvedSeriesName = '';
    if (assignType === 'series' && testSeriesId) {
      try {
        const seriesDoc = await TestSeries.findById(testSeriesId).select('name title').lean();
        resolvedSeriesName = seriesDoc ? (seriesDoc.name || seriesDoc.title || '') : '';
      } catch {}
    }

    const exam = await Exam.create({
      title:      examTitle || meta.examTitle || 'Smart Generated Exam',
      duration:   meta.duration || 200,
      totalMarks: meta.totalMarks || primarySet.questions.length * 4,
      questions:  primarySet.questions.map(q => q.questionId),
      questionSnapshot,
      sections,
      markingScheme: {
        correct:     (meta.markingScheme && meta.markingScheme.correct)     || 4,
        incorrect:   (meta.markingScheme && meta.markingScheme.incorrect)   || -1,
        unattempted: (meta.markingScheme && meta.markingScheme.unattempted) || 0
      },
      // 🔧 FIX — batch/testSeriesId now match real Exam schema fields, resolved via proper IDs
      batch:          assignType === 'batch'  ? (batchId || '') : '',
      testSeriesId:   assignType === 'series' ? (testSeriesId || null) : null,
      seriesName:     resolvedSeriesName,
      assignmentType: assignType === 'batch' ? 'batch' : assignType === 'series' ? 'series' : 'individual',
      category:   type     || 'Full Mock',
      type:       (meta.mode || 'Custom').toUpperCase(),
      status:     'draft',
      medium:     req.body.medium || 'bilingual', // 17.30
      createdBy:  req.user.id
    });

    // Update usageCount for selected questions
    const qIds = primarySet.questions.map(q => q.questionId);
    await Question.updateMany({ _id: { $in: qIds } }, { $inc: { usageCount: 1 } });

    // 🔧 FIX (Assign System) — link the exam back into the Batch/TestSeries so it actually
    // "uploads" into that batch/series (same fix as the main Create Exam wizard).
    try {
      if (assignType === 'batch' && batchId) {
        await Batch.findByIdAndUpdate(batchId, { \$addToSet: { exams: exam._id } });
      } else if (assignType === 'series' && testSeriesId) {
        await TestSeries.findByIdAndUpdate(testSeriesId, { \$addToSet: { tests: exam._id } });
      }
    } catch (linkErr) {
      console.error('Assign-link warning (exam created but batch/series link failed):', linkErr.message);
    }

    return res.json({ success: true, message: 'Exam created! ✅', exam: { _id: exam._id, title: exam.title }, examId: exam._id });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};`;

must(oldBlock, newBlock, 'rewrite useAsExam with batch/series linking');

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_papergen_ctrl.js
node -c src/controllers/paperGenerator.js && echo "✅ paperGenerator.js syntax OK"

echo "🛠️  Step 3 — Patching frontend/app/admin/x7k2p/SmartPaperGen.tsx..."
cat > /tmp/patch_smartpapergen.js << 'NODEEOF'
const fs = require('fs');
const file = 'frontend/app/admin/x7k2p/SmartPaperGen.tsx';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

// 1) Function signature — accept batches/testSeries props
must(
`export default function SmartPaperGen({ API, token }: { API: string; token: string }) {`,
`export default function SmartPaperGen({ API, token, batches, testSeries }: { API: string; token: string; batches?: any[]; testSeries?: any[] }) {
  const uaeBatches = batches || [];
  const uaeTestSeries = testSeries || [];`,
'function signature + batches/testSeries props'
);

// 2) Replace uaeBatch free-text state with proper assignType/batchId/testSeriesId state
must(
`  const [uaeTitle,    setUaeTitle]      = useState('');
  const [uaeBatch,    setUaeBatch]      = useState('');
  const [uaeType,     setUaeType]       = useState('Full Mock');`,
`  const [uaeTitle,    setUaeTitle]      = useState('');
  const [uaeAssignType, setUaeAssignType] = useState<'open'|'batch'|'series'>('open');
  const [uaeBatchId,    setUaeBatchId]    = useState('');
  const [uaeTestSeriesId, setUaeTestSeriesId] = useState('');
  const [uaeType,     setUaeType]       = useState('Full Mock');`,
'replace uaeBatch state with assignType/batchId/testSeriesId'
);

// 3) Fetch payload — send assignType/batchId/testSeriesId instead of raw batch text
must(
`          examTitle:        uaeTitle || paper.meta.examTitle,
          batch:            uaeBatch,
          type:             uaeType,`,
`          examTitle:        uaeTitle || paper.meta.examTitle,
          assignType:       uaeAssignType,
          batchId:          uaeBatchId,
          testSeriesId:     uaeTestSeriesId,
          type:             uaeType,`,
'fetch payload — assignType/batchId/testSeriesId'
);

// 4) Modal UI — replace free-text "Assign to Batch" input with proper selector + dropdowns
must(
`            <label style={S.label}>Assign to Batch (optional, 17.11)</label>
            <input value={uaeBatch} onChange={e => setUaeBatch(e.target.value)} placeholder="e.g. Batch A, NEET 2025..." style={{ ...S.inp, marginBottom:12 }} />`,
`            <label style={S.label}>Assign To (optional, 17.11)</label>
            <div style={{ display:'flex', gap:8, marginBottom:12 }}>
              {([['open','🌐 Open'],['batch','🏫 Batch'],['series','📚 Test Series']] as const).map(([v,l]) => (
                <button key={v} onClick={() => { setUaeAssignType(v); if (v!=='batch') setUaeBatchId(''); if (v!=='series') setUaeTestSeriesId(''); }} style={{ flex:1, padding:'8px', borderRadius:8, border:\`1px solid \${uaeAssignType===v ? '#6366F1':'rgba(255,255,255,0.1)'}\`, background: uaeAssignType===v ? 'rgba(99,102,241,0.2)':'rgba(255,255,255,0.04)', color: uaeAssignType===v ? '#A5B4FC':'#64748B', cursor:'pointer', fontWeight:700, fontSize:11 }}>
                  {l}
                </button>
              ))}
            </div>
            {uaeAssignType === 'batch' && (
              <select value={uaeBatchId} onChange={e => setUaeBatchId(e.target.value)} style={{ ...S.inp, marginBottom:12 }}>
                <option value="">— Select Batch —</option>
                {uaeBatches.map((b:any) => <option key={b._id} value={b._id}>{b.name}{b.lifecycleStatus?\` · \${b.lifecycleStatus}\`:''}</option>)}
              </select>
            )}
            {uaeAssignType === 'series' && (
              <select value={uaeTestSeriesId} onChange={e => setUaeTestSeriesId(e.target.value)} style={{ ...S.inp, marginBottom:12 }}>
                <option value="">— Select Test Series —</option>
                {uaeTestSeries.map((s:any) => <option key={s._id} value={s._id}>{s.name||s.title}{s.lifecycleStatus?\` · \${s.lifecycleStatus}\`:''}</option>)}
              </select>
            )}`,
'Assign To UI — batch/series dropdowns'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_smartpapergen.js

echo "🛠️  Step 4 — Patching frontend/app/admin/x7k2p/page.tsx (pass batches/testSeries to SmartPaperGen)..."
cat > /tmp/patch_page_smartgen.js << 'NODEEOF'
const fs = require('fs');
const file = 'frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

must(
`<SmartPaperGen API={API} token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''} />`,
`<SmartPaperGen API={API} token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''} batches={batches||[]} testSeries={testSeries||[]} />`,
'pass batches/testSeries props to SmartPaperGen'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_page_smartgen.js

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ ALL PATCHES APPLIED — Smart Paper Generator Assign System Fixed"
echo "═══════════════════════════════════════════════════"
echo "Changed files:"
echo "  1. src/controllers/paperGenerator.js         — batch/series proper IDs + back-link"
echo "  2. frontend/app/admin/x7k2p/SmartPaperGen.tsx — free-text replaced with Batch/Test Series dropdowns"
echo "  3. frontend/app/admin/x7k2p/page.tsx          — passes batches/testSeries to SmartPaperGen"
echo ""
echo "👉 Next steps:"
echo "   1. Restart backend: pkill -f node 2>/dev/null; cd ~/workspace && node src/index.js"
echo "   2. Test 'Create Exam from Paper' modal — Batch/Test Series dropdowns should populate & sync"
echo "   3. git add -A && git commit -m 'Fix: Smart Paper Generator assign system - batch/testseries dropdown + backlink' && git push"
