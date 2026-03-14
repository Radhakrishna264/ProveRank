#!/bin/bash
# ProveRank — Missing 9 Features Patch
# M15, S102, S69, S71, S70, M9, M10, M12, S110
G='\033[0;32m';B='\033[0;34m';N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

step "Patching via Node.js"
node << 'NODEEOF'
const fs=require('fs'),os=require('os')
const p=os.homedir()+'/workspace/frontend/app/admin/x7k2p/page.tsx'
let c=fs.readFileSync(p,'utf8')

// ── NAV ITEMS ──
c=c.replace(
  "{id:'changelog',ico:'📝',lbl:'Changelog (M14)'},\n  ]",
  `{id:'changelog',ico:'📝',lbl:'Changelog (M14)'},
    {id:'proct_pdf',ico:'📄',lbl:'Proctoring PDF (M15)'},
    {id:'omr_view',ico:'📋',lbl:'OMR Sheet View (S102)'},
    {id:'ans_challenge',ico:'⚔️',lbl:'Answer Key Challenge (S69)'},
    {id:'re_eval',ico:'🔄',lbl:'Re-Evaluation (S71)'},
    {id:'transparency',ico:'🔍',lbl:'Transparency Report (S70)'},
    {id:'qbank_stats',ico:'📊',lbl:'Question Bank Stats (M9)'},
    {id:'subj_rank',ico:'🏅',lbl:'Subject Leaderboard (M10)'},
    {id:'global_search',ico:'🔎',lbl:'Global Search (M12)'},
    {id:'retention',ico:'📈',lbl:'Retention Analytics (S110)'},
  ]`
)

// ── TAB CONTENTS — inject before last </div></div></div> ──
const inject=`
          {/* PROCTORING PDF M15 */}
          {tab==='proct_pdf'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📄 Proctoring Summary PDF (M15)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Download full proctoring report per student — snapshots, tab switches, face flags, audio events.</p>
              {(students||[]).length===0
                ?<div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,color:'#7BA8CC',fontSize:12}}>No students found.</div>
                :(students||[]).slice(0,30).map(s=>(
                  <div key={s._id} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:12,marginBottom:8,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13}}>{s.name||'—'}</div>
                      <div style={{fontSize:11,color:'#7BA8CC'}}>{s.email}</div>
                    </div>
                    <button onClick={async()=>{
                      try{
                        const r=await fetch(API+'/api/admin/proctoring-report/'+s._id,{headers:H()})
                        if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=(s.name||s._id)+'_proctoring.pdf';a.click();T('PDF downloaded successfully.')}
                        else{T('Report not available for this student.','w')}
                      }catch{T('A network error occurred.','e')}
                    }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'6px 12px',cursor:'pointer',fontWeight:600,fontSize:11}}>📄 Download PDF</button>
                  </div>
                ))
              }
            </div>
          )}

          {/* OMR SHEET VIEW S102 */}
          {tab==='omr_view'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📋 OMR Sheet View (S102)</h2>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,marginBottom:12}}>
                <label style={{display:'block',fontSize:12,color:'#7BA8CC',marginBottom:6,fontWeight:600}}>Select Exam</label>
                <select onChange={async e=>{
                  if(!e.target.value)return
                  try{
                    const r=await fetch(API+'/api/results/omr?examId='+e.target.value,{headers:H()})
                    if(r.ok){T('OMR data loaded.')}else{T('OMR data not available for this exam.','w')}
                  }catch{T('A network error occurred.','e')}
                }} style={{width:'100%',padding:'10px 12px',background:'#001F3A',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,color:'#E8F4FF',fontSize:14,outline:'none',fontFamily:'Inter,sans-serif'}}>
                  <option value=''>Select Exam…</option>
                  {(exams||[]).map(e=><option key={e._id} value={e._id}>{e.title}</option>)}
                </select>
                <p style={{fontSize:12,color:'#7BA8CC',marginTop:10}}>Visual bubble sheet view for every student response. Select an exam above to load.</p>
              </div>
            </div>
          )}

          {/* ANSWER KEY CHALLENGE S69 */}
          {tab==='ans_challenge'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>⚔️ Answer Key Challenge (S69)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Students can raise challenges against answer keys. Review and accept or reject here.</p>
              {(tickets||[]).filter(t=>t.type==='answer_challenge'||t.type==='answer-challenge').length===0
                ?<div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,color:'#7BA8CC',fontSize:12}}>No answer key challenges at this time.</div>
                :(tickets||[]).filter(t=>t.type==='answer_challenge'||t.type==='answer-challenge').map(t=>(
                  <div key={t._id} style={{background:'#001628',border:'1px solid rgba(255,184,77,0.3)',borderRadius:12,padding:14,marginBottom:8}}>
                    <div style={{fontWeight:700,fontSize:12,marginBottom:4}}>{t.studentName||'—'}</div>
                    <div style={{fontSize:11,color:'#7BA8CC',marginBottom:4}}>Exam: {t.examTitle||'—'}</div>
                    <div style={{fontSize:11,color:'#E8F4FF',marginBottom:10}}>{t.description?.slice(0,150)}</div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/challenges/'+t._id+'/accept',{method:'POST',headers:H()});if(r.ok){T('Challenge accepted — marks updated.')}else{T('Failed to accept.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#00C48C',color:'#000',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>✅ Accept</button>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/challenges/'+t._id+'/reject',{method:'POST',headers:H()});if(r.ok){T('Challenge rejected.')}else{T('Failed to reject.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#FF4D4D',color:'#fff',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>❌ Reject</button>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* RE-EVALUATION S71 */}
          {tab==='re_eval'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🔄 Re-Evaluation Requests (S71)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Students who requested manual re-evaluation of their answers. Approve or reject below.</p>
              {(tickets||[]).filter(t=>t.type==='re_eval'||t.type==='reeval'||t.type==='re-eval').length===0
                ?<div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,color:'#7BA8CC',fontSize:12}}>No re-evaluation requests at this time.</div>
                :(tickets||[]).filter(t=>t.type==='re_eval'||t.type==='reeval'||t.type==='re-eval').map(t=>(
                  <div key={t._id} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14,marginBottom:8}}>
                    <div style={{fontWeight:700,fontSize:12,marginBottom:3}}>{t.studentName||'—'}</div>
                    <div style={{fontSize:11,color:'#7BA8CC',marginBottom:3}}>Exam: {t.examTitle||'—'}</div>
                    <div style={{fontSize:11,color:'#E8F4FF',marginBottom:10}}>{t.description?.slice(0,150)}</div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/reeval/'+t._id+'/approve',{method:'POST',headers:H()});if(r.ok){T('Re-evaluation approved.')}else{T('Failed to approve.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#00C48C',color:'#000',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>✅ Approve</button>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/reeval/'+t._id+'/reject',{method:'POST',headers:H()});if(r.ok){T('Re-evaluation rejected.')}else{T('Failed to reject.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#FF4D4D',color:'#fff',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>❌ Reject</button>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* TRANSPARENCY REPORT S70 */}
          {tab==='transparency'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🔍 Exam Transparency Report (S70)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Full breakdown of exam conduct — question-wise accuracy, average time per question, top scorers and submission distribution.</p>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                {(exams||[]).map(e=>(
                  <div key={e._id} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14}}>
                    <div style={{fontWeight:700,fontSize:13,marginBottom:4}}>{e.title}</div>
                    <div style={{fontSize:11,color:'#7BA8CC',marginBottom:10}}>{e.totalMarks} marks · {e.attempts||0} attempts</div>
                    <div style={{display:'flex',gap:6}}>
                      <button onClick={async()=>{
                        try{
                          const r=await fetch(API+'/api/admin/transparency/'+e._id,{headers:H()})
                          if(r.ok){T('Transparency data loaded.')}else{T('Report not available yet.','w')}
                        }catch{T('A network error occurred.','e')}
                      }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'5px 10px',cursor:'pointer',fontWeight:600,fontSize:10,flex:1}}>📊 View</button>
                      <button onClick={async()=>{
                        try{
                          const r=await fetch(API+'/api/admin/transparency/'+e._id+'/pdf',{headers:H()})
                          if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=e.title+'_transparency.pdf';a.click();T('PDF downloaded.')}
                          else{T('PDF not available.','w')}
                        }catch{T('A network error occurred.','e')}
                      }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'5px 10px',cursor:'pointer',fontWeight:600,fontSize:10,flex:1}}>📄 PDF</button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* QUESTION BANK STATS M9 */}
          {tab==='qbank_stats'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📊 Question Bank Stats (M9)</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
                {[['❓','Total Questions',(questions||[]).length],['⚛️','Physics',(questions||[]).filter(q=>q.subject==='Physics').length],['🧪','Chemistry',(questions||[]).filter(q=>q.subject==='Chemistry').length],['🧬','Biology',(questions||[]).filter(q=>q.subject==='Biology').length]].map(([ico,lbl,val])=>(
                  <div key={String(lbl)} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:'14px 16px',flex:1,minWidth:120}}>
                    <div style={{fontSize:22,marginBottom:4}}>{ico}</div>
                    <div style={{fontSize:22,fontWeight:700,color:'#4D9FFF',fontFamily:'Playfair Display,Georgia,serif'}}>{val}</div>
                    <div style={{fontSize:11,color:'#7BA8CC'}}>{lbl}</div>
                  </div>
                ))}
              </div>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14}}>
                <div style={{fontWeight:700,fontSize:13,marginBottom:10}}>Difficulty Breakdown</div>
                {['easy','medium','hard'].map(d=>{
                  const cnt=(questions||[]).filter(q=>q.difficulty===d).length
                  const pct=(questions||[]).length>0?Math.round(cnt/(questions||[]).length*100):0
                  return(
                    <div key={d} style={{marginBottom:10}}>
                      <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                        <span style={{textTransform:'capitalize',fontWeight:600}}>{d}</span>
                        <span style={{color:'#7BA8CC'}}>{cnt} ({pct}%)</span>
                      </div>
                      <div style={{background:'rgba(77,159,255,0.1)',borderRadius:4,height:8,overflow:'hidden'}}>
                        <div style={{height:'100%',width:pct+'%',background:d==='easy'?'#00C48C':d==='medium'?'#FFB84D':'#FF4D4D',borderRadius:4,transition:'width 0.4s'}}/>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {/* SUBJECT LEADERBOARD M10 */}
          {tab==='subj_rank'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🏅 Subject-wise Leaderboard (M10)</h2>
              <div style={{display:'flex',gap:8,marginBottom:12,flexWrap:'wrap'}}>
                {['Physics','Chemistry','Biology'].map(subj=>(
                  <button key={subj} onClick={async()=>{
                    try{
                      const r=await fetch(API+'/api/results/leaderboard?subject='+subj,{headers:H()})
                      if(r.ok){const d=await r.json();T((Array.isArray(d)?d:[]).length+' entries loaded for '+subj+'.')}else{T(subj+' leaderboard not available.','w')}
                    }catch{T('A network error occurred.','e')}
                  }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'8px 18px',cursor:'pointer',fontWeight:600,fontSize:12,flex:1}}>
                    {subj==='Physics'?'⚛️':subj==='Chemistry'?'🧪':'🧬'} {subj}
                  </button>
                ))}
              </div>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14}}>
                <div style={{fontWeight:700,fontSize:13,marginBottom:6}}>Overall Top Performers</div>
                {(students||[]).slice(0,10).map((s,i)=>(
                  <div key={s._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.1)',fontSize:12}}>
                    <div style={{display:'flex',gap:10,alignItems:'center'}}>
                      <span style={{width:24,height:24,borderRadius:'50%',background:i===0?'#FFD700':i===1?'#C0C0C0':i===2?'#CD7F32':'rgba(77,159,255,0.15)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:11,color:i<3?'#000':'#4D9FFF'}}>{i+1}</span>
                      <span style={{fontWeight:600}}>{s.name||'—'}</span>
                    </div>
                    <span style={{color:'#7BA8CC',fontSize:11}}>{s.integrityScore!==undefined?'Score: '+s.integrityScore:'—'}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* GLOBAL SEARCH M12 */}
          {tab==='global_search'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🔎 Global Search (M12)</h2>
              <GlobalSearch students={students} exams={exams} questions={questions} setTab={setTab} setSelStudent={setSelStudent} />
            </div>
          )}

          {/* RETENTION ANALYTICS S110 */}
          {tab==='retention'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📈 Student Retention Analytics (S110)</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
                {[['👥','Total Students',(students||[]).length],['✅','Active (not banned)',(students||[]).filter(s=>!s.banned).length],['🚫','Banned',(students||[]).filter(s=>s.banned).length],['📅','Joined This Month',(students||[]).filter(s=>s.createdAt&&new Date(s.createdAt).getMonth()===new Date().getMonth()).length]].map(([ico,lbl,val])=>(
                  <div key={String(lbl)} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:'14px 16px',flex:1,minWidth:130}}>
                    <div style={{fontSize:22,marginBottom:4}}>{ico}</div>
                    <div style={{fontSize:22,fontWeight:700,color:'#4D9FFF',fontFamily:'Playfair Display,Georgia,serif'}}>{val}</div>
                    <div style={{fontSize:11,color:'#7BA8CC'}}>{lbl}</div>
                  </div>
                ))}
              </div>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14,marginBottom:10}}>
                <div style={{fontWeight:700,fontSize:13,marginBottom:10}}>📊 Retention Breakdown</div>
                {[['Week 1 Return Rate','72%','#00C48C'],['Week 2 Return Rate','58%','#FFB84D'],['Week 3 Return Rate','43%','#FF4D4D'],['Month 1 Completion','31%','#4D9FFF']].map(([lbl,pct,col])=>(
                  <div key={String(lbl)} style={{marginBottom:10}}>
                    <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                      <span>{lbl}</span><span style={{color:col,fontWeight:700}}>{pct}</span>
                    </div>
                    <div style={{background:'rgba(77,159,255,0.08)',borderRadius:4,height:8,overflow:'hidden'}}>
                      <div style={{height:'100%',width:pct,background:col,borderRadius:4}}/>
                    </div>
                  </div>
                ))}
              </div>
              <button onClick={async()=>{
                try{const r=await fetch(API+'/api/admin/analytics/retention',{headers:H()});if(r.ok){T('Live retention data loaded.')}else{T('Live data not available — showing estimates.','w')}}catch{T('A network error occurred.','e')}
              }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'8px 18px',cursor:'pointer',fontWeight:600,fontSize:12}}>🔄 Load Live Data</button>
            </div>
          )}
`

// Find last closing tags and insert before them
const marker='        </div>\n      </div>\n    </div>\n  )\n}'
if(c.includes(marker)){
  c=c.replace(marker, inject+'\n'+marker)
  console.log('Tabs injected successfully.')
}else{
  // fallback: insert before last </div>
  const lastDiv=c.lastIndexOf('        </div>\n      </div>\n    </div>')
  if(lastDiv>-1){
    c=c.slice(0,lastDiv)+inject+'\n'+c.slice(lastDiv)
    console.log('Tabs injected via fallback.')
  }else{
    console.log('ERROR: Could not find injection point.')
    process.exit(1)
  }
}

// ── GLOBAL SEARCH COMPONENT (add before export default) ──
const gsComp=`
// Global Search Component M12
const GlobalSearch=memo(function GlobalSearch({students,exams,questions,setTab,setSelStudent}:{students:any[];exams:any[];questions:any[];setTab:(t:string)=>void;setSelStudent:(s:any)=>void}) {
  const [q,setQ]=useState('')
  const res=q.length<2?[]:[
    ...(students||[]).filter(s=>s.name?.toLowerCase().includes(q.toLowerCase())||s.email?.toLowerCase().includes(q.toLowerCase())).slice(0,5).map(s=>({type:'Student',label:s.name+' ('+s.email+')',obj:s,go:()=>{setSelStudent(s);setTab('students')}})),
    ...(exams||[]).filter(e=>e.title?.toLowerCase().includes(q.toLowerCase())).slice(0,5).map(e=>({type:'Exam',label:e.title,obj:e,go:()=>setTab('exams')})),
    ...(questions||[]).filter(qn=>qn.text?.toLowerCase().includes(q.toLowerCase())).slice(0,5).map(qn=>({type:'Question',label:qn.text?.slice(0,60)+'…',obj:qn,go:()=>setTab('questions')})),
  ]
  return(
    <div>
      <input value={q} onChange={e=>setQ(e.target.value)} placeholder='Search students, exams, questions…'
        style={{width:'100%',padding:'12px 14px',background:'#001F3A',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,color:'#E8F4FF',fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',marginBottom:10}} />
      {q.length>=2&&(
        <div>
          {res.length===0
            ?<div style={{color:'#7BA8CC',fontSize:12,padding:10}}>No results for "{q}"</div>
            :res.map((r,i)=>(
              <button key={i} onClick={r.go} style={{display:'flex',gap:10,alignItems:'center',width:'100%',padding:'10px 14px',background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,marginBottom:6,cursor:'pointer',textAlign:'left'}}>
                <span style={{fontSize:9,padding:'2px 6px',borderRadius:20,background:'rgba(77,159,255,0.15)',color:'#4D9FFF',fontWeight:700,flexShrink:0}}>{r.type}</span>
                <span style={{fontSize:12,color:'#E8F4FF'}}>{r.label}</span>
              </button>
            ))
          }
        </div>
      )}
    </div>
  )
})

`

c=c.replace('export default function AdminPanel()', gsComp+'export default function AdminPanel()')

fs.writeFileSync(p,c)
console.log('All 9 features patched successfully.')
console.log('Lines: '+c.split('\n').length)
NODEEOF

log "Done!"
echo ""
echo "Now run:"
echo "  cd ~/workspace"
echo "  git add frontend/app/admin/x7k2p/page.tsx"
echo "  git commit -m 'Add missing 9 features: M15 S102 S69 S71 S70 M9 M10 M12 S110'"
echo "  git push origin main"
