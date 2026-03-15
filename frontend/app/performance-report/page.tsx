'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function PerformanceReportPage() {
  return (
    <StudentShell pageKey="results">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [results, setResults] = useState<any[]>([])
        const [generating, setGenerating] = useState(false)
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
        },[token])

        const generatePDF = async () => {
          if(!token) return
          setGenerating(true)
          try {
            const res = await fetch(`${API}/api/results/report/pdf`,{headers:{Authorization:`Bearer ${token}`}})
            if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${user?.name||'Student'}_Performance_Report.pdf`;a.click();toast(lang==='en'?'Report downloaded!':'रिपोर्ट डाउनलोड हुई!','s')}
            else toast(lang==='en'?'Report generation not available yet':'रिपोर्ट अभी उपलब्ध नहीं','w')
          } catch{toast('Network error','e')}
          setGenerating(false)
        }

        const bestScore = results.length>0?Math.max(...results.map((r:any)=>r.score||0)):0
        const avgScore = results.length>0?Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length):0
        const bestRank = results.length>0?Math.min(...results.map((r:any)=>r.rank||99999)):null

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Performance Report':'प्रदर्शन रिपोर्ट'} (S14)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Download your complete performance report PDF — all exams summary':'अपनी पूरी प्रदर्शन रिपोर्ट PDF डाउनलोड करें'}</div>
            </div>

            {/* Report Preview */}
            <div style={{background:'linear-gradient(135deg,rgba(0,22,40,0.95),rgba(0,31,58,0.9))',border:`2px solid rgba(77,159,255,0.3)`,borderRadius:20,overflow:'hidden',marginBottom:24,boxShadow:'0 8px 32px rgba(0,0,0,0.4)'}}>
              {/* Header */}
              <div style={{background:'linear-gradient(135deg,#001F3F,#003366)',padding:'20px 24px',display:'flex',alignItems:'center',gap:12,borderBottom:`1px solid rgba(77,159,255,0.2)`}}>
                <div style={{width:44,height:44,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:900,color:'#fff'}}>{(user?.name||'S').charAt(0)}</div>
                <div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#fff'}}>{user?.name||'Student'}</div>
                  <div style={{fontSize:11,color:'rgba(77,159,255,0.7)'}}>{lang==='en'?'NEET 2026 Performance Report':'NEET 2026 प्रदर्शन रिपोर्ट'}</div>
                </div>
                <div style={{marginLeft:'auto',fontSize:11,color:'rgba(77,159,255,0.5)'}}>ProveRank · {new Date().toLocaleDateString('en-IN',{month:'long',year:'numeric'})}</div>
              </div>

              {/* Summary Stats */}
              <div style={{padding:'20px 24px'}}>
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(120px,1fr))',gap:12,marginBottom:20}}>
                  {[[lang==='en'?'Tests Given':'दिए टेस्ट',results.length,C.primary,'📝'],[lang==='en'?'Best Score':'सर्वश्रेष्ठ',`${bestScore}/720`,C.gold,'🏆'],[lang==='en'?'Avg Score':'औसत',`${avgScore}/720`,C.success,'📊'],[lang==='en'?'Best Rank':'रैंक',bestRank&&bestRank<99999?`#${bestRank}`:'—',C.warn,'🥇']].map(([l,v,c,i])=>(
                    <div key={String(l)} style={{textAlign:'center',padding:'14px',background:'rgba(77,159,255,0.06)',border:`1px solid rgba(77,159,255,0.12)`,borderRadius:12}}>
                      <div style={{fontSize:20,marginBottom:6}}>{i}</div>
                      <div style={{fontWeight:800,fontSize:18,color:String(c),fontFamily:'Playfair Display,serif'}}>{v}</div>
                      <div style={{fontSize:10,color:C.sub,marginTop:2}}>{l}</div>
                    </div>
                  ))}
                </div>

                {/* Subject Bars */}
                <div style={{marginBottom:16}}>
                  <div style={{fontSize:12,fontWeight:700,color:C.sub,marginBottom:10,textTransform:'uppercase',letterSpacing:.5}}>{lang==='en'?'Subject Performance':'विषय प्रदर्शन'}</div>
                  {[{n:lang==='en'?'Physics':'भौतिकी',v:82,c:'#00B4FF'},{n:lang==='en'?'Chemistry':'रसायन',v:84,c:'#FF6B9D'},{n:lang==='en'?'Biology':'जीव विज्ञान',v:87,c:'#00E5A0'}].map(s=>(
                    <div key={s.n} style={{marginBottom:10}}>
                      <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}><span style={{color:s.c,fontWeight:600}}>{s.n}</span><span style={{color:C.sub,fontWeight:700}}>{s.v}%</span></div>
                      <div style={{background:'rgba(255,255,255,0.06)',borderRadius:4,height:8,overflow:'hidden'}}><div style={{height:'100%',width:`${s.v}%`,background:s.c,borderRadius:4}}/></div>
                    </div>
                  ))}
                </div>

                {/* Results List */}
                {results.slice(0,5).map((r:any,i:number)=>(
                  <div key={r._id||i} style={{display:'flex',justifyContent:'space-between',padding:'8px 0',borderBottom:`1px solid rgba(77,159,255,0.08)`,fontSize:11}}>
                    <span style={{color:C.sub,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',flex:1,marginRight:10}}>{r.examTitle||'—'}</span>
                    <span style={{color:C.primary,fontWeight:700,marginRight:10}}>{r.score}/{r.totalMarks||720}</span>
                    <span style={{color:C.gold}}>#{r.rank||'—'}</span>
                  </div>
                ))}
              </div>
            </div>

            <button onClick={generatePDF} disabled={generating||results.length===0} className="btn-p" style={{width:'100%',fontSize:15,padding:'14px',opacity:(generating||results.length===0)?.6:1}}>
              {generating?'⟳ Generating PDF...':lang==='en'?'📄 Download Complete Performance Report PDF':'📄 पूरी प्रदर्शन रिपोर्ट PDF डाउनलोड करें'}
            </button>
            {results.length===0&&<div style={{textAlign:'center',fontSize:12,color:C.sub,marginTop:10}}>{lang==='en'?'Give at least one exam to generate report':'रिपोर्ट के लिए कम से कम एक परीक्षा दें'}</div>}
          </div>
        )
      }}
    </StudentShell>
  )
}
