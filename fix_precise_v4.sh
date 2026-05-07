#!/bin/bash
# ProveRank — Precise Fix V4 (exact line matches)
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; }
step(){ echo -e "\n${Y}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
if [ ! -f "$FILE" ]; then err "File not found!"; exit 1; fi
cp "$FILE" "${FILE}.bak_v4"
log "Backup done"

# ══════════════════════════════════════════
# FIX 1: Exam Attempts — || to ??
# Original:  stats?.totalAttempts||'—'
# Fixed:     stats?.totalAttempts??0
# ══════════════════════════════════════════
step "FIX 1: Exam Attempts value"
sed -i "s|val={loading?'…':stats?.totalAttempts||'—'}|val={loading?'…':(stats?.totalAttempts??0)}|g" "$FILE"
# Double-pipe version
sed -i 's/stats?\.totalAttempts||'"'"'—'"'"'/stats?.totalAttempts??0/g' "$FILE"
grep -n "totalAttempts" "$FILE" | head -3
log "Attempts fix applied"

# ══════════════════════════════════════════
# FIX 2: Active Today — || to ??
# ══════════════════════════════════════════
step "FIX 2: Active Today value"
sed -i 's/stats?\.activeStudents||'"'"'—'"'"'/stats?.activeStudents??0/g' "$FILE"
grep -n "activeStudents" "$FILE" | head -3
log "Active Today fix applied"

# ══════════════════════════════════════════
# FIX 3: Questions card — full width
# Use awk to replace exact line 1013 area
# ══════════════════════════════════════════
step "FIX 3: Questions card full width"

# Check current state
QLINE=$(grep -n "StatBox ico='❓' lbl='Questions'" "$FILE" | head -1)
log "Current Questions line: $QLINE"

# Replace with wrapped version
sed -i "s|<StatBox ico='❓' lbl='Questions' val={loading?'…':stats?.totalQuestions||(questions||[]).length||0} col='#FF6B9D'/>|<div style={{gridColumn:'span 2',width:'100%'}}><StatBox ico='❓' lbl='Questions' val={loading?'…':stats?.totalQuestions||(questions||[]).length||0} col='#FF6B9D'/></div>|g" "$FILE"

# Verify
grep -n "gridColumn:'span 2'" "$FILE" | head -3
log "Questions span 2 applied"

# ══════════════════════════════════════════
# FIX 4: Remove large empty space at bottom
# The main content div has minHeight 100vh
# After all content, empty space remains
# Add paddingBottom fix
# ══════════════════════════════════════════
step "FIX 4: Remove empty space at bottom"
sed -i "s|flex:1,padding:'20px 16px',minHeight:'calc(100vh - 58px)',maxWidth:'100vw',overflow:'auto',animation:'fadeIn 0.4s ease'|flex:1,padding:'20px 16px',maxWidth:'100vw',overflow:'auto',animation:'fadeIn 0.4s ease',paddingBottom:32|g" "$FILE"
log "minHeight removed → no empty space"

# ══════════════════════════════════════════
# FIX 5: Platform Health — span full width on mobile
# ══════════════════════════════════════════
step "FIX 5: Platform Health full width"
# Bottom row: 'Top Students' + 'Recent Flags' + 'Platform Health' 
# Already auto-fit — Platform Health alone pe fix
# Change minWidth from 220 to 260 so it takes full row when alone
sed -i "s|gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:12|gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',gap:12|g" "$FILE"
log "Bottom grid minWidth 220→260"

# ══════════════════════════════════════════
# VERIFY ALL
# ══════════════════════════════════════════
step "Final Verification"
echo "--- Stats fixes ---"
grep -n "totalAttempts\|activeStudents" "$FILE" | grep -v "Connected\|//\|History" | head -5
echo ""
echo "--- Questions card ---"
grep -n "span 2\|❓.*Questions" "$FILE" | head -3
echo ""
echo "--- Empty space fix ---"
grep -n "paddingBottom:32\|minHeight.*58" "$FILE" | head -3

LINES=$(wc -l < "$FILE")
log "File OK — $LINES lines"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL FIXES DONE! Git push:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "cd ~/workspace"
echo "git add frontend/app/admin/x7k2p/page.tsx"
echo 'git commit -m "fix: stats 0 fallback + questions full width + no empty space"'
echo "git push"
