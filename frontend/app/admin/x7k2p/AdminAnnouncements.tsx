'use client'
import { useState, useEffect, useRef, useMemo, createContext, useContext } from 'react'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const DEFAULT_THEME = {
  CRD: 'rgba(0,28,52,0.88)', ACC: '#4D9FFF', BOR: 'rgba(77,159,255,0.18)',
  TS: '#E8F4FF', DIM: '#6B8FAF', SUC: '#00C48C', DNG: '#FF4D4D', WRN: '#FFB84D', GOLD: '#FFD700',
}
const ThemeCtx = createContext(DEFAULT_THEME)

const TYPES = [
  { v: 'exam',   l: 'Exam',   ico: '📝', col: '#4D9FFF' },
  { v: 'update', l: 'Update', ico: '✨', col: '#00C48C' },
  { v: 'result', l: 'Result', ico: '🏅', col: '#FFD700' },
  { v: 'maintenance', l: 'Maintenance', ico: '🔧', col: '#A855F7' },
  { v: 'urgent', l: 'Urgent', ico: '🚨', col: '#FF4D4D' },
]
const typeInfo = (v: string) => TYPES.find(t => t.v === v) || TYPES[1]

function fmt(d: any) { if (!d) return '—'; try { return new Date(d).toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) } catch { return '—' } }

function Badge({ children, col, bg }: any) {
  const theme = useContext(ThemeCtx)
  const c = col || theme.ACC
  return <span style={{ fontSize: 9.5, fontWeight: 700, color: c, background: bg || `${c}22`, padding: '2px 8px', borderRadius: 6, border: `1px solid ${c}44` }}>{children}</span>
}
function Card({ title, icon, children, style }: any) {
  const theme = useContext(ThemeCtx)
  return (
    <div style={{ background: theme.CRD, border: `1px solid ${theme.BOR}`, borderRadius: 14, padding: 18, marginBottom: 14, backdropFilter: 'blur(12px)', ...style }}>
      {title && <div style={{ fontWeight: 700, marginBottom: 12, fontSize: 13, color: theme.TS, display: 'flex', alignItems: 'center', gap: 7 }}>{icon} {title}</div>}
      {children}
    </div>
  )
}
function Lbl({ children }: any) {
  const theme = useContext(ThemeCtx)
  return <label style={{ display: 'block', fontSize: 11, color: theme.DIM, marginBottom: 5, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>{children}</label>
}

export default function AdminAnnouncements({ token, toast, theme }: { token: string; toast?: (msg: string, tp?: 's' | 'e' | 'w') => void; theme?: Partial<typeof DEFAULT_THEME> }) {
  const T = { ...DEFAULT_THEME, ...(theme || {}) }
  const notify = (msg: string, tp: 's' | 'e' | 'w' = 's') => toast ? toast(msg, tp) : (typeof window !== 'undefined' && window.alert(msg))

  const inp: any = { width: '100%', padding: '11px 13px', background: 'rgba(0,22,40,0.85)', border: `1.5px solid ${T.BOR}`, borderRadius: 10, color: T.TS, fontSize: 13, fontFamily: 'Inter,sans-serif', outline: 'none', boxSizing: 'border-box' }
  const btnP: any = { background: `linear-gradient(135deg,${T.ACC},#0055CC)`, color: '#fff', border: 'none', borderRadius: 10, padding: '11px 22px', cursor: 'pointer', fontWeight: 700, fontSize: 13 }
  const btnGhost: any = { background: 'rgba(77,159,255,0.1)', color: T.ACC, border: `1px solid ${T.BOR}`, borderRadius: 10, padding: '9px 18px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
  const btnDng: any = { background: 'rgba(255,77,77,0.15)', color: T.DNG, border: '1px solid rgba(255,77,77,0.3)', borderRadius: 10, padding: '9px 16px', cursor: 'pointer', fontWeight: 700, fontSize: 11.5 }

  // ── Compose state ──
  const [editingId, setEditingId] = useState<string | null>(null)
  const [title, setTitle] = useState(''); const [titleHi, setTitleHi] = useState('')
  const [message, setMessage] = useState(''); const [messageHi, setMessageHi] = useState('')
  const [showBilingual, setShowBilingual] = useState(false)
  const [type, setType] = useState('update')
  const [audienceMode, setAudienceMode] = useState<'all' | 'batch' | 'testseries' | 'students'>('all')
  const [selBatchIds, setSelBatchIds] = useState<string[]>([])
  const [selTestSeriesIds, setSelTestSeriesIds] = useState<string[]>([])
  const [studentQuery, setStudentQuery] = useState('')
  const [studentResults, setStudentResults] = useState<any[]>([])
  const [selStudents, setSelStudents] = useState<any[]>([])
  const [sendVia, setSendVia] = useState<'in-app' | 'email' | 'both'>('in-app')
  const [pinned, setPinned] = useState(false)
  const [imageUrl, setImageUrl] = useState('')
  const [scheduleMode, setScheduleMode] = useState<'now' | 'schedule'>('now')
  const [scheduledAt, setScheduledAt] = useState('')
  const [expiryDate, setExpiryDate] = useState('')
  const [sending, setSending] = useState(false)
  const [previewOpen, setPreviewOpen] = useState(false)
  const msgRef = useRef<HTMLTextAreaElement>(null)

  // ── Data ──
  const [batches, setBatches] = useState<any[]>([])
  const [templates, setTemplates] = useState<any[]>([])
  const [stats, setStats] = useState<any>({ totalSent: 0, thisWeek: 0, avgReadRate: 0, scheduled: 0 })
  const [history, setHistory] = useState<any[]>([])
  const [historyLoading, setHistoryLoading] = useState(true)
  const [expandedDelivery, setExpandedDelivery] = useState<string | null>(null)
  const [deliveryData, setDeliveryData] = useState<any>(null)

  // ── Filters ──
  const [fSearch, setFSearch] = useState(''); const [fType, setFType] = useState(''); const [fAudience, setFAudience] = useState('')
  const [fDateFrom, setFDateFrom] = useState(''); const [fDateTo, setFDateTo] = useState('')

  const headers = { Authorization: `Bearer ${token}` }
  const jsonHeaders = { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }

  const loadBatches = () => fetch(`${API}/api/admin/announcements/batches`, { headers }).then(r => r.json()).then(d => setBatches(Array.isArray(d) ? d : [])).catch(() => {})
  const loadTemplates = () => fetch(`${API}/api/admin/announcements/templates`, { headers }).then(r => r.json()).then(d => setTemplates(Array.isArray(d) ? d : [])).catch(() => {})
  const loadStats = () => fetch(`${API}/api/admin/announcements/stats`, { headers }).then(r => r.json()).then(d => setStats(d)).catch(() => {})
  const loadHistory = () => {
    setHistoryLoading(true)
    const qs = new URLSearchParams()
    if (fSearch) qs.set('search', fSearch)
    if (fType) qs.set('type', fType)
    if (fAudience) qs.set('audienceMode', fAudience)
    if (fDateFrom) qs.set('dateFrom', fDateFrom)
    if (fDateTo) qs.set('dateTo', fDateTo)
    fetch(`${API}/api/admin/announcements?${qs.toString()}`, { headers }).then(r => r.json()).then(d => setHistory(Array.isArray(d) ? d : [])).catch(() => {}).finally(() => setHistoryLoading(false))
  }

  useEffect(() => { if (token) { loadBatches(); loadTemplates(); loadStats(); loadHistory() } }, [token])
  useEffect(() => { if (token) loadHistory() }, [fSearch, fType, fAudience, fDateFrom, fDateTo])

  // ── Student smart-search (debounced) ──
  useEffect(() => {
    if (!studentQuery.trim()) { setStudentResults([]); return }
    const h = setTimeout(() => {
      fetch(`${API}/api/admin/announcements/students-search?q=${encodeURIComponent(studentQuery)}`, { headers }).then(r => r.json()).then(d => setStudentResults(Array.isArray(d) ? d : [])).catch(() => {})
    }, 350)
    return () => clearTimeout(h)
  }, [studentQuery])

  const charCount = message.replace(/<[^>]*>/g, '').length

  // ── Rich text toolbar (wrap selected text) ──
  const wrapSelection = (tag: 'b' | 'i' | 'a') => {
    const el = msgRef.current; if (!el) return
    const start = el.selectionStart, end = el.selectionEnd
    const selected = message.slice(start, end) || 'text'
    let insert = `<b>${selected}</b>`
    if (tag === 'i') insert = `<i>${selected}</i>`
    if (tag === 'a') { const url = window.prompt('Link URL:', 'https://') || '#'; insert = `<a href="${url}" target="_blank">${selected}</a>` }
    const next = message.slice(0, start) + insert + message.slice(end)
    setMessage(next)
    setTimeout(() => el.focus(), 0)
  }

  const applyTemplate = (tpl: any) => { setType(tpl.type); setTitle(tpl.title); setMessage(tpl.message) }

  const resetCompose = () => {
    setEditingId(null); setTitle(''); setTitleHi(''); setMessage(''); setMessageHi(''); setShowBilingual(false)
    setType('update'); setAudienceMode('all'); setSelBatchIds([]); setSelTestSeriesIds([]); setSelStudents([]); setStudentQuery(''); setStudentResults([])
    setSendVia('in-app'); setPinned(false); setImageUrl(''); setScheduleMode('now'); setScheduledAt(''); setExpiryDate('')
  }

  const buildAudience = () => {
    if (audienceMode === 'batch') return { mode: 'batch', batchIds: selBatchIds }
    if (audienceMode === 'testseries') return { mode: 'testseries', testSeriesIds: selTestSeriesIds }
    if (audienceMode === 'students') return { mode: 'students', studentIds: selStudents.map(s => s._id) }
    return { mode: 'all' }
  }

  const doSend = async (asDraft = false) => {
    if (!title.trim() || !message.trim()) { notify('Title and message are required', 'e'); return }
    if (audienceMode === 'batch' && selBatchIds.length === 0) { notify('Select at least one batch', 'e'); return }
    if (audienceMode === 'testseries' && selTestSeriesIds.length === 0) { notify('Select at least one test series', 'e'); return }
    if (audienceMode === 'students' && selStudents.length === 0) { notify('Select at least one student', 'e'); return }
    setSending(true)
    try {
      const body: any = {
        title, titleHi, message, messageHi, type, sendVia, pinned, imageUrl,
        audience: buildAudience(),
        expiryDate: expiryDate || null,
        saveAsDraft: asDraft,
        scheduledAt: scheduleMode === 'schedule' ? scheduledAt : null,
      }
      const url = editingId ? `${API}/api/admin/announcements/${editingId}` : `${API}/api/admin/announcements`
      const method = editingId ? 'PUT' : 'POST'
      const r = await fetch(url, { method, headers: jsonHeaders, body: JSON.stringify(body) })
      const d = await r.json()
      if (!r.ok) { notify(d.message || 'Failed', 'e'); setSending(false); return }
      notify(d.message || 'Success', 's')
      resetCompose(); loadHistory(); loadStats()
    } catch (e) { notify('Network error', 'e') }
    setSending(false)
  }

  const doEdit = (a: any) => {
    setEditingId(a._id); setTitle(a.title); setTitleHi(a.titleHi || ''); setMessage(a.message); setMessageHi(a.messageHi || '')
    setShowBilingual(!!a.titleHi || !!a.messageHi)
    setType(a.type); setPinned(!!a.pinned); setImageUrl(a.imageUrl || ''); setSendVia(a.sendVia || 'in-app')
    setExpiryDate(a.expiryDate ? String(a.expiryDate).slice(0, 10) : '')
    const mode = a.audience?.mode || 'all'
    setAudienceMode(mode)
    setSelBatchIds(mode === 'batch' ? (a.audience.batchIds || []).map((b: any) => b._id || b) : [])
    setSelTestSeriesIds(mode === 'testseries' ? (a.audience.testSeriesIds || []).map((b: any) => b._id || b) : [])
    setSelStudents([])
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const doDelete = async (id: string) => {
    if (!window.confirm('Delete this announcement permanently?')) return
    try {
      const r = await fetch(`${API}/api/admin/announcements/${id}`, { method: 'DELETE', headers })
      if (r.ok) { notify('Deleted', 's'); loadHistory(); loadStats() } else notify('Failed', 'e')
    } catch (e) { notify('Network error', 'e') }
  }

  const doResend = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/admin/announcements/${id}/resend`, { method: 'POST', headers })
      const d = await r.json()
      if (r.ok) { notify(d.message || 'Resent', 's'); loadHistory(); loadStats() } else notify(d.message || 'Failed', 'e')
    } catch (e) { notify('Network error', 'e') }
  }

  // v2 §4 — Duplicate as DRAFT (does not send) — distinct from Resend (sends immediately)
  const doDuplicate = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/admin/announcements/${id}/duplicate`, { method: 'POST', headers })
      const d = await r.json()
      if (r.ok) { notify(d.message || 'Duplicated as draft', 's'); loadHistory() } else notify(d.message || 'Failed', 'e')
    } catch (e) { notify('Network error', 'e') }
  }

  const toggleDelivery = async (id: string) => {
    if (expandedDelivery === id) { setExpandedDelivery(null); return }
    setExpandedDelivery(id)
    try { const r = await fetch(`${API}/api/admin/announcements/${id}/delivery`, { headers }); setDeliveryData(await r.json()) } catch (e) {}
  }

  const cardStyle = { display: 'flex', flexDirection: 'column' as const, gap: 10 }

  return (
    <ThemeCtx.Provider value={T}>
      <div>
        <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: T.TS, margin: '0 0 4px' }}>📢 Announcements</div>
        <div style={{ fontSize: 12, color: T.DIM, marginBottom: 16 }}>Send broadcasts to all students or specific batches</div>

        {/* §1.1.3 PageHero-style banner */}
        <div style={{ background: `linear-gradient(135deg, rgba(77,159,255,0.1), rgba(0,20,40,0.4))`, border: `1px solid ${T.BOR}`, borderRadius: 16, padding: '20px 22px', marginBottom: 16, display: 'flex', gap: 14, alignItems: 'center' }}>
          <div style={{ fontSize: 34 }}>📢</div>
          <div>
            <div style={{ fontWeight: 800, fontSize: 15, color: T.TS }}>Platform Broadcast Center</div>
            <div style={{ fontSize: 11.5, color: T.DIM, marginTop: 3 }}>Send announcements via in-app notifications, email, or both. Target all students, specific batches, or individual students. Schedule for later or save as a draft.</div>
          </div>
        </div>

        {/* §3.4 Stats bar */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(130px,1fr))', gap: 10, marginBottom: 16 }}>
          {[
            { l: 'Total Sent', v: stats.totalSent, c: T.ACC, i: '📤' },
            { l: 'This Week', v: stats.thisWeek, c: T.SUC, i: '📅' },
            { l: 'Avg. Read Rate', v: `${stats.avgReadRate}%`, c: T.GOLD, i: '👁️' },
            { l: 'Scheduled', v: stats.scheduled, c: T.WRN, i: '⏰' },
          ].map((s, i) => (
            <div key={i} style={{ background: T.CRD, border: `1px solid ${T.BOR}`, borderRadius: 14, padding: '14px 10px', textAlign: 'center' }}>
              <div style={{ fontSize: 18 }}>{s.i}</div>
              <div style={{ fontSize: 18, fontWeight: 800, color: s.c, marginTop: 4 }}>{s.v}</div>
              <div style={{ fontSize: 9.5, color: T.DIM, marginTop: 2, fontWeight: 600 }}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* §1.2/§2.1/§3.1 COMPOSE CARD */}
        <Card title={editingId ? '✏️ Edit Announcement' : '✍️ Compose Announcement'} icon="">
          {/* Templates quick-fill (§2.4.1) */}
          {!editingId && templates.length > 0 && (
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 14 }}>
              {templates.map((tpl, i) => (
                <button key={i} onClick={() => applyTemplate(tpl)} style={{ ...btnGhost, fontSize: 10.5, padding: '6px 12px' }}>📋 {tpl.name}</button>
              ))}
            </div>
          )}

          {/* Type selector — 4 colored pills (§3.1.1) */}
          <Lbl>Type / Category</Lbl>
          <div style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' }}>
            {TYPES.map(tp => (
              <button key={tp.v} onClick={() => setType(tp.v)} style={{
                display: 'flex', alignItems: 'center', gap: 6, padding: '8px 16px', borderRadius: 99,
                border: `1.5px solid ${type === tp.v ? tp.col : T.BOR}`,
                background: type === tp.v ? `${tp.col}22` : 'transparent',
                boxShadow: type === tp.v ? `0 0 14px ${tp.col}55` : 'none',
                color: type === tp.v ? tp.col : T.DIM, fontWeight: 700, fontSize: 12, cursor: 'pointer',
              }}>{tp.ico} {tp.l}</button>
            ))}
          </div>

          {/* Title (+ bilingual toggle §2.1.7) */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Lbl>Title</Lbl>
            <button onClick={() => setShowBilingual(!showBilingual)} style={{ ...btnGhost, fontSize: 10, padding: '4px 10px', marginBottom: 5 }}>🇮🇳/🇬🇧 {showBilingual ? 'Hide Hindi' : 'Add Hindi'}</button>
          </div>
          <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Announcement title…" style={{ ...inp, marginBottom: showBilingual ? 8 : 14 }} />
          {showBilingual && <input value={titleHi} onChange={e => setTitleHi(e.target.value)} placeholder="शीर्षक (हिंदी में)…" style={{ ...inp, marginBottom: 14 }} />}

          {/* Audience selector — visual cards (§1.2.2, §2.1.9, §3.1.2) — v2: 4 modes */}
          <Lbl>Target Audience</Lbl>
          <div style={{ display: 'flex', gap: 8, marginBottom: 10, flexWrap: 'wrap' }}>
            {[{ v: 'all', l: '🌍 All Students' }, { v: 'batch', l: '🏫 Batches' }, { v: 'testseries', l: '🎯 Test Series' }, { v: 'students', l: '👤 Specific Students' }].map(a => (
              <button key={a.v} onClick={() => setAudienceMode(a.v as any)} style={{
                padding: '8px 14px', borderRadius: 10, border: `1.5px solid ${audienceMode === a.v ? T.ACC : T.BOR}`,
                background: audienceMode === a.v ? 'rgba(77,159,255,0.15)' : 'transparent',
                color: audienceMode === a.v ? T.ACC : T.DIM, fontWeight: 700, fontSize: 11.5, cursor: 'pointer',
              }}>{a.l}</button>
            ))}
          </div>
          {audienceMode === 'batch' && (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 8, marginBottom: 14, maxHeight: 220, overflowY: 'auto', padding: 4 }}>
              {batches.length === 0 && <div style={{ fontSize: 11, color: T.DIM }}>No batches found.</div>}
              {batches.map(b => {
                const on = selBatchIds.includes(b._id)
                return (
                  <div key={b._id} onClick={() => setSelBatchIds(on ? selBatchIds.filter(x => x !== b._id) : [...selBatchIds, b._id])} style={{
                    display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px', borderRadius: 10, cursor: 'pointer',
                    border: `1.5px solid ${on ? T.ACC : T.BOR}`, background: on ? 'rgba(77,159,255,0.1)' : 'rgba(255,255,255,0.02)',
                  }}>
                    <input type="checkbox" checked={on} readOnly style={{ accentColor: T.ACC }} />
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 12, fontWeight: 700, color: T.TS, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>🏫 {b.name}</div>
                      <div style={{ fontSize: 10, color: T.DIM }}>{b.studentCount} students · {b.examType}</div>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
          {audienceMode === 'testseries' && (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 8, marginBottom: 14, maxHeight: 220, overflowY: 'auto', padding: 4 }}>
              {batches.length === 0 && <div style={{ fontSize: 11, color: T.DIM }}>No test series found.</div>}
              {batches.map(b => {
                const on = selTestSeriesIds.includes(b._id)
                return (
                  <div key={b._id} onClick={() => setSelTestSeriesIds(on ? selTestSeriesIds.filter(x => x !== b._id) : [...selTestSeriesIds, b._id])} style={{
                    display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px', borderRadius: 10, cursor: 'pointer',
                    border: `1.5px solid ${on ? T.ACC : T.BOR}`, background: on ? 'rgba(77,159,255,0.1)' : 'rgba(255,255,255,0.02)',
                  }}>
                    <input type="checkbox" checked={on} readOnly style={{ accentColor: T.ACC }} />
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 12, fontWeight: 700, color: T.TS, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>🎯 {b.name}</div>
                      <div style={{ fontSize: 10, color: T.DIM }}>{b.studentCount} students · {b.examType}</div>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
          {audienceMode === 'students' && (
            <div style={{ marginBottom: 14 }}>
              <input value={studentQuery} onChange={e => setStudentQuery(e.target.value)} placeholder="🔍 Search by name, email, or student ID…" style={inp} />
              {studentResults.length > 0 && (
                <div style={{ marginTop: 6, maxHeight: 160, overflowY: 'auto', border: `1px solid ${T.BOR}`, borderRadius: 10 }}>
                  {studentResults.map(s => (
                    <div key={s._id} onClick={() => { if (!selStudents.find(x => x._id === s._id)) setSelStudents([...selStudents, s]); setStudentQuery(''); setStudentResults([]) }} style={{ padding: '8px 12px', cursor: 'pointer', fontSize: 12, color: T.TS, borderBottom: `1px solid ${T.BOR}` }}>
                      {s.name} <span style={{ color: T.DIM }}>· {s.email} {s.studentId ? `· ${s.studentId}` : ''}</span>
                    </div>
                  ))}
                </div>
              )}
              {selStudents.length > 0 && (
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 8 }}>
                  {selStudents.map(s => (
                    <span key={s._id} style={{ fontSize: 10.5, background: 'rgba(77,159,255,0.12)', color: T.ACC, padding: '4px 10px', borderRadius: 99, display: 'flex', alignItems: 'center', gap: 6 }}>
                      {s.name} <span onClick={() => setSelStudents(selStudents.filter(x => x._id !== s._id))} style={{ cursor: 'pointer', fontWeight: 800 }}>✕</span>
                    </span>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Send Via + Pin */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 14 }}>
            <div>
              <Lbl>Send Via</Lbl>
              <select value={sendVia} onChange={e => setSendVia(e.target.value as any)} style={inp}>
                <option value="in-app">In-App Only</option>
                <option value="email">Email Only</option>
                <option value="both">In-App + Email</option>
              </select>
            </div>
            <div>
              <Lbl>Priority</Lbl>
              <button onClick={() => setPinned(!pinned)} style={{ ...inp, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8, background: pinned ? 'rgba(255,215,0,0.12)' : inp.background, borderColor: pinned ? T.GOLD : T.BOR, color: pinned ? T.GOLD : T.TS, fontWeight: 700 }}>
                📌 {pinned ? 'Pinned — shows at top' : 'Pin this announcement'}
              </button>
            </div>
          </div>

          {/* Schedule toggle (§2.1.3, §3.1.4) */}
          <Lbl>When to Send</Lbl>
          <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
            <button onClick={() => setScheduleMode('now')} style={{ flex: 1, padding: '9px 0', borderRadius: 10, border: `1.5px solid ${scheduleMode === 'now' ? T.SUC : T.BOR}`, background: scheduleMode === 'now' ? 'rgba(0,196,140,0.12)' : 'transparent', color: scheduleMode === 'now' ? T.SUC : T.DIM, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}>🟢 Send Now</button>
            <button onClick={() => setScheduleMode('schedule')} style={{ flex: 1, padding: '9px 0', borderRadius: 10, border: `1.5px solid ${scheduleMode === 'schedule' ? T.ACC : T.BOR}`, background: scheduleMode === 'schedule' ? 'rgba(77,159,255,0.12)' : 'transparent', color: scheduleMode === 'schedule' ? T.ACC : T.DIM, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}>🔵 Schedule</button>
          </div>
          {scheduleMode === 'schedule' && (
            <input type="datetime-local" value={scheduledAt} onChange={e => setScheduledAt(e.target.value)} style={{ ...inp, marginBottom: 14 }} />
          )}

          {/* Expiry date (§2.1.8) + Image URL (§2.1.6) */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 14 }}>
            <div><Lbl>Expiry Date (optional)</Lbl><input type="date" value={expiryDate} onChange={e => setExpiryDate(e.target.value)} style={inp} /></div>
            <div><Lbl>Image/Banner URL (optional)</Lbl><input value={imageUrl} onChange={e => setImageUrl(e.target.value)} placeholder="https://…" style={inp} /></div>
          </div>

          {/* Message + rich text toolbar (§2.1.5) + char counter (§3.1.3) */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Lbl>Message *</Lbl>
            <span style={{ fontSize: 10, color: T.DIM }}>{charCount} chars</span>
          </div>
          <div style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
            <button onClick={() => wrapSelection('b')} style={{ ...btnGhost, padding: '4px 10px', fontWeight: 800 }}>B</button>
            <button onClick={() => wrapSelection('i')} style={{ ...btnGhost, padding: '4px 10px', fontStyle: 'italic' }}>I</button>
            <button onClick={() => wrapSelection('a')} style={{ ...btnGhost, padding: '4px 10px' }}>🔗 Link</button>
          </div>
          <textarea ref={msgRef} value={message} onChange={e => setMessage(e.target.value)} placeholder="Write your announcement here… (supports bold/italic/links)" rows={5} style={{ ...inp, resize: 'vertical', marginBottom: showBilingual ? 8 : 14 }} />
          {showBilingual && <textarea value={messageHi} onChange={e => setMessageHi(e.target.value)} placeholder="संदेश (हिंदी में)…" rows={4} style={{ ...inp, resize: 'vertical', marginBottom: 14 }} />}

          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <button onClick={() => setPreviewOpen(true)} style={btnGhost}>👁️ Preview</button>
            <button onClick={() => doSend(true)} disabled={sending} style={btnGhost}>💾 Save Draft</button>
            <button onClick={() => doSend(false)} disabled={sending} style={{ ...btnP, flex: 1 }}>
              {sending ? 'Sending…' : scheduleMode === 'schedule' ? '⏰ Schedule Announcement' : '📢 Send Announcement'}
            </button>
            {editingId && <button onClick={resetCompose} style={btnDng}>Cancel Edit</button>}
          </div>
        </Card>

        {/* §2.2 Sent History + Search/Filter */}
        <Card title="📜 Sent Announcements" icon="">
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(130px,1fr))', gap: 8, marginBottom: 14 }}>
            <input value={fSearch} onChange={e => setFSearch(e.target.value)} placeholder="🔍 Search…" style={inp} />
            <select value={fType} onChange={e => setFType(e.target.value)} style={inp}>
              <option value="">All Types</option>
              {TYPES.map(t => <option key={t.v} value={t.v}>{t.l}</option>)}
            </select>
            <select value={fAudience} onChange={e => setFAudience(e.target.value)} style={inp}>
              <option value="">All Audiences</option>
              <option value="all">All Students</option>
              <option value="batch">Batch</option>
              <option value="testseries">Test Series</option>
              <option value="students">Specific Students</option>
            </select>
            <input type="date" value={fDateFrom} onChange={e => setFDateFrom(e.target.value)} style={inp} />
            <input type="date" value={fDateTo} onChange={e => setFDateTo(e.target.value)} style={inp} />
          </div>

          {historyLoading ? (
            <div style={{ textAlign: 'center', padding: 30, color: T.DIM, fontSize: 12 }}>Loading…</div>
          ) : history.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '30px 0' }}>
              <div style={{ fontSize: 34, marginBottom: 8, opacity: 0.5 }}>🔕</div>
              <div style={{ fontSize: 12.5, color: T.DIM }}>No announcements sent yet</div>
            </div>
          ) : history.map(a => {
            const ti = typeInfo(a.type)
            const audLabel = a.audience?.mode === 'all' ? 'All Students' : a.audience?.mode === 'batch' ? `${(a.audience.batchIds || []).length} batch(es)` : a.audience?.mode === 'testseries' ? `${(a.audience.testSeriesIds || []).length} test series` : `${(a.audience.studentIds || []).length} student(s)`
            return (
              <div key={a._id} style={{
                borderLeft: `4px solid ${a.type === 'urgent' ? T.DNG : a.pinned ? T.GOLD : ti.col}`,
                background: 'rgba(255,255,255,0.02)', borderRadius: 10, padding: '12px 14px', marginBottom: 10, position: 'relative',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, flexWrap: 'wrap' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                    <Badge col={ti.col}>{ti.ico} {ti.l}</Badge>
                    {a.pinned && <Badge col={T.GOLD}>📌 Pinned</Badge>}
                    {a.status === 'scheduled' && <Badge col={T.WRN}>⏰ Scheduled</Badge>}
                    {a.status === 'draft' && <Badge col={T.DIM}>📝 Draft</Badge>}
                    <span style={{ fontWeight: 700, fontSize: 13, color: T.TS }}>{a.title}</span>
                  </div>
                  <span style={{ fontSize: 10.5, color: T.DIM }}>{fmt(a.createdAt)}</span>
                </div>
                <div style={{ fontSize: 11.5, color: T.DIM, marginTop: 6, maxWidth: '90%', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} dangerouslySetInnerHTML={{ __html: a.message }} />
                <div style={{ display: 'flex', gap: 12, marginTop: 8, flexWrap: 'wrap', fontSize: 10.5, color: T.DIM }}>
                  <span>👥 {audLabel}</span>
                  <span>📨 {a.sendVia}</span>
                  <span>👁️ {a.readCount}/{a.targetCount} read</span>
                  {a.ackCount > 0 && <span>👍 {a.ackCount} acknowledged</span>}
                </div>
                <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
                  <button onClick={() => doEdit(a)} style={{ ...btnGhost, fontSize: 10, padding: '5px 10px' }}>✏️ Edit</button>
                  <button onClick={() => doResend(a._id)} style={{ ...btnGhost, fontSize: 10, padding: '5px 10px' }}>🔄 Resend</button>
                  <button onClick={() => doDuplicate(a._id)} style={{ ...btnGhost, fontSize: 10, padding: '5px 10px' }}>📄 Duplicate</button>
                  <button onClick={() => toggleDelivery(a._id)} style={{ ...btnGhost, fontSize: 10, padding: '5px 10px' }}>📊 Delivery</button>
                  <button onClick={() => doDelete(a._id)} style={{ ...btnDng, fontSize: 10, padding: '5px 10px' }}>🗑️ Delete</button>
                </div>
                {expandedDelivery === a._id && deliveryData && (
                  <div style={{ marginTop: 10, padding: 10, background: 'rgba(77,159,255,0.05)', borderRadius: 8, fontSize: 11, color: T.TS, display: 'flex', gap: 16, flexWrap: 'wrap' }}>
                    <span>✅ Email Sent: {deliveryData.emailStats?.sent || 0}</span>
                    <span>📬 Delivered: {deliveryData.emailStats?.delivered || 0}</span>
                    <span>❌ Failed: {deliveryData.emailStats?.failed || 0}</span>
                    <span>👁️ Read: {deliveryData.readCount}/{deliveryData.targetCount}</span>
                  </div>
                )}
              </div>
            )
          })}
        </Card>
      </div>

      {/* §2.1.4 / §3.3 Preview Modal — exact replica of student card */}
      {previewOpen && (
        <div onClick={() => setPreviewOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 400, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
          <div onClick={e => e.stopPropagation()} style={{ maxWidth: 380, width: '100%' }}>
            <div style={{ color: '#fff', fontWeight: 700, marginBottom: 10, textAlign: 'center' }}>👁️ Student Preview</div>
            <div style={{
              background: T.CRD, borderRadius: 14, border: `1px solid ${T.BOR}`,
              borderLeft: `5px solid ${typeInfo(type).col}`, padding: 16, boxShadow: pinned ? `0 0 20px rgba(255,215,0,0.15)` : 'none',
            }}>
              {imageUrl && <img src={imageUrl} alt="" style={{ width: '100%', height: 120, objectFit: 'cover', borderRadius: 10, marginBottom: 10 }} onError={(e: any) => e.target.style.display = 'none'} />}
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                <Badge col={typeInfo(type).col}>{typeInfo(type).ico} {typeInfo(type).l}</Badge>
                {pinned && <span style={{ fontSize: 14 }}>📌</span>}
                <span style={{ width: 8, height: 8, borderRadius: '50%', background: T.ACC, display: 'inline-block' }} />
              </div>
              <div style={{ fontWeight: 800, fontSize: 14.5, color: T.TS, marginBottom: 6 }}>{title || 'Announcement title…'}</div>
              <div style={{ fontSize: 12.5, color: T.DIM, lineHeight: 1.6 }} dangerouslySetInnerHTML={{ __html: message || 'Your message will appear here…' }} />
              <div style={{ fontSize: 10, color: T.DIM, marginTop: 10 }}>Just now</div>
            </div>
            <button onClick={() => setPreviewOpen(false)} style={{ ...btnGhost, width: '100%', marginTop: 12 }}>Close Preview</button>
          </div>
        </div>
      )}
    </ThemeCtx.Provider>
  )
}
