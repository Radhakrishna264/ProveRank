#!/bin/bash
# =========================================================
# ProveRank — Duplicate / Dead / Old Code Scanner (V1)
# Run: cd ~/workspace && bash proverank_scan_v1.sh > scan_report.txt 2>&1
# Phir scan_report.txt yahan share kar dena.
# =========================================================

echo "=================================================="
echo "1. PROJECT STRUCTURE (2 levels)"
echo "=================================================="
find . -maxdepth 3 -type d \( -name node_modules -o -name .next -o -name .git \) -prune -o -type d -print | sort

echo ""
echo "=================================================="
echo "2. SUSPICIOUS FILE NAMES (old/backup/copy/dead/unused/v1/v2/temp)"
echo "=================================================="
find . -type d \( -name node_modules -o -name .next -o -name .git \) -prune -o -type f \
  \( -iname "*old*" -o -iname "*backup*" -o -iname "*copy*" -o -iname "*dead*" \
     -o -iname "*unused*" -o -iname "*temp*" -o -iname "*tmp*" -o -iname "*_v[0-9]*" \
     -o -iname "*.bak" -o -iname "*-new*" -o -iname "*final*" \) -print

echo ""
echo "=================================================="
echo "3. ALL page.tsx FILES (frontend routes) — with size + last modified"
echo "=================================================="
find ./frontend -type f -name "page.tsx" -exec ls -la {} \; 2>/dev/null

echo ""
echo "=================================================="
echo "4. DUPLICATE COMPONENT / LOGO / SHELL DEFINITIONS"
echo "=================================================="
echo "--- Files containing 'ProveRank' text/logo string ---"
grep -rl "ProveRank" ./frontend --include=*.tsx --include=*.ts --include=*.jsx --include=*.js 2>/dev/null | grep -v node_modules

echo ""
echo "--- Files defining StudentShell ---"
grep -rl "function StudentShell\|const StudentShell" ./frontend 2>/dev/null | grep -v node_modules

echo ""
echo "--- Files defining Sidebar / AdminShell ---"
grep -rln "function Sidebar\|const Sidebar\|function AdminShell\|const AdminShell" ./frontend 2>/dev/null | grep -v node_modules

echo ""
echo "--- Files defining Logo / Monogram ---"
grep -rln "Monogram\|SplitBlockLogo\|function Logo\|const Logo " ./frontend 2>/dev/null | grep -v node_modules

echo ""
echo "--- Files defining GalaxyBG / ParticlesBg / theme toggle ---"
grep -rln "GalaxyBG\|ParticlesBg\|CanvasGalaxy" ./frontend 2>/dev/null | grep -v node_modules
grep -rln "pr_theme" ./frontend 2>/dev/null | grep -v node_modules

echo ""
echo "=================================================="
echo "5. LARGE FILES (possible bloated/duplicated code) — top 20 by lines"
echo "=================================================="
find ./frontend ./src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" -o -name "*.jsx" \) 2>/dev/null \
  | grep -v node_modules | xargs wc -l 2>/dev/null | sort -rn | head -20

echo ""
echo "=================================================="
echo "6. POSSIBLY ORPHAN FILES (not imported anywhere by filename)"
echo "=================================================="
for f in $(find ./frontend/components ./frontend/app -type f \( -name "*.tsx" -o -name "*.ts" \) 2>/dev/null | grep -v node_modules); do
  base=$(basename "$f" | sed 's/\.[^.]*$//')
  if [ "$base" != "page" ] && [ "$base" != "layout" ]; then
    count=$(grep -rl "$base" ./frontend --include=*.tsx --include=*.ts 2>/dev/null | grep -v node_modules | grep -v "$f" | wc -l)
    if [ "$count" -eq 0 ]; then
      echo "ORPHAN?: $f"
    fi
  fi
done

echo ""
echo "=================================================="
echo "7. BACKEND ROUTE FILES + MOUNT ORDER (index.js)"
echo "=================================================="
find ./src ./routes -type f -iname "*.js" 2>/dev/null | grep -v node_modules
echo "--- app.use / router mounts in index.js or server.js ---"
grep -n "app.use(" ./src/index.js ./index.js ./server.js 2>/dev/null

echo ""
echo "=================================================="
echo "8. DUPLICATE ROUTE FILE NAMES ACROSS FOLDERS"
echo "=================================================="
find . -type d \( -name node_modules -o -name .next -o -name .git \) -prune -o -type f -name "*.js" -print 2>/dev/null \
  | xargs -n1 basename 2>/dev/null | sort | uniq -c | sort -rn | awk '$1>1'

echo ""
echo "=================================================="
echo "9. GIT — LAST MODIFIED DATE OF EVERY TRACKED FILE (find stale/old files)"
echo "=================================================="
git log --format="%ad" --date=short --diff-filter=A --name-only 2>/dev/null | \
  awk '/^[0-9]/{d=$0} /^[^0-9]/ && NF{print d, $0}' | sort -k2 | awk '!seen[$2]++' | sort

echo ""
echo "=================================================="
echo "10. TODO / FIXME / DEPRECATED / DO-NOT-USE COMMENTS"
echo "=================================================="
grep -rn "TODO\|FIXME\|DEPRECATED\|DO NOT USE\|OLD VERSION\|not used\|unused" ./frontend ./src 2>/dev/null | grep -v node_modules

echo ""
echo "=================================================="
echo "SCAN COMPLETE — copy full scan_report.txt output back to chat"
echo "=================================================="
