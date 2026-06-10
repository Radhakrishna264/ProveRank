#!/bin/bash
# ProveRank Fix: Option Images — Thumbnail + Lightbox + 2-col Layout
# Small images, A+B side by side, C+D side by side, click to enlarge

echo "========================================"
echo " ProveRank — Image Thumbnail + Lightbox Fix"
echo "========================================"

PAGE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(filePath, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────
// FIX 1: Add lightbox state variable
// ─────────────────────────────────────────────────────────
const LB_STATE = `const [lbImg,setLbImg]=useState<string>('');`;

if (!content.includes('lbImg,setLbImg')) {
  // Find a good insertion point — after any existing useState
  const stateMarker = `const [optImgsInit,setOptImgsInit]=useState`;
  const idx = content.indexOf(stateMarker);
  if (idx > -1) {
    const lineEnd = content.indexOf('\n', idx);
    content = content.slice(0, lineEnd+1) + `  ${LB_STATE}\n` + content.slice(lineEnd+1);
    console.log('✅ Fix 1: lightbox state added');
    fixes++;
  } else {
    // Try alternate marker
    const alt = `const [selQ,setSelQ]`;
    const idx2 = content.indexOf(alt);
    if (idx2 > -1) {
      const lineEnd2 = content.indexOf('\n', idx2);
      content = content.slice(0, lineEnd2+1) + `  ${LB_STATE}\n` + content.slice(lineEnd2+1);
      console.log('✅ Fix 1 (alt): lightbox state added');
      fixes++;
    } else {
      console.log('⚠️  Fix 1: Could not find state insertion point — searching...');
      const anyState = content.indexOf('useState(');
      if (anyState > -1) {
        const le = content.indexOf('\n', anyState);
        content = content.slice(0, le+1) + `  ${LB_STATE}\n` + content.slice(le+1);
        console.log('✅ Fix 1 (fallback): lightbox state added');
        fixes++;
      }
    }
  }
} else {
  console.log('ℹ️  Fix 1: lightbox state already exists');
}

// ─────────────────────────────────────────────────────────
// FIX 2: Add Lightbox Modal JSX
// Insert near the end of the page's return JSX — before final </div> or </>
// ─────────────────────────────────────────────────────────
const LIGHTBOX_JSX = `
      {/* ── Image Lightbox ── */}
      {lbImg&&<div onClick={()=>setLbImg('')} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:99999,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
        <div onClick={e=>e.stopPropagation()} style={{position:'relative',maxWidth:'92vw',maxHeight:'92vh',borderRadius:12,overflow:'hidden',boxShadow:'0 8px 48px rgba(0,0,0,0.6)'}}>
          <img src={lbImg} alt='preview' style={{maxWidth:'92vw',maxHeight:'88vh',objectFit:'contain',display:'block',borderRadius:12}}/>
          <button onClick={()=>setLbImg('')} style={{position:'absolute',top:8,right:8,background:'rgba(0,0,0,0.6)',border:'1px solid rgba(255,255,255,0.3)',color:'#fff',width:32,height:32,borderRadius:'50%',cursor:'pointer',fontSize:16,display:'flex',alignItems:'center',justifyContent:'center',lineHeight:1}}>✕</button>
        </div>
      </div>}`;

if (!content.includes('Image Lightbox')) {
  // Find a safe insertion point — just before the closing of the main return
  // Look for the last </div> before the component closes
  const insertMarker = `{/* == PYQ BANK == */}`;
  const idx = content.indexOf(insertMarker);
  if (idx > -1) {
    content = content.slice(0, idx) + LIGHTBOX_JSX + '\n      ' + content.slice(idx);
    console.log('✅ Fix 2: Lightbox modal added before PYQ section');
    fixes++;
  } else {
    // Try to insert before a common end marker
    const endMarkers = ['</main>', '</div>\n  )\n}', `\n  )\n}\n`];
    let inserted = false;
    for (const em of endMarkers) {
      const eidx = content.lastIndexOf(em);
      if (eidx > -1 && eidx > content.length * 0.8) { // must be near end
        content = content.slice(0, eidx) + LIGHTBOX_JSX + '\n' + content.slice(eidx);
        console.log('✅ Fix 2 (alt): Lightbox modal added at:', em.slice(0,20));
        fixes++;
        inserted = true;
        break;
      }
    }
    if (!inserted) console.log('⚠️  Fix 2: Could not insert lightbox modal — check manually');
  }
} else {
  console.log('ℹ️  Fix 2: Lightbox already exists');
}

// ─────────────────────────────────────────────────────────
// FIX 3: Update option images in Preview All Questions modal
//         — Small thumbnail, clickable, 2-col grid
// Target the section with _hasT / _hasI (our modified map)
// ─────────────────────────────────────────────────────────

// 3a: Change the outer options grid wrapper to explicit 2-col
// Find the gridTemplateColumns around the options map  
const GRID_OLD_1 = `gridTemplateColumns:'1fr 1fr',marginBottom:6`;
const GRID_NEW_1 = `gridTemplateColumns:'1fr 1fr',gap:'6px 8px',marginBottom:8`;

if (content.includes(GRID_OLD_1)) {
  content = content.replaceAll(GRID_OLD_1, GRID_NEW_1);
  console.log('✅ Fix 3a: Options grid gap updated');
  fixes++;
} else {
  console.log('ℹ️  Fix 3a: Grid already updated or different format');
}

// 3b: Update image styles in options map — make thumbnails + add click handler
// Pattern 1: images in the _hasT/_hasI section (our modified map area)
const IMG_PATTERNS = [
  // Pattern from options list (3258 area) - our modified map
  {
    old: `style={{display:'block',maxWidth:'100%',maxHeight:60,borderRadius:3,marginTop:0,border:'1px solid rgba(255,255,255,0.1)'}} onError={(e:any)=>{e.currentTarget.style.display='none'}}`,
    new: `style={{height:56,width:'100%',objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)',transition:'opacity 0.15s'}} onClick={()=>setLbImg(String(q.optionImages?.[j]||''))} onError={(e:any)=>{e.currentTarget.style.display='none'}}`
  },
  // Pattern from preview modal (3134 area)
  {
    old: `style={{display:'block',maxWidth:'100%',marginTop:4,borderRadius:4,border:'1px solid rgba(255,255,255,0.08)'}} onError={(e:any)=>{(e.target as HTMLImageElement).style.display='none'}}`,
    new: `style={{height:56,width:'100%',objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)'}} onClick={()=>setLbImg(String((q.optionImages as any)?.[oi]||''))} onError={(e:any)=>{(e.target as HTMLImageElement).style.display='none'}}`
  },
  // Pattern with maxWidth:100% and maxHeight:60 (older format)
  {
    old: `style={{display:'block',maxWidth:'100%',maxHeight:60,borderRadius:3,marginTop:0,border:'1px solid rgba(255,255,255,0.1)'}}`,
    new: `style={{height:56,width:'100%',objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)'}} onClick={()=>setLbImg(String(q.optionImages?.[j]||''))}`
  }
];

for (const {old, new: nw} of IMG_PATTERNS) {
  if (content.includes(old)) {
    content = content.replaceAll(old, nw);
    console.log('✅ Fix 3b: Image style updated →', old.slice(0,40)+'...');
    fixes++;
  }
}

// 3c: Also fix the main question image in the preview to be reasonable size
// The main question image: look for it in the preview modal
const MAIN_IMG_OLD = `style={{width:'100%',height:'100%',objectFit:'cover'}}`;
// Don't touch this — it's likely the background

// 3d: Snapshot image (small card view in list)
const SNAP_OLD = `s.imageUrl?<img src={s.imageUrl} alt='snapshot' style={{width:'100%',height:'100%',objectFit:'cover'}}`;
// Don't touch snapshots

// ─────────────────────────────────────────────────────────
// FIX 4: Main question image in preview modal — reasonable max height
// Find the main image display in the question preview panel
// ─────────────────────────────────────────────────────────
// Look for the main q.image or q.imageUrl img tag in the preview
const MAIN_Q_IMG_PATTERNS = [
  {
    old: `src={q.imageUrl} alt='` ,
    contextCheck: true
  }
];

// Find q.imageUrl img tags and check their styles
const qImgIdx = content.indexOf(`src={q.imageUrl} alt=`);
if (qImgIdx > -1) {
  const imgContext = content.slice(qImgIdx-50, qImgIdx+200);
  console.log('ℹ️  Fix 4: Main question image context:', imgContext.slice(0,100).replace(/\n/g,'↵'));
  
  // Check if it has maxHeight already
  if (!imgContext.includes('maxHeight') && !imgContext.includes('height:56')) {
    // Find the full img tag style and update
    const styleStart = content.indexOf('style={{', qImgIdx);
    const styleEnd = content.indexOf('}}', styleStart) + 2;
    if (styleStart > -1 && styleStart < qImgIdx + 200) {
      const oldStyle = content.slice(styleStart, styleEnd);
      const newStyle = `style={{width:'100%',maxHeight:200,objectFit:'contain',borderRadius:8,cursor:'pointer'}} onClick={()=>setLbImg(q.imageUrl||q.image||'')}`;
      content = content.slice(0, styleStart) + newStyle + content.slice(styleEnd);
      console.log('✅ Fix 4: Main question image maxHeight set');
      fixes++;
    }
  } else {
    console.log('ℹ️  Fix 4: Main question image already has height constraint');
  }
}

// ─────────────────────────────────────────────────────────
// SAVE
// ─────────────────────────────────────────────────────────
if (fixes > 0) {
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`\n✅ Saved ${fixes} fix(es)`);
} else {
  console.log('\n⚠️  No changes made — all patterns need manual check');
}

// ─────────────────────────────────────────────────────────
// DIAGNOSE — Show current image styles in options sections
// ─────────────────────────────────────────────────────────
console.log('\n--- Image Style Audit ---');
const imgMatches = [...content.matchAll(/<img[^>]*style=\{\{[^}]+\}\}[^>]*>/g)];
imgMatches.slice(0,8).forEach((m,i) => {
  const hasOpt = m[0].includes('optionImages') || m[0].includes('lbImg') || m[0].includes('setLbImg');
  const hasH = m[0].includes('height:56') || m[0].includes('objectFit');
  console.log(`  img[${i}]: clickable=${hasOpt}, thumbnail=${hasH}`);
  console.log('  ', m[0].slice(0,100));
});
JSEOF

echo ""
echo "--- TS Build Check ---"
cd ~/workspace/frontend && npx tsc --noEmit 2>&1 | grep "x7k2p" | head -8

echo ""
echo "========================================"
echo "If OK: git add -A && git commit -m 'feat: image thumbnails + lightbox + 2col' && git push"
echo "========================================"
