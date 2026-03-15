'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const TR = {
  en:{
    hello:'Good Morning', title:'Welcome back', sub:'Your NEET preparation dashboard — Stay focused, stay ranked.',
    quote:'"Success is not given, it is earned — one test at a time."',
    quoteHi:'सफलता दी नहीं जाती, कमाई जाती है — एक परीक्षा एक कदम।',
    rank:'All India Rank', bestScore:'Best Score', streak:'Day Streak', pct:'Percentile',
    daysLeft:'Days to NEET', nextExam:'Next Exam', accuracy:'Accuracy', tests:'Tests Given',
    upcoming:'Upcoming Exams', recent:'Recent Results', subjects:'Subject Performance',
    health:'Platform Health', quick:'Quick Access', activity:'Recent Activity',
    tip:'Pro Tip', viewAll:'View All →', startExam:'Start Exam →', noExam:'No upcoming exams',
    noResult:'No results yet. Give your first exam!', proTip:'Revise your weak chapters before the next test for best results.',
    neet:'NEET 2026', target:'Days to Target', study:'Weekly Study Goal', badges:'Badges Earned',
  },
  hi:{
    hello:'शुभ प्रभात', title:'वापसी पर स्वागत', sub:'आपका NEET तैयारी डैशबोर्ड — केंद्रित रहें, रैंक पाएं।',
    quote:'"सफलता मिलती नहीं, कमानी पड़ती है — एक परीक्षा, एक कदम।"',
    quoteHi:'Success is not given, it is earned — one test at a time.',
    rank:'अखिल भारत रैंक', bestScore:'सर्वश्रेष्ठ स्कोर', streak:'दिन की स्ट्रीक', pct:'पर्सेंटाइल',
    daysLeft:'NEET तक दिन', nextExam:'अगली परीक्षा', accuracy:'सटीकता', tests:'दिए गए टेस्ट',
    upcoming:'आगामी परीक्षाएं', recent:'हालिया परिणाम', subjects:'विषय प्रदर्शन',
    health:'प्लेटफ़ॉर्म स्वास्थ्य', quick:'त्वरित एक्सेस', activity:'हालिया गतिविधि',
    tip:'प्रो टिप', viewAll:'सब देखें →', startExam:'परीक्षा शुरू करें →', noExam:'कोई आगामी परीक्षा नहीं',
    noResult:'अभी कोई परिणाम नहीं। पहली परीक्षा दें!', proTip:'सर्वोत्तम परिणाम के लिए अगले टेस्ट से पहले कमजोर अध्याय दोहराएं।',
    neet:'NEET 2026', target:'लक्ष्य तक दिन', study:'साप्ताहिक अध्ययन लक्ष्य', badges:'अर्जित बैज',
  }
}

const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

function StatCard({icon,label,value,sub,col=C.primary,dm}:{icon:string;label:string;value:any;sub?:string;col?:string;dm:boolean}) {
  return (
    <div className="card-h" style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:'18px 16px',flex:1,minWidth:130,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden',transition:'all .2s'}}>
      <div style={{position:'absolute',right:-8,bottom:-8,fontSize:50,opacity:.07}}>{icon}</div>
      <div style={{fontSize:24,marginBottom:8}}>{icon}</div>
      <div style={{fontSize:26,fontWeight:800,color:col,fontFamily:'Playfair Display,serif',lineHeight:1}}>{value??'—'}</div>
      <div style={{fontSize:11,color:C.sub,marginTop:4,fontWeight:600}}>{label}</div>
      {sub&&<div style={{fontSize:10,color:col,marginTop:2,opacity:.9}}>{sub}</div>}
    </div>
  )
}

export default function DashboardPage() {
  return (
    <StudentShell pageKey="dashboard">
      {({lang, darkMode:dm, user, toast, token}) => {
        const t = TR[lang]
        const [stats, setStats] = useState<any>(null)
        const [exams, setExams] = useState<any[]>([])
        const [results, setResults] = useState<any[]>([])
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          const h = {Authorization:`Bearer ${token}`}
          Promise.all([
            fetch(`${API}/api/admin/stats`,{headers:h}).then(r=>r.ok?r.json():null).catch(()=>null),
            fetch(`${API}/api/exams`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
            fetch(`${API}/api/results`,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
          ]).then(([s,e,r])=>{
            setStats(s); setExams(Array.isArray(e)?e:[]); setResults(Array.isArray(r)?r:[])
            setLoading(false)
          })
        },[token])

        const name = user?.name || 'Student'
        const bestScore = results.length>0?Math.max(...results.map((r:any)=>r.score||0)):null
        const bestRank = results.length>0?Math.min(...results.map((r:any)=>r.rank||99999)):null
        const streak = user?.streak || 0
        const neetDate = new Date('2026-05-03')
        const daysLeft = Math.max(0,Math.ceil((neetDate.getTime()-Date.now())/(1000*60*60*24)))

        return (
          <div style={{animation:'fadeIn .4s ease'}}>

            {/* Hero Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(0,85,204,0.20),rgba(77,159,255,0.08))',border:`1px solid rgba(77,159,255,0.25)`,borderRadius:20,padding:'24px 20px',marginBottom:24,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:-20,top:-20,fontSize:120,opacity:.05}}>⬡</div>
              <div style={{position:'absolute',right:60,bottom:-10,fontSize:80,opacity:.04}}>⬡</div>
              {/* Dashboard SVG Illustration */}
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.15}}>
                <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
                  <circle cx="60" cy="50" r="40" stroke="#4D9FFF" strokeWidth="1.5" strokeDasharray="4 3"/>
                  <path d="M20 80 L40 55 L55 65 L75 35 L95 45 L100 30" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/>
                  <circle cx="75" cy="35" r="5" fill="#4D9FFF"/>
                  <path d="M60 10 L63 20 L60 18 L57 20 Z" fill="#FFD700"/>
                  <circle cx="60" cy="50" r="8" fill="rgba(77,159,255,0.3)" stroke="#4D9FFF" strokeWidth="1.5"/>
                </svg>
              </div>
              <div style={{fontSize:12,color:C.primary,fontWeight:600,marginBottom:4}}>{t.hello} ☀️</div>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:dm?C.text:'#0F172A',margin:'0 0 6px'}}>
                {t.title}, <span style={{color:C.primary}}>{name}</span> 👋
              </h1>
              <p style={{fontSize:13,color:C.sub,marginBottom:16,maxWidth:500}}>{t.sub}</p>
              {/* Motivational Quote */}
              <div style={{background:'rgba(77,159,255,0.07)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:10,padding:'10px 14px',maxWidth:520}}>
                <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600,marginBottom:3}}>{t.quote}</div>
                <div style={{fontSize:11,color:C.sub}}>{t.quoteHi}</div>
              </div>
              {/* Quick buttons */}
              <div style={{display:'flex',flexWrap:'wrap',gap:8,marginTop:16}}>
                {[['📝 '+( lang==='en'?'My Exams':'मेरी परीक्षाएं'),'/my-exams',C.primary],[' 📈 '+(lang==='en'?'Results':'परिणाम'),'/results',C.success],['🧠 '+(lang==='en'?'Smart Revision':'स्मार्ट रिवीजन'),'/revision','#A78BFA'],['🎯 '+(lang==='en'?'My Goals':'मेरे लक्ष्य'),'/goals',C.gold]].map(([l,h,c])=>(
                  <a key={String(h)} href={String(h)} style={{padding:'8px 14px',background:`${c}22`,border:`1px solid ${c}44`,color:String(c),borderRadius:20,textDecoration:'none',fontSize:12,fontWeight:600}}>{String(l)}</a>
                ))}
              </div>
            </div>

            {/* Stats Row */}
            <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:20}}>
              <StatCard dm={dm} icon="🏆" label={t.rank} value={bestRank?`#${bestRank}`:t.rank} col={C.gold}/>
              <StatCard dm={dm} icon="📊" label={t.bestScore} value={bestScore?`${bestScore}/720`:t.bestScore} col={C.primary}/>
              <StatCard dm={dm} icon="🔥" label={t.streak} value={`${streak} ${lang==='en'?'days':'दिन'}`} col="#FF6B6B" sub={lang==='en'?'Keep it up!':'जारी रखें!'}/>
              <StatCard dm={dm} icon="⏳" label={t.daysLeft} value={`${daysLeft}`} col={C.warn} sub="NEET 2026"/>
            </div>
            <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:24}}>
              <StatCard dm={dm} icon="🎯" label={t.accuracy} value={stats?.avgAccuracy?`${stats.avgAccuracy}%`:'—'} col={C.success}/>
              <StatCard dm={dm} icon="📝" label={t.tests} value={results.length||0} col={C.primary}/>
              <StatCard dm={dm} icon="🎖️" label={t.badges} value={user?.badges?.length||0} col={C.purple||'#A78BFA'}/>
              <StatCard dm={dm} icon="📅" label={t.nextExam} value={exams.filter((e:any)=>new Date(e.scheduledAt)>new Date()).length} col="#FF6B9D" sub={lang==='en'?'upcoming':'आगामी'}/>
            </div>

            {/* Subject Performance */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:dm?C.text:'#0F172A',marginBottom:14}}>📚 {t.subjects} ({lang==='en'?'Last Test':'पिछला टेस्ट'})</div>
              {[{name:'Physics',icon:'⚛️',score:results[0]?.subjectScores?.physics||148,total:180,col:'#00B4FF'},{name:'Chemistry',icon:'🧪',score:results[0]?.subjectScores?.chemistry||152,total:180,col:'#FF6B9D'},{name:'Biology',icon:'🧬',score:results[0]?.subjectScores?.biology||310,total:360,col:'#00E5A0'}].map(s=>{
                const pct = Math.round((s.score/s.total)*100)
                return (
                  <div key={s.name} style={{marginBottom:14}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:6}}>
                      <span style={{fontSize:13,fontWeight:600,color:s.col}}>{s.icon} {lang==='en'?s.name:s.name==='Physics'?'भौतिकी':s.name==='Chemistry'?'रसायन':'जीव विज्ञान'}</span>
                      <span style={{fontSize:12,color:C.sub}}>{s.score}/{s.total} <span style={{color:s.col,fontWeight:700}}>({pct}%)</span></span>
                    </div>
                    <div style={{background:'rgba(255,255,255,0.06)',borderRadius:6,height:10,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:6,transition:'width .8s ease'}}/>
                    </div>
                  </div>
                )
              })}
            </div>

            {/* 2 Column: Upcoming + Results */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
              {/* Upcoming Exams */}
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:'#0F172A'}}>📅 {t.upcoming}</div>
                  <a href="/my-exams" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t.viewAll}</a>
                </div>
                {loading?<div style={{textAlign:'center',color:C.sub,padding:'20px 0',fontSize:12}}>⟳ Loading...</div>:
                  exams.filter((e:any)=>new Date(e.scheduledAt)>new Date()).length===0?
                  <div style={{textAlign:'center',padding:'24px 0',color:C.sub}}>
                    <svg width="48" height="48" viewBox="0 0 48 48" style={{display:'block',margin:'0 auto 10px'}}><rect x="6" y="10" width="36" height="32" rx="4" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/><path d="M6 18h36M16 6v8M32 6v8" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/><circle cx="24" cy="30" r="4" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/></svg>
                    <div style={{fontSize:12}}>{t.noExam}</div>
                  </div>:
                  exams.filter((e:any)=>new Date(e.scheduledAt)>new Date()).slice(0,3).map((e:any)=>(
                    <div key={e._id} style={{padding:'10px 0',borderBottom:`1px solid ${C.border}`,fontSize:12}}>
                      <div style={{fontWeight:600,color:dm?C.text:'#0F172A',marginBottom:3}}>{e.title}</div>
                      <div style={{color:C.sub,fontSize:11}}>{new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'})} · {e.duration} min · {e.totalMarks} marks</div>
                      <a href={`/exam/${e._id}`} style={{display:'inline-block',marginTop:6,padding:'4px 12px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:6,fontSize:11,textDecoration:'none',fontWeight:600}}>{t.startExam}</a>
                    </div>
                  ))
                }
              </div>

              {/* Recent Results */}
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:dm?C.text:'#0F172A'}}>🏅 {t.recent}</div>
                  <a href="/results" style={{fontSize:11,color:C.primary,textDecoration:'none',fontWeight:600}}>{t.viewAll}</a>
                </div>
                {loading?<div style={{textAlign:'center',color:C.sub,padding:'20px 0',fontSize:12}}>⟳ Loading...</div>:
                  results.length===0?
                  <div style={{textAlign:'center',padding:'24px 0',color:C.sub}}>
                    <svg width="48" height="48" viewBox="0 0 48 48" style={{display:'block',margin:'0 auto 10px'}}><path d="M24 8l3 9h9l-7 5 3 9-8-6-8 6 3-9-7-5h9z" stroke="#FFD700" strokeWidth="1.5" fill="none"/></svg>
                    <div style={{fontSize:12}}>{t.noResult}</div>
                  </div>:
                  results.slice(0,3).map((r:any)=>(
                    <div key={r._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'8px 0',borderBottom:`1px solid ${C.border}`}}>
                      <div style={{fontSize:12}}>
                        <div style={{fontWeight:600,color:dm?C.text:'#0F172A'}}>{r.examTitle||r.exam?.title||'—'}</div>
                        <div style={{color:C.sub,fontSize:10,marginTop:2}}>#{r.rank||'—'} AIR · {r.percentile||'—'}%ile</div>
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

            {/* Pro Tip + Activity */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
              <div style={{background:'linear-gradient(135deg,rgba(255,215,0,0.08),rgba(0,22,40,0.8))',border:`1px solid ${C.gold}33`,borderRadius:16,padding:18}}>
                <div style={{fontWeight:700,fontSize:13,color:C.gold,marginBottom:8}}>💡 {t.tip}</div>
                <div style={{fontSize:12,color:dm?C.text:'#0F172A',lineHeight:1.6}}>{t.proTip}</div>
                <div style={{marginTop:12,display:'flex',gap:8,flexWrap:'wrap'}}>
                  <a href="/revision" style={{fontSize:11,padding:'5px 12px',background:`${C.primary}22`,border:`1px solid ${C.primary}44`,color:C.primary,borderRadius:6,textDecoration:'none',fontWeight:600}}>{lang==='en'?'Start Revision →':'रिवीजन शुरू करें →'}</a>
                  <a href="/pyq-bank" style={{fontSize:11,padding:'5px 12px',background:`${C.gold}22`,border:`1px solid ${C.gold}44`,color:C.gold,borderRadius:6,textDecoration:'none',fontWeight:600}}>{lang==='en'?'PYQ Bank →':'पिछले प्रश्न →'}</a>
                </div>
              </div>
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
                <div style={{fontWeight:700,fontSize:13,color:dm?C.text:'#0F172A',marginBottom:10}}>⚡ {t.quick}</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                  {[['📝','My Exams','मेरी परीक्षाएं','/my-exams'],['📚','PYQ Bank','पिछले प्रश्न','/pyq-bank'],['🧠','Revision','रिवीजन','/revision'],['🎯','Goals','लक्ष्य','/goals']].map(([ic,en,hi,href])=>(
                    <a key={String(href)} href={String(href)} style={{display:'flex',alignItems:'center',gap:6,padding:'10px 10px',background:'rgba(77,159,255,0.07)',border:`1px solid ${C.border}`,borderRadius:10,textDecoration:'none',color:dm?C.text:'#0F172A',fontSize:12,fontWeight:600,transition:'all .2s'}}>
                      <span style={{fontSize:16}}>{ic}</span>
                      <span>{lang==='en'?en:hi}</span>
                    </a>
                  ))}
                </div>
              </div>
            </div>

            {/* Motivational Footer SVG */}
            <div style={{background:'linear-gradient(135deg,rgba(0,85,204,0.15),rgba(77,159,255,0.05))',border:`1px solid rgba(77,159,255,0.15)`,borderRadius:20,padding:'24px 20px',textAlign:'center',position:'relative',overflow:'hidden'}}>
              <svg width="100%" height="80" viewBox="0 0 600 80" preserveAspectRatio="xMidYMid meet" style={{display:'block',marginBottom:12}}>
                <text x="50%" y="40" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="28" fontWeight="700" fill="url(#dg)" opacity=".15">PROVE YOUR RANK</text>
                <defs><linearGradient id="dg" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stopColor="#4D9FFF"/><stop offset="100%" stopColor="#ffffff"/></linearGradient></defs>
                <text x="50%" y="65" textAnchor="middle" fontFamily="Inter,sans-serif" fontSize="11" fill="#4D9FFF" opacity=".6">अपनी रैंक साबित करो · Prove Your Rank · NEET 2026</text>
              </svg>
              <div style={{fontSize:18,color:C.primary,fontFamily:'Playfair Display,serif',fontWeight:700,marginBottom:4}}>
                {lang==='en'?"You're on the right path! 🚀":"आप सही रास्ते पर हैं! 🚀"}
              </div>
              <div style={{fontSize:12,color:C.sub}}>{lang==='en'?`${daysLeft} days remaining for NEET 2026 — Make every day count!`:`NEET 2026 के लिए ${daysLeft} दिन शेष — हर दिन को सार्थक बनाएं!`}</div>
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
