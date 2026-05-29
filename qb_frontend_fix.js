// qb_frontend_fix.js — Comprehensive QB frontend fixes
// Run from ~/workspace: node qb_frontend_fix.js
const fs = require('fs')
const FILE = 'frontend/app/admin/x7k2p/page.tsx'
let t = fs.readFileSync(FILE, 'utf8')

// ─────────────────────────────────────────────
// FIX 1: Change qSubj default 'Physics' → ''
// ─────────────────────────────────────────────
if (t.includes("const [qSubj,setQSubj]=useState('Physics')")) {
  t = t.replace("const [qSubj,setQSubj]=useState('Physics')", "const [qSubj,setQSubj]=useState('')")
  console.log('✅ Fix 1: qSubj default cleared')
} else { console.log('ℹ️  Fix 1: qSubj already fixed or not found') }

// ─────────────────────────────────────────────
// FIX 2: Change qAns default 'A' → ''
// ─────────────────────────────────────────────
if (t.includes("const [qAns,setQAns]=useState('A')")) {
  t = t.replace("const [qAns,setQAns]=useState('A')", "const [qAns,setQAns]=useState('')")
  console.log('✅ Fix 2: qAns default cleared')
} else { console.log('ℹ️  Fix 2: qAns already fixed') }

// ─────────────────────────────────────────────
// FIX 3: After addQ success — reset qSubj,qDiff,qType,qAns states
// ─────────────────────────────────────────────
// Find addQ success line and add state resets
const ADD_SUCCESS_OLD = "qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current='';qTopicR.current='';qExpR.current=''"
const ADD_SUCCESS_NEW = "qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current='';qTopicR.current='';qExpR.current='';setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('')"
if (t.includes(ADD_SUCCESS_OLD)) {
  t = t.replace(ADD_SUCCESS_OLD, ADD_SUCCESS_NEW)
  console.log('✅ Fix 3: addQ clear states fixed')
} else { console.log('ℹ️  Fix 3: addQ clear anchor not found - skipping') }

// ─────────────────────────────────────────────
// FIX 4: Fix editQF to send correct[] array + correctAnswer
// ─────────────────────────────────────────────
const OLD_EDITQF = [
  "  const editQF=async(id,data)=>{",
  "    setSavingEQ(true)",
  "    try{",
  "      const r=await fetch(API+'/api/questions/'+id,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(data)})",
  "      if(r.ok){T('Question updated!');setEditQD(null);setTimeout(()=>fetchAll(),400)}",
  "      else{const e=await r.json().catch(()=>({}));T(e.message||'Update failed','e')}",
  "    }catch(ex){T(ex.message,'e')}",
  "    setSavingEQ(false)",
  "  }"
].join('\n')

const NEW_EDITQF = [
  "  const editQF=async(id,data)=>{",
  "    setSavingEQ(true)",
  "    try{",
  "      // Convert correctLetter to correct[] array for backend",
  "      const ltrs=['A','B','C','D']",
  "      const correctIdx=ltrs.indexOf(data.correctLetter||'A')",
  "      const payload={",
  "        text:data.text,hindiText:data.hindiText,subject:data.subject,",
  "        chapter:data.chapter,topic:data.topic,difficulty:data.difficulty,",
  "        type:data.type,options:data.options,explanation:data.explanation,",
  "        correct:[correctIdx>=0?correctIdx:0],",
  "        correctAnswer:data.correctLetter||'A'",
  "      }",
  "      const r=await fetch(API+'/api/questions/'+id,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(payload)})",
  "      if(r.ok){T('Question updated!');setEditQD(null);setTimeout(()=>fetchAll(),500)}",
  "      else{const e=await r.json().catch(()=>({}));T(e.message||'Update failed','e')}",
  "    }catch(ex){T(ex.message,'e')}",
  "    setSavingEQ(false)",
  "  }"
].join('\n')

if (t.includes(OLD_EDITQF)) {
  t = t.replace(OLD_EDITQF, NEW_EDITQF)
  console.log('✅ Fix 4: editQF fixed with correct[] mapping')
} else { console.log('ℹ️  Fix 4: editQF anchor not found') }

// ─────────────────────────────────────────────
// FIX 5: Replace QB JSX (complete redesign)
// ─────────────────────────────────────────────
const QB_COMMENT = '{/* ══ QUESTION BANK ══ */}'
const SMART_COMMENT = '{/* ══ SMART GENERATOR ══ */}'
const si = t.indexOf(QB_COMMENT)
const smartIdx = t.indexOf(SMART_COMMENT)

// Find the closing )} before SMART GENERATOR
const QB_BLOCK_END = "          )}\n\n          {/* ══ SMART GENERATOR ══ */}"
const ei = t.indexOf(QB_BLOCK_END, si)

if (si === -1 || ei === -1) {
  console.error('ERROR: QB JSX block not found. si='+si+' ei='+ei)
  process.exit(1)
}

const NEW_QB = `{/* ══ QUESTION BANK ══ */}
          {tab==='questions'&&(
            <div style={{position:'relative'}}>

              {/* ── QB HOME ── */}
              {qBV==='home'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:16,flexWrap:'wrap',gap:10}}>
                    <div>
                      <div style={pageTitle}>📚 Question Bank</div>
                      <div style={pageSub}>{(questions||[]).length} questions · NEET Pattern Ready</div>
                    </div>
                    <button onClick={expQB} style={{...bg_,fontSize:11,padding:'6px 12px'}}>⬇️ Export CSV</button>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:6,marginBottom:20}}>
                    {[{l:'Total',v:(questions||[]).length,c:'#A78BFA'},{l:'Physics',v:(questions||[]).filter(function(q){return q.subject==='Physics'}).length,c:'#60A5FA'},{l:'Chemistry',v:(questions||[]).filter(function(q){return q.subject==='Chemistry'}).length,c:'#F472B6'},{l:'Biology',v:(questions||[]).filter(function(q){return q.subject==='Biology'}).length,c:'#34D399'},{l:'Math',v:(questions||[]).filter(function(q){return q.subject==='Math'}).length,c:'#FBBF24'}].map(function(x){return(
                      <div key={x.l} style={{background:'rgba(255,255,255,0.04)',border:'1px solid '+x.c+'30',borderRadius:10,padding:'10px 6px',textAlign:'center'}}>
                        <div style={{fontSize:18,fontWeight:800,color:x.c}}>{x.v}</div>
                        <div style={{fontSize:9,color:'#64748b',marginTop:2}}>{x.l}</div>
                      </div>
                    )})}
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,maxWidth:660,margin:'0 auto 20px'}}>
                    <div onClick={function(){setQBV('add')}} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(77,159,255,0.12),rgba(160,80,255,0.08))',border:'1.5px solid rgba(77,159,255,0.3)',borderRadius:18,padding:'24px 16px',textAlign:'center',transition:'all 0.3s'}}>
                      <div style={{fontSize:36,marginBottom:8,filter:'drop-shadow(0 0 10px rgba(77,159,255,0.5))'}}>➕</div>
                      <div style={{fontSize:15,fontWeight:800,color:'#E2E8F0',marginBottom:4}}>Add Question</div>
                      <div style={{fontSize:11,color:'#64748B',marginBottom:14}}>Manually add or AI auto-generate</div>
                      <div style={{display:'inline-block',background:'rgba(77,159,255,0.15)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:8,padding:'6px 14px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>Add Questions →</div>
                    </div>
                    <div onClick={function(){setQBV('preview');setQSec('all')}} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(0,229,160,0.08),rgba(160,80,255,0.06))',border:'1.5px solid rgba(0,229,160,0.25)',borderRadius:18,padding:'24px 16px',textAlign:'center',transition:'all 0.3s'}}>
                      <div style={{fontSize:36,marginBottom:8,filter:'drop-shadow(0 0 10px rgba(0,229,160,0.4))'}}>👁️</div>
                      <div style={{fontSize:15,fontWeight:800,color:'#E2E8F0',marginBottom:4}}>Preview All Questions</div>
                      <div style={{fontSize:11,color:'#64748B',marginBottom:14}}>Browse, filter, edit section-wise</div>
                      <div style={{display:'inline-block',background:'rgba(0,229,160,0.12)',border:'1px solid rgba(0,229,160,0.35)',borderRadius:8,padding:'6px 14px',fontSize:11,color:'#00E5A0',fontWeight:700}}>Preview Bank →</div>
                    </div>
                  </div>
                  {(questions||[]).length>0&&(function(){
                    const all=questions||[];const tot=all.length||1
                    const ez=all.filter(function(q){return q.difficulty==='easy'}).length
                    const md=all.filter(function(q){return q.difficulty==='medium'}).length
                    const hd=all.filter(function(q){return q.difficulty==='hard'}).length
                    return(
                      <div style={{background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.07)',borderRadius:12,padding:'12px 14px'}}>
                        <div style={{fontSize:11,color:'#94A3B8',fontWeight:600,marginBottom:8}}>📊 Difficulty Distribution</div>
                        {[{l:'Easy',v:ez,col:'#00C864'},{l:'Medium',v:md,col:'#FFB300'},{l:'Hard',v:hd,col:'#FF4D4D'}].map(function(x){
                          const pct=Math.round((x.v/tot)*100)
                          return(
                            <div key={x.l} style={{display:'flex',alignItems:'center',gap:8,marginBottom:6}}>
                              <div style={{width:48,fontSize:10,color:x.col,fontWeight:600}}>{x.l}</div>
                              <div style={{flex:1,height:4,background:'rgba(255,255,255,0.06)',borderRadius:2}}>
                                <div style={{width:pct+'%',height:'100%',background:x.col,borderRadius:2,transition:'width 0.5s'}}/>
                              </div>
                              <div style={{width:58,fontSize:10,color:'#475569',textAlign:'right'}}>{x.v} ({pct}%)</div>
                            </div>
                          )
                        })}
                      </div>
                    )
                  })()}
                </div>
              )}

              {/* ── ADD QUESTION ── */}
              {qBV==='add'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:16}}>
                    <button onClick={function(){setQBV('home')}} style={{...bg_,padding:'6px 12px',fontSize:12}}>← Back</button>
                    <div>
                      <div style={pageTitle}>➕ Add Question to Bank</div>
                      <div style={pageSub}>Fill all details — saves instantly to Question Bank</div>
                    </div>
                  </div>
                  <div style={cs}>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:11}}>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>📝 Question Text (English) *</label>
                        <STextarea init='' onSet={function(v){qTxtR.current=v}} ph='Type the full question here…' rows={3} style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>🇮🇳 Hindi Text <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <STextarea init='' onSet={function(v){qHindiR.current=v}} ph='हिंदी में प्रश्न (वैकल्पिक)…' rows={2} style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div>
                        <label style={lbl}>📚 Subject *</label>
                        <select value={qSubj} onChange={function(e){setQSubj(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select Subject —</option>
                          <option value='Physics'>⚛️ Physics</option>
                          <option value='Chemistry'>🧪 Chemistry</option>
                          <option value='Biology'>🧬 Biology</option>
                          <option value='Math'>📐 Math</option>
                          <option value='Other'>📖 Other</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>🔢 Question Type</label>
                        <select value={qType} onChange={function(e){setQType(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value='SCQ'>SCQ — Single Correct</option>
                          <option value='MSQ'>MSQ — Multiple Correct</option>
                          <option value='Integer'>Integer Type</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>🎯 Difficulty</label>
                        <select value={qDiff} onChange={function(e){setQDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select —</option>
                          <option value='easy'>🟢 Easy</option>
                          <option value='medium'>🟡 Medium</option>
                          <option value='hard'>🔴 Hard</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>✅ Correct Answer</label>
                        <select value={qAns} onChange={function(e){setQAns(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select —</option>
                          <option value='A'>Option A</option>
                          <option value='B'>Option B</option>
                          <option value='C'>Option C</option>
                          <option value='D'>Option D</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>📖 Chapter</label>
                        <SInput init='' onSet={function(v){qChapR.current=v}} ph='e.g. Electrostatics' style={inp}/>
                      </div>
                      <div>
                        <label style={lbl}>📌 Topic</label>
                        <SInput init='' onSet={function(v){qTopicR.current=v}} ph='e.g. Coulombs Law' style={inp}/>
                      </div>
                      {['SCQ','MSQ'].includes(qType)&&(
                        <>
                          <div><label style={lbl}>Option A</label><SInput init='' onSet={function(v){qA.current=v}} ph='Option A…' style={inp}/></div>
                          <div><label style={lbl}>Option B</label><SInput init='' onSet={function(v){qB.current=v}} ph='Option B…' style={inp}/></div>
                          <div><label style={lbl}>Option C</label><SInput init='' onSet={function(v){qC.current=v}} ph='Option C…' style={inp}/></div>
                          <div><label style={lbl}>Option D</label><SInput init='' onSet={function(v){qD.current=v}} ph='Option D…' style={inp}/></div>
                        </>
                      )}
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>💡 Explanation <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <STextarea init='' onSet={function(v){qExpR.current=v}} ph='Explain the correct answer…' rows={2} style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>🖼️ Image URL <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <SInput init='' onSet={function(v){qImageR.current=v}} ph='https://imgur.com/… (paste image link)' style={inp}/>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:10,marginTop:14,flexWrap:'wrap'}}>
                      <button onClick={addQ} disabled={savingQ} style={{...bp,flex:2,minWidth:150,opacity:savingQ?0.7:1}}>
                        {savingQ?'⟳ Saving…':'✅ Add to Question Bank'}
                      </button>
                      <button onClick={function(){
                        qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';
                        qChapR.current='';qTopicR.current='';qExpR.current='';qImageR.current='';
                        setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('');
                        T('Form cleared')
                      }} style={{...bg_,padding:'8px 16px'}}>🗑️ Clear</button>
                    </div>
                  </div>
                  {/* AI Badge — below form card */}
                  <div style={{display:'flex',justifyContent:'center',marginTop:20}}>
                    <div onClick={function(){setAiGO(true);setAiGStep(1)}}
                      style={{
                        display:'flex',alignItems:'center',gap:10,
                        background:'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(168,85,247,0.2))',
                        border:'1.5px solid rgba(168,85,247,0.45)',
                        borderRadius:50,padding:'10px 22px',cursor:'pointer',
                        boxShadow:'0 0 20px rgba(168,85,247,0.35),0 0 40px rgba(77,159,255,0.15)',
                        animation:'pulse 2s infinite'
                      }}>
                      <div style={{
                        width:38,height:38,borderRadius:'50%',
                        background:'linear-gradient(135deg,#4D9FFF,#A855F7)',
                        display:'flex',alignItems:'center',justifyContent:'center',
                        boxShadow:'0 0 12px rgba(168,85,247,0.6)',
                        fontSize:18
                      }}>🤖</div>
                      <div>
                        <div style={{fontSize:13,fontWeight:800,color:'#E2E8F0',letterSpacing:'0.3px'}}>Upload Via AI</div>
                        <div style={{fontSize:10,color:'#A78BFA'}}>Auto-generate questions instantly</div>
                      </div>
                      <div style={{fontSize:16,color:'#A78BFA',marginLeft:4}}>✨</div>
                    </div>
                  </div>
                  <style dangerouslySetInnerHTML={{__html:'@keyframes pulse{0%,100%{box-shadow:0 0 20px rgba(168,85,247,0.35),0 0 40px rgba(77,159,255,0.15)}50%{box-shadow:0 0 30px rgba(168,85,247,0.6),0 0 60px rgba(77,159,255,0.25)}}'}}/>
                </div>
              )}

              {/* ── PREVIEW ALL QUESTIONS ── */}
              {qBV==='preview'&&(
                <div>
                  {/* Header */}
                  <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:12,flexWrap:'wrap'}}>
                    <button onClick={function(){setQBV('home');setBulkSel([])}} style={{...bg_,padding:'5px 11px',fontSize:11}}>← Back</button>
                    <div style={{flex:1}}>
                      <div style={pageTitle}>👁️ Preview All Questions</div>
                      <div style={pageSub}>{fQs.length} of {(questions||[]).length} shown</div>
                    </div>
                    <button onClick={function(){setStdPrv(function(p){return !p})}}
                      style={{...bg_,fontSize:10,padding:'5px 10px',
                        background:stdPrv?'rgba(0,229,160,0.12)':'rgba(255,255,255,0.05)',
                        border:'1px solid '+(stdPrv?'rgba(0,229,160,0.4)':'rgba(255,255,255,0.1)'),
                        color:stdPrv?'#00E5A0':'#94A3B8'}}>
                      {stdPrv?'🎓 Student ON':'🎓 Student View'}
                    </button>
                    <button onClick={expQB} style={{...bg_,fontSize:10,padding:'5px 10px'}}>⬇️ Export</button>
                    <button onClick={function(){setQBV('add')}} style={{...bp,fontSize:10,padding:'5px 12px'}}>➕ Add</button>
                  </div>
                  {/* Search */}
                  <SInput init='' onSet={setQSearch} ph='🔍 Search by question, chapter, topic…' style={{...inp,marginBottom:10,fontSize:12}}/>
                  {/* Section Tabs */}
                  <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:8}}>
                    {[
                      {k:'all',l:'All',col:'#A78BFA'},
                      {k:'Physics',l:'⚛️ Physics',col:'#60A5FA'},
                      {k:'Chemistry',l:'🧪 Chem',col:'#F472B6'},
                      {k:'Biology',l:'🧬 Bio',col:'#34D399'},
                      {k:'Math',l:'📐 Math',col:'#FBBF24'},
                      {k:'Other',l:'📚 Other',col:'#94A3B8'}
                    ].map(function(x){
                      const cnt=x.k==='all'?(questions||[]).length:x.k==='Other'?(questions||[]).filter(function(q){return !['Physics','Chemistry','Biology','Math'].includes(q.subject||'')}).length:(questions||[]).filter(function(q){return q.subject===x.k}).length
                      const isA=qSec===x.k
                      return(
                        <button key={x.k}
                          onClick={function(){setQSec(x.k);setQBioSub('all')}}
                          style={{padding:'4px 10px',borderRadius:16,
                            border:'1.5px solid '+(isA?x.col:x.col+'22'),
                            background:isA?x.col+'18':'transparent',
                            color:isA?x.col:'#64748B',
                            fontSize:10,fontWeight:isA?700:400,cursor:'pointer',transition:'all 0.2s'}}>
                          {x.l} <span style={{opacity:0.7,fontSize:9}}>({cnt})</span>
                        </button>
                      )
                    })}
                  </div>
                  {/* Bio sub-tabs */}
                  {qSec==='Biology'&&(
                    <div style={{display:'flex',gap:5,marginBottom:8,paddingLeft:4}}>
                      {[{k:'all',l:'All Biology'},{k:'Zoology',l:'🦁 Zoology'},{k:'Botany',l:'🌿 Botany'}].map(function(x){
                        const isA=qBioSub===x.k
                        return(
                          <button key={x.k} onClick={function(){setQBioSub(x.k)}}
                            style={{padding:'3px 9px',borderRadius:12,
                              border:'1px solid '+(isA?'#34D399':'rgba(52,211,153,0.2)'),
                              background:isA?'rgba(52,211,153,0.12)':'transparent',
                              color:isA?'#34D399':'#64748B',fontSize:10,cursor:'pointer'}}>
                            {x.l}
                          </button>
                        )
                      })}
                    </div>
                  )}
                  {/* Difficulty mini stats */}
                  {fQs.length>0&&(function(){
                    const tot=fQs.length
                    const ez=fQs.filter(function(q){return q.difficulty==='easy'}).length
                    const md=fQs.filter(function(q){return q.difficulty==='medium'}).length
                    const hd=fQs.filter(function(q){return q.difficulty==='hard'}).length
                    return(
                      <div style={{display:'flex',gap:8,alignItems:'center',marginBottom:10,padding:'6px 10px',background:'rgba(255,255,255,0.025)',borderRadius:8,flexWrap:'wrap'}}>
                        <span style={{color:'#475569',fontSize:10,fontWeight:600}}>Difficulty:</span>
                        {[{l:'Easy',v:ez,c:'#00C864'},{l:'Med',v:md,c:'#FFB300'},{l:'Hard',v:hd,c:'#FF4D4D'}].map(function(x){return(
                          <span key={x.l} style={{fontSize:10,color:x.c,fontWeight:600}}>{x.v} {x.l} <span style={{color:'#475569',fontWeight:400}}>({Math.round((x.v/tot)*100)}%)</span></span>
                        )})}
                      </div>
                    )
                  })()}
                  {/* Bulk bar */}
                  {bulkSel.length>0&&(
                    <div style={{display:'flex',alignItems:'center',gap:8,padding:'7px 12px',background:'rgba(255,60,60,0.07)',border:'1px solid rgba(255,60,60,0.2)',borderRadius:8,marginBottom:8,flexWrap:'wrap'}}>
                      <span style={{fontSize:11,color:'#FC8181',fontWeight:700}}>{bulkSel.length} selected</span>
                      <button onClick={blkDelQs} style={{...bd,fontSize:10,padding:'3px 12px'}}>🗑️ Delete</button>
                      <button onClick={function(){setBulkSel([])}} style={{...bg_,fontSize:10,padding:'3px 10px'}}>✕</button>
                    </div>
                  )}
                  {/* Question list */}
                  {fQs.length===0
                    ?<PageHero icon='❓' title='No Questions Found' subtitle='Try different search or section filter.'/>
                    :<div style={{display:'flex',flexDirection:'column',gap:6}}>
                      {fQs.map(function(q,qi){
                        const isChk=bulkSel.includes(q._id)
                        const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':q.subject==='Math'?'#FBBF24':'#94A3B8'
                        const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                        return(
                          <div key={q._id||qi}
                            style={{background:isChk?'rgba(77,159,255,0.05)':'rgba(255,255,255,0.02)',
                              border:'1px solid '+(isChk?'rgba(77,159,255,0.25)':'rgba(255,255,255,0.06)'),
                              borderLeft:'3px solid '+sCol+'55',
                              borderRadius:10,padding:'10px 12px'}}>
                            <div style={{display:'flex',alignItems:'flex-start',gap:8}}>
                              <input type='checkbox' checked={isChk}
                                onChange={function(e){
                                  if(e.target.checked)setBulkSel(function(p){return [...p,q._id]})
                                  else setBulkSel(function(p){return p.filter(function(x){return x!==q._id})})
                                }}
                                style={{marginTop:3,cursor:'pointer',accentColor:'#4D9FFF',flexShrink:0}}/>
                              <div style={{flex:1,minWidth:0}}>
                                <div style={{display:'flex',gap:4,marginBottom:4,flexWrap:'wrap',alignItems:'center'}}>
                                  <span style={{fontSize:9,color:'#4D9FFF',fontWeight:700,background:'rgba(77,159,255,0.1)',borderRadius:3,padding:'1px 5px'}}>#{qi+1}</span>
                                  <span style={{fontSize:9,fontWeight:600,padding:'1px 6px',borderRadius:4,background:sCol+'18',color:sCol,border:'1px solid '+sCol+'30'}}>{q.subject||'General'}</span>
                                  <span style={{fontSize:9,fontWeight:600,padding:'1px 6px',borderRadius:4,background:dCol+'18',color:dCol,border:'1px solid '+dCol+'30'}}>{q.difficulty||'?'}</span>
                                  <span style={{fontSize:9,fontWeight:600,padding:'1px 6px',borderRadius:4,background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)'}}>{q.type||'SCQ'}</span>
                                </div>
                                <div onClick={function(){setSelQId(q._id)}}
                                  style={{cursor:'pointer',fontSize:12,color:'#CBD5E1',lineHeight:1.55,marginBottom:3}}>
                                  {(q.text||'').slice(0,150)}{(q.text||'').length>150?'…':''}
                                </div>
                                {q.chapter&&<div style={{fontSize:10,color:'#475569'}}>📖 {q.chapter}{q.topic?' › '+q.topic:''}</div>}
                                {stdPrv&&(q.options||[]).length>0&&(
                                  <div style={{marginTop:7,display:'grid',gridTemplateColumns:'1fr 1fr',gap:3}}>
                                    {(q.options||[]).map(function(opt,oi){
                                      const ltr=String.fromCharCode(65+oi)
                                      const isC=String(q.correct&&q.correct[0])===String(oi)||q.correctAnswer===ltr
                                      return(
                                        <div key={oi} style={{
                                          padding:'4px 8px',borderRadius:5,fontSize:10,
                                          border:'1px solid '+(isC?'rgba(0,200,100,0.4)':'rgba(255,255,255,0.06)'),
                                          background:isC?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)',
                                          color:isC?'#00C864':'#94A3B8'
                                        }}>
                                          <span style={{fontWeight:700,marginRight:4,color:isC?'#00C864':'#4D9FFF'}}>{ltr}.</span>{opt.slice(0,30)}{opt.length>30?'…':''}{isC&&' ✓'}
                                        </div>
                                      )
                                    })}
                                  </div>
                                )}
                              </div>
                              <div style={{display:'flex',flexDirection:'column',gap:3,flexShrink:0}}>
                                <button onClick={function(){setSelQId(q._id)}} style={{...bg_,padding:'3px 6px',fontSize:9}} title='Preview'>👁️</button>
                                <button onClick={function(){
                                  const ltrs=['A','B','C','D']
                                  const cIdx=q.correct&&q.correct[0]!==undefined?q.correct[0]:ltrs.indexOf(q.correctAnswer||'A')
                                  setEditQD(Object.assign({},q,{correctLetter:ltrs[cIdx>=0?cIdx:0]||'A'}))
                                }} style={{...bg_,padding:'3px 6px',fontSize:9}} title='Edit'>✏️</button>
                                <button onClick={function(){dupQF(q)}} style={{...bg_,padding:'3px 6px',fontSize:9}} title='Duplicate'>📋</button>
                                <button onClick={async function(){
                                  if(confirm('Delete this question?')){
                                    const r=await fetch(API+'/api/questions/'+q._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
                                    if(r.ok){setQuestions(function(p){return p.filter(function(x){return x._id!==q._id})});T('Deleted.')}
                                    else T('Delete failed','e')
                                  }
                                }} style={{...bd,padding:'3px 6px',fontSize:9}} title='Delete'>🗑️</button>
                              </div>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  }
                </div>
              )}

              {/* ── AI GENERATE MODAL ── */}
              {aiGO&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                  <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:22,width:'100%',maxWidth:420,maxHeight:'90vh',overflowY:'auto',boxShadow:'0 20px 60px rgba(0,0,0,0.6)'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div>
                        <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>🤖 AI Question Generator</div>
                        <div style={{fontSize:10,color:'#64748B',marginTop:2}}>Step {aiGStep} of 4 · Subject: {aiGSub}</div>
                      </div>
                      <button onClick={function(){setAiGO(false);setAiGStep(1);setAiGResult([])}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                    </div>
                    <div style={{display:'flex',gap:3,marginBottom:16}}>
                      {[1,2,3,4].map(function(s){return(
                        <div key={s} style={{flex:1,height:3,borderRadius:2,background:s<=aiGStep?'linear-gradient(90deg,#4D9FFF,#A855F7)':'rgba(255,255,255,0.08)',transition:'all 0.3s'}}/>
                      )})}
                    </div>
                    {aiGStep===1&&(
                      <div>
                        <div style={{fontSize:12,fontWeight:700,color:'#CBD5E1',marginBottom:12}}>1️⃣ Select Subject</div>
                        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                          {[{v:'Physics',e:'⚛️',c:'#60A5FA'},{v:'Chemistry',e:'🧪',c:'#F472B6'},{v:'Biology',e:'🧬',c:'#34D399'},{v:'Math',e:'📐',c:'#FBBF24'}].map(function(x){return(
                            <div key={x.v} onClick={function(){setAiGSub(x.v);setAiGStep(2)}}
                              style={{padding:'12px 8px',borderRadius:10,
                                border:'1.5px solid '+(aiGSub===x.v?x.c:'rgba(255,255,255,0.07)'),
                                background:aiGSub===x.v?x.c+'15':'rgba(255,255,255,0.02)',
                                cursor:'pointer',textAlign:'center',transition:'all 0.2s'}}>
                              <div style={{fontSize:22,marginBottom:3}}>{x.e}</div>
                              <div style={{fontSize:11,fontWeight:700,color:'#CBD5E1'}}>{x.v}</div>
                            </div>
                          )})}
                        </div>
                      </div>
                    )}
                    {aiGStep===2&&(
                      <div>
                        <div style={{fontSize:12,fontWeight:700,color:'#CBD5E1',marginBottom:10}}>2️⃣ Chapter</div>
                        <div style={{marginBottom:8}}>
                          <select onChange={function(e){if(e.target.value){aiChR.current=e.target.value}}} style={{...inp,width:'100%',marginBottom:6}}>
                            <option value=''>— Select common chapter —</option>
                            {(aiGSub==='Physics'?['Electrostatics','Magnetism','Optics','Thermodynamics','Mechanics','Modern Physics','Waves','Current Electricity']:
                              aiGSub==='Chemistry'?['Organic Chemistry','Periodic Table','Chemical Bonding','Thermodynamics','Electrochemistry','Coordination Compounds']:
                              aiGSub==='Biology'?['Cell Biology','Genetics','Ecology','Human Physiology','Plant Kingdom','Animal Kingdom','Evolution']:
                              ['Calculus','Algebra','Trigonometry','Coordinate Geometry','Statistics']).map(function(c){return(
                              <option key={c} value={c}>{c}</option>
                            )})}
                          </select>
                          <input placeholder='Or type custom chapter…' onChange={function(e){aiChR.current=e.target.value}} style={{...inp,width:'100%',fontSize:11}}/>
                        </div>
                        <div style={{display:'flex',gap:8}}>
                          <button onClick={function(){setAiGStep(1)}} style={{...bg_,flex:1,fontSize:11}}>← Back</button>
                          <button onClick={function(){if(aiChR.current)setAiGStep(3);else T('Chapter fill karo','e')}} style={{...bp,flex:2,fontSize:11}}>Next →</button>
                        </div>
                      </div>
                    )}
                    {aiGStep===3&&(
                      <div>
                        <div style={{fontSize:12,fontWeight:700,color:'#CBD5E1',marginBottom:10}}>3️⃣ Topic</div>
                        <input placeholder='Type topic… (e.g. Coulombs Law, Mitosis)' onChange={function(e){aiTopR.current=e.target.value}} style={{...inp,width:'100%',marginBottom:12,fontSize:11}}/>
                        <div style={{display:'flex',gap:8}}>
                          <button onClick={function(){setAiGStep(2)}} style={{...bg_,flex:1,fontSize:11}}>← Back</button>
                          <button onClick={function(){if(aiTopR.current)setAiGStep(4);else T('Topic fill karo','e')}} style={{...bp,flex:2,fontSize:11}}>Next →</button>
                        </div>
                      </div>
                    )}
                    {aiGStep===4&&(
                      <div>
                        <div style={{fontSize:12,fontWeight:700,color:'#CBD5E1',marginBottom:10}}>4️⃣ Configure</div>
                        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:12}}>
                          <div>
                            <label style={lbl}>Count</label>
                            <input
                              type='number' min='1' max='30'
                              defaultValue={aiGCnt}
                              onChange={function(e){setAiGCnt(e.target.value)}}
                              placeholder='e.g. 10'
                              style={{...inp,width:'100%'}}/>
                            <div style={{fontSize:9,color:'#475569',marginTop:2}}>Type any number (1–30)</div>
                          </div>
                          <div>
                            <label style={lbl}>Difficulty</label>
                            <select value={aiGDiff} onChange={function(e){setAiGDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                              <option value='easy'>🟢 Easy</option>
                              <option value='medium'>🟡 Medium</option>
                              <option value='hard'>🔴 Hard</option>
                            </select>
                          </div>
                        </div>
                        <div style={{padding:'8px 10px',background:'rgba(77,159,255,0.06)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:8,fontSize:10,color:'#94A3B8',marginBottom:12,lineHeight:1.6}}>
                          <span style={{color:'#4D9FFF',fontWeight:700}}>{aiGCnt}</span> {aiGDiff} {aiGSub} questions
                          <br/>Ch: <span style={{color:'#4D9FFF'}}>{aiChR.current}</span> · Topic: <span style={{color:'#4D9FFF'}}>{aiTopR.current}</span>
                        </div>
                        <div style={{display:'flex',gap:8}}>
                          <button onClick={function(){setAiGStep(3)}} style={{...bg_,flex:1,fontSize:11}}>← Back</button>
                          <button onClick={aiGF} disabled={aiGLoading} style={{...bp,flex:2,fontSize:11,opacity:aiGLoading?0.7:1}}>
                            {aiGLoading?'⟳ Generating…':'🤖 Generate Questions'}
                          </button>
                        </div>
                      </div>
                    )}
                    {aiGResult.length>0&&(
                      <div style={{marginTop:14}}>
                        <div style={{fontSize:11,fontWeight:700,color:'#00C864',marginBottom:8}}>✅ {aiGResult.length} Questions Generated!</div>
                        <div style={{maxHeight:120,overflowY:'auto',marginBottom:10,display:'flex',flexDirection:'column',gap:4}}>
                          {aiGResult.map(function(q,i){return(
                            <div key={i} style={{padding:'5px 9px',background:'rgba(255,255,255,0.03)',borderRadius:6,fontSize:10,color:'#CBD5E1'}}>
                              Q{i+1}: {(q.text||'').slice(0,70)}…
                            </div>
                          )})}
                        </div>
                        <button onClick={saveAiQs} style={{...bp,width:'100%',fontSize:11}}>💾 Save All {aiGResult.length} to Question Bank</button>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* ── QUESTION PREVIEW MODAL ── */}
              {selQId&&(function(){
                const qi=(questions||[]).findIndex(function(q){return q._id===selQId})
                const q=(questions||[])[qi]
                if(!q)return null
                const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':'#A78BFA'
                const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.9)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                    <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:20,width:'100%',maxWidth:500,maxHeight:'90vh',overflowY:'auto'}}>
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12}}>
                        <div>
                          <div style={{display:'flex',gap:4,flexWrap:'wrap',marginBottom:4}}>
                            <span style={{fontSize:9,fontWeight:600,padding:'2px 7px',borderRadius:4,background:sCol+'18',color:sCol,border:'1px solid '+sCol+'30'}}>{q.subject||'General'}</span>
                            <span style={{fontSize:9,fontWeight:600,padding:'2px 7px',borderRadius:4,background:dCol+'18',color:dCol,border:'1px solid '+dCol+'30'}}>{q.difficulty||'?'}</span>
                            <span style={{fontSize:9,fontWeight:600,padding:'2px 7px',borderRadius:4,background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)'}}>{q.type||'SCQ'}</span>
                          </div>
                          <div style={{fontSize:10,color:'#475569'}}>Q{qi+1} of {(questions||[]).length}</div>
                        </div>
                        <button onClick={function(){setSelQId(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                      </div>
                      <div style={{fontSize:13,color:'#E2E8F0',lineHeight:1.7,marginBottom:12,padding:'11px 13px',background:'rgba(255,255,255,0.03)',borderRadius:10,border:'1px solid rgba(255,255,255,0.06)'}}>{q.text}</div>
                      {q.hindiText&&<div style={{fontSize:11,color:'#94A3B8',marginBottom:10,fontStyle:'italic',padding:'6px 11px',background:'rgba(255,255,255,0.02)',borderRadius:8}}>{q.hindiText}</div>}
                      {(q.options||[]).length>0&&(
                        <div style={{display:'flex',flexDirection:'column',gap:5,marginBottom:10}}>
                          {(q.options||[]).map(function(opt,oi){
                            const ltr=String.fromCharCode(65+oi)
                            const isC=String(q.correct&&q.correct[0])===String(oi)||q.correctAnswer===ltr
                            return(
                              <div key={oi} style={{padding:'7px 11px',borderRadius:7,border:'1px solid '+(isC?'rgba(0,200,100,0.4)':'rgba(255,255,255,0.07)'),background:isC?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)'}}>
                                <span style={{fontWeight:700,color:isC?'#00C864':'#4D9FFF',marginRight:8}}>{ltr}.</span>
                                <span style={{fontSize:12,color:isC?'#E2E8F0':'#94A3B8'}}>{opt}</span>
                                {isC&&<span style={{marginLeft:8,fontSize:10,color:'#00C864',fontWeight:700}}>✓ Correct</span>}
                              </div>
                            )
                          })}
                        </div>
                      )}
                      {(q.chapter||q.topic||q.explanation)&&(
                        <div style={{fontSize:11,color:'#64748B',marginBottom:12,lineHeight:1.6}}>
                          {q.chapter&&<div>📖 {q.chapter}{q.topic?' › '+q.topic:''}</div>}
                          {q.explanation&&<div style={{color:'#94A3B8',marginTop:4}}>💡 {q.explanation}</div>}
                        </div>
                      )}
                      <div style={{display:'flex',gap:7}}>
                        <button onClick={function(){if(qi>0)setSelQId((questions||[])[qi-1]._id)}} disabled={qi===0} style={{...bg_,flex:1,opacity:qi===0?0.35:1,fontSize:11}}>← Prev</button>
                        <button onClick={function(){
                          const ltrs=['A','B','C','D']
                          const cIdx=q.correct&&q.correct[0]!==undefined?q.correct[0]:ltrs.indexOf(q.correctAnswer||'A')
                          setEditQD(Object.assign({},q,{correctLetter:ltrs[cIdx>=0?cIdx:0]||'A'}))
                          setSelQId(null)
                        }} style={{...bp,flex:1,fontSize:11}}>✏️ Edit</button>
                        <button onClick={function(){if(qi<(questions||[]).length-1)setSelQId((questions||[])[qi+1]._id)}} disabled={qi>=(questions||[]).length-1} style={{...bg_,flex:1,opacity:qi>=(questions||[]).length-1?0.35:1,fontSize:11}}>Next →</button>
                      </div>
                    </div>
                  </div>
                )
              })()}

              {/* ── EDIT MODAL ── */}
              {editQD&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.9)',zIndex:1001,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                  <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(255,184,0,0.25)',borderRadius:20,padding:20,width:'100%',maxWidth:490,maxHeight:'90vh',overflowY:'auto'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div style={{fontSize:13,fontWeight:800,color:'#E2E8F0'}}>✏️ Edit Question</div>
                      <button onClick={function(){setEditQD(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                    </div>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Question Text *</label>
                        <textarea value={editQD.text||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{text:e.target.value})})}} rows={3} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Hindi Text <span style={{color:'#475569',fontSize:9}}>(optional)</span></label>
                        <textarea value={editQD.hindiText||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{hindiText:e.target.value})})}} rows={2} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                      <div>
                        <label style={lbl}>Subject</label>
                        <select value={editQD.subject||'Physics'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{subject:e.target.value})})}} style={{...inp,width:'100%'}}>
                          {['Physics','Chemistry','Biology','Math','Other'].map(function(s){return <option key={s} value={s}>{s}</option>})}
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>Difficulty</label>
                        <select value={editQD.difficulty||'medium'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{difficulty:e.target.value})})}} style={{...inp,width:'100%'}}>
                          {['easy','medium','hard'].map(function(d){return <option key={d} value={d}>{d}</option>})}
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>Chapter</label>
                        <input value={editQD.chapter||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{chapter:e.target.value})})}} style={{...inp,width:'100%'}}/>
                      </div>
                      <div>
                        <label style={lbl}>Topic</label>
                        <input value={editQD.topic||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{topic:e.target.value})})}} style={{...inp,width:'100%'}}/>
                      </div>
                      {/* Options editing */}
                      {(editQD.options||[]).length>0&&(editQD.options||[]).map(function(opt,oi){return(
                        <div key={oi}>
                          <label style={lbl}>Option {String.fromCharCode(65+oi)}</label>
                          <input value={opt} onChange={function(e){
                            const opts=[...(editQD.options||[])]
                            opts[oi]=e.target.value
                            setEditQD(function(p){return Object.assign({},p,{options:opts})})
                          }} style={{...inp,width:'100%'}}/>
                        </div>
                      )})}
                      {/* If no options, show 4 blank fields */}
                      {(editQD.options||[]).length===0&&['A','B','C','D'].map(function(ltr,oi){return(
                        <div key={oi}>
                          <label style={lbl}>Option {ltr}</label>
                          <input value='' onChange={function(e){
                            const opts=['','','','']
                            opts[oi]=e.target.value
                            setEditQD(function(p){return Object.assign({},p,{options:opts})})
                          }} placeholder={'Option '+ltr+'…'} style={{...inp,width:'100%'}}/>
                        </div>
                      )})}
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>✅ Correct Answer</label>
                        <select value={editQD.correctLetter||'A'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{correctLetter:e.target.value})})}} style={{...inp,width:'100%'}}>
                          <option value='A'>Option A</option>
                          <option value='B'>Option B</option>
                          <option value='C'>Option C</option>
                          <option value='D'>Option D</option>
                        </select>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Explanation</label>
                        <textarea value={editQD.explanation||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{explanation:e.target.value})})}} rows={2} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={function(){setEditQD(null)}} style={{...bg_,flex:1,fontSize:11}}>Cancel</button>
                      <button onClick={function(){editQF(editQD._id,editQD)}} disabled={savingEQ} style={{...bp,flex:2,fontSize:11,opacity:savingEQ?0.7:1}}>
                        {savingEQ?'⟳ Saving…':'💾 Save Changes'}
                      </button>
                    </div>
                  </div>
                </div>
              )}

            </div>
          )}`

t = t.slice(0, si) + NEW_QB + '\n\n          ' + SMART_COMMENT + t.slice(t.indexOf(SMART_COMMENT, si) + SMART_COMMENT.length)
fs.writeFileSync(FILE, t)
console.log('✅ Fix 5: QB JSX completely replaced')
console.log('')
console.log('✅ ALL FRONTEND FIXES DONE!')
