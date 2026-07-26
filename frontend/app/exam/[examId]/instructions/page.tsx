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
