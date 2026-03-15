'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// Animated Rocket SVG
function RocketSVG() {
  return (
    <svg width="90" height="120" viewBox="0 0 90 120" fill="none" style={{animation:'float 4s ease-in-out infinite'}}>
      <defs><linearGradient id="rg" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stopColor="#4D9FFF"/><stop offset="100%" stopColor="#0055CC"/></linearGradient></defs>
      {/* Rocket body */}
      <path d="M45 10 C45 10 25 35 20 65 L70 65 C65 35 45 10 45 10Z" fill="url(#rg)"/>
      {/* Window */}
      <circle cx="45" cy="45" r="10" fill="rgba(255,255,255,0.25)" stroke="rgba(255,255,255,0.5)" strokeWidth="1.5"/>
      <circle cx="45" cy="45" r="6" fill="rgba(255,255,255,0.4)"/>
      {/* Fins */}
      <path d="M20 65 L8 80 L25 72Z" fill="#0055CC"/>
      <path d="M70 65 L82 80 L65 72Z" fill="#0055CC"/>
      {/* Flame */}
      <path d="M35 65 Q45 95 45 95 Q45 95 55 65Z" fill="#FFB84D" style={{animation:'pulse 0.5s ease-in-out infinite'}}/>
      <path d="M38 65 Q45 85 45 85 Q45 85 52 65Z" fill="#FFD700" style={{animation:'pulse 0.5s ease-in-out infinite 0.1s'}}/>
      {/* Stars around */}
      <circle cx="10" cy="30" r="2" fill="#FFD700" style={{animation:'pulse 2s infinite'}}/>
      <circle cx="80" cy="20" r="1.5" fill="#fff" style={{animation:'pulse 1.5s infinite'}}/>
      <circle cx="15" cy="55" r="1" fill="#4D9FFF" style={{animation:'pulse 2.5s infinite'}}/>
      <circle cx="78" cy="55" r="2" fill="#FFD700" style={{animation:'pulse 1.8s infinite'}}/>
    </svg>
  )
}

// Animated DNA SVG
function DNASVG() {
  return (
    <svg width="60" height="120" viewBox="0 0 60 120" fill="none" style={{animation:'floatR 5s ease-in-out infinite'}}>
      {Array.from({length:8},(_,i)=>{
        const y=i*16+8; const progress=i/8; const offset=Math.sin(progress*Math.PI*2)*20
        return (
          <g key={i}>
            <line x1={30-offset} y1={y} x2={30+offset} y2={y} stroke={i%2===0?'#4D9FFF':'#00C48C'} strokeWidth="2" strokeLinecap="round"/>
            <circle cx={30-offset} cy={y} r="3" fill={i%2===0?'#4D9FFF':'#00C48C'}/>
            <circle cx={30+offset} cy={y} r="3" fill={i%2===0?'#0055CC':'#00a87a'}/>
          </g>
        )
      })}
      <path d="M10 8 Q10 60 10 112" stroke="rgba(77,159,255,0.3)" strokeWidth="1.5" fill="none"/>
      <path d="M50 8 Q50 60 50 112" stroke="rgba(77,159,255,0.3)" strokeWidth="1.5" fill="none"/>
    </svg>
  )
}

function StatCard({icon,label,value,col,dm,sub}:{icon:string;label:string;value:any;col:string;dm:boolean;sub?:string}) {
  return (
    <div className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:'18px 16px',flex:1,minWidth:130,backdropFilter:'blur(14px)',position:'relative',overflow:'hidden',transition:'all .25s',textAlign:'center',boxShadow:'0 4px 16px rgba(0,0,0,.2)'}}>
      <div style={{position:'absolute',right:-8,bottom:-8,fontSize:48,opacity:.07,filter:'blur(2px)'}}>{icon}</div>
      <div style={{fontSize:26,marginBottom:8,display:'block'}}>{icon}</div>
      <div style={{fontSize:26,fontWeight:800,color:col,fontFamily:'Playfair Display,serif',lineHeight:1,textShadow:`0 0 20px ${col}44`}}>{value??'—'}</div>
      <div style={{fontSize:10,color:C.sub,marginTop:4,fontWeight:600,letterSpacing:.3}}>{label}</div>
      {sub&&<div style={{fontSize:9,color:col,marginTop:2,opacity:.85}}>{sub}</div>}
    </div>
  )
}

function DashboardContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [exams,   setExams]   = useState<any[]>([])
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    const h={Authorization:`Bearer ${token}`}
    Promise.all([
      fetch(`${API}/api/exams`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([e,r])=>{
      setExams(Array.isArray(e)?e:[])
      setResults(Array.isArray(r)?r:[])
      setLoading(false)
    })
  },[token])

  const name=user?.name||t('Student','छात्र')
  const bestScore=results.length?Math.max(...results.map((r:any)=>r.score||0)):null
  const bestRank=results.length?Math.min(...results.map((r:any)=>r.rank||99999)):null
  const daysLeft=Math.max(0,Math.ceil((new Date('2026-05-03').getTime()-Date.now())/86400000))
  const upcoming=exams.filter((e:any)=>new Date(e.scheduledAt)>new Date())
  const avgScore=results.length?Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length):null

  return (
    <div>
      {/* Hero Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.2),rgba(77,159,255,.08),rgba(0,0,0,0))',border:'1px solid rgba(77,159,255,.25)',borderRadius:22,padding:'24px 20px',marginBottom:24,position:'relative',overflow:'hidden',boxShadow:'0 4px 32px rgba(0,0,0,.25)'}}>
        {/* Animated BG hexagons */}
        <div style={{position:'absolute',right:-30,top:-20,fontSize:180,color:'rgba(77,159,255,.05)',lineHeight:1,animation:'spinSlow 30s linear infinite',userSelect:'none'}}>⬡</div>
        <div style={{position:'absolute',right:80,bottom:-20,fontSize:100,color:'rgba(77,159,255,.04)',lineHeight:1,animation:'spinSlow 20s linear infinite reverse',userSelect:'none'}}>⬡</div>

        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:16}}>
          <div style={{flex:1,minWidth:260}}>
            <div style={{fontSize:12,color:C.primary,fontWeight:600,marginBottom:6,display:'flex',alignItems:'center',gap:6}}>
              <span style={{animation:'pulse 2s infinite'}}>☀️</span> {t('Good Morning','शुभ प्रभात')}
            </div>
            <h1 style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,color:dm?C.text:C.textL,margin:'0 0 8px'}}>
              {t('Welcome back,','वापसी पर स्वागत,')} <span style={{color:C.primary,textShadow:`0 0 20px ${C.primary}66`}}>{name}</span> 👋
            </h1>
            <p style={{fontSize:12,color:C.sub,marginBottom:16,lineHeight:1.6}}>{t('Your NEET preparation dashboard — Stay focused, stay ranked.','आपका NEET डैशबोर्ड — केंद्रित रहें, रैंक पाएं।')}</p>

            {/* Motivational Quote SVG */}
            <div style={{background:'rgba(77,159,255,.07)',border:'1px solid rgba(77,159,255,.15)',borderRadius:12,padding:'12px 16px',marginBottom:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',left:0,top:0,bottom:0,width:3,background:`linear-gradient(180deg,${C.primary},#0055CC)`}}/>
              <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600,paddingLeft:8}}>
                {t('"Success is not given, it is earned — one test at a time."','"सफलता दी नहीं जाती, कमाई जाती है — एक परीक्षा एक कदम।"')}
              </div>
            </div>

            {/* Quick links */}
            <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
              {[[t('📝 My Exams','📝 परीक्षाएं'),'/my-exams',C.primary],[t('📈 Results','📈 परिणाम'),'/results',C.success],[t('🧠 Revision','🧠 रिवीजन'),'/revision',C.purple],[t('🎯 Goals','🎯 लक्ष्य'),'/goals',C.gold]].map(([l,h,c]:any)=>(
                <a key={h} href={h} style={{padding:'7px 14px',background:`${c}18`,border:`1px solid ${c}44`,color:c,borderRadius:20,textDecoration:'none',fontSize:12,fontWeight:600,transition:'all .2s'}}>{l}</a>
              ))}
            </div>
          </div>

          {/* Animated Rocket */}
          <div style={{flexShrink:0,opacity:.85}}><RocketSVG/></div>
        </div>
      </div>

      {/* Stats Row 1 */}
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:14}}>
        <StatCard dm={dm} icon="🏆" label={t('Best Rank','सर्वश्रेष्ठ रैंक')} value={bestRank&&bestRank<99999?`#${bestRank}`:'—'} col={C.gold}/>
        <StatCard dm={dm} icon="📊" label={t('Best Score','सर्वश्रेष्ठ स्कोर')} value={bestScore?`${bestScore}/720`:'—'} col={C.primary}/>
        <StatCard dm={dm} icon="📈" label={t('Avg Score','औसत स्कोर')} value={avgScore?`${avgScore}/720`:'—'} col={C.success}/>
        <StatCard dm={dm} icon="⏳" label={t('Days to NEET','NEET तक दिन')} value={daysLeft} col={C.warn} sub="NEET 2026"/>
      </div>
      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:24}}>
        <StatCard dm={dm} icon="📝" label={t('Tests Given','दिए टेस्ट')} value={results.length} col={C.primary}/>
        <StatCard dm={dm} icon="📅" label={t('Upcoming','आगामी')} value={upcoming.length} col={C.pink}/>
        <StatCard dm={dm} icon="🔥" label={t('Streak','स्ट्रीक')} value={`${user?.streak||0}d`} col={C.danger} sub={t('Keep going!','जारी रखें!')}/>
        <StatCard dm={dm} icon="🎖️" label={t('Badges','बैज')} value={user?.badges?.length||0} col={C.purple}/>
      </div>

      {/* Subject Performance */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:18,padding:20,marginBottom:20,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:16}}>
          <DNASVG/>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:dm?C.text:C.textL}}>{t('Subject Performance','विषय प्रदर्शन')}</div>
            <div style={{fontSize:11,color:C.sub,marginTop:2}}>{t('Based on your latest test','नवीनतम टेस्ट के आधार पर')}</div>
          </div>
        </div>
        {[
          {n:t('Physics','भौतिकी'),icon:'⚛️',sc:results[0]?.subjectScores?.physics,tot:180,col:'#00B4FF'},
          {n:t('Chemistry','रसायन'),icon:'🧪',sc:results[0]?.subjectScores?.chemistry,tot:180,col:'#FF6B9D'},
          {n:t('Biology','जीव विज्ञान'),icon:'🧬',sc:results[0]?.subjectScores?.biology,tot:360,col:'#00E5A0'},
        ].map(s=>{
          const p=s.sc!=null?Math.round((s.sc/s.tot)*100):0
          return (
            <div key={s.n} style={{marginBottom:14}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:6,fontSize:12}}>
                <span style={{fontWeight:700,color:s.col,display:'flex',alignItems:'center',gap:5}}>{s.icon} {s.n}</span>
                <span style={{color:C.sub}}>{s.sc!=null?(s.sc+'/'+s.tot):'—'} <span style={{color:s.col,fontWeight:700}}>({p}%)</span></span>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:8,height:11,overflow:'hidden',position:'relative'}}>
                <div style={{height:'100%',width:`${p}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:8,transition:'width .9s ease',boxShadow:`0 0 8px ${s.col}44`}}/>
                {p===0&&<div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',paddingLeft:8,fontSize:9,color:C.sub}}>{t('No data yet','अभी कोई डेटा नहीं')}</div>}
              </div>
            </div>
          )
        })}
      </div>

      {/* 2-col grid */}
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
        {/* Upcoming Exams */}
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>📅 {t('Upcoming','आगामी')}</div>
            <a href="/my-exams" style={{fontSize:10,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('All →','सब →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'14px 0',fontSize:12,animation:'pulse 1.5s infinite'}}>⟳</div>:
            upcoming.length===0?(
              <div style={{textAlign:'center',padding:'20px 0',color:C.sub}}>
                {/* Calendar SVG */}
                <svg width="50" height="50" viewBox="0 0 50 50" style={{display:'block',margin:'0 auto 8px'}} fill="none">
                  <rect x="5" y="10" width="40" height="34" rx="4" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                  <path d="M5 20h40" stroke="#4D9FFF" strokeWidth="1"/>
                  <circle cx="17" cy="14" r="3" fill="#4D9FFF"/>
                  <circle cx="33" cy="14" r="3" fill="#4D9FFF"/>
                  <circle cx="17" cy="30" r="2" fill="rgba(77,159,255,0.4)"/>
                  <circle cx="25" cy="30" r="2" fill="rgba(77,159,255,0.4)"/>
                  <circle cx="33" cy="30" r="2" fill="rgba(77,159,255,0.4)"/>
                </svg>
                <div style={{fontSize:11}}>{t('No upcoming exams','कोई परीक्षा नहीं')}</div>
              </div>
            ):upcoming.slice(0,3).map((e:any)=>(
              <div key={e._id} style={{padding:'8px 0',borderBottom:`1px solid ${C.border}`}}>
                <div style={{fontWeight:600,fontSize:12,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{e.title}</div>
                <div style={{color:C.sub,fontSize:10,marginTop:1}}>{new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})} · {e.duration}m</div>
                <a href={`/exam/${e._id}`} style={{display:'inline-block',marginTop:4,padding:'2px 9px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:5,fontSize:9,textDecoration:'none',fontWeight:600}}>{t('Start →','शुरू →')}</a>
              </div>
            ))
          }
        </div>

        {/* Recent Results */}
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:C.textL}}>🏅 {t('Results','परिणाम')}</div>
            <a href="/results" style={{fontSize:10,color:C.primary,textDecoration:'none',fontWeight:600}}>{t('All →','सब →')}</a>
          </div>
          {loading?<div style={{textAlign:'center',color:C.sub,padding:'14px 0',fontSize:12,animation:'pulse 1.5s infinite'}}>⟳</div>:
            results.length===0?(
              <div style={{textAlign:'center',padding:'20px 0',color:C.sub}}>
                {/* Star SVG */}
                <svg width="50" height="50" viewBox="0 0 50 50" style={{display:'block',margin:'0 auto 8px'}} fill="none">
                  <path d="M25 5L29 18H43L32 26L36 39L25 31L14 39L18 26L7 18H21Z" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
                  <path d="M25 12L28 20H36L30 25L32 33L25 28L18 33L20 25L14 20H22Z" fill="rgba(255,215,0,0.2)"/>
                </svg>
                <div style={{fontSize:11}}>{t('No results yet','अभी कोई परिणाम नहीं')}</div>
              </div>
            ):results.slice(0,3).map((r:any)=>(
              <div key={r._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'7px 0',borderBottom:`1px solid ${C.border}`}}>
                <div style={{fontSize:11,flex:1,overflow:'hidden'}}>
                  <div style={{fontWeight:600,color:dm?C.text:C.textL,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{r.examTitle||'—'}</div>
                  <div style={{color:C.sub,fontSize:9,marginTop:1}}>#{r.rank||'—'} · {r.percentile||'—'}%ile</div>
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

      {/* NEET Countdown Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.1),rgba(0,85,204,.15))',border:'1px solid rgba(255,215,0,.22)',borderRadius:20,padding:'22px 20px',marginBottom:20,position:'relative',overflow:'hidden',boxShadow:'0 4px 24px rgba(0,0,0,.2)'}}>
        {/* Animated orbit circles */}
        <div style={{position:'absolute',right:20,top:'50%',transform:'translateY(-50%)',width:80,height:80,borderRadius:'50%',border:'1px dashed rgba(255,215,0,.2)',animation:'spinSlow 20s linear infinite',pointerEvents:'none'}}/>
        <div style={{position:'absolute',right:30,top:'50%',transform:'translateY(-50%)',width:55,height:55,borderRadius:'50%',border:'1px dashed rgba(255,215,0,.3)',animation:'spinSlow 12s linear infinite reverse',pointerEvents:'none'}}/>
        <div style={{fontSize:13,color:C.gold,fontWeight:700,marginBottom:4}}>🏆 NEET 2026</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:dm?C.text:C.textL,marginBottom:4}}>
          <span style={{color:C.gold,textShadow:`0 0 20px ${C.gold}44`}}>{daysLeft}</span> {t('Days Remaining','दिन शेष')}
        </div>
        <div style={{fontSize:12,color:C.sub,marginBottom:14}}>{t('NEET 2026 — May 3, 2026 · 180 Questions · 720 Marks','NEET 2026 — 3 मई 2026 · 180 प्रश्न · 720 अंक')}</div>
        {/* Progress bar */}
        <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:8,overflow:'hidden',marginBottom:12}}>
          <div style={{height:'100%',width:`${Math.max(5,100-Math.round(daysLeft/365*100))}%`,background:`linear-gradient(90deg,${C.gold},#FF8C00)`,borderRadius:6,transition:'width .8s'}}/>
        </div>
        <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
          <a href="/my-exams" style={{padding:'8px 16px',background:`${C.gold}20`,border:`1px solid ${C.gold}44`,color:C.gold,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('📝 Practice Tests','📝 अभ्यास टेस्ट')}</a>
          <a href="/pyq-bank" style={{padding:'8px 16px',background:`${C.primary}20`,border:`1px solid ${C.primary}44`,color:C.primary,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('📚 PYQ Bank','📚 PYQ बैंक')}</a>
          <a href="/revision" style={{padding:'8px 16px',background:`${C.purple}20`,border:`1px solid ${C.purple}44`,color:C.purple,borderRadius:10,textDecoration:'none',fontWeight:600,fontSize:12}}>{t('🧠 Revise','🧠 रिवाइज')}</a>
        </div>
      </div>

      {/* Quick Access Grid */}
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(14px)',marginBottom:20}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:14}}>⚡ {t('Quick Access','त्वरित एक्सेस')}</div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(120px,1fr))',gap:10}}>
          {[['📝',t('My Exams','परीक्षाएं'),'/my-exams',C.primary],['📚',t('PYQ Bank','PYQ बैंक'),'/pyq-bank',C.gold],['🧠',t('Revision','रिवीजन'),'/revision',C.purple],['🎯',t('Goals','लक्ष्य'),'/goals',C.gold],['⚖️',t('Compare','तुलना'),'/compare',C.success],['📋',t('OMR View','OMR व्यू'),'/omr-view',C.pink]].map(([ic,label,href,col])=>(
            <a key={href as string} href={href as string} style={{display:'flex',flexDirection:'column',alignItems:'center',gap:6,padding:'14px 10px',background:`${col}0f`,border:`1px solid ${col}22`,borderRadius:12,textDecoration:'none',color:dm?C.text:C.textL,fontSize:11,fontWeight:600,transition:'all .2s',textAlign:'center'}}>
              <span style={{fontSize:22}}>{ic}</span>
              <span style={{color:col as string,fontSize:10}}>{label}</span>
            </a>
          ))}
        </div>
      </div>

      {/* Motivational Footer */}
      <div style={{background:'linear-gradient(135deg,rgba(0,85,204,.14),rgba(77,159,255,.05))',border:'1px solid rgba(77,159,255,.15)',borderRadius:20,padding:'26px 20px',textAlign:'center',position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',opacity:.04,overflow:'hidden'}}>
          <svg width="600" height="80" viewBox="0 0 600 80"><text x="50%" y="65" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="52" fontWeight="700" fill="#4D9FFF">PROVE YOUR RANK</text></svg>
        </div>
        <div style={{fontSize:20,color:C.primary,fontFamily:'Playfair Display,serif',fontWeight:700,marginBottom:6,textShadow:`0 0 30px ${C.primary}44`}}>
          {t("You're on the right path! 🚀","आप सही रास्ते पर हैं! 🚀")}
        </div>
        <div style={{fontSize:13,color:C.sub}}>{t(daysLeft+' days remaining for NEET 2026 — Make every day count!','NEET 2026 के लिए '+daysLeft+' दिन शेष — हर दिन सार्थक बनाएं!')}</div>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  return <StudentShell pageKey="dashboard"><DashboardContent/></StudentShell>
}
