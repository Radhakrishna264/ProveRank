#!/bin/bash
# Fix Build Error — Line 956 exact fix
G='\033[0;32m'; R='\033[0;31m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
if [ ! -f "$FILE" ]; then err "File not found!"; exit 1; fi
cp "$FILE" "${FILE}.bak_build"
log "Backup done"

# Error is on line 956 — Refresh button has:
# 1. duplicate fontSize (14 and 12 both)
# 2. ↻ unicode char not supported by Turbopack directly
# Fix: replace entire line 956 with clean version

REFRESH_LINE=$(grep -n "fetchAll.*title.*Refresh\|Refresh.*fetchAll" "$FILE" | head -1 | cut -d: -f1)
log "Refresh button at line: $REFRESH_LINE"

if [ -n "$REFRESH_LINE" ]; then
  awk -v ln="$REFRESH_LINE" 'NR==ln{
    print "          <button onClick={fetchAll} title=\"Refresh\" style={{background:\"rgba(77,159,255,0.1)\",color:ACC,border:`1px solid ${BOR2}`,borderRadius:8,width:32,height:32,cursor:\"pointer\",fontSize:13,display:\"flex\",alignItems:\"center\",justifyContent:\"center\",flexShrink:0,fontWeight:700}}>R</button>"
    next
  }1' "$FILE" > /tmp/fix_build.tsx

  LINES=$(wc -l < /tmp/fix_build.tsx)
  if [ "$LINES" -gt 100 ]; then
    cp /tmp/fix_build.tsx "$FILE"
    log "Line $REFRESH_LINE replaced — Refresh button fixed"
  else
    err "awk failed ($LINES lines)"
    exit 1
  fi
else
  err "Refresh line not found!"
  exit 1
fi

# Verify no duplicate fontSize
echo "--- Line check ---"
grep -n "fetchAll.*title" "$FILE" | head -3
grep -n "fontSize:14.*fontSize\|fontSize:12.*fontSize" "$FILE" | head -3 && echo "Duplicate fontSize found!" || log "No duplicate fontSize"

BLINES=$(wc -l < "$FILE")
log "File OK: $BLINES lines"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build fix done! Ab git push karo:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd ~/workspace"
echo "git add frontend/app/admin/x7k2p/page.tsx"
echo 'git commit -m "fix: build error line 956 refresh button"'
echo "git push"
