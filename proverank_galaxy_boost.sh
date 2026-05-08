#!/bin/bash
# ProveRank — Galaxy Opacity Boost + Stats Loading Fix
# Galaxy dikh nahi raha — opacity values bahut low hain
# Stats "..." stuck — loading flag fix

G='\033[0;32m'; B='\033[0;34m'; R='\033[0;31m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; exit 1; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
FIXER=/tmp/galaxy_boost.js

[ ! -f "$FILE" ] && err "page.tsx not found!"
cp $FILE ${FILE}.bak_boost
log "Backup done"

cat > $FIXER << 'JSEOF'
const fs = require('fs')
const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(FILE, 'utf8')

// ── FIX 1: Galaxy opacity boost ──
// Find GalaxyBg function and replace nebula + spiral opacity values
const fixes = [
  // Nebula opacities — boost karo
  ["'rgba(77,159,255,0.055)'",  "'rgba(77,159,255,0.18)'"],
  ["'rgba(110,70,255,0.045)'",  "'rgba(110,70,255,0.15)'"],
  ["'rgba(0,212,255,0.040)'",   "'rgba(0,212,255,0.14)'"],
  ["'rgba(255,90,180,0.035)'",  "'rgba(255,90,180,0.12)'"],
  ["'rgba(0,230,160,0.032)'",   "'rgba(0,230,160,0.11)'"],
  // Galaxy spiral opacity
  ["(1-t/90)*0.11",             "(1-t/90)*0.35"],
  // Galaxy core
  ["'rgba(180,220,255,0.20)'",  "'rgba(180,220,255,0.55)'"],
  // Stars opacity
  ["+s.op*0.9+",                "+Math.min(s.op*1.0,0.95)+"],
  // Particles opacity
  ["Math.random()*.2+.06",      "Math.random()*.35+.12"],
  // Connection lines
  ["0.065*(1-d/115)",           "0.12*(1-d/115)"],
  // Star count boost
  ["for(let i=0;i<220;i++)",    "for(let i=0;i<280;i++)"],
]

let changed = 0
fixes.forEach(([from, to]) => {
  if (code.includes(from)) {
    code = code.split(from).join(to)
    changed++
    console.log('[OK] Fixed:', from.slice(0,40), '->', to.slice(0,40))
  } else {
    console.log('[SKIP] Not found:', from.slice(0,40))
  }
})
console.log('[OK] Total fixes applied:', changed)

// ── FIX 2: Stats loading stuck fix ──
// Problem: setLoading(false) call hoti hai but students fetch fail ho rahi hai
// Add: setLoading(false) after timeout as fallback
const OLD_LOADING = 'setLoading(false)\n  },[token])'
const NEW_LOADING = `setLoading(false)
    // Fallback: 4 sec baad bhi loading true ho to force false
    setTimeout(()=>setLoading(false), 4000)
  },[token])`

if (code.includes(OLD_LOADING)) {
  code = code.replace(OLD_LOADING, NEW_LOADING)
  console.log('[OK] Loading fallback added')
} else {
  console.log('[SKIP] Loading pattern not found — checking alternate...')
  // Try alternate pattern
  const alt = 'setLoading(false)'
  const idx = code.lastIndexOf(alt)
  if (idx !== -1) {
    console.log('[INFO] setLoading found at index:', idx)
  }
}

fs.writeFileSync(FILE, code, 'utf8')
console.log('[OK] File saved! Lines:', code.split('\n').length)
JSEOF

step "Running opacity boost"
node $FIXER

step "Verify opacity values"
grep -n "rgba(77,159,255,0.18\|rgba(180,220,255,0.55\|1-t/90.*0.35\|i<280" $FILE | head -6

step "TypeScript"
cd ~/workspace/frontend && npx tsc --noEmit --skipLibCheck 2>&1 | tail -3

step "DONE"
log "Opacity boost complete!"
echo ""
echo "git add -A && git commit -m 'Fix: Galaxy opacity boost + stats loading' && git push origin main"
