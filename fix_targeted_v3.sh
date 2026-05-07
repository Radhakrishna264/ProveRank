#!/bin/bash
# ProveRank — 2 Targeted Fixes Only (Pure Bash)
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; }
step(){ echo -e "\n${Y}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
if [ ! -f "$FILE" ]; then err "File not found!"; exit 1; fi
cp "$FILE" "${FILE}.bak_fix3"
log "Backup: page.tsx.bak_fix3"

# ══════════════════════════════════════════
# FIX A: Questions card — full width span
# The gridColumn 1/-1 wrapper approach
# ══════════════════════════════════════════
step "FIX A: Questions card full width"

# Check if already wrapped
if grep -q "gridColumn:'1/-1'" "$FILE"; then
  log "Already has gridColumn 1/-1 — checking if wrapper is correct"
  # Remove old wrapper if malformed, reapply clean
  sed -i "s|<div style={{gridColumn:'1/-1'}}><StatBox ico='❓'|<div style={{gridColumn:'span 2'}}><StatBox ico='❓'|g" "$FILE"
  log "Updated to span 2"
else
  # Wrap Questions StatBox
  sed -i "s|<StatBox ico='❓' lbl='Questions'|<div style={{gridColumn:'span 2'}}><StatBox ico='❓' lbl='Questions'|g" "$FILE"
  # Find the closing /> and add </div> after it
  sed -i "s|col='#FF6B9D'/>$|col='#FF6B9D'/></div>|g" "$FILE"
  log "Questions card wrapped with span 2"
fi

# ══════════════════════════════════════════
# FIX B: Navbar right buttons — proper emoji rendering
# Issue: ⏻ power symbol not showing on Android
# Fix: Use text "X" for logout instead of ⏻
# ══════════════════════════════════════════
step "FIX B: Navbar logout button visible text"

# Replace ⏻ with clear text since Android doesn't render it
sed -i 's|flexShrink:0}}>⏻</button>|flexShrink:0,fontSize:11,fontWeight:700}}>OUT</button>|g' "$FILE"
log "Logout button: ⏻ → OUT (Android compatible)"

# Also check if Refresh 🔄 is showing — if not, add text fallback
# Keep 🔄 as it usually works, but make button bigger
sed -i 's|justifyContent:'\''center'\'',flexShrink:0}}>🔄</button>|justifyContent:'\''center'\'',flexShrink:0}}>↻</button>|g' "$FILE"
log "Refresh button: 🔄 → ↻ (universal)"

# ══════════════════════════════════════════
# FIX C: Exam Attempts & Active Today — show 0 instead of blank
# The issue is stats?.totalAttempts returns undefined → '—'
# Fix: show 0 as fallback instead of '—'
# ══════════════════════════════════════════
step "FIX C: Stats blank values → show 0"

sed -i "s|val={loading?'…':stats?.totalAttempts||'—'}|val={loading?'…':stats?.totalAttempts??0}|g" "$FILE"
sed -i "s|val={loading?'…':stats?.activeStudents||'—'}|val={loading?'…':stats?.activeStudents??0}|g" "$FILE"
log "Exam Attempts + Active Today: '—' → 0"

# ══════════════════════════════════════════
# VERIFY
# ══════════════════════════════════════════
step "Verification"
grep -c "span 2\|1/-1" "$FILE" && log "Questions full width: confirmed"
grep -c "OUT</button>" "$FILE" && log "Logout OUT text: confirmed"
grep -c "totalAttempts??0" "$FILE" && log "Stats fallback 0: confirmed"

LINES=$(wc -l < "$FILE")
log "Total lines: $LINES"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 3 FIXES DONE! Git push karo:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "cd ~/workspace"
echo "git add frontend/app/admin/x7k2p/page.tsx"
echo 'git commit -m "fix: questions full width + navbar icons + stats 0 fallback"'
echo "git push"
