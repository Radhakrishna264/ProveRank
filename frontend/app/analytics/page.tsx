'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

const TR = {
  en:{ title:'Analytics', sub:'Deep performance insights — data-driven preparation',
    scoreTrend:'Score Trend', subjectPerf:'Subject-wise Performance',
    weakChapters:'Weak Chapters', strongChapters:'Strong Chapters',
    testHistory:'Test History', revise:'Revise →', accuracy:'Accuracy',
    correct:'Correct', wrong:'Wrong', skipped:'Skipped',
    quote:'"Data is the compass — let analytics guide your preparation."',
    quoteHi:'डेटा कम्पास है — विश्लेषण को अपनी तैयारी का मार्गदर्शक बनाएं।',
    noCutoff:'Performance vs NEET Cutoff',cutoff:'NEET 2025 Cutoff',yourAvg:'Your Average',
    vsNeet:'vs NEET Cutoff', needMore:'More marks needed', topicAcc:'Topic Accuracy',
    timeSpent:'Avg Time/Question', physics:'Physics', chemistry:'Chemistry', biology:'Biology',
  },
  hi:{ title:'विश्लेषण', sub:'गहरी प्रदर्शन अंतर्दृष्टि — डेटा-आधारित तैयारी',
    scoreTrend:'स्कोर ट्रेंड', subjectPerf:'विषय-वार प्रदर्शन',
    weakChapters:'कमजोर अध्याय', strongChapters:'मजबूत अध्याय',
    testHistory:'टेस्ट इतिहास', revise:'रिवीजन करें →', accuracy:'सटीकता',
    correct:'सही', wrong:'गलत', skipped:'छोड़ा',
    quote:'"डेटा कम्पास है — विश्लेषण को अपनी तैयारी का मार्गदर्शक बनाएं।"',
    quoteHi:'Data is the compass — let analytics guide your preparation.',
    noCutoff:'NEET कटऑफ से तुलना',cutoff:'NEET 2025 कटऑफ',yourAvg:'आपका औसत',
    vsNeet:'NEET कटऑफ से', needMore:'और अंक चाहिए', topicAcc:'विषय सटीकता',
    timeSpent:'औसत समय/प्रश्न', physics:'भौतिकी', chemistry:'रसायन', biology:'जीव विज्ञान',
  }
}

export default function AnalyticsPage() {
  return (
    <StudentShell pageKey="analytics">
      {({lang, darkMode:dm, user, toast, token}) => {
        const t = TR[lang]
        const [results, setResults] = useState<any[]>([])
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
        },[token])

        const avgScore = results.length>0?Math.round(results.reduce((a,r)=>a+(r.score||0),0)/results.length):0
        const neetCutoff = 550

        const weakChapters = [
          {name:lang==='en'?'Inorganic Chemistry':'अकार्बनिक रसायन',sub:lang==='en'?'Chemistry':'रसायन',pct:52,col:'#FF6B9D'},
          {name:lang==='en'?'Thermodynamics':'ऊष्मागतिकी',sub:lang==='en'?'Physics':'भौतिकी',pct:58,col:C.warn},
          {name:lang==='en'?'Plant Physiology':'पादप शरीर क्रिया',sub:lang==='en'?'Biology':'जीव विज्ञान',pct:63,col:C.primary},
          {name:lang==='en'?'Modern Physics':'आधुनिक भौतिकी',sub:lang==='en'?'Physics':'भौतिकी',pct:66,col:C.warn},
        ]
        const strongChapters = [
          {name:lang==='en'?'Genetics & Evolution':'आनुवंशिकी और विकास',pct:94,col:C.success},
          {name:lang==='en'?'Organic Chemistry':'कार्बनिक रसायन',pct:89,col:C.success},
          {name:lang==='en'?'Human Physiology':'मानव शरीर क्रिया',pct:87,col:C.primary},
          {name:lang==='en'?'Optics':'प्रकाशिकी',pct:84,col:C.primary},
        ]

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            {/* Header */}
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{t.title}</h1>
              <div style={{fontSize:13,color:C.sub}}>{t.sub}</div>
            </div>

            {/* Quote + SVG Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(167,139,250,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(167,139,250,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:20,flexWrap:'wrap',position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.1}}>
                <svg width="130" height="100" viewBox="0 0 130 100" fill="none">
                  <rect x="10" y="10" width="110" height="80" rx="6" stroke="#A78BFA" strokeWidth="1.5" fill="none"/>
                  <path d="M20 70 L35 50 L50 60 L65 35 L80 45 L95 25 L110 40" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/>
                  <circle cx="65" cy="35" r="4" fill="#FFD700"/>
                  <circle cx="95" cy="25" r="4" fill="#00C48C"/>
                  <path d="M20 80h90" stroke="#A78BFA" strokeWidth=".5"/>
                  <path d="M20 10v70" stroke="#A78BFA" strokeWidth=".5"/>
                </svg>
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:14,color:'#A78BFA',fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t.quote}</div>
                <div style={{fontSize:12,color:C.sub}}>{t.quoteHi}</div>
              </div>
            </div>

            {/* Score Trend */}
            {results.length>0&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,marginBottom:20,backdropFilter:'blur(12px)'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>📈 {t.scoreTrend} ({lang==='en'?'Last 5 Tests':'पिछले 5 टेस्ट'})</div>
                <div style={{display:'flex',alignItems:'flex-end',gap:6,height:100,position:'relative'}}>
                  {/* Grid lines */}
                  {[100,75,50,25].map(p=>(
                    <div key={p} style={{position:'absolute',left:0,right:0,bottom:`${p}%`,borderTop:'1px dashed rgba(77,159,255,0.1)',display:'flex',alignItems:'center'}}>
                      <span style={{fontSize:9,color:C.sub,marginLeft:-28,width:24,textAlign:'right'}}>{Math.round(p*7.2)}</span>
                    </div>
                  ))}
                  {results.slice(0,5).reverse().map((r:any,i:number)=>{
                    const h = Math.round(((r.score||0)/720)*100)
                    const col = h>80?C.success:h>60?C.primary:h>40?C.warn:C.danger
                    return (
                      <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:4,position:'relative',zIndex:1}}>
                        <div style={{fontSize:11,color:col,fontWeight:700}}>{r.score}</div>
                        <div title={r.examTitle} style={{width:'80%',height:`${h}%`,background:`linear-gradient(180deg,${col},${col}66)`,borderRadius:'6px 6px 0 0',minHeight:4,transition:'height .8s ease',cursor:'pointer',position:'relative'}}>
                          <div style={{position:'absolute',top:-1,left:'50%',transform:'translateX(-50%)',width:'100%',height:4,background:col,borderRadius:2,opacity:.8}}/>
                        </div>
                        <div style={{fontSize:9,color:C.sub,textAlign:'center'}}>{new Date(r.submittedAt||r.createdAt||'').toLocaleDateString('en-IN',{month:'short',day:'numeric'})}</div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )}

            {/* Subject Performance */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>🔬 {t.subjectPerf}</div>
              {[{name:t.physics,icon:'⚛️',score:results[0]?.subjectScores?.physics||148,total:180,col:'#00B4FF'},{name:t.chemistry,icon:'🧪',score:results[0]?.subjectScores?.chemistry||152,total:180,col:'#FF6B9D'},{name:t.biology,icon:'🧬',score:results[0]?.subjectScores?.biology||310,total:360,col:'#00E5A0'}].map(s=>{
                const pct=Math.round((s.score/s.total)*100)
                const correct=Math.round(s.score/4)
                const wrong=Math.round((s.total-s.score)/5)
                return (
                  <div key={s.name} style={{marginBottom:18,padding:'12px',background:'rgba(77,159,255,0.04)',borderRadius:10,border:`1px solid ${s.col}22`}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8}}>
                      <span style={{fontSize:14,fontWeight:700,color:s.col}}>{s.icon} {s.name}</span>
                      <div style={{display:'flex',gap:10,fontSize:11}}>
                        <span style={{color:C.success}}>✓ {correct}</span>
                        <span style={{color:C.danger}}>✗ {wrong}</span>
                        <span style={{color:s.col,fontWeight:700}}>{s.score}/{s.total} ({pct}%)</span>
                      </div>
                    </div>
                    <div style={{background:'rgba(255,255,255,0.06)',borderRadius:6,height:10,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:6,transition:'width .8s ease'}}/>
                    </div>
                  </div>
                )
              })}
            </div>

            {/* Weak + Strong Chapters */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:20}}>
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid rgba(255,77,77,0.2)`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:C.danger,marginBottom:14}}>⚠️ {t.weakChapters}</div>
                {weakChapters.map((ch,i)=>(
                  <div key={i} style={{marginBottom:12}}>
                    <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:5}}>
                      <div><div style={{fontWeight:600,color:dm?C.text:'#0F172A'}}>{ch.name}</div><div style={{fontSize:10,color:ch.col}}>{ch.sub}</div></div>
                      <div style={{display:'flex',alignItems:'center',gap:6}}>
                        <span style={{color:C.warn,fontWeight:700,fontSize:13}}>{ch.pct}%</span>
                        <a href="/revision" style={{fontSize:10,padding:'2px 8px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:6,textDecoration:'none',fontWeight:600}}>{t.revise}</a>
                      </div>
                    </div>
                    <div style={{background:'rgba(255,255,255,0.06)',borderRadius:4,height:6,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${ch.pct}%`,background:`linear-gradient(90deg,${C.danger},${C.warn})`,borderRadius:4}}/>
                    </div>
                  </div>
                ))}
              </div>
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid rgba(0,196,140,0.2)`,borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:C.success,marginBottom:14}}>💪 {t.strongChapters}</div>
                {strongChapters.map((ch,i)=>(
                  <div key={i} style={{marginBottom:12}}>
                    <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:5}}>
                      <span style={{fontWeight:600,color:dm?C.text:'#0F172A'}}>{ch.name}</span>
                      <span style={{color:C.success,fontWeight:700,fontSize:13}}>{ch.pct}%</span>
                    </div>
                    <div style={{background:'rgba(255,255,255,0.06)',borderRadius:4,height:6,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${ch.pct}%`,background:`linear-gradient(90deg,${C.success}88,${C.success})`,borderRadius:4}}/>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* vs NEET Cutoff */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid rgba(255,215,0,0.2)`,borderRadius:16,padding:20,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>🎯 {t.noCutoff} (N4)</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:14}}>
                <div style={{padding:'12px',background:'rgba(77,159,255,0.08)',borderRadius:12,border:`1px solid ${C.border}`,textAlign:'center'}}>
                  <div style={{fontWeight:800,fontSize:24,color:C.primary,fontFamily:'Playfair Display,serif'}}>{avgScore||'—'}</div>
                  <div style={{fontSize:11,color:C.sub,marginTop:3}}>{t.yourAvg}</div>
                </div>
                <div style={{padding:'12px',background:'rgba(255,215,0,0.08)',borderRadius:12,border:'1px solid rgba(255,215,0,0.2)',textAlign:'center'}}>
                  <div style={{fontWeight:800,fontSize:24,color:C.gold,fontFamily:'Playfair Display,serif'}}>{neetCutoff}</div>
                  <div style={{fontSize:11,color:C.sub,marginTop:3}}>{t.cutoff}</div>
                </div>
              </div>
              {avgScore>0&&(
                <div>
                  <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:6}}>
                    <span style={{color:C.sub}}>{t.vsNeet}</span>
                    <span style={{color:avgScore>=neetCutoff?C.success:C.danger,fontWeight:700}}>{avgScore>=neetCutoff?'✅ Above Cutoff':`❌ ${neetCutoff-avgScore} ${t.needMore}`}</span>
                  </div>
                  <div style={{background:'rgba(255,255,255,0.06)',borderRadius:6,height:12,overflow:'hidden',position:'relative'}}>
                    <div style={{height:'100%',width:`${Math.min(100,(avgScore/720)*100)}%`,background:`linear-gradient(90deg,${avgScore>=neetCutoff?C.success:C.warn},${avgScore>=neetCutoff?C.success:C.danger})`,borderRadius:6,transition:'width .8s'}}/>
                    <div style={{position:'absolute',top:0,bottom:0,left:`${(neetCutoff/720)*100}%`,width:2,background:C.gold}}/>
                  </div>
                </div>
              )}
            </div>

            {/* Test History Table */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(12px)'}}>
              <div style={{padding:'14px 20px',borderBottom:`1px solid ${C.border}`,fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A'}}>📋 {t.testHistory}</div>
              {results.length===0?<div style={{textAlign:'center',padding:'30px',color:C.sub,fontSize:12}}>{lang==='en'?'No test history yet':'अभी कोई टेस्ट इतिहास नहीं'}</div>:(
                <div>
                  <div style={{display:'grid',gridTemplateColumns:'2fr 1fr 1fr 1fr 1fr',padding:'10px 20px',background:'rgba(77,159,255,0.05)',borderBottom:`1px solid ${C.border}`,fontSize:10,color:C.primary,fontWeight:700,textTransform:'uppercase',letterSpacing:.5}}>
                    <span>{lang==='en'?'TEST':'टेस्ट'}</span><span>{t.score.toUpperCase()}</span><span>{t.correct.toUpperCase()}</span><span style={{color:C.gold}}>RANK</span><span>{lang==='en'?'DATE':'तारीख'}</span>
                  </div>
                  {results.map((r:any,i:number)=>(
                    <div key={r._id||i} style={{display:'grid',gridTemplateColumns:'2fr 1fr 1fr 1fr 1fr',padding:'12px 20px',borderBottom:`1px solid ${C.border}`,fontSize:12,transition:'background .15s'}}>
                      <span style={{color:dm?C.text:'#0F172A',fontWeight:600,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{r.examTitle||'—'}</span>
                      <span style={{color:C.primary,fontWeight:700}}>{r.score}/{r.totalMarks||720}</span>
                      <span style={{color:C.success}}>{r.correct||'—'}</span>
                      <span style={{color:C.gold,fontWeight:700}}>#{r.rank||'—'}</span>
                      <span style={{color:C.sub,fontSize:10}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short'}):''}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
