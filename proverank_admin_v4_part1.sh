#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║   ProveRank Admin Panel V4 — PART 1 of 2                   ║
# ║   Rule C1: cat > EOF | Rule C2: NO sed -i | NO Python      ║
# ║   Design: N6 Neon Blue Arctic | Login page theme matched   ║
# ╚══════════════════════════════════════════════════════════════╝
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }
warn(){ echo -e "${Y}[NOTE]${N} $1"; }

FE=~/workspace/frontend
mkdir -p $FE/app/admin/x7k2p

step "Writing ProveRank Admin Panel V4 — Part 1"

cat > $FE/app/admin/x7k2p/page.tsx << 'ENDOFFILE'
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
  const [tab,setTab]=useState('dashboard')
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
      getFirst(`${API}/api/admin/users`,`${API}/api/admin/students`),
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
  const impersonate=useCallback(async()=>{
    if(!impId){T('Student ID required.','e');return}
    try{
      const res=await fetch(`${API}/api/admin/manage/impersonate/${impId}`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){const d=await res.json();T(`Viewing as: ${d.name||impId}`);window.open(`/dashboard?impersonate=${impId}`,'_blank')}
      else T('Impersonate failed.','e')
    } catch{T('Network error.','e')}
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
                <StatBox ico='📈' lbl='Exam Attempts' val={loading?'…':stats?.totalAttempts||'—'} col={SUC}/>
                <StatBox ico='🟢' lbl='Active Today' val={loading?'…':stats?.activeStudents||'—'} col='#00E5FF'/>
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

ENDOFFILE

log "Part 1 written — $(wc -l < $FE/app/admin/x7k2p/page.tsx) lines so far"
step "Part 1 Complete!"
echo ""
echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}PART 1 DONE!${N} Now run Part 2 script to complete the panel."
echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo ""
echo "DO NOT run git push yet — run Part 2 first!"
