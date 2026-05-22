#!/bin/bash
echo "=== Full Fresh Rewrite ==="
mkdir -p ~/workspace/frontend/app/dashboard/test-series
cat > ~/workspace/frontend/app/dashboard/test-series/page.tsx << 'EOF'
'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; description: string; examType: string;
  price: number; discountPrice: number; isFree: boolean; thumbnail: string;
  totalTests: number; enrolledCount: number; language: string; batchType: string;
  isSpotlight: boolean; flashSaleEndTime?: string; flashSalePrice?: number;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean; validity: number;
  rating: number; isEnrolled?: boolean; isWishlisted?: boolean; createdAt: string;
}

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', JEE: '#9B59B6', CUET: '#27AE60',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C',
  Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}
const CATS = ['All', 'NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course']
const CICONS: Record<string, string> = {
  All: '🌟', NEET: '🩺', JEE: '⚙️', CUET: '📖',
  'Class 11': '📗', 'Class 12': '📘', Foundation: '🏛️', 'Crash Course': '🚀'
}
const QUOTES = [
  { q: "Champions aren't made in gyms. They are made from something deep inside them.", a: "Muhammad Ali" },
  { q: "The secret of getting ahead is getting started. Every expert was once a beginner.", a: "Mark Twain" },
  { q: "In the middle of every difficulty lies opportunity. Stay focused, stay strong.", a: "Albert Einstein" },
  { q: "Success is not final, failure is not fatal — it is the courage to continue that counts.", a: "Winston Churchill" },
]
const FACTS = [
  { icon: '🧬', t: 'DNA Replication', f: 'Semi-conservative — each new DNA retains one original strand (Meselson-Stahl, 1958). 3 billion base pairs in human genome.', c: '#4D9FFF' },
  { icon: '⚡', t: 'ATP Synthesis', f: 'Mitochondria produce 36-38 ATP per glucose via oxidative phosphorylation. F0F1 ATP synthase rotates at 100 rpm.', c: '#00D4FF' },
]

function PRLogo({ size = 36 }: { size?: number }) {
  const b = Math.round(size * 0.94)
  const p = Math.round(b * 0.63)
  const f = Math.round(p * 0.52)
  const radius = Math.round(p * 0.28)
  return (
    <div style={{ position: 'relative', width: b, height: b, flexShrink: 0, display: 'inline-flex' }}>
      <div style={{ position: 'absolute', top: 0, left: 0, width: p, height: p, borderRadius: radius, background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: f, fontWeight: 900, fontFamily: 'Inter,sans-serif', color: '#030810' }}>P</div>
      <div style={{ position: 'absolute', bottom: 0, right: 0, width: p, height: p, borderRadius: radius, background: 'rgba(0,212,255,0.15)', border: '1.5px solid rgba(0,212,255,0.45)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: f, fontWeight: 900, fontFamily: 'Inter,sans-serif', color: '#00D4FF' }}>R</div>
    </div>
  )
}

function MilkyWayCanvas() {
  const r = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const cv = r.current; if (!cv) return
    const ctx = cv.getContext('2d'); if (!ctx) return
    let af: number, t = 0
    const resize = () => { cv.width = window.innerWidth; cv.height = window.innerHeight }
    resize(); window.addEventListener('resize', resize)
    const stars = Array.from({ length: 1100 }, () => {
      const cls = Math.random()
      return {
        x: Math.random(), y: Math.random(),
        r: cls < 0.005 ? 2.4 : cls < 0.02 ? 1.5 : cls < 0.08 ? 0.9 : 0.42,
        phase: Math.random() * Math.PI * 2, spd: 0.3 + Math.random() * 3,
        col: cls < 0.003 ? '#9BB0FF' : cls < 0.015 ? '#CAD7FF' : cls < 0.06 ? '#F8F7FF' : '#FFF4EA',
        inArm: Math.random() < 0.55,
      }
    })
    const draw = () => {
      t += 0.003
      const W = cv.width, H = cv.height, cx = W / 2, cy = H * 0.44
      ctx.clearRect(0, 0, W, H)
      ctx.fillStyle = '#020816'; ctx.fillRect(0, 0, W, H)
      const mw = ctx.createLinearGradient(0, H * 0.2, W, H * 0.8)
      mw.addColorStop(0, 'transparent'); mw.addColorStop(0.5, 'rgba(140,155,220,0.055)'); mw.addColorStop(1, 'transparent')
      ctx.fillStyle = mw; ctx.fillRect(0, 0, W, H)
      const sz = Math.min(W, H)
      const core = ctx.createRadialGradient(cx, cy, 0, cx, cy, sz * 0.18)
      core.addColorStop(0, 'rgba(255,215,120,0.15)'); core.addColorStop(0.4, 'rgba(255,170,70,0.07)'); core.addColorStop(1, 'transparent')
      ctx.fillStyle = core; ctx.fillRect(0, 0, W, H)
      const armCols = ['rgba(100,160,255,', 'rgba(180,120,255,', 'rgba(80,200,255,', 'rgba(120,200,140,']
      for (let arm = 0; arm < 4; arm++) {
        for (let seg = 0; seg < 8; seg++) {
          const angle = arm * (Math.PI / 2) + (0.25 + seg * 0.38) * 1.35 + t * 0.04
          const dist = sz * 0.055 + sz * 0.062 * seg
          const nx = cx + Math.cos(angle) * dist, ny = cy + Math.sin(angle) * dist * (H / W)
          const bsz = sz * 0.038 + sz * 0.02 * seg
          const neb = ctx.createRadialGradient(nx, ny, 0, nx, ny, bsz * (1 + 0.1 * Math.sin(t + seg + arm)))
          neb.addColorStop(0, armCols[arm] + '0.09)'); neb.addColorStop(1, 'transparent')
          ctx.fillStyle = neb; ctx.fillRect(0, 0, W, H)
        }
      }
      const nebCols: [number, number, number][] = [[77, 159, 255], [155, 89, 182], [231, 76, 60], [39, 174, 96], [0, 212, 255]]
      nebCols.forEach(([rr, gg, bb], i) => {
        const nx = W * (0.1 + i * 0.2) + Math.cos(t * 0.09 + i) * W * 0.025
        const ny = H * (0.08 + i * 0.19) + Math.sin(t * 0.07 + i) * H * 0.025
        const ng = ctx.createRadialGradient(nx, ny, 0, nx, ny, sz * (0.065 + 0.025 * Math.sin(t * 0.12 + i)))
        ng.addColorStop(0, `rgba(${rr},${gg},${bb},0.06)`); ng.addColorStop(1, 'transparent')
        ctx.fillStyle = ng; ctx.fillRect(0, 0, W, H)
      })
      stars.forEach(s => {
        const x = s.x * W, y = s.y * H
        const tw = 0.3 + 0.7 * Math.abs(Math.sin(t * s.spd + s.phase))
        const alpha = s.inArm ? tw * 0.72 : tw * 0.5
        if (s.r > 1.3) {
          const gl = ctx.createRadialGradient(x, y, 0, x, y, s.r * 3.2)
          gl.addColorStop(0, 'rgba(255,255,255,0.18)'); gl.addColorStop(1, 'transparent')
          ctx.fillStyle = gl; ctx.beginPath(); ctx.arc(x, y, s.r * 3.2, 0, Math.PI * 2); ctx.fill()
        }
        ctx.beginPath(); ctx.arc(x, y, s.r, 0, Math.PI * 2)
        const hex = Math.round(alpha * 255).toString(16).padStart(2, '0')
        ctx.fillStyle = s.col + hex; ctx.fill()
      })
      af = requestAnimationFrame(draw)
    }
    draw()
    return () => { cancelAnimationFrame(af); window.removeEventListener('resize', resize) }
  }, [])
  return <canvas ref={r} style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }} />
}

function SolarSystem() {
  const planets = [
    { sz: 7, col: '#9E9E9E', o: 110, dur: 47, dl: 0 },
    { sz: 13, col: 'radial-gradient(circle at 35% 35%,#F5D5A0,#C4A265)', o: 170, dur: 35, dl: -8 },
    { sz: 14, col: 'radial-gradient(circle at 35% 35%,#5BC8FA,#1565C0)', o: 240, dur: 29, dl: -14 },
    { sz: 9, col: 'radial-gradient(circle at 35% 35%,#FF7043,#BF360C)', o: 308, dur: 24, dl: -20 },
  ]
  return (
    <div style={{ position: 'fixed', top: '42%', left: '50%', transform: 'translate(-50%,-50%)', zIndex: 1, pointerEvents: 'none', width: 0, height: 0 }}>
      <div style={{ position: 'absolute', width: 24, height: 24, marginLeft: -12, marginTop: -12, borderRadius: '50%', background: 'radial-gradient(circle at 40% 40%,#FFF9C4,#FFD600,#FF8F00)', boxShadow: '0 0 34px rgba(255,200,0,0.5)' }} />
      {planets.map((p, i) => (
        <div key={i} style={{ position: 'absolute', width: p.o * 2, height: p.o * 2, marginLeft: -p.o, marginTop: -p.o, borderRadius: '50%', border: '1px solid rgba(77,159,255,0.05)', animation: `orb ${p.dur}s linear infinite`, animationDelay: `${p.dl}s` }}>
          <div style={{ position: 'absolute', top: -p.sz / 2, left: '50%', marginLeft: -p.sz / 2, width: p.sz, height: p.sz, borderRadius: '50%', background: p.col }} />
        </div>
      ))}
      <div style={{ position: 'absolute', width: 820, height: 820, marginLeft: -410, marginTop: -410, borderRadius: '50%', border: '1px solid rgba(77,159,255,0.04)', animation: 'orb 87s linear infinite', animationDelay: '-30s' }}>
        <div style={{ position: 'absolute', top: -18, left: '50%', marginLeft: -18 }}>
          <div style={{ position: 'relative', width: 36, height: 36 }}>
            <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'radial-gradient(circle at 35% 35%,#FFF9C4,#F0D060,#B8860B)' }} />
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%) rotateX(70deg)', width: 70, height: 70, borderRadius: '50%', border: '3px solid rgba(240,210,140,0.38)', pointerEvents: 'none' }} />
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%) rotateX(70deg)', width: 88, height: 88, borderRadius: '50%', border: '2px solid rgba(240,210,140,0.18)', pointerEvents: 'none' }} />
          </div>
        </div>
      </div>
    </div>
  )
}

function FlashTimer({ end }: { end: string }) {
  const [s, setS] = useState({ h: 0, m: 0, s: 0 })
  useEffect(() => {
    const tick = () => {
      const d = new Date(end).getTime() - Date.now()
      if (d <= 0) { setS({ h: 0, m: 0, s: 0 }); return }
      setS({ h: Math.floor(d / 3600000), m: Math.floor(d % 3600000 / 60000), s: Math.floor(d % 60000 / 1000) })
    }
    tick(); const iv = setInterval(tick, 1000); return () => clearInterval(iv)
  }, [end])
  const p = (n: number) => n.toString().padStart(2, '0')
  return <span style={{ fontFamily: 'monospace', fontSize: 13, fontWeight: 800, color: '#FF6B6B', letterSpacing: 2 }}>{p(s.h)}:{p(s.m)}:{p(s.s)}</span>
}

function Stars({ r }: { r: number }) {
  return (
    <span>
      {[1, 2, 3, 4, 5].map(i => <span key={i} style={{ color: i <= Math.round(r) ? '#FFD700' : 'rgba(255,215,0,0.15)', fontSize: 11 }}>★</span>)}
      <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.3)', marginLeft: 3 }}>{r.toFixed(1)}</span>
    </span>
  )
}

function BatchCard({ b, tok, onUpdate }: { b: Batch; tok: string | null; onUpdate: () => void }) {
  const [loading, setLoading] = useState(false)
  const [hov, setHov] = useState(false)
  const isFlash = !!(b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date())
  const isNew = Date.now() - new Date(b.createdAt).getTime() < 7 * 86400000
  const ec = ECOLS[b.examType] || '#4D9FFF'
  const finalPrice = isFlash && b.flashSalePrice ? b.flashSalePrice : b.discountPrice || b.price
  const disc = b.price > 0 && finalPrice < b.price ? Math.round((1 - finalPrice / b.price) * 100) : 0
  const enroll = async () => {
    if (!tok) return alert('Please login')
    setLoading(true)
    try {
      const res = await fetch(`${API}/api/student/batches/${b._id}/enroll`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await res.json()
      if (d.success) onUpdate(); else alert(d.error || 'Error')
    } finally { setLoading(false) }
  }
  const toggleWish = async () => {
    if (!tok) return alert('Please login')
    await fetch(`${API}/api/student/batches/${b._id}/wishlist`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
    onUpdate()
  }
  return (
    <div onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ background: 'rgba(4,12,30,0.95)', border: `1px solid ${hov ? ec + '50' : ec + '18'}`, borderRadius: 20, overflow: 'hidden', backdropFilter: 'blur(22px)', position: 'relative', transition: 'all 0.3s', transform: hov ? 'translateY(-5px)' : 'none', boxShadow: hov ? `0 20px 50px ${ec}18` : '0 4px 18px rgba(0,10,40,0.4)' }}>
      <div style={{ position: 'absolute', top: 10, left: 10, zIndex: 5, display: 'flex', flexDirection: 'column', gap: 4 }}>
        {isNew && <span style={{ background: 'linear-gradient(135deg,#27AE60,#1E8449)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 20 }}>✨ NEW</span>}
        {b.enrolledCount > 100 && <span style={{ background: 'linear-gradient(135deg,#E67E22,#CA6F1E)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 20 }}>🔥 HOT</span>}
        {b.isBundle && <span style={{ background: 'linear-gradient(135deg,#9B59B6,#7D3C98)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 20 }}>📦 BUNDLE</span>}
      </div>
      <button onClick={toggleWish} style={{ position: 'absolute', top: 10, right: 10, zIndex: 5, background: 'rgba(0,0,20,0.6)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '50%', width: 36, height: 36, cursor: 'pointer', fontSize: 15, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{b.isWishlisted ? '❤️' : '🤍'}</button>
      <div style={{ height: 140, background: b.thumbnail ? `url(${b.thumbnail}) center/cover` : `linear-gradient(135deg,${ec}12,${ec}05,rgba(2,8,22,0.9))`, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.95))', zIndex: 1 }} />
        {!b.thumbnail && <span style={{ fontSize: 46, filter: `drop-shadow(0 0 16px ${ec})`, zIndex: 2, opacity: 0.88 }}>{b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : b.examType === 'CUET' ? '📖' : b.examType === 'Crash Course' ? '🚀' : '📚'}</span>}
        {isFlash && b.flashSaleEndTime && <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'rgba(200,40,40,0.92)', padding: '4px 0', textAlign: 'center', fontSize: 10, fontWeight: 700, color: '#fff', zIndex: 3 }}>⚡ Flash: <FlashTimer end={b.flashSaleEndTime} /></div>}
        {b.isEnrolled && <div style={{ position: 'absolute', inset: 0, background: 'rgba(39,174,96,0.16)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2 }}><span style={{ background: 'rgba(39,174,96,0.9)', color: '#fff', padding: '5px 14px', borderRadius: 20, fontSize: 11, fontWeight: 800 }}>✅ Enrolled</span></div>}
      </div>
      <div style={{ padding: '13px 14px 15px' }}>
        <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', marginBottom: 7 }}>
          <span style={{ background: `${ec}16`, color: ec, fontSize: 9, fontWeight: 700, padding: '3px 9px', borderRadius: 20, border: `1px solid ${ec}25` }}>{b.examType}</span>
          <span style={{ background: b.isFree ? 'rgba(39,174,96,0.13)' : 'rgba(230,126,34,0.13)', color: b.isFree ? '#27AE60' : '#E67E22', fontSize: 9, fontWeight: 700, padding: '3px 9px', borderRadius: 20 }}>{b.isFree ? '🆓 FREE' : b.allowFreeTrial ? `🎯 ${b.trialDays}-Day Trial` : '💎 PAID'}</span>
        </div>
        <div style={{ fontSize: 14, fontWeight: 700, color: '#F0F8FF', marginBottom: 4, fontFamily: 'Playfair Display,serif', lineHeight: 1.4, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{b.name}</div>
        <div style={{ fontSize: 11, color: 'rgba(180,210,240,0.55)', lineHeight: 1.5, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', marginBottom: 9 }}>{b.description || 'Premium test series — NCERT based, expert curated.'}</div>
        <Stars r={b.rating} />
        <div style={{ display: 'flex', gap: 7, marginTop: 7, flexWrap: 'wrap' }}>
          {[{ i: '📝', v: `${b.totalTests} Tests` }, { i: '👥', v: b.enrolledCount.toLocaleString() }, { i: '📅', v: `${b.validity}d` }].map((it, idx) => (
            <span key={idx} style={{ fontSize: 10, color: 'rgba(180,210,240,0.45)' }}>{it.i} {it.v}</span>
          ))}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, margin: '9px 0 11px' }}>
          {b.isFree
            ? <span style={{ fontSize: 21, fontWeight: 900, color: '#27AE60', fontFamily: 'Playfair Display,serif' }}>FREE</span>
            : <><span style={{ fontSize: 21, fontWeight: 900, color: '#F0F8FF', fontFamily: 'Playfair Display,serif' }}>₹{finalPrice}</span>{disc > 0 && <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.26)', textDecoration: 'line-through' }}>₹{b.price}</span>}{disc > 0 && <span style={{ fontSize: 9, background: 'rgba(39,174,96,0.16)', color: '#27AE60', padding: '2px 7px', borderRadius: 20, fontWeight: 700 }}>{disc}% OFF</span>}</>}
        </div>
        {b.isEnrolled
          ? <button style={{ width: '100%', padding: '10px', background: `linear-gradient(135deg,${ec}20,${ec}10)`, border: `1px solid ${ec}40`, borderRadius: 11, color: ec, fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>Continue Learning →</button>
          : b.isFree
            ? <button onClick={enroll} disabled={loading} style={{ width: '100%', padding: '10px', background: 'linear-gradient(135deg,#27AE60,#1E8449)', border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>{loading ? 'Enrolling...' : '🚀 Enroll Free'}</button>
            : b.allowFreeTrial
              ? <button onClick={enroll} disabled={loading} style={{ width: '100%', padding: '10px', background: `linear-gradient(135deg,${ec},${ec}BB)`, border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>{loading ? 'Starting...' : '🎯 Free Trial'}</button>
              : <button style={{ width: '100%', padding: '10px', background: `linear-gradient(135deg,${ec},${ec}BB)`, border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>🛒 Buy ₹{finalPrice}</button>}
      </div>
    </div>
  )
}

function EmptyState() {
  return (
    <div style={{ textAlign: 'center', padding: '55px 16px' }}>
      <div style={{ fontSize: 72, marginBottom: 18, display: 'inline-block', animation: 'floatBob 3s ease infinite' }}>🚀</div>
      <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', marginBottom: 10 }}>Batches Launching Soon!</div>
      <div style={{ fontSize: 12, color: 'rgba(160,200,240,0.6)', maxWidth: 360, margin: '0 auto 24px', lineHeight: 1.8 }}>Premium Test Series will appear here once created by the Admin.</div>
      <div style={{ display: 'flex', gap: 7, justifyContent: 'center', flexWrap: 'wrap', marginBottom: 26 }}>
        {['🩺 NEET', '⚙️ JEE Advanced', '📖 CUET', '🚀 Crash Course', '🏛️ Foundation'].map((t, i) => (
          <div key={i} style={{ background: 'rgba(77,159,255,0.07)', border: '1px solid rgba(77,159,255,0.16)', borderRadius: 20, padding: '7px 14px', fontSize: 11, color: '#4D9FFF', fontWeight: 600 }}>{t}</div>
        ))}
      </div>
      <div style={{ background: 'rgba(4,12,30,0.9)', border: '1px solid rgba(77,159,255,0.14)', borderRadius: 16, padding: 20, maxWidth: 400, margin: '0 auto', textAlign: 'left', backdropFilter: 'blur(14px)' }}>
        <div style={{ fontWeight: 700, color: '#4D9FFF', fontSize: 11, marginBottom: 10, textTransform: 'uppercase', letterSpacing: 1 }}>📋 What is Coming</div>
        {['Full Syllabus Test Series', 'Chapter-wise Mini Tests', 'Crash Courses with PDF Notes', 'PYQ Bank (Previous Year Questions)', 'Free & Paid — both available'].map((t, i) => (
          <div key={i} style={{ fontSize: 11, color: 'rgba(160,200,240,0.6)', marginBottom: 6, display: 'flex', gap: 7 }}><span style={{ color: '#27AE60', flexShrink: 0 }}>✓</span>{t}</div>
        ))}
      </div>
    </div>
  )
}

export default function TestSeriesPage() {
  const router = useRouter()
  const [batches, setBatches] = useState<Batch[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [cat, setCat] = useState('All')
  const [sort, setSort] = useState('newest')
  const [filterOpen, setFilterOpen] = useState(false)
  const [filters, setFilters] = useState({ isFree: '', batchType: '' })
  const [tab, setTab] = useState<'all' | 'enrolled' | 'wishlist'>('all')
  const [tok, setTok] = useState<string | null>(null)
  const [qIdx, setQIdx] = useState(0)
  const [spotlights, setSpotlights] = useState<Batch[]>([])

  useEffect(() => {
    setTok(localStorage.getItem('pr_token'))
    const iv = setInterval(() => setQIdx(i => (i + 1) % QUOTES.length), 5000)
    return () => clearInterval(iv)
  }, [])

  const fetchBatches = useCallback(async () => {
    setLoading(true)
    try {
      const p = new URLSearchParams({ sort })
      if (cat !== 'All') p.set('examType', cat)
      if (search) p.set('search', search)
      if (filters.isFree) p.set('isFree', filters.isFree)
      if (filters.batchType) p.set('batchType', filters.batchType)
      const token = localStorage.getItem('pr_token')
      const h = token ? { Authorization: `Bearer ${token}` } : {} as Record<string, string>
      const url = tab === 'enrolled' ? `${API}/api/student/batches/my` : tab === 'wishlist' ? `${API}/api/student/batches/wishlist` : `${API}/api/student/batches?${p}`
      const res = await fetch(url, { headers: h })
      const d = await res.json()
      const all = d.batches || []
      setBatches(all)
      setSpotlights(all.filter((b: Batch) => b.isSpotlight).slice(0, 3))
    } catch { setBatches([]) } finally { setLoading(false) }
  }, [cat, sort, search, filters, tab])

  useEffect(() => { fetchBatches() }, [fetchBatches])

  const currentQuote = QUOTES[qIdx]

  return (
    <div style={{ minHeight: '100vh', color: '#F0F8FF', fontFamily: 'Inter,sans-serif', position: 'relative', overflowX: 'hidden', background: 'transparent' }}>
      <MilkyWayCanvas />
      <SolarSystem />
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes floatBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-13px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(26px)}to{opacity:1;transform:translateY(0)}}
        @keyframes fadeSlide{from{opacity:0;transform:translateX(16px)}to{opacity:1;transform:translateX(0)}}
        @keyframes gradShift{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes orb{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.26);border-radius:4px}
        input,select{outline:none}
        input::placeholder{color:rgba(100,150,200,0.42)}
      `}</style>

      {/* STICKY TOP BAR */}
      <div style={{ position: 'sticky', top: 0, zIndex: 50, background: 'rgba(2,8,22,0.94)', backdropFilter: 'blur(22px)', borderBottom: '1px solid rgba(77,159,255,0.1)', padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={() => router.back()}
          style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#4D9FFF', fontSize: 20, flexShrink: 0 }}
          onMouseEnter={e => (e.currentTarget.style.background = 'rgba(77,159,255,0.2)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'rgba(77,159,255,0.1)')}>←</button>
        <PRLogo size={32} />
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 14, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>Test Series & Batches</div>
          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.42)' }}>NEET / JEE / CUET</div>
        </div>
      </div>

      <div style={{ position: 'relative', zIndex: 2, padding: '14px 14px 80px', maxWidth: 1200, margin: '0 auto' }}>

        {/* HERO — transparent */}
        <div style={{ background: 'transparent', padding: '22px 18px 20px', marginBottom: 16, position: 'relative', overflow: 'hidden', animation: 'slideUp 0.5s ease', textAlign: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 4, justifyContent: 'center' }}>
            <span style={{ fontSize: 34, filter: 'drop-shadow(0 0 13px rgba(77,159,255,0.5))' }}>🎓</span>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 25, fontWeight: 700, background: 'linear-gradient(135deg,#4D9FFF 0%,#00D4FF 45%,#9B59B6 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundSize: '200%', animation: 'gradShift 6s ease infinite' }}>Test Series & Batches</div>
          </div>
        </div>

        {/* CATEGORY STRIP */}
        <div style={{ display: 'flex', gap: 7, overflowX: 'auto', paddingBottom: 7, marginBottom: 14, scrollbarWidth: 'none' }}>
          {CATS.map(c => {
            const active = cat === c
            return <button key={c} onClick={() => setCat(c)} style={{ flexShrink: 0, padding: '8px 15px', borderRadius: 22, background: active ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(77,159,255,0.07)', border: active ? 'none' : '1px solid rgba(77,159,255,0.13)', color: active ? '#fff' : 'rgba(160,200,240,0.62)', fontWeight: active ? 700 : 400, cursor: 'pointer', fontSize: 11, transition: 'all 0.2s', whiteSpace: 'nowrap', boxShadow: active ? '0 4px 13px rgba(77,159,255,0.26)' : 'none' }}>{CICONS[c]} {c}</button>
          })}
        </div>

        {/* SPOTLIGHT */}
        {spotlights.length > 0 && (
          <div style={{ marginBottom: 20 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 11 }}>
              <span style={{ fontSize: 17 }}>⭐</span>
              <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, color: '#F0F8FF' }}>Spotlight Picks</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 14 }}>
              {spotlights.map(b => <BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches} />)}
            </div>
          </div>
        )}

        {/* TABS */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 7, marginBottom: 13 }}>
          {(['all', 'enrolled', 'wishlist'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)} style={{ padding: '10px', borderRadius: 12, background: tab === t ? 'rgba(77,159,255,0.13)' : 'rgba(4,12,30,0.8)', border: `1px solid ${tab === t ? 'rgba(77,159,255,0.36)' : 'rgba(77,159,255,0.1)'}`, color: tab === t ? '#4D9FFF' : 'rgba(160,200,240,0.42)', fontWeight: tab === t ? 700 : 400, cursor: 'pointer', fontSize: 11, backdropFilter: 'blur(12px)' }}>
              {t === 'all' ? '🌟 All' : t === 'enrolled' ? '✅ My Batches' : '❤️ Wishlist'}
            </button>
          ))}
        </div>

        {/* SEARCH + SORT + FILTER */}
        <div style={{ display: 'flex', gap: 7, marginBottom: 12, flexWrap: 'wrap' }}>
          <div style={{ flex: 1, minWidth: 150, position: 'relative' }}>
            <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', fontSize: 12, opacity: 0.42 }}>🔍</span>
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search batches..." style={{ width: '100%', padding: '10px 10px 10px 32px', background: 'rgba(4,12,30,0.9)', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 12, color: '#F0F8FF', fontSize: 12, backdropFilter: 'blur(12px)' }} />
          </div>
          <select value={sort} onChange={e => setSort(e.target.value)} style={{ padding: '10px 7px', background: 'rgba(4,12,30,0.9)', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 12, color: '#F0F8FF', fontSize: 11, cursor: 'pointer' }}>
            <option value="newest">🆕 Newest</option>
            <option value="popular">🔥 Popular</option>
            <option value="rating">⭐ Top Rated</option>
            <option value="price_low">💰 Low Price</option>
            <option value="price_high">💎 High Price</option>
          </select>
          <button onClick={() => setFilterOpen(o => !o)} style={{ padding: '10px 12px', background: filterOpen ? 'rgba(77,159,255,0.13)' : 'rgba(4,12,30,0.9)', border: `1px solid ${filterOpen ? 'rgba(77,159,255,0.36)' : 'rgba(77,159,255,0.13)'}`, borderRadius: 12, color: '#4D9FFF', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>⚙️ Filter</button>
        </div>

        {/* FILTER PANEL */}
        {filterOpen && (
          <div style={{ background: 'rgba(4,12,30,0.97)', border: '1px solid rgba(77,159,255,0.14)', borderRadius: 15, padding: 15, marginBottom: 12, backdropFilter: 'blur(22px)', display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(130px,1fr))', gap: 13, animation: 'slideUp 0.22s ease' }}>
            {[
              { label: 'Price', key: 'isFree', opts: [{ v: '', l: 'All' }, { v: 'true', l: 'Free' }, { v: 'false', l: 'Paid' }] },
              { label: 'Format', key: 'batchType', opts: [{ v: '', l: 'Any' }, { v: 'Live', l: '🔴 Live' }, { v: 'Recorded', l: '📹 Recorded' }, { v: 'Both', l: '🔄 Both' }] },
            ].map(f => (
              <div key={f.key}>
                <div style={{ fontSize: 9, color: 'rgba(160,200,240,0.42)', marginBottom: 7, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1 }}>{f.label}</div>
                <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
                  {f.opts.map(o => {
                    const active = (filters as Record<string, string>)[f.key] === o.v
                    return <button key={o.v} onClick={() => setFilters(prev => ({ ...prev, [f.key]: o.v }))} style={{ padding: '4px 9px', borderRadius: 20, fontSize: 10, cursor: 'pointer', background: active ? 'rgba(77,159,255,0.18)' : 'rgba(77,159,255,0.05)', border: `1px solid ${active ? 'rgba(77,159,255,0.42)' : 'rgba(77,159,255,0.1)'}`, color: active ? '#4D9FFF' : 'rgba(160,200,240,0.42)' }}>{o.l}</button>
                  })}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* BATCH GRID */}
        {loading ? (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 16 }}>
            {[1, 2, 3, 4].map(i => <div key={i} style={{ height: 380, background: 'rgba(4,12,30,0.8)', borderRadius: 20, border: '1px solid rgba(77,159,255,0.06)', animation: 'shimmer 1.5s ease infinite', animationDelay: `${i * 0.14}s` }} />)}
          </div>
        ) : batches.length === 0 ? <EmptyState /> : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 16 }}>
            {batches.map((b, i) => (
              <div key={b._id} style={{ animation: `slideUp ${0.28 + i * 0.04}s ease both` }}>
                <BatchCard b={b} tok={tok} onUpdate={fetchBatches} />
              </div>
            ))}
          </div>
        )}

        {/* NCERT FACTS — 2, transparent */}
        <div style={{ marginTop: 50, padding: '0 4px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(230px,1fr))', gap: 26, maxWidth: 640, margin: '0 auto' }}>
            {FACTS.map((f, i) => (
              <div key={i} style={{ display: 'flex', gap: 13, alignItems: 'flex-start', animation: `slideUp ${1.1 + i * 0.12}s ease` }}>
                <div style={{ fontSize: 30, filter: `drop-shadow(0 0 11px ${f.c}80)`, flexShrink: 0 }}>{f.icon}</div>
                <div>
                  <div style={{ fontWeight: 700, color: f.c, fontSize: 12, marginBottom: 4, fontFamily: 'Playfair Display,serif' }}>{f.t}</div>
                  <div style={{ fontSize: 11, color: 'rgba(180,210,240,0.58)', lineHeight: 1.7 }}>{f.f}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* WHY PROVERANK */}
        <div style={{ marginTop: 42, background: 'rgba(4,12,30,0.97)', border: '1px solid rgba(77,159,255,0.12)', borderRadius: 20, padding: '24px 16px', backdropFilter: 'blur(22px)', boxShadow: '0 10px 40px rgba(0,10,40,0.42)' }}>
          <div style={{ textAlign: 'center', marginBottom: 20 }}>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 19, fontWeight: 700, color: '#F0F8FF', marginBottom: 3 }}>✨ Why Choose ProveRank?</div>
            <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.42)' }}>India's most advanced NEET / JEE platform</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(130px,1fr))', gap: 10 }}>
            {[
              { i: '🤖', t: 'AI Analytics', d: 'Weak area detection\nSmart revision', c: '#9B59B6' },
              { i: '🔒', t: 'Anti-Cheat', d: 'Webcam · Face AI\nIP Lock', c: '#E74C3C' },
              { i: '📊', t: 'Live Ranks', d: 'Real-time AIR\nPercentile', c: '#27AE60' },
              { i: '📄', t: 'OMR + PDFs', d: 'Bubble sheet\nCertificates', c: '#E67E22' },
              { i: '🆓', t: '100% Free', d: 'Free hosting\nNo charges', c: '#00D4FF' },
            ].map((f, i) => (
              <div key={i} style={{ background: 'rgba(4,12,30,0.72)', border: `1px solid ${f.c}14`, borderRadius: 14, padding: '14px 10px', textAlign: 'center', transition: 'all 0.3s' }}
                onMouseEnter={e => { (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-3px)'; (e.currentTarget as HTMLDivElement).style.borderColor = f.c + '36' }}
                onMouseLeave={e => { (e.currentTarget as HTMLDivElement).style.transform = ''; (e.currentTarget as HTMLDivElement).style.borderColor = f.c + '14' }}>
                <div style={{ fontSize: 26, marginBottom: 8, filter: `drop-shadow(0 0 6px ${f.c}75)` }}>{f.i}</div>
                <div style={{ fontWeight: 700, color: f.c, fontSize: 11, marginBottom: 4 }}>{f.t}</div>
                <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.46)', lineHeight: 1.62, whiteSpace: 'pre-line' }}>{f.d}</div>
              </div>
            ))}
          </div>
        </div>

        {/* QUOTE — transparent, very bottom */}
        <div style={{ padding: '24px 4px 8px', display: 'flex', alignItems: 'center', gap: 13 }}>
          <span style={{ fontSize: 26, flexShrink: 0 }}>💫</span>
          <div>
            <div style={{ fontSize: 13, color: 'rgba(200,220,240,0.72)', fontStyle: 'italic', lineHeight: 1.65, fontFamily: 'Playfair Display,serif' }}>"{currentQuote.q}"</div>
            <div style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 700, marginTop: 5 }}>— {currentQuote.a}</div>
          </div>
        </div>

      </div>
    </div>
  )
}
EOF
echo "✅ page.tsx written"
cd ~/workspace && git add -A && git commit -m "fix: test-series final rewrite — all batch fixes + no qIdx scope error" && git push origin main
echo "=== DONE ==="
