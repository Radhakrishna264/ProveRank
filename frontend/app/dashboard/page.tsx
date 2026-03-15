'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function StatCard({icon,label,value,col,dm,sub}:{icon:string;label:string;value:any;col:string;dm:boolean;sub?:string}) {
  return (
    <div className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:'16px',flex:1,minWidth:120,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden',transition:'all .2s',textAlign:'center'}}>
      <div style={{position:'absolute',right:-6,bottom:-6,fontSize:44,opacity:.06}}>{icon}</div>
      <div style={{fontSize:22,marginBottom:6}}>{icon}</div>
      <div style={{fontSize:24,fontWeight:800,color:col,fontFamily:'Playfair Display,serif',lineHeight:1}}>{value??'—'}</div>
      <div style={{fontSize:10,color:C.sub,marginTop:4,fontWeight:600}}>{label}</div>
      {sub&&<div style={{fontSize:9,color:col,marginTop:2,opacity:.85}}>{sub}</div>}
    </div>
  )
}

function DashboardContent() {
  const { lang, darkMode:dm, user, token } = useShell()
  const [exams,   setExams]   = useState<any[]>([])
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    const h = { Authorization:`Bearer ${token}` }
    Promise.all([
      fetch(`${API}/api/exams`,  {headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([e,r])=>{
      setExams(Array.isArray(e)?e:[])
      setResults(Array.isArray(r)?r:[])
      setLoading(false)
    })
  },[token])

  const name      = user?.name || t('Student','छात्र')
  const bestScore = results.length ? Math.max(...results.map((r:any)=>r.score||0)) : null
  const bestRank  = results.length ? Math.min(...results.map((r:any)=>r.rank||99999)) : null
  const daysLeft  = Math.max(0, Math.ceil((new Date('2026-05-03').getTime()-Date.now())/86400000))
  const upcoming  = exams.filter((e:any)=>new Date(e.scheduledAt)>new Date())

  return (
    <div>
      {/* Hero */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.18),rgba(77,159,255,.07))',border:'1px solid rgba(77,159,255,.22)',borderRadius:20,padding:'22px 20px',marginBottom:22,position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',right:-10,top:-10,fontSize:110,opacity:.04,lineHeight:1}}>⬡</div>
        <div style={{fontSize:12,color:C.primary,fontWeight:600,marginBottom:4}}>☀️ {t('Good Morning','शुभ प्रभात')}</div>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:dm?C.text:C.textL,margin:'0 0 6px'}}>
          {t('Welcome back,','वापसी पर स्वागत,')} <span style={{color:C.primary}}>{name}</span> 👋
        </h1>
        <p style={{fontSize:12,color:C.sub,marginBottom:14}}>{t('Your NEET preparation dashboard — Stay focused, stay ranked.','आपका NEET डैशबोर्ड — केंद्रित रहें, रैंक पाएं।')}</p>
        <div style={{background:'rgba(77,159,255,.07)',border:'1px solid rgba(77,159,255,.14)',borderRadius:10,padding:'9px 14px',marginBottom:14}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600}}>
            {t('"Success is not given, it is earned — one test at a time."','"सफलता दी नहीं जाती, कमाई जाती है।"')}
          </div>
        </div>
        <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
          {[[t('📝 My Exams','📝 परीक्षाएं'),'/my-exams',C.primary],[t('📈 Results','📈 परिणाम'),'/results',C.success],[t('🧠 Revision','🧠 रिवीजन'),C.purple],[t('🎯 Goals','🎯 लक्ष्य'),'/goals',C.gold]].map(([l,h,c]:any)=>(
            <a key={h||String(c)} href={typeof h==='string'&&h.startsWith('/')?h:'/revision'} style={{padding:'7px 14px',background:`${c}22`,border:`1px solid ${c}44`,color:c,borderRadius:20,textDecoration:'none',fontSize:12,fontWeight:600}}>{l}</a>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
        <StatCard dm={dm} icon="🏆" label={t('Best Rank','सर्वश्रेष्ठ रैंक')} value={bestRank&&bestRank<99999?`#${bestRank}`:'—'} col={C.gold}/>
        <StatCard dm={dm} icon="📊" label={t('Best Score','सर्वश्रेष्ठ स्कोर')} value={bestScore?`${bestScore}/720`:'—'} col={C.primary}/>
        <StatCard dm={dm} icon="🔥" label={t('Streak','स्ट्रीक')} value={`${user?.streak||0}d`} col={C.danger}/>
        <StatCard dm={dm} icon="⏳" label={t('Days to NEET','NEET तक दिन')} value={daysLeft} col={C.warn} sub="NEET 2026"/>
      </div>
      <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:22}}>
        <StatCard dm={dm} icon="📝" label={t('Tests Given','दिए टेस्ट')} value={results.length} col={C.primary}/>
        <StatCard dm={dm} icon="📅" label={t('Upcoming','आगामी')} value={upcoming.length} col="#FF6B9D"/>
        <StatCard dm={dm} icon="🎖️" label={t('Badges','बैज')} value={user?.badges?.length||0} col={C.purple}/>
        <StatCard dm={dm} icon="🎯" label={t('Accuracy','सटीकता')} value={results.length?`${Math.round(results.reduce((a:number,r:any)=>a+(r.accuracy||0),0)/results.length)}%`:'—'} col={C.success}/>
      </div>

      {/* Subject Performance */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:dm?C.text:C.textL,marginBottom:14}}>📚 {t('Subject Performance','विषय प्रदर्शन')}</div>
        {[
          {n:t('Physics','भौतिकी'),   icon:'⚛️', sc:results[0]?.subjectScores?.physics  ||0, tot:180, col:'#00B4FF'},
          {n:t('Chemistry','रसायन'),  icon:'🧪', sc:results[0]?.subjectScores?.chemistry||0, tot:180, col:'#FF6B9D'},
          {n:t('Biology','जीव विज्ञान'),icon:'🧬',sc:results[0]?.subjectScores?.biology  ||0, tot:360, col:'#00E5A0'},
        ].map(s=>{
          const p = s.sc ? Math.round((s.sc/s.tot)*100) : 0
          return (
            <div key={s.n} style={{marginBottom:12}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:5,fontSize:12}}>
                <span style={{fontWeight:600,color:s.col}}>{s.icon} {s.n}</span>
                <span style={{color:C.sub}}>{s.sc||'—'}/{s.tot} <span style={{color:s.col,fontWeight:700}}>({p}%)</span></span>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:9,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${p}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:6,transition:'width .8s ease'}}/>
              </div>
            </div>
          )
        })}
      </div>

      {/* 2 col */}
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:18}}>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:16,backdropFilter:'blur(12px)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>📅 {t('Upcoming Exams','आगामी परीक्षाएं')}</div>
            <a href="/my-exams" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('All →','सब →')}</a>
          </div>
          {loading ? <div style={{textAlign:'center',color:C.sub,padding:'16px 0',fontSize:12}}>⟳</div> :
            upcoming.length===0
              ? <div style={{textAlign:'center',padding:'16px 0',color:C.sub,fontSize:11}}>📭 {t('No upcoming exams','कोई परीक्षा नहीं')}</div>
              : upcoming.slice(0,3).map((e:any)=>(
                  <div key={e._id} style={{padding:'7px 0',borderBottom:`1px solid ${C.border}`,fontSize:12}}>
                    <div style={{fontWeight:600,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{e.title}</div>
                    <div style={{color:C.sub,fontSize:10,marginTop:1}}>{new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})} · {e.duration}m</div>
                    <a href={`/exam/${e._id}`} style={{display:'inline-block',marginTop:4,padding:'2px 8px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:5,fontSize:9,textDecoration:'none',fontWeight:600}}>{t('Start →','शुरू →')}</a>
                  </div>
                ))
          }
        </div>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:16,backdropFilter:'blur(12px)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>🏅 {t('Recent Results','हालिया परिणाम')}</div>
            <a href="/results" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('All →','सब →')}</a>
          </div>
          {loading ? <div style={{textAlign:'center',color:C.sub,padding:'16px 0',fontSize:12}}>⟳</div> :
            results.length===0
              ? <div style={{textAlign:'center',padding:'16px 0',color:C.sub,fontSize:11}}>⭐ {t('No results yet','अभी कोई परिणाम नहीं')}</div>
              : results.slice(0,3).map((r:any)=>(
                  <div key={r._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'7px 0',borderBottom:`1px solid ${C.border}`}}>
                    <div style={{fontSize:11,flex:1,overflow:'hidden'}}>
                      <div style={{fontWeight:600,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{r.examTitle||'—'}</div>
                      <div style={{color:C.sub,fontSize:9,marginTop:1}}>#{r.rank||'—'} · {r.percentile||'—'}%ile</div>
                    </div>
                    <div style={{textAlign:'right',flexShrink:0,marginLeft:8}}>
                      <div style={{fontWeight:800,fontSize:15,color:C.primary}}>{r.score}</div>
                      <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                    </div>
                  </div>
                ))
          }
        </div>
      </div>

      {/* Pro Tip + Quick */}
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:18}}>
        <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.08),rgba(0,22,40,.85))',border:'1px solid rgba(255,215,0,.2)',borderRadius:16,padding:16}}>
          <div style={{fontWeight:700,fontSize:13,color:C.gold,marginBottom:7}}>💡 {t('Pro Tip','प्रो टिप')}</div>
          <div style={{fontSize:12,color:dm?C.text:C.textL,lineHeight:1.6,marginBottom:10}}>{t('Revise weak chapters before the next test for best results.','अगले टेस्ट से पहले कमजोर अध्याय दोहराएं।')}</div>
          <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
            <a href="/revision" style={{fontSize:11,padding:'4px 10px',background:`${C.primary}22`,border:`1px solid ${C.primary}44`,color:C.primary,borderRadius:6,textDecoration:'none',fontWeight:600}}>{t('Revise →','रिवाइज →')}</a>
            <a href="/pyq-bank" style={{fontSize:11,padding:'4px 10px',background:`${C.gold}22`,border:`1px solid ${C.gold}44`,color:C.gold,borderRadius:6,textDecoration:'none',fontWeight:600}}>PYQ →</a>
          </div>
        </div>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:16,backdropFilter:'blur(12px)'}}>
          <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:10}}>⚡ {t('Quick Access','त्वरित एक्सेस')}</div>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:7}}>
            {[['📝',t('Exams','परीक्षाएं'),'/my-exams'],['📚','PYQ','/pyq-bank'],['🧠',t('Revise','रिवीजन'),'/revision'],['🎯',t('Goals','लक्ष्य'),'/goals']].map(([ic,label,href])=>(
              <a key={href} href={href} style={{display:'flex',alignItems:'center',gap:6,padding:'9px',background:'rgba(77,159,255,.07)',border:`1px solid ${C.border}`,borderRadius:9,textDecoration:'none',color:dm?C.text:C.textL,fontSize:11,fontWeight:600}}>
                <span style={{fontSize:14}}>{ic}</span><span>{label}</span>
              </a>
            ))}
          </div>
        </div>
      </div>

      {/* Footer Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.14),rgba(77,159,255,.05))',border:'1px solid rgba(77,159,255,.14)',borderRadius:18,padding:'22px 20px',textAlign:'center'}}>
        <div style={{fontSize:17,color:C.primary,fontFamily:'Playfair Display,serif',fontWeight:700,marginBottom:4}}>{t("You're on the right path! 🚀","आप सही रास्ते पर हैं! 🚀")}</div>
        <div style={{fontSize:12,color:C.sub}}>{t(`${daysLeft} days remaining for NEET 2026 — Make every day count!`,`NEET 2026 के लिए ${daysLeft} दिन शेष!`)}</div>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  return <StudentShell pageKey="dashboard"><DashboardContent/></StudentShell>
}
