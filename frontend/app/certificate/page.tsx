'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D' }

export default function CertificatePage() {
  return (
    <StudentShell pageKey="certificate">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [certs, setCerts] = useState<any[]>([])
        const [selCert, setSelCert] = useState<any>(null)
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/certificates`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{
            const list = Array.isArray(d)?d:[]
            setCerts(list)
            if(list.length>0) setSelCert(list[0])
            setLoading(false)
          }).catch(()=>{
            // Demo certs if API not available
            const demo = [{_id:'c1',title:lang==='en'?'NEET Mock Excellence':'NEET मॉक उत्कृष्टता',subtitle:lang==='en'?'Top 5% Performer':'शीर्ष 5% प्रदर्शनकर्ता',date:'Feb 14, 2026',score:632,rank:189},{_id:'c2',title:lang==='en'?'100-Day Streak':'100 दिन की स्ट्रीक',subtitle:lang==='en'?'Consistent Learner Award':'निरंतर शिक्षार्थी पुरस्कार',date:'Mar 1, 2026'},{_id:'c3',title:lang==='en'?'Biology Master':'जीव विज्ञान मास्टर',subtitle:lang==='en'?'95%+ in Biology — 3 Tests':'जीव विज्ञान में 95%+ — 3 टेस्ट',date:'Feb 20, 2026'}]
            setCerts(demo); setSelCert(demo[0]); setLoading(false)
          })
        },[token])

        const downloadCert = async (cert:any) => {
          try {
            const res = await fetch(`${API}/api/certificates/${cert._id}/download`,{headers:{Authorization:`Bearer ${token}`}})
            if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${cert.title||'certificate'}.pdf`;a.click();toast(lang==='en'?'Certificate downloaded!':'प्रमाणपत्र डाउनलोड हुआ!','s')}
            else toast(lang==='en'?'Download not available yet':'डाउनलोड अभी उपलब्ध नहीं','w')
          } catch{toast('Network error','e')}
        }

        const shareCert = (cert:any) => {
          const text = `🏆 I earned the "${cert.title}" certificate on ProveRank!\n${cert.score?`Score: ${cert.score}/720`:''}\nprove-rank.vercel.app`
          if(navigator.share) navigator.share({title:'My ProveRank Certificate',text}).catch(()=>{})
          else{navigator.clipboard?.writeText(text);toast('Copied to clipboard!','s')}
        }

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.gold},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'My Certificates':'मेरे प्रमाणपत्र'}</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Your achievements & certificates — earned with excellence':'आपकी उपलब्धियां और प्रमाणपत्र — उत्कृष्टता से अर्जित'}</div>
            </div>

            {/* Quote Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(255,215,0,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(255,215,0,0.25)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:10,top:'50%',transform:'translateY(-50%)',opacity:.1}}>
                <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
                  <path d="M60 5 L72 38 L108 38 L80 58 L92 90 L60 70 L28 90 L40 58 L12 38 L48 38 Z" stroke="#FFD700" strokeWidth="2" fill="none"/>
                  <circle cx="20" cy="15" r="5" fill="#FFD700" opacity=".5"/>
                  <circle cx="100" cy="20" r="4" fill="#4D9FFF" opacity=".5"/>
                  <circle cx="105" cy="80" r="6" fill="#00C48C" opacity=".4"/>
                </svg>
              </div>
              <span style={{fontSize:36}}>🏆</span>
              <div style={{flex:1}}>
                <div style={{fontSize:15,color:C.gold,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{lang==='en'?'"Achievement is a journey, not a destination — keep collecting your stars."':'"उपलब्धि एक यात्रा है, मंजिल नहीं — अपने सितारे इकट्ठा करते रहो।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{lang==='en'?'"उपलब्धि एक यात्रा है — अपने सितारे इकट्ठा करते रहो।"':'Achievement is a journey — keep collecting your stars.'}</div>
              </div>
            </div>

            {/* Certificate Thumbnails */}
            {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:certs.length===0?(
              <div style={{textAlign:'center',padding:'60px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:20,border:`1px solid ${C.border}`}}>
                <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{display:'block',margin:'0 auto 16px'}}>
                  <rect x="10" y="20" width="60" height="45" rx="4" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
                  <path d="M10 32h60" stroke="#FFD700" strokeWidth="1"/>
                  <circle cx="40" cy="52" r="8" stroke="#FFD700" strokeWidth="1.5" fill="none"/>
                  <path d="M36 52 L39 55 L44 49" stroke="#FFD700" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M35 20 L40 10 L45 20" stroke="#FFD700" strokeWidth="1.5" strokeLinecap="round"/>
                </svg>
                <div style={{fontSize:16,fontWeight:700,color:dm?C.text:'#0F172A',marginBottom:8}}>{lang==='en'?'No certificates yet':'अभी कोई प्रमाणपत्र नहीं'}</div>
                <div style={{fontSize:12,color:C.sub,marginBottom:16}}>{lang==='en'?'Complete exams and achieve milestones to earn certificates!':'प्रमाणपत्र अर्जित करने के लिए परीक्षाएं पूरी करें!'}</div>
                <a href="/my-exams" style={{padding:'10px 20px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:13,display:'inline-block'}}>{lang==='en'?'Give First Exam →':'पहली परीक्षा दें →'}</a>
              </div>
            ):(
              <>
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(200px,1fr))',gap:12,marginBottom:24}}>
                  {certs.map((cert:any)=>(
                    <div key={cert._id} onClick={()=>setSelCert(cert)} className="card-h" style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`2px solid ${selCert?._id===cert._id?C.gold:C.border}`,borderRadius:14,padding:16,cursor:'pointer',transition:'all .2s',backdropFilter:'blur(12px)'}}>
                      <div style={{fontSize:28,marginBottom:8}}>🏆</div>
                      <div style={{fontWeight:700,fontSize:13,color:dm?C.text:'#0F172A',marginBottom:3}}>{cert.title}</div>
                      <div style={{fontSize:11,color:C.gold,marginBottom:6}}>{cert.subtitle}</div>
                      <div style={{fontSize:10,color:C.sub}}>{cert.date}</div>
                    </div>
                  ))}
                </div>

                {/* Certificate Preview */}
                {selCert&&(
                  <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid rgba(255,215,0,0.3)`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(12px)',marginBottom:24}}>
                    {/* Certificate Design */}
                    <div style={{background:'linear-gradient(135deg,#000A18,#001628,#000510)',padding:'40px 30px',textAlign:'center',position:'relative',overflow:'hidden',borderBottom:`1px solid rgba(255,215,0,0.2)`}}>
                      {/* Corner decorations */}
                      {[[0,0],[0,'auto'],['auto',0],['auto','auto']].map(([t2,r2],i)=>(
                        <div key={i} style={{position:'absolute',top:String(t2),bottom:i>1?'0':undefined,left:i%2===0?'0':undefined,right:i%2===1?'0':undefined,width:40,height:40,border:`2px solid rgba(255,215,0,0.4)`,borderRadius:4}}/>
                      ))}
                      <div style={{position:'absolute',inset:0,background:'radial-gradient(ellipse at center,rgba(255,215,0,0.05),transparent 70%)'}}/>

                      <div style={{position:'relative',zIndex:1}}>
                        <div style={{display:'flex',alignItems:'center',justifyContent:'center',gap:10,marginBottom:16}}>
                          <svg width="36" height="36" viewBox="0 0 64 64"><defs><filter id="gl2"><feGaussianBlur stdDeviation="2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs><polygon points="56.3,32 49.5,25.5 51.5,16.5 42.8,14 39.2,5.8 32,10 24.8,5.8 21.2,14 12.5,16.5 14.5,25.5 7.7,32 14.5,38.5 12.5,47.5 21.2,50 24.8,58.2 32,54 39.2,58.2 42.8,50 51.5,47.5 49.5,38.5" fill="none" stroke="#FFD700" strokeWidth="1.5" filter="url(#gl2)"/><text x="32" y="36" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#FFD700">PR</text></svg>
                          <span style={{fontSize:11,letterSpacing:3,color:'rgba(255,215,0,0.7)',textTransform:'uppercase',fontFamily:'Inter,sans-serif'}}>CERTIFICATE OF ACHIEVEMENT</span>
                        </div>
                        <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:700,color:C.gold,marginBottom:10}}>{selCert.title}</div>
                        <div style={{fontSize:12,color:'rgba(232,244,255,0.6)',marginBottom:16}}>{lang==='en'?'This certifies that':'यह प्रमाणित करता है कि'}</div>
                        <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontStyle:'italic',color:'#fff',marginBottom:10}}>{user?.name||'Student'}</div>
                        <div style={{fontSize:13,color:'rgba(232,244,255,0.7)',marginBottom:20}}>{lang==='en'?`has earned the award for "${selCert.subtitle}" on ProveRank Platform.`:`ने ProveRank Platform पर "${selCert.subtitle}" पुरस्कार अर्जित किया है।`}</div>
                        {selCert.score&&(
                          <div style={{display:'inline-flex',gap:20,background:'rgba(255,215,0,0.1)',border:'1px solid rgba(255,215,0,0.3)',borderRadius:10,padding:'10px 24px',marginBottom:20}}>
                            <div style={{textAlign:'center'}}>
                              <div style={{fontWeight:800,fontSize:20,color:C.gold}}>{selCert.score}</div>
                              <div style={{fontSize:9,color:C.sub}}>SCORE</div>
                            </div>
                            {selCert.rank&&<div style={{textAlign:'center'}}>
                              <div style={{fontWeight:800,fontSize:20,color:C.primary}}>#{selCert.rank}</div>
                              <div style={{fontSize:9,color:C.sub}}>AIR</div>
                            </div>}
                          </div>
                        )}
                        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',fontSize:10,color:'rgba(107,143,175,0.6)',borderTop:'1px solid rgba(255,215,0,0.1)',paddingTop:16}}>
                          <span>ProveRank · {user?.email||'proverank.com'}</span>
                          <span>{selCert.date}</span>
                        </div>
                      </div>
                    </div>
                    {/* Actions */}
                    <div style={{padding:'16px 24px',display:'flex',gap:10,flexWrap:'wrap'}}>
                      <button onClick={()=>downloadCert(selCert)} className="btn-p">📥 {lang==='en'?'Download PDF':'PDF डाउनलोड'}</button>
                      <button onClick={()=>shareCert(selCert)} className="btn-g">📤 {lang==='en'?'Share':'शेयर करें'}</button>
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
