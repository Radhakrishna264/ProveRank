#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  ProveRank — Admin Page Persistence Fix                 ║
# ║  Refresh ke baad same page par rehega                   ║
# ╚══════════════════════════════════════════════════════════╝
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'
ok(){  echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; exit 1; }
step(){ echo -e "\n${Y}===== $1 =====${N}"; }

# ── STEP 1: Admin file dhundho ────────────────────────────
step "Step 1: Admin panel file dhundh raha hoon..."

ADMIN_FILE=$(grep -rl "tab,setTab" ~/workspace \
  --include="*.tsx" --include="*.jsx" --include="*.js" \
  2>/dev/null | grep -v node_modules | head -1)

if [ -z "$ADMIN_FILE" ]; then
  err "File nahi mili!\nManually check: grep -r 'tab,setTab' ~/workspace --include='*.tsx'"
fi
ok "File mili: $ADMIN_FILE"

# ── STEP 2: Already fixed check ───────────────────────────
if grep -q "pr_admin_tab" "$ADMIN_FILE"; then
  ok "Already fixed hai — pr_admin_tab already present hai"
  exit 0
fi

# ── STEP 3: Backup ────────────────────────────────────────
step "Step 3: Backup..."
cp "$ADMIN_FILE" "${ADMIN_FILE}.bak"
ok "Backup: ${ADMIN_FILE}.bak"

# ── STEP 4: Fix apply ─────────────────────────────────────
step "Step 4: Fix apply kar raha hoon..."

export ADMIN_FILE
node << 'NODEEOF'
const fs = require('fs')
const file = process.env.ADMIN_FILE
let code = fs.readFileSync(file, 'utf8')

// Step A: Find the exact useState line using regex
const re = /const \[tab,\s*setTab\]\s*=\s*useState\(['"]dashboard['"]\)/
const match = code.match(re)

if (!match) {
  console.error('❌ useState("dashboard") pattern nahi mila')
  console.error('File mein ye lines hain:')
  code.split('\n').forEach((l,i)=>{ if(l.includes('tab')&&l.includes('useState')) console.error((i+1)+': '+l.trim()) })
  process.exit(1)
}

const originalLine = match[0]
console.log('Found: ' + originalLine)

// Step B: Replace useState with localStorage restore version
const restoredUseState = originalLine.replace(
  /useState\(['"]dashboard['"]\)/,
  "useState(()=>{try{return localStorage.getItem('pr_admin_tab')||'dashboard'}catch{return'dashboard'}})"
)
code = code.replace(originalLine, restoredUseState)
console.log('✅ useState: localStorage restore added')

// Step C: Add _setTab wrapper immediately after the useState line
// Find the line and insert wrapper after it
const lines = code.split('\n')
let insertAt = -1
for(let i = 0; i < lines.length; i++){
  if(lines[i].includes('pr_admin_tab') && lines[i].includes('useState')){
    insertAt = i
    break
  }
}

if(insertAt === -1){
  // fallback search
  for(let i = 0; i < lines.length; i++){
    if(lines[i].includes('setTab') && lines[i].includes('useState')){
      insertAt = i; break
    }
  }
}

if(insertAt !== -1){
  const wrapper = "  const _setTab=(t:string)=>{try{localStorage.setItem('pr_admin_tab',t)}catch{};setTab(t)}"
  lines.splice(insertAt + 1, 0, wrapper)
  code = lines.join('\n')
  console.log('✅ _setTab wrapper added at line ' + (insertAt+1))
} else {
  console.error('⚠️  Could not find insert position — manual insert needed')
  process.exit(1)
}

// Step D: Replace all setTab( → _setTab(
// BUT carefully: skip the destructure line and the wrapper fn itself
const codeLines = code.split('\n')
const fixed = codeLines.map(line => {
  // Skip: the useState destructure line
  if(line.includes('pr_admin_tab') && line.includes('useState')) return line
  // Skip: the wrapper definition line
  if(line.includes('const _setTab=')) return line
  // Replace in all other lines
  return line.replace(/\bsetTab\(/g, '_setTab(')
})
code = fixed.join('\n')
console.log('✅ All setTab() calls replaced with _setTab()')

// Verify counts
const saves = (code.match(/localStorage\.setItem\('pr_admin_tab'/g)||[]).length
const calls = (code.match(/_setTab\(/g)||[]).length
console.log('\nVerification:')
console.log('  localStorage.setItem calls: ' + saves)
console.log('  _setTab() calls: ' + calls)

if(saves === 0){ console.error('❌ Verify fail'); process.exit(1) }

fs.writeFileSync(file, code, 'utf8')
console.log('\n✅ File saved!')
NODEEOF

if [ $? -ne 0 ]; then
  echo -e "${Y}Backup restore kar raha hoon...${N}"
  cp "${ADMIN_FILE}.bak" "$ADMIN_FILE"
  err "Fix fail hua — backup restore kar diya"
fi

# ── STEP 5: Verify ────────────────────────────────────────
step "Step 5: Verify..."
echo ""
grep -n "pr_admin_tab\|_setTab" "$ADMIN_FILE" | head -12
echo ""

# ── STEP 6: Git push ─────────────────────────────────────
step "Step 6: Git push..."
cd ~/workspace
git add -A
git commit -m "fix: persist admin page on refresh — localStorage save/restore"
git push

if [ $? -eq 0 ]; then
  ok "Git push ho gaya! ~3-4 min mein Vercel deploy hoga"
else
  err "Git push fail — manually karo: cd ~/workspace && git push"
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Deploy ke baad test karna:                          ║"
echo "║  1. Admin panel kholو — koi bhi page kholo           ║"
echo "║     jaise: Questions / Students / Settings           ║"
echo "║  2. Pull-to-refresh ya F5 / browser refresh karo    ║"
echo "║  3. ✅ Usi page par rehna chahiye                    ║"
echo "║  4. ❌ Dashboard par nahi jana chahiye               ║"
echo "╚══════════════════════════════════════════════════════╝"
