'use client'
import { useState, useEffect, useRef, useMemo, createContext, useContext } from 'react'
import CopyBtn from '@/components/CopyBtn'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Theme comes from the Admin Panel's shared constants (CRD/ACC/BOR/TS/DIM/
//    SUC/DNG/WRN/GOLD), passed in via the `theme` prop from page.tsx. Falls
//    back to sensible defaults if not provided so the component never breaks. ──
const DEFAULT_THEME = {
  CRD: 'rgba(0,22,40,0.78)', ACC: '#4D9FFF', BOR: 'rgba(77,159,255,0.18)',
  TS: '#E8F4FD', DIM: '#8899AA', SUC: '#00C48C', DNG: '#FF4D4D', WRN: '#FFB84D', GOLD: '#FFD700',
}
const ThemeCtx = createContext(DEFAULT_THEME)

const SECTIONS = [
  { id: 'personal',  ico:'👤', lbl:'Personal Details' },
  { id: 'academic',  ico:'🎓', lbl:'Academic Profile' },
  { id: 'security',  ico:'🔒', lbl:'Security' },
  { id: 'login',     ico:'📶', lbl:'Login Activity' },
  { id: 'photos',    ico:'🖼️', lbl:'Photo History' },
  { id: 'identity',  ico:'🛡️', lbl:'Identity & Verification' },
  { id: 'versioned', ico:'🗂️', lbl:'Versioned Field History' },
  { id: 'frequency', ico:'📊', lbl:'Change Frequency' },
  { id: 'quick',     ico:'⚡', lbl:'Quick Inspect' },
]

const TIMELINE_FILTERS = [
  { id:'all', lbl:'All' },
  { id:'personal', lbl:'Personal Info' },
  { id:'academic', lbl:'Academic Info' },
  { id:'security', lbl:'Security' },
  { id:'login', lbl:'Login Activity' },
  { id:'photo', lbl:'Photo Changes' },
]
const PERSONAL_FIELDS = ['name','phone','dob','gender','state','city','bio','avatar']
const ACADEMIC_FIELDS = ['targetExam','targetYear','board','school','medium','coachingInstitute','yearOfAppearing']

function fmt(d:any) { if (!d) return '—'; try { return new Date(d).toLocaleString('en-IN',{day:'2-digit',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit'}) } catch { return '—' } }
function fmtDate(d:any) { if (!d) return '—'; try { return new Date(d).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}) } catch { return '—' } }

function Badge({ children, col, bg }: any) {
  const theme = useContext(ThemeCtx)
  const c = col || theme.ACC
  return <span style={{fontSize:9.5,fontWeight:700,color:c,background:bg||`${c}22`,padding:'2px 8px',borderRadius:6,border:`1px solid ${c}44`}}>{children}</span>
}
function Card({ title, icon, children, id }: any) {
  const theme = useContext(ThemeCtx)
  return (
    <div id={id} style={{background:theme.CRD,border:`1px solid ${theme.BOR}`,borderRadius:16,padding:'16px 16px',marginBottom:14,scrollMarginTop:80}}>
      {title && <div style={{fontSize:13,fontWeight:700,color:theme.ACC,marginBottom:12,display:'flex',alignItems:'center',gap:7}}>{icon} {title}</div>}
      {children}
    </div>
  )
}
function Row({ label, value }: any) {
  const theme = useContext(ThemeCtx)
  return (
    <div style={{display:'flex',justifyContent:'space-between',gap:10,padding:'7px 0',borderBottom:`1px solid ${theme.BOR}`,fontSize:12}}>
      <span style={{color:theme.DIM}}>{label}</span>
      <span style={{color:theme.TS,fontWeight:600,textAlign:'right'}}>{value ?? '—'}</span>
    </div>
  )
}

export default function Student360Preview({ studentId, token, onClose, theme }: { studentId: string; token: string; onClose: () => void; theme?: Partial<typeof DEFAULT_THEME> }) {
  const T = { ...DEFAULT_THEME, ...(theme || {}) }
  const [data, setData] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [timelineFilter, setTimelineFilter] = useState('all')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [expandedField, setExpandedField] = useState<string|null>(null)
  const [enlargedPhoto, setEnlargedPhoto] = useState<string|null>(null)
  const [mobileTab, setMobileTab] = useState<'summary'|'main'|'timeline'>('main')

  useEffect(() => {
    let cancelled = false
    setLoading(true); setError('')
    fetch(`${API}/api/admin/student-preview/${studentId}/full-profile`, { headers:{Authorization:`Bearer ${token}`} })
      .then(r => r.json())
      .then(d => { if (cancelled) return; if (d.success) setData(d.student); else setError(d.message||'Could not load profile') })
      .catch(() => { if (!cancelled) setError('Network error') })
      .finally(() => { if (!cancelled) setLoading(false) })
    return () => { cancelled = true }
  }, [studentId, token])

  // ESC key support (§1.2.6)
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  const jump = (id: string) => {
    setMobileTab('main')
    setTimeout(() => document.getElementById(id)?.scrollIntoView({ behavior:'smooth', block:'start' }), 60)
  }

  // ── §13.2 Timeline filters applied to field-change timeline + audit trail ──
  const filteredTimeline = useMemo(() => {
    if (!data) return []
    let items = (data.fieldChangeTimeline || []).map((h:any) => ({ ...h, _type:'field' }))
    if (timelineFilter !== 'all') {
      items = items.filter((h:any) => {
        const flds = h.updatedFields || []
        if (timelineFilter === 'personal') return flds.some((f:string)=>PERSONAL_FIELDS.includes(f))
        if (timelineFilter === 'academic') return flds.some((f:string)=>ACADEMIC_FIELDS.includes(f))
        if (timelineFilter === 'security') return flds.includes('password')
        if (timelineFilter === 'photo') return flds.includes('avatar')
        if (timelineFilter === 'login') return false
        return true
      })
    }
    if (dateFrom) items = items.filter((h:any) => new Date(h.updatedAt) >= new Date(dateFrom))
    if (dateTo) items = items.filter((h:any) => new Date(h.updatedAt) <= new Date(dateTo + 'T23:59:59'))
    if (search.trim()) {
      const q = search.toLowerCase()
      items = items.filter((h:any) => (h.updatedFields||[]).join(' ').toLowerCase().includes(q) || (h.source||'').toLowerCase().includes(q))
    }
    return items
  }, [data, timelineFilter, dateFrom, dateTo, search])

  const filteredAudit = useMemo(() => {
    if (!data) return []
    let items = data.auditTrail || []
    if (timelineFilter === 'login') items = items.filter((a:any) => (a.action||'').toUpperCase().includes('LOGIN'))
    else if (timelineFilter === 'security') items = items.filter((a:any) => (a.module||'')==='security')
    else if (['personal','academic','photo'].includes(timelineFilter)) items = []
    if (dateFrom) items = items.filter((a:any) => new Date(a.createdAt) >= new Date(dateFrom))
    if (dateTo) items = items.filter((a:any) => new Date(a.createdAt) <= new Date(dateTo + 'T23:59:59'))
    if (search.trim()) {
      const q = search.toLowerCase()
      items = items.filter((a:any) => (a.details||'').toLowerCase().includes(q) || (a.action||'').toLowerCase().includes(q))
    }
    return items
  }, [data, timelineFilter, search, dateFrom, dateTo])

  // ── §13.1 Versioned field history — group profileHistory changes per field ──
  const versionedFields = useMemo(() => {
    if (!data) return {}
    const map: Record<string, any[]> = {}
    ;(data.fieldChangeTimeline || []).slice().reverse().forEach((h:any) => {
      (h.changes||[]).forEach((c:any) => {
        if (!map[c.field]) map[c.field] = []
        map[c.field].push({ ...c, updatedAt: h.updatedAt, source: h.source, updatedBy: h.updatedBy })
      })
    })
    return map
  }, [data])

  const btnGhost:any = { background:'transparent', border:`1px solid ${T.BOR}`, color:T.TS, borderRadius:9, padding:'7px 14px', cursor:'pointer', fontSize:11.5, fontWeight:600 }
  const btnP:any = { background:`linear-gradient(135deg,${T.ACC},#0055CC)`, color:'#fff', border:'none', borderRadius:9, padding:'8px 16px', cursor:'pointer', fontSize:11.5, fontWeight:700 }

  return (
    <ThemeCtx.Provider value={T}>
    <div style={{ position:'fixed', inset:0, zIndex:500, background:'#000A18', display:'flex', flexDirection:'column', animation:'s360SlideIn .28s cubic-bezier(.4,0,.2,1)' }}>
      <style>{`
        @keyframes s360SlideIn { from { opacity:0; transform:translateY(18px);} to { opacity:1; transform:translateY(0);} }
        .s360-scroll::-webkit-scrollbar{width:5px} .s360-scroll::-webkit-scrollbar-thumb{background:rgba(77,159,255,.3);border-radius:3px}
        @media(max-width:980px){ .s360-panel-left,.s360-panel-right{display:none !important} .s360-panel-left.mshow,.s360-panel-right.mshow{display:block !important} }
      `}</style>

      {/* ── §1.3 Sticky top header ── */}
      <div style={{ position:'sticky', top:0, zIndex:5, background:'rgba(0,10,24,0.96)', backdropFilter:'blur(16px)', borderBottom:`1px solid ${T.BOR}`, padding:'12px 18px', display:'flex', alignItems:'center', gap:14, flexWrap:'wrap' }}>
        <div style={{ display:'flex', alignItems:'center', gap:10, flex:1, minWidth:220 }}>
          <div style={{fontSize:20}}>🔎</div>
          <div>
            <div style={{ display:'flex', alignItems:'center', gap:8, flexWrap:'wrap' }}>
              <span style={{fontWeight:800, fontSize:15, color:T.TS}}>{data?.name || (loading?'Loading…':'Student')}</span>
              {data?.verified && <Badge col={T.SUC}>✓ Verified</Badge>}
              {data?.studentId && <span style={{fontSize:10.5,color:T.DIM}}>ID: {data.studentId}</span>}
              {data?.studentId && <CopyBtn text={data.studentId} size="sm"/>}
            </div>
            <div style={{fontSize:10.5, color:T.DIM, marginTop:2}}>
              360° Profile Preview {data && <>· {data.completion}% complete · Last updated {fmt(data.lastUpdated)}</>}
            </div>
          </div>
        </div>
        <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔍 Search inside preview…" style={{ background:'rgba(0,22,40,0.7)', border:`1px solid ${T.BOR}`, borderRadius:9, padding:'8px 12px', color:T.TS, fontSize:12, outline:'none', width:200 }}/>
        <button onClick={onClose} style={{ background:'rgba(255,71,87,0.12)', border:'1px solid rgba(255,71,87,0.35)', color:T.DNG, borderRadius:9, width:36, height:36, cursor:'pointer', fontSize:16 }}>✕</button>
      </div>

      {/* ── §1.2.8 Section jump navigation ── */}
      <div className="s360-scroll" style={{ display:'flex', gap:6, overflowX:'auto', padding:'10px 18px', borderBottom:`1px solid ${T.BOR}`, background:'rgba(0,10,24,0.7)' }}>
        {SECTIONS.map(s => (
          <button key={s.id} onClick={()=>jump(s.id)} style={{ flexShrink:0, display:'flex', alignItems:'center', gap:5, padding:'7px 13px', borderRadius:99, border:`1px solid ${T.BOR}`, background:'rgba(77,159,255,0.06)', color:T.TS, fontSize:11.5, fontWeight:600, cursor:'pointer', whiteSpace:'nowrap' }}>
            {s.ico} {s.lbl}
          </button>
        ))}
        <div style={{display:'flex',gap:6,marginLeft:'auto'}} className="mshow-tabs">
          {(['summary','main','timeline'] as const).map(m=>(
            <button key={m} onClick={()=>setMobileTab(m)} style={{ display:'none' }} />
          ))}
        </div>
      </div>

      {/* Mobile tab switcher (only relevant <980px, controlled via CSS) */}
      <div style={{ display:'flex', gap:6, padding:'8px 18px 0' }} className="s360-mobiletabs">
        {(['summary','main','timeline'] as const).map(m=>(
          <button key={m} onClick={()=>setMobileTab(m)} style={{ flex:1, padding:'7px 0', borderRadius:8, border:`1px solid ${mobileTab===m?T.ACC:T.BOR}`, background:mobileTab===m?'rgba(77,159,255,0.15)':'transparent', color:mobileTab===m?T.ACC:T.DIM, fontSize:11, fontWeight:700, cursor:'pointer' }}>{m==='summary'?'Summary':m==='main'?'Details':'Timeline'}</button>
        ))}
      </div>

      {loading && <div style={{padding:40,textAlign:'center',color:T.DIM}}>Loading 360° profile…</div>}
      {error && <div style={{padding:40,textAlign:'center',color:T.DNG}}>⚠️ {error}</div>}

      {data && !loading && (
        <div style={{ flex:1, overflow:'hidden', display:'flex', gap:16, padding:'16px 18px' }}>

          {/* ══ §1.1.1 LEFT SUMMARY PANEL ══ */}
          <div className={`s360-panel-left${mobileTab==='summary'?' mshow':''}`} style={{ width:260, flexShrink:0, overflowY:'auto' }}>
            <Card>
              <div style={{textAlign:'center', marginBottom:12}}>
                <div style={{ width:76, height:76, borderRadius:'50%', margin:'0 auto 10px', background: data.personal.avatar?`url(${data.personal.avatar})`:`linear-gradient(135deg,${T.ACC},#00D4FF)`, backgroundSize:'contain', backgroundPosition:'center', backgroundRepeat:'no-repeat', backgroundColor:'#0A0E17', display:'flex', alignItems:'center', justifyContent:'center', fontSize:26, fontWeight:800, color:'#fff', cursor: data.personal.avatar ? 'pointer':'default' }} onClick={()=>data.personal.avatar && setEnlargedPhoto(data.personal.avatar)}>
                  {!data.personal.avatar && (data.name||'?').charAt(0).toUpperCase()}
                </div>
                <div style={{fontWeight:800, fontSize:15, color:T.TS}}>{data.name}</div>
                <div style={{fontSize:10.5, color:T.DIM, marginTop:2}}>{data.email}</div>
                <div style={{display:'flex',gap:6,justifyContent:'center',marginTop:8,flexWrap:'wrap'}}>
                  {data.verified && <Badge col={T.SUC}>✓ Verified</Badge>}
                  {data.batch && <Badge col={T.ACC}>📚 {data.batch}</Badge>}
                  {data.targetExam && <Badge col={T.GOLD}>🎯 {data.targetExam}</Badge>}
                </div>
              </div>
              <Row label="Student ID" value={<span style={{display:'flex',gap:6,alignItems:'center'}}>{data.studentId||'—'} {data.studentId && <CopyBtn text={data.studentId} size="sm"/>}</span>}/>
              <Row label="Profile Health" value={`${data.health}/100`}/>
              <Row label="Completion" value={`${data.completion}%`}/>
              <Row label="Last Login" value={fmt(data.security.lastLogin?.at || data.security.lastLogin?.time)}/>
              <Row label="Last Profile Update" value={fmt(data.lastUpdated)}/>
            </Card>

            <Card title="Quick Actions" icon="⚡">
              <div style={{display:'flex', flexDirection:'column', gap:8}}>
                <div style={{display:'flex',alignItems:'center',justifyContent:'space-between'}}>
                  <span style={{fontSize:11.5,color:T.DIM}}>Copy Student ID</span>
                  {data.studentId && <CopyBtn text={data.studentId} size="sm"/>}
                </div>
                <button style={btnGhost} onClick={()=>jump('personal')}>📄 Open Full Profile</button>
                <button style={btnGhost} onClick={()=>jump('login')}>📶 View Login Activity</button>
                <button style={btnGhost} onClick={()=>{setMobileTab('timeline')}}>🕐 View Audit Timeline</button>
                <button style={btnGhost} onClick={()=>jump('photos')}>🖼️ Open Photo History</button>
                <button style={btnGhost} onClick={()=>jump('security')}>🔒 Jump to Security</button>
              </div>
            </Card>
          </div>

          {/* ══ §1.1.2 MAIN DETAIL WORKSPACE ══ */}
          <div className="s360-scroll" style={{ flex:1, overflowY:'auto', minWidth:0, display: mobileTab==='main' || typeof window==='undefined' ? 'block':'block' }}>

            {/* §3 PERSONAL DETAILS */}
            <Card id="personal" title="Personal Details" icon="👤">
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:0}}>
                <Row label="Full Name" value={data.personal.name}/>
                <Row label="Email (read-only)" value={data.personal.email}/>
                <Row label="Phone" value={data.personal.phone}/>
                <Row label="Date of Birth" value={data.personal.dob}/>
                <Row label="Gender" value={data.personal.gender}/>
                <Row label="State" value={data.personal.state}/>
                <Row label="City" value={data.personal.city}/>
                <Row label="Profile Completion" value={`${data.completion}%`}/>
              </div>
              {data.personal.bio && <div style={{marginTop:8,fontSize:11.5,color:T.DIM,fontStyle:'italic'}}>"{data.personal.bio}"</div>}
              <div style={{marginTop:10,display:'flex',gap:8,flexWrap:'wrap'}}>
                {PERSONAL_FIELDS.map(f => versionedFields[f]?.length ? (
                  <button key={f} onClick={()=>setExpandedField(expandedField===f?null:f)} style={{...btnGhost, fontSize:10.5, padding:'5px 10px', borderColor: expandedField===f?T.ACC:T.BOR, color: expandedField===f?T.ACC:T.DIM}}>
                    {f} · {versionedFields[f].length} version{versionedFields[f].length>1?'s':''}
                  </button>
                ) : null)}
              </div>
              {expandedField && PERSONAL_FIELDS.includes(expandedField) && versionedFields[expandedField] && (
                <div style={{marginTop:10,background:'rgba(77,159,255,0.05)',borderRadius:10,padding:10,border:`1px solid ${T.BOR}`}}>
                  <div style={{fontSize:10.5,fontWeight:700,color:T.ACC,marginBottom:6}}>History — {expandedField}</div>
                  {versionedFields[expandedField].map((v:any,i:number)=>(
                    <div key={i} style={{fontSize:11,color:T.TS,padding:'5px 0',borderBottom: i<versionedFields[expandedField].length-1?`1px solid ${T.BOR}`:'none',display:'flex',justifyContent:'space-between',gap:8,flexWrap:'wrap'}}>
                      <span><span style={{color:'#FF8C42'}}>{String(v.oldValue||'—')}</span> → <span style={{color:T.SUC}}>{String(v.newValue||'—')}</span></span>
                      <span style={{color:T.DIM,fontSize:10}}>{fmt(v.updatedAt)} · {v.source}</span>
                    </div>
                  ))}
                </div>
              )}
            </Card>

            {/* §4 ACADEMIC PROFILE */}
            <Card id="academic" title="Academic Profile" icon="🎓">
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:0}}>
                <Row label="Target Exam" value={data.academic.targetExam}/>
                <Row label="Target Year" value={data.academic.targetYear}/>
                <Row label="Board" value={data.academic.board}/>
                <Row label="School / College" value={data.academic.school}/>
                <Row label="Medium" value={data.academic.medium}/>
                <Row label="Coaching Institute" value={data.academic.coachingInstitute}/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(100px,1fr))',gap:8,marginTop:12}}>
                {[
                  {l:'Total Exams',v:data.academicSnapshot.totalExams,c:'#A855F7'},
                  {l:'Best Score',v:data.academicSnapshot.bestScore,c:T.GOLD},
                  {l:'Avg Score',v:data.academicSnapshot.avgScore,c:T.ACC},
                  {l:'Streak',v:`${data.academicSnapshot.currentStreak}d`,c:'#FFA502'},
                ].map((s,i)=>(
                  <div key={i} style={{background:'rgba(77,159,255,0.05)',border:`1px solid ${T.BOR}`,borderRadius:10,padding:'9px 6px',textAlign:'center'}}>
                    <div style={{fontSize:15,fontWeight:800,color:s.c}}>{s.v}</div>
                    <div style={{fontSize:9,color:T.DIM,marginTop:2}}>{s.l}</div>
                  </div>
                ))}
              </div>
              <div style={{marginTop:10,display:'flex',gap:8,flexWrap:'wrap'}}>
                {ACADEMIC_FIELDS.map(f => versionedFields[f]?.length ? (
                  <button key={f} onClick={()=>setExpandedField(expandedField===f?null:f)} style={{...btnGhost, fontSize:10.5, padding:'5px 10px', borderColor: expandedField===f?T.ACC:T.BOR, color: expandedField===f?T.ACC:T.DIM}}>
                    {f} · {versionedFields[f].length} version{versionedFields[f].length>1?'s':''}
                  </button>
                ) : null)}
              </div>
              {expandedField && ACADEMIC_FIELDS.includes(expandedField) && versionedFields[expandedField] && (
                <div style={{marginTop:10,background:'rgba(77,159,255,0.05)',borderRadius:10,padding:10,border:`1px solid ${T.BOR}`}}>
                  <div style={{fontSize:10.5,fontWeight:700,color:T.ACC,marginBottom:6}}>History — {expandedField}</div>
                  {versionedFields[expandedField].map((v:any,i:number)=>(
                    <div key={i} style={{fontSize:11,color:T.TS,padding:'5px 0',borderBottom: i<versionedFields[expandedField].length-1?`1px solid ${T.BOR}`:'none',display:'flex',justifyContent:'space-between',gap:8,flexWrap:'wrap'}}>
                      <span><span style={{color:'#FF8C42'}}>{String(v.oldValue||'—')}</span> → <span style={{color:T.SUC}}>{String(v.newValue||'—')}</span></span>
                      <span style={{color:T.DIM,fontSize:10}}>{fmt(v.updatedAt)} · {v.source}</span>
                    </div>
                  ))}
                </div>
              )}
            </Card>

            {/* §5 SECURITY */}
            <Card id="security" title="Security" icon="🔒">
              <Row label="Password Last Changed" value={fmt(data.security.passwordChangedAt)}/>
              <Row label="Password Change Count" value={data.security.passwordChangeCount}/>
              <Row label="Password Reset History" value={data.security.passwordResetHistory?.length || 0}/>
              <Row label="2FA Status" value={data.security.twoFactorEnabled ? <Badge col={T.SUC}>Enabled</Badge> : <Badge col={T.DNG}>Disabled</Badge>}/>
              <Row label="Active Devices" value={data.security.activeDeviceCount}/>
              <Row label="Trusted Devices" value={data.security.trustedDevices?.length || 0}/>
              <Row label="Last Login" value={fmt(data.security.lastLogin?.at || data.security.lastLogin?.time)}/>
              <Row label="Failed Login Attempts" value={data.security.failedLoginAttempts}/>
              <Row label="Last Failed Login" value={fmt(data.security.lastFailedLoginAt)}/>
              <div style={{fontSize:9.5,color:T.DIM,marginTop:10,fontStyle:'italic'}}>🔒 Actual password / hash is never shown or stored here — only change metadata.</div>

              {/* §13.3 Device Intelligence */}
              {data.security.trustedDevices?.length > 0 && (
                <div style={{marginTop:12}}>
                  <div style={{fontSize:11,fontWeight:700,color:T.ACC,marginBottom:6}}>Device Intelligence</div>
                  {data.security.trustedDevices.map((d:any,i:number)=>(
                    <div key={i} style={{display:'flex',justifyContent:'space-between',fontSize:11,padding:'6px 0',borderBottom: i<data.security.trustedDevices.length-1?`1px solid ${T.BOR}`:'none'}}>
                      <span style={{color:T.TS}}>{d.label||d.browser||'Device'} · {d.os||'—'}</span>
                      <span style={{color:T.DIM}}>First: {fmtDate(d.addedAt)} · Last: {fmtDate(d.lastUsedAt)} <Badge col={T.SUC}>Trusted</Badge></span>
                    </div>
                  ))}
                </div>
              )}

              {/* §13.4 Session Intelligence */}
              <div style={{marginTop:12}}>
                <div style={{fontSize:11,fontWeight:700,color:T.ACC,marginBottom:6}}>Session Intelligence</div>
                <Row label="Active Session" value={data.security.activeDeviceCount>0?'Yes':'No'}/>
                <Row label="Session Duration" value="—"/>
                <Row label="Logout Reason" value="—"/>
                <Row label="Failed Attempt Count" value={data.security.failedLoginAttempts}/>
                <Row label="Suspicious Session Flag" value={data.security.failedLoginAttempts>=5 ? <Badge col={T.DNG}>⚠ Suspicious</Badge> : <Badge col={T.SUC}>Normal</Badge>}/>
              </div>
            </Card>

            {/* §6 LOGIN ACTIVITY */}
            <Card id="login" title="Login Activity" icon="📶">
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(100px,1fr))',gap:8,marginBottom:12}}>
                <div style={{background:'rgba(77,159,255,0.05)',border:`1px solid ${T.BOR}`,borderRadius:10,padding:'9px 6px',textAlign:'center'}}><div style={{fontSize:15,fontWeight:800,color:T.ACC}}>{data.loginActivity.loginCount}</div><div style={{fontSize:9,color:T.DIM}}>Login Count</div></div>
                <div style={{background:'rgba(255,71,87,0.05)',border:`1px solid ${T.BOR}`,borderRadius:10,padding:'9px 6px',textAlign:'center'}}><div style={{fontSize:15,fontWeight:800,color:T.DNG}}>{data.loginActivity.failedLoginAttempts}</div><div style={{fontSize:9,color:T.DIM}}>Failed Logins</div></div>
                <div style={{background:'rgba(255,215,0,0.05)',border:`1px solid ${T.BOR}`,borderRadius:10,padding:'9px 6px',textAlign:'center'}}><div style={{fontSize:15,fontWeight:800,color:T.GOLD}}>{data.loginActivity.peakHour!==null?`${data.loginActivity.peakHour}:00`:'—'}</div><div style={{fontSize:9,color:T.DIM}}>Peak Login Hour</div></div>
              </div>
              {/* Daily login pattern heatmap */}
              {Object.keys(data.loginActivity.dailyPattern||{}).length > 0 && (
                <div style={{display:'flex',gap:6,marginBottom:12,flexWrap:'wrap'}}>
                  {['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map(day=>{
                    const c = data.loginActivity.dailyPattern[day]||0
                    const max = Math.max(1,...Object.values(data.loginActivity.dailyPattern) as number[])
                    return (
                      <div key={day} style={{textAlign:'center',flex:1,minWidth:32}}>
                        <div style={{height:40,display:'flex',alignItems:'flex-end',justifyContent:'center'}}>
                          <div style={{width:16,height:`${Math.max(4,(c/max)*40)}px`,background:c>0?T.ACC:'rgba(255,255,255,0.06)',borderRadius:3}}/>
                        </div>
                        <div style={{fontSize:9,color:T.DIM,marginTop:3}}>{day}</div>
                      </div>
                    )
                  })}
                </div>
              )}
              <div style={{fontSize:11,fontWeight:700,color:T.ACC,marginBottom:6}}>Recent Sessions</div>
              {data.loginActivity.history.length===0 ? <div style={{fontSize:11,color:T.DIM}}>No login history yet.</div> : data.loginActivity.history.slice(0,10).map((h:any,i:number)=>(
                <div key={i} style={{display:'flex',justifyContent:'space-between',fontSize:11,padding:'6px 0',borderBottom: i<9?`1px solid ${T.BOR}`:'none',flexWrap:'wrap',gap:6}}>
                  <span style={{color:T.TS}}>{h.device||`${h.browser} on ${h.os}`}</span>
                  <span style={{color:T.DIM}}>{h.city&&h.city!=='Unknown'?`${h.city}, ${h.country}`:h.ip} · {fmt(h.at||h.time)}</span>
                </div>
              ))}
            </Card>

            {/* §7 PHOTO HISTORY */}
            <Card id="photos" title="Photo History" icon="🖼️">
              {data.photoHistory.length===0 ? <div style={{fontSize:11,color:T.DIM}}>No photo changes recorded.</div> : (
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(90px,1fr))',gap:10}}>
                  {data.photoHistory.map((p:any,i:number)=>(
                    <div key={i} onClick={()=>setEnlargedPhoto(p.url)} style={{cursor:'pointer',textAlign:'center'}}>
                      <div style={{width:'100%',aspectRatio:'1',borderRadius:10,background:`url(${p.url})`,backgroundSize:'contain',backgroundPosition:'center',backgroundRepeat:'no-repeat',backgroundColor:'#0A0E17',border:`2px solid ${p.current?T.SUC:T.BOR}`}}/>
                      <div style={{fontSize:9,color:T.DIM,marginTop:4}}>{fmtDate(p.updatedAt)}</div>
                      {p.current && <Badge col={T.SUC}>Current</Badge>}
                    </div>
                  ))}
                </div>
              )}
            </Card>

            {/* §10 IDENTITY & VERIFICATION */}
            <Card id="identity" title="Identity & Verification" icon="🛡️">
              <Row label="Verification Status" value={data.verification.emailVerified ? <Badge col={T.SUC}>Verified</Badge> : <Badge col={T.WRN}>Pending</Badge>}/>
              <Row label="Email Verified" value={data.verification.emailVerified ? '✅ Yes' : '❌ No'}/>
              <Row label="Phone Verified" value={data.verification.phoneVerified ? '✅ Yes' : '❌ No'}/>
              <Row label="Photo Verified" value={data.verification.photoVerified ? '✅ Yes' : '❌ No'}/>
              <Row label="Profile Health Score" value={`${data.verification.healthScore}/100`}/>
              <Row label="Risk Indicator" value={<Badge col={data.verification.riskIndicator==='high'?T.DNG:data.verification.riskIndicator==='medium'?T.WRN:T.SUC}>{data.verification.riskIndicator.toUpperCase()}</Badge>}/>
            </Card>

            {/* §13.1 VERSIONED FIELD HISTORY */}
            <Card id="versioned" title="Versioned Field History" icon="🗂️">
              {Object.keys(versionedFields).length===0 ? <div style={{fontSize:11,color:T.DIM}}>No field changes recorded yet.</div> : Object.entries(versionedFields).map(([field, versions]:any) => (
                <div key={field} style={{marginBottom:10,paddingBottom:10,borderBottom:`1px solid ${T.BOR}`}}>
                  <div style={{fontSize:11.5,fontWeight:700,color:T.TS,marginBottom:6,textTransform:'capitalize'}}>{field}</div>
                  <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                    {versions.map((v:any,i:number)=>(
                      <div key={i} style={{fontSize:10,padding:'4px 9px',borderRadius:7,background: i===versions.length-1?'rgba(0,196,140,0.12)':'rgba(77,159,255,0.06)', border:`1px solid ${i===versions.length-1?'rgba(0,196,140,0.35)':T.BOR}`, color: i===versions.length-1?T.SUC:T.DIM}}>
                        V{i+1}{i===versions.length-1?' (current)':''} · {fmtDate(v.updatedAt)}
                      </div>
                    ))}
                  </div>
                </div>
              ))}
              <div style={{fontSize:9.5,color:T.DIM,marginTop:6,fontStyle:'italic'}}>Reference only — versions cannot be restored from here.</div>
            </Card>

            {/* §13.5 CHANGE FREQUENCY ANALYSIS */}
            <Card id="frequency" title="Change Frequency Analysis" icon="📊">
              {data.changeFrequency.length===0 ? <div style={{fontSize:11,color:T.DIM}}>No field changes recorded yet.</div> : (
                <table style={{width:'100%',borderCollapse:'collapse',fontSize:11.5}}>
                  <thead><tr style={{color:T.DIM,textAlign:'left'}}><th style={{padding:'6px 4px'}}>Field</th><th>Changes</th><th>Last Update</th><th>Risk</th></tr></thead>
                  <tbody>
                    {data.changeFrequency.map((f:any,i:number)=>(
                      <tr key={i} style={{borderTop:`1px solid ${T.BOR}`}}>
                        <td style={{padding:'7px 4px',color:T.TS,textTransform:'capitalize'}}>{f.field}</td>
                        <td style={{color:T.TS}}>{f.count}</td>
                        <td style={{color:T.DIM}}>{fmtDate(f.lastUpdate)}</td>
                        <td><Badge col={f.riskLevel==='high'?T.DNG:f.riskLevel==='medium'?T.WRN:T.SUC}>{f.riskLevel}</Badge></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>

            {/* §12 QUICK INSPECT CARDS */}
            <Card id="quick" title="Quick Inspect" icon="⚡">
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(100px,1fr))',gap:8}}>
                {[
                  {l:'Best Score',v:data.quickInspect.bestScore,c:T.GOLD,j:'academic'},
                  {l:'Average Score',v:data.quickInspect.avgScore,c:T.ACC,j:'academic'},
                  {l:'Total Exams',v:data.quickInspect.totalExams,c:'#A855F7',j:'academic'},
                  {l:'Login Count',v:data.quickInspect.loginCount,c:T.SUC,j:'login'},
                  {l:'Failed Logins',v:data.quickInspect.failedLogins,c:T.DNG,j:'security'},
                  {l:'Photo Changes',v:data.quickInspect.photoChanges,c:'#FF8C42',j:'photos'},
                  {l:'Last Active',v:fmtDate(data.quickInspect.lastActive),c:T.DIM,j:'login'},
                ].map((s,i)=>(
                  <div key={i} onClick={()=>jump(s.j)} style={{cursor:'pointer',background:'rgba(77,159,255,0.05)',border:`1px solid ${T.BOR}`,borderRadius:10,padding:'10px 6px',textAlign:'center'}}>
                    <div style={{fontSize:14,fontWeight:800,color:s.c}}>{s.v}</div>
                    <div style={{fontSize:9,color:T.DIM,marginTop:2}}>{s.l}</div>
                  </div>
                ))}
              </div>
            </Card>
          </div>

          {/* ══ §1.1.3 RIGHT HISTORY TIMELINE PANEL ══ */}
          <div className={`s360-panel-right${mobileTab==='timeline'?' mshow':''}`} style={{ width:300, flexShrink:0, overflowY:'auto' }}>
            <Card title="History Timeline" icon="🕐">
              {/* §13.2 Filters */}
              <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:8}}>
                {TIMELINE_FILTERS.map(f=>(
                  <button key={f.id} onClick={()=>setTimelineFilter(f.id)} style={{fontSize:9.5,padding:'4px 9px',borderRadius:7,border:`1px solid ${timelineFilter===f.id?T.ACC:T.BOR}`,background:timelineFilter===f.id?'rgba(77,159,255,0.15)':'transparent',color:timelineFilter===f.id?T.ACC:T.DIM,cursor:'pointer',fontWeight:600}}>{f.lbl}</button>
                ))}
              </div>
              <div style={{display:'flex',gap:6,marginBottom:10}}>
                <input type="date" value={dateFrom} onChange={e=>setDateFrom(e.target.value)} style={{flex:1,fontSize:10,background:'rgba(0,22,40,0.7)',border:`1px solid ${T.BOR}`,borderRadius:7,padding:'5px 7px',color:T.TS}}/>
                <input type="date" value={dateTo} onChange={e=>setDateTo(e.target.value)} style={{flex:1,fontSize:10,background:'rgba(0,22,40,0.7)',border:`1px solid ${T.BOR}`,borderRadius:7,padding:'5px 7px',color:T.TS}}/>
              </div>

              {/* Field change timeline (§8.4 expandable cards) */}
              {filteredTimeline.map((h:any,i:number)=>(
                <div key={'f'+i} style={{marginBottom:8,padding:'8px 10px',background:'rgba(77,159,255,0.04)',borderRadius:9,border:`1px solid ${T.BOR}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',fontSize:10,marginBottom:4}}>
                    <Badge col={T.ACC}>{(h.updatedFields||[]).join(', ')}</Badge>
                    <span style={{color:T.DIM}}>{fmt(h.updatedAt)}</span>
                  </div>
                  {h.changes.map((c:any,j:number)=>(
                    <div key={j} style={{fontSize:10.5,color:T.TS,marginBottom:2}}>
                      <span style={{color:T.DIM}}>{c.field}:</span> <span style={{color:'#FF8C42'}}>{String(c.oldValue||'—')}</span> → <span style={{color:T.SUC}}>{String(c.newValue||'—')}</span>
                    </div>
                  ))}
                  <div style={{fontSize:9,color:T.DIM,marginTop:3}}>Source: {h.source} · By: {h.updatedBy}</div>
                </div>
              ))}

              {/* Audit / login events */}
              {filteredAudit.map((a:any,i:number)=>(
                <div key={'a'+i} style={{marginBottom:8,padding:'8px 10px',background:'rgba(168,85,247,0.04)',borderRadius:9,border:`1px solid ${T.BOR}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',fontSize:10,marginBottom:3}}>
                    <Badge col="#A855F7">{a.action}</Badge>
                    <span style={{color:T.DIM}}>{fmt(a.createdAt)}</span>
                  </div>
                  <div style={{fontSize:10.5,color:T.TS}}>{a.details}</div>
                </div>
              ))}

              {filteredTimeline.length===0 && filteredAudit.length===0 && <div style={{fontSize:11,color:T.DIM,textAlign:'center',padding:'20px 0'}}>No matching history events.</div>}
            </Card>
          </div>
        </div>
      )}

      {/* §7.2.4 Enlarge photo */}
      {enlargedPhoto && (
        <div onClick={()=>setEnlargedPhoto(null)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:600,display:'flex',alignItems:'center',justifyContent:'center',padding:20}}>
          <img src={enlargedPhoto} alt="Enlarged" style={{maxWidth:'90vw',maxHeight:'90vh',borderRadius:16,border:`2px solid ${T.BOR}`}}/>
        </div>
      )}
    </div>
    </ThemeCtx.Provider>
  )
}
