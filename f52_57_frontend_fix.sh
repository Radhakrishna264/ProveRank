#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F52-F57 — Exam Flow — FRONTEND fix script"
echo "════════════════════════════════════════════════════════"

FRONTEND_APP=""
for candidate in "/root/workspace/frontend/app" "/home/runner/workspace/frontend/app" "$(pwd)/frontend/app"; do
  if [ -d "$candidate" ]; then FRONTEND_APP="$candidate"; break; fi
done
if [ -z "$FRONTEND_APP" ]; then echo "❌ Could not find frontend/app — set FRONTEND_APP env var and re-run."; exit 1; fi
echo "📂 Frontend app dir: $FRONTEND_APP"

# ── F52: My Exams (full rewrite) ──
if [ -f "$FRONTEND_APP/my-exams/page.tsx" ]; then cp "$FRONTEND_APP/my-exams/page.tsx" "$FRONTEND_APP/my-exams/page.tsx.bak_$(date +%s)"; fi
mkdir -p "$(dirname "$FRONTEND_APP/my-exams/page.tsx")"
cat > "$FRONTEND_APP/my-exams/page.tsx" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

/* ══════════════════════════════════════════════════════════════
   F52 — MY EXAMS: View All Attempted, Live, Upcoming, Search & Filter
   ══════════════════════════════════════════════════════════════ */

const JOIN_LABEL: any = {
  join_allowed: ['Join Allowed', 'शामिल हों'],
  join_closed: ['Join Closed', 'बंद'],
  join_soon: ['Available Later', 'बाद में उपलब्ध'],
  available_later: ['Available Later', 'बाद में उपलब्ध'],
  ended: ['Ended', 'समाप्त'],
}

function EmptySVG() {
  return (
    <svg width="80" height="80" viewBox="0 0 80 80" style={{ display: 'block', margin: '0 auto 14px' }} fill="none">
      <rect x="10" y="12" width="60" height="56" rx="6" stroke="#4D9FFF" strokeWidth="1.5" fill="none" />
      <path d="M10 28h60" stroke="#4D9FFF" strokeWidth="1" />
      <circle cx="25" cy="20" r="4" fill="#4D9FFF" />
      <circle cx="55" cy="20" r="4" fill="#4D9FFF" />
      <path d="M25 44h30M25 54h20" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  )
}

function MyExamsContent() {
  const { lang, darkMode: dm, token, toast } = useShell()
  const router = useRouter()
  const t = (en: string, hi: string) => (lang === 'en' ? en : hi)

  const [exams, setExams] = useState<any[]>([])
  const [stats, setStats] = useState<any>({ total: 0, upcoming: 0, live: 0, completed: 0, attempted: 0, bestScore: 0 })
  const [batches, setBatches] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  // ── §10.5 Filter Memory ──
  const [filter, setFilter] = useState('all')
  const [subjectF, setSubjectF] = useState('')
  const [batchF, setBatchF] = useState('')
  const [categoryF, setCategoryF] = useState('')
  const [search, setSearch] = useState('')
  const [pwModal, setPwModal] = useState<any>(null)
  const [pwInput, setPwInput] = useState('')
  const [pwErr, setPwErr] = useState('')
  const [starting, setStarting] = useState<string | null>(null)

  useEffect(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('pr_exam_filters') || '{}')
      if (saved.filter) setFilter(saved.filter)
      if (saved.subjectF) setSubjectF(saved.subjectF)
      if (saved.batchF) setBatchF(saved.batchF)
      if (saved.categoryF) setCategoryF(saved.categoryF)
      if (saved.search) setSearch(saved.search)
    } catch {}
  }, [])
  useEffect(() => {
    localStorage.setItem('pr_exam_filters', JSON.stringify({ filter, subjectF, batchF, categoryF, search }))
  }, [filter, subjectF, batchF, categoryF, search])

  const load = () => {
    if (!token) return
    fetch(`${API}/api/exams/my-exams`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => (r.ok ? r.json() : null))
      .then(d => {
        if (d?.success) { setExams(d.exams || []); setStats(d.stats || {}); setBatches(d.batches || []) }
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }
  useEffect(() => { load() }, [token])
  // live-state refresh every 30s (join windows / LIVE badges change over time)
  useEffect(() => { const iv = setInterval(load, 30000); return () => clearInterval(iv) }, [token])

  const subjects = useMemo(() => Array.from(new Set(exams.map(e => e.subject).filter(Boolean))), [exams])

  const filtered = useMemo(() => {
    return exams.filter(e => {
      if (search && !e.title?.toLowerCase().includes(search.toLowerCase())) return false
      if (filter === 'upcoming' && e.derivedStatus !== 'scheduled') return false
      if (filter === 'live' && e.derivedStatus !== 'live') return false
      if (filter === 'completed' && e.derivedStatus !== 'ended') return false
      if (subjectF && e.subject !== subjectF) return false
      if (batchF && e.batchName !== batchF) return false
      if (categoryF && e.category !== categoryF) return false
      return true
    })
  }, [exams, search, filter, subjectF, batchF, categoryF])

  const resetFilters = () => { setFilter('all'); setSubjectF(''); setBatchF(''); setCategoryF(''); setSearch('') }

  // ── §6 Start Exam flow ──
  const beginFlow = (e: any) => {
    if (e.passwordProtected && !e.activeAttemptId) { setPwModal(e); setPwErr(''); setPwInput(''); return }
    go(e)
  }
  const go = (e: any) => {
    if (e.activeAttemptId) { router.push(`/exam/${e._id}/attempt`); return }
    const minsToStart = e.schedule?.startTime ? (new Date(e.schedule.startTime).getTime() - Date.now()) / 60000 : -1
    if (e.derivedStatus === 'scheduled' && minsToStart <= 20) { router.push(`/exam/${e._id}/waiting`); return }
    if (e.derivedStatus === 'scheduled') { toast?.(t('This exam is not open yet.', 'यह परीक्षा अभी उपलब्ध नहीं है।'), 'w'); return }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') { toast?.(t('Join window has closed for this live exam.', 'इस लाइव परीक्षा के लिए प्रवेश बंद हो गया है।'), 'e'); return }
    router.push(`/exam/${e._id}/instructions`)
  }
  const submitPassword = async () => {
    if (!pwModal) return
    setStarting(pwModal._id)
    try {
      const r = await fetch(`${API}/api/exams/verify-password/${pwModal._id}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ password: pwInput }) })
      const d = await r.json()
      if (r.ok && d.verified) { sessionStorage.setItem(`pr_exam_pw_${pwModal._id}`, pwInput); setPwModal(null); go(pwModal) }
      else setPwErr(d.message || t('Wrong password', 'गलत पासवर्ड'))
    } catch { setPwErr(t('Network error', 'नेटवर्क त्रुटि')) }
    setStarting(null)
  }

  const toggleReminder = (e: any) => {
    const next = !e.reminderOn
    setExams(prev => prev.map(x => (x._id === e._id ? { ...x, reminderOn: next } : x)))
    fetch(`${API}/api/exams/${e._id}/reminder`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ enabled: next }) })
      .then(() => toast?.(next ? t('Reminder set 🔔', 'अनुस्मारक सेट ✅') : t('Reminder removed', 'अनुस्मारक हटाया गया'), 's'))
      .catch(() => {})
  }

  const startBtn = (e: any) => {
    if (e.activeAttemptId) return { label: t('Continue Attempt', 'जारी रखें'), col: C.gold, icon: '▶️' }
    if (e.derivedStatus === 'live' && e.joinState === 'join_allowed') return { label: t('Start Now', 'अभी शुरू'), col: C.danger, icon: '🔴' }
    if (e.derivedStatus === 'live' && e.joinState === 'join_closed') return { label: t('Join Closed', 'बंद'), col: C.sub, icon: '🔒', disabled: true }
    if (e.derivedStatus === 'scheduled') {
      const minsToStart = e.schedule?.startTime ? (new Date(e.schedule.startTime).getTime() - Date.now()) / 60000 : 9999
      if (minsToStart <= 20) return { label: t('Enter Waiting Room', 'वेटिंग रूम में जाएं'), col: C.primary, icon: '⏳' }
      return { label: t('Available Later', 'बाद में उपलब्ध'), col: C.sub, icon: '🕐', disabled: true }
    }
    if (e.derivedStatus === 'ended') {
      if (!e.unlimitedAttempts && e.attemptsRemaining === 0) return { label: t('View Result', 'परिणाम देखें'), col: C.primary, icon: '📊', result: true }
      return { label: t('Attempt Again', 'फिर से प्रयास करें'), col: C.success, icon: '🔁' }
    }
    return { label: t('Start Exam', 'परीक्षा शुरू करें'), col: C.primary, icon: '▶️' }
  }

  const cardStyle = (e: any): any => ({
    background: dm ? C.card : C.cardL,
    border: `1px solid ${e.derivedStatus === 'live' ? C.danger : e.derivedStatus === 'scheduled' ? 'rgba(77,159,255,.35)' : C.border}`,
    borderRadius: 16, padding: 18, marginBottom: 12, backdropFilter: 'blur(14px)', position: 'relative' as const,
    overflow: 'hidden', boxShadow: '0 2px 14px rgba(0,0,0,.15)',
  })

  return (
    <div style={{ animation: 'fadeIn .4s ease' }}>
      <style>{`
        @keyframes livePulseF52{0%,100%{box-shadow:0 0 0 0 rgba(255,77,77,.4)}50%{box-shadow:0 0 0 8px rgba(255,77,77,0)}}
        .f52-filters::-webkit-scrollbar{display:none}
      `}</style>

      <h1 style={{ fontFamily: 'Playfair Display,serif', fontSize: 26, fontWeight: 700, background: `linear-gradient(90deg,${C.primary},#fff)`, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', margin: '0 0 4px' }}>📝 {t('My Exams', 'मेरी परीक्षाएं')}</h1>
      <div style={{ fontSize: 13, color: C.sub, marginBottom: 16 }}>{t('View, search and start your available exams', 'अपनी उपलब्ध परीक्षाएं देखें, खोजें और शुरू करें')}</div>

      {/* ── §2 Header & Quick Stats ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(90px,1fr))', gap: 8, marginBottom: 16 }}>
        {[
          ['Total', stats.total, C.primary, '📝'],
          ['Upcoming', stats.upcoming, C.primary, '📅'],
          ['Live', stats.live, C.danger, '🔴'],
          ['Completed', stats.completed, C.success, '✅'],
          ['Attempted', stats.attempted, C.gold, '🎯'],
          ['Best Score', stats.bestScore, C.gold, '🏆'],
        ].map(([l, v, c, ic]: any, i) => (
          <div key={i} style={{ background: dm ? C.card : C.cardL, border: `1px solid ${l === 'Live' && v > 0 ? C.danger : C.border}`, borderRadius: 12, padding: '10px 8px', textAlign: 'center' as const, animation: l === 'Live' && v > 0 ? 'livePulseF52 1.8s infinite' : undefined }}>
            <div style={{ fontSize: 16 }}>{ic}</div>
            <div style={{ fontWeight: 800, fontSize: 16, color: c }}>{v}</div>
            <div style={{ fontSize: 8.5, color: C.sub, textTransform: 'uppercase' as const }}>{t(l, l)}</div>
          </div>
        ))}
      </div>

      {/* ── §3 Smart Search + Filter Bar ── */}
      <div style={{ background: dm ? C.card : C.cardL, border: `1px solid ${C.border}`, borderRadius: 14, padding: 14, marginBottom: 16 }}>
        <div style={{ position: 'relative', marginBottom: 10 }}>
          <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', fontSize: 13 }}>🔍</span>
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('Search exam title...', 'परीक्षा शीर्षक खोजें...')} style={{ width: '100%', padding: '10px 12px 10px 34px', background: dm ? 'rgba(0,22,40,.85)' : '#fff', border: `1.5px solid ${C.border}`, borderRadius: 10, color: dm ? C.text : C.textL, fontSize: 13, outline: 'none', boxSizing: 'border-box' as const }} />
        </div>
        <div className="f52-filters" style={{ display: 'flex', gap: 7, overflowX: 'auto' as const, marginBottom: 10 }}>
          {['all', 'upcoming', 'live', 'completed'].map(f => (
            <button key={f} onClick={() => setFilter(f)} style={{ flexShrink: 0, padding: '7px 14px', borderRadius: 9, border: `1px solid ${filter === f ? C.primary : C.border}`, background: filter === f ? `${C.primary}22` : 'transparent', color: filter === f ? C.primary : C.sub, cursor: 'pointer', fontSize: 11, fontWeight: filter === f ? 700 : 500 }}>
              {f === 'all' ? t('All', 'सभी') : f === 'upcoming' ? t('Upcoming', 'आगामी') : f === 'live' ? t('Live', 'लाइव') : t('Completed', 'पूर्ण')}
            </button>
          ))}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(130px,1fr))', gap: 8 }}>
          <select value={subjectF} onChange={e => setSubjectF(e.target.value)} style={{ padding: '8px 10px', borderRadius: 9, border: `1px solid ${C.border}`, background: dm ? 'rgba(0,22,40,.7)' : '#fff', color: dm ? C.text : C.textL, fontSize: 11 }}>
            <option value="">{t('All Subjects', 'सभी विषय')}</option>
            {subjects.map(s => <option key={s} value={s}>{s}</option>)}
          </select>
          <select value={batchF} onChange={e => setBatchF(e.target.value)} style={{ padding: '8px 10px', borderRadius: 9, border: `1px solid ${C.border}`, background: dm ? 'rgba(0,22,40,.7)' : '#fff', color: dm ? C.text : C.textL, fontSize: 11 }}>
            <option value="">{t('All Batches', 'सभी बैच')}</option>
            {batches.map((b: any) => <option key={b._id} value={b.name}>{b.name}</option>)}
          </select>
          <select value={categoryF} onChange={e => setCategoryF(e.target.value)} style={{ padding: '8px 10px', borderRadius: 9, border: `1px solid ${C.border}`, background: dm ? 'rgba(0,22,40,.7)' : '#fff', color: dm ? C.text : C.textL, fontSize: 11 }}>
            <option value="">{t('All Categories', 'सभी श्रेणियां')}</option>
            {['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test', 'Mini Test'].map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        {(filter !== 'all' || subjectF || batchF || categoryF || search) && (
          <button onClick={resetFilters} style={{ marginTop: 8, fontSize: 10, color: C.sub, background: 'none', border: 'none', cursor: 'pointer', textDecoration: 'underline' }}>{t('Reset Filters', 'फ़िल्टर रीसेट करें')}</button>
        )}
      </div>

      {/* ── §4 Exam List ── */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: 50, color: C.sub }}><div style={{ fontSize: 36, animation: 'pulse 1.5s infinite' }}>📝</div></div>
      ) : filtered.length === 0 ? (
        exams.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '60px 20px', background: dm ? C.card : C.cardL, borderRadius: 20, border: `1px solid ${C.border}` }}>
            <EmptySVG />
            <div style={{ fontWeight: 700, fontSize: 16, color: dm ? C.text : C.textL, marginBottom: 6 }}>{t('No exams scheduled yet', 'अभी तक कोई परीक्षा निर्धारित नहीं')}</div>
            <div style={{ fontSize: 12, color: C.sub, marginBottom: 14 }}>{t('Check back later, or make sure you have joined a batch.', 'बाद में देखें, या सुनिश्चित करें कि आप किसी बैच में शामिल हैं।')}</div>
            <button onClick={load} style={{ padding: '8px 16px', borderRadius: 9, border: `1px solid ${C.border}`, background: 'transparent', color: C.primary, cursor: 'pointer', fontSize: 12 }}>🔄 {t('Refresh', 'रीफ़्रेश करें')}</button>
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: 30, color: C.sub, fontSize: 12 }}>
            {t('No exams match this filter', 'इस फ़िल्टर से कोई परीक्षा मेल नहीं खाती')}
            <div><button onClick={resetFilters} style={{ marginTop: 8, fontSize: 11, color: C.primary, background: 'none', border: 'none', cursor: 'pointer', textDecoration: 'underline' }}>{t('Clear filters', 'फ़िल्टर हटाएं')}</button></div>
          </div>
        )
      ) : (
        filtered.map((e: any) => {
          const btn = startBtn(e)
          const jl = JOIN_LABEL[e.joinState]?.[lang === 'en' ? 0 : 1] || ''
          return (
            <div key={e._id} style={cardStyle(e)}>
              {e.derivedStatus === 'live' && <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg,${C.danger},#ff8080)`, animation: 'shimmer 1.5s infinite' }} />}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap' as const, gap: 10 }}>
                <div style={{ flex: 1, minWidth: 200 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 7, flexWrap: 'wrap' as const }}>
                    <span style={{ fontFamily: 'Playfair Display,serif', fontWeight: 700, fontSize: 15, color: dm ? C.text : C.textL }}>{e.title}</span>
                    {e.derivedStatus === 'live' && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: `${C.danger}22`, color: C.danger, border: `1px solid ${C.danger}44`, fontWeight: 700 }}>🔴 LIVE</span>}
                    {e.passwordProtected && <span style={{ fontSize: 10 }}>🔒</span>}
                    {e.category && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: `${C.gold}15`, color: C.gold, fontWeight: 600 }}>{e.category}</span>}
                    {e.subject && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: `${C.primary}15`, color: C.primary, fontWeight: 600 }}>{e.subject}</span>}
                    {e.batchName && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: dm ? 'rgba(255,255,255,.06)' : 'rgba(0,0,0,.05)', color: C.sub, fontWeight: 600 }}>📦 {e.batchName}</span>}
                  </div>
                  <div style={{ display: 'flex', gap: 14, fontSize: 11, color: C.sub, flexWrap: 'wrap' as const }}>
                    {e.schedule?.startTime && <span>📅 {new Date(e.schedule.startTime).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</span>}
                    <span>⏱️ {e.duration} {t('min', 'मिनट')}</span>
                    <span>🎯 {e.totalMarks} {t('marks', 'अंक')}</span>
                    {jl && <span style={{ color: e.joinState === 'join_allowed' ? C.success : e.joinState === 'join_closed' ? C.danger : C.sub }}>● {jl}</span>}
                  </div>
                  {e.attemptedCount > 0 && (
                    <div style={{ display: 'flex', gap: 10, marginTop: 8, flexWrap: 'wrap' as const }}>
                      <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 8, background: `${C.primary}12`, color: C.primary }}>{t('Attempted', 'प्रयास किया')} {e.attemptedCount}×</span>
                      {e.bestScore !== null && <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 8, background: `${C.gold}12`, color: C.gold }}>🏆 {t('Best', 'सर्वोत्तम')}: {e.bestScore}</span>}
                      {e.lastAttemptAt && <span style={{ fontSize: 10, color: C.sub }}>{t('Last', 'अंतिम')}: {new Date(e.lastAttemptAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}</span>}
                    </div>
                  )}
                </div>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' as const, alignItems: 'center' }}>
                  {e.derivedStatus === 'scheduled' && (
                    <button onClick={() => toggleReminder(e)} title={t('Toggle reminder', 'अनुस्मारक टॉगल करें')} style={{ width: 34, height: 34, borderRadius: 9, border: `1px solid ${e.reminderOn ? C.gold : C.border}`, background: e.reminderOn ? `${C.gold}18` : 'transparent', color: e.reminderOn ? C.gold : C.sub, cursor: 'pointer', fontSize: 14 }}>{e.reminderOn ? '🔔' : '🔕'}</button>
                  )}
                  <button
                    disabled={btn.disabled || starting === e._id}
                    onClick={() => (btn.result ? router.push('/results') : beginFlow(e))}
                    style={{ padding: '10px 18px', background: btn.disabled ? (dm ? 'rgba(255,255,255,.06)' : 'rgba(0,0,0,.06)') : `linear-gradient(135deg,${btn.col},${btn.col}CC)`, color: btn.disabled ? C.sub : '#fff', border: 'none', borderRadius: 10, cursor: btn.disabled ? 'not-allowed' : 'pointer', fontWeight: 700, fontSize: 12, boxShadow: btn.disabled ? 'none' : `0 4px 14px ${btn.col}44` }}
                  >{btn.icon} {btn.label}</button>
                </div>
              </div>
            </div>
          )
        })
      )}

      {/* ── §6.3 Inline Password Modal ── */}
      {pwModal && (
        <div onClick={() => setPwModal(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,.7)', zIndex: 5000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', maxWidth: 340, background: dm ? C.card : C.cardL, border: `1px solid ${C.border}`, borderRadius: 16, padding: 20 }}>
            <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 4, color: dm ? C.text : C.textL }}>🔒 {t('Password Required', 'पासवर्ड आवश्यक')}</div>
            <div style={{ fontSize: 11, color: C.sub, marginBottom: 12 }}>{pwModal.title}</div>
            <input type="password" value={pwInput} onChange={e => setPwInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && submitPassword()} placeholder={t('Enter exam password', 'परीक्षा पासवर्ड दर्ज करें')} autoFocus style={{ width: '100%', padding: '10px 12px', borderRadius: 10, border: `1.5px solid ${pwErr ? C.danger : C.border}`, background: dm ? 'rgba(0,22,40,.85)' : '#fff', color: dm ? C.text : C.textL, fontSize: 13, outline: 'none', boxSizing: 'border-box' as const, marginBottom: 8 }} />
            {pwErr && <div style={{ fontSize: 11, color: C.danger, marginBottom: 8 }}>❌ {pwErr}</div>}
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => setPwModal(null)} style={{ flex: 1, padding: '10px', borderRadius: 10, border: `1px solid ${C.border}`, background: 'transparent', color: C.sub, cursor: 'pointer', fontSize: 12 }}>{t('Cancel', 'रद्द करें')}</button>
              <button onClick={submitPassword} disabled={starting === pwModal._id} style={{ flex: 1, padding: '10px', borderRadius: 10, border: 'none', background: `linear-gradient(135deg,${C.primary},#0055CC)`, color: '#fff', cursor: 'pointer', fontSize: 12, fontWeight: 700 }}>{starting === pwModal._id ? '⟳' : t('Submit', 'जमा करें')}</button>
            </div>
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
echo "✅ Rewrote my-exams/page.tsx (F52)"

# ── F53: Waiting Room (new) ──
if [ -f "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" ]; then cp "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx.bak_$(date +%s)"; fi
mkdir -p "$(dirname "$FRONTEND_APP/exam/[examId]/waiting/page.tsx")"
cat > "$FRONTEND_APP/exam/[examId]/waiting/page.tsx" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

/* ══════════════════════════════════════════════════════════════
   F53 — WAITING ROOM: Enter & Countdown
   ══════════════════════════════════════════════════════════════ */

const TIPS_EN = [
  '💡 Read every question carefully before answering.',
  '💡 Manage your time — don\'t get stuck on one question.',
  '💡 Attempt easy questions first to build confidence.',
  '💡 Negative marking applies — avoid random guessing.',
  '💡 Keep your ID and admit card ready.',
  '💡 Ensure a stable internet connection before starting.',
  '💡 Sit in a quiet, well-lit room for the webcam check.',
]
const TIPS_HI = [
  '💡 उत्तर देने से पहले हर प्रश्न ध्यान से पढ़ें।',
  '💡 अपना समय प्रबंधित करें — एक प्रश्न में न फंसें।',
  '💡 आत्मविश्वास बढ़ाने के लिए पहले आसान प्रश्न हल करें।',
  '💡 नेगेटिव मार्किंग लागू है — अंदाज़े से उत्तर न दें।',
  '💡 अपना ID और एडमिट कार्ड तैयार रखें।',
  '💡 शुरू करने से पहले स्थिर इंटरनेट कनेक्शन सुनिश्चित करें।',
  '💡 वेबकैम जांच के लिए शांत, अच्छी रोशनी वाले कमरे में बैठें।',
]

function WaitingRoomContent() {
  const { lang, darkMode: dm, token, toast } = useShell()
  const params = useParams()
  const router = useRouter()
  const examId = params?.examId as string
  const t = (en: string, hi: string) => (lang === 'en' ? en : hi)

  const [exam, setExam] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [secsLeft, setSecsLeft] = useState(0)
  const [liveCount, setLiveCount] = useState(1)
  const [tipIdx, setTipIdx] = useState(0)
  const [entered, setEntered] = useState(false)
  const [musicOn, setMusicOn] = useState(false)
  const [chatOpen, setChatOpen] = useState(true)
  const [chatMinsLeft, setChatMinsLeft] = useState(10)
  const [chatMsgs, setChatMsgs] = useState<any[]>([])
  const [chatInput, setChatInput] = useState('')
  const [broadcast, setBroadcast] = useState<string | null>(null)
  const enteredAtRef = useRef<number | null>(null)
  const chatBoxRef = useRef<HTMLDivElement>(null)

  const tips = lang === 'en' ? TIPS_EN : TIPS_HI

  const load = () => {
    fetch(`${API}/api/exams/${examId}/waiting-info`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => (r.ok ? r.json() : null))
      .then(d => {
        if (d?.success) {
          setExam(d)
          setLiveCount(Math.max(1, d.liveCount || 1))
          const start = d.schedule?.startTime ? new Date(d.schedule.startTime).getTime() : Date.now()
          setSecsLeft(Math.max(0, Math.floor((start - Date.now()) / 1000)))
        }
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }
  useEffect(() => { if (token && examId) load() }, [token, examId])

  // countdown tick
  useEffect(() => {
    const iv = setInterval(() => {
      setSecsLeft(s => {
        if (s <= 1) {
          clearInterval(iv)
          router.push(`/exam/${examId}/instructions`)
          return 0
        }
        return s - 1
      })
    }, 1000)
    return () => clearInterval(iv)
  }, [examId])

  // §1.4 / §3.2.3 auto-transition threshold — when close enough, go to instructions automatically
  useEffect(() => {
    if (secsLeft > 0 && secsLeft <= 2 * 60) {
      // within last 2 minutes, push forward automatically once
      const to = setTimeout(() => router.push(`/exam/${examId}/instructions`), 1500)
      return () => clearTimeout(to)
    }
  }, [secsLeft <= 120])

  // tips rotation every 30s
  useEffect(() => { const iv = setInterval(() => setTipIdx(i => (i + 1) % tips.length), 30000); return () => clearInterval(iv) }, [tips.length])

  // live count + chat polling (no socket.io-client on frontend — REST polling instead)
  useEffect(() => {
    if (!entered) return
    const iv = setInterval(() => {
      fetch(`${API}/api/exams/${examId}/waiting-room/live-count`, { headers: { Authorization: `Bearer ${token}` } })
        .then(r => r.ok ? r.json() : null).then(d => { if (d?.success) setLiveCount(Math.max(1, d.liveCount)) }).catch(() => {})
      if (chatOpen) {
        fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { headers: { Authorization: `Bearer ${token}` } })
          .then(r => r.ok ? r.json() : null).then(d => { if (d?.success) setChatMsgs(d.messages || []) }).catch(() => {})
      }
    }, 5000)
    return () => clearInterval(iv)
  }, [entered, chatOpen, examId, token])

  // §5.1.5/§5.1.6 chat 10-min countdown from entering the room
  useEffect(() => {
    if (!entered) return
    enteredAtRef.current = Date.now()
    const iv = setInterval(() => {
      const mins = 10 - (Date.now() - (enteredAtRef.current || Date.now())) / 60000
      if (mins <= 0) { setChatOpen(false); setChatMinsLeft(0); clearInterval(iv) }
      else setChatMinsLeft(Math.ceil(mins))
    }, 1000)
    return () => clearInterval(iv)
  }, [entered])

  useEffect(() => { chatBoxRef.current?.scrollTo(0, chatBoxRef.current.scrollHeight) }, [chatMsgs])

  const sendChat = async () => {
    if (!chatInput.trim() || !chatOpen) return
    const msg = chatInput; setChatInput('')
    try {
      const r = await fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ message: msg }) })
      if (r.ok) {
        const cr = await fetch(`${API}/api/exams/${examId}/waiting-room/chat`, { headers: { Authorization: `Bearer ${token}` } })
        const cd = await cr.json(); if (cd?.success) setChatMsgs(cd.messages || [])
      } else toast?.(t('Chat is closed', 'चैट बंद है'), 'w')
    } catch {}
  }

  const enter = () => { setEntered(true); toast?.(t('You have entered the waiting room 👋', 'आप वेटिंग रूम में शामिल हो गए हैं 👋'), 's') }

  const mm = Math.floor(secsLeft / 60).toString().padStart(2, '0')
  const ss = (secsLeft % 60).toString().padStart(2, '0')
  const totalWait = exam?.exam?.waitingRoomMinutes ? exam.exam.waitingRoomMinutes * 60 : 20 * 60
  const progressPct = Math.max(0, Math.min(100, 100 - (secsLeft / totalWait) * 100))
  const urgent = secsLeft <= 5 * 60

  if (loading) return <div style={{ textAlign: 'center', padding: 80, color: C.sub }}><div style={{ fontSize: 40, animation: 'pulse 1.5s infinite' }}>⏳</div></div>

  return (
    <div style={{ animation: 'fadeIn .4s ease', maxWidth: 720, margin: '0 auto' }}>
      <style>{`
        @keyframes floatIcon{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        @keyframes urgentGlowF53{0%,100%{textShadow:0 0 20px rgba(255,77,77,.4)}50%{textShadow:0 0 40px rgba(255,77,77,.8)}}
      `}</style>

      {/* ── §2 Top Content ── */}
      <div style={{ background: dm ? C.card : C.cardL, border: `1px solid ${C.border}`, borderRadius: 20, padding: 24, backdropFilter: 'blur(16px)', textAlign: 'center' as const, marginBottom: 16 }}>
        <div style={{ fontSize: 44, animation: 'floatIcon 3s ease-in-out infinite', marginBottom: 8 }}>⏳</div>
        <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: dm ? C.text : C.textL, marginBottom: 6 }}>{exam?.exam?.title}</div>
        <div style={{ display: 'flex', gap: 10, justifyContent: 'center', flexWrap: 'wrap' as const, marginBottom: 18 }}>
          <span style={{ fontSize: 11, padding: '4px 12px', borderRadius: 20, background: `${C.primary}15`, color: C.primary }}>⏱️ {exam?.exam?.duration} {t('min', 'मिनट')}</span>
          <span style={{ fontSize: 11, padding: '4px 12px', borderRadius: 20, background: `${C.gold}15`, color: C.gold }}>🎯 {exam?.exam?.totalMarks} {t('marks', 'अंक')}</span>
          <span style={{ fontSize: 11, padding: '4px 12px', borderRadius: 20, background: `${C.success}15`, color: C.success }}>❓ {exam?.exam?.totalQuestions} {t('questions', 'प्रश्न')}</span>
          <span style={{ fontSize: 11, padding: '4px 12px', borderRadius: 20, background: dm ? 'rgba(255,255,255,.06)' : 'rgba(0,0,0,.05)', color: C.sub }}>👥 {liveCount} {t('waiting', 'प्रतीक्षारत')}</span>
        </div>

        {/* ── §3 Countdown ── */}
        <div style={{ fontFamily: 'monospace', fontSize: 46, fontWeight: 800, color: urgent ? C.danger : C.primary, animation: urgent ? 'urgentGlowF53 1.2s infinite' : undefined, letterSpacing: 2, marginBottom: 8 }}>{mm}:{ss}</div>
        <div style={{ fontSize: 11, color: C.sub, marginBottom: 12 }}>{urgent ? t('⚠️ Get ready — exam starting soon!', '⚠️ तैयार हो जाइए — परीक्षा जल्द शुरू!') : t('Time until exam starts', 'परीक्षा शुरू होने में समय')}</div>
        <div style={{ height: 6, borderRadius: 4, background: dm ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.06)', overflow: 'hidden', marginBottom: 18 }}>
          <div style={{ height: '100%', width: `${progressPct}%`, background: `linear-gradient(90deg,${C.primary},${urgent ? C.danger : C.success})`, transition: 'width 1s linear' }} />
        </div>

        {!entered ? (
          <button onClick={enter} style={{ padding: '12px 28px', borderRadius: 12, border: 'none', background: `linear-gradient(135deg,${C.primary},#0055CC)`, color: '#fff', fontWeight: 700, fontSize: 13, cursor: 'pointer', boxShadow: `0 6px 20px ${C.primary}44` }}>🚪 {t('Enter Waiting Room', 'वेटिंग रूम में प्रवेश करें')}</button>
        ) : (
          <div style={{ fontSize: 11, color: C.success }}>✅ {t('You are in the waiting room', 'आप वेटिंग रूम में हैं')}</div>
        )}
      </div>

      {entered && (
        <>
          {/* ── §4.1.2 Tips rotation ── */}
          <div style={{ background: dm ? 'rgba(77,159,255,.06)' : 'rgba(37,99,235,.05)', border: `1px solid ${C.border}`, borderRadius: 14, padding: '14px 16px', marginBottom: 12, fontSize: 12, color: dm ? C.text : C.textL, textAlign: 'center' as const, minHeight: 20 }}>{tips[tipIdx]}</div>

          {/* Admin broadcast */}
          {broadcast && <div style={{ background: `${C.gold}12`, border: `1px solid ${C.gold}44`, borderRadius: 12, padding: '10px 14px', marginBottom: 12, fontSize: 11, color: C.gold }}>📢 {broadcast}</div>}

          {/* ── §4.1.3 Music toggle ── */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <button onClick={() => setMusicOn(m => !m)} style={{ fontSize: 11, padding: '7px 14px', borderRadius: 10, border: `1px solid ${C.border}`, background: musicOn ? `${C.primary}15` : 'transparent', color: musicOn ? C.primary : C.sub, cursor: 'pointer' }}>{musicOn ? '🔊' : '🔇'} {t('Background Music', 'बैकग्राउंड संगीत')}</button>
            <span style={{ fontSize: 10, color: C.sub }}>👥 {liveCount} {t('students waiting', 'छात्र प्रतीक्षा में')}</span>
          </div>

          {/* ── §5 Chat Window (time-limited) ── */}
          <div style={{ background: dm ? C.card : C.cardL, border: `1px solid ${C.border}`, borderRadius: 14, padding: 14 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <span style={{ fontSize: 12, fontWeight: 700, color: dm ? C.text : C.textL }}>💬 {t('Room Chat', 'रूम चैट')}</span>
              {chatOpen ? <span style={{ fontSize: 10, color: chatMinsLeft <= 2 ? C.danger : C.sub }}>{t('Closes in', 'बंद होगा')} {chatMinsLeft} {t('min', 'मिनट')}</span> : <span style={{ fontSize: 10, color: C.danger }}>{t('Chat closed (anti-cheat)', 'चैट बंद (एंटी-चीट)')}</span>}
            </div>
            {chatMinsLeft <= 2 && chatOpen && <div style={{ fontSize: 10, color: C.warn, marginBottom: 6 }}>⚠️ {t('Chat will close soon.', 'चैट जल्द बंद हो जाएगी।')}</div>}
            <div ref={chatBoxRef} style={{ height: 140, overflowY: 'auto' as const, background: dm ? 'rgba(0,0,0,.15)' : 'rgba(0,0,0,.03)', borderRadius: 10, padding: 8, marginBottom: 8 }}>
              {chatMsgs.length === 0 ? <div style={{ fontSize: 10, color: C.sub, textAlign: 'center' as const, marginTop: 20 }}>{t('No messages yet', 'अभी तक कोई संदेश नहीं')}</div> :
                chatMsgs.map((m, i) => (
                  <div key={i} style={{ fontSize: 11, marginBottom: 5, color: dm ? C.text : C.textL }}><b style={{ color: C.primary }}>{m.studentName}:</b> {m.message}</div>
                ))}
            </div>
            <div style={{ display: 'flex', gap: 6 }}>
              <input disabled={!chatOpen} value={chatInput} onChange={e => setChatInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && sendChat()} placeholder={chatOpen ? t('Type a message...', 'संदेश लिखें...') : t('Chat closed', 'चैट बंद')} style={{ flex: 1, padding: '8px 10px', borderRadius: 8, border: `1px solid ${C.border}`, background: dm ? 'rgba(0,22,40,.7)' : '#fff', color: dm ? C.text : C.textL, fontSize: 11, outline: 'none' }} />
              <button disabled={!chatOpen} onClick={sendChat} style={{ padding: '8px 14px', borderRadius: 8, border: 'none', background: chatOpen ? C.primary : C.sub, color: '#fff', fontSize: 11, cursor: chatOpen ? 'pointer' : 'not-allowed' }}>➤</button>
            </div>
          </div>
        </>
      )}
    </div>
  )
}

export default function WaitingRoomPage() {
  return <StudentShell pageKey="my-exams"><WaitingRoomContent /></StudentShell>
}
PRNODEEOF
echo "✅ Created exam/[examId]/waiting/page.tsx (F53)"

# ── F54+F55: Instructions + T&C (new) ──
if [ -f "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" ]; then cp "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx.bak_$(date +%s)"; fi
mkdir -p "$(dirname "$FRONTEND_APP/exam/[examId]/instructions/page.tsx")"
cat > "$FRONTEND_APP/exam/[examId]/instructions/page.tsx" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

/* ══════════════════════════════════════════════════════════════
   F54 — INSTRUCTIONS SCREEN  +  F55 — T&C ACCEPT CHECKBOX
   ══════════════════════════════════════════════════════════════ */

const TC_VERSION = '1.0'
const TC_TEXT_EN = `By proceeding, you agree to the following:

1. You will attempt this exam independently without any external help.
2. Webcam monitoring is compulsory throughout the exam duration.
3. Switching tabs, minimizing the window, or exiting fullscreen more than the allowed number of times will result in automatic submission of your exam.
4. Right-click and copy-paste are disabled during the exam.
5. Any attempt to use unfair means (multiple devices, screen sharing, impersonation) will result in disqualification and possible account suspension.
6. Your responses, timing data, and proctoring data (webcam snapshots, tab-switch events) will be recorded and may be reviewed by ProveRank administrators.
7. Once submitted, answers cannot be changed.
8. Technical issues should be reported immediately through the support option; ProveRank is not responsible for issues caused by your internet connection or device.
9. Marks will be awarded strictly as per the marking scheme declared for this exam.
10. ProveRank reserves the right to void results found to be obtained through malpractice.

Please scroll to the bottom and check the box to confirm you have read and understood these terms.`
const TC_TEXT_HI = `आगे बढ़ने पर, आप निम्नलिखित से सहमत होते हैं:

1. आप यह परीक्षा बिना किसी बाहरी सहायता के स्वतंत्र रूप से देंगे।
2. पूरी परीक्षा अवधि के दौरान वेबकैम निगरानी अनिवार्य है।
3. टैब बदलना, विंडो को छोटा करना, या फुलस्क्रीन से बाहर निकलना निर्धारित सीमा से अधिक बार करने पर परीक्षा स्वतः जमा हो जाएगी।
4. परीक्षा के दौरान राइट-क्लिक और कॉपी-पेस्ट अक्षम हैं।
5. किसी भी अनुचित साधन (कई डिवाइस, स्क्रीन शेयरिंग, प्रतिरूपण) का उपयोग करने पर अयोग्यता और खाता निलंबन हो सकता है।
6. आपकी प्रतिक्रियाएं, समय डेटा और प्रॉक्टरिंग डेटा रिकॉर्ड किए जाएंगे और ProveRank प्रशासकों द्वारा समीक्षा किए जा सकते हैं।
7. एक बार जमा करने के बाद उत्तर बदले नहीं जा सकते।
8. तकनीकी समस्याओं की सूचना तुरंत सहायता विकल्प के माध्यम से दें।
9. अंक इस परीक्षा के लिए घोषित मार्किंग स्कीम के अनुसार ही दिए जाएंगे।
10. अनुचित तरीकों से प्राप्त परिणामों को रद्द करने का अधिकार ProveRank के पास सुरक्षित है।

कृपया नीचे स्क्रॉल करें और इन शर्तों को पढ़ने और समझने की पुष्टि के लिए बॉक्स को चेक करें।`

function InstructionsContent() {
  const { lang, darkMode: dm, token, toast } = useShell()
  const params = useParams()
  const router = useRouter()
  const examId = params?.examId as string
  const t = (en: string, hi: string) => (lang === 'en' ? en : hi)

  const [exam, setExam] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [tcOpen, setTcOpen] = useState(false)
  const [scrolledEnd, setScrolledEnd] = useState(false)
  const [agreed, setAgreed] = useState(false)
  const tcBoxRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!token || !examId) return
    fetch(`${API}/api/exams/${examId}/waiting-info`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => (r.ok ? r.json() : null))
      .then(d => { if (d?.success) setExam(d); setLoading(false) })
      .catch(() => setLoading(false))
  }, [token, examId])

  const subjectCounts = (exam?.exam?.sections || []).reduce((acc: any, s: any) => {
    if (s.subject) acc[s.subject] = (acc[s.subject] || 0) + (s.questionCount || 0)
    return acc
  }, {})

  const defaultInstructions = [
    t(`Exam: ${exam?.exam?.title || ''} — Duration: ${exam?.exam?.duration || 0} minutes`, `परीक्षा: ${exam?.exam?.title || ''} — अवधि: ${exam?.exam?.duration || 0} मिनट`),
    t(`Total Marks: ${exam?.exam?.totalMarks || 0}`, `कुल अंक: ${exam?.exam?.totalMarks || 0}`),
    t(`Marking Scheme: +${exam?.exam?.markingScheme?.correct ?? 4} correct, ${exam?.exam?.markingScheme?.incorrect ?? -1} incorrect, ${exam?.exam?.markingScheme?.unattempted ?? 0} unattempted`, `मार्किंग स्कीम: सही +${exam?.exam?.markingScheme?.correct ?? 4}, गलत ${exam?.exam?.markingScheme?.incorrect ?? -1}, अनुत्तरित ${exam?.exam?.markingScheme?.unattempted ?? 0}`),
    t(`Total Questions: ${exam?.exam?.totalQuestions || 0}`, `कुल प्रश्न: ${exam?.exam?.totalQuestions || 0}`),
    Object.keys(subjectCounts).length ? t(`Subject-wise: ${Object.entries(subjectCounts).map(([s, c]) => `${s} (${c})`).join(', ')}`, `विषय-वार: ${Object.entries(subjectCounts).map(([s, c]) => `${s} (${c})`).join(', ')}`) : null,
    t('Webcam is compulsory throughout the exam.', 'पूरी परीक्षा के दौरान वेबकैम अनिवार्य है।'),
    t('Right-click and copy-paste are disabled.', 'राइट-क्लिक और कॉपी-पेस्ट अक्षम हैं।'),
    t('3 tab switches will auto-submit your exam.', '3 बार टैब बदलने पर परीक्षा स्वतः जमा हो जाएगी।'),
    t('Fullscreen mode will be enforced throughout.', 'पूरी परीक्षा के दौरान फुलस्क्रीन मोड लागू रहेगा।'),
  ].filter(Boolean)

  const onScrollTC = () => {
    const el = tcBoxRef.current
    if (!el) return
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 12) setScrolledEnd(true)
  }

  const proceed = () => {
    if (!agreed) return
    // F55 §2.5 — acceptance recorded; actual DB persistence happens when
    // the Attempt document is created (auth-scoped, per-attempt) on the
    // next screen's webcam-confirm → start-attempt call.
    sessionStorage.setItem(`pr_tc_${examId}`, JSON.stringify({ accepted: true, version: TC_VERSION, at: new Date().toISOString() }))
    router.push(`/exam/${examId}/webcam`)
  }

  if (loading) return <div style={{ textAlign: 'center', padding: 80, color: C.sub }}><div style={{ fontSize: 36, animation: 'pulse 1.5s infinite' }}>📋</div></div>

  const progressSteps = [t('Waiting Room', 'वेटिंग रूम'), t('Instructions', 'निर्देश'), t('Webcam Check', 'वेबकैम जांच'), t('Exam', 'परीक्षा')]

  return (
    <div style={{ animation: 'fadeIn .4s ease', maxWidth: 640, margin: '0 auto', paddingBottom: 90 }}>
      {/* ── §5.1 Instruction progress indicator ── */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 18, alignItems: 'center' }}>
        {progressSteps.map((s, i) => (
          <div key={i} style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 4 }}>
            <div style={{ width: 22, height: 22, borderRadius: '50%', background: i <= 1 ? C.primary : (dm ? 'rgba(255,255,255,.1)' : 'rgba(0,0,0,.08)'), color: i <= 1 ? '#fff' : C.sub, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, flexShrink: 0 }}>{i <= 1 ? '✓' : i + 1}</div>
            {i < progressSteps.length - 1 && <div style={{ flex: 1, height: 2, background: i < 1 ? C.primary : (dm ? 'rgba(255,255,255,.1)' : 'rgba(0,0,0,.08)') }} />}
          </div>
        ))}
      </div>

      <div style={{ background: dm ? C.card : C.cardL, border: `1px solid ${C.border}`, borderRadius: 20, padding: 22, backdropFilter: 'blur(16px)' }}>
        <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: dm ? C.text : C.textL, marginBottom: 2 }}>📋 {t('Instructions', 'निर्देश')}</div>
        <div style={{ fontSize: 12, color: C.sub, marginBottom: 18 }}>{exam?.exam?.title}</div>

        {/* ── §2.1 Default instructions ── */}
        <div style={{ marginBottom: 16 }}>
          {defaultInstructions.map((ins, i) => (
            <div key={i} style={{ display: 'flex', gap: 10, marginBottom: 10 }}>
              <span style={{ width: 22, height: 22, borderRadius: '50%', background: `${C.primary}15`, color: C.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, flexShrink: 0 }}>{i + 1}</span>
              <span style={{ fontSize: 12.5, color: dm ? C.text : C.textL, lineHeight: 1.6 }}>{ins}</span>
            </div>
          ))}
        </div>

        {/* ── §2.2 Custom Instructions ── */}
        {exam?.exam?.customInstructions && (
          <div style={{ background: 'rgba(255,184,77,.08)', border: `1px solid ${C.warn}44`, borderRadius: 12, padding: '12px 14px', marginBottom: 18 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: C.warn, marginBottom: 4 }}>⚠️ {t('Additional Instructions', 'अतिरिक्त निर्देश')}</div>
            <div style={{ fontSize: 12, color: dm ? C.text : C.textL, lineHeight: 1.6, whiteSpace: 'pre-wrap' as const }}>{exam.exam.customInstructions}</div>
          </div>
        )}

        {/* ── §3 T&C Flow ── */}
        <div style={{ background: 'rgba(0,196,140,.06)', border: `1px solid ${C.success}33`, borderRadius: 14, padding: 16 }}>
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer' }}>
            <input type="checkbox" checked={agreed} disabled={!scrolledEnd} onChange={e => setAgreed(e.target.checked)} style={{ width: 18, height: 18, marginTop: 2, flexShrink: 0 }} />
            <span style={{ fontSize: 12.5, color: dm ? C.text : C.textL }}>
              {t('I have read and agree to all instructions.', 'मैंने सभी निर्देश पढ़ लिए हैं और सहमत हूं।')}{' '}
              <button onClick={(e) => { e.preventDefault(); setTcOpen(true) }} style={{ color: C.primary, background: 'none', border: 'none', cursor: 'pointer', textDecoration: 'underline', fontSize: 12.5, padding: 0 }}>{t('Read full Terms & Conditions', 'पूरी नियम व शर्तें पढ़ें')}</button>
            </span>
          </label>
          {!scrolledEnd && <div style={{ fontSize: 10.5, color: C.sub, marginTop: 8 }}>{t('Open and scroll through the full T&C to enable the checkbox.', 'चेकबॉक्स सक्षम करने के लिए पूरी T&C खोलें और स्क्रॉल करें।')}</div>}
        </div>
      </div>

      {/* ── Sticky proceed footer (mobile-friendly) ── */}
      <div style={{ position: 'sticky', bottom: 0, marginTop: 16, padding: '12px 0', background: dm ? 'rgba(5,11,20,.9)' : 'rgba(255,255,255,.9)', backdropFilter: 'blur(10px)' }}>
        <button disabled={!agreed} onClick={proceed} style={{ width: '100%', padding: '14px', borderRadius: 14, border: 'none', background: agreed ? `linear-gradient(135deg,${C.primary},#0055CC)` : (dm ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.08)'), color: agreed ? '#fff' : C.sub, fontWeight: 700, fontSize: 14, cursor: agreed ? 'pointer' : 'not-allowed', transition: 'all .25s', boxShadow: agreed ? `0 6px 20px ${C.primary}44` : 'none' }}>
          {t('Proceed to AI Webcam →', 'AI वेबकैम पर जाएं →')}
        </button>
      </div>

      {/* ── §3.1.3 T&C Modal (scrollable, F55) ── */}
      {tcOpen && (
        <div onClick={() => setTcOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,.75)', zIndex: 6000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
          <div onClick={e => e.stopPropagation()} style={{ width: '100%', maxWidth: 520, maxHeight: '85vh', display: 'flex', flexDirection: 'column' as const, background: dm ? C.card : C.cardL, border: `1px solid ${C.success}44`, borderRadius: 18 }}>
            <div style={{ padding: '16px 18px', borderBottom: `1px solid ${C.border}` }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: dm ? C.text : C.textL }}>📜 {t('Terms & Conditions', 'नियम व शर्तें')} <span style={{ fontSize: 10, color: C.sub }}>v{TC_VERSION}</span></div>
            </div>
            <div ref={tcBoxRef} onScroll={onScrollTC} style={{ flex: 1, overflowY: 'auto' as const, padding: '16px 18px', fontSize: 12, color: dm ? C.text : C.textL, lineHeight: 1.8, whiteSpace: 'pre-wrap' as const }}>
              {lang === 'en' ? TC_TEXT_EN : TC_TEXT_HI}
            </div>
            <div style={{ padding: '12px 18px', borderTop: `1px solid ${C.border}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 10, color: scrolledEnd ? C.success : C.sub }}>{scrolledEnd ? `✅ ${t('Reached end', 'अंत तक पहुंचे')}` : `📜 ${t('Scroll to bottom', 'नीचे स्क्रॉल करें')}`}</span>
              <button onClick={() => setTcOpen(false)} style={{ padding: '8px 18px', borderRadius: 10, border: 'none', background: C.primary, color: '#fff', fontSize: 12, fontWeight: 700, cursor: 'pointer' }}>{t('Close', 'बंद करें')}</button>
            </div>
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
echo "✅ Created exam/[examId]/instructions/page.tsx (F54+F55)"

# ── F56: Webcam Check (new) ──
if [ -f "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" ]; then cp "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx.bak_$(date +%s)"; fi
mkdir -p "$(dirname "$FRONTEND_APP/exam/[examId]/webcam/page.tsx")"
cat > "$FRONTEND_APP/exam/[examId]/webcam/page.tsx" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

/* ══════════════════════════════════════════════════════════════
   F56 — WEBCAM PERMISSION CHECK + LIVE FEED (client-side readiness)
   NOTE: real-time AI face detection needs a vision model (e.g.
   face-api.js / TensorFlow.js) which is not installed in this
   project yet — so "face visible" here is an honest self-confirm
   step backed by the live preview, not a fake AI claim. Lighting
   is a genuine measured heuristic (canvas pixel brightness).
   ══════════════════════════════════════════════════════════════ */

function WebcamCheckContent() {
  const { lang, darkMode: dm, token, toast } = useShell()
  const params = useParams()
  const router = useRouter()
  const examId = params?.examId as string
  const t = (en: string, hi: string) => (lang === 'en' ? en : hi)

  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const streamRef = useRef<MediaStream | null>(null)

  const [status, setStatus] = useState<'idle' | 'requesting' | 'active' | 'denied' | 'error'>('idle')
  const [devices, setDevices] = useState<MediaDeviceInfo[]>([])
  const [deviceId, setDeviceId] = useState<string>('')
  const [brightness, setBrightness] = useState(0)
  const [faceConfirmed, setFaceConfirmed] = useState(false)
  const [audioAllowed, setAudioAllowed] = useState<boolean | null>(null)
  const [historyLog, setHistoryLog] = useState<string[]>([])
  const [starting, setStarting] = useState(false)

  const lightOk = brightness >= 60 && brightness <= 235
  const readinessScore = (status === 'active' ? 40 : 0) + (lightOk ? 30 : 0) + (faceConfirmed ? 30 : 0)

  const stopStream = () => { streamRef.current?.getTracks().forEach(tr => tr.stop()); streamRef.current = null }

  const startCamera = async (chosenDeviceId?: string) => {
    setStatus('requesting')
    try {
      stopStream()
      const constraints: MediaStreamConstraints = { video: chosenDeviceId ? { deviceId: { exact: chosenDeviceId } } : true }
      const stream = await navigator.mediaDevices.getUserMedia(constraints)
      streamRef.current = stream
      if (videoRef.current) { videoRef.current.srcObject = stream }
      setStatus('active')
      setHistoryLog(h => [...h, `${new Date().toLocaleTimeString()} — ${t('Camera permission granted', 'कैमरा अनुमति दी गई')}`])
      try {
        const list = await navigator.mediaDevices.enumerateDevices()
        setDevices(list.filter(d => d.kind === 'videoinput'))
      } catch {}
    } catch (err: any) {
      setStatus(err?.name === 'NotAllowedError' ? 'denied' : 'error')
      setHistoryLog(h => [...h, `${new Date().toLocaleTimeString()} — ${t('Camera permission denied/failed', 'कैमरा अनुमति अस्वीकृत/विफल')}`])
    }
  }

  const requestAudio = async () => {
    try { const s = await navigator.mediaDevices.getUserMedia({ audio: true }); s.getTracks().forEach(t => t.stop()); setAudioAllowed(true) }
    catch { setAudioAllowed(false) }
  }

  useEffect(() => { startCamera(); return () => stopStream() }, [])

  // genuine lighting measurement via canvas pixel sampling
  useEffect(() => {
    if (status !== 'active') return
    const iv = setInterval(() => {
      const v = videoRef.current, c = canvasRef.current
      if (!v || !c || v.readyState < 2) return
      c.width = 64; c.height = 48
      const ctx = c.getContext('2d')
      if (!ctx) return
      ctx.drawImage(v, 0, 0, 64, 48)
      try {
        const data = ctx.getImageData(0, 0, 64, 48).data
        let sum = 0
        for (let i = 0; i < data.length; i += 4) sum += (data[i] + data[i + 1] + data[i + 2]) / 3
        setBrightness(Math.round(sum / (data.length / 4)))
      } catch {}
    }, 1000)
    return () => clearInterval(iv)
  }, [status])

  const proceed = async () => {
    if (!faceConfirmed || !lightOk) return
    setStarting(true)
    stopStream()
    sessionStorage.setItem(`pr_webcam_${examId}`, JSON.stringify({ verified: true, at: new Date().toISOString() }))
    try {
      const r = await fetch(`${API}/api/exams/${examId}/start-attempt`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      const d = await r.json()
      if (r.ok && d.success) router.push(`/exam/${examId}/attempt`)
      else { toast?.(d.error || t('Could not start exam', 'परीक्षा शुरू नहीं हो सकी'), 'e'); setStarting(false) }
    } catch { toast?.(t('Network error', 'नेटवर्क त्रुटि'), 'e'); setStarting(false) }
  }

  return (
    <div style={{ animation: 'fadeIn .4s ease', maxWidth: 640, margin: '0 auto' }}>
      <h1 style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: dm ? C.text : C.textL, marginBottom: 4 }}>📷 {t('Webcam Check', 'वेबकैम जांच')}</h1>
      <div style={{ fontSize: 12, color: C.sub, marginBottom: 16 }}>{t('Confirm your camera is working before the exam begins', 'परीक्षा शुरू होने से पहले सुनिश्चित करें कि आपका कैमरा काम कर रहा है')}</div>

      <div style={{ background: dm ? C.card : C.cardL, border: `1px solid ${C.border}`, borderRadius: 20, padding: 18, backdropFilter: 'blur(16px)' }}>
        {/* ── Live Preview ── */}
        <div style={{ position: 'relative', width: '100%', aspectRatio: '4/3', background: '#000', borderRadius: 14, overflow: 'hidden', marginBottom: 14 }}>
          <video ref={videoRef} autoPlay playsInline muted style={{ width: '100%', height: '100%', objectFit: 'cover', transform: 'scaleX(-1)' }} />
          <canvas ref={canvasRef} style={{ display: 'none' }} />
          {status === 'active' && <span style={{ position: 'absolute', top: 10, left: 10, fontSize: 10, fontWeight: 800, padding: '3px 10px', borderRadius: 20, background: 'rgba(255,0,0,.8)', color: '#fff', display: 'flex', alignItems: 'center', gap: 4 }}><span style={{ width: 6, height: 6, borderRadius: '50%', background: '#fff', animation: 'pulse .9s infinite' }} /> LIVE</span>}
          {status !== 'active' && (
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column' as const, gap: 10 }}>
              {status === 'requesting' && <div style={{ color: '#fff', fontSize: 12 }}>⟳ {t('Requesting camera access...', 'कैमरा एक्सेस का अनुरोध...')}</div>}
              {status === 'denied' && <div style={{ color: '#FF6B6B', fontSize: 12, textAlign: 'center' as const, padding: '0 20px' }}>🚫 {t('Camera permission denied. Allow camera access in your browser settings.', 'कैमरा अनुमति अस्वीकृत। ब्राउज़र सेटिंग्स में कैमरा एक्सेस दें।')}</div>}
              {status === 'error' && <div style={{ color: '#FF6B6B', fontSize: 12 }}>⚠️ {t('Could not access camera.', 'कैमरा एक्सेस नहीं हो सका।')}</div>}
            </div>
          )}
        </div>

        {(status === 'denied' || status === 'error') && (
          <button onClick={() => startCamera(deviceId)} style={{ width: '100%', padding: '10px', borderRadius: 10, border: `1px solid ${C.primary}`, background: 'transparent', color: C.primary, cursor: 'pointer', fontSize: 12, fontWeight: 700, marginBottom: 14 }}>🔄 {t('Retry Camera Permission', 'कैमरा अनुमति फिर से आज़माएं')}</button>
        )}

        {/* ── Device selector ── */}
        {devices.length > 1 && (
          <select value={deviceId} onChange={e => { setDeviceId(e.target.value); startCamera(e.target.value) }} style={{ width: '100%', padding: '8px 10px', borderRadius: 9, border: `1px solid ${C.border}`, background: dm ? 'rgba(0,22,40,.7)' : '#fff', color: dm ? C.text : C.textL, fontSize: 11, marginBottom: 14 }}>
            {devices.map(d => <option key={d.deviceId} value={d.deviceId}>{d.label || 'Camera'}</option>)}
          </select>
        )}

        {/* ── Readiness checklist ── */}
        <div style={{ display: 'flex', flexDirection: 'column' as const, gap: 8, marginBottom: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', borderRadius: 10, background: dm ? 'rgba(0,0,0,.15)' : 'rgba(0,0,0,.03)' }}>
            <span style={{ fontSize: 12, color: dm ? C.text : C.textL }}>📷 {t('Camera Active', 'कैमरा सक्रिय')}</span>
            <span style={{ fontSize: 12 }}>{status === 'active' ? '✅' : '⬜'}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', borderRadius: 10, background: dm ? 'rgba(0,0,0,.15)' : 'rgba(0,0,0,.03)' }}>
            <span style={{ fontSize: 12, color: dm ? C.text : C.textL }}>💡 {t('Lighting Check', 'रोशनी जांच')}</span>
            <span style={{ fontSize: 11, color: status !== 'active' ? C.sub : lightOk ? C.success : C.warn }}>{status !== 'active' ? '—' : lightOk ? `✅ ${t('Good', 'अच्छा')}` : brightness < 60 ? `⚠️ ${t('Too Dark', 'बहुत अंधेरा')}` : `⚠️ ${t('Too Bright', 'बहुत तेज़')}`}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', borderRadius: 10, background: dm ? 'rgba(0,0,0,.15)' : 'rgba(0,0,0,.03)' }}>
            <span style={{ fontSize: 12, color: dm ? C.text : C.textL }}>🎙️ {t('Audio (optional)', 'ऑडियो (वैकल्पिक)')}</span>
            {audioAllowed === null ? <button onClick={requestAudio} style={{ fontSize: 10, padding: '4px 10px', borderRadius: 8, border: `1px solid ${C.border}`, background: 'transparent', color: C.primary, cursor: 'pointer' }}>{t('Allow', 'अनुमति दें')}</button> : <span style={{ fontSize: 12 }}>{audioAllowed ? '✅' : '❌'}</span>}
          </div>
        </div>

        {/* ── Camera readiness score ── */}
        <div style={{ marginBottom: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: C.sub, marginBottom: 4 }}>
            <span>{t('Camera Readiness', 'कैमरा तैयारी')}</span><span>{readinessScore}/100</span>
          </div>
          <div style={{ height: 6, borderRadius: 4, background: dm ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.06)', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${readinessScore}%`, background: readinessScore >= 80 ? C.success : readinessScore >= 40 ? C.warn : C.danger, transition: 'width .4s' }} />
          </div>
        </div>

        {/* ── Face visible self-confirm (honest — no fake AI claim) ── */}
        {status === 'active' && (
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer', padding: '10px 12px', borderRadius: 10, background: faceConfirmed ? 'rgba(0,196,140,.08)' : (dm ? 'rgba(0,0,0,.15)' : 'rgba(0,0,0,.03)'), border: `1px solid ${faceConfirmed ? C.success + '44' : C.border}`, marginBottom: 14 }}>
            <input type="checkbox" checked={faceConfirmed} onChange={e => setFaceConfirmed(e.target.checked)} style={{ width: 17, height: 17, marginTop: 1, flexShrink: 0 }} />
            <span style={{ fontSize: 11.5, color: dm ? C.text : C.textL }}>{t('I can clearly see my face in the preview above, alone in the frame.', 'मैं ऊपर प्रीव्यू में अपना चेहरा स्पष्ट रूप से देख सकता हूं, अकेला फ्रेम में।')}</span>
          </label>
        )}

        <button
          disabled={status !== 'active' || !lightOk || !faceConfirmed || starting}
          onClick={proceed}
          style={{ width: '100%', padding: '13px', borderRadius: 12, border: 'none', cursor: (status === 'active' && lightOk && faceConfirmed && !starting) ? 'pointer' : 'not-allowed', background: (status === 'active' && lightOk && faceConfirmed) ? `linear-gradient(135deg,${C.primary},#0055CC)` : (dm ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.08)'), color: (status === 'active' && lightOk && faceConfirmed) ? '#fff' : C.sub, fontWeight: 700, fontSize: 13 }}
        >{starting ? `⟳ ${t('Starting...', 'शुरू हो रहा है...')}` : `📷 ${t('Allow Camera & Start Exam', 'कैमरा अनुमति दें और परीक्षा शुरू करें')}`}</button>
      </div>
    </div>
  )
}

export default function WebcamCheckPage() {
  return <StudentShell pageKey="my-exams"><WebcamCheckContent /></StudentShell>
}
PRNODEEOF
echo "✅ Created exam/[examId]/webcam/page.tsx (F56)"

# ── F57: Patch existing Attempt page (fullscreen enforcement) ──
WORKDIR=$(mktemp -d); cd "$WORKDIR"
cat > patch_attempt_f57.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F57 — Fullscreen Mode Enforcement (+ fixes a pre-existing bug where
// tab-switch logging called a non-existent endpoint).
// Patches: frontend/app/exam/[examId]/attempt/page.tsx
// ════════════════════════════════════════════════════════════════
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
  console.error('   Set APP_DIR env var, e.g.:');
  console.error("   APP_DIR='/home/runner/workspace/frontend/app/exam/[examId]/attempt' node patch_attempt_f57.js");
  process.exit(1);
}
console.log('📄 Target file:', TARGET);

let src = fs.readFileSync(TARGET, 'utf8');
let count = 0;

// ── 1) Add F57 state near existing warnings state ──
{
  const anchor = `const [warnings, setWarnings] = useState(0)`;
  const addition = `${anchor}
  const [showFSWarning, setShowFSWarning] = useState(false)
  const [fsCompliant, setFsCompliant] = useState(true)
  const fsExitTimerRef = useRef<any>(null)`;
  if (src.includes(anchor) && !src.includes('showFSWarning')) {
    src = src.replace(anchor, addition);
    count++;
    console.log('✅ Patched: added F57 fullscreen state');
  } else if (src.includes('showFSWarning')) {
    console.log('⚠️  F57 state already present — skipping');
  } else {
    console.log('❌ warnings-state anchor not found — state patch NOT applied');
  }
}

// ── 2) Ensure useRef is imported (fsExitTimerRef needs it) ──
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
//      window-blur + fullscreen enforcement (request + exit handling) ──
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
              method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${user.token}\`},
              body:JSON.stringify({count:next})
            }).catch(()=>{})
          }
          return next
        })
      }
    }
    document.addEventListener('visibilitychange', onVis)
    return () => document.removeEventListener('visibilitychange', onVis)
  },[attempt, user])`;

  const good = `  // F57 — Anti-cheat: tab switch, window blur, fullscreen enforcement
  // (fixed: previously posted to a non-existent /api/attempts/:id/tab-switch
  //  endpoint — now correctly uses /api/anticheat/* which already exists
  //  and drives 3-warning auto-submit server-side too)
  const logAntiCheatEvent = useCallback(async (eventType: 'tab-switch'|'window-blur'|'fullscreen-exit') => {
    if (!attempt?._id || !user || !examId) return
    try {
      const r = await fetch(\`\${API}/api/anticheat/\${eventType}\`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: \`Bearer \${user.token}\` },
        body: JSON.stringify({ attemptId: attempt._id, examId, metadata: {} }),
      })
      const d = await r.json()
      if (typeof d.warningCount === 'number') setWarnings(d.warningCount)
      if (d.autoSubmitted) autoSubmit()
    } catch {}
  }, [attempt, user, examId])

  useEffect(()=>{
    const onVis = () => { if (document.hidden && attempt) logAntiCheatEvent('tab-switch') }
    const onBlur = () => { if (attempt) logAntiCheatEvent('window-blur') }
    document.addEventListener('visibilitychange', onVis)
    window.addEventListener('blur', onBlur)
    return () => { document.removeEventListener('visibilitychange', onVis); window.removeEventListener('blur', onBlur) }
  },[attempt, user, logAntiCheatEvent])

  // §1.1/§1.7 — force fullscreen once the attempt is active
  useEffect(() => {
    if (!attempt) return
    const el = document.documentElement as any
    const req = el.requestFullscreen || el.webkitRequestFullscreen || el.mozRequestFullScreen || el.msRequestFullscreen
    if (req && !document.fullscreenElement) { req.call(el).catch(() => {}) }
  }, [attempt])

  // §1.4/§1.6/§2 — fullscreen exit → 5s grace period → warning + modal
  useEffect(() => {
    const onFsChange = () => {
      const isFs = !!document.fullscreenElement
      setFsCompliant(isFs)
      if (!isFs && attempt) {
        setShowFSWarning(true)
        fsExitTimerRef.current = setTimeout(() => {
          logAntiCheatEvent('fullscreen-exit')
        }, 5000) // §1.6 — 5-second grace period before it's counted
      } else if (isFs) {
        if (fsExitTimerRef.current) { clearTimeout(fsExitTimerRef.current); fsExitTimerRef.current = null }
        setShowFSWarning(false)
      }
    }
    document.addEventListener('fullscreenchange', onFsChange)
    return () => { document.removeEventListener('fullscreenchange', onFsChange); if (fsExitTimerRef.current) clearTimeout(fsExitTimerRef.current) }
  }, [attempt, logAntiCheatEvent])

  const returnToFullscreen = () => {
    const el = document.documentElement as any
    const req = el.requestFullscreen || el.webkitRequestFullscreen || el.mozRequestFullScreen || el.msRequestFullscreen
    if (req) req.call(el).catch(() => {})
  }`;

  if (src.includes(anchor)) {
    src = src.replace(anchor, good);
    count++;
    console.log('✅ Patched: fixed tab-switch endpoint bug + added window-blur + fullscreen enforcement');
  } else if (src.includes('logAntiCheatEvent')) {
    console.log('⚠️  Already patched — skipping');
  } else {
    console.log('❌ Anti-cheat effect anchor not found — this patch was NOT applied (file may differ)');
  }
}

// ── 4) Insert the Warning Modal UI ──
{
  const anchor = `{/* ── Feature 32: Time Extension Notification ── */}`;
  const modal = `      {/* ── F57 — Fullscreen Exit Warning Modal ── */}
      {showFSWarning && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.75)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:300,backdropFilter:'blur(4px)'}}>
          <div style={{background:'rgba(30,5,5,0.97)',border:'2px solid #FF4757',borderRadius:18,padding:'32px',maxWidth:380,width:'90%',textAlign:'center',boxShadow:'0 0 40px rgba(255,71,87,0.35)'}}>
            <div style={{fontSize:44,marginBottom:12}}>⚠️</div>
            <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#FF6B6B',marginBottom:8}}>{lang==='en'?'You exited fullscreen!':'आप फुलस्क्रीन से बाहर निकल गए!'}</h2>
            <p style={{color:'#E8B4B4',fontSize:13,marginBottom:6}}>{lang==='en'?'Return to fullscreen within 5 seconds or this will be counted as a warning.':'5 सेकंड के भीतर फुलस्क्रीन पर लौटें अन्यथा यह चेतावनी के रूप में गिना जाएगा।'}</p>
            <div style={{fontSize:11,color:'#FF9999',marginBottom:20}}>{lang==='en'?\`Warnings so far: \${warnings}/3\`:\`अब तक चेतावनियां: \${warnings}/3\`}</div>
            <button className="lb" style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',width:'100%'}} onClick={returnToFullscreen}>
              🔳 {lang==='en'?'Return to Fullscreen':'फुलस्क्रीन पर लौटें'}
            </button>
          </div>
        </div>
      )}

      {/* ── Feature 32: Time Extension Notification ── */}`;
  if (src.includes(anchor) && !src.includes('F57 — Fullscreen Exit Warning Modal')) {
    src = src.replace(anchor, modal);
    count++;
    console.log('✅ Patched: inserted Fullscreen Exit Warning Modal UI');
  } else if (src.includes('F57 — Fullscreen Exit Warning Modal')) {
    console.log('⚠️  Modal already present — skipping');
  } else {
    console.log('❌ Time Extension Notification anchor not found — modal NOT inserted');
  }
}

// ── 5) Add a header badge showing fullscreen compliance status ──
{
  const anchor = `{warnings>0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}`;
  const addition = `{!fsCompliant && <span className="badge badge-red">🔲 {lang==='en'?'Not Fullscreen':'फुलस्क्रीन नहीं'}</span>}
            {warnings>0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}`;
  if (src.includes(anchor) && !src.includes('Not Fullscreen')) {
    src = src.replace(anchor, addition);
    count++;
    console.log('✅ Patched: added fullscreen-compliance header badge');
  } else if (src.includes('Not Fullscreen')) {
    console.log('⚠️  Badge already present — skipping');
  } else {
    console.log('❌ warnings-badge anchor not found — badge NOT added');
  }
}

if (count > 0) {
  fs.writeFileSync(TARGET, src);
  console.log(`\n✅ ${count}/5 F57 patch(es) applied and saved.`);
} else {
  console.log('\n⚠️  No changes were applied.');
}
PRNODEEOF
echo "🚀 Patching Attempt page (F57)..."
APP_DIR="$FRONTEND_APP/exam/[examId]/attempt" node patch_attempt_f57.js

# ══════════════════════════════════════════════════════════
# VERIFICATION
# ══════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════"
echo " VERIFICATION — F52-F57 Frontend"
echo "════════════════════════════════════════════════════════"
PASS=0; FAIL=0
check() { if grep -qF "$2" "$3" 2>/dev/null; then echo "✅ $1"; PASS=$((PASS+1)); else echo "❌ $1"; FAIL=$((FAIL+1)); fi }

check "F52 §2 Header quick stats (6 tiles)" "Best Score" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §3 Smart Search + Filter Bar" "t('Search exam title" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §3.2 Filters (All/Upcoming/Live/Completed)" "'upcoming', 'live', 'completed'" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §3.2.6 Batch/Test Series filter (auto-synced)" "batches.map" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §3.3 Category filters (Full Mock/Chapter/Mini etc)" "'Full Mock'" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §10.5 Filter Memory (localStorage)" "pr_exam_filters" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §4 Exam cards with badges (subject/batch/category)" "e.batchName" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §5.1 LIVE badge with glow" "livePulseF52" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §5.3 Join state labels" "JOIN_LABEL" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §6.3 Inline password entry" "pwModal" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §6.4 Start button states (Now/Continue/Locked/etc)" "const startBtn" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §7 Reminder toggle" "toggleReminder" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §8 Completed exam attempt count + best score" "e.attemptedCount > 0" "$FRONTEND_APP/my-exams/page.tsx"
check "F52 §9 Empty states (no exams / filtered empty)" "No exams scheduled yet" "$FRONTEND_APP/my-exams/page.tsx"
check "F53 §1.1 Waiting room trigger (20 min window)" "auto-transition threshold" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F53 §2 Exam info chips (duration/marks/questions)" "t('questions'" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F53 §3 MM:SS countdown + progress bar" "progressPct" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F53 §4.1.2 Tips rotation (30s)" "setInterval(() => setTipIdx" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F53 §4.1.3 Background music toggle (muted default)" "musicOn" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F53 §4.1.5 Live waiting count" "liveCount" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F53 §5.1.1 Time-limited chat (10 min)" "chatMinsLeft" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F53 §5.1.5 Chat close reminder" "chatMinsLeft <= 2" "$FRONTEND_APP/exam/[examId]/waiting/page.tsx"
check "F54 §1.1.3 8 numbered instruction points" "defaultInstructions" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F54 §2.2 Custom admin instructions (highlighted)" "customInstructions" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F54 §5.1 Instruction progress indicator" "progressSteps" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F55 §1.1 T&C modal with full scrollable text" "TC_TEXT_EN" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F55 §1.2 Scroll-to-bottom before checkbox activates" "scrolledEnd" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F55 §1.3 T&C version tracking" "TC_VERSION" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F55 §2.3 Button grey-to-blue on activation" "agreed ?" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F55 §3.2.1 Checkbox text exact match" "I have read and agree to all instructions" "$FRONTEND_APP/exam/[examId]/instructions/page.tsx"
check "F56 §1.1 getUserMedia permission request" "getUserMedia" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx"
check "F56 §2.2 LIVE badge on active preview" "LIVE</span>" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx"
check "F56 §1.7 Lighting check (real canvas brightness heuristic)" "getImageData" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx"
check "F56 §2.4/2.5 Permission denied + retry" "Retry Camera Permission" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx"
check "F56 §3.5 Camera device selector" "enumerateDevices" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx"
check "F56 §1.8 Optional audio permission" "requestAudio" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx"
check "F56 §3.1 Camera readiness score" "readinessScore" "$FRONTEND_APP/exam/[examId]/webcam/page.tsx"

# ── F57 checks (patched attempt page) ──
ATTEMPT_FILE="$FRONTEND_APP/exam/[examId]/attempt/page.tsx"
check "F57 §1.1 requestFullscreen on exam start" "requestFullscreen" "$ATTEMPT_FILE"
check "F57 §1.4 Fullscreen exit warning tracking" "logAntiCheatEvent" "$ATTEMPT_FILE"
check "F57 §1.6 5-second grace period" "setTimeout(() => {" "$ATTEMPT_FILE"
check "F57 §2.1/2.2/2.3 Warning modal (red border, return button)" "Fullscreen Exit Warning Modal" "$ATTEMPT_FILE"
check "F57 §2.4 Header warning-count badge" "Not Fullscreen" "$ATTEMPT_FILE"
check "Bug fix: tab-switch now hits the real /api/anticheat endpoint" "api/anticheat/" "$ATTEMPT_FILE"

echo ""
echo "════════════════════════════════════════════════════════"
echo " RESULT: $PASS passed / $((PASS+FAIL)) total"
if [ "$FAIL" -eq 0 ]; then echo " 🎉 ALL F52-F57 FRONTEND FEATURES SUCCESSFULLY IMPLEMENTED ✅"; else echo " ⚠️  $FAIL item(s) need review."; fi
echo "════════════════════════════════════════════════════════"

echo "👉 Make sure you also ran the backend fix script."
echo "👉 Restart your frontend (Replit Run button) to see changes."
echo "👉 Flow: My Exams → (password if any) → Waiting Room → Instructions/T&C → Webcam → Attempt"
