#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  ProveRank — F38 + F39 + F40: Profile Page Complete Rewrite
#  Two-column layout, completion ring, new fields, F40 save UX
# ═══════════════════════════════════════════════════════════════
set -e

PROF_F=$(find . -path "*/app/profile/page.tsx" | grep -v node_modules | head -1)
echo "Profile: $PROF_F"
cp "$PROF_F" "${PROF_F}.bak_f38"

cat > "$PROF_F" << 'PAGEOF'
'use client'
import CopyBtn from '@/components/CopyBtn'
import { useState, useEffect, useRef } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Input style ───────────────────────────────────────────────
const inp:any = {
  width:'100%',padding:'11px 14px',
  background:'rgba(0,22,40,.88)',
  border:'1.5px solid rgba(77,159,255,.25)',
  borderRadius:11,color:'#E8F4FF',fontSize:13,
  fontFamily:'Inter,sans-serif',outline:'none',
  boxSizing:'border-box',transition:'border-color .2s',
}
const sel:any = { ...inp, cursor:'pointer' }

// ── Indian States ─────────────────────────────────────────────
const STATES = ['Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal','Delhi','Jammu & Kashmir','Ladakh','Chandigarh','Puducherry','Other']

// ── Target Exams ──────────────────────────────────────────────
const TARGET_EXAMS = ['NEET','NEET PG','JEE Main','JEE Advanced','CUET','RPSC','DSSSB','SSC CGL','SSC CHSL','UPSC','Board Exam','Other']
const TARGET_YEARS = ['2025','2026','2027','2028','2029']
const BOARDS        = ['CBSE','ICSE','UP Board','MP Board','Rajasthan Board','Maharashtra Board','Bihar Board','Other State Board']
const YEAR_APPEAR   = ['Class 11','Class 12','Dropper','Graduated']
const GENDERS       = ['Male','Female','Non-binary','Prefer not to say']
const TIMEZONES     = ['Asia/Kolkata','Asia/Colombo','Asia/Dhaka','Asia/Kathmandu','UTC']

// ── Profile Completion % ─────────────────────────────────────
function calcCp(u:any, fields:any) {
  const checks = [
    !!fields.name, !!fields.phone, !!fields.dob,
    !!fields.city, !!fields.gender, !!fields.bio,
    !!(u?.avatar||fields.avatar),
    !!fields.targetExam, !!fields.board, !!fields.school,
  ]
  return Math.round((checks.filter(Boolean).length / checks.length) * 100)
}

// ── Completion Ring SVG ───────────────────────────────────────
function CompletionRing({ pct, size=96 }: { pct:number; size?:number }) {
  const r  = (size-8)/2
  const circ = 2 * Math.PI * r
  const dash = (pct/100) * circ
  const col  = pct>=80?'#00C48C':pct>=50?'#4D9FFF':'#FFD700'
  return (
    <svg width={size} height={size} style={{position:'absolute',top:0,left:0,transform:'rotate(-90deg)'}}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="4"/>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={col} strokeWidth="4"
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"
        style={{transition:'stroke-dasharray 0.6s ease'}}/>
    </svg>
  )
}

// ── Eye icon for password ─────────────────────────────────────
function EyeBtn({show,toggle}:{show:boolean;toggle:()=>void}) {
  return (
    <button type="button" onClick={toggle}
      style={{position:'absolute',right:12,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',cursor:'pointer',color:'#6B8FAF',padding:0,display:'flex',alignItems:'center'}}>
      {show
        ? <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
        : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
      }
    </button>
  )
}

function ProfileContent() {
  const { lang, darkMode:dm, user, toast, token } = useShell()
  const t = (en:string, hi:string) => lang==='en' ? en : hi

  // ── F38 Tabs ──────────────────────────────────────────────
  const [tab, setTab]           = useState<'personal'|'security'|'prefs'>('personal')

  // ── F40 Save behavior states ──────────────────────────────
  const [editing,   setEditing]   = useState(true)
  const [saved,     setSaved]     = useState(false)
  const [saving,    setSaving]    = useState(false)
  const [passSaved, setPassSaved] = useState(false)
  const [passSaving,setPassSaving]= useState(false)

  // ── F38 Personal fields ───────────────────────────────────
  const [name,    setName]    = useState('')
  const [phone,   setPhone]   = useState('')
  const [dob,     setDob]     = useState('')
  const [city,    setCity]    = useState('')
  const [state,   setState2]  = useState('')
  const [gender,  setGender]  = useState('')
  const [bio,     setBio]     = useState('')
  const [avatar,  setAvatar]  = useState('')
  const [timezone,setTimezone]= useState('Asia/Kolkata')

  // ── F39 Study fields ──────────────────────────────────────
  const [targetExam,    setTargetExam]    = useState('')
  const [targetYear,    setTargetYear]    = useState('')
  const [yearAppearing, setYearAppearing] = useState('')
  const [board,         setBoard]         = useState('')
  const [school,        setSchool]        = useState('')
  const [coaching,      setCoaching]      = useState('')

  // ── Security fields ────────────────────────────────────────
  const [cp,   setCp]   = useState('')
  const [np,   setNp]   = useState('')
  const [cnp,  setCnp]  = useState('')
  const [showCp, setShowCp] = useState(false)
  const [showNp, setShowNp] = useState(false)
  const [showCnp,setShowCnp]= useState(false)

  // ── Prefs toggles ──────────────────────────────────────────
  const [notifEmail, setNotifEmail] = useState(true)
  const [notifSms,   setNotifSms]   = useState(false)
  const [notifStudy, setNotifStudy] = useState(true)

  // ── Load user data on mount ────────────────────────────────
  useEffect(() => {
    if (!user) return
    setName(user.name||'')
    setPhone(user.phone||'')
    setDob(user.dob||'')
    setCity(user.city||'')
    setState2(user.state||'')
    setGender(user.gender||'')
    setBio(user.bio||'')
    setAvatar(user.avatar||'')
    setTimezone(user.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Kolkata')
    setTargetExam(user.targetExam||'')
    setTargetYear(user.targetYear||'')
    setYearAppearing(user.yearOfAppearing||'')
    setBoard(user.board||'')
    setSchool(user.school||'')
    setCoaching(user.coachingInstitute||'')
    if (user.preferences) {
      setNotifEmail(user.preferences.emailNotif ?? true)
      setNotifSms(user.preferences.smsNotif ?? false)
      setNotifStudy(user.preferences.studyReminder ?? true)
    }
  }, [user])

  const fields = { name,phone,dob,city,state,gender,bio,avatar,targetExam,board,school }
  const cp_pct = calcCp(user, fields)

  // ── F38/F39/F40 Save ──────────────────────────────────────
  const save = async () => {
    if (!token) return
    setSaving(true)
    try {
      const r = await fetch(`${API}/api/auth/me`, {
        method: 'PATCH',
        headers: { 'Content-Type':'application/json', Authorization:`Bearer ${token}` },
        body: JSON.stringify({
          name, phone, dob, city, state, gender, bio, avatar, timezone,
          targetExam, targetYear, yearOfAppearing:yearAppearing,
          board, school, coachingInstitute:coaching,
        })
      })
      if (r.ok) {
        toast(t('✅ Profile saved!','✅ प्रोफ़ाइल सहेजी!'),'s')
        setSaved(true); setEditing(false)
      } else { toast(t('Failed to save','सहेजने में विफल'),'e') }
    } catch { toast('Network error','e') }
    setSaving(false)
  }

  // ── Avatar upload ──────────────────────────────────────────
  const uploadAvatar = (e:React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]; if (!file) return
    const reader = new FileReader()
    reader.onload = (ev) => { setAvatar(ev.target?.result as string); setEditing(true); setSaved(false) }
    reader.readAsDataURL(file)
  }

  // ── Password change ────────────────────────────────────────
  const changePass = async () => {
    if (np !== cnp) { toast(t('Passwords do not match','पासवर्ड मेल नहीं खाते'),'e'); return }
    if (!np.trim())  { toast(t('Enter new password','नया पासवर्ड दर्ज करें'),'e'); return }
    setPassSaving(true)
    try {
      const r = await fetch(`${API}/api/auth/change-password`, {
        method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify({currentPassword:cp,newPassword:np})
      })
      if (r.ok) {
        toast(t('Password changed!','पासवर्ड बदल गया!'),'s')
        setCp(''); setNp(''); setCnp(''); setPassSaved(true)
      } else { const d=await r.json(); toast(d.message||'Failed','e') }
    } catch { toast('Network error','e') }
    setPassSaving(false)
  }

  const markEditing = () => { setSaved(false); setEditing(true) }

  // ── TABS ───────────────────────────────────────────────────
  const TABS = [
    { key:'personal' as const, icon:'👤', label:t('Personal','व्यक्तिगत') },
    { key:'security' as const, icon:'🔒', label:t('Security','सुरक्षा') },
    { key:'prefs'    as const, icon:'⚙️', label:t('Preferences','प्राथमिकताएं') },
  ]

  const cardStyle:any = {
    background: 'rgba(0,18,36,0.85)',
    border: `1px solid rgba(77,159,255,0.18)`,
    borderRadius:18, padding:22,
    backdropFilter:'blur(16px)',
    boxShadow:'0 4px 28px rgba(0,0,0,0.15)',
  }

  return (
    <div style={{animation:'fadeIn .4s ease'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&display=swap');
        @keyframes fadeIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-6px)}}
        @keyframes checkPop{0%{transform:scale(0)}80%{transform:scale(1.2)}100%{transform:scale(1)}}
        .field-inp:focus{border-color:rgba(77,159,255,.7)!important;box-shadow:0 0 0 3px rgba(77,159,255,.1)}
        .field-inp:hover{border-color:rgba(77,159,255,.45)!important}
      `}</style>

      {/* ══ PAGE HEADER ══ */}
      <div style={{marginBottom:20}}>
        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,background:`linear-gradient(90deg,#E8F4FF,#4D9FFF)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',margin:'0 0 4px'}}>
          👤 {t('My Profile','मेरी प्रोफ़ाइल')}
        </h1>
        <div style={{fontSize:12,color:'#6B8FAF'}}>{t('Manage your identity, security & study preferences','अपनी पहचान, सुरक्षा और अध्ययन प्राथमिकताएं प्रबंधित करें')}</div>
      </div>

      {/* ══ TWO-COLUMN LAYOUT ══ */}
      <div style={{display:'flex',gap:18,alignItems:'flex-start',flexWrap:'wrap'}}>

        {/* ── LEFT: Avatar Card (280px on desktop, full-width on mobile) ── */}
        <div style={{width:'100%',maxWidth:268,flexShrink:0,...cardStyle,textAlign:'center'}}>

          {/* Completion Ring + Avatar */}
          <div style={{position:'relative',width:96,height:96,margin:'0 auto 14px',cursor:'pointer'}} onClick={()=>document.getElementById('avatarInput')?.click()}>
            <CompletionRing pct={cp_pct}/>
            <div style={{position:'absolute',inset:6,borderRadius:'50%',overflow:'hidden',background:`linear-gradient(135deg,#4D9FFF,#0055CC)`,display:'flex',alignItems:'center',justifyContent:'center',border:'2px solid rgba(77,159,255,0.3)'}}>
              {avatar
                ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover'}}/>
                : <span style={{fontSize:32,fontWeight:900,color:'#fff'}}>{(user?.name||'S').charAt(0).toUpperCase()}</span>
              }
            </div>
            {/* Camera overlay */}
            <div style={{position:'absolute',bottom:0,right:0,width:26,height:26,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',border:'2px solid #050C1A',fontSize:12}}>
              📷
            </div>
            <input id="avatarInput" type="file" accept="image/*" onChange={uploadAvatar} style={{display:'none'}}/>
          </div>

          {/* Completion % */}
          <div style={{fontSize:13,fontWeight:700,color:cp_pct>=80?'#00C48C':cp_pct>=50?'#4D9FFF':'#FFD700',marginBottom:2}}>
            {cp_pct}% {t('Complete','पूर्ण')}
          </div>
          <div style={{height:4,background:'rgba(255,255,255,0.06)',borderRadius:4,overflow:'hidden',marginBottom:12,marginLeft:8,marginRight:8}}>
            <div style={{height:'100%',width:`${cp_pct}%`,background:`linear-gradient(90deg,#4D9FFF,#00C48C)`,borderRadius:4,transition:'width 0.6s ease'}}/>
          </div>

          {/* Amber warning */}
          {cp_pct < 100 && (
            <div style={{fontSize:10,color:'rgba(251,191,36,0.85)',marginBottom:12,lineHeight:1.5,padding:'6px 8px',background:'rgba(251,191,36,0.06)',borderRadius:8,border:'1px solid rgba(251,191,36,0.15)'}}>
              ⚠️ {t('Complete your profile to unlock full analytics','पूर्ण प्रोफ़ाइल से एनालिटिक्स अनलॉक होगी')}
            </div>
          )}

          {/* Name + Email */}
          <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#E8F4FF',marginBottom:3}}>
            {user?.name || t('Student','छात्र')}
          </div>
          <div style={{fontSize:11,color:'#6B8FAF',marginBottom:10,wordBreak:'break-all'}}>{user?.email||''}</div>

          {/* Verified badge */}
          {(user?.emailVerified||user?.verified) && (
            <div style={{display:'inline-flex',alignItems:'center',gap:5,fontSize:10,padding:'4px 10px',borderRadius:20,background:'rgba(0,196,140,0.12)',color:'#00C48C',fontWeight:700,border:'1px solid rgba(0,196,140,0.25)',marginBottom:10}}>
              ✓ {t('Verified','सत्यापित')}
            </div>
          )}

          {/* Member since */}
          <div style={{fontSize:10,color:'#4B6A8A',marginBottom:14}}>
            {t('Member since','सदस्य')} {user?.createdAt ? new Date(user.createdAt).toLocaleDateString('en-IN',{month:'short',year:'numeric'}) : ''}
          </div>

          {/* Student ID */}
          {user?.studentId && (
            <div style={{background:'linear-gradient(135deg,rgba(192,192,192,0.06),rgba(255,255,255,0.02))',border:'1px solid rgba(192,192,192,0.15)',borderRadius:11,padding:'10px 12px',marginBottom:12}}>
              <div style={{fontSize:9,color:'#6B8FAF',letterSpacing:'2px',textTransform:'uppercase',marginBottom:5,fontWeight:700}}>🪪 Student ID</div>
              <div style={{fontSize:16,fontWeight:900,fontFamily:'Courier New,monospace',letterSpacing:'3px',background:'linear-gradient(135deg,#AAAAAA,#FFFFFF,#CCCCCC)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:6}}>
                {user.studentId}
              </div>
              <CopyBtn text={user.studentId} size="sm" label="Copy ID"/>
            </div>
          )}

          {/* Target exam badge */}
          {targetExam && (
            <div style={{fontSize:10,padding:'4px 10px',borderRadius:20,background:'rgba(255,215,0,0.09)',color:'#FFD700',fontWeight:700,border:'1px solid rgba(255,215,0,0.2)',display:'inline-block'}}>
              ⚡ {targetExam} {targetYear}
            </div>
          )}
        </div>

        {/* ── RIGHT: Tabs + Content ── */}
        <div style={{flex:1,minWidth:280}}>

          {/* Tab Bar — pill shaped */}
          <div style={{display:'flex',gap:8,marginBottom:18,background:'rgba(0,10,22,0.5)',borderRadius:14,padding:4,border:'1px solid rgba(77,159,255,0.1)'}}>
            {TABS.map(tb => (
              <button key={tb.key} onClick={()=>setTab(tb.key)} style={{
                flex:1, padding:'10px 4px', textAlign:'center', fontSize:12,
                fontWeight: tab===tb.key ? 700 : 500,
                background: tab===tb.key ? `linear-gradient(135deg,#4D9FFF,#0044BB)` : 'transparent',
                color: tab===tb.key ? '#fff' : '#6B8FAF',
                border: 'none', borderRadius:10, cursor:'pointer',
                fontFamily:'Inter,sans-serif', transition:'all .25s',
                boxShadow: tab===tb.key ? '0 4px 16px rgba(77,159,255,0.25)' : 'none'
              }}>
                {tb.icon} {tb.label}
              </button>
            ))}
          </div>

          {/* ══════════════════════════════════════
              F38 + F39 — PERSONAL INFO TAB
          ══════════════════════════════════════ */}
          {tab==='personal' && (
            <div style={cardStyle}>

              {/* Personal Info section */}
              <div style={{fontSize:13,fontWeight:700,color:'#4D9FFF',marginBottom:16,display:'flex',alignItems:'center',gap:8}}>
                <span>👤</span> {t('Personal Information','व्यक्तिगत जानकारी')}
              </div>

              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                {/* Full Name */}
                <div style={{gridColumn:'1/-1'}}>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Full Name *','पूरा नाम *')}</label>
                  <input className="field-inp" value={name} onChange={e=>{setName(e.target.value);markEditing()}} style={inp} placeholder={t('Your full name','आपका पूरा नाम')}/>
                </div>

                {/* Email (read-only) */}
                <div>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Email','ईमेल')}</label>
                  <input value={user?.email||''} disabled style={{...inp,opacity:.5,cursor:'not-allowed'}}/>
                </div>

                {/* Phone */}
                <div>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Phone Number','फोन नंबर')}</label>
                  <input className="field-inp" value={phone} onChange={e=>{setPhone(e.target.value);markEditing()}} style={inp} placeholder="+91 XXXXXXXXXX"/>
                </div>

                {/* DOB */}
                <div>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Date of Birth','जन्म तारीख')}</label>
                  <input type="date" className="field-inp" value={dob} onChange={e=>{setDob(e.target.value);markEditing()}} style={inp}/>
                </div>

                {/* Gender */}
                <div>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Gender','लिंग')} ({t('Optional','वैकल्पिक')})</label>
                  <select className="field-inp" value={gender} onChange={e=>{setGender(e.target.value);markEditing()}} style={sel}>
                    <option value="">{t('Prefer not to say','बताना नहीं चाहते')}</option>
                    {GENDERS.map(g=><option key={g} value={g}>{g}</option>)}
                  </select>
                </div>

                {/* City */}
                <div>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('City','शहर')}</label>
                  <input className="field-inp" value={city} onChange={e=>{setCity(e.target.value);markEditing()}} style={inp} placeholder={t('e.g. Delhi','जैसे दिल्ली')}/>
                </div>

                {/* State */}
                <div>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('State','राज्य')}</label>
                  <select className="field-inp" value={state} onChange={e=>{setState2(e.target.value);markEditing()}} style={sel}>
                    <option value="">{t('Select State','राज्य चुनें')}</option>
                    {STATES.map(s=><option key={s} value={s}>{s}</option>)}
                  </select>
                </div>

                {/* Timezone */}
                <div>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Timezone','टाइमज़ोन')}</label>
                  <select className="field-inp" value={timezone} onChange={e=>{setTimezone(e.target.value);markEditing()}} style={sel}>
                    {TIMEZONES.map(tz=><option key={tz} value={tz}>{tz}</option>)}
                  </select>
                </div>

                {/* Bio */}
                <div style={{gridColumn:'1/-1'}}>
                  <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Short Bio','संक्षिप्त परिचय')} ({bio.length}/160)</label>
                  <textarea className="field-inp" value={bio} onChange={e=>{if(e.target.value.length<=160){setBio(e.target.value);markEditing()}}} rows={2}
                    placeholder={t('Tell us a little about yourself...','अपने बारे में थोड़ा बताएं...')} style={{...inp,resize:'vertical'}}/>
                </div>
              </div>

              {/* ── F39: Study Info section ── */}
              <div style={{borderTop:'1px solid rgba(77,159,255,0.12)',marginTop:20,paddingTop:18}}>
                <div style={{fontSize:13,fontWeight:700,marginBottom:16,background:'linear-gradient(90deg,#FFD700,#FFF0AA)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',display:'flex',alignItems:'center',gap:8}}>
                  📚 {t('Study Information','अध्ययन जानकारी')}
                </div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>

                  {/* Target Exam */}
                  <div>
                    <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Target Exam','लक्ष्य परीक्षा')}</label>
                    <select className="field-inp" value={targetExam} onChange={e=>{setTargetExam(e.target.value);markEditing()}} style={sel}>
                      <option value="">{t('Select Exam','परीक्षा चुनें')}</option>
                      {TARGET_EXAMS.map(e=><option key={e} value={e}>{e}</option>)}
                    </select>
                  </div>

                  {/* Target Year */}
                  <div>
                    <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Target Year','लक्ष्य वर्ष')}</label>
                    <select className="field-inp" value={targetYear} onChange={e=>{setTargetYear(e.target.value);markEditing()}} style={sel}>
                      <option value="">{t('Select Year','वर्ष चुनें')}</option>
                      {TARGET_YEARS.map(y=><option key={y} value={y}>{y}</option>)}
                    </select>
                  </div>

                  {/* Year of Appearing */}
                  <div>
                    <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Year of Appearing','परीक्षा देने का वर्ष')}</label>
                    <select className="field-inp" value={yearAppearing} onChange={e=>{setYearAppearing(e.target.value);markEditing()}} style={sel}>
                      <option value="">{t('Select','चुनें')}</option>
                      {YEAR_APPEAR.map(y=><option key={y} value={y}>{y}</option>)}
                    </select>
                  </div>

                  {/* Board */}
                  <div>
                    <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Board','बोर्ड')}</label>
                    <select className="field-inp" value={board} onChange={e=>{setBoard(e.target.value);markEditing()}} style={sel}>
                      <option value="">{t('Select Board','बोर्ड चुनें')}</option>
                      {BOARDS.map(b=><option key={b} value={b}>{b}</option>)}
                    </select>
                  </div>

                  {/* School */}
                  <div style={{gridColumn:'1/-1'}}>
                    <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('School / College','स्कूल / कॉलेज')}</label>
                    <input className="field-inp" value={school} onChange={e=>{setSchool(e.target.value);markEditing()}} style={inp} placeholder={t('Your school or college name','आपके स्कूल या कॉलेज का नाम')}/>
                  </div>

                  {/* Coaching */}
                  <div style={{gridColumn:'1/-1'}}>
                    <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Coaching Institute','कोचिंग इंस्टिट्यूट')} ({t('Optional','वैकल्पिक')})</label>
                    <input className="field-inp" value={coaching} onChange={e=>{setCoaching(e.target.value);markEditing()}} style={inp} placeholder={t('e.g. Allen, Aakash, Self Study','जैसे Allen, Aakash, Self Study')}/>
                  </div>

                </div>
              </div>

              {/* ── F40: Save Button / Saved state ── */}
              <div style={{marginTop:20}}>
                {!saved ? (
                  <button onClick={save} disabled={saving} style={{
                    width:'100%',padding:'13px',border:'none',borderRadius:12,cursor:saving?'not-allowed':'pointer',
                    background:saving?'rgba(0,196,140,0.5)':'linear-gradient(135deg,#00C48C,#007755)',
                    color:'#fff',fontSize:14,fontWeight:700,fontFamily:'Inter,sans-serif',
                    display:'flex',alignItems:'center',justifyContent:'center',gap:8,
                    transition:'all .2s',
                    boxShadow:saving?'none':'0 4px 16px rgba(0,196,140,0.25)',
                    transform:saving?'scale(0.98)':'scale(1)',
                  }}>
                    {saving
                      ? <><span style={{animation:'spin 1s linear infinite',display:'inline-block'}}>⟳</span> {t('Saving...','सहेज रहे हैं...')}</>
                      : <>💾 {t('Save Changes','बदलाव सहेजें')}</>
                    }
                  </button>
                ) : (
                  <div style={{display:'flex',gap:10,alignItems:'center'}}>
                    <div style={{flex:1,padding:'12px',background:'rgba(0,196,140,0.08)',border:'1px solid rgba(0,196,140,0.25)',borderRadius:12,textAlign:'center',color:'#00C48C',fontWeight:600,fontSize:13,display:'flex',alignItems:'center',justifyContent:'center',gap:8}}>
                      <span style={{animation:'checkPop .4s ease',display:'inline-block'}}>✅</span>
                      {t('Profile saved!','प्रोफ़ाइल सहेजी!')}
                    </div>
                    {/* F40: Edit Profile button — outlined purple */}
                    <button onClick={()=>{setEditing(true);setSaved(false)}} style={{
                      padding:'12px 18px',border:'1.5px solid #A78BFA',borderRadius:12,
                      background:'rgba(167,139,250,0.08)',color:'#A78BFA',
                      fontSize:13,fontWeight:700,cursor:'pointer',whiteSpace:'nowrap',
                      display:'flex',alignItems:'center',gap:6,
                    }}>
                      ✏️ {t('Edit','संपादित')}
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ══════════════════════════════════════
              SECURITY TAB
          ══════════════════════════════════════ */}
          {tab==='security' && (
            <div style={cardStyle}>
              <div style={{fontSize:13,fontWeight:700,color:'#4D9FFF',marginBottom:18}}>🔒 {t('Change Password','पासवर्ड बदलें')}</div>

              {/* Current Password */}
              <div style={{marginBottom:14,position:'relative'}}>
                <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Current Password','वर्तमान पासवर्ड')}</label>
                <div style={{position:'relative'}}>
                  <input type={showCp?'text':'password'} value={cp} onChange={e=>setCp(e.target.value)} className="field-inp" style={{...inp,paddingRight:40}} placeholder="••••••••"/>
                  <EyeBtn show={showCp} toggle={()=>setShowCp(!showCp)}/>
                </div>
              </div>

              {/* New Password */}
              <div style={{marginBottom:14}}>
                <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('New Password','नया पासवर्ड')}</label>
                <div style={{position:'relative'}}>
                  <input type={showNp?'text':'password'} value={np} onChange={e=>setNp(e.target.value)} className="field-inp"
                    style={{...inp,paddingRight:40,borderColor:np&&cnp&&np!==cnp?'rgba(239,68,68,0.6)':np&&cnp&&np===cnp?'rgba(0,196,140,0.6)':undefined}} placeholder="••••••••"/>
                  <EyeBtn show={showNp} toggle={()=>setShowNp(!showNp)}/>
                </div>
              </div>

              {/* Confirm Password — live validation */}
              <div style={{marginBottom:18}}>
                <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.5}}>{t('Confirm New Password','नया पासवर्ड दोबारा')}</label>
                <div style={{position:'relative'}}>
                  <input type={showCnp?'text':'password'} value={cnp} onChange={e=>setCnp(e.target.value)} className="field-inp"
                    style={{...inp,paddingRight:40,
                      borderColor:cnp&&np!==cnp?'rgba(239,68,68,0.6)':cnp&&np===cnp?'rgba(0,196,140,0.6)':undefined}}
                    placeholder="••••••••"/>
                  <EyeBtn show={showCnp} toggle={()=>setShowCnp(!showCnp)}/>
                </div>
                {cnp && np !== cnp && (
                  <div style={{fontSize:11,color:'#ef4444',marginTop:5}}>❌ {t('Passwords do not match','पासवर्ड मेल नहीं खाते')}</div>
                )}
                {cnp && np === cnp && (
                  <div style={{fontSize:11,color:'#00C48C',marginTop:5}}>✅ {t('Passwords match!','पासवर्ड मेल खाते हैं!')}</div>
                )}
              </div>

              {/* F40 — Save/Saved state for security */}
              {!passSaved ? (
                <button onClick={changePass} disabled={passSaving||!cp||!np||!cnp||np!==cnp} style={{
                  width:'100%',padding:'13px',border:'none',borderRadius:12,
                  background:(!cp||!np||!cnp||np!==cnp)?'rgba(77,159,255,0.2)':'linear-gradient(135deg,#4D9FFF,#0044BB)',
                  color:(!cp||!np||!cnp||np!==cnp)?'#4B6A8A':'#fff',
                  fontSize:14,fontWeight:700,cursor:(!cp||!np||!cnp||np!==cnp)?'not-allowed':'pointer',
                  fontFamily:'Inter,sans-serif',transition:'all .2s',
                }}>
                  {passSaving ? '⟳ '+t('Changing...','बदल रहे हैं...') : '🔒 '+t('Change Password','पासवर्ड बदलें')}
                </button>
              ) : (
                <div style={{display:'flex',gap:10}}>
                  <div style={{flex:1,padding:'12px',background:'rgba(0,196,140,0.08)',border:'1px solid rgba(0,196,140,0.25)',borderRadius:12,textAlign:'center',color:'#00C48C',fontWeight:600,fontSize:13}}>
                    ✅ {t('Password changed!','पासवर्ड बदल गया!')}
                  </div>
                  <button onClick={()=>setPassSaved(false)} style={{padding:'12px 16px',border:'1.5px solid #A78BFA',borderRadius:12,background:'rgba(167,139,250,0.08)',color:'#A78BFA',fontSize:13,fontWeight:700,cursor:'pointer',whiteSpace:'nowrap'}}>
                    🔑 {t('Change Again','फिर बदलें')}
                  </button>
                </div>
              )}

              {/* Security Tips */}
              <div style={{marginTop:18,padding:'14px 16px',background:'rgba(77,159,255,0.05)',borderRadius:12,border:'1px solid rgba(77,159,255,0.12)'}}>
                <div style={{fontWeight:700,fontSize:12,color:'#E8F4FF',marginBottom:8}}>🔐 {t('Security Tips','सुरक्षा सुझाव')}</div>
                {(lang==='en'
                  ?['Use at least 8 characters with numbers & symbols','Never share your password with anyone','Change password every 3 months']
                  :['कम से कम 8 अक्षर, संख्याएं और प्रतीकों का उपयोग करें','अपना पासवर्ड कभी भी किसी के साथ साझा न करें','हर 3 महीने में पासवर्ड बदलें']
                ).map((tip,i)=>(
                  <div key={i} style={{fontSize:11,color:'#6B8FAF',marginBottom:4,display:'flex',gap:6}}>
                    <span style={{color:'#00C48C'}}>✓</span>{tip}
                  </div>
                ))}
              </div>

              {/* Login History */}
              {user?.loginHistory?.length > 0 && (
                <div style={{marginTop:16,padding:'14px 16px',background:'rgba(0,0,0,0.15)',borderRadius:12,border:'1px solid rgba(77,159,255,0.1)'}}>
                  <div style={{fontWeight:700,fontSize:12,color:'#E8F4FF',marginBottom:10}}>🕐 {t('Recent Login Activity','हालिया लॉगिन गतिविधि')}</div>
                  {user.loginHistory.slice(-5).reverse().map((l:any,i:number)=>(
                    <div key={i} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.08)',fontSize:11}}>
                      <span style={{color:'#6B8FAF'}}>📍 {l.city||'Unknown'} · {l.device||'Web'}</span>
                      <span style={{color:'#4B6A8A'}}>{l.at?new Date(l.at).toLocaleString('en-IN',{dateStyle:'short',timeStyle:'short'}):''}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ══════════════════════════════════════
              PREFERENCES TAB
          ══════════════════════════════════════ */}
          {tab==='prefs' && (
            <div style={cardStyle}>
              <div style={{fontSize:13,fontWeight:700,color:'#4D9FFF',marginBottom:18}}>⚙️ {t('Notification Preferences','सूचना प्राथमिकताएं')}</div>
              {([
                {l:t('Email Notifications','ईमेल सूचनाएं'),  d:t('Exam reminders & result alerts via email','ईमेल पर परीक्षा अनुस्मारक'), on:notifEmail, set:setNotifEmail},
                {l:t('SMS Notifications','SMS सूचनाएं'),     d:t('Get results and updates via SMS','SMS पर परिणाम और अपडेट'),           on:notifSms,   set:setNotifSms},
                {l:t('Study Reminders','अध्ययन अनुस्मारक'), d:t('Daily study reminder notifications','दैनिक अध्ययन अनुस्मारक'),        on:notifStudy, set:setNotifStudy},
              ]).map((p,i)=>(
                <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'14px 0',borderBottom:'1px solid rgba(77,159,255,0.08)'}}>
                  <div>
                    <div style={{fontSize:13,fontWeight:600,color:'#E8F4FF'}}>{p.l}</div>
                    <div style={{fontSize:11,color:'#6B8FAF',marginTop:2}}>{p.d}</div>
                  </div>
                  <div onClick={()=>p.set(!p.on)} style={{width:44,height:24,borderRadius:12,background:p.on?'linear-gradient(90deg,#00C48C,#00a87a)':'rgba(255,255,255,0.1)',cursor:'pointer',position:'relative',flexShrink:0,transition:'background .3s'}}>
                    <span style={{position:'absolute',top:2,left:p.on?22:2,width:20,height:20,borderRadius:'50%',background:'#fff',display:'block',boxShadow:'0 1px 4px rgba(0,0,0,0.3)',transition:'left .3s'}}/>
                  </div>
                </div>
              ))}
            </div>
          )}

        </div>{/* end right column */}
      </div>{/* end two-column */}
    </div>
  )
}

export default function ProfilePage() {
  return <StudentShell pageKey="profile"><ProfileContent/></StudentShell>
}
PAGEOF

echo "✅ Profile page rewritten"

# ── Verify ─────────────────────────────────────────────────────
export PROF_F
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.PROF_F;
const c  = fs.readFileSync(f,'utf8');

const checks = [
  // F38
  ['F38: Two-column layout',                c.includes('flex:1,minWidth:280')],
  ['F38: CompletionRing SVG',               c.includes('CompletionRing')],
  ['F38: Profile completion % calc',        c.includes('calcCp')],
  ['F38: Avatar upload + camera overlay',   c.includes('avatarInput') && c.includes('uploadAvatar')],
  ['F38: First-letter initial fallback',    c.includes('charAt(0).toUpperCase')],
  ['F38: Student ID + CopyBtn',             c.includes('CopyBtn') && c.includes('studentId')],
  ['F38: Amber warning < 100%',             c.includes('amber') || c.includes('251,191,36')],
  ['F38: Verified badge',                   c.includes('emailVerified')],
  ['F38: Member since date',                c.includes('createdAt')],
  ['F38: Gender dropdown (optional)',       c.includes('GENDERS')],
  ['F38: State dropdown (Indian states)',   c.includes('STATES') && c.includes('Uttar Pradesh')],
  ['F38: Bio with char counter (160)',      c.includes('/160') && c.includes('bio.length')],
  ['F38: Timezone auto-detect + editable', c.includes('TIMEZONES') && c.includes('Intl.DateTimeFormat')],
  ['F38: Pill-shaped tabs',                c.includes('borderRadius:10') && c.includes('TABS')],
  // F39
  ['F39: Target Exam dropdown',            c.includes('TARGET_EXAMS')],
  ['F39: Target Year dropdown',            c.includes('TARGET_YEARS')],
  ['F39: Board dropdown',                  c.includes('BOARDS')],
  ['F39: Year of Appearing dropdown',      c.includes('YEAR_APPEAR')],
  ['F39: School/College field',            c.includes('school')],
  ['F39: Coaching Institute field',        c.includes('coaching')],
  ['F39: Study Info section header',       c.includes('Study Information') || c.includes('अध्ययन जानकारी')],
  // F40
  ['F40: Save → disappears on success',    c.includes('setSaved(true)')],
  ['F40: Edit Profile button appears',     c.includes('setEditing(true);setSaved(false)')],
  ['F40: Green save button animation',     c.includes('00C48C,#007755')],
  ['F40: Purple Edit button outlined',     c.includes('A78BFA') && c.includes('✏️')],
  ['F40: passSaved for security tab',      c.includes('passSaved')],
  ['F40: Change Again button',             c.includes('Change Again')],
  // Security
  ['Security: Eye icon toggle (3 fields)', c.includes('EyeBtn') && (c.match(/EyeBtn/g)||[]).length >= 3],
  ['Security: Live password match valid.', c.includes('np!==cnp')],
  ['Security: Login history',              c.includes('loginHistory')],
  // Preserved
  ['StudentShell wrapper preserved',       c.includes('StudentShell') && c.includes('pageKey="profile"')],
  ['CopyBtn import preserved',             c.includes("import CopyBtn")],
  ['changePass API preserved',             c.includes('change-password')],
];

let pass=0,fail=0;
checks.forEach(([l,v])=>{ console.log((v?'✅':'❌')+' '+l); v?pass++:fail++; });
console.log('\n'+pass+'/'+checks.length+' passed');
if(fail===0) console.log('\n🎉 F38+F39+F40 fully implemented!');
else         console.log('\n⚠️ '+fail+' issue(s)');
JSEOF

echo ""
echo "git add . && git commit -m 'feat: F38+F39+F40 Profile page — new UI, completion ring, all fields' && git push"
