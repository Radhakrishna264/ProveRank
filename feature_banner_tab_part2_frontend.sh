#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# BANNER MANAGEMENT — PART 2: Frontend Tab (run AFTER part 1 backend
# script). Adds "🖼️ Banner" tab right after "🎟️ Coupons" on both the
# Batch Detail and Test Series Detail admin pages.
#
# Includes: Overview strip, Current Banner panel (live preview +
# edit/replace/remove/duplicate/restore), Banner Builder (content +
# design fields + live validation warnings), Preview & Variants
# (Card/Wide/Square/Mobile + PNG export via html2canvas + safe-zone
# guide toggle), Templates & Assets (31 templates across 8 categories
# with search/filter, 18 badges, 6 color presets, 3 fonts, 8 SVG
# illustrations ported from the old Creative Studio page), Version
# History (restore), Analytics, Audit Trail, Integration Summary.
# Publish/Launch is intentionally NOT here (future Publish Center).
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_banner_tab_frontend.js << 'NODEEOF'
const fs = require('fs');

function replaceExact(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error(`❌ [${path}] anchor not found: ${label}`);
      process.exit(1);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src);
  console.log(`✅ ${path} updated`);
}

const bannerTabCode = `// ══════════════════════════════════════════════════════════════════
// BANNER MANAGEMENT TAB — shared asset/template/illustration data +
// live preview engine, ported & upgraded from the old Creative Studio
// script, now scoped to a single batch/series banner.
// ══════════════════════════════════════════════════════════════════
const BN_TEMPLATES = [
  { id: 'classic', label: 'Classic Premium', category: 'Featured', bg: 'linear-gradient(135deg,#0a0a1a,#1a1a3e)', accent: '#FFD700' },
  { id: 'glass', label: 'Glassmorphism', category: 'Premium', bg: 'linear-gradient(135deg,rgba(77,159,255,0.25),rgba(155,89,182,0.25))', accent: '#4D9FFF' },
  { id: 'minimal', label: 'Minimal Clean', category: 'Featured', bg: 'linear-gradient(135deg,#f8f9fa,#e9ecef)', accent: '#1a237e' },
  { id: 'moderngrad', label: 'Modern Gradient', category: 'Premium', bg: 'linear-gradient(135deg,#4568DC,#B06AB3)', accent: '#FFD700' },
  { id: 'premiumdark', label: 'Premium Dark', category: 'Premium', bg: 'linear-gradient(135deg,#0f0c29,#302b63)', accent: '#00D4FF' },
  { id: 'lightpro', label: 'Light Professional', category: 'Professional', bg: 'linear-gradient(135deg,#e0eafc,#cfdef3)', accent: '#1a237e' },
  { id: 'aurora', label: 'Aurora', category: 'Premium', bg: 'linear-gradient(135deg,#1a0533,#003333)', accent: '#00FFD1' },
  { id: 'cosmic', label: 'Cosmic Dark', category: 'Premium', bg: 'linear-gradient(135deg,#020816,#0d1b2a)', accent: '#4D9FFF' },
  { id: 'gold', label: 'Gold Elite', category: 'Premium', bg: 'linear-gradient(135deg,#1a1200,#3d2e00)', accent: '#FFD700' },
  { id: 'platinum', label: 'Platinum Elite', category: 'Premium', bg: 'linear-gradient(135deg,#232526,#414345)', accent: '#E5E4E2' },
  { id: 'luxuryblack', label: 'Luxury Black', category: 'Premium', bg: 'linear-gradient(135deg,#000000,#1a1a1a)', accent: '#FFD700' },
  { id: 'royalblue', label: 'Royal Blue', category: 'Premium', bg: 'linear-gradient(135deg,#1e3c72,#2a5298)', accent: '#FFD700' },
  { id: 'emerald', label: 'Emerald Premium', category: 'Premium', bg: 'linear-gradient(135deg,#0f3d3e,#1b5e20)', accent: '#00E676' },
  { id: 'crimson', label: 'Crimson Pro', category: 'Professional', bg: 'linear-gradient(135deg,#870000,#190A05)', accent: '#FFD700' },
  { id: 'neontech', label: 'Neon Tech', category: 'Premium', bg: 'linear-gradient(135deg,#0f0c29,#24243e)', accent: '#00FFF0' },
  { id: 'cyber', label: 'Cyber Future', category: 'Premium', bg: 'linear-gradient(135deg,#12121e,#1e1e3a)', accent: '#FF00E5' },
  { id: 'academic', label: 'Academic Professional', category: 'Academic', bg: 'linear-gradient(135deg,#1a2980,#26d0ce)', accent: '#FFD700' },
  { id: 'university', label: 'University Style', category: 'Academic', bg: 'linear-gradient(135deg,#232526,#0f2027)', accent: '#4D9FFF' },
  { id: 'coaching', label: 'Coaching Institute', category: 'Academic', bg: 'linear-gradient(135deg,#134E5E,#71B280)', accent: '#FFD700' },
  { id: 'studyplan', label: 'Study Planner', category: 'Academic', bg: 'linear-gradient(135deg,#3a1c71,#d76d77)', accent: '#FFD700' },
  { id: 'warrior', label: 'Exam Warrior', category: 'Motivation', bg: 'linear-gradient(135deg,#bf360c,#e65100)', accent: '#FFD700' },
  { id: 'topper', label: 'Topper Edition', category: 'Motivation', bg: 'linear-gradient(135deg,#f7971e,#ffd200)', accent: '#1a1a2e' },
  { id: 'rankbooster', label: 'Rank Booster', category: 'Motivation', bg: 'linear-gradient(135deg,#DA22FF,#9733EE)', accent: '#FFD700' },
  { id: 'launch', label: 'New Batch Launch', category: 'Offer', bg: 'linear-gradient(135deg,#11998e,#38ef7d)', accent: '#1a1a2e' },
  { id: 'earlybird', label: 'Early Bird Offer', category: 'Offer', bg: 'linear-gradient(135deg,#f857a6,#ff5858)', accent: '#FFD700' },
  { id: 'megasale', label: 'Mega Sale', category: 'Offer', bg: 'linear-gradient(135deg,#eb3349,#f45c43)', accent: '#FFD700' },
  { id: 'limitedseats', label: 'Limited Seats', category: 'Offer', bg: 'linear-gradient(135deg,#7f0000,#3d0000)', accent: '#FFD700' },
  { id: 'diwali', label: 'Diwali Special', category: 'Seasonal', bg: 'linear-gradient(135deg,#8E2DE2,#FF6B00)', accent: '#FFD700' },
  { id: 'newyear', label: 'New Year Special', category: 'Seasonal', bg: 'linear-gradient(135deg,#000046,#1CB5E0)', accent: '#FFD700' },
  { id: 'neetv', label: 'Medical (NEET)', category: 'Exam-Specific', bg: 'linear-gradient(135deg,#004d40,#006064)', accent: '#00E5FF' },
  { id: 'jeev', label: 'Engineering (JEE)', category: 'Exam-Specific', bg: 'linear-gradient(135deg,#1a237e,#283593)', accent: '#FFD700' },
]
const BN_CATEGORIES = ['All', 'Featured', 'Premium', 'Professional', 'Academic', 'Motivation', 'Offer', 'Seasonal', 'Exam-Specific']
const BN_PRESETS = [
  { label: 'Ocean', primaryColor: '#0077B6', secondaryColor: '#00B4D8', textColor: '#FFFFFF', accentColor: '#90E0EF' },
  { label: 'Forest', primaryColor: '#1B4332', secondaryColor: '#2D6A4F', textColor: '#FFFFFF', accentColor: '#95D5B2' },
  { label: 'Sunset', primaryColor: '#FF6B35', secondaryColor: '#F7931E', textColor: '#FFFFFF', accentColor: '#FFD700' },
  { label: 'Royal', primaryColor: '#3A0CA3', secondaryColor: '#7209B7', textColor: '#FFFFFF', accentColor: '#F72585' },
  { label: 'Gold', primaryColor: '#1a1200', secondaryColor: '#3d2e00', textColor: '#FFFFFF', accentColor: '#FFD700' },
  { label: 'Neon', primaryColor: '#0f0c29', secondaryColor: '#24243e', textColor: '#FFFFFF', accentColor: '#00FFF0' },
]
const BN_FONTS = [
  { id: 'modern', label: 'Bold Modern', family: "'Inter',sans-serif" },
  { id: 'serif', label: 'Elegant Serif', family: "'Playfair Display',serif" },
  { id: 'clean', label: 'Clean Sans', family: "'Poppins',sans-serif" },
]
const BN_BADGES = [
  { id: 'none', label: 'None' }, { id: 'new', label: '✨ New' }, { id: 'trending', label: '📈 Trending' },
  { id: 'popular', label: '⭐ Popular' }, { id: 'bestseller', label: '🏆 Best Seller' }, { id: 'premium', label: '💎 Premium' },
  { id: 'limitedseats', label: '🔥 Limited Seats' }, { id: 'scholarship', label: '🎓 Scholarship' }, { id: 'earlybird', label: '🐦 Early Bird' },
  { id: 'flashsale', label: '⚡ Flash Sale' }, { id: 'live', label: '🔴 Live' }, { id: 'upcoming', label: '🕐 Upcoming' },
  { id: 'regopen', label: '📝 Registration Open' }, { id: 'closingsoon', label: '⏳ Closing Soon' }, { id: 'freedemo', label: '🆓 Free Demo' },
  { id: 'recommended', label: '👍 Recommended' }, { id: 'topRated', label: '🌟 Top Rated' }, { id: 'verified', label: '✅ Verified' },
]
const BN_EXAM_ICON: any = { NEET: '🧬', 'NEET UG': '🧬', 'NEET PG': '🩺', JEE: '⚛️', 'JEE Main': '⚛️', 'JEE Advanced': '⚛️', CUET: '📘', 'CUET UG': '📘', 'CUET PG': '📗', SSC: '📋', 'SSC CGL': '📋', 'SSC CHSL': '📋', UPSC: '🏛️', 'UPSC CSE': '🏛️', NDA: '🎖️', CDS: '🎖️', CAT: '📊', CLAT: '⚖️', GATE: '🔧', 'IIT JAM': '🔬', 'CSIR NET': '🔬', 'UGC NET': '📖', 'Railway (RRB)': '🚆', 'Banking (IBPS / SBI)': '🏦', 'State PSC': '🏛️' }
const BN_ILLUSTRATIONS = [
  { id: 'dna', label: 'DNA Helix', category: 'Biology', svg: '<svg viewBox="0 0 100 100"><path d="M30 10 Q50 30 30 50 Q10 70 30 90" stroke="#00E5FF" stroke-width="3" fill="none"/><path d="M70 10 Q50 30 70 50 Q90 70 70 90" stroke="#FF00E5" stroke-width="3" fill="none"/></svg>' },
  { id: 'atom', label: 'Atom', category: 'Physics', svg: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="6" fill="#FFD700"/><ellipse cx="50" cy="50" rx="40" ry="15" stroke="#4D9FFF" stroke-width="2" fill="none"/><ellipse cx="50" cy="50" rx="40" ry="15" stroke="#4D9FFF" stroke-width="2" fill="none" transform="rotate(60 50 50)"/><ellipse cx="50" cy="50" rx="40" ry="15" stroke="#4D9FFF" stroke-width="2" fill="none" transform="rotate(120 50 50)"/></svg>' },
  { id: 'cell', label: 'Cell Nucleus', category: 'Biology', svg: '<svg viewBox="0 0 100 100"><ellipse cx="50" cy="50" rx="45" ry="35" stroke="#00E676" stroke-width="2" fill="none"/><circle cx="50" cy="50" r="15" fill="#00E676" opacity="0.3"/></svg>' },
  { id: 'periodic', label: 'Periodic Table', category: 'Chemistry', svg: '<svg viewBox="0 0 100 100"><rect x="20" y="20" width="25" height="25" stroke="#FF6B35" stroke-width="2" fill="none"/><text x="32" y="37" font-size="12" fill="#FF6B35" text-anchor="middle">Na</text></svg>' },
  { id: 'wave', label: 'Wave / Light', category: 'Physics', svg: '<svg viewBox="0 0 100 40"><path d="M0 20 Q10 0 20 20 T40 20 T60 20 T80 20 T100 20" stroke="#4D9FFF" stroke-width="2" fill="none"/></svg>' },
  { id: 'equation', label: 'E=mc²', category: 'Physics', svg: '<svg viewBox="0 0 100 40"><text x="50" y="25" font-size="20" fill="#FFD700" text-anchor="middle">E=mc²</text></svg>' },
  { id: 'mitosis', label: 'Mitosis', category: 'Biology', svg: '<svg viewBox="0 0 100 60"><ellipse cx="30" cy="30" rx="20" ry="15" stroke="#00E676" stroke-width="2" fill="none"/><ellipse cx="70" cy="30" rx="20" ry="15" stroke="#00E676" stroke-width="2" fill="none"/></svg>' },
  { id: 'circuit', label: 'Circuit', category: 'Physics', svg: '<svg viewBox="0 0 100 60"><path d="M10 30 H30 V10 H70 V30 H90" stroke="#00D4FF" stroke-width="2" fill="none"/><circle cx="50" cy="30" r="4" fill="#00D4FF"/></svg>' },
]

function BN_effPrice(b: any) { return b.discountPrice || b.price || 0 }
function BN_statusChip(s: string) {
  const map: any = { draft: [WARN, 'rgba(251,191,36,0.12)'], ready: [GOOD, 'rgba(52,211,153,0.12)'], synced: [ACC, 'rgba(77,159,255,0.12)'], pending_sync: [WARN, 'rgba(251,191,36,0.12)'], conflict: [BAD, 'rgba(248,113,113,0.12)'], manual_override: ['#A78BFA', 'rgba(167,139,250,0.12)'], removed: [BAD, 'rgba(248,113,113,0.12)'], replaced: [DIM, 'rgba(107,143,175,0.12)'], published: [GOOD, 'rgba(52,211,153,0.12)'] }
  const [c, bg] = map[s] || map.draft
  return <span style={{ ...chip(c, bg), marginLeft: 6 }}>{(s || '').replace('_', ' ').toUpperCase()}</span>
}

function BannerLivePreview({ b, size, showSafeZone }: any) {
  const dims: any = { card: { w: 320, h: 200 }, wide: { w: 480, h: 200 }, square: { w: 320, h: 320 }, mobile: { w: 280, h: 420 } }
  const d = dims[size] || dims.card
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  const bg = b.bgImage ? \`url(\${b.bgImage}) center/cover\` : (tpl.bg)
  const badgeObj = BN_BADGES.find(x => x.id === b.badge)
  return (
    <div style={{ width: d.w, height: d.h, maxWidth: '100%', borderRadius: 14, position: 'relative', overflow: 'hidden', background: bg, color: b.textColor || '#fff', fontFamily: (BN_FONTS.find(f => f.id === b.fontStyle) || BN_FONTS[0]).family, border: \`1px solid \${BOR}\`, padding: 16, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', margin: '0 auto' }}>
      {showSafeZone && <div style={{ position: 'absolute', inset: '8%', border: '1px dashed rgba(255,255,255,0.4)', borderRadius: 8, pointerEvents: 'none' }} />}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <span style={{ fontSize: 20 }}>{BN_EXAM_ICON[b.examType] || '📚'}</span>
        {badgeObj && badgeObj.id !== 'none' && <span style={{ fontSize: 9, fontWeight: 700, padding: '3px 8px', borderRadius: 20, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{badgeObj.label}</span>}
      </div>
      <div>
        <div style={{ fontSize: size === 'square' ? 18 : 16, fontWeight: 800, lineHeight: 1.2 }}>{b.title || 'Batch Title'}</div>
        {b.tagline && <div style={{ fontSize: 10.5, opacity: 0.85, marginTop: 3 }}>{b.tagline}</div>}
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 6 }}>
          {(b.highlights || []).filter(Boolean).slice(0, 3).map((h: string, i: number) => (
            <span key={i} style={{ fontSize: 8.5, padding: '2px 6px', borderRadius: 6, background: 'rgba(255,255,255,0.15)' }}>{h}</span>
          ))}
        </div>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 14, fontWeight: 800, color: b.accentColor || tpl.accent }}>{b.price && Number(b.price) > 0 ? '₹' + b.price : 'FREE'}</span>
        <span style={{ fontSize: 9.5, fontWeight: 700, padding: '5px 10px', borderRadius: 20, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{b.ctaText || 'Enroll Now'} →</span>
      </div>
    </div>
  )
}

function BN_IllustrationModal({ onSelect, onClose }: any) {
  const [cat, setCat] = useState('All')
  const cats = ['All', ...Array.from(new Set(BN_ILLUSTRATIONS.map(i => i.category)))]
  const list = cat === 'All' ? BN_ILLUSTRATIONS : BN_ILLUSTRATIONS.filter(i => i.category === cat)
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={onClose}>
      <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 480, width: '100%', maxHeight: '80vh', overflowY: 'auto', border: \`1px solid \${BOR2}\` }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontWeight: 700, color: TS }}>🎨 Subject Illustration Library</div>
          <button style={bs} onClick={onClose}>✕</button>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 12 }}>
          {cats.map(c => <button key={c} style={cat === c ? bp : bs} onClick={() => setCat(c)}>{c}</button>)}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(90px,1fr))', gap: 10 }}>
          {list.map(ill => (
            <div key={ill.id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer' }} onClick={() => { onSelect('data:image/svg+xml;utf8,' + encodeURIComponent(ill.svg)); onClose() }}>
              <div style={{ width: 60, height: 60, margin: '0 auto 6px' }} dangerouslySetInnerHTML={{ __html: ill.svg }} />
              <div style={{ fontSize: 10, color: DIM }}>{ill.label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function BannerManagementTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const [form, setForm] = useState<any>(null)
  const [previewSize, setPreviewSize] = useState('card')
  const [showSafeZone, setShowSafeZone] = useState(false)
  const [showIllustrations, setShowIllustrations] = useState(false)
  const [showVersions, setShowVersions] = useState(false)
  const [showAllVariants, setShowAllVariants] = useState(false)
  const [analytics, setAnalytics] = useState<any>(null)
  const [audit, setAudit] = useState<any>(null)
  const [templateCat, setTemplateCat] = useState('All')
  const [templateSearch, setTemplateSearch] = useState('')
  const [downloading, setDownloading] = useState(false)
  const previewRef = useRef<any>(null)
  const cardRef = useRef<any>(null); const wideRef = useRef<any>(null); const squareRef = useRef<any>(null); const mobileRef = useRef<any>(null)

  const load = useCallback(() => fetch(base + '/' + id + '/banner', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  useEffect(() => { if (data?.banner) setForm(data.banner) }, [data])
  useEffect(() => { fetch(base + '/' + id + '/banner/analytics', { headers: authHeaders }).then(r => r.json()).then(d => setAnalytics(d.analytics)).catch(() => {}) }, [data?.banner?._id])
  useEffect(() => { fetch(base + '/' + id + '/banner/audit', { headers: authHeaders }).then(r => r.json()).then(d => setAudit(d.audit)).catch(() => {}) }, [data?.banner?._id])

  if (!data) return <EmptyMsg text="⟳ Loading banner…" />

  const autoGenerate = async () => {
    const r = await fetch(base + '/' + id + '/banner/auto-generate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Banner draft created'); load() } else showToast('⚠️ ' + d.error)
  }
  const saveBanner = async (opts: any = {}) => {
    if (!form.title || !form.title.trim()) return showToast('⚠️ Title is required')
    const r = await fetch(base + '/' + id + '/banner', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ ...form, ...opts }) })
    const d = await r.json()
    if (d.success) { showToast('✅ Banner saved'); load() } else showToast('⚠️ ' + d.error)
  }
  const syncNow = async () => { const r = await fetch(base + '/' + id + '/banner/sync', { method: 'POST', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Synced from product details'); load() } else showToast('⚠️ ' + d.error) }
  const duplicate = async () => { const r = await fetch(base + '/' + id + '/banner/duplicate', { method: 'POST', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Duplicated (unlinked draft)'); load() } else showToast('⚠️ ' + d.error) }
  const removeBanner = async () => { if (!window.confirm('Remove this banner? It can be restored later.')) return; const r = await fetch(base + '/' + id + '/banner/remove', { method: 'POST', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Banner removed'); load() } else showToast('⚠️ ' + d.error) }
  const restoreRemoved = async () => { const r = await fetch(base + '/' + id + '/banner/restore-removed', { method: 'POST', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Banner restored'); load() } else showToast('⚠️ ' + d.error) }
  const replaceBanner = async () => { if (!window.confirm('Create a replacement draft? The current banner will be marked as replaced.')) return; const r = await fetch(base + '/' + id + '/banner/replace', { method: 'POST', headers: authHeaders, body: JSON.stringify({}) }); const d = await r.json(); if (d.success) { showToast('✅ Replacement draft created'); load() } else showToast('⚠️ ' + d.error) }
  const restoreVersion = async (idx: number) => { const r = await fetch(base + '/' + id + '/banner/restore-version/' + idx, { method: 'POST', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Version restored'); load() } else showToast('⚠️ ' + d.error) }
  const discard = () => { if (data?.banner) setForm(data.banner); showToast('↩️ Changes discarded') }

  const downloadPNG = async (ref: any, label: string) => {
    if (!ref?.current) return
    setDownloading(true)
    try {
      const html2canvas = (await import('html2canvas')).default
      const canvas = await html2canvas(ref.current, { backgroundColor: null, scale: 2 })
      const link = document.createElement('a')
      link.download = (form?.title || 'banner') + '-' + label + '.png'
      link.href = canvas.toDataURL('image/png')
      link.click()
    } catch (e) { showToast('⚠️ Export failed') }
    setDownloading(false)
  }

  const warnings: string[] = []
  if (form) {
    if (!form.title || !form.title.trim()) warnings.push('Missing title')
    if (!form.ctaText || !form.ctaText.trim()) warnings.push('Missing CTA text')
    if (form.bgImage && !/^https?:\\/\\/|^data:image/.test(form.bgImage)) warnings.push('Invalid image URL')
    if (data.syncPreview && form.price !== data.syncPreview.price) warnings.push('Price differs from current batch price — consider syncing')
  }

  const filteredTemplates = BN_TEMPLATES.filter(t => (templateCat === 'All' || t.category === templateCat) && t.label.toLowerCase().includes(templateSearch.toLowerCase()))

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 10, marginBottom: 14 }}>
        <div style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 14, fontWeight: 800, color: TS }}>{data.overview?.status ? data.overview.status.toUpperCase() : 'NONE'}</div><div style={{ fontSize: 9.5, color: DIM }}>STATUS</div></div>
        <div style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 18, fontWeight: 800, color: (data.overview?.qualityScore || 0) >= 60 ? GOOD : WARN }}>{data.overview?.qualityScore || 0}</div><div style={{ fontSize: 9.5, color: DIM }}>QUALITY SCORE</div></div>
        <div style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 12, fontWeight: 700, color: ACC }}>{(data.overview?.syncState || '—').replace('_', ' ')}</div><div style={{ fontSize: 9.5, color: DIM }}>SYNC STATE</div></div>
        <div style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 11, color: TS }}>{data.overview?.lastUpdated ? new Date(data.overview.lastUpdated).toLocaleDateString() : '—'}</div><div style={{ fontSize: 9.5, color: DIM }}>LAST UPDATED</div></div>
        <div style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 12, fontWeight: 700, color: data.overview?.readiness === 'ready' ? GOOD : WARN }}>{data.overview?.readiness === 'ready' ? '✅ Ready' : '⏳ Incomplete'}</div><div style={{ fontSize: 9.5, color: DIM }}>READINESS</div></div>
      </div>

      {!data.banner ? (
        <div style={cs}>
          <div style={{ fontWeight: 700, color: TS, marginBottom: 8 }}>No banner yet for this batch</div>
          <div style={{ fontSize: 11.5, color: DIM, marginBottom: 10 }}>Auto-generate a draft — it will pre-fill from current batch details:</div>
          <div style={{ fontSize: 11.5, color: DIM, lineHeight: 1.8, marginBottom: 12 }}>
            Title: <b style={{ color: TS }}>{data.syncPreview?.title}</b> · Price: <b style={{ color: TS }}>₹{data.syncPreview?.price}</b> · Tests: <b style={{ color: TS }}>{data.syncPreview?.totalTests}</b> · Validity: <b style={{ color: TS }}>{data.syncPreview?.validity}</b>
          </div>
          <button style={bp} onClick={autoGenerate}>✨ Auto-Generate Draft</button>
        </div>
      ) : form && (
        <>
          <div style={cs}>
            <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', alignItems: 'flex-start' }}>
              <BannerLivePreview b={form} size="card" showSafeZone={false} />
              <div style={{ flex: 1, minWidth: 160 }}>
                <div style={{ fontWeight: 700, color: TS, fontSize: 14 }}>{form.title}{BN_statusChip(form.status)}</div>
                <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>Linked to: {data.batchName}</div>
                <div style={{ fontSize: 11, color: DIM, marginTop: 2 }}>Sync: {form.syncState?.replace('_', ' ')}</div>
                <div style={{ fontSize: 10, color: DIM, marginTop: 2 }}>Updated {new Date(form.updatedAt).toLocaleString()}</div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 12 }}>
              {form.status === 'removed'
                ? <button style={bp} onClick={restoreRemoved}>♻️ Restore Banner</button>
                : <>
                  <button style={bs} onClick={replaceBanner}>🔁 Replace</button>
                  <button style={bs} onClick={duplicate}>⧉ Duplicate</button>
                  <button style={bd} onClick={removeBanner}>🗑️ Remove</button>
                  <button style={bs} onClick={() => setShowVersions(v => !v)}>{showVersions ? 'Hide Versions' : '🕐 Version History'}</button>
                </>}
            </div>
          </div>

          {showVersions && (
            <div style={cs}>
              <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>🕐 Version History</div>
              {(!form.versions || form.versions.length === 0) ? <EmptyMsg text="No previous versions yet." /> : form.versions.slice().reverse().map((v: any, i: number) => {
                const realIdx = form.versions.length - 1 - i
                return (
                  <div key={realIdx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: \`1px solid \${BOR}\` }}>
                    <span>{v.label} · {new Date(v.savedAt).toLocaleString()}</span>
                    <button style={bs} onClick={() => restoreVersion(realIdx)}>Restore</button>
                  </div>
                )
              })}
            </div>
          )}

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>✏️ Banner Builder</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
              <div><label style={lbl}>Title</label><input style={inp} value={form.title || ''} onChange={e => setForm({ ...form, title: e.target.value })} /></div>
              <div><label style={lbl}>Tagline / Subtitle</label><input style={inp} value={form.tagline || ''} onChange={e => setForm({ ...form, tagline: e.target.value })} /></div>
              <div><label style={lbl}>Base Price ₹</label><input style={inp} value={form.price || ''} onChange={e => setForm({ ...form, price: e.target.value })} /></div>
              <div><label style={lbl}>Total Tests</label><input style={inp} value={form.totalTests || ''} onChange={e => setForm({ ...form, totalTests: e.target.value })} /></div>
              <div><label style={lbl}>Validity (read-only)</label><input style={{ ...inp, opacity: 0.6 }} value={form.validity || ''} disabled /></div>
              <div><label style={lbl}>Duration (auto)</label><input style={{ ...inp, opacity: 0.6 }} value={form.duration || ''} disabled /></div>
              <div><label style={lbl}>CTA Button Text</label><input style={inp} value={form.ctaText || ''} onChange={e => setForm({ ...form, ctaText: e.target.value })} /></div>
              <div><label style={lbl}>Badge / Ribbon</label>
                <select style={inp} value={form.badge || 'none'} onChange={e => setForm({ ...form, badge: e.target.value })}>
                  {BN_BADGES.map(b => <option key={b.id} value={b.id}>{b.label}</option>)}
                </select>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8 }}>
              {[0, 1, 2].map(i => (
                <input key={i} style={inp} placeholder={'Highlight ' + (i + 1)} value={(form.highlights || [])[i] || ''} onChange={e => { const h = [...(form.highlights || ['', '', ''])]; h[i] = e.target.value; setForm({ ...form, highlights: h }) }} />
              ))}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 8, marginTop: 10 }}>
              <div><label style={lbl}>Primary Color</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={form.primaryColor || '#4D9FFF'} onChange={e => setForm({ ...form, primaryColor: e.target.value })} /></div>
              <div><label style={lbl}>Secondary Color</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={form.secondaryColor || '#00D4FF'} onChange={e => setForm({ ...form, secondaryColor: e.target.value })} /></div>
              <div><label style={lbl}>Text Color</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={form.textColor || '#FFFFFF'} onChange={e => setForm({ ...form, textColor: e.target.value })} /></div>
              <div><label style={lbl}>Accent Color</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={form.accentColor || '#FFD700'} onChange={e => setForm({ ...form, accentColor: e.target.value })} /></div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 8, marginTop: 8 }}>
              <div><label style={lbl}>Font Style</label>
                <select style={inp} value={form.fontStyle || 'modern'} onChange={e => setForm({ ...form, fontStyle: e.target.value })}>
                  {BN_FONTS.map(f => <option key={f.id} value={f.id}>{f.label}</option>)}
                </select>
              </div>
              <div><label style={lbl}>Background Image URL</label><input style={inp} value={form.bgImage || ''} onChange={e => setForm({ ...form, bgImage: e.target.value })} placeholder="https:// or pick from library" /></div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}><button style={{ ...bs, width: '100%' }} onClick={() => setShowIllustrations(true)}>🎨 Illustration Library</button></div>
            </div>

            {warnings.length > 0 && (
              <div style={{ marginTop: 10, padding: 8, borderRadius: 8, background: 'rgba(251,191,36,0.1)', border: '1px solid rgba(251,191,36,0.3)' }}>
                {warnings.map((w, i) => <div key={i} style={{ fontSize: 11, color: WARN }}>⚠️ {w}</div>)}
              </div>
            )}

            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 12 }}>
              <button style={bs} onClick={syncNow}>🔄 Sync Now</button>
              <button style={bs} onClick={() => saveBanner({ saveAsDraft: true })}>💾 Save Draft</button>
              <button style={bp} onClick={() => saveBanner({ markReady: true })}>✅ Save & Mark Ready</button>
              <button style={bs} onClick={discard}>↩️ Discard Changes</button>
            </div>
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>👁️ Preview & Variants</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
              {['card', 'wide', 'square', 'mobile'].map(s => <button key={s} style={previewSize === s ? bp : bs} onClick={() => setPreviewSize(s)}>{s.charAt(0).toUpperCase() + s.slice(1)}</button>)}
              <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: DIM, marginLeft: 8 }}>
                <input type="checkbox" checked={showSafeZone} onChange={e => setShowSafeZone(e.target.checked)} /> Safe Zone Guide
              </label>
              <button style={{ ...bs, marginLeft: 'auto' }} onClick={() => setShowAllVariants(v => !v)}>{showAllVariants ? 'Hide All Variants' : 'Generate All Variants'}</button>
            </div>
            <div ref={previewRef}><BannerLivePreview b={form} size={previewSize} showSafeZone={showSafeZone} /></div>
            <div style={{ marginTop: 10 }}><button style={bs} disabled={downloading} onClick={() => downloadPNG(previewRef, previewSize)}>{downloading ? '⟳ Exporting…' : '⬇️ Download PNG (' + previewSize + ')'}</button></div>

            {showAllVariants && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 14, marginTop: 14 }}>
                {[['card', cardRef], ['wide', wideRef], ['square', squareRef], ['mobile', mobileRef]].map(([label, ref]: any) => (
                  <div key={label} style={{ textAlign: 'center' }}>
                    <div ref={ref}><BannerLivePreview b={form} size={label} showSafeZone={false} /></div>
                    <button style={{ ...bs, marginTop: 6 }} onClick={() => downloadPNG(ref, label)}>⬇️ {label}</button>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>🖼️ Templates & Assets</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8, alignItems: 'center' }}>
              {BN_CATEGORIES.map(c => <button key={c} style={templateCat === c ? bp : bs} onClick={() => setTemplateCat(c)}>{c}</button>)}
              <input style={{ ...inp, width: 140, marginLeft: 'auto' }} placeholder="Search templates…" value={templateSearch} onChange={e => setTemplateSearch(e.target.value)} />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8, marginBottom: 14 }}>
              {filteredTemplates.map(t => (
                <div key={t.id} onClick={() => setForm({ ...form, template: t.id })} style={{ cursor: 'pointer', borderRadius: 10, height: 54, background: t.bg, border: form.template === t.id ? \`2px solid \${ACC}\` : \`1px solid \${BOR}\`, display: 'flex', alignItems: 'flex-end', padding: 4 }}>
                  <span style={{ fontSize: 8.5, color: '#fff', fontWeight: 700, textShadow: '0 1px 2px rgba(0,0,0,0.6)' }}>{t.label}</span>
                </div>
              ))}
            </div>
            <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>Color Presets</div>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
              {BN_PRESETS.map(p => (
                <div key={p.label} onClick={() => setForm({ ...form, primaryColor: p.primaryColor, secondaryColor: p.secondaryColor, textColor: p.textColor, accentColor: p.accentColor })} style={{ cursor: 'pointer', width: 46, height: 46, borderRadius: 10, background: \`linear-gradient(135deg,\${p.primaryColor},\${p.secondaryColor})\`, border: \`1px solid \${BOR}\`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 8, color: '#fff', fontWeight: 700 }} title={p.label}>{p.label[0]}</div>
              ))}
            </div>
            <button style={bs} onClick={() => setShowIllustrations(true)}>🎨 Open Illustration Library ({BN_ILLUSTRATIONS.length})</button>
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Analytics</div>
            {!analytics ? <EmptyMsg text="No analytics yet." /> : (
              <div style={{ fontSize: 11.5, color: DIM, lineHeight: 1.9 }}>
                Views: {analytics.views} · Clicks: {analytics.clicks} · Enrolls: {analytics.enrolls}<br />
                Click Rate: {analytics.clickRate}% · Conversion Rate: {analytics.conversionRate}%
              </div>
            )}
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📋 Audit Trail</div>
            {(!audit || audit.length === 0) ? <EmptyMsg text="No audit entries yet." /> : audit.map((a: any, i: number) => (
              <div key={i} style={{ fontSize: 11, color: DIM, padding: '5px 0', borderBottom: \`1px solid \${BOR}\` }}>{a.action} · by {a.performedByName || 'Admin'} · {new Date(a.timestamp).toLocaleString()}</div>
            ))}
          </div>

          <div style={{ ...cs, fontSize: 11, color: DIM }}>
            🔗 This banner is linked to <b style={{ color: TS }}>{data.batchName}</b>. Publish / Launch happens in the separate Publish Center (coming soon) — not from this tab.
          </div>
        </>
      )}

      {showIllustrations && <BN_IllustrationModal onSelect={(url: string) => setForm({ ...form, bgImage: url })} onClose={() => setShowIllustrations(false)} />}
    </div>
  )
}

`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
[
'BatchManagerUltra — add banner tab entry after coupons',
`    ['coupons', '🎟️ Coupons'],`,
`    ['coupons', '🎟️ Coupons'],
    ['banner', '🖼️ Banner'],`
],
[
'BatchManagerUltra — render BannerManagementTab',
`      {tab === 'coupons' && <CouponManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`,
`      {tab === 'coupons' && <CouponManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'banner' && <BannerManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`
],
[
'BatchManagerUltra — insert BannerManagementTab component before ControlsTab',
`// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`,
bannerTabCode + `// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`
]
]);

const bannerTabCodeSeries = bannerTabCode
  .replace(/Linked to this batch's banner\./g, "Linked to this test series' banner.")
  .replace(/for this batch/g, 'for this test series');

replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
[
'TestSeriesManagerUltra — add banner tab entry after coupons',
`    ['coupons', '🎟️ Coupons'],`,
`    ['coupons', '🎟️ Coupons'],
    ['banner', '🖼️ Banner'],`
],
[
'TestSeriesManagerUltra — render BannerManagementTab',
`      {tab === 'coupons' && <CouponManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`,
`      {tab === 'coupons' && <CouponManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'banner' && <BannerManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`
],
[
'TestSeriesManagerUltra — insert BannerManagementTab component before ControlsTab',
`// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`,
bannerTabCodeSeries + `// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`
]
]);

console.log('\\n✅ FRONTEND PATCHED SUCCESSFULLY');
NODEEOF

node /tmp/fix_banner_tab_frontend.js

echo ""
echo "=== Verifying ==="
grep -c "BannerManagementTab" "$B_TSX" "$S_TSX"

echo ""
echo "✅ DONE. Git push karke Render + Vercel pe deploy karo, phir Batch/Test Series Detail page pe naya 🖼️ Banner tab (Coupons ke baad) check karo."
