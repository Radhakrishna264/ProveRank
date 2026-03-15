'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function AnalyticsContent() {
  const { lang, darkMode:dm, token } = useShell()
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const avg  = results.length ? Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length) : 0
  const neet = 550
  const weak  = [{name:t('Inorganic Chemistry','अकार्बनिक रसायन'),sub:'Chemistry',pct:52,col:'#FF6B9D'},{name:t('Thermodynamics','ऊष्मागतिकी'),sub:'Physics',pct:58,col:C.warn},{name:t('Plant Physiology','पादप शरीर क्रिया'),sub:'Biology',pct:63,col:C.primary},{name:t('Modern Physics','आधुनिक भौतिकी'),sub:'Physics',pct:66,col:C.warn}]
  const strong= [{name:t('Genetics & Evolution','आनुवंशिकी'),pct:94,col:C.success},{name:t('Organic Chemistry','कार्बनिक रसायन'),pct:89,col:C.success},{name:t('Human Physiology','मानव शरीर क्रिया'),pct:87,col:C.primary},{name:t('Optics','प्रकाशिकी'),pct:84,col:C.primary}]

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.purple||'#A78BFA'},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📉 {t('Analytics','विश्लेषण')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Deep performance insights — data-driven preparation','गहरी प्रदर्शन अंतर्दृष्टि')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(167,139,250,.1),rgba(0,22,40,.85))',border:'1px solid rgba(167,139,250,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14,position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',right:14,opacity:.08}}><svg width="110" height="80" viewBox="0 0 110 80" fill="none"><rect x="5" y="5" width="100" height="70" rx="5" stroke="#A78BFA" strokeWidth="1.5" fill="none"/><path d="M15 60 L30 40 L45 50 L60 25 L75 35 L90 15" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/></svg></div>
        <span style={{fontSize:28}}>🧠</span>
        <div style={{fontSize:13,color:'#A78BFA',fontStyle:'italic',fontWeight:600}}>{t('"Data is the compass — let analytics guide your preparation."','"डेटा कम्पास है — विश्लेषण को मार्गदर्शक बनाएं।"')}</div>
      </div>

      {results.length>1 && (
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(12px)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:14}}>📈 {t('Score Trend','स्कोर ट्रेंड')}</div>
          <div style={{display:'flex',alignItems:'flex-end',gap:8,height:100}}>
            {results.slice(0,5).reverse().map((r:any,i:number)=>{
              const h=Math.round(((r.score||0)/720)*100)
              const col=h>80?C.success:h>60?C.primary:h>40?C.warn:C.danger
              return (
                <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:4}}>
                  <div style={{fontSize:10,color:col,fontWeight:700}}>{r.score}</div>
                  <div style={{width:'100%',height:`${h}%`,background:`linear-gradient(180deg,${col},${col}44)`,borderRadius:'5px 5px 0 0',minHeight:4,transition:'height .8s ease'}}/>
                  <div style={{fontSize:9,color:C.sub}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{month:'short',day:'numeric'}):`T${i+1}`}</div>
                </div>
              )
            })}
          </div>
        </div>
      )}

      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:14}}>🔬 {t('Subject Performance','विषय प्रदर्शन')}</div>
        {[{n:t('Physics','भौतिकी'),icon:'⚛️',sc:results[0]?.subjectScores?.physics||0,tot:180,col:'#00B4FF'},{n:t('Chemistry','रसायन'),icon:'🧪',sc:results[0]?.subjectScores?.chemistry||0,tot:180,col:'#FF6B9D'},{n:t('Biology','जीव विज्ञान'),icon:'🧬',sc:results[0]?.subjectScores?.biology||0,tot:360,col:'#00E5A0'}].map(s=>{
          const p=s.sc?Math.round((s.sc/s.tot)*100):0
          return (
            <div key={s.n} style={{marginBottom:14,padding:'10px',background:'rgba(77,159,255,.04)',borderRadius:9}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:7,fontSize:12}}>
                <span style={{fontWeight:700,color:s.col}}>{s.icon} {s.n}</span>
                <span style={{color:C.sub}}>{s.sc||'—'}/{s.tot} <span style={{color:s.col,fontWeight:700}}>({p}%)</span></span>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:5,height:9,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${p}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:5,transition:'width .8s'}}/>
              </div>
            </div>
          )
        })}
      </div>

      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:18}}>
        <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(255,77,77,.2)',borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:C.danger,marginBottom:12}}>⚠️ {t('Weak Chapters','कमजोर अध्याय')}</div>
          {weak.map((ch,i)=>(
            <div key={i} style={{marginBottom:10}}>
              <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                <div><div style={{fontWeight:600,color:dm?C.text:C.textL,fontSize:11}}>{ch.name}</div><div style={{fontSize:10,color:ch.col}}>{ch.sub}</div></div>
                <div style={{display:'flex',alignItems:'center',gap:6}}>
                  <span style={{color:C.warn,fontWeight:700,fontSize:13}}>{ch.pct}%</span>
                  <a href="/revision" style={{fontSize:9,padding:'2px 7px',background:`${C.primary}22`,color:C.primary,border:`1px solid ${C.primary}44`,borderRadius:5,textDecoration:'none',fontWeight:600}}>{t('Revise','रिवाइज')}</a>
                </div>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:4,height:6,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${ch.pct}%`,background:`linear-gradient(90deg,${C.danger},${C.warn})`,borderRadius:4}}/>
              </div>
            </div>
          ))}
        </div>
        <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(0,196,140,.2)',borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:C.success,marginBottom:12}}>💪 {t('Strong Chapters','मजबूत अध्याय')}</div>
          {strong.map((ch,i)=>(
            <div key={i} style={{marginBottom:10}}>
              <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                <span style={{fontWeight:600,color:dm?C.text:C.textL,fontSize:11}}>{ch.name}</span>
                <span style={{color:C.success,fontWeight:700,fontSize:13}}>{ch.pct}%</span>
              </div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:4,height:6,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${ch.pct}%`,background:`linear-gradient(90deg,${C.success}88,${C.success})`,borderRadius:4}}/>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(255,215,0,.2)',borderRadius:16,padding:18,backdropFilter:'blur(12px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:14}}>🎯 {t('vs NEET Cutoff (N4)','NEET कटऑफ से तुलना')}</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
          <div style={{textAlign:'center',padding:'12px',background:'rgba(77,159,255,.08)',borderRadius:12,border:`1px solid ${C.border}`}}>
            <div style={{fontWeight:800,fontSize:24,color:C.primary,fontFamily:'Playfair Display,serif'}}>{avg||'—'}</div>
            <div style={{fontSize:11,color:C.sub,marginTop:3}}>{t('Your Avg','आपका औसत')}</div>
          </div>
          <div style={{textAlign:'center',padding:'12px',background:'rgba(255,215,0,.08)',borderRadius:12,border:'1px solid rgba(255,215,0,.2)'}}>
            <div style={{fontWeight:800,fontSize:24,color:C.gold,fontFamily:'Playfair Display,serif'}}>{neet}</div>
            <div style={{fontSize:11,color:C.sub,marginTop:3}}>{t('NEET 2025 Cutoff','NEET 2025 कटऑफ')}</div>
          </div>
        </div>
        {avg>0 && (
          <div>
            <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:5}}>
              <span style={{color:C.sub}}>{t('vs NEET Cutoff','NEET कटऑफ से')}</span>
              <span style={{color:avg>=neet?C.success:C.danger,fontWeight:700}}>{avg>=neet?t('✅ Above Cutoff','✅ कटऑफ से ऊपर'):`❌ ${neet-avg} ${t('more marks needed','और अंक चाहिए')}`}</span>
            </div>
            <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:12,overflow:'hidden',position:'relative'}}>
              <div style={{height:'100%',width:`${Math.min(100,(avg/720)*100)}%`,background:`linear-gradient(90deg,${avg>=neet?C.success:C.warn},${avg>=neet?C.success:C.danger})`,borderRadius:6,transition:'width .8s'}}/>
              <div style={{position:'absolute',top:0,bottom:0,left:`${(neet/720)*100}%`,width:2,background:C.gold}}/>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default function AnalyticsPage() {
  return <StudentShell pageKey="analytics"><AnalyticsContent/></StudentShell>
}
