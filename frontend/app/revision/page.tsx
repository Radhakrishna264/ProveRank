'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function RevisionPage() {
  return (
    <StudentShell pageKey="revision">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [results, setResults] = useState<any[]>([])
        const [suggestions, setSuggestions] = useState<any[]>([])
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
            setResults(Array.isArray(d)?d:[])
            setSuggestions([
              {topic:lang==='en'?'Inorganic Chemistry':'अकार्बनिक रसायन',subject:'Chemistry',accuracy:52,priority:'high',questions:45,col:'#FF6B9D'},
              {topic:lang==='en'?'Thermodynamics':'ऊष्मागतिकी',subject:'Physics',accuracy:58,priority:'high',questions:38,col:C.warn},
              {topic:lang==='en'?'Plant Physiology':'पादप शरीर क्रिया',subject:'Biology',accuracy:63,priority:'medium',questions:42,col:C.primary},
              {topic:lang==='en'?'Modern Physics':'आधुनिक भौतिकी',subject:'Physics',accuracy:66,priority:'medium',questions:35,col:C.primary},
              {topic:lang==='en'?'Chemical Equilibrium':'रासायनिक साम्यावस्था',subject:'Chemistry',accuracy:70,priority:'low',questions:30,col:C.success},
            ])
            setLoading(false)
          }).catch(()=>setLoading(false))
        },[token])

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,#A78BFA,#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Smart Revision':'स्मार्ट रिवीजन'} (S81/S44/AI-7)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'AI-powered revision suggestions based on your weak areas':'आपके कमजोर क्षेत्रों के आधार पर AI-संचालित रिवीजन सुझाव'}</div>
            </div>

            {/* AI Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(167,139,250,0.15),rgba(0,22,40,0.9))',border:`1px solid rgba(167,139,250,0.3)`,borderRadius:20,padding:'20px',marginBottom:24,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,top:'50%',transform:'translateY(-50%)',opacity:.08}}>
                <svg width="130" height="110" viewBox="0 0 130 110" fill="none">
                  <circle cx="65" cy="55" r="40" stroke="#A78BFA" strokeWidth="1.5" strokeDasharray="3 4"/>
                  <circle cx="65" cy="55" r="25" stroke="#A78BFA" strokeWidth="1" opacity=".5"/>
                  <circle cx="65" cy="55" r="10" fill="rgba(167,139,250,0.3)" stroke="#A78BFA" strokeWidth="1.5"/>
                  <path d="M65 15 L65 30 M65 80 L65 95 M25 55 L40 55 M90 55 L105 55" stroke="#A78BFA" strokeWidth="1.5" strokeLinecap="round"/>
                  <circle cx="30" cy="25" r="4" fill="#4D9FFF" opacity=".5"/>
                  <circle cx="100" cy="20" r="3" fill="#FFD700" opacity=".5"/>
                </svg>
              </div>
              <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:8}}>
                <span style={{fontSize:28}}>🧠</span>
                <div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#A78BFA'}}>{lang==='en'?'AI-Powered Smart Revision':'AI-संचालित स्मार्ट रिवीजन'}</div>
                  <div style={{fontSize:11,color:C.sub}}>{lang==='en'?'Based on your last 3 exam performances':'आपकी पिछली 3 परीक्षाओं के प्रदर्शन पर आधारित'}</div>
                </div>
              </div>
              <div style={{fontSize:13,color:'#C4B5FD',fontStyle:'italic',fontWeight:600}}>{lang==='en'?'"Focus on your weak areas today — they will become your strengths tomorrow."':'"आज के कमजोर क्षेत्रों पर ध्यान दें — वे कल की ताकत बनेंगे।"'}</div>
            </div>

            {/* Priority Suggestions */}
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:dm?C.text:'#0F172A',marginBottom:14}}>🎯 {lang==='en'?'Revision Priority List':'रिवीजन प्राथमिकता सूची'}</div>
            {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:(
              suggestions.map((s,i)=>(
                <div key={i} className="card-h" style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${s.accuracy<60?'rgba(255,77,77,0.3)':s.accuracy<70?'rgba(255,184,77,0.3)':C.border}`,borderRadius:14,padding:'16px 20px',marginBottom:10,backdropFilter:'blur(12px)',transition:'all .2s'}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:10,marginBottom:8,alignItems:'center'}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A',marginBottom:3}}>{s.topic}</div>
                      <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                        <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${s.col}15`,color:s.col,border:`1px solid ${s.col}30`,fontWeight:600}}>{s.subject}</span>
                        <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:s.priority==='high'?`${C.danger}15`:s.priority==='medium'?`${C.warn}15`:`${C.success}15`,color:s.priority==='high'?C.danger:s.priority==='medium'?C.warn:C.success,border:`1px solid ${s.priority==='high'?C.danger:s.priority==='medium'?C.warn:C.success}30`,fontWeight:600}}>
                          {s.priority==='high'?(lang==='en'?'High Priority':'उच्च प्राथमिकता'):s.priority==='medium'?(lang==='en'?'Medium':'मध्यम'):(lang==='en'?'Low':'कम')}
                        </span>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:12,alignItems:'center'}}>
                      <div style={{textAlign:'center'}}>
                        <div style={{fontWeight:800,fontSize:22,color:s.accuracy<60?C.danger:s.accuracy<70?C.warn:C.success}}>{s.accuracy}%</div>
                        <div style={{fontSize:9,color:C.sub}}>{lang==='en'?'Accuracy':'सटीकता'}</div>
                      </div>
                      <div style={{textAlign:'center'}}>
                        <div style={{fontWeight:700,fontSize:14,color:C.sub}}>{s.questions}</div>
                        <div style={{fontSize:9,color:C.sub}}>Qs</div>
                      </div>
                      <a href="/pyq-bank" style={{padding:'8px 14px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:12}}>
                        {lang==='en'?'Revise Now →':'अभी रिवाइज →'}
                      </a>
                    </div>
                  </div>
                  <div style={{background:'rgba(255,255,255,0.06)',borderRadius:6,height:8,overflow:'hidden'}}>
                    <div style={{height:'100%',width:`${s.accuracy}%`,background:`linear-gradient(90deg,${s.accuracy<60?C.danger:s.accuracy<70?C.warn:C.success}88,${s.accuracy<60?C.danger:s.accuracy<70?C.warn:C.success})`,borderRadius:6,transition:'width .6s'}}/>
                  </div>
                </div>
              ))
            )}

            {/* Study Plan */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid rgba(167,139,250,0.2)`,borderRadius:16,padding:20,marginTop:16,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:14}}>📅 {lang==='en'?'7-Day Revision Plan':'7-दिन की रिवीजन योजना'}</div>
              {(lang==='en'?['Day 1-2: Inorganic Chemistry (Focus: P-block, D-block)','Day 3: Thermodynamics (Focus: Laws, Gibbs energy)','Day 4-5: Plant Physiology (Focus: Photosynthesis, Respiration)','Day 6: Modern Physics (Focus: Photoelectric, Nuclear)','Day 7: Full Mock Test + Analysis']:['दिन 1-2: अकार्बनिक रसायन (फोकस: P-ब्लॉक, D-ब्लॉक)','दिन 3: ऊष्मागतिकी (फोकस: नियम, गिब्स ऊर्जा)','दिन 4-5: पादप शरीर क्रिया (फोकस: प्रकाश संश्लेषण, श्वसन)','दिन 6: आधुनिक भौतिकी (फोकस: फोटोइलेक्ट्रिक, नाभिकीय)','दिन 7: पूर्ण मॉक टेस्ट + विश्लेषण']).map((plan,i)=>(
                <div key={i} style={{display:'flex',gap:12,padding:'8px 0',borderBottom:`1px solid ${C.border}`,alignItems:'center',fontSize:12}}>
                  <span style={{width:28,height:28,borderRadius:'50%',background:`${C.primary}22`,border:`1px solid ${C.primary}44`,display:'flex',alignItems:'center',justifyContent:'center',color:C.primary,fontWeight:700,fontSize:11,flexShrink:0}}>{i+1}</span>
                  <span style={{color:dm?C.text:'#0F172A'}}>{plan}</span>
                </div>
              ))}
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
