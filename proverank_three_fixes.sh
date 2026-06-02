#!/bin/bash
set -e
echo "================================================="
echo "🚀 ProveRank — 3 Fixes: LaTeX + Image URLs + aiGF"
echo "================================================="

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 1: Question model — add optionImages
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "▶ Step 1: Question model..."
node << 'MODEL_EOF'
const fs = require('fs');
const f = '/home/runner/workspace/src/models/Question.js';
let c = fs.readFileSync(f,'utf8');
if(c.includes('optionImages')){console.log('already exists');process.exit(0);}
const t = "imageUrl: { type: String, default: '' },";
if(!c.includes(t)){console.error('imageUrl not found');process.exit(1);}
c = c.replace(t, t+"\n  optionImages: { type: [String], default: [] },");
fs.writeFileSync(f,c,'utf8');
console.log('✅ optionImages added to Question model');
MODEL_EOF

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 2: Groq prompt — LaTeX rules
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "▶ Step 2: Groq prompt LaTeX update..."
node << 'PROMPT_EOF'
const fs = require('fs');
const f = '/home/runner/workspace/src/utils/geminiAI.js';
let c = fs.readFileSync(f,'utf8');
if(c.includes('LATEX MATH RULES')){console.log('already has LaTeX rules');process.exit(0);}
const marker = 'Generate all ${n} questions now. Maximum scientific accuracy. Zero compromise on quality.`';
if(!c.includes(marker)){
  // Try without template literal backtick
  const m2 = 'Zero compromise on quality.';
  const idx = c.lastIndexOf(m2);
  if(idx === -1){console.log('marker not found');process.exit(1);}
  const latex = `\n\nLATEX MATH RULES (for numerical/physics/chemistry questions):\n- All formulas MUST use LaTeX: inline as $formula$ e.g. $\\\\tau = r \\\\times F$, $I = \\\\frac{V}{R}$\n- Display math: $$formula$$ for standalone equations e.g. $$\\\\alpha = \\\\frac{\\\\tau}{I} = 8 \\\\text{ rad/s}^2$$\n- Use: \\\\frac{a}{b} fractions, \\\\times multiply, ^2 squared, _0 subscript, \\\\omega \\\\alpha \\\\beta for Greek\n- Biology/theory questions: LaTeX not needed`;
  c = c.slice(0,idx+m2.length) + latex + c.slice(idx+m2.length);
  fs.writeFileSync(f,c,'utf8');
  console.log('✅ LaTeX rules added to Groq prompt');
} else {
  const idx2 = c.indexOf(marker);
  const latex2 = `\n\nLATEX MATH RULES (for numerical/physics/chemistry questions):\n- All formulas MUST use LaTeX: inline as $formula$ e.g. $\\\\tau = r \\\\times F$, $I = \\\\frac{V}{R}$\n- Display math: $$formula$$ e.g. $$\\\\alpha = \\\\frac{\\\\tau}{I} = 8 \\\\text{ rad/s}^2$$\n- Use: \\\\frac{a}{b} fractions, \\\\times multiply, ^2 squared\n- Biology/theory: LaTeX not needed\``;
  c = c.slice(0,idx2+marker.length-1) + latex2 + c.slice(idx2+marker.length);
  fs.writeFileSync(f,c,'utf8');
  console.log('✅ LaTeX rules added to Groq prompt (marker found)');
}
PROMPT_EOF

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 3: page.tsx — all frontend fixes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "▶ Step 3: page.tsx patching..."
node << 'PAGE_EOF'
const fs = require('fs');
const f = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(f,'utf8');
let fixes = 0;

// FIX A: aiGF fetch body
const gfT = 'JSON.stringify({subject:aiGSub,chapter:ch,topic:tp,count:parseInt(aiGCnt)||10,difficulty:aiGDiff,type:aiType})';
if(c.includes(gfT) && !c.includes('aiExamLevel,formats')){
  c = c.replace(gfT,'JSON.stringify({subject:aiGSub,chapter:ch,topic:tp,count:parseInt(aiGCnt)||10,difficulty:aiGDiff,type:aiType,examLevel:aiExamLevel,formats:aiFormats,imageUrl:aiImageUrl})');
  console.log('✅ Fix A: aiGF fetch body updated');
  fixes++;
} else { console.log('ℹ️  Fix A: aiGF fetch — already updated or not found'); }

// FIX B: Add aiQImgs state
if(!c.includes('aiQImgs')){
  const anchors = [
    "const [aiImageUrl,setAiImageUrl]=useState('')",
    "const [aiImageUrl,setAiImageUrl] = useState('')",
    "const [aiExamLevel,setAiExamLevel]=useState('NEET')",
  ];
  let stateAdded = false;
  for(const a of anchors){
    if(c.includes(a)){
      c = c.replace(a, a+"\nconst [aiQImgs,setAiQImgs]=useState({})");
      console.log('✅ Fix B: aiQImgs state added');
      fixes++; stateAdded=true; break;
    }
  }
  if(!stateAdded) console.log('⚠️  Fix B: anchor not found for aiQImgs state');
}

// FIX C: LaTeX in explanation — use renderLatex
// Find explanation display inside aiResult.map
const mapIdx = c.indexOf('aiResult.map((q:any,i:number)');
if(mapIdx !== -1){
  const expPats = ['{q.explanation}','{q.explanation||""}',"{q.explanation||''}",'{q?.explanation}'];
  let latexFixed = false;
  for(const ep of expPats){
    const eIdx = c.indexOf(ep, mapIdx);
    if(eIdx !== -1 && eIdx < mapIdx+8000){
      c = c.slice(0,eIdx)+'<span dangerouslySetInnerHTML={{__html:renderLatex(q.explanation||"")}}/>'+c.slice(eIdx+ep.length);
      console.log('✅ Fix C: renderLatex applied to explanation');
      fixes++; latexFixed=true; break;
    }
  }
  if(!latexFixed) console.log('⚠️  Fix C: explanation pattern not found in map');
} else { console.log('⚠️  Fix C: aiResult.map not found'); }

// FIX D: Image URL fields per question — inject into preview map
const mapIdx2 = c.indexOf('aiResult.map((q:any,i:number)');
if(mapIdx2 !== -1 && !c.includes('ATTACH IMAGES')){
  // Find the 💡 explanation section or renderLatex section end
  const anchPats = [
    '<span dangerouslySetInnerHTML={{__html:renderLatex(q.explanation||"")}}/>',
    'dangerouslySetInnerHTML={{__html:renderLatex',
    'q.explanation',
  ];
  let imgAdded = false;
  for(const ap of anchPats){
    const apIdx = c.indexOf(ap, mapIdx2);
    if(apIdx !== -1 && apIdx < mapIdx2+8000){
      // Find next </div> after this anchor
      const closeDivIdx = c.indexOf('</div>', apIdx);
      if(closeDivIdx !== -1 && closeDivIdx < apIdx+800){
        const imgSection = `</div><div style={{marginTop:8,padding:'8px 10px',background:'rgba(99,102,241,0.08)',borderRadius:8,border:'1px solid rgba(99,102,241,0.15)'}}>
<div style={{fontSize:10,fontWeight:700,color:'#818CF8',marginBottom:5}}>📷 ATTACH IMAGES (Optional)</div>
<div style={{marginBottom:5}}><div style={{fontSize:10,color:'#9CA3AF',marginBottom:2}}>Question Image URL:</div>
<input value={(aiQImgs[i]&&aiQImgs[i].qImg)||''} onChange={function(e){setAiQImgs(function(p){var n=Object.assign({},p);if(!n[i])n[i]={qImg:'',optImgs:['','','','']};n[i]=Object.assign({},n[i],{qImg:e.target.value});return n;})}} placeholder="https://... (diagram/image for this question)" style={{width:'100%',padding:'4px 8px',background:'rgba(255,255,255,0.05)',border:'1px solid rgba(99,102,241,0.3)',borderRadius:5,color:'#fff',fontSize:11,outline:'none',boxSizing:'border-box'}}/></div>
{q.options&&q.options.length>0&&(<div><div style={{fontSize:10,color:'#9CA3AF',marginBottom:3}}>Option Image URLs:</div>
{q.options.map(function(_,oi){return(<div key={oi} style={{display:'flex',alignItems:'center',gap:5,marginBottom:3}}><span style={{fontSize:10,color:'#6EE7B7',fontWeight:700,minWidth:18}}>{['A','B','C','D'][oi]}.</span><input value={(aiQImgs[i]&&aiQImgs[i].optImgs&&aiQImgs[i].optImgs[oi])||''} onChange={function(e){setAiQImgs(function(p){var n=Object.assign({},p);if(!n[i])n[i]={qImg:'',optImgs:['','','','']};var opts=(n[i].optImgs||['','','','']).slice();opts[oi]=e.target.value;n[i]=Object.assign({},n[i],{optImgs:opts});return n;})}} placeholder={'Image for option '+['A','B','C','D'][oi]} style={{flex:1,padding:'3px 6px',background:'rgba(255,255,255,0.04)',border:'1px solid rgba(99,102,241,0.2)',borderRadius:4,color:'#fff',fontSize:10,outline:'none'}}/></div>);})}`;
        c = c.slice(0,closeDivIdx) + imgSection + c.slice(closeDivIdx);
        console.log('✅ Fix D: Image URL fields injected per question in preview');
        fixes++; imgAdded=true; break;
      }
    }
  }
  if(!imgAdded) console.log('⚠️  Fix D: image URL injection anchor not found');
}

// FIX E: Include aiQImgs in save — find approvalStatus in bulk mapping
const savePats = [
  "approvalStatus:q.approvalStatus||'pending'",
  "approvalStatus:'pending'",
];
let saveFixed = false;
for(const sp of savePats){
  const spIdx = c.indexOf(sp);
  if(spIdx !== -1 && !saveFixed){
    const before = c.slice(Math.max(0,spIdx-300),spIdx);
    if((before.includes('aiResult')||before.includes('toSave')||before.includes('q.type'))&&!c.slice(spIdx,spIdx+100).includes('optionImages')){
      c = c.slice(0,spIdx+sp.length)+',imageUrl:(aiQImgs[i]&&aiQImgs[i].qImg)||q.imageUrl||"",optionImages:(aiQImgs[i]&&aiQImgs[i].optImgs)||[]'+c.slice(spIdx+sp.length);
      console.log('✅ Fix E: imageUrl+optionImages in save function');
      fixes++; saveFixed=true;
    }
  }
}
if(!saveFixed) console.log('ℹ️  Fix E: save function pattern not found or already done');

// FIX F: Reset aiQImgs after successful save
if(c.includes('setAiResult([])') && !c.includes('setAiQImgs({})')){
  c = c.replace('setAiResult([])', 'setAiResult([]);setAiQImgs({})');
  console.log('✅ Fix F: aiQImgs reset on save');
  fixes++;
}

fs.writeFileSync(f, c, 'utf8');
console.log('\nTotal fixes applied: '+fixes);
PAGE_EOF

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 4: bulk-save — add optionImages support
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "▶ Step 4: bulk-save update..."
node << 'BULK_EOF'
const fs = require('fs');
const f = '/home/runner/workspace/src/routes/questionFeatures.js';
let c = fs.readFileSync(f,'utf8');
if(c.includes('optionImages')){console.log('already has optionImages');process.exit(0);}
const targets = ["imageUrl: q.imageUrl || '',", "imageUrl: q.imageUrl||'',", "imageUrl:q.imageUrl||''"];
let done = false;
for(const t of targets){
  if(c.includes(t)){
    c = c.replace(t, t+"\n        optionImages: Array.isArray(q.optionImages)?q.optionImages:[],");
    done=true; break;
  }
}
if(done){ fs.writeFileSync(f,c,'utf8'); console.log('✅ optionImages in bulk-save'); }
else { console.log('ℹ️  imageUrl not in bulk-save — model default will handle it'); }
BULK_EOF

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 5: Git push
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "▶ Step 5: Git push..."
cd ~/workspace
git add -A
git commit -m "feat: LaTeX math rendering + image URL per Q&Option + aiGF fix + optionImages"
git push origin main
echo "✅ Pushed!"

echo ""
echo "================================================="
echo "✅ ALL DONE! Test on live site after 3-5 min"
echo "================================================="
