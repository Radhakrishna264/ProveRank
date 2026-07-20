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
