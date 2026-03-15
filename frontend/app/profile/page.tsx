'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',transition:'border-color .2s'}

function ProfileContent() {
  const {lang,darkMode:dm,user,toast,token}=useShell()
  const [tab,     setTab]    = useState<'personal'|'security'|'prefs'>('personal')
  const [saved,   setSaved]  = useState(false)
  const [editing, setEditing]= useState(true)
  const [saving,  setSaving] = useState(false)
  // Fields
  const [name,    setName]   = useState('')
  const [phone,   setPhone]  = useState('')
  const [dob,     setDob]    = useState('')
  const [city,    setCity]   = useState('')
  const [target,  setTarget] = useState('NEET 2026')
  const [board,   setBoard]  = useState('')
  const [school,  setSchool] = useState('')
  const [bio,     setBio]    = useState('')
  const [avatar,  setAvatar] = useState('')
  // Security
  const [cp,setCp]=useState(''); const [np,setNp]=useState(''); const [cnp,setCnp]=useState('')
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{
    if(user){
      setName(user.name||''); setPhone(user.phone||'')
      setDob(user.dob||''); setCity(user.city||''); setTarget(user.targetExam||'NEET 2026')
      setBoard(user.board||''); setSchool(user.school||''); setBio(user.bio||'')
      setAvatar(user.avatar||'')
    }
  },[user])

  const save=async()=>{
    if(!token) return; setSaving(true)
    try{
      const r=await fetch(`${API}/api/auth/me`,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({name,phone,dob,city,targetExam:target,board,school,bio})})
      if(r.ok){toast(t('✅ Profile saved successfully!','✅ प्रोफ़ाइल सफलतापूर्वक सहेजी!'),'s');setSaved(true);setEditing(false)}
      else toast(t('Failed to save','सहेजने में विफल'),'e')
    }catch{toast('Network error','e')}
    setSaving(false)
  }

  const changePass=async()=>{
    if(np!==cnp){toast(t('Passwords do not match','पासवर्ड मेल नहीं खाते'),'e');return}
    if(!np.trim()){toast(t('Enter new password','नया पासवर्ड दर्ज करें'),'e');return}
    try{
      const r=await fetch(`${API}/api/auth/change-password`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({currentPassword:cp,newPassword:np})})
      if(r.ok){toast(t('Password changed!','पासवर्ड बदल गया!'),'s');setCp('');setNp('');setCnp('')}
      else{const d=await r.json();toast(d.message||'Failed','e')}
    }catch{toast('Network error','e')}
  }

  const uploadAvatar=(e:React.ChangeEvent<HTMLInputElement>)=>{
    const file=e.target.files?.[0]; if(!file) return
    const reader=new FileReader()
    reader.onload=(ev)=>{ setAvatar(ev.target?.result as string); setEditing(true); setSaved(false) }
    reader.readAsDataURL(file)
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>👤 {t('My Profile','मेरी प्रोफ़ाइल')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Manage your account, personal info & preferences','अकाउंट, व्यक्तिगत जानकारी और प्राथमिकताएं प्रबंधित करें')}</div>

      {/* Profile Hero Card */}
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.15),rgba(0,22,40,.92))',border:'1px solid rgba(77,159,255,.3)',borderRadius:22,padding:24,marginBottom:22,display:'flex',gap:20,alignItems:'center',flexWrap:'wrap',position:'relative',overflow:'hidden',boxShadow:'0 4px 28px rgba(0,0,0,.25)'}}>
        {/* Animated molecules BG */}
        <div style={{position:'absolute',right:10,top:'50%',transform:'translateY(-50%)',opacity:.07}}>
          <svg width="160" height="130" viewBox="0 0 160 130" fill="none">
            <circle cx="80" cy="65" r="40" stroke="#4D9FFF" strokeWidth="1.5" strokeDasharray="6 4"/>
            <circle cx="80" cy="65" r="25" stroke="#4D9FFF" strokeWidth="1" strokeDasharray="3 5" style={{animationDuration:'8s'}}/>
            <path d="M40 65 L120 65 M80 25 L80 105" stroke="#4D9FFF" strokeWidth=".8"/>
            <circle cx="40" cy="65" r="6" fill="#4D9FFF"/>
            <circle cx="120" cy="65" r="6" fill="#4D9FFF"/>
            <circle cx="80" cy="25" r="6" fill="#FFD700"/>
            <circle cx="80" cy="105" r="6" fill="#00C48C"/>
          </svg>
        </div>

        {/* Avatar */}
        <div style={{position:'relative',flexShrink:0}}>
          <div style={{width:80,height:80,borderRadius:'50%',overflow:'hidden',border:'3px solid rgba(77,159,255,.5)',boxShadow:'0 0 20px rgba(77,159,255,.3)',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center'}}>
            {avatar
              ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover'}}/>
              : <span style={{fontSize:30,fontWeight:900,color:'#fff'}}>{(user?.name||'S').charAt(0).toUpperCase()}</span>
            }
          </div>
          {/* Upload button */}
          <label title={t('Change photo','फोटो बदलें')} style={{position:'absolute',bottom:-2,right:-2,width:26,height:26,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',border:'2px solid rgba(0,5,18,1)'}}>
            <span style={{fontSize:12}}>📷</span>
            <input type="file" accept="image/*" onChange={uploadAvatar} style={{display:'none'}}/>
          </label>
        </div>

        <div style={{flex:1,minWidth:200}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:C.text,marginBottom:4}}>{user?.name||t('Student','छात्र')}</div>
          <div style={{fontSize:12,color:C.sub,marginBottom:8}}>{user?.email||''}</div>
          <div style={{display:'flex',gap:7,flexWrap:'wrap',marginBottom:6}}>
            <span style={{fontSize:10,padding:'2px 9px',borderRadius:20,background:'rgba(77,159,255,.15)',color:C.primary,fontWeight:600}}>🎓 {t('Student','छात्र')}</span>
            {(user?.emailVerified||user?.verified)&&<span style={{fontSize:10,padding:'2px 9px',borderRadius:20,background:'rgba(0,196,140,.15)',color:C.success,fontWeight:600}}>✓ {t('Verified','सत्यापित')}</span>}
            <span style={{fontSize:10,padding:'2px 9px',borderRadius:20,background:`${C.gold}15`,color:C.gold,fontWeight:600}}>⚡ {target||'NEET 2026'}</span>
          </div>
          <div style={{fontSize:10,color:C.sub}}>{t('Member since','सदस्य बने')}: {user?.createdAt?new Date(user.createdAt).toLocaleDateString('en-IN',{month:'long',year:'numeric'}):''}</div>
        </div>

        {/* Edit / Saved state */}
        <div style={{flexShrink:0}}>
          {saved&&!editing?(
            <button onClick={()=>{setEditing(true);setSaved(false)}} className="btn-g">✏️ {t('Edit Profile','प्रोफ़ाइल संपादित करें')}</button>
          ):(
            <div style={{fontSize:11,color:C.sub,textAlign:'center'}}>
              <div style={{fontSize:20,marginBottom:4}}>✏️</div>
              <div>{t('Edit below','नीचे संपादित करें')}</div>
            </div>
          )}
        </div>
      </div>

      {/* Quote */}
      <div style={{background:'rgba(77,159,255,.06)',border:'1px solid rgba(77,159,255,.14)',borderRadius:12,padding:'12px 16px',marginBottom:20,display:'flex',gap:10,alignItems:'center'}}>
        <span style={{fontSize:20}}>💎</span>
        <div style={{fontSize:12,color:C.primary,fontStyle:'italic',fontWeight:600}}>{t('"Know yourself, improve yourself — your profile is your foundation."','"खुद को जानो, खुद को बेहतर बनाओ — आपकी प्रोफ़ाइल आपकी नींव है।"')}</div>
      </div>

      {/* Tabs */}
      <div style={{display:'flex',gap:0,marginBottom:20,borderRadius:12,overflow:'hidden',border:`1px solid ${C.border}`}}>
        {(['personal','security','prefs']as const).map(tb=>(
          <button key={tb} onClick={()=>setTab(tb)} style={{flex:1,padding:'12px 6px',textAlign:'center',fontSize:12,fontWeight:tab===tb?700:400,background:tab===tb?`linear-gradient(135deg,${C.primary},#0055CC)`:'rgba(0,22,40,.8)',color:tab===tb?'#fff':C.sub,border:'none',cursor:'pointer',fontFamily:'Inter,sans-serif',borderRight:tb!=='prefs'?`1px solid ${C.border}`:'none',transition:'all .3s'}}>
            {tb==='personal'?`👤 ${t('Personal','व्यक्तिगत')}`:tb==='security'?`🔒 ${t('Security','सुरक्षा')}`:`⚙️ ${t('Preferences','प्राथमिकताएं')}`}
          </button>
        ))}
      </div>

      {/* Personal Tab */}
      {tab==='personal'&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,backdropFilter:'blur(14px)',boxShadow:'0 4px 20px rgba(0,0,0,.15)'}}>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
            <div style={{gridColumn:'1/-1'}}>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Full Name *','पूरा नाम *')}</label>
              <input value={name} onChange={e=>{setName(e.target.value);setSaved(false);setEditing(true)}} style={inp} placeholder={t('Your full name','आपका पूरा नाम')}/>
            </div>
            <div>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Email','ईमेल')}</label>
              <input value={user?.email||''} disabled style={{...inp,opacity:.55,cursor:'not-allowed'}}/>
            </div>
            <div>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Mobile Number','मोबाइल नंबर')}</label>
              <input value={phone} onChange={e=>{setPhone(e.target.value);setSaved(false);setEditing(true)}} style={inp} placeholder="+91 XXXXX XXXXX"/>
            </div>
            <div>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Date of Birth','जन्म तारीख')}</label>
              <input type="date" value={dob} onChange={e=>{setDob(e.target.value);setSaved(false);setEditing(true)}} style={inp}/>
            </div>
            <div>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('City / State','शहर / राज्य')}</label>
              <input value={city} onChange={e=>{setCity(e.target.value);setSaved(false);setEditing(true)}} style={inp} placeholder={t('e.g. Delhi, UP','जैसे दिल्ली, UP')}/>
            </div>
            <div style={{gridColumn:'1/-1',paddingTop:8,borderTop:`1px solid ${C.border}`,marginTop:4}}>
              <div style={{fontSize:12,color:C.gold,fontWeight:700,marginBottom:12}}>📚 {t('Study Information','अध्ययन जानकारी')}</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                <div>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Target Exam','लक्ष्य परीक्षा')}</label>
                  <select value={target} onChange={e=>{setTarget(e.target.value);setSaved(false);setEditing(true)}} style={{...inp}}>
                    <option value="NEET 2026">NEET 2026</option>
                    <option value="NEET PG">NEET PG</option>
                    <option value="JEE 2026">JEE 2026</option>
                    <option value="CUET">CUET</option>
                  </select>
                </div>
                <div>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Board','बोर्ड')}</label>
                  <select value={board} onChange={e=>{setBoard(e.target.value);setSaved(false);setEditing(true)}} style={{...inp}}>
                    <option value="">Select Board</option>
                    <option value="CBSE">CBSE</option>
                    <option value="ICSE">ICSE</option>
                    <option value="UP Board">UP Board</option>
                    <option value="MP Board">MP Board</option>
                    <option value="Rajasthan Board">Rajasthan Board</option>
                    <option value="Other">Other State Board</option>
                  </select>
                </div>
                <div style={{gridColumn:'1/-1'}}>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('School / College','स्कूल / कॉलेज')}</label>
                  <input value={school} onChange={e=>{setSchool(e.target.value);setSaved(false);setEditing(true)}} style={inp} placeholder={t('Your school or coaching name','आपके स्कूल या कोचिंग का नाम')}/>
                </div>
                <div style={{gridColumn:'1/-1'}}>
                  <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Short Bio','संक्षिप्त परिचय')}</label>
                  <textarea value={bio} onChange={e=>{setBio(e.target.value);setSaved(false);setEditing(true)}} rows={2} placeholder={t('Tell us a little about yourself...','अपने बारे में थोड़ा बताएं...')} style={{...inp,resize:'vertical'}}/>
                </div>
              </div>
            </div>
          </div>

          {/* Save / Saved state */}
          {!saved?(
            <button onClick={save} disabled={saving} className="btn-p" style={{marginTop:18,width:'100%',opacity:saving?.7:1}}>
              {saving?'⟳ Saving...':t('💾 Save Changes','💾 बदलाव सहेजें')}
            </button>
          ):(
            <div style={{marginTop:18,padding:'12px',background:'rgba(0,196,140,.1)',border:'1px solid rgba(0,196,140,.3)',borderRadius:10,textAlign:'center',color:C.success,fontWeight:600,fontSize:13}}>
              ✅ {t('Profile saved! Click "Edit Profile" to make changes.','प्रोफ़ाइल सहेजी! बदलाव के लिए "प्रोफ़ाइल संपादित करें" पर क्लिक करें।')}
            </div>
          )}
        </div>
      )}

      {/* Security Tab */}
      {tab==='security'&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,backdropFilter:'blur(14px)'}}>
          {[[t('Current Password','वर्तमान पासवर्ड'),cp,setCp],[t('New Password','नया पासवर्ड'),np,setNp],[t('Confirm New Password','नया पासवर्ड दोबारा'),cnp,setCnp]].map(([l,v,s]:any,i)=>(
            <div key={i} style={{marginBottom:14}}>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{l}</label>
              <input type="password" value={v} onChange={e=>s(e.target.value)} style={inp} placeholder="••••••••"/>
            </div>
          ))}
          <button onClick={changePass} className="btn-p" style={{width:'100%'}}>{t('🔒 Change Password','🔒 पासवर्ड बदलें')}</button>
          <div style={{marginTop:16,padding:'12px 16px',background:'rgba(77,159,255,.05)',borderRadius:10,border:`1px solid ${C.border}`}}>
            <div style={{fontWeight:600,fontSize:12,color:dm?C.text:C.textL,marginBottom:8}}>🔐 {t('Security Tips','सुरक्षा सुझाव')}</div>
            {(lang==='en'?['Use at least 8 characters with numbers & symbols','Never share your password with anyone','Change password every 3 months']:['कम से कम 8 अक्षर, संख्याएं और प्रतीकों का उपयोग करें','अपना पासवर्ड कभी भी किसी के साथ साझा न करें','हर 3 महीने में पासवर्ड बदलें']).map((tip,i)=>(
              <div key={i} style={{fontSize:11,color:C.sub,marginBottom:3}}>✓ {tip}</div>
            ))}
          </div>
        </div>
      )}

      {/* Preferences Tab */}
      {tab==='prefs'&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:22,backdropFilter:'blur(14px)'}}>
          {[{l:t('Email Notifications','ईमेल सूचनाएं'),d:t('Exam reminders and result alerts via email','ईमेल पर परीक्षा अनुस्मारक और परिणाम अलर्ट'),on:true},{l:t('SMS Notifications','SMS सूचनाएं'),d:t('Get results and updates via SMS','SMS पर परिणाम और अपडेट पाएं'),on:false},{l:t('Study Reminders','अध्ययन अनुस्मारक'),d:t('Daily study reminder notifications','दैनिक अध्ययन अनुस्मारक'),on:true}].map((p,i)=>(
            <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'14px 0',borderBottom:`1px solid ${C.border}`}}>
              <div><div style={{fontSize:13,fontWeight:600,color:dm?C.text:C.textL}}>{p.l}</div><div style={{fontSize:11,color:C.sub,marginTop:2}}>{p.d}</div></div>
              <div style={{width:46,height:26,borderRadius:13,background:p.on?`linear-gradient(90deg,${C.success},#00a87a)`:'rgba(255,255,255,.1)',cursor:'pointer',position:'relative',flexShrink:0,transition:'background .3s'}}>
                <span style={{position:'absolute',top:3,left:p.on?22:3,width:20,height:20,borderRadius:'50%',background:'#fff',display:'block',boxShadow:'0 1px 4px rgba(0,0,0,.3)',transition:'left .3s'}}/>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Login History */}
      {user?.loginHistory?.length>0&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:14,padding:18,backdropFilter:'blur(14px)',marginTop:16}}>
          <div style={{fontWeight:700,fontSize:13,color:dm?C.text:C.textL,marginBottom:10}}>🕐 {t('Recent Login Activity (S48)','हालिया लॉगिन गतिविधि')}</div>
          {user.loginHistory.slice(-5).reverse().map((l:any,i:number)=>(
            <div key={i} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:`1px solid ${C.border}`,fontSize:11}}>
              <span style={{color:C.sub}}>📍 {l.city||'Unknown'} · {l.device||'Web'}</span>
              <span style={{color:C.sub}}>{l.at?new Date(l.at).toLocaleString('en-IN',{dateStyle:'short',timeStyle:'short'}):''}</span>
            </div>
          ))}
        </div>
      )}

      {/* SVG Motivational section */}
      <div style={{background:'linear-gradient(135deg,rgba(167,139,250,.08),rgba(0,22,40,.85))',border:'1px solid rgba(167,139,250,.18)',borderRadius:16,padding:20,marginTop:16,display:'flex',alignItems:'center',gap:16}}>
        <svg width="60" height="60" viewBox="0 0 60 60" fill="none" style={{animation:'float 4s ease-in-out infinite',flexShrink:0}}>
          <circle cx="30" cy="30" r="28" stroke="#A78BFA" strokeWidth="1.5" strokeDasharray="5 4"/>
          <path d="M30 10 L34 22H47L37 30L41 42L30 34L19 42L23 30L13 22H26Z" fill="none" stroke="#A78BFA" strokeWidth="1.5"/>
          <path d="M30 16 L33 24H40L35 28L37 36L30 32L23 36L25 28L20 24H27Z" fill="rgba(167,139,250,0.25)"/>
        </svg>
        <div>
          <div style={{fontSize:14,color:C.purple,fontStyle:'italic',fontWeight:700,marginBottom:3}}>{t('"Your profile reflects your dedication — keep it complete and updated!"','"आपकी प्रोफ़ाइल आपकी लगन को दर्शाती है — इसे पूर्ण और अपडेट रखें!"')}</div>
          <div style={{fontSize:11,color:C.sub}}>{t('Complete profiles get better personalized recommendations.','पूर्ण प्रोफ़ाइल बेहतर व्यक्तिगत अनुशंसाएं प्राप्त करती हैं।')}</div>
        </div>
      </div>
    </div>
  )
}

export default function ProfilePage() {
  return <StudentShell pageKey="profile"><ProfileContent/></StudentShell>
}
