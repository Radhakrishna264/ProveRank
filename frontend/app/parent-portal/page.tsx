'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}
function ParentPortalContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [parentEmail,setParentEmail]=useState('')
  const [saving,setSaving]=useState(false)
  const t=(en:string,hi:string)=>lang==='en'?en:hi
  useEffect(()=>{ if(user?.parentEmail) setParentEmail(user.parentEmail) },[user])
  const shareLink=`https://prove-rank.vercel.app/parent-view/${user?._id||''}`
  const save=async()=>{
    if(!parentEmail.trim()){toast(t('Enter parent email','अभिभावक ईमेल दर्ज करें'),'e');return}
    setSaving(true)
    try{const r=await fetch(`${API}/api/auth/me`,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({parentEmail})});if(r.ok)toast(t('Parent email saved!','अभिभावक ईमेल सहेजी!'),'s');else toast('Failed','e')}catch{toast('Network error','e')}
    setSaving(false)
  }
  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>👨‍👩‍👧 {t('Parent Portal','अभिभावक पोर्टल')} (N17)</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Share your progress — read-only view for parents','प्रगति शेयर करें — अभिभावकों के लिए केवल-पढ़ें व्यू')}</div>
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.1),rgba(0,22,40,.88))',border:'1px solid rgba(77,159,255,.2)',borderRadius:18,padding:18,marginBottom:22,display:'flex',alignItems:'center',gap:14}}>
        <svg width="70" height="60" viewBox="0 0 70 60" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <circle cx="22" cy="20" r="10" stroke="#4D9FFF" strokeWidth="1.5" fill="rgba(77,159,255,0.12)"/>
          <circle cx="48" cy="20" r="10" stroke="#4D9FFF" strokeWidth="1.5" fill="rgba(77,159,255,0.12)"/>
          <path d="M5 55 Q22 38 35 42 Q48 38 65 55" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round" fill="none"/>
          <path d="M28 42 Q35 36 42 42" stroke="#4D9FFF" strokeWidth="1" opacity=".5" fill="none"/>
          <circle cx="35" cy="50" r="6" fill="rgba(77,159,255,0.25)" stroke="#4D9FFF" strokeWidth="1"/>
          <text x="35" y="53.5" textAnchor="middle" fontSize="7" fill="#4D9FFF">👶</text>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Keep your parents informed — their support fuels your success."','"अभिभावकों को सूचित रखें — उनका समर्थन आपकी सफलता का ईंधन है।"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{t('Parents get read-only access — scores, ranks, attendance, no exam access','अभिभावकों को केवल-पढ़ें एक्सेस — स्कोर, रैंक')}</div>
        </div>
      </div>
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,marginBottom:14,backdropFilter:'blur(14px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:13}}>📧 {t('Add Parent Email','अभिभावक ईमेल जोड़ें')}</div>
        <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{t('Parent / Guardian Email','अभिभावक ईमेल')}</label>
        <input type="email" value={parentEmail} onChange={e=>setParentEmail(e.target.value)} style={{...inp,marginBottom:12}} placeholder="parent@example.com"/>
        <button onClick={save} disabled={saving} className="btn-p" style={{opacity:saving?.7:1}}>{saving?'⟳ Saving...':t('💾 Save','💾 सहेजें')}</button>
      </div>
      <div style={{background:dm?C.card:C.cardL,border:'1px solid rgba(0,196,140,.2)',borderRadius:16,padding:22,marginBottom:14,backdropFilter:'blur(14px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:dm?C.text:C.textL,marginBottom:11}}>🔗 {t('Share Progress Link','प्रगति लिंक शेयर करें')}</div>
        <div style={{background:'rgba(0,22,40,.6)',border:`1px solid ${C.border}`,borderRadius:9,padding:'9px 13px',fontSize:11,color:C.sub,marginBottom:11,wordBreak:'break-all'}}>{shareLink}</div>
        <button onClick={()=>{try{navigator.clipboard?.writeText(shareLink)}catch{};toast(t('Link copied!','लिंक कॉपी हुआ!'),'s')}} className="btn-g">📋 {t('Copy Link','लिंक कॉपी करें')}</button>
      </div>
      <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(14px)'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:12}}>👁️ {t('What Parents Can See','अभिभावक क्या देख सकते हैं')}</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:7}}>
          {(lang==='en'?['✅ Exam scores & rank','✅ Attempt history','✅ Upcoming exams','✅ Performance trend','✅ Subject accuracy','✅ Integrity summary']:['✅ परीक्षा स्कोर और रैंक','✅ परीक्षा का इतिहास','✅ आगामी परीक्षाएं','✅ प्रदर्शन ट्रेंड','✅ विषय सटीकता','✅ अखंडता सारांश']).map((item,i)=>(
            <div key={i} style={{fontSize:11,color:dm?C.text:C.textL,padding:'7px 10px',background:'rgba(0,196,140,.06)',border:'1px solid rgba(0,196,140,.14)',borderRadius:8}}>{item}</div>
          ))}
        </div>
        <div style={{marginTop:10,padding:'9px 13px',background:'rgba(255,77,77,.06)',border:'1px solid rgba(255,77,77,.14)',borderRadius:8,fontSize:11,color:C.sub}}>🔒 {t('Parents CANNOT: Edit anything or access exam directly.','अभिभावक: कुछ भी संपादित या परीक्षा एक्सेस नहीं कर सकते।')}</div>
      </div>
    </div>
  )
}
export default function ParentPortalPage() {
  return <StudentShell pageKey="parent-portal"><ParentPortalContent/></StudentShell>
}
