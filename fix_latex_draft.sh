#!/bin/bash
set -e
cd ~/workspace/frontend

echo "=== Step 1: Install KaTeX ==="
npm install katex --save 2>&1 | tail -3

echo ""
echo "=== Step 2: Patch page.tsx ==="
cat > /tmp/patch_page.js << 'JSEOF'
const fs = require('fs');
let c = fs.readFileSync('app/admin/x7k2p/page.tsx', 'utf8');

// Safe replace: checks uniqueness, uses function to avoid $ issues
function rep(old, nw, label) {
  if (!c.includes(old)) {
    console.error('PATTERN NOT FOUND: ' + label);
    console.error('First 80 chars: ' + old.substring(0,80));
    process.exit(1);
  }
  const cnt = c.split(old).length - 1;
  if (cnt > 1) { console.error('MULTIPLE MATCHES (' + cnt + '): ' + label); process.exit(1); }
  c = c.replace(old, () => nw);
  console.log('  ✓ ' + label);
}

// ── FIX 1: katex import + renderLatex function ──
rep(
  `import { useState, useEffect, useRef, useCallback, memo } from 'react'`,
  `import { useState, useEffect, useRef, useCallback, memo } from 'react'
import katex from 'katex'
function renderLatex(t){if(!t)return '';let h=t.replace(/\\$\\$([^$]+)\\$\\$/g,function(_,m){try{return katex.renderToString(m,{displayMode:true,throwOnError:false})}catch(e){return m}});h=h.replace(/\\$([^$\\n]+)\\$/g,function(_,m){try{return katex.renderToString(m,{displayMode:false,throwOnError:false})}catch(e){return m}});return h;}`,
  'katex import + renderLatex fn'
);

// ── FIX 2: new states ──
rep(
  `const [formKey,setFormKey]=useState(0)`,
  `const [formKey,setFormKey]=useState(0)
  const [latexPrev,setLatexPrev]=useState(false)
  const [qTxtVal,setQTxtVal]=useState('')
  const [qTxtInit,setQTxtInit]=useState('')
  const [draftSaved,setDraftSaved]=useState(false)
  const [draftRestored,setDraftRestored]=useState(false)`,
  'new states (latex + draft)'
);

// ── FIX 3: 3 useEffects before addQ ──
rep(
  `const addQ=useCallback(async()=>{`,
  `useEffect(()=>{const t=setInterval(()=>{setQTxtVal(qTxtR.current||'')},800);return ()=>clearInterval(t);},[]);
  useEffect(()=>{const timer=setTimeout(()=>{const d={text:qTxtVal,subj:qSubj,diff:qDiff,type:qType,ans:qAns};if(d.text||d.subj){try{localStorage.setItem('pr_q_draft',JSON.stringify(d));setDraftSaved(true);setTimeout(()=>setDraftSaved(false),2000)}catch(ex){}}},2000);return ()=>clearTimeout(timer);},[qTxtVal,qSubj,qDiff,qType,qAns]);
  useEffect(()=>{try{const d=JSON.parse(localStorage.getItem('pr_q_draft')||'{}');if(d.text||d.subj){if(d.text){qTxtR.current=d.text;setQTxtVal(d.text);setQTxtInit(d.text);setFormKey(function(k){return k+1})}if(d.subj)setQSubj(d.subj);if(d.diff)setQDiff(d.diff);if(d.type)setQType(d.type);if(d.ans)setQAns(d.ans);setDraftRestored(true);setTimeout(()=>setDraftRestored(false),3000)}}catch(e){}},[]);
  const addQ=useCallback(async()=>{`,
  '3 useEffects (interval + autosave + restore)'
);

// ── FIX 4a: clear draft on submit success ──
rep(
  `setQImg('');setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('');setFormKey(function(k){return k+1})`,
  `setQImg('');setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('');setFormKey(function(k){return k+1});try{localStorage.removeItem('pr_q_draft')}catch(e){};setQTxtVal('');setQTxtInit('');setLatexPrev(false)`,
  'clear draft on submit success'
);

// ── FIX 4b: clear draft on Clear button ──
rep(
  `setFormKey(function(k){return k+1});T('Form cleared')`,
  `setFormKey(function(k){return k+1});try{localStorage.removeItem('pr_q_draft')}catch(e){};setQTxtVal('');setQTxtInit('');setLatexPrev(false);T('Form cleared')`,
  'clear draft on Clear button'
);

// ── FIX 5a: STextarea init='' → init={qTxtInit} ──
rep(
  `<STextarea init='' onSet={function(v){qTxtR.current=v}}`,
  `<STextarea init={qTxtInit} onSet={function(v){qTxtR.current=v}}`,
  'STextarea init prop'
);

// ── FIX 5b: LaTeX preview UI after STextarea ──
const previewUI = `
                  <div style={{marginTop:6,display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
                    <button type='button' onClick={()=>setLatexPrev(function(p){return !p})} style={{fontSize:10,padding:'3px 10px',borderRadius:4,background:'rgba(167,139,250,0.15)',border:'1px solid rgba(167,139,250,0.3)',color:'#A78BFA',cursor:'pointer'}}>{latexPrev?'\\u25b2 Hide Math':'\\u25bc Preview Math \\u0192(x)'}</button>
                    {draftSaved&&<span style={{fontSize:10,color:'#22c55e',marginLeft:4}}>{'\\u2713 Draft saved'}</span>}
                    {draftRestored&&<span style={{fontSize:10,color:'#A78BFA',marginLeft:4}}>{'\\u21ba Draft restored'}</span>}
                  </div>
                  {latexPrev&&<div style={{marginTop:6,padding:'8px 12px',background:'rgba(255,255,255,0.04)',borderRadius:6,border:'1px solid rgba(255,255,255,0.08)',color:'#E2E8F0',fontSize:13,lineHeight:1.6,minHeight:40}} dangerouslySetInnerHTML={{__html:renderLatex(qTxtVal)||'<span style="color:#475569;font-style:italic">Type $x^2$ above to preview math...</span>'}}/>}`;

// Try Unicode ellipsis variant first, then three-dots
const ST_UNI = "onSet={function(v){qTxtR.current=v}} ph='Type the full question here\u2026' rows={3} style={{...inp,resize:'vertical'}}/>"; 
const ST_DOT = "onSet={function(v){qTxtR.current=v}} ph='Type the full question here...' rows={3} style={{...inp,resize:'vertical'}}/>"; 

if (c.includes(ST_UNI)) {
  c = c.replace(ST_UNI, () => ST_UNI + previewUI);
  console.log('  ✓ LaTeX preview UI injected (ellipsis)');
} else if (c.includes(ST_DOT)) {
  c = c.replace(ST_DOT, () => ST_DOT + previewUI);
  console.log('  ✓ LaTeX preview UI injected (dots)');
} else {
  console.error('FIX5b FAIL: STextarea placeholder not found');
  process.exit(1);
}

fs.writeFileSync('app/admin/x7k2p/page.tsx', c);
console.log('\npage.tsx: All fixes applied!');
JSEOF

node /tmp/patch_page.js

echo ""
echo "=== Step 3: Add KaTeX CSS to layout ==="
node -e "
const fs=require('fs');
const lp='app/layout.tsx';
if(!fs.existsSync(lp)){console.log('layout.tsx not found, skipping');process.exit(0);}
let c=fs.readFileSync(lp,'utf8');
if(c.includes('katex')){console.log('KaTeX CSS already present');process.exit(0);}
c=\\\"import 'katex/dist/katex.min.css'\\n\\\"+c;
fs.writeFileSync(lp,c);
console.log('  ✓ KaTeX CSS added to layout.tsx');
"

echo ""
echo "=== Step 4: Verify ==="
grep -n "renderLatex\|katex\|latexPrev\|qTxtVal\|qTxtInit\|draftSaved\|pr_q_draft" app/admin/x7k2p/page.tsx | head -20

echo ""
echo "=== Step 5: Git push ==="
git add -A
git commit -m "feat: LaTeX/Math preview + Auto-save draft in Add Question"
GIT_ASKPASS='' git push origin HEAD:main

echo ""
echo "=== DONE ==="
echo "Test karo:"
echo "  1. Add Question page kholo"
echo "  2. Question text mein type karo: x^2 + y^2 = r^2 phir dollar signs mein wrap karo"
echo "  3. 'Preview Math' button click karo → formula render hogi"
echo "  4. Form fill karo → 2 sec baad 'Draft saved' dikhega"
echo "  5. Page reload karo → 'Draft restored' dikhega aur form refill hoga"
