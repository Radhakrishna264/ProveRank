#!/bin/bash
# ProveRank — FINAL CLEANUP: fixes 2 crash-risk refs (Review.js,
# StudentNotification.js still say ref:'Batch' after Batch.js was deleted),
# renames BatchNote.js -> SeriesNote.js (was ALREADY broken — schema
# required a `batch` field that testSeriesManagerUltra.js never provided;
# fixed + renamed since it's 100% Series-only now), and removes every
# remaining confirmed-dead batch reference across routes/frontend found
# in the final sweep. Does NOT touch testSeriesManagerUltra.js's cosmetic
# UI text or TestSeriesManagerUltra.tsx (legacy naming only, not dead code).
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/final_cleanup_backup_$ts.tar.gz \
  src/models/Review.js src/models/StudentNotification.js src/models/BatchNote.js \
  src/models/ExamInstance.js src/models/Banner.js \
  src/routes/examFeatures.js src/routes/exam.js src/routes/testSeriesManagerUltra.js \
  frontend/app/admin/x7k2p/EntryProctoringControlCenter.tsx \
  frontend/app/admin/x7k2p/AdminWelcomeBanner.tsx \
  frontend/app/my-exams/page.tsx 2>/dev/null || true
echo "Backup saved."

node << 'NODEEOF'
const fs = require('fs');
const path = require('path');

function editFile(relPath, edits) {
  const full = path.join(process.cwd(), relPath);
  let lines = fs.readFileSync(full, 'utf8').split('\n');
  for (const e of edits) {
    const actual = lines.slice(e.start - 1, e.end).join('\n');
    const expected = e.old.join('\n');
    if (actual !== expected) {
      console.error(`\nABORT: ${relPath} lines ${e.start}-${e.end} mismatch.`);
      console.error('--- EXPECTED ---\n' + expected);
      console.error('--- FOUND ---\n' + actual);
      process.exit(1);
    }
  }
  const sorted = [...edits].sort((a, b) => b.start - a.start);
  for (const e of sorted) lines.splice(e.start - 1, e.end - e.start + 1, ...e.new);
  fs.writeFileSync(full, lines.join('\n'));
  console.log(`OK — ${relPath}: applied ${edits.length} edit(s).`);
}

// ════════════════════════════════════════════════════════════
// 1) src/models/Review.js — CRITICAL: fix crash-risk ref
// ════════════════════════════════════════════════════════════
editFile('src/models/Review.js', [{
  start: 3, end: 3,
  old: ["  batchId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },"],
  new: ["  batchId:     { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries', required: true },"],
}]);

// ════════════════════════════════════════════════════════════
// 2) src/models/StudentNotification.js — CRITICAL: fix crash-risk ref
// ════════════════════════════════════════════════════════════
editFile('src/models/StudentNotification.js', [{
  start: 7, end: 7,
  old: ["  batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch' },"],
  new: ["  batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries' },"],
}]);

// ════════════════════════════════════════════════════════════
// 3) src/models/ExamInstance.js — remove dead unreferenced field
// ════════════════════════════════════════════════════════════
editFile('src/models/ExamInstance.js', [{
  start: 15, end: 15,
  old: ["  batchId: { type: mongoose.Schema.Types.ObjectId, default: null },"],
  new: [],
}]);

// ════════════════════════════════════════════════════════════
// 4) src/models/Banner.js — remove 'batch' from linkedType enum
// ════════════════════════════════════════════════════════════
editFile('src/models/Banner.js', [{
  start: 48, end: 48,
  old: ["  linkedType: { type: String, default: 'none', enum: ['batch', 'series', 'none'] },"],
  new: ["  linkedType: { type: String, default: 'none', enum: ['series', 'none'] },"],
}]);

// ════════════════════════════════════════════════════════════
// 5) src/routes/examFeatures.js — fix dead Exam.distinct('batch')
// ════════════════════════════════════════════════════════════
editFile('src/routes/examFeatures.js', [
{
  start: 5, end: 5,
  old: ["const User = require('../models/User');"],
  new: ["const User = require('../models/User');\nconst TestSeries = require('../models/TestSeries');"],
},
{
  start: 19, end: 19,
  old: ["    const series = await Exam.distinct('batch');"],
  new: ["    const series = await TestSeries.distinct('name');"],
},
]);

// ════════════════════════════════════════════════════════════
// 6) src/routes/exam.js — remove dead batch query filter
// ════════════════════════════════════════════════════════════
editFile('src/routes/exam.js', [{
  start: 26, end: 28,
  old: [
"    const { batch, category, status } = req.query;",
"    const filter = {};",
"    if (batch) filter.batch = batch;",
  ],
  new: [
"    const { category, status } = req.query;",
"    const filter = {};",
  ],
}]);

// ════════════════════════════════════════════════════════════
// 7) src/routes/testSeriesManagerUltra.js — switch BatchNote → SeriesNote
//    (also fixes the materialsCount field-name bug: batch → series)
// ════════════════════════════════════════════════════════════
editFile('src/routes/testSeriesManagerUltra.js', [
{
  start: 17, end: 20,
  old: [
"let TestSeriesAuditLog, TestSeriesTemplate, BatchNote;",
"try { TestSeriesAuditLog = require('../models/TestSeriesAuditLog'); } catch (e) { TestSeriesAuditLog = null; }",
"try { TestSeriesTemplate  = require('../models/TestSeriesTemplate'); } catch (e) { TestSeriesTemplate = null; }",
"try { BatchNote      = require('../models/BatchNote'); } catch (e) { BatchNote = null; }",
  ],
  new: [
"let TestSeriesAuditLog, TestSeriesTemplate, SeriesNote;",
"try { TestSeriesAuditLog = require('../models/TestSeriesAuditLog'); } catch (e) { TestSeriesAuditLog = null; }",
"try { TestSeriesTemplate  = require('../models/TestSeriesTemplate'); } catch (e) { TestSeriesTemplate = null; }",
"try { SeriesNote      = require('../models/SeriesNote'); } catch (e) { SeriesNote = null; }",
  ],
},
{
  start: 1257, end: 1258,
  old: [
"    if (!BatchNote) return res.json({ materials: [] });",
"    const materials = await BatchNote.find({ series: req.params.id }).sort({ pinned: -1, createdAt: -1 }).lean();",
  ],
  new: [
"    if (!SeriesNote) return res.json({ materials: [] });",
"    const materials = await SeriesNote.find({ series: req.params.id }).sort({ pinned: -1, createdAt: -1 }).lean();",
  ],
},
{
  start: 1265, end: 1267,
  old: [
"    if (!BatchNote) return res.status(500).json({ error: 'Materials model unavailable' });",
"    const { title, type, url, category, expiryDate } = req.body;",
"    const note = await BatchNote.create({ series: req.params.id, title, type, url, subject: category || 'General', expiryDate: expiryDate ? new Date(expiryDate) : null, pinned: false, version: 1, createdBy: req.user.id });",
  ],
  new: [
"    if (!SeriesNote) return res.status(500).json({ error: 'Materials model unavailable' });",
"    const { title, type, url, category, expiryDate } = req.body;",
"    const note = await SeriesNote.create({ series: req.params.id, title, type, url, subject: category || 'General', expiryDate: expiryDate ? new Date(expiryDate) : null, pinned: false, version: 1, createdBy: req.user.id });",
  ],
},
{
  start: 1275, end: 1277,
  old: [
"    if (!BatchNote) return res.status(500).json({ error: 'Materials model unavailable' });",
"    const { pinned, category, expiryDate, title } = req.body;",
"    const note = await BatchNote.findById(req.params.noteId);",
  ],
  new: [
"    if (!SeriesNote) return res.status(500).json({ error: 'Materials model unavailable' });",
"    const { pinned, category, expiryDate, title } = req.body;",
"    const note = await SeriesNote.findById(req.params.noteId);",
  ],
},
{
  start: 1290, end: 1290,
  old: ["    if (BatchNote) await BatchNote.findByIdAndDelete(req.params.noteId);"],
  new: ["    if (SeriesNote) await SeriesNote.findByIdAndDelete(req.params.noteId);"],
},
{
  start: 1464, end: 1464,
  old: ["  try { if (BatchNote) materialsCount = await BatchNote.countDocuments({ batch: series._id }); } catch (e) {}"],
  new: ["  try { if (SeriesNote) materialsCount = await SeriesNote.countDocuments({ series: series._id }); } catch (e) {}"],
},
{
  start: 1474, end: 1474,
  old: ["  try { if (BatchNote) materialsCount = await BatchNote.countDocuments({ batch: series._id }); } catch (e) {}"],
  new: ["  try { if (SeriesNote) materialsCount = await SeriesNote.countDocuments({ series: series._id }); } catch (e) {}"],
},
]);

console.log('\\n✅ Backend model/route fixes applied.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Rename BatchNote.js → SeriesNote.js (with schema fix)"
echo "═══════════════════════════════════════════"
cat > src/models/SeriesNote.js << 'FILEEOF'
const mongoose=require('mongoose');
const SeriesNoteSchema=new mongoose.Schema({
  series:{type:mongoose.Schema.Types.ObjectId,ref:'TestSeries',required:true},
  title:{type:String,required:true,trim:true},
  description:{type:String,default:''},
  url:{type:String,default:''},
  type:{type:String,enum:['pdf','video','doc','link','image','other'],default:'link'},
  subject:{type:String,default:'General'},
  createdBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
  pinned:{type:Boolean,default:false},
  expiryDate:{type:Date,default:null},
  version:{type:Number,default:1},
  // ── Series Workspace (student read-tracking) — additive, non-breaking ──
  viewedBy:[{
    studentId:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
    viewedAt:{type:Date,default:Date.now}
  }],
},{timestamps:true});
module.exports=mongoose.model('SeriesNote',SeriesNoteSchema);
FILEEOF
rm -fv src/models/BatchNote.js
echo "OK — renamed BatchNote.js → SeriesNote.js (field 'batch'→'series', ref 'Batch'→'TestSeries')"

echo "═══════════════════════════════════════════"
echo "STEP — Frontend: EntryProctoringControlCenter.tsx"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = require('path');
function editFile(relPath, edits) {
  const full = path.join(process.cwd(), relPath);
  let lines = fs.readFileSync(full, 'utf8').split('\n');
  for (const e of edits) {
    const actual = lines.slice(e.start - 1, e.end).join('\n');
    const expected = e.old.join('\n');
    if (actual !== expected) {
      console.error(`\nABORT: ${relPath} lines ${e.start}-${e.end} mismatch.`);
      console.error('--- EXPECTED ---\n' + expected);
      console.error('--- FOUND ---\n' + actual);
      process.exit(1);
    }
  }
  const sorted = [...edits].sort((a, b) => b.start - a.start);
  for (const e of sorted) lines.splice(e.start - 1, e.end - e.start + 1, ...e.new);
  fs.writeFileSync(full, lines.join('\n'));
  console.log(`OK — ${relPath}: applied ${edits.length} edit(s).`);
}

editFile('frontend/app/admin/x7k2p/EntryProctoringControlCenter.tsx', [
{
  start: 88, end: 88,
  old: ["  const [newScope, setNewScope] = useState<{ type: string; examId: string; batchId: string; testSeriesId: string; name: string }>({ type: 'global', examId: '', batchId: '', testSeriesId: '', name: '' })"],
  new: ["  const [newScope, setNewScope] = useState<{ type: string; examId: string; testSeriesId: string; name: string }>({ type: 'global', examId: '', testSeriesId: '', name: '' })"],
},
{
  start: 115, end: 115,
  old: ["      if (newScope.type === 'batch') scope.batchId = newScope.batchId"],
  new: [],
},
{
  start: 490, end: 490,
  old: ["              <option value=\"batch\">Batch</option>"],
  new: [],
},
{
  start: 494, end: 494,
  old: ["            {newScope.type === 'batch' && <input placeholder=\"Batch ID\" value={newScope.batchId} onChange={e => setNewScope(s => ({ ...s, batchId: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />}"],
  new: [],
},
]);

editFile('frontend/app/admin/x7k2p/AdminWelcomeBanner.tsx', [{
  start: 26, end: 26,
  old: ["  manageBatches: '🎓 Batch Mgmt',"],
  new: [],
}]);
console.log('OK — frontend admin cleanup done.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Frontend: my-exams/page.tsx (dead batch matching/display)"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/app/my-exams/page.tsx';
let lines = fs.readFileSync(path, 'utf8').split('\n');

function assertLine(ln, expected) {
  const actual = lines[ln - 1];
  if (actual !== expected) {
    console.error(`ABORT: my-exams/page.tsx line ${ln} mismatch.\n  Expected: ${expected}\n  Found:    ${actual}`);
    process.exit(1);
  }
}

const replacements = [
  [43,
    "  const [synced, setSynced] = useState<{ batches: string[]; series: string[] }>({ batches: [], series: [] })",
    "  const [synced, setSynced] = useState<{ series: string[] }>({ series: [] })"],
  [48,
    "  const [batchFilter, setBatchFilter] = useState('all') // holds a batch name OR a series name",
    "  const [seriesFilter, setSeriesFilter] = useState('all') // holds a series name"],
  [62,
    "      if (saved.batchFilter) setBatchFilter(saved.batchFilter)",
    "      if (saved.seriesFilter) setSeriesFilter(saved.seriesFilter)"],
  [68,
    "    localStorage.setItem('pr_myexams_filters', JSON.stringify({ statusFilter, subjectFilter, batchFilter, categoryFilter, search }))",
    "    localStorage.setItem('pr_myexams_filters', JSON.stringify({ statusFilter, subjectFilter, seriesFilter, categoryFilter, search }))"],
  [69,
    "  }, [statusFilter, subjectFilter, batchFilter, categoryFilter, search])",
    "  }, [statusFilter, subjectFilter, seriesFilter, categoryFilter, search])"],
  [78,
    "          setSynced({ batches: d.syncedBatches || [], series: d.syncedSeries || [] })",
    "          setSynced({ series: d.syncedSeries || [] })"],
  [103,
    "  }, [exams, search, statusFilter, subjectFilter, batchFilter, categoryFilter])",
    "  }, [exams, search, statusFilter, subjectFilter, seriesFilter, categoryFilter])"],
  [226,
    "      {(synced.batches.length > 0 || synced.series.length > 0) && (",
    "      {synced.series.length > 0 && ("],
  [230,
    "            {t('Synced', 'Synced')}: {synced.batches.length > 0 && `${synced.batches.length} ${t('Batch(es)', 'Batch(es)')}`}",
    "            {t('Synced', 'Synced')}: "],
  [231,
    "            {synced.batches.length > 0 && synced.series.length > 0 && ' · '}",
    ""],
  [265,
    "          <select value={batchFilter} onChange={e => setBatchFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>",
    "          <select value={seriesFilter} onChange={e => setSeriesFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>"],
  [266,
    "            <option value=\"all\">{t('All Batches/Test Series', 'All Batches/Test Series')}</option>",
    "            <option value=\"all\">{t('All Test Series', 'All Test Series')}</option>"],
  [267,
    "            {batchesAndSeries.map(b => <option key={b} value={b}>{b}</option>)}",
    "            {seriesOptions.map(b => <option key={b} value={b}>{b}</option>)}"],
  [274,
    "        {(search || statusFilter !== 'all' || subjectFilter !== 'all' || batchFilter !== 'all' || categoryFilter !== 'all') && (",
    "        {(search || statusFilter !== 'all' || subjectFilter !== 'all' || seriesFilter !== 'all' || categoryFilter !== 'all') && ("],
  [279,
    "            {batchFilter !== 'all' && <span onClick={() => setBatchFilter('all')} style={{ cursor: 'pointer', fontSize: 11, background: chipBg, border: `1px solid ${border}`, padding: '3px 8px', borderRadius: 20, color: text }}>{batchFilter} ✕</span>}",
    "            {seriesFilter !== 'all' && <span onClick={() => setSeriesFilter('all')} style={{ cursor: 'pointer', fontSize: 11, background: chipBg, border: `1px solid ${border}`, padding: '3px 8px', borderRadius: 20, color: text }}>{seriesFilter} ✕</span>}"],
  [281,
    "            <span onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setBatchFilter('all'); setCategoryFilter('all') }} style={{ cursor: 'pointer', fontSize: 11, color: C.danger, padding: '3px 4px' }}>{t('Clear all', 'Sab clear karo')}</span>",
    "            <span onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setSeriesFilter('all'); setCategoryFilter('all') }} style={{ cursor: 'pointer', fontSize: 11, color: C.danger, padding: '3px 4px' }}>{t('Clear all', 'Sab clear karo')}</span>"],
  [295,
    "            {exams.length > 0 && <button onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setBatchFilter('all'); setCategoryFilter('all') }} style={{ padding: '8px 16px', borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer' }}>{t('Reset Filters', 'Filters Reset Karo')}</button>}",
    "            {exams.length > 0 && <button onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setSeriesFilter('all'); setCategoryFilter('all') }} style={{ padding: '8px 16px', borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer' }}>{t('Reset Filters', 'Filters Reset Karo')}</button>}"],
  [319,
    "                  {e.assignmentType && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.assignmentType === 'mini_test' ? t('Mini Test', 'Mini Test') : e.assignmentType === 'series' ? t('Series', 'Series') : e.assignmentType === 'batch' ? t('Batch', 'Batch') : t('Individual', 'Individual')}</span>}",
    "                  {e.assignmentType && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.assignmentType === 'mini_test' ? t('Mini Test', 'Mini Test') : e.assignmentType === 'series' ? t('Series', 'Series') : t('Individual', 'Individual')}</span>}"],
];

for (const [ln, expected] of replacements) assertLine(ln, expected);

// ── Range: matching logic (95-99) ──
assertLine(95, "      // F52 v4 fix #2 — batchFilter now matches EITHER a batch name/multiBatch OR a series name");
assertLine(96, "      if (batchFilter !== 'all') {");
assertLine(97, "        const matchesBatch = e.batch === batchFilter || (e.multiBatch || []).includes(batchFilter)");
assertLine(98, "        const matchesSeries = e.seriesName === batchFilter");
assertLine(99, "        if (!matchesBatch && !matchesSeries) return false");
assertLine(100, "      }");

// ── Range: batchesAndSeries useMemo (196-202) ──
assertLine(196, "  // F52 v4 fix #2 — merged Batches + Test Series into one synced list for the dropdown");
assertLine(197, "  const batchesAndSeries = useMemo(() => Array.from(new Set([");
assertLine(198, "    ...synced.batches,");
assertLine(199, "    ...synced.series,");
assertLine(200, "    ...exams.map(e => e.batch).filter(Boolean),");
assertLine(201, "    ...exams.map(e => e.seriesName).filter(Boolean)");
assertLine(202, "  ])), [exams, synced])");

// ── Single line: dead e.batch chip (320) ──
assertLine(320, "                  {e.batch && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{e.batch}</span>}");

console.log('All checks passed. Applying edits...');

for (const [ln, , next] of replacements) lines[ln - 1] = next;

const deleteRanges = [
  [94, 99],    // matching logic block (95-99, keep closing brace at 100... wait handle below)
  [195, 200],  // useMemo lines 196-201 (keep closing line 202)
  [319, 319],  // 0-based idx for line 320 dead chip
];
// Precise ranges (0-based, inclusive):
const ranges = [
  [94, 99],   // lines 95-100 minus closing brace kept -> handled via explicit replace below instead
];

fs.writeFileSync(path, lines.join('\n'));

// Now do the two multi-line block replacements precisely (re-read fresh state)
let content = fs.readFileSync(path, 'utf8');
content = content.replace(
`      // F52 v4 fix #2 — batchFilter now matches EITHER a batch name/multiBatch OR a series name
      if (batchFilter !== 'all') {
        const matchesBatch = e.batch === batchFilter || (e.multiBatch || []).includes(batchFilter)
        const matchesSeries = e.seriesName === batchFilter
        if (!matchesBatch && !matchesSeries) return false
      }`,
`      if (seriesFilter !== 'all') {
        if (e.seriesName !== seriesFilter) return false
      }`
);
content = content.replace(
`  // F52 v4 fix #2 — merged Batches + Test Series into one synced list for the dropdown
  const batchesAndSeries = useMemo(() => Array.from(new Set([
    ...synced.batches,
    ...synced.series,
    ...exams.map(e => e.batch).filter(Boolean),
    ...exams.map(e => e.seriesName).filter(Boolean)
  ])), [exams, synced])`,
`  const seriesOptions = useMemo(() => Array.from(new Set([
    ...synced.series,
    ...exams.map(e => e.seriesName).filter(Boolean)
  ])), [exams, synced])`
);
content = content.replace(
`                  {e.batch && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{e.batch}</span>}
`, '');

fs.writeFileSync(path, content);
console.log('OK — my-exams/page.tsx: fully cleaned of dead batch matching/display logic.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
for f in src/models/Review.js src/models/StudentNotification.js src/models/ExamInstance.js src/models/Banner.js src/models/SeriesNote.js src/routes/examFeatures.js src/routes/exam.js src/routes/testSeriesManagerUltra.js; do
  echo "-- node -c $f --"
  node -c "$f" && echo "OK"
done

echo ""
echo "-- remaining 'batch' occurrences in touched files --"
for f in src/models/Review.js src/models/StudentNotification.js src/models/ExamInstance.js src/models/Banner.js src/models/SeriesNote.js src/routes/examFeatures.js src/routes/exam.js frontend/app/admin/x7k2p/EntryProctoringControlCenter.tsx frontend/app/admin/x7k2p/AdminWelcomeBanner.tsx frontend/app/my-exams/page.tsx; do
  echo "[$f]"; grep -n -i "batch" "$f" || echo "  (none)"
done

echo ""
echo "-- confirm zero remaining requires of BatchNote anywhere --"
grep -rn "models/BatchNote" src/ --include="*.js" || echo "(none — clean)"

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS:"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. cd ~/workspace && node src/index.js   (confirm boots clean)"
echo "3. Test in browser: /admin/x7k2p → Test Series Management → open a"
echo "   series → Materials tab → Add Material (should now actually work!)"
echo "4. Only after both pass — git add, commit, push"
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
