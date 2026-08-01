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
  const [chatReminderShown, setChatReminderShown] = useState(false)
  const [broadcasts, setBroadcasts] = useState<any[]>([])
  const [activityLog, setActivityLog] = useState<string[]>([])
  const socketRef = useRef<any>(null)
  const transitionedRef = useRef(false)
  const audioCtxRef = useRef<any>(null)
  const audioNodesRef = useRef<any>(null)

  const toggleMusic = () => {
    if (musicOn) {
      try { audioNodesRef.current?.osc1?.stop(); audioNodesRef.current?.osc2?.stop(); audioCtxRef.current?.close() } catch (e) {}
      audioCtxRef.current = null; audioNodesRef.current = null
      setMusicOn(false)
      return
    }
    try {
      const AC = (window as any).AudioContext || (window as any).webkitAudioContext
      const ctx = new AC()
      const gain = ctx.createGain(); gain.gain.value = 0.035; gain.connect(ctx.destination)
      const osc1 = ctx.createOscillator(); osc1.type = 'sine'; osc1.frequency.value = 220
      const osc2 = ctx.createOscillator(); osc2.type = 'sine'; osc2.frequency.value = 330
      osc1.connect(gain); osc2.connect(gain)
      osc1.start(); osc2.start()
      audioCtxRef.current = ctx; audioNodesRef.current = { osc1, osc2 }
      setMusicOn(true)
    } catch (e) { /* Web Audio not available — no-op */ }
  }
  useEffect(() => () => { try { audioNodesRef.current?.osc1?.stop(); audioNodesRef.current?.osc2?.stop(); audioCtxRef.current?.close() } catch (e) {} }, [])

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
  const loadBroadcasts = () => {
    if (!token) return
    fetch(`${API}/api/exams/${examId}/broadcasts`, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => { if (d?.success) setBroadcasts(d.broadcasts || []) })
      .catch(() => {})
  }
  useEffect(() => { loadInfo(); loadBroadcasts() }, [examId, token])

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
    const poll = setInterval(() => { loadInfo(); loadBroadcasts() }, 15000)
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
      else if (left <= 2 && left > 0 && !chatReminderShown) { setChatReminderShown(true); logActivity(t('Chat closing soon', 'Chat jaldi band hoga')) }
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
    <div style={{ padding: 16 }} className="pr-wr-wrap">
      <style>{`.pr-wr-wrap{max-width:640px;margin:0 auto} @media(min-width:900px){.pr-wr-wrap{max-width:980px;display:grid;grid-template-columns:1fr 300px;gap:20px;align-items:start}}`}</style>
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
            <div style={{ fontSize: 28, animation: 'pr-float 2s ease-in-out infinite' }}>⏳</div>
            <style>{`@keyframes pr-float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-6px)} }`}</style>
            <div style={{ fontSize: 48, fontWeight: 900, color: secsLeft != null && secsLeft < 120 ? C.danger : C.gold, margin: '4px 0 6px' }}>
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

            <button onClick={toggleMusic} style={{ background: 'transparent', border: `1px solid ${border}`, color: sub, borderRadius: 20, padding: '4px 12px', fontSize: 12, cursor: 'pointer', marginBottom: 14 }}>
              {musicOn ? '🔊' : '🔇'} {t('Background Music', 'Background Music')}
            </button>

            <div style={{ textAlign: 'left', background: theme.chipBg, borderRadius: 10, padding: 10, maxHeight: 160, overflowY: 'auto', marginBottom: 8 }}>
              {chatMsgs.length === 0 ? <div style={{ color: sub, fontSize: 12 }}>{t('No messages yet', 'Abhi koi message nahi')}</div> :
                chatMsgs.map((m, i) => <div key={i} style={{ fontSize: 12, color: text, marginBottom: 4 }}><b>{m.name}:</b> {m.text}</div>)}
            </div>
            {chatOpen && chatMinsLeft != null && chatMinsLeft <= 2 && (
              <div style={{ background: '#3a2a00', border: '1px solid #f2b134', borderRadius: 8, padding: '8px 10px', marginBottom: 8, fontSize: 12, color: '#f2d38a', textAlign: 'left' }}>
                ⏰ {t('Chat will close in', 'Chat band ho jayega')} {Math.ceil(chatMinsLeft)} {t('min for anti-cheat', 'min me anti-cheat ke liye')}
              </div>
            )}
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

      <div style={{ background: card, border: `1px solid ${border}`, borderRadius: 18, padding: 18, marginTop: 16 }}>
        <div style={{ fontSize: 13, fontWeight: 800, color: text, marginBottom: 10 }}>{t('Exam Details', 'Exam Details')}</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, fontSize: 12, color: sub }}>
          <div>⏱ {t('Duration', 'Duration')}: <b style={{ color: text }}>{info.exam.duration} min</b></div>
          <div>🎯 {t('Marks', 'Marks')}: <b style={{ color: text }}>{info.exam.totalMarks}</b></div>
          <div>❓ {t('Questions', 'Questions')}: <b style={{ color: text }}>{info.exam.totalQuestions}</b></div>
          <div>👥 {t('Live in room', 'Live in room')}: <b style={{ color: C.gold }}>{liveCount}</b></div>
        </div>
        {broadcasts.length > 0 && (
          <div style={{ marginTop: 12 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: text, marginBottom: 6 }}>📢 {t('Broadcasts', 'Broadcasts')}</div>
            {broadcasts.slice(0, 3).map((b, i) => (
              <div key={i} style={{ fontSize: 11, color: sub, marginBottom: 4 }}>{b.message || b.text}</div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default function WaitingRoomPage() {
  return <StudentShell pageKey="my-exams"><WaitingRoomContent /></StudentShell>
}
