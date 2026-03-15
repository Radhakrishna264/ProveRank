'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
function OMRContent() {
  const {lang,darkMode:dm,toast,token}=useShell()
  const [results,setResults]=useState<any[]>([])
  const [sel,setSel]=useState<any>(null)
  const [omr,setOmr]=useState<any>(null)
  const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{const list=Array.isArray(d)?d:[];setResults(list);if(list.length)setSel(list[0]);setLoading(false)}).catch(()=>setLoading(false))
  },[token])
  useEffect(()=>{
    if(!sel||!token) return
    fetch(`${API}/api/results/${sel._id}/omr`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():null).then(d=>{if(d)setOmr(d)}).catch(()=>{})
  },[sel,token])
  const ans=omr?.answers||{}
  const corrAns=omr?.correctAnswers||{}
  const sections=[{name:t('Physics','भौतिकी'),icon:'⚛️',col:'#00B4FF',s:0,e:45},{name:t('Chemistry','रसायन'),icon:'🧪',col:'#FF6B9D',s:45,e:90},{name:t('Biology','जीव विज्ञान'),icon:'🧬',col:'#00E5A0',s:90,e:180}]
  const dlPDF=async()=>{
    if(!sel) return
    try{const r=await fetch(`${API}/api/results/${sel._id}/omr/pdf`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`OMR_${sel.examTitle||'exam'}.pdf`;a.click();toast(t('Downloaded!','डाउनलोड हुआ!'),'s')}else toast(t('PDF not available','PDF उपलब्ध नहीं'),'w')}catch{toast('Network error','e')}
  }
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>📋 {t('OMR Sheet View','OMR शीट व्यू')} (S102)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Visual bubble sheet — Green: correct, Red: wrong, Orange: attempted wrong, Grey: skipped','विज़ुअल शीट — हरा: सही, लाल: गलत, ग्रे: छोड़ा')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="65" height="75" viewBox="0 0 65 75" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <rect x="5" y="5" width="55" height="65" rx="5" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
          <path d="M5 22h55" stroke="#4D9FFF" strokeWidth="1"/>
          <text x="32.5" y="16" textAnchor="middle" fontSize="8" fill="#4D9FFF" fontWeight="700">OMR SHEET</text>
          {Array.from({length:4},(_,row)=>Array.from({length:5},(_,col)=>(
            <circle key={`${row}-${col}`} cx={14+col*9} cy={32+row*10} r="3.5"
              fill={row===0&&col===0?'#00C48C':row===1&&col===2?'#FF4D4D':row===0&&col===3?'#4D9FFF':'rgba(77,159,255,0.15)'}
              stroke="#4D9FFF" strokeWidth=".8"/>
          )))}
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Review every answer — understanding mistakes is the fastest path to improvement."','"हर उत्तर की समीक्षा करें — गलतियां समझना सुधार का सबसे तेज़ रास्ता है।"')}</div>
          <div style={{display:'flex',gap:10,marginTop:6,flexWrap:'wrap'}}>
            {[[C.success,t('Correct','सही')],[C.danger,t('Wrong','गलत')],['rgba(255,255,255,.15)',t('Skipped','छोड़ा')]].map(([col,lbl])=>(
              <div key={String(lbl)} style={{display:'flex',alignItems:'center',gap:4,fontSize:10}}>
                <div style={{width:10,height:10,borderRadius:2,background:String(col)}}/>
                <span style={{color:C.sub}}>{lbl}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      {results.length>0&&(
        <div style={{display:'flex',gap:7,marginBottom:18,flexWrap:'wrap'}}>
          {results.slice(0,6).map((r:any)=>(
            <button key={r._id} onClick={()=>{setSel(r);setOmr(null)}} style={{padding:'7px 13px',borderRadius:9,border:`1px solid ${sel?._id===r._id?C.primary:C.border}`,background:sel?._id===r._id?`${C.primary}22`:C.card,color:sel?._id===r._id?C.primary:C.sub,cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif',fontWeight:sel?._id===r._id?700:400,transition:'all .2s'}}>
              {(r.examTitle||'Exam').split(' ').slice(-2).join(' ')}
            </button>
          ))}
        </div>
      )}
      {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳</div>:
        !sel?(
          <div style={{textAlign:'center',padding:'60px 20px',background:dm?C.card:C.cardL,borderRadius:20,border:`1px solid ${C.border}`}}>
            <div style={{fontSize:40,marginBottom:12}}>📋</div>
            <div style={{fontWeight:700,color:dm?C.text:C.textL,marginBottom:6}}>{t('No exam results yet','अभी कोई परिणाम नहीं')}</div>
            <a href="/my-exams" className="btn-p" style={{textDecoration:'none',display:'inline-block'}}>{t('Give First Exam →','पहली परीक्षा दें →')}</a>
          </div>
        ):(
          <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(77,159,255,.3)',borderRadius:18,overflow:'hidden',backdropFilter:'blur(14px)'}}>
            <div style={{padding:'13px 18px',borderBottom:`1px solid ${C.border}`,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8}}>
              <div>
                <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL}}>{sel.examTitle||'—'}</div>
                <div style={{fontSize:11,color:C.sub}}>Score: <span style={{color:C.primary,fontWeight:700}}>{sel.score}/{sel.totalMarks||720}</span> · Rank: <span style={{color:C.gold,fontWeight:700}}>#{sel.rank||'—'}</span></div>
              </div>
              <button onClick={dlPDF} className="btn-p" style={{fontSize:11}}>📄 {t('Download PDF','PDF')}</button>
            </div>
            {sections.map(sec=>(
              <div key={sec.name} style={{padding:'14px 18px',borderBottom:`1px solid ${C.border}`}}>
                <div style={{fontWeight:700,fontSize:12,color:sec.col,marginBottom:10}}>{sec.icon} {sec.name} — Q{sec.s+1}–Q{sec.e}</div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(32px,1fr))',gap:4}}>
                  {Array.from({length:sec.e-sec.s},(_,i)=>{
                    const qn=sec.s+i+1; const myA=ans[qn]; const cA=corrAns[qn]
                    const isC=myA&&cA&&myA===cA; const isW=myA&&cA&&myA!==cA
                    return (
                      <div key={qn} title={`Q${qn}: ${myA||'Not attempted'}${cA?` (Correct: ${cA})`:''}`}
                        style={{width:'100%',aspectRatio:'1',borderRadius:5,background:isC?C.success:isW?C.danger:myA?C.warn:'rgba(255,255,255,.07)',border:`1px solid ${isC?'rgba(0,196,140,.5)':isW?'rgba(255,77,77,.5)':myA?'rgba(255,184,77,.4)':'rgba(255,255,255,.1)'}`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:8,fontWeight:700,color:'rgba(255,255,255,.9)',cursor:'default',transition:'all .2s'}}>
                        {qn}
                      </div>
                    )
                  })}
                </div>
              </div>
            ))}
            <div style={{padding:'11px 18px',display:'flex',gap:10,flexWrap:'wrap',fontSize:11,alignItems:'center'}}>
              {[[C.success,t('Correct','सही')],[C.danger,t('Wrong','गलत')],[C.warn,t('Attempted','प्रयास किया')],['rgba(255,255,255,.07)',t('Skipped','छोड़ा')]].map(([col,label])=>(
                <div key={String(label)} style={{display:'flex',alignItems:'center',gap:5}}>
                  <div style={{width:13,height:13,borderRadius:3,background:String(col),border:'1px solid rgba(255,255,255,.15)'}}/>
                  <span style={{color:C.sub}}>{label}</span>
                </div>
              ))}
            </div>
          </div>
        )
      }
    </div>
  )
}
export default function OMRPage() {
  return <StudentShell pageKey="results"><OMRContent/></StudentShell>
}
