#!/bin/bash
# ProveRank — Duplicate Question Check Patch v1
# Adds: Qs Bank scan before save (Manual + AI + Files preview modals)
# Usage: bash proverank_dup_check_v1.sh

FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

if [ ! -f "$FILE" ]; then
  echo "❌ ERROR: File not found: $FILE"
  exit 1
fi

echo "📂 Found page.tsx — applying patch..."

node << 'NODEEOF'
const fs = require('fs');
const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let code = fs.readFileSync(FILE, 'utf8');

// ─────────────────────────────────────────────
// PATCH 1 — Add 3 new states after showAddPreview state
// ─────────────────────────────────────────────
const P1_OLD = `const [showAddPreview,setShowAddPreview]=useState(false)`;
const P1_NEW = `const [showAddPreview,setShowAddPreview]=useState(false)
const [dupFound,setDupFound]=useState<any[]>([])
const [aiDupMap,setAiDupMap]=useState<Record<number,any>>({})
const [fmDupMap,setFmDupMap]=useState<Record<number,any>>({})`;
if (!code.includes(P1_OLD)) { console.error('❌ PATCH 1 target not found'); process.exit(1); }
code = code.replace(P1_OLD, P1_NEW);
console.log('✅ Patch 1 — States added');

// ─────────────────────────────────────────────
// PATCH 2 — Add findDups utility function before addQ
// ─────────────────────────────────────────────
const P2_OLD = `  const addQ=useCallback(()=>{`;
const P2_NEW = `  const findDups=useCallback((newText:string,opts:string[],bank:any[])=>{
    const nt=(newText||'').toLowerCase().trim()
    if(nt.length<10)return[]
    return bank.filter((q:any)=>{
      if((q.text||'').toLowerCase().trim()!==nt)return false
      const eo=(q.options||[]).map((o:string)=>(o||'').toLowerCase().trim()).sort().join('|')
      const no=opts.map((o:string)=>(o||'').toLowerCase().trim()).filter(Boolean).sort().join('|')
      return !no||eo===no
    })
  },[])
  const addQ=useCallback(()=>{`;
if (!code.includes(P2_OLD)) { console.error('❌ PATCH 2 target not found'); process.exit(1); }
code = code.replace(P2_OLD, P2_NEW);
console.log('✅ Patch 2 — findDups utility added');

// ─────────────────────────────────────────────
// PATCH 3 — Modify addQ to check duplicates before showing preview
// ─────────────────────────────────────────────
const P3_OLD = `const addQ=useCallback(()=>{\nconst text=qTxtR.current\nif(!text){T('Question text is required.','e');return}\nsetShowAddPreview(true)\n},[qSubj,qDiff,qType,qAns,T])`;
const P3_NEW = `const addQ=useCallback(()=>{\nconst text=qTxtR.current\nif(!text){T('Question text is required.','e');return}\nconst dups=findDups(text,[qA.current,qB.current,qC.current,qD.current],questions)\nsetDupFound(dups)\nsetShowAddPreview(true)\n},[qSubj,qDiff,qType,qAns,T,questions,findDups])`;
if (!code.includes(P3_OLD)) { console.error('❌ PATCH 3 target not found'); process.exit(1); }
code = code.replace(P3_OLD, P3_NEW);
console.log('✅ Patch 3 — addQ updated with dup check');

// ─────────────────────────────────────────────
// PATCH 4 — Modify "Add to Question Bank" direct button (also checks dups)
// ─────────────────────────────────────────────
const P4_OLD = `<button onClick={()=>setShowAddPreview(true)} disabled={savingQ} style={{...bp,flex:2,minWidth:150,opacity:savingQ?0.7:1}}>{savingQ?'⟳ Saving\u2026':'✅ Add to Question Bank'}</button>`;
const P4_NEW = `<button onClick={()=>{const dups=findDups(qTxtR.current,[qA.current,qB.current,qC.current,qD.current],questions);setDupFound(dups);setShowAddPreview(true)}} disabled={savingQ} style={{...bp,flex:2,minWidth:150,opacity:savingQ?0.7:1}}>{savingQ?'\u29d0 Saving\u2026':'✅ Add to Question Bank'}</button>`;
if (!code.includes(P4_OLD)) {
  // Try alternate ellipsis
  const P4_OLD2 = `<button onClick={()=>setShowAddPreview(true)} disabled={savingQ} style={{...bp,flex:2,minWidth:150,opacity:savingQ?0.7:1}}>{savingQ?'⟳ Saving…':'✅ Add to Question Bank'}</button>`;
  if (!code.includes(P4_OLD2)) { console.error('❌ PATCH 4 target not found'); process.exit(1); }
  code = code.replace(P4_OLD2, `<button onClick={()=>{const dups=findDups(qTxtR.current,[qA.current,qB.current,qC.current,qD.current],questions);setDupFound(dups);setShowAddPreview(true)}} disabled={savingQ} style={{...bp,flex:2,minWidth:150,opacity:savingQ?0.7:1}}>{savingQ?'⟳ Saving…':'✅ Add to Question Bank'}</button>`);
} else {
  code = code.replace(P4_OLD, P4_NEW);
}
console.log('✅ Patch 4 — Add to Bank button updated');

// ─────────────────────────────────────────────
// PATCH 5 — Add dup warning inside showAddPreview modal (before action buttons)
// ─────────────────────────────────────────────
const P5_ANCHOR = `<div style={{display:'flex',gap:10,justifyContent:'flex-end',marginTop:16}}>`;
// Find unique occurrence — only the one in showAddPreview modal
// Context: it comes right after the tags row which ends with qType span
const P5_BEFORE = `{qType&&<span style={{background:'rgba(99,102,241,0.2)',color:'#818cf8',padding:'3px 10px',borderRadius:20,fontSize:11}}>{qType}</span>}\n</div>\n<div style={{display:'flex',gap:10,justifyContent:'flex-end',marginTop:16}}>`;
const P5_AFTER  = `{qType&&<span style={{background:'rgba(99,102,241,0.2)',color:'#818cf8',padding:'3px 10px',borderRadius:20,fontSize:11}}>{qType}</span>}\n</div>\n{dupFound.length>0&&(<div style={{background:'rgba(239,68,68,0.1)',border:'1px solid rgba(239,68,68,0.45)',borderRadius:10,padding:'11px 14px',marginBottom:12,marginTop:10}}><div style={{color:'#f87171',fontWeight:700,fontSize:12,marginBottom:5}}>⚠️ Duplicate Detected — {dupFound.length} similar question{dupFound.length>1?'s are':' is'} already in the bank</div>{dupFound.slice(0,2).map((dq:any,di:number)=>(<div key={di} style={{fontSize:11,color:'#94a3b8',padding:'4px 8px',background:'rgba(239,68,68,0.07)',borderRadius:6,marginBottom:3}}>🔴 {(dq.text||'').slice(0,80)}{(dq.text||'').length>80?'\u2026':''}</div>))}<div style={{fontSize:10,color:'#f87171',marginTop:5,opacity:0.8}}>You can still save — but duplicate questions reduce paper quality.</div></div>)}\n<div style={{display:'flex',gap:10,justifyContent:'flex-end',marginTop:16}}>`;
if (!code.includes(P5_BEFORE)) { console.error('❌ PATCH 5 target not found'); process.exit(1); }
code = code.replace(P5_BEFORE, P5_AFTER);
console.log('✅ Patch 5 — Dup warning added in Manual Add preview modal');

// ─────────────────────────────────────────────
// PATCH 6 — Modify "Review & Save All" button (AI) to compute aiDupMap
// ─────────────────────────────────────────────
const P6_OLD = `<button onClick={()=>setShowAiPreview(true)} style={{...bp,width:'100%',fontSize:11,marginBottom:8}}>`;
const P6_NEW = `<button onClick={()=>{const m:Record<number,any>={};aiGResult.forEach((q:any,i:number)=>{const d=findDups(q.text||q.question||'',q.options||[],questions);if(d.length)m[i]=d[0]});setAiDupMap(m);setShowAiPreview(true)}} style={{...bp,width:'100%',fontSize:11,marginBottom:8}}>`;
if (!code.includes(P6_OLD)) { console.error('❌ PATCH 6 target not found'); process.exit(1); }
code = code.replace(P6_OLD, P6_NEW);
console.log('✅ Patch 6 — AI Review button updated with dupMap compute');

// ─────────────────────────────────────────────
// PATCH 7 — Add dup badge on each question in AI preview modal
// ─────────────────────────────────────────────
const P7_OLD = `<span style={{color:'#c084fc',fontSize:11,fontWeight:700}}>Q{i+1}</span>`;
const P7_NEW = `<span style={{color:'#c084fc',fontSize:11,fontWeight:700}}>Q{i+1}</span>{aiDupMap[i]&&<span style={{background:'rgba(239,68,68,0.22)',color:'#f87171',fontSize:10,fontWeight:700,padding:'2px 8px',borderRadius:10,marginLeft:6,border:'1px solid rgba(239,68,68,0.5)'}}>⚠️ Duplicate in Bank</span>}`;
if (!code.includes(P7_OLD)) { console.error('❌ PATCH 7 target not found'); process.exit(1); }
code = code.replace(P7_OLD, P7_NEW);
console.log('✅ Patch 7 — AI dup badge added per question');

// ─────────────────────────────────────────────
// PATCH 8 — Add dup detail box inside AI question card (after explanation)
// ─────────────────────────────────────────────
const P8_OLD = `{(q.explanation||q.exp)&&<div style={{fontSize:11,color:'#fcd34d',marginTop:6,padding:'4px 8px',background:'rgba(252,211,77,0.07)',borderRadius:6}}>` + '\ud83d\udca1' + ` <span dangerouslySetInnerHTML={{__html:renderLatex(formatQText(q.explanation||q.exp||''))}}/></div>}\n</div>\n))}`;

// Use a safer anchor that doesn't rely on emoji encoding
const P8_ANCHOR_SEARCH = '){aiDupMap[i]&&' ;
if (code.includes(P8_ANCHOR_SEARCH)) {
  console.log('ℹ️  Patch 8 already applied — skipping');
} else {
  // Find the end of AI question card: after explanation line before closing divs
  const P8_IDX = code.indexOf(
    `{(q.explanation||q.exp)&&<div style={{fontSize:11,color:'#fcd34d',marginTop:6,padding:'4px 8px',background:'rgba(252,211,77,0.07)',borderRadius:6}}>`
  );
  if (P8_IDX === -1) { console.error('❌ PATCH 8 anchor not found'); process.exit(1); }
  // Find the closing sequence after the explanation div
  const P8_CLOSE_SEARCH = `</div>}\n</div>\n))}\n</div>\n{aiGResult.length===0`;
  const P8_CLOSE_IDX = code.indexOf(P8_CLOSE_SEARCH, P8_IDX);
  if (P8_CLOSE_IDX === -1) { console.error('❌ PATCH 8 close anchor not found'); process.exit(1); }
  const INSERT_POS = P8_CLOSE_IDX + `</div>}`.length;
  const DUP_BOX = `\n{aiDupMap[i]&&<div style={{background:'rgba(239,68,68,0.09)',border:'1px solid rgba(239,68,68,0.35)',borderRadius:7,padding:'7px 10px',marginTop:6,fontSize:11,color:'#f87171'}}>⚠️ Already in bank: <span style={{color:'#94a3b8'}}>{(aiDupMap[i].text||'').slice(0,70)}{(aiDupMap[i].text||'').length>70?'\u2026':''}</span></div>}`;
  code = code.slice(0, INSERT_POS) + DUP_BOX + code.slice(INSERT_POS);
  console.log('✅ Patch 8 — AI dup detail box added inside card');
}

// ─────────────────────────────────────────────
// PATCH 9 — Modify FM preview trigger to compute fmDupMap
// ─────────────────────────────────────────────
const P9_OLD = `setFmResult(tagged);setFmShowPreview(true);T('✅ '+tagged.length+' Qs generated!')`;
const P9_NEW = `setFmResult(tagged);const fmp:Record<number,any>={};tagged.forEach((q:any,j:number)=>{const d=findDups(q.text||'',q.options||[],questions);if(d.length)fmp[j]=d[0]});setFmDupMap(fmp);setFmShowPreview(true);T('✅ '+tagged.length+' Qs generated!')`;
if (!code.includes(P9_OLD)) { console.error('❌ PATCH 9 target not found'); process.exit(1); }
code = code.replace(P9_OLD, P9_NEW);
console.log('✅ Patch 9 — FM preview trigger updated with dupMap compute');

// ─────────────────────────────────────────────
// PATCH 10 — Add dup badge on each question in FM preview modal
// ─────────────────────────────────────────────
const P10_OLD = `<span style={{color:'#00C864',fontSize:11,fontWeight:700}}>Q{i+1}</span>`;
const P10_NEW = `<span style={{color:'#00C864',fontSize:11,fontWeight:700}}>Q{i+1}</span>{fmDupMap[i]&&<span style={{background:'rgba(239,68,68,0.22)',color:'#f87171',fontSize:10,fontWeight:700,padding:'2px 8px',borderRadius:10,marginLeft:6,border:'1px solid rgba(239,68,68,0.5)'}}>⚠️ Duplicate in Bank</span>}`;
if (!code.includes(P10_OLD)) { console.error('❌ PATCH 10 target not found'); process.exit(1); }
code = code.replace(P10_OLD, P10_NEW);
console.log('✅ Patch 10 — FM dup badge added per question');

// ─────────────────────────────────────────────
// PATCH 11 — Add dup detail box inside FM question card (after explanation)
// ─────────────────────────────────────────────
const P11_ANCHOR_SEARCH = '){fmDupMap[i]&&';
if (code.includes(P11_ANCHOR_SEARCH)) {
  console.log('ℹ️  Patch 11 already applied — skipping');
} else {
  const FM_CLOSE_SEARCH = `</div>}\n                                </div>\n                              )\n                            })}\n                          </div>\n                          {fmResult.length===0`;
  const FM_CLOSE_IDX = code.indexOf(FM_CLOSE_SEARCH);
  if (FM_CLOSE_IDX === -1) { console.error('❌ PATCH 11 FM close anchor not found'); process.exit(1); }
  const FM_INSERT_POS = FM_CLOSE_IDX + `</div>}`.length;
  const FM_DUP_BOX = `\n                                  {fmDupMap[i]&&<div style={{background:'rgba(239,68,68,0.09)',border:'1px solid rgba(239,68,68,0.35)',borderRadius:7,padding:'7px 10px',marginTop:6,fontSize:11,color:'#f87171'}}>⚠️ Already in bank: <span style={{color:'#94a3b8'}}>{(fmDupMap[i].text||'').slice(0,70)}{(fmDupMap[i].text||'').length>70?'\u2026':''}</span></div>}`;
  code = code.slice(0, FM_INSERT_POS) + FM_DUP_BOX + code.slice(FM_INSERT_POS);
  console.log('✅ Patch 11 — FM dup detail box added inside card');
}

// ─────────────────────────────────────────────
// WRITE FILE
// ─────────────────────────────────────────────
fs.writeFileSync(FILE, code, 'utf8');
console.log('\n🎉 All patches applied! page.tsx updated successfully.');
NODEEOF

if [ $? -eq 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Patch complete — next steps:"
  echo "1. cd ~/workspace/frontend && npm run build"
  echo "2. If build ✅ → git add -A && git commit -m 'feat: duplicate question check in all 3 preview modals' && git push"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo "❌ Patch FAILED — check errors above"
fi
