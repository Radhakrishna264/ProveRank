'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',GLD='#FFD700',SUB='#6B8FAF',TXT='#E8F4FF'
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:TXT,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',transition:'border-color .2s'}

export default function LoginPage() {
  const router = useRouter()
  type Tab = 'password'|'otp'|'forgot'
  const [tab,      setTab]     = useState<Tab>('password')
  // Password login
  const [email,    setEmail]   = useState('')
  const [password, setPassword]= useState('')
  // OTP login
  const [otpEmail, setOtpEmail]= useState('')
  const [loginOtp, setLoginOtp]= useState('')
  const [otpSent,  setOtpSent] = useState(false)
  // Forgot password
  const [fpEmail,  setFpEmail] = useState('')
  const [fpOtp,    setFpOtp]   = useState('')
  const [fpNew,    setFpNew]   = useState('')
  const [fpStep,   setFpStep]  = useState<'email'|'otp'|'done'>('email')
  // Common
  const [loading,  setLoading] = useState(false)
  const [error,    setError]   = useState('')
  const [msg,      setMsg]     = useState('')

  useEffect(()=>{
    try{
      const tk=localStorage.getItem('pr_token')
      const role=localStorage.getItem('pr_role')||'student'
      if(tk){
        if(role==='admin'||role==='superadmin') router.replace('/admin/x7k2p')
        else router.replace('/dashboard')
      }
    }catch{}
  },[router])

  const goAfterLogin=(token:string,role:string)=>{
    try{localStorage.setItem('pr_token',token);localStorage.setItem('pr_role',role)}catch{}
    if(role==='admin'||role==='superadmin') router.replace('/admin/x7k2p')
    else router.replace('/dashboard')
  }

  const loginPassword = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/login`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,password})})
      const d=await r.json()
      if(r.ok) goAfterLogin(d.token,d.role)
      else setError(d.message||'Invalid email or password')
    }catch{setError('Network error. Please try again.')}
    setLoading(false)
  }

  const sendLoginOtp = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/send-login-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:otpEmail})})
      const d=await r.json()
      if(r.ok){setOtpSent(true);setMsg(d.message||'OTP sent!')}
      else setError(d.message||'Failed to send OTP')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const loginWithOtp = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/login-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:otpEmail,otp:loginOtp})})
      const d=await r.json()
      if(r.ok) goAfterLogin(d.token,d.role)
      else setError(d.message||'Invalid OTP')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const sendFpOtp = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/forgot-password`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:fpEmail})})
      const d=await r.json()
      if(r.ok){setFpStep('otp');setMsg(d.message||'OTP sent!')}
      else setError(d.message||'Failed')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const resetPassword = async () => {
    setError(''); setLoading(true)
    try{
      const r=await fetch(`${API}/api/auth/reset-password`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:fpEmail,otp:fpOtp,newPassword:fpNew})})
      const d=await r.json()
      if(r.ok){setFpStep('done');setMsg(d.message||'Password reset!')}
      else setError(d.message||'Failed')
    }catch{setError('Network error')}
    setLoading(false)
  }

  const clearAll=()=>{setError('');setMsg('')}

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 15% 55%,#001020,#000A18 50%,#000308)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:20}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.9}}`}</style>

      {Array.from({length:50},(_,i)=>(
        <div key={i} style={{position:'fixed',left:`${(i*137.5)%100}%`,top:`${(i*97.3)%100}%`,width:`${i%3===0?2:1.2}px`,height:`${i%3===0?2:1.2}px`,borderRadius:'50%',background:`rgba(200,218,255,${.07+i%8*.045})`,pointerEvents:'none',animation:`pulse ${2+i%4}s ${(i%20)/10}s infinite`}}/>
      ))}

      <div style={{width:'100%',maxWidth:420,animation:'fadeIn .5s ease',position:'relative',zIndex:1}}>
        <div style={{textAlign:'center',marginBottom:24}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:700,color:PRI}}>ProveRank</div>
          <div style={{fontSize:12,color:SUB,marginTop:4}}>NEET 2026 Preparation Platform</div>
        </div>

        <div style={{background:'rgba(0,22,40,.88)',border:'1px solid rgba(77,159,255,.28)',borderRadius:20,padding:'28px 24px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,.5)'}}>

          {/* ── TABS ── */}
          <div style={{display:'flex',gap:0,marginBottom:22,borderRadius:10,overflow:'hidden',border:'1px solid rgba(77,159,255,.25)'}}>
            {([['password','🔑 Password'],['otp','📱 OTP Login'],['forgot','🔓 Forgot']] as const).map(([t,l])=>(
              <button key={t} onClick={()=>{setTab(t);clearAll()}} style={{flex:1,padding:'10px 4px',background:tab===t?`linear-gradient(135deg,${PRI},#0055CC)`:'rgba(0,22,40,.8)',color:tab===t?'#fff':SUB,border:'none',cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:11,fontWeight:tab===t?700:400,borderRight:t!=='forgot'?'1px solid rgba(77,159,255,.2)':'none',transition:'all .2s'}}>
                {l}
              </button>
            ))}
          </div>

          {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}
          {msg&&<div style={{background:'rgba(0,196,140,.1)',border:'1px solid rgba(0,196,140,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:SUC,marginBottom:14,textAlign:'center'}}>{msg}</div>}

          {/* ── PASSWORD TAB ── */}
          {tab==='password'&&(
            <>
              <div style={{display:'flex',flexDirection:'column',gap:13,marginBottom:16}}>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email</label>
                  <input type="email" value={email} onChange={e=>setEmail(e.target.value)} onKeyDown={e=>e.key==='Enter'&&loginPassword()} style={inp} placeholder="your@email.com"/>
                </div>
                <div>
                  <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Password</label>
                  <input type="password" value={password} onChange={e=>setPassword(e.target.value)} onKeyDown={e=>e.key==='Enter'&&loginPassword()} style={inp} placeholder="••••••••"/>
                </div>
              </div>

              {/* Forgot Password link — clickable */}
              <div style={{textAlign:'right',marginBottom:16}}>
                <button onClick={()=>{setTab('forgot');clearAll()}} style={{background:'none',border:'none',color:PRI,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',fontWeight:600,padding:0,textDecoration:'underline'}}>
                  Forgot Password?
                </button>
              </div>

              <button onClick={loginPassword} disabled={loading||!email||!password} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!email||!password)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||!email||!password)?.6:1,boxShadow:`0 4px 16px ${PRI}44`}}>
                {loading?'Logging in...':'Login →'}
              </button>
            </>
          )}

          {/* ── OTP LOGIN TAB ── */}
          {tab==='otp'&&(
            <>
              <div style={{marginBottom:13}}>
                <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email</label>
                <input type="email" value={otpEmail} onChange={e=>setOtpEmail(e.target.value)} style={inp} placeholder="your@email.com" disabled={otpSent}/>
              </div>

              {!otpSent?(
                <button onClick={sendLoginOtp} disabled={loading||!otpEmail} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!otpEmail)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||!otpEmail)?.6:1}}>
                  {loading?'Sending OTP...':'Send OTP →'}
                </button>
              ):(
                <>
                  <div style={{marginBottom:13}}>
                    <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Enter OTP</label>
                    <input value={loginOtp} onChange={e=>setLoginOtp(e.target.value.replace(/\D/g,'').slice(0,6))} style={{...inp,fontSize:24,fontWeight:900,textAlign:'center',letterSpacing:10,fontFamily:'monospace'}} placeholder="000000" maxLength={6} inputMode="numeric"/>
                    <div style={{fontSize:11,color:SUB,marginTop:5,textAlign:'center'}}>
                      OTP sent to {otpEmail} · {' '}
                      <button onClick={sendLoginOtp} style={{background:'none',border:'none',color:PRI,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif',fontWeight:600,padding:0}}>Resend</button>
                    </div>
                  </div>
                  <button onClick={loginWithOtp} disabled={loading||loginOtp.length!==6} style={{width:'100%',padding:'13px',background:loginOtp.length===6?`linear-gradient(135deg,${SUC},#00a87a)`:'rgba(77,159,255,.2)',color:loginOtp.length===6?'#000':'#fff',border:'none',borderRadius:12,cursor:(loading||loginOtp.length!==6)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||loginOtp.length!==6)?.6:1}}>
                    {loading?'Verifying...':'✅ Login with OTP →'}
                  </button>
                  <button onClick={()=>{setOtpSent(false);setLoginOtp('');clearAll()}} style={{width:'100%',marginTop:10,padding:'8px',background:'none',border:`1px solid rgba(77,159,255,.2)`,borderRadius:9,color:SUB,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>← Change Email</button>
                </>
              )}
            </>
          )}

          {/* ── FORGOT PASSWORD TAB ── */}
          {tab==='forgot'&&(
            <>
              {fpStep==='email'&&(
                <>
                  <p style={{fontSize:13,color:SUB,marginBottom:16,textAlign:'center'}}>Enter your registered email — we&apos;ll send a reset OTP.</p>
                  <div style={{marginBottom:14}}>
                    <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email</label>
                    <input type="email" value={fpEmail} onChange={e=>setFpEmail(e.target.value)} style={inp} placeholder="your@email.com"/>
                  </div>
                  <button onClick={sendFpOtp} disabled={loading||!fpEmail} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!fpEmail)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||!fpEmail)?.6:1}}>
                    {loading?'Sending OTP...':'Send Reset OTP →'}
                  </button>
                </>
              )}
              {fpStep==='otp'&&(
                <>
                  <p style={{fontSize:13,color:SUB,marginBottom:16,textAlign:'center'}}>OTP sent to <span style={{color:PRI,fontWeight:600}}>{fpEmail}</span></p>
                  <div style={{display:'flex',flexDirection:'column',gap:12,marginBottom:14}}>
                    <div>
                      <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>OTP</label>
                      <input value={fpOtp} onChange={e=>setFpOtp(e.target.value.replace(/\D/g,'').slice(0,6))} style={{...inp,fontSize:22,fontWeight:900,textAlign:'center',letterSpacing:10,fontFamily:'monospace'}} placeholder="000000" maxLength={6} inputMode="numeric"/>
                    </div>
                    <div>
                      <label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>New Password</label>
                      <input type="password" value={fpNew} onChange={e=>setFpNew(e.target.value)} style={inp} placeholder="Min 6 characters"/>
                    </div>
                  </div>
                  <button onClick={resetPassword} disabled={loading||fpOtp.length!==6||fpNew.length<6} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${SUC},#00a87a)`,color:'#000',border:'none',borderRadius:12,cursor:(loading||fpOtp.length!==6||fpNew.length<6)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||fpOtp.length!==6||fpNew.length<6)?.6:1}}>
                    {loading?'Resetting...':'🔑 Reset Password →'}
                  </button>
                  <button onClick={()=>{setFpStep('email');clearAll()}} style={{width:'100%',marginTop:10,padding:'8px',background:'none',border:`1px solid rgba(77,159,255,.2)`,borderRadius:9,color:SUB,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>← Back</button>
                </>
              )}
              {fpStep==='done'&&(
                <div style={{textAlign:'center',padding:'20px 0'}}>
                  <div style={{fontSize:48,marginBottom:12}}>✅</div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:TXT,marginBottom:8}}>Password Reset!</div>
                  <div style={{fontSize:13,color:SUB,marginBottom:20}}>You can now login with your new password.</div>
                  <button onClick={()=>{setTab('password');setFpStep('email');setFpEmail('');setFpOtp('');setFpNew('');clearAll()}} style={{padding:'11px 24px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:10,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif'}}>Go to Login →</button>
                </div>
              )}
            </>
          )}

          {/* Register link */}
          {tab!=='forgot'&&(
            <div style={{textAlign:'center',marginTop:16,fontSize:13,color:SUB}}>
              New to ProveRank?{' '}
              <a href="/register" style={{color:PRI,fontWeight:600,textDecoration:'none'}}>Create Account →</a>
            </div>
          )}
        </div>

        <div style={{textAlign:'center',marginTop:16,fontSize:11,color:'rgba(107,143,175,.5)'}}>
          ProveRank · NEET 2026 · prove-rank.vercel.app
        </div>
      </div>
    </div>
  )
}
