'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function TrophySVG() {
  return (
    <svg width="70" height="80" viewBox="0 0 70 80" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
      <path d="M22 5 H48 V35 Q48 55 35 60 Q22 55 22 35 Z" stroke="#FFD700" strokeWidth="1.5" fill="rgba(255,215,0,0.15)"/>
      <path d="M5 10 H22 V30 Q8 28 5 10 Z" stroke="#FFD700" strokeWidth="1" fill="rgba(255,215,0,0.1)"/>
      <path d="M48 10 H65 V10 Q62 28 48 30 Z" stroke="#FFD700" strokeWidth="1" fill="rgba(255,215,0,0.1)"/>
      <line x1="35" y1="60" x2="35" y2="68" stroke="#FFD700" strokeWidth="2"/>
      <rect x="20" y="68" width="30" height="7" rx="2" stroke="#FFD700" strokeWidth="1.5" fill="rgba(255,215,0,0.2)"/>
      <circle cx="35" cy="32" r="6" fill="rgba(255,215,0,0.3)" stroke="#FFD700" strokeWidth="1"/>
      <path d="M35 28 L36.5 31.5H40L37.2 33.5L38.2 37L35 35L31.8 37L32.8 33.5L30 31.5H33.5Z" fill="#FFD700"/>
    </svg>
  )
}

function CertificateContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [certs,  setCerts]  = useState<any[]>([])
  const [selIdx, setSelIdx] = useState(0)
  const [loading,setLoading]= useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/certificates`,{headers:{Authorization:`Bearer ${token}`}})
      .then(r=>r.ok?r.json():[])
      .then(d=>{setCerts(Array.isArray(d)?d:[]);setLoading(false)})
      .catch(()=>{setCerts([]);setLoading(false)})
  },[token])

  const sel=certs[selIdx]

  const download=async()=>{
    if(!sel) return
    try{
      const r=await fetch(`${API}/api/certificates/${sel._id}/download`,{headers:{Authorization:`Bearer ${token}`}})
      if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${sel.title||'certificate'}.pdf`;a.click();toast(t('Downloaded!','डाउनलोड हुआ!'),'s')}
      else toast(t('Download not available yet','डाउनलोड अभी उपलब्ध नहीं'),'w')
    }catch{toast('Network error','e')}
  }

  const share=()=>{
    if(!sel) return
    const txt=`🏆 I earned "${sel.title}" on ProveRank!${sel.score?`\nScore: ${sel.score}/720`:''}\nprove-rank.vercel.app`
    if(navigator.share) navigator.share({title:'My Certificate',text:txt}).catch(()=>{})
    else{navigator.clipboard?.writeText(txt);toast(t('Copied!','कॉपी हुआ!'),'s')}
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🎖️ {t('My Certificates','मेरे प्रमाणपत्र')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Your achievements & certificates — earned with excellence','आपकी उपलब्धियां — उत्कृष्टता से अर्जित')}</div>

      {/* Banner */}
      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.1),rgba(0,22,40,.9))',border:'1px solid rgba(255,215,0,.22)',borderRadius:20,padding:20,marginBottom:22,display:'flex',alignItems:'center',gap:16,flexWrap:'wrap'}}>
        <TrophySVG/>
        <div style={{flex:1}}>
          <div style={{fontSize:14,color:C.gold,fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t('"Achievement is a journey — keep collecting your stars."','"उपलब्धि एक यात्रा है — अपने सितारे इकट्ठा करते रहो।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{certs.length>0?`${certs.length} ${t('certificates earned','प्रमाणपत्र अर्जित')}`:t('Complete exams & milestones to earn certificates!','प्रमाणपत्र अर्जित करने के लिए परीक्षाएं और मील-पत्थर पूरे करें!')}</div>
        </div>
      </div>

      {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳ Loading...</div>:
        certs.length===0?(
          /* Empty state — NO fake certificates */
          <div style={{textAlign:'center',padding:'70px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`,backdropFilter:'blur(14px)'}}>
            <svg width="90" height="90" viewBox="0 0 90 90" style={{display:'block',margin:'0 auto 16px'}} fill="none">
              <rect x="10" y="20" width="70" height="55" rx="5" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
              <path d="M10 36h70" stroke="#FFD700" strokeWidth="1"/>
              <circle cx="45" cy="58" r="12" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
              <path d="M38 58L43 63L52 53" stroke="#FFD700" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M38 20L45 10L52 20" stroke="#FFD700" strokeWidth="1.5" strokeLinecap="round"/>
              <circle cx="20" cy="30" r="3" fill="#FFD700" opacity=".6"/>
              <circle cx="70" cy="30" r="3" fill="#FFD700" opacity=".6"/>
            </svg>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:dm?C.text:C.textL,marginBottom:8}}>{t('No certificates yet!','अभी कोई प्रमाणपत्र नहीं!')}</div>
            <div style={{fontSize:13,color:C.sub,maxWidth:360,margin:'0 auto 8px',lineHeight:1.6}}>{t('You earn certificates by:','प्रमाणपत्र अर्जित करने के तरीके:')}</div>
            <div style={{display:'flex',flexDirection:'column',gap:6,maxWidth:300,margin:'0 auto 20px',textAlign:'left'}}>
              {(lang==='en'?['📝 Completing full mock exams','🔥 Achieving day streaks (7, 30, 100 days)','🏆 Scoring in top 5% or 10%','✅ Completing subject-specific challenges']:['📝 पूर्ण मॉक परीक्षाएं पूरी करना','🔥 डे स्ट्रीक प्राप्त करना (7, 30, 100 दिन)','🏆 शीर्ष 5% या 10% में स्कोर करना','✅ विषय-विशिष्ट चुनौतियां पूरी करना']).map((item,i)=>(
                <div key={i} style={{fontSize:12,color:C.sub,padding:'6px 10px',background:'rgba(255,215,0,.07)',border:'1px solid rgba(255,215,0,.15)',borderRadius:8}}>{item}</div>
              ))}
            </div>
            <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('📝 Give First Exam →','📝 पहली परीक्षा दें →')}</a>
          </div>
        ):(
          <>
            {/* Certificate thumbnails */}
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(180px,1fr))',gap:12,marginBottom:22}}>
              {certs.map((c:any,i:number)=>(
                <div key={c._id} onClick={()=>setSelIdx(i)} className="card-h" style={{background:dm?C.card:C.cardL,border:`2px solid ${i===selIdx?C.gold:C.border}`,borderRadius:14,padding:16,cursor:'pointer',transition:'all .25s',backdropFilter:'blur(14px)'}}>
                  <div style={{fontSize:30,marginBottom:8}}>🏆</div>
                  <div style={{fontWeight:700,fontSize:12,color:dm?C.text:C.textL,marginBottom:3}}>{c.title}</div>
                  <div style={{fontSize:10,color:C.gold,marginBottom:5}}>{c.subtitle}</div>
                  <div style={{fontSize:9,color:C.sub}}>{c.date}</div>
                </div>
              ))}
            </div>

            {/* Certificate preview */}
            {sel&&(
              <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(255,215,0,.3)',borderRadius:20,overflow:'hidden',backdropFilter:'blur(14px)'}}>
                <div style={{background:'linear-gradient(135deg,#000A18,#001628)',padding:'40px 28px',textAlign:'center',position:'relative',overflow:'hidden',borderBottom:'1px solid rgba(255,215,0,.15)'}}>
                  {[[0,0],[0,'auto'],['auto',0],['auto','auto']].map((_,i)=>(
                    <div key={i} style={{position:'absolute',[i<2?'top':'bottom']:0,[i%2===0?'left':'right']:0,width:40,height:40,border:'2px solid rgba(255,215,0,.4)',borderRadius:3}}/>
                  ))}
                  <div style={{position:'absolute',inset:0,background:'radial-gradient(ellipse at center,rgba(255,215,0,.06),transparent 65%)'}}/>
                  <div style={{position:'relative',zIndex:1}}>
                    <div style={{fontSize:9,letterSpacing:4,color:'rgba(255,215,0,.7)',textTransform:'uppercase',marginBottom:14,fontFamily:'Inter,sans-serif'}}>CERTIFICATE OF ACHIEVEMENT</div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,color:C.gold,marginBottom:8,textShadow:`0 0 30px ${C.gold}44`}}>{sel.title}</div>
                    <div style={{fontSize:12,color:'rgba(232,244,255,.6)',marginBottom:10}}>{t('This certifies that','यह प्रमाणित करता है कि')}</div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontStyle:'italic',color:'#fff',marginBottom:8}}>{user?.name||t('Student','छात्र')}</div>
                    <div style={{fontSize:12,color:'rgba(232,244,255,.7)',marginBottom:16}}>{t(`has earned "${sel.subtitle}" on ProveRank Platform.`,`ने ProveRank पर "${sel.subtitle}" अर्जित किया।`)}</div>
                    {sel.score&&(
                      <div style={{display:'inline-flex',gap:20,background:'rgba(255,215,0,.1)',border:'1px solid rgba(255,215,0,.25)',borderRadius:10,padding:'10px 24px',marginBottom:16}}>
                        <div style={{textAlign:'center'}}><div style={{fontWeight:800,fontSize:20,color:C.gold}}>{sel.score}</div><div style={{fontSize:9,color:C.sub}}>SCORE</div></div>
                        {sel.rank&&<div style={{textAlign:'center'}}><div style={{fontWeight:800,fontSize:20,color:C.primary}}>#{sel.rank}</div><div style={{fontSize:9,color:C.sub}}>AIR</div></div>}
                      </div>
                    )}
                    <div style={{display:'flex',justifyContent:'space-between',fontSize:9,color:'rgba(107,143,175,.6)',borderTop:'1px solid rgba(255,215,0,.1)',paddingTop:12,marginTop:4}}>
                      <span>ProveRank · {user?.email}</span><span>{sel.date}</span>
                    </div>
                  </div>
                </div>
                <div style={{padding:'14px 22px',display:'flex',gap:10,flexWrap:'wrap'}}>
                  <button onClick={download} className="btn-p">📥 {t('Download PDF','PDF डाउनलोड')}</button>
                  <button onClick={share} className="btn-g">📤 {t('Share','शेयर करें')}</button>
                </div>
              </div>
            )}
          </>
        )
      }
    </div>
  )
}

export default function CertificatePage() {
  return <StudentShell pageKey="certificate"><CertificateContent/></StudentShell>
}
