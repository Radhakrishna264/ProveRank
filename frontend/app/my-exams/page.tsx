'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function MyExamsContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [exams,   setExams]   = useState<any[]>([])
  const [filter,  setFilter]  = useState<'all'|'upcoming'|'completed'>('all')
  const [search,  setSearch]  = useState('')
  const [loading, setLoading] = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}})
      .then(r=>r.ok?r.json():[]).then(d=>{setExams(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const now = new Date()
  const filtered = exams.filter(e=>{
    const matchSearch = !search||e.title?.toLowerCase().includes(search.toLowerCase())
    if(filter==='upcoming')  return matchSearch && new Date(e.scheduledAt)>now
    if(filter==='completed') return matchSearch && new Date(e.scheduledAt)<=now
    return matchSearch
  })
  const upcoming  = exams.filter(e=>new Date(e.scheduledAt)>now)
  const completed = exams.filter(e=>new Date(e.scheduledAt)<=now)
  const daysLeft  = Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/86400000))

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📝 {t('My Exams','मेरी परीक्षाएं')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Upcoming & completed exams','आगामी और पूर्ण परीक्षाएं')}</div>

      {/* Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.85))',border:'1px solid rgba(77,159,255,.2)',borderRadius:20,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:18,flexWrap:'wrap',position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',right:14,opacity:.08}}><svg width="120" height="90" viewBox="0 0 120 90" fill="none"><rect x="10" y="10" width="100" height="70" rx="6" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/><path d="M10 28h100" stroke="#4D9FFF" strokeWidth="1"/><circle cx="22" cy="19" r="4" fill="#FF4D4D"/><circle cx="36" cy="19" r="4" fill="#FFD700"/><circle cx="50" cy="19" r="4" fill="#00C48C"/><rect x="20" y="38" width="80" height="5" rx="2" fill="#4D9FFF" opacity=".5"/><rect x="20" y="50" width="60" height="5" rx="2" fill="#4D9FFF" opacity=".3"/></svg></div>
        <div style={{flex:1}}>
          <div style={{fontSize:14,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Every exam is a stepping stone — not a stumbling block."','"हर परीक्षा एक सीढ़ी है — रुकावट नहीं।"')}</div>
        </div>
        <div style={{display:'flex',gap:10}}>
          <div style={{textAlign:'center',padding:'10px 16px',background:'rgba(77,159,255,.1)',borderRadius:12,border:`1px solid ${C.border}`}}>
            <div style={{fontWeight:800,fontSize:20,color:C.primary}}>{upcoming.length}</div>
            <div style={{fontSize:10,color:C.sub}}>{t('Upcoming','आगामी')}</div>
          </div>
          <div style={{textAlign:'center',padding:'10px 16px',background:'rgba(0,196,140,.08)',borderRadius:12,border:'1px solid rgba(0,196,140,.2)'}}>
            <div style={{fontWeight:800,fontSize:20,color:C.success}}>{completed.length}</div>
            <div style={{fontSize:10,color:C.sub}}>{t('Completed','पूर्ण')}</div>
          </div>
        </div>
      </div>

      {/* Search + Filter */}
      <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap'}}>
        <div style={{position:'relative',flex:1,minWidth:200}}>
          <span style={{position:'absolute',left:12,top:'50%',transform:'translateY(-50%)',fontSize:13}}>🔍</span>
          <input value={search} onChange={e=>setSearch(e.target.value)} placeholder={t('Search exams...','परीक्षा खोजें...')} style={{width:'100%',padding:'10px 12px 10px 34px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
        </div>
        <div style={{display:'flex',gap:6}}>
          {(['all','upcoming','completed'] as const).map(f=>(
            <button key={f} onClick={()=>setFilter(f)} style={{padding:'9px 14px',borderRadius:8,border:`1px solid ${filter===f?C.primary:C.border}`,background:filter===f?`${C.primary}22`:C.card,color:filter===f?C.primary:C.sub,cursor:'pointer',fontSize:11,fontWeight:filter===f?700:400,fontFamily:'Inter,sans-serif'}}>
              {f==='all'?t('All','सभी'):f==='upcoming'?t('Upcoming','आगामी'):t('Completed','पूर्ण')}
            </button>
          ))}
        </div>
      </div>

      {/* Exam List */}
      {loading ? (
        <div style={{textAlign:'center',padding:'50px',color:C.sub}}><div style={{fontSize:36,marginBottom:10,animation:'pulse 1.5s infinite'}}>📝</div><div>{t('Loading exams...','परीक्षाएं लोड हो रही हैं...')}</div></div>
      ) : filtered.length===0 ? (
        <div style={{textAlign:'center',padding:'50px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`}}>
          <div style={{fontSize:40,marginBottom:12}}>📭</div>
          <div style={{fontWeight:700,fontSize:16,color:dm?C.text:C.textL,marginBottom:6}}>{t('No exams found','कोई परीक्षा नहीं मिली')}</div>
          <div style={{fontSize:12,color:C.sub}}>{t('Check back later for scheduled exams','बाद में निर्धारित परीक्षाओं के लिए जांचें')}</div>
        </div>
      ) : (
        filtered.map((e:any)=>{
          const ed = new Date(e.scheduledAt)
          const diff = ed.getTime()-Date.now()
          const isLive = diff>-60000*e.duration && diff<0
          const isUp   = diff>0
          const dLeft  = Math.ceil(diff/86400000)
          const statusCol = isLive?C.danger:isUp?C.primary:C.sub
          const statusTxt = isLive?'🔴 LIVE':isUp?dLeft===0?t('Today!','आज!'):t(`In ${dLeft} days`,`${dLeft} दिनों में`):t('Completed','पूर्ण')
          return (
            <div key={e._id} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${isLive?C.danger:isUp?'rgba(77,159,255,.35)':C.border}`,borderRadius:16,padding:18,marginBottom:10,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden',transition:'all .2s'}}>
              {isLive && <div style={{position:'absolute',top:0,left:0,right:0,height:3,background:`linear-gradient(90deg,${C.danger},#ff8080)`,animation:'shimmer 2s infinite'}}/>}
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:10}}>
                <div style={{flex:1,minWidth:200}}>
                  <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:6,flexWrap:'wrap'}}>
                    <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL}}>{e.title}</span>
                    <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${statusCol}22`,color:statusCol,border:`1px solid ${statusCol}44`,fontWeight:700}}>{statusTxt}</span>
                    {e.category&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${C.gold}15`,color:C.gold,fontWeight:600}}>{e.category}</span>}
                  </div>
                  <div style={{display:'flex',gap:12,fontSize:11,color:C.sub,flexWrap:'wrap'}}>
                    <span>📅 {ed.toLocaleDateString('en-IN',{day:'numeric',month:'short'})}</span>
                    <span>⏱️ {e.duration} {t('min','मिनट')}</span>
                    <span>🎯 {e.totalMarks} {t('marks','अंक')}</span>
                    {e.batch&&<span>📦 {e.batch}</span>}
                  </div>
                </div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap',alignItems:'center'}}>
                  {isLive && <a href={`/exam/${e._id}`} style={{padding:'9px 16px',background:`linear-gradient(135deg,${C.danger},#cc0000)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:12,animation:'glow 1.5s infinite'}}>🔴 {t('Start Now','अभी शुरू')}</a>}
                  {isUp&&!isLive && <a href={`/exam/${e._id}`} style={{padding:'9px 16px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:12}}>{t('Start Exam →','परीक्षा शुरू →')}</a>}
                  {!isUp&&!isLive && <a href="/results" style={{padding:'8px 14px',background:'rgba(77,159,255,.12)',color:C.primary,border:`1px solid rgba(77,159,255,.3)`,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('View Result','परिणाम देखें')}</a>}
                </div>
              </div>
            </div>
          )
        })
      )}

      {/* NEET Countdown */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.08),rgba(0,22,40,.9))',border:'1px solid rgba(255,215,0,.2)',borderRadius:18,padding:22,marginTop:20,textAlign:'center',position:'relative',overflow:'hidden'}}>
        <div style={{fontSize:13,color:C.gold,fontWeight:600,marginBottom:4}}>🏆 NEET 2026</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:dm?C.text:C.textL,marginBottom:4}}>{daysLeft} {t('Days Remaining','दिन शेष')}</div>
        <div style={{fontSize:12,color:C.sub}}>{t('NEET 2026 — May 3, 2026 · 180 Questions · 720 Marks','NEET 2026 — 3 मई 2026 · 180 प्रश्न · 720 अंक')}</div>
      </div>
    </div>
  )
}

export default function MyExamsPage() {
  return <StudentShell pageKey="my-exams"><MyExamsContent/></StudentShell>
}
