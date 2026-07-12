'use client'
import { useState, useEffect, useRef, useMemo } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

const TYPE_META: Record<string, { ico: string; col: string; en: string; hi: string }> = {
  exam:   { ico: '📝', col: '#4D9FFF', en: 'Exam',   hi: 'परीक्षा' },
  update: { ico: '✨', col: '#00C48C', en: 'Update', hi: 'अपडेट' },
  result: { ico: '🏅', col: '#FFD700', en: 'Result', hi: 'परिणाम' },
  maintenance: { ico: '🔧', col: '#A855F7', en: 'Maintenance', hi: 'रखरखाव' },
  urgent: { ico: '🚨', col: '#FF4D4D', en: 'Urgent', hi: 'अत्यावश्यक' },
}
const FILTERS = ['all', 'exam', 'update', 'result', 'maintenance', 'urgent']

function relTime(d: string, lang: 'en' | 'hi') {
  const diff = Date.now() - new Date(d).getTime()
  const m = Math.floor(diff / 60000), h = Math.floor(diff / 3600000), day = Math.floor(diff / 86400000)
  if (m < 1) return lang === 'en' ? 'Just now' : 'अभी अभी'
  if (m < 60) return lang === 'en' ? `${m}m ago` : `${m} मिनट पहले`
  if (h < 24) return lang === 'en' ? `${h}h ago` : `${h} घंटे पहले`
  if (day < 7) return lang === 'en' ? `${day}d ago` : `${day} दिन पहले`
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}

function sanitizeClient(html: string) {
  if (!html) return ''
  let s = String(html).replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
  s = s.replace(/<(?!\/?(b|strong|i|em|u|br|p|a)(\s|>|\/))[^>]*>/gi, '')
  s = s.replace(/\son\w+\s*=\s*"[^"]*"/gi, '').replace(/\son\w+\s*=\s*'[^']*'/gi, '')
  return s
}

function extractUrl(text: string) { const m = String(text).match(/https?:\/\/[^\s<"]+/i); return m ? m[0] : null }

function extractDate(text: string) {
  const months = 'January|February|March|April|May|June|July|August|September|October|November|December'
  let m = text.match(new RegExp(`\\b(${months})\\s+(\\d{1,2}),?\\s+(\\d{4})\\b`, 'i'))
  if (m) return new Date(`${m[1]} ${m[2]}, ${m[3]}`)
  m = text.match(new RegExp(`\\b(\\d{1,2})\\s+(${months})\\s+(\\d{4})\\b`, 'i'))
  if (m) return new Date(`${m[2]} ${m[1]}, ${m[3]}`)
  return null
}
function downloadICS(title: string, date: Date) {
  const dt = date.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
  const ics = `BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:${title}\nDTSTART:${dt}\nDTEND:${dt}\nEND:VEVENT\nEND:VCALENDAR`
  const blob = new Blob([ics], { type: 'text/calendar' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a'); a.href = url; a.download = `${title}.ics`; a.click()
  URL.revokeObjectURL(url)
}

function SkeletonCard({ dm }: { dm: boolean }) {
  return (
    <div style={{ background: dm ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)', borderRadius: 14, padding: 16, marginBottom: 12, overflow: 'hidden', position: 'relative' }}>
      <div style={{ height: 14, width: '40%', background: dm ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)', borderRadius: 6, marginBottom: 10 }} />
      <div style={{ height: 10, width: '90%', background: dm ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)', borderRadius: 6, marginBottom: 6 }} />
      <div style={{ height: 10, width: '70%', background: dm ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)', borderRadius: 6 }} />
      <div style={{ position: 'absolute', inset: 0, background: `linear-gradient(90deg, transparent, ${dm ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)'}, transparent)`, animation: 'annShimmer 1.4s infinite' }} />
    </div>
  )
}

function AnnouncementsContent() {
  const { lang, darkMode: dm, token, theme } = useShell()
  const t = (en: string, hi: string) => lang === 'en' ? en : hi
  const txt = theme.text, sub = theme.sub, bdr = theme.border, prim = theme.primary

  const [notices, setNotices] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [filterType, setFilterType] = useState('all')
  const [sortMode, setSortMode] = useState<'newest' | 'pinned'>('pinned')
  const [search, setSearch] = useState('')
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set())
  const [soundEnabled, setSoundEnabled] = useState(true)

  useEffect(() => { try { setSoundEnabled(localStorage.getItem('pr_ann_sound') !== 'off') } catch {} }, [])

  const load = () => {
    if (!token) return
    fetch(`${API}/api/announcements`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.ok ? r.json() : [])
      .then(d => {
        const list = Array.isArray(d) ? d : []
        setNotices(list)
        setLoading(false)

        // v2 §6.2 — Bell badge is now synced independently by StudentShell
        // polling GET /api/announcements/unread-count every 60s from any
        // page. No localStorage/event bridging needed here anymore.

        // §6.1 Push notification for genuinely new unread items
        try {
          if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
            const notified = JSON.parse(localStorage.getItem('pr_notified_ann_ids') || '[]')
            const fresh = list.filter((n: any) => !n.isRead && !notified.includes(n._id))
            fresh.slice(0, 3).forEach((n: any) => {
              try { new Notification(n.title, { body: n.message.replace(/<[^>]*>/g, '').slice(0, 100), icon: '/favicon.ico' }) } catch {}
            })
            if (fresh.length) localStorage.setItem('pr_notified_ann_ids', JSON.stringify([...notified, ...fresh.map((n: any) => n._id)].slice(-200)))
          }
        } catch {}

        // §6.7 Sound/vibration on urgent unread
        try {
          const urgentUnread = list.some((n: any) => n.type === 'urgent' && !n.isRead)
          if (urgentUnread && soundEnabled) {
            const audio = new Audio('data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=')
            audio.play().catch(() => {})
            if (navigator.vibrate) navigator.vibrate([80, 40, 80])
          }
        } catch {}
      })
      .catch(() => { setNotices([]); setLoading(false) })
  }
  useEffect(() => { load() }, [token])

  // §6.1 request Notification permission once, quietly
  useEffect(() => {
    try { if (typeof Notification !== 'undefined' && Notification.permission === 'default') Notification.requestPermission() } catch {}
  }, [])

  const markRead = (id: string) => {
    setNotices(prev => prev.map(n => n._id === id ? { ...n, isRead: true } : n))
    fetch(`${API}/api/announcements/${id}/read`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } }).catch(() => {})
  }
  const markAllRead = () => {
    setNotices(prev => prev.map(n => ({ ...n, isRead: true })))
    fetch(`${API}/api/announcements/read-all`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } }).catch(() => {})
  }
  const doAck = (id: string) => {
    setNotices(prev => prev.map(n => n._id === id ? { ...n, isAcked: true } : n))
    fetch(`${API}/api/announcements/${id}/ack`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } }).catch(() => {})
  }
  const onCardClick = (n: any) => {
    if (!n.isRead) { markRead(n._id); return }
    setExpandedIds(prev => { const s = new Set(prev); s.has(n._id) ? s.delete(n._id) : s.add(n._id); return s })
  }
  const toggleSound = () => {
    const next = !soundEnabled; setSoundEnabled(next)
    try { localStorage.setItem('pr_ann_sound', next ? 'on' : 'off') } catch {}
  }

  // §3.9 expiry filter (defensive, backend already filters) + search/type/sort
  const now = Date.now()
  const visible = useMemo(() => {
    let list = notices.filter(n => !n.expiryDate || new Date(n.expiryDate).getTime() >= now)
    if (filterType !== 'all') list = list.filter(n => (n.type || 'update') === filterType)
    if (search.trim()) {
      const q = search.toLowerCase()
      list = list.filter(n => (n.title || '').toLowerCase().includes(q) || (lang === 'hi' && n.titleHi || '').toLowerCase().includes(q))
    }
    const arr = [...list]
    if (sortMode === 'pinned') arr.sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0) || +new Date(b.createdAt) - +new Date(a.createdAt))
    else arr.sort((a, b) => +new Date(b.createdAt) - +new Date(a.createdAt))
    return arr
  }, [notices, filterType, search, sortMode, lang])

  const pinnedList = visible.filter(n => n.pinned)
  const unpinnedList = sortMode === 'pinned' ? visible.filter(n => !n.pinned) : visible
  const totalCount = notices.length
  const unreadCount = notices.filter(n => !n.isRead).length
  const urgentCount = notices.filter(n => n.type === 'urgent' && (!n.expiryDate || new Date(n.expiryDate).getTime() >= now)).length

  const Card = ({ n }: { n: any }) => {
    const meta = TYPE_META[n.type || 'update'] || TYPE_META.update
    const isExpanded = expandedIds.has(n._id)
    const displayTitle = lang === 'hi' && n.titleHi ? n.titleHi : n.title
    const displayMsg = lang === 'hi' && n.messageHi ? n.messageHi : n.message
    const plainMsg = displayMsg.replace(/<[^>]*>/g, '')
    const isLong = plainMsg.length > 180
    const linkUrl = extractUrl(plainMsg)
    const examDate = n.type === 'exam' ? extractDate(plainMsg) : null

    return (
      <div
        onClick={() => onCardClick(n)}
        style={{
          background: dm ? 'rgba(0,22,40,0.7)' : 'rgba(255,255,255,0.92)',
          border: `1px solid ${bdr}`,
          borderLeft: `${n.isRead ? 4 : 5}px solid ${meta.col}`,
          borderRadius: 14, padding: 0, marginBottom: 12, cursor: 'pointer',
          opacity: n.isRead ? 0.85 : 1,
          boxShadow: n.pinned ? `0 0 0 1px ${C.gold}22, 0 4px 18px rgba(0,0,0,0.1)` : n.type === 'urgent' && !n.isRead ? `0 0 16px ${meta.col}33` : '0 2px 10px rgba(0,0,0,0.08)',
          animation: n.type === 'urgent' && !n.isRead ? 'annUrgentPulse 2s infinite' : 'none',
          overflow: 'hidden', position: 'relative',
          backgroundImage: n.pinned ? 'linear-gradient(135deg, rgba(251,191,36,0.06), transparent)' : 'none',
        }}
      >
        {n.pinned && <div style={{ position: 'absolute', top: 10, right: 12, fontSize: 16, transform: 'rotate(-15deg)' }}>📌</div>}
        {n.imageUrl && <img src={n.imageUrl} alt="" style={{ width: '100%', height: 120, objectFit: 'cover', borderRadius: '13px 13px 0 0' }} onError={(e: any) => e.target.style.display = 'none'} />}
        <div style={{ padding: '14px 16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, flexWrap: 'wrap', marginBottom: 7 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 16 }}>{meta.ico}</span>
              <span style={{ fontWeight: n.isRead ? 600 : 800, fontSize: 13.5, color: txt }}>{displayTitle}</span>
              {!n.isRead && <span style={{ width: 7, height: 7, borderRadius: '50%', background: prim, display: 'inline-block' }} />}
            </div>
            <span style={{ fontSize: 10, color: sub, whiteSpace: 'nowrap' }}>{relTime(n.createdAt, lang)}</span>
          </div>

          <div
            style={{ fontSize: 12.5, color: sub, lineHeight: 1.7, ...( !isExpanded && isLong ? { display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical' as const, overflow: 'hidden' } : {}) }}
            dangerouslySetInnerHTML={{ __html: sanitizeClient(displayMsg) }}
          />
          {isLong && <span style={{ fontSize: 11, color: prim, fontWeight: 700, marginTop: 4, display: 'inline-block' }}>{isExpanded ? t('Show less','कम दिखाएं') : t('Read more →','और पढ़ें →')}</span>}

          {linkUrl && (
            <div onClick={e => e.stopPropagation()} style={{ marginTop: 10, border: `1px solid ${bdr}`, borderRadius: 10, padding: '8px 10px', display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 14 }}>🔗</span>
              <a href={linkUrl} target="_blank" rel="noreferrer" style={{ fontSize: 11, color: prim, textDecoration: 'none', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{linkUrl}</a>
            </div>
          )}

          <div onClick={e => e.stopPropagation()} style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap', alignItems: 'center' }}>
            {!n.isAcked ? (
              <button onClick={() => doAck(n._id)} style={{ fontSize: 10.5, fontWeight: 700, color: prim, background: theme.chipBg, border: `1px solid ${bdr}`, borderRadius: 99, padding: '5px 12px', cursor: 'pointer' }}>👍 {t('Got it','समझ गया')}</button>
            ) : (
              <span style={{ fontSize: 10.5, color: theme.isDark ? '#00C48C' : '#00A876', fontWeight: 700 }}>✓ {t('Acknowledged','स्वीकृत')}</span>
            )}
            {examDate && !isNaN(examDate.getTime()) && (
              <button onClick={() => downloadICS(displayTitle, examDate!)} style={{ fontSize: 10.5, fontWeight: 700, color: prim, background: theme.chipBg, border: `1px solid ${bdr}`, borderRadius: 99, padding: '5px 12px', cursor: 'pointer' }}>📅 {t('Add to Calendar','कैलेंडर में जोड़ें')}</button>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div style={{ animation: 'fadeIn .4s ease', maxWidth: 720, margin: '0 auto' }}>
      <style>{`
        @keyframes annShimmer { 0% { transform: translateX(-100%); } 100% { transform: translateX(100%); } }
        @keyframes annUrgentPulse { 0%,100% { box-shadow: 0 0 10px rgba(255,77,77,0.25); } 50% { box-shadow: 0 0 20px rgba(255,77,77,0.5); } }
      `}</style>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 10, flexWrap: 'wrap' }}>
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: txt, margin: '0 0 4px' }}>📢 {t('Announcements', 'घोषणाएं')}</div>
          <div style={{ fontSize: 12.5, color: sub, marginBottom: 14 }}>{t('Official notices, exam updates & important messages', 'आधिकारिक सूचनाएं, परीक्षा अपडेट और महत्वपूर्ण संदेश')}</div>
        </div>
        <button onClick={toggleSound} title={t('Toggle urgent sound/vibration','अत्यावश्यक ध्वनि टॉगल करें')} style={{ background: theme.chipBg, border: `1px solid ${bdr}`, borderRadius: 9, width: 34, height: 34, cursor: 'pointer', fontSize: 14 }}>{soundEnabled ? '🔔' : '🔕'}</button>
      </div>

      {/* §1.2 Stats chips */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' }}>
        <span style={{ fontSize: 11, fontWeight: 700, color: sub, background: theme.chipBg, padding: '6px 13px', borderRadius: 99 }}>{t('Total','कुल')}: {totalCount}</span>
        <span style={{ fontSize: 11, fontWeight: 700, color: prim, background: theme.chipBg, padding: '6px 13px', borderRadius: 99, boxShadow: unreadCount > 0 ? `0 0 10px ${prim}44` : 'none' }}>{t('Unread','अपठित')}: {unreadCount}</span>
        {urgentCount > 0 && <span style={{ fontSize: 11, fontWeight: 700, color: '#FF4D4D', background: 'rgba(255,77,77,0.12)', padding: '6px 13px', borderRadius: 99, animation: 'annUrgentPulse 2s infinite' }}>{t('Urgent','अत्यावश्यक')}: {urgentCount}</span>}
        {unreadCount > 0 && <button onClick={markAllRead} style={{ marginLeft: 'auto', fontSize: 11, fontWeight: 700, color: prim, background: 'transparent', border: `1px solid ${bdr}`, borderRadius: 99, padding: '6px 13px', cursor: 'pointer' }}>✓ {t('Mark all as read','सभी को पढ़ा हुआ चिह्नित करें')}</button>}
      </div>

      {/* §1.3 Filter pills + sort */}
      <div style={{ display: 'flex', gap: 7, overflowX: 'auto', paddingBottom: 4, marginBottom: 8 }}>
        {FILTERS.map(f => {
          const meta = f === 'all' ? null : TYPE_META[f]
          const active = filterType === f
          const col = meta?.col || prim
          return (
            <button key={f} onClick={() => setFilterType(f)} style={{ flexShrink: 0, display: 'flex', alignItems: 'center', gap: 5, padding: '7px 14px', borderRadius: 99, border: `1.5px solid ${active ? col : bdr}`, background: active ? `${col}1a` : 'transparent', boxShadow: active ? `0 0 10px ${col}44` : 'none', color: active ? col : sub, fontWeight: 700, fontSize: 11.5, cursor: 'pointer', whiteSpace: 'nowrap' }}>
              {meta ? `${meta.ico} ${t(meta.en, meta.hi)}` : t('All', 'सभी')}
            </button>
          )
        })}
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 14, alignItems: 'center' }}>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('🔍 Search announcements…', '🔍 घोषणाएं खोजें…')} style={{ flex: 1, background: theme.chipBg, border: `1px solid ${bdr}`, borderRadius: 10, padding: '9px 12px', color: txt, fontSize: 12.5, outline: 'none' }} />
        <button onClick={() => setSortMode(sortMode === 'pinned' ? 'newest' : 'pinned')} style={{ background: theme.chipBg, border: `1px solid ${bdr}`, borderRadius: 10, padding: '9px 14px', color: prim, fontSize: 11, fontWeight: 700, cursor: 'pointer', whiteSpace: 'nowrap' }}>
          {sortMode === 'pinned' ? `📌 ${t('Pinned First','पिन किए हुए पहले')}` : `🕐 ${t('Newest First','नवीनतम पहले')}`}
        </button>
      </div>

      {loading ? (
        <>{[1, 2, 3].map(i => <SkeletonCard key={i} dm={dm} />)}</>
      ) : visible.length === 0 ? (
        notices.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '50px 20px' }}>
            <svg width="80" height="80" viewBox="0 0 80 80" fill="none" style={{ opacity: 0.4, marginBottom: 12 }}>
              <path d="M15 30 Q15 15 30 15 L50 15 Q65 15 65 30 L65 48 Q65 62 50 62 L40 62 L22 74 L22 62 L30 62 Q15 62 15 48 Z" stroke={sub} strokeWidth="2" fill="none" />
              <text x="46" y="26" fontSize="14" fill={sub}>z z</text>
            </svg>
            <div style={{ fontSize: 13, color: sub }}>{t('No announcements yet. Check back soon!', 'अभी तक कोई घोषणा नहीं। जल्द ही वापस देखें!')}</div>
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '30px 20px', fontSize: 12.5, color: sub }}>{t('No announcements match this filter', 'इस फ़िल्टर से कोई घोषणा मेल नहीं खाती')}</div>
        )
      ) : (
        <>
          {pinnedList.length > 0 && sortMode === 'pinned' && (
            <>
              <div style={{ fontSize: 11.5, fontWeight: 700, color: C.gold, marginBottom: 8 }}>📌 {t('Pinned', 'पिन की गई')}</div>
              {pinnedList.map(n => <Card key={n._id} n={n} />)}
            </>
          )}
          {unpinnedList.map(n => <Card key={n._id} n={n} />)}
        </>
      )}
    </div>
  )
}

export default function AnnouncementsPage() {
  return <StudentShell pageKey="announcements"><AnnouncementsContent /></StudentShell>
}
