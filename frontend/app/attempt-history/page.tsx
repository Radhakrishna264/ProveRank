'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function AttemptHistoryPage() {
  return (
    <StudentShell pageKey="attempt-history">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [results, setResults] = useState<any[]>([])
        const [loading, setLoading] = useState(true)
        const [filter, setFilter] = useState('all')

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
        },[token])

        const filtered = results.filter(r=>{
          if(filter==='all') return true
          return r.examTitle?.toLowerCase().includes(filter.toLowerCase())||r.exam?.title?.toLowerCase().includes(filter.toLowerCase())
        })

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Attempt History':'परीक्षा इतिहास'} (S82)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Complete journey — every exam recorded, filtered by subject/date':'पूरी यात्रा — हर परीक्षा दर्ज, विषय/तारीख से फ़िल्टर'}</div>
            </div>

            {/* SVG Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(167,139,250,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(167,139,250,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,opacity:.08}}>
                <svg width="120" height="90" viewBox="0 0 120 90" fill="none">
                  <path d="M10 80 L30 60 L45 70 L60 45 L75 55 L90 30 L110 40" stroke="#A78BFA" strokeWidth="2" strokeLinecap="round"/>
                  {[30,60,45,75,90,110].map((x,i)=><circle key={i} cx={x} cy={[60,45,70,55,30,40][i]} r="4" fill="#A78BFA" opacity=".7"/>)}
                  <path d="M10 85h100" stroke="#A78BFA" strokeWidth=".5" opacity=".3"/>
                </svg>
              </div>
              <span style={{fontSize:30}}>🕐</span>
              <div style={{flex:1}}>
                <div style={{fontSize:14,color:'#A78BFA',fontStyle:'italic',fontWeight:700,marginBottom:3}}>{lang==='en'?'"Every attempt is a lesson — your history is your greatest teacher."':'"हर प्रयास एक सबक है — आपका इतिहास आपका सबसे बड़ा शिक्षक है।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{lang==='en'?`${results.length} total attempts recorded`:`${results.length} कुल प्रयास दर्ज`}</div>
              </div>
            </div>

            {/* Stats Summary */}
            <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:20}}>
              {[[results.length,lang==='en'?'Total Attempts':'कुल प्रयास',C.primary,'📝'],[results.length>0?Math.max(...results.map((r:any)=>r.score||0)):'—',lang==='en'?'Best Score':'सर्वश्रेष्ठ',C.gold,'🏆'],[results.length>0?Math.min(...results.map((r:any)=>r.rank||99999))+'':'—',lang==='en'?'Best Rank':'सर्वश्रेष्ठ रैंक',C.success,'🥇'],[results.length>0?Math.round(results.reduce((a:number,r:any)=>a+(r.score||0),0)/results.length)+'':'—',lang==='en'?'Avg Score':'औसत स्कोर',C.warn,'📊']].map(([v,l,c,ic])=>(
                <div key={String(l)} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:14,padding:'14px 18px',flex:1,minWidth:110,backdropFilter:'blur(12px)',textAlign:'center'}}>
                  <div style={{fontSize:20,marginBottom:6}}>{ic}</div>
                  <div style={{fontWeight:800,fontSize:20,color:String(c),fontFamily:'Playfair Display,serif'}}>{v}</div>
                  <div style={{fontSize:10,color:C.sub,marginTop:2}}>{l}</div>
                </div>
              ))}
            </div>

            {/* Timeline */}
            {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>:results.length===0?(
              <div style={{textAlign:'center',padding:'60px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:20,border:`1px solid ${C.border}`}}>
                <svg width="70" height="70" viewBox="0 0 70 70" fill="none" style={{display:'block',margin:'0 auto 14px'}}>
                  <circle cx="35" cy="35" r="28" stroke="#4D9FFF" strokeWidth="1.5" strokeDasharray="4 3"/>
                  <path d="M35 20v18l12 8" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/>
                </svg>
                <div style={{fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:6}}>{lang==='en'?'No attempts yet':'अभी कोई प्रयास नहीं'}</div>
                <a href="/my-exams" style={{padding:'10px 20px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:13,display:'inline-block'}}>{lang==='en'?'Give First Exam →':'पहली परीक्षा दें →'}</a>
              </div>
            ):(
              <div style={{position:'relative',paddingLeft:24}}>
                <div style={{position:'absolute',left:8,top:0,bottom:0,width:2,background:`linear-gradient(180deg,${C.primary},rgba(77,159,255,0.1))`}}/>
                {results.map((r:any,i:number)=>(
                  <div key={r._id||i} style={{position:'relative',marginBottom:16}}>
                    <div style={{position:'absolute',left:-20,top:16,width:14,height:14,borderRadius:'50%',background:i===0?C.primary:C.card,border:`2px solid ${C.primary}`,zIndex:1}}/>
                    <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${i===0?'rgba(77,159,255,0.4)':C.border}`,borderRadius:14,padding:'14px 18px',backdropFilter:'blur(12px)',marginLeft:8}}>
                      <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8,alignItems:'center'}}>
                        <div style={{flex:1,minWidth:180}}>
                          <div style={{fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A',marginBottom:3}}>{r.examTitle||r.exam?.title||'—'}</div>
                          <div style={{fontSize:11,color:C.sub}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{weekday:'short',day:'numeric',month:'short',year:'numeric'}):''}</div>
                        </div>
                        <div style={{display:'flex',gap:14,alignItems:'center'}}>
                          <div style={{textAlign:'center'}}>
                            <div style={{fontWeight:800,fontSize:18,color:C.primary}}>{r.score}</div>
                            <div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div>
                          </div>
                          <div style={{textAlign:'center'}}>
                            <div style={{fontWeight:700,fontSize:14,color:C.gold}}>#{r.rank||'—'}</div>
                            <div style={{fontSize:9,color:C.sub}}>AIR</div>
                          </div>
                          <div style={{textAlign:'center'}}>
                            <div style={{fontWeight:700,fontSize:14,color:C.success}}>{r.percentile||'—'}%</div>
                            <div style={{fontSize:9,color:C.sub}}>ile</div>
                          </div>
                          <a href="/results" style={{padding:'6px 12px',background:'rgba(77,159,255,0.12)',color:C.primary,border:`1px solid rgba(77,159,255,0.3)`,borderRadius:8,textDecoration:'none',fontSize:11,fontWeight:600}}>{lang==='en'?'View':'देखें'}</a>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
