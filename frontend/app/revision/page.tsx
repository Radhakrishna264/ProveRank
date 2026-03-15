'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function BrainSVG() {
  return (
    <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
      <circle cx="40" cy="40" r="34" stroke="#A78BFA" strokeWidth="1.5" strokeDasharray="4 4"/>
      <circle cx="40" cy="40" r="22" stroke="#A78BFA" strokeWidth="1" opacity=".5" fill="rgba(167,139,250,0.08)"/>
      {/* Neural connections */}
      {[[40,18,56,28],[40,18,24,28],[56,28,62,42],[24,28,18,42],[62,42,56,56],[18,42,24,56],[56,56,40,62],[24,56,40,62]].map(([x1,y1,x2,y2],i)=>(
        <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke="#A78BFA" strokeWidth="1" opacity=".5"/>
      ))}
      {[[40,18],[56,28],[24,28],[62,42],[18,42],[56,56],[24,56],[40,62],[40,40]].map(([x,y],i)=>(
        <circle key={i} cx={x} cy={y} r={i===8?6:3.5} fill={i===8?'rgba(167,139,250,0.4)':'#A78BFA'} stroke="#A78BFA" strokeWidth={i===8?1.5:0}/>
      ))}
      <circle cx="40" cy="40" r="2" fill="#A78BFA" style={{animation:'pulse 1.5s infinite'}}/>
    </svg>
  )
}

function RevisionContent() {
  const {lang,darkMode:dm,token}=useShell()
  const [results,setResults]=useState<any[]>([])
  const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const hasData=results.length>0

  // Generate weak chapters only from REAL data
  const weakTopics = hasData?(()=>{
    const phys=results.reduce((a,r:any)=>a+(r.subjectScores?.physics||0),0)/results.length
    const chem=results.reduce((a,r:any)=>a+(r.subjectScores?.chemistry||0),0)/results.length
    const bio=results.reduce((a,r:any)=>a+(r.subjectScores?.biology||0),0)/results.length
    const weak=[]
    if(phys<140) weak.push({topic:t('Physics','भौतिकी'),acc:Math.round((phys/180)*100),col:'#00B4FF',priority:'high',sub:'Physics'})
    if(chem<140) weak.push({topic:t('Chemistry','रसायन'),acc:Math.round((chem/180)*100),col:'#FF6B9D',priority:'high',sub:'Chemistry'})
    if(bio<280) weak.push({topic:t('Biology','जीव विज्ञान'),acc:Math.round((bio/360)*100),col:'#00E5A0',priority:bio<200?'high':'medium',sub:'Biology'})
    return weak
  })():[]

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.purple},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🧠 {t('Smart Revision','स्मार्ट रिवीजन')} (S81/S44)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('AI-powered revision suggestions based on your performance data','आपके प्रदर्शन डेटा पर आधारित AI-संचालित रिवीजन सुझाव')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(167,139,250,.14),rgba(0,22,40,.9))',border:'1px solid rgba(167,139,250,.28)',borderRadius:20,padding:20,marginBottom:22,display:'flex',alignItems:'center',gap:16,flexWrap:'wrap'}}>
        <BrainSVG/>
        <div style={{flex:1}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:C.purple,marginBottom:4}}>{t('AI-Powered Smart Revision','AI-संचालित स्मार्ट रिवीजन')}</div>
          <div style={{fontSize:13,color:C.purple,fontStyle:'italic',fontWeight:600,marginBottom:4}}>{t('"Focus on your weak areas today — they will become your strengths tomorrow."','"आज के कमजोर क्षेत्रों पर ध्यान दें — वे कल की ताकत बनेंगे।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{hasData?`${t('Based on your last','पिछले')} ${results.length} ${t('exam(s)','परीक्षा के आधार पर')}`:t('Give your first exam to get personalized revision suggestions!','व्यक्तिगत रिवीजन सुझाव के लिए पहला एग्जाम दें!')}</div>
        </div>
      </div>

      {!hasData&&!loading?(
        <div style={{textAlign:'center',padding:'60px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`,backdropFilter:'blur(14px)',marginBottom:20}}>
          <BrainSVG/>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:dm?C.text:C.textL,marginTop:14,marginBottom:8}}>{t('No revision data yet!','अभी कोई रिवीजन डेटा नहीं!')}</div>
          <div style={{fontSize:13,color:C.sub,maxWidth:360,margin:'0 auto 20px',lineHeight:1.6}}>{t('Smart Revision will show your weak topics, strong chapters, and a personalized 7-day study plan after your first exam.','पहले एग्जाम के बाद Smart Revision आपके कमजोर विषय और 7-दिन की योजना दिखाएगा।')}</div>
          <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('📝 Give First Exam →','📝 पहला एग्जाम दें →')}</a>
        </div>
      ):(
        <>
          {weakTopics.length>0?(
            <div style={{marginBottom:20}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:12}}>⚠️ {t('Areas Needing Attention','ध्यान देने वाले क्षेत्र')}</div>
              {weakTopics.map((w,i)=>(
                <div key={i} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${w.acc<60?'rgba(255,77,77,.3)':w.acc<75?'rgba(255,184,77,.3)':C.border}`,borderRadius:14,padding:'16px 18px',marginBottom:10,backdropFilter:'blur(14px)',transition:'all .25s'}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:9,marginBottom:9,alignItems:'center'}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:4}}>{w.topic}</div>
                      <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:w.acc<60?`${C.danger}15`:`${C.warn}15`,color:w.acc<60?C.danger:C.warn,fontWeight:600}}>{w.acc<60?t('High Priority','उच्च प्राथमिकता'):t('Medium Priority','मध्यम प्राथमिकता')}</span>
                    </div>
                    <div style={{display:'flex',gap:10,alignItems:'center'}}>
                      <div style={{textAlign:'center'}}>
                        <div style={{fontWeight:800,fontSize:20,color:w.acc<60?C.danger:C.warn}}>{w.acc}%</div>
                        <div style={{fontSize:9,color:C.sub}}>{t('Accuracy','सटीकता')}</div>
                      </div>
                      <a href="/pyq-bank" style={{padding:'8px 14px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:9,textDecoration:'none',fontWeight:700,fontSize:12}}>{t('Revise →','रिवाइज →')}</a>
                    </div>
                  </div>
                  <div style={{background:'rgba(255,255,255,.06)',borderRadius:6,height:9,overflow:'hidden'}}>
                    <div style={{height:'100%',width:`${w.acc}%`,background:`linear-gradient(90deg,${w.acc<60?C.danger:C.warn}88,${w.acc<60?C.danger:C.warn})`,borderRadius:6,transition:'width .8s'}}/>
                  </div>
                </div>
              ))}
            </div>
          ):(
            <div style={{padding:'20px',background:'rgba(0,196,140,.07)',border:'1px solid rgba(0,196,140,.2)',borderRadius:14,marginBottom:20,textAlign:'center'}}>
              <div style={{fontSize:16,marginBottom:6}}>🎉</div>
              <div style={{fontWeight:700,color:C.success,fontSize:14}}>{t('Great performance! All subjects above target!','बेहतरीन प्रदर्शन! सभी विषय लक्ष्य से ऊपर!')}</div>
              <div style={{fontSize:12,color:C.sub,marginTop:4}}>{t('Keep practicing with PYQ Bank to maintain your edge.','अपना बढ़त बनाए रखने के लिए PYQ Bank से अभ्यास जारी रखें।')}</div>
            </div>
          )}

          {/* 7-day plan */}
          <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(167,139,250,.18)',borderRadius:14,padding:18,backdropFilter:'blur(14px)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:12}}>📅 {t('Suggested 7-Day Revision Plan','सुझाया 7-दिन रिवीजन प्लान')}</div>
            {[t('Day 1-2: Focus on your weakest subject chapters','दिन 1-2: अपने सबसे कमजोर विषय अध्याय'),t('Day 3: PYQ Bank — solve 2017-2019 questions','दिन 3: PYQ बैंक — 2017-2019 प्रश्न'),t('Day 4-5: Medium priority topic revision','दिन 4-5: मध्यम प्राथमिकता विषय'),t('Day 6: Full subject mock mini-tests (S103)','दिन 6: पूर्ण विषय मिनी-टेस्ट'),t('Day 7: Full Mock Test + Detailed Analysis','दिन 7: पूर्ण मॉक टेस्ट + विस्तृत विश्लेषण')].map((p,i)=>(
              <div key={i} style={{display:'flex',gap:10,padding:'8px 0',borderBottom:`1px solid ${C.border}`,alignItems:'center',fontSize:12}}>
                <span style={{width:26,height:26,borderRadius:'50%',background:`${C.purple}22`,border:`1px solid ${C.purple}44`,display:'flex',alignItems:'center',justifyContent:'center',color:C.purple,fontWeight:700,fontSize:11,flexShrink:0}}>{i+1}</span>
                <span style={{color:dm?C.text:C.textL}}>{p}</span>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  )
}

export default function RevisionPage() {
  return <StudentShell pageKey="revision"><RevisionContent/></StudentShell>
}
