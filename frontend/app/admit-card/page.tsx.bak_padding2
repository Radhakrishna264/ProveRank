'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
function AdmitCardContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [exams,setExams]=useState<any[]>([]); const [selIdx,setSelIdx]=useState(0); const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  const rollNo=`PR2026-${String(Math.abs((user?.email||'x').split('').reduce((a:number,c:string)=>a+c.charCodeAt(0),0)%99999)).padStart(5,'0')}`
  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{const list=Array.isArray(d)?d.filter((e:any)=>new Date(e.scheduledAt)>new Date()):[];setExams(list);setLoading(false)}).catch(()=>setLoading(false))
  },[token])
  const sel=exams[selIdx]
  const download=async()=>{
    if(!sel) return
    try{const r=await fetch(`${API}/api/exams/${sel._id}/admit-card`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='admit_card.pdf';a.click();toast(t('Downloaded!','डाउनलोड हुआ!'),'s')}else toast(t('Not available yet','अभी उपलब्ध नहीं'),'w')}catch{toast('Network error','e')}
  }
  const instr=lang==='en'?['📷 Webcam required throughout (anti-cheat)','🌐 Stable internet — min 10 Mbps','🔇 Quiet environment — no disturbance','🪪 Valid ID proof ready for verification','📺 Fullscreen mode enforced (S32)','⚠️ 3 tab switches = auto submit (S1/S2)']:['📷 वेबकैम पूरे समय अनिवार्य','🌐 स्थिर इंटरनेट — न्यूनतम 10 Mbps','🔇 शांत वातावरण','🪪 सत्यापन के लिए वैध आईडी','📺 फुलस्क्रीन मोड अनिवार्य','⚠️ 3 टैब स्विच = स्वतः सबमिट']
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🪪 {t('Admit Card','प्रवेश पत्र')} (S106)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Digital admit card for upcoming exams','आगामी परीक्षाओं के लिए डिजिटल प्रवेश पत्र')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="60" height="70" viewBox="0 0 60 70" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <rect x="5" y="5" width="50" height="60" rx="5" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
          <rect x="5" y="5" width="50" height="18" rx="5" fill="rgba(77,159,255,0.2)" stroke="#4D9FFF" strokeWidth="1.5"/>
          <circle cx="14" cy="14" r="5" fill="#4D9FFF" opacity=".7"/>
          <path d="M23 10h22M23 15h15" stroke="#fff" strokeWidth="1.5" strokeLinecap="round" opacity=".7"/>
          <path d="M15 33h30M15 41h20M15 49h25" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
          <rect x="38" y="33" width="15" height="22" rx="2" stroke="#FFD700" strokeWidth="1" fill="rgba(255,215,0,0.1)"/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Your admit card is your passport to success."','"आपका प्रवेश पत्र सफलता का पासपोर्ट है।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{t('Roll No:','रोल नं:')} <span style={{color:C.primary,fontWeight:600}}>{rollNo}</span></div>
        </div>
      </div>
      {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳</div>:
        exams.length===0?(
          <div style={{textAlign:'center',padding:'60px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`,backdropFilter:'blur(14px)'}}>
            <div style={{fontSize:40,marginBottom:12}}>📭</div>
            <div style={{fontWeight:700,fontSize:16,color:dm?C.text:C.textL,marginBottom:6}}>{t('No upcoming exams','कोई आगामी परीक्षा नहीं')}</div>
            <div style={{fontSize:12,color:C.sub}}>{t('Admit cards for scheduled exams will appear here.','निर्धारित परीक्षाओं के प्रवेश पत्र यहां दिखेंगे।')}</div>
          </div>
        ):(
          <>
            <div style={{display:'flex',gap:8,marginBottom:18,flexWrap:'wrap'}}>
              {exams.map((e:any,i:number)=>(
                <button key={e._id} onClick={()=>setSelIdx(i)} style={{padding:'8px 14px',borderRadius:9,border:`1px solid ${i===selIdx?C.primary:C.border}`,background:i===selIdx?`${C.primary}22`:C.card,color:i===selIdx?C.primary:C.sub,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif',fontWeight:i===selIdx?700:400,transition:'all .2s'}}>
                  {e.title?.split(' ').slice(0,3).join(' ')||'Exam'}
                </button>
              ))}
            </div>
            {sel&&(
              <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(77,159,255,.35)',borderRadius:20,overflow:'hidden',backdropFilter:'blur(14px)'}}>
                <div style={{background:'linear-gradient(135deg,#001F3F,#003366)',padding:'14px 22px',display:'flex',justifyContent:'space-between',alignItems:'center',borderBottom:'1px solid rgba(77,159,255,.25)'}}>
                  <div style={{display:'flex',alignItems:'center',gap:10}}>
                    <svg width="26" height="26" viewBox="0 0 64 64"><polygon points="56.3,32 49.5,25.5 51.5,16.5 42.8,14 39.2,5.8 32,10 24.8,5.8 21.2,14 12.5,16.5 14.5,25.5 7.7,32 14.5,38.5 12.5,47.5 21.2,50 24.8,58.2 32,54 39.2,58.2 42.8,50 51.5,47.5 49.5,38.5" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF">PR</text></svg>
                    <div><div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:'#fff'}}>ProveRank</div><div style={{fontSize:8,color:'rgba(77,159,255,.7)',letterSpacing:2}}>ADMIT CARD</div></div>
                  </div>
                  <span style={{fontSize:10,padding:'2px 9px',borderRadius:20,background:'rgba(0,196,140,.2)',color:C.success,fontWeight:700}}>✓ VALID</span>
                </div>
                <div style={{padding:22}}>
                  <div style={{display:'grid',gap:10,marginBottom:18}}>
                    {[[t('EXAM NAME','परीक्षा नाम'),sel.title],[t('DATE','तारीख'),new Date(sel.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'long',year:'numeric'})],[t('TIME','समय'),new Date(sel.scheduledAt).toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit'})],[t('DURATION','अवधि'),`${sel.duration} ${t('minutes','मिनट')}`],[t('TOTAL MARKS','कुल अंक'),`${sel.totalMarks}`],[t('MODE','मोड'),'Online (ProveRank Platform)'],[t('ROLL NUMBER','रोल नंबर'),rollNo]].map(([l,v])=>(
                      <div key={String(l)} style={{display:'flex',gap:12}}>
                        <span style={{fontSize:10,color:C.primary,fontWeight:700,textTransform:'uppercase',minWidth:100,letterSpacing:.3}}>{l}</span>
                        <span style={{fontSize:13,color:dm?C.text:C.textL,fontWeight:600}}>{String(v)}</span>
                      </div>
                    ))}
                  </div>
                  <div style={{background:'rgba(255,184,77,.07)',border:'1px solid rgba(255,184,77,.22)',borderRadius:10,padding:'12px 16px'}}>
                    <div style={{fontSize:11,color:C.warn,fontWeight:700,marginBottom:8}}>⚠️ {t('Instructions','निर्देश')}</div>
                    {instr.map((ins,i)=><div key={i} style={{fontSize:11,color:C.sub,marginBottom:4}}>{ins}</div>)}
                  </div>
                </div>
                <div style={{padding:'14px 22px',borderTop:`1px solid ${C.border}`,display:'flex',gap:10,flexWrap:'wrap'}}>
                  <button onClick={download} className="btn-p">📥 {t('Download PDF','PDF डाउनलोड')}</button>
                  <a href={`/exam/${sel._id}`} className="btn-g" style={{textDecoration:'none'}}>🚀 {t('Start Exam','शुरू')}</a>
                </div>
              </div>
            )}
          </>
        )
      }
    </div>
  )
}
export default function AdmitCardPage() {
  return <StudentShell pageKey="admit-card"><AdmitCardContent/></StudentShell>
}
