#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — DIRECT JSX FIX for page.tsx
# Fixes: High Trust (>70) and Low Trust (<40) raw JSX error
# ═══════════════════════════════════════════════════════════════

FE=~/workspace/frontend
FILE=$FE/app/admin/x7k2p/page.tsx

echo "🔍 Checking file..."
if [ ! -f "$FILE" ]; then
  echo "❌ ERROR: page.tsx not found at $FILE"
  echo "Try: find ~/workspace -name 'page.tsx' | grep admin"
  exit 1
fi

echo "✅ File found! Applying fix..."

# Fix 1: High Trust (>70) → High Trust (&gt;70)
sed -i 's/>High Trust (>70)</>High Trust (\&gt;70)</g' "$FILE"

# Fix 2: Low Trust (<40) → Low Trust (&lt;40)  
sed -i 's/>Low Trust (<40)</>Low Trust (\&lt;40)</g' "$FILE"

echo ""
echo "🔍 Verifying fix..."
if grep -q "High Trust (>70)" "$FILE"; then
  echo "❌ Fix 1 FAILED — still has raw >"
else
  echo "✅ Fix 1 OK — High Trust fixed"
fi

if grep -q "Low Trust (<40)" "$FILE"; then
  echo "❌ Fix 2 FAILED — still has raw <"
else
  echo "✅ Fix 2 OK — Low Trust fixed"  
fi

echo ""
echo "📋 Context check (lines around the fix):"
grep -n "High Trust\|Low Trust\|Medium Trust" "$FILE"

echo ""
echo "🚀 Now run:"
echo "   cd ~/workspace"
echo "   git add frontend/app/admin/x7k2p/page.tsx"
echo "   git commit -m 'Fix JSX High Trust Low Trust syntax error'"
echo "   git push origin main"
