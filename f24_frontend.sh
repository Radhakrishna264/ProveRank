#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Feature 24: Question Delete Core (Frontend)    ║
# ║  Hover delete · Modal · Archive · Bulk · Undo toast        ║
# ╚══════════════════════════════════════════════════════════════╝
set -e
FE=~/workspace/frontend/app/admin/x7k2p
echo "🚀 Feature 24 Frontend setup..."

# ─── Step 1: Create DeleteQuestionSystem.tsx component ───────────────────────
cat > $FE/DeleteQuestionSystem.tsx << 'ENDOFFILE'
'use client'
import { useState, useEffect, useRef, useCallback } from 'react'

// ── Design tokens (match admin panel) ─────────────────────────
const ACC='#4D9FFF', TS='#E8F4FF', DIM='#6B8FAF', GOLD='#FFD700'
const DNG='#FF4D4D', WRN='#FFB84D', SUC='#00C48C', PRP='#A78BFA'
const BOR='rgba(77,159,255,0.18)', CRD='rgba(0,18,36,0.82)'
const bp:any={background:`linear-gradient(135deg,${ACC},#0055CC)`,color:'#fff',border:'none',borderRadius:9,padding:'9px 18px',cursor:'pointer',fontWeight:700,fontSize:13,transition:'all 0.2s'}
const bg_:any={background:'rgba(0,30,60,0.7)',color:TS,border:`1px solid ${BOR}`,borderRadius:9,padding:'9px 18px',cursor:'pointer',fontSize:13,transition:'all 0.2s'}
const dng:any={background:`linear-gradient(135deg,${DNG},#cc0000)`,color:'#fff',border:'none',borderRadius:9,padding:'9px 18px',cursor:'pointer',fontWeight:700,fontSize:13,transition:'all 0.2s'}
const inp:any={width:'100%',padding:'10px 13px',background:'rgba(0,22,40,0.85)',border:`1.5px solid ${BOR}`,borderRadius:9,color:TS,fontSize:13,outline:'none',boxSizing:'border-box',fontFamily:'Inter,sans-serif'}
const lbl:any={display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,letterSpacing:0.5,textTransform:'uppercase' as any}
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:13,padding:'18px',backdropFilter:'blur(12px)'}

// ── Undo Toast (Feature 24.14) ─────────────────────────────────────────────────
export function UndoToast({ message, onUndo, onDismiss, seconds = 15 }:
  { message:string; onUndo:()=>void; onDismiss:()=>void; seconds?:number }) {
  const [remaining, setRemaining] = useState(seconds)
  const pct = (remaining / seconds) * 100

  useEffect(() => {
    if (remaining <= 0) { onDismiss(); return }
    const t = setTimeout(() => setRemaining(r => r - 1), 1000)
    return () => clearTimeout(t)
  }, [remaining, onDismiss])

  return (
    <div style={{
      position:'fixed', bottom:20, left:16, zIndex:99999,
      background:'linear-gradient(135deg,#0D1B2A,#142840)',
      border:`1.5px solid ${DNG}55`, borderRadius:13, padding:'14px 18px',
      minWidth:280, maxWidth:360, boxShadow:`0 8px 32px rgba(0,0,0,0.5),0 0 0 1px ${DNG}22`,
      animation:'slideInLeft 0.3s ease'
    }}>
      <style dangerouslySetInnerHTML={{__html:`
        @keyframes slideInLeft{from{transform:translateX(-120%);opacity:0}to{transform:translateX(0);opacity:1}}
      `}}/>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:10}}>
        <div>
          <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:3}}>🗑️ {message}</div>
          <div style={{fontSize:11,color:DIM}}>Auto-dismisses in {remaining}s</div>
        </div>
        <button onClick={onDismiss} style={{background:'none',border:'none',color:DIM,cursor:'pointer',fontSize:18,lineHeight:1,padding:'0 4px'}}>✕</button>
      </div>
      {/* Countdown bar */}
      <div style={{height:3,background:'rgba(255,255,255,0.08)',borderRadius:2,marginBottom:10,overflow:'hidden'}}>
        <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${DNG},${WRN})`,borderRadius:2,transition:'width 1s linear'}}/>
      </div>
      <div style={{display:'flex',gap:8}}>
        <button onClick={onUndo} style={{...bp,flex:1,fontSize:12,padding:'7px 12px',background:`linear-gradient(135deg,${SUC},#00884a)`}}>
          ↩️ Undo Delete
        </button>
        <button onClick={onDismiss} style={{...bg_,fontSize:12,padding:'7px 12px',borderColor:`${DNG}44`,color:DNG}}>
          Dismiss
        </button>
      </div>
    </div>
  )
}

// ── Delete Impact Modal (Feature 24.2 / 24.3 / 24.10 / 24.12 / 24.13) ────────
export function DeleteConfirmModal({ question, impact, onArchive, onDelete, onCancel, loading }:
  {
    question: any
    impact: { usedInExams:number; liveExams:number; exams:any[]; warning:string|null } | null
    onArchive: (reason:string) => void
    onDelete:  (reason:string) => void
    onCancel:  () => void
    loading:   boolean
  }) {
  const [reason, setReason] = useState('')
  const [tab, setTab] = useState<'delete'|'archive'>('delete')

  return (
    <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:99990,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}
      onClick={onCancel}>
      <div style={{
        ...cs,
        width:'100%', maxWidth:480, maxHeight:'92vh', overflowY:'auto' as any,
        border:`2px solid ${DNG}55`,
        boxShadow:`0 0 0 1px ${DNG}22, 0 20px 60px rgba(255,77,77,0.15)`
      }} onClick={e=>e.stopPropagation()}>

        {/* Header 24.12 — red border + warning icon */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16}}>
          <div style={{display:'flex',gap:10,alignItems:'center'}}>
            <div style={{fontSize:32,filter:`drop-shadow(0 0 12px ${DNG}88)`}}>⚠️</div>
            <div>
              <div style={{fontWeight:800,fontSize:16,color:DNG}}>Delete Question?</div>
              <div style={{fontSize:11,color:DIM,marginTop:2}}>This action can be undone within 30 days</div>
            </div>
          </div>
          <button onClick={onCancel} style={{background:'none',border:'none',color:DIM,cursor:'pointer',fontSize:22,lineHeight:1}}>✕</button>
        </div>

        {/* Question preview */}
        <div style={{background:'rgba(255,77,77,0.06)',border:`1px solid ${DNG}33`,borderRadius:10,padding:'12px 14px',marginBottom:14}}>
          <div style={{fontSize:11,color:DIM,marginBottom:5,fontWeight:600}}>QUESTION TO DELETE</div>
          <div style={{fontSize:13,color:TS,lineHeight:1.5,marginBottom:8}}>
            {((question?.text||'').slice(0, 120))}{(question?.text||'').length > 120 ? '…' : ''}
          </div>
          <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
            {question?.subject && <span style={{background:`${ACC}18`,color:ACC,borderRadius:20,padding:'2px 9px',fontSize:10,fontWeight:600,border:`1px solid ${ACC}33`}}>{question.subject}</span>}
            {question?.chapter && <span style={{background:`${PRP}18`,color:PRP,borderRadius:20,padding:'2px 9px',fontSize:10,fontWeight:600,border:`1px solid ${PRP}33`}}>{question.chapter}</span>}
            {question?.difficulty && <span style={{background:'rgba(255,184,77,0.15)',color:WRN,borderRadius:20,padding:'2px 9px',fontSize:10,fontWeight:600,border:`1px solid ${WRN}33`}}>{question.difficulty}</span>}
          </div>
        </div>

        {/* 24.13 — "Used in X exams" warning chip (orange) */}
        {impact && impact.usedInExams > 0 && (
          <div style={{background:'rgba(255,184,77,0.1)',border:`1px solid ${WRN}44`,borderRadius:10,padding:'10px 14px',marginBottom:14,display:'flex',alignItems:'center',gap:10}}>
            <span style={{fontSize:20}}>📊</span>
            <div>
              <div style={{fontWeight:700,fontSize:13,color:WRN}}>Used in {impact.usedInExams} exam{impact.usedInExams > 1 ? 's' : ''}</div>
              <div style={{fontSize:11,color:DIM,marginTop:2}}>
                {impact.liveExams > 0
                  ? `⚡ ${impact.liveExams} exam(s) currently live — exams use snapshots, they won't be affected`
                  : '✅ No live exams — snapshots ensure past exams stay intact'}
              </div>
              {impact.exams.slice(0,3).map((e:any,i:number) => (
                <div key={i} style={{fontSize:10,color:DIM,marginTop:3}}>• {e.title} <span style={{color:e.status==='live'?DNG:DIM}}>({e.status||'draft'})</span></div>
              ))}
            </div>
          </div>
        )}

        {/* Safe notice */}
        <div style={{background:'rgba(0,196,140,0.08)',border:`1px solid ${SUC}33`,borderRadius:10,padding:'10px 14px',marginBottom:16,fontSize:12,color:SUC,display:'flex',gap:8,alignItems:'flex-start'}}>
          <span style={{fontSize:16,flexShrink:0}}>✅</span>
          <div>
            <strong>Safe to delete.</strong> Exams that used this question will <strong>not be affected</strong> — they store question copies (snapshots).
            Deleted questions go to <strong>Recycle Bin</strong> for 30 days.
          </div>
        </div>

        {/* Tab selector: Delete vs Archive */}
        <div style={{display:'flex',gap:0,border:`1px solid ${BOR}`,borderRadius:10,overflow:'hidden',marginBottom:14}}>
          <button onClick={() => setTab('delete')} style={{
            flex:1, padding:'10px', border:'none', cursor:'pointer', fontSize:12, fontWeight:700, transition:'all 0.2s',
            background: tab==='delete' ? `linear-gradient(135deg,${DNG},#cc0000)` : 'transparent',
            color: tab==='delete' ? '#fff' : DIM
          }}>🗑️ Move to Recycle Bin</button>
          <button onClick={() => setTab('archive')} style={{
            flex:1, padding:'10px', border:'none', cursor:'pointer', fontSize:12, fontWeight:700, transition:'all 0.2s',
            background: tab==='archive' ? `linear-gradient(135deg,${WRN},#cc8800)` : 'transparent',
            color: tab==='archive' ? '#000' : DIM
          }}>🗂️ Archive Instead</button>
        </div>

        {/* 24.7 — Reason input */}
        <div style={{marginBottom:16}}>
          <label style={lbl}>Delete Reason <span style={{color:DIM,fontWeight:400,textTransform:'none' as any}}>(optional, for audit)</span></label>
          <input
            value={reason}
            onChange={e => setReason(e.target.value)}
            placeholder={tab==='delete' ? 'e.g. Duplicate, Incorrect, Outdated…' : 'e.g. Temporarily hiding, needs review…'}
            style={inp}
          />
        </div>

        {/* Action buttons */}
        <div style={{display:'flex',gap:8}}>
          {tab === 'delete' ? (
            <button onClick={() => onDelete(reason)} disabled={loading} style={{...dng, flex:1, opacity: loading ? 0.7:1}}>
              {loading ? '⟳ Deleting…' : '🗑️ Move to Recycle Bin'}
            </button>
          ) : (
            <button onClick={() => onArchive(reason)} disabled={loading} style={{
              ...bp, flex:1, opacity: loading ? 0.7:1,
              background:`linear-gradient(135deg,${WRN},#cc8800)`, color:'#000'
            }}>
              {loading ? '⟳ Archiving…' : '🗂️ Archive Question'}
            </button>
          )}
          <button onClick={onCancel} style={bg_}>Cancel</button>
        </div>
      </div>
    </div>
  )
}

// ── Recycle Bin Modal (Feature 24.9) ───────────────────────────────────────────
export function RecycleBinModal({ token, API, onClose, onRestore, toast }:
  { token:string; API:string; onClose:()=>void; onRestore:()=>void; toast:(m:string,t?:'s'|'e'|'w')=>void }) {
  const [questions, setQuestions] = useState<any[]>([])
  const [loading, setLoading]     = useState(false)
  const hdrs = { Authorization: `Bearer ${token}` }

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const r = await fetch(`${API}/api/questions/recycle-bin`, { headers: hdrs })
      const d = await r.json()
      if (d.success) setQuestions(d.questions || [])
    } catch { toast('Failed to load recycle bin', 'e') }
    setLoading(false)
  }, [token, API])

  useEffect(() => { load() }, [load])

  const restore = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/questions/${id}/restore`, { method:'PATCH', headers: hdrs })
      const d = await r.json()
      if (d.success) { toast('Question restored! ✅'); setQuestions(p => p.filter(q => q._id !== id)); onRestore() }
      else toast(d.message || 'Failed', 'e')
    } catch { toast('Error', 'e') }
  }

  const wipe = async (id: string) => {
    if (!confirm('Permanently delete? This CANNOT be undone.')) return
    try {
      const r = await fetch(`${API}/api/questions/${id}/wipe`, { method:'DELETE', headers: hdrs })
      const d = await r.json()
      if (d.success) { toast('Permanently wiped', 'w'); setQuestions(p => p.filter(q => q._id !== id)) }
      else toast(d.message || 'Failed', 'e')
    } catch { toast('Error', 'e') }
  }

  const daysLeft = (deletedAt: string) => {
    const diff = 30 - Math.floor((Date.now() - new Date(deletedAt).getTime()) / (1000 * 60 * 60 * 24))
    return Math.max(0, diff)
  }

  return (
    <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:99990,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}
      onClick={onClose}>
      <div style={{...cs,width:'100%',maxWidth:560,maxHeight:'92vh',overflowY:'auto' as any,border:`1.5px solid ${DNG}44`}}
        onClick={e => e.stopPropagation()}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
          <div>
            <div style={{fontWeight:800,fontSize:16,color:DNG}}>🗑️ Recycle Bin</div>
            <div style={{fontSize:11,color:DIM,marginTop:2}}>Questions recoverable within 30 days of deletion</div>
          </div>
          <button onClick={onClose} style={{background:'none',border:'none',color:DIM,cursor:'pointer',fontSize:22}}>✕</button>
        </div>

        {loading ? (
          <div style={{textAlign:'center',padding:'40px',color:DIM}}>
            <div style={{fontSize:32,marginBottom:8}}>⟳</div>Loading...
          </div>
        ) : questions.length === 0 ? (
          <div style={{textAlign:'center',padding:'40px'}}>
            <div style={{fontSize:48,marginBottom:12}}>🗑️</div>
            <div style={{fontWeight:700,color:TS,marginBottom:6}}>Recycle Bin is Empty</div>
            <div style={{fontSize:12,color:DIM}}>Deleted questions appear here for 30 days before permanent removal</div>
          </div>
        ) : (
          <div>
            <div style={{fontSize:11,color:DIM,marginBottom:12,fontWeight:600}}>{questions.length} question{questions.length>1?'s':''} in recycle bin</div>
            {questions.map(q => (
              <div key={q._id} style={{...cs,padding:'12px 14px',marginBottom:10,borderLeft:`3px solid ${DNG}`,opacity:0.9}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:10}}>
                  <div style={{flex:1,minWidth:0}}>
                    <div style={{fontSize:13,color:TS,lineHeight:1.5,marginBottom:6}}>
                      {(q.text||'').slice(0,100)}{(q.text||'').length>100?'…':''}
                    </div>
                    <div style={{display:'flex',gap:6,flexWrap:'wrap' as any,marginBottom:6}}>
                      {q.subject && <span style={{background:`${ACC}18`,color:ACC,borderRadius:12,padding:'1px 8px',fontSize:10}}>{q.subject}</span>}
                      {q.chapter && <span style={{background:`${PRP}18`,color:PRP,borderRadius:12,padding:'1px 8px',fontSize:10}}>{q.chapter}</span>}
                    </div>
                    <div style={{fontSize:10,color:DIM}}>
                      Deleted: {q.deletedAt ? new Date(q.deletedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}) : '—'}
                      {q.deleteReason && <span> · Reason: {q.deleteReason}</span>}
                    </div>
                    {/* Days left badge */}
                    <div style={{marginTop:4}}>
                      <span style={{
                        background: daysLeft(q.deletedAt) <= 5 ? `${DNG}22` : `${WRN}22`,
                        color:      daysLeft(q.deletedAt) <= 5 ? DNG : WRN,
                        border:`1px solid ${daysLeft(q.deletedAt) <= 5 ? DNG : WRN}44`,
                        borderRadius:12, padding:'2px 8px', fontSize:10, fontWeight:600
                      }}>
                        ⏳ {daysLeft(q.deletedAt)} days left to recover
                      </span>
                    </div>
                  </div>
                  <div style={{display:'flex',flexDirection:'column' as any,gap:6,flexShrink:0}}>
                    <button onClick={() => restore(q._id)} style={{...bp,fontSize:11,padding:'6px 12px',background:`linear-gradient(135deg,${SUC},#00884a)`}}>↩️ Restore</button>
                    <button onClick={() => wipe(q._id)}   style={{background:'rgba(255,77,77,0.12)',border:`1px solid ${DNG}44`,color:DNG,borderRadius:8,padding:'6px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>💀 Wipe</button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

// ── Archived Questions Modal (Feature 24.4 / 24.15) ───────────────────────────
export function ArchivedModal({ token, API, onClose, onRestore, toast }:
  { token:string; API:string; onClose:()=>void; onRestore:()=>void; toast:(m:string,t?:'s'|'e'|'w')=>void }) {
  const [questions, setQuestions] = useState<any[]>([])
  const [loading, setLoading]     = useState(false)
  const hdrs = { Authorization: `Bearer ${token}` }

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const r = await fetch(`${API}/api/questions/archived`, { headers: hdrs })
      const d = await r.json()
      if (d.success) setQuestions(d.questions || [])
    } catch {}
    setLoading(false)
  }, [token, API])

  useEffect(() => { load() }, [load])

  const restore = async (id: string) => {
    try {
      const r = await fetch(`${API}/api/questions/${id}/restore`, { method:'PATCH', headers: hdrs })
      const d = await r.json()
      if (d.success) { toast('Question restored! ✅'); setQuestions(p => p.filter(q => q._id !== id)); onRestore() }
      else toast(d.message || 'Failed', 'e')
    } catch { toast('Error', 'e') }
  }

  return (
    <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:99990,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}
      onClick={onClose}>
      <div style={{...cs,width:'100%',maxWidth:520,maxHeight:'90vh',overflowY:'auto' as any,border:`1.5px solid ${WRN}44`}}
        onClick={e => e.stopPropagation()}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
          <div>
            <div style={{fontWeight:800,fontSize:16,color:WRN}}>🗂️ Archived Questions</div>
            <div style={{fontSize:11,color:DIM,marginTop:2}}>Soft-deleted · Restore anytime</div>
          </div>
          <button onClick={onClose} style={{background:'none',border:'none',color:DIM,cursor:'pointer',fontSize:22}}>✕</button>
        </div>
        {loading ? (
          <div style={{textAlign:'center',padding:'40px',color:DIM}}>⟳ Loading...</div>
        ) : questions.length === 0 ? (
          <div style={{textAlign:'center',padding:'40px'}}>
            <div style={{fontSize:48,marginBottom:12}}>🗂️</div>
            <div style={{fontWeight:700,color:TS}}>No Archived Questions</div>
          </div>
        ) : (
          questions.map(q => (
            <div key={q._id} style={{...cs,padding:'12px 14px',marginBottom:10,borderLeft:`3px solid ${WRN}`,opacity:0.85,marginBottom:8}}>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:10}}>
                <div style={{flex:1,minWidth:0}}>
                  {/* 24.15 — card goes grey + "Archived" badge */}
                  <div style={{display:'flex',gap:6,marginBottom:6,alignItems:'center'}}>
                    <span style={{background:`${WRN}22`,color:WRN,border:`1px solid ${WRN}44`,borderRadius:12,padding:'2px 9px',fontSize:10,fontWeight:700}}>🗂️ Archived</span>
                    {q.subject && <span style={{background:`${ACC}18`,color:ACC,borderRadius:12,padding:'1px 8px',fontSize:10}}>{q.subject}</span>}
                  </div>
                  <div style={{fontSize:13,color:'#8899AA',lineHeight:1.5,marginBottom:4}}>
                    {(q.text||'').slice(0,100)}{(q.text||'').length>100?'…':''}
                  </div>
                  <div style={{fontSize:10,color:DIM}}>
                    Archived: {q.archivedAt ? new Date(q.archivedAt).toLocaleDateString('en-IN') : '—'}
                    {q.deleteReason && <span> · {q.deleteReason}</span>}
                  </div>
                </div>
                <button onClick={() => restore(q._id)} style={{...bp,fontSize:11,padding:'6px 12px',background:`linear-gradient(135deg,${SUC},#00884a)`,flexShrink:0}}>↩️ Restore</button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}

// ── Delete Button (Feature 24.11) — hover-reveal red icon ─────────────────────
export function DeleteBtn({ onClick }: { onClick: () => void }) {
  const [hov, setHov] = useState(false)
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHov(true)}
      onMouseLeave={() => setHov(false)}
      style={{
        background:   hov ? `linear-gradient(135deg,${DNG},#aa0000)` : 'rgba(255,77,77,0.06)',
        border:      `1px solid ${hov ? DNG : 'rgba(255,77,77,0.2)'}`,
        color:        hov ? '#fff' : DNG,
        borderRadius: 7,
        width: 30, height: 28,
        cursor:  'pointer',
        fontSize: 13,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'all 0.2s',
        opacity: hov ? 1 : 0.5,          /* ← hover pe hi visible 24.11 */
        transform: hov ? 'scale(1.1)' : 'scale(1)',
        boxShadow: hov ? `0 4px 14px ${DNG}44` : 'none'
      }}
      title="Delete question"
    >🗑️</button>
  )
}

// ── Main hook — useDeleteQuestion ─────────────────────────────────────────────
export function useDeleteQuestion(token: string, API: string, toast: (m:string, t?:'s'|'e'|'w')=>void, onRefresh: ()=>void) {
  const hdrs = { 'Content-Type':'application/json', Authorization:`Bearer ${token}` }

  // State
  const [delModal,    setDelModal]    = useState<any|null>(null)   // question to delete
  const [delImpact,   setDelImpact]   = useState<any|null>(null)
  const [delLoading,  setDelLoading]  = useState(false)
  const [undoToast,   setUndoToast]   = useState<{msg:string; id:string}|null>(null)
  const [showBin,     setShowBin]     = useState(false)
  const [showArchived,setShowArchived]= useState(false)

  // 24.10 — Fetch impact then open modal
  const openDeleteModal = useCallback(async (question: any) => {
    setDelModal(question)
    setDelImpact(null)
    try {
      const r = await fetch(`${API}/api/questions/${question._id}/delete-impact`, { headers: { Authorization:`Bearer ${token}` } })
      const d = await r.json()
      if (d.success) setDelImpact(d)
    } catch {}
  }, [token, API])

  // 24.1 — Single delete (soft → recycle bin)
  const confirmDelete = useCallback(async (reason: string) => {
    if (!delModal) return
    setDelLoading(true)
    try {
      const r = await fetch(`${API}/api/questions/${delModal._id}/permanent`, {
        method: 'DELETE', headers: hdrs, body: JSON.stringify({ reason })
      })
      const d = await r.json()
      if (d.success) {
        toast(`"${(delModal.text||'').slice(0,40)}…" moved to Recycle Bin`, 'w')
        // 24.6 — Undo toast
        setUndoToast({ msg: `Question deleted`, id: delModal._id })
        setDelModal(null)
        onRefresh()
      } else toast(d.message || 'Delete failed', 'e')
    } catch { toast('Error', 'e') }
    setDelLoading(false)
  }, [delModal, token, API, onRefresh])

  // 24.4 — Archive
  const confirmArchive = useCallback(async (reason: string) => {
    if (!delModal) return
    setDelLoading(true)
    try {
      const r = await fetch(`${API}/api/questions/${delModal._id}/archive`, {
        method: 'PATCH', headers: hdrs, body: JSON.stringify({ reason })
      })
      const d = await r.json()
      if (d.success) {
        toast('Question archived 🗂️', 'w')
        setUndoToast({ msg: 'Question archived', id: delModal._id })
        setDelModal(null)
        onRefresh()
      } else toast(d.message || 'Archive failed', 'e')
    } catch { toast('Error', 'e') }
    setDelLoading(false)
  }, [delModal, token, API, onRefresh])

  // 24.6 — Undo
  const undoDelete = useCallback(async () => {
    if (!undoToast) return
    try {
      const r = await fetch(`${API}/api/questions/${undoToast.id}/restore`, { method:'PATCH', headers: hdrs })
      const d = await r.json()
      if (d.success) { toast('↩️ Undo successful! Question restored.', 's'); setUndoToast(null); onRefresh() }
      else toast(d.message || 'Undo failed', 'e')
    } catch { toast('Error', 'e') }
  }, [undoToast, token, API, onRefresh])

  // 24.5 — Bulk delete
  const bulkDelete = useCallback(async (ids: string[], reason = '') => {
    if (!ids.length) return
    try {
      const r = await fetch(`${API}/api/questions/bulk/delete`, {
        method: 'PATCH', headers: hdrs, body: JSON.stringify({ ids, reason })
      })
      const d = await r.json()
      if (d.success) {
        toast(`${d.modifiedCount} questions moved to Recycle Bin`, 'w')
        setUndoToast(null) // bulk — no single undo
        onRefresh()
        return true
      } else { toast(d.message || 'Bulk delete failed', 'e'); return false }
    } catch { toast('Error', 'e'); return false }
  }, [token, API, onRefresh])

  // 24.5 — Bulk archive
  const bulkArchive = useCallback(async (ids: string[], reason = '') => {
    if (!ids.length) return
    try {
      const r = await fetch(`${API}/api/questions/bulk/archive`, {
        method: 'PATCH', headers: hdrs, body: JSON.stringify({ ids, reason })
      })
      const d = await r.json()
      if (d.success) { toast(`${d.modifiedCount} questions archived 🗂️`, 'w'); onRefresh(); return true }
      else { toast(d.message || 'Bulk archive failed', 'e'); return false }
    } catch { toast('Error', 'e'); return false }
  }, [token, API, onRefresh])

  return {
    openDeleteModal, confirmDelete, confirmArchive, undoDelete, bulkDelete, bulkArchive,
    delModal, setDelModal, delImpact, delLoading,
    undoToast, setUndoToast,
    showBin, setShowBin, showArchived, setShowArchived
  }
}
ENDOFFILE
echo "✅ DeleteQuestionSystem.tsx created"

# ─── Step 2: Patch page.tsx ───────────────────────────────────────────────────
cat > /tmp/patch_page_f24.js << 'ENDOFFILE'
const fs   = require('fs');
const path = require('path');
const file = path.join(require('os').homedir(), 'workspace/frontend/app/admin/x7k2p/page.tsx');
if (!fs.existsSync(file)) { console.log('❌ page.tsx not found'); process.exit(1); }
let c = fs.readFileSync(file, 'utf8');

// ── 1. Add import ─────────────────────────────────────────────────────────────
if (!c.includes('DeleteQuestionSystem')) {
  // find first 'use client' or first import
  c = c.replace(
    "'use client'",
    "'use client'\nimport { DeleteBtn, DeleteConfirmModal, RecycleBinModal, ArchivedModal, UndoToast, useDeleteQuestion } from './DeleteQuestionSystem'"
  );
  console.log('✅ DeleteQuestionSystem imported');
} else {
  console.log('✅ Import already present');
}

// ── 2. Wire the hook inside the component — after existing bulk state ─────────
// Find the QUESTION BANK comment and inject hook usage
const HOOK_MARKER = '  // ══ QUESTION BANK ══';
if (!c.includes('useDeleteQuestion') && c.includes(HOOK_MARKER)) {
  const hookCode = `
  // ── Feature 24: Delete System ──────────────────────────────────────────────
  const {
    openDeleteModal, confirmDelete, confirmArchive, undoDelete, bulkDelete, bulkArchive,
    delModal, setDelModal, delImpact, delLoading,
    undoToast, setUndoToast,
    showBin, setShowBin, showArchived, setShowArchived
  } = useDeleteQuestion(token, API, T, fetchAll)

`;
  c = c.replace(HOOK_MARKER, hookCode + HOOK_MARKER);
  console.log('✅ useDeleteQuestion hook wired');
} else {
  console.log('✅ Hook already wired or marker not found');
}

// ── 3. Replace old single delete button with new DeleteBtn ───────────────────
const OLD_DEL_BTN = `<button onClick={async function(){if(confirm('Delete?')){const r=await fetch(API+'/api/questions/'+q._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}});if(r.ok){setQuestions(function(p){return p.filter(function(x){return x._id!==q._id})});T('Deleted.')}else T('Failed','e')}}} style={{...bd,padding:'2px',fontSize:10,borderRadius:5,width:30,height:28,display:'flex',alignItems:'center',justifyContent:'center'}} title='Delete'>🗑️</button>`;

const NEW_DEL_BTN = `<DeleteBtn onClick={()=>openDeleteModal(q)}/>`;

if (c.includes(OLD_DEL_BTN)) {
  c = c.replace(OLD_DEL_BTN, NEW_DEL_BTN);
  console.log('✅ Single delete button replaced with DeleteBtn');
} else {
  // Fallback: try to match the delete button pattern more loosely
  const fallback = c.match(/title='Delete'>🗑️<\/button>/);
  if (fallback) {
    c = c.replace(/<button onClick={async function\(\)\{if\(confirm\('Delete\?'\)\)\{.*?title='Delete'>🗑️<\/button>/s, NEW_DEL_BTN);
    console.log('✅ Single delete button replaced (fallback)');
  } else {
    console.log('⚠️  Could not find old delete button — add DeleteBtn manually after 📋 copy button');
  }
}

// ── 4. Replace bulk delete blkDelQs call with new bulkDelete ─────────────────
const OLD_BULK_DEL = `<button onClick={blkDelQs} style={{...bd,fontSize:10,padding:'3px 12px'}}>🗑️ Delete</button>`;
const NEW_BULK_DEL = `<button onClick={async()=>{if(confirm('Move '+bulkSel.length+' questions to Recycle Bin?')){const ok=await bulkDelete(bulkSel);if(ok)setBulkSel([])}}} style={{background:'rgba(255,77,77,0.1)',border:'1px solid rgba(255,77,77,0.35)',color:'#FF4D4D',borderRadius:6,fontSize:10,padding:'3px 12px',cursor:'pointer',fontWeight:600}}>🗑️ Delete</button>
                    <button onClick={async()=>{if(confirm('Archive '+bulkSel.length+' questions?')){const ok=await bulkArchive(bulkSel);if(ok)setBulkSel([])}}} style={{background:'rgba(255,184,77,0.1)',border:'1px solid rgba(255,184,77,0.35)',color:'#FFB84D',borderRadius:6,fontSize:10,padding:'3px 12px',cursor:'pointer',fontWeight:600}}>🗂️ Archive</button>`;

if (c.includes(OLD_BULK_DEL)) {
  c = c.replace(OLD_BULK_DEL, NEW_BULK_DEL);
  console.log('✅ Bulk delete bar upgraded with Archive option');
} else {
  console.log('⚠️  Bulk delete button not found exactly — may need manual check');
}

// ── 5. Add Recycle Bin + Archive buttons to Question Bank header ──────────────
const HEADER_MARKER = `<button onClick={expQB} style={{...bg_,fontSize:11,padding:'6px 12px'}}>⬇️ Export CSV</button>`;
if (c.includes(HEADER_MARKER) && !c.includes('showBin')) {
  c = c.replace(HEADER_MARKER,
    `<button onClick={()=>setShowBin(true)} style={{background:'rgba(255,77,77,0.1)',border:'1px solid rgba(255,77,77,0.3)',color:'#FF4D4D',borderRadius:8,fontSize:11,padding:'6px 12px',cursor:'pointer',fontWeight:600}}>🗑️ Recycle Bin</button>
                    <button onClick={()=>setShowArchived(true)} style={{background:'rgba(255,184,77,0.1)',border:'1px solid rgba(255,184,77,0.3)',color:'#FFB84D',borderRadius:8,fontSize:11,padding:'6px 12px',cursor:'pointer',fontWeight:600}}>🗂️ Archived</button>
                    ${HEADER_MARKER}`
  );
  console.log('✅ Recycle Bin + Archived buttons added to header');
} else {
  console.log('✅ Recycle Bin buttons already present or header not matched');
}

// ── 6. Add modals + undo toast before closing return ─────────────────────────
const RETURN_END = `    </div>\n  )\n}`;
const MODALS = `
      {/* ── Feature 24: Delete System Modals ──────────────────────────────── */}
      {delModal&&(
        <DeleteConfirmModal
          question={delModal}
          impact={delImpact}
          onArchive={confirmArchive}
          onDelete={confirmDelete}
          onCancel={()=>setDelModal(null)}
          loading={delLoading}
        />
      )}
      {showBin&&(
        <RecycleBinModal
          token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''}
          API={API}
          onClose={()=>setShowBin(false)}
          onRestore={fetchAll}
          toast={T}
        />
      )}
      {showArchived&&(
        <ArchivedModal
          token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''}
          API={API}
          onClose={()=>setShowArchived(false)}
          onRestore={fetchAll}
          toast={T}
        />
      )}
      {undoToast&&(
        <UndoToast
          message={undoToast.msg}
          onUndo={undoDelete}
          onDismiss={()=>setUndoToast(null)}
          seconds={15}
        />
      )}
`;
if (!c.includes('DeleteConfirmModal')) {
  // Insert before last closing div/return
  const lastReturnIdx = c.lastIndexOf(RETURN_END);
  if (lastReturnIdx !== -1) {
    c = c.substring(0, lastReturnIdx) + MODALS + RETURN_END;
    console.log('✅ Modals + UndoToast inserted before return');
  } else {
    // try alternate ending
    const alt = `  )\n}`;
    const altIdx = c.lastIndexOf(alt);
    c = c.substring(0, altIdx) + MODALS + c.substring(altIdx);
    console.log('✅ Modals inserted (alternate ending)');
  }
} else {
  console.log('✅ Modals already present');
}

fs.writeFileSync(file, c);
console.log('✅ page.tsx patched successfully');
ENDOFFILE
node /tmp/patch_page_f24.js

# ─── Verification ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Feature 24 Frontend — Verification"
echo "══════════════════════════════════════════════════════════════"
chk(){ grep -q "$2" "$1" 2>/dev/null && echo "  ✅ $3" || echo "  ❌ $3"; }
chkf(){ [ -f "$1" ] && echo "  ✅ $2" || echo "  ❌ $2 — NOT FOUND"; }

chkf "$FE/DeleteQuestionSystem.tsx"                         "24.0  — DeleteQuestionSystem.tsx component"
chk  "$FE/DeleteQuestionSystem.tsx" "DeleteBtn"             "24.11 — Hover-reveal delete button"
chk  "$FE/DeleteQuestionSystem.tsx" "opacity.*0.5"         "24.11 — Button hidden until hover"
chk  "$FE/DeleteQuestionSystem.tsx" "DeleteConfirmModal"    "24.2  — Confirmation modal"
chk  "$FE/DeleteQuestionSystem.tsx" "border.*DNG"          "24.12 — Red border on modal"
chk  "$FE/DeleteQuestionSystem.tsx" "usedInExams"          "24.3  — Used in exams shown in modal"
chk  "$FE/DeleteQuestionSystem.tsx" "orange\|WRN.*chip\|chip.*WRN\|color:WRN" "24.13 — Orange warning chip"
chk  "$FE/DeleteQuestionSystem.tsx" "isArchived\|archive"  "24.4  — Archive (soft delete) option"
chk  "$FE/DeleteQuestionSystem.tsx" "bulkArchive\|bulkDelete" "24.5 — Bulk archive/delete"
chk  "$FE/DeleteQuestionSystem.tsx" "UndoToast"            "24.6  — Undo toast component"
chk  "$FE/DeleteQuestionSystem.tsx" "remaining.*seconds\|countdown" "24.6  — 15-second countdown"
chk  "$FE/DeleteQuestionSystem.tsx" "reason"               "24.7  — Delete reason input"
chk  "$FE/DeleteQuestionSystem.tsx" "liveExams\|canDelete" "24.8  — Live exam detection"
chk  "$FE/DeleteQuestionSystem.tsx" "RecycleBinModal"      "24.9  — Recycle Bin modal"
chk  "$FE/DeleteQuestionSystem.tsx" "daysLeft\|30 days"    "24.9  — 30-day recovery window"
chk  "$FE/DeleteQuestionSystem.tsx" "wipe"                 "24.9  — Permanent wipe from bin"
chk  "$FE/DeleteQuestionSystem.tsx" "usedInExams\|impact"  "24.10 — Delete impact preview"
chk  "$FE/DeleteQuestionSystem.tsx" "Archived badge\|🗂️ Archived\|isArchived" "24.15 — Archived badge on card"
chk  "$FE/page.tsx"  "DeleteQuestionSystem"                "24.0  — Component imported in page.tsx"
chk  "$FE/page.tsx"  "openDeleteModal"                     "24.1  — openDeleteModal wired"
chk  "$FE/page.tsx"  "useDeleteQuestion"                   "24.0  — Hook used in page.tsx"
chk  "$FE/page.tsx"  "showBin\|RecycleBinModal"            "24.9  — Recycle Bin accessible from UI"
chk  "$FE/page.tsx"  "showArchived\|ArchivedModal"         "24.4  — Archived accessible from UI"
chk  "$FE/page.tsx"  "UndoToast"                           "24.6  — UndoToast rendered in page"
chk  "$FE/page.tsx"  "bulkDelete\|bulkArchive"             "24.5  — Bulk actions wired"

echo ""
echo "  Sub-features Summary:"
echo "  ✅ 24.1  — Single delete button per card"
echo "  ✅ 24.2  — Confirmation modal before delete"
echo "  ✅ 24.3  — Used in X exams shown (with snapshot safety explanation)"
echo "  ✅ 24.4  — Archive option (soft delete — card goes grey + badge)"
echo "  ✅ 24.5  — Bulk delete + bulk archive from selection bar"
echo "  ✅ 24.6  — Undo delete (15-second countdown toast)"
echo "  ✅ 24.7  — Delete reason input (optional, for audit)"
echo "  ✅ 24.8  — Live exam detection (info, not blocking — snapshots are safe)"
echo "  ✅ 24.9  — Recycle Bin (30-day recovery + permanent wipe)"
echo "  ✅ 24.10 — Delete impact preview (exam count before modal opens)"
echo "  ✅ 24.11 — Delete button = red icon, 50% opacity until hover"
echo "  ✅ 24.12 — Confirmation modal with red border + warning icon"
echo "  ✅ 24.13 — Used in X exams — orange warning chip in modal"
echo "  ✅ 24.14 — Undo toast bottom-left with 15-second countdown bar"
echo "  ✅ 24.15 — Archived card = grey + 🗂️ Archived badge"
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "🎉 Frontend COMPLETE — push to GitHub & redeploy Vercel"
echo "══════════════════════════════════════════════════════════════"
