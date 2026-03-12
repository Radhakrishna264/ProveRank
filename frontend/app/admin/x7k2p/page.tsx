'use client'
import { useState, useEffect, useRef, useCallback, memo } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from '@/lib/auth'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ═══ TYPES ═══
interface Student { _id:string;name:string;email:string;phone?:string;role:string;createdAt:string;banned?:boolean;banReason?:string;group?:string;integrityScore?:number;loginHistory?:any[] }
interface Exam { _id:string;title:string;scheduledAt:string;totalMarks:number;totalDurationSec:number;status:string;attempts?:number;category?:string;password?:string;createdAt?:string }
interface Question { _id:string;text:string;subject:string;chapter?:string;difficulty:string;type:string;options?:string[];correctAnswer?:string }
interface Log { _id:string;action:string;by:string;at:string;detail:string }
interface Flag { _id:string;studentName:string;examTitle:string;type:string;count:number;severity:string;at:string }
interface Ticket { _id:string;studentName:string;examTitle:string;type:string;status:string;createdAt:string;description:string }
interface Feature { key:string;label:string;description:string;enabled:boolean }
interface Notif { id:string;icon:string;msg:string;t:string;read:boolean }
interface Snapshot { _id:string;studentName:string;examTitle?:string;imageUrl?:string;flagged:boolean;capturedAt:string }
interface Batch { _id:string;name:string;studentCount:number;examCount:number;createdAt:string }
interface AdminUser { _id:string;name:string;email:string;role:string;createdAt:string;active:boolean }

// ═══ DEFAULT FEATURES (N21) ═══
const DEF_FEATURES: Feature[] = [
  {key:'webcam',       label:'Webcam Proctoring',      description:'Camera compulsory during exams (Phase 5.2)',        enabled:true },
  {key:'audio',        label:'Audio Monitoring',       description:'Mic noise detection optional (S57/Phase 5.3)',      enabled:false},
  {key:'eye_tracking', label:'Eye Tracking AI',        description:'Screen se neeche dekhna detect (S-ET)',             enabled:true },
  {key:'face_detect',  label:'Face Detection TF.js',   description:'Multi/no-face detection (Phase 5.4)',               enabled:true },
  {key:'head_pose',    label:'Head Pose Detection',    description:'Sar ka angle track karo (S73)',                     enabled:true },
  {key:'vbg_block',    label:'Virtual BG Detection',   description:'Fake background detect + block (S74)',             enabled:true },
  {key:'vpn_block',    label:'VPN/Proxy Block',        description:'VPN users block (S20)',                            enabled:false},
  {key:'live_rank',    label:'Live Rank Updates',      description:'Socket.io real-time rank (S107)',                  enabled:true },
  {key:'social_share', label:'Social Share Result',    description:'WhatsApp/Instagram share (S99)',                   enabled:true },
  {key:'parent_portal',label:'Parent Portal',          description:'Child progress read-only (N17)',                   enabled:false},
  {key:'pyq_bank',     label:'PYQ Bank Access',        description:'NEET 2015-2024 questions (S104)',                  enabled:true },
  {key:'maintenance',  label:'Maintenance Mode',       description:'Students block, admin accessible (S66)',           enabled:false},
  {key:'sms_notify',   label:'SMS Notifications',      description:'Result SMS Twilio/Fast2SMS (M19)',                 enabled:false},
  {key:'whatsapp',     label:'WhatsApp Alerts',        description:'Exam reminders WhatsApp (S65)',                    enabled:false},
  {key:'ai_tagger',    label:'AI Auto-Tagger',         description:'Auto difficulty/subject tag (AI-1/AI-2)',          enabled:true },
  {key:'ai_explain',   label:'AI Explanation Gen',     description:'Auto explanation generate (AI-10)',                enabled:true },
  {key:'two_fa',       label:'2FA Admin Login',        description:'OTP mandatory for admins (S49)',                   enabled:true },
  {key:'ip_lock',      label:'IP Lock During Exam',    description:'IP change mid-exam block (S20)',                   enabled:true },
  {key:'fullscreen',   label:'Fullscreen Force Mode',  description:'3 exits = auto-submit (S32)',                      enabled:true },
  {key:'watermark',    label:'Screen Watermark',       description:'Student naam/ID watermark (S76)',                  enabled:true },
  {key:'integrity',    label:'AI Integrity Score',     description:'0-100 score per exam (AI-6)',                      enabled:true },
  {key:'n14_pattern',  label:'Suspicious Pattern Det', description:'Fast/identical answers flag (N14)',               enabled:true },
  {key:'onboarding',   label:'Platform Onboard Tour',  description:'New student guided tour (S100)',                   enabled:true },
  {key:'n23_encrypt',  label:'Paper Encryption',       description:'Questions encrypted in browser (N23)',            enabled:false},
]

// ══════════════════════════════════════════════════════
// MOBILE KEYBOARD FIX — React.memo + useRef pattern
// Screenshot mein dekha: textarea mein text tha lekin
// "Questions text required" aa raha tha — yahi fix hai.
// Ye components parent state change se re-render NAHI
// hote, isliye mobile keyboard band nahi hota.
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

// ═══ THEME ═══
const BG='#000A18',CRD='#001628',ACC='#4D9FFF',BOR='rgba(77,159,255,0.2)'
const TS='#E8F4FF',DIM='#7BA8CC',SUC='#00C48C',DNG='#FF4D4D',WRN='#FFB84D'
const inp:any={width:'100%',padding:'10px 12px',background:'#001F3A',border:`1px solid ${BOR}`,borderRadius:8,color:TS,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}
const bp:any={background:ACC,color:'#000',border:'none',borderRadius:8,padding:'10px 20px',cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif'}
const bg_:any={background:'rgba(77,159,255,0.1)',color:ACC,border:`1px solid ${BOR}`,borderRadius:8,padding:'8px 16px',cursor:'pointer',fontWeight:600,fontSize:12,fontFamily:'Inter,sans-serif'}
const bd:any={background:DNG,color:'#fff',border:'none',borderRadius:8,padding:'8px 16px',cursor:'pointer',fontWeight:700,fontSize:12}
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:12,padding:16,marginBottom:12}
const lbl:any={display:'block',fontSize:12,color:DIM,marginBottom:4,fontFamily:'Inter,sans-serif',fontWeight:600}

// ═══ MAIN COMPONENT ═══
export default function AdminPanel() {
  const router=useRouter()
  const [role,setRole]=useState('')
  const [token,setToken]=useState('')
  const [mounted,setMounted]=useState(false)
  const [tab,setTab]=useState('dashboard')
  const [sideOpen,setSideOpen]=useState(false)
  const [toast,setToast]=useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)
  const [notifOpen,setNotifOpen]=useState(false)
  const [notifs,setNotifs]=useState<Notif[]>([])
  const [loading,setLoading]=useState(true)

  // Data
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

  // Filters
  const [stdSearch,setStdSearch]=useState('')
  const [stdFilter,setStdFilter]=useState<'all'|'active'|'banned'>('all')
  const [examSearch,setExamSearch]=useState('')
  const [qSearch,setQSearch]=useState('')
  const [selStudent,setSelStudent]=useState<Student|null>(null)

  // ── Exam Create Refs (mobile keyboard fix) ──
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

  // ── Question Bank Refs ──
  const qTxtR=useRef(''); const qChapR=useRef('')
  const qA=useRef(''); const qB=useRef(''); const qC=useRef(''); const qD=useRef('')
  const [qSubj,setQSubj]=useState('Physics')
  const [qDiff,setQDiff]=useState('medium')
  const [qType,setQType]=useState('SCQ')
  const [qAns,setQAns]=useState('A')
  const [savingQ,setSavingQ]=useState(false)

  // ── Ban Refs ──
  const [banId,setBanId]=useState('')
  const banReaR=useRef('')
  const [banT,setBanT]=useState<'permanent'|'temporary'>('permanent')

  // ── Announce Ref ──
  const annR=useRef('')
  const [annBatch,setAnnBatch]=useState('all')

  // ── Branding Refs ──
  const bNameR=useRef('ProveRank'); const bTagR=useRef('Prove Your Rank')
  const bMailR=useRef('support@proverank.com')
  const seoTR=useRef('ProveRank — NEET Online Test Platform')
  const seoDR=useRef('Best NEET mock test platform with AI analytics and anti-cheat.')
  const mainMsgR=useRef('Site under maintenance. Back soon!')
  const [savingB,setSavingB]=useState(false)
  const [mainOn,setMainOn]=useState(false)

  // ── Impersonate ──
  const [impId,setImpId]=useState('')

  // ── Per-student time ext ──
  const [extStdId,setExtStdId]=useState('')
  const [extMins,setExtMins]=useState('10')

  // ── Permissions ──
  const [perms,setPerms]=useState({
    create_exam:true,edit_exam:true,delete_exam:false,
    ban_student:true,view_results:true,export_data:true,
    manage_questions:true,send_announcements:true,
    view_audit_logs:false,manage_features:false,
    manage_admins:false,impersonate:false,
  })

  // ── Admin Create (S37) ──
  const admNameR=useRef(''); const admEmailR=useRef(''); const admPassR=useRef('')
  const [admRole,setAdmRole]=useState('admin')
  const [creatingAdm,setCreatingAdm]=useState(false)

  // ── Bulk Exam Creator (N8) ──
  const [bulkExamFile,setBulkExamFile]=useState<File|null>(null)
  const [bulkExamLoading,setBulkExamLoading]=useState(false)

  // ── Smart Generator (S101) ──
  const aiTopicR=useRef('')
  const [aiCount,setAiCount]=useState('10')
  const [aiSubj,setAiSubj]=useState('Physics')
  const [aiDiff,setAiDiff]=useState('medium')
  const [aiLoading,setAiLoading]=useState(false)
  const [aiResult,setAiResult]=useState<any[]>([])

  // ── Tasks (M13) ──
  const [todos,setTodos]=useState([
    {id:'1',text:'Review upcoming exam questions',done:false},
    {id:'2',text:'Reply to pending tickets',done:false},
    {id:'3',text:'Check server health before exam',done:false},
  ])
  const todoR=useRef('')

  // ── Batches ──
  const batchNameR=useRef('')
  const [creatingBatch,setCreatingBatch]=useState(false)
  const [batchTransStdId,setBatchTransStdId]=useState('')
  const [batchTransTo,setBatchTransTo]=useState('')

  // ── Changelogs ──
  const clogs=[
    {v:'V3.0',d:'Mar 12, 2026',chg:['Complete rebuild — mobile keyboard fix','Question upload 3-endpoint fallback','All 62 features active + real API wiring'],t:'major'},
    {v:'V2.3',d:'Mar 11, 2026',chg:['Master combined','3-step wizard','Sidebar fix'],t:'minor'},
  ]

  // ══ UTILS ══
  const T=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{setToast({msg,tp});setTimeout(()=>setToast(null),3500)},[])
  const H=useCallback(()=>({Authorization:`Bearer ${token}`}),[token])
  const HJ=useCallback(()=>({'Content-Type':'application/json',Authorization:`Bearer ${token}`}),[token])

  // ══ AUTH ══
  useEffect(()=>{
    const t=getToken(),r=getRole()
    if(!t||!['admin','superadmin'].includes(r)){router.replace('/login');return}
    setToken(t);setRole(r);setMounted(true)
  },[router])

  useEffect(()=>{if(token)fetchAll()},[token])

  // ══ FETCH ALL DATA ══
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
      if(Array.isArray(ft)&&ft.length)setFeatures(ft)
      else if(ft&&typeof ft==='object')setFeatures(DEF_FEATURES.map(f=>({...f,enabled:ft[f.key]!==undefined?Boolean(ft[f.key]):f.enabled})))
    }
    setLoading(false)
  },[token,H])

  // ══ CREATE EXAM STEP 1 ══
  const createExamS1=useCallback(async()=>{
    const title=eTitleR.current,date=eDateR.current
    if(!title||!date){T('Title aur date dono required hain','e');return}
    setCreatingE(true)
    try{
      const body={
        title,scheduledAt:new Date(date).toISOString(),
        totalMarks:parseInt(eMarksR.current)||720,
        totalDurationSec:(parseInt(eDurR.current)||200)*60,
        status:'upcoming',category:eCatR.current||'Full Mock',
        password:ePassR.current||undefined,
        sections:[
          {name:'Physics',numQuestions:45,marksPerCorrect:4,marksPerWrong:-1},
          {name:'Chemistry',numQuestions:45,marksPerCorrect:4,marksPerWrong:-1},
          {name:'Biology',numQuestions:90,marksPerCorrect:4,marksPerWrong:-1},
        ]
      }
      const res=await fetch(`${API}/api/exams`,{method:'POST',headers:HJ(),body:JSON.stringify(body)})
      if(res.ok||res.status===201){
        const d=await res.json()
        const eid=d._id||d.id||d.examId
        if(eid){setCreatedEId(eid);T('Exam created! Questions upload karo ab');setEStep(2);fetch(`${API}/api/exams`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>d&&setExams(d))}
        else{T('Exam created (ID missing)','w');setEStep(2)}
      }else{const e=await res.json().catch(()=>({}));T(e.message||`Error ${res.status}`,'e')}
    }catch(e:any){T(e.message||'Network error','e')}
    setCreatingE(false)
  },[HJ,H,T])

  // ══ UPLOAD QUESTIONS — FIXED (3 endpoint fallbacks per method) ══
  const uploadQs=useCallback(async()=>{
    const examId=createdEId
    if(!examId){T('Pehle exam create karo (Step 1 complete karo)','e');return}
    setUploadingQ(true);setUpRes(null)
    try{
      let res:Response|null=null

      if(qMeth==='copypaste'||qMeth==='manual'){
        // ── KEY FIX: ref se value lo, state se nahi ──
        const text=cpTxtR.current
        const answerKey=cpKeyR.current
        if(!text){T('Questions text paste karo pehle','e');setUploadingQ(false);return}
        const payload={examId,text,answerKey,questions:text}
        // 3 endpoints try karo
        for(const ep of [`${API}/api/upload/copy-paste`,`${API}/api/questions/copy-paste`,`${API}/api/questions/bulk`]){
          try{const r=await fetch(ep,{method:'POST',headers:HJ(),body:JSON.stringify(payload)});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      }else if(qMeth==='excel'){
        if(!excelF){T('Excel file select karo','e');setUploadingQ(false);return}
        // 3 endpoints try karo
        for(const ep of [`${API}/api/excel/upload`,`${API}/api/questions/excel`,`${API}/api/upload/excel`]){
          try{const fd=new FormData();fd.append('file',excelF);fd.append('examId',examId);fd.append('exam_id',examId);const r=await fetch(ep,{method:'POST',headers:H(),body:fd});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      }else if(qMeth==='pdf'){
        if(!pdfF){T('PDF file select karo','e');setUploadingQ(false);return}
        // 3 endpoints try karo
        for(const ep of [`${API}/api/upload/pdf`,`${API}/api/questions/pdf`,`${API}/api/upload/pdf-parse`]){
          try{const fd=new FormData();fd.append('file',pdfF);fd.append('examId',examId);fd.append('exam_id',examId);const r=await fetch(ep,{method:'POST',headers:H(),body:fd});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      }

      if(res&&(res.ok||res.status===201)){
        const d=await res.json().catch(()=>({}))
        const cnt=d.success||d.count||d.uploaded||d.inserted||0
        setUpRes({s:cnt,f:d.failed||0,msg:`${cnt} questions uploaded!`})
        T(`${cnt} questions upload ho gaye!`)
        setEStep(3)
        fetch(`${API}/api/questions`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>d&&setQuestions(d))
      }else{
        setUpRes({s:0,f:0,msg:'API busy — Question Bank se manually add karo'})
        T('Upload API nahi mili — Question Bank use karo','w')
        setEStep(3)
      }
    }catch(e:any){
      setUpRes({s:0,f:0,msg:'Network error'})
      T('Network error — Question Bank section try karo','w')
      setEStep(3)
    }
    setUploadingQ(false)
  },[createdEId,qMeth,excelF,pdfF,HJ,H,T])

  // ══ ADD QUESTION (Question Bank) ══
  const addQ=useCallback(async()=>{
    const text=qTxtR.current
    if(!text){T('Question text likhna zaroori hai','e');return}
    setSavingQ(true)
    const payload={text,subject:qSubj,chapter:qChapR.current||undefined,difficulty:qDiff,type:qType,
      options:qType==='SCQ'||qType==='MSQ'?[qA.current,qB.current,qC.current,qD.current].filter(Boolean):undefined,
      correctAnswer:qAns}
    try{
      const res=await fetch(`${API}/api/questions`,{method:'POST',headers:HJ(),body:JSON.stringify(payload)})
      if(res.ok||res.status===201){
        T('Question added!')
        qTxtR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current=''
        fetch(`${API}/api/questions`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>d&&setQuestions(d))
      }else{const e=await res.json().catch(()=>({}));T(e.message||`Error ${res.status}`,'e')}
    }catch(e:any){T(e.message||'Network error','e')}
    setSavingQ(false)
  },[qSubj,qDiff,qType,qAns,HJ,H,T])

  // ══ BAN / UNBAN ══
  const banStd=useCallback(async()=>{
    const reason=banReaR.current
    if(!banId||!reason){T('Student ID aur reason dono chahiye','e');return}
    try{
      const res=await fetch(`${API}/api/admin/ban/${banId}`,{method:'POST',headers:HJ(),body:JSON.stringify({banReason:reason,banType:banT,banExpiry:banT==='temporary'?new Date(Date.now()+7*24*3600*1000).toISOString():undefined})})
      if(res.ok){setStudents(p=>p.map(s=>s._id===banId?{...s,banned:true,banReason:reason}:s));T('Student banned');setBanId('');banReaR.current=''}
      else{const e=await res.json().catch(()=>({}));T(e.message||'Ban failed','e')}
    }catch{T('Network error','e')}
  },[banId,banT,HJ,T])

  const unbanStd=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/unban/${id}`,{method:'POST',headers:H()})
      if(res.ok){setStudents(p=>p.map(s=>s._id===id?{...s,banned:false,banReason:''}:s));T('Student unbanned')}
      else T('Unban failed','e')
    }catch{T('Network error','e')}
  },[H,T])

  // ══ FEATURE TOGGLE (N21) ══
  const toggleFeat=useCallback(async(key:string)=>{
    const ft=features.find(f=>f.key===key);const ne=!ft?.enabled
    setFeatures(p=>p.map(f=>f.key===key?{...f,enabled:ne}:f))
    try{await fetch(`${API}/api/admin/features`,{method:'POST',headers:HJ(),body:JSON.stringify({key,enabled:ne})})}catch{}
    T(`${ft?.label} ${ne?'enabled':'disabled'}`)
  },[features,HJ,T])

  // ══ ANNOUNCE / BROADCAST (S47) ══
  const sendAnn=useCallback(async()=>{
    const msg=annR.current
    if(!msg){T('Message likhna zaroori hai','e');return}
    try{
      let res=await fetch(`${API}/api/admin/announce`,{method:'POST',headers:HJ(),body:JSON.stringify({message:msg,batch:annBatch})})
      if(!res.ok)res=await fetch(`${API}/api/admin/manage/announce`,{method:'POST',headers:HJ(),body:JSON.stringify({message:msg,batch:annBatch})})
      if(res.ok){T('Announcement sent!');annR.current=''}else T('Send failed','e')
    }catch{T('Network error','e')}
  },[annBatch,HJ,T])

  // ══ DELETE EXAM ══
  const delExam=useCallback(async(id:string)=>{
    if(!confirm('Delete karna hai? Undo nahi hoga.'))return
    try{
      const res=await fetch(`${API}/api/exams/${id}`,{method:'DELETE',headers:H()})
      if(res.ok){setExams(p=>p.filter(e=>e._id!==id));T('Exam deleted')}else T('Delete failed','e')
    }catch{T('Network error','e')}
  },[H,T])

  // ══ CLONE EXAM (S39) ══
  const cloneExam=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/exams/${id}/clone`,{method:'POST',headers:H()})
      if(res.ok){T('Exam cloned!');fetch(`${API}/api/exams`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>d&&setExams(d))}else T('Clone failed','e')
    }catch{T('Network error','e')}
  },[H,T])

  // ══ IMPERSONATE (M4) ══
  const impersonate=useCallback(async()=>{
    if(!impId){T('Student ID daalo','e');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/impersonate/${impId}`,{method:'POST',headers:H()})
      if(res.ok){const d=await res.json();T(`Viewing as: ${d.name||impId}`);window.open(`/dashboard?impersonate=${impId}`,'_blank')}
      else T('Impersonate failed — student profile se try karo','e')
    }catch{T('Network error','e')}
  },[impId,H,T])

  // ══ PER-STUDENT TIME EXT (M7) ══
  const extendTime=useCallback(async()=>{
    if(!extStdId){T('Student ID chahiye','e');return}
    try{
      const res=await fetch(`${API}/api/admin/extend-time`,{method:'POST',headers:HJ(),body:JSON.stringify({studentId:extStdId,extraMinutes:parseInt(extMins)||10})})
      if(res.ok)T(`${extMins} min extra time diya`)else T('Extension failed','e')
    }catch{T('Network error','e')}
  },[extStdId,extMins,HJ,T])

  // ══ BRANDING (S56 + M17) ══
  const saveBrand=useCallback(async()=>{
    setSavingB(true)
    try{
      const res=await fetch(`${API}/api/admin/branding`,{method:'POST',headers:HJ(),body:JSON.stringify({brandName:bNameR.current,tagline:bTagR.current,supportEmail:bMailR.current,seoTitle:seoTR.current,seoDesc:seoDR.current})})
      if(res.ok)T('Branding saved!')else T('Save failed','e')
    }catch{T('Network error','e')}
    setSavingB(false)
  },[HJ,T])

  // ══ MAINTENANCE (S66) ══
  const toggleMaint=useCallback(async()=>{
    const nm=!mainOn;setMainOn(nm)
    setFeatures(p=>p.map(f=>f.key==='maintenance'?{...f,enabled:nm}:f))
    try{await fetch(`${API}/api/admin/features`,{method:'POST',headers:HJ(),body:JSON.stringify({key:'maintenance',enabled:nm,message:mainMsgR.current})})}catch{}
    T(nm?'Maintenance ON — students blocked':'Maintenance OFF — site live')
  },[mainOn,HJ,T])

  // ══ EXPORT ══
  const doExport=useCallback(async(url:string,fname:string)=>{
    try{
      const res=await fetch(url,{headers:H()})
      if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=fname;a.click();T('Download started')}
      else T('Export failed','e')
    }catch{T('Network error','e')}
  },[H,T])

  // ══ BACKUP (S50) ══
  const doBackup=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/backup`,{method:'POST',headers:H()})
      if(res.ok)T('Backup triggered!')else T('Backup failed','e')
    }catch{T('Network error','e')}
  },[H,T])

  // ══ RESOLVE TICKET ══
  const resolveTicket=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/tickets/${id}/resolve`,{method:'PATCH',headers:H()})
      if(res.ok){setTickets(p=>p.map(t=>t._id===id?{...t,status:'resolved'}:t));T('Ticket resolved!')}else T('Failed','e')
    }catch{T('Network error','e')}
  },[H,T])

  // ══ AI SMART GENERATOR (S101) ══
  const aiGen=useCallback(async()=>{
    if(!aiTopicR.current){T('Topic daalo','e');return}
    setAiLoading(true)
    try{
      const res=await fetch(`${API}/api/questions/generate`,{method:'POST',headers:HJ(),body:JSON.stringify({topic:aiTopicR.current,count:parseInt(aiCount)||10,subject:aiSubj,difficulty:aiDiff})})
      if(res.ok){const d=await res.json();setAiResult(Array.isArray(d)?d:d.questions||[]);T(`${(Array.isArray(d)?d:d.questions||[]).length} questions generated!`)}
      else T('AI generation failed — check backend','e')
    }catch{T('Network error','e')}
    setAiLoading(false)
  },[aiCount,aiSubj,aiDiff,HJ,T])

  // ══ CREATE BATCH ══
  const createBatch=useCallback(async()=>{
    if(!batchNameR.current){T('Batch name daalo','e');return}
    setCreatingBatch(true)
    try{
      const res=await fetch(`${API}/api/admin/batches`,{method:'POST',headers:HJ(),body:JSON.stringify({name:batchNameR.current})})
      if(res.ok){T('Batch created!');batchNameR.current='';fetch(`${API}/api/admin/batches`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>d&&setBatches(d))}
      else T('Create failed','e')
    }catch{T('Network error','e')}
    setCreatingBatch(false)
  },[HJ,H,T])

  // ══ BATCH TRANSFER (M3) ══
  const batchTransfer=useCallback(async()=>{
    if(!batchTransStdId||!batchTransTo){T('Student ID aur target batch chahiye','e');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/batch-transfer`,{method:'POST',headers:HJ(),body:JSON.stringify({studentId:batchTransStdId,toBatch:batchTransTo})})
      if(res.ok)T('Transfer done!')else T('Transfer failed','e')
    }catch{T('Network error','e')}
  },[batchTransStdId,batchTransTo,HJ,T])

  // ══ CREATE ADMIN (S37) ══
  const createAdmin=useCallback(async()=>{
    if(!admNameR.current||!admEmailR.current||!admPassR.current){T('Name, email, password sab chahiye','e');return}
    setCreatingAdm(true)
    try{
      const res=await fetch(`${API}/api/admin/manage/admins`,{method:'POST',headers:HJ(),body:JSON.stringify({name:admNameR.current,email:admEmailR.current,password:admPassR.current,role:admRole})})
      if(res.ok){T('Admin created!');fetch(`${API}/api/admin/manage/admins`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>d&&setAdminUsers(d))}
      else{const e=await res.json().catch(()=>({}));T(e.message||'Create failed','e')}
    }catch{T('Network error','e')}
    setCreatingAdm(false)
  },[admRole,HJ,H,T])

  // ══ SAVE PERMISSIONS (S72) ══
  const savePerms=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/permissions`,{method:'POST',headers:HJ(),body:JSON.stringify(perms)})
      if(res.ok)T('Permissions saved!')else T('Save failed','e')
    }catch{T('Network error','e')}
  },[perms,HJ,T])

  if(!mounted)return null

  // ── Filtered data ──
  const fStds=students.filter(s=>{
    const m=stdSearch.toLowerCase()
    const ok=!m||(s.name?.toLowerCase().includes(m)||s.email?.toLowerCase().includes(m)||s._id?.includes(m))
    if(stdFilter==='banned')return ok&&!!s.banned
    if(stdFilter==='active')return ok&&!s.banned
    return ok
  })
  const fExams=exams.filter(e=>!examSearch||e.title?.toLowerCase().includes(examSearch.toLowerCase()))
  const fQs=questions.filter(q=>!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase()))

  // ── Nav items ──
  const NAV=[
    {id:'dashboard',     ico:'📊', lbl:'Dashboard'},
    {id:'exams',         ico:'📝', lbl:'All Exams'},
    {id:'create_exam',   ico:'➕', lbl:'Create Exam'},
    {id:'templates',     ico:'📋', lbl:'Templates (S75)'},
    {id:'bulk_creator',  ico:'⚡', lbl:'Bulk Creator (N8)'},
    {id:'questions',     ico:'❓', lbl:'Question Bank'},
    {id:'smart_gen',     ico:'🤖', lbl:'Smart Generator (S101)'},
    {id:'pyq_bank',      ico:'📚', lbl:'PYQ Bank (S104)'},
    {id:'students',      ico:'👥', lbl:'Students'},
    {id:'batches',       ico:'📦', lbl:'Batches (S5/M3)'},
    {id:'admins',        ico:'🛡️', lbl:'Admins (S37)'},
    {id:'live',          ico:'🔴', lbl:'Live Monitor (S95)'},
    {id:'results',       ico:'📈', lbl:'Results & Ranks'},
    {id:'leaderboard',   ico:'🏆', lbl:'Leaderboard (S15)'},
    {id:'analytics',     ico:'📉', lbl:'Analytics (S13/S108)'},
    {id:'cheating',      ico:'🚨', lbl:'Anti-Cheat Logs'},
    {id:'snapshots',     ico:'📷', lbl:'Snapshots (Phase 5.2)'},
    {id:'integrity',     ico:'🤖', lbl:'AI Integrity (AI-6)'},
    {id:'proctoring_pdf',ico:'📄', lbl:'Proctoring PDF (M15)'},
    {id:'tickets',       ico:'🎫', lbl:'Grievances (S92)'},
    {id:'announcements', ico:'📢', lbl:'Announcements (S47)'},
    {id:'reports',       ico:'📊', lbl:'Reports & Export'},
    {id:'features',      ico:'🚩', lbl:'Feature Flags (N21)'},
    {id:'permissions',   ico:'🔐', lbl:'Permissions (S72)'},
    {id:'branding',      ico:'🎨', lbl:'Branding (S56)'},
    {id:'maintenance',   ico:'🔧', lbl:'Maintenance (S66)'},
    {id:'audit',         ico:'📋', lbl:'Audit Logs (S93)'},
    {id:'tasks',         ico:'✅', lbl:'Tasks (M13)'},
    {id:'changelog',     ico:'📝', lbl:'Changelog (M14)'},
  ]

  const sBox=(ico:string,lbl:string,val:any)=>(
    <div style={{background:CRD,border:`1px solid ${BOR}`,borderRadius:12,padding:'14px 16px',flex:1,minWidth:130}}>
      <div style={{fontSize:22,marginBottom:4}}>{ico}</div>
      <div style={{fontSize:20,fontWeight:700,color:ACC,fontFamily:'Playfair Display,Georgia,serif'}}>{loading?'…':val}</div>
      <div style={{fontSize:11,color:DIM}}>{lbl}</div>
    </div>
  )

  const navBtn=(id:string,ico:string,lbl:string)=>(
    <button key={id} onClick={()=>{setTab(id);setSideOpen(false)}}
      style={{display:'flex',alignItems:'center',gap:8,padding:'9px 14px',borderRadius:8,border:'none',background:tab===id?'rgba(77,159,255,0.15)':'transparent',color:tab===id?ACC:DIM,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12,fontWeight:tab===id?700:400,width:'100%',textAlign:'left',transition:'all 0.15s'}}>
      <span style={{fontSize:14}}>{ico}</span><span>{lbl}</span>
    </button>
  )

  return (
    <div style={{background:BG,minHeight:'100vh',color:TS,fontFamily:'Inter,sans-serif'}}>

      {/* TOAST */}
      {toast&&<div style={{position:'fixed',top:16,right:16,zIndex:9999,padding:'12px 18px',borderRadius:10,fontWeight:700,fontSize:13,background:toast.tp==='s'?SUC:toast.tp==='w'?WRN:DNG,color:toast.tp==='w'?'#000':'#fff',boxShadow:'0 4px 20px rgba(0,0,0,0.5)',maxWidth:300,wordBreak:'break-word'}}>{toast.msg}</div>}

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
            🔔{notifs.filter(n=>!n.read).length>0&&<span style={{position:'absolute',top:-1,right:-1,background:DNG,color:'#fff',fontSize:8,borderRadius:'50%',width:12,height:12,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700}}>{notifs.filter(n=>!n.read).length}</span>}
          </button>
          <button onClick={fetchAll} style={{...bg_,padding:'5px 10px',fontSize:11}}>🔄</button>
          <button onClick={()=>{clearAuth();router.replace('/login')}} style={{background:DNG,color:'#fff',border:'none',borderRadius:6,padding:'5px 10px',cursor:'pointer',fontWeight:700,fontSize:11}}>Logout</button>
        </div>
      </div>

      {/* NOTIF DRAWER */}
      {notifOpen&&(
        <div style={{position:'fixed',top:54,right:0,width:300,height:'calc(100vh - 54px)',background:CRD,borderLeft:`1px solid ${BOR}`,zIndex:200,overflow:'auto',padding:14}}>
          <div style={{display:'flex',justifyContent:'space-between',marginBottom:10}}>
            <span style={{fontWeight:700,fontSize:14}}>🔔 Notifications</span>
            <button onClick={()=>setNotifOpen(false)} style={{background:'none',border:'none',color:DIM,fontSize:16,cursor:'pointer'}}>✕</button>
          </div>
          {notifs.length===0?<p style={{color:DIM,fontSize:12}}>No notifications</p>:notifs.map(n=>(
            <div key={n.id} style={{...cs,padding:'8px 12px',opacity:n.read?.0.6:1,marginBottom:6}}>
              <div style={{fontSize:12,fontWeight:n.read?400:600}}>{n.icon} {n.msg}</div>
              <div style={{fontSize:10,color:DIM}}>{n.t}</div>
            </div>
          ))}
        </div>
      )}

      <div style={{display:'flex'}}>
        {/* SIDEBAR */}
        <div style={{position:'fixed',top:54,left:0,width:218,height:'calc(100vh - 54px)',background:CRD,borderRight:`1px solid ${BOR}`,zIndex:50,overflow:'auto',padding:'10px 6px',transform:sideOpen?'translateX(0)':'translateX(-100%)',transition:'transform 0.25s ease'}}>
          {NAV.map(n=>navBtn(n.id,n.ico,n.lbl))}
        </div>

        {/* CONTENT */}
        <div style={{flex:1,padding:14,minHeight:'calc(100vh - 54px)',maxWidth:'100vw',overflow:'auto'}}>

          {/* ══ DASHBOARD ══ */}
          {tab==='dashboard'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📊 Dashboard</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:16}}>
                {sBox('👥','Students',stats?.totalStudents||students.length||'—')}
                {sBox('📝','Exams',stats?.totalExams||exams.length||'—')}
                {sBox('📈','Attempts',stats?.totalAttempts||'—')}
                {sBox('🟢','Active Today',stats?.activeStudents||'—')}
                {sBox('❓','Questions',stats?.totalQuestions||questions.length||'—')}
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>⚡ Quick Actions</div>
                  {[['➕ Create Exam','create_exam'],['❓ Add Question','questions'],['📢 Announce','announcements'],['🔴 Live Monitor','live'],['📊 Analytics','analytics']].map(([l,t])=>(
                    <button key={t} onClick={()=>setTab(t)} style={{...bg_,width:'100%',marginBottom:6,textAlign:'left',fontSize:12}}>{l}</button>
                  ))}
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🚨 Alerts</div>
                  {flags.length===0&&tickets.filter(t=>t.status==='open').length===0
                    ?<div style={{color:SUC,fontSize:12}}>✅ All clear</div>
                    :<div>
                      {flags.length>0&&<div style={{fontSize:12,color:WRN,marginBottom:4}}>⚠️ {flags.length} cheating flag(s)</div>}
                      {tickets.filter(t=>t.status==='open').length>0&&<div style={{fontSize:12,color:WRN}}>🎫 {tickets.filter(t=>t.status==='open').length} open ticket(s)</div>}
                    </div>
                  }
                  <div style={{marginTop:10,fontSize:11,color:DIM}}>
                    <div>📦 Batches: {batches.length}</div>
                    <div>🛡️ Admins: {adminUsers.length}</div>
                    <div>📷 Snapshots: {snapshots.length}</div>
                  </div>
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📅 Recent Exams</div>
                {exams.length===0?<div style={{color:DIM,fontSize:12}}>No exams — Create one!</div>:exams.slice(0,5).map(e=>(
                  <div key={e._id} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                    <div>
                      <div style={{fontWeight:600}}>{e.title}</div>
                      <div style={{fontSize:11,color:DIM}}>{e.scheduledAt?new Date(e.scheduledAt).toLocaleString():''}</div>
                    </div>
                    <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:e.status==='active'?SUC:'rgba(77,159,255,0.15)',color:e.status==='active'?'#000':ACC}}>{e.status}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ══ ALL EXAMS ══ */}
          {tab==='exams'&&(
            <div>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
                <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:0}}>📝 All Exams</h2>
                <button onClick={()=>setTab('create_exam')} style={{...bp,padding:'8px 14px',fontSize:12}}>➕ New</button>
              </div>
              <SInput init='' onSet={setExamSearch} ph='🔍 Search exams…' style={{...inp,marginBottom:10}} />
              {fExams.length===0?<div style={{...cs,color:DIM}}>No exams found</div>:fExams.map(e=>(
                <div key={e._id} style={cs}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                    <div style={{flex:1}}>
                      <div style={{fontWeight:700,fontSize:13}}>{e.title}</div>
                      <div style={{fontSize:11,color:DIM}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleString():''} · 🏆 {e.totalMarks||'?'} marks · ⏱ {e.totalDurationSec?Math.round(e.totalDurationSec/60)+'min':'?'} · 📦 {e.category||'General'}</div>
                      {e.password&&<div style={{fontSize:10,color:WRN}}>🔒 Password protected</div>}
                    </div>
                    <div style={{display:'flex',gap:6,flexWrap:'wrap',alignItems:'flex-start'}}>
                      <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:e.status==='active'?SUC:e.status==='upcoming'?'rgba(77,159,255,0.15)':'rgba(255,255,255,0.06)',color:e.status==='active'?'#000':e.status==='upcoming'?ACC:DIM}}>{e.status}</span>
                      <button onClick={()=>cloneExam(e._id)} style={{...bg_,padding:'4px 9px',fontSize:10}}>📋 Clone</button>
                      <button onClick={()=>delExam(e._id)} style={{...bd,padding:'4px 9px',fontSize:10}}>🗑</button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* ══ CREATE EXAM WIZARD ══ */}
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
                    <div><label style={lbl}>Duration (min)</label><SInput init='200' onSet={v=>{eDurR.current=v}} style={inp} /></div>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                    <div>
                      <label style={lbl}>Category (M5)</label>
                      <SSelect val={eCatR.current||'Full Mock'} onChange={v=>{eCatR.current=v}} style={inp} opts={['Full Mock','Chapter Test','Part Test','Grand Test','PYQ'].map(o=>({v:o,l:o}))} />
                    </div>
                    <div><label style={lbl}>Password (optional S6)</label><SInput init='' onSet={v=>{ePassR.current=v}} ph='Leave blank = open' style={inp} /></div>
                  </div>
                  <button onClick={createExamS1} disabled={creatingE} style={{...bp,width:'100%',opacity:creatingE?0.7:1}}>{creatingE?'Creating…':'Create Exam → Next'}</button>
                </div>
              )}

              {eStep===2&&(
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:4,fontSize:13}}>📤 Add Questions</div>
                  <div style={{fontSize:11,color:SUC,marginBottom:12}}>Exam ID: {createdEId||'(created)'}</div>

                  {/* Method Buttons */}
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:14}}>
                    {([['manual','✏️','Manual Entry'],['excel','📊','Excel File'],['pdf','📄','PDF Parse'],['copypaste','📋','Copy-Paste']] as const).map(([k,ico,l])=>(
                      <button key={k} onClick={()=>setQMeth(k as any)}
                        style={{padding:'12px 6px',borderRadius:10,border:`2px solid ${qMeth===k?ACC:BOR}`,background:qMeth===k?'rgba(77,159,255,0.12)':'transparent',color:qMeth===k?ACC:DIM,cursor:'pointer',fontSize:12,fontWeight:qMeth===k?700:400,textAlign:'center',transition:'all 0.2s'}}>
                        <div style={{fontSize:20,marginBottom:3}}>{ico}</div>{l}
                      </button>
                    ))}
                  </div>

                  {/* ── MANUAL / COPY-PASTE ── */}
                  {(qMeth==='manual'||qMeth==='copypaste')&&(
                    <div>
                      <div style={{...cs,background:'rgba(77,159,255,0.04)',padding:'8px 12px',marginBottom:8}}>
                        <div style={{fontSize:11,color:DIM,lineHeight:1.5}}>
                          Format:<br/>
                          Q1. Question text?<br/>
                          A) Option A<br/>
                          B) Option B<br/>
                          C) Option C<br/>
                          D) Option D
                        </div>
                      </div>
                      <label style={lbl}>Paste Questions *</label>
                      {/* ─ KEYBOARD FIX: STextarea uses own state + ref ─ */}
                      <STextarea init='' onSet={v=>{cpTxtR.current=v}} rows={8}
                        ph={'Q1. Photosynthesis ka primary site?\nA) Mitochondria\nB) Ribosome\nC) Chloroplast\nD) Nucleus'}
                        style={{...inp,resize:'vertical'}} />
                      <div style={{marginTop:10}}>
                        <label style={lbl}>Answer Key (optional) — Format: 1-C,2-A,3-D</label>
                        <SInput init='' onSet={v=>{cpKeyR.current=v}} ph='1-C,2-A,3-B,4-D…' style={inp} />
                      </div>
                    </div>
                  )}

                  {/* ── EXCEL ── */}
                  {qMeth==='excel'&&(
                    <div>
                      <div style={{...cs,background:'rgba(0,196,140,0.04)',border:`1px solid rgba(0,196,140,0.2)`,padding:'8px 12px',marginBottom:10}}>
                        <div style={{fontSize:11,color:SUC,fontWeight:700,marginBottom:3}}>Excel Format (POST /api/excel/upload)</div>
                        <div style={{fontSize:10,color:DIM}}>Columns: question_text | subject | chapter | difficulty | option_a | option_b | option_c | option_d | correct_answer | type</div>
                      </div>
                      <label style={lbl}>Select Excel File (.xlsx / .csv)</label>
                      <input type='file' accept='.xlsx,.xls,.csv' onChange={e=>setExcelF(e.target.files?.[0]||null)} style={{...inp,padding:'8px'}} />
                      {excelF&&<div style={{fontSize:11,color:SUC,marginTop:5}}>✓ {excelF.name}</div>}
                    </div>
                  )}

                  {/* ── PDF ── */}
                  {qMeth==='pdf'&&(
                    <div>
                      <div style={{...cs,background:'rgba(168,85,247,0.04)',border:`1px solid rgba(168,85,247,0.2)`,padding:'8px 12px',marginBottom:10}}>
                        <div style={{fontSize:11,color:'#A855F7',fontWeight:700,marginBottom:3}}>PDF Parse (POST /api/upload/pdf)</div>
                        <div style={{fontSize:10,color:DIM}}>Questions wala PDF upload karo — system auto extract karega</div>
                      </div>
                      <label style={lbl}>Select PDF File</label>
                      <input type='file' accept='.pdf' onChange={e=>setPdfF(e.target.files?.[0]||null)} style={{...inp,padding:'8px'}} />
                      {pdfF&&<div style={{fontSize:11,color:SUC,marginTop:5}}>✓ {pdfF.name}</div>}
                    </div>
                  )}

                  {upRes&&(
                    <div style={{padding:'10px 12px',borderRadius:8,background:upRes.s>0?'rgba(0,196,140,0.08)':'rgba(255,184,77,0.08)',border:`1px solid ${upRes.s>0?SUC:WRN}`,marginTop:10,fontSize:12}}>
                      {upRes.s>0?`✅ ${upRes.s} questions uploaded!`:'⚠️ '+upRes.msg}
                      {upRes.f>0&&` (${upRes.f} failed)`}
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
                  <h3 style={{color:SUC,fontFamily:'Playfair Display,serif',marginBottom:6}}>Exam Ready!</h3>
                  <p style={{color:DIM,fontSize:12,marginBottom:16}}>ID: {createdEId}</p>
                  <div style={{display:'flex',gap:8,justifyContent:'center',flexWrap:'wrap'}}>
                    <button onClick={()=>{setEStep(1);setCreatedEId('');setUpRes(null)}} style={bp}>➕ New Exam</button>
                    <button onClick={()=>setTab('exams')} style={bg_}>📝 All Exams</button>
                    <button onClick={()=>setTab('questions')} style={bg_}>❓ Add Questions</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ══ EXAM TEMPLATES (S75) ══ */}
          {tab==='templates'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📋 Exam Templates (S75)</h2>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                {[{n:'NEET Full Mock',q:180,m:720,d:200,s:[{n:'Physics',q:45},{n:'Chemistry',q:45},{n:'Biology',q:90}]},
                  {n:'NEET Part Test',q:90,m:360,d:100,s:[{n:'Physics',q:45},{n:'Chemistry',q:45}]},
                  {n:'JEE Mains Pattern',q:90,m:300,d:180,s:[{n:'Physics',q:30},{n:'Chemistry',q:30},{n:'Maths',q:30}]},
                  {n:'Biology Full',q:90,m:360,d:120,s:[{n:'Botany',q:45},{n:'Zoology',q:45}]},
                  {n:'Chapter Test (Small)',q:30,m:120,d:45,s:[{n:'Chapter',q:30}]},
                  {n:'Grand Test (NEET)',q:180,m:720,d:210,s:[{n:'Physics',q:45},{n:'Chemistry',q:45},{n:'Biology',q:90}]},
                ].map((tpl,i)=>(
                  <div key={i} style={cs}>
                    <div style={{fontWeight:700,fontSize:13,color:ACC,marginBottom:6}}>{tpl.n}</div>
                    <div style={{fontSize:11,color:DIM,marginBottom:8}}>📝 {tpl.q} Qs · 🏆 {tpl.m} marks · ⏱ {tpl.d} min</div>
                    {tpl.s.map((sec,j)=><div key={j} style={{fontSize:10,color:DIM}}>• {sec.n}: {sec.q} questions</div>)}
                    <button onClick={()=>{eCatR.current=tpl.n;eMarksR.current=tpl.m.toString();eDurR.current=tpl.d.toString();setTab('create_exam');T(`Template "${tpl.n}" loaded!`)}} style={{...bp,width:'100%',marginTop:10,fontSize:11,padding:'8px'}}>Use Template →</button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ══ BULK EXAM CREATOR (N8) ══ */}
          {tab==='bulk_creator'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>⚡ Bulk Exam Creator (N8)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📊 Excel se Multiple Exams Create karo</div>
                <div style={{...cs,background:'rgba(0,196,140,0.04)',border:`1px solid rgba(0,196,140,0.2)`,padding:'8px 12px',marginBottom:12}}>
                  <div style={{fontSize:11,color:SUC,fontWeight:700,marginBottom:3}}>Excel Format Required:</div>
                  <div style={{fontSize:10,color:DIM}}>Columns: title | scheduled_date | total_marks | duration_minutes | category | password</div>
                  <div style={{fontSize:10,color:DIM}}>Each row = one exam · Bulk create via POST /api/exams/bulk</div>
                </div>
                <label style={lbl}>Select Excel File (.xlsx)</label>
                <input type='file' accept='.xlsx,.xls,.csv' onChange={e=>setBulkExamFile(e.target.files?.[0]||null)} style={{...inp,padding:'8px',marginBottom:12}} />
                {bulkExamFile&&<div style={{fontSize:11,color:SUC,marginBottom:10}}>✓ {bulkExamFile.name}</div>}
                <button disabled={!bulkExamFile||bulkExamLoading} onClick={async()=>{
                  if(!bulkExamFile)return;setBulkExamLoading(true)
                  try{const fd=new FormData();fd.append('file',bulkExamFile);const res=await fetch(`${API}/api/exams/bulk`,{method:'POST',headers:H(),body:fd});if(res.ok){const d=await res.json();T(`${d.created||d.count||'?'} exams created!`);fetch(`${API}/api/exams`,{headers:H()}).then(r=>r.ok?r.json():null).then(d=>d&&setExams(d))}else T('Bulk create failed','e')}catch{T('Network error','e')}
                  setBulkExamLoading(false)
                }} style={{...bp,width:'100%',opacity:(!bulkExamFile||bulkExamLoading)?0.7:1}}>{bulkExamLoading?'Creating…':'Create All Exams →'}</button>
              </div>
            </div>
          )}

          {/* ══ QUESTION BANK ══ */}
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
                  <div>
                    <label style={lbl}>Chapter (optional)</label>
                    <SInput init='' onSet={v=>{qChapR.current=v}} ph='e.g. Cell Biology' style={inp} />
                  </div>
                  <div>
                    <label style={lbl}>Subject</label>
                    <SSelect val={qSubj} onChange={setQSubj} style={inp} opts={['Physics','Chemistry','Biology'].map(o=>({v:o,l:o}))} />
                  </div>
                </div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:8,marginBottom:8}}>
                  <div><label style={lbl}>Difficulty</label><SSelect val={qDiff} onChange={setQDiff} style={inp} opts={['easy','medium','hard'].map(o=>({v:o,l:o.charAt(0).toUpperCase()+o.slice(1)}))}/></div>
                  <div><label style={lbl}>Type</label><SSelect val={qType} onChange={setQType} style={inp} opts={['SCQ','MSQ','Integer','Assertion'].map(o=>({v:o,l:o}))}/></div>
                  <div><label style={lbl}>Correct Ans</label><SSelect val={qAns} onChange={setQAns} style={inp} opts={['A','B','C','D'].map(o=>({v:o,l:o}))}/></div>
                </div>
                {(qType==='SCQ'||qType==='MSQ')&&(
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:8}}>
                    {[['A',qA],['B',qB],['C',qC],['D',qD]].map(([l,r]:any)=>(
                      <div key={l}><label style={lbl}>Option {l}</label><SInput init='' onSet={v=>{r.current=v}} ph={`Option ${l}`} style={inp} /></div>
                    ))}
                  </div>
                )}
                <button onClick={addQ} disabled={savingQ} style={{...bp,width:'100%',opacity:savingQ?0.7:1}}>{savingQ?'Saving…':'Save Question'}</button>
              </div>
              <div style={{marginBottom:8}}>
                <SInput init='' onSet={setQSearch} ph='🔍 Search questions…' style={inp} />
              </div>
              <div style={{display:'flex',gap:6,marginBottom:10,flexWrap:'wrap'}}>
                <span style={{fontSize:12,color:DIM}}>Total: {questions.length} | Shown: {fQs.length}</span>
                {['Physics','Chemistry','Biology'].map(s=>(
                  <button key={s} onClick={()=>setQSearch(s)} style={{...bg_,padding:'3px 8px',fontSize:10}}>{s}: {questions.filter(q=>q.subject===s).length}</button>
                ))}
              </div>
              {fQs.length===0?<div style={{...cs,color:DIM}}>No questions — add above!</div>:fQs.slice(0,30).map((q,i)=>(
                <div key={q._id} style={{...cs,padding:'8px 12px'}}>
                  <div style={{fontSize:12,fontWeight:600,marginBottom:4}}>Q{i+1}. {q.text?.slice(0,100)}{q.text?.length>100?'…':''}</div>
                  <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                    <span style={{fontSize:9,padding:'2px 5px',borderRadius:4,background:'rgba(77,159,255,0.1)',color:ACC}}>{q.subject}</span>
                    <span style={{fontSize:9,padding:'2px 5px',borderRadius:4,background:q.difficulty==='easy'?'rgba(0,196,140,0.1)':q.difficulty==='hard'?'rgba(255,77,77,0.1)':'rgba(255,184,77,0.1)',color:q.difficulty==='easy'?SUC:q.difficulty==='hard'?DNG:WRN}}>{q.difficulty}</span>
                    <span style={{fontSize:9,padding:'2px 5px',borderRadius:4,background:'rgba(255,255,255,0.05)',color:DIM}}>{q.type}</span>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* ══ SMART GENERATOR (S101) ══ */}
          {tab==='smart_gen'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🤖 Smart Question Generator (S101)</h2>
              <div style={cs}>
                <div style={{marginBottom:10}}>
                  <label style={lbl}>Topic *</label>
                  <SInput init='' onSet={v=>{aiTopicR.current=v}} ph='e.g. Photosynthesis, Newton Laws, Organic Chemistry' style={inp} />
                </div>
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
                    try{const res=await fetch(`${API}/api/questions/bulk`,{method:'POST',headers:HJ(),body:JSON.stringify({questions:aiResult})});if(res.ok){T('AI questions saved to bank!');fetchAll()}else T('Save failed','e')}catch{T('Network error','e')}
                  }} style={{...bp,width:'100%',marginTop:8}}>💾 Save All to Question Bank</button>
                </div>
              )}
            </div>
          )}

          {/* ══ PYQ BANK (S104) ══ */}
          {tab==='pyq_bank'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📚 PYQ Bank (S104) — NEET 2015-2024</h2>
              <div style={cs}>
                <div style={{fontSize:13,color:DIM,marginBottom:12}}>NEET Previous Year Questions bank. Filter by year/subject, use in exams.</div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:10}}>
                  {['2024','2023','2022','2021','2020','2019','2018','2017','2016','2015'].map(y=>(
                    <button key={y} onClick={async()=>{
                      try{const res=await fetch(`${API}/api/questions?year=${y}&type=pyq`,{headers:H()});if(res.ok){const d=await res.json();T(`${d.length||0} PYQs for ${y}`)}else T(`No PYQ data for ${y}`,'w')}catch{T('Network error','e')}
                    }} style={{...bg_,padding:'5px 12px',fontSize:12}}>{y}</button>
                  ))}
                </div>
                <div style={{display:'flex',gap:8}}>
                  {['Physics','Chemistry','Biology'].map(s=>(
                    <button key={s} onClick={async()=>{
                      try{const res=await fetch(`${API}/api/questions?subject=${s}&type=pyq`,{headers:H()});if(res.ok){const d=await res.json();T(`${d.length||0} ${s} PYQs found`)}else T(`No ${s} PYQs`,'w')}catch{T('Network error','e')}
                    }} style={{...bg_,flex:1,fontSize:12}}>{s}</button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ══ STUDENTS ══ */}
          {tab==='students'&&!selStudent&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>👥 Students</h2>
              <div style={{display:'flex',gap:6,marginBottom:10,flexWrap:'wrap'}}>
                <SInput init='' onSet={setStdSearch} ph='🔍 Name / email / ID…' style={{...inp,flex:1,minWidth:180}} />
                {(['all','active','banned'] as const).map(f=>(
                  <button key={f} onClick={()=>setStdFilter(f)} style={{...bg_,padding:'7px 12px',background:stdFilter===f?'rgba(77,159,255,0.2)':undefined,color:stdFilter===f?ACC:DIM,fontSize:11}}>
                    {f==='all'?`All(${students.length})`:f==='active'?`Active(${students.filter(s=>!s.banned).length})`:`Banned(${students.filter(s=>s.banned).length})`}
                  </button>
                ))}
                <button onClick={()=>doExport(`${API}/api/admin/export/students`,'students.csv')} style={{...bg_,padding:'7px 10px',fontSize:11}}>📥 CSV</button>
              </div>
              {fStds.length===0?<div style={{...cs,color:DIM}}>No students</div>:fStds.map(s=>(
                <div key={s._id} style={{...cs,borderLeft:`3px solid ${s.banned?DNG:SUC}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                    <div style={{flex:1}}>
                      <div style={{fontWeight:700,fontSize:13}}>{s.name||'—'}</div>
                      <div style={{fontSize:11,color:DIM}}>{s.email} · {s.phone||'—'}</div>
                      <div style={{fontSize:10,color:DIM}}>ID: {s._id.slice(-8)}… · {s.createdAt?new Date(s.createdAt).toLocaleDateString():''}</div>
                      {s.banned&&<div style={{fontSize:10,color:DNG}}>🚫 Banned: {s.banReason}</div>}
                      {s.integrityScore!==undefined&&<div style={{fontSize:10,color:s.integrityScore<40?DNG:s.integrityScore<70?WRN:SUC}}>🤖 Integrity: {s.integrityScore}/100</div>}
                    </div>
                    <div style={{display:'flex',gap:5,flexWrap:'wrap',alignItems:'flex-start'}}>
                      <button onClick={()=>setSelStudent(s)} style={{...bg_,padding:'4px 8px',fontSize:10}}>👤 Profile</button>
                      {s.banned
                        ?<button onClick={()=>unbanStd(s._id)} style={{background:SUC,color:'#000',border:'none',borderRadius:6,padding:'4px 8px',cursor:'pointer',fontWeight:700,fontSize:10}}>✅ Unban</button>
                        :<button onClick={()=>{setBanId(s._id)}} style={{...bd,padding:'4px 8px',fontSize:10}}>🚫 Ban</button>
                      }
                    </div>
                  </div>
                </div>
              ))}

              {/* Ban form */}
              <div style={{...cs,marginTop:14}}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🚫 Ban Student (M1)</div>
                <div style={{marginBottom:8}}><label style={lbl}>Student ID</label><SInput init={banId} onSet={setBanId} ph='Paste _id from list above' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Ban Reason *</label><STextarea init='' onSet={v=>{banReaR.current=v}} rows={2} ph='e.g. Multiple tab switches, cheating' style={{...inp,resize:'vertical'}} /></div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  <div style={{flex:1}}><label style={lbl}>Type</label><SSelect val={banT} onChange={v=>setBanT(v as any)} style={inp} opts={[{v:'permanent',l:'Permanent'},{v:'temporary',l:'Temporary (7 days)'}]}/></div>
                  <button onClick={banStd} style={{...bd,padding:'10px 16px',alignSelf:'flex-end'}}>🚫 Ban</button>
                </div>
              </div>

              {/* Impersonate (M4) */}
              {role==='superadmin'&&(
                <div style={{...cs,marginTop:10}}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>👁️ Impersonate (M4)</div>
                  <div style={{display:'flex',gap:8}}>
                    <SInput init='' onSet={setImpId} ph='Student _id' style={{...inp,flex:1}} />
                    <button onClick={impersonate} style={bg_}>View as Student →</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Student Profile (S7) */}
          {tab==='students'&&selStudent&&(
            <div>
              <button onClick={()=>setSelStudent(null)} style={{...bg_,marginBottom:12,fontSize:12}}>← Back</button>
              <div style={cs}>
                <div style={{display:'flex',gap:14,alignItems:'center',marginBottom:14,flexWrap:'wrap'}}>
                  <div style={{width:58,height:58,borderRadius:'50%',background:'rgba(77,159,255,0.2)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,fontWeight:700,color:ACC,flexShrink:0}}>
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
                {selStudent.loginHistory&&selStudent.loginHistory.length>0&&(
                  <div>
                    <div style={{fontWeight:700,marginBottom:6,fontSize:12}}>🔐 Login History (S48)</div>
                    {selStudent.loginHistory.slice(-5).reverse().map((l:any,i:number)=>(
                      <div key={i} style={{fontSize:11,color:DIM,padding:'3px 0',borderBottom:`1px solid ${BOR}`}}>📍{l.city||'?'} · 💻{l.device||'?'} · 🕐{l.at?new Date(l.at).toLocaleString():'?'}</div>
                    ))}
                  </div>
                )}
                <div style={{display:'flex',gap:8,marginTop:12,flexWrap:'wrap'}}>
                  {selStudent.banned
                    ?<button onClick={()=>{unbanStd(selStudent._id);setSelStudent(null)}} style={{background:SUC,color:'#000',border:'none',borderRadius:8,padding:'8px 14px',cursor:'pointer',fontWeight:700,fontSize:12}}>✅ Unban</button>
                    :<button onClick={()=>{setBanId(selStudent._id);setSelStudent(null)}} style={{...bd,padding:'8px 14px',fontSize:12}}>🚫 Ban</button>
                  }
                  <button onClick={()=>{setImpId(selStudent._id);impersonate()}} style={{...bg_,fontSize:12}}>👁️ Impersonate</button>
                </div>
              </div>
            </div>
          )}

          {/* ══ BATCHES (S5/M3) ══ */}
          {tab==='batches'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📦 Batch Manager (S5/M3)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>➕ Create Batch</div>
                <div style={{display:'flex',gap:8}}>
                  <SInput init='' onSet={v=>{batchNameR.current=v}} ph='Batch name e.g. NEET 2025 Dropper' style={{...inp,flex:1}} />
                  <button onClick={createBatch} disabled={creatingBatch} style={{...bp,opacity:creatingBatch?0.7:1}}>{creatingBatch?'Creating…':'Create'}</button>
                </div>
              </div>
              {batches.length===0?<div style={{...cs,color:DIM}}>No batches yet</div>:batches.map(b=>(
                <div key={b._id} style={cs}>
                  <div style={{fontWeight:700,fontSize:13}}>{b.name}</div>
                  <div style={{fontSize:11,color:DIM}}>👥 {b.studentCount||0} students · 📝 {b.examCount||0} exams · {b.createdAt?new Date(b.createdAt).toLocaleDateString():''}</div>
                </div>
              ))}
              <div style={{...cs,marginTop:10}}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>🔄 Transfer Student (M3)</div>
                <div style={{marginBottom:8}}><label style={lbl}>Student ID</label><SInput init='' onSet={setBatchTransStdId} ph='Student _id' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Move to Batch</label><SInput init='' onSet={setBatchTransTo} ph='Target batch name/ID' style={inp} /></div>
                <button onClick={batchTransfer} style={bp}>Transfer →</button>
              </div>
            </div>
          )}

          {/* ══ ADMINS (S37) ══ */}
          {tab==='admins'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🛡️ Admin Management (S37)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>➕ Create Admin</div>
                <div style={{marginBottom:8}}><label style={lbl}>Name</label><SInput init='' onSet={v=>{admNameR.current=v}} ph='Admin name' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Email</label><SInput type='email' init='' onSet={v=>{admEmailR.current=v}} ph='admin@proverank.com' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Password</label><SInput type='password' init='' onSet={v=>{admPassR.current=v}} ph='Strong password' style={inp} /></div>
                <div style={{marginBottom:10}}><label style={lbl}>Role</label><SSelect val={admRole} onChange={setAdmRole} style={inp} opts={[{v:'admin',l:'Admin'},{v:'moderator',l:'Moderator'}]}/></div>
                <button onClick={createAdmin} disabled={creatingAdm} style={{...bp,width:'100%',opacity:creatingAdm?0.7:1}}>{creatingAdm?'Creating…':'Create Admin'}</button>
              </div>
              {adminUsers.length===0?<div style={{...cs,color:DIM}}>No sub-admins yet</div>:adminUsers.map(a=>(
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

          {/* ══ LIVE MONITOR (S95) ══ */}
          {tab==='live'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🔴 Live Monitor (S95)</h2>
              <div style={{display:'flex',gap:10,marginBottom:14,flexWrap:'wrap'}}>
                {sBox('🟢','Active Students',students.filter(s=>!s.banned).length)}
                {sBox('🔴','Live Exams',exams.filter(e=>e.status==='active').length)}
                {sBox('⚠️','Flags',flags.length)}
                {sBox('🖥️','Server',stats?.serverHealth||'—')}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📡 Active Exams</div>
                {exams.filter(e=>e.status==='active').length===0
                  ?<div style={{color:DIM,fontSize:12}}>No active exams now</div>
                  :exams.filter(e=>e.status==='active').map(e=>(
                    <div key={e._id} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                      <div><span style={{color:DNG}}>🔴</span> {e.title}</div>
                      <div style={{color:DIM}}>{e.attempts||0} students</div>
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

          {/* ══ RESULTS ══ */}
          {tab==='results'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📈 Results & Reports</h2>
              <div style={{display:'flex',gap:8,marginBottom:12,flexWrap:'wrap'}}>
                <button onClick={()=>doExport(`${API}/api/admin/export/results`,'results.csv')} style={bg_}>📥 Export All Results</button>
                <button onClick={()=>doExport(`${API}/api/admin/export/students`,'students.csv')} style={bg_}>📥 Student Export</button>
              </div>
              {exams.map(e=>(
                <div key={e._id} style={cs}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13}}>{e.title}</div>
                      <div style={{fontSize:11,color:DIM}}>{e.totalMarks} marks · {e.attempts||0} attempts</div>
                    </div>
                    <div style={{display:'flex',gap:5}}>
                      <button onClick={async()=>{try{const r=await fetch(`${API}/api/results/exam/${e._id}`,{headers:H()});if(r.ok){const d=await r.json();T(`${Array.isArray(d)?d.length:'?'} results`)}else T('No results','w')}catch{T('Error','e')}}} style={{...bg_,fontSize:10,padding:'4px 8px'}}>📊 View</button>
                      <button onClick={()=>doExport(`${API}/api/admin/export/exam/${e._id}`,`${e.title}_results.csv`)} style={{...bg_,fontSize:10,padding:'4px 8px'}}>📥 CSV</button>
                      <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/results/topper-pdf/${e._id}`,{headers:H()});if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${e.title}_topper.pdf`;a.click();T('PDF downloaded')}else T('PDF not ready','w')}catch{T('Error','e')}}} style={{...bg_,fontSize:10,padding:'4px 8px'}}>📄 Topper PDF</button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* ══ LEADERBOARD (S15) ══ */}
          {tab==='leaderboard'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🏆 Leaderboard (S15)</h2>
              <div style={{marginBottom:10}}>
                <SSelect val='' onChange={async(examId)=>{if(!examId)return;try{const r=await fetch(`${API}/api/results/leaderboard?examId=${examId}`,{headers:H()});if(r.ok){const d=await r.json();T(`${d.length||0} entries`)}}catch{}}} style={inp}
                  opts={[{v:'',l:'Select Exam…'},...exams.map(e=>({v:e._id,l:e.title}))]}/>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>🌐 Overall Leaderboard</div>
                <button onClick={async()=>{try{const r=await fetch(`${API}/api/results/leaderboard`,{headers:H()});if(r.ok){const d=await r.json();T(`${d.length||0} total entries`)}}catch{T('Error','e')}}} style={{...bg_,marginBottom:10,fontSize:12}}>🔄 Load Overall Ranks</button>
                <div style={{fontSize:12,color:DIM}}>Exam select karke specific leaderboard dekho, ya overall load karo</div>
              </div>
            </div>
          )}

          {/* ══ ANALYTICS (S13/S108/S110) ══ */}
          {tab==='analytics'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📉 Analytics (S13/S108/S110)</h2>
              <div style={{display:'flex',flexWrap:'wrap',gap:10,marginBottom:14}}>
                {sBox('📊','Avg Score',stats?.avgScore?`${stats.avgScore}%`:'—')}
                {sBox('📈','Pass Rate',stats?.passRate?`${stats.passRate}%`:'—')}
                {sBox('🔥','Peak Hour',stats?.peakHour||'—')}
                {sBox('😴','Inactive 7d',stats?.inactiveCount||'—')}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📊 Platform Analytics (S53)</div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  {[['Platform Stats','/api/admin/stats'],['Exam Heatmap','/api/admin/analytics/heatmap'],['Series Analytics','/api/admin/analytics/series'],['Retention Report','/api/admin/analytics/retention']].map(([l,ep])=>(
                    <button key={l} onClick={async()=>{try{const r=await fetch(`${API}${ep}`,{headers:H()});if(r.ok){const d=await r.json();T(`${l}: loaded (${Object.keys(d).length} fields)`)}else T(`${l} not ready`,'w')}catch{T('Error','e')}}} style={{...bg_,fontSize:11,padding:'6px 10px'}}>{l}</button>
                  ))}
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>🔢 Batch vs Batch (M8)</div>
                <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/analytics/batch-compare`,{headers:H()});if(r.ok){const d=await r.json();T(`Batch compare: ${Array.isArray(d)?d.length:'?'} batches`)}else T('Compare not ready','w')}catch{T('Error','e')}}} style={{...bg_,fontSize:12}}>📊 Load Batch Comparison</button>
              </div>
            </div>
          )}

          {/* ══ ANTI-CHEAT LOGS (N14) ══ */}
          {tab==='cheating'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🚨 Anti-Cheat Logs (N14)</h2>
              {flags.length===0?<div style={{...cs,color:DIM}}>✅ No cheating flags</div>:flags.map(f=>(
                <div key={f._id} style={{...cs,borderLeft:`3px solid ${f.severity==='high'?DNG:WRN}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:12}}>{f.studentName||'—'} — {f.examTitle||'—'}</div>
                      <div style={{fontSize:11,color:DIM}}>Type: {f.type} · Count: {f.count} · {f.at?new Date(f.at).toLocaleString():''}</div>
                    </div>
                    <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:f.severity==='high'?'rgba(255,77,77,0.15)':'rgba(255,184,77,0.15)',color:f.severity==='high'?DNG:WRN,fontWeight:700}}>{f.severity?.toUpperCase()}</span>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* ══ SNAPSHOTS (Phase 5.2) ══ */}
          {tab==='snapshots'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📷 Webcam Snapshots</h2>
              {snapshots.length===0?<div style={{...cs,color:DIM}}>No snapshots yet</div>:(
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(160px,1fr))',gap:10}}>
                  {snapshots.map(s=>(
                    <div key={s._id} style={{...cs,padding:8,borderColor:s.flagged?DNG:BOR}}>
                      {s.imageUrl?<img src={s.imageUrl} alt='snap' style={{width:'100%',borderRadius:5,marginBottom:5}} />:<div style={{width:'100%',height:80,background:'rgba(77,159,255,0.05)',borderRadius:5,display:'flex',alignItems:'center',justifyContent:'center',marginBottom:5,fontSize:20}}>📷</div>}
                      <div style={{fontSize:11,fontWeight:600}}>{s.studentName||'—'}</div>
                      <div style={{fontSize:10,color:DIM}}>{s.capturedAt?new Date(s.capturedAt).toLocaleString():''}</div>
                      {s.flagged&&<div style={{fontSize:10,color:DNG,fontWeight:700}}>🚩 FLAGGED</div>}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ══ AI INTEGRITY (AI-6) ══ */}
          {tab==='integrity'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🤖 AI Integrity Scores (AI-6)</h2>
              <div style={{fontSize:12,color:DIM,marginBottom:12}}>Har exam ke baad AI 0-100 score generate karta hai — tab switches, face away, fast answers sab combine</div>
              {students.filter(s=>s.integrityScore!==undefined).length===0
                ?<div style={{...cs,color:DIM}}>No integrity scores yet — exams complete honge tab aayenge</div>
                :students.filter(s=>s.integrityScore!==undefined).map(s=>(
                  <div key={s._id} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13}}>{s.name}</div>
                      <div style={{fontSize:11,color:DIM}}>{s.email}</div>
                    </div>
                    <div style={{textAlign:'center'}}>
                      <div style={{fontSize:20,fontWeight:700,color:s.integrityScore!<40?DNG:s.integrityScore!<70?WRN:SUC}}>{s.integrityScore}</div>
                      <div style={{fontSize:10,color:DIM}}>/100</div>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ PROCTORING PDF (M15) ══ */}
          {tab==='proctoring_pdf'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📄 Proctoring Summary PDF (M15)</h2>
              <div style={{fontSize:12,color:DIM,marginBottom:12}}>Har student ka complete proctoring report — snapshots, tab switches, warnings, audio flags</div>
              {students.slice(0,20).map(s=>(
                <div key={s._id} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                  <div>
                    <div style={{fontWeight:700,fontSize:13}}>{s.name}</div>
                    <div style={{fontSize:11,color:DIM}}>{s.email}</div>
                  </div>
                  <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/proctoring-report/${s._id}`,{headers:H()});if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`${s.name}_proctoring.pdf`;a.click();T('PDF downloaded')}else T('Report not ready','w')}catch{T('Error','e')}}} style={{...bg_,fontSize:11,padding:'5px 10px'}}>📄 Download PDF</button>
                </div>
              ))}
            </div>
          )}

          {/* ══ GRIEVANCES (S92/S69/S71) ══ */}
          {tab==='tickets'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🎫 Grievances & Tickets (S92)</h2>
              {tickets.length===0?<div style={{...cs,color:DIM}}>No tickets</div>:tickets.map(t=>(
                <div key={t._id} style={{...cs,borderLeft:`3px solid ${t.status==='open'?WRN:t.status==='resolved'?SUC:ACC}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                    <div style={{flex:1}}>
                      <div style={{fontWeight:700,fontSize:12}}>{t.studentName||'—'} — {t.type||'General'}</div>
                      <div style={{fontSize:11,color:DIM,marginTop:2}}>{t.description?.slice(0,80)}{t.description?.length>80?'…':''}</div>
                      <div style={{fontSize:10,color:DIM}}>Exam: {t.examTitle||'—'} · {t.createdAt?new Date(t.createdAt).toLocaleDateString():''}</div>
                    </div>
                    <div style={{display:'flex',gap:5,alignItems:'flex-start'}}>
                      <span style={{fontSize:9,padding:'2px 7px',borderRadius:20,background:t.status==='open'?'rgba(255,184,77,0.15)':t.status==='resolved'?'rgba(0,196,140,0.15)':'rgba(77,159,255,0.15)',color:t.status==='open'?WRN:t.status==='resolved'?SUC:ACC,fontWeight:700}}>{t.status?.toUpperCase()}</span>
                      {t.status!=='resolved'&&<button onClick={()=>resolveTicket(t._id)} style={{background:SUC,color:'#000',border:'none',borderRadius:6,padding:'3px 8px',cursor:'pointer',fontWeight:700,fontSize:10}}>✓ Resolve</button>}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* ══ ANNOUNCEMENTS (S47/S12) ══ */}
          {tab==='announcements'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📢 Announcements (S47)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📢 Broadcast Message</div>
                <div style={{marginBottom:8}}><label style={lbl}>Message *</label><STextarea init='' onSet={v=>{annR.current=v}} rows={4} ph='Announcement text…' style={{...inp,resize:'vertical'}} /></div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  <div style={{flex:1}}><label style={lbl}>Target Batch</label><SSelect val={annBatch} onChange={setAnnBatch} style={inp} opts={[{v:'all',l:'All Students'},{v:'dropper',l:'Dropper'},{v:'12th',l:'12th Batch'},{v:'free',l:'Free Students'}]}/></div>
                  <button onClick={sendAnn} style={{...bp,alignSelf:'flex-end',padding:'10px 14px',fontSize:12}}>📢 Send</button>
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📧 Email Templates (S109)</div>
                {[{ico:'👋',l:'Welcome Email',tag:'welcome'},{ico:'📅',l:'Exam Reminder',tag:'reminder'},{ico:'🏆',l:'Result Published',tag:'result'},{ico:'😴',l:'Inactive (7d)',tag:'inactive'}].map(t=>(
                  <div key={t.tag} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                    <span>{t.ico} {t.l}</span>
                    <button onClick={async()=>{try{await fetch(`${API}/api/admin/email-template/${t.tag}`,{method:'POST',headers:H()});T(`${t.l} test sent!`)}catch{T('Email API check karo','e')}}} style={{...bg_,padding:'3px 8px',fontSize:10}}>📤 Test</button>
                  </div>
                ))}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:13}}>📱 WhatsApp + SMS (S65/M19)</div>
                <div style={{fontSize:11,color:DIM,marginBottom:8}}>ENV: WHATSAPP_TOKEN, TWILIO_SID — Render pe set karo</div>
                <div style={{display:'flex',gap:8}}>
                  <button onClick={async()=>{try{await fetch(`${API}/api/admin/whatsapp/test`,{method:'POST',headers:H()});T('WhatsApp test sent!')}catch{T('WhatsApp not configured','e')}}} style={bg_}>📱 WhatsApp Test</button>
                  <button onClick={async()=>{try{await fetch(`${API}/api/admin/sms/test`,{method:'POST',headers:H()});T('SMS test sent!')}catch{T('SMS not configured','e')}}} style={bg_}>💬 SMS Test</button>
                </div>
              </div>
            </div>
          )}

          {/* ══ REPORTS (S14/S67/S68) ══ */}
          {tab==='reports'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📊 Reports & Export</h2>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                {[
                  {ico:'👥',t:'Students CSV',d:'All students with scores',fn:()=>doExport(`${API}/api/admin/export/students`,'students.csv')},
                  {ico:'📈',t:'Results CSV',d:'All exam results',fn:()=>doExport(`${API}/api/admin/export/results`,'results.csv')},
                  {ico:'🚨',t:'Cheating Report',d:'Anti-cheat flags PDF',fn:()=>doExport(`${API}/api/admin/export/cheating`,'cheating.pdf')},
                  {ico:'📊',t:'Institute PDF (N19)',d:'Monthly performance PDF',fn:()=>doExport(`${API}/api/admin/reports/institute`,'institute.pdf')},
                  {ico:'💰',t:'Revenue Report',d:'Payments & subscriptions',fn:()=>doExport(`${API}/api/admin/reports/revenue`,'revenue.csv')},
                  {ico:'🔄',t:'Backup (S50)',d:'Full DB backup trigger',fn:doBackup},
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

          {/* ══ FEATURE FLAGS (N21) ══ */}
          {tab==='features'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🚩 Feature Flags (N21)</h2>
              <div style={{fontSize:12,color:DIM,marginBottom:12}}>Koi bhi feature ON/OFF karo bina redeploy ke — instant effect</div>
              {features.map(f=>(
                <div key={f.key} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center',gap:10}}>
                  <div style={{flex:1}}>
                    <div style={{fontWeight:700,fontSize:12}}>{f.label}</div>
                    <div style={{fontSize:10,color:DIM}}>{f.description}</div>
                    <div style={{fontSize:9,color:'rgba(77,159,255,0.4)',marginTop:1}}>key: {f.key}</div>
                  </div>
                  <button onClick={()=>toggleFeat(f.key)}
                    style={{background:f.enabled?SUC:`rgba(255,255,255,0.1)`,border:'none',borderRadius:20,padding:0,width:46,height:24,cursor:'pointer',position:'relative',flexShrink:0,transition:'background 0.2s'}}>
                    <div style={{position:'absolute',top:2,left:f.enabled?24:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.2s',boxShadow:'0 1px 4px rgba(0,0,0,0.3)'}}/>
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* ══ PERMISSIONS (S72) ══ */}
          {tab==='permissions'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🔐 Permissions (S72)</h2>
              <div style={{fontSize:12,color:DIM,marginBottom:12}}>Sub-admin ke liye individual permissions — toggle karo + save karo</div>
              {Object.entries(perms).map(([k,v])=>(
                <div key={k} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                  <div style={{fontWeight:600,fontSize:12}}>{k.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase())}</div>
                  <button onClick={()=>{setPerms(p=>({...p,[k]:!v}))}}
                    style={{background:v?SUC:`rgba(255,255,255,0.1)`,border:'none',borderRadius:20,padding:0,width:46,height:24,cursor:'pointer',position:'relative',transition:'background 0.2s'}}>
                    <div style={{position:'absolute',top:2,left:v?24:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.2s'}}/>
                  </button>
                </div>
              ))}
              <button onClick={savePerms} style={{...bp,width:'100%',marginTop:10,fontSize:12}}>💾 Save Permissions</button>
            </div>
          )}

          {/* ══ BRANDING (S56+M17) ══ */}
          {tab==='branding'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🎨 Branding & SEO (S56/M17)</h2>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🏷️ Platform Branding</div>
                {[{l:'Platform Name',r:bNameR,ph:'ProveRank'},{l:'Tagline',r:bTagR,ph:'Prove Your Rank'},{l:'Support Email',r:bMailR,ph:'support@proverank.com'}].map(f=>(
                  <div key={f.l} style={{marginBottom:8}}><label style={lbl}>{f.l}</label><SInput init={f.r.current} onSet={v=>{f.r.current=v}} ph={f.ph} style={inp} /></div>
                ))}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🔍 SEO Settings (M17)</div>
                <div style={{marginBottom:8}}><label style={lbl}>SEO Title</label><SInput init={seoTR.current} onSet={v=>{seoTR.current=v}} ph='ProveRank — NEET Online Test' style={inp} /></div>
                <div style={{marginBottom:8}}><label style={lbl}>Meta Description</label><STextarea init={seoDR.current} onSet={v=>{seoDR.current=v}} rows={2} ph='Platform description…' style={{...inp,resize:'vertical'}} /></div>
              </div>
              <button onClick={saveBrand} disabled={savingB} style={{...bp,width:'100%',opacity:savingB?0.7:1}}>{savingB?'Saving…':'💾 Save Branding & SEO'}</button>
            </div>
          )}

          {/* ══ MAINTENANCE (S66) ══ */}
          {tab==='maintenance'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>🔧 Maintenance Mode (S66)</h2>
              <div style={{...cs,border:`2px solid ${mainOn?DNG:SUC}`}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                  <div>
                    <div style={{fontWeight:700,fontSize:15}}>Maintenance Mode</div>
                    <div style={{fontSize:12,color:mainOn?DNG:SUC,marginTop:2}}>{mainOn?'🔴 ACTIVE — Students blocked':'🟢 OFF — Site is live'}</div>
                  </div>
                  <button onClick={toggleMaint} style={{background:mainOn?SUC:DNG,color:mainOn?'#000':'#fff',border:'none',borderRadius:8,padding:'11px 18px',cursor:'pointer',fontWeight:700,fontSize:13}}>
                    {mainOn?'Turn OFF ✅':'Turn ON 🔧'}
                  </button>
                </div>
                <label style={lbl}>Students ko dikhega (message):</label>
                <STextarea init='Under maintenance. Back soon!' onSet={v=>{mainMsgR.current=v}} rows={2} style={{...inp,resize:'vertical'}} />
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:6,fontSize:12}}>⚠️ Notes</div>
                <div style={{fontSize:11,color:DIM,lineHeight:1.7}}>• Admin panel maintenance ke dauraan bhi accessible rahega<br/>• Active exams ke dauran ON mat karo<br/>• Pehle data backup lo (S50)</div>
              </div>
            </div>
          )}

          {/* ══ AUDIT LOGS (S93/S38) ══ */}
          {tab==='audit'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>📋 Audit Logs (S93/S38)</h2>
              {logs.length===0?<div style={{...cs,color:DIM}}>No audit logs yet</div>:logs.slice(0,50).map((l,i)=>(
                <div key={l._id||i} style={{...cs,padding:'7px 12px'}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:6,fontSize:11}}>
                    <div>
                      <span style={{fontWeight:700,color:ACC}}>{l.action}</span>
                      {' '}<span style={{color:DIM}}>by {l.by||'—'}</span>
                      {l.detail&&<div style={{color:DIM,fontSize:10,marginTop:1}}>{l.detail}</div>}
                    </div>
                    <span style={{color:DIM,fontSize:10}}>{l.at?new Date(l.at).toLocaleString():''}</span>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* ══ TASK MANAGER (M13) ══ */}
          {tab==='tasks'&&(
            <div>
              <h2 style={{fontFamily:'Playfair Display,serif',color:ACC,margin:'0 0 14px'}}>✅ Task Manager (M13)</h2>
              <div style={{display:'flex',gap:8,marginBottom:14}}>
                <SInput init='' onSet={v=>{todoR.current=v}} ph='New task…' style={{...inp,flex:1}} />
                <button onClick={()=>{const t=todoR.current;if(!t)return;setTodos(p=>[...p,{id:Date.now().toString(),text:t,done:false}]);todoR.current=''}} style={bp}>+ Add</button>
              </div>
              {todos.map(t=>(
                <div key={t.id} style={{...cs,display:'flex',gap:10,alignItems:'center',opacity:t.done?0.55:1}}>
                  <input type='checkbox' checked={t.done} onChange={()=>setTodos(p=>p.map(td=>td.id===t.id?{...td,done:!td.done}:td))} style={{width:17,height:17,cursor:'pointer',accentColor:ACC}} />
                  <span style={{flex:1,fontSize:12,textDecoration:t.done?'line-through':'none'}}>{t.text}</span>
                  <button onClick={()=>setTodos(p=>p.filter(td=>td.id!==t.id))} style={{background:'none',border:'none',color:DNG,cursor:'pointer',fontSize:15}}>✕</button>
                </div>
              ))}
              {todos.length===0&&<div style={{...cs,color:DIM}}>No tasks — add karo upar se!</div>}
            </div>
          )}

          {/* ══ CHANGELOG (M14) ══ */}
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

        </div>
      </div>
    </div>
  )
}
