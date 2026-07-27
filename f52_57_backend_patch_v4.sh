#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F52 v4 — Backend micro-patch"
echo " Adds seriesName + testSeriesId to /my-exams response so"
echo " frontend can filter by enrolled Test Series too (bug #2)"
echo "════════════════════════════════════════════════════════"

BACKEND=""
for candidate in "/root/workspace" "/home/runner/workspace" "$(pwd)"; do
  if [ -d "$candidate/routes" ] && [ -f "$candidate/routes/examFlow.js" ]; then BACKEND="$candidate"; break; fi
done
if [ -z "$BACKEND" ]; then echo "❌ Could not find routes/examFlow.js — set BACKEND env var and re-run."; exit 1; fi
cd "$BACKEND"
echo "📂 Backend root: $BACKEND"
ts=$(date +%s)
cp routes/examFlow.js "routes/examFlow.js.bak_v4_$ts"

node << 'NODEEOF'
const fs = require('fs');
const file = 'routes/examFlow.js';
let src = fs.readFileSync(file, 'utf8');
let count = 0;

// 1) Add seriesName/testSeriesId to the per-exam object returned by /my-exams
{
  const anchor = `        batch: e.batch,
        multiBatch: e.multiBatch,
        schedule: e.schedule,`;
  const replacement = `        batch: e.batch,
        multiBatch: e.multiBatch,
        testSeriesId: e.testSeriesId || null,
        seriesName: e.seriesName || '',
        schedule: e.schedule,`;
  if (src.includes(anchor) && !src.includes('testSeriesId: e.testSeriesId')) {
    src = src.replace(anchor, replacement);
    count++;
    console.log('✅ Patched: testSeriesId + seriesName added to /my-exams per-exam response');
  } else if (src.includes('testSeriesId: e.testSeriesId')) {
    console.log('⚠️  Already patched — skipping');
  } else {
    console.log('❌ Anchor not found — patch NOT applied. Check routes/examFlow.js structure manually.');
  }
}

fs.writeFileSync(file, src, 'utf8');
console.log(`\n${count} block(s) modified.`);
NODEEOF

node --check routes/examFlow.js && echo "✅ routes/examFlow.js syntax OK after patch"
echo "🎉 Backend v4 patch complete"
