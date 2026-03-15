'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function OMRViewPage() {
  return (
    <StudentShell pageKey="results">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [results, setResults] = useState<any[]>([])
        const [selResult, setSelResult] = useState<any>(null)
        const [omrData, setOmrData] = useState<any>(null)
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{const list=Array.isArray(d)?d:[];setResults(list);if(list.length>0)setSelResult(list[0]);setLoading(false)}).catch(()=>setLoading(false))
        },[token])

        useEffect(()=>{
          if(!selResult||!token) return
          fetch(`${API}/api/results/${selResult._id}/omr`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():null).then(d=>{if(d)setOmrData(d)}).catch(()=>{})
        },[selResult,token])

        const downloadOMR = async () => {
          if(!selResult) return
          try {
            const res = await fetch(`${API}/api/results/${selResult._id}/omr/pdf`,{headers:{Authorization:`Bearer ${token}`}})
            if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`OMR_${selResult.examTitle||'exam'}.pdf`;a.click();toast(lang==='en'?'OMR PDF downloaded!':'OMR PDF डाउनलोड हुआ!','s')}
            else toast('PDF not available','w')
          } catch{toast('Network error','e')}
        }

        const answers = omrData?.answers || {}
        const correctAnswers = omrData?.correctAnswers || {}
        const totalQ = omrData?.totalQuestions || 180
        const sections = [
          {name:lang==='en'?'Physics':'भौतिकी',icon:'⚛️',color:'#00B4FF',start:0,end:45},
          {name:lang==='en'?'Chemistry':'रसायन',icon:'🧪',color:'#FF6B9D',start:45,end:90},
          {name:lang==='en'?'Biology':'जीव विज्ञान',icon:'🧬',color:'#00E5A0',start:90,end:180},
        ]

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'OMR Sheet View':'OMR शीट व्यू'} (S102)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Visual bubble sheet — Green: correct, Red: wrong, Grey: skipped':'विज़ुअल बुलबुला शीट — हरा: सही, लाल: गलत, ग्रे: छोड़ा'}</div>
            </div>

            {/* Quote Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(77,159,255,0.2)`,borderRadius:20,padding:'18px 20px',marginBottom:24,display:'flex',alignItems:'center',gap:14}}>
              <span style={{fontSize:28}}>📋</span>
              <div>
                <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600,marginBottom:2}}>{lang==='en'?'"Review every answer — understanding mistakes is the fastest way to improve."':'"हर उत्तर की समीक्षा करें — गलतियों को समझना सुधार का सबसे तेज़ रास्ता है।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{lang==='en'?'Green = Correct · Red = Wrong · Orange = Flagged · Grey = Skipped':'हरा = सही · लाल = गलत · नारंगी = फ्लैग · ग्रे = छोड़ा'}</div>
              </div>
            </div>

            {/* Exam Selector */}
            {results.length>0&&(
              <div style={{display:'flex',gap:8,marginBottom:20,flexWrap:'wrap'}}>
                {results.slice(0,6).map((r:any)=>(
                  <button key={r._id} onClick={()=>setSelResult(r)} style={{padding:'8px 14px',borderRadius:10,border:`1px solid ${selResult?._id===r._id?C.primary:C.border}`,background:selResult?._id===r._id?`${C.primary}22`:C.card,color:selResult?._id===r._id?C.primary:C.sub,cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif',fontWeight:selResult?._id===r._id?700:400}}>
                    {r.examTitle?.split(' ').slice(-2).join(' ')||'Exam'}
                  </button>
                ))}
              </div>
            )}

            {selResult&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,overflow:'hidden',backdropFilter:'blur(12px)',marginBottom:20}}>
                {/* Header */}
                <div style={{padding:'14px 20px',borderBottom:`1px solid ${C.border}`,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8}}>
                  <div>
                    <div style={{fontWeight:700,fontSize:14,color:dm?C.text:'#0F172A'}}>{selResult.examTitle||'—'}</div>
                    <div style={{fontSize:11,color:C.sub,marginTop:2}}>Score: <span style={{color:C.primary,fontWeight:700}}>{selResult.score}/{selResult.totalMarks||720}</span> · Rank: <span style={{color:C.gold,fontWeight:700}}>#{selResult.rank||'—'}</span></div>
                  </div>
                  <button onClick={downloadOMR} className="btn-p" style={{fontSize:11}}>📄 {lang==='en'?'Download PDF':'PDF डाउनलोड'}</button>
                </div>

                {/* OMR Grid per Section */}
                {sections.map(sec=>(
                  <div key={sec.name} style={{padding:'16px 20px',borderBottom:`1px solid ${C.border}`}}>
                    <div style={{fontWeight:700,fontSize:12,color:sec.color,marginBottom:10}}>{sec.icon} {sec.name} — Q{sec.start+1} to Q{sec.end}</div>
                    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(36px,1fr))',gap:6}}>
                      {Array.from({length:sec.end-sec.start},(_,i)=>{
                        const qNum = sec.start+i+1
                        const ans = answers[qNum]
                        const correct = correctAnswers[qNum]
                        const isCorrect = ans&&correct&&ans===correct
                        const isWrong = ans&&correct&&ans!==correct
                        const bg = isCorrect?C.success:isWrong?C.danger:ans?C.warn:'rgba(255,255,255,0.08)'
                        const border2 = isCorrect?'rgba(0,196,140,0.5)':isWrong?'rgba(255,77,77,0.5)':ans?'rgba(255,184,77,0.4)':'rgba(255,255,255,0.1)'
                        return (
                          <div key={qNum} title={`Q${qNum}: ${ans||'Not attempted'}${correct?` (Correct: ${correct})`:''}`} style={{width:'100%',aspectRatio:'1',borderRadius:6,background:bg,border:`1px solid ${border2}`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:9,fontWeight:700,color:'rgba(255,255,255,0.9)',cursor:'default',transition:'transform .1s'}}>
                            {qNum}
                          </div>
                        )
                      })}
                    </div>
                  </div>
                ))}

                {/* Legend */}
                <div style={{padding:'12px 20px',display:'flex',gap:16,flexWrap:'wrap',fontSize:11}}>
                  {[[C.success,lang==='en'?'Correct':'सही'],[C.danger,lang==='en'?'Wrong':'गलत'],[C.warn,lang==='en'?'Attempted (unchecked)':'प्रयास किया'],['rgba(255,255,255,0.08)',lang==='en'?'Skipped':'छोड़ा']].map(([col,label])=>(
                    <div key={String(label)} style={{display:'flex',alignItems:'center',gap:5}}>
                      <div style={{width:14,height:14,borderRadius:3,background:String(col),border:'1px solid rgba(255,255,255,0.15)'}}/>
                      <span style={{color:C.sub}}>{label}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {loading&&<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading...</div>}
            {!loading&&results.length===0&&(
              <div style={{textAlign:'center',padding:'60px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:20,border:`1px solid ${C.border}`}}>
                <div style={{fontSize:48,marginBottom:12}}>📋</div>
                <div style={{fontWeight:700,color:dm?C.text:'#0F172A',marginBottom:8}}>{lang==='en'?'No exam results yet':'अभी कोई परीक्षा परिणाम नहीं'}</div>
                <a href="/my-exams" style={{padding:'10px 20px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',borderRadius:10,textDecoration:'none',fontWeight:700,fontSize:13,display:'inline-block'}}>{lang==='en'?'Give First Exam →':'पहली परीक्षा दें →'}</a>
              </div>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
