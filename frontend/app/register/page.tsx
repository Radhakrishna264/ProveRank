'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import PRLogo from '@/components/PRLogo'
import ParticlesBg from '@/components/ParticlesBg'

export default function RegisterPage() {
  const router = useRouter()
  const [step, setStep] = useState<'form'|'otp'>('form')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [otp, setOtp] = useState(['','','','','',''])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [termsOk, setTermsOk] = useState(false)

  const t = lang==='en' ? {
    title:'Create Your Account', sub:'Join ProveRank today',
    nameL:'FULL NAME', emailL:'EMAIL ADDRESS', phoneL:'MOBILE NUMBER',
    passL:'PASSWORD', otpTitle:'Verify Your Number',
    otpSub:'OTP sent to your mobile number',
    btn:'Create Account →', loading:'Creating account...',
    haveAcc:'Already have an account?', loginLink:'Login',
    terms:'I agree to the', termsLink:'Terms & Conditions',
    otpBtn:'Verify & Continue', footer:'NEET · NEET PG · JEE · CUET',
  } : {
    title:'अपना खाता बनाएं', sub:'आज ProveRank से जुड़ें',
    nameL:'पूरा नाम', emailL:'ईमेल पता', phoneL:'मोबाइल नंबर',
    passL:'पासवर्ड', otpTitle:'अपना नंबर सत्यापित करें',
    otpSub:'आपके मोबाइल नंबर पर OTP भेजा गया',
    btn:'खाता बनाएं →', loading:'खाता बनाया जा रहा है...',
    haveAcc:'पहले से खाता है?', loginLink:'लॉगिन करें',
    terms:'मैं सहमत हूं', termsLink:'नियम और शर्तें',
    otpBtn:'सत्यापित करें और जारी रखें', footer:'NEET · NEET PG · JEE · CUET',
  }

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st = localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
  },[])

  const toggleLang = () => { const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark = () => { const n=!dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }

  const handleOtpChange = (i: number, v: string) => {
    if (!/^\d?$/.test(v)) return
    const next = [...otp]; next[i] = v; setOtp(next)
    if (v && i < 5) { const el = document.getElementById(`otp-${i+1}`); if(el)(el as HTMLInputElement).focus() }
  }

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault(); setError(''); setLoading(true)
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/register`,{
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ name, email, phone, password }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.message||'Registration failed')
      setStep('otp')
    } catch(e: unknown) { setError(e instanceof Error ? e.message : 'Failed') }
    finally { setLoading(false) }
  }

  const handleOtp = async (e: React.FormEvent) => {
    e.preventDefault(); setError(''); setLoading(true)
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/verify-otp`,{
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ email, otp: otp.join('') }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.message||'OTP failed')
      router.push('/login')
    } catch(e: unknown) { setError(e instanceof Error ? e.message : 'OTP failed') }
    finally { setLoading(false) }
  }

  if (!mounted) return null

  const bg = dark
    ? 'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)'
    : 'radial-gradient(ellipse at 20% 50%,#E8F4FF 0%,#C9E0FF 60%,#A8CCFF 100%)'
  const cardBg = dark ? 'rgba(0,22,40,0.78)' : 'rgba(255,255,255,0.85)'
  const cardBorder = dark ? 'rgba(77,159,255,0.22)' : 'rgba(77,159,255,0.35)'
  const tm   = dark ? '#E8F4FF' : '#0F172A'
  const ts   = dark ? '#6B8BAF' : '#475569'
  const iBg  = dark ? 'rgba(0,22,40,0.85)' : 'rgba(255,255,255,0.9)'
  const iBrd = dark ? '#002D55' : '#CBD5E1'
  const iClr = dark ? '#E8F4FF' : '#0F172A'

  return (
    <div style={{minHeight:'100vh',background:bg,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:'24px',position:'relative',overflow:'hidden',transition:'background 0.4s'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes fadeUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        @keyframes pulse{0%,100%{opacity:0.4}50%{opacity:0.8}}
        .li{width:100%;padding:14px 16px;border-radius:10px;font-size:15px;outline:none;transition:border 0.2s;font-family:Inter,sans-serif;}
        .li:focus{border-color:#4D9FFF!important;box-shadow:0 0 0 3px rgba(77,159,255,0.15);}
        .lb{width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.4);transition:all 0.3s;}
        .lb:hover{transform:translateY(-2px);box-shadow:0 8px 30px rgba(77,159,255,0.55);}
        .lb:disabled{opacity:0.6;cursor:not-allowed;}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}
        .tbtn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15);}
        .otp-box{width:48px;height:56px;border-radius:12px;border:1.5px solid;text-align:center;font-size:22px;font-weight:700;outline:none;transition:all 0.2s;}
        .otp-box:focus{border-color:#4D9FFF!important;box-shadow:0 0 0 3px rgba(77,159,255,0.2);}
      `}</style>
      <ParticlesBg />
      {/* Toggles */}
      <div style={{position:'fixed',top:16,right:16,display:'flex',gap:8,zIndex:100}}>
        <button className="tbtn" onClick={toggleLang}>{lang==='en'?'🇮🇳 EN':'🌐 हिंदी'}</button>
        <button className="tbtn" onClick={toggleDark}>{dark?'☀️':'🌙'}</button>
      </div>
      {/* Logo */}
      <div style={{animation:'fadeUp 0.6s ease, float 5s 0.6s ease-in-out infinite',marginBottom:32,textAlign:'center',zIndex:10,position:'relative'}}>
        <PRLogo />
      </div>
      {/* Card */}
      <div style={{width:'100%',maxWidth:440,background:cardBg,border:`1px solid ${cardBorder}`,borderRadius:20,padding:'36px 32px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.4)',animation:'fadeUp 0.7s 0.15s ease both',position:'relative',zIndex:10}}>
        {step === 'form' ? (
          <>
            <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,color:tm,textAlign:'center',marginBottom:6}}>{t.title}</h1>
            <p style={{color:ts,fontSize:14,textAlign:'center',marginBottom:28}}>{t.sub}</p>
            {error && <div style={{background:'rgba(239,68,68,0.12)',border:'1px solid rgba(239,68,68,0.3)',borderRadius:10,padding:'12px 16px',marginBottom:16,color:'#FCA5A5',fontSize:14,textAlign:'center'}}>⚠️ {error}</div>}
            <form onSubmit={handleRegister} style={{display:'flex',flexDirection:'column',gap:14}}>
              {[
                [t.nameL,  'text',     name,     setName],
                [t.emailL, 'email',    email,    setEmail],
                [t.phoneL, 'tel',      phone,    setPhone],
                [t.passL,  'password', password, setPassword],
              ].map(([label, type, value, setter]: any) => (
                <div key={label}>
                  <label style={{fontSize:12,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:6,letterSpacing:0.5}}>{label}</label>
                  <input type={type} value={value} onChange={e=>setter(e.target.value)} required className="li" style={{background:iBg,border:`1.5px solid ${iBrd}`,color:iClr}}/>
                </div>
              ))}
              <label style={{display:'flex',alignItems:'center',gap:10,cursor:'pointer',color:ts,fontSize:13,marginTop:4}}>
                <input type="checkbox" checked={termsOk} onChange={e=>setTermsOk(e.target.checked)} style={{accentColor:'#4D9FFF',width:16,height:16}}/>
                {t.terms}{' '}<a href="/terms" target="_blank" style={{color:'#4D9FFF',fontWeight:600,textDecoration:'none'}}>{t.termsLink}</a>
              </label>
              <button type="submit" disabled={loading||!termsOk} className="lb" style={{marginTop:8}}>{loading?t.loading:t.btn}</button>
            </form>
            <div style={{textAlign:'center',marginTop:20,color:ts,fontSize:14}}>
              {t.haveAcc}{' '}<a href="/login" style={{color:'#4D9FFF',fontWeight:600,textDecoration:'none'}}>{t.loginLink}</a>
            </div>
          </>
        ) : (
          <>
            <h1 style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,color:tm,textAlign:'center',marginBottom:6}}>{t.otpTitle}</h1>
            <p style={{color:ts,fontSize:14,textAlign:'center',marginBottom:28}}>{t.otpSub}</p>
            {error && <div style={{background:'rgba(239,68,68,0.12)',border:'1px solid rgba(239,68,68,0.3)',borderRadius:10,padding:'12px',marginBottom:16,color:'#FCA5A5',fontSize:14,textAlign:'center'}}>⚠️ {error}</div>}
            <form onSubmit={handleOtp} style={{display:'flex',flexDirection:'column',gap:24}}>
              <div style={{display:'flex',gap:8,justifyContent:'center'}}>
                {otp.map((v,i)=>(
                  <input key={i} id={`otp-${i}`} value={v} onChange={e=>handleOtpChange(i,e.target.value)} maxLength={1} className="otp-box" style={{background:iBg,border:`1.5px solid ${iBrd}`,color:iClr}}/>
                ))}
              </div>
              <button type="submit" disabled={loading||otp.join('').length!==6} className="lb">{loading?'◌':'✓'} {t.otpBtn}</button>
            </form>
            <div style={{textAlign:'center',marginTop:16}}>
              <button onClick={()=>setStep('form')} style={{background:'none',border:'none',color:'#4D9FFF',cursor:'pointer',fontSize:13}}>← {lang==='en'?'Go back':'वापस जाएं'}</button>
            </div>
          </>
        )}
      </div>
      <div style={{marginTop:32,color:'#3A5A7A',fontSize:11,letterSpacing:3,textTransform:'uppercase',animation:'pulse 3s infinite',zIndex:10,position:'relative'}}>{t.footer}</div>
    </div>
  )
}
