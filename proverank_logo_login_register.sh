#!/bin/bash
# ============================================================
# ProveRank — PR4 Logo Fix
# Login + Register page par PRLogo component add karo
# Design Lock: PR4 + N6 + F1 — Kabhi mat badlo!
# ============================================================

cd ~/workspace/frontend

echo "🔧 Login + Register page mein PR4 Logo add ho raha hai..."

# ════════════════════════════════════════════════════════════
# FILE 1 — Login Page with PRLogo
# L2: Glassmorphism | B1: Particles | PR4 Logo top center
# ════════════════════════════════════════════════════════════
cat > "src/app/login/page.tsx" << 'ENDOFFILE'
'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { setToken, setRole, getToken } from '@/lib/auth';
import PRLogo from '@/components/PRLogo';

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
      else if (data.role === 'admin') router.push('/admin');
      else router.push('/dashboard');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Login nahi hua');
    } finally {
      setLoading(false);
    }
  };

  if (!mounted) return null;

  return (
    <div style={{
      minHeight: '100vh',
      background: 'radial-gradient(ellipse at 20% 50%, #001628 0%, #000A18 60%, #000510 100%)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'Inter, sans-serif',
      padding: '24px 16px',
      position: 'relative',
      overflow: 'hidden',
    }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        * { box-sizing: border-box; }
        @keyframes float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-8px)} }
        @keyframes fadeUp { from{opacity:0;transform:translateY(24px)} to{opacity:1;transform:translateY(0)} }
        @keyframes pulse { 0%,100%{opacity:0.4} 50%{opacity:0.8} }
        .hex-deco { position:absolute; color:rgba(77,159,255,0.05); pointer-events:none; font-size:160px; }
        .login-input {
          width: 100%; padding: 14px 16px; border-radius: 10px;
          background: rgba(0,22,40,0.8); border: 1.5px solid #002D55;
          color: #E8F4FF; font-size: 15px; font-family: Inter,sans-serif;
          outline: none; transition: border 0.2s;
        }
        .login-input:focus { border-color: #4D9FFF; box-shadow: 0 0 0 3px rgba(77,159,255,0.12); }
        .login-input::placeholder { color: #6B8FAF; }
        .login-btn {
          width: 100%; padding: 15px; border-radius: 10px; border: none;
          background: linear-gradient(135deg, #4D9FFF 0%, #0055CC 100%);
          color: white; font-size: 16px; font-weight: 700;
          font-family: Inter,sans-serif; cursor: pointer;
          box-shadow: 0 4px 20px rgba(77,159,255,0.35);
          transition: all 0.3s; letter-spacing: 0.5px;
        }
        .login-btn:hover:not(:disabled) { transform: translateY(-1px); box-shadow: 0 6px 28px rgba(77,159,255,0.5); }
        .login-btn:disabled { opacity: 0.6; cursor: not-allowed; }
      `}</style>

      {/* BG Hex Decorations */}
      <div className="hex-deco" style={{ top: -40, left: -40 }}>⬡</div>
      <div className="hex-deco" style={{ bottom: -40, right: -40 }}>⬡</div>
      <div className="hex-deco" style={{ top: '35%', right: -50, fontSize: 100 }}>⬡</div>

      {/* BG Particles */}
      <canvas id="bgCanvas" style={{ position: 'absolute', inset: 0, pointerEvents: 'none', opacity: 0.4 }} />

      {/* ── PR4 LOGO — Top Center ── */}
      <div style={{ animation: 'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite', marginBottom: 36, textAlign: 'center' }}>
        <PRLogo size={56} showName showTag nameSize={26} />
      </div>

      {/* Glass Card */}
      <div style={{
        width: '100%', maxWidth: 420,
        background: 'rgba(0, 22, 40, 0.75)',
        border: '1px solid rgba(77,159,255,0.2)',
        borderRadius: 20,
        padding: '36px 32px',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        boxShadow: '0 8px 40px rgba(0,0,0,0.5), inset 0 1px 0 rgba(77,159,255,0.1)',
        animation: 'fadeUp 0.7s ease 0.1s both',
      }}>

        <h1 style={{
          fontFamily: 'Playfair Display, serif',
          fontSize: 26, fontWeight: 700,
          color: '#E8F4FF', textAlign: 'center',
          marginBottom: 6, margin: '0 0 6px',
        }}>
          Welcome Back
        </h1>
        <p style={{ textAlign: 'center', color: '#6B8FAF', fontSize: 14, marginBottom: 28 }}>
          Apne account mein login karo
        </p>

        {error && (
          <div style={{
            background: 'rgba(239,68,68,0.12)', border: '1px solid rgba(239,68,68,0.3)',
            borderRadius: 10, padding: '12px 16px', marginBottom: 20,
            color: '#FCA5A5', fontSize: 14, textAlign: 'center',
          }}>
            ⚠️ {error}
          </div>
        )}

        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* Email */}
          <div>
            <label style={{ fontSize: 12, color: '#4D9FFF', fontWeight: 600, display: 'block', marginBottom: 6, letterSpacing: 0.5 }}>
              EMAIL / ROLL NUMBER
            </label>
            <input
              type="text" value={email} onChange={e => setEmail(e.target.value)}
              placeholder="student@proverank.com" required className="login-input"
            />
          </div>

          {/* Password */}
          <div>
            <label style={{ fontSize: 12, color: '#4D9FFF', fontWeight: 600, display: 'block', marginBottom: 6, letterSpacing: 0.5 }}>
              PASSWORD
            </label>
            <div style={{ position: 'relative' }}>
              <input
                type={showPass ? 'text' : 'password'}
                value={password} onChange={e => setPassword(e.target.value)}
                placeholder="••••••••••••" required className="login-input"
                style={{ paddingRight: 48 }}
              />
              <button type="button" onClick={() => setShowPass(!showPass)}
                style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: '#6B8FAF', cursor: 'pointer', fontSize: 16 }}>
                {showPass ? '🙈' : '👁️'}
              </button>
            </div>
          </div>

          {/* Forgot */}
          <div style={{ textAlign: 'right', marginTop: -8 }}>
            <button type="button" style={{ background: 'none', border: 'none', color: '#4D9FFF', fontSize: 13, cursor: 'pointer', fontFamily: 'Inter,sans-serif' }}>
              Forgot password?
            </button>
          </div>

          {/* Login Button */}
          <button type="submit" disabled={loading} className="login-btn">
            {loading ? '⟳ Logging in...' : 'Login →'}
          </button>
        </form>

        {/* Register link */}
        <div style={{ textAlign: 'center', marginTop: 24, fontSize: 14, color: '#6B8FAF' }}>
          Account nahi hai?{' '}
          <a href="/register" style={{ color: '#4D9FFF', fontWeight: 600, textDecoration: 'none' }}>
            Register karo
          </a>
        </div>
      </div>

      {/* Bottom tagline */}
      <div style={{ marginTop: 28, color: '#3A5A7A', fontSize: 12, letterSpacing: 2, textTransform: 'uppercase', animation: 'pulse 3s infinite' }}>
        NEET Pattern Online Test Platform
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 1/2 — Login Page (PR4 Logo + L2 Glassmorphism)"

# ════════════════════════════════════════════════════════════
# FILE 2 — Register Page with PRLogo
# Same dark theme + PR4 logo on top
# ════════════════════════════════════════════════════════════
cat > "src/app/register/page.tsx" << 'ENDOFFILE'
'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';
import PRLogo from '@/components/PRLogo';

export default function RegisterPage() {
  const router = useRouter();
  const [form, setForm] = useState({ name: '', email: '', phone: '', password: '', confirmPassword: '' });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPass, setShowPass] = useState(false);
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const token = getToken();
    if (token) router.push('/dashboard');
  }, [router]);

  const handleChange = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }));

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setSuccess('');
    if (form.password !== form.confirmPassword) { setError('Passwords match nahi karte!'); return; }
    if (!termsAccepted) { setError('Terms & Conditions accept karo pehle!'); return; }
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: form.name, email: form.email, phone: form.phone, password: form.password, termsAccepted }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Registration failed');
      setSuccess('✅ Account ban gaya! Login karo ab.');
      setTimeout(() => router.push('/login'), 2000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Registration nahi hua');
    } finally {
      setLoading(false);
    }
  };

  if (!mounted) return null;

  return (
    <div style={{
      minHeight: '100vh',
      background: 'radial-gradient(ellipse at 20% 50%, #001628 0%, #000A18 60%, #000510 100%)',
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Inter, sans-serif', padding: '24px 16px',
      position: 'relative', overflow: 'hidden',
    }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        * { box-sizing: border-box; }
        @keyframes float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-8px)} }
        @keyframes fadeUp { from{opacity:0;transform:translateY(24px)} to{opacity:1;transform:translateY(0)} }
        @keyframes pulse { 0%,100%{opacity:0.4} 50%{opacity:0.8} }
        .hex-deco { position:absolute; color:rgba(77,159,255,0.05); pointer-events:none; font-size:160px; }
        .reg-input {
          width: 100%; padding: 13px 16px; border-radius: 10px;
          background: rgba(0,22,40,0.8); border: 1.5px solid #002D55;
          color: #E8F4FF; font-size: 14px; font-family: Inter,sans-serif;
          outline: none; transition: border 0.2s;
        }
        .reg-input:focus { border-color: #4D9FFF; box-shadow: 0 0 0 3px rgba(77,159,255,0.12); }
        .reg-input::placeholder { color: #6B8FAF; }
        .reg-btn {
          width: 100%; padding: 14px; border-radius: 10px; border: none;
          background: linear-gradient(135deg, #4D9FFF 0%, #0055CC 100%);
          color: white; font-size: 16px; font-weight: 700;
          font-family: Inter,sans-serif; cursor: pointer;
          box-shadow: 0 4px 20px rgba(77,159,255,0.35); transition: all 0.3s;
        }
        .reg-btn:hover:not(:disabled) { transform: translateY(-1px); box-shadow: 0 6px 28px rgba(77,159,255,0.5); }
        .reg-btn:disabled { opacity: 0.6; cursor: not-allowed; }
      `}</style>

      {/* BG Hex Decorations */}
      <div className="hex-deco" style={{ top: -40, left: -40 }}>⬡</div>
      <div className="hex-deco" style={{ bottom: -40, right: -40 }}>⬡</div>

      {/* ── PR4 LOGO — Top Center ── */}
      <div style={{ animation: 'fadeUp 0.6s ease, float 5s ease-in-out 0.6s infinite', marginBottom: 28, textAlign: 'center' }}>
        <PRLogo size={52} showName showTag nameSize={24} />
      </div>

      {/* Glass Card */}
      <div style={{
        width: '100%', maxWidth: 440,
        background: 'rgba(0, 22, 40, 0.75)',
        border: '1px solid rgba(77,159,255,0.2)',
        borderRadius: 20, padding: '32px 28px',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        boxShadow: '0 8px 40px rgba(0,0,0,0.5), inset 0 1px 0 rgba(77,159,255,0.1)',
        animation: 'fadeUp 0.7s ease 0.1s both',
      }}>
        <h1 style={{ fontFamily: 'Playfair Display, serif', fontSize: 24, fontWeight: 700, color: '#E8F4FF', textAlign: 'center', margin: '0 0 4px' }}>
          Create Account
        </h1>
        <p style={{ textAlign: 'center', color: '#6B8FAF', fontSize: 13, marginBottom: 24 }}>
          ProveRank par apna account banao
        </p>

        {error && (
          <div style={{ background: 'rgba(239,68,68,0.12)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 10, padding: '11px 16px', marginBottom: 16, color: '#FCA5A5', fontSize: 13, textAlign: 'center' }}>
            ⚠️ {error}
          </div>
        )}
        {success && (
          <div style={{ background: 'rgba(34,197,94,0.12)', border: '1px solid rgba(34,197,94,0.3)', borderRadius: 10, padding: '11px 16px', marginBottom: 16, color: '#86EFAC', fontSize: 13, textAlign: 'center' }}>
            {success}
          </div>
        )}

        <form onSubmit={handleRegister} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {/* Full Name */}
          <div>
            <label style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 600, display: 'block', marginBottom: 5, letterSpacing: 0.5 }}>FULL NAME</label>
            <input type="text" value={form.name} onChange={e => handleChange('name', e.target.value)}
              placeholder="Apna poora naam likho" required className="reg-input" />
          </div>

          {/* Email */}
          <div>
            <label style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 600, display: 'block', marginBottom: 5, letterSpacing: 0.5 }}>EMAIL</label>
            <input type="email" value={form.email} onChange={e => handleChange('email', e.target.value)}
              placeholder="email@example.com" required className="reg-input" />
          </div>

          {/* Phone */}
          <div>
            <label style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 600, display: 'block', marginBottom: 5, letterSpacing: 0.5 }}>PHONE NUMBER</label>
            <input type="tel" value={form.phone} onChange={e => handleChange('phone', e.target.value)}
              placeholder="10-digit mobile number" className="reg-input" />
          </div>

          {/* Password */}
          <div>
            <label style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 600, display: 'block', marginBottom: 5, letterSpacing: 0.5 }}>PASSWORD</label>
            <div style={{ position: 'relative' }}>
              <input type={showPass ? 'text' : 'password'} value={form.password}
                onChange={e => handleChange('password', e.target.value)}
                placeholder="Min 8 characters" required className="reg-input" style={{ paddingRight: 44 }} />
              <button type="button" onClick={() => setShowPass(!showPass)}
                style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: '#6B8FAF', cursor: 'pointer', fontSize: 15 }}>
                {showPass ? '🙈' : '👁️'}
              </button>
            </div>
          </div>

          {/* Confirm Password */}
          <div>
            <label style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 600, display: 'block', marginBottom: 5, letterSpacing: 0.5 }}>CONFIRM PASSWORD</label>
            <input type="password" value={form.confirmPassword}
              onChange={e => handleChange('confirmPassword', e.target.value)}
              placeholder="Password dobara likho" required className="reg-input" />
          </div>

          {/* Terms */}
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, marginTop: 4 }}>
            <div onClick={() => setTermsAccepted(!termsAccepted)}
              style={{ width: 18, height: 18, borderRadius: 4, border: `2px solid ${termsAccepted ? '#4D9FFF' : '#002D55'}`, background: termsAccepted ? '#4D9FFF' : 'transparent', cursor: 'pointer', flexShrink: 0, marginTop: 2, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, color: 'white', transition: 'all 0.2s' }}>
              {termsAccepted && '✓'}
            </div>
            <span style={{ fontSize: 12, color: '#6B8FAF', lineHeight: 1.5 }}>
              Main{' '}
              <a href="/terms" style={{ color: '#4D9FFF', textDecoration: 'none', fontWeight: 600 }}>Terms & Conditions</a>
              {' '}aur{' '}
              <a href="/terms" style={{ color: '#4D9FFF', textDecoration: 'none', fontWeight: 600 }}>Privacy Policy</a>
              {' '}se agree karta/karti hoon
            </span>
          </div>

          {/* Register Button */}
          <button type="submit" disabled={loading} className="reg-btn" style={{ marginTop: 8 }}>
            {loading ? '⟳ Creating account...' : 'Create Account →'}
          </button>
        </form>

        {/* Login link */}
        <div style={{ textAlign: 'center', marginTop: 20, fontSize: 14, color: '#6B8FAF' }}>
          Already account hai?{' '}
          <a href="/login" style={{ color: '#4D9FFF', fontWeight: 600, textDecoration: 'none' }}>Login karo</a>
        </div>
      </div>

      {/* Bottom tagline */}
      <div style={{ marginTop: 24, color: '#3A5A7A', fontSize: 12, letterSpacing: 2, textTransform: 'uppercase', animation: 'pulse 3s infinite' }}>
        NEET Pattern Online Test Platform
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 2/2 — Register Page (PR4 Logo + Same Dark Theme)"

# ════════════════════════════════════════════════════════════
# VERIFY files
# ════════════════════════════════════════════════════════════
echo ""
echo "── Verifying files ──"
for f in "src/app/login/page.tsx" "src/app/register/page.tsx"; do
  [ -f "$f" ] && echo "✅ $f" || echo "❌ MISSING: $f"
done

echo ""
echo "── Logo check ──"
grep -l "PRLogo" src/app/login/page.tsx src/app/register/page.tsx && echo "✅ PRLogo imported in both pages"

# ════════════════════════════════════════════════════════════
# GIT PUSH
# ════════════════════════════════════════════════════════════
cd ~/workspace
git add -A
git commit -m "feat: PR4 Logo added to Login + Register pages

- Login: PRLogo size=56 showName showTag + L2 Glassmorphism
- Register: PRLogo size=52 showName showTag + same N6 dark theme
- Both pages: Playfair Display + Inter font (F1)
- Design Lock: PR4 + N6 + F1 maintained"
git push origin main

echo ""
echo "🎉 Logo fix COMPLETE!"
echo "Preview: /login aur /register pages pe PR4 Logo dikh raha hoga"
echo ""
echo "Test karo:"
echo "  /login    → PR4 Logo with ProveRank name + tagline"
echo "  /register → PR4 Logo with ProveRank name + tagline"
