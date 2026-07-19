#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# REMOVE: Exam Control Extras from EXAMS/TESTS TAB
#   • Required exam  • Optional/Unlocked exam  • Locked exam
#   • Featured exam  • Hidden exam
# Removed completely from: Batch + TestSeries — backend routes,
# Mongoose schemas, and both admin frontend tabs. Assign/Unassign
# (core exam linking) is untouched and keeps working exactly as before.
# Verified: student panel never reads these flags — zero impact there.
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_MODEL="src/models/Batch.js"
S_MODEL="src/models/TestSeries.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$B_ROUTE" "$S_ROUTE" "$B_MODEL" "$S_MODEL" "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_exam_control_extras.js << 'ENDOFFILE'
const fs = require('fs');

function replaceExact(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error(`❌ [${path}] anchor not found: ${label}`);
      process.exit(1);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src);
  console.log(`✅ ${path} updated`);
}

// ── 1) Batch route: src/routes/batchManagerUltra.js ──
replaceExact('src/routes/batchManagerUltra.js', [
[
'GET /:id/exams — drop control mapping',
`    const meta = batch.examMeta || [];
    assigned = assigned.map(e => ({ ...e, control: meta.find(m => String(m.examId) === String(e._id)) || {} }));
    res.json({ assigned, available, examCount: assigned.length });`,
`    res.json({ assigned, available, examCount: assigned.length });`
],
[
'POST /:id/exams/assign — drop flags',
`    const { examId, required, locked, featured, hidden, priority } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = batch.exams || [];
    if (!batch.exams.some(e => String(e) === String(examId))) batch.exams.push(examId);
    batch.examMeta = batch.examMeta || [];
    batch.examMeta = batch.examMeta.filter(m => String(m.examId) !== String(examId));
    batch.examMeta.push({ examId, required: !!required, locked: !!locked, featured: !!featured, hidden: !!hidden, priority: Number(priority) || 0 });
    batch.lastActivityAt = new Date();`,
`    const { examId } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = batch.exams || [];
    if (!batch.exams.some(e => String(e) === String(examId))) batch.exams.push(examId);
    batch.lastActivityAt = new Date();`
],
[
'DELETE PUT /:id/exams/:examId route entirely',
`router.put('/:id/exams/:examId', auth, isAdmin, async (req, res) => {
  try {
    const { required, locked, featured, hidden, priority } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.examMeta = batch.examMeta || [];
    let m = batch.examMeta.find(x => String(x.examId) === String(req.params.examId));
    if (!m) { m = { examId: req.params.examId }; batch.examMeta.push(m); }
    if (required !== undefined) m.required = !!required;
    if (locked !== undefined) m.locked = !!locked;
    if (featured !== undefined) m.featured = !!featured;
    if (hidden !== undefined) m.hidden = !!hidden;
    if (priority !== undefined) m.priority = Number(priority);
    await batch.save();
    res.json({ success: true, meta: m });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

`,
``
],
[
'DELETE /:id/exams/:examId — drop examMeta filter line',
`    batch.exams = (batch.exams || []).filter(e => String(e) !== String(req.params.examId));
    batch.examMeta = (batch.examMeta || []).filter(m => String(m.examId) !== String(req.params.examId));
    await batch.save();`,
`    batch.exams = (batch.exams || []).filter(e => String(e) !== String(req.params.examId));
    await batch.save();`
]
]);

// ── 2) TestSeries route: src/routes/testSeriesManagerUltra.js ──
replaceExact('src/routes/testSeriesManagerUltra.js', [
[
'GET /:id/tests — drop control mapping',
`    const meta = series.testMeta || [];
    assigned = assigned.map(e => ({ ...e, control: meta.find(m => String(m.testId) === String(e._id)) || {} }));
    res.json({ assigned, available, testCount: assigned.length });`,
`    res.json({ assigned, available, testCount: assigned.length });`
],
[
'POST /:id/tests/assign — drop flags',
`    const { testId, required, locked, featured, hidden, priority } = req.body;
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = series.tests || [];
    if (!series.tests.some(e => String(e) === String(testId))) series.tests.push(testId);
    series.testMeta = series.testMeta || [];
    series.testMeta = series.testMeta.filter(m => String(m.testId) !== String(testId));
    series.testMeta.push({ testId, required: !!required, locked: !!locked, featured: !!featured, hidden: !!hidden, priority: Number(priority) || 0 });
    series.lastActivityAt = new Date();`,
`    const { testId } = req.body;
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = series.tests || [];
    if (!series.tests.some(e => String(e) === String(testId))) series.tests.push(testId);
    series.lastActivityAt = new Date();`
],
[
'DELETE PUT /:id/tests/:testId route entirely',
`router.put('/:id/tests/:testId', auth, isAdmin, async (req, res) => {
  try {
    const { required, locked, featured, hidden, priority } = req.body;
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.testMeta = series.testMeta || [];
    let m = series.testMeta.find(x => String(x.testId) === String(req.params.testId));
    if (!m) { m = { testId: req.params.testId }; series.testMeta.push(m); }
    if (required !== undefined) m.required = !!required;
    if (locked !== undefined) m.locked = !!locked;
    if (featured !== undefined) m.featured = !!featured;
    if (hidden !== undefined) m.hidden = !!hidden;
    if (priority !== undefined) m.priority = Number(priority);
    await series.save();
    res.json({ success: true, meta: m });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

`,
``
],
[
'DELETE /:id/tests/:testId — drop testMeta filter line',
`    series.tests = (series.tests || []).filter(e => String(e) !== String(req.params.testId));
    series.testMeta = (series.testMeta || []).filter(m => String(m.testId) !== String(req.params.testId));
    await series.save();`,
`    series.tests = (series.tests || []).filter(e => String(e) !== String(req.params.testId));
    await series.save();`
]
]);

// ── 3) Batch model: src/models/Batch.js — drop examMeta field ──
replaceExact('src/models/Batch.js', [
[
'Batch schema — remove examMeta field',
`  exams:[{type:mongoose.Schema.Types.ObjectId,ref:'Exam'}],
  examMeta:[{examId:{type:mongoose.Schema.Types.ObjectId,ref:'Exam'},required:Boolean,locked:Boolean,featured:Boolean,hidden:Boolean,priority:{type:Number,default:0}}],`,
`  exams:[{type:mongoose.Schema.Types.ObjectId,ref:'Exam'}],`
]
]);

// ── 4) TestSeries model: src/models/TestSeries.js — drop testMeta field ──
replaceExact('src/models/TestSeries.js', [
[
'TestSeries schema — remove testMeta field',
`  tests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Exam' }],
  testMeta: [{ testId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' }, required: Boolean, locked: Boolean, featured: Boolean, hidden: Boolean, priority: { type: Number, default: 0 } }],`,
`  tests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Exam' }],`
]
]);

// ── 5) Frontend: BatchManagerUltra.tsx — ExamsTab ──
replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
[
'ExamsTab — drop updateFlag fn',
`  const updateFlag = async (examId: string, field: string, val: boolean) => { await fetch(base + '/' + id + '/exams/' + examId, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ [field]: val }) }); load() }
`,
``
],
[
'ExamsTab — drop flags toggle row',
`            <div style={{ display: 'flex', gap: 10, marginTop: 6, flexWrap: 'wrap' }}>
              {['required', 'locked', 'featured', 'hidden'].map(f => (
                <Toggle key={f} on={!!e.control?.[f]} onChange={v => updateFlag(e._id, f, v)} label={f} />
              ))}
            </div>
`,
``
]
]);

// ── 6) Frontend: TestSeriesManagerUltra.tsx — TestsTab ──
replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
[
'TestsTab — drop updateFlag fn',
`  const updateFlag = async (testId: string, field: string, val: boolean) => { await fetch(base + '/' + id + '/tests/' + testId, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ [field]: val }) }); load() }
`,
``
],
[
'TestsTab — drop flags toggle row',
`            <div style={{ display: 'flex', gap: 10, marginTop: 6, flexWrap: 'wrap' }}>
              {['required', 'locked', 'featured', 'hidden'].map(f => (
                <Toggle key={f} on={!!e.control?.[f]} onChange={v => updateFlag(e._id, f, v)} label={f} />
              ))}
            </div>
`,
``
]
]);

console.log('\n✅ ALL 6 FILES PATCHED SUCCESSFULLY');
ENDOFFILE

node /tmp/fix_exam_control_extras.js

echo ""
echo "=== Verifying removal ==="
grep -n "required.*locked.*featured.*hidden\|examMeta\|testMeta" "$B_ROUTE" "$S_ROUTE" "$B_MODEL" "$S_MODEL" "$B_TSX" "$S_TSX" && echo "⚠️ Some references still remain — check above" || echo "✅ Clean — no references left"

echo ""
echo "✅ DONE. Git push karke Render + Vercel pe deploy karo."
