'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// Animated Molecule SVG for analytics page
function MoleculeSVG() {
  return (
    <svg width="120" height="120" viewBox="0 0 120 120" fill="none" style={{animation:'spinSlow 20s linear infinite',flexShrink:0}}>
      <circle cx="60" cy="60" r="12" fill="rgba(77,159,255,0.3)" stroke="#4D9FFF" strokeWidth="1.5"/>
      <text x="60" y="65" textAnchor="middle" fontSize="9" fill="#4D9FFF" fontWeight="700">C</text>
      {[0,60,120,180,240,300].map((deg,i)=>{
        const rad=deg*Math.PI/180; const x=60+38*Math.cos(rad); const y=60+38*Math.sin(rad)
        const atom=['H','O','N','H','O','N'][i]
        const col=['#FFD700','#FF6B9D','#00C48C','#FFD700','#FF6B9D','#00C48C'][i]
        return (
          <g key={i}>
            <line x1="60" y1="60" x2={x} y2={y} stroke={col} strokeWidth="1.5" opacity=".6"/>
            <circle cx={x} cy={y} r="8" fill={`${col}33`} stroke={col} strokeWidth="1"/>
            <text x={x} y={y+3} textAnchor="middle" fontSize="7" fill={col} fontWeight="700">{atom}</text>
          </g>
        )
      })}
    </svg>
  )
}

// Empty State SVG
function EmptyAtom() {
  return (
    <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{display:'block',margin:'0 auto',animation:'float 3s ease-in-out infinite'}}>
      <circle cx="40" cy="40" r="35" stroke="#4D9FFF" strokeWidth="1.5" strokeDasharray="5 4"/>
      <circle cx="40" cy="40" r="8" fill="rgba(77,159,255,0.2)" stroke="#4D9FFF" strokeWidth="1.5"/>
      <ellipse cx="40" cy="40" rx="35" ry="12" stroke="#4D9FFF" strokeWidth="1" opacity=".4" transform="rotate(30 40 40)" fill="none"/>
      <ellipse cx="40" cy="40" rx="35" ry="12" stroke="#4D9FFF" strokeWidth="1" opacity=".4" transform="rotate(-30 40 40)" fill="none"/>
    </svg>
  )
}

function AnalyticsContent() {
  const {lang,darkMode:dm,token}=useShell()
  const [results,setResults]=useState<any[]>([])
  const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const hasData = results.length>0
  const avg=hasData?Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length):0
  const neet=550

  // Subject data — ONLY from real API
  const physAvg  = hasData&&results[0]?.subjectScores?.physics!=null  ? Math.round(results.reduce((a,r:any)=>a+(r.subjectScores?.physics||0),0)/results.length) : null
  const chemAvg  = hasData&&results[0]?.subjectScores?.chemistry!=null ? Math.round(results.reduce((a,r:any)=>a+(r.subjectScores?.chemistry||0),0)/results.length) : null
  const bioAvg   = hasData&&results[0]?.subjectScores?.biology!=null  ? Math.round(results.reduce((a,r:any)=>a+(r.subjectScores?.biology||0),0)/results.length) : null

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.purple},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📉 {t('Analytics','विश्लेषण')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Deep performance insights — data-driven NEET preparation','गहरी प्रदर्शन अंतर्दृष्टि — डेटा-आधारित NEET तैयारी')}</div>

      {/* Quote Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(167,139,250,.12),rgba(0,22,40,.88))',border:'1px solid rgba(167,139,250,.22)',borderRadius:20,padding:20,marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
        <MoleculeSVG/>
        <div style={{flex:1}}>
          <div style={{fontSize:15,color:C.purple,fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t('"Data is the compass — let analytics guide your preparation."','"डेटा कम्पास है — विश्लेषण को अपनी तैयारी का मार्गदर्शक बनाएं।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{hasData?`${results.length} ${t('tests analyzed','टेस्ट विश्लेषण')}`:t('Give your first test to unlock analytics!','पहला टेस्ट दें और एनालिटिक्स अनलॉक करें!')}</div>
        </div>
      </div>

      {!hasData&&!loading?(
        /* Empty State */
        <div style={{textAlign:'center',padding:'60px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`,backdropFilter:'blur(14px)',marginBottom:20}}>
          <EmptyAtom/>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:dm?C.text:C.textL,marginTop:16,marginBottom:8}}>{t('No data yet!','अभी कोई डेटा नहीं!')}</div>
          <div style={{fontSize:13,color:C.sub,maxWidth:360,margin:'0 auto 20px',lineHeight:1.6}}>{t('Your analytics dashboard will show performance charts, weak/strong chapters, and NEET cutoff comparison once you give your first exam.','एक बार पहला एग्जाम देने के बाद यहां परफॉर्मेंस चार्ट, कमजोर/मजबूत अध्याय दिखेंगे।')}</div>
          <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('📝 Give First Exam →','📝 पहला एग्जाम दें →')}</a>
        </div>
      ):(
        <>
          {/* Score Trend */}
          {results.length>1&&(
            <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:18,padding:20,marginBottom:18,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:16}}>📈 {t('Score Trend','स्कोर ट्रेंड')}</div>
              <div style={{display:'flex',alignItems:'flex-end',gap:8,height:110,position:'relative'}}>
                {[25,50,75,100].map(p=>(
                  <div key={p} style={{position:'absolute',left:0,right:0,bottom:`${p}%`,borderTop:'1px dashed rgba(77,159,255,.1)'}}>
                    <span style={{fontSize:8,color:C.sub,marginLeft:-26,position:'absolute'}}>{Math.round(p*7.2)}</span>
                  </div>
                ))}
                {results.slice(0,6).reverse().map((r:any,i:number)=>{
                  const h=Math.round(((r.score||0)/720)*100)
                  const col=h>80?C.success:h>60?C.primary:h>40?C.warn:C.danger
                  return (
                    <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:4,position:'relative',zIndex:1}}>
                      <div style={{fontSize:10,color:col,fontWeight:700}}>{r.score}</div>
                      <div style={{width:'100%',height:`${h}%`,background:`linear-gradient(180deg,${col},${col}55)`,borderRadius:'6px 6px 0 0',minHeight:3,transition:'height .8s ease',boxShadow:`0 -2px 8px ${col}33`}}/>
                      <div style={{fontSize:8,color:C.sub,textAlign:'center'}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{month:'short',day:'numeric'}):`T${i+1}`}</div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {/* Subject Performance */}
          <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:18,padding:20,marginBottom:18,backdropFilter:'blur(14px)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:16}}>🔬 {t('Subject Performance','विषय प्रदर्शन')}</div>
            {[{n:t('Physics','भौतिकी'),icon:'⚛️',avg:physAvg,tot:180,col:'#00B4FF'},{n:t('Chemistry','रसायन'),icon:'🧪',avg:chemAvg,tot:180,col:'#FF6B9D'},{n:t('Biology','जीव विज्ञान'),icon:'🧬',avg:bioAvg,tot:360,col:'#00E5A0'}].map(s=>{
              const p=s.avg!=null?Math.round((s.avg/s.tot)*100):0
              return (
                <div key={s.n} style={{marginBottom:16,padding:'12px',background:'rgba(77,159,255,.04)',borderRadius:10}}>
                  <div style={{display:'flex',justifyContent:'space-between',marginBottom:7,fontSize:13}}>
                    <span style={{fontWeight:700,color:s.col}}>{s.icon} {s.n}</span>
                    <span style={{color:C.sub,fontSize:12}}>{s.avg!=null?`${s.avg}/${s.tot}`:'—'} <span style={{color:s.col,fontWeight:700}}>({p}%)</span></span>
                  </div>
                  <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:10,overflow:'hidden'}}>
                    {s.avg!=null
                      ?<div style={{height:'100%',width:`${p}%`,background:`linear-gradient(90deg,${s.col}88,${s.col})`,borderRadius:6,transition:'width .8s'}}/>
                      :<div style={{height:'100%',display:'flex',alignItems:'center',paddingLeft:8,fontSize:9,color:C.sub}}>{t('No data','डेटा नहीं')}</div>
                    }
                  </div>
                </div>
              )
            })}
          </div>

          {/* vs NEET Cutoff */}
          <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(255,215,0,.2)',borderRadius:16,padding:20,marginBottom:18,backdropFilter:'blur(14px)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:14}}>🎯 {t('vs NEET Cutoff (N4)','NEET कटऑफ से तुलना')}</div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:12}}>
              <div style={{padding:'14px',background:'rgba(77,159,255,.08)',borderRadius:12,border:`1px solid ${C.border}`,textAlign:'center'}}>
                <div style={{fontWeight:800,fontSize:26,color:C.primary,fontFamily:'Playfair Display,serif'}}>{avg||'—'}</div>
                <div style={{fontSize:11,color:C.sub,marginTop:3}}>{t('Your Avg','आपका औसत')}</div>
              </div>
              <div style={{padding:'14px',background:'rgba(255,215,0,.08)',borderRadius:12,border:'1px solid rgba(255,215,0,.2)',textAlign:'center'}}>
                <div style={{fontWeight:800,fontSize:26,color:C.gold,fontFamily:'Playfair Display,serif'}}>{neet}</div>
                <div style={{fontSize:11,color:C.sub,marginTop:3}}>{t('NEET 2025 Cutoff','NEET 2025 कटऑफ')}</div>
              </div>
            </div>
            {avg>0&&(
              <div>
                <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:6}}>
                  <span style={{color:C.sub}}>{t('Gap from cutoff','कटऑफ से अंतर')}</span>
                  <span style={{color:avg>=neet?C.success:C.danger,fontWeight:700}}>{avg>=neet?`✅ ${t('Above Cutoff! 🎉','कटऑफ से ऊपर! 🎉')}`:`❌ ${neet-avg} ${t('more marks needed','और अंक चाहिए')}`}</span>
                </div>
                <div style={{background:'rgba(255,255,255,.06)',borderRadius:8,height:12,overflow:'hidden',position:'relative'}}>
                  <div style={{height:'100%',width:`${Math.min(100,(avg/720)*100)}%`,background:`linear-gradient(90deg,${avg>=neet?C.success:C.warn},${avg>=neet?C.success:C.danger})`,borderRadius:8,transition:'width .8s'}}/>
                  <div style={{position:'absolute',top:0,bottom:0,left:`${(neet/720)*100}%`,width:2,background:C.gold}}/>
                </div>
                <div style={{fontSize:9,color:C.sub,marginTop:4}}>{t('Gold line = NEET 2025 Cutoff (550)','सोनी रेखा = NEET 2025 कटऑफ (550)')}</div>
              </div>
            )}
          </div>
        </>
      )}

      {/* Science illustration footer */}
      <div style={{background:'linear-gradient(135deg,rgba(0,196,140,.06),rgba(0,22,40,.85))',border:'1px solid rgba(0,196,140,.15)',borderRadius:18,padding:20,display:'flex',alignItems:'center',gap:16,flexWrap:'wrap'}}>
        <svg width="70" height="70" viewBox="0 0 70 70" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <path d="M35 5 L65 22 L65 57 L35 74 L5 57 L5 22 Z" stroke="#00C48C" strokeWidth="1.5" fill="none"/>
          <path d="M35 18 L52 28 L52 48 L35 58 L18 48 L18 28 Z" stroke="#00C48C" strokeWidth="1" opacity=".5" fill="none"/>
          <circle cx="35" cy="38" r="8" fill="rgba(0,196,140,0.2)" stroke="#00C48C" strokeWidth="1.5"/>
          <circle cx="35" cy="38" r="3" fill="#00C48C"/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.success,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Consistent analysis of your performance is the key to NEET success."','"आपके प्रदर्शन का निरंतर विश्लेषण NEET सफलता की कुंजी है।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{t('Give more tests to unlock detailed chapter-wise analytics and AI insights.','विस्तृत अध्याय-वार एनालिटिक्स और AI अंतर्दृष्टि के लिए अधिक टेस्ट दें।')}</div>
        </div>
      </div>
    </div>
  )
}

export default function AnalyticsPage() {
  return <StudentShell pageKey="analytics"><AnalyticsContent/></StudentShell>
}
