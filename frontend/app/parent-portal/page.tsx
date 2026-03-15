'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D', warn:'#FFB84D' }

export default function ParentPortalPage() {
  return (
    <StudentShell pageKey="parent-portal">
      {({lang, darkMode:dm, user, toast, token}) => {
        const [parentEmail, setParentEmail] = useState(user?.parentEmail||'')
        const [saving, setSaving] = useState(false)
        const [results, setResults] = useState<any[]>([])
        const [shareLink] = useState(`https://prove-rank.vercel.app/parent-view/${user?._id||''}`)

        useEffect(()=>{
          if(user?.parentEmail) setParentEmail(user.parentEmail)
          if(!token) return
          fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>setResults(Array.isArray(d)?d:[])).catch(()=>{})
        },[user,token])

        const saveParentEmail = async () => {
          if(!parentEmail.trim()){toast(lang==='en'?'Enter parent email':'अभिभावक ईमेल दर्ज करें','e');return}
          setSaving(true)
          try {
            const res = await fetch(`${API}/api/auth/me`,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({parentEmail})})
            if(res.ok) toast(lang==='en'?'Parent email saved! They can now view your progress.':'अभिभावक ईमेल सहेजी! वे अब आपकी प्रगति देख सकते हैं।','s')
            else toast('Failed','e')
          } catch{toast('Network error','e')}
          setSaving(false)
        }

        const copyLink = () => {
          navigator.clipboard?.writeText(shareLink)
          toast(lang==='en'?'Link copied! Share with parent.':'लिंक कॉपी हुआ! अभिभावक को शेयर करें।','s')
        }

        const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            <div style={{marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{lang==='en'?'Parent Portal':'अभिभावक पोर्टल'} (N17)</h1>
              <div style={{fontSize:13,color:C.sub}}>{lang==='en'?'Share your progress with parents — read-only view for complete transparency':'अभिभावकों के साथ प्रगति शेयर करें — पूर्ण पारदर्शिता के लिए केवल-पढ़ें दृश्य'}</div>
            </div>

            {/* SVG Banner */}
            <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.1),rgba(0,22,40,0.85))',border:`1px solid rgba(77,159,255,0.2)`,borderRadius:20,padding:'20px',marginBottom:24,display:'flex',alignItems:'center',gap:16,position:'relative',overflow:'hidden'}}>
              <div style={{position:'absolute',right:16,opacity:.08}}>
                <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
                  <circle cx="40" cy="30" r="16" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                  <circle cx="80" cy="30" r="16" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/>
                  <circle cx="60" cy="65" r="12" fill="rgba(77,159,255,0.2)" stroke="#4D9FFF" strokeWidth="1.5"/>
                  <path d="M15 90 Q40 70 60 77 Q80 70 105 90" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
                  <path d="M40 47 Q50 58 60 60 Q70 58 80 47" stroke="#4D9FFF" strokeWidth="1" strokeLinecap="round"/>
                </svg>
              </div>
              <span style={{fontSize:32}}>👨‍👩‍👧</span>
              <div style={{flex:1}}>
                <div style={{fontSize:14,color:C.primary,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{lang==='en'?'"Keep your parents informed — their support fuels your success."':'"अभिभावकों को सूचित रखें — उनका समर्थन आपकी सफलता का ईंधन है।"'}</div>
                <div style={{fontSize:11,color:C.sub}}>{lang==='en'?'Parents get read-only access — scores, ranks, attendance, integrity':'अभिभावकों को केवल-पढ़ें एक्सेस — स्कोर, रैंक, उपस्थिति, अखंडता'}</div>
              </div>
            </div>

            {/* Setup Parent Email */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:16}}>📧 {lang==='en'?'Add Parent Email':'अभिभावक ईमेल जोड़ें'}</div>
              <div style={{marginBottom:12}}>
                <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{lang==='en'?'Parent / Guardian Email':'अभिभावक ईमेल'}</label>
                <input type="email" value={parentEmail} onChange={e=>setParentEmail(e.target.value)} style={inp} placeholder={lang==='en'?'parent@example.com':'अभिभावक@example.com'}/>
              </div>
              <button onClick={saveParentEmail} disabled={saving} className="btn-p" style={{opacity:saving?.7:1}}>
                {saving?'⟳ Saving...':lang==='en'?'💾 Save Parent Email':'💾 अभिभावक ईमेल सहेजें'}
              </button>
            </div>

            {/* Share Link */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid rgba(0,196,140,0.2)`,borderRadius:16,padding:24,marginBottom:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:12}}>🔗 {lang==='en'?'Share Progress Link':'प्रगति लिंक शेयर करें'}</div>
              <div style={{background:'rgba(0,22,40,0.6)',border:`1px solid ${C.border}`,borderRadius:10,padding:'10px 14px',fontSize:12,color:C.sub,marginBottom:12,wordBreak:'break-all'}}>{shareLink}</div>
              <button onClick={copyLink} className="btn-g">📋 {lang==='en'?'Copy Link':'लिंक कॉपी करें'}</button>
            </div>

            {/* What parents can see */}
            <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:dm?C.text:'#0F172A',marginBottom:14}}>👁️ {lang==='en'?'What Parents Can See':'अभिभावक क्या देख सकते हैं'}</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                {(lang==='en'?['✅ Exam scores & rank','✅ Attempt history','✅ Integrity score summary','✅ Upcoming exam schedule','✅ Performance trend graph','✅ Subject-wise accuracy']:['✅ परीक्षा स्कोर और रैंक','✅ परीक्षा का इतिहास','✅ अखंडता स्कोर','✅ आगामी परीक्षा सारिणी','✅ प्रदर्शन ट्रेंड ग्राफ','✅ विषय-वार सटीकता']).map((item,i)=>(
                  <div key={i} style={{fontSize:12,color:dm?C.text:'#0F172A',padding:'8px 12px',background:'rgba(0,196,140,0.06)',border:'1px solid rgba(0,196,140,0.15)',borderRadius:8}}>{item}</div>
                ))}
              </div>
              <div style={{marginTop:14,padding:'10px 14px',background:'rgba(255,77,77,0.06)',border:'1px solid rgba(255,77,77,0.15)',borderRadius:8,fontSize:11,color:C.sub}}>
                🔒 {lang==='en'?'Parents CANNOT: Edit anything, access exam, change settings or see personal messages.':'अभिभावक नहीं कर सकते: कुछ भी संपादित करें, परीक्षा एक्सेस करें, या व्यक्तिगत संदेश देखें।'}
              </div>
            </div>
          </div>
        )
      }}
    </StudentShell>
  )
}
