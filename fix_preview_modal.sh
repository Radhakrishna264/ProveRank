#!/bin/bash
# ProveRank Fix: Preview Modal — 2-col grid + proper thumbnail dimensions
# Problem: width:'100%' creates ugly strips; oi-section not in grid

echo "========================================"
echo " ProveRank — Preview Modal Layout Fix"
echo "========================================"

PAGE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(filePath, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────
// DIAGNOSE first — show current state of options section in preview modal
// ─────────────────────────────────────────────────────────
console.log('--- Diagnosis ---');

// Find the preview modal options section (uses 'oi' as index)
const oiImgIdx = content.indexOf('(q.optionImages as any)?.[oi]');
const oiImgIdx2 = content.indexOf('(q.optionImages as any)[oi]');
const oiImgIdx3 = content.indexOf('q.optionImages[oi]');
console.log('oi pattern 1 (as any)?.[oi]:', oiImgIdx > -1 ? 'FOUND at ' + oiImgIdx : 'NOT FOUND');
console.log('oi pattern 2 (as any)[oi]:', oiImgIdx2 > -1 ? 'FOUND at ' + oiImgIdx2 : 'NOT FOUND');
console.log('oi pattern 3 q.optionImages[oi]:', oiImgIdx3 > -1 ? 'FOUND at ' + oiImgIdx3 : 'NOT FOUND');

// Also check for j-indexed images (list view - already fixed)
const jImgIdx = content.indexOf('q.optionImages[j]');
console.log('j pattern q.optionImages[j]:', jImgIdx > -1 ? 'FOUND at ' + jImgIdx : 'NOT FOUND');

// Show context around oi image
const checkIdx = oiImgIdx > -1 ? oiImgIdx : oiImgIdx2 > -1 ? oiImgIdx2 : oiImgIdx3;
if (checkIdx > -1) {
  const ctx = content.slice(Math.max(0, checkIdx - 300), checkIdx + 400);
  console.log('\nContext around oi image:');
  console.log(ctx.replace(/\n/g, '↵').slice(0, 600));
}

// Find current image style for oi section
console.log('\n--- Current img styles (preview modal) ---');
const imgRegex = /<img[^]*?\/>/g;
let m;
let imgCount = 0;
const srcContent = content;
while ((m = imgRegex.exec(srcContent)) !== null && imgCount < 15) {
  if (m[0].includes('[oi]') || m[0].includes('q.imageUrl') || m[0].includes('q.image}')) {
    console.log(`img: ${m[0].slice(0,150)}`);
    imgCount++;
  }
}

// ─────────────────────────────────────────────────────────
// FIX 1: Fix ALL remaining full-width images in options sections
// Change width:'100%' to width:auto + add maxWidth constraint in option context
// ─────────────────────────────────────────────────────────
console.log('\n--- Applying Fixes ---');

// Fix height:52,width:'100%' strips → proper thumbnail
const STRIP_OLD = `height:52,width:'100%',objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)',display:'block'`;
const THUMB_NEW = `height:64,width:64,minWidth:64,objectFit:'cover',borderRadius:6,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.4)',display:'block',flexShrink:0`;

const stripCount = (content.match(new RegExp(STRIP_OLD.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length;
if (stripCount > 0) {
  content = content.replaceAll(STRIP_OLD, THUMB_NEW);
  console.log(`✅ Fix 1: ${stripCount} strip style(s) → 64×64 thumbnails`);
  fixes++;
} else {
  console.log('ℹ️  Fix 1: No strip style found');
}

// ─────────────────────────────────────────────────────────
// FIX 2: Fix oi-indexed images (preview modal section)
// These still have old maxWidth:'100%' style
// ─────────────────────────────────────────────────────────

// Pattern variants for oi images
const OI_PATTERNS = [
  // Old full-width style in preview modal
  `style={{display:'block',maxWidth:'100%',marginTop:4,borderRadius:4,border:'1px solid rgba(255,255,255,0.08)'}} onError={(e:any)=>{(e.target as HTMLImageElement).style.display='none'}}`,
  // After previous fix attempt
  `style={{maxWidth:'100%',maxHeight:52,objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer'}}`,
  // Any remaining full-width in oi context
  `style={{display:'block',maxWidth:'100%',marginTop:4,borderRadius:4,border:'1px solid rgba(255,255,255,0.08)'}}`
];

const OI_NEW_STYLE = `style={{height:64,width:64,minWidth:64,objectFit:'cover',borderRadius:6,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.4)',display:'block',flexShrink:0}} onClick={()=>setLbImg(String((q.optionImages as any)?.[oi]||''))} onError={(e:any)=>{(e.target as HTMLImageElement).style.display='none'}}`;

let oiFixed = false;
for (const pat of OI_PATTERNS) {
  const cnt = (content.match(new RegExp(pat.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length;
  if (cnt > 0) {
    content = content.replaceAll(pat, OI_NEW_STYLE);
    console.log(`✅ Fix 2: oi image style fixed (${cnt}) → 64×64`);
    fixes++;
    oiFixed = true;
    break;
  }
}
if (!oiFixed) console.log('⚠️  Fix 2: oi image pattern not found — checking manually...');

// ─────────────────────────────────────────────────────────
// FIX 3: Add 2-column grid to options container in PREVIEW MODAL
// Find the options map in the preview section and wrap/update its container
// ─────────────────────────────────────────────────────────

// Strategy: Find the isC variable usage (unique to preview modal)
// and look for nearby options container

const IS_C_IDX = content.indexOf('isC&&<span');
if (IS_C_IDX > -1) {
  // Look backwards for the options map wrapper
  const searchRange = content.slice(Math.max(0, IS_C_IDX - 1500), IS_C_IDX);
  
  // Find the grid/flex container for options
  // Look for gridTemplateColumns in this range
  const gridInRange = searchRange.lastIndexOf('gridTemplateColumns');
  if (gridInRange > -1) {
    const gridCtx = searchRange.slice(gridInRange, gridInRange + 100);
    console.log('Found grid near isC:', gridCtx.slice(0,80));
    
    // Update this grid to be 2-column if not already
    const gridAbsPos = IS_C_IDX - 1500 + gridInRange;
    
    // Fix: ensure it's 2-col with proper gap
    const GRID_PATTERNS = [
      {old: `gridTemplateColumns:'1fr 1fr',gap:'6px 8px',marginBottom:8`, new: `gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:8`},
      {old: `gridTemplateColumns:'1fr 1fr',marginBottom:6`, new: `gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:8`},
      {old: `gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:8`, new: null} // already correct
    ];
    
    for (const gp of GRID_PATTERNS) {
      if (!gp.new) { console.log('ℹ️  Fix 3: Grid already correct'); break; }
      if (content.indexOf(gp.old) > -1) {
        content = content.replaceAll(gp.old, gp.new);
        console.log('✅ Fix 3: Grid gap normalized');
        fixes++;
        break;
      }
    }
  } else {
    // No grid found — need to find the options container and add grid
    console.log('⚠️  Fix 3: No grid found near preview modal options');
    
    // Look for q.options.map or q.options&&... in the preview modal section  
    const optMapSearch = content.slice(Math.max(0, IS_C_IDX - 2000), IS_C_IDX);
    const optMapIdx = optMapSearch.lastIndexOf('q.options');
    if (optMapIdx > -1) {
      console.log('Found q.options before isC at:', optMapIdx);
      console.log('Context:', optMapSearch.slice(optMapIdx, optMapIdx + 150).replace(/\n/g,'↵'));
    }
  }
} else {
  console.log('⚠️  Fix 3: isC marker not found');
}

// ─────────────────────────────────────────────────────────
// FIX 4: Make each option div a proper flex container
// Each option: letter label + text on top, small image below/beside
// ─────────────────────────────────────────────────────────

// Find option div with padding:'3px 0' (from our modified map) and update
const OPT_DIV_OLD = `style={{padding:'3px 0'}}`;
const OPT_DIV_NEW = `style={{padding:'6px',borderRadius:6,background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.06)'}}`;

const optDivCount = (content.match(/style=\{\{padding:'3px 0'\}\}/g)||[]).length;
if (optDivCount > 0) {
  content = content.replaceAll(OPT_DIV_OLD, OPT_DIV_NEW);
  console.log(`✅ Fix 4: Option div style updated (${optDivCount})`);
  fixes++;
} else {
  console.log('ℹ️  Fix 4: Option div pattern not found');
}

// ─────────────────────────────────────────────────────────
// FIX 5: Main question image — limit size in preview modal
// ─────────────────────────────────────────────────────────
const MAIN_IMG_PATTERNS = [
  `style={{width:'100%',maxHeight:200,objectFit:'contain',borderRadius:8,cursor:'pointer',display:'block'}}`,
  `style={{width:'100%',maxHeight:160,objectFit:'contain',borderRadius:8,marginBottom:8,cursor:'pointer',background:'rgba(255,255,255,0.03)',display:'block'}}`,
  `style={{maxWidth:'100%',borderRadius:8,marginTop:8}}`
];

// Find q.imageUrl img and update
const qImgUrlIdx = content.indexOf(`src={q.imageUrl}`);
if (qImgUrlIdx > -1) {
  const styleAfter = content.indexOf('style={{', qImgUrlIdx);
  if (styleAfter > -1 && styleAfter < qImgUrlIdx + 200) {
    const styleEnd = content.indexOf('}}', styleAfter) + 2;
    const oldStyle = content.slice(styleAfter, styleEnd);
    if (!oldStyle.includes('maxHeight:160') && !oldStyle.includes('maxHeight:120')) {
      const newStyle = `style={{width:'100%',maxHeight:140,objectFit:'contain',borderRadius:8,cursor:'pointer',marginBottom:6,background:'rgba(255,255,255,0.03)'}}`;
      content = content.slice(0, styleAfter) + newStyle + content.slice(styleEnd);
      // Add onClick for lightbox
      const afterNewStyle = content.slice(styleAfter + newStyle.length, styleAfter + newStyle.length + 50);
      if (!afterNewStyle.includes('onClick')) {
        content = content.slice(0, styleAfter + newStyle.length) + 
                  ` onClick={()=>setLbImg(q.imageUrl||'')}` + 
                  content.slice(styleAfter + newStyle.length);
      }
      console.log('✅ Fix 5: q.imageUrl main image constrained to maxHeight:140');
      fixes++;
    } else {
      console.log('ℹ️  Fix 5: q.imageUrl already constrained');
    }
  }
}

// ─────────────────────────────────────────────────────────
// SAVE
// ─────────────────────────────────────────────────────────
if (fixes > 0) {
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`\n✅ Saved ${fixes} fix(es)`);
} else {
  console.log('\n⚠️  0 fixes applied — diagnosis output above will show what to target next');
}
JSEOF

echo ""
echo "--- TS Check (x7k2p only) ---"
cd ~/workspace/frontend && npx tsc --noEmit 2>&1 | grep "x7k2p" | head -5

echo ""
echo "If clean: git add -A && git commit -m 'fix: 2col grid + 64px thumbnails' && git push"
