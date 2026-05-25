'use client'
import { useState, useEffect, useCallback, Suspense, useRef } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; examType: string; price: number; discountPrice: number;
  isFree: boolean; thumbnail: string; totalTests: number; enrolledCount: number;
  language: string; batchType: string; validity: number; rating: number;
  allowFreeTrial: boolean; difficulty: string; isEnrolled?: boolean;
  hasCertificate?: boolean; hasLiveTests?: boolean; hasStudyMaterial?: boolean;
  description: string; createdAt: string;
}

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', JEE: '#9B59B6', CUET: '#27AE60',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C',
  Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}

const ROWS = [
  { key: 'price', label: 'Price', fmt: (b: Batch) => b.isFree ? 'Free' : `₹${b.discountPrice || b.price}`, better: 'lower' },
  { key: 'totalTests', label: 'Total Tests', fmt: (b: Batch) => `${b.totalTests || 0}`, better: 'higher' },
  { key: 'validity', label: 'Validity (Days)', fmt: (b: Batch) => `${b.validity || 0}d`, better: 'higher' },
  { key: 'rating', label: 'Rating', fmt: (b: Batch) => `⭐ ${b.rating?.toFixed(1) || 'N/A'}`, better: 'higher' },
  { key: 'enrolledCount', label: 'Students Enrolled', fmt: (b: Batch) => (b.enrolledCount || 0).toLocaleString(), better: 'higher' },
  { key: 'batchType', label: 'Batch Type', fmt: (b: Batch) => b.batchType || 'Recorded', better: 'none' },
  { key: 'language', label: 'Language', fmt: (b: Batch) => b.language || 'Hindi + English', better: 'none' },
  { key: 'difficulty', label: 'Difficulty', fmt: (b: Batch) => b.difficulty || 'Medium', better: 'none' },
  { key: 'isFree', label: 'Free Available', fmt: (b: Batch) => b.isFree ? '✅ Yes' : '❌ No', better: 'true' },
  { key: 'allowFreeTrial', label: 'Free Trial', fmt: (b: Batch) => b.allowFreeTrial ? '✅ Yes' : '❌ No', better: 'true' },
  { key: 'hasLiveTests', label: 'Live Tests', fmt: (b: Batch) => b.hasLiveTests ? '✅ Yes' : '⚫ N/A', better: 'none' },
  { key: 'hasStudyMaterial', label: 'Study Material', fmt: (b: Batch) => b.hasStudyMaterial ? '✅ Yes' : '⚫ N/A', better: 'none' },
  { key: 'hasCertificate', label: 'Certificate', fmt: (b: Batch) => b.hasCertificate !== false ? '✅ Yes' : '❌ No', better: 'true' },
]


const getBetterByPct = (batches, row, bi) => {
  if (row.better === "none" || row.better === "true" || batches.length < 2) return ""
  const vals = batches.map(b => {
    const v = b[row.key]
    return typeof v === "number" ? v : 0
  })
  const myVal = vals[bi]
  const others = vals.filter((_, i) => i !== bi)
  const bestOther = row.better === "lower" ? Math.min(...others) : Math.max(...others)
  if (bestOther === 0 || myVal === bestOther) return ""
  const pct = Math.abs(Math.round(((myVal - bestOther) / bestOther) * 100))
  if (pct === 0) return ""
  const isBetter = row.better === "lower" ? myVal < bestOther : myVal > bestOther
  return isBetter ? ("+" + pct + "% better") : ("-" + pct + "% lower")
}
const getBestIdx = (batches: Batch[], row: typeof ROWS[0]) => {
  if (row.better === 'none' || batches.length < 2) return -1
  const vals = batches.map(b => {
    const v = (b as Record<string, unknown>)[row.key]
    if (row.better === 'true') return v === true ? 1 : 0
    if (typeof v === 'number') return v
    return 0
  })
  if (vals.every(v => v === vals[0])) return -1
  const best = row.better === 'lower' ? Math.min(...vals) : Math.max(...vals)
  return vals.indexOf(best)
}

function CompareInner() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [allBatches, setAllBatches] = useState<Batch[]>([])
  const [selected, setSelected] = useState<Batch[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [showModal, setShowModal] = useState(false)
  const modalRef = useRef<HTMLDivElement>(null)
  const [tok, setTok] = useState('')
  const [enrolling, setEnrolling] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)
  const [downloading, setDownloading] = useState(false)
  const [publicCopied, setPublicCopied] = useState(false)

  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t)
    fetchBatches(t)
  }, [])

  const fetchBatches = async (t: string) => {
    setLoading(true)
    try {
      const h = t ? { Authorization: `Bearer ${t}` } : {} as Record<string, string>
      const r = await fetch(`${API}/api/student/batches`, { headers: h })
      const d = await r.json()
      const batches = d.batches || []
      setAllBatches(batches)
      // Pre-select from URL params
      const ids = searchParams.get('ids')?.split(',').filter(Boolean) || []
      if (ids.length > 0) {
        const pre = batches.filter((b: Batch) => ids.includes(b._id)).slice(0, 3)
        setSelected(pre)
        if (pre.length >= 2) setShowModal(true)
      }
    } catch { setAllBatches([]) }
    finally { setLoading(false) }
  }

  const toggle = (b: Batch) => setSelected(prev =>
    prev.find(x => x._id === b._id)
      ? prev.filter(x => x._id !== b._id)
      : prev.length >= 3 ? prev
      : [...prev, b]
  )

  const enroll = async (b: Batch) => {
    if (!tok) return alert('Please login')
    setEnrolling(b._id)
    try {
      const r = await fetch(`${API}/api/student/batches/${b._id}/enroll`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) fetchBatches(tok); else alert(d.error || 'Error')
    } finally { setEnrolling(null) }
  }

  const shareLink = () => {
    const url = `${window.location.origin}/dashboard/batch-compare?ids=${selected.map(b => b._id).join(',')}`
    navigator.clipboard.writeText(url)
    setCopied(true); setTimeout(() => setCopied(false), 2500)
  }

  const shareAsImage = async () => {
    setDownloading(true)
    try {
      const el = modalRef.current
      if (!el) { alert('Open the comparison modal first'); setDownloading(false); return }
      const html2canvas = (await import('html2canvas')).default
      const canvas = await html2canvas(el, {
        backgroundColor: '#020816', scale: 2, useCORS: true,
        allowTaint: true, logging: false
      })
      const link = document.createElement('a')
      link.download = 'proverank-comparison.png'
      link.href = canvas.toDataURL('image/png')
      link.click()
    } catch { alert('Download failed — try again') }
    finally { setDownloading(false) }
  }

  const copyPublicLink = () => {
    const ids = selected.map(b => b._id).join(',')
    const url = `${window.location.origin}/compare/public?ids=${ids}`
    navigator.clipboard.writeText(url)
    setPublicCopied(true); setTimeout(() => setPublicCopied(false), 2500)
  }

  const filtered = allBatches.filter(b =>
    b.name.toLowerCase().includes(search.toLowerCase()) ||
    b.examType.toLowerCase().includes(search.toLowerCase())
  )

  const bestValueIdx = (() => {
    if (selected.length < 2) return -1
    const scores = selected.map((b) => {
      let s = 0
      const p = b.isFree ? 0 : (b.discountPrice || b.price)
      if (p === Math.min(...selected.map(x => x.isFree ? 0 : (x.discountPrice || x.price)))) s += 2
      if ((b.totalTests || 0) === Math.max(...selected.map(x => x.totalTests || 0))) s += 2
      if ((b.rating || 0) === Math.max(...selected.map(x => x.rating || 0))) s += 1
      return s
    })
    return scores.indexOf(Math.max(...scores))
  })()

  const C = { text: '#F0F8FF', sub: 'rgba(160,200,240,0.6)', border: 'rgba(77,159,255,0.18)', card: 'rgba(4,12,30,0.95)', blue: '#4D9FFF' }

  return (
    <div style={{ minHeight: '100vh', color: C.text, fontFamily: 'Inter,sans-serif', background:'#020816' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700;800&display=swap');
        @keyframes slideUp{from{opacity:0;transform:translateY(22px)}to{opacity:1;transform:translateY(0)}}
        @keyframes slideUpM{from{transform:translateY(100%)}to{transform:translateY(0)}}
        @keyframes glow{0%,100%{box-shadow:0 0 20px rgba(155,89,182,0.3)}50%{box-shadow:0 0 40px rgba(155,89,182,0.6)}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @media print{.no-print{display:none!important} body{background:#020816!important} @page{margin:8mm;size:A4 landscape}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.28);border-radius:4px}
        input{outline:none}
        input::placeholder{color:rgba(100,150,200,0.42)}
      `}</style>

      {/* TOP BAR */}
      <div style={{ position: 'sticky', top: 0, zIndex: 100, background: 'rgba(2,8,22,0.95)', backdropFilter: 'blur(22px)', borderBottom: `1px solid ${C.border}`, padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={() => router.back()}
          style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: C.blue, fontSize: 20, flexShrink: 0 }}
          onMouseEnter={e => (e.currentTarget.style.background = 'rgba(77,159,255,0.2)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'rgba(77,159,255,0.1)')}>←</button>
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 15, fontWeight: 700, background: 'linear-gradient(90deg,#9B59B6,#4D9FFF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>⚖️ Compare Batches</div>
          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.42)' }}>Select up to 3 batches to compare side-by-side</div>
        </div>
        <div style={{ flex: 1 }} />
        {selected.length >= 2 && (
          <button onClick={() => setShowModal(true)}
            style={{ background: 'linear-gradient(135deg,#9B59B6,#7D3C98)', border: 'none', borderRadius: 10, padding: '9px 18px', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 12, animation: 'glow 2s ease infinite' }}>
            Compare {selected.length} →
          </button>
        )}
      </div>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '14px 14px 120px', position: 'relative', zIndex: 2 }}>

        {/* HOW TO */}
        <div style={{ background: 'rgba(155,89,182,0.06)', border: '1px solid rgba(155,89,182,0.2)', borderRadius: 14, padding: '12px 16px', marginBottom: 16, display: 'flex', gap: 10, alignItems: 'center', animation: 'slideUp 0.4s ease' }}>
          <span style={{ fontSize: 20, flexShrink: 0 }}>💡</span>
          <div style={{ fontSize: 12, color: C.sub, lineHeight: 1.6 }}>
            Tap <strong style={{ color: '#9B59B6' }}>⚖</strong> on any batch card in Test Series page, or select here. Choose <strong style={{ color: C.blue }}>2–3 batches</strong> → tap <strong style={{ color: '#9B59B6' }}>Compare Now</strong> for full side-by-side view.
          </div>
        </div>

        {/* SEARCH */}
        <div style={{ position: 'relative', marginBottom: 14 }}>
          <span style={{ position: 'absolute', left: 11, top: '50%', transform: 'translateY(-50%)', fontSize: 13, opacity: 0.4 }}>🔍</span>
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search by name or exam type..."
            style={{ width: '100%', padding: '10px 12px 10px 34px', background: C.card, border: `1px solid ${C.border}`, borderRadius: 13, color: C.text, fontSize: 12, backdropFilter: 'blur(12px)' }} />
        </div>

        {/* SELECTED PILLS */}
        {selected.length > 0 && (
          <div style={{ display: 'flex', gap: 7, flexWrap: 'wrap', marginBottom: 14, animation: 'slideUp 0.3s ease' }}>
            <span style={{ fontSize: 11, color: C.sub, alignSelf: 'center', flexShrink: 0 }}>Selected:</span>
            {selected.map(b => (
              <div key={b._id} style={{ display: 'flex', alignItems: 'center', gap: 5, background: `${ECOLS[b.examType] || '#9B59B6'}18`, border: `1px solid ${ECOLS[b.examType] || '#9B59B6'}35`, borderRadius: 20, padding: '4px 10px' }}>
                <span style={{ fontSize: 11, fontWeight: 600, color: ECOLS[b.examType] || '#9B59B6', maxWidth: 130, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{b.name}</span>
                <button onClick={() => toggle(b)} style={{ background: 'none', border: 'none', color: 'rgba(255,255,255,0.45)', cursor: 'pointer', fontSize: 15, lineHeight: 1, padding: 0 }}>×</button>
              </div>
            ))}
            {selected.length < 3 && <span style={{ fontSize: 11, color: 'rgba(160,200,240,0.35)', alignSelf: 'center' }}>{3 - selected.length} more can be added</span>}
          </div>
        )}

        {/* BATCH GRID */}
        {loading ? (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 12 }}>
            {[1, 2, 3, 4, 5, 6].map(i => <div key={i} style={{ height: 180, background: C.card, borderRadius: 16, animation: 'shimmer 1.5s ease infinite', animationDelay: `${i * 0.1}s` }} />)}
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '50px 20px', color: C.sub }}>
            <div style={{ fontSize: 44, marginBottom: 12 }}>🔍</div>
            <div style={{ fontSize: 16, fontWeight: 600, color: C.text, marginBottom: 8 }}>No batches found</div>
          </div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 12 }}>
            {filtered.map((b, i) => {
              const isSel = !!selected.find(x => x._id === b._id)
              const disabled = !isSel && selected.length >= 3
              const ec = ECOLS[b.examType] || '#4D9FFF'
              return (
                <div key={b._id} onClick={() => !disabled && toggle(b)}
                  style={{ background: C.card, border: `2px solid ${isSel ? ec + '70' : disabled ? 'rgba(255,255,255,0.04)' : ec + '18'}`, borderRadius: 16, overflow: 'hidden', cursor: disabled ? 'not-allowed' : 'pointer', transition: 'all 0.22s', opacity: disabled ? 0.4 : 1, transform: isSel ? 'scale(1.02)' : 'scale(1)', boxShadow: isSel ? `0 6px 28px ${ec}22` : 'none', animation: `slideUp ${0.3 + i * 0.04}s ease`, position: 'relative' }}>
                  {/* Checkbox */}
                  <div style={{ position: 'absolute', top: 9, right: 9, zIndex: 5, width: 22, height: 22, borderRadius: 6, background: isSel ? ec : 'rgba(0,0,20,0.7)', border: `2px solid ${isSel ? ec : 'rgba(255,255,255,0.18)'}`, display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}>
                    {isSel && <span style={{ color: '#fff', fontSize: 13, fontWeight: 900 }}>✓</span>}
                  </div>
                  {/* Thumbnail */}
                  <div style={{ height: 88, background: b.thumbnail ? `url(${b.thumbnail}) center/cover` : `linear-gradient(135deg,${ec}14,${ec}05,rgba(2,8,22,0.9))`, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.9))', zIndex: 1 }} />
                    {!b.thumbnail && <span style={{ fontSize: 34, opacity: 0.85, zIndex: 2 }}>{b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : b.examType === 'CUET' ? '📖' : b.examType === 'Crash Course' ? '🚀' : '📚'}</span>}
                  </div>
                  {/* Body */}
                  <div style={{ padding: '10px 12px 12px' }}>
                    <div style={{ display: 'flex', gap: 5, marginBottom: 5 }}>
                      <span style={{ background: `${ec}18`, color: ec, fontSize: 9, fontWeight: 700, padding: '2px 8px', borderRadius: 20 }}>{b.examType}</span>
                      <span style={{ background: b.isFree ? 'rgba(39,174,96,0.14)' : 'rgba(230,126,34,0.14)', color: b.isFree ? '#27AE60' : '#E67E22', fontSize: 9, fontWeight: 700, padding: '2px 8px', borderRadius: 20 }}>{b.isFree ? 'FREE' : 'PAID'}</span>
                    </div>
                    <div style={{ fontSize: 12, fontWeight: 700, color: C.text, marginBottom: 5, fontFamily: 'Playfair Display,serif', lineHeight: 1.35, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{b.name}</div>
                    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 10, color: C.sub }}>📝 {b.totalTests || 0}</span>
                      <span style={{ fontSize: 10, color: C.sub }}>⭐ {b.rating?.toFixed(1) || 'N/A'}</span>
                      <span style={{ fontSize: 10, fontWeight: 700, color: b.isFree ? '#27AE60' : C.text }}>{b.isFree ? 'FREE' : `₹${b.discountPrice || b.price}`}</span>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>

      {/* FLOATING TRAY */}
      {selected.length >= 1 && !showModal && (
        <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 200, background: 'rgba(4,12,30,0.98)', borderTop: `1px solid ${selected.length === 3 ? 'rgba(155,89,182,0.5)' : 'rgba(77,159,255,0.2)'}`, backdropFilter: 'blur(24px)', padding: '12px 16px', boxShadow: selected.length === 3 ? '0 -8px 40px rgba(155,89,182,0.2)' : '0 -4px 20px rgba(0,0,0,0.4)', animation: 'slideUpM 0.3s ease' }}>
          <div style={{ maxWidth: 1100, margin: '0 auto', display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
            <div style={{ display: 'flex', gap: 7, flex: 1 }}>
              {selected.map(b => (
                <div key={b._id} style={{ width: 40, height: 40, borderRadius: 10, background: b.thumbnail ? `url(${b.thumbnail}) center/cover` : `${ECOLS[b.examType] || '#9B59B6'}20`, border: `2px solid ${ECOLS[b.examType] || '#9B59B6'}50`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, flexShrink: 0, position: 'relative' }}>
                  {!b.thumbnail && (b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : '📚')}
                  <button onClick={e => { e.stopPropagation(); toggle(b) }} style={{ position: 'absolute', top: -5, right: -5, background: 'rgba(231,76,60,0.9)', border: 'none', borderRadius: '50%', width: 14, height: 14, cursor: 'pointer', fontSize: 8, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 900, padding: 0 }}>×</button>
                </div>
              ))}
              {Array.from({ length: 3 - selected.length }).map((_, i) => (
                <div key={i} style={{ width: 40, height: 40, borderRadius: 10, background: 'rgba(77,159,255,0.05)', border: '2px dashed rgba(77,159,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, color: 'rgba(77,159,255,0.25)', flexShrink: 0 }}>+</div>
              ))}
            </div>
            <span style={{ fontSize: 11, color: C.sub, flexShrink: 0 }}><strong style={{ color: '#9B59B6' }}>{selected.length}</strong>/3</span>
            <button onClick={() => setSelected([])} style={{ background: 'rgba(231,76,60,0.1)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 8, padding: '7px 10px', color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 600, flexShrink: 0 }}>Clear</button>
            {selected.length >= 2
              ? <button onClick={() => setShowModal(true)} style={{ background: 'linear-gradient(135deg,#9B59B6,#7D3C98)', border: 'none', borderRadius: 10, padding: '9px 16px', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 12, flexShrink: 0, animation: selected.length === 3 ? 'glow 2s ease infinite' : 'none' }}>Compare Now →</button>
              : <span style={{ fontSize: 11, color: 'rgba(160,200,240,0.38)', flexShrink: 0 }}>+{2 - selected.length} more</span>}
          </div>
        </div>
      )}

      {/* COMPARISON MODAL */}
      {showModal && selected.length >= 2 && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 300, background: 'rgba(0,0,10,0.88)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'flex-end', justifyContent: 'center' }}
          onClick={e => { if (e.target === e.currentTarget) setShowModal(false) }}>
          <div style={{ background: '#020816', border: '1px solid rgba(155,89,182,0.25)', borderRadius: '22px 22px 0 0', width: '100%', maxWidth: 900, maxHeight: '90vh', overflow: 'auto', animation: 'slideUpM 0.35s ease', boxShadow: '0 -12px 60px rgba(0,10,40,0.7)' }}>

            {/* Modal Header */}
            <div style={{ position: 'sticky', top: 0, background: 'rgba(2,8,22,0.98)', backdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(155,89,182,0.18)', padding: '14px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', zIndex: 10 }}>
              <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, background: 'linear-gradient(90deg,#9B59B6,#4D9FFF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>⚖️ Batch Comparison</div>
              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={shareLink} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.22)', borderRadius: 10, padding: '7px 13px', color: C.blue, cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>
                  {copied ? '✅ Copied!' : '🔗 Share Link'}
                </button>
                <button onClick={() => window.print()} style={{ background: 'rgba(39,174,96,0.1)', border: '1px solid rgba(39,174,96,0.25)', borderRadius: 10, padding: '7px 13px', color: '#27AE60', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>
                  📄 Export PDF
                </button>
                <button onClick={shareAsImage} disabled={downloading} style={{ background: 'rgba(155,89,182,0.1)', border: '1px solid rgba(155,89,182,0.25)', borderRadius: 10, padding: '7px 13px', color: '#9B59B6', cursor: downloading ? 'wait' : 'pointer', fontSize: 11, fontWeight: 600 }}>
                  {downloading ? '⏳ Saving...' : '🖼️ Save as Image'}
                </button>
                <button onClick={copyPublicLink} style={{ background: 'rgba(255,215,0,0.08)', border: '1px solid rgba(255,215,0,0.2)', borderRadius: 10, padding: '7px 13px', color: '#FFD700', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>
                  {publicCopied ? '✅ Public Link Copied!' : '🌐 Share Public Link'}
                </button>
                <button onClick={() => setShowModal(false)} style={{ background: 'rgba(231,76,60,0.1)', border: '1px solid rgba(231,76,60,0.25)', borderRadius: 10, padding: '7px 13px', color: '#E74C3C', cursor: 'pointer', fontSize: 12, fontWeight: 700 }}>✕ Close</button>
              </div>
            </div>

            {/* Batch Headers */}
            <div style={{ display: 'grid', gridTemplateColumns: `130px ${selected.map(() => '1fr').join(' ')}`, borderBottom: '1px solid rgba(155,89,182,0.15)', padding: '16px 18px 12px' }}>
              <div />
              {selected.map((b, bi) => {
                const ec = ECOLS[b.examType] || '#4D9FFF'
                const isBest = bi === bestValueIdx
                return (
                  <div key={b._id} style={{ textAlign: 'center', padding: '0 6px', position: 'relative' }}>
                    {isBest && <div style={{ position: 'absolute', top: -8, left: '50%', transform: 'translateX(-50%)', background: 'linear-gradient(135deg,#27AE60,#1E8449)', color: '#fff', fontSize: 8, fontWeight: 800, padding: '2px 10px', borderRadius: 20, whiteSpace: 'nowrap' }}>✨ BEST VALUE</div>}
                    <div style={{ width: 50, height: 50, borderRadius: 12, background: b.thumbnail ? `url(${b.thumbnail}) center/cover` : `linear-gradient(135deg,${ec}25,${ec}10)`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, margin: '8px auto 8px', border: `2px solid ${isBest ? '#27AE60' : ec + '40'}`, boxShadow: isBest ? '0 0 16px rgba(39,174,96,0.3)' : 'none' }}>
                      {!b.thumbnail && (b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : b.examType === 'CUET' ? '📖' : b.examType === 'Crash Course' ? '🚀' : '📚')}
                    </div>
                    <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 12, fontWeight: 700, color: isBest ? '#27AE60' : C.text, lineHeight: 1.3, marginBottom: 5, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{b.name}</div>
                    <span style={{ background: `${ec}18`, color: ec, fontSize: 9, fontWeight: 700, padding: '2px 8px', borderRadius: 20 }}>{b.examType}</span>
                  </div>
                )
              })}
            </div>

            {/* Comparison Rows */}
            <div style={{ padding: '4px 18px 8px' }}>
              {ROWS.map((row, ri) => {
                const bestIdx = getBestIdx(selected, row)
                return (
                  <div key={row.key} style={{ display: 'grid', gridTemplateColumns: `130px ${selected.map(() => '1fr').join(' ')}`, borderBottom: '1px solid rgba(77,159,255,0.07)', background: ri % 2 === 0 ? 'rgba(77,159,255,0.015)' : 'transparent', animation: 'slideUp ' + (0.1 + ri * 0.05) + 's ease both' }}>
                    <div style={{ padding: '10px 8px', fontSize: 11, fontWeight: 700, color: 'rgba(160,200,240,0.5)', display: 'flex', alignItems: 'center' }}>{row.label}</div>
                    {selected.map((b, bi) => {
                      const isBest = bestIdx === bi
                      const isWorst = bestIdx >= 0 && !isBest && row.better !== 'none' && selected.length > 1
                      return (
                        <div key={b._id} style={{ padding: '10px 8px', textAlign: 'center', background: isBest ? 'rgba(39,174,96,0.1)' : isWorst ? 'rgba(231,76,60,0.04)' : 'transparent', borderLeft: '1px solid rgba(77,159,255,0.07)', transition: 'background 0.6s ease', boxShadow: isBest ? 'inset 0 0 14px rgba(39,174,96,0.1)' : 'none' }}>
                          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>
                            <span style={{ fontSize: 12, fontWeight: isBest ? 700 : 400, color: isBest ? '#27AE60' : isWorst ? 'rgba(180,180,180,0.5)' : C.text }}>{row.fmt(b)}</span>
                            {isBest && <span style={{ fontSize: 8, background: 'rgba(39,174,96,0.18)', color: '#27AE60', padding: '1px 7px', borderRadius: 20, fontWeight: 700 }}>BEST</span>}
                            {isBest && (() => { const pct = getBetterByPct(selected, row, bi); return pct ? <span style={{ fontSize: 8, color: 'rgba(39,174,96,0.7)', marginTop: 2, display: 'block' }}>{pct}</span> : null })()}
                          </div>
                        </div>
                      )
                    })}
                  </div>
                )
              })}
            </div>

            {/* Direct Action Buttons */}
            <div style={{ padding: '16px 18px 28px', borderTop: '1px solid rgba(155,89,182,0.15)' }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: 'rgba(160,200,240,0.45)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 12 }}>Quick Enroll</div>
              <div style={{ display: 'grid', gridTemplateColumns: `repeat(${selected.length},1fr)`, gap: 10 }}>
                {selected.map(b => {
                  const ec = ECOLS[b.examType] || '#4D9FFF'
                  return (
                    <div key={b._id} style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.5)', marginBottom: 7, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{b.name}</div>
                      {b.isEnrolled
                        ? <button onClick={() => { setShowModal(false); router.push('/dashboard/exams') }} style={{ width: '100%', padding: '10px', background: `${ec}20`, border: `1px solid ${ec}40`, borderRadius: 11, color: ec, fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>Continue →</button>
                        : b.isFree
                          ? <button onClick={() => enroll(b)} disabled={enrolling === b._id} style={{ width: '100%', padding: '10px', background: 'linear-gradient(135deg,#27AE60,#1E8449)', border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11, boxShadow: '0 4px 14px rgba(39,174,96,0.28)' }}>{enrolling === b._id ? 'Enrolling...' : '🚀 Enroll Free'}</button>
                          : b.allowFreeTrial
                            ? <button onClick={() => enroll(b)} disabled={enrolling === b._id} style={{ width: '100%', padding: '10px', background: `linear-gradient(135deg,${ec},${ec}BB)`, border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>{enrolling === b._id ? 'Starting...' : '🎯 Free Trial'}</button>
                            : <button style={{ width: '100%', padding: '10px', background: `linear-gradient(135deg,${ec},${ec}BB)`, border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>🛒 ₹{b.discountPrice || b.price}</button>}
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default function ComparePage() {
  return (
    <Suspense fallback={<div style={{ minHeight: '100vh', background: '#020816', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4D9FFF', fontSize: 14 }}>Loading...</div>}>
      <CompareInner />
    </Suspense>
  )
}
