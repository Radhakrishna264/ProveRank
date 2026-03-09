#!/bin/bash
# ============================================================
# ProveRank — Auth.ts check karo phir login fix karo
# ============================================================

echo "📋 auth.ts ka poora content:"
echo "================================"
cat ~/workspace/frontend/lib/auth.ts
echo "================================"
echo ""
echo "✅ Exports:"
grep "export" ~/workspace/frontend/lib/auth.ts
