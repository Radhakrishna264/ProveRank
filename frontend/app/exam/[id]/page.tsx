'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter, useParams } from 'next/navigation'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const _gt=():string=>{try{return localStorage.getItem('pr_token')||''}catch{return''}}
const _gl=():string=>{try{return localStorage.getItem('pr_lang')||'en'}catch{return'en'}}
const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',GLD='#FFD700',WRN='#FFB84D',SUB='#6B8FAF',TXT='#E8F4FF',CRD='rgba(0,22,40,0.94)'

export default function ExamPage() {
  const router = useRouter()
  const params = useParams()
  const examId = params?.id as string
  const [phase,   setPhase]  = useState<'waiting'|'instructions'|'webcam'|'exam'|'done'>('waiting')
  const [exam,    setExam]   = useState<any>(null)
  const [qs,      setQs]     = useState<any[]>([])
  const [ans,     setAns]    = useState<{[k:string]:string}>({})
  const [flag,    setFlag]   = useState<Set<string>>(new Set())
  const [visited, setVisited]= useState<Set<string>>(new Set())
  const [curQ,    setCurQ]   = useState(0)
  const [time,    setTime]   = useState(0)
  const [loading, setLoading]= useState(true)
  const [sending, setSending]= useState(false)
  const [attId,   setAttId]  = useState('')
  const [tabs,    setTabs]   = useState(0)
  const [camOk,   setCamOk]  = useState(false)
  const [camErr,  setCamErr] = useState('')
  const [terms,   setTerms]  = useState(false)
  const [score,   setScore]  = useState<number|null>(null)
  const [rank,    setRank]   = useState<number|null>(null)
  const camRef  = useRef<HTMLVideoElement>(null)
  const timerRef= useRef<ReturnType<typeof setInterval>>()
  const saveRef = useRef<ReturnType<typeof setInterval>>()
  const token   = _gt()
  const lang    = _gl()
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token){router.replace('/login');return}
    if(!examId) return
    fetch(`${API}/api/exams/${examId}`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():null).then(d=>{
      if(!d){router.replace('/my-exams');return}
      setExam(d); setTime((d.duration||180)*60)
      const diff=new Date(d.scheduledAt).getTime()-Date.now()
      setPhase(diff>10*60*1000?'waiting':'instructions')
      setLoading(false)
    }).catch(()=>router.replace('/my-exams'))
  },[examId,token,router])

  useEffect(()=>{
    if(phase!=='exam'||time<=0) return
    timerRef.current=setInterval(()=>setTime(p=>{if(p<=1){clearInterval(timerRef.current);submitExam(true);return 0}return p-1}),1000)
    return()=>clearInterval(timerRef.current)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  },[phase])

  useEffect(()=>{
    if(phase!=='exam') return
    saveRef.current=setInterval(()=>{
      if(attId&&token) fetch(`${API}/api/attempts/${attId}/save`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({answers:ans})}).catch(()=>{})
    },30000)
    return()=>clearInterval(saveRef.current)
  },[phase,attId,ans,token])

  useEffect(()=>{
    if(phase!=='exam') return
    const h=()=>{
      if(document.hidden) setTabs(p=>{
        const n=p+1
        if(n>=3){alert(t('Auto submitting! 3 tab switches detected.','स्वतः सबमिट! 3 टैब स्विच पाए गए।'));submitExam(true)}
        else alert(t(`Warning ${n}/3: Do NOT switch tabs! 3 = auto submit`,`चेतावनी ${n}/3: टैब स्विच मत करें!`))
        if(attId&&token) fetch(`${API}/api/attempts/${attId}/flag`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({type:'tab_switch',count:n})}).catch(()=>{})
        return n
      })
    }
    const rc=(e:MouseEvent)=>{e.preventDefault();return false}
    const kd=(e:KeyboardEvent)=>{if(e.key==='F12'||(e.ctrlKey&&e.shiftKey&&e.key==='I')){e.preventDefault();return false}}
    document.addEventListener('visibilitychange',h)
    document.addEventListener('contextmenu',rc)
    document.addEventListener('keydown',kd)
    return()=>{document.removeEventListener('visibilitychange',h);document.removeEventListener('contextmenu',rc);document.removeEventListener('keydown',kd)}
  // eslint-disable-next-line react-hooks/exhaustive-deps
  },[phase,attId,token])

  useEffect(()=>{
    if(phase==='exam'){document.documentElement.requestFullscreen?.().catch(()=>{})}
    else if(document.fullscreenElement){document.exitFullscreen?.().catch(()=>{})}
  },[phase])

  const startExam=useCallback(async()=>{
    if(!token||!examId) return
    try{
      const r=await fetch(`${API}/api/attempts/start`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({examId,termsAccepted:true})})
      if(!r.ok){const e=await r.json();alert(e.message||'Cannot start exam');return}
      const d=await r.json()
      setAttId(d.attempt?._id||d.attemptId||d._id||'')
      const qr=await fetch(`${API}/api/exams/${examId}/questions`,{headers:{Authorization:`Bearer ${token}`}})
      const qdata=qr.ok?await qr.json():[]
      setQs(Array.isArray(qdata)?qdata:(qdata.questions||[]))
      setPhase('exam')
    }catch(e:any){alert('Network error: '+e.message)}
  },[examId,token])

  const setupCam=async()=>{
    try{
      const stream=await navigator.mediaDevices.getUserMedia({video:true})
      if(camRef.current){camRef.current.srcObject=stream;camRef.current.play()}
      setCamOk(true); setTimeout(()=>startExam(),1500)
    }catch{setCamErr(t('Camera access denied. Webcam is required to proceed.','कैमरा एक्सेस अस्वीकृत। आगे बढ़ने के लिए वेबकैम आवश्यक है।'))}
  }

  const submitExam=useCallback(async(auto=false)=>{
    if(!auto&&!confirm(t('Submit the exam? Review all answers first.','परीक्षा सबमिट करें? सभी उत्तर जांचें।'))) return
    if(sending) return; setSending(true)
    clearInterval(timerRef.current); clearInterval(saveRef.current)
    try{document.exitFullscreen?.().catch(()=>{})}catch{}
    try{
      const r=await fetch(`${API}/api/attempts/${attId}/submit`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({answers:ans})})
      if(r.ok){const d=await r.json();setScore(d.result?.score??d.score??null);setRank(d.result?.rank??d.rank??null);setPhase('done')}
      else{const e=await r.json();alert(e.message||'Submit failed');setSending(false)}
    }catch(e:any){alert('Network error: '+e.message);setSending(false)}
  // eslint-disable-next-line react-hooks/exhaustive-deps
  },[attId,ans,token,sending])

  const fmt=(s:number)=>`${String(Math.floor(s/60)).padStart(2,'0')}:${String(s%60).padStart(2,'0')}`
  const q=qs[curQ]
  const sBg=(qId:string)=>{if(ans[qId]&&flag.has(qId))return'#A78BFA';if(ans[qId])return SUC;if(flag.has(qId))return WRN;if(visited.has(qId))return DNG;return'rgba(255,255,255,.1)'}
  const navTo=(i:number)=>{setCurQ(i);setVisited(p=>{const n=new Set(p);n.add(qs[i]?._id||'');return n})}

  if(loading) return <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628,#000510)',display:'flex',alignItems:'center',justifyContent:'center',color:TXT,fontFamily:'Inter,sans-serif',fontSize:36}}>📝</div>

  const card=(children:React.ReactNode)=>(
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628,#000510)',display:'flex',alignItems:'center',justifyContent:'center',padding:24,fontFamily:'Inter,sans-serif'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}@keyframes pulse{0%,100%{opacity:.4}50%{opacity:1}}`}</style>
      <div style={{background:CRD,border:`1px solid rgba(77,159,255,.3)`,borderRadius:22,padding:'36px 28px',maxWidth:490,width:'100%',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,.5)'}}>{children}</div>
    </div>
  )

  if(phase==='waiting'&&exam) return card(
    <div style={{textAlign:'center'}}>
      <div style={{fontSize:52,marginBottom:14,animation:'float 4s ease-in-out infinite'}}>⏳</div>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,marginBottom:4}}>{t('Exam Waiting Room','परीक्षा वेटिंग रूम')} (M6)</div>
      <div style={{fontSize:12,color:SUB,marginBottom:20}}>{exam.title}</div>
      <div style={{background:'rgba(77,159,255,.1)',border:'1px solid rgba(77,159,255,.2)',borderRadius:13,padding:'18px',marginBottom:22}}>
        <div style={{fontSize:36,fontWeight:800,color:PRI,fontFamily:'Playfair Display,serif'}}>{fmt(time)}</div>
        <div style={{fontSize:11,color:SUB,marginTop:4}}>{t('Time until exam starts','परीक्षा शुरू होने में समय')}</div>
      </div>
      <div style={{display:'flex',gap:12,justifyContent:'center',fontSize:12,color:SUB,flexWrap:'wrap',marginBottom:20}}>
        <span>⏱️ {exam.duration} min</span><span>🎯 {exam.totalMarks} marks</span><span>📝 {exam.totalQuestions||180} Qs</span>
      </div>
      <button onClick={()=>setPhase('instructions')} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',boxShadow:`0 4px 16px ${PRI}44`}}>
        {t('Enter Waiting Room →','वेटिंग रूम में प्रवेश →')}
      </button>
    </div>
  )

  if(phase==='instructions'&&exam) return card(
    <div>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:TXT,marginBottom:4,textAlign:'center'}}>📋 {t('Instructions','निर्देश')}</div>
      <div style={{fontSize:12,color:SUB,textAlign:'center',marginBottom:18}}>{t('Read carefully before starting','शुरू करने से पहले ध्यान से पढ़ें')}</div>
      <div style={{background:'rgba(77,159,255,.06)',border:'1px solid rgba(77,159,255,.15)',borderRadius:12,padding:'14px 18px',marginBottom:16}}>
        {(lang==='en'?[`Exam: ${exam.title}`,`Duration: ${exam.duration} minutes`,`Total Marks: ${exam.totalMarks}`,`Questions: ${exam.totalQuestions||180}`,'📷 Webcam is COMPULSORY throughout (anti-cheat)','🚫 Right-click & copy-paste disabled','⚠️ 3 tab switches = auto submit (S1/S2)','📺 Fullscreen will be enforced (S32)']:
        [`परीक्षा: ${exam.title}`,`अवधि: ${exam.duration} मिनट`,`कुल अंक: ${exam.totalMarks}`,`प्रश्न: ${exam.totalQuestions||180}`,'📷 वेबकैम पूरे समय अनिवार्य (anti-cheat)','🚫 राइट-क्लिक और कॉपी-पेस्ट अक्षम','⚠️ 3 टैब स्विच = स्वतः सबमिट','📺 फुलस्क्रीन अनिवार्य']).map((p,i)=>(
          <div key={i} style={{display:'flex',gap:8,padding:'5px 0',borderBottom:i<7?'1px solid rgba(77,159,255,.07)':'none',fontSize:11}}>
            <span style={{color:PRI,fontWeight:700,width:18,flexShrink:0}}>{i+1}.</span>
            <span style={{color:TXT}}>{p}</span>
          </div>
        ))}
      </div>
      {exam.customInstructions&&<div style={{background:'rgba(255,184,77,.08)',border:'1px solid rgba(255,184,77,.2)',borderRadius:9,padding:'9px 14px',marginBottom:14,fontSize:11,color:WRN}}>📌 {exam.customInstructions}</div>}
      <div style={{display:'flex',alignItems:'center',gap:9,marginBottom:18,padding:'11px 14px',background:'rgba(0,196,140,.07)',border:'1px solid rgba(0,196,140,.2)',borderRadius:9}}>
        <input type="checkbox" id="tc" checked={terms} onChange={e=>setTerms(e.target.checked)} style={{width:16,height:16,accentColor:PRI,cursor:'pointer',flexShrink:0}}/>
        <label htmlFor="tc" style={{fontSize:12,color:TXT,cursor:'pointer',lineHeight:1.4}}>{t('I have read and agree to all instructions (S91)','मैंने सभी निर्देश पढ़े और सहमत हूं')}</label>
      </div>
      <button onClick={()=>setPhase('webcam')} disabled={!terms} style={{width:'100%',padding:'13px',background:terms?`linear-gradient(135deg,${PRI},#0055CC)`:'rgba(107,143,175,.2)',color:'#fff',border:'none',borderRadius:12,cursor:terms?'pointer':'not-allowed',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',transition:'all .3s',boxShadow:terms?`0 4px 16px ${PRI}44`:undefined}}>
        {t('Proceed to Webcam →','वेबकैम की ओर जाएं →')}
      </button>
    </div>
  )

  if(phase==='webcam') return card(
    <div style={{textAlign:'center'}}>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:TXT,marginBottom:4}}>📷 {t('Webcam Check','वेबकैम जांच')}</div>
      <div style={{fontSize:12,color:SUB,marginBottom:18}}>{t('Camera permission required for anti-cheat proctoring','Anti-cheat प्रॉक्टरिंग के लिए कैमरा अनुमति आवश्यक')}</div>
      <div style={{width:220,height:160,background:'rgba(0,22,40,.6)',borderRadius:12,margin:'0 auto 18px',overflow:'hidden',border:`1px solid rgba(77,159,255,.25)`,display:'flex',alignItems:'center',justifyContent:'center',position:'relative'}}>
        <video ref={camRef} style={{width:'100%',height:'100%',objectFit:'cover',display:camOk?'block':'none'}} muted autoPlay/>
        {!camOk&&<span style={{fontSize:44,color:SUB}}>📷</span>}
        {camOk&&<div style={{position:'absolute',top:8,right:8,background:'rgba(0,196,140,.9)',borderRadius:6,padding:'2px 7px',fontSize:9,fontWeight:700,color:'#000'}}>✅ LIVE</div>}
      </div>
      {camErr&&<div style={{color:DNG,fontSize:12,marginBottom:13,background:'rgba(255,77,77,.1)',border:'1px solid rgba(255,77,77,.25)',borderRadius:8,padding:'9px 14px'}}>{camErr}</div>}
      {camOk?<div style={{color:SUC,fontSize:13,fontWeight:600,marginBottom:14}}>✅ {t('Camera ready! Starting exam...','कैमरा तैयार! परीक्षा शुरू हो रही है...')}</div>:(
        <button onClick={setupCam} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',boxShadow:`0 4px 16px ${PRI}44`}}>
          📷 {t('Allow Camera & Start Exam','कैमरा अनुमति दें और शुरू करें')}
        </button>
      )}
      <div style={{marginTop:11,fontSize:11,color:SUB}}>{t('Webcam is mandatory. Exam cannot start without camera access.','वेबकैम अनिवार्य है — बिना इसके परीक्षा शुरू नहीं होगी।')}</div>
    </div>
  )

  if(phase==='exam'&&q) return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628,#000510)',fontFamily:'Inter,sans-serif',display:'flex',flexDirection:'column'}}>
      <style>{`*{box-sizing:border-box}::-webkit-scrollbar{width:4px}::-webkit-scrollbar-thumb{background:rgba(77,159,255,.3);border-radius:4px}@keyframes shimmer{0%,100%{opacity:.5}50%{opacity:1}}@keyframes pulse{0%,100%{opacity:.4}50%{opacity:1}}`}</style>
      {/* Topbar */}
      <div style={{position:'sticky',top:0,zIndex:50,background:'rgba(0,5,18,.97)',backdropFilter:'blur(22px)',borderBottom:'1px solid rgba(77,159,255,.2)',padding:'0 14px',height:52,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:13,color:TXT,maxWidth:'35%',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{exam?.title}</div>
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          {tabs>0&&<span style={{fontSize:11,color:DNG,fontWeight:700,animation:'pulse 1s infinite'}}>⚠️ {tabs}/3 {t('tabs','टैब')}</span>}
          <div style={{background:time<300?'rgba(255,77,77,.2)':'rgba(77,159,255,.1)',border:`1px solid ${time<300?DNG:'rgba(77,159,255,.2)'}`,borderRadius:8,padding:'5px 12px',fontSize:13,fontWeight:800,color:time<300?DNG:PRI,fontFamily:'monospace',minWidth:70,textAlign:'center'}}>{fmt(time)}</div>
          <button onClick={()=>submitExam(false)} disabled={sending} style={{padding:'7px 13px',background:`linear-gradient(135deg,${DNG},#cc0000)`,color:'#fff',border:'none',borderRadius:8,cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif',opacity:sending?.7:1}}>
            {sending?t('Submitting...','सबमिट...'):t('Submit','सबमिट')}
          </button>
        </div>
      </div>
      <div style={{display:'flex',flex:1,overflow:'hidden'}}>
        {/* Question Area */}
        <div style={{flex:1,overflowY:'auto',padding:14}}>
          <div style={{background:CRD,border:'1px solid rgba(77,159,255,.2)',borderRadius:15,padding:18,marginBottom:12,backdropFilter:'blur(12px)'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12,flexWrap:'wrap',gap:7}}>
              <div style={{display:'flex',gap:7,flexWrap:'wrap'}}>
                <span style={{fontSize:10,padding:'2px 9px',borderRadius:20,background:'rgba(77,159,255,.15)',color:PRI,fontWeight:700}}>Q {curQ+1}/{qs.length}</span>
                {q.subject&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:q.subject==='Physics'?'rgba(0,180,255,.15)':q.subject==='Chemistry'?'rgba(255,107,157,.15)':'rgba(0,229,160,.15)',color:q.subject==='Physics'?'#00B4FF':q.subject==='Chemistry'?'#FF6B9D':'#00E5A0',fontWeight:600}}>{q.subject}</span>}
              </div>
              <button onClick={()=>setFlag(p=>{const n=new Set(p);n.has(q._id)?n.delete(q._id):n.add(q._id);return n})} style={{padding:'3px 9px',background:flag.has(q._id)?'rgba(255,184,77,.2)':'rgba(255,255,255,.05)',border:`1px solid ${flag.has(q._id)?WRN:'rgba(77,159,255,.2)'}`,borderRadius:6,color:flag.has(q._id)?WRN:SUB,cursor:'pointer',fontSize:10,fontFamily:'Inter,sans-serif'}}>
                {flag.has(q._id)?'🚩 Flagged':'🏳️ Flag'}
              </button>
            </div>
            <div style={{fontSize:15,color:TXT,lineHeight:1.7,marginBottom:q.hindiText?7:0}}>{q.text||q.question||'—'}</div>
            {q.hindiText&&<div style={{fontSize:12,color:SUB,lineHeight:1.6,fontStyle:'italic'}}>{q.hindiText}</div>}
          </div>
          {/* Options */}
          <div style={{display:'flex',flexDirection:'column',gap:9,marginBottom:16}}>
            {(q.options||['Option A','Option B','Option C','Option D']).map((opt:string,i:number)=>{
              const ltr=String.fromCharCode(65+i); const sel=ans[q._id]===ltr
              return (
                <button key={i} onClick={()=>{setAns(p=>({...p,[q._id]:ltr}));setVisited(p=>{const n=new Set(p);n.add(q._id);return n})}} style={{display:'flex',alignItems:'center',gap:11,padding:'13px 16px',background:sel?'rgba(77,159,255,.2)':'rgba(0,22,40,.6)',border:`2px solid ${sel?PRI:'rgba(77,159,255,.14)'}`,borderRadius:11,cursor:'pointer',textAlign:'left',transition:'all .15s',color:sel?TXT:SUB,fontFamily:'Inter,sans-serif'}}>
                  <span style={{width:30,height:30,borderRadius:'50%',background:sel?PRI:'rgba(77,159,255,.1)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:13,color:sel?'#fff':SUB,flexShrink:0,border:`1px solid ${sel?PRI:'rgba(77,159,255,.2)'}`}}>{ltr}</span>
                  <span style={{fontSize:14,lineHeight:1.5}}>{opt}</span>
                </button>
              )
            })}
          </div>
          {/* Prev/Next */}
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:9}}>
            <button onClick={()=>{if(curQ>0)navTo(curQ-1)}} disabled={curQ===0} style={{padding:'10px 18px',background:'rgba(77,159,255,.12)',color:curQ===0?SUB:PRI,border:`1px solid ${curQ===0?'rgba(77,159,255,.2)':'rgba(77,159,255,.35)'}`,borderRadius:9,cursor:curQ===0?'not-allowed':'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif',opacity:curQ===0?.5:1}}>← {t('Prev','पिछला')}</button>
            <div style={{fontSize:10,color:SUB,textAlign:'center'}}>
              <span style={{color:SUC}}>✅ {Object.keys(ans).length}</span> · <span style={{color:WRN}}>🚩 {flag.size}</span> · <span style={{color:DNG}}>⭕ {qs.length-Object.keys(ans).length}</span>
            </div>
            <button onClick={()=>{if(curQ<qs.length-1)navTo(curQ+1)}} disabled={curQ===qs.length-1} style={{padding:'10px 18px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:9,cursor:curQ===qs.length-1?'not-allowed':'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif',opacity:curQ===qs.length-1?.5:1,boxShadow:`0 4px 12px ${PRI}44`}}>{t('Next','अगला')} →</button>
          </div>
        </div>
        {/* Side Panel */}
        <div style={{width:182,background:'rgba(0,5,18,.97)',borderLeft:'1px solid rgba(77,159,255,.18)',overflowY:'auto',padding:10,flexShrink:0,display:'flex',flexDirection:'column',gap:8}}>
          <div style={{fontSize:9,fontWeight:700,color:SUB,letterSpacing:.5,textTransform:'uppercase'}}>Navigate</div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:3}}>
            {qs.map((qn:any,i:number)=>(
              <button key={i} onClick={()=>navTo(i)} style={{width:'100%',aspectRatio:'1',borderRadius:5,border:`1.5px solid ${i===curQ?PRI:'transparent'}`,background:sBg(qn._id),color:'#fff',fontSize:9,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif',outline:'none',transition:'all .15s'}}>{i+1}</button>
            ))}
          </div>
          <div style={{display:'flex',flexDirection:'column',gap:3}}>
            {[[SUC,'Answered'],[WRN,'Flagged'],[DNG,'Not Ans'],['rgba(255,255,255,.1)','Not Visited']].map(([col,lbl])=>(
              <div key={lbl} style={{display:'flex',alignItems:'center',gap:4,fontSize:8,color:SUB}}>
                <span style={{width:8,height:8,borderRadius:2,background:String(col),flexShrink:0}}/>
                <span>{lbl}</span>
              </div>
            ))}
          </div>
          {/* Webcam mini view */}
          <div style={{borderRadius:7,overflow:'hidden',border:'1px solid rgba(77,159,255,.2)',marginTop:'auto'}}>
            <video ref={camRef} style={{width:'100%',height:80,objectFit:'cover',display:'block'}} muted autoPlay/>
          </div>
          <div style={{fontSize:8,color:SUC,textAlign:'center'}}>🟢 Webcam Active</div>
        </div>
      </div>
    </div>
  )

  if(phase==='done') return card(
    <div style={{textAlign:'center'}}>
      <div style={{fontSize:64,marginBottom:18,animation:'float 2s ease-in-out infinite'}}>🎉</div>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,color:SUC,marginBottom:7,textShadow:`0 0 20px ${SUC}44`}}>{t('Exam Submitted!','परीक्षा सबमिट हुई!')}</div>
      <div style={{fontSize:13,color:SUB,marginBottom:24}}>{exam?.title}</div>
      <div style={{display:'flex',gap:12,justifyContent:'center',marginBottom:26,flexWrap:'wrap'}}>
        {[[score!=null?`${score}/${exam?.totalMarks||720}`:'—',t('Score','स्कोर'),PRI],[rank?`#${rank}`:'—',t('AIR Rank','AIR रैंक'),GLD],['—',t('Percentile','पर्सेंटाइल'),SUC]].map(([v,l,c])=>(
          <div key={String(l)} style={{textAlign:'center',padding:'14px 18px',background:`${c}15`,border:`1px solid ${c}30`,borderRadius:13,minWidth:90}}>
            <div style={{fontWeight:900,fontSize:24,color:String(c),fontFamily:'Playfair Display,serif',textShadow:`0 0 12px ${c}44`}}>{v}</div>
            <div style={{fontSize:10,color:SUB,marginTop:3}}>{l}</div>
          </div>
        ))}
      </div>
      <div style={{display:'flex',gap:9,justifyContent:'center',flexWrap:'wrap',marginBottom:16}}>
        <a href="/results" style={{padding:'11px 22px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',borderRadius:11,textDecoration:'none',fontWeight:700,fontSize:13,boxShadow:`0 4px 16px ${PRI}44`}}>{t('View Results →','परिणाम देखें →')}</a>
        <a href="/dashboard" style={{padding:'11px 18px',background:'rgba(77,159,255,.12)',color:PRI,border:'1px solid rgba(77,159,255,.3)',borderRadius:11,textDecoration:'none',fontWeight:600,fontSize:13}}>{t('Dashboard','डैशबोर्ड')}</a>
      </div>
      <div style={{fontSize:12,color:SUB,fontStyle:'italic'}}>{t('"Every attempt makes you stronger! Keep going! 🚀"','"हर प्रयास आपको मजबूत बनाता है! 🚀"')}</div>
    </div>
  )
  return null
}
