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
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [stats,   setStats]   = useState<any>(null)
  const [exams,   setExams]   = useState<any[]>([])
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(()=>{
    if(!token) return
    const h={Authorization:`Bearer ${token}`}
    Promise.all([
      fetch(`${API}/api/admin/stats`,{headers:h}).then(r=>r.ok?r.json():null).catch(()=>null),
      fetch(`${API}/api/exams`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([s,e,r])=>{ setStats(s); setExams(Array.isArray(e)?e:[]); setResults(Array.isArray(r)?r:[]); setLoading(false) })
  },[token])

  const name      = user?.name||'Student'
  const bestScore = results.length>0?Math.max(...results.map((r:any)=>r.score||0)):null
  const bestRank  = results.length>0?Math.min(...results.map((r:any)=>r.rank||99999)):null
  const daysLeft  = Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/(86400000)))
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      {/* Hero Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.20),rgba(77,159,255,.08))',border:'1px solid rgba(77,159,255,.25)',borderRadius:20,padding:'24px 20px',marginBottom:24,position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',right:-20,top:-20,fontSize:120,opacity:.05}}>⬡</div>
        <div style={{fontSize:12,color:C.primary,fontWeight:600,marginBottom:4}}>{t('Good Morning ☀️','शुभ प्रभात ☀️')}</div>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:dm?C.text:C.textL,margin:'0 0 6px'}}>
          {t('Welcome back,','वापसी पर स्वागत,')} <span style={{color:C.primary}}>{name}</span> 👋
        </h1>
        <p style={{fontSize:13,color:C.sub,marginBottom:16}}>{t('Your NEET preparation dashboard — Stay focused, stay ranked.','आपका NEET तैयारी डैशबोर्ड — केंद्रित रहें, रैंक पाएं।')}</p>
        <div style={{background:'rgba(77,159,255,.07)',border:'1px solid rgba(77,159,255,.15)',borderRadius:10,padding:'10px 14px',maxWidth:520,marginBottom:16}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600}}>{t('"Success is not given, it is earned — one test at a time."','"सफलता दी नहीं जाती, कमाई जाती है — एक परीक्षा एक कदम।"')}</div>
        </div>
        <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
          {[[t('📝 My Exams','📝 मेरी परीक्षाएं'),'/my-exams',C.primary],[t('📈 Results','📈 परिणाम'),'/results',C.success],[t('🧠 Revision','🧠 रिवीजन'),'/revision','#A78BFA'],[t('🎯 Goals','🎯 लक्ष्य'),'/goals',C.gold]].map(([l,h,c])=>(
            <a key={String(h)} href={String(h)} style={{padding:'8px 14px',background:`${c}22`,border:`1px solid ${c}44`,color:String(c),borderRadius:20,textDecoration:'none',fontSize:12,fontWeight:600}}>{String(l)}</a>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:20}}>
        <StatCard dm={dm} icon="🏆" label={t('Best Rank','सर्वश्रेष्ठ रैंक')} value={bestRank&&bestRank<99999?`#${bestRank}`:'—'} col={C.gold}/>
        <StatCard dm={dm} icon="📊" label={t('Best Score','सर्वश्रेष्ठ स्कोर')} value={bestScore?`${bestScore}/720`:'—'} col={C.primary}/>
        <StatCard dm={dm} icon="🔥" label={t('Day Streak','दिन स्ट्रीक')} value={`${user?.streak||0}`} col="#FF6B6B" sub={t('Keep it up!','जारी रखें!')}/>
        <StatCard dm={dm} icon="⏳" label={t('Days to NEET','NEET तक दिन')} value={`${daysLeft}`} col={C.warn} sub="NEET 2026"/>
      </div>
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:24}}>
        <StatCard dm={dm} icon="🎯" label={t('Accuracy','सटीकता')} value={stats?.avgAccuracy?`${stats.avgAccuracy}%`:'—'} col={C.success}/>
        <StatCard dm={dm} icon="📝" label={t('Tests Given','दिए टेस्ट')} value={results.length||0} col={C.primary}/>
        <StatCard dm={dm} icon="🎖️" label={t('Badges','बैज')} value={user?.badges?.length||0} col="#A78BFA"/>
        <StatCard dm={dm} icon="📅" label={t('Upcoming Exams','आगामी परीक्षाएं')} value={exams.filter((e:any)=>new Date(e.scheduledAt)>new Date()).length} col="#FF6B9D"/>
      </div>

      {/* Subject Performance */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:20,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:dm?C.text:C.textL,marginBottom:14}}>📚 {t('Subject Performance','विषय प्रदर्शन')}</div>
        {[{name:t('Physics','भौतिकी'),icon:'⚛️',sc:results[0]?.subjectScores?.physics||148,tot:180,col:'#00B4FF'},{name:t('Chemistry','रसायन'),icon:'🧪',sc:results[0]?.subjectScores?.chemistry||152,tot:180,col:'#FF6B9D'},{name:t('Biology','जीव विज्ञान'),icon:'🧬',sc:results[0]?.subjectScores?.biology||310,tot:360,col:'#00E5A0'}].map(s=>{
          const p=Math.round((s.sc/s.tot)*100)
          return (
            <div key={s.name} style={{marginBottom:14}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:6,fontSize:12}}>
                <span style={{fontWeight:600,color:s.col}}>{s.icon} {s.name}</span>
                <span style={{color:C.sub}}>{s.sc}/{s.tot} <span style={{color:s.col,fontWeight:700}}>({p}%)</span></span>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:10,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${p}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:6,transition:'width .8s'}}/>
              </div>
            </div>
          )
        })}
      </div>

      {/* 2-col grid */}
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>📅 {t('Upcoming Exams','आगामी परीक्षाएं')}</div>
            <a href="/my-exams" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('View All →','सब देखें →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'20px 0',fontSize:12}}>⟳ Loading...</div>:
            exams.filter((e:any)=>new Date(e.scheduledAt)>new Date()).length===0
              ?<div style={{textAlign:'center',padding:'24px 0',color:C.sub,fontSize:12}}><div style={{fontSize:28,marginBottom:8}}>📭</div>{t('No upcoming exams','कोई आगामी परीक्षा नहीं')}</div>
              :exams.filter((e:any)=>new Date(e.scheduledAt)>new Date()).slice(0,3).map((e:any)=>(
                <div key={e._id} style={{padding:'8px 0',borderBottom:`1px solid ${C.border}`,fontSize:12}}>
                  <div style={{fontWeight:600,color:dm?C.text:C.textL}}>{e.title}</div>
                  <div style={{color:C.sub,fontSize:10,marginTop:2}}>{new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})} · {e.duration} min</div>
                  <a href={`/exam/${e._id}`} style={{display:'inline-block',marginTop:4,padding:'3px 10px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:6,fontSize:10,textDecoration:'none',fontWeight:600}}>{t('Start →','शुरू →')}</a>
                </div>
              ))
          }
        </div>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>🏅 {t('Recent Results','हालिया परिणाम')}</div>
            <a href="/results" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('View All →','सब देखें →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'20px 0',fontSize:12}}>⟳ Loading...</div>:
            results.length===0
              ?<div style={{textAlign:'center',padding:'24px 0',color:C.sub,fontSize:12}}><div style={{fontSize:28,marginBottom:8}}>⭐</div>{t('No results yet. Give your first exam!','पहली परीक्षा दें!')}</div>
              :results.slice(0,3).map((r:any)=>(
                <div key={r._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'8px 0',borderBottom:`1px solid ${C.border}`}}>
                  <div style={{fontSize:12}}>
                    <div style={{fontWeight:600,color:dm?C.text:C.textL}}>{r.examTitle||'—'}</div>
                    <div style={{color:C.sub,fontSize:10,marginTop:1}}>#{r.rank||'—'} AIR · {r.percentile||'—'}%ile</div>
                  </div>
                  <div style={{textAlign:'right'}}>
                    <div style={{fontWeight:800,fontSize:16,color:C.primary}}>{r.score}</div>
                    <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                  </div>
                </div>
              ))
          }
        </div>
      </div>

      {/* Pro Tip + Quick Access */}
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
        <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.08),rgba(0,22,40,.8))',border:`1px solid rgba(255,215,0,.2)`,borderRadius:16,padding:18}}>
          <div style={{fontWeight:700,fontSize:13,color:C.gold,marginBottom:8}}>💡 {t('Pro Tip','प्रो टिप')}</div>
          <div style={{fontSize:12,color:dm?C.text:C.textL,lineHeight:1.6}}>{t('Revise your weak chapters before the next test for best results.','सर्वोत्तम परिणाम के लिए अगले टेस्ट से पहले कमजोर अध्याय दोहराएं।')}</div>
          <div style={{display:'flex',gap:8,marginTop:12,flexWrap:'wrap'}}>
            <a href="/revision" style={{fontSize:11,padding:'5px 12px',background:`${C.primary}22`,border:`1px solid ${C.primary}44`,color:C.primary,borderRadius:6,textDecoration:'none',fontWeight:600}}>{t('Revise Now →','अभी रिवाइज →')}</a>
            <a href="/pyq-bank" style={{fontSize:11,padding:'5px 12px',background:`${C.gold}22`,border:`1px solid ${C.gold}44`,color:C.gold,borderRadius:6,textDecoration:'none',fontWeight:600}}>{t('PYQ Bank →','पिछले प्रश्न →')}</a>
          </div>
        </div>
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
          <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:10}}>⚡ {t('Quick Access','त्वरित एक्सेस')}</div>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
            {[['📝',t('My Exams','परीक्षाएं'),'/my-exams'],['📚',t('PYQ Bank','PYQ बैंक'),'/pyq-bank'],['🧠',t('Revision','रिवीजन'),'/revision'],['🎯',t('Goals','लक्ष्य'),'/goals']].map(([ic,label,href])=>(
              <a key={String(href)} href={String(href)} style={{display:'flex',alignItems:'center',gap:6,padding:'10px',background:'rgba(77,159,255,.07)',border:`1px solid ${C.border}`,borderRadius:10,textDecoration:'none',color:dm?C.text:C.textL,fontSize:12,fontWeight:600}}>
                <span style={{fontSize:16}}>{ic}</span><span>{label}</span>
              </a>
            ))}
          </div>
        </div>
      </div>

      {/* Footer Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.15),rgba(77,159,255,.05))',border:'1px solid rgba(77,159,255,.15)',borderRadius:20,padding:'24px 20px',textAlign:'center',position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',inset:0,opacity:.03,overflow:'hidden'}}><svg width="100%" height="80" viewBox="0 0 600 80"><text x="50%" y="55" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="48" fontWeight="700" fill="#4D9FFF">PROVE YOUR RANK</text></svg></div>
        <div style={{fontSize:18,color:C.primary,fontFamily:'Playfair Display,serif',fontWeight:700,marginBottom:4}}>{t("You're on the right path! 🚀","आप सही रास्ते पर हैं! 🚀")}</div>
        <div style={{fontSize:12,color:C.sub}}>{t(`${daysLeft} days remaining for NEET 2026 — Make every day count!`,`NEET 2026 के लिए ${daysLeft} दिन शेष — हर दिन सार्थक बनाएं!`)}</div>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  return <StudentShell pageKey="dashboard"><DashboardContent/></StudentShell>
}
