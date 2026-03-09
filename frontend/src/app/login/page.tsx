'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { setToken, setRole, getToken } from '@/lib/auth';

// Inline PRLogo (no import needed)
function PRLogo({ size = 48, showName = false, showTag = false, nameSize = 20 }: {
  size?: number; showName?: boolean; showTag?: boolean; nameSize?: number;
}) {
  const r = size / 2;
  const cx = r; const cy = r;
  const pts = Array.from({ length: 6 }, (_, i) => {
    const a = (Math.PI / 180) * (60 * i - 30);
    return `${cx + r * 0.85 * Math.cos(a)},${cy + r * 0.85 * Math.sin(a)}`;
  }).join(' ');
  return (
    <div style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <defs>
          <filter id="glow"><feGaussianBlur stdDeviation="2" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
        </defs>
        <polygon points={pts} fill="none" stroke="rgba(77,159,255,0.4)" strokeWidth="1" filter="url(#glow)"/>
        <polygon points={Array.from({ length: 6 }, (_, i) => {
          const a = (Math.PI / 180) * (60 * i - 30);
          return `${cx + r * 0.72 * Math.cos(a)},${cy + r * 0.72 * Math.sin(a)}`;
        }).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="1.5" filter="url(#glow)"/>
        {Array.from({ length: 6 }, (_, i) => {
          const a = (Math.PI / 180) * (60 * i - 30);
          return <circle key={i} cx={cx + r * 0.85 * Math.cos(a)} cy={cy + r * 0.85 * Math.sin(a)} r={r * 0.07} fill="#4D9FFF" filter="url(#glow)"/>;
        })}
        <text x={cx} y={cy + r * 0.38} textAnchor="middle" fontFamily="Playfair Display, serif" fontSize={r * 0.62} fontWeight="700" fill="#4D9FFF" filter="url(#glow)">PR</text>
      </svg>
      {showName && (
        <div style={{ fontFamily: 'Playfair Display, serif', fontSize: nameSize, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', letterSpacing: 1 }}>
          ProveRank
        </div>
      )}
      {showTag && (
        <div style={{ fontSize: nameSize * 0.45, color: '#6B8FAF', letterSpacing: 4, textTransform: 'uppercase' }}>
          Online Test Platform
        </div>
      )}
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
    const token = getToken();
    if (token) router.push('/dashboard');
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
    <div style={{ minHeight: '100vh', background: 'radial-gradient(ellipse at 20% 50%, #001628 0%, #000A18 60%, #000510 100%)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter, sans-serif', padding: '24px 16px', position: 'relative', overflow: 'hidden' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-8px)} }
        @keyframes fadeUp { from{opacity:0;transform:translateY(24px)} to{opacity:1;transform:translateY(0)} }
        @keyframes pulse { 0%,100%{opacity:0.4} 50%{opacity:0.8} }
        .li { width:100%;padding:14px 16px;border-radius:10px;background:rgba(0,22,40,0.8);border:1.5px solid #002D55;color:#E8F4FF;font-size:15px;outline:none;transition:border 0.2s;font-family:Inter,sans-serif; }
        .li:focus { border-color:#4D9FFF;box-shadow:0 0 0 3px rgba(77,159,255,0.12); }
        .li::placeholder { color:#6B8FAF; }
        .lb { width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:16px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.35);transition:all 0.3s;font-family:Inter,sans-serif; }
        .lb:disabled { opacity:0.6;cursor:not-allowed; }
      `}</style>

      {/* BG hex */}
      <div style={{ position:'absolute', top:-40, left:-40, fontSize:160, color:'rgba(77,159,255,0.04)', pointerEvents:'none' }}>⬡</div>
      <div style={{ position:'absolute', bottom:-40, right:-40, fontSize:160, color:'rgba(77,159,255,0.04)', pointerEvents:'none' }}>⬡</div>

      {/* PR4 LOGO */}
      <div style={{ animation: 'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite', marginBottom: 36, textAlign: 'center' }}>
        <PRLogo size={60} showName showTag nameSize={28} />
      </div>

      {/* Glass Card */}
      <div style={{ width:'100%', maxWidth:420, background:'rgba(0,22,40,0.75)', border:'1px solid rgba(77,159,255,0.2)', borderRadius:20, padding:'36px 32px', backdropFilter:'blur(20px)', WebkitBackdropFilter:'blur(20px)', boxShadow:'0 8px 40px rgba(0,0,0,0.5)', animation:'fadeUp 0.7s ease 0.1s both' }}>
        <h1 style={{ fontFamily:'Playfair Display,serif', fontSize:26, fontWeight:700, color:'#E8F4FF', textAlign:'center', margin:'0 0 6px' }}>Welcome Back</h1>
        <p style={{ textAlign:'center', color:'#6B8FAF', fontSize:14, marginBottom:28 }}>Apne account mein login karo</p>

        {error && <div style={{ background:'rgba(239,68,68,0.12)', border:'1px solid rgba(239,68,68,0.3)', borderRadius:10, padding:'12px 16px', marginBottom:20, color:'#FCA5A5', fontSize:14, textAlign:'center' }}>⚠️ {error}</div>}

        <form onSubmit={handleLogin} style={{ display:'flex', flexDirection:'column', gap:16 }}>
          <div>
            <label style={{ fontSize:12, color:'#4D9FFF', fontWeight:600, display:'block', marginBottom:6, letterSpacing:0.5 }}>EMAIL / ROLL NUMBER</label>
            <input type="text" value={email} onChange={e=>setEmail(e.target.value)} placeholder="student@proverank.com" required className="li" />
          </div>
          <div>
            <label style={{ fontSize:12, color:'#4D9FFF', fontWeight:600, display:'block', marginBottom:6, letterSpacing:0.5 }}>PASSWORD</label>
            <div style={{ position:'relative' }}>
              <input type={showPass?'text':'password'} value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••••••" required className="li" style={{ paddingRight:48 }} />
              <button type="button" onClick={()=>setShowPass(!showPass)} style={{ position:'absolute', right:14, top:'50%', transform:'translateY(-50%)', background:'none', border:'none', color:'#6B8FAF', cursor:'pointer', fontSize:16 }}>{showPass?'🙈':'👁️'}</button>
            </div>
          </div>
          <div style={{ textAlign:'right', marginTop:-8 }}>
            <button type="button" style={{ background:'none', border:'none', color:'#4D9FFF', fontSize:13, cursor:'pointer', fontFamily:'Inter,sans-serif' }}>Forgot password?</button>
          </div>
          <button type="submit" disabled={loading} className="lb">{loading?'⟳ Logging in...':'Login →'}</button>
        </form>

        <div style={{ textAlign:'center', marginTop:24, fontSize:14, color:'#6B8FAF' }}>
          Account nahi hai? <a href="/register" style={{ color:'#4D9FFF', fontWeight:600, textDecoration:'none' }}>Register karo</a>
        </div>
      </div>

      <div style={{ marginTop:28, color:'#3A5A7A', fontSize:12, letterSpacing:2, textTransform:'uppercase', animation:'pulse 3s infinite' }}>
        NEET Pattern Online Test Platform
      </div>
    </div>
  );
}
