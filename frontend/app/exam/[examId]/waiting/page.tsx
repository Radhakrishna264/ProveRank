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
