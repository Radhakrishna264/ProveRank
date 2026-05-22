'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Types ──
type Banner = {
  _id?: string
  batchId: string; batchName: string; title: string; tagline: string
  examType: string; price: string; totalTests: string; duration: string
  validity: string; highlights: string[]; ctaText: string; badge: string
  template: string; primaryColor: string; secondaryColor: string
  textColor: string; accentColor: string; fontStyle: string; bgImage: string
  published: boolean; scheduledAt?: string
  versions?: { data: object; savedAt: string; label: string }[]
  analytics?: { views: number; clicks: number; enrolls: number }
  createdAt?: string
}

const EMPTY: Banner = {
  batchId: '', batchName: '', title: '', tagline: '', examType: 'NEET',
  price: '', totalTests: '', duration: '', validity: '',
  highlights: ['', '', ''], ctaText: 'Enroll Now', badge: 'none',
  template: 'classic', primaryColor: '#4D9FFF', secondaryColor: '#00D4FF',
  textColor: '#FFFFFF', accentColor: '#FFD700', fontStyle: 'modern',
  bgImage: '', published: false
}

const TEMPLATES = [
  { id: 'classic', label: 'Classic Premium', desc: 'Dark gradient, gold accent', bg: 'linear-gradient(135deg,#0a0a1a,#1a1a3e)', accent: '#FFD700' },
  { id: 'glass', label: 'Glassmorphism', desc: 'Frosted glass effect', bg: 'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(155,89,182,0.15))', accent: '#4D9FFF' },
  { id: 'neet', label: 'Vibrant NEET', desc: 'Green-blue gradient', bg: 'linear-gradient(135deg,#004d40,#006064)', accent: '#00E5FF' },
  { id: 'minimal', label: 'Minimal Clean', desc: 'Clean, bold typography', bg: 'linear-gradient(135deg,#f8f9fa,#e9ecef)', accent: '#1a237e' },
  { id: 'cosmic', label: 'Cosmic Dark', desc: 'Deep space theme', bg: 'linear-gradient(135deg,#020816,#0d1b2a)', accent: '#4D9FFF' },
  { id: 'warrior', label: 'Exam Warrior', desc: 'Bold orange-red energy', bg: 'linear-gradient(135deg,#bf360c,#e65100)', accent: '#FFD700' },
  { id: 'gold', label: 'Gold Elite', desc: 'Luxury gold-black', bg: 'linear-gradient(135deg,#1a1200,#3d2e00)', accent: '#FFD700' },
  { id: 'aurora', label: 'Dark Aurora', desc: 'Purple-teal aurora', bg: 'linear-gradient(135deg,#1a0533,#003333)', accent: '#00FFD1' },
]

const PRESETS = [
  { name: 'Ocean', p: '#0277BD', s: '#00ACC1', t: '#FFFFFF', a: '#80DEEA' },
  { name: 'Forest', p: '#2E7D32', s: '#00695C', t: '#FFFFFF', a: '#CCFF90' },
  { name: 'Sunset', p: '#BF360C', s: '#E65100', t: '#FFFFFF', a: '#FFD740' },
  { name: 'Royal', p: '#4527A0', s: '#283593', t: '#FFFFFF', a: '#E040FB' },
  { name: 'Gold', p: '#1a1200', s: '#3d2e00', t: '#FFD700', a: '#FFA000' },
  { name: 'Neon', p: '#006064', s: '#004d40', t: '#FFFFFF', a: '#69FF47' },
]

const FONTS = [
  { id: 'modern', label: 'Bold Modern', family: 'Inter,sans-serif', weight: 800 },
  { id: 'serif', label: 'Elegant Serif', family: 'Playfair Display,serif', weight: 700 },
  { id: 'clean', label: 'Clean Sans', family: 'Inter,sans-serif', weight: 600 },
]

const BADGES = [
  { id: 'none', label: 'None' }, { id: 'new', label: '✨ New' },
  { id: 'hot', label: '🔥 Hot' }, { id: 'sale', label: '🏷️ Sale' },
  { id: 'limited', label: '⚡ Limited' }, { id: 'premium', label: '💎 Premium' },
]

const EXAM_SUBJECTS: Record<string, string> = {
  NEET: '🧬', JEE: '⚙️', CUET: '📖', 'Class 11': '📗', 'Class 12': '📘',
  Foundation: '🏛️', 'Crash Course': '🚀', Other: '📚'
}

// ── Live Banner Preview ──
function BannerPreview({ b, size = 'card' }: { b: Banner; size?: 'card' | 'wide' | 'square' }) {
  const tpl = TEMPLATES.find(t => t.id === b.template) || TEMPLATES[0]
  const font = FONTS.find(f => f.id === b.fontStyle) || FONTS[0]
  const isLight = b.template === 'minimal'
  const tc = isLight ? '#1a1a2e' : b.textColor

  const dims = size === 'wide' ? { w: '100%', h: 160, titleSize: 20 }
    : size === 'square' ? { w: 260, h: 260, titleSize: 16 }
    : { w: '100%', h: 'auto', titleSize: 17 }

  const badgeColors: Record<string, string> = {
    new: '#27AE60', hot: '#E74C3C', sale: '#E67E22', limited: '#9B59B6', premium: '#F39C12'
  }

  return (
    <div style={{
      background: b.bgImage ? `url(${b.bgImage}) center/cover` : tpl.bg,
      borderRadius: 16, padding: '20px 22px', position: 'relative', overflow: 'hidden',
      width: dims.w, minHeight: size === 'card' ? 200 : dims.h,
      border: `1px solid ${b.primaryColor}40`,
      boxShadow: `0 8px 32px ${b.primaryColor}25`,
      backdropFilter: b.template === 'glass' ? 'blur(20px)' : 'none',
    }}>
      {/* Subtle overlay */}
      {b.template !== 'minimal' && (
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.12)', borderRadius: 16, pointerEvents: 'none' }} />
      )}
      {/* Accent glow top-right */}
      <div style={{ position: 'absolute', top: -30, right: -30, width: 100, height: 100, borderRadius: '50%', background: `radial-gradient(circle,${b.accentColor}30,transparent)`, pointerEvents: 'none' }} />

      <div style={{ position: 'relative', zIndex: 1 }}>
        {/* Top row: Exam type + Badge */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <span style={{ background: `${b.primaryColor}30`, color: b.primaryColor, fontSize: 10, fontWeight: 700, padding: '3px 10px', borderRadius: 20, border: `1px solid ${b.primaryColor}50`, fontFamily: 'Inter,sans-serif' }}>
            {EXAM_SUBJECTS[b.examType] || '📚'} {b.examType}
          </span>
          {b.badge !== 'none' && (
            <span style={{ background: badgeColors[b.badge] || '#888', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 10px', borderRadius: 20, fontFamily: 'Inter,sans-serif' }}>
              {BADGES.find(x => x.id === b.badge)?.label}
            </span>
          )}
        </div>

        {/* Title */}
        <div style={{ fontFamily: font.family, fontWeight: font.weight, fontSize: dims.titleSize, color: tc, lineHeight: 1.3, marginBottom: 5, textShadow: b.template !== 'minimal' ? `0 2px 8px rgba(0,0,0,0.4)` : 'none' }}>
          {b.title || 'Batch Title Here'}
        </div>

        {/* Tagline */}
        {b.tagline && (
          <div style={{ fontSize: 11, color: b.template === 'minimal' ? '#555' : 'rgba(255,255,255,0.75)', marginBottom: 10, fontFamily: 'Inter,sans-serif', fontStyle: 'italic' }}>
            {b.tagline}
          </div>
        )}

        {/* Stats row */}
        <div style={{ display: 'flex', gap: 10, marginBottom: 12, flexWrap: 'wrap' }}>
          {b.totalTests && <span style={{ fontSize: 10, color: b.template === 'minimal' ? '#444' : 'rgba(255,255,255,0.7)', fontFamily: 'Inter,sans-serif' }}>📝 {b.totalTests} Tests</span>}
          {b.duration && <span style={{ fontSize: 10, color: b.template === 'minimal' ? '#444' : 'rgba(255,255,255,0.7)', fontFamily: 'Inter,sans-serif' }}>⏱️ {b.duration}</span>}
          {b.validity && <span style={{ fontSize: 10, color: b.template === 'minimal' ? '#444' : 'rgba(255,255,255,0.7)', fontFamily: 'Inter,sans-serif' }}>📅 {b.validity}</span>}
        </div>

        {/* Highlights */}
        {b.highlights.filter(Boolean).length > 0 && (
          <div style={{ marginBottom: 12 }}>
            {b.highlights.filter(Boolean).map((h, i) => (
              <div key={i} style={{ fontSize: 10, color: b.template === 'minimal' ? '#333' : 'rgba(255,255,255,0.82)', marginBottom: 3, display: 'flex', gap: 6, fontFamily: 'Inter,sans-serif' }}>
                <span style={{ color: b.accentColor, flexShrink: 0 }}>✓</span>{h}
              </div>
            ))}
          </div>
        )}

        {/* Bottom: Price + CTA */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, flexWrap: 'wrap' }}>
          <div>
            {b.price && (
              <span style={{ fontFamily: font.family, fontWeight: 800, fontSize: 20, color: b.accentColor, textShadow: `0 0 12px ${b.accentColor}60` }}>
                {b.price.toLowerCase() === 'free' ? 'FREE' : `₹${b.price}`}
              </span>
            )}
          </div>
          <button style={{ background: `linear-gradient(135deg,${b.primaryColor},${b.secondaryColor})`, border: 'none', borderRadius: 10, padding: '8px 18px', color: '#fff', fontWeight: 700, fontSize: 11, cursor: 'pointer', fontFamily: 'Inter,sans-serif', boxShadow: `0 4px 14px ${b.primaryColor}40`, whiteSpace: 'nowrap' }}>
            {b.ctaText || 'Enroll Now'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Input helper ──
function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'rgba(180,200,220,0.7)', marginBottom: 5, textTransform: 'uppercase', letterSpacing: 0.8 }}>{label}</label>
      {children}
    </div>
  )
}

const INP = { width: '100%', padding: '9px 12px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 10, color: '#F0F8FF', fontSize: 13, fontFamily: 'Inter,sans-serif', outline: 'none' } as React.CSSProperties

// ── Main Page ──
export default function BannerGeneratorPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [darkMode, setDarkMode] = useState(true)
  const [form, setForm] = useState<Banner>({ ...EMPTY })
  const [banners, setBanners] = useState<Banner[]>([])
  const [editId, setEditId] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [tab, setTab] = useState<'editor' | 'library'>('editor')
  const [previewSize, setPreviewSize] = useState<'card' | 'wide' | 'square'>('card')
  const [showVersions, setShowVersions] = useState(false)
  const [toast, setToast] = useState('')
  const [batches, setBatches] = useState<{ _id: string; name: string; examType: string }[]>([])
  const [tok, setTok] = useState('')

  const BG = darkMode ? '#0a0e1a' : '#f0f4f8'
  const CARD = darkMode ? 'rgba(15,20,40,0.95)' : 'rgba(255,255,255,0.95)'
  const BORDER = darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'
  const TEXT = darkMode ? '#F0F8FF' : '#1a1a2e'
  const SUB = darkMode ? 'rgba(180,200,220,0.6)' : 'rgba(0,0,0,0.5)'

  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t)
    fetchBanners(t)
    fetchBatches(t)
    // Pre-fill from URL param (from Batch Management "Generate Banner" button)
    const bId = searchParams.get('batchId')
    const bName = searchParams.get('batchName')
    if (bId && bName) {
      setForm(prev => ({ ...prev, batchId: bId, batchName: bName, title: bName }))
    }
  }, [])

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000) }

  const fetchBanners = async (t: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners`, { headers: { Authorization: `Bearer ${t}` } })
      const d = await r.json(); setBanners(d.banners || [])
    } catch { }
  }

  const fetchBatches = async (t: string) => {
    try {
      const r = await fetch(`${API}/api/admin/batches`, { headers: { Authorization: `Bearer ${t}` } })
      const d = await r.json(); setBatches(d.batches || [])
    } catch { }
  }

  const upd = (k: keyof Banner, v: string | boolean | string[]) => setForm(prev => ({ ...prev, [k]: v }))

  const save = async () => {
    if (!form.title.trim()) return showToast('❌ Title is required')
    setSaving(true)
    try {
      const method = editId ? 'PUT' : 'POST'
      const url = editId ? `${API}/api/admin/banners/${editId}` : `${API}/api/admin/banners`
      const r = await fetch(url, { method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` }, body: JSON.stringify(form) })
      const d = await r.json()
      if (d.success) { showToast('✅ Banner saved!'); fetchBanners(tok); setEditId(d.banner._id); }
      else showToast('❌ ' + (d.error || 'Error'))
    } catch { showToast('❌ Network error') } finally { setSaving(false) }
  }

  const deleteBanner = async (id: string) => {
    if (!confirm('Delete this banner?')) return
    await fetch(`${API}/api/admin/banners/${id}`, { method: 'DELETE', headers: { Authorization: `Bearer ${tok}` } })
    fetchBanners(tok); showToast('🗑️ Deleted')
    if (editId === id) { setEditId(null); setForm({ ...EMPTY }) }
  }

  const duplicate = async (id: string) => {
    await fetch(`${API}/api/admin/banners/${id}/duplicate`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
    fetchBanners(tok); showToast('📋 Duplicated!')
  }

  const togglePublish = async (id: string) => {
    const r = await fetch(`${API}/api/admin/banners/${id}/publish`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
    const d = await r.json()
    fetchBanners(tok); showToast(d.published ? '🟢 Published!' : '⭕ Unpublished')
  }

  const loadBanner = (b: Banner) => { setForm({ ...b }); setEditId(b._id || null); setTab('editor'); setShowVersions(false) }

  const newBanner = () => { setForm({ ...EMPTY }); setEditId(null); setShowVersions(false) }

  const restoreVersion = async (vIdx: number) => {
    if (!editId) return
    await fetch(`${API}/api/admin/banners/${editId}/restore/${vIdx}`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
    const r = await fetch(`${API}/api/admin/banners/${editId}`, { headers: { Authorization: `Bearer ${tok}` } })
    const d = await r.json(); if (d.banner) { setForm({ ...d.banner }); showToast('🔄 Version restored!') }
  }

  const inpStyle = { ...INP, background: darkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)', border: `1px solid ${BORDER}`, color: TEXT } as React.CSSProperties

  return (
    <div style={{ minHeight: '100vh', background: BG, color: TEXT, fontFamily: 'Inter,sans-serif', transition: 'all 0.3s' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700;800&display=swap');
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:4px;height:4px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
        input,select,textarea{outline:none}
        input::placeholder,textarea::placeholder{color:rgba(150,170,200,0.45)}
        @keyframes slideUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        @keyframes toastIn{from{opacity:0;transform:translateX(40px)}to{opacity:1;transform:translateX(0)}}
      `}</style>

      {/* ── TOP BAR ── */}
      <div style={{ position: 'sticky', top: 0, zIndex: 100, background: darkMode ? 'rgba(10,14,26,0.96)' : 'rgba(240,244,248,0.96)', backdropFilter: 'blur(20px)', borderBottom: `1px solid ${BORDER}`, padding: '12px 20px', display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
        <button onClick={() => router.back()} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#4D9FFF', fontSize: 18, flexShrink: 0 }}>←</button>
        <div style={{ fontSize: 18, fontWeight: 800, fontFamily: 'Playfair Display,serif', background: 'linear-gradient(135deg,#4D9FFF,#9B59B6)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>🎨 Banner Generator</div>
        <div style={{ flex: 1 }} />
        {/* Tabs */}
        <div style={{ display: 'flex', gap: 6 }}>
          {(['editor', 'library'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)} style={{ padding: '7px 16px', borderRadius: 10, background: tab === t ? 'rgba(77,159,255,0.18)' : 'transparent', border: `1px solid ${tab === t ? 'rgba(77,159,255,0.4)' : BORDER}`, color: tab === t ? '#4D9FFF' : SUB, fontWeight: tab === t ? 700 : 400, cursor: 'pointer', fontSize: 12 }}>
              {t === 'editor' ? '✏️ Editor' : `🗂️ Library (${banners.length})`}
            </button>
          ))}
        </div>
        <button onClick={() => setDarkMode(d => !d)} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '7px 12px', cursor: 'pointer', color: TEXT, fontSize: 14 }}>{darkMode ? '☀️' : '🌙'}</button>
        <button onClick={newBanner} style={{ background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 10, padding: '8px 16px', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 12 }}>+ New</button>
      </div>

      {/* ── TOAST ── */}
      {toast && (
        <div style={{ position: 'fixed', top: 70, right: 20, background: darkMode ? 'rgba(15,20,40,0.97)' : '#fff', border: `1px solid ${BORDER}`, borderRadius: 12, padding: '12px 18px', fontSize: 13, fontWeight: 600, color: TEXT, zIndex: 999, animation: 'toastIn 0.3s ease', boxShadow: '0 8px 30px rgba(0,0,0,0.25)' }}>
          {toast}
        </div>
      )}

      {/* ── EDITOR TAB ── */}
      {tab === 'editor' && (
        <div style={{ maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px', display: 'grid', gridTemplateColumns: 'minmax(340px,440px) 1fr', gap: 20, alignItems: 'start' }}>

          {/* LEFT: Form */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>

            {/* Batch Link */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 0.8 }}>🔗 Link to Batch</div>
              <Field label="Select Batch (optional)">
                <select value={form.batchId} onChange={e => {
                  const b = batches.find(x => x._id === e.target.value)
                  if (b) { upd('batchId', b._id); upd('batchName', b.name); if (!form.title) upd('title', b.name); upd('examType', b.examType) }
                  else upd('batchId', '')
                }} style={inpStyle}>
                  <option value="">— No Batch Linked —</option>
                  {batches.map(b => <option key={b._id} value={b._id}>{b.name}</option>)}
                </select>
              </Field>
              {form.batchId && <div style={{ fontSize: 11, color: '#4D9FFF', marginTop: -6 }}>✅ Linked: {form.batchName}</div>}
            </div>

            {/* Banner Content */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', marginBottom: 14, textTransform: 'uppercase', letterSpacing: 0.8 }}>📝 Banner Content</div>
              <Field label="Batch Title *">
                <input value={form.title} onChange={e => upd('title', e.target.value)} placeholder="e.g. NEET Full Syllabus Batch 2025" style={inpStyle} />
              </Field>
              <Field label="Short Tagline">
                <input value={form.tagline} onChange={e => upd('tagline', e.target.value)} placeholder="e.g. Master every topic with AI-powered tests" style={inpStyle} />
              </Field>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <Field label="Exam Type">
                  <select value={form.examType} onChange={e => upd('examType', e.target.value)} style={inpStyle}>
                    {Object.keys(EXAM_SUBJECTS).map(k => <option key={k} value={k}>{k}</option>)}
                  </select>
                </Field>
                <Field label="Price (₹ or Free)">
                  <input value={form.price} onChange={e => upd('price', e.target.value)} placeholder="499 or Free" style={inpStyle} />
                </Field>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
                <Field label="Total Tests">
                  <input value={form.totalTests} onChange={e => upd('totalTests', e.target.value)} placeholder="120" style={inpStyle} />
                </Field>
                <Field label="Duration">
                  <input value={form.duration} onChange={e => upd('duration', e.target.value)} placeholder="3 Months" style={inpStyle} />
                </Field>
                <Field label="Validity">
                  <input value={form.validity} onChange={e => upd('validity', e.target.value)} placeholder="365 Days" style={inpStyle} />
                </Field>
              </div>
              <Field label="Key Highlights (3 points)">
                {[0, 1, 2].map(i => (
                  <input key={i} value={form.highlights[i] || ''} onChange={e => { const h = [...form.highlights]; h[i] = e.target.value; upd('highlights', h) }} placeholder={`Highlight ${i + 1}`} style={{ ...inpStyle, marginBottom: 6 }} />
                ))}
              </Field>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <Field label="CTA Button Text">
                  <input value={form.ctaText} onChange={e => upd('ctaText', e.target.value)} placeholder="Enroll Now" style={inpStyle} />
                </Field>
                <Field label="Badge / Ribbon">
                  <select value={form.badge} onChange={e => upd('badge', e.target.value)} style={inpStyle}>
                    {BADGES.map(b => <option key={b.id} value={b.id}>{b.label}</option>)}
                  </select>
                </Field>
              </div>
            </div>

            {/* Template Gallery */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', marginBottom: 14, textTransform: 'uppercase', letterSpacing: 0.8 }}>🎨 Template</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8 }}>
                {TEMPLATES.map(t => (
                  <div key={t.id} onClick={() => upd('template', t.id)} style={{ cursor: 'pointer', borderRadius: 10, overflow: 'hidden', border: `2px solid ${form.template === t.id ? '#4D9FFF' : BORDER}`, transition: 'all 0.2s', transform: form.template === t.id ? 'scale(1.03)' : 'scale(1)' }}>
                    <div style={{ height: 44, background: t.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <div style={{ width: 20, height: 3, background: t.accent, borderRadius: 2 }} />
                    </div>
                    <div style={{ padding: '5px 6px', background: darkMode ? 'rgba(15,20,40,0.9)' : '#fff' }}>
                      <div style={{ fontSize: 9, fontWeight: 700, color: form.template === t.id ? '#4D9FFF' : SUB, lineHeight: 1.3 }}>{t.label}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Colors */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', marginBottom: 14, textTransform: 'uppercase', letterSpacing: 0.8 }}>🎨 Colors</div>
              {/* Presets */}
              <div style={{ display: 'flex', gap: 7, flexWrap: 'wrap', marginBottom: 14 }}>
                {PRESETS.map(pr => (
                  <button key={pr.name} onClick={() => { upd('primaryColor', pr.p); upd('secondaryColor', pr.s); upd('textColor', pr.t); upd('accentColor', pr.a) }} style={{ padding: '5px 12px', borderRadius: 20, fontSize: 10, cursor: 'pointer', background: `linear-gradient(135deg,${pr.p},${pr.s})`, border: 'none', color: '#fff', fontWeight: 600 }}>{pr.name}</button>
                ))}
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                {[
                  { label: 'Primary', key: 'primaryColor' as const },
                  { label: 'Secondary', key: 'secondaryColor' as const },
                  { label: 'Text', key: 'textColor' as const },
                  { label: 'Accent', key: 'accentColor' as const },
                ].map(({ label, key }) => (
                  <Field key={key} label={label}>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                      <input type="color" value={form[key] as string} onChange={e => upd(key, e.target.value)} style={{ width: 36, height: 36, border: 'none', borderRadius: 8, cursor: 'pointer', background: 'transparent' }} />
                      <input value={form[key] as string} onChange={e => upd(key, e.target.value)} style={{ ...inpStyle, flex: 1 }} />
                    </div>
                  </Field>
                ))}
              </div>
            </div>

            {/* Typography */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 0.8 }}>🔤 Typography</div>
              <div style={{ display: 'flex', gap: 8 }}>
                {FONTS.map(f => (
                  <button key={f.id} onClick={() => upd('fontStyle', f.id)} style={{ flex: 1, padding: '8px 6px', borderRadius: 10, background: form.fontStyle === f.id ? 'rgba(77,159,255,0.18)' : 'transparent', border: `1px solid ${form.fontStyle === f.id ? 'rgba(77,159,255,0.4)' : BORDER}`, color: form.fontStyle === f.id ? '#4D9FFF' : SUB, fontWeight: form.fontStyle === f.id ? 700 : 400, cursor: 'pointer', fontSize: 11, fontFamily: f.family }}>
                    {f.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Scheduled Publish */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 0.8 }}>📅 Scheduled Publish</div>
              <Field label="Publish At (optional)">
                <input type="datetime-local" value={form.scheduledAt || ''} onChange={e => upd('scheduledAt', e.target.value)} style={inpStyle} />
              </Field>
              <div style={{ fontSize: 11, color: SUB }}>Leave empty to publish manually</div>
            </div>

            {/* Save Button */}
            <button onClick={save} disabled={saving} style={{ width: '100%', padding: '14px', background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 14, color: '#fff', fontWeight: 800, cursor: 'pointer', fontSize: 14, boxShadow: '0 6px 24px rgba(77,159,255,0.4)', transition: 'all 0.2s' }}>
              {saving ? '⏳ Saving...' : editId ? '💾 Update Banner' : '✨ Create Banner'}
            </button>
          </div>

          {/* RIGHT: Preview */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16, position: 'sticky', top: 76 }}>

            {/* Preview Header */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 16, backdropFilter: 'blur(16px)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: TEXT }}>👁️ Live Preview</div>
              <div style={{ display: 'flex', gap: 6 }}>
                {(['card', 'wide', 'square'] as const).map(s => (
                  <button key={s} onClick={() => setPreviewSize(s)} style={{ padding: '5px 12px', borderRadius: 8, background: previewSize === s ? 'rgba(77,159,255,0.18)' : 'transparent', border: `1px solid ${previewSize === s ? 'rgba(77,159,255,0.4)' : BORDER}`, color: previewSize === s ? '#4D9FFF' : SUB, cursor: 'pointer', fontSize: 11, fontWeight: previewSize === s ? 700 : 400 }}>
                    {s === 'card' ? '🃏 Card' : s === 'wide' ? '📺 Wide' : '⬜ Square'}
                  </button>
                ))}
              </div>
              {editId && (
                <button onClick={() => togglePublish(editId)} style={{ padding: '6px 14px', borderRadius: 10, background: form.published ? 'rgba(39,174,96,0.18)' : 'rgba(231,76,60,0.12)', border: `1px solid ${form.published ? 'rgba(39,174,96,0.4)' : 'rgba(231,76,60,0.3)'}`, color: form.published ? '#27AE60' : '#E74C3C', cursor: 'pointer', fontSize: 12, fontWeight: 700 }}>
                  {form.published ? '🟢 Published' : '⭕ Unpublished'}
                </button>
              )}
            </div>

            {/* Preview Canvas */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 20, padding: 24, backdropFilter: 'blur(16px)', display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 300 }}>
              <div style={{ width: previewSize === 'square' ? 260 : '100%', maxWidth: previewSize === 'wide' ? '100%' : 460 }}>
                <BannerPreview b={form} size={previewSize} />
              </div>
            </div>

            {/* Analytics (if editing existing) */}
            {editId && (() => {
              const cur = banners.find(b => b._id === editId)
              if (!cur?.analytics) return null
              return (
                <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
                  <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 0.8 }}>📊 Banner Analytics</div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 10 }}>
                    {[
                      { label: 'Views', v: cur.analytics!.views, c: '#4D9FFF', i: '👁️' },
                      { label: 'Clicks', v: cur.analytics!.clicks, c: '#9B59B6', i: '👆' },
                      { label: 'Enrolls', v: cur.analytics!.enrolls, c: '#27AE60', i: '✅' },
                    ].map(s => (
                      <div key={s.label} style={{ background: `${s.c}10`, border: `1px solid ${s.c}25`, borderRadius: 12, padding: '12px 10px', textAlign: 'center' }}>
                        <div style={{ fontSize: 18 }}>{s.i}</div>
                        <div style={{ fontSize: 20, fontWeight: 800, color: s.c }}>{s.v}</div>
                        <div style={{ fontSize: 10, color: SUB }}>{s.label}</div>
                      </div>
                    ))}
                  </div>
                  {cur.analytics!.views > 0 && (
                    <div style={{ marginTop: 10, fontSize: 11, color: SUB }}>
                      Click rate: {((cur.analytics!.clicks / cur.analytics!.views) * 100).toFixed(1)}% · Conversion: {((cur.analytics!.enrolls / cur.analytics!.views) * 100).toFixed(1)}%
                    </div>
                  )}
                </div>
              )
            })()}

            {/* Version History */}
            {editId && form.versions && form.versions.length > 0 && (
              <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                  <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', textTransform: 'uppercase', letterSpacing: 0.8 }}>🕐 Version History</div>
                  <button onClick={() => setShowVersions(v => !v)} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 8, padding: '4px 10px', cursor: 'pointer', color: SUB, fontSize: 11 }}>{showVersions ? 'Hide' : 'Show'}</button>
                </div>
                {showVersions && form.versions.map((v, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 0', borderBottom: `1px solid ${BORDER}` }}>
                    <div>
                      <div style={{ fontSize: 12, fontWeight: 600, color: TEXT }}>{v.label}</div>
                      <div style={{ fontSize: 10, color: SUB }}>{new Date(v.savedAt).toLocaleString()}</div>
                    </div>
                    <button onClick={() => restoreVersion(i)} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 8, padding: '4px 10px', cursor: 'pointer', color: '#4D9FFF', fontSize: 11 }}>Restore</button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── LIBRARY TAB ── */}
      {tab === 'library' && (
        <div style={{ maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px' }}>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TEXT, marginBottom: 20 }}>🗂️ Banner Library</div>
          {banners.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '60px 20px', color: SUB }}>
              <div style={{ fontSize: 56, marginBottom: 16 }}>🎨</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: TEXT, marginBottom: 8 }}>No Banners Yet</div>
              <div style={{ fontSize: 13, marginBottom: 24 }}>Create your first banner from the Editor tab</div>
              <button onClick={() => setTab('editor')} style={{ background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 12, padding: '12px 28px', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 13 }}>+ Create Banner</button>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(320px,1fr))', gap: 20 }}>
              {banners.map(b => (
                <div key={b._id} style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 18, overflow: 'hidden', backdropFilter: 'blur(16px)', transition: 'all 0.2s', animation: 'slideUp 0.4s ease' }}>
                  <div style={{ padding: 16 }}>
                    <BannerPreview b={b} size="card" />
                  </div>
                  <div style={{ padding: '0 16px 14px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                      <span style={{ fontSize: 11, background: b.published ? 'rgba(39,174,96,0.15)' : 'rgba(231,76,60,0.1)', color: b.published ? '#27AE60' : '#E74C3C', padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>{b.published ? '🟢 Live' : '⭕ Draft'}</span>
                      <span style={{ fontSize: 10, color: SUB }}>{new Date(b.createdAt || '').toLocaleDateString()}</span>
                    </div>
                    {b.analytics && (
                      <div style={{ display: 'flex', gap: 10, marginBottom: 10, fontSize: 10, color: SUB }}>
                        <span>👁️ {b.analytics.views}</span>
                        <span>👆 {b.analytics.clicks}</span>
                        <span>✅ {b.analytics.enrolls}</span>
                      </div>
                    )}
                    <div style={{ display: 'flex', gap: 7, flexWrap: 'wrap' }}>
                      <button onClick={() => loadBanner(b)} style={{ flex: 1, padding: '7px', background: 'rgba(77,159,255,0.12)', border: '1px solid rgba(77,159,255,0.25)', borderRadius: 10, color: '#4D9FFF', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>✏️ Edit</button>
                      <button onClick={() => togglePublish(b._id!)} style={{ flex: 1, padding: '7px', background: b.published ? 'rgba(231,76,60,0.1)' : 'rgba(39,174,96,0.12)', border: `1px solid ${b.published ? 'rgba(231,76,60,0.3)' : 'rgba(39,174,96,0.3)'}`, borderRadius: 10, color: b.published ? '#E74C3C' : '#27AE60', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>{b.published ? '⭕ Unpublish' : '🟢 Publish'}</button>
                      <button onClick={() => duplicate(b._id!)} style={{ padding: '7px 10px', background: 'rgba(155,89,182,0.1)', border: '1px solid rgba(155,89,182,0.25)', borderRadius: 10, color: '#9B59B6', cursor: 'pointer', fontSize: 11 }}>📋</button>
                      <button onClick={() => deleteBanner(b._id!)} style={{ padding: '7px 10px', background: 'rgba(231,76,60,0.08)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 10, color: '#E74C3C', cursor: 'pointer', fontSize: 11 }}>🗑️</button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
