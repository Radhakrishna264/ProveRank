#!/bin/bash
# ProveRank — Navbar Mobile Fix V2 (Line-based sed only)
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; }
step(){ echo -e "\n${Y}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
if [ ! -f "$FILE" ]; then err "File not found!"; exit 1; fi
cp "$FILE" "${FILE}.bak_nav"
log "Backup done"

# ══════════════════════════════
# FIX 1: Right div — add flexShrink
# ══════════════════════════════
step "FIX 1: Right div gap fix"
sed -i "s|display:'flex',gap:8,alignItems:'center'}}>\$|display:'flex',gap:6,alignItems:'center',flexShrink:0}}>|g" "$FILE"

# More specific match
sed -i "s/{display:'flex',gap:8,alignItems:'center'}}>/{display:'flex',gap:6,alignItems:'center',flexShrink:0}}>/g" "$FILE"
log "Right div gap 8→6 + flexShrink added"

# ══════════════════════════════
# FIX 2: Loading text compact
# ══════════════════════════════
step "FIX 2: Loading indicator"
sed -i "s|fontSize:11,color:DIM,animation:'pulse 1s infinite'}}>⟳ Loading…|fontSize:10,color:DIM,animation:'pulse 1s infinite'}}>⟳|g" "$FILE"
log "Loading text removed, only icon"

# ══════════════════════════════
# FIX 3: Notif bell — smaller
# ══════════════════════════════
step "FIX 3: Bell button size"
sed -i "s|background:'none',border:\`1px solid \${BOR}\`,color:TS,fontSize:15,cursor:'pointer',position:'relative',width:36,height:36,borderRadius:8,display:'flex',alignItems:'center',justifyContent:'center',backdropFilter:'blur(8px)'|background:'none',border:\`1px solid \${BOR}\`,color:TS,fontSize:14,cursor:'pointer',position:'relative',width:32,height:32,borderRadius:8,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0|g" "$FILE"
log "Bell button 36→32px"

# ══════════════════════════════
# FIX 4: Refresh — icon only square button
# ══════════════════════════════
step "FIX 4: Refresh button icon-only"
sed -i "s|<button onClick={fetchAll} style={{\.\.\.bg_,padding:'7px 12px',fontSize:11}}>🔄 Refresh</button>|<button onClick={fetchAll} title=\"Refresh\" style={{background:'rgba(77,159,255,0.1)',color:ACC,border:\`1px solid \${BOR2}\`,borderRadius:8,width:32,height:32,cursor:'pointer',fontSize:14,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}>🔄</button>|g" "$FILE"
log "Refresh → icon-only 32px"

# ══════════════════════════════
# FIX 5: Logout — icon only square button
# ══════════════════════════════
step "FIX 5: Logout button icon-only"
sed -i "s|background:'rgba(255,77,77,0.12)',color:DNG,border:'1px solid rgba(255,77,77,0.25)',borderRadius:8,padding:'7px 12px',cursor:'pointer',fontWeight:700,fontSize:11}}>Logout</button>|background:'rgba(255,77,77,0.12)',color:DNG,border:'1px solid rgba(255,77,77,0.25)',borderRadius:8,width:32,height:32,cursor:'pointer',fontWeight:700,fontSize:14,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}>⏻</button>|g" "$FILE"
log "Logout → icon-only ⏻ 32px"

# ══════════════════════════════
# FIX 6: Logo font size 16→13
# ══════════════════════════════
step "FIX 6: Logo text compact"
sed -i "s|fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,background:\`linear-gradient(90deg,\${ACC},#fff)\`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1|fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:13,background:\`linear-gradient(90deg,\${ACC},#fff)\`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1,whiteSpace:'nowrap'|g" "$FILE"
log "Logo font 16→13, nowrap added"

# ══════════════════════════════
# FIX 7: Role text size 10→9
# ══════════════════════════════
step "FIX 7: Role badge compact"
sed -i "s|fontSize:10,fontWeight:700,letterSpacing:1.5,color:role==='superadmin'?GOLD:ACC,lineHeight:1.2|fontSize:9,fontWeight:700,letterSpacing:1,color:role==='superadmin'?GOLD:ACC,lineHeight:1.2,whiteSpace:'nowrap'|g" "$FILE"
log "Role font 10→9, nowrap"

# ══════════════════════════════
# FIX 8: Navbar overflow hidden
# ══════════════════════════════
step "FIX 8: Navbar overflow"
sed -i "s|padding:'0 16px',height:58,display:'flex',alignItems:'center',justifyContent:'space-between',boxShadow:'0 2px 20px rgba(0,0,0,0.4)'|padding:'0 12px',height:56,display:'flex',alignItems:'center',justifyContent:'space-between',boxShadow:'0 2px 20px rgba(0,0,0,0.4)',overflow:'hidden'|g" "$FILE"
log "Navbar padding 16→12, overflow hidden"

# ══════════════════════════════
# FIX 9: Stats 5th card — span full width
# Use grid with special last-child handling
# Change to 2-col but wrap in a style that last odd spans 2
# ══════════════════════════════
step "FIX 9: Stats 5th card full width"
# Change stats container to CSS grid with auto-flow
sed -i "s|display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:10,marginBottom:20|display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:10,marginBottom:20|g" "$FILE"

# The 5th StatBox (Questions) — we need to wrap it differently
# Simplest fix: change Questions card style by targeting its specific line
sed -i "s|<StatBox ico='❓' lbl='Questions' val={loading?'…':stats?.totalQuestions||(questions||[]).length||0} col='#FF6B9D'/>|<div style={{gridColumn:'1/-1'}}><StatBox ico='❓' lbl='Questions' val={loading?'…':stats?.totalQuestions||(questions||[]).length||0} col='#FF6B9D'/></div>|g" "$FILE"
log "Questions card spans full width"

# ══════════════════════════════
# VERIFY
# ══════════════════════════════
step "Verification"
echo "Checking fixes..."
grep -c "flexShrink:0" "$FILE" && log "flexShrink found"
grep -c "width:32,height:32" "$FILE" && log "Icon buttons 32px found"
grep -c "whiteSpace:'nowrap'" "$FILE" && log "nowrap on logo found"
grep -c "gridColumn:'1/-1'" "$FILE" && log "Questions full-width span found"
grep -c "overflow:'hidden'" "$FILE" && log "overflow hidden found"

LINES=$(wc -l < "$FILE")
log "File lines: $LINES (should be 1500+)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ NAVBAR FIX DONE! Ab git push karo:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "cd ~/workspace"
echo "git add frontend/app/admin/x7k2p/page.tsx"
echo 'git commit -m "fix: navbar mobile - icon buttons, no overflow, logo compact"'
echo "git push"
