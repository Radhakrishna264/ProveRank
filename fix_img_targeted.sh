#!/bin/bash
# ProveRank Fix: Targeted image thumbnail fix for remaining images
# Finds images by src content and updates their styles

echo "========================================"
echo " ProveRank — Targeted Image Thumbnail Fix"
echo "========================================"

PAGE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(filePath, 'utf8');
let fixes = 0;

// Helper: replace style of a specific img tag found by its src pattern
function fixImgStyle(srcPattern, newStyleStr, onClickStr, label) {
  const idx = content.indexOf(srcPattern);
  if (idx === -1) {
    console.log(`⚠️  ${label}: src pattern not found`);
    return false;
  }

  // Find 'style={{' after the src
  let styleStart = content.indexOf('style={{', idx);
  if (styleStart === -1 || styleStart > idx + 300) {
    console.log(`⚠️  ${label}: style not found near src`);
    return false;
  }

  // Find closing '}}' of style
  let depth = 0;
  let styleEnd = styleStart + 8; // skip 'style={{'
  while (styleEnd < content.length) {
    if (content[styleEnd] === '{') depth++;
    if (content[styleEnd] === '}') {
      if (depth === 0) { styleEnd += 2; break; } // found closing }}
      depth--;
    }
    styleEnd++;
  }

  const oldStyle = content.slice(styleStart, styleEnd);
  console.log(`  ${label} old style:`, oldStyle.slice(0, 80));

  // Also check for existing onClick (don't double-add)
  const afterStyle = content.slice(styleEnd, styleEnd + 200);
  const hasOnClick = afterStyle.slice(0,50).includes('onClick') || 
                     content.slice(styleStart - 10, styleStart).includes('onClick');

  let replacement = newStyleStr;
  if (!hasOnClick && onClickStr) {
    replacement += ' ' + onClickStr;
  }

  content = content.slice(0, styleStart) + replacement + content.slice(styleEnd);
  console.log(`✅ ${label}: style updated`);
  fixes++;
  return true;
}

// ─────────────────────────────────────────────────────────
// FIX A: q.optionImages[j] image (Preview All Questions options)
// ─────────────────────────────────────────────────────────
fixImgStyle(
  `src={q.optionImages[j] as string}`,
  `style={{height:52,width:'100%',objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)',display:'block'}}`,
  `onClick={()=>setLbImg(String(q.optionImages?.[j]||''))}`,
  'img[3] q.optionImages[j]'
);

// Also try alternate format if above not found
fixImgStyle(
  `src={(q.optionImages as any)[j] as string}`,
  `style={{height:52,width:'100%',objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)',display:'block'}}`,
  `onClick={()=>setLbImg(String(q.optionImages?.[j]||''))}`,
  'img[3] alt q.optionImages'
);

// ─────────────────────────────────────────────────────────
// FIX B: optImgsInit image (Confirmation preview options)
// ─────────────────────────────────────────────────────────
fixImgStyle(
  `src={(optImgsInit as any)[['a','b','c','d'][i]]}`,
  `style={{height:52,width:'100%',objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer',border:'1px solid rgba(99,102,241,0.3)',display:'block'}}`,
  `onClick={()=>setLbImg(String((optImgsInit as any)[['a','b','c','d'][i]]||''))}`,
  'img[4] optImgsInit'
);

// ─────────────────────────────────────────────────────────
// FIX C: q.image (main question image in preview modal)
// Make it reasonable max height, clickable
// ─────────────────────────────────────────────────────────
fixImgStyle(
  `src={q.image}`,
  `style={{width:'100%',maxHeight:160,objectFit:'contain',borderRadius:8,marginBottom:8,cursor:'pointer',background:'rgba(255,255,255,0.03)',display:'block'}}`,
  `onClick={()=>setLbImg(q.image||'')}`,
  'img[2] q.image main'
);

// ─────────────────────────────────────────────────────────
// FIX D: qImg (add question form preview — main image)
// Make it compact
// ─────────────────────────────────────────────────────────
fixImgStyle(
  `src={qImg}`,
  `style={{maxWidth:'100%',maxHeight:120,objectFit:'contain',borderRadius:8,marginTop:8,cursor:'pointer',display:'block'}}`,
  `onClick={()=>setLbImg(qImg)}`,
  'img[0] qImg form preview'
);

// ─────────────────────────────────────────────────────────
// FIX E: Also fix aiResult section option images if any
// The AI generated questions preview section
// ─────────────────────────────────────────────────────────
const aiOptImg = `src={q.optionImages[j] as string}`;
// Already handled above (Fix A)

// ─────────────────────────────────────────────────────────
// FIX F: The preview panel option images (2nd occurrence if any)
// Look for any remaining maxWidth:'100%' maxHeight:60 combos
// ─────────────────────────────────────────────────────────
{
  const OLD_COMBO = `maxWidth:'100%',maxHeight:60,borderRadius:3,marginTop:0`;
  const count = (content.match(new RegExp(OLD_COMBO.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'))||[]).length;
  if (count > 0) {
    content = content.replaceAll(OLD_COMBO, `maxWidth:'100%',maxHeight:52,objectFit:'cover',borderRadius:4,marginTop:4,cursor:'pointer'`);
    console.log(`✅ Fix F: Remaining maxHeight:60 combos updated (${count})`);
    fixes++;
  } else {
    console.log('ℹ️  Fix F: No remaining old combos found');
  }
}

// ─────────────────────────────────────────────────────────
// SAVE & VERIFY
// ─────────────────────────────────────────────────────────
if (fixes > 0) {
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`\n✅ Saved ${fixes} fix(es)`);
}

// Quick audit
console.log('\n--- Final Image Audit ---');
const imgs = [...content.matchAll(/<img[^>]*>/g)];
imgs.slice(0, 10).forEach((m, i) => {
  const h52 = m[0].includes('height:52') || m[0].includes('maxHeight:52');
  const lbClick = m[0].includes('setLbImg');
  const src = (m[0].match(/src=\{([^}]{0,40})/)||['',''])[1];
  console.log(`  img[${i}]: h52=${h52}, lbClick=${lbClick} | src: ${src}`);
});
JSEOF

echo ""
echo "--- TS Check ---"
cd ~/workspace/frontend && npx tsc --noEmit 2>&1 | grep -E "error|x7k2p" | head -10

echo ""
echo "========================================" 
echo "If clean: git add -A && git commit -m 'fix: thumbnail images all sections' && git push"
echo "========================================"
