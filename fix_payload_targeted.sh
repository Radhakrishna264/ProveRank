#!/bin/bash
# ProveRank Fix 1 (Targeted): Add optionImages to actual SAVE PAYLOAD (POST body)
# The previous script skipped because optionImages exists in PREVIEW object (line ~1527)
# But the actual payload sent to backend was still missing it

echo "========================================"
echo " ProveRank — Fix 1 Targeted (Save Payload)"
echo "========================================"

PAGE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';

let content = fs.readFileSync(filePath, 'utf8');

// ── Step 1: Check current state ──
const imageStr = 'image:qImg||qImageR.current||undefined';
const optImgStr = 'optionImages:[optImgsInit.a,optImgsInit.b,optImgsInit.c,optImgsInit.d]';

const allOccurrences = [];
let searchStart = 0;
while (true) {
  const idx = content.indexOf(imageStr, searchStart);
  if (idx === -1) break;
  // Get surrounding context (100 chars before + 200 chars after)
  const before = content.slice(Math.max(0, idx - 200), idx);
  const after = content.slice(idx, idx + 300);
  allOccurrences.push({ idx, before, after });
  searchStart = idx + 1;
}

console.log(`Found "${imageStr}" → ${allOccurrences.length} time(s)`);

if (allOccurrences.length === 0) {
  console.log('❌ Target string not found!');
  // Show what's near the fetch call
  const fetchIdx = content.indexOf("fetch(`${API}/api/questions`,{method:'POST'");
  if (fetchIdx > -1) {
    console.log('Fetch call context:', content.slice(fetchIdx - 300, fetchIdx + 100));
  }
  process.exit(1);
}

// ── Step 2: Find which occurrence is the SAVE PAYLOAD ──
// The save payload is followed by a try{ and a fetch POST call
// The preview object (line 1527) is inside a setDraftQ or similar state update

let payloadOccurrenceIdx = -1;
let occurrencePosition = -1;

for (const occ of allOccurrences) {
  const after = occ.after;
  const isPayload = (
    // After image: , next should be closing } then try{ with fetch POST
    after.includes("try{") || 
    after.includes("try {") ||
    (after.indexOf('}') < after.indexOf('optionImages') || after.indexOf('optionImages') === -1)
  );
  
  const alreadyHasOptImg = (
    after.slice(0, 150).includes('optionImages')
  );
  
  console.log(`\nOccurrence at index ${occ.idx}:`);
  console.log('  After (first 200 chars):', after.slice(0, 200).replace(/\n/g,'↵'));
  console.log('  Has try{:', after.includes('try{') || after.includes('try {'));
  console.log('  Already has optionImages after it:', alreadyHasOptImg);
  
  if (!alreadyHasOptImg) {
    payloadOccurrenceIdx = occ.idx;
    occurrencePosition = occ.idx;
  }
}

if (payloadOccurrenceIdx === -1) {
  console.log('\nℹ️  All occurrences already have optionImages after them — checking if values are correct');
  // Show the line after each occurrence
  for (const occ of allOccurrences) {
    const after = occ.after;
    console.log('After:', after.slice(0, 200));
  }
  process.exit(0);
}

// ── Step 3: Fix — Add optionImages to the save payload ──
// Replace only the occurrence that's missing optionImages
// We use a split approach to avoid replacing wrong occurrence

const before = content.slice(0, occurrencePosition);
const rest = content.slice(occurrencePosition);

const replacement = imageStr + ',\n      optionImages:[optImgsInit.a,optImgsInit.b,optImgsInit.c,optImgsInit.d].filter(x=>!!(x&&x.trim()))';
const newRest = rest.replace(imageStr, replacement);

if (newRest === rest) {
  console.log('\n❌ Replace failed!');
  process.exit(1);
}

const newContent = before + newRest;
fs.writeFileSync(filePath, newContent, 'utf8');
console.log('\n✅ Fix 1 DONE: optionImages added to save payload!');

// ── Step 4: Verify ──
const verify = fs.readFileSync(filePath, 'utf8');
const verifyIdx = verify.indexOf('optionImages:[optImgsInit.a,optImgsInit.b,optImgsInit.c,optImgsInit.d].filter');
if (verifyIdx > -1) {
  console.log('✅ Verification PASS: optionImages.filter line found in file');
  // Show context
  console.log('Context:', verify.slice(Math.max(0,verifyIdx-50), verifyIdx+120).replace(/\n/g,'↵'));
} else {
  console.log('⚠️  Verification: filter version not found, checking plain version...');
  const v2 = verify.indexOf('optionImages:[optImgsInit.a');
  console.log('Plain version found:', v2 > -1 ? 'YES at ' + v2 : 'NO');
}
JSEOF

echo ""
echo "--- Quick Verify ---"
echo "Payload optionImages lines:"
grep -n "optionImages.*optImgsInit\|optImgsInit.*optionImages" "$PAGE" | head -10

echo ""
echo "========================================"
echo "Next: git push + Vercel deploy"
echo "git add -A && git commit -m 'fix: optionImages in save payload' && git push"
echo "========================================"
