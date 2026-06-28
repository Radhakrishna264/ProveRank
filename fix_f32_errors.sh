#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  ProveRank — F32 Error Fix Script
#  Fixes: SERVER_ROOT path, attemptRoutes patch, index.js
#         patch, page.tsx patch (env var issue)
# ═══════════════════════════════════════════════════════════
set -e

echo "🔧 Starting F32 error fixes..."
echo ""

# ═══════════════════════════════════════════════════════════
# FIX 1 — Correct SERVER_ROOT (find main server file)
# ═══════════════════════════════════════════════════════════
# Look for file with mongoose.connect — that's the real server root
SERVER_ROOT=$(grep -rl "mongoose.connect" . --include="*.js" 2>/dev/null \
  | grep -v node_modules | grep -v frontend \
  | head -1 | xargs dirname 2>/dev/null)

if [ -z "$SERVER_ROOT" ]; then
  SERVER_ROOT=$(grep -rl "initSocket\|server.listen" . --include="*.js" 2>/dev/null \
    | grep -v node_modules | grep -v frontend \
    | head -1 | xargs dirname 2>/dev/null || echo ".")
fi

echo "✅ SERVER_ROOT = $SERVER_ROOT"

ROUTES_DIR="$SERVER_ROOT/routes"
MODELS_DIR="$SERVER_ROOT/models"

# ═══════════════════════════════════════════════════════════
# FIX 2 — Patch attemptRoutes.js (correct path + env fix)
# ═══════════════════════════════════════════════════════════
ATTEMPT_FILE="$ROUTES_DIR/attemptRoutes.js"
echo "🔍 Looking for attemptRoutes.js at: $ATTEMPT_FILE"

if [ ! -f "$ATTEMPT_FILE" ]; then
  # Try to find it anywhere
  ATTEMPT_FILE=$(find . -name "attemptRoutes.js" | grep -v node_modules | head -1)
  echo "📍 Found at: $ATTEMPT_FILE"
fi

if [ -f "$ATTEMPT_FILE" ]; then
  cp "$ATTEMPT_FILE" "${ATTEMPT_FILE}.bak2"
  export ATTEMPT_FILE
  node -e "
const fs = require('fs');
const filePath = process.env.ATTEMPT_FILE;

let c = fs.readFileSync(filePath, 'utf8');

if (c.includes('timeExtMin')) {
  console.log('ℹ️  attemptRoutes.js already patched');
  process.exit(0);
}

const OLD = 'const totalDurationSec = (exam.duration || 200) * 60;';
const NEW = \`// Feature 32: include granted extra time in timer
    let timeExtMin = 0;
    try {
      const TE = require('../models/TimeExtension');
      const exts = await TE.find({ attemptId: attempt._id, isUndone: false });
      timeExtMin = exts.reduce((s, e) => s + e.extraMinutes, 0);
    } catch(_e) {}
    const totalDurationSec = ((exam.duration || 200) + timeExtMin) * 60;\`;

if (c.includes(OLD)) {
  c = c.replace(OLD, NEW);
  c = c.replace(
    'totalDurationSec, elapsedSec, remainingSec,',
    'totalDurationSec, elapsedSec, remainingSec, timeExtMin,'
  );
  fs.writeFileSync(filePath, c);
  console.log('✅ attemptRoutes.js patched — extension time in timer');
} else {
  // Regex fallback
  const patched = c.replace(
    /const totalDurationSec = \(exam\.duration \|\| 200\) \* 60;/,
    \`let timeExtMin = 0;
    try { const TE = require('../models/TimeExtension'); const exts = await TE.find({ attemptId: attempt._id, isUndone: false }); timeExtMin = exts.reduce((s,e)=>s+e.extraMinutes,0); } catch(_e){}
    const totalDurationSec = ((exam.duration || 200) + timeExtMin) * 60;\`
  );
  if (patched !== c) {
    fs.writeFileSync(filePath, patched);
    console.log('✅ attemptRoutes.js patched (regex fallback)');
  } else {
    console.log('⚠️  Could not patch attemptRoutes.js — add manually');
  }
}
"
else
  echo "⚠️  attemptRoutes.js not found — skipping timer patch"
fi

# ═══════════════════════════════════════════════════════════
# FIX 3 — Patch index.js (correct path + env fix)
# ═══════════════════════════════════════════════════════════
INDEX_FILE=$(find "$SERVER_ROOT" -maxdepth 1 -name "index.js" 2>/dev/null | head -1)

if [ -z "$INDEX_FILE" ]; then
  INDEX_FILE=$(find . -name "index.js" | grep -v node_modules | grep -v frontend \
    | xargs grep -l "mongoose.connect" 2>/dev/null | head -1)
fi

echo "🔍 index.js = $INDEX_FILE"

if [ -f "$INDEX_FILE" ]; then
  cp "$INDEX_FILE" "${INDEX_FILE}.bak2"
  export INDEX_FILE
  node -e "
const fs = require('fs');
const filePath = process.env.INDEX_FILE;
let c = fs.readFileSync(filePath, 'utf8');

if (c.includes('timeExtension') || c.includes('time-extension')) {
  console.log('ℹ️  index.js already has time-extension route');
  process.exit(0);
}

// Add require
const reqMark = \"const attemptRoutes = require('./routes/attemptRoutes');\";
const reqAdd  = \"\nconst timeExtensionRoutes = require('./routes/timeExtension'); // Feature 32\";

// Add app.use
const useMark = \"app.use('/api/attempts', attemptRoutes);\";
const useAdd  = \"\napp.use('/api/time-extension', timeExtensionRoutes); // F32\";

if (c.includes(reqMark)) {
  c = c.replace(reqMark, reqMark + reqAdd);
} else {
  // Fallback: add before server.listen
  c = c.replace(
    'server.listen(',
    \"const timeExtensionRoutes = require('./routes/timeExtension');\napp.use('/api/time-extension', timeExtensionRoutes);\n\nserver.listen(\"
  );
}

if (c.includes(useMark)) c = c.replace(useMark, useMark + useAdd);

fs.writeFileSync(filePath, c);
console.log('✅ index.js patched — /api/time-extension registered');
"
else
  echo "⚠️  index.js not found — add manually:"
  echo "    const timeExtensionRoutes = require('./routes/timeExtension');"
  echo "    app.use('/api/time-extension', timeExtensionRoutes);"
fi

# ═══════════════════════════════════════════════════════════
# FIX 4 — Patch page.tsx (env var correctly passed)
# ═══════════════════════════════════════════════════════════
PAGE_TSX=$(find . -path "*/admin/x7k2p/page.tsx" | grep -v node_modules | head -1)
if [ -z "$PAGE_TSX" ]; then
  PAGE_TSX=$(find . -name "page.tsx" | grep -v node_modules | head -1)
fi

echo "🔍 page.tsx = $PAGE_TSX"

if [ -f "$PAGE_TSX" ]; then
  cp "$PAGE_TSX" "${PAGE_TSX}.bak2"
  export PAGE_TSX
  node -e "
const fs = require('fs');
const pt  = process.env.PAGE_TSX;
let c  = fs.readFileSync(pt, 'utf8');

// 1. Add import
if (!c.includes('TimeExtensionPanel')) {
  const anchors = [
    \"import AdminProfilePage from './AdminProfilePage';\",
    \"'use client'\",
    \"\\\"use client\\\"\",
  ];
  let inserted = false;
  for (const anchor of anchors) {
    if (c.includes(anchor)) {
      c = c.replace(anchor, anchor + \"\nimport TimeExtensionPanel from './TimeExtensionPanel'; // Feature 32\");
      inserted = true;
      break;
    }
  }
  if (!inserted) {
    c = \"import TimeExtensionPanel from './TimeExtensionPanel'; // Feature 32\n\" + c;
  }
  console.log('✅ Import added');
} else {
  console.log('ℹ️  Import already present');
}

// 2. Inject into live tab
const liveMarker  = \"tab==='live'&&(\";
const liveIdx     = c.indexOf(liveMarker);

if (liveIdx === -1) {
  // Add as a new tab instead
  const navEntry = \"{id:'live',ico:'🔴',lbl:'Live Monitor',grp:'Overview'},\";
  if (c.includes(navEntry)) {
    c = c.replace(navEntry, navEntry + \"\n    {id:'time_extension',ico:'⏱️',lbl:'Time Extension',grp:'Exams'},\");
  }
  // Find a tab block to insert before
  const insertBefore = \"tab==='create_exam'&&(\";
  const insertIdx    = c.indexOf(insertBefore);
  if (insertIdx !== -1) {
    const block = \"\n          {/* ══ F32: TIME EXTENSION ══ */}\n          {tab==='time_extension'&&(\n            <TimeExtensionPanel token={token} API={API} T={T} role={role} />\n          )}\n\n          \";
    c = c.slice(0, insertIdx) + block + c.slice(insertIdx);
    console.log('✅ Added as new Time Extension sidebar tab');
  } else {
    console.log('⚠️  Could not inject tab — add manually');
  }
} else {
  // Find closing of live tab — look for next section comment
  const nextSec = c.indexOf('\n          {/* ══', liveIdx + 20);
  if (nextSec !== -1) {
    const beforeNext = c.slice(0, nextSec);
    const closeIdx   = beforeNext.lastIndexOf('          )}');
    if (closeIdx > liveIdx) {
      if (!c.includes('TimeExtensionPanel token=')) {
        const inject = \"\n            {/* Feature 32 */}\n            <TimeExtensionPanel token={token} API={API} T={T} role={role} />\n\";
        c = c.slice(0, closeIdx) + inject + c.slice(closeIdx);
        console.log('✅ TimeExtensionPanel injected into live tab');
      } else {
        console.log('ℹ️  Already injected');
      }
    }
  }
}

fs.writeFileSync(pt, c);
console.log('✅ page.tsx saved');
"
else
  echo "⚠️  page.tsx not found"
fi

# ═══════════════════════════════════════════════════════════
# VERIFY — All files
# ═══════════════════════════════════════════════════════════
echo ""
echo "══════════════════════════════════════════"
echo "  🔍 Verification"
echo "══════════════════════════════════════════"
export ROUTES_DIR MODELS_DIR PAGE_TSX
node -e "
const fs = require('fs');
const rd  = process.env.ROUTES_DIR;
const md  = process.env.MODELS_DIR;
const pt  = process.env.PAGE_TSX;

function read(p) { try { return fs.readFileSync(p,'utf8'); } catch(e){ return ''; } }

const model   = read(md  + '/TimeExtension.js');
const route   = read(rd  + '/timeExtension.js');
const attempt = read(process.env.ATTEMPT_FILE || rd + '/attemptRoutes.js');
const page    = pt ? read(pt) : '';

const checks = [
  ['TimeExtension model created',           model.length > 100],
  ['timeExtension route file created',      route.length > 100],
  ['/give endpoint exists',                 route.includes(\"router.post('/give'\")],
  ['/global endpoint exists',               route.includes(\"router.post('/global'\")],
  ['/log/:examId endpoint exists',          route.includes('/log/:examId')],
  ['/remaining/:attemptId endpoint exists', route.includes('/remaining/:attemptId')],
  ['/undo endpoint exists',                 route.includes('/undo')],
  ['/report/:examId PDF endpoint exists',   route.includes('/report/:examId')],
  ['attemptRoutes timer includes extTime',  attempt.includes('timeExtMin')],
  ['page.tsx imports TimeExtensionPanel',   page.includes('TimeExtensionPanel')],
  ['TimeExtensionPanel injected in page',   page.includes('<TimeExtensionPanel')],
];

let ok = 0, fail = 0;
checks.forEach(([l,v]) => { console.log((v?'✅':'❌') + ' ' + l); v?ok++:fail++; });
console.log('');
if(fail===0) console.log('🎉 All checks passed! Now run: git add . && git commit -m \"feat: F32 time extension\" && git push');
else         console.log('⚠️  ' + fail + ' issue(s) remain');
"

echo ""
echo "Done! Now run:"
echo "  git add . && git commit -m 'feat: Feature 32 — Time Extension' && git push"
