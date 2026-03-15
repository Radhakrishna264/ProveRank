'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function AdmitCardContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [exams,  setExams]  = useState<any[]>([])
  const [selIdx, setSelIdx] = useState(0)
  const [loading,setLoading]= useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
      const list=Array.isArray(d)?d.filter((e:any)=>new Date(e.scheduledAt)>new Date()):[]
      setExams(list); setLoading(false)
    }).catch(()=>setLoading(false))
  },[token])

  const rollNo = `PR2026-${String(Math.abs((user?.email||'x').split('').reduce((a:number,c:string)=>a+c.charCodeAt(0),0)%99999)).padStart(5,'0')}`
  const sel = exams[selIdx]
  const instr = lang==='en'?['Webcam required — keep it on throughout','Stable internet (10 Mbps minimum)','Quiet environment — no disturbance','Valid ID proof ready for verification','Fullscreen mode will be enforced']:['वेबकैम अनिवार्य — पूरे समय चालू रखें','स्थिर इंटरनेट (10 Mbps न्यूनतम)','शांत वातावरण','सत्यापन के लिए आईडी प्रूफ तैयार रखें','फुलस्क्रीन मोड अनिवार्य']

  const download = async () => {
    if(!sel) return
    try {
      const r=await fetch(`${API}/api/exams/${sel._id}/admit-card`,{headers:{Authorization:`Bearer ${token}`}})
      if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='admit_card.pdf';a.click();toast(t('Downloaded!','डाउनलोड हुआ!'),'s')}
      else toast(t('Admit card not available yet','प्रवेश पत्र अभी उपलब्ध नहीं'),'w')
    } catch { toast('Network error','e') }
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🪪 {t('Admit Card','प्रवेश पत्र')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Download admit cards for upcoming exams','आगामी परीक्षाओं के लिए प्रवेश पत्र')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.85))',border:'1px solid rgba(77,159,255,.2)',borderRadius:16,padding:16,marginBottom:22,display:'flex',alignItems:'center',gap:12}}>
        <span style={{fontSize:26}}>🪪</span>
        <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600}}>{t('"Your admit card is your passport to success."','"आपका प्रवेश पत्र सफलता का पासपोर्ट है।"')}</div>
      </div>

      {loading ? <div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div> :
        exams.length===0 ? (
          <div style={{textAlign:'center',padding:'50px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`}}>
            <div style={{fontSize:40,marginBottom:12}}>📭</div>
            <div style={{fontWeight:700,color:dm?C.text:C.textL,marginBottom:6}}>{t('No upcoming exams','कोई आगामी परीक्षा नहीं')}</div>
            <div style={{fontSize:12,color:C.sub}}>{t('Admit cards for scheduled exams will appear here','निर्धारित परीक्षाओं के प्रवेश पत्र यहां दिखेंगे')}</div>
          </div>
        ) : (
          <>
            <div style={{display:'flex',gap:7,marginBottom:18,flexWrap:'wrap'}}>
              {exams.map((e:any,i:number)=>(
                <button key={e._id} onClick={()=>setSelIdx(i)} style={{padding:'8px 14px',borderRadius:9,border:`1px solid ${i===selIdx?C.primary:C.border}`,background:i===selIdx?`${C.primary}22`:C.card,color:i===selIdx?C.primary:C.sub,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif',fontWeight:i===selIdx?700:400}}>
                  {e.title?.split(' ').slice(0,3).join(' ')||'Exam'}
                </button>
              ))}
            </div>
            {sel && (
              <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(77,159,255,.3)',borderRadius:20,overflow:'hidden',backdropFilter:'blur(12px)'}}>
                <div style={{background:'linear-gradient(135deg,#001F3F,#003366)',padding:'12px 22px',display:'flex',justifyContent:'space-between',alignItems:'center',borderBottom:'1px solid rgba(77,159,255,.25)'}}>
                  <div style={{display:'flex',alignItems:'center',gap:9}}>
                    <svg width="28" height="28" viewBox="0 0 64 64"><polygon points="56.3,32 49.5,25.5 51.5,16.5 42.8,14 39.2,5.8 32,10 24.8,5.8 21.2,14 12.5,16.5 14.5,25.5 7.7,32 14.5,38.5 12.5,47.5 21.2,50 24.8,58.2 32,54 39.2,58.2 42.8,50 51.5,47.5 49.5,38.5" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF">PR</text></svg>
                    <div><div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:'#fff'}}>ProveRank</div><div style={{fontSize:8,color:'rgba(77,159,255,.7)',letterSpacing:2}}>ADMIT CARD</div></div>
                  </div>
                  <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:'rgba(0,196,140,.2)',color:C.success,fontWeight:700}}>✓ VALID</span>
                </div>
                <div style={{padding:22}}>
                  <div style={{display:'grid',gap:9,marginBottom:18}}>
                    {[[t('EXAM NAME','परीक्षा नाम'),sel.title],[t('DATE','तारीख'),new Date(sel.scheduledAt).toLocaleDateString('en-IN',{day:'numeric',month:'long',year:'numeric'})],[t('TIME','समय'),new Date(sel.scheduledAt).toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit'})],[t('MODE','मोड'),'Online (ProveRank Platform)'],[t('ROLL NUMBER','रोल नंबर'),rollNo]].map(([l,v])=>(
                      <div key={String(l)} style={{display:'flex',gap:10,alignItems:'flex-start'}}>
                        <span style={{fontSize:10,color:C.primary,fontWeight:700,textTransform:'uppercase',minWidth:90,paddingTop:1}}>{l}</span>
                        <span style={{fontSize:12,color:dm?C.text:C.textL,fontWeight:600}}>{String(v)}</span>
                      </div>
                    ))}
                  </div>
                  <div style={{background:'rgba(255,184,77,.06)',border:'1px solid rgba(255,184,77,.2)',borderRadius:9,padding:'11px 15px'}}>
                    <div style={{fontSize:11,color:C.warn,fontWeight:700,marginBottom:7}}>⚠️ {t('Instructions','निर्देश')}</div>
                    {instr.map((ins,i)=><div key={i} style={{fontSize:11,color:C.sub,marginBottom:3}}>• {ins}</div>)}
                  </div>
                </div>
                <div style={{padding:'13px 22px',borderTop:`1px solid ${C.border}`,display:'flex',gap:9,flexWrap:'wrap'}}>
                  <button onClick={download} className="btn-p">📥 {t('Download PDF','PDF डाउनलोड')}</button>
                  <a href={`/exam/${sel._id}`} className="btn-g" style={{textDecoration:'none'}}>🚀 {t('Start Exam','परीक्षा शुरू')}</a>
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
