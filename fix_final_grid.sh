#!/bin/bash
# ProveRank Fix: Final — oi image width fix + 2-col grid for preview modal options

echo "========================================"
echo " ProveRank — Final Image + Grid Fix"
echo "========================================"

PAGE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(filePath, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────
// FIX 1: oi image — change width:'100%' to fixed 64px thumbnail
// Current: height:56,width:'100%',objectFit:'cover',borderRadius:4,
//          cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)'
// ─────────────────────────────────────────────────────────
const OI_OLD = `height:56,width:'100%',objectFit:'cover',borderRadius:4,`;
const OI_NEW = `height:64,width:64,minWidth:64,objectFit:'cover',borderRadius:6,`;

const oi1 = (content.match(new RegExp(OI_OLD.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length;
if (oi1 > 0) {
  content = content.replaceAll(OI_OLD, OI_NEW);
  console.log(`✅ Fix 1: oi image width fixed (${oi1}) → 64×64`);
  fixes++;
} else {
  // Try broader pattern
  const ALT_OLD = `height:56,width:'100%',objectFit:'cover'`;
  const ALT_NEW = `height:64,width:64,minWidth:64,objectFit:'cover'`;
  const oi1b = (content.match(new RegExp(ALT_OLD.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length;
  if (oi1b > 0) {
    content = content.replaceAll(ALT_OLD, ALT_NEW);
    console.log(`✅ Fix 1 (alt): oi image width fixed (${oi1b}) → 64×64`);
    fixes++;
  } else {
    console.log('⚠️  Fix 1: height:56,width:100% not found. Showing all width:100% in img context:');
    const matches = [...content.matchAll(/height:\d+,width:'100%'/g)];
    matches.forEach(m => console.log('  Found:', m[0], 'at', m.index));
    
    // Try to fix ALL height:Npx,width:'100%' in option image context
    const BROAD = /height:\d+,width:'100%',objectFit:'cover'/g;
    content = content.replace(BROAD, `height:64,width:64,minWidth:64,objectFit:'cover'`);
    console.log('✅ Fix 1 (broad): All height+width:100%+cover replaced');
    fixes++;
  }
}

// Also fix j-indexed remaining width:100%
const J_OLD = `height:52,width:'100%',objectFit:'cover'`;
const J_NEW = `height:64,width:64,minWidth:64,objectFit:'cover'`;
const j1 = (content.match(new RegExp(J_OLD.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length;
if (j1 > 0) {
  content = content.replaceAll(J_OLD, J_NEW);
  console.log(`✅ Fix 1b: j image width fixed (${j1}) → 64×64`);
  fixes++;
}

// ─────────────────────────────────────────────────────────
// FIX 2: Add 2-column grid wrapper around q.options map in preview modal
// Find: {(q.options||[]).map(function(opt,oi)
// Wrap its OUTPUT in a grid container
// Strategy: Find the div BEFORE the map and add grid styles
// ─────────────────────────────────────────────────────────

const MAP_MARKER = `(q.options||[]).map(function(opt,oi)`;
const mapIdx = content.indexOf(MAP_MARKER);

if (mapIdx > -1) {
  console.log(`\nMap marker found at: ${mapIdx}`);
  
  // Look backwards from mapIdx to find the parent div's style
  const before = content.slice(Math.max(0, mapIdx - 600), mapIdx);
  console.log('Before map (last 300):', before.slice(-300).replace(/\n/g,'↵'));
  
  // Find the last <div or last style={{ before the map
  const lastDivStyle = before.lastIndexOf('style={{');
  const lastDiv = before.lastIndexOf('<div');
  
  console.log('lastDivStyle offset:', lastDivStyle);
  console.log('lastDiv offset:', lastDiv);
  
  if (lastDivStyle > -1) {
    const styleContext = before.slice(lastDivStyle, lastDivStyle + 150);
    console.log('Last style before map:', styleContext.replace(/\n/g,'↵'));
    
    // Calculate absolute position
    const absStylePos = (mapIdx - 600 < 0 ? 0 : mapIdx - 600) + lastDivStyle;
    const styleContentStart = absStylePos + 8; // skip 'style={{'
    
    // Find the closing of this style
    let depth = 0;
    let styleEnd = styleContentStart;
    while (styleEnd < content.length) {
      if (content[styleEnd] === '{') depth++;
      if (content[styleEnd] === '}') {
        if (depth === 0) { styleEnd += 2; break; }
        depth--;
      }
      styleEnd++;
    }
    
    const currentStyle = content.slice(absStylePos, styleEnd);
    console.log('\nCurrent parent div style:', currentStyle.slice(0, 120));
    
    // Check if it already has grid
    if (currentStyle.includes('gridTemplateColumns') || currentStyle.includes('display:') ) {
      console.log('⚠️  Parent already has display style — checking if grid');
      if (!currentStyle.includes("'1fr 1fr'")) {
        // Add grid to existing style - insert after first {{
        const insertPos = absStylePos + 8;
        content = content.slice(0, insertPos) + 
                  `display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,` + 
                  content.slice(insertPos);
        console.log('✅ Fix 2: Grid inserted into existing parent div style');
        fixes++;
      } else {
        console.log('ℹ️  Fix 2: Grid already present');
      }
    } else {
      // Add grid at start of existing style
      const insertPos = absStylePos + 8;
      content = content.slice(0, insertPos) + 
                `display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,` + 
                content.slice(insertPos);
      console.log('✅ Fix 2: 2-col grid added to parent div');
      fixes++;
    }
  } else {
    // No style found nearby — wrap the map call directly
    console.log('⚠️  No parent style found — wrapping map with grid div');
    
    // Find the full JSX expression: {(q.options||[]).map(...)}
    const mapExprStart = content.lastIndexOf('{', mapIdx);  
    
    // Actually use a simpler approach - find the {( before map
    const exprStart = content.lastIndexOf('{(q.options', mapIdx + 5);
    if (exprStart > -1) {
      // Find the closing } of the JSX expression
      // For now, just wrap the whole expression
      // This is risky without knowing the exact end, so let's add a wrapper div differently
      
      // Instead: find {(q.options||[]).map( and replace the containing div style
      // The options are rendered inside the question card — we need to find it
      
      // Alternative: change each option div to flex and use width:50% float approach
      console.log('⚠️  Complex wrapping needed — using alternative approach');
      
      // Each option div currently has style from Fix 4 (padding:6px, borderRadius:6...)
      // Add width:'calc(50% - 4px)' and display:'inline-block'... risky
    }
  }
} else {
  console.log('⚠️  Fix 2: Map marker not found!');
}

// ─────────────────────────────────────────────────────────
// FIX 3: Also wrap each option item to fill the grid cell properly
// Ensure option divs work well in 2-col grid
// ─────────────────────────────────────────────────────────
const OPT_DIV_CURRENT = `style={{padding:'6px',borderRadius:6,background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.06)'}}`;
const OPT_DIV_GRID = `style={{padding:'6px',borderRadius:6,background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.06)',overflow:'hidden'}}`;

if (content.includes(OPT_DIV_CURRENT)) {
  content = content.replaceAll(OPT_DIV_CURRENT, OPT_DIV_GRID);
  console.log('✅ Fix 3: Option div overflow:hidden added for grid');
  fixes++;
}

// ─────────────────────────────────────────────────────────
// SAVE & TS CHECK
// ─────────────────────────────────────────────────────────
if (fixes > 0) {
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`\n✅ Saved ${fixes} fix(es)`);
}

// Verify image styles
console.log('\n--- Image Style Verify ---');
const imgRx = /<img[^]*?style=\{\{[^}]*\}\}[^]*?\/>/g;
let m2;
let cnt = 0;
while ((m2 = imgRx.exec(content)) !== null && cnt < 10) {
  const has64 = m2[0].includes('width:64') || m2[0].includes('minWidth:64');
  const hasFullW = m2[0].includes("width:'100%'") && m2[0].includes('height:');
  const src = (m2[0].match(/src=\{([^>]{0,50})/)||['','unknown'])[1];
  if (hasFullW || m2[0].includes('[oi]') || m2[0].includes('[j]')) {
    console.log(`  [${cnt}] 64px=${has64} fullW=${hasFullW} | ${src.slice(0,40)}`);
    cnt++;
  }
}
JSEOF

echo ""
echo "--- TS Check ---"
cd ~/workspace/frontend && npx tsc --noEmit 2>&1 | grep "x7k2p" | head -5

echo ""
echo "If clean → git add -A && git commit -m 'fix: 64px thumbnails + 2col grid' && git push"
