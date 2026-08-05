#!/bin/bash
set -e
echo "=== Fix: Batch Workspace text-contrast bug (was invisible in both themes) ==="
cat > ~/workspace/frontend/app/dashboard/my-batches/\[id\]/page.tsx << 'FILEEOF1'
'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter, useParams } from 'next/navigation'
import StudentShell, { useShell } from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const EXAM_ROUTES = {
  waitingRoom: (id: string) => `/exam/${id}/waiting-room`,
  instructions: (id: string) => `/exam/${id}/instructions`,
  attempt: (id: string) => `/exam/${id}/attempt`,
  result: (id: string) => `/exam/${id}/result`,
}

function useIsDesktop() {
  const [isDesktop, setIsDesktop] = useState(false)
  useEffect(() => {
    const mq = window.matchMedia('(min-width: 900px)')
    const update = () => setIsDesktop(mq.matches)
    update()
    mq.addEventListener ? mq.addEventListener('change', update) : mq.addListener(update)
    return () => { mq.removeEventListener ? mq.removeEventListener('change', update) : mq.removeListener(update) }
  }, [])
  return isDesktop
}

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', 'NEET UG': '#4D9FFF', JEE: '#9B59B6', 'JEE MAINS': '#9B59B6', 'JEE ADVANCE': '#7D3C98',
  CUET: '#27AE60', 'CUET UG': '#27AE60', 'CUET PG': '#1E8449', 'SSC CGL': '#E67E22', 'IIT JAM': '#00D4FF',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C', Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}

const SECTIONS = [
  { key: 'overview', label: 'Overview', icon: '🏠' },
  { key: 'exams', label: 'Exams', icon: '📝' },
  { key: 'announcements', label: 'Announcements', icon: '📢' },
  { key: 'resources', label: 'Resources', icon: '📚' },
  { key: 'leaderboard', label: 'Leaderboard', icon: '🏆' },
  { key: 'progress', label: 'Progress', icon: '📈' },
  { key: 'activity', label: 'Activity', icon: '🕐' },
  { key: 'info', label: 'Batch Info', icon: 'ℹ️' },
  { key: 'faq', label: 'FAQ / Help', icon: '❓' },
] as const
type SectionKey = typeof SECTIONS[number]['key']

function fmtDate(d: any) { try { return new Date(d).toLocaleDateString() } catch { return '' } }
function fmtCountdown(secs: number) {
  if (secs <= 0) return '00:00:00'
  const h = Math.floor(secs / 3600), m = Math.floor((secs % 3600) / 60), s = Math.floor(secs % 60)
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

// ── Exam CTA resolver — mirrors My Exams page launch rules exactly ──
function examCTA(e: any) {
  if (e.derivedStatus === 'ended') {
    if (e.joinState === 'available_again') return { label: 'Attempt / Continue', mode: 'attempt' }
    if (e.performance) return { label: 'View Result', mode: 'result' }
    return { label: 'Locked', mode: 'locked' }
  }
  if (e.activeAttemptId) return { label: 'Resume', mode: 'attempt' }
  if (e.derivedStatus === 'live') {
    if (e.joinState === 'join_open') return { label: 'Join Exam', mode: 'attempt' }
    return { label: 'Join Closed', mode: 'locked' }
  }
  if (e.derivedStatus === 'scheduled') {
    if (e.joinState === 'waiting_room_open') {
      return { label: e.hasJoinedWaitingRoom ? 'Resume Waiting Room' : 'Join Waiting Room', mode: 'waiting' }
    }
    return { label: 'Countdown to Exam', mode: 'countdown' }
  }
  return { label: 'Unavailable', mode: 'locked' }
}

export default function BatchWorkspacePage() {
  const router = useRouter()
  const params = useParams() as any
  const batchId = params?.id as string
  const shell = useShell() as any
  const isDark = shell?.darkMode !== false
  const theme = {
    isDark,
    text: isDark ? '#F1F6FC' : '#0F172A',
    sub: isDark ? '#8DA2C0' : '#51607A',
    border: isDark ? 'rgba(77,159,255,0.14)' : 'rgba(37,99,235,0.14)',
    primary: isDark ? '#4D9FFF' : '#2563EB',
    chipBg: isDark ? 'rgba(77,159,255,0.07)' : 'rgba(37,99,235,0.06)',
  }
  const isDesktop = useIsDesktop()

  const [tok, setTok] = useState('')
  const [section, setSection] = useState<SectionKey>('overview')
  const [restored, setRestored] = useState(false)
  const [overview, setOverview] = useState<any>(null)
  const [exams, setExams] = useState<any[]>([])
  const [announcements, setAnnouncements] = useState<any[]>([])
  const [resources, setResources] = useState<any[]>([])
  const [leaderboard, setLeaderboard] = useState<any>(null)
  const [progress, setProgress] = useState<any>(null)
  const [activity, setActivity] = useState<any>(null)
  const [info, setInfo] = useState<any>(null)
  const [faqs, setFaqs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [toast, setToast] = useState<string | null>(null)
  const [faqSearch, setFaqSearch] = useState('')
  const loadedSections = useRef<Set<string>>(new Set())
  const saveTimer = useRef<ReturnType<typeof setTimeout>>()

  const CARD = theme.isDark ? 'rgba(8,16,34,0.72)' : 'rgba(255,255,255,0.85)'
  const BORDER = theme.border
  const TEXT = theme.text
  const SUB = theme.sub
  const ec = (overview && ECOLS[overview.examType]) || theme.primary

  const showToast = (m: string) => { setToast(m); setTimeout(() => setToast(null), 2600) }

  // ── init: token + restore last section ──
  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t)
    if (!t || !batchId) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/state`, { headers: { Authorization: `Bearer ${t}` } })
      .then(r => r.json()).then(d => { if (d?.state?.lastSection) setSection(d.state.lastSection) })
      .catch(() => {}).finally(() => setRestored(true))
    fetch(`${API}/api/my-batches/${batchId}/access`, { method: 'POST', headers: { Authorization: `Bearer ${t}` } }).catch(() => {})
  }, [batchId])

  // ── persist section changes (debounced) ──
  useEffect(() => {
    if (!restored || !tok || !batchId) return
    if (saveTimer.current) clearTimeout(saveTimer.current)
    saveTimer.current = setTimeout(() => {
      fetch(`${API}/api/student/batch-workspace/${batchId}/state`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` },
        body: JSON.stringify({ lastSection: section })
      }).catch(() => {})
    }, 500)
  }, [section, restored, tok, batchId])

  // ── overview always loads first (drives hero banner) ──
  useEffect(() => {
    if (!tok || !batchId) return
    setLoading(true)
    fetch(`${API}/api/student/batch-workspace/${batchId}/overview`, { headers: { Authorization: `Bearer ${tok}` } })
      .then(r => r.json()).then(d => setOverview(d.workspace || null)).catch(() => {}).finally(() => setLoading(false))
  }, [tok, batchId])

  // ── lazy-load each section on first visit ──
  const loadSection = useCallback((key: SectionKey) => {
    if (!tok || !batchId || loadedSections.current.has(key)) return
    loadedSections.current.add(key)
    const H = { Authorization: `Bearer ${tok}` }
    if (key === 'exams') fetch(`${API}/api/student/batch-workspace/${batchId}/exams`, { headers: H }).then(r => r.json()).then(d => setExams(d.exams || [])).catch(() => {})
    if (key === 'announcements') fetch(`${API}/api/student/batch-workspace/${batchId}/announcements`, { headers: H }).then(r => r.json()).then(d => setAnnouncements(d.announcements || [])).catch(() => {})
    if (key === 'resources') fetch(`${API}/api/student/batch-workspace/${batchId}/resources`, { headers: H }).then(r => r.json()).then(d => setResources(d.resources || [])).catch(() => {})
    if (key === 'leaderboard') fetch(`${API}/api/student/batch-workspace/${batchId}/leaderboard?scope=top50`, { headers: H }).then(r => r.json()).then(d => setLeaderboard(d)).catch(() => {})
    if (key === 'progress') fetch(`${API}/api/student/batch-workspace/${batchId}/progress`, { headers: H }).then(r => r.json()).then(d => setProgress(d)).catch(() => {})
    if (key === 'activity') fetch(`${API}/api/student/batch-workspace/${batchId}/activity`, { headers: H }).then(r => r.json()).then(d => setActivity(d)).catch(() => {})
    if (key === 'info') fetch(`${API}/api/student/batch-workspace/${batchId}/info`, { headers: H }).then(r => r.json()).then(d => setInfo(d.info || null)).catch(() => {})
    if (key === 'faq') fetch(`${API}/api/student/batch-workspace/${batchId}/faq`, { headers: H }).then(r => r.json()).then(d => setFaqs(d.faqs || [])).catch(() => {})
  }, [tok, batchId])

  useEffect(() => { if (restored) loadSection(section) }, [section, restored, loadSection])

  // ── actions ──
  const goSection = (k: SectionKey) => setSection(k)

  const toggleFavorite = async () => {
    if (!tok || !overview) return
    try {
      const r = await fetch(`${API}/api/student/batches/${batchId}/wishlist`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      setOverview((o: any) => ({ ...o, isFavorite: d.isWishlisted }))
      showToast(d.isWishlisted ? '❤️ Added to favorites' : 'Removed from favorites')
    } catch { showToast('Could not update favorite') }
  }

  const shareBatch = async () => {
    const url = typeof window !== 'undefined' ? window.location.href : ''
    const title = overview?.name || 'ProveRank Batch'
    try {
      if (navigator.share) await navigator.share({ title, url })
      else { await navigator.clipboard.writeText(url); showToast('🔗 Link copied to clipboard') }
    } catch {}
  }

  const toggleReminder = async (examId: string, enabled: boolean) => {
    if (!tok) return
    try {
      await fetch(`${API}/api/exams/${examId}/reminder`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` }, body: JSON.stringify({ enabled })
      })
      setExams(list => list.map(e => e._id === examId ? { ...e, reminderEnabled: enabled } : e))
      showToast(enabled ? '🔔 Reminder set' : 'Reminder removed')
    } catch {}
  }

  const launchExam = async (e: any) => {
    const cta = examCTA(e)
    if (cta.mode === 'locked' || cta.mode === 'countdown') return
    if (cta.mode === 'result') { router.push(EXAM_ROUTES.result(e._id)); return }
    if (cta.mode === 'attempt') {
      if (e.activeAttemptId || e.skipWaitingRoom || e.derivedStatus === 'ended' || e.derivedStatus === 'live') {
        router.push(EXAM_ROUTES.attempt(e._id)); return
      }
    }
    if (cta.mode === 'waiting') {
      if (e.hasJoinedWaitingRoom) { router.push(EXAM_ROUTES.waitingRoom(e._id)); return }
      try {
        await fetch(`${API}/api/exams/${e._id}/join-waiting-room`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      } catch {}
      router.push(EXAM_ROUTES.waitingRoom(e._id))
    }
  }

  const markResourceViewed = (noteId: string) => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/resources/${noteId}/view`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } }).catch(() => {})
    setResources(list => list.map(r => r._id === noteId ? { ...r, viewed: true } : r))
  }

  const togglePinResource = (noteId: string) => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/resources/${noteId}/pin`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      .then(r => r.json()).then(d => setResources(list => list.map(r => r._id === noteId ? { ...r, studentPinned: d.pinned } : r))).catch(() => {})
  }

  const markAnnRead = (annId: string) => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/announcements/${annId}/read`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } }).catch(() => {})
    setAnnouncements(list => list.map(a => a._id === annId ? { ...a, isRead: true } : a))
  }

  const markAllAnnRead = () => {
    if (!tok) return
    fetch(`${API}/api/student/batch-workspace/${batchId}/announcements/read-all`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } }).catch(() => {})
    setAnnouncements(list => list.map(a => ({ ...a, isRead: true })))
    showToast('✅ All marked as read')
  }

  const inp = { padding: '8px 12px', background: theme.isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)', border: `1px solid ${BORDER}`, borderRadius: 10, color: TEXT, fontSize: 12, outline: 'none' as const, width: '100%' }
  const sectionCard = { background: CARD, border: `1px solid ${BORDER}`, borderRadius: 20, padding: 18, backdropFilter: 'blur(20px)' as const, marginBottom: 14, boxShadow: theme.isDark ? '0 8px 32px -12px rgba(0,0,0,0.4)' : 'none' }

  return (
    <StudentShell pageKey="my-batches">
      <div style={{ minHeight: '100vh', color: TEXT, fontFamily: 'Inter,sans-serif', position: 'relative', overflowX: 'hidden' }}>
        <style>{`
          @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;800&family=Inter:wght@400;500;600;700;800&display=swap');
          *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
          @keyframes slideUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
          @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        `}</style>

        <div style={{ position: 'relative', zIndex: 2, maxWidth: 980, margin: '0 auto', padding: '20px 16px 100px', display: isDesktop ? 'grid' : 'block', gridTemplateColumns: isDesktop ? '210px 1fr' : undefined, gap: isDesktop ? 22 : 0 }}>

          {/* ── DESKTOP LEFT RAIL ── */}
          {isDesktop && (
            <div style={{ position: 'sticky', top: 20, alignSelf: 'start' }}>
              <button onClick={() => router.push('/dashboard/my-batches')} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '7px 12px', color: SUB, fontSize: 11, cursor: 'pointer', marginBottom: 14 }}>← My Batches</button>
              <div style={sectionCard}>
                {SECTIONS.map(s => (
                  <button key={s.key} onClick={() => goSection(s.key)}
                    style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', textAlign: 'left', padding: '9px 10px', borderRadius: 10, marginBottom: 4, background: section === s.key ? `${ec}18` : 'transparent', border: 'none', color: section === s.key ? ec : SUB, fontWeight: section === s.key ? 700 : 500, cursor: 'pointer', fontSize: 12.5 }}>
                    <span>{s.icon}</span>{s.label}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* ── MOBILE TOP BAR + CHIPS ── */}
          {!isDesktop && (
            <>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
                <button onClick={() => router.push('/dashboard/my-batches')} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '7px 10px', color: SUB, fontSize: 13, cursor: 'pointer' }}>←</button>
                <div style={{ fontSize: 14, fontWeight: 700, color: TEXT, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{overview?.name || 'Workspace'}</div>
              </div>
              <div style={{ display: 'flex', gap: 6, overflowX: 'auto', marginBottom: 12, paddingBottom: 4 }}>
                {SECTIONS.map(s => (
                  <button key={s.key} onClick={() => goSection(s.key)}
                    style={{ flexShrink: 0, padding: '7px 12px', borderRadius: 20, fontSize: 11, whiteSpace: 'nowrap', cursor: 'pointer', background: section === s.key ? `${ec}20` : CARD, border: `1px solid ${section === s.key ? ec + '50' : BORDER}`, color: section === s.key ? ec : SUB, fontWeight: section === s.key ? 700 : 500 }}>
                    {s.icon} {s.label}
                  </button>
                ))}
              </div>
            </>
          )}

          {/* ── CENTER CONTENT ── */}
          <div>
            {/* HERO SUMMARY BANNER */}
            {overview && (
              <div style={{ ...sectionCard, border: `1px solid ${ec}30`, animation: 'slideUp 0.3s ease', position: 'relative', overflow: 'hidden' }}>
                <div style={{ position: 'absolute', top: -50, right: -50, width: 160, height: 160, borderRadius: '50%', background: `radial-gradient(circle, ${ec}16 0%, transparent 70%)`, pointerEvents: 'none' }} />
                <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap', position: 'relative' }}>
                  <div style={{ width: 58, height: 58, borderRadius: 16, background: `linear-gradient(135deg, ${ec}22, ${ec}0A)`, border: `1px solid ${ec}35`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 26, flexShrink: 0, boxShadow: `0 8px 24px -8px ${ec}40` }}>{overview.colorIcon || '📦'}</div>
                  <div style={{ flex: 1, minWidth: 180 }}>
                    <div style={{ fontSize: 9.5, fontWeight: 700, color: ec, textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: 4 }}>{overview.examType}</div>
                    <div style={{ fontFamily: 'Playfair Display,serif', fontSize: isDesktop ? 22 : 18, fontWeight: 800, color: TEXT, lineHeight: 1.15 }}>{overview.name}</div>
                    <div style={{ fontSize: 11.5, color: SUB, marginTop: 5 }}>
                      {overview.testsAttempted}/{overview.totalTests} tests · {overview.progress}% complete · {overview.daysLeft}d left
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button onClick={toggleFavorite} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 12, padding: '9px 11px', color: overview.isFavorite ? '#FF6B6B' : SUB, cursor: 'pointer', fontSize: 15, transition: 'all 0.2s' }}>{overview.isFavorite ? '❤️' : '🤍'}</button>
                    <button onClick={shareBatch} style={{ background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 12, padding: '9px 11px', color: SUB, cursor: 'pointer', fontSize: 15, transition: 'all 0.2s' }}>🔗</button>
                  </div>
                </div>
              </div>
            )}

            {loading && !overview && <div style={{ textAlign: 'center', padding: 40, color: SUB }}>Loading workspace…</div>}

            {/* ═══ OVERVIEW ═══ */}
            {section === 'overview' && overview && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(110px,1fr))', gap: 8, marginBottom: 12 }}>
                  {[
                    { l: 'Tests Completed', v: overview.testsAttempted, i: '✅' },
                    { l: 'Total Planned', v: overview.totalTests, i: '📋' },
                    { l: 'Current Rank', v: overview.currentRank ? `#${overview.currentRank}` : '—', i: '🏅' },
                    { l: 'Days Left', v: overview.daysLeft, i: '⏳' },
                  ].map((s, i) => (
                    <div key={i} style={{ ...sectionCard, textAlign: 'center', marginBottom: 0, padding: 12 }}>
                      <div style={{ fontSize: 16 }}>{s.i}</div>
                      <div style={{ fontSize: 18, fontWeight: 800, color: ec }}>{s.v}</div>
                      <div style={{ fontSize: 9, color: SUB }}>{s.l}</div>
                    </div>
                  ))}
                </div>

                {overview.nextTest && (
                  <div style={sectionCard}>
                    <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 6 }}>⏰ Next Test</div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{overview.nextTest.title}</div>
                    <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>{fmtDate(overview.nextTest.startTime)}</div>
                  </div>
                )}

                {overview.latestAnnouncement && (
                  <div style={sectionCard}>
                    <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 6 }}>📢 Latest Announcement</div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{overview.latestAnnouncement.title}</div>
                    <button onClick={() => goSection('announcements')} style={{ marginTop: 6, background: 'transparent', border: `1px solid ${ec}40`, borderRadius: 8, padding: '4px 10px', color: ec, fontSize: 10, cursor: 'pointer' }}>View all →</button>
                  </div>
                )}

                {overview.latestActivity && (
                  <div style={sectionCard}>
                    <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 6 }}>🕐 Latest Activity</div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{overview.latestActivity.icon} {overview.latestActivity.title}</div>
                  </div>
                )}
              </div>
            )}

            {/* ═══ EXAMS ═══ */}
            {section === 'exams' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {exams.length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}>
                    <div style={{ fontSize: 40, marginBottom: 8 }}>📭</div>
                    <div style={{ fontSize: 13, color: SUB }}>No exams scheduled yet in this batch.</div>
                  </div>
                ) : exams.map(e => {
                  const cta = examCTA(e)
                  const isLive = e.derivedStatus === 'live'
                  return (
                    <div key={e._id} style={{ ...sectionCard, position: 'relative' }}>
                      {isLive && <div style={{ position: 'absolute', top: 10, right: 12, background: 'rgba(231,76,60,0.16)', color: '#E74C3C', fontSize: 9, fontWeight: 800, padding: '2px 8px', borderRadius: 20, animation: 'slideUp 0.3s ease' }}>🔴 LIVE</div>}
                      <div style={{ fontSize: 13, fontWeight: 700 }}>{e.title}</div>
                      <div style={{ fontSize: 10, color: SUB, marginTop: 3 }}>{e.subject || 'General'} · {e.duration}min · {e.totalMarks} marks</div>
                      {e.schedule?.startTime && <div style={{ fontSize: 10, color: SUB, marginTop: 2 }}>📅 {fmtDate(e.schedule.startTime)}</div>}
                      {e.performance?.bestScore != null && <div style={{ fontSize: 10, color: '#27AE60', marginTop: 2 }}>Best: {e.performance.bestScore}</div>}
                      <div style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap' }}>
                        <button disabled={cta.mode === 'locked' || cta.mode === 'countdown'} onClick={() => launchExam(e)}
                          style={{ flex: 1, minWidth: 140, padding: '9px', borderRadius: 10, border: 'none', color: (cta.mode === 'locked' || cta.mode === 'countdown') ? SUB : '#fff', background: (cta.mode === 'locked' || cta.mode === 'countdown') ? 'rgba(255,255,255,0.06)' : `linear-gradient(135deg,${ec},${ec}BB)`, fontWeight: 700, fontSize: 11, cursor: (cta.mode === 'locked' || cta.mode === 'countdown') ? 'default' : 'pointer' }}>
                          {cta.mode === 'countdown' && e.secsToStart != null ? `⏳ ${fmtCountdown(e.secsToStart)}` : cta.label}
                        </button>
                        {cta.mode === 'countdown' && (
                          <button onClick={() => toggleReminder(e._id, !e.reminderEnabled)} style={{ padding: '9px 12px', borderRadius: 10, background: e.reminderEnabled ? `${ec}18` : 'rgba(255,255,255,0.06)', border: `1px solid ${ec}30`, color: ec, fontSize: 13, cursor: 'pointer' }}>{e.reminderEnabled ? '🔔' : '🔕'}</button>
                        )}
                      </div>
                    </div>
                  )
                })}
              </div>
            )}

            {/* ═══ ANNOUNCEMENTS ═══ */}
            {section === 'announcements' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {announcements.length > 0 && (
                  <button onClick={markAllAnnRead} style={{ marginBottom: 10, background: 'transparent', border: `1px solid ${BORDER}`, borderRadius: 10, padding: '7px 12px', color: SUB, fontSize: 11, cursor: 'pointer' }}>✓ Mark all as read</button>
                )}
                {announcements.length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}><div style={{ fontSize: 40, marginBottom: 8 }}>📪</div><div style={{ fontSize: 13, color: SUB }}>No announcements yet.</div></div>
                ) : announcements.map(a => (
                  <div key={a._id} onClick={() => !a.isRead && markAnnRead(a._id)} style={{ ...sectionCard, cursor: a.isRead ? 'default' : 'pointer', opacity: a.isRead ? 0.75 : 1 }}>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 4 }}>
                      {a.pinned && <span style={{ fontSize: 10 }}>📌</span>}
                      {!a.isRead && <span style={{ width: 7, height: 7, borderRadius: '50%', background: ec, display: 'inline-block' }} />}
                      <span style={{ fontSize: 9, background: `${ec}16`, color: ec, padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>{a.type}</span>
                    </div>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{a.title}</div>
                    <div style={{ fontSize: 11, color: SUB, marginTop: 4 }} dangerouslySetInnerHTML={{ __html: a.message }} />
                    <div style={{ fontSize: 9, color: SUB, marginTop: 6 }}>{fmtDate(a.createdAt)}</div>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ RESOURCES ═══ */}
            {section === 'resources' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {resources.length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}><div style={{ fontSize: 40, marginBottom: 8 }}>📁</div><div style={{ fontSize: 13, color: SUB }}>No resources added yet for this batch.</div></div>
                ) : resources.map(r => (
                  <div key={r._id} style={sectionCard}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginBottom: 4, flexWrap: 'wrap' }}>
                          <span style={{ fontSize: 9, background: `${ec}16`, color: ec, padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>{r.type}</span>
                          {r.recentlyAdded && <span style={{ fontSize: 9, background: 'rgba(39,174,96,0.14)', color: '#27AE60', padding: '2px 8px', borderRadius: 20, fontWeight: 700 }}>NEW</span>}
                          {r.viewed && <span style={{ fontSize: 9, color: SUB }}>✓ Viewed</span>}
                        </div>
                        <div style={{ fontSize: 13, fontWeight: 700 }}>{r.title}</div>
                        {r.description && <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>{r.description}</div>}
                      </div>
                      <button onClick={() => togglePinResource(r._id)} style={{ background: 'transparent', border: 'none', color: r.studentPinned ? '#FFD700' : SUB, cursor: 'pointer', fontSize: 15, flexShrink: 0 }}>📌</button>
                    </div>
                    <a href={r.url} target="_blank" rel="noreferrer" onClick={() => markResourceViewed(r._id)}
                      style={{ display: 'inline-block', marginTop: 10, padding: '8px 14px', borderRadius: 10, background: `linear-gradient(135deg,${ec},${ec}BB)`, color: '#fff', fontWeight: 700, fontSize: 11, textDecoration: 'none' }}>Open →</a>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ LEADERBOARD ═══ */}
            {section === 'leaderboard' && leaderboard && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                {leaderboard.myRank && (
                  <div style={{ ...sectionCard, border: `1px solid ${ec}30` }}>
                    <div style={{ fontSize: 12, color: SUB }}>Your Rank</div>
                    <div style={{ fontSize: 22, fontWeight: 900, color: ec }}>#{leaderboard.myRank} <span style={{ fontSize: 12, color: SUB, fontWeight: 400 }}>of {leaderboard.total}</span></div>
                    {leaderboard.percentile != null && <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>Top {100 - leaderboard.percentile}% percentile</div>}
                    {leaderboard.topper && <div style={{ fontSize: 11, color: SUB, marginTop: 3 }}>🥇 Topper: {leaderboard.topper.name} ({leaderboard.topper.avgScore.toFixed(1)}% avg)</div>}
                  </div>
                )}
                <div style={sectionCard}>
                  {(leaderboard.leaderboard || []).map((l: any, i: number) => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                      <div style={{ width: 26, height: 26, borderRadius: '50%', background: i === 0 ? 'linear-gradient(135deg,#FFD700,#FFA000)' : i === 1 ? 'linear-gradient(135deg,#C0C0C0,#9E9E9E)' : i === 2 ? 'linear-gradient(135deg,#CD7F32,#A0522D)' : 'rgba(77,159,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: i < 3 ? 13 : 10, fontWeight: 900, color: i < 3 ? '#000' : SUB }}>{i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : i + 1}</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 12, fontWeight: 700 }}>{l.name}</div>
                        <div style={{ fontSize: 10, color: SUB }}>📝 {l.testsCompleted} tests · ⭐ {l.avgScore.toFixed(1)}% avg · 🔥 {l.streak}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ═══ PROGRESS ═══ */}
            {section === 'progress' && progress && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(110px,1fr))', gap: 8, marginBottom: 12 }}>
                  {[
                    { l: 'Tests Attempted', v: progress.testsAttempted, i: '📝' },
                    { l: 'Accuracy', v: `${progress.accuracy}%`, i: '🎯' },
                    { l: 'Avg Score', v: progress.avgScore, i: '📊' },
                    { l: 'Completion', v: `${progress.completionPct}%`, i: '✅' },
                  ].map((s, i) => (
                    <div key={i} style={{ ...sectionCard, textAlign: 'center', marginBottom: 0, padding: 12 }}>
                      <div style={{ fontSize: 16 }}>{s.i}</div>
                      <div style={{ fontSize: 18, fontWeight: 800, color: ec }}>{s.v}</div>
                      <div style={{ fontSize: 9, color: SUB }}>{s.l}</div>
                    </div>
                  ))}
                </div>
                {progress.weakSubjects?.length > 0 && (
                  <div style={sectionCard}><div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>⚠️ Weak Subjects</div>
                    {progress.weakSubjects.map((w: any, i: number) => <div key={i} style={{ fontSize: 12, marginBottom: 4 }}>{w.subject}: <span style={{ color: '#E74C3C', fontWeight: 700 }}>{w.accuracy}%</span></div>)}
                  </div>
                )}
                {progress.strongSubjects?.length > 0 && (
                  <div style={sectionCard}><div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>💪 Strong Subjects</div>
                    {progress.strongSubjects.map((w: any, i: number) => <div key={i} style={{ fontSize: 12, marginBottom: 4 }}>{w.subject}: <span style={{ color: '#27AE60', fontWeight: 700 }}>{w.accuracy}%</span></div>)}
                  </div>
                )}
              </div>
            )}

            {/* ═══ ACTIVITY ═══ */}
            {section === 'activity' && activity && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <div style={sectionCard}>
                  <div style={{ fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8 }}>🏅 Milestones</div>
                  <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
                    {(activity.milestones || []).map((m: any, i: number) => (
                      <span key={i} style={{ fontSize: 9, padding: '2px 8px', borderRadius: 20, fontWeight: 700, background: m.achieved ? 'rgba(39,174,96,0.14)' : (theme.isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)'), color: m.achieved ? '#27AE60' : SUB }}>{m.achieved ? '✓' : '○'} {m.label}</span>
                    ))}
                  </div>
                </div>
                {(activity.activity || []).length === 0 ? (
                  <div style={{ ...sectionCard, textAlign: 'center', padding: 30 }}><div style={{ fontSize: 13, color: SUB }}>No activity yet.</div></div>
                ) : (activity.activity || []).map((a: any, i: number) => (
                  <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start', padding: '9px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                    <span style={{ fontSize: 18, flexShrink: 0 }}>{a.icon}</span>
                    <div><div style={{ fontSize: 12, fontWeight: 700 }}>{a.title}</div>{a.message && <div style={{ fontSize: 10, color: SUB, marginTop: 2 }}>{a.message}</div>}<div style={{ fontSize: 9, color: SUB, marginTop: 3 }}>{fmtDate(a.at)}</div></div>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ BATCH INFO ═══ */}
            {section === 'info' && info && (
              <div style={{ ...sectionCard, animation: 'slideUp 0.3s ease' }}>
                {[
                  ['Name', info.name], ['Code', info.batchCode || '—'], ['Faculty', info.teacherAssigned || '—'],
                  ['Subject', info.subject], ['Type', info.batchType], ['Language', info.language],
                  ['Start Date', info.startDate ? fmtDate(info.startDate) : '—'], ['End Date', info.endDate ? fmtDate(info.endDate) : '—'],
                  ['Enrolled', fmtDate(info.enrolledAt)], ['Expires', fmtDate(info.expiresAt)],
                  ['Total Tests', info.totalTests], ['Access Status', info.accessStatus],
                ].map(([l, v], i) => (
                  <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                    <span style={{ fontSize: 11, color: SUB }}>{l}</span><span style={{ fontSize: 12, fontWeight: 700 }}>{String(v)}</span>
                  </div>
                ))}
              </div>
            )}

            {/* ═══ FAQ ═══ */}
            {section === 'faq' && (
              <div style={{ animation: 'slideUp 0.3s ease' }}>
                <input value={faqSearch} onChange={e => setFaqSearch(e.target.value)} placeholder="🔎 Search FAQ…" style={{ ...inp, marginBottom: 10 }} />
                {faqs.filter(f => !faqSearch || f.q.toLowerCase().includes(faqSearch.toLowerCase()) || f.a.toLowerCase().includes(faqSearch.toLowerCase())).map((f, i) => (
                  <div key={i} style={sectionCard}>
                    <div style={{ fontSize: 12, fontWeight: 700, marginBottom: 5 }}>❓ {f.q}</div>
                    <div style={{ fontSize: 11, color: SUB }}>{f.a}</div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {toast && <div style={{ position: 'fixed', bottom: 24, left: '50%', transform: 'translateX(-50%)', zIndex: 2000, background: 'rgba(20,20,35,0.95)', border: '1px solid rgba(77,159,255,0.35)', borderRadius: 12, padding: '10px 18px', fontSize: 12, color: '#fff', fontWeight: 600, boxShadow: '0 10px 30px rgba(0,0,0,0.4)', whiteSpace: 'nowrap' }}>{toast}</div>}
      </div>
    </StudentShell>
  )
}

FILEEOF1
echo "my-batches/[id]/page.tsx fixed ✅"

cd ~/workspace
git add -A
git commit -m "fix: Batch Workspace text contrast — theme colors were silently falling back to near-white text in light mode when useShell() context timing caused theme.text/sub to be undefined; now derives colors directly from darkMode boolean with guaranteed values"
git push
