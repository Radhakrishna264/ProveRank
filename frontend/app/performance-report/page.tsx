'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function PerfReportContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const [results,   setResults]   = useState<any[]>([])
  const [generating,setGenerating]= useState(false)
  const [loading,   setLoading]   = useState(true)
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])

  const best = results.length ? Math.max(...results.map((r:any)=>r.score||0)) : 0
  const avg  = results.length ? Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length) : 0
  const bRnk = results.length ? Math.min(...results.map((r:any)=>r.rank||99999)) : null

  const dlPDF = async () => {
    if(!token||!results.length) return; setGenerating(true)
    try {
      const r=await fetch(`${API}/api/results/report/pdf`,{headers:{Authorization:`Bearer ${token}`}})
      if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${user?.name||'Student'}_Performance_Report.pdf`;a.click();toast(t('Report downloaded!','रिपोर्ट डाउनलोड हुई!'),'s')}
      else toast(t('Report generation not available yet','रिपोर्ट अभी उपलब्ध नहीं'),'w')
    } catch { toast('Network error','e') }
    setGenerating(false)
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📄 {t('Performance Report','प्रदर्शन रिपोर्ट')} (S14)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Download your complete performance PDF — all exams summary','पूरी प्रदर्शन रिपोर्ट PDF डाउनलोड करें')}</div>

      {/* Preview card */}
      <div style={{background:'linear-gradient(135deg,rgba(0,22,40,.95),rgba(0,31,58,.9))',border:'2px solid rgba(77,159,255,.3)',borderRadius:20,overflow:'hidden',marginBottom:22,boxShadow:'0 8px 32px rgba(0,0,0,.4)'}}>
        <div style={{background:'linear-gradient(135deg,#001F3F,#003366)',padding:'18px 22px',display:'flex',alignItems:'center',gap:11,borderBottom:'1px solid rgba(77,159,255,.2)'}}>
          <div style={{width:40,height:40,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,fontWeight:900,color:'#fff',flexShrink:0}}>{(user?.name||'S').charAt(0)}</div>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#fff'}}>{user?.name||'Student'}</div>
            <div style={{fontSize:10,color:'rgba(77,159,255,.7)'}}>{t('NEET 2026 Performance Report','NEET 2026 प्रदर्शन रिपोर्ट')}</div>
          </div>
          <div style={{marginLeft:'auto',fontSize:10,color:'rgba(77,159,255,.5)'}}>ProveRank · {new Date().toLocaleDateString('en-IN',{month:'long',year:'numeric'})}</div>
        </div>
        <div style={{padding:'18px 22px'}}>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(110px,1fr))',gap:10,marginBottom:16}}>
            {[[results.length,t('Tests','टेस्ट'),C.primary,'📝'],[best?`${best}/720`:'—',t('Best','सर्वश्रेष्ठ'),C.gold,'🏆'],[avg?`${avg}/720`:'—',t('Avg','औसत'),C.success,'📊'],[bRnk&&bRnk<99999?`#${bRnk}`:'—',t('Best Rank','सर्वश्रेष्ठ रैंक'),C.warn,'🥇']].map(([v,l,c,ic])=>(
              <div key={String(l)} style={{textAlign:'center',padding:'12px',background:'rgba(77,159,255,.06)',border:'1px solid rgba(77,159,255,.12)',borderRadius:11}}>
                <div style={{fontSize:18,marginBottom:4}}>{ic}</div>
                <div style={{fontWeight:800,fontSize:17,color:String(c),fontFamily:'Playfair Display,serif'}}>{v}</div>
                <div style={{fontSize:9,color:C.sub,marginTop:2}}>{l}</div>
              </div>
            ))}
          </div>
          {[{n:t('Physics','भौतिकी'),v:82,c:'#00B4FF'},{n:t('Chemistry','रसायन'),v:84,c:'#FF6B9D'},{n:t('Biology','जीव विज्ञान'),v:87,c:'#00E5A0'}].map(s=>(
            <div key={s.n} style={{marginBottom:8}}>
              <div style={{display:'flex',justifyContent:'space-between',fontSize:11,marginBottom:3}}><span style={{color:s.c,fontWeight:600}}>{s.n}</span><span style={{color:C.sub,fontWeight:700}}>{s.v}%</span></div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:4,height:7,overflow:'hidden'}}><div style={{height:'100%',width:`${s.v}%`,background:s.c,borderRadius:4}}/></div>
            </div>
          ))}
          {results.slice(0,4).map((r:any,i:number)=>(
            <div key={r._id||i} style={{display:'flex',justifyContent:'space-between',padding:'6px 0',borderBottom:'1px solid rgba(77,159,255,.07)',fontSize:10}}>
              <span style={{color:C.sub,flex:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',marginRight:8}}>{r.examTitle||'—'}</span>
              <span style={{color:C.primary,fontWeight:700,marginRight:8}}>{r.score}/{r.totalMarks||720}</span>
              <span style={{color:C.gold}}>#{r.rank||'—'}</span>
            </div>
          ))}
        </div>
      </div>

      <button onClick={dlPDF} disabled={generating||!results.length} className="btn-p" style={{width:'100%',fontSize:14,padding:'14px',opacity:(generating||!results.length)?.6:1}}>
        {generating?'⟳ Generating PDF...':t('📄 Download Complete Performance Report PDF','📄 पूरी प्रदर्शन रिपोर्ट PDF डाउनलोड करें')}
      </button>
      {!results.length&&<div style={{textAlign:'center',fontSize:12,color:C.sub,marginTop:9}}>{t('Give at least one exam to generate report','रिपोर्ट के लिए कम से कम एक परीक्षा दें')}</div>}
    </div>
  )
}
export default function PerformanceReportPage() {
  return <StudentShell pageKey="results"><PerfReportContent/></StudentShell>
}
