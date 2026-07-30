#!/bin/bash
# ProveRank — Cleanup V2 (only confirmed-safe items, zero references found)
BK="./.dead_code_backup_v2_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BK"
echo "Backup folder: $BK"

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

echo "--- Duplicate model (confirmed zero references) ---"
move_it "models/Attempt.js"
[ -d "models" ] && [ -z "$(ls -A models 2>/dev/null)" ] && rmdir "models" && echo "REMOVED empty stray folder: models"

echo "--- Orphan unmounted route files (confirmed zero references) ---"
move_it "src/routes/models/TimeExtension.js"
move_it "src/routes/routes/timeExtension.js"
[ -d "src/routes/models" ] && [ -z "$(ls -A src/routes/models 2>/dev/null)" ] && rmdir "src/routes/models" && echo "REMOVED empty stray folder: src/routes/models"
[ -d "src/routes/routes" ] && [ -z "$(ls -A src/routes/routes 2>/dev/null)" ] && rmdir "src/routes/routes" && echo "REMOVED empty stray folder: src/routes/routes"

echo "DONE — backup: $BK"
