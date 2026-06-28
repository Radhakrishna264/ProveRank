'use client'
import { useState, useEffect, useCallback } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useAuth } from '@/lib/useAuth'

const API = process.env.NEXT_PUBLIC_API_URL || ''

export default function ExamAttempt() {
  const { user, loading } = useAuth('student')
  const params   = useParams()
  const router   = useRouter()
  const examId   = params?.examId as string
  const [lang, setLang]       = useState<'en'|'hi'>('en')
  const [dark, setDark]       = useState(true)
  const [attempt, setAttempt] = useState<any>(null)
  const [questions, setQuestions] = useState<any[]>([])
  const [current, setCurrent] = useState(0)
  const [answers, setAnswers] = useState<Record<string,string>>({})
  const [flagged, setFlagged] = useState<Set<string>>(new Set())
  const [visited, setVisited] = useState<Set<string>>(new Set())
  const [timeLeft, setTimeLeft] = useState(12000)
  const [submitting, setSubmitting] = useState(false)
  const [showSubmit, setShowSubmit] = useState(false)
  const [warnings, setWarnings] = useState(0)
  const [mounted, setMounted] = useState(false)

  const t = lang==='en' ? {
    submit:'Submit Exam', confirm:'Confirm Submission',
    warning:'⚠️ Warning: Tab switch detected!',
    autoSubmit:'Auto-submitting due to 3 warnings...',
    answered:'Answered', unanswered:'Not Answered', flagged:'Marked', notVisited:'Not Visited',
    saveNext:'Save & Next', markReview:'Mark for Review', clearResp:'Clear Response',
    timeLeft:'Time Remaining', question:'Question',
    subWarn:'You have unanswered questions. Submit anyway?',
    cancelSub:'Cancel', confirmSub:'Yes, Submit',
    physics:'Physics', chemistry:'Chemistry', biology:'Biology',
  } : {
    submit:'परीक्षा जमा करें', confirm:'जमा करने की पुष्टि',
    warning:'⚠️ चेतावनी: टैब परिवर्तन का पता चला!',
    autoSubmit:'3 चेतावनियों के बाद स्वतः जमा...',
    answered:'उत्तर दिया', unanswered:'उत्तर नहीं दिया', flagged:'चिह्नित', notVisited:'नहीं देखा',
    saveNext:'सहेजें और आगे', markReview:'समीक्षा के लिए', clearResp:'साफ करें',
    timeLeft:'शेष समय', question:'प्रश्न',
    subWarn:'कुछ प्रश्नों का उत्तर नहीं दिया। क्या फिर भी जमा करें?',
    cancelSub:'रद्द करें', confirmSub:'हाँ, जमा करें',
    physics:'भौतिकी', chemistry:'रसायन विज्ञान', biology:'जीव विज्ञान',
  }

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
  },[])

  useEffect(()=>{
    if (user && examId) startAttempt()
  },[user, examId])

  // Anti-cheat: tab switch
  useEffect(()=>{
    const onVis = () => {
      if (document.hidden && attempt) {
        setWarnings(w => {
          const next = w+1
          if (next >= 3) { autoSubmit(); return next }
          // Save warning to backend
          if (user && attempt?._id) {
            fetch(`${API}/api/attempts/${attempt._id}/tab-switch`,{
              method:'POST', headers:{'Content-Type':'application/json','Authorization':`Bearer ${user.token}`},
              body:JSON.stringify({count:next})
            }).catch(()=>{})
          }
          return next
        })
      }
    }
    document.addEventListener('visibilitychange', onVis)
    return () => document.removeEventListener('visibilitychange', onVis)
  },[attempt, user])

  // Timer
  useEffect(()=>{
    if (!attempt) return
    const iv = setInterval(()=>{
      setTimeLeft(t=>{
        if(t<=1){ clearInterval(iv); autoSubmit(); return 0 }
        return t-1
      })
    },1000)
    return ()=>clearInterval(iv)
  },[attempt])

  // Auto-save every 30s
  useEffect(()=>{
    if (!attempt) return
    const iv = setInterval(()=>autoSave(), 30000)
    return ()=>clearInterval(iv)
  },[attempt, answers])

  const startAttempt = async () => {
    try {
      const h = {'Content-Type':'application/json','Authorization':`Bearer ${user!.token}`}
      const r = await fetch(`${API}/api/exams/${examId}/start-attempt`,{method:'POST',headers:h})
      const d = await r.json()
      if (r.ok) {
        setAttempt(d.attempt||d)
        setTimeLeft(d.attempt?.remainingSec || d.remainingSec || 12000)
        const qr = await fetch(`${API}/api/exams/${examId}/questions`,{headers:{Authorization:`Bearer ${user!.token}`}})
        const qd = await qr.json()
        if (Array.isArray(qd)) setQuestions(qd)
        else if (qd.questions) setQuestions(qd.questions)
      }
    } catch {}
  }

  const autoSave = useCallback(async()=>{
    if (!attempt?._id || !user) return
    try {
      await fetch(`${API}/api/attempts/${attempt._id}/auto-save`,{
        method:'PATCH', headers:{'Content-Type':'application/json','Authorization':`Bearer ${user.token}`},
        body:JSON.stringify({answers: Object.entries(answers).map(([qId,selectedOption])=>({qId,selectedOption}))})
      })
    } catch {}
  },[attempt, answers, user])

  const saveAnswer = async(qId:string, opt:string)=>{
    setAnswers(a=>({...a,[qId]:opt}))
    if (!attempt?._id || !user) return
    try {
      await fetch(`${API}/api/attempts/${attempt._id}/save-answer`,{
        method:'PATCH', headers:{'Content-Type':'application/json','Authorization':`Bearer ${user.token}`},
        body:JSON.stringify({qId, selectedOption:opt})
      })
    } catch {}
  }

  const autoSubmit = async()=>{
    if (submitting) return
    setSubmitting(true)
    if (!attempt?._id || !user) return
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/submit`,{
        method:'POST', headers:{'Content-Type':'application/json','Authorization':`Bearer ${user!.token}`}
      })
      const d = await r.json()
      if (r.ok) router.push(`/exam/${examId}/result?attemptId=${attempt._id}`)
    } catch {}
    finally { setSubmitting(false) }
  }

  const getStatus = (qId:string)=>{
    if (answers[qId]) return flagged.has(qId)?'flagged':'answered'
    if (flagged.has(qId)) return 'flagged'
    if (visited.has(qId)) return 'unanswered'
    return 'unvisited'
  }

  const h=Math.floor(timeLeft/3600), m=Math.floor((timeLeft%3600)/60), s=timeLeft%60
  const fmt=(n:number)=>String(n).padStart(2,'0')
  const timerPct = attempt ? (timeLeft / (attempt.totalDurationSec||12000)) * 100 : 100
  const timerClass = timerPct>33 ? 'timer-safe' : timerPct>10 ? 'timer-warning' : 'timer-danger'

  const q = questions[current]
  const opts = q ? ['A','B','C','D'] : []

  if (loading || !mounted) return <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>Loading exam...</div>

  const dark2 = true // Exam always dark
  const tm  = '#E8F4FF'; const ts = '#6B8BAF'
  const card = 'rgba(0,22,40,0.85)'; const bord = 'rgba(77,159,255,0.2)'

  return (
    <div style={{minHeight:'100vh',background:'#000A18',color:tm,fontFamily:'Inter,sans-serif',display:'flex',flexDirection:'column'}}
      onContextMenu={e=>e.preventDefault()}>
      <style>{`
        @keyframes pulse{0%,100%{opacity:.4}50%{opacity:1}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;}
        .lb{padding:12px 24px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:14px;font-weight:700;cursor:pointer;transition:all 0.3s;}
        .lb:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(77,159,255,0.4);}
        select option{background:#001628;}
      `}</style>

      {/* Watermark */}
      <div className="exam-watermark">ProveRank • {lang==='en'?'Student':'छात्र'} • ProveRank • {lang==='en'?'Student':'छात्र'} • ProveRank • {lang==='en'?'Student':'छात्र'} • ProveRank</div>

      {/* ── HEADER (Timer + Exam Name) ─────────────────────────── */}
      <header style={{background:'rgba(0,10,24,0.95)',borderBottom:`1px solid ${bord}`,padding:'0 16px',position:'sticky',top:0,zIndex:100,display:'flex',flexDirection:'column'}}>
        <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',height:56,gap:12}}>
          <div style={{display:'flex',alignItems:'center',gap:10}}>
            <svg width={24} height={24} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
            <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,color:'#4D9FFF',fontSize:15}}>ProveRank</span>
          </div>
          {/* Timer */}
          <div style={{display:'flex',alignItems:'center',gap:8,background:'rgba(77,159,255,0.08)',border:`1px solid ${bord}`,borderRadius:10,padding:'8px 16px'}}>
            <span style={{fontSize:14}}>⏱</span>
            <span style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:timerPct<10?'#FF4757':timerPct<33?'#FFA502':'#4D9FFF'}}>
              {fmt(h)}:{fmt(m)}:{fmt(s)}
            </span>
            <span style={{color:ts,fontSize:12}}>{t.timeLeft}</span>
          </div>
          {/* Warnings + Submit */}
          <div style={{display:'flex',gap:10,alignItems:'center'}}>
            {warnings>0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}
            <button className="lb" style={{background:'linear-gradient(135deg,#FF4757,#CC2233)',boxShadow:'0 4px 15px rgba(255,71,87,0.3)'}} onClick={()=>setShowSubmit(true)}>
              {t.submit}
            </button>
          </div>
        </div>
        {/* Timer bar */}
        <div style={{height:4,background:'rgba(77,159,255,0.1)'}}>
          <div className={timerClass} style={{height:'100%',width:`${timerPct}%`,borderRadius:2,transition:'width 1s linear'}}/>
        </div>
      </header>

      {/* ── BODY ────────────────────────────────────────────────── */}
      <div style={{display:'flex',flex:1,overflow:'hidden'}}>
        {/* LEFT: Question Nav Grid */}
        <aside style={{width:220,background:'rgba(0,10,24,0.9)',borderRight:`1px solid ${bord}`,padding:'16px 12px',overflowY:'auto',flexShrink:0}}>
          {/* Section tabs */}
          <div style={{display:'flex',gap:6,marginBottom:16,flexWrap:'wrap'}}>
            {[t.physics, t.chemistry, t.biology].map((sec,i)=>(
              <button key={i} className="tbtn" style={{fontSize:11,padding:'4px 8px',flex:1}}>{sec}</button>
            ))}
          </div>
          {/* Legend */}
          <div style={{display:'flex',flexDirection:'column',gap:4,marginBottom:16}}>
            {[['answered','#00C48C',t.answered],['unanswered','#FF4757',t.unanswered],['flagged','#A855F7',t.flagged],['unvisited','rgba(77,159,255,0.1)',t.notVisited]].map(([cls,clr,lbl])=>(
              <div key={cls} style={{display:'flex',alignItems:'center',gap:6,fontSize:11,color:ts}}>
                <div style={{width:12,height:12,borderRadius:3,background:String(clr)}}/>
                {lbl}
              </div>
            ))}
          </div>
          {/* Grid */}
          <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:4}}>
            {(questions.length > 0 ? questions : Array.from({length:180},(_,i)=>({_id:`q${i}`}))).map((q2:any,i)=>{
              const st2 = getStatus(q2._id)
              return (
                <div key={i} className={`qnum ${st2} ${i===current?'current':''}`}
                  onClick={()=>{ setCurrent(i); setVisited(v2=>new Set([...v2,q2._id])) }}>
                  {i+1}
                </div>
              )
            })}
          </div>
        </aside>

        {/* RIGHT: Question + Options */}
        <main style={{flex:1,overflowY:'auto',padding:'24px'}}>
          {/* Section tabs */}
          <div style={{display:'flex',gap:8,marginBottom:20}}>
            {[t.physics,t.chemistry,t.biology].map((s2,i)=>(
              <button key={i} className="tbtn" style={{fontWeight:600}}>{s2}</button>
            ))}
          </div>

          {/* Question Card */}
          <div style={{background:card,border:`1px solid ${bord}`,borderRadius:16,padding:'28px',marginBottom:20,minHeight:200}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16}}>
              <span style={{color:'#4D9FFF',fontWeight:700,fontSize:14}}>{t.question} {current+1} / {questions.length||180}</span>
              <span className="badge badge-blue">+4 / -1</span>
            </div>
            <div style={{fontSize:16,lineHeight:1.8,color:tm,fontFamily:'Inter,sans-serif'}}>
              {q?.text || `Sample Question ${current+1}: What is the correct statement regarding the structure of DNA?`}
            </div>
            {q?.image && <img src={q.image} alt="Question" style={{maxWidth:'100%',marginTop:16,borderRadius:8}}/>}
          </div>

          {/* Options (OMR Bubble Style) */}
          <div style={{display:'flex',flexDirection:'column',gap:12,marginBottom:28}}>
            {opts.map(opt=>{
              const optText = q?.[`option${opt}`] || `Option ${opt}: Sample answer text here for this question.`
              const isSelected = q && answers[q._id] === opt
              return (
                <div key={opt} onClick={()=>q && saveAnswer(q._id, opt)}
                  style={{display:'flex',alignItems:'center',gap:14,padding:'14px 20px',borderRadius:12,border:`1.5px solid ${isSelected?'#4D9FFF':bord}`,background:isSelected?'rgba(77,159,255,0.1)':'rgba(0,22,40,0.5)',cursor:'pointer',transition:'all .2s'}}
                  onMouseEnter={e=>{if(!isSelected){e.currentTarget.style.borderColor='rgba(77,159,255,0.4)';e.currentTarget.style.background='rgba(77,159,255,0.06)'}}}
                  onMouseLeave={e=>{if(!isSelected){e.currentTarget.style.borderColor=bord;e.currentTarget.style.background='rgba(0,22,40,0.5)'}}}>
                  <div className={`omr-bubble ${isSelected?'selected':''}`} style={{borderColor:isSelected?'#4D9FFF':bord,color:isSelected?'#fff':ts,flexShrink:0}}>
                    {opt}
                  </div>
                  <span style={{color:isSelected?tm:ts,fontSize:15}}>{optText}</span>
                </div>
              )
            })}
          </div>

          {/* Action Buttons */}
          <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
            <button className="tbtn" style={{color:'#A855F7',borderColor:'rgba(168,85,247,0.4)'}} onClick={()=>q&&setFlagged(f=>{const n=new Set(f);n.has(q._id)?n.delete(q._id):n.add(q._id);return n})}>
              🔖 {t.markReview}
            </button>
            <button className="tbtn" onClick={()=>q&&setAnswers(a=>{const n={...a};delete n[q._id];return n})}>
              🗑 {t.clearResp}
            </button>
            <div style={{flex:1}}/>
            <button className="tbtn" onClick={()=>setCurrent(c=>Math.max(0,c-1))} disabled={current===0}>← {lang==='en'?'Previous':'पिछला'}</button>
            <button className="lb" onClick={()=>{ if(q){setVisited(v2=>new Set([...v2,q._id]));} setCurrent(c=>Math.min(c+1,(questions.length||180)-1)) }}>
              {t.saveNext} →
            </button>
          </div>
        </main>
      </div>

      {/* ── Submit Modal ─────────────────────────────────────────── */}
      {showSubmit && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.7)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:200,backdropFilter:'blur(4px)'}}>
          <div style={{background:'rgba(0,22,40,0.95)',border:`1px solid ${bord}`,borderRadius:20,padding:'36px',maxWidth:440,width:'90%',textAlign:'center'}}>
            <div style={{fontSize:48,marginBottom:16}}>📤</div>
            <h2 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,marginBottom:12}}>{t.confirm}</h2>
            <div style={{display:'flex',justifyContent:'center',gap:24,marginBottom:20}}>
              <div><div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#00C48C'}}>{Object.keys(answers).length}</div><div style={{color:ts,fontSize:12}}>{t.answered}</div></div>
              <div><div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#FF4757'}}>{(questions.length||180)-Object.keys(answers).length}</div><div style={{color:ts,fontSize:12}}>{t.unanswered}</div></div>
              <div><div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#A855F7'}}>{flagged.size}</div><div style={{color:ts,fontSize:12}}>{t.flagged}</div></div>
            </div>
            <p style={{color:ts,fontSize:14,marginBottom:24}}>{t.subWarn}</p>
            <div style={{display:'flex',gap:12}}>
              <button onClick={()=>setShowSubmit(false)} style={{flex:1,padding:14,borderRadius:10,border:`1px solid ${bord}`,background:'transparent',color:ts,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:14}}>{t.cancelSub}</button>
              <button className="lb" disabled={submitting} onClick={autoSubmit} style={{flex:1,background:'linear-gradient(135deg,#FF4757,#CC2233)'}}>
                {submitting?'◌ ...' : `✓ ${t.confirmSub}`}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
