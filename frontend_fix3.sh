#!/bin/bash
set -e
echo "═══════════════════════════════════════════"
echo "  Bug Fix — Frontend"
echo "  Bug3: T&C reset | Dead pages: delete"
echo "═══════════════════════════════════════════"

if [ ! -d "src" ]; then echo "❌ Run from frontend/ directory"; exit 1; fi

# ── BUG 3: Fix T&C in register/page.tsx ─────────────────
REG="src/app/register/page.tsx"
if [ ! -f "$REG" ]; then echo "❌ $REG not found"; exit 1; fi

cp "$REG" "${REG}.bak_fix3"
echo "✅ Backup: register/page.tsx.bak_fix3"

node << 'JSEOF'
const fs = require('fs')
let code = fs.readFileSync('src/app/register/page.tsx', 'utf8')
let fixed = 0

// ── BUG 3A: Remove T&C auto-accept from useEffect ───────
const tnc_old = `      if (localStorage.getItem('pr_terms_viewed') === 'true') {
        setAgreedTnc(true)
        localStorage.removeItem('pr_terms_viewed') // consume it
      }`
const tnc_new = `      localStorage.removeItem('pr_terms_viewed') // Bug3: clear only, never auto-accept`
if (code.includes(tnc_old)) {
  code = code.replace(tnc_old, tnc_new)
  fixed++; console.log('✅ Bug3-A: T&C auto-accept removed from useEffect')
} else console.log('⚠️  Bug3-A: pattern not found')

// ── BUG 3B: Remove localStorage persist on accept btn ───
const btn_old = `try { localStorage.setItem('pr_terms_viewed','true') } catch {}`
const btn_new = `/* Bug3: T&C state is session-only */`
if (code.includes(btn_old)) {
  code = code.replace(btn_old, btn_new)
  fixed++; console.log('✅ Bug3-B: T&C localStorage persist removed from accept button')
} else console.log('⚠️  Bug3-B: pattern not found')

fs.writeFileSync('src/app/register/page.tsx', code)
console.log(`\n✅ Bug3 done — ${fixed}/2 fixes applied`)
JSEOF

echo ""

# ── DELETE DEAD PAGES ────────────────────────────────────
echo "── Searching for dead pages (@/lib/auth import) ────"

DEAD_FILES=$(grep -rl "from '@/lib/auth'" src/ 2>/dev/null || true)

if [ -z "$DEAD_FILES" ]; then
  echo "ℹ️  No dead pages found (already cleaned)"
else
  for f in $DEAD_FILES; do
    echo "🗑️  Deleting dead file: $f"
    rm "$f"
    # Remove empty directory if applicable
    DIR=$(dirname "$f")
    if [ -z "$(ls -A $DIR 2>/dev/null)" ]; then
      rmdir "$DIR"
      echo "   └─ Empty dir removed: $DIR"
    fi
  done
  echo "✅ Dead pages deleted"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ FRONTEND DONE"
echo "  → git add -A && git commit -m 'Fix: T&C"
echo "    reset + remove dead pages' && git push"
echo "═══════════════════════════════════════════"
