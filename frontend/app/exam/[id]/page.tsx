'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter, useParams } from 'next/navigation'
import { getToken, clearAuth } from '@/lib/auth'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.92)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function ExamAttemptPage() {
  const router = useRouter()
  const params = useParams()
  const examId = params?.id as string

  const [phase, setPhase] = useState<'waiting'|'instructions'|'webcam'|'exam'|'submitted'>('waiting')
  const [exam, setExam] = useState<any>(null)
  const [questions, setQuestions] = useState<any[]>([])
  const [answers, setAnswers] = useState<{[qId:string]:string}>({})
  const [flagged, setFlagged] = useState<Set<string>>(new Set())
  const [visited, setVisited] = useState<Set<string>>(new Set())
  const [currentQ, setCurrentQ] = useState(0)
  const [timeLeft, setTimeLeft] = useState(0)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [attemptId, setAttemptId] = useState('')
  const [tabSwitchCount, setTabSwitchCount] = useState(0)
  const [webcamOk, setWebcamOk] = useState(false)
  const [webcamError, setWebcamError] = useState('')
  const [rank, setRank] = useState<number|null>(null)
  const [score, setScore] = useState<number|null>(null)
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const webcamRef = useRef<HTMLVideoElement>(null)
  const timerRef = useRef<NodeJS.Timeout>()
  const autoSaveRef = useRef<NodeJS.Timeout>()
  const token = getToken()

  const TR:{[k:string]:any} = {
    en:{waitTitle:'Exam Waiting Room',waitSub:'Please wait — exam starts soon',minsLeft:'minutes remaining',instr:'Instructions',instrSub:'Read carefully before starting',points:[`Exam: {title}`,'Duration: {duration} minutes','Total Marks: {marks}','Webcam is COMPULSORY — keep it on throughout','Right-click and copy-paste are disabled','3 tab switches = auto submit','Fullscreen will be enforced','Save answers every 30 seconds automatically'],agree:'I have read and agree to all instructions',start:'Start Exam →',webcamTitle:'Webcam Check',webcamAllow:'Please allow camera access',webcamOk:'Camera ready! Starting exam...',next:'Next →',prev:'← Prev',submit:'Submit Exam',submitting:'Submitting...',result:'Your Result!',scoreLabel:'Score',rankLabel:'AIR Rank',percentileLabel:'Percentile',goResults:'View Full Results →',tabWarn:'⚠️ Tab switch detected! {n}/3 — 3 switches = auto submit',autoSubmit:'Auto submitting — 3 tab switches detected',answered:'Answered',flaggedLbl:'Flagged',unanswered:'Not Answered',notVisited:'Not Visited',sureSubmit:'Submit the exam? Make sure you have reviewed all answers.',},
    hi:{waitTitle:'परीक्षा वेटिंग रूम',waitSub:'कृपया प्रतीक्षा करें — परीक्षा जल्द शुरू होगी',minsLeft:'मिनट शेष',instr:'निर्देश',instrSub:'शुरू करने से पहले ध्यान से पढ़ें',points:[`परीक्षा: {title}`,'अवधि: {duration} मिनट','कुल अंक: {marks}','वेबकैम अनिवार्य है — पूरे समय चालू रखें','राइट-क्लिक और कॉपी-पेस्ट अक्षम है','3 टैब स्विच = स्वतः सबमिट','फुलस्क्रीन अनिवार्य होगा','उत्तर हर 30 सेकंड में स्वतः सहेजे जाते हैं'],agree:'मैंने सभी निर्देश पढ़ लिए हैं और सहमत हूं',start:'परीक्षा शुरू करें →',webcamTitle:'वेबकैम जांच',webcamAllow:'कृपया कैमरा एक्सेस की अनुमति दें',webcamOk:'कैमरा तैयार! परीक्षा शुरू हो रही है...',next:'अगला →',prev:'← पिछला',submit:'परीक्षा सबमिट करें',submitting:'सबमिट हो रहा है...',result:'आपका परिणाम!',scoreLabel:'स्कोर',rankLabel:'AIR रैंक',percentileLabel:'पर्सेंटाइल',goResults:'पूरे परिणाम देखें →',tabWarn:'⚠️ टैब स्विच पकड़ा! {n}/3 — 3 बार = स्वतः सबमिट',autoSubmit:'स्वतः सबमिट — 3 टैब स्विच पकड़े गए',answered:'उत्तर दिया',flaggedLbl:'फ्लैग किया',unanswered:'उत्तर नहीं',notVisited:'नहीं देखा',sureSubmit:'परीक्षा सबमिट करें? सुनिश्चित करें कि सभी उत्तर जांचे हैं।',}
  }
  const t = TR[lang]

  useEffect(()=>{
    const savedLang = localStorage.getItem('pr_lang') as 'en'|'hi'
    if(savedLang) setLang(savedLang)
    if(!token){router.replace('/login');return}
    if(!examId) return
    fetch(`${API}/api/exams/${examId}`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():null).then(d=>{
      if(!d){router.replace('/my-exams');return}
      setExam(d)
      setTimeLeft((d.duration||200)*60)
      const now = new Date()
      const examTime = new Date(d.scheduledAt)
      const diff = examTime.getTime()-now.getTime()
      if(diff>10*60*1000) setPhase('waiting')
      else setPhase('instructions')
      setLoading(false)
    }).catch(()=>{router.replace('/my-exams')})
  },[examId,token,router])

  // Countdown timer
  useEffect(()=>{
    if(phase!=='exam'||timeLeft<=0) return
    timerRef.current = setInterval(()=>{
      setTimeLeft(p=>{
        if(p<=1){clearInterval(timerRef.current);handleSubmit(true);return 0}
        return p-1
      })
    },1000)
    return()=>clearInterval(timerRef.current)
  },[phase])

  // Auto-save
  useEffect(()=>{
    if(phase!=='exam') return
    autoSaveRef.current = setInterval(()=>autoSave(),30000)
    return()=>clearInterval(autoSaveRef.current)
  },[phase,answers])

  // Anti-cheat: tab switch
  useEffect(()=>{
    if(phase!=='exam') return
    const handler = ()=>{
      if(document.hidden){
        setTabSwitchCount(p=>{
          const n=p+1
          if(n>=3){alert(t.autoSubmit);handleSubmit(true)}
          else alert(t.tabWarn.replace('{n}',String(n)))
          fetch(`${API}/api/attempts/${attemptId}/flag`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token||''}`},body:JSON.stringify({type:'tab_switch',count:n})}).catch(()=>{})
          return n
        })
      }
    }
    document.addEventListener('visibilitychange',handler)
    const rcHandler = (e:MouseEvent)=>{e.preventDefault();return false}
    document.addEventListener('contextmenu',rcHandler)
    return()=>{document.removeEventListener('visibilitychange',handler);document.removeEventListener('contextmenu',rcHandler)}
  },[phase,attemptId])

  // Fullscreen
  useEffect(()=>{
    if(phase==='exam'&&document.documentElement.requestFullscreen){
      document.documentElement.requestFullscreen().catch(()=>{})
    }
    return()=>{if(document.fullscreenElement&&document.exitFullscreen)document.exitFullscreen().catch(()=>{})}
  },[phase])

  // Load questions + start attempt
  const startExam = useCallback(async()=>{
    if(!token||!examId) return
    try {
      const res = await fetch(`${API}/api/attempts/start`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({examId,termsAccepted:true})})
      if(!res.ok){const e=await res.json();alert(e.message||'Could not start exam');return}
      const d = await res.json()
      setAttemptId(d.attempt?._id||d.attemptId||d._id||'')
      const qRes = await fetch(`${API}/api/exams/${examId}/questions`,{headers:{Authorization:`Bearer ${token}`}})
      const qs = qRes.ok?await qRes.json():[]
      setQuestions(Array.isArray(qs)?qs:(qs.questions||[]))
      setPhase('exam')
    } catch(e:any){alert('Network error: '+e.message)}
  },[examId,token])

  const autoSave = useCallback(async()=>{
    if(!attemptId||!token) return
    try {
      await fetch(`${API}/api/attempts/${attemptId}/save`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({answers})})
    } catch{}
  },[attemptId,answers,token])

  const handleSubmit = useCallback(async(auto=false)=>{
    if(!auto&&!confirm(t.sureSubmit)) return
    if(submitting) return
    setSubmitting(true)
    clearInterval(timerRef.current)
    clearInterval(autoSaveRef.current)
    if(document.fullscreenElement) document.exitFullscreen().catch(()=>{})
    try {
      const res = await fetch(`${API}/api/attempts/${attemptId}/submit`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({answers})})
      if(res.ok){
        const d=await res.json()
        setScore(d.result?.score||d.score||null)
        setRank(d.result?.rank||d.rank||null)
        setPhase('submitted')
      } else {
        const e=await res.json()
        alert(e.message||'Submit failed')
        setSubmitting(false)
      }
    } catch(e:any){alert('Network error: '+e.message);setSubmitting(false)}
  },[attemptId,answers,token,submitting,t.sureSubmit])

  const setupWebcam = async()=>{
    try {
      const stream = await navigator.mediaDevices.getUserMedia({video:true})
      if(webcamRef.current){webcamRef.current.srcObject=stream;webcamRef.current.play()}
      setWebcamOk(true)
      setTimeout(()=>startExam(),1500)
    } catch{setWebcamError(lang==='en'?'Camera access denied. Webcam is required for the exam.':'कैमरा एक्सेस अस्वीकृत। परीक्षा के लिए वेबकैम आवश्यक है।')}
  }

  const fmt = (s:number)=>{
    const m=Math.floor(s/60),sec=s%60
    return `${String(m).padStart(2,'0')}:${String(sec).padStart(2,'0')}`
  }

  const q = questions[currentQ]
  const answeredCount = Object.keys(answers).length
  const flaggedCount = flagged.size
  const statusBg = (qId:string)=>{
    if(answers[qId]&&flagged.has(qId)) return '#A78BFA'
    if(answers[qId]) return C.success
    if(flagged.has(qId)) return C.warn
    if(visited.has(qId)) return C.danger
    return 'rgba(255,255,255,0.1)'
  }

  if(loading) return <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',display:'flex',alignItems:'center',justifyContent:'center',color:C.text,fontFamily:'Inter,sans-serif'}}><div style={{textAlign:'center'}}><div style={{fontSize:40,marginBottom:12,animation:'pulse 1s infinite'}}>📝</div><div>Loading exam...</div></div></div>

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',color:C.text,fontFamily:'Inter,sans-serif',position:'relative'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');@keyframes pulse{0%,100%{opacity:.5}50%{opacity:1}}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}*{box-sizing:border-box}::-webkit-scrollbar{width:4px}::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}`}</style>

      {/* ══ WAITING ROOM ══ */}
      {phase==='waiting'&&exam&&(
        <div style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',padding:24,animation:'fadeIn .5s ease'}}>
          <div style={{background:C.card,border:`1px solid rgba(77,159,255,0.3)`,borderRadius:24,padding:'40px 32px',maxWidth:480,width:'100%',backdropFilter:'blur(20px)',textAlign:'center',boxShadow:'0 8px 40px rgba(0,0,0,0.5)'}}>
            <div style={{fontSize:52,marginBottom:16,animation:'pulse 2s infinite'}}>⏳</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,color:C.text,marginBottom:6}}>{t.waitTitle}</div>
            <div style={{fontSize:13,color:C.sub,marginBottom:24}}>{exam.title}</div>
            <div style={{background:'rgba(77,159,255,0.1)',border:`1px solid rgba(77,159,255,0.2)`,borderRadius:14,padding:'20px',marginBottom:24}}>
              <div style={{fontSize:36,fontWeight:800,color:C.primary,fontFamily:'Playfair Display,serif'}}>{fmt(timeLeft)}</div>
              <div style={{fontSize:12,color:C.sub,marginTop:4}}>{t.waitSub}</div>
            </div>
            <div style={{display:'flex',gap:10,justifyContent:'center',fontSize:12,color:C.sub,flexWrap:'wrap'}}>
              <span>⏱️ {exam.duration} min</span>
              <span>🎯 {exam.totalMarks} marks</span>
              <span>📅 {new Date(exam.scheduledAt).toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit'})}</span>
            </div>
            <button onClick={()=>setPhase('instructions')} style={{marginTop:20,padding:'12px 24px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',width:'100%'}}>{lang==='en'?'Enter Waiting Room →':'वेटिंग रूम में प्रवेश करें →'}</button>
          </div>
        </div>
      )}

      {/* ══ INSTRUCTIONS ══ */}
      {phase==='instructions'&&exam&&(
        <div style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',padding:24,animation:'fadeIn .5s ease'}}>
          <div style={{background:C.card,border:`1px solid rgba(77,159,255,0.3)`,borderRadius:24,padding:'40px 32px',maxWidth:520,width:'100%',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.5)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:C.text,marginBottom:4,textAlign:'center'}}>📋 {t.instr}</div>
            <div style={{fontSize:12,color:C.sub,textAlign:'center',marginBottom:24}}>{t.instrSub}</div>
            <div style={{background:'rgba(77,159,255,0.06)',border:`1px solid rgba(77,159,255,0.15)`,borderRadius:14,padding:'16px 20px',marginBottom:20}}>
              {t.points.map((p:string,i:number)=>(
                <div key={i} style={{display:'flex',gap:10,padding:'6px 0',borderBottom:i<t.points.length-1?`1px solid rgba(77,159,255,0.1)`:'none',fontSize:12}}>
                  <span style={{color:C.primary,fontWeight:700,flexShrink:0,width:20}}>{i+1}.</span>
                  <span style={{color:C.text}}>{p.replace('{title}',exam.title||'').replace('{duration}',exam.duration||'200').replace('{marks}',exam.totalMarks||'720')}</span>
                </div>
              ))}
            </div>
            {exam.customInstructions&&<div style={{background:'rgba(255,184,77,0.08)',border:'1px solid rgba(255,184,77,0.2)',borderRadius:10,padding:'12px 16px',marginBottom:16,fontSize:12,color:C.warn}}>📌 {exam.customInstructions}</div>}
            <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:20,padding:'12px 16px',background:'rgba(0,196,140,0.06)',border:'1px solid rgba(0,196,140,0.2)',borderRadius:10}}>
              <input type="checkbox" id="terms" checked={termsAccepted} onChange={e=>setTermsAccepted(e.target.checked)} style={{width:16,height:16,accentColor:C.primary,cursor:'pointer',flexShrink:0}}/>
              <label htmlFor="terms" style={{fontSize:12,color:C.text,cursor:'pointer',lineHeight:1.4}}>{t.agree}</label>
            </div>
            <button onClick={()=>setPhase('webcam')} disabled={!termsAccepted} style={{width:'100%',padding:'14px',background:termsAccepted?`linear-gradient(135deg,${C.primary},#0055CC)`:'rgba(107,143,175,0.2)',color:'#fff',border:'none',borderRadius:12,cursor:termsAccepted?'pointer':'not-allowed',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',transition:'all .3s'}}>{t.start}</button>
          </div>
        </div>
      )}

      {/* ══ WEBCAM CHECK ══ */}
      {phase==='webcam'&&(
        <div style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',padding:24,animation:'fadeIn .5s ease'}}>
          <div style={{background:C.card,border:`1px solid rgba(77,159,255,0.3)`,borderRadius:24,padding:'40px 32px',maxWidth:440,width:'100%',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.5)',textAlign:'center'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:C.text,marginBottom:6}}>📷 {t.webcamTitle}</div>
            <div style={{fontSize:12,color:C.sub,marginBottom:20}}>{t.webcamAllow}</div>
            <div style={{width:200,height:150,background:'rgba(0,22,40,0.6)',borderRadius:14,margin:'0 auto 20px',overflow:'hidden',border:`1px solid ${C.border}`,display:'flex',alignItems:'center',justifyContent:'center',position:'relative'}}>
              <video ref={webcamRef} style={{width:'100%',height:'100%',objectFit:'cover',display:webcamOk?'block':'none'}} muted/>
              {!webcamOk&&<span style={{fontSize:40,color:C.sub}}>📷</span>}
            </div>
            {webcamError&&<div style={{color:C.danger,fontSize:12,marginBottom:14,background:'rgba(255,77,77,0.1)',border:'1px solid rgba(255,77,77,0.25)',borderRadius:8,padding:'8px 12px'}}>{webcamError}</div>}
            {webcamOk?<div style={{color:C.success,fontSize:13,fontWeight:600,marginBottom:16}}>✅ {t.webcamOk}</div>:(
              <button onClick={setupWebcam} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif'}}>
                📷 {lang==='en'?'Allow Camera & Start':'कैमरा अनुमति दें और शुरू करें'}
              </button>
            )}
            <div style={{marginTop:12,fontSize:11,color:C.sub}}>{lang==='en'?'Webcam is compulsory. Exam cannot start without camera.':'वेबकैम अनिवार्य है। कैमरा के बिना परीक्षा शुरू नहीं होगी।'}</div>
          </div>
        </div>
      )}

      {/* ══ EXAM UI ══ */}
      {phase==='exam'&&q&&(
        <div style={{display:'flex',flexDirection:'column',minHeight:'100vh'}}>
          {/* Exam Header */}
          <div style={{background:'rgba(0,6,18,0.95)',backdropFilter:'blur(20px)',borderBottom:`1px solid ${C.border}`,padding:'0 16px',height:52,display:'flex',alignItems:'center',justifyContent:'space-between',position:'sticky',top:0,zIndex:100}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:C.text,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',maxWidth:'40%'}}>{exam?.title}</div>
            <div style={{display:'flex',alignItems:'center',gap:14}}>
              {tabSwitchCount>0&&<span style={{fontSize:11,color:C.danger,fontWeight:600}}>⚠️ {tabSwitchCount}/3</span>}
              <div style={{background:timeLeft<300?'rgba(255,77,77,0.2)':'rgba(77,159,255,0.1)',border:`1px solid ${timeLeft<300?C.danger:C.border}`,borderRadius:8,padding:'5px 12px',fontSize:14,fontWeight:800,color:timeLeft<300?C.danger:C.primary,fontFamily:'monospace',minWidth:70,textAlign:'center'}}>{fmt(timeLeft)}</div>
              <button onClick={()=>handleSubmit(false)} disabled={submitting} style={{padding:'7px 14px',background:`linear-gradient(135deg,${C.danger},#cc0000)`,color:'#fff',border:'none',borderRadius:8,cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif',opacity:submitting?.7:1}}>
                {submitting?t.submitting:t.submit}
              </button>
            </div>
          </div>

          <div style={{display:'flex',flex:1,overflow:'hidden'}}>
            {/* Question Area */}
            <div style={{flex:1,overflowY:'auto',padding:16}}>
              {/* Question */}
              <div style={{background:C.card,border:`1px solid ${C.border}`,borderRadius:16,padding:20,marginBottom:16,backdropFilter:'blur(12px)'}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14,flexWrap:'wrap',gap:8}}>
                  <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                    <span style={{fontSize:11,padding:'2px 8px',borderRadius:20,background:'rgba(77,159,255,0.15)',color:C.primary,fontWeight:700}}>Q {currentQ+1}/{questions.length}</span>
                    {q.subject&&<span style={{fontSize:11,padding:'2px 8px',borderRadius:20,background:q.subject==='Physics'?'rgba(0,180,255,0.15)':q.subject==='Chemistry'?'rgba(255,107,157,0.15)':'rgba(0,229,160,0.15)',color:q.subject==='Physics'?'#00B4FF':q.subject==='Chemistry'?'#FF6B9D':'#00E5A0',fontWeight:600}}>{q.subject}</span>}
                    {q.difficulty&&<span style={{fontSize:11,padding:'2px 8px',borderRadius:20,background:'rgba(255,255,255,0.08)',color:C.sub,fontWeight:600}}>{q.difficulty}</span>}
                  </div>
                  <button onClick={()=>{setFlagged(p=>{const n=new Set(p);n.has(q._id)?n.delete(q._id):n.add(q._id);return n})}} style={{padding:'4px 10px',background:flagged.has(q._id)?'rgba(255,184,77,0.2)':'rgba(255,255,255,0.06)',border:`1px solid ${flagged.has(q._id)?C.warn:C.border}`,borderRadius:6,color:flagged.has(q._id)?C.warn:C.sub,cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif'}}>
                    {flagged.has(q._id)?'🚩 Flagged':'🏳️ Flag'}
                  </button>
                </div>
                <div style={{fontSize:15,color:C.text,lineHeight:1.7,fontWeight:500,marginBottom:q.hindiText?8:0}}>{q.text||q.question||'—'}</div>
                {q.hindiText&&<div style={{fontSize:13,color:C.sub,lineHeight:1.6,fontStyle:'italic'}}>{q.hindiText}</div>}
                {q.imageUrl&&<img src={q.imageUrl} alt="Question" style={{maxWidth:'100%',borderRadius:8,marginTop:10,border:`1px solid ${C.border}`}}/>}
              </div>

              {/* Options */}
              <div style={{display:'flex',flexDirection:'column',gap:10,marginBottom:20}}>
                {(q.options||['Option A','Option B','Option C','Option D']).map((opt:string,i:number)=>{
                  const letter = String.fromCharCode(65+i)
                  const sel = answers[q._id]===letter
                  return (
                    <button key={i} onClick={()=>{setAnswers(p=>({...p,[q._id]:letter}));setVisited(p=>{const n=new Set(p);n.add(q._id);return n})}} style={{display:'flex',alignItems:'center',gap:12,padding:'14px 18px',background:sel?`rgba(77,159,255,0.2)`:'rgba(0,22,40,0.6)',border:`2px solid ${sel?C.primary:'rgba(77,159,255,0.15)'}`,borderRadius:12,cursor:'pointer',textAlign:'left',transition:'all .15s',color:sel?C.text:C.sub}}>
                      <span style={{width:30,height:30,borderRadius:'50%',background:sel?C.primary:'rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:13,color:sel?'#fff':C.sub,flexShrink:0,border:`1px solid ${sel?C.primary:'rgba(77,159,255,0.2)'}`}}>{letter}</span>
                      <span style={{fontSize:14,lineHeight:1.5}}>{opt}</span>
                    </button>
                  )
                })}
              </div>

              {/* Navigation Buttons */}
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:10}}>
                <button onClick={()=>{if(currentQ>0){setCurrentQ(p=>p-1);setVisited(p=>{const n=new Set(p);n.add(questions[currentQ-1]?._id||'');return n})}}} disabled={currentQ===0} style={{padding:'11px 20px',background:'rgba(77,159,255,0.12)',color:currentQ===0?C.sub:C.primary,border:`1px solid ${currentQ===0?C.border:'rgba(77,159,255,0.3)'}`,borderRadius:10,cursor:currentQ===0?'not-allowed':'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',opacity:currentQ===0?.5:1}}>{t.prev}</button>
                <div style={{fontSize:11,color:C.sub,textAlign:'center'}}>
                  <span style={{color:C.success}}>✅ {answeredCount}</span> · <span style={{color:C.warn}}>🚩 {flaggedCount}</span> · <span style={{color:C.danger}}>❌ {questions.length-answeredCount}</span>
                </div>
                <button onClick={()=>{if(currentQ<questions.length-1){setCurrentQ(p=>p+1);setVisited(p=>{const n=new Set(p);n.add(questions[currentQ+1]?._id||'');return n})}}} disabled={currentQ===questions.length-1} style={{padding:'11px 20px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',border:'none',borderRadius:10,cursor:currentQ===questions.length-1?'not-allowed':'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',opacity:currentQ===questions.length-1?.5:1}}>{t.next}</button>
              </div>
            </div>

            {/* Question Navigator Sidebar */}
            <div style={{width:200,background:'rgba(0,6,18,0.95)',borderLeft:`1px solid ${C.border}`,overflowY:'auto',padding:12,flexShrink:0}}>
              <div style={{fontSize:11,fontWeight:700,color:C.sub,marginBottom:10,letterSpacing:.5,textTransform:'uppercase'}}>{lang==='en'?'Navigate':'नेविगेट'}</div>
              <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:4,marginBottom:12}}>
                {questions.map((qn:any,i:number)=>(
                  <button key={i} onClick={()=>{setCurrentQ(i);setVisited(p=>{const n=new Set(p);n.add(qn._id);return n})}} style={{width:'100%',aspectRatio:'1',borderRadius:6,border:`1px solid ${i===currentQ?C.primary:'transparent'}`,background:statusBg(qn._id),color:'#fff',fontSize:10,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif',display:'flex',alignItems:'center',justifyContent:'center',outline:i===currentQ?`2px solid ${C.primary}`:'none'}}>
                    {i+1}
                  </button>
                ))}
              </div>
              <div style={{fontSize:9,color:C.sub,display:'flex',flexDirection:'column',gap:4}}>
                {[[C.success,t.answered],[C.warn,t.flaggedLbl],[C.danger,t.unanswered],['rgba(255,255,255,0.1)',t.notVisited]].map(([col,label])=>(
                  <div key={String(label)} style={{display:'flex',alignItems:'center',gap:5}}>
                    <span style={{width:10,height:10,borderRadius:2,background:String(col),flexShrink:0}}/>
                    <span>{label}</span>
                  </div>
                ))}
              </div>
              {/* Webcam mini */}
              <div style={{marginTop:14,borderRadius:8,overflow:'hidden',border:`1px solid ${C.border}`}}>
                <video ref={webcamRef} style={{width:'100%',height:90,objectFit:'cover'}} muted/>
              </div>
              <div style={{fontSize:9,color:C.success,textAlign:'center',marginTop:4}}>🟢 {lang==='en'?'Webcam Active':'वेबकैम चालू'}</div>
            </div>
          </div>
        </div>
      )}

      {/* ══ SUBMITTED / RESULT ══ */}
      {phase==='submitted'&&(
        <div style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',padding:24,animation:'fadeIn .5s ease'}}>
          <div style={{background:C.card,border:`1px solid rgba(0,196,140,0.4)`,borderRadius:24,padding:'48px 32px',maxWidth:480,width:'100%',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.5)',textAlign:'center'}}>
            <div style={{fontSize:64,marginBottom:20}}>🎉</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:700,color:C.success,marginBottom:8}}>{t.result}</div>
            <div style={{fontSize:14,color:C.sub,marginBottom:28}}>{exam?.title}</div>
            <div style={{display:'flex',gap:14,justifyContent:'center',marginBottom:28,flexWrap:'wrap'}}>
              {[[t.scoreLabel,score!==null?`${score}/${exam?.totalMarks||720}`:'—',C.primary],[t.rankLabel,rank?`#${rank}`:'—',C.gold],[t.percentileLabel,'—%',C.success]].map(([l,v,c])=>(
                <div key={String(l)} style={{textAlign:'center',padding:'16px 20px',background:`${c}15`,border:`1px solid ${c}30`,borderRadius:14,minWidth:100}}>
                  <div style={{fontWeight:900,fontSize:28,color:String(c),fontFamily:'Playfair Display,serif'}}>{v}</div>
                  <div style={{fontSize:11,color:C.sub,marginTop:4}}>{l}</div>
                </div>
              ))}
            </div>
            <div style={{display:'flex',gap:10,justifyContent:'center',flexWrap:'wrap'}}>
              <a href="/results" style={{padding:'12px 24px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:12,textDecoration:'none',fontWeight:700,fontSize:14,display:'inline-block'}}>{t.goResults}</a>
              <a href="/dashboard" style={{padding:'12px 24px',background:'rgba(77,159,255,0.12)',color:C.primary,border:`1px solid rgba(77,159,255,0.3)`,borderRadius:12,textDecoration:'none',fontWeight:600,fontSize:14,display:'inline-block'}}>{lang==='en'?'Dashboard':'डैशबोर्ड'}</a>
            </div>
            <div style={{marginTop:20,fontSize:12,color:C.sub}}>{lang==='en'?'"Every attempt makes you stronger — keep going! 🚀"':'"हर प्रयास आपको मजबूत बनाता है — आगे बढ़ते रहो! 🚀"'}</div>
          </div>
        </div>
      )}
    </div>
  )
}
