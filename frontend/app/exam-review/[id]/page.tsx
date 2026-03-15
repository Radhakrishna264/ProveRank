'use client'
import { useState, useEffect } from 'react'
import { useParams } from 'next/navigation'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function ExamReviewPage() {
  const params = useParams()
  const resultId = params?.id as string
  return (
    <StudentShell pageKey="results">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [result, setResult] = useState<any>(null)
        const [questions, setQuestions] = useState<any[]>([])
        const [currentQ, setCurrentQ] = useState(0)
        const [filter, setFilter] = useState<'all'|'wrong'|'correct'|'skipped'>('all')
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token||!resultId) return
          Promise.all([
            fetch(`${API}/api/results/${resultId}`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():null),
            fetch(`${API}/api/results/${resultId}/review`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).catch(()=>[]),
          ]).then(([r,qs])=>{setResult(r);setQuestions(Array.isArray(qs)?qs:[]);setLoading(false)}).catch(()=>setLoading(false))
        },[token,resultId])

        const answers = result?.answers||{}
        const correctAnswers = result?.correctAnswers||{}

        const filtered = questions.filter((q:any)=>{
          const myAns = answers[q._id||q.questionId]
          const corrAns = correctAnswers[q._id||q.questionId]
          if(filter==='correct') return myAns&&myAns===corrAns
          if(filter==='wrong') return myAns&&myAns!==corrAns
          if(filter==='skipped') return !myAns
          return true
        })
        const q = filtered[currentQ]

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:6}}>
                <a href="/results" style={{fontSize:12,color:C.primary,textDecoration:'none'}}>← {lang==='en'?'Back to Results':'परिणाम पर वापस'}</a>
              </div>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Exam Review Mode':'परीक्षा समीक्षा मोड'} (S29)</h1>
              <div style={{fontSize:13,color:C.sub}}>{result?.examTitle||''} · {lang==='en'?'Review answers with explanations':'उत्तरों की समीक्षा स्पष्टीकरण के साथ'}</div>
            </div>

            {/* Stats */}
            {result&&(
              <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:20}}>
                {[[result.correct||0,lang==='en'?'Correct':'सही',C.success,'✅'],[result.wrong||0,lang==='en'?'Wrong':'गलत',C.danger,'❌'],[result.unattempted||0,lang==='en'?'Skipped':'छोड़ा',C.sub,'⭕'],[result.score,lang==='en'?'Score':'स्कोर',C.primary,'📊']].map(([v,l,c,i])=>(
                  <div key={String(l)} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:12,padding:'12px 18px',flex:1,minWidth:80,textAlign:'center',backdropFilter:'blur(12px)'}}>
                    <div style={{fontSize:18}}>{i}</div>
                    <div style={{fontWeight:800,fontSize:18,color:String(c)}}>{v}</div>
                    <div style={{fontSize:10,color:C.sub}}>{l}</div>
                  </div>
                ))}
              </div>
            )}

            {/* Filter */}
            <div style={{display:'flex',gap:8,marginBottom:16,flexWrap:'wrap'}}>
              {(['all','correct','wrong','skipped'] as const).map(f=>(
                <button key={f} onClick={()=>{setFilter(f);setCurrentQ(0)}} style={{padding:'8px 14px',borderRadius:8,border:`1px solid ${filter===f?C.primary:C.border}`,background:filter===f?`${C.primary}22`:C.card,color:filter===f?C.primary:C.sub,cursor:'pointer',fontSize:11,fontFamily:'Inter,sans-serif',fontWeight:filter===f?700:400}}>
                  {f==='all'?(lang==='en'?'All':'सभी'):f==='correct'?(lang==='en'?'✅ Correct':'✅ सही'):f==='wrong'?(lang==='en'?'❌ Wrong':'❌ गलत'):(lang==='en'?'⭕ Skipped':'⭕ छोड़ा')} ({f==='all'?questions.length:filtered.length})
                </button>
              ))}
            </div>

            {loading?<div style={{textAlign:'center',padding:'40px',color:C.sub}}>⟳ Loading review...</div>:filtered.length===0?(
              <div style={{textAlign:'center',padding:'40px',color:C.sub,background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:16,border:`1px solid ${C.border}`}}>{lang==='en'?'No questions in this category':'इस श्रेणी में कोई प्रश्न नहीं'}</div>
            ):q&&(
              <div>
                {/* Question Card */}
                <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)',marginBottom:14}}>
                  <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:12}}>
                    <span style={{fontSize:11,padding:'2px 8px',borderRadius:20,background:'rgba(77,159,255,0.15)',color:C.primary,fontWeight:700}}>Q{currentQ+1}/{filtered.length}</span>
                    {q.subject&&<span style={{fontSize:11,padding:'2px 8px',borderRadius:20,background:q.subject==='Physics'?'rgba(0,180,255,0.15)':q.subject==='Chemistry'?'rgba(255,107,157,0.15)':'rgba(0,229,160,0.15)',color:q.subject==='Physics'?'#00B4FF':q.subject==='Chemistry'?'#FF6B9D':'#00E5A0',fontWeight:600}}>{q.subject}</span>}
                  </div>
                  <div style={{fontSize:15,color:dm?C.text:'#0F172A',lineHeight:1.7,marginBottom:16}}>{q.text||q.question||'—'}</div>

                  {/* Options with correct/wrong highlight */}
                  <div style={{display:'flex',flexDirection:'column',gap:8,marginBottom:14}}>
                    {(q.options||[]).map((opt:string,i:number)=>{
                      const letter=String.fromCharCode(65+i)
                      const myAns=answers[q._id||q.questionId]
                      const corrAns=correctAnswers[q._id||q.questionId]||q.correctAnswer
                      const isCorrect=letter===corrAns
                      const isMyWrong=letter===myAns&&myAns!==corrAns
                      const bg=isCorrect?'rgba(0,196,140,0.15)':isMyWrong?'rgba(255,77,77,0.15)':'rgba(0,22,40,0.5)'
                      const border2=isCorrect?'rgba(0,196,140,0.5)':isMyWrong?'rgba(255,77,77,0.5)':'rgba(77,159,255,0.15)'
                      return (
                        <div key={i} style={{display:'flex',alignItems:'center',gap:10,padding:'10px 14px',background:bg,border:`1px solid ${border2}`,borderRadius:10}}>
                          <span style={{width:28,height:28,borderRadius:'50%',background:isCorrect?C.success:isMyWrong?C.danger:'rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:12,color:isCorrect||isMyWrong?'#fff':C.sub,flexShrink:0}}>{letter}</span>
                          <span style={{fontSize:13,color:isCorrect?C.success:isMyWrong?C.danger:dm?C.text:'#0F172A'}}>{opt}</span>
                          {isCorrect&&<span style={{marginLeft:'auto',fontSize:14}}>✅</span>}
                          {isMyWrong&&<span style={{marginLeft:'auto',fontSize:14}}>❌</span>}
                        </div>
                      )
                    })}
                  </div>

                  {/* Explanation */}
                  {q.explanation&&(
                    <div style={{background:'rgba(77,159,255,0.06)',border:`1px solid rgba(77,159,255,0.15)`,borderRadius:10,padding:'12px 16px'}}>
                      <div style={{fontSize:11,color:C.primary,fontWeight:700,marginBottom:4}}>💡 {lang==='en'?'Explanation':'स्पष्टीकरण'}</div>
                      <div style={{fontSize:12,color:C.sub,lineHeight:1.7}}>{q.explanation}</div>
                    </div>
                  )}
                </div>

                {/* Nav */}
                <div style={{display:'flex',justifyContent:'space-between',gap:10}}>
                  <button onClick={()=>setCurrentQ(p=>Math.max(0,p-1))} disabled={currentQ===0} style={{padding:'10px 20px',background:'rgba(77,159,255,0.12)',color:currentQ===0?C.sub:C.primary,border:`1px solid ${currentQ===0?C.border:'rgba(77,159,255,0.3)'}`,borderRadius:10,cursor:currentQ===0?'not-allowed':'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',opacity:currentQ===0?.5:1}}>← {lang==='en'?'Prev':'पिछला'}</button>
                  <span style={{fontSize:12,color:C.sub,alignSelf:'center'}}>{currentQ+1} / {filtered.length}</span>
                  <button onClick={()=>setCurrentQ(p=>Math.min(filtered.length-1,p+1))} disabled={currentQ===filtered.length-1} style={{padding:'10px 20px',background:`linear-gradient(135deg,${C.primary},#0055CC)`,color:'#fff',border:'none',borderRadius:10,cursor:currentQ===filtered.length-1?'not-allowed':'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',opacity:currentQ===filtered.length-1?.5:1}}>{lang==='en'?'Next →':'अगला →'}</button>
                </div>
              </div>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
