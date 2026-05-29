#!/bin/bash
# ═══════════════════════════════════════════════════════
# ProveRank — Question Bank Redesign (NO PYTHON — Node only)
# Run: bash qbank_redesign.sh  (from ~/workspace)
# ═══════════════════════════════════════════════════════
set -e
FILE="frontend/app/admin/x7k2p/page.tsx"
BAK="frontend/app/admin/x7k2p/page.tsx.bak_qb_$(date +%s)"
cp "$FILE" "$BAK"
echo "✅ Backup saved: $BAK"

node << 'NODEEOF'
const fs = require('fs')
const FILE = 'frontend/app/admin/x7k2p/page.tsx'
let txt = fs.readFileSync(FILE, 'utf8')

// ══════════════════════════════════════════
// STEP 1 — Add new QB states after qPreview
// ══════════════════════════════════════════
const S1_OLD = `  const [qPreview,setQPreview]=useState(false)`
const S1_NEW = `  const [qPreview,setQPreview]=useState(false)
  const [qBV,setQBV]=useState('home')
  const [qSec,setQSec]=useState('all')
  const [qBioSub,setQBioSub]=useState('all')
  const [bulkSel,setBulkSel]=useState([])
  const [selQId,setSelQId]=useState(null)
  const [editQD,setEditQD]=useState(null)
  const [savingEQ,setSavingEQ]=useState(false)
  const [stdPrv,setStdPrv]=useState(false)
  const [aiGO,setAiGO]=useState(false)
  const [aiGStep,setAiGStep]=useState(1)
  const [aiGSub,setAiGSub]=useState('Physics')
  const [aiGCnt,setAiGCnt]=useState('10')
  const [aiGDiff,setAiGDiff]=useState('medium')
  const [aiGLoading,setAiGLoading]=useState(false)
  const [aiGResult,setAiGResult]=useState([])
  const aiChR=useRef('');const aiTopR=useRef('')
  const qImageR=useRef('')`

if(!txt.includes(S1_OLD)){console.error('❌ STEP1 anchor missing');process.exit(1)}
txt = txt.replace(S1_OLD, S1_NEW)
console.log('✅ Step 1: QB states added')

// ══════════════════════════════════════════
// STEP 2 — Update fQs filter
// ══════════════════════════════════════════
const S2_OLD = `  const fQs=(questions||[]).filter(q=>{
    const mq=!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase())
    const ms=qSubjFilter==='all'||q.subject===qSubjFilter
    return mq&&ms
  })`
const S2_NEW = `  const fQs=(questions||[]).filter(q=>{
    const mq=!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase())||q.chapter?.toLowerCase().includes(qSearch.toLowerCase())||q.topic?.toLowerCase().includes(qSearch.toLowerCase())
    const ms=qSubjFilter==='all'||q.subject===qSubjFilter
    const otherSubjs=['Physics','Chemistry','Biology','Math']
    const sec=qSec==='all'||(qSec==='Other'?!otherSubjs.includes(q.subject||''):q.subject===qSec)
    const bio=qSec!=='Biology'||qBioSub==='all'||(q.chapter?.toLowerCase().includes(qBioSub.toLowerCase())||q.topic?.toLowerCase().includes(qBioSub.toLowerCase()))
    return mq&&ms&&sec&&bio
  })`

if(!txt.includes(S2_OLD)){console.error('❌ STEP2 anchor missing');process.exit(1)}
txt = txt.replace(S2_OLD, S2_NEW)
console.log('✅ Step 2: fQs filter updated')

// ══════════════════════════════════════════
// STEP 3 — Add QB functions before addQ
// ══════════════════════════════════════════
const S3_ANCHOR = `  const addQ=useCallback(async()=>{`
const S3_INSERT = `  const editQF=async(id,data)=>{
    setSavingEQ(true)
    try{
      const r=await fetch(API+'/api/questions/'+id,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(data)})
      if(r.ok){T('Question updated!');setEditQD(null);setTimeout(()=>fetchAll(),400)}
      else{const e=await r.json().catch(()=>({}));T(e.message||'Update failed','e')}
    }catch(ex){T(ex.message,'e')}
    setSavingEQ(false)
  }
  const dupQF=async(q)=>{
    const d={text:'[COPY] '+q.text,subject:q.subject,chapter:q.chapter,topic:q.topic,difficulty:q.difficulty,type:q.type,options:q.options,correctAnswer:q.correctAnswer||String(q.correct?.[0]??'')}
    try{
      const r=await fetch(API+'/api/questions',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(d)})
      if(r.ok){T('Question duplicated!');setTimeout(()=>fetchAll(),400)}
      else T('Duplicate failed','e')
    }catch{T('Network error','e')}
  }
  const aiGF=async()=>{
    const ch=aiChR.current,tp=aiTopR.current
    if(!ch||!tp){T('Chapter aur Topic fill karo','e');return}
    setAiGLoading(true)
    try{
      const r=await fetch(API+'/api/questions/generate',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({subject:aiGSub,chapter:ch,topic:tp,count:parseInt(aiGCnt)||10,difficulty:aiGDiff})})
      if(r.ok){const d=await r.json();const qs=d.questions||d.generated||[];setAiGResult(qs);T(qs.length+' questions generated!')}
      else T('AI generation failed','e')
    }catch{T('Network error','e')}
    setAiGLoading(false)
  }
  const saveAiQs=async()=>{
    if(!aiGResult.length)return
    try{
      const r=await fetch(API+'/api/questions/bulk-save',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({questions:aiGResult})})
      if(r.ok){T(aiGResult.length+' questions saved!');setAiGResult([]);setAiGO(false);setTimeout(()=>fetchAll(),400)}
      else T('Save failed','e')
    }catch{T('Network error','e')}
  }
  const blkDelQs=async()=>{
    if(!bulkSel.length||!confirm('Delete '+bulkSel.length+' selected questions?'))return
    for(const id of bulkSel){await fetch(API+'/api/questions/'+id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})}
    setQuestions(p=>p.filter(q=>!bulkSel.includes(q._id)));setBulkSel([]);T('Bulk delete done.')
  }
  const expQB=()=>{
    const rows=(questions||[]).map(q=>[q._id,'"'+String(q.text||'').replace(/"/g,"''")+'"',q.subject||'',q.chapter||'',q.difficulty||'',q.type||''].join(','))
    const blob=new Blob(['ID,Text,Subject,Chapter,Difficulty,Type\n'+rows.join('\n')],{type:'text/csv'})
    const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='question_bank.csv';a.click()
  }
  `

if(!txt.includes(S3_ANCHOR)){console.error('❌ STEP3 anchor missing');process.exit(1)}
txt = txt.replace(S3_ANCHOR, S3_INSERT + S3_ANCHOR)
console.log('✅ Step 3: QB functions added')

// ══════════════════════════════════════════
// STEP 4 — Replace full questions tab JSX
// ══════════════════════════════════════════
const QB_START = `          {tab==='questions'&&(\n            <div>`
const QB_END   = `          )}\n\n          {/* ══ SMART GENERATOR ══ */}`
const si = txt.indexOf(QB_START)
const ei = txt.indexOf(QB_END, si)
if(si===-1||ei===-1){console.error('❌ STEP4 QB JSX block not found');process.exit(1)}

const NEW_QB = `          {tab==='questions'&&(
            <div style={{position:'relative'}}>

              {qBV==='home'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:20,flexWrap:'wrap',gap:10}}>
                    <div><div style={pageTitle}>📚 Question Bank</div><div style={pageSub}>{(questions||[]).length} questions · NEET Pattern Ready</div></div>
                    <button onClick={expQB} style={{...bg_,fontSize:11}}>⬇️ Export CSV</button>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:8,marginBottom:24}}>
                    {[{l:'Total',v:(questions||[]).length,c:'#A78BFA'},{l:'Physics',v:(questions||[]).filter(q=>q.subject==='Physics').length,c:'#60A5FA'},{l:'Chemistry',v:(questions||[]).filter(q=>q.subject==='Chemistry').length,c:'#F472B6'},{l:'Biology',v:(questions||[]).filter(q=>q.subject==='Biology').length,c:'#34D399'},{l:'Math',v:(questions||[]).filter(q=>q.subject==='Math').length,c:'#FBBF24'}].map(({l,v,c:col})=>(
                      <div key={l} style={{background:'rgba(255,255,255,0.04)',border:'1px solid '+col+'30',borderRadius:10,padding:'10px 6px',textAlign:'center'}}>
                        <div style={{fontSize:18,fontWeight:800,color:col}}>{v}</div>
                        <div style={{fontSize:9,color:'#64748b',marginTop:2}}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:20,maxWidth:680,margin:'0 auto 28px'}}>
                    <div onClick={()=>setQBV('add')} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(77,159,255,0.12),rgba(160,80,255,0.08))',border:'1.5px solid rgba(77,159,255,0.3)',borderRadius:20,padding:'28px 18px',textAlign:'center'}}>
                      <div style={{fontSize:40,marginBottom:10,filter:'drop-shadow(0 0 10px rgba(77,159,255,0.5))'}}>➕</div>
                      <div style={{fontSize:16,fontWeight:800,color:'#E2E8F0',marginBottom:6}}>Add Question</div>
                      <div style={{fontSize:11,color:'#64748B',lineHeight:1.6,marginBottom:16}}>Manually add or AI auto-generate</div>
                      <div style={{display:'inline-block',background:'rgba(77,159,255,0.15)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:8,padding:'7px 16px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>Add Questions →</div>
                    </div>
                    <div onClick={()=>{setQBV('preview');setQSec('all')}} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(0,229,160,0.08),rgba(160,80,255,0.06))',border:'1.5px solid rgba(0,229,160,0.25)',borderRadius:20,padding:'28px 18px',textAlign:'center'}}>
                      <div style={{fontSize:40,marginBottom:10,filter:'drop-shadow(0 0 10px rgba(0,229,160,0.45))'}}>👁️</div>
                      <div style={{fontSize:16,fontWeight:800,color:'#E2E8F0',marginBottom:6}}>Preview All Questions</div>
                      <div style={{fontSize:11,color:'#64748B',lineHeight:1.6,marginBottom:16}}>Browse, filter, edit section-wise</div>
                      <div style={{display:'inline-block',background:'rgba(0,229,160,0.12)',border:'1px solid rgba(0,229,160,0.35)',borderRadius:8,padding:'7px 16px',fontSize:11,color:'#00E5A0',fontWeight:700}}>Preview Bank →</div>
                    </div>
                  </div>
                  {(questions||[]).length>0&&(()=>{
                    const all=questions||[];const tot=all.length||1
                    const ez=all.filter(q=>q.difficulty==='easy').length
                    const md=all.filter(q=>q.difficulty==='medium').length
                    const hd=all.filter(q=>q.difficulty==='hard').length
                    return(
                      <div style={{background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.07)',borderRadius:14,padding:'14px 16px'}}>
                        <div style={{fontSize:12,color:'#94A3B8',fontWeight:600,marginBottom:10}}>📊 Difficulty Distribution</div>
                        {[{l:'Easy',v:ez,col:'#00C864'},{l:'Medium',v:md,col:'#FFB300'},{l:'Hard',v:hd,col:'#FF4D4D'}].map(({l,v,col})=>{
                          const pct=Math.round((v/tot)*100)
                          return(
                            <div key={l} style={{display:'flex',alignItems:'center',gap:8,marginBottom:7}}>
                              <div style={{width:52,fontSize:11,color:col,fontWeight:600}}>{l}</div>
                              <div style={{flex:1,height:5,background:'rgba(255,255,255,0.06)',borderRadius:3}}><div style={{width:pct+'%',height:'100%',background:col,borderRadius:3}}/></div>
                              <div style={{width:52,fontSize:10,color:'#475569',textAlign:'right'}}>{v} ({pct}%)</div>
                            </div>
                          )
                        })}
                      </div>
                    )
                  })()}
                </div>
              )}

              {qBV==='add'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:20}}>
                    <button onClick={()=>setQBV('home')} style={{...bg_,padding:'6px 14px',fontSize:12}}>← Back</button>
                    <div><div style={pageTitle}>➕ Add Question to Bank</div><div style={pageSub}>Fill all details — auto-saves instantly</div></div>
                  </div>
                  <div style={cs}>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                      <div style={{gridColumn:'1/-1'}}><label style={lbl}>📝 Question Text (English) *</label><STextarea init='' onSet={v=>{qTxtR.current=v}} ph='Type the full question text here…' rows={3} style={{...inp,resize:'vertical'}}/></div>
                      <div style={{gridColumn:'1/-1'}}><label style={lbl}>🇮🇳 Hindi Text (optional)</label><STextarea init='' onSet={v=>{qHindiR.current=v}} ph='हिंदी में प्रश्न…' rows={2} style={{...inp,resize:'vertical'}}/></div>
                      <div><label style={lbl}>📚 Subject *</label><SSelect val={qSubj} onChange={setQSubj} opts={[{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'},{v:'Math',l:'📐 Math'},{v:'Other',l:'📖 Other'}]} style={{...inp}}/></div>
                      <div><label style={lbl}>🔢 Question Type</label><SSelect val={qType} onChange={setQType} opts={[{v:'SCQ',l:'SCQ — Single Correct'},{v:'MSQ',l:'MSQ — Multiple Correct'},{v:'Integer',l:'Integer Type'}]} style={{...inp}}/></div>
                      <div><label style={lbl}>🎯 Difficulty</label><SSelect val={qDiff} onChange={setQDiff} opts={[{v:'easy',l:'🟢 Easy'},{v:'medium',l:'🟡 Medium'},{v:'hard',l:'🔴 Hard'}]} style={{...inp}}/></div>
                      <div><label style={lbl}>✅ Correct Answer</label><SSelect val={qAns} onChange={setQAns} opts={[{v:'A',l:'Option A'},{v:'B',l:'Option B'},{v:'C',l:'Option C'},{v:'D',l:'Option D'}]} style={{...inp}}/></div>
                      <div><label style={lbl}>📖 Chapter</label><SInput init='' onSet={v=>{qChapR.current=v}} ph='e.g. Electrostatics' style={inp}/></div>
                      <div><label style={lbl}>📌 Topic</label><SInput init='' onSet={v=>{qTopicR.current=v}} ph='e.g. Coulombs Law' style={inp}/></div>
                      {['SCQ','MSQ'].includes(qType)&&<>
                        <div><label style={lbl}>Option A</label><SInput init='' onSet={v=>{qA.current=v}} ph='Option A…' style={inp}/></div>
                        <div><label style={lbl}>Option B</label><SInput init='' onSet={v=>{qB.current=v}} ph='Option B…' style={inp}/></div>
                        <div><label style={lbl}>Option C</label><SInput init='' onSet={v=>{qC.current=v}} ph='Option C…' style={inp}/></div>
                        <div><label style={lbl}>Option D</label><SInput init='' onSet={v=>{qD.current=v}} ph='Option D…' style={inp}/></div>
                      </>}
                      <div style={{gridColumn:'1/-1'}}><label style={lbl}>💡 Explanation (optional)</label><STextarea init='' onSet={v=>{qExpR.current=v}} ph='Explain the correct answer…' rows={2} style={{...inp,resize:'vertical'}}/></div>
                      <div><label style={lbl}>🖼️ Image URL (optional)</label><SInput init='' onSet={v=>{qImageR.current=v}} ph='https://imgur.com/…' style={inp}/></div>
                    </div>
                    <div style={{display:'flex',gap:10,marginTop:16,flexWrap:'wrap'}}>
                      <button onClick={addQ} disabled={savingQ} style={{...bp,flex:2,opacity:savingQ?0.7:1}}>{savingQ?'⟳ Saving…':'✅ Add to Question Bank'}</button>
                      <button onClick={()=>{qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current='';qTopicR.current='';qExpR.current='';qImageR.current='';T('Form cleared')}} style={{...bg_}}>🗑️ Clear</button>
                    </div>
                  </div>
                  <div onClick={()=>{setAiGO(true);setAiGStep(1)}} title="AI Auto-Generate" style={{position:'fixed',bottom:90,right:16,width:62,height:62,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#A855F7)',boxShadow:'0 0 22px rgba(168,85,247,0.55)',cursor:'pointer',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',zIndex:990,border:'2px solid rgba(255,255,255,0.15)'}}>
                    <div style={{fontSize:18}}>🤖</div>
                    <div style={{fontSize:7,color:'#fff',fontWeight:700}}>AI GEN</div>
                  </div>
                </div>
              )}

              {qBV==='preview'&&(
                <div>
                  <div style={{marginBottom:14}}>
                    <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:12,flexWrap:'wrap'}}>
                      <button onClick={()=>{setQBV('home');setBulkSel([])}} style={{...bg_,padding:'6px 12px',fontSize:12}}>← Back</button>
                      <div style={{flex:1}}><div style={pageTitle}>👁️ Preview All Questions</div><div style={pageSub}>{fQs.length} of {(questions||[]).length} shown</div></div>
                      <button onClick={()=>setStdPrv(p=>!p)} style={{...bg_,fontSize:11,background:stdPrv?'rgba(0,229,160,0.12)':undefined}}>{stdPrv?'🎓 Student ON':'🎓 Student View'}</button>
                      <button onClick={expQB} style={{...bg_,fontSize:11}}>⬇️ CSV</button>
                      <button onClick={()=>setQBV('add')} style={{...bp,fontSize:11}}>➕ Add</button>
                    </div>
                    <SInput init='' onSet={setQSearch} ph='🔍 Search questions, chapters, topics…' style={{...inp,marginBottom:10}}/>
                    <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                      {[{k:'all',l:'All',col:'#A78BFA'},{k:'Physics',l:'⚛️ Physics',col:'#60A5FA'},{k:'Chemistry',l:'🧪 Chem',col:'#F472B6'},{k:'Biology',l:'🧬 Bio',col:'#34D399'},{k:'Math',l:'📐 Math',col:'#FBBF24'},{k:'Other',l:'📚 Other',col:'#94A3B8'}].map(({k,l,col})=>{
                        const cnt=k==='all'?(questions||[]).length:k==='Other'?(questions||[]).filter(q=>!['Physics','Chemistry','Biology','Math'].includes(q.subject||'')).length:(questions||[]).filter(q=>q.subject===k).length
                        const isA=qSec===k
                        return(<button key={k} onClick={()=>{setQSec(k);setQBioSub('all')}} style={{padding:'5px 11px',borderRadius:20,border:'1.5px solid '+(isA?col:col+'28'),background:isA?col+'18':'transparent',color:isA?col:'#64748B',fontSize:11,fontWeight:isA?700:400,cursor:'pointer'}}>{l} ({cnt})</button>)
                      })}
                    </div>
                    {qSec==='Biology'&&(
                      <div style={{display:'flex',gap:6,marginTop:8,paddingLeft:6}}>
                        {[{k:'all',l:'All Bio'},{k:'Zoology',l:'🦁 Zoology'},{k:'Botany',l:'🌿 Botany'}].map(({k,l})=>{
                          const isA=qBioSub===k
                          return(<button key={k} onClick={()=>setQBioSub(k)} style={{padding:'4px 10px',borderRadius:14,border:'1px solid '+(isA?'#34D399':'rgba(52,211,153,0.2)'),background:isA?'rgba(52,211,153,0.15)':'transparent',color:isA?'#34D399':'#64748B',fontSize:10,cursor:'pointer'}}>{l}</button>)
                        })}
                      </div>
                    )}
                    {fQs.length>0&&(()=>{
                      const tot=fQs.length
                      const ez=fQs.filter(q=>q.difficulty==='easy').length
                      const md=fQs.filter(q=>q.difficulty==='medium').length
                      const hd=fQs.filter(q=>q.difficulty==='hard').length
                      return(<div style={{display:'flex',gap:10,alignItems:'center',marginTop:8,padding:'7px 12px',background:'rgba(255,255,255,0.03)',borderRadius:8,flexWrap:'wrap'}}>
                        <span style={{color:'#64748B',fontSize:10,fontWeight:600}}>Difficulty:</span>
                        {[{l:'Easy',v:ez,col:'#00C864'},{l:'Med',v:md,col:'#FFB300'},{l:'Hard',v:hd,col:'#FF4D4D'}].map(({l,v,col})=>(
                          <span key={l} style={{fontSize:11}}><span style={{color:col,fontWeight:700}}>{v} {l}</span><span style={{color:'#475569',fontSize:10}}> ({Math.round((v/tot)*100)}%)</span></span>
                        ))}
                      </div>)
                    })()}
                  </div>
                  {bulkSel.length>0&&(
                    <div style={{display:'flex',alignItems:'center',gap:10,padding:'9px 14px',background:'rgba(255,75,75,0.08)',border:'1px solid rgba(255,75,75,0.25)',borderRadius:10,marginBottom:12,flexWrap:'wrap'}}>
                      <span style={{fontSize:12,color:'#FC8181',fontWeight:700}}>{bulkSel.length} selected</span>
                      <button onClick={blkDelQs} style={{...bd,fontSize:11,padding:'4px 14px'}}>🗑️ Delete Selected</button>
                      <button onClick={()=>setBulkSel([])} style={{...bg_,fontSize:11}}>✕ Clear</button>
                    </div>
                  )}
                  {fQs.length===0
                    ?<PageHero icon="❓" title="No Questions Found" subtitle="Try different search or section."/>
                    :<div style={{display:'flex',flexDirection:'column',gap:8}}>
                      {fQs.map((q,qi)=>{
                        const isChk=bulkSel.includes(q._id)
                        const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':q.subject==='Math'?'#FBBF24':'#94A3B8'
                        const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                        return(
                          <div key={q._id||qi} style={{...cs,marginBottom:0,borderLeft:'3px solid '+sCol+'50',background:isChk?'rgba(77,159,255,0.06)':undefined}}>
                            <div style={{display:'flex',alignItems:'flex-start',gap:10}}>
                              <input type="checkbox" checked={isChk} onChange={e=>{if(e.target.checked)setBulkSel(p=>[...p,q._id]);else setBulkSel(p=>p.filter(x=>x!==q._id))}} style={{marginTop:4,cursor:'pointer',accentColor:'#4D9FFF'}}/>
                              <div style={{flex:1,minWidth:0}}>
                                <div style={{display:'flex',gap:5,marginBottom:5,flexWrap:'wrap',alignItems:'center'}}>
                                  <span style={{fontSize:10,color:'#4D9FFF',fontWeight:700,background:'rgba(77,159,255,0.1)',borderRadius:4,padding:'1px 6px'}}>#{qi+1}</span>
                                  <Badge label={q.subject||'General'} col={sCol}/>
                                  <Badge label={q.difficulty||'?'} col={dCol}/>
                                  <Badge label={q.type||'SCQ'} col='#4D9FFF'/>
                                  {(q.usageCount||0)>0&&<Badge label={'Used '+(q.usageCount||0)+'x'} col='#A78BFA'/>}
                                </div>
                                <div onClick={()=>setSelQId(q._id)} style={{cursor:'pointer',fontSize:12,color:'#CBD5E1',lineHeight:1.6,marginBottom:4}}>{(q.text||'').slice(0,160)}{(q.text||'').length>160?'…':''}</div>
                                {q.chapter&&<div style={{fontSize:10,color:'#64748B'}}>📖 {q.chapter}{q.topic?' → '+q.topic:''}</div>}
                                {stdPrv&&(q.options||[]).length>0&&(
                                  <div style={{marginTop:8,display:'flex',flexDirection:'column',gap:4}}>
                                    {(q.options||[]).map((opt,oi)=>{
                                      const ltr=String.fromCharCode(65+oi)
                                      const isC=String(q.correct?.[0])===String(oi)||q.correctAnswer===ltr
                                      return(<div key={oi} style={{padding:'5px 10px',borderRadius:6,border:'1px solid '+(isC?'rgba(0,200,100,0.35)':'rgba(255,255,255,0.07)'),background:isC?'rgba(0,200,100,0.07)':'transparent',fontSize:11,color:isC?'#00C864':'#94A3B8'}}><span style={{fontWeight:700,marginRight:6,color:isC?'#00C864':'#4D9FFF'}}>{ltr}.</span>{opt}{isC&&<span style={{marginLeft:8,fontSize:10}}>✓</span>}</div>)
                                    })}
                                  </div>
                                )}
                              </div>
                              <div style={{display:'flex',gap:3,flexShrink:0,flexDirection:'column'}}>
                                <button onClick={()=>setSelQId(q._id)} style={{...bg_,padding:'3px 7px',fontSize:10}}>👁️</button>
                                <button onClick={()=>setEditQD({...q})} style={{...bg_,padding:'3px 7px',fontSize:10}}>✏️</button>
                                <button onClick={()=>dupQF(q)} style={{...bg_,padding:'3px 7px',fontSize:10}}>📋</button>
                                <button onClick={async()=>{if(confirm('Delete?')){const r=await fetch(API+'/api/questions/'+q._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}});if(r.ok){setQuestions(p=>p.filter(x=>x._id!==q._id));T('Deleted.')}else T('Failed','e')}}} style={{...bd,padding:'3px 7px',fontSize:10}}>🗑️</button>
                              </div>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  }
                </div>
              )}

              {aiGO&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
                  <div style={{background:'#0D1B2A',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:24,width:'100%',maxWidth:420,maxHeight:'90vh',overflowY:'auto'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div><div style={{fontSize:15,fontWeight:800,color:'#E2E8F0'}}>🤖 AI Question Generator</div><div style={{fontSize:11,color:'#64748B',marginTop:2}}>Step {aiGStep} of 4 · {aiGSub}</div></div>
                      <button onClick={()=>{setAiGO(false);setAiGStep(1);setAiGResult([])}} style={{...bg_,padding:'3px 9px',fontSize:12}}>✕</button>
                    </div>
                    <div style={{display:'flex',gap:4,marginBottom:16}}>{[1,2,3,4].map(s=><div key={s} style={{flex:1,height:3,borderRadius:2,background:s<=aiGStep?'#4D9FFF':'rgba(255,255,255,0.1)'}}/>)}</div>
                    {aiGStep===1&&(
                      <div>
                        <div style={{fontSize:13,fontWeight:700,color:'#CBD5E1',marginBottom:12}}>1️⃣ Select Subject</div>
                        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                          {[{v:'Physics',e:'⚛️'},{v:'Chemistry',e:'🧪'},{v:'Biology',e:'🧬'},{v:'Math',e:'📐'}].map(({v,e})=>(
                            <div key={v} onClick={()=>{setAiGSub(v);setAiGStep(2)}} style={{padding:'14px 10px',borderRadius:12,border:'1.5px solid '+(aiGSub===v?'rgba(77,159,255,0.5)':'rgba(255,255,255,0.08)'),background:aiGSub===v?'rgba(77,159,255,0.1)':'rgba(255,255,255,0.02)',cursor:'pointer',textAlign:'center'}}>
                              <div style={{fontSize:24,marginBottom:4}}>{e}</div>
                              <div style={{fontSize:12,fontWeight:700,color:'#CBD5E1'}}>{v}</div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                    {aiGStep===2&&(<div><div style={{fontSize:13,fontWeight:700,color:'#CBD5E1',marginBottom:12}}>2️⃣ Enter Chapter</div><SInput init='' onSet={v=>{aiChR.current=v}} ph='e.g. Electrostatics / Cell Biology' style={{...inp,marginBottom:14}}/><div style={{display:'flex',gap:8}}><button onClick={()=>setAiGStep(1)} style={{...bg_,flex:1}}>← Back</button><button onClick={()=>{if(aiChR.current)setAiGStep(3);else T('Chapter fill karo','e')}} style={{...bp,flex:2}}>Next →</button></div></div>)}
                    {aiGStep===3&&(<div><div style={{fontSize:13,fontWeight:700,color:'#CBD5E1',marginBottom:12}}>3️⃣ Enter Topic</div><SInput init='' onSet={v=>{aiTopR.current=v}} ph='e.g. Coulombs Law / Mitosis' style={{...inp,marginBottom:14}}/><div style={{display:'flex',gap:8}}><button onClick={()=>setAiGStep(2)} style={{...bg_,flex:1}}>← Back</button><button onClick={()=>{if(aiTopR.current)setAiGStep(4);else T('Topic fill karo','e')}} style={{...bp,flex:2}}>Next →</button></div></div>)}
                    {aiGStep===4&&(
                      <div>
                        <div style={{fontSize:13,fontWeight:700,color:'#CBD5E1',marginBottom:12}}>4️⃣ Configure</div>
                        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                          <div><label style={lbl}>Count</label><SSelect val={aiGCnt} onChange={setAiGCnt} opts={[{v:'5',l:'5 Qs'},{v:'10',l:'10 Qs'},{v:'15',l:'15 Qs'},{v:'20',l:'20 Qs'}]} style={{...inp}}/></div>
                          <div><label style={lbl}>Difficulty</label><SSelect val={aiGDiff} onChange={setAiGDiff} opts={[{v:'easy',l:'🟢 Easy'},{v:'medium',l:'🟡 Med'},{v:'hard',l:'🔴 Hard'}]} style={{...inp}}/></div>
                        </div>
                        <div style={{padding:'9px 12px',background:'rgba(77,159,255,0.07)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,fontSize:11,color:'#94A3B8',marginBottom:14,lineHeight:1.7}}>
                          <span style={{color:'#4D9FFF',fontWeight:700}}>{aiGCnt}</span> {aiGDiff} {aiGSub} Qs · Ch: <span style={{color:'#4D9FFF'}}>{aiChR.current}</span> · T: <span style={{color:'#4D9FFF'}}>{aiTopR.current}</span>
                        </div>
                        <div style={{display:'flex',gap:8}}><button onClick={()=>setAiGStep(3)} style={{...bg_,flex:1}}>← Back</button><button onClick={aiGF} disabled={aiGLoading} style={{...bp,flex:2,opacity:aiGLoading?0.7:1}}>{aiGLoading?'⟳ Generating…':'🤖 Generate'}</button></div>
                      </div>
                    )}
                    {aiGResult.length>0&&(
                      <div style={{marginTop:16}}>
                        <div style={{fontSize:12,fontWeight:700,color:'#00C864',marginBottom:8}}>✅ {aiGResult.length} Questions Generated!</div>
                        <div style={{maxHeight:130,overflowY:'auto',marginBottom:12,display:'flex',flexDirection:'column',gap:5}}>
                          {aiGResult.map((q,i)=>(
                            <div key={i} style={{padding:'6px 10px',background:'rgba(255,255,255,0.03)',borderRadius:7,fontSize:11,color:'#CBD5E1'}}>Q{i+1}: {(q.text||'').slice(0,80)}…</div>
                          ))}
                        </div>
                        <button onClick={saveAiQs} style={{...bp,width:'100%'}}>💾 Save All {aiGResult.length} to Bank</button>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {selQId&&(()=>{
                const qi=(questions||[]).findIndex(q=>q._id===selQId)
                const q=(questions||[])[qi]
                if(!q)return null
                const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':'#A78BFA'
                const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
                    <div style={{background:'#0D1B2A',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:22,width:'100%',maxWidth:500,maxHeight:'90vh',overflowY:'auto'}}>
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12}}>
                        <div>
                          <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:4}}><Badge label={q.subject||'?'} col={sCol}/><Badge label={q.difficulty||'?'} col={dCol}/><Badge label={q.type||'SCQ'} col='#4D9FFF'/></div>
                          <div style={{fontSize:10,color:'#475569'}}>Q{qi+1} of {(questions||[]).length}</div>
                        </div>
                        <button onClick={()=>setSelQId(null)} style={{...bg_,padding:'3px 9px',fontSize:12}}>✕</button>
                      </div>
                      <div style={{fontSize:13,color:'#E2E8F0',lineHeight:1.7,marginBottom:12,padding:'12px 14px',background:'rgba(255,255,255,0.03)',borderRadius:10,border:'1px solid rgba(255,255,255,0.06)'}}>{q.text}</div>
                      {q.hindiText&&<div style={{fontSize:11,color:'#94A3B8',marginBottom:10,fontStyle:'italic',padding:'6px 12px',background:'rgba(255,255,255,0.02)',borderRadius:8}}>{q.hindiText}</div>}
                      {(q.options||[]).length>0&&(
                        <div style={{display:'flex',flexDirection:'column',gap:6,marginBottom:12}}>
                          {(q.options||[]).map((opt,oi)=>{
                            const ltr=String.fromCharCode(65+oi)
                            const isC=String(q.correct?.[0])===String(oi)||q.correctAnswer===ltr
                            return(<div key={oi} style={{padding:'8px 12px',borderRadius:8,border:'1px solid '+(isC?'rgba(0,200,100,0.4)':'rgba(255,255,255,0.07)'),background:isC?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)'}}><span style={{fontWeight:700,color:isC?'#00C864':'#4D9FFF',marginRight:8}}>{ltr}.</span><span style={{fontSize:12,color:isC?'#E2E8F0':'#94A3B8'}}>{opt}</span>{isC&&<span style={{marginLeft:8,fontSize:10,color:'#00C864',fontWeight:700}}>✓</span>}</div>)
                          })}
                        </div>
                      )}
                      {(q.chapter||q.topic||q.explanation)&&<div style={{fontSize:11,color:'#64748B',marginBottom:12,lineHeight:1.7}}>{q.chapter&&<div>📖 {q.chapter}</div>}{q.topic&&<div>📌 {q.topic}</div>}{q.explanation&&<div style={{color:'#94A3B8',marginTop:5}}>💡 {q.explanation}</div>}</div>}
                      <div style={{display:'flex',gap:8}}>
                        <button onClick={()=>{if(qi>0)setSelQId((questions||[])[qi-1]._id)}} disabled={qi===0} style={{...bg_,flex:1,opacity:qi===0?0.4:1,fontSize:12}}>← Prev</button>
                        <button onClick={()=>{setEditQD({...q});setSelQId(null)}} style={{...bp,flex:1,fontSize:12}}>✏️ Edit</button>
                        <button onClick={()=>{if(qi<(questions||[]).length-1)setSelQId((questions||[])[qi+1]._id)}} disabled={qi>=(questions||[]).length-1} style={{...bg_,flex:1,opacity:qi>=(questions||[]).length-1?0.4:1,fontSize:12}}>Next →</button>
                      </div>
                    </div>
                  </div>
                )
              })()}

              {editQD&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:1001,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
                  <div style={{background:'#0D1B2A',border:'1px solid rgba(255,184,0,0.25)',borderRadius:20,padding:22,width:'100%',maxWidth:480,maxHeight:'90vh',overflowY:'auto'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>✏️ Edit Question</div>
                      <button onClick={()=>setEditQD(null)} style={{...bg_,padding:'3px 9px',fontSize:12}}>✕</button>
                    </div>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:14}}>
                      <div style={{gridColumn:'1/-1'}}><label style={lbl}>Question Text *</label><textarea value={editQD.text||''} onChange={e=>setEditQD(p=>({...p,text:e.target.value}))} rows={3} style={{...inp,width:'100%',resize:'vertical'}}/></div>
                      <div><label style={lbl}>Subject</label><select value={editQD.subject||'Physics'} onChange={e=>setEditQD(p=>({...p,subject:e.target.value}))} style={{...inp,width:'100%'}}>{['Physics','Chemistry','Biology','Math','Other'].map(s=><option key={s} value={s}>{s}</option>)}</select></div>
                      <div><label style={lbl}>Difficulty</label><select value={editQD.difficulty||'medium'} onChange={e=>setEditQD(p=>({...p,difficulty:e.target.value}))} style={{...inp,width:'100%'}}>{['easy','medium','hard'].map(d=><option key={d} value={d}>{d}</option>)}</select></div>
                      <div><label style={lbl}>Chapter</label><input value={editQD.chapter||''} onChange={e=>setEditQD(p=>({...p,chapter:e.target.value}))} style={{...inp,width:'100%'}}/></div>
                      <div><label style={lbl}>Topic</label><input value={editQD.topic||''} onChange={e=>setEditQD(p=>({...p,topic:e.target.value}))} style={{...inp,width:'100%'}}/></div>
                      {(editQD.options||[]).map((opt,oi)=>(
                        <div key={oi}><label style={lbl}>Option {String.fromCharCode(65+oi)}</label><input value={opt} onChange={e=>{const opts=[...(editQD.options||[])];opts[oi]=e.target.value;setEditQD(p=>({...p,options:opts}))}} style={{...inp,width:'100%'}}/></div>
                      ))}
                      <div style={{gridColumn:'1/-1'}}><label style={lbl}>Explanation</label><textarea value={editQD.explanation||''} onChange={e=>setEditQD(p=>({...p,explanation:e.target.value}))} rows={2} style={{...inp,width:'100%',resize:'vertical'}}/></div>
                    </div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={()=>setEditQD(null)} style={{...bg_,flex:1}}>Cancel</button>
                      <button onClick={()=>editQF(editQD._id,editQD)} disabled={savingEQ} style={{...bp,flex:2,opacity:savingEQ?0.7:1}}>{savingEQ?'⟳ Saving…':'💾 Save Changes'}</button>
                    </div>
                  </div>
                </div>
              )}

            </div>
          )}`

txt2 = txt.slice(0, si) + NEW_QB + '\n' + txt.slice(ei)
fs.writeFileSync(FILE, txt2)
console.log('✅ Step 4: QB JSX replaced')
console.log('')
console.log('═══════════════════════════')
console.log('✅ All 4 steps complete!')
console.log('═══════════════════════════')
NODEEOF

echo ""
echo "Running TypeScript check…"
cd frontend && npx tsc --noEmit 2>&1 | head -50
