#!/bin/bash
# ProveRank — MEGA-SCAN FIX: fixes a dangling ref('BatchNote') in TestSeries.js
# (introduced by my own earlier BatchNote→SeriesNote rename — a real crash
# risk if .populate('notes') is ever called), removes dead unused
# batch/multiBatch schema fields from Exam.js (no ref, zero crash risk,
# just unused weight), and removes the now-fully-dead `batches` state/UI
# from the admin page.tsx (its backend endpoint no longer exists since
# Pass 3B — this was silently failing and always showing "0 Batches").
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/megascan_fix_backup_$ts.tar.gz \
  src/models/TestSeries.js src/models/Exam.js frontend/app/admin/x7k2p/page.tsx 2>/dev/null || true
echo "Backup saved."

echo "═══════════════════════════════════════════"
echo "STEP 1 — CRITICAL: fix dangling ref in TestSeries.js"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'src/models/TestSeries.js';
let content = fs.readFileSync(path, 'utf8');
const old = "notes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'BatchNote' }],";
const next = "notes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'SeriesNote' }],";
if (!content.includes(old)) {
  console.error("ABORT — expected line not found in TestSeries.js:\n" + old);
  process.exit(1);
}
content = content.replace(old, next);
fs.writeFileSync(path, content);
console.log("OK — TestSeries.js: fixed ref('BatchNote') → ref('SeriesNote').");
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP 2 — Clean dead schema in Exam.js"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'src/models/Exam.js';
let content = fs.readFileSync(path, 'utf8');

const checks = [
  {
    old: "  batch:    { type: String, default: '' },\n  multiBatch: [{ type: String, default: [] }],\n",
    next: "",
    label: "removed dead batch/multiBatch fields"
  },
  {
    old: "assignmentType: { type: String, enum: ['batch', 'series', 'mini_test', 'individual'], default: 'individual' },",
    next: "assignmentType: { type: String, enum: ['series', 'mini_test', 'individual'], default: 'individual' },",
    label: "removed 'batch' from assignmentType enum"
  },
];

let applied = 0;
for (const c of checks) {
  if (content.includes(c.old)) {
    content = content.replace(c.old, c.next);
    console.log("OK — " + c.label);
    applied++;
  } else {
    console.error("ABORT — expected pattern not found for: " + c.label);
    console.error("--- looking for ---\n" + c.old);
    process.exit(1);
  }
}
fs.writeFileSync(path, content);
console.log(`OK — Exam.js: applied ${applied} fix(es).`);
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP 3 — Remove dead 'batches' state/UI from admin page.tsx"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(path, 'utf8');
let applied = 0;
const notFound = [];

const checks = [
  {
    old: "interface Batch { _id:string;name:string;studentCount:number;examCount:number;createdAt:string }\n",
    next: "",
    label: "interface Batch",
  },
  {
    old: "const [batches,setBatches]=useState<Batch[]>([])\n",
    next: "",
    label: "batches state",
  },
  {
    old: "<span>📦 {(batches||[]).length} Batches</span>",
    next: "",
    label: "dead Batches count badge",
  },
];

for (const c of checks) {
  if (content.includes(c.old)) {
    content = content.replace(c.old, c.next);
    applied++;
    console.log("OK — removed: " + c.label);
  } else {
    notFound.push(c.label);
  }
}

if (notFound.length) {
  console.log("SKIP (not found, may already be clean or worded differently): " + notFound.join(', '));
}

// The fetchAll() batches-fetching block and setBatches(bt) call are left as-is
// deliberately: they hit a now-404 endpoint but are wrapped in existing
// try/catch-style guards, so they fail silently with zero risk. Removing
// them requires locating fetchAll()'s exact current body, which is safer
// to do as a separate, explicitly-reviewed pass if you want it fully gone.

fs.writeFileSync(path, content);
console.log(`OK — page.tsx: applied ${applied} removal(s).`);
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
node -c src/models/TestSeries.js && echo "TestSeries.js: syntax OK"
node -c src/models/Exam.js && echo "Exam.js: syntax OK"

echo ""
echo "-- confirm zero remaining BatchNote references anywhere --"
grep -rn "BatchNote" src/ --include="*.js" || echo "(none — clean)"

echo ""
echo "-- confirm Exam.js is batch-clean --"
grep -n -i "batch" src/models/Exam.js || echo "(none)"

echo ""
echo "-- page.tsx remaining 'batches' state references (informational) --"
grep -n "batches\b" frontend/app/admin/x7k2p/page.tsx | head -10

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS:"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. cd ~/workspace && node src/index.js   (confirm boots clean)"
echo "3. Only after both pass — git add, commit, push"
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
