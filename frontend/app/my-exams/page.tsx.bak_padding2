'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function TestTubeSVG() {
  return (
    <svg width="55" height="110" viewBox="0 0 55 110" fill="none" style={{animation:'floatR 5s ease-in-out infinite',flexShrink:0}}>
      <rect x="18" y="5" width="19" height="65" rx="3" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
      <path d="M18 70 Q18 100 27.5 100 Q37 100 37 70Z" stroke="#4D9FFF" strokeWidth="1.5" fill="rgba(77,159,255,0.2)"/>
      <rect x="13" y="5" width="5" height="5" fill="#4D9FFF" rx="1"/>
      <rect x="37" y="5" width="5" height="5" fill="#4D9FFF" rx="1"/>
      <line x1="18" y1="50" x2="37" y2="50" stroke="rgba(77,159,255,0.4)" strokeWidth="1" strokeDasharray="2 2"/>
      <line x1="18" y1="60" x2="37" y2="60" stroke="rgba(77,159,255,0.4)" strokeWidth="1" strokeDasharray="2 2"/>
      <circle cx="45" cy="15" r="4" fill="#FFD700" opacity=".7"/>
      <circle cx="10" cy="40" r="3" fill="#00C48C" opacity=".7"/>
      <circle cx="8" cy="20" r="2" fill="#FF6B9D" opacity=".6"/>
    </svg>
  )
}

function MyExamsContent() {
  const {lang,darkMode:dm,token}=useShell()
  const [exams,  setExams]  = useState<any[]>([])
  const [filter, setFilter] = useState<'all'|'upcoming'|'completed'>('all')
  const [search, setSearch] = useState('')
  const [loading,setLoading]= useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setExams(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const now=new Date()
  const filtered=exams.filter(e=>{
    const match=!search||e.title?.toLowerCase().includes(search.toLowerCase())
    if(filter==='upcoming') return match&&new Date(e.scheduledAt)>now
    if(filter==='completed') return match&&new Date(e.scheduledAt)<=now
    return match
  })
  const upcoming=exams.filter(e=>new Date(e.scheduledAt)>now)
  const completed=exams.filter(e=>new Date(e.scheduledAt)<=now)
  const daysLeft=Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/86400000))

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📝 {t('My Exams','मेरी परीक्षाएं')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Upcoming & completed exams — your NEET journey documented','आगामी और पूर्ण परीक्षाएं — आपकी NEET यात्रा दर्ज')}</div>

      {/* Banner with TestTube SVG */}
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.22)',borderRadius:20,padding:20,marginBottom:22,display:'flex',alignItems:'center',gap:16,flexWrap:'wrap',position:'relative',overflow:'hidden',boxShadow:'0 4px 24px rgba(0,0,0,.2)'}}>
        <TestTubeSVG/>
        <div style={{flex:1}}>
          <div style={{fontSize:15,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:6}}>{t('"Every exam is a stepping stone — not a stumbling block."','"हर परीक्षा एक सीढ़ी है — रुकावट नहीं।"')}</div>
          <div style={{display:'flex',gap:12,flexWrap:'wrap'}}>
            <div style={{textAlign:'center',padding:'8px 14px',background:'rgba(77,159,255,.1)',borderRadius:10,border:`1px solid ${C.border}`}}>
              <div style={{fontWeight:800,fontSize:18,color:C.primary}}>{upcoming.length}</div>
              <div style={{fontSize:9,color:C.sub}}>{t('Upcoming','आगामी')}</div>
            </div>
            <div style={{textAlign:'center',padding:'8px 14px',background:'rgba(0,196,140,.08)',borderRadius:10,border:'1px solid rgba(0,196,140,.2)'}}>
              <div style={{fontWeight:800,fontSize:18,color:C.success}}>{completed.length}</div>
              <div style={{fontSize:9,color:C.sub}}>{t('Completed','पूर्ण')}</div>
            </div>
            <div style={{textAlign:'center',padding:'8px 14px',background:'rgba(255,215,0,.08)',borderRadius:10,border:'1px solid rgba(255,215,0,.2)'}}>
              <div style={{fontWeight:800,fontSize:18,color:C.gold}}>{daysLeft}</div>
              <div style={{fontSize:9,color:C.sub}}>{t('Days to NEET','NEET तक')}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Search + Filter */}
      <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap'}}>
        <div style={{position:'relative',flex:1,minWidth:200}}>
          <span style={{position:'absolute',left:12,top:'50%',transform:'translateY(-50%)',fontSize:13}}>🔍</span>
          <input value={search} onChange={e=>setSearch(e.target.value)} placeholder={t('Search exams...','परीक्षा खोजें...')} style={{width:'100%',padding:'10px 12px 10px 34px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
        </div>
        <div style={{display:'flex',gap:7}}>
          {(['all','upcoming','completed']as const).map(f=>(
            <button key={f} onClick={()=>setFilter(f)} style={{padding:'9px 14px',borderRadius:9,border:`1px solid ${filter===f?C.primary:C.border}`,background:filter===f?`${C.primary}22`:C.card,color:filter===f?C.primary:C.sub,cursor:'pointer',fontSize:11,fontWeight:filter===f?700:400,fontFamily:'Inter,sans-serif',transition:'all .2s'}}>
              {f==='all'?t('All','सभी'):f==='upcoming'?t('Upcoming','आगामी'):t('Completed','पूर्ण')}
            </button>
          ))}
        </div>
      </div>

      {/* Exam cards */}
      {loading?<div style={{textAlign:'center',padding:'50px',color:C.sub}}><div style={{fontSize:36,animation:'pulse 1.5s infinite'}}>📝</div></div>:
        filtered.length===0?(
          <div style={{textAlign:'center',padding:'60px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`,backdropFilter:'blur(14px)'}}>
            <svg width="80" height="80" viewBox="0 0 80 80" style={{display:'block',margin:'0 auto 14px'}} fill="none">
              <rect x="10" y="12" width="60" height="56" rx="6" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
              <path d="M10 28h60" stroke="#4D9FFF" strokeWidth="1"/>
              <circle cx="25" cy="20" r="4" fill="#4D9FFF"/>
              <circle cx="55" cy="20" r="4" fill="#4D9FFF"/>
              <path d="M25 44h30M25 54h20" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
            <div style={{fontWeight:700,fontSize:16,color:dm?C.text:C.textL,marginBottom:6}}>{t('No exams found','कोई परीक्षा नहीं मिली')}</div>
            <div style={{fontSize:12,color:C.sub}}>{t('Scheduled exams will appear here. Check back soon!','निर्धारित परीक्षाएं यहां दिखेंगी। जल्द जांचें!')}</div>
          </div>
        ):filtered.map((e:any)=>{
          const ed=new Date(e.scheduledAt)
          const diff=ed.getTime()-Date.now()
          const isLive=diff>-60000*e.duration&&diff<0
          const isUp=diff>0
          const dLeft=Math.ceil(diff/86400000)
          const sCol=isLive?C.danger:isUp?C.primary:C.sub
          const sTxt=isLive?'🔴 LIVE':isUp?dLeft===0?t('Today!','आज!'):t(`In ${dLeft} days`,`${dLeft} दिन में`):t('Completed','पूर्ण')
          return (
            <div key={e._id} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${isLive?C.danger:isUp?'rgba(77,159,255,.35)':C.border}`,borderRadius:16,padding:18,marginBottom:12,backdropFilter:'blur(14px)',position:'relative',overflow:'hidden',transition:'all .25s',boxShadow:'0 2px 14px rgba(0,0,0,.15)'}}>
              {isLive&&<div style={{position:'absolute',top:0,left:0,right:0,height:3,background:`linear-gradient(90deg,${C.danger},#ff8080)`,animation:'shimmer 1.5s infinite'}}/>}
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:10}}>
                <div style={{flex:1,minWidth:200}}>
                  <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:7,flexWrap:'wrap'}}>
                    <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL}}>{e.title}</span>
                    <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${sCol}22`,color:sCol,border:`1px solid ${sCol}44`,fontWeight:700}}>{sTxt}</span>
                    {e.category&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${C.gold}15`,color:C.gold,fontWeight:600}}>{e.category}</span>}
                  </div>
                  <div style={{display:'flex',gap:14,fontSize:11,color:C.sub,flexWrap:'wrap'}}>
                    <span>📅 {ed.toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})}</span>
                    <span>⏱️ {e.duration} {t('min','मिनट')}</span>
                    <span>🎯 {e.totalMarks} {t('marks','अंक')}</span>
                    {e.batch&&<span>📦 {e.batch}</span>}
                  </div>
                </div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap',alignItems:'center'}}>
                  {isLive&&<a href={`/exam/${e._id}`} style={{padding:'10px 18px',background:`linear-gradient(135deg,${C.danger},#cc0000)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:12,animation:'glow 1.5s infinite'}}>🔴 {t('Start Now','अभी शुरू')}</a>}
                  {isUp&&!isLive&&<a href={`/exam/${e._id}`} style={{padding:'10px 18px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:12,boxShadow:`0 4px 14px ${C.primary}44`}}>{t('Start Exam →','परीक्षा शुरू →')}</a>}
                  {!isUp&&!isLive&&<a href="/results" style={{padding:'9px 16px',background:'rgba(77,159,255,.12)',color:C.primary,border:`1px solid rgba(77,159,255,.3)`,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('View Result','परिणाम देखें')}</a>}
                </div>
              </div>
            </div>
          )
        })
      }

      {/* NEET Countdown */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.1),rgba(0,22,40,.92))',border:'1px solid rgba(255,215,0,.22)',borderRadius:20,padding:24,marginTop:16,textAlign:'center',position:'relative',overflow:'hidden',boxShadow:'0 4px 24px rgba(0,0,0,.2)'}}>
        <div style={{position:'absolute',inset:0,opacity:.03}}><svg width="100%" height="100%" viewBox="0 0 600 150"><text x="50%" y="75%" textAnchor="middle" fontSize="110" fontFamily="Playfair Display,serif" fontWeight="700" fill="#FFD700">NEET</text></svg></div>
        <div style={{fontSize:13,color:C.gold,fontWeight:700,marginBottom:4}}>🏆 NEET 2026 Countdown</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:dm?C.text:C.textL,marginBottom:6}}>
          <span style={{color:C.gold,textShadow:`0 0 20px ${C.gold}66`,fontSize:28}}>{daysLeft}</span> {t('Days Remaining','दिन शेष')}
        </div>
        <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{t('NEET 2026 — May 3, 2026 · 180 Questions · 720 Marks','NEET 2026 — 3 मई 2026 · 180 प्रश्न · 720 अंक')}</div>
        <div style={{display:'flex',gap:10,justifyContent:'center',flexWrap:'wrap'}}>
          <a href="/pyq-bank" style={{padding:'8px 18px',background:`${C.gold}20`,border:`1px solid ${C.gold}44`,color:C.gold,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('📚 PYQ Bank','📚 PYQ बैंक')}</a>
          <a href="/revision" style={{padding:'8px 18px',background:`${C.primary}20`,border:`1px solid ${C.primary}44`,color:C.primary,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('🧠 Smart Revision','🧠 स्मार्ट रिवीजन')}</a>
        </div>
      </div>
    </div>
  )
}

export default function MyExamsPage() {
  return <StudentShell pageKey="my-exams"><MyExamsContent/></StudentShell>
}
