'use client'
import { useState, useEffect, useRef } from 'react'
import DashLayout from '@/components/DashLayout'
import { useAuth } from '@/lib/useAuth'

export default function Profile() {
  const { user, logout } = useAuth('student')
  const formRef = useRef<HTMLDivElement>(null)
    const [activeTheme,setActiveTheme]=useState<'white'|'dark'|'teal'>('dark')
  useEffect(()=>{try{const t=localStorage.getItem('pr_color_theme') as any;if(t&&['white','dark','teal'].includes(t))setActiveTheme(t)}catch{}},[])
  const applyTheme=(t:'white'|'dark'|'teal')=>{
    setActiveTheme(t);
    try{
      localStorage.setItem('pr_color_theme',t);
      // Apply html class immediately
      const h=document.documentElement;
      h.classList.remove('white-theme','dark-theme','teal-theme');
      h.classList.add(t+'-theme');
      h.setAttribute('data-color-theme',t);
    }catch{}
  }
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [tab, setTab] = useState<'info'|'security'|'preferences'>('info')
  const [mounted, setMounted] = useState(false)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [dob, setDob] = useState('')
  const [city, setCity] = useState('')
  const [targetExam, setTargetExam] = useState('NEET')
  const [board, setBoard] = useState('')
  const [school, setSchool] = useState('')
  const [bio, setBio] = useState('')
  const [saved, setSaved] = useState(false)
  const [copied, setCopied] = useState(false)
  const [curPass, setCurPass] = useState('')
  const [newPass, setNewPass] = useState('')
  const [confPass, setConfPass] = useState('')
  const [passSaved, setPassSaved] = useState(false)
  const [emailNotif, setEmailNotif] = useState(true)
  const [smsNotif, setSmsNotif] = useState(false)
  const [showLB, setShowLB] = useState(true)

  useEffect(()=>{
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'
    if(sl) setLang(sl)
  },[])

  useEffect(()=>{
    if(user){
      setName((user as any).name||'')
      setEmail((user as any).email||'')
      setPhone((user as any).phone||'')
      setDob((user as any).dob||'')
      setCity((user as any).city||'')
      setTargetExam((user as any).targetExam||'NEET')
      setBoard((user as any).board||'')
      setSchool((user as any).school||'')
      setBio((user as any).bio||'')
    }
  },[user])

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

  const studentId   = (user as any)?.studentId || null
  const loginHistory = (user as any)?.loginHistory || []
  const memberSince = (user as any)?.createdAt
    ? new Date((user as any).createdAt).toLocaleDateString('en-US',{month:'long',year:'numeric'})
    : ''
  const avatarLetter = (name||'S')[0].toUpperCase()

  const handleSave  = ()=>{ setSaved(true);  setTimeout(()=>setSaved(false),2500) }
  const handlePassSave = ()=>{ setPassSaved(true); setTimeout(()=>setPassSaved(false),2500) }
  const copyId = ()=>{
    if(studentId){ navigator.clipboard.writeText(studentId); setCopied(true); setTimeout(()=>setCopied(false),2000) }
  }
  const scrollToForm = ()=>{
    setTab('info')
    setTimeout(()=>formRef.current?.scrollIntoView({behavior:'smooth',block:'start'}),100)
  }

  return (
    <DashLayout
      title={lang==='en'?'My Profile':'मेरी प्रोफाइल'}
      subtitle={lang==='en'?'Manage your account, personal info & preferences':'अपना खाता और प्राथमिकताएं प्रबंधित करें'}
    >
      <style>{`
        .p-tab{padding:10px 22px;border-radius:10px;border:none;cursor:pointer;font-weight:600;font-size:13px;font-family:Inter,sans-serif;transition:all 0.2s;}
        .p-tab.active{background:rgba(77,159,255,0.18);color:#4D9FFF;}
        .p-tab:not(.active){background:transparent;color:${v.ts};}
        .p-tab:hover:not(.active){background:rgba(77,159,255,0.08);color:${v.tm};}
        .p-input{width:100%;padding:12px 16px;border-radius:10px;border:1.5px solid ${v.iBrd};background:${v.iBg};color:${v.iClr};font-size:14px;font-family:Inter,sans-serif;outline:none;transition:border 0.2s;box-sizing:border-box;}
        .p-input:focus{border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.12);}
        .p-select{width:100%;padding:12px 16px;border-radius:10px;border:1.5px solid ${v.iBrd};background:${v.iBg};color:${v.iClr};font-size:14px;font-family:Inter,sans-serif;outline:none;cursor:pointer;box-sizing:border-box;}
        .p-textarea{width:100%;padding:12px 16px;border-radius:10px;border:1.5px solid ${v.iBrd};background:${v.iBg};color:${v.iClr};font-size:14px;font-family:Inter,sans-serif;outline:none;resize:vertical;min-height:88px;box-sizing:border-box;}
        .p-textarea:focus{border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.12);}
        .flbl{font-size:11px;font-weight:700;display:block;margin-bottom:6px;letter-spacing:0.06em;text-transform:uppercase;color:#4D9FFF;}
        .sid-row{display:flex;align-items:center;gap:10px;background:rgba(0,196,140,0.08);border:1.5px solid rgba(0,196,140,0.32);border-radius:12px;padding:11px 16px;}
        .sid-val{font-family:'Courier New',monospace;font-size:16px;font-weight:800;color:#00C48C;letter-spacing:0.12em;flex:1;}
        .sid-copy{padding:7px 16px;border-radius:8px;border:1px solid rgba(0,196,140,0.4);background:rgba(0,196,140,0.1);color:#00C48C;cursor:pointer;font-size:12px;font-weight:700;white-space:nowrap;}
        .toggle{width:44px;height:24px;border-radius:12px;cursor:pointer;position:relative;transition:background 0.3s;flex-shrink:0;margin-left:14px;}
        .toggle-dot{position:absolute;top:3px;width:18px;height:18px;border-radius:50%;background:#fff;transition:left 0.3s;}
      `}</style>

      {/* ── Header Card ── */}
      <div style={{display:'flex',justifyContent:'flex-end',marginBottom:10}}>
      <button onClick={()=>{try{localStorage.removeItem('pr_token');localStorage.removeItem('pr_role');sessionStorage.clear();}catch(e){}window.location.href='/login'}} style={{display:'inline-flex',alignItems:'center',gap:6,background:'rgba(79,195,247,0.08)',border:'1px solid rgba(79,195,247,0.3)',borderRadius:9,padding:'7px 15px',color:'#4FC3F7',fontSize:13,fontWeight:700,cursor:'pointer'}}>
        <svg width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2.2" viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16,17 21,12 16,7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        Sign Out
      </button>
    </div>
    <div style={{background:'linear-gradient(135deg,rgba(0,40,100,0.5),rgba(0,22,50,0.5))',border:'1px solid rgba(77,159,255,0.25)',borderRadius:20,padding:'22px 24px',marginBottom:20,position:'relative'}}>
      
        <div style={{display:'flex',gap:20,alignItems:'flex-start',flexWrap:'wrap'}}>
          {/* Avatar */}
          <div style={{position:'relative',flexShrink:0}}>
            <div style={{width:76,height:76,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:30,fontWeight:800,color:'#fff',boxShadow:'0 0 0 4px rgba(77,159,255,0.3)',fontFamily:'Playfair Display,serif'}}>{avatarLetter}</div>
            <div style={{position:'absolute',bottom:2,right:2,width:18,height:18,borderRadius:'50%',background:'#00C48C',border:`3px solid ${dark?'#000A18':'#F0F7FF'}`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:7}}>✓</div>
          </div>

          {/* Info */}
          <div style={{flex:1,minWidth:160}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:21,fontWeight:800,color:'#E8F4FF',marginBottom:2}}>{name||'Student'}</div>
            <div style={{color:'#6B8BAF',fontSize:13,marginBottom:8}}>{email}</div>

            {/* Student ID mini badge */}
            {studentId && (
              <div style={{display:'inline-flex',alignItems:'center',gap:8,marginBottom:8}}>
                <span style={{background:'rgba(0,196,140,0.12)',border:'1px solid rgba(0,196,140,0.35)',color:'#00C48C',padding:'3px 12px',borderRadius:8,fontSize:12,fontWeight:800,fontFamily:'Courier New,monospace',letterSpacing:'0.1em'}}>🪪 {studentId}</span>
                <button onClick={copyId} style={{background:'rgba(0,196,140,0.1)',border:'1px solid rgba(0,196,140,0.3)',color:'#00C48C',padding:'3px 10px',borderRadius:7,fontSize:11,fontWeight:700,cursor:'pointer'}}>{copied?'✓ Copied':'📋 Copy'}</button>
              </div>
            )}

            <div style={{display:'flex',gap:6,flexWrap:'wrap',alignItems:'center'}}>
              <span style={{background:'rgba(77,159,255,0.15)',color:'#4D9FFF',padding:'3px 10px',borderRadius:99,fontSize:11,fontWeight:700}}>🎓 Student</span>
              <span style={{background:'rgba(0,196,140,0.15)',color:'#00C48C',padding:'3px 10px',borderRadius:99,fontSize:11,fontWeight:700}}>✓ Verified</span>
              {memberSince&&<span style={{color:'#6B8BAF',fontSize:11,marginLeft:2}}>Member since: {memberSince}</span>}
            </div>
          </div>

          {/* Edit Button */}
          <button
            onClick={scrollToForm}
            style={{position:'absolute',top:16,right:16,background:'rgba(77,159,255,0.12)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:10,padding:'8px 14px',color:'#4D9FFF',cursor:'pointer',fontSize:12,fontWeight:700,display:'flex',alignItems:'center',gap:6,transition:'all 0.2s'}}
            onMouseEnter={e=>{(e.currentTarget as HTMLElement).style.background='rgba(77,159,255,0.22)'}}
            onMouseLeave={e=>{(e.currentTarget as HTMLElement).style.background='rgba(77,159,255,0.12)'}}
          >
            ✏️ {lang==='en'?'Edit below':'संपादित करें'}
          </button>
        </div>
      </div>

      {/* ── Quote 1 ── */}
      <div style={{background:'rgba(77,159,255,0.06)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:12,padding:'12px 18px',marginBottom:20,fontStyle:'italic',color:'#6B9FDF',fontSize:13}}>
        💎 &quot;{lang==='en'?'Know yourself, improve yourself — your profile is your foundation.':'खुद को जानो, खुद को सुधारो — आपकी प्रोफाइल आपकी नींव है।'}&quot;
      </div>

      {/* ── Tabs Card ── */}
      <div ref={formRef} style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:18,overflow:'hidden',marginBottom:20}}>
        <div style={{display:'flex',gap:4,padding:'12px 16px',borderBottom:`1px solid ${v.bord}`,overflowX:'auto'}}>
          {([
            ['info',    lang==='en'?'Personal':'व्यक्तिगत'],
            ['security',lang==='en'?'Security':'सुरक्षा'],
            ['preferences',lang==='en'?'Preferences':'प्राथमिकताएं'],
          ] as [string,string][]).map(([id,label])=>(
            <button key={id} className={`p-tab ${tab===id?'active':''}`} onClick={()=>setTab(id as any)}>{label}</button>
          ))}
        </div>

        <div style={{padding:24}}>

          {/* ── PERSONAL TAB ── */}
          {tab==='info' && (
            <div style={{display:'flex',flexDirection:'column',gap:20}}>

              {/* Student ID — big read-only display */}
              {studentId && (
                <div>
                  <label className="flbl" style={{color:'#00C48C'}}>🪪 {lang==='en'?'Student ID (Read Only)':'स्टूडेंट आईडी'}</label>
                  <div className="sid-row">
                    <span className="sid-val">{studentId}</span>
                    <button className="sid-copy" onClick={copyId}>{copied?'✓ Copied!':'📋 Copy ID'}</button>
                  </div>
                </div>
              )}

              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(240px,1fr))',gap:16}}>
                <div style={{gridColumn:'1/-1'}}>
                  <label className="flbl">{lang==='en'?'Full Name *':'पूरा नाम *'}</label>
                  <input type="text" value={name} onChange={e=>setName(e.target.value)} className="p-input" placeholder="Your full name"/>
                </div>
                <div>
                  <label className="flbl">{lang==='en'?'Email':'ईमेल'}</label>
                  <input type="email" value={email} onChange={e=>setEmail(e.target.value)} className="p-input" placeholder="email@example.com"/>
                </div>
                <div>
                  <label className="flbl">{lang==='en'?'Mobile Number':'मोबाइल नंबर'}</label>
                  <input type="tel" value={phone} onChange={e=>setPhone(e.target.value)} className="p-input" placeholder="10-digit number"/>
                </div>
                <div>
                  <label className="flbl">{lang==='en'?'Date of Birth':'जन्म तिथि'}</label>
                  <input type="date" value={dob} onChange={e=>setDob(e.target.value)} className="p-input p-select"/>
                </div>
                <div>
                  <label className="flbl">{lang==='en'?'City / State':'शहर / राज्य'}</label>
                  <input type="text" value={city} onChange={e=>setCity(e.target.value)} className="p-input" placeholder="e.g. Delhi, UP"/>
                </div>
              </div>

              {/* Study Information */}
              <div>
                <div style={{fontSize:13,fontWeight:800,color:'#FF6B35',marginBottom:14,display:'flex',alignItems:'center',gap:6}}>
                  🚀 {lang==='en'?'Study Information':'अध्ययन जानकारी'}
                </div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(240px,1fr))',gap:16}}>
                  <div>
                    <label className="flbl">{lang==='en'?'Target Exam':'लक्ष्य परीक्षा'}</label>
                    <select value={targetExam} onChange={e=>setTargetExam(e.target.value)} className="p-select">
                      <option value="NEET">NEET</option>
                      <option value="JEE">JEE</option>
                      <option value="AIIMS">AIIMS</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                  <div>
                    <label className="flbl">{lang==='en'?'Board':'बोर्ड'}</label>
                    <select value={board} onChange={e=>setBoard(e.target.value)} className="p-select">
                      <option value="">Select Board</option>
                      <option value="CBSE">CBSE</option>
                      <option value="ICSE">ICSE</option>
                      <option value="State Board">State Board</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                  <div style={{gridColumn:'1/-1'}}>
                    <label className="flbl">{lang==='en'?'School / College':'स्कूल / कॉलेज'}</label>
                    <input type="text" value={school} onChange={e=>setSchool(e.target.value)} className="p-input" placeholder="Your school or coaching name"/>
                  </div>
                  <div style={{gridColumn:'1/-1'}}>
                    <label className="flbl">{lang==='en'?'Short Bio':'संक्षिप्त परिचय'}</label>
                    <textarea value={bio} onChange={e=>setBio(e.target.value)} className="p-textarea" placeholder="Tell us a little about yourself..."/>
                  </div>
                </div>
              </div>

              <div style={{display:'flex',gap:12,alignItems:'center',paddingTop:4}}>
                <button
                  onClick={handleSave}
                  style={{padding:'13px 32px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif',display:'flex',alignItems:'center',gap:8}}
                >
                  👤 {lang==='en'?'Save Changes':'परिवर्तन सहेजें'}
                </button>
                {saved&&<span style={{color:'#00C48C',fontWeight:700,fontSize:14}}>✓ {lang==='en'?'Saved!':'सहेजा!'}</span>}
              </div>
            </div>
          )}

          {/* ── SECURITY TAB ── */}
          {tab==='security' && (
            <div style={{maxWidth:480,display:'flex',flexDirection:'column',gap:18}}>
              {([
                [lang==='en'?'Current Password':'वर्तमान पासवर्ड', curPass, setCurPass],
                [lang==='en'?'New Password':'नया पासवर्ड', newPass, setNewPass],
                [lang==='en'?'Confirm New Password':'पासवर्ड की पुष्टि', confPass, setConfPass],
              ] as [string,string,any][]).map(([label,val,setter])=>(
                <div key={label}>
                  <label className="flbl">{label}</label>
                  <input type="password" value={val} onChange={e=>setter(e.target.value)} className="p-input" placeholder="••••••••"/>
                </div>
              ))}
              <div style={{display:'flex',gap:12,alignItems:'center'}}>
                <button onClick={handlePassSave} style={{padding:'13px 28px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif',width:'fit-content'}}>
                  {lang==='en'?'Update Password':'पासवर्ड अपडेट करें'}
                </button>
                {passSaved&&<span style={{color:'#00C48C',fontWeight:700,fontSize:14}}>✓ Updated!</span>}
              </div>
            </div>
          )}

          {/* ── PREFERENCES TAB ── */}
          {tab==='preferences' && (
            <div style={{display:'flex',flexDirection:'column',gap:14,maxWidth:520}}>
              {[
                {label:lang==='en'?'Email Notifications':'ईमेल सूचनाएं',sub:lang==='en'?'Receive exam reminders and result alerts':'परीक्षा अनुस्मारक और परिणाम अलर्ट प्राप्त करें',val:emailNotif,set:setEmailNotif},
                {label:lang==='en'?'SMS Notifications':'SMS सूचनाएं',sub:lang==='en'?'Get important updates on mobile':'मोबाइल पर महत्वपूर्ण अपडेट प्राप्त करें',val:smsNotif,set:setSmsNotif},
                {label:lang==='en'?'Show in Leaderboard':'लीडरबोर्ड में दिखाएं',sub:lang==='en'?'Allow your rank to be visible to others':'अपनी रैंक को दूसरों के लिए दृश्यमान बनाएं',val:showLB,set:setShowLB},
              ].map((p,i)=>(
                <div key={i} onClick={()=>p.set(!p.val)} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'14px 18px',background:'rgba(77,159,255,0.05)',border:`1px solid ${v.bord}`,borderRadius:12,cursor:'pointer',userSelect:'none'}}>
                  <div>
                    <div style={{fontWeight:600,fontSize:14,color:v.tm,marginBottom:3}}>{p.label}</div>
                    <div style={{fontSize:12,color:v.ts}}>{p.sub}</div>
                  </div>
                  <div className="toggle" style={{background:p.val?'#4D9FFF':'rgba(77,159,255,0.2)'}}>
                    <div className="toggle-dot" style={{left:p.val?20:3}}/>
                  </div>
                
          {/* 🎨 Color Theme Picker */}
          <div style={{borderTop:'1px solid '+C.border,paddingTop:18,marginTop:6}}>
            <div style={{fontSize:13,fontWeight:700,color:C.primary,marginBottom:14}}>🎨 {t('App Color Theme','ऐप कलर थीम')}</div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:10}}>
              {[
                {id:'white',lbl:'Pure White',bg:'#FFFFFF',acc:'#2563EB',ico:'☀️'},
                {id:'dark', lbl:'Pure Dark', bg:'#0A0A0A',acc:'#4D9FFF',ico:'🌑'},
                {id:'teal', lbl:'Neon Teal',  bg:'linear-gradient(135deg,#001A1A,#002E2E)',acc:'#2DD4BF',ico:'🌊'},
              ].map((th)=>
                <button key={th.id} onClick={()=>applyTheme(th.id as any)}
                  style={{background:th.bg,border:'2px solid '+(activeTheme===th.id?th.acc:'rgba(255,255,255,0.08)'),borderRadius:14,padding:'12px 6px',cursor:'pointer',textAlign:'center',transition:'all .2s',position:'relative',minHeight:82,boxShadow:activeTheme===th.id?('0 0 18px '+th.acc+'55'):'none'}}>
                  {activeTheme===th.id&&<span style={{position:'absolute',top:5,right:7,fontSize:10,color:th.acc,fontWeight:800}}>✓</span>}
                  <div style={{fontSize:20,marginBottom:4}}>{th.ico}</div>
                  <div style={{fontSize:11,fontWeight:700,color:th.acc}}>{th.lbl}</div>
                </button>
              )}
            </div>
            <div style={{fontSize:10,color:C.sub,textAlign:'center',marginTop:8}}>{t('Theme applies to all student pages','थीम सभी पेजों पर लागू')}</div>
          </div>
</div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Login Activity ── */}
      {loginHistory.length > 0 && (
        <div style={{background:v.card,border:`1px solid ${v.bord}`,borderRadius:16,padding:20,marginBottom:20}}>
          <div style={{fontWeight:700,fontSize:14,color:v.tm,marginBottom:14,display:'flex',alignItems:'center',gap:8}}>
            🕐 {lang==='en'?'Recent Login Activity':'हाल की लॉगिन गतिविधि'}
            <span style={{fontSize:12,color:'#6B8BAF',fontWeight:400,marginLeft:4}}>({loginHistory.length} {lang==='en'?'sessions':'सेशन'})</span>
          </div>
          <div style={{display:'flex',flexDirection:'column',gap:8}}>
            {[...loginHistory].reverse().slice(0,5).map((log: any,i: number)=>(
              <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 14px',background:'rgba(77,159,255,0.04)',borderRadius:10,fontSize:12,color:v.ts,flexWrap:'wrap',gap:8}}>
                <span style={{color:'#FF6B7A',marginRight:4,fontSize:10}}>●</span>
                <span style={{flex:1,minWidth:160,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{log.userAgent||'Unknown · Browser'}</span>
                <span style={{color:'#4D9FFF',flexShrink:0}}>{log.createdAt ? new Date(log.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit'}) : '—'}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── Bottom Quote ── */}
      <div style={{background:'rgba(77,159,255,0.05)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:14,padding:'16px 20px',display:'flex',gap:14,alignItems:'flex-start'}}>
        <div style={{fontSize:24,flexShrink:0}}>⭐</div>
        <div>
          <div style={{fontStyle:'italic',color:'#6B9FDF',fontSize:13,fontWeight:600,marginBottom:4}}>
            &quot;{lang==='en'?'Your profile reflects your dedication — keep it complete and updated!':'आपकी प्रोफाइल आपकी मेहनत को दर्शाती है — इसे पूर्ण और अपडेट रखें!'}&quot;
          </div>
          <div style={{fontSize:11,color:'#6B8BAF'}}>{lang==='en'?'Complete profiles get better personalized recommendations.':'पूर्ण प्रोफाइल बेहतर व्यक्तिगत सुझाव देती हैं।'}</div>
        </div>
      </div>

    </DashLayout>
  )
}
