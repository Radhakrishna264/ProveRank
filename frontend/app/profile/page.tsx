'use client'
import { useState, useEffect } from 'react'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const C = { primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', border:'rgba(77,159,255,0.22)', text:'#E8F4FF', sub:'#6B8FAF', success:'#00C48C', gold:'#FFD700', danger:'#FF4D4D' }

const TR = {
  en:{ title:'My Profile', sub:'Manage your account & preferences', personalInfo:'Personal Information', security:'Security', preferences:'Preferences',
    name:'Full Name', email:'Email Address', phone:'Mobile Number', save:'Save Changes', saving:'Saving...', saved:'✅ Profile updated!',
    currentPass:'Current Password', newPass:'New Password', confirmPass:'Confirm Password', changePass:'Change Password',
    lang:'Language Preference', theme:'Theme', emailNotif:'Email Notifications', smsNotif:'SMS Notifications',
    quote:'"Know yourself, improve yourself — your profile is your foundation."',
    quoteHi:'खुद को जानो, खुद को बेहतर बनाओ — आपकी प्रोफ़ाइल आपकी नींव है।',
    joined:'Member since', role:'Role', verified:'Verified', stats:'Your Stats',
    totalTests:'Total Tests', bestRank:'Best Rank', bestScore:'Best Score', streak:'Current Streak',
  },
  hi:{ title:'मेरी प्रोफ़ाइल', sub:'अपना अकाउंट और प्राथमिकताएं प्रबंधित करें', personalInfo:'व्यक्तिगत जानकारी', security:'सुरक्षा', preferences:'प्राथमिकताएं',
    name:'पूरा नाम', email:'ईमेल पता', phone:'मोबाइल नंबर', save:'बदलाव सहेजें', saving:'सहेजा जा रहा है...', saved:'✅ प्रोफ़ाइल अपडेट हुई!',
    currentPass:'वर्तमान पासवर्ड', newPass:'नया पासवर्ड', confirmPass:'पासवर्ड की पुष्टि करें', changePass:'पासवर्ड बदलें',
    lang:'भाषा वरीयता', theme:'थीम', emailNotif:'ईमेल सूचनाएं', smsNotif:'SMS सूचनाएं',
    quote:'"खुद को जानो, खुद को बेहतर बनाओ — आपकी प्रोफ़ाइल आपकी नींव है।"',
    quoteHi:'Know yourself, improve yourself — your profile is your foundation.',
    joined:'सदस्य बने', role:'भूमिका', verified:'सत्यापित', stats:'आपके आँकड़े',
    totalTests:'कुल टेस्ट', bestRank:'सर्वश्रेष्ठ रैंक', bestScore:'सर्वश्रेष्ठ स्कोर', streak:'वर्तमान स्ट्रीक',
  }
}

export default function ProfilePage() {
  return (
    <StudentShell pageKey="profile">
      {({lang, darkMode:dm, user, toast, token}) => {
        const t = TR[lang]
        const [tab, setTab] = useState<'personal'|'security'|'preferences'>('personal')
        const [name, setName] = useState(user?.name||'')
        const [phone, setPhone] = useState(user?.phone||'')
        const [saving, setSaving] = useState(false)
        const [results, setResults] = useState<any[]>([])
        const [curPass, setCurPass] = useState('')
        const [newPass, setNewPass] = useState('')
        const [confPass, setConfPass] = useState('')

        useEffect(()=>{
          if(user){setName(user.name||'');setPhone(user.phone||'')}
          if(token) fetch(`${API}/api/results`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():[]).then(d=>setResults(Array.isArray(d)?d:[])).catch(()=>{})
        },[user,token])

        const saveProfile = async () => {
          if(!token) return
          setSaving(true)
          try {
            const res = await fetch(`${API}/api/auth/me`,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({name,phone})})
            if(res.ok) toast(t.saved,'s'); else toast('Failed to save','e')
          } catch{ toast('Network error','e') }
          setSaving(false)
        }

        const changePassword = async () => {
          if(newPass!==confPass){toast('Passwords do not match','e');return}
          if(!token) return
          try {
            const res = await fetch(`${API}/api/auth/change-password`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({currentPassword:curPass,newPassword:newPass})})
            if(res.ok){toast('Password changed successfully!','s');setCurPass('');setNewPass('');setConfPass('')}
            else{const d=await res.json();toast(d.message||'Failed','e')}
          } catch{toast('Network error','e')}
        }

        const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid rgba(77,159,255,0.3)`,borderRadius:10,color:C.text,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}

        const bestScore = results.length>0?Math.max(...results.map((r:any)=>r.score||0)):null
        const bestRank = results.length>0?Math.min(...results.map((r:any)=>r.rank||99999)):null

        return (
          <div style={{animation:'fadeIn .4s ease'}}>
            {/* Header */}
            <div style={{marginBottom:24}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{t.title}</h1>
              <div style={{fontSize:13,color:C.sub}}>{t.sub}</div>
            </div>

            {/* Profile Hero Card */}
            <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(0,22,40,0.9))',border:`1px solid rgba(77,159,255,0.3)`,borderRadius:20,padding:24,marginBottom:24,display:'flex',gap:20,alignItems:'center',flexWrap:'wrap',position:'relative',overflow:'hidden'}}>
              {/* Profile SVG illustration */}
              <div style={{position:'absolute',right:20,top:'50%',transform:'translateY(-50%)',opacity:.08}}>
                <svg width="140" height="120" viewBox="0 0 140 120" fill="none">
                  <circle cx="70" cy="40" r="30" stroke="#4D9FFF" strokeWidth="2"/>
                  <path d="M20 110 Q70 80 120 110" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/>
                  <circle cx="70" cy="40" r="18" fill="rgba(77,159,255,0.2)" stroke="#4D9FFF" strokeWidth="1.5"/>
                  <path d="M55 40 L65 50 L85 30" stroke="#FFD700" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <circle cx="25" cy="25" r="4" fill="#4D9FFF" opacity=".5"/>
                  <circle cx="115" cy="20" r="3" fill="#FFD700" opacity=".5"/>
                  <circle cx="110" cy="70" r="5" fill="#00C48C" opacity=".4"/>
                </svg>
              </div>

              {/* Avatar */}
              <div style={{width:72,height:72,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:28,fontWeight:900,color:'#fff',flexShrink:0,border:'3px solid rgba(77,159,255,0.5)',boxShadow:'0 0 20px rgba(77,159,255,0.3)'}}>
                {(user?.name||'S').charAt(0).toUpperCase()}
              </div>
              <div style={{flex:1,minWidth:200}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:C.text,marginBottom:4}}>{user?.name||'Student'}</div>
                <div style={{fontSize:13,color:C.sub,marginBottom:8}}>{user?.email||''}</div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  <span style={{fontSize:11,padding:'3px 10px',borderRadius:20,background:'rgba(77,159,255,0.15)',color:C.primary,border:`1px solid rgba(77,159,255,0.3)`,fontWeight:600}}>🎓 {lang==='en'?'Student':'छात्र'}</span>
                  {(user?.emailVerified||user?.verified)&&<span style={{fontSize:11,padding:'3px 10px',borderRadius:20,background:'rgba(0,196,140,0.15)',color:C.success,border:`1px solid rgba(0,196,140,0.3)`,fontWeight:600}}>✓ {t.verified}</span>}
                  <span style={{fontSize:11,padding:'3px 10px',borderRadius:20,background:'rgba(255,215,0,0.1)',color:C.gold,border:`1px solid rgba(255,215,0,0.25)`,fontWeight:600}}>⚡ NEET 2026</span>
                </div>
                <div style={{fontSize:11,color:C.sub,marginTop:8}}>{t.joined}: {user?.createdAt?new Date(user.createdAt).toLocaleDateString('en-IN',{year:'numeric',month:'long'}):' 2026'}</div>
              </div>

              {/* Quick Stats */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,minWidth:200}}>
                {[[t.totalTests,results.length,C.primary],[t.bestRank,bestRank?`#${bestRank}`:'—',C.gold],[t.bestScore,bestScore?`${bestScore}/720`:'—',C.success],[t.streak,`${user?.streak||0}d`,'#FF6B6B']].map(([l,v,c])=>(
                  <div key={String(l)} style={{background:'rgba(0,22,40,0.6)',border:`1px solid ${C.border}`,borderRadius:10,padding:'10px 12px',textAlign:'center'}}>
                    <div style={{fontWeight:800,fontSize:16,color:String(c)}}>{v}</div>
                    <div style={{fontSize:9,color:C.sub,marginTop:2}}>{String(l)}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quote */}
            <div style={{background:'rgba(77,159,255,0.06)',border:`1px solid rgba(77,159,255,0.15)`,borderRadius:12,padding:'14px 18px',marginBottom:24,display:'flex',gap:12,alignItems:'flex-start'}}>
              <span style={{fontSize:24,color:C.primary,lineHeight:1}}>💎</span>
              <div>
                <div style={{fontSize:13,color:C.primary,fontStyle:'italic',fontWeight:600,marginBottom:3}}>{t.quote}</div>
                <div style={{fontSize:11,color:C.sub}}>{t.quoteHi}</div>
              </div>
            </div>

            {/* Tabs */}
            <div style={{display:'flex',gap:0,marginBottom:20,borderRadius:12,overflow:'hidden',border:`1px solid ${C.border}`}}>
              {(['personal','security','preferences'] as const).map(tb=>(
                <button key={tb} onClick={()=>setTab(tb)} style={{flex:1,padding:'12px 8px',textAlign:'center',fontSize:12,fontWeight:tab===tb?700:400,background:tab===tb?`linear-gradient(135deg,${C.primary},#0055CC)`:C.card,color:tab===tb?'#fff':C.sub,border:'none',cursor:'pointer',fontFamily:'Inter,sans-serif',borderRight:tb!=='preferences'?`1px solid ${C.border}`:'none',transition:'all .3s'}}>
                  {tb==='personal'?`👤 ${t.personalInfo}`:tb==='security'?`🔒 ${t.security}`:`⚙️ ${t.preferences}`}
                </button>
              ))}
            </div>

            {/* Personal Info Tab */}
            {tab==='personal'&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                  <div style={{gridColumn:'1/-1'}}>
                    <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase',letterSpacing:.5}}>{t.name}</label>
                    <input value={name} onChange={e=>setName(e.target.value)} style={inp} placeholder={t.name}/>
                  </div>
                  <div>
                    <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase',letterSpacing:.5}}>{t.email}</label>
                    <input value={user?.email||''} disabled style={{...inp,opacity:.6,cursor:'not-allowed'}}/>
                  </div>
                  <div>
                    <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase',letterSpacing:.5}}>{t.phone}</label>
                    <input value={phone} onChange={e=>setPhone(e.target.value)} style={inp} placeholder="+91 XXXXX XXXXX"/>
                  </div>
                </div>
                <button onClick={saveProfile} disabled={saving} className="btn-p" style={{marginTop:18,width:'100%',opacity:saving?.7:1}}>
                  {saving?t.saving:t.save}
                </button>
              </div>
            )}

            {/* Security Tab */}
            {tab==='security'&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
                <div style={{display:'flex',gap:12,flexDirection:'column'}}>
                  {[[t.currentPass,curPass,setCurPass],[t.newPass,newPass,setNewPass],[t.confirmPass,confPass,setConfPass]].map(([label,val,setter]:any)=>(
                    <div key={String(label)}>
                      <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase',letterSpacing:.5}}>{label}</label>
                      <input type="password" value={val} onChange={e=>setter(e.target.value)} style={inp} placeholder="••••••••"/>
                    </div>
                  ))}
                </div>
                <button onClick={changePassword} className="btn-p" style={{marginTop:18,width:'100%'}}>{t.changePass}</button>
                <div style={{marginTop:20,padding:'14px',background:'rgba(77,159,255,0.05)',borderRadius:10,border:`1px solid ${C.border}`}}>
                  <div style={{fontWeight:600,fontSize:12,color:dm?C.text:'#0F172A',marginBottom:8}}>🔐 {lang==='en'?'Security Tips':'सुरक्षा सुझाव'}</div>
                  {(lang==='en'?['Use at least 8 characters','Include numbers and symbols','Never share your password','Change password regularly']:['कम से कम 8 अक्षर उपयोग करें','संख्याएं और प्रतीक शामिल करें','अपना पासवर्ड कभी न बताएं','नियमित रूप से पासवर्ड बदलें']).map((tip,i)=>(
                    <div key={i} style={{fontSize:11,color:C.sub,marginBottom:4}}>✓ {tip}</div>
                  ))}
                </div>
              </div>
            )}

            {/* Preferences Tab */}
            {tab==='preferences'&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
                {[{label:t.emailNotif,icon:'📧',desc:lang==='en'?'Receive exam reminders via email':'ईमेल से परीक्षा अनुस्मारक पाएं'},{label:t.smsNotif,icon:'📱',desc:lang==='en'?'Get SMS for results and updates':'परिणाम और अपडेट के लिए SMS पाएं'},{label:lang==='en'?'Dark Mode':'डार्क मोड',icon:'🌙',desc:lang==='en'?'Use dark theme for better focus':'बेहतर फोकस के लिए डार्क थीम'}].map((p,i)=>(
                  <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'14px 0',borderBottom:`1px solid ${C.border}`}}>
                    <div>
                      <div style={{fontSize:13,fontWeight:600,color:dm?C.text:'#0F172A'}}>{p.icon} {p.label}</div>
                      <div style={{fontSize:11,color:C.sub,marginTop:2}}>{p.desc}</div>
                    </div>
                    <div style={{width:44,height:24,borderRadius:12,background:`linear-gradient(90deg,${C.success},#00a87a)`,cursor:'pointer',position:'relative'}}>
                      <span style={{position:'absolute',top:2,left:22,width:20,height:20,borderRadius:'50%',background:'#fff',display:'block',boxShadow:'0 1px 4px rgba(0,0,0,0.3)'}}/>
                    </div>
                  </div>
                ))}
                <div style={{marginTop:20,padding:'14px',background:'rgba(255,215,0,0.05)',borderRadius:10,border:`1px solid rgba(255,215,0,0.15)`,fontSize:12,color:C.sub}}>
                  💡 {lang==='en'?'Your preferences are saved automatically.':'आपकी प्राथमिकताएं स्वतः सहेज ली जाती हैं।'}
                </div>
              </div>
            )}

            {/* Login History */}
            {user?.loginHistory&&user.loginHistory.length>0&&(
              <div style={{background:dm?C.card:'rgba(255,255,255,0.85)',border:`1px solid ${C.border}`,borderRadius:16,padding:20,backdropFilter:'blur(12px)',marginTop:16}}>
                <div style={{fontWeight:700,fontSize:13,color:dm?C.text:'#0F172A',marginBottom:12}}>🕐 {lang==='en'?'Recent Login Activity (S48)':'हालिया लॉगिन गतिविधि'}</div>
                {user.loginHistory.slice(-5).reverse().map((l:any,i:number)=>(
                  <div key={i} style={{display:'flex',justifyContent:'space-between',padding:'8px 0',borderBottom:`1px solid ${C.border}`,fontSize:11}}>
                    <span style={{color:C.sub}}>📍 {l.city||'Unknown location'} · {l.device||'Web browser'}</span>
                    <span style={{color:C.sub}}>{l.at?new Date(l.at).toLocaleString('en-IN',{dateStyle:'short',timeStyle:'short'}):''}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )
      }}
    </StudentShell>
  )
}
