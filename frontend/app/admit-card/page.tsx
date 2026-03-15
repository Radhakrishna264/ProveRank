'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D' }

export default function AdmitCardPage() {
  return (
    <StudentShell pageKey="admit-card">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [exams, setExams] = useState<any[]>([])
        const [selExam, setSelExam] = useState<any>(null)
        const [loading, setLoading] = useState(true)
        const rollNo = `PR2026-${String(Math.abs((user?.email||'').split('').reduce((a:number,c:string)=>a+c.charCodeAt(0),0)%99999)).padStart(5,'0')}`

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
            const list = Array.isArray(d)?d.filter((e:any)=>new Date(e.scheduledAt)>new Date()):[]
            setExams(list); if(list.length>0) setSelExam(list[0]); setLoading(false)
          }).catch(()=>setLoading(false))
        },[token])

        const downloadCard = async (exam:any) => {
          try {
            const res = await fetch(`${API}/api/exams/${exam._id}/admit-card`,{headers:{Authorization:`Bearer ${token}`}})
            if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='admit_card.pdf';a.click();toast(lang==='en'?'Admit card downloaded!':'प्रवेश पत्र डाउनलोड हुआ!','s')}
            else toast(lang==='en'?'Admit card not available yet':'प्रवेश पत्र अभी उपलब्ध नहीं','w')
          } catch{toast('Network error','e')}
        }

        const instructions = lang==='en'?['Webcam required — keep it on throughout the exam','Stable internet connection (10 Mbps minimum)','Quiet environment — no noise or disturbance','Valid ID proof ready for verification','Fullscreen mode will be enforced']:['वेबकैम आवश्यक — परीक्षा के दौरान चालू रखें','स्थिर इंटरनेट कनेक्शन (10 Mbps न्यूनतम)','शांत वातावरण — कोई शोर या व्यवधान नहीं','सत्यापन के लिए वैध आईडी प्रूफ तैयार रखें','फुलस्क्रीन मोड अनिवार्य होगा']

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Admit Card':'प्रवेश पत्र'}</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Download admit cards for upcoming exams':'आगामी परीक्षाओं के लिए प्रवेश पत्र डाउनलोड करें'}</div>
            </div>

            {/* Quote */}
            <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(77,159,255,0.2)`,borderRadius:16,padding:'16px 20px',marginBottom:24,display:'flex',alignItems:'center',gap:14}}>
              <span style={{fontSize:30}}>🪪</span>
              <div>
                <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600}}>{lang==='en'?'"Your admit card is your passport to success — carry it with pride."':'"आपका प्रवेश पत्र सफलता का पासपोर्ट है — गर्व के साथ लेकर चलें।"'}</div>
                <div style={{fontSize:11,color:C.sub,marginTop:2}}>{lang==='en'?'"आपका प्रवेश पत्र सफलता का पासपोर्ट है।"':'Your admit card is your passport to success.'}</div>
              </div>
            </div>

            {/* Exam Tabs */}
            {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:exams.length===0?(
              <div style={{textAlign:'center',padding:'60px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:20,border:`1px solid ${C.border}`}}>
                <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{display:'block',margin:'0 auto 16px'}}>
                  <rect x="12" y="8" width="56" height="64" rx="5" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                  <path d="M24 24h32M24 34h24M24 44h16" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
                  <circle cx="60" cy="60" r="14" fill="rgba(0,196,140,0.2)" stroke="#00C48C" strokeWidth="1.5"/>
                  <path d="M54 60 L58 64 L66 56" stroke="#00C48C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <div style={{fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:6}}>{lang==='en'?'No upcoming exams':'कोई आगामी परीक्षा नहीं'}</div>
                <div style={{fontSize:12,color:C.sub}}>{lang==='en'?'Admit cards for scheduled exams will appear here':'निर्धारित परीक्षाओं के प्रवेश पत्र यहां दिखेंगे'}</div>
              </div>
            ):(
              <>
                {/* Exam Selector */}
                <div style={{display:'flex',gap:8,marginBottom:20,flexWrap:'wrap'}}>
                  {exams.map((e:any)=>(
                    <button key={e._id} onClick={()=>setSelExam(e)} style={{padding:'9px 16px',borderRadius:10,border:`1px solid ${selExam?._id===e._id?C.primary:C.border}`,background:selExam?._id===e._id?`${C.primary}22`:C.card,color:selExam?._id===e._id?C.primary:C.sub,cursor:'pointer',fontSize:12,fontWeight:selExam?._id===e._id?700:400,fontFamily:'Inter,sans-serif'}}>
                      {e.title}
                    </button>
                  ))}
                </div>

                {/* Admit Card Design */}
                {selExam&&(
                  <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid rgba(77,159,255,0.35)`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(12px)',marginBottom:20}}>
                    {/* Card Top Bar */}
                    <div style={{background:'linear-gradient(135deg,#001F3F,#003366)',padding:'14px 24px',display:'flex',justifyContent:'space-between',alignItems:'center',borderBottom:`1px solid rgba(77,159,255,0.3)`}}>
                      <div style={{display:'flex',alignItems:'center',gap:10}}>
                        <svg width="32" height="32" viewBox="0 0 64 64"><polygon points="56.3,32 49.5,25.5 51.5,16.5 42.8,14 39.2,5.8 32,10 24.8,5.8 21.2,14 12.5,16.5 14.5,25.5 7.7,32 14.5,38.5 12.5,47.5 21.2,50 24.8,58.2 32,54 39.2,58.2 42.8,50 51.5,47.5 49.5,38.5" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/><text x="32" y="36" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF">PR</text></svg>
                        <div>
                          <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#fff'}}>ProveRank</div>
                          <div style={{fontSize:9,color:'rgba(77,159,255,0.7)',letterSpacing:2}}>ADMIT CARD</div>
                        </div>
                      </div>
                      <span style={{fontSize:11,padding:'3px 10px',borderRadius:20,background:'rgba(0,196,140,0.2)',color:C.success,border:'1px solid rgba(0,196,140,0.3)',fontWeight:700}}>✓ VALID</span>
                    </div>

                    <div style={{padding:24}}>
                      <div style={{display:'grid',gridTemplateColumns:'1fr auto',gap:16,marginBottom:20}}>
                        <div>
                          <div style={{display:'grid',gap:10}}>
                            {[[lang==='en'?'EXAM NAME':'परीक्षा नाम',selExam.title],[lang==='en'?'DATE':'तारीख',new Date(selExam.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'long',year:'numeric'})],[lang==='en'?'TIME':'समय',new Date(selExam.scheduledAt).toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit'})+' — '+new Date(new Date(selExam.scheduledAt).getTime()+selExam.duration*60000).toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit'})],[lang==='en'?'MODE':'मोड','Online (ProveRank Platform)'],[lang==='en'?'ROLL NUMBER':'रोल नंबर',rollNo]].map(([l,v])=>(
                              <div key={String(l)} style={{display:'flex',gap:10,alignItems:'flex-start'}}>
                                <span style={{fontSize:10,color:C.primary,fontWeight:700,textTransform:'uppercase',minWidth:100,paddingTop:1}}>{l}</span>
                                <span style={{fontSize:13,color:dm?C.text:'#0F172A',fontWeight:600}}>{String(v)}</span>
                              </div>
                            ))}
                          </div>
                        </div>
                        {/* QR Code placeholder */}
                        <div style={{textAlign:'center'}}>
                          <div style={{width:80,height:80,background:'rgba(77,159,255,0.1)',border:`1px solid ${C.border}`,borderRadius:8,display:'flex',alignItems:'center',justifyContent:'center',marginBottom:4}}>
                            <svg width="50" height="50" viewBox="0 0 50 50" fill="none">
                              {[0,1,2,3,4,5,6].map(row=>[0,1,2,3,4,5,6].map(col=>(<rect key={`${row}-${col}`} x={col*7} y={row*7} width="6" height="6" rx="1" fill={Math.random()>0.5?'#4D9FFF':'transparent'} opacity=".7"/>)))}
                            </svg>
                          </div>
                          <div style={{fontSize:9,color:C.sub}}>Scan to verify</div>
                        </div>
                      </div>

                      {/* Instructions */}
                      <div style={{background:'rgba(255,184,77,0.06)',border:'1px solid rgba(255,184,77,0.2)',borderRadius:10,padding:'12px 16px'}}>
                        <div style={{fontSize:11,color:C.gold,fontWeight:700,marginBottom:8}}>⚠️ {lang==='en'?'Instructions':'निर्देश'}</div>
                        {instructions.map((ins,i)=>(
                          <div key={i} style={{fontSize:11,color:C.sub,marginBottom:4}}>• {ins}</div>
                        ))}
                      </div>
                    </div>

                    <div style={{padding:'14px 24px',borderTop:`1px solid ${C.border}`,display:'flex',gap:10,flexWrap:'wrap'}}>
                      <button onClick={()=>downloadCard(selExam)} className="btn-p">📥 {lang==='en'?'Download Admit Card':'प्रवेश पत्र डाउनलोड'}</button>
                      <a href={`/exam/${selExam._id}`} className="btn-g" style={{textDecoration:'none'}}>🚀 {lang==='en'?'Start Exam':'परीक्षा शुरू करें'}</a>
                    </div>
                  </div>
                )}
              </>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
