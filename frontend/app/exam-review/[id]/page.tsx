'use client'
import { useState, useEffect } from 'react'
import { useParams } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
function ExamReviewContent() {
  const params = useParams()
  const resultId = params?.id as string
  const {lang,darkMode:dm,toast,token}=useShell()
  const [result,setResult]=useState<any>(null)
  const [qs,setQs]=useState<any[]>([])
  const [curQ,setCurQ]=useState(0)
  const [filter,setFilter]=useState<'all'|'correct'|'wrong'|'skipped'>('all')
  const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{
    if(!token||!resultId) return
    Promise.all([
      fetch(`${API}/api/results/${resultId}`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():null).catch(()=>null),
      fetch(`${API}/api/results/${resultId}/review`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).catch(()=>[]),
    ]).then(([r,q])=>{setResult(r);setQs(Array.isArray(q)?q:[]);setLoading(false)}).catch(()=>setLoading(false))
  },[token,resultId])
  const ans=result?.answers||{}
  const corr=result?.correctAnswers||{}
  const filtered=qs.filter((q:any)=>{
    const mA=ans[q._id||q.questionId]; const cA=corr[q._id||q.questionId]||q.correctAnswer
    if(filter==='correct') return mA&&mA===cA
    if(filter==='wrong') return mA&&mA!==cA
    if(filter==='skipped') return !mA
    return true
  })
  const q=filtered[curQ]
  const correct=qs.filter((q:any)=>{const m=ans[q._id];const c=corr[q._id]||q.correctAnswer;return m&&m===c}).length
  const wrong=qs.filter((q:any)=>{const m=ans[q._id];const c=corr[q._id]||q.correctAnswer;return m&&m!==c}).length
  const skipped=qs.filter((q:any)=>!ans[q._id]).length
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <div style={{marginBottom:16}}><a href="/results" style={{fontSize:12,color:C.primary,textDecoration:'none',display:'flex',alignItems:'center',gap:5}}>← {t('Back to Results','परिणाम पर वापस')}</a></div>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>🔍 {t('Exam Review Mode','परीक्षा समीक्षा मोड')} (S29)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:18}}>{result?.examTitle||''} · {t('Answer-by-answer with explanations','उत्तर-दर-उत्तर स्पष्टीकरण के साथ')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.2)',borderRadius:16,padding:16,marginBottom:20,display:'flex',alignItems:'center',gap:14}}>
        <svg width="55" height="55" viewBox="0 0 55 55" fill="none" style={{animation:'float 3s ease-in-out infinite',flexShrink:0}}>
          <circle cx="27.5" cy="27.5" r="24" stroke="#4D9FFF" strokeWidth="1.5" fill="rgba(77,159,255,0.08)"/>
          <path d="M20 27.5L25 32.5L35 22.5" stroke="#4D9FFF" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700}}>{t('"Every mistake understood is a step closer to perfection."','"हर समझी गई गलती परिपूर्णता के एक कदम और करीब है।"')}</div>
        </div>
      </div>
      {result&&(
        <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:18}}>
          {[[correct,t('Correct','सही'),C.success,'✅'],[wrong,t('Wrong','गलत'),C.danger,'❌'],[skipped,t('Skipped','छोड़ा'),C.sub,'⭕'],[result.score,t('Score','स्कोर'),C.primary,'📊']].map(([v,l,c,ic])=>(
            <div key={String(l)} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:11,padding:'11px 16px',flex:1,minWidth:80,textAlign:'center',backdropFilter:'blur(14px)'}}>
              <div style={{fontSize:18}}>{ic}</div>
              <div style={{fontWeight:800,fontSize:17,color:String(c)}}>{v}</div>
              <div style={{fontSize:10,color:C.sub}}>{l}</div>
            </div>
          ))}
        </div>
      )}
      <div style={{display:'flex',gap:7,marginBottom:14,flexWrap:'wrap'}}>
        {(['all','correct','wrong','skipped']as const).map(f=>(
          <button key={f} onClick={()=>{setFilter(f);setCurQ(0)}} style={{padding:'7px 13px',borderRadius:8,border:`1px solid ${filter===f?C.primary:C.border}`,background:filter===f?`${C.primary}22`:C.card,color:filter===f?C.primary:C.sub,cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif',fontWeight:filter===f?700:400,transition:'all .2s'}}>
            {f==='all'?t('All','सभी'):f==='correct'?`✅ ${t('Correct','सही')}`:f==='wrong'?`❌ ${t('Wrong','गलत')}`:`⭕ ${t('Skipped','छोड़ा')}`}
            {' '}({f==='all'?qs.length:f==='correct'?correct:f==='wrong'?wrong:skipped})
          </button>
        ))}
      </div>
      {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳ Loading review...</div>:
        filtered.length===0?<div style={{textAlign:'center',padding:'30px',color:C.sub,background:dm?C.card:C.cardL,borderRadius:14,border:`1px solid ${C.border}`}}>{t('No questions in this category','इस श्रेणी में कोई प्रश्न नहीं')}</div>:
        q&&(
          <div>
            <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(14px)',marginBottom:12}}>
              <div style={{display:'flex',gap:7,flexWrap:'wrap',marginBottom:11}}>
                <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:'rgba(77,159,255,.15)',color:C.primary,fontWeight:700}}>Q{curQ+1}/{filtered.length}</span>
                {q.subject&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:q.subject==='Physics'?'rgba(0,180,255,.15)':q.subject==='Chemistry'?'rgba(255,107,157,.15)':'rgba(0,229,160,.15)',color:q.subject==='Physics'?'#00B4FF':q.subject==='Chemistry'?'#FF6B9D':'#00E5A0',fontWeight:600}}>{q.subject}</span>}
              </div>
              <div style={{fontSize:14,color:dm?C.text:C.textL,lineHeight:1.7,marginBottom:14}}>{q.text||q.question||'—'}</div>
              <div style={{display:'flex',flexDirection:'column',gap:8,marginBottom:12}}>
                {(q.options||[]).map((opt:string,i:number)=>{
                  const ltr=String.fromCharCode(65+i)
                  const mA=ans[q._id||q.questionId]
                  const cA=corr[q._id||q.questionId]||q.correctAnswer
                  const isC=ltr===cA; const isWrong=ltr===mA&&mA!==cA
                  return (
                    <div key={i} style={{display:'flex',alignItems:'center',gap:10,padding:'11px 14px',background:isC?'rgba(0,196,140,.15)':isWrong?'rgba(255,77,77,.15)':'rgba(0,22,40,.5)',border:`1px solid ${isC?'rgba(0,196,140,.5)':isWrong?'rgba(255,77,77,.5)':'rgba(77,159,255,.14)'}`,borderRadius:10,transition:'all .2s'}}>
                      <span style={{width:28,height:28,borderRadius:'50%',background:isC?C.success:isWrong?C.danger:'rgba(77,159,255,.1)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:12,color:isC||isWrong?'#fff':C.sub,flexShrink:0}}>{ltr}</span>
                      <span style={{fontSize:13,color:isC?C.success:isWrong?C.danger:dm?C.text:C.textL,flex:1}}>{opt}</span>
                      {isC&&<span style={{marginLeft:'auto',fontSize:14}}>✅</span>}
                      {isWrong&&<span style={{marginLeft:'auto',fontSize:14}}>❌</span>}
                    </div>
                  )
                })}
              </div>
              {q.explanation&&(
                <div style={{background:'rgba(77,159,255,.07)',border:'1px solid rgba(77,159,255,.18)',borderRadius:10,padding:'12px 16px'}}>
                  <div style={{fontSize:11,color:C.primary,fontWeight:700,marginBottom:5}}>💡 {t('Explanation','स्पष्टीकरण')}</div>
                  <div style={{fontSize:12,color:C.sub,lineHeight:1.7}}>{q.explanation}</div>
                </div>
              )}
            </div>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:9}}>
              <button onClick={()=>setCurQ(p=>Math.max(0,p-1))} disabled={curQ===0} style={{padding:'10px 18px',background:'rgba(77,159,255,.12)',color:curQ===0?C.sub:C.primary,border:`1px solid ${curQ===0?C.border:'rgba(77,159,255,.3)'}`,borderRadius:9,cursor:curQ===0?'not-allowed':'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif',opacity:curQ===0?.5:1}}>← {t('Prev','पिछला')}</button>
              <span style={{fontSize:12,color:C.sub}}>{curQ+1} / {filtered.length}</span>
              <button onClick={()=>setCurQ(p=>Math.min(filtered.length-1,p+1))} disabled={curQ===filtered.length-1} style={{padding:'10px 18px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',border:'none',borderRadius:9,cursor:curQ===filtered.length-1?'not-allowed':'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif',opacity:curQ===filtered.length-1?.5:1}}>{t('Next','अगला')} →</button>
            </div>
          </div>
        )
      }
    </div>
  )
}
export default function ExamReviewPage() {
  return <StudentShell pageKey="results"><ExamReviewContent/></StudentShell>
}
