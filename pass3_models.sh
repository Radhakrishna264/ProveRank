#!/bin/bash
# ProveRank — PASS 3: Remove Batch from models (Coupon, Announcement,
# EntryProctoringPolicy) + small cleanups (examInstance.js, contentForge.js).
# Does NOT touch: Batch.js, BatchNote.js, or any other Batch-only model
# (those are deleted together in the final Pass 4, once nothing references
# them). Does NOT touch adminQuestionMgmtRoutes.js or controllers/paperGenerator.js
# — those need their own pass once shared.
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/pass3_backup_$ts.tar.gz \
  src/models/Coupon.js src/models/Announcement.js src/models/EntryProctoringPolicy.js \
  src/routes/examInstance.js src/routes/contentForge.js 2>/dev/null || true
echo "Backup saved: ~/workspace/.pre_batch_removal_backup/pass3_backup_$ts.tar.gz"

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
// 1) src/models/Coupon.js
// ════════════════════════════════════════════════════════════
editFile('src/models/Coupon.js', [
{
  start: 1, end: 5,
  old: [
"// ══════════════════════════════════════════════════════════════════",
"// Coupon — scoped ONLY to a single Batch or single TestSeries via",
"// scopeType + scopeId. No global coupon manager. Uniqueness of `code`",
"// is enforced within (scopeType, scopeId) only, among non-deleted docs.",
"// ══════════════════════════════════════════════════════════════════",
  ],
  new: [
"// ══════════════════════════════════════════════════════════════════",
"// Coupon — scoped ONLY to a single TestSeries via scopeType + scopeId.",
"// No global coupon manager. Uniqueness of `code` is enforced within",
"// (scopeType, scopeId) only, among non-deleted docs.",
"// ══════════════════════════════════════════════════════════════════",
  ],
},
{
  start: 10, end: 10,
  old: ["  scopeType: { type: String, required: true, enum: ['batch', 'series'] },"],
  new: ["  scopeType: { type: String, required: true, enum: ['series'] },"],
},
]);

// ════════════════════════════════════════════════════════════
// 2) src/models/Announcement.js
// ════════════════════════════════════════════════════════════
editFile('src/models/Announcement.js', [
{
  start: 26, end: 28,
  old: [
"    mode:         { type: String, enum: ['all', 'batch', 'testseries', 'students'], default: 'all' }, // F42A §1.2.2 / §2.1.9 (v2: +testseries)",
"    batchIds:     [{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],   // multi-select batches",
"    testSeriesIds:[{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],   // multi-select test series (same underlying collection, tracked separately)",
  ],
  new: [
"    mode:         { type: String, enum: ['all', 'testseries', 'students'], default: 'all' }, // F42A §1.2.2 / §2.1.9 (v2: +testseries)",
"    testSeriesIds:[{ type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries' }],   // multi-select test series",
  ],
},
{
  start: 56, end: 56,
  old: ["  // F42A §2.3.2 per-batch/email delivery status"],
  new: ["  // F42A §2.3.2 per-series/email delivery status"],
},
{
  start: 77, end: 77,
  old: ["AnnouncementSchema.index({ 'audience.batchIds': 1 })"],
  new: ["AnnouncementSchema.index({ 'audience.testSeriesIds': 1 })"],
},
]);

// ════════════════════════════════════════════════════════════
// 3) src/models/EntryProctoringPolicy.js
// ════════════════════════════════════════════════════════════
editFile('src/models/EntryProctoringPolicy.js', [
{
  start: 5, end: 5,
  old: ["// scope (global default / exam / batch / test series / custom)."],
  new: ["// scope (global default / exam / test series / custom)."],
},
{
  start: 41, end: 43,
  old: [
"    type: { type: String, enum: ['global', 'exam', 'batch', 'series', 'subject_group', 'custom'], default: 'global' },",
"    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', default: null },",
"    batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', default: null },",
  ],
  new: [
"    type: { type: String, enum: ['global', 'exam', 'series', 'subject_group', 'custom'], default: 'global' },",
"    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', default: null },",
  ],
},
{
  start: 188, end: 188,
  old: ["EntryProctoringPolicySchema.index({ 'scope.type': 1, 'scope.examId': 1, 'scope.batchId': 1, 'scope.testSeriesId': 1 });"],
  new: ["EntryProctoringPolicySchema.index({ 'scope.type': 1, 'scope.examId': 1, 'scope.testSeriesId': 1 });"],
},
]);

// ════════════════════════════════════════════════════════════
// 4) src/routes/examInstance.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/examInstance.js', [
{
  start: 20, end: 20,
  old: ["    const { examId, setLabel, batchId, sectionTimers } = req.body;"],
  new: ["    const { examId, setLabel, sectionTimers } = req.body;"],
},
{
  start: 65, end: 65,
  old: ["      batchId: batchId || null,"],
  new: [],
},
]);

// ════════════════════════════════════════════════════════════
// 5) src/routes/contentForge.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/contentForge.js', [
{
  start: 260, end: 273,
  old: [
"router.post('/check-duplicates', verifyToken, isAdmin, async (req, res) => {",
"  try {",
"    const { texts, batch } = req.body;",
"    if (!Array.isArray(texts) || texts.length === 0) return res.json({ success: true, duplicates: [] });",
"    const existing = await Question.find({ text: { \$in: texts } }).select('text sourceExam');",
"    let sameBatchExamIds = new Set();",
"    if (batch) {",
"      const exams = await Exam.find({ \$or: [{ batch }, { multiBatch: batch }] }).select('_id');",
"      sameBatchExamIds = new Set(exams.map(e => String(e._id)));",
"    }",
"    const duplicates = existing.map(e => ({ text: e.text, inSameBatch: sameBatchExamIds.has(String(e.sourceExam)) }));",
"    res.json({ success: true, duplicates });",
"  } catch (err) { res.status(500).json({ success: false, message: err.message }); }",
"});",
  ],
  new: [
"router.post('/check-duplicates', verifyToken, isAdmin, async (req, res) => {",
"  try {",
"    const { texts } = req.body;",
"    if (!Array.isArray(texts) || texts.length === 0) return res.json({ success: true, duplicates: [] });",
"    const existing = await Question.find({ text: { \$in: texts } }).select('text');",
"    const duplicates = existing.map(e => ({ text: e.text }));",
"    res.json({ success: true, duplicates });",
"  } catch (err) { res.status(500).json({ success: false, message: err.message }); }",
"});",
  ],
},
]);

console.log('\\n✅ Pass 3 (models + small files) applied successfully.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
for f in src/models/Coupon.js src/models/Announcement.js src/models/EntryProctoringPolicy.js src/routes/examInstance.js src/routes/contentForge.js; do
  echo "-- node -c $f --"
  node -c "$f" && echo "OK"
done

echo ""
echo "-- remaining 'batch' occurrences per file --"
for f in src/models/Coupon.js src/models/Announcement.js src/models/EntryProctoringPolicy.js src/routes/examInstance.js src/routes/contentForge.js; do
  echo "[$f]"; grep -n -i "batch" "$f" || echo "  (none)"
done

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS:"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. cd ~/workspace && node src/index.js   (confirm boots clean)"
echo "3. Only after both pass — git add, commit, push"
echo "NOTE: adminQuestionMgmtRoutes.js (full Batch CRUD API) and"
echo "controllers/paperGenerator.js are NOT touched — Pass 3B, pending."
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
