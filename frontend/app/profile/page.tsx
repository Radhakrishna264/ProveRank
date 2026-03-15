'use client'
import { useState, useEffect } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}

function ProfileContent() {
  const {lang,darkMode:dm,user,toast,token} = useShell()
  const [tab,  setTab]  = useState<'personal'|'security'|'preferences'>('personal')
  const [name, setName] = useState('')
  const [phone,setPhone]= useState('')
  const [cp,   setCp]   = useState('')
  const [np,   setNp]   = useState('')
  const [cnp,  setCnp]  = useState('')
  const [saving,setSaving]=useState(false)
  const t=(en:string,hi:string)=>lang==='en'?en:hi

  useEffect(()=>{ if(user){setName(user.name||'');setPhone(user.phone||'')} },[user])

  const saveProfile=async()=>{
    if(!token)return; setSaving(true)
    try{const r=await fetch(`${API}/api/auth/me`,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({name,phone})});if(r.ok)toast(t('Profile updated!','प्रोफ़ाइल अपडेट हुई!'),'s');else toast('Failed','e')}catch{toast('Network error','e')}
    setSaving(false)
  }
  const changePass=async()=>{
    if(np!==cnp){toast(t('Passwords do not match','पासवर्ड मेल नहीं खाते'),'e');return}
    try{const r=await fetch(`${API}/api/auth/change-password`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({currentPassword:cp,newPassword:np})});if(r.ok){toast(t('Password changed!','पासवर्ड बदला!'),'s');setCp('');setNp('');setCnp('')}else{const d=await r.json();toast(d.message||'Failed','e')}}catch{toast('Network error','e')}
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>{t('My Profile','मेरी प्रोफ़ाइल')}</h1>
      <div style={{fontSize:13,color:C.sub,marginBottom:20}}>{t('Manage your account & preferences','अकाउंट और प्राथमिकताएं प्रबंधित करें')}</div>

      {/* Profile Hero */}
      <div style={{background:'linear-gradient(135deg,rgba(77,159,255,.15),rgba(0,22,40,.9))',border:'1px solid rgba(77,159,255,.3)',borderRadius:20,padding:24,marginBottom:24,display:'flex',gap:20,alignItems:'center',flexWrap:'wrap',position:'relative',overflow:'hidden'}}>
        <div style={{position:'absolute',right:16,opacity:.06}}><svg width="120" height="100" viewBox="0 0 120 100" fill="none"><circle cx="60" cy="35" r="22" stroke="#4D9FFF" strokeWidth="1.5" fill="none"/><path d="M15 90 Q60 68 105 90" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/></svg></div>
        <div style={{width:72,height:72,borderRadius:'50%',background:`linear-gradient(135deg,${C.primary},#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:28,fontWeight:900,color:'#fff',flexShrink:0,border:'3px solid rgba(77,159,255,.5)'}}>{(user?.name||'S').charAt(0).toUpperCase()}</div>
        <div style={{flex:1}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:C.text,marginBottom:4}}>{user?.name||t('Student','छात्र')}</div>
          <div style={{fontSize:12,color:C.sub,marginBottom:6}}>{user?.email||''}</div>
          <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
            <span style={{fontSize:11,padding:'2px 8px',borderRadius:20,background:'rgba(77,159,255,.15)',color:C.primary,fontWeight:600}}>🎓 {t('Student','छात्र')}</span>
            {(user?.emailVerified||user?.verified)&&<span style={{fontSize:11,padding:'2px 8px',borderRadius:20,background:'rgba(0,196,140,.15)',color:C.success,fontWeight:600}}>✓ {t('Verified','सत्यापित')}</span>}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{display:'flex',gap:0,marginBottom:20,borderRadius:12,overflow:'hidden',border:`1px solid ${C.border}`}}>
        {(['personal','security','preferences']as const).map(tb=>(
          <button key={tb} onClick={()=>setTab(tb)} style={{flex:1,padding:'12px 8px',textAlign:'center',fontSize:12,fontWeight:tab===tb?700:400,background:tab===tb?`linear-gradient(135deg,${C.primary},#0055CC)`:'rgba(0,22,40,.8)',color:tab===tb?'#fff':C.sub,border:'none',cursor:'pointer',fontFamily:'Inter,sans-serif',borderRight:tb!=='preferences'?`1px solid ${C.border}`:'none',transition:'all .3s'}}>
            {tb==='personal'?`👤 ${t('Personal','व्यक्तिगत')}`:tb==='security'?`🔒 ${t('Security','सुरक्षा')}`:`⚙️ ${t('Preferences','प्राथमिकताएं')}`}
          </button>
        ))}
      </div>

      {tab==='personal'&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
            <div style={{gridColumn:'1/-1'}}>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{t('Full Name','पूरा नाम')}</label>
              <input value={name} onChange={e=>setName(e.target.value)} style={inp}/>
            </div>
            <div>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{t('Email','ईमेल')}</label>
              <input value={user?.email||''} disabled style={{...inp,opacity:.6}}/>
            </div>
            <div>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{t('Phone','फ़ोन')}</label>
              <input value={phone} onChange={e=>setPhone(e.target.value)} style={inp} placeholder="+91 XXXXX XXXXX"/>
            </div>
          </div>
          <button onClick={saveProfile} disabled={saving} className="btn-p" style={{marginTop:16,width:'100%',opacity:saving?.7:1}}>{saving?'⟳ Saving...':t('Save Changes','बदलाव सहेजें')}</button>
        </div>
      )}
      {tab==='security'&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
          {[[t('Current Password','वर्तमान पासवर्ड'),cp,setCp],[t('New Password','नया पासवर्ड'),np,setNp],[t('Confirm Password','पुष्टि करें'),cnp,setCnp]].map(([l,v,s]:any)=>(
            <div key={String(l)} style={{marginBottom:12}}>
              <label style={{fontSize:11,color:C.primary,fontWeight:600,display:'block',marginBottom:6,textTransform:'uppercase'}}>{l}</label>
              <input type="password" value={v} onChange={e=>s(e.target.value)} style={inp} placeholder="••••••••"/>
            </div>
          ))}
          <button onClick={changePass} className="btn-p" style={{width:'100%'}}>{t('Change Password','पासवर्ड बदलें')}</button>
        </div>
      )}
      {tab==='preferences'&&(
        <div style={{background:dm?C.card:C.cardL,border:`1px solid ${C.border}`,borderRadius:16,padding:24,backdropFilter:'blur(12px)'}}>
          {[{l:t('Email Notifications','ईमेल सूचनाएं'),d:t('Receive exam reminders','परीक्षा अनुस्मारक पाएं')},{l:t('Dark Mode','डार्क मोड'),d:t('Use dark theme','डार्क थीम उपयोग करें')}].map((p,i)=>(
            <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'14px 0',borderBottom:`1px solid ${C.border}`}}>
              <div><div style={{fontSize:13,fontWeight:600,color:dm?C.text:C.textL}}>{p.l}</div><div style={{fontSize:11,color:C.sub,marginTop:2}}>{p.d}</div></div>
              <div style={{width:44,height:24,borderRadius:12,background:`linear-gradient(90deg,${C.success},#00a87a)`,cursor:'pointer',position:'relative'}}>
                <span style={{position:'absolute',top:2,left:22,width:20,height:20,borderRadius:'50%',background:'#fff',display:'block'}}/>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
export default function ProfilePage() {
  return <StudentShell pageKey="profile"><ProfileContent/></StudentShell>
}
