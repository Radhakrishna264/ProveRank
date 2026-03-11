'use client'
import { useState, useEffect } from 'react'
import { useParams, useSearchParams, useRouter } from 'next/navigation'
import { useAuth } from '@/lib/useAuth'
import Link from 'next/link'

const API = process.env.NEXT_PUBLIC_API_URL || ''

export default function ResultPage() {
  const { user, loading } = useAuth('student')
  const params  = useParams()
  const search  = useSearchParams()
  const router  = useRouter()
  const examId  = params?.examId as string
  const attemptId = search?.get('attemptId')
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [result, setResult] = useState<any>(null)
  const [tab, setTab] = useState<'score'|'analysis'|'leaderboard'>('score')
  const [mounted, setMounted] = useState(false)

  const t = lang==='en' ? {
    title:'Your Result', rank:'All India Rank', score:'Score',
    percentile:'Percentile', accuracy:'Accuracy', correct:'Correct',
    incorrect:'Incorrect', skipped:'Skipped', download:'Download PDF',
    share:'Share Result', analysis:'View Analysis', board:'Leaderboard',
    physics:'Physics', chemistry:'Chemistry', biology:'Biology',
    strong:'Strong Topics', weak:'Weak Topics', revise:'Revise Now →',
    backDash:'← Back to Dashboard',
  } : {
    title:'आपका परिणाम', rank:'अखिल भारत रैंक', score:'स्कोर',
    percentile:'प्रतिशतक', accuracy:'सटीकता', correct:'सही',
    incorrect:'गलत', skipped:'छोड़े', download:'PDF डाउनलोड',
    share:'परिणाम साझा करें', analysis:'विश्लेषण', board:'लीडरबोर्ड',
    physics:'भौतिकी', chemistry:'रसायन विज्ञान', biology:'जीव विज्ञान',
    strong:'मजबूत विषय', weak:'कमजोर विषय', revise:'अभी दोहराएं →',
    backDash:'← डैशबोर्ड पर वापस',
  }

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    if (user && attemptId) fetchResult()
  },[user, attemptId])

  const fetchResult = async()=>{
    try {
      const h = {Authorization:`Bearer ${user!.token}`}
      const r = await fetch(`${API}/api/results/${attemptId}`,{headers:h})
      if(r.ok){ const d=await r.json(); setResult(d) }
    } catch {}
  }

  if (loading || !mounted) return <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>Loading result...</div>

  const sc = result?.score || 0
  const mx = 720; const pct = Math.round((sc/mx)*100)
  const rank = result?.rank || '—'
  const percentile = result?.percentile || '—'
  const correct = result?.totalCorrect || 0
  const incorrect = result?.totalIncorrect || 0
  const skipped = result?.totalSkipped || (180-correct-incorrect)
  const accuracy = correct+incorrect > 0 ? Math.round((correct/(correct+incorrect))*100) : 0
  const r = 70; const circumference = 2*Math.PI*r

  const subjectData = [
    {name:t.physics,   score:result?.subjectStats?.Physics?.score   || 0, max:180},
    {name:t.chemistry, score:result?.subjectStats?.Chemistry?.score || 0, max:180},
    {name:t.biology,   score:result?.subjectStats?.Biology?.score   || 0, max:360},
  ]

  return (
    <div style={{minHeight:'100vh',background:'#000A18',color:'#E8F4FF',fontFamily:'Inter,sans-serif'}}>
      <style>{`
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes scoreIn{from{stroke-dashoffset:${circumference}}to{stroke-dashoffset:${circumference-(pct/100)*circumference}}}
        .tbtn{padding:8px 18px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}
        .tbtn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15);}
        .lb{padding:12px 24px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:14px;font-weight:700;cursor:pointer;transition:all 0.3s;}
        .lb:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(77,159,255,0.4);}
      `}</style>
      {/* Header */}
      <div style={{borderBottom:'1px solid rgba(77,159,255,0.15)',padding:'16px 5%',display:'flex',justifyContent:'space-between',alignItems:'center',position:'sticky',top:0,background:'rgba(0,10,24,0.92)',backdropFilter:'blur(20px)',zIndex:50}}>
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <button onClick={()=>router.push('/dashboard')} style={{background:'none',border:'none',color:'#4D9FFF',cursor:'pointer',fontSize:14,fontWeight:600}}>{t.backDash}</button>
        </div>
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <svg width={24} height={24} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
          <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,color:'#4D9FFF',fontSize:16}}>ProveRank</span>
        </div>
        <button className="tbtn" onClick={()=>setLang(l=>l==='en'?'hi':'en')}>{lang==='en'?'🇮🇳':'🌐'}</button>
      </div>

      <div style={{maxWidth:1100,margin:'0 auto',padding:'40px 5%'}}>
        {/* Tabs */}
        <div style={{display:'flex',gap:8,marginBottom:32,background:'rgba(0,22,40,0.5)',borderRadius:14,padding:6,border:'1px solid rgba(77,159,255,0.15)',width:'fit-content'}}>
          {([['score',`🏆 ${t.title}`],['analysis',`📊 ${t.analysis}`],['leaderboard',`🥇 ${t.board}`]] as [string,string][]).map(([id,label])=>(
            <button key={id} onClick={()=>setTab(id as any)} style={{padding:'10px 20px',borderRadius:10,border:'none',cursor:'pointer',fontWeight:tab===id?700:500,fontSize:13,fontFamily:'Inter,sans-serif',background:tab===id?'rgba(77,159,255,0.2)':'transparent',color:tab===id?'#4D9FFF':'#6B8BAF',transition:'all 0.2s'}}>{label}</button>
          ))}
        </div>

        {/* Score Tab */}
        {tab==='score' && (
          <div style={{animation:'fadeUp 0.5s ease forwards'}}>
            {/* Hero Score */}
            <div style={{background:'linear-gradient(135deg,rgba(0,40,100,0.6),rgba(0,22,50,0.6))',border:'1px solid rgba(77,159,255,0.25)',borderRadius:20,padding:'40px',textAlign:'center',marginBottom:24}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.6rem,4vw,2.4rem)',fontWeight:800,marginBottom:32,color:'#E8F4FF'}}>{t.title}</h1>
              {/* Score Ring */}
              <div style={{position:'relative',display:'inline-flex',alignItems:'center',justifyContent:'center',marginBottom:32}}>
                <svg width={180} height={180} viewBox="0 0 180 180">
                  <defs><linearGradient id="rg" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#4D9FFF"/><stop offset="100%" stopColor="#00C48C"/></linearGradient></defs>
                  <circle cx="90" cy="90" r={r} fill="none" stroke="rgba(77,159,255,0.1)" strokeWidth="10"/>
                  <circle cx="90" cy="90" r={r} fill="none" stroke="url(#rg)" strokeWidth="10" strokeLinecap="round"
                    strokeDasharray={circumference} strokeDashoffset={circumference-(pct/100)*circumference}
                    transform="rotate(-90 90 90)" style={{transition:'stroke-dashoffset 1.5s ease'}}/>
                </svg>
                <div style={{position:'absolute',textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:36,fontWeight:800,color:'#4D9FFF',lineHeight:1}}>{sc}</div>
                  <div style={{color:'#6B8BAF',fontSize:14}}>/ {mx}</div>
                </div>
              </div>
              {/* Stat Row */}
              <div style={{display:'flex',justifyContent:'center',gap:32,flexWrap:'wrap'}}>
                {[[`#${rank}`,t.rank,'#FFD700'],[`${percentile}%`,t.percentile,'#A855F7'],[`${accuracy}%`,t.accuracy,'#00C48C']].map(([v2,l,c])=>(
                  <div key={l} style={{textAlign:'center'}}>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:String(c)}}>{v2}</div>
                    <div style={{color:'#6B8BAF',fontSize:13,marginTop:4}}>{l}</div>
                  </div>
                ))}
              </div>
            </div>
            {/* Stats */}
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:16,marginBottom:24}}>
              {[[correct,t.correct,'#00C48C','✓'],[incorrect,t.incorrect,'#FF4757','✗'],[skipped,t.skipped,'#6B8BAF','—']].map(([v2,l,c,icon])=>(
                <div key={String(l)} style={{background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:14,padding:'20px 24px',textAlign:'center'}}>
                  <div style={{fontSize:28,marginBottom:8}}>{icon}</div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:32,fontWeight:800,color:String(c)}}>{v2}</div>
                  <div style={{color:'#6B8BAF',fontSize:13,marginTop:4}}>{l}</div>
                </div>
              ))}
            </div>
            {/* Subject wise */}
            <div style={{background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:16,padding:24,marginBottom:24}}>
              <h3 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:20}}>{lang==='en'?'Subject-wise Performance':'विषय-वार प्रदर्शन'}</h3>
              {subjectData.map(sub=>(
                <div key={sub.name} style={{marginBottom:16}}>
                  <div style={{display:'flex',justifyContent:'space-between',marginBottom:6}}>
                    <span style={{fontWeight:600,fontSize:14}}>{sub.name}</span>
                    <span style={{color:'#4D9FFF',fontWeight:700}}>{sub.score}/{sub.max}</span>
                  </div>
                  <div className="progress-bar"><div className="progress-fill" style={{width:`${(sub.score/sub.max)*100}%`}}/></div>
                </div>
              ))}
            </div>
            {/* Action Buttons */}
            <div style={{display:'flex',gap:12,flexWrap:'wrap'}}>
              <button className="lb">{t.download}</button>
              <button className="tbtn" style={{fontSize:14,padding:'12px 24px'}}>{t.share}</button>
              <button onClick={()=>router.push('/dashboard')} style={{padding:'12px 24px',borderRadius:10,border:'1px solid rgba(77,159,255,0.2)',background:'transparent',color:'#6B8BAF',cursor:'pointer',fontSize:14,fontFamily:'Inter,sans-serif'}}>{t.backDash}</button>
            </div>
          </div>
        )}

        {/* Analysis Tab */}
        {tab==='analysis' && (
          <div style={{animation:'fadeUp 0.5s ease forwards'}}>
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:20}}>
              <div style={{background:'rgba(0,196,140,0.06)',border:'1px solid rgba(0,196,140,0.2)',borderRadius:16,padding:24}}>
                <h3 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#00C48C',marginBottom:16}}>💪 {t.strong}</h3>
                {['Biology - Genetics (94%)','Chemistry - Organic (88%)','Physics - Optics (82%)'].map((s,i)=>(
                  <div key={i} style={{background:'rgba(0,196,140,0.08)',borderRadius:10,padding:'12px 16px',marginBottom:8,fontSize:14}}>{s}</div>
                ))}
              </div>
              <div style={{background:'rgba(255,71,87,0.06)',border:'1px solid rgba(255,71,87,0.2)',borderRadius:16,padding:24}}>
                <h3 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#FF4757',marginBottom:16}}>⚠️ {t.weak}</h3>
                {['Chemistry - Inorganic (52%)','Physics - Thermodynamics (58%)','Biology - Plant Physiology (61%)'].map((s,i)=>(
                  <div key={i} style={{background:'rgba(255,71,87,0.08)',borderRadius:10,padding:'12px 16px',marginBottom:8,display:'flex',justifyContent:'space-between',alignItems:'center',fontSize:14}}>
                    <span>{s}</span>
                    <button className="tbtn" style={{fontSize:11,padding:'4px 10px',color:'#FF4757',borderColor:'rgba(255,71,87,0.3)'}}>{t.revise}</button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Leaderboard Tab */}
        {tab==='leaderboard' && (
          <div style={{background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:16,padding:24,animation:'fadeUp 0.5s ease forwards'}}>
            <h2 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,marginBottom:20}}>🏆 {t.board}</h2>
            <table className="pr-table" style={{color:'#E8F4FF'}}>
              <thead><tr>{[lang==='en'?'Rank':'रैंक',lang==='en'?'Name':'नाम',lang==='en'?'Score':'स्कोर','Percentile'].map(h2=><th key={h2} style={{color:'#6B8BAF',borderBottom:'1px solid rgba(77,159,255,0.15)'}}>{h2}</th>)}</tr></thead>
              <tbody>
                {[{r:1,name:'Arjun Sharma',sc:692,pct:99.8},{r:2,name:'Priya K.',sc:685,pct:99.5},{r:3,name:'Rohit V.',sc:681,pct:99.2}].map(s=>(
                  <tr key={s.r}><td style={{borderBottom:'1px solid rgba(0,45,85,0.3)'}}><span className={`badge ${s.r===1?'badge-gold':s.r===2?'badge-blue':'badge-green'}`}>#{s.r}</span></td><td style={{borderBottom:'1px solid rgba(0,45,85,0.3)',fontWeight:600}}>{s.name}</td><td style={{borderBottom:'1px solid rgba(0,45,85,0.3)',color:'#4D9FFF',fontWeight:700}}>{s.sc}/720</td><td style={{borderBottom:'1px solid rgba(0,45,85,0.3)',color:'#00C48C'}}>{s.pct}%</td></tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
