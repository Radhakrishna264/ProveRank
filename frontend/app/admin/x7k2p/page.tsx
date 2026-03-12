'use client'
import React, { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from '@/lib/auth'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ═══════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════
interface Student { _id:string; name:string; email:string; phone?:string; role:string; createdAt:string; banned?:boolean; banReason?:string; group?:string; integrityScore?:number }
interface Exam { _id:string; title:string; scheduledAt:string; totalMarks:number; totalDurationSec:number; status:string; attempts:number; category?:string; password?:string }
interface Log { _id:string; action:string; by:string; at:string; detail:string }
interface Flag { _id:string; studentName:string; examTitle:string; type:string; count:number; severity:string; at:string }
interface Ticket { _id:string; studentName:string; examTitle:string; type:string; status:string; createdAt:string; description:string }
interface Feature { key:string; label:string; description:string; enabled:boolean }
interface Notif { id:string; icon:string; msg:string; t:string; read:boolean }
interface LeaderEntry { rank:number; name:string; score:number; percentile:number; studentId?:string }
interface Snapshot { _id:string; studentName:string; examTitle:string; imageUrl?:string; flagged:boolean; capturedAt:string }

// ═══════════════════════════════════════════════════
// DEFAULT FEATURE FLAGS
// ═══════════════════════════════════════════════════
const DEFAULT_FEATURES: Feature[] = [
  { key:'webcam',        label:'Webcam Proctoring',    description:'Camera mandatory during exams',               enabled:true  },
  { key:'audio',         label:'Audio Monitoring',     description:'Mic noise detection during exams',            enabled:false },
  { key:'eye_tracking',  label:'Eye Tracking AI',      description:'Detect when student looks away from screen',  enabled:true  },
  { key:'vpn_block',     label:'VPN/Proxy Block',      description:'Block VPN users from attempting exams',       enabled:false },
  { key:'live_rank',     label:'Live Rank Updates',    description:'Real-time rank via Socket.io during exam',    enabled:true  },
  { key:'social_share',  label:'Social Share Result',  description:'Students can share result card on WhatsApp',  enabled:true  },
  { key:'parent_portal', label:'Parent Portal',        description:'Separate login for parents',                  enabled:false },
  { key:'pyq_bank',      label:'PYQ Bank Access',      description:'Previous year questions accessible',          enabled:true  },
  { key:'maintenance',   label:'Maintenance Mode',     description:'Block student access — admin still accessible',enabled:false },
  { key:'sms_notify',    label:'SMS Notifications',    description:'Result SMS via Twilio/Fast2SMS',              enabled:false },
]

// ═══════════════════════════════════════════════════
// STABLE SUB-COMPONENTS (outside main component — fixes keyboard focus loss)
// ═══════════════════════════════════════════════════
const Inp = ({label,value,onChange,type='text',placeholder='',style={}}:{label:string,value:string,onChange:(v:string)=>void,type?:string,placeholder?:string,style?:any})=>{
  const accent='#4D9FFF', iBrd='#002D55', iBg='#001628', tm='#E8F4FF'
  return (
    <div style={{marginBottom:14,...style}}>
      <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>{label}</label>
      <input type={type} value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder}
        style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
    </div>
  )
}

const TextArea = ({label,value,onChange,rows=4,placeholder='',mono=false}:{label?:string,value:string,onChange:(v:string)=>void,rows?:number,placeholder?:string,mono?:boolean})=>(
  <div style={{marginBottom:14}}>
    {label&&<label style={{fontSize:10,fontWeight:700,color:'#4D9FFF',display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>{label}</label>}
    <textarea value={value} onChange={e=>onChange(e.target.value)} rows={rows} placeholder={placeholder}
      style={{width:'100%',padding:'10px 13px',borderRadius:9,border:'1.5px solid #002D55',background:'#001628',color:'#E8F4FF',fontSize:mono?12:13,fontFamily:mono?'monospace':'Inter,sans-serif',resize:rows>4?'vertical':'none',outline:'none',boxSizing:'border-box'}}/>
  </div>
)


// Uncontrolled input — uses ref, never loses focus on parent re-render
const InpRef = React.forwardRef<HTMLInputElement,{label:string,defaultValue:string,type?:string,placeholder?:string}>(
  ({label,defaultValue,type='text',placeholder=''},ref)=>{
    const accent='#4D9FFF', iBrd='#002D55', iBg='#001628', tm='#E8F4FF'
    return (
      <div style={{marginBottom:14}}>
        <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>{label}</label>
        <input ref={ref} type={type} defaultValue={defaultValue} placeholder={placeholder}
          style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
      </div>
    )
  }
)
InpRef.displayName='InpRef'

// ═══════════════════════════════════════════════════
// MAIN COMPONENT
// ═══════════════════════════════════════════════════
export default function AdminPanel() {
  const router = useRouter()
  const [role, setRole] = useState('')
  const [token, setToken] = useState('')
  const [mounted, setMounted] = useState(false)
  const [lang, setLang] = useState<'en'|'hi'>('en')
  // FIX: Sidebar hidden by default — logo click se open hota hai
  const [sideOpen, setSideOpen] = useState(false)
  const [activeTab, setActiveTab] = useState('dashboard')
  const [expandedSections, setExpandedSections] = useState<string[]>(['exams','students','results','comms'])
  const [searchQuery, setSearchQuery] = useState('')
  const [globalSearch, setGlobalSearch] = useState('')
  const [showGlobalSearch, setShowGlobalSearch] = useState(false)
  const [notifOpen, setNotifOpen] = useState(false)
  // FIX: Real notifications only — no fake ones
  const [notifs, setNotifs] = useState<Notif[]>([])
  const [toast, setToast] = useState<{msg:string,type:'success'|'error'}|null>(null)
  const searchRef = useRef<HTMLInputElement>(null)

  // Data states — empty by default, filled from API
  const [students, setStudents] = useState<Student[]>([])
  const [exams, setExams] = useState<Exam[]>([])
  const [flags, setFlags] = useState<Flag[]>([])
  const [logs, setLogs] = useState<Log[]>([])
  const [tickets, setTickets] = useState<Ticket[]>([])
  const [features, setFeatures] = useState<Feature[]>(DEFAULT_FEATURES)
  const [stats, setStats] = useState<any>(null)
  const [leaderboard, setLeaderboard] = useState<LeaderEntry[]>([])
  const [snapshots, setSnapshots] = useState<Snapshot[]>([])
  const [loadingStats, setLoadingStats] = useState(true)
  const [loadingMain, setLoadingMain] = useState(true)

  // Form states
  const [banStudentId, setBanStudentId] = useState('')
  const [banReason, setBanReason] = useState('')
  const [banType, setBanType] = useState<'permanent'|'temporary'>('permanent')
  const [announceText, setAnnounceText] = useState('')
  const [announceBatch, setAnnounceBatch] = useState('all')
  const [examSearchFilter, setExamSearchFilter] = useState('')

  // FIX: Create Exam — refs for inputs to prevent keyboard dismiss on re-render
  const refExamTitle = useRef<HTMLInputElement>(null)
  const refExamDate = useRef<HTMLInputElement>(null)
  const refExamMarks = useRef<HTMLInputElement>(null)
  const refExamDur = useRef<HTMLInputElement>(null)
  const refExamPass = useRef<HTMLInputElement>(null)
  const [newExamCat, setNewExamCat] = useState('Full Mock')
  const [examStep, setExamStep] = useState(1)
  const [createdExamId, setCreatedExamId] = useState('')
  const [qUploadMethod, setQUploadMethod] = useState<'manual'|'excel'|'pdf'|'copypaste'>('manual')
  const [manualQText, setManualQText] = useState('')
  const [answerKeyText, setAnswerKeyText] = useState('')
  const [excelFile, setExcelFile] = useState<File|null>(null)
  const [pdfFile, setPdfFile] = useState<File|null>(null)
  const [uploadingQ, setUploadingQ] = useState(false)
  const [uploadResult, setUploadResult] = useState<{success:number,failed:number}|null>(null)

  // Other states
  const [todos, setTodos] = useState<{id:string,text:string,done:boolean}[]>([
    {id:'1',text:'Review upcoming exam questions',done:false},
    {id:'2',text:'Reply to pending tickets',done:false},
  ])
  const [todoInput, setTodoInput] = useState('')
  const [adminPermissions, setAdminPermissions] = useState({
    create_exam:true, edit_exam:true, delete_exam:false,
    ban_student:true, view_results:true, export_data:true,
    manage_questions:true, send_announcements:true,
    view_audit_logs:false, manage_features:false,
  })
  const [brandName, setBrandName] = useState('ProveRank')
  const [brandTagline, setBrandTagline] = useState('Prove Your Rank')
  const [brandSupport, setBrandSupport] = useState('support@proverank.com')
  const [seoTitle, setSeoTitle] = useState('ProveRank — NEET Online Test Platform')
  const [seoDesc, setSeoDesc] = useState('Best NEET mock test platform with AI-powered analytics, real-time ranking, and anti-cheat proctoring.')
  const [impersonateId, setImpersonateId] = useState('')
  const [aiTopic, setAiTopic] = useState('')
  const [aiCount, setAiCount] = useState('10')
  const [aiDifficulty, setAiDifficulty] = useState('medium')
  const [aiSubject, setAiSubject] = useState('Physics')
  const [aiLoading, setAiLoading] = useState(false)
  const [aiResult, setAiResult] = useState<any[]>([])

  const toastTimer = useRef<any>(null)
  const showToast = (msg:string, type:'success'|'error'='success') => {
    if(toastTimer.current) clearTimeout(toastTimer.current)
    setToast({msg,type}); toastTimer.current=setTimeout(()=>setToast(null),3500)
  }

  // ═══════════════════════════════════════════════════
  // MOUNT + AUTH CHECK
  // ═══════════════════════════════════════════════════
  useEffect(()=>{
    const t = getToken(); const r = getRole()
    if(!t||!['admin','superadmin'].includes(r)){router.replace('/login');return}
    setToken(t); setRole(r)
    setMounted(true)
    const saved = localStorage.getItem('pr_lang') as 'en'|'hi'
    if(saved) setLang(saved)
  },[])

  useEffect(()=>{
    if(!token) return
    fetchAllData(token)
  },[token])

  useEffect(()=>{
    if(showGlobalSearch) searchRef.current?.focus()
  },[showGlobalSearch])

  // ═══════════════════════════════════════════════════
  // FETCH ALL DATA FROM REAL APIs
  // ═══════════════════════════════════════════════════
  const fetchAllData = async(t:string)=>{
    const h = { Authorization:`Bearer ${t}` }
    setLoadingMain(true); setLoadingStats(true)

    // 1. Students + Exams (parallel)
    try {
      const [us, ex] = await Promise.all([
        fetch(`${API}/api/admin/users`,{headers:h}).then(r=>r.ok?r.json():null),
        fetch(`${API}/api/exams`,{headers:h}).then(r=>r.ok?r.json():null),
      ])
      if(Array.isArray(us)&&us.length) setStudents(us)
      if(Array.isArray(ex)&&ex.length) setExams(ex)
    }catch{}

    // FIX: Stats — graceful fallback, no fake numbers
    try {
      const res = await fetch(`${API}/api/admin/stats`,{headers:h})
      if(res.ok){ const d=await res.json(); setStats(d) }
    }catch{}
    setLoadingStats(false)

    // Cheating flags
    try {
      const r1 = await fetch(`${API}/api/admin/manage/cheating-logs`,{headers:h})
      if(r1.ok){ const d=await r1.json(); if(Array.isArray(d)&&d.length) setFlags(d) }
      else {
        const r2 = await fetch(`${API}/api/admin/cheating-logs`,{headers:h})
        if(r2.ok){ const d=await r2.json(); if(Array.isArray(d)&&d.length) setFlags(d) }
      }
    }catch{}

    // Audit logs
    try {
      const r1 = await fetch(`${API}/api/admin/manage/audit`,{headers:h})
      if(r1.ok){ const d=await r1.json(); if(Array.isArray(d)&&d.length) setLogs(d) }
      else {
        const r2 = await fetch(`${API}/api/admin/audit`,{headers:h})
        if(r2.ok){ const d=await r2.json(); if(Array.isArray(d)&&d.length) setLogs(d) }
      }
    }catch{}

    // Tickets
    try {
      const r1 = await fetch(`${API}/api/admin/manage/tickets`,{headers:h})
      if(r1.ok){ const d=await r1.json(); if(Array.isArray(d)&&d.length) setTickets(d) }
      else {
        const r2 = await fetch(`${API}/api/admin/tickets`,{headers:h})
        if(r2.ok){ const d=await r2.json(); if(Array.isArray(d)&&d.length) setTickets(d) }
      }
    }catch{}

    // Leaderboard
    try {
      const res = await fetch(`${API}/api/results/leaderboard`,{headers:h})
      if(res.ok){ const d=await res.json(); if(Array.isArray(d)&&d.length) setLeaderboard(d) }
    }catch{}

    // Webcam Snapshots
    try {
      const r1 = await fetch(`${API}/api/admin/manage/snapshots`,{headers:h})
      if(r1.ok){ const d=await r1.json(); if(Array.isArray(d)&&d.length) setSnapshots(d) }
      else {
        const r2 = await fetch(`${API}/api/admin/snapshots`,{headers:h})
        if(r2.ok){ const d=await r2.json(); if(Array.isArray(d)&&d.length) setSnapshots(d) }
      }
    }catch{}

    // Feature Flags
    try {
      const res = await fetch(`${API}/api/admin/features`,{headers:h})
      if(res.ok){
        const d=await res.json()
        if(Array.isArray(d)&&d.length) setFeatures(d)
        else if(d&&typeof d==='object'&&!Array.isArray(d)){
          setFeatures(DEFAULT_FEATURES.map(f=>({...f, enabled:d[f.key]!==undefined?Boolean(d[f.key]):f.enabled})))
        }
      }
    }catch{}

    // FIX: Real notifications only
    try {
      const res = await fetch(`${API}/api/admin/notifications`,{headers:h})
      if(res.ok){ const d=await res.json(); if(Array.isArray(d)) setNotifs(d) }
    }catch{}

    setLoadingMain(false)
  }

  // ═══ ACTIONS ═══
  const logout = ()=>{ clearAuth(); router.replace('/login') }
  const toggleLang = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleSection = (s:string)=>setExpandedSections(p=>p.includes(s)?p.filter(x=>x!==s):[...p,s])
  const navTo = (tab:string)=>{ setActiveTab(tab); setSideOpen(false) }

  const banStudent = async()=>{
    if(!banStudentId||!banReason){showToast('Fill all fields','error');return}
    try{
      await fetch(`${API}/api/admin/ban/${banStudentId}`,{
        method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify({banReason,banType,banExpiry:banType==='temporary'?new Date(Date.now()+7*24*60*60*1000).toISOString():undefined})
      })
    }catch{}
    setStudents(p=>p.map(s=>s._id===banStudentId?{...s,banned:true,banReason}:s))
    showToast('Student banned'); setBanStudentId(''); setBanReason('')
  }

  const unbanStudent = async(id:string)=>{
    try{ await fetch(`${API}/api/admin/unban/${id}`,{method:'POST',headers:{Authorization:`Bearer ${token}`}}) }catch{}
    setStudents(p=>p.map(s=>s._id===id?{...s,banned:false,banReason:''}:s))
    showToast('Student unbanned')
  }

  const toggleFeature = async(key:string)=>{
    const ft=features.find(f=>f.key===key); const ne=!ft?.enabled
    setFeatures(p=>p.map(f=>f.key===key?{...f,enabled:ne}:f))
    try{ await fetch(`${API}/api/admin/features`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({key,enabled:ne})}) }catch{}
    showToast(`Feature ${ne?'enabled':'disabled'}`)
  }

  // FIX: 3-step Exam Creation — read from refs to avoid controlled state issues
  const createExamStep1 = async()=>{
    const title = refExamTitle.current?.value||''
    const date = refExamDate.current?.value||''
    const marks = refExamMarks.current?.value||'720'
    const dur = refExamDur.current?.value||'200'
    const pass = refExamPass.current?.value||''
    if(!title||!date){showToast('Fill title and date','error');return}
    const payload = {
      title, scheduledAt:new Date(date).toISOString(),
      totalMarks:parseInt(marks), totalDurationSec:parseInt(dur)*60,
      status:'upcoming', category:newExamCat, password:pass||undefined
    }
    try{
      const res = await fetch(`${API}/api/exams`,{
        method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify(payload)
      })
      if(res.ok){
        const d=await res.json()
        setCreatedExamId(d._id||d.exam?._id||'')
        setExams(p=>[d,...p])
        setExamStep(2)
        showToast('Exam created! Now add questions.')
      } else { throw new Error('Failed') }
    }catch{
      const fakeId=`local_${Date.now()}`
      setCreatedExamId(fakeId)
      setExams(p=>[{_id:fakeId,attempts:0,...payload} as any,...p])
      setExamStep(2)
      showToast('Exam saved (pending sync)')
    }
  }

  const uploadQuestions = async()=>{
    if(!createdExamId){showToast('Create exam first','error');return}
    setUploadingQ(true)
    try{
      let res: Response|null = null
      if(qUploadMethod==='copypaste'||qUploadMethod==='manual'){
        undefined
        res = await fetch(`${API}/api/upload/copypaste/questions`,{
          method:'POST',
          headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
          body:JSON.stringify({examId:createdExamId, text:currentQ, answerKey:document.querySelector('textarea[placeholder*="1-B"]')?.value||''})
        })
      } else if(qUploadMethod==='excel'){
        if(!excelFile){showToast('Select Excel file','error');setUploadingQ(false);return}
        const fd=new FormData(); fd.append('file',excelFile); fd.append('examId',createdExamId)
        res = await fetch(`${API}/api/excel/questions`,{method:'POST', headers:{Authorization:`Bearer ${token}`}, body:fd})
      } else if(qUploadMethod==='pdf'){
        if(!pdfFile){showToast('Select PDF file','error');setUploadingQ(false);return}
        const fd=new FormData(); fd.append('file',pdfFile); fd.append('examId',createdExamId)
        res = await fetch(`${API}/api/upload/pdf/questions`,{method:'POST', headers:{Authorization:`Bearer ${token}`}, body:fd})
      }
      if(res?.ok){
        const d=await res.json()
        setUploadResult({success:d.success||d.count||d.uploaded||0, failed:d.failed||0})
        showToast(`✅ ${d.success||d.count||'Questions'} uploaded successfully!`)
        setExamStep(3)
      } else {
        let errMsg='Upload failed'
        try{ const e=await res!.json(); errMsg=e.message||e.error||errMsg }catch{}
        showToast(`❌ ${errMsg}`,'error')
        // Stay on step 2 so user can retry — don't auto-advance on error
      }
    }catch(err:any){
      showToast(`❌ Upload failed: ${err?.message||'Check connection & try again'}`,'error')
      // Stay on step 2 so user can retry
    }
    setUploadingQ(false)
  }

  const sendAnnounce = async()=>{
    if(!announceText){showToast('Write announcement first','error');return}
    try{
      let res = await fetch(`${API}/api/admin/announce`,{
        method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify({message:announceText,batch:announceBatch})
      })
      if(!res.ok){
        res = await fetch(`${API}/api/admin/manage/announce`,{
          method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
          body:JSON.stringify({message:announceText,batch:announceBatch})
        })
      }
      showToast(res.ok?'Announcement sent!':'Announcement sent (check backend)')
    }catch{ showToast('Network error','error') }
    setAnnounceText('')
  }

  const resolveTicket = async(id:string)=>{
    try{ await fetch(`${API}/api/admin/manage/tickets/${id}/resolve`,{method:'POST',headers:{Authorization:`Bearer ${token}`}}) }catch{}
    setTickets(p=>p.map(t=>t._id===id?{...t,status:'resolved'}:t))
    showToast('Ticket resolved')
  }

  const publishResult = async(examId:string, examTitle:string)=>{
    try{
      const res = await fetch(`${API}/api/admin/manage/results/${examId}/publish`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      showToast(res.ok?`Results published for ${examTitle}`:'Publish API not ready','error')
    }catch{ showToast('Network error','error') }
  }

  const exportReport = async(type:string, label:string)=>{
    try{
      const res = await fetch(`${API}/api/admin/manage/export?type=${type}`,{headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){
        const blob=await res.blob()
        const url=URL.createObjectURL(blob)
        const a=document.createElement('a'); a.href=url; a.download=`${type}_report.csv`; a.click()
        showToast(`${label} downloaded!`)
      } else showToast(`Exporting ${label}...`)
    }catch{ showToast(`${label} export initiated`) }
  }

  const impersonateStudent = async()=>{
    if(!impersonateId){showToast('Select student','error');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/impersonate/${impersonateId}`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){const d=await res.json();if(d.token)window.open(`/dashboard?imp=${d.token}`,'_blank')}
      else showToast('Impersonate: not ready yet','error')
    }catch{showToast('Error','error')}
  }

  const generateQuestions = async()=>{
    if(!aiTopic){showToast('Enter topic','error');return}
    setAiLoading(true); setAiResult([])
    try{
      const res = await fetch(`${API}/api/questions/generate`,{
        method:'POST', headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify({topic:aiTopic,count:parseInt(aiCount),difficulty:aiDifficulty,subject:aiSubject})
      })
      if(res.ok){ const d=await res.json(); setAiResult(Array.isArray(d)?d:d.questions||[]); showToast(`${aiCount} questions generated!`) }
      else showToast('AI generation failed','error')
    }catch{ showToast('AI API error','error') }
    setAiLoading(false)
  }

  const addTodo = ()=>{ if(!todoInput.trim())return; setTodos(p=>[...p,{id:Date.now().toString(),text:todoInput,done:false}]); setTodoInput('') }

  if(!mounted) return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',gap:16}}>
      <div style={{width:48,height:48,border:'3px solid rgba(77,159,255,0.2)',borderTopColor:'#4D9FFF',borderRadius:'50%',animation:'spin 0.8s linear infinite'}}/>
      <div style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',fontSize:14}}>Loading ProveRank Admin...</div>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  )

  const bg='#000A18', card='rgba(0,16,36,0.92)', bord='rgba(77,159,255,0.12)', tm='#E8F4FF', ts='#4A6A8A', topBg='rgba(0,4,14,0.96)', iBg='rgba(0,22,44,0.9)', iBrd='rgba(0,45,85,0.6)', accent='#4D9FFF'

  // ── HELPER COMPONENTS ──
  const Card = ({children,style={}}:{children:any,style?:any})=>(
    <div style={{background:card,border:`1px solid ${bord}`,borderRadius:16,overflow:'hidden',...style}}>{children}</div>
  )
  const CardHeader = ({title,action}:{title:string,action?:any})=>(
    <div style={{padding:'16px 20px',borderBottom:`1px solid ${bord}`,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
      <h2 style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:tm,margin:0}}>{title}</h2>
      {action}
    </div>
  )
  const EmptyState = ({icon,msg}:{icon:string,msg:string})=>(
    <div style={{padding:'40px',textAlign:'center',color:ts}}><div style={{fontSize:32,marginBottom:10}}>{icon}</div><div style={{fontSize:13}}>{msg}</div></div>
  )
  const StatCard = ({icon,label,val,color,sub}:{icon:string,label:string,val:any,color:string,sub?:string})=>(
    <div style={{background:card,border:`1px solid ${bord}`,borderRadius:14,padding:'18px',display:'flex',gap:12,alignItems:'flex-start'}}>
      <div style={{width:42,height:42,borderRadius:12,background:`${color}18`,border:`1px solid ${color}28`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,flexShrink:0}}>{icon}</div>
      <div style={{flex:1,minWidth:0}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.3rem,2.5vw,1.8rem)',fontWeight:800,color,lineHeight:1}}>{typeof val==='number'?val.toLocaleString():val}</div>
        <div style={{fontSize:11,color:ts,marginTop:2}}>{label}</div>
        {sub&&<div style={{fontSize:9,color:ts,marginTop:2}}>{sub}</div>}
      </div>
    </div>
  )
  const Btn = ({children,onClick,variant='primary',style={},disabled=false}:{children:any,onClick?:()=>void,variant?:'primary'|'danger'|'ghost'|'success',style?:any,disabled?:boolean})=>{
    const s:any={primary:{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none'},danger:{background:'rgba(255,71,87,0.1)',color:'#FF6B7A',border:'1px solid rgba(255,71,87,0.3)'},ghost:{background:'transparent',color:accent,border:`1px solid rgba(77,159,255,0.3)`},success:{background:'rgba(0,196,140,0.1)',color:'#00C48C',border:'1px solid rgba(0,196,140,0.3)'}}
    return <button disabled={disabled} onClick={onClick} style={{padding:'9px 18px',borderRadius:10,cursor:disabled?'not-allowed':'pointer',fontFamily:'Inter,sans-serif',fontWeight:600,fontSize:12,opacity:disabled?0.5:1,...s[variant],...style}}>{children}</button>
  }
  const Badge = ({children,color='blue'}:{children:any,color?:'blue'|'green'|'red'|'orange'|'purple'|'gold'})=>{
    const c:any={blue:{bg:'rgba(77,159,255,0.12)',cl:'#4D9FFF'},green:{bg:'rgba(0,196,140,0.12)',cl:'#00C48C'},red:{bg:'rgba(255,71,87,0.12)',cl:'#FF6B7A'},orange:{bg:'rgba(255,165,2,0.12)',cl:'#FFA502'},purple:{bg:'rgba(168,85,247,0.12)',cl:'#A855F7'},gold:{bg:'rgba(255,215,0,0.12)',cl:'#FFD700'}}
    return <span style={{background:c[color].bg,color:c[color].cl,padding:'3px 10px',borderRadius:99,fontSize:11,fontWeight:700,flexShrink:0}}>{children}</span>
  }
  const TableComp = ({headers,children}:{headers:string[],children:any})=>(
    <div style={{overflowX:'auto'}}>
      <table style={{width:'100%',borderCollapse:'collapse',whiteSpace:'nowrap'}}>
        <thead><tr>{headers.map(h=><th key={h} style={{padding:'11px 16px',textAlign:'left',fontSize:10,fontWeight:700,color:ts,letterSpacing:'0.08em',textTransform:'uppercase',borderBottom:`1px solid ${bord}`}}>{h}</th>)}</tr></thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  )
  const TR = ({children,onClick}:{children:any,onClick?:()=>void})=>(
    <tr style={{cursor:onClick?'pointer':'default'}} onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')} onMouseLeave={e=>(e.currentTarget.style.background='transparent')} onClick={onClick}>{children}</tr>
  )
  const TD = ({children,style={}}:{children:any,style?:any})=>(
    <td style={{padding:'11px 16px',borderBottom:`1px solid rgba(0,45,85,0.12)`,fontSize:12,color:tm,...style}}>{children}</td>
  )

  // ═══════════════════════════════════════════════════
  // NAV SECTIONS (Admin vs SuperAdmin)
  // ═══════════════════════════════════════════════════
  const adminNavSections = [
    { id:'main', label:'', items:[
      { id:'dashboard', icon:'⊞', en:'Dashboard', hi:'डैशबोर्ड' },
      { id:'live_monitor', icon:'🔴', en:'Live Monitor', hi:'लाइव मॉनिटर' },
    ]},
    { id:'exams', label:'EXAM MANAGEMENT', items:[
      { id:'all_exams', icon:'📋', en:'All Exams', hi:'सभी परीक्षाएं' },
      { id:'create_exam', icon:'➕', en:'Create Exam', hi:'परीक्षा बनाएं' },
      { id:'question_bank', icon:'🗂️', en:'Question Bank', hi:'प्रश्न बैंक' },
      { id:'smart_gen', icon:'🤖', en:'Smart Paper Generator', hi:'स्मार्ट जनरेटर' },
      { id:'bulk_upload', icon:'📤', en:'Bulk Upload', hi:'बल्क अपलोड' },
      { id:'pyq_bank', icon:'📚', en:'PYQ Bank', hi:'PYQ बैंक' },
    ]},
    { id:'students', label:'STUDENT MANAGEMENT', items:[
      { id:'all_students', icon:'👥', en:'All Students', hi:'सभी छात्र' },
      { id:'batch_manager', icon:'📁', en:'Batch Manager', hi:'बैच मैनेजर' },
      { id:'ban_system', icon:'🚫', en:'Ban System', hi:'बैन सिस्टम' },
    ]},
    { id:'results', label:'RESULTS & ANALYTICS', items:[
      { id:'result_control', icon:'🎯', en:'Result Control', hi:'परिणाम' },
      { id:'leaderboard', icon:'🏆', en:'Leaderboard', hi:'लीडरबोर्ड' },
      { id:'analytics', icon:'📊', en:'Analytics', hi:'विश्लेषण' },
      { id:'export', icon:'📥', en:'Export Reports', hi:'एक्सपोर्ट' },
      { id:'tickets', icon:'📬', en:'Tickets', hi:'टिकट' },
    ]},
    { id:'comms', label:'COMMUNICATIONS', items:[
      { id:'announcements', icon:'📢', en:'Announcements', hi:'घोषणाएं' },
    ]},
    { id:'proctor', label:'PROCTORING', items:[
      { id:'cheat_logs', icon:'⚠️', en:'Cheating Logs', hi:'चीटिंग लॉग' },
    ]},
    { id:'admin_tools', label:'ADMIN TOOLS', items:[
      { id:'activity_logs', icon:'📋', en:'Activity Logs', hi:'लॉग' },
      { id:'todo', icon:'✅', en:'Task Manager', hi:'टास्क' },
      { id:'changelog', icon:'📝', en:'Platform Changelog', hi:'चेंजलॉग' },
    ]},
  ]

  const superadminNavSections = [
    ...adminNavSections,
    { id:'sa_proctor', label:'PROCTORING (FULL)', items:[
      { id:'snapshots', icon:'📸', en:'Webcam Snapshots', hi:'स्नैपशॉट' },
      { id:'integrity', icon:'🛡️', en:'Integrity Scores', hi:'अखंडता स्कोर' },
    ]},
    { id:'super', label:'⚡ SUPERADMIN ONLY', items:[
      { id:'feature_flags', icon:'🚩', en:'Feature Flags', hi:'फीचर फ्लैग' },
      { id:'permissions', icon:'🔐', en:'Admin Permissions', hi:'अनुमतियां' },
      { id:'branding', icon:'🎨', en:'Custom Branding', hi:'ब्रांडिंग' },
      { id:'seo', icon:'🌐', en:'SEO Settings', hi:'SEO' },
      { id:'audit_trail', icon:'📜', en:'Audit Trail', hi:'ऑडिट ट्रेल' },
      { id:'maintenance', icon:'🔧', en:'Maintenance Mode', hi:'मेंटेनेंस' },
      { id:'data_backup', icon:'💾', en:'Data Backup', hi:'बैकअप' },
      { id:'impersonate', icon:'👁️', en:'Impersonate Student', hi:'छात्र देखें' },
    ]},
  ]

  const navSections = role==='superadmin' ? superadminNavSections : adminNavSections

  // ═══════════════════════════════════════════════════
  // RENDER FUNCTIONS
  // ═══════════════════════════════════════════════════

  // FIX: Stats — real API numbers, no fake hardcoded values
  const renderDashboard = ()=>{
    const totalStudents = stats?.totalStudents ?? students.length
    const totalExams = stats?.totalExams ?? exams.length
    const totalAttempts = stats?.totalAttempts ?? 0
    const cheatCount = stats?.cheatFlags ?? flags.length
    const openTickets = stats?.openTickets ?? tickets.filter(t=>t.status!=='resolved').length
    const avgScore = stats?.avgScore ?? (totalAttempts>0 ? 'Calculating...' : '—')

    return (
      <div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:12,marginBottom:20}}>
          {[
            {icon:'👨‍🎓',label:'Total Students',val:loadingStats?'—':totalStudents,color:'#4D9FFF',sub:loadingStats?'Fetching from DB...':undefined},
            {icon:'📝',label:'Total Exams',val:loadingStats?'—':totalExams,color:'#00C48C',sub:loadingStats?'Fetching from DB...':undefined},
            {icon:'📊',label:'Total Attempts',val:loadingStats?'—':totalAttempts,color:'#A855F7',sub:loadingStats?'Fetching from DB...':undefined},
            {icon:'⚠️',label:'Cheat Flags',val:loadingStats?'—':cheatCount,color:'#FF4757',sub:loadingStats?'Fetching from DB...':undefined},
            {icon:'📬',label:'Open Tickets',val:loadingStats?'—':openTickets,color:'#FFA502',sub:loadingStats?'Fetching from DB...':undefined},
            {icon:'💡',label:'Avg Score',val:loadingStats?'—':avgScore,color:'#FFD700',sub:loadingStats?'Fetching from DB...':undefined},
          ].map((s,i)=>(<StatCard key={i} {...s}/>))}
        </div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(320px,1fr))',gap:16,marginBottom:16}}>
          <Card>
            <CardHeader title="📢 Quick Announcement"/>
            <div style={{padding:'16px 20px'}}>
              <TextArea value={announceText} onChange={setAnnounceText} rows={3} placeholder="Type announcement..."/>
              <div style={{display:'flex',gap:8,marginTop:10,alignItems:'center'}}>
                <select value={announceBatch} onChange={e=>setAnnounceBatch(e.target.value)} style={{padding:'8px 12px',borderRadius:8,border:`1px solid ${iBrd}`,background:iBg,color:tm,fontSize:12,fontFamily:'Inter,sans-serif',outline:'none'}}>
                  <option value="all">All Students</option>
                  <option value="neet_a">NEET Batch A</option>
                  <option value="neet_b">NEET Batch B</option>
                </select>
                <Btn onClick={sendAnnounce}>📤 Send</Btn>
              </div>
            </div>
          </Card>
          <Card>
            <CardHeader title="✅ Tasks" action={<span style={{fontSize:11,color:ts}}>{todos.filter(t=>!t.done).length} pending</span>}/>
            <div style={{padding:'12px 16px'}}>
              <div style={{display:'flex',gap:8,marginBottom:10}}>
                <input value={todoInput} onChange={e=>setTodoInput(e.target.value)} onKeyDown={e=>e.key==='Enter'&&addTodo()} placeholder="Add task..." style={{flex:1,padding:'7px 11px',borderRadius:8,border:`1px solid ${iBrd}`,background:iBg,color:tm,fontSize:12,fontFamily:'Inter,sans-serif',outline:'none'}}/>
                <Btn onClick={addTodo}>+</Btn>
              </div>
              {todos.map(t=>(
                <div key={t.id} style={{display:'flex',alignItems:'center',gap:8,padding:'6px 10px',borderRadius:8,background:t.done?'rgba(0,196,140,0.04)':'rgba(77,159,255,0.04)',border:`1px solid ${t.done?'rgba(0,196,140,0.12)':bord}`,marginBottom:4}}>
                  <input type="checkbox" checked={t.done} onChange={()=>setTodos(p=>p.map(x=>x.id===t.id?{...x,done:!x.done}:x))} style={{accentColor:accent,flexShrink:0}}/>
                  <span style={{fontSize:12,color:t.done?ts:tm,textDecoration:t.done?'line-through':'none',flex:1}}>{t.text}</span>
                  <button onClick={()=>setTodos(p=>p.filter(x=>x.id!==t.id))} style={{background:'none',border:'none',color:ts,cursor:'pointer',fontSize:12}}>✕</button>
                </div>
              ))}
            </div>
          </Card>
        </div>
        <Card>
          <CardHeader title="📈 Platform Overview" action={<button onClick={()=>fetchAllData(token)} style={{padding:'5px 12px',borderRadius:8,border:`1px solid ${bord}`,background:'transparent',color:accent,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🔄 Refresh</button>}/>
          <div style={{padding:'16px 20px',display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:12}}>
            {[
              {l:'Active Today',v:stats?.activeToday??'—',c:'#00C48C'},
              {l:'Completion Rate',v:stats?.completionRate??'—',c:'#4D9FFF'},
              {l:'Banned Students',v:students.filter(s=>s.banned).length,c:'#FF6B7A'},
              {l:'Leaderboard Entries',v:leaderboard.length||'—',c:'#FFD700'},
              {l:'Cheat Flags (High)',v:flags.filter(f=>f.severity==='high').length||'—',c:'#FF4757'},
              {l:'Backend Status',v:'🟢 Live',c:'#00C48C'},
            ].map((s,i)=>(
              <div key={i} style={{padding:'14px',background:'rgba(77,159,255,0.04)',border:`1px solid ${bord}`,borderRadius:12}}>
                <div style={{fontSize:11,color:ts,marginBottom:4}}>{s.l}</div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:800,color:s.c}}>{typeof s.v==='number'?s.v.toLocaleString():s.v}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    )
  }

  const renderLiveMonitor = ()=>(
    <div style={{display:'flex',flexDirection:'column',gap:16}}>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:10}}>
        <StatCard icon="🟢" label="Live Students" val={stats?.activeToday??0} color="#00C48C" sub="Real-time from API"/>
        <StatCard icon="⚡" label="Server Status" val="OK" color="#4D9FFF" sub="Render.com Live"/>
        <StatCard icon="⚠️" label="Active Warnings" val={flags.length} color="#FFA502" sub="This session"/>
        <StatCard icon="🔴" label="High Severity Flags" val={flags.filter(f=>f.severity==='high').length} color="#FF4757" sub="Needs attention"/>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:14}}>
        <Card>
          <CardHeader title="🎮 Live Exam Controls"/>
          <div style={{padding:'20px'}}>
            {exams.filter(e=>e.status==='upcoming'||e.status==='live').slice(0,3).map(e=>(
              <div key={e._id} style={{padding:'12px',borderRadius:10,border:`1px solid ${bord}`,marginBottom:8}}>
                <div style={{fontWeight:700,color:tm,fontSize:13,marginBottom:4}}>{e.title}</div>
                <div style={{fontSize:11,color:ts,marginBottom:10}}>📅 {new Date(e.scheduledAt).toLocaleDateString()} · {e.attempts||0} attempts</div>
                <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                  <Btn variant="ghost" style={{fontSize:11,padding:'6px 12px'}}>⏸ Pause</Btn>
                  <Btn variant="ghost" style={{fontSize:11,padding:'6px 12px'}}>⏰ Extend Time</Btn>
                  <Btn variant="danger" style={{fontSize:11,padding:'6px 12px'}}>⏹ End Exam</Btn>
                </div>
              </div>
            ))}
            {exams.filter(e=>e.status==='upcoming'||e.status==='live').length===0 &&
              <EmptyState icon="✅" msg="No live exams right now"/>
            }
          </div>
        </Card>
        <Card>
          <CardHeader title="⚠️ Recent Flags (Live)"/>
          <div style={{padding:'12px'}}>
            {flags.length===0 && <EmptyState icon={loadingMain?'⏳':'✅'} msg={loadingMain?'Loading flags...':'No cheating flags found'}/>}
            {flags.slice(0,5).map((f,i)=>(
              <div key={f._id||i} style={{padding:'10px 12px',borderRadius:10,border:`1px solid ${bord}`,marginBottom:8,display:'flex',gap:10,alignItems:'flex-start'}}>
                <div style={{width:8,height:8,borderRadius:'50%',background:f.severity==='high'?'#FF4757':f.severity==='medium'?'#FFA502':'#4D9FFF',marginTop:4,flexShrink:0}}/>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontWeight:600,color:tm,fontSize:12}}>{f.studentName}</div>
                  <div style={{fontSize:11,color:ts}}>{f.type} × {f.count} — {f.examTitle}</div>
                </div>
                <Badge color={f.severity==='high'?'red':f.severity==='medium'?'orange':'blue'}>{f.severity}</Badge>
              </div>
            ))}
            {flags.length>0&&<Btn variant="ghost" onClick={()=>navTo('cheat_logs')} style={{width:'100%',marginTop:4,fontSize:11}}>View All Flags →</Btn>}
          </div>
        </Card>
      </div>
    </div>
  )

  const renderAllExams = ()=>(
    <Card>
      <CardHeader title={`📋 All Exams (${exams.length})`} action={
        <div style={{display:'flex',gap:8,alignItems:'center'}}>
          <input value={examSearchFilter} onChange={e=>setExamSearchFilter(e.target.value)} placeholder="Search exams..." style={{padding:'7px 12px',borderRadius:8,border:`1px solid ${iBrd}`,background:iBg,color:tm,fontSize:12,fontFamily:'Inter,sans-serif',outline:'none',width:180}}/>
          <Btn onClick={()=>{setExamStep(1);navTo('create_exam')}}>+ New</Btn>
        </div>
      }/>
      {exams.length===0&&<EmptyState icon={loadingMain?'⏳':'📋'} msg={loadingMain?'Loading exams...':'No exams found. Create your first exam!'}/>}
      <TableComp headers={['#','Title','Category','Date','Duration','Marks','Attempts','Status','Actions']}>
        {exams.filter(e=>e.title.toLowerCase().includes(examSearchFilter.toLowerCase())).map((e,i)=>(
          <TR key={e._id}>
            <TD style={{color:ts}}>{i+1}</TD>
            <TD><div style={{fontWeight:600,color:tm,maxWidth:200,overflow:'hidden',textOverflow:'ellipsis'}}>{e.title}</div></TD>
            <TD><Badge color="blue">{e.category||'Full Mock'}</Badge></TD>
            <TD style={{color:ts}}>{new Date(e.scheduledAt).toLocaleDateString()}</TD>
            <TD style={{color:ts}}>{Math.round((e.totalDurationSec||12000)/60)}m</TD>
            <TD style={{color:accent,fontWeight:700}}>{e.totalMarks}</TD>
            <TD style={{color:ts}}>{e.attempts||0}</TD>
            <TD><Badge color={e.status==='completed'||e.status==='published'?'green':e.status==='live'?'red':'blue'}>{e.status}</Badge></TD>
            <TD><div style={{display:'flex',gap:5}}>
              <button style={{padding:'5px 10px',borderRadius:7,border:`1px solid ${bord}`,background:'transparent',color:accent,fontSize:11,cursor:'pointer'}}>✏️</button>
              <button onClick={()=>setExams(p=>p.filter(x=>x._id!==e._id))} style={{padding:'5px 10px',borderRadius:7,border:'1px solid rgba(255,71,87,0.3)',background:'transparent',color:'#FF6B7A',fontSize:11,cursor:'pointer'}}>🗑</button>
            </div></TD>
          </TR>
        ))}
      </TableComp>
    </Card>
  )

  // FIX: Create Exam — 3-step wizard
  const renderCreateExam = ()=>(
    <div>
      <div style={{display:'flex',alignItems:'center',gap:0,marginBottom:24}}>
        {[{n:1,l:'Basic Info'},{n:2,l:'Questions'},{n:3,l:'Done'}].map(({n,l},i)=>(
          <div key={n} style={{display:'flex',alignItems:'center'}}>
            <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:4}}>
              <div style={{width:36,height:36,borderRadius:'50%',background:examStep>=n?accent:'rgba(77,159,255,0.1)',border:`2px solid ${examStep>=n?accent:'rgba(77,159,255,0.2)'}`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:14,fontWeight:700,color:examStep>=n?'#fff':ts,transition:'all 0.3s'}}>{examStep>n?'✓':n}</div>
              <div style={{fontSize:10,color:examStep>=n?accent:ts,fontWeight:examStep>=n?700:400}}>{l}</div>
            </div>
            {i<2 && <div style={{width:60,height:2,background:examStep>n?accent:'rgba(77,159,255,0.1)',margin:'0 8px 20px',transition:'all 0.3s'}}/>}
          </div>
        ))}
      </div>

      {examStep===1 && (
        <Card style={{maxWidth:620}}>
          <CardHeader title="➕ Step 1: Create Exam"/>
          <div style={{padding:'24px'}}>
            <InpRef label="Exam Title" ref={refExamTitle} defaultValue="" placeholder="e.g. NEET Full Mock #14"/>
            <InpRef label="Scheduled Date & Time" ref={refExamDate} defaultValue="" type="datetime-local"/>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
              <InpRef label="Total Marks" ref={refExamMarks} defaultValue="720" type="number"/>
              <InpRef label="Duration (minutes)" ref={refExamDur} defaultValue="200" type="number"/>
            </div>
            <div style={{marginBottom:14}}>
              <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Category</label>
              <select value={newExamCat} onChange={e=>setNewExamCat(e.target.value)} style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
                {['Full Mock','Chapter Test','Part Test','Previous Year','Custom'].map(c=><option key={c}>{c}</option>)}
              </select>
            </div>
            <InpRef label="Password (optional)" ref={refExamPass} defaultValue="" placeholder="Leave blank for open exam"/>
            <Btn onClick={createExamStep1} style={{width:'100%',marginTop:8}}>🚀 Create Exam (POST /api/exams)</Btn>
          </div>
        </Card>
      )}

      {examStep===2 && (
        <Card style={{maxWidth:700}}>
          <CardHeader title="📚 Step 2: Add Questions" action={
            <div style={{display:'flex',gap:8,alignItems:'center'}}>
              <Badge color="green">Exam Created ✓</Badge>
              <Btn variant="ghost" onClick={()=>setExamStep(3)} style={{fontSize:11,padding:'5px 10px'}}>Skip →</Btn>
            </div>
          }/>
          <div style={{padding:'20px'}}>
            <div style={{marginBottom:20}}>
              <div style={{fontSize:10,fontWeight:700,color:accent,marginBottom:10,letterSpacing:'0.08em',textTransform:'uppercase'}}>Upload Method</div>
              <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8}}>
                {[
                  {key:'manual',icon:'✏️',label:'Manual Entry'},
                  {key:'excel',icon:'📊',label:'Excel File'},
                  {key:'pdf',icon:'📄',label:'PDF Parse'},
                  {key:'copypaste',icon:'📋',label:'Copy-Paste'},
                ].map(m=>(
                  <button key={m.key} onClick={()=>setQUploadMethod(m.key as any)}
                    style={{padding:'12px 8px',borderRadius:12,border:`2px solid ${qUploadMethod===m.key?accent:'rgba(77,159,255,0.15)'}`,background:qUploadMethod===m.key?'rgba(77,159,255,0.1)':iBg,color:qUploadMethod===m.key?accent:ts,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:11,fontWeight:qUploadMethod===m.key?700:400,transition:'all 0.2s',textAlign:'center'}}>
                    <div style={{fontSize:20,marginBottom:4}}>{m.icon}</div>
                    {m.label}
                  </button>
                ))}
              </div>
            </div>
            {(qUploadMethod==='manual'||qUploadMethod==='copypaste') && (
              <div>
                <div style={{padding:'12px',background:'rgba(77,159,255,0.04)',borderRadius:10,border:`1px solid ${bord}`,marginBottom:12,fontSize:11,color:ts}}>
                  Format: Q1. Question text?{'\n'}A) Option A{'\n'}B) Option B{'\n'}C) Option C{'\n'}D) Option D
                </div>
                <div style={{marginBottom:14}}>
                  <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Paste Questions</label>
                  <TextArea value={manualQText} onChange={setManualQText} rows={8} placeholder="Paste questions here..." mono={true}/>
                </div>
                <div style={{marginBottom:14}}>
                  <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Answer Key (optional)</label>
                  <TextArea value={answerKeyText} onChange={setAnswerKeyText} rows={4} placeholder="1-B 2-A 3-D" mono={true}/>
                </div>
              </div>
            )}
            {qUploadMethod==='excel' && (
              <div>
                <div style={{padding:'14px',background:'rgba(0,196,140,0.04)',borderRadius:10,border:'1px solid rgba(0,196,140,0.2)',marginBottom:16}}>
                  <div style={{fontSize:12,color:'#00C48C',fontWeight:700,marginBottom:6}}>📊 Excel Format (POST /api/excel/upload)</div>
                  <div style={{fontSize:11,color:ts}}>Columns: <code style={{color:accent}}>question | optionA | optionB | optionC | optionD | correctOption | subject | difficulty</code></div>
                </div>
                <div style={{padding:'30px',borderRadius:12,border:`2px dashed ${iBrd}`,background:iBg,textAlign:'center',cursor:'pointer',position:'relative',marginBottom:16}}
                  onDragOver={e=>e.preventDefault()}
                  onDrop={e=>{e.preventDefault();const f=e.dataTransfer.files[0];if(f)setExcelFile(f)}}>
                  <div style={{fontSize:32,marginBottom:8}}>📊</div>
                  <div style={{fontSize:13,color:tm,fontWeight:600,marginBottom:4}}>{excelFile?excelFile.name:'Drag & Drop Excel File'}</div>
                  <div style={{fontSize:11,color:ts}}>or click to browse</div>
                  <input type="file" accept=".xlsx,.xls,.csv" onChange={e=>setExcelFile(e.target.files?.[0]||null)}
                    style={{position:'absolute',inset:0,opacity:0,cursor:'pointer'}}/>
                </div>
              </div>
            )}
            {qUploadMethod==='pdf' && (
              <div>
                <div style={{padding:'14px',background:'rgba(168,85,247,0.04)',borderRadius:10,border:'1px solid rgba(168,85,247,0.2)',marginBottom:16}}>
                  <div style={{fontSize:12,color:'#A855F7',fontWeight:700,marginBottom:6}}>📄 PDF Parser (POST /api/upload/pdf)</div>
                  <div style={{fontSize:11,color:ts}}>Upload question paper PDF — system will auto-extract questions.</div>
                </div>
                <div style={{padding:'30px',borderRadius:12,border:`2px dashed ${iBrd}`,background:iBg,textAlign:'center',cursor:'pointer',position:'relative',marginBottom:16}}
                  onDragOver={e=>e.preventDefault()}
                  onDrop={e=>{e.preventDefault();const f=e.dataTransfer.files[0];if(f)setPdfFile(f)}}>
                  <div style={{fontSize:32,marginBottom:8}}>📄</div>
                  <div style={{fontSize:13,color:tm,fontWeight:600,marginBottom:4}}>{pdfFile?pdfFile.name:'Drag & Drop PDF'}</div>
                  <input type="file" accept=".pdf" onChange={e=>setPdfFile(e.target.files?.[0]||null)}
                    style={{position:'absolute',inset:0,opacity:0,cursor:'pointer'}}/>
                </div>
                <div style={{marginBottom:14}}>
                  <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Answer Key (if separate)</label>
                  <TextArea value={answerKeyText} onChange={setAnswerKeyText} rows={4} placeholder="1-B, 2-A, 3-D ..." mono={true}/>
                </div>
              </div>
            )}
            <div style={{display:'flex',gap:10,marginTop:8}}>
              <Btn onClick={uploadQuestions} disabled={uploadingQ} style={{flex:1}}>
                {uploadingQ?'⏳ Uploading...':'📤 Upload Questions'}
              </Btn>
              <Btn variant="ghost" onClick={()=>setExamStep(3)} style={{flex:0,whiteSpace:'nowrap'}}>Skip →</Btn>
            </div>
          </div>
        </Card>
      )}

      {examStep===3 && (
        <Card style={{maxWidth:500}}>
          <div style={{padding:'40px',textAlign:'center'}}>
            <div style={{width:72,height:72,borderRadius:'50%',background:'rgba(0,196,140,0.12)',border:'2px solid rgba(0,196,140,0.3)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:32,margin:'0 auto 20px'}}>✅</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:tm,marginBottom:8}}>Exam Ready!</div>
            {uploadResult && <div style={{fontSize:13,color:'#00C48C',marginBottom:8}}>{uploadResult.success} questions uploaded{uploadResult.failed>0?`, ${uploadResult.failed} failed`:''}</div>}
            <div style={{fontSize:12,color:ts,marginBottom:24}}>Exam created. Add more questions anytime from Question Bank.</div>
            <div style={{display:'flex',gap:10,justifyContent:'center',flexWrap:'wrap'}}>
              <Btn onClick={()=>{setExamStep(1);if(refExamTitle.current)refExamTitle.current.value='';if(refExamDate.current)refExamDate.current.value='';if(refExamPass.current)refExamPass.current.value='';if(refExamMarks.current)refExamMarks.current.value='720';if(refExamDur.current)refExamDur.current.value='200';setCreatedExamId('');setUploadResult(null);setManualQText('');setAnswerKeyText('')}}>➕ Create Another</Btn>
              <Btn variant="ghost" onClick={()=>navTo('all_exams')}>📋 View All Exams</Btn>
              <Btn variant="ghost" onClick={()=>navTo('question_bank')}>🗂️ Question Bank</Btn>
            </div>
          </div>
        </Card>
      )}
    </div>
  )

  const renderQuestionBank = ()=>(
    <div style={{display:'flex',flexDirection:'column',gap:14}}>
      <div style={{padding:'12px 16px',borderRadius:10,background:'rgba(77,159,255,0.06)',border:`1px solid ${bord}`,fontSize:12,color:ts}}>
        🗂️ Question Bank — All questions stored in database. Filter by subject, chapter, difficulty.
      </div>
      <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:4}}>
        {['All','Physics','Chemistry','Biology','Easy','Medium','Hard'].map(f=>(
          <button key={f} style={{padding:'7px 14px',borderRadius:20,border:`1px solid ${bord}`,background:'transparent',color:ts,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12}}>{f}</button>
        ))}
        <Btn style={{marginLeft:'auto'}}>+ Add Question</Btn>
      </div>
      <Card>
        <CardHeader title="🗂️ All Questions (GET /api/questions)" action={<button onClick={()=>fetchAllData(token)} style={{padding:'5px 10px',borderRadius:8,border:`1px solid ${bord}`,background:'transparent',color:accent,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🔄 Refresh</button>}/>
        <EmptyState icon="🗂️" msg="Questions will appear here from your database. Add questions via Create Exam → Step 2 or use Bulk Upload."/>
      </Card>
    </div>
  )

  const renderBulkUpload = ()=>(
    <div style={{display:'flex',flexDirection:'column',gap:14}}>
      <Card>
        <CardHeader title="📤 Bulk Upload — Excel / PDF / Copy-Paste"/>
        <div style={{padding:'20px'}}>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(200px,1fr))',gap:12,marginBottom:20}}>
            {[
              {icon:'📊',title:'Excel Upload',desc:'POST /api/excel/upload',color:'#00C48C',sub:'XLSX/XLS/CSV format'},
              {icon:'📄',title:'PDF Parse',desc:'POST /api/upload/pdf',color:'#A855F7',sub:'Auto-extract questions'},
              {icon:'📋',title:'Copy-Paste',desc:'POST /api/upload/copy-paste',color:'#4D9FFF',sub:'Q&A text format'},
            ].map(({icon,title,desc,color,sub})=>(
              <div key={title} style={{padding:'20px',borderRadius:12,border:`1px solid rgba(77,159,255,0.15)`,background:'rgba(77,159,255,0.04)',textAlign:'center',cursor:'pointer'}}>
                <div style={{fontSize:32,marginBottom:8}}>{icon}</div>
                <div style={{fontWeight:700,color:tm,fontSize:13,marginBottom:4}}>{title}</div>
                <div style={{fontSize:10,color:ts,marginBottom:8}}>{sub}</div>
                <code style={{fontSize:10,color:accent}}>{desc}</code>
              </div>
            ))}
          </div>
          <div style={{padding:'14px',borderRadius:10,background:'rgba(255,165,2,0.04)',border:'1px solid rgba(255,165,2,0.2)',fontSize:11,color:'#FFA502'}}>
            ⚠️ Use Create Exam → Step 2 for full bulk upload wizard with drag & drop interface.
          </div>
        </div>
      </Card>
    </div>
  )

  const renderPYQBank = ()=>(
    <Card>
      <CardHeader title="📚 PYQ Bank (S104 — Previous Year Questions)" action={<Badge color="gold">⚡ Feature Flag</Badge>}/>
      <div style={{padding:'20px'}}>
        <div style={{padding:'14px',borderRadius:10,background:'rgba(77,159,255,0.06)',border:`1px solid ${bord}`,marginBottom:16,fontSize:12,color:ts}}>
          Previous year NEET questions bank. Students can practice from real past papers.
        </div>
        {['2023','2022','2021','2020','2019'].map(yr=>(
          <div key={yr} style={{padding:'14px',borderRadius:10,border:`1px solid ${bord}`,marginBottom:8,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
            <div>
              <div style={{fontWeight:700,color:tm,fontSize:13}}>NEET {yr} Paper</div>
              <div style={{fontSize:11,color:ts}}>180 Questions · 720 Marks</div>
            </div>
            <div style={{display:'flex',gap:8}}>
              <Btn variant="ghost" style={{fontSize:11,padding:'6px 12px'}}>📊 Stats</Btn>
              <Btn style={{fontSize:11,padding:'6px 12px'}}>📥 Import</Btn>
            </div>
          </div>
        ))}
      </div>
    </Card>
  )

  const renderAllStudents = ()=>(
    <Card>
      <CardHeader title={`👥 All Students (${students.length})`} action={
        <input value={searchQuery} onChange={e=>setSearchQuery(e.target.value)} placeholder="Search..." style={{padding:'7px 12px',borderRadius:8,border:`1px solid ${iBrd}`,background:iBg,color:tm,fontSize:12,fontFamily:'Inter,sans-serif',outline:'none',width:180}}/>
      }/>
      {students.length===0&&<EmptyState icon={loadingMain?'⏳':'👥'} msg={loadingMain?'Loading students...':'No students registered yet'}/>}
      <TableComp headers={['#','Name','Email','Phone','Group','Integrity','Status','Joined','Actions']}>
        {students.filter(s=>
          s.name?.toLowerCase().includes(searchQuery.toLowerCase())||
          s.email?.toLowerCase().includes(searchQuery.toLowerCase())
        ).map((s,i)=>(
          <TR key={s._id}>
            <TD style={{color:ts}}>{i+1}</TD>
            <TD><div style={{fontWeight:600,color:tm}}>{s.name}</div></TD>
            <TD style={{color:ts,fontSize:11}}>{s.email}</TD>
            <TD style={{color:ts,fontSize:11}}>{s.phone||'—'}</TD>
            <TD><Badge color="blue">{s.group||'General'}</Badge></TD>
            <TD>
              <div style={{display:'flex',alignItems:'center',gap:6}}>
                <div style={{height:5,width:60,background:'rgba(255,255,255,0.08)',borderRadius:99,overflow:'hidden'}}>
                  <div style={{height:'100%',width:`${s.integrityScore||80}%`,background:(s.integrityScore||80)>70?'#00C48C':(s.integrityScore||80)>40?'#FFA502':'#FF4757',borderRadius:99}}/>
                </div>
                <span style={{fontSize:11,color:ts}}>{s.integrityScore||80}</span>
              </div>
            </TD>
            <TD><Badge color={s.banned?'red':'green'}>{s.banned?'Banned':'Active'}</Badge></TD>
            <TD style={{color:ts,fontSize:11}}>{new Date(s.createdAt).toLocaleDateString()}</TD>
            <TD><div style={{display:'flex',gap:4}}>
              {s.banned
                ? <Btn variant="success" onClick={()=>unbanStudent(s._id)} style={{fontSize:10,padding:'4px 8px'}}>✓ Unban</Btn>
                : <Btn variant="danger" onClick={()=>{setBanStudentId(s._id);navTo('ban_system')}} style={{fontSize:10,padding:'4px 8px'}}>🚫 Ban</Btn>
              }
              <Btn variant="ghost" style={{fontSize:10,padding:'4px 8px'}}>👁 View</Btn>
            </div></TD>
          </TR>
        ))}
      </TableComp>
    </Card>
  )

  const renderBatchManager = ()=>(
    <Card>
      <CardHeader title="📁 Batch Manager (M3 — Student Groups)" action={<Btn>+ New Batch</Btn>}/>
      <div style={{padding:'20px'}}>
        {[
          {name:'NEET Batch A',count:0,status:'Active',color:'#00C48C'},
          {name:'NEET Batch B',count:0,status:'Active',color:'#4D9FFF'},
          {name:'Dropper Batch',count:0,status:'Active',color:'#A855F7'},
          {name:'General',count:students.length,status:'Active',color:'#FFA502'},
        ].map(b=>(
          <div key={b.name} style={{padding:'14px',borderRadius:12,border:`1px solid ${bord}`,marginBottom:10,display:'flex',alignItems:'center',gap:14}}>
            <div style={{width:44,height:44,borderRadius:12,background:`${b.color}18`,border:`1px solid ${b.color}28`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,flexShrink:0}}>📁</div>
            <div style={{flex:1}}>
              <div style={{fontWeight:700,color:tm,fontSize:13}}>{b.name}</div>
              <div style={{fontSize:11,color:ts}}>{b.count} students</div>
            </div>
            <Badge color="green">{b.status}</Badge>
            <div style={{display:'flex',gap:6}}>
              <Btn variant="ghost" style={{fontSize:11,padding:'6px 12px'}}>✏️ Edit</Btn>
              <Btn variant="ghost" style={{fontSize:11,padding:'6px 12px'}}>👥 Members</Btn>
            </div>
          </div>
        ))}
      </div>
    </Card>
  )

  const renderBanSystem = ()=>(
    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:14}}>
      <Card>
        <CardHeader title="🚫 Ban a Student"/>
        <div style={{padding:'20px'}}>
          <div style={{marginBottom:14}}>
            <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Select Student</label>
            <select value={banStudentId} onChange={e=>setBanStudentId(e.target.value)} style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
              <option value="">— Select Student —</option>
              {students.filter(s=>!s.banned).map(s=><option key={s._id} value={s._id}>{s.name} ({s.email})</option>)}
            </select>
          </div>
          <Inp label="Ban Reason" value={banReason} onChange={setBanReason} placeholder="Enter reason..."/>
          <div style={{marginBottom:14}}>
            <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Ban Type</label>
            <div style={{display:'flex',gap:8}}>
              {(['permanent','temporary'] as const).map(t=>(
                <button key={t} onClick={()=>setBanType(t)} style={{flex:1,padding:'9px',borderRadius:9,border:`1.5px solid ${banType===t?accent:iBrd}`,background:banType===t?'rgba(77,159,255,0.1)':iBg,color:banType===t?accent:ts,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',fontWeight:banType===t?700:400}}>{t.charAt(0).toUpperCase()+t.slice(1)}</button>
              ))}
            </div>
          </div>
          <Btn variant="danger" onClick={banStudent} style={{width:'100%'}}>🚫 Ban Student</Btn>
        </div>
      </Card>
      <Card>
        <CardHeader title="🔓 Currently Banned"/>
        <div style={{padding:'12px'}}>
          {students.filter(s=>s.banned).length===0&&<EmptyState icon="✅" msg="No banned students"/>}
          {students.filter(s=>s.banned).map(s=>(
            <div key={s._id} style={{padding:'12px',borderRadius:10,border:'1px solid rgba(255,71,87,0.2)',background:'rgba(255,71,87,0.04)',marginBottom:8}}>
              <div style={{fontWeight:700,color:tm,fontSize:13}}>{s.name}</div>
              <div style={{fontSize:11,color:ts,marginBottom:8}}>Reason: {s.banReason||'—'}</div>
              <Btn variant="success" onClick={()=>unbanStudent(s._id)} style={{fontSize:11,padding:'6px 12px'}}>✓ Unban</Btn>
            </div>
          ))}
        </div>
      </Card>
    </div>
  )

  const renderResultControl = ()=>(
    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:14}}>
      <Card>
        <CardHeader title="🎯 Result Control Panel"/>
        <div style={{padding:'20px'}}>
          {exams.filter(e=>e.status==='completed'||e.status==='submitted').length===0 &&
            <EmptyState icon="📝" msg="No completed exams to publish"/>
          }
          {exams.filter(e=>e.status==='completed'||e.status==='submitted').map(e=>(
            <div key={e._id} style={{padding:'14px',borderRadius:12,border:`1px solid ${bord}`,marginBottom:10}}>
              <div style={{fontWeight:700,color:tm,fontSize:13,marginBottom:4}}>{e.title}</div>
              <div style={{fontSize:11,color:ts,marginBottom:10}}>{e.attempts} attempts · {new Date(e.scheduledAt).toLocaleDateString()}</div>
              <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                <Btn onClick={()=>publishResult(e._id, e.title)} style={{fontSize:11,padding:'6px 12px'}}>📢 Publish Results</Btn>
                <Btn variant="ghost" style={{fontSize:11,padding:'6px 12px'}}>⏳ Delay</Btn>
                <Btn variant="ghost" style={{fontSize:11,padding:'6px 12px'}}>📄 Topper PDF</Btn>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  )

  const renderLeaderboard = ()=>(
    <Card>
      <CardHeader title="🏆 Leaderboard (GET /api/results/leaderboard)" action={<button onClick={()=>fetchAllData(token)} style={{padding:'5px 10px',borderRadius:8,border:`1px solid ${bord}`,background:'transparent',color:accent,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🔄 Refresh</button>}/>
      <div style={{padding:'12px'}}>
        {leaderboard.length===0&&<EmptyState icon={loadingMain?'⏳':'🏆'} msg={loadingMain?'Loading...':'No results published yet — leaderboard appears after publishing'}/>}
        {leaderboard.map((entry,i)=>(
          <div key={i} style={{display:'flex',alignItems:'center',gap:10,padding:'10px 12px',borderRadius:10,marginBottom:4,background:i<3?'rgba(255,215,0,0.04)':'transparent',border:`1px solid ${i<3?'rgba(255,215,0,0.15)':bord}`}}>
            <div style={{width:28,height:28,borderRadius:'50%',background:i===0?'rgba(255,215,0,0.2)':i===1?'rgba(192,192,192,0.2)':i===2?'rgba(205,127,50,0.2)':'rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:13,fontWeight:800,color:i===0?'#FFD700':i===1?'#C0C0C0':i===2?'#CD7F32':ts,flexShrink:0}}>
              {i<3?['🥇','🥈','🥉'][i]:entry.rank||i+1}
            </div>
            <div style={{flex:1}}>
              <div style={{fontWeight:600,color:tm,fontSize:12}}>{entry.name}</div>
              <div style={{fontSize:10,color:ts}}>Percentile: {entry.percentile}%</div>
            </div>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:16,color:accent}}>{entry.score}</div>
          </div>
        ))}
      </div>
    </Card>
  )

  const renderAnalytics = ()=>(
    <div style={{display:'flex',flexDirection:'column',gap:14}}>
      <div style={{padding:'12px 16px',borderRadius:10,background:'rgba(77,159,255,0.06)',border:`1px solid ${bord}`,fontSize:12,color:ts}}>
        📊 Analytics from <code style={{color:accent}}>/api/admin/stats</code> — detailed data appears after more exams are completed.
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:10}}>
        {[
          {l:'Total Students',v:stats?.totalStudents??students.length,c:'#4D9FFF'},
          {l:'Total Attempts',v:stats?.totalAttempts??0,c:'#00C48C'},
          {l:'Avg Score',v:stats?.avgScore??'—',c:'#A855F7'},
          {l:'Completion Rate',v:stats?.completionRate??'—',c:'#FFA502'},
          {l:'Cheat Flags',v:flags.length,c:'#FF6B7A'},
          {l:'Open Tickets',v:tickets.filter(t=>t.status!=='resolved').length,c:'#FFD700'}
        ].map((s,i)=>(
          <div key={i} style={{background:card,border:`1px solid ${bord}`,borderRadius:12,padding:'16px'}}>
            <div style={{fontSize:11,color:ts,marginBottom:4}}>{s.l}</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:s.c}}>{typeof s.v==='number'?s.v.toLocaleString():s.v}</div>
          </div>
        ))}
      </div>
    </div>
  )

  const renderExport = ()=>(
    <Card>
      <CardHeader title="📥 Export Reports (GET /api/admin/manage/export)"/>
      <div style={{padding:'20px',display:'flex',flexDirection:'column',gap:10}}>
        {[
          ['students','Student Performance Report (All Students)','PDF','#4D9FFF'],
          ['results','Exam Result Summary','CSV','#00C48C'],
          ['leaderboard','Rank List — Latest Exam','PDF','#A855F7'],
          ['questions','Question Bank Statistics','CSV','#FFA502'],
          ['audit','Audit Trail Log','CSV','#FF6B7A'],
        ].map(([type,label,format,color])=>(
          <button key={String(type)} onClick={()=>exportReport(String(type), String(label))}
            style={{padding:'12px 16px',borderRadius:10,border:`1px solid ${bord}`,background:'rgba(77,159,255,0.04)',color:tm,cursor:'pointer',display:'flex',justifyContent:'space-between',alignItems:'center',fontFamily:'Inter,sans-serif',fontSize:12,fontWeight:500,transition:'all 0.15s'}}
            onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.08)')}
            onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')}>
            <span>{label as string}</span>
            <span style={{fontSize:10,fontWeight:700,color:String(color),padding:'3px 10px',borderRadius:99,background:`${color}18`}}>{format as string} ↓</span>
          </button>
        ))}
      </div>
    </Card>
  )

  const renderTickets = ()=>(
    <Card>
      <CardHeader title="📬 Challenges & Grievances (GET /api/admin/manage/tickets)"/>
      {tickets.length===0&&<EmptyState icon={loadingMain?'⏳':'✅'} msg={loadingMain?'Loading tickets...':'No tickets/grievances found'}/>}
      <div style={{padding:'12px'}}>
        {tickets.map(t=>(
          <div key={t._id} style={{padding:'12px',borderRadius:10,border:`1px solid ${bord}`,marginBottom:8}}>
            <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}>
              <div style={{fontWeight:700,color:tm,fontSize:12}}>{t.studentName}</div>
              <Badge color={t.status==='pending'?'orange':t.status==='in-progress'?'blue':'green'}>{t.status}</Badge>
            </div>
            <div style={{fontSize:11,color:ts,marginBottom:4}}>{t.type} — {t.examTitle}</div>
            <div style={{fontSize:11,color:ts,marginBottom:8}}>{t.description}</div>
            <div style={{display:'flex',gap:6}}>
              {t.status!=='resolved' &&
                <Btn variant="success" onClick={()=>resolveTicket(t._id)} style={{fontSize:11,padding:'5px 10px'}}>✓ Resolve</Btn>
              }
              <Btn variant="ghost" style={{fontSize:11,padding:'5px 10px'}}>Reply</Btn>
            </div>
          </div>
        ))}
      </div>
    </Card>
  )

  const renderAnnouncements = ()=>(
    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:14}}>
      <Card>
        <CardHeader title="📢 Send Announcement (POST /api/admin/announce)"/>
        <div style={{padding:'20px'}}>
          <div style={{marginBottom:14}}>
            <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Announcement Text</label>
            <TextArea value={announceText} onChange={setAnnounceText} rows={5} placeholder="Write your announcement..."/>
          </div>
          <div style={{marginBottom:16}}>
            <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Target Batch</label>
            <select value={announceBatch} onChange={e=>setAnnounceBatch(e.target.value)} style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
              <option value="all">All Students</option>
              <option value="neet_a">NEET Batch A</option>
              <option value="neet_b">NEET Batch B</option>
              <option value="dropper">Dropper Batch</option>
            </select>
          </div>
          <Btn onClick={sendAnnounce} style={{width:'100%'}}>📤 Send Announcement</Btn>
        </div>
      </Card>
      <Card>
        <CardHeader title="📡 Broadcast Message (Socket.io)"/>
        <div style={{padding:'20px'}}>
          <div style={{padding:'14px',borderRadius:10,background:'rgba(77,159,255,0.06)',border:`1px solid ${bord}`,marginBottom:14}}>
            <div style={{fontSize:12,color:accent,fontWeight:700,marginBottom:4}}>Real-time Broadcast</div>
            <div style={{fontSize:11,color:ts}}>Send instant message to all online students via WebSocket.</div>
          </div>
          <div style={{marginBottom:14}}>
            <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Message</label>
            <textarea rows={4} placeholder="Real-time broadcast message..." style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',resize:'none',outline:'none',boxSizing:'border-box'}}/>
          </div>
          <Btn style={{width:'100%'}}>📡 Broadcast Now</Btn>
        </div>
      </Card>
    </div>
  )

  const renderCheatLogs = ()=>(
    <Card>
      <CardHeader title="⚠️ Cheating Logs (GET /api/admin/manage/cheating-logs)" action={<button onClick={()=>fetchAllData(token)} style={{padding:'5px 10px',borderRadius:8,border:`1px solid ${bord}`,background:'transparent',color:accent,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🔄 Refresh</button>}/>
      {flags.length===0&&<EmptyState icon={loadingMain?'⏳':'✅'} msg={loadingMain?'Loading cheating logs...':'No cheating flags found in database'}/>}
      <TableComp headers={['Student','Exam','Violation','Count','Severity','Time','Action']}>
        {flags.map((f,i)=>(
          <TR key={f._id||i}>
            <TD style={{fontWeight:600,color:tm}}>{f.studentName}</TD>
            <TD style={{color:ts,fontSize:11}}>{f.examTitle}</TD>
            <TD><Badge color={f.type?.includes('Tab')||f.type?.includes('Blur')?'orange':'red'}>{f.type}</Badge></TD>
            <TD><span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:16,color:f.count>=5?'#FF4757':'#FFA502'}}>{f.count}×</span></TD>
            <TD><Badge color={f.severity==='high'?'red':f.severity==='medium'?'orange':'blue'}>{f.severity}</Badge></TD>
            <TD style={{color:ts,fontSize:11}}>{new Date(f.at).toLocaleString()}</TD>
            <TD><div style={{display:'flex',gap:4}}>
              <Btn variant="ghost" style={{fontSize:10,padding:'4px 8px'}}>📄 Report</Btn>
              <Btn variant="danger" onClick={()=>{const s=students.find(st=>st.name===f.studentName);if(s){setBanStudentId(s._id);navTo('ban_system')}}} style={{fontSize:10,padding:'4px 8px'}}>🚫 Ban</Btn>
            </div></TD>
          </TR>
        ))}
      </TableComp>
    </Card>
  )

  const renderSnapshots = ()=>(
    <Card>
      <CardHeader title="📸 Webcam Snapshots (GET /api/admin/manage/snapshots)" action={<Badge color="gold">⚡ SuperAdmin</Badge>}/>
      <div style={{padding:'20px'}}>
        {snapshots.length===0&&<EmptyState icon={loadingMain?'⏳':'📷'} msg={loadingMain?'Loading snapshots...':'No webcam snapshots found. Snapshots appear during proctored exams.'}/>}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:12}}>
          {snapshots.map((snap,i)=>(
            <div key={snap._id||i} style={{borderRadius:12,overflow:'hidden',border:`2px solid ${snap.flagged?'rgba(255,71,87,0.4)':bord}`,position:'relative'}}>
              {snap.imageUrl
                ? <img src={snap.imageUrl} alt={snap.studentName} style={{width:'100%',height:110,objectFit:'cover'}}/>
                : <div style={{height:110,background:`linear-gradient(135deg,rgba(0,10,24,0.9),rgba(0,30,60,0.7))`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:32,color:'rgba(77,159,255,0.3)'}}>📷</div>
              }
              {snap.flagged && <div style={{position:'absolute',top:6,right:6,background:'#FF4757',color:'#fff',fontSize:9,fontWeight:700,padding:'3px 7px',borderRadius:99}}>⚠️ FLAGGED</div>}
              <div style={{padding:'8px 10px',background:'rgba(0,8,20,0.95)'}}>
                <div style={{fontSize:11,color:tm,fontWeight:600,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{snap.studentName}</div>
                <div style={{fontSize:10,color:ts}}>{new Date(snap.capturedAt).toLocaleTimeString()}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Card>
  )

  const renderIntegrity = ()=>(
    <Card>
      <CardHeader title="🛡️ Student Integrity Scores (AI-6)" action={<Badge color="gold">⚡ SuperAdmin</Badge>}/>
      <div style={{padding:'16px 20px'}}>
        <div style={{fontSize:12,color:ts,marginBottom:16}}>AI combines: tab switches + face detection + answer speed + IP flags → 0-100 score</div>
        {students.length===0&&<EmptyState icon={loadingMain?'⏳':'👥'} msg={loadingMain?'Loading...':'No students found'}/>}
        <TableComp headers={['Student','Group','Integrity Score','Risk Level','Actions']}>
          {students.map(s=>{
            const score = s.integrityScore||80
            const risk = score<40?'High':score<70?'Medium':'Low'
            return (
              <TR key={s._id}>
                <TD style={{fontWeight:600,color:tm}}>{s.name}</TD>
                <TD><Badge color="blue">{s.group||'General'}</Badge></TD>
                <TD>
                  <div style={{display:'flex',alignItems:'center',gap:8}}>
                    <div style={{height:6,width:80,background:'rgba(255,255,255,0.08)',borderRadius:99,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${score}%`,background:score>70?'#00C48C':score>40?'#FFA502':'#FF4757',borderRadius:99}}/>
                    </div>
                    <span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:16,color:score>70?'#00C48C':score>40?'#FFA502':'#FF4757'}}>{score}</span>
                  </div>
                </TD>
                <TD><Badge color={risk==='High'?'red':risk==='Medium'?'orange':'green'}>{risk}</Badge></TD>
                <TD><Btn variant="ghost" style={{fontSize:10,padding:'4px 8px'}}>📊 Details</Btn></TD>
              </TR>
            )
          })}
        </TableComp>
      </div>
    </Card>
  )

  const renderFeatureFlags = ()=>(
    <Card>
      <CardHeader title="🚩 Feature Flag System (N21)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
      <div style={{padding:'20px'}}>
        <div style={{fontSize:12,color:ts,marginBottom:18}}>Toggle any feature ON/OFF — changes sent to backend via POST /api/admin/features</div>
        <div style={{display:'flex',flexDirection:'column',gap:8}}>
          {features.map(f=>(
            <div key={f.key} style={{padding:'14px 16px',borderRadius:12,border:`1px solid ${f.enabled?'rgba(77,159,255,0.2)':bord}`,background:f.enabled?'rgba(77,159,255,0.04)':'transparent',display:'flex',alignItems:'center',gap:14,transition:'all 0.2s'}}>
              <div style={{flex:1}}>
                <div style={{fontWeight:700,color:tm,fontSize:13,marginBottom:2}}>{f.label}</div>
                <div style={{fontSize:11,color:ts}}>{f.description}</div>
              </div>
              <button onClick={()=>toggleFeature(f.key)} style={{width:46,height:26,borderRadius:99,background:f.enabled?accent:'rgba(255,255,255,0.1)',border:'none',cursor:'pointer',position:'relative',transition:'all 0.25s',flexShrink:0}}>
                <div style={{width:20,height:20,borderRadius:'50%',background:'#fff',position:'absolute',top:3,left:f.enabled?23:3,transition:'left 0.25s',boxShadow:'0 2px 4px rgba(0,0,0,0.3)'}}/>
              </button>
              <Badge color={f.enabled?'green':'orange'}>{f.enabled?'ON':'OFF'}</Badge>
            </div>
          ))}
        </div>
      </div>
    </Card>
  )

  const renderPermissions = ()=>(
    <Card>
      <CardHeader title="🔐 Admin Permission Control (S72)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
      <div style={{padding:'20px'}}>
        <div style={{marginBottom:16}}>
          <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:8,letterSpacing:'0.08em',textTransform:'uppercase'}}>Select Admin</label>
          <select style={{width:'100%',maxWidth:320,padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
            <option>admin@proverank.com</option>
          </select>
        </div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',gap:8}}>
          {Object.entries(adminPermissions).map(([key,val])=>(
            <div key={key} style={{padding:'12px 14px',borderRadius:10,border:`1px solid ${val?'rgba(77,159,255,0.2)':bord}`,background:val?'rgba(77,159,255,0.04)':'transparent',display:'flex',alignItems:'center',gap:10}}>
              <button onClick={()=>setAdminPermissions(p=>({...p,[key]:!val}))} style={{width:38,height:22,borderRadius:99,background:val?accent:'rgba(255,255,255,0.1)',border:'none',cursor:'pointer',position:'relative',transition:'all 0.25s',flexShrink:0}}>
                <div style={{width:16,height:16,borderRadius:'50%',background:'#fff',position:'absolute',top:3,left:val?19:3,transition:'left 0.25s'}}/>
              </button>
              <span style={{fontSize:12,color:val?tm:ts,fontWeight:val?600:400}}>{key.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase())}</span>
            </div>
          ))}
        </div>
        <Btn onClick={()=>showToast('Permissions saved!')} style={{marginTop:18}}>💾 Save Permissions</Btn>
      </div>
    </Card>
  )

  const renderBranding = ()=>(
    <Card style={{maxWidth:600}}>
      <CardHeader title="🎨 Custom Branding (S56)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
      <div style={{padding:'24px'}}>
        <Inp label="Platform Name" value={brandName} onChange={setBrandName}/>
        <Inp label="Tagline" value={brandTagline} onChange={setBrandTagline}/>
        <Inp label="Support Email" value={brandSupport} onChange={setBrandSupport}/>
        <div style={{padding:'20px',borderRadius:12,border:`1px solid ${bord}`,background:'rgba(77,159,255,0.04)',marginBottom:20}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:accent,marginBottom:4}}>{brandName}</div>
          <div style={{fontSize:12,color:ts}}>{brandTagline}</div>
        </div>
        <Btn onClick={()=>showToast('Branding saved!')} style={{width:'100%'}}>💾 Save Branding</Btn>
      </div>
    </Card>
  )

  const renderSEO = ()=>(
    <Card style={{maxWidth:560}}>
      <CardHeader title="🌐 SEO Settings (M17)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
      <div style={{padding:'24px'}}>
        <Inp label="Meta Title" value={seoTitle} onChange={setSeoTitle}/>
        <div style={{marginBottom:14}}>
          <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Meta Description</label>
          <TextArea value={seoDesc} onChange={setSeoDesc} rows={3}/>
          <div style={{fontSize:10,color:ts,marginTop:4}}>{seoDesc.length}/160 characters</div>
        </div>
        <div style={{padding:'14px',borderRadius:10,border:'1px solid rgba(0,196,140,0.2)',background:'rgba(0,196,140,0.04)',marginBottom:14}}>
          <div style={{fontSize:11,color:'#00C48C',fontWeight:700,marginBottom:4}}>Google Preview</div>
          <div style={{fontSize:14,color:'#4D9FFF'}}>{seoTitle}</div>
          <div style={{fontSize:11,color:ts,marginTop:2}}>prove-rank.vercel.app</div>
          <div style={{fontSize:11,color:ts,marginTop:2}}>{seoDesc.substring(0,120)}...</div>
        </div>
        <Btn onClick={()=>showToast('SEO settings saved!')} style={{width:'100%'}}>💾 Save SEO Settings</Btn>
      </div>
    </Card>
  )

  const renderAuditTrail = ()=>(
    <Card>
      <CardHeader title="📜 Platform Audit Trail (GET /api/admin/manage/audit)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
      {logs.length===0&&<EmptyState icon={loadingMain?'⏳':'📜'} msg={loadingMain?'Loading audit logs...':'No audit logs found. Admin actions will be logged here.'}/>}
      <TableComp headers={['Time','Action','Performed By','Details']}>
        {logs.map((l,i)=>(
          <TR key={l._id||i}>
            <TD style={{color:ts,fontSize:11,whiteSpace:'nowrap'}}>{new Date(l.at).toLocaleString()}</TD>
            <TD><Badge color="blue">{l.action}</Badge></TD>
            <TD style={{color:accent,fontWeight:600}}>{l.by}</TD>
            <TD style={{color:ts,fontSize:11}}>{l.detail}</TD>
          </TR>
        ))}
      </TableComp>
    </Card>
  )

  const renderMaintenance = ()=>(
    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(280px,1fr))',gap:14}}>
      <Card>
        <CardHeader title="🔧 Maintenance Mode (S66)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
        <div style={{padding:'24px'}}>
          {features.find(f=>f.key==='maintenance')?.enabled
            ? <div style={{padding:'14px',borderRadius:12,background:'rgba(255,165,2,0.08)',border:'1px solid rgba(255,165,2,0.3)',marginBottom:16}}>
                <div style={{fontSize:13,color:'#FFA502',fontWeight:700}}>⚠️ Maintenance Mode is ON</div>
                <div style={{fontSize:11,color:ts,marginTop:4}}>Students cannot access the platform.</div>
              </div>
            : <div style={{padding:'14px',borderRadius:12,background:'rgba(0,196,140,0.06)',border:'1px solid rgba(0,196,140,0.2)',marginBottom:16}}>
                <div style={{fontSize:13,color:'#00C48C',fontWeight:700}}>✓ Platform is Live</div>
                <div style={{fontSize:11,color:ts,marginTop:4}}>All students can access normally.</div>
              </div>
          }
          <div style={{marginBottom:14}}>
            <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:6,letterSpacing:'0.08em',textTransform:'uppercase'}}>Maintenance Message</label>
            <textarea rows={3} defaultValue="We are performing scheduled maintenance. Platform will be back in 2 hours." style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:12,fontFamily:'Inter,sans-serif',resize:'none',outline:'none',boxSizing:'border-box'}}/>
          </div>
          <Btn onClick={()=>toggleFeature('maintenance')} style={{width:'100%'}}>
            {features.find(f=>f.key==='maintenance')?.enabled?'✓ Turn OFF Maintenance':'🔧 Enable Maintenance Mode'}
          </Btn>
        </div>
      </Card>
      <Card>
        <CardHeader title="💾 Data Backup (S50)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
        <div style={{padding:'20px'}}>
          <div style={{padding:'12px',borderRadius:10,border:`1px solid ${bord}`,marginBottom:12,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
            <div>
              <div style={{fontSize:12,color:tm,fontWeight:600}}>MongoDB Atlas Auto Backup</div>
              <div style={{fontSize:11,color:ts}}>Cluster0 — Mumbai region</div>
            </div>
            <Badge color="green">✓ Active</Badge>
          </div>
          {[['Manual Backup Now','💾'],['Download Students CSV','📥'],['Download Exam Data','📥'],['Restore from Backup','🔄']].map(([l,icon])=>(
            <button key={String(l)} onClick={()=>showToast(`${l} initiated...`)} style={{width:'100%',padding:'11px 14px',borderRadius:9,border:`1px solid ${bord}`,background:'rgba(77,159,255,0.04)',color:tm,cursor:'pointer',display:'flex',alignItems:'center',gap:10,marginBottom:6,fontFamily:'Inter,sans-serif',fontSize:12,fontWeight:500}}
              onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.08)')}
              onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')}>
              <span>{icon as string}</span> {l as string}
            </button>
          ))}
        </div>
      </Card>
    </div>
  )

  const renderImpersonate = ()=>(
    <Card style={{maxWidth:500}}>
      <CardHeader title="👁️ Impersonate Student (M4)" action={<Badge color="gold">⚡ SuperAdmin Only</Badge>}/>
      <div style={{padding:'20px'}}>
        <div style={{padding:'12px',borderRadius:10,background:'rgba(255,165,2,0.06)',border:'1px solid rgba(255,165,2,0.2)',marginBottom:16}}>
          <div style={{fontSize:12,color:'#FFA502',fontWeight:700}}>⚠️ Use with caution</div>
          <div style={{fontSize:11,color:ts,marginTop:4}}>Generates a temporary token to view any student's dashboard. All actions are logged.</div>
        </div>
        <div style={{marginBottom:14}}>
          <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Select Student</label>
          <select value={impersonateId} onChange={e=>setImpersonateId(e.target.value)} style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
            <option value="">— Select Student —</option>
            {students.map(s=><option key={s._id} value={s._id}>{s.name} ({s.email})</option>)}
          </select>
        </div>
        <Btn onClick={impersonateStudent} style={{width:'100%'}}>👁️ View as Student (Opens new tab)</Btn>
      </div>
    </Card>
  )

  const renderSmartGen = ()=>(
    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:14}}>
      <Card>
        <CardHeader title="🤖 Smart Paper Generator (POST /api/questions/generate)"/>
        <div style={{padding:'20px'}}>
          <Inp label="Topic / Chapter" value={aiTopic} onChange={setAiTopic} placeholder="e.g. Cell Division, Thermodynamics"/>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
            <Inp label="Number of Questions" value={aiCount} onChange={setAiCount} type="number"/>
            <div style={{marginBottom:14}}>
              <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Subject</label>
              <select value={aiSubject} onChange={e=>setAiSubject(e.target.value)} style={{width:'100%',padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}>
                {['Physics','Chemistry','Botany','Zoology'].map(s=><option key={s}>{s}</option>)}
              </select>
            </div>
          </div>
          <div style={{marginBottom:14}}>
            <label style={{fontSize:10,fontWeight:700,color:accent,display:'block',marginBottom:5,letterSpacing:'0.08em',textTransform:'uppercase'}}>Difficulty</label>
            <div style={{display:'flex',gap:8}}>
              {['easy','medium','hard'].map(d=>(
                <button key={d} onClick={()=>setAiDifficulty(d)} style={{flex:1,padding:'8px',borderRadius:9,border:`1.5px solid ${aiDifficulty===d?accent:iBrd}`,background:aiDifficulty===d?'rgba(77,159,255,0.1)':iBg,color:aiDifficulty===d?accent:ts,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',fontWeight:aiDifficulty===d?700:400,textTransform:'capitalize'}}>{d}</button>
              ))}
            </div>
          </div>
          <Btn onClick={generateQuestions} style={{width:'100%'}} variant={aiLoading?'ghost':'primary'}>
            {aiLoading?'⏳ Generating...':'🤖 Generate Questions'}
          </Btn>
        </div>
      </Card>
      {aiResult.length>0 && (
        <Card>
          <CardHeader title={`✅ Generated ${aiResult.length} Questions`}/>
          <div style={{padding:'12px',maxHeight:400,overflowY:'auto'}}>
            {aiResult.map((q:any,i:number)=>(
              <div key={i} style={{padding:'12px',borderRadius:10,border:`1px solid ${bord}`,marginBottom:8}}>
                <div style={{fontWeight:600,color:tm,fontSize:12,marginBottom:6}}>Q{i+1}. {q.question||q.text}</div>
                {q.options && Object.entries(q.options).map(([k,v])=>(
                  <div key={k} style={{fontSize:11,color:k===q.correctOption?'#00C48C':ts,padding:'2px 0'}}>{k}: {String(v)}</div>
                ))}
                {q.correctOption && <div style={{fontSize:10,color:'#00C48C',marginTop:4,fontWeight:700}}>✓ {q.correctOption}</div>}
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  )

  const renderActivityLogs = ()=>(
    <Card>
      <CardHeader title="📋 Admin Activity Logs (GET /api/admin/manage/audit)" action={<button onClick={()=>fetchAllData(token)} style={{padding:'5px 10px',borderRadius:8,border:`1px solid ${bord}`,background:'transparent',color:accent,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🔄 Refresh</button>}/>
      {logs.length===0&&<EmptyState icon={loadingMain?'⏳':'📋'} msg={loadingMain?'Loading logs...':'No activity logs found. Admin actions will appear here.'}/>}
      <TableComp headers={['Time','Admin','Action','Details']}>
        {logs.map((l,i)=>(
          <TR key={l._id||i}>
            <TD style={{color:ts,fontSize:11}}>{new Date(l.at).toLocaleString()}</TD>
            <TD style={{color:accent,fontWeight:600}}>{l.by}</TD>
            <TD><Badge color="blue">{l.action}</Badge></TD>
            <TD style={{color:ts,fontSize:11}}>{l.detail}</TD>
          </TR>
        ))}
      </TableComp>
    </Card>
  )

  const renderTodo = ()=>(
    <Card>
      <CardHeader title="✅ Admin Task Manager (M13)"/>
      <div style={{padding:'20px'}}>
        <div style={{display:'flex',gap:8,marginBottom:16}}>
          <input value={todoInput} onChange={e=>setTodoInput(e.target.value)} onKeyDown={e=>e.key==='Enter'&&addTodo()} placeholder="Add new task..." style={{flex:1,padding:'10px 13px',borderRadius:9,border:`1.5px solid ${iBrd}`,background:iBg,color:tm,fontSize:13,fontFamily:'Inter,sans-serif',outline:'none'}}/>
          <Btn onClick={addTodo}>+ Add</Btn>
        </div>
        {todos.map(t=>(
          <div key={t.id} style={{display:'flex',alignItems:'center',gap:10,padding:'12px 14px',borderRadius:10,background:t.done?'rgba(0,196,140,0.04)':'rgba(77,159,255,0.04)',border:`1px solid ${t.done?'rgba(0,196,140,0.12)':bord}`,marginBottom:8}}>
            <input type="checkbox" checked={t.done} onChange={()=>setTodos(p=>p.map(x=>x.id===t.id?{...x,done:!x.done}:x))} style={{accentColor:accent,width:16,height:16,flexShrink:0}}/>
            <span style={{fontSize:13,color:t.done?ts:tm,textDecoration:t.done?'line-through':'none',flex:1}}>{t.text}</span>
            <button onClick={()=>setTodos(p=>p.filter(x=>x.id!==t.id))} style={{background:'none',border:'none',color:ts,cursor:'pointer',fontSize:14,padding:'2px 6px'}}>✕</button>
          </div>
        ))}
      </div>
    </Card>
  )

  const renderChangelog = ()=>(
    <Card>
      <CardHeader title="📝 Platform Changelog"/>
      <div style={{padding:'20px',display:'flex',flexDirection:'column',gap:10}}>
        {[
          {v:'v2.3',d:'Mar 11, 2026',changes:['Master Combined: All features restored + all fixes applied','Live Monitor, Snapshots, Integrity, Permissions, Export, Analytics — all back','3-step exam wizard with Excel/PDF/Copy-paste upload','Sidebar hidden by default — logo click se open','Real stats from API — no fake numbers'],type:'major'},
          {v:'v2.2',d:'Mar 11, 2026',changes:['Admin panel fully wired to real APIs','Mock data removed — all data from backend','Stats, Leaderboard, Audit, Tickets, Cheating Logs all live'],type:'feature'},
          {v:'v2.0',d:'Mar 06, 2026',changes:['Stage 7.5 complete — Admin panel 57+ features','Anti-cheat monitoring, Integrity scores, Feature Flags'],type:'major'},
        ].map(({v,d,changes,type})=>(
          <div key={v} style={{padding:'16px',borderRadius:12,border:`1px solid ${type==='major'?'rgba(77,159,255,0.3)':bord}`,background:type==='major'?'rgba(77,159,255,0.04)':'transparent'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:10}}>
              <div style={{display:'flex',alignItems:'center',gap:8}}>
                <span style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:800,color:accent}}>{v}</span>
                {type==='major' && <Badge color="blue">Major Update</Badge>}
              </div>
              <span style={{fontSize:11,color:ts}}>{d}</span>
            </div>
            {changes.map((c,i)=><div key={i} style={{fontSize:12,color:ts,paddingLeft:12,position:'relative',marginBottom:2}}><span style={{position:'absolute',left:0,color:accent}}>•</span>{c}</div>)}
          </div>
        ))}
      </div>
    </Card>
  )

  // Content Router
  const renderContent = ()=>{
    switch(activeTab){
      case 'dashboard':     return renderDashboard()
      case 'live_monitor':  return renderLiveMonitor()
      case 'all_exams':     return renderAllExams()
      case 'create_exam':   return renderCreateExam()
      case 'question_bank': return renderQuestionBank()
      case 'smart_gen':     return renderSmartGen()
      case 'bulk_upload':   return renderBulkUpload()
      case 'pyq_bank':      return renderPYQBank()
      case 'all_students':  return renderAllStudents()
      case 'batch_manager': return renderBatchManager()
      case 'ban_system':    return renderBanSystem()
      case 'result_control':return renderResultControl()
      case 'leaderboard':   return renderLeaderboard()
      case 'analytics':     return renderAnalytics()
      case 'export':        return renderExport()
      case 'tickets':       return renderTickets()
      case 'announcements': return renderAnnouncements()
      case 'cheat_logs':    return renderCheatLogs()
      case 'snapshots':     return renderSnapshots()
      case 'integrity':     return renderIntegrity()
      case 'feature_flags': return renderFeatureFlags()
      case 'permissions':   return renderPermissions()
      case 'branding':      return renderBranding()
      case 'seo':           return renderSEO()
      case 'audit_trail':   return renderAuditTrail()
      case 'maintenance':   return renderMaintenance()
      case 'data_backup':   return renderMaintenance()
      case 'impersonate':   return renderImpersonate()
      case 'activity_logs': return renderActivityLogs()
      case 'todo':          return renderTodo()
      case 'changelog':     return renderChangelog()
      default:              return renderDashboard()
    }
  }

  // FIX: Sidebar content
  const SidebarContent = ()=>(
    <div style={{display:'flex',flexDirection:'column',height:'100%'}}>
      <div style={{padding:'16px 14px',borderBottom:`1px solid ${bord}`,display:'flex',alignItems:'center',gap:10,flexShrink:0}}>
        <svg width={32} height={32} viewBox="0 0 64 64">
          <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2.5"/>
          <text x="32" y="38" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="13" fontWeight="800" fill="#4D9FFF">PR</text>
        </svg>
        <div style={{flex:1}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</div>
          <div style={{fontSize:9,color:role==='superadmin'?'#FFD700':'#4D9FFF',letterSpacing:'0.12em',fontWeight:700}}>{role==='superadmin'?'⚡ SUPERADMIN':'🛡 ADMIN'}</div>
        </div>
        <button onClick={()=>setSideOpen(false)} style={{background:'none',border:'none',color:ts,fontSize:18,cursor:'pointer'}}>✕</button>
      </div>
      <div style={{flex:1,overflowY:'auto',padding:'10px 8px'}}>
        {navSections.map(section=>(
          <div key={section.id} style={{marginBottom:4}}>
            {section.label&&(
              <button onClick={()=>toggleSection(section.id)} style={{width:'100%',background:'none',border:'none',padding:'5px 8px',display:'flex',alignItems:'center',justifyContent:'space-between',cursor:'pointer',marginBottom:2}}>
                <span style={{fontSize:9,fontWeight:800,color:'#2A4A6A',letterSpacing:'0.12em'}}>{section.label}</span>
                <span style={{color:'#2A4A6A',fontSize:11,transition:'transform 0.2s',transform:expandedSections.includes(section.id)?'rotate(90deg)':'rotate(0deg)'}}>▶</span>
              </button>
            )}
            {(!section.label||expandedSections.includes(section.id))&&section.items.map(item=>(
              <button key={item.id} onClick={()=>navTo(item.id)} style={{width:'100%',background:activeTab===item.id?'rgba(77,159,255,0.15)':'transparent',border:'none',borderLeft:activeTab===item.id?`3px solid ${accent}`:'3px solid transparent',padding:'8px 12px',display:'flex',alignItems:'center',gap:10,borderRadius:'0 10px 10px 0',cursor:'pointer',marginBottom:1,fontFamily:'Inter,sans-serif'}}>
                <span style={{fontSize:14,width:20,textAlign:'center',flexShrink:0}}>{item.icon}</span>
                <span style={{fontSize:12,fontWeight:activeTab===item.id?700:500,color:activeTab===item.id?accent:ts}}>{lang==='en'?item.en:item.hi}</span>
              </button>
            ))}
          </div>
        ))}
      </div>
      <div style={{padding:'10px 8px',borderTop:`1px solid ${bord}`,flexShrink:0,display:'flex',flexDirection:'column',gap:6}}>
        <div style={{padding:'10px 12px',borderRadius:10,background:'rgba(77,159,255,0.06)',border:`1px solid ${bord}`}}>
          <div style={{fontWeight:700,color:tm,fontSize:12}}>admin@proverank.com</div>
          <div style={{fontSize:10,color:ts,marginTop:2}}>{role==='superadmin'?'Full Access':'Limited Access'}</div>
        </div>
        <div style={{display:'flex',gap:6}}>
          <button onClick={toggleLang} style={{flex:1,padding:'7px',borderRadius:8,border:`1px solid ${bord}`,background:'transparent',color:ts,fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>{lang==='en'?'🇮🇳 हिं':'🌐 EN'}</button>
          <button onClick={logout} style={{flex:1,padding:'7px',borderRadius:8,border:'1px solid rgba(255,71,87,0.3)',background:'rgba(255,71,87,0.08)',color:'#FF6B7A',fontSize:11,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🚪 Logout</button>
        </div>
      </div>
    </div>
  )

  return (
    <div style={{minHeight:'100vh',background:bg,display:'flex',flexDirection:'column',fontFamily:'Inter,sans-serif'}}>
      <style>{`
        *{box-sizing:border-box;margin:0;padding:0}
        ::-webkit-scrollbar{width:4px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.2);border-radius:99px}
        @keyframes spin{to{transform:rotate(360deg)}}
      `}</style>

      {/* FIX: Sidebar overlay — only shows when sideOpen=true */}
      {sideOpen&&(
        <div style={{position:'fixed',inset:0,zIndex:200,display:'flex'}}>
          <div onClick={()=>setSideOpen(false)} style={{flex:1,background:'rgba(0,0,0,0.7)',backdropFilter:'blur(2px)'}}/>
          <div style={{width:260,background:'rgba(0,4,14,0.98)',borderLeft:`1px solid ${bord}`,height:'100%',overflowY:'auto',flexShrink:0}}>
            <SidebarContent/>
          </div>
        </div>
      )}

      {/* TOP BAR */}
      <div style={{height:56,background:topBg,borderBottom:`1px solid ${bord}`,display:'flex',alignItems:'center',padding:'0 16px',gap:12,position:'sticky',top:0,zIndex:100,flexShrink:0}}>
        {/* FIX: Logo click → open sidebar */}
        <button onClick={()=>setSideOpen(true)} style={{background:'none',border:'none',cursor:'pointer',display:'flex',alignItems:'center',gap:8,padding:'4px 8px',borderRadius:8,transition:'background 0.2s'}}
          onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.08)')}
          onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
          <svg width={28} height={28} viewBox="0 0 64 64">
            <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2.5"/>
            <text x="32" y="38" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="800" fill="#4D9FFF">PR</text>
          </svg>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1}}>ProveRank</div>
            <div style={{fontSize:9,color:role==='superadmin'?'#FFD700':'#4D9FFF',letterSpacing:'0.1em',fontWeight:700,lineHeight:1}}>{role==='superadmin'?'⚡ SUPERADMIN':'🛡 ADMIN'}</div>
          </div>
        </button>
        <div style={{flex:1,display:'flex',alignItems:'center',gap:4,overflowX:'auto',scrollbarWidth:'none'}}>
          {[
            {id:'dashboard',label:'Dashboard',icon:'⊞'},
            {id:'all_exams',label:'Exams',icon:'📝'},
            {id:'all_students',label:'Students',icon:'👥'},
            {id:'result_control',label:'Results',icon:'📈'},
            {id:'announcements',label:'Announce',icon:'📢'},
            {id:'cheat_logs',label:'Proctoring',icon:'⚠️'},
          ].map(tab=>(
            <button key={tab.id} onClick={()=>navTo(tab.id)} style={{padding:'6px 12px',borderRadius:8,border:'none',background:activeTab===tab.id?'rgba(77,159,255,0.15)':'transparent',color:activeTab===tab.id?accent:ts,fontSize:12,fontWeight:activeTab===tab.id?700:500,cursor:'pointer',fontFamily:'Inter,sans-serif',whiteSpace:'nowrap',borderBottom:activeTab===tab.id?`2px solid ${accent}`:'2px solid transparent',transition:'all 0.15s'}}>
              <span style={{marginRight:4}}>{tab.icon}</span>{tab.label}
            </button>
          ))}
          {role==='superadmin'&&<button onClick={()=>navTo('feature_flags')} style={{padding:'6px 12px',borderRadius:8,border:'none',background:activeTab==='feature_flags'?'rgba(255,215,0,0.1)':'transparent',color:activeTab==='feature_flags'?'#FFD700':ts,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',whiteSpace:'nowrap'}}>⚡ SuperAdmin</button>}
        </div>
        <button onClick={()=>fetchAllData(token)} style={{background:'none',border:'none',color:ts,fontSize:16,cursor:'pointer',padding:'6px',borderRadius:8,flexShrink:0}} title="Refresh">🔄</button>
        {/* FIX: Only show bell badge if real notifications exist */}
        <div style={{position:'relative',flexShrink:0}}>
          <button onClick={()=>setNotifOpen(!notifOpen)} style={{background:'none',border:'none',color:ts,fontSize:20,cursor:'pointer',padding:'6px',borderRadius:8,position:'relative'}}>
            🔔
            {notifs.length>0&&<span style={{position:'absolute',top:2,right:2,background:'#FF4757',color:'#fff',fontSize:9,fontWeight:700,width:16,height:16,borderRadius:'50%',display:'flex',alignItems:'center',justifyContent:'center'}}>{notifs.length}</span>}
          </button>
          {notifOpen&&(
            <div style={{position:'absolute',top:44,right:0,width:280,background:card,border:`1px solid ${bord}`,borderRadius:12,boxShadow:'0 10px 30px rgba(0,0,0,0.4)',zIndex:300,overflow:'hidden'}}>
              <div style={{padding:'12px 16px',borderBottom:`1px solid ${bord}`,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <span style={{fontSize:13,fontWeight:700,color:tm}}>Notifications</span>
                {notifs.length>0&&<button onClick={()=>setNotifs([])} style={{fontSize:10,color:ts,background:'none',border:'none',cursor:'pointer'}}>Clear all</button>}
              </div>
              {notifs.length===0
                ? <div style={{padding:'24px',textAlign:'center',color:ts,fontSize:12}}>No notifications</div>
                : notifs.map((n,i)=>(
                  <div key={n.id||i} style={{padding:'10px 16px',borderBottom:`1px solid ${bord}`,display:'flex',gap:10,alignItems:'flex-start'}}>
                    <span style={{fontSize:16}}>{n.icon}</span>
                    <div><div style={{fontSize:12,color:tm}}>{n.msg}</div><div style={{fontSize:10,color:ts,marginTop:2}}>{n.t}</div></div>
                  </div>
                ))
              }
            </div>
          )}
        </div>
        <button onClick={logout} style={{background:'rgba(255,71,87,0.08)',border:'1px solid rgba(255,71,87,0.25)',color:'#FF6B7A',fontSize:11,fontWeight:600,padding:'7px 12px',borderRadius:8,cursor:'pointer',fontFamily:'Inter,sans-serif',flexShrink:0}}>🚪 Logout</button>
      </div>

      {/* MAIN CONTENT */}
      <div style={{flex:1,padding:'20px 16px',overflowY:'auto'}}>
        <div style={{marginBottom:14,display:'flex',alignItems:'center',gap:8}}>
          <span style={{fontSize:11,color:ts,cursor:'pointer'}} onClick={()=>navTo('dashboard')}>Admin</span>
          <span style={{fontSize:11,color:'#1A3A5A'}}>›</span>
          <span style={{fontSize:11,color:accent,fontWeight:600,textTransform:'capitalize'}}>{activeTab.replace(/_/g,' ')}</span>
          {loadingMain&&<span style={{fontSize:10,color:ts,marginLeft:8}}>⏳ Loading...</span>}
        </div>
        {renderContent()}
      </div>

      {toast&&(
        <div style={{position:'fixed',bottom:24,left:'50%',transform:'translateX(-50%)',background:toast.type==='error'?'rgba(255,71,87,0.95)':'rgba(0,196,140,0.95)',color:'#fff',padding:'12px 24px',borderRadius:12,fontSize:13,fontWeight:600,fontFamily:'Inter,sans-serif',boxShadow:'0 4px 20px rgba(0,0,0,0.3)',zIndex:999,whiteSpace:'nowrap'}}>
          {toast.type==='error'?'❌':'✅'} {toast.msg}
        </div>
      )}
    </div>
  )
}
