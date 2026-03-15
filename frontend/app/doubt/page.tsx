'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}
function DoubtContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [doubts,setDoubts]=useState<any[]>([])
  const [msg,setMsg]=useState(''); const [subject,setSubject]=useState('Physics'); const [chapter,setChapter]=useState('')
  const [sending,setSending]=useState(false); const [loading,setLoading]=useState(true)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{
    if(!token) return
    fetch(`${API}/api/doubts`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>{setDoubts(Array.isArray(d)?d:[]);setLoading(false)}).catch(()=>{setDoubts([]);setLoading(false)})
  },[token])
  const submit=async()=>{
    if(!msg.trim()){toast(t('Please write your doubt','कृपया संदेह लिखें'),'e');return}
    setSending(true)
    try{
      const r=await fetch(`${API}/api/doubts`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({question:msg,subject,chapter,studentName:user?.name})})
      if(r.ok){toast(t('Submitted! Admin will respond within 24-48 hrs.','सबमिट हुआ! Admin 24-48 घंटे में जवाब देगा।'),'s');setMsg('');setDoubts(p=>[{_id:Date.now().toString(),question:msg,subject,chapter,status:'pending',createdAt:new Date().toISOString()},...p])}
      else toast(t('Failed','विफल'),'e')
    }catch{toast('Network error','e')}
    setSending(false)
  }
  const stCol:{[k:string]:string}={pending:C.warn,answered:C.success,closed:C.sub}
  const stTxt:{[k:string]:string}={pending:t('Pending','लंबित'),answered:t('Answered','उत्तर दिया'),closed:t('Closed','बंद')}
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.success},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>💬 {t('Doubt & Query','संदेह और प्रश्न')} (S63)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Ask specific questions — Admin responds with detailed explanation','विशिष्ट प्रश्न पूछें — Admin विस्तृत उत्तर देगा')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(0,196,140,.1),rgba(0,22,40,.88))',border:'1px solid rgba(0,196,140,.22)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="65" height="65" viewBox="0 0 65 65" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <path d="M10 22 Q10 10 22 10 L43 10 Q55 10 55 22 L55 38 Q55 50 43 50 L32.5 50 L15 60 L15 50 L22 50 Q10 50 10 38 Z" stroke="#00C48C" strokeWidth="1.5" fill="rgba(0,196,140,0.1)"/>
          <path d="M32.5 24 Q32.5 18 37.5 18 Q42.5 18 42.5 24 Q42.5 30 32.5 32 L32.5 35" stroke="#00C48C" strokeWidth="1.5" strokeLinecap="round"/>
          <circle cx="32.5" cy="39" r="2" fill="#00C48C"/>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.success,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"No question is too small — every doubt cleared is a step forward."','"कोई भी प्रश्न छोटा नहीं — हर संदेह दूर करना एक कदम आगे है।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{t('Response time: 24-48 hours','प्रतिक्रिया समय: 24-48 घंटे')} · {doubts.length} {t('doubts submitted','संदेह सबमिट')}</div>
        </div>
      </div>
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,marginBottom:18,backdropFilter:'blur(14px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:14}}>✍️ {t('Submit New Doubt','नया संदेह सबमिट करें')}</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:12}}>
          <div>
            <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>{t('Subject','विषय')}</label>
            <select value={subject} onChange={e=>setSubject(e.target.value)} style={{...inp}}>
              <option value="Physics">⚛️ {t('Physics','भौतिकी')}</option>
              <option value="Chemistry">🧪 {t('Chemistry','रसायन')}</option>
              <option value="Biology">🧬 {t('Biology','जीव विज्ञान')}</option>
            </select>
          </div>
          <div>
            <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>{t('Chapter (optional)','अध्याय (वैकल्पिक)')}</label>
            <input value={chapter} onChange={e=>setChapter(e.target.value)} style={inp} placeholder={t('e.g. Electrostatics','जैसे विद्युत स्थैतिकी')}/>
          </div>
        </div>
        <div style={{marginBottom:13}}>
          <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase'}}>{t('Your Question *','आपका प्रश्न *')}</label>
          <textarea value={msg} onChange={e=>setMsg(e.target.value)} rows={4} placeholder={t('Write clearly with context... e.g. In this question, why is the answer B and not C?','संदर्भ के साथ स्पष्ट रूप से लिखें...')} style={{...inp,resize:'vertical'}}/>
        </div>
        <button onClick={submit} disabled={sending} className="btn-p" style={{width:'100%',opacity:sending?.7:1}}>{sending?'⟳ Submitting...':t('📤 Submit Doubt','📤 संदेह सबमिट करें')}</button>
      </div>
      <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:12}}>📋 {t('My Doubts','मेरे संदेह')} ({doubts.length})</div>
      {loading?<div style={{textAlign:'center',padding:'20px',color:C.sub,animation:'pulse 1.5s infinite'}}>⟳</div>:
        doubts.length===0?<div style={{textAlign:'center',padding:'30px',background:dm?C.card:C.cardL,borderRadius:14,border:`1px solid ${C.border}`,color:C.sub,fontSize:12}}>{t('No doubts yet. Ask your first question above!','अभी कोई संदेह नहीं। ऊपर पहला प्रश्न पूछें!')}</div>:
        doubts.map((d:any,i:number)=>(
          <div key={d._id||i} style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:12,padding:'13px 16px',marginBottom:10,backdropFilter:'blur(14px)'}}>
            <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:7,marginBottom:7}}>
              <div style={{display:'flex',gap:7,flexWrap:'wrap'}}>
                <span style={{fontSize:10,padding:'1px 7px',borderRadius:20,background:'rgba(77,159,255,.15)',color:C.primary,fontWeight:600}}>{d.subject}</span>
                {d.chapter&&<span style={{fontSize:10,padding:'1px 7px',borderRadius:20,background:'rgba(255,255,255,.08)',color:C.sub}}>{d.chapter}</span>}
                <span style={{fontSize:10,padding:'1px 7px',borderRadius:20,background:`${stCol[d.status||'pending']}15`,color:stCol[d.status||'pending'],fontWeight:600}}>{stTxt[d.status||'pending']}</span>
              </div>
              <span style={{fontSize:10,color:C.sub}}>{d.createdAt?new Date(d.createdAt).toLocaleDateString('en-IN',{day:'numeric',month:'short'}):''}</span>
            </div>
            <div style={{fontSize:12,color:dm?C.text:C.textL,marginBottom:d.answer?7:0,fontWeight:600}}>❓ {d.question}</div>
            {d.answer&&<div style={{fontSize:12,color:C.success,background:'rgba(0,196,140,.07)',border:'1px solid rgba(0,196,140,.2)',borderRadius:8,padding:'8px 12px'}}>💡 {t('Answer:','उत्तर:')} {d.answer}</div>}
          </div>
        ))
      }
    </div>
  )
}
export default function DoubtPage() {
  return <StudentShell pageKey="doubt"><DoubtContent/></StudentShell>
}
