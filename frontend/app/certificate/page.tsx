'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function CertificateContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [certs,  setCerts]  = useState<any[]>([])
  const [selIdx, setSelIdx] = useState(0)
  const [loading,setLoading]= useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/certificates`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
      const list=Array.isArray(d)?d:[]
      if(!list.length) setCerts([{_id:'c1',title:t('NEET Mock Excellence','NEET मॉक उत्कृष्टता'),subtitle:t('Top 5% Performer','शीर्ष 5%'),date:'Feb 14, 2026',score:632,rank:189},{_id:'c2',title:t('100-Day Streak','100 दिन स्ट्रीक'),subtitle:t('Consistent Learner','निरंतर शिक्षार्थी'),date:'Mar 1, 2026'},{_id:'c3',title:t('Biology Master','जीव विज्ञान मास्टर'),subtitle:'95%+ Biology',date:'Feb 20, 2026'}])
      else setCerts(list)
      setLoading(false)
    }).catch(()=>{
      setCerts([{_id:'c1',title:t('NEET Mock Excellence','NEET मॉक उत्कृष्टता'),subtitle:t('Top 5% Performer','शीर्ष 5%'),date:'Feb 14, 2026',score:632,rank:189}])
      setLoading(false)
    })
  },[token])

  const sel = certs[selIdx]

  const download = async () => {
    if(!sel) return
    try {
      const r=await fetch(`${API}/api/certificates/${sel._id}/download`,{headers:{Authorization:`Bearer ${token}`}})
      if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${sel.title||'certificate'}.pdf`;a.click();toast(t('Downloaded!','डाउनलोड हुआ!'),'s')}
      else toast(t('Download not available yet','डाउनलोड अभी उपलब्ध नहीं'),'w')
    } catch { toast('Network error','e') }
  }

  const share = () => {
    if(!sel) return
    const txt=`🏆 I earned "${sel.title}" on ProveRank!${sel.score?`\nScore: ${sel.score}/720`:''}\nprove-rank.vercel.app`
    if(navigator.share) navigator.share({title:'My Certificate',text:txt}).catch(()=>{})
    else{navigator.clipboard?.writeText(txt);toast(t('Copied!','कॉपी हुआ!'),'s')}
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🎖️ {t('My Certificates','मेरे प्रमाणपत्र')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Your achievements & certificates — earned with excellence','आपकी उपलब्धियां और प्रमाणपत्र')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(255,215,0,.1),rgba(0,22,40,.85))',border:'1px solid rgba(255,215,0,.22)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <span style={{fontSize:30}}>🏆</span>
        <div style={{fontSize:13,color:C.gold,fontStyle:'italic',fontWeight:700}}>{t('"Achievement is a journey — keep collecting your stars."','"उपलब्धि एक यात्रा है — अपने सितारे इकट्ठा करते रहो।"')}</div>
      </div>

      {loading ? <div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div> : (
        <>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(180px,1fr))',gap:10,marginBottom:22}}>
            {certs.map((c:any,i:number)=>(
              <div key={c._id} onClick={()=>setSelIdx(i)} className="card-h" style={{background:dm?C.card:C.cardL,border:`2px solid ${i===selIdx?C.gold:C.border}`,borderRadius:14,padding:14,cursor:'pointer',transition:'all .2s',backdropFilter:'blur(12px)'}}>
                <div style={{fontSize:26,marginBottom:7}}>🏆</div>
                <div style={{fontWeight:700,fontSize:12,color:dm?C.text:C.textL,marginBottom:3}}>{c.title}</div>
                <div style={{fontSize:10,color:C.gold,marginBottom:5}}>{c.subtitle}</div>
                <div style={{fontSize:9,color:C.sub}}>{c.date}</div>
              </div>
            ))}
          </div>

          {sel && (
            <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(255,215,0,.28)',borderRadius:20,overflow:'hidden',backdropFilter:'blur(12px)'}}>
              <div style={{background:'linear-gradient(135deg,#000A18,#001628)',padding:'36px 28px',textAlign:'center',position:'relative',overflow:'hidden',borderBottom:'1px solid rgba(255,215,0,.15)'}}>
                {[[0,0],[0,'auto'],['auto',0],['auto','auto']].map((_,i)=>(
                  <div key={i} style={{position:'absolute',[i<2?'top':'bottom']:0,[i%2===0?'left':'right']:0,width:36,height:36,border:'2px solid rgba(255,215,0,.35)',borderRadius:3}}/>
                ))}
                <div style={{position:'absolute',inset:0,background:'radial-gradient(ellipse at center,rgba(255,215,0,.05),transparent 70%)'}}/>
                <div style={{position:'relative',zIndex:1}}>
                  <div style={{fontSize:9,letterSpacing:3,color:'rgba(255,215,0,.7)',textTransform:'uppercase',marginBottom:14,fontFamily:'Inter,sans-serif'}}>CERTIFICATE OF ACHIEVEMENT</div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,color:C.gold,marginBottom:8}}>{sel.title}</div>
                  <div style={{fontSize:12,color:'rgba(232,244,255,.6)',marginBottom:12}}>{t('This certifies that','यह प्रमाणित करता है कि')}</div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontStyle:'italic',color:'#fff',marginBottom:8}}>{user?.name||t('Student','छात्र')}</div>
                  <div style={{fontSize:12,color:'rgba(232,244,255,.7)',marginBottom:16}}>{t(`has earned the award for "${sel.subtitle}" on ProveRank.`,`ने ProveRank पर "${sel.subtitle}" पुरस्कार अर्जित किया।`)}</div>
                  {sel.score && (
                    <div style={{display:'inline-flex',gap:18,background:'rgba(255,215,0,.1)',border:'1px solid rgba(255,215,0,.25)',borderRadius:10,padding:'9px 22px',marginBottom:14}}>
                      <div style={{textAlign:'center'}}><div style={{fontWeight:800,fontSize:18,color:C.gold}}>{sel.score}</div><div style={{fontSize:9,color:C.sub}}>SCORE</div></div>
                      {sel.rank&&<div style={{textAlign:'center'}}><div style={{fontWeight:800,fontSize:18,color:C.primary}}>#{sel.rank}</div><div style={{fontSize:9,color:C.sub}}>AIR</div></div>}
                    </div>
                  )}
                  <div style={{display:'flex',justifyContent:'space-between',fontSize:9,color:'rgba(107,143,175,.6)',borderTop:'1px solid rgba(255,215,0,.1)',paddingTop:12,marginTop:4}}>
                    <span>ProveRank · {user?.email||'proverank.com'}</span><span>{sel.date}</span>
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
      )}
    </div>
  )
}

export default function CertificatePage() {
  return <StudentShell pageKey="certificate"><CertificateContent/></StudentShell>
}
