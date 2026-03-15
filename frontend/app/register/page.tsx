'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',GLD='#FFD700',SUB='#6B8FAF',TXT='#E8F4FF'
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:TXT,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',transition:'border-color .2s'}

export default function RegisterPage() {
  const router = useRouter()
  // Step 1: fill details | Step 2: enter OTP
  const [step,     setStep]    = useState<'details'|'otp'>('details')
  const [name,     setName]    = useState('')
  const [email,    setEmail]   = useState('')
  const [password, setPassword]= useState('')
  const [phone,    setPhone]   = useState('')
  const [otp,      setOtp]     = useState('')
  const [loading,  setLoading] = useState(false)
  const [error,    setError]   = useState('')
  const [msg,      setMsg]     = useState('')
  const [resending,setResend]  = useState(false)

  const register = async () => {
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/register`, {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ name, email, password, phone })
      })
      const d = await r.json()
      if (r.ok) { setStep('otp'); setMsg(d.message||'OTP sent!') }
      else setError(d.message||'Registration failed')
    } catch { setError('Network error. Please try again.') }
    setLoading(false)
  }

  const verifyOtp = async () => {
    if (otp.length !== 6) { setError('Enter 6-digit OTP'); return }
    setError(''); setLoading(true)
    try {
      const r = await fetch(`${API}/api/auth/verify-otp`, {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ email, otp })
      })
      const d = await r.json()
      if (r.ok) {
        // Save token and go directly to dashboard
        try { localStorage.setItem('pr_token', d.token); localStorage.setItem('pr_role', d.role||'student') } catch{}
        router.replace('/dashboard')
      } else { setError(d.message||'Invalid OTP') }
    } catch { setError('Network error. Please try again.') }
    setLoading(false)
  }

  const resendOtp = async () => {
    setResend(true); setError(''); setMsg('')
    try {
      const r = await fetch(`${API}/api/auth/resend-otp`, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ email })
      })
      const d = await r.json()
      if (r.ok) setMsg('New OTP sent! Check your inbox.')
      else setError(d.message||'Failed to resend')
    } catch { setError('Network error') }
    setResend(false)
  }

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 15% 55%,#001020,#000A18 50%,#000308)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:20}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.9}}`}</style>

      {/* Stars BG */}
      {Array.from({length:50},(_,i)=>(
        <div key={i} style={{position:'fixed',left:`${(i*137.5)%100}%`,top:`${(i*97.3)%100}%`,width:`${i%3===0?2:1.2}px`,height:`${i%3===0?2:1.2}px`,borderRadius:'50%',background:`rgba(200,218,255,${.07+i%8*.045})`,pointerEvents:'none',animation:`pulse ${2+i%4}s ${(i%20)/10}s infinite`}}/>
      ))}

      <div style={{width:'100%',maxWidth:420,animation:'fadeIn .5s ease',position:'relative',zIndex:1}}>
        {/* Logo */}
        <div style={{textAlign:'center',marginBottom:28}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:700,color:PRI}}>ProveRank</div>
          <div style={{fontSize:12,color:SUB,marginTop:4}}>NEET 2026 Preparation Platform</div>
        </div>

        <div style={{background:'rgba(0,22,40,.88)',border:'1px solid rgba(77,159,255,.28)',borderRadius:20,padding:'32px 28px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,.5)'}}>

          {step === 'details' ? (
            <>
              <h2 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,margin:'0 0 6px',textAlign:'center'}}>Create Account</h2>
              <p style={{fontSize:13,color:SUB,textAlign:'center',marginBottom:22}}>Join ProveRank — Free NEET Preparation</p>

              {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}

              <div style={{display:'flex',flexDirection:'column',gap:13}}>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Full Name *</label>
                  <input value={name} onChange={e=>setName(e.target.value)} style={inp} placeholder="Your full name"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email *</label>
                  <input type="email" value={email} onChange={e=>setEmail(e.target.value)} style={inp} placeholder="your@email.com"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Password *</label>
                  <input type="password" value={password} onChange={e=>setPassword(e.target.value)} style={inp} placeholder="Min 6 characters"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Phone (optional)</label>
                  <input value={phone} onChange={e=>setPhone(e.target.value)} style={inp} placeholder="+91 XXXXX XXXXX"/>
                </div>
              </div>

              <button onClick={register} disabled={loading||!name||!email||!password} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!name||!email||!password)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',marginTop:20,opacity:(loading||!name||!email||!password)?.6:1,boxShadow:`0 4px 16px ${PRI}44`}}>
                {loading?'Creating Account...':'Create Account →'}
              </button>

              <div style={{textAlign:'center',marginTop:16,fontSize:13,color:SUB}}>
                Already have an account?{' '}
                <a href="/login" style={{color:PRI,fontWeight:600,textDecoration:'none'}}>Login →</a>
              </div>
            </>
          ) : (
            <>
              {/* OTP STEP */}
              <div style={{textAlign:'center',marginBottom:22}}>
                <div style={{fontSize:48,marginBottom:12}}>📧</div>
                <h2 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,margin:'0 0 6px'}}>Verify Your Email</h2>
                <p style={{fontSize:13,color:SUB,margin:0}}>OTP sent to <span style={{color:PRI,fontWeight:600}}>{email}</span></p>
              </div>

              {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}
              {msg&&<div style={{background:'rgba(0,196,140,.1)',border:'1px solid rgba(0,196,140,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:SUC,marginBottom:14,textAlign:'center'}}>{msg}</div>}

              {/* Big OTP input */}
              <div style={{marginBottom:18}}>
                <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:8,textTransform:'uppercase',letterSpacing:.4,textAlign:'center'}}>Enter 6-Digit OTP</label>
                <input
                  value={otp}
                  onChange={e=>{ setOtp(e.target.value.replace(/\D/g,'').slice(0,6)); setError('') }}
                  style={{...inp,fontSize:28,fontWeight:900,textAlign:'center',letterSpacing:12,fontFamily:'monospace',padding:'16px'}}
                  placeholder="000000"
                  maxLength={6}
                  inputMode="numeric"
                />
              </div>

              <button onClick={verifyOtp} disabled={loading||otp.length!==6} style={{width:'100%',padding:'13px',background:otp.length===6?`linear-gradient(135deg,${SUC},#00a87a)`:'rgba(77,159,255,.2)',color:otp.length===6?'#000':'#fff',border:'none',borderRadius:12,cursor:(loading||otp.length!==6)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||otp.length!==6)?.6:1,boxShadow:otp.length===6?`0 4px 16px ${SUC}44`:undefined}}>
                {loading?'Verifying...':'✅ Verify & Go to Dashboard →'}
              </button>

              <div style={{textAlign:'center',marginTop:14,fontSize:12,color:SUB}}>
                Didn&apos;t receive OTP?{' '}
                <button onClick={resendOtp} disabled={resending} style={{background:'none',border:'none',color:PRI,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12,padding:0}}>
                  {resending?'Sending...':'Resend OTP'}
                </button>
              </div>
              <div style={{textAlign:'center',marginTop:8,fontSize:11,color:SUB}}>
                OTP valid for 10 minutes · Check spam/junk folder
              </div>

              <button onClick={()=>{setStep('details');setOtp('');setError('');setMsg('')}} style={{width:'100%',marginTop:14,padding:'8px',background:'none',border:`1px solid rgba(77,159,255,.2)`,borderRadius:9,color:SUB,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>
                ← Change Email / Register Again
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
