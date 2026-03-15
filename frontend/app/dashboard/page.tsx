'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function StatCard({icon,label,value,sub,col=C.primary,dm}:{icon:string;label:string;value:any;sub?:string;col?:string;dm:boolean}) {
  return (
    <div className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:'18px 16px',flex:1,minWidth:130,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden',transition:'all .2s'}}>
      <div style={{position:'absolute',right:-8,bottom:-8,fontSize:50,opacity:.06}}>{icon}</div>
      <div style={{fontSize:24,marginBottom:8}}>{icon}</div>
      <div style={{fontSize:26,fontWeight:800,color:col,fontFamily:'Playfair Display,serif',lineHeight:1}}>{value??'—'}</div>
      <div style={{fontSize:11,color:C.sub,marginTop:4,fontWeight:600}}>{label}</div>
      {sub&&<div style={{fontSize:10,color:col,marginTop:2,opacity:.9}}>{sub}</div>}
    </div>
  )
}

function DashboardContent() {
  const {lang,darkMode:dm,user,toast,token} = useShell()
  const [exams,   setExams]   = useState<any[]>([])
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const t = (en:string,hi:string) => lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    const h={Authorization:`Bearer ${token}`}
    Promise.all([
      fetch(`${API}/api/exams`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([e,r])=>{ setExams(Array.isArray(e)?e:[]); setResults(Array.isArray(r)?r:[]); setLoading(false) })
  },[token])

  const name      = user?.name||t('Student','छात्र')
  const bestScore = results.length>0?Math.max(...results.map((r:any)=>r.score||0)):null
  const bestRank  = results.length>0?Math.min(...results.map((r:any)=>r.rank||99999)):null
  const daysLeft  = Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/86400000))
  const upcoming  = exams.filter((e:any)=>new Date(e.scheduledAt)>new Date())

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      {/* Hero */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.2),rgba(77,159,255,.08))',border:'1px solid rgba(77,159,255,.25)',borderRadius:20,padding:'24px 20px',marginBottom:24,position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',right:-20,top:-20,fontSize:120,opacity:.04}}>⬡</div>
        <div style={{fontSize:12,color:C.primary,fontWeight:600,marginBottom:4}}>{t('Good Morning ☀️','शुभ प्रभात ☀️')}</div>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:dm?C.text:C.textL,margin:'0 0 6px'}}>{t('Welcome back,','वापसी पर स्वागत,')} <span style={{color:C.primary}}>{name}</span> 👋</h1>
        <p style={{fontSize:13,color:C.sub,marginBottom:16}}>{t('Your NEET preparation dashboard — Stay focused, stay ranked.','आपका NEET तैयारी डैशबोर्ड — केंद्रित रहें, रैंक पाएं।')}</p>
        <div style={{background:'rgba(77,159,255,.07)',border:'1px solid rgba(77,159,255,.15)',borderRadius:10,padding:'10px 14px',marginBottom:14}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600}}>{t('"Success is not given, it is earned — one test at a time."','"सफलता दी नहीं जाती, कमाई जाती है — एक परीक्षा एक कदम।"')}</div>
        </div>
        <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
          {[[t('📝 My Exams','📝 मेरी परीक्षाएं'),'/my-exams',C.primary],[t('📈 Results','📈 परिणाम'),'/results',C.success],[t('🧠 Revision','🧠 रिवीजन'),'/revision','#A78BFA'],[t('🎯 Goals','🎯 लक्ष्य'),'/goals',C.gold]].map(([l,h,c])=>(
            <a key={String(h)} href={String(h)} style={{padding:'8px 14px',background:`${c}22`,border:`1px solid ${c}44`,color:String(c),borderRadius:20,textDecoration:'none',fontSize:12,fontWeight:600}}>{String(l)}</a>
          ))}
        </div>
      </div>

      {/* Stats Row 1 */}
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
        <StatCard dm={dm} icon="🏆" label={t('Best Rank','सर्वश्रेष्ठ रैंक')} value={bestRank&&bestRank<99999?`#${bestRank}`:'—'} col={C.gold}/>
        <StatCard dm={dm} icon="📊" label={t('Best Score','सर्वश्रेष्ठ स्कोर')} value={bestScore?`${bestScore}/720`:'—'} col={C.primary}/>
        <StatCard dm={dm} icon="🔥" label={t('Day Streak','दिन स्ट्रीक')} value={`${user?.streak||0}`} col="#FF6B6B" sub={t('Keep going!','जारी रखें!')}/>
        <StatCard dm={dm} icon="⏳" label={t('Days to NEET','NEET तक दिन')} value={`${daysLeft}`} col={C.warn} sub="NEET 2026"/>
      </div>
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:24}}>
        <StatCard dm={dm} icon="📝" label={t('Tests Given','दिए टेस्ट')} value={results.length} col={C.primary}/>
        <StatCard dm={dm} icon="📅" label={t('Upcoming','आगामी')} value={upcoming.length} col="#FF6B9D"/>
        <StatCard dm={dm} icon="🎖️" label={t('Badges','बैज')} value={user?.badges?.length||0} col="#A78BFA"/>
        <StatCard dm={dm} icon="🎯" label={t('Accuracy','सटीकता')} value={results.length>0?`${Math.round(results.reduce((a:number,r:any)=>a+(r.accuracy||0),0)/results.length)}%`:'—'} col={C.success}/>
      </div>

      {/* Subject Perf */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:20,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:dm?C.text:C.textL,marginBottom:14}}>📚 {t('Subject Performance','विषय प्रदर्शन')}</div>
        {[{name:t('Physics','भौतिकी'),icon:'⚛️',sc:results[0]?.subjectScores?.physics||0,tot:180,col:'#00B4FF'},{name:t('Chemistry','रसायन'),icon:'🧪',sc:results[0]?.subjectScores?.chemistry||0,tot:180,col:'#FF6B9D'},{name:t('Biology','जीव विज्ञान'),icon:'🧬',sc:results[0]?.subjectScores?.biology||0,tot:360,col:'#00E5A0'}].map(s=>{
          const p=s.sc?Math.round((s.sc/s.tot)*100):0
          return (
            <div key={s.name} style={{marginBottom:14}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:6,fontSize:12}}>
                <span style={{fontWeight:600,color:s.col}}>{s.icon} {s.name}</span>
                <span style={{color:C.sub}}>{s.sc||'—'}/{s.tot} <span style={{color:s.col,fontWeight:700}}>({p}%)</span></span>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:10,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${p}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:6,transition:'width .8s'}}/>
              </div>
            </div>
          )
        })}
      </div>

      {/* 2-col */}
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>📅 {t('Upcoming Exams','आगामी परीक्षाएं')}</div>
            <a href="/my-exams" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('View All →','सब →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'20px 0',fontSize:12,animation:'pulse 1s infinite'}}>⟳ Loading...</div>:
            upcoming.length===0
              ?<div style={{textAlign:'center',padding:'20px 0',color:C.sub,fontSize:12}}><div style={{fontSize:28,marginBottom:6}}>📭</div>{t('No upcoming exams','कोई आगामी परीक्षा नहीं')}<br/><a href="/my-exams" style={{color:C.primary,fontSize:11,fontWeight:600}}>{t('Check all exams →','सभी परीक्षाएं देखें →')}</a></div>
              :upcoming.slice(0,3).map((e:any)=>(
                <div key={e._id} style={{padding:'8px 0',borderBottom:`1px solid ${C.border}`,fontSize:12}}>
                  <div style={{fontWeight:600,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{e.title}</div>
                  <div style={{color:C.sub,fontSize:10,marginTop:1}}>{new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})} · {e.duration} min</div>
                  <a href={`/exam/${e._id}`} style={{display:'inline-block',marginTop:4,padding:'3px 10px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:6,fontSize:10,textDecoration:'none',fontWeight:600}}>{t('Start →','शुरू →')}</a>
                </div>
              ))
          }
        </div>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>🏅 {t('Recent Results','हालिया परिणाम')}</div>
            <a href="/results" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('View All →','सब →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'20px 0',fontSize:12,animation:'pulse 1s infinite'}}>⟳ Loading...</div>:
            results.length===0
              ?<div style={{textAlign:'center',padding:'20px 0',color:C.sub,fontSize:12}}><div style={{fontSize:28,marginBottom:6}}>⭐</div>{t('No results yet. Give your first exam!','पहली परीक्षा दें!')}</div>
              :results.slice(0,3).map((r:any)=>(
                <div key={r._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'8px 0',borderBottom:`1px solid ${C.border}`}}>
                  <div style={{fontSize:12,flex:1,overflow:'hidden'}}>
                    <div style={{fontWeight:600,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{r.examTitle||'—'}</div>
                    <div style={{color:C.sub,fontSize:10,marginTop:1}}>#{r.rank||'—'} AIR · {r.percentile||'—'}%ile</div>
                  </div>
                  <div style={{textAlign:'right',flexShrink:0,marginLeft:8}}>
                    <div style={{fontWeight:800,fontSize:16,color:C.primary}}>{r.score}</div>
                    <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                  </div>
                </div>
              ))
          }
        </div>
      </div>

      {/* Footer */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.15),rgba(77,159,255,.05))',border:'1px solid rgba(77,159,255,.15)',borderRadius:20,padding:'24px 20px',textAlign:'center'}}>
        <div style={{fontSize:18,color:C.primary,fontFamily:'Playfair Display,serif',fontWeight:700,marginBottom:4}}>{t("You're on the right path! 🚀","आप सही रास्ते पर हैं! 🚀")}</div>
        <div style={{fontSize:12,color:C.sub}}>{t(`${daysLeft} days remaining for NEET 2026 — Make every day count!`,`NEET 2026 के लिए ${daysLeft} दिन शेष — हर दिन सार्थक बनाएं!`)}</div>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  return <StudentShell pageKey="dashboard"><DashboardContent/></StudentShell>
}
