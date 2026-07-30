#!/bin/bash
# =========================================================
# ProveRank — Dead/Duplicate Code Cleanup (V1)
# Everything is MOVED (not rm -rf'd) into a timestamped backup
# folder so nothing is unrecoverable. THEME files are fully
# excluded — user will review those separately.
#
# Run: cd ~/workspace && bash proverank_cleanup_v1.sh > cleanup_report.txt 2>&1
# Then share cleanup_report.txt back in chat.
# =========================================================

BK="./.dead_code_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BK"
echo "Backup folder: $BK"
echo ""

move_it() {
  local src="$1"
  if [ -e "$src" ]; then
    local dest="$BK/$src"
    mkdir -p "$(dirname "$dest")"
    mv "$src" "$dest"
    echo "MOVED: $src"
  else
    echo "SKIP (not found): $src"
  fi
}

echo "=================================================="
echo "SECTION 1 — Root-level old backup folders / archives (confirmed dead)"
echo "=================================================="
move_it ".backup_bugfix1_20260622_025410"
move_it ".backup_contentforge_20260617_234349"
move_it ".backup_contentforge_frontend_20260619_000830"
move_it ".backup_contentforge_frontend_20260619_050041"
move_it ".backup_contentforge_frontend_20260622_025414"
move_it ".backup_contentforge_patch2_20260619_050024"
move_it ".backups_examid_fix"
move_it ".banner_backend_v2_backups_1784848658"
move_it ".banner_frontend_v2_backups_1784848667"
move_it ".fix_backups"
move_it "backups/dead_code_removed_20260730_072737.tar.gz"

echo ""
echo "=================================================="
echo "SECTION 2 — .bak / .bak2 / .bak_* files inside live folders"
echo "(anything with 'theme' in the name is SKIPPED on purpose)"
echo "=================================================="
find ./frontend -type f -iname "*.bak*" 2>/dev/null | grep -v node_modules | while read -r f; do
  base=$(basename "$f")
  if echo "$base" | grep -qi "theme"; then
    echo "SKIP (theme-related, review manually): $f"
  else
    move_it "$f"
  fi
done

echo ""
echo "=================================================="
echo "SECTION 3 — Misplaced duplicate component (backend has no business holding a React shell)"
echo "(ThemeHelper.tsx in this same folder is SKIPPED — theme-related)"
echo "=================================================="
move_it "src/components/StudentShell.tsx"
if [ -e "src/components/ThemeHelper.tsx" ]; then
  echo "SKIP (theme-related, review manually): src/components/ThemeHelper.tsx"
fi
# remove the now-empty stray dir if nothing else is left in it
if [ -d "src/components" ] && [ -z "$(ls -A src/components 2>/dev/null)" ]; then
  rmdir "src/components"
  echo "REMOVED empty stray folder: src/components"
fi

echo ""
echo "=================================================="
echo "SECTION 4 — Duplicate model file: models/Attempt.js (root) vs src/models/Attempt.js (live)"
echo "=================================================="
REFS=$(grep -rln "\.\./models/Attempt\|require('\./models/Attempt')\|require(\"\./models/Attempt\")" ./src ./*.js 2>/dev/null | grep -v "^\./models/Attempt.js" | wc -l)
if [ "$REFS" -eq 0 ]; then
  move_it "models/Attempt.js"
  if [ -d "models" ] && [ -z "$(ls -A models 2>/dev/null)" ]; then
    rmdir "models"
    echo "REMOVED empty stray folder: models"
  fi
else
  echo "SKIP (still referenced somewhere — verify manually): models/Attempt.js"
fi

echo ""
echo "=================================================="
echo "SECTION 5 — Misplaced/unmounted route files (not found in index.js app.use list)"
echo "=================================================="
for f in "src/routes/models/TimeExtension.js" "src/routes/routes/timeExtension.js"; do
  if [ -e "$f" ]; then
    base=$(basename "$f" .js)
    REFS=$(grep -rln "$base" ./src --include=*.js 2>/dev/null | grep -v "^$f" | wc -l)
    if [ "$REFS" -eq 0 ]; then
      move_it "$f"
    else
      echo "SKIP (still referenced — verify manually): $f"
    fi
  else
    echo "SKIP (not found): $f"
  fi
done
# clean up now-empty stray nested dirs
[ -d "src/routes/models" ] && [ -z "$(ls -A src/routes/models 2>/dev/null)" ] && rmdir "src/routes/models" && echo "REMOVED empty stray folder: src/routes/models"
[ -d "src/routes/routes" ] && [ -z "$(ls -A src/routes/routes 2>/dev/null)" ] && rmdir "src/routes/routes" && echo "REMOVED empty stray folder: src/routes/routes"

echo ""
echo "=================================================="
echo "SECTION 6 — Dead /dashboard/* student pages (StudentShell sidebar does NOT link to these — confirmed via live route grep)"
echo "=================================================="
declare -A DASH_PAGES=(
  ["frontend/app/dashboard/results"]="dashboard/results"
  ["frontend/app/dashboard/leaderboard"]="dashboard/leaderboard"
  ["frontend/app/dashboard/exams"]="dashboard/exams"
  ["frontend/app/dashboard/analytics"]="dashboard/analytics"
  ["frontend/app/dashboard/certificate"]="dashboard/certificate"
  ["frontend/app/dashboard/admit-card"]="dashboard/admit-card"
)
for dir in "${!DASH_PAGES[@]}"; do
  term="${DASH_PAGES[$dir]}"
  if [ -d "$dir" ]; then
    REFS=$(grep -rln "$term" ./frontend/app ./frontend/src ./frontend/components 2>/dev/null | grep -v "^$dir/" | wc -l)
    if [ "$REFS" -eq 0 ]; then
      move_it "$dir"
    else
      echo "SKIP (still referenced somewhere — verify manually): $dir"
    fi
  else
    echo "SKIP (not found): $dir"
  fi
done

echo ""
echo "=================================================="
echo "SECTION 7 — Orphan components (no import found anywhere)"
echo "(ThemeToggle.tsx SKIPPED on purpose — theme-related)"
echo "=================================================="
if [ -e "frontend/components/ui/ThemeToggle.tsx" ]; then
  echo "SKIP (theme-related, review manually): frontend/components/ui/ThemeToggle.tsx"
fi
REFS=$(grep -rln "ProtectedRoute" ./frontend/app ./frontend/src 2>/dev/null | grep -v "ProtectedRoute.tsx$" | wc -l)
if [ "$REFS" -eq 0 ]; then
  move_it "frontend/components/auth/ProtectedRoute.tsx"
else
  echo "SKIP (still referenced — verify manually): frontend/components/auth/ProtectedRoute.tsx"
fi

echo ""
echo "=================================================="
echo "CLEANUP COMPLETE"
echo "Everything moved to: $BK"
echo "Nothing permanently deleted — verify site works, then you can delete $BK yourself."
echo "Next: cd frontend && rm -rf .next && npm run dev   (fresh rebuild, clears stale cache)"
echo "=================================================="
