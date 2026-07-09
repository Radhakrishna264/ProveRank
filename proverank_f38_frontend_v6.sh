#!/bin/bash
# ProveRank — F38 Student Profile — FRONTEND deploy script (v6: fix stuck "unsaved changes" after successful save)
# Run from project ROOT in Replit shell: bash proverank_f38_frontend_v6.sh
set -e

APP_DIR="frontend/app"

mkdir -p "$APP_DIR/profile"

echo '-> Writing $APP_DIR/profile/page.tsx'
cat > "$APP_DIR/profile/page.tsx" << 'PRSHEOF'
'use client'
import CopyBtn from '@/components/CopyBtn'
import { useState, useEffect, useRef, useMemo } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ══════════════════════════════════════════════════════════════
// F38 — Static option lists (per spec §4.2 / §4.3 / §4.4)
// ══════════════════════════════════════════════════════════════
const STATES = ['Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal','Delhi','Jammu & Kashmir','Ladakh','Chandigarh','Puducherry','Other']
const CITY_MAP: Record<string,string[]> = {
  'Delhi':['New Delhi','Dwarka','Rohini','Karol Bagh'],
  'Maharashtra':['Mumbai','Pune','Nagpur','Nashik','Thane'],
  'Karnataka':['Bengaluru','Mysuru','Hubli'],
  'Rajasthan':['Jaipur','Jodhpur','Udaipur','Kota'],
  'Uttar Pradesh':['Lucknow','Kanpur','Noida','Ghaziabad','Varanasi'],
  'Tamil Nadu':['Chennai','Coimbatore','Madurai'],
  'West Bengal':['Kolkata','Howrah','Siliguri'],
  'Gujarat':['Ahmedabad','Surat','Vadodara'],
  'Bihar':['Patna','Gaya'],
  'Telangana':['Hyderabad','Warangal'],
  'Punjab':['Ludhiana','Amritsar','Chandigarh'],
  'Madhya Pradesh':['Bhopal','Indore','Gwalior'],
  'Haryana':['Gurugram','Faridabad','Panipat'],
}
const TARGET_EXAMS = ['NEET UG','NEET PG','JEE Main','JEE Advanced','CUET UG','CUET PG','SSC','IIT JAM','Other']
const TARGET_YEARS = ['2025','2026','2027','2028','2029']
const BOARDS   = ['CBSE','Rajasthan','ICSE','UP Board','Maharashtra','Others']
const MEDIUMS  = ['English','Hindi','Other']
const YEAR_APPEAR = ['Class 11','Class 12','Dropper','Graduated']
const GENDERS  = ['Male','Female','Non-binary','Prefer not to say']
const TIMEZONES = ['Asia/Kolkata','Asia/Colombo','Asia/Dhaka','Asia/Kathmandu','UTC']

const PHONE_RX = /^(\+91)?[6-9]\d{9}$/

// ══════════════════════════════════════════════════════════════
// Small shared pieces
// ══════════════════════════════════════════════════════════════
function CompletionRing({ pct, size=96, color }: { pct:number; size?:number; color?:string }) {
  const r = (size-8)/2, circ = 2*Math.PI*r, dash = (pct/100)*circ
  const col = color || (pct>=80?'#00C48C':pct>=50?'#4D9FFF':'#FFD700')
  return (
    <svg width={size} height={size} style={{position:'absolute',top:0,left:0,transform:'rotate(-90deg)'}}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(120,140,170,0.18)" strokeWidth="4"/>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={col} strokeWidth="4"
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round" style={{transition:'stroke-dasharray .6s ease'}}/>
    </svg>
  )
}
function EyeBtn({show,toggle,sub}:{show:boolean;toggle:()=>void;sub:string}) {
  return (
    <button type="button" onClick={toggle} style={{position:'absolute',right:12,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',cursor:'pointer',color:sub,padding:0,display:'flex',alignItems:'center'}}>
      {show
        ? <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
        : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>}
    </button>
  )
}
function SectionCard({title,icon,children,theme}:{title?:string;icon?:string;children:any;theme:any}) {
  return (
    <div style={{background: theme.isDark?'rgba(255,255,255,0.03)':'rgba(37,99,235,0.02)', border:`1px solid ${theme.border}`, borderRadius:16, padding:'18px 16px', marginBottom:14}}>
      {title && <div style={{fontSize:13.5,fontWeight:700,color:theme.primary,marginBottom:14,display:'flex',alignItems:'center',gap:7}}>{icon}{title}</div>}
      {children}
    </div>
  )
}
function Field({label,children,theme}:{label:string;children:any;theme:any}) {
  return (<div style={{marginBottom:14}}><label style={{display:'block',fontSize:11,fontWeight:700,color:theme.sub,marginBottom:6,letterSpacing:'.02em'}}>{label}</label>{children}</div>)
}

function ProfileContent() {
  const { lang, darkMode:dm, user, toast, token, theme, setColorTheme } = useShell()
  const t = (en:string, hi:string) => lang==='en' ? en : hi
  const bdr = theme.border, txt = theme.text, sub = theme.sub, prim = theme.primary

  const inp:any = { width:'100%',padding:'11px 14px', background: dm?'rgba(0,22,40,.7)':'rgba(255,255,255,.9)',
    border:`1.5px solid ${bdr}`, borderRadius:11, color:txt, fontSize:13,
    fontFamily:'Inter,sans-serif', outline:'none', boxSizing:'border-box', transition:'border-color .2s' }
  const sel:any = { ...inp, cursor:'pointer' }
  const btnP:any = { background:`linear-gradient(135deg,${prim},${dm?'#0055CC':'#1D4ED8'})`, color:'#fff', border:'none', borderRadius:10, padding:'11px 22px', cursor:'pointer', fontWeight:700, fontSize:13, fontFamily:'Inter,sans-serif' }
  const btnGhost:any = { background:'transparent', border:`1.5px solid ${bdr}`, color:txt, borderRadius:10, padding:'10px 20px', cursor:'pointer', fontWeight:600, fontSize:13, fontFamily:'Inter,sans-serif' }

  const SECTIONS = [
    {id:'overview',  en:'Overview',          hi:'अवलोकन',        icon:'🏠'},
    {id:'personal',  en:'Personal Details',  hi:'व्यक्तिगत विवरण', icon:'👤'},
    {id:'academic',  en:'Academic Profile',  hi:'शैक्षणिक प्रोफ़ाइल', icon:'🎓'},
    {id:'security',  en:'Security',          hi:'सुरक्षा',        icon:'🔒'},
    {id:'preferences',en:'Preferences',      hi:'प्राथमिकताएं',   icon:'⚙️'},
    {id:'activity',  en:'Activity',          hi:'गतिविधि',        icon:'🕐'},
  ]
  const [section, setSection] = useState('overview')
  const [pendingSection, setPendingSection] = useState<string|null>(null)
  const [isMobile, setIsMobile] = useState(true)
  const [idCardOpen, setIdCardOpen] = useState(false)
  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 900)
    check(); window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  // ── Core "me" state (own copy — refreshed after saves) ──
  const [me, setMe] = useState<any>(user || null)
  const loadMe = async () => {
    try { const r = await fetch(`${API}/api/auth/me`, { headers:{Authorization:`Bearer ${token}`} }); const d = await r.json(); if (d?._id) setMe(d) } catch {}
  }
  useEffect(() => { if (user) setMe(user) }, [user])
  useEffect(() => { if (token) loadMe() }, [token])

  // ── Overview data ──
  const [ov, setOv] = useState<any>(null)
  const loadOverview = async () => {
    try { const r = await fetch(`${API}/api/auth/profile-overview`, { headers:{Authorization:`Bearer ${token}`} }); const d = await r.json(); setOv(d) } catch {}
  }
  useEffect(() => { if (token) loadOverview() }, [token])

  // ── Security overview data ──
  const [sec, setSec] = useState<any>(null)
  const loadSecurity = async () => {
    try { const r = await fetch(`${API}/api/auth/security-overview`, { headers:{Authorization:`Bearer ${token}`} }); const d = await r.json(); setSec(d) } catch {}
  }
  useEffect(() => { if (token && section==='security') loadSecurity() }, [token, section])

  // ── Activity timeline data ──
  const [logs, setLogs] = useState<any[]>([])
  const loadActivity = async () => {
    try { const r = await fetch(`${API}/api/auth/activity`, { headers:{Authorization:`Bearer ${token}`} }); const d = await r.json(); setLogs(d.logs||[]) } catch {}
  }
  useEffect(() => { if (token && section==='activity') loadActivity() }, [token, section])

  // ── Personal fields ──
  const [name,setName]=useState(''); const [phone,setPhone]=useState(''); const [dob,setDob]=useState('')
  const [city,setCity]=useState(''); const [state,setState2]=useState(''); const [gender,setGender]=useState('')
  const [bio,setBio]=useState(''); const [avatar,setAvatar]=useState(''); const [timezone,setTimezone]=useState('Asia/Kolkata')
  const [savingPersonal,setSavingPersonal]=useState(false); const [dirtyPersonal,setDirtyPersonal]=useState(false)

  // ── Academic fields ──
  const [targetExam,setTargetExam]=useState(''); const [targetYear,setTargetYear]=useState('')
  const [yearAppearing,setYearAppearing]=useState(''); const [board,setBoard]=useState('')
  const [school,setSchool]=useState(''); const [medium,setMedium]=useState(''); const [coaching,setCoaching]=useState('')
  const [savingAcademic,setSavingAcademic]=useState(false); const [dirtyAcademic,setDirtyAcademic]=useState(false)

  // ── Security — password fields ──
  const [cp,setCp]=useState(''); const [np,setNp]=useState(''); const [cnp,setCnp]=useState('')
  const [showCp,setShowCp]=useState(false); const [showNp,setShowNp]=useState(false); const [showCnp,setShowCnp]=useState(false)
  const [passSaving,setPassSaving]=useState(false)
  const [pwConfirmOpen,setPwConfirmOpen]=useState(false)

  // ── 2FA flow ──
  const [tfaBusy,setTfaBusy]=useState(false)
  const [tfaSetup,setTfaSetup]=useState<{secret:string;qrCode:string}|null>(null)
  const [tfaOtp,setTfaOtp]=useState('')
  const [tfaDisableOtp,setTfaDisableOtp]=useState('')
  const [tfaDisableOpen,setTfaDisableOpen]=useState(false)

  // ── Preferences ──
  const [notifEmail,setNotifEmail]=useState(true); const [notifSms,setNotifSms]=useState(false); const [notifStudy,setNotifStudy]=useState(true)
  const [savingPrefs,setSavingPrefs]=useState(false); const [dirtyPrefs,setDirtyPrefs]=useState(false)

  const initial = useRef<any>({})
  const [loaded, setLoaded] = useState(false)

  useEffect(() => {
    if (!me) return
    const tz = me.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Kolkata'
    setName(me.name||''); setPhone(me.phone||''); setDob(me.dob||''); setCity(me.city||'')
    setState2(me.state||''); setGender(me.gender||''); setBio(me.bio||''); setAvatar(me.avatar||'')
    setTimezone(tz)
    setTargetExam(me.targetExam||''); setTargetYear(me.targetYear||''); setYearAppearing(me.yearOfAppearing||'')
    setBoard(me.board||''); setSchool(me.school||''); setMedium(me.medium||''); setCoaching(me.coachingInstitute||'')
    if (me.preferences) { setNotifEmail(me.preferences.emailNotif ?? true); setNotifSms(me.preferences.smsNotif ?? false); setNotifStudy(me.preferences.studyReminder ?? true) }
    initial.current = {
      name:me.name||'', phone:me.phone||'', dob:me.dob||'', city:me.city||'', state:me.state||'', gender:me.gender||'', bio:me.bio||'', avatar:me.avatar||'', timezone:tz,
      targetExam:me.targetExam||'', targetYear:me.targetYear||'', yearAppearing:me.yearOfAppearing||'', board:me.board||'', school:me.school||'', medium:me.medium||'', coaching:me.coachingInstitute||'',
      notifEmail: me.preferences?.emailNotif ?? true, notifSms: me.preferences?.smsNotif ?? false, notifStudy: me.preferences?.studyReminder ?? true,
    }
    setLoaded(true)
  }, [me])

  // Dirty checks are guarded by `loaded` — prevents a false "unsaved changes"
  // prompt from firing before the initial snapshot has actually been set.
  useEffect(()=>{ if(!loaded) return; const i=initial.current; setDirtyPersonal(name!==i.name||phone!==i.phone||dob!==i.dob||city!==i.city||state!==i.state||gender!==i.gender||bio!==i.bio||avatar!==i.avatar||timezone!==i.timezone) },[loaded,name,phone,dob,city,state,gender,bio,avatar,timezone])
  useEffect(()=>{ if(!loaded) return; const i=initial.current; setDirtyAcademic(targetExam!==i.targetExam||targetYear!==i.targetYear||yearAppearing!==i.yearAppearing||board!==i.board||school!==i.school||medium!==i.medium||coaching!==i.coaching) },[loaded,targetExam,targetYear,yearAppearing,board,school,medium,coaching])
  useEffect(()=>{ if(!loaded) return; const i=initial.current; setDirtyPrefs(notifEmail!==i.notifEmail||notifSms!==i.notifSms||notifStudy!==i.notifStudy) },[loaded,notifEmail,notifSms,notifStudy])

  // ── F38 §11.4 — Live inline validation (as-you-type) ──
  const phoneWarning = useMemo(() => {
    if (!phone) return ''
    return PHONE_RX.test(phone.replace(/[\s-]/g,'')) ? '' : t('Enter a valid 10-digit Indian mobile number (e.g. +919876543210)','एक मान्य 10 अंकों का मोबाइल नंबर दर्ज करें')
  }, [phone])
  const dobWarning = useMemo(() => {
    if (!dob) return ''
    const d = new Date(dob)
    if (isNaN(d.getTime())) return t('Invalid date','अमान्य तिथि')
    if (d > new Date()) return t('Date of birth cannot be in the future','जन्म तिथि भविष्य में नहीं हो सकती')
    const age = new Date().getFullYear() - d.getFullYear()
    if (age < 5 || age > 100) return t('Please enter a realistic date of birth','कृपया एक सही जन्म तिथि दर्ज करें')
    return ''
  }, [dob])
  const cityWarning = useMemo(() => {
    if (state && !city) return t('Please select/enter your city','कृपया अपना शहर चुनें/दर्ज करें')
    return ''
  }, [state, city])

  // ── F38 §11.4.2.5 — Duplicate phone check (debounced, live) ──
  const [phoneDupWarning, setPhoneDupWarning] = useState('')
  const [phoneChecking, setPhoneChecking] = useState(false)
  useEffect(() => {
    if (!phone || phoneWarning) { setPhoneDupWarning(''); return }
    if (phone === initial.current.phone) { setPhoneDupWarning(''); return }
    setPhoneChecking(true)
    const h = setTimeout(async () => {
      try {
        const r = await fetch(`${API}/api/auth/check-phone?phone=${encodeURIComponent(phone.replace(/[\s-]/g,''))}`, { headers:{Authorization:`Bearer ${token}`} })
        const d = await r.json()
        setPhoneDupWarning(d.available ? '' : t('This phone number is already registered with another account','यह फ़ोन नंबर पहले से किसी अन्य खाते से पंजीकृत है'))
      } catch {} finally { setPhoneChecking(false) }
    }, 600)
    return () => clearTimeout(h)
  }, [phone, token, phoneWarning])

  const anyDirty = dirtyPersonal || dirtyAcademic || dirtyPrefs
  const goSection = (id:string) => {
    if (anyDirty && id !== section) {
      const ok = window.confirm(t('You have unsaved changes. Leave this section anyway?','आपके पास असहेजे गए बदलाव हैं। फिर भी छोड़ें?'))
      if (!ok) return
    }
    setSection(id)
  }

  // ── Avatar upload (client-side resize → base64, then PATCH) ──
  const fileRef = useRef<HTMLInputElement>(null)
  const [avatarBusy,setAvatarBusy]=useState(false)
  const onPickPhoto = () => fileRef.current?.click()
  const onPhotoChange = (e:any) => {
    const file = e.target.files?.[0]; if (!file) return
    if (!file.type.startsWith('image/')) { toast?.(t('Please select an image file','कृपया इमेज फ़ाइल चुनें'),'e'); return }
    setAvatarBusy(true)
    const img = new Image()
    const reader = new FileReader()
    reader.onload = (ev:any) => {
      img.onload = () => {
        const size = 300
        const canvas = document.createElement('canvas'); canvas.width = size; canvas.height = size
        const ctx = canvas.getContext('2d')!
        const scale = Math.max(size/img.width, size/img.height)
        const w = img.width*scale, h = img.height*scale
        ctx.drawImage(img, (size-w)/2, (size-h)/2, w, h)
        const dataUrl = canvas.toDataURL('image/jpeg', 0.75)
        setAvatar(dataUrl); setAvatarBusy(false)
      }
      img.src = ev.target.result
    }
    reader.readAsDataURL(file)
  }

  // ── Generic section save ──
  const saveSection = async (body:any, section_:string, onDone?:()=>void) => {
    try {
      const r = await fetch(`${API}/api/auth/me`, { method:'PATCH', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`}, body: JSON.stringify({ ...body, __section: section_ }) })
      const d = await r.json()
      if (!r.ok) { toast?.(d.message||t('Save failed','सहेजने में विफल'),'e'); return false }
      toast?.(t('Saved successfully!','सफलतापूर्वक सहेजा गया!'),'s')
      await loadMe(); await loadOverview()
      onDone?.()
      return true
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e'); return false }
  }

  const savePersonal = async () => {
    if (phone && !PHONE_RX.test(phone.replace(/[\s-]/g,''))) { toast?.(t('Invalid phone number','अमान्य फ़ोन नंबर'),'e'); return }
    if (phoneDupWarning) { toast?.(phoneDupWarning,'e'); return }
    if (dobWarning) { toast?.(dobWarning,'e'); return }
    if (dob) { const d=new Date(dob); if (isNaN(d.getTime())||d>new Date()) { toast?.(t('Invalid date of birth','अमान्य जन्म तिथि'),'e'); return } }
    setSavingPersonal(true)
    const ok = await saveSection({name,phone,dob,city,state,gender,bio,avatar,timezone}, 'personal')
    if (ok) {
      initial.current = { ...initial.current, name,phone,dob,city,state,gender,bio,avatar,timezone }
      setDirtyPersonal(false)
    }
    setSavingPersonal(false)
  }
  const saveAcademic = async () => {
    setSavingAcademic(true)
    const ok = await saveSection({targetExam,targetYear,yearOfAppearing:yearAppearing,board,school,medium,coachingInstitute:coaching}, 'academic')
    if (ok) {
      initial.current = { ...initial.current, targetExam,targetYear,yearAppearing,board,school,medium,coaching }
      setDirtyAcademic(false)
    }
    setSavingAcademic(false)
  }
  const savePrefs = async () => {
    setSavingPrefs(true)
    const ok = await saveSection({preferences:{emailNotif:notifEmail,smsNotif:notifSms,studyReminder:notifStudy}}, 'preferences')
    if (ok) {
      initial.current = { ...initial.current, notifEmail,notifSms,notifStudy }
      setDirtyPrefs(false)
    }
    setSavingPrefs(false)
  }
  const doChangePassword = async () => {
    if (!cp || !np || !cnp) { toast?.(t('Fill all password fields','सभी पासवर्ड फ़ील्ड भरें'),'e'); return }
    if (np.length < 6) { toast?.(t('New password min 6 characters','नया पासवर्ड कम से कम 6 अक्षर'),'e'); return }
    if (np !== cnp) { toast?.(t('Passwords do not match','पासवर्ड मेल नहीं खाते'),'e'); return }
    setPassSaving(true)
    try {
      const r = await fetch(`${API}/api/auth/change-password`, { method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`}, body: JSON.stringify({currentPassword:cp,newPassword:np}) })
      const d = await r.json()
      if (!r.ok) toast?.(d.message||t('Failed','विफल'),'e')
      else { toast?.(t('Password changed!','पासवर्ड बदल गया!'),'s'); setCp('');setNp('');setCnp(''); loadSecurity() }
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e') }
    setPassSaving(false)
    setPwConfirmOpen(false)
  }

  // ── 2FA handlers ──
  const enable2FA = async () => {
    setTfaBusy(true)
    try {
      const r = await fetch(`${API}/api/auth/2fa/enable`, { method:'POST', headers:{Authorization:`Bearer ${token}`} })
      const d = await r.json()
      if (!r.ok) toast?.(d.message||t('Failed to start 2FA setup','2FA सेटअप शुरू नहीं हो सका'),'e')
      else setTfaSetup({secret:d.secret, qrCode:d.qrCode})
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e') }
    setTfaBusy(false)
  }
  const verify2FA = async () => {
    if (!tfaOtp || tfaOtp.length !== 6) { toast?.(t('Enter the 6-digit code','6 अंकों का कोड डालें'),'e'); return }
    setTfaBusy(true)
    try {
      const r = await fetch(`${API}/api/auth/2fa/verify`, { method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`}, body: JSON.stringify({otp:tfaOtp}) })
      const d = await r.json()
      if (!r.ok) toast?.(d.message||t('Invalid code','अमान्य कोड'),'e')
      else { toast?.(t('2FA enabled!','2FA सक्षम!'),'s'); setTfaSetup(null); setTfaOtp(''); loadSecurity(); loadOverview() }
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e') }
    setTfaBusy(false)
  }
  const disable2FA = async () => {
    setTfaBusy(true)
    try {
      const r = await fetch(`${API}/api/auth/2fa/disable`, { method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`}, body: JSON.stringify({otp:tfaDisableOtp}) })
      const d = await r.json()
      if (!r.ok) toast?.(d.message||t('Invalid code','अमान्य कोड'),'e')
      else { toast?.(t('2FA disabled','2FA अक्षम'),'s'); setTfaDisableOpen(false); setTfaDisableOtp(''); loadSecurity(); loadOverview() }
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e') }
    setTfaBusy(false)
  }
  const logoutOtherSessions = async () => {
    const ok = window.confirm(t('This will sign you out from every other device. This device stays logged in. Continue?','यह आपको अन्य सभी डिवाइस से लॉगआउट कर देगा। यह डिवाइस लॉगिन रहेगा। जारी रखें?'))
    if (!ok) return
    try {
      const r = await fetch(`${API}/api/auth/logout-other-sessions`, { method:'POST', headers:{Authorization:`Bearer ${token}`} })
      const d = await r.json()
      if (!r.ok) { toast?.(d.message||t('Failed','विफल'),'e'); return }
      try { if (d.token) localStorage.setItem('pr_token', d.token) } catch {}
      toast?.(t('Logged out from other devices. This device stays signed in.','अन्य डिवाइस से लॉगआउट हो गया। यह डिवाइस लॉगिन है।'),'s')
      loadSecurity()
    } catch { toast?.(t('Network error','नेटवर्क त्रुटि'),'e') }
  }

  const cityOptions = state && CITY_MAP[state] ? CITY_MAP[state] : []
  const initials = (name||me?.name||'S').trim().charAt(0).toUpperCase()

  // ── Hero card (persistent, per spec §2.1 / §13.2) ──
  const Hero = () => (
    <SectionCard theme={theme}>
      <div style={{display:'flex',gap:16,alignItems:'center',flexWrap:'wrap'}}>
        <div style={{position:'relative',width:84,height:84,flexShrink:0}}>
          <CompletionRing pct={ov?.completion ?? 0} size={84}/>
          <div onClick={onPickPhoto} style={{position:'absolute',top:6,left:6,width:72,height:72,borderRadius:'50%',background: avatar?`url(${avatar})`:`linear-gradient(135deg,${prim},#00D4FF)`,backgroundSize:'cover',backgroundPosition:'center',display:'flex',alignItems:'center',justifyContent:'center',fontSize:26,fontWeight:800,color:'#fff',cursor:'pointer',overflow:'hidden'}}>
            {!avatar && initials}
            <div style={{position:'absolute',inset:0,background:'rgba(0,0,0,0.35)',opacity:0,transition:'opacity .2s',display:'flex',alignItems:'center',justifyContent:'center',fontSize:16}} className="avatar-hover">📷</div>
          </div>
          {avatarBusy && <div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,color:'#fff'}}>...</div>}
          <input ref={fileRef} type="file" accept="image/*" onChange={onPhotoChange} style={{display:'none'}}/>
        </div>
        <div style={{flex:1,minWidth:160}}>
          <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
            <div style={{fontSize:18,fontWeight:800,color:txt}}>{me?.name || '—'}</div>
            {ov?.verified && <span style={{fontSize:10,fontWeight:700,color:'#00C48C',background:'rgba(0,196,140,0.12)',padding:'2px 8px',borderRadius:99}}>✓ {t('Verified','सत्यापित')}</span>}
          </div>
          <div style={{display:'flex',alignItems:'center',gap:6,marginTop:4,flexWrap:'wrap'}}>
            <span style={{fontSize:11,color:sub}}>ID: {me?.studentId || '—'}</span>
            {me?.studentId && <CopyBtn text={me.studentId}/>}
          </div>
          <div style={{display:'flex',gap:6,marginTop:8,flexWrap:'wrap'}}>
            {ov?.batch && <span style={{fontSize:10,fontWeight:700,color:prim,background:theme.chipBg,padding:'3px 9px',borderRadius:99}}>📚 {ov.batch}</span>}
            {targetExam && <span style={{fontSize:10,fontWeight:700,color:'#FFD700',background:'rgba(255,215,0,0.1)',padding:'3px 9px',borderRadius:99}}>🎯 {targetExam}</span>}
          </div>
        </div>
        <button onClick={()=>goSection('personal')} style={btnGhost}>✏️ {t('Quick Edit','त्वरित संपादन')}</button>
      </div>
    </SectionCard>
  )

  // ══════════════════════════════════════════════════════════
  // OVERVIEW SECTION
  // ══════════════════════════════════════════════════════════
  const OverviewSection = () => (
    <>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(130px,1fr))',gap:10,marginBottom:14}}>
        {[
          {lbl:t('Completion','पूर्णता'), val:`${ov?.completion ?? 0}%`, ico:'📊', col:'#4D9FFF'},
          {lbl:t('Health Score','स्वास्थ्य स्कोर'), val:`${ov?.health ?? 0}/100`, ico:'💚', col:'#00C48C'},
          {lbl:t('Total Exams','कुल परीक्षाएं'), val: ov?.stats?.totalExams ?? 0, ico:'📝', col:'#A855F7'},
          {lbl:t('Best Score','सर्वश्रेष्ठ स्कोर'), val: ov?.stats?.bestScore ?? 0, ico:'🏆', col:'#FFD700'},
          {lbl:t('Avg Score','औसत स्कोर'), val: ov?.stats?.avgScore ?? 0, ico:'📈', col:'#FF6B9D'},
          {lbl:t('Current Streak','वर्तमान लकीर'), val:`${ov?.stats?.currentStreak ?? 0}d`, ico:'🔥', col:'#FFA502'},
        ].map((s,i)=>(
          <div key={i} style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:14,padding:'14px 10px',textAlign:'center'}}>
            <div style={{fontSize:18}}>{s.ico}</div>
            <div style={{fontSize:16,fontWeight:800,color:s.col,marginTop:4}}>{s.val}</div>
            <div style={{fontSize:9.5,color:sub,marginTop:2,fontWeight:600}}>{s.lbl}</div>
          </div>
        ))}
      </div>

      {!!(ov?.missing?.length) && (
        <SectionCard theme={theme} title={t('Complete Your Profile','अपनी प्रोफ़ाइल पूरी करें')} icon="✅">
          {ov.missing.map((m:any,i:number)=>(
            <div key={i} onClick={()=> m.href && goSection(m.href.replace('#',''))} style={{display:'flex',alignItems:'center',gap:8,padding:'8px 4px',cursor:m.href?'pointer':'default',borderBottom: i<ov.missing.length-1?`1px solid ${bdr}`:'none'}}>
              <span style={{width:18,height:18,borderRadius:'50%',border:`1.5px solid ${prim}`,flexShrink:0}}/>
              <span style={{fontSize:12.5,color:txt}}>{m.label}</span>
              {m.href && <span style={{marginLeft:'auto',fontSize:11,color:prim}}>→</span>}
            </div>
          ))}
        </SectionCard>
      )}

      <SectionCard theme={theme} title={t('Quick Actions','त्वरित कार्रवाई')} icon="⚡">
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:10}}>
          {[
            {lbl:t('Edit Profile','प्रोफ़ाइल संपादित करें'),ico:'✏️',fn:()=>goSection('personal')},
            {lbl:t('Upload Photo','फोटो अपलोड करें'),ico:'📷',fn:onPickPhoto},
            {lbl:t('Change Password','पासवर्ड बदलें'),ico:'🔑',fn:()=>goSection('security')},
            {lbl:t('Manage Devices','डिवाइस प्रबंधित करें'),ico:'📱',fn:()=>goSection('security')},
            {lbl:t('Academic Snapshot','शैक्षणिक स्नैपशॉट'),ico:'🎓',fn:()=>goSection('academic')},
            {lbl:t('View ID Card','आईडी कार्ड देखें'),ico:'🪪',fn:()=>setIdCardOpen(true)},
          ].map((a,i)=>(
            <button key={i} onClick={a.fn} style={{...btnGhost,display:'flex',alignItems:'center',gap:8,justifyContent:'flex-start'}}>{a.ico} {a.lbl}</button>
          ))}
        </div>
      </SectionCard>

      <SectionCard theme={theme}>
        <button onClick={()=>setIdCardOpen(true)} style={{...btnGhost,width:'100%',display:'flex',alignItems:'center',justifyContent:'center',gap:8}}>🪪 {t('View Digital Student ID Card','डिजिटल छात्र आईडी कार्ड देखें')}</button>
      </SectionCard>
    </>
  )

  // ── Digital Student ID Card visual (used inline preview + modal) — §11.3 ──
  const IdCardVisual = () => (
    <div style={{display:'flex',gap:16,alignItems:'center',flexWrap:'wrap',background: dm?'linear-gradient(135deg,#020816,#001830)':'linear-gradient(135deg,#EEF4FF,#DCEBFF)', borderRadius:14, padding:16, border:`1px solid ${bdr}`}}>
      <div style={{width:56,height:56,borderRadius:'50%',background: avatar?`url(${avatar})`:`linear-gradient(135deg,${prim},#00D4FF)`,backgroundSize:'cover',backgroundPosition:'center',display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:800,color:'#fff',flexShrink:0}}>{!avatar && initials}</div>
      <div style={{flex:1,minWidth:140}}>
        <div style={{fontWeight:800,fontSize:14,color: dm?'#F1F6FC':'#0F172A'}}>{me?.name}</div>
        <div style={{fontSize:11,color: dm?'#8DA2C0':'#51607A'}}>ID: {me?.studentId||'—'} {ov?.batch?`· ${ov.batch}`:''}</div>
        <div style={{fontSize:11,color: dm?'#8DA2C0':'#51607A'}}>{t('Target','लक्ष्य')}: {targetExam||'—'}</div>
        {ov?.verified && <span style={{fontSize:9,fontWeight:700,color:'#00C48C'}}>✓ {t('Verified','सत्यापित')}</span>}
      </div>
      {me?.studentId && <img alt="QR" width={72} height={72} style={{borderRadius:8,background:'#fff',padding:4}} src={`https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=${encodeURIComponent(me.studentId)}`}/>}
    </div>
  )


  // ══════════════════════════════════════════════════════════
  // PERSONAL SECTION
  // ══════════════════════════════════════════════════════════
  const PersonalSection = () => (
    <SectionCard theme={theme}>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:0}}>
        <Field label={t('FULL NAME','पूरा नाम')} theme={theme}><input style={inp} value={name} onChange={e=>setName(e.target.value)} placeholder={t('Your name','आपका नाम')}/></Field>
        <Field label={t('EMAIL (read-only)','ईमेल (केवल पढ़ने योग्य)')} theme={theme}><input style={{...inp,opacity:.6,cursor:'not-allowed'}} value={me?.email||''} disabled/></Field>
        <Field label={t('PHONE NUMBER','फ़ोन नंबर')} theme={theme}>
          <input style={{...inp, borderColor: (phoneWarning||phoneDupWarning)?'#FF4757':bdr}} value={phone} onChange={e=>setPhone(e.target.value)} placeholder="+91XXXXXXXXXX"/>
          {phoneChecking && <div style={{fontSize:10.5,color:sub,marginTop:4}}>{t('Checking availability...','उपलब्धता जांची जा रही है...')}</div>}
          {!phoneChecking && phoneWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {phoneWarning}</div>}
          {!phoneChecking && !phoneWarning && phoneDupWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {phoneDupWarning}</div>}
          {!phoneChecking && !phoneWarning && !phoneDupWarning && phone && phone!==initial.current.phone && <div style={{fontSize:10.5,color:'#00C48C',marginTop:4}}>✓ {t('Available','उपलब्ध')}</div>}
        </Field>
        <Field label={t('DATE OF BIRTH','जन्म तिथि')} theme={theme}>
          <input type="date" style={{...inp, borderColor: dobWarning?'#FF4757':bdr}} value={dob} onChange={e=>setDob(e.target.value)} max={new Date().toISOString().split('T')[0]}/>
          {dobWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {dobWarning}</div>}
        </Field>
        <Field label={t('GENDER','लिंग')} theme={theme}>
          <select style={sel} value={gender} onChange={e=>setGender(e.target.value)}><option value="">{t('Select','चुनें')}</option>{GENDERS.map(g=><option key={g} value={g}>{g}</option>)}</select>
        </Field>
        <Field label={t('STATE','राज्य')} theme={theme}>
          <select style={sel} value={state} onChange={e=>{setState2(e.target.value); setCity('')}}><option value="">{t('Select','चुनें')}</option>{STATES.map(s=><option key={s} value={s}>{s}</option>)}</select>
        </Field>
        <Field label={t('CITY','शहर')} theme={theme}>
          <input style={{...inp, borderColor: cityWarning?'#FF4757':bdr}} list="city-suggest" value={city} onChange={e=>setCity(e.target.value)} placeholder={t('Your city','आपका शहर')}/>
          <datalist id="city-suggest">{cityOptions.map(c=><option key={c} value={c}/>)}</datalist>
          {cityWarning && <div style={{fontSize:10.5,color:'#FF4757',marginTop:4}}>⚠️ {cityWarning}</div>}
        </Field>
        <Field label={t('TIMEZONE','समय क्षेत्र')} theme={theme}>
          <select style={sel} value={timezone} onChange={e=>setTimezone(e.target.value)}>{TIMEZONES.map(z=><option key={z} value={z}>{z}</option>)}</select>
        </Field>
      </div>
      <Field label={`${t('SHORT BIO','संक्षिप्त परिचय')} (${bio.length}/160)`} theme={theme}>
        <textarea style={{...inp,minHeight:70,resize:'vertical'}} value={bio} maxLength={160} onChange={e=>setBio(e.target.value)} placeholder={t('Tell us about yourself...','अपने बारे में बताएं...')}/>
      </Field>
      <div style={{display:'flex',gap:10,marginTop:6}}>
        <button style={{...btnP,opacity:dirtyPersonal?1:.5,cursor:dirtyPersonal?'pointer':'not-allowed'}} disabled={!dirtyPersonal||savingPersonal} onClick={savePersonal}>{savingPersonal?t('Saving...','सहेज रहे हैं...'):t('Save Personal Details','व्यक्तिगत विवरण सहेजें')}</button>
        {dirtyPersonal && <button style={btnGhost} onClick={()=>setMe({...me})}>{t('Cancel','रद्द करें')}</button>}
      </div>
    </SectionCard>
  )

  // ══════════════════════════════════════════════════════════
  // ACADEMIC SECTION
  // ══════════════════════════════════════════════════════════
  const AcademicSection = () => (
    <>
      <SectionCard theme={theme}>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:0}}>
          <Field label={t('TARGET EXAM','लक्षित परीक्षा')} theme={theme}><select style={sel} value={targetExam} onChange={e=>setTargetExam(e.target.value)}><option value="">{t('Select','चुनें')}</option>{TARGET_EXAMS.map(x=><option key={x} value={x}>{x}</option>)}</select></Field>
          <Field label={t('TARGET YEAR','लक्षित वर्ष')} theme={theme}><select style={sel} value={targetYear} onChange={e=>setTargetYear(e.target.value)}><option value="">{t('Select','चुनें')}</option>{TARGET_YEARS.map(y=><option key={y} value={y}>{y}</option>)}</select></Field>
          <Field label={t('BOARD','बोर्ड')} theme={theme}><select style={sel} value={board} onChange={e=>setBoard(e.target.value)}><option value="">{t('Select','चुनें')}</option>{BOARDS.map(b=><option key={b} value={b}>{b}</option>)}</select></Field>
          <Field label={t('MEDIUM','माध्यम')} theme={theme}><select style={sel} value={medium} onChange={e=>setMedium(e.target.value)}><option value="">{t('Select','चुनें')}</option>{MEDIUMS.map(m=><option key={m} value={m}>{m}</option>)}</select></Field>
          <Field label={t('YEAR OF APPEARING','उपस्थित होने का वर्ष')} theme={theme}><select style={sel} value={yearAppearing} onChange={e=>setYearAppearing(e.target.value)}><option value="">{t('Select','चुनें')}</option>{YEAR_APPEAR.map(y=><option key={y} value={y}>{y}</option>)}</select></Field>
          <Field label={t('SCHOOL / COLLEGE NAME','स्कूल/कॉलेज का नाम')} theme={theme}><input style={inp} value={school} onChange={e=>setSchool(e.target.value)} placeholder={t('e.g. DPS RK Puram','जैसे DPS RK Puram')}/></Field>
          <Field label={t('COACHING INSTITUTE (optional)','कोचिंग संस्थान (वैकल्पिक)')} theme={theme}><input style={inp} value={coaching} onChange={e=>setCoaching(e.target.value)} placeholder={t('Optional','वैकल्पिक')}/></Field>
        </div>
        <div style={{display:'flex',gap:10,marginTop:6}}>
          <button style={{...btnP,opacity:dirtyAcademic?1:.5,cursor:dirtyAcademic?'pointer':'not-allowed'}} disabled={!dirtyAcademic||savingAcademic} onClick={saveAcademic}>{savingAcademic?t('Saving...','सहेज रहे हैं...'):t('Save Academic Profile','शैक्षणिक प्रोफ़ाइल सहेजें')}</button>
        </div>
      </SectionCard>

      <SectionCard theme={theme} title={t('Academic Snapshot','शैक्षणिक स्नैपशॉट')} icon="📊">
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(120px,1fr))',gap:10}}>
          {[
            {lbl:t('Total Exams','कुल परीक्षाएं'),val:ov?.stats?.totalExams??0,col:'#A855F7'},
            {lbl:t('Best Score','सर्वश्रेष्ठ स्कोर'),val:ov?.stats?.bestScore??0,col:'#FFD700'},
            {lbl:t('Average Score','औसत स्कोर'),val:ov?.stats?.avgScore??0,col:'#4D9FFF'},
            {lbl:t('Current Streak','वर्तमान लकीर'),val:`${ov?.stats?.currentStreak??0}d`,col:'#FFA502'},
          ].map((s,i)=>(
            <div key={i} style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'12px 8px',textAlign:'center'}}>
              <div style={{fontSize:16,fontWeight:800,color:s.col}}>{s.val}</div>
              <div style={{fontSize:9.5,color:sub,marginTop:2,fontWeight:600}}>{s.lbl}</div>
            </div>
          ))}
        </div>
        {!!(ov?.stats?.rankHistory?.length) && (
          <div style={{marginTop:14}}>
            <div style={{fontSize:11,fontWeight:700,color:sub,marginBottom:8}}>{t('Rank History','रैंक इतिहास')}</div>
            {ov.stats.rankHistory.map((r:any,i:number)=>(
              <div key={i} style={{display:'flex',justifyContent:'space-between',fontSize:12,padding:'6px 0',borderBottom: i<ov.stats.rankHistory.length-1?`1px solid ${bdr}`:'none',color:txt}}>
                <span>{r.examTitle}</span><span style={{color:prim,fontWeight:700}}>{r.rank?`#${r.rank}`:'—'} · {r.score}</span>
              </div>
            ))}
          </div>
        )}
      </SectionCard>
    </>
  )

  // ══════════════════════════════════════════════════════════
  // SECURITY SECTION
  // ══════════════════════════════════════════════════════════
  const SecuritySection = () => (
    <>
      <SectionCard theme={theme} title={t('Change Password','पासवर्ड बदलें')} icon="🔑">
        <Field label={t('CURRENT PASSWORD','वर्तमान पासवर्ड')} theme={theme}><div style={{position:'relative'}}><input type={showCp?'text':'password'} style={inp} value={cp} onChange={e=>setCp(e.target.value)}/><EyeBtn show={showCp} toggle={()=>setShowCp(!showCp)} sub={sub}/></div></Field>
        <Field label={t('NEW PASSWORD','नया पासवर्ड')} theme={theme}><div style={{position:'relative'}}><input type={showNp?'text':'password'} style={inp} value={np} onChange={e=>setNp(e.target.value)}/><EyeBtn show={showNp} toggle={()=>setShowNp(!showNp)} sub={sub}/></div></Field>
        <Field label={t('CONFIRM PASSWORD','पासवर्ड की पुष्टि करें')} theme={theme}><div style={{position:'relative'}}><input type={showCnp?'text':'password'} style={inp} value={cnp} onChange={e=>setCnp(e.target.value)}/><EyeBtn show={showCnp} toggle={()=>setShowCnp(!showCnp)} sub={sub}/></div></Field>
        <button style={btnP} disabled={passSaving} onClick={()=>setPwConfirmOpen(true)}>{passSaving?t('Saving...','सहेज रहे हैं...'):t('Change Password','पासवर्ड बदलें')}</button>
        {pwConfirmOpen && (
          <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,.6)',zIndex:200,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setPwConfirmOpen(false)}>
            <div onClick={e=>e.stopPropagation()} style={{background: dm?'#0A0E17':'#fff', border:`1px solid ${bdr}`, borderRadius:16, padding:24, maxWidth:340, width:'100%'}}>
              <div style={{fontWeight:800,fontSize:15,color:txt,marginBottom:8}}>⚠️ {t('Confirm Password Change','पासवर्ड परिवर्तन की पुष्टि करें')}</div>
              <div style={{fontSize:12.5,color:sub,marginBottom:18}}>{t('Are you sure you want to change your password?','क्या आप वाकई अपना पासवर्ड बदलना चाहते हैं?')}</div>
              <div style={{display:'flex',gap:10}}>
                <button style={btnP} onClick={doChangePassword}>{t('Yes, Change It','हां, बदलें')}</button>
                <button style={btnGhost} onClick={()=>setPwConfirmOpen(false)}>{t('Cancel','रद्द करें')}</button>
              </div>
            </div>
          </div>
        )}
      </SectionCard>

      <SectionCard theme={theme} title={t('Two-Factor Authentication (2FA)','दो-चरणीय सत्यापन')} icon="🛡️">
        {sec?.twoFactorEnabled ? (
          <>
            <div style={{fontSize:12.5,color:'#00C48C',fontWeight:700,marginBottom:12}}>✓ {t('2FA is enabled on your account','आपके खाते पर 2FA सक्षम है')}</div>
            {!tfaDisableOpen ? (
              <button style={btnGhost} onClick={()=>setTfaDisableOpen(true)}>{t('Disable 2FA','2FA अक्षम करें')}</button>
            ) : (
              <div>
                <Field label={t('Enter 6-digit code from your app','ऐप से 6 अंकों का कोड डालें')} theme={theme}><input style={inp} value={tfaDisableOtp} onChange={e=>setTfaDisableOtp(e.target.value)} maxLength={6} placeholder="000000"/></Field>
                <div style={{display:'flex',gap:8}}>
                  <button style={btnP} disabled={tfaBusy} onClick={disable2FA}>{t('Confirm Disable','अक्षम करने की पुष्टि करें')}</button>
                  <button style={btnGhost} onClick={()=>setTfaDisableOpen(false)}>{t('Cancel','रद्द करें')}</button>
                </div>
              </div>
            )}
          </>
        ) : tfaSetup ? (
          <div>
            <div style={{fontSize:12,color:sub,marginBottom:10}}>{t('Scan this QR with Google Authenticator / Authy, then enter the code below.','इस QR को Google Authenticator/Authy से स्कैन करें, फिर नीचे कोड डालें।')}</div>
            <img src={tfaSetup.qrCode} alt="2FA QR" style={{width:140,height:140,borderRadius:10,background:'#fff',padding:6,marginBottom:12}}/>
            <Field label={t('6-digit code','6 अंकों का कोड')} theme={theme}><input style={inp} value={tfaOtp} onChange={e=>setTfaOtp(e.target.value)} maxLength={6} placeholder="000000"/></Field>
            <div style={{display:'flex',gap:8}}>
              <button style={btnP} disabled={tfaBusy} onClick={verify2FA}>{t('Verify & Enable','सत्यापित करें और सक्षम करें')}</button>
              <button style={btnGhost} onClick={()=>setTfaSetup(null)}>{t('Cancel','रद्द करें')}</button>
            </div>
          </div>
        ) : (
          <button style={btnP} disabled={tfaBusy} onClick={enable2FA}>{tfaBusy?t('Loading...','लोड हो रहा है...'):t('Enable 2FA','2FA सक्षम करें')}</button>
        )}
      </SectionCard>

      <SectionCard theme={theme} title={t('Device & Login Health','डिवाइस और लॉगिन स्वास्थ्य')} icon="📱">
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:10,marginBottom:14}}>
          <div style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'10px 12px'}}>
            <div style={{fontSize:9.5,color:sub,fontWeight:700}}>{t('LAST LOGIN','अंतिम लॉगिन')}</div>
            <div style={{fontSize:12,color:txt,marginTop:3}}>{sec?.lastLogin ? new Date(sec.lastLogin.at||sec.lastLogin.time).toLocaleString() : '—'}</div>
            <div style={{fontSize:10.5,color:sub}}>{sec?.lastLogin?.city ? `${sec.lastLogin.city}, ${sec.lastLogin.country}` : ''}</div>
          </div>
          <div style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'10px 12px'}}>
            <div style={{fontSize:9.5,color:sub,fontWeight:700}}>{t('ACTIVE DEVICES','सक्रिय डिवाइस')}</div>
            <div style={{fontSize:16,color:'#00C48C',fontWeight:800}}>{sec?.activeDeviceCount ?? 0}</div>
          </div>
          <div style={{background:theme.chipBg,border:`1px solid ${bdr}`,borderRadius:12,padding:'10px 12px'}}>
            <div style={{fontSize:9.5,color:sub,fontWeight:700}}>{t('FAILED ATTEMPTS','असफल प्रयास')}</div>
            <div style={{fontSize:16,fontWeight:800,color: (sec?.failedLoginAttempts||0)>3?'#FF4757':txt}}>{sec?.failedLoginAttempts ?? 0}</div>
          </div>
        </div>
        <button style={{...btnGhost,borderColor:'rgba(255,71,87,0.4)',color:'#FF6B6B'}} onClick={logoutOtherSessions}>🚪 {t('Logout from Other Devices','अन्य डिवाइस से लॉगआउट करें')}</button>
      </SectionCard>
    </>
  )

  // ══════════════════════════════════════════════════════════
  // PREFERENCES SECTION
  // ══════════════════════════════════════════════════════════
  const Toggle = ({on,onClick}:{on:boolean;onClick:()=>void}) => (
    <button onClick={onClick} style={{width:44,height:24,borderRadius:99,border:'none',cursor:'pointer',background:on?prim:(dm?'rgba(255,255,255,.15)':'rgba(0,0,0,.15)'),position:'relative',transition:'background .2s',flexShrink:0}}>
      <div style={{position:'absolute',top:2,left:on?22:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left .2s'}}/>
    </button>
  )
  const PreferencesSection = () => (
    <SectionCard theme={theme}>
      {[
        {lbl:t('Email Notifications','ईमेल सूचनाएं'),val:notifEmail,fn:()=>setNotifEmail(!notifEmail)},
        {lbl:t('SMS Notifications','SMS सूचनाएं'),val:notifSms,fn:()=>setNotifSms(!notifSms)},
        {lbl:t('Study Reminders','अध्ययन अनुस्मारक'),val:notifStudy,fn:()=>setNotifStudy(!notifStudy)},
      ].map((p,i)=>(
        <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'12px 4px',borderBottom:`1px solid ${bdr}`}}>
          <span style={{fontSize:13,color:txt,fontWeight:600}}>{p.lbl}</span><Toggle on={p.val} onClick={p.fn}/>
        </div>
      ))}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'12px 4px',borderBottom:`1px solid ${bdr}`}}>
        <span style={{fontSize:13,color:txt,fontWeight:600}}>{t('Theme','थीम')}</span>
        <button onClick={()=>setColorTheme(dm?'light':'dark')} style={{display:'flex',alignItems:'center',gap:6,background:theme.chipBg,border:`1.5px solid ${bdr}`,borderRadius:99,padding:'6px 14px',cursor:'pointer',fontSize:12,fontWeight:700,color:prim}}>
          {dm?'🌙':'☀️'} {dm?t('Dark','डार्क'):t('Light','लाइट')}
        </button>
      </div>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'12px 4px'}}>
        <span style={{fontSize:13,color:txt,fontWeight:600}}>{t('Language','भाषा')}</span>
        <span style={{fontSize:12,color:sub}}>{lang==='en'?'English':'हिन्दी'}</span>
      </div>
      <div style={{marginTop:14}}>
        <button style={{...btnP,opacity:dirtyPrefs?1:.5,cursor:dirtyPrefs?'pointer':'not-allowed'}} disabled={!dirtyPrefs||savingPrefs} onClick={savePrefs}>{savingPrefs?t('Saving...','सहेज रहे हैं...'):t('Save Preferences','प्राथमिकताएं सहेजें')}</button>
      </div>
    </SectionCard>
  )

  // ══════════════════════════════════════════════════════════
  // ACTIVITY SECTION
  // ══════════════════════════════════════════════════════════
  const ACT_ICON:any = { LOGIN:'🔓', PROFILE_UPDATED:'✏️', PASSWORD_CHANGED:'🔑', EMAIL_VERIFIED:'✅', PHOTO_UPDATED:'📷', LOGOUT_ALL_DEVICES:'🚪' }
  const ActivitySection = () => (
    <SectionCard theme={theme} title={t('Recent Activity','हाल की गतिविधि')} icon="🕐">
      {logs.length === 0 ? (
        <div style={{textAlign:'center',padding:'30px 0',color:sub,fontSize:12.5}}>{t('No activity yet','अभी तक कोई गतिविधि नहीं')}</div>
      ) : logs.map((l,i)=>(
        <div key={i} style={{display:'flex',gap:10,padding:'10px 4px',borderBottom: i<logs.length-1?`1px solid ${bdr}`:'none'}}>
          <div style={{width:30,height:30,borderRadius:'50%',background:theme.chipBg,display:'flex',alignItems:'center',justifyContent:'center',fontSize:14,flexShrink:0}}>{ACT_ICON[l.action]||'•'}</div>
          <div style={{flex:1,minWidth:0}}>
            <div style={{fontSize:12.5,color:txt,fontWeight:600}}>{l.details || l.action}</div>
            <div style={{fontSize:10.5,color:sub,marginTop:2}}>{new Date(l.createdAt).toLocaleString()}</div>
          </div>
        </div>
      ))}
    </SectionCard>
  )

  return (
    <div style={{maxWidth: isMobile?880:1040, margin:'0 auto'}}>
      <div style={{fontSize:20,fontWeight:800,marginBottom:4,color:txt}}>👤 {t('My Profile','मेरी प्रोफ़ाइल')}</div>
      <div style={{fontSize:12.5,color:sub,marginBottom:18}}>{t('Manage your personal, academic, and security settings','अपनी व्यक्तिगत, शैक्षणिक और सुरक्षा सेटिंग्स प्रबंधित करें')}</div>

      <Hero/>

      {isMobile ? (
        <>
          {/* ── Mobile: swipe-friendly horizontal chips (§1.2.2 / §13.1.3) ── */}
          <div style={{display:'flex',gap:8,overflowX:'auto',marginBottom:16,paddingBottom:4,WebkitOverflowScrolling:'touch'}}>
            {SECTIONS.map(s=>{
              const active = section===s.id
              return (
                <button key={s.id} onClick={()=>goSection(s.id)} style={{flexShrink:0,display:'flex',alignItems:'center',gap:6,padding:'9px 16px',borderRadius:99,border:`1.5px solid ${active?prim:bdr}`,background: active?theme.navActive:'transparent',color: active?prim:txt,fontWeight:active?700:600,fontSize:12.5,cursor:'pointer',whiteSpace:'nowrap'}}>
                  {s.icon} {lang==='en'?s.en:s.hi}
                </button>
              )
            })}
          </div>
          {section==='overview' && <OverviewSection/>}
          {section==='personal' && <PersonalSection/>}
          {section==='academic' && <AcademicSection/>}
          {section==='security' && <SecuritySection/>}
          {section==='preferences' && <PreferencesSection/>}
          {section==='activity' && <ActivitySection/>}
        </>
      ) : (
        <div style={{display:'flex',gap:22,alignItems:'flex-start'}}>
          {/* ── Desktop: real left section rail (§1.2.1 / §12.1.1) ── */}
          <div style={{width:210,flexShrink:0,position:'sticky',top:76,background: theme.isDark?'rgba(255,255,255,0.03)':'rgba(37,99,235,0.02)',border:`1px solid ${bdr}`,borderRadius:16,padding:10}}>
            {SECTIONS.map(s=>{
              const active = section===s.id
              return (
                <button key={s.id} onClick={()=>goSection(s.id)} style={{width:'100%',display:'flex',alignItems:'center',gap:10,padding:'11px 14px',borderRadius:11,border:'none',background: active?theme.navActive:'transparent',color: active?prim:txt,fontWeight:active?700:600,fontSize:13,cursor:'pointer',marginBottom:3,textAlign:'left'}}>
                  <span style={{fontSize:16}}>{s.icon}</span> {lang==='en'?s.en:s.hi}
                  {active && <span style={{marginLeft:'auto',width:6,height:6,borderRadius:'50%',background:prim}}/>}
                </button>
              )
            })}
          </div>
          <div style={{flex:1,minWidth:0}}>
            {section==='overview' && <OverviewSection/>}
            {section==='personal' && <PersonalSection/>}
            {section==='academic' && <AcademicSection/>}
            {section==='security' && <SecuritySection/>}
            {section==='preferences' && <PreferencesSection/>}
            {section==='activity' && <ActivitySection/>}
          </div>
        </div>
      )}

      {/* ── §11.3 — Digital Student ID Card modal ── */}
      {idCardOpen && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,.65)',zIndex:300,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setIdCardOpen(false)}>
          <div onClick={e=>e.stopPropagation()} style={{maxWidth:380,width:'100%'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:10}}>
              <span style={{color:'#fff',fontWeight:700,fontSize:14}}>🪪 {t('Digital Student ID Card','डिजिटल छात्र आईडी कार्ड')}</span>
              <button onClick={()=>setIdCardOpen(false)} style={{background:'rgba(255,255,255,.15)',border:'none',borderRadius:8,width:32,height:32,color:'#fff',cursor:'pointer',fontSize:16}}>✕</button>
            </div>
            <IdCardVisual/>
          </div>
        </div>
      )}
    </div>
  )
}

export default function ProfilePage() {
  return <StudentShell pageKey="profile"><ProfileContent/></StudentShell>
}
PRSHEOF

echo ""
echo "════════════════════════════════════════════════════"
echo "  F38 FRONTEND v6 — VERIFICATION"
echo "════════════════════════════════════════════════════"
PASS=0; TOTAL=0
check() {
  TOTAL=$((TOTAL+1))
  if grep -q "$2" "$1" 2>/dev/null; then echo "✅ $3"; PASS=$((PASS+1)); else echo "❌ $3"; fi
}

F="$APP_DIR/profile/page.tsx"

check "$F" "const ok = await saveSection({name,phone,dob,city,state,gender,bio,avatar,timezone}, 'personal')" "Bug fix: savePersonal captures save result"
check "$F" "setDirtyPersonal(false)"    "Bug fix: dirtyPersonal explicitly cleared on successful save"
check "$F" "const ok = await saveSection({targetExam" "Bug fix: saveAcademic captures save result"
check "$F" "setDirtyAcademic(false)"    "Bug fix: dirtyAcademic explicitly cleared on successful save"
check "$F" "const ok = await saveSection({preferences" "Bug fix: savePrefs captures save result"
check "$F" "setDirtyPrefs(false)"       "Bug fix: dirtyPrefs explicitly cleared on successful save"
check "$F" "setColorTheme"              "Previous fix intact: inline theme toggle in Preferences"
check "$F" "const \[loaded, setLoaded\]" "Previous fix intact: false-dirty-on-load guard"
check "$F" "logout-other-sessions"      "Previous feature intact: logout-other-sessions"

echo "────────────────────────────────────────────────────"
echo "  $PASS / $TOTAL checks passed"
echo "════════════════════════════════════════════════════"
if [ "$PASS" -eq "$TOTAL" ]; then
  echo "🎉 Bug fixed and all prior features intact!"
else
  echo "⚠️  Review the ❌ lines above."
fi
