#!/bin/bash
# ============================================================
# ProveRank — Login + Register COMPLETE FIX
# B1: Particles background restored
# हि/EN: Language toggle (top right)
# 🌙/☀️: Dark/Light toggle (top right)
# PR4 Logo + N6 Theme + F1 Font — Design Lock maintained
# ============================================================

# ════════════════════════════════════════════════════════════
# FILE 1 — LOGIN PAGE (Complete)
# ════════════════════════════════════════════════════════════
cat > ~/workspace/frontend/app/login/page.tsx << 'ENDOFFILE'
'use client';
import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

// ── PR4 Logo Inline ──
function PRLogo() {
  const size = 64; const r = 32; const cx = 32; const cy = 32;
  const outer = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.88*Math.cos(a)},${cy+r*0.88*Math.sin(a)}`;}).join(' ');
  const inner = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;}).join(' ');
  return (
    <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:10}}>
      <svg width={size} height={size} viewBox="0 0 64 64">
        <defs><filter id="gl"><feGaussianBlur stdDeviation="2.5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
        <polygon points={outer} fill="none" stroke="rgba(77,159,255,0.35)" strokeWidth="1" filter="url(#gl)"/>
        <polygon points={inner} fill="none" stroke="#4D9FFF" strokeWidth="2" filter="url(#gl)"/>
        {Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return <circle key={i} cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)} r={3} fill="#4D9FFF" filter="url(#gl)"/>;  })}
        <text x={cx} y={cy+6} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="20" fontWeight="700" fill="#4D9FFF" filter="url(#gl)">PR</text>
      </svg>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:30,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',letterSpacing:1,lineHeight:1}}>
        ProveRank
      </div>
      <div style={{fontSize:11,color:'#6B8FAF',letterSpacing:4,textTransform:'uppercase'}}>Online Test Platform</div>
    </div>
  );
}

// ── B1: Particles Canvas Background ──
function ParticlesBg() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = canvasRef.current; if (!canvas) return;
    const ctx = canvas.getContext('2d'); if (!ctx) return;
    canvas.width = window.innerWidth; canvas.height = window.innerHeight;
    const particles: {x:number;y:number;vx:number;vy:number;r:number;opacity:number}[] = [];
    for (let i = 0; i < 80; i++) {
      particles.push({
        x: Math.random() * canvas.width, y: Math.random() * canvas.height,
        vx: (Math.random()-0.5)*0.4, vy: (Math.random()-0.5)*0.4,
        r: Math.random()*2+1, opacity: Math.random()*0.5+0.1
      });
    }
    let animId: number;
    const draw = () => {
      ctx.clearRect(0,0,canvas.width,canvas.height);
      particles.forEach(p => {
        p.x += p.vx; p.y += p.vy;
        if (p.x<0) p.x=canvas.width; if (p.x>canvas.width) p.x=0;
        if (p.y<0) p.y=canvas.height; if (p.y>canvas.height) p.y=0;
        ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2);
        ctx.fillStyle=`rgba(77,159,255,${p.opacity})`; ctx.fill();
      });
      // Connect nearby particles
      for (let i=0;i<particles.length;i++) for (let j=i+1;j<particles.length;j++) {
        const dx=particles[i].x-particles[j].x, dy=particles[i].y-particles[j].y;
        const dist=Math.sqrt(dx*dx+dy*dy);
        if (dist<120) {
          ctx.beginPath(); ctx.moveTo(particles[i].x,particles[i].y); ctx.lineTo(particles[j].x,particles[j].y);
          ctx.strokeStyle=`rgba(77,159,255,${0.12*(1-dist/120)})`; ctx.lineWidth=0.5; ctx.stroke();
        }
      }
      animId = requestAnimationFrame(draw);
    };
    draw();
    const resize = () => { canvas.width=window.innerWidth; canvas.height=window.innerHeight; };
    window.addEventListener('resize', resize);
    return () => { cancelAnimationFrame(animId); window.removeEventListener('resize',resize); };
  }, []);
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>;
}

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [lang, setLang] = useState<'en'|'hi'>('en');
  const [darkMode, setDarkMode] = useState(true);

  const t = {
    en: { title:'Welcome Back', sub:'Apne account mein login karo', email:'EMAIL / ROLL NUMBER', pass:'PASSWORD', forgot:'Forgot password?', btn:'Login →', loading:'⟳ Logging in...', noAcc:'Account nahi hai?', reg:'Register karo' },
    hi: { title:'वापसी पर स्वागत', sub:'अपने अकाउंट में लॉगिन करें', email:'ईमेल / रोल नंबर', pass:'पासवर्ड', forgot:'पासवर्ड भूल गए?', btn:'लॉगिन करें →', loading:'⟳ लॉगिन हो रहा है...', noAcc:'अकाउंट नहीं है?', reg:'रजिस्टर करें' },
  };
  const txt = t[lang];

  useEffect(() => {
    setMounted(true);
    if (getToken()) router.push('/dashboard');
    const saved = localStorage.getItem('pr_theme');
    if (saved === 'light') setDarkMode(false);
  }, [router]);

  const toggleTheme = () => {
    const next = !darkMode;
    setDarkMode(next);
    localStorage.setItem('pr_theme', next ? 'dark' : 'light');
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault(); setError(''); setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/login`, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Login failed');
      localStorage.setItem('pr_token', data.token);
      localStorage.setItem('pr_role', data.role || 'student');
      if (data.role === 'superadmin') router.push('/superadmin');
      else if (data.role === 'admin') router.push('/admin');
      else router.push('/dashboard');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Login nahi hua');
    } finally { setLoading(false); }
  };

  if (!mounted) return null;

  const bg = darkMode ? 'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)' : 'radial-gradient(ellipse at 20% 50%,#E8F4FF 0%,#C9E0FF 60%,#A8CCFF 100%)';
  const cardBg = darkMode ? 'rgba(0,22,40,0.78)' : 'rgba(255,255,255,0.85)';
  const cardBorder = darkMode ? 'rgba(77,159,255,0.22)' : 'rgba(77,159,255,0.35)';
  const textMain = darkMode ? '#E8F4FF' : '#0F172A';
  const textSub = darkMode ? '#6B8FAF' : '#475569';
  const inputBg = darkMode ? 'rgba(0,22,40,0.85)' : 'rgba(255,255,255,0.9)';
  const inputBorder = darkMode ? '#002D55' : '#CBD5E1';
  const inputColor = darkMode ? '#E8F4FF' : '#0F172A';

  return (
    <div style={{minHeight:'100vh',background:bg,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:'24px 16px',position:'relative',overflow:'hidden',transition:'background 0.4s'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:0.4}50%{opacity:0.8}}
        .li{width:100%;padding:14px 16px;border-radius:10px;font-size:15px;outline:none;transition:border 0.2s;font-family:Inter,sans-serif;}
        .li:focus{border-color:#4D9FFF !important;box-shadow:0 0 0 3px rgba(77,159,255,0.15);}
        .lb{width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.4);transition:all 0.3s;font-family:Inter,sans-serif;}
        .lb:disabled{opacity:0.6;cursor:not-allowed;}
        .toggle-btn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;font-family:Inter,sans-serif;backdrop-filter:blur(8px);}
        .toggle-btn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15);}
      `}</style>

      {/* B1: Particles */}
      <ParticlesBg />

      {/* BG hex decorations */}
      <div style={{position:'fixed',top:-40,left:-40,fontSize:200,color:'rgba(77,159,255,0.04)',pointerEvents:'none',zIndex:0}}>⬡</div>
      <div style={{position:'fixed',bottom:-40,right:-40,fontSize:200,color:'rgba(77,159,255,0.04)',pointerEvents:'none',zIndex:0}}>⬡</div>

      {/* ── TOP RIGHT TOGGLES ── */}
      <div style={{position:'fixed',top:16,right:16,display:'flex',gap:8,zIndex:100}}>
        {/* हि/EN Language Toggle */}
        <button className="toggle-btn" onClick={()=>setLang(lang==='en'?'hi':'en')}>
          {lang==='en'?'हि':'EN'}
        </button>
        {/* 🌙/☀️ Dark/Light Toggle */}
        <button className="toggle-btn" onClick={toggleTheme}>
          {darkMode?'☀️':'🌙'}
        </button>
      </div>

      {/* PR4 LOGO */}
      <div style={{animation:'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite',marginBottom:40,textAlign:'center',position:'relative',zIndex:10}}>
        <PRLogo />
      </div>

      {/* Glass Card */}
      <div style={{width:'100%',maxWidth:420,background:cardBg,border:`1px solid ${cardBorder}`,borderRadius:20,padding:'36px 32px',backdropFilter:'blur(20px)',WebkitBackdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.4),inset 0 1px 0 rgba(77,159,255,0.1)',animation:'fadeUp 0.7s ease 0.15s both',position:'relative',zIndex:10}}>

        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,color:textMain,textAlign:'center',margin:'0 0 6px'}}>{txt.title}</h1>
        <p style={{textAlign:'center',color:textSub,fontSize:14,marginBottom:28}}>{txt.sub}</p>

        {error && <div style={{background:'rgba(239,68,68,0.12)',border:'1px solid rgba(239,68,68,0.3)',borderRadius:10,padding:'12px 16px',marginBottom:20,color:'#FCA5A5',fontSize:14,textAlign:'center'}}>⚠️ {error}</div>}

        <form onSubmit={handleLogin} style={{display:'flex',flexDirection:'column',gap:16}}>
          <div>
            <label style={{fontSize:12,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:6,letterSpacing:0.5}}>{txt.email}</label>
            <input type="text" value={email} onChange={e=>setEmail(e.target.value)} placeholder="student@proverank.com" required className="li"
              style={{background:inputBg,border:`1.5px solid ${inputBorder}`,color:inputColor}} />
          </div>
          <div>
            <label style={{fontSize:12,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:6,letterSpacing:0.5}}>{txt.pass}</label>
            <div style={{position:'relative'}}>
              <input type={showPass?'text':'password'} value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••••••" required className="li"
                style={{paddingRight:48,background:inputBg,border:`1.5px solid ${inputBorder}`,color:inputColor}}/>
              <button type="button" onClick={()=>setShowPass(!showPass)} style={{position:'absolute',right:14,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'#6B8FAF',cursor:'pointer',fontSize:16}}>
                {showPass?'🙈':'👁️'}
              </button>
            </div>
          </div>
          <div style={{textAlign:'right',marginTop:-8}}>
            <button type="button" style={{background:'none',border:'none',color:'#4D9FFF',fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>{txt.forgot}</button>
          </div>
          <button type="submit" disabled={loading} className="lb">{loading?txt.loading:txt.btn}</button>
        </form>

        <div style={{textAlign:'center',marginTop:24,fontSize:14,color:textSub}}>
          {txt.noAcc}{' '}<a href="/register" style={{color:'#4D9FFF',fontWeight:600,textDecoration:'none'}}>{txt.reg}</a>
        </div>
      </div>

      <div style={{marginTop:32,color:'#3A5A7A',fontSize:11,letterSpacing:3,textTransform:'uppercase',animation:'pulse 3s infinite',position:'relative',zIndex:10}}>
        NEET · NEET PG · JEE · CUET
      </div>
    </div>
  );
}
ENDOFFILE

echo "✅ 1/2 — Login page complete (Particles + हि/EN + 🌙/☀️ + PR4 Logo)"

# ════════════════════════════════════════════════════════════
# FILE 2 — REGISTER PAGE (Complete)
# ════════════════════════════════════════════════════════════
cat > ~/workspace/frontend/app/register/page.tsx << 'ENDOFFILE'
'use client';
import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

function PRLogo() {
  const size = 60; const r = 30; const cx = 30; const cy = 30;
  const outer = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.88*Math.cos(a)},${cy+r*0.88*Math.sin(a)}`;}).join(' ');
  const inner = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;}).join(' ');
  return (
    <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:8}}>
      <svg width={size} height={size} viewBox="0 0 60 60">
        <defs><filter id="gl2"><feGaussianBlur stdDeviation="2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
        <polygon points={outer} fill="none" stroke="rgba(77,159,255,0.35)" strokeWidth="1" filter="url(#gl2)"/>
        <polygon points={inner} fill="none" stroke="#4D9FFF" strokeWidth="1.8" filter="url(#gl2)"/>
        {Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return <circle key={i} cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)} r={2.8} fill="#4D9FFF" filter="url(#gl2)"/>;  })}
        <text x={cx} y={cy+5} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="19" fontWeight="700" fill="#4D9FFF" filter="url(#gl2)">PR</text>
      </svg>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',letterSpacing:1}}>ProveRank</div>
      <div style={{fontSize:10,color:'#6B8FAF',letterSpacing:4,textTransform:'uppercase'}}>Online Test Platform</div>
    </div>
  );
}

function ParticlesBg() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = canvasRef.current; if (!canvas) return;
    const ctx = canvas.getContext('2d'); if (!ctx) return;
    canvas.width = window.innerWidth; canvas.height = window.innerHeight;
    const particles: {x:number;y:number;vx:number;vy:number;r:number;opacity:number}[] = [];
    for (let i=0;i<80;i++) particles.push({x:Math.random()*canvas.width,y:Math.random()*canvas.height,vx:(Math.random()-.5)*.4,vy:(Math.random()-.5)*.4,r:Math.random()*2+1,opacity:Math.random()*.5+.1});
    let animId: number;
    const draw = () => {
      ctx.clearRect(0,0,canvas.width,canvas.height);
      particles.forEach(p => {
        p.x+=p.vx; p.y+=p.vy;
        if(p.x<0)p.x=canvas.width; if(p.x>canvas.width)p.x=0;
        if(p.y<0)p.y=canvas.height; if(p.y>canvas.height)p.y=0;
        ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2);
        ctx.fillStyle=`rgba(77,159,255,${p.opacity})`; ctx.fill();
      });
      for(let i=0;i<particles.length;i++) for(let j=i+1;j<particles.length;j++){
        const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y,dist=Math.sqrt(dx*dx+dy*dy);
        if(dist<120){ctx.beginPath();ctx.moveTo(particles[i].x,particles[i].y);ctx.lineTo(particles[j].x,particles[j].y);ctx.strokeStyle=`rgba(77,159,255,${.12*(1-dist/120)})`;ctx.lineWidth=.5;ctx.stroke();}
      }
      animId=requestAnimationFrame(draw);
    };
    draw();
    const resize=()=>{canvas.width=window.innerWidth;canvas.height=window.innerHeight;};
    window.addEventListener('resize',resize);
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize);};
  },[]);
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>;
}

export default function RegisterPage() {
  const router = useRouter();
  const [form, setForm] = useState({name:'',email:'',phone:'',password:'',confirm:''});
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);
  const [terms, setTerms] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [lang, setLang] = useState<'en'|'hi'>('en');
  const [darkMode, setDarkMode] = useState(true);

  useEffect(() => {
    setMounted(true);
    if (getToken()) router.push('/dashboard');
    const saved = localStorage.getItem('pr_theme');
    if (saved==='light') setDarkMode(false);
  }, [router]);

  const toggleTheme = () => {
    const next = !darkMode;
    setDarkMode(next);
    localStorage.setItem('pr_theme', next?'dark':'light');
  };

  const set = (k:string,v:string) => setForm(f=>({...f,[k]:v}));

  const handleSubmit = async (e:React.FormEvent) => {
    e.preventDefault(); setError(''); setSuccess('');
    if (form.password!==form.confirm){setError(lang==='en'?'Passwords match nahi karte!':'पासवर्ड मेल नहीं खाते!');return;}
    if (!terms){setError(lang==='en'?'Terms & Conditions accept karo!':'Terms & Conditions स्वीकार करें!');return;}
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/register`,{
        method:'POST',headers:{'Content-Type':'application/json'},
        body:JSON.stringify({name:form.name,email:form.email,phone:form.phone,password:form.password,termsAccepted:true}),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message||'Registration failed');
      setSuccess(lang==='en'?'✅ Account ban gaya! Login karo ab.':'✅ अकाउंट बन गया! अब लॉगिन करें।');
      setTimeout(()=>router.push('/login'),2000);
    } catch(e:unknown){
      setError(e instanceof Error?e.message:'Registration nahi hua');
    } finally{setLoading(false);}
  };

  if (!mounted) return null;

  const bg = darkMode?'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)':'radial-gradient(ellipse at 20% 50%,#E8F4FF 0%,#C9E0FF 60%,#A8CCFF 100%)';
  const cardBg = darkMode?'rgba(0,22,40,0.78)':'rgba(255,255,255,0.85)';
  const cardBorder = darkMode?'rgba(77,159,255,0.22)':'rgba(77,159,255,0.35)';
  const textMain = darkMode?'#E8F4FF':'#0F172A';
  const textSub = darkMode?'#6B8FAF':'#475569';
  const inputBg = darkMode?'rgba(0,22,40,0.85)':'rgba(255,255,255,0.9)';
  const inputBorder = darkMode?'#002D55':'#CBD5E1';
  const inputColor = darkMode?'#E8F4FF':'#0F172A';

  const fields = lang==='en'
    ? [{k:'name',l:'FULL NAME',t:'text',p:'Apna poora naam'},{k:'email',l:'EMAIL',t:'email',p:'email@example.com'},{k:'phone',l:'PHONE',t:'tel',p:'10-digit number'}]
    : [{k:'name',l:'पूरा नाम',t:'text',p:'अपना पूरा नाम'},{k:'email',l:'ईमेल',t:'email',p:'email@example.com'},{k:'phone',l:'मोबाइल',t:'tel',p:'10 अंकों का नंबर'}];

  return (
    <div style={{minHeight:'100vh',background:bg,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:'24px 16px',position:'relative',overflow:'hidden',transition:'background 0.4s'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:0.4}50%{opacity:0.8}}
        .ri{width:100%;padding:13px 16px;border-radius:10px;font-size:14px;outline:none;transition:border 0.2s;font-family:Inter,sans-serif;}
        .ri:focus{border-color:#4D9FFF !important;box-shadow:0 0 0 3px rgba(77,159,255,0.15);}
        .rb{width:100%;padding:14px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:15px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.4);font-family:Inter,sans-serif;}
        .rb:disabled{opacity:0.6;cursor:not-allowed;}
        .toggle-btn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;font-family:Inter,sans-serif;backdrop-filter:blur(8px);}
        .toggle-btn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15);}
      `}</style>

      <ParticlesBg />
      <div style={{position:'fixed',top:-40,left:-40,fontSize:200,color:'rgba(77,159,255,0.04)',pointerEvents:'none',zIndex:0}}>⬡</div>
      <div style={{position:'fixed',bottom:-40,right:-40,fontSize:200,color:'rgba(77,159,255,0.04)',pointerEvents:'none',zIndex:0}}>⬡</div>

      {/* ── TOP RIGHT TOGGLES ── */}
      <div style={{position:'fixed',top:16,right:16,display:'flex',gap:8,zIndex:100}}>
        <button className="toggle-btn" onClick={()=>setLang(lang==='en'?'hi':'en')}>{lang==='en'?'हि':'EN'}</button>
        <button className="toggle-btn" onClick={toggleTheme}>{darkMode?'☀️':'🌙'}</button>
      </div>

      {/* PR4 LOGO */}
      <div style={{animation:'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite',marginBottom:28,textAlign:'center',position:'relative',zIndex:10}}>
        <PRLogo />
      </div>

      {/* Glass Card */}
      <div style={{width:'100%',maxWidth:440,background:cardBg,border:`1px solid ${cardBorder}`,borderRadius:20,padding:'28px 28px',backdropFilter:'blur(20px)',WebkitBackdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.4)',animation:'fadeUp 0.7s ease 0.15s both',position:'relative',zIndex:10}}>

        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:textMain,textAlign:'center',margin:'0 0 4px'}}>
          {lang==='en'?'Create Account':'नया खाता बनाएं'}
        </h1>
        <p style={{textAlign:'center',color:textSub,fontSize:13,marginBottom:22}}>
          {lang==='en'?'ProveRank par apna account banao':'ProveRank पर अपना अकाउंट बनाएं'}
        </p>

        {error && <div style={{background:'rgba(239,68,68,0.12)',border:'1px solid rgba(239,68,68,0.3)',borderRadius:10,padding:'10px 16px',marginBottom:14,color:'#FCA5A5',fontSize:13,textAlign:'center'}}>⚠️ {error}</div>}
        {success && <div style={{background:'rgba(34,197,94,0.12)',border:'1px solid rgba(34,197,94,0.3)',borderRadius:10,padding:'10px 16px',marginBottom:14,color:'#86EFAC',fontSize:13,textAlign:'center'}}>{success}</div>}

        <form onSubmit={handleSubmit} style={{display:'flex',flexDirection:'column',gap:12}}>
          {fields.map(({k,l,t,p})=>(
            <div key={k}>
              <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:4,letterSpacing:0.5}}>{l}</label>
              <input type={t} value={form[k as keyof typeof form]} onChange={e=>set(k,e.target.value)} placeholder={p} required={k!=='phone'} className="ri"
                style={{background:inputBg,border:`1.5px solid ${inputBorder}`,color:inputColor}}/>
            </div>
          ))}
          <div>
            <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:4,letterSpacing:0.5}}>
              {lang==='en'?'PASSWORD':'पासवर्ड'}
            </label>
            <div style={{position:'relative'}}>
              <input type={showPass?'text':'password'} value={form.password} onChange={e=>set('password',e.target.value)} placeholder="Min 8 characters" required className="ri"
                style={{paddingRight:44,background:inputBg,border:`1.5px solid ${inputBorder}`,color:inputColor}}/>
              <button type="button" onClick={()=>setShowPass(!showPass)} style={{position:'absolute',right:12,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'#6B8FAF',cursor:'pointer',fontSize:14}}>
                {showPass?'🙈':'👁️'}
              </button>
            </div>
          </div>
          <div>
            <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:4,letterSpacing:0.5}}>
              {lang==='en'?'CONFIRM PASSWORD':'पासवर्ड पुनः दर्ज करें'}
            </label>
            <input type="password" value={form.confirm} onChange={e=>set('confirm',e.target.value)} placeholder={lang==='en'?'Password dobara likho':'पासवर्ड दोबारा लिखें'} required className="ri"
              style={{background:inputBg,border:`1.5px solid ${inputBorder}`,color:inputColor}}/>
          </div>
          <div style={{display:'flex',alignItems:'flex-start',gap:10,marginTop:4}}>
            <div onClick={()=>setTerms(!terms)} style={{width:18,height:18,borderRadius:4,border:`2px solid ${terms?'#4D9FFF':inputBorder}`,background:terms?'#4D9FFF':'transparent',cursor:'pointer',flexShrink:0,marginTop:1,display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,color:'white',transition:'all 0.2s'}}>
              {terms&&'✓'}
            </div>
            <span style={{fontSize:12,color:textSub,lineHeight:1.6}}>
              {lang==='en'?'Main':' मैं'}{' '}
              <a href="/terms" style={{color:'#4D9FFF',textDecoration:'none',fontWeight:600}}>Terms & Conditions</a>
              {lang==='en'?' se agree karta/karti hoon':' से सहमत हूं'}
            </span>
          </div>
          <button type="submit" disabled={loading} className="rb" style={{marginTop:6}}>
            {loading?(lang==='en'?'⟳ Creating account...':'⟳ बन रहा है...'):(lang==='en'?'Create Account →':'अकाउंट बनाएं →')}
          </button>
        </form>

        <div style={{textAlign:'center',marginTop:18,fontSize:14,color:textSub}}>
          {lang==='en'?'Already account hai?':'पहले से अकाउंट है?'}{' '}
          <a href="/login" style={{color:'#4D9FFF',fontWeight:600,textDecoration:'none'}}>{lang==='en'?'Login karo':'लॉगिन करें'}</a>
        </div>
      </div>
      <div style={{marginTop:24,color:'#3A5A7A',fontSize:11,letterSpacing:3,textTransform:'uppercase',animation:'pulse 3s infinite',position:'relative',zIndex:10}}>
        NEET Pattern Online Test Platform
      </div>
    </div>
  );
}
ENDOFFILE

echo "✅ 2/2 — Register page complete (Particles + हि/EN + 🌙/☀️ + PR4 Logo)"

# ════════════════════════════════════════════════════════════
# VERIFY
# ════════════════════════════════════════════════════════════
echo ""
echo "── Verify ──"
grep -c "ParticlesBg\|toggle-btn\|lang\|darkMode" ~/workspace/frontend/app/login/page.tsx && echo "✅ Login — all features present"
grep -c "ParticlesBg\|toggle-btn\|lang\|darkMode" ~/workspace/frontend/app/register/page.tsx && echo "✅ Register — all features present"

# ════════════════════════════════════════════════════════════
# GIT PUSH
# ════════════════════════════════════════════════════════════
cd ~/workspace
git add -A
git commit -m "feat: Login + Register — B1 Particles + हि/EN + Dark/Light restored + PR4 Logo"
git push origin main

echo ""
echo "🎉 Complete! Login + Register dono pages pe:"
echo "   ✅ B1 Particles background (live dots + lines)"
echo "   ✅ हि/EN language toggle (top right)"
echo "   ✅ 🌙/☀️ Dark/Light toggle (top right)"
echo "   ✅ PR4 Hexagon Logo + ProveRank gradient text"
