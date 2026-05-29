#!/bin/bash
# ═══════════════════════════════════════════════
# ProveRank QB — Complete Fix v2 (No Python)
# Run: bash qb_complete_fix.sh  (from ~/workspace)
# ═══════════════════════════════════════════════
set -e
cd ~/workspace

echo "══ ProveRank QB Complete Fix ══"
echo ""

# ── Backup ──────────────────────────────────────
BAK="frontend/app/admin/x7k2p/page.tsx.bak_v2_$(date +%s)"
cp frontend/app/admin/x7k2p/page.tsx "$BAK"
echo "✅ Backup: $BAK"
echo ""

# ── Step 1: Backend fix ──────────────────────────
echo "Running backend fix..."
node qb_backend_fix.js
echo ""

# ── Step 2: Frontend fix ─────────────────────────
echo "Running frontend fix..."
node qb_frontend_fix.js
echo ""

# ── Step 3: TypeScript check ─────────────────────
echo "TypeScript check..."
cd frontend && npx tsc --noEmit 2>&1 | grep -v "login\|src/app/login" | grep "error TS\|admin/x7k2p" | head -15
echo "══ Done ══"
