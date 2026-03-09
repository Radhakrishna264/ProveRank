#!/bin/bash
# ============================================================
# ProveRank — PR4 Logo Fix FINAL
# Direct: ~/workspace/frontend/app/login/ & register/
# ============================================================

echo "🎯 Sahi folder pe seedha likhenge..."
echo ""

# Confirm correct paths exist
ls ~/workspace/frontend/app/login/page.tsx && echo "✅ Login path sahi hai" || echo "❌ Login path nahi mila"
ls ~/workspace/frontend/app/register/page.tsx && echo "✅ Register path sahi hai" || echo "❌ Register path nahi mila"
echo ""

# ════════════════════════════════════════════════════════════
# LOGIN PAGE — Direct overwrite
# ════════════════════════════════════════════════════════════
cat > ~/workspace/frontend/app/login/page.tsx << 'ENDOFFILE'
'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { setToken, setRole, getToken } from '@/lib/auth';

// PR4 Logo — Inline (no import needed)
function PRLogo() {
  const size = 64; const r = 32; const cx = 32; const cy = 32;
  const outer = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.88*Math.cos(a)},${cy+r*0.88*Math.sin(a)}`;}).join(' ');
  const inner = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;}).join(' ');
  return (
    <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:10}}>
      <svg width={size} height={size} viewBox="0 0 64 64">
        <defs>
          <filter id="glow"><feGaussianBlur stdDeviation="2.5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
        </defs>
        {/* Honeycomb BG dots */}
        {[16,32,48].map(x=>[16,32,48].map(y=>(
          <circle key={`${x}${y}`} cx={x} cy={y} r={1} fill="rgba(77,159,255,0.15)"/>
        )))}
        {/* Outer hex border */}
        <polygon points={outer} fill="none" stroke="rgba(77,159,255,0.35)" strokeWidth="1" filter="url(#glow)"/>
        {/* Inner hex */}
        <polygon points={inner} fill="none" stroke="#4D9FFF" strokeWidth="2" filter="url(#glow)"/>
        {/* 6 corner dots */}
        {Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return(
          <circle key={i} cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)} r={3} fill="#4D9FFF" filter="url(#glow)"/>
        )})}
        {/* PR text */}
        <text x={cx} y={cy+6} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="20" fontWeight="700" fill="#4D9FFF" filter="url(#glow)">PR</text>
      </svg>
      {/* ProveRank — Blue→White→Blue gradient */}
      <div style={{fontFamily:'Playfair Display,serif',fontSize:30,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',letterSpacing:1,lineHeight:1}}>
        ProveRank
      </div>
      {/* Tagline */}
      <div style={{fontSize:11,color:'#6B8FAF',letterSpacing:4,textTransform:'uppercase'}}>
        Online Test Platform
      </div>
    </div>
  );
}

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (getToken()) router.push('/dashboard');
  }, [router]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Login failed');
      setToken(data.token);
      setRole(data.role);
      if (data.role === 'student') router.push('/dashboard');
      else router.push('/dashboard');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Login nahi hua');
    } finally {
      setLoading(false);
    }
  };

  if (!mounted) return null;

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:'24px 16px',position:'relative',overflow:'hidden'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:0.4}50%{opacity:0.8}}
        .li{width:100%;padding:14px 16px;border-radius:10px;background:rgba(0,22,40,0.85);border:1.5px solid #002D55;color:#E8F4FF;font-size:15px;outline:none;transition:border 0.2s;font-family:Inter,sans-serif;}
        .li:focus{border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.15);}
        .li::placeholder{color:#6B8FAF;}
        .lb{width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.4);transition:all 0.3s;font-family:Inter,sans-serif;letter-spacing:0.5px;}
        .lb:disabled{opacity:0.6;cursor:not-allowed;}
      `}</style>

      {/* BG hex decorations */}
      <div style={{position:'absolute',top:-40,left:-40,fontSize:180,color:'rgba(77,159,255,0.04)',pointerEvents:'none'}}>⬡</div>
      <div style={{position:'absolute',bottom:-40,right:-40,fontSize:180,color:'rgba(77,159,255,0.04)',pointerEvents:'none'}}>⬡</div>
      <div style={{position:'absolute',top:'30%',right:-60,fontSize:120,color:'rgba(77,159,255,0.03)',pointerEvents:'none'}}>⬡</div>

      {/* ── PR4 LOGO — Floating top ── */}
      <div style={{animation:'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite',marginBottom:40,textAlign:'center'}}>
        <PRLogo />
      </div>

      {/* Glass Card */}
      <div style={{width:'100%',maxWidth:420,background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:'36px 32px',backdropFilter:'blur(20px)',WebkitBackdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.5),inset 0 1px 0 rgba(77,159,255,0.1)',animation:'fadeUp 0.7s ease 0.15s both'}}>

        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,color:'#E8F4FF',textAlign:'center',margin:'0 0 6px'}}>Welcome Back</h1>
        <p style={{textAlign:'center',color:'#6B8FAF',fontSize:14,marginBottom:28}}>Apne account mein login karo</p>

        {error && (
          <div style={{background:'rgba(239,68,68,0.12)',border:'1px solid rgba(239,68,68,0.3)',borderRadius:10,padding:'12px 16px',marginBottom:20,color:'#FCA5A5',fontSize:14,textAlign:'center'}}>
            ⚠️ {error}
          </div>
        )}

        <form onSubmit={handleLogin} style={{display:'flex',flexDirection:'column',gap:16}}>
          <div>
            <label style={{fontSize:12,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:6,letterSpacing:0.5}}>EMAIL / ROLL NUMBER</label>
            <input type="text" value={email} onChange={e=>setEmail(e.target.value)} placeholder="student@proverank.com" required className="li"/>
          </div>
          <div>
            <label style={{fontSize:12,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:6,letterSpacing:0.5}}>PASSWORD</label>
            <div style={{position:'relative'}}>
              <input type={showPass?'text':'password'} value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••••••" required className="li" style={{paddingRight:48}}/>
              <button type="button" onClick={()=>setShowPass(!showPass)} style={{position:'absolute',right:14,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'#6B8FAF',cursor:'pointer',fontSize:16}}>
                {showPass?'🙈':'👁️'}
              </button>
            </div>
          </div>
          <div style={{textAlign:'right',marginTop:-8}}>
            <button type="button" style={{background:'none',border:'none',color:'#4D9FFF',fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>Forgot password?</button>
          </div>
          <button type="submit" disabled={loading} className="lb">
            {loading?'⟳ Logging in...':'Login →'}
          </button>
        </form>

        <div style={{textAlign:'center',marginTop:24,fontSize:14,color:'#6B8FAF'}}>
          Account nahi hai?{' '}
          <a href="/register" style={{color:'#4D9FFF',fontWeight:600,textDecoration:'none'}}>Register karo</a>
        </div>
      </div>

      <div style={{marginTop:32,color:'#3A5A7A',fontSize:11,letterSpacing:3,textTransform:'uppercase',animation:'pulse 3s infinite'}}>
        NEET · NEET PG · JEE · CUET
      </div>
    </div>
  );
}
ENDOFFILE

echo "✅ 1/2 — Login page updated!"

# ════════════════════════════════════════════════════════════
# REGISTER PAGE — Direct overwrite
# ════════════════════════════════════════════════════════════
cat > ~/workspace/frontend/app/register/page.tsx << 'ENDOFFILE'
'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

function PRLogo() {
  const size = 60; const r = 30; const cx = 30; const cy = 30;
  const outer = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.88*Math.cos(a)},${cy+r*0.88*Math.sin(a)}`;}).join(' ');
  const inner = Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;}).join(' ');
  return (
    <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:8}}>
      <svg width={size} height={size} viewBox="0 0 60 60">
        <defs><filter id="g2"><feGaussianBlur stdDeviation="2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
        <polygon points={outer} fill="none" stroke="rgba(77,159,255,0.35)" strokeWidth="1" filter="url(#g2)"/>
        <polygon points={inner} fill="none" stroke="#4D9FFF" strokeWidth="1.8" filter="url(#g2)"/>
        {Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return <circle key={i} cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)} r={2.8} fill="#4D9FFF" filter="url(#g2)"/>;  })}
        <text x={cx} y={cy+6} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="19" fontWeight="700" fill="#4D9FFF" filter="url(#g2)">PR</text>
      </svg>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',letterSpacing:1}}>
        ProveRank
      </div>
      <div style={{fontSize:10,color:'#6B8FAF',letterSpacing:4,textTransform:'uppercase'}}>Online Test Platform</div>
    </div>
  );
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

  useEffect(() => {
    setMounted(true);
    if (getToken()) router.push('/dashboard');
  }, [router]);

  const set = (k: string, v: string) => setForm(f=>({...f,[k]:v}));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setSuccess('');
    if (form.password !== form.confirm) { setError('Passwords match nahi karte!'); return; }
    if (!terms) { setError('Terms & Conditions accept karo!'); return; }
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/register`, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({name:form.name,email:form.email,phone:form.phone,password:form.password,termsAccepted:true}),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message||'Registration failed');
      setSuccess('✅ Account ban gaya! Login karo ab.');
      setTimeout(()=>router.push('/login'),2000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Registration nahi hua');
    } finally { setLoading(false); }
  };

  if (!mounted) return null;

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',padding:'24px 16px',position:'relative',overflow:'hidden'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:0.4}50%{opacity:0.8}}
        .ri{width:100%;padding:13px 16px;border-radius:10px;background:rgba(0,22,40,0.85);border:1.5px solid #002D55;color:#E8F4FF;font-size:14px;outline:none;transition:border 0.2s;font-family:Inter,sans-serif;}
        .ri:focus{border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.15);}
        .ri::placeholder{color:#6B8FAF;}
        .rb{width:100%;padding:14px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:15px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.4);font-family:Inter,sans-serif;}
        .rb:disabled{opacity:0.6;cursor:not-allowed;}
      `}</style>

      <div style={{position:'absolute',top:-40,left:-40,fontSize:180,color:'rgba(77,159,255,0.04)',pointerEvents:'none'}}>⬡</div>
      <div style={{position:'absolute',bottom:-40,right:-40,fontSize:180,color:'rgba(77,159,255,0.04)',pointerEvents:'none'}}>⬡</div>

      {/* ── PR4 LOGO ── */}
      <div style={{animation:'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite',marginBottom:28,textAlign:'center'}}>
        <PRLogo />
      </div>

      {/* Glass Card */}
      <div style={{width:'100%',maxWidth:440,background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:'28px 28px',backdropFilter:'blur(20px)',WebkitBackdropFilter:'blur(20px)',boxShadow:'0 8px 40px rgba(0,0,0,0.5)',animation:'fadeUp 0.7s ease 0.15s both'}}>

        <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:'#E8F4FF',textAlign:'center',margin:'0 0 4px'}}>Create Account</h1>
        <p style={{textAlign:'center',color:'#6B8FAF',fontSize:13,marginBottom:22}}>ProveRank par apna account banao</p>

        {error && <div style={{background:'rgba(239,68,68,0.12)',border:'1px solid rgba(239,68,68,0.3)',borderRadius:10,padding:'10px 16px',marginBottom:14,color:'#FCA5A5',fontSize:13,textAlign:'center'}}>⚠️ {error}</div>}
        {success && <div style={{background:'rgba(34,197,94,0.12)',border:'1px solid rgba(34,197,94,0.3)',borderRadius:10,padding:'10px 16px',marginBottom:14,color:'#86EFAC',fontSize:13,textAlign:'center'}}>{success}</div>}

        <form onSubmit={handleSubmit} style={{display:'flex',flexDirection:'column',gap:12}}>
          {[
            {k:'name',l:'FULL NAME',t:'text',p:'Apna poora naam'},
            {k:'email',l:'EMAIL',t:'email',p:'email@example.com'},
            {k:'phone',l:'PHONE',t:'tel',p:'10-digit number'},
          ].map(({k,l,t,p})=>(
            <div key={k}>
              <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:4,letterSpacing:0.5}}>{l}</label>
              <input type={t} value={form[k as keyof typeof form]} onChange={e=>set(k,e.target.value)} placeholder={p} required={k!=='phone'} className="ri"/>
            </div>
          ))}
          <div>
            <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:4,letterSpacing:0.5}}>PASSWORD</label>
            <div style={{position:'relative'}}>
              <input type={showPass?'text':'password'} value={form.password} onChange={e=>set('password',e.target.value)} placeholder="Min 8 characters" required className="ri" style={{paddingRight:44}}/>
              <button type="button" onClick={()=>setShowPass(!showPass)} style={{position:'absolute',right:12,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'#6B8FAF',cursor:'pointer',fontSize:14}}>
                {showPass?'🙈':'👁️'}
              </button>
            </div>
          </div>
          <div>
            <label style={{fontSize:11,color:'#4D9FFF',fontWeight:600,display:'block',marginBottom:4,letterSpacing:0.5}}>CONFIRM PASSWORD</label>
            <input type="password" value={form.confirm} onChange={e=>set('confirm',e.target.value)} placeholder="Password dobara likho" required className="ri"/>
          </div>

          {/* Terms checkbox */}
          <div style={{display:'flex',alignItems:'flex-start',gap:10,marginTop:4}}>
            <div onClick={()=>setTerms(!terms)} style={{width:18,height:18,borderRadius:4,border:`2px solid ${terms?'#4D9FFF':'#002D55'}`,background:terms?'#4D9FFF':'transparent',cursor:'pointer',flexShrink:0,marginTop:1,display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,color:'white',transition:'all 0.2s'}}>
              {terms&&'✓'}
            </div>
            <span style={{fontSize:12,color:'#6B8FAF',lineHeight:1.6}}>
              Main <a href="/terms" style={{color:'#4D9FFF',textDecoration:'none',fontWeight:600}}>Terms & Conditions</a> se agree karta/karti hoon
            </span>
          </div>

          <button type="submit" disabled={loading} className="rb" style={{marginTop:6}}>
            {loading?'⟳ Creating account...':'Create Account →'}
          </button>
        </form>

        <div style={{textAlign:'center',marginTop:18,fontSize:14,color:'#6B8FAF'}}>
          Already account hai?{' '}
          <a href="/login" style={{color:'#4D9FFF',fontWeight:600,textDecoration:'none'}}>Login karo</a>
        </div>
      </div>
      <div style={{marginTop:24,color:'#3A5A7A',fontSize:11,letterSpacing:3,textTransform:'uppercase',animation:'pulse 3s infinite'}}>NEET Pattern Online Test Platform</div>
    </div>
  );
}
ENDOFFILE

echo "✅ 2/2 — Register page updated!"

# ════════════════════════════════════════════════════════════
# VERIFY
# ════════════════════════════════════════════════════════════
echo ""
echo "── Verify ──"
grep -c "PRLogo\|ProveRank\|gradient" ~/workspace/frontend/app/login/page.tsx && echo "✅ Login — PR4 Logo confirmed"
grep -c "PRLogo\|ProveRank\|gradient" ~/workspace/frontend/app/register/page.tsx && echo "✅ Register — PR4 Logo confirmed"

# ════════════════════════════════════════════════════════════
# GIT PUSH
# ════════════════════════════════════════════════════════════
cd ~/workspace
git add -A
git commit -m "fix: PR4 Logo final — correct app/ folder path

- Correct path: frontend/app/login + register
- PR4 Hexagon SVG (outer+inner hex + 6 corner dots)
- ProveRank Blue→White→Blue gradient text
- Online Test Platform tagline
- N6 dark theme + L2 Glassmorphism"
git push origin main

echo ""
echo "🎉 DONE! Ab /login aur /register refresh karo"
echo "PR4 Logo + ProveRank gradient text dikhega!"
