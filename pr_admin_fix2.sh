#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ProveRank — Admin Fix 2
# Fix A: Archived section red theme → blue premium
# Fix B: fetchArchivedAdmins auto-load on page open
# ═══════════════════════════════════════════════════════════
export FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

if [ ! -f "$FILE" ]; then echo "❌ File not found"; exit 1; fi
cp "$FILE" "${FILE}.bak4.$(date +%s)"
echo "✅ Backup created"

node << 'NODEEOF'
const fs=require('fs');
const FILE=process.env.FILE;
let c=fs.readFileSync(FILE,'utf8');
let changes=0;

// ════════════════════════════════════════════════
// FIX B — Auto-fetch archived admins on page load
// ════════════════════════════════════════════════
const OLD_EFFECT=`useEffect(()=>{if(token)fetchAll()},[token])`;
const NEW_EFFECT=`useEffect(()=>{if(token){fetchAll();fetchArchivedAdmins();}},[token])`;
if(c.includes(OLD_EFFECT)){
  c=c.replace(OLD_EFFECT,NEW_EFFECT);
  changes++;
  console.log('✅ Fix B applied: auto-fetch archived admins on load');
}else{
  console.warn('⚠️  Fix B: useEffect string not found — check manually');
}

// ════════════════════════════════════════════════
// FIX A — Archived section: red → blue premium
// ════════════════════════════════════════════════
// Outer container
c=c.replace(
  `background:'rgba(28,4,4,0.97)',border:'1.5px solid rgba(255,80,80,0.26)',borderRadius:18,overflow:'hidden'`,
  `background:'rgba(4,12,30,0.97)',border:'1.5px solid rgba(77,159,255,0.2)',borderRadius:18,overflow:'hidden'`
);

// Header bg + border
c=c.replace(
  `background:'rgba(255,80,80,0.08)',borderBottom:'1px solid rgba(255,80,80,0.14)',padding:'14px 18px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:8`,
  `background:'rgba(77,159,255,0.06)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'14px 18px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:8`
);

// Icon box in archived header
c=c.replace(
  `width:32,height:32,background:'rgba(255,60,60,0.16)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,border:'1px solid rgba(255,60,60,0.28)',flexShrink:0`,
  `width:32,height:32,background:'rgba(77,159,255,0.12)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,border:'1px solid rgba(77,159,255,0.25)',flexShrink:0`
);

// Title color
c=c.replace(
  `fontWeight:700,fontSize:13,color:'#FF7878'`,
  `fontWeight:700,fontSize:13,color:'#7BB8FF'`
);

// Subtitle color
c=c.replace(
  `fontSize:10,color:'#994444',marginTop:1`,
  `fontSize:10,color:'#4D6A8F',marginTop:1`
);

// Count badge
c=c.replace(
  `background:'rgba(255,60,60,0.16)',color:'#FF6B6B',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(255,60,60,0.28)'`,
  `background:'rgba(77,159,255,0.14)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(77,159,255,0.28)'`
);

// Archived card bg + border
c=c.replace(
  `background:'rgba(0,0,0,0.35)',border:'1px solid rgba(255,60,60,0.15)',borderRadius:13,padding:'13px 15px',display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'`,
  `background:'rgba(0,10,28,0.6)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:13,padding:'13px 15px',display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'`
);

// Avatar bg + border + color
c=c.replace(
  `width:40,height:40,background:'rgba(255,60,60,0.12)',border:'1.5px solid rgba(255,60,60,0.28)',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,fontWeight:900,color:'#FF7878',flexShrink:0`,
  `width:40,height:40,background:'rgba(77,159,255,0.12)',border:'1.5px solid rgba(77,159,255,0.25)',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,fontWeight:900,color:'#7BB8FF',flexShrink:0`
);

// ARCHIVED badge (span)
c=c.replace(
  `background:'rgba(255,60,60,0.13)',color:'#FF6B6B',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600`,
  `background:'rgba(120,80,255,0.14)',color:'#A080FF',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600`
);

// Date color
c=c.replace(
  `fontSize:10,color:'#553333'`,
  `fontSize:10,color:'#3D5A7A'`
);

// Empty state check mark color area
c=c.replace(
  `color:'#557766',fontSize:12,fontWeight:600`,
  `color:'#4D6A8F',fontSize:12,fontWeight:600`
);

// Empty state subtitle
c=c.replace(
  `No archived admins — All are active`,
  `No archived admins — All admins are active`
);

changes++;
console.log('✅ Fix A applied: archived section — blue premium theme');

fs.writeFileSync(FILE,c,'utf8');
console.log('\u2705 Both fixes applied! Total changes: '+changes);
NODEEOF

echo ""
echo "══════════════════════════════════════════════════"
echo "✅ Run: git add -A && git commit -m 'Admin: archived theme fix + auto-load' && git push"
echo "══════════════════════════════════════════════════"
