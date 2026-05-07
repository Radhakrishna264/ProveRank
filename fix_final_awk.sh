#!/bin/bash
# ProveRank — FINAL FIX using awk line numbers (no sed || problem)
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; }
step(){ echo -e "\n${Y}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
if [ ! -f "$FILE" ]; then err "File not found!"; exit 1; fi
cp "$FILE" "${FILE}.bak_final"
log "Backup done"

# ══════════════════════════════════════════
# STEP 1: Find exact line numbers in current file
# ══════════════════════════════════════════
step "Finding line numbers"

Q_LINE=$(grep -n "StatBox ico='❓' lbl='Questions'" "$FILE" | head -1 | cut -d: -f1)
STATS_DIV=$(grep -n "Stats Row" "$FILE" | head -1 | cut -d: -f1)
CONTENT_DIV=$(grep -n "flex:1,padding:'20px 16px'" "$FILE" | head -1 | cut -d: -f1)
ATTEMPT_LINE=$(grep -n "totalAttempts" "$FILE" | grep "val=" | head -1 | cut -d: -f1)
ACTIVE_LINE=$(grep -n "activeStudents" "$FILE" | grep "val=" | head -1 | cut -d: -f1)

log "Questions card line: $Q_LINE"
log "Stats Row div line: $STATS_DIV"
log "Content div line: $CONTENT_DIV"
log "Attempts line: $ATTEMPT_LINE"
log "Active Today line: $ACTIVE_LINE"

# ══════════════════════════════════════════
# FIX 1: Questions card — full width via awk line replace
# ══════════════════════════════════════════
step "FIX 1: Questions full width (awk line $Q_LINE)"

if [ -z "$Q_LINE" ]; then
  err "Questions line not found!"
else
  awk -v linenum="$Q_LINE" '
  NR == linenum {
    print "                <div style={{gridColumn:\"span 2\",width:\"100%\"}}><StatBox ico=\"\U2753\" lbl=\"Questions\" val={loading?\"\u2026\":stats?.totalQuestions||(questions||[]).length||0} col=\"#FF6B9D\"/></div>"
    next
  }
  { print }
  ' "$FILE" > /tmp/fix_q.tsx

  # Simpler approach - just print replacement
  awk -v ln="$Q_LINE" 'NR==ln{print "                <div style={{gridColumn:\"span 2\"}}><StatBox ico=\x27❓\x27 lbl=\x27Questions\x27 val={loading?\x27\u2026\x27:stats?.totalQuestions||(questions||[]).length||0} col=\x27#FF6B9D\x27/></div>"; next}1' "$FILE" > /tmp/fix_q2.tsx

  if [ $(wc -l < /tmp/fix_q2.tsx) -gt 100 ]; then
    cp /tmp/fix_q2.tsx "$FILE"
    log "Questions span 2 applied via awk"
  else
    err "awk output bad, trying Python-free node approach"
  fi
fi

# ══════════════════════════════════════════
# FIX 2: Stats — Attempts & Active Today
# Use awk to replace specific lines
# ══════════════════════════════════════════
step "FIX 2: Stats blank values"

ATTEMPT_LINE=$(grep -n "totalAttempts" "$FILE" | grep "val=" | head -1 | cut -d: -f1)
ACTIVE_LINE=$(grep -n "activeStudents" "$FILE" | grep "val=\|col=" | grep -v "Connected\|History\|S48" | head -1 | cut -d: -f1)

log "Attempts at line: $ATTEMPT_LINE, Active at line: $ACTIVE_LINE"

# Replace attempts line
if [ -n "$ATTEMPT_LINE" ]; then
  awk -v ln="$ATTEMPT_LINE" 'NR==ln{
    gsub(/totalAttempts\|\|'"'"'—'"'"'/, "totalAttempts??0")
    gsub(/totalAttempts\|\|"—"/, "totalAttempts??0")
  }1' "$FILE" > /tmp/fix_att.tsx
  [ $(wc -l < /tmp/fix_att.tsx) -gt 100 ] && cp /tmp/fix_att.tsx "$FILE" && log "Attempts ??0 done"
fi

# Replace active line
ACTIVE_LINE=$(grep -n "activeStudents" "$FILE" | grep "val=" | grep -v "Connected" | head -1 | cut -d: -f1)
if [ -n "$ACTIVE_LINE" ]; then
  awk -v ln="$ACTIVE_LINE" 'NR==ln{
    gsub(/activeStudents\|\|'"'"'—'"'"'/, "activeStudents??0")
    gsub(/activeStudents\|\|"—"/, "activeStudents??0")
  }1' "$FILE" > /tmp/fix_act.tsx
  [ $(wc -l < /tmp/fix_act.tsx) -gt 100 ] && cp /tmp/fix_act.tsx "$FILE" && log "Active Today ??0 done"
fi

# ══════════════════════════════════════════
# FIX 3: Remove empty space — minHeight
# ══════════════════════════════════════════
step "FIX 3: Empty space fix"

CONTENT_DIV=$(grep -n "minHeight:'calc(100vh - 58px)'" "$FILE" | head -1 | cut -d: -f1)
log "Content div at line: $CONTENT_DIV"

if [ -n "$CONTENT_DIV" ]; then
  awk -v ln="$CONTENT_DIV" 'NR==ln{
    gsub(/minHeight:'"'"'calc\(100vh - 58px\)'"'"',/, "")
  }1' "$FILE" > /tmp/fix_mh.tsx
  [ $(wc -l < /tmp/fix_mh.tsx) -gt 100 ] && cp /tmp/fix_mh.tsx "$FILE" && log "minHeight removed"
fi

# ══════════════════════════════════════════
# FIX 4: Navbar ↻ button — make it text+icon
# ══════════════════════════════════════════
step "FIX 4: Refresh button visible"

awk '{
  gsub(/flexShrink:0}}>↻<\/button>/, "flexShrink:0,fontSize:12,letterSpacing:0}>↻<\/button>")
  gsub(/justifyContent:'"'"'center'"'"',flexShrink:0}}>↻/, "justifyContent:\"center\",flexShrink:0,color:\"#4D9FFF\"}}>↻")
}1' "$FILE" > /tmp/fix_ref.tsx
[ $(wc -l < /tmp/fix_ref.tsx) -gt 100 ] && cp /tmp/fix_ref.tsx "$FILE" && log "Refresh button color fixed"

# ══════════════════════════════════════════
# VERIFY
# ══════════════════════════════════════════
step "Verification"
echo "--- Questions card ---"
grep -n "span 2\|gridColumn" "$FILE" | head -5

echo "--- Stats values ---"
grep -n "totalAttempts\|activeStudents" "$FILE" | grep "val=" | grep -v "Connected" | head -3

echo "--- Empty space ---"
grep -n "minHeight.*58\|minHeight.*100vh" "$FILE" | head -3

LINES=$(wc -l < "$FILE")
log "File lines: $LINES"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DONE! Git push karo:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd ~/workspace"
echo "git add frontend/app/admin/x7k2p/page.tsx"
echo 'git commit -m "fix: questions full width + no empty space + stats"'
echo "git push"
