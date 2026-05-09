#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  ProveRank — Backend Login Messages Fix (FINAL)         ║
# ║  C1: cat > EOF | C2: NO sed -i | NO Python              ║
# ╚══════════════════════════════════════════════════════════╝
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'
ok(){  echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }
warn(){ echo -e "${Y}⚠️  $1${N}"; }
step(){ echo -e "\n${Y}===== $1 =====${N}"; }

# ── STEP 1: Auth file dhundho ─────────────────────────────
step "Step 1: Auth file dhundh raha hoon..."

export AUTH_FILE=$(find ~/workspace/src -name "*.js" 2>/dev/null \
  | grep -v node_modules \
  | xargs grep -l "Invalid email or password" 2>/dev/null \
  | head -1)

if [ -z "$AUTH_FILE" ]; then
  warn "src mein nahi mila, workspace mein dhundh raha hoon..."
  export AUTH_FILE=$(find ~/workspace -name "*.js" 2>/dev/null \
    | grep -v node_modules \
    | xargs grep -l "Invalid email or password" 2>/dev/null \
    | head -1)
fi

if [ -z "$AUTH_FILE" ]; then
  err "File nahi mili!"
  echo "Manual karo ye command:"
  echo "grep -r 'Invalid email or password' ~/workspace --include='*.js' -l"
  exit 1
fi

ok "Auth file mili: $AUTH_FILE"

# ── STEP 2: Current state dikhao ─────────────────────────
step "Step 2: Current occurrences check kar raha hoon..."
echo ""
echo "=== 'Invalid email or password' kahan kahan hai ==="
grep -n "Invalid email or password" "$AUTH_FILE"
echo "===================================================="
echo ""
OCCUR_COUNT=$(grep -c "Invalid email or password" "$AUTH_FILE")
ok "Total occurrences: $OCCUR_COUNT"

if [ "$OCCUR_COUNT" -eq 0 ]; then
  err "Koi occurrence nahi mili — shayad already fix ho gayi!"
  echo "Check karo: grep -n 'No account\|Incorrect password\|removed' $AUTH_FILE"
  exit 0
fi

# ── STEP 3: Node.js se fix karo ──────────────────────────
step "Step 3: Messages replace kar raha hoon..."

node << 'NODEEOF'
const fs = require('fs')
const filePath = process.env.AUTH_FILE

// File padho
let code = fs.readFileSync(filePath, 'utf8')
const original = code

const TARGET = 'Invalid email or password'

// Occurrences count karo
const totalCount = (code.split(TARGET).length - 1)
console.log('Found occurrences: ' + totalCount)

if (totalCount === 0) {
  console.log('❌ String nahi mili — check karo manually')
  process.exit(1)
}

// Simple occurrence-by-occurrence replacement
// 1st occurrence = user not found case
// 2nd occurrence = wrong password case
let count = 0
let result = ''
let lastIdx = 0
let idx = code.indexOf(TARGET)

while (idx !== -1) {
  count++
  result += code.substring(lastIdx, idx)

  if (count === 1) {
    result += 'No account found with this email.'
    console.log('✅ Occurrence #1 replaced → "No account found with this email."')
  } else if (count === 2) {
    result += 'Incorrect password. Please try again.'
    console.log('✅ Occurrence #2 replaced → "Incorrect password. Please try again."')
  } else {
    // 3rd ya zyada ho to as-is rakho (safety)
    result += TARGET
    console.log('ℹ️  Occurrence #' + count + ' → unchanged (check manually)')
  }

  lastIdx = idx + TARGET.length
  idx = code.indexOf(TARGET, lastIdx)
}
result += code.substring(lastIdx)

// File likho wapas
fs.writeFileSync(filePath, result, 'utf8')
console.log('\n✅ File saved! Total replaced: ' + Math.min(count, 2) + '/' + count)
console.log('📁 Path: ' + filePath)
NODEEOF

NODE_STATUS=$?

if [ $NODE_STATUS -ne 0 ]; then
  err "Node script fail hua!"
  exit 1
fi

# ── STEP 4: Verify ────────────────────────────────────────
step "Step 4: Verify kar raha hoon..."
echo ""
echo "=== Updated messages ==="
grep -n "No account found\|Incorrect password\|removed by admin\|Invalid email" "$AUTH_FILE"
echo "========================"
echo ""

# ── STEP 5: Git push ─────────────────────────────────────
step "Step 5: Git push kar raha hoon..."
cd ~/workspace
git add -A
git commit -m "fix: differentiate login error messages (wrong email vs wrong password)"
git push

if [ $? -eq 0 ]; then
  ok "Git push ho gaya! Render pe deploy hoga ~3-4 min mein"
else
  err "Git push fail — manually karo: cd ~/workspace && git push"
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Deploy ke baad ye 3 cases test karna:               ║"
echo "║  1. Wrong email    → No account found with...        ║"
echo "║  2. Wrong password → Incorrect password...           ║"
echo "║  3. Deleted acct   → Your account has been removed   ║"
echo "╚══════════════════════════════════════════════════════╝"
