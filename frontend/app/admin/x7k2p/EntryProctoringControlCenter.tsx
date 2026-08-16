'use client'
import { useState, useEffect, useCallback } from 'react'

// ══════════════════════════════════════════════════════════════════
// F53–57-B — Entry & Proctoring Control Center (Admin)
// Mounted as its own tab component inside the main Admin Panel
// (frontend/app/admin/x7k2p/page.tsx) — same pattern as other
// standalone tab components in this file.
// ══════════════════════════════════════════════════════════════════

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const BASE = `${API}/api/admin/entry-proctoring`

const CARD = 'rgba(10,16,32,0.92)'
const BORDER = '1px solid rgba(77,159,255,0.16)'
const SUB = 'rgba(180,200,230,0.7)'
const TXT = '#F1F6FC'
const EC = '#4D9FFF'

const TABS = [
  { key: 'overview', label: 'Overview', icon: '🏠' },
  { key: 'waitingRoom', label: 'Waiting Room', icon: '⏳' },
  { key: 'instructions', label: 'Instructions', icon: '📋' },
  { key: 'tnc', label: 'T&C / Consent', icon: '📜' },
  { key: 'webcam', label: 'Webcam', icon: '📷' },
  { key: 'fullscreen', label: 'Fullscreen', icon: '🖥️' },
  { key: 'joinRules', label: 'Join Rules', icon: '🚪' },
  { key: 'broadcasts', label: 'Broadcasts', icon: '📢' },
  { key: 'templates', label: 'Templates', icon: '🗂️' },
  { key: 'preview', label: 'Live Preview', icon: '👁️' },
  { key: 'audit', label: 'Audit & History', icon: '🕵️' },
  { key: 'controlLogs', label: 'Control Logs', icon: '📊' },
] as const
type TabKey = typeof TABS[number]['key']

function tok() { try { return localStorage.getItem('pr_token') || '' } catch { return '' } }
async function api(path: string, opts: any = {}) {
  const r = await fetch(`${BASE}${path}`, {
    ...opts, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok()}`, ...(opts.headers || {}) }
  })
  const d = await r.json().catch(() => ({}))
  if (!r.ok) throw new Error(d.error || `Request failed (${r.status})`)
  return d
}

const card: React.CSSProperties = { background: CARD, border: BORDER, borderRadius: 16, padding: 16, marginBottom: 12 }
const label: React.CSSProperties = { fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8, letterSpacing: 0.4 }
const inputStyle: React.CSSProperties = { padding: '8px 10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 8, color: TXT, fontSize: 12, width: '100%' }
const btn = (active = false): React.CSSProperties => ({ padding: '8px 14px', borderRadius: 9, border: active ? 'none' : '1px solid rgba(77,159,255,0.3)', background: active ? `linear-gradient(135deg,${EC},#2E7FE0)` : 'transparent', color: active ? '#fff' : EC, fontSize: 11, fontWeight: 700, cursor: 'pointer' })

function Toggle({ checked, onChange, label: l }: { checked: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '7px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
      <span style={{ fontSize: 12 }}>{l}</span>
      <button onClick={() => onChange(!checked)} style={{ width: 38, height: 20, borderRadius: 20, border: 'none', cursor: 'pointer', background: checked ? EC : 'rgba(255,255,255,0.14)', position: 'relative', flexShrink: 0 }}>
        <span style={{ position: 'absolute', top: 2, left: checked ? 20 : 2, width: 16, height: 16, borderRadius: '50%', background: '#fff', transition: 'left 0.15s' }} />
      </button>
    </div>
  )
}
function NumField({ value, onChange, label: l, suffix }: { value: number; onChange: (v: number) => void; label: string; suffix?: string }) {
  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{ fontSize: 10, color: SUB, marginBottom: 3 }}>{l}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <input type="number" value={value ?? 0} onChange={e => onChange(Number(e.target.value))} style={inputStyle} />
        {suffix && <span style={{ fontSize: 10, color: SUB }}>{suffix}</span>}
      </div>
    </div>
  )
}

export default function EntryProctoringControlCenter() {
  const [tab, setTab] = useState<TabKey>('overview')
  const [kpis, setKpis] = useState<any>(null)
  const [policies, setPolicies] = useState<any[]>([])
  const [policy, setPolicy] = useState<any>(null)
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [templates, setTemplates] = useState<any[]>([])
  const [broadcasts, setBroadcasts] = useState<any[]>([])
  const [history, setHistory] = useState<any[]>([])
  const [controlLogs, setControlLogs] = useState<any[]>([])
  const [previewMins, setPreviewMins] = useState(20)
  const [previewFlow, setPreviewFlow] = useState<any[]>([])
  const [showCreate, setShowCreate] = useState(false)
  const [newScope, setNewScope] = useState<{ type: string; examId: string; testSeriesId: string; name: string }>({ type: 'global', examId: '', testSeriesId: '', name: '' })
  const [massApplyIds, setMassApplyIds] = useState('')

  const notify = (m: string) => { setToast(m); setTimeout(() => setToast(null), 3000) }

  const loadKpis = useCallback(() => { api('/kpis').then(d => setKpis(d.kpis)).catch(() => {}) }, [])
  const loadPolicies = useCallback(() => { api('/policies').then(d => setPolicies(d.policies || [])).catch(() => {}) }, [])
  const loadTemplates = useCallback(() => { api('/templates').then(d => setTemplates(d.templates || [])).catch(() => {}) }, [])

  useEffect(() => { loadKpis(); loadPolicies(); loadTemplates() }, [loadKpis, loadPolicies, loadTemplates])

  const openPolicy = (id: string) => {
    setLoading(true)
    api(`/policies/${id}`).then(d => setPolicy(d.policy)).catch(e => notify('❌ ' + e.message)).finally(() => setLoading(false))
  }

  useEffect(() => {
    if (!policy?._id) return
    if (tab === 'broadcasts') api(`/policies/${policy._id}/broadcasts`).then(d => setBroadcasts(d.broadcasts || [])).catch(() => {})
    if (tab === 'audit') api(`/policies/${policy._id}/history`).then(d => setHistory(d.history || [])).catch(() => {})
    if (tab === 'controlLogs') api(`/control-logs?examId=${policy.scope?.examId || ''}`).then(d => setControlLogs(d.logs || [])).catch(() => {})
  }, [tab, policy?._id])

  const createPolicy = async () => {
    try {
      const scope: any = { type: newScope.type }
      if (newScope.type === 'exam') scope.examId = newScope.examId
      if (newScope.type === 'series') scope.testSeriesId = newScope.testSeriesId
      const d = await api('/policies', { method: 'POST', body: JSON.stringify({ name: newScope.name || undefined, scope }) })
      notify('✅ Policy created')
      setShowCreate(false)
      loadPolicies()
      setPolicy(d.policy)
    } catch (e: any) { notify('❌ ' + e.message) }
  }

  const saveSection = async (section: string, value: any) => {
    if (!policy?._id) return
    try {
      const d = await api(`/policies/${policy._id}`, { method: 'PUT', body: JSON.stringify({ [section]: value, reason }) })
      setPolicy(d.policy)
      notify('✅ Saved')
    } catch (e: any) { notify('❌ ' + e.message) }
  }

  const patchLocal = (section: string, patch: any) => setPolicy((p: any) => ({ ...p, [section]: { ...(p[section] || {}), ...patch } }))

  const publish = async () => {
    if (!policy?._id) return
    try { const d = await api(`/policies/${policy._id}/publish`, { method: 'POST', body: JSON.stringify({ reason }) }); setPolicy(d.policy); notify('🚀 Published'); loadKpis(); loadPolicies() }
    catch (e: any) { notify('❌ ' + e.message) }
  }
  const cloneIt = async () => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/clone`, { method: 'POST' }); notify('✅ Cloned'); loadPolicies(); setPolicy(d.policy) } catch (e: any) { notify('❌ ' + e.message) } }
  const lockIt = async (v: boolean) => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/${v ? 'lock' : 'unlock'}`, { method: 'POST' }); setPolicy(d.policy); notify(v ? '🔒 Locked' : '🔓 Unlocked') } catch (e: any) { notify('❌ ' + e.message) } }
  const rollback = async (version: number) => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/rollback/${version}`, { method: 'POST' }); setPolicy(d.policy); notify(`↩️ Rolled back to v${version}`) } catch (e: any) { notify('❌ ' + e.message) } }
  const emergency = async (action: string) => { if (!policy?._id) return; try { await api(`/policies/${policy._id}/emergency-override`, { method: 'POST', body: JSON.stringify({ action }) }); notify('⚡ Override sent: ' + action) } catch (e: any) { notify('❌ ' + e.message) } }
  const applyTemplate = async (templateId: string) => { if (!policy?._id) return; try { const d = await api(`/templates/${templateId}/apply/${policy._id}`, { method: 'POST' }); setPolicy(d.policy); notify('✅ Template applied') } catch (e: any) { notify('❌ ' + e.message) } }
  const massApply = async () => {
    if (!policy?._id) return
    const examIds = massApplyIds.split(',').map(s => s.trim()).filter(Boolean)
    if (!examIds.length) return notify('⚠️ Enter at least one exam ID')
    try { const d = await api(`/policies/${policy._id}/mass-apply`, { method: 'POST', body: JSON.stringify({ examIds }) }); notify(`✅ Applied to ${d.results.filter((r: any) => r.success).length}/${examIds.length} exam(s)`) }
    catch (e: any) { notify('❌ ' + e.message) }
  }
  const runPreview = async () => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/preview`, { method: 'POST', body: JSON.stringify({ minutesBeforeStart: previewMins }) }); setPreviewFlow(d.flow || []) } catch (e: any) { notify('❌ ' + e.message) } }
  const sendBroadcast = async (form: any) => {
    if (!policy?._id) return
    try {
      await api('/broadcasts', { method: 'POST', body: JSON.stringify({ examId: policy.scope?.examId, broadcastType: form.type, title: form.title, message: form.message, channel: form.channel }) })
      notify('📢 Broadcast sent'); api(`/policies/${policy._id}/broadcasts`).then(d => setBroadcasts(d.broadcasts || []))
    } catch (e: any) { notify('❌ ' + e.message) }
  }

  const readiness = policy?.readinessScore ?? 0
  const warnings: string[] = policy?.warnings || []

  return (
    <div style={{ minHeight: '100vh', color: TXT, fontFamily: 'Inter,sans-serif', padding: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14, flexWrap: 'wrap', gap: 10 }}>
        <div>
          <div style={{ fontSize: 20, fontWeight: 800 }}>🛡️ Entry & Proctoring Control Center</div>
          <div style={{ fontSize: 11, color: SUB }}>Waiting Room · Instructions · T&C · Webcam · Fullscreen · Join Rules — centralised</div>
        </div>
        <button onClick={() => setShowCreate(true)} style={btn(true)}>+ Create New Policy</button>
      </div>

      {/* ── 2) KPI CARDS ── */}
      {kpis && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 8, marginBottom: 14 }}>
          {[
            ['Active Policies', kpis.activeExamPolicies], ['Waiting Room ON', kpis.waitingRoomEnabled],
            ['Instructions Published', kpis.instructionsPublished], ['T&C Active', kpis.tncActiveVersions],
            ['Webcam Mandatory', kpis.webcamMandatoryExams], ['Fullscreen ON', kpis.fullscreenEnabledExams],
            ['Live Join Blocks (7d)', kpis.liveJoinBlocks7d], ['Changes Today', kpis.policyChangesToday],
          ].map(([l, v], i) => (
            <div key={i} style={{ ...card, textAlign: 'center', marginBottom: 0, padding: 12 }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: EC }}>{v as any}</div>
              <div style={{ fontSize: 9, color: SUB, marginTop: 2 }}>{l as any}</div>
            </div>
          ))}
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: '260px 1fr', gap: 14 }}>
        {/* ── POLICY LIST ── */}
        <div>
          <div style={card}>
            <div style={label}>Policies ({policies.length})</div>
            {policies.map(p => (
              <div key={p._id} onClick={() => openPolicy(p._id)}
                style={{ padding: '8px 10px', borderRadius: 8, marginBottom: 5, cursor: 'pointer', background: policy?._id === p._id ? `${EC}20` : 'rgba(255,255,255,0.03)', border: `1px solid ${policy?._id === p._id ? EC + '50' : 'transparent'}` }}>
                <div style={{ fontSize: 11, fontWeight: 700 }}>{p.name}</div>
                <div style={{ fontSize: 9, color: SUB }}>{p.scope?.type} · {p.status} · v{p.version} · {p.readinessScore}% ready</div>
              </div>
            ))}
            {policies.length === 0 && <div style={{ fontSize: 11, color: SUB }}>No policies yet. Create one to get started.</div>}
          </div>
        </div>

        {/* ── SELECTED POLICY WORKSPACE ── */}
        <div>
          {!policy ? (
            <div style={{ ...card, textAlign: 'center', padding: 40 }}>Select or create a policy to begin.</div>
          ) : (
            <>
              <div style={card}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
                  <div>
                    <div style={{ fontSize: 15, fontWeight: 800 }}>{policy.name}</div>
                    <div style={{ fontSize: 10, color: SUB }}>Scope: {policy.scope?.type} · Status: <b style={{ color: policy.status === 'published' ? '#27AE60' : '#F5A623' }}>{policy.status}</b> · v{policy.version}{policy.locked && ' · 🔒 Locked'}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                    <button onClick={cloneIt} style={btn()}>Clone</button>
                    <button onClick={() => lockIt(!policy.locked)} style={btn()}>{policy.locked ? 'Unlock' : 'Lock'}</button>
                    <button onClick={publish} style={btn(true)}>Publish</button>
                  </div>
                </div>
                <div style={{ marginTop: 10 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: SUB, marginBottom: 4 }}>
                    <span>Readiness Score</span><span>{readiness}%</span>
                  </div>
                  <div style={{ height: 6, background: 'rgba(255,255,255,0.08)', borderRadius: 4, overflow: 'hidden' }}>
                    <div style={{ width: `${readiness}%`, height: '100%', background: readiness >= 80 ? '#27AE60' : readiness >= 50 ? '#F5A623' : '#E74C3C' }} />
                  </div>
                  {warnings.length > 0 && <div style={{ marginTop: 8, fontSize: 10, color: '#F5A623' }}>{warnings.map((w, i) => <div key={i}>⚠️ {w}</div>)}</div>}
                </div>
                <input placeholder="Reason for this change (optional, saved to audit log)" value={reason} onChange={e => setReason(e.target.value)} style={{ ...inputStyle, marginTop: 10 }} />
                <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
                  <span style={{ fontSize: 9, color: SUB }}>Emergency Override:</span>
                  {['open_waiting_room_now', 'close_waiting_room', 'skip_to_instructions', 'skip_to_permission_check', 'force_exam_start'].map(a => (
                    <button key={a} onClick={() => emergency(a)} style={{ ...btn(), fontSize: 9, padding: '5px 8px' }}>{a.replace(/_/g, ' ')}</button>
                  ))}
                </div>
                <div style={{ display: 'flex', gap: 6, marginTop: 8, alignItems: 'center' }}>
                  <input placeholder="Mass apply → exam IDs (comma-separated)" value={massApplyIds} onChange={e => setMassApplyIds(e.target.value)} style={inputStyle} />
                  <button onClick={massApply} style={{ ...btn(), whiteSpace: 'nowrap' }}>Mass Apply</button>
                </div>
              </div>

              {/* ── SECTION TABS ── */}
              <div style={{ display: 'flex', gap: 5, overflowX: 'auto', marginBottom: 10, paddingBottom: 4 }}>
                {TABS.filter(t => t.key !== 'overview').map(t => (
                  <button key={t.key} onClick={() => setTab(t.key)} style={{ ...btn(tab === t.key), whiteSpace: 'nowrap', flexShrink: 0 }}>{t.icon} {t.label}</button>
                ))}
              </div>

              {tab === 'waitingRoom' && policy.waitingRoom && (
                <div style={card}>
                  <div style={label}>Waiting Room Control (5)</div>
                  <Toggle label="Waiting Room ON/OFF" checked={policy.waitingRoom.enabled} onChange={v => patchLocal('waitingRoom', { enabled: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Preset trigger (min before exam)" value={policy.waitingRoom.presetMinutes} onChange={v => patchLocal('waitingRoom', { presetMinutes: v })} suffix="min" />
                    <NumField label="Custom trigger (min)" value={policy.waitingRoom.customMinutes} onChange={v => patchLocal('waitingRoom', { customMinutes: v })} suffix="min" />
                  </div>
                  <Toggle label="Countdown Display" checked={policy.waitingRoom.countdownDisplay} onChange={v => patchLocal('waitingRoom', { countdownDisplay: v })} />
                  <Toggle label="Live Student Count" checked={policy.waitingRoom.liveStudentCount} onChange={v => patchLocal('waitingRoom', { liveStudentCount: v })} />
                  <Toggle label="Student Join Access" checked={policy.waitingRoom.studentJoinAccess} onChange={v => patchLocal('waitingRoom', { studentJoinAccess: v })} />
                  <Toggle label="Admin Broadcast Access" checked={policy.waitingRoom.adminBroadcastAccess} onChange={v => patchLocal('waitingRoom', { adminBroadcastAccess: v })} />
                  <Toggle label="Tips Rotation" checked={policy.waitingRoom.tipsRotation} onChange={v => patchLocal('waitingRoom', { tipsRotation: v })} />
                  <Toggle label="Background Music Toggle" checked={policy.waitingRoom.musicToggle} onChange={v => patchLocal('waitingRoom', { musicToggle: v })} />
                  <Toggle label="Chat Enabled" checked={policy.waitingRoom.chatEnabled} onChange={v => patchLocal('waitingRoom', { chatEnabled: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Chat Start (min before exam)" value={policy.waitingRoom.chatStartOffsetMin} onChange={v => patchLocal('waitingRoom', { chatStartOffsetMin: v })} suffix="min" />
                    <NumField label="Chat End (min before exam)" value={policy.waitingRoom.chatEndOffsetMin} onChange={v => patchLocal('waitingRoom', { chatEndOffsetMin: v })} suffix="min" />
                  </div>
                  <Toggle label="Admin Chat Only Mode" checked={policy.waitingRoom.adminChatOnlyMode} onChange={v => patchLocal('waitingRoom', { adminChatOnlyMode: v })} />
                  <Toggle label="Auto Transition to Instructions" checked={policy.waitingRoom.autoTransitionToInstructions} onChange={v => patchLocal('waitingRoom', { autoTransitionToInstructions: v })} />
                  <Toggle label="Show Seconds" checked={policy.waitingRoom.showSeconds} onChange={v => patchLocal('waitingRoom', { showSeconds: v })} />
                  <Toggle label="Show Progress Bar" checked={policy.waitingRoom.showProgressBar} onChange={v => patchLocal('waitingRoom', { showProgressBar: v })} />
                  <Toggle label="Server Time Sync" checked={policy.waitingRoom.serverTimeSync} onChange={v => patchLocal('waitingRoom', { serverTimeSync: v })} />

                  <div style={{ ...label, marginTop: 14 }}>Instructions Trigger (5.5.1.3)</div>
                  <Toggle label="Auto Open Instructions" checked={policy.instructionsTrigger?.autoOpen} onChange={v => patchLocal('instructionsTrigger', { autoOpen: v })} />
                  <NumField label="Trigger before exam" value={policy.instructionsTrigger?.presetMinutesBeforeExam} onChange={v => patchLocal('instructionsTrigger', { presetMinutesBeforeExam: v })} suffix="min" />

                  <div style={{ ...label, marginTop: 14 }}>Permission Check Trigger (5.5.1.4)</div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                    <NumField label="Webcam Check" value={policy.permissionCheckTrigger?.webcamCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { webcamCheckOffsetMin: v })} suffix="min before" />
                    <NumField label="Mic Check" value={policy.permissionCheckTrigger?.micCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { micCheckOffsetMin: v })} suffix="min before" />
                    <NumField label="Fullscreen Check" value={policy.permissionCheckTrigger?.fullscreenCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { fullscreenCheckOffsetMin: v })} suffix="min before" />
                    <NumField label="Device Check" value={policy.permissionCheckTrigger?.deviceCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { deviceCheckOffsetMin: v })} suffix="min before" />
                  </div>

                  <div style={{ ...label, marginTop: 14 }}>Late Join Rules (5.5.1.7)</div>
                  <Toggle label="Allow Late Join" checked={policy.lateJoin?.allowLateJoin} onChange={v => patchLocal('lateJoin', { allowLateJoin: v })} />
                  <NumField label="Grace Duration" value={policy.lateJoin?.graceMinutes} onChange={v => patchLocal('lateJoin', { graceMinutes: v })} suffix="min" />
                  <Toggle label="Lock Entry After Grace" checked={policy.lateJoin?.lockEntryAfterGrace} onChange={v => patchLocal('lateJoin', { lockEntryAfterGrace: v })} />
                  <Toggle label="Allow Rejoin" checked={policy.lateJoin?.allowRejoin} onChange={v => patchLocal('lateJoin', { allowRejoin: v })} />
                  <NumField label="Rejoin Window" value={policy.lateJoin?.rejoinWindowMinutes} onChange={v => patchLocal('lateJoin', { rejoinWindowMinutes: v })} suffix="min" />

                  <div style={{ ...label, marginTop: 14 }}>Waiting Room Lock (5.5.1.8)</div>
                  <Toggle label="Lock Waiting Room" checked={policy.waitingRoomLock?.lockWaitingRoom} onChange={v => patchLocal('waitingRoomLock', { lockWaitingRoom: v })} />
                  <Toggle label="Force Student To Stay" checked={policy.waitingRoomLock?.forceStudentToStay} onChange={v => patchLocal('waitingRoomLock', { forceStudentToStay: v })} />
                  <Toggle label="Disable Navigation" checked={policy.waitingRoomLock?.disableNavigation} onChange={v => patchLocal('waitingRoomLock', { disableNavigation: v })} />
                  <Toggle label="Prevent Browser Refresh" checked={policy.waitingRoomLock?.preventBrowserRefresh} onChange={v => patchLocal('waitingRoomLock', { preventBrowserRefresh: v })} />
                  <Toggle label="Auto Reconnect" checked={policy.waitingRoomLock?.autoReconnect} onChange={v => patchLocal('waitingRoomLock', { autoReconnect: v })} />

                  <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                    <button onClick={() => saveSection('waitingRoom', policy.waitingRoom)} style={btn(true)}>Save Waiting Room</button>
                    <button onClick={() => { saveSection('instructionsTrigger', policy.instructionsTrigger); saveSection('permissionCheckTrigger', policy.permissionCheckTrigger); saveSection('lateJoin', policy.lateJoin); saveSection('waitingRoomLock', policy.waitingRoomLock) }} style={btn()}>Save Related Rules</button>
                  </div>
                </div>
              )}

              {tab === 'instructions' && policy.instructions && (
                <div style={card}>
                  <div style={label}>Instructions Manager (6)</div>
                  <Toggle label="Published" checked={policy.instructions.published} onChange={v => patchLocal('instructions', { published: v })} />
                  {(policy.instructions.points || []).map((pt: any, i: number) => (
                    <div key={pt.id || i} style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 8, padding: 8, marginBottom: 6 }}>
                      <div style={{ display: 'flex', gap: 6, marginBottom: 4 }}>
                        <input value={pt.text} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, text: e.target.value }; patchLocal('instructions', { points: pts }) }} placeholder="Instruction text (English)" style={inputStyle} />
                        <button onClick={() => { const pts = policy.instructions.points.filter((_: any, j: number) => j !== i); patchLocal('instructions', { points: pts }) }} style={{ ...btn(), padding: '4px 8px' }}>✕</button>
                      </div>
                      <input value={pt.textHi} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, textHi: e.target.value }; patchLocal('instructions', { points: pts }) }} placeholder="Instruction text (Hindi)" style={{ ...inputStyle, marginBottom: 4 }} />
                      <div style={{ display: 'flex', gap: 12, fontSize: 10 }}>
                        <label><input type="checkbox" checked={pt.mandatory} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, mandatory: e.target.checked }; patchLocal('instructions', { points: pts }) }} /> Mandatory</label>
                        <label><input type="checkbox" checked={pt.warning} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, warning: e.target.checked }; patchLocal('instructions', { points: pts }) }} /> Warning</label>
                        <label><input type="checkbox" checked={pt.bilingual} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, bilingual: e.target.checked }; patchLocal('instructions', { points: pts }) }} /> Bilingual</label>
                        <button onClick={() => { if (i === 0) return; const pts = [...policy.instructions.points]; [pts[i - 1], pts[i]] = [pts[i], pts[i - 1]]; patchLocal('instructions', { points: pts }) }} style={{ background: 'none', border: 'none', color: SUB, cursor: 'pointer' }}>↑</button>
                        <button onClick={() => { if (i === policy.instructions.points.length - 1) return; const pts = [...policy.instructions.points]; [pts[i + 1], pts[i]] = [pts[i], pts[i + 1]]; patchLocal('instructions', { points: pts }) }} style={{ background: 'none', border: 'none', color: SUB, cursor: 'pointer' }}>↓</button>
                        <button onClick={() => { const pts = [...policy.instructions.points, { ...pt, id: undefined }]; patchLocal('instructions', { points: pts }) }} style={{ background: 'none', border: 'none', color: EC, cursor: 'pointer' }}>⧉ Duplicate</button>
                      </div>
                    </div>
                  ))}
                  <button onClick={() => patchLocal('instructions', { points: [...(policy.instructions.points || []), { text: '', textHi: '', type: 'custom', mandatory: false, warning: false, bilingual: true, order: (policy.instructions.points || []).length }] })} style={{ ...btn(), marginTop: 6 }}>+ Add Instruction</button>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('instructions', policy.instructions)} style={btn(true)}>Save Instructions</button></div>
                </div>
              )}

              {tab === 'tnc' && policy.tnc && (
                <div style={card}>
                  <div style={label}>T&C / Consent Manager (7)</div>
                  <div style={{ fontSize: 10, color: SUB, marginBottom: 4 }}>Version label: {policy.tnc.version}</div>
                  <textarea value={policy.tnc.text} onChange={e => patchLocal('tnc', { text: e.target.value })} placeholder="T&C text (English)" rows={5} style={{ ...inputStyle, marginBottom: 8 }} />
                  <textarea value={policy.tnc.textHi} onChange={e => patchLocal('tnc', { textHi: e.target.value })} placeholder="T&C text (Hindi)" rows={5} style={{ ...inputStyle, marginBottom: 8 }} />
                  <input value={policy.tnc.version} onChange={e => patchLocal('tnc', { version: e.target.value })} placeholder="Version label e.g. 1.0" style={{ ...inputStyle, marginBottom: 8 }} />
                  <Toggle label="Require Scroll to Bottom" checked={policy.tnc.requireScroll} onChange={v => patchLocal('tnc', { requireScroll: v })} />
                  <Toggle label="Require Checkbox Confirmation" checked={policy.tnc.requireCheckbox} onChange={v => patchLocal('tnc', { requireCheckbox: v })} />
                  <Toggle label="Require Re-Accept on Update" checked={policy.tnc.requireReacceptOnUpdate} onChange={v => patchLocal('tnc', { requireReacceptOnUpdate: v })} />
                  <Toggle label="Published" checked={policy.tnc.published} onChange={v => patchLocal('tnc', { published: v })} />
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('tnc', policy.tnc)} style={btn(true)}>Save T&C</button></div>
                </div>
              )}

              {tab === 'webcam' && policy.webcam && (
                <div style={card}>
                  <div style={label}>Webcam Permission Control (8)</div>
                  <Toggle label="Camera Mandatory" checked={policy.webcam.mandatory} onChange={v => patchLocal('webcam', { mandatory: v })} />
                  <Toggle label="Live Preview Required" checked={policy.webcam.livePreviewRequired} onChange={v => patchLocal('webcam', { livePreviewRequired: v })} />
                  <Toggle label="Face Visible Required" checked={policy.webcam.faceVisibleRequired} onChange={v => patchLocal('webcam', { faceVisibleRequired: v })} />
                  <Toggle label="Multiple Face Alert" checked={policy.webcam.multiFaceAlert} onChange={v => patchLocal('webcam', { multiFaceAlert: v })} />
                  <Toggle label="Virtual Background Block" checked={policy.webcam.virtualBackgroundBlock} onChange={v => patchLocal('webcam', { virtualBackgroundBlock: v })} />
                  <Toggle label="Retry Allowed" checked={policy.webcam.retryAllowed} onChange={v => patchLocal('webcam', { retryAllowed: v })} />
                  <Toggle label="Optional Audio Permission" checked={policy.webcam.optionalAudioPermission} onChange={v => patchLocal('webcam', { optionalAudioPermission: v })} />
                  <Toggle label="Block on Denial" checked={policy.webcam.blockOnDenial} onChange={v => patchLocal('webcam', { blockOnDenial: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Lighting Warning Threshold" value={policy.webcam.lightingWarningThreshold} onChange={v => patchLocal('webcam', { lightingWarningThreshold: v })} suffix="/100" />
                    <NumField label="Min Confidence Threshold" value={policy.webcam.minConfidenceThreshold} onChange={v => patchLocal('webcam', { minConfidenceThreshold: v })} suffix="/100" />
                    <NumField label="Retry Count" value={policy.webcam.retryCount} onChange={v => patchLocal('webcam', { retryCount: v })} />
                    <NumField label="Retry Delay" value={policy.webcam.retryDelaySec} onChange={v => patchLocal('webcam', { retryDelaySec: v })} suffix="sec" />
                    <NumField label="Live Preview Duration" value={policy.webcam.showLivePreviewDurationSec} onChange={v => patchLocal('webcam', { showLivePreviewDurationSec: v })} suffix="sec" />
                  </div>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('webcam', policy.webcam)} style={btn(true)}>Save Webcam Policy</button></div>
                </div>
              )}

              {tab === 'fullscreen' && policy.fullscreen && (
                <div style={card}>
                  <div style={label}>Fullscreen Enforcement (9)</div>
                  <Toggle label="Fullscreen ON/OFF" checked={policy.fullscreen.enabled} onChange={v => patchLocal('fullscreen', { enabled: v })} />
                  <Toggle label="Auto Fullscreen on Start" checked={policy.fullscreen.autoFullscreenOnStart} onChange={v => patchLocal('fullscreen', { autoFullscreenOnStart: v })} />
                  <Toggle label="Return-to-Fullscreen Prompt" checked={policy.fullscreen.returnPrompt} onChange={v => patchLocal('fullscreen', { returnPrompt: v })} />
                  <Toggle label="Exit Reporting Enabled" checked={policy.fullscreen.exitReportingEnabled} onChange={v => patchLocal('fullscreen', { exitReportingEnabled: v })} />
                  <Toggle label="Auto-Submit Linkage" checked={policy.fullscreen.autoSubmitLinkage} onChange={v => patchLocal('fullscreen', { autoSubmitLinkage: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Warning Threshold (count)" value={policy.fullscreen.warningThreshold} onChange={v => patchLocal('fullscreen', { warningThreshold: v })} />
                    <NumField label="Grace Period" value={policy.fullscreen.gracePeriodSec} onChange={v => patchLocal('fullscreen', { gracePeriodSec: v })} suffix="sec" />
                  </div>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('fullscreen', policy.fullscreen)} style={btn(true)}>Save Fullscreen Policy</button></div>
                </div>
              )}

              {tab === 'joinRules' && policy.joinRules && (
                <div style={card}>
                  <div style={label}>Join Rules & Availability Engine (10)</div>
                  <NumField label="Join Grace Minutes" value={policy.joinRules.joinGraceMinutes} onChange={v => patchLocal('joinRules', { joinGraceMinutes: v })} suffix="min" />
                  <Toggle label="Block New Join While Live" checked={policy.joinRules.blockNewJoinWhileLive} onChange={v => patchLocal('joinRules', { blockNewJoinWhileLive: v })} />
                  <Toggle label="Re-Attempt Availability" checked={policy.joinRules.reAttemptAvailability} onChange={v => patchLocal('joinRules', { reAttemptAvailability: v })} />
                  <Toggle label="Emergency Access Override" checked={policy.joinRules.emergencyAccessOverride} onChange={v => patchLocal('joinRules', { emergencyAccessOverride: v })} />
                  <div style={{ fontSize: 10, color: SUB, margin: '8px 0 4px' }}>Availability After End</div>
                  <select value={policy.joinRules.availabilityAfterEnd} onChange={e => patchLocal('joinRules', { availabilityAfterEnd: e.target.value })} style={inputStyle}>
                    <option value="locked">Locked</option>
                    <option value="available_if_attempts_left">Available if attempts left</option>
                  </select>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('joinRules', policy.joinRules)} style={btn(true)}>Save Join Rules</button></div>
                </div>
              )}

              {tab === 'broadcasts' && (
                <BroadcastsPanel broadcasts={broadcasts} onSend={sendBroadcast} />
              )}

              {tab === 'templates' && (
                <div style={card}>
                  <div style={label}>Policy Templates (12)</div>
                  {templates.map(t => (
                    <div key={t._id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                      <div><span style={{ marginRight: 6 }}>{t.icon}</span><b style={{ fontSize: 12 }}>{t.name}</b>{t.isBuiltIn && <span style={{ fontSize: 8, color: SUB, marginLeft: 6 }}>BUILT-IN</span>}<div style={{ fontSize: 10, color: SUB }}>{t.description}</div></div>
                      <button onClick={() => applyTemplate(t._id)} style={btn()}>Apply</button>
                    </div>
                  ))}
                </div>
              )}

              {tab === 'preview' && (
                <div style={card}>
                  <div style={label}>Live Preview / Simulator (13)</div>
                  <NumField label="Simulate: minutes before exam start" value={previewMins} onChange={setPreviewMins} suffix="min" />
                  <button onClick={runPreview} style={btn(true)}>▶ Run Simulation</button>
                  <div style={{ marginTop: 12 }}>
                    {previewFlow.map((s, i) => (
                      <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '7px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                        <span style={{ fontSize: 12 }}>{s.label}</span>
                        <span style={{ fontSize: 10, fontWeight: 700, color: s.state === 'active' ? '#27AE60' : s.state === 'done' ? SUB : s.state === 'skipped' ? '#E74C3C' : '#F5A623' }}>{s.state}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {tab === 'audit' && (
                <div style={card}>
                  <div style={label}>Audit & Version History (14)</div>
                  {history.map((h, i) => (
                    <div key={i} style={{ padding: '8px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                      <div style={{ fontSize: 11 }}><b>{h.section}</b> changed by {h.changedByName || 'admin'} — v{h.version}</div>
                      <div style={{ fontSize: 9, color: SUB }}>{new Date(h.changedAt).toLocaleString()} {h.reason && `· ${h.reason}`}</div>
                      {h.snapshot && <button onClick={() => rollback(h.version)} style={{ ...btn(), fontSize: 9, marginTop: 4 }}>↩️ Rollback to v{h.version}</button>}
                    </div>
                  ))}
                  {history.length === 0 && <div style={{ fontSize: 11, color: SUB }}>No changes recorded yet.</div>}
                </div>
              )}

              {tab === 'controlLogs' && (
                <div style={card}>
                  <div style={label}>Control Logs (15)</div>
                  <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', fontSize: 10, borderCollapse: 'collapse' }}>
                      <thead><tr style={{ textAlign: 'left', color: SUB }}><th>Time</th><th>Event</th><th>Severity</th><th>Status</th><th>Student</th></tr></thead>
                      <tbody>
                        {controlLogs.map((l, i) => (
                          <tr key={i} style={{ borderTop: '1px solid rgba(77,159,255,0.06)' }}>
                            <td style={{ padding: '5px 4px' }}>{new Date(l.createdAt).toLocaleString()}</td>
                            <td>{l.eventType}</td>
                            <td style={{ color: l.severity === 'critical' ? '#E74C3C' : l.severity === 'warning' ? '#F5A623' : SUB }}>{l.severity}</td>
                            <td>{l.status}</td>
                            <td>{l.studentId?.name || '—'}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                    {controlLogs.length === 0 && <div style={{ fontSize: 11, color: SUB, padding: 10 }}>No events logged yet.</div>}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {/* ── CREATE POLICY MODAL ── */}
      {showCreate && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div style={{ ...card, width: 360, marginBottom: 0 }}>
            <div style={label}>Create New Policy</div>
            <input placeholder="Policy name (optional)" value={newScope.name} onChange={e => setNewScope(s => ({ ...s, name: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />
            <select value={newScope.type} onChange={e => setNewScope(s => ({ ...s, type: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }}>
              <option value="global">Global Default</option>
              <option value="exam">Single Exam</option>
              <option value="series">Test Series</option>
            </select>
            {newScope.type === 'exam' && <input placeholder="Exam ID" value={newScope.examId} onChange={e => setNewScope(s => ({ ...s, examId: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />}
            {newScope.type === 'series' && <input placeholder="Test Series ID" value={newScope.testSeriesId} onChange={e => setNewScope(s => ({ ...s, testSeriesId: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />}
            <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
              <button onClick={createPolicy} style={btn(true)}>Create</button>
              <button onClick={() => setShowCreate(false)} style={btn()}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {toast && <div style={{ position: 'fixed', bottom: 24, left: '50%', transform: 'translateX(-50%)', zIndex: 2000, background: 'rgba(20,20,35,0.96)', border: '1px solid rgba(77,159,255,0.35)', borderRadius: 12, padding: '10px 18px', fontSize: 12, fontWeight: 600 }}>{toast}</div>}
    </div>
  )
}

function BroadcastsPanel({ broadcasts, onSend }: { broadcasts: any[]; onSend: (f: any) => void }) {
  const [form, setForm] = useState({ type: 'waiting_room_announcement', title: '', message: '', channel: 'in-app' })
  return (
    <div style={card}>
      <div style={label}>Broadcasts & Notifications (11)</div>
      <select value={form.type} onChange={e => setForm(f => ({ ...f, type: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }}>
        <option value="waiting_room_announcement">Waiting Room Announcement</option>
        <option value="instruction_update">Instruction Update</option>
        <option value="consent_reminder">Consent Reminder</option>
        <option value="camera_reminder">Camera Reminder</option>
        <option value="fullscreen_reminder">Fullscreen Reminder</option>
        <option value="join_window_warning">Join Window Warning</option>
        <option value="emergency_notice">Emergency Notice</option>
      </select>
      <input placeholder="Title" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />
      <textarea placeholder="Message" value={form.message} onChange={e => setForm(f => ({ ...f, message: e.target.value }))} rows={3} style={{ ...inputStyle, marginBottom: 8 }} />
      <select value={form.channel} onChange={e => setForm(f => ({ ...f, channel: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }}>
        <option value="in-app">In-app Banner</option>
        <option value="waiting_room_popup">Waiting Room Popup</option>
        <option value="notification_center">Notification Center</option>
        <option value="email">Email</option>
      </select>
      <button onClick={() => { onSend(form); setForm({ ...form, title: '', message: '' }) }} style={btn(true)}>📢 Send Broadcast</button>
      <div style={{ marginTop: 14 }}>
        {broadcasts.map((b, i) => (
          <div key={i} style={{ padding: '7px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
            <div style={{ fontSize: 11, fontWeight: 700 }}>{b.title}</div>
            <div style={{ fontSize: 9, color: SUB }}>{b.entryContext?.broadcastType} · {b.status} · {new Date(b.createdAt).toLocaleString()}</div>
          </div>
        ))}
        {broadcasts.length === 0 && <div style={{ fontSize: 11, color: SUB }}>No broadcasts sent yet for this exam.</div>}
      </div>
    </div>
  )
}

