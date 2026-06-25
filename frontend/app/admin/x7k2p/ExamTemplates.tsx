'use client'
import { useState, useEffect, useCallback } from 'react'

// ── Design tokens (locked: Neon Blue + Glassmorphism + Playfair/Inter — matches CreateExamWizard.tsx) ──
const ACC='#4D9FFF', TS='#E8F4FF', DIM='#6B8FAF', GOLD='#FFD700'
const SUC='#00C48C', DNG='#FF4D4D', WRN='#FFB84D', PRP='#A78BFA'
const BOR='rgba(77,159,255,0.16)', CRD='rgba(0,15,35,0.88)'
const bp:any={background:`linear-gradient(135deg,${PRP},#6D28D9)`,color:'#fff',border:'none',borderRadius:10,padding:'11px 22px',cursor:'pointer',fontWeight:700,fontSize:13,transition:'all 0.2s'}
const bpAcc:any={...bp,background:`linear-gradient(135deg,${ACC},#0055CC)`}
const bg_:any={background:'rgba(0,25,55,0.7)',color:TS,border:`1px solid ${BOR}`,borderRadius:10,padding:'10px 18px',cursor:'pointer',fontSize:12,transition:'all 0.2s'}
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,12,30,0.9)',border:`1.5px solid ${BOR}`,borderRadius:10,color:TS,fontSize:13,outline:'none',boxSizing:'border-box' as any,fontFamily:'Inter,sans-serif'}
const lbl:any={display:'block',fontSize:10,color:DIM,marginBottom:5,fontWeight:700,letterSpacing:0.6,textTransform:'uppercase' as any}
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:16,padding:'20px',backdropFilter:'blur(14px)'}

const SUBJECTS = ['Physics','Chemistry','Biology','Math','GK','English','Other']
const EXAM_TYPES = ['NEET','JEE','CUET','RBSE','CBSE','Custom']
const ICONS = ['📋','🎯','📖','⚡','🏆','🔬','✏️','📐','🧪','🧬','📅','⚙️']
const SWATCHES = ['#4D9FFF','#FFB84D','#00C48C','#A78BFA','#F472B6','#FBBF24','#34D399','#60A5FA','#FF4D4D','#22D3EE','#FB7185','#84CC16']

interface Props { token:string; API:string; T:(m:string,t?:'s'|'e'|'w')=>void; onApply:(payload:any)=>void }

function timeAgo(d:any){
  if(!d) return 'Never used'
  const diff = Date.now() - new Date(d).getTime()
  const mins = Math.floor(diff/60000)
  if(mins<1) return 'Just now'
  if(mins<60) return `${mins}m ago`
  const hrs = Math.floor(mins/60)
  if(hrs<24) return `${hrs}h ago`
  const days = Math.floor(hrs/24)
  if(days<30) return `${days}d ago`
  const months = Math.floor(days/30)
  if(months<12) return `${months}mo ago`
  return `${Math.floor(months/12)}y ago`
}

function previewTitle(t:any){
  const dateStr = new Date().toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})
  const fmt = t.titleFormat || '{name}'
  return fmt.replace(/{name}/gi,t.name||'Exam').replace(/{date}/gi,dateStr).replace(/{category}/gi,t.category||'').replace(/{examType}/gi,t.examType||'').replace(/{n}/gi,String((t.usageCount||0)+1)).replace(/\s+/g,' ').trim()
}

function emptyForm(){
  return { name:'', icon:'📋', titleFormat:'{name}', category:'NEET', categoryColor:'#4D9FFF', subject:'Full Mock', examType:'NEET', totalQs:180, subjectQs:{Physics:45,Chemistry:45,Biology:90} as Record<string,number>, duration:200, correctMarks:4, negativeMarks:1, instructions:'' }
}

function Chip({ico,label,col}:{ico:string;label:string;col?:string}){
  const c = col || DIM
  return <span style={{display:'inline-flex',alignItems:'center',gap:4,fontSize:10,fontWeight:600,color:c,background:`${c}14`,border:`1px solid ${c}2E`,borderRadius:7,padding:'3px 8px',whiteSpace:'nowrap' as any}}>{ico} {label}</span>
}

export default function ExamTemplates({ token, API, T, onApply }: Props) {
  const hdrs = { 'Content-Type':'application/json', Authorization:`Bearer ${token}` }

  const [templates, setTemplates] = useState<any[]>([])
  const [categories, setCategories] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [activeCat, setActiveCat] = useState('all')

  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string|null>(null)
  const [form, setForm] = useState<any>(emptyForm())
  const [saving, setSaving] = useState(false)
  const [showNewCat, setShowNewCat] = useState(false)
  const [newCatName, setNewCatName] = useState('')
  const [newCatColor, setNewCatColor] = useState(SWATCHES[0])
  const [savingCat, setSavingCat] = useState(false)

  const [previewT, setPreviewT] = useState<any>(null)
  const [versionsT, setVersionsT] = useState<any>(null)
  const [versions, setVersions] = useState<any[]>([])
  const [versionsLoading, setVersionsLoading] = useState(false)

  const [applyingId, setApplyingId] = useState<string|null>(null)
  const [busyId, setBusyId] = useState<string|null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<any>(null)

  // ── debounce search ────────────────────────────────────────────────────────
  useEffect(() => { const tm = setTimeout(() => setSearch(searchInput), 350); return () => clearTimeout(tm) }, [searchInput])

  const fetchTemplates = useCallback(async () => {
    setLoading(true)
    try {
      const p = new URLSearchParams()
      if (activeCat !== 'all') p.set('category', activeCat)
      if (search.trim()) p.set('search', search.trim())
      const r = await fetch(`${API}/api/exam-templates?${p}`, { headers: { Authorization:`Bearer ${token}` } })
      const d = await r.json()
      if (d.success) setTemplates(d.templates || [])
    } catch {}
    setLoading(false)
  }, [API, token, activeCat, search])

  const fetchCategories = useCallback(async () => {
    try {
      const r = await fetch(`${API}/api/exam-templates/categories`, { headers: { Authorization:`Bearer ${token}` } })
      const d = await r.json()
      if (d.success) setCategories(d.categories || [])
    } catch {}
  }, [API, token])

  useEffect(() => { fetchCategories() }, [fetchCategories])
  useEffect(() => { fetchTemplates() }, [fetchTemplates])

  const catColor = (name:string) => categories.find(c=>c.name===name)?.color || PRP

  // ── 29.2 / 29.9 — create / edit ──────────────────────────────────────────────
  const openCreate = () => { setEditingId(null); setForm(emptyForm()); setShowForm(true) }
  const openEdit = (t:any) => {
    setEditingId(t._id)
    setForm({ name:t.name, icon:t.icon||'📋', titleFormat:t.titleFormat||'{name}', category:t.category||'Custom', categoryColor:t.categoryColor||catColor(t.category), subject:t.subject||'Full Mock', examType:t.examType||'Custom', totalQs:t.totalQs||0, subjectQs:t.subjectQs||{}, duration:t.duration||60, correctMarks:t.correctMarks!=null?t.correctMarks:4, negativeMarks:t.negativeMarks!=null?t.negativeMarks:1, instructions:t.instructions||'' })
    setShowForm(true)
  }

  const saveTemplate = async () => {
    if (!form.name.trim()) { T('Template name required hai','e'); return }
    setSaving(true)
    try {
      const url = editingId ? `${API}/api/exam-templates/${editingId}` : `${API}/api/exam-templates`
      const method = editingId ? 'PUT' : 'POST'
      const r = await fetch(url, { method, headers: hdrs, body: JSON.stringify(form) })
      const d = await r.json()
      if (d.success) { T(d.message || 'Saved ✅'); setShowForm(false); fetchTemplates() }
      else T(d.message || 'Failed','e')
    } catch { T('Network error','e') }
    setSaving(false)
  }

  // ── 29.5 — duplicate ──────────────────────────────────────────────────────────
  const duplicateTemplate = async (t:any) => {
    setBusyId(t._id)
    try {
      const r = await fetch(`${API}/api/exam-templates/${t._id}/duplicate`, { method:'POST', headers: hdrs })
      const d = await r.json()
      if (d.success) { T('Duplicated ✅'); fetchTemplates() } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setBusyId(null)
  }

  // ── 29.8 — pin / favourite ───────────────────────────────────────────────────
  const togglePin = async (t:any) => {
    setTemplates(p => p.map(x => x._id===t._id ? {...x, isPinned:!x.isPinned} : x))
    try {
      const r = await fetch(`${API}/api/exam-templates/${t._id}/pin`, { method:'PATCH', headers: hdrs })
      await r.json()
      fetchTemplates()
    } catch { fetchTemplates() }
  }

  // ── delete ────────────────────────────────────────────────────────────────────
  const deleteTemplate = async (t:any) => {
    setBusyId(t._id)
    try {
      const r = await fetch(`${API}/api/exam-templates/${t._id}`, { method:'DELETE', headers: { Authorization:`Bearer ${token}` } })
      const d = await r.json()
      if (d.success) { T('Deleted'); setTemplates(p=>p.filter(x=>x._id!==t._id)) } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setBusyId(null); setDeleteConfirm(null)
  }

  // ── 29.13 — apply to Create Exam Wizard ──────────────────────────────────────
  const applyTemplateAction = async (t:any) => {
    setApplyingId(t._id)
    try {
      const r = await fetch(`${API}/api/exam-templates/${t._id}/apply`, { method:'POST', headers: hdrs })
      const d = await r.json()
      if (d.success) { onApply(d.template); T(`"${t.name}" applied to Exam Wizard ✅`) } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setApplyingId(null)
  }

  // ── 29.9 — version history ───────────────────────────────────────────────────
  const openVersions = async (t:any) => {
    setVersionsT(t); setVersionsLoading(true); setVersions([])
    try {
      const r = await fetch(`${API}/api/exam-templates/${t._id}/versions`, { headers: { Authorization:`Bearer ${token}` } })
      const d = await r.json()
      if (d.success) setVersions(d.versions || [])
    } catch {}
    setVersionsLoading(false)
  }

  const restoreVersion = async (idx:number) => {
    if (!versionsT) return
    try {
      const r = await fetch(`${API}/api/exam-templates/${versionsT._id}/versions/${idx}/restore`, { method:'POST', headers: hdrs })
      const d = await r.json()
      if (d.success) { T('Version restored ✅'); setVersionsT(null); fetchTemplates() } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
  }

  // ── 29.10 — custom category ──────────────────────────────────────────────────
  const createCategory = async () => {
    if (!newCatName.trim()) { T('Category name required hai','e'); return }
    setSavingCat(true)
    try {
      const r = await fetch(`${API}/api/exam-templates/categories`, { method:'POST', headers: hdrs, body: JSON.stringify({ name:newCatName.trim(), color:newCatColor }) })
      const d = await r.json()
      if (d.success) {
        T('Category added ✅')
        setCategories(p=>[...p, d.category])
        setForm((f:any)=>({...f, category:d.category.name, categoryColor:d.category.color}))
        setShowNewCat(false); setNewCatName('')
      } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setSavingCat(false)
  }

  // ── subjectQs editor helpers ──────────────────────────────────────────────────
  const setSubjectQ = (subj:string, val:number) => {
    setForm((f:any) => {
      const sq = { ...f.subjectQs, [subj]: val }
      const totalQs = Object.values(sq).reduce((a:number,b:any)=>a+(Number(b)||0),0)
      return { ...f, subjectQs: sq, totalQs }
    })
  }
  const removeSubjectQ = (subj:string) => {
    setForm((f:any) => {
      const sq = { ...f.subjectQs }; delete sq[subj]
      const totalQs = Object.values(sq).reduce((a:number,b:any)=>a+(Number(b)||0),0)
      return { ...f, subjectQs: sq, totalQs }
    })
  }
  const addSubjectQ = () => {
    const used = Object.keys(form.subjectQs||{})
    const next = SUBJECTS.find(s=>!used.includes(s)) || SUBJECTS[0]
    setSubjectQ(next, 10)
  }
  const renameSubjectQ = (oldSubj:string, newSubj:string) => {
    setForm((f:any) => {
      const sq = { ...f.subjectQs }
      const val = sq[oldSubj]
      delete sq[oldSubj]
      sq[newSubj] = val
      return { ...f, subjectQs: sq }
    })
  }

  const totalMarksPreview = Math.round((form.totalQs||0)*(form.correctMarks!=null?form.correctMarks:4))
  const maxUsage = Math.max(1, ...templates.map(t=>t.usageCount||0), 1)

  return (
    <div style={{fontFamily:'Inter,sans-serif'}}>
      <style dangerouslySetInnerHTML={{__html:`
        @keyframes etFadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @keyframes etPulse{0%,100%{transform:scale(1)}50%{transform:scale(1.04)}}
        @keyframes etSpin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        .et-card{animation:etFadeIn 0.35s ease}
        .et-spin{animation:etSpin 0.8s linear infinite;display:inline-block}
        .et-apply-btn:active{animation:etPulse 0.3s ease}
      `}}/>

      {/* ══ HEADER ══════════════════════════════════════════════════════════════ */}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:12,marginBottom:18,flexWrap:'wrap' as any}}>
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:22,color:TS,display:'flex',alignItems:'center',gap:8}}>⚡ Exam Templates</div>
          <div style={{fontSize:12,color:DIM,marginTop:3}}>Create once, reuse forever — exam patterns ready to deploy</div>
        </div>
        <button onClick={openCreate} style={{...bp,fontSize:13,boxShadow:`0 4px 18px ${PRP}44`}}>+ New Template</button>
      </div>

      {/* ══ SEARCH + CATEGORY FILTER (29.3) ════════════════════════════════════ */}
      <div style={{...cs,padding:'14px',marginBottom:16}}>
        <input value={searchInput} onChange={e=>setSearchInput(e.target.value)} placeholder="🔍 Search templates by name..." style={{...inp,marginBottom:12}}/>
        <div style={{display:'flex',gap:7,overflowX:'auto' as any,paddingBottom:2}}>
          <button onClick={()=>setActiveCat('all')} style={{flexShrink:0,background:activeCat==='all'?`linear-gradient(135deg,${ACC},#0055CC)`:'rgba(255,255,255,0.04)',color:activeCat==='all'?'#fff':DIM,border:`1px solid ${activeCat==='all'?ACC:BOR}`,borderRadius:20,padding:'7px 14px',fontSize:11,fontWeight:700,cursor:'pointer',whiteSpace:'nowrap' as any}}>All ({templates.length})</button>
          {categories.map(c=>(
            <button key={c.name} onClick={()=>setActiveCat(c.name)} style={{flexShrink:0,background:activeCat===c.name?c.color:`${c.color}14`,color:activeCat===c.name?'#fff':c.color,border:`1px solid ${c.color}44`,borderRadius:20,padding:'7px 14px',fontSize:11,fontWeight:700,cursor:'pointer',whiteSpace:'nowrap' as any,display:'flex',alignItems:'center',gap:5}}>
              <span style={{width:6,height:6,borderRadius:'50%',background:activeCat===c.name?'#fff':c.color}}/>{c.name}
            </button>
          ))}
        </div>
      </div>

      {/* ══ GRID / EMPTY STATE / LOADING ════════════════════════════════════════ */}
      {loading ? (
        <div style={{textAlign:'center' as any,padding:'60px 20px',color:DIM}}><span className="et-spin" style={{fontSize:24}}>⟳</span><div style={{marginTop:10,fontSize:12}}>Loading templates...</div></div>
      ) : templates.length===0 ? (
        <div style={{...cs,textAlign:'center' as any,padding:'48px 24px'}}>
          <div style={{fontSize:52,marginBottom:14,opacity:0.7}}>📋</div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:TS,marginBottom:6}}>No templates yet</div>
          <div style={{fontSize:12,color:DIM,marginBottom:20}}>Save your first exam as template — or build one from scratch right here.</div>
          <button onClick={openCreate} style={{...bp,fontSize:13}}>+ Create Your First Template</button>
        </div>
      ) : (
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(290px,1fr))',gap:14}}>
          {templates.map(t=>{
            const col = t.categoryColor || catColor(t.category) || PRP
            const sqEntries = Object.entries(t.subjectQs||{})
            const usagePct = Math.round(((t.usageCount||0)/maxUsage)*100)
            const busy = busyId===t._id, applying = applyingId===t._id
            return (
              <div key={t._id} className="et-card" style={{position:'relative' as any,overflow:'hidden',borderRadius:16,background:CRD,border:`1px solid ${BOR}`,backdropFilter:'blur(16px)',boxShadow:'0 4px 18px rgba(0,0,0,0.25)',transition:'all 0.25s'}}
                onMouseEnter={e=>{(e.currentTarget as HTMLElement).style.transform='translateY(-2px)';(e.currentTarget as HTMLElement).style.boxShadow='0 10px 28px rgba(0,0,0,0.35)'}}
                onMouseLeave={e=>{(e.currentTarget as HTMLElement).style.transform='none';(e.currentTarget as HTMLElement).style.boxShadow='0 4px 18px rgba(0,0,0,0.25)'}}>

                <div style={{position:'absolute',top:0,left:0,right:0,height:3,background:`linear-gradient(90deg,${col},${col}00 85%)`}}/>

                <div style={{padding:'16px 16px 14px'}}>
                  {/* header row */}
                  <div style={{display:'flex',alignItems:'flex-start',gap:10,marginBottom:10}}>
                    <div style={{width:40,height:40,borderRadius:12,flexShrink:0,display:'flex',alignItems:'center',justifyContent:'center',fontSize:19,background:`linear-gradient(145deg,${col}26,rgba(5,12,26,0.9))`,boxShadow:`0 0 0 2px ${col}22`}}>{t.icon||'📋'}</div>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14,color:TS,overflow:'hidden',whiteSpace:'nowrap' as any,textOverflow:'ellipsis'}}>{t.name}</div>
                      <span style={{fontSize:9,fontWeight:700,letterSpacing:0.4,color:col,background:`${col}16`,border:`1px solid ${col}33`,borderRadius:6,padding:'2px 7px',display:'inline-block',marginTop:4,textTransform:'uppercase' as any}}>{t.category||'Custom'}</span>
                    </div>
                    <button onClick={()=>togglePin(t)} title={t.isPinned?'Unpin':'Pin to top'} style={{background:'transparent',border:'none',cursor:'pointer',fontSize:18,color:t.isPinned?GOLD:'rgba(255,255,255,0.18)',flexShrink:0,filter:t.isPinned?`drop-shadow(0 0 6px ${GOLD}88)`:'none',transition:'all 0.2s'}}>{t.isPinned?'★':'☆'}</button>
                  </div>

                  {/* compact chips — 29.12 */}
                  <div style={{display:'flex',gap:5,flexWrap:'wrap' as any,marginBottom:10}}>
                    <Chip ico="⏱" label={`${t.duration||0} min`} col={ACC}/>
                    <Chip ico="📊" label={`${t.totalMarks||0} marks`} col={GOLD}/>
                    <Chip ico="❓" label={`${t.totalQs||0} Qs`} col={SUC}/>
                    <Chip ico="🎯" label={t.examType||'Custom'} col={PRP}/>
                  </div>

                  {/* sections breakdown — 29.2 */}
                  {sqEntries.length>0 && (
                    <div style={{fontSize:10,color:DIM,marginBottom:10,overflow:'hidden',whiteSpace:'nowrap' as any,textOverflow:'ellipsis'}}>
                      {sqEntries.map(([s,n])=>`${s} ${n}`).join(' · ')}
                    </div>
                  )}

                  {/* usage heat bar — 29.4 / 29.6 */}
                  <div style={{marginBottom:10}}>
                    <div style={{display:'flex',justifyContent:'space-between',fontSize:9,color:DIM,marginBottom:4}}>
                      <span>Used {t.usageCount||0} time{(t.usageCount||0)!==1?'s':''}</span>
                      <span>{timeAgo(t.lastUsedAt)}</span>
                    </div>
                    <div style={{height:4,borderRadius:3,background:'rgba(255,255,255,0.06)',overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${Math.max(usagePct,t.usageCount?4:0)}%`,background:`linear-gradient(90deg,${col},${ACC})`,borderRadius:3,transition:'width 0.4s'}}/>
                    </div>
                  </div>

                  {/* action row */}
                  <div style={{display:'flex',gap:6,marginBottom:8}}>
                    <button onClick={()=>setPreviewT(t)} title="Preview" style={{...bg_,flex:1,padding:'7px 0',fontSize:11,textAlign:'center' as any}}>👁 Preview</button>
                    <button onClick={()=>openEdit(t)} title="Edit" style={{...bg_,padding:'7px 10px',fontSize:11}}>✏️</button>
                    <button onClick={()=>duplicateTemplate(t)} disabled={busy} title="Duplicate" style={{...bg_,padding:'7px 10px',fontSize:11,opacity:busy?0.6:1}}>{busy?<span className="et-spin">⟳</span>:'⧉'}</button>
                    <button onClick={()=>openVersions(t)} title="Version history" style={{...bg_,padding:'7px 10px',fontSize:11}}>🕒</button>
                    <button onClick={()=>setDeleteConfirm(t)} title="Delete" style={{...bg_,padding:'7px 10px',fontSize:11,color:DNG,borderColor:`${DNG}33`}}>🗑</button>
                  </div>

                  <button className="et-apply-btn" onClick={()=>applyTemplateAction(t)} disabled={applying} style={{...bpAcc,width:'100%',padding:'10px',fontSize:12.5,boxShadow:`0 4px 16px ${ACC}44`,opacity:applying?0.7:1}}>
                    {applying ? <span className="et-spin">⟳</span> : '✓ Apply Template'}
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* ══ CREATE / EDIT MODAL — 29.2 / 29.9 ═══════════════════════════════════ */}
      {showForm && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.7)',backdropFilter:'blur(4px)',zIndex:200,display:'flex',alignItems:'flex-start',justifyContent:'center',padding:'20px 14px',overflowY:'auto' as any}} onClick={()=>setShowForm(false)}>
          <div onClick={e=>e.stopPropagation()} style={{...cs,width:'100%',maxWidth:520,marginTop:10}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:TS,marginBottom:16}}>{editingId?'✏️ Edit Template':'+ New Template'}</div>

            <div style={{display:'flex',flexDirection:'column' as any,gap:12}}>
              <div>
                <label style={lbl}>Icon</label>
                <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
                  {ICONS.map(ic=>(
                    <button key={ic} onClick={()=>setForm((f:any)=>({...f,icon:ic}))} style={{width:34,height:34,borderRadius:9,fontSize:16,cursor:'pointer',background:form.icon===ic?`${ACC}26`:'rgba(255,255,255,0.04)',border:`1.5px solid ${form.icon===ic?ACC:BOR}`}}>{ic}</button>
                  ))}
                </div>
              </div>

              <div>
                <label style={lbl}>Template Name *</label>
                <input value={form.name} onChange={e=>setForm((f:any)=>({...f,name:e.target.value}))} placeholder="e.g. NEET Full Mock" style={inp}/>
              </div>

              <div>
                <label style={lbl}>Title Format <span style={{textTransform:'none' as any,fontWeight:400,color:DIM}}>— tokens: {'{name} {date} {category} {n}'}</span></label>
                <input value={form.titleFormat} onChange={e=>setForm((f:any)=>({...f,titleFormat:e.target.value}))} placeholder="{name} - {date}" style={inp}/>
                <div style={{fontSize:10,color:SUC,marginTop:4}}>Preview: {previewTitle(form)}</div>
              </div>

              <div>
                <label style={lbl}>Category</label>
                <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
                  {categories.map(c=>(
                    <button key={c.name} onClick={()=>setForm((f:any)=>({...f,category:c.name,categoryColor:c.color}))} style={{display:'flex',alignItems:'center',gap:5,padding:'6px 11px',borderRadius:18,fontSize:11,fontWeight:700,cursor:'pointer',background:form.category===c.name?c.color:`${c.color}14`,color:form.category===c.name?'#fff':c.color,border:`1px solid ${c.color}44`}}>
                      <span style={{width:6,height:6,borderRadius:'50%',background:form.category===c.name?'#fff':c.color}}/>{c.name}
                    </button>
                  ))}
                  <button onClick={()=>setShowNewCat(p=>!p)} style={{padding:'6px 11px',borderRadius:18,fontSize:11,fontWeight:700,cursor:'pointer',background:'rgba(255,255,255,0.04)',color:DIM,border:`1px dashed ${BOR}`}}>+ New</button>
                </div>
                {showNewCat && (
                  <div style={{marginTop:10,padding:12,background:'rgba(0,0,0,0.2)',borderRadius:10,border:`1px solid ${BOR}`}}>
                    <input value={newCatName} onChange={e=>setNewCatName(e.target.value)} placeholder="e.g. RPSC" style={{...inp,marginBottom:8,fontSize:12}}/>
                    <div style={{display:'flex',gap:6,flexWrap:'wrap' as any,marginBottom:10,alignItems:'center'}}>
                      {SWATCHES.map(sw=>(
                        <button key={sw} onClick={()=>setNewCatColor(sw)} style={{width:24,height:24,borderRadius:'50%',background:sw,cursor:'pointer',border:newCatColor===sw?'2px solid #fff':'2px solid transparent',boxShadow:newCatColor===sw?`0 0 0 2px ${sw}`:'none'}}/>
                      ))}
                      <input type="color" value={newCatColor} onChange={e=>setNewCatColor(e.target.value)} style={{width:28,height:24,borderRadius:6,border:'none',cursor:'pointer',background:'transparent'}}/>
                    </div>
                    <button onClick={createCategory} disabled={savingCat} style={{...bpAcc,fontSize:11,padding:'7px 14px'}}>{savingCat?'Saving...':'Add Category'}</button>
                  </div>
                )}
              </div>

              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div>
                  <label style={lbl}>Exam Type</label>
                  <select value={form.examType} onChange={e=>setForm((f:any)=>({...f,examType:e.target.value}))} style={inp}>
                    {EXAM_TYPES.map(et=><option key={et} value={et}>{et}</option>)}
                  </select>
                </div>
                <div>
                  <label style={lbl}>Duration (min)</label>
                  <input type="number" value={form.duration} onChange={e=>setForm((f:any)=>({...f,duration:parseInt(e.target.value)||0}))} style={inp}/>
                </div>
              </div>

              <div>
                <label style={lbl}>Subject-wise Questions</label>
                <div style={{display:'flex',flexDirection:'column' as any,gap:6}}>
                  {Object.entries(form.subjectQs||{}).map(([subj,cnt]:[string,any])=>(
                    <div key={subj} style={{display:'flex',gap:6,alignItems:'center'}}>
                      <select value={subj} onChange={e=>renameSubjectQ(subj,e.target.value)} style={{...inp,flex:1}}>
                        {SUBJECTS.map(s=><option key={s} value={s}>{s}</option>)}
                      </select>
                      <input type="number" value={cnt} onChange={e=>setSubjectQ(subj,parseInt(e.target.value)||0)} style={{...inp,width:80}}/>
                      <button onClick={()=>removeSubjectQ(subj)} style={{background:'transparent',border:'none',color:DNG,cursor:'pointer',fontSize:15}}>✕</button>
                    </div>
                  ))}
                  <button onClick={addSubjectQ} style={{...bg_,fontSize:11,padding:'6px 12px',alignSelf:'flex-start' as any}}>+ Add Subject</button>
                </div>
                <div style={{fontSize:10,color:DIM,marginTop:6}}>Total Questions: <b style={{color:TS}}>{form.totalQs||0}</b> · Total Marks: <b style={{color:GOLD}}>{totalMarksPreview}</b></div>
              </div>

              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div>
                  <label style={lbl}>Marks per Correct</label>
                  <input type="number" value={form.correctMarks} onChange={e=>setForm((f:any)=>({...f,correctMarks:parseFloat(e.target.value)||0}))} style={inp}/>
                </div>
                <div>
                  <label style={lbl}>Negative Marks</label>
                  <input type="number" value={form.negativeMarks} onChange={e=>setForm((f:any)=>({...f,negativeMarks:parseFloat(e.target.value)||0}))} style={inp}/>
                </div>
              </div>

              <div>
                <label style={lbl}>Instructions (optional)</label>
                <textarea value={form.instructions} onChange={e=>setForm((f:any)=>({...f,instructions:e.target.value}))} rows={3} style={{...inp,resize:'vertical' as any,fontFamily:'Inter,sans-serif'}}/>
              </div>
            </div>

            <div style={{display:'flex',gap:10,marginTop:18}}>
              <button onClick={()=>setShowForm(false)} style={{...bg_,flex:1}}>Cancel</button>
              <button onClick={saveTemplate} disabled={saving} style={{...bpAcc,flex:1,opacity:saving?0.7:1}}>{saving?'Saving...':editingId?'Save Changes':'Create Template'}</button>
            </div>
          </div>
        </div>
      )}

      {/* ══ PREVIEW MODAL — 29.7 ════════════════════════════════════════════════ */}
      {previewT && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.7)',backdropFilter:'blur(4px)',zIndex:200,display:'flex',alignItems:'center',justifyContent:'center',padding:14}} onClick={()=>setPreviewT(null)}>
          <div onClick={e=>e.stopPropagation()} style={{...cs,width:'100%',maxWidth:440,maxHeight:'88vh',overflowY:'auto' as any}}>
            <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:14}}>
              <div style={{fontSize:28}}>{previewT.icon||'📋'}</div>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:TS}}>{previewT.name}</div>
                <span style={{fontSize:9,fontWeight:700,color:previewT.categoryColor||PRP,background:`${previewT.categoryColor||PRP}16`,border:`1px solid ${previewT.categoryColor||PRP}33`,borderRadius:6,padding:'2px 7px'}}>{previewT.category}</span>
              </div>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:12}}>
              <Chip ico="⏱" label={`${previewT.duration} min`} col={ACC}/>
              <Chip ico="📊" label={`${previewT.totalMarks} marks`} col={GOLD}/>
              <Chip ico="❓" label={`${previewT.totalQs} questions`} col={SUC}/>
              <Chip ico="🎯" label={previewT.examType} col={PRP}/>
              <Chip ico="✅" label={`+${previewT.correctMarks} correct`} col={SUC}/>
              <Chip ico="❌" label={`-${previewT.negativeMarks} wrong`} col={DNG}/>
            </div>
            {Object.keys(previewT.subjectQs||{}).length>0 && (
              <div style={{marginBottom:12}}>
                <label style={lbl}>Sections</label>
                <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
                  {Object.entries(previewT.subjectQs).map(([s,n]:[string,any])=><Chip key={s} ico="📚" label={`${s}: ${n}`} col={DIM}/>)}
                </div>
              </div>
            )}
            <div style={{fontSize:11,color:DIM,marginBottom:4}}>Resolved title preview:</div>
            <div style={{fontSize:13,color:TS,fontWeight:600,marginBottom:12,background:'rgba(255,255,255,0.03)',padding:'8px 10px',borderRadius:8}}>{previewTitle(previewT)}</div>
            {previewT.instructions && <div style={{fontSize:11,color:DIM,marginBottom:12,lineHeight:1.6}}>{previewT.instructions}</div>}
            <div style={{fontSize:10,color:DIM,marginBottom:14}}>Used {previewT.usageCount||0} time{(previewT.usageCount||0)!==1?'s':''} · {timeAgo(previewT.lastUsedAt)}</div>
            <div style={{display:'flex',gap:8}}>
              <button onClick={()=>setPreviewT(null)} style={{...bg_,flex:1}}>Close</button>
              <button onClick={()=>{ const t=previewT; setPreviewT(null); applyTemplateAction(t) }} style={{...bpAcc,flex:1}}>✓ Apply Template</button>
            </div>
          </div>
        </div>
      )}

      {/* ══ VERSION HISTORY MODAL — 29.9 ════════════════════════════════════════ */}
      {versionsT && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.7)',backdropFilter:'blur(4px)',zIndex:200,display:'flex',alignItems:'center',justifyContent:'center',padding:14}} onClick={()=>setVersionsT(null)}>
          <div onClick={e=>e.stopPropagation()} style={{...cs,width:'100%',maxWidth:440,maxHeight:'80vh',overflowY:'auto' as any}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:TS,marginBottom:4}}>🕒 Version History</div>
            <div style={{fontSize:11,color:DIM,marginBottom:14}}>{versionsT.name}</div>
            {versionsLoading ? (
              <div style={{textAlign:'center' as any,padding:24,color:DIM}}><span className="et-spin">⟳</span></div>
            ) : versions.length===0 ? (
              <div style={{fontSize:12,color:DIM,textAlign:'center' as any,padding:'20px 0'}}>No previous versions yet — edits will be tracked here.</div>
            ) : (
              <div style={{display:'flex',flexDirection:'column' as any,gap:8}}>
                {versions.map((v,i)=>(
                  <div key={i} style={{padding:'10px 12px',borderRadius:10,background:'rgba(255,255,255,0.03)',border:`1px solid ${BOR}`}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:6}}>
                      <div style={{fontSize:12,fontWeight:700,color:TS}}>{v.name}</div>
                      <button onClick={()=>restoreVersion(i)} style={{...bg_,fontSize:10,padding:'4px 10px',color:SUC,borderColor:`${SUC}33`}}>↺ Restore</button>
                    </div>
                    <div style={{fontSize:10,color:DIM}}>{v.totalQs} Qs · {v.duration} min · {v.totalMarks} marks · saved {timeAgo(v.savedAt)}</div>
                  </div>
                ))}
              </div>
            )}
            <button onClick={()=>setVersionsT(null)} style={{...bg_,width:'100%',marginTop:14}}>Close</button>
          </div>
        </div>
      )}

      {/* ══ DELETE CONFIRM ══════════════════════════════════════════════════════ */}
      {deleteConfirm && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.7)',backdropFilter:'blur(4px)',zIndex:210,display:'flex',alignItems:'center',justifyContent:'center',padding:14}} onClick={()=>setDeleteConfirm(null)}>
          <div onClick={e=>e.stopPropagation()} style={{...cs,width:'100%',maxWidth:340,borderColor:`${DNG}33`}}>
            <div style={{fontSize:14,fontWeight:700,color:TS,marginBottom:8}}>🗑 Delete Template?</div>
            <div style={{fontSize:12,color:DIM,marginBottom:18}}>"{deleteConfirm.name}" permanently delete ho jaayega. Ye undo nahi ho sakta.</div>
            <div style={{display:'flex',gap:8}}>
              <button onClick={()=>setDeleteConfirm(null)} style={{...bg_,flex:1}}>Cancel</button>
              <button onClick={()=>deleteTemplate(deleteConfirm)} style={{...bp,flex:1,background:`linear-gradient(135deg,${DNG},#9B0000)`}}>Delete</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
