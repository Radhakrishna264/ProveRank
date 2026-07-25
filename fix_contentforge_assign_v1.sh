#!/bin/bash
set -e
cd ~/workspace

echo "🔎 Step 0 — Verifying target files exist..."
for f in src/utils/examBuilder.js src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx; do
  if [ ! -f "$f" ]; then echo "❌ Missing: $f — abort"; exit 1; fi
done
echo "✅ All target files found"

echo "🗄️  Step 1 — Backups..."
mkdir -p .fix_backups
ts=$(date +%Y%m%d_%H%M%S)
cp src/utils/examBuilder.js ".fix_backups/examBuilder.js.bak_$ts"
cp src/routes/contentForge.js ".fix_backups/contentForge.js.bak_$ts"
cp frontend/app/admin/x7k2p/ContentForge.tsx ".fix_backups/ContentForge.tsx.bak_$ts"
echo "✅ Backups saved in .fix_backups/"

# ════════════════════════════════════════════════════════════════
echo "🛠️  Step 2 — Patching src/utils/examBuilder.js (shared by paste/excel/pdf)..."
cat > /tmp/patch_exambuilder.js << 'NODEEOF'
const fs = require('fs');
const file = 'src/utils/examBuilder.js';
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

// 1) Add TestSeries require
must(
`const Question = require('../models/Question');
const Exam = require('../models/Exam');
const Batch = require('../models/Batch');`,
`const Question = require('../models/Question');
const Exam = require('../models/Exam');
const Batch = require('../models/Batch');
const TestSeries = require('../models/TestSeries');`,
'add TestSeries require'
);

// 2) Function signature — mark as async-aware for series lookup (already async, just need the doc comment note — no code change needed here, skip)

// 3) Remove mini_test category override (mini test removed from Assign system)
must(
`  // F19B.6 / F20B.6 / F21B.9 — Assignment Type resolution
  const assignmentType = assignment.assignmentType || 'individual';
  let category = examDetails.category || 'Full Mock';
  if (assignmentType === 'mini_test') category = 'Mini Test'; // F19B.6.3/20B.6.3/21B.9.3

  // F19B.5.16 / F20B.5.16 / F21B.8.16 — Unlimited attempts -> large maxAttempts (no other code needs to change)
  const maxAttempts = examDetails.unlimitedAttempts ? 99999 : (examDetails.maxAttempts || 1);`,
`  // F19B.6 / F20B.6 / F21B.9 — Assignment Type resolution
  const assignmentType = assignment.assignmentType || 'individual';
  const category = examDetails.category || 'Full Mock';

  // 🔧 FIX (Assign System) — resolve real Test Series name instead of storing raw text
  let resolvedSeriesName = '';
  if (assignmentType === 'series' && assignment.testSeriesId) {
    try {
      const seriesDoc = await TestSeries.findById(assignment.testSeriesId).select('name title').lean();
      resolvedSeriesName = seriesDoc ? (seriesDoc.name || seriesDoc.title || '') : '';
    } catch {}
  }

  // F19B.5.16 / F20B.5.16 / F21B.8.16 — Unlimited attempts -> large maxAttempts (no other code needs to change)
  const maxAttempts = examDetails.unlimitedAttempts ? 99999 : (examDetails.maxAttempts || 1);`,
'remove mini_test branch + resolve real series name'
);

// 4) Fix batch/testSeriesId/assignmentType fields in Exam.create()
must(
`    category,
    batch: assignmentType === 'batch' || assignmentType === 'series' ? (assignment.batch || '') : '',
    multiBatch: assignment.multiBatch || [],
    assignmentType,
    seriesName: assignment.seriesName || '',`,
`    category,
    batch: (assignmentType === 'batch' || assignmentType === 'series') ? (assignment.batch || '') : '',
    multiBatch: assignment.multiBatch || [],
    assignmentType,
    testSeriesId: assignmentType === 'series' ? (assignment.testSeriesId || null) : null,
    seriesName: resolvedSeriesName,`,
'fix batch/testSeriesId/assignmentType fields'
);

// 5) Add Batch/TestSeries back-link after exam + question usage update, before notify block
must(
`  await Question.updateMany({ _id: { $in: inserted.map(d => d._id) } }, { $inc: { usageCount: 1 } }).catch(() => {});

  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle`,
`  await Question.updateMany({ _id: { $in: inserted.map(d => d._id) } }, { $inc: { usageCount: 1 } }).catch(() => {});

  // 🔧 FIX (Assign System) — link the exam back into the Batch/TestSeries so it actually
  // "uploads" into that batch/series (same fix applied to Create Exam wizard + Smart Paper Gen).
  try {
    if (assignmentType === 'batch' && assignment.batch) {
      await Batch.findByIdAndUpdate(assignment.batch, { \$addToSet: { exams: exam._id } });
    } else if (assignmentType === 'series' && assignment.testSeriesId) {
      await TestSeries.findByIdAndUpdate(assignment.testSeriesId, { \$addToSet: { tests: exam._id } });
    }
    if (assignment.multiBatch && assignment.multiBatch.length) {
      await Batch.updateMany({ _id: { \$in: assignment.multiBatch } }, { \$addToSet: { exams: exam._id } });
    }
  } catch (linkErr) {
    console.error('Assign-link warning (exam created but batch/series link failed):', linkErr.message);
  }

  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle`,
'add Batch/TestSeries back-link after exam creation'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_exambuilder.js
node -c src/utils/examBuilder.js && echo "✅ examBuilder.js syntax OK"

# ════════════════════════════════════════════════════════════════
echo "🛠️  Step 3 — Patching src/routes/contentForge.js ('/series' route → real TestSeries list)..."
cat > /tmp/patch_contentforge_route.js << 'NODEEOF'
const fs = require('fs');
const file = 'src/routes/contentForge.js';
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

// 1) Add TestSeries require near other model requires
must(
`const Question = require('../models/Question');
const Exam = require('../models/Exam');
const ContentForgeImportLog = require('../models/ContentForgeImportLog'); // F20.15 import history`,
`const Question = require('../models/Question');
const Exam = require('../models/Exam');
const TestSeries = require('../models/TestSeries');
const ContentForgeImportLog = require('../models/ContentForgeImportLog'); // F20.15 import history`,
'add TestSeries require'
);

// 2) Replace '/series' route — was querying Exam.distinct('seriesName') (old free-typed names only),
//    now returns the real TestSeries collection so the dropdown is properly synced (draft+active both)
must(
`router.get('/series', verifyToken, isAdmin, async (req, res) => {
  try {
    const series = await Exam.distinct('seriesName', { seriesName: { \$ne: '' } });
    res.json({ success: true, series });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`,
`router.get('/series', verifyToken, isAdmin, async (req, res) => {
  try {
    // 🔧 FIX (Assign System) — real TestSeries collection instead of distinct exam seriesName text
    const series = await TestSeries.find({}).select('name title lifecycleStatus').sort({ createdAt: -1 }).limit(200).lean();
    res.json({ success: true, series });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`,
'replace /series route with real TestSeries list'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_contentforge_route.js
node -c src/routes/contentForge.js && echo "✅ contentForge.js syntax OK"

# ════════════════════════════════════════════════════════════════
echo "🛠️  Step 4 — Patching frontend/app/admin/x7k2p/ContentForge.tsx..."
cat > /tmp/patch_contentforge_tsx.js << 'NODEEOF'
const fs = require('fs');
const file = 'frontend/app/admin/x7k2p/ContentForge.tsx';
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

function mustAllOf(oldStr, newStr, expectedCount, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== expectedCount) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected ${expectedCount}). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.split(oldStr).join(newStr);
  console.log(`✅ Patched (${count}x): ${label}`);
}

// 1) AssignmentState interface — remove mini_test, rename seriesName -> testSeriesId
must(
`interface AssignmentState {
  assignmentType: 'batch' | 'series' | 'mini_test' | 'individual';
  batch: string;
  multiBatchEnabled: boolean;
  multiBatch: string[];
  seriesName: string;
  notifyStudents: boolean;
}`,
`interface AssignmentState {
  assignmentType: 'batch' | 'series' | 'individual';
  batch: string;
  multiBatchEnabled: boolean;
  multiBatch: string[];
  testSeriesId: string;
  notifyStudents: boolean;
}`,
'AssignmentState interface'
);

// 2) defaultAssignment() — update default field
must(
`function defaultAssignment(): AssignmentState {
  return { assignmentType: 'individual', batch: '', multiBatchEnabled: false, multiBatch: [], seriesName: '', notifyStudents: false };
}`,
`function defaultAssignment(): AssignmentState {
  return { assignmentType: 'individual', batch: '', multiBatchEnabled: false, multiBatch: [], testSeriesId: '', notifyStudents: false };
}`,
'defaultAssignment()'
);

// 3) AssignmentSelector — seriesList state type (now objects, not strings)
must(
`  const [batches, setBatches] = useState<{_id:string; name:string; studentCount?:number}[]>([]);
  const [seriesList, setSeriesList] = useState<string[]>([]);`,
`  const [batches, setBatches] = useState<{_id:string; name:string; studentCount?:number}[]>([]);
  const [seriesList, setSeriesList] = useState<{_id:string; name:string; title?:string; lifecycleStatus?:string}[]>([]);`,
'seriesList state type'
);

// 4) cards array — remove Mini Test card
must(
`  const cards: { key:AssignmentState['assignmentType']; icon:string; label:string }[] = [
    { key:'batch', icon:'🏫', label:'Assign to Batch' },
    { key:'series', icon:'📚', label:'Test Series' },
    { key:'mini_test', icon:'🧪', label:'Mini Test' },
    { key:'individual', icon:'👤', label:'Individual / Open' },
  ];`,
`  const cards: { key:AssignmentState['assignmentType']; icon:string; label:string }[] = [
    { key:'batch', icon:'🏫', label:'Assign to Batch' },
    { key:'series', icon:'📚', label:'Test Series' },
    { key:'individual', icon:'👤', label:'Individual / Open' },
  ];`,
'cards array — remove Mini Test'
);

// 5) grid columns — 4 -> 3 (one less card now)
must(
`      <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:8, marginBottom:14 }}>`,
`      <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:8, marginBottom:14 }}>`,
'grid columns 4→3'
);

// 6) batch dropdown condition — remove mini_test reference
must(
`      {(a.assignmentType==='batch' || a.assignmentType==='mini_test') && (`,
`      {a.assignmentType==='batch' && (`,
'batch dropdown condition'
);

// 7) Test Series block — replace free-text input+datalist with proper dropdown
must(
`      {a.assignmentType==='series' && (
        <div style={{ marginBottom:10 }}>
          <label style={S.lbl}>Test Series Name</label>
          <input value={a.seriesName} onChange={e=>upd({seriesName:e.target.value})} placeholder="e.g. Weekly Test Series — Batch A" list="series-list" style={S.inp} />
          <datalist id="series-list">{seriesList.map(s=><option key={s} value={s} />)}</datalist>
          <label style={{ ...S.lbl, marginTop:8 }}>Batch (optional)</label>
          <select value={a.batch} onChange={e=>upd({batch:e.target.value})} style={S.inp}>
            <option value="">— Select Batch —</option>
            {batches.map(b=><option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
        </div>
      )}`,
`      {a.assignmentType==='series' && (
        <div style={{ marginBottom:10 }}>
          <label style={S.lbl}>Test Series</label>
          <select value={a.testSeriesId} onChange={e=>upd({testSeriesId:e.target.value})} style={S.inp}>
            <option value="">— Select Test Series —</option>
            {seriesList.map(s=><option key={s._id} value={s._id}>{s.name||s.title}{s.lifecycleStatus?\` · \${s.lifecycleStatus}\`:''}</option>)}
          </select>
          <label style={{ ...S.lbl, marginTop:8 }}>Batch (optional)</label>
          <select value={a.batch} onChange={e=>upd({batch:e.target.value})} style={S.inp}>
            <option value="">— Select Batch —</option>
            {batches.map(b=><option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
        </div>
      )}`,
'Test Series block — free-text → dropdown'
);

// 8) Payload builders (identical block appears 3x — paste/excel/pdf tabs) — seriesName -> testSeriesId
mustAllOf(
`        assignment: {
          assignmentType: assign.assignmentType, batch: assign.batch,
          multiBatch: assign.multiBatchEnabled ? assign.multiBatch : [],
          seriesName: assign.seriesName, notifyStudents: assign.notifyStudents,
        },`,
`        assignment: {
          assignmentType: assign.assignmentType, batch: assign.batch,
          multiBatch: assign.multiBatchEnabled ? assign.multiBatch : [],
          testSeriesId: assign.testSeriesId, notifyStudents: assign.notifyStudents,
        },`,
3,
'payload assignment object (paste/excel/pdf tabs)'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_contentforge_tsx.js

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ ALL PATCHES APPLIED — ContentForge Assign System Fixed (Paste + Excel + PDF, all 3 methods)"
echo "═══════════════════════════════════════════════════"
echo "Changed files:"
echo "  1. src/utils/examBuilder.js       — shared engine: testSeriesId resolve + Batch/TestSeries back-link, mini_test removed"
echo "  2. src/routes/contentForge.js     — /series route now returns real TestSeries collection"
echo "  3. frontend/app/admin/x7k2p/ContentForge.tsx — Mini Test option removed, Test Series free-text → dropdown"
echo ""
echo "👉 Next steps:"
echo "   1. Restart backend: pkill -f node 2>/dev/null; cd ~/workspace && node src/index.js"
echo "   2. Test all 3 tabs (Copy-Paste / Excel-CSV / PDF Parse) — Assignment step should show"
echo "      Batch / Test Series (dropdown, no Mini Test) / Individual, and created exam should"
echo "      appear inside the chosen Batch's/Test Series's list."
echo "   3. git add -A && git commit -m 'Fix: ContentForge assign system - testseries dropdown + backlink, removed mini test' && git push"
