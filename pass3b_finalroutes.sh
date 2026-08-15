#!/bin/bash
# ProveRank — PASS 3B: Delete the entire Batch CRUD API block from
# adminQuestionMgmtRoutes.js (Step 11 M8 Batch Comparison, Step 12 M3
# Batch Transfer, and the full /batches/* CRUD — everything after the
# legitimate Question Bank / Doubt / Bulk-Exam-Creator routes, which are
# untouched). Also cleans controllers/paperGenerator.js's useAsExam().
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/pass3b_backup_$ts.tar.gz \
  src/routes/adminQuestionMgmtRoutes.js src/controllers/paperGenerator.js 2>/dev/null || true
echo "Backup saved: ~/workspace/.pre_batch_removal_backup/pass3b_backup_$ts.tar.gz"

node << 'NODEEOF'
const fs = require('fs');
const path = require('path');

// ════════════════════════════════════════════════════════════
// 1) src/routes/adminQuestionMgmtRoutes.js — anchored block deletion
// ════════════════════════════════════════════════════════════
{
  const p = 'src/routes/adminQuestionMgmtRoutes.js';
  const content = fs.readFileSync(p, 'utf8');
  const lines = content.split('\n');

  const startAnchor = "// ─── Step 11: Batch vs Batch Comparison (M8) ─────────────────────────────────";
  const endAnchor = "module.exports = router;";

  const startMatches = lines.map((l, i) => l === startAnchor ? i : -1).filter(i => i >= 0);
  const endMatches = lines.map((l, i) => l === endAnchor ? i : -1).filter(i => i >= 0);

  if (startMatches.length !== 1) {
    console.error(`ABORT (${p}): expected exactly 1 match for start anchor, found ${startMatches.length}.`);
    process.exit(1);
  }
  if (endMatches.length !== 1) {
    console.error(`ABORT (${p}): expected exactly 1 match for 'module.exports = router;', found ${endMatches.length}.`);
    process.exit(1);
  }

  const startIdx = startMatches[0]; // 0-based
  const endIdx = endMatches[0];     // 0-based, points to the module.exports line itself

  // Sanity: the block we're about to delete must actually be Batch-only —
  // verify no OTHER "Step N:" section header exists between start and end
  // (which would mean legitimate non-batch routes got swept in by mistake).
  const between = lines.slice(startIdx, endIdx);
  const otherSteps = between.filter(l => /^\/\/ ─── Step \d+:/.test(l) && l !== startAnchor && !l.includes('Batch'));
  if (otherSteps.length > 0) {
    console.error(`ABORT (${p}): found a non-Batch "Step N" section inside the block about to be deleted — aborting to avoid data loss:`);
    otherSteps.forEach(l => console.error('  ' + l));
    process.exit(1);
  }

  // Delete from startIdx through the blank line just before module.exports (endIdx - 1)
  const newLines = [...lines.slice(0, startIdx), ...lines.slice(endIdx)];
  fs.writeFileSync(p, newLines.join('\n'));
  console.log(`OK — ${p}: removed lines ${startIdx + 1}-${endIdx} (${endIdx - startIdx} lines, the entire Batch CRUD block).`);
}

// ════════════════════════════════════════════════════════════
// 2) src/controllers/paperGenerator.js
// ════════════════════════════════════════════════════════════
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

editFile('src/controllers/paperGenerator.js', [
{
  start: 7, end: 7,
  old: ["const Batch      = require('../models/Batch');"],
  new: [],
},
{
  start: 321, end: 321,
  old: ["    const { sets, meta, answerKey, examTitle, assignType, batchId, testSeriesId, type, targetType, selectedSetLabel, startDate, endDate } = req.body;"],
  new: ["    const { sets, meta, answerKey, examTitle, assignType, testSeriesId, type, targetType, selectedSetLabel, startDate, endDate } = req.body;"],
},
{
  start: 384, end: 388,
  old: [
"      // 🔧 FIX — batch/testSeriesId now match real Exam schema fields, resolved via proper IDs",
"      batch:          assignType === 'batch'  ? (batchId || '') : '',",
"      testSeriesId:   assignType === 'series' ? (testSeriesId || null) : null,",
"      seriesName:     resolvedSeriesName,",
"      assignmentType: assignType === 'batch' ? 'batch' : assignType === 'series' ? 'series' : 'individual',",
  ],
  new: [
"      testSeriesId:   assignType === 'series' ? (testSeriesId || null) : null,",
"      seriesName:     resolvedSeriesName,",
"      assignmentType: assignType === 'series' ? 'series' : 'individual',",
  ],
},
{
  start: 403, end: 413,
  old: [
"    // 🔧 FIX (Assign System) — link the exam back into the Batch/TestSeries so it actually",
"    // \"uploads\" into that batch/series (same fix as the main Create Exam wizard).",
"    try {",
"      if (assignType === 'batch' && batchId) {",
"        await Batch.findByIdAndUpdate(batchId, { \$addToSet: { exams: exam._id } });",
"      } else if (assignType === 'series' && testSeriesId) {",
"        await TestSeries.findByIdAndUpdate(testSeriesId, { \$addToSet: { tests: exam._id } });",
"      }",
"    } catch (linkErr) {",
"      console.error('Assign-link warning (exam created but batch/series link failed):', linkErr.message);",
"    }",
  ],
  new: [
"    // 🔧 FIX (Assign System) — link the exam back into the TestSeries so it actually",
"    // \"uploads\" into that series (same fix as the main Create Exam wizard).",
"    try {",
"      if (assignType === 'series' && testSeriesId) {",
"        await TestSeries.findByIdAndUpdate(testSeriesId, { \$addToSet: { tests: exam._id } });",
"      }",
"    } catch (linkErr) {",
"      console.error('Assign-link warning (exam created but series link failed):', linkErr.message);",
"    }",
  ],
},
]);

console.log('\\n✅ Pass 3B applied successfully.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
for f in src/routes/adminQuestionMgmtRoutes.js src/controllers/paperGenerator.js; do
  echo "-- node -c $f --"
  node -c "$f" && echo "OK"
done

echo ""
echo "-- remaining 'batch' occurrences per file --"
for f in src/routes/adminQuestionMgmtRoutes.js src/controllers/paperGenerator.js; do
  echo "[$f]"; grep -n -i "batch" "$f" || echo "  (none)"
done

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS:"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. cd ~/workspace && node src/index.js   (confirm boots clean)"
echo "3. Only after both pass — git add, commit, push"
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
