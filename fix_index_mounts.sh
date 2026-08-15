#!/bin/bash
# ProveRank — CRITICAL FIX: The previous two scripts (urgent_hotfix_restore_series_api.sh
# and restore_my_test_series.sh) looked for an 'app.listen(' anchor in index.js to mount
# their routes — but this project actually uses 'server.listen(' (Socket.io wraps app in
# an http server). This script checks EACH of the 5 restored route files individually and
# mounts ONLY the ones not already mounted, using the correct anchor. Safe to run even if
# some were already mounted correctly — it will just skip those.
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
cp src/index.js ~/workspace/.pre_batch_removal_backup/index_before_mount_fix_$ts.js
echo "Backup saved."

node << 'NODEEOF'
const fs = require('fs');
const path = 'src/index.js';
let content = fs.readFileSync(path, 'utf8');

const anchor = "server.listen(";
const idx = content.indexOf(anchor);
if (idx === -1) {
  console.error("ABORT — could not find 'server.listen(' in index.js either.");
  console.error("Please paste the last ~20 lines of your live src/index.js so the exact server-start pattern can be confirmed.");
  process.exit(1);
}

// Each entry: [require-check-string, block-to-insert-if-missing]
const routes = [
  {
    check: "require('./routes/studentBatches')",
    block:
`const studentBatchRoutes = require('./routes/studentBatches');
app.use('/api/student/batches', studentBatchRoutes);
`
  },
  {
    check: "require('./routes/studentBatchExtras')",
    block:
`const studentBatchExtrasRoutes = require('./routes/studentBatchExtras');
app.use('/api/student/batch-extras', studentBatchExtrasRoutes);
`
  },
  {
    check: "require('./routes/studentBatchUltra')",
    block:
`const studentBatchUltraRoutes = require('./routes/studentBatchUltra');
app.use('/api/student/batch-ultra', studentBatchUltraRoutes);
`
  },
  {
    check: "require('./routes/myBatches')",
    block:
`const myBatchesRoutes = require('./routes/myBatches');
app.use('/api/my-batches', myBatchesRoutes);
`
  },
  {
    check: "require('./routes/batchActivityRoutes')",
    block:
`const batchActivityRoutes = require('./routes/batchActivityRoutes');
app.use('/api/batch-activity', batchActivityRoutes);
`
  },
];

let toInsert = '';
let insertedNames = [];
let skippedNames = [];
for (const r of routes) {
  if (content.includes(r.check)) {
    skippedNames.push(r.check);
  } else {
    toInsert += r.block;
    insertedNames.push(r.check);
  }
}

if (!toInsert) {
  console.log('SKIP — all 5 routes already mounted. Nothing to do.');
} else {
  const insertion = `// ── Restored Test Series routes (correct anchor: server.listen) ──\n${toInsert}\n`;
  const freshIdx = content.indexOf(anchor); // recompute in case content unchanged so far
  content = content.slice(0, freshIdx) + insertion + content.slice(freshIdx);
  fs.writeFileSync(path, content);
  console.log('OK — mounted:', insertedNames.join(', '));
  if (skippedNames.length) console.log('SKIPPED (already present):', skippedNames.join(', '));
}
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
node -c src/index.js && echo "index.js: syntax OK"

echo ""
echo "-- confirm all 5 routes are now mounted --"
for r in studentBatches studentBatchExtras studentBatchUltra myBatches batchActivityRoutes; do
  if grep -q "require('./routes/$r')" src/index.js; then
    echo "✅ $r — mounted"
  else
    echo "❌ $r — STILL NOT MOUNTED"
  fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS (CRITICAL — verify live payment page works):"
echo "1. cd ~/workspace && node src/index.js   (confirm boots clean, no errors)"
echo "2. Test in browser: /dashboard/test-series — browse/enroll/wishlist"
echo "   AND /dashboard/my-batches — should show enrolled series"
echo "3. Only after BOTH verified working — git add, commit, push"
echo "═══════════════════════════════════════════"
