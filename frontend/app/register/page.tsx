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

  // ── Galaxy Canvas — FIXED: brighter nebula ──
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
      // Nebula g1 — green-teal  ★ FIX: 0.11 → 0.32
      const g1=ctx.createRadialGradient(W()*0.8,H()*0.2,0,W()*0.8,H()*0.2,W()*0.4)
      g1.addColorStop(0,'rgba(0,160,120,0.32)'); g1.addColorStop(1,'transparent')
      ctx.fillStyle=g1; ctx.fillRect(0,0,W(),H())
      // Nebula g2 — blue  ★ FIX: 0.10 → 0.28
      const g2=ctx.createRadialGradient(W()*0.15,H()*0.8,0,W()*0.15,H()*0.8,W()*0.35)
      g2.addColorStop(0,'rgba(0,100,200,0.28)'); g2.addColorStop(1,'transparent')
      ctx.fillStyle=g2; ctx.fillRect(0,0,W(),H())
      // Nebula g3 — cyan-teal  ★ FIX: 0.05 → 0.18
      const g3=ctx.createRadialGradient(W()*0.5,H()*0.4,0,W()*0.5,H()*0.4,W()*0.22)
      g3.addColorStop(0,'rgba(0,220,180,0.18)'); g3.addColorStop(1,'transparent')
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
    try{ const r=await fetch(`${API}/api/auth/verify-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,otp})}); const d=await r.json(); if(r.ok){try{localStorage.setItem('pr_token',d.token);localStorage.setItem('pr_role',d.role||'student')}catch{};try{localStorage.setItem('pr_new_student','true')}catch(e){};router.replace('/dashboard')}else setError(d.message||'Invalid OTP') }catch{setError('Network error. Please try again.')}
    setLoading(false)
  }
  const resendOtp=async()=>{
    setResend(true);setError('');setMsg('')
    try{ const r=await fetch(`${API}/api/auth/resend-otp`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email})}); const d=await r.json(); if(r.ok) setMsg('New OTP sent! Check your inbox.'); else setError(d.message||'Failed to resend') }catch{setError('Network error')}
    setResend(false)
  }

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 80% 40%,#000D1A,#000510 55%,#000108)',fontFamily:'Inter,sans-serif',overflowX:'hidden'}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');*{box-sizing:border-box}@keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}@keyframes floatY{0%,100%{transform:translateY(0)}50%{transform:translateY(-14px)}}@keyframes spinSlow{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}@keyframes fadeInUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}@keyframes glowGreen{0%,100%{filter:drop-shadow(0 0 6px #00C48C55)}50%{filter:drop-shadow(0 0 18px #00C48C99)}}@keyframes bounce{0%,100%{transform:translateY(0) scale(1)}30%{transform:translateY(-18px) scale(1.06)}60%{transform:translateY(-8px) scale(0.97)}}`}</style>

      {/* Galaxy Canvas */}
      <canvas ref={canvasRef} style={{position:'fixed',top:0,left:0,width:'100%',height:'100%',pointerEvents:'none',zIndex:0}}/>

      {/* ── Semiconductor chip SVG — top left  ★ FIX: opacity 0.16→0.38 ── */}
      <div style={{position:'fixed',top:'5%',left:'2%',opacity:0.38,pointerEvents:'none',zIndex:1}}>
        <svg width="95" height="95" viewBox="0 0 95 95">
          <rect x="26" y="26" width="43" height="43" rx="4" fill="none" stroke="#00C48C" strokeWidth="1.8"/>
          <rect x="33" y="33" width="29" height="29" rx="2" fill="rgba(0,196,140,0.10)" stroke="#4D9FFF" strokeWidth="1.2"/>
          {[38,48,58].map(y=><line key={y} x1={33} y1={y} x2={62} y2={y} stroke="#4D9FFF" strokeWidth="1" opacity={0.6}/>)}
          {[38,48,58].map(x=><line key={x} x1={x} y1={33} x2={x} y2={62} stroke="#00C48C" strokeWidth="1" opacity={0.6}/>)}
          {[21,31,41,51,61,71].map((v,i)=>(
            <line key={i} x1={i<3?v:26} y1={i<3?26:v-30} x2={i<3?v:26} y2={i<3?16:v-40} stroke="#4D9FFF" strokeWidth="1.4" opacity="0.8"/>
          ))}
        </svg>
      </div>

      {/* ── Spiral galaxy SVG — top right  ★ FIX: opacity 0.15→0.32 ── */}
      <div style={{position:'fixed',top:'4%',right:'2%',opacity:0.32,pointerEvents:'none',animation:'spinSlow 25s linear infinite',zIndex:1}}>
        <svg width="100" height="100" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="5" fill="#00C48C"/>
          {[9,18,27,36,44].map((r,i)=>(
            <ellipse key={i} cx="50" cy="50" rx={r} ry={r*0.42} fill="none" stroke={i%2===0?'#4D9FFF':'#00C48C'} strokeWidth="1.2" opacity={0.75-i*0.08} transform={`rotate(${i*36} 50 50)`}/>
          ))}
        </svg>
      </div>

      {/* ── Mitochondria SVG — bottom left  ★ FIX: opacity 0.14→0.30, bounce anim ── */}
      <div style={{position:'fixed',bottom:'6%',left:'2%',opacity:0.30,pointerEvents:'none',animation:'bounce 6s ease-in-out infinite',zIndex:1}}>
        <svg width="85" height="65" viewBox="0 0 85 65">
          <ellipse cx="42" cy="32" rx="34" ry="19" fill="none" stroke="#00C48C" strokeWidth="1.8"/>
          <ellipse cx="42" cy="32" rx="23" ry="11" fill="none" stroke="#4D9FFF" strokeWidth="1.2"/>
          {[24,32,40,48,60].map((x,i)=><path key={i} d={`M${x} 21 Q${x+5} 32 ${x} 43`} fill="none" stroke="#00C48C" strokeWidth="1.2" opacity={0.7}/>)}
        </svg>
      </div>

      {/* ── Hexagon pattern — bottom right  ★ FIX: opacity 0.12→0.26 ── */}
      <div style={{position:'fixed',bottom:'5%',right:'1%',opacity:0.26,pointerEvents:'none',zIndex:1}}>
        <svg width="110" height="110" viewBox="0 0 110 110">
          {[[55,30],[32,60],[78,60],[55,90]].map(([cx,cy],i)=>(
            <polygon key={i} points={`${cx},${cy-17} ${cx+15},${cy-8} ${cx+15},${cy+8} ${cx},${cy+17} ${cx-15},${cy+8} ${cx-15},${cy-8}`} fill="none" stroke="#00C48C" strokeWidth="1.4"/>
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
            <div style={{fontSize:12,color:SUB,marginTop:4}}>NEET Preparation Platform</div>
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

          {/* ── Motivational Quote ── */}
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

          {/* ── Animated Molecule SVG illustration  ★ FIX: bounce animation ── */}
          <div style={{marginTop:20,textAlign:'center',animation:'fadeInUp 0.8s ease 0.9s both'}}>
            <div style={{display:'inline-block',animation:'bounce 5s ease-in-out infinite'}}>
              <svg width="175" height="72" viewBox="0 0 175 72">
                {/* Semiconductor pattern */}
                <rect x="5" y="18" width="32" height="32" rx="3" fill="none" stroke="#00C48C" strokeWidth="1.4" opacity="0.8"/>
                {[25,33,41].map((y,i)=><line key={i} x1={5} y1={y} x2={37} y2={y} stroke="#4D9FFF" strokeWidth="0.9" opacity={0.6}/>)}
                <line x1="37" y1="34" x2="57" y2="34" stroke="#00C48C" strokeWidth="1.4" opacity="0.8"/>
                {/* Benzene ring */}
                {[0,1,2,3,4,5].map(i=>{
                  const a1=i*Math.PI/3-Math.PI/6; const a2=(i+1)*Math.PI/3-Math.PI/6
                  return <line key={i} x1={87+19*Math.cos(a1)} y1={34+19*Math.sin(a1)} x2={87+19*Math.cos(a2)} y2={34+19*Math.sin(a2)} stroke="#4D9FFF" strokeWidth="1.6" opacity="0.85"/>
                })}
                <circle cx="87" cy="34" r="8" fill="none" stroke="#00C48C" strokeWidth="1.2" opacity="0.7"/>
                <line x1="106" y1="34" x2="126" y2="34" stroke="#00C48C" strokeWidth="1.4" opacity="0.8"/>
                {/* Flask */}
                <path d="M131 13 L131 33 L121 54 L151 54 L141 33 L141 13 Z" fill="rgba(0,196,140,0.12)" stroke="#00C48C" strokeWidth="1.6"/>
                <line x1="126" y1="13" x2="146" y2="13" stroke="#4D9FFF" strokeWidth="1.6"/>
                <circle cx="133" cy="44" r="3.5" fill="#00C48C" opacity={0.8}/>
                <circle cx="141" cy="47" r="2.5" fill="#4D9FFF" opacity={0.8}/>
              </svg>
            </div>
            <div style={{fontSize:10,color:'rgba(107,143,175,0.45)',marginTop:4}}>ProveRank · NEET · prove-rank.vercel.app</div>
          </div>

        </div>
      </div>
    </div>
  )
}
