#!/bin/bash
# Auto-restore antiCheatRoutes.js: walks commit history newest-to-oldest,
# finds the FIRST (most recent) commit where the file is NOT the
# corrupted User-schema content, and restores exactly that version.
# No manual hash typing involved — avoids transcription errors.
set -e
cd ~/workspace

echo "Backing up current (corrupted) file first..."
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
cp src/routes/antiCheatRoutes.js ~/workspace/.pre_batch_removal_backup/antiCheatRoutes_corrupted_$ts.js
echo "Backup saved."
echo ""

FOUND=""
for hash in $(git log --format="%H" -- src/routes/antiCheatRoutes.js); do
  line4=$(git show "$hash:src/routes/antiCheatRoutes.js" 2>/dev/null | sed -n '4p')
  if [[ "$line4" != *"userSchema"* ]]; then
    FOUND="$hash"
    echo "Found clean version at commit: $hash"
    echo "  commit message: $(git log -1 --format=%s $hash)"
    echo "  line 4 was: $line4"
    break
  else
    echo "SKIP (corrupted — has userSchema): $hash — $(git log -1 --format=%s $hash)"
  fi
done

if [ -z "$FOUND" ]; then
  echo ""
  echo "ABORT — no clean version found in entire history. Manual recovery needed."
  exit 1
fi

echo ""
echo "Restoring from $FOUND ..."
git show "$FOUND:src/routes/antiCheatRoutes.js" > src/routes/antiCheatRoutes.js

echo ""
echo "═══════════════════════════════════════════"
echo "-- Verifying restored file --"
node -c src/routes/antiCheatRoutes.js && echo "Syntax OK"
head -10 src/routes/antiCheatRoutes.js
echo "..."
wc -l src/routes/antiCheatRoutes.js
echo "═══════════════════════════════════════════"
echo "DONE. Review the content above — if it looks like a proper Express"
echo "router (not a User schema), you're good. Next steps:"
echo "1. node src/index.js   (confirm boots clean)"
echo "2. git add -A && git commit -m 'Fix: restore corrupted antiCheatRoutes.js' && git push"
