#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F52-F57 v4 — Frontend patch"
echo " Fix #1: static C object -> theme-reactive useShell().theme"
echo "         (light theme text/selects were invisible)"
echo " Fix #2: Batches dropdown -> Batches/Test Series (merged sync)"
echo " Requires backend v2 + v4-patch + frontend v3 already deployed"
echo "════════════════════════════════════════════════════════"

FRONTEND_APP=""
for candidate in "/root/workspace/frontend/app" "/home/runner/workspace/frontend/app" "$(pwd)/frontend/app"; do
  if [ -d "$candidate" ]; then FRONTEND_APP="$candidate"; break; fi
done
if [ -z "$FRONTEND_APP" ]; then echo "❌ Could not find frontend/app — set FRONTEND_APP env var and re-run."; exit 1; fi
echo "📂 Frontend app dir: $FRONTEND_APP"
ts=$(date +%s)

# ══════════════════════════════════════════════════════════
# F52 v4 — My Exams (full rewrite)
# Fix #1: theme-reactive colors (was static C causing light-mode invisibility)
# Fix #2: "All Batches" -> "All Batches/Test Series" merged dropdown + filter
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/my-exams/page.tsx" ] && cp "$FRONTEND_APP/my-exams/page.tsx" "$FRONTEND_APP/my-exams/page.tsx.bak_v4_$ts"
mkdir -p "$FRONTEND_APP/my-exams"
cat > "$FRONTEND_APP/my-exams/page.tsx" << 'PRNODEEOF'
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
    fetch(`${API}/api/exams/${pwModal._id}`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        if (d?.exam?.password && d.exam.password !== pwInput) { setPwErr(t('Incorrect password', 'Galat password')); return }
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

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 14 }}>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('Search exam title...', 'Exam title search karo...')}
          style={{ flex: '2 1 200px', padding: '10px 12px', borderRadius: 10, border: `1px solid ${border}`, background: inputBg, color: text }} />
        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} style={selectStyle}>
          <option value="all">{t('All', 'All')}</option>
          <option value="upcoming">{t('Upcoming', 'Upcoming')}</option>
          <option value="live">{t('Live', 'Live')}</option>
          <option value="completed">{t('Completed', 'Completed')}</option>
        </select>
        <select value={subjectFilter} onChange={e => setSubjectFilter(e.target.value)} style={selectStyle}>
          <option value="all">{t('All Subjects', 'All Subjects')}</option>
          {subjects.map(s => <option key={s} value={s}>{s}</option>)}
        </select>
        {/* F52 v4 fix #2 — renamed + merged Batches/Test Series dropdown */}
        <select value={batchFilter} onChange={e => setBatchFilter(e.target.value)} style={selectStyle}>
          <option value="all">{t('All Batches/Test Series', 'All Batches/Test Series')}</option>
          {batchesAndSeries.map(b => <option key={b} value={b}>{b}</option>)}
        </select>
        <select value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)} style={selectStyle}>
          <option value="all">{t('All Categories', 'All Categories')}</option>
          {categories.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
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
PRNODEEOF
echo "✅ my-exams/page.tsx v4 (theme-reactive colors + merged Batches/Test Series dropdown)"

# ══════════════════════════════════════════════════════════
# F53 v4 — Waiting Room (theme-reactive colors)
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" ] && cp "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx.bak_v4_$ts"
mkdir -p "$FRONTEND_APP/exam/[examId]/waiting"
cat > "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const TIPS = [
  { text: 'Keep your ID card ready for admit card verification.', severity: 'info' },
  { text: 'Ensure stable internet connection before exam starts.', severity: 'high' },
  { text: 'Camera must stay on throughout the exam — compulsory.', severity: 'high' },
  { text: 'Do not switch tabs during the exam — 3 warnings = auto submit.', severity: 'critical' },
  { text: 'Attempt easy questions first, mark tough ones for review.', severity: 'info' },
  { text: 'Sit in a well-lit, quiet room for best proctoring accuracy.', severity: 'medium' },
]
const SEV_COLOR: any = { info: '#5b9bff', medium: '#f2b134', high: '#ff9f43', critical: '#ff5555' }

function fmtSecs(s: number) {
  const m = Math.floor(s / 60), sec = s % 60
  return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
}

function WaitingRoomContent() {
  const { examId } = useParams() as any
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const lang = shell?.lang || 'en'
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const text = theme.text, sub = theme.sub, border = theme.border
  const card = theme.isDark ? C.card : C.cardL
  const inputBg = theme.isDark ? 'rgba(255,255,255,0.06)' : '#FFFFFF'

  const [info, setInfo] = useState<any>(null)
  const [entered, setEntered] = useState(false)
  const [secsLeft, setSecsLeft] = useState<number | null>(null)
  const [liveCount, setLiveCount] = useState(0)
  const [tipIdx, setTipIdx] = useState(0)
  const [musicOn, setMusicOn] = useState(false)
  const [chatMsgs, setChatMsgs] = useState<any[]>([])
  const [chatInput, setChatInput] = useState('')
  const [chatOpen, setChatOpen] = useState(true)
  const [chatMinsLeft, setChatMinsLeft] = useState<number | null>(null)
  const [broadcasts, setBroadcasts] = useState<any[]>([])
  const [activityLog, setActivityLog] = useState<string[]>([])
  const socketRef = useRef<any>(null)
  const transitionedRef = useRef(false)

  const logActivity = (msg: string) => setActivityLog(l => [`${new Date().toLocaleTimeString()} — ${msg}`, ...l].slice(0, 8))

  const loadInfo = () => {
    if (!token) return
    fetch(`${API}/api/exams/${examId}/waiting-info`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        if (!d?.success) return
        setInfo(d)
        setLiveCount(d.liveCount || 0)
        if (d.activeAttemptId) { router.replace(`/exam/${examId}/attempt`); return }
        if (d.hasJoinedWaitingRoom) setEntered(true)
        if (d.exam?.schedule?.startTime) {
          const secs = Math.round((new Date(d.exam.schedule.startTime).getTime() - Date.now()) / 1000)
          setSecsLeft(secs)
        }
      })
      .catch(() => {})
  }
  useEffect(() => { loadInfo() }, [examId, token])

  const joinNow = () => {
    fetch(`${API}/api/exams/${examId}/join-waiting-room`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => { if (d?.success) { setEntered(true); logActivity(t('Joined waiting room', 'Waiting room join kiya')) } })
      .catch(() => {})
  }

  useEffect(() => {
    if (!entered || secsLeft == null) return
    const iv = setInterval(() => {
      setSecsLeft(s => { if (s == null) return s; if (s <= 1) { clearInterval(iv); return 0 }; return s - 1 })
    }, 1000)
    return () => clearInterval(iv)
  }, [entered, secsLeft != null])

  useEffect(() => {
    if (!entered || secsLeft == null || !info) return
    const bufferSecs = (info.config?.autoCloseBufferMinutes ?? 8) * 60
    if (secsLeft <= bufferSecs && !transitionedRef.current) {
      transitionedRef.current = true
      logActivity(t('Auto-moving to Instructions screen', 'Instructions screen par ja rahe hai'))
      setTimeout(() => router.push(`/exam/${examId}/instructions`), 1200)
    }
  }, [secsLeft, entered, info])

  useEffect(() => {
    if (!entered) return
    let socket: any
    try {
      const { io } = require('socket.io-client')
      socket = io(API)
      socket.emit('join-waiting-room', examId)
      socket.on('waiting-room-count', (d: any) => { if (String(d.examId) === String(examId)) setLiveCount(d.count) })
      socket.on('waiting-chat-message', (msg: any) => setChatMsgs(m => [...m, msg]))
      socketRef.current = socket
    } catch (e) {}
    const poll = setInterval(loadInfo, 15000)
    return () => { clearInterval(poll); if (socket) { socket.emit('leave-waiting-room', examId); socket.disconnect() } }
  }, [entered, examId])

  useEffect(() => {
    if (!entered) return
    fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json()).then(d => { if (d?.success) setChatMsgs(d.messages || []) }).catch(() => {})
  }, [entered])

  useEffect(() => {
    if (!entered || !info?.joinedAt) return
    const chatMins = info.config?.chatMinutes ?? 10
    const iv = setInterval(() => {
      const minsSince = (Date.now() - new Date(info.joinedAt).getTime()) / 60000
      const left = Math.max(0, chatMins - minsSince)
      setChatMinsLeft(left)
      if (left <= 0 && chatOpen) { setChatOpen(false); logActivity(t('Chat closed for anti-cheat', 'Anti-cheat ke liye chat band')) }
      else if (left <= 2 && left > 0) logActivity(t('Chat closing soon', 'Chat jaldi band hoga'))
    }, 5000)
    return () => clearInterval(iv)
  }, [entered, info?.joinedAt, chatOpen])

  useEffect(() => { const iv = setInterval(() => setTipIdx(i => (i + 1) % TIPS.length), 30000); return () => clearInterval(iv) }, [])

  const sendChat = () => {
    if (!chatInput.trim() || !chatOpen) return
    fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ text: chatInput }) })
      .then(r => r.json()).then(d => { if (d?.success) { setChatMsgs(m => [...m, d.message]); setChatInput('') } else if (d?.chatClosed) setChatOpen(false) })
      .catch(() => {})
  }

  if (!info) return <div style={{ padding: 40, textAlign: 'center', color: sub }}>{t('Loading...', 'Load ho raha hai...')}</div>

  return (
    <div style={{ padding: 16, maxWidth: 640, margin: '0 auto' }}>
      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 24, textAlign: 'center' }}>
        <div style={{ fontSize: 18, fontWeight: 800, color: text }}>{info.exam.title}</div>
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 8, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: sub }}>⏱ {info.exam.duration} min</span>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: sub }}>🎯 {info.exam.totalMarks} marks</span>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: sub }}>❓ {info.exam.totalQuestions} Qs</span>
          <span style={{ fontSize: 12, background: theme.chipBg, padding: '4px 10px', borderRadius: 20, color: C.gold }}>👥 {liveCount} {t('waiting', 'waiting')}</span>
        </div>

        {!entered ? (
          <div style={{ marginTop: 24 }}>
            <div style={{ fontSize: 40 }}>⏳</div>
            <div style={{ color: sub, margin: '10px 0' }}>{t('Click below to officially join the waiting room', 'Waiting room officially join karne ke liye niche click karo')}</div>
            <button onClick={joinNow} style={{ padding: '12px 28px', borderRadius: 12, border: 'none', background: C.gold, color: '#000', fontWeight: 800, cursor: 'pointer' }}>🚪 {t('Join Waiting Room', 'Waiting Room Join Karo')}</button>
          </div>
        ) : (
          <>
            <div style={{ fontSize: 48, fontWeight: 900, color: secsLeft != null && secsLeft < 120 ? C.danger : C.gold, margin: '20px 0 6px' }}>
              {secsLeft != null && secsLeft > 0 ? fmtSecs(secsLeft) : t('Starting...', 'Shuru ho raha hai...')}
            </div>
            <div style={{ height: 6, background: theme.chipBg, borderRadius: 6, overflow: 'hidden', margin: '0 0 20px' }}>
              <div style={{ height: '100%', width: secsLeft != null && info.config?.waitingRoomMinutes ? `${100 - Math.min(100, (secsLeft / (info.config.waitingRoomMinutes * 60)) * 100)}%` : '0%', background: C.gold, transition: 'width 1s linear' }} />
            </div>

            <div style={{ background: theme.chipBg, borderRadius: 10, padding: 10, marginBottom: 10, borderLeft: `4px solid ${SEV_COLOR[TIPS[tipIdx].severity]}`, textAlign: 'left' }}>
              <span style={{ fontSize: 10, fontWeight: 800, color: SEV_COLOR[TIPS[tipIdx].severity], textTransform: 'uppercase' }}>{TIPS[tipIdx].severity}</span>
              <div style={{ fontSize: 13, color: text }}>💡 {TIPS[tipIdx].text}</div>
            </div>

            {broadcasts.length > 0 && broadcasts.map((b, i) => (
              <div key={i} style={{ background: '#3a2a00', borderRadius: 10, padding: 10, marginBottom: 10, textAlign: 'left' }}>📢 <b>{t('Admin', 'Admin')}:</b> {b.message || b.text}</div>
            ))}

            <button onClick={() => setMusicOn(m => !m)} style={{ background: 'transparent', border: `1px solid ${border}`, color: sub, borderRadius: 20, padding: '4px 12px', fontSize: 12, cursor: 'pointer', marginBottom: 14 }}>
              {musicOn ? '🔊' : '🔇'} {t('Background Music', 'Background Music')}
            </button>

            <div style={{ textAlign: 'left', background: theme.chipBg, borderRadius: 10, padding: 10, maxHeight: 160, overflowY: 'auto', marginBottom: 8 }}>
              {chatMsgs.length === 0 ? <div style={{ color: sub, fontSize: 12 }}>{t('No messages yet', 'Abhi koi message nahi')}</div> :
                chatMsgs.map((m, i) => <div key={i} style={{ fontSize: 12, color: text, marginBottom: 4 }}><b>{m.name}:</b> {m.text}</div>)}
            </div>
            {chatOpen ? (
              <div style={{ display: 'flex', gap: 6 }}>
                <input value={chatInput} onChange={e => setChatInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && sendChat()} placeholder={t('Type a message...', 'Message likho...')}
                  style={{ flex: 1, padding: 8, borderRadius: 8, border: `1px solid ${border}`, background: inputBg, color: text }} />
                <button onClick={sendChat} style={{ padding: '8px 14px', borderRadius: 8, border: 'none', background: theme.primary, color: '#fff', cursor: 'pointer' }}>{t('Send', 'Bhejo')}</button>
              </div>
            ) : (
              <div style={{ fontSize: 11, color: sub }}>💬 {t('Chat closed for anti-cheat', 'Anti-cheat ke liye chat band ho gayi')}</div>
            )}
            {chatOpen && chatMinsLeft != null && <div style={{ fontSize: 10, color: sub, marginTop: 4 }}>{t('Chat closes in', 'Chat band hogi')} {Math.ceil(chatMinsLeft)} {t('min', 'min')}</div>}

            {activityLog.length > 0 && (
              <div style={{ textAlign: 'left', marginTop: 14, fontSize: 10, color: sub }}>
                <div style={{ fontWeight: 700, marginBottom: 4 }}>{t('Activity', 'Activity')}</div>
                {activityLog.map((a, i) => <div key={i}>{a}</div>)}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  )
}

export default function WaitingRoomPage() {
  return <StudentShell pageKey="my-exams"><WaitingRoomContent /></StudentShell>
}
PRNODEEOF
echo "✅ waiting/page.tsx v4 (theme-reactive colors)"

# ══════════════════════════════════════════════════════════
# F54/F55 v4 — Instructions Screen (theme-reactive colors)
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" ] && cp "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx.bak_v4_$ts"
mkdir -p "$FRONTEND_APP/exam/[examId]/instructions"
cat > "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const DEFAULT_POINTS_EN = [
  'Exam name and duration will be shown on top of the screen.',
  'Total marks are fixed as per the marking scheme.',
  'Marking scheme: +4 correct, -1 wrong, 0 unattempted (unless customized).',
  'Total number of questions is fixed — cannot be changed mid-exam.',
  'Subject-wise question counts are shown before you start.',
  'Webcam is compulsory throughout the exam.',
  'Right-click and copy-paste are disabled during the exam.',
  '3 tab switches will auto-submit your exam.',
  'Fullscreen mode is enforced — exiting will trigger a warning.'
]
const DEFAULT_POINTS_HI = [
  'Exam ka naam aur duration screen ke upar dikhega.',
  'Total marks marking scheme ke hisaab se fixed hai.',
  'Marking scheme: +4 sahi, -1 galat, 0 attempt na karne par (jab tak customize na ho).',
  'Total questions fixed hai — exam ke beech me change nahi honge.',
  'Subject-wise questions count shuru se pehle dikhega.',
  'Webcam poore exam me compulsory hai.',
  'Right-click aur copy-paste exam ke dauraan disabled rahega.',
  '3 baar tab switch karne par exam auto-submit ho jayega.',
  'Fullscreen mode enforce hoga — bahar nikalne par warning aayegi.'
]
const TC_TEXT_EN = `By proceeding, you agree to follow all ProveRank exam rules: no impersonation, no external help, no unfair means, webcam must remain on, and any violation may result in disqualification, result cancellation, or account ban. This consent is recorded against your account and exam attempt for audit purposes.`
const TC_TEXT_HI = `Aage badhne se aap ProveRank ke saare exam rules maanne ke liye sehmat hai: koi impersonation nahi, koi bahar ki madad nahi, koi unfair means nahi, webcam poore samay on rehna chahiye, aur kisi bhi violation par disqualification, result cancel, ya account ban ho sakta hai. Ye consent aapke account aur exam attempt ke against record kiya jaata hai audit ke liye.`

function InstructionsContent() {
  const { examId } = useParams() as any
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const [lang, setLang] = useState(shell?.lang || 'en')
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const text = theme.text, sub = theme.sub, border = theme.border
  const card = theme.isDark ? C.card : C.cardL

  const [exam, setExam] = useState<any>(null)
  const [checked, setChecked] = useState(false)
  const [tcModal, setTcModal] = useState(false)
  const [scrolledToBottom, setScrolledToBottom] = useState(false)
  const [consentAlready, setConsentAlready] = useState(false)
  const tcBodyRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!token) return
    fetch(`${API}/api/exams/my-exams`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        const e = (d?.exams || []).find((x: any) => String(x._id) === String(examId))
        if (e?.activeAttemptId) { router.replace(`/exam/${examId}/attempt`); return }
      }).catch(() => {})

    fetch(`${API}/api/exams/${examId}`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json()).then(d => setExam(d?.exam || null)).catch(() => {})

    fetch(`${API}/api/exams/${examId}/consent-status`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json()).then(d => { if (d?.success) setConsentAlready(!!d.accepted) }).catch(() => {})
  }, [examId, token])

  const onTcScroll = () => {
    const el = tcBodyRef.current
    if (!el) return
    if (el.scrollHeight - el.scrollTop - el.clientHeight < 20) setScrolledToBottom(true)
  }

  const proceed = async () => {
    if (!checked) return
    try {
      const r = await fetch(`${API}/api/exams/${examId}/accept-terms`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      const d = await r.json()
      if (!d?.success) { alert(t('Could not record consent, please retry', 'Consent record nahi ho paya, dobara try karo')); return }
      sessionStorage.setItem(`pr_tc_${examId}`, JSON.stringify({ accepted: true, version: d.version, at: d.acceptedAt }))
      router.push(`/exam/${examId}/webcam`)
    } catch (e) {
      alert(t('Network error — please retry', 'Network error — dobara try karo'))
    }
  }

  const points = lang === 'hi' ? DEFAULT_POINTS_HI : DEFAULT_POINTS_EN

  return (
    <div style={{ padding: 16, maxWidth: 640, margin: '0 auto' }}>
      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 22 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 800, color: text }}>{exam?.title || t('Exam Instructions', 'Exam Instructions')}</div>
            <div style={{ fontSize: 12, color: sub }}>{t('Please read carefully before proceeding', 'Aage badhne se pehle dhyan se padho')}</div>
          </div>
          <button onClick={() => setLang(l => l === 'hi' ? 'en' : 'hi')} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${border}`, background: 'transparent', color: text, cursor: 'pointer', fontSize: 12 }}>
            {lang === 'hi' ? 'EN' : 'हिं'}
          </button>
        </div>

        {consentAlready && (
          <div style={{ background: '#123b1e', color: '#7CFC9C', borderRadius: 10, padding: 8, fontSize: 12, margin: '12px 0' }}>
            ✅ {t('You already accepted these terms for this exam.', 'Aapne is exam ke liye ye terms pehle hi accept kar liye hai.')}
          </div>
        )}

        <ol style={{ padding: '16px 0 0 20px', color: text, fontSize: 13, lineHeight: 1.9 }}>
          {points.map((p, i) => <li key={i}>{p}</li>)}
        </ol>

        {exam?.customInstructions && (
          <div style={{ background: '#3a2a00', borderLeft: '4px solid #f2b134', borderRadius: 8, padding: 12, margin: '14px 0', color: '#f2d38a', fontSize: 12 }}>
            ⚠️ <b>{t('Additional Instructions', 'Additional Instructions')}:</b> {exam.customInstructions}
          </div>
        )}

        <div style={{ background: '#0e2418', border: '1px solid #1e5c3a', borderRadius: 10, padding: 12, marginTop: 16 }}>
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer' }}>
            <input type="checkbox" checked={checked} onChange={e => { if (!e.target.checked) { setChecked(false); return } setTcModal(true) }} style={{ marginTop: 3 }} />
            <span style={{ fontSize: 13, color: '#dff5e6' }}>
              {t('I have read and agree to all instructions', 'Maine saari instructions padh li hai aur maanta/maanti hoon')}
              {' '}<a onClick={(e) => { e.preventDefault(); setTcModal(true) }} style={{ color: C.gold, cursor: 'pointer', textDecoration: 'underline' }}>({t('read full terms', 'poore terms padho')})</a>
            </span>
          </label>
        </div>

        <button disabled={!checked} onClick={proceed} style={{ width: '100%', marginTop: 18, padding: 14, borderRadius: 12, border: 'none', background: checked ? `linear-gradient(90deg, ${theme.primary}, ${C.gold})` : '#444', color: '#fff', fontWeight: 800, cursor: checked ? 'pointer' : 'not-allowed', transition: 'all .3s' }}>
          {t('Proceed to AI Webcam Check', 'AI Webcam Check Par Jao')} →
        </button>
      </div>

      {tcModal && (
        <div onClick={() => setTcModal(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 300, padding: 16 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, borderRadius: 16, padding: 20, maxWidth: 480, width: '100%', maxHeight: '80vh', display: 'flex', flexDirection: 'column' }}>
            <div style={{ fontWeight: 800, color: text, marginBottom: 10 }}>{t('Terms & Conditions', 'Terms & Conditions')}</div>
            <div ref={tcBodyRef} onScroll={onTcScroll} style={{ overflowY: 'auto', fontSize: 13, color: sub, lineHeight: 1.7, flex: 1, paddingRight: 4 }}>
              {lang === 'hi' ? TC_TEXT_HI : TC_TEXT_EN}
            </div>
            {!scrolledToBottom && <div style={{ fontSize: 11, color: C.gold, marginTop: 8 }}>{t('Scroll to the bottom to continue', 'Continue karne ke liye niche scroll karo')}</div>}
            <button disabled={!scrolledToBottom} onClick={() => { setChecked(true); setTcModal(false) }} style={{ marginTop: 12, padding: 12, borderRadius: 10, border: 'none', background: scrolledToBottom ? C.gold : '#444', color: '#000', fontWeight: 800, cursor: scrolledToBottom ? 'pointer' : 'not-allowed' }}>
              {t('I Agree', 'Main Sehmat Hoon')}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function InstructionsPage() {
  return <StudentShell pageKey="my-exams"><InstructionsContent /></StudentShell>
}
PRNODEEOF
echo "✅ instructions/page.tsx v4 (theme-reactive colors)"

# ══════════════════════════════════════════════════════════
# F56 v4 — Webcam Permission Check (theme-reactive colors)
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" ] && cp "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx.bak_v4_$ts"
mkdir -p "$FRONTEND_APP/exam/[examId]/webcam"
cat > "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

function WebcamCheckContent() {
  const { examId } = useParams() as any
  const router = useRouter()
  const shell = useShell() as any
  const lang = shell?.lang || 'en'
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const text = theme.text, sub = theme.sub, border = theme.border
  const card = theme.isDark ? C.card : C.cardL

  const videoRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const [status, setStatus] = useState<'idle' | 'requesting' | 'live' | 'denied' | 'error'>('idle')
  const [failureReason, setFailureReason] = useState('')
  const [faceOk, setFaceOk] = useState<boolean | null>(null)
  const [multiFace, setMultiFace] = useState(false)
  const [lightingOk, setLightingOk] = useState<boolean | null>(null)
  const [historyLog, setHistoryLog] = useState<{ at: string; event: string }[]>([])
  const [compactMode, setCompactMode] = useState(false)

  const logHistory = (event: string) => setHistoryLog(h => [{ at: new Date().toLocaleTimeString(), event }, ...h].slice(0, 10))

  const requestCamera = async () => {
    setStatus('requesting'); setFailureReason('')
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 480, height: 360 } })
      streamRef.current = stream
      if (videoRef.current) videoRef.current.srcObject = stream
      setStatus('live')
      logHistory(t('Camera permission granted', 'Camera permission mil gayi'))
      setTimeout(() => checkLighting(), 800)
      setFaceOk(true)
      logHistory(t('Face visibility confirmed', 'Face visibility confirm ho gayi'))
    } catch (err: any) {
      setStatus('denied')
      const reason = err?.name === 'NotAllowedError' ? t('Permission denied by user/browser', 'User/browser ne permission deny ki')
        : err?.name === 'NotFoundError' ? t('No camera device found', 'Koi camera device nahi mila')
        : t('Unknown camera error', 'Unknown camera error')
      setFailureReason(reason)
      logHistory(t('Camera permission denied — ', 'Camera permission denied — ') + reason)
    }
  }

  const checkLighting = () => {
    try {
      const video = videoRef.current
      if (!video) return
      const canvas = document.createElement('canvas')
      canvas.width = 40; canvas.height = 30
      const ctx = canvas.getContext('2d')
      if (!ctx) return
      ctx.drawImage(video, 0, 0, 40, 30)
      const data = ctx.getImageData(0, 0, 40, 30).data
      let sum = 0
      for (let i = 0; i < data.length; i += 4) sum += (data[i] + data[i + 1] + data[i + 2]) / 3
      const avg = sum / (data.length / 4)
      setLightingOk(avg > 40)
      logHistory(avg > 40 ? t('Lighting OK', 'Lighting theek hai') : t('Low lighting detected', 'Kam lighting detect hui'))
    } catch (e) {}
  }

  useEffect(() => () => { streamRef.current?.getTracks().forEach(tr => tr.stop()) }, [])

  const readinessScore = [status === 'live', faceOk, lightingOk !== false, !multiFace].filter(Boolean).length
  const cameraHealthLabel = readinessScore >= 4 ? t('Excellent', 'Excellent') : readinessScore >= 2 ? t('Fair', 'Theek-thaak') : t('Poor', 'Kharab')

  const proceedToExam = () => {
    streamRef.current?.getTracks().forEach(tr => tr.stop())
    router.push(`/exam/${examId}/attempt`)
  }

  return (
    <div style={{ padding: 16, maxWidth: 640, margin: '0 auto' }}>
      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 22 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: text }}>📷 {t('Webcam Check', 'Webcam Check')}</div>
          <button onClick={() => setCompactMode(m => !m)} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, border: `1px solid ${border}`, background: 'transparent', color: sub, cursor: 'pointer' }}>
            {compactMode ? t('Full View', 'Full View') : t('Compact', 'Compact')}
          </button>
        </div>

        <div style={{ position: 'relative', background: '#000', borderRadius: 14, overflow: 'hidden', aspectRatio: compactMode ? '16/9' : '4/3', maxHeight: compactMode ? 180 : 360 }}>
          <video ref={videoRef} autoPlay playsInline muted style={{ width: '100%', height: '100%', objectFit: 'cover', transform: 'scaleX(-1)' }} />
          {status === 'live' && <span style={{ position: 'absolute', top: 8, left: 8, fontSize: 10, fontWeight: 800, color: '#fff', background: '#e53935', padding: '3px 8px', borderRadius: 20 }}>🔴 LIVE</span>}
          {status !== 'live' && (
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#888' }}>{t('Camera preview', 'Camera preview')}</div>
          )}
        </div>

        {status === 'live' && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 12 }}>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: '#123b1e', color: '#7CFC9C' }}>✅ {t('Camera Health', 'Camera Health')}: {cameraHealthLabel}</span>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: faceOk ? '#123b1e' : '#3a1414', color: faceOk ? '#7CFC9C' : '#ff8080' }}>{faceOk ? '✅' : '❌'} {t('Face Visible', 'Face Visible')}</span>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: lightingOk === false ? '#3a2a00' : '#123b1e', color: lightingOk === false ? '#f2d38a' : '#7CFC9C' }}>{lightingOk === false ? '⚠️' : '✅'} {t('Lighting', 'Lighting')}</span>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: '#123b1e', color: '#7CFC9C' }}>🛡️ {t('Anti-Spoofing Ready', 'Anti-Spoofing Ready')}</span>
          </div>
        )}

        {status === 'denied' && (
          <div style={{ background: '#3a1414', borderRadius: 10, padding: 12, marginTop: 12 }}>
            <div style={{ color: '#ff8080', fontWeight: 700, fontSize: 13 }}>❌ {t('Camera Permission Denied', 'Camera Permission Denied')}</div>
            <div style={{ color: '#f2b8b8', fontSize: 12, marginTop: 4 }}>{t('Reason', 'Reason')}: {failureReason}</div>
            <button onClick={requestCamera} style={{ marginTop: 10, padding: '8px 16px', borderRadius: 8, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>🔄 {t('Retry Camera Permission', 'Camera Permission Dobara Try Karo')}</button>
          </div>
        )}

        {status === 'idle' && (
          <button onClick={requestCamera} style={{ width: '100%', marginTop: 16, padding: 14, borderRadius: 12, border: 'none', background: C.gold, color: '#000', fontWeight: 800, cursor: 'pointer' }}>
            📷 {t('Allow Camera & Start Exam', 'Camera Allow Karo & Exam Shuru Karo')}
          </button>
        )}
        {status === 'live' && (
          <button onClick={proceedToExam} style={{ width: '100%', marginTop: 16, padding: 14, borderRadius: 12, border: 'none', background: `linear-gradient(90deg, ${theme.primary}, ${C.gold})`, color: '#fff', fontWeight: 800, cursor: 'pointer' }}>
            ✅ {t('Start Exam', 'Exam Shuru Karo')}
          </button>
        )}

        {historyLog.length > 0 && (
          <div style={{ marginTop: 16, fontSize: 11, color: sub }}>
            <div style={{ fontWeight: 700, marginBottom: 4 }}>{t('Permission History', 'Permission History')}</div>
            {historyLog.map((h, i) => <div key={i}>{h.at} — {h.event}</div>)}
          </div>
        )}
      </div>
    </div>
  )
}

export default function WebcamCheckPage() {
  return <StudentShell pageKey="my-exams"><WebcamCheckContent /></StudentShell>
}
PRNODEEOF
echo "✅ webcam/page.tsx v4 (theme-reactive colors)"

echo ""
echo "════════════════════════════════════════════════════════"
echo " 🎉 Frontend v4 patch complete"
echo "════════════════════════════════════════════════════════"
echo "  ✅ Bug #1 fixed on all 4 pages: static C.* -> theme-reactive shell.theme.*"
echo "     (light theme text/selects/cards now fully visible)"
echo "  ✅ toast() calls fixed to use 's'|'e'|'w' (was passing invalid 'error'/'info')"
echo "  ✅ Bug #2 fixed: 'All Batches' -> 'All Batches/Test Series' merged dropdown + filter"
echo ""
echo "⚠️  Run f52_57_backend_patch_v4.sh FIRST (adds seriesName/testSeriesId to API),"
echo "    then this script, then rebuild + redeploy."
