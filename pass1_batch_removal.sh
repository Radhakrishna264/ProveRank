#!/bin/bash
# ProveRank — PASS 1: Safe Batch System Removal (dedicated files only)
# Removes: standalone Batch routes, Batch Manager admin UI, BatchDetailOverlay,
#          Batch nav links. Does NOT touch Batch.js model or mixed files
#          (announcements.js, examFlow.js, examBuilder.js, examWizardRoutes.js,
#          adminSystem.js) — those need PASS 2 with full-file review.
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup (safety net)"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/backup_$ts.tar.gz \
  src/index.js \
  src/routes/adminBatchControls.js src/routes/batchActivityRoutes.js src/routes/batchManagerUltra.js \
  src/routes/myBatches.js src/routes/studentBatchExtras.js src/routes/studentBatchUltra.js \
  src/routes/studentBatchWorkspace.js src/routes/studentBatches.js \
  frontend/app/admin/x7k2p/page.tsx \
  frontend/app/admin/x7k2p/BatchManagerUltra.tsx \
  frontend/src/components/StudentShell.tsx \
  frontend/app/dashboard/my-batches \
  frontend/app/admin/x7k2p/batch-controls 2>/dev/null || true
echo "Backup saved: ~/workspace/.pre_batch_removal_backup/backup_$ts.tar.gz"

echo "═══════════════════════════════════════════"
echo "STEP 1 — Edit src/index.js (remove 16 batch route-mount lines)"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'src/index.js';
let lines = fs.readFileSync(path, 'utf8').split('\n');

// [1-based line number, exact expected content]
const toDelete = [
  [151, "const adminBatchControlRoutes  = require('./routes/adminBatchControls');"],
  [152, "const studentBatchExtrasRoutes = require('./routes/studentBatchExtras');"],
  [154, "app.use('/api/admin/batch-controls',  adminBatchControlRoutes);"],
  [155, "const batchManagerUltraRoutes = require('./routes/batchManagerUltra');"],
  [156, "app.use('/api/admin/batch-manager', batchManagerUltraRoutes);"],
  [157, "app.use('/api/student/batch-extras',  studentBatchExtrasRoutes);"],
  [166, "const batchActivityRoutes = require('./routes/batchActivityRoutes');"],
  [167, "app.use('/api/batch-activity', batchActivityRoutes);"],
  [186, "const studentBatchRoutes=require('./routes/studentBatches');"],
  [187, "const studentBatchWorkspaceRoutes = require('./routes/studentBatchWorkspace');"],
  [189, "const myBatchesRoutes=require('./routes/myBatches');"],
  [195, "app.use('/api/my-batches',myBatchesRoutes);"],
  [196, "app.use('/api/student/batches',studentBatchRoutes);"],
  [197, "app.use('/api/student/batch-workspace', studentBatchWorkspaceRoutes);"],
  [215, "const studentBatchUltraRoutes = require('./routes/studentBatchUltra');"],
  [216, "app.use('/api/student/batch-ultra', studentBatchUltraRoutes);"],
];

// Verify all first — abort loudly if anything mismatches
for (const [ln, expected] of toDelete) {
  const actual = lines[ln - 1];
  if (actual !== expected) {
    console.error(`ABORT: index.js line ${ln} mismatch.\n  Expected: ${expected}\n  Found:    ${actual}`);
    process.exit(1);
  }
}

// Delete in descending order so indices stay valid
const idxs = toDelete.map(([ln]) => ln - 1).sort((a, b) => b - a);
for (const idx of idxs) lines.splice(idx, 1);

fs.writeFileSync(path, lines.join('\n'));
console.log(`OK — index.js: removed ${toDelete.length} lines.`);
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP 2 — Edit frontend/src/components/StudentShell.tsx"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/src/components/StudentShell.tsx';
let lines = fs.readFileSync(path, 'utf8').split('\n');

const checks = [
  [52, "  {label:'Batches & Store',labelHi:'बैच और स्टोर',items:[", "  {label:'Test Series & Store',labelHi:'टेस्ट सीरीज और स्टोर',items:["],
  [53, "    {id:'my-batches',icon:'📚',en:'My Batches & Test Series',hi:'मेरे बैच और टेस्ट सीरीज',href:'/dashboard/my-batches'},", null], // delete
  [54, "    {id:'test-series',icon:'📚',en:'Batches & Test Series',hi:'बैच और टेस्ट सीरीज',href:'/dashboard/test-series'},", "    {id:'test-series',icon:'📚',en:'Test Series',hi:'टेस्ट सीरीज',href:'/dashboard/test-series'},"],
];

for (const [ln, expected] of checks) {
  const actual = lines[ln - 1];
  if (actual !== expected) {
    console.error(`ABORT: StudentShell.tsx line ${ln} mismatch.\n  Expected: ${expected}\n  Found:    ${actual}`);
    process.exit(1);
  }
}

// Apply replacements first (line 52, 54), then delete line 53
lines[51] = checks[0][2];
lines[53] = checks[2][2];
lines.splice(52, 1); // delete line 53 (0-based idx 52)

fs.writeFileSync(path, lines.join('\n'));
console.log('OK — StudentShell.tsx: removed My Batches nav link, relabeled Test Series link.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP 3 — Edit frontend/app/admin/x7k2p/page.tsx (biggest file)"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/app/admin/x7k2p/page.tsx';
let lines = fs.readFileSync(path, 'utf8').split('\n');

function assertLine(ln, expected) {
  const actual = lines[ln - 1];
  if (actual !== expected) {
    console.error(`ABORT: page.tsx line ${ln} mismatch.\n  Expected: ${expected}\n  Found:    ${actual}`);
    process.exit(1);
  }
}

// ── Verify + collect single-line DELETIONS (1-based) ──
const singleDeletes = [
  [2, "import BatchManagerUltra from './BatchManagerUltra'"],
  [389, "    {key:'batches',label:'Batches',icon:'🗂️'},"],
  [1135, "  const [selectedBatch,setSelectedBatch]=useState<any>(null)"],
  [1331, "  // Batch management"],
  [1332, "  const batchNameR=useRef('')"],
  [1333, "  const [creatingBatch,setCreatingBatch]=useState(false)"],
  [1334, "  const [batchTransStdId,setBatchTransStdId]=useState('')"],
  [1335, "  const [batchTransTo,setBatchTransTo]=useState('')"],
  [2281, "    {id:'batches',ico:'📦',lbl:'Batch Management',grp:'Students'},"],
  [2318, "    batch_transfer:['batches','test_series'],"],
  [2350, "{/* BD_OVERLAY_INJECTED */}"],
  [4185, "          {/* == BATCHES == (FPR1 Ultra SaaS Upgrade) */}"],
  [4186, "          {tab==='batches'&&(<BatchManagerUltra token={token} API={API}/>)}"],
  [4484, "                      {k:'batch_transfer',l:'Batch Transfer',d:'Move students between batches (M3)'},"],
];
// Line 2351 (BatchDetailOverlay JSX) is huge/exact-verbatim risky to hardcode char-for-char;
// verify by unique substring instead, then mark for deletion.
const line2351 = lines[2350];
if (!line2351 || !line2351.startsWith("{selectedBatch!=null&&<BatchDetailOverlay")) {
  console.error(`ABORT: page.tsx line 2351 does not start with expected BatchDetailOverlay JSX.\n  Found: ${line2351}`);
  process.exit(1);
}

for (const [ln, expected] of singleDeletes) assertLine(ln, expected);

// ── Verify + collect RANGE deletions (1-based, inclusive) ──
// Range 1: BatchDetailOverlay function body (comment through blank line before AdminPanel)
assertLine(651, "// BatchDetailOverlay — S5/M3 Complete Batch Detail");
assertLine(1095, "}");
assertLine(1096, "");
assertLine(1097, "export default function AdminPanel() {");
// Range 2: Batches block inside global search results
assertLine(562, "            {show('batches')&&results?.batches?.length>0&&<div>");
assertLine(570, "                  <span style={S.chip('rgba(0,200,200,0.15)','#00C8C8')}>Batch</span>");
assertLine(573, "            </div>}");
// Range 3: Auto-open batch from URL block
assertLine(1459, "    // Auto-open batch from URL (refresh fix)");
assertLine(1471, "    }");
// Range 4: createBatch + batchTransfer functions
assertLine(2130, "  // ══ BATCH ══");
assertLine(2149, "  },[batchTransStdId,batchTransTo,token,T])");

const ranges = [
  [651, 1096],
  [562, 573],
  [1459, 1471],
  [2130, 2149],
];

// ── Verify + collect REPLACEMENTS (1-based) ──
const replacements = [
  [161,
    "interface Exam { _id:string;title:string;scheduledAt:string;totalMarks:number;duration:number;status:string;attempts?:number;category?:string;password?:string;batch?:string;subject?:string }",
    "interface Exam { _id:string;title:string;scheduledAt:string;totalMarks:number;duration:number;status:string;attempts?:number;category?:string;password?:string;subject?:string }"],
  [363,
    "  {label:'All Students',tab:'students',icon:'👥'},{label:'Batch Manager',tab:'batches',icon:'🗂️'},{label:'Test Series Management',tab:'test_series',icon:'📚'},",
    "  {label:'All Students',tab:'students',icon:'👥'},{label:'Test Series Management',tab:'test_series',icon:'📚'},"],
  [410,
    "  const totalCount=(results?((results.students?.length||0)+(results.admins?.length||0)+(results.exams?.length||0)+(results.questions?.length||0)+(results.batches?.length||0)):0)+navResults.length",
    "  const totalCount=(results?((results.students?.length||0)+(results.admins?.length||0)+(results.exams?.length||0)+(results.questions?.length||0)):0)+navResults.length"],
  [434,
    '        <input style={S.input} value={q} onChange={e=>setQ(e.target.value)} placeholder="Search tabs, students, exams, questions, batches, admins..."/>',
    '        <input style={S.input} value={q} onChange={e=>setQ(e.target.value)} placeholder="Search tabs, students, exams, questions, admins..."/>'],
  [443,
    "            {[{icon:'👥',label:'Students',color:'#00C864'},{icon:'📋',label:'Exams',color:'#4D9FFF'},{icon:'📚',label:'Questions',color:'#964DFF'},{icon:'🗂️',label:'Batches',color:'#00C8C8'},{icon:'👤',label:'Admins',color:'#FFA500'},{icon:'🗂️',label:'Tabs',color:'#E8F4FF'}].map((s,i)=>(",
    "            {[{icon:'👥',label:'Students',color:'#00C864'},{icon:'📋',label:'Exams',color:'#4D9FFF'},{icon:'📚',label:'Questions',color:'#964DFF'},{icon:'👤',label:'Admins',color:'#FFA500'},{icon:'🗂️',label:'Tabs',color:'#E8F4FF'}].map((s,i)=>("],
  [460,
    "            <div style={{fontSize:12,color:'#6B8BAF',lineHeight:1.6}}>Type at least 2 characters to search across<br/>Students · Admins · Exams · Questions · Batches · Navigation Tabs</div>",
    "            <div style={{fontSize:12,color:'#6B8BAF',lineHeight:1.6}}>Type at least 2 characters to search across<br/>Students · Admins · Exams · Questions · Navigation Tabs</div>"],
  [1159,
    "  const eBatchR=useRef('');const eInstrR=useRef('')",
    "  const eInstrR=useRef('')"],
  [1318,
    "  view_students:false,ban_student:false,impersonate:false,export_data:false,batch_transfer:false,",
    "  view_students:false,ban_student:false,impersonate:false,export_data:false,"],
  [1499,
    "      const body={title,scheduledAt:new Date(date).toISOString(),totalMarks:parseInt(eMarksR.current)||720,duration:parseInt(eDurR.current)||200,subject:'NEET',type:'NEET',difficulty:'Mixed',category:eCatR.current||'Full Mock',batch:eBatchR.current||undefined,customInstructions:eInstrR.current||undefined,password:ePassR.current||undefined}",
    "      const body={title,scheduledAt:new Date(date).toISOString(),totalMarks:parseInt(eMarksR.current)||720,duration:parseInt(eDurR.current)||200,subject:'NEET',type:'NEET',difficulty:'Mixed',category:eCatR.current||'Full Mock',customInstructions:eInstrR.current||undefined,password:ePassR.current||undefined}"],
  [4813,
    "                  <div><label style={lbl}>Target</label><SSelect val='all' onChange={()=>{}} opts={[{v:'all',l:'All Students'},{v:'batch',l:'Specific Batch'}]} style={{...inp}}/></div>",
    "                  <div><label style={lbl}>Target</label><SSelect val='all' onChange={()=>{}} opts={[{v:'all',l:'All Students'}]} style={{...inp}}/></div>"],
];

for (const [ln, expected] of replacements) assertLine(ln, expected);

console.log('All 29 checks passed. Applying edits...');

// ── Apply: replacements first (line content, no length change) ──
for (const [ln, , next] of replacements) lines[ln - 1] = next;

// ── Apply: single-line deletes + range deletes, all via one sorted descending splice pass ──
const deleteRanges = [
  ...singleDeletes.map(([ln]) => [ln - 1, ln - 1]),
  [2350, 2350], // line 2351 BatchDetailOverlay JSX (0-based idx 2350)
  ...ranges.map(([s, e]) => [s - 1, e - 1]),
];
deleteRanges.sort((a, b) => b[0] - a[0]);
for (const [start, end] of deleteRanges) {
  lines.splice(start, end - start + 1);
}

fs.writeFileSync(path, lines.join('\n'));
console.log(`OK — page.tsx: applied ${replacements.length} replacements + ${deleteRanges.length} deletion blocks.`);
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP 4 — Delete standalone Batch-only files"
echo "═══════════════════════════════════════════"
rm -fv \
  src/routes/adminBatchControls.js \
  src/routes/batchActivityRoutes.js \
  src/routes/batchManagerUltra.js \
  src/routes/myBatches.js \
  src/routes/studentBatchExtras.js \
  src/routes/studentBatchUltra.js \
  src/routes/studentBatchWorkspace.js \
  src/routes/studentBatches.js \
  frontend/app/admin/x7k2p/BatchManagerUltra.tsx

rm -rfv \
  frontend/app/dashboard/my-batches \
  frontend/app/admin/x7k2p/batch-controls

echo "═══════════════════════════════════════════"
echo "STEP 5 — Sanity checks"
echo "═══════════════════════════════════════════"
echo "-- index.js syntax check --"
node -c src/index.js && echo "index.js: syntax OK"

echo "-- remaining 'batch' occurrences in page.tsx (expected: only kept Pass-2 items ~9) --"
grep -n -i "batch" frontend/app/admin/x7k2p/page.tsx || echo "(none found)"

echo "-- remaining 'batch' occurrences in StudentShell.tsx (expected: 0) --"
grep -n -i "batch" frontend/src/components/StudentShell.tsx || echo "(none found)"

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS (important):"
echo "1. cd ~/workspace/frontend && npm run build   (catch any TS/JSX error before deploy)"
echo "2. cd ~/workspace && node src/index.js         (confirm server boots clean)"
echo "3. Only after both pass — git add, commit, push"
echo "Backup is at ~/workspace/.pre_batch_removal_backup/ if anything looks wrong."
echo "═══════════════════════════════════════════"
