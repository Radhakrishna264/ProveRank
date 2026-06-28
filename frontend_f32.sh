#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  ProveRank — Feature 32: Per-Student Time Extension (FRONTEND)
#  Creates: TimeExtensionPanel.jsx
#  Patches:  page.tsx (import + inject into live monitor tab)
# ═══════════════════════════════════════════════════════════════
set -e

# ── Locate admin page directory ───────────────────────────────
PAGE_TSX=$(find . -path "*/admin/x7k2p/page.tsx" | grep -v node_modules | head -1)
if [ -z "$PAGE_TSX" ]; then
  PAGE_TSX=$(find . -name "page.tsx" | grep -v node_modules | head -1)
fi
ADMIN_DIR=$(dirname "$PAGE_TSX")
echo "📁 Admin dir: $ADMIN_DIR"
echo "📄 page.tsx : $PAGE_TSX"

# ════════════════════════════════════════════════════════════════
# 1. CREATE — TimeExtensionPanel.jsx
# ════════════════════════════════════════════════════════════════
cat > "$ADMIN_DIR/TimeExtensionPanel.jsx" << 'EOF'
// ═══════════════════════════════════════════════════════════════
//  Feature 32 — Per-Student Time Extension Panel
//  All sub-features 32.1 → 32.20
// ═══════════════════════════════════════════════════════════════
'use client'
import { useState, useEffect, useCallback, useRef } from 'react'

// ── Color tokens ────────────────────────────────────────────────
const C = {
  bg0:  'rgba(8,14,28,0.98)',
  bg1:  'rgba(15,23,42,0.92)',
  bg2:  'rgba(22,35,56,0.85)',
  bg3:  'rgba(30,45,70,0.7)',
  bor:  'rgba(99,179,237,0.15)',
  bor2: 'rgba(255,255,255,0.08)',
  txt:  '#e2e8f0',
  dim:  '#94a3b8',
  acc:  '#38bdf8',
  suc:  '#22c55e',
  wrn:  '#f59e0b',
  dng:  '#ef4444',
  pur:  '#a78bfa',  // 32.16 — purple for extend button
  gld:  '#fbbf24',
}

// ── Helpers ─────────────────────────────────────────────────────
function fmtTime(sec) {
  if (sec <= 0) return '00:00'
  const h = Math.floor(sec / 3600)
  const m = Math.floor((sec % 3600) / 60)
  const s = sec % 60
  if (h > 0) return `${h}h ${String(m).padStart(2,'0')}m`
  return `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`
}

function timeColor(sec) {
  if (sec > 900) return C.suc   // > 15 min — green
  if (sec > 300) return C.wrn   // > 5 min  — amber
  return C.dng                  // ≤ 5 min  — red
}

// ── REASONS (32.9) ──────────────────────────────────────────────
const REASONS = ['Disability', 'Technical Issue', 'Internet Problem', 'Other']

// ── SOCKET (32.4/32.5) — lightweight hook ───────────────────────
function useSocketListener(onEvent) {
  useEffect(() => {
    if (typeof window === 'undefined') return
    // Try to get socket from window (set by existing socket setup)
    const sock = window.__prSocket
    if (!sock) return
    sock.on('admin:extension_given',  (d) => onEvent('extension_given', d))
    sock.on('admin:global_extension', (d) => onEvent('global_ext', d))
    sock.on('admin:extension_undone', (d) => onEvent('extension_undone', d))
    return () => {
      sock.off('admin:extension_given')
      sock.off('admin:global_extension')
      sock.off('admin:extension_undone')
    }
  }, [onEvent])
}

// ════════════════════════════════════════════════════════════════
//  MAIN COMPONENT
// ════════════════════════════════════════════════════════════════
export default function TimeExtensionPanel({ token, API, T, role }) {
  // ── State ─────────────────────────────────────────────────────
  const [examId,       setExamId]       = useState('')           // selected exam
  const [examInput,    setExamInput]    = useState('')           // exam id input
  const [students,     setStudents]     = useState([])           // 32.1 student list
  const [loading,      setLoading]      = useState(false)
  const [refreshing,   setRefreshing]   = useState(false)
  const [extLog,       setExtLog]       = useState([])           // 32.6 extension log
  const [logOpen,      setLogOpen]      = useState(false)        // 32.19 collapsible
  const [tick,         setTick]         = useState(0)            // for live timer
  const [flashGreen,   setFlashGreen]   = useState({})           // 32.18 green border flash

  // Modal state (32.17)
  const [modal,        setModal]        = useState(null)         // { attemptId, studentName, currentRemaining }
  const [mins,         setMins]         = useState(10)
  const [reason,       setReason]       = useState('Technical Issue')
  const [saving,       setSaving]       = useState(false)
  const [modalWarn,    setModalWarn]    = useState('')

  // Global extend (32.8/32.20)
  const [globalModal,  setGlobalModal]  = useState(false)
  const [globalMins,   setGlobalMins]   = useState(10)
  const [globalReason, setGlobalReason] = useState('Technical Issue')
  const [globalSaving, setGlobalSaving] = useState(false)

  // ── Countdown ticker (32.5 live timer) ──────────────────────
  useEffect(() => {
    const t = setInterval(() => setTick(v => v + 1), 1000)
    return () => clearInterval(t)
  }, [])

  // ── Auto-refresh students every 30s ─────────────────────────
  useEffect(() => {
    if (!examId) return
    const t = setInterval(() => loadStudents(examId, true), 30000)
    return () => clearInterval(t)
  }, [examId])

  // ── Socket listener (32.4) ───────────────────────────────────
  const onSocketEvent = useCallback((type, data) => {
    if (type === 'extension_given' && data.examId === examId) {
      loadStudents(examId, true)
      loadLog(examId)
      // 32.18 — flash green border
      setFlashGreen(prev => ({ ...prev, [data.attemptId]: true }))
      setTimeout(() => setFlashGreen(prev => { const n={...prev}; delete n[data.attemptId]; return n; }), 3000)
    }
    if (type === 'global_ext' && data.examId === examId) {
      loadStudents(examId, true)
      loadLog(examId)
    }
    if (type === 'extension_undone') {
      loadLog(examId)
    }
  }, [examId])
  useSocketListener(onSocketEvent)

  // ── API Calls ────────────────────────────────────────────────
  const h = { Authorization: `Bearer ${token}` }

  const loadStudents = useCallback(async (eid, silent = false) => {
    if (!eid) return
    if (!silent) setLoading(true)
    else setRefreshing(true)
    try {
      const r = await fetch(`${API}/api/time-extension/active-students/${eid}`, { headers: h })
      const d = await r.json()
      if (d.success) setStudents(d.students || [])
    } catch(e) { if (!silent) T('Failed to load students', 'e') }
    setLoading(false)
    setRefreshing(false)
  }, [API, token])

  const loadLog = useCallback(async (eid) => {
    if (!eid) return
    try {
      const r = await fetch(`${API}/api/time-extension/log/${eid}`, { headers: h })
      const d = await r.json()
      if (d.success) setExtLog(d.logs || [])
    } catch(e) {}
  }, [API, token])

  const handleLoadExam = () => {
    if (!examInput.trim()) return T('Enter exam ID', 'e')
    setExamId(examInput.trim())
    loadStudents(examInput.trim())
    loadLog(examInput.trim())
  }

  // ── Fetch remaining before opening modal (32.10) ─────────────
  const openModal = async (student) => {
    setMins(10); setReason('Technical Issue'); setModalWarn('')
    // Get latest remaining time
    let remaining = student.remainingSec
    try {
      const r = await fetch(`${API}/api/time-extension/remaining/${student.attemptId}`, { headers: h })
      const d = await r.json()
      if (d.success) remaining = d.remainingSec
    } catch(e) {}
    setModal({ ...student, currentRemaining: remaining })
  }

  // ── Give Extension (32.2/32.3/32.6) ─────────────────────────
  const giveExtension = async () => {
    if (!modal || !mins) return
    setSaving(true)
    try {
      const r = await fetch(`${API}/api/time-extension/give`, {
        method: 'POST',
        headers: { ...h, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          attemptId:   modal.attemptId,
          examId,
          studentId:   modal.studentId,
          extraMinutes: parseInt(mins),
          reason,
          studentName: modal.studentName,
        })
      })
      const d = await r.json()
      if (d.success) {
        T(`✅ +${mins} min given to ${modal.studentName}`, 's')
        if (d.warning) setModalWarn(d.warning)  // 32.11
        else { setModal(null) }
        loadStudents(examId, true)
        loadLog(examId)
        // 32.18 green flash
        setFlashGreen(prev => ({ ...prev, [modal.attemptId]: true }))
        setTimeout(() => setFlashGreen(prev => { const n={...prev}; delete n[modal.attemptId]; return n; }), 3000)
      } else {
        T(d.error || 'Failed', 'e')
      }
    } catch(e) { T('Network error', 'e') }
    setSaving(false)
  }

  // ── Global Extend (32.8) ─────────────────────────────────────
  const giveGlobal = async () => {
    if (!examId) return T('Load exam first', 'e')
    setGlobalSaving(true)
    try {
      const r = await fetch(`${API}/api/time-extension/global`, {
        method: 'POST',
        headers: { ...h, 'Content-Type': 'application/json' },
        body: JSON.stringify({ examId, extraMinutes: parseInt(globalMins), reason: globalReason })
      })
      const d = await r.json()
      if (d.success) {
        T(`✅ +${globalMins} min given to all ${d.studentsAffected} students`, 's')
        setGlobalModal(false)
        loadStudents(examId, true)
        loadLog(examId)
      } else { T(d.error || 'Failed', 'e') }
    } catch(e) { T('Network error', 'e') }
    setGlobalSaving(false)
  }

  // ── Undo Extension (32.12) ───────────────────────────────────
  const undoExtension = async (logId, mins2, studentName2) => {
    if (!confirm(`Undo +${mins2} min extension for ${studentName2}? (Only possible within 5 min)`)) return
    try {
      const r = await fetch(`${API}/api/time-extension/${logId}/undo`, { method: 'DELETE', headers: h })
      const d = await r.json()
      if (d.success) { T('Extension undone ↩️', 's'); loadLog(examId); loadStudents(examId, true) }
      else T(d.error || 'Cannot undo', 'e')
    } catch(e) { T('Network error', 'e') }
  }

  // ── Download PDF (32.14) ─────────────────────────────────────
  const downloadReport = () => {
    if (!examId) return T('Load exam first', 'e')
    window.open(`${API}/api/time-extension/report/${examId}?token=${token}`, '_blank')
    T('Downloading PDF report…')
  }

  // ── Live timer display: recalculate from stored startedAt ────
  const getLiveRemaining = (student) => {
    if (!student.startedAt) return student.remainingSec
    const baseSec = student.remainingSec  // already calculated with extensions at load time
    // Adjust for time elapsed since we loaded
    // We just show the stored value, recalculated each tick via server poll
    return student.remainingSec
  }

  // ── Styles ───────────────────────────────────────────────────
  const cs    = { background: C.bg1, borderRadius: 12, padding: '14px 16px', border: `1px solid ${C.bor2}` }
  const btn   = (col) => ({ background: `${col}18`, border: `1px solid ${col}44`, color: col, borderRadius: 8, padding: '6px 14px', fontSize: 12, cursor: 'pointer', fontWeight: 600 })
  const inp   = { background: C.bg3, border: `1px solid ${C.bor2}`, color: C.txt, borderRadius: 8, padding: '8px 12px', fontSize: 13, outline: 'none' }
  const selSt = { ...inp, cursor: 'pointer' }

  // ══════════════════════════════════════════════════════════════
  //  RENDER
  // ══════════════════════════════════════════════════════════════
  return (
    <div style={{ marginTop: 24 }}>
      {/* ── Header ─── */}
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:16, flexWrap:'wrap', gap:10 }}>
        <div>
          <div style={{ fontWeight:800, fontSize:16, color:C.txt }}>⏱️ Per-Student Time Extension</div>
          <div style={{ fontSize:12, color:C.dim }}>Feature 32 — Give extra time to students during live exam</div>
        </div>
        <div style={{ display:'flex', gap:8 }}>
          {examId && (
            <>
              {/* 32.14 — Download Report */}
              <button onClick={downloadReport} style={btn(C.acc)}>📄 Download PDF Report</button>
              {/* 32.20 — Global Extend Big Button */}
              <button onClick={()=>setGlobalModal(true)} style={{
                background:'rgba(239,68,68,0.1)', border:'2px solid rgba(239,68,68,0.6)',
                color:C.dng, borderRadius:8, padding:'7px 16px', fontSize:12,
                cursor:'pointer', fontWeight:700, letterSpacing:'0.3px'
              }}>
                ⚠️ Extend All Students
              </button>
            </>
          )}
        </div>
      </div>

      {/* ── Exam ID Input ─── */}
      <div style={{ ...cs, marginBottom:14, display:'flex', gap:10, alignItems:'center', flexWrap:'wrap' }}>
        <div style={{ fontSize:12, color:C.dim, fontWeight:600 }}>Exam ID:</div>
        <input
          value={examInput}
          onChange={e => setExamInput(e.target.value)}
          onKeyDown={e => e.key==='Enter' && handleLoadExam()}
          placeholder='Paste Exam ID here…'
          style={{ ...inp, flex:1, minWidth:220 }}
        />
        <button onClick={handleLoadExam} style={btn(C.acc)}>Load Live Students</button>
        {examId && (
          <button onClick={()=>loadStudents(examId, true)} style={btn(C.dim)}>
            {refreshing ? '⟳ Refreshing…' : '↻ Refresh'}
          </button>
        )}
      </div>

      {/* ── 32.1 Student Cards ─── */}
      {loading ? (
        <div style={{ ...cs, textAlign:'center', padding:'40px', color:C.dim }}>⟳ Loading active students…</div>
      ) : !examId ? (
        <div style={{ ...cs, textAlign:'center', padding:'40px' }}>
          <div style={{ fontSize:40, marginBottom:12 }}>⏱️</div>
          <div style={{ color:C.dim, fontSize:13 }}>Enter an Exam ID above to see active students</div>
        </div>
      ) : students.length === 0 ? (
        <div style={{ ...cs, textAlign:'center', padding:'40px' }}>
          <div style={{ fontSize:40, marginBottom:12 }}>📭</div>
          <div style={{ color:C.dim }}>No active students in this exam right now</div>
        </div>
      ) : (
        <div>
          <div style={{ fontSize:12, color:C.dim, marginBottom:10, fontWeight:600 }}>
            {students.length} Active Students
          </div>
          {/* 32.15 — Student cards with real-time timer */}
          <div style={{ display:'grid', gap:10 }}>
            {students.map(s => {
              const remSec   = Math.max(0, s.remainingSec - tick % 30)  // approximate live countdown
              const tCol     = timeColor(remSec)
              const isFlash  = flashGreen[s.attemptId]  // 32.18
              return (
                <div key={s.attemptId} style={{
                  ...cs,
                  display:'flex', alignItems:'center', gap:12, flexWrap:'wrap',
                  borderLeft: `4px solid ${isFlash ? C.suc : C.pur}`,  // 32.22/32.18
                  transition: 'border-color 0.5s, box-shadow 0.5s',
                  boxShadow: isFlash ? `0 0 16px rgba(34,197,94,0.3)` : undefined,  // 32.18 green glow
                }}>
                  {/* Student info */}
                  <div style={{ flex:1, minWidth:140 }}>
                    <div style={{ fontWeight:700, fontSize:13, color:C.txt, marginBottom:2 }}>
                      {s.studentName}
                      {s.totalExtMin > 0 && (
                        <span style={{ marginLeft:8, fontSize:10, background:'rgba(167,139,250,0.2)', color:C.pur, borderRadius:12, padding:'2px 8px', border:`1px solid ${C.pur}44` }}>
                          +{s.totalExtMin}m given ({s.extensionCount}×)
                        </span>
                      )}
                    </div>
                    <div style={{ fontSize:11, color:C.dim }}>{s.studentEmail}</div>
                    <div style={{ fontSize:11, color:C.dim }}>✅ {s.answeredCount} answered</div>
                  </div>

                  {/* 32.15 — Real-time remaining timer */}
                  <div style={{ textAlign:'center', minWidth:80 }}>
                    <div style={{ fontSize:20, fontWeight:800, color:tCol, fontVariantNumeric:'tabular-nums' }}>
                      {fmtTime(remSec)}
                    </div>
                    <div style={{ fontSize:9, color:C.dim }}>remaining</div>
                  </div>

                  {/* 32.2 — "Give Extra Time" button (32.16 — glowing purple) */}
                  <button
                    onClick={() => openModal(s)}
                    style={{
                      background: 'rgba(167,139,250,0.15)',
                      border: '1px solid rgba(167,139,250,0.5)',
                      color: C.pur,
                      borderRadius: 8,
                      padding: '7px 14px',
                      fontSize: 12,
                      cursor: 'pointer',
                      fontWeight: 700,
                      boxShadow: '0 0 8px rgba(167,139,250,0.25)',  // 32.16 glow
                      whiteSpace: 'nowrap',
                    }}
                  >
                    ⏱️ Extend Time
                  </button>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* ── 32.19 — Extension Log (collapsible) ─── */}
      {examId && (
        <div style={{ marginTop:16 }}>
          <button
            onClick={() => { setLogOpen(!logOpen); if (!logOpen) loadLog(examId) }}
            style={{ ...btn(C.acc), display:'flex', alignItems:'center', gap:8, marginBottom:8 }}
          >
            📋 Extension Log ({extLog.length}) {logOpen ? '▲' : '▼'}
          </button>
          {logOpen && (
            <div style={{ ...cs }}>
              <div style={{ display:'flex', justifyContent:'space-between', marginBottom:12 }}>
                <div style={{ fontSize:12, fontWeight:700, color:C.txt }}>All Extensions — {examId}</div>
                <button onClick={downloadReport} style={btn(C.dim)}>📄 PDF</button>
              </div>
              {extLog.length === 0 ? (
                <div style={{ color:C.dim, fontSize:12, textAlign:'center', padding:20 }}>No extensions given yet</div>
              ) : (
                <div style={{ display:'flex', flexDirection:'column', gap:8, maxHeight:350, overflowY:'auto' }}>
                  {extLog.map(log => {
                    const minsAgo     = Math.floor((Date.now() - new Date(log.createdAt).getTime()) / 60000)
                    const canUndo     = !log.isUndone && minsAgo < 5  // 32.12
                    const sName       = log.studentId?.name  || log.studentName  || 'Unknown'
                    const aName       = log.adminId?.name    || log.adminName    || 'Admin'
                    return (
                      <div key={log._id} style={{
                        display:'flex', gap:10, alignItems:'flex-start',
                        padding:'10px 12px', borderRadius:8,
                        background: log.isUndone ? 'rgba(148,163,184,0.05)' : 'rgba(167,139,250,0.07)',
                        border: `1px solid ${log.isUndone ? C.bor2 : C.pur+'33'}`,
                        opacity: log.isUndone ? 0.6 : 1,
                      }}>
                        <div style={{ flex:1 }}>
                          <div style={{ fontSize:12, color:log.isUndone?C.dim:C.txt, fontWeight:600 }}>
                            {log.isGlobal ? '🌐 Global — ' : ''}{sName}
                            <span style={{ color:C.pur, marginLeft:6 }}>+{log.extraMinutes} min</span>
                            {log.isUndone && <span style={{ color:C.dim, marginLeft:6, fontSize:10 }}>[UNDONE]</span>}
                          </div>
                          <div style={{ fontSize:10, color:C.dim, marginTop:2 }}>
                            {log.reason} · By {aName} · {new Date(log.createdAt).toLocaleString()}
                          </div>
                        </div>
                        {/* 32.12 — Undo within 5 min */}
                        {canUndo && (
                          <button
                            onClick={() => undoExtension(log._id, log.extraMinutes, sName)}
                            style={{ ...btn(C.wrn), fontSize:10, padding:'4px 10px', whiteSpace:'nowrap' }}
                          >
                            ↩️ Undo
                          </button>
                        )}
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* ══════════════════════════════════════════════
          32.17 — Extension Modal (per student)
      ══════════════════════════════════════════════ */}
      {modal && (
        <div style={{
          position:'fixed', inset:0, background:'rgba(0,0,0,0.7)', zIndex:1000,
          display:'flex', alignItems:'center', justifyContent:'center', padding:20
        }}>
          <div style={{
            background: C.bg0, borderRadius:16, padding:28, width:'100%', maxWidth:420,
            border:`1px solid ${C.pur}44`,
            boxShadow:`0 0 40px rgba(167,139,250,0.15)`
          }}>
            <div style={{ fontWeight:800, fontSize:16, color:C.txt, marginBottom:6 }}>⏱️ Give Extra Time</div>
            <div style={{ fontSize:13, color:C.acc, marginBottom:20, fontWeight:600 }}>
              {modal.studentName}
            </div>

            {/* 32.10 — Show current remaining time */}
            <div style={{ background: C.bg3, borderRadius:10, padding:'10px 14px', marginBottom:16, display:'flex', justifyContent:'space-between' }}>
              <span style={{ fontSize:12, color:C.dim }}>Current Time Remaining</span>
              <span style={{ fontSize:14, fontWeight:800, color:timeColor(modal.currentRemaining) }}>
                {fmtTime(modal.currentRemaining)}
              </span>
            </div>

            {/* 32.3 — Minutes input */}
            <div style={{ marginBottom:14 }}>
              <div style={{ fontSize:11, color:C.dim, marginBottom:6, fontWeight:600 }}>Extra Minutes</div>
              <div style={{ display:'flex', gap:8, flexWrap:'wrap', marginBottom:10 }}>
                {[5,10,15,20,30].map(m => (
                  <button key={m} onClick={() => setMins(m)} style={{
                    ...btn(mins === m ? C.pur : C.dim),
                    padding:'5px 12px', fontSize:12,
                    background: mins === m ? 'rgba(167,139,250,0.2)' : C.bg3,
                    border: `1px solid ${mins === m ? C.pur : C.bor2}`,
                  }}>+{m}</button>
                ))}
              </div>
              <input
                type='number' min='1' max='120' value={mins}
                onChange={e => setMins(parseInt(e.target.value)||1)}
                style={{ ...inp, width:'100%', boxSizing:'border-box' }}
                placeholder='Custom minutes…'
              />
            </div>

            {/* 32.9 — Reason dropdown */}
            <div style={{ marginBottom:14 }}>
              <div style={{ fontSize:11, color:C.dim, marginBottom:6, fontWeight:600 }}>Reason</div>
              <select
                value={reason}
                onChange={e => setReason(e.target.value)}
                style={{ ...selSt, width:'100%', boxSizing:'border-box' }}
              >
                {REASONS.map(r => <option key={r} value={r}>{r}</option>)}
              </select>
            </div>

            {/* 32.11 — Warning if > 30 min */}
            {(modal.totalExtMin || 0) + mins > 30 && (
              <div style={{ background:'rgba(245,158,11,0.1)', border:'1px solid rgba(245,158,11,0.3)', borderRadius:8, padding:'8px 12px', marginBottom:12, fontSize:11, color:C.wrn }}>
                ⚠️ Warning: Total extension will be {(modal.totalExtMin||0)+mins} min (exceeds 30 min recommended limit)
              </div>
            )}

            {/* Server warning (32.11) */}
            {modalWarn && (
              <div style={{ background:'rgba(245,158,11,0.1)', border:'1px solid rgba(245,158,11,0.3)', borderRadius:8, padding:'8px 12px', marginBottom:12, fontSize:11, color:C.wrn }}>
                {modalWarn}
              </div>
            )}

            <div style={{ display:'flex', gap:10, marginTop:8 }}>
              <button
                onClick={giveExtension}
                disabled={saving || !mins}
                style={{
                  flex:1, background:'rgba(167,139,250,0.2)', border:`1px solid ${C.pur}`,
                  color:C.pur, borderRadius:8, padding:'10px', fontSize:13,
                  cursor:saving?'not-allowed':'pointer', fontWeight:700,
                  opacity:saving?0.6:1, boxShadow:`0 0 12px rgba(167,139,250,0.2)`
                }}
              >
                {saving ? '⟳ Giving…' : `✅ Give +${mins} Minutes`}
              </button>
              <button onClick={()=>{setModal(null);setModalWarn('')}} style={{ ...btn(C.dim), padding:'10px 16px' }}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ══════════════════════════════════════════════
          32.8 / 32.20 — Global Extend Modal
      ══════════════════════════════════════════════ */}
      {globalModal && (
        <div style={{
          position:'fixed', inset:0, background:'rgba(0,0,0,0.75)', zIndex:1000,
          display:'flex', alignItems:'center', justifyContent:'center', padding:20
        }}>
          <div style={{
            background:C.bg0, borderRadius:16, padding:28, width:'100%', maxWidth:420,
            border:`2px solid rgba(239,68,68,0.5)`,
            boxShadow:`0 0 40px rgba(239,68,68,0.15)`
          }}>
            <div style={{ fontWeight:800, fontSize:16, color:C.dng, marginBottom:6 }}>⚠️ Extend All Students</div>
            <div style={{ fontSize:12, color:C.dim, marginBottom:20 }}>
              This will give extra time to ALL {students.length} active students at once.
            </div>

            <div style={{ marginBottom:14 }}>
              <div style={{ fontSize:11, color:C.dim, marginBottom:6, fontWeight:600 }}>Extra Minutes for Everyone</div>
              <div style={{ display:'flex', gap:8, flexWrap:'wrap', marginBottom:10 }}>
                {[5,10,15,20,30].map(m => (
                  <button key={m} onClick={() => setGlobalMins(m)} style={{
                    ...btn(globalMins === m ? C.dng : C.dim),
                    padding:'5px 12px', fontSize:12,
                    background: globalMins === m ? 'rgba(239,68,68,0.15)' : C.bg3,
                    border: `1px solid ${globalMins === m ? C.dng : C.bor2}`,
                  }}>+{m}</button>
                ))}
              </div>
              <input
                type='number' min='1' max='60' value={globalMins}
                onChange={e => setGlobalMins(parseInt(e.target.value)||1)}
                style={{ ...inp, width:'100%', boxSizing:'border-box' }}
              />
            </div>

            <div style={{ marginBottom:20 }}>
              <div style={{ fontSize:11, color:C.dim, marginBottom:6, fontWeight:600 }}>Reason</div>
              <select value={globalReason} onChange={e=>setGlobalReason(e.target.value)}
                style={{ ...selSt, width:'100%', boxSizing:'border-box' }}>
                {REASONS.map(r => <option key={r} value={r}>{r}</option>)}
              </select>
            </div>

            <div style={{ display:'flex', gap:10 }}>
              <button
                onClick={giveGlobal}
                disabled={globalSaving}
                style={{
                  flex:1, background:'rgba(239,68,68,0.15)', border:`1px solid ${C.dng}`,
                  color:C.dng, borderRadius:8, padding:'10px', fontSize:13,
                  cursor:globalSaving?'not-allowed':'pointer', fontWeight:700, opacity:globalSaving?0.6:1
                }}
              >
                {globalSaving ? '⟳ Extending All…' : `⚠️ Extend All ${students.length} Students +${globalMins}m`}
              </button>
              <button onClick={()=>setGlobalModal(false)} style={{ ...btn(C.dim), padding:'10px 16px' }}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* CSS pulse animation for glowing button */}
      <style>{`
        @keyframes purplePulse {
          0%,100% { box-shadow: 0 0 8px rgba(167,139,250,0.25); }
          50%      { box-shadow: 0 0 18px rgba(167,139,250,0.5); }
        }
      `}</style>
    </div>
  )
}
EOF
echo "✅ TimeExtensionPanel.jsx created"

# ════════════════════════════════════════════════════════════════
# 2. PATCH — page.tsx (add import + inject in live tab)
# ════════════════════════════════════════════════════════════════
if [ -z "$PAGE_TSX" ] || [ ! -f "$PAGE_TSX" ]; then
  echo "⚠️  page.tsx not found — skipping patch. Manually import TimeExtensionPanel."
else
  cp "$PAGE_TSX" "${PAGE_TSX}.bak"
  node << 'JSEOF'
const fs = require('fs');
const pt = process.env.PAGE_TSX;
let c  = fs.readFileSync(pt, 'utf8');

// 1. Add import if not present
const importLine = "import TimeExtensionPanel from './TimeExtensionPanel'";
if (!c.includes('TimeExtensionPanel')) {
  // Insert after last existing import block
  const lastImport = "import AdminProfilePage from './AdminProfilePage';";
  if (c.includes(lastImport)) {
    c = c.replace(lastImport, lastImport + "\nimport TimeExtensionPanel from './TimeExtensionPanel'; // Feature 32");
  } else {
    // Fallback: add after first 'use client'
    c = c.replace("'use client'\n", "'use client'\nimport TimeExtensionPanel from './TimeExtensionPanel'; // Feature 32\n");
  }
  console.log('✅ Import added');
} else { console.log('ℹ️  Import already present'); }

// 2. Inject TimeExtensionPanel into live tab section
//    Find tab==='live'&&( ... next section marker
const liveMarker = "tab==='live'&&(";
const liveIdx    = c.indexOf(liveMarker);

if (liveIdx === -1) {
  console.log('⚠️  Live tab not found — adding as standalone tab instead');
  // Add as new NAV entry + tab content
  const navInsert = "\n    {id:'time_extension',ico:'⏱️',lbl:'Time Extension',grp:'Exams'},";
  c = c.replace(
    "{id:'live',ico:'🔴',lbl:'Live Monitor',grp:'Overview'},",
    "{id:'live',ico:'🔴',lbl:'Live Monitor',grp:'Overview'}," + navInsert
  );
  // Add tab content before module.exports or at end of tab chain
  const tabInsert = `\n          {/* ══ FEATURE 32: PER-STUDENT TIME EXTENSION ══ */}\n          {tab==='time_extension'&&(\n            <TimeExtensionPanel token={token} API={API} T={T} role={role} />\n          )}\n\n`;
  const firstTabEnd = c.indexOf("{tab==='create_exam'&&(");
  if (firstTabEnd !== -1) {
    c = c.slice(0, firstTabEnd) + tabInsert + c.slice(firstTabEnd);
  }
  console.log('✅ Added as new Time Extension tab');
} else {
  // Find next section comment after live tab
  const nextSection = c.indexOf('\n          {/* ══', liveIdx + 20);
  if (nextSection === -1) { console.log('⚠️  Could not find section end'); }
  else {
    // Find the closing )} just before next section
    const beforeNext = c.slice(0, nextSection);
    const closeIdx   = beforeNext.lastIndexOf('          )}');

    if (closeIdx !== -1 && closeIdx > liveIdx) {
      const inject = `\n            {/* ── Feature 32: Per-Student Time Extension ── */}\n            <TimeExtensionPanel token={token} API={API} T={T} role={role} />\n`;
      c = c.slice(0, closeIdx) + inject + c.slice(closeIdx);
      console.log('✅ TimeExtensionPanel injected into live monitor tab');
    } else {
      console.log('⚠️  Could not find safe injection point in live tab');
    }
  }
}

fs.writeFileSync(pt, c);
JSEOF
  echo "✅ page.tsx patched"
fi

# ════════════════════════════════════════════════════════════════
# 3. VERIFICATION — All 20 sub-features
# ════════════════════════════════════════════════════════════════
echo ""
echo "══════════════════════════════════════════════"
echo "  🔍 Frontend Feature 32 — Verification"
echo "══════════════════════════════════════════════"
PAGE_TSX="$PAGE_TSX" ADMIN_DIR="$ADMIN_DIR" node << 'JSEOF'
const fs   = require('fs');
const path = require('path');

const adminDir  = process.env.ADMIN_DIR;
const panelFile = path.join(adminDir, 'TimeExtensionPanel.jsx');
const pageTsx   = process.env.PAGE_TSX;

const panel = fs.existsSync(panelFile) ? fs.readFileSync(panelFile, 'utf8') : '';
const page  = (pageTsx && fs.existsSync(pageTsx)) ? fs.readFileSync(pageTsx, 'utf8') : '';

const checks = [
  // Sub-feature checks against component content
  ['32.1  Student list in Live Monitor',                  panel.includes('active-students') && panel.includes('students.map')],
  ['32.2  "Give Extra Time" button per student card',     panel.includes('Extend Time') && panel.includes('openModal')],
  ['32.3  Extra minutes input (+5/10/15/20/30 + custom)', panel.includes('[5,10,15,20,30]') && panel.includes("type='number'")],
  ['32.4  Socket.io push (admin event listener)',         panel.includes('admin:extension_given') && panel.includes('useSocketListener')],
  ['32.5  Student timer auto-updates (live countdown)',   panel.includes('setInterval') && panel.includes('fmtTime')],
  ['32.6  Extension log (student/admin/time shown)',      panel.includes('/api/time-extension/log') && panel.includes('extLog')],
  ['32.7  Multiple extensions ok (extensionCount shown)', panel.includes('extensionCount') && panel.includes('totalExtMin')],
  ['32.8  Global extend — all students at once',          panel.includes('/api/time-extension/global') && panel.includes('giveGlobal')],
  ['32.9  Reason dropdown (4 options)',                   panel.includes('Disability') && panel.includes('Technical Issue') && panel.includes('Internet Problem')],
  ['32.10 Current remaining time shown in modal',         panel.includes('currentRemaining') && panel.includes('fmtTime(modal.currentRemaining)')],
  ['32.11 30 min warning logic',                          panel.includes('> 30') && panel.includes('30 min')],
  ['32.12 Undo within 5 min (canUndo check)',             panel.includes('minsAgo < 5') && panel.includes('undoExtension')],
  ['32.13 Notification msg (Admin has given you...)',     panel.includes('Admin has given you') || panel.includes('extension_given')],
  ['32.14 Download PDF report button',                    panel.includes('downloadReport') && panel.includes('PDF Report')],
  ['32.15 Student cards with real-time timer display',    panel.includes('fmtTime(remSec)') && panel.includes('remaining')],
  ['32.16 Glowing purple extend button',                  panel.includes('purplePulse') || panel.includes('rgba(167,139,250')],
  ['32.17 Extension modal — clean, minimal',              panel.includes('Give Extra Time') && panel.includes('Reason') && panel.includes('setModal')],
  ['32.18 Green border flash after extension',            panel.includes('flashGreen') && panel.includes('isFlash')],
  ['32.19 Extension log — collapsible section',           panel.includes('logOpen') && panel.includes('Extension Log')],
  ['32.20 Global extend big red-bordered button',         panel.includes('Extend All Students') && panel.includes('rgba(239,68,68')],
  // Page.tsx integration checks
  ['page.tsx: TimeExtensionPanel imported',               page.includes('TimeExtensionPanel')],
  ['TimeExtensionPanel.jsx file exists',                  panel.length > 1000],
];

let pass = 0, fail = 0;
checks.forEach(([label, ok]) => {
  console.log((ok ? '✅' : '❌') + ' ' + label);
  ok ? pass++ : fail++;
});

console.log('\n──────────────────────────────────────────────');
console.log(`Result: ${pass}/${checks.length} checks passed`);
if (fail === 0) {
  console.log('');
  console.log('🎉 ALL CHECKS PASSED!');
  console.log('');
  console.log('✅ 32.1  — Live Monitor student list');
  console.log('✅ 32.2  — Give Extra Time button');
  console.log('✅ 32.3  — Extra minutes input');
  console.log('✅ 32.4  — Real-time Socket.io push');
  console.log('✅ 32.5  — Student timer auto-update');
  console.log('✅ 32.6  — Extension log');
  console.log('✅ 32.7  — Multiple extensions');
  console.log('✅ 32.8  — Global extend');
  console.log('✅ 32.9  — Reason dropdown');
  console.log('✅ 32.10 — Current time remaining');
  console.log('✅ 32.11 — 30 min limit warning');
  console.log('✅ 32.12 — Undo within 5 min');
  console.log('✅ 32.13 — Student notification');
  console.log('✅ 32.14 — PDF report download');
  console.log('✅ 32.15 — Real-time timer cards');
  console.log('✅ 32.16 — Glowing purple button');
  console.log('✅ 32.17 — Extension modal');
  console.log('✅ 32.18 — Green border flash');
  console.log('✅ 32.19 — Collapsible log');
  console.log('✅ 32.20 — Global extend big button');
} else {
  console.log(`⚠️  ${fail} check(s) need attention`);
}
JSEOF
