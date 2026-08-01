'use client'
import { useState, useEffect, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'

// F56 §1.5/§2.6-2.9 — real face detection via TensorFlow.js Blazeface,
// loaded on-demand from CDN (no package.json change needed). Previously
// faceOk was hardcoded `true` and multiFace was never set — both fake.
const TF_URL = 'https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.20.0/dist/tf.min.js'
const BLAZEFACE_URL = 'https://cdn.jsdelivr.net/npm/@tensorflow-models/blazeface@0.1.0/dist/blazeface.min.js'

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) { resolve(); return }
    const s = document.createElement('script')
    s.src = src; s.async = true
    s.onload = () => resolve()
    s.onerror = () => reject(new Error('script load failed: ' + src))
    document.body.appendChild(s)
  })
}

function WebcamCheckContent() {
  const { examId } = useParams() as any
  const router = useRouter()
  const shell = useShell() as any
  const token = shell?.token
  const lang = shell?.lang || 'en'
  const theme = shell?.theme || {}
  const t = (en: string, hi: string) => (lang === 'hi' ? hi : en)

  const text = theme.text, sub = theme.sub, border = theme.border
  const card = theme.isDark ? C.card : C.cardL

  const videoRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const audioStreamRef = useRef<MediaStream | null>(null)
  const modelRef = useRef<any>(null)
  const detectTimerRef = useRef<any>(null)

  const [status, setStatus] = useState<'idle' | 'requesting' | 'live' | 'denied' | 'error'>('idle')
  const [failureReason, setFailureReason] = useState('')
  const [faceOk, setFaceOk] = useState<boolean | null>(null)
  const [noFace, setNoFace] = useState(false)
  const [multiFace, setMultiFace] = useState(false)
  const [lightingOk, setLightingOk] = useState<boolean | null>(null)
  const [vbgSuspicious, setVbgSuspicious] = useState(false)
  const [modelReady, setModelReady] = useState(false)
  const [modelLoadFailed, setModelLoadFailed] = useState(false)
  const [audioOn, setAudioOn] = useState(false)
  const [devices, setDevices] = useState<MediaDeviceInfo[]>([])
  const [selectedDeviceId, setSelectedDeviceId] = useState<string>('')
  const [historyLog, setHistoryLog] = useState<{ at: string; event: string }[]>([])
  const [compactMode, setCompactMode] = useState(false)

  const logHistory = (event: string) => setHistoryLog(h => [{ at: new Date().toLocaleTimeString(), event }, ...h].slice(0, 10))

  // Load TF.js + Blazeface model once, in background — camera works even if this is still loading/fails
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        await loadScript(TF_URL)
        await loadScript(BLAZEFACE_URL)
        const bf = (window as any).blazeface
        if (!bf) throw new Error('blazeface not on window')
        const model = await bf.load()
        if (cancelled) return
        modelRef.current = model
        setModelReady(true)
        logHistory(t('Face detection model loaded', 'Face detection model load ho gaya'))
      } catch (e) {
        if (cancelled) return
        setModelLoadFailed(true)
        logHistory(t('Face detection model failed to load — camera still works', 'Face detection model load nahi hua — camera phir bhi kaam karega'))
      }
    })()
    return () => { cancelled = true }
  }, [])

  useEffect(() => {
    navigator.mediaDevices?.enumerateDevices?.().then(list => {
      setDevices(list.filter(d => d.kind === 'videoinput'))
    }).catch(() => {})
  }, [])

  const requestCamera = async (deviceId?: string) => {
    setStatus('requesting'); setFailureReason('')
    try {
      const constraints: MediaStreamConstraints = {
        video: deviceId ? { deviceId: { exact: deviceId }, width: 480, height: 360 } : { width: 480, height: 360 }
      }
      const stream = await navigator.mediaDevices.getUserMedia(constraints)
      streamRef.current = stream
      if (videoRef.current) videoRef.current.srcObject = stream
      setStatus('live')
      logHistory(t('Camera permission granted', 'Camera permission mil gayi'))
      setTimeout(() => checkLighting(), 800)
    } catch (err: any) {
      setStatus('denied')
      const reason = err?.name === 'NotAllowedError' ? t('Permission denied by user/browser', 'User/browser ne permission deny ki')
        : err?.name === 'NotFoundError' ? t('No camera device found', 'Koi camera device nahi mila')
        : t('Unknown camera error', 'Unknown camera error')
      setFailureReason(reason)
      logHistory(t('Camera permission denied — ', 'Camera permission denied — ') + reason)
    }
  }

  // F56 §1.8 — optional audio permission (separate from compulsory camera)
  const requestAudio = async () => {
    try {
      const s = await navigator.mediaDevices.getUserMedia({ audio: true })
      audioStreamRef.current = s
      setAudioOn(true)
      logHistory(t('Optional mic permission granted', 'Optional mic permission mil gayi'))
    } catch (e) {
      logHistory(t('Mic permission skipped/denied', 'Mic permission skip/deny hui'))
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

  // F56 §1.6 — lightweight heuristic virtual-background check: sample a strip
  // of pixels away from the detected face box; an unnaturally flat/uniform
  // background (very low pixel variance) is flagged as suspicious. This is a
  // heuristic signal, not a certified anti-spoofing verdict.
  const checkVirtualBackground = (faceBox: number[] | null) => {
    try {
      const video = videoRef.current
      if (!video) return
      const canvas = document.createElement('canvas')
      canvas.width = 80; canvas.height = 60
      const ctx = canvas.getContext('2d')
      if (!ctx) return
      ctx.drawImage(video, 0, 0, 80, 60)
      const data = ctx.getImageData(0, 0, 80, 60).data
      // sample the top strip (usually background, above a centered face)
      let sum = 0, sumSq = 0, n = 0
      for (let y = 0; y < 12; y++) {
        for (let x = 0; x < 80; x++) {
          const i = (y * 80 + x) * 4
          const lum = (data[i] + data[i + 1] + data[i + 2]) / 3
          sum += lum; sumSq += lum * lum; n++
        }
      }
      const mean = sum / n
      const variance = sumSq / n - mean * mean
      setVbgSuspicious(variance < 4) // near-flat single-color band = suspicious
    } catch (e) {}
  }

  // Real detection loop — replaces the old hardcoded setFaceOk(true)
  useEffect(() => {
    if (status !== 'live' || !modelReady) return
    detectTimerRef.current = setInterval(async () => {
      try {
        const model = modelRef.current
        const video = videoRef.current
        if (!model || !video) return
        const predictions = await model.estimateFaces(video, false)
        const count = predictions?.length || 0
        setFaceOk(count === 1)
        setNoFace(count === 0)
        setMultiFace(count > 1)
        if (count === 1) checkVirtualBackground(predictions[0]?.topLeft || null)
      } catch (e) {}
    }, 1200)
    return () => clearInterval(detectTimerRef.current)
  }, [status, modelReady])

  // Fallback: if the model failed to load, don't fake success — mark as "unverified" (null) not "confirmed"
  useEffect(() => {
    if (status === 'live' && modelLoadFailed) {
      setFaceOk(null)
      logHistory(t('Face check unavailable — proceeding on camera-live signal only', 'Face check available nahi — sirf camera-live signal use ho raha hai'))
    }
  }, [status, modelLoadFailed])

  useEffect(() => () => {
    streamRef.current?.getTracks().forEach(tr => tr.stop())
    audioStreamRef.current?.getTracks().forEach(tr => tr.stop())
    if (detectTimerRef.current) clearInterval(detectTimerRef.current)
  }, [])

  const readinessScore = [status === 'live', faceOk === true, lightingOk !== false, !multiFace, !vbgSuspicious].filter(Boolean).length
  const cameraHealthLabel = readinessScore >= 5 ? t('Excellent', 'Excellent') : readinessScore >= 3 ? t('Fair', 'Theek-thaak') : t('Poor', 'Kharab')

  // F56 §1.3 — exam stays blocked while there's a real problem: no face / multiple faces.
  // (Lighting/VBG remain warnings, not hard blocks, to avoid false-positive lockouts.)
  const canStart = status === 'live' && !multiFace && !noFace

  const proceedToExam = () => {
    if (!canStart) return
    streamRef.current?.getTracks().forEach(tr => tr.stop())
    audioStreamRef.current?.getTracks().forEach(tr => tr.stop())
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

        {devices.length > 1 && status !== 'live' && (
          <select value={selectedDeviceId} onChange={e => setSelectedDeviceId(e.target.value)} style={{ width: '100%', padding: 8, borderRadius: 8, border: `1px solid ${border}`, background: 'transparent', color: text, marginBottom: 10, fontSize: 12 }}>
            <option value="">{t('Default Camera', 'Default Camera')}</option>
            {devices.map(d => <option key={d.deviceId} value={d.deviceId}>{d.label || t('Camera', 'Camera')}</option>)}
          </select>
        )}

        <div style={{ position: 'relative', background: '#000', borderRadius: 14, overflow: 'hidden', aspectRatio: compactMode ? '16/9' : '4/3', maxHeight: compactMode ? 180 : 360 }}>
          <video ref={videoRef} autoPlay playsInline muted style={{ width: '100%', height: '100%', objectFit: 'cover', transform: 'scaleX(-1)' }} />
          {status === 'live' && <span style={{ position: 'absolute', top: 8, left: 8, fontSize: 10, fontWeight: 800, color: '#fff', background: '#e53935', padding: '3px 8px', borderRadius: 20 }}>🔴 LIVE</span>}
          {status !== 'live' && (
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#888' }}>{t('Camera preview', 'Camera preview')}</div>
          )}
        </div>

        {status === 'live' && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 12 }}>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: readinessScore >= 3 ? '#123b1e' : '#3a1414', color: readinessScore >= 3 ? '#7CFC9C' : '#ff8080' }}>✅ {t('Camera Health', 'Camera Health')}: {cameraHealthLabel}</span>
            {!modelReady && !modelLoadFailed && <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: '#2a2a3a', color: '#b0b0ff' }}>⏳ {t('Loading face check...', 'Face check load ho raha...')}</span>}
            {modelReady && (
              <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: faceOk ? '#123b1e' : '#3a1414', color: faceOk ? '#7CFC9C' : '#ff8080' }}>
                {faceOk ? '✅' : noFace ? '❌' : '⚠️'} {noFace ? t('No Face Detected', 'Face Detect Nahi Hua') : multiFace ? t('Multiple Faces!', 'Multiple Faces!') : t('Face Visible', 'Face Visible')}
              </span>
            )}
            {modelLoadFailed && <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: '#3a2a00', color: '#f2d38a' }}>⚠️ {t('Face check unavailable', 'Face check unavailable')}</span>}
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: lightingOk === false ? '#3a2a00' : '#123b1e', color: lightingOk === false ? '#f2d38a' : '#7CFC9C' }}>{lightingOk === false ? '⚠️' : '✅'} {t('Lighting', 'Lighting')}</span>
            <span style={{ fontSize: 11, padding: '4px 10px', borderRadius: 20, background: vbgSuspicious ? '#3a2a00' : '#123b1e', color: vbgSuspicious ? '#f2d38a' : '#7CFC9C' }}>{vbgSuspicious ? '⚠️' : '✅'} {t('Background Check', 'Background Check')}</span>
          </div>
        )}

        {status === 'live' && multiFace && (
          <div style={{ background: '#3a1414', borderRadius: 10, padding: 10, marginTop: 10, fontSize: 12, color: '#ff8080' }}>
            🚫 {t('Multiple faces detected — only you should be in frame. Exam cannot start until this is resolved.', 'Multiple faces detect hui — sirf aap frame me hone chahiye. Ye theek hue bina exam shuru nahi hoga.')}
          </div>
        )}
        {status === 'live' && noFace && !multiFace && (
          <div style={{ background: '#3a2a00', borderRadius: 10, padding: 10, marginTop: 10, fontSize: 12, color: '#f2d38a' }}>
            ⚠️ {t('No face detected — please face the camera clearly.', 'Face detect nahi hua — camera ki taraf saaf dekho.')}
          </div>
        )}
        {status === 'live' && vbgSuspicious && (
          <div style={{ background: '#3a2a00', borderRadius: 10, padding: 10, marginTop: 10, fontSize: 12, color: '#f2d38a' }}>
            ⚠️ {t('Background looks unusually uniform — please sit in a real, plain room (virtual backgrounds are not allowed).', 'Background asamanya roop se flat lag raha hai — real room me baitho (virtual background allowed nahi hai).')}
          </div>
        )}

        {status === 'live' && !audioOn && (
          <button onClick={requestAudio} style={{ marginTop: 10, fontSize: 11, padding: '6px 12px', borderRadius: 20, border: `1px solid ${border}`, background: 'transparent', color: sub, cursor: 'pointer' }}>
            🎙️ {t('Enable Optional Mic Monitoring', 'Optional Mic Monitoring On Karo')}
          </button>
        )}

        {status === 'denied' && (
          <div style={{ background: '#3a1414', borderRadius: 10, padding: 12, marginTop: 12 }}>
            <div style={{ color: '#ff8080', fontWeight: 700, fontSize: 13 }}>❌ {t('Camera Permission Denied', 'Camera Permission Denied')}</div>
            <div style={{ color: '#f2b8b8', fontSize: 12, marginTop: 4 }}>{t('Reason', 'Reason')}: {failureReason}</div>
            <button onClick={() => requestCamera(selectedDeviceId || undefined)} style={{ marginTop: 10, padding: '8px 16px', borderRadius: 8, border: 'none', background: C.gold, color: '#000', fontWeight: 700, cursor: 'pointer' }}>🔄 {t('Retry Camera Permission', 'Camera Permission Dobara Try Karo')}</button>
          </div>
        )}

        {status === 'idle' && (
          <button onClick={() => requestCamera(selectedDeviceId || undefined)} style={{ width: '100%', marginTop: 16, padding: 14, borderRadius: 12, border: 'none', background: C.gold, color: '#000', fontWeight: 800, cursor: 'pointer' }}>
            📷 {t('Allow Camera & Start Exam', 'Camera Allow Karo & Exam Shuru Karo')}
          </button>
        )}
        {status === 'live' && (
          <button onClick={proceedToExam} disabled={!canStart} style={{ width: '100%', marginTop: 16, padding: 14, borderRadius: 12, border: 'none', background: canStart ? `linear-gradient(90deg, ${theme.primary}, ${C.gold})` : '#444', color: '#fff', fontWeight: 800, cursor: canStart ? 'pointer' : 'not-allowed' }}>
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
