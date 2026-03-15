'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

const TR = {
  en:{ title:'My Exams', sub:'Upcoming & completed exams — your journey documented',
    upcoming:'Upcoming', completed:'Completed', all:'All Exams', search:'Search exams...',
    startExam:'Start Exam →', viewResult:'View Result →', duration:'Duration', marks:'Marks',
    noExam:'No exams found', days:'days', hours:'hours', mins:'mins',
    quote:'"Every exam is a stepping stone — not a stumbling block."',
    quoteHi:'हर परीक्षा एक सीढ़ी है — रुकावट नहीं।',
    inDays:'In {n} days', today:'Today!', expired:'Expired', live:'LIVE',
    joinWaiting:'Join Waiting Room', waitingRoom:'Waiting Room opens 10 min before exam',
  },
  hi:{ title:'मेरी परीक्षाएं', sub:'आगामी और पूर्ण परीक्षाएं — आपकी यात्रा दर्ज',
    upcoming:'आगामी', completed:'पूर्ण', all:'सभी परीक्षाएं', search:'परीक्षा खोजें...',
    startExam:'परीक्षा शुरू करें →', viewResult:'परिणाम देखें →', duration:'अवधि', marks:'अंक',
    noExam:'कोई परीक्षा नहीं मिली', days:'दिन', hours:'घंटे', mins:'मिनट',
    quote:'"हर परीक्षा एक सीढ़ी है — रुकावट नहीं।"',
    quoteHi:'Every exam is a stepping stone — not a stumbling block.',
    inDays:'{n} दिनों में', today:'आज!', expired:'समाप्त', live:'लाइव',
    joinWaiting:'वेटिंग रूम में शामिल हों', waitingRoom:'परीक्षा से 10 मिनट पहले वेटिंग रूम खुलेगा',
  }
}

function ExamCard({exam, dm, lang, t}:{exam:any;dm:boolean;lang:'en'|'hi';t:any}) {
  const now = new Date()
  const examDate = new Date(exam.scheduledAt)
  const diff = examDate.getTime() - now.getTime()
  const daysLeft = Math.ceil(diff / (1000*60*60*24))
  const isLive = diff > -1000*60*exam.duration && diff < 0
  const isUpcoming = diff > 0
  const waitingOpen = diff > 0 && diff < 10*60*1000

  const statusCol = isLive?C.danger:isUpcoming?C.primary:C.sub
  const statusText = isLive?t.live:isUpcoming?daysLeft===0?t.today:`${t.inDays.replace('{n}',daysLeft)}`:exam.status==='completed'?'Completed':t.expired

  return (
    <div className="card-h" style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${isLive?C.danger:isUpcoming?'rgba(77,159,255,0.35)':C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden',transition:'all .2s',marginBottom:12}}>
      {isLive&&<div style={{position:'absolute',top:0,left:0,right:0,height:3,background:`linear-gradient(90deg,${C.danger},#ff8080)`,animation:'shimmer 2s infinite'}}/>}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:10}}>
        <div style={{flex:1,minWidth:200}}>
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:6,flexWrap:'wrap'}}>
            <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A'}}>{exam.title}</span>
            <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${statusCol}22`,color:statusCol,border:`1px solid ${statusCol}44`,fontWeight:700}}>{statusText}</span>
            {exam.category&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${C.gold}15`,color:C.gold,border:`1px solid ${C.gold}30`,fontWeight:600}}>{exam.category}</span>}
          </div>
          <div style={{display:'flex',gap:14,fontSize:11,color:C.sub,flexWrap:'wrap',marginBottom:8}}>
            <span>📅 {examDate.toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})}</span>
            <span>⏱️ {exam.duration} {lang==='en'?'min':'मिनट'}</span>
            <span>🎯 {exam.totalMarks} {t.marks}</span>
            {exam.batch&&<span>📦 {exam.batch}</span>}
          </div>
          {waitingOpen&&<div style={{fontSize:11,color:C.warn,background:'rgba(255,184,77,0.1)',border:'1px solid rgba(255,184,77,0.2)',borderRadius:6,padding:'4px 10px',marginBottom:8}}>⏳ {t.waitingRoom}</div>}
        </div>
        <div style={{display:'flex',gap:8,flexWrap:'wrap',alignItems:'center'}}>
          {isLive&&<a href={`/exam/${exam._id}`} style={{padding:'10px 18px',background:`linear-gradient(135deg,${C.danger},#cc0000)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:12,animation:'glow 1.5s infinite'}}>🔴 {t.startExam}</a>}
          {isUpcoming&&!isLive&&<a href={`/exam/${exam._id}`} style={{padding:'10px 18px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:12}}>{waitingOpen?t.joinWaiting:t.startExam}</a>}
          {!isUpcoming&&!isLive&&<a href={`/results`} style={{padding:'9px 16px',background:'rgba(77,159,255,0.12)',color:C.primary,border:`1px solid rgba(77,159,255,0.3)`,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t.viewResult}</a>}
        </div>
      </div>
    </div>
  )
}

export default function MyExamsPage() {
  return (
    <StudentShell pageKey="my-exams">
      {({lang, darkMode:dm, user, toast, token}) => {
        const t = TR[lang]
        const [exams, setExams] = useState<any[]>([])
        const [loading, setLoading] = useState(true)
        const [filter, setFilter] = useState<'all'|'upcoming'|'completed'>('all')
        const [search, setSearch] = useState('')

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setExams(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
        },[token])

        const now = new Date()
        const filtered = exams.filter(e=>{
          const ed = new Date(e.scheduledAt)
          const matchSearch = !search||e.title?.toLowerCase().includes(search.toLowerCase())
          if(filter==='upcoming') return matchSearch&&ed>now
          if(filter==='completed') return matchSearch&&ed<=now
          return matchSearch
        })

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            {/* Header */}
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{t.title}</h1>
              <div style={{fontSize:13,color:C.sub}}>{t.sub}</div>
            </div>

            {/* SVG + Quote Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.1),rgba(0,22,40,0.8))',border:`1px solid rgba(77,159,255,0.2)`,borderRadius:20,padding:'20px 20px',marginBottom:24,display:'flex',alignItems:'center',gap:20,flexWrap:'wrap',position:'relative',overflow:'hidden'}}>
              <div style={{opacity:.12,position:'absolute',right:20,top:'50%',transform:'translateY(-50%)'}}>
                <svg width="140" height="110" viewBox="0 0 140 110" fill="none">
                  <rect x="10" y="15" width="120" height="80" rx="8" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                  <path d="M10 35h120" stroke="#4D9FFF" strokeWidth="1"/>
                  <circle cx="22" cy="25" r="4" fill="#FF4D4D"/>
                  <circle cx="36" cy="25" r="4" fill="#FFD700"/>
                  <circle cx="50" cy="25" r="4" fill="#00C48C"/>
                  <rect x="20" y="50" width="40" height="6" rx="3" fill="#4D9FFF" opacity=".6"/>
                  <rect x="20" y="62" width="60" height="6" rx="3" fill="#4D9FFF" opacity=".4"/>
                  <rect x="20" y="74" width="30" height="6" rx="3" fill="#4D9FFF" opacity=".3"/>
                  <path d="M90 50 L100 70 L110 55 L120 75" stroke="#FFD700" strokeWidth="2" strokeLinecap="round"/>
                </svg>
              </div>
              <div style={{flex:1,minWidth:250}}>
                <div style={{fontSize:15,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t.quote}</div>
                <div style={{fontSize:12,color:C.sub}}>{t.quoteHi}</div>
              </div>
              <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
                <div style={{textAlign:'center',padding:'10px 16px',background:'rgba(77,159,255,0.1)',borderRadius:12,border:`1px solid ${C.border}`}}>
                  <div style={{fontWeight:800,fontSize:20,color:C.primary}}>{exams.filter(e=>new Date(e.scheduledAt)>now).length}</div>
                  <div style={{fontSize:10,color:C.sub}}>{t.upcoming}</div>
                </div>
                <div style={{textAlign:'center',padding:'10px 16px',background:'rgba(0,196,140,0.08)',borderRadius:12,border:'1px solid rgba(0,196,140,0.2)'}}>
                  <div style={{fontWeight:800,fontSize:20,color:C.success}}>{exams.filter(e=>new Date(e.scheduledAt)<=now).length}</div>
                  <div style={{fontSize:10,color:C.sub}}>{t.completed}</div>
                </div>
              </div>
            </div>

            {/* Search + Filter */}
            <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap'}}>
              <div style={{position:'relative',flex:1,minWidth:200}}>
                <span style={{position:'absolute',left:12,top:'50%',transform:'translateY(-50%)',fontSize:14}}>🔍</span>
                <input value={search} onChange={e=>setSearch(e.target.value)} placeholder={t.search} style={{width:'100%',padding:'11px 12px 11px 36px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
              </div>
              <div style={{display:'flex',gap:6}}>
                {(['all','upcoming','completed'] as const).map(f=>(
                  <button key={f} onClick={()=>setFilter(f)} style={{padding:'9px 14px',borderRadius:8,border:`1px solid ${filter===f?C.primary:C.border}`,background:filter===f?`${C.primary}22`:C.card,color:filter===f?C.primary:C.sub,cursor:'pointer',fontSize:11,fontWeight:filter===f?700:400,fontFamily:'Inter,sans-serif'}}>
                    {f==='all'?t.all:f==='upcoming'?t.upcoming:t.completed}
                  </button>
                ))}
              </div>
            </div>

            {/* Exam List */}
            {loading?(
              <div style={{textAlign:'center',padding:'60px 0',color:C.sub}}>
                <div style={{fontSize:36,marginBottom:12,animation:'pulse 1.5s infinite'}}>📝</div>
                <div>Loading exams...</div>
              </div>
            ):filtered.length===0?(
              <div style={{textAlign:'center',padding:'60px 20px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:20,border:`1px solid ${C.border}`}}>
                <svg width="80" height="80" viewBox="0 0 80 80" style={{display:'block',margin:'0 auto 16px'}} fill="none">
                  <rect x="10" y="15" width="60" height="50" rx="6" stroke="#4D9FFF" strokeWidth="1.5"/>
                  <path d="M10 30h60" stroke="#4D9FFF" strokeWidth="1"/>
                  <circle cx="40" cy="50" r="10" stroke="#4D9FFF" strokeWidth="1.5"/>
                  <path d="M35 50 L38 53 L45 46" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <div style={{fontSize:16,fontWeight:700,color:dm?C.text:'#0F172A',marginBottom:6}}>{t.noExam}</div>
                <div style={{fontSize:12,color:C.sub}}>{lang==='en'?'Check back later for scheduled exams':'बाद में निर्धारित परीक्षाओं के लिए जांचें'}</div>
              </div>
            ):(
              filtered.map((e:any)=><ExamCard key={e._id} exam={e} dm={dm} lang={lang} t={t}/>)
            )}

            {/* NEET Countdown */}
            <div style={{background:'linear-gradient(135deg,rgba(255,215,0,0.08),rgba(0,22,40,0.9))',border:`1px solid rgba(255,215,0,0.2)`,borderRadius:20,padding:24,marginTop:24,textAlign:'center',position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',inset:0,opacity:.03}}>
                <svg width="100%" height="100%" viewBox="0 0 600 150"><text x="50%" y="80%" textAnchor="middle" fontSize="100" fontFamily="Playfair Display,serif" fontWeight="700" fill="#FFD700">NEET</text></svg>
              </div>
              <div style={{fontSize:13,color:C.gold,fontWeight:600,marginBottom:4}}>🏆 NEET 2026</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:dm?C.text:'#0F172A',marginBottom:4}}>
                {lang==='en'?`${Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/(1000*60*60*24)))} Days Remaining`:`${Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/(1000*60*60*24)))} दिन शेष`}
              </div>
              <div style={{fontSize:12,color:C.sub}}>{lang==='en'?'NEET 2026 — May 3, 2026 · 180 Questions · 720 Marks':'NEET 2026 — 3 मई 2026 · 180 प्रश्न · 720 अंक'}</div>
              <div style={{display:'flex',gap:10,justifyContent:'center',marginTop:16,flexWrap:'wrap'}}>
                <a href="/my-exams" style={{padding:'8px 18px',background:`${C.gold}22`,border:`1px solid ${C.gold}44`,color:C.gold,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{lang==='en'?'📝 Practice Tests':'📝 अभ्यास परीक्षाएं'}</a>
                <a href="/pyq-bank" style={{padding:'8px 18px',background:`${C.primary}22`,border:`1px solid ${C.primary}44`,color:C.primary,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{lang==='en'?'📚 PYQ Bank':'📚 पिछले वर्ष के प्रश्न'}</a>
              </div>
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
