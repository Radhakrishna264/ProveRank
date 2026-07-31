'use client'
import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function fmtTime(d: any) {
  if (!d) return ''
  const dt = new Date(d)
  return dt.toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
}
function dayLabel(d: any) {
  if (!d) return ''
  const dt = new Date(d); const now = new Date()
  const diffDays = Math.floor((new Date(dt.toDateString()).getTime() - new Date(now.toDateString()).getTime()) / 86400000)
  if (diffDays === 0) return 'Today'
  if (diffDays === 1) return 'Tomorrow'
  if (diffDays < 0) return 'Past'
  return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })
}

function MyExamsContent() {
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const toast = shell?.toast
  const lang = shell?.lang || 'en'
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  // F52 v4 fix #1 — theme-reactive colors (were static C.* before, which never
  // switches with light/dark and caused invisible text in light mode)
  const text = theme.text
  const sub = theme.sub
  const primary = theme.primary
  const border = theme.border
  const card = theme.isDark ? C.card : C.cardL
  const inputBg = theme.isDark ? 'rgba(255,255,255,0.06)' : '#FFFFFF'
  const chipBg = theme.chipBg || (theme.isDark ? 'rgba(255,255,255,0.06)' : 'rgba(37,99,235,0.06)')

  const [exams, setExams] = useState<any[]>([])
  const [synced, setSynced] = useState<{ batches: string[]; series: string[] }>({ batches: [], series: [] })
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [subjectFilter, setSubjectFilter] = useState('all')
  const [batchFilter, setBatchFilter] = useState('all') // holds a batch name OR a series name
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [previewExam, setPreviewExam] = useState<any>(null)
  const [pwModal, setPwModal] = useState<any>(null)
  const [pwInput, setPwInput] = useState('')
  const [pwErr, setPwErr] = useState('')
  const [now, setNow] = useState(Date.now())
  const [joining, setJoining] = useState<string | null>(null)

  useEffect(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('pr_myexams_filters') || '{}')
      if (saved.statusFilter) setStatusFilter(saved.statusFilter)
      if (saved.subjectFilter) setSubjectFilter(saved.subjectFilter)
      if (saved.batchFilter) setBatchFilter(saved.batchFilter)
      if (saved.categoryFilter) setCategoryFilter(saved.categoryFilter)
      if (saved.search) setSearch(saved.search)
    } catch (e) {}
  }, [])
  useEffect(() => {
    localStorage.setItem('pr_myexams_filters', JSON.stringify({ statusFilter, subjectFilter, batchFilter, categoryFilter, search }))
  }, [statusFilter, subjectFilter, batchFilter, categoryFilter, search])

  const load = () => {
    if (!token) return
    fetch(`${API}/api/exams/my-exams`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        if (d?.success) {
          setExams(d.exams || [])
          setSynced({ batches: d.syncedBatches || [], series: d.syncedSeries || [] })
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }
  useEffect(() => { load(); const iv = setInterval(load, 30000); return () => clearInterval(iv) }, [token])
  useEffect(() => { const iv = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(iv) }, [])

  const filtered = useMemo(() => {
    return exams.filter(e => {
      if (search && !e.title?.toLowerCase().includes(search.toLowerCase())) return false
      if (statusFilter === 'upcoming' && e.derivedStatus !== 'scheduled') return false
      if (statusFilter === 'live' && e.derivedStatus !== 'live') return false
      if (statusFilter === 'completed' && !(e.derivedStatus === 'ended' || (e.activeAttemptId === null && e.performance))) return false
      if (subjectFilter !== 'all' && e.subject !== subjectFilter) return false
      if (categoryFilter !== 'all' && e.category !== categoryFilter) return false
      // F52 v4 fix #2 — batchFilter now matches EITHER a batch name/multiBatch OR a series name
      if (batchFilter !== 'all') {
        const matchesBatch = e.batch === batchFilter || (e.multiBatch || []).includes(batchFilter)
        const matchesSeries = e.seriesName === batchFilter
        if (!matchesBatch && !matchesSeries) return false
      }
      return true
    })
  }, [exams, search, statusFilter, subjectFilter, batchFilter, categoryFilter])

  const stats = useMemo(() => ({
    total: exams.length,
    upcoming: exams.filter(e => e.derivedStatus === 'scheduled').length,
    live: exams.filter(e => e.derivedStatus === 'live').length,
    completed: exams.filter(e => e.derivedStatus === 'ended').length,
    attempted: exams.filter(e => e.performance).length,
    bestScore: Math.max(0, ...exams.filter(e => e.performance).map(e => e.performance.bestScore || 0))
  }), [exams])

  const timeline = useMemo(() => {
    return exams
      .filter(e => e.derivedStatus === 'scheduled' && e.schedule?.startTime)
      .sort((a, b) => new Date(a.schedule.startTime).getTime() - new Date(b.schedule.startTime).getTime())
      .slice(0, 8)
  }, [exams])

  async function doJoinWaitingRoom(e: any) {
    setJoining(e._id)
    try {
      await fetch(`${API}/api/exams/${e._id}/join-waiting-room`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      router.push(`/exam/${e._id}/waiting`)
    } catch (err) {
      toast?.(t('Could not join waiting room, try again', 'Waiting room join nahi ho paya, dobara try karo'), 'e')
    } finally { setJoining(null) }
  }

  const go = (e: any) => {
    if (e.passwordProtected && !e.activeAttemptId) { setPwModal(e); setPwErr(''); setPwInput(''); return }
    if (e.activeAttemptId) { router.push(`/exam/${e._id}/attempt`); return }

    if (e.derivedStatus === 'scheduled' && e.waitingRoomWindowOpen) { doJoinWaitingRoom(e); return }
    if (e.derivedStatus === 'scheduled') {
      toast?.(t('Waiting room will open ' + e.waitMins + ' minutes before start', 'Waiting room shuru se ' + e.waitMins + ' minute pehle khulega'), 'w')
      return
    }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') {
      toast?.(t('Join window has closed. Available again: ' + fmtTime(e.nextAvailableAttemptTime), 'Join window band ho gayi. Dobara available: ' + fmtTime(e.nextAvailableAttemptTime)), 'e')
      return
    }
    if (e.joinState === 'locked') { toast?.(t('No attempts left for this exam', 'Is exam ke liye attempts khatam ho gaye'), 'e'); return }

    router.push(`/exam/${e._id}/instructions`)
  }

  const submitPassword = () => {
    if (!pwInput.trim()) { setPwErr(t('Enter password', 'Password daalo')); return }
    // F52 security fix — verified server-side now; plaintext password never sent to client
    fetch(`${API}/api/exams/${pwModal._id}/verify-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ password: pwInput })
    })
      .then(r => r.json())
      .then(d => {
        if (!d?.valid) { setPwErr(t('Incorrect password', 'Galat password')); return }
        const e = pwModal; setPwModal(null)
        if (e.derivedStatus === 'scheduled' && e.waitingRoomWindowOpen) { doJoinWaitingRoom(e); return }
        router.push(`/exam/${e._id}/instructions`)
      })
      .catch(() => setPwErr(t('Error verifying password', 'Password verify karne me error')))
  }

  const toggleReminder = (e: any) => {
    const next = !e.reminderEnabled
    setExams(prev => prev.map(x => x._id === e._id ? { ...x, reminderEnabled: next } : x))
    fetch(`${API}/api/exams/${e._id}/reminder`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ enabled: next }) }).catch(() => {})
  }

  function startBtn(e: any) {
    if (e.activeAttemptId) return { label: t('Continue Attempt', 'Jaari Rakhein'), col: C.gold, icon: '▶️', disabled: false }
    if (e.passwordProtected && !e.activeAttemptId) return { label: t('Password Required', 'Password Chahiye'), col: C.purple, icon: '🔒', disabled: false }
    if (e.derivedStatus === 'scheduled' && e.waitingRoomWindowOpen) {
      return e.hasJoinedWaitingRoom
        ? { label: t('Resume Waiting Room', 'Waiting Room Resume Karo'), col: primary, icon: '🔁', disabled: false }
        : { label: t('Join Waiting Room', 'Waiting Room Join Karo'), col: primary, icon: '🚪', disabled: false }
    }
    if (e.derivedStatus === 'scheduled') return { label: t('Available Later', 'Baad Me Available'), col: '#888', icon: '⏳', disabled: true }
    if (e.derivedStatus === 'live' && e.joinState === 'join_open') return { label: t('Start Now', 'Abhi Shuru Karo'), col: C.success, icon: '🔴', disabled: false }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') return { label: t('Join Closed', 'Join Band'), col: '#888', icon: '🚫', disabled: true }
    if (e.joinState === 'available_again') return { label: t('Start Exam', 'Exam Shuru Karo'), col: C.success, icon: '▶️', disabled: false }
    if (e.joinState === 'locked') return { label: t('Locked', 'Locked'), col: '#888', icon: '🔒', disabled: true }
    return { label: t('View', 'Dekho'), col: C.gold, icon: '👁️', disabled: false }
  }

  const subjects = useMemo(() => Array.from(new Set(exams.map(e => e.subject).filter(Boolean))), [exams])
  // F52 v4 fix #2 — merged Batches + Test Series into one synced list for the dropdown
  const batchesAndSeries = useMemo(() => Array.from(new Set([
    ...synced.batches,
    ...synced.series,
    ...exams.map(e => e.batch).filter(Boolean),
    ...exams.map(e => e.seriesName).filter(Boolean)
  ])), [exams, synced])
  const categories = useMemo(() => Array.from(new Set(exams.map(e => e.category).filter(Boolean))), [exams])

  const selectStyle: any = { padding: 10, borderRadius: 10, border: `1px solid ${border}`, background: inputBg, color: text }

  return (
    <div style={{ padding: 16, maxWidth: 1100, margin: '0 auto' }}>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, marginBottom: 14 }}>
        {[
          ['📚', stats.total, t('Total', 'Total')],
          ['⏳', stats.upcoming, t('Upcoming', 'Upcoming')],
          ['🔴', stats.live, t('Live', 'Live')],
          ['✅', stats.completed, t('Completed', 'Completed')],
          ['🎯', stats.attempted, t('Attempted', 'Attempted')],
          ['🏆', stats.bestScore, t('Best Score', 'Best Score')]
        ].map(([icon, val, label]: any, i) => (
          <div key={i} style={{ flex: '1 1 100px', background: card, border: `1px solid ${border}`, borderRadius: 12, padding: '10px 12px', textAlign: 'center' }}>
            <div style={{ fontSize: 18 }}>{icon}</div>
            <div style={{ fontSize: 20, fontWeight: 800, color: text }}>{val}</div>
            <div style={{ fontSize: 11, color: sub }}>{label}</div>
          </div>
        ))}
      </div>

      {timeline.length > 0 && (
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 8, marginBottom: 14 }}>
          {timeline.map(e => (
            <div key={e._id} onClick={() => setPreviewExam(e)} style={{ cursor: 'pointer', minWidth: 130, background: card, border: `1px solid ${e.derivedStatus === 'live' ? C.success : border}`, borderRadius: 10, padding: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 700, color: C.gold }}>{dayLabel(e.schedule?.startTime)}</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.title}</div>
              <div style={{ fontSize: 10, color: sub }}>{fmtTime(e.schedule?.startTime)}</div>
            </div>
          ))}
        </div>
      )}

      <div style={{ marginBottom: 14 }}>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('Search exam title...', 'Exam title search karo...')}
          style={{ width: '100%', padding: '10px 12px', borderRadius: 10, border: `1px solid ${border}`, background: inputBg, color: text, marginBottom: 8, boxSizing: 'border-box' }} />
        {/* F52 §12.1.3 — horizontal scroll strip on mobile; wraps naturally on wide desktop screens */}
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4, WebkitOverflowScrolling: 'touch' }}>
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All', 'All')}</option>
            <option value="upcoming">{t('Upcoming', 'Upcoming')}</option>
            <option value="live">{t('Live', 'Live')}</option>
            <option value="completed">{t('Completed', 'Completed')}</option>
          </select>
          <select value={subjectFilter} onChange={e => setSubjectFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All Subjects', 'All Subjects')}</option>
            {subjects.map(s => <option key={s} value={s}>{s}</option>)}
          </select>
          {/* F52 v4 fix #2 — renamed + merged Batches/Test Series dropdown */}
          <select value={batchFilter} onChange={e => setBatchFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All Batches/Test Series', 'All Batches/Test Series')}</option>
            {batchesAndSeries.map(b => <option key={b} value={b}>{b}</option>)}
          </select>
          <select value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)} style={{ ...selectStyle, flexShrink: 0 }}>
            <option value="all">{t('All Categories', 'All Categories')}</option>
            {categories.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: sub }}>{t('Loading exams...', 'Exams load ho rahe hai...')}</div>
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, color: sub }}>
          <div style={{ fontSize: 40 }}>📭</div>
          <div style={{ marginTop: 8 }}>{exams.length === 0 ? t('No exams scheduled yet', 'Abhi koi exam schedule nahi hai') : t('No exams match your filters', 'Filters se koi exam match nahi hua')}</div>
          {exams.length > 0 && <button onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setBatchFilter('all'); setCategoryFilter('all') }} style={{ marginTop: 10, padding: '8px 16px', borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer' }}>{t('Reset Filters', 'Filters Reset Karo')}</button>}
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 12 }}>
          {filtered.map(e => {
            const btn = startBtn(e)
            const minsToStart = e.schedule?.startTime ? Math.round((new Date(e.schedule.startTime).getTime() - now) / 60000) : null
            return (
              <div key={e._id} style={{ background: card, border: `1px solid ${e.derivedStatus === 'live' ? C.success : border}`, borderRadius: 14, padding: 14, position: 'relative' }}>
                {e.derivedStatus === 'live' && e.joinState === 'join_open' && (
                  <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 10, fontWeight: 800, color: '#fff', background: C.success, padding: '3px 8px', borderRadius: 20 }}>🔴 LIVE</span>
                )}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ fontWeight: 800, fontSize: 15, color: text, maxWidth: '80%' }}>{e.title}</div>
                  <button onClick={() => setPreviewExam(e)} title={t('Quick preview', 'Quick preview')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontSize: 14 }}>ℹ️</button>
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, margin: '8px 0' }}>
                  <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.subject}</span>
                  <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.duration} min</span>
                  <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.totalMarks} marks</span>
                  {e.category && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.category}</span>}
                  {e.assignmentType && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{e.assignmentType === 'mini_test' ? t('Mini Test', 'Mini Test') : e.assignmentType === 'series' ? t('Series', 'Series') : e.assignmentType === 'batch' ? t('Batch', 'Batch') : t('Individual', 'Individual')}</span>}
                  {e.batch && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{e.batch}</span>}
                  {e.seriesName && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>📚 {e.seriesName}</span>}
                </div>
                <div style={{ fontSize: 11, color: sub, marginBottom: 8 }}>{fmtTime(e.schedule?.startTime)}</div>

                {e.derivedStatus === 'scheduled' && !e.waitingRoomWindowOpen && minsToStart != null && minsToStart > 0 && (
                  <div style={{ fontSize: 12, color: C.gold, marginBottom: 8 }}>⏱ {t('Starts in', 'Shuru hoga')} {minsToStart > 60 ? Math.floor(minsToStart / 60) + 'h ' + (minsToStart % 60) + 'm' : minsToStart + 'm'}</div>
                )}
                {e.joinState === 'join_closed' && (
                  <div style={{ fontSize: 11, color: C.danger, marginBottom: 8 }}>⚠️ {t('Join closed. Available again:', 'Join band. Dobara available:')} {fmtTime(e.nextAvailableAttemptTime)}</div>
                )}

                {e.performance && (
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{t('Best', 'Best')}: {e.performance.bestScore}</span>
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{t('Avg', 'Avg')}: {e.performance.avgScore}</span>
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{t('Attempts', 'Attempts')}: {e.performance.attemptCount}</span>
                    {e.performance.lastAttemptAt && <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: sub }}>{t('Last', 'Last')}: {fmtTime(e.performance.lastAttemptAt)}</span>}
                    <span style={{ fontSize: 11, background: chipBg, padding: '3px 8px', borderRadius: 20, color: e.performance.rankTrend === 'up' ? C.success : e.performance.rankTrend === 'down' ? C.danger : sub }}>
                      {e.performance.rankTrend === 'up' ? '📈' : e.performance.rankTrend === 'down' ? '📉' : '➖'} {t('Rank', 'Rank')} {e.performance.rankTrend}
                    </span>
                  </div>
                )}

                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <button disabled={btn.disabled || joining === e._id} onClick={() => go(e)} style={{ flex: 1, padding: '10px 14px', borderRadius: 10, border: 'none', background: btn.disabled ? '#444' : btn.col, color: '#fff', fontWeight: 700, cursor: btn.disabled ? 'not-allowed' : 'pointer', opacity: joining === e._id ? 0.6 : 1 }}>
                    {btn.icon} {joining === e._id ? t('Joining...', 'Join ho raha hai...') : btn.label}
                  </button>
                  {e.derivedStatus === 'scheduled' && (
                    <button onClick={() => toggleReminder(e)} title={t('Reminder', 'Reminder')} style={{ padding: '10px 12px', borderRadius: 10, border: `1px solid ${border}`, background: e.reminderEnabled ? C.gold : 'transparent', color: e.reminderEnabled ? '#000' : text, cursor: 'pointer' }}>
                      {e.reminderEnabled ? '🔔' : '🔕'}
                    </button>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {previewExam && (
        <div onClick={() => setPreviewExam(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, border: `1px solid ${border}`, borderRadius: 16, padding: 20, maxWidth: 340, width: '90%' }}>
            <div style={{ fontWeight: 800, fontSize: 16, color: text, marginBottom: 8 }}>{previewExam.title}</div>
            <div style={{ fontSize: 13, color: sub, lineHeight: 1.8 }}>
              <div>⏱ {t('Duration', 'Duration')}: {previewExam.duration} min</div>
              <div>🎯 {t('Marks', 'Marks')}: {previewExam.totalMarks}</div>
              <div>📚 {t('Subject', 'Subject')}: {previewExam.subject}</div>
              <div>🏷 {t('Category', 'Category')}: {previewExam.category || '-'}</div>
              {previewExam.seriesName && <div>📖 {t('Test Series', 'Test Series')}: {previewExam.seriesName}</div>}
              <div>📅 {fmtTime(previewExam.schedule?.startTime)}</div>
              <div>📍 {t('Status', 'Status')}: {previewExam.derivedStatus} / {previewExam.joinState}</div>
            </div>
            <button onClick={() => { const e = previewExam; setPreviewExam(null); go(e) }} style={{ marginTop: 14, width: '100%', padding: 10, borderRadius: 10, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>{t('Open', 'Kholo')}</button>
          </div>
        </div>
      )}

      {pwModal && (
        <div onClick={() => setPwModal(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, border: `1px solid ${border}`, borderRadius: 16, padding: 20, maxWidth: 320, width: '90%' }}>
            <div style={{ fontWeight: 800, color: text, marginBottom: 10 }}>🔒 {t('Enter Exam Password', 'Exam Password Daalo')}</div>
            <input type="password" value={pwInput} onChange={e => setPwInput(e.target.value)} placeholder={t('Password', 'Password')}
              style={{ width: '100%', padding: 10, borderRadius: 8, border: `1px solid ${border}`, background: inputBg, color: text, marginBottom: 8 }} />
            {pwErr && <div style={{ color: C.danger, fontSize: 12, marginBottom: 8 }}>{pwErr}</div>}
            <button onClick={submitPassword} style={{ width: '100%', padding: 10, borderRadius: 8, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>{t('Submit', 'Submit')}</button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function MyExamsPage() {
  return <StudentShell pageKey="my-exams"><MyExamsContent /></StudentShell>
}
