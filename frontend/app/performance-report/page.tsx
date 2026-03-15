'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
function PerfReportContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [results,setResults]=useState<any[]>([])
  const [generating,setGenerating]=useState(false)
  const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setResults(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])
  const best=results.length?Math.max(...results.map((r:any)=>r.score||0)):0
  const avg=results.length?Math.round(results.reduce((a,r:any)=>a+(r.score||0),0)/results.length):0
  const bRnk=results.length?Math.min(...results.map((r:any)=>r.rank||99999)):null
  const dlPDF=async()=>{
    if(!token||!results.length) return; setGenerating(true)
    try{const r=await fetch(`${API}/api/results/report/pdf`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${user?.name||'Student'}_Performance_Report.pdf`;a.click();toast(t('Report downloaded! (S14)','रिपोर्ट डाउनलोड हुई!'),'s')}else toast(t('Report not available yet — give more exams!','रिपोर्ट अभी उपलब्ध नहीं'),'w')}catch{toast('Network error','e')}
    setGenerating(false)
  }
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📄 {t('Performance Report','प्रदर्शन रिपोर्ट')} (S14)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Download complete performance PDF — all exams in one report','पूरी प्रदर्शन रिपोर्ट PDF डाउनलोड करें')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="65" height="80" viewBox="0 0 65 80" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <rect x="8" y="5" width="49" height="65" rx="5" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
          <path d="M8 22h49" stroke="#4D9FFF" strokeWidth="1"/>
          <text x="32.5" y="15" textAnchor="middle" fontSize="7" fill="#4D9FFF" fontWeight="700">REPORT</text>
          <rect x="15" y="28" width="35" height="5" rx="2.5" fill="#4D9FFF" opacity=".6"/>
          <rect x="15" y="38" width="28" height="5" rx="2.5" fill="#4D9FFF" opacity=".4"/>
          <rect x="15" y="48" width="32" height="5" rx="2.5" fill="#4D9FFF" opacity=".3"/>
          <rect x="15" y="58" width="20" height="5" rx="2.5" fill="#4D9FFF" opacity=".2"/>
          <circle cx="52" cy="68" r="12" fill="rgba(0,196,140,0.2)" stroke="#00C48C" strokeWidth="1.5"/>
          <path d="M47 68L51 72L57 63" stroke="#00C48C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:4}}>{t('"Your report card tells your story — make it a story worth telling."','"आपकी रिपोर्ट आपकी कहानी कहती है — इसे एक अच्छी कहानी बनाएं।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{results.length>0?`${results.length} ${t('exams included in report','परीक्षाएं शामिल')}`:{t('Give exams first to generate report','रिपोर्ट के लिए पहले परीक्षाएं दें')}}</div>
        </div>
      </div>
      {/* Report Preview */}
      <div style={{background:'linear-gradient(135deg,rgba(0,22,40,.97),rgba(0,31,58,.94))',border:'2px solid rgba(77,159,255,.3)',borderRadius:20,overflow:'hidden',marginBottom:20,boxShadow:'0 8px 32px rgba(0,0,0,.4)'}}>
        <div style={{background:'linear-gradient(135deg,#001F3F,#003366)',padding:'18px 22px',display:'flex',alignItems:'center',gap:11,borderBottom:'1px solid rgba(77,159,255,.2)'}}>
          <div style={{width:44,height:44,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:900,color:'#fff',flexShrink:0}}>{(user?.name||'S').charAt(0)}</div>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#fff'}}>{user?.name||'Student'}</div>
            <div style={{fontSize:10,color:'rgba(77,159,255,.7)'}}>{t('NEET 2026 Performance Report','NEET 2026 प्रदर्शन रिपोर्ट')}</div>
          </div>
          <div style={{marginLeft:'auto',fontSize:10,color:'rgba(77,159,255,.5)'}}>{new Date().toLocaleDateString('en-IN',{month:'long',year:'numeric'})}</div>
        </div>
        <div style={{padding:'18px 22px'}}>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(110px,1fr))',gap:10,marginBottom:16}}>
            {[[results.length,t('Tests','टेस्ट'),C.primary,'📝'],[best?`${best}/720`:'—',t('Best','सर्वश्रेष्ठ'),C.gold,'🏆'],[avg?`${avg}/720`:'—',t('Avg','औसत'),C.success,'📊'],[bRnk&&bRnk<99999?`#${bRnk}`:'—',t('Best Rank','रैंक'),C.warn,'🥇']].map(([v,l,c,ic])=>(
              <div key={String(l)} style={{textAlign:'center',padding:'12px',background:'rgba(77,159,255,.06)',border:'1px solid rgba(77,159,255,.12)',borderRadius:11}}>
                <div style={{fontSize:18,marginBottom:4}}>{ic}</div>
                <div style={{fontWeight:800,fontSize:17,color:String(c),fontFamily:'Playfair Display,serif'}}>{v}</div>
                <div style={{fontSize:9,color:C.sub,marginTop:2}}>{l}</div>
              </div>
            ))}
          </div>
          {[{n:t('Physics','भौतिकी'),v:results.length?Math.round(results.reduce((a,r:any)=>a+(r.subjectScores?.physics||0),0)/results.length/180*100):0,c:'#00B4FF'},{n:t('Chemistry','रसायन'),v:results.length?Math.round(results.reduce((a,r:any)=>a+(r.subjectScores?.chemistry||0),0)/results.length/180*100):0,c:'#FF6B9D'},{n:t('Biology','जीव विज्ञान'),v:results.length?Math.round(results.reduce((a,r:any)=>a+(r.subjectScores?.biology||0),0)/results.length/360*100):0,c:'#00E5A0'}].map(s=>(
            <div key={s.n} style={{marginBottom:8}}>
              <div style={{display:'flex',justifyContent:'space-between',fontSize:11,marginBottom:3}}><span style={{color:s.c,fontWeight:600}}>{s.n}</span><span style={{color:C.sub,fontWeight:700}}>{s.v}%</span></div>
              <div style={{background:'rgba(255,255,255,.06)',borderRadius:4,height:7,overflow:'hidden'}}><div style={{height:'100%',width:`${s.v}%`,background:s.c,borderRadius:4,transition:'width .8s'}}/></div>
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
      {!results.length&&<div style={{textAlign:'center',fontSize:12,color:C.sub,marginTop:9}}>{t('Give at least one exam to generate your report.','रिपोर्ट के लिए कम से कम एक परीक्षा दें।')}</div>}
    </div>
  )
}
export default function PerformanceReportPage() {
  return <StudentShell pageKey="results"><PerfReportContent/></StudentShell>
}
