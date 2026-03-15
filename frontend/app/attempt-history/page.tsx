'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function AttemptHistoryContent() {
  const { lang, darkMode:dm, token } = useShell()
  const [results, setResults] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}})
      .then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const best  = results.length ? Math.max(...results.map((r:any)=>r.score||0)) : null
  const bRank = results.length ? Math.min(...results.map((r:any)=>r.rank||99999)) : null
  const avg   = results.length ? Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length) : null

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🕐 {t('Attempt History','परीक्षा इतिहास')} (S82)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Your complete exam journey — every attempt recorded','आपकी पूरी परीक्षा यात्रा — हर प्रयास दर्ज')}</div>

      <div style={{background:'linear-gradient(135deg,rgba(167,139,250,.1),rgba(0,22,40,.85))',border:'1px solid rgba(167,139,250,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <span style={{fontSize:26}}>🕐</span>
        <div style={{fontSize:13,color:C.purple||'#A78BFA',fontStyle:'italic',fontWeight:700}}>{t('"Every attempt is a lesson — your history is your greatest teacher."','"हर प्रयास एक सबक है — आपका इतिहास आपका सबसे बड़ा शिक्षक है।"')}</div>
      </div>

      <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:22}}>
        {[[results.length,t('Total Attempts','कुल प्रयास'),C.primary,'📝'],[best?`${best}/720`:'—',t('Best Score','सर्वश्रेष्ठ'),C.gold,'🏆'],[bRank&&bRank<99999?`#${bRank}`:'—',t('Best Rank','सर्वश्रेष्ठ रैंक'),C.success,'🥇'],[avg?`${avg}/720`:'—',t('Avg Score','औसत'),C.warn,'📊']].map(([v,l,c,ic])=>(
          <div key={String(l)} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:13,padding:'13px 16px',flex:1,minWidth:110,backdropFilter:'blur(12px)',textAlign:'center'}}>
            <div style={{fontSize:20,marginBottom:5}}>{ic}</div>
            <div style={{fontWeight:800,fontSize:20,color:String(c),fontFamily:'Playfair Display,serif'}}>{v}</div>
            <div style={{fontSize:10,color:C.sub,marginTop:2}}>{l}</div>
          </div>
        ))}
      </div>

      {loading ? <div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div> :
        results.length===0 ? (
          <div style={{textAlign:'center',padding:'50px 20px',background:dm?C.card:C.cardL,borderRadius:18,border:`1px solid ${C.border}`}}>
            <div style={{fontSize:40,marginBottom:12}}>🕐</div>
            <div style={{fontWeight:700,fontSize:15,color:dm?C.text:C.textL,marginBottom:8}}>{t('No attempts yet','अभी कोई प्रयास नहीं')}</div>
            <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('Give First Exam →','पहली परीक्षा दें →')}</a>
          </div>
        ) : (
          <div style={{position:'relative',paddingLeft:22}}>
            <div style={{position:'absolute',left:7,top:0,bottom:0,width:2,background:`linear-gradient(180deg,${C.primary},rgba(77,159,255,.1))`}}/>
            {results.map((r:any,i:number)=>(
              <div key={r._id||i} style={{position:'relative',marginBottom:14}}>
                <div style={{position:'absolute',left:-19,top:14,width:13,height:13,borderRadius:'50%',background:i===0?C.primary:C.card,border:`2px solid ${C.primary}`,zIndex:1}}/>
                <div style={{background:dm?C.card:C.cardL,border:`1px solid ${i===0?'rgba(77,159,255,.4)':C.border}`,borderRadius:13,padding:'13px 16px',backdropFilter:'blur(12px)',marginLeft:6}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8,alignItems:'center'}}>
                    <div style={{flex:1,minWidth:160}}>
                      <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:2}}>{r.examTitle||r.exam?.title||'—'}</div>
                      <div style={{fontSize:10,color:C.sub}}>{r.submittedAt?new Date(r.submittedAt).toLocaleDateString('en-IN',{weekday:'short',day:'numeric',month:'short',year:'numeric'}):''}</div>
                    </div>
                    <div style={{display:'flex',gap:12,alignItems:'center',flexWrap:'wrap'}}>
                      <div style={{textAlign:'center'}}><div style={{fontWeight:800,fontSize:17,color:C.primary}}>{r.score}</div><div style={{fontSize:9,color:C.sub}}>/{r.totalMarks||720}</div></div>
                      <div style={{textAlign:'center'}}><div style={{fontWeight:700,fontSize:14,color:C.gold}}>#{r.rank||'—'}</div><div style={{fontSize:9,color:C.sub}}>AIR</div></div>
                      <div style={{textAlign:'center'}}><div style={{fontWeight:700,fontSize:13,color:C.success}}>{r.percentile||'—'}%</div><div style={{fontSize:9,color:C.sub}}>ile</div></div>
                      <a href="/results" style={{padding:'5px 11px',background:'rgba(77,159,255,.12)',color:C.primary,border:`1px solid rgba(77,159,255,.3)`,borderRadius:7,textDecoration:'none',fontSize:10,fontWeight:600}}>{t('View','देखें')}</a>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )
      }
    </div>
  )
}
export default function AttemptHistoryPage() {
  return <StudentShell pageKey="attempt-history"><AttemptHistoryContent/></StudentShell>
}
