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
            {['spotlight', 'trial', 'bundle', 'flashsale'].map(f => (
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
    name: '', examType: 'NEET UG', description: '',
    seatLimit: 0, visibility: 'public',
    price: 0, templateId: ''
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

  const steps = ['Basic Info', 'Pricing', 'Preview & Confirm']
  const EXAM_TYPES = ['NEET UG', 'NEET PG', 'JEE Main', 'JEE Advanced', 'CUET UG', 'CUET PG', 'SSC CGL', 'SSC CHSL', 'UPSC CSE', 'NDA', 'CDS', 'CAT', 'CLAT', 'GATE', 'IIT JAM', 'CSIR NET', 'UGC NET', 'Railway (RRB)', 'Banking (IBPS / SBI)', 'State PSC', 'Nursing Entrance', 'Paramedical Entrance', 'Defence Exams', 'Other (Custom)']

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
          <label style={lbl}>Exam / Course</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.examType} onChange={e => set('examType', e.target.value)}>
            {EXAM_TYPES.map(x => <option key={x}>{x}</option>)}
          </select>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Seat Limit (0 = unlimited)</label><input type="number" style={inp} value={form.seatLimit} onChange={e => set('seatLimit', e.target.value)} /></div>
            <div><label style={lbl}>Visibility</label>
              <select style={inp} value={form.visibility} onChange={e => set('visibility', e.target.value)}>
                <option value="public">Public</option><option value="private">Private</option><option value="invite_only">Invite Only</option>
              </select>
            </div>
          </div>
          <label style={{ ...lbl, marginTop: 10 }}>Description</label>
          <textarea style={{ ...inp, minHeight: 60 }} value={form.description} onChange={e => set('description', e.target.value)} />
        </div>
      )}

      {step === 2 && (
        <div>
          <label style={lbl}>Base Price ₹</label><input type="number" style={inp} value={form.price} onChange={e => set('price', e.target.value)} />
        </div>
      )}

      {step === 3 && (
        <div>
          <div style={{ ...cs, marginBottom: 0 }}>
            <div style={{ fontWeight: 700, color: '#93C5FD', fontSize: 14 }}>{form.name || '(Unnamed Batch)'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.examType} · Seat Limit: {form.seatLimit || 'Unlimited'} · {form.visibility}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>Price: ₹{form.price}</div>
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
        {step < 3 ? <button style={bp} onClick={() => setStep(step + 1)}>Next →</button> : <button style={bp} onClick={() => submit(false)}>✅ Confirm</button>}
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
    ['coupons', '🎟️ Coupons'],
    ['banner', '🖼️ Banner'],
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
      {tab === 'coupons' && <CouponManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'banner' && <BannerManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
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
  const saveAndLock = async () => {
    const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ price: form.basePrice, discountPrice: form.discountPrice, discountValidTill: form.discountValidTill }) })
    const d = await r.json()
    if (d.success) {
      if (!p.priceLocked) await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders })
      showToast('✅ Price saved & locked')
      load()
    } else showToast('⚠️ ' + d.error)
  }
  const unlock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); showToast('🔓 Price unlocked'); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        {p.priceLocked && <button style={bs} onClick={unlock}>Unlock</button>}
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" disabled={p.priceLocked} value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" disabled={p.priceLocked} value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Valid Till</label><input style={inp} type="date" disabled={p.priceLocked} value={form.discountValidTill ? String(form.discountValidTill).slice(0, 10) : ''} onChange={e => setForm({ ...form, discountValidTill: e.target.value })} /></div>
      </div>
      <button style={bp} onClick={saveAndLock} disabled={p.priceLocked}>🔒 Save & Lock Price</button>

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

// ── COUPON MANAGEMENT TAB ──
function CouponManagementTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const [analytics, setAnalytics] = useState<any>(null)
  const [filterStatus, setFilterStatus] = useState('all')
  const [sortBy, setSortBy] = useState('newest')
  const [showForm, setShowForm] = useState(false)
  const [editingCoupon, setEditingCoupon] = useState<any>(null)
  const emptyForm = { code: '', type: 'percent', value: '', maxDiscount: '', usageLimit: 100, perStudentLimitType: 'once', perStudentLimitCustom: 1, validFrom: '', validTill: '', description: '', status: 'draft', visibility: 'public', autoApplyBest: false, applicablePlan: 'entire' }
  const [form, setForm] = useState<any>(emptyForm)
  const [expandedUsage, setExpandedUsage] = useState('')
  const [expandedAnalytics, setExpandedAnalytics] = useState('')
  const [usageMap, setUsageMap] = useState<any>({})
  const [analyticsMap, setAnalyticsMap] = useState<any>({})
  const analyticsRef = useRef<any>(null)

  const load = useCallback(() => {
    const params = new URLSearchParams()
    if (filterStatus !== 'all') params.set('status', filterStatus)
    if (sortBy) params.set('sort', sortBy)
    fetch(base + '/' + id + '/coupons?' + params.toString(), { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {})
  }, [filterStatus, sortBy])
  useEffect(() => { load() }, [load])
  useEffect(() => { fetch(base + '/' + id + '/coupons/analytics', { headers: authHeaders }).then(r => r.json()).then(setAnalytics).catch(() => {}) }, [])

  const openCreate = () => { setEditingCoupon(null); setForm(emptyForm); setShowForm(true) }
  const openEdit = (c: any) => {
    setEditingCoupon(c)
    setForm({ ...c, validFrom: c.validFrom ? String(c.validFrom).slice(0, 10) : '', validTill: c.validTill ? String(c.validTill).slice(0, 10) : '' })
    setShowForm(true)
  }
  const submitForm = async () => {
    if (!form.code || !form.code.trim()) return showToast('⚠️ Coupon code required')
    if (!form.value || Number(form.value) <= 0) return showToast('⚠️ Value must be greater than 0')
    if (!form.validFrom || !form.validTill) return showToast('⚠️ Valid From and Valid Till required')
    const url = editingCoupon ? base + '/' + id + '/coupons/' + editingCoupon._id : base + '/' + id + '/coupons'
    const method = editingCoupon ? 'PUT' : 'POST'
    const r = await fetch(url, { method, headers: authHeaders, body: JSON.stringify(form) })
    const d = await r.json()
    if (d.success) { showToast(editingCoupon ? '✅ Coupon updated' : '✅ Coupon created'); setShowForm(false); load() }
    else showToast('⚠️ ' + d.error)
  }
  const duplicate = async (couponId: string) => { const r = await fetch(base + '/' + id + '/coupons/' + couponId + '/duplicate', { method: 'POST', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Coupon duplicated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleStatus = async (c: any, status: string) => { const r = await fetch(base + '/' + id + '/coupons/' + c._id + '/status', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ status }) }); const d = await r.json(); if (d.success) { showToast('✅ Status updated'); load() } else showToast('⚠️ ' + d.error) }
  const del = async (couponId: string) => { if (!window.confirm('Delete this coupon? This cannot be undone.')) return; const r = await fetch(base + '/' + id + '/coupons/' + couponId, { method: 'DELETE', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Coupon deleted'); load() } else showToast('⚠️ ' + d.error) }
  const viewUsage = async (couponId: string) => {
    if (expandedUsage === couponId) { setExpandedUsage(''); return }
    setExpandedUsage(couponId)
    if (!usageMap[couponId]) { const d = await fetch(base + '/' + id + '/coupons/' + couponId + '/usage', { headers: authHeaders }).then(r => r.json()); setUsageMap((m: any) => ({ ...m, [couponId]: d })) }
  }
  const viewAnalytics = async (couponId: string) => {
    if (expandedAnalytics === couponId) { setExpandedAnalytics(''); return }
    setExpandedAnalytics(couponId)
    if (!analyticsMap[couponId]) { const d = await fetch(base + '/' + id + '/coupons/' + couponId + '/analytics', { headers: authHeaders }).then(r => r.json()); setAnalyticsMap((m: any) => ({ ...m, [couponId]: d.analytics })) }
  }

  const statusChip = (s: string) => {
    const map: any = { active: [GOOD, 'rgba(52,211,153,0.12)'], scheduled: [ACC, 'rgba(77,159,255,0.12)'], expired: [DIM, 'rgba(107,143,175,0.12)'], disabled: [BAD, 'rgba(248,113,113,0.12)'], draft: [WARN, 'rgba(251,191,36,0.12)'] }
    const [c, bg] = map[s] || map.draft
    return <span style={{ ...chip(c, bg), marginLeft: 6 }}>{s.toUpperCase()}</span>
  }

  const kpis = data?.kpis || {}
  const kpiCards: any[] = [
    ['total', 'Total Coupons', ACC, null],
    ['active', 'Active', GOOD, 'active'],
    ['scheduled', 'Scheduled', ACC, 'scheduled'],
    ['expired', 'Expired', DIM, 'expired'],
    ['disabled', 'Disabled', BAD, 'disabled'],
    ['totalRedemptions', 'Redemptions', '#7DD3FC', 'scroll'],
    ['revenueViaCoupons', 'Revenue ₹', '#FDE68A', 'scroll'],
    ['conversionRate', 'Conversion %', '#A78BFA', null]
  ]

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 10, marginBottom: 14 }}>
        {kpiCards.map(([key, label, color, action]) => (
          <div key={key} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: action ? 'pointer' : 'default' }}
            onClick={() => { if (action === 'scroll') analyticsRef.current?.scrollIntoView({ behavior: 'smooth' }); else if (action) setFilterStatus(action) }}>
            <div style={{ fontSize: 18, fontWeight: 800, color }}>{kpis[key] ?? 0}</div>
            <div style={{ fontSize: 9.5, color: DIM }}>{label.toUpperCase()}</div>
          </div>
        ))}
      </div>

      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10, alignItems: 'center' }}>
        {['all', 'active', 'scheduled', 'expired', 'disabled'].map(s => (
          <button key={s} style={filterStatus === s ? bp : bs} onClick={() => setFilterStatus(s)}>{s === 'all' ? 'All' : s.charAt(0).toUpperCase() + s.slice(1)}</button>
        ))}
        <select style={{ ...inp, width: 'auto' }} value={sortBy} onChange={e => setSortBy(e.target.value)}>
          <option value="newest">Newest</option>
          <option value="usage">Highest Usage</option>
          <option value="discount">Highest Discount</option>
          <option value="expiring">Expiring Soon</option>
          <option value="updated">Recently Updated</option>
        </select>
        <button style={{ ...bp, marginLeft: 'auto' }} onClick={openCreate}>+ Create Coupon</button>
      </div>

      {showForm && (
        <div style={{ ...cs, border: `1.5px solid ${BOR2}` }}>
          <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>{editingCoupon ? '✏️ Edit Coupon' : '➕ Create Coupon'}</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
            <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.code} onChange={e => setForm({ ...form, code: e.target.value.toUpperCase() })} placeholder="e.g. NEET50" /></div>
            <div><label style={lbl}>Type</label>
              <select style={inp} value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>
                <option value="percent">Percent (%)</option>
                <option value="flat">Flat (₹)</option>
              </select>
            </div>
            <div><label style={lbl}>Value {form.type === 'percent' ? '(%)' : '(₹)'}</label><input style={inp} type="number" value={form.value} onChange={e => setForm({ ...form, value: e.target.value })} /></div>
            {form.type === 'percent' && (
              <div><label style={lbl}>Max Discount ₹</label><input style={inp} type="number" value={form.maxDiscount} onChange={e => setForm({ ...form, maxDiscount: e.target.value })} /></div>
            )}
            <div><label style={lbl}>Usage Limit</label><input style={inp} type="number" value={form.usageLimit} onChange={e => setForm({ ...form, usageLimit: e.target.value })} /></div>
            <div><label style={lbl}>Per Student Limit</label>
              <select style={inp} value={form.perStudentLimitType} onChange={e => setForm({ ...form, perStudentLimitType: e.target.value })}>
                <option value="once">Once</option>
                <option value="unlimited">Unlimited</option>
                <option value="custom">Custom</option>
              </select>
            </div>
            {form.perStudentLimitType === 'custom' && (
              <div><label style={lbl}>Custom Usage Count</label><input style={inp} type="number" value={form.perStudentLimitCustom} onChange={e => setForm({ ...form, perStudentLimitCustom: e.target.value })} /></div>
            )}
            <div><label style={lbl}>Valid From</label><input style={inp} type="date" value={form.validFrom} onChange={e => setForm({ ...form, validFrom: e.target.value })} /></div>
            <div><label style={lbl}>Valid Till</label><input style={inp} type="date" value={form.validTill} onChange={e => setForm({ ...form, validTill: e.target.value })} /></div>
            <div><label style={lbl}>Applicable Plan</label>
              <select style={inp} value={form.applicablePlan} onChange={e => setForm({ ...form, applicablePlan: e.target.value })}>
                <option value="entire">Entire Batch</option>
                <option value="base_price">Base Price</option>
              </select>
            </div>
            <div><label style={lbl}>Visibility</label>
              <select style={inp} value={form.visibility} onChange={e => setForm({ ...form, visibility: e.target.value })}>
                <option value="public">Public</option>
                <option value="hidden">Hidden</option>
              </select>
            </div>
            <div><label style={lbl}>Status</label>
              <select style={inp} value={form.status} onChange={e => setForm({ ...form, status: e.target.value })}>
                <option value="draft">Draft</option>
                <option value="active">Active</option>
                <option value="disabled">Disabled</option>
              </select>
            </div>
          </div>
          <div style={{ marginTop: 8 }}>
            <label style={lbl}>Description</label>
            <input style={inp} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} placeholder="Short promo note (optional)" />
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '10px 0' }}>
            <Toggle on={!!form.autoApplyBest} onChange={v => setForm({ ...form, autoApplyBest: v })} label="Auto Apply Best Coupon" />
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={bp} onClick={submitForm}>{editingCoupon ? '💾 Save Changes' : '✅ Create Coupon'}</button>
            <button style={bs} onClick={() => setShowForm(false)}>Cancel</button>
          </div>
        </div>
      )}

      {(!data || !data.coupons) ? <EmptyMsg text="⟳ Loading coupons…" /> : data.coupons.length === 0 ? <EmptyMsg text="No coupons yet. Create your first coupon for this batch." /> : data.coupons.map((c: any) => (
        <div key={c._id} style={cs}>
          <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8 }}>
            <div>
              <div style={{ color: TS, fontWeight: 700, fontSize: 14 }}>{c.code}{statusChip(c.effectiveStatus)}</div>
              <div style={{ fontSize: 11, color: DIM, marginTop: 3 }}>{c.type === 'percent' ? `${c.value}% off` : `₹${c.value} off`}{c.maxDiscount ? ` (max ₹${c.maxDiscount})` : ''} · {c.usageCount}/{c.usageLimit} used · {c.perStudentLimitType === 'once' ? '1 per student' : c.perStudentLimitType === 'unlimited' ? 'Unlimited per student' : `${c.perStudentLimitCustom} per student`}</div>
              <div style={{ fontSize: 10.5, color: DIM, marginTop: 3 }}>Valid: {new Date(c.validFrom).toLocaleDateString()} → {new Date(c.validTill).toLocaleDateString()} · {c.applicablePlan === 'base_price' ? 'Base Price only' : 'Entire Batch'} · {c.visibility}</div>
              {c.description && <div style={{ fontSize: 11, color: DIM, marginTop: 3, fontStyle: 'italic' }}>{c.description}</div>}
              <div style={{ fontSize: 9.5, color: DIM, marginTop: 4 }}>Updated {new Date(c.updatedAt).toLocaleString()}</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 10 }}>
            <button style={bs} onClick={() => openEdit(c)}>Edit</button>
            <button style={bs} onClick={() => duplicate(c._id)}>Duplicate</button>
            {c.status === 'disabled' ? <button style={bs} onClick={() => toggleStatus(c, 'active')}>Enable</button> : <button style={bs} onClick={() => toggleStatus(c, 'disabled')}>Disable</button>}
            <button style={bs} onClick={() => viewUsage(c._id)}>{expandedUsage === c._id ? 'Hide Usage' : 'View Usage'}</button>
            <button style={bs} onClick={() => viewAnalytics(c._id)}>{expandedAnalytics === c._id ? 'Hide Analytics' : 'View Analytics'}</button>
            <button style={bd} onClick={() => del(c._id)}>Delete</button>
          </div>
          {expandedUsage === c._id && usageMap[c._id] && (
            <div style={{ marginTop: 10, paddingTop: 10, borderTop: `1px solid ${BOR}` }}>
              <div style={{ fontSize: 11.5, color: DIM, marginBottom: 6 }}>Total: {usageMap[c._id].summary.totalUses} · Unique Students: {usageMap[c._id].summary.uniqueStudents} · Revenue: ₹{usageMap[c._id].summary.revenueGenerated} · Discount Given: ₹{usageMap[c._id].summary.discountGiven}</div>
              {usageMap[c._id].usage.length === 0 ? <EmptyMsg text="No redemptions yet." /> : usageMap[c._id].usage.map((u: any, i: number) => (
                <div key={i} style={{ fontSize: 11, color: DIM, padding: '5px 0', borderBottom: `1px solid ${BOR}` }}>{u.studentName || 'Student'} · Applied ₹{u.appliedAmount} · Discount ₹{u.discountAmount} · {new Date(u.timestamp).toLocaleString()} · {u.status}</div>
              ))}
            </div>
          )}
          {expandedAnalytics === c._id && analyticsMap[c._id] && (
            <div style={{ marginTop: 10, paddingTop: 10, borderTop: `1px solid ${BOR}` }}>
              <div style={{ fontSize: 11.5, color: DIM }}>Uses: {analyticsMap[c._id].uses} · Conversion: {analyticsMap[c._id].conversionRate}% · Revenue: ₹{analyticsMap[c._id].revenueGenerated} · Discount Given: ₹{analyticsMap[c._id].discountGiven}{analyticsMap[c._id].isExpiringSoon ? ' · ⚠️ Expiring Soon' : ''}</div>
            </div>
          )}
        </div>
      ))}

      <div ref={analyticsRef} style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Coupon Analytics</div>
        {!analytics ? <EmptyMsg text="⟳ Loading analytics…" /> : (
          <div style={{ fontSize: 11.5, color: DIM, lineHeight: 1.9 }}>
            Best Performing: {analytics.bestPerforming ? `${analytics.bestPerforming.code} (${analytics.bestPerforming.usageCount} uses)` : '—'}<br />
            Lowest Performing: {analytics.lowestPerforming ? `${analytics.lowestPerforming.code} (${analytics.lowestPerforming.usageCount} uses)` : '—'}<br />
            Total Redemptions: {analytics.totalRedemptions}<br />
            Revenue Loss via Discounts: ₹{analytics.totalRevenueLoss}<br />
            Expiring Soon: {analytics.expiringSoon?.length ? analytics.expiringSoon.map((e: any) => e.code).join(', ') : 'None'}
          </div>
        )}
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════
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
  { id: 'stethoscope-il', label: 'Stethoscope', category: 'Medical (NEET)', svg: '<svg viewBox="0 0 100 100"><path d="M25 15 Q25 50 50 55 Q75 50 75 15" stroke="#FF6B6B" stroke-width="4" fill="none"/><circle cx="50" cy="70" r="10" fill="#FF6B6B"/></svg>' },
  { id: 'gear-il', label: 'Engineering Gear', category: 'Engineering (JEE)', svg: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="22" fill="none" stroke="#4D9FFF" stroke-width="6"/><circle cx="50" cy="50" r="8" fill="#4D9FFF"/></svg>' },
  { id: 'graduation-il', label: 'Graduation Cap', category: 'CUET', svg: '<svg viewBox="0 0 100 60"><polygon points="50,10 95,30 50,50 5,30" fill="#A78BFA"/><rect x="45" y="30" width="10" height="25" fill="#A78BFA"/></svg>' },
  { id: 'document-il', label: 'Govt Document', category: 'SSC', svg: '<svg viewBox="0 0 100 100"><rect x="25" y="10" width="50" height="80" rx="4" fill="none" stroke="#37474F" stroke-width="3"/><line x1="35" y1="30" x2="65" y2="30" stroke="#37474F" stroke-width="2"/><line x1="35" y1="45" x2="65" y2="45" stroke="#37474F" stroke-width="2"/></svg>' },
  { id: 'ashoka-il', label: 'Civil Services Pillar', category: 'UPSC', svg: '<svg viewBox="0 0 100 100"><rect x="40" y="20" width="20" height="60" fill="#8D6E63"/><ellipse cx="50" cy="20" rx="25" ry="8" fill="#8D6E63"/></svg>' },
  { id: 'bank-il', label: 'Bank Building', category: 'Banking', svg: '<svg viewBox="0 0 100 100"><polygon points="50,15 90,40 10,40" fill="#00796B"/><rect x="15" y="40" width="70" height="45" fill="none" stroke="#00796B" stroke-width="3"/></svg>' },
  { id: 'shield-il', label: 'Defence Shield', category: 'Defence', svg: '<svg viewBox="0 0 100 100"><path d="M50 10 L85 25 V55 Q85 80 50 95 Q15 80 15 55 V25 Z" fill="#2E7D32"/></svg>' },
  { id: 'scale-il', label: 'Justice Scale', category: 'Law', svg: '<svg viewBox="0 0 100 100"><line x1="50" y1="10" x2="50" y2="80" stroke="#B71C1C" stroke-width="3"/><line x1="20" y1="30" x2="80" y2="30" stroke="#B71C1C" stroke-width="3"/><circle cx="20" cy="45" r="10" fill="none" stroke="#B71C1C" stroke-width="2"/><circle cx="80" cy="45" r="10" fill="none" stroke="#B71C1C" stroke-width="2"/></svg>' },
  { id: 'chart-il', label: 'Business Chart', category: 'MBA', svg: '<svg viewBox="0 0 100 60"><rect x="10" y="30" width="15" height="25" fill="#FF9800"/><rect x="35" y="15" width="15" height="40" fill="#FF9800"/><rect x="60" y="5" width="15" height="50" fill="#FF9800"/></svg>' },
]

function BN_luminance(hex: string) {
  const c = (hex || '#888888').replace('#', '')
  if (c.length !== 6) return 0.5
  const r = parseInt(c.slice(0, 2), 16) / 255, g = parseInt(c.slice(2, 4), 16) / 255, b = parseInt(c.slice(4, 6), 16) / 255
  const [rl, gl, bl] = [r, g, b].map(v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4))
  return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
}
function BN_contrastRatio(hex1: string, hex2: string) {
  const l1 = BN_luminance(hex1), l2 = BN_luminance(hex2)
  const lighter = Math.max(l1, l2), darker = Math.min(l1, l2)
  return (lighter + 0.05) / (darker + 0.05)
}
function BN_titleSuggestions(name: string, examType: string) {
  const n = name || 'Your Batch', e = examType || 'NEET'
  return [n + ' — Crack ' + e + ' 2026', 'Master ' + e + ' with ' + n, n + ': Your Path to ' + e + ' Success']
}
function BN_ctaSuggestions() { return ['Enroll Now', 'Start Learning', 'Join Batch', 'Get Started', 'Claim Your Seat', 'Book Now'] }
function BN_highlightSuggestions(sp: any) {
  const s = sp || {}
  return [(s.totalTests || '0') + ' Practice Tests', (s.duration || '365 days') + ' Access', 'Expert Faculty Support', 'Detailed Performance Analytics', 'Hindi + English Both']
}
function BN_badgeSuggestions() { return ['new', 'trending', 'limitedseats', 'earlybird'] }
function BN_effPrice(b: any) { return b.discountPrice || b.price || 0 }
function BN_statusChip(s: string) {
  const map: any = { draft: [WARN, 'rgba(251,191,36,0.12)'], ready: [GOOD, 'rgba(52,211,153,0.12)'], synced: [ACC, 'rgba(77,159,255,0.12)'], pending_sync: [WARN, 'rgba(251,191,36,0.12)'], conflict: [BAD, 'rgba(248,113,113,0.12)'], manual_override: ['#A78BFA', 'rgba(167,139,250,0.12)'], removed: [BAD, 'rgba(248,113,113,0.12)'], replaced: [DIM, 'rgba(107,143,175,0.12)'], published: [GOOD, 'rgba(52,211,153,0.12)'] }
  const [c, bg] = map[s] || map.draft
  return <span style={{ ...chip(c, bg), marginLeft: 6 }}>{(s || '').replace('_', ' ').toUpperCase()}</span>
}

function BannerLivePreview({ b, size, showSafeZone, safeZoneMode, onLayerPointerDown, selectedLayerId, boxRef }: any) {
  const dims: any = { card: { w: 320, h: 200 }, wide: { w: 480, h: 200 }, square: { w: 320, h: 320 }, mobile: { w: 280, h: 420 } }
  const d = dims[size] || dims.card
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  let bg = b.bgImage ? (/^(linear|radial)-gradient|^#|^rgba?\(/.test(b.bgImage) ? b.bgImage : `url(${b.bgImage}) center/cover`) : (tpl.bg)
  if (b.gradientAngle && b.gradientAngle !== 135 && typeof bg === 'string' && bg.indexOf('135deg') >= 0) bg = bg.replace('135deg', b.gradientAngle + 'deg')
  const ctaRadius = b.ctaShape === 'square' ? 4 : b.ctaShape === 'rounded' ? 10 : 20
  const ctaIsOutline = b.ctaShape === 'outline'
  const badgeObj = BN_BADGES.find(x => x.id === b.badge)
  const safeInset = safeZoneMode === 'mobile' ? '12%' : safeZoneMode === 'desktop' ? '6%' : '8%'
  const sv = b.sectionVisibility || { icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }
  const cardRadius = b.cardStyle === 'sharp' ? 4 : b.cardStyle === 'soft' ? 20 : 14
  const cardShadow = b.cardStyle === 'elevated' ? '0 12px 28px rgba(0,0,0,0.35)' : 'none'
  const pad = b.spacing === 'compact' ? 10 : b.spacing === 'spacious' ? 24 : 16
  const badgeRadius = b.badgeStyle === 'corner' ? 0 : b.badgeStyle === 'ribbon' ? 3 : 20
  const renderLayerContent = (l: any) => {
    if (l.type === 'icon') return <span style={{ fontSize: 26 }}>{l.content}</span>
    if (!l.content) return <span style={{ fontSize: 20 }}>🖼️</span>
    if (l.content.startsWith('<svg')) return <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: l.content }} />
    // FIX: handle both data: URLs AND normal http(s) URLs (e.g. Brand
    // Kit logo/watermark links) — previously only data: URLs rendered,
    // any plain https:// image link silently fell through to the
    // placeholder emoji below.
    if (l.content.startsWith('data:image') || /^https?:\/\//.test(l.content)) {
      const hasCrop = (l.cropTop || l.cropRight || l.cropBottom || l.cropLeft)
      return <img src={l.content} style={{ width: '100%', height: '100%', objectFit: 'cover', clipPath: hasCrop ? `inset(${l.cropTop || 0}% ${l.cropRight || 0}% ${l.cropBottom || 0}% ${l.cropLeft || 0}%)` : 'none' }} />
    }
    return <span style={{ fontSize: 20 }}>🖼️</span>
  }
  return (
    <div ref={boxRef} style={{ width: d.w, height: d.h, maxWidth: '100%', borderRadius: cardRadius, boxShadow: cardShadow, position: 'relative', overflow: 'hidden', background: bg, color: b.textColor || '#fff', fontFamily: (BN_FONTS.find(f => f.id === b.fontStyle) || BN_FONTS[0]).family, border: `1px solid ${BOR}`, padding: pad, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', margin: '0 auto' }}>
      {showSafeZone && <div style={{ position: 'absolute', inset: safeInset, border: '1px dashed rgba(255,255,255,0.4)', borderRadius: 8, pointerEvents: 'none', zIndex: 50 }} />}
      {(b.layers || []).slice().sort((a: any, b2: any) => a.zIndex - b2.zIndex).map((l: any) => (
        <div key={l.id}
          onMouseDown={(e: any) => onLayerPointerDown && onLayerPointerDown(e, l.id)}
          onTouchStart={(e: any) => onLayerPointerDown && onLayerPointerDown(e, l.id)}
          style={{
            position: 'absolute', left: l.x + '%', top: l.y + '%',
            transform: `translate(-50%,-50%) scale(${l.scale}) rotate(${l.rotation}deg) scaleX(${l.flipH ? -1 : 1}) scaleY(${l.flipV ? -1 : 1})`,
            opacity: l.opacity, mixBlendMode: l.blendMode, zIndex: 10 + l.zIndex,
            cursor: l.locked ? 'not-allowed' : 'move',
            filter: l.shadow ? `drop-shadow(0 4px 6px ${l.shadowColor})` : 'none',
            border: l.border ? `${l.borderWidth}px solid ${l.borderColor}` : 'none',
            borderRadius: l.border ? 6 : 0,
            outline: selectedLayerId === l.id ? '2px dashed #4D9FFF' : 'none',
            outlineOffset: 2,
            width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden'
          }}>
          {renderLayerContent(l)}
        </div>
      ))}
      {(sv.icon !== false || sv.badge !== false) && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          {sv.icon !== false ? <span style={{ fontSize: 20 }}>{BN_EXAM_ICON[b.examType] || '📚'}</span> : <span />}
          {sv.badge !== false && badgeObj && badgeObj.id !== 'none' && <span style={{ fontSize: 9, fontWeight: 700, padding: '3px 8px', borderRadius: badgeRadius, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{badgeObj.label}</span>}
        </div>
      )}
      {(sv.title !== false || sv.tagline !== false || sv.highlights !== false) && (
        <div style={{ textAlign: (b.textAlign || 'left') as any }}>
          {sv.title !== false && (
            <div style={{
              fontSize: (b.title || '').length > 30 ? (size === 'square' ? 15 : 13) : (size === 'square' ? 18 : 16),
              fontWeight: 800, lineHeight: 1.2, overflow: 'hidden', display: '-webkit-box',
              WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any, wordBreak: 'break-word',
              ...(b.textStyleOverride || {})
            }}>{b.title || 'Batch Title'}</div>
          )}
          {sv.tagline !== false && b.tagline && <div style={{ fontSize: 10.5, opacity: 0.85, marginTop: 3 }}>{b.tagline}</div>}
          {sv.highlights !== false && (
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 6, justifyContent: b.textAlign === 'center' ? 'center' : b.textAlign === 'right' ? 'flex-end' : 'flex-start' }}>
              {(b.highlights || []).filter(Boolean).slice(0, 3).map((h: string, i: number) => (
                <span key={i} style={{ fontSize: 8.5, padding: '2px 6px', borderRadius: 6, background: 'rgba(255,255,255,0.15)' }}>{h}</span>
              ))}
            </div>
          )}
        </div>
      )}
      {(sv.price !== false || sv.cta !== false) && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          {sv.price !== false ? <span style={{ fontSize: 14, fontWeight: 800, color: b.accentColor || tpl.accent }}>{b.price && Number(b.price) > 0 ? '₹' + b.price : 'FREE'}</span> : <span />}
          {sv.cta !== false && <span style={{ fontSize: 9.5, fontWeight: 700, padding: '5px 10px', borderRadius: ctaRadius, background: ctaIsOutline ? 'transparent' : (b.accentColor || tpl.accent), color: ctaIsOutline ? (b.accentColor || tpl.accent) : '#1a1a2e', border: ctaIsOutline ? `1.5px solid ${b.accentColor || tpl.accent}` : 'none' }}>{b.ctaText || 'Enroll Now'} →</span>}
        </div>
      )}
    </div>
  )
}

function BN_IllustrationModal({ onSelect, onClose }: any) {
  const [cat, setCat] = useState('All')
  const [search, setSearch] = useState('')
  const cats = ['All', ...Array.from(new Set(BN_ILLUSTRATIONS.map(i => i.category)))]
  const list = BN_ILLUSTRATIONS.filter(i => (cat === 'All' || i.category === cat) && i.label.toLowerCase().includes(search.toLowerCase()))
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={onClose}>
      <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 480, width: '100%', maxHeight: '80vh', overflowY: 'auto', border: `1px solid ${BOR2}` }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontWeight: 700, color: TS }}>🎨 Subject Illustration Library</div>
          <button style={bs} onClick={onClose}>✕</button>
        </div>
        <input style={{ width: '100%', padding: '8px 10px', borderRadius: 8, border: `1px solid ${BOR}`, background: 'rgba(255,255,255,0.04)', color: TS, fontSize: 12, marginBottom: 10 }} placeholder="Search illustrations…" value={search} onChange={e => setSearch(e.target.value)} />
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
        {list.length === 0 && <div style={{ textAlign: 'center', padding: 20, fontSize: 11, color: DIM }}>No illustrations match your search.</div>}
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
  const [assetTab, setAssetTab] = useState('builtin')
  const [assetSearch, setAssetSearch] = useState('')
  const [brandKit, setBrandKit] = useState<any>(null)
  const [brandKits, setBrandKits] = useState<any[]>([])
  const [orgTemplates, setOrgTemplates] = useState<any[]>([])
  const [assetFilter, setAssetFilter] = useState('all')
  const [templateVersionsOpenId, setTemplateVersionsOpenId] = useState('')
  const [templateAnalytics, setTemplateAnalytics] = useState<any[]>([])
  const [ctaAnalytics, setCtaAnalytics] = useState<any[]>([])
  const [replacingLayerId, setReplacingLayerId] = useState('')
  const [expandedVersionIdx, setExpandedVersionIdx] = useState(-1)
  const [recommendedAssets, setRecommendedAssets] = useState<any[]>([])
  const [uploadingImage, setUploadingImage] = useState(false)
  const [showIntegrationSummary, setShowIntegrationSummary] = useState(true)
  const [previewTemplate, setPreviewTemplate] = useState<any>(null)
  const [illustrationSearch, setIllustrationSearch] = useState('')
  const [assetsMap, setAssetsMap] = useState<any>({ sticker: [], decorative: [], subject_graphic: [], icon: [], typography: [], background: [], cta: [] })
  const [builtinFav, setBuiltinFav] = useState<string[]>(() => { try { return JSON.parse(localStorage.getItem('pr_banner_builtin_fav') || '[]') } catch { return [] } })
  const [builtinRecent, setBuiltinRecent] = useState<string[]>(() => { try { return JSON.parse(localStorage.getItem('pr_banner_builtin_recent') || '[]') } catch { return [] } })
  const assetsBase = base.replace('/api/admin/batch-manager', '/api/admin/banner-assets').replace('/api/admin/test-series-manager', '/api/admin/banner-assets')

  const loadOrgTemplates = useCallback(() => {
    const p = new URLSearchParams()
    if (assetSearch) p.set('search', assetSearch)
    fetch(assetsBase + '/templates?' + p.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setOrgTemplates(d.templates || [])).catch(() => {})
  }, [assetSearch])
  const loadBrandKits = useCallback(() => fetch(assetsBase + '/brand-kits', { headers: authHeaders }).then(r => r.json()).then(d => setBrandKits(d.brandKits || [])).catch(() => {}), [])
  useEffect(() => { fetch(assetsBase + '/brand-kit', { headers: authHeaders }).then(r => r.json()).then(d => setBrandKit(d.brandKit)).catch(() => {}); loadBrandKits() }, [])
  useEffect(() => {
    fetch(assetsBase + '/analytics/templates', { headers: authHeaders }).then(r => r.json()).then(d => setTemplateAnalytics(d.breakdown || [])).catch(() => {})
    fetch(assetsBase + '/analytics/cta', { headers: authHeaders }).then(r => r.json()).then(d => setCtaAnalytics(d.breakdown || [])).catch(() => {})
  }, [])
  const createBrandKitPreset = async () => {
    const name = window.prompt('New Brand Kit preset name?')
    if (!name || !name.trim()) return
    const r = await fetch(assetsBase + '/brand-kits', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name: name.trim(), primaryColor: brandKit?.primaryColor, secondaryColor: brandKit?.secondaryColor, accentColor: brandKit?.accentColor, fontPair: brandKit?.fontPair, logoUrl: brandKit?.logoUrl, watermarkUrl: brandKit?.watermarkUrl }) })
    const d = await r.json()
    if (d.success) { showToast('✅ Preset created'); loadBrandKits() } else showToast('⚠️ ' + d.error)
  }
  const setDefaultBrandKit = async (kitId: string) => {
    await fetch(assetsBase + '/brand-kits/' + kitId + '/set-default', { method: 'POST', headers: authHeaders })
    const r = await fetch(assetsBase + '/brand-kit', { headers: authHeaders }); const d = await r.json()
    setBrandKit(d.brandKit); loadBrandKits(); showToast('✅ Default preset changed')
  }
  const deleteBrandKitPreset = async (kitId: string) => {
    if (!window.confirm('Delete this Brand Kit preset?')) return
    const r = await fetch(assetsBase + '/brand-kits/' + kitId, { method: 'DELETE', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Preset deleted'); loadBrandKits() } else showToast('⚠️ ' + d.error)
  }
  const toggleAssetFavorite = async (asset: any, tab: string) => {
    await fetch(assetsBase + '/assets/' + asset._id, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ isFavorite: !asset.isFavorite }) })
    fetch(assetsBase + '/assets?type=' + tab, { headers: authHeaders }).then(r => r.json()).then(d => setAssetsMap((m: any) => ({ ...m, [tab]: d.assets || [] })))
  }
  const cycleFontStyle = () => {
    const idx = BN_FONTS.findIndex(f => f.id === form.fontStyle)
    const next = BN_FONTS[(idx + 1) % BN_FONTS.length]
    setForm({ ...form, fontStyle: next.id })
    showToast('🔤 Font changed to ' + next.label)
  }
  const toggleSectionVisible = (key: string) => {
    const sv = { ...(form.sectionVisibility || { icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }) }
    sv[key] = sv[key] === false ? true : false
    setForm({ ...form, sectionVisibility: sv })
  }
  const toggleSectionLock = (key: string) => {
    const sl = { ...(form.sectionLock || {}) }
    sl[key] = !sl[key]
    setForm({ ...form, sectionLock: sl })
    showToast(sl[key] ? '🔒 ' + key + ' locked — its field is now disabled in Banner Builder' : '🔓 ' + key + ' unlocked')
  }
  useEffect(() => { loadOrgTemplates() }, [loadOrgTemplates])
  useEffect(() => {
    ['sticker', 'decorative', 'subject_graphic', 'icon', 'typography', 'background', 'cta'].forEach(t => {
      fetch(assetsBase + '/assets?type=' + t, { headers: authHeaders }).then(r => r.json()).then(d => setAssetsMap((m: any) => ({ ...m, [t]: d.assets || [] }))).catch(() => {})
    })
  }, [])

  const toggleBuiltinFav = (tid: string) => {
    setBuiltinFav(prev => { const next = prev.includes(tid) ? prev.filter(x => x !== tid) : [...prev, tid]; try { localStorage.setItem('pr_banner_builtin_fav', JSON.stringify(next)) } catch { }; return next })
  }
  const applyBuiltinTemplate = (tid: string) => {
    setForm({ ...form, template: tid })
    setBuiltinRecent(prev => { const next = [tid, ...prev.filter(x => x !== tid)].slice(0, 10); try { localStorage.setItem('pr_banner_builtin_recent', JSON.stringify(next)) } catch { }; return next })
  }
  const applyBrandKitToBanner = () => {
    if (!brandKit) return
    setForm({ ...form, primaryColor: brandKit.primaryColor, secondaryColor: brandKit.secondaryColor, accentColor: brandKit.accentColor, fontStyle: brandKit.fontPair })
    showToast('✅ Brand Kit applied to this banner')
  }
  const applyLogoToBanner = () => {
    if (!brandKit?.logoUrl) return showToast('⚠️ No Logo URL set in this Brand Kit preset yet')
    const layer = { id: 'ly_logo_' + Date.now(), type: 'logo', content: brandKit.logoUrl, x: 12, y: 12, scale: 0.5, rotation: 0, opacity: 1, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal', cropTop: 0, cropRight: 0, cropBottom: 0, cropLeft: 0 }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    showToast('✅ Logo added as a layer — drag/resize/crop it in Preview & Variants')
  }
  const applyWatermarkToBanner = () => {
    if (!brandKit?.watermarkUrl) return showToast('⚠️ No Watermark URL set in this Brand Kit preset yet')
    const layer = { id: 'ly_watermark_' + Date.now(), type: 'watermark', content: brandKit.watermarkUrl, x: 85, y: 88, scale: 0.35, rotation: 0, opacity: 0.55, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal', cropTop: 0, cropRight: 0, cropBottom: 0, cropLeft: 0 }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    showToast('✅ Watermark added as a layer — drag/resize/crop it in Preview & Variants')
  }
  const saveBrandKitField = async (patch: any) => {
    const r = await fetch(assetsBase + '/brand-kit', { method: 'PUT', headers: authHeaders, body: JSON.stringify(patch) })
    const d = await r.json()
    if (d.success) { setBrandKit(d.brandKit); showToast('✅ Brand Kit saved') } else showToast('⚠️ ' + d.error)
  }
  const saveAsOrgTemplate = async () => {
    const name = window.prompt('Template name?')
    if (!name || !name.trim()) return
    const config = { template: form.template, primaryColor: form.primaryColor, secondaryColor: form.secondaryColor, textColor: form.textColor, accentColor: form.accentColor, fontStyle: form.fontStyle, bgImage: form.bgImage, layers: form.layers || [] }
    const r = await fetch(assetsBase + '/templates', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name: name.trim(), category: 'Custom', config }) })
    const d = await r.json()
    if (d.success) { showToast('✅ Saved as template'); loadOrgTemplates() } else showToast('⚠️ ' + d.error)
  }
  const applyOrgTemplate = async (t: any) => {
    setForm({ ...form, ...t.config })
    await fetch(assetsBase + '/templates/' + t._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    loadOrgTemplates()
  }
  const toggleOrgTemplateFav = async (t: any) => { await fetch(assetsBase + '/templates/' + t._id, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ isFavorite: !t.isFavorite }) }); loadOrgTemplates() }
  const cloneOrgTemplate = async (t: any) => { await fetch(assetsBase + '/templates/' + t._id + '/clone', { method: 'POST', headers: authHeaders }); showToast('✅ Cloned'); loadOrgTemplates() }
  const deleteOrgTemplate = async (t: any) => { if (!window.confirm('Delete template "' + t.name + '"?')) return; await fetch(assetsBase + '/templates/' + t._id, { method: 'DELETE', headers: authHeaders }); showToast('✅ Deleted'); loadOrgTemplates() }
  const exportOrgTemplate = async (t: any) => {
    const r = await fetch(assetsBase + '/templates/' + t._id + '/export', { headers: authHeaders })
    const d = await r.json()
    const blob = new Blob([JSON.stringify(d.exportData, null, 2)], { type: 'application/json' })
    const link = document.createElement('a'); link.href = URL.createObjectURL(blob); link.download = t.name + '.json'; link.click()
  }
  const addAssetLayer = (asset: any) => {
    if (asset.type === 'typography') {
      // Typography presets are a TEXT STYLE, not a visual layer —
      // apply directly to the title's style instead of adding an
      // overlay (fixes: previously created a broken placeholder layer).
      try {
        const style = JSON.parse(asset.content)
        setForm({ ...form, textStyleOverride: style })
        fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
        showToast('✅ Title style applied: ' + asset.name)
      } catch (e) { showToast('⚠️ Could not apply this typography style') }
      return
    }
    const layer = { id: 'ly_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8), type: asset.type, content: asset.content, assetId: asset._id, x: 50, y: 50, scale: 1, rotation: 0, opacity: 1, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal' }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    showToast('✅ Added to banner — drag it into position in Preview & Variants')
  }

  // ── FPR5: interactive layer manipulation (drag/resize/rotate/flip/
  // shadow/border/blend/reorder) — plain React pointer events, no
  // external drag library. Edits form.layers locally; persisted via
  // the existing Save Draft / Save & Mark Ready buttons. ──
  const [selectedLayerId, setSelectedLayerId] = useState('')
  const [draggingLayerId, setDraggingLayerId] = useState('')
  const [safeZoneMode, setSafeZoneMode] = useState('default')
  const [autoSnapSafeZone, setAutoSnapSafeZone] = useState(false)

  const onLayerPointerDown = (e: any, layerId: string) => {
    const layer = (form.layers || []).find((l: any) => l.id === layerId)
    if (!layer || layer.locked) return
    setSelectedLayerId(layerId)
    setDraggingLayerId(layerId)
    e.stopPropagation()
  }
  useEffect(() => {
    if (!draggingLayerId) return
    const onMove = (e: any) => {
      const box = previewRef.current
      if (!box) return
      const rect = box.getBoundingClientRect()
      const clientX = e.touches ? e.touches[0].clientX : e.clientX
      const clientY = e.touches ? e.touches[0].clientY : e.clientY
      let x = ((clientX - rect.left) / rect.width) * 100
      let y = ((clientY - rect.top) / rect.height) * 100
      x = Math.max(0, Math.min(100, x))
      y = Math.max(0, Math.min(100, y))
      if (autoSnapSafeZone) {
        const inset = safeZoneMode === 'mobile' ? 12 : safeZoneMode === 'desktop' ? 6 : 8
        x = Math.max(inset, Math.min(100 - inset, x))
        y = Math.max(inset, Math.min(100 - inset, y))
      }
      setForm((f: any) => ({ ...f, layers: (f.layers || []).map((l: any) => l.id === draggingLayerId ? { ...l, x, y } : l) }))
    }
    const onUp = () => setDraggingLayerId('')
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    window.addEventListener('touchmove', onMove)
    window.addEventListener('touchend', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
      window.removeEventListener('touchmove', onMove)
      window.removeEventListener('touchend', onUp)
    }
  }, [draggingLayerId, autoSnapSafeZone, safeZoneMode])
  const updateLayer = (layerId: string, patch: any) => setForm((f: any) => ({ ...f, layers: (f.layers || []).map((l: any) => l.id === layerId ? { ...l, ...patch } : l) }))
  const removeLayer = (layerId: string) => { setForm((f: any) => ({ ...f, layers: (f.layers || []).filter((l: any) => l.id !== layerId) })); if (selectedLayerId === layerId) setSelectedLayerId('') }
  const duplicateLayer = (layerId: string) => {
    const layer = (form.layers || []).find((l: any) => l.id === layerId)
    if (!layer) return
    const clone = { ...layer, id: 'ly_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8), x: Math.min(95, layer.x + 5), y: Math.min(95, layer.y + 5), zIndex: (form.layers || []).length + 1 }
    setForm((f: any) => ({ ...f, layers: [...(f.layers || []), clone] }))
  }
  const moveLayerZ = (layerId: string, dir: number) => {
    setForm((f: any) => {
      const layers = [...(f.layers || [])]
      const layer = layers.find((l: any) => l.id === layerId)
      if (!layer) return f
      layer.zIndex = Math.max(0, (layer.zIndex || 0) + dir)
      return { ...f, layers }
    })
  }

  // ── FPR6: Undo/Redo, Auto-Save Draft, image-resolution check,
  // Smart Replace Colors — all local-state productivity features. ──
  const [historyStack, setHistoryStack] = useState<any[]>([])
  const [redoStack, setRedoStack] = useState<any[]>([])
  const historyTimerRef = useRef<any>(null)
  const isUndoRedoRef = useRef(false)
  const autoSaveTimerRef = useRef<any>(null)
  const [lastAutoSaved, setLastAutoSaved] = useState<any>(null)
  const [imgResWarning, setImgResWarning] = useState('')
  const [replaceFromColor, setReplaceFromColor] = useState('#4D9FFF')
  const [replaceToColor, setReplaceToColor] = useState('#4D9FFF')
  const [showSuggestions, setShowSuggestions] = useState(false)

  useEffect(() => {
    if (!form) return
    if (isUndoRedoRef.current) { isUndoRedoRef.current = false; return }
    if (historyTimerRef.current) clearTimeout(historyTimerRef.current)
    historyTimerRef.current = setTimeout(() => { setHistoryStack(prev => [...prev.slice(-19), form]); setRedoStack([]) }, 800)
    return () => { if (historyTimerRef.current) clearTimeout(historyTimerRef.current) }
  }, [form])

  useEffect(() => {
    if (!form || !data?.banner) return
    if (autoSaveTimerRef.current) clearTimeout(autoSaveTimerRef.current)
    autoSaveTimerRef.current = setTimeout(() => {
      fetch(base + '/' + id + '/banner', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }).then(r => r.json()).then(d => { if (d.success) setLastAutoSaved(new Date()) }).catch(() => {})
    }, 5000)
    return () => { if (autoSaveTimerRef.current) clearTimeout(autoSaveTimerRef.current) }
  }, [form])

  useEffect(() => {
    if (!form?.bgImage || !/^https?:\/\//.test(form.bgImage)) { setImgResWarning(''); return }
    const img = new Image()
    img.onload = () => { setImgResWarning((img.naturalWidth < 300 || img.naturalHeight < 150) ? 'Background image resolution is low — may look blurry' : '') }
    img.onerror = () => setImgResWarning('')
    img.src = form.bgImage
  }, [form?.bgImage])

  const undo = () => {
    if (historyStack.length < 2) { showToast('Nothing to undo'); return }
    const current = historyStack[historyStack.length - 1]
    const prevState = historyStack[historyStack.length - 2]
    isUndoRedoRef.current = true
    setRedoStack(r => [current, ...r])
    setHistoryStack(h => h.slice(0, -1))
    setForm(prevState)
  }
  const redo = () => {
    if (redoStack.length === 0) { showToast('Nothing to redo'); return }
    const next = redoStack[0]
    isUndoRedoRef.current = true
    setHistoryStack(h => [...h, next])
    setRedoStack(r => r.slice(1))
    setForm(next)
  }
  useEffect(() => {
    const onKey = (e: any) => {
      const tag = ((e.target && e.target.tagName) || '').toLowerCase()
      const inField = tag === 'input' || tag === 'textarea' || tag === 'select'
      if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) { e.preventDefault(); undo() }
      else if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) { e.preventDefault(); redo() }
      else if ((e.ctrlKey || e.metaKey) && e.key === 's') { e.preventDefault(); if (form?.title?.trim()) saveBanner({ saveAsDraft: true }) }
      else if ((e.key === 'Delete' || e.key === 'Backspace') && !inField && selectedLayerId) { e.preventDefault(); removeLayer(selectedLayerId) }
      else if (e.key === 'Escape') { if (replacingLayerId) setReplacingLayerId(''); else if (selectedLayerId) setSelectedLayerId('') }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [historyStack, redoStack, selectedLayerId, form, replacingLayerId])

  const smartReplaceColor = () => {
    const from = (replaceFromColor || '').toLowerCase()
    const to = replaceToColor
    const newForm: any = { ...form }
    const fields = ['primaryColor', 'secondaryColor', 'accentColor', 'textColor']
    fields.forEach(f => { if ((newForm[f] || '').toLowerCase() === from) newForm[f] = to })
    newForm.layers = (newForm.layers || []).map((l: any) => ({ ...l, shadowColor: (l.shadowColor || '').toLowerCase() === from ? to : l.shadowColor, borderColor: (l.borderColor || '').toLowerCase() === from ? to : l.borderColor }))
    setForm(newForm)
    showToast('✅ Colors replaced across banner')
  }

  const [compareList, setCompareList] = useState<any[]>([])
  const toggleCompare = (item: any) => {
    setCompareList(prev => {
      const exists = prev.find(c => c.id === item.id)
      if (exists) return prev.filter(c => c.id !== item.id)
      if (prev.length >= 2) { showToast('⚠️ You can only compare 2 at a time'); return prev }
      return [...prev, item]
    })
  }
  const resetToTemplateDefaults = () => {
    const tpl = BN_TEMPLATES.find(t => t.id === form.template) || BN_TEMPLATES[0]
    setForm({ ...form, bgImage: '', layers: [], primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: tpl.accent, ctaShape: 'pill' })
    showToast('✅ Reset to template defaults')
  }

  const uploadBannerImage = async (file: File, target: 'background' | 'layer') => {
    if (!file) return
    if (!/^image\/(png|jpe?g|webp|svg\+xml|gif)$/.test(file.type)) return showToast('⚠️ Unsupported file type — use PNG, JPG, WebP, SVG or GIF')
    if (file.size > 900000) return showToast('⚠️ Image too large (max ~900KB) — please compress first')
    setUploadingImage(true)
    try {
      const dataUrl: string = await new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = () => resolve(reader.result as string)
        reader.onerror = reject
        reader.readAsDataURL(file)
      })
      const r = await fetch(assetsBase + '/assets/upload-image', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name: file.name, dataUrl, category: 'Uploaded' }) })
      const d = await r.json()
      if (!d.success) return showToast('⚠️ ' + (d.error || 'Upload failed'))
      if (target === 'background') { setForm({ ...form, bgImage: d.asset.content }); showToast('✅ Image uploaded and set as background') }
      else { addOrReplaceAssetLayer(d.asset); showToast('✅ Image uploaded and added as a layer') }
    } catch (e) { showToast('⚠️ Upload failed — please try again') }
    setUploadingImage(false)
  }
  const duplicateVersion = async (vIdx: number) => {
    const r = await fetch(base + '/' + id + '/banner/duplicate-version/' + vIdx, { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Version duplicated'); load() } else showToast('⚠️ ' + d.error)
  }
  const importTemplateFile = async (file: File) => {
    if (!file) return
    try {
      const text = await file.text()
      const parsed = JSON.parse(text)
      const name = parsed.name || file.name.replace(/\.json$/i, '')
      const config = parsed.config || parsed
      const r = await fetch(assetsBase + '/templates/import', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name, category: parsed.category || 'Custom', config }) })
      const d = await r.json()
      if (d.success) { showToast('✅ Template imported'); loadOrgTemplates() } else showToast('⚠️ ' + d.error)
    } catch (e) { showToast('⚠️ Invalid template file — expected exported JSON') }
  }
  const restoreTemplateVersion = async (t: any, vIdx: number) => {
    const r = await fetch(assetsBase + '/templates/' + t._id + '/restore-version/' + vIdx, { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Template version restored'); loadOrgTemplates() } else showToast('⚠️ ' + d.error)
  }
  const loadRecommendedAssets = useCallback(() => {
    const p = new URLSearchParams()
    if (data?.syncPreview?.examType) p.set('examType', data.syncPreview.examType)
    fetch(assetsBase + '/assets/recommended?' + p.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setRecommendedAssets(d.assets || [])).catch(() => {})
  }, [data?.syncPreview?.examType])
  useEffect(() => { loadRecommendedAssets() }, [loadRecommendedAssets])
  const VERSION_DIFF_FIELDS: [string, string][] = [['title', 'Title'], ['tagline', 'Tagline'], ['price', 'Price'], ['ctaText', 'CTA Text'], ['template', 'Template'], ['primaryColor', 'Primary Color'], ['badge', 'Badge'], ['bgImage', 'Background Image']]
  const versionDiff = (vData: any) => {
    if (!vData || !form) return []
    return VERSION_DIFF_FIELDS.filter(([key]) => (vData[key] || '') !== (form[key] || '')).map(([key, label]) => ({ label, from: vData[key] || '—', to: form[key] || '—' }))
  }
  // TRUE "Replace Asset": unlike a simple add, this keeps the existing
  // layer's position/scale/rotation/opacity/crop/lock and only swaps
  // its content — click "🔁 Replace" on a layer, then pick any asset
  // from the library below to swap it in-place.
  const startReplaceAsset = (layerId: string) => {
    setReplacingLayerId(layerId)
    showToast('🔁 Pick an asset below to replace the selected layer (position kept)')
  }
  const addOrReplaceAssetLayer = (asset: any) => {
    if (replacingLayerId) {
      setForm({ ...form, layers: (form.layers || []).map((l: any) => l.id === replacingLayerId ? { ...l, type: asset.type, content: asset.content, assetId: asset._id } : l) })
      setReplacingLayerId('')
      showToast('✅ Layer replaced: ' + asset.name)
      fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
      return
    }
    addAssetLayer(asset)
  }

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
    if (form.bgImage && !/^https?:\/\/|^data:image/.test(form.bgImage)) warnings.push('Invalid image URL')
    if (data.syncPreview && form.price !== data.syncPreview.price) warnings.push('Price differs from current batch price — consider syncing')
    if (form.textColor && form.primaryColor && BN_contrastRatio(form.textColor, form.primaryColor) < 3) warnings.push('Low contrast between text and background — may be hard to read')
    if (form.title && form.title.length > 40) warnings.push('Title may overflow on smaller sizes — consider shortening')
    if (form.accentColor && BN_luminance(form.accentColor) < 0.25) warnings.push('CTA button color is quite dark — may reduce visibility')
    if (imgResWarning) warnings.push(imgResWarning)
    if (form.layers && form.layers.length) {
      const inset = safeZoneMode === 'mobile' ? 12 : safeZoneMode === 'desktop' ? 6 : 8
      const outside = form.layers.filter((l: any) => l.x < inset || l.x > 100 - inset || l.y < inset || l.y > 100 - inset)
      if (outside.length > 0) warnings.push(outside.length + ' layer(s) are outside the safe zone')
    }
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
                <div style={{ fontSize: 11, color: DIM, marginTop: 2 }}>Sync: {form.status === 'draft' && form.syncState === 'synced' ? 'Ready To Edit' : form.syncState?.replace('_', ' ')}</div>
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
                const isExpanded = expandedVersionIdx === realIdx
                const diff = isExpanded ? versionDiff(v.data) : []
                return (
                  <div key={realIdx} style={{ padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11.5, color: DIM, flexWrap: 'wrap', gap: 6 }}>
                      <span style={{ cursor: 'pointer' }} onClick={() => setExpandedVersionIdx(isExpanded ? -1 : realIdx)}>{isExpanded ? '▾' : '▸'} {v.label} · {new Date(v.savedAt).toLocaleString()}</span>
                      <span style={{ display: 'flex', gap: 4 }}>
                        <button style={bs} onClick={() => setExpandedVersionIdx(isExpanded ? -1 : realIdx)}>{isExpanded ? 'Hide Diff' : 'View Diff'}</button>
                        <button style={bs} onClick={() => duplicateVersion(realIdx)}>⧉ Duplicate</button>
                        <button style={bp} onClick={() => restoreVersion(realIdx)}>Restore</button>
                      </span>
                    </div>
                    {isExpanded && (
                      <div style={{ marginTop: 6, padding: 8, borderRadius: 8, background: 'rgba(77,159,255,0.05)', border: `1px solid ${BOR}` }}>
                        {diff.length === 0 ? <div style={{ fontSize: 10.5, color: DIM }}>No differences from the current live banner.</div> : diff.map((d, di) => (
                          <div key={di} style={{ fontSize: 10.5, color: DIM, padding: '3px 0' }}><b style={{ color: TS }}>{d.label}:</b> <span style={{ color: '#E74C3C' }}>{String(d.from).slice(0, 40)}</span> → <span style={{ color: '#27AE60' }}>{String(d.to).slice(0, 40)}</span></div>
                        ))}
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>✏️ Banner Builder</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
              <div><label style={lbl}>Title {(form.sectionLock || {}).title && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).title ? 0.5 : 1 }} value={form.title || ''} disabled={!!(form.sectionLock || {}).title} onChange={e => setForm({ ...form, title: e.target.value })} /></div>
              <div><label style={lbl}>Tagline / Subtitle {(form.sectionLock || {}).tagline && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).tagline ? 0.5 : 1 }} value={form.tagline || ''} disabled={!!(form.sectionLock || {}).tagline} onChange={e => setForm({ ...form, tagline: e.target.value })} /></div>
              <div><label style={lbl}>Base Price ₹ {(form.sectionLock || {}).price && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).price ? 0.5 : 1 }} value={form.price || ''} disabled={!!(form.sectionLock || {}).price} onChange={e => setForm({ ...form, price: e.target.value })} /></div>
              <div><label style={lbl}>Total Tests</label><input style={inp} value={form.totalTests || ''} onChange={e => setForm({ ...form, totalTests: e.target.value })} /></div>
              <div><label style={lbl}>Validity (read-only)</label><input style={{ ...inp, opacity: 0.6 }} value={form.validity || ''} disabled /></div>
              <div><label style={lbl}>Duration (auto)</label><input style={{ ...inp, opacity: 0.6 }} value={form.duration || ''} disabled /></div>
              <div><label style={lbl}>CTA Button Text {(form.sectionLock || {}).cta && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).cta ? 0.5 : 1 }} value={form.ctaText || ''} disabled={!!(form.sectionLock || {}).cta} onChange={e => setForm({ ...form, ctaText: e.target.value })} /></div>
              <div><label style={lbl}>Badge / Ribbon {(form.sectionLock || {}).badge && '🔒'}</label>
                <select style={{ ...inp, opacity: (form.sectionLock || {}).badge ? 0.5 : 1 }} value={form.badge || 'none'} disabled={!!(form.sectionLock || {}).badge} onChange={e => setForm({ ...form, badge: e.target.value })}>
                  {BN_BADGES.map(b => <option key={b.id} value={b.id}>{b.label}</option>)}
                </select>
              </div>
              <div><label style={lbl}>Text Alignment</label>
                <div style={{ display: 'flex', gap: 4 }}>
                  {['left', 'center', 'right'].map(al => (
                    <button key={al} style={(form.textAlign || 'left') === al ? bp : bs} onClick={() => setForm({ ...form, textAlign: al })}>{al === 'left' ? '⬅️' : al === 'center' ? '⬛' : '➡️'}</button>
                  ))}
                </div>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8, opacity: (form.sectionLock || {}).highlights ? 0.5 : 1 }}>
              {[0, 1, 2].map(i => (
                <input key={i} style={inp} disabled={!!(form.sectionLock || {}).highlights} placeholder={'Highlight ' + (i + 1) + ((form.sectionLock || {}).highlights ? ' 🔒' : '')} value={(form.highlights || [])[i] || ''} onChange={e => { const h = [...(form.highlights || ['', '', ''])]; h[i] = e.target.value; setForm({ ...form, highlights: h }) }} />
              ))}
            </div>
            <button style={{ ...bs, marginTop: 8 }} onClick={() => setShowSuggestions(v => !v)}>💡 {showSuggestions ? 'Hide' : 'Show'} Smart Suggestions</button>
            {showSuggestions && (
              <div style={{ marginTop: 8, padding: 10, borderRadius: 8, background: 'rgba(77,159,255,0.06)', border: `1px solid ${BOR}` }}>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>Title suggestions</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  {BN_titleSuggestions(data.batchName, form.examType).map((s, i) => <button key={i} style={bs} onClick={() => setForm({ ...form, title: s })}>{s}</button>)}
                </div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>CTA suggestions</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  {BN_ctaSuggestions().map((s, i) => <button key={i} style={bs} onClick={() => setForm({ ...form, ctaText: s })}>{s}</button>)}
                </div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>Highlight suggestions (click to fill next empty slot)</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  {BN_highlightSuggestions(data.syncPreview).map((s, i) => <button key={i} style={bs} onClick={() => { const h = [...(form.highlights || ['', '', ''])]; const idx = h.findIndex((x: string) => !x); if (idx >= 0) h[idx] = s; else h[0] = s; setForm({ ...form, highlights: h }) }}>{s}</button>)}
                </div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>Badge suggestions</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {BN_badgeSuggestions().map(bId => { const bObj = BN_BADGES.find(x => x.id === bId); return bObj ? <button key={bId} style={bs} onClick={() => setForm({ ...form, badge: bId })}>{bObj.label}</button> : null })}
                </div>
              </div>
            )}
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
              <div><label style={lbl}>Background Image URL</label><input style={inp} value={(form.bgImage || '').startsWith('data:') ? '(uploaded image set)' : (form.bgImage || '')} onChange={e => setForm({ ...form, bgImage: e.target.value })} placeholder="https:// or pick from library" /></div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}><button style={{ ...bs, width: '100%' }} onClick={() => setShowIllustrations(true)}>🎨 Illustration Library</button></div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}>
                <label style={{ ...bs, width: '100%', textAlign: 'center', cursor: 'pointer', display: 'block' }}>
                  {uploadingImage ? '⟳ Uploading…' : '📤 Upload (as Background)'}
                  <input type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif" style={{ display: 'none' }} disabled={uploadingImage} onChange={e => { if (e.target.files && e.target.files[0]) uploadBannerImage(e.target.files[0], 'background'); e.target.value = '' }} />
                </label>
              </div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}>
                <label style={{ ...bs, width: '100%', textAlign: 'center', cursor: 'pointer', display: 'block' }}>
                  {uploadingImage ? '⟳ Uploading…' : '📤 Upload (as Layer)'}
                  <input type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif" style={{ display: 'none' }} disabled={uploadingImage} onChange={e => { if (e.target.files && e.target.files[0]) uploadBannerImage(e.target.files[0], 'layer'); e.target.value = '' }} />
                </label>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8 }}>
              <div><label style={lbl}>Badge Style</label>
                <select style={inp} value={form.badgeStyle || 'pill'} onChange={e => setForm({ ...form, badgeStyle: e.target.value })}>
                  <option value="pill">Pill</option><option value="ribbon">Ribbon</option><option value="corner">Corner</option>
                </select>
              </div>
              <div><label style={lbl}>Card Style</label>
                <select style={inp} value={form.cardStyle || 'rounded'} onChange={e => setForm({ ...form, cardStyle: e.target.value })}>
                  <option value="sharp">Sharp</option><option value="rounded">Rounded</option><option value="soft">Soft</option><option value="elevated">Elevated</option>
                </select>
              </div>
              <div><label style={lbl}>Gradient Angle ({form.gradientAngle || 135}°)</label><input type="range" min="0" max="360" value={form.gradientAngle || 135} onChange={e => setForm({ ...form, gradientAngle: Number(e.target.value) })} style={{ width: '100%' }} /></div>
              <div><label style={lbl}>Spacing</label>
                <select style={inp} value={form.spacing || 'normal'} onChange={e => setForm({ ...form, spacing: e.target.value })}>
                  <option value="compact">Compact</option><option value="normal">Normal</option><option value="spacious">Spacious</option>
                </select>
              </div>
            </div>
            <button style={{ ...bs, marginTop: 8 }} onClick={cycleFontStyle}>🔤 Smart Replace Font (cycle)</button>
            <div style={{ marginTop: 10, marginBottom: 4 }}>
              <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>👁️ Section Visibility / Lock (Layout Controls)</div>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                {['icon', 'badge', 'title', 'tagline', 'highlights', 'price', 'cta'].map(key => {
                  const sv = form.sectionVisibility || { icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }
                  const sl = form.sectionLock || {}
                  const visible = sv[key] !== false
                  return (
                    <div key={key} style={{ display: 'flex', alignItems: 'center', gap: 3, padding: '4px 8px', borderRadius: 6, border: `1px solid ${BOR}`, opacity: visible ? 1 : 0.5 }}>
                      <span style={{ fontSize: 10.5, color: DIM, textTransform: 'capitalize' }}>{key}</span>
                      <button style={{ ...bs, padding: '1px 5px', fontSize: 10 }} onClick={() => toggleSectionVisible(key)} title={visible ? 'Hide this section' : 'Show this section'}>{visible ? '👁️' : '🚫'}</button>
                      <button style={{ ...bs, padding: '1px 5px', fontSize: 10 }} onClick={() => toggleSectionLock(key)} title={sl[key] ? 'Unlock editing' : 'Lock editing'}>{sl[key] ? '🔒' : '🔓'}</button>
                    </div>
                  )
                })}
              </div>
            </div>

            {warnings.length > 0 && (
              <div style={{ marginTop: 10, padding: 8, borderRadius: 8, background: 'rgba(251,191,36,0.1)', border: '1px solid rgba(251,191,36,0.3)' }}>
                {warnings.map((w, i) => <div key={i} style={{ fontSize: 11, color: WARN }}>⚠️ {w}</div>)}
              </div>
            )}

            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 12, alignItems: 'center' }}>
              <button style={bs} onClick={undo} disabled={historyStack.length < 2}>↶ Undo</button>
              <button style={bs} onClick={redo} disabled={redoStack.length === 0}>↷ Redo</button>
              <button style={bs} onClick={syncNow}>🔄 Sync Now</button>
              <button style={bs} onClick={() => saveBanner({ saveAsDraft: true })}>💾 Save Draft</button>
              <button style={bp} onClick={() => saveBanner({ markReady: true })}>✅ Save & Mark Ready</button>
              <button style={bs} onClick={discard}>↩️ Discard Changes</button>
              {lastAutoSaved && <span style={{ fontSize: 10, color: DIM }}>Auto-saved {lastAutoSaved.toLocaleTimeString()}</span>}
            </div>
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>👁️ Preview & Variants</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
              {['card', 'wide', 'square', 'mobile'].map(s => <button key={s} style={previewSize === s ? bp : bs} onClick={() => setPreviewSize(s)}>{s.charAt(0).toUpperCase() + s.slice(1)}</button>)}
              <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: DIM, marginLeft: 8 }}>
                <input type="checkbox" checked={showSafeZone} onChange={e => setShowSafeZone(e.target.checked)} /> Safe Zone Guide
              </label>
              <select style={{ ...inp, width: 'auto' }} value={safeZoneMode} onChange={e => setSafeZoneMode(e.target.value)}>
                <option value="default">Default Safe Zone</option>
                <option value="mobile">Mobile Safe Zone</option>
                <option value="desktop">Desktop Safe Zone</option>
              </select>
              <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: DIM }}>
                <input type="checkbox" checked={autoSnapSafeZone} onChange={e => setAutoSnapSafeZone(e.target.checked)} /> Auto Safe-Zone Snap
              </label>
              <button style={{ ...bs, marginLeft: 'auto' }} onClick={() => setShowAllVariants(v => !v)}>{showAllVariants ? 'Hide All Variants' : 'Generate All Variants'}</button>
            </div>
            <BannerLivePreview b={form} size={previewSize} showSafeZone={showSafeZone} safeZoneMode={safeZoneMode} boxRef={previewRef} onLayerPointerDown={onLayerPointerDown} selectedLayerId={selectedLayerId} />
            <div style={{ marginTop: 10 }}><button style={bs} disabled={downloading} onClick={() => downloadPNG(previewRef, previewSize)}>{downloading ? '⟳ Exporting…' : '⬇️ Download PNG (' + previewSize + ')'}</button></div>

            {form.layers && form.layers.length > 0 && (
              <div style={{ marginTop: 14, paddingTop: 14, borderTop: `1px solid ${BOR}` }}>
                <div style={{ fontWeight: 700, marginBottom: 8, color: TS, fontSize: 12 }}>🗂️ Layers ({form.layers.length})</div>
                {form.layers.slice().sort((a: any, b: any) => b.zIndex - a.zIndex).map((l: any) => (
                  <div key={l.id} onClick={() => setSelectedLayerId(l.id)} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 8px', borderRadius: 6, cursor: 'pointer', background: selectedLayerId === l.id ? 'rgba(77,159,255,0.12)' : 'transparent', fontSize: 11, color: DIM }}>
                    <span>{l.locked ? '🔒 ' : ''}{l.type}</span>
                    <span style={{ display: 'flex', gap: 4 }}>
                      <button style={{ ...bs, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); moveLayerZ(l.id, 1) }}>⬆️</button>
                      <button style={{ ...bs, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); moveLayerZ(l.id, -1) }}>⬇️</button>
                      <button style={{ ...bs, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); duplicateLayer(l.id) }}>⧉</button>
                      <button style={{ ...bd, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); removeLayer(l.id) }}>🗑️</button>
                    </span>
                  </div>
                ))}
              </div>
            )}

            {selectedLayerId && (form.layers || []).find((l: any) => l.id === selectedLayerId) && (() => {
              const layer = (form.layers || []).find((l: any) => l.id === selectedLayerId)
              return (
                <div style={{ marginTop: 14, paddingTop: 14, borderTop: `1px solid ${BOR}` }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                    <div style={{ fontWeight: 700, color: TS, fontSize: 12 }}>🔧 Layer Controls — {layer.type}</div>
                    <button style={bs} onClick={() => setSelectedLayerId('')}>✕ Close</button>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 10 }}>
                    <div><label style={lbl}>Scale ({layer.scale.toFixed(2)}x)</label><input type="range" min="0.3" max="3" step="0.05" value={layer.scale} onChange={e => updateLayer(layer.id, { scale: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                    <div><label style={lbl}>Rotation ({layer.rotation}°)</label><input type="range" min="-180" max="180" value={layer.rotation} onChange={e => updateLayer(layer.id, { rotation: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                    <div><label style={lbl}>Opacity ({Math.round(layer.opacity * 100)}%)</label><input type="range" min="0" max="1" step="0.05" value={layer.opacity} onChange={e => updateLayer(layer.id, { opacity: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                  </div>
                  <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '10px 0' }}>
                    <Toggle on={!!layer.locked} onChange={(v: boolean) => updateLayer(layer.id, { locked: v })} label="Lock" />
                    <Toggle on={!!layer.flipH} onChange={(v: boolean) => updateLayer(layer.id, { flipH: v })} label="Flip H" />
                    <Toggle on={!!layer.flipV} onChange={(v: boolean) => updateLayer(layer.id, { flipV: v })} label="Flip V" />
                    <Toggle on={!!layer.shadow} onChange={(v: boolean) => updateLayer(layer.id, { shadow: v })} label="Shadow" />
                    <Toggle on={!!layer.border} onChange={(v: boolean) => updateLayer(layer.id, { border: v })} label="Border" />
                  </div>
                  {layer.shadow && (
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 8 }}>
                      <label style={lbl}>Shadow Color</label><input type="color" value={layer.shadowColor} onChange={e => updateLayer(layer.id, { shadowColor: e.target.value })} />
                    </div>
                  )}
                  {layer.border && (
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 8 }}>
                      <label style={lbl}>Border Color</label><input type="color" value={layer.borderColor} onChange={e => updateLayer(layer.id, { borderColor: e.target.value })} />
                      <label style={lbl}>Width</label><input type="number" style={{ ...inp, width: 60 }} value={layer.borderWidth} onChange={e => updateLayer(layer.id, { borderWidth: Number(e.target.value) })} />
                    </div>
                  )}
                  <div><label style={lbl}>Blend Mode</label>
                    <select style={inp} value={layer.blendMode} onChange={e => updateLayer(layer.id, { blendMode: e.target.value })}>
                      {['normal', 'multiply', 'screen', 'overlay', 'darken', 'lighten', 'color-dodge', 'difference'].map(m => <option key={m} value={m}>{m}</option>)}
                    </select>
                  </div>
                  {['sticker', 'decorative', 'subject_graphic', 'illustration', 'logo', 'watermark', 'media'].includes(layer.type) && (
                    <div style={{ marginTop: 10, paddingTop: 10, borderTop: `1px solid ${BOR}` }}>
                      <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>✂️ Crop (Safe Zone Trim)</div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(110px,1fr))', gap: 8 }}>
                        <div><label style={lbl}>Crop Top ({layer.cropTop || 0}%)</label><input type="range" min="0" max="45" value={layer.cropTop || 0} onChange={e => updateLayer(layer.id, { cropTop: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                        <div><label style={lbl}>Crop Right ({layer.cropRight || 0}%)</label><input type="range" min="0" max="45" value={layer.cropRight || 0} onChange={e => updateLayer(layer.id, { cropRight: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                        <div><label style={lbl}>Crop Bottom ({layer.cropBottom || 0}%)</label><input type="range" min="0" max="45" value={layer.cropBottom || 0} onChange={e => updateLayer(layer.id, { cropBottom: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                        <div><label style={lbl}>Crop Left ({layer.cropLeft || 0}%)</label><input type="range" min="0" max="45" value={layer.cropLeft || 0} onChange={e => updateLayer(layer.id, { cropLeft: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                      </div>
                      {(layer.cropTop || layer.cropRight || layer.cropBottom || layer.cropLeft) ? <button style={{ ...bs, marginTop: 6 }} onClick={() => updateLayer(layer.id, { cropTop: 0, cropRight: 0, cropBottom: 0, cropLeft: 0 })}>↺ Reset Crop</button> : null}
                    </div>
                  )}
                  <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                    <button style={bs} onClick={() => duplicateLayer(layer.id)}>⧉ Duplicate</button>
                    <button style={replacingLayerId === layer.id ? bp : bs} onClick={() => startReplaceAsset(layer.id)}>🔁 {replacingLayerId === layer.id ? 'Pick asset below…' : 'Replace'}</button>
                    <button style={bd} onClick={() => removeLayer(layer.id)}>🗑️ Delete</button>
                  </div>
                </div>
              )
            })()}

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
                <div key={t.id} onClick={() => setForm({ ...form, template: t.id })} style={{ cursor: 'pointer', borderRadius: 10, height: 54, background: t.bg, border: form.template === t.id ? `2px solid ${ACC}` : `1px solid ${BOR}`, display: 'flex', alignItems: 'flex-end', padding: 4 }}>
                  <span style={{ fontSize: 8.5, color: '#fff', fontWeight: 700, textShadow: '0 1px 2px rgba(0,0,0,0.6)' }}>{t.label}</span>
                </div>
              ))}
            </div>
            <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>Color Presets</div>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
              {BN_PRESETS.map(p => (
                <div key={p.label} onClick={() => setForm({ ...form, primaryColor: p.primaryColor, secondaryColor: p.secondaryColor, textColor: p.textColor, accentColor: p.accentColor })} style={{ cursor: 'pointer', width: 46, height: 46, borderRadius: 10, background: `linear-gradient(135deg,${p.primaryColor},${p.secondaryColor})`, border: `1px solid ${BOR}`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 8, color: '#fff', fontWeight: 700 }} title={p.label}>{p.label[0]}</div>
              ))}
            </div>
            <button style={bs} onClick={() => setShowIllustrations(true)}>🎨 Open Illustration Library ({BN_ILLUSTRATIONS.length})</button>
            <div style={{ marginTop: 12, paddingTop: 12, borderTop: `1px solid ${BOR}` }}>
              <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>🔁 Smart Replace Color (across colors + all layer borders/shadows)</div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                <label style={lbl}>From</label><input type="color" value={replaceFromColor} onChange={e => setReplaceFromColor(e.target.value)} />
                <label style={lbl}>To</label><input type="color" value={replaceToColor} onChange={e => setReplaceToColor(e.target.value)} />
                <button style={bs} onClick={smartReplaceColor}>Replace</button>
              </div>
            </div>
          </div>

          <div style={cs}>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
              {[['builtin', '🖼️ Built-in'], ['mytemplates', '📁 My Templates'], ['brandkit', '🎨 Brand Kit'], ['recommended', '🤖 AI Recommended'], ['sticker', '🏷️ Stickers'], ['decorative', '✨ Decorative'], ['subject_graphic', '🧬 Subject Graphics'], ['icon', '🔣 Icons'], ['typography', '🔤 Typography'], ['background', '🌌 Backgrounds'], ['cta', '🔘 CTA Elements']].map(([k, l]) => (
                <button key={k} style={assetTab === k ? bp : bs} onClick={() => setAssetTab(k)}>{l}</button>
              ))}
            </div>

            {assetTab === 'builtin' && (
              <div>
                {builtinRecent.length > 0 && (
                  <div style={{ marginBottom: 10 }}>
                    <div style={{ fontSize: 11, color: DIM, marginBottom: 4 }}>Recently Used</div>
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                      {builtinRecent.map(tid => { const t = BN_TEMPLATES.find(x => x.id === tid); return t ? <button key={tid} style={bs} onClick={() => applyBuiltinTemplate(tid)}>{t.label}</button> : null })}
                    </div>
                  </div>
                )}
                <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>All Templates</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8 }}>
                  {BN_TEMPLATES.map(t => (
                    <div key={t.id} style={{ position: 'relative', cursor: 'pointer', borderRadius: 10, height: 54, background: t.bg, border: form.template === t.id ? `2px solid ${ACC}` : `1px solid ${BOR}`, display: 'flex', alignItems: 'flex-end', padding: 4 }} onClick={() => applyBuiltinTemplate(t.id)}>
                      <span style={{ fontSize: 8.5, color: '#fff', fontWeight: 700, textShadow: '0 1px 2px rgba(0,0,0,0.6)' }}>{t.label}</span>
                      <span onClick={(e) => { e.stopPropagation(); toggleBuiltinFav(t.id) }} style={{ position: 'absolute', top: 2, right: 4, fontSize: 12 }}>{builtinFav.includes(t.id) ? '⭐' : '☆'}</span>
                      <span onClick={(e) => { e.stopPropagation(); toggleCompare({ id: 'b_' + t.id, label: t.label, category: t.category, bg: t.bg, accent: t.accent }) }} style={{ position: 'absolute', top: 2, left: 4, fontSize: 11, background: 'rgba(0,0,0,0.4)', borderRadius: 4, padding: '0 3px' }}>⚖</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {assetTab === 'mytemplates' && (
              <div>
                <div style={{ display: 'flex', gap: 8, marginBottom: 10, flexWrap: 'wrap' }}>
                  <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder="Search my templates…" value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                  <button style={bp} onClick={saveAsOrgTemplate}>💾 Save Current As Template</button>
                  <label style={{ ...bs, cursor: 'pointer' }}>
                    📥 Import Template
                    <input type="file" accept="application/json" style={{ display: 'none' }} onChange={e => { if (e.target.files && e.target.files[0]) importTemplateFile(e.target.files[0]); e.target.value = '' }} />
                  </label>
                </div>
                {orgTemplates.length === 0 ? <EmptyMsg text="No saved templates yet." /> : orgTemplates.map((t: any) => (
                  <div key={t._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 6 }}>
                      <span style={{ fontSize: 12, color: TS }}>{t.isFavorite ? '⭐ ' : ''}{t.name} <span style={{ color: DIM, fontSize: 10 }}>({t.category} · used {t.usageCount || 0}× · v{(t.versions || []).length + 1})</span></span>
                      <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                        <button style={bs} onClick={() => setPreviewTemplate(t)}>👁 Preview</button>
                        <button style={bs} onClick={() => applyOrgTemplate(t)}>Apply</button>
                        <button style={bs} onClick={() => toggleOrgTemplateFav(t)}>{t.isFavorite ? 'Unfavorite' : 'Favorite'}</button>
                        <button style={bs} onClick={() => cloneOrgTemplate(t)}>Clone</button>
                        <button style={bs} onClick={() => exportOrgTemplate(t)}>Export</button>
                        <button style={bs} onClick={() => setTemplateVersionsOpenId(templateVersionsOpenId === t._id ? '' : t._id)}>Versions</button>
                        <button style={bd} onClick={() => deleteOrgTemplate(t)}>Delete</button>
                      </div>
                    </div>
                    {templateVersionsOpenId === t._id && (
                      <div style={{ marginTop: 6, paddingLeft: 10, borderLeft: `2px solid ${BOR}` }}>
                        {(!t.versions || t.versions.length === 0) ? <div style={{ fontSize: 10.5, color: DIM }}>No previous versions.</div> : t.versions.slice().reverse().map((v: any, i: number) => {
                          const realIdx = t.versions.length - 1 - i
                          return (
                            <div key={realIdx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 10.5, color: DIM, padding: '4px 0' }}>
                              <span>{v.label || ('v' + (realIdx + 1))} · {new Date(v.savedAt).toLocaleString()}</span>
                              <button style={bs} onClick={() => restoreTemplateVersion(t, realIdx)}>Restore</button>
                            </div>
                          )
                        })}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}

            {assetTab === 'brandkit' && brandKit && (
              <div>
                <div style={{ marginBottom: 12 }}>
                  <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>💾 Saved Brand Kits</div>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', alignItems: 'center' }}>
                    {brandKits.map((k: any) => (
                      <button key={k._id} style={k.isDefault ? bp : bs} onClick={() => !k.isDefault && setDefaultBrandKit(k._id)} title={k.isDefault ? 'Currently active preset' : 'Click to make this the active preset'}>
                        {k.isDefault ? '★ ' : ''}{k.name}
                        {!k.isDefault && <span onClick={(e) => { e.stopPropagation(); deleteBrandKitPreset(k._id) }} style={{ marginLeft: 6, opacity: 0.7 }}>✕</span>}
                      </button>
                    ))}
                    <button style={bs} onClick={createBrandKitPreset}>➕ New Preset</button>
                  </div>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginBottom: 10 }}>
                  <div><label style={lbl}>Primary</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.primaryColor} onChange={e => saveBrandKitField({ primaryColor: e.target.value })} /></div>
                  <div><label style={lbl}>Secondary</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.secondaryColor} onChange={e => saveBrandKitField({ secondaryColor: e.target.value })} /></div>
                  <div><label style={lbl}>Accent</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.accentColor} onChange={e => saveBrandKitField({ accentColor: e.target.value })} /></div>
                  <div><label style={lbl}>Font Pair</label>
                    <select style={inp} value={brandKit.fontPair} onChange={e => saveBrandKitField({ fontPair: e.target.value })}>
                      {BN_FONTS.map(f => <option key={f.id} value={f.id}>{f.label}</option>)}
                    </select>
                  </div>
                  <div><label style={lbl}>Logo URL</label><input style={inp} value={brandKit.logoUrl || ''} onChange={e => setBrandKit({ ...brandKit, logoUrl: e.target.value })} onBlur={e => saveBrandKitField({ logoUrl: e.target.value })} /></div>
                  <div><label style={lbl}>Watermark URL</label><input style={inp} value={brandKit.watermarkUrl || ''} onChange={e => setBrandKit({ ...brandKit, watermarkUrl: e.target.value })} onBlur={e => saveBrandKitField({ watermarkUrl: e.target.value })} /></div>
                </div>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <button style={bp} onClick={applyBrandKitToBanner}>✅ Apply Brand Kit to This Banner</button>
                  <button style={bs} onClick={applyLogoToBanner}>🏷️ Apply Official Logo</button>
                  <button style={bs} onClick={applyWatermarkToBanner}>💧 Apply Watermark</button>
                </div>
              </div>
            )}

            {['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].includes(assetTab) && (
              <div>
                {replacingLayerId && <div style={{ fontSize: 10.5, color: '#FFD700', marginBottom: 8, padding: '6px 8px', borderRadius: 6, background: 'rgba(255,215,0,0.08)' }}>🔁 Replace mode — pick any asset to swap it into the selected layer. <span style={{ cursor: 'pointer', textDecoration: 'underline' }} onClick={() => setReplacingLayerId('')}>Cancel</span></div>}
                <div style={{ display: 'flex', gap: 6, marginBottom: 8, flexWrap: 'wrap' }}>
                  <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder={'Search ' + assetTab + '…'} value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                  {['all', 'favorites', 'recent', 'most_used'].map(f => <button key={f} style={assetFilter === f ? bp : bs} onClick={() => setAssetFilter(f)}>{f === 'all' ? 'All' : f === 'favorites' ? '⭐ Favorites' : f === 'recent' ? 'Recent' : 'Most Used'}</button>)}
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(80px,1fr))', gap: 8 }}>
                  {(assetsMap[assetTab] || [])
                    .filter((a: any) => a.name.toLowerCase().includes(assetSearch.toLowerCase()))
                    .filter((a: any) => assetFilter !== 'favorites' || a.isFavorite)
                    .slice().sort((a: any, b: any) => assetFilter === 'recent' ? (new Date(b.lastUsedAt || 0).getTime() - new Date(a.lastUsedAt || 0).getTime()) : assetFilter === 'most_used' ? ((b.usageCount || 0) - (a.usageCount || 0)) : 0)
                    .map((a: any) => (
                    <div key={a._id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer', padding: 8, position: 'relative' }} title={a.name}>
                      <span onClick={(e) => { e.stopPropagation(); toggleAssetFavorite(a, assetTab) }} style={{ position: 'absolute', top: 2, right: 4, fontSize: 11 }}>{a.isFavorite ? '⭐' : '☆'}</span>
                      <div onClick={() => addOrReplaceAssetLayer(a)} style={{ width: 40, height: 40, margin: '0 auto 4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {a.type === 'icon' ? <span style={{ fontSize: 24 }}>{a.content}</span> : a.type === 'typography' ? <span style={{ fontSize: 10, color: TS }}>Aa</span> : <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: a.content }} />}
                      </div>
                      <div onClick={() => addOrReplaceAssetLayer(a)} style={{ fontSize: 8.5, color: DIM }}>{a.name}</div>
                    </div>
                  ))}
                </div>
                {(assetsMap[assetTab] || []).length === 0 && <EmptyMsg text="No assets yet — run the one-time seed from the admin setup, or contact support." />}
              </div>
            )}

            {assetTab === 'recommended' && (
              <div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 10, lineHeight: 1.6 }}>🤖 Recommended from the asset library based on this batch's exam type — a keyword-matching engine, not generative AI (no image-gen API is configured).</div>
                {recommendedAssets.length === 0 ? <EmptyMsg text="No recommendations yet — try adding more assets to the library." /> : (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(80px,1fr))', gap: 8 }}>
                    {recommendedAssets.map((a: any) => (
                      <div key={a._id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer', padding: 8, position: 'relative' }} onClick={() => addOrReplaceAssetLayer(a)} title={a.name}>
                        <span style={{ position: 'absolute', top: 2, right: 4, fontSize: 9 }}>🤖</span>
                        <div style={{ width: 40, height: 40, margin: '0 auto 4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          {a.type === 'icon' ? <span style={{ fontSize: 24 }}>{a.content}</span> : a.type === 'typography' ? <span style={{ fontSize: 10, color: TS }}>Aa</span> : a.type === 'media' ? <img src={a.content} style={{ maxWidth: '100%', maxHeight: '100%' }} /> : <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: a.content }} />}
                        </div>
                        <div style={{ fontSize: 8.5, color: DIM }}>{a.name}</div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {assetTab === 'background' && (
              <div>
                <input style={{ ...inp, marginBottom: 10 }} placeholder="Search backgrounds…" value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8 }}>
                  {(assetsMap.background || []).filter((a: any) => a.name.toLowerCase().includes(assetSearch.toLowerCase())).map((a: any) => (
                    <div key={a._id} onClick={() => { setForm({ ...form, bgImage: a.content }); fetch(assetsBase + '/assets/' + a._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {}); showToast('✅ Background applied') }} style={{ cursor: 'pointer', borderRadius: 10, height: 50, background: a.content, border: form.bgImage === a.content ? `2px solid ${ACC}` : `1px solid ${BOR}` }} title={a.name} />
                  ))}
                </div>
                {(assetsMap.background || []).length === 0 && <EmptyMsg text="No backgrounds yet — run the one-time seed." />}
              </div>
            )}

            {assetTab === 'cta' && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(110px,1fr))', gap: 10 }}>
                {(assetsMap.cta || []).map((a: any) => (
                  <div key={a._id} onClick={() => { setForm({ ...form, ctaShape: a.content }); fetch(assetsBase + '/assets/' + a._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {}) }} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer', padding: 10 }}>
                    <span style={{ display: 'inline-block', fontSize: 10, fontWeight: 700, padding: '5px 12px', borderRadius: a.content === 'square' ? 4 : a.content === 'rounded' ? 10 : 20, background: a.content === 'outline' ? 'transparent' : '#FFD700', color: a.content === 'outline' ? '#FFD700' : '#1a1a2e', border: a.content === 'outline' ? '1.5px solid #FFD700' : 'none' }}>Enroll →</span>
                    <div style={{ fontSize: 9, color: DIM, marginTop: 6 }}>{a.name}</div>
                  </div>
                ))}
                {(assetsMap.cta || []).length === 0 && <EmptyMsg text="No CTA styles yet — run the one-time seed." />}
              </div>
            )}

            <div style={{ marginTop: 14, paddingTop: 14, borderTop: `1px solid ${BOR}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                <div style={{ fontWeight: 700, color: TS, fontSize: 12 }}>⚖️ Compare Templates ({compareList.length}/2)</div>
                {compareList.length > 0 && <button style={bs} onClick={() => setCompareList([])}>Clear</button>}
              </div>
              <div style={{ fontSize: 10.5, color: DIM, marginBottom: 8 }}>Click ⚖ on a Built-in or My Template card above to add it here (max 2).</div>
              {compareList.length === 2 && (
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                  {compareList.map((c: any, i: number) => (
                    <div key={i} style={cs}>
                      <div style={{ fontWeight: 700, color: TS, fontSize: 12, marginBottom: 6 }}>{c.label}</div>
                      <div style={{ height: 50, borderRadius: 8, background: c.bg, marginBottom: 6 }} />
                      <div style={{ fontSize: 10.5, color: DIM }}>Category: {c.category}</div>
                      <div style={{ fontSize: 10.5, color: DIM }}>Accent: <span style={{ color: c.accent }}>■</span> {c.accent}</div>
                    </div>
                  ))}
                </div>
              )}
              <button style={{ ...bs, marginTop: 10 }} onClick={resetToTemplateDefaults}>↺ Reset to Template Defaults</button>
            </div>
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Analytics</div>
            {!analytics ? <EmptyMsg text="No analytics yet." /> : (
              <div style={{ fontSize: 11.5, color: DIM, lineHeight: 1.9 }}>
                Views: {analytics.views} · Clicks: {analytics.clicks} · Enrolls: {analytics.enrolls}<br />
                Click Rate: {analytics.clickRate}% · Conversion Rate: {analytics.conversionRate}%
              </div>
            )}
            <div style={{ marginTop: 12, paddingTop: 12, borderTop: `1px solid ${BOR}` }}>
              <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>📈 Performance by Template (platform-wide)</div>
              {templateAnalytics.length === 0 ? <div style={{ fontSize: 10.5, color: DIM }}>Not enough data yet.</div> : templateAnalytics.slice(0, 5).map((t: any, i: number) => (
                <div key={i} style={{ fontSize: 10.5, color: DIM, padding: '3px 0' }}>{t.template}{form.template === t.template ? ' (current)' : ''} — {t.count} banner(s) · {t.conversionRate}% conversion</div>
              ))}
              <div style={{ fontSize: 11, color: DIM, margin: '10px 0 6px' }}>🔘 Performance by CTA (platform-wide)</div>
              {ctaAnalytics.length === 0 ? <div style={{ fontSize: 10.5, color: DIM }}>Not enough data yet.</div> : ctaAnalytics.slice(0, 5).map((c: any, i: number) => (
                <div key={i} style={{ fontSize: 10.5, color: DIM, padding: '3px 0' }}>{c.cta} — {c.count} banner(s) · {c.conversionRate}% conversion</div>
              ))}
            </div>
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📋 Audit Trail</div>
            {(!audit || audit.length === 0) ? <EmptyMsg text="No audit entries yet." /> : audit.map((a: any, i: number) => (
              <div key={i} style={{ fontSize: 11, color: DIM, padding: '5px 0', borderBottom: `1px solid ${BOR}` }}>{a.action} · by {a.performedByName || 'Admin'} · {new Date(a.timestamp).toLocaleString()}</div>
            ))}
          </div>

          <div style={cs}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: showIntegrationSummary ? 10 : 0, cursor: 'pointer' }} onClick={() => setShowIntegrationSummary(v => !v)}>
              <div style={{ fontWeight: 700, color: TS }}>📎 Integration Summary</div>
              <span style={{ fontSize: 11, color: DIM }}>{showIntegrationSummary ? '▾ Hide' : '▸ Show'}</span>
            </div>
            {showIntegrationSummary && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 10, fontSize: 11, color: DIM, lineHeight: 1.9 }}>
                <div>🔗 Linked Product: <b style={{ color: TS }}>{data.batchName}</b></div>
                <div>📌 Banner Status: <b style={{ color: TS }}>{form.status}</b></div>
                <div>🔄 Sync State: <b style={{ color: TS }}>{(form.syncState || '—').replace('_', ' ')}</b></div>
                <div>⭐ Quality Score: <b style={{ color: (data.overview?.qualityScore || 0) >= 60 ? GOOD : WARN }}>{data.overview?.qualityScore || 0}/100</b></div>
                <div>🕐 Versions Saved: <b style={{ color: TS }}>{(form.versions || []).length}</b></div>
                <div>🗂️ Layers Placed: <b style={{ color: TS }}>{(form.layers || []).length}</b></div>
                <div>👁️ Views: <b style={{ color: TS }}>{analytics?.views ?? 0}</b> · Clicks: <b style={{ color: TS }}>{analytics?.clicks ?? 0}</b> · Enrolls: <b style={{ color: TS }}>{analytics?.enrolls ?? 0}</b></div>
                <div>📋 Last Audit Action: <b style={{ color: TS }}>{audit && audit.length > 0 ? audit[0].action : '—'}</b></div>
                <div>🕒 Last Updated: <b style={{ color: TS }}>{form.updatedAt ? new Date(form.updatedAt).toLocaleString() : '—'}</b></div>
              </div>
            )}
          </div>

          <div style={{ ...cs, fontSize: 11, color: DIM }}>
            🔗 This banner is linked to <b style={{ color: TS }}>{data.batchName}</b>. Publish / Launch happens in the separate Publish Center (coming soon) — not from this tab.
          </div>
        </>
      )}

      {showIllustrations && <BN_IllustrationModal onSelect={(url: string) => setForm({ ...form, bgImage: url })} onClose={() => setShowIllustrations(false)} />}
      {previewTemplate && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={() => setPreviewTemplate(null)}>
          <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 420, width: '100%', border: `1px solid ${BOR2}` }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
              <div style={{ fontWeight: 700, color: TS }}>👁 Preview — {previewTemplate.name}</div>
              <button style={bs} onClick={() => setPreviewTemplate(null)}>✕</button>
            </div>
            <BannerLivePreview b={{ ...form, ...previewTemplate.config }} size="card" showSafeZone={false} />
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              <button style={{ ...bs, flex: 1 }} onClick={() => setPreviewTemplate(null)}>Cancel</button>
              <button style={{ ...bp, flex: 1 }} onClick={() => { applyOrgTemplate(previewTemplate); setPreviewTemplate(null) }}>✅ Apply This Template</button>
            </div>
          </div>
        </div>
      )}
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
