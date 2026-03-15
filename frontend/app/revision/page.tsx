'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function RevisionContent() {
  const { lang, darkMode:dm, token } = useShell()
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const weak=[
    {topic:t('Inorganic Chemistry','अकार्बनिक रसायन'),sub:'Chemistry',acc:52,priority:'high',col:'#FF6B9D'},
    {topic:t('Thermodynamics','ऊष्मागतिकी'),sub:'Physics',acc:58,priority:'high',col:C.warn},
    {topic:t('Plant Physiology','पादप शरीर क्रिया'),sub:'Biology',acc:63,priority:'medium',col:C.primary},
    {topic:t('Modern Physics','आधुनिक भौतिकी'),sub:'Physics',acc:66,priority:'medium',col:C.warn},
    {topic:t('Chemical Equilibrium','रासायनिक साम्यावस्था'),sub:'Chemistry',acc:70,priority:'low',col:C.success},
  ]
  const plan = lang==='en'?['Day 1-2: Inorganic Chemistry (P-block, D-block)','Day 3: Thermodynamics (Laws, Gibbs energy)','Day 4-5: Plant Physiology (Photosynthesis, Respiration)','Day 6: Modern Physics (Photoelectric, Nuclear)','Day 7: Full Mock Test + Analysis']:['दिन 1-2: अकार्बनिक रसायन (P-ब्लॉक, D-ब्लॉक)','दिन 3: ऊष्मागतिकी (नियम, गिब्स ऊर्जा)','दिन 4-5: पादप शरीर क्रिया (प्रकाश संश्लेषण, श्वसन)','दिन 6: आधुनिक भौतिकी (फोटोइलेक्ट्रिक, नाभिकीय)','दिन 7: पूर्ण मॉक टेस्ट + विश्लेषण']

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.purple||'#A78BFA'},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🧠 {t('Smart Revision','स्मार्ट रिवीजन')} (S81/S44)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('AI-powered revision based on your weak areas','आपके कमजोर क्षेत्रों पर AI-आधारित रिवीजन')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(167,139,250,.14),rgba(0,22,40,.9))',border:'1px solid rgba(167,139,250,.28)',borderRadius:18,padding:18,marginBottom:22}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:7}}>
          <span style={{fontSize:26}}>🧠</span>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:C.purple||'#A78BFA'}}>{t('AI-Powered Smart Revision','AI-संचालित स्मार्ट रिवीजन')}</div>
        </div>
        <div style={{fontSize:13,color:C.purple||'#A78BFA',fontStyle:'italic',fontWeight:600}}>{t('"Focus on your weak areas today — they will become your strengths tomorrow."','"आज के कमजोर क्षेत्रों पर ध्यान दें — वे कल की ताकत बनेंगे।"')}</div>
      </div>

      <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:12}}>🎯 {t('Revision Priority List','रिवीजन प्राथमिकता सूची')}</div>

      {weak.map((w,i)=>(
        <div key={i} className="card-h" style={{background:dm?C.card:C.cardL,border:`1px solid ${w.acc<60?'rgba(255,77,77,.3)':w.acc<70?'rgba(255,184,77,.3)':C.border}`,borderRadius:13,padding:'14px 18px',marginBottom:10,backdropFilter:'blur(12px)',transition:'all .2s'}}>
          <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:9,marginBottom:8,alignItems:'center'}}>
            <div>
              <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:3}}>{w.topic}</div>
              <div style={{display:'flex',gap:7,flexWrap:'wrap'}}>
                <span style={{fontSize:10,padding:'2px 7px',borderRadius:20,background:`${w.col}15`,color:w.col,fontWeight:600}}>{w.sub}</span>
                <span style={{fontSize:10,padding:'2px 7px',borderRadius:20,background:w.priority==='high'?`${C.danger}15`:w.priority==='medium'?`${C.warn}15`:`${C.success}15`,color:w.priority==='high'?C.danger:w.priority==='medium'?C.warn:C.success,fontWeight:600}}>{w.priority==='high'?t('High','उच्च'):w.priority==='medium'?t('Medium','मध्यम'):t('Low','कम')}</span>
              </div>
            </div>
            <div style={{display:'flex',gap:10,alignItems:'center'}}>
              <div style={{textAlign:'center'}}>
                <div style={{fontWeight:800,fontSize:20,color:w.acc<60?C.danger:w.acc<70?C.warn:C.success}}>{w.acc}%</div>
                <div style={{fontSize:9,color:C.sub}}>{t('Accuracy','सटीकता')}</div>
              </div>
              <a href="/pyq-bank" style={{padding:'7px 13px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:9,textDecoration:'none',fontWeight:700,fontSize:11}}>{t('Revise →','रिवाइज →')}</a>
            </div>
          </div>
          <div style={{background:'rgba(255,255,255,.06)',borderRadius:5,height:8,overflow:'hidden'}}>
            <div style={{height:'100%',width:`${w.acc}%`,background:`linear-gradient(90deg,${w.acc<60?C.danger:w.acc<70?C.warn:C.success}88,${w.acc<60?C.danger:w.acc<70?C.warn:C.success})`,borderRadius:5,transition:'width .6s'}}/>
          </div>
        </div>
      ))}

      <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(167,139,250,.18)',borderRadius:14,padding:18,backdropFilter:'blur(12px)',marginTop:6}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:12}}>📅 {t('7-Day Revision Plan','7-दिन की रिवीजन योजना')}</div>
        {plan.map((p,i)=>(
          <div key={i} style={{display:'flex',gap:10,padding:'8px 0',borderBottom:`1px solid ${C.border}`,alignItems:'center',fontSize:12}}>
            <span style={{width:26,height:26,borderRadius:'50%',background:`${C.primary}22`,border:`1px solid ${C.primary}44`,display:'flex',alignItems:'center',justifyContent:'center',color:C.primary,fontWeight:700,fontSize:11,flexShrink:0}}>{i+1}</span>
            <span style={{color:dm?C.text:C.textL}}>{p}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
export default function RevisionPage() {
  return <StudentShell pageKey="revision"><RevisionContent/></StudentShell>
}
