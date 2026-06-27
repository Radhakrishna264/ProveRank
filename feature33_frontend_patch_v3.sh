#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
#  ProveRank — Feature 33 — FRONTEND patch v3
#  v2: fixed exam card layout bug + added Preview Exam button/modal
#  v3: Preview Exam now also supports — Explanation (hidden by default, per-
#      question toggle) + Hindi/English toggle (auto-shown only if available)
#  No other files touched — only AllExams.tsx is rewritten.
# ════════════════════════════════════════════════════════════════════════════
set -e
echo "════════════════════════════════════════════════"
echo " Feature 33 — FRONTEND patch v3 (Explanation + Hindi/English toggle)"
echo "════════════════════════════════════════════════"

PAGE_FILE=$(grep -rl "import CreateExamWizard from './CreateExamWizard'" --include="*.tsx" . 2>/dev/null | head -1)
if [ -z "$PAGE_FILE" ]; then
  echo "❌ page.tsx nahi mila. Frontend project root se chalao."
  exit 1
fi
DIR=$(dirname "$PAGE_FILE")
ALLEXAMS_FILE="$DIR/AllExams.tsx"
echo "✓ Admin folder mila: $DIR"

if [ -f "$ALLEXAMS_FILE" ]; then
  cp "$ALLEXAMS_FILE" "$ALLEXAMS_FILE.bak_feat33_v3"
  echo "✓ Backup bana: $ALLEXAMS_FILE.bak_feat33_v3"
fi
echo ""
echo "→ Rewriting $ALLEXAMS_FILE ..."
cat > "$ALLEXAMS_FILE" << '__PRRANK_EOF_ALLEXAMS3__'
'use client'
import { useState, useEffect, useCallback } from 'react'

// ── Design tokens (locked: Neon Blue + Glassmorphism + Playfair/Inter) ──
const ACC='#4D9FFF', TS='#E8F4FF', DIM='#6B8FAF', GOLD='#FFD700'
const SUC='#00C48C', DNG='#FF4D4D', WRN='#FFB84D', PRP='#A78BFA'
const BOR='rgba(77,159,255,0.16)', CRD='rgba(0,15,35,0.88)'

const bp:any={background:`linear-gradient(135deg,${PRP},#6D28D9)`,color:'#fff',border:'none',borderRadius:10,padding:'11px 22px',cursor:'pointer',fontWeight:700,fontSize:13,transition:'all 0.2s'}
const bpAcc:any={...bp,background:`linear-gradient(135deg,${ACC},#0055CC)`}
const bg_:any={background:'rgba(0,25,55,0.7)',color:TS,border:`1px solid ${BOR}`,borderRadius:10,padding:'10px 18px',cursor:'pointer',fontSize:12,transition:'all 0.2s'}
const inp:any={width:'100%',padding:'10px 13px',background:'rgba(0,12,30,0.9)',border:`1.5px solid ${BOR}`,borderRadius:10,color:TS,fontSize:13,outline:'none',boxSizing:'border-box' as any,fontFamily:'Inter,sans-serif'}
const lbl:any={display:'block',fontSize:10,color:DIM,marginBottom:5,fontWeight:700,letterSpacing:0.6,textTransform:'uppercase' as any}
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:16,padding:'18px',backdropFilter:'blur(14px)'}

// ── Status mapping — real schema enum (draft/scheduled/live/ended) shown as
// the spec's own labels (Draft/Upcoming/Active/Completed) — 33.3 / 33.19 ──
const STATUS_META: Record<string,{label:string,color:string,icon:string}> = {
  draft:     { label:'Draft',     color: DIM, icon:'📝' },
  scheduled: { label:'Upcoming',  color: ACC, icon:'⏳' },
  live:      { label:'Active',    color: SUC, icon:'🟢' },
  ended:     { label:'Completed', color: PRP, icon:'✅' },
}
const STATUS_ORDER = ['draft','scheduled','live','ended']

interface Props { token:string; API:string; T:(m:string,t?:'s'|'e'|'w')=>void; onCreateNew:()=>void }

function fmtDate(d:any){ if(!d) return null; const dt=new Date(d); return isNaN(dt.getTime())?null:dt }
function fmtDateStr(d:any){ const dt=fmtDate(d); return dt? dt.toLocaleString('en-IN',{day:'2-digit',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit'}) : 'No schedule set' }

function countdownLabel(startTime:any, now:number){
  const dt = fmtDate(startTime)
  if(!dt) return null
  const diff = dt.getTime() - now
  if(diff<=0) return null
  const mins = Math.floor(diff/60000)
  if(mins<60) return `Starts in ${mins}m`
  const hrs = Math.floor(mins/60)
  if(hrs<24) return `Starts in ${hrs}h`
  const days = Math.floor(hrs/24)
  return `Starts in ${days}d`
}

function Chip({ico,label,col}:{ico:string;label:string;col?:string}){
  const c = col || DIM
  return <span style={{display:'inline-flex',alignItems:'center',gap:4,fontSize:10,fontWeight:600,color:c,background:`${c}14`,border:`1px solid ${c}2E`,borderRadius:7,padding:'3px 8px',whiteSpace:'nowrap' as any}}>{ico} {label}</span>
}

function EmptyIllustration(){
  return (
    <svg width="120" height="120" viewBox="0 0 120 120" fill="none" style={{opacity:0.85}}>
      <rect x="28" y="14" width="64" height="92" rx="10" fill="rgba(77,159,255,0.08)" stroke={ACC} strokeWidth="2"/>
      <rect x="44" y="6" width="32" height="14" rx="5" fill="#0A1830" stroke={PRP} strokeWidth="2"/>
      <line x1="40" y1="40" x2="80" y2="40" stroke={DIM} strokeWidth="3" strokeLinecap="round"/>
      <line x1="40" y1="52" x2="80" y2="52" stroke={DIM} strokeWidth="3" strokeLinecap="round"/>
      <line x1="40" y1="64" x2="64" y2="64" stroke={DIM} strokeWidth="3" strokeLinecap="round"/>
      <circle cx="72" cy="86" r="16" fill="rgba(0,196,140,0.12)" stroke={SUC} strokeWidth="2.5"/>
      <path d="M65 86l4.5 4.5L80 79" stroke={SUC} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
    </svg>
  )
}

export default function AllExams({ token, API, T, onCreateNew }: Props) {
  const isSuperAdmin = typeof window!=='undefined' && localStorage.getItem('pr_role')==='superadmin'
  const hdrs = { 'Content-Type':'application/json', Authorization:`Bearer ${token}` }

  const [exams, setExams] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<any>({total:0,draft:0,scheduled:0,live:0,ended:0})
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [now, setNow] = useState(Date.now())

  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<string[]>([])
  const [categoryFilter, setCategoryFilter] = useState('')
  const [subjectFilter, setSubjectFilter] = useState('')
  const [batchFilter, setBatchFilter] = useState('')
  const [seriesFilter, setSeriesFilter] = useState('')
  const [dateStart, setDateStart] = useState('')
  const [dateEnd, setDateEnd] = useState('')
  const [sort, setSort] = useState('newest')
  const [mine, setMine] = useState(false)
  const [viewAsAdmin, setViewAsAdmin] = useState('')
  const [needsAttention, setNeedsAttention] = useState(false)
  const [showFilters, setShowFilters] = useState(false)
  const [viewMode, setViewMode] = useState<'list'|'calendar'>('list')
  const [bulkMode, setBulkMode] = useState(false)
  const [selectedIds, setSelectedIds] = useState<string[]>([])

  const [filterOptions, setFilterOptions] = useState<any>({categories:[],subjects:[],batches:[],series:[]})
  const [admins, setAdmins] = useState<any[]>([])

  const [analyticsExam, setAnalyticsExam] = useState<any>(null)
  const [analyticsData, setAnalyticsData] = useState<any>(null)
  const [analyticsLoading, setAnalyticsLoading] = useState(false)

  const [previewExam, setPreviewExam] = useState<any>(null)
  const [previewQuestions, setPreviewQuestions] = useState<any[]>([])
  const [previewLoading, setPreviewLoading] = useState(false)
  const [previewLang, setPreviewLang] = useState<'en'|'hi'>('en')
  const [expandedExplain, setExpandedExplain] = useState<Record<string,boolean>>({})

  const [editExam, setEditExam] = useState<any>(null)
  const [editForm, setEditForm] = useState<any>({})
  const [savingEdit, setSavingEdit] = useState(false)

  const [deleteConfirm, setDeleteConfirm] = useState<any>(null)
  const [busyId, setBusyId] = useState<string|null>(null)
  const [bulkBusy, setBulkBusy] = useState(false)

  const [calExams, setCalExams] = useState<any[]>([])
  const [calLoading, setCalLoading] = useState(false)
  const [calMonth, setCalMonth] = useState(()=>{ const d=new Date(); return new Date(d.getFullYear(),d.getMonth(),1) })

  // ── countdown ticker (33.16/33.26 stay fresh) ───────────────────────────────
  useEffect(()=>{ const iv=setInterval(()=>setNow(Date.now()),60000); return ()=>clearInterval(iv) },[])

  // ── debounce search (33.2) ───────────────────────────────────────────────────
  useEffect(()=>{ const tm=setTimeout(()=>setSearch(searchInput),350); return ()=>clearTimeout(tm) },[searchInput])

  // ── reset to page 1 whenever a filter changes ───────────────────────────────
  useEffect(()=>{ setPage(1) },[search,statusFilter,categoryFilter,subjectFilter,batchFilter,seriesFilter,dateStart,dateEnd,sort,mine,viewAsAdmin,needsAttention])

  const buildParams = useCallback((forExport?:boolean)=>{
    const p = new URLSearchParams()
    if(search.trim()) p.set('search',search.trim())
    if(statusFilter.length) p.set('status',statusFilter.join(','))
    if(categoryFilter) p.set('category',categoryFilter)
    if(subjectFilter) p.set('subject',subjectFilter)
    if(batchFilter) p.set('batch',batchFilter)
    if(seriesFilter) p.set('series',seriesFilter)
    if(dateStart) p.set('startDate',dateStart)
    if(dateEnd) p.set('endDate',dateEnd)
    if(sort!=='newest') p.set('sort',sort)
    if(mine) p.set('mine','true')
    if(!mine && viewAsAdmin) p.set('createdBy',viewAsAdmin)
    if(needsAttention) p.set('needsAttention','true')
    if(!forExport){ p.set('page',String(page)); p.set('limit','20') }
    return p
  },[search,statusFilter,categoryFilter,subjectFilter,batchFilter,seriesFilter,dateStart,dateEnd,sort,mine,viewAsAdmin,needsAttention,page])

  const fetchExams = useCallback(async ()=>{
    setLoading(true)
    try {
      const p = buildParams()
      const r = await fetch(`${API}/api/exams-manage/list?${p.toString()}`,{headers:{Authorization:`Bearer ${token}`}})
      const d = await r.json()
      if(d.success){ setExams(d.exams||[]); setStats(d.stats||stats); setTotalPages(d.totalPages||1) }
    } catch {}
    setLoading(false)
  },[API,token,buildParams])

  useEffect(()=>{ fetchExams() },[fetchExams])

  const fetchFilterOptions = useCallback(async ()=>{
    try {
      const r = await fetch(`${API}/api/exams-manage/filter-options`,{headers:{Authorization:`Bearer ${token}`}})
      const d = await r.json()
      if(d.success) setFilterOptions({categories:d.categories||[],subjects:d.subjects||[],batches:d.batches||[],series:d.series||[]})
    } catch {}
  },[API,token])

  const fetchAdmins = useCallback(async ()=>{
    try {
      const r = await fetch(`${API}/api/exams-manage/admins`,{headers:{Authorization:`Bearer ${token}`}})
      const d = await r.json()
      if(d.success) setAdmins(d.admins||[])
    } catch {}
  },[API,token])

  useEffect(()=>{ fetchFilterOptions() },[fetchFilterOptions])
  useEffect(()=>{ if(isSuperAdmin) fetchAdmins() },[isSuperAdmin,fetchAdmins])

  // ── 33.15 — calendar view data (separate, wider, date-bounded fetch) ────────
  const fetchCalendar = useCallback(async ()=>{
    setCalLoading(true)
    try {
      const start = new Date(calMonth.getFullYear(), calMonth.getMonth(), 1)
      const end = new Date(calMonth.getFullYear(), calMonth.getMonth()+1, 0, 23, 59, 59)
      const p = new URLSearchParams()
      p.set('startDate', start.toISOString()); p.set('endDate', end.toISOString())
      p.set('limit','100')
      if(mine) p.set('mine','true')
      if(!mine && viewAsAdmin) p.set('createdBy',viewAsAdmin)
      const r = await fetch(`${API}/api/exams-manage/list?${p.toString()}`,{headers:{Authorization:`Bearer ${token}`}})
      const d = await r.json()
      if(d.success) setCalExams(d.exams||[])
    } catch {}
    setCalLoading(false)
  },[API,token,calMonth,mine,viewAsAdmin])

  useEffect(()=>{ if(viewMode==='calendar') fetchCalendar() },[viewMode,fetchCalendar])

  // ── 33.20 — pin toggle ────────────────────────────────────────────────────────
  const togglePin = async (exam:any) => {
    setExams(p=>p.map(x=>x._id===exam._id?{...x,isPinned:!x.isPinned}:x))
    try {
      const r = await fetch(`${API}/api/exams-manage/${exam._id}/pin`,{method:'PATCH',headers:hdrs})
      await r.json()
      fetchExams()
    } catch { fetchExams() }
  }

  // ── 33.11 — quick status toggle ───────────────────────────────────────────────
  const togglePublish = async (exam:any) => {
    setBusyId(exam._id)
    try {
      const r = await fetch(`${API}/api/exams-manage/${exam._id}/publish`,{method:'PATCH',headers:hdrs})
      const d = await r.json()
      if(d.success){ T(d.message||'Status updated ✅'); fetchExams() } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setBusyId(null)
  }

  // ── 33.9 — clone (reuses existing working endpoint; it has no success:false
  // shape on error, only a non-200 status, so check r.ok) ─────────────────────
  const cloneExam = async (exam:any) => {
    setBusyId(exam._id)
    try {
      const r = await fetch(`${API}/api/exams/${exam._id}/clone`,{method:'POST',headers:hdrs})
      const d = await r.json()
      if(r.ok){ T('Exam cloned ✅'); fetchExams() } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setBusyId(null)
  }

  // ── 33.9 — delete (reuses existing working endpoint; same r.ok-based check) ──
  const deleteExam = async (exam:any) => {
    setBusyId(exam._id)
    try {
      const r = await fetch(`${API}/api/exams/${exam._id}`,{method:'DELETE',headers:{Authorization:`Bearer ${token}`}})
      const d = await r.json()
      if(r.ok){ T('Exam deleted'); setExams(p=>p.filter(x=>x._id!==exam._id)) } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setBusyId(null); setDeleteConfirm(null)
  }

  // ── 33.9 — quick edit ─────────────────────────────────────────────────────────
  const openEdit = (exam:any) => {
    setEditExam(exam)
    setEditForm({
      title: exam.title||'', category: exam.category||'Full Mock', subject: exam.subject||'NEET', type: exam.type||'NEET',
      duration: exam.duration||60, totalMarks: exam.totalMarks||0,
      correctMarks: exam.markingScheme?.correct ?? 4, incorrectMarks: exam.markingScheme?.incorrect ?? -1,
      batch: exam.batch||'', seriesName: exam.seriesName||'', watermark: !!exam.watermark,
      customInstructions: exam.customInstructions||'', status: exam.status||'draft',
      startTime: exam.schedule?.startTime ? new Date(exam.schedule.startTime).toISOString().slice(0,16) : '',
      endTime: exam.schedule?.endTime ? new Date(exam.schedule.endTime).toISOString().slice(0,16) : ''
    })
  }

  const saveEdit = async () => {
    if(!editExam) return
    setSavingEdit(true)
    try {
      const r = await fetch(`${API}/api/exams-manage/${editExam._id}/quick-edit`,{method:'PUT',headers:hdrs,body:JSON.stringify(editForm)})
      const d = await r.json()
      if(d.success){ T('Exam updated ✅'); setEditExam(null); fetchExams() } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setSavingEdit(false)
  }

  // ── NEW — Preview Exam (verify question/option content renders correctly,
  // before students attempt it). Read-only, creates no attempt record. ───────
  const openPreview = async (exam:any) => {
    setPreviewExam(exam); setPreviewLoading(true); setPreviewQuestions([])
    setPreviewLang('en'); setExpandedExplain({})
    try {
      const r = await fetch(`${API}/api/exams-manage/${exam._id}/preview`,{headers:{Authorization:`Bearer ${token}`}})
      const d = await r.json()
      if(d.success) setPreviewQuestions(d.questions||[])
      else T(d.message||'Preview load nahi ho payi','e')
    } catch { T('Network error','e') }
    setPreviewLoading(false)
  }

  const toggleExplain = (qid:string) => setExpandedExplain(p=>({...p,[qid]:!p[qid]}))

  // ── 33.14 — analytics side panel ─────────────────────────────────────────────
  const openAnalytics = async (exam:any) => {
    setAnalyticsExam(exam); setAnalyticsLoading(true); setAnalyticsData(null)
    try {
      const r = await fetch(`${API}/api/exams-manage/${exam._id}/analytics`,{headers:{Authorization:`Bearer ${token}`}})
      const d = await r.json()
      if(d.success) setAnalyticsData(d)
    } catch {}
    setAnalyticsLoading(false)
  }

  // ── 33.27 — bulk actions ──────────────────────────────────────────────────────
  const toggleSelect = (id:string) => setSelectedIds(p=>p.includes(id)?p.filter(x=>x!==id):[...p,id])
  const selectAllOnPage = () => setSelectedIds(exams.map(e=>e._id))
  const clearSelection = () => setSelectedIds([])

  const bulkDelete = async () => {
    if(!selectedIds.length) return
    setBulkBusy(true)
    try {
      const r = await fetch(`${API}/api/exams-manage/bulk-delete`,{method:'POST',headers:hdrs,body:JSON.stringify({ids:selectedIds})})
      const d = await r.json()
      if(d.success){ T(d.message||'Deleted ✅'); setSelectedIds([]); fetchExams() } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setBulkBusy(false)
  }

  const bulkPublish = async () => {
    if(!selectedIds.length) return
    setBulkBusy(true)
    try {
      const r = await fetch(`${API}/api/exams-manage/bulk-publish`,{method:'POST',headers:hdrs,body:JSON.stringify({ids:selectedIds})})
      const d = await r.json()
      if(d.success){ T(d.message||'Published ✅'); setSelectedIds([]); fetchExams() } else T(d.message||'Failed','e')
    } catch { T('Network error','e') }
    setBulkBusy(false)
  }

  // ── 33.17 — export ────────────────────────────────────────────────────────────
  const exportList = async (format:'xlsx'|'csv') => {
    try {
      const p = buildParams(true)
      p.set('format',format)
      const r = await fetch(`${API}/api/exams-manage/export?${p.toString()}`,{headers:{Authorization:`Bearer ${token}`}})
      if(!r.ok){ T('Export failed','e'); return }
      const blob = await r.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url; a.download = format==='csv'?'ProveRank_Exams.csv':'ProveRank_Exams.xlsx'
      document.body.appendChild(a); a.click(); a.remove()
      window.URL.revokeObjectURL(url)
      T('Export downloaded ✅')
    } catch { T('Export failed','e') }
  }

  const toggleStatusFilter = (s:string) => setStatusFilter(p=>p.includes(s)?p.filter(x=>x!==s):[...p,s])
  const clearAllFilters = () => { setSearchInput(''); setStatusFilter([]); setCategoryFilter(''); setSubjectFilter(''); setBatchFilter(''); setSeriesFilter(''); setDateStart(''); setDateEnd(''); setSort('newest'); setMine(false); setViewAsAdmin(''); setNeedsAttention(false) }
  const activeFilterCount = [statusFilter.length>0,!!categoryFilter,!!subjectFilter,!!batchFilter,!!seriesFilter,!!dateStart||!!dateEnd,mine,!!viewAsAdmin,needsAttention].filter(Boolean).length

  return (
    <div style={{fontFamily:'Inter,sans-serif'}}>
      <style dangerouslySetInnerHTML={{__html:`
        @keyframes aeFadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @keyframes aeSpin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes aePulse{0%,100%{box-shadow:0 0 0 0 ${ACC}66}50%{box-shadow:0 0 0 6px ${ACC}00}}
        .ae-card{animation:aeFadeIn 0.3s ease}
        .ae-spin{animation:aeSpin 0.8s linear infinite;display:inline-block}
        .ae-countdown{animation:aePulse 1.8s ease infinite}
      `}}/>

      {/* ══ HEADER ══════════════════════════════════════════════════════════════ */}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:12,marginBottom:16,flexWrap:'wrap' as any}}>
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:22,color:TS,display:'flex',alignItems:'center',gap:8}}>📝 All Exams</div>
          <div style={{fontSize:12,color:DIM,marginTop:3}}>Every exam, one place — search, filter, manage, monitor</div>
        </div>
        <div style={{display:'flex',gap:8,flexWrap:'wrap' as any}}>
          <button onClick={()=>exportList('xlsx')} style={{...bg_,fontSize:12}}>⬇️ Export</button>
          <button onClick={onCreateNew} style={{...bp,fontSize:13,boxShadow:`0 4px 18px ${PRP}44`}}>+ Create Exam</button>
        </div>
      </div>

      {/* ══ STATS BAR — 33.21 ═══════════════════════════════════════════════════ */}
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(110px,1fr))',gap:8,marginBottom:14}}>
        {[
          {label:'Total',val:stats.total,col:ACC,ico:'📊'},
          {label:'Draft',val:stats.draft,col:DIM,ico:'📝'},
          {label:'Upcoming',val:stats.scheduled,col:ACC,ico:'⏳'},
          {label:'Active',val:stats.live,col:SUC,ico:'🟢'},
          {label:'Completed',val:stats.ended,col:PRP,ico:'✅'},
        ].map(s=>(
          <div key={s.label} style={{...cs,padding:'12px 14px',textAlign:'center' as any}}>
            <div style={{fontSize:18,fontWeight:800,color:s.col}}>{s.ico} {s.val}</div>
            <div style={{fontSize:10,color:DIM,fontWeight:700,letterSpacing:0.4,textTransform:'uppercase' as any,marginTop:2}}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* ══ TOOLBAR — search + view toggle + bulk toggle — 33.24/33.25/33.27 ════ */}
      <div style={{...cs,padding:'14px',marginBottom:12}}>
        <div style={{display:'flex',gap:8,alignItems:'center',flexWrap:'wrap' as any}}>
          <input value={searchInput} onChange={e=>setSearchInput(e.target.value)} placeholder="🔍 Search exams by title..." style={{...inp,flex:1,minWidth:200}}/>
          <button onClick={()=>setShowFilters(p=>!p)} style={{...bg_,fontSize:12,background:activeFilterCount>0?`${ACC}22`:bg_.background,borderColor:activeFilterCount>0?ACC:BOR}}>
            🎛 Filters{activeFilterCount>0?` (${activeFilterCount})`:''}
          </button>
          <div style={{display:'flex',background:'rgba(255,255,255,0.04)',borderRadius:10,border:`1px solid ${BOR}`,padding:2}}>
            <button onClick={()=>setViewMode('list')} title="List view" style={{background:viewMode==='list'?`${ACC}33`:'transparent',border:'none',color:viewMode==='list'?TS:DIM,borderRadius:8,padding:'7px 11px',cursor:'pointer',fontSize:13}}>≡</button>
            <button onClick={()=>setViewMode('calendar')} title="Calendar view" style={{background:viewMode==='calendar'?`${ACC}33`:'transparent',border:'none',color:viewMode==='calendar'?TS:DIM,borderRadius:8,padding:'7px 11px',cursor:'pointer',fontSize:13}}>📅</button>
          </div>
          <button onClick={()=>{setBulkMode(p=>!p);setSelectedIds([])}} style={{...bg_,fontSize:12,background:bulkMode?`${PRP}22`:bg_.background,borderColor:bulkMode?PRP:BOR,color:bulkMode?PRP:TS}}>☑️ Bulk Select</button>
        </div>

        {showFilters && (
          <div style={{marginTop:14,paddingTop:14,borderTop:`1px solid ${BOR}`,display:'flex',flexDirection:'column' as any,gap:12}}>
            {/* status pills — 33.3 */}
            <div>
              <label style={lbl}>Status</label>
              <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
                {STATUS_ORDER.map(s=>{
                  const m = STATUS_META[s]; const active = statusFilter.includes(s)
                  return (
                    <button key={s} onClick={()=>toggleStatusFilter(s)} style={{display:'flex',alignItems:'center',gap:5,padding:'6px 12px',borderRadius:18,fontSize:11,fontWeight:700,cursor:'pointer',background:active?m.color:`${m.color}14`,color:active?'#fff':m.color,border:`1px solid ${m.color}44`}}>
                      {m.icon} {m.label}
                    </button>
                  )
                })}
              </div>
            </div>

            {/* category / subject — 33.4 */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
              <div>
                <label style={lbl}>Category</label>
                <select value={categoryFilter} onChange={e=>setCategoryFilter(e.target.value)} style={inp}>
                  <option value="">All Categories</option>
                  {filterOptions.categories.map((c:string)=><option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label style={lbl}>Subject</label>
                <select value={subjectFilter} onChange={e=>setSubjectFilter(e.target.value)} style={inp}>
                  <option value="">All Subjects</option>
                  {filterOptions.subjects.map((s:string)=><option key={s} value={s}>{s}</option>)}
                </select>
              </div>
            </div>

            {/* batch / series — 33.5 */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
              <div>
                <label style={lbl}>Batch</label>
                <select value={batchFilter} onChange={e=>setBatchFilter(e.target.value)} style={inp}>
                  <option value="">All Batches</option>
                  {filterOptions.batches.map((b:string)=><option key={b} value={b}>{b}</option>)}
                </select>
              </div>
              <div>
                <label style={lbl}>Test Series</label>
                <select value={seriesFilter} onChange={e=>setSeriesFilter(e.target.value)} style={inp}>
                  <option value="">All Series</option>
                  {filterOptions.series.map((s:string)=><option key={s} value={s}>{s}</option>)}
                </select>
              </div>
            </div>

            {/* date range — 33.6 */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
              <div>
                <label style={lbl}>From Date</label>
                <input type="date" value={dateStart} onChange={e=>setDateStart(e.target.value)} style={inp}/>
              </div>
              <div>
                <label style={lbl}>To Date</label>
                <input type="date" value={dateEnd} onChange={e=>setDateEnd(e.target.value)} style={inp}/>
              </div>
            </div>

            {/* sort — 33.8 */}
            <div>
              <label style={lbl}>Sort By</label>
              <select value={sort} onChange={e=>setSort(e.target.value)} style={inp}>
                <option value="newest">Newest First</option>
                <option value="oldest">Oldest First</option>
                <option value="dateAsc">Exam Date — Ascending</option>
                <option value="dateDesc">Exam Date — Descending</option>
              </select>
            </div>

            {/* my created exams / admin picker — 33.12 */}
            <div style={{display:'flex',gap:10,alignItems:'center',flexWrap:'wrap' as any}}>
              <label style={{display:'flex',alignItems:'center',gap:7,fontSize:12,color:TS,cursor:'pointer'}}>
                <input type="checkbox" checked={mine} onChange={e=>{setMine(e.target.checked); if(e.target.checked) setViewAsAdmin('')}}/>
                My Created Exams
              </label>
              {isSuperAdmin && !mine && (
                <select value={viewAsAdmin} onChange={e=>setViewAsAdmin(e.target.value)} style={{...inp,maxWidth:240}}>
                  <option value="">All Admins</option>
                  {admins.map(a=><option key={a._id} value={a._id}>{a.name||a.email} ({a.examCount})</option>)}
                </select>
              )}
            </div>

            {/* needs attention — 33.18 */}
            <label style={{display:'flex',alignItems:'center',gap:7,fontSize:12,color:WRN,cursor:'pointer'}}>
              <input type="checkbox" checked={needsAttention} onChange={e=>setNeedsAttention(e.target.checked)}/>
              ⚠️ Needs Attention (no batch assigned / 0 questions)
            </label>

            {activeFilterCount>0 && <button onClick={clearAllFilters} style={{...bg_,fontSize:11,alignSelf:'flex-start' as any,color:DNG,borderColor:`${DNG}33`}}>✕ Clear All Filters</button>}
          </div>
        )}
      </div>

      {/* ══ BULK ACTION BAR — 33.27 ══════════════════════════════════════════════ */}
      {bulkMode && selectedIds.length>0 && (
        <div style={{...cs,padding:'10px 16px',marginBottom:12,display:'flex',alignItems:'center',justifyContent:'space-between',gap:10,flexWrap:'wrap' as any,borderColor:`${PRP}44`}}>
          <span style={{fontSize:12,color:TS,fontWeight:600}}>{selectedIds.length} exam(s) selected</span>
          <div style={{display:'flex',gap:8,flexWrap:'wrap' as any}}>
            <button onClick={selectAllOnPage} style={{...bg_,fontSize:11}}>Select all on page</button>
            <button onClick={clearSelection} style={{...bg_,fontSize:11}}>Clear</button>
            <button onClick={bulkPublish} disabled={bulkBusy} style={{...bg_,fontSize:11,color:SUC,borderColor:`${SUC}33`}}>{bulkBusy?<span className="ae-spin">⟳</span>:'📢 Publish Selected'}</button>
            <button onClick={bulkDelete} disabled={bulkBusy} style={{...bg_,fontSize:11,color:DNG,borderColor:`${DNG}33`}}>{bulkBusy?<span className="ae-spin">⟳</span>:'🗑 Delete Selected'}</button>
          </div>
        </div>
      )}

      {/* ══ LIST VIEW ════════════════════════════════════════════════════════════ */}
      {viewMode==='list' && (loading ? (
        <div style={{textAlign:'center' as any,padding:'60px 20px',color:DIM}}><span className="ae-spin" style={{fontSize:24}}>⟳</span><div style={{marginTop:10,fontSize:12}}>Loading exams...</div></div>
      ) : exams.length===0 ? (
        <div style={{...cs,textAlign:'center' as any,padding:'48px 24px'}}>
          <div style={{display:'flex',justifyContent:'center',marginBottom:10}}><EmptyIllustration/></div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:TS,marginBottom:6}}>No exams yet</div>
          <div style={{fontSize:12,color:DIM,marginBottom:20}}>Create your first exam to get started →</div>
          <button onClick={onCreateNew} style={{...bp,fontSize:13}}>+ Create Your First Exam</button>
        </div>
      ) : (
        <div style={{display:'flex',flexDirection:'column' as any,gap:12}}>
          {exams.map(e=>{
            const meta = STATUS_META[e.status] || STATUS_META.draft
            const cd = e.status==='scheduled' ? countdownLabel(e.schedule?.startTime, now) : null
            const needsAttn = (!e.batch) || (e.questionCount===0)
            const selected = selectedIds.includes(e._id)
            const busy = busyId===e._id
            return (
              <div key={e._id} className="ae-card" style={{position:'relative' as any,overflow:'hidden',borderRadius:16,background:CRD,border:`1px solid ${BOR}`,borderLeft:`4px solid ${meta.color}`,backdropFilter:'blur(14px)',boxShadow:'0 4px 18px rgba(0,0,0,0.3)'}}>
                <div style={{position:'absolute',top:0,left:0,right:0,height:3,background:`linear-gradient(90deg,${meta.color},${meta.color}00 85%)`}}/>

                <div style={{padding:'14px 16px 12px',display:'flex',gap:10,alignItems:'flex-start'}}>
                  {bulkMode && (
                    <input type="checkbox" checked={selected} onChange={()=>toggleSelect(e._id)} style={{marginTop:4,width:16,height:16,cursor:'pointer',flexShrink:0}}/>
                  )}
                  <div style={{flex:1,minWidth:0,cursor:'pointer'}} onClick={()=>openAnalytics(e)}>
                    <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:8,flexWrap:'wrap' as any}}>
                      {e.isPinned && <span title="Pinned" style={{color:GOLD,fontSize:13}}>📌</span>}
                      <span style={{fontWeight:700,fontSize:14,color:TS,fontFamily:'Playfair Display,serif'}}>{e.title}</span>
                      <span style={{display:'inline-flex',alignItems:'center',gap:4,fontSize:10,fontWeight:700,color:meta.color,background:`${meta.color}18`,border:`1px solid ${meta.color}44`,borderRadius:20,padding:'3px 10px',boxShadow:e.status==='live'?`0 0 10px ${SUC}66`:'none'}}>{meta.icon} {meta.label}</span>
                      {cd && <span className="ae-countdown" style={{fontSize:10,fontWeight:700,color:WRN,background:`${WRN}18`,border:`1px solid ${WRN}44`,borderRadius:20,padding:'3px 10px'}}>⏰ {cd}</span>}
                      {needsAttn && <span title="Needs attention" style={{fontSize:10,fontWeight:700,color:DNG,background:`${DNG}18`,border:`1px solid ${DNG}44`,borderRadius:20,padding:'3px 10px'}}>⚠️ Needs attention</span>}
                    </div>
                    <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
                      <Chip ico="📅" label={fmtDateStr(e.schedule?.startTime)} col={ACC}/>
                      <Chip ico="⏱" label={`${e.duration||0} min`} col={ACC}/>
                      <Chip ico="📊" label={`${e.totalMarks||0} marks`} col={GOLD}/>
                      <Chip ico="👥" label={`${e.studentCount||0} students`} col={SUC}/>
                      <Chip ico="❓" label={`${e.questionCount||0} Qs`} col={PRP}/>
                      {e.category && <Chip ico="📐" label={e.category} col={DIM}/>}
                      {e.batch && <Chip ico="📦" label={e.batch} col={DIM}/>}
                    </div>
                  </div>
                </div>

                <div style={{height:1,background:'rgba(255,255,255,0.06)',margin:'0 16px'}}/>

                <div style={{display:'flex',gap:6,padding:'10px 14px',overflowX:'auto' as any}}>
                  <button onClick={()=>togglePin(e)} title={e.isPinned?'Unpin':'Pin to top'} style={{...bg_,flexShrink:0,padding:'7px 12px',fontSize:11,color:e.isPinned?GOLD:DIM,borderColor:e.isPinned?`${GOLD}44`:BOR}}>📌 {e.isPinned?'Pinned':'Pin'}</button>
                  <button onClick={()=>togglePublish(e)} disabled={busy} title="Toggle status" style={{...bg_,flexShrink:0,padding:'7px 12px',fontSize:11,color:e.status==='draft'?SUC:WRN,borderColor:e.status==='draft'?`${SUC}44`:`${WRN}44`}}>
                    {busy?<span className="ae-spin">⟳</span>:(e.status==='draft'?'📢 Publish':'↩️ Unpublish')}
                  </button>
                  <div style={{width:1,background:'rgba(255,255,255,0.08)',flexShrink:0,margin:'2px 2px'}}/>
                  <button onClick={()=>openPreview(e)} title="Preview as student — check questions/options render correctly" style={{...bg_,flexShrink:0,padding:'7px 11px',fontSize:13,color:ACC}}>👁</button>
                  <button onClick={()=>openEdit(e)} title="Edit" style={{...bg_,flexShrink:0,padding:'7px 11px',fontSize:13}}>✏️</button>
                  <button onClick={()=>cloneExam(e)} title="Clone" disabled={busy} style={{...bg_,flexShrink:0,padding:'7px 11px',fontSize:13}}>⧉</button>
                  <button onClick={()=>openAnalytics(e)} title="View Results" style={{...bg_,flexShrink:0,padding:'7px 11px',fontSize:13}}>📈</button>
                  <button onClick={()=>setDeleteConfirm(e)} title="Delete" style={{...bg_,flexShrink:0,padding:'7px 11px',fontSize:13,color:DNG,borderColor:`${DNG}33`}}>🗑</button>
                </div>
              </div>
            )
          })}
        </div>
      ))}

      {/* ══ PAGINATION — 33.10 ══════════════════════════════════════════════════ */}
      {viewMode==='list' && !loading && exams.length>0 && totalPages>1 && (
        <div style={{display:'flex',justifyContent:'center',alignItems:'center',gap:10,marginTop:18}}>
          <button onClick={()=>setPage(p=>Math.max(1,p-1))} disabled={page<=1} style={{...bg_,fontSize:12,opacity:page<=1?0.4:1}}>← Prev</button>
          <span style={{fontSize:12,color:DIM}}>Page {page} of {totalPages}</span>
          <button onClick={()=>setPage(p=>Math.min(totalPages,p+1))} disabled={page>=totalPages} style={{...bg_,fontSize:12,opacity:page>=totalPages?0.4:1}}>Next →</button>
        </div>
      )}

      {/* ══ CALENDAR VIEW — 33.15 ════════════════════════════════════════════════ */}
      {viewMode==='calendar' && (
        <div style={cs}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
            <button onClick={()=>setCalMonth(d=>new Date(d.getFullYear(),d.getMonth()-1,1))} style={{...bg_,fontSize:12,padding:'6px 12px'}}>←</button>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:TS}}>{calMonth.toLocaleString('en-IN',{month:'long',year:'numeric'})}</div>
            <button onClick={()=>setCalMonth(d=>new Date(d.getFullYear(),d.getMonth()+1,1))} style={{...bg_,fontSize:12,padding:'6px 12px'}}>→</button>
          </div>
          {calLoading ? (
            <div style={{textAlign:'center' as any,padding:'40px 0',color:DIM}}><span className="ae-spin" style={{fontSize:22}}>⟳</span></div>
          ) : (
            <CalendarGrid month={calMonth} exams={calExams} onDayClick={(d:Date)=>{ setDateStart(d.toISOString().slice(0,10)); setDateEnd(d.toISOString().slice(0,10)); setViewMode('list'); setShowFilters(true) }} onExamClick={openAnalytics}/>
          )}
        </div>
      )}

      {/* ══ DELETE CONFIRM ══════════════════════════════════════════════════════ */}
      {deleteConfirm && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.7)',backdropFilter:'blur(4px)',zIndex:210,display:'flex',alignItems:'center',justifyContent:'center',padding:14}} onClick={()=>setDeleteConfirm(null)}>
          <div onClick={e=>e.stopPropagation()} style={{...cs,width:'100%',maxWidth:340,borderColor:`${DNG}33`}}>
            <div style={{fontSize:14,fontWeight:700,color:TS,marginBottom:8}}>🗑 Delete Exam?</div>
            <div style={{fontSize:12,color:DIM,marginBottom:18}}>"{deleteConfirm.title}" permanently delete ho jaayega, saari attempts/results bhi. Ye undo nahi ho sakta.</div>
            <div style={{display:'flex',gap:8}}>
              <button onClick={()=>setDeleteConfirm(null)} style={{...bg_,flex:1}}>Cancel</button>
              <button onClick={()=>deleteExam(deleteConfirm)} style={{...bp,flex:1,background:`linear-gradient(135deg,${DNG},#9B0000)`}}>Delete</button>
            </div>
          </div>
        </div>
      )}

      {/* ══ QUICK EDIT MODAL — 33.9 ═════════════════════════════════════════════ */}
      {editExam && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.7)',backdropFilter:'blur(4px)',zIndex:200,display:'flex',alignItems:'flex-start',justifyContent:'center',padding:'20px 14px',overflowY:'auto' as any}} onClick={()=>setEditExam(null)}>
          <div onClick={e=>e.stopPropagation()} style={{...cs,width:'100%',maxWidth:480,marginTop:10}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:TS,marginBottom:16}}>✏️ Edit Exam</div>
            <div style={{display:'flex',flexDirection:'column' as any,gap:12}}>
              <div>
                <label style={lbl}>Title</label>
                <input value={editForm.title} onChange={e=>setEditForm((f:any)=>({...f,title:e.target.value}))} style={inp}/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div><label style={lbl}>Duration (min)</label><input type="number" value={editForm.duration} onChange={e=>setEditForm((f:any)=>({...f,duration:parseInt(e.target.value)||0}))} style={inp}/></div>
                <div><label style={lbl}>Total Marks</label><input type="number" value={editForm.totalMarks} onChange={e=>setEditForm((f:any)=>({...f,totalMarks:parseInt(e.target.value)||0}))} style={inp}/></div>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div><label style={lbl}>Correct Marks</label><input type="number" value={editForm.correctMarks} onChange={e=>setEditForm((f:any)=>({...f,correctMarks:parseFloat(e.target.value)||0}))} style={inp}/></div>
                <div><label style={lbl}>Incorrect Marks</label><input type="number" value={editForm.incorrectMarks} onChange={e=>setEditForm((f:any)=>({...f,incorrectMarks:parseFloat(e.target.value)||0}))} style={inp}/></div>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div><label style={lbl}>Start Time</label><input type="datetime-local" value={editForm.startTime} onChange={e=>setEditForm((f:any)=>({...f,startTime:e.target.value}))} style={inp}/></div>
                <div><label style={lbl}>End Time</label><input type="datetime-local" value={editForm.endTime} onChange={e=>setEditForm((f:any)=>({...f,endTime:e.target.value}))} style={inp}/></div>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div><label style={lbl}>Batch</label><input value={editForm.batch} onChange={e=>setEditForm((f:any)=>({...f,batch:e.target.value}))} style={inp}/></div>
                <div><label style={lbl}>Test Series</label><input value={editForm.seriesName} onChange={e=>setEditForm((f:any)=>({...f,seriesName:e.target.value}))} style={inp}/></div>
              </div>
              <div>
                <label style={lbl}>Status</label>
                <select value={editForm.status} onChange={e=>setEditForm((f:any)=>({...f,status:e.target.value}))} style={inp}>
                  {STATUS_ORDER.map(s=><option key={s} value={s}>{STATUS_META[s].label}</option>)}
                </select>
              </div>
              <label style={{display:'flex',alignItems:'center',gap:7,fontSize:12,color:TS,cursor:'pointer'}}>
                <input type="checkbox" checked={editForm.watermark} onChange={e=>setEditForm((f:any)=>({...f,watermark:e.target.checked}))}/>
                Student Watermark
              </label>
              <div>
                <label style={lbl}>Custom Instructions</label>
                <textarea value={editForm.customInstructions} onChange={e=>setEditForm((f:any)=>({...f,customInstructions:e.target.value}))} rows={3} style={{...inp,resize:'vertical' as any}}/>
              </div>
            </div>
            <div style={{display:'flex',gap:10,marginTop:18}}>
              <button onClick={()=>setEditExam(null)} style={{...bg_,flex:1}}>Cancel</button>
              <button onClick={saveEdit} disabled={savingEdit} style={{...bpAcc,flex:1,opacity:savingEdit?0.7:1}}>{savingEdit?'Saving...':'Save Changes'}</button>
            </div>
          </div>
        </div>
      )}

      {/* ══ ANALYTICS SIDE PANEL — 33.14 ════════════════════════════════════════ */}
      {analyticsExam && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.6)',backdropFilter:'blur(3px)',zIndex:220,display:'flex',justifyContent:'flex-end'}} onClick={()=>setAnalyticsExam(null)}>
          <div onClick={e=>e.stopPropagation()} style={{width:'100%',maxWidth:420,height:'100%',overflowY:'auto' as any,background:CRD,borderLeft:`1px solid ${BOR}`,padding:20,boxSizing:'border-box' as any}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16}}>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:TS}}>{analyticsExam.title}</div>
                <div style={{fontSize:11,color:DIM,marginTop:2}}>📈 Exam Analytics</div>
              </div>
              <button onClick={()=>setAnalyticsExam(null)} style={{background:'transparent',border:'none',color:DIM,fontSize:18,cursor:'pointer'}}>✕</button>
            </div>

            {analyticsLoading ? (
              <div style={{textAlign:'center' as any,padding:'40px 0',color:DIM}}><span className="ae-spin" style={{fontSize:22}}>⟳</span></div>
            ) : !analyticsData ? (
              <div style={{fontSize:12,color:DIM,textAlign:'center' as any,padding:'30px 0'}}>Analytics load nahi ho payi.</div>
            ) : (
              <div style={{display:'flex',flexDirection:'column' as any,gap:14}}>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                  <div style={{background:'rgba(255,255,255,0.03)',borderRadius:10,padding:'12px',textAlign:'center' as any}}>
                    <div style={{fontSize:20,fontWeight:800,color:ACC}}>{analyticsData.totalAttempts}</div>
                    <div style={{fontSize:9,color:DIM,textTransform:'uppercase' as any,fontWeight:700}}>Attempts</div>
                  </div>
                  <div style={{background:'rgba(255,255,255,0.03)',borderRadius:10,padding:'12px',textAlign:'center' as any}}>
                    <div style={{fontSize:20,fontWeight:800,color:GOLD}}>{analyticsData.avgScore}</div>
                    <div style={{fontSize:9,color:DIM,textTransform:'uppercase' as any,fontWeight:700}}>Avg Score</div>
                  </div>
                  <div style={{background:'rgba(255,255,255,0.03)',borderRadius:10,padding:'12px',textAlign:'center' as any}}>
                    <div style={{fontSize:20,fontWeight:800,color:SUC}}>{analyticsData.passRate}%</div>
                    <div style={{fontSize:9,color:DIM,textTransform:'uppercase' as any,fontWeight:700}}>Pass Rate</div>
                  </div>
                  <div style={{background:'rgba(255,255,255,0.03)',borderRadius:10,padding:'12px',textAlign:'center' as any}}>
                    <div style={{fontSize:20,fontWeight:800,color:PRP}}>{analyticsData.completionRate}%</div>
                    <div style={{fontSize:9,color:DIM,textTransform:'uppercase' as any,fontWeight:700}}>Completion</div>
                  </div>
                </div>

                <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
                  <Chip ico="🔺" label={`Max: ${analyticsData.maxScore}`} col={SUC}/>
                  <Chip ico="🔻" label={`Min: ${analyticsData.minScore}`} col={DNG}/>
                  <Chip ico="✅" label={`Passed: ${analyticsData.passCount}`} col={SUC}/>
                  <Chip ico="❓" label={`${analyticsData.exam?.questionCount||0} Qs`} col={DIM}/>
                </div>

                {analyticsData.scoreDistribution?.length>0 && (
                  <div>
                    <div style={{fontSize:11,fontWeight:700,color:TS,marginBottom:8}}>Score Distribution</div>
                    <div style={{display:'flex',gap:4,alignItems:'flex-end',height:60}}>
                      {analyticsData.scoreDistribution.map((b:any,i:number)=>{
                        const maxC = Math.max(...analyticsData.scoreDistribution.map((x:any)=>x.count),1)
                        return <div key={i} style={{flex:1,background:`linear-gradient(180deg,${ACC},${PRP})`,borderRadius:'4px 4px 0 0',height:`${Math.max((b.count/maxC)*100,4)}%`}} title={`${b.count} students`}/>
                      })}
                    </div>
                  </div>
                )}

                <div>
                  <div style={{fontSize:11,fontWeight:700,color:TS,marginBottom:8}}>🏆 Leaderboard (Top 10)</div>
                  {(!analyticsData.leaderboard || analyticsData.leaderboard.length===0) ? (
                    <div style={{fontSize:11,color:DIM}}>Abhi tak koi attempt nahi hua.</div>
                  ) : (
                    <div style={{display:'flex',flexDirection:'column' as any,gap:6}}>
                      {analyticsData.leaderboard.map((l:any,i:number)=>(
                        <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'7px 10px',background:'rgba(255,255,255,0.03)',borderRadius:8,fontSize:11}}>
                          <span style={{color:TS}}>{i===0?'🥇':i===1?'🥈':i===2?'🥉':`#${i+1}`} {l.studentName||l.studentEmail||'Student'}</span>
                          <span style={{color:GOLD,fontWeight:700}}>{l.score}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ══ PREVIEW EXAM — content/option rendering check (no attempt created) ══ */}
      {previewExam && (
        <div style={{position:'fixed' as any,inset:0,background:'rgba(0,4,14,0.85)',backdropFilter:'blur(4px)',zIndex:230,display:'flex',flexDirection:'column' as any}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'14px 18px',borderBottom:`1px solid ${BOR}`,background:CRD,flexShrink:0,gap:10}}>
            <div style={{minWidth:0}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:TS,overflow:'hidden',whiteSpace:'nowrap' as any,textOverflow:'ellipsis'}}>👁 {previewExam.title}</div>
              <div style={{fontSize:10,color:DIM,marginTop:2}}>Student jaisa hi content view — read-only, koi attempt record nahi banta</div>
            </div>
            <div style={{display:'flex',alignItems:'center',gap:8,flexShrink:0}}>
              {previewQuestions.some((q:any)=>q.hindiText || (q.hindiOptions&&q.hindiOptions.length>0)) && (
                <div style={{display:'flex',background:'rgba(255,255,255,0.04)',borderRadius:8,border:`1px solid ${BOR}`,padding:2}}>
                  <button onClick={()=>setPreviewLang('en')} style={{background:previewLang==='en'?`${ACC}33`:'transparent',border:'none',color:previewLang==='en'?TS:DIM,borderRadius:6,padding:'5px 10px',cursor:'pointer',fontSize:11,fontWeight:700}}>EN</button>
                  <button onClick={()=>setPreviewLang('hi')} style={{background:previewLang==='hi'?`${ACC}33`:'transparent',border:'none',color:previewLang==='hi'?TS:DIM,borderRadius:6,padding:'5px 10px',cursor:'pointer',fontSize:11,fontWeight:700}}>हिं</button>
                </div>
              )}
              <button onClick={()=>setPreviewExam(null)} style={{background:'transparent',border:'none',color:DIM,fontSize:20,cursor:'pointer'}}>✕</button>
            </div>
          </div>

          <div style={{flex:1,overflowY:'auto' as any,padding:'16px',boxSizing:'border-box' as any}}>
            {previewLoading ? (
              <div style={{textAlign:'center' as any,padding:'60px 0',color:DIM}}><span className="ae-spin" style={{fontSize:24}}>⟳</span><div style={{marginTop:10,fontSize:12}}>Questions load ho rahe hain...</div></div>
            ) : previewQuestions.length===0 ? (
              <div style={{...cs,textAlign:'center' as any,padding:'40px 20px'}}>
                <div style={{fontSize:40,marginBottom:10}}>❓</div>
                <div style={{fontSize:13,color:TS,fontWeight:700,marginBottom:4}}>Is exam me koi question nahi hai</div>
                <div style={{fontSize:11,color:DIM}}>Step 2 (Add Questions) complete nahi hua hoga.</div>
              </div>
            ) : (
              <div style={{display:'flex',flexDirection:'column' as any,gap:12,maxWidth:680,margin:'0 auto'}}>
                {previewQuestions.map((q:any,qi:number)=>{
                  const qid = String(q._id||qi)
                  const showHindi = previewLang==='hi'
                  const hasHindiQ = !!q.hindiText
                  const hasHindiOpts = !!(q.hindiOptions && q.hindiOptions.length>0)
                  const qTextEn = q.questionText || q.text || q.question || q.title || '(Question text missing — render issue!)'
                  const qText = (showHindi && hasHindiQ) ? q.hindiText : qTextEn
                  const opts = q.options || q.choices || []
                  const correctRaw = q.correct ?? q.correctAnswer ?? q.correctOption ?? q.answer
                  const isCorrect = (idx:number, letter:string) => {
                    if(Array.isArray(correctRaw)) return correctRaw.includes(idx) || correctRaw.includes(letter)
                    if(typeof correctRaw==='number') return correctRaw===idx
                    if(typeof correctRaw==='string') return correctRaw.toUpperCase()===letter || correctRaw===String(idx)
                    return false
                  }
                  const missingOpts = !opts || opts.length===0
                  const explanation = q.explanation || q.solution || q.explanationText || q.answerExplanation || q.detailedSolution
                  const hindiExplanation = q.hindiExplanation || q.explanationHindi
                  const explainShown = !!expandedExplain[qid]
                  return (
                    <div key={qid} style={{...cs,padding:'14px 16px',borderLeft:`3px solid ${missingOpts?DNG:ACC}`}}>
                      <div style={{display:'flex',gap:6,alignItems:'center',marginBottom:8,flexWrap:'wrap' as any}}>
                        <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:13,color:TS}}>Q{qi+1}</span>
                        {q.subject && <Chip ico="📚" label={q.subject} col={PRP}/>}
                        {q.difficulty && <Chip ico="🎯" label={q.difficulty} col={WRN}/>}
                        {q.type && <Chip ico="📝" label={q.type} col={ACC}/>}
                        {missingOpts && <Chip ico="⚠️" label="No options found!" col={DNG}/>}
                      </div>
                      <div style={{fontSize:13,color:TS,lineHeight:1.6,marginBottom:6}}>{qText}</div>
                      {showHindi && !hasHindiQ && <div style={{fontSize:9,color:'#818CF8',marginBottom:8}}>हिंदी अनुवाद उपलब्ध नहीं — अंग्रेज़ी दिखाया जा रहा है</div>}
                      {!missingOpts && (
                        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:6,marginBottom:explanation?10:0}}>
                          {opts.map((opt:any,oi:number)=>{
                            const letter = String.fromCharCode(65+oi)
                            const correct = isCorrect(oi,letter)
                            const optTextEn = typeof opt==='string' ? opt : (opt?.text||opt?.label||JSON.stringify(opt))
                            const optText = (showHindi && hasHindiOpts && q.hindiOptions[oi]) ? q.hindiOptions[oi] : optTextEn
                            return (
                              <div key={oi} style={{padding:'7px 10px',borderRadius:8,fontSize:11,border:`1px solid ${correct?`${SUC}55`:BOR}`,background:correct?`${SUC}10`:'rgba(255,255,255,0.02)',color:correct?SUC:'#CBD5E1'}}>
                                <b style={{marginRight:4}}>{letter}.</b>{optText} {correct?'✓':''}
                              </div>
                            )
                          })}
                        </div>
                      )}
                      {explanation && (
                        <div>
                          <button onClick={()=>toggleExplain(qid)} style={{...bg_,fontSize:10,padding:'5px 11px',color:GOLD,borderColor:`${GOLD}33`}}>
                            {explainShown?'🔼 Hide Explanation':'💡 Show Explanation'}
                          </button>
                          {explainShown && (
                            <div style={{marginTop:8,padding:'10px 12px',background:`${GOLD}0C`,border:`1px solid ${GOLD}33`,borderRadius:8,fontSize:11,color:'#FDE68A',lineHeight:1.6}}>
                              {(showHindi && hindiExplanation) ? hindiExplanation : explanation}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

// ── 33.15 — Calendar month grid ────────────────────────────────────────────────
function CalendarGrid({month,exams,onDayClick,onExamClick}:{month:Date;exams:any[];onDayClick:(d:Date)=>void;onExamClick:(e:any)=>void}){
  const year = month.getFullYear(), mon = month.getMonth()
  const firstDay = new Date(year,mon,1).getDay()
  const daysInMonth = new Date(year,mon+1,0).getDate()
  const cells: (number|null)[] = []
  for(let i=0;i<firstDay;i++) cells.push(null)
  for(let d=1;d<=daysInMonth;d++) cells.push(d)
  while(cells.length%7!==0) cells.push(null)

  const examsByDay: Record<number,any[]> = {}
  exams.forEach(e=>{
    const dt = e.schedule?.startTime ? new Date(e.schedule.startTime) : null
    if(dt && dt.getFullYear()===year && dt.getMonth()===mon){
      const day = dt.getDate()
      if(!examsByDay[day]) examsByDay[day]=[]
      examsByDay[day].push(e)
    }
  })

  const todayStr = new Date().toDateString()

  return (
    <div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(7,1fr)',gap:4,marginBottom:6}}>
        {['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map(d=>(
          <div key={d} style={{textAlign:'center' as any,fontSize:10,fontWeight:700,color:DIM,padding:'4px 0'}}>{d}</div>
        ))}
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(7,1fr)',gap:4}}>
        {cells.map((d,i)=>{
          if(d===null) return <div key={i}/>
          const dayExams = examsByDay[d]||[]
          const dateObj = new Date(year,mon,d)
          const isToday = dateObj.toDateString()===todayStr
          return (
            <div key={i} onClick={()=>onDayClick(dateObj)} style={{minHeight:64,borderRadius:8,padding:'5px 4px',background:isToday?`${ACC}14`:'rgba(255,255,255,0.02)',border:`1px solid ${isToday?ACC:BOR}`,cursor:'pointer',overflow:'hidden'}}>
              <div style={{fontSize:10,fontWeight:isToday?800:600,color:isToday?ACC:DIM,marginBottom:3}}>{d}</div>
              {dayExams.slice(0,2).map((e:any,idx:number)=>{
                const meta = STATUS_META[e.status]||STATUS_META.draft
                return (
                  <div key={idx} onClick={(ev:any)=>{ev.stopPropagation();onExamClick(e)}} title={e.title} style={{fontSize:8,color:meta.color,background:`${meta.color}1A`,borderRadius:4,padding:'1px 4px',marginBottom:2,overflow:'hidden',whiteSpace:'nowrap' as any,textOverflow:'ellipsis'}}>
                    {e.title}
                  </div>
                )
              })}
              {dayExams.length>2 && <div style={{fontSize:8,color:DIM}}>+{dayExams.length-2} more</div>}
            </div>
          )
        })}
      </div>
    </div>
  )
}
__PRRANK_EOF_ALLEXAMS3__

echo ""
node --version >/dev/null 2>&1 || true

echo "── Verification ──"
pass=0; total=0
chk(){ total=$((total+1)); if grep -q "$1" "$2" 2>/dev/null; then echo "✅ $3"; pass=$((pass+1)); else echo "❌ $3"; fi }

chk "openPreview"            "$ALLEXAMS_FILE" "Preview Exam action intact"
chk "toggleExplain"          "$ALLEXAMS_FILE" "NEW: Explanation toggle (hidden by default)"
chk "Show Explanation"       "$ALLEXAMS_FILE" "NEW: per-question Show/Hide Explanation button"
chk "previewLang"            "$ALLEXAMS_FILE" "NEW: Hindi/English language state"
chk "hasHindiQ"               "$ALLEXAMS_FILE" "NEW: auto-detects Hindi availability (toggle only shows if present)"
chk "हिंदी अनुवाद उपलब्ध नहीं" "$ALLEXAMS_FILE" "NEW: graceful per-question fallback when Hindi missing"
chk "exams.map(e=>{"         "$ALLEXAMS_FILE" "33.1  listing intact"
chk "CalendarGrid"           "$ALLEXAMS_FILE" "33.15 calendar view intact"
chk "leaderboard"            "$ALLEXAMS_FILE" "33.14 analytics panel intact"

echo ""
echo "Checks passed: $pass / $total"
echo ""
echo "Note: agar question documents me explanation field ka naam 'explanation'/"
echo "'solution'/'explanationText'/'answerExplanation'/'detailedSolution' me se"
echo "koi NA ho, to button khud nahi dikhega (kyunki field detect nahi hota)."
echo "Exact field name bata do to update kar denge."
echo ""
echo "Ab: dev server restart karo (Replit Run / redeploy)."
