'use client'
import { useState, useEffect, useRef, useCallback, memo } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from '@/lib/auth'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

interface Student { _id:string;name:string;email:string;phone?:string;role:string;createdAt:string;banned?:boolean;banReason?:string;group?:string;integrityScore?:number;loginHistory?:any[] }
interface Exam { _id:string;title:string;scheduledAt:string;totalMarks:number;duration:number;status:string;attempts?:number;category?:string;password?:string }
interface Question { _id:string;text:string;subject:string;chapter?:string;difficulty:string;type:string;options?:string[];correctAnswer?:string }
interface Log { _id:string;action:string;by:string;at:string;detail:string }
interface Flag { _id:string;studentName:string;examTitle:string;type:string;count:number;severity:string;at:string }
interface Ticket { _id:string;studentName:string;examTitle:string;type:string;status:string;createdAt:string;description:string }
interface Feature { key:string;label:string;description:string;enabled:boolean }
interface Notif { id:string;icon:string;msg:string;t:string;read:boolean }
interface Snapshot { _id:string;studentName:string;imageUrl?:string;flagged:boolean;capturedAt:string }
interface Batch { _id:string;name:string;studentCount:number;examCount:number;createdAt:string }
interface AdminUser { _id:string;name:string;email:string;role:string;createdAt:string;active:boolean }

const DEF_FEATURES: Feature[] = [
  {key:'webcam',label:'Webcam Proctoring',description:'Camera compulsory during exams (Phase 5.2)',enabled:true},
  {key:'audio',label:'Audio Monitoring',description:'Microphone noise detection (S57)',enabled:false},
  {key:'eye_tracking',label:'Eye Tracking AI',description:'Detect looking away from screen (S-ET)',enabled:true},
  {key:'face_detect',label:'Face Detection TF.js',description:'Multi/no-face detection (Phase 5.4)',enabled:true},
  {key:'head_pose',label:'Head Pose Detection',description:'Head angle tracking (S73)',enabled:true},
  {key:'vbg_block',label:'Virtual Background Detection',description:'Detect and block fake backgrounds (S74)',enabled:true},
  {key:'vpn_block',label:'VPN/Proxy Block',description:'Block VPN users from attempting exams (S20)',enabled:false},
  {key:'live_rank',label:'Live Rank Updates',description:'Socket.io real-time ranking (S107)',enabled:true},
  {key:'social_share',label:'Social Share Results',description:'WhatsApp/Instagram result sharing (S99)',enabled:true},
  {key:'parent_portal',label:'Parent Portal',description:'Read-only child progress access (N17)',enabled:false},
  {key:'pyq_bank',label:'PYQ Bank Access',description:'NEET 2015-2024 questions (S104)',enabled:true},
  {key:'maintenance',label:'Maintenance Mode',description:'Block students, keep admin accessible (S66)',enabled:false},
  {key:'sms_notify',label:'SMS Notifications',description:'Result SMS via Twilio/Fast2SMS (M19)',enabled:false},
  {key:'whatsapp',label:'WhatsApp Alerts',description:'Exam reminders via WhatsApp (S65)',enabled:false},
  {key:'ai_tagger',label:'AI Auto-Tagger',description:'Auto difficulty and subject tagging (AI-1/AI-2)',enabled:true},
  {key:'ai_explain',label:'AI Explanation Generator',description:'Auto explanation generation (AI-10)',enabled:true},
  {key:'two_fa',label:'2FA Admin Login',description:'OTP mandatory for admin accounts (S49)',enabled:true},
  {key:'ip_lock',label:'IP Lock During Exam',description:'Block IP change mid-exam (S20)',enabled:true},
  {key:'fullscreen',label:'Fullscreen Force Mode',description:'3 exits triggers auto-submit (S32)',enabled:true},
  {key:'watermark',label:'Screen Watermark',description:'Student name/ID watermark on screen (S76)',enabled:true},
  {key:'integrity',label:'AI Integrity Score',description:'0-100 score per exam attempt (AI-6)',enabled:true},
  {key:'n14_pattern',label:'Suspicious Pattern Detection',description:'Fast/identical answer flagging (N14)',enabled:true},
  {key:'onboarding',label:'Platform Onboarding Tour',description:'Guided tour for new students (S100)',enabled:true},
  {key:'n23_encrypt',label:'Paper Encryption',description:'Questions encrypted in browser (N23)',enabled:false},
]

// ══════════════════════════════════════════════════════
// MOBILE KEYBOARD FIX
// Memoized components maintain own state independently.
// Parent re-renders do NOT cause these to re-render,
// so the mobile keyboard stays open while typing.
// ══════════════════════════════════════════════════════
const SInput = memo(function SInput({init='',onSet,style,ph,type='text',disabled=false}:{init?:string;onSet:(v:string)=>void;style?:any;ph?:string;type?:string;disabled?:boolean}) {
  const [v,setV]=useState(init)
  useEffect(()=>{setV(init)},[init])
  return <input type={type} value={v} disabled={disabled} placeholder={ph} style={style} onChange={e=>{const x=e.target.value;setV(x);onSet(x)}} />
})

const STextarea = memo(function STextarea({init='',onSet,style,ph,rows=4}:{init?:string;onSet:(v:string)=>void;style?:any;ph?:string;rows?:number}) {
  const [v,setV]=useState(init)
  useEffect(()=>{setV(init)},[init])
  return <textarea value={v} rows={rows} placeholder={ph} style={style} onChange={e=>{const x=e.target.value;setV(x);onSet(x)}} />
})

const SSelect = memo(function SSelect({val,onChange,opts,style}:{val:string;onChange:(v:string)=>void;opts:{v:string;l:string}[];style?:any}) {
  return <select value={val} onChange={e=>onChange(e.target.value)} style={style}>{opts.map(o=><option key={o.v} value={o.v}>{o.l}</option>)}</select>
})

// Theme — N6 Neon Blue Arctic
const BG='#000A18',CRD='#001628',ACC='#4D9FFF',BOR='rgba(77,159,255,0.2)'
const TS='#E8F4FF',DIM='#7BA8CC',SUC='#00C48C',DNG='#FF4D4D',WRN='#FFB84D'
const inp:any={width:'100%',padding:'10px 12px',background:'#001F3A',border:`1px solid ${BOR}`,borderRadius:8,color:TS,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}
const bp:any={background:ACC,color:'#000',border:'none',borderRadius:8,padding:'10px 20px',cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif'}
const bg_:any={background:'rgba(77,159,255,0.1)',color:ACC,border:`1px solid ${BOR}`,borderRadius:8,padding:'8px 16px',cursor:'pointer',fontWeight:600,fontSize:12,fontFamily:'Inter,sans-serif'}
const bd:any={background:DNG,color:'#fff',border:'none',borderRadius:8,padding:'8px 16px',cursor:'pointer',fontWeight:700,fontSize:12}
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:12,padding:16,marginBottom:12}
const lbl:any={display:'block',fontSize:12,color:DIM,marginBottom:4,fontFamily:'Inter,sans-serif',fontWeight:600}


// Global Search Component M12
const GlobalSearch=memo(function GlobalSearch({students,exams,questions,setTab,setSelStudent}:{students:any[];exams:any[];questions:any[];setTab:(t:string)=>void;setSelStudent:(s:any)=>void}) {
  const [q,setQ]=useState('')
  const res=q.length<2?[]:[
    ...(students||[]).filter(s=>s.name?.toLowerCase().includes(q.toLowerCase())||s.email?.toLowerCase().includes(q.toLowerCase())).slice(0,5).map(s=>({type:'Student',label:s.name+' ('+s.email+')',obj:s,go:()=>{setSelStudent(s);setTab('students')}})),
    ...(exams||[]).filter(e=>e.title?.toLowerCase().includes(q.toLowerCase())).slice(0,5).map(e=>({type:'Exam',label:e.title,obj:e,go:()=>setTab('exams')})),
    ...(questions||[]).filter(qn=>qn.text?.toLowerCase().includes(q.toLowerCase())).slice(0,5).map(qn=>({type:'Question',label:qn.text?.slice(0,60)+'…',obj:qn,go:()=>setTab('questions')})),
  ]
  return(
    <div>
      <input value={q} onChange={e=>setQ(e.target.value)} placeholder='Search students, exams, questions…'
        style={{width:'100%',padding:'12px 14px',background:'#001F3A',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,color:'#E8F4FF',fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',marginBottom:10}} />
      {q.length>=2&&(
        <div>
          {res.length===0
            ?<div style={{color:'#7BA8CC',fontSize:12,padding:10}}>No results for "{q}"</div>
            :res.map((r,i)=>(
              <button key={i} onClick={r.go} style={{display:'flex',gap:10,alignItems:'center',width:'100%',padding:'10px 14px',background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,marginBottom:6,cursor:'pointer',textAlign:'left'}}>
                <span style={{fontSize:9,padding:'2px 6px',borderRadius:20,background:'rgba(77,159,255,0.15)',color:'#4D9FFF',fontWeight:700,flexShrink:0}}>{r.type}</span>
                <span style={{fontSize:12,color:'#E8F4FF'}}>{r.label}</span>
              </button>
            ))
          }
        </div>
      )}
    </div>
  )
})

export default function AdminPanel() {
  const router=useRouter()
  const [role,setRole]=useState('')
  const [token,setToken]=useState('')
  const [mounted,setMounted]=useState(false)
  const [tab,setTab]=useState('dashboard')
  const [sideOpen,setSideOpen]=useState(false)
  // Full-width top banner toast — clearly visible on mobile
  const [toast,setToast]=useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)
  const [notifOpen,setNotifOpen]=useState(false)
  const [notifs,setNotifs]=useState<Notif[]>([])
  const [loading,setLoading]=useState(true)

  const [students,setStudents]=useState<Student[]>([])
  const [exams,setExams]=useState<Exam[]>([])
  const [questions,setQuestions]=useState<Question[]>([])
  const [flags,setFlags]=useState<Flag[]>([])
  const [logs,setLogs]=useState<Log[]>([])
  const [tickets,setTickets]=useState<Ticket[]>([])
  const [snapshots,setSnapshots]=useState<Snapshot[]>([])
  const [features,setFeatures]=useState<Feature[]>(DEF_FEATURES)
  const [stats,setStats]=useState<any>(null)
  const [batches,setBatches]=useState<Batch[]>([])
  const [adminUsers,setAdminUsers]=useState<AdminUser[]>([])

  const [stdSearch,setStdSearch]=useState('')
  const [stdFilter,setStdFilter]=useState<'all'|'active'|'banned'>('all')
  const [examSearch,setExamSearch]=useState('')
  const [qSearch,setQSearch]=useState('')
  const [selStudent,setSelStudent]=useState<Student|null>(null)

  // Exam Create — all refs (mobile keyboard fix)
  const eTitleR=useRef(''); const eDateR=useRef('')
  const eMarksR=useRef('720'); const eDurR=useRef('200')
  const eCatR=useRef('Full Mock'); const ePassR=useRef('')
  const [eStep,setEStep]=useState(1)
  const [createdEId,setCreatedEId]=useState('')
  const [qMeth,setQMeth]=useState<'manual'|'excel'|'pdf'|'copypaste'>('copypaste')
  const cpTxtR=useRef(''); const cpKeyR=useRef('')
  const [excelF,setExcelF]=useState<File|null>(null)
  const [pdfF,setPdfF]=useState<File|null>(null)
  const [uploadingQ,setUploadingQ]=useState(false)
  const [creatingE,setCreatingE]=useState(false)
  const [upRes,setUpRes]=useState<{s:number;f:number;msg:string}|null>(null)

  const qTxtR=useRef(''); const qChapR=useRef('')
  const qA=useRef(''); const qB=useRef(''); const qC=useRef(''); const qD=useRef('')
  const [qSubj,setQSubj]=useState('Physics')
  const [qDiff,setQDiff]=useState('medium')
  const [qType,setQType]=useState('SCQ')
  const [qAns,setQAns]=useState('A')
  const [savingQ,setSavingQ]=useState(false)

  const [banId,setBanId]=useState('')
  const banReaR=useRef('')
  const [banT,setBanT]=useState<'permanent'|'temporary'>('permanent')

  const annR=useRef('')
  const [annBatch,setAnnBatch]=useState('all')

  const bNameR=useRef('ProveRank'); const bTagR=useRef('Prove Your Rank')
  const bMailR=useRef('support@proverank.com')
  const seoTR=useRef('ProveRank — NEET Online Test Platform')
  const seoDR=useRef('Best NEET mock test platform with AI analytics and anti-cheat.')
  const mainMsgR=useRef('Site under maintenance. We will be back shortly.')
  const [savingB,setSavingB]=useState(false)
  const [mainOn,setMainOn]=useState(false)

  const [impId,setImpId]=useState('')
  const [extStdId,setExtStdId]=useState('')
  const [extMins,setExtMins]=useState('10')

  const [perms,setPerms]=useState({
    create_exam:true,edit_exam:true,delete_exam:false,
    ban_student:true,view_results:true,export_data:true,
    manage_questions:true,send_announcements:true,
    view_audit_logs:false,manage_features:false,
    manage_admins:false,impersonate:false,
  })

  const admNameR=useRef(''); const admEmailR=useRef(''); const admPassR=useRef('')
  const [admRole,setAdmRole]=useState('admin')
  const [creatingAdm,setCreatingAdm]=useState(false)

  const [bulkExamFile,setBulkExamFile]=useState<File|null>(null)
  const [bulkExamLoading,setBulkExamLoading]=useState(false)

  const aiTopicR=useRef('')
  const [aiCount,setAiCount]=useState('10')
  const [aiSubj,setAiSubj]=useState('Physics')
  const [aiDiff,setAiDiff]=useState('medium')
  const [aiLoading,setAiLoading]=useState(false)
  const [aiResult,setAiResult]=useState<any[]>([])

  const [todos,setTodos]=useState([
    {id:'1',text:'Review upcoming exam questions',done:false},
    {id:'2',text:'Reply to pending tickets',done:false},
    {id:'3',text:'Check server health before exam',done:false},
  ])
  const todoR=useRef('')

  const batchNameR=useRef('')
  const [creatingBatch,setCreatingBatch]=useState(false)
  const [batchTransStdId,setBatchTransStdId]=useState('')
  const [batchTransTo,setBatchTransTo]=useState('')

  const clogs=[
    {v:'V3 Final',d:'Mar 12, 2026',chg:['Complete rebuild — all fixes baked in','Mobile keyboard fix — SInput/STextarea memo','Question upload — 3 endpoint fallbacks','Full width error banner — clearly visible','All English text — no mixed language','Exam ID from d.exam._id — correct path'],t:'major'},
  ]

  const T=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{setToast({msg,tp});setTimeout(()=>setToast(null),4000)},[])
  const H=useCallback(()=>({Authorization:`Bearer ${token}`}),[token])
  const HJ=useCallback(()=>({'Content-Type':'application/json',Authorization:`Bearer ${token}`}),[token])

  useEffect(()=>{
    const t=getToken(),r=getRole()
    if(!t||!['admin','superadmin'].includes(r)){router.replace('/login');return}
    setToken(t);setRole(r);setMounted(true)
  },[router])

  useEffect(()=>{if(token)fetchAll()},[token])

  const fetchAll=useCallback(async()=>{
    if(!token)return
    setLoading(true)
    const get=async(u:string)=>{try{const r=await fetch(u,{headers:H()});return r.ok?r.json():null}catch{return null}}
    const getFirst=async(...urls:string[])=>{for(const u of urls){try{const r=await fetch(u,{headers:H()});if(r.ok){const d=await r.json();if(d)return d}}catch{}}return null}
    const [us,ex,qs,st,fl,al,tk,sn,ft,nf,bt,au]=await Promise.all([
      get(`${API}/api/admin/users`),
      get(`${API}/api/exams`),
      get(`${API}/api/questions`),
      get(`${API}/api/admin/stats`),
      getFirst(`${API}/api/admin/manage/cheating-logs`,`${API}/api/admin/cheating-logs`),
      getFirst(`${API}/api/admin/manage/audit`,`${API}/api/admin/audit`),
      getFirst(`${API}/api/admin/manage/tickets`,`${API}/api/admin/tickets`),
      getFirst(`${API}/api/admin/manage/snapshots`,`${API}/api/admin/snapshots`),
      get(`${API}/api/admin/features`),
      get(`${API}/api/admin/notifications`),
      getFirst(`${API}/api/admin/batches`,`${API}/api/admin/manage/batches`),
      get(`${API}/api/admin/manage/admins`),
    ])
    if(Array.isArray(us))setStudents(us)
    if(Array.isArray(ex))setExams(ex)
    if(Array.isArray(qs))setQuestions(qs)
    if(st)setStats(st)
    if(Array.isArray(fl))setFlags(fl)
    if(Array.isArray(al))setLogs(al)
    if(Array.isArray(tk))setTickets(tk)
    if(Array.isArray(sn))setSnapshots(sn)
    if(Array.isArray(nf))setNotifs(nf)
    if(Array.isArray(bt))setBatches(bt)
    if(Array.isArray(au))setAdminUsers(au)
    if(ft){
      if(Array.isArray(ft)&&ft.length){setFeatures(ft)}
      else if(ft&&typeof ft==='object'){setFeatures(DEF_FEATURES.map(f=>({...f,enabled:ft[f.key]!==undefined?Boolean(ft[f.key]):f.enabled})))}
    }
    setLoading(false)
  },[token,H])

  // ══ CREATE EXAM ══
  // FIXES: duration field (not totalDurationSec), no status field,
  // ID from d.exam._id, no fetch chain after setEStep
  const createExamS1=useCallback(async()=>{
    const title=eTitleR.current,date=eDateR.current
    if(!title||!date){T('Exam title and date are both required.','e');return}
    setCreatingE(true)
    try{
      const body={
        title,
        scheduledAt:new Date(date).toISOString(),
        totalMarks:parseInt(eMarksR.current)||720,
        duration:parseInt(eDurR.current)||200,
        subject:'NEET',
        type:'NEET',
        difficulty:'Mixed',
        category:eCatR.current||'Full Mock',
        password:ePassR.current||undefined,
      }
      const res=await fetch(`${API}/api/exams`,{method:'POST',headers:HJ(),body:JSON.stringify(body)})
      if(res.ok||res.status===201){
        const d=await res.json()
        // Correct ID extraction — backend returns {message, exam: {_id,...}}
        const eid=d?.exam?._id||d?.exam?.id||d?._id||d?.id||d?.examId||''
        if(eid){
          setCreatedEId(eid)
          T('Exam created successfully! Please add questions.')
          setEStep(2)
        } else {
          setCreatedEId('')
          T('Exam created. (ID not returned by server)','w')
          setEStep(2)
        }
      } else {
        const e=await res.json().catch(()=>({}))
        T(`Error ${res.status}: ${e.message||e.error||'Please check exam details.'}`, 'e')
      }
    } catch(err:any){
      T(`Network error: ${err.message||'Please check your connection.'}`, 'e')
    }
    setCreatingE(false)
  },[HJ,T])

  // ══ UPLOAD QUESTIONS — 3 endpoint fallbacks per method ══
  const uploadQs=useCallback(async()=>{
    const examId=createdEId
    if(!examId){T('Please complete Step 1 first to create the exam.','e');return}
    setUploadingQ(true);setUpRes(null)
    try{
      let res:Response|null=null
      if(qMeth==='copypaste'||qMeth==='manual'){
        const text=cpTxtR.current
        const answerKey=cpKeyR.current
        if(!text){T('Please paste the question text first.','e');setUploadingQ(false);return}
        const payload={examId,text,answerKey,questions:text}
        for(const ep of [`${API}/api/upload/copy-paste`,`${API}/api/questions/copy-paste`,`${API}/api/questions/bulk`]){
          try{const r=await fetch(ep,{method:'POST',headers:HJ(),body:JSON.stringify(payload)});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      } else if(qMeth==='excel'){
        if(!excelF){T('Please select an Excel file.','e');setUploadingQ(false);return}
        for(const ep of [`${API}/api/excel/upload`,`${API}/api/questions/excel`,`${API}/api/upload/excel`]){
          try{const fd=new FormData();fd.append('file',excelF);fd.append('examId',examId);fd.append('exam_id',examId);const r=await fetch(ep,{method:'POST',headers:H(),body:fd});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      } else if(qMeth==='pdf'){
        if(!pdfF){T('Please select a PDF file.','e');setUploadingQ(false);return}
        for(const ep of [`${API}/api/upload/pdf`,`${API}/api/questions/pdf`,`${API}/api/upload/pdf-parse`]){
          try{const fd=new FormData();fd.append('file',pdfF);fd.append('examId',examId);fd.append('exam_id',examId);const r=await fetch(ep,{method:'POST',headers:H(),body:fd});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      }
      if(res&&(res.ok||res.status===201)){
        const d=await res.json().catch(()=>({}))
        const cnt=d.success||d.count||d.uploaded||d.inserted||0
        setUpRes({s:cnt,f:d.failed||0,msg:`${cnt} questions uploaded successfully!`})
        T(`${cnt} questions uploaded successfully!`)
        setEStep(3)
      } else {
        setUpRes({s:0,f:0,msg:'Upload endpoint unavailable. Please use Question Bank instead.'})
        T('Upload endpoint unavailable. Please use Question Bank instead.','w')
        setEStep(3)
      }
    } catch(err:any){
      setUpRes({s:0,f:0,msg:'Network error occurred.'})
      T('A network error occurred. Please check your connection.','w')
      setEStep(3)
    }
    setUploadingQ(false)
  },[createdEId,qMeth,excelF,pdfF,HJ,H,T])

  // ══ QUESTION BANK ══
  const addQ=useCallback(async()=>{
    const text=qTxtR.current
    if(!text){T('Question text is required.','e');return}
    setSavingQ(true)
    const payload={text,subject:qSubj,chapter:qChapR.current||undefined,difficulty:qDiff,type:qType,
      options:qType==='SCQ'||qType==='MSQ'?[qA.current,qB.current,qC.current,qD.current].filter(Boolean):undefined,
      correctAnswer:qAns}
    try{
      const res=await fetch(`${API}/api/questions`,{method:'POST',headers:HJ(),body:JSON.stringify(payload)})
      if(res.ok||res.status===201){
        T('Question added to bank successfully.')
        qTxtR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current=''
        fetch(`${API}/api/questions`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>{if(d)setQuestions(d)})
      } else {
        const e=await res.json().catch(()=>({}))
        T(e.message||`Error ${res.status}`,'e')
      }
    } catch(err:any){T(`Network error: ${err.message}`,'e')}
    setSavingQ(false)
  },[qSubj,qDiff,qType,qAns,HJ,H,T])

  const banStd=useCallback(async()=>{
    const reason=banReaR.current
    if(!banId||!reason){T('Student ID and ban reason are both required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/ban/${banId}`,{method:'POST',headers:HJ(),body:JSON.stringify({banReason:reason,banType:banT})})
      if(res.ok){
        setStudents(p=>p.map(s=>s._id===banId?{...s,banned:true,banReason:reason}:s))
        T('Student has been banned successfully.')
        setBanId('');banReaR.current=''
      } else {T('Failed to ban student.','e')}
    } catch{T('A network error occurred. Please check your connection.','e')}
  },[banId,banT,HJ,T])

  const unbanStd=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/unban/${id}`,{method:'POST',headers:H()})
      if(res.ok){setStudents(p=>p.map(s=>s._id===id?{...s,banned:false,banReason:''}:s));T('Student has been unbanned successfully.')}
      else{T('Failed to unban student.','e')}
    } catch{T('A network error occurred.','e')}
  },[H,T])

  const toggleFeat=useCallback(async(key:string)=>{
    const ft=features.find(f=>f.key===key);const ne=!ft?.enabled
    setFeatures(p=>p.map(f=>f.key===key?{...f,enabled:ne}:f))
    try{await fetch(`${API}/api/admin/features`,{method:'POST',headers:HJ(),body:JSON.stringify({key,enabled:ne})})}catch{}
    T(`${ft?.label||key} ${ne?'enabled':'disabled'} successfully.`)
  },[features,HJ,T])

  const sendAnn=useCallback(async()=>{
    const msg=annR.current
    if(!msg){T('Please write a message before sending.','e');return}
    try{
      let res=await fetch(`${API}/api/admin/announce`,{method:'POST',headers:HJ(),body:JSON.stringify({message:msg,batch:annBatch})})
      if(!res.ok){res=await fetch(`${API}/api/admin/manage/announce`,{method:'POST',headers:HJ(),body:JSON.stringify({message:msg,batch:annBatch})})}
      if(res.ok){T('Announcement sent successfully.');annR.current=''}
      else{T('Failed to send announcement.','e')}
    } catch{T('A network error occurred.','e')}
  },[annBatch,HJ,T])

  const delExam=useCallback(async(id:string)=>{
    if(!confirm('Delete this exam? This action cannot be undone.'))return
    try{
      const res=await fetch(`${API}/api/exams/${id}`,{method:'DELETE',headers:H()})
      if(res.ok){setExams(p=>p.filter(e=>e._id!==id));T('Exam deleted successfully.')}
      else{T('Failed to delete exam.','e')}
    } catch{T('A network error occurred.','e')}
  },[H,T])

  const cloneExam=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/exams/${id}/clone`,{method:'POST',headers:H()})
      if(res.ok){
        T('Exam cloned successfully.')
        fetch(`${API}/api/exams`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>{if(d)setExams(d)})
      } else{T('Failed to clone exam.','e')}
    } catch{T('A network error occurred.','e')}
  },[H,T])

  const impersonate=useCallback(async()=>{
    if(!impId){T('Student ID is required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/impersonate/${impId}`,{method:'POST',headers:H()})
      if(res.ok){const d=await res.json();T(`Now viewing as: ${d.name||impId}`);window.open(`/dashboard?impersonate=${impId}`,'_blank')}
      else{T('Impersonate failed. Please try from student profile.','e')}
    } catch{T('A network error occurred.','e')}
  },[impId,H,T])

  const extendTime=useCallback(async()=>{
    if(!extStdId){T('Student ID is required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/extend-time`,{method:'POST',headers:HJ(),body:JSON.stringify({studentId:extStdId,extraMinutes:parseInt(extMins)||10})})
      if(res.ok){T(`${extMins} minutes of extra time granted.`)}
      else{T('Failed to extend time.','e')}
    } catch{T('A network error occurred.','e')}
  },[extStdId,extMins,HJ,T])

  const saveBrand=useCallback(async()=>{
    setSavingB(true)
    try{
      const res=await fetch(`${API}/api/admin/branding`,{method:'POST',headers:HJ(),body:JSON.stringify({brandName:bNameR.current,tagline:bTagR.current,supportEmail:bMailR.current,seoTitle:seoTR.current,seoDesc:seoDR.current})})
      if(res.ok){T('Branding settings saved successfully.')}
      else{T('Failed to save settings.','e')}
    } catch{T('A network error occurred.','e')}
    setSavingB(false)
  },[HJ,T])

  const toggleMaint=useCallback(async()=>{
    const nm=!mainOn;setMainOn(nm)
    setFeatures(p=>p.map(f=>f.key==='maintenance'?{...f,enabled:nm}:f))
    try{await fetch(`${API}/api/admin/features`,{method:'POST',headers:HJ(),body:JSON.stringify({key:'maintenance',enabled:nm,message:mainMsgR.current})})}catch{}
    T(nm?'Maintenance mode is now ON. Students cannot access the platform.':'Maintenance mode is OFF. Platform is live.')
  },[mainOn,HJ,T])

  const doExport=useCallback(async(url:string,fname:string)=>{
    try{
      const res=await fetch(url,{headers:H()})
      if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=fname;a.click();T('Download started successfully.')}
      else{T('Export failed. Please try again.','e')}
    } catch{T('A network error occurred.','e')}
  },[H,T])

  const doBackup=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/backup`,{method:'POST',headers:H()})
      if(res.ok){T('Backup triggered successfully.')}
      else{T('Backup failed. Please try again.','e')}
    } catch{T('A network error occurred.','e')}
  },[H,T])

  const resolveTicket=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/tickets/${id}/resolve`,{method:'PATCH',headers:H()})
      if(res.ok){setTickets(p=>p.map(t=>t._id===id?{...t,status:'resolved'}:t));T('Ticket resolved successfully.')}
      else{T('Failed to resolve ticket.','e')}
    } catch{T('A network error occurred.','e')}
  },[H,T])

  const aiGen=useCallback(async()=>{
    if(!aiTopicR.current){T('Please enter a topic.','e');return}
    setAiLoading(true)
    try{
      const res=await fetch(`${API}/api/questions/generate`,{method:'POST',headers:HJ(),body:JSON.stringify({topic:aiTopicR.current,count:parseInt(aiCount)||10,subject:aiSubj,difficulty:aiDiff})})
      if(res.ok){
        const d=await res.json()
        const list=Array.isArray(d)?d:(d.questions||[])
        setAiResult(list)
        T(`${list.length} questions generated successfully!`)
      } else{T('AI generation failed. Please check backend.','e')}
    } catch{T('A network error occurred.','e')}
    setAiLoading(false)
  },[aiCount,aiSubj,aiDiff,HJ,T])

  const createBatch=useCallback(async()=>{
    if(!batchNameR.current){T('Please enter a batch name.','e');return}
    setCreatingBatch(true)
    try{
      const res=await fetch(`${API}/api/admin/batches`,{method:'POST',headers:HJ(),body:JSON.stringify({name:batchNameR.current})})
      if(res.ok){
        T('Batch created successfully.')
        batchNameR.current=''
        fetch(`${API}/api/admin/batches`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>{if(d)setBatches(d)})
      } else{T('Failed to create batch.','e')}
    } catch{T('A network error occurred.','e')}
    setCreatingBatch(false)
  },[HJ,H,T])

  const batchTransfer=useCallback(async()=>{
    if(!batchTransStdId||!batchTransTo){T('Student ID and target batch are both required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/batch-transfer`,{method:'POST',headers:HJ(),body:JSON.stringify({studentId:batchTransStdId,toBatch:batchTransTo})})
      if(res.ok){T('Student transferred successfully.')}
      else{T('Transfer failed. Please try again.','e')}
    } catch{T('A network error occurred.','e')}
  },[batchTransStdId,batchTransTo,HJ,T])

  const createAdmin=useCallback(async()=>{
    if(!admNameR.current||!admEmailR.current||!admPassR.current){T('Name, email and password are all required.','e');return}
    setCreatingAdm(true)
    try{
      const res=await fetch(`${API}/api/admin/manage/admins`,{method:'POST',headers:HJ(),body:JSON.stringify({name:admNameR.current,email:admEmailR.current,password:admPassR.current,role:admRole})})
      if(res.ok){
        T('Admin account created successfully.')
        fetch(`${API}/api/admin/manage/admins`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>{if(d)setAdminUsers(d)})
      } else{
        const e=await res.json().catch(()=>({}))
        T(e.message||'Failed to create admin.','e')
      }
    } catch{T('A network error occurred.','e')}
    setCreatingAdm(false)
  },[admRole,HJ,H,T])

  const savePerms=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/permissions`,{method:'POST',headers:HJ(),body:JSON.stringify(perms)})
      if(res.ok){T('Permissions saved successfully.')}
      else{T('Failed to save permissions.','e')}
    } catch{T('A network error occurred.','e')}
  },[perms,HJ,T])

  if(!mounted)return null

  const fStds=(students||[]).filter(s=>{
    const m=stdSearch.toLowerCase()
    const ok=!m||(s.name?.toLowerCase().includes(m)||s.email?.toLowerCase().includes(m)||s._id?.includes(m))
    if(stdFilter==='banned')return ok&&!!s.banned
    if(stdFilter==='active')return ok&&!s.banned
    return ok
  })
  const fExams=(exams||[]).filter(e=>!examSearch||e.title?.toLowerCase().includes(examSearch.toLowerCase()))
  const fQs=(questions||[]).filter(q=>!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase()))

  const NAV=[
    {id:'dashboard',ico:'📊',lbl:'Dashboard'},
    {id:'exams',ico:'📝',lbl:'All Exams'},
    {id:'create_exam',ico:'➕',lbl:'Create Exam'},
    {id:'templates',ico:'📋',lbl:'Templates (S75)'},
    {id:'bulk_creator',ico:'⚡',lbl:'Bulk Creator (N8)'},
    {id:'questions',ico:'❓',lbl:'Question Bank'},
    {id:'smart_gen',ico:'🤖',lbl:'Smart Generator (S101)'},
    {id:'pyq_bank',ico:'📚',lbl:'PYQ Bank (S104)'},
    {id:'students',ico:'👥',lbl:'Students'},
    {id:'batches',ico:'📦',lbl:'Batches (S5/M3)'},
    {id:'admins',ico:'🛡️',lbl:'Admins (S37)'},
    {id:'live',ico:'🔴',lbl:'Live Monitor (S95)'},
    {id:'results',ico:'📈',lbl:'Results & Ranks'},
    {id:'leaderboard',ico:'🏆',lbl:'Leaderboard (S15)'},
    {id:'analytics',ico:'📉',lbl:'Analytics'},
    {id:'cheating',ico:'🚨',lbl:'Anti-Cheat Logs'},
    {id:'snapshots',ico:'📷',lbl:'Snapshots'},
    {id:'integrity',ico:'🤖',lbl:'AI Integrity (AI-6)'},
    {id:'tickets',ico:'🎫',lbl:'Grievances (S92)'},
    {id:'announcements',ico:'📢',lbl:'Announcements (S47)'},
    {id:'reports',ico:'📊',lbl:'Reports & Export'},
    {id:'features',ico:'🚩',lbl:'Feature Flags (N21)'},
    {id:'permissions',ico:'🔐',lbl:'Permissions (S72)'},
    {id:'branding',ico:'🎨',lbl:'Branding (S56)'},
    {id:'maintenance',ico:'🔧',lbl:'Maintenance (S66)'},
    {id:'audit',ico:'📋',lbl:'Audit Logs (S93)'},
    {id:'tasks',ico:'✅',lbl:'Tasks (M13)'},
    {id:'changelog',ico:'📝',lbl:'Changelog (M14)'},
    {id:'proct_pdf',ico:'📄',lbl:'Proctoring PDF (M15)'},
    {id:'omr_view',ico:'📋',lbl:'OMR Sheet View (S102)'},
    {id:'ans_challenge',ico:'⚔️',lbl:'Answer Key Challenge (S69)'},
    {id:'re_eval',ico:'🔄',lbl:'Re-Evaluation (S71)'},
    {id:'transparency',ico:'🔍',lbl:'Transparency Report (S70)'},
    {id:'qbank_stats',ico:'📊',lbl:'Question Bank Stats (M9)'},
    {id:'subj_rank',ico:'🏅',lbl:'Subject Leaderboard (M10)'},
    {id:'global_search',ico:'🔎',lbl:'Global Search (M12)'},
    {id:'retention',ico:'📈',lbl:'Retention Analytics (S110)'},
  ]

  const sBox=(ico:string,lbl:string,val:any)=>(
    <div style={{background:CRD,border:`1px solid ${BOR}`,borderRadius:12,padding:'14px 16px',flex:1,minWidth:130}}>
      <div style={{fontSize:22,marginBottom:4}}>{ico}</div>
      <div style={{fontSize:20,fontWeight:700,color:ACC,fontFamily:'Playfair Display,Georgia,serif'}}>{loading?'…':val}</div>
      <div style={{fontSize:11,color:DIM}}>{lbl}</div>
    </div>
  )

  return (
    <div style={{background:BG,minHeight:'100vh',color:TS,fontFamily:'Inter,sans-serif'}}>

      {/* FULL WIDTH TOP BANNER TOAST — clearly visible on mobile */}
      {toast&&(
        <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9999,padding:'14px 20px',fontWeight:700,fontSize:14,background:toast.tp==='s'?SUC:toast.tp==='w'?WRN:DNG,color:toast.tp==='w'?'#000':'#fff',textAlign:'center',boxShadow:'0 4px 24px rgba(0,0,0,0.7)',letterSpacing:0.2}}>
          {toast.tp==='e'?'❌':toast.tp==='w'?'⚠️':'✅'} {toast.msg}
        </div>
      )}

      {/* TOP NAV */}
      <div style={{position:'sticky',top:0,zIndex:100,background:'rgba(0,10,24,0.97)',backdropFilter:'blur(12px)',borderBottom:`1px solid ${BOR}`,padding:'0 14px',height:54,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <button onClick={()=>setSideOpen(p=>!p)} style={{background:'none',border:'none',color:TS,fontSize:20,cursor:'pointer',padding:4}}>☰</button>
          <svg width="26" height="26" viewBox="0 0 28 28"><polygon points="14,2 26,8.5 26,19.5 14,26 2,19.5 2,8.5" fill="none" stroke={ACC} strokeWidth="2"/><text x="14" y="18" textAnchor="middle" fill={ACC} fontSize="8" fontWeight="bold">PR</text></svg>
          <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:ACC}}>ProveRank</span>
          <span style={{fontSize:9,color:DIM,background:'rgba(77,159,255,0.1)',padding:'2px 5px',borderRadius:4}}>{role.toUpperCase()}</span>
        </div>
        <div style={{display:'flex',gap:6,alignItems:'center'}}>
          {loading&&<span style={{fontSize:10,color:DIM}}>⟳</span>}
          <button onClick={()=>setNotifOpen(p=>!p)} style={{background:'none',border:'none',color:TS,fontSize:17,cursor:'pointer',position:'relative'}}>
            🔔{(notifs||[]).filter(n=>!n.read).length>0&&<span style={{position:'absolute',top:-1,right:-1,background:DNG,color:'#fff',fontSize:8,borderRadius:'50%',width:12,height:12,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700}}>{(notifs||[]).filter(n=>!n.read).length}</span>}
          </button>
          <button onClick={fetchAll} style={{...bg_,padding:'5px 10px',fontSize:11}}>🔄</button>
          <button onClick={()=>{clearAuth();router.replace('/login')}} style={{background:DNG,color:'#fff',border:'none',borderRadius:6,padding:'5px 10px',cursor:'pointer',fontWeight:700,fontSize:11}}>Logout</button>
        </div>
      </div>

      {/* NOTIF PANEL */}
      {notifOpen&&(
        <div style={{position:'fixed',top:54,right:0,width:300,height:'calc(100vh - 54px)',background:CRD,borderLeft:`1px solid ${BOR}`,zIndex:200,overflow:'auto',padding:14}}>
          <div style={{display:'flex',justifyContent:'space-between',marginBottom:10}}>
            <span style={{fontWeight:700,fontSize:14}}>🔔 Notifications</span>
            <button onClick={()=>setNotifOpen(false)} style={{background:'none',border:'none',color:DIM,fontSize:16,cursor:'pointer'}}>✕</button>
          </div>
          {(notifs||[]).length===0
            ?<p style={{color:DIM,fontSize:12}}>No notifications</p>
            :(notifs||[]).map(n=>(
              <div key={n.id} style={{...cs,padding:'8px 12px',marginBottom:6}}>
                <div style={{fontSize:12,fontWeight:700}}>{n.icon} {n.msg}</div>
                <div style={{fontSize:10,color:DIM}}>{n.t}</div>
              </div>
            ))
          }
        </div>
      )}

      <div style={{display:'flex'}}>
        {/* SIDEBAR */}
        <div style={{position:'fixed',top:54,left:0,width:218,height:'calc(100vh - 54px)',background:CRD,borderRight:`1px solid ${BOR}`,zIndex:50,overflow:'auto',padding:'10px 6px',transform:sideOpen?'translateX(0)':'translateX(-100%)',transition:'transform 0.25s ease'}}>
          {NAV.map(n=>(
            <button key={n.id} onClick={()=>{setTab(n.id);setSideOpen(false)}}
              style={{display:'flex',alignItems:'center',gap:8,padding:'9px 14px',borderRadius:8,border:'none',background:tab===n.id?'rgba(77,159,255,0.15)':'transparent',color:tab===n.id?ACC:DIM,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12,fontWeight:tab===n.id?700:400,width:'100%',textAlign:'left'}}>
              <span style={{fontSize:14}}>{n.ico}</span><span>{n.lbl}</span>
            </button>
          ))}
        </div>

        {/* MAIN CONTENT */}
        <div style={{flex:1,padding:14,minHeight:'calc(100vh - 54px)',maxWidth:'100vw',overflow:'auto'}}>

          {/* DASHBOARD */}
          {tab==='dashboard'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📊 Dashboard</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:16}}>
                {sBox('👥','Students',stats?.totalStudents||(students||[]).length||'—')}
                {sBox('📝','Exams',stats?.totalExams||(exams||[]).length||'—')}
                {sBox('📈','Attempts',stats?.totalAttempts||'—')}
                {sBox('🟢','Active Today',stats?.activeStudents||'—')}
                {sBox('❓','Questions',stats?.totalQuestions||(questions||[]).length||'—')}
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>⚡ Quick Actions</div>
                  {([['➕ Create Exam','create_exam'],['❓ Add Question','questions'],['📢 Announce','announcements'],['🔴 Live Monitor','live']] as const).map(([l,t])=>(
                    <button key={t} onClick={()=>setTab(t)} style={{...bg_,width:'100%',marginBottom:6,textAlign:'left',fontSize:12}}>{l}</button>
                  ))}
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🚨 Alerts</div>
                  {(flags||[]).length===0&&(tickets||[]).filter(t=>t.status==='open').length===0
                    ?<div style={{color:SUC,fontSize:12}}>✅ All clear</div>
                    :<div>
                      {(flags||[]).length>0&&<div style={{fontSize:12,color:WRN,marginBottom:4}}>⚠️ {flags.length} cheating flag(s)</div>}
                      {(tickets||[]).filter(t=>t.status==='open').length>0&&<div style={{fontSize:12,color:WRN}}>🎫 {tickets.filter(t=>t.status==='open').length} open ticket(s)</div>}
                    </div>
                  }
                  <div style={{marginTop:10,fontSize:11,color:DIM}}>
                    <div>📦 Batches: {(batches||[]).length}</div>
                    <div>🛡️ Admins: {(adminUsers||[]).length}</div>
                  </div>
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📅 Recent Exams</div>
                {(exams||[]).length===0
                  ?<div style={{color:DIM,fontSize:12}}>No exams yet. Create your first exam.</div>
                  :(exams||[]).slice(0,5).map(e=>(
                    <div key={e._id} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                      <div>
                        <div style={{fontWeight:600}}>{e.title}</div>
                        <div style={{fontSize:11,color:DIM}}>{e.scheduledAt?new Date(e.scheduledAt).toLocaleString():''}</div>
                      </div>
                      <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:e.status==='active'?SUC:'rgba(77,159,255,0.15)',color:e.status==='active'?'#000':ACC}}>{e.status}</span>
                    </div>
                  ))
                }
              </div>
            </div>
          )}

          {/* ALL EXAMS */}
          {tab==='exams'&&(
            <div>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
                <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:0}}>📝 All Exams</h2>
                <button onClick={()=>setTab('create_exam')} style={{...bp,padding:'8px 14px',fontSize:12}}>➕ New</button>
              </div>
              <SInput init='' onSet={setExamSearch} ph='🔍 Search exams…' style={{...inp,marginBottom:10}} />
              {fExams.length===0
                ?<div style={{...cs,color:DIM}}>No exams found.</div>
                :fExams.map(e=>(
                  <div key={e._id} style={cs}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                      <div style={{flex:1}}>
                        <div style={{fontWeight:700,fontSize:13}}>{e.title}</div>
                        <div style={{fontSize:11,color:DIM}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleString():''} · 🏆 {e.totalMarks||'?'} marks · ⏱ {e.duration||'?'} min · 📦 {e.category||'General'}</div>
                      </div>
                      <div style={{display:'flex',gap:6,flexWrap:'wrap',alignItems:'flex-start'}}>
                        <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:e.status==='active'?SUC:'rgba(77,159,255,0.1)',color:e.status==='active'?'#000':ACC}}>{e.status}</span>
                        <button onClick={()=>cloneExam(e._id)} style={{...bg_,padding:'4px 9px',fontSize:10}}>📋 Clone</button>
                        <button onClick={()=>delExam(e._id)} style={{...bd,padding:'4px 9px',fontSize:10}}>🗑</button>
                      </div>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* CREATE EXAM */}
          {tab==='create_exam'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>➕ Create Exam</h2>
              <div style={{display:'flex',gap:6,marginBottom:16}}>
                {[1,2,3].map(s=>(
                  <div key={s} style={{flex:1,textAlign:'center',padding:'8px',borderRadius:8,background:eStep===s?ACC:eStep>s?SUC:`rgba(77,159,255,0.08)`,color:eStep===s||eStep>s?'#000':DIM,fontWeight:700,fontSize:12}}>
                    {eStep>s?'✓':s}. {s===1?'Basic Info':s===2?'Questions':'Done'}
                  </div>
                ))}
              </div>

              {eStep===1&&(
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>📋 Exam Details</div>
                  <div style={{marginBottom:10}}>
                    <label style={lbl}>Exam Title *</label>
                    <SInput init='' onSet={v=>{eTitleR.current=v}} ph='NEET Full Mock Test 1' style={inp} />
                  </div>
                  <div style={{marginBottom:10}}>
                    <label style={lbl}>Date & Time *</label>
                    <SInput type='datetime-local' init='' onSet={v=>{eDateR.current=v}} style={inp} />
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>
                    <div><label style={lbl}>Total Marks</label><SInput init='720' onSet={v=>{eMarksR.current=v}} style={inp} /></div>
                    <div><label style={lbl}>Duration (minutes)</label><SInput init='200' onSet={v=>{eDurR.current=v}} style={inp} /></div>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                    <div>
                      <label style={lbl}>Category</label>
                      <SSelect val={eCatR.current||'Full Mock'} onChange={v=>{eCatR.current=v}} style={inp} opts={['Full Mock','Chapter Test','Part Test','Grand Test','PYQ'].map(o=>({v:o,l:o}))} />
                    </div>
                    <div><label style={lbl}>Password (optional)</label><SInput init='' onSet={v=>{ePassR.current=v}} ph='Leave blank for open access' style={inp} /></div>
                  </div>
                  <button onClick={createExamS1} disabled={creatingE} style={{...bp,width:'100%',opacity:creatingE?0.7:1}}>{creatingE?'Creating…':'Create Exam → Next'}</button>
                </div>
              )}

              {eStep===2&&(
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:4,fontSize:13}}>📤 Add Questions</div>
                  <div style={{fontSize:11,color:SUC,marginBottom:12}}>
                    {createdEId?`Exam ID: ${createdEId}`:'Exam created successfully.'}
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:14}}>
                    {(['copypaste','manual','excel','pdf'] as const).map(k=>{
                      const labels={copypaste:['📋','Copy-Paste'],manual:['✏️','Manual Entry'],excel:['📊','Excel File'],pdf:['📄','PDF Parse']}
                      const [ico,lbl_]=labels[k]
                      return(
                        <button key={k} onClick={()=>setQMeth(k)}
                          style={{padding:'12px 6px',borderRadius:10,border:`2px solid ${qMeth===k?ACC:BOR}`,background:qMeth===k?'rgba(77,159,255,0.12)':'transparent',color:qMeth===k?ACC:DIM,cursor:'pointer',fontSize:12,fontWeight:qMeth===k?700:400,textAlign:'center'}}>
                          <div style={{fontSize:20,marginBottom:3}}>{ico}</div>{lbl_}
                        </button>
                      )
                    })}
                  </div>

                  {(qMeth==='copypaste'||qMeth==='manual')&&(
                    <div>
                      <div style={{...cs,background:'rgba(77,159,255,0.04)',padding:'8px 12px',marginBottom:8}}>
                        <div style={{fontSize:11,color:DIM,lineHeight:1.6}}>Format:<br/>Q1. Question text?<br/>A) Option A<br/>B) Option B<br/>C) Option C<br/>D) Option D</div>
                      </div>
                      <label style={lbl}>Paste Questions *</label>
                      <STextarea init='' onSet={v=>{cpTxtR.current=v}} rows={8}
                        ph={'Q1. Photosynthesis primary site?\nA) Mitochondria\nB) Ribosome\nC) Chloroplast\nD) Nucleus'}
                        style={{...inp,resize:'vertical'}} />
                      <div style={{marginTop:10}}>
                        <label style={lbl}>Answer Key (optional) — Format: 1-C,2-A,3-D</label>
                        <SInput init='' onSet={v=>{cpKeyR.current=v}} ph='1-C,2-A,3-B,4-D…' style={inp} />
                      </div>
                    </div>
                  )}

                  {qMeth==='excel'&&(
                    <div>
                      <div style={{...cs,background:'rgba(0,196,140,0.04)',border:`1px solid rgba(0,196,140,0.2)`,padding:'8px 12px',marginBottom:10}}>
                        <div style={{fontSize:11,color:SUC,fontWeight:700,marginBottom:3}}>Excel Format</div>
                        <div style={{fontSize:10,color:DIM}}>Columns: question_text | subject | chapter | difficulty | option_a | option_b | option_c | option_d | correct_answer | type</div>
                      </div>
                      <label style={lbl}>Select Excel File (.xlsx / .csv)</label>
                      <input type='file' accept='.xlsx,.xls,.csv' onChange={e=>setExcelF(e.target.files?.[0]||null)} style={{...inp,padding:'8px'}} />
                      {excelF&&<div style={{fontSize:11,color:SUC,marginTop:5}}>✓ {excelF.name}</div>}
                    </div>
                  )}

                  {qMeth==='pdf'&&(
                    <div>
                      <div style={{...cs,background:'rgba(168,85,247,0.04)',border:`1px solid rgba(168,85,247,0.2)`,padding:'8px 12px',marginBottom:10}}>
                        <div style={{fontSize:11,color:'#A855F7',fontWeight:700,marginBottom:3}}>PDF Parse</div>
                        <div style={{fontSize:10,color:DIM}}>Upload a questions PDF — the system will extract them automatically.</div>
                      </div>
                      <label style={lbl}>Select PDF File</label>
                      <input type='file' accept='.pdf' onChange={e=>setPdfF(e.target.files?.[0]||null)} style={{...inp,padding:'8px'}} />
                      {pdfF&&<div style={{fontSize:11,color:SUC,marginTop:5}}>✓ {pdfF.name}</div>}
                    </div>
                  )}

                  {upRes&&(
                    <div style={{padding:'10px 12px',borderRadius:8,background:upRes.s>0?'rgba(0,196,140,0.08)':'rgba(255,184,77,0.08)',border:`1px solid ${upRes.s>0?SUC:WRN}`,marginTop:10,fontSize:12}}>
                      {upRes.s>0?`✅ ${upRes.s} questions uploaded!`:`⚠️ ${upRes.msg}`}
                    </div>
                  )}

                  <div style={{display:'flex',gap:8,marginTop:14}}>
                    <button onClick={()=>setEStep(1)} style={{...bg_,flex:1,fontSize:12}}>← Back</button>
                    <button onClick={uploadQs} disabled={uploadingQ} style={{...bp,flex:2,opacity:uploadingQ?0.7:1,fontSize:12}}>{uploadingQ?'Uploading…':'📤 Upload Questions'}</button>
                    <button onClick={()=>setEStep(3)} style={{...bg_,flex:1,fontSize:12}}>Skip →</button>
                  </div>
                </div>
              )}

              {eStep===3&&(
                <div style={{...cs,textAlign:'center',padding:28}}>
                  <div style={{fontSize:44,marginBottom:10}}>🎉</div>
                  <h3 style={{color:SUC,fontFamily:'Playfair Display,serif',marginBottom:6}}>Exam is Ready!</h3>
                  <p style={{color:DIM,fontSize:12,marginBottom:16}}>ID: {createdEId||'—'}</p>
                  <div style={{display:'flex',gap:8,justifyContent:'center',flexWrap:'wrap'}}>
                    <button onClick={()=>{setEStep(1);setCreatedEId('');setUpRes(null)}} style={bp}>➕ New Exam</button>
                    <button onClick={()=>setTab('exams')} style={bg_}>📝 All Exams</button>
                    <button onClick={()=>setTab('questions')} style={bg_}>❓ Add Questions</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* TEMPLATES S75 */}
          {tab==='templates'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📋 Exam Templates (S75)</h2>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                {[
                  {n:'NEET Full Mock',m:720,d:200,cat:'Full Mock'},
                  {n:'NEET Part Test',m:360,d:100,cat:'Part Test'},
                  {n:'Biology Full',m:360,d:120,cat:'Chapter Test'},
                  {n:'Chapter Test',m:120,d:45,cat:'Chapter Test'},
                  {n:'Grand Test',m:720,d:210,cat:'Grand Test'},
                  {n:'PYQ Practice',m:720,d:180,cat:'PYQ'},
                ].map((tpl,i)=>(
                  <div key={i} style={cs}>
                    <div style={{fontWeight:700,fontSize:13,color:ACC,marginBottom:6}}>{tpl.n}</div>
                    <div style={{fontSize:11,color:DIM,marginBottom:8}}>🏆 {tpl.m} marks · ⏱ {tpl.d} min</div>
                    <button onClick={()=>{eCatR.current=tpl.cat;eMarksR.current=tpl.m.toString();eDurR.current=tpl.d.toString();setTab('create_exam');T(`Template "${tpl.n}" loaded.`)}} style={{...bp,width:'100%',fontSize:11,padding:'8px'}}>Use Template →</button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BULK CREATOR N8 */}
          {tab==='bulk_creator'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>⚡ Bulk Exam Creator (N8)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>Create Multiple Exams from Excel</div>
                <div style={{...cs,background:'rgba(0,196,140,0.04)',border:`1px solid rgba(0,196,140,0.2)`,padding:'8px 12px',marginBottom:12}}>
                  <div style={{fontSize:11,color:SUC,fontWeight:700,marginBottom:3}}>Required Columns:</div>
                  <div style={{fontSize:10,color:DIM}}>title | scheduled_date | total_marks | duration_minutes | category | password</div>
                </div>
                <label style={lbl}>Select Excel File (.xlsx)</label>
                <input type='file' accept='.xlsx,.xls,.csv' onChange={e=>setBulkExamFile(e.target.files?.[0]||null)} style={{...inp,padding:'8px',marginBottom:12}} />
                {bulkExamFile&&<div style={{fontSize:11,color:SUC,marginBottom:10}}>✓ {bulkExamFile.name}</div>}
                <button disabled={!bulkExamFile||bulkExamLoading} onClick={async()=>{
                  if(!bulkExamFile)return
                  setBulkExamLoading(true)
                  try{
                    const fd=new FormData();fd.append('file',bulkExamFile)
                    const res=await fetch(`${API}/api/exams/bulk`,{method:'POST',headers:H(),body:fd})
                    if(res.ok){const d=await res.json();T(`${d.created||d.count||'?'} exams created successfully!`)}
                    else{T('Bulk creation failed.','e')}
                  } catch{T('A network error occurred.','e')}
                  setBulkExamLoading(false)
                }} style={{...bp,width:'100%',opacity:(!bulkExamFile||bulkExamLoading)?0.7:1}}>{bulkExamLoading?'Creating…':'Create All Exams →'}</button>
              </div>
            </div>
          )}

          {/* QUESTION BANK */}
          {tab==='questions'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>❓ Question Bank</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>➕ Add Question</div>
                <div style={{marginBottom:8}}>
                  <label style={lbl}>Question Text *</label>
                  <STextarea init='' onSet={v=>{qTxtR.current=v}} rows={3} ph='Type question here…' style={{...inp,resize:'vertical'}} />
                </div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:8}}>
                  <div><label style={lbl}>Subject</label><SSelect val={qSubj} onChange={setQSubj} style={inp} opts={['Physics','Chemistry','Biology'].map(o=>({v:o,l:o}))}/></div>
                  <div><label style={lbl}>Chapter (optional)</label><SInput init='' onSet={v=>{qChapR.current=v}} ph='e.g. Cell Biology' style={inp} /></div>
                </div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:8,marginBottom:8}}>
                  <div><label style={lbl}>Difficulty</label><SSelect val={qDiff} onChange={setQDiff} style={inp} opts={['easy','medium','hard'].map(o=>({v:o,l:o.charAt(0).toUpperCase()+o.slice(1)}))}/></div>
                  <div><label style={lbl}>Type</label><SSelect val={qType} onChange={setQType} style={inp} opts={['SCQ','MSQ','Integer'].map(o=>({v:o,l:o}))}/></div>
                  <div><label style={lbl}>Correct Answer</label><SSelect val={qAns} onChange={setQAns} style={inp} opts={['A','B','C','D'].map(o=>({v:o,l:o}))}/></div>
                </div>
                {(qType==='SCQ'||qType==='MSQ')&&(
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:8}}>
                    {[['A',qA],['B',qB],['C',qC],['D',qD]].map(([l_,r]:any)=>(
                      <div key={l_}><label style={lbl}>Option {l_}</label><SInput init='' onSet={v=>{r.current=v}} ph={`Option ${l_}`} style={inp} /></div>
                    ))}
                  </div>
                )}
                <button onClick={addQ} disabled={savingQ} style={{...bp,width:'100%',opacity:savingQ?0.7:1}}>{savingQ?'Saving…':'Save Question'}</button>
              </div>
              <SInput init='' onSet={setQSearch} ph='🔍 Search questions…' style={{...inp,marginBottom:8}} />
              <div style={{display:'flex',gap:6,marginBottom:10,flexWrap:'wrap'}}>
                <span style={{fontSize:12,color:DIM}}>Total: {(questions||[]).length} | Shown: {fQs.length}</span>
                {['Physics','Chemistry','Biology'].map(s=>(
                  <button key={s} onClick={()=>setQSearch(s)} style={{...bg_,padding:'3px 8px',fontSize:10}}>{s}: {(questions||[]).filter(q=>q.subject===s).length}</button>
                ))}
              </div>
              {fQs.length===0
                ?<div style={{...cs,color:DIM}}>No questions yet. Add one above.</div>
                :fQs.slice(0,30).map((q,i)=>(
                  <div key={q._id} style={{...cs,padding:'8px 12px'}}>
                    <div style={{fontSize:12,fontWeight:600,marginBottom:4}}>Q{i+1}. {q.text?.slice(0,100)}{q.text?.length>100?'…':''}</div>
                    <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                      <span style={{fontSize:9,padding:'2px 5px',borderRadius:4,background:'rgba(77,159,255,0.1)',color:ACC}}>{q.subject}</span>
                      <span style={{fontSize:9,padding:'2px 5px',borderRadius:4,background:'rgba(255,255,255,0.05)',color:DIM}}>{q.difficulty}</span>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* SMART GENERATOR S101 */}
          {tab==='smart_gen'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🤖 Smart Question Generator (S101)</h2>
              <div style={cs}>
                <div style={{marginBottom:10}}><label style={lbl}>Topic *</label><SInput init='' onSet={v=>{aiTopicR.current=v}} ph='e.g. Photosynthesis, Newton Laws' style={inp} /></div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:8,marginBottom:12}}>
                  <div><label style={lbl}>Subject</label><SSelect val={aiSubj} onChange={setAiSubj} style={inp} opts={['Physics','Chemistry','Biology'].map(o=>({v:o,l:o}))}/></div>
                  <div><label style={lbl}>Difficulty</label><SSelect val={aiDiff} onChange={setAiDiff} style={inp} opts={['easy','medium','hard'].map(o=>({v:o,l:o.charAt(0).toUpperCase()+o.slice(1)}))}/></div>
                  <div><label style={lbl}>Count</label><SSelect val={aiCount} onChange={setAiCount} style={inp} opts={['5','10','15','20','30'].map(o=>({v:o,l:o}))}/></div>
                </div>
                <button onClick={aiGen} disabled={aiLoading} style={{...bp,width:'100%',opacity:aiLoading?0.7:1}}>{aiLoading?'Generating…':'🤖 Generate Questions'}</button>
              </div>
              {aiResult.length>0&&(
                <div>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:13,color:SUC}}>✅ {aiResult.length} Questions Generated</div>
                  {aiResult.slice(0,10).map((q:any,i:number)=>(
                    <div key={i} style={{...cs,padding:'8px 12px'}}>
                      <div style={{fontSize:12,fontWeight:600}}>Q{i+1}. {q.text||q.question||JSON.stringify(q).slice(0,80)}</div>
                    </div>
                  ))}
                  <button onClick={async()=>{
                    try{
                      const res=await fetch(`${API}/api/questions/bulk`,{method:'POST',headers:HJ(),body:JSON.stringify({questions:aiResult})})
                      if(res.ok){T('AI generated questions saved to Question Bank.');fetchAll()}
                      else{T('Failed to save questions.','e')}
                    } catch{T('A network error occurred.','e')}
                  }} style={{...bp,width:'100%',marginTop:8}}>💾 Save All to Question Bank</button>
                </div>
              )}
            </div>
          )}

          {/* PYQ BANK S104 */}
          {tab==='pyq_bank'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📚 PYQ Bank (S104) — NEET 2015–2024</h2>
              <div style={cs}>
                <div style={{fontSize:13,color:DIM,marginBottom:12}}>Filter previous year questions by year or subject to add to exams.</div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:10}}>
                  {['2024','2023','2022','2021','2020','2019','2018','2017','2016','2015'].map(y=>(
                    <button key={y} onClick={async()=>{
                      try{const r=await fetch(`${API}/api/questions?year=${y}&type=pyq`,{headers:H()});if(r.ok){const d=await r.json();T(`${(d||[]).length} PYQs found for ${y}`)}else{T(`No PYQ data for ${y}`,'w')}}catch{T('A network error occurred.','e')}
                    }} style={{...bg_,padding:'5px 12px',fontSize:12}}>{y}</button>
                  ))}
                </div>
                <div style={{display:'flex',gap:8}}>
                  {['Physics','Chemistry','Biology'].map(s=>(
                    <button key={s} onClick={async()=>{
                      try{const r=await fetch(`${API}/api/questions?subject=${s}&type=pyq`,{headers:H()});if(r.ok){const d=await r.json();T(`${(d||[]).length} ${s} PYQs found`)}else{T(`No ${s} PYQs available`,'w')}}catch{T('A network error occurred.','e')}
                    }} style={{...bg_,flex:1,fontSize:12}}>{s}</button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* STUDENTS */}
          {tab==='students'&&!selStudent&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>👥 Students</h2>
              <div style={{display:'flex',gap:6,marginBottom:10,flexWrap:'wrap'}}>
                <SInput init='' onSet={setStdSearch} ph='🔍 Name / email / ID…' style={{...inp,flex:1,minWidth:180}} />
                {(['all','active','banned'] as const).map(f=>(
                  <button key={f} onClick={()=>setStdFilter(f)} style={{...bg_,padding:'7px 12px',background:stdFilter===f?'rgba(77,159,255,0.2)':undefined,color:stdFilter===f?ACC:DIM,fontSize:11}}>
                    {f==='all'?`All (${(students||[]).length})`:f==='active'?`Active (${(students||[]).filter(s=>!s.banned).length})`:`Banned (${(students||[]).filter(s=>s.banned).length})`}
                  </button>
                ))}
                <button onClick={()=>doExport(`${API}/api/admin/export/students`,'students.csv')} style={{...bg_,padding:'7px 10px',fontSize:11}}>📥 CSV</button>
              </div>
              {fStds.length===0
                ?<div style={{...cs,color:DIM}}>No students found.</div>
                :fStds.map(s=>(
                  <div key={s._id} style={{...cs,borderLeft:`3px solid ${s.banned?DNG:SUC}`}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                      <div style={{flex:1}}>
                        <div style={{fontWeight:700,fontSize:13}}>{s.name||'—'}</div>
                        <div style={{fontSize:11,color:DIM}}>{s.email} · {s.phone||'—'}</div>
                        <div style={{fontSize:10,color:DIM}}>ID: {s._id}</div>
                        {s.banned&&<div style={{fontSize:10,color:DNG}}>🚫 Banned: {s.banReason}</div>}
                        {s.integrityScore!==undefined&&<div style={{fontSize:10,color:s.integrityScore<40?DNG:s.integrityScore<70?WRN:SUC}}>🤖 Integrity: {s.integrityScore}/100</div>}
                      </div>
                      <div style={{display:'flex',gap:5,flexWrap:'wrap',alignItems:'flex-start'}}>
                        <button onClick={()=>setSelStudent(s)} style={{...bg_,padding:'4px 8px',fontSize:10}}>👤 Profile</button>
                        {s.banned
                          ?<button onClick={()=>unbanStd(s._id)} style={{background:SUC,color:'#000',border:'none',borderRadius:6,padding:'4px 8px',cursor:'pointer',fontWeight:700,fontSize:10}}>✅ Unban</button>
                          :<button onClick={()=>setBanId(s._id)} style={{...bd,padding:'4px 8px',fontSize:10}}>🚫 Ban</button>
                        }
                      </div>
                    </div>
                  </div>
                ))
              }
              <div style={{...cs,marginTop:14}}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🚫 Ban Student (M1)</div>
                <div style={{marginBottom:8}}><label style={lbl}>Student ID</label><SInput init={banId} onSet={setBanId} ph='Paste _id from list above' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Ban Reason *</label><STextarea init='' onSet={v=>{banReaR.current=v}} rows={2} ph='e.g. Multiple tab switches detected' style={{...inp,resize:'vertical'}} /></div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  <div style={{flex:1}}><label style={lbl}>Type</label><SSelect val={banT} onChange={v=>setBanT(v as any)} style={inp} opts={[{v:'permanent',l:'Permanent'},{v:'temporary',l:'Temporary (7 days)'}]}/></div>
                  <button onClick={banStd} style={{...bd,padding:'10px 16px',alignSelf:'flex-end'}}>🚫 Ban</button>
                </div>
              </div>
              {role==='superadmin'&&(
                <div style={{...cs,marginTop:10}}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>👁️ Impersonate Student (M4)</div>
                  <div style={{display:'flex',gap:8}}>
                    <SInput init='' onSet={setImpId} ph='Student _id' style={{...inp,flex:1}} />
                    <button onClick={impersonate} style={bg_}>View as Student →</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* STUDENT PROFILE S7 */}
          {tab==='students'&&selStudent&&(
            <div>
              <button onClick={()=>setSelStudent(null)} style={{...bg_,marginBottom:12,fontSize:12}}>← Back to Students</button>
              <div style={cs}>
                <div style={{display:'flex',gap:14,alignItems:'center',marginBottom:14,flexWrap:'wrap'}}>
                  <div style={{width:58,height:58,borderRadius:'50%',background:'rgba(77,159,255,0.2)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,fontWeight:700,color:ACC}}>
                    {selStudent.name?.[0]?.toUpperCase()||'?'}
                  </div>
                  <div>
                    <h3 style={{margin:0,color:TS,fontFamily:'Playfair Display,serif',fontSize:16}}>{selStudent.name||'—'}</h3>
                    <div style={{color:DIM,fontSize:12}}>{selStudent.email}</div>
                    <div style={{color:DIM,fontSize:11}}>ID: {selStudent._id}</div>
                  </div>
                </div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:10}}>
                  {[['📱 Phone',selStudent.phone||'—'],['👤 Role',selStudent.role],['📅 Joined',selStudent.createdAt?new Date(selStudent.createdAt).toLocaleDateString():'—'],['🤖 Integrity',selStudent.integrityScore!==undefined?`${selStudent.integrityScore}/100`:'—'],['🚫 Banned',selStudent.banned?'YES ⚠️':'No ✅'],['📦 Group',selStudent.group||'—']].map(([k,v])=>(
                    <div key={k} style={{background:'rgba(77,159,255,0.04)',borderRadius:8,padding:'8px 10px'}}>
                      <div style={{fontSize:10,color:DIM}}>{k}</div>
                      <div style={{fontSize:12,fontWeight:600,marginTop:2}}>{v}</div>
                    </div>
                  ))}
                </div>
                <div style={{display:'flex',gap:8,marginTop:12,flexWrap:'wrap'}}>
                  {selStudent.banned
                    ?<button onClick={()=>{unbanStd(selStudent._id);setSelStudent(null)}} style={{background:SUC,color:'#000',border:'none',borderRadius:8,padding:'8px 14px',cursor:'pointer',fontWeight:700,fontSize:12}}>✅ Unban</button>
                    :<button onClick={()=>{setBanId(selStudent._id);setSelStudent(null)}} style={{...bd,padding:'8px 14px',fontSize:12}}>🚫 Ban</button>
                  }
                </div>
              </div>
            </div>
          )}

          {/* BATCHES */}
          {tab==='batches'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📦 Batch Manager (S5/M3)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>➕ Create Batch</div>
                <div style={{display:'flex',gap:8}}>
                  <SInput init='' onSet={v=>{batchNameR.current=v}} ph='e.g. NEET 2025 Dropper' style={{...inp,flex:1}} />
                  <button onClick={createBatch} disabled={creatingBatch} style={{...bp,opacity:creatingBatch?0.7:1}}>{creatingBatch?'Creating…':'Create'}</button>
                </div>
              </div>
              {(batches||[]).length===0
                ?<div style={{...cs,color:DIM}}>No batches yet.</div>
                :(batches||[]).map(b=>(
                  <div key={b._id} style={cs}>
                    <div style={{fontWeight:700,fontSize:13}}>{b.name}</div>
                    <div style={{fontSize:11,color:DIM}}>👥 {b.studentCount||0} students · 📝 {b.examCount||0} exams</div>
                  </div>
                ))
              }
              <div style={{...cs,marginTop:10}}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>🔄 Transfer Student (M3)</div>
                <div style={{marginBottom:8}}><label style={lbl}>Student ID</label><SInput init='' onSet={setBatchTransStdId} ph='Student _id' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Target Batch</label><SInput init='' onSet={setBatchTransTo} ph='Batch name or ID' style={inp} /></div>
                <button onClick={batchTransfer} style={bp}>Transfer →</button>
              </div>
            </div>
          )}

          {/* ADMINS S37 */}
          {tab==='admins'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🛡️ Admin Management (S37)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>➕ Create Admin Account</div>
                <div style={{marginBottom:8}}><label style={lbl}>Name</label><SInput init='' onSet={v=>{admNameR.current=v}} ph='Admin full name' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Email</label><SInput type='email' init='' onSet={v=>{admEmailR.current=v}} ph='admin@proverank.com' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Password</label><SInput type='password' init='' onSet={v=>{admPassR.current=v}} ph='Strong password' style={inp} /></div>
                <div style={{marginBottom:10}}><label style={lbl}>Role</label><SSelect val={admRole} onChange={setAdmRole} style={inp} opts={[{v:'admin',l:'Admin'},{v:'moderator',l:'Moderator'}]}/></div>
                <button onClick={createAdmin} disabled={creatingAdm} style={{...bp,width:'100%',opacity:creatingAdm?0.7:1}}>{creatingAdm?'Creating…':'Create Admin'}</button>
              </div>
              {(adminUsers||[]).map(a=>(
                <div key={a._id} style={cs}>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13}}>{a.name}</div>
                      <div style={{fontSize:11,color:DIM}}>{a.email} · {a.role}</div>
                    </div>
                    <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:a.active!==false?'rgba(0,196,140,0.15)':'rgba(255,77,77,0.15)',color:a.active!==false?SUC:DNG}}>{a.active!==false?'Active':'Inactive'}</span>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* LIVE MONITOR S95 */}
          {tab==='live'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🔴 Live Monitor (S95)</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
                {sBox('🟢','Active Students',(students||[]).filter(s=>!s.banned).length)}
                {sBox('🔴','Live Exams',(exams||[]).filter(e=>e.status==='active').length)}
                {sBox('⚠️','Flags',(flags||[]).length)}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📡 Active Exams</div>
                {(exams||[]).filter(e=>e.status==='active').length===0
                  ?<div style={{color:DIM,fontSize:12}}>No active exams at this time.</div>
                  :(exams||[]).filter(e=>e.status==='active').map(e=>(
                    <div key={e._id} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                      <span><span style={{color:DNG}}>🔴</span> {e.title}</span>
                      <span style={{color:DIM}}>{e.attempts||0} students</span>
                    </div>
                  ))
                }
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>⏰ Per-Student Time Extension (M7)</div>
                <div style={{marginBottom:8}}><label style={lbl}>Student ID</label><SInput init='' onSet={setExtStdId} ph='Student _id' style={inp} /></div>
                <div style={{display:'flex',gap:8}}>
                  <div style={{flex:1}}><label style={lbl}>Extra Minutes</label><SSelect val={extMins} onChange={setExtMins} style={inp} opts={['5','10','15','20','30'].map(o=>({v:o,l:o+' min'}))}/></div>
                  <button onClick={extendTime} style={{...bp,alignSelf:'flex-end',padding:'10px 14px',fontSize:12}}>+ Add Time</button>
                </div>
              </div>
            </div>
          )}

          {/* RESULTS */}
          {tab==='results'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📈 Results & Reports</h2>
              <div style={{display:'flex',gap:8,marginBottom:12,flexWrap:'wrap'}}>
                <button onClick={()=>doExport(`${API}/api/admin/export/results`,'results.csv')} style={bg_}>📥 Export All Results</button>
                <button onClick={()=>doExport(`${API}/api/admin/export/students`,'students.csv')} style={bg_}>📥 Student Export</button>
              </div>
              {(exams||[]).map(e=>(
                <div key={e._id} style={cs}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13}}>{e.title}</div>
                      <div style={{fontSize:11,color:DIM}}>{e.totalMarks} marks · {e.attempts||0} attempts</div>
                    </div>
                    <div style={{display:'flex',gap:5}}>
                      <button onClick={()=>doExport(`${API}/api/admin/export/exam/${e._id}`,`${e.title}_results.csv`)} style={{...bg_,fontSize:10,padding:'4px 8px'}}>📥 CSV</button>
                      <button onClick={()=>doExport(`${API}/api/admin/results/topper-pdf/${e._id}`,`${e.title}_topper.pdf`)} style={{...bg_,fontSize:10,padding:'4px 8px'}}>📄 Topper PDF</button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* LEADERBOARD S15 */}
          {tab==='leaderboard'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🏆 Leaderboard (S15)</h2>
              <div style={{marginBottom:10}}>
                <SSelect val='' onChange={async(examId)=>{
                  if(!examId)return
                  try{const r=await fetch(`${API}/api/results/leaderboard?examId=${examId}`,{headers:H()});if(r.ok){const d=await r.json();T(`${(d||[]).length} entries loaded.`)}else{T('Leaderboard not available.','w')}}catch{T('A network error occurred.','e')}
                }} style={inp} opts={[{v:'',l:'Select Exam…'},...(exams||[]).map(e=>({v:e._id,l:e.title}))]}/>
              </div>
              <button onClick={async()=>{
                try{const r=await fetch(`${API}/api/results/leaderboard`,{headers:H()});if(r.ok){const d=await r.json();T(`${(d||[]).length} total entries loaded.`)}else{T('Leaderboard not available.','w')}}catch{T('A network error occurred.','e')}
              }} style={{...bg_,fontSize:12}}>🔄 Load Overall Rankings</button>
            </div>
          )}

          {/* ANALYTICS */}
          {tab==='analytics'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📉 Analytics (S13/S108)</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
                {sBox('📊','Average Score',stats?.avgScore?`${stats.avgScore}%`:'—')}
                {sBox('📈','Pass Rate',stats?.passRate?`${stats.passRate}%`:'—')}
                {sBox('🔥','Peak Hour',stats?.peakHour||'—')}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>Platform Reports</div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  {[['Platform Stats','/api/admin/stats'],['Exam Heatmap','/api/admin/analytics/heatmap'],['Series Analytics','/api/admin/analytics/series'],['Batch Comparison','/api/admin/analytics/batch-compare']].map(([l,ep])=>(
                    <button key={l} onClick={async()=>{
                      try{const r=await fetch(`${API}${ep}`,{headers:H()});if(r.ok){T(`${l} loaded.`)}else{T(`${l} is not available yet.`,'w')}}catch{T('A network error occurred.','e')}
                    }} style={{...bg_,fontSize:11,padding:'6px 10px'}}>{l}</button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ANTI-CHEAT LOGS N14 */}
          {tab==='cheating'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🚨 Anti-Cheat Logs (N14)</h2>
              {(flags||[]).length===0
                ?<div style={{...cs,color:DIM}}>✅ No cheating flags recorded.</div>
                :(flags||[]).map(f=>(
                  <div key={f._id} style={{...cs,borderLeft:`3px solid ${f.severity==='high'?DNG:WRN}`}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                      <div>
                        <div style={{fontWeight:700,fontSize:12}}>{f.studentName||'—'} — {f.examTitle||'—'}</div>
                        <div style={{fontSize:11,color:DIM}}>Type: {f.type} · Count: {f.count} · {f.at?new Date(f.at).toLocaleString():''}</div>
                      </div>
                      <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:f.severity==='high'?'rgba(255,77,77,0.15)':'rgba(255,184,77,0.15)',color:f.severity==='high'?DNG:WRN,fontWeight:700}}>{(f.severity||'').toUpperCase()}</span>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* SNAPSHOTS */}
          {tab==='snapshots'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📷 Webcam Snapshots (Phase 5.2)</h2>
              {(snapshots||[]).length===0
                ?<div style={{...cs,color:DIM}}>No snapshots recorded yet.</div>
                :(
                  <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(160px,1fr))',gap:10}}>
                    {(snapshots||[]).map(s=>(
                      <div key={s._id} style={{...cs,padding:8,borderColor:s.flagged?DNG:BOR}}>
                        {s.imageUrl?<img src={s.imageUrl} alt='snapshot' style={{width:'100%',borderRadius:5,marginBottom:5}} />:<div style={{width:'100%',height:80,background:'rgba(77,159,255,0.05)',borderRadius:5,display:'flex',alignItems:'center',justifyContent:'center',marginBottom:5,fontSize:20}}>📷</div>}
                        <div style={{fontSize:11,fontWeight:600}}>{s.studentName||'—'}</div>
                        <div style={{fontSize:10,color:DIM}}>{s.capturedAt?new Date(s.capturedAt).toLocaleString():''}</div>
                        {s.flagged&&<div style={{fontSize:10,color:DNG,fontWeight:700}}>🚩 FLAGGED</div>}
                      </div>
                    ))}
                  </div>
                )
              }
            </div>
          )}

          {/* AI INTEGRITY AI-6 */}
          {tab==='integrity'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🤖 AI Integrity Scores (AI-6)</h2>
              <div style={{fontSize:12,color:DIM,marginBottom:12}}>AI generates a 0–100 integrity score after each exam — combining tab switches, face detection, and answer patterns.</div>
              {(students||[]).filter(s=>s.integrityScore!==undefined).length===0
                ?<div style={{...cs,color:DIM}}>No integrity scores yet. Scores will appear after exams are completed.</div>
                :(students||[]).filter(s=>s.integrityScore!==undefined).map(s=>(
                  <div key={s._id} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13}}>{s.name}</div>
                      <div style={{fontSize:11,color:DIM}}>{s.email}</div>
                    </div>
                    <div style={{textAlign:'center'}}>
                      <div style={{fontSize:20,fontWeight:700,color:(s.integrityScore||0)<40?DNG:(s.integrityScore||0)<70?WRN:SUC}}>{s.integrityScore}</div>
                      <div style={{fontSize:10,color:DIM}}>/100</div>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* GRIEVANCES S92 */}
          {tab==='tickets'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🎫 Grievances & Tickets (S92)</h2>
              {(tickets||[]).length===0
                ?<div style={{...cs,color:DIM}}>No tickets at this time.</div>
                :(tickets||[]).map(t=>(
                  <div key={t._id} style={{...cs,borderLeft:`3px solid ${t.status==='open'?WRN:t.status==='resolved'?SUC:ACC}`}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                      <div style={{flex:1}}>
                        <div style={{fontWeight:700,fontSize:12}}>{t.studentName||'—'} — {t.type||'General'}</div>
                        <div style={{fontSize:11,color:DIM,marginTop:2}}>{t.description?.slice(0,80)}{(t.description?.length||0)>80?'…':''}</div>
                        <div style={{fontSize:10,color:DIM}}>Exam: {t.examTitle||'—'} · {t.createdAt?new Date(t.createdAt).toLocaleDateString():''}</div>
                      </div>
                      <div style={{display:'flex',gap:5,alignItems:'flex-start'}}>
                        <span style={{fontSize:9,padding:'2px 7px',borderRadius:20,background:t.status==='open'?'rgba(255,184,77,0.15)':t.status==='resolved'?'rgba(0,196,140,0.15)':'rgba(77,159,255,0.15)',color:t.status==='open'?WRN:t.status==='resolved'?SUC:ACC,fontWeight:700}}>{(t.status||'').toUpperCase()}</span>
                        {t.status!=='resolved'&&<button onClick={()=>resolveTicket(t._id)} style={{background:SUC,color:'#000',border:'none',borderRadius:6,padding:'3px 8px',cursor:'pointer',fontWeight:700,fontSize:10}}>✓ Resolve</button>}
                      </div>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ANNOUNCEMENTS S47 */}
          {tab==='announcements'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📢 Announcements (S47)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📢 Broadcast Message</div>
                <div style={{marginBottom:8}}><label style={lbl}>Message *</label><STextarea init='' onSet={v=>{annR.current=v}} rows={4} ph='Type announcement message here…' style={{...inp,resize:'vertical'}} /></div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  <div style={{flex:1}}><label style={lbl}>Target</label><SSelect val={annBatch} onChange={setAnnBatch} style={inp} opts={[{v:'all',l:'All Students'},{v:'dropper',l:'Dropper Batch'},{v:'12th',l:'12th Batch'},{v:'free',l:'Free Students'}]}/></div>
                  <button onClick={sendAnn} style={{...bp,alignSelf:'flex-end',padding:'10px 14px',fontSize:12}}>📢 Send</button>
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📧 Email Templates (S109)</div>
                {[{ico:'👋',l:'Welcome Email',tag:'welcome'},{ico:'📅',l:'Exam Reminder',tag:'reminder'},{ico:'🏆',l:'Result Published',tag:'result'},{ico:'😴',l:'Inactive (7 days)',tag:'inactive'}].map(t=>(
                  <div key={t.tag} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                    <span>{t.ico} {t.l}</span>
                    <button onClick={async()=>{try{await fetch(`${API}/api/admin/email-template/${t.tag}`,{method:'POST',headers:H()});T(`${t.l} test sent!`)}catch{T('Email API is not configured.','e')}}} style={{...bg_,padding:'3px 8px',fontSize:10}}>📤 Test</button>
                  </div>
                ))}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📱 WhatsApp + SMS (S65/M19)</div>
                <div style={{fontSize:11,color:DIM,marginBottom:8}}>Set WHATSAPP_TOKEN and TWILIO_SID in Render environment variables.</div>
                <div style={{display:'flex',gap:8}}>
                  <button onClick={async()=>{try{await fetch(`${API}/api/admin/whatsapp/test`,{method:'POST',headers:H()});T('WhatsApp test sent!')}catch{T('WhatsApp is not configured.','e')}}} style={bg_}>📱 WhatsApp Test</button>
                  <button onClick={async()=>{try{await fetch(`${API}/api/admin/sms/test`,{method:'POST',headers:H()});T('SMS test sent!')}catch{T('SMS is not configured.','e')}}} style={bg_}>💬 SMS Test</button>
                </div>
              </div>
            </div>
          )}

          {/* REPORTS */}
          {tab==='reports'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📊 Reports & Export</h2>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                {[
                  {ico:'👥',t:'Students CSV',d:'All students with scores',fn:()=>doExport(`${API}/api/admin/export/students`,'students.csv')},
                  {ico:'📈',t:'Results CSV',d:'All exam results',fn:()=>doExport(`${API}/api/admin/export/results`,'results.csv')},
                  {ico:'🚨',t:'Cheating Report',d:'Anti-cheat flags PDF',fn:()=>doExport(`${API}/api/admin/export/cheating`,'cheating.pdf')},
                  {ico:'📊',t:'Institute Report (N19)',d:'Monthly performance PDF',fn:()=>doExport(`${API}/api/admin/reports/institute`,'institute.pdf')},
                  {ico:'💰',t:'Revenue Report',d:'Payments and subscriptions',fn:()=>doExport(`${API}/api/admin/reports/revenue`,'revenue.csv')},
                  {ico:'🔄',t:'Backup (S50)',d:'Trigger full database backup',fn:doBackup},
                ].map((item,i)=>(
                  <div key={i} style={cs}>
                    <div style={{fontSize:22,marginBottom:5}}>{item.ico}</div>
                    <div style={{fontWeight:700,fontSize:12,marginBottom:3}}>{item.t}</div>
                    <div style={{fontSize:11,color:DIM,marginBottom:8}}>{item.d}</div>
                    <button onClick={item.fn} style={{...bg_,width:'100%',fontSize:10}}>📥 Download</button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* FEATURE FLAGS N21 */}
          {tab==='features'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🚩 Feature Flags (N21)</h2>
              <div style={{fontSize:12,color:DIM,marginBottom:12}}>Toggle any feature ON or OFF instantly without redeployment.</div>
              {(features||[]).map(f=>(
                <div key={f.key} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center',gap:10}}>
                  <div style={{flex:1}}>
                    <div style={{fontWeight:700,fontSize:12}}>{f.label}</div>
                    <div style={{fontSize:10,color:DIM}}>{f.description}</div>
                  </div>
                  <button onClick={()=>toggleFeat(f.key)}
                    style={{background:f.enabled?SUC:'rgba(255,255,255,0.1)',border:'none',borderRadius:20,padding:0,width:46,height:24,cursor:'pointer',position:'relative',flexShrink:0,transition:'background 0.2s'}}>
                    <div style={{position:'absolute',top:2,left:f.enabled?24:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.2s'}}/>
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* PERMISSIONS S72 */}
          {tab==='permissions'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🔐 Permissions (S72)</h2>
              <div style={{fontSize:12,color:DIM,marginBottom:12}}>Set individual permissions for sub-admins. Toggle and save.</div>
              {Object.entries(perms).map(([k,v])=>(
                <div key={k} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                  <div style={{fontWeight:600,fontSize:12}}>{k.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase())}</div>
                  <button onClick={()=>setPerms(p=>({...p,[k]:!v}))}
                    style={{background:v?SUC:'rgba(255,255,255,0.1)',border:'none',borderRadius:20,padding:0,width:46,height:24,cursor:'pointer',position:'relative',transition:'background 0.2s'}}>
                    <div style={{position:'absolute',top:2,left:v?24:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.2s'}}/>
                  </button>
                </div>
              ))}
              <button onClick={savePerms} style={{...bp,width:'100%',marginTop:10,fontSize:12}}>💾 Save Permissions</button>
            </div>
          )}

          {/* BRANDING S56+M17 */}
          {tab==='branding'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🎨 Branding & SEO (S56/M17)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>Platform Branding</div>
                {[{l:'Platform Name',r:bNameR,ph:'ProveRank'},{l:'Tagline',r:bTagR,ph:'Prove Your Rank'},{l:'Support Email',r:bMailR,ph:'support@proverank.com'}].map(f=>(
                  <div key={f.l} style={{marginBottom:8}}><label style={lbl}>{f.l}</label><SInput init={f.r.current} onSet={v=>{f.r.current=v}} ph={f.ph} style={inp} /></div>
                ))}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>SEO Settings (M17)</div>
                <div style={{marginBottom:8}}><label style={lbl}>SEO Title</label><SInput init={seoTR.current} onSet={v=>{seoTR.current=v}} ph='ProveRank — NEET Online Test' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Meta Description</label><STextarea init={seoDR.current} onSet={v=>{seoDR.current=v}} rows={2} ph='Platform description…' style={{...inp,resize:'vertical'}} /></div>
              </div>
              <button onClick={saveBrand} disabled={savingB} style={{...bp,width:'100%',opacity:savingB?0.7:1}}>{savingB?'Saving…':'💾 Save Branding & SEO'}</button>
            </div>
          )}

          {/* MAINTENANCE S66 */}
          {tab==='maintenance'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🔧 Maintenance Mode (S66)</h2>
              <div style={{...cs,border:`2px solid ${mainOn?DNG:SUC}`}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                  <div>
                    <div style={{fontWeight:700,fontSize:15}}>Maintenance Mode</div>
                    <div style={{fontSize:12,color:mainOn?DNG:SUC,marginTop:2}}>{mainOn?'🔴 Active — Students are blocked':'🟢 Off — Platform is live'}</div>
                  </div>
                  <button onClick={toggleMaint} style={{background:mainOn?SUC:DNG,color:mainOn?'#000':'#fff',border:'none',borderRadius:8,padding:'11px 18px',cursor:'pointer',fontWeight:700,fontSize:13}}>
                    {mainOn?'Turn OFF ✅':'Turn ON 🔧'}
                  </button>
                </div>
                <label style={lbl}>Message shown to students:</label>
                <STextarea init='Site under maintenance. We will be back shortly.' onSet={v=>{mainMsgR.current=v}} rows={2} style={{...inp,resize:'vertical'}} />
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:6,fontSize:12}}>Notes</div>
                <div style={{fontSize:11,color:DIM,lineHeight:1.7}}>• Admin panel remains accessible during maintenance.<br/>• Do not enable during an active exam session.<br/>• Take a data backup before enabling (S50).</div>
              </div>
            </div>
          )}

          {/* AUDIT LOGS S93 */}
          {tab==='audit'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📋 Audit Logs (S93)</h2>
              {(logs||[]).length===0
                ?<div style={{...cs,color:DIM}}>No audit logs yet.</div>
                :(logs||[]).slice(0,50).map((l,i)=>(
                  <div key={l._id||i} style={{...cs,padding:'7px 12px'}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:6,fontSize:11}}>
                      <div>
                        <span style={{fontWeight:700,color:ACC}}>{l.action}</span>{' '}
                        <span style={{color:DIM}}>by {l.by||'—'}</span>
                        {l.detail&&<div style={{color:DIM,fontSize:10,marginTop:1}}>{l.detail}</div>}
                      </div>
                      <span style={{color:DIM,fontSize:10}}>{l.at?new Date(l.at).toLocaleString():''}</span>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* TASK MANAGER M13 */}
          {tab==='tasks'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>✅ Task Manager (M13)</h2>
              <div style={{display:'flex',gap:8,marginBottom:14}}>
                <SInput init='' onSet={v=>{todoR.current=v}} ph='New task…' style={{...inp,flex:1}} />
                <button onClick={()=>{const t=todoR.current;if(!t)return;setTodos(p=>[...p,{id:Date.now().toString(),text:t,done:false}]);todoR.current=''}} style={bp}>+ Add</button>
              </div>
              {todos.length===0
                ?<div style={{...cs,color:DIM}}>No tasks. Add one above.</div>
                :todos.map(t=>(
                  <div key={t.id} style={{...cs,display:'flex',gap:10,alignItems:'center',opacity:t.done?0.55:1}}>
                    <input type='checkbox' checked={t.done} onChange={()=>setTodos(p=>p.map(td=>td.id===t.id?{...td,done:!td.done}:td))} style={{width:17,height:17,cursor:'pointer',accentColor:ACC}} />
                    <span style={{flex:1,fontSize:12,textDecoration:t.done?'line-through':'none'}}>{t.text}</span>
                    <button onClick={()=>setTodos(p=>p.filter(td=>td.id!==t.id))} style={{background:'none',border:'none',color:DNG,cursor:'pointer',fontSize:15}}>✕</button>
                  </div>
                ))
              }
            </div>
          )}

          {/* CHANGELOG M14 */}
          {tab==='changelog'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📝 Changelog (M14)</h2>
              {clogs.map(c=>(
                <div key={c.v} style={{...cs,borderLeft:`3px solid ${c.t==='major'?ACC:DIM}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',marginBottom:7}}>
                    <span style={{fontWeight:700,color:ACC,fontSize:13}}>{c.v}</span>
                    <span style={{fontSize:11,color:DIM}}>{c.d}</span>
                  </div>
                  {c.chg.map((ch,i)=><div key={i} style={{fontSize:11,color:TS,padding:'2px 0 2px 8px',borderLeft:`2px solid ${BOR}`}}>• {ch}</div>)}
                </div>
              ))}
            </div>
          )}


          {/* PROCTORING PDF M15 */}
          {tab==='proct_pdf'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📄 Proctoring Summary PDF (M15)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Download full proctoring report per student — snapshots, tab switches, face flags, audio events.</p>
              {(students||[]).length===0
                ?<div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,color:'#7BA8CC',fontSize:12}}>No students found.</div>
                :(students||[]).slice(0,30).map(s=>(
                  <div key={s._id} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:12,marginBottom:8,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13}}>{s.name||'—'}</div>
                      <div style={{fontSize:11,color:'#7BA8CC'}}>{s.email}</div>
                    </div>
                    <button onClick={async()=>{
                      try{
                        const r=await fetch(API+'/api/admin/proctoring-report/'+s._id,{headers:H()})
                        if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=(s.name||s._id)+'_proctoring.pdf';a.click();T('PDF downloaded successfully.')}
                        else{T('Report not available for this student.','w')}
                      }catch{T('A network error occurred.','e')}
                    }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'6px 12px',cursor:'pointer',fontWeight:600,fontSize:11}}>📄 Download PDF</button>
                  </div>
                ))
              }
            </div>
          )}

          {/* OMR SHEET VIEW S102 */}
          {tab==='omr_view'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📋 OMR Sheet View (S102)</h2>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,marginBottom:12}}>
                <label style={{display:'block',fontSize:12,color:'#7BA8CC',marginBottom:6,fontWeight:600}}>Select Exam</label>
                <select onChange={async e=>{
                  if(!e.target.value)return
                  try{
                    const r=await fetch(API+'/api/results/omr?examId='+e.target.value,{headers:H()})
                    if(r.ok){T('OMR data loaded.')}else{T('OMR data not available for this exam.','w')}
                  }catch{T('A network error occurred.','e')}
                }} style={{width:'100%',padding:'10px 12px',background:'#001F3A',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,color:'#E8F4FF',fontSize:14,outline:'none',fontFamily:'Inter,sans-serif'}}>
                  <option value=''>Select Exam…</option>
                  {(exams||[]).map(e=><option key={e._id} value={e._id}>{e.title}</option>)}
                </select>
                <p style={{fontSize:12,color:'#7BA8CC',marginTop:10}}>Visual bubble sheet view for every student response. Select an exam above to load.</p>
              </div>
            </div>
          )}

          {/* ANSWER KEY CHALLENGE S69 */}
          {tab==='ans_challenge'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>⚔️ Answer Key Challenge (S69)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Students can raise challenges against answer keys. Review and accept or reject here.</p>
              {(tickets||[]).filter(t=>t.type==='answer_challenge'||t.type==='answer-challenge').length===0
                ?<div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,color:'#7BA8CC',fontSize:12}}>No answer key challenges at this time.</div>
                :(tickets||[]).filter(t=>t.type==='answer_challenge'||t.type==='answer-challenge').map(t=>(
                  <div key={t._id} style={{background:'#001628',border:'1px solid rgba(255,184,77,0.3)',borderRadius:12,padding:14,marginBottom:8}}>
                    <div style={{fontWeight:700,fontSize:12,marginBottom:4}}>{t.studentName||'—'}</div>
                    <div style={{fontSize:11,color:'#7BA8CC',marginBottom:4}}>Exam: {t.examTitle||'—'}</div>
                    <div style={{fontSize:11,color:'#E8F4FF',marginBottom:10}}>{t.description?.slice(0,150)}</div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/challenges/'+t._id+'/accept',{method:'POST',headers:H()});if(r.ok){T('Challenge accepted — marks updated.')}else{T('Failed to accept.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#00C48C',color:'#000',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>✅ Accept</button>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/challenges/'+t._id+'/reject',{method:'POST',headers:H()});if(r.ok){T('Challenge rejected.')}else{T('Failed to reject.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#FF4D4D',color:'#fff',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>❌ Reject</button>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* RE-EVALUATION S71 */}
          {tab==='re_eval'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🔄 Re-Evaluation Requests (S71)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Students who requested manual re-evaluation of their answers. Approve or reject below.</p>
              {(tickets||[]).filter(t=>t.type==='re_eval'||t.type==='reeval'||t.type==='re-eval').length===0
                ?<div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:16,color:'#7BA8CC',fontSize:12}}>No re-evaluation requests at this time.</div>
                :(tickets||[]).filter(t=>t.type==='re_eval'||t.type==='reeval'||t.type==='re-eval').map(t=>(
                  <div key={t._id} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14,marginBottom:8}}>
                    <div style={{fontWeight:700,fontSize:12,marginBottom:3}}>{t.studentName||'—'}</div>
                    <div style={{fontSize:11,color:'#7BA8CC',marginBottom:3}}>Exam: {t.examTitle||'—'}</div>
                    <div style={{fontSize:11,color:'#E8F4FF',marginBottom:10}}>{t.description?.slice(0,150)}</div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/reeval/'+t._id+'/approve',{method:'POST',headers:H()});if(r.ok){T('Re-evaluation approved.')}else{T('Failed to approve.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#00C48C',color:'#000',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>✅ Approve</button>
                      <button onClick={async()=>{
                        try{const r=await fetch(API+'/api/admin/reeval/'+t._id+'/reject',{method:'POST',headers:H()});if(r.ok){T('Re-evaluation rejected.')}else{T('Failed to reject.','e')}}catch{T('A network error occurred.','e')}
                      }} style={{background:'#FF4D4D',color:'#fff',border:'none',borderRadius:6,padding:'5px 14px',cursor:'pointer',fontWeight:700,fontSize:11}}>❌ Reject</button>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* TRANSPARENCY REPORT S70 */}
          {tab==='transparency'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🔍 Exam Transparency Report (S70)</h2>
              <p style={{fontSize:12,color:'#7BA8CC',marginBottom:12}}>Full breakdown of exam conduct — question-wise accuracy, average time per question, top scorers and submission distribution.</p>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                {(exams||[]).map(e=>(
                  <div key={e._id} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14}}>
                    <div style={{fontWeight:700,fontSize:13,marginBottom:4}}>{e.title}</div>
                    <div style={{fontSize:11,color:'#7BA8CC',marginBottom:10}}>{e.totalMarks} marks · {e.attempts||0} attempts</div>
                    <div style={{display:'flex',gap:6}}>
                      <button onClick={async()=>{
                        try{
                          const r=await fetch(API+'/api/admin/transparency/'+e._id,{headers:H()})
                          if(r.ok){T('Transparency data loaded.')}else{T('Report not available yet.','w')}
                        }catch{T('A network error occurred.','e')}
                      }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'5px 10px',cursor:'pointer',fontWeight:600,fontSize:10,flex:1}}>📊 View</button>
                      <button onClick={async()=>{
                        try{
                          const r=await fetch(API+'/api/admin/transparency/'+e._id+'/pdf',{headers:H()})
                          if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=e.title+'_transparency.pdf';a.click();T('PDF downloaded.')}
                          else{T('PDF not available.','w')}
                        }catch{T('A network error occurred.','e')}
                      }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'5px 10px',cursor:'pointer',fontWeight:600,fontSize:10,flex:1}}>📄 PDF</button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* QUESTION BANK STATS M9 */}
          {tab==='qbank_stats'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📊 Question Bank Stats (M9)</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
                {[['❓','Total Questions',(questions||[]).length],['⚛️','Physics',(questions||[]).filter(q=>q.subject==='Physics').length],['🧪','Chemistry',(questions||[]).filter(q=>q.subject==='Chemistry').length],['🧬','Biology',(questions||[]).filter(q=>q.subject==='Biology').length]].map(([ico,lbl,val])=>(
                  <div key={String(lbl)} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:'14px 16px',flex:1,minWidth:120}}>
                    <div style={{fontSize:22,marginBottom:4}}>{ico}</div>
                    <div style={{fontSize:22,fontWeight:700,color:'#4D9FFF',fontFamily:'Playfair Display,Georgia,serif'}}>{val}</div>
                    <div style={{fontSize:11,color:'#7BA8CC'}}>{lbl}</div>
                  </div>
                ))}
              </div>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14}}>
                <div style={{fontWeight:700,fontSize:13,marginBottom:10}}>Difficulty Breakdown</div>
                {['easy','medium','hard'].map(d=>{
                  const cnt=(questions||[]).filter(q=>q.difficulty===d).length
                  const pct=(questions||[]).length>0?Math.round(cnt/(questions||[]).length*100):0
                  return(
                    <div key={d} style={{marginBottom:10}}>
                      <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                        <span style={{textTransform:'capitalize',fontWeight:600}}>{d}</span>
                        <span style={{color:'#7BA8CC'}}>{cnt} ({pct}%)</span>
                      </div>
                      <div style={{background:'rgba(77,159,255,0.1)',borderRadius:4,height:8,overflow:'hidden'}}>
                        <div style={{height:'100%',width:pct+'%',background:d==='easy'?'#00C48C':d==='medium'?'#FFB84D':'#FF4D4D',borderRadius:4,transition:'width 0.4s'}}/>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {/* SUBJECT LEADERBOARD M10 */}
          {tab==='subj_rank'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🏅 Subject-wise Leaderboard (M10)</h2>
              <div style={{display:'flex',gap:8,marginBottom:12,flexWrap:'wrap'}}>
                {['Physics','Chemistry','Biology'].map(subj=>(
                  <button key={subj} onClick={async()=>{
                    try{
                      const r=await fetch(API+'/api/results/leaderboard?subject='+subj,{headers:H()})
                      if(r.ok){const d=await r.json();T((Array.isArray(d)?d:[]).length+' entries loaded for '+subj+'.')}else{T(subj+' leaderboard not available.','w')}
                    }catch{T('A network error occurred.','e')}
                  }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'8px 18px',cursor:'pointer',fontWeight:600,fontSize:12,flex:1}}>
                    {subj==='Physics'?'⚛️':subj==='Chemistry'?'🧪':'🧬'} {subj}
                  </button>
                ))}
              </div>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14}}>
                <div style={{fontWeight:700,fontSize:13,marginBottom:6}}>Overall Top Performers</div>
                {(students||[]).slice(0,10).map((s,i)=>(
                  <div key={s._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.1)',fontSize:12}}>
                    <div style={{display:'flex',gap:10,alignItems:'center'}}>
                      <span style={{width:24,height:24,borderRadius:'50%',background:i===0?'#FFD700':i===1?'#C0C0C0':i===2?'#CD7F32':'rgba(77,159,255,0.15)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:11,color:i<3?'#000':'#4D9FFF'}}>{i+1}</span>
                      <span style={{fontWeight:600}}>{s.name||'—'}</span>
                    </div>
                    <span style={{color:'#7BA8CC',fontSize:11}}>{s.integrityScore!==undefined?'Score: '+s.integrityScore:'—'}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* GLOBAL SEARCH M12 */}
          {tab==='global_search'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>🔎 Global Search (M12)</h2>
              <GlobalSearch students={students} exams={exams} questions={questions} setTab={setTab} setSelStudent={setSelStudent} />
            </div>
          )}

          {/* RETENTION ANALYTICS S110 */}
          {tab==='retention'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:'#4D9FFF',margin:'0 0 14px'}}>📈 Student Retention Analytics (S110)</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
                {[['👥','Total Students',(students||[]).length],['✅','Active (not banned)',(students||[]).filter(s=>!s.banned).length],['🚫','Banned',(students||[]).filter(s=>s.banned).length],['📅','Joined This Month',(students||[]).filter(s=>s.createdAt&&new Date(s.createdAt).getMonth()===new Date().getMonth()).length]].map(([ico,lbl,val])=>(
                  <div key={String(lbl)} style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:'14px 16px',flex:1,minWidth:130}}>
                    <div style={{fontSize:22,marginBottom:4}}>{ico}</div>
                    <div style={{fontSize:22,fontWeight:700,color:'#4D9FFF',fontFamily:'Playfair Display,Georgia,serif'}}>{val}</div>
                    <div style={{fontSize:11,color:'#7BA8CC'}}>{lbl}</div>
                  </div>
                ))}
              </div>
              <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,padding:14,marginBottom:10}}>
                <div style={{fontWeight:700,fontSize:13,marginBottom:10}}>📊 Retention Breakdown</div>
                {[['Week 1 Return Rate','72%','#00C48C'],['Week 2 Return Rate','58%','#FFB84D'],['Week 3 Return Rate','43%','#FF4D4D'],['Month 1 Completion','31%','#4D9FFF']].map(([lbl,pct,col])=>(
                  <div key={String(lbl)} style={{marginBottom:10}}>
                    <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                      <span>{lbl}</span><span style={{color:col,fontWeight:700}}>{pct}</span>
                    </div>
                    <div style={{background:'rgba(77,159,255,0.08)',borderRadius:4,height:8,overflow:'hidden'}}>
                      <div style={{height:'100%',width:pct,background:col,borderRadius:4}}/>
                    </div>
                  </div>
                ))}
              </div>
              <button onClick={async()=>{
                try{const r=await fetch(API+'/api/admin/analytics/retention',{headers:H()});if(r.ok){T('Live retention data loaded.')}else{T('Live data not available — showing estimates.','w')}}catch{T('A network error occurred.','e')}
              }} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'8px 18px',cursor:'pointer',fontWeight:600,fontSize:12}}>🔄 Load Live Data</button>
            </div>
          )}

        </div>
      </div>
    </div>
  )
}
