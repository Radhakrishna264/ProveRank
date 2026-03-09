'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

function PRLogo({ size = 48, showName = false, showTag = false, nameSize = 20 }: {
  size?: number; showName?: boolean; showTag?: boolean; nameSize?: number;
}) {
  const r = size / 2; const cx = r; const cy = r;
  const pts = Array.from({ length: 6 }, (_, i) => {
    const a = (Math.PI / 180) * (60 * i - 30);
    return `${cx + r * 0.85 * Math.cos(a)},${cy + r * 0.85 * Math.sin(a)}`;
  }).join(' ');
  return (
    <div style={{ display:'inline-flex', flexDirection:'column', alignItems:'center', gap:6 }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <defs><filter id="glow2"><feGaussianBlur stdDeviation="2" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
        <polygon points={pts} fill="none" stroke="rgba(77,159,255,0.4)" strokeWidth="1" filter="url(#glow2)"/>
        <polygon points={Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="1.5" filter="url(#glow2)"/>
        {Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return <circle key={i} cx={cx+r*0.85*Math.cos(a)} cy={cy+r*0.85*Math.sin(a)} r={r*0.07} fill="#4D9FFF" filter="url(#glow2)"/>;  })}
        <text x={cx} y={cy+r*0.38} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize={r*0.62} fontWeight="700" fill="#4D9FFF" filter="url(#glow2)">PR</text>
      </svg>
      {showName && <div style={{ fontFamily:'Playfair Display,serif', fontSize:nameSize, fontWeight:700, background:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent', letterSpacing:1 }}>ProveRank</div>}
      {showTag && <div style={{ fontSize:nameSize*0.45, color:'#6B8FAF', letterSpacing:4, textTransform:'uppercase' }}>Online Test Platform</div>}
    </div>
  );
}

export default function RegisterPage() {
  const router = useRouter();
  const [form, setForm] = useState({ name:'', email:'', phone:'', password:'', confirmPassword:'' });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (getToken()) router.push('/dashboard');
  }, [router]);

  const handleChange = (k: string, v: string) => setForm(f=>({...f,[k]:v}));

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setSuccess('');
    if (form.password !== form.confirmPassword) { setError('Passwords match nahi karte!'); return; }
    if (!termsAccepted) { setError('Terms & Conditions accept karo pehle!'); return; }
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/register`, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ name:form.name, email:form.email, phone:form.phone, password:form.password, termsAccepted }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message||'Registration failed');
      setSuccess('✅ Account ban gaya! Login karo ab.');
      setTimeout(()=>router.push('/login'), 2000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Registration nahi hua');
    } finally { setLoading(false); }
  };

  if (!mounted) return null;

  return (
    <div style={{ minHeight:'100vh', background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', fontFamily:'Inter,sans-serif', padding:'24px 16px', position:'relative', overflow:'hidden' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:0.4}50%{opacity:0.8}}
        .ri{width:100%;padding:13px 16px;border-radius:10px;background:rgba(0,22,40,0.8);border:1.5px solid #002D55;color:#E8F4FF;font-size:14px;outline:none;transition:border 0.2s;font-family:Inter,sans-serif;}
        .ri:focus{border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.12);}
        .ri::placeholder{color:#6B8FAF;}
        .rb{width:100%;padding:14px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.35);transition:all 0.3s;font-family:Inter,sans-serif;}
        .rb:disabled{opacity:0.6;cursor:not-allowed;}
      `}</style>

      <div style={{ position:'absolute', top:-40, left:-40, fontSize:160, color:'rgba(77,159,255,0.04)', pointerEvents:'none' }}>⬡</div>
      <div style={{ position:'absolute', bottom:-40, right:-40, fontSize:160, color:'rgba(77,159,255,0.04)', pointerEvents:'none' }}>⬡</div>

      {/* PR4 LOGO */}
      <div style={{ animation:'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite', marginBottom:28, textAlign:'center' }}>
        <PRLogo size={56} showName showTag nameSize={26} />
      </div>

      {/* Glass Card */}
      <div style={{ width:'100%', maxWidth:440, background:'rgba(0,22,40,0.75)', border:'1px solid rgba(77,159,255,0.2)', borderRadius:20, padding:'32px 28px', backdropFilter:'blur(20px)', WebkitBackdropFilter:'blur(20px)', boxShadow:'0 8px 40px rgba(0,0,0,0.5)', animation:'fadeUp 0.7s ease 0.1s both' }}>
        <h1 style={{ fontFamily:'Playfair Display,serif', fontSize:24, fontWeight:700, color:'#E8F4FF', textAlign:'center', margin:'0 0 4px' }}>Create Account</h1>
        <p style={{ textAlign:'center', color:'#6B8FAF', fontSize:13, marginBottom:24 }}>ProveRank par apna account banao</p>

        {error && <div style={{ background:'rgba(239,68,68,0.12)', border:'1px solid rgba(239,68,68,0.3)', borderRadius:10, padding:'11px 16px', marginBottom:16, color:'#FCA5A5', fontSize:13, textAlign:'center' }}>⚠️ {error}</div>}
        {success && <div style={{ background:'rgba(34,197,94,0.12)', border:'1px solid rgba(34,197,94,0.3)', borderRadius:10, padding:'11px 16px', marginBottom:16, color:'#86EFAC', fontSize:13, textAlign:'center' }}>{success}</div>}

        <form onSubmit={handleRegister} style={{ display:'flex', flexDirection:'column', gap:14 }}>
          {[
            { k:'name', label:'FULL NAME', type:'text', ph:'Apna poora naam likho' },
            { k:'email', label:'EMAIL', type:'email', ph:'email@example.com' },
            { k:'phone', label:'PHONE', type:'tel', ph:'10-digit mobile number' },
          ].map(({k,label,type,ph})=>(
            <div key={k}>
              <label style={{ fontSize:11, color:'#4D9FFF', fontWeight:600, display:'block', marginBottom:5, letterSpacing:0.5 }}>{label}</label>
              <input type={type} value={form[k as keyof typeof form]} onChange={e=>handleChange(k,e.target.value)} placeholder={ph} required={k!=='phone'} className="ri" />
            </div>
          ))}
          <div>
            <label style={{ fontSize:11, color:'#4D9FFF', fontWeight:600, display:'block', marginBottom:5, letterSpacing:0.5 }}>PASSWORD</label>
            <div style={{ position:'relative' }}>
              <input type={showPass?'text':'password'} value={form.password} onChange={e=>handleChange('password',e.target.value)} placeholder="Min 8 characters" required className="ri" style={{ paddingRight:44 }} />
              <button type="button" onClick={()=>setShowPass(!showPass)} style={{ position:'absolute', right:12, top:'50%', transform:'translateY(-50%)', background:'none', border:'none', color:'#6B8FAF', cursor:'pointer', fontSize:15 }}>{showPass?'🙈':'👁️'}</button>
            </div>
          </div>
          <div>
            <label style={{ fontSize:11, color:'#4D9FFF', fontWeight:600, display:'block', marginBottom:5, letterSpacing:0.5 }}>CONFIRM PASSWORD</label>
            <input type="password" value={form.confirmPassword} onChange={e=>handleChange('confirmPassword',e.target.value)} placeholder="Password dobara likho" required className="ri" />
          </div>
          <div style={{ display:'flex', alignItems:'flex-start', gap:10, marginTop:4 }}>
            <div onClick={()=>setTermsAccepted(!termsAccepted)} style={{ width:18, height:18, borderRadius:4, border:`2px solid ${termsAccepted?'#4D9FFF':'#002D55'}`, background:termsAccepted?'#4D9FFF':'transparent', cursor:'pointer', flexShrink:0, marginTop:2, display:'flex', alignItems:'center', justifyContent:'center', fontSize:11, color:'white', transition:'all 0.2s' }}>{termsAccepted&&'✓'}</div>
            <span style={{ fontSize:12, color:'#6B8FAF', lineHeight:1.5 }}>Main <a href="/terms" style={{ color:'#4D9FFF', textDecoration:'none', fontWeight:600 }}>Terms & Conditions</a> se agree karta/karti hoon</span>
          </div>
          <button type="submit" disabled={loading} className="rb" style={{ marginTop:8 }}>{loading?'⟳ Creating account...':'Create Account →'}</button>
        </form>

        <div style={{ textAlign:'center', marginTop:20, fontSize:14, color:'#6B8FAF' }}>
          Already account hai? <a href="/login" style={{ color:'#4D9FFF', fontWeight:600, textDecoration:'none' }}>Login karo</a>
        </div>
      </div>
      <div style={{ marginTop:24, color:'#3A5A7A', fontSize:12, letterSpacing:2, textTransform:'uppercase', animation:'pulse 3s infinite' }}>NEET Pattern Online Test Platform</div>
    </div>
  );
}
