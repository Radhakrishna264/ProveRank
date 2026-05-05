#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — DIRECT page.tsx HOTFIX (Python based, unicode safe)
# Run this ONCE after scripts have already run
# ═══════════════════════════════════════════════════════════════

# Find page.tsx automatically
FILE=$(find . -path "*/app/admin/x7k2p/page.tsx" 2>/dev/null | head -1)

if [ -z "$FILE" ]; then
  FILE=$(find ~/workspace -path "*/app/admin/x7k2p/page.tsx" 2>/dev/null | head -1)
fi

if [ -z "$FILE" ]; then
  echo "❌ page.tsx not found! Run from your project root."
  exit 1
fi

echo "✅ Found: $FILE"
echo "🔧 Applying fixes..."

python3 - "$FILE" << 'PYEOF'
import sys

filepath = sys.argv[1]

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# ── FIX 1: High Trust (>70) raw JSX ──
content = content.replace(
    '>High Trust (>70)<',
    '>High Trust (&gt;70)<'
)

# ── FIX 2: Low Trust (<40) raw JSX ──
content = content.replace(
    '>Low Trust (<40)<',
    '>Low Trust (&lt;40)<'
)

# ── FIX 3: Broken object literal in Monthly Institute Report ──
# Bad: {ico:'👥',l:'Total Students',(students||[]).length}
# Good: {ico:'👥',l:'Total Students',v:(students||[]).length}

bad_obj = "{ico:'👥',l:'Total Students',(students||[]).length},{ico:'📝',l:'Exams Conducted',(exams||[]).length},{ico:'📈',l:'Avg Score',stats?.avgScore||'—'},{ico:'🏆',l:'Completion Rate',stats?.completionRate||'—'}"

good_obj = "{ico:'👥',l:'Total Students',v:(students||[]).length},{ico:'📝',l:'Exams Conducted',v:(exams||[]).length},{ico:'📈',l:'Avg Score',v:stats?.avgScore||'—'},{ico:'🏆',l:'Completion Rate',v:stats?.completionRate||'—'}"

content = content.replace(bad_obj, good_obj)

# ── FIX 4: Bad value display that uses dynamic key lookup ──
bad_val = "{(s as any)[(students||[]).length]||s[(exams||[]).length]||s[stats?.avgScore]||s[stats?.completionRate]||Object.values(s)[2]||'—'}"
good_val = "{s.v}"

content = content.replace(bad_val, good_val)

# ── REPORT ──
fixes = 0
labels = [
    ('High Trust (&gt;70)', 'Fix 1 - High Trust'),
    ('Low Trust (&lt;40)',   'Fix 2 - Low Trust'),
    (good_obj,               'Fix 3 - Object literal'),
    ('{s.v}',               'Fix 4 - Value display'),
]
for check, label in labels:
    if check in content:
        print(f"  ✅ {label}")
        fixes += 1
    else:
        print(f"  ❌ {label} - NOT found (may already be fixed)")

if content != original:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"\n✅ File saved! {fixes} fixes applied.")
else:
    print("\n⚠️  No changes made — patterns not found.")

PYEOF

echo ""
echo "🚀 Now run:"
echo "   git add ."
echo "   git commit -m 'Hotfix: JSX syntax errors in page.tsx'"
echo "   git push origin main"
