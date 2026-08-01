#!/bin/bash
set -e
echo "=== Pre-delete safety check: any OTHER references to DashLayout or these 6 routes? ==="
echo "--- DashLayout importers (should be exactly these 6 files) ---"
grep -rl "DashLayout" ~/workspace/frontend/app ~/workspace/frontend/components 2>/dev/null || echo "(none found)"
echo "--- Links/nav pointing to the 6 routes being deleted (check these manually after) ---"
grep -rn "dashboard/admit-card\|dashboard/analytics\|dashboard/certificate\|dashboard/leaderboard\|dashboard/results\|dashboard/settings" ~/workspace/frontend/app ~/workspace/frontend/components ~/workspace/frontend/src 2>/dev/null | grep -v "^Binary" || echo "(none found)"

echo ""
echo "=== Deleting 6 legacy dashboard pages + now-orphaned DashLayout.tsx ==="
rm -rf ~/workspace/frontend/app/dashboard/admit-card
rm -rf ~/workspace/frontend/app/dashboard/analytics
rm -rf ~/workspace/frontend/app/dashboard/certificate
rm -rf ~/workspace/frontend/app/dashboard/leaderboard
rm -rf ~/workspace/frontend/app/dashboard/results
rm -rf ~/workspace/frontend/app/dashboard/settings
rm -f ~/workspace/frontend/components/DashLayout.tsx
echo "6 pages + DashLayout.tsx deleted ✅"

echo "--- Post-delete confirmation: any remaining DashLayout references? (should be empty) ---"
grep -rl "DashLayout" ~/workspace/frontend/app ~/workspace/frontend/components 2>/dev/null || echo "(clean — no references left)"

cd ~/workspace
git add -A
git commit -m "cleanup: remove 6 legacy dashboard pages (admit-card, analytics, certificate, leaderboard, results, settings) + orphaned DashLayout.tsx"
git push

echo "=== DONE — Vercel will auto-redeploy. If the nav-links check above showed matches, verify those menu items separately. ==="
