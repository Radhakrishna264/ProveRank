#!/bin/bash
# ProveRank Fix: optionImages not showing in Preview All Questions
# Bug: 1) Frontend payload missing optionImages  2) Backend select missing optionImages

echo "========================================"
echo " ProveRank — Option Images Fix"
echo "========================================"

PAGE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"
ADMIN_ROUTE="/home/runner/workspace/src/routes/adminQuestionMgmtRoutes.js"
QUESTION_ROUTE="/home/runner/workspace/src/routes/question.js"

# ─────────────────────────────────────────────
# FIX 1: Frontend — Add optionImages to save payload
# ─────────────────────────────────────────────
echo ""
echo "--- FIX 1: Frontend Save Payload ---"

node << 'JSEOF'
const fs = require('fs');
const filePath = process.env.PAGE_PATH || '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';

let content;
try {
  content = fs.readFileSync(filePath, 'utf8');
} catch(e) {
  console.log('❌ page.tsx not found:', e.message);
  process.exit(1);
}

// Check if already fixed
if (content.includes('optionImages:[optImgsInit.a,optImgsInit.b,optImgsInit.c,optImgsInit.d]')) {
  console.log('ℹ️  Skip: optionImages already in payload');
  process.exit(0);
}

// Target: the image field in the save payload
// payload = { ... image:qImg||qImageR.current||undefined }
// We add optionImages right after image field

const oldStr = 'image:qImg||qImageR.current||undefined';
const newStr  = 'image:qImg||qImageR.current||undefined,\n      optionImages:[optImgsInit.a,optImgsInit.b,optImgsInit.c,optImgsInit.d].filter(x=>!!(x&&x.trim()))';

const count = (content.match(new RegExp(oldStr.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length;
console.log(`Found "${oldStr}" → ${count} time(s)`);

if (count === 0) {
  console.log('❌ Fix 1 FAILED: Target string not found in payload section!');
  console.log('   Manual check needed at the payload= block in page.tsx');
  process.exit(1);
}

// Replace only FIRST occurrence (the save payload, not any other occurrence)
content = content.replace(oldStr, newStr);
fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ Fix 1 DONE: optionImages added to save payload');
JSEOF

# ─────────────────────────────────────────────
# FIX 2: Backend adminQuestionMgmtRoutes.js — Add optionImages to select
# ─────────────────────────────────────────────
echo ""
echo "--- FIX 2: Backend adminQuestionMgmtRoutes.js Select ---"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/src/routes/adminQuestionMgmtRoutes.js';

let content;
try {
  content = fs.readFileSync(filePath, 'utf8');
} catch(e) {
  console.log('⚠️  adminQuestionMgmtRoutes.js not found — skip Fix 2');
  process.exit(0);
}

let changed = false;

// Fix all .select() calls that include imageUrl or options but NOT optionImages
const fixed = content.replace(
  /\.select\((['"`])([\s\S]*?)\1\)/g,
  (match, q, fields) => {
    const hasRelevant = fields.includes('imageUrl') || fields.includes('options') || fields.includes('questionText');
    if (hasRelevant && !fields.includes('optionImages')) {
      changed = true;
      return `.select(${q}${fields.trimEnd()} optionImages${q})`;
    }
    return match;
  }
);

if (changed) {
  fs.writeFileSync(filePath, fixed, 'utf8');
  console.log('✅ Fix 2 DONE: optionImages added to backend select(s)');
} else if (content.includes('optionImages')) {
  console.log('ℹ️  Skip: optionImages already present in select');
} else {
  console.log('⚠️  Fix 2: No matching select found — may not need fix');
}
JSEOF

# ─────────────────────────────────────────────
# FIX 3: Backend question.js — Ensure optionImages in select (if any)
# ─────────────────────────────────────────────
echo ""
echo "--- FIX 3: Backend question.js Select Check ---"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/src/routes/question.js';

let content;
try {
  content = fs.readFileSync(filePath, 'utf8');
} catch(e) {
  console.log('⚠️  question.js not found — skip Fix 3');
  process.exit(0);
}

let changed = false;

const fixed = content.replace(
  /\.select\((['"`])([\s\S]*?)\1\)/g,
  (match, q, fields) => {
    const hasRelevant = fields.includes('options') || fields.includes('imageUrl');
    if (hasRelevant && !fields.includes('optionImages')) {
      changed = true;
      return `.select(${q}${fields.trimEnd()} optionImages${q})`;
    }
    return match;
  }
);

if (changed) {
  fs.writeFileSync(filePath, fixed, 'utf8');
  console.log('✅ Fix 3 DONE: optionImages added to question.js select');
} else {
  console.log('ℹ️  Fix 3: question.js — no select change needed');
}
JSEOF

# ─────────────────────────────────────────────
# VERIFY
# ─────────────────────────────────────────────
echo ""
echo "--- Verification ---"
echo "Frontend payload check:"
grep -n "optionImages" "$PAGE" | grep -v "optionImgs\|optImgsInit\b" | grep -v "generate\|aiImg\|label\|placeholder\|Interface\|type " | head -5

echo ""
echo "Backend select check:"
grep -n "optionImages" "$ADMIN_ROUTE" 2>/dev/null | head -5
grep -n "optionImages" "$QUESTION_ROUTE" 2>/dev/null | head -5

echo ""
echo "========================================"
echo " Fix Complete!"
echo " Next steps:"
echo " 1. cd ~/workspace && node src/index.js  (server restart)"
echo " 2. Vercel pe deploy: git add -A && git commit -m 'fix: optionImages save+fetch' && git push"
echo "========================================"
