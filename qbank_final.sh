#!/bin/bash
# ═══════════════════════════════════════════════════
# ProveRank — QB Final Fix (Restore + Clean Patch)
# Run from ~/workspace: bash qbank_final.sh
# NO Python. Node only.
# ═══════════════════════════════════════════════════
set -e
cd ~/workspace

FILE="frontend/app/admin/x7k2p/page.tsx"

# ── STEP 0: Restore original backup ─────────────────
echo "Looking for original backup..."
BAK=$(ls frontend/app/admin/x7k2p/page.tsx.bak_qb_* 2>/dev/null | sort | head -1)
if [ -z "$BAK" ]; then
  echo "❌ No backup found. Checking for fix backup..."
  BAK=$(ls frontend/app/admin/x7k2p/page.tsx.bak_fix_* 2>/dev/null | sort | head -1)
fi
if [ -z "$BAK" ]; then
  echo "❌ No backup found at all. Aborting."
  exit 1
fi
echo "✅ Restoring from: $BAK"
cp "$BAK" "$FILE"
echo "✅ Restore done."

# ── STEP 1-4: Run Node patch ─────────────────────────
echo "Running Node patch..."
node qb_patch.js

# ── STEP 5: TypeScript check ─────────────────────────
echo ""
echo "Running TypeScript check..."
cd frontend && npx tsc --noEmit 2>&1 | grep -E "admin/x7k2p|error TS" | grep -v "login" | head -20
echo "══ Done ══"
