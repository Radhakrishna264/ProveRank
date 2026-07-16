'use client'
import { useState, useEffect, useRef, useCallback, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

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

export default function BannerGeneratorPage() {
  return (
    <Suspense fallback={<div style={{minHeight:'100vh',background:'#0a0e1a',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontSize:14}}>Loading...</div>}>
      <BannerGeneratorInner />
    </Suspense>
  )
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

// ── Subject Illustration Library SVGs ──
const ILLUSTRATIONS = [
  {
    id: 'dna', name: 'DNA Double Helix', category: 'Biology',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M20 5 Q40 20 60 5" stroke="#27AE60" stroke-width="3" fill="none" stroke-linecap="round"/>
      <path d="M20 15 Q40 30 60 15" stroke="#4D9FFF" stroke-width="3" fill="none" stroke-linecap="round"/>
      <path d="M20 25 Q40 40 60 25" stroke="#27AE60" stroke-width="3" fill="none" stroke-linecap="round"/>
      <path d="M20 35 Q40 50 60 35" stroke="#4D9FFF" stroke-width="3" fill="none" stroke-linecap="round"/>
      <path d="M20 45 Q40 60 60 45" stroke="#27AE60" stroke-width="3" fill="none" stroke-linecap="round"/>
      <path d="M20 55 Q40 70 60 55" stroke="#4D9FFF" stroke-width="3" fill="none" stroke-linecap="round"/>
      <path d="M20 65 Q40 80 60 65" stroke="#27AE60" stroke-width="3" fill="none" stroke-linecap="round"/>
      <line x1="30" y1="10" x2="50" y2="10" stroke="#E74C3C" stroke-width="2"/>
      <line x1="25" y1="30" x2="55" y2="30" stroke="#E74C3C" stroke-width="2"/>
      <line x1="28" y1="50" x2="52" y2="50" stroke="#E74C3C" stroke-width="2"/>
      <circle cx="20" cy="5" r="3" fill="#27AE60"/><circle cx="60" cy="5" r="3" fill="#4D9FFF"/>
      <circle cx="20" cy="65" r="3" fill="#27AE60"/><circle cx="60" cy="65" r="3" fill="#4D9FFF"/>
    </svg>`
  },
  {
    id: 'atom', name: 'Atom Structure', category: 'Physics/Chemistry',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="40" cy="40" r="6" fill="#FFD700"/>
      <ellipse cx="40" cy="40" rx="30" ry="12" stroke="#4D9FFF" stroke-width="2" fill="none"/>
      <ellipse cx="40" cy="40" rx="30" ry="12" stroke="#4D9FFF" stroke-width="2" fill="none" transform="rotate(60 40 40)"/>
      <ellipse cx="40" cy="40" rx="30" ry="12" stroke="#4D9FFF" stroke-width="2" fill="none" transform="rotate(120 40 40)"/>
      <circle cx="70" cy="40" r="4" fill="#E74C3C"/>
      <circle cx="25" cy="14" r="4" fill="#27AE60"/>
      <circle cx="25" cy="66" r="4" fill="#9B59B6"/>
    </svg>`
  },
  {
    id: 'cell', name: 'Cell Structure', category: 'Biology',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <ellipse cx="40" cy="40" rx="35" ry="28" stroke="#27AE60" stroke-width="2.5" fill="rgba(39,174,96,0.08)"/>
      <circle cx="40" cy="40" r="10" fill="rgba(77,159,255,0.3)" stroke="#4D9FFF" stroke-width="2"/>
      <circle cx="40" cy="40" r="5" fill="#4D9FFF"/>
      <circle cx="22" cy="30" r="5" fill="rgba(155,89,182,0.4)" stroke="#9B59B6" stroke-width="1.5"/>
      <circle cx="58" cy="32" r="4" fill="rgba(231,76,60,0.3)" stroke="#E74C3C" stroke-width="1.5"/>
      <circle cx="20" cy="50" r="3" fill="rgba(255,215,0,0.5)" stroke="#FFD700" stroke-width="1"/>
      <circle cx="60" cy="50" r="4" fill="rgba(39,174,96,0.4)" stroke="#27AE60" stroke-width="1.5"/>
      <circle cx="35" cy="58" r="3" fill="rgba(231,76,60,0.3)" stroke="#E74C3C" stroke-width="1"/>
    </svg>`
  },
  {
    id: 'periodic', name: 'Periodic Table', category: 'Chemistry',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      ${[0,1,2,3].map(row => [0,1,2,3].map(col => `
        <rect x="${8+col*18}" y="${8+row*18}" width="15" height="15" rx="2"
          fill="rgba(${row===0?'77,159,255':row===1?'39,174,96':row===2?'231,76,60':'155,89,182'},0.2)"
          stroke="${row===0?'#4D9FFF':row===1?'#27AE60':row===2?'#E74C3C':'#9B59B6'}" stroke-width="1"/>
        <text x="${15.5+col*18}" y="${19+row*18}" font-size="5" fill="white" text-anchor="middle" font-weight="bold">
          ${[['H','He','Li','Be'],['C','N','O','F'],['Na','Mg','Al','Si'],['P','S','Cl','Ar']][row][col]}
        </text>
      `).join('')).join('')}
    </svg>`
  },
  {
    id: 'wave', name: 'Wave / Light', category: 'Physics',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M5 40 Q15 20 25 40 Q35 60 45 40 Q55 20 65 40 Q75 60 80 40" stroke="#4D9FFF" stroke-width="2.5" fill="none" stroke-linecap="round"/>
      <path d="M5 50 Q15 30 25 50 Q35 70 45 50 Q55 30 65 50 Q75 70 80 50" stroke="#9B59B6" stroke-width="2" fill="none" stroke-linecap="round" stroke-dasharray="3,2"/>
      <line x1="5" y1="40" x2="75" y2="40" stroke="rgba(255,255,255,0.15)" stroke-width="1" stroke-dasharray="2,2"/>
      <text x="5" y="15" font-size="8" fill="#FFD700" font-weight="bold">λ</text>
      <text x="40" y="15" font-size="8" fill="#E74C3C" font-weight="bold">f</text>
      <text x="65" y="15" font-size="8" fill="#27AE60" font-weight="bold">c</text>
    </svg>`
  },
  {
    id: 'equation', name: 'E = mc²', category: 'Physics',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="5" y="25" width="70" height="30" rx="8" fill="rgba(77,159,255,0.08)" stroke="rgba(77,159,255,0.3)" stroke-width="1"/>
      <text x="40" y="47" font-size="20" fill="#4D9FFF" text-anchor="middle" font-weight="bold" font-family="serif">E=mc²</text>
      <text x="40" y="68" font-size="7" fill="rgba(160,200,240,0.6)" text-anchor="middle">Mass-Energy Equivalence</text>
      <circle cx="12" cy="15" r="4" fill="rgba(255,215,0,0.3)" stroke="#FFD700" stroke-width="1"/>
      <circle cx="68" cy="15" r="4" fill="rgba(231,76,60,0.3)" stroke="#E74C3C" stroke-width="1"/>
    </svg>`
  },
  {
    id: 'mitosis', name: 'Cell Division', category: 'Biology',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <ellipse cx="22" cy="40" rx="16" ry="22" stroke="#27AE60" stroke-width="2" fill="rgba(39,174,96,0.08)"/>
      <ellipse cx="58" cy="40" rx="16" ry="22" stroke="#27AE60" stroke-width="2" fill="rgba(39,174,96,0.08)"/>
      <circle cx="22" cy="40" r="6" fill="rgba(77,159,255,0.4)" stroke="#4D9FFF" stroke-width="1.5"/>
      <circle cx="58" cy="40" r="6" fill="rgba(77,159,255,0.4)" stroke="#4D9FFF" stroke-width="1.5"/>
      <line x1="36" y1="40" x2="44" y2="40" stroke="#E74C3C" stroke-width="2" stroke-dasharray="2,2"/>
      <text x="40" y="75" font-size="7" fill="rgba(160,200,240,0.6)" text-anchor="middle">Mitosis</text>
    </svg>`
  },
  {
    id: 'circuit', name: 'Circuit Diagram', category: 'Physics',
    svg: `<svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="10" y="30" width="10" height="20" rx="2" fill="none" stroke="#4D9FFF" stroke-width="2"/>
      <line x1="5" y1="40" x2="10" y2="40" stroke="#4D9FFF" stroke-width="2"/>
      <line x1="20" y1="40" x2="30" y2="40" stroke="#4D9FFF" stroke-width="2"/>
      <line x1="30" y1="25" x2="30" y2="55" stroke="#FFD700" stroke-width="2"/>
      <line x1="35" y1="28" x2="35" y2="52" stroke="#FFD700" stroke-width="2"/>
      <line x1="35" y1="40" x2="50" y2="40" stroke="#4D9FFF" stroke-width="2"/>
      <circle cx="55" cy="40" r="8" fill="none" stroke="#E74C3C" stroke-width="2"/>
      <line x1="52" y1="37" x2="58" y2="43" stroke="#E74C3C" stroke-width="1.5"/>
      <line x1="58" y1="37" x2="52" y2="43" stroke="#E74C3C" stroke-width="1.5"/>
      <line x1="63" y1="40" x2="75" y2="40" stroke="#4D9FFF" stroke-width="2"/>
      <line x1="5" y1="40" x2="5" y2="70" stroke="#4D9FFF" stroke-width="2"/>
      <line x1="75" y1="40" x2="75" y2="70" stroke="#4D9FFF" stroke-width="2"/>
      <line x1="5" y1="70" x2="75" y2="70" stroke="#4D9FFF" stroke-width="2"/>
    </svg>`
  },
]

// ── Live Banner Preview ──
function BannerPreview({ b, size = 'card', previewRef }: { b: Banner; size?: 'card' | 'wide' | 'square'; previewRef?: React.RefObject<HTMLDivElement> }) {
  const tpl = TEMPLATES.find(t => t.id === b.template) || TEMPLATES[0]
  const font = FONTS.find(f => f.id === b.fontStyle) || FONTS[0]
  const isLight = b.template === 'minimal'
  const tc = isLight ? '#1a1a2e' : b.textColor
  const dims: Record<string, { w: number | string; h: number }> = {
    card: { w: '100%', h: 220 }, wide: { w: '100%', h: 160 }, square: { w: 300, h: 300 }, mobile: { w: 320, h: 180 }
  }
  const { w, h } = dims[size]
  return (
    <div ref={previewRef} data-banner-preview="true" style={{ width: w, height: h, borderRadius: 16, overflow: 'hidden', position: 'relative', background: b.bgImage ? `url(${b.bgImage}) center/cover` : tpl.bg, fontFamily: font.family, cursor: 'pointer', flexShrink: 0 }}>
      {!b.bgImage && <div style={{ position: 'absolute', inset: 0, background: `radial-gradient(circle at 20% 50%, ${b.primaryColor}25 0%, transparent 50%), radial-gradient(circle at 80% 50%, ${b.secondaryColor}25 0%, transparent 50%)` }} />}
      <div style={{ position: 'relative', zIndex: 1, padding: size === 'wide' ? '16px 20px' : '20px', height: '100%', display: 'flex', flexDirection: size === 'wide' ? 'row' : 'column', justifyContent: size === 'wide' ? 'space-between' : 'space-between', alignItems: size === 'wide' ? 'center' : 'flex-start' }}>
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ fontSize: size === 'card' ? 22 : 18 }}>{EXAM_SUBJECTS[b.examType] || '📚'}</span>
            {b.badge !== 'none' && <span style={{ background: b.accentColor, color: isLight ? '#fff' : '#000', fontSize: 10, fontWeight: 800, padding: '2px 8px', borderRadius: 20 }}>{BADGES.find(bd => bd.id === b.badge)?.label}</span>}
            <span style={{ fontSize: 10, color: b.accentColor, fontWeight: 700, opacity: 0.9 }}>{b.examType}</span>
          </div>
          <div style={{ fontSize: size === 'card' ? 18 : 15, fontWeight: font.weight, color: tc, lineHeight: 1.3, marginBottom: 4 }}>{b.title || 'Banner Title'}</div>
          {b.tagline && <div style={{ fontSize: 11, color: tc, opacity: 0.72, marginBottom: 8 }}>{b.tagline}</div>}
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 8 }}>
            {b.totalTests && <span style={{ fontSize: 10, color: b.accentColor }}>📝 {b.totalTests} Tests</span>}
            {b.duration && <span style={{ fontSize: 10, color: tc, opacity: 0.7 }}>⏱️ {b.duration}</span>}
            {b.validity && <span style={{ fontSize: 10, color: tc, opacity: 0.7 }}>📅 {b.validity}</span>}
          </div>
          {b.highlights.filter(Boolean).length > 0 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              {b.highlights.filter(Boolean).slice(0, size === 'wide' ? 1 : 3).map((h, i) => (
                <div key={i} style={{ fontSize: 10, color: tc, opacity: 0.8, display: 'flex', alignItems: 'center', gap: 4 }}>
                  <span style={{ color: b.accentColor }}>✓</span>{h}
                </div>
              ))}
            </div>
          )}
        </div>
        <div style={{ display: 'flex', flexDirection: size === 'wide' ? 'column' : 'row', alignItems: size === 'wide' ? 'flex-end' : 'center', justifyContent: 'space-between', gap: 8, marginTop: size === 'wide' ? 0 : 12, width: size === 'wide' ? 'auto' : '100%' }}>
          <div>
            {b.price && <div style={{ fontSize: size === 'card' ? 22 : 18, fontWeight: 900, color: b.accentColor }}>₹{b.price}</div>}
          </div>
          <button style={{ background: `linear-gradient(135deg,${b.primaryColor},${b.secondaryColor})`, border: 'none', borderRadius: 10, padding: size === 'wide' ? '8px 16px' : '10px 20px', color: '#fff', fontWeight: 700, fontSize: 12, cursor: 'pointer', boxShadow: `0 4px 14px ${b.primaryColor}40`, pointerEvents: 'none' }}>{b.ctaText || 'Enroll Now'}</button>
        </div>
      </div>
    </div>
  )
}

// ── IllustrationLibrary Modal ──
function IllustrationLibrary({ onSelect, onClose }: { onSelect: (url: string) => void; onClose: () => void }) {
  const [cat, setCat] = useState('All')
  const cats = ['All', 'Biology', 'Physics', 'Chemistry', 'Physics/Chemistry']
  const filtered = cat === 'All' ? ILLUSTRATIONS : ILLUSTRATIONS.filter(i => i.category.includes(cat))
  const [copied, setCopied] = useState('')
  const getSvgUrl = (svg: string) => {
    const encoded = encodeURIComponent(svg)
    return `data:image/svg+xml,${encoded}`
  }
  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 1000, background: 'rgba(0,0,0,0.88)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div style={{ background: 'rgba(4,12,30,0.99)', border: '1px solid rgba(77,159,255,0.25)', borderRadius: 22, padding: 24, maxWidth: 560, width: '100%', maxHeight: '85vh', overflow: 'hidden', display: 'flex', flexDirection: 'column', backdropFilter: 'blur(30px)', boxShadow: '0 30px 80px rgba(0,0,0,0.6)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 18, fontWeight: 700, color: '#F0F8FF' }}>🎨 Subject Illustration Library</div>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', color: 'rgba(160,200,240,0.5)', cursor: 'pointer', fontSize: 22 }}>×</button>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 16 }}>
          {cats.map(c => (
            <button key={c} onClick={() => setCat(c)} style={{ padding: '5px 12px', borderRadius: 20, fontSize: 10, cursor: 'pointer', background: cat === c ? 'rgba(77,159,255,0.2)' : 'rgba(77,159,255,0.05)', border: `1px solid ${cat === c ? 'rgba(77,159,255,0.5)' : 'rgba(77,159,255,0.1)'}`, color: cat === c ? '#4D9FFF' : 'rgba(160,200,240,0.5)', fontWeight: cat === c ? 700 : 400 }}>{c}</button>
          ))}
        </div>
        <div style={{ overflowY: 'auto', flex: 1 }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(120px,1fr))', gap: 12 }}>
            {filtered.map(ill => (
              <div key={ill.id} style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(77,159,255,0.1)', borderRadius: 14, padding: 14, textAlign: 'center', cursor: 'pointer', transition: 'all 0.2s' }}
                onMouseEnter={e => { (e.currentTarget as HTMLDivElement).style.borderColor = 'rgba(77,159,255,0.4)'; (e.currentTarget as HTMLDivElement).style.background = 'rgba(77,159,255,0.06)' }}
                onMouseLeave={e => { (e.currentTarget as HTMLDivElement).style.borderColor = 'rgba(77,159,255,0.1)'; (e.currentTarget as HTMLDivElement).style.background = 'rgba(255,255,255,0.04)' }}>
                <div style={{ marginBottom: 8 }} dangerouslySetInnerHTML={{ __html: ill.svg }} />
                <div style={{ fontSize: 10, fontWeight: 700, color: '#F0F8FF', marginBottom: 4 }}>{ill.name}</div>
                <div style={{ fontSize: 9, color: 'rgba(160,200,240,0.45)', marginBottom: 10 }}>{ill.category}</div>
                <div style={{ display: 'flex', gap: 4, justifyContent: 'center' }}>
                  <button onClick={() => { onSelect(getSvgUrl(ill.svg)); onClose(); }}
                    style={{ flex: 1, padding: '5px 4px', background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 8, color: '#fff', cursor: 'pointer', fontSize: 9, fontWeight: 700 }}>Use as BG</button>
                  <button onClick={() => { navigator.clipboard.writeText(ill.svg); setCopied(ill.id); setTimeout(() => setCopied(''), 2000) }}
                    style={{ padding: '5px 6px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: copied === ill.id ? '#27AE60' : 'rgba(160,200,240,0.5)', cursor: 'pointer', fontSize: 9 }}>
                    {copied === ill.id ? '✓' : '📋'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function BannerGeneratorInner() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [tab, setTab] = useState<'editor' | 'library'>('editor')
  const [form, setForm] = useState<Banner>(EMPTY)
  const [banners, setBanners] = useState<Banner[]>([])
  const [batches, setBatches] = useState<any[]>([])
  const [tok, setTok] = useState('')
  const [saving, setSaving] = useState(false)
  const [editId, setEditId] = useState<string | null>(null)
  const [toast, setToast] = useState('')
  const [previewSize, setPreviewSize] = useState<'card' | 'wide' | 'square' | 'mobile'>('card')
  const [darkMode, setDarkMode] = useState(true)
  const [showVersions, setShowVersions] = useState(false)
  const [showIllustrations, setShowIllustrations] = useState(false)
  const [downloading, setDownloading] = useState(false)
  const [sharing, setSharing] = useState(false)
  const previewRef = useRef<HTMLDivElement>(null)
  const cardRef   = useRef<HTMLDivElement>(null)
  const wideRef   = useRef<HTMLDivElement>(null)
  const squareRef = useRef<HTMLDivElement>(null)
  const mobileRef = useRef<HTMLDivElement>(null)
  const [showAllVariants, setShowAllVariants] = useState(false)
  const [downloadingVariant, setDownloadingVariant] = useState<string|null>(null)

  const downloadVariant = async (ref: React.RefObject<HTMLDivElement>, label: string) => {
    setDownloadingVariant(label)
    try {
      const html2canvas = (await import('html2canvas')).default
      const canvas = await html2canvas(ref.current, { backgroundColor: null, scale: 2, useCORS: true, allowTaint: true, logging: false })
      const link = document.createElement('a')
      link.download = 'proverank-banner-' + (form.title || 'banner') + '-' + label + '.png'
      link.href = canvas.toDataURL('image/png')
      link.click()
      showToast(label + ' downloaded ✅')
    } catch { showToast('Download failed — try again') }
    finally { setDownloadingVariant(null) }
  }

  const generateAllVariants = () => { setShowAllVariants(true); showToast('All variants ready — download each below ✅') }

  const BG = darkMode ? '#0a0e1a' : '#f0f4f8'
  const CARD = darkMode ? 'rgba(15,20,40,0.95)' : 'rgba(255,255,255,0.95)'
  const BORDER = darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'
  const TEXT = darkMode ? '#F0F8FF' : '#1a1a2e'
  const SUB = darkMode ? 'rgba(180,200,220,0.6)' : 'rgba(0,0,0,0.5)'

  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t); fetchBanners(t); fetchBatches(t)
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

  const upd = (k: keyof Banner, v: any) => setForm(prev => ({ ...prev, [k]: v }))
  const updHighlight = (i: number, v: string) => setForm(prev => {
    const h = [...prev.highlights]; h[i] = v; return { ...prev, highlights: h }
  })

  const saveBanner = async () => {
    if (!form.title) return showToast('Please enter a banner title')
    setSaving(true)
    try {
      const url = editId ? `${API}/api/admin/banners/${editId}` : `${API}/api/admin/banners`
      const method = editId ? 'PUT' : 'POST'
      const r = await fetch(url, { method, headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' }, body: JSON.stringify(form) })
      const d = await r.json()
      if (d.success) { showToast(editId ? 'Banner updated ✅' : 'Banner created ✅'); setEditId(d.banner._id); fetchBanners(tok); setTab('library') }
      else showToast(d.error || 'Save failed')
    } catch { showToast('Network error') } finally { setSaving(false) }
  }

  const loadBanner = (b: Banner) => { setForm(b); setEditId(b._id!); setTab('editor') }
  const togglePublish = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/${id}/publish`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast(d.published ? 'Published 🟢' : 'Unpublished ⭕'); fetchBanners(tok) }
    } catch { showToast('Error') }
  }
  const duplicate = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/${id}/duplicate`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Duplicated ✅'); fetchBanners(tok) }
    } catch { showToast('Error') }
  }
  const deleteBanner = async (id: string) => {
    if (!window.confirm('Delete this banner?')) return
    try {
      await fetch(`${API}/api/admin/banners/${id}`, { method: 'DELETE', headers: { Authorization: `Bearer ${tok}` } })
      showToast('Deleted'); fetchBanners(tok)
    } catch { showToast('Error') }
  }
  const restoreVersion = async (vIdx: number) => {
    if (!editId) return
    try {
      const r = await fetch(`${API}/api/admin/banners/${editId}/restore/${vIdx}`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { setForm(d.banner); showToast('Version restored ✅') }
    } catch { showToast('Error') }
  }

  // ── Download Banner as Image (html2canvas) ──
  const downloadBannerImage = async () => {
    setDownloading(true)
    try {
      const el = previewRef.current
      if (!el) { showToast('Preview not found'); return }
      // Dynamic import html2canvas
      const html2canvas = (await import('html2canvas')).default
      const canvas = await html2canvas(el, {
        backgroundColor: null, scale: 2, useCORS: true, allowTaint: true,
        logging: false
      })
      const link = document.createElement('a')
      link.download = `proverank-banner-${form.title || 'banner'}.png`
      link.href = canvas.toDataURL('image/png')
      link.click()
      showToast('Banner downloaded ✅')
    } catch (e) {
      // Fallback: print
      showToast('Downloading via print...')
      window.print()
    } finally { setDownloading(false) }
  }

  // ── WhatsApp / Social Share ──
  const shareBanner = async () => {
    setSharing(true)
    try {
      const shareData = {
        title: `ProveRank — ${form.title || 'Test Series Banner'}`,
        text: `${form.title}\n${form.tagline}\n₹${form.price} | ${form.totalTests} Tests\n\nEnroll Now on ProveRank!`,
        url: window.location.href,
      }
      if (navigator.share) {
        await navigator.share(shareData)
        showToast('Shared successfully ✅')
      } else {
        // Fallback: WhatsApp direct link
        const whatsappText = encodeURIComponent(`🎓 *${form.title}*\n${form.tagline}\n💰 ₹${form.price} | 📝 ${form.totalTests} Tests\n\n👉 Enroll on ProveRank: ${window.location.href}`)
        window.open(`https://wa.me/?text=${whatsappText}`, '_blank')
        showToast('Opening WhatsApp ✅')
      }
    } catch { showToast('Share cancelled') } finally { setSharing(false) }
  }

  // ── Share Banner URL ──
  const copyShareLink = (b: Banner) => {
    const url = `${window.location.origin}/admin/x7k2p/banner-generator?editBanner=${b._id}`
    navigator.clipboard.writeText(url)
    showToast('Link copied ✅')
  }

  const inpStyle = { width: '100%', padding: '9px 12px', background: darkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)', border: `1px solid ${BORDER}`, borderRadius: 10, color: TEXT, fontSize: 12, outline: 'none', fontFamily: 'Inter,sans-serif' }
  const labelStyle = { fontSize: 10, color: SUB, fontWeight: 700, textTransform: 'uppercase' as const, letterSpacing: 0.8, marginBottom: 5, display: 'block' }

  return (
    <div style={{ minHeight: '100vh', background: BG, color: TEXT, fontFamily: 'Inter,sans-serif', transition: 'background 0.3s' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700;800&display=swap');
        *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
        input,select,textarea{outline:none} @keyframes slideUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
        @media print { body { background: white !important; } [data-no-print] { display: none !important; } }
      `}</style>

      {/* TOAST */}
      {toast && <div style={{ position: 'fixed', top: 20, left: '50%', transform: 'translateX(-50%)', zIndex: 9999, background: 'rgba(4,12,30,0.98)', border: '1px solid rgba(77,159,255,0.3)', borderRadius: 12, padding: '12px 24px', fontSize: 13, fontWeight: 600, boxShadow: '0 8px 40px rgba(0,0,0,0.5)', backdropFilter: 'blur(20px)', whiteSpace: 'nowrap' }}>{toast}</div>}

      {/* ILLUSTRATION LIBRARY MODAL */}
      {showIllustrations && (
        <IllustrationLibrary
          onSelect={(url) => { upd('bgImage', url); showToast('Illustration applied ✅') }}
          onClose={() => setShowIllustrations(false)}
        />
      )}

      {/* HEADER */}
      <div data-no-print style={{ background: darkMode ? 'rgba(10,14,26,0.96)' : 'rgba(255,255,255,0.96)', backdropFilter: 'blur(20px)', borderBottom: `1px solid ${BORDER}`, padding: '12px 20px', display: 'flex', alignItems: 'center', gap: 12, position: 'sticky', top: 0, zIndex: 50 }}>
        <button onClick={() => router.push('/admin/x7k2p')} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#4D9FFF', fontSize: 20 }}>←</button>
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 17, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>🎨 Banner Generator</div>
          <div style={{ fontSize: 10, color: SUB }}>Creative Studio — ProveRank</div>
        </div>
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8 }}>
          <button onClick={() => setDarkMode(d => !d)} style={{ background: 'rgba(77,159,255,0.1)', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '6px 12px', cursor: 'pointer', color: TEXT, fontSize: 12 }}>{darkMode ? '☀️ Light' : '🌙 Dark'}</button>
          <div style={{ display: 'flex', gap: 1, background: darkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)', borderRadius: 10, padding: 3 }}>
            {(['editor', 'library'] as const).map(t => (
              <button key={t} onClick={() => setTab(t)} style={{ padding: '6px 14px', borderRadius: 8, background: tab === t ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'transparent', border: 'none', color: tab === t ? '#fff' : SUB, fontWeight: tab === t ? 700 : 400, cursor: 'pointer', fontSize: 11 }}>
                {t === 'editor' ? '✏️ Editor' : `🗂️ Library (${banners.length})`}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── EDITOR TAB ── */}
      {tab === 'editor' && (
        <div style={{ display: 'flex', gap: 20, maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px' }}>

          {/* LEFT — Form */}
          <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 16 }}>

            {/* Batch Link */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 14 }}>🔗 Batch Link</div>
              <label style={labelStyle}>Link to Batch</label>
              <select value={form.batchId} onChange={e => {
                const b = batches.find(bt => bt._id === e.target.value)
                upd('batchId', e.target.value)
                if (b) { upd('batchName', b.name); upd('title', b.name); upd('examType', b.examType || 'NEET') }
              }} style={{ ...inpStyle, marginBottom: 10 }}>
                <option value="">— No batch linked —</option>
                {batches.map(b => <option key={b._id} value={b._id}>{b.name}</option>)}
              </select>
              {form.batchId && <div style={{ fontSize: 10, color: '#27AE60' }}>✅ Linked: {form.batchName}</div>}
            </div>

            {/* Content */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 14 }}>📝 Content</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
                <div>
                  <label style={labelStyle}>Exam Type</label>
                  <select value={form.examType} onChange={e => upd('examType', e.target.value)} style={inpStyle}>
                    {Object.keys(EXAM_SUBJECTS).map(k => <option key={k} value={k}>{k}</option>)}
                  </select>
                </div>
                <div>
                  <label style={labelStyle}>Badge / Ribbon</label>
                  <select value={form.badge} onChange={e => upd('badge', e.target.value)} style={inpStyle}>
                    {BADGES.map(b => <option key={b.id} value={b.id}>{b.label}</option>)}
                  </select>
                </div>
              </div>
              {[{ k: 'title', label: 'Banner Title *', ph: 'e.g. NEET 2026 Full Syllabus Batch' }, { k: 'tagline', label: 'Tagline / Subtitle', ph: 'e.g. India\'s Most Advanced Test Series' }, { k: 'price', label: 'Price (₹)', ph: '499' }, { k: 'totalTests', label: 'Total Tests', ph: '180' }, { k: 'duration', label: 'Duration', ph: '12 Months' }, { k: 'validity', label: 'Validity', ph: '365 Days' }, { k: 'ctaText', label: 'CTA Button Text', ph: 'Enroll Now' }].map(f => (
                <div key={f.k} style={{ marginBottom: 10 }}>
                  <label style={labelStyle}>{f.label}</label>
                  <input value={(form as any)[f.k]} onChange={e => upd(f.k as keyof Banner, e.target.value)} placeholder={f.ph} style={inpStyle} />
                </div>
              ))}
              <div style={{ marginBottom: 4 }}>
                <label style={labelStyle}>Key Highlights (3 bullet points)</label>
                {[0, 1, 2].map(i => (
                  <input key={i} value={form.highlights[i] || ''} onChange={e => updHighlight(i, e.target.value)} placeholder={`Highlight ${i + 1}`} style={{ ...inpStyle, marginBottom: 6 }} />
                ))}
              </div>
            </div>

            {/* Design */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#9B59B6', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 14 }}>🎨 Design</div>

              {/* Templates */}
              <label style={labelStyle}>Template</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(110px,1fr))', gap: 8, marginBottom: 14 }}>
                {TEMPLATES.map(t => (
                  <div key={t.id} onClick={() => upd('template', t.id)}
                    style={{ border: `2px solid ${form.template === t.id ? '#4D9FFF' : BORDER}`, borderRadius: 10, padding: 8, cursor: 'pointer', background: t.bg, transition: 'all 0.2s' }}>
                    <div style={{ fontSize: 9, fontWeight: 700, color: '#fff', textShadow: '0 1px 3px rgba(0,0,0,0.7)', marginBottom: 2 }}>{t.label}</div>
                    <div style={{ fontSize: 8, color: 'rgba(255,255,255,0.7)' }}>{t.desc}</div>
                  </div>
                ))}
              </div>

              {/* Color Presets */}
              <label style={labelStyle}>Color Preset</label>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14 }}>
                {PRESETS.map(pr => (
                  <button key={pr.name} onClick={() => setForm(f => ({ ...f, primaryColor: pr.p, secondaryColor: pr.s, textColor: pr.t, accentColor: pr.a }))}
                    style={{ padding: '5px 10px', borderRadius: 20, border: `1px solid ${BORDER}`, background: `linear-gradient(135deg,${pr.p},${pr.s})`, color: pr.t, fontSize: 10, cursor: 'pointer', fontWeight: 600 }}>{pr.name}</button>
                ))}
              </div>

              {/* Color Pickers */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 14 }}>
                {[{ k: 'primaryColor', label: 'Primary' }, { k: 'secondaryColor', label: 'Secondary' }, { k: 'textColor', label: 'Text' }, { k: 'accentColor', label: 'Accent' }].map(c => (
                  <div key={c.k}>
                    <label style={labelStyle}>{c.label}</label>
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                      <input type="color" value={(form as any)[c.k]} onChange={e => upd(c.k as keyof Banner, e.target.value)} style={{ width: 36, height: 32, borderRadius: 8, border: `1px solid ${BORDER}`, cursor: 'pointer', background: 'none', padding: 2 }} />
                      <input value={(form as any)[c.k]} onChange={e => upd(c.k as keyof Banner, e.target.value)} style={{ ...inpStyle, flex: 1 }} placeholder="#4D9FFF" />
                    </div>
                  </div>
                ))}
              </div>

              {/* Font */}
              <label style={labelStyle}>Typography</label>
              <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
                {FONTS.map(f => (
                  <button key={f.id} onClick={() => upd('fontStyle', f.id)}
                    style={{ flex: 1, padding: '8px 4px', borderRadius: 10, border: `1px solid ${form.fontStyle === f.id ? '#4D9FFF' : BORDER}`, background: form.fontStyle === f.id ? 'rgba(77,159,255,0.12)' : 'transparent', color: form.fontStyle === f.id ? '#4D9FFF' : SUB, cursor: 'pointer', fontSize: 10, fontFamily: f.family, fontWeight: f.weight }}>{f.label}</button>
                ))}
              </div>

              {/* BG Image + Illustration Library */}
              <label style={labelStyle}>Background Image URL</label>
              <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
                <input value={form.bgImage} onChange={e => upd('bgImage', e.target.value)} placeholder="https://... (paste image URL)" style={{ ...inpStyle, flex: 1 }} />
                {form.bgImage && <button onClick={() => upd('bgImage', '')} style={{ padding: '8px 10px', background: 'rgba(231,76,60,0.1)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 10, color: '#E74C3C', cursor: 'pointer', fontSize: 11 }}>✕</button>}
              </div>
              <button onClick={() => setShowIllustrations(true)}
                style={{ width: '100%', padding: '9px', background: 'rgba(155,89,182,0.1)', border: '1px solid rgba(155,89,182,0.25)', borderRadius: 10, color: '#9B59B6', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                🔬 Open Subject Illustration Library (DNA, Atoms, Cells, Equations...)
              </button>
            </div>

            {/* Schedule + Publish */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#27AE60', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 14 }}>📅 Schedule & Publish</div>
              <label style={labelStyle}>Scheduled Publish Date & Time (Auto-publish via cron)</label>
              <input type="datetime-local" value={form.scheduledAt || ''} onChange={e => upd('scheduledAt', e.target.value)} style={{ ...inpStyle, marginBottom: 10 }} />
              {form.scheduledAt && <div style={{ fontSize: 10, color: '#27AE60', marginBottom: 10 }}>⏰ Will auto-publish on: {new Date(form.scheduledAt).toLocaleString()}</div>}
              <div style={{ display: 'flex', gap: 8, alignItems: 'center', padding: '10px 14px', background: form.published ? 'rgba(39,174,96,0.08)' : 'rgba(231,76,60,0.06)', borderRadius: 12, border: `1px solid ${form.published ? 'rgba(39,174,96,0.2)' : 'rgba(231,76,60,0.15)'}` }}>
                <span style={{ fontSize: 16 }}>{form.published ? '🟢' : '⭕'}</span>
                <span style={{ fontSize: 12, color: form.published ? '#27AE60' : '#E74C3C', fontWeight: 700 }}>{form.published ? 'Published — Live' : 'Draft — Not Published'}</span>
              </div>
            </div>

            {/* Save Buttons */}
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={saveBanner} disabled={saving}
                style={{ flex: 1, padding: '13px', background: saving ? 'rgba(77,159,255,0.3)' : 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 14, color: '#fff', fontWeight: 700, cursor: saving ? 'not-allowed' : 'pointer', fontSize: 13, boxShadow: '0 6px 20px rgba(77,159,255,0.3)' }}>
                {saving ? 'Saving...' : editId ? '💾 Update Banner' : '✨ Create Banner'}
              </button>
              {editId && <button onClick={() => { setForm(EMPTY); setEditId(null) }}
                style={{ padding: '13px 16px', background: 'rgba(231,76,60,0.1)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 14, color: '#E74C3C', cursor: 'pointer', fontSize: 12, fontWeight: 600 }}>New</button>}
            </div>

            {/* Analytics */}
            {editId && (() => {
              const cur = banners.find(b => b._id === editId)
              if (!cur?.analytics) return null
              return (
                <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
                  <div style={{ fontWeight: 700, fontSize: 13, color: '#E67E22', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 14 }}>📊 Analytics</div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 10 }}>
                    {[{ label: 'Views', v: cur.analytics!.views, c: '#4D9FFF', i: '👁️' }, { label: 'Clicks', v: cur.analytics!.clicks, c: '#9B59B6', i: '👆' }, { label: 'Enrolls', v: cur.analytics!.enrolls, c: '#27AE60', i: '✅' }].map(s => (
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

          {/* RIGHT — Preview */}
          <div style={{ width: 360, flexShrink: 0, position: 'sticky', top: 80, height: 'fit-content', display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF' }}>👁️ Live Preview</div>
                <div style={{ display: 'flex', gap: 4 }}>
                  {(['card', 'wide', 'square', 'mobile'] as const).map(s => (
                    <button key={s} onClick={() => setPreviewSize(s)}
                      style={{ padding: '4px 8px', borderRadius: 8, border: `1px solid ${previewSize === s ? '#4D9FFF' : BORDER}`, background: previewSize === s ? 'rgba(77,159,255,0.15)' : 'transparent', color: previewSize === s ? '#4D9FFF' : SUB, cursor: 'pointer', fontSize: 9, fontWeight: previewSize === s ? 700 : 400 }}>
                      {s === 'card' ? '🃏' : s === 'wide' ? '📰' : s === 'square' ? '⬜' : '📱'} {s}
                    </button>
                  ))}
                </div>
              </div>
              <BannerPreview b={form} size={previewSize} previewRef={previewRef} />

              {/* Action Buttons */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 14 }}>
                <button onClick={downloadBannerImage} disabled={downloading}
                  style={{ padding: '10px', background: 'rgba(39,174,96,0.1)', border: '1px solid rgba(39,174,96,0.25)', borderRadius: 12, color: '#27AE60', cursor: downloading ? 'wait' : 'pointer', fontSize: 11, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
                  {downloading ? '⏳ Saving...' : '⬇️ Download PNG'}
                </button>
                <button onClick={shareBanner} disabled={sharing}
                  style={{ padding: '10px', background: 'rgba(39,174,96,0.1)', border: '1px solid rgba(39,174,96,0.25)', borderRadius: 12, color: '#27AE60', cursor: sharing ? 'wait' : 'pointer', fontSize: 11, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
                  {sharing ? '⏳...' : '📤 Share / WhatsApp'}
                </button>
              </div>

              {/* Generate All Variants button */}
              <button onClick={generateAllVariants}
                style={{ width:'100%', marginTop:10, padding:'11px', background:'linear-gradient(135deg,#9B59B6,#7D3C98)', border:'none', borderRadius:12, color:'#fff', fontWeight:700, cursor:'pointer', fontSize:12, boxShadow:'0 6px 20px rgba(155,89,182,0.35)', display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}>
                🖼️ Generate All Size Variants (Card + Wide + Square + Mobile)
              </button>
            </div>

            {/* ALL VARIANTS SECTION */}
            {showAllVariants && (
              <div style={{ background:CARD, border:`1px solid ${BORDER}`, borderRadius:16, padding:18, backdropFilter:'blur(16px)' }}>
                <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:16 }}>
                  <div style={{ fontWeight:700, fontSize:13, color:'#9B59B6', textTransform:'uppercase', letterSpacing:0.8 }}>🖼️ All Size Variants</div>
                  <button onClick={()=>setShowAllVariants(false)} style={{ background:'transparent', border:`1px solid ${BORDER}`, borderRadius:8, padding:'4px 10px', cursor:'pointer', color:SUB, fontSize:11 }}>Hide</button>
                </div>
                <div style={{ display:'flex', flexDirection:'column', gap:20 }}>

                  {/* Card Variant */}
                  <div>
                    <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10 }}>
                      <div>
                        <div style={{ fontSize:12, fontWeight:700, color:TEXT }}>🃏 Card Preview</div>
                        <div style={{ fontSize:10, color:SUB }}>Used on Test Series page — standard batch card</div>
                      </div>
                      <button onClick={()=>downloadVariant(cardRef,'card')} disabled={downloadingVariant==='card'}
                        style={{ padding:'7px 14px', background:'rgba(39,174,96,0.12)', border:'1px solid rgba(39,174,96,0.25)', borderRadius:10, color:'#27AE60', cursor:'pointer', fontSize:11, fontWeight:700 }}>
                        {downloadingVariant==='card'?'⏳...':'⬇️ Download'}
                      </button>
                    </div>
                    <div ref={cardRef}><BannerPreview b={form} size='card' /></div>
                  </div>

                  <div style={{ height:1, background:BORDER }} />

                  {/* Wide Variant */}
                  <div>
                    <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10 }}>
                      <div>
                        <div style={{ fontSize:12, fontWeight:700, color:TEXT }}>📰 Wide / Hero Preview</div>
                        <div style={{ fontSize:10, color:SUB }}>Used in Spotlight section — full-width banner</div>
                      </div>
                      <button onClick={()=>downloadVariant(wideRef,'wide')} disabled={downloadingVariant==='wide'}
                        style={{ padding:'7px 14px', background:'rgba(39,174,96,0.12)', border:'1px solid rgba(39,174,96,0.25)', borderRadius:10, color:'#27AE60', cursor:'pointer', fontSize:11, fontWeight:700 }}>
                        {downloadingVariant==='wide'?'⏳...':'⬇️ Download'}
                      </button>
                    </div>
                    <div ref={wideRef}><BannerPreview b={form} size='wide' /></div>
                  </div>

                  <div style={{ height:1, background:BORDER }} />

                  {/* Square Variant */}
                  <div>
                    <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10 }}>
                      <div>
                        <div style={{ fontSize:12, fontWeight:700, color:TEXT }}>⬜ Square Preview</div>
                        <div style={{ fontSize:10, color:SUB }}>WhatsApp / Social Media — 1:1 ratio</div>
                      </div>
                      <button onClick={()=>downloadVariant(squareRef,'square')} disabled={downloadingVariant==='square'}
                        style={{ padding:'7px 14px', background:'rgba(39,174,96,0.12)', border:'1px solid rgba(39,174,96,0.25)', borderRadius:10, color:'#27AE60', cursor:'pointer', fontSize:11, fontWeight:700 }}>
                        {downloadingVariant==='square'?'⏳...':'⬇️ Download'}
                      </button>
                    </div>
                    <div ref={squareRef} style={{ display:'flex', justifyContent:'center' }}><BannerPreview b={form} size='square' /></div>
                  </div>

                  <div style={{ height:1, background:BORDER }} />

                  {/* Mobile Variant */}
                  <div>
                    <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10 }}>
                      <div>
                        <div style={{ fontSize:12, fontWeight:700, color:TEXT }}>📱 Mobile Preview</div>
                        <div style={{ fontSize:10, color:SUB }}>Mobile-optimized — 320×180px compact view</div>
                      </div>
                      <button onClick={()=>downloadVariant(mobileRef,'mobile')} disabled={downloadingVariant==='mobile'}
                        style={{ padding:'7px 14px', background:'rgba(39,174,96,0.12)', border:'1px solid rgba(39,174,96,0.25)', borderRadius:10, color:'#27AE60', cursor:'pointer', fontSize:11, fontWeight:700 }}>
                        {downloadingVariant==='mobile'?'⏳...':'⬇️ Download'}
                      </button>
                    </div>
                    <div ref={mobileRef} style={{ display:'flex', justifyContent:'center' }}>
                      <div style={{ width:320, border:'8px solid rgba(255,255,255,0.1)', borderRadius:20, overflow:'hidden', boxShadow:'0 8px 30px rgba(0,0,0,0.4)' }}>
                        <BannerPreview b={form} size='mobile' />
                      </div>
                    </div>
                    <div style={{ textAlign:'center', marginTop:8, fontSize:10, color:SUB }}>📱 Mobile frame simulation — 320×180</div>
                  </div>

                </div>
              </div>
            )}

            {/* Quick Info */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 16, backdropFilter: 'blur(16px)', fontSize: 11, color: SUB, lineHeight: 1.8 }}>
              <div style={{ fontWeight: 700, color: TEXT, marginBottom: 8 }}>💡 Tips</div>
              <div>🔗 Link a batch to auto-fill title & exam type</div>
              <div>🔬 Use Illustration Library for science SVGs as BG</div>
              <div>⬇️ Download PNG saves the preview as an image file</div>
              <div>📤 Share opens WhatsApp or native share sheet</div>
              <div>⏰ Scheduled banners auto-publish via server cron</div>
              <div>🕐 Version history lets you restore any previous save</div>
            </div>
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
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8, flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 11, background: b.published ? 'rgba(39,174,96,0.15)' : 'rgba(231,76,60,0.1)', color: b.published ? '#27AE60' : '#E74C3C', padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>{b.published ? '🟢 Live' : '⭕ Draft'}</span>
                      {b.scheduledAt && !b.published && new Date(b.scheduledAt) > new Date() && (
                        <span style={{ fontSize: 10, background: 'rgba(230,126,34,0.12)', color: '#E67E22', padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>⏰ Scheduled: {new Date(b.scheduledAt).toLocaleDateString()}</span>
                      )}
                      <span style={{ fontSize: 10, color: SUB, marginLeft: 'auto' }}>{new Date(b.createdAt || '').toLocaleDateString()}</span>
                    </div>
                    {b.analytics && (
                      <div style={{ display: 'flex', gap: 10, marginBottom: 10, fontSize: 10, color: SUB }}>
                        <span>👁️ {b.analytics.views}</span>
                        <span>👆 {b.analytics.clicks}</span>
                        <span>✅ {b.analytics.enrolls}</span>
                      </div>
                    )}
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                      <button onClick={() => loadBanner(b)} style={{ flex: 1, padding: '7px', background: 'rgba(77,159,255,0.12)', border: '1px solid rgba(77,159,255,0.25)', borderRadius: 10, color: '#4D9FFF', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>✏️ Edit</button>
                      <button onClick={() => togglePublish(b._id!)} style={{ flex: 1, padding: '7px', background: b.published ? 'rgba(231,76,60,0.1)' : 'rgba(39,174,96,0.12)', border: `1px solid ${b.published ? 'rgba(231,76,60,0.3)' : 'rgba(39,174,96,0.3)'}`, borderRadius: 10, color: b.published ? '#E74C3C' : '#27AE60', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>{b.published ? '⭕ Unpublish' : '🟢 Publish'}</button>
                      <button onClick={() => duplicate(b._id!)} style={{ padding: '7px 10px', background: 'rgba(155,89,182,0.1)', border: '1px solid rgba(155,89,182,0.25)', borderRadius: 10, color: '#9B59B6', cursor: 'pointer', fontSize: 11 }}>📋</button>
                      <button onClick={() => copyShareLink(b)} style={{ padding: '7px 10px', background: 'rgba(39,174,96,0.08)', border: '1px solid rgba(39,174,96,0.2)', borderRadius: 10, color: '#27AE60', cursor: 'pointer', fontSize: 11 }}>🔗</button>
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
