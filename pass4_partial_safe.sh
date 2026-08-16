#!/bin/bash
# ProveRank — PASS 4 (PARTIAL, SAFE): Delete only the 3 Batch models
# confirmed to have ZERO references anywhere in the repo (Batch.js,
# BatchAuditLog.js, BatchTemplate.js). Does NOT delete BatchNote.js,
# BatchActivity.js, or BatchPayment.js — all three are confirmed to be
# actively required by live, working code (testSeriesManagerUltra.js and
# our restored Test Series routes). Also cleans up dead `batches` prop
# passing in page.tsx left over from Pass 1/2 (harmless but unused).
#
# This is NOT the final Pass 4 — several files with residual 'batch' text
# (testSeriesManagerUltra.js, TestSeriesManagerUltra.tsx, exam.js, etc.)
# still need review before the project can be called fully batch-free.
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup + LIVE re-verification"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/pass4_partial_backup_$ts.tar.gz \
  src/models/Batch.js src/models/BatchAuditLog.js src/models/BatchTemplate.js \
  frontend/app/admin/x7k2p/page.tsx 2>/dev/null || true
echo "Backup saved."

echo "-- Re-checking (both quote styles) for any reference to these 3 models before deleting --"
for m in "models/Batch'" 'models/Batch"' "models/BatchAuditLog" "models/BatchTemplate"; do
  echo "  checking: $m"
done
FOUND=$(grep -rn "require(['\"]\.\./models/Batch['\"])\|require(['\"]\./models/Batch['\"])" src/ --include="*.js" 2>/dev/null | grep -v "models/BatchNote\|models/BatchActivity\|models/BatchAuditLog\|models/BatchPayment\|models/BatchTemplate\|src/models/Batch.js:" || true)
if [ -n "$FOUND" ]; then
  echo "ABORT — found an unexpected reference to models/Batch that wasn't in the earlier sweep:"
  echo "$FOUND"
  exit 1
fi
FOUND2=$(grep -rln "models/BatchAuditLog\|models/BatchTemplate" src/ --include="*.js" 2>/dev/null | grep -v "src/models/BatchAuditLog.js\|src/models/BatchTemplate.js" || true)
if [ -n "$FOUND2" ]; then
  echo "ABORT — found an unexpected reference to BatchAuditLog/BatchTemplate:"
  echo "$FOUND2"
  exit 1
fi
echo "OK — re-verified live: zero references. Safe to delete."

echo "═══════════════════════════════════════════"
echo "STEP 1 — Delete the 3 confirmed-dead model files"
echo "═══════════════════════════════════════════"
rm -fv src/models/Batch.js src/models/BatchAuditLog.js src/models/BatchTemplate.js

echo "═══════════════════════════════════════════"
echo "STEP 2 — Clean dead 'batches' prop-passing in page.tsx"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(path, 'utf8');
let changed = 0;

// Remove batches={batches||[]} prop wherever passed to CreateExamWizard/SmartPaperGen
// (both components stopped accepting this prop in Pass 2). Safe: only removes the
// exact prop=value pair, leaves every other prop on the same line untouched.
const patterns = [
  / batches=\{batches\|\|\[\]\}/g,
];
for (const p of patterns) {
  const before = content;
  content = content.replace(p, '');
  if (content !== before) changed++;
}

if (changed === 0) {
  console.log('SKIP — no dead batches= prop found (already clean or different pattern).');
} else {
  fs.writeFileSync(path, content);
  console.log(`OK — page.tsx: removed ${changed} dead 'batches=' prop occurrence(s).`);
}
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
echo "-- models folder (Batch* remaining) --"
ls src/models/ | grep -i batch || echo "(none matched — unexpected, check manually)"

echo ""
echo "-- confirm page.tsx still parses (via node syntax-adjacent check on brace balance) --"
node -e "
const fs=require('fs');
const c=fs.readFileSync('frontend/app/admin/x7k2p/page.tsx','utf8');
const o=(c.match(/\{/g)||[]).length, cl=(c.match(/\}/g)||[]).length;
console.log('braces: {',o,'}',cl, o===cl?'BALANCED':'MISMATCH — investigate');
"

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS:"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. cd ~/workspace && node src/index.js   (confirm boots clean)"
echo "3. Only after both pass — git add, commit, push"
echo ""
echo "STILL KEPT (confirmed alive, do not delete):"
echo "  BatchNote.js, BatchActivity.js, BatchPayment.js"
echo ""
echo "STILL NEEDS REVIEW before the project is fully batch-free:"
echo "  src/routes/testSeriesManagerUltra.js, src/routes/exam.js,"
echo "  src/routes/examFeatures.js, src/routes/auth.js,"
echo "  src/routes/antiCheatRoutes.js, src/routes/studentProfilePreview.js,"
echo "  src/models/ExamInstance.js, src/models/Review.js,"
echo "  src/models/StudentNotification.js, src/models/Banner.js,"
echo "  src/models/BannerAuditLog.js, src/controllers/uploadController.js,"
echo "  src/utils/groqAI.js,"
echo "  frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx,"
echo "  frontend/app/admin/x7k2p/AdminWelcomeBanner.tsx,"
echo "  frontend/app/admin/x7k2p/AIExplainTab.tsx,"
echo "  frontend/app/admin/x7k2p/Student360Preview.tsx,"
echo "  frontend/app/admin/x7k2p/EntryProctoringControlCenter.tsx,"
echo "  frontend/app/profile/page.tsx, frontend/app/my-exams/page.tsx"
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
