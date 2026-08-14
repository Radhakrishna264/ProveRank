#!/bin/bash
# ProveRank — HOTFIX: fix orphan </div> in AllExams.tsx (Pass 2 bug)
# Root cause: Pass 2 removed a grid-wrapper <div>'s OPENING tag (the Batch
# field) but left its matching CLOSING tag behind (after the Test Series
# field), which broke JSX balance and failed the Vercel/Turbopack build.
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
cp frontend/app/admin/x7k2p/AllExams.tsx ~/workspace/.pre_batch_removal_backup/AllExams_before_hotfix_$ts.tsx
echo "Backup saved: ~/workspace/.pre_batch_removal_backup/AllExams_before_hotfix_$ts.tsx"

node << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/app/admin/x7k2p/AllExams.tsx';
let content = fs.readFileSync(path, 'utf8');

const anchor = `                <div>
                  <label style={lbl}>Test Series / Mini Series</label>
                  <input list="series-suggestions" value={editForm.seriesName} onChange={e=>setEditForm((f:any)=>({...f,seriesName:e.target.value}))} style={inp} placeholder="Leave blank, or pick/type a series name"/>
                </div>
              </div>`;

const occurrences = content.split(anchor).length - 1;
if (occurrences !== 1) {
  console.error(`ABORT: expected exactly 1 occurrence of the broken pattern, found ${occurrences}.`);
  console.error('The file may already be fixed, or differ from what this hotfix expects.');
  console.error('No changes made — please share the current file for a manual check.');
  process.exit(1);
}

const fixed = `                <div>
                  <label style={lbl}>Test Series / Mini Series</label>
                  <input list="series-suggestions" value={editForm.seriesName} onChange={e=>setEditForm((f:any)=>({...f,seriesName:e.target.value}))} style={inp} placeholder="Leave blank, or pick/type a series name"/>
                </div>`;

content = content.replace(anchor, fixed);
fs.writeFileSync(path, content);
console.log('OK — removed the orphan </div>. AllExams.tsx JSX balance restored.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Verify bracket balance restored"
echo "═══════════════════════════════════════════"
node -e "
const fs = require('fs');
const c = fs.readFileSync('frontend/app/admin/x7k2p/AllExams.tsx','utf8');
const o = (c.match(/</g)||[]).length===undefined?0:0; // noop
const opens = (c.match(/\<div/g)||[]).length;
console.log('Sanity: file read OK, length', c.length, 'chars');
"

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS (important — verify before pushing):"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. Only if build succeeds — git add, commit, push"
echo "═══════════════════════════════════════════"
