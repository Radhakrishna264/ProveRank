#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F42A/F42B — Announcements — FRONTEND fix script"
echo "════════════════════════════════════════════════════════"

WORKDIR=$(mktemp -d); cd "$WORKDIR"

# ── 1) Patch StudentShell.tsx — bell badge sync ──
cat > patch_studentshell_f42.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F42B §6.2 — Bell icon badge sync (unread announcement count)
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.APP_DIR,
  '/root/workspace/frontend/src/components',
  '/home/runner/workspace/frontend/src/components',
  path.join(process.cwd(), 'frontend/src/components'),
].filter(Boolean);

let TARGET = null;
for (const dir of CANDIDATES) {
  const p = path.join(dir, 'StudentShell.tsx');
  if (fs.existsSync(p)) { TARGET = p; break; }
}
if (!TARGET) {
  console.error('❌ Could not find StudentShell.tsx automatically.');
  console.error('   Set APP_DIR env var, e.g.:');
  console.error('   APP_DIR=/home/runner/workspace/frontend/src/components node patch_studentshell_f42.js');
  process.exit(1);
}
console.log('📄 Target file:', TARGET);

let src = fs.readFileSync(TARGET, 'utf8');
let count = 0;

// ── 1) Add unread state + fetch ──
{
  const anchor = `useEffect(()=>{fetch(\`\${API}/api/admin/maintenance\`).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.maintenance)setMaint(d.maintenance)}).catch(()=>{})},[])`;
  const addition = anchor + `

  // F42B §6.2 — Bell badge sync (unread announcement count)
  const [annUnread,setAnnUnread]=useState(0)
  useEffect(()=>{
    if(!token) return
    const loadUnread=()=>{fetch(\`\${API}/api/announcements/unread-count\`,{headers:{Authorization:\`Bearer \${token}\`}}).then(r=>r.ok?r.json():null).then(d=>{if(d)setAnnUnread(d.count||0)}).catch(()=>{})}
    loadUnread()
    const iv=setInterval(loadUnread,60000)
    return ()=>clearInterval(iv)
  },[token])`;
  if (src.includes(anchor) && !src.includes('annUnread')) {
    src = src.replace(anchor, addition);
    count++;
    console.log('✅ Patched: added unread-count state + polling fetch');
  } else if (src.includes('annUnread')) {
    console.log('⚠️  annUnread already present — skipping');
  } else {
    console.log('❌ maintenance useEffect anchor not found — state patch NOT applied');
  }
}

// ── 2) Add badge to bell icon ──
{
  const anchor = `<a href="/announcements" title={lang==='en'?'Announcements':'घोषणाएं'} style={{background:'transparent',border:\`1px solid \${bdr}\`,borderRadius:9,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',textDecoration:'none',fontSize:15,color:txt,flexShrink:0}}>🔔</a>`;
  const addition = `<a href="/announcements" title={lang==='en'?'Announcements':'घोषणाएं'} style={{position:'relative',background:'transparent',border:\`1px solid \${bdr}\`,borderRadius:9,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',textDecoration:'none',fontSize:15,color:txt,flexShrink:0}}>
              🔔
              {annUnread>0&&<span style={{position:'absolute',top:-4,right:-4,minWidth:16,height:16,borderRadius:8,background:'#FF4D4D',color:'#fff',fontSize:9,fontWeight:800,display:'flex',alignItems:'center',justifyContent:'center',padding:'0 3px',border:'1.5px solid '+(dm?'#050B14':'#fff')}}>{annUnread>9?'9+':annUnread}</span>}
            </a>`;
  if (src.includes(anchor)) {
    src = src.replace(anchor, addition);
    count++;
    console.log('✅ Patched: bell icon now shows unread badge');
  } else {
    console.log('⚠️  Bell icon anchor not found — badge NOT added (may already be patched)');
  }
}

if (count > 0) {
  fs.writeFileSync(TARGET, src);
  console.log(`\n✅ ${count}/2 StudentShell.tsx patch(es) applied and saved.`);
} else {
  console.log('\n⚠️  No changes were applied.');
}
PRNODEEOF
echo "🚀 Patching StudentShell.tsx..."
node patch_studentshell_f42.js

# ── 2) Write new Student Announcements page (full rewrite, F42B) ──
STU_TARGET=""
for candidate in \
  "/root/workspace/frontend/app/announcements/page.tsx" \
  "/home/runner/workspace/frontend/app/announcements/page.tsx"; do
  if [ -f "$candidate" ]; then STU_TARGET="$candidate"; break; fi
done
if [ -z "$STU_TARGET" ]; then
  echo "⚠️  Could not auto-detect student announcements page.tsx"
  echo "    Defaulting to: /root/workspace/frontend/app/announcements/page.tsx"
  STU_TARGET="/root/workspace/frontend/app/announcements/page.tsx"
fi
echo "📄 Student page target: $STU_TARGET"
mkdir -p "$(dirname "$STU_TARGET")"
if [ -f "$STU_TARGET" ]; then cp "$STU_TARGET" "$STU_TARGET.bak_$(date +%s)"; echo "🗄️  Backed up old file"; fi
cat > "$STU_TARGET" << 'PRNODEEOF'
'use client'
import { useState, useEffect, useMemo, useRef } from 'react'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

/* ══════════════════════════════════════════════════════════════
   F42B — STUDENT ANNOUNCEMENTS (restructured)
   ══════════════════════════════════════════════════════════════ */

const TYPE_COL: { [k: string]: string } = { exam: C.primary, update: C.success, result: C.gold, maintenance: C.warn, urgent: C.danger }
const TYPE_ICON: { [k: string]: string } = { exam: '📝', update: '✨', result: '🏅', maintenance: '🔧', urgent: '🚨' }
const TYPE_LABEL: { [k: string]: [string, string] } = { exam: ['Exam', 'परीक्षा'], update: ['Update', 'अपडेट'], result: ['Result', 'परिणाम'], maintenance: ['Maintenance', 'रखरखाव'], urgent: ['Urgent', 'जरूरी'] }

// ── §3.6 safe rich-text renderer — **bold** *italic* [text](url) — no raw HTML injection ──
function RichText({ text }: { text: string }) {
  if (!text) return null
  const parts: any[] = []
  let rest = text
  let key = 0
  const pattern = /\*\*(.+?)\*\*|\*(.+?)\*|\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g
  let lastIndex = 0
  let m: RegExpExecArray | null
  while ((m = pattern.exec(text))) {
    if (m.index > lastIndex) parts.push(<span key={key++}>{text.slice(lastIndex, m.index)}</span>)
    if (m[1]) parts.push(<b key={key++}>{m[1]}</b>)
    else if (m[2]) parts.push(<i key={key++}>{m[2]}</i>)
    else if (m[3] && m[4]) parts.push(<a key={key++} href={m[4]} target="_blank" rel="noopener noreferrer" style={{ color: C.primary, textDecoration: 'underline' }}>{m[3]}</a>)
    lastIndex = pattern.lastIndex
  }
  if (lastIndex < text.length) parts.push(<span key={key++}>{text.slice(lastIndex)}</span>)
  rest = ''
  return <>{parts}</>
}

// ── §6.6 simple link preview — detect first bare URL in message ──
function extractUrl(text: string): string | null {
  const m = text.match(/https?:\/\/[^\s)]+/)
  return m ? m[0] : null
}

// ── relative time (§3.7) ──
function relTime(d: string, lang: string) {
  const diff = Date.now() - new Date(d).getTime()
  const mins = Math.floor(diff / 60000), hrs = Math.floor(diff / 3600000), days = Math.floor(diff / 86400000)
  if (mins < 1) return lang === 'en' ? 'just now' : 'अभी'
  if (mins < 60) return lang === 'en' ? `${mins}m ago` : `${mins} मिनट पहले`
  if (hrs < 24) return lang === 'en' ? `${hrs}h ago` : `${hrs} घंटे पहले`
  if (days < 7) return lang === 'en' ? `${days}d ago` : `${days} दिन पहले`
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
}

function SkeletonCard({ dm }: { dm: boolean }) {
  return (
    <div style={{ background: dm ? C.card : C.cardL, border: `1px solid ${C.border}`, borderRadius: 13, padding: '15px 18px', marginBottom: 12, overflow: 'hidden', position: 'relative' as const }}>
      <style>{`@keyframes shimmerF42{0%{background-position:-200px 0}100%{background-position:200px 0}}`}</style>
      {[18, 12, 12].map((h, i) => (
        <div key={i} style={{ height: h, width: i === 0 ? '55%' : '90%', borderRadius: 6, marginBottom: 8, background: `linear-gradient(90deg, ${dm ? 'rgba(255,255,255,.05)' : 'rgba(0,0,0,.05)'} 25%, ${dm ? 'rgba(255,255,255,.12)' : 'rgba(0,0,0,.10)'} 37%, ${dm ? 'rgba(255,255,255,.05)' : 'rgba(0,0,0,.05)'} 63%)`, backgroundSize: '400px 100%', animation: 'shimmerF42 1.4s infinite linear' }} />
      ))}
    </div>
  )
}

function AnnouncementsContent() {
  const { lang, darkMode: dm, token, toast } = useShell()
  const t = (en: string, hi: string) => (lang === 'en' ? en : hi)
  const [notices, setNotices] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [sortMode, setSortMode] = useState<'pinned' | 'newest'>('pinned')
  const [search, setSearch] = useState('')
  const [expanded, setExpanded] = useState<{ [id: string]: boolean }>({})
  const notifiedRef = useRef<Set<string>>(new Set())

  const load = () => {
    if (!token) return
    fetch(`${API}/api/announcements`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => (r.ok ? r.json() : null))
      .then(d => {
        const list = d?.announcements || []
        const now = Date.now()
        const active = list.filter((n: any) => !n.expiryDate || new Date(n.expiryDate).getTime() >= now)
        setNotices(active)
        setLoading(false)
        // §6.1 Push notification for genuinely new announcements
        if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
          active.forEach((n: any) => {
            if (!n.isRead && !notifiedRef.current.has(n._id)) {
              notifiedRef.current.add(n._id)
              try { new Notification(n.title, { body: n.message?.slice(0, 100), icon: '/favicon.ico' }) } catch {}
            }
          })
        }
      })
      .catch(() => setLoading(false))
  }

  useEffect(() => { load() }, [token])
  useEffect(() => {
    if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission().catch(() => {})
    }
  }, [])

  const markRead = (id: string) => {
    setNotices(prev => prev.map(n => (n._id === id ? { ...n, isRead: true } : n)))
    fetch(`${API}/api/announcements/${id}/read`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } }).catch(() => {})
  }
  const ack = (id: string, e: any) => {
    e.stopPropagation()
    setNotices(prev => prev.map(n => (n._id === id ? { ...n, isAcked: true } : n)))
    fetch(`${API}/api/announcements/${id}/ack`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } }).then(() => toast?.(t('Thanks! 👍', 'धन्यवाद! 👍'), 's')).catch(() => {})
  }
  const markAllRead = () => {
    setNotices(prev => prev.map(n => ({ ...n, isRead: true })))
    fetch(`${API}/api/announcements/mark-all-read`, { method: 'POST', headers: { Authorization: `Bearer ${token}` } })
      .then(() => toast?.(t('All marked as read', 'सभी पढ़ा हुआ चिह्नित'), 's')).catch(() => {})
  }
  const addToCalendar = (n: any, e: any) => {
    e.stopPropagation()
    const dt = new Date(n.createdAt)
    const start = dt.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
    const url = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(n.title)}&dates=${start}/${start}&details=${encodeURIComponent(n.message)}`
    window.open(url, '_blank')
  }
  const toggleExpand = (id: string, e: any) => { e.stopPropagation(); setExpanded(p => ({ ...p, [id]: !p[id] })) }

  const clickCard = (n: any) => {
    if (!n.isRead) { markRead(n._id); return }
    setExpanded(p => ({ ...p, [n._id]: !p[n._id] }))
  }

  // ── filter/search/sort ──
  const filtered = useMemo(() => {
    let list = notices.filter(n => (filter === 'all' ? true : n.type === filter))
    if (search.trim()) {
      const q = search.toLowerCase()
      list = list.filter(n => n.title?.toLowerCase().includes(q) || n.message?.toLowerCase().includes(q))
    }
    return list
  }, [notices, filter, search])

  const pinned = filtered.filter(n => n.pinned)
  const rest = sortMode === 'pinned' ? filtered.filter(n => !n.pinned) : [...filtered].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
  const showPinnedSeparately = sortMode === 'pinned' && pinned.length > 0

  const total = notices.length
  const unread = notices.filter(n => !n.isRead).length
  const urgentCount = notices.filter(n => n.type === 'urgent' && !n.isRead).length

  const cardStyle = (n: any): any => ({
    background: dm ? C.card : C.cardL,
    border: `1px solid ${n.pinned ? 'rgba(255,215,0,0.35)' : C.border}`,
    borderRadius: 13, padding: '15px 18px', marginBottom: 12, backdropFilter: 'blur(14px)',
    borderLeft: `${n.isRead ? 4 : 5}px solid ${TYPE_COL[n.type] || C.primary}`,
    boxShadow: n.type === 'urgent' && !n.isRead ? `0 0 0 1px ${C.danger}33, 0 2px 16px ${C.danger}22` : '0 2px 12px rgba(0,0,0,.12)',
    opacity: n.isRead ? 0.85 : 1, cursor: 'pointer', position: 'relative' as const,
    animation: n.type === 'urgent' && !n.isRead ? 'urgentPulseF42 2s ease-in-out infinite' : undefined,
    background2: n.pinned ? 'linear-gradient(135deg, rgba(251,191,36,0.06), transparent)' : undefined,
  })

  const renderCard = (n: any) => {
    const url = extractUrl(n.message || '')
    const title = lang === 'hi' && n.titleHi ? n.titleHi : n.title
    const message = lang === 'hi' && n.messageHi ? n.messageHi : n.message
    const isLong = (message || '').length > 180
    const isExp = expanded[n._id]
    return (
      <div key={n._id} onClick={() => clickCard(n)} style={cardStyle(n)}>
        {n.pinned && <span style={{ position: 'absolute', top: 10, right: 12, fontSize: 14, transform: 'rotate(-15deg)' }}>📌</span>}
        {n.imageUrl && <img src={n.imageUrl} style={{ width: '100%', height: 120, objectFit: 'cover', borderRadius: 10, marginBottom: 10 }} />}
        <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap' as const, gap: 7, marginBottom: 7 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {!n.isRead && <span style={{ width: 7, height: 7, borderRadius: '50%', background: TYPE_COL[n.type] || C.primary, flexShrink: 0 }} />}
            <span style={{ fontSize: 16 }}>{TYPE_ICON[n.type] || '📢'}</span>
            <span style={{ fontWeight: n.isRead ? 500 : 700, fontSize: 13, color: dm ? C.text : C.textL }}>{title}</span>
            {n.type === 'urgent' && <span style={{ width: 6, height: 6, borderRadius: '50%', background: C.danger, animation: 'pulse .9s infinite' }} />}
          </div>
          <span style={{ fontSize: 10, color: C.sub, whiteSpace: 'nowrap' as const }}>{relTime(n.createdAt, lang)}</span>
        </div>
        <div style={{ fontSize: 12, color: C.sub, lineHeight: 1.7, ...(isLong && !isExp ? { display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical' as const, overflow: 'hidden' } : {}) }}>
          <RichText text={message || ''} />
        </div>
        {isLong && <button onClick={(e) => toggleExpand(n._id, e)} style={{ background: 'none', border: 'none', color: C.primary, fontSize: 11, fontWeight: 700, cursor: 'pointer', padding: '4px 0' }}>{isExp ? t('Show less', 'कम दिखाएं') : t('Read more →', 'और पढ़ें →')}</button>}
        {url && <a href={url} target="_blank" rel="noopener noreferrer" onClick={(e) => e.stopPropagation()} style={{ display: 'block', marginTop: 8, fontSize: 10, color: C.primary, background: dm ? 'rgba(77,159,255,0.08)' : 'rgba(37,99,235,0.06)', border: `1px solid ${C.border}`, borderRadius: 8, padding: '6px 10px', textDecoration: 'none', wordBreak: 'break-all' as const }}>🔗 {url}</a>}
        <div style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap' as const }}>
          {n.type === 'exam' && <button onClick={(e) => addToCalendar(n, e)} style={{ fontSize: 10, padding: '5px 10px', borderRadius: 8, border: `1px solid ${C.border}`, background: 'transparent', color: C.sub, cursor: 'pointer' }}>📅 {t('Add to Calendar', 'कैलेंडर में जोड़ें')}</button>}
          {!n.isAcked ? (
            <button onClick={(e) => ack(n._id, e)} style={{ fontSize: 10, padding: '5px 10px', borderRadius: 8, border: `1px solid ${C.success}55`, background: `${C.success}12`, color: C.success, cursor: 'pointer', fontWeight: 700 }}>👍 {t('Got it', 'समझ गया')}</button>
          ) : (
            <span style={{ fontSize: 10, padding: '5px 10px', color: C.success }}>✓ {t('Acknowledged', 'स्वीकृत')}</span>
          )}
        </div>
      </div>
    )
  }

  return (
    <div style={{ animation: 'fadeIn .4s ease' }}>
      <style>{`
        @keyframes urgentPulseF42{0%,100%{box-shadow:0 0 0 1px ${C.danger}33,0 2px 16px ${C.danger}22}50%{box-shadow:0 0 0 2px ${C.danger}55,0 2px 24px ${C.danger}44}}
        .f42-filters::-webkit-scrollbar{display:none}
      `}</style>

      <h1 style={{ fontFamily: 'Playfair Display,serif', fontSize: 26, fontWeight: 700, background: `linear-gradient(90deg,${C.primary},#fff)`, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', margin: '0 0 4px' }}>📢 {t('Announcements', 'घोषणाएं')}</h1>
      <div style={{ fontSize: 13, color: C.sub, marginBottom: 16 }}>{t('Official notices, exam updates & important messages', 'आधिकारिक सूचनाएं, परीक्षा अपडेट और महत्वपूर्ण संदेश')}</div>

      {/* ── Stats chips ── */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' as const, alignItems: 'center' }}>
        <span style={{ fontSize: 11, padding: '6px 12px', borderRadius: 20, background: dm ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)', color: C.sub, fontWeight: 600 }}>{t('Total', 'कुल')}: {total}</span>
        <span style={{ fontSize: 11, padding: '6px 12px', borderRadius: 20, background: `${C.primary}18`, color: C.primary, fontWeight: 800, boxShadow: unread > 0 ? `0 0 10px ${C.primary}33` : undefined }}>{t('Unread', 'अपठित')}: {unread}</span>
        {urgentCount > 0 && <span style={{ fontSize: 11, padding: '6px 12px', borderRadius: 20, background: `${C.danger}18`, color: C.danger, fontWeight: 800, border: `1px solid ${C.danger}55`, animation: 'pulse 1.2s infinite' }}>{t('Urgent', 'जरूरी')}: {urgentCount}</span>}
        {unread > 0 && <button onClick={markAllRead} style={{ marginLeft: 'auto', fontSize: 11, padding: '6px 12px', borderRadius: 20, border: `1px solid ${C.border}`, background: 'transparent', color: C.sub, cursor: 'pointer', fontWeight: 600 }}>✓ {t('Mark all as read', 'सभी पढ़ा हुआ चिह्नित करें')}</button>}
      </div>

      {/* ── Search ── */}
      <input value={search} onChange={e => setSearch(e.target.value)} placeholder={t('Search announcements...', 'घोषणाएं खोजें...')} style={{ width: '100%', padding: '10px 14px', borderRadius: 11, border: `1px solid ${C.border}`, background: dm ? 'rgba(0,22,40,.6)' : '#fff', color: dm ? C.text : C.textL, fontSize: 13, marginBottom: 12, boxSizing: 'border-box' as const }} />

      {/* ── Filter pills + sort ── */}
      <div className="f42-filters" style={{ display: 'flex', gap: 7, marginBottom: 18, overflowX: 'auto' as const, alignItems: 'center' }}>
        {[['all', t('All', 'सभी'), '📋'], ['exam', TYPE_LABEL.exam[lang === 'en' ? 0 : 1], TYPE_ICON.exam], ['update', TYPE_LABEL.update[lang === 'en' ? 0 : 1], TYPE_ICON.update], ['result', TYPE_LABEL.result[lang === 'en' ? 0 : 1], TYPE_ICON.result], ['maintenance', TYPE_LABEL.maintenance[lang === 'en' ? 0 : 1], TYPE_ICON.maintenance], ['urgent', TYPE_LABEL.urgent[lang === 'en' ? 0 : 1], TYPE_ICON.urgent]].map(([k, l, ic]: any) => (
          <button key={k} onClick={() => setFilter(k)} style={{ flexShrink: 0, padding: '7px 14px', borderRadius: 20, fontSize: 11, fontWeight: 700, cursor: 'pointer', border: `1px solid ${filter === k ? (TYPE_COL[k] || C.primary) : C.border}`, background: filter === k ? `${(TYPE_COL[k] || C.primary)}18` : 'transparent', color: filter === k ? (TYPE_COL[k] || C.primary) : C.sub, boxShadow: filter === k ? `0 0 10px ${(TYPE_COL[k] || C.primary)}33` : undefined }}>{ic} {l}</button>
        ))}
        <button onClick={() => setSortMode(m => (m === 'pinned' ? 'newest' : 'pinned'))} style={{ marginLeft: 'auto', flexShrink: 0, fontSize: 10, padding: '7px 12px', borderRadius: 20, border: `1px solid ${C.border}`, background: 'transparent', color: C.sub, cursor: 'pointer' }}>{sortMode === 'pinned' ? `📌 ${t('Pinned First', 'पिन पहले')}` : `🕐 ${t('Newest First', 'नया पहले')}`}</button>
      </div>

      {/* ── Content ── */}
      {loading ? (
        <>{[1, 2, 3].map(i => <SkeletonCard key={i} dm={!!dm} />)}</>
      ) : filtered.length === 0 ? (
        notices.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '50px 20px' }}>
            <div style={{ fontSize: 50, marginBottom: 10, opacity: 0.5 }}>🔔💤</div>
            <div style={{ color: C.sub, fontSize: 13 }}>{t('No announcements yet. Check back soon!', 'अभी तक कोई घोषणा नहीं। जल्द ही देखें!')}</div>
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '30px 20px', color: C.sub, fontSize: 12 }}>{t('No announcements match this filter', 'इस फ़िल्टर से कोई घोषणा मेल नहीं खाती')}</div>
        )
      ) : (
        <>
          {showPinnedSeparately && (
            <>
              <div style={{ fontSize: 11, fontWeight: 700, color: C.gold, marginBottom: 8, display: 'flex', alignItems: 'center', gap: 5 }}>📌 {t('Pinned', 'पिन किया गया')}</div>
              {pinned.map(renderCard)}
              <div style={{ height: 1, background: C.border, margin: '14px 0' }} />
            </>
          )}
          {rest.map(renderCard)}
        </>
      )}
    </div>
  )
}

export default function AnnouncementsPage() {
  return (
    <StudentShell pageKey="announcements">
      <AnnouncementsContent />
    </StudentShell>
  )
}
PRNODEEOF
echo "✅ Student Announcements page rewritten (F42B)"

# ── 3) Patch Admin panel — full F42A Announcements tab rebuild ──
cat > patch_admin_f42.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F42A — Patch admin panel page.tsx: add Announcements state/functions
// + replace the old basic Announcements tab JSX with the full rebuild.
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.APP_DIR,
  '/root/workspace/frontend/app/admin/x7k2p',
  '/home/runner/workspace/frontend/app/admin/x7k2p',
  path.join(process.cwd(), 'frontend/app/admin/x7k2p'),
].filter(Boolean);

let TARGET = null;
for (const dir of CANDIDATES) {
  const p = path.join(dir, 'page.tsx');
  if (fs.existsSync(p)) { TARGET = p; break; }
}
if (!TARGET) {
  console.error('❌ Could not find admin page.tsx automatically.');
  console.error('   Set APP_DIR env var, e.g.:');
  console.error('   APP_DIR=/home/runner/workspace/frontend/app/admin/x7k2p node patch_admin_f42.js');
  process.exit(1);
}
console.log('📄 Target file:', TARGET);

let src = fs.readFileSync(TARGET, 'utf8');
let count = 0;

// ── 1) Insert new state + functions after existing annType state ──
{
  const anchor = "const [annType,setAnnType]=useState<'in-app'|'email'|'both'>('both')";
  const stateBlock = "  // ══ F42A — Announcements: extended state ══\n  const [annCategory,setAnnCategory]=useState<'exam'|'update'|'result'|'urgent'>('update')\n  const [annTitle,setAnnTitle]=useState('')\n  const [annTitleHi,setAnnTitleHi]=useState('')\n  const [annMsg,setAnnMsg]=useState('')\n  const [annMsgHi,setAnnMsgHi]=useState('')\n  const [annAudMode,setAnnAudMode]=useState<'all'|'batch'|'testseries'|'students'>('all')\n  const [annSelBatches,setAnnSelBatches]=useState<string[]>([])\n  const [annStudentQ,setAnnStudentQ]=useState('')\n  const [annStudentResults,setAnnStudentResults]=useState<any[]>([])\n  const [annSelStudents,setAnnSelStudents]=useState<any[]>([])\n  const [annPinned,setAnnPinned]=useState(false)\n  const [annImageUrl,setAnnImageUrl]=useState('')\n  const [annScheduleMode,setAnnScheduleMode]=useState<'now'|'schedule'>('now')\n  const [annScheduledAt,setAnnScheduledAt]=useState('')\n  const [annExpiryDays,setAnnExpiryDays]=useState('')\n  const [annPreviewOpen,setAnnPreviewOpen]=useState(false)\n  const [annSending,setAnnSending]=useState(false)\n  const [annHistory,setAnnHistory]=useState<any[]>([])\n  const [annHistoryLoading,setAnnHistoryLoading]=useState(false)\n  const [annStats,setAnnStats]=useState<any>(null)\n  const [annSearchQ,setAnnSearchQ]=useState('')\n  const [annFilterType,setAnnFilterType]=useState('')\n  const [annTemplates,setAnnTemplates]=useState<any[]>([])\n  const [annReadStatsId,setAnnReadStatsId]=useState<string|null>(null)\n  const [annReadStatsData,setAnnReadStatsData]=useState<any>(null)\n\n  const annResetCompose=()=>{\n    setAnnTitle('');setAnnTitleHi('');setAnnMsg('');setAnnMsgHi('');setAnnCategory('update')\n    setAnnAudMode('all');setAnnSelBatches([]);setAnnSelStudents([]);setAnnStudentQ('');setAnnStudentResults([])\n    setAnnPinned(false);setAnnImageUrl('');setAnnScheduleMode('now');setAnnScheduledAt('');setAnnExpiryDays('')\n  }\n\n  const loadAnnHistory=useCallback(async()=>{\n    setAnnHistoryLoading(true)\n    try{\n      const qs=new URLSearchParams()\n      if(annSearchQ)qs.set('search',annSearchQ)\n      if(annFilterType)qs.set('type',annFilterType)\n      const r=await fetch(`${API}/api/admin/announcements?${qs.toString()}`,{headers:{Authorization:`Bearer ${token}`}})\n      const d=await r.json()\n      if(r.ok&&d.success)setAnnHistory(d.announcements||[])\n    }catch{}\n    setAnnHistoryLoading(false)\n  },[annSearchQ,annFilterType,token])\n\n  const loadAnnStats=useCallback(async()=>{\n    try{\n      const r=await fetch(`${API}/api/admin/announcements/stats`,{headers:{Authorization:`Bearer ${token}`}})\n      const d=await r.json()\n      if(r.ok&&d.success)setAnnStats(d)\n    }catch{}\n  },[token])\n\n  const loadAnnTemplates=useCallback(async()=>{\n    try{\n      const r=await fetch(`${API}/api/admin/announcements/templates`,{headers:{Authorization:`Bearer ${token}`}})\n      const d=await r.json()\n      if(r.ok&&d.success)setAnnTemplates(d.templates||[])\n    }catch{}\n  },[token])\n\n  useEffect(()=>{ if(tab==='announcements'){loadAnnHistory();loadAnnStats();loadAnnTemplates()} },[tab])\n  useEffect(()=>{ if(tab==='announcements')loadAnnHistory() },[annSearchQ,annFilterType])\n\n  useEffect(()=>{\n    if(annAudMode!=='students'||!annStudentQ.trim()){setAnnStudentResults([]);return}\n    const h=setTimeout(async()=>{\n      try{\n        const r=await fetch(`${API}/api/admin/announcements/students-search?q=${encodeURIComponent(annStudentQ)}`,{headers:{Authorization:`Bearer ${token}`}})\n        const d=await r.json()\n        if(r.ok&&d.success)setAnnStudentResults(d.students||[])\n      }catch{}\n    },400)\n    return ()=>clearTimeout(h)\n  },[annStudentQ,annAudMode,token])\n\n  const annBuildAudience=()=>{\n    if(annAudMode==='all')return{mode:'all'}\n    if(annAudMode==='batch'||annAudMode==='testseries')return{mode:annAudMode,batchIds:annSelBatches}\n    return{mode:'students',studentIds:annSelStudents.map(s=>s._id)}\n  }\n\n  const annApplyTemplate=(tpl:any)=>{\n    setAnnTitle(tpl.title);setAnnMsg(tpl.message);setAnnCategory(tpl.type)\n    T(`Template \"${tpl.label}\" applied.`)\n  }\n\n  const sendAnn2=useCallback(async(asDraft=false)=>{\n    if(!annTitle.trim()||!annMsg.trim()){T('Title and message are required.','e');return}\n    setAnnSending(true)\n    try{\n      const payload={\n        title:annTitle,titleHi:annTitleHi,message:annMsg,messageHi:annMsgHi,\n        type:annCategory,pinned:annPinned,imageUrl:annImageUrl,\n        audience:annBuildAudience(),sendVia:annType,\n        saveAsDraft:asDraft,\n        scheduledAt:annScheduleMode==='schedule'&&annScheduledAt?annScheduledAt:null,\n        expiryDate:annExpiryDays?new Date(Date.now()+Number(annExpiryDays)*86400000).toISOString():null,\n      }\n      const r=await fetch(`${API}/api/admin/announcements`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(payload)})\n      const d=await r.json()\n      if(r.ok&&d.success){T(d.message||'Done.');annResetCompose();loadAnnHistory();loadAnnStats()}\n      else T(d.message||'Failed to send announcement.','e')\n    }catch{T('Network error.','e')}\n    setAnnSending(false)\n  },[annTitle,annTitleHi,annMsg,annMsgHi,annCategory,annPinned,annImageUrl,annAudMode,annSelBatches,annSelStudents,annType,annScheduleMode,annScheduledAt,annExpiryDays,token,T,loadAnnHistory,loadAnnStats])\n\n  const annResend=async(id:string)=>{\n    try{\n      const r=await fetch(`${API}/api/admin/announcements/${id}/resend`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})\n      const d=await r.json()\n      if(r.ok&&d.success){T('Resent successfully.');loadAnnHistory();loadAnnStats()}\n      else T(d.message||'Failed to resend.','e')\n    }catch{T('Network error.','e')}\n  }\n  const annDuplicate=async(id:string)=>{\n    try{\n      const r=await fetch(`${API}/api/admin/announcements/${id}/duplicate`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})\n      const d=await r.json()\n      if(r.ok&&d.success){T('Duplicated as draft.');loadAnnHistory()}\n      else T(d.message||'Failed to duplicate.','e')\n    }catch{T('Network error.','e')}\n  }\n  const annDelete=async(id:string)=>{\n    if(!window.confirm('Delete this announcement?'))return\n    try{\n      const r=await fetch(`${API}/api/admin/announcements/${id}`,{method:'DELETE',headers:{Authorization:`Bearer ${token}`}})\n      if(r.ok){T('Deleted.');loadAnnHistory();loadAnnStats()}\n      else T('Failed to delete.','e')\n    }catch{T('Network error.','e')}\n  }\n  const annOpenReadStats=async(id:string)=>{\n    setAnnReadStatsId(id);setAnnReadStatsData(null)\n    try{\n      const r=await fetch(`${API}/api/admin/announcements/${id}/read-stats`,{headers:{Authorization:`Bearer ${token}`}})\n      const d=await r.json()\n      if(r.ok&&d.success)setAnnReadStatsData(d)\n    }catch{}\n  }\n";
  if (src.includes(anchor) && !src.includes('annCategory')) {
    src = src.replace(anchor, anchor + '\n' + stateBlock);
    count++;
    console.log('✅ Patched: added F42A state + functions (templates, audience, schedule, history, resend/duplicate/delete, read-stats)');
  } else if (src.includes('annCategory')) {
    console.log('⚠️  F42A state already present — skipping');
  } else {
    console.log('❌ annType state anchor not found — state patch NOT applied');
  }
}

// ── 2) Replace the old Announcements tab JSX with the full F42A rebuild ──
{
  const anchor = "{tab==='announcements'&&(\n            <div>\n              <div style={pageTitle}>📢 Announcements (S47/S12)</div>\n              <div style={pageSub}>Send broadcasts to all students or specific batches</div>\n              <PageHero icon=\"📢\" title=\"Platform Broadcast Center\" subtitle=\"Send announcements via in-app notifications, email, or both. Target all students or specific batches. Schedule announcements in advance.\"/>\n              <div style={cs}>\n                <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>✍️ Compose Announcement</div>\n                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>\n                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Title</label><SInput init='' onSet={v=>{annTitleR.current=v}} ph='Announcement title…' style={inp}/></div>\n                  <div><label style={lbl}>Target Audience</label><SSelect val={annBatch} onChange={setAnnBatch} opts={[{v:'all',l:'All Students'},...(batches||[]).map(b=>({v:b._id,l:b.name}))]} style={{...inp}}/></div>\n                  <div><label style={lbl}>Send Via</label><SSelect val={annType} onChange={v=>setAnnType(v as 'in-app'|'email'|'both')} opts={[{v:'in-app',l:'In-App Only'},{v:'email',l:'Email Only'},{v:'both',l:'In-App + Email'}]} style={{...inp}}/></div>\n                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Message *</label><STextarea init='' onSet={v=>{annR.current=v}} ph='Write your announcement here…' rows={4} style={{...inp,resize:'vertical'}}/></div>\n                </div>\n                <button onClick={sendAnn} style={{...bp,width:'100%'}}>📢 Send Announcement</button>\n              </div>\n            </div>\n          )}";
  const jsxBlock = "{tab==='announcements'&&(\n            <div>\n              <div style={pageTitle}>📢 Announcements</div>\n              <div style={pageSub}>Send broadcasts to all students or specific batches</div>\n              <PageHero icon=\"📢\" title=\"Platform Broadcast Center\" subtitle=\"Send announcements via in-app notifications, email, or both. Target all students, specific batches, or individuals. Schedule announcements in advance.\"/>\n\n              {/* ── Stats bar ── */}\n              <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:10,marginBottom:16}}>\n                {[['Total Sent',annStats?.totalSent??'—',ACC],['This Week',annStats?.thisWeek??'—',SUC],['Avg. Read Rate',annStats?annStats.avgReadRate+'%':'—',GOLD],['Scheduled',annStats?.scheduled??'—',WRN]].map(([l,v,c],i)=>(\n                  <div key={i} style={{...cs,padding:'12px 14px',textAlign:'center' as const}}>\n                    <div style={{fontSize:18,fontWeight:800,color:c as string}}>{v as any}</div>\n                    <div style={{fontSize:9,color:DIM,textTransform:'uppercase' as const,marginTop:2}}>{l as string}</div>\n                  </div>\n                ))}\n              </div>\n\n              {/* ── Compose Card ── */}\n              <div style={cs}>\n                <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>✍️ Compose Announcement</div>\n\n                {/* Templates quick-fill */}\n                {annTemplates.length>0&&(\n                  <div style={{display:'flex',gap:6,marginBottom:12,flexWrap:'wrap' as const}}>\n                    {annTemplates.map((tpl:any)=>(\n                      <button key={tpl.key} onClick={()=>annApplyTemplate(tpl)} style={{fontSize:10,padding:'5px 10px',borderRadius:8,border:`1px solid ${BOR}`,background:'transparent',color:DIM,cursor:'pointer'}}>📋 {tpl.label}</button>\n                    ))}\n                  </div>\n                )}\n\n                {/* Type/Category pills */}\n                <label style={lbl}>Type</label>\n                <div style={{display:'flex',gap:8,marginBottom:14,flexWrap:'wrap' as const}}>\n                  {[['exam','🔵 Exam',ACC],['update','🟢 Update',SUC],['result','🟡 Result',GOLD],['urgent','🔴 Urgent',DNG]].map(([k,l,c])=>(\n                    <button key={k as string} onClick={()=>setAnnCategory(k as any)} style={{padding:'8px 16px',borderRadius:10,fontSize:11,fontWeight:700,cursor:'pointer',border:`1.5px solid ${annCategory===k?c:BOR}`,background:annCategory===k?`${c}18`:'transparent',color:annCategory===k?c:DIM,boxShadow:annCategory===k?`0 0 10px ${c}33`:undefined}}>{l as string}</button>\n                  ))}\n                </div>\n\n                {/* Bilingual Title */}\n                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>\n                  <div><label style={lbl}>Title (English)</label><SInput init={annTitle} onSet={setAnnTitle} ph='Announcement title…' style={inp}/></div>\n                  <div><label style={lbl}>Title (Hindi) — optional</label><SInput init={annTitleHi} onSet={setAnnTitleHi} ph='शीर्षक हिंदी में…' style={inp}/></div>\n                </div>\n\n                {/* Audience mode */}\n                <label style={lbl}>Target Audience</label>\n                <div style={{display:'flex',gap:8,marginBottom:10,flexWrap:'wrap' as const}}>\n                  {[['all','🌐 All Students'],['batch','🏫 Batches'],['testseries','📚 Test Series'],['students','👤 Specific Students']].map(([k,l])=>(\n                    <button key={k} onClick={()=>setAnnAudMode(k as any)} style={{padding:'7px 13px',borderRadius:9,fontSize:11,fontWeight:600,cursor:'pointer',border:`1px solid ${annAudMode===k?ACC:BOR}`,background:annAudMode===k?`${ACC}15`:'transparent',color:annAudMode===k?ACC:DIM}}>{l}</button>\n                  ))}\n                </div>\n\n                {(annAudMode==='batch'||annAudMode==='testseries')&&(\n                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:14,maxHeight:180,overflowY:'auto' as const,padding:10,background:'rgba(0,0,0,0.15)',borderRadius:10}}>\n                    {(batches||[]).map(b=>{\n                      const sel=annSelBatches.includes(b._id)\n                      return (\n                        <label key={b._id} style={{display:'flex',alignItems:'center',gap:7,fontSize:11,color:sel?ACC:DIM,cursor:'pointer',padding:'6px 8px',borderRadius:7,background:sel?`${ACC}12`:'transparent'}}>\n                          <input type=\"checkbox\" checked={sel} onChange={()=>setAnnSelBatches(p=>sel?p.filter(x=>x!==b._id):[...p,b._id])}/>\n                          🏫 {b.name} — {(b as any).studentCount||0} students\n                        </label>\n                      )\n                    })}\n                    {(!batches||batches.length===0)&&<div style={{fontSize:11,color:DIM,gridColumn:'1/-1'}}>No batches found.</div>}\n                  </div>\n                )}\n\n                {annAudMode==='students'&&(\n                  <div style={{marginBottom:14}}>\n                    <SInput init={annStudentQ} onSet={setAnnStudentQ} ph='🔍 Search student by name, email or ID…' style={inp}/>\n                    {annStudentResults.length>0&&(\n                      <div style={{marginTop:6,maxHeight:150,overflowY:'auto' as const,background:'rgba(0,0,0,0.2)',borderRadius:8}}>\n                        {annStudentResults.map((s:any)=>(\n                          <div key={s._id} onClick={()=>{if(!annSelStudents.find(x=>x._id===s._id))setAnnSelStudents(p=>[...p,s]);setAnnStudentQ('');setAnnStudentResults([])}} style={{padding:'8px 10px',fontSize:11,cursor:'pointer',borderBottom:`1px solid ${BOR}`,color:TS}}>{s.name} — {s.email} {s.studentId?`(${s.studentId})`:''}</div>\n                        ))}\n                      </div>\n                    )}\n                    {annSelStudents.length>0&&(\n                      <div style={{display:'flex',gap:6,flexWrap:'wrap' as const,marginTop:8}}>\n                        {annSelStudents.map(s=>(\n                          <span key={s._id} style={{fontSize:10,padding:'4px 9px',borderRadius:14,background:`${ACC}15`,color:ACC,display:'flex',alignItems:'center',gap:5}}>{s.name} <span onClick={()=>setAnnSelStudents(p=>p.filter(x=>x._id!==s._id))} style={{cursor:'pointer',fontWeight:800}}>✕</span></span>\n                        ))}\n                      </div>\n                    )}\n                  </div>\n                )}\n\n                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>\n                  <div><label style={lbl}>Send Via</label><SSelect val={annType} onChange={v=>setAnnType(v as 'in-app'|'email'|'both')} opts={[{v:'in-app',l:'In-App Only'},{v:'email',l:'Email Only'},{v:'both',l:'In-App + Email'}]} style={{...inp}}/></div>\n                  <div><label style={lbl}>Image URL — optional</label><SInput init={annImageUrl} onSet={setAnnImageUrl} ph='https://…' style={inp}/></div>\n                </div>\n\n                {/* Bilingual message */}\n                <div style={{marginBottom:10}}><label style={lbl}>Message (English) *  —  supports **bold** *italic* [text](url)</label><STextarea init={annMsg} onSet={setAnnMsg} ph='Write your announcement here…' rows={4} style={{...inp,resize:'vertical'}}/><div style={{fontSize:9,color:DIM,textAlign:'right' as const,marginTop:2}}>{annMsg.length} characters</div></div>\n                <div style={{marginBottom:14}}><label style={lbl}>Message (Hindi) — optional</label><STextarea init={annMsgHi} onSet={setAnnMsgHi} ph='संदेश हिंदी में…' rows={3} style={{...inp,resize:'vertical'}}/></div>\n\n                {/* Pin + schedule + expiry row */}\n                <div style={{display:'flex',gap:16,alignItems:'center',marginBottom:14,flexWrap:'wrap' as const}}>\n                  <label style={{display:'flex',alignItems:'center',gap:7,fontSize:12,color:TS,cursor:'pointer'}}><input type=\"checkbox\" checked={annPinned} onChange={e=>setAnnPinned(e.target.checked)}/> 📌 Pin this announcement</label>\n                  <div style={{display:'flex',gap:6}}>\n                    <button onClick={()=>setAnnScheduleMode('now')} style={{fontSize:10,padding:'6px 12px',borderRadius:8,border:`1px solid ${annScheduleMode==='now'?SUC:BOR}`,background:annScheduleMode==='now'?`${SUC}15`:'transparent',color:annScheduleMode==='now'?SUC:DIM,cursor:'pointer'}}>⚡ Send Now</button>\n                    <button onClick={()=>setAnnScheduleMode('schedule')} style={{fontSize:10,padding:'6px 12px',borderRadius:8,border:`1px solid ${annScheduleMode==='schedule'?ACC:BOR}`,background:annScheduleMode==='schedule'?`${ACC}15`:'transparent',color:annScheduleMode==='schedule'?ACC:DIM,cursor:'pointer'}}>🕐 Schedule</button>\n                  </div>\n                  {annScheduleMode==='schedule'&&<input type=\"datetime-local\" value={annScheduledAt} onChange={e=>setAnnScheduledAt(e.target.value)} style={{...inp,width:200,padding:'7px 10px',fontSize:11}}/>}\n                  <div style={{display:'flex',alignItems:'center',gap:6}}>\n                    <span style={{fontSize:11,color:DIM}}>Expires after</span>\n                    <input type=\"number\" min=\"0\" value={annExpiryDays} onChange={e=>setAnnExpiryDays(e.target.value)} placeholder=\"—\" style={{...inp,width:60,padding:'6px 8px',fontSize:11}}/>\n                    <span style={{fontSize:11,color:DIM}}>days</span>\n                  </div>\n                </div>\n\n                <div style={{display:'flex',gap:10}}>\n                  <button onClick={()=>setAnnPreviewOpen(true)} style={{...bp,flex:'0 0 auto',background:'transparent',border:`1px solid ${BOR}`,color:DIM}}>👁️ Preview</button>\n                  <button onClick={()=>sendAnn2(true)} disabled={annSending} style={{...bp,flex:'0 0 auto',background:'transparent',border:`1px solid ${BOR}`,color:DIM}}>💾 Save Draft</button>\n                  <button onClick={()=>sendAnn2(false)} disabled={annSending} style={{...bp,flex:1,opacity:annSending?0.7:1}}>{annSending?'⟳ Sending…':annScheduleMode==='schedule'?'🕐 Schedule Announcement':'📢 Send Announcement'}</button>\n                </div>\n              </div>\n\n              {/* ── Sent History ── */}\n              <div style={{...cs,marginTop:16}}>\n                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap' as const,gap:8,marginBottom:12}}>\n                  <div style={{fontWeight:700,fontSize:13}}>📜 Sent Announcements</div>\n                  <div style={{display:'flex',gap:8,flexWrap:'wrap' as const}}>\n                    <SInput init={annSearchQ} onSet={setAnnSearchQ} ph='Search…' style={{...inp,width:160,padding:'6px 10px',fontSize:11}}/>\n                    <SSelect val={annFilterType} onChange={setAnnFilterType} opts={[{v:'',l:'All Types'},{v:'exam',l:'Exam'},{v:'update',l:'Update'},{v:'result',l:'Result'},{v:'urgent',l:'Urgent'}]} style={{...inp,width:130,padding:'6px 10px',fontSize:11}}/>\n                  </div>\n                </div>\n                {annHistoryLoading?(\n                  <div style={{textAlign:'center' as const,padding:20,color:DIM,fontSize:12}}>⟳ Loading…</div>\n                ):annHistory.length===0?(\n                  <div style={{textAlign:'center' as const,padding:30,color:DIM,fontSize:12}}>No announcements sent yet.</div>\n                ):(\n                  annHistory.map((a:any)=>(\n                    <div key={a._id} style={{padding:'12px 14px',borderRadius:10,background:'rgba(0,0,0,0.15)',marginBottom:8,borderLeft:`4px solid ${a.pinned?GOLD:a.type==='urgent'?DNG:ACC}`}}>\n                      <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap' as const,gap:6}}>\n                        <div style={{display:'flex',alignItems:'center',gap:7}}>\n                          {a.pinned&&<span>📌</span>}\n                          {a.type==='urgent'&&<span style={{width:6,height:6,borderRadius:'50%',background:DNG,animation:'pulse .9s infinite'}}/>}\n                          <span style={{fontWeight:700,fontSize:12,color:TS}}>{a.title}</span>\n                          <span style={{fontSize:9,padding:'2px 8px',borderRadius:12,background:`${ACC}15`,color:ACC,textTransform:'capitalize' as const}}>{a.status}</span>\n                        </div>\n                        <span style={{fontSize:10,color:DIM}}>{a.createdAt?new Date(a.createdAt).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'}):''}</span>\n                      </div>\n                      <div style={{fontSize:11,color:DIM,margin:'6px 0',overflow:'hidden',textOverflow:'ellipsis' as const,whiteSpace:'nowrap' as const}}>{a.message}</div>\n                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap' as const,gap:8}}>\n                        <div style={{fontSize:10,color:DIM}}>{a.audience?.mode} · {a.sendVia} · <span onClick={()=>annOpenReadStats(a._id)} style={{cursor:'pointer',color:ACC,textDecoration:'underline'}}>{a.readCount||0}/{a.targetCount||0} viewed</span></div>\n                        <div style={{display:'flex',gap:6}}>\n                          <button onClick={()=>annResend(a._id)} style={{fontSize:10,padding:'4px 9px',borderRadius:7,border:`1px solid ${BOR}`,background:'transparent',color:DIM,cursor:'pointer'}}>🔄 Resend</button>\n                          <button onClick={()=>annDuplicate(a._id)} style={{fontSize:10,padding:'4px 9px',borderRadius:7,border:`1px solid ${BOR}`,background:'transparent',color:DIM,cursor:'pointer'}}>📋 Duplicate</button>\n                          <button onClick={()=>annDelete(a._id)} style={{fontSize:10,padding:'4px 9px',borderRadius:7,border:`1px solid ${DNG}44`,background:'transparent',color:DNG,cursor:'pointer'}}>🗑️ Delete</button>\n                        </div>\n                      </div>\n                    </div>\n                  ))\n                )}\n              </div>\n\n              {/* ── Preview Modal ── */}\n              {annPreviewOpen&&(\n                <div onClick={()=>setAnnPreviewOpen(false)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.7)',zIndex:9000,display:'flex',alignItems:'center',justifyContent:'center',padding:20}}>\n                  <div onClick={e=>e.stopPropagation()} style={{width:'100%',maxWidth:420,background:CRD,border:`1px solid ${BOR}`,borderRadius:16,padding:18}}>\n                    <div style={{fontSize:11,color:DIM,marginBottom:10,fontWeight:700}}>👁️ STUDENT-SIDE PREVIEW</div>\n                    <div style={{background:'rgba(0,0,0,0.2)',borderRadius:12,padding:'14px 16px',borderLeft:`4px solid ${annCategory==='urgent'?DNG:annCategory==='result'?GOLD:annCategory==='exam'?ACC:SUC}`}}>\n                      {annImageUrl&&<img src={annImageUrl} style={{width:'100%',height:100,objectFit:'cover',borderRadius:8,marginBottom:8}}/>}\n                      <div style={{display:'flex',alignItems:'center',gap:7,marginBottom:6}}>\n                        {annPinned&&<span>📌</span>}\n                        <span style={{fontWeight:700,fontSize:13,color:TS}}>{annTitle||'Untitled Announcement'}</span>\n                      </div>\n                      <div style={{fontSize:11,color:DIM,lineHeight:1.6}}>{annMsg||'Your message will appear here…'}</div>\n                    </div>\n                    <button onClick={()=>setAnnPreviewOpen(false)} style={{...bp,width:'100%',marginTop:14}}>Close Preview</button>\n                  </div>\n                </div>\n              )}\n\n              {/* ── Read Stats Modal ── */}\n              {annReadStatsId&&(\n                <div onClick={()=>setAnnReadStatsId(null)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.7)',zIndex:9000,display:'flex',alignItems:'center',justifyContent:'center',padding:20}}>\n                  <div onClick={e=>e.stopPropagation()} style={{width:'100%',maxWidth:400,maxHeight:'70vh',overflowY:'auto' as const,background:CRD,border:`1px solid ${BOR}`,borderRadius:16,padding:18}}>\n                    <div style={{fontWeight:700,fontSize:13,marginBottom:10}}>👁️ Read Receipts</div>\n                    {!annReadStatsData?<div style={{color:DIM,fontSize:12}}>Loading…</div>:(\n                      <>\n                        <div style={{fontSize:12,color:DIM,marginBottom:10}}>{annReadStatsData.readCount}/{annReadStatsData.targetCount} students viewed this announcement</div>\n                        {(annReadStatsData.readList||[]).map((r:any,i:number)=>(\n                          <div key={i} style={{fontSize:11,padding:'6px 0',borderBottom:`1px solid ${BOR}`,color:TS}}>{r.studentId?.name||'Unknown'} — {r.readAt?new Date(r.readAt).toLocaleString('en-IN'):''}</div>\n                        ))}\n                      </>\n                    )}\n                    <button onClick={()=>setAnnReadStatsId(null)} style={{...bp,width:'100%',marginTop:14}}>Close</button>\n                  </div>\n                </div>\n              )}\n            </div>\n          )}";
  if (src.includes(anchor)) {
    src = src.replace(anchor, jsxBlock);
    count++;
    console.log('✅ Patched: replaced Announcements tab with full F42A UI (stats bar, type pills, bilingual, audience targeting, schedule, history, preview, read-stats)');
  } else if (src.includes('STUDENT-SIDE PREVIEW')) {
    console.log('⚠️  F42A JSX already present — skipping');
  } else {
    console.log('❌ Old Announcements tab JSX not found — JSX patch NOT applied (file may have changed)');
  }
}

if (count > 0) {
  fs.writeFileSync(TARGET, src);
  console.log(`\n✅ ${count}/2 admin patch(es) applied and saved.`);
} else {
  console.log('\n⚠️  No changes were applied.');
}
PRNODEEOF
echo "🚀 Patching Admin panel (Announcements tab)..."
node patch_admin_f42.js

# ══════════════════════════════════════════════════════════
# VERIFICATION
# ══════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════"
echo " VERIFICATION — F42 Frontend"
echo "════════════════════════════════════════════════════════"
PASS=0; FAIL=0
check() { if grep -qF "$2" "$3" 2>/dev/null; then echo "✅ $1"; PASS=$((PASS+1)); else echo "❌ $1"; FAIL=$((FAIL+1)); fi }

check "F42B §1.2 Stats chips (Total/Unread/Urgent)" "t('Unread'" "$STU_TARGET"
check "F42B §1.3.1 Type filter pills" "TYPE_LABEL.exam" "$STU_TARGET"
check "F42B §1.3.2 Sort toggle (Newest/Pinned First)" "setSortMode" "$STU_TARGET"
check "F42B §1.4 Search bar" "t('Search announcements" "$STU_TARGET"
check "F42B §2 Pinned section (golden, separated)" "showPinnedSeparately" "$STU_TARGET"
check "F42B §3.2 Unread indicator dot" "!n.isRead &&" "$STU_TARGET"
check "F42B §3.3 Urgent pulsing animation" "urgentPulseF42" "$STU_TARGET"
check "F42B §3.4 Image banner rendering" "n.imageUrl && <img" "$STU_TARGET"
check "F42B §3.5 Bilingual rendering (titleHi/messageHi)" "lang === 'hi' && n.titleHi" "$STU_TARGET"
check "F42B §3.6 Safe rich-text renderer (no raw HTML injection)" "function RichText" "$STU_TARGET"
check "F42B §3.7 Relative time (\"2 hours ago\")" "function relTime" "$STU_TARGET"
check "F42B §3.8 Expand/collapse long messages" "Read more" "$STU_TARGET"
check "F42B §3.9 Expiry auto-filter" "expiryDate" "$STU_TARGET"
check "F42B §4.1 Click to mark read" "const clickCard" "$STU_TARGET"
check "F42B §5.1 Skeleton loading cards" "function SkeletonCard" "$STU_TARGET"
check "F42B §5.2/5.3 Empty states" "No announcements yet" "$STU_TARGET"
check "F42B §6.1 Push notification (Notification API)" "new Notification(" "$STU_TARGET"
check "F42B §6.3 Mark all as read button" "markAllRead" "$STU_TARGET"
check "F42B §6.4 Add to Calendar (exam type)" "addToCalendar" "$STU_TARGET"
check "F42B §6.5 Acknowledge / Got it button" "const ack =" "$STU_TARGET"
check "F42B §6.6 Link preview" "function extractUrl" "$STU_TARGET"

# ── Admin panel checks ──
ADM_TARGET=""
for candidate in \
  "/root/workspace/frontend/app/admin/x7k2p/page.tsx" \
  "/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"; do
  if [ -f "$candidate" ]; then ADM_TARGET="$candidate"; break; fi
done
if [ -n "$ADM_TARGET" ]; then
  check "F42A §1.1 Stats bar (4 tiles)" "Avg. Read Rate" "$ADM_TARGET"
  check "F42A §2.1.1 Type/category pills (colored)" "annCategory" "$ADM_TARGET"
  check "F42A §1.2.2 Audience mode (all/batch/testseries/students)" "annAudMode" "$ADM_TARGET"
  check "F42A §2.1.9 Multi-select batches (checkboxes)" "annSelBatches" "$ADM_TARGET"
  check "F42A §1.2.2.1 Specific Students smart search" "annStudentQ" "$ADM_TARGET"
  check "F42A §2.1.7 Bilingual EN/HI compose fields" "annTitleHi" "$ADM_TARGET"
  check "F42A §2.1.6 Image URL attach" "annImageUrl" "$ADM_TARGET"
  check "F42A §2.1.2 Pin toggle" "annPinned" "$ADM_TARGET"
  check "F42A §2.1.3 Schedule for later toggle" "annScheduleMode" "$ADM_TARGET"
  check "F42A §2.1.8 Expiry date (auto-hide after X days)" "annExpiryDays" "$ADM_TARGET"
  check "F42A §2.1.4 Preview modal" "STUDENT-SIDE PREVIEW" "$ADM_TARGET"
  check "F42A §2.2.1 Sent history list" "loadAnnHistory" "$ADM_TARGET"
  check "F42A §2.2.2 Read receipt stats modal" "annOpenReadStats" "$ADM_TARGET"
  check "F42A §2.2.3 Search/filter past announcements" "annSearchQ" "$ADM_TARGET"
  check "F42A §2.2.4 Resend / Duplicate" "annResend" "$ADM_TARGET"
  check "F42A §2.2.5 Draft save" "sendAnn2(true)" "$ADM_TARGET"
  check "F42A §2.4.1 Templates quick-fill" "annApplyTemplate" "$ADM_TARGET"
else
  echo "❌ Admin page.tsx not found — could not verify F42A checks"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo " RESULT: $PASS passed / $((PASS+FAIL)) total"
if [ "$FAIL" -eq 0 ]; then echo " 🎉 ALL F42 FRONTEND FEATURES SUCCESSFULLY IMPLEMENTED ✅"; else echo " ⚠️  $FAIL item(s) need review."; fi
echo "════════════════════════════════════════════════════════"

echo "👉 Make sure you also ran f42_backend_fix.sh on the backend."
echo "👉 Restart your frontend (Replit Run button) to see changes."
