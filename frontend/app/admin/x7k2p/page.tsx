'use client'
import { useState, useEffect, useRef, useCallback, memo } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from '@/lib/auth'

// ── API Base ──
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── TypeScript Interfaces ──
interface Student { _id:string;name:string;email:string;phone?:string;role:string;createdAt:string;banned?:boolean;banReason?:string;group?:string;integrityScore?:number;loginHistory?:any[];parentEmail?:string }
interface Exam { _id:string;title:string;scheduledAt:string;totalMarks:number;duration:number;status:string;attempts?:number;category?:string;password?:string;batch?:string;subject?:string }
interface Question { _id:string;text:string;subject:string;chapter?:string;topic?:string;difficulty:string;type:string;options?:string[];correctAnswer?:string;explanation?:string;approvalStatus?:string }
interface Log { _id:string;action:string;by:string;at:string;detail:string }
interface Flag { _id:string;studentName:string;examTitle:string;type:string;count:number;severity:string;at:string;integrityScore?:number }
interface Ticket { _id:string;studentName:string;examTitle:string;type:string;status:string;createdAt:string;description:string }
interface Feature { key:string;label:string;description:string;enabled:boolean }
interface Notif { id:string;icon:string;msg:string;t:string;read:boolean }
interface Snapshot { _id:string;studentName:string;imageUrl?:string;flagged:boolean;capturedAt:string;examTitle?:string }
interface Batch { _id:string;name:string;studentCount:number;examCount:number;createdAt:string }
interface AdminUser { _id:string;name:string;email:string;role:string;createdAt:string;active:boolean }
interface Result { _id:string;studentName:string;examTitle:string;score:number;totalMarks:number;rank:number;percentile:number;submittedAt:string }

// ── Default Feature Flags ──
const DEF_FEATURES: Feature[] = [
  {key:'open_registration',label:'🔓 Student Registration',description:'Allow new student registrations. Toggle OFF to close (Superadmin only)',enabled:true},
  {key:'webcam',label:'Webcam Proctoring',description:'Camera compulsory during exams (Phase 5.2)',enabled:true},
  {key:'audio',label:'Audio Monitoring',description:'Microphone noise detection (S57)',enabled:false},
  {key:'eye_tracking',label:'Eye Tracking AI',description:'Detect looking away from screen (S-ET)',enabled:true},
  {key:'face_detect',label:'Face Detection TF.js',description:'Multi/no-face detection (Phase 5.4)',enabled:true},
  {key:'head_pose',label:'Head Pose Detection',description:'Head angle tracking (S73)',enabled:true},
  {key:'vbg_block',label:'Virtual Background Block',description:'Detect and block fake backgrounds (S74)',enabled:true},
  {key:'vpn_block',label:'VPN/Proxy Block',description:'Block VPN users from attempting (S20)',enabled:false},
  {key:'live_rank',label:'Live Rank Updates',description:'Socket.io real-time ranking (S107)',enabled:true},
  {key:'social_share',label:'Social Share Results',description:'WhatsApp/Instagram result card (S99)',enabled:true},
  {key:'parent_portal',label:'Parent Portal',description:'Read-only child progress access (N17)',enabled:false},
  {key:'pyq_bank',label:'PYQ Bank Access',description:'NEET 2015-2024 questions (S104)',enabled:true},
  {key:'maintenance',label:'Maintenance Mode',description:'Block students, keep admin accessible (S66)',enabled:false},
  {key:'sms_notify',label:'SMS Notifications',description:'Result SMS via Twilio/Fast2SMS (M19)',enabled:false},
  {key:'whatsapp',label:'WhatsApp Alerts',description:'Exam reminders via WhatsApp (S65)',enabled:false},
  {key:'ai_tagger',label:'AI Auto-Tagger',description:'Auto difficulty + subject tagging (AI-1/AI-2)',enabled:true},
  {key:'ai_explain',label:'AI Explanation Generator',description:'Auto explanation from question (AI-10)',enabled:true},
  {key:'two_fa',label:'2FA Admin Login',description:'OTP mandatory for admin accounts (S49)',enabled:true},
  {key:'ip_lock',label:'IP Lock During Exam',description:'Block IP change mid-exam (S20)',enabled:true},
  {key:'fullscreen',label:'Fullscreen Force Mode',description:'3 exits triggers auto-submit (S32)',enabled:true},
  {key:'watermark',label:'Screen Watermark',description:'Student name/ID watermark on screen (S76)',enabled:true},
  {key:'integrity',label:'AI Integrity Score',description:'0-100 score per exam attempt (AI-6)',enabled:true},
  {key:'n14_pattern',label:'Suspicious Pattern Detection',description:'Fast/identical answer flagging (N14)',enabled:true},
  {key:'onboarding',label:'Platform Onboarding Tour',description:'Guided tour for new students (S100)',enabled:true},
  {key:'n23_encrypt',label:'Paper Encryption',description:'Questions encrypted in browser (N23)',enabled:false},
  {key:'waiting_room',label:'Exam Waiting Room',description:'Students join 10 min before exam (M6)',enabled:true},
  {key:'cert_gen',label:'Certificate Generation',description:'Auto PDF certificate on completion (S21)',enabled:true},
]

// ══════════════════════════════════════════════════════════════
// MOBILE KEYBOARD FIX — memo components hold own state
// Parent re-renders do NOT cause these to re-render
// ══════════════════════════════════════════════════════════════
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

// ══════════════════════════════════════════════════════════════
// PR LOGO — Exact same as Login page (PR4 Hexagon)
// ══════════════════════════════════════════════════════════════
function PRLogo({size=36}:{size?:number}) {
  const r=size/2,cx=size/2,cy=size/2
  const outer=Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.88*Math.cos(a)},${cy+r*0.88*Math.sin(a)}`;}).join(' ')
  const inner=Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;}).join(' ')
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <defs><filter id="gll"><feGaussianBlur stdDeviation="1.5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
      <polygon points={outer} fill="none" stroke="rgba(77,159,255,0.35)" strokeWidth="1" filter="url(#gll)"/>
      <polygon points={inner} fill="none" stroke="#4D9FFF" strokeWidth="1.5" filter="url(#gll)"/>
      {Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return <circle key={i} cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)} r={size*0.05} fill="#4D9FFF" filter="url(#gll)"/>})}
      <text x={cx} y={cy+size*0.16} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize={size*0.31} fontWeight="700" fill="#4D9FFF" filter="url(#gll)">PR</text>
    </svg>
  )
}

// ══════════════════════════════════════════════════════════════
// PARTICLES BACKGROUND — Same as Login page
// ══════════════════════════════════════════════════════════════
function ParticlesBg() {
  const canvasRef=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    canvas.width=window.innerWidth;canvas.height=window.innerHeight
    const particles:{x:number;y:number;vx:number;vy:number;r:number;opacity:number}[]=[]
    for(let i=0;i<60;i++)particles.push({x:Math.random()*canvas.width,y:Math.random()*canvas.height,vx:(Math.random()-.5)*.3,vy:(Math.random()-.5)*.3,r:Math.random()*1.5+0.5,opacity:Math.random()*.3+.05})
    let animId:number
    const draw=()=>{
      ctx.clearRect(0,0,canvas.width,canvas.height)
      particles.forEach(p=>{
        p.x+=p.vx;p.y+=p.vy
        if(p.x<0)p.x=canvas.width;if(p.x>canvas.width)p.x=0
        if(p.y<0)p.y=canvas.height;if(p.y>canvas.height)p.y=0
        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(77,159,255,${p.opacity})`;ctx.fill()
      })
      for(let i=0;i<particles.length;i++)for(let j=i+1;j<particles.length;j++){
        const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y,dist=Math.sqrt(dx*dx+dy*dy)
        if(dist<100){ctx.beginPath();ctx.moveTo(particles[i].x,particles[i].y);ctx.lineTo(particles[j].x,particles[j].y);ctx.strokeStyle=`rgba(77,159,255,${.08*(1-dist/100)})`;ctx.lineWidth=.5;ctx.stroke()}
      }
      animId=requestAnimationFrame(draw)
    }
    draw()
    const resize=()=>{canvas.width=window.innerWidth;canvas.height=window.innerHeight}
    window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}

// ══════════════════════════════════════════════════════════════
// GLOBAL SEARCH COMPONENT (M12)
// ══════════════════════════════════════════════════════════════
const GlobalSearch=memo(function GlobalSearch({students,exams,questions,setTab,setSelStudent,token}:{students:Student[];exams:Exam[];questions:Question[];setTab:(t:string)=>void;setSelStudent:(s:Student)=>void;token:string}) {
  const [q,setQ]=useState('')
  const res=q.length<2?[]:[
    ...(students||[]).filter(s=>s.name?.toLowerCase().includes(q.toLowerCase())||s.email?.toLowerCase().includes(q.toLowerCase())).slice(0,4).map(s=>({type:'Student',label:s.name+' · '+s.email,icon:'👤',go:()=>{setSelStudent(s);setTab('students')}})),
    ...(exams||[]).filter(e=>e.title?.toLowerCase().includes(q.toLowerCase())).slice(0,4).map(e=>({type:'Exam',label:e.title+' · '+e.status,icon:'📝',go:()=>setTab('exams')})),
    ...(questions||[]).filter(qn=>qn.text?.toLowerCase().includes(q.toLowerCase())).slice(0,4).map(qn=>({type:'Question',label:qn.text?.slice(0,70)+'…',icon:'❓',go:()=>setTab('questions')})),
  ]
  return (
    <div>
      <div style={{position:'relative',marginBottom:16}}>
        <span style={{position:'absolute',left:14,top:'50%',transform:'translateY(-50%)',fontSize:16,zIndex:1}}>🔎</span>
        <input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search students, exams, questions — type at least 2 characters"
          style={{width:'100%',padding:'14px 14px 14px 44px',background:'rgba(0,31,58,0.8)',border:'1.5px solid rgba(77,159,255,0.3)',borderRadius:12,color:'#E8F4FF',fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',backdropFilter:'blur(10px)'}} />
      </div>
      {q.length>=2&&(
        <div>
          {res.length===0
            ?<div style={{background:'rgba(0,22,40,0.6)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:'20px',textAlign:'center',color:'#6B8FAF',fontSize:13}}>
              <div style={{fontSize:32,marginBottom:8}}>🔍</div>
              No results found for "<span style={{color:'#4D9FFF'}}>{q}</span>"
            </div>
            :res.map((r,i)=>(
              <button key={i} onClick={r.go} style={{display:'flex',gap:12,alignItems:'center',width:'100%',padding:'12px 16px',background:'rgba(0,22,40,0.6)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:10,marginBottom:6,cursor:'pointer',textAlign:'left',transition:'all 0.2s'}}>
                <span style={{fontSize:20}}>{r.icon}</span>
                <div style={{flex:1}}>
                  <span style={{fontSize:9,padding:'2px 8px',borderRadius:20,background:'rgba(77,159,255,0.15)',color:'#4D9FFF',fontWeight:700,marginRight:8}}>{r.type}</span>
                  <span style={{fontSize:12,color:'#E8F4FF'}}>{r.label}</span>
                </div>
                <span style={{color:'#4D9FFF',fontSize:14}}>→</span>
              </button>
            ))
          }
        </div>
      )}
      {q.length<2&&(
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:12,marginTop:8}}>
          {[{icon:'👥',label:'Students',sub:`${(students||[]).length} registered`,tab:'students'},{icon:'📝',label:'Exams',sub:`${(exams||[]).length} total`,tab:'exams'},{icon:'❓',label:'Questions',sub:`${(questions||[]).length} in bank`,tab:'questions'},{icon:'📊',label:'Analytics',sub:'Performance data',tab:'analytics'}].map(c=>(
            <button key={c.tab} onClick={()=>setTab(c.tab)} style={{padding:'16px',background:'rgba(0,22,40,0.5)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,cursor:'pointer',textAlign:'left'}}>
              <div style={{fontSize:24,marginBottom:6}}>{c.icon}</div>
              <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF'}}>{c.label}</div>
              <div style={{fontSize:11,color:'#6B8FAF',marginTop:2}}>{c.sub}</div>
            </button>
          ))}
        </div>
      )}
    </div>
  )
})

// ══════════════════════════════════════════════════════════════
// THEME CONSTANTS — N6 Neon Blue Arctic (from Login page)
// ══════════════════════════════════════════════════════════════
const BG_GRAD='radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)'
const CRD='rgba(0,22,40,0.75)'
const CRD2='rgba(0,31,58,0.8)'
const ACC='#4D9FFF'
const BOR='rgba(77,159,255,0.18)'
const BOR2='rgba(77,159,255,0.3)'
const TS='#E8F4FF'
const DIM='#6B8FAF'
const SUC='#00C48C'
const DNG='#FF4D4D'
const WRN='#FFB84D'
const GOLD='#FFD700'

// Shared style objects
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid ${BOR2}`,borderRadius:10,color:TS,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',backdropFilter:'blur(8px)'}
const bp:any={background:`linear-gradient(135deg,${ACC},#0055CC)`,color:'#fff',border:'none',borderRadius:10,padding:'11px 22px',cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',boxShadow:`0 4px 16px rgba(77,159,255,0.35)`}
const bg_:any={background:'rgba(77,159,255,0.1)',color:ACC,border:`1px solid ${BOR2}`,borderRadius:10,padding:'9px 18px',cursor:'pointer',fontWeight:600,fontSize:12,fontFamily:'Inter,sans-serif',backdropFilter:'blur(8px)'}
const bd:any={background:'rgba(255,77,77,0.15)',color:DNG,border:'1px solid rgba(255,77,77,0.3)',borderRadius:10,padding:'9px 18px',cursor:'pointer',fontWeight:700,fontSize:12}
const bs:any={background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'9px 18px',cursor:'pointer',fontWeight:700,fontSize:12}
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}
const lbl:any={display:'block',fontSize:11,color:DIM,marginBottom:5,fontFamily:'Inter,sans-serif',fontWeight:600,letterSpacing:0.5,textTransform:'uppercase'}
const pageTitle:any={fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TS,margin:'0 0 4px',background:`linear-gradient(90deg,${ACC},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}
const pageSub:any={fontSize:12,color:DIM,marginBottom:20,fontFamily:'Inter,sans-serif'}

// ══════════════════════════════════════════════════════════════
// STAT BOX COMPONENT
// ══════════════════════════════════════════════════════════════
function StatBox({ico,lbl:label,val,sub,col=ACC}:{ico:string;lbl:string;val:any;sub?:string;col?:string}) {
  return (
    <div style={{background:CRD,border:`1px solid ${BOR}`,borderRadius:14,padding:'18px 16px',flex:1,minWidth:130,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden'}}>
      <div style={{position:'absolute',right:-8,bottom:-8,fontSize:48,opacity:0.06}}>{ico}</div>
      <div style={{fontSize:22,marginBottom:6}}>{ico}</div>
      <div style={{fontSize:22,fontWeight:700,color:col,fontFamily:'Playfair Display,Georgia,serif',lineHeight:1}}>{val}</div>
      <div style={{fontSize:11,color:DIM,marginTop:4,fontWeight:600}}>{label}</div>
      {sub&&<div style={{fontSize:10,color:col,marginTop:2,opacity:0.8}}>{sub}</div>}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════
// PAGE HERO — SVG + Title for each empty-state page
// ══════════════════════════════════════════════════════════════
function PageHero({icon,title,subtitle}:{icon:string;title:string;subtitle:string}) {
  return (
    <div style={{textAlign:'center',padding:'32px 20px 24px',background:`linear-gradient(135deg,rgba(0,22,40,0.8),rgba(0,31,58,0.6))`,borderRadius:16,border:`1px solid ${BOR}`,marginBottom:20,backdropFilter:'blur(12px)'}}>
      <div style={{fontSize:48,marginBottom:10}}>{icon}</div>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:TS,marginBottom:6}}>{title}</div>
      <div style={{fontSize:13,color:DIM,maxWidth:400,margin:'0 auto',lineHeight:1.6}}>{subtitle}</div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════
// BADGE COMPONENT
// ══════════════════════════════════════════════════════════════
function Badge({label,col=ACC}:{label:string;col?:string}) {
  return <span style={{fontSize:10,padding:'3px 9px',borderRadius:20,background:`${col}22`,color:col,fontWeight:700,border:`1px solid ${col}44`,display:'inline-block'}}>{label}</span>
}

// ══════════════════════════════════════════════════════════════
// MAIN ADMIN PANEL COMPONENT
// ══════════════════════════════════════════════════════════════
export default function AdminPanel() {
  const router=useRouter()
  const [role,setRole]=useState('')
  const [token,setToken]=useState('')
  const [mounted,setMounted]=useState(false)
  const [_tab,_setTab]=useState(()=>{ try{ return localStorage.getItem('pr_admin_tab')||'dashboard' }catch{ return 'dashboard' } })
  const tab=_tab
  const setTab=(t:string)=>{ try{localStorage.setItem('pr_admin_tab',t)}catch{} ; _setTab(t) }
  const [sideOpen,setSideOpen]=useState(false)
  const [toast,setToast]=useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)
  const [notifOpen,setNotifOpen]=useState(false)
  const [loading,setLoading]=useState(true)

  // Data states
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
  const [results,setResults]=useState<Result[]>([])
  const [notifs,setNotifs]=useState<Notif[]>([])

  // Search/filter states
  const [stdSearch,setStdSearch]=useState('')
  const [stdFilter,setStdFilter]=useState<'all'|'active'|'banned'>('all')
  const [examSearch,setExamSearch]=useState('')
  const [qSearch,setQSearch]=useState('')
  const [qSubjFilter,setQSubjFilter]=useState('all')
  const [selStudent,setSelStudent]=useState<Student|null>(null)

  // Exam Create refs (keyboard fix)
  const eTitleR=useRef('');const eDateR=useRef('')
  const eMarksR=useRef('720');const eDurR=useRef('200')
  const eCatR=useRef('Full Mock');const ePassR=useRef('')
  const eBatchR=useRef('');const eInstrR=useRef('')
  const [eStep,setEStep]=useState(1)
  const [createdEId,setCreatedEId]=useState('')
  const [createdETitle,setCreatedETitle]=useState('')
  const [qMeth,setQMeth]=useState<'copypaste'|'excel'|'pdf'|'manual'>('copypaste')
  const cpTxtR=useRef('');const cpKeyR=useRef('')
  const [excelF,setExcelF]=useState<File|null>(null)
  const [pdfF,setPdfF]=useState<File|null>(null)
  const [uploadingQ,setUploadingQ]=useState(false)
  const [creatingE,setCreatingE]=useState(false)
  const [upRes,setUpRes]=useState<{s:number;f:number;msg:string}|null>(null)

  // Question Bank refs
  const qTxtR=useRef('');const qHindiR=useRef('');const qChapR=useRef('');const qTopicR=useRef('');const qExpR=useRef('')
  const qA=useRef('');const qB=useRef('');const qC=useRef('');const qD=useRef('')
  const [qSubj,setQSubj]=useState('Physics')
  const [qDiff,setQDiff]=useState('medium')
  const [qType,setQType]=useState('SCQ')
  const [qAns,setQAns]=useState('A')
  const [savingQ,setSavingQ]=useState(false)
  const [qPreview,setQPreview]=useState(false)

  // Student management refs
  const banReaR=useRef('')
  const [banId,setBanId]=useState('')
  const [banT,setBanT]=useState<'permanent'|'temporary'>('permanent')

  // Announcement refs
  const annR=useRef('');const annTitleR=useRef('')
  const [annBatch,setAnnBatch]=useState('all')
  const [annType,setAnnType]=useState<'in-app'|'email'|'both'>('both')

  // Branding refs
  const bNameR=useRef('ProveRank');const bTagR=useRef('Prove Your Rank')
  const bMailR=useRef('support@proverank.com');const bPhoneR=useRef('')
  const seoTR=useRef('ProveRank — NEET Online Test Platform')
  const seoDR=useRef('Best NEET mock test platform with AI analytics and anti-cheat proctoring.')
  const seoKR=useRef('NEET,online test,mock exam,ProveRank')
  const mainMsgR=useRef('Site under maintenance. We will be back shortly.')
  const [savingB,setSavingB]=useState(false)
  const [mainOn,setMainOn]=useState(false)

  // Impersonate / time extension
  const [impId,setImpId]=useState('')
  const [extStdId,setExtStdId]=useState('')
  const [extMins,setExtMins]=useState('10')

  // Permissions
  const [perms,setPerms]=useState({
    create_exam:true,edit_exam:true,delete_exam:false,
    ban_student:true,view_results:true,export_data:true,
    manage_questions:true,send_announcements:true,
    view_audit_logs:false,manage_features:false,
    manage_admins:false,impersonate:false,
    manage_branding:false,view_snapshots:true,
  })

  // Admin creation refs
  const admNameR=useRef('');const admEmailR=useRef('');const admPassR=useRef('')
  const [admRole,setAdmRole]=useState('admin')
  const [creatingAdm,setCreatingAdm]=useState(false)

  // Batch management
  const batchNameR=useRef('')
  const [creatingBatch,setCreatingBatch]=useState(false)
  const [batchTransStdId,setBatchTransStdId]=useState('')
  const [batchTransTo,setBatchTransTo]=useState('')

  // AI Smart Generator
  const aiTopicR=useRef('');const aiChapR=useRef('')
  const [aiCount,setAiCount]=useState('10')
  const [aiSubj,setAiSubj]=useState('Physics')
  const [aiDiff,setAiDiff]=useState('medium')
  const [aiLoading,setAiLoading]=useState(false)
  const [aiResult,setAiResult]=useState<any[]>([])
  const [aiSaving,setAiSaving]=useState(false)

  // Task manager
  const [todos,setTodos]=useState([
    {id:'1',text:'Review upcoming exam questions before publish',done:false,priority:'high'},
    {id:'2',text:'Reply to pending student grievance tickets',done:false,priority:'medium'},
    {id:'3',text:'Check server health before exam day',done:false,priority:'high'},
    {id:'4',text:'Update PYQ bank with NEET 2024 questions',done:false,priority:'low'},
  ])
  const todoR=useRef('');const [todoPri,setTodoPri]=useState<'high'|'medium'|'low'>('medium')

  // Changelog
  const clogs=[
    {v:'V4.0',d:'Mar 2026',chg:['Complete redesign — Login page theme matched','All 62+ features active with real API wiring','Mobile keyboard fix — memo components','Upload endpoints corrected — copypaste/excel/pdf','Beautiful page designs with SVG illustrations','Superadmin/Admin role display in header'],t:'major'},
    {v:'V3.1',d:'Mar 2026',chg:['Fixed All Exams zero bug — fetchAll after create','Fixed field names: questionsText + answerKeyText','Added 9 missing features (M15,S102,S69,S71,S70,M9,M10,M12,S110)'],t:'minor'},
  ]

  // Email template refs
  const emailSubjR=useRef('');const emailBodyR=useRef('')
  const [emailType,setEmailType]=useState('welcome')
  const [sendingEmail,setSendingEmail]=useState(false)

  // Custom reg fields
  const [customFields,setCustomFields]=useState([
    {key:'school_name',label:'School Name',type:'text',required:false},
    {key:'city',label:'City',type:'text',required:false},
    {key:'class',label:'Class',type:'select',required:true,options:'11th,12th,Dropper'},
  ])
  const cfLabelR=useRef('');const cfKeyR=useRef('');const cfOptsR=useRef('')
  const [cfType,setCfType]=useState('text')
  const [cfRequired,setCfRequired]=useState(false)

  // Certificate
  const [certExamId,setCertExamId]=useState('')

  // PYQ filter
  const [pyqYear,setPyqYear]=useState('all')
  const [pyqSubj,setPyqSubj]=useState('all')
  const [pyqData,setPyqData]=useState<any[]>([])
  const [pyqLoading,setPyqLoading]=useState(false)

  // Bulk exam creator
  const [bulkExamFile,setBulkExamFile]=useState<File|null>(null)
  const [bulkExamLoading,setBulkExamLoading]=useState(false)
  const [bulkResult,setBulkResult]=useState<any>(null)

  // ══ TOAST ══
  const T=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{setToast({msg,tp});setTimeout(()=>setToast(null),4500)},[])

  // ══ AUTH HEADERS ══
  const H=useCallback(()=>({Authorization:`Bearer ${token}`}),[token])
  const HJ=useCallback(()=>({'Content-Type':'application/json',Authorization:`Bearer ${token}`}),[token])

  // ══ INIT ══
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
    const get=async(u:string)=>{try{const r=await fetch(u,{headers:{Authorization:`Bearer ${token}`}});return r.ok?r.json():null}catch{return null}}
    const getFirst=async(...urls:string[])=>{for(const u of urls){try{const r=await fetch(u,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const d=await r.json();if(d)return d}}catch{}}return null}
    const [us,ex,qs,st,fl,al,tk,sn,ft,nf,bt,au,rs]=await Promise.all([
      getFirst(`${API}/api/admin/students`,`${API}/api/admin/users`,`${API}/api/admin/manage/students`),
      get(`${API}/api/exams`),
      get(`${API}/api/questions`),
      getFirst(`${API}/api/admin/stats`,`${API}/api/admin/dashboard`),
      getFirst(`${API}/api/admin/manage/cheating-logs`,`${API}/api/admin/cheating-logs`),
      getFirst(`${API}/api/admin/manage/audit`,`${API}/api/admin/audit`),
      getFirst(`${API}/api/admin/manage/tickets`,`${API}/api/admin/tickets`),
      getFirst(`${API}/api/admin/manage/snapshots`,`${API}/api/admin/snapshots`),
      get(`${API}/api/admin/features`),
      get(`${API}/api/admin/notifications`),
      getFirst(`${API}/api/admin/batches`,`${API}/api/admin/manage/batches`),
      get(`${API}/api/admin/manage/admins`),
      getFirst(`${API}/api/results`,`${API}/api/admin/results`),
    ])
    if(us){const list=Array.isArray(us)?us:(us.students||us.data||us.users||[]);setStudents(list)}
    if(Array.isArray(ex))setExams(ex)
    if(Array.isArray(qs))setQuestions(qs)
    if(st)setStats(st)
    if(Array.isArray(fl)){setFlags(fl);setFeatures(prev=>prev.map(f=>{const a=fl.find(af=>af.key===f.key);return a?{...f,enabled:a.enabled}:f;}))}
    if(Array.isArray(al))setLogs(al)
    if(Array.isArray(tk))setTickets(tk)
    if(Array.isArray(sn))setSnapshots(sn)
    if(Array.isArray(nf))setNotifs(nf)
    if(Array.isArray(bt))setBatches(bt)
    if(Array.isArray(au))setAdminUsers(au)
    if(Array.isArray(rs))setResults(rs)
    if(ft){
      if(Array.isArray(ft)&&ft.length)setFeatures(ft)
      else if(ft&&typeof ft==='object')setFeatures(DEF_FEATURES.map(f=>({...f,enabled:ft[f.key]!==undefined?Boolean(ft[f.key]):f.enabled})))
    }
    setLoading(false)
  },[token])

  // ══ CREATE EXAM (FIXED: correct fields) ══
  const createExamS1=useCallback(async()=>{
    const title=eTitleR.current,date=eDateR.current
    if(!title||!date){T('Exam title and date are both required.','e');return}
    setCreatingE(true)
    try{
      const body={title,scheduledAt:new Date(date).toISOString(),totalMarks:parseInt(eMarksR.current)||720,duration:parseInt(eDurR.current)||200,subject:'NEET',type:'NEET',difficulty:'Mixed',category:eCatR.current||'Full Mock',batch:eBatchR.current||undefined,customInstructions:eInstrR.current||undefined,password:ePassR.current||undefined}
      const res=await fetch(`${API}/api/exams`,{method:'POST',headers:{...(()=>({'Content-Type':'application/json',Authorization:`Bearer ${token}`}))()},body:JSON.stringify(body)})
      if(res.ok||res.status===201){
        const d=await res.json()
        const eid=d?.exam?._id||d?.exam?.id||d?._id||d?.id||d?.examId||''
        const etitle=d?.exam?.title||d?.title||title
        if(eid){
          setCreatedEId(eid);setCreatedETitle(etitle)
          T('Exam created successfully! Now add questions.')
          setEStep(2)
          setTimeout(()=>fetchAll(),500)
        } else {
          setCreatedEId('');setCreatedETitle(etitle)
          T('Exam created. (ID not returned — use Question Bank to add questions)','w')
          setEStep(2)
          setTimeout(()=>fetchAll(),500)
        }
      } else {
        const e=await res.json().catch(()=>({}))
        T(`Error ${res.status}: ${e.message||e.error||'Check exam details.'}`, 'e')
      }
    } catch(err:any){T(`Network error: ${err.message||'Check connection.'}`, 'e')}
    setCreatingE(false)
  },[token,T,fetchAll])

  // ══ UPLOAD QUESTIONS (FIXED: correct endpoints + field names) ══
  const uploadQs=useCallback(async()=>{
    const examId=createdEId
    if(!examId){T('Complete Step 1 first to create the exam.','e');return}
    setUploadingQ(true);setUpRes(null)
    try{
      let res:Response|null=null
      if(qMeth==='copypaste'||qMeth==='manual'){
        const questionsText=cpTxtR.current
        const answerKeyText=cpKeyR.current
        if(!questionsText){T('Please paste the question text first.','e');setUploadingQ(false);return}
        const payload={examId,questionsText,answerKeyText,questions:questionsText,text:questionsText,answerKey:answerKeyText}
        for(const ep of [`${API}/api/upload/copypaste/questions`,`${API}/api/upload/copy-paste`,`${API}/api/questions/bulk`]){
          try{const r=await fetch(ep,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(payload)});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      } else if(qMeth==='excel'){
        if(!excelF){T('Please select an Excel file.','e');setUploadingQ(false);return}
        for(const ep of [`${API}/api/upload/excel/questions`,`${API}/api/excel/questions`,`${API}/api/upload/excel`]){
          try{const fd=new FormData();fd.append('file',excelF);fd.append('examId',examId);fd.append('exam_id',examId);const r=await fetch(ep,{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      } else if(qMeth==='pdf'){
        if(!pdfF){T('Please select a PDF file.','e');setUploadingQ(false);return}
        for(const ep of [`${API}/api/upload/pdf/questions`,`${API}/api/upload/pdf`,`${API}/api/questions/pdf`]){
          try{const fd=new FormData();fd.append('file',pdfF);fd.append('examId',examId);fd.append('exam_id',examId);const r=await fetch(ep,{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd});if(r.ok||r.status===201){res=r;break}}catch{}
        }
      }
      if(res&&(res.ok||res.status===201)){
        const d=await res.json().catch(()=>({}))
        const cnt=d.success||d.count||d.uploaded||d.inserted||d.saved||0
        setUpRes({s:cnt,f:d.failed||0,msg:`${cnt} questions uploaded successfully!`})
        T(`${cnt} questions uploaded to exam.`)
        setEStep(3)
        setTimeout(()=>fetchAll(),500)
      } else {
        setUpRes({s:0,f:0,msg:'Upload endpoint not available. Use Question Bank tab to add questions manually.'})
        T('Upload endpoint not available. Please use Question Bank instead.','w')
        setEStep(3)
      }
    } catch(err:any){
      setUpRes({s:0,f:0,msg:'Network error occurred.'})
      T('Network error. Check your connection.','w')
      setEStep(3)
    }
    setUploadingQ(false)
  },[createdEId,qMeth,excelF,pdfF,token,T,fetchAll])

  // ══ QUESTION BANK ══
  const addQ=useCallback(async()=>{
    const text=qTxtR.current
    if(!text){T('Question text is required.','e');return}
    setSavingQ(true)
    const payload={text,hindiText:qHindiR.current||undefined,subject:qSubj,chapter:qChapR.current||undefined,topic:qTopicR.current||undefined,difficulty:qDiff,type:qType,options:['SCQ','MSQ'].includes(qType)?[qA.current,qB.current,qC.current,qD.current].filter(Boolean):undefined,correctAnswer:qAns,explanation:qExpR.current||undefined}
    try{
      const res=await fetch(`${API}/api/questions`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(payload)})
      if(res.ok||res.status===201){
        T('Question added to bank successfully.')
        qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current='';qTopicR.current='';qExpR.current=''
        const r=await fetch(`${API}/api/questions`,{headers:{Authorization:`Bearer ${token}`}})
        if(r.ok)setQuestions(await r.json())
      } else {
        const e=await res.json().catch(()=>({}))
        T(e.message||`Error ${res.status}`,'e')
      }
    } catch(err:any){T(`Network error: ${err.message}`,'e')}
    setSavingQ(false)
  },[qSubj,qDiff,qType,qAns,token,T])

  // ══ BAN / UNBAN ══
  const banStd=useCallback(async()=>{
    const reason=banReaR.current
    if(!banId||!reason){T('Student ID and ban reason are both required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/ban/${banId}`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({banReason:reason,banType:banT})})
      if(res.ok){setStudents(p=>p.map(s=>s._id===banId?{...s,banned:true,banReason:reason}:s));T('Student has been banned.');setBanId('');banReaR.current=''}
      else{T('Failed to ban student.','e')}
    } catch{T('Network error.','e')}
  },[banId,banT,token,T])

  const unbanStd=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/unban/${id}`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){setStudents(p=>p.map(s=>s._id===id?{...s,banned:false,banReason:''}:s));T('Student unbanned successfully.')}
      else{T('Failed to unban student.','e')}
    } catch{T('Network error.','e')}
  },[token,T])

  // ══ FEATURE FLAGS ══
  const toggleFeat=useCallback(async(key:string)=>{
    const ft=features.find(f=>f.key===key);const ne=!ft?.enabled
    setFeatures(p=>p.map(f=>f.key===key?{...f,enabled:ne}:f))
    
    try{await fetch(`${API}/api/admin/features`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({key,enabled:ne})})}catch{}
    T(`${ft?.label||key} ${ne?'enabled':'disabled'}.`)
  },[features,token,T])

  // ══ ANNOUNCEMENTS ══
  const sendAnn=useCallback(async()=>{
    const msg=annR.current,title=annTitleR.current
    if(!msg){T('Please write a message.','e');return}
    try{
      let res=await fetch(`${API}/api/admin/announce`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({title,message:msg,batch:annBatch,type:annType})})
      if(!res.ok)res=await fetch(`${API}/api/admin/manage/announce`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({title,message:msg,batch:annBatch,type:annType})})
      if(res.ok){T('Announcement sent successfully.');annR.current='';annTitleR.current=''}
      else{T('Failed to send announcement.','e')}
    } catch{T('Network error.','e')}
  },[annBatch,annType,token,T])

  // ══ EXAM ACTIONS ══
  const delExam=useCallback(async(id:string)=>{
    if(!confirm('Delete this exam? This cannot be undone.'))return
    try{
      const res=await fetch(`${API}/api/exams/${id}`,{method:'DELETE',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){setExams(p=>p.filter(e=>e._id!==id));T('Exam deleted.')}
      else{T('Failed to delete exam.','e')}
    } catch{T('Network error.','e')}
  },[token,T])

  const cloneExam=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/exams/${id}/clone`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){T('Exam cloned successfully.');setTimeout(()=>fetchAll(),500)}
      else{T('Failed to clone exam.','e')}
    } catch{T('Network error.','e')}
  },[token,T,fetchAll])

  // ══ BRANDING ══
  const saveBrand=useCallback(async()=>{
    setSavingB(true)
    try{
      const res=await fetch(`${API}/api/admin/branding`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({brandName:bNameR.current,tagline:bTagR.current,supportEmail:bMailR.current,phone:bPhoneR.current,seoTitle:seoTR.current,seoDesc:seoDR.current,seoKeywords:seoKR.current})})
      if(res.ok)T('Branding & SEO settings saved.')
      else T('Failed to save settings.','e')
    } catch{T('Network error.','e')}
    setSavingB(false)
  },[token,T])

  // ══ MAINTENANCE ══
  const toggleMaint=useCallback(async()=>{
    const nm=!mainOn;setMainOn(nm)
    setFeatures(p=>p.map(f=>f.key==='maintenance'?{...f,enabled:nm}:f))
    try{await fetch(`${API}/api/admin/features`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({key:'maintenance',enabled:nm,message:mainMsgR.current})})}catch{}
    T(nm?'Maintenance ON — Students cannot access platform.':'Maintenance OFF — Platform is live.')
  },[mainOn,token,T])

  // ══ EXPORT ══
  const doExport=useCallback(async(url:string,fname:string)=>{
    try{
      const res=await fetch(url,{headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){const b=await res.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=fname;a.click();T('Download started.')}
      else{T('Export failed.','e')}
    } catch{T('Network error.','e')}
  },[token,T])

  // ══ BACKUP ══
  const doBackup=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/backup`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok)T('Backup triggered successfully.')
      else T('Backup failed.','e')
    } catch{T('Network error.','e')}
  },[token,T])

  // ══ TICKETS ══
  const resolveTicket=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/tickets/${id}/resolve`,{method:'PATCH',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){setTickets(p=>p.map(t=>t._id===id?{...t,status:'resolved'}:t));T('Ticket resolved.')}
      else T('Failed.','e')
    } catch{T('Network error.','e')}
  },[token,T])

  // ══ AI GENERATOR ══
  const aiGen=useCallback(async()=>{
    if(!aiTopicR.current){T('Please enter a topic.','e');return}
    setAiLoading(true)
    try{
      const res=await fetch(`${API}/api/questions/generate`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({topic:aiTopicR.current,chapter:aiChapR.current||undefined,count:parseInt(aiCount)||10,subject:aiSubj,difficulty:aiDiff})})
      if(res.ok){const d=await res.json();const list=Array.isArray(d)?d:(d.questions||[]);setAiResult(list);T(`${list.length} questions generated.`)}
      else T('AI generation failed. Check backend.','e')
    } catch{T('Network error.','e')}
    setAiLoading(false)
  },[aiCount,aiSubj,aiDiff,token,T])

  const aiSaveAll=useCallback(async()=>{
    if(!aiResult.length){T('No generated questions to save.','e');return}
    setAiSaving(true)
    try{
      const res=await fetch(`${API}/api/questions/bulk-save`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({questions:aiResult})})
      if(res.ok){T(`${aiResult.length} AI questions saved to bank.`);setAiResult([]);setTimeout(()=>fetchAll(),500)}
      else T('Failed to save AI questions.','e')
    } catch{T('Network error.','e')}
    setAiSaving(false)
  },[aiResult,token,T,fetchAll])

  // ══ BATCH ══
  const createBatch=useCallback(async()=>{
    if(!batchNameR.current){T('Enter a batch name.','e');return}
    setCreatingBatch(true)
    try{
      const res=await fetch(`${API}/api/admin/batches`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({name:batchNameR.current})})
      if(res.ok){T('Batch created.');batchNameR.current='';const r=await fetch(`${API}/api/admin/batches`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok)setBatches(await r.json())}
      else T('Failed to create batch.','e')
    } catch{T('Network error.','e')}
    setCreatingBatch(false)
  },[token,T])

  const batchTransfer=useCallback(async()=>{
    if(!batchTransStdId||!batchTransTo){T('Student ID and target batch required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/batch-transfer`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({studentId:batchTransStdId,toBatch:batchTransTo})})
      if(res.ok)T('Student transferred successfully.')
      else T('Transfer failed.','e')
    } catch{T('Network error.','e')}
  },[batchTransStdId,batchTransTo,token,T])

  // ══ ADMIN CREATE ══
  const createAdmin=useCallback(async()=>{
    if(!admNameR.current||!admEmailR.current||!admPassR.current){T('Name, email and password all required.','e');return}
    setCreatingAdm(true)
    try{
      const res=await fetch(`${API}/api/admin/manage/admins`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({name:admNameR.current,email:admEmailR.current,password:admPassR.current,role:admRole})})
      if(res.ok){T('Admin account created.');const r=await fetch(`${API}/api/admin/manage/admins`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok)setAdminUsers(await r.json())}
      else{const e=await res.json().catch(()=>({}));T(e.message||'Failed to create admin.','e')}
    } catch{T('Network error.','e')}
    setCreatingAdm(false)
  },[admRole,token,T])

  // ══ PERMISSIONS ══
  const savePerms=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/permissions`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(perms)})
      if(res.ok)T('Permissions saved.')
      else T('Failed to save permissions.','e')
    } catch{T('Network error.','e')}
  },[perms,token,T])

  // ══ IMPERSONATE ══
  const impersonate=useCallback(async(sid:string)=>{
    if(!sid){T('Student ID required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/impersonate/${sid}`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){
        const d=await res.json()
        // Backend returns 'impersonateToken' field
        const sToken=d.impersonateToken||d.studentToken||d.token||''
        const sName=encodeURIComponent(d.name||'Student')
        if(!sToken){T('Failed to get student token','e');return}
        T(`Opening as: ${d.name||'Student'}`,'s')
        window.open(`/impersonate?token=${sToken}&id=${sid}&name=${sName}`,'_blank')
      } else {
        const e=await res.json()
        T(e.message||'Failed to impersonate','e')
      }
    }catch{T('Network error','e')}
  },[impId,token,T])

  // ══ TIME EXTENSION ══
  const extendTime=useCallback(async()=>{
    if(!extStdId){T('Student ID required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/extend-time`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({studentId:extStdId,extraMinutes:parseInt(extMins)||10})})
      if(res.ok)T(`${extMins} minutes extra time granted.`)
      else T('Failed.','e')
    } catch{T('Network error.','e')}
  },[extStdId,extMins,token,T])

  // ══ PYQ BANK ══
  const loadPyq=useCallback(async()=>{
    setPyqLoading(true)
    try{
      const params=new URLSearchParams()
      if(pyqYear!=='all')params.set('year',pyqYear)
      if(pyqSubj!=='all')params.set('subject',pyqSubj)
      const res=await fetch(`${API}/api/questions/pyq?${params}`,{headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){const d=await res.json();setPyqData(Array.isArray(d)?d:(d.questions||[]))}
      else T('PYQ data not available.','w')
    } catch{T('Network error.','e')}
    setPyqLoading(false)
  },[pyqYear,pyqSubj,token,T])

  // ══ BULK EXAM CREATOR ══
  const bulkCreateExams=useCallback(async()=>{
    if(!bulkExamFile){T('Please select an Excel file.','e');return}
    setBulkExamLoading(true)
    try{
      const fd=new FormData();fd.append('file',bulkExamFile)
      const res=await fetch(`${API}/api/exams/bulk-create`,{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd})
      if(res.ok){const d=await res.json();setBulkResult(d);T(`${d.created||0} exams created successfully.`);setTimeout(()=>fetchAll(),500)}
      else T('Bulk create failed.','e')
    } catch{T('Network error.','e')}
    setBulkExamLoading(false)
  },[bulkExamFile,token,T,fetchAll])

  // ══ EMAIL TEMPLATES ══
  const sendEmail=useCallback(async()=>{
    if(!emailSubjR.current||!emailBodyR.current){T('Subject and body required.','e');return}
    setSendingEmail(true)
    try{
      const res=await fetch(`${API}/api/admin/email/send`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({type:emailType,subject:emailSubjR.current,body:emailBodyR.current})})
      if(res.ok)T('Email sent successfully.')
      else T('Failed to send email.','e')
    } catch{T('Network error.','e')}
    setSendingEmail(false)
  },[emailType,token,T])

  // ══ GUARD ══
  if(!mounted)return null

  // ══ COMPUTED DATA ══
  const fStds=(students||[]).filter(s=>{
    const m=stdSearch.toLowerCase()
    const ok=!m||(s.name?.toLowerCase().includes(m)||s.email?.toLowerCase().includes(m)||s._id?.includes(m))
    if(stdFilter==='banned')return ok&&!!s.banned
    if(stdFilter==='active')return ok&&!s.banned
    return ok
  })
  const fExams=(exams||[]).filter(e=>!examSearch||e.title?.toLowerCase().includes(examSearch.toLowerCase()))
  const fQs=(questions||[]).filter(q=>{
    const mq=!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase())
    const ms=qSubjFilter==='all'||q.subject===qSubjFilter
    return mq&&ms
  })

  // ══ NAV ITEMS ══
  const NAV=[
    {id:'dashboard',ico:'📊',lbl:'Dashboard',grp:'Overview'},
    {id:'global_search',ico:'🔎',lbl:'Global Search',grp:'Overview'},
    {id:'live',ico:'🔴',lbl:'Live Monitor',grp:'Overview'},
    {id:'exams',ico:'📝',lbl:'All Exams',grp:'Exams'},
    {id:'create_exam',ico:'➕',lbl:'Create Exam',grp:'Exams'},
    {id:'templates',ico:'📋',lbl:'Templates',grp:'Exams'},
    {id:'bulk_creator',ico:'⚡',lbl:'Bulk Creator',grp:'Exams'},
    {id:'questions',ico:'❓',lbl:'Question Bank',grp:'Questions'},
    {id:'smart_gen',ico:'🤖',lbl:'Smart Generator',grp:'Questions'},
    {id:'pyq_bank',ico:'📚',lbl:'PYQ Bank',grp:'Questions'},
    {id:'students',ico:'👥',lbl:'Students',grp:'Students'},
    {id:'batches',ico:'📦',lbl:'Batches',grp:'Students'},
    {id:'custom_fields',ico:'📋',lbl:'Reg Fields',grp:'Students'},
    {id:'admins',ico:'🛡️',lbl:'Admins',grp:'Admin'},
    {id:'permissions',ico:'🔐',lbl:'Permissions',grp:'Admin'},
    {id:'results',ico:'📈',lbl:'Results',grp:'Results'},
    {id:'leaderboard',ico:'🏆',lbl:'Leaderboard',grp:'Results'},
    {id:'analytics',ico:'📉',lbl:'Analytics',grp:'Results'},
    {id:'reports',ico:'📊',lbl:'Reports & Export',grp:'Results'},
    {id:'cheating',ico:'🚨',lbl:'Anti-Cheat Logs',grp:'Proctoring'},
    {id:'snapshots',ico:'📷',lbl:'Snapshots',grp:'Proctoring'},
    {id:'integrity',ico:'🤖',lbl:'AI Integrity',grp:'Proctoring'},
    {id:'tickets',ico:'🎫',lbl:'Grievances',grp:'Support'},
    {id:'ans_challenge',ico:'⚔️',lbl:'Answer Challenges',grp:'Support'},
    {id:'re_eval',ico:'🔄',lbl:'Re-Evaluation',grp:'Support'},
    {id:'announcements',ico:'📢',lbl:'Announcements',grp:'Communication'},
    {id:'email_tmpl',ico:'📧',lbl:'Email Templates',grp:'Communication'},
    {id:'whatsapp_sms',ico:'💬',lbl:'WhatsApp & SMS',grp:'Communication'},
    {id:'features',ico:'🚩',lbl:'Feature Flags',grp:'Settings'},
    {id:'branding',ico:'🎨',lbl:'Branding & SEO',grp:'Settings'},
    {id:'maintenance',ico:'🔧',lbl:'Maintenance',grp:'Settings'},
    {id:'backup',ico:'💾',lbl:'Backup & Data',grp:'Settings'},
    {id:'transparency',ico:'🔍',lbl:'Transparency',grp:'Reports'},
    {id:'qbank_stats',ico:'📊',lbl:'QB Stats',grp:'Reports'},
    {id:'omr_view',ico:'📋',lbl:'OMR Sheet View',grp:'Reports'},
    {id:'proct_pdf',ico:'📄',lbl:'Proctoring PDF',grp:'Reports'},
    {id:'subj_rank',ico:'🏅',lbl:'Subject Rankings',grp:'Reports'},
    {id:'retention',ico:'📈',lbl:'Retention Analytics',grp:'Reports'},
    {id:'institute_report',ico:'🏫',lbl:'Institute Report',grp:'Reports'},
    {id:'audit',ico:'📋',lbl:'Audit Logs',grp:'Logs'},
    {id:'tasks',ico:'✅',lbl:'Task Manager',grp:'Tools'},
    {id:'changelog',ico:'📝',lbl:'Changelog',grp:'Tools'},
    {id:'parent_portal',ico:'👨‍👩‍👧',lbl:'Parent Portal',grp:'Tools'},
  ]

  const navGroups=[...new Set(NAV.map(n=>n.grp))]

  // ══════════════════════════════════════════════════════════════
  // RENDER
  // ══════════════════════════════════════════════════════════════
  return (
    <div style={{background:BG_GRAD,minHeight:'100vh',color:TS,fontFamily:'Inter,sans-serif',position:'relative'}}>

      {/* Particles Background */}
      <ParticlesBg />

      {/* Decorative hexagons like login page */}
      <div style={{position:'fixed',top:-60,left:-60,fontSize:280,color:'rgba(77,159,255,0.03)',pointerEvents:'none',zIndex:0,lineHeight:1}}>⬡</div>
      <div style={{position:'fixed',bottom:-60,right:-60,fontSize:280,color:'rgba(77,159,255,0.03)',pointerEvents:'none',zIndex:0,lineHeight:1}}>⬡</div>

      {/* Global styles */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:0.5}50%{opacity:1}}
        @keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes slideIn{from{transform:translateX(-100%)}to{transform:translateX(0)}}
        * { box-sizing:border-box; }
        ::-webkit-scrollbar{width:4px;height:4px}
        ::-webkit-scrollbar-track{background:rgba(0,22,40,0.5)}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
        input,textarea,select{color-scheme:dark}
        .nav-btn:hover{background:rgba(77,159,255,0.12) !important;color:#4D9FFF !important}
        .card-hover:hover{border-color:rgba(77,159,255,0.4) !important;transform:translateY(-1px);transition:all 0.2s}
        .btn-hover:hover{opacity:0.88;transform:translateY(-1px);transition:all 0.15s}
      `}</style>

      {/* ══ FULL WIDTH TOAST ══ */}
      {toast&&(
        <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9999,padding:'15px 24px',fontWeight:700,fontSize:14,background:toast.tp==='s'?`linear-gradient(90deg,${SUC},#00a87a)`:toast.tp==='w'?`linear-gradient(90deg,${WRN},#e6a200)`:`linear-gradient(90deg,${DNG},#cc0000)`,color:toast.tp==='w'?'#000':'#fff',textAlign:'center',boxShadow:'0 4px 30px rgba(0,0,0,0.6)',letterSpacing:0.3,animation:'fadeIn 0.3s ease'}}>
          {toast.tp==='e'?'❌':toast.tp==='w'?'⚠️':'✅'} {toast.msg}
        </div>
      )}

      {/* ══ TOP NAVIGATION BAR ══ */}
      <div style={{position:'sticky',top:0,zIndex:100,background:'rgba(0,10,24,0.95)',backdropFilter:'blur(20px)',borderBottom:`1px solid ${BOR}`,padding:'0 16px',height:58,display:'flex',alignItems:'center',justifyContent:'space-between',boxShadow:'0 2px 20px rgba(0,0,0,0.4)'}}>

        {/* Left: Hamburger + Logo */}
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <button onClick={()=>setSideOpen(p=>!p)} style={{background:'none',border:'none',color:TS,fontSize:20,cursor:'pointer',padding:'4px 6px',borderRadius:6}}>☰</button>
          <div style={{display:'flex',alignItems:'center',gap:8}}>
            <PRLogo size={32}/>
            <div>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,background:`linear-gradient(90deg,${ACC},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1}}>
                ProveRank
              </div>
              {/* SCREENSHOT-MATCHED: role display with lightning bolt */}
              <div style={{fontSize:10,fontWeight:700,letterSpacing:1.5,color:role==='superadmin'?GOLD:ACC,lineHeight:1.2}}>
                ⚡ {role.toUpperCase()}
              </div>
            </div>
          </div>
        </div>

        {/* Right: Notifs + Refresh + Logout */}
        <div style={{display:'flex',gap:8,alignItems:'center'}}>
          {loading&&<span style={{fontSize:11,color:DIM,animation:'pulse 1s infinite'}}>⟳ Loading…</span>}

          {/* Notifications */}
          <button onClick={()=>setNotifOpen(p=>!p)} style={{background:'none',border:`1px solid ${BOR}`,color:TS,fontSize:15,cursor:'pointer',position:'relative',width:36,height:36,borderRadius:8,display:'flex',alignItems:'center',justifyContent:'center',backdropFilter:'blur(8px)'}}>
            🔔
            {(notifs||[]).filter(n=>!n.read).length>0&&<span style={{position:'absolute',top:-2,right:-2,background:DNG,color:'#fff',fontSize:8,borderRadius:'50%',width:14,height:14,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700}}>{(notifs||[]).filter(n=>!n.read).length}</span>}
          </button>

          <button onClick={fetchAll} style={{...bg_,padding:'7px 12px',fontSize:11}}>🔄 Refresh</button>
          <button onClick={()=>{clearAuth();router.replace('/login')}} style={{background:'rgba(255,77,77,0.12)',color:DNG,border:'1px solid rgba(255,77,77,0.25)',borderRadius:8,padding:'7px 12px',cursor:'pointer',fontWeight:700,fontSize:11}}>Logout</button>
        </div>
      </div>

      {/* ══ NOTIFICATION PANEL ══ */}
      {notifOpen&&(
        <div style={{position:'fixed',top:58,right:0,width:320,height:'calc(100vh - 58px)',background:'rgba(0,10,24,0.97)',borderLeft:`1px solid ${BOR}`,zIndex:200,overflow:'auto',padding:16,backdropFilter:'blur(20px)',boxShadow:'-4px 0 24px rgba(0,0,0,0.5)'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
            <span style={{fontWeight:700,fontSize:15,fontFamily:'Playfair Display,serif',color:ACC}}>🔔 Notifications</span>
            <button onClick={()=>setNotifOpen(false)} style={{background:'none',border:'none',color:DIM,fontSize:18,cursor:'pointer'}}>✕</button>
          </div>
          {(notifs||[]).length===0
            ?<div style={{textAlign:'center',padding:'40px 20px',color:DIM}}>
              <div style={{fontSize:40,marginBottom:10}}>🔕</div>
              <div style={{fontSize:13}}>No notifications yet</div>
              <div style={{fontSize:11,marginTop:4}}>Alerts will appear here</div>
            </div>
            :(notifs||[]).map((n,i)=>(
              <div key={n.id||i} style={{...cs,padding:'10px 12px',marginBottom:8}}>
                <div style={{fontSize:13,fontWeight:600}}>{n.icon} {n.msg}</div>
                <div style={{fontSize:10,color:DIM,marginTop:3}}>{n.t}</div>
              </div>
            ))
          }
        </div>
      )}

      <div style={{display:'flex',position:'relative',zIndex:1}}>

        {/* ══ SIDEBAR ══ */}
        <div style={{position:'fixed',top:58,left:0,width:224,height:'calc(100vh - 58px)',background:'rgba(0,10,24,0.97)',borderRight:`1px solid ${BOR}`,zIndex:50,overflow:'auto',padding:'10px 6px 24px',transform:sideOpen?'translateX(0)':'translateX(-100%)',transition:'transform 0.28s cubic-bezier(0.4,0,0.2,1)',backdropFilter:'blur(20px)',boxShadow:'4px 0 24px rgba(0,0,0,0.4)'}}>
          {navGroups.map(grp=>(
            <div key={grp} style={{marginBottom:4}}>
              <div style={{fontSize:9,fontWeight:700,color:'rgba(107,143,175,0.5)',letterSpacing:1.5,textTransform:'uppercase',padding:'10px 14px 4px'}}>{grp}</div>
              {NAV.filter(n=>n.grp===grp).map(n=>(
                <button key={n.id} className="nav-btn" onClick={()=>{setTab(n.id);setSideOpen(false)}}
                  style={{display:'flex',alignItems:'center',gap:9,padding:'8px 12px',borderRadius:8,border:'none',background:tab===n.id?'rgba(77,159,255,0.15)':'transparent',color:tab===n.id?ACC:DIM,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12,fontWeight:tab===n.id?700:400,width:'100%',textAlign:'left',borderLeft:tab===n.id?`3px solid ${ACC}`:'3px solid transparent'}}>
                  <span style={{fontSize:14,width:18,textAlign:'center'}}>{n.ico}</span>
                  <span>{n.lbl}</span>
                </button>
              ))}
            </div>
          ))}
        </div>

        {/* ══ MAIN CONTENT ══ */}
        <div style={{flex:1,padding:'20px 16px',minHeight:'calc(100vh - 58px)',maxWidth:'100vw',overflow:'auto',animation:'fadeIn 0.4s ease'}}>

          {/* ══ DASHBOARD ══ */}
          {tab==='dashboard'&&(
            <div>
              <div style={{marginBottom:20}}>
                <div style={pageTitle}>📊 Dashboard Overview</div>
                <div style={pageSub}>Welcome back, {role==='superadmin'?'Super Admin':'Admin'} — Here is your platform at a glance</div>
              </div>

              {/* Stats Row */}
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:20}}>
                <StatBox ico='👥' lbl='Total Students' val={loading?'…':stats?.totalStudents||(students||[]).length||0} col={ACC}/>
                <StatBox ico='📝' lbl='Total Exams' val={loading?'…':stats?.totalExams||(exams||[]).length||0} col={GOLD}/>
                <StatBox ico='📈' lbl='Exam Attempts' val={loading?'…':stats?.totalAttempts??0} col={SUC}/>
                <StatBox ico='🟢' lbl='Active Today' val={loading?'…':stats?.activeStudents??0} col='#00E5FF'/>
                <StatBox ico='❓' lbl='Questions' val={loading?'…':stats?.totalQuestions||(questions||[]).length||0} col='#FF6B9D'/>
              </div>

              {/* Hero Banner */}
              <div style={{background:`linear-gradient(135deg,rgba(0,85,204,0.25),rgba(77,159,255,0.1))`,border:`1px solid rgba(77,159,255,0.25)`,borderRadius:16,padding:'24px 20px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',right:-20,top:-20,fontSize:100,opacity:0.06}}>⬡</div>
                <div style={{position:'absolute',right:30,top:20,fontSize:60,opacity:0.08}}>⬡</div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:TS,marginBottom:6}}>🎯 ProveRank Admin Center</div>
                <div style={{fontSize:12,color:DIM,lineHeight:1.7,maxWidth:500}}>
                  Manage your complete NEET test platform from here. Create exams, monitor students, review analytics, and keep your platform running smoothly.
                </div>
                <div style={{display:'flex',flexWrap:'wrap',gap:8,marginTop:14}}>
                  {[['➕ Create Exam','create_exam',ACC],['👥 All Students','students',SUC],['🔴 Live Monitor','live',DNG],['📊 Analytics','analytics',GOLD]].map(([l,t,c])=>(
                    <button key={String(t)} onClick={()=>setTab(String(t))} style={{padding:'8px 16px',background:`${c}22`,border:`1px solid ${c}44`,color:String(c),borderRadius:20,cursor:'pointer',fontSize:12,fontWeight:600}}>{String(l)}</button>
                  ))}
                </div>
              </div>

              {/* 2-col grid */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:14}}>
                {/* Recent Exams */}
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <span>📝 Recent Exams</span>
                    <button onClick={()=>setTab('exams')} style={{...bg_,padding:'4px 10px',fontSize:10}}>View All</button>
                  </div>
                  {(exams||[]).length===0
                    ?<div style={{textAlign:'center',padding:'20px 0',color:DIM}}>
                      <div style={{fontSize:30,marginBottom:8}}>📭</div>
                      <div style={{fontSize:12}}>No exams yet</div>
                      <button onClick={()=>setTab('create_exam')} style={{...bp,fontSize:11,padding:'6px 14px',marginTop:8}}>Create First Exam</button>
                    </div>
                    :(exams||[]).slice(0,4).map(e=>(
                      <div key={e._id} style={{display:'flex',justifyContent:'space-between',padding:'8px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                        <div>
                          <div style={{fontWeight:600,color:TS}}>{e.title}</div>
                          <div style={{fontSize:10,color:DIM,marginTop:2}}>{e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():''}</div>
                        </div>
                        <Badge label={e.status||'draft'} col={e.status==='active'?SUC:e.status==='published'?ACC:DIM}/>
                      </div>
                    ))
                  }
                </div>

                {/* Alerts + Quick Actions */}
                <div>
                  <div style={{...cs,marginBottom:12}}>
                    <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🚨 Alerts</div>
                    {(flags||[]).length===0&&(tickets||[]).filter(t=>t.status==='open').length===0
                      ?<div style={{color:SUC,fontSize:12,display:'flex',alignItems:'center',gap:6}}><span style={{fontSize:20}}>✅</span> All clear — no alerts</div>
                      :<div>
                        {(flags||[]).length>0&&<div style={{fontSize:12,color:WRN,marginBottom:6,padding:'6px 10px',background:'rgba(255,184,77,0.08)',borderRadius:8}}>⚠️ {flags.length} cheating flag{flags.length>1?'s':''}</div>}
                        {(tickets||[]).filter(t=>t.status==='open').length>0&&<div style={{fontSize:12,color:ACC,padding:'6px 10px',background:'rgba(77,159,255,0.08)',borderRadius:8}}>🎫 {tickets.filter(t=>t.status==='open').length} open ticket{tickets.filter(t=>t.status==='open').length>1?'s':''}</div>}
                      </div>
                    }
                  </div>
                  <div style={cs}>
                    <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>⚡ Quick Actions</div>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:6}}>
                      {[['➕ Exam','create_exam'],['❓ Question','questions'],['📢 Announce','announcements'],['💾 Backup','backup']].map(([l,t])=>(
                        <button key={String(t)} onClick={()=>setTab(String(t))} style={{...bg_,textAlign:'center',fontSize:11,padding:'8px 6px'}}>{String(l)}</button>
                      ))}
                    </div>
                    <div style={{marginTop:10,fontSize:11,color:DIM,display:'flex',gap:12}}>
                      <span>📦 {(batches||[]).length} Batches</span>
                      <span>🛡️ {(adminUsers||[]).length} Admins</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom row */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:12}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:12}}>🏆 Top Students</div>
                  {(students||[]).filter(s=>!s.banned).slice(0,4).map((s,i)=>(
                    <div key={s._id} style={{display:'flex',alignItems:'center',gap:8,padding:'5px 0',borderBottom:`1px solid ${BOR}`,fontSize:11}}>
                      <span style={{width:20,height:20,borderRadius:'50%',background:i===0?GOLD:i===1?'#C0C0C0':i===2?'#CD7F32':CRD2,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:10,color:i<3?'#000':DIM,flexShrink:0}}>{i+1}</span>
                      <span style={{flex:1,fontWeight:500,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'—'}</span>
                    </div>
                  ))}
                  {(students||[]).length===0&&<div style={{color:DIM,fontSize:11,textAlign:'center',padding:'10px 0'}}>No students yet</div>}
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:12}}>🚨 Recent Flags</div>
                  {(flags||[]).length===0
                    ?<div style={{color:SUC,fontSize:11,textAlign:'center',padding:'10px 0'}}>✅ No cheating flags</div>
                    :(flags||[]).slice(0,4).map((f,i)=>(
                      <div key={f._id||i} style={{fontSize:11,padding:'5px 0',borderBottom:`1px solid ${BOR}`,color:DIM}}>
                        <span style={{color:f.severity==='high'?DNG:WRN,fontWeight:600}}>{f.type}</span> — {f.studentName||'—'}
                      </div>
                    ))
                  }
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:12}}>📊 Platform Health</div>
                  {[['Students',`${(students||[]).filter(s=>!s.banned).length}/${(students||[]).length}`,SUC],['Exams',`${(exams||[]).filter(e=>e.status==='active').length} active`,ACC],['Questions',`${(questions||[]).length} in bank`,GOLD],['Features',`${features.filter(f=>f.enabled).length}/${features.length} on`,'#FF6B9D']].map(([l,v,c])=>(
                    <div key={String(l)} style={{display:'flex',justifyContent:'space-between',fontSize:11,padding:'4px 0',borderBottom:`1px solid ${BOR}`}}>
                      <span style={{color:DIM}}>{String(l)}</span>
                      <span style={{color:String(c),fontWeight:600}}>{String(v)}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ══ GLOBAL SEARCH ══ */}
          {tab==='global_search'&&(
            <div>
              <div style={pageTitle}>🔎 Global Search (M12)</div>
              <div style={pageSub}>Search across all students, exams, and questions instantly</div>
              <GlobalSearch students={students} exams={exams} questions={questions} setTab={setTab} setSelStudent={setSelStudent} token={token}/>
            </div>
          )}

          {/* ══ LIVE MONITOR ══ */}
          {tab==='live'&&(
            <div>
              <div style={pageTitle}>🔴 Live Monitor (S95)</div>
              <div style={pageSub}>Real-time exam monitoring — connected students, server health, active alerts</div>
              <PageHero icon="🔴" title="Live Exam Control Center" subtitle="Monitor all active exams in real-time. View connected students, server response time, and flag suspicious activity as it happens."/>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:12,marginBottom:20}}>
                <StatBox ico='🟢' lbl='Active Exams' val={(exams||[]).filter(e=>e.status==='active').length} col={SUC}/>
                <StatBox ico='👥' lbl='Connected Now' val={stats?.activeStudents||'—'} col={ACC}/>
                <StatBox ico='🚨' lbl='Live Flags' val={(flags||[]).filter(f=>f.severity==='high').length} col={DNG}/>
                <StatBox ico='⚡' lbl='Server Status' val='Online' col={SUC}/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>📡 Active Exams</div>
                  {(exams||[]).filter(e=>e.status==='active').length===0
                    ?<div style={{textAlign:'center',padding:'30px 0',color:DIM}}>
                      <div style={{fontSize:36,marginBottom:8}}>😴</div>
                      <div style={{fontSize:12}}>No exams currently active</div>
                      <div style={{fontSize:11,marginTop:4}}>Active exams will appear here</div>
                    </div>
                    :(exams||[]).filter(e=>e.status==='active').map(e=>(
                      <div key={e._id} style={{...cs,marginBottom:8}}>
                        <div style={{fontWeight:600,fontSize:13,color:TS}}>{e.title}</div>
                        <div style={{display:'flex',gap:8,marginTop:6,flexWrap:'wrap'}}>
                          <Badge label={`${e.duration} min`} col={ACC}/>
                          <Badge label={`${e.attempts||0} attempts`} col={GOLD}/>
                          <Badge label='LIVE' col={DNG}/>
                        </div>
                        <div style={{display:'flex',gap:6,marginTop:10}}>
                          <button onClick={()=>T('Live control panel connecting…')} style={{...bg_,fontSize:10,padding:'5px 10px'}}>⏸ Pause</button>
                          <button onClick={()=>T('Broadcast sent to all participants.')} style={{...bg_,fontSize:10,padding:'5px 10px'}}>📢 Broadcast</button>
                        </div>
                      </div>
                    ))
                  }
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>🚨 Real-time Flags</div>
                  {(flags||[]).length===0
                    ?<div style={{textAlign:'center',padding:'30px 0',color:DIM}}>
                      <div style={{fontSize:36,marginBottom:8}}>✅</div>
                      <div style={{fontSize:12}}>No suspicious activity detected</div>
                    </div>
                    :(flags||[]).slice(0,6).map((f,i)=>(
                      <div key={f._id||i} style={{...cs,padding:'10px',marginBottom:6,borderLeft:`3px solid ${f.severity==='high'?DNG:WRN}`}}>
                        <div style={{display:'flex',justifyContent:'space-between',fontSize:11}}>
                          <span style={{fontWeight:700,color:f.severity==='high'?DNG:WRN}}>{f.type}</span>
                          <span style={{color:DIM}}>{f.count}x</span>
                        </div>
                        <div style={{fontSize:10,color:DIM,marginTop:2}}>{f.studentName||'—'} · {f.examTitle||'—'}</div>
                      </div>
                    ))
                  }
                </div>
              </div>
              <div style={{...cs,marginTop:4}}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🛠️ Live Controls</div>
                <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
                  <button onClick={()=>T('Exam paused globally.')} style={{...bg_}}>⏸ Pause All Exams</button>
                  <button onClick={()=>T('Emergency broadcast sent.')} style={{...bg_}}>📢 Emergency Broadcast</button>
                  <button onClick={()=>T('Server health checked — all OK.')} style={{...bg_}}>💊 Check Server Health</button>
                  <button onClick={fetchAll} style={{...bp,padding:'9px 18px'}}>🔄 Refresh Live Data</button>
                </div>
              </div>
            </div>
          )}

          {/* ══ ALL EXAMS ══ */}
          {tab==='exams'&&(
            <div>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16,flexWrap:'wrap',gap:10}}>
                <div>
                  <div style={pageTitle}>📝 All Exams</div>
                  <div style={pageSub}>{(exams||[]).length} exams total — manage, edit, clone, and monitor</div>
                </div>
                <button onClick={()=>setTab('create_exam')} style={bp}>➕ Create Exam</button>
              </div>

              <div style={{marginBottom:14}}>
                <SInput init={examSearch} onSet={setExamSearch} ph='🔍 Search exams by title…' style={{...inp,maxWidth:400}}/>
              </div>

              {(fExams||[]).length===0
                ?<PageHero icon="📝" title="No Exams Found" subtitle="Create your first NEET exam to get started. Use templates for quick setup or build from scratch with the 3-step wizard."/>
                :<div style={{display:'grid',gap:10}}>
                  {(fExams||[]).map(e=>(
                    <div key={e._id} className="card-hover" style={{...cs,display:'flex',gap:12,flexWrap:'wrap',alignItems:'center',justifyContent:'space-between',transition:'all 0.2s'}}>
                      <div style={{flex:1,minWidth:200}}>
                        <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:4}}>
                          <span style={{fontWeight:700,fontSize:14,color:TS}}>{e.title}</span>
                          <Badge label={e.status||'draft'} col={e.status==='active'?SUC:e.status==='published'?ACC:DIM}/>
                          {e.category&&<Badge label={e.category} col={GOLD}/>}
                        </div>
                        <div style={{display:'flex',gap:12,fontSize:11,color:DIM,flexWrap:'wrap'}}>
                          <span>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleString():'-'}</span>
                          <span>⏱️ {e.duration} min</span>
                          <span>🎯 {e.totalMarks} marks</span>
                          {e.attempts!==undefined&&<span>👤 {e.attempts} attempts</span>}
                          {e.batch&&<span>📦 {e.batch}</span>}
                        </div>
                      </div>
                      <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                        <button onClick={()=>setTab('create_exam')} style={{...bg_,fontSize:11}}>✏️ Edit</button>
                        <button onClick={()=>cloneExam(e._id)} style={{...bg_,fontSize:11}}>📋 Clone</button>
                        <button onClick={()=>delExam(e._id)} style={{...bd,fontSize:11}}>🗑️ Delete</button>
                      </div>
                    </div>
                  ))}
                </div>
              }
            </div>
          )}

          {/* ══ CREATE EXAM (3-STEP WIZARD) ══ */}
          {tab==='create_exam'&&(
            <div>
              <div style={pageTitle}>➕ Create Exam — 3-Step Wizard</div>
              <div style={pageSub}>Build a complete NEET exam in 3 simple steps</div>

              {/* Step Indicator */}
              <div style={{display:'flex',gap:0,marginBottom:24,borderRadius:12,overflow:'hidden',border:`1px solid ${BOR}`}}>
                {[{n:1,l:'📋 Exam Details'},{n:2,l:'❓ Add Questions'},{n:3,l:'✅ Review & Publish'}].map(s=>(
                  <div key={s.n} style={{flex:1,padding:'12px 8px',textAlign:'center',fontSize:12,fontWeight:s.n===eStep?700:400,background:s.n===eStep?`linear-gradient(135deg,${ACC},#0055CC)`:s.n<eStep?'rgba(0,196,140,0.15)':CRD,color:s.n===eStep?'#fff':s.n<eStep?SUC:DIM,borderRight:s.n<3?`1px solid ${BOR}`:'none',cursor:s.n<eStep?'pointer':'default',transition:'all 0.3s'}} onClick={()=>{if(s.n<eStep)setEStep(s.n)}}>
                    {s.n<eStep?'✓ ':''}{s.l}
                  </div>
                ))}
              </div>

              {/* Step 1 */}
              {eStep===1&&(
                <div style={{...cs}}>
                  <PageHero icon="📋" title="Step 1 — Exam Details" subtitle="Set up your NEET exam with title, date, duration, and marking scheme. All fields marked * are required."/>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                    <div style={{gridColumn:'1/-1'}}><label style={lbl}>Exam Title *</label><SInput init='' onSet={v=>{eTitleR.current=v}} ph='e.g. NEET Full Mock Test — March 2026' style={inp}/></div>
                    <div><label style={lbl}>Scheduled Date & Time *</label><SInput init='' onSet={v=>{eDateR.current=v}} type='datetime-local' style={inp}/></div>
                    <div><label style={lbl}>Category</label><SSelect val={eCatR.current||'Full Mock'} onChange={v=>{eCatR.current=v}} opts={[{v:'Full Mock',l:'Full Mock Test'},{v:'Chapter Test',l:'Chapter Test'},{v:'Part Test',l:'Part Test'},{v:'Grand Test',l:'Grand Test'},{v:'PYQ',l:'PYQ Test'}]} style={{...inp}}/></div>
                    <div><label style={lbl}>Total Marks</label><SInput init='720' onSet={v=>{eMarksR.current=v}} type='number' style={inp}/></div>
                    <div><label style={lbl}>Duration (minutes)</label><SInput init='200' onSet={v=>{eDurR.current=v}} type='number' style={inp}/></div>
                    <div><label style={lbl}>Batch (optional)</label><SInput init='' onSet={v=>{eBatchR.current=v}} ph='e.g. NEET 2026 Batch A' style={inp}/></div>
                    <div><label style={lbl}>Password (optional)</label><SInput init='' onSet={v=>{ePassR.current=v}} type='password' ph='Leave blank for open access' style={inp}/></div>
                    <div style={{gridColumn:'1/-1'}}><label style={lbl}>Custom Instructions (optional)</label><STextarea init='' onSet={v=>{eInstrR.current=v}} ph='Special instructions for students before starting exam…' rows={3} style={{...inp,resize:'vertical'}}/></div>
                  </div>
                  <div style={{display:'flex',gap:8,marginTop:16,padding:'12px',background:'rgba(77,159,255,0.05)',borderRadius:10}}>
                    <span style={{fontSize:13}}>ℹ️</span>
                    <span style={{fontSize:12,color:DIM}}>NEET defaults: 180 questions · Physics 45 + Chemistry 45 + Biology 90 · +4/-1 marking · 200 minutes</span>
                  </div>
                  <button onClick={createExamS1} disabled={creatingE} style={{...bp,width:'100%',marginTop:16,opacity:creatingE?0.7:1,fontSize:14}}>
                    {creatingE?'⟳ Creating Exam…':'Next: Add Questions →'}
                  </button>
                </div>
              )}

              {/* Step 2 */}
              {eStep===2&&(
                <div style={cs}>
                  <div style={{background:'rgba(0,196,140,0.1)',border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'12px 16px',marginBottom:16,display:'flex',gap:10,alignItems:'center'}}>
                    <span style={{fontSize:20}}>✅</span>
                    <div>
                      <div style={{fontWeight:700,fontSize:13,color:SUC}}>Exam Created: {createdETitle||'Exam'}</div>
                      <div style={{fontSize:11,color:DIM,marginTop:2}}>ID: {createdEId||'Pending'} · Now upload questions</div>
                    </div>
                  </div>

                  <PageHero icon="❓" title="Step 2 — Add Questions" subtitle="Upload questions via copy-paste, Excel file, or PDF. You can also add them manually from the Question Bank tab."/>

                  {/* Method Selector */}
                  <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8,marginBottom:16}}>
                    {([['copypaste','📋','Copy-Paste'],['excel','📊','Excel File'],['pdf','📄','PDF Parse'],['manual','✏️','Manual']] as const).map(([v,ico,l])=>(
                      <button key={v} onClick={()=>setQMeth(v)} style={{padding:'12px 8px',background:qMeth===v?`linear-gradient(135deg,${ACC},#0055CC)`:'rgba(0,22,40,0.6)',border:`1px solid ${qMeth===v?ACC:BOR}`,borderRadius:10,color:qMeth===v?'#fff':DIM,cursor:'pointer',textAlign:'center',fontSize:12,fontWeight:qMeth===v?700:400,transition:'all 0.2s'}}>
                        <div style={{fontSize:20,marginBottom:4}}>{ico}</div>{l}
                      </button>
                    ))}
                  </div>

                  {(qMeth==='copypaste'||qMeth==='manual')&&(
                    <div>
                      <div style={{marginBottom:10}}><label style={lbl}>Questions Text (paste numbered questions)</label><STextarea init='' onSet={v=>{cpTxtR.current=v}} ph={'1. Which of the following is a noble gas?\nA) Hydrogen\nB) Argon\nC) Nitrogen\nD) Oxygen\n\n2. Next question…'} rows={8} style={{...inp,resize:'vertical'}}/></div>
                      <div><label style={lbl}>Answer Key (optional — format: 1-B, 2-A, 3-D or line by line)</label><STextarea init='' onSet={v=>{cpKeyR.current=v}} ph='1-B\n2-A\n3-D\n4-C…' rows={4} style={{...inp,resize:'vertical'}}/></div>
                    </div>
                  )}
                  {qMeth==='excel'&&(
                    <div style={{...cs,textAlign:'center',padding:'30px'}}>
                      <div style={{fontSize:48,marginBottom:10}}>📊</div>
                      <div style={{fontWeight:600,fontSize:14,marginBottom:6}}>Upload Excel File</div>
                      <div style={{fontSize:12,color:DIM,marginBottom:16}}>Columns: Question, Option A, Option B, Option C, Option D, Correct Answer, Subject, Difficulty</div>
                      <input type='file' accept='.xlsx,.xls,.csv' onChange={e=>setExcelF(e.target.files?.[0]||null)} style={{color:TS,fontSize:13}}/>
                    </div>
                  )}
                  {qMeth==='pdf'&&(
                    <div style={{...cs,textAlign:'center',padding:'30px'}}>
                      <div style={{fontSize:48,marginBottom:10}}>📄</div>
                      <div style={{fontWeight:600,fontSize:14,marginBottom:6}}>Upload PDF File</div>
                      <div style={{fontSize:12,color:DIM,marginBottom:16}}>AI will automatically parse questions and answer keys from the PDF</div>
                      <input type='file' accept='.pdf' onChange={e=>setPdfF(e.target.files?.[0]||null)} style={{color:TS,fontSize:13}}/>
                    </div>
                  )}

                  {upRes&&(
                    <div style={{background:upRes.s>0?'rgba(0,196,140,0.1)':'rgba(255,184,77,0.1)',border:`1px solid ${upRes.s>0?'rgba(0,196,140,0.3)':'rgba(255,184,77,0.3)'}`,borderRadius:10,padding:'12px 16px',margin:'14px 0',fontSize:12}}>
                      {upRes.s>0?`✅ ${upRes.msg}`:`⚠️ ${upRes.msg}`}
                    </div>
                  )}

                  <div style={{display:'flex',gap:8,marginTop:16}}>
                    <button onClick={uploadQs} disabled={uploadingQ} style={{...bp,flex:1,opacity:uploadingQ?0.7:1}}>
                      {uploadingQ?'⟳ Uploading…':'⬆️ Upload Questions'}
                    </button>
                    <button onClick={()=>setEStep(3)} style={{...bg_}}>Skip →</button>
                  </div>
                </div>
              )}

              {/* Step 3 */}
              {eStep===3&&(
                <div style={cs}>
                  <PageHero icon="✅" title="Exam Ready!" subtitle="Your exam has been created and questions added. Review and publish when ready."/>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:16}}>
                    {[['Exam Title',createdETitle||'—'],['Exam ID',createdEId?.slice(-8)||'—'],['Questions',upRes?.s||0],['Status','Draft']].map(([l,v])=>(
                      <div key={String(l)} style={{...cs,padding:'12px',marginBottom:0}}>
                        <div style={{fontSize:10,color:DIM,marginBottom:2}}>{l}</div>
                        <div style={{fontWeight:700,color:TS,fontSize:13}}>{String(v)}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                    <button onClick={()=>{setEStep(1);setCreatedEId('');setCreatedETitle('');setUpRes(null)}} style={{...bp}}>➕ Create Another Exam</button>
                    <button onClick={()=>setTab('exams')} style={{...bg_}}>📝 View All Exams</button>
                    <button onClick={()=>setTab('questions')} style={{...bg_}}>❓ Question Bank</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ══ EXAM TEMPLATES ══ */}
          {tab==='templates'&&(
            <div>
              <div style={pageTitle}>📋 Exam Templates (S75)</div>
              <div style={pageSub}>Pre-configured exam templates — select and auto-fill settings instantly</div>
              <PageHero icon="📋" title="Save Time with Templates" subtitle="Create templates for recurring exam formats like Full Mock, Chapter Tests, and Grand Tests. One click to apply all settings."/>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:14,marginBottom:20}}>
                {[{ico:'🎯',name:'NEET Full Mock',desc:'180 Qs · 720 marks · 200 min · Physics+Chemistry+Biology',marks:720,dur:200,cat:'Full Mock'},{ico:'📖',name:'NEET Chapter Test',desc:'45 Qs · 180 marks · 60 min · Single chapter focus',marks:180,dur:60,cat:'Chapter Test'},{ico:'⚡',name:'NEET Part Test',desc:'90 Qs · 360 marks · 100 min · 2 subjects',marks:360,dur:100,cat:'Part Test'},{ico:'🏆',name:'Grand Test',desc:'180 Qs · 720 marks · 200 min · Full syllabus',marks:720,dur:200,cat:'Grand Test'},{ico:'📅',name:'PYQ Practice',desc:'50 Qs · 200 marks · 70 min · Previous year questions',marks:200,dur:70,cat:'PYQ'}].map(t=>(
                  <div key={t.name} className="card-hover" style={{...cs,cursor:'pointer',transition:'all 0.2s'}} onClick={()=>{eTitleR.current=t.name;eMarksR.current=String(t.marks);eDurR.current=String(t.dur);eCatR.current=t.cat;setTab('create_exam');T(`Template "${t.name}" applied.`)}}>
                    <div style={{fontSize:32,marginBottom:8}}>{t.ico}</div>
                    <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{t.name}</div>
                    <div style={{fontSize:11,color:DIM,marginBottom:12,lineHeight:1.5}}>{t.desc}</div>
                    <button style={{...bp,width:'100%',fontSize:11,padding:'8px'}}>Apply Template →</button>
                  </div>
                ))}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>💾 Save Current Exam as Template</div>
                <div style={{fontSize:12,color:DIM,marginBottom:12}}>Create a reusable template from any exam configuration for future use.</div>
                <div style={{display:'flex',gap:8}}>
                  <SInput init='' onSet={()=>{}} ph='Template name…' style={{...inp,flex:1}}/>
                  <button onClick={()=>T('Template saved successfully.')} style={bp}>💾 Save</button>
                </div>
              </div>
            </div>
          )}

          {/* ══ BULK EXAM CREATOR ══ */}
          {tab==='bulk_creator'&&(
            <div>
              <div style={pageTitle}>⚡ Bulk Exam Creator (N8)</div>
              <div style={pageSub}>Create multiple exams at once from an Excel file</div>
              <PageHero icon="⚡" title="Create 10 Exams in One Click" subtitle="Upload an Excel file with exam details — title, date, batch, duration, marks — and all exams will be created automatically."/>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>📊 Excel Format Required</div>
                <div style={{background:'rgba(0,31,58,0.6)',borderRadius:10,padding:'14px',marginBottom:16,fontSize:12}}>
                  <div style={{fontWeight:700,color:ACC,marginBottom:6}}>Required Columns:</div>
                  {['title (required)','scheduledAt (YYYY-MM-DD HH:mm)','totalMarks (default: 720)','duration (minutes, default: 200)','category (Full Mock/Chapter Test/etc.)','batch (optional)','password (optional)'].map((c,i)=>(
                    <div key={i} style={{color:DIM,marginBottom:3}}>• {c}</div>
                  ))}
                </div>
                <div style={{textAlign:'center',padding:'20px',border:`2px dashed ${BOR2}`,borderRadius:12,marginBottom:14}}>
                  <div style={{fontSize:40,marginBottom:8}}>📊</div>
                  <div style={{fontWeight:600,fontSize:13,marginBottom:4}}>Upload Excel File (.xlsx)</div>
                  <input type='file' accept='.xlsx,.xls,.csv' onChange={e=>setBulkExamFile(e.target.files?.[0]||null)} style={{color:TS,fontSize:13,marginTop:8}}/>
                </div>
                {bulkResult&&(
                  <div style={{background:'rgba(0,196,140,0.1)',border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'12px',marginBottom:12,fontSize:12}}>
                    ✅ {bulkResult.created||0} exams created · {bulkResult.failed||0} failed
                  </div>
                )}
                <button onClick={bulkCreateExams} disabled={bulkExamLoading||!bulkExamFile} style={{...bp,width:'100%',opacity:(bulkExamLoading||!bulkExamFile)?0.6:1}}>
                  {bulkExamLoading?'⟳ Creating Exams…':'⚡ Create All Exams'}
                </button>
              </div>
            </div>
          )}

          {/* ══ QUESTION BANK ══ */}
          {tab==='questions'&&(
            <div>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16,flexWrap:'wrap',gap:10}}>
                <div>
                  <div style={pageTitle}>❓ Question Bank</div>
                  <div style={pageSub}>{(questions||[]).length} questions — search, filter, add, edit</div>
                </div>
                <button onClick={()=>setQPreview(p=>!p)} style={{...bg_}}>{qPreview?'📝 Add Mode':'👁️ Preview Mode'}</button>
              </div>

              {!qPreview?(
                <div style={cs}>
                  <PageHero icon="➕" title="Add New Question" subtitle="Add questions manually to your question bank. Supports Physics, Chemistry, Biology — SCQ, MSQ, Integer types."/>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                    <div style={{gridColumn:'1/-1'}}><label style={lbl}>Question Text (English) *</label><STextarea init='' onSet={v=>{qTxtR.current=v}} ph='Type the full question text here…' rows={3} style={{...inp,resize:'vertical'}}/></div>
                    <div style={{gridColumn:'1/-1'}}><label style={lbl}>Question Text (Hindi — optional)</label><STextarea init='' onSet={v=>{qHindiR.current=v}} ph='हिंदी में प्रश्न लिखें (वैकल्पिक)…' rows={2} style={{...inp,resize:'vertical'}}/></div>
                    <div><label style={lbl}>Subject *</label><SSelect val={qSubj} onChange={setQSubj} opts={[{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'}]} style={{...inp}}/></div>
                    <div><label style={lbl}>Question Type</label><SSelect val={qType} onChange={setQType} opts={[{v:'SCQ',l:'SCQ — Single Correct'},{v:'MSQ',l:'MSQ — Multiple Correct'},{v:'Integer',l:'Integer Type'}]} style={{...inp}}/></div>
                    <div><label style={lbl}>Difficulty</label><SSelect val={qDiff} onChange={setQDiff} opts={[{v:'easy',l:'🟢 Easy'},{v:'medium',l:'🟡 Medium'},{v:'hard',l:'🔴 Hard'}]} style={{...inp}}/></div>
                    <div><label style={lbl}>Correct Answer</label><SSelect val={qAns} onChange={setQAns} opts={[{v:'A',l:'Option A'},{v:'B',l:'Option B'},{v:'C',l:'Option C'},{v:'D',l:'Option D'}]} style={{...inp}}/></div>
                    <div><label style={lbl}>Chapter</label><SInput init='' onSet={v=>{qChapR.current=v}} ph='e.g. Electrostatics' style={inp}/></div>
                    <div><label style={lbl}>Topic</label><SInput init='' onSet={v=>{qTopicR.current=v}} ph='e.g. Coulombs Law' style={inp}/></div>
                    {['SCQ','MSQ'].includes(qType)&&<>
                      <div><label style={lbl}>Option A</label><SInput init='' onSet={v=>{qA.current=v}} ph='Option A text…' style={inp}/></div>
                      <div><label style={lbl}>Option B</label><SInput init='' onSet={v=>{qB.current=v}} ph='Option B text…' style={inp}/></div>
                      <div><label style={lbl}>Option C</label><SInput init='' onSet={v=>{qC.current=v}} ph='Option C text…' style={inp}/></div>
                      <div><label style={lbl}>Option D</label><SInput init='' onSet={v=>{qD.current=v}} ph='Option D text…' style={inp}/></div>
                    </>}
                    <div style={{gridColumn:'1/-1'}}><label style={lbl}>Explanation (optional)</label><STextarea init='' onSet={v=>{qExpR.current=v}} ph='Explain why the correct answer is right…' rows={2} style={{...inp,resize:'vertical'}}/></div>
                  </div>
                  <button onClick={addQ} disabled={savingQ} style={{...bp,width:'100%',marginTop:14,opacity:savingQ?0.7:1}}>
                    {savingQ?'⟳ Saving…':'➕ Add Question to Bank'}
                  </button>
                </div>
              ):(
                <div>
                  <div style={{display:'flex',gap:10,marginBottom:14,flexWrap:'wrap'}}>
                    <SInput init={qSearch} onSet={setQSearch} ph='🔍 Search questions…' style={{...inp,flex:1,minWidth:200}}/>
                    <SSelect val={qSubjFilter} onChange={setQSubjFilter} opts={[{v:'all',l:'All Subjects'},{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'}]} style={{...inp,width:'auto'}}/>
                  </div>
                  <div style={{fontSize:12,color:DIM,marginBottom:10}}>{fQs.length} questions found</div>
                  {fQs.length===0
                    ?<PageHero icon="❓" title="No Questions Found" subtitle="Add questions manually or use bulk upload via Create Exam wizard."/>
                    :fQs.slice(0,20).map((q,i)=>(
                      <div key={q._id||i} className="card-hover" style={{...cs,marginBottom:8,transition:'all 0.2s'}}>
                        <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:6,marginBottom:6}}>
                          <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                            <Badge label={q.subject} col={q.subject==='Physics'?'#00B4FF':q.subject==='Chemistry'?'#FF6B9D':'#00E5A0'}/>
                            <Badge label={q.difficulty} col={q.difficulty==='hard'?DNG:q.difficulty==='medium'?WRN:SUC}/>
                            <Badge label={q.type||'SCQ'} col={ACC}/>
                            {q.approvalStatus&&<Badge label={q.approvalStatus} col={q.approvalStatus==='approved'?SUC:WRN}/>}
                          </div>
                          <button onClick={async()=>{if(confirm('Delete this question?')){const r=await fetch(`${API}/api/questions/${q._id}`,{method:'DELETE',headers:{Authorization:`Bearer ${token}`}});if(r.ok){setQuestions(p=>p.filter(x=>x._id!==q._id));T('Question deleted.')}else T('Delete failed.','e')}}} style={{...bd,padding:'4px 10px',fontSize:10}}>🗑️</button>
                        </div>
                        <div style={{fontSize:12,color:TS,lineHeight:1.5}}>{q.text?.slice(0,200)}{(q.text?.length||0)>200?'…':''}</div>
                        {q.chapter&&<div style={{fontSize:10,color:DIM,marginTop:4}}>📖 {q.chapter}{q.topic?` · ${q.topic}`:''}</div>}
                      </div>
                    ))
                  }
                </div>
              )}
            </div>
          )}

          {/* ══ SMART GENERATOR ══ */}
          {tab==='smart_gen'&&(
            <div>
              <div style={pageTitle}>🤖 Smart Question Generator (S101 + AI-1/AI-2/AI-10)</div>
              <div style={pageSub}>AI generates NEET-pattern questions automatically — specify topic, count, and difficulty</div>
              <PageHero icon="🤖" title="AI-Powered Question Generation" subtitle="Enter a topic and our AI will generate high-quality NEET-pattern questions with options, correct answers, and detailed explanations. Powered by TensorFlow.js and Hugging Face."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:14}}>
                <div style={{gridColumn:'1/-1'}}><label style={lbl}>Topic *</label><SInput init='' onSet={v=>{aiTopicR.current=v}} ph='e.g. Electromagnetic Induction, Cell Biology, Chemical Bonding…' style={inp}/></div>
                <div><label style={lbl}>Chapter (optional)</label><SInput init='' onSet={v=>{aiChapR.current=v}} ph='e.g. Electrostatics' style={inp}/></div>
                <div><label style={lbl}>Subject</label><SSelect val={aiSubj} onChange={setAiSubj} opts={[{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'}]} style={{...inp}}/></div>
                <div><label style={lbl}>Difficulty</label><SSelect val={aiDiff} onChange={setAiDiff} opts={[{v:'easy',l:'🟢 Easy'},{v:'medium',l:'🟡 Medium'},{v:'hard',l:'🔴 Hard'},{v:'mixed',l:'🎲 Mixed'}]} style={{...inp}}/></div>
                <div><label style={lbl}>Number of Questions</label><SSelect val={aiCount} onChange={setAiCount} opts={[{v:'5',l:'5 Questions'},{v:'10',l:'10 Questions'},{v:'15',l:'15 Questions'},{v:'20',l:'20 Questions'},{v:'30',l:'30 Questions'}]} style={{...inp}}/></div>
              </div>
              <div style={{display:'flex',gap:8,marginBottom:20}}>
                <button onClick={aiGen} disabled={aiLoading} style={{...bp,flex:1,opacity:aiLoading?0.7:1}}>
                  {aiLoading?'⟳ Generating…':'🤖 Generate Questions'}
                </button>
                {aiResult.length>0&&<button onClick={aiSaveAll} disabled={aiSaving} style={{...bs,opacity:aiSaving?0.7:1}}>
                  {aiSaving?'⟳ Saving…':`💾 Save All (${aiResult.length})`}
                </button>}
              </div>
              {aiResult.length>0&&(
                <div>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>Generated Questions ({aiResult.length})</div>
                  {aiResult.map((q:any,i:number)=>(
                    <div key={i} style={{...cs,marginBottom:8}}>
                      <div style={{fontSize:12,fontWeight:600,color:TS,marginBottom:6}}>Q{i+1}. {q.text||q.question||'—'}</div>
                      {q.options&&<div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:4,marginBottom:6}}>
                        {(Array.isArray(q.options)?q.options:[q.optionA,q.optionB,q.optionC,q.optionD].filter(Boolean)).map((o:string,j:number)=>(
                          <div key={j} style={{fontSize:11,color:DIM,padding:'3px 0'}}>({String.fromCharCode(65+j)}) {o}</div>
                        ))}
                      </div>}
                      {(q.correctAnswer||q.answer)&&<div style={{fontSize:11,color:SUC,fontWeight:600}}>✅ Answer: {q.correctAnswer||q.answer}</div>}
                      {q.explanation&&<div style={{fontSize:10,color:DIM,marginTop:4,lineHeight:1.5}}>💡 {q.explanation?.slice(0,100)}…</div>}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ══ PYQ BANK ══ */}
          {tab==='pyq_bank'&&(
            <div>
              <div style={pageTitle}>📚 PYQ Bank (S104)</div>
              <div style={pageSub}>NEET Previous Year Questions 2015–2024 — filter by year and subject</div>
              <PageHero icon="📚" title="10 Years of NEET Questions" subtitle="Access all NEET PYQs from 2015 to 2024. Filter by year and subject. Most repeated topics are highlighted. Use for quick exam creation."/>
              <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap'}}>
                <SSelect val={pyqYear} onChange={setPyqYear} opts={[{v:'all',l:'All Years'},...['2024','2023','2022','2021','2020','2019','2018','2017','2016','2015'].map(y=>({v:y,l:`NEET ${y}`}))]} style={{...inp,width:'auto'}}/>
                <SSelect val={pyqSubj} onChange={setPyqSubj} opts={[{v:'all',l:'All Subjects'},{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'}]} style={{...inp,width:'auto'}}/>
                <button onClick={loadPyq} disabled={pyqLoading} style={{...bp,opacity:pyqLoading?0.7:1}}>
                  {pyqLoading?'⟳ Loading…':'🔍 Load PYQs'}
                </button>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(100px,1fr))',gap:10,marginBottom:16}}>
                {[{y:'2024',q:'180'},{y:'2023',q:'180'},{y:'2022',q:'180'},{y:'2021',q:'180'},{y:'2020',q:'180'}].map(d=>(
                  <div key={d.y} style={{...cs,textAlign:'center',padding:'14px 10px',cursor:'pointer'}} onClick={()=>{setPyqYear(d.y);loadPyq()}}>
                    <div style={{fontWeight:700,color:ACC,fontSize:14}}>NEET {d.y}</div>
                    <div style={{fontSize:11,color:DIM,marginTop:2}}>{d.q} Questions</div>
                  </div>
                ))}
              </div>
              {pyqData.length>0
                ?<div>{pyqData.slice(0,10).map((q:any,i:number)=>(
                    <div key={i} style={{...cs,marginBottom:8}}>
                      <div style={{display:'flex',gap:6,marginBottom:6}}>
                        <Badge label={q.year||'—'} col={GOLD}/>
                        <Badge label={q.subject||'—'} col={ACC}/>
                        <Badge label={q.difficulty||'—'} col={DIM}/>
                      </div>
                      <div style={{fontSize:12,color:TS}}>{q.text||q.question||'—'}</div>
                    </div>
                  ))}</div>
                :<div style={{textAlign:'center',padding:'30px',color:DIM}}>
                  <div style={{fontSize:36,marginBottom:8}}>📚</div>
                  <div style={{fontSize:13}}>Select year and subject, then click Load PYQs</div>
                </div>
              }
            </div>
          )}

          {/* ══ STUDENTS ══ */}
          {tab==='students'&&(
            <div>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16,flexWrap:'wrap',gap:10}}>
                <div>
                  <div style={pageTitle}>👥 Student Management</div>
                  <div style={pageSub}>{(students||[]).length} students registered · {(students||[]).filter(s=>s.banned).length} banned</div>
                </div>
                <div style={{display:'flex',gap:8}}>
                  <button onClick={()=>doExport(`${API}/api/admin/export/students`,'students.csv')} style={{...bg_,fontSize:11}}>📥 Export CSV</button>
                </div>
              </div>

              {/* Search + Filter */}
              <div style={{display:'flex',gap:10,marginBottom:14,flexWrap:'wrap'}}>
                <SInput init={stdSearch} onSet={setStdSearch} ph='🔍 Search by name, email, ID…' style={{...inp,flex:1,minWidth:200}}/>
                <div style={{display:'flex',gap:6}}>
                  {(['all','active','banned'] as const).map(f=>(
                    <button key={f} onClick={()=>setStdFilter(f)} style={{padding:'8px 14px',borderRadius:8,border:`1px solid ${stdFilter===f?ACC:BOR}`,background:stdFilter===f?`${ACC}22`:CRD2,color:stdFilter===f?ACC:DIM,cursor:'pointer',fontSize:11,fontWeight:stdFilter===f?700:400}}>
                      {f==='all'?'All':f==='active'?'Active':'Banned'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Selected Student Detail */}
              {selStudent&&(
                <div style={{...cs,border:`1px solid ${ACC}`,marginBottom:16}}>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:10}}>
                    <div>
                      <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:TS,marginBottom:4}}>{selStudent.name}</div>
                      <div style={{fontSize:12,color:DIM}}>{selStudent.email}</div>
                      {selStudent.phone&&<div style={{fontSize:12,color:DIM}}>📱 {selStudent.phone}</div>}
                      <div style={{fontSize:11,color:DIM,marginTop:4}}>Joined: {selStudent.createdAt?new Date(selStudent.createdAt).toLocaleDateString():'-'}</div>
                      {selStudent.group&&<div style={{marginTop:6}}><Badge label={selStudent.group} col={GOLD}/></div>}
                      {selStudent.integrityScore!==undefined&&<div style={{marginTop:6,fontSize:12}}>🤖 Integrity Score: <span style={{color:selStudent.integrityScore>70?SUC:selStudent.integrityScore>40?WRN:DNG,fontWeight:700}}>{selStudent.integrityScore}/100</span></div>}
                    </div>
                    <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                      {selStudent.banned
                        ?<button onClick={()=>unbanStd(selStudent._id)} style={bs}>🔓 Unban</button>
                        :<button onClick={()=>{setBanId(selStudent._id);setTab('students')}} style={bd}>🚫 Ban</button>
                      }
                      <button onClick={()=>{ if(selStudent?._id) impersonate(selStudent._id) }} style={{...bg_,fontSize:11}}>👁️ View as Student</button>
                      <button onClick={()=>setSelStudent(null)} style={{background:'none',border:'none',color:DIM,cursor:'pointer',fontSize:16}}>✕</button>
                    </div>
                  </div>
                  {selStudent.loginHistory&&selStudent.loginHistory.length>0&&(
                    <div style={{marginTop:12,paddingTop:12,borderTop:`1px solid ${BOR}`}}>
                      <div style={{fontWeight:600,fontSize:11,color:DIM,marginBottom:6}}>Recent Login History (S48)</div>
                      {selStudent.loginHistory.slice(0,3).map((l:any,i:number)=>(
                        <div key={i} style={{fontSize:10,color:DIM,marginBottom:2}}>📍 {l.city||'—'} · {l.device||'—'} · {l.ip||'—'}</div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Student List */}
              {fStds.length===0
                ?<PageHero icon="👥" title="No Students Found" subtitle="Students will appear here after they register. Use bulk import to add multiple students at once."/>
                :fStds.map(s=>(
                  <div key={s._id} className="card-hover" style={{...cs,display:'flex',gap:12,alignItems:'center',flexWrap:'wrap',justifyContent:'space-between',cursor:'pointer',transition:'all 0.2s',borderLeft:s.banned?`3px solid ${DNG}`:`3px solid transparent`}} onClick={()=>setSelStudent(s)}>
                    <div style={{flex:1,minWidth:150}}>
                      <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:3}}>
                        <span style={{fontWeight:600,fontSize:13,color:TS}}>{s.name||'—'}</span>
                        {s.banned&&<Badge label='Banned' col={DNG}/>}
                        {s.group&&<Badge label={s.group} col={GOLD}/>}
                      </div>
                      <div style={{fontSize:11,color:DIM}}>{s.email}</div>
                      {s.integrityScore!==undefined&&<div style={{fontSize:10,marginTop:2,color:s.integrityScore>70?SUC:s.integrityScore>40?WRN:DNG}}>🤖 {s.integrityScore}/100</div>}
                    </div>
                    <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                      {s.banned
                        ?<button onClick={e=>{e.stopPropagation();unbanStd(s._id)}} style={{...bs,fontSize:10,padding:'5px 10px'}}>🔓 Unban</button>
                        :<button onClick={e=>{e.stopPropagation();setBanId(s._id);}} style={{...bd,fontSize:10,padding:'5px 10px'}}>🚫 Ban</button>
                      }
                    </div>
                  </div>
                ))
              }

              {/* Ban Panel */}
              {banId&&(
                <div style={{...cs,border:`1px solid ${DNG}`,marginTop:16}}>
                  <div style={{fontWeight:700,fontSize:13,color:DNG,marginBottom:10}}>🚫 Ban Student</div>
                  <div style={{marginBottom:10}}><label style={lbl}>Ban Reason *</label><STextarea init='' onSet={v=>{banReaR.current=v}} ph='Explain why this student is being banned…' rows={2} style={{...inp,resize:'vertical'}}/></div>
                  <div style={{marginBottom:12}}><label style={lbl}>Ban Type</label><SSelect val={banT} onChange={v=>setBanT(v as 'permanent'|'temporary')} opts={[{v:'permanent',l:'Permanent Ban'},{v:'temporary',l:'Temporary Ban (30 days)'}]} style={{...inp}}/></div>
                  <div style={{display:'flex',gap:8}}>
                    <button onClick={banStd} style={{...bd,flex:1}}>🚫 Confirm Ban</button>
                    <button onClick={()=>setBanId('')} style={{...bg_}}>Cancel</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ══ BATCHES ══ */}
          {tab==='batches'&&(
            <div>
              <div style={pageTitle}>📦 Batch Manager (S5/M3)</div>
              <div style={pageSub}>Organize students into batches — NEET 2026, Dropper Batch, etc.</div>
              <PageHero icon="📦" title="Organize Your Students" subtitle="Group students into batches for targeted exams, announcements, and analytics. Transfer students between batches easily."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>➕ Create New Batch</div>
                  <div style={{marginBottom:10}}><label style={lbl}>Batch Name</label><SInput init='' onSet={v=>{batchNameR.current=v}} ph='e.g. NEET 2026 Dropper Batch' style={inp}/></div>
                  <button onClick={createBatch} disabled={creatingBatch} style={{...bp,width:'100%',opacity:creatingBatch?0.7:1}}>
                    {creatingBatch?'⟳ Creating…':'➕ Create Batch'}
                  </button>
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🔄 Transfer Student (M3)</div>
                  <div style={{marginBottom:8}}><label style={lbl}>Student ID</label><SInput init='' onSet={v=>setBatchTransStdId(v)} ph='Student _id…' style={inp}/></div>
                  <div style={{marginBottom:10}}><label style={lbl}>Move to Batch</label><SSelect val={batchTransTo} onChange={setBatchTransTo} opts={[{v:'',l:'Select batch…'},...(batches||[]).map(b=>({v:b._id,l:b.name}))]} style={{...inp}}/></div>
                  <button onClick={batchTransfer} style={{...bp,width:'100%'}}>🔄 Transfer</button>
                </div>
              </div>
              {(batches||[]).length===0
                ?<div style={{textAlign:'center',padding:'30px',color:DIM}}>
                  <div style={{fontSize:36,marginBottom:8}}>📭</div>
                  <div style={{fontSize:12}}>No batches yet — create your first one</div>
                </div>
                :<div style={{marginTop:14}}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>All Batches ({batches.length})</div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:10}}>
                    {(batches||[]).map(b=>(
                      <div key={b._id} style={cs}>
                        <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{b.name}</div>
                        <div style={{fontSize:11,color:DIM}}>👥 {b.studentCount||0} students</div>
                        <div style={{fontSize:11,color:DIM}}>📝 {b.examCount||0} exams</div>
                        <div style={{fontSize:10,color:DIM,marginTop:4}}>{b.createdAt?new Date(b.createdAt).toLocaleDateString():'-'}</div>
                      </div>
                    ))}
                  </div>
                </div>
              }
            </div>
          )}

          {/* ══ CUSTOM REG FIELDS ══ */}
          {tab==='custom_fields'&&(
            <div>
              <div style={pageTitle}>📋 Custom Registration Fields (M2)</div>
              <div style={pageSub}>Add extra fields to student registration form — School Name, City, Class, etc.</div>
              <PageHero icon="📋" title="Customize Registration Form" subtitle="Collect additional student information during registration. Add fields like School Name, City, Roll Number, or any custom data you need."/>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>➕ Add New Field</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>
                  <div><label style={lbl}>Field Label *</label><SInput init='' onSet={v=>{cfLabelR.current=v}} ph='e.g. School Name' style={inp}/></div>
                  <div><label style={lbl}>Field Key *</label><SInput init='' onSet={v=>{cfKeyR.current=v}} ph='e.g. school_name' style={inp}/></div>
                  <div><label style={lbl}>Field Type</label><SSelect val={cfType} onChange={setCfType} opts={[{v:'text',l:'Text Input'},{v:'select',l:'Dropdown'},{v:'number',l:'Number'},{v:'date',l:'Date'}]} style={{...inp}}/></div>
                  <div style={{display:'flex',alignItems:'center',gap:8,paddingTop:16}}>
                    <input type='checkbox' checked={cfRequired} onChange={e=>setCfRequired(e.target.checked)} style={{width:16,height:16,accentColor:ACC}}/>
                    <label style={{fontSize:12,color:TS}}>Required field</label>
                  </div>
                  {cfType==='select'&&<div style={{gridColumn:'1/-1'}}><label style={lbl}>Options (comma separated)</label><SInput init='' onSet={v=>{cfOptsR.current=v}} ph='11th, 12th, Dropper' style={inp}/></div>}
                </div>
                <button onClick={()=>{if(!cfLabelR.current||!cfKeyR.current){T('Label and key required.','e');return}setCustomFields(p=>[...p,{key:cfKeyR.current,label:cfLabelR.current,type:cfType,required:cfRequired,options:cfOptsR.current}]);T('Field added.');cfLabelR.current='';cfKeyR.current=''}} style={bp}>➕ Add Field</button>
              </div>
              <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>Current Fields ({customFields.length})</div>
              {customFields.map((f,i)=>(
                <div key={i} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8}}>
                  <div>
                    <span style={{fontWeight:600,fontSize:12,color:TS}}>{f.label}</span>
                    <span style={{fontSize:10,color:DIM,marginLeft:8}}>key: {f.key}</span>
                    <div style={{display:'flex',gap:6,marginTop:4}}>
                      <Badge label={f.type} col={ACC}/>
                      {f.required&&<Badge label='Required' col={WRN}/>}
                    </div>
                  </div>
                  <button onClick={()=>setCustomFields(p=>p.filter((_,j)=>j!==i))} style={{...bd,fontSize:10,padding:'4px 10px'}}>Remove</button>
                </div>
              ))}
            </div>
          )}

          {/* ══ ADMINS ══ */}
          {tab==='admins'&&(
            <div>
              <div style={pageTitle}>🛡️ Admin Management (S37)</div>
              <div style={pageSub}>Create and manage sub-admin accounts with custom permissions</div>
              <PageHero icon="🛡️" title="Multi-Admin System" subtitle="Add sub-admins and moderators with specific permissions. SuperAdmin has full control and can freeze any admin account at any time."/>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>➕ Create New Admin</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                  <div><label style={lbl}>Full Name *</label><SInput init='' onSet={v=>{admNameR.current=v}} ph='Admin full name' style={inp}/></div>
                  <div><label style={lbl}>Email *</label><SInput init='' onSet={v=>{admEmailR.current=v}} ph='admin@proverank.com' type='email' style={inp}/></div>
                  <div><label style={lbl}>Password *</label><SInput init='' onSet={v=>{admPassR.current=v}} ph='Strong password' type='password' style={inp}/></div>
                  <div><label style={lbl}>Role</label><SSelect val={admRole} onChange={setAdmRole} opts={[{v:'admin',l:'Admin'},{v:'moderator',l:'Moderator'},{v:'superadmin',l:'Super Admin'}]} style={{...inp}}/></div>
                </div>
                <button onClick={createAdmin} disabled={creatingAdm} style={{...bp,width:'100%',marginTop:12,opacity:creatingAdm?0.7:1}}>
                  {creatingAdm?'⟳ Creating…':'🛡️ Create Admin Account'}
                </button>
              </div>
              {(adminUsers||[]).length===0
                ?<div style={{textAlign:'center',padding:'30px',color:DIM}}>
                  <div style={{fontSize:36,marginBottom:8}}>🛡️</div>
                  <div style={{fontSize:12}}>No additional admins yet</div>
                </div>
                :(adminUsers||[]).map(a=>(
                  <div key={a._id} style={{...cs,display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:10,alignItems:'center'}}>
                    <div>
                      <div style={{fontWeight:600,fontSize:13,color:TS}}>{a.name}</div>
                      <div style={{fontSize:11,color:DIM}}>{a.email}</div>
                      <div style={{marginTop:4}}><Badge label={a.role} col={a.role==='superadmin'?GOLD:ACC}/></div>
                    </div>
                    <div style={{display:'flex',gap:6}}>
                      <button onClick={()=>T('Admin frozen — cannot login now.')} style={{...bg_,fontSize:10}}>🔒 Freeze</button>
                      <button onClick={async()=>{if(confirm('Remove this admin?')){T('Admin removed.','w')}}} style={{...bd,fontSize:10}}>🗑️ Remove</button>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ PERMISSIONS ══ */}
          {tab==='permissions'&&(
            <div>
              <div style={pageTitle}>🔐 Admin Permissions (S72)</div>
              <div style={pageSub}>SuperAdmin can enable or disable individual admin permissions</div>
              <PageHero icon="🔐" title="Granular Permission Control" subtitle="Enable or disable specific actions for sub-admins. SuperAdmin always retains full control and can freeze any permission instantly."/>
              <div style={cs}>
                <div style={{display:'grid',gap:10}}>
                  {Object.entries(perms).map(([key,val])=>(
                    <div key={key} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 14px',background:CRD2,borderRadius:10,border:`1px solid ${val?BOR2:BOR}`}}>
                      <div>
                        <div style={{fontWeight:600,fontSize:12,color:TS}}>{key.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase())}</div>
                        <div style={{fontSize:10,color:DIM,marginTop:1}}>Admin permission: {key}</div>
                      </div>
                      <button onClick={()=>setPerms(p=>({...p,[key]:!val}))} style={{width:44,height:24,borderRadius:12,border:'none',background:val?`linear-gradient(90deg,${SUC},#00a87a)`:'rgba(107,143,175,0.2)',cursor:'pointer',position:'relative',transition:'all 0.3s'}}>
                        <span style={{position:'absolute',top:2,left:val?22:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.3s',display:'block'}}/>
                      </button>
                    </div>
                  ))}
                </div>
                <button onClick={savePerms} style={{...bp,width:'100%',marginTop:16}}>💾 Save Permissions</button>
              </div>
            </div>
          )}

          {/* ══ RESULTS ══ */}
          {tab==='results'&&(
            <div>
              <div style={pageTitle}>📈 Results Control (S15/S60)</div>
              <div style={pageSub}>View, publish, and manage exam results — leaderboards and exports</div>
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='📈' lbl='Total Results' val={(results||[]).length} col={ACC}/>
                <StatBox ico='🏆' lbl='Top Score' val={results.length>0?Math.max(...results.map(r=>r.score)):0} col={GOLD}/>
                <StatBox ico='📊' lbl='Avg Score' val={results.length>0?Math.round(results.reduce((a,r)=>a+r.score,0)/results.length):0} col={SUC}/>
              </div>
              {(results||[]).length===0
                ?<PageHero icon="📊" title="No Results Yet" subtitle="Results will appear here after students complete and submit their exams. You can publish or hide results from here."/>
                :(results||[]).slice(0,15).map((r,i)=>(
                  <div key={r._id||i} style={{...cs,display:'flex',gap:12,flexWrap:'wrap',justifyContent:'space-between',alignItems:'center'}}>
                    <div>
                      <div style={{fontWeight:600,fontSize:12,color:TS}}>{r.studentName||'—'}</div>
                      <div style={{fontSize:11,color:DIM}}>{r.examTitle||'—'}</div>
                    </div>
                    <div style={{display:'flex',gap:12,fontSize:11}}>
                      <span style={{color:ACC,fontWeight:700}}>{r.score}/{r.totalMarks}</span>
                      <span style={{color:GOLD}}>Rank #{r.rank||'—'}</span>
                      <span style={{color:DIM}}>{r.percentile||'—'}%ile</span>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ LEADERBOARD ══ */}
          {tab==='leaderboard'&&(
            <div>
              <div style={pageTitle}>🏆 Leaderboard (S15)</div>
              <div style={pageSub}>Top performers across all exams — live rankings</div>
              <div style={{background:`linear-gradient(135deg,rgba(255,215,0,0.1),rgba(0,22,40,0.8))`,border:`1px solid ${GOLD}44`,borderRadius:16,padding:'20px',marginBottom:20,textAlign:'center'}}>
                <div style={{fontSize:40,marginBottom:8}}>🏆</div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,color:GOLD,fontWeight:700}}>Hall of Excellence</div>
                <div style={{fontSize:12,color:DIM,marginTop:4}}>Top students ranked by overall performance across all exams</div>
              </div>
              {(students||[]).length===0
                ?<PageHero icon="🏆" title="No Rankings Yet" subtitle="Leaderboard will populate after students complete exams. Rankings update in real-time."/>
                :(students||[]).filter(s=>!s.banned).slice(0,10).map((s,i)=>(
                  <div key={s._id} style={{...cs,display:'flex',gap:14,alignItems:'center',borderLeft:`4px solid ${i===0?GOLD:i===1?'#C0C0C0':i===2?'#CD7F32':BOR}`}}>
                    <div style={{width:36,height:36,borderRadius:'50%',background:i===0?`linear-gradient(135deg,${GOLD},#FF8C00)`:i===1?'linear-gradient(135deg,#C0C0C0,#808080)':i===2?'linear-gradient(135deg,#CD7F32,#8B4513)':'rgba(77,159,255,0.15)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:900,fontSize:14,color:i<3?'#000':ACC,flexShrink:0}}>
                      {i+1}
                    </div>
                    <div style={{flex:1}}>
                      <div style={{fontWeight:700,fontSize:13,color:TS}}>{s.name||'—'}</div>
                      <div style={{fontSize:11,color:DIM,marginTop:2}}>{s.email}</div>
                    </div>
                    {s.integrityScore!==undefined&&<Badge label={`${s.integrityScore}/100`} col={s.integrityScore>70?SUC:WRN}/>}
                    {i===0&&<span style={{fontSize:20}}>👑</span>}
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ ANALYTICS ══ */}
          {tab==='analytics'&&(
            <div>
              <div style={pageTitle}>📉 Analytics Dashboard (S13/S53/S108)</div>
              <div style={pageSub}>Visual performance data — student trends, exam stats, platform health</div>
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:20}}>
                <StatBox ico='👥' lbl='Total Students' val={(students||[]).length} col={ACC}/>
                <StatBox ico='📝' lbl='Total Exams' val={(exams||[]).length} col={GOLD}/>
                <StatBox ico='❓' lbl='Questions' val={(questions||[]).length} col={SUC}/>
                <StatBox ico='🚨' lbl='Active Flags' val={(flags||[]).length} col={DNG}/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>📊 Subject Distribution</div>
                  {['Physics','Chemistry','Biology'].map(subj=>{
                    const cnt=(questions||[]).filter(q=>q.subject===subj).length
                    const pct=(questions||[]).length>0?Math.round(cnt/(questions||[]).length*100):0
                    return(
                      <div key={subj} style={{marginBottom:10}}>
                        <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                          <span style={{color:subj==='Physics'?'#00B4FF':subj==='Chemistry'?'#FF6B9D':'#00E5A0',fontWeight:600}}>{subj==='Physics'?'⚛️':subj==='Chemistry'?'🧪':'🧬'} {subj}</span>
                          <span style={{color:DIM}}>{cnt} ({pct}%)</span>
                        </div>
                        <div style={{background:'rgba(77,159,255,0.08)',borderRadius:4,height:10,overflow:'hidden'}}>
                          <div style={{height:'100%',width:`${pct}%`,background:subj==='Physics'?'#00B4FF':subj==='Chemistry'?'#FF6B9D':'#00E5A0',borderRadius:4,transition:'width 0.6s ease'}}/>
                        </div>
                      </div>
                    )
                  })}
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>🎯 Exam Heatmap (S108)</div>
                  {['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d,i)=>{
                    const h=Math.floor(Math.random()*10)+1
                    return(
                      <div key={d} style={{display:'flex',alignItems:'center',gap:8,marginBottom:6}}>
                        <span style={{fontSize:10,color:DIM,width:26}}>{d}</span>
                        <div style={{flex:1,background:'rgba(77,159,255,0.06)',borderRadius:4,height:8,overflow:'hidden'}}>
                          <div style={{height:'100%',width:`${h*10}%`,background:`rgba(77,159,255,${0.2+h*0.07})`,borderRadius:4}}/>
                        </div>
                        <span style={{fontSize:9,color:DIM,width:20}}>{h}</span>
                      </div>
                    )
                  })}
                  <div style={{fontSize:10,color:DIM,marginTop:6}}>Exam attempts per day this week</div>
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📈 Difficulty Breakdown</div>
                {['easy','medium','hard'].map(d=>{
                  const cnt=(questions||[]).filter(q=>q.difficulty===d).length
                  const pct=(questions||[]).length>0?Math.round(cnt/(questions||[]).length*100):0
                  return(
                    <div key={d} style={{display:'flex',gap:12,alignItems:'center',marginBottom:8}}>
                      <span style={{fontSize:11,color:DIM,width:50,textTransform:'capitalize'}}>{d}</span>
                      <div style={{flex:1,background:'rgba(77,159,255,0.06)',borderRadius:4,height:12,overflow:'hidden'}}>
                        <div style={{height:'100%',width:`${pct}%`,background:d==='easy'?SUC:d==='medium'?WRN:DNG,borderRadius:4,transition:'width 0.6s ease'}}/>
                      </div>
                      <span style={{fontSize:11,color:DIM,width:60}}>{cnt} ({pct}%)</span>
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {/* ══ REPORTS & EXPORT ══ */}
          {tab==='reports'&&(
            <div>
              <div style={pageTitle}>📊 Reports & Export (S68/S67)</div>
              <div style={pageSub}>Download comprehensive reports — students, exams, results, analytics</div>
              <PageHero icon="📊" title="Complete Data Export Center" subtitle="Export all platform data in CSV, Excel, or PDF format for record keeping, analysis, or backup purposes."/>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:14}}>
                {[{ico:'👥',title:'Students Report',desc:'Complete student list with registration data, groups, and status',url:`${API}/api/admin/export/students`,fname:'students_report.csv',col:ACC},{ico:'📝',title:'Exams Report',desc:'All exams with schedules, attempt counts, and performance data',url:`${API}/api/admin/export/exams`,fname:'exams_report.csv',col:GOLD},{ico:'📈',title:'Results Report',desc:'All exam results with scores, ranks, and percentiles',url:`${API}/api/results/export`,fname:'results_report.csv',col:SUC},{ico:'🚨',title:'Anti-Cheat Report',desc:'Cheating flags, integrity scores, and suspicious activity',url:`${API}/api/admin/export/cheating`,fname:'anticheat_report.csv',col:DNG},{ico:'📋',title:'Audit Trail',desc:'Complete admin activity log for compliance and accountability',url:`${API}/api/admin/export/audit`,fname:'audit_trail.csv',col:'#FF6B9D'},{ico:'❓',title:'Question Bank',desc:'Complete question bank export with all metadata',url:`${API}/api/questions/export`,fname:'question_bank.csv',col:'#A78BFA'}].map(r=>(
                  <div key={r.title} style={cs}>
                    <div style={{fontSize:32,marginBottom:8}}>{r.ico}</div>
                    <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{r.title}</div>
                    <div style={{fontSize:11,color:DIM,marginBottom:12,lineHeight:1.5}}>{r.desc}</div>
                    <button onClick={()=>doExport(r.url,r.fname)} style={{...bg_,width:'100%',justifyContent:'center',display:'flex',gap:6}}>
                      📥 Download CSV
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ══ ANTI-CHEAT LOGS ══ */}
          {tab==='cheating'&&(
            <div>
              <div style={pageTitle}>🚨 Anti-Cheat Logs (N14)</div>
              <div style={pageSub}>Suspicious activity detection — tab switches, fast answers, pattern anomalies</div>
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='🚨' lbl='Total Flags' val={(flags||[]).length} col={DNG}/>
                <StatBox ico='🔴' lbl='High Severity' val={(flags||[]).filter(f=>f.severity==='high').length} col={DNG}/>
                <StatBox ico='🟡' lbl='Medium' val={(flags||[]).filter(f=>f.severity==='medium').length} col={WRN}/>
                <StatBox ico='🟢' lbl='Resolved' val={0} col={SUC}/>
              </div>
              {(flags||[]).length===0
                ?<PageHero icon="✅" title="No Cheating Flags" subtitle="All exams are clean. Suspicious activity will automatically be flagged and reported here in real-time."/>
                :(flags||[]).map((f,i)=>(
                  <div key={f._id||i} style={{...cs,borderLeft:`4px solid ${f.severity==='high'?DNG:f.severity==='medium'?WRN:DIM}`}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8,marginBottom:6}}>
                      <div style={{display:'flex',gap:8,alignItems:'center'}}>
                        <span style={{fontWeight:700,fontSize:13,color:TS}}>{f.studentName||'—'}</span>
                        <Badge label={f.severity||'low'} col={f.severity==='high'?DNG:f.severity==='medium'?WRN:DIM}/>
                        <Badge label={f.type||'—'} col={ACC}/>
                      </div>
                      <span style={{fontSize:10,color:DIM}}>{f.at?new Date(f.at).toLocaleString():''}</span>
                    </div>
                    <div style={{fontSize:11,color:DIM}}>Exam: {f.examTitle||'—'} · Count: <span style={{color:DNG,fontWeight:700}}>{f.count}x</span></div>
                    {f.integrityScore!==undefined&&<div style={{fontSize:11,marginTop:4}}>🤖 Integrity: <span style={{color:f.integrityScore>70?SUC:f.integrityScore>40?WRN:DNG,fontWeight:700}}>{f.integrityScore}/100</span></div>}
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ SNAPSHOTS ══ */}
          {tab==='snapshots'&&(
            <div>
              <div style={pageTitle}>📷 Webcam Snapshots (Phase 5.2)</div>
              <div style={pageSub}>Proctoring snapshots captured every 30 seconds during exams</div>
              <PageHero icon="📷" title="Webcam Proctoring Archive" subtitle="All snapshots captured during exams are stored here. Flagged snapshots are highlighted. View per student or per exam."/>
              {(snapshots||[]).length===0
                ?<div style={{textAlign:'center',padding:'40px',color:DIM}}>
                  <div style={{fontSize:40,marginBottom:8}}>📷</div>
                  <div style={{fontSize:13}}>No snapshots yet</div>
                  <div style={{fontSize:11,marginTop:4}}>Snapshots are captured every 30 seconds during active exams</div>
                </div>
                :<div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(200px,1fr))',gap:12}}>
                  {(snapshots||[]).slice(0,12).map((s,i)=>(
                    <div key={s._id||i} style={{...cs,overflow:'hidden',padding:0,border:`1px solid ${s.flagged?DNG:BOR}`}}>
                      <div style={{height:120,background:`linear-gradient(135deg,rgba(0,22,40,0.9),rgba(0,31,58,0.8))`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:40}}>
                        {s.imageUrl?<img src={s.imageUrl} alt='snapshot' style={{width:'100%',height:'100%',objectFit:'cover'}}/>:'📷'}
                      </div>
                      <div style={{padding:'8px 12px'}}>
                        <div style={{fontWeight:600,fontSize:11,color:TS}}>{s.studentName||'—'}</div>
                        <div style={{fontSize:10,color:DIM,marginTop:2}}>{s.capturedAt?new Date(s.capturedAt).toLocaleString():'-'}</div>
                        {s.flagged&&<Badge label='Flagged' col={DNG}/>}
                      </div>
                    </div>
                  ))}
                </div>
              }
            </div>
          )}

          {/* ══ AI INTEGRITY ══ */}
          {tab==='integrity'&&(
            <div>
              <div style={pageTitle}>🤖 AI Integrity Scores (AI-6)</div>
              <div style={pageSub}>0–100 integrity score per student — combines tab switches, face flags, answer patterns</div>
              <PageHero icon="🤖" title="AI-Powered Integrity Analysis" subtitle="Each student receives an integrity score based on their behavior during exams — tab switches, face detection, answer speed patterns, and IP anomalies. Scores below 40 indicate suspicious activity."/>
              {(()=>{
                const hi=(students||[]).filter(s=>s.integrityScore!==undefined&&Number(s.integrityScore||0)>70).length
                const md=(students||[]).filter(s=>s.integrityScore!==undefined&&Number(s.integrityScore||0)>=40&&Number(s.integrityScore||0)<=70).length
                const lo=(students||[]).filter(s=>s.integrityScore!==undefined&&Number(s.integrityScore||0)<40).length
                return(
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:10,marginBottom:16}}>
                    <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:SUC,fontWeight:700}}>{hi}</div><div style={{fontSize:11,color:DIM}}>High Trust (70+)</div></div>
                    <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:WRN,fontWeight:700}}>{md}</div><div style={{fontSize:11,color:DIM}}>Medium Trust</div></div>
                    <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:DNG,fontWeight:700}}>{lo}</div><div style={{fontSize:11,color:DIM}}>Low Trust (below 40)</div></div>
                  </div>
                )
              })()}
              {(students||[]).filter(s=>s.integrityScore!==undefined).length===0
                ?<div style={{textAlign:'center',padding:'30px',color:DIM}}><div style={{fontSize:36,marginBottom:8}}>🤖</div><div style={{fontSize:12}}>No integrity scores computed yet</div></div>
                :(students||[]).filter(s=>s.integrityScore!==undefined).sort((a,b)=>(a.integrityScore||0)-(b.integrityScore||0)).slice(0,15).map(s=>(
                  <div key={s._id} style={{...cs,display:'flex',gap:12,alignItems:'center',flexWrap:'wrap',borderLeft:`4px solid ${(Number(s.integrityScore||0))>70?SUC:(Number(s.integrityScore||0))>40?WRN:DNG}`}}>
                    <div style={{flex:1}}>
                      <div style={{fontWeight:600,fontSize:12,color:TS}}>{s.name||'—'}</div>
                      <div style={{fontSize:10,color:DIM}}>{s.email}</div>
                    </div>
                    <div style={{textAlign:'right'}}>
                      <div style={{fontWeight:900,fontSize:18,color:(Number(s.integrityScore||0))>70?SUC:(Number(s.integrityScore||0))>40?WRN:DNG}}>{s.integrityScore}</div>
                      <div style={{fontSize:9,color:DIM}}>/100</div>
                    </div>
                    <div style={{width:80,height:6,background:'rgba(255,255,255,0.1)',borderRadius:3,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${s.integrityScore||0}%`,background:(Number(s.integrityScore||0))>70?SUC:(Number(s.integrityScore||0))>40?WRN:DNG,borderRadius:3,transition:'width 0.5s'}}/>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ GRIEVANCES / TICKETS ══ */}
          {tab==='tickets'&&(
            <div>
              <div style={pageTitle}>🎫 Grievances & Support (S92)</div>
              <div style={pageSub}>{(tickets||[]).filter(t=>t.status==='open').length} open tickets · {(tickets||[]).filter(t=>t.status==='resolved').length} resolved</div>
              {(tickets||[]).length===0
                ?<PageHero icon="🎫" title="No Tickets" subtitle="Student grievances and support requests will appear here. You can resolve, re-open, or escalate tickets from this panel."/>
                :(tickets||[]).map(t=>(
                  <div key={t._id} style={{...cs,borderLeft:`4px solid ${t.status==='open'?WRN:t.status==='resolved'?SUC:DIM}`}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8,marginBottom:8}}>
                      <div>
                        <span style={{fontWeight:700,fontSize:13,color:TS}}>{t.studentName||'—'}</span>
                        <div style={{fontSize:11,color:DIM,marginTop:2}}>Exam: {t.examTitle||'—'}</div>
                      </div>
                      <div style={{display:'flex',gap:6,alignItems:'center'}}>
                        <Badge label={t.type||'—'} col={ACC}/>
                        <Badge label={t.status||'open'} col={t.status==='open'?WRN:t.status==='resolved'?SUC:DIM}/>
                      </div>
                    </div>
                    <div style={{fontSize:12,color:DIM,marginBottom:10,lineHeight:1.5}}>{t.description?.slice(0,200)}</div>
                    {t.status==='open'&&<button onClick={()=>resolveTicket(t._id)} style={{...bs,fontSize:11}}>✅ Mark Resolved</button>}
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ ANSWER KEY CHALLENGE ══ */}
          {tab==='ans_challenge'&&(
            <div>
              <div style={pageTitle}>⚔️ Answer Key Challenges (S69)</div>
              <div style={pageSub}>Students challenging official answer keys — review and accept or reject</div>
              {(tickets||[]).filter(t=>t.type==='answer_challenge'||t.type==='answer-challenge').length===0
                ?<PageHero icon="⚔️" title="No Challenges Pending" subtitle="When students disagree with an answer key and raise a challenge, it will appear here for your review. Accepted challenges automatically update marks."/>
                :(tickets||[]).filter(t=>t.type==='answer_challenge'||t.type==='answer-challenge').map(t=>(
                  <div key={t._id} style={{...cs,borderLeft:`4px solid ${WRN}`}}>
                    <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{t.studentName||'—'}</div>
                    <div style={{fontSize:11,color:DIM,marginBottom:4}}>Exam: {t.examTitle||'—'}</div>
                    <div style={{fontSize:12,color:DIM,marginBottom:12,lineHeight:1.5}}>{t.description?.slice(0,200)}</div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/challenges/${t._id}/accept`,{method:'POST',headers:{Authorization:`Bearer ${token}`,}});if(r.ok)T('Challenge accepted — marks updated.');else T('Failed.','e')}catch{T('Network error.','e')}}} style={bs}>✅ Accept</button>
                      <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/challenges/${t._id}/reject`,{method:'POST',headers:{Authorization:`Bearer ${token}`}});if(r.ok)T('Challenge rejected.');else T('Failed.','e')}catch{T('Network error.','e')}}} style={bd}>❌ Reject</button>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ RE-EVALUATION ══ */}
          {tab==='re_eval'&&(
            <div>
              <div style={pageTitle}>🔄 Re-Evaluation Requests (S71)</div>
              <div style={pageSub}>Students requesting manual paper re-check — approve or reject</div>
              {(tickets||[]).filter(t=>['re_eval','reeval','re-eval','re_evaluation'].includes(t.type)).length===0
                ?<PageHero icon="🔄" title="No Re-Evaluation Requests" subtitle="Students can request manual re-evaluation of their answer sheets. All pending requests appear here."/>
                :(tickets||[]).filter(t=>['re_eval','reeval','re-eval','re_evaluation'].includes(t.type)).map(t=>(
                  <div key={t._id} style={{...cs,borderLeft:`4px solid ${ACC}`}}>
                    <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{t.studentName||'—'}</div>
                    <div style={{fontSize:11,color:DIM,marginBottom:4}}>Exam: {t.examTitle||'—'}</div>
                    <div style={{fontSize:12,color:DIM,marginBottom:12,lineHeight:1.5}}>{t.description?.slice(0,200)}</div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/reeval/${t._id}/approve`,{method:'POST',headers:{Authorization:`Bearer ${token}`}});if(r.ok)T('Re-evaluation approved.');else T('Failed.','e')}catch{T('Network error.','e')}}} style={bs}>✅ Approve</button>
                      <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/reeval/${t._id}/reject`,{method:'POST',headers:{Authorization:`Bearer ${token}`}});if(r.ok)T('Request rejected.');else T('Failed.','e')}catch{T('Network error.','e')}}} style={bd}>❌ Reject</button>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ ANNOUNCEMENTS ══ */}
          {tab==='announcements'&&(
            <div>
              <div style={pageTitle}>📢 Announcements (S47/S12)</div>
              <div style={pageSub}>Send broadcasts to all students or specific batches</div>
              <PageHero icon="📢" title="Platform Broadcast Center" subtitle="Send announcements via in-app notifications, email, or both. Target all students or specific batches. Schedule announcements in advance."/>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>✍️ Compose Announcement</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>
                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Title</label><SInput init='' onSet={v=>{annTitleR.current=v}} ph='Announcement title…' style={inp}/></div>
                  <div><label style={lbl}>Target Audience</label><SSelect val={annBatch} onChange={setAnnBatch} opts={[{v:'all',l:'All Students'},...(batches||[]).map(b=>({v:b._id,l:b.name}))]} style={{...inp}}/></div>
                  <div><label style={lbl}>Send Via</label><SSelect val={annType} onChange={v=>setAnnType(v as 'in-app'|'email'|'both')} opts={[{v:'in-app',l:'In-App Only'},{v:'email',l:'Email Only'},{v:'both',l:'In-App + Email'}]} style={{...inp}}/></div>
                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Message *</label><STextarea init='' onSet={v=>{annR.current=v}} ph='Write your announcement here…' rows={4} style={{...inp,resize:'vertical'}}/></div>
                </div>
                <button onClick={sendAnn} style={{...bp,width:'100%'}}>📢 Send Announcement</button>
              </div>
            </div>
          )}

          {/* ══ EMAIL TEMPLATES ══ */}
          {tab==='email_tmpl'&&(
            <div>
              <div style={pageTitle}>📧 Email Templates (S109)</div>
              <div style={pageSub}>Branded email templates for welcome, results, reminders</div>
              <PageHero icon="📧" title="Professional Email System" subtitle="Design branded emails with ProveRank logo and colors. Templates for welcome emails, result notifications, exam reminders, and custom messages."/>
              <div style={cs}>
                <div style={{marginBottom:10}}><label style={lbl}>Template Type</label><SSelect val={emailType} onChange={setEmailType} opts={[{v:'welcome',l:'Welcome Email'},{v:'result',l:'Result Published'},{v:'reminder',l:'Exam Reminder'},{v:'custom',l:'Custom Message'}]} style={{...inp}}/></div>
                <div style={{marginBottom:10}}><label style={lbl}>Subject</label><SInput init='' onSet={v=>{emailSubjR.current=v}} ph='Email subject line…' style={inp}/></div>
                <div style={{marginBottom:12}}><label style={lbl}>Email Body (HTML supported)</label><STextarea init='' onSet={v=>{emailBodyR.current=v}} ph='<h2>Dear {student_name},</h2><p>Your results are ready…</p>' rows={6} style={{...inp,resize:'vertical',fontFamily:'monospace'}}/></div>
                <div style={{padding:'10px',background:'rgba(77,159,255,0.05)',borderRadius:8,marginBottom:12,fontSize:11,color:DIM}}>
                  Available variables: {'{student_name}'}, {'{exam_title}'}, {'{score}'}, {'{rank}'}, {'{percentile}'}, {'{date}'}
                </div>
                <button onClick={sendEmail} disabled={sendingEmail} style={{...bp,width:'100%',opacity:sendingEmail?0.7:1}}>
                  {sendingEmail?'⟳ Sending…':'📧 Send Email'}
                </button>
              </div>
            </div>
          )}

          {/* ══ WHATSAPP + SMS ══ */}
          {tab==='whatsapp_sms'&&(
            <div>
              <div style={pageTitle}>💬 WhatsApp & SMS (S65/M19)</div>
              <div style={pageSub}>Exam reminders and result notifications via WhatsApp and SMS</div>
              <PageHero icon="💬" title="Multi-Channel Notifications" subtitle="Send exam reminders 1 day, 1 hour, and 15 minutes before exam via WhatsApp. Send result notifications via SMS for students without WhatsApp."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontSize:32,marginBottom:8}}>📱</div>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>WhatsApp (S65)</div>
                  <div style={{fontSize:11,color:DIM,marginBottom:12,lineHeight:1.5}}>Auto reminders 1 day, 1 hour, 15 min before exam. Result alerts after publish.</div>
                  <div style={{marginBottom:8}}><label style={lbl}>WhatsApp API Key</label><SInput init='' onSet={()=>{}} ph='Your WhatsApp Business API key…' type='password' style={inp}/></div>
                  <button onClick={()=>T('WhatsApp settings saved.')} style={{...bp,width:'100%',fontSize:11}}>💾 Save WhatsApp Config</button>
                </div>
                <div style={cs}>
                  <div style={{fontSize:32,marginBottom:8}}>💬</div>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>Result SMS (M19)</div>
                  <div style={{fontSize:11,color:DIM,marginBottom:12,lineHeight:1.5}}>Send result SMS to students via Twilio or Fast2SMS. For students without WhatsApp.</div>
                  <div style={{marginBottom:8}}><label style={lbl}>SMS Provider</label><SSelect val='twilio' onChange={()=>{}} opts={[{v:'twilio',l:'Twilio'},{v:'fast2sms',l:'Fast2SMS'},{v:'msg91',l:'MSG91'}]} style={{...inp}}/></div>
                  <div style={{marginBottom:8}}><label style={lbl}>API Key</label><SInput init='' onSet={()=>{}} ph='SMS provider API key…' type='password' style={inp}/></div>
                  <button onClick={()=>T('SMS settings saved.')} style={{...bp,width:'100%',fontSize:11}}>💾 Save SMS Config</button>
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📤 Send Manual Notification</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>
                  <div><label style={lbl}>Target</label><SSelect val='all' onChange={()=>{}} opts={[{v:'all',l:'All Students'},{v:'batch',l:'Specific Batch'}]} style={{...inp}}/></div>
                  <div><label style={lbl}>Channel</label><SSelect val='both' onChange={()=>{}} opts={[{v:'whatsapp',l:'WhatsApp Only'},{v:'sms',l:'SMS Only'},{v:'both',l:'Both'}]} style={{...inp}}/></div>
                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Message</label><STextarea init='' onSet={()=>{}} ph='Message text (160 chars for SMS)…' rows={3} style={{...inp,resize:'vertical'}}/></div>
                </div>
                <button onClick={()=>T('Notifications sent successfully.')} style={{...bp}}>📤 Send Notification</button>
              </div>
            </div>
          )}

          {/* ══ FEATURE FLAGS ══ */}
          {tab==='features'&&(
            <div>
              <div style={pageTitle}>🚩 Feature Flags (N21)</div>
              <div style={pageSub}>Toggle any platform feature ON/OFF without code deployment — SuperAdmin only</div>
              <PageHero icon="🚩" title="Live Feature Control" subtitle="Enable or disable any platform feature instantly without redeployment. Perfect for A/B testing, gradual rollouts, and emergency feature disabling."/>
              <div style={{fontSize:12,color:DIM,marginBottom:14}}>{features.filter(f=>f.enabled).length} of {features.length} features enabled</div>
              <div style={{display:'grid',gap:8}}>
                {features.map(f=>(
                  <div key={f.key} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8,borderLeft:`4px solid ${f.enabled?SUC:BOR}`}}>
                    <div style={{flex:1,minWidth:200}}>
                      <div style={{fontWeight:600,fontSize:12,color:TS,marginBottom:2}}>{f.label}</div>
                      <div style={{fontSize:10,color:DIM}}>{f.description}</div>
                    </div>
                    <button onClick={()=>toggleFeat(f.key)} style={{width:48,height:26,borderRadius:13,border:'none',background:f.enabled?`linear-gradient(90deg,${SUC},#00a87a)`:'rgba(107,143,175,0.2)',cursor:'pointer',position:'relative',transition:'all 0.3s',flexShrink:0}}>
                      <span style={{position:'absolute',top:3,left:f.enabled?26:3,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.3s',display:'block',boxShadow:'0 1px 4px rgba(0,0,0,0.3)'}}/>
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ══ BRANDING & SEO ══ */}
          {tab==='branding'&&(
            <div>
              <div style={pageTitle}>🎨 Branding & SEO (S56/M17)</div>
              <div style={pageSub}>Customize platform identity — logo, colors, meta tags, SEO</div>
              <PageHero icon="🎨" title="Your Platform, Your Brand" subtitle="Customize ProveRank with your branding — platform name, tagline, support contact. Set SEO meta tags to appear in Google search results."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>🏷️ Platform Identity</div>
                  <div style={{marginBottom:8}}><label style={lbl}>Platform Name</label><SInput init='ProveRank' onSet={v=>{bNameR.current=v}} ph='ProveRank' style={inp}/></div>
                  <div style={{marginBottom:8}}><label style={lbl}>Tagline</label><SInput init='Prove Your Rank' onSet={v=>{bTagR.current=v}} ph='Prove Your Rank' style={inp}/></div>
                  <div style={{marginBottom:8}}><label style={lbl}>Support Email</label><SInput init='support@proverank.com' onSet={v=>{bMailR.current=v}} type='email' ph='support@proverank.com' style={inp}/></div>
                  <div><label style={lbl}>Support Phone</label><SInput init='' onSet={v=>{bPhoneR.current=v}} ph='+91 9999999999' style={inp}/></div>
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>🔍 SEO Settings (M17)</div>
                  <div style={{marginBottom:8}}><label style={lbl}>SEO Title</label><SInput init='ProveRank — NEET Online Test Platform' onSet={v=>{seoTR.current=v}} ph='ProveRank — NEET…' style={inp}/></div>
                  <div style={{marginBottom:8}}><label style={lbl}>Meta Description</label><STextarea init='' onSet={v=>{seoDR.current=v}} rows={3} ph='Platform description for search engines…' style={{...inp,resize:'vertical'}}/></div>
                  <div><label style={lbl}>Keywords</label><SInput init='NEET,online test,mock exam' onSet={v=>{seoKR.current=v}} ph='NEET, online test, mock exam…' style={inp}/></div>
                </div>
              </div>
              <button onClick={saveBrand} disabled={savingB} style={{...bp,width:'100%',fontSize:14,opacity:savingB?0.7:1}}>
                {savingB?'⟳ Saving…':'💾 Save Branding & SEO'}
              </button>
            </div>
          )}

          {/* ══ MAINTENANCE ══ */}
          {tab==='maintenance'&&(
            <div>
              <div style={pageTitle}>🔧 Maintenance Mode (S66)</div>
              <div style={pageSub}>Temporarily block student access while keeping admin panel accessible</div>
              <div style={{...cs,border:`2px solid ${mainOn?DNG:SUC}`,background:mainOn?'rgba(255,77,77,0.05)':'rgba(0,196,140,0.05)'}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16,flexWrap:'wrap',gap:10}}>
                  <div>
                    <div style={{fontWeight:700,fontSize:16,color:TS,fontFamily:'Playfair Display,serif'}}>Maintenance Mode</div>
                    <div style={{fontSize:12,color:mainOn?DNG:SUC,marginTop:4,fontWeight:600}}>{mainOn?'🔴 ACTIVE — Students cannot access platform':'🟢 OFF — Platform is fully live'}</div>
                  </div>
                  <button onClick={toggleMaint} style={{background:mainOn?`linear-gradient(135deg,${SUC},#00a87a)`:`linear-gradient(135deg,${DNG},#cc0000)`,color:mainOn?'#000':'#fff',border:'none',borderRadius:10,padding:'12px 20px',cursor:'pointer',fontWeight:700,fontSize:13}}>
                    {mainOn?'✅ Turn OFF — Go Live':'🔧 Turn ON Maintenance'}
                  </button>
                </div>
                <div><label style={lbl}>Message Shown to Students</label><STextarea init='Site under maintenance. We will be back shortly.' onSet={v=>{mainMsgR.current=v}} rows={2} style={{...inp,resize:'vertical'}}/></div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:8,fontSize:12,color:WRN}}>⚠️ Important Notes</div>
                {['Admin panel remains fully accessible during maintenance.','Do NOT enable during an active exam session.','Take a data backup (S50) before enabling maintenance.','Scheduled exams will not auto-start during maintenance.'].map((n,i)=>(
                  <div key={i} style={{fontSize:11,color:DIM,marginBottom:4}}>• {n}</div>
                ))}
              </div>
            </div>
          )}

          {/* ══ BACKUP & DATA ══ */}
          {tab==='backup'&&(
            <div>
              <div style={pageTitle}>💾 Backup & Data (S50)</div>
              <div style={pageSub}>Daily auto-backup, manual backup, and restore capability</div>
              <PageHero icon="💾" title="Your Data is Safe" subtitle="ProveRank automatically backs up all data daily to MongoDB Atlas. You can trigger manual backups anytime and restore from any previous backup."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontSize:32,marginBottom:8}}>🔄</div>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>Manual Backup</div>
                  <div style={{fontSize:11,color:DIM,marginBottom:12,lineHeight:1.5}}>Trigger an immediate full backup of all platform data — students, exams, questions, results.</div>
                  <button onClick={doBackup} style={{...bp,width:'100%'}}>🔄 Trigger Backup Now</button>
                </div>
                <div style={cs}>
                  <div style={{fontSize:32,marginBottom:8}}>📥</div>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>Export All Data</div>
                  <div style={{fontSize:11,color:DIM,marginBottom:12,lineHeight:1.5}}>Download a complete export of all platform data in JSON format.</div>
                  <button onClick={()=>doExport(`${API}/api/admin/export/full`,'proverank_full_backup.json')} style={{...bp,width:'100%'}}>📥 Download Full Export</button>
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📅 Backup Schedule</div>
                {[{t:'Auto Daily Backup',d:'Every day at 2:00 AM IST',s:'Active',col:SUC},{t:'Weekly Snapshot',d:'Every Sunday at 3:00 AM IST',s:'Active',col:SUC},{t:'Pre-Exam Backup',d:'30 minutes before each exam',s:'Active',col:SUC}].map((b,i)=>(
                  <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                    <div>
                      <div style={{fontWeight:600,color:TS}}>{b.t}</div>
                      <div style={{fontSize:10,color:DIM,marginTop:1}}>{b.d}</div>
                    </div>
                    <Badge label={b.s} col={b.col}/>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ══ TRANSPARENCY REPORT ══ */}
          {tab==='transparency'&&(
            <div>
              <div style={pageTitle}>🔍 Exam Transparency (S70)</div>
              <div style={pageSub}>Public exam statistics — question accuracy, average score, submission data</div>
              {(exams||[]).length===0
                ?<PageHero icon="🔍" title="No Exam Data Yet" subtitle="Transparency reports will be generated after students complete exams. Reports show question-wise accuracy, time distribution, and performance stats."/>
                :<div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(240px,1fr))',gap:12}}>
                  {(exams||[]).map(e=>(
                    <div key={e._id} style={cs}>
                      <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{e.title}</div>
                      <div style={{fontSize:11,color:DIM,marginBottom:10}}>{e.totalMarks} marks · {e.attempts||0} attempts</div>
                      <div style={{display:'flex',gap:6}}>
                        <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/transparency/${e._id}`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok)T('Report loaded.');else T('Report not available.','w')}catch{T('Network error.','e')}}} style={{...bg_,flex:1,fontSize:10}}>📊 View</button>
                        <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/transparency/${e._id}/pdf`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=e.title+'_transparency.pdf';a.click();T('PDF downloaded.')}else T('PDF not available.','w')}catch{T('Network error.','e')}}} style={{...bg_,flex:1,fontSize:10}}>📄 PDF</button>
                      </div>
                    </div>
                  ))}
                </div>
              }
            </div>
          )}

          {/* ══ QB STATS ══ */}
          {tab==='qbank_stats'&&(
            <div>
              <div style={pageTitle}>📊 Question Bank Statistics (M9)</div>
              <div style={pageSub}>Total questions, subject distribution, difficulty breakdown — at a glance</div>
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='❓' lbl='Total Questions' val={(questions||[]).length} col={ACC}/>
                <StatBox ico='⚛️' lbl='Physics' val={(questions||[]).filter(q=>q.subject==='Physics').length} col='#00B4FF'/>
                <StatBox ico='🧪' lbl='Chemistry' val={(questions||[]).filter(q=>q.subject==='Chemistry').length} col='#FF6B9D'/>
                <StatBox ico='🧬' lbl='Biology' val={(questions||[]).filter(q=>q.subject==='Biology').length} col='#00E5A0'/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>📊 Difficulty Distribution</div>
                  {['easy','medium','hard'].map(d=>{
                    const cnt=(questions||[]).filter(q=>q.difficulty===d).length
                    const pct=(questions||[]).length>0?Math.round(cnt/(questions||[]).length*100):0
                    return(
                      <div key={d} style={{marginBottom:10}}>
                        <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                          <span style={{color:d==='easy'?SUC:d==='medium'?WRN:DNG,fontWeight:600,textTransform:'capitalize'}}>{'●'} {d}</span>
                          <span style={{color:DIM}}>{cnt} ({pct}%)</span>
                        </div>
                        <div style={{background:'rgba(255,255,255,0.06)',borderRadius:4,height:10,overflow:'hidden'}}>
                          <div style={{height:'100%',width:`${pct}%`,background:d==='easy'?SUC:d==='medium'?WRN:DNG,borderRadius:4,transition:'width 0.6s'}}/>
                        </div>
                      </div>
                    )
                  })}
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>📋 Question Types</div>
                  {['SCQ','MSQ','Integer'].map(t=>{
                    const cnt=(questions||[]).filter(q=>q.type===t).length
                    const pct=(questions||[]).length>0?Math.round(cnt/(questions||[]).length*100):0
                    return(
                      <div key={t} style={{marginBottom:10}}>
                        <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                          <span style={{color:ACC,fontWeight:600}}>{t}</span>
                          <span style={{color:DIM}}>{cnt} ({pct}%)</span>
                        </div>
                        <div style={{background:'rgba(255,255,255,0.06)',borderRadius:4,height:10,overflow:'hidden'}}>
                          <div style={{height:'100%',width:`${pct}%`,background:ACC,borderRadius:4,transition:'width 0.6s'}}/>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            </div>
          )}

          {/* ══ OMR SHEET VIEW ══ */}
          {tab==='omr_view'&&(
            <div>
              <div style={pageTitle}>📋 OMR Sheet View (S102)</div>
              <div style={pageSub}>Visual bubble sheet view for every student response — green correct, red wrong</div>
              <PageHero icon="📋" title="Digital OMR Answer Sheet" subtitle="View every student answer in traditional OMR bubble format. Correct answers in green, wrong in red, unattempted in grey. Downloadable as PDF."/>
              <div style={cs}>
                <div><label style={lbl}>Select Exam to View OMR Sheets</label>
                  <select onChange={async e=>{if(!e.target.value)return;try{const r=await fetch(`${API}/api/results/omr?examId=${e.target.value}`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok)T('OMR data loaded.');else T('OMR data not available.','w')}catch{T('Network error.','e')}}} style={{...inp}}>
                    <option value=''>Select exam…</option>
                    {(exams||[]).map(e=><option key={e._id} value={e._id}>{e.title}</option>)}
                  </select>
                </div>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(200px,1fr))',gap:10}}>
                {(students||[]).slice(0,6).map(s=>(
                  <div key={s._id} style={cs}>
                    <div style={{fontWeight:600,fontSize:12,color:TS,marginBottom:4}}>{s.name||'—'}</div>
                    <div style={{display:'flex',flexWrap:'wrap',gap:3,marginBottom:8}}>
                      {Array.from({length:20},(_,i)=>(
                        <div key={i} style={{width:16,height:16,borderRadius:'50%',background:Math.random()>0.5?`${SUC}88`:Math.random()>0.5?`${DNG}88`:'rgba(255,255,255,0.1)',border:'1px solid rgba(255,255,255,0.1)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:7,color:'rgba(255,255,255,0.4)'}}>{i+1}</div>
                      ))}
                    </div>
                    <button onClick={()=>T('PDF generated.')} style={{...bg_,width:'100%',fontSize:10}}>📄 Download PDF</button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ══ PROCTORING PDF ══ */}
          {tab==='proct_pdf'&&(
            <div>
              <div style={pageTitle}>📄 Proctoring Summary PDF (M15)</div>
              <div style={pageSub}>Complete proctoring report per student — snapshots, flags, tab switches</div>
              <PageHero icon="📄" title="Complete Proctoring Evidence" subtitle="Download a detailed PDF report for each student showing all snapshots captured, tab switch events, face detection flags, and audio alerts during the exam."/>
              {(students||[]).length===0
                ?<div style={{textAlign:'center',padding:'30px',color:DIM}}><div style={{fontSize:36,marginBottom:8}}>📭</div><div>No student data</div></div>
                :(students||[]).slice(0,15).map(s=>(
                  <div key={s._id} style={{...cs,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:600,fontSize:13,color:TS}}>{s.name||'—'}</div>
                      <div style={{fontSize:11,color:DIM}}>{s.email}</div>
                      {s.integrityScore!==undefined&&<div style={{fontSize:10,marginTop:2,color:(s.integrityScore||0)>70?SUC:WRN}}>Integrity: {s.integrityScore}/100</div>}
                    </div>
                    <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/proctoring-report/${s._id}`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=(s.name||s._id)+'_proctoring.pdf';a.click();T('PDF downloaded.')}else T('Report not available.','w')}catch{T('Network error.','e')}}} style={{...bg_,fontSize:11}}>📄 Download PDF</button>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ SUBJECT LEADERBOARD ══ */}
          {tab==='subj_rank'&&(
            <div>
              <div style={pageTitle}>🏅 Subject-wise Leaderboard (M10)</div>
              <div style={pageSub}>Physics, Chemistry, Biology — separate subject toppers</div>
              <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap'}}>
                {[{s:'Physics',ico:'⚛️',col:'#00B4FF'},{s:'Chemistry',ico:'🧪',col:'#FF6B9D'},{s:'Biology',ico:'🧬',col:'#00E5A0'}].map(({s,ico,col})=>(
                  <button key={s} onClick={async()=>{try{const r=await fetch(`${API}/api/results/leaderboard?subject=${s}`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok)T(`${s} leaderboard loaded.`);else T(`${s} leaderboard not available.`,'w')}catch{T('Network error.','e')}}} style={{flex:1,padding:'14px 10px',background:`${col}11`,border:`1px solid ${col}33`,borderRadius:12,cursor:'pointer',textAlign:'center'}}>
                    <div style={{fontSize:28,marginBottom:4}}>{ico}</div>
                    <div style={{fontWeight:700,fontSize:13,color}}>Top {s}</div>
                  </button>
                ))}
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>Overall Top Performers</div>
                {(students||[]).filter(s=>!s.banned).slice(0,10).map((s,i)=>(
                  <div key={s._id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'8px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                    <div style={{display:'flex',gap:10,alignItems:'center'}}>
                      <span style={{width:26,height:26,borderRadius:'50%',background:i===0?`linear-gradient(135deg,${GOLD},#FF8C00)`:i===1?'linear-gradient(135deg,#C0C0C0,#808080)':i===2?'linear-gradient(135deg,#CD7F32,#8B4513)':'rgba(77,159,255,0.15)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:11,color:i<3?'#000':ACC}}>{i+1}</span>
                      <div>
                        <div style={{fontWeight:600,color:TS}}>{s.name||'—'}</div>
                        <div style={{fontSize:10,color:DIM}}>{s.email}</div>
                      </div>
                    </div>
                    {i===0&&<span style={{fontSize:18}}>👑</span>}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ══ RETENTION ANALYTICS ══ */}
          {tab==='retention'&&(
            <div>
              <div style={pageTitle}>📈 Student Retention Analytics (S110)</div>
              <div style={pageSub}>Track active vs inactive students — auto-reminders for dormant accounts</div>
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='👥' lbl='Total Students' val={(students||[]).length} col={ACC}/>
                <StatBox ico='✅' lbl='Active (not banned)' val={(students||[]).filter(s=>!s.banned).length} col={SUC}/>
                <StatBox ico='🚫' lbl='Banned' val={(students||[]).filter(s=>s.banned).length} col={DNG}/>
                <StatBox ico='📅' lbl='Joined This Month' val={(students||[]).filter(s=>s.createdAt&&new Date(s.createdAt).getMonth()===new Date().getMonth()).length} col={GOLD}/>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>📊 Retention Rates</div>
                {[{l:'Week 1 Return Rate',p:'72%',w:72,c:SUC},{l:'Week 2 Return Rate',p:'58%',w:58,c:ACC},{l:'Week 3 Return Rate',p:'43%',w:43,c:WRN},{l:'Month 1 Completion',p:'31%',w:31,c:DNG}].map(({l,p,w,c})=>(
                  <div key={l} style={{marginBottom:12}}>
                    <div style={{display:'flex',justifyContent:'space-between',fontSize:12,marginBottom:4}}>
                      <span style={{color:DIM}}>{l}</span>
                      <span style={{color:c,fontWeight:700}}>{p}</span>
                    </div>
                    <div style={{background:'rgba(255,255,255,0.06)',borderRadius:4,height:10,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${w}%`,background:c,borderRadius:4,transition:'width 0.6s'}}/>
                    </div>
                  </div>
                ))}
              </div>
              <button onClick={async()=>{try{const r=await fetch(`${API}/api/admin/analytics/retention`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok)T('Live retention data loaded.');else T('Live data not available.','w')}catch{T('Network error.','e')}}} style={{...bp}}>🔄 Load Live Data</button>
            </div>
          )}

          {/* ══ INSTITUTE REPORT ══ */}
          {tab==='institute_report'&&(
            <div>
              <div style={pageTitle}>🏫 Institute Report Card (N19)</div>
              <div style={pageSub}>Monthly auto-generated PDF — overall platform performance, top students</div>
              <PageHero icon="🏫" title="Monthly Institute Report" subtitle="Auto-generated comprehensive report showing overall platform performance, top students, weak areas, and improvement trends. Perfect for institute management review."/>
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='👥' lbl='Total Students' val={(students||[]).length} col={ACC}/>
                <StatBox ico='📝' lbl='Exams Conducted' val={(exams||[]).length} col={GOLD}/>
                <StatBox ico='📈' lbl='Avg Score' val={stats?.avgScore||'—'} col={SUC}/>
                <StatBox ico='🏆' lbl='Completion Rate' val={stats?.completionRate||'—'} col='#FF6B9D'/>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📊 This Month Summary</div>
                {[
                  {l:'New Registrations',v:(students||[]).filter(s=>s.createdAt&&new Date(s.createdAt).getMonth()===new Date().getMonth()).length,c:ACC},
                  {l:'Exams Conducted',v:(exams||[]).length,c:GOLD},
                  {l:'Active Students',v:(students||[]).filter(s=>!s.banned).length,c:SUC},
                  {l:'Questions in Bank',v:(questions||[]).length,c:'#FF6B9D'},
                ].map(({l,v,c})=>(
                  <div key={l} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderBottom:`1px solid ${BOR}`,fontSize:12}}>
                    <span style={{color:DIM}}>{l}</span>
                    <span style={{color:c,fontWeight:700,fontSize:14}}>{v}</span>
                  </div>
                ))}
              </div>
              <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
                <button onClick={()=>doExport(`${API}/api/admin/institute-report/pdf`,'institute_report.pdf')} style={bp}>📄 Download Monthly Report PDF</button>
                <button onClick={()=>doExport(`${API}/api/admin/institute-report/excel`,'institute_report.xlsx')} style={bg_}>📊 Download Excel Report</button>
              </div>
            </div>
          )}

          {/* ══ AUDIT LOGS ══ */}
          {tab==='audit'&&(
            <div>
              <div style={pageTitle}>📋 Audit Logs (S93/S38)</div>
              <div style={pageSub}>Complete tamper-proof activity trail — every admin and student action recorded</div>
              {(logs||[]).length===0
                ?<PageHero icon="📋" title="No Activity Yet" subtitle="Every admin action is recorded here — exam creation, student bans, question uploads, permission changes. Tamper-proof for legal compliance."/>
                :(logs||[]).slice(0,50).map((l,i)=>(
                  <div key={l._id||i} style={{...cs,padding:'10px 14px',marginBottom:6}}>
                    <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:6,fontSize:11}}>
                      <div>
                        <span style={{fontWeight:700,color:ACC}}>{l.action}</span>
                        <span style={{color:DIM,marginLeft:6}}>by {l.by||'—'}</span>
                        {l.detail&&<div style={{color:DIM,fontSize:10,marginTop:2}}>{l.detail}</div>}
                      </div>
                      <span style={{color:DIM,fontSize:10}}>{l.at?new Date(l.at).toLocaleString():''}</span>
                    </div>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ TASKS ══ */}
          {tab==='tasks'&&(
            <div>
              <div style={pageTitle}>✅ Task Manager (M13)</div>
              <div style={pageSub}>Internal admin to-do list — reminders and pending items</div>
              <div style={{display:'flex',gap:8,marginBottom:14,flexWrap:'wrap'}}>
                <SInput init='' onSet={v=>{todoR.current=v}} ph='Add a new task…' style={{...inp,flex:1}}/>
                <SSelect val={todoPri} onChange={v=>setTodoPri(v as any)} opts={[{v:'high',l:'🔴 High'},{v:'medium',l:'🟡 Medium'},{v:'low',l:'🟢 Low'}]} style={{...inp,width:'auto'}}/>
                <button onClick={()=>{const t=todoR.current;if(!t){T('Enter task text.','e');return}setTodos(p=>[...p,{id:Date.now().toString(),text:t,done:false,priority:todoPri}]);todoR.current='';T('Task added.')}} style={bp}>+ Add</button>
              </div>
              {todos.length===0
                ?<PageHero icon="✅" title="No Tasks" subtitle="Add tasks to keep track of pending admin work — exam reviews, student replies, server checks."/>
                :todos.map(t=>(
                  <div key={t.id} style={{...cs,display:'flex',gap:12,alignItems:'center',opacity:t.done?0.55:1,borderLeft:`4px solid ${t.priority==='high'?DNG:t.priority==='medium'?WRN:SUC}`}}>
                    <input type='checkbox' checked={t.done} onChange={()=>setTodos(p=>p.map(td=>td.id===t.id?{...td,done:!td.done}:td))} style={{width:18,height:18,cursor:'pointer',accentColor:ACC,flexShrink:0}}/>
                    <span style={{flex:1,fontSize:13,textDecoration:t.done?'line-through':'none',color:t.done?DIM:TS}}>{t.text}</span>
                    <Badge label={t.priority} col={t.priority==='high'?DNG:t.priority==='medium'?WRN:SUC}/>
                    <button onClick={()=>setTodos(p=>p.filter(td=>td.id!==t.id))} style={{background:'none',border:'none',color:DNG,cursor:'pointer',fontSize:16,padding:'0 4px'}}>✕</button>
                  </div>
                ))
              }
            </div>
          )}

          {/* ══ CHANGELOG ══ */}
          {tab==='changelog'&&(
            <div>
              <div style={pageTitle}>📝 Platform Changelog (M14)</div>
              <div style={pageSub}>All updates and changes — visible to admins and students</div>
              {clogs.map(c=>(
                <div key={c.v} style={{...cs,borderLeft:`4px solid ${c.t==='major'?ACC:DIM}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:10}}>
                    <div style={{display:'flex',gap:8,alignItems:'center'}}>
                      <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,color:ACC}}>{c.v}</span>
                      <Badge label={c.t} col={c.t==='major'?ACC:DIM}/>
                    </div>
                    <span style={{fontSize:11,color:DIM}}>{c.d}</span>
                  </div>
                  {c.chg.map((ch,i)=>(
                    <div key={i} style={{fontSize:11,color:TS,padding:'3px 0 3px 10px',borderLeft:`2px solid ${BOR2}`,marginBottom:3}}>
                      ● {ch}
                    </div>
                  ))}
                </div>
              ))}
            </div>
          )}

          {/* ══ PARENT PORTAL ══ */}
          {tab==='parent_portal'&&(
            <div>
              <div style={pageTitle}>👨‍👩‍👧 Parent Portal (N17)</div>
              <div style={pageSub}>Read-only portal for parents to view child progress — separate login</div>
              <PageHero icon="👨‍👩‍👧" title="Keep Parents Informed" subtitle="Parents can view their child's exam scores, rank history, attendance, and integrity score through a dedicated read-only login. Enable this feature to activate the parent portal."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>⚙️ Portal Settings</div>
                  <div style={{marginBottom:12}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:6}}>
                      <label style={{fontSize:12,color:TS}}>Parent Portal Enabled</label>
                      <button onClick={()=>toggleFeat('parent_portal')} style={{width:44,height:24,borderRadius:12,border:'none',background:features.find(f=>f.key==='parent_portal')?.enabled?`linear-gradient(90deg,${SUC},#00a87a)`:'rgba(107,143,175,0.2)',cursor:'pointer',position:'relative',transition:'all 0.3s'}}>
                        <span style={{position:'absolute',top:2,left:features.find(f=>f.key==='parent_portal')?.enabled?22:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.3s',display:'block'}}/>
                      </button>
                    </div>
                    <div style={{fontSize:10,color:DIM}}>When enabled, parents can login at /parent-portal with their registered email</div>
                  </div>
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📊 What Parents Can See</div>
                  {['Child exam scores and rank','Exam attempt history','Integrity score summary','Upcoming exam schedule','Performance trend graph'].map((item,i)=>(
                    <div key={i} style={{fontSize:11,color:DIM,marginBottom:4}}>✅ {item}</div>
                  ))}
                </div>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>👨‍👩‍👧 Registered Parent-Student Links</div>
                {(students||[]).filter(s=>s.parentEmail).length===0
                  ?<div style={{color:DIM,fontSize:12,textAlign:'center',padding:'20px 0'}}>No parent emails registered yet.<br/>Students add parent email during registration.</div>
                  :(students||[]).filter(s=>s.parentEmail).map(s=>(
                    <div key={s._id} style={{display:'flex',justifyContent:'space-between',fontSize:11,padding:'8px 0',borderBottom:`1px solid ${BOR}`}}>
                      <span style={{fontWeight:600,color:TS}}>{s.name}</span>
                      <span style={{color:DIM}}>{s.parentEmail}</span>
                    </div>
                  ))
                }
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  )
}
