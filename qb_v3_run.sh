#!/bin/bash
# QB v3 complete runner
set -e
cd ~/workspace

BAK="frontend/app/admin/x7k2p/page.tsx.bak_v3_$(date +%s)"
cp frontend/app/admin/x7k2p/page.tsx "$BAK"
echo "✅ Backup: $BAK"

node qb_v3_fix.js

echo ""
echo "TypeScript check..."
cd frontend && npx tsc --noEmit 2>&1 | grep -v "login\|src/app/login" | grep "error TS\|admin/x7k2p" | head -15
echo "══ Done ══"
