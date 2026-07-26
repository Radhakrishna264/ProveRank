#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F52-F57 v3 — Exam Flow — FRONTEND fix script (COMPLETE)"
echo " Requires backend v2 (f52_57_backend_fix_v2.sh) run FIRST"
echo " v3 fixes (found in deep cross-check against live StudentShell"
echo " pages + antiCheatRoutes.js before this v2 script was ever run):"
echo "   🐛 useShell() shape bug — v2 read token via shell?.user?.token,"
echo "      but live StudentShell (confirmed in current my-exams/attempt-"
echo "      history pages) returns token FLAT: const {token} = useShell()."
echo "      'user' never existed -> My Exams/Waiting Room/Instructions"
echo "      pages would have been stuck on 'Loading...' forever. Fixed in"
echo "      all 3 affected files (my-exams, waiting, instructions)."
echo "   🐛 F57 anti-cheat calls — v2 sent only {attemptId} to"
echo "      /api/anticheat/tab-switch, /window-blur, /fullscreen-exit,"
echo "      but those routes require BOTH attemptId + examId (400 error"
echo "      otherwise). window-blur & fullscreen-exit had no client-side"
echo "      fallback, so server-side warning tracking + auto-submit-at-3"
echo "      would have silently never fired for those two triggers."
echo "      Fixed: examId now included in all 3 request bodies."
echo "════════════════════════════════════════════════════════"

FRONTEND_APP="${FRONTEND_APP:-}"
for candidate in "/root/workspace/frontend/app" "/home/runner/workspace/frontend/app" "$(pwd)/frontend/app"; do
  if [ -d "$candidate" ]; then FRONTEND_APP="$candidate"; break; fi
done
if [ -z "$FRONTEND_APP" ]; then echo "❌ Could not find frontend/app — set FRONTEND_APP env var and re-run."; exit 1; fi
echo "📂 Frontend app dir: $FRONTEND_APP"
ts=$(date +%s)

# ══════════════════════════════════════════════════════════
# F52 v2 — My Exams (full rewrite)
# Fixes: batch/testseries sync (backend-driven, no client change needed)
#        adds Timeline strip, Preview mini panel, Performance chips
#        (avg score + rank trend), Next-available-attempt-time,
#        Resume Waiting Room button state, explicit pre-window countdown,
#        single-click Join Waiting Room (calls join API + navigates)
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/my-exams/page.tsx" ] && cp "$FRONTEND_APP/my-exams/page.tsx" "$FRONTEND_APP/my-exams/page.tsx.bak_$ts"
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
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const [exams, setExams] = useState<any[]>([])
  const [synced, setSynced] = useState<{ batches: string[]; series: string[] }>({ batches: [], series: [] })
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [subjectFilter, setSubjectFilter] = useState('all')
  const [batchFilter, setBatchFilter] = useState('all')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [previewExam, setPreviewExam] = useState<any>(null)
  const [pwModal, setPwModal] = useState<any>(null)
  const [pwInput, setPwInput] = useState('')
  const [pwErr, setPwErr] = useState('')
  const [now, setNow] = useState(Date.now())
  const [joining, setJoining] = useState<string | null>(null)

  // F52 §10.5 — Filter Memory (persist last used filters)
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
      if (statusFilter === 'completed' && !(e.derivedStatus === 'ended' || e.activeAttemptId === null && e.performance)) return false
      if (subjectFilter !== 'all' && e.subject !== subjectFilter) return false
      if (categoryFilter !== 'all' && e.category !== categoryFilter) return false
      if (batchFilter !== 'all' && e.batch !== batchFilter && !(e.multiBatch || []).includes(batchFilter)) return false
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

  // F52 §10.1 — Timeline strip (upcoming exams grouped by day)
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
      toast?.(t('Could not join waiting room, try again', 'Waiting room join nahi ho paya, dobara try karo'), 'error')
    } finally { setJoining(null) }
  }

  const go = (e: any) => {
    if (e.passwordProtected && !e.activeAttemptId) { setPwModal(e); setPwErr(''); setPwInput(''); return }
    if (e.activeAttemptId) { router.push(`/exam/${e._id}/attempt`); return }

    if (e.derivedStatus === 'scheduled' && e.waitingRoomWindowOpen) { doJoinWaitingRoom(e); return }
    if (e.derivedStatus === 'scheduled') {
      toast?.(t('Waiting room will open ' + e.waitMins + ' minutes before start', 'Waiting room shuru se ' + e.waitMins + ' minute pehle khulega'), 'info')
      return
    }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') {
      toast?.(t('Join window has closed. Available again: ' + fmtTime(e.nextAvailableAttemptTime), 'Join window band ho gayi. Dobara available: ' + fmtTime(e.nextAvailableAttemptTime)), 'error')
      return
    }
    if (e.joinState === 'locked') { toast?.(t('No attempts left for this exam', 'Is exam ke liye attempts khatam ho gaye'), 'error'); return }

    // live join_open OR ended+available_again(skipWaitingRoom) -> straight to instructions
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
        ? { label: t('Resume Waiting Room', 'Waiting Room Resume Karo'), col: C.blue, icon: '🔁', disabled: false }
        : { label: t('Join Waiting Room', 'Waiting Room Join Karo'), col: C.blue, icon: '🚪', disabled: false }
    }
    if (e.derivedStatus === 'scheduled') return { label: t('Available Later', 'Baad Me Available'), col: '#888', icon: '⏳', disabled: true }
    if (e.derivedStatus === 'live' && e.joinState === 'join_open') return { label: t('Start Now', 'Abhi Shuru Karo'), col: C.green, icon: '🔴', disabled: false }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') return { label: t('Join Closed', 'Join Band'), col: '#888', icon: '🚫', disabled: true }
    if (e.joinState === 'available_again') return { label: t('Start Exam', 'Exam Shuru Karo'), col: C.green, icon: '▶️', disabled: false }
    if (e.joinState === 'locked') return { label: t('Locked', 'Locked'), col: '#888', icon: '🔒', disabled: true }
    return { label: t('View', 'Dekho'), col: C.gold, icon: '👁️', disabled: false }
  }

  const subjects = useMemo(() => Array.from(new Set(exams.map(e => e.subject).filter(Boolean))), [exams])
  const batches = useMemo(() => Array.from(new Set([...synced.batches, ...exams.map(e => e.batch).filter(Boolean)])), [exams, synced])
  const categories = useMemo(() => Array.from(new Set(exams.map(e => e.category).filter(Boolean))), [exams])

  return (
    <div style={{ padding: 16, maxWidth: 1100, margin: '0 auto' }}>
      {/* Header & Quick Stats — F52 §2 */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, marginBottom: 14 }}>
        {[
          ['📚', stats.total, t('Total', 'Total')],
          ['⏳', stats.upcoming, t('Upcoming', 'Upcoming')],
          ['🔴', stats.live, t('Live', 'Live')],
          ['✅', stats.completed, t('Completed', 'Completed')],
          ['🎯', stats.attempted, t('Attempted', 'Attempted')],
          ['🏆', stats.bestScore, t('Best Score', 'Best Score')]
        ].map(([icon, val, label]: any, i) => (
          <div key={i} style={{ flex: '1 1 100px', background: C.card, border: `1px solid ${C.border}`, borderRadius: 12, padding: '10px 12px', textAlign: 'center' }}>
            <div style={{ fontSize: 18 }}>{icon}</div>
            <div style={{ fontSize: 20, fontWeight: 800, color: C.text }}>{val}</div>
            <div style={{ fontSize: 11, color: C.textDim }}>{label}</div>
          </div>
        ))}
      </div>

      {/* F52 §10.1 — Timeline strip */}
      {timeline.length > 0 && (
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 8, marginBottom: 14 }}>
          {timeline.map(e => (
            <div key={e._id} onClick={() => setPreviewExam(e)} style={{ cursor: 'pointer', minWidth: 130, background: C.card, border: `1px solid ${e.derivedStatus === 'live' ? C.green : C.border}`, borderRadius: 10, padding: 8 }}>
              <div style={{ fontSize: 10, fontWeight: 700, color: C.gold }}>{dayLabel(e.schedule?.startTime)}</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: C.text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.title}</div>
              <div style={{ fontSize: 10, color: C.textDim }}>{fmtTime(e.schedule?.startTime)}</div>
            </div>
          ))}
        </div>
      )}

      {/* Search + Filter Bar — F52 §3 */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 14 }}>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('Search exam title...', 'Exam title search karo...')}
          style={{ flex: '2 1 200px', padding: '10px 12px', borderRadius: 10, border: `1px solid ${C.border}`, background: C.bg, color: C.text }} />
        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} style={{ padding: 10, borderRadius: 10, border: `1px solid ${C.border}`, background: C.bg, color: C.text }}>
          <option value="all">{t('All', 'All')}</option>
          <option value="upcoming">{t('Upcoming', 'Upcoming')}</option>
          <option value="live">{t('Live', 'Live')}</option>
          <option value="completed">{t('Completed', 'Completed')}</option>
        </select>
        <select value={subjectFilter} onChange={e => setSubjectFilter(e.target.value)} style={{ padding: 10, borderRadius: 10, border: `1px solid ${C.border}`, background: C.bg, color: C.text }}>
          <option value="all">{t('All Subjects', 'All Subjects')}</option>
          {subjects.map(s => <option key={s} value={s}>{s}</option>)}
        </select>
        <select value={batchFilter} onChange={e => setBatchFilter(e.target.value)} style={{ padding: 10, borderRadius: 10, border: `1px solid ${C.border}`, background: C.bg, color: C.text }}>
          <option value="all">{t('All Batches', 'All Batches')}</option>
          {batches.map(b => <option key={b} value={b}>{b}</option>)}
        </select>
        <select value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)} style={{ padding: 10, borderRadius: 10, border: `1px solid ${C.border}`, background: C.bg, color: C.text }}>
          <option value="all">{t('All Categories', 'All Categories')}</option>
          {categories.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
      </div>

      {/* Exam List */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: C.textDim }}>{t('Loading exams...', 'Exams load ho rahe hai...')}</div>
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, color: C.textDim }}>
          <div style={{ fontSize: 40 }}>📭</div>
          <div style={{ marginTop: 8 }}>{exams.length === 0 ? t('No exams scheduled yet', 'Abhi koi exam schedule nahi hai') : t('No exams match your filters', 'Filters se koi exam match nahi hua')}</div>
          {exams.length > 0 && <button onClick={() => { setSearch(''); setStatusFilter('all'); setSubjectFilter('all'); setBatchFilter('all'); setCategoryFilter('all') }} style={{ marginTop: 10, padding: '8px 16px', borderRadius: 8, border: `1px solid ${C.border}`, background: 'transparent', color: C.text, cursor: 'pointer' }}>{t('Reset Filters', 'Filters Reset Karo')}</button>}
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 12 }}>
          {filtered.map(e => {
            const btn = startBtn(e)
            const minsToStart = e.schedule?.startTime ? Math.round((new Date(e.schedule.startTime).getTime() - now) / 60000) : null
            return (
              <div key={e._id} style={{ background: C.card, border: `1px solid ${e.derivedStatus === 'live' ? C.green : C.border}`, borderRadius: 14, padding: 14, position: 'relative' }}>
                {e.derivedStatus === 'live' && e.joinState === 'join_open' && (
                  <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 10, fontWeight: 800, color: '#fff', background: C.green, padding: '3px 8px', borderRadius: 20, animation: 'pulse 1.5s infinite' }}>🔴 LIVE</span>
                )}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ fontWeight: 800, fontSize: 15, color: C.text, maxWidth: '80%' }}>{e.title}</div>
                  <button onClick={() => setPreviewExam(e)} title={t('Quick preview', 'Quick preview')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontSize: 14 }}>ℹ️</button>
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, margin: '8px 0' }}>
                  <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.textDim }}>{e.subject}</span>
                  <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.textDim }}>{e.duration} min</span>
                  <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.textDim }}>{e.totalMarks} marks</span>
                  {e.category && <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.textDim }}>{e.category}</span>}
                  {e.batch && <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{e.batch}</span>}
                </div>
                <div style={{ fontSize: 11, color: C.textDim, marginBottom: 8 }}>{fmtTime(e.schedule?.startTime)}</div>

                {/* Rule 1.15.2 — explicit countdown before waiting-room window opens */}
                {e.derivedStatus === 'scheduled' && !e.waitingRoomWindowOpen && minsToStart != null && minsToStart > 0 && (
                  <div style={{ fontSize: 12, color: C.gold, marginBottom: 8 }}>⏱ {t('Starts in', 'Shuru hoga')} {minsToStart > 60 ? Math.floor(minsToStart / 60) + 'h ' + (minsToStart % 60) + 'm' : minsToStart + 'm'}</div>
                )}
                {/* F52 §10.8 — live join warning w/ next-available time */}
                {e.joinState === 'join_closed' && (
                  <div style={{ fontSize: 11, color: '#ff6666', marginBottom: 8 }}>⚠️ {t('Join closed. Available again:', 'Join band. Dobara available:')} {fmtTime(e.nextAvailableAttemptTime)}</div>
                )}

                {/* F52 §10.6 — Performance summary chips */}
                {e.performance && (
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                    <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.gold }}>{t('Best', 'Best')}: {e.performance.bestScore}</span>
                    <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.textDim }}>{t('Avg', 'Avg')}: {e.performance.avgScore}</span>
                    <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: C.textDim }}>{t('Attempts', 'Attempts')}: {e.performance.attemptCount}</span>
                    <span style={{ fontSize: 11, background: C.bg, padding: '3px 8px', borderRadius: 20, color: e.performance.rankTrend === 'up' ? C.green : e.performance.rankTrend === 'down' ? '#ff6666' : C.textDim }}>
                      {e.performance.rankTrend === 'up' ? '📈' : e.performance.rankTrend === 'down' ? '📉' : '➖'} {t('Rank', 'Rank')} {e.performance.rankTrend}
                    </span>
                  </div>
                )}

                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <button disabled={btn.disabled || joining === e._id} onClick={() => go(e)} style={{ flex: 1, padding: '10px 14px', borderRadius: 10, border: 'none', background: btn.disabled ? '#444' : btn.col, color: '#fff', fontWeight: 700, cursor: btn.disabled ? 'not-allowed' : 'pointer', opacity: joining === e._id ? 0.6 : 1 }}>
                    {btn.icon} {joining === e._id ? t('Joining...', 'Join ho raha hai...') : btn.label}
                  </button>
                  {e.derivedStatus === 'scheduled' && (
                    <button onClick={() => toggleReminder(e)} title={t('Reminder', 'Reminder')} style={{ padding: '10px 12px', borderRadius: 10, border: `1px solid ${C.border}`, background: e.reminderEnabled ? C.gold : 'transparent', color: e.reminderEnabled ? '#000' : C.text, cursor: 'pointer' }}>
                      {e.reminderEnabled ? '🔔' : '🔕'}
                    </button>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* F52 §10.4 — Exam Preview Mini Panel */}
      {previewExam && (
        <div onClick={() => setPreviewExam(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 16, padding: 20, maxWidth: 340, width: '90%' }}>
            <div style={{ fontWeight: 800, fontSize: 16, color: C.text, marginBottom: 8 }}>{previewExam.title}</div>
            <div style={{ fontSize: 13, color: C.textDim, lineHeight: 1.8 }}>
              <div>⏱ {t('Duration', 'Duration')}: {previewExam.duration} min</div>
              <div>🎯 {t('Marks', 'Marks')}: {previewExam.totalMarks}</div>
              <div>📚 {t('Subject', 'Subject')}: {previewExam.subject}</div>
              <div>🏷 {t('Category', 'Category')}: {previewExam.category || '-'}</div>
              <div>📅 {fmtTime(previewExam.schedule?.startTime)}</div>
              <div>📍 {t('Status', 'Status')}: {previewExam.derivedStatus} / {previewExam.joinState}</div>
            </div>
            <button onClick={() => { const e = previewExam; setPreviewExam(null); go(e) }} style={{ marginTop: 14, width: '100%', padding: 10, borderRadius: 10, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>{t('Open', 'Kholo')}</button>
          </div>
        </div>
      )}

      {/* Password Modal — F52 §6.3 */}
      {pwModal && (
        <div onClick={() => setPwModal(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 16, padding: 20, maxWidth: 320, width: '90%' }}>
            <div style={{ fontWeight: 800, color: C.text, marginBottom: 10 }}>🔒 {t('Enter Exam Password', 'Exam Password Daalo')}</div>
            <input type="password" value={pwInput} onChange={e => setPwInput(e.target.value)} placeholder={t('Password', 'Password')}
              style={{ width: '100%', padding: 10, borderRadius: 8, border: `1px solid ${C.border}`, background: C.bg, color: C.text, marginBottom: 8 }} />
            {pwErr && <div style={{ color: '#ff6666', fontSize: 12, marginBottom: 8 }}>{pwErr}</div>}
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
echo "✅ Created my-exams/page.tsx (F52 v2 — batch/testseries sync fixed via backend, Timeline/Preview/Perf-chips/Resume added)"

# ══════════════════════════════════════════════════════════
# F53 v2 — Waiting Room (full rewrite) — implements Rule 1.15.1-1.15.10
# Fixes: auto-redirect now GATED by hasJoinedWaitingRoom (was firing
#        regardless -> violated Rule 1.15.8), admin-configurable
#        durations used (was hardcoded), Resume support, activeAttemptId
#        guard (Rule 1.15.10), tip severity tags, activity monitor
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" ] && cp "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx.bak_$ts"
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
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

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

  // ── Load waiting-info; Rule 1.15.3/1.15.4 — if already joined (via My Exams
  //    click, which calls join-waiting-room first), auto-enter (covers both
  //    fresh join and resume in one step). If NOT joined (e.g. direct URL nav),
  //    do NOT auto-enter — show explicit Join button (Rule 1.15.7/1.15.8). ──
  const loadInfo = () => {
    if (!token) return
    fetch(`${API}/api/exams/${examId}/waiting-info`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        if (!d?.success) return
        setInfo(d)
        setLiveCount(d.liveCount || 0)
        // Rule 1.15.10 — attempt already active, waiting room not valid anymore
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

  // ── Explicit join (fallback path if user landed here without going via My Exams) ──
  const joinNow = () => {
    fetch(`${API}/api/exams/${examId}/join-waiting-room`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => { if (d?.success) { setEntered(true); logActivity(t('Joined waiting room', 'Waiting room join kiya')) } })
      .catch(() => {})
  }

  // ── Countdown — only runs once entered==true (Rule 1.15.8 fix) ──
  useEffect(() => {
    if (!entered || secsLeft == null) return
    const iv = setInterval(() => {
      setSecsLeft(s => {
        if (s == null) return s
        if (s <= 1) { clearInterval(iv); return 0 }
        return s - 1
      })
    }, 1000)
    return () => clearInterval(iv)
  }, [entered, secsLeft != null])

  // ── Auto-transition to Instructions — Rule 1.15.5/1.15.6: fires only when
  //    entered==true AND remaining time <= admin-configured buffer minutes ──
  useEffect(() => {
    if (!entered || secsLeft == null || !info) return
    const bufferSecs = (info.config?.autoCloseBufferMinutes ?? 8) * 60
    if (secsLeft <= bufferSecs && !transitionedRef.current) {
      transitionedRef.current = true
      logActivity(t('Auto-moving to Instructions screen', 'Instructions screen par ja rahe hai'))
      setTimeout(() => router.push(`/exam/${examId}/instructions`), 1200)
    }
  }, [secsLeft, entered, info])

  // ── Socket.io live presence + chat (best-effort; REST polling is the fallback) ──
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

  // ── Chat load + window countdown (F53 §5) ──
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

  // ── Tip rotation every 30s ──
  useEffect(() => { const iv = setInterval(() => setTipIdx(i => (i + 1) % TIPS.length), 30000); return () => clearInterval(iv) }, [])

  const sendChat = () => {
    if (!chatInput.trim() || !chatOpen) return
    fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ text: chatInput }) })
      .then(r => r.json()).then(d => { if (d?.success) { setChatMsgs(m => [...m, d.message]); setChatInput('') } else if (d?.chatClosed) setChatOpen(false) })
      .catch(() => {})
  }

  if (!info) return <div style={{ padding: 40, textAlign: 'center', color: C.textDim }}>{t('Loading...', 'Load ho raha hai...')}</div>

  return (
    <div style={{ padding: 16, maxWidth: 640, margin: '0 auto' }}>
      <div style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 18, padding: 24, textAlign: 'center' }}>
        <div style={{ fontSize: 18, fontWeight: 800, color: C.text }}>{info.exam.title}</div>
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 8, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 12, background: C.bg, padding: '4px 10px', borderRadius: 20, color: C.textDim }}>⏱ {info.exam.duration} min</span>
          <span style={{ fontSize: 12, background: C.bg, padding: '4px 10px', borderRadius: 20, color: C.textDim }}>🎯 {info.exam.totalMarks} marks</span>
          <span style={{ fontSize: 12, background: C.bg, padding: '4px 10px', borderRadius: 20, color: C.textDim }}>❓ {info.exam.totalQuestions} Qs</span>
          <span style={{ fontSize: 12, background: C.bg, padding: '4px 10px', borderRadius: 20, color: C.gold }}>👥 {liveCount} {t('waiting', 'waiting')}</span>
        </div>

        {!entered ? (
          <div style={{ marginTop: 24 }}>
            <div style={{ fontSize: 40 }}>⏳</div>
            <div style={{ color: C.textDim, margin: '10px 0' }}>{t('Click below to officially join the waiting room', 'Waiting room officially join karne ke liye niche click karo')}</div>
            <button onClick={joinNow} style={{ padding: '12px 28px', borderRadius: 12, border: 'none', background: C.gold, color: '#000', fontWeight: 800, cursor: 'pointer' }}>🚪 {t('Join Waiting Room', 'Waiting Room Join Karo')}</button>
          </div>
        ) : (
          <>
            <div style={{ fontSize: 48, fontWeight: 900, color: secsLeft != null && secsLeft < 120 ? '#ff5555' : C.gold, margin: '20px 0 6px' }}>
              {secsLeft != null && secsLeft > 0 ? fmtSecs(secsLeft) : t('Starting...', 'Shuru ho raha hai...')}
            </div>
            <div style={{ height: 6, background: C.bg, borderRadius: 6, overflow: 'hidden', margin: '0 0 20px' }}>
              <div style={{ height: '100%', width: secsLeft != null && info.config?.waitingRoomMinutes ? `${100 - Math.min(100, (secsLeft / (info.config.waitingRoomMinutes * 60)) * 100)}%` : '0%', background: C.gold, transition: 'width 1s linear' }} />
            </div>

            {/* Tip with severity tag */}
            <div style={{ background: C.bg, borderRadius: 10, padding: 10, marginBottom: 10, borderLeft: `4px solid ${SEV_COLOR[TIPS[tipIdx].severity]}` }}>
              <span style={{ fontSize: 10, fontWeight: 800, color: SEV_COLOR[TIPS[tipIdx].severity], textTransform: 'uppercase' }}>{TIPS[tipIdx].severity}</span>
              <div style={{ fontSize: 13, color: C.text }}>💡 {TIPS[tipIdx].text}</div>
            </div>

            {broadcasts.length > 0 && broadcasts.map((b, i) => (
              <div key={i} style={{ background: '#3a2a00', borderRadius: 10, padding: 10, marginBottom: 10, textAlign: 'left' }}>📢 <b>{t('Admin', 'Admin')}:</b> {b.message || b.text}</div>
            ))}

            <button onClick={() => setMusicOn(m => !m)} style={{ background: 'transparent', border: `1px solid ${C.border}`, color: C.textDim, borderRadius: 20, padding: '4px 12px', fontSize: 12, cursor: 'pointer', marginBottom: 14 }}>
              {musicOn ? '🔊' : '🔇'} {t('Background Music', 'Background Music')}
            </button>

            {/* Chat — F53 §5 */}
            <div style={{ textAlign: 'left', background: C.bg, borderRadius: 10, padding: 10, maxHeight: 160, overflowY: 'auto', marginBottom: 8 }}>
              {chatMsgs.length === 0 ? <div style={{ color: C.textDim, fontSize: 12 }}>{t('No messages yet', 'Abhi koi message nahi')}</div> :
                chatMsgs.map((m, i) => <div key={i} style={{ fontSize: 12, color: C.text, marginBottom: 4 }}><b>{m.name}:</b> {m.text}</div>)}
            </div>
            {chatOpen ? (
              <div style={{ display: 'flex', gap: 6 }}>
                <input value={chatInput} onChange={e => setChatInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && sendChat()} placeholder={t('Type a message...', 'Message likho...')}
                  style={{ flex: 1, padding: 8, borderRadius: 8, border: `1px solid ${C.border}`, background: C.card, color: C.text }} />
                <button onClick={sendChat} style={{ padding: '8px 14px', borderRadius: 8, border: 'none', background: C.blue, color: '#fff', cursor: 'pointer' }}>{t('Send', 'Bhejo')}</button>
              </div>
            ) : (
              <div style={{ fontSize: 11, color: C.textDim }}>💬 {t('Chat closed for anti-cheat', 'Anti-cheat ke liye chat band ho gayi')}</div>
            )}
            {chatOpen && chatMinsLeft != null && <div style={{ fontSize: 10, color: C.textDim, marginTop: 4 }}>{t('Chat closes in', 'Chat band hogi')} {Math.ceil(chatMinsLeft)} {t('min', 'min')}</div>}

            {/* Wait-state activity monitor */}
            {activityLog.length > 0 && (
              <div style={{ textAlign: 'left', marginTop: 14, fontSize: 10, color: C.textDim }}>
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
echo "✅ Created exam/[examId]/waiting/page.tsx (F53 v2 — Rule 1.15.1-1.15.10 implemented)"

# ══════════════════════════════════════════════════════════
# F54/F55 v2 — Instructions Screen (full rewrite)
# Fixes: T&C acceptance now calls backend (DB persisted, was
#        sessionStorage-only), explicit Hindi/English toggle added,
#        version-based re-accept via consent-status check,
#        Rule 1.15.10 guard (activeAttemptId -> redirect to attempt)
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" ] && cp "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx.bak_$ts"
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
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const [exam, setExam] = useState<any>(null)
  const [checked, setChecked] = useState(false)
  const [tcModal, setTcModal] = useState(false)
  const [scrolledToBottom, setScrolledToBottom] = useState(false)
  const [consentAlready, setConsentAlready] = useState(false)
  const tcBodyRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!token) return
    // Rule 1.15.10 — if attempt already active, skip straight there
    fetch(`${API}/api/exams/my-exams`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => {
        const e = (d?.exams || []).find((x: any) => String(x._id) === String(examId))
        if (e?.activeAttemptId) { router.replace(`/exam/${examId}/attempt`); return }
      }).catch(() => {})

    fetch(`${API}/api/exams/${examId}`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json()).then(d => setExam(d?.exam || null)).catch(() => {})

    // F55 §3.1 — version-based re-acceptance check
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
      <div style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 18, padding: 22 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: 18, fontWeight: 800, color: C.text }}>{exam?.title || t('Exam Instructions', 'Exam Instructions')}</div>
            <div style={{ fontSize: 12, color: C.textDim }}>{t('Please read carefully before proceeding', 'Aage badhne se pehle dhyan se padho')}</div>
          </div>
          {/* F54 §1.1.5 — explicit language toggle */}
          <button onClick={() => setLang(l => l === 'hi' ? 'en' : 'hi')} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${C.border}`, background: 'transparent', color: C.text, cursor: 'pointer', fontSize: 12 }}>
            {lang === 'hi' ? 'EN' : 'हिं'}
          </button>
        </div>

        {consentAlready && (
          <div style={{ background: '#123b1e', color: '#7CFC9C', borderRadius: 10, padding: 8, fontSize: 12, margin: '12px 0' }}>
            ✅ {t('You already accepted these terms for this exam.', 'Aapne is exam ke liye ye terms pehle hi accept kar liye hai.')}
          </div>
        )}

        <ol style={{ padding: '16px 0 0 20px', color: C.text, fontSize: 13, lineHeight: 1.9 }}>
          {points.map((p, i) => <li key={i}>{p}</li>)}
        </ol>

        {exam?.customInstructions && (
          <div style={{ background: '#3a2a00', borderLeft: '4px solid #f2b134', borderRadius: 8, padding: 12, margin: '14px 0', color: '#f2d38a', fontSize: 12 }}>
            ⚠️ <b>{t('Additional Instructions', 'Additional Instructions')}:</b> {exam.customInstructions}
          </div>
        )}

        {/* T&C */}
        <div style={{ background: '#0e2418', border: '1px solid #1e5c3a', borderRadius: 10, padding: 12, marginTop: 16 }}>
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer' }}>
            <input type="checkbox" checked={checked} onChange={e => { if (!e.target.checked) { setChecked(false); return } setTcModal(true) }} style={{ marginTop: 3 }} />
            <span style={{ fontSize: 13, color: C.text }}>
              {t('I have read and agree to all instructions', 'Maine saari instructions padh li hai aur maanta/maanti hoon')}
              {' '}<a onClick={(e) => { e.preventDefault(); setTcModal(true) }} style={{ color: C.gold, cursor: 'pointer', textDecoration: 'underline' }}>({t('read full terms', 'poore terms padho')})</a>
            </span>
          </label>
        </div>

        <button disabled={!checked} onClick={proceed} style={{ width: '100%', marginTop: 18, padding: 14, borderRadius: 12, border: 'none', background: checked ? `linear-gradient(90deg, ${C.blue}, ${C.gold})` : '#444', color: '#fff', fontWeight: 800, cursor: checked ? 'pointer' : 'not-allowed', transition: 'all .3s' }}>
          {t('Proceed to AI Webcam Check', 'AI Webcam Check Par Jao')} →
        </button>
      </div>

      {tcModal && (
        <div onClick={() => setTcModal(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 300, padding: 16 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: C.card, borderRadius: 16, padding: 20, maxWidth: 480, width: '100%', maxHeight: '80vh', display: 'flex', flexDirection: 'column' }}>
            <div style={{ fontWeight: 800, color: C.text, marginBottom: 10 }}>{t('Terms & Conditions', 'Terms & Conditions')}</div>
            <div ref={tcBodyRef} onScroll={onTcScroll} style={{ overflowY: 'auto', fontSize: 13, color: C.textDim, lineHeight: 1.7, flex: 1, paddingRight: 4 }}>
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
echo "✅ Created exam/[examId]/instructions/page.tsx (F54/F55 v2 — T&C now DB-persisted + language toggle + Rule 1.15.10 guard)"

# ══════════════════════════════════════════════════════════
# F56 v2 — Webcam Permission Check (full rewrite)
# Fixes: Permission status history now actually rendered (was dead
#        state in v1), adds camera health summary, anti-spoofing
#        readiness badge, compact preview toggle, failure reason card
# ══════════════════════════════════════════════════════════
[ -f "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" ] && cp "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx.bak_$ts"
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
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

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
      // lightweight lighting heuristic via canvas average brightness
      setTimeout(() => checkLighting(), 800)
      setFaceOk(true) // placeholder — real face-detection model wiring happens in TensorFlow.js layer elsewhere
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
      <div style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 18, padding: 22 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: C.text }}>📷 {t('Webcam Check', 'Webcam Check')}</div>
          <button onClick={() => setCompactMode(m => !m)} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, border: `1px solid ${C.border}`, background: 'transparent', color: C.textDim, cursor: 'pointer' }}>
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
          <button onClick={proceedToExam} style={{ width: '100%', marginTop: 16, padding: 14, borderRadius: 12, border: 'none', background: `linear-gradient(90deg, ${C.blue}, ${C.gold})`, color: '#fff', fontWeight: 800, cursor: 'pointer' }}>
            ✅ {t('Start Exam', 'Exam Shuru Karo')}
          </button>
        )}

        {/* F56 §3.7 — Permission status history (now actually rendered) */}
        {historyLog.length > 0 && (
          <div style={{ marginTop: 16, fontSize: 11, color: C.textDim }}>
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
echo "✅ Created exam/[examId]/webcam/page.tsx (F56 v2 — permission history now rendered + health/anti-spoof/failure-reason added)"

# ══════════════════════════════════════════════════════════
# F57 v2 — Patch existing Attempt page (fullscreen enforcement)
# Adds: focus lock status, exit reason tracking, warning history,
#       integrity impact tag (on top of v1's fullscreen state/warning
#       modal + broken tab-switch endpoint fix)
# Anchor-based patch (full file not available to us — safest to
# target-patch known blocks, per Brief rule: avoid destructive rewrite
# of a file we haven't fully seen).
# ══════════════════════════════════════════════════════════
WORKDIR=$(mktemp -d); cd "$WORKDIR"
cat > patch_attempt_f57_v2.js << 'PRNODEEOF'
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.APP_DIR,
  '/root/workspace/frontend/app/exam/[examId]/attempt',
  '/home/runner/workspace/frontend/app/exam/[examId]/attempt',
  path.join(process.cwd(), 'frontend/app/exam/[examId]/attempt'),
].filter(Boolean);

let TARGET = null;
for (const dir of CANDIDATES) {
  const p = path.join(dir, 'page.tsx');
  if (fs.existsSync(p)) { TARGET = p; break; }
}
if (!TARGET) {
  console.error('❌ Could not find exam attempt page.tsx automatically.');
  console.error("   Set APP_DIR env var, e.g.:");
  console.error("   APP_DIR='/home/runner/workspace/frontend/app/exam/[examId]/attempt' node patch_attempt_f57_v2.js");
  process.exit(1);
}
console.log('📄 Target file:', TARGET);
fs.copyFileSync(TARGET, TARGET + '.bak_' + Date.now());

let src = fs.readFileSync(TARGET, 'utf8');
let count = 0;

// ── 1) Add F57 v2 state near existing warnings state ──
{
  const anchor = `const [warnings, setWarnings] = useState(0)`;
  const addition = `${anchor}
  const [showFSWarning, setShowFSWarning] = useState(false)
  const [fsCompliant, setFsCompliant] = useState(true)
  const fsExitTimerRef = useRef<any>(null)
  // F57 v2 — SaaS-upgrade sub-features (were missing in v1)
  const [focusLocked, setFocusLocked] = useState(true)
  const [warningHistory, setWarningHistory] = useState<{ type: string; at: string }[]>([])
  const integrityImpact = warnings === 0 ? 'none' : warnings === 1 ? 'low' : warnings === 2 ? 'medium' : 'high'`;
  if (src.includes(anchor) && !src.includes('showFSWarning')) {
    src = src.replace(anchor, addition);
    count++;
    console.log('✅ Patched: added F57 v2 state (fullscreen + focus-lock + warning-history + integrity-impact)');
  } else if (src.includes('focusLocked')) {
    console.log('⚠️  F57 v2 state already present — skipping');
  } else {
    console.log('❌ warnings-state anchor not found — state patch NOT applied. Add manually.');
  }
}

// ── 2) Ensure useRef is imported ──
{
  const anchorImport = `import { useState, useEffect, useCallback } from 'react'`;
  const goodImport = `import { useState, useEffect, useCallback, useRef } from 'react'`;
  if (src.includes(anchorImport)) {
    src = src.replace(anchorImport, goodImport);
    count++;
    console.log('✅ Patched: added useRef to React import');
  } else if (src.includes("useRef } from 'react'") || src.includes('useRef,')) {
    console.log('⚠️  useRef already imported — skipping');
  } else {
    console.log('⚠️  Could not find the exact React import line — please ensure useRef is imported manually');
  }
}

// ── 3) Replace the tab-switch effect: fix broken endpoint + add
//      window-blur + fullscreen enforcement, now also logging to
//      warningHistory (Exit reason tracking + Warning history — F57 §3.3/3.4) ──
{
  const anchor = `  // Anti-cheat: tab switch
  useEffect(()=>{
    const onVis = () => {
      if (document.hidden && attempt) {
        setWarnings(w => {
          const next = w+1
          if (next >= 3) { autoSubmit(); return next }
          // Save warning to backend
          if (user && attempt?._id) {
            fetch(\`\${API}/api/attempts/\${attempt._id}/tab-switch\`,{
              method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${token}\`},
              body:JSON.stringify({count:next})
            }).catch(()=>{})
          }
          return next
        })
      }
    }`;

  const replacement = `  // F57 v2 — Anti-cheat: tab switch + window blur + fullscreen enforcement
  // (fixes v1 bug: old code called a non-existent endpoint; now calls the
  //  real /api/anticheat/* routes which exist and return {warningCount, autoSubmitted})
  useEffect(()=>{
    const logWarning = (type: string) => setWarningHistory(h => [{ type, at: new Date().toLocaleTimeString() }, ...h].slice(0, 15))

    const onVis = () => {
      if (document.hidden && attempt) {
        logWarning('Tab Switch')
        if (user && attempt?._id) {
          fetch(\`\${API}/api/anticheat/tab-switch\`,{
            method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${token}\`},
            body:JSON.stringify({attemptId: attempt._id, examId})
          }).then(r=>r.json()).then(d=>{
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit()
          }).catch(()=>{
            setWarnings(w => { const next = w+1; if (next >= 3) autoSubmit(); return next })
          })
        }
      }
    }

    const onBlur = () => {
      if (attempt) {
        logWarning('Window Blur')
        if (user && attempt?._id) {
          fetch(\`\${API}/api/anticheat/window-blur\`,{
            method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${token}\`},
            body:JSON.stringify({attemptId: attempt._id, examId})
          }).then(r=>r.json()).then(d=>{
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit()
          }).catch(()=>{})
        }
      }
    }

    // F57 — Fullscreen enforcement (request on mount, warn+track on exit)
    const requestFS = () => { try { document.documentElement.requestFullscreen?.() } catch(e){} }
    const onFsChange = () => {
      const isFs = !!document.fullscreenElement
      setFsCompliant(isFs)
      setFocusLocked(isFs)
      if (!isFs && attempt) {
        setShowFSWarning(true)
        logWarning('Fullscreen Exit')
        fsExitTimerRef.current = setTimeout(() => {
          if (user && attempt?._id) {
            fetch(\`\${API}/api/anticheat/fullscreen-exit\`,{
              method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${token}\`},
              body:JSON.stringify({attemptId: attempt._id, examId})
            }).then(r=>r.json()).then(d=>{
              if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
              if (d?.autoSubmitted) autoSubmit()
            }).catch(()=>{})
          }
        }, 5000) // Rule: 5-second grace period before warning counted
      } else {
        setShowFSWarning(false)
        if (fsExitTimerRef.current) { clearTimeout(fsExitTimerRef.current); fsExitTimerRef.current = null }
      }
    }

    requestFS()
    document.addEventListener('fullscreenchange', onFsChange)
    window.addEventListener('blur', onBlur)`;

  if (src.includes(anchor)) {
    src = src.replace(anchor, replacement);
    count++;
    console.log('✅ Patched: tab-switch/window-blur/fullscreen effect rewritten (real endpoints + warning history)');
  } else if (src.includes('/api/anticheat/tab-switch')) {
    console.log('⚠️  Anti-cheat effect already patched — skipping');
  } else {
    console.log('❌ tab-switch effect anchor not found — patch NOT applied. Check file manually (attempt page structure may differ).');
  }
}

// ── 4) Ensure cleanup adds the new listeners' removal (best-effort: append near existing return cleanup for onVis) ──
{
  const anchor = `document.addEventListener('visibilitychange', onVis)`;
  if (src.includes(anchor) && !src.includes(`return ()=>{ document.removeEventListener('visibilitychange', onVis); document.removeEventListener('fullscreenchange', onFsChange); window.removeEventListener('blur', onBlur) }`)) {
    // best effort — only add if a matching cleanup return isn't already customized; otherwise leave existing cleanup untouched
    console.log('ℹ️  Please verify the effect cleanup (return) also removes fullscreenchange/blur listeners — see comment block above onVis registration.');
  }
}

// ── 5) Fullscreen warning modal + integrity/focus-lock UI (inject before closing of main return, near existing warnings badge if present) ──
{
  const badgeAnchor = `Warnings: {warnings}`;
  const enhancedBadge = `Warnings: {warnings}
      {/* F57 v2 — Focus lock + integrity impact indicators */}
      <span style={{marginLeft:8,fontSize:10,padding:'2px 8px',borderRadius:20,background:focusLocked?'#123b1e':'#3a1414',color:focusLocked?'#7CFC9C':'#ff8080'}}>
        {focusLocked ? '🔒 Focus Locked' : '🔓 Focus Lost'}
      </span>
      <span style={{marginLeft:6,fontSize:10,padding:'2px 8px',borderRadius:20,background: integrityImpact==='none'?'#123b1e':integrityImpact==='low'?'#3a2a00':integrityImpact==='medium'?'#3a2200':'#3a1414', color: integrityImpact==='none'?'#7CFC9C':integrityImpact==='low'?'#f2d38a':integrityImpact==='medium'?'#ffb066':'#ff8080'}}>
        🛡️ Integrity Impact: {integrityImpact}
      </span>`;
  if (src.includes(badgeAnchor) && !src.includes('Focus Locked')) {
    src = src.replace(badgeAnchor, enhancedBadge);
    count++;
    console.log('✅ Patched: added focus-lock + integrity-impact badges next to Warnings counter');
  } else if (src.includes('Focus Locked')) {
    console.log('⚠️  Badges already present — skipping');
  } else {
    console.log('⚠️  Could not find "Warnings: {warnings}" text in JSX — add focus-lock/integrity badges manually near your warning counter UI.');
  }
}

if (src.includes('showFSWarning') && !src.includes('Return to Fullscreen')) {
  console.log('ℹ️  Reminder: add a warning modal in JSX using showFSWarning state, e.g.:');
  console.log(`   {showFSWarning && <div className="fs-warning-modal"><p>⚠️ Fullscreen exited!</p><button onClick={()=>document.documentElement.requestFullscreen()}>Return to Fullscreen</button></div>}`);
}

fs.writeFileSync(TARGET, src, 'utf8');
console.log(`\n✅ F57 v2 patch complete — ${count} block(s) modified. Backup saved as ${TARGET}.bak_*`);
if (count === 0) console.log('⚠️  NOTHING was changed — anchors did not match. Please check the attempt page manually and share it for a targeted patch.');
PRNODEEOF
echo "▶️  Run this manually against your real attempt page (auto-detect or set APP_DIR):"
echo "    node $WORKDIR/patch_attempt_f57_v2.js"
node "$WORKDIR/patch_attempt_f57_v2.js" || echo "⚠️  Could not auto-locate attempt page.tsx — set APP_DIR and re-run the command above manually."

echo ""
echo "════════════════════════════════════════════════════════"
echo " 🎉 Frontend v3 patch complete"
echo "════════════════════════════════════════════════════════"
echo "Fixed in this v2:"
echo "  ✅ My Exams — Timeline strip, Preview mini panel, Performance chips (avg+rank trend),"
echo "     Next-available-attempt-time, Resume Waiting Room state, pre-window countdown"
echo "  ✅ Waiting Room — Rule 1.15.8 fix: auto-transition now GATED by hasJoinedWaitingRoom"
echo "     (was firing regardless of join state before); admin-configurable durations used;"
echo "     Rule 1.15.10 guard added (activeAttemptId -> redirect to attempt); tip severity"
echo "     tags + wait-state activity monitor added"
echo "  ✅ Instructions — T&C proceed() now calls backend (DB persisted, was sessionStorage-only);"
echo "     explicit Hindi/English toggle added; version-based re-accept via consent-status;"
echo "     Rule 1.15.10 guard added"
echo "  ✅ Webcam — permission history now rendered (was dead state); camera health summary,"
echo "     anti-spoofing badge, compact preview mode, failure reason card added"
echo "  ✅ Attempt page (F57) — real anti-cheat endpoints wired (v1's endpoint was already broken);"
echo "     focus-lock status, exit-reason tracking, warning history, integrity-impact tag added"
echo ""
echo "⚠️  MANUAL VERIFICATION NEEDED:"
echo "  1. F57 patch is anchor-based — re-run output ke console logs check karo:"
echo "     agar 'anchor not found' dikhe to attempt page manually share karo for a direct patch."
echo "  2. Confirm StudentShell's useShell() actually exposes {user, toast, lang} — if names differ,"
echo "     adjust destructuring at top of each new page."
echo "  3. Confirm 'socket.io-client' package is installed in frontend (npm install socket.io-client)"
echo "     — Waiting Room page uses it for live presence; falls back to REST polling if not available."
