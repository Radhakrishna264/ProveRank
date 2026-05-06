'use client'
import PRLogo from '@/components/PRLogo'
import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',SUB='#6B8FAF',TXT='#E8F4FF'
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)',borderRadius:10,color:TXT,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',transition:'border-color .2s'}

export default function RegisterPage() {
  const router = useRouter()
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [step, setStep] = useState<'details'|'otp'>('details')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [phone, setPhone] = useState('')
  const [otp, setOtp] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')
  const [resending, setResend] = useState(false)

  // ── Galaxy Canvas (different nebula colors from login) ──
  useEffect(()=>{
    const canvas=canvasRef.current; if(!canvas) return
    const ctx=canvas.getContext('2d'); if(!ctx) return
    let raf:number
    const resize=()=>{ canvas.width=window.innerWidth; canvas.height=window.innerHeight }
    resize(); window.addEventListener('resize',resize)
    const W=()=>canvas.width, H=()=>canvas.height
    const stars=Array.from({length:200},(_,i)=>({
      x:Math.random()*window.innerWidth, y:Math.random()*window.innerHeight,
      r:Math.random()*2+0.3, o:Math.random()*0.5+0.1,
      sp:Math.random()*0.035+0.008, ph:Math.random()*Math.PI*2
    }))
    const shoots:any[]=[]
    let frame=0
    const draw=()=>{
      ctx.clearRect(0,0,W(),H()); frame++
      // Nebula — green-teal (different from login blue-purple)
      const g1=ctx.createRadialGradient(W()*0.8,H()*0.2,0,W()*0.8,H()*0.2,W()*0.4)
      g1.addColorStop(0,'rgba(0,160,120,0.11)'); g1.addColorStop(1,'transparent')
      ctx.fillStyle=g1; ctx.fillRect(0,0,W(),H())
      const g2=ctx.createRadialGradient(W()*0.15,H()*0.8,0,W()*0.15,H()*0.8,W()*0.35)
      g2.addColorStop(0,'rgba(0,100,200,0.1)'); g2.addColorStop(1,'transparent')
      ctx.fillStyle=g2; ctx.fillRect(0,0,W(),H())
      const g3=ctx.createRadialGradient(W()*0.5,H()*0.4,0,W()*0.5,H()*0.4,W()*0.22)
      g3.addColorStop(0,'rgba(0,220,180,0.05)'); g3.addColorStop(1,'transparent')
      ctx.fillStyle=g3; ctx.fillRect(0,0,W(),H())
      stars.forEach(s=>{
        s.ph+=s.sp
        const op=s.o*(0.5+0.5*Math.sin(s.ph))
        ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(210,230,255,${op})`; ctx.fill()
      })
      const shouldSpawn = frame%120===0
      if(shouldSpawn && shoots.length<3){
        shoots.push({x:Math.random()*W()*0.5,y:Math.random()*H()*0.4,vx:3.5+Math.random()*3,vy:1.5+Math.random()*2,life:1})
      }
      for(let i=shoots.length-1;i>=0;i--){
        const sh=shoots[i]; sh.x+=sh.vx; sh.y+=sh.vy; sh.life-=0.02
        if(sh.life<=0){shoots.splice(i,1);continue}
        const sg=ctx.createLinearGradient(sh.x-sh.vx*12,sh.y-sh.vy*12,sh.x,sh.y)
        sg.addColorStop(0,'transparent'); sg.addColorStop(1,`rgba(0,220,180,${sh.life*0.9})`)
        ctx.beginPath(); ctx.moveTo(sh.x-sh.vx*12,sh.y-sh.vy*12); ctx.lineTo(sh.x,sh.y)
        ctx.strokeStyle=sg; ctx.lineWidth=1.8; ctx.stroke()
      }
      raf=requestAnimationFrame(draw)
    }
    draw()
    return ()=>{ cancelAnimationFrame(raf); window.removeEventListener('resize',resize) }
  },[])

  const register=async()=>{
    setError('');setLoading(true)
    try{ const r=await fetch(`${API}/api/auth/register`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name,email,password,phone})}); const d=await r.json(); if(r.ok){setStep('otp');setMsg(d.message||'OTP sent!')}else setError(d.message||'Registration failed') }catch{setError('Network error. Please try again.')}
    setLoading(false)
  }
  const verifyOtp=async()=>{
    if(otp.length!==6){setError('Enter 6-digit OTP');return}
    setError('');setLoading(true)
    try{ const r=await fetch(`${API}/api/auth/verify-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,otp})}); const d=await r.json(); if(r.ok){try{localStorage.setItem('pr_token',d.token);localStorage.setItem('pr_role',d.role||'student')}catch{};router.replace('/dashboard')}else setError(d.message||'Invalid OTP') }catch{setError('Network error. Please try again.')}
    setLoading(false)
  }
  const resendOtp=async()=>{
    setResend(true);setError('');setMsg('')
    try{ const r=await fetch(`${API}/api/auth/resend-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email})}); const d=await r.json(); if(r.ok) setMsg('New OTP sent! Check your inbox.'); else setError(d.message||'Failed to resend') }catch{setError('Network error')}
    setResend(false)
  }

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 80% 40%,#000D1A,#000510 55%,#000108)',fontFamily:'Inter,sans-serif',overflowX:'hidden'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}@keyframes floatY{0%,100%{transform:translateY(0)}50%{transform:translateY(-14px)}}@keyframes spinSlow{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}@keyframes fadeInUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}@keyframes glowGreen{0%,100%{filter:drop-shadow(0 0 6px #00C48C55)}50%{filter:drop-shadow(0 0 18px #00C48C99)}}`}</style>

      {/* Galaxy Canvas */}
      <canvas ref={canvasRef} style={{position:'fixed',top:0,left:0,width:'100%',height:'100%',pointerEvents:'none',zIndex:0}}/>

      {/* ── Semiconductor chip SVG — top left ── */}
      <div style={{position:'fixed',top:'5%',left:'2%',opacity:0.16,pointerEvents:'none',zIndex:1}}>
        <svg width="90" height="90" viewBox="0 0 90 90">
          <rect x="25" y="25" width="40" height="40" rx="4" fill="none" stroke="#00C48C" strokeWidth="1.5"/>
          <rect x="31" y="31" width="28" height="28" rx="2" fill="rgba(0,196,140,0.08)" stroke="#4D9FFF" strokeWidth="1"/>
          {[35,45,55].map(y=><line key={y} x1={31} y1={y} x2={59} y2={y} stroke="#4D9FFF" strokeWidth="0.8" opacity={0.5}/>)}
          {[35,45,55].map(x=><line key={x} x1={x} y1={31} x2={x} y2={59} stroke="#00C48C" strokeWidth="0.8" opacity={0.5}/>)}
          {[20,30,40,50,60,70].map((v,i)=>(
            <line key={i} x1={i<3?v:25} y1={i<3?25:v-30} x2={i<3?v:25} y2={i<3?15:v-40} stroke="#4D9FFF" strokeWidth="1.2" opacity="0.7"/>
          ))}
        </svg>
      </div>

      {/* ── Spiral galaxy SVG — top right ── */}
      <div style={{position:'fixed',top:'4%',right:'2%',opacity:0.15,pointerEvents:'none',animation:'spinSlow 25s linear infinite',zIndex:1}}>
        <svg width="95" height="95" viewBox="0 0 95 95">
          <circle cx="47" cy="47" r="4" fill="#00C48C"/>
          {[8,16,24,32,40].map((r,i)=>(
            <ellipse key={i} cx="47" cy="47" rx={r} ry={r*0.4} fill="none" stroke={i%2===0?'#4D9FFF':'#00C48C'} strokeWidth="1" opacity={0.7-i*0.08} transform={`rotate(${i*36} 47 47)`}/>
          ))}
        </svg>
      </div>

      {/* ── Mitochondria SVG — bottom left ── */}
      <div style={{position:'fixed',bottom:'6%',left:'2%',opacity:0.14,pointerEvents:'none',animation:'floatY 8s ease-in-out infinite',zIndex:1}}>
        <svg width="80" height="60" viewBox="0 0 80 60">
          <ellipse cx="40" cy="30" rx="32" ry="18" fill="none" stroke="#00C48C" strokeWidth="1.5"/>
          <ellipse cx="40" cy="30" rx="22" ry="10" fill="none" stroke="#4D9FFF" strokeWidth="1"/>
          {[22,30,38,46,58].map((x,i)=><path key={i} d={`M${x} 20 Q${x+4} 30 ${x} 40`} fill="none" stroke="#00C48C" strokeWidth="1" opacity={0.6}/>)}
        </svg>
      </div>

      {/* ── Hexagon pattern — bottom right ── */}
      <div style={{position:'fixed',bottom:'5%',right:'1%',opacity:0.12,pointerEvents:'none',zIndex:1}}>
        <svg width="100" height="100" viewBox="0 0 100 100">
          {[[50,28],[28,56],[72,56],[50,84]].map(([cx,cy],i)=>(
            <polygon key={i} points={`${cx},${cy-16} ${cx+14},${cy-8} ${cx+14},${cy+8} ${cx},${cy+16} ${cx-14},${cy+8} ${cx-14},${cy-8}`} fill="none" stroke="#00C48C" strokeWidth="1.2"/>
          ))}
        </svg>
      </div>

      {/* ── Main Content ── */}
      <div style={{position:'relative',zIndex:2,display:'flex',flexDirection:'column',alignItems:'center',padding:'24px 20px 48px',minHeight:'100vh'}}>

        <div style={{width:'100%',maxWidth:420,animation:'fadeIn .5s ease',paddingTop:45}}>

          {/* Logo */}
          <div style={{textAlign:'center',marginBottom:28,animation:'glowGreen 3s ease-in-out infinite'}}>
            <div style={{display:'flex',alignItems:'center',justifyContent:'center',gap:10,marginBottom:4}}>
              <PRLogo size={44}/>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</div>
            </div>
            <div style={{fontSize:12,color:SUB,marginTop:4}}>NEET 2026 Preparation Platform</div>
          </div>

          {/* Form Card */}
          <div style={{background:'rgba(0,22,40,.88)',border:'1px solid rgba(77,159,255,.28)',borderRadius:20,padding:'32px 28px',backdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,.5)'}}>

            {step==='details'?(
              <>
                <h2 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,margin:'0 0 6px',textAlign:'center'}}>Create Account</h2>
                <p style={{fontSize:13,color:SUB,textAlign:'center',marginBottom:22}}>Join ProveRank — Free NEET Preparation</p>
                {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}
                <div style={{display:'flex',flexDirection:'column',gap:13}}>
                  <div><label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Full Name *</label><input value={name} onChange={e=>setName(e.target.value)} style={inp} placeholder="Your full name"/></div>
                  <div><label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Email *</label><input type="email" value={email} onChange={e=>setEmail(e.target.value)} style={inp} placeholder="your@email.com"/></div>
                  <div><label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Password *</label><input type="password" value={password} onChange={e=>setPassword(e.target.value)} style={inp} placeholder="Min 6 characters"/></div>
                  <div><label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:5,textTransform:'uppercase',letterSpacing:.4}}>Phone (optional)</label><input value={phone} onChange={e=>setPhone(e.target.value)} style={inp} placeholder="+91 XXXXX XXXXX"/></div>
                </div>
                <button onClick={register} disabled={loading||!name||!email||!password} style={{width:'100%',padding:'13px',background:`linear-gradient(135deg,${PRI},#0055CC)`,color:'#fff',border:'none',borderRadius:12,cursor:(loading||!name||!email||!password)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',marginTop:20,opacity:(loading||!name||!email||!password)?.6:1,boxShadow:`0 4px 16px ${PRI}44`}}>{loading?'Creating Account...':'Create Account →'}</button>
                <div style={{textAlign:'center',marginTop:16,fontSize:13,color:SUB}}>Already have an account?{' '}<a href="/login" style={{color:PRI,fontWeight:600,textDecoration:'none'}}>Login →</a></div>
              </>
            ):(
              <>
                <div style={{textAlign:'center',marginBottom:22}}>
                  <div style={{fontSize:48,marginBottom:12}}>📧</div>
                  <h2 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,margin:'0 0 6px'}}>Verify Your Email</h2>
                  <p style={{fontSize:13,color:SUB,margin:0}}>OTP sent to <span style={{color:PRI,fontWeight:600}}>{email}</span></p>
                </div>
                {error&&<div style={{background:'rgba(255,77,77,.12)',border:'1px solid rgba(255,77,77,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:DNG,marginBottom:14,textAlign:'center'}}>{error}</div>}
                {msg&&<div style={{background:'rgba(0,196,140,.1)',border:'1px solid rgba(0,196,140,.3)',borderRadius:9,padding:'10px 14px',fontSize:13,color:SUC,marginBottom:14,textAlign:'center'}}>{msg}</div>}
                <div style={{marginBottom:18}}><label style={{fontSize:11,color:PRI,fontWeight:600,display:'block',marginBottom:8,textTransform:'uppercase',letterSpacing:.4,textAlign:'center'}}>Enter 6-Digit OTP</label><input value={otp} onChange={e=>{setOtp(e.target.value.replace(/\D/g,'').slice(0,6));setError('')}} style={{...inp,fontSize:28,fontWeight:900,textAlign:'center',letterSpacing:12,fontFamily:'monospace',padding:'16px'}} placeholder="000000" maxLength={6} inputMode="numeric"/></div>
                <button onClick={verifyOtp} disabled={loading||otp.length!==6} style={{width:'100%',padding:'13px',background:otp.length===6?`linear-gradient(135deg,${SUC},#00a87a)`:'rgba(77,159,255,.2)',color:otp.length===6?'#000':'#fff',border:'none',borderRadius:12,cursor:(loading||otp.length!==6)?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',opacity:(loading||otp.length!==6)?.6:1,boxShadow:otp.length===6?`0 4px 16px ${SUC}44`:undefined}}>{loading?'Verifying...':'✅ Verify & Go to Dashboard →'}</button>
                <div style={{textAlign:'center',marginTop:14,fontSize:12,color:SUB}}>Didn&apos;t receive OTP?{' '}<button onClick={resendOtp} disabled={resending} style={{background:'none',border:'none',color:PRI,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12,padding:0}}>{resending?'Sending...':'Resend OTP'}</button></div>
                <div style={{textAlign:'center',marginTop:8,fontSize:11,color:SUB}}>OTP valid for 10 minutes · Check spam/junk folder</div>
                <button onClick={()=>{setStep('details');setOtp('');setError('');setMsg('')}} style={{width:'100%',marginTop:14,padding:'8px',background:'none',border:'1px solid rgba(77,159,255,.2)',borderRadius:9,color:SUB,cursor:'pointer',fontSize:12,fontFamily:'Inter,sans-serif'}}>← Change Email / Register Again</button>
              </>
            )}
          </div>

          {/* ── Motivational Quote (different from login) ── */}
          <div style={{marginTop:24,background:'rgba(0,35,25,0.65)',border:'1px solid rgba(0,196,140,0.2)',borderRadius:16,padding:'18px 22px',backdropFilter:'blur(12px)',animation:'fadeInUp 0.8s ease 0.4s both'}}>
            <div style={{fontSize:10,color:'#00C48C',fontWeight:700,textTransform:'uppercase',letterSpacing:1.2,marginBottom:8}}>🚀 Start Your Journey</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,color:TXT,lineHeight:1.7,fontStyle:'italic'}}>&ldquo;Every expert was once a beginner. Your NEET preparation starts with a single step.&rdquo;</div>
            <div style={{fontSize:11,color:SUB,marginTop:8}}>— ProveRank Team</div>
          </div>

          {/* ── 3 Feature Highlights ── */}
          <div style={{marginTop:16,display:'flex',flexDirection:'column',gap:10,animation:'fadeInUp 0.8s ease 0.6s both'}}>
            {[['🎯','NEET Pattern Tests','720 marks · 180 Qs · +4/-1 marking'],['📊','AI Performance Analytics','Weak areas · Subject trends · Smart revision'],['🏆','All India Rankings','Live rank · Percentile · Leaderboard']].map(([ic,title,sub])=>(
              <div key={title} style={{display:'flex',alignItems:'center',gap:14,background:'rgba(0,22,40,0.55)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:12,padding:'12px 16px',backdropFilter:'blur(8px)'}}>
                <div style={{fontSize:24,flexShrink:0}}>{ic}</div>
                <div><div style={{fontSize:12,color:TXT,fontWeight:600}}>{title}</div><div style={{fontSize:11,color:SUB,marginTop:2}}>{sub}</div></div>
              </div>
            ))}
          </div>

          {/* ── Animated SVG illustration ── */}
          <div style={{marginTop:20,textAlign:'center',animation:'fadeInUp 0.8s ease 0.9s both'}}>
            <div style={{display:'inline-block',animation:'floatY 6s ease-in-out infinite'}}>
              <svg width="170" height="70" viewBox="0 0 170 70">
                {/* Semiconductor pattern */}
                <rect x="5" y="20" width="30" height="30" rx="3" fill="none" stroke="#00C48C" strokeWidth="1.2" opacity="0.7"/>
                {[26,32,38].map((y,i)=><line key={i} x1={5} y1={y} x2={35} y2={y} stroke="#4D9FFF" strokeWidth="0.8" opacity={0.5}/>)}
                <line x1="35" y1="35" x2="55" y2="35" stroke="#00C48C" strokeWidth="1.2" opacity="0.7"/>
                {/* Benzene ring */}
                {[0,1,2,3,4,5].map(i=>{
                  const a1=i*Math.PI/3-Math.PI/6; const a2=(i+1)*Math.PI/3-Math.PI/6
                  return <line key={i} x1={85+18*Math.cos(a1)} y1={35+18*Math.sin(a1)} x2={85+18*Math.cos(a2)} y2={35+18*Math.sin(a2)} stroke="#4D9FFF" strokeWidth="1.5" opacity="0.8"/>
                })}
                <circle cx="85" cy="35" r="8" fill="none" stroke="#00C48C" strokeWidth="1" opacity="0.6"/>
                <line x1="103" y1="35" x2="125" y2="35" stroke="#00C48C" strokeWidth="1.2" opacity="0.7"/>
                {/* Flask */}
                <path d="M130 15 L130 35 L120 55 L150 55 L140 35 L140 15 Z" fill="rgba(0,196,140,0.1)" stroke="#00C48C" strokeWidth="1.5"/>
                <line x1="125" y1="15" x2="145" y2="15" stroke="#4D9FFF" strokeWidth="1.5"/>
                <circle cx="132" cy="45" r="3" fill="#00C48C" opacity="0.7"/>
                <circle cx="140" cy="48" r="2" fill="#4D9FFF" opacity="0.7"/>
              </svg>
            </div>
            <div style={{fontSize:10,color:'rgba(107,143,175,0.45)',marginTop:4}}>ProveRank · NEET 2026 · prove-rank.vercel.app</div>
          </div>

        </div>
      </div>
    </div>
  )
}
