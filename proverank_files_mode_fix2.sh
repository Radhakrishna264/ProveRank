#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — Files Mode Bug Fix #2
# Fix: Double A/B/C/D prefix | Edit in preview | Answer+Explanation | Formats
# ═══════════════════════════════════════════════════════════════

FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_fix2"
echo "✅ Backup created"

node << 'NODEEOF'
const fs = require('fs');
const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let code = fs.readFileSync(FILE, 'utf8');
let patches = 0;

function replace(label, oldStr, newStr) {
  if (code.includes(oldStr)) {
    code = code.replace(oldStr, newStr);
    console.log('  ✅ PATCH ' + (++patches) + ': ' + label);
  } else {
    console.log('  ⚠️  SKIP : ' + label + ' (not found)');
  }
}

// ── PATCH 1 — Add fmEditIdx + fmEditQ states ───────────────────
replace(
  'Add fmEditIdx & fmEditQ states',
  `  const [fmResult,setFmResult]=useState([])
  const [fmShowPreview,setFmShowPreview]=useState(false)`,
  `  const [fmResult,setFmResult]=useState([])
  const [fmShowPreview,setFmShowPreview]=useState(false)
  const [fmEditIdx,setFmEditIdx]=useState(null)
  const [fmEditQ,setFmEditQ]=useState(null)`
);

// ── PATCH 2 — Bug 1: Fix generateFromMat to use correct API ────
// The materials/generate endpoint needs type & formats passed correctly
replace(
  'Fix generateFromMat API body with type+formats',
  `body:JSON.stringify({materialId:matId,count:cnt,difficulty:diff,examLevel:fmExamLevel,formats:fmFormats,subject:fmSubj,type:fmType})})`,
  `body:JSON.stringify({materialId:matId,count:parseInt(cnt)||10,difficulty:diff,examLevel:fmExamLevel,formats:fmFormats,subject:fmSubj,questionType:fmType,type:fmType})})` 
);

// ── PATCH 3 — Bug 2: Fix double prefix in NCERT showAiPreview ──
replace(
  'Fix double A/B/C/D prefix in NCERT preview',
  `<b>{L}.</b> <span dangerouslySetInnerHTML={{__html:renderLatex(opt)}}/>{isAns&&<span style={{marginLeft:6,fontSize:10}}>✓</span>}`,
  `<b>{L}.</b> <span dangerouslySetInnerHTML={{__html:renderLatex((opt||'').replace(/^[A-Da-d][\\.\\)\\:]\\s*/,'').trim())}}/>{isAns&&<span style={{marginLeft:6,fontSize:10}}>✓</span>}`
);

// ── PATCH 4 — Bug 2+3+4: Replace Files fmShowPreview modal ─────
// Old minimal preview → New full preview with Edit, Answer, Explanation
replace(
  'Replace fmShowPreview with full-featured modal (Edit+Answer+Explanation)',
  `    {/* Files Mode — Question Preview Modal */}
                    {fmShowPreview&&(
                      <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.95)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:'12px'}} onClick={function(){setFmShowPreview(false)}}>
                        <div style={{background:'#0d1117',border:'1px solid rgba(0,200,100,0.4)',borderRadius:16,padding:'20px',maxWidth:640,width:'100%',maxHeight:'92vh',overflowY:'auto'}} onClick={function(e){e.stopPropagation()}}>
                          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                            <span style={{color:'#00C864',fontWeight:700,fontSize:15}}>📁 Questions Preview ({fmResult.length})</span>
                            <button onClick={function(){setFmShowPreview(false)}} style={{background:'none',border:'none',color:'#666',fontSize:22,cursor:'pointer'}}>✕</button>
                          </div>
                          {fmResult.map(function(q:any,i:number){return(
                            <div key={i} style={{background:'rgba(0,200,100,0.04)',border:'1px solid rgba(0,200,100,0.15)',borderRadius:12,padding:'14px',marginBottom:10}}>
                              <div style={{fontSize:12,color:'#E2E8F0',marginBottom:8,lineHeight:1.6}}><span style={{color:'#00C864',fontWeight:700,marginRight:6}}>Q{i+1}.</span>{q.text||'No text'}</div>
                              {(q.options||[]).map(function(o:string,j:number){const isCorr=q.correctAnswer===('Option '+String.fromCharCode(65+j))||q.correct===j||q.correctAnswer===o;return(
                                <div key={j} style={{padding:'4px 10px',borderRadius:6,marginBottom:3,background:isCorr?'rgba(0,200,100,0.1)':'rgba(255,255,255,0.03)',border:isCorr?'1px solid rgba(0,200,100,0.4)':'1px solid transparent',fontSize:11,color:isCorr?'#00C864':'#CBD5E1'}}>{String.fromCharCode(65+j)}. {o}{isCorr&&' ✓'}</div>
                              )})}
                              <button onClick={function(){setFmResult(function(p:any[]){return p.filter(function(_:any,idx:number){return idx!==i})})}} style={{...bg_,fontSize:9,padding:'2px 7px',marginTop:6,color:'#F87171'}}>🗑️ Remove</button>
                            </div>
                          )})}
                          {fmResult.length===0&&<div style={{color:'#f87171',textAlign:'center',padding:'20px'}}>All questions removed!</div>}
                          <div style={{display:'flex',gap:10,justifyContent:'flex-end',marginTop:12}}>
                            <button onClick={function(){setFmShowPreview(false)}} style={{padding:'10px 20px',borderRadius:8,background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.15)',color:'#94a3b8',cursor:'pointer',fontSize:13}}>Cancel</button>
                            <button onClick={function(){setFmShowPreview(false);saveFmQs()}} disabled={fmResult.length===0} style={{padding:'10px 24px',borderRadius:8,background:'linear-gradient(135deg,#059669,#10b981)',border:'none',color:'#fff',cursor:'pointer',fontSize:13,fontWeight:700,opacity:fmResult.length===0?0.5:1}}>✅ Save All ({fmResult.length})</button>
                          </div>
                        </div>
                      </div>
                    )}`,

  `    {/* Files Mode — Question Preview Modal (Full) */}
                    {fmShowPreview&&(
                      <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.92)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:'12px'}} onClick={function(){setFmShowPreview(false)}}>
                        <div style={{background:'#0d1117',border:'1px solid rgba(0,200,100,0.4)',borderRadius:16,padding:'20px',maxWidth:660,width:'100%',maxHeight:'92vh',overflowY:'auto'}} onClick={function(e){e.stopPropagation()}}>
                          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                            <span style={{color:'#00C864',fontWeight:700,fontSize:15}}>📁 Files Questions Preview ({fmResult.length})</span>
                            <button onClick={function(){setFmShowPreview(false)}} style={{background:'none',border:'none',color:'#666',fontSize:22,cursor:'pointer'}}>✕</button>
                          </div>
                          <div style={{marginBottom:14}}>
                            {fmResult.map(function(q:any,i:number){
                              return(
                                <div key={i} style={{background:'rgba(0,200,100,0.06)',border:'1px solid rgba(0,200,100,0.2)',borderRadius:10,padding:'12px',marginBottom:10,position:'relative'}}>
                                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:8}}>
                                    <span style={{color:'#00C864',fontSize:11,fontWeight:700}}>Q{i+1}</span>
                                    <div style={{display:'flex',gap:6}}>
                                      <button onClick={function(){setFmEditIdx(i);setFmEditQ(Object.assign({},q))}} style={{background:'rgba(59,130,246,0.2)',border:'1px solid rgba(59,130,246,0.4)',color:'#60a5fa',borderRadius:6,padding:'3px 10px',fontSize:11,cursor:'pointer'}}>✏️ Edit</button>
                                      <button onClick={function(){setFmResult(function(p:any[]){return p.filter(function(_:any,j:number){return j!==i})})}} style={{background:'rgba(239,68,68,0.15)',border:'1px solid rgba(239,68,68,0.4)',color:'#f87171',borderRadius:6,padding:'3px 10px',fontSize:11,cursor:'pointer'}}>🗑️ Delete</button>
                                    </div>
                                  </div>
                                  <div style={{color:'#e2e8f0',fontSize:13,marginBottom:6,lineHeight:1.6}} dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/>
                                  {(q.options||[]).map(function(opt:string,j:number){
                                    const L=['A','B','C','D'][j]
                                    const isAns=q.correctAnswer===('Option '+L)||q.correctAnswer===L||q.correctLetter===L||q.correct_answer===('Option '+L)||q.correct_answer===L||(Array.isArray(q.correct)&&q.correct.includes(j))
                                    const cleanOpt=(opt||'').replace(/^[A-Da-d][\.\)\:]\s*/,'').trim()
                                    return <div key={j} style={{fontSize:12,padding:'4px 8px',borderRadius:6,marginBottom:3,background:isAns?'rgba(34,197,94,0.12)':'rgba(255,255,255,0.03)',border:isAns?'1px solid rgba(34,197,94,0.4)':'1px solid rgba(255,255,255,0.06)',color:isAns?'#4ade80':'#94a3b8'}}>
                                      <b>{L}.</b> <span dangerouslySetInnerHTML={{__html:renderLatex(cleanOpt)}}/>{isAns&&<span style={{marginLeft:6,fontSize:10}}>✓</span>}
                                    </div>
                                  })}
                                  {(q.explanation||q.exp)&&<div style={{fontSize:11,color:'#fcd34d',marginTop:6,padding:'4px 8px',background:'rgba(252,211,77,0.07)',borderRadius:6}}>💡 <span dangerouslySetInnerHTML={{__html:renderLatex(formatQText(q.explanation||q.exp||''))}}/></div>}
                                </div>
                              )
                            })}
                          </div>
                          {fmResult.length===0&&<div style={{color:'#f87171',textAlign:'center',padding:'20px'}}>All questions deleted!</div>}
                          <div style={{display:'flex',gap:10,justifyContent:'flex-end'}}>
                            <button onClick={function(){setFmShowPreview(false)}} style={{padding:'10px 20px',borderRadius:8,background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.15)',color:'#94a3b8',cursor:'pointer',fontSize:13}}>Cancel</button>
                            <button onClick={function(){setFmShowPreview(false);saveFmQs()}} disabled={fmResult.length===0||aiSaving} style={{padding:'10px 24px',borderRadius:8,background:'linear-gradient(135deg,#059669,#10b981)',border:'none',color:'#fff',cursor:'pointer',fontSize:13,fontWeight:700}}>✅ Confirm Save All ({fmResult.length})</button>
                          </div>
                        </div>
                      </div>
                    )}
                    {/* Files Mode — Edit Question Modal */}
                    {fmEditQ!==null&&fmEditIdx!==null&&(
                      <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.92)',zIndex:10001,display:'flex',alignItems:'center',justifyContent:'center',padding:'12px'}} onClick={function(){setFmEditQ(null)}}>
                        <div style={{background:'#0d1117',border:'1px solid rgba(0,200,100,0.4)',borderRadius:16,padding:'20px',maxWidth:600,width:'100%',maxHeight:'90vh',overflowY:'auto'}} onClick={function(e){e.stopPropagation()}}>
                          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                            <span style={{color:'#00C864',fontWeight:700,fontSize:15}}>✏️ Edit Q{(fmEditIdx||0)+1}</span>
                            <button onClick={function(){setFmEditQ(null)}} style={{background:'none',border:'none',color:'#666',fontSize:22,cursor:'pointer'}}>✕</button>
                          </div>
                          <div style={{marginBottom:10}}><label style={lbl}>Question Text</label><textarea value={fmEditQ.text||fmEditQ.question||''} onChange={function(e){setFmEditQ(function(p:any){return Object.assign({},p,{text:e.target.value,question:e.target.value})})}} rows={3} style={{...inp,resize:'vertical' as any}}/></div>
                          {[0,1,2,3].map(function(j){return(
                            <div key={j} style={{marginBottom:8}}><label style={lbl}>Option {['A','B','C','D'][j]}</label>
                            <input value={(fmEditQ.options||[])[j]||''} onChange={function(e){setFmEditQ(function(p:any){const o=[...(p.options||['','','',''])];o[j]=e.target.value;return Object.assign({},p,{options:o})})}} style={{...inp}}/>
                            </div>
                          )})}
                          <div style={{marginBottom:10}}><label style={lbl}>Correct Answer</label>
                            <select value={fmEditQ.correctAnswer||fmEditQ.correct_answer||''} onChange={function(e){setFmEditQ(function(p:any){return Object.assign({},p,{correctAnswer:e.target.value,correct_answer:e.target.value})})}} style={{...inp,width:'100%'}}>
                              <option value=''>Select</option>
                              {['A','B','C','D'].map(function(l){return <option key={l} value={'Option '+l}>Option {l}</option>})}
                            </select>
                          </div>
                          <div style={{marginBottom:10}}><label style={lbl}>Explanation</label><textarea value={fmEditQ.explanation||fmEditQ.exp||''} onChange={function(e){setFmEditQ(function(p:any){return Object.assign({},p,{explanation:e.target.value,exp:e.target.value})})}} rows={2} style={{...inp,resize:'vertical' as any}}/></div>
                          <div style={{display:'flex',gap:10,justifyContent:'flex-end',marginTop:16}}>
                            <button onClick={function(){setFmEditQ(null)}} style={{padding:'10px 20px',borderRadius:8,background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.15)',color:'#94a3b8',cursor:'pointer'}}>Cancel</button>
                            <button onClick={function(){setFmResult(function(p:any[]){const a=[...p];const _q=Object.assign({},fmEditQ);const _map={'Option A':0,'Option B':1,'Option C':2,'Option D':3};const _ci=_map[_q.correctAnswer];if(_ci!==undefined){_q.correct=[_ci];_q.correctLetter=['A','B','C','D'][_ci];}a[fmEditIdx]=_q;return a});setFmEditQ(null)}} style={{padding:'10px 24px',borderRadius:8,background:'linear-gradient(135deg,#059669,#10b981)',border:'none',color:'#fff',cursor:'pointer',fontWeight:700}}>💾 Save</button>
                          </div>
                        </div>
                      </div>
                    )}`
);

fs.writeFileSync(FILE, code, 'utf8');
console.log('');
console.log('════════════════════════════════════════');
console.log('✅ All patches done! Total: ' + patches);
console.log('════════════════════════════════════════');
NODEEOF

echo ""
echo "🔍 Build check..."
cd $HOME/workspace/frontend && npm run build 2>&1 | grep -E "error|Error|✓|✗|Route" | head -20
echo ""
echo "▶ Push: git add -A && git commit -m 'fix: Files Mode bugs — edit/answer/explanation/double-prefix' && git push"
