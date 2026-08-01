'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'

// ── EXACT current logo — copied 1:1 from frontend/app/admin/x7k2p/page.tsx
// (Split Block Monogram, Blue+Cyan T1) so it matches the rest of the site. ──
function PRLogo({ size = 64 }: { size?: number }) {
  const blockSize = size * 0.94
  const pSize = Math.round(blockSize * 0.63)
  const rSize = Math.round(blockSize * 0.63)
  const fontSize = Math.round(pSize * 0.52)
  const radius = Math.round(pSize * 0.28)
  return (
    <div style={{ position: 'relative', width: blockSize, height: blockSize, flexShrink: 0, display: 'inline-flex' }}>
      <div style={{
        position: 'absolute', top: 0, left: 0,
        width: pSize, height: pSize,
        borderRadius: radius,
        background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: fontSize, fontWeight: 900, fontFamily: 'Inter,sans-serif',
        color: '#030810',
        boxShadow: '0 4px 16px rgba(77,159,255,0.4)'
      }}>P</div>
      <div style={{
        position: 'absolute', bottom: 0, right: 0,
        width: rSize, height: rSize,
        borderRadius: radius,
        background: 'rgba(0,212,255,0.1)',
        border: '1.5px solid rgba(0,212,255,0.45)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: fontSize, fontWeight: 900, fontFamily: 'Inter,sans-serif',
        color: '#00D4FF',
        backdropFilter: 'blur(8px)'
      }}>R</div>
    </div>
  )
}

export default function NotFound() {
  const [lang, setLang] = useState<'en' | 'hi'>('en')
  const [mounted, setMounted] = useState(false)
  const [dashboardHref, setDashboardHref] = useState('/dashboard')
  const [dashboardLabel, setDashboardLabel] = useState({ en: 'Back to Dashboard', hi: 'डैशबोर्ड पर वापस जाएं' })

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en' | 'hi'; if (sl) setLang(sl)
    // Smart return target — student panel users go to /dashboard, admin/superadmin go to /admin/x7k2p
    const role = localStorage.getItem('pr_role')
    if (role === 'admin' || role === 'superadmin') {
      setDashboardHref('/admin/x7k2p')
      setDashboardLabel({ en: 'Back to Admin Dashboard', hi: 'एडमिन डैशबोर्ड पर वापस जाएं' })
    }
  }, [])

  if (!mounted) return null

  return (
    <div style={{ minHeight: '100vh', background: 'radial-gradient(ellipse at 20% 20%,#001628 0%,#000A18 55%,#000510 100%)', position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter,sans-serif', textAlign: 'center', padding: '5%', color: '#E8F4FF' }}>
      <style>{`
        @keyframes pr404-orb1 { 0%,100%{ transform:translate(0,0) scale(1); } 50%{ transform:translate(30px,-40px) scale(1.15); } }
        @keyframes pr404-orb2 { 0%,100%{ transform:translate(0,0) scale(1); } 50%{ transform:translate(-40px,30px) scale(1.1); } }
        @keyframes pr404-orb3 { 0%,100%{ transform:translate(0,0) scale(1); } 50%{ transform:translate(20px,25px) scale(1.2); } }
        @keyframes pr404-fadeUp { from{ opacity:0; transform:translateY(24px); } to{ opacity:1; transform:translateY(0); } }
        @keyframes pr404-pulseGlow { 0%,100%{ box-shadow:0 0 40px 6px rgba(77,159,255,0.25); } 50%{ box-shadow:0 0 64px 14px rgba(0,212,255,0.4); } }
        @keyframes pr404-shimmer { 0%{ background-position:-200% center; } 100%{ background-position:200% center; } }
        @keyframes pr404-float { 0%,100%{ transform:translateY(0); } 50%{ transform:translateY(-10px); } }
        .pr404-orb { position:absolute; border-radius:50%; filter:blur(60px); pointer-events:none; }
        .pr404-btn-primary { padding:14px 32px; border-radius:12px; border:none; background:linear-gradient(135deg,#4D9FFF,#00D4FF); color:#030810; font-size:15px; font-weight:800; cursor:pointer; box-shadow:0 4px 24px rgba(77,159,255,0.45); transition:transform 0.25s ease, box-shadow 0.25s ease; }
        .pr404-btn-primary:hover { transform:translateY(-3px); box-shadow:0 8px 32px rgba(0,212,255,0.55); }
        .pr404-btn-ghost { padding:13px 26px; border-radius:12px; border:1.5px solid rgba(77,159,255,0.35); background:rgba(0,22,40,0.55); backdrop-filter:blur(10px); color:#E8F4FF; font-size:15px; font-weight:700; cursor:pointer; transition:all 0.25s ease; }
        .pr404-btn-ghost:hover { border-color:rgba(0,212,255,0.6); background:rgba(0,32,55,0.7); transform:translateY(-3px); }
        .pr404-toggle { padding:6px 14px; border-radius:20px; border:1.5px solid rgba(77,159,255,0.3); background:rgba(0,22,40,0.5); color:#9FC6FF; font-size:12px; font-weight:600; cursor:pointer; transition:all 0.2s ease; }
        .pr404-toggle:hover { border-color:rgba(77,159,255,0.6); color:#E8F4FF; }
      `}</style>

      {/* Ambient floating orbs — smooth, GPU-friendly, no canvas needed */}
      <div className="pr404-orb" style={{ width: 280, height: 280, top: '8%', left: '10%', background: 'rgba(77,159,255,0.22)', animation: 'pr404-orb1 9s ease-in-out infinite' }} />
      <div className="pr404-orb" style={{ width: 220, height: 220, bottom: '12%', right: '8%', background: 'rgba(0,212,255,0.18)', animation: 'pr404-orb2 11s ease-in-out infinite' }} />
      <div className="pr404-orb" style={{ width: 180, height: 180, top: '55%', left: '75%', background: 'rgba(120,90,255,0.14)', animation: 'pr404-orb3 8s ease-in-out infinite' }} />

      {/* Logo + animated glow ring */}
      <div style={{ position: 'relative', marginBottom: 28, animation: 'pr404-fadeUp 0.6s ease both, pr404-float 5s ease-in-out infinite 0.6s' }}>
        <div style={{ position: 'absolute', inset: -18, borderRadius: 28, animation: 'pr404-pulseGlow 3s ease-in-out infinite' }} />
        <PRLogo size={76} />
      </div>

      <div style={{
        fontFamily: 'Playfair Display,serif', fontSize: 'clamp(3.5rem,14vw,6rem)', fontWeight: 900, lineHeight: 1,
        marginBottom: 6, opacity: 0,
        background: 'linear-gradient(90deg,#4D9FFF 0%,#00D4FF 25%,#E8F4FF 50%,#00D4FF 75%,#4D9FFF 100%)',
        backgroundSize: '200% auto', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
        animationName: 'pr404-fadeUp, pr404-shimmer', animationDuration: '0.6s, 4s', animationDelay: '0.05s, 0.6s',
        animationTimingFunction: 'ease, linear', animationIterationCount: '1, infinite', animationFillMode: 'both, none'
      }}>404</div>

      <h1 style={{ fontFamily: 'Playfair Display,serif', fontSize: 'clamp(1.6rem,4.5vw,2.4rem)', fontWeight: 800, marginBottom: 12, animation: 'pr404-fadeUp 0.6s 0.15s ease both', opacity: 0 }}>
        {lang === 'en' ? 'Page Not Found' : 'पृष्ठ नहीं मिला'}
      </h1>
      <p style={{ color: '#6B8BAF', fontSize: 16, maxWidth: 440, lineHeight: 1.7, marginBottom: 36, animation: 'pr404-fadeUp 0.6s 0.25s ease both', opacity: 0 }}>
        {lang === 'en'
          ? "The page you're looking for doesn't exist or has been moved."
          : 'आप जिस पृष्ठ को ढूंढ रहे हैं वह मौजूद नहीं है या हटा दिया गया है।'}
      </p>

      <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', justifyContent: 'center', animation: 'pr404-fadeUp 0.6s 0.35s ease both', opacity: 0 }}>
        <Link href={dashboardHref}><button className="pr404-btn-primary">{lang === 'en' ? `${dashboardLabel.en} →` : `${dashboardLabel.hi} →`}</button></Link>
      </div>

      {/* Footer brand — exact same logo, mini size */}
      <div style={{ marginTop: 64, display: 'flex', alignItems: 'center', gap: 10, color: '#6B8BAF', fontSize: 13, animation: 'pr404-fadeUp 0.6s 0.45s ease both', opacity: 0 }}>
        <PRLogo size={22} />
        <span style={{ fontFamily: 'Playfair Display,serif', fontWeight: 700, color: '#9FC6FF' }}>ProveRank</span>
      </div>
      <div style={{ marginTop: 10, animation: 'pr404-fadeUp 0.6s 0.5s ease both', opacity: 0 }}>
        <button className="pr404-toggle" onClick={() => { const n = lang === 'en' ? 'hi' : 'en'; setLang(n); localStorage.setItem('pr_lang', n) }}>
          {lang === 'en' ? '🇮🇳 हिंदी' : '🌐 EN'}
        </button>
      </div>
    </div>
  )
}
