'use client'
import { useState, useEffect } from 'react'
import DashLayout from '@/components/DashLayout'
import { useAuth } from '@/lib/useAuth'

export default function Profile() {
  const { user, logout } = useAuth('student')
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [tab, setTab] = useState<'info'|'security'|'preferences'>('info')
  const [mounted, setMounted] = useState(false)
  const [name, setName] = useState('Student')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [saved, setSaved] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
  },[])

  const dark = mounted ? localStorage.getItem('pr_theme')!=='light' : true
  const v = {
    card: dark ? 'rgba(0,18,36,0.9)' : 'rgba(255,255,255,0.95)',
    bord: dark ? 'rgba(77,159,255,0.14)' : 'rgba(77,159,255,0.25)',
    tm: dark ? '#E8F4FF' : '#0F172A',
    ts: dark ? '#6B8BAF' : '#64748B',
    iBg: dark ? 'rgba(0,22,40,0.8)' : 'rgba(255,255,255,0.9)',
    iBrd: dark ? '#002D55' : '#CBD5E1',
    iClr: dark ? '#E8F4FF' : '#0F172A',
  }

  const handleSave = ()=>{ setSaved(true); setTimeout(()=>setSaved(false),2500) }

  return (
    <DashLayout title={lang==='en'?'My Profile':'मेरी प्रोफाइल'} subtitle={lang==='en'?'Manage your account & preferences':'अपना खाता और प्राथमिकताएं प्रबंधित करें'}>
      <style>{`
        .p-tab{padding:10px 22px;border-radius:10px;border:none;cursor:pointer;font-weight:600;font-size:13px;font-family:Inter,sans-serif;transition:all 0.2s;}
        .p-tab.active{background:rgba(77,159,255,0.18);color:#4D9FFF;}
        .p-tab:not(.active){background:transparent;color:${v.ts};}
        .p-tab:hover:not(.active){background:rgba(77,159,255,0.08);color:${v.tm};}
        .p-input{width:100%;padding:13px 16px;border-radius:10px;border:1.5px solid ${v.iBrd};background:${v.iBg};color:${v.iClr};font-size:14px;font-family:Inter,sans-serif;outline:none;transition:border 0.2s;}
        .p-input:focus{border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.12);}
      `}</style>

      {/* Profile Header Card */}
      <div style={{background:`linear-gradient(135deg,rgba(0,40,100,0.5),rgba(0,22,50,0.5))`,border:`1px solid rgba(77,159,255,0.25)`,borderRadius:20,padding:28,marginBottom:24,display:'flex',gap:24,alignItems:'center',flexWrap:'wrap'}}>
        {/* Avatar */}
        <div style={{position:'relative'}}>
          <div style={{width:80,height:80,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:32,fontWeight:800,color:'#fff',boxShadow:'0 0 0 4px rgba(77,159,255,0.3)',fontFamily:'Playfair Display,serif'}}>S</div>
          <div style={{position:'absolute',bottom:2,right:2,width:20,height:20,borderRadius:'50%',background:'#00C48C',border:`3px solid ${dark?'#000A18':'#F0F7FF'}`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:8}}>✓</div>
        </div>
        <div style={{flex:1}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#E8F4FF',marginBottom:4}}>Student</div>
          <div style={{color:'#6B8BAF',fontSize:13,marginBottom:8}}>student@proverank.com</div>
          <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
            <span style={{background:'rgba(77,159,255,0.15)',color:'#4D9FFF',padding:'4px 12px',borderRadius:99,fontSize:12,fontWeight:700}}>🎓 Student</span>
            <span style={{background:'rgba(0,196,140,0.15)',color:'#00C48C',padding:'4px 12px',borderRadius:99,fontSize:12,fontWeight:700}}>✓ Verified</span>
          </div>
        </div>
        {/* Logout Button — Premium */}
        <button onClick={logout} style={{display:'flex',alignItems:'center',gap:10,padding:'12px 22px',borderRadius:12,border:'1.5px solid rgba(255,71,87,0.4)',background:'rgba(255,71,87,0.1)',color:'#FF6B7A',cursor:'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',transition:'all 0.2s',backdropFilter:'blur(8px)',boxShadow:'0 4px 16px rgba(255,71,87,0.15)'}}
          onMouseEnter={e=>{e.currentTarget.style.background='rgba(255,71,87,0.2)';e.currentTarget.style.transform='translateY(-2px)';e.currentTarget.style.boxShadow='0 8px 24px rgba(255,71,87,0.25)'}}
          onMouseLeave={e=>{e.currentTarget.style.background='rgba(255,71,87,0.1)';e.currentTarget.style.transform='none';e.currentTarget.style.boxShadow='0 4px 16px rgba(255,71,87,0.15)'}}>
          <svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke="#FF6B7A" strokeWidth="2.5" strokeLinecap="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>
          </svg>
          {lang==='en'?'Sign Out':'साइन आउट'}
        </button>
      </div>

      {/* Tabs */}
      <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,overflow:'hidden'}}>
        <div style={{display:'flex',gap:4,padding:'12px 16px',borderBottom:`1px solid ${v.bord}`,overflowX:'auto'}}>
          {([['info',lang==='en'?'Personal Info':'व्यक्तिगत जानकारी'],['security',lang==='en'?'Security':'सुरक्षा'],['preferences',lang==='en'?'Preferences':'प्राथमिकताएं']] as [string,string][]).map(([id,label])=>(
            <button key={id} className={`p-tab ${tab===id?'active':''}`} onClick={()=>setTab(id as any)}>{label}</button>
          ))}
        </div>

        <div style={{padding:'24px'}}>
          {tab==='info' && (
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',gap:18}}>
              {[
                [lang==='en'?'Full Name':'पूरा नाम', name, setName, 'text'],
                [lang==='en'?'Email Address':'ईमेल', email, setEmail, 'email'],
                [lang==='en'?'Mobile Number':'मोबाइल', phone, setPhone, 'tel'],
              ].map(([label, val, setter, type]: any)=>(
                <div key={label}>
                  <label style={{fontSize:12,color:'#4D9FFF',fontWeight:700,display:'block',marginBottom:6,letterSpacing:'0.04em',textTransform:'uppercase'}}>{label}</label>
                  <input type={type} value={val} onChange={e=>setter(e.target.value)} className="p-input" placeholder={`Enter ${label}`}/>
                </div>
              ))}
              <div style={{display:'flex',gap:12,alignItems:'center',paddingTop:4}}>
                <button onClick={handleSave} style={{padding:'12px 28px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
                  {lang==='en'?'Save Changes':'परिवर्तन सहेजें'}
                </button>
                {saved && <span style={{color:'#00C48C',fontWeight:700,fontSize:14}}>✓ {lang==='en'?'Saved!':'सहेजा!'}</span>}
              </div>
            </div>
          )}
          {tab==='security' && (
            <div style={{maxWidth:480,display:'flex',flexDirection:'column',gap:18}}>
              {[lang==='en'?'Current Password':'वर्तमान पासवर्ड',lang==='en'?'New Password':'नया पासवर्ड',lang==='en'?'Confirm New Password':'पासवर्ड की पुष्टि'].map(label=>(
                <div key={label}>
                  <label style={{fontSize:12,color:'#4D9FFF',fontWeight:700,display:'block',marginBottom:6,letterSpacing:'0.04em',textTransform:'uppercase'}}>{label}</label>
                  <input type="password" className="p-input" placeholder="••••••••"/>
                </div>
              ))}
              <button style={{padding:'12px 28px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif',width:'fit-content'}}>
                {lang==='en'?'Update Password':'पासवर्ड अपडेट करें'}
              </button>
            </div>
          )}
          {tab==='preferences' && (
            <div style={{display:'flex',flexDirection:'column',gap:16,maxWidth:500}}>
              {[
                {label:lang==='en'?'Email Notifications':'ईमेल सूचनाएं', sub:lang==='en'?'Receive exam reminders and result alerts':'परीक्षा अनुस्मारक और परिणाम अलर्ट प्राप्त करें', def:true},
                {label:lang==='en'?'SMS Notifications':'SMS सूचनाएं', sub:lang==='en'?'Get important updates on mobile':'मोबाइल पर महत्वपूर्ण अपडेट प्राप्त करें', def:false},
                {label:lang==='en'?'Show in Leaderboard':'लीडरबोर्ड में दिखाएं', sub:lang==='en'?'Allow your rank to be visible to others':'अपनी रैंक को दूसरों के लिए दृश्यमान बनाएं', def:true},
              ].map((p,i)=>(
                <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'14px 18px',background:`rgba(77,159,255,0.05)`,border:`1px solid ${v.bord}`,borderRadius:12}}>
                  <div>
                    <div style={{fontWeight:600,fontSize:14,color:v.tm,marginBottom:3}}>{p.label}</div>
                    <div style={{fontSize:12,color:v.ts}}>{p.sub}</div>
                  </div>
                  <div style={{width:44,height:24,borderRadius:12,background:p.def?'#4D9FFF':'rgba(77,159,255,0.2)',cursor:'pointer',position:'relative',transition:'background 0.3s',flexShrink:0}}>
                    <div style={{position:'absolute',top:3,left:p.def?20:3,width:18,height:18,borderRadius:'50%',background:'#fff',transition:'left 0.3s'}}/>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </DashLayout>
  )
}
