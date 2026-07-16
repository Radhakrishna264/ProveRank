#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — FPR3 BANNER MANAGEMENT & PUBLISH GATE — FRONTEND INSTALLER
# Run from your project ROOT on Replit, AFTER FPR1 + FPR2 frontend
# installers have already run.
# Safe to re-run (idempotent).
# ══════════════════════════════════════════════════════════════════
set -e
echo "🚀 ProveRank FPR3 — Banner Management & Publish Gate — FRONTEND install starting..."

# ── Auto-detect admin panel directory ──
ADMIN_DIR=$(grep -rl "NAV_TABS\|const NAV=" --include="page.tsx" . 2>/dev/null | grep -v node_modules | grep -v banner-generator | head -1 | xargs -I{} dirname {})
if [ -z "$ADMIN_DIR" ]; then
  ADMIN_DIR=$(find . -type d -path "*admin/x7k2p" -not -path "*/node_modules/*" -not -path "*banner-generator*" 2>/dev/null | head -1)
fi
if [ -z "$ADMIN_DIR" ]; then
  ADMIN_DIR="./frontend/app/admin/x7k2p"
  echo "⚠️  Could not auto-detect admin panel page.tsx — defaulting to $ADMIN_DIR"
fi
mkdir -p "$ADMIN_DIR"
PAGE_FILE="$ADMIN_DIR/page.tsx"
echo "📁 Admin panel dir: $ADMIN_DIR"

# ── Auto-detect Banner Generator nested route directory ──
BANNER_DIR=$(find "$ADMIN_DIR" -maxdepth 2 -type d -iname "banner-generator" 2>/dev/null | head -1)
if [ -z "$BANNER_DIR" ]; then
  BANNER_DIR="$ADMIN_DIR/banner-generator"
  echo "⚠️  banner-generator route dir not found — defaulting to $BANNER_DIR"
fi
mkdir -p "$BANNER_DIR"
echo "📁 Banner Generator route dir: $BANNER_DIR"

if [ ! -f "$PAGE_FILE" ]; then
  echo "❌ page.tsx not found at $ADMIN_DIR — aborting. Please edit ADMIN_DIR in this script manually and re-run."
  exit 1
fi

# ── 1) Overwrite BatchManagerUltra.tsx (adds Banner Panel — requires FPR1 already installed) ──
if [ -f "$ADMIN_DIR/BatchManagerUltra.tsx" ]; then
cat > "$ADMIN_DIR/BatchManagerUltra.tsx" << 'PRVRNK_EOF_MARKER'
'use client'
// ══════════════════════════════════════════════════════════════════
// FPR1 — BATCH MANAGEMENT ULTRA SaaS UPGRADE (Admin) — Frontend
// Home (cards + smart search/filter + create) + Detail (10 tabs)
// Add/Transfer Student by ID + Email · Pricing · Controls · Materials
// Analytics · Announcements · Settings · Audit History · Templates
// Desktop + Mobile responsive · Admin theme matched
// ══════════════════════════════════════════════════════════════════
import { useState, useEffect, useCallback, useRef } from 'react'

// ── Theme (matches global admin panel theme) ─────────────────────
const CRD  = 'rgba(0,28,52,0.88)'
const CRD2 = 'rgba(0,36,65,0.92)'
const ACC  = '#4D9FFF'
const BOR  = 'rgba(77,159,255,0.18)'
const BOR2 = 'rgba(77,159,255,0.3)'
const TS   = '#E8F4FF'
const DIM  = '#6B8FAF'
const GOOD = '#34D399'
const WARN = '#FBBF24'
const BAD  = '#F87171'

const cs: any = { background: CRD, border: `1px solid ${BOR}`, borderRadius: 14, padding: 18, marginBottom: 14, backdropFilter: 'blur(12px)' }
const inp: any = { width: '100%', padding: '10px 12px', background: 'rgba(0,22,40,0.85)', border: `1.5px solid ${BOR2}`, borderRadius: 10, color: TS, fontSize: 13, fontFamily: 'Inter,sans-serif', outline: 'none', boxSizing: 'border-box' }
const bp: any = { background: `linear-gradient(135deg,${ACC},#0055CC)`, color: '#fff', border: 'none', borderRadius: 10, padding: '10px 18px', cursor: 'pointer', fontWeight: 700, fontSize: 13, fontFamily: 'Inter,sans-serif', boxShadow: '0 4px 16px rgba(77,159,255,0.35)' }
const bs: any = { background: 'rgba(77,159,255,0.1)', color: ACC, border: `1px solid ${BOR2}`, borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const bd: any = { background: 'rgba(239,68,68,0.1)', color: BAD, border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const lbl: any = { display: 'block', fontSize: 10.5, color: DIM, marginBottom: 5, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }
const pageTitle: any = { fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TS, margin: '0 0 4px', background: `linear-gradient(90deg,${ACC},#fff)`, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }
const pageSub: any = { fontSize: 12, color: DIM, marginBottom: 18 }
const chip = (color: string, bg: string): any => ({ fontSize: 10.5, color, background: bg, padding: '3px 10px', borderRadius: 20, fontWeight: 600, display: 'inline-block' })

function useIsMobile() {
  const [m, setM] = useState(false)
  useEffect(() => {
    const chk = () => setM(window.innerWidth < 768)
    chk(); window.addEventListener('resize', chk)
    return () => window.removeEventListener('resize', chk)
  }, [])
  return m
}

function Toggle({ on, onChange, label }: { on: boolean; onChange: (v: boolean) => void; label?: string }) {
  return (
    <div onClick={() => onChange(!on)} style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
      <div style={{ width: 38, height: 20, borderRadius: 20, background: on ? ACC : 'rgba(107,143,175,0.3)', position: 'relative', transition: 'all .2s' }}>
        <div style={{ width: 16, height: 16, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: on ? 20 : 2, transition: 'all .2s' }} />
      </div>
      {label && <span style={{ fontSize: 12, color: TS }}>{label}</span>}
    </div>
  )
}

function Modal({ children, onClose, width = 560 }: { children: any; onClose: () => void; width?: number }) {
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: 14 }}>
      <div onClick={e => e.stopPropagation()} style={{ background: `linear-gradient(135deg,${CRD2},${CRD})`, border: `1.5px solid ${BOR2}`, borderRadius: 18, padding: 22, maxWidth: width, width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
        {children}
      </div>
    </div>
  )
}

function EmptyMsg({ text }: { text: string }) {
  return <div style={{ textAlign: 'center', padding: '30px 10px', color: DIM, fontSize: 12.5 }}>{text}</div>
}

// ══════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ══════════════════════════════════════════════════════════════════
export default function BatchManagerUltra({ token, API }: { token: string; API: string }) {
  const isMobile = useIsMobile()
  const [batches, setBatches] = useState<any[]>([])
  const [summary, setSummary] = useState<any>({})
  const [loading, setLoading] = useState(false)
  const [q, setQ] = useState('')
  const [filters, setFilters] = useState<any>({})
  const [showFilters, setShowFilters] = useState(false)
  const [sort, setSort] = useState('newest')
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  const [detailId, setDetailId] = useState<string | null>(() => {
    try { return typeof window !== 'undefined' ? localStorage.getItem('pr_bm_detailId') : null } catch (e) { return null }
  })
  const [showCreate, setShowCreate] = useState(false)
  const [presets, setPresets] = useState<any[]>([])
  const [toast, setToast] = useState('')

  const authHeaders = { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' }
  const base = API + '/api/admin/batch-manager'

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3500) }

  const loadBatches = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (q) params.set('q', q)
      Object.entries(filters).forEach(([k, v]: any) => { if (v !== undefined && v !== '' && v !== null) params.set(k, String(v)) })
      if (sort) params.set('sort', sort)
      const r = await fetch(base + '?' + params.toString(), { headers: authHeaders })
      const d = await r.json()
      setBatches(d.batches || [])
      setSummary(d.summary || {})
    } catch (e) { showToast('⚠️ Failed to load batches') }
    setLoading(false)
  }, [q, filters, sort])

  useEffect(() => { loadBatches() }, [loadBatches])

  useEffect(() => {
    try {
      if (detailId) localStorage.setItem('pr_bm_detailId', detailId)
      else localStorage.removeItem('pr_bm_detailId')
    } catch (e) { /* localStorage unavailable */ }
  }, [detailId])

  useEffect(() => {
    fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json()).then(d => setPresets(d.presets || [])).catch(() => {})
  }, [])

  const savePreset = async () => {
    const name = window.prompt('Preset name?')
    if (!name) return
    await fetch(base + '/filter-presets', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name, filters }) })
    const d = await fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json())
    setPresets(d.presets || [])
    showToast('✅ Filter preset saved')
  }

  const toggleSelect = (id: string) => setSelectedIds(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  const bulkAction = async (action: 'archive' | 'delete') => {
    if (selectedIds.length === 0) return
    if (action === 'delete' && !window.confirm(`Delete ${selectedIds.length} selected batch(es)? This cannot be undone.`)) return
    for (const id of selectedIds) {
      await fetch(base + '/' + id + (action === 'archive' ? '/archive' : ''), { method: action === 'archive' ? 'PUT' : 'DELETE', headers: authHeaders })
    }
    showToast(action === 'archive' ? '✅ Batches archived/unarchived' : '✅ Batches deleted')
    setSelectedIds([])
    loadBatches()
  }

  const duplicateBatch = async (id: string) => {
    const r = await fetch(base + '/' + id + '/duplicate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Batch duplicated'); loadBatches() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  const archiveBatch = async (id: string) => {
    const r = await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Status: ' + d.lifecycleStatus); loadBatches() }
  }
  const deleteBatch = async (id: string, name: string) => {
    if (!window.confirm(`Delete batch "${name}"? Students will be unassigned.`)) return
    const r = await fetch(base + '/' + id, { method: 'DELETE', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Batch deleted'); loadBatches() }
  }

  if (detailId) {
    return <BatchDetail id={detailId} base={base} authHeaders={authHeaders} onBack={() => { setDetailId(null); loadBatches() }} isMobile={isMobile} showToast={showToast} allBatches={batches} />
  }

  return (
    <div>
      <div style={pageTitle}>🗂️ Batch Management — Ultra SaaS</div>
      <div style={pageSub}>Complete lifecycle control — create, price, control, enroll, assign exams, analyze & archive batches.</div>

      {toast && <div style={{ position: 'fixed', top: 16, right: 16, zIndex: 10000, background: CRD2, border: `1px solid ${BOR2}`, borderRadius: 10, padding: '10px 16px', color: TS, fontSize: 12.5, boxShadow: '0 8px 24px rgba(0,0,0,0.4)' }}>{toast}</div>}

      {/* ── Status Summary Strip ── */}
      <div style={{ display: 'grid', gridTemplateColumns: isMobile ? 'repeat(3,1fr)' : 'repeat(6,1fr)', gap: 8, marginBottom: 14 }}>
        {[
          ['Active', summary.active, GOOD], ['Paused', summary.paused, WARN], ['Archived', summary.archived, DIM],
          ['Draft', summary.draft, '#A78BFA'], ['Upcoming', summary.upcoming, ACC], ['Students', summary.totalStudents, '#7DD3FC']
        ].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, padding: 10, textAlign: 'center' }}>
            <div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v ?? 0}</div>
            <div style={{ fontSize: 9.5, color: DIM, textTransform: 'uppercase', letterSpacing: 0.5 }}>{l}</div>
          </div>
        ))}
      </div>

      {/* ── Smart Search + Filter Bar ── */}
      <div style={cs}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <input style={{ ...inp, flex: 1, minWidth: 160 }} placeholder="🔎 Search batch, code, exam, student, faculty, email…" value={q} onChange={e => setQ(e.target.value)} />
          <button style={bs} onClick={() => setShowFilters(s => !s)}>🧰 Filters {showFilters ? '▲' : '▼'}</button>
          <select style={{ ...inp, width: 150 }} value={sort} onChange={e => setSort(e.target.value)}>
            <option value="newest">Newest</option><option value="oldest">Oldest</option>
            <option value="most_students">Most Students</option><option value="price_high">Highest Revenue</option>
            <option value="price_low">Lowest Price</option><option value="most_active">Most Active</option><option value="name">Name A-Z</option>
          </select>
          <button style={bp} onClick={() => setShowCreate(true)}>➕ Create Batch</button>
        </div>
        {showFilters && (
          <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: isMobile ? '1fr 1fr' : 'repeat(4,1fr)', gap: 10 }}>
            <div><label style={lbl}>Status</label>
              <select style={inp} value={filters.status || ''} onChange={e => setFilters({ ...filters, status: e.target.value })}>
                <option value="">All</option><option value="draft">Draft</option><option value="active">Active</option>
                <option value="upcoming">Upcoming</option><option value="paused">Paused</option><option value="archived">Archived</option>
              </select>
            </div>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={filters.exam || ''} onChange={e => setFilters({ ...filters, exam: e.target.value })}>
                <option value="">All</option><option value="NEET">NEET</option><option value="JEE">JEE</option><option value="CUET">CUET</option>
                <option value="Class 11">Class 11</option><option value="Class 12">Class 12</option><option value="Foundation">Foundation</option><option value="Crash Course">Crash Course</option>
              </select>
            </div>
            <div><label style={lbl}>Price Min</label><input style={inp} type="number" value={filters.priceMin || ''} onChange={e => setFilters({ ...filters, priceMin: e.target.value })} /></div>
            <div><label style={lbl}>Price Max</label><input style={inp} type="number" value={filters.priceMax || ''} onChange={e => setFilters({ ...filters, priceMax: e.target.value })} /></div>
            <div><label style={lbl}>Students Min</label><input style={inp} type="number" value={filters.studentMin || ''} onChange={e => setFilters({ ...filters, studentMin: e.target.value })} /></div>
            <div><label style={lbl}>Students Max</label><input style={inp} type="number" value={filters.studentMax || ''} onChange={e => setFilters({ ...filters, studentMax: e.target.value })} /></div>
            <div><label style={lbl}>Date From</label><input style={inp} type="date" value={filters.dateFrom || ''} onChange={e => setFilters({ ...filters, dateFrom: e.target.value })} /></div>
            <div><label style={lbl}>Date To</label><input style={inp} type="date" value={filters.dateTo || ''} onChange={e => setFilters({ ...filters, dateTo: e.target.value })} /></div>
            {['spotlight', 'trial', 'bundle', 'emi', 'flashsale'].map(f => (
              <div key={f} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Toggle on={filters[f] === 'true'} onChange={v => setFilters({ ...filters, [f]: v ? 'true' : '' })} label={f[0].toUpperCase() + f.slice(1)} />
              </div>
            ))}
            <div style={{ display: 'flex', gap: 8, gridColumn: isMobile ? 'span 2' : 'span 2' }}>
              <button style={bs} onClick={savePreset}>💾 Save Preset</button>
              <button style={bd} onClick={() => setFilters({})}>✕ Clear All</button>
            </div>
          </div>
        )}
        {presets.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {presets.map(p => <span key={p._id} onClick={() => setFilters(p.filters || {})} style={{ ...chip(ACC, 'rgba(77,159,255,0.12)'), cursor: 'pointer' }}>⭐ {p.name}</span>)}
          </div>
        )}
      </div>

      {/* ── Bulk Actions ── */}
      {selectedIds.length > 0 && (
        <div style={{ ...cs, display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 12.5, color: TS }}>{selectedIds.length} selected</span>
          <button style={bs} onClick={() => bulkAction('archive')}>📦 Archive/Unarchive</button>
          <button style={bd} onClick={() => bulkAction('delete')}>🗑️ Delete Selected</button>
          <button style={bs} onClick={() => setSelectedIds([])}>✕ Clear Selection</button>
        </div>
      )}

      {/* ── Batch Card Grid ── */}
      {loading ? <EmptyMsg text="⟳ Loading batches…" /> : batches.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '50px 20px', color: DIM }}>
          <div style={{ fontSize: 60, marginBottom: 10 }}>🗂️</div>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#93C5FD' }}>No Batches Found</div>
          <div style={{ fontSize: 12, marginTop: 6 }}>Create your first batch or adjust filters.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fit,minmax(280px,1fr))', gap: 12 }}>
          {batches.map(b => (
            <div key={b._id} style={{ ...cs, marginBottom: 0, position: 'relative', borderLeft: `3px solid ${b.lifecycleStatus === 'archived' ? DIM : ACC}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <input type="checkbox" checked={selectedIds.includes(b._id)} onChange={() => toggleSelect(b._id)} style={{ marginTop: 2 }} />
                <span style={chip(b.lifecycleStatus === 'active' ? GOOD : b.lifecycleStatus === 'paused' ? WARN : b.lifecycleStatus === 'archived' ? DIM : '#A78BFA', 'rgba(255,255,255,0.06)')}>{b.lifecycleStatus || 'active'}</span>
              </div>
              <div onClick={() => setDetailId(b._id)} style={{ cursor: 'pointer', marginTop: 6 }}>
                <div style={{ fontWeight: 700, fontSize: 14.5, color: '#93C5FD' }}>{b.colorIcon || '📦'} {b.name}</div>
                <div style={{ fontSize: 10, color: DIM, fontFamily: 'monospace', marginTop: 2 }}>{b.batchCode || '—'} · {b.examType}</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', margin: '8px 0' }}>
                  <span style={chip('#7DD3FC', 'rgba(59,130,246,0.12)')}>👥 {b.studentCount || 0}{b.seatLimit ? '/' + b.seatLimit : ''}</span>
                  <span style={chip('#6EE7B7', 'rgba(16,185,129,0.12)')}>📝 {b.examCount || 0} Exams</span>
                  <span style={chip('#FDE68A', 'rgba(251,191,36,0.12)')}>₹{b.effectivePrice ?? b.price ?? 0}</span>
                  <span style={chip(ACC, 'rgba(77,159,255,0.12)')}>💚 {b.healthScore ?? 0}</span>
                </div>
                <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                  {b.isSpotlight && <span style={chip('#FBBF24', 'rgba(251,191,36,0.1)')}>✨ Spotlight</span>}
                  {b.allowFreeTrial && <span style={chip(GOOD, 'rgba(52,211,153,0.1)')}>🆓 Trial</span>}
                  {b.isBundle && <span style={chip('#A78BFA', 'rgba(167,139,250,0.1)')}>📦 Bundle</span>}
                  {b.allowEMI && <span style={chip('#7DD3FC', 'rgba(125,211,252,0.1)')}>💳 EMI</span>}
                  {b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date() && <span style={chip(BAD, 'rgba(248,113,113,0.1)')}>⚡ Flash</span>}
                </div>
                <div style={{ fontSize: 9.5, color: 'rgba(148,163,184,0.5)', marginTop: 8 }}>Updated {b.updatedAt ? new Date(b.updatedAt).toLocaleDateString() : '-'}</div>
              </div>
              <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                <button style={bs} onClick={() => setDetailId(b._id)}>Open</button>
                <button style={bs} onClick={() => duplicateBatch(b._id)}>⧉ Duplicate</button>
                <button style={bs} onClick={() => archiveBatch(b._id)}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive'}</button>
                <button style={bd} onClick={() => deleteBatch(b._id, b.name)}>🗑️</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showCreate && <CreateBatchWizard base={base} authHeaders={authHeaders} isMobile={isMobile} onClose={() => setShowCreate(false)} onCreated={() => { setShowCreate(false); loadBatches(); showToast('✅ Batch created') }} />}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════
// CREATE BATCH WIZARD (multi-step)
// ══════════════════════════════════════════════════════════════════
function CreateBatchWizard({ base, authHeaders, isMobile, onClose, onCreated }: any) {
  const [step, setStep] = useState(1)
  const [templates, setTemplates] = useState<any[]>([])
  const [form, setForm] = useState<any>({
    name: '', batchCode: '', examType: 'NEET', description: '', colorIcon: '📦',
    lifecycleStatus: 'draft', visibility: 'public', seatLimit: 0, enrollmentRule: 'open',
    price: 0, discountPrice: '', allowFreeTrial: false, trialDays: 3, isBundle: false,
    bundlePrice: '', allowEMI: false, isSpotlight: false, autoArchiveAfterEnd: false, templateId: ''
  })
  const [dupWarn, setDupWarn] = useState<any>(null)

  useEffect(() => { fetch(base + '/templates', { headers: authHeaders }).then(r => r.json()).then(d => setTemplates(d.templates || [])).catch(() => {}) }, [])

  const set = (k: string, v: any) => setForm((p: any) => ({ ...p, [k]: v }))

  const submit = async (confirmDuplicate = false) => {
    const r = await fetch(base, { method: 'POST', headers: authHeaders, body: JSON.stringify({ ...form, confirmDuplicate }) })
    const d = await r.json()
    if (d.warning === 'duplicate') { setDupWarn(d); return }
    if (d.success) onCreated()
    else alert(d.error || 'Failed to create batch')
  }

  const steps = ['Basic Info', 'Lifecycle & Enrollment', 'Pricing Wizard', 'Default Controls', 'Preview & Confirm']

  return (
    <Modal onClose={onClose} width={640}>
      <div style={{ fontWeight: 800, fontSize: 17, color: ACC, marginBottom: 4 }}>➕ Create New Batch</div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 16 }}>
        {steps.map((s, i) => <span key={s} style={{ ...chip(i + 1 === step ? '#fff' : DIM, i + 1 === step ? ACC : 'rgba(255,255,255,0.05)'), fontSize: 10 }}>{i + 1}. {s}</span>)}
      </div>

      {step === 1 && (
        <div>
          {templates.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <label style={lbl}>Batch Template Picker (optional)</label>
              <select style={inp} value={form.templateId} onChange={e => set('templateId', e.target.value)}>
                <option value="">Start blank</option>
                {templates.map(t => <option key={t._id} value={t._id}>{t.name}</option>)}
              </select>
            </div>
          )}
          <label style={lbl}>Batch Name *</label><input style={{ ...inp, marginBottom: 10 }} value={form.name} onChange={e => set('name', e.target.value)} placeholder="e.g. NEET Dropper 2027" />
          <label style={lbl}>Batch Code</label><input style={{ ...inp, marginBottom: 10 }} value={form.batchCode} onChange={e => set('batchCode', e.target.value)} placeholder="Auto-generated if left blank" />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={form.examType} onChange={e => set('examType', e.target.value)}>
                {['NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course', 'Other'].map(x => <option key={x}>{x}</option>)}
              </select>
            </div>
            <div><label style={lbl}>Cover Icon</label><input style={inp} value={form.colorIcon} onChange={e => set('colorIcon', e.target.value)} /></div>
          </div>
          <label style={{ ...lbl, marginTop: 10 }}>Description</label>
          <textarea style={{ ...inp, minHeight: 60 }} value={form.description} onChange={e => set('description', e.target.value)} />
        </div>
      )}

      {step === 2 && (
        <div>
          <label style={lbl}>Lifecycle Mode</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.lifecycleStatus} onChange={e => set('lifecycleStatus', e.target.value)}>
            {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
          </select>
          <label style={lbl}>Enrollment Rule Builder</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.enrollmentRule} onChange={e => set('enrollmentRule', e.target.value)}>
            <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option>
            <option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval by Criteria</option>
          </select>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Seat Limit (0 = unlimited)</label><input type="number" style={inp} value={form.seatLimit} onChange={e => set('seatLimit', e.target.value)} /></div>
            <div><label style={lbl}>Visibility</label>
              <select style={inp} value={form.visibility} onChange={e => set('visibility', e.target.value)}>
                <option value="public">Public</option><option value="private">Private</option><option value="invite_only">Invite Only</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {step === 3 && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Base Price ₹</label><input type="number" style={inp} value={form.price} onChange={e => set('price', e.target.value)} /></div>
            <div><label style={lbl}>Discount Price ₹</label><input type="number" style={inp} value={form.discountPrice} onChange={e => set('discountPrice', e.target.value)} /></div>
          </div>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <Toggle on={form.allowFreeTrial} onChange={v => set('allowFreeTrial', v)} label="Enable Free Trial" />
            {form.allowFreeTrial && <input type="number" style={inp} value={form.trialDays} onChange={e => set('trialDays', e.target.value)} placeholder="Trial days" />}
            <Toggle on={form.isBundle} onChange={v => set('isBundle', v)} label="Bundle Pricing" />
            {form.isBundle && <input type="number" style={inp} value={form.bundlePrice} onChange={e => set('bundlePrice', e.target.value)} placeholder="Bundle price" />}
            <Toggle on={form.allowEMI} onChange={v => set('allowEMI', v)} label="EMI Eligible" />
          </div>
        </div>
      )}

      {step === 4 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Toggle on={form.isSpotlight} onChange={v => set('isSpotlight', v)} label="✨ Spotlight (Featured)" />
          <Toggle on={form.autoArchiveAfterEnd} onChange={v => set('autoArchiveAfterEnd', v)} label="🗄️ Auto-Archive After End Date" />
        </div>
      )}

      {step === 5 && (
        <div>
          <div style={{ ...cs, marginBottom: 0 }}>
            <div style={{ fontWeight: 700, color: '#93C5FD', fontSize: 14 }}>{form.colorIcon} {form.name || '(Unnamed Batch)'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.examType} · {form.lifecycleStatus} · Seat Limit: {form.seatLimit || 'Unlimited'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>Price: ₹{form.price} {form.discountPrice ? `(₹${form.discountPrice} discounted)` : ''}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.allowFreeTrial ? '🆓 Trial Enabled · ' : ''}{form.isBundle ? '📦 Bundle · ' : ''}{form.allowEMI ? '💳 EMI · ' : ''}{form.isSpotlight ? '✨ Spotlight' : ''}</div>
          </div>
          {dupWarn && (
            <div style={{ marginTop: 10, padding: 10, background: 'rgba(251,191,36,0.1)', border: '1px solid rgba(251,191,36,0.3)', borderRadius: 8, fontSize: 11.5, color: WARN }}>
              ⚠️ Similar batch exists: "{dupWarn.existing?.name}" ({dupWarn.existing?.batchCode}). Create anyway?
              <div style={{ marginTop: 8 }}><button style={bp} onClick={() => submit(true)}>Yes, Create Anyway</button></div>
            </div>
          )}
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 18 }}>
        <button style={bs} onClick={step === 1 ? onClose : () => setStep(step - 1)}>{step === 1 ? 'Cancel' : '← Back'}</button>
        {step < 5 ? <button style={bp} onClick={() => setStep(step + 1)}>Next →</button> : <button style={bp} onClick={() => submit(false)}>✅ Publish Batch</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// ADD / TRANSFER STUDENT MODAL — dual ID/Email selector
// ══════════════════════════════════════════════════════════════════
function StudentAddTransferModal({ base, authHeaders, batchId, mode, batches, onClose, onDone, showToast }: any) {
  const [inputType, setInputType] = useState<'id' | 'email'>('id')
  const [val, setVal] = useState('')
  const [suggestions, setSuggestions] = useState<any[]>([])
  const [matched, setMatched] = useState<any>(null)
  const [toBatch, setToBatch] = useState('')
  const [beforeAfter, setBeforeAfter] = useState<any>(null)

  useEffect(() => {
    if (!val || val.length < 2) { setSuggestions([]); return }
    const t = setTimeout(() => {
      fetch(base + '/student-lookup?query=' + encodeURIComponent(val), { headers: authHeaders }).then(r => r.json()).then(d => setSuggestions(d.matches || [])).catch(() => {})
    }, 300)
    return () => clearTimeout(t)
  }, [val])

  const confirm = async () => {
    const payload: any = inputType === 'id' ? { studentId: matched ? matched.studentId || matched._id : val } : { email: matched ? matched.email : val }
    if (mode === 'add') {
      const r = await fetch(base + '/' + batchId + '/students/add', { method: 'POST', headers: authHeaders, body: JSON.stringify(payload) })
      const d = await r.json()
      if (d.success) { setBeforeAfter(d); showToast('✅ Student added to batch'); }
      else showToast('⚠️ ' + (d.error || 'Failed'))
    } else {
      if (!toBatch) { showToast('⚠️ Select target batch'); return }
      const r = await fetch(base + '/' + batchId + '/students/transfer', { method: 'POST', headers: authHeaders, body: JSON.stringify({ ...payload, toBatchId: toBatch }) })
      const d = await r.json()
      if (d.success) { setBeforeAfter(d); showToast('✅ Student transferred') }
      else showToast('⚠️ ' + (d.error || 'Failed'))
    }
  }

  return (
    <Modal onClose={onClose} width={480}>
      <div style={{ fontWeight: 800, fontSize: 16, color: ACC, marginBottom: 12 }}>{mode === 'add' ? '➕ Add Student to Batch' : '🔄 Transfer Student'}</div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
        <button style={inputType === 'id' ? bp : bs} onClick={() => setInputType('id')}>🆔 By Student ID</button>
        <button style={inputType === 'email' ? bp : bs} onClick={() => setInputType('email')}>📧 By Registered Email</button>
      </div>
      <input style={inp} value={val} onChange={e => { setVal(e.target.value); setMatched(null) }} placeholder={inputType === 'id' ? 'Enter Student ID (PRxxABCD)…' : 'Enter registered email…'} />
      {suggestions.length > 0 && !matched && (
        <div style={{ marginTop: 6, border: `1px solid ${BOR}`, borderRadius: 8, overflow: 'hidden' }}>
          {suggestions.map(s => (
            <div key={s._id} onClick={() => { setMatched(s); setVal(inputType === 'id' ? (s.studentId || s._id) : s.email) }} style={{ padding: '8px 10px', cursor: 'pointer', fontSize: 12, borderBottom: `1px solid ${BOR}`, color: TS }}>
              {s.name} — {s.email} {s.studentId ? `(${s.studentId})` : ''}
            </div>
          ))}
        </div>
      )}
      {matched && <div style={{ marginTop: 8, fontSize: 12, color: GOOD }}>✅ Matched: {matched.name} ({matched.email})</div>}

      {mode === 'transfer' && (
        <div style={{ marginTop: 12 }}>
          <label style={lbl}>Move To Batch</label>
          <select style={inp} value={toBatch} onChange={e => setToBatch(e.target.value)}>
            <option value="">Select target batch…</option>
            {(batches || []).filter((b: any) => b._id !== batchId).map((b: any) => <option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
        </div>
      )}

      {beforeAfter && (
        <div style={{ marginTop: 12, padding: 10, background: 'rgba(52,211,153,0.08)', border: '1px solid rgba(52,211,153,0.25)', borderRadius: 8, fontSize: 12, color: GOOD }}>
          {mode === 'add'
            ? <>Before: {beforeAfter.before?.count} students → After: {beforeAfter.after?.count} students</>
            : <>Source: {beforeAfter.before?.fromCount} → {beforeAfter.after?.fromCount} · Target: {beforeAfter.before?.toCount} → {beforeAfter.after?.toCount}</>}
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 16 }}>
        <button style={bs} onClick={onClose}>Close</button>
        {!beforeAfter ? <button style={bp} onClick={confirm}>Confirm</button> : <button style={bp} onClick={() => { onDone(); onClose() }}>Done</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// BATCH DETAIL PAGE — 10 Tabs
// ══════════════════════════════════════════════════════════════════
function BatchDetail({ id, base, authHeaders, onBack, isMobile, showToast, allBatches }: any) {
  const [tab, setTab] = useState('overview')
  const [detail, setDetail] = useState<any>(null)
  const [notFound, setNotFound] = useState(false)
  const [modal, setModal] = useState<'' | 'add' | 'transfer'>('')

  const load = useCallback(() => {
    fetch(base + '/' + id, { headers: authHeaders })
      .then(r => { if (!r.ok) throw new Error('not-found'); return r.json() })
      .then(d => { if (d.error) throw new Error(d.error); setDetail(d) })
      .catch(() => setNotFound(true))
  }, [id])
  useEffect(() => { load() }, [load])

  if (notFound) {
    return (
      <div style={{ textAlign: 'center', padding: '50px 20px' }}>
        <div style={{ fontSize: 40, marginBottom: 10 }}>⚠️</div>
        <div style={{ color: '#F87171', fontWeight: 700, marginBottom: 10 }}>This batch could not be found. It may have been deleted.</div>
        <button style={bp} onClick={onBack}>← Back to Batch Management</button>
      </div>
    )
  }

  const tabs = [
    ['overview', '📊 Overview'], ['students', '👥 Students'], ['exams', '📝 Exams'], ['pricing', '💰 Pricing'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],
    ['announcements', '📢 Announcements'], ['settings', '🔧 Settings'], ['audit', '🕐 Audit History']
  ]

  if (!detail) return <EmptyMsg text="⟳ Loading batch details…" />
  const b = detail.batch || {}

  return (
    <div>
      <button style={{ ...bs, marginBottom: 10 }} onClick={onBack}>← Back to Batch Management</button>

      <div style={{ ...cs, background: `linear-gradient(135deg,${CRD2},${CRD})` }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
          <div>
            <div style={{ fontWeight: 800, fontSize: 19, color: '#93C5FD' }}>{b.colorIcon || '📦'} {b.name}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{b.batchCode} · {b.examType} · {b.lifecycleStatus}</div>
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: ACC }}>{b.healthScore}</div><div style={{ fontSize: 9, color: DIM }}>HEALTH SCORE</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#7DD3FC' }}>{b.studentCount}</div><div style={{ fontSize: 9, color: DIM }}>STUDENTS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#6EE7B7' }}>{b.examCount}</div><div style={{ fontSize: 9, color: DIM }}>EXAMS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#FDE68A' }}>₹{b.effectivePrice}</div><div style={{ fontSize: 9, color: DIM }}>PRICE</div></div>
          </div>
        </div>
        {detail.alerts?.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {detail.alerts.map((a: any, i: number) => <span key={i} style={chip(a.type === 'warning' ? WARN : ACC, 'rgba(255,255,255,0.05)')}>⚠️ {a.message}</span>)}
          </div>
        )}
      </div>

      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14, overflowX: isMobile ? 'auto' : 'visible' }}>
        {tabs.map(([k, l]) => <button key={k} onClick={() => setTab(k)} style={tab === k ? bp : bs}>{l}</button>)}
      </div>

      {tab === 'overview' && <OverviewTab detail={detail} base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} load={load} />}
      {tab === 'students' && <StudentsTab base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} />}
      {tab === 'exams' && <ExamsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'controls' && <ControlsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'materials' && <MaterialsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'analytics' && <AnalyticsTab base={base} authHeaders={authHeaders} id={id} allBatches={allBatches} />}
      {tab === 'announcements' && <AnnouncementsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'settings' && <SettingsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'audit' && <AuditTab base={base} authHeaders={authHeaders} id={id} />}

      {modal && <StudentAddTransferModal base={base} authHeaders={authHeaders} batchId={id} mode={modal} batches={allBatches} onClose={() => setModal('')} onDone={load} showToast={showToast} />}
    </div>
  )
}

// ── 6) OVERVIEW TAB ──
function OverviewTab({ detail, base, authHeaders, id, setModal, showToast, load }: any) {
  const b = detail.batch
  const exportSnapshot = () => window.open(base + '/' + id + '/export-snapshot')
  const archiveToggle = async () => { await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders }); showToast('✅ Status updated'); load() }
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(200px,1fr))', gap: 12 }}>
        <div style={cs}><div style={lbl}>Seat Utilization</div><div style={{ fontSize: 22, fontWeight: 800, color: ACC }}>{b.seatUtilPct ?? '∞'}{b.seatUtilPct !== null ? '%' : ''}</div></div>
        <div style={cs}><div style={lbl}>Engagement Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: GOOD }}>{b.engagementMeter}%</div></div>
        <div style={cs}><div style={lbl}>Revenue Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: '#FDE68A' }}>{b.revenueMeter}%</div></div>
        <div style={cs}><div style={lbl}>Faculty</div><div style={{ fontSize: 15, fontWeight: 700, color: TS }}>{b.teacherAssigned || '—'}</div></div>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '14px 0' }}>
        <button style={bp} onClick={() => setModal('add')}>➕ Add Student</button>
        <button style={bp} onClick={() => setModal('transfer')}>🔄 Transfer Student</button>
        <button style={bs} onClick={archiveToggle}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive Batch'}</button>
        <button style={bs} onClick={exportSnapshot}>📤 Export Snapshot</button>
      </div>
      <BannerPanel base={base} authHeaders={authHeaders} id={id} linkedType="batch" showToast={showToast} />
      <div style={cs}>
        <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 8, color: TS }}>Recent Activity</div>
        {(detail.recentActivity || []).length === 0 ? <EmptyMsg text="No recent activity yet." /> :
          detail.recentActivity.map((a: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              <b style={{ color: TS }}>{a.action}</b> — {a.field} {a.changedByName ? 'by ' + a.changedByName : ''} · {new Date(a.timestamp).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── FPR3: Banner Panel (Publish Gate integration) ──
function BannerPanel({ base, authHeaders, id, linkedType, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/banner-panel', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const regenerate = async () => {
    const r = await fetch(base + '/' + id + '/banner-panel/regenerate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Banner draft generated'); load() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  if (!data) return null
  const banner = data.banner
  const gate = data.gate || {}
  const openBannerManagement = () => window.open(`/admin/x7k2p/banner-generator?${linkedType === 'batch' ? 'batchId' : 'seriesId'}=${id}&${linkedType === 'batch' ? 'batchName' : 'seriesName'}=${encodeURIComponent(banner?.title || '')}`, '_blank')
  return (
    <div style={{ ...cs, border: `1px solid ${gate.ready ? 'rgba(52,211,153,0.35)' : 'rgba(248,113,113,0.35)'}` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: TS }}>🖼️ Banner Panel</div>
        <span style={{ fontSize: 10.5, fontWeight: 700, color: gate.ready ? GOOD : BAD }}>{gate.ready ? '✅ Launch Allowed' : '⛔ Launch Blocked'}</span>
      </div>
      {banner ? (
        <>
          <div style={{ fontSize: 12, color: DIM, marginBottom: 8 }}>{banner.title} · Status: {banner.status} · Quality: {banner.qualityScore || 0}/100</div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <button style={bs} onClick={openBannerManagement}>✏️ Edit Banner</button>
            <button style={bs} onClick={regenerate}>🔄 Regenerate Draft</button>
          </div>
        </>
      ) : (
        <>
          <div style={{ fontSize: 12, color: BAD, marginBottom: 8 }}>{gate.reason || 'No banner created yet for this batch.'}</div>
          <button style={bp} onClick={regenerate}>➕ Auto-Generate Banner Draft</button>
        </>
      )}
    </div>
  )
}

// ── 7) STUDENTS TAB ──
function StudentsTab({ base, authHeaders, id, setModal, showToast }: any) {
  const [students, setStudents] = useState<any[]>([])
  const [q, setQ] = useState(''); const [status, setStatus] = useState(''); const [sort, setSort] = useState('')
  const load = useCallback(() => {
    const params = new URLSearchParams(); if (q) params.set('q', q); if (status) params.set('status', status); if (sort) params.set('sort', sort)
    fetch(base + '/' + id + '/students?' + params.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setStudents(d.students || [])).catch(() => {})
  }, [q, status, sort])
  useEffect(() => { load() }, [load])

  const remove = async (sid: string) => { if (!window.confirm('Remove student from batch?')) return; await fetch(base + '/' + id + '/students/' + sid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Removed'); load() }
  const setInactive = async (sid: string, s: string) => { await fetch(base + '/' + id + '/students/' + sid + '/status', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ status: s }) }); load() }
  const exportCsv = () => window.open(base + '/' + id + '/students/export')

  return (
    <div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
        <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder="Search student…" value={q} onChange={e => setQ(e.target.value)} />
        <select style={{ ...inp, width: 130 }} value={status} onChange={e => setStatus(e.target.value)}><option value="">All Status</option><option value="active">Active</option><option value="inactive">Inactive</option></select>
        <select style={{ ...inp, width: 130 }} value={sort} onChange={e => setSort(e.target.value)}><option value="">Newest</option><option value="oldest">Oldest</option><option value="name">Name</option></select>
        <button style={bp} onClick={() => setModal('add')}>➕ Add</button>
        <button style={bp} onClick={() => setModal('transfer')}>🔄 Transfer</button>
        <button style={bs} onClick={exportCsv}>⬇️ Export CSV</button>
      </div>
      {students.length === 0 ? <EmptyMsg text="No students in this batch yet." /> : (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
            <thead><tr style={{ color: DIM, textAlign: 'left' }}><th style={{ padding: 6 }}>Name</th><th>ID</th><th>Email</th><th>Status</th><th>Joined</th><th>Action</th></tr></thead>
            <tbody>
              {students.map(s => (
                <tr key={s._id} style={{ borderTop: `1px solid ${BOR}` }}>
                  <td style={{ padding: 6, color: TS }}>{s.name}</td><td style={{ color: DIM }}>{s.studentId}</td><td style={{ color: DIM }}>{s.email}</td>
                  <td><span style={chip(s.status === 'active' ? GOOD : DIM, 'rgba(255,255,255,0.05)')}>{s.status}</span></td>
                  <td style={{ color: DIM }}>{s.joinedDate ? new Date(s.joinedDate).toLocaleDateString() : '-'}</td>
                  <td>
                    <button style={{ ...bs, padding: '3px 8px', marginRight: 4 }} onClick={() => setInactive(s._id, s.status === 'active' ? 'inactive' : 'active')}>{s.status === 'active' ? 'Mark Inactive' : 'Mark Active'}</button>
                    <button style={{ ...bd, padding: '3px 8px' }} onClick={() => remove(s._id)}>Remove</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ── 8) EXAMS TAB ──
function ExamsTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>({ assigned: [], available: [] })
  const load = useCallback(() => fetch(base + '/' + id + '/exams', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const assign = async (examId: string) => { await fetch(base + '/' + id + '/exams/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ examId }) }); showToast('✅ Exam assigned'); load() }
  const unassign = async (examId: string) => { await fetch(base + '/' + id + '/exams/' + examId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Exam removed'); load() }
  const updateFlag = async (examId: string, field: string, val: boolean) => { await fetch(base + '/' + id + '/exams/' + examId, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ [field]: val }) }); load() }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Exams ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No exams assigned yet." /> : data.assigned.map((e: any) => (
          <div key={e._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 6 }}>
              <span style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{e.title || e.name}</span>
              <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
            </div>
            <div style={{ display: 'flex', gap: 10, marginTop: 6, flexWrap: 'wrap' }}>
              {['required', 'locked', 'featured', 'hidden'].map(f => (
                <Toggle key={f} on={!!e.control?.[f]} onChange={v => updateFlag(e._id, f, v)} label={f} />
              ))}
            </div>
          </div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Available Exams</div>
        {(!data.available || data.available.length === 0) ? <EmptyMsg text="No more exams available." /> : data.available.map((e: any) => (
          <div key={e._id} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
            <span style={{ color: DIM, fontSize: 12 }}>{e.title || e.name}</span>
            <button style={{ ...bs, padding: '3px 10px' }} onClick={() => assign(e._id)}>+ Assign</button>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 9) PRICING TAB ──
function PricingTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const [form, setForm] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/pricing', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  useEffect(() => { if (data?.pricing) setForm(data.pricing) }, [data])
  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const save = async () => { const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }); const d = await r.json(); if (d.success) { showToast('✅ Pricing updated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleLock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        <button style={bs} onClick={toggleLock}>{p.priceLocked ? 'Unlock' : 'Lock'} Price</button>
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Bundle Price ₹</label><input style={inp} type="number" value={form.bundlePrice || ''} onChange={e => setForm({ ...form, bundlePrice: e.target.value })} /></div>
        <div><label style={lbl}>Early Bird Price ₹</label><input style={inp} type="number" value={form.earlyBirdPrice || ''} onChange={e => setForm({ ...form, earlyBirdPrice: e.target.value })} /></div>
        <div><label style={lbl}>Limited Time Price ₹</label><input style={inp} type="number" value={form.limitedTimePrice || ''} onChange={e => setForm({ ...form, limitedTimePrice: e.target.value })} /></div>
        <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.couponCode || ''} onChange={e => setForm({ ...form, couponCode: e.target.value })} /></div>
      </div>
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '4px 0 14px' }}>
        <Toggle on={!!form.allowFreeTrial} onChange={v => setForm({ ...form, allowFreeTrial: v })} label="Free Trial" />
        <Toggle on={!!form.allowEMI} onChange={v => setForm({ ...form, allowEMI: v })} label="EMI" />
      </div>
      <button style={bp} onClick={save}>💾 Save Pricing</button>

      <div style={{ ...cs, marginTop: 16 }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>💡 Revenue Forecast</div>
        <div style={{ fontSize: 12, color: DIM }}>Expected Income: ₹{Math.round(data.forecast?.expectedIncome || 0)} · Conversion Estimate: {data.forecast?.conversionEstimate}% · Offer Performance: {data.forecast?.offerPerformance}</div>
      </div>

      <div style={{ ...cs }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>📜 Price History Timeline</div>
        {(!data.history || data.history.length === 0) ? <EmptyMsg text="No price changes yet." /> :
          data.history.slice().reverse().map((h: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              {h.field}: ₹{h.oldPrice} → ₹{h.newPrice} by {h.updatedByName} · {new Date(h.updatedAt).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/controls', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!data) return <EmptyMsg text="⟳ Loading controls…" />
  const c = data.controls
  const update = async (patch: any) => { await fetch(base + '/' + id + '/controls', { method: 'PUT', headers: authHeaders, body: JSON.stringify(patch) }); showToast('✅ Control updated'); load(); loadParent && loadParent() }
  const pause = async () => { await fetch(base + '/' + id + '/controls/pause', { method: 'PUT', headers: authHeaders }); showToast('✅ Pause toggled'); load(); loadParent && loadParent() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 14 }}>
        <Toggle on={c.isSpotlight} onChange={v => update({ isSpotlight: v })} label="✨ Spotlight" />
        <Toggle on={c.isBundle} onChange={v => update({ isBundle: v })} label="📦 Bundle" />
        <Toggle on={c.allowFreeTrial} onChange={v => update({ allowFreeTrial: v })} label="🆓 Free Trial" />
        <Toggle on={c.allowEMI} onChange={v => update({ allowEMI: v })} label="💳 EMI" />
      </div>
      <div style={cs}>
        <label style={lbl}>Batch Status Manager</label>
        <select style={inp} value={c.lifecycleStatus} onChange={e => update({ lifecycleStatus: e.target.value })}>
          {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Enrollment Lock / Access Policy</label>
        <select style={{ ...inp, marginBottom: 8 }} value={c.enrollmentRule} onChange={e => update({ enrollmentRule: e.target.value })}>
          <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval</option>
        </select>
        <select style={inp} value={c.accessPolicy} onChange={e => update({ accessPolicy: e.target.value })}>
          <option value="open">Open Access</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="code_based">Code-Based Join</option>
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Seat Limit</label>
        <input style={inp} type="number" value={c.seatLimit} onChange={e => update({ seatLimit: e.target.value })} />
      </div>
      <button style={bd} onClick={pause}>{c.lifecycleStatus === 'paused' ? '▶️ Resume Batch (One-Click)' : '⏸️ One-Click Pause'}</button>
      {data.snapshot && <div style={{ fontSize: 11, color: DIM, marginTop: 10 }}>Last applied by {data.snapshot.appliedBy} at {new Date(data.snapshot.appliedAt).toLocaleString()}</div>}
    </div>
  )
}

// ── 11) MATERIALS TAB ──
function MaterialsTab({ base, authHeaders, id, showToast }: any) {
  const [materials, setMaterials] = useState<any[]>([])
  const [form, setForm] = useState<any>({ title: '', type: 'pdf', url: '', category: 'General' })
  const load = useCallback(() => fetch(base + '/' + id + '/materials', { headers: authHeaders }).then(r => r.json()).then(d => setMaterials(d.materials || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const add = async () => { if (!form.title) return showToast('⚠️ Title required'); await fetch(base + '/' + id + '/materials', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) }); showToast('✅ Material added'); setForm({ title: '', type: 'pdf', url: '', category: 'General' }); load() }
  const pin = async (mid: string, pinned: boolean) => { await fetch(base + '/' + id + '/materials/' + mid, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ pinned: !pinned }) }); load() }
  const del = async (mid: string) => { if (!window.confirm('Delete material?')) return; await fetch(base + '/' + id + '/materials/' + mid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Deleted'); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8 }}>
        <input style={inp} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <select style={inp} value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>{['pdf', 'video', 'doc', 'link', 'image', 'other'].map(x => <option key={x}>{x}</option>)}</select>
        <input style={inp} placeholder="URL" value={form.url} onChange={e => setForm({ ...form, url: e.target.value })} />
        <input style={inp} placeholder="Category" value={form.category} onChange={e => setForm({ ...form, category: e.target.value })} />
        <button style={bp} onClick={add}>⬆️ Upload</button>
      </div>
      {materials.length === 0 ? <EmptyMsg text="No materials uploaded yet." /> : materials.map(m => (
        <div key={m._id} style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{m.pinned ? '📌 ' : ''}{m.title} <span style={{ fontSize: 10, color: DIM }}>v{m.version}</span></div>
            <div style={{ fontSize: 10, color: DIM }}>{m.type} · {m.subject} {m.expiryDate ? '· expires ' + new Date(m.expiryDate).toLocaleDateString() : ''}</div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={bs} onClick={() => pin(m._id, m.pinned)}>{m.pinned ? 'Unpin' : 'Pin'}</button>
            <button style={bd} onClick={() => del(m._id)}>Delete</button>
          </div>
        </div>
      ))}
    </div>
  )
}

// ── 12) ANALYTICS TAB ──
function AnalyticsTab({ base, authHeaders, id, allBatches }: any) {
  const [data, setData] = useState<any>(null)
  const [compareWith, setCompareWith] = useState('')
  const [cmp, setCmp] = useState<any>(null)
  useEffect(() => { fetch(base + '/' + id + '/analytics', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}) }, [])
  const runCompare = async () => { if (!compareWith) return; const d = await fetch(base + '/' + id + '/analytics/compare?withId=' + compareWith, { headers: authHeaders }).then(r => r.json()); setCmp(d) }
  if (!data) return <EmptyMsg text="⟳ Loading analytics…" />
  const a = data.analytics
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(150px,1fr))', gap: 10 }}>
        {[['Health Score', a.healthScore, ACC], ['Active Users', a.activeUsers, '#7DD3FC'], ['Exam Participation', a.examParticipation, '#6EE7B7'],
        ['Avg Score', a.avgScore ?? '—', '#FDE68A'], ['Revenue', '₹' + a.revenueSummary, GOOD], ['Seat Util %', a.seatUtilization ?? '∞', WARN],
        ['Engagement Trend', a.engagementTrend + '%', ACC], ['Revenue/Seat', '₹' + a.revenuePerSeat, '#A78BFA'], ['Churn Trend', a.churnTrend, BAD]].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v}</div><div style={{ fontSize: 9.5, color: DIM }}>{l}</div></div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>🔻 Conversion Funnel</div>
        <div style={{ fontSize: 12, color: DIM }}>Views: {a.conversionFunnel?.views} → Wishlisted: {a.conversionFunnel?.wishlisted} → Enrolled: {a.conversionFunnel?.enrolled}</div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>⚖️ Batch Comparison</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <select style={inp} value={compareWith} onChange={e => setCompareWith(e.target.value)}>
            <option value="">Select batch to compare…</option>
            {(allBatches || []).filter((b: any) => b._id !== id).map((b: any) => <option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
          <button style={bs} onClick={runCompare}>Compare</button>
        </div>
        {cmp && <div style={{ fontSize: 12, color: DIM, marginTop: 8 }}>{cmp.a?.name}: {cmp.a?.studentCount} students, ₹{cmp.a?.revenue} vs {cmp.b?.name}: {cmp.b?.studentCount} students, ₹{cmp.b?.revenue}</div>}
      </div>
    </div>
  )
}

// ── 13) ANNOUNCEMENTS TAB ──
function AnnouncementsTab({ base, authHeaders, id, showToast }: any) {
  const [list, setList] = useState<any[]>([])
  const [form, setForm] = useState({ title: '', message: '', urgent: false, scheduledAt: '' })
  const load = useCallback(() => fetch(base + '/' + id + '/announcements', { headers: authHeaders }).then(r => r.json()).then(d => setList(d.announcements || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const send = async () => {
    if (!form.message) return showToast('⚠️ Message required')
    const r = await fetch(base + '/' + id + '/announcements', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) })
    const d = await r.json()
    showToast(`✅ Sent to ${d.notified || 0} students`)
    setForm({ title: '', message: '', urgent: false, scheduledAt: '' }); load()
  }
  return (
    <div>
      <div style={cs}>
        <input style={{ ...inp, marginBottom: 8 }} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <textarea style={{ ...inp, minHeight: 70, marginBottom: 8 }} placeholder="Message" value={form.message} onChange={e => setForm({ ...form, message: e.target.value })} />
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
          <Toggle on={form.urgent} onChange={v => setForm({ ...form, urgent: v })} label="🚨 Urgent" />
          <input style={{ ...inp, width: 200 }} type="datetime-local" value={form.scheduledAt} onChange={e => setForm({ ...form, scheduledAt: e.target.value })} />
          <button style={bp} onClick={send}>📢 Send / Schedule</button>
        </div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>History</div>
        {list.length === 0 ? <EmptyMsg text="No announcements sent yet." /> : list.map((a: any) => (
          <div key={a._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{a.urgent ? '🚨 ' : ''}{a.title}</div>
            <div style={{ color: DIM, fontSize: 11 }}>{a.message}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 14) SETTINGS TAB ──
function SettingsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [s, setS] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/settings', { headers: authHeaders }).then(r => r.json()).then(d => setS(d.settings)).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!s) return <EmptyMsg text="⟳ Loading settings…" />
  const save = async () => { await fetch(base + '/' + id, { method: 'PUT', headers: authHeaders, body: JSON.stringify(s) }); showToast('✅ Settings saved'); load(); loadParent && loadParent() }
  const toggleLock = async () => { await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders }); load() }
  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Batch Name</label><input style={inp} value={s.name} onChange={e => setS({ ...s, name: e.target.value })} /></div>
        <div><label style={lbl}>Color / Icon</label><input style={inp} value={s.colorIcon} onChange={e => setS({ ...s, colorIcon: e.target.value })} /></div>
        <div><label style={lbl}>Start Date</label><input style={inp} type="date" value={s.startDate ? s.startDate.slice(0, 10) : ''} onChange={e => setS({ ...s, startDate: e.target.value })} /></div>
        <div><label style={lbl}>End Date</label><input style={inp} type="date" value={s.endDate ? s.endDate.slice(0, 10) : ''} onChange={e => setS({ ...s, endDate: e.target.value })} /></div>
        <div><label style={lbl}>Seat Limit</label><input style={inp} type="number" value={s.seatLimit} onChange={e => setS({ ...s, seatLimit: e.target.value })} /></div>
        <div><label style={lbl}>Teacher / Faculty</label><input style={inp} value={s.teacherAssigned} onChange={e => setS({ ...s, teacherAssigned: e.target.value })} /></div>
      </div>
      <div style={{ margin: '10px 0' }}><Toggle on={s.autoArchiveAfterEnd} onChange={v => setS({ ...s, autoArchiveAfterEnd: v })} label="Auto-Archive After End Date" /></div>
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={bp} onClick={save}>💾 Save Settings</button>
        <button style={bs} onClick={toggleLock}>{s.isLocked ? '🔓 Unlock Batch' : '🔒 Lock Batch'}</button>
      </div>
      {s.renameHistory?.length > 0 && (
        <div style={{ ...cs, marginTop: 14 }}>
          <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>Rename History</div>
          {s.renameHistory.map((r: any, i: number) => <div key={i} style={{ fontSize: 11, color: DIM }}>{r.oldName} → {r.newName} ({new Date(r.changedAt).toLocaleDateString()})</div>)}
        </div>
      )}
    </div>
  )
}

// ── 15) AUDIT HISTORY TAB ──
function AuditTab({ base, authHeaders, id }: any) {
  const [audit, setAudit] = useState<any[]>([])
  useEffect(() => { fetch(base + '/' + id + '/audit', { headers: authHeaders }).then(r => r.json()).then(d => setAudit(d.audit || [])).catch(() => {}) }, [])
  return (
    <div style={cs}>
      {audit.length === 0 ? <EmptyMsg text="No audit records yet." /> : audit.map((a, i) => (
        <div key={i} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}`, fontSize: 11.5 }}>
          <div style={{ color: TS, fontWeight: 600 }}>{a.action} — {a.field}</div>
          <div style={{ color: DIM }}>Old: {JSON.stringify(a.oldValue)} → New: {JSON.stringify(a.newValue)}</div>
          <div style={{ color: DIM, fontSize: 10 }}>{a.changedByName} · {new Date(a.timestamp).toLocaleString()}</div>
        </div>
      ))}
    </div>
  )
}
PRVRNK_EOF_MARKER
echo "✅ Updated BatchManagerUltra.tsx with Banner Panel"
else echo "⚠️  BatchManagerUltra.tsx not found — run FPR1 frontend installer first. Skipping this update."; fi

# ── 2) Overwrite TestSeriesManagerUltra.tsx (adds Banner Panel — requires FPR2 already installed) ──
if [ -f "$ADMIN_DIR/TestSeriesManagerUltra.tsx" ]; then
cat > "$ADMIN_DIR/TestSeriesManagerUltra.tsx" << 'PRVRNK_EOF_MARKER'
'use client'
// ══════════════════════════════════════════════════════════════════
// FPR2 — TEST SERIES MANAGEMENT ULTRA SaaS UPGRADE (Admin) — Frontend
// Home (cards + smart search/filter + create) + Detail (10 tabs)
// Add Student by ID + Email · Pricing · Controls · Materials
// Analytics · Announcements · Settings · Audit History · Templates
// Desktop + Mobile responsive · Admin theme matched
// ══════════════════════════════════════════════════════════════════
import { useState, useEffect, useCallback, useRef } from 'react'

// ── Theme (matches global admin panel theme) ─────────────────────
const CRD  = 'rgba(0,28,52,0.88)'
const CRD2 = 'rgba(0,36,65,0.92)'
const ACC  = '#4D9FFF'
const BOR  = 'rgba(77,159,255,0.18)'
const BOR2 = 'rgba(77,159,255,0.3)'
const TS   = '#E8F4FF'
const DIM  = '#6B8FAF'
const GOOD = '#34D399'
const WARN = '#FBBF24'
const BAD  = '#F87171'

const cs: any = { background: CRD, border: `1px solid ${BOR}`, borderRadius: 14, padding: 18, marginBottom: 14, backdropFilter: 'blur(12px)' }
const inp: any = { width: '100%', padding: '10px 12px', background: 'rgba(0,22,40,0.85)', border: `1.5px solid ${BOR2}`, borderRadius: 10, color: TS, fontSize: 13, fontFamily: 'Inter,sans-serif', outline: 'none', boxSizing: 'border-box' }
const bp: any = { background: `linear-gradient(135deg,${ACC},#0055CC)`, color: '#fff', border: 'none', borderRadius: 10, padding: '10px 18px', cursor: 'pointer', fontWeight: 700, fontSize: 13, fontFamily: 'Inter,sans-serif', boxShadow: '0 4px 16px rgba(77,159,255,0.35)' }
const bs: any = { background: 'rgba(77,159,255,0.1)', color: ACC, border: `1px solid ${BOR2}`, borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const bd: any = { background: 'rgba(239,68,68,0.1)', color: BAD, border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const lbl: any = { display: 'block', fontSize: 10.5, color: DIM, marginBottom: 5, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }
const pageTitle: any = { fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TS, margin: '0 0 4px', background: `linear-gradient(90deg,${ACC},#fff)`, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }
const pageSub: any = { fontSize: 12, color: DIM, marginBottom: 18 }
const chip = (color: string, bg: string): any => ({ fontSize: 10.5, color, background: bg, padding: '3px 10px', borderRadius: 20, fontWeight: 600, display: 'inline-block' })

function useIsMobile() {
  const [m, setM] = useState(false)
  useEffect(() => {
    const chk = () => setM(window.innerWidth < 768)
    chk(); window.addEventListener('resize', chk)
    return () => window.removeEventListener('resize', chk)
  }, [])
  return m
}

function Toggle({ on, onChange, label }: { on: boolean; onChange: (v: boolean) => void; label?: string }) {
  return (
    <div onClick={() => onChange(!on)} style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
      <div style={{ width: 38, height: 20, borderRadius: 20, background: on ? ACC : 'rgba(107,143,175,0.3)', position: 'relative', transition: 'all .2s' }}>
        <div style={{ width: 16, height: 16, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: on ? 20 : 2, transition: 'all .2s' }} />
      </div>
      {label && <span style={{ fontSize: 12, color: TS }}>{label}</span>}
    </div>
  )
}

function Modal({ children, onClose, width = 560 }: { children: any; onClose: () => void; width?: number }) {
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: 14 }}>
      <div onClick={e => e.stopPropagation()} style={{ background: `linear-gradient(135deg,${CRD2},${CRD})`, border: `1.5px solid ${BOR2}`, borderRadius: 18, padding: 22, maxWidth: width, width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
        {children}
      </div>
    </div>
  )
}

function EmptyMsg({ text }: { text: string }) {
  return <div style={{ textAlign: 'center', padding: '30px 10px', color: DIM, fontSize: 12.5 }}>{text}</div>
}

// ══════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ══════════════════════════════════════════════════════════════════
export default function TestSeriesManagerUltra({ token, API }: { token: string; API: string }) {
  const isMobile = useIsMobile()
  const [series, setSeriesList] = useState<any[]>([])
  const [summary, setSummary] = useState<any>({})
  const [loading, setLoading] = useState(false)
  const [q, setQ] = useState('')
  const [filters, setFilters] = useState<any>({})
  const [showFilters, setShowFilters] = useState(false)
  const [sort, setSort] = useState('newest')
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  const [detailId, setDetailId] = useState<string | null>(() => {
    try { return typeof window !== 'undefined' ? localStorage.getItem('pr_tsm_detailId') : null } catch (e) { return null }
  })
  const [showCreate, setShowCreate] = useState(false)
  const [presets, setPresets] = useState<any[]>([])
  const [toast, setToast] = useState('')

  const authHeaders = { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' }
  const base = API + '/api/admin/test-series-manager'

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3500) }

  const loadSeries = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (q) params.set('q', q)
      Object.entries(filters).forEach(([k, v]: any) => { if (v !== undefined && v !== '' && v !== null) params.set(k, String(v)) })
      if (sort) params.set('sort', sort)
      const r = await fetch(base + '?' + params.toString(), { headers: authHeaders })
      const d = await r.json()
      setSeriesList(d.series || [])
      setSummary(d.summary || {})
    } catch (e) { showToast('⚠️ Failed to load series') }
    setLoading(false)
  }, [q, filters, sort])

  useEffect(() => { loadSeries() }, [loadSeries])

  useEffect(() => {
    try {
      if (detailId) localStorage.setItem('pr_tsm_detailId', detailId)
      else localStorage.removeItem('pr_tsm_detailId')
    } catch (e) { /* localStorage unavailable */ }
  }, [detailId])

  useEffect(() => {
    fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json()).then(d => setPresets(d.presets || [])).catch(() => {})
  }, [])

  const savePreset = async () => {
    const name = window.prompt('Preset name?')
    if (!name) return
    await fetch(base + '/filter-presets', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name, filters }) })
    const d = await fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json())
    setPresets(d.presets || [])
    showToast('✅ Filter preset saved')
  }

  const toggleSelect = (id: string) => setSelectedIds(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  const bulkAction = async (action: 'archive' | 'delete') => {
    if (selectedIds.length === 0) return
    if (action === 'delete' && !window.confirm(`Delete ${selectedIds.length} selected series(es)? This cannot be undone.`)) return
    for (const id of selectedIds) {
      await fetch(base + '/' + id + (action === 'archive' ? '/archive' : ''), { method: action === 'archive' ? 'PUT' : 'DELETE', headers: authHeaders })
    }
    showToast(action === 'archive' ? '✅ Test series archived/unarchived' : '✅ Test series deleted')
    setSelectedIds([])
    loadSeries()
  }

  const duplicateSeries = async (id: string) => {
    const r = await fetch(base + '/' + id + '/duplicate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Series duplicated'); loadSeries() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  const archiveSeries = async (id: string) => {
    const r = await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Status: ' + d.lifecycleStatus); loadSeries() }
  }
  const deleteSeries = async (id: string, name: string) => {
    if (!window.confirm(`Delete series "${name}"? Students will be unassigned.`)) return
    const r = await fetch(base + '/' + id, { method: 'DELETE', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Series deleted'); loadSeries() }
  }

  if (detailId) {
    return <TestSeriesDetail id={detailId} base={base} authHeaders={authHeaders} onBack={() => { setDetailId(null); loadSeries() }} isMobile={isMobile} showToast={showToast} allSeries={series} />
  }

  return (
    <div>
      <div style={pageTitle}>📚 Test Series Management — Ultra SaaS</div>
      <div style={pageSub}>Complete lifecycle control — create, price, control, enroll, assign tests, analyze & archive series.</div>

      {toast && <div style={{ position: 'fixed', top: 16, right: 16, zIndex: 10000, background: CRD2, border: `1px solid ${BOR2}`, borderRadius: 10, padding: '10px 16px', color: TS, fontSize: 12.5, boxShadow: '0 8px 24px rgba(0,0,0,0.4)' }}>{toast}</div>}

      {/* ── Status Summary Strip ── */}
      <div style={{ display: 'grid', gridTemplateColumns: isMobile ? 'repeat(3,1fr)' : 'repeat(6,1fr)', gap: 8, marginBottom: 14 }}>
        {[
          ['Active', summary.active, GOOD], ['Paused', summary.paused, WARN], ['Archived', summary.archived, DIM],
          ['Draft', summary.draft, '#A78BFA'], ['Upcoming', summary.upcoming, ACC], ['Students', summary.totalStudents, '#7DD3FC']
        ].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, padding: 10, textAlign: 'center' }}>
            <div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v ?? 0}</div>
            <div style={{ fontSize: 9.5, color: DIM, textTransform: 'uppercase', letterSpacing: 0.5 }}>{l}</div>
          </div>
        ))}
      </div>

      {/* ── Smart Search + Filter Bar ── */}
      <div style={cs}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <input style={{ ...inp, flex: 1, minWidth: 160 }} placeholder="🔎 Search series, code, exam, student, faculty, email…" value={q} onChange={e => setQ(e.target.value)} />
          <button style={bs} onClick={() => setShowFilters(s => !s)}>🧰 Filters {showFilters ? '▲' : '▼'}</button>
          <select style={{ ...inp, width: 150 }} value={sort} onChange={e => setSort(e.target.value)}>
            <option value="newest">Newest</option><option value="oldest">Oldest</option>
            <option value="most_students">Most Students</option><option value="price_high">Highest Revenue</option>
            <option value="price_low">Lowest Price</option><option value="most_active">Most Active</option><option value="name">Name A-Z</option>
          </select>
          <button style={bp} onClick={() => setShowCreate(true)}>➕ Create Series</button>
        </div>
        {showFilters && (
          <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: isMobile ? '1fr 1fr' : 'repeat(4,1fr)', gap: 10 }}>
            <div><label style={lbl}>Status</label>
              <select style={inp} value={filters.status || ''} onChange={e => setFilters({ ...filters, status: e.target.value })}>
                <option value="">All</option><option value="draft">Draft</option><option value="active">Active</option>
                <option value="upcoming">Upcoming</option><option value="paused">Paused</option><option value="archived">Archived</option>
              </select>
            </div>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={filters.exam || ''} onChange={e => setFilters({ ...filters, exam: e.target.value })}>
                <option value="">All</option><option value="NEET">NEET</option><option value="JEE">JEE</option><option value="CUET">CUET</option>
                <option value="Class 11">Class 11</option><option value="Class 12">Class 12</option><option value="Foundation">Foundation</option><option value="Crash Course">Crash Course</option>
              </select>
            </div>
            <div><label style={lbl}>Price Min</label><input style={inp} type="number" value={filters.priceMin || ''} onChange={e => setFilters({ ...filters, priceMin: e.target.value })} /></div>
            <div><label style={lbl}>Price Max</label><input style={inp} type="number" value={filters.priceMax || ''} onChange={e => setFilters({ ...filters, priceMax: e.target.value })} /></div>
            <div><label style={lbl}>Students Min</label><input style={inp} type="number" value={filters.studentMin || ''} onChange={e => setFilters({ ...filters, studentMin: e.target.value })} /></div>
            <div><label style={lbl}>Students Max</label><input style={inp} type="number" value={filters.studentMax || ''} onChange={e => setFilters({ ...filters, studentMax: e.target.value })} /></div>
            <div><label style={lbl}>Date From</label><input style={inp} type="date" value={filters.dateFrom || ''} onChange={e => setFilters({ ...filters, dateFrom: e.target.value })} /></div>
            <div><label style={lbl}>Date To</label><input style={inp} type="date" value={filters.dateTo || ''} onChange={e => setFilters({ ...filters, dateTo: e.target.value })} /></div>
            {['spotlight', 'trial', 'bundle', 'emi', 'flashsale'].map(f => (
              <div key={f} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Toggle on={filters[f] === 'true'} onChange={v => setFilters({ ...filters, [f]: v ? 'true' : '' })} label={f[0].toUpperCase() + f.slice(1)} />
              </div>
            ))}
            <div style={{ display: 'flex', gap: 8, gridColumn: isMobile ? 'span 2' : 'span 2' }}>
              <button style={bs} onClick={savePreset}>💾 Save Preset</button>
              <button style={bd} onClick={() => setFilters({})}>✕ Clear All</button>
            </div>
          </div>
        )}
        {presets.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {presets.map(p => <span key={p._id} onClick={() => setFilters(p.filters || {})} style={{ ...chip(ACC, 'rgba(77,159,255,0.12)'), cursor: 'pointer' }}>⭐ {p.name}</span>)}
          </div>
        )}
      </div>

      {/* ── Bulk Actions ── */}
      {selectedIds.length > 0 && (
        <div style={{ ...cs, display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 12.5, color: TS }}>{selectedIds.length} selected</span>
          <button style={bs} onClick={() => bulkAction('archive')}>📦 Archive/Unarchive</button>
          <button style={bd} onClick={() => bulkAction('delete')}>🗑️ Delete Selected</button>
          <button style={bs} onClick={() => setSelectedIds([])}>✕ Clear Selection</button>
        </div>
      )}

      {/* ── Series Card Grid ── */}
      {loading ? <EmptyMsg text="⟳ Loading series…" /> : series.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '50px 20px', color: DIM }}>
          <div style={{ fontSize: 60, marginBottom: 10 }}>📚</div>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#93C5FD' }}>No Test Series Found</div>
          <div style={{ fontSize: 12, marginTop: 6 }}>Create your first series or adjust filters.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fit,minmax(280px,1fr))', gap: 12 }}>
          {series.map(b => (
            <div key={b._id} style={{ ...cs, marginBottom: 0, position: 'relative', borderLeft: `3px solid ${b.lifecycleStatus === 'archived' ? DIM : ACC}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <input type="checkbox" checked={selectedIds.includes(b._id)} onChange={() => toggleSelect(b._id)} style={{ marginTop: 2 }} />
                <span style={chip(b.lifecycleStatus === 'active' ? GOOD : b.lifecycleStatus === 'paused' ? WARN : b.lifecycleStatus === 'archived' ? DIM : '#A78BFA', 'rgba(255,255,255,0.06)')}>{b.lifecycleStatus || 'active'}</span>
              </div>
              <div onClick={() => setDetailId(b._id)} style={{ cursor: 'pointer', marginTop: 6 }}>
                <div style={{ fontWeight: 700, fontSize: 14.5, color: '#93C5FD' }}>{b.colorIcon || '📚'} {b.name}</div>
                <div style={{ fontSize: 10, color: DIM, fontFamily: 'monospace', marginTop: 2 }}>{b.seriesCode || '—'} · {b.examType}</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', margin: '8px 0' }}>
                  <span style={chip('#7DD3FC', 'rgba(59,130,246,0.12)')}>👥 {b.studentCount || 0}{b.seatLimit ? '/' + b.seatLimit : ''}</span>
                  <span style={chip('#6EE7B7', 'rgba(16,185,129,0.12)')}>📝 {b.testCount || 0} Tests</span>
                  <span style={chip('#FDE68A', 'rgba(251,191,36,0.12)')}>₹{b.effectivePrice ?? b.price ?? 0}</span>
                  <span style={chip(ACC, 'rgba(77,159,255,0.12)')}>💚 {b.healthScore ?? 0}</span>
                </div>
                <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                  {b.isSpotlight && <span style={chip('#FBBF24', 'rgba(251,191,36,0.1)')}>✨ Spotlight</span>}
                  {b.allowFreeTrial && <span style={chip(GOOD, 'rgba(52,211,153,0.1)')}>🆓 Trial</span>}
                  {b.isBundle && <span style={chip('#A78BFA', 'rgba(167,139,250,0.1)')}>📦 Bundle</span>}
                  {b.allowEMI && <span style={chip('#7DD3FC', 'rgba(125,211,252,0.1)')}>💳 EMI</span>}
                  {b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date() && <span style={chip(BAD, 'rgba(248,113,113,0.1)')}>⚡ Flash</span>}
                </div>
                <div style={{ fontSize: 9.5, color: 'rgba(148,163,184,0.5)', marginTop: 8 }}>Updated {b.updatedAt ? new Date(b.updatedAt).toLocaleDateString() : '-'}</div>
              </div>
              <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                <button style={bs} onClick={() => setDetailId(b._id)}>Open</button>
                <button style={bs} onClick={() => duplicateSeries(b._id)}>⧉ Duplicate</button>
                <button style={bs} onClick={() => archiveSeries(b._id)}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive'}</button>
                <button style={bd} onClick={() => deleteSeries(b._id, b.name)}>🗑️</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showCreate && <CreateSeriesWizard base={base} authHeaders={authHeaders} isMobile={isMobile} onClose={() => setShowCreate(false)} onCreated={() => { setShowCreate(false); loadSeries(); showToast('✅ Series created') }} />}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════
// CREATE TEST SERIES WIZARD (multi-step)
// ══════════════════════════════════════════════════════════════════
function CreateSeriesWizard({ base, authHeaders, isMobile, onClose, onCreated }: any) {
  const [step, setStep] = useState(1)
  const [templates, setTemplates] = useState<any[]>([])
  const [form, setForm] = useState<any>({
    name: '', seriesCode: '', examType: 'NEET', description: '', colorIcon: '📚',
    lifecycleStatus: 'draft', visibility: 'public', seatLimit: 0, enrollmentRule: 'open',
    price: 0, discountPrice: '', allowFreeTrial: false, trialDays: 3, isBundle: false,
    bundlePrice: '', allowEMI: false, isSpotlight: false, autoArchiveAfterEnd: false, templateId: ''
  })
  const [dupWarn, setDupWarn] = useState<any>(null)

  useEffect(() => { fetch(base + '/templates', { headers: authHeaders }).then(r => r.json()).then(d => setTemplates(d.templates || [])).catch(() => {}) }, [])

  const set = (k: string, v: any) => setForm((p: any) => ({ ...p, [k]: v }))

  const submit = async (confirmDuplicate = false) => {
    const r = await fetch(base, { method: 'POST', headers: authHeaders, body: JSON.stringify({ ...form, confirmDuplicate }) })
    const d = await r.json()
    if (d.warning === 'duplicate') { setDupWarn(d); return }
    if (d.success) onCreated()
    else alert(d.error || 'Failed to create series')
  }

  const steps = ['Basic Info', 'Lifecycle & Enrollment', 'Pricing Wizard', 'Default Controls', 'Preview & Confirm']

  return (
    <Modal onClose={onClose} width={640}>
      <div style={{ fontWeight: 800, fontSize: 17, color: ACC, marginBottom: 4 }}>➕ Create New Test Series</div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 16 }}>
        {steps.map((s, i) => <span key={s} style={{ ...chip(i + 1 === step ? '#fff' : DIM, i + 1 === step ? ACC : 'rgba(255,255,255,0.05)'), fontSize: 10 }}>{i + 1}. {s}</span>)}
      </div>

      {step === 1 && (
        <div>
          {templates.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <label style={lbl}>Series Template Picker (optional)</label>
              <select style={inp} value={form.templateId} onChange={e => set('templateId', e.target.value)}>
                <option value="">Start blank</option>
                {templates.map(t => <option key={t._id} value={t._id}>{t.name}</option>)}
              </select>
            </div>
          )}
          <label style={lbl}>Series Name *</label><input style={{ ...inp, marginBottom: 10 }} value={form.name} onChange={e => set('name', e.target.value)} placeholder="e.g. NEET Full Syllabus Test Series 2027" />
          <label style={lbl}>Series Code</label><input style={{ ...inp, marginBottom: 10 }} value={form.seriesCode} onChange={e => set('seriesCode', e.target.value)} placeholder="Auto-generated if left blank" />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={form.examType} onChange={e => set('examType', e.target.value)}>
                {['NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course', 'Other'].map(x => <option key={x}>{x}</option>)}
              </select>
            </div>
            <div><label style={lbl}>Cover Icon</label><input style={inp} value={form.colorIcon} onChange={e => set('colorIcon', e.target.value)} /></div>
          </div>
          <label style={{ ...lbl, marginTop: 10 }}>Description</label>
          <textarea style={{ ...inp, minHeight: 60 }} value={form.description} onChange={e => set('description', e.target.value)} />
        </div>
      )}

      {step === 2 && (
        <div>
          <label style={lbl}>Lifecycle Mode</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.lifecycleStatus} onChange={e => set('lifecycleStatus', e.target.value)}>
            {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
          </select>
          <label style={lbl}>Enrollment Rule Builder</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.enrollmentRule} onChange={e => set('enrollmentRule', e.target.value)}>
            <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option>
            <option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval by Criteria</option>
          </select>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Seat Limit (0 = unlimited)</label><input type="number" style={inp} value={form.seatLimit} onChange={e => set('seatLimit', e.target.value)} /></div>
            <div><label style={lbl}>Visibility</label>
              <select style={inp} value={form.visibility} onChange={e => set('visibility', e.target.value)}>
                <option value="public">Public</option><option value="private">Private</option><option value="invite_only">Invite Only</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {step === 3 && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Base Price ₹</label><input type="number" style={inp} value={form.price} onChange={e => set('price', e.target.value)} /></div>
            <div><label style={lbl}>Discount Price ₹</label><input type="number" style={inp} value={form.discountPrice} onChange={e => set('discountPrice', e.target.value)} /></div>
          </div>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <Toggle on={form.allowFreeTrial} onChange={v => set('allowFreeTrial', v)} label="Enable Free Trial" />
            {form.allowFreeTrial && <input type="number" style={inp} value={form.trialDays} onChange={e => set('trialDays', e.target.value)} placeholder="Trial days" />}
            <Toggle on={form.isBundle} onChange={v => set('isBundle', v)} label="Bundle Pricing" />
            {form.isBundle && <input type="number" style={inp} value={form.bundlePrice} onChange={e => set('bundlePrice', e.target.value)} placeholder="Bundle price" />}
            <Toggle on={form.allowEMI} onChange={v => set('allowEMI', v)} label="EMI Eligible" />
          </div>
        </div>
      )}

      {step === 4 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Toggle on={form.isSpotlight} onChange={v => set('isSpotlight', v)} label="✨ Spotlight (Featured)" />
          <Toggle on={form.autoArchiveAfterEnd} onChange={v => set('autoArchiveAfterEnd', v)} label="🗄️ Auto-Archive After End Date" />
        </div>
      )}

      {step === 5 && (
        <div>
          <div style={{ ...cs, marginBottom: 0 }}>
            <div style={{ fontWeight: 700, color: '#93C5FD', fontSize: 14 }}>{form.colorIcon} {form.name || '(Unnamed Series)'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.examType} · {form.lifecycleStatus} · Seat Limit: {form.seatLimit || 'Unlimited'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>Price: ₹{form.price} {form.discountPrice ? `(₹${form.discountPrice} discounted)` : ''}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.allowFreeTrial ? '🆓 Trial Enabled · ' : ''}{form.isBundle ? '📦 Bundle · ' : ''}{form.allowEMI ? '💳 EMI · ' : ''}{form.isSpotlight ? '✨ Spotlight' : ''}</div>
          </div>
          {dupWarn && (
            <div style={{ marginTop: 10, padding: 10, background: 'rgba(251,191,36,0.1)', border: '1px solid rgba(251,191,36,0.3)', borderRadius: 8, fontSize: 11.5, color: WARN }}>
              ⚠️ Similar series exists: "{dupWarn.existing?.name}" ({dupWarn.existing?.seriesCode}). Create anyway?
              <div style={{ marginTop: 8 }}><button style={bp} onClick={() => submit(true)}>Yes, Create Anyway</button></div>
            </div>
          )}
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 18 }}>
        <button style={bs} onClick={step === 1 ? onClose : () => setStep(step - 1)}>{step === 1 ? 'Cancel' : '← Back'}</button>
        {step < 5 ? <button style={bp} onClick={() => setStep(step + 1)}>Next →</button> : <button style={bp} onClick={() => submit(false)}>✅ Publish Series</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// ADD / TRANSFER STUDENT MODAL — dual ID/Email selector
// ══════════════════════════════════════════════════════════════════
function StudentAddModal({ base, authHeaders, seriesId, onClose, onDone, showToast }: any) {
  const [inputType, setInputType] = useState<'id' | 'email'>('id')
  const [val, setVal] = useState('')
  const [suggestions, setSuggestions] = useState<any[]>([])
  const [matched, setMatched] = useState<any>(null)
  const [beforeAfter, setBeforeAfter] = useState<any>(null)

  useEffect(() => {
    if (!val || val.length < 2) { setSuggestions([]); return }
    const t = setTimeout(() => {
      fetch(base + '/student-lookup?query=' + encodeURIComponent(val), { headers: authHeaders }).then(r => r.json()).then(d => setSuggestions(d.matches || [])).catch(() => {})
    }, 300)
    return () => clearTimeout(t)
  }, [val])

  const confirm = async () => {
    const payload: any = inputType === 'id' ? { studentId: matched ? matched.studentId || matched._id : val } : { email: matched ? matched.email : val }
    const r = await fetch(base + '/' + seriesId + '/students/add', { method: 'POST', headers: authHeaders, body: JSON.stringify(payload) })
    const d = await r.json()
    if (d.success) { setBeforeAfter(d); showToast('✅ Student added to test series') }
    else showToast('⚠️ ' + (d.error || 'Failed'))
  }

  return (
    <Modal onClose={onClose} width={480}>
      <div style={{ fontWeight: 800, fontSize: 16, color: ACC, marginBottom: 12 }}>➕ Add Student to Test Series</div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
        <button style={inputType === 'id' ? bp : bs} onClick={() => setInputType('id')}>🆔 By Student ID</button>
        <button style={inputType === 'email' ? bp : bs} onClick={() => setInputType('email')}>📧 By Registered Email</button>
      </div>
      <input style={inp} value={val} onChange={e => { setVal(e.target.value); setMatched(null) }} placeholder={inputType === 'id' ? 'Enter Student ID (PRxxABCD)…' : 'Enter registered email…'} />
      {suggestions.length > 0 && !matched && (
        <div style={{ marginTop: 6, border: `1px solid ${BOR}`, borderRadius: 8, overflow: 'hidden' }}>
          {suggestions.map(s => (
            <div key={s._id} onClick={() => { setMatched(s); setVal(inputType === 'id' ? (s.studentId || s._id) : s.email) }} style={{ padding: '8px 10px', cursor: 'pointer', fontSize: 12, borderBottom: `1px solid ${BOR}`, color: TS }}>
              {s.name} — {s.email} {s.studentId ? `(${s.studentId})` : ''}
            </div>
          ))}
        </div>
      )}
      {matched && <div style={{ marginTop: 8, fontSize: 12, color: GOOD }}>✅ Matched: {matched.name} ({matched.email})</div>}

      {beforeAfter && (
        <div style={{ marginTop: 12, padding: 10, background: 'rgba(52,211,153,0.08)', border: '1px solid rgba(52,211,153,0.25)', borderRadius: 8, fontSize: 12, color: GOOD }}>
          Before: {beforeAfter.before?.count} students → After: {beforeAfter.after?.count} students
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 16 }}>
        <button style={bs} onClick={onClose}>Close</button>
        {!beforeAfter ? <button style={bp} onClick={confirm}>Confirm</button> : <button style={bp} onClick={() => { onDone(); onClose() }}>Done</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// TEST SERIES DETAIL PAGE — 10 Tabs
// ══════════════════════════════════════════════════════════════════
function TestSeriesDetail({ id, base, authHeaders, onBack, isMobile, showToast, allSeries }: any) {
  const [tab, setTab] = useState('overview')
  const [detail, setDetail] = useState<any>(null)
  const [notFound, setNotFound] = useState(false)
  const [modal, setModal] = useState<'' | 'add'>('')

  const load = useCallback(() => {
    fetch(base + '/' + id, { headers: authHeaders })
      .then(r => { if (!r.ok) throw new Error('not-found'); return r.json() })
      .then(d => { if (d.error) throw new Error(d.error); setDetail(d) })
      .catch(() => setNotFound(true))
  }, [id])
  useEffect(() => { load() }, [load])

  if (notFound) {
    return (
      <div style={{ textAlign: 'center', padding: '50px 20px' }}>
        <div style={{ fontSize: 40, marginBottom: 10 }}>⚠️</div>
        <div style={{ color: '#F87171', fontWeight: 700, marginBottom: 10 }}>This series could not be found. It may have been deleted.</div>
        <button style={bp} onClick={onBack}>← Back to Test Series Management</button>
      </div>
    )
  }

  const tabs = [
    ['overview', '📊 Overview'], ['students', '👥 Students'], ['tests', '📝 Tests'], ['pricing', '💰 Pricing'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],
    ['announcements', '📢 Announcements'], ['settings', '🔧 Settings'], ['audit', '🕐 Audit History']
  ]

  if (!detail) return <EmptyMsg text="⟳ Loading series details…" />
  const b = detail.series || {}

  return (
    <div>
      <button style={{ ...bs, marginBottom: 10 }} onClick={onBack}>← Back to Test Series Management</button>

      <div style={{ ...cs, background: `linear-gradient(135deg,${CRD2},${CRD})` }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
          <div>
            <div style={{ fontWeight: 800, fontSize: 19, color: '#93C5FD' }}>{b.colorIcon || '📚'} {b.name}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{b.seriesCode} · {b.examType} · {b.lifecycleStatus}</div>
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: ACC }}>{b.healthScore}</div><div style={{ fontSize: 9, color: DIM }}>HEALTH SCORE</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#7DD3FC' }}>{b.studentCount}</div><div style={{ fontSize: 9, color: DIM }}>STUDENTS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#6EE7B7' }}>{b.testCount}</div><div style={{ fontSize: 9, color: DIM }}>TESTS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#FDE68A' }}>₹{b.effectivePrice}</div><div style={{ fontSize: 9, color: DIM }}>PRICE</div></div>
          </div>
        </div>
        {detail.alerts?.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {detail.alerts.map((a: any, i: number) => <span key={i} style={chip(a.type === 'warning' ? WARN : ACC, 'rgba(255,255,255,0.05)')}>⚠️ {a.message}</span>)}
          </div>
        )}
      </div>

      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14, overflowX: isMobile ? 'auto' : 'visible' }}>
        {tabs.map(([k, l]) => <button key={k} onClick={() => setTab(k)} style={tab === k ? bp : bs}>{l}</button>)}
      </div>

      {tab === 'overview' && <OverviewTab detail={detail} base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} load={load} />}
      {tab === 'students' && <StudentsTab base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} />}
      {tab === 'tests' && <TestsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'controls' && <ControlsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'materials' && <MaterialsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'analytics' && <AnalyticsTab base={base} authHeaders={authHeaders} id={id} allSeries={allSeries} />}
      {tab === 'announcements' && <AnnouncementsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'settings' && <SettingsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'audit' && <AuditTab base={base} authHeaders={authHeaders} id={id} />}

      {modal === 'add' && <StudentAddModal base={base} authHeaders={authHeaders} seriesId={id} onClose={() => setModal('')} onDone={load} showToast={showToast} />}
    </div>
  )
}

// ── 6) OVERVIEW TAB ──
function OverviewTab({ detail, base, authHeaders, id, setModal, showToast, load }: any) {
  const b = detail.series
  const exportSnapshot = () => window.open(base + '/' + id + '/export-snapshot')
  const archiveToggle = async () => { await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders }); showToast('✅ Status updated'); load() }
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(200px,1fr))', gap: 12 }}>
        <div style={cs}><div style={lbl}>Seat Utilization</div><div style={{ fontSize: 22, fontWeight: 800, color: ACC }}>{b.seatUtilPct ?? '∞'}{b.seatUtilPct !== null ? '%' : ''}</div></div>
        <div style={cs}><div style={lbl}>Engagement Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: GOOD }}>{b.engagementMeter}%</div></div>
        <div style={cs}><div style={lbl}>Revenue Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: '#FDE68A' }}>{b.revenueMeter}%</div></div>
        <div style={cs}><div style={lbl}>Faculty</div><div style={{ fontSize: 15, fontWeight: 700, color: TS }}>{b.teacherAssigned || '—'}</div></div>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '14px 0' }}>
        <button style={bp} onClick={() => setModal('add')}>➕ Add Student</button>
        <button style={bs} onClick={archiveToggle}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive Series'}</button>
        <button style={bs} onClick={exportSnapshot}>📤 Export Snapshot</button>
      </div>
      <BannerPanel base={base} authHeaders={authHeaders} id={id} linkedType="series" showToast={showToast} />
      <div style={cs}>
        <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 8, color: TS }}>Recent Activity</div>
        {(detail.recentActivity || []).length === 0 ? <EmptyMsg text="No recent activity yet." /> :
          detail.recentActivity.map((a: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              <b style={{ color: TS }}>{a.action}</b> — {a.field} {a.changedByName ? 'by ' + a.changedByName : ''} · {new Date(a.timestamp).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── FPR3: Banner Panel (Publish Gate integration) ──
function BannerPanel({ base, authHeaders, id, linkedType, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/banner-panel', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const regenerate = async () => {
    const r = await fetch(base + '/' + id + '/banner-panel/regenerate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Banner draft generated'); load() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  if (!data) return null
  const banner = data.banner
  const gate = data.gate || {}
  const openBannerManagement = () => window.open(`/admin/x7k2p/banner-generator?${linkedType === 'batch' ? 'batchId' : 'seriesId'}=${id}&${linkedType === 'batch' ? 'batchName' : 'seriesName'}=${encodeURIComponent(banner?.title || '')}`, '_blank')
  return (
    <div style={{ ...cs, border: `1px solid ${gate.ready ? 'rgba(52,211,153,0.35)' : 'rgba(248,113,113,0.35)'}` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: TS }}>🖼️ Banner Panel</div>
        <span style={{ fontSize: 10.5, fontWeight: 700, color: gate.ready ? GOOD : BAD }}>{gate.ready ? '✅ Launch Allowed' : '⛔ Launch Blocked'}</span>
      </div>
      {banner ? (
        <>
          <div style={{ fontSize: 12, color: DIM, marginBottom: 8 }}>{banner.title} · Status: {banner.status} · Quality: {banner.qualityScore || 0}/100</div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <button style={bs} onClick={openBannerManagement}>✏️ Edit Banner</button>
            <button style={bs} onClick={regenerate}>🔄 Regenerate Draft</button>
          </div>
        </>
      ) : (
        <>
          <div style={{ fontSize: 12, color: BAD, marginBottom: 8 }}>{gate.reason || 'No banner created yet for this test series.'}</div>
          <button style={bp} onClick={regenerate}>➕ Auto-Generate Banner Draft</button>
        </>
      )}
    </div>
  )
}

// ── 7) STUDENTS TAB ──
function StudentsTab({ base, authHeaders, id, setModal, showToast }: any) {
  const [students, setStudents] = useState<any[]>([])
  const [q, setQ] = useState(''); const [status, setStatus] = useState(''); const [sort, setSort] = useState('')
  const load = useCallback(() => {
    const params = new URLSearchParams(); if (q) params.set('q', q); if (status) params.set('status', status); if (sort) params.set('sort', sort)
    fetch(base + '/' + id + '/students?' + params.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setStudents(d.students || [])).catch(() => {})
  }, [q, status, sort])
  useEffect(() => { load() }, [load])

  const remove = async (sid: string) => { if (!window.confirm('Remove student from series?')) return; await fetch(base + '/' + id + '/students/' + sid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Removed'); load() }
  const setInactive = async (sid: string, s: string) => { await fetch(base + '/' + id + '/students/' + sid + '/status', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ status: s }) }); load() }
  const exportCsv = () => window.open(base + '/' + id + '/students/export')

  return (
    <div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
        <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder="Search student…" value={q} onChange={e => setQ(e.target.value)} />
        <select style={{ ...inp, width: 130 }} value={status} onChange={e => setStatus(e.target.value)}><option value="">All Status</option><option value="active">Active</option><option value="inactive">Inactive</option></select>
        <select style={{ ...inp, width: 130 }} value={sort} onChange={e => setSort(e.target.value)}><option value="">Newest</option><option value="oldest">Oldest</option><option value="name">Name</option></select>
        <button style={bp} onClick={() => setModal('add')}>➕ Add</button>
        <button style={bs} onClick={exportCsv}>⬇️ Export CSV</button>
      </div>
      {students.length === 0 ? <EmptyMsg text="No students in this series yet." /> : (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
            <thead><tr style={{ color: DIM, textAlign: 'left' }}><th style={{ padding: 6 }}>Name</th><th>ID</th><th>Email</th><th>Status</th><th>Joined</th><th>Action</th></tr></thead>
            <tbody>
              {students.map(s => (
                <tr key={s._id} style={{ borderTop: `1px solid ${BOR}` }}>
                  <td style={{ padding: 6, color: TS }}>{s.name}</td><td style={{ color: DIM }}>{s.studentId}</td><td style={{ color: DIM }}>{s.email}</td>
                  <td><span style={chip(s.status === 'active' ? GOOD : DIM, 'rgba(255,255,255,0.05)')}>{s.status}</span></td>
                  <td style={{ color: DIM }}>{s.joinedDate ? new Date(s.joinedDate).toLocaleDateString() : '-'}</td>
                  <td>
                    <button style={{ ...bs, padding: '3px 8px', marginRight: 4 }} onClick={() => setInactive(s._id, s.status === 'active' ? 'inactive' : 'active')}>{s.status === 'active' ? 'Mark Inactive' : 'Mark Active'}</button>
                    <button style={{ ...bd, padding: '3px 8px' }} onClick={() => remove(s._id)}>Remove</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ── 8) TESTS TAB ──
function TestsTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>({ assigned: [], available: [] })
  const load = useCallback(() => fetch(base + '/' + id + '/tests', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const assign = async (testId: string) => { await fetch(base + '/' + id + '/tests/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ testId }) }); showToast('✅ Test assigned'); load() }
  const unassign = async (testId: string) => { await fetch(base + '/' + id + '/tests/' + testId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Test removed'); load() }
  const updateFlag = async (testId: string, field: string, val: boolean) => { await fetch(base + '/' + id + '/tests/' + testId, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ [field]: val }) }); load() }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Tests ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No tests assigned yet." /> : data.assigned.map((e: any) => (
          <div key={e._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 6 }}>
              <span style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{e.title || e.name}</span>
              <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
            </div>
            <div style={{ display: 'flex', gap: 10, marginTop: 6, flexWrap: 'wrap' }}>
              {['required', 'locked', 'featured', 'hidden'].map(f => (
                <Toggle key={f} on={!!e.control?.[f]} onChange={v => updateFlag(e._id, f, v)} label={f} />
              ))}
            </div>
          </div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Available Tests</div>
        {(!data.available || data.available.length === 0) ? <EmptyMsg text="No more tests available." /> : data.available.map((e: any) => (
          <div key={e._id} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
            <span style={{ color: DIM, fontSize: 12 }}>{e.title || e.name}</span>
            <button style={{ ...bs, padding: '3px 10px' }} onClick={() => assign(e._id)}>+ Assign</button>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 9) PRICING TAB ──
function PricingTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const [form, setForm] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/pricing', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  useEffect(() => { if (data?.pricing) setForm(data.pricing) }, [data])
  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const save = async () => { const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }); const d = await r.json(); if (d.success) { showToast('✅ Pricing updated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleLock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        <button style={bs} onClick={toggleLock}>{p.priceLocked ? 'Unlock' : 'Lock'} Price</button>
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Bundle Price ₹</label><input style={inp} type="number" value={form.bundlePrice || ''} onChange={e => setForm({ ...form, bundlePrice: e.target.value })} /></div>
        <div><label style={lbl}>Early Bird Price ₹</label><input style={inp} type="number" value={form.earlyBirdPrice || ''} onChange={e => setForm({ ...form, earlyBirdPrice: e.target.value })} /></div>
        <div><label style={lbl}>Limited Time Price ₹</label><input style={inp} type="number" value={form.limitedTimePrice || ''} onChange={e => setForm({ ...form, limitedTimePrice: e.target.value })} /></div>
        <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.couponCode || ''} onChange={e => setForm({ ...form, couponCode: e.target.value })} /></div>
      </div>
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '4px 0 14px' }}>
        <Toggle on={!!form.allowFreeTrial} onChange={v => setForm({ ...form, allowFreeTrial: v })} label="Free Trial" />
        <Toggle on={!!form.allowEMI} onChange={v => setForm({ ...form, allowEMI: v })} label="EMI" />
      </div>
      <button style={bp} onClick={save}>💾 Save Pricing</button>

      <div style={{ ...cs, marginTop: 16 }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>💡 Revenue Forecast</div>
        <div style={{ fontSize: 12, color: DIM }}>Expected Income: ₹{Math.round(data.forecast?.expectedIncome || 0)} · Conversion Estimate: {data.forecast?.conversionEstimate}% · Offer Performance: {data.forecast?.offerPerformance}</div>
      </div>

      <div style={{ ...cs }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>📜 Price History Timeline</div>
        {(!data.history || data.history.length === 0) ? <EmptyMsg text="No price changes yet." /> :
          data.history.slice().reverse().map((h: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              {h.field}: ₹{h.oldPrice} → ₹{h.newPrice} by {h.updatedByName} · {new Date(h.updatedAt).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/controls', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!data) return <EmptyMsg text="⟳ Loading controls…" />
  const c = data.controls
  const update = async (patch: any) => { await fetch(base + '/' + id + '/controls', { method: 'PUT', headers: authHeaders, body: JSON.stringify(patch) }); showToast('✅ Control updated'); load(); loadParent && loadParent() }
  const pause = async () => { await fetch(base + '/' + id + '/controls/pause', { method: 'PUT', headers: authHeaders }); showToast('✅ Pause toggled'); load(); loadParent && loadParent() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 14 }}>
        <Toggle on={c.isSpotlight} onChange={v => update({ isSpotlight: v })} label="✨ Spotlight" />
        <Toggle on={c.isBundle} onChange={v => update({ isBundle: v })} label="📦 Bundle" />
        <Toggle on={c.allowFreeTrial} onChange={v => update({ allowFreeTrial: v })} label="🆓 Free Trial" />
        <Toggle on={c.allowEMI} onChange={v => update({ allowEMI: v })} label="💳 EMI" />
      </div>
      <div style={cs}>
        <label style={lbl}>Series Status Manager</label>
        <select style={inp} value={c.lifecycleStatus} onChange={e => update({ lifecycleStatus: e.target.value })}>
          {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Enrollment Lock / Access Policy</label>
        <select style={{ ...inp, marginBottom: 8 }} value={c.enrollmentRule} onChange={e => update({ enrollmentRule: e.target.value })}>
          <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval</option>
        </select>
        <select style={inp} value={c.accessPolicy} onChange={e => update({ accessPolicy: e.target.value })}>
          <option value="open">Open Access</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="code_based">Code-Based Join</option>
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Seat Limit</label>
        <input style={inp} type="number" value={c.seatLimit} onChange={e => update({ seatLimit: e.target.value })} />
      </div>
      <button style={bd} onClick={pause}>{c.lifecycleStatus === 'paused' ? '▶️ Resume Series (One-Click)' : '⏸️ One-Click Pause'}</button>
      {data.snapshot && <div style={{ fontSize: 11, color: DIM, marginTop: 10 }}>Last applied by {data.snapshot.appliedBy} at {new Date(data.snapshot.appliedAt).toLocaleString()}</div>}
    </div>
  )
}

// ── 11) MATERIALS TAB ──
function MaterialsTab({ base, authHeaders, id, showToast }: any) {
  const [materials, setMaterials] = useState<any[]>([])
  const [form, setForm] = useState<any>({ title: '', type: 'pdf', url: '', category: 'General' })
  const load = useCallback(() => fetch(base + '/' + id + '/materials', { headers: authHeaders }).then(r => r.json()).then(d => setMaterials(d.materials || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const add = async () => { if (!form.title) return showToast('⚠️ Title required'); await fetch(base + '/' + id + '/materials', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) }); showToast('✅ Material added'); setForm({ title: '', type: 'pdf', url: '', category: 'General' }); load() }
  const pin = async (mid: string, pinned: boolean) => { await fetch(base + '/' + id + '/materials/' + mid, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ pinned: !pinned }) }); load() }
  const del = async (mid: string) => { if (!window.confirm('Delete material?')) return; await fetch(base + '/' + id + '/materials/' + mid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Deleted'); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8 }}>
        <input style={inp} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <select style={inp} value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>{['pdf', 'video', 'doc', 'link', 'image', 'other'].map(x => <option key={x}>{x}</option>)}</select>
        <input style={inp} placeholder="URL" value={form.url} onChange={e => setForm({ ...form, url: e.target.value })} />
        <input style={inp} placeholder="Category" value={form.category} onChange={e => setForm({ ...form, category: e.target.value })} />
        <button style={bp} onClick={add}>⬆️ Upload</button>
      </div>
      {materials.length === 0 ? <EmptyMsg text="No materials uploaded yet." /> : materials.map(m => (
        <div key={m._id} style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{m.pinned ? '📌 ' : ''}{m.title} <span style={{ fontSize: 10, color: DIM }}>v{m.version}</span></div>
            <div style={{ fontSize: 10, color: DIM }}>{m.type} · {m.subject} {m.expiryDate ? '· expires ' + new Date(m.expiryDate).toLocaleDateString() : ''}</div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={bs} onClick={() => pin(m._id, m.pinned)}>{m.pinned ? 'Unpin' : 'Pin'}</button>
            <button style={bd} onClick={() => del(m._id)}>Delete</button>
          </div>
        </div>
      ))}
    </div>
  )
}

// ── 12) ANALYTICS TAB ──
function AnalyticsTab({ base, authHeaders, id, allSeries }: any) {
  const [data, setData] = useState<any>(null)
  const [compareWith, setCompareWith] = useState('')
  const [cmp, setCmp] = useState<any>(null)
  useEffect(() => { fetch(base + '/' + id + '/analytics', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}) }, [])
  const runCompare = async () => { if (!compareWith) return; const d = await fetch(base + '/' + id + '/analytics/compare?withId=' + compareWith, { headers: authHeaders }).then(r => r.json()); setCmp(d) }
  if (!data) return <EmptyMsg text="⟳ Loading analytics…" />
  const a = data.analytics
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(150px,1fr))', gap: 10 }}>
        {[['Health Score', a.healthScore, ACC], ['Active Users', a.activeUsers, '#7DD3FC'], ['Test Participation', a.testParticipation, '#6EE7B7'],
        ['Avg Score', a.avgScore ?? '—', '#FDE68A'], ['Revenue', '₹' + a.revenueSummary, GOOD], ['Seat Util %', a.seatUtilization ?? '∞', WARN],
        ['Engagement Trend', a.engagementTrend + '%', ACC], ['Revenue/Seat', '₹' + a.revenuePerSeat, '#A78BFA'], ['Churn Trend', a.churnTrend, BAD]].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v}</div><div style={{ fontSize: 9.5, color: DIM }}>{l}</div></div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>🔻 Conversion Funnel</div>
        <div style={{ fontSize: 12, color: DIM }}>Views: {a.conversionFunnel?.views} → Wishlisted: {a.conversionFunnel?.wishlisted} → Enrolled: {a.conversionFunnel?.enrolled}</div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>⚖️ Series Comparison</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <select style={inp} value={compareWith} onChange={e => setCompareWith(e.target.value)}>
            <option value="">Select series to compare…</option>
            {(allSeries || []).filter((b: any) => b._id !== id).map((b: any) => <option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
          <button style={bs} onClick={runCompare}>Compare</button>
        </div>
        {cmp && <div style={{ fontSize: 12, color: DIM, marginTop: 8 }}>{cmp.a?.name}: {cmp.a?.studentCount} students, ₹{cmp.a?.revenue} vs {cmp.b?.name}: {cmp.b?.studentCount} students, ₹{cmp.b?.revenue}</div>}
      </div>
    </div>
  )
}

// ── 13) ANNOUNCEMENTS TAB ──
function AnnouncementsTab({ base, authHeaders, id, showToast }: any) {
  const [list, setList] = useState<any[]>([])
  const [form, setForm] = useState({ title: '', message: '', urgent: false, scheduledAt: '' })
  const load = useCallback(() => fetch(base + '/' + id + '/announcements', { headers: authHeaders }).then(r => r.json()).then(d => setList(d.announcements || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const send = async () => {
    if (!form.message) return showToast('⚠️ Message required')
    const r = await fetch(base + '/' + id + '/announcements', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) })
    const d = await r.json()
    showToast(`✅ Sent to ${d.notified || 0} students`)
    setForm({ title: '', message: '', urgent: false, scheduledAt: '' }); load()
  }
  return (
    <div>
      <div style={cs}>
        <input style={{ ...inp, marginBottom: 8 }} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <textarea style={{ ...inp, minHeight: 70, marginBottom: 8 }} placeholder="Message" value={form.message} onChange={e => setForm({ ...form, message: e.target.value })} />
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
          <Toggle on={form.urgent} onChange={v => setForm({ ...form, urgent: v })} label="🚨 Urgent" />
          <input style={{ ...inp, width: 200 }} type="datetime-local" value={form.scheduledAt} onChange={e => setForm({ ...form, scheduledAt: e.target.value })} />
          <button style={bp} onClick={send}>📢 Send / Schedule</button>
        </div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>History</div>
        {list.length === 0 ? <EmptyMsg text="No announcements sent yet." /> : list.map((a: any) => (
          <div key={a._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{a.urgent ? '🚨 ' : ''}{a.title}</div>
            <div style={{ color: DIM, fontSize: 11 }}>{a.message}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 14) SETTINGS TAB ──
function SettingsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [s, setS] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/settings', { headers: authHeaders }).then(r => r.json()).then(d => setS(d.settings)).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!s) return <EmptyMsg text="⟳ Loading settings…" />
  const save = async () => { await fetch(base + '/' + id, { method: 'PUT', headers: authHeaders, body: JSON.stringify(s) }); showToast('✅ Settings saved'); load(); loadParent && loadParent() }
  const toggleLock = async () => { await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders }); load() }
  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Series Name</label><input style={inp} value={s.name} onChange={e => setS({ ...s, name: e.target.value })} /></div>
        <div><label style={lbl}>Color / Icon</label><input style={inp} value={s.colorIcon} onChange={e => setS({ ...s, colorIcon: e.target.value })} /></div>
        <div><label style={lbl}>Start Date</label><input style={inp} type="date" value={s.startDate ? s.startDate.slice(0, 10) : ''} onChange={e => setS({ ...s, startDate: e.target.value })} /></div>
        <div><label style={lbl}>End Date</label><input style={inp} type="date" value={s.endDate ? s.endDate.slice(0, 10) : ''} onChange={e => setS({ ...s, endDate: e.target.value })} /></div>
        <div><label style={lbl}>Seat Limit</label><input style={inp} type="number" value={s.seatLimit} onChange={e => setS({ ...s, seatLimit: e.target.value })} /></div>
        <div><label style={lbl}>Teacher / Faculty</label><input style={inp} value={s.teacherAssigned} onChange={e => setS({ ...s, teacherAssigned: e.target.value })} /></div>
      </div>
      <div style={{ margin: '10px 0' }}><Toggle on={s.autoArchiveAfterEnd} onChange={v => setS({ ...s, autoArchiveAfterEnd: v })} label="Auto-Archive After End Date" /></div>
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={bp} onClick={save}>💾 Save Settings</button>
        <button style={bs} onClick={toggleLock}>{s.isLocked ? '🔓 Unlock Series' : '🔒 Lock Series'}</button>
      </div>
      {s.renameHistory?.length > 0 && (
        <div style={{ ...cs, marginTop: 14 }}>
          <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>Rename History</div>
          {s.renameHistory.map((r: any, i: number) => <div key={i} style={{ fontSize: 11, color: DIM }}>{r.oldName} → {r.newName} ({new Date(r.changedAt).toLocaleDateString()})</div>)}
        </div>
      )}
    </div>
  )
}

// ── 15) AUDIT HISTORY TAB ──
function AuditTab({ base, authHeaders, id }: any) {
  const [audit, setAudit] = useState<any[]>([])
  useEffect(() => { fetch(base + '/' + id + '/audit', { headers: authHeaders }).then(r => r.json()).then(d => setAudit(d.audit || [])).catch(() => {}) }, [])
  return (
    <div style={cs}>
      {audit.length === 0 ? <EmptyMsg text="No audit records yet." /> : audit.map((a, i) => (
        <div key={i} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}`, fontSize: 11.5 }}>
          <div style={{ color: TS, fontWeight: 600 }}>{a.action} — {a.field}</div>
          <div style={{ color: DIM }}>Old: {JSON.stringify(a.oldValue)} → New: {JSON.stringify(a.newValue)}</div>
          <div style={{ color: DIM, fontSize: 10 }}>{a.changedByName} · {new Date(a.timestamp).toLocaleString()}</div>
        </div>
      ))}
    </div>
  )
}
PRVRNK_EOF_MARKER
echo "✅ Updated TestSeriesManagerUltra.tsx with Banner Panel"
else echo "⚠️  TestSeriesManagerUltra.tsx not found — run FPR2 frontend installer first. Skipping this update."; fi

# ── 3) Overwrite Banner Generator page.tsx (Ultra SaaS upgrade) ──
cp "$BANNER_DIR/page.tsx" "$BANNER_DIR/page.tsx.bak_fpr3" 2>/dev/null || true
cat > "$BANNER_DIR/page.tsx" << 'PRVRNK_EOF_MARKER'
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
  // ── FPR3 fields ──
  linkedType?: 'batch' | 'series' | 'none'
  linkedBatchId?: string
  status?: 'draft' | 'ready' | 'scheduled' | 'published' | 'archived' | 'removed' | 'replaced'
  syncState?: 'synced' | 'pending_sync' | 'conflict' | 'manual_override' | 'ready_to_publish'
  qualityScore?: number
  tags?: string[]
  approvedAt?: string
  approvedBy?: string
  removedAt?: string
  replacedBy?: string
  replacedFrom?: string
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
  bgImage: '', published: false,
  linkedType: 'none', linkedBatchId: '', status: 'draft', syncState: 'synced',
  qualityScore: 0, tags: []
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
function BannerPreview({ b, size = 'card', previewRef }: { b: Banner; size?: 'card' | 'wide' | 'square' | 'mobile'; previewRef?: React.RefObject<HTMLDivElement> }) {
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
  const [tab, setTab] = useState<'overview' | 'gate' | 'editor' | 'library' | 'analytics' | 'audit'>('overview')
  const [form, setForm] = useState<Banner>(EMPTY)
  const [banners, setBanners] = useState<Banner[]>([])
  const [batches, setBatches] = useState<any[]>([])
  const [seriesList, setSeriesList] = useState<any[]>([])
  const [linkType, setLinkType] = useState<'batch' | 'series' | 'none'>('none')
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
  // ── FPR3 state ──
  const [overviewData, setOverviewData] = useState<any>(null)
  const [gateItems, setGateItems] = useState<any[]>([])
  const [syncQueue, setSyncQueue] = useState<any[]>([])
  const [bulkSelected, setBulkSelected] = useState<string[]>([])
  const [analyticsSummary, setAnalyticsSummary] = useState<any>(null)
  const [auditLog, setAuditLog] = useState<any[]>([])
  const [libraryFilter, setLibraryFilter] = useState<string>('')

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
    setTok(t); fetchBanners(t); fetchBatches(t); fetchSeriesList(t)
    fetchOverview(t); fetchSyncQueue(t); fetchAnalyticsSummary(t)
    const bId = searchParams.get('batchId')
    const bName = searchParams.get('batchName')
    const sId = searchParams.get('seriesId')
    const sName = searchParams.get('seriesName')
    if (bId && bName) {
      setLinkType('batch')
      setForm(prev => ({ ...prev, batchId: bId, batchName: bName, title: bName, linkedType: 'batch', linkedBatchId: bId }))
    }
    if (sId && sName) {
      setLinkType('series')
      setForm(prev => ({ ...prev, batchId: sId, batchName: sName, title: sName, linkedType: 'series', linkedBatchId: sId }))
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
      const r = await fetch(`${API}/api/admin/batch-controls`, { headers: { Authorization: `Bearer ${t}` } })
      const d = await r.json(); setBatches(d.batches || [])
    } catch { }
  }

  const fetchSeriesList = async (t: string) => {
    try {
      const r = await fetch(`${API}/api/admin/test-series-manager`, { headers: { Authorization: `Bearer ${t}` } })
      const d = await r.json(); setSeriesList(d.testSeries || [])
    } catch { }
  }

  const fetchOverview = async (t: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/overview`, { headers: { Authorization: `Bearer ${t}` } })
      const d = await r.json(); setOverviewData(d.overview || null)
    } catch { }
  }

  const fetchSyncQueue = async (t: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/sync-queue`, { headers: { Authorization: `Bearer ${t}` } })
      const d = await r.json(); setSyncQueue(d.pending || [])
    } catch { }
  }

  const fetchAnalyticsSummary = async (t: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/analytics/summary`, { headers: { Authorization: `Bearer ${t}` } })
      const d = await r.json(); setAnalyticsSummary(d.summary || null)
    } catch { }
  }

  const fetchAudit = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/audit/${id}`, { headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json(); setAuditLog(d.audit || [])
    } catch { }
  }

  const refreshAll = () => { fetchBanners(tok); fetchOverview(tok); fetchSyncQueue(tok) }

  const approveBanner = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/${id}/approve`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Banner approved ✅'); refreshAll() }
    } catch { showToast('Error') }
  }

  const removeBannerFlow = async (id: string) => {
    if (!window.confirm('Remove this banner? It can be restored later from Overview.')) return
    try {
      await fetch(`${API}/api/admin/banners/${id}/remove`, { method: 'POST', headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ reason: 'Removed from Banner Management' }) })
      showToast('Banner removed 🗑️'); refreshAll()
    } catch { showToast('Error') }
  }

  const restoreRemovedBanner = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/${id}/restore-removed`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Banner restored ✅'); refreshAll() }
    } catch { showToast('Error') }
  }

  const replaceBannerFlow = async (id: string) => {
    if (!window.confirm('Create a replacement draft for this banner? The old one will be archived as replaced.')) return
    try {
      const r = await fetch(`${API}/api/admin/banners/${id}/replace`, { method: 'POST', headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ title: 'Replacement Draft' }) })
      const d = await r.json()
      if (d.success) { showToast('Replacement draft created ✅'); loadBanner(d.banner); refreshAll() }
    } catch { showToast('Error') }
  }

  const syncBannerNow = async (b: Banner) => {
    try {
      const r = await fetch(`${API}/api/admin/banners/${b._id}/sync`, { method: 'POST', headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' }, body: JSON.stringify({}) })
      const d = await r.json()
      if (d.success) { showToast('Banner synced ✅'); refreshAll() }
    } catch { showToast('Error') }
  }

  const toggleBulkSelect = (id: string) => setBulkSelected(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])
  const bulkAction = async (action: 'publish' | 'archive' | 'duplicate') => {
    if (bulkSelected.length === 0) return
    try {
      const r = await fetch(`${API}/api/admin/banners/bulk`, { method: 'POST', headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ ids: bulkSelected, action }) })
      const d = await r.json()
      showToast(`✅ ${d.affected || 0} banner(s) ${action}d`); setBulkSelected([]); refreshAll()
    } catch { showToast('Error') }
  }

  const buildPublishGateItems = () => {
    const items: any[] = []
    batches.forEach(b => {
      const linkedBanner = banners.find(bn => bn.linkedType === 'batch' && bn.linkedBatchId === b._id && bn.status !== 'removed')
      items.push({ id: b._id, name: b.name, type: 'batch', banner: linkedBanner || null })
    })
    seriesList.forEach(s => {
      const linkedBanner = banners.find(bn => bn.linkedType === 'series' && bn.linkedBatchId === s._id && bn.status !== 'removed')
      items.push({ id: s._id, name: s.name, type: 'series', banner: linkedBanner || null })
    })
    return items
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

  const loadBanner = (b: Banner) => { setForm(b); setEditId(b._id!); setLinkType((b.linkedType as any) || 'none'); setTab('editor') }
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
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 17, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>🖼️ Banner Management</div>
          <div style={{ fontSize: 10, color: SUB }}>Branding — ProveRank</div>
        </div>
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <button onClick={() => setDarkMode(d => !d)} style={{ background: 'rgba(77,159,255,0.1)', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '6px 12px', cursor: 'pointer', color: TEXT, fontSize: 12 }}>{darkMode ? '☀️ Light' : '🌙 Dark'}</button>
          <div style={{ display: 'flex', gap: 1, background: darkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)', borderRadius: 10, padding: 3, flexWrap: 'wrap' }}>
            {(['overview', 'gate', 'editor', 'library', 'analytics', 'audit'] as const).map(t => (
              <button key={t} onClick={() => { setTab(t); if (t === 'audit' && editId) fetchAudit(editId) }} style={{ padding: '6px 12px', borderRadius: 8, background: tab === t ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'transparent', border: 'none', color: tab === t ? '#fff' : SUB, fontWeight: tab === t ? 700 : 400, cursor: 'pointer', fontSize: 11 }}>
                {t === 'overview' ? '📊 Overview' : t === 'gate' ? '🚦 Publish Gate' : t === 'editor' ? '✏️ Editor' : t === 'library' ? `🗂️ Library (${banners.length})` : t === 'analytics' ? '📈 Analytics' : '🕐 Audit'}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── OVERVIEW TAB (FPR3) ── */}
      {tab === 'overview' && (
        <div style={{ maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px' }}>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TEXT, marginBottom: 20 }}>📊 Banner Overview</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 12, marginBottom: 20 }}>
            {[
              ['Total', overviewData?.total, '#4D9FFF'], ['Draft', overviewData?.draft, '#9B59B6'],
              ['Ready', overviewData?.ready, '#E67E22'], ['Published', overviewData?.published, '#27AE60'],
              ['Scheduled', overviewData?.scheduled, '#00D4FF'], ['Removed', overviewData?.removed, '#E74C3C'],
              ['Linked Batches', overviewData?.linkedBatches, '#7DD3FC'], ['Linked Series', overviewData?.linkedSeries, '#FDE68A']
            ].map(([l, v, c]: any) => (
              <div key={l} style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 14, padding: 14, textAlign: 'center' }}>
                <div style={{ fontSize: 22, fontWeight: 800, color: c }}>{v ?? 0}</div>
                <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase' }}>{l}</div>
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 20 }}>
            <button onClick={() => { setForm(EMPTY); setEditId(null); setLinkType('none'); setTab('editor') }} style={{ padding: '10px 18px', background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 12, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 12 }}>➕ Create Banner</button>
            <button onClick={() => setTab('library')} style={{ padding: '10px 18px', background: 'rgba(77,159,255,0.1)', border: `1px solid ${BORDER}`, borderRadius: 12, color: '#4D9FFF', fontWeight: 700, cursor: 'pointer', fontSize: 12 }}>🗂️ Open Library</button>
            <button onClick={() => setTab('gate')} style={{ padding: '10px 18px', background: 'rgba(230,126,34,0.1)', border: `1px solid ${BORDER}`, borderRadius: 12, color: '#E67E22', fontWeight: 700, cursor: 'pointer', fontSize: 12 }}>🚦 View Publish Gate</button>
            <button onClick={() => setTab('analytics')} style={{ padding: '10px 18px', background: 'rgba(39,174,96,0.1)', border: `1px solid ${BORDER}`, borderRadius: 12, color: '#27AE60', fontWeight: 700, cursor: 'pointer', fontSize: 12 }}>📈 Open Analytics</button>
          </div>
          {syncQueue.length > 0 && (
            <div style={{ background: CARD, border: '1px solid rgba(230,126,34,0.3)', borderRadius: 16, padding: 18, marginBottom: 20 }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#E67E22', marginBottom: 10 }}>⚠️ Sync Queue — {syncQueue.length} banner(s) need re-sync</div>
              {syncQueue.map(b => (
                <div key={b._id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 0', borderBottom: `1px solid ${BORDER}` }}>
                  <span style={{ fontSize: 12, color: TEXT }}>{b.title} <span style={{ fontSize: 10, color: SUB }}>({b.syncState})</span></span>
                  <button onClick={() => loadBanner(b)} style={{ padding: '5px 12px', background: 'rgba(77,159,255,0.12)', border: 'none', borderRadius: 8, color: '#4D9FFF', cursor: 'pointer', fontSize: 11 }}>Open</button>
                </div>
              ))}
            </div>
          )}
          <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18 }}>
            <div style={{ fontWeight: 700, fontSize: 13, color: TEXT, marginBottom: 10 }}>🕐 Recently Edited</div>
            {(overviewData?.recentlyEdited || []).length === 0 ? <div style={{ fontSize: 12, color: SUB }}>No banners yet.</div> :
              overviewData.recentlyEdited.map((b: any) => (
                <div key={b._id} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${BORDER}`, fontSize: 12, color: SUB }}>
                  <span>{b.title}</span><span>{b.status} · {new Date(b.updatedAt).toLocaleDateString()}</span>
                </div>
              ))}
          </div>
        </div>
      )}

      {/* ── PUBLISH GATE TAB (FPR3) ── */}
      {tab === 'gate' && (
        <div style={{ maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px' }}>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TEXT, marginBottom: 8 }}>🚦 Publish Gate</div>
          <div style={{ fontSize: 12, color: SUB, marginBottom: 20 }}>Every Batch / Test Series must have a ready banner before it can launch. Items below need action.</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(280px,1fr))', gap: 14 }}>
            {buildPublishGateItems().map(item => {
              const b = item.banner
              const ready = b && (['ready', 'scheduled', 'published'].includes(b.status) || b.published)
              return (
                <div key={item.type + item.id} style={{ background: CARD, border: `1px solid ${ready ? 'rgba(39,174,96,0.3)' : 'rgba(231,76,60,0.3)'}`, borderRadius: 14, padding: 16 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                    <span style={{ fontSize: 10, color: SUB }}>{item.type === 'batch' ? '📦 Batch' : '📚 Test Series'}</span>
                    <span style={{ fontSize: 10, fontWeight: 700, color: ready ? '#27AE60' : '#E74C3C' }}>{ready ? '✅ Launch Allowed' : '⛔ Launch Blocked'}</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: 13, color: TEXT, marginBottom: 8 }}>{item.name}</div>
                  {b ? (
                    <div style={{ fontSize: 11, color: SUB, marginBottom: 10 }}>Banner: {b.title} · Status: {b.status} · Quality: {b.qualityScore || 0}/100</div>
                  ) : (
                    <div style={{ fontSize: 11, color: '#E74C3C', marginBottom: 10 }}>No banner created yet.</div>
                  )}
                  <button onClick={() => {
                    if (b) { loadBanner(b) } else {
                      setForm({ ...EMPTY, batchId: item.id, batchName: item.name, title: item.name, linkedType: item.type, linkedBatchId: item.id })
                      setLinkType(item.type); setEditId(null); setTab('editor')
                    }
                  }} style={{ width: '100%', padding: '8px', background: ready ? 'rgba(77,159,255,0.1)' : 'linear-gradient(135deg,#E74C3C,#C0392B)', border: 'none', borderRadius: 10, color: ready ? '#4D9FFF' : '#fff', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                    {b ? '✏️ Open Banner Builder' : '➕ Auto-Generate Banner Draft'}
                  </button>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* ── EDITOR TAB ── */}
      {tab === 'editor' && (
        <div style={{ display: 'flex', gap: 20, maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px' }}>

          {/* LEFT — Form */}
          <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 16 }}>

            {/* Batch / Series Link */}
            <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, backdropFilter: 'blur(16px)' }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: '#4D9FFF', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 14 }}>🔗 Link Batch / Test Series</div>
              <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
                {(['none', 'batch', 'series'] as const).map(lt => (
                  <button key={lt} onClick={() => { setLinkType(lt); if (lt === 'none') { upd('batchId', ''); upd('batchName', ''); upd('linkedType', 'none'); upd('linkedBatchId', '') } else { upd('linkedType', lt) } }}
                    style={{ flex: 1, padding: '7px', borderRadius: 10, border: `1px solid ${linkType === lt ? '#4D9FFF' : BORDER}`, background: linkType === lt ? 'rgba(77,159,255,0.15)' : 'transparent', color: linkType === lt ? '#4D9FFF' : SUB, cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                    {lt === 'none' ? '⭕ No Link' : lt === 'batch' ? '📦 Batch' : '📚 Test Series'}
                  </button>
                ))}
              </div>
              {linkType === 'batch' && (
                <>
                  <label style={labelStyle}>Link to Batch</label>
                  <select value={form.batchId} onChange={e => {
                    const b = batches.find(bt => bt._id === e.target.value)
                    upd('batchId', e.target.value); upd('linkedBatchId', e.target.value); upd('linkedType', 'batch')
                    if (b) { upd('batchName', b.name); upd('title', b.name); upd('examType', b.examType || 'NEET'); upd('price', String(b.effectivePrice ?? b.price ?? '')) }
                  }} style={{ ...inpStyle, marginBottom: 10 }}>
                    <option value="">— Select a batch —</option>
                    {batches.map(b => <option key={b._id} value={b._id}>{b.name}</option>)}
                  </select>
                  {form.batchId && <div style={{ fontSize: 10, color: '#27AE60' }}>✅ Linked: {form.batchName}</div>}
                </>
              )}
              {linkType === 'series' && (
                <>
                  <label style={labelStyle}>Link to Test Series</label>
                  <select value={form.batchId} onChange={e => {
                    const s = seriesList.find(st => st._id === e.target.value)
                    upd('batchId', e.target.value); upd('linkedBatchId', e.target.value); upd('linkedType', 'series')
                    if (s) { upd('batchName', s.name); upd('title', s.name); upd('examType', s.examType || 'NEET'); upd('price', String(s.effectivePrice ?? s.price ?? '')) }
                  }} style={{ ...inpStyle, marginBottom: 10 }}>
                    <option value="">— Select a test series —</option>
                    {seriesList.map(s => <option key={s._id} value={s._id}>{s.name}</option>)}
                  </select>
                  {form.batchId && <div style={{ fontSize: 10, color: '#27AE60' }}>✅ Linked: {form.batchName}</div>}
                </>
              )}
              {linkType !== 'none' && form.batchId && (
                <button onClick={() => syncBannerNow(form)} disabled={!editId} title={!editId ? 'Save banner first to enable sync' : ''}
                  style={{ marginTop: 8, width: '100%', padding: '7px', background: 'rgba(155,89,182,0.1)', border: '1px solid rgba(155,89,182,0.25)', borderRadius: 10, color: editId ? '#9B59B6' : SUB, cursor: editId ? 'pointer' : 'not-allowed', fontSize: 11, fontWeight: 700 }}>
                  🔄 Re-Sync from Linked {linkType === 'batch' ? 'Batch' : 'Test Series'}
                </button>
              )}
              {editId && (
                <div style={{ marginTop: 10, display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
                  <span style={{ fontSize: 10, color: SUB }}>Quality Score:</span>
                  <span style={{ fontSize: 12, fontWeight: 800, color: (form.qualityScore || 0) >= 70 ? '#27AE60' : (form.qualityScore || 0) >= 40 ? '#E67E22' : '#E74C3C' }}>{form.qualityScore || 0}/100</span>
                  <span style={{ fontSize: 10, background: 'rgba(77,159,255,0.1)', color: '#4D9FFF', padding: '2px 8px', borderRadius: 20, marginLeft: 'auto' }}>{form.status || 'draft'}</span>
                  {form.status === 'draft' && <button onClick={() => approveBanner(editId)} style={{ padding: '4px 10px', background: 'rgba(39,174,96,0.12)', border: '1px solid rgba(39,174,96,0.3)', borderRadius: 8, color: '#27AE60', cursor: 'pointer', fontSize: 10, fontWeight: 700 }}>✅ Approve</button>}
                </div>
              )}
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
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 10, marginBottom: 20 }}>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TEXT }}>🗂️ Banner Library</div>
            <select value={libraryFilter} onChange={e => setLibraryFilter(e.target.value)} style={{ ...inpStyle, width: 180 }}>
              <option value="">All Statuses</option>
              {['draft', 'ready', 'scheduled', 'published', 'archived', 'removed', 'replaced'].map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
          {bulkSelected.length > 0 && (
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 14, background: CARD, border: `1px solid ${BORDER}`, borderRadius: 12, padding: 10 }}>
              <span style={{ fontSize: 12, color: TEXT }}>{bulkSelected.length} selected</span>
              <button onClick={() => bulkAction('publish')} style={{ padding: '5px 12px', background: 'rgba(39,174,96,0.12)', border: 'none', borderRadius: 8, color: '#27AE60', cursor: 'pointer', fontSize: 11 }}>🟢 Publish</button>
              <button onClick={() => bulkAction('archive')} style={{ padding: '5px 12px', background: 'rgba(230,126,34,0.12)', border: 'none', borderRadius: 8, color: '#E67E22', cursor: 'pointer', fontSize: 11 }}>📦 Archive</button>
              <button onClick={() => bulkAction('duplicate')} style={{ padding: '5px 12px', background: 'rgba(155,89,182,0.12)', border: 'none', borderRadius: 8, color: '#9B59B6', cursor: 'pointer', fontSize: 11 }}>⧉ Duplicate</button>
              <button onClick={() => setBulkSelected([])} style={{ padding: '5px 12px', background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 8, color: SUB, cursor: 'pointer', fontSize: 11, marginLeft: 'auto' }}>✕ Clear</button>
            </div>
          )}
          {banners.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '60px 20px', color: SUB }}>
              <div style={{ fontSize: 56, marginBottom: 16 }}>🎨</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: TEXT, marginBottom: 8 }}>No Banners Yet</div>
              <div style={{ fontSize: 13, marginBottom: 24 }}>Create your first banner from the Editor tab</div>
              <button onClick={() => setTab('editor')} style={{ background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 12, padding: '12px 28px', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 13 }}>+ Create Banner</button>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(320px,1fr))', gap: 20 }}>
              {banners.filter(b => !libraryFilter || b.status === libraryFilter).map(b => {
                const statusColors: any = { draft: '#9B59B6', ready: '#E67E22', scheduled: '#00D4FF', published: '#27AE60', archived: '#7f8c8d', removed: '#E74C3C', replaced: '#7f8c8d' }
                const st = b.status || (b.published ? 'published' : 'draft')
                return (
                <div key={b._id} style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 18, overflow: 'hidden', backdropFilter: 'blur(16px)', transition: 'all 0.2s', animation: 'slideUp 0.4s ease', opacity: st === 'removed' ? 0.55 : 1 }}>
                  <div style={{ padding: 16, position: 'relative' }}>
                    <input type="checkbox" checked={bulkSelected.includes(b._id!)} onChange={() => toggleBulkSelect(b._id!)} style={{ position: 'absolute', top: 24, left: 24, zIndex: 2 }} />
                    <BannerPreview b={b} size="card" />
                  </div>
                  <div style={{ padding: '0 16px 14px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6, flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 11, background: `${statusColors[st]}22`, color: statusColors[st], padding: '2px 8px', borderRadius: 20, fontWeight: 700, textTransform: 'capitalize' }}>{st}</span>
                      {b.linkedType && b.linkedType !== 'none' && <span style={{ fontSize: 10, background: 'rgba(77,159,255,0.1)', color: '#4D9FFF', padding: '2px 8px', borderRadius: 20 }}>{b.linkedType === 'batch' ? '📦 Batch' : '📚 Series'}</span>}
                      {b.syncState && b.syncState !== 'synced' && <span style={{ fontSize: 10, background: 'rgba(230,126,34,0.12)', color: '#E67E22', padding: '2px 8px', borderRadius: 20 }}>⚠️ {b.syncState}</span>}
                      <span style={{ fontSize: 10, color: SUB, marginLeft: 'auto' }}>Q: {b.qualityScore || 0}</span>
                    </div>
                    {b.scheduledAt && !b.published && new Date(b.scheduledAt) > new Date() && (
                      <div style={{ fontSize: 10, background: 'rgba(230,126,34,0.12)', color: '#E67E22', padding: '2px 8px', borderRadius: 20, fontWeight: 700, display: 'inline-block', marginBottom: 8 }}>⏰ Scheduled: {new Date(b.scheduledAt).toLocaleDateString()}</div>
                    )}
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
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 6 }}>
                      {st === 'draft' && <button onClick={() => approveBanner(b._id!)} style={{ flex: 1, padding: '6px', background: 'rgba(39,174,96,0.1)', border: '1px solid rgba(39,174,96,0.25)', borderRadius: 10, color: '#27AE60', cursor: 'pointer', fontSize: 10 }}>✅ Approve</button>}
                      {st === 'removed' ? (
                        <button onClick={() => restoreRemovedBanner(b._id!)} style={{ flex: 1, padding: '6px', background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.25)', borderRadius: 10, color: '#4D9FFF', cursor: 'pointer', fontSize: 10 }}>♻️ Restore</button>
                      ) : (
                        <button onClick={() => removeBannerFlow(b._id!)} style={{ flex: 1, padding: '6px', background: 'rgba(231,76,60,0.06)', border: '1px solid rgba(231,76,60,0.15)', borderRadius: 10, color: '#E74C3C', cursor: 'pointer', fontSize: 10 }}>🗑️ Remove</button>
                      )}
                      {b.linkedType && b.linkedType !== 'none' && <button onClick={() => replaceBannerFlow(b._id!)} style={{ flex: 1, padding: '6px', background: 'rgba(230,126,34,0.08)', border: '1px solid rgba(230,126,34,0.2)', borderRadius: 10, color: '#E67E22', cursor: 'pointer', fontSize: 10 }}>🔁 Replace</button>}
                    </div>
                  </div>
                </div>
              )})}
            </div>
          )}
        </div>
      )}

      {/* ── ANALYTICS TAB (FPR3) ── */}
      {tab === 'analytics' && (
        <div style={{ maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px' }}>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TEXT, marginBottom: 20 }}>📈 Banner Analytics</div>
          {!analyticsSummary ? <div style={{ color: SUB, fontSize: 12 }}>Loading analytics…</div> : (
            <>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 12, marginBottom: 20 }}>
                {[['Total Views', analyticsSummary.totalViews, '#4D9FFF'], ['Total Clicks', analyticsSummary.totalClicks, '#00D4FF'],
                ['Total Enrolls', analyticsSummary.totalEnrolls, '#27AE60'], ['Click Rate', analyticsSummary.clickRate + '%', '#E67E22'],
                ['Conversion Rate', analyticsSummary.conversionRate + '%', '#9B59B6']].map(([l, v, c]: any) => (
                  <div key={l} style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 14, padding: 14, textAlign: 'center' }}>
                    <div style={{ fontSize: 20, fontWeight: 800, color: c }}>{v}</div>
                    <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase' }}>{l}</div>
                  </div>
                ))}
              </div>
              <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, marginBottom: 16 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: TEXT, marginBottom: 10 }}>🏆 Template Performance Leaderboard</div>
                {Object.entries(analyticsSummary.byTemplate || {}).sort((a: any, b: any) => b[1].views - a[1].views).map(([tpl, s]: any) => (
                  <div key={tpl} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${BORDER}`, fontSize: 12, color: SUB }}>
                    <span style={{ textTransform: 'capitalize' }}>{tpl} ({s.count})</span><span>{s.views} views · {s.clicks} clicks</span>
                  </div>
                ))}
              </div>
              <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18, marginBottom: 16 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: TEXT, marginBottom: 10 }}>🖱️ CTA Performance Comparison</div>
                {Object.entries(analyticsSummary.byCta || {}).map(([cta, s]: any) => (
                  <div key={cta} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${BORDER}`, fontSize: 12, color: SUB }}>
                    <span>{cta}</span><span>{s.views} views · {s.clicks} clicks</span>
                  </div>
                ))}
              </div>
              <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: TEXT, marginBottom: 10 }}>⚖️ Batch vs Test Series Performance</div>
                <div style={{ fontSize: 12, color: SUB }}>📦 Batch Banners: {analyticsSummary.batchVsSeries?.batch || 0} views · 📚 Series Banners: {analyticsSummary.batchVsSeries?.series || 0} views</div>
              </div>
            </>
          )}
        </div>
      )}

      {/* ── AUDIT TAB (FPR3) ── */}
      {tab === 'audit' && (
        <div style={{ maxWidth: 1300, margin: '0 auto', padding: '20px 16px 80px' }}>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TEXT, marginBottom: 8 }}>🕐 Audit Trail</div>
          <div style={{ fontSize: 12, color: SUB, marginBottom: 20 }}>{editId ? `Showing history for: ${form.title}` : 'Open a banner from the Editor or Library to view its audit trail.'}</div>
          <div style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 16, padding: 18 }}>
            {auditLog.length === 0 ? <div style={{ color: SUB, fontSize: 12 }}>No audit records{editId ? ' for this banner yet.' : '.'}</div> :
              auditLog.map((a, i) => (
                <div key={i} style={{ padding: '8px 0', borderBottom: `1px solid ${BORDER}`, fontSize: 11.5 }}>
                  <div style={{ color: TEXT, fontWeight: 600 }}>{a.action}{a.reason ? ` — ${a.reason}` : ''}</div>
                  <div style={{ color: SUB }}>{a.performedByName || 'System'} · {new Date(a.timestamp).toLocaleString()}</div>
                </div>
              ))}
          </div>
        </div>
      )}
    </div>
  )
}
PRVRNK_EOF_MARKER
echo "✅ Created/Updated Banner Generator page.tsx (Ultra SaaS Banner Management)"

# ── 4) Relabel "Creative Studio" nav -> "Banner Management" (idempotent) ──
cp "$PAGE_FILE" "$PAGE_FILE.bak_fpr3"

if grep -q "Banner Management" "$PAGE_FILE"; then
  echo "⏭️  Nav already relabeled to Banner Management — skipping"
else
  if grep -q "{id:'banner-generator',label:'🎨 Creative Studio',href:'/admin/x7k2p/banner-generator'}," "$PAGE_FILE"; then
    sed -i "s/{id:'banner-generator',label:'🎨 Creative Studio',href:'\/admin\/x7k2p\/banner-generator'},/{id:'banner-generator',label:'🖼️ Banner Management',href:'\/admin\/x7k2p\/banner-generator'},/" "$PAGE_FILE"
    echo "✅ Relabeled quick-link entry"
  else
    echo "ℹ️  Quick-link anchor not found (may already differ) — skipping this specific patch"
  fi

  if grep -q "{id:'creative_studio',ico:'🎨',lbl:'Creative Studio',grp:'Creative',alwaysShow:true}," "$PAGE_FILE"; then
    sed -i "s/{id:'creative_studio',ico:'🎨',lbl:'Creative Studio',grp:'Creative',alwaysShow:true},/{id:'creative_studio',ico:'🖼️',lbl:'Banner Management',grp:'Settings',alwaysShow:true},/" "$PAGE_FILE"
    echo "✅ Relabeled sidebar NAV entry (moved under Settings, next to Branding & SEO)"
  else
    echo "ℹ️  Sidebar NAV anchor not found (may already differ) — skipping this specific patch"
  fi
fi

# ══════════════════════════════════════════════════════════════════
# ✅ FINAL VERIFICATION CHECKLIST — FRONTEND (FPR3 Banner Management & Publish Gate)
# ══════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FPR3 BANNER MANAGEMENT — FRONTEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
BGFILE="$BANNER_DIR/page.tsx"
PASS=0; FAIL=0
check() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "✅ $DESC"; PASS=$((PASS+1))
  else
    echo "❌ $DESC"; FAIL=$((FAIL+1))
  fi
}

check "1) Existing Templates/Assets/Editor Preserved (8 templates)"   "Aurora" "$BGFILE"
check "2) Existing PNG Download / Share / Duplicate Preserved"        "html2canvas" "$BGFILE"
check "3) Overview Dashboard Tab"                                      "OVERVIEW TAB (FPR3)" "$BGFILE"
check "4) Overview — Status Counts (draft/ready/published/scheduled)" "overviewData?.draft" "$BGFILE"
check "5) Overview — Sync Queue Alert Panel"                           "Sync Queue —" "$BGFILE"
check "6) Publish Gate Tab (batch + series items)"                    "PUBLISH GATE TAB (FPR3)" "$BGFILE"
check "7) Publish Gate — Launch Allowed / Blocked Indicator"          "Launch Allowed" "$BGFILE"
check "8) Publish Gate — Auto-Generate Draft Action"                  "Auto-Generate Banner Draft" "$BGFILE"
check "9) Dual Link Type Selector (Batch vs Test Series)"             "🔗 Link Batch / Test Series" "$BGFILE"
check "10) Link to Batch Dropdown"                                     "Link to Batch" "$BGFILE"
check "11) Link to Test Series Dropdown"                               "Link to Test Series" "$BGFILE"
check "12) Re-Sync From Linked Batch/Series Button"                    "Re-Sync from Linked" "$BGFILE"
check "13) Quality Score Display in Editor"                            "Quality Score:" "$BGFILE"
check "14) Approve Banner Action"                                       "approveBanner" "$BGFILE"
check "15) Remove Banner Action (recoverable)"                         "removeBannerFlow" "$BGFILE"
check "16) Restore Removed Banner Action"                              "restoreRemovedBanner" "$BGFILE"
check "17) Replace Banner Flow"                                         "replaceBannerFlow" "$BGFILE"
check "18) Library — Status Badges (draft/ready/scheduled/published/archived/removed/replaced)" "statusColors" "$BGFILE"
check "19) Library — Sync State Badge"                                  "b.syncState && b.syncState !== 'synced'" "$BGFILE"
check "20) Library — Bulk Select + Bulk Publish/Archive/Duplicate"     "bulkAction('publish')" "$BGFILE"
check "21) Library — Status Filter Dropdown"                            "libraryFilter" "$BGFILE"
check "22) Analytics Tab — Conversion/Click/Template Leaderboard"      "Template Performance Leaderboard" "$BGFILE"
check "23) Analytics — CTA Performance Comparison"                     "CTA Performance Comparison" "$BGFILE"
check "24) Analytics — Batch vs Series Performance"                    "Batch vs Test Series Performance" "$BGFILE"
check "25) Audit Trail Tab"                                             "AUDIT TAB (FPR3)" "$BGFILE"
check "26) Bugfix — Batches Endpoint Corrected (was broken pre-FPR3)"  "/api/admin/batch-controls" "$BGFILE"
check "27) Bugfix — BannerPreview 'mobile' size type fixed"            "'card' | 'wide' | 'square' | 'mobile'" "$BGFILE"
check "28) Header Rebranded to Banner Management"                       "🖼️ Banner Management" "$BGFILE"
check "29) Batch Detail — Banner Panel Integrated"                     "function BannerPanel" "$ADMIN_DIR/BatchManagerUltra.tsx"
check "30) Batch Detail — Banner Panel Wired into Overview"            "<BannerPanel base={base}" "$ADMIN_DIR/BatchManagerUltra.tsx"
check "31) Test Series Detail — Banner Panel Integrated"               "function BannerPanel" "$ADMIN_DIR/TestSeriesManagerUltra.tsx"
check "32) Test Series Detail — Banner Panel Wired into Overview"      "<BannerPanel base={base}" "$ADMIN_DIR/TestSeriesManagerUltra.tsx"
check "33) Sidebar Nav Relabeled to Banner Management"                  "Banner Management" "$PAGE_FILE"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL)) TOTAL"
if [ "$FAIL" -eq 0 ]; then
  echo "  🎉 ALL FRONTEND FPR3 FEATURES SUCCESSFULLY IMPLEMENTED ✅"
else
  echo "  ⚠️  $FAIL item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🧹 Backups saved as *.bak_fpr3 next to originals (safe to delete once verified working)."
echo "👉 Next: Restart your Next.js dev server (or redeploy). Open Admin Panel → Banner Management (under Settings) to test the Publish Gate."
