'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function DoubtPage() {
  return (
    <StudentShell pageKey="doubt">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [doubts, setDoubts] = useState<any[]>([])
        const [msg, setMsg] = useState('')
        const [subject, setSubject] = useState('Physics')
        const [chapter, setChapter] = useState('')
        const [submitting, setSubmitting] = useState(false)
        const [loading, setLoading] = useState(true)

        useEffect(()=>{
          if(!token) return
          fetch(`${API}/api/doubts`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setDoubts(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>{setDoubts([]);setLoading(false)})
        },[token])

        const submitDoubt = async () => {
          if(!msg.trim()){toast(lang==='en'?'Please write your doubt':'कृपया अपना संदेह लिखें','e');return}
          setSubmitting(true)
          try {
            const res = await fetch(`${API}/api/doubts`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({question:msg,subject,chapter,studentName:user?.name})})
            if(res.ok){toast(lang==='en'?'Doubt submitted! Admin will respond soon.':'संदेह सबमिट हुआ! Admin जल्द जवाब देगा।','s');setMsg('');setDoubts(p=>[{_id:Date.now().toString(),question:msg,subject,chapter,status:'pending',createdAt:new Date().toISOString()},...p])}
            else toast('Failed to submit','e')
          } catch{toast('Network error','e')}
          setSubmitting(false)
        }

        const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}
        const statusCol:{[k:string]:string}={pending:C.warn,answered:C.success,closed:C.sub}
        const statusText:{[k:string]:string}={pending:lang==='en'?'Pending':'लंबित',answered:lang==='en'?'Answered':'उत्तर दिया',closed:lang==='en'?'Closed':'बंद'}

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Doubt & Query System':'संदेह और प्रश्न'} (S63)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Ask specific questions — admin will respond with detailed explanation':'विशिष्ट प्रश्न पूछें — Admin विस्तृत स्पष्टीकरण देगा'}</div>
            </div>

            {/* SVG Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(0,196,140,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(0,196,140,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,opacity:.08}}>
                <svg width="110" height="90" viewBox="0 0 110 90" fill="none">
                  <path d="M15 25 Q15 12 28 12 L82 12 Q95 12 95 25 L95 50 Q95 63 82 63 L55 63 L35 78 L35 63 L28 63 Q15 63 15 50 Z" stroke="#00C48C" strokeWidth="1.5" fill="none"/>
                  <path d="M40 35 Q40 27 48 27 Q56 27 56 35 Q56 41 48 43 L48 48" stroke="#00C48C" strokeWidth="1.5" strokeLinecap="round"/>
                  <circle cx="48" cy="53" r="2" fill="#00C48C"/>
                </svg>
              </div>
              <span style={{fontSize:30}}>💬</span>
              <div style={{flex:1}}>
                <div style={{fontSize:14,color:C.success,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{lang==='en'?'"No question is too small — every doubt cleared is a step forward."':'"कोई भी प्रश्न छोटा नहीं — हर संदेह दूर करना एक कदम आगे है।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{lang==='en'?'Response time: 24-48 hours':'प्रतिक्रिया समय: 24-48 घंटे'}</div>
              </div>
            </div>

            {/* Submit Doubt Form */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>✍️ {lang==='en'?'Submit New Doubt':'नया संदेह सबमिट करें'}</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:12}}>
                <div>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{lang==='en'?'Subject':'विषय'}</label>
                  <select value={subject} onChange={e=>setSubject(e.target.value)} style={{...inp}}>
                    <option value="Physics">{lang==='en'?'⚛️ Physics':'⚛️ भौतिकी'}</option>
                    <option value="Chemistry">{lang==='en'?'🧪 Chemistry':'🧪 रसायन'}</option>
                    <option value="Biology">{lang==='en'?'🧬 Biology':'🧬 जीव विज्ञान'}</option>
                  </select>
                </div>
                <div>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{lang==='en'?'Chapter (optional)':'अध्याय (वैकल्पिक)'}</label>
                  <input value={chapter} onChange={e=>setChapter(e.target.value)} style={inp} placeholder={lang==='en'?'e.g. Electrostatics':'जैसे विद्युत स्थैतिकी'}/>
                </div>
              </div>
              <div style={{marginBottom:14}}>
                <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{lang==='en'?'Your Question / Doubt *':'आपका प्रश्न / संदेह *'}</label>
                <textarea value={msg} onChange={e=>setMsg(e.target.value)} rows={4} placeholder={lang==='en'?'Write your doubt clearly with context... e.g. In this question, why is the answer B and not C?':'अपना संदेह स्पष्ट रूप से लिखें...'} style={{...inp,resize:'vertical'}}/>
              </div>
              <button onClick={submitDoubt} disabled={submitting} className="btn-p" style={{width:'100%',opacity:submitting?.7:1}}>
                {submitting?'⟳ Submitting...':lang==='en'?'📤 Submit Doubt':'📤 संदेह सबमिट करें'}
              </button>
            </div>

            {/* Previous Doubts */}
            <div>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:12}}>📋 {lang==='en'?'My Previous Doubts':'मेरे पिछले संदेह'} ({doubts.length})</div>
              {loading?<div style={{textAlign:'center',padding:'30px',color:C.sub}}>⟳ Loading...</div>:doubts.length===0?(
                <div style={{textAlign:'center',padding:'40px',background:dm?C.card:'rgba(255,255,255,0.85)',borderRadius:16,border:`1px solid ${C.border}`,color:C.sub,fontSize:12}}>{lang==='en'?'No doubts submitted yet. Ask your first question!':'अभी कोई संदेह नहीं। पहला प्रश्न पूछें!'}</div>
              ):(
                doubts.map((d:any,i:number)=>(
                  <div key={d._id||i} style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:12,padding:'14px 18px',marginBottom:10,backdropFilter:'blur(12px)'}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8,marginBottom:8}}>
                      <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                        <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:'rgba(77,159,255,0.15)',color:C.primary,border:`1px solid rgba(77,159,255,0.3)`,fontWeight:600}}>{d.subject}</span>
                        {d.chapter&&<span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:'rgba(255,255,255,0.08)',color:C.sub,fontWeight:600}}>{d.chapter}</span>}
                        <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:`${statusCol[d.status||'pending']}15`,color:statusCol[d.status||'pending'],border:`1px solid ${statusCol[d.status||'pending']}30`,fontWeight:600}}>{statusText[d.status||'pending']}</span>
                      </div>
                      <span style={{fontSize:10,color:C.sub}}>{d.createdAt?new Date(d.createdAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'}):''}</span>
                    </div>
                    <div style={{fontSize:13,color:dm?C.text:'#0F172A',marginBottom:d.answer?8:0,fontWeight:600}}>❓ {d.question}</div>
                    {d.answer&&<div style={{fontSize:12,color:C.success,background:'rgba(0,196,140,0.06)',border:'1px solid rgba(0,196,140,0.2)',borderRadius:8,padding:'8px 12px',marginTop:6}}><strong>💡 {lang==='en'?'Answer:':'उत्तर:'}</strong> {d.answer}</div>}
                  </div>
                ))
              )}
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
