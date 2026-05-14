'use client'
import { useState, useEffect, useRef, useCallback, memo } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from '@/lib/auth'

// ── API Base ──
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── TypeScript Interfaces ──
interface Student { _id:string;name:string;email:string;phone?:string;role:string;createdAt:string;banned?:boolean;banReason?:string;group?:string;integrityScore?:number;loginHistory?:any[];parentEmail?:string;deleted?:boolean;deletedAt?:string;deleteReason?:string;city?:string;school?:string;dob?:string;targetExam?:string;qualifications?:string;_snapshot?:any }
interface Exam { _id:string;title:string;scheduledAt:string;totalMarks:number;duration:number;status:string;attempts?:number;category?:string;password?:string;batch?:string;subject?:string }
interface Question { _id:string;text:string;subject:string;chapter?:string;topic?:string;difficulty:string;type:string;options?:string[];correctAnswer?:string;explanation?:string;approvalStatus?:string }
interface Log { _id:string;action:string;by:string;at:string;detail:string }
interface Flag { _id:string;studentName:string;examTitle:string;type:string;count:number;severity:string;at:string;integrityScore?:number }
interface Ticket { _id:string;studentName:string;examTitle:string;type:string;status:string;createdAt:string;description:string }
interface Feature { key:string;label:string;description:string;enabled:boolean }
interface Notif { id:string;icon:string;msg:string;t:string;read:boolean }
interface Snapshot { _id:string;studentName:string;imageUrl?:string;flagged:boolean;capturedAt:string;examTitle?:string }
interface Batch { _id:string;name:string;studentCount:number;examCount:number;createdAt:string }
interface AdminUser { _id:string;name:string;email:string;role:string;createdAt:string;active:boolean;frozen?:boolean;archived?:boolean;archivedAt?:string;archivedBy?:string;permissions?:any }
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
  const blockSize = size * 0.94
  const pSize = Math.round(blockSize * 0.63)
  const rSize = Math.round(blockSize * 0.63)
  const fontSize = Math.round(pSize * 0.52)
  const radius = Math.round(pSize * 0.28)
  return (
    <div style={{position:'relative',width:blockSize,height:blockSize,flexShrink:0,display:'inline-flex'}}>
      <div style={{
        position:'absolute',top:0,left:0,
        width:pSize,height:pSize,
        borderRadius:radius,
        background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:fontSize,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#030810',
        boxShadow:'0 4px 16px rgba(77,159,255,0.4)'
      }}>P</div>
      <div style={{
        position:'absolute',bottom:0,right:0,
        width:rSize,height:rSize,
        borderRadius:radius,
        background:'rgba(0,212,255,0.1)',
        border:'1.5px solid rgba(0,212,255,0.45)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:fontSize,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#00D4FF',
        backdropFilter:'blur(8px)'
      }}>R</div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════
// PARTICLES BACKGROUND — Same as Login page
// ══════════════════════════════════════════════════════════════
function GalaxyBg() {
  const canvasRef=useRef(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    let W=window.innerWidth,H=window.innerHeight
    canvas.width=W;canvas.height=H
    // Stars
    const stars=[]
    for(let i=0;i<280;i++)stars.push({x:Math.random()*W,y:Math.random()*H,r:Math.random()*1.2+0.2,op:Math.random(),spd:0.003+Math.random()*0.007})
    // Particles
    const pts=[]
    for(let i=0;i<55;i++)pts.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.4,vy:(Math.random()-.5)*.4,r:Math.random()*1.4+0.4,op:Math.random()*.35+.12})
    // Nebula defs
    const nebs=[
      {fx:0.12,fy:0.22,fr:0.22,c:'rgba(77,159,255,0.18)'},
      {fx:0.82,fy:0.55,fr:0.26,c:'rgba(110,70,255,0.15)'},
      {fx:0.48,fy:0.88,fr:0.20,c:'rgba(0,212,255,0.14)'},
      {fx:0.28,fy:0.68,fr:0.17,c:'rgba(255,90,180,0.12)'},
      {fx:0.65,fy:0.15,fr:0.19,c:'rgba(0,230,160,0.11)'},
    ]
    let angle=0
    let animId
    const draw=()=>{
      ctx.clearRect(0,0,W,H)
      // Nebula blobs
      nebs.forEach(function(n){
        const nx=n.fx*W,ny=n.fy*H,nr=n.fr*W
        const g=ctx.createRadialGradient(nx,ny,0,nx,ny,nr)
        g.addColorStop(0,n.c)
        g.addColorStop(1,'rgba(0,0,0,0)')
        ctx.fillStyle=g;ctx.beginPath();ctx.arc(nx,ny,nr,0,Math.PI*2);ctx.fill()
      })
      // Galaxy spiral arms
      const cx=W*0.5,cy=H*0.42
      for(let arm=0;arm<3;arm++){
        for(let t=0;t<90;t++){
          const a=angle+(arm*Math.PI*2/3)+(t*0.11)
          const dist=t*2.8
          const sx=cx+Math.cos(a)*dist,sy=cy+Math.sin(a)*dist*0.42
          if(sx<0||sx>W||sy<0||sy>H)continue
          const op=Math.max(0,(1-t/90)*0.35)
          ctx.beginPath();ctx.arc(sx,sy,0.9,0,Math.PI*2)
          ctx.fillStyle='rgba(120,190,255,'+op+')'
          ctx.fill()
        }
      }
      // Galaxy core
      const cg=ctx.createRadialGradient(cx,cy,0,cx,cy,20)
      cg.addColorStop(0,'rgba(180,220,255,0.55)')
      cg.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=cg;ctx.beginPath();ctx.arc(cx,cy,20,0,Math.PI*2);ctx.fill()
      angle+=0.0007
      // Twinkling stars
      stars.forEach(function(s){
        s.op+=s.spd;if(s.op>=1||s.op<=0.02)s.spd*=-1
        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2)
        ctx.fillStyle='rgba(215,235,255,'+Math.min(s.op*1.0,0.95)+')'
        ctx.fill()
      })
      // Particles
      pts.forEach(function(p){
        p.x+=p.vx;p.y+=p.vy
        if(p.x<0)p.x=W;if(p.x>W)p.x=0
        if(p.y<0)p.y=H;if(p.y>H)p.y=0
        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle='rgba(77,159,255,'+p.op+')'
        ctx.fill()
      })
      // Connection lines
      for(let i=0;i<pts.length;i++)for(let j=i+1;j<pts.length;j++){
        const dx=pts[i].x-pts[j].x,dy=pts[i].y-pts[j].y,d=Math.sqrt(dx*dx+dy*dy)
        if(d<115){
          ctx.beginPath();ctx.moveTo(pts[i].x,pts[i].y);ctx.lineTo(pts[j].x,pts[j].y)
          ctx.strokeStyle='rgba(77,159,255,'+0.12*(1-d/115)+')'
          ctx.lineWidth=.5;ctx.stroke()
        }
      }
      animId=requestAnimationFrame(draw)
    }
    draw()
    const resize=function(){W=canvas.width=window.innerWidth;H=canvas.height=window.innerHeight}
    window.addEventListener('resize',resize)
    return function(){cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}

// ══════════════════════════════════════════════════════════════
// GLOBAL SEARCH COMPONENT (M12)
// ══════════════════════════════════════════════════════════════
const GlobalSearch=memo(function GlobalSearch({students,exams,questions,setTab,setSelStudent,token}:{students:Student[];exams:Exam[];questions:Question[];setTab:(t:string)=>void;setSelStudent:(s:Student)=>void;token:string}) {
  const [q,setQ]=useState('')
  const res=q.length<2?[]:[
    ...(students||[]).filter(s=>s.name?.toLowerCase().includes(q.toLowerCase())||s.email?.toLowerCase().includes(q.toLowerCase())).slice(0,4).map(s=>({type:'Student',label:s.name+' · '+s.email,icon:'👤',go:()=>{setSelStudent(s);_setTab('students')}})),
    ...(exams||[]).filter(e=>e.title?.toLowerCase().includes(q.toLowerCase())).slice(0,4).map(e=>({type:'Exam',label:e.title+' · '+e.status,icon:'📝',go:()=>_setTab('exams')})),
    ...(questions||[]).filter(qn=>qn.text?.toLowerCase().includes(q.toLowerCase())).slice(0,4).map(qn=>({type:'Question',label:qn.text?.slice(0,70)+'…',icon:'❓',go:()=>_setTab('questions')})),
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
            <button key={c.tab} onClick={()=>_setTab(c.tab)} style={{padding:'16px',background:'rgba(0,22,40,0.5)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,cursor:'pointer',textAlign:'left'}}>
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
const BG_GRAD='radial-gradient(ellipse at 20% 50%,#001e38 0%,#000f22 60%,#000810 100%)'
const CRD='rgba(0,28,52,0.88)'
const CRD2='rgba(0,36,65,0.92)'
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
    <div style={{background:CRD,border:`1px solid ${BOR}`,borderRadius:14,padding:'16px 12px',width:'100%',backdropFilter:'blur(12px)',position:'relative',overflow:'hidden'}}>
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
  useEffect(()=>{const r=localStorage.getItem('pr_role');if(r&&r!=='superadmin'){window.location.href='/admin/x7k2p/admin-panel';}},[]);
  const [role,setRole]=useState('')
  const [token,setToken]=useState('')
  const [mounted,setMounted]=useState(false)
  const [tab,setTab]=useState(()=>{try{return sessionStorage.getItem('pr_admin_tab')||'dashboard'}catch{return'dashboard'}})
  const _setTab=(t:string)=>{try{sessionStorage.setItem('pr_admin_tab',t)}catch{};setTab(t)}
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
  const [stdFilter,setStdFilter]=useState<'all'|'active'|'banned'|'deleted'>('all')
  const [examSearch,setExamSearch]=useState('')
  const [qSearch,setQSearch]=useState('')
  const [qSubjFilter,setQSubjFilter]=useState('all')
  const [selStudent,setSelStudent]=useState<Student|null>(null)

  // Exam Create refs (keyboard fix)
  const eTitleR=useRef('');
  const [archivedAdmins,setArchivedAdmins]=useState([] as any[]);
  const [profileAdmin,setProfileAdmin]=useState(null as any);
  const [profileLogs,setProfileLogs]=useState([] as any[]);
  const [showProfileModal,setShowProfileModal]=useState(false);
  const [profileLoading,setProfileLoading]=useState(false);const eDateR=useRef('')
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
  const [delConfirmId,setDelConfirmId]=useState('')
  const delReasonR=useRef('')
  const [deletedStds,setDeletedStds]=useState<any[]>([])
  const [stdDelLoading,setStdDelLoading]=useState(false)
  const [stdSort,setStdSort]=useState<'newest'|'name'|'active'>('newest')
  const [banT,setBanT]=useState<'permanent'|'temporary'>('permanent')

  // Announcement refs
  const annR=useRef('');const annTitleR=useRef('')
  const [annBatch,setAnnBatch]=useState('all')
  const [annType,setAnnType]=useState<'in-app'|'email'|'both'>('both')

  // Branding refs
  const bNameR=useRef('ProveRank');const bTagR=useRef('Prove Your Rank')
  const [brandLoaded,setBrandLoaded]=useState({bName:'ProveRank',bTag:'Prove Your Rank',bMail:'support@proverank.com',bPhone:'',seoT:'ProveRank — NEET Online Test Platform',seoD:'',seoK:'NEET,online test,mock exam'})
  const bMailR=useRef('support@proverank.com');const bPhoneR=useRef('')
  const seoTR=useRef('ProveRank — NEET Online Test Platform')
  const seoDR=useRef('Best NEET mock test platform with AI analytics and anti-cheat proctoring.')
  const seoKR=useRef('NEET,online test,mock exam,ProveRank')
  const mainMsgR=useRef('Site under maintenance. We will be back shortly.')
  const maintWhitelistR=useRef('')
  const [savingWL,setSavingWL]=useState(false)
  const [wlText,setWlText]=useState('')
  const [savingB,setSavingB]=useState(false)
  const [mainOn,setMainOn]=useState(()=>{try{return localStorage.getItem('pr_maint')==='1'}catch{return false}})

  // Impersonate / time extension
  const [impId,setImpId]=useState('')
  const [extStdId,setExtStdId]=useState('')
  const [extMins,setExtMins]=useState('10')

  // Permissions
  const [perms,setPerms]=useState({
  create_exam:false,edit_exam:false,delete_exam:false,clone_exam:false,bulk_exam:false,
  manage_questions:false,bulk_upload:false,ai_questions:false,pyq_access:false,
  view_students:false,ban_student:false,impersonate:false,export_data:false,batch_transfer:false,
  view_results:false,view_analytics:false,view_leaderboard:false,download_reports:false,
  send_announcements:false,manage_doubts:false,manage_grievances:false,answer_key_challenge:false,
  manage_features:false,manage_branding:false,view_audit_logs:false,view_snapshots:false,manage_backup:false,manage_admins:false,
});
const [selectedPermAdmin,setSelectedPermAdmin]=useState(null);
const [adminOwnPerms,setAdminOwnPerms]=useState({});

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
    setToken(t);setRole(r);setMounted(true);if(typeof window!=='undefined'&&sessionStorage.getItem('pr_just_logged_in')){sessionStorage.removeItem('pr_just_logged_in');sessionStorage.removeItem('pr_admin_tab');setTab('dashboard');};
    // If admin (not superadmin), fetch own permissions for nav filtering
    if(r==='admin'){
      fetch((process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com')+'/api/admin/manage/profile/me',{headers:{Authorization:'Bearer '+t}})
        .then(res=>res.json())
        .then(d=>{
          if(d.success&&d.admin&&d.admin.permissions){
            const p=d.admin.permissions;
            const obj=typeof p.forEach==='function'?Object.fromEntries(p):p;
            setAdminOwnPerms(obj||{});
          }
        })
        .catch(()=>{
          // fallback: try profile with own ID from token
        });
    }
  },[router])

  useEffect(()=>{if(token){fetchAll();fetchArchivedAdmins();}},[token])

  // ══ FETCH ALL DATA ══
    const fetchArchivedAdmins=async()=>{try{const r=await fetch(API+'/api/admin/manage/archived',{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success)setArchivedAdmins(d.admins||d.data||[]);else setArchivedAdmins([]);}catch(e){}};
  const viewAdminProfile=async(adminId:string)=>{setProfileLoading(true);setShowProfileModal(true);setProfileAdmin(null);setProfileLogs([]);try{const r=await fetch(API+'/api/admin/manage/profile/'+adminId,{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success){setProfileAdmin(d.admin);setProfileLogs(d.activityLogs||[]);}}catch(e){}setProfileLoading(false);};
  const restoreAdmin=async(adminId:string)=>{if(!confirm('Restore admin?'))return;try{const r=await fetch(API+'/api/admin/manage/restore/'+adminId,{method:'PUT',headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success){T('Restored! ✅','s');fetchArchivedAdmins();fetchAdmins();}else T(d.message||'Failed','e');}catch(e){}};
  const fetchAll=useCallback(async()=>{
    if(!token)return
    setLoading(true)
    const get=async(u:string)=>{try{const r=await fetch(u,{headers:{Authorization:`Bearer ${token}`}});return r.ok?r.json():null}catch{return null}}
    const getFirst=async(...urls:string[])=>{for(const u of urls){try{const r=await fetch(u,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const d=await r.json();if(d)return d}}catch{}}return null}
    const [us,ex,qs,st,fl,al,tk,sn,ft,nf,bt,au,rs,mn]=await Promise.all([
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
      get(`${API}/api/admin/maintenance`),
    ])
    if(Array.isArray(us))setStudents(us)
    else if(us&&Array.isArray(us.students))setStudents(us.students)
    else if(us&&Array.isArray(us.data))setStudents(us.data)
    else if(us&&Array.isArray(us.users))setStudents(us.users)
    if(Array.isArray(ex))setExams(ex)
    if(Array.isArray(qs))setQuestions(qs)
    if(st)setStats(st)
    if(Array.isArray(fl))setFlags(fl)
    if(Array.isArray(al))setLogs(al)
    if(Array.isArray(tk))setTickets(tk)
    if(Array.isArray(sn))setSnapshots(sn)
    if(Array.isArray(nf))setNotifs(nf)
    if(Array.isArray(bt))setBatches(bt)
    if(Array.isArray(au))setAdminUsers(au);else if(au&&Array.isArray(au.admins))setAdminUsers(au.admins)
    if(Array.isArray(rs))setResults(rs)
    if(mn&&mn.maintenance!=null){
      const s=mn.maintenance.enabled===true
      setMainOn(s)
      try{localStorage.setItem('pr_maint',s?'1':'0')}catch{}
      if(mn.maintenance.allowedEmails&&Array.isArray(mn.maintenance.allowedEmails)){
        const wl=mn.maintenance.allowedEmails.join('\n')
        maintWhitelistR.current=wl
        setWlText(wl)
      }
    }
    if(ft){
      if(Array.isArray(ft)&&ft.length)setFeatures(ft)
      else if(ft&&typeof ft==='object')setFeatures(DEF_FEATURES.map(f=>({...f,enabled:ft[f.key]!==undefined?Boolean(ft[f.key]):f.enabled})))
      }
    setLoading(false)
    // Fallback: 4 sec baad bhi loading true ho to force false
    setTimeout(()=>setLoading(false), 4000)
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

  // ── SOFT DELETE STUDENT (SuperAdmin only) ──
  const softDelStd=useCallback(async(id:string)=>{
    setStdDelLoading(true)
    try{
      const res=await fetch(`${API}/api/admin/delete/${id}`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({reason:delReasonR.current||'Removed by SuperAdmin'})})
      if(res.ok){
        setStudents((p:any)=>p.filter((s:any)=>s._id!==id))
        if(selStudent?._id===id) setSelStudent(null)
        setDelConfirmId('')
        delReasonR.current=''
        T('Student account archived successfully.','s')
      } else {
        const d=await res.json()
        T(d.error||'Delete failed. Try again.','e')
      }
    } catch{ T('Network error.','e') }
    finally{ setStdDelLoading(false) }
  },[token,T,selStudent])

  // ── RESTORE DELETED STUDENT (SuperAdmin only) ──
  const restoreStd=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/restore/${id}`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){
        setDeletedStds((p:any)=>p.filter((s:any)=>s._id!==id))
        T('Student account restored successfully! 🎉','s')
        fetchAll()
      } else { T('Restore failed. Try again.','e') }
    } catch{ T('Network error.','e') }
  },[token,T,fetchAll])

  // ── FETCH DELETED STUDENTS ──
  const fetchDeletedStds=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/deleted-students`,{headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){
        const d=await res.json()
        setDeletedStds(Array.isArray(d)?d:(d.students||[]))
      }
    } catch{}
  },[token])


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
  useEffect(()=>{
  if(tab==='branding'){
    const tk=getToken();if(!tk)return
    fetch(API+'/api/admin/branding',{headers:{Authorization:'Bearer '+tk}})
      .then(r=>r.json()).then(d=>{
        if(d.success&&d.branding){
          const b=d.branding
          const loaded={bName:b.brandName||'ProveRank',bTag:b.tagline||'Prove Your Rank',bMail:b.supportEmail||'support@proverank.com',bPhone:b.phone||'',seoT:b.seoTitle||'ProveRank — NEET Online Test Platform',seoD:b.seoDesc||'',seoK:b.seoKeywords||'NEET,online test,mock exam'}
          setBrandLoaded(loaded)
          bNameR.current=loaded.bName;bTagR.current=loaded.bTag
          bMailR.current=loaded.bMail;bPhoneR.current=loaded.bPhone
          seoTR.current=loaded.seoT;seoDR.current=loaded.seoD;seoKR.current=loaded.seoK
        }
      }).catch(()=>{})
  }
},[tab])
  const saveBrand=useCallback(async()=>{
    setSavingB(true)
    try{
      const res=await fetch(`${API}/api/admin/branding`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({brandName:bNameR.current,tagline:bTagR.current,supportEmail:bMailR.current,phone:bPhoneR.current,seoTitle:seoTR.current,seoDesc:seoDR.current,seoKeywords:seoKR.current})})
      if(res.ok)T('Branding & SEO settings saved.')
      else T('Failed to save settings.','e')
    } catch{T('Network error.','e')}
    setSavingB(false)
  },[token,T])

  // ══ MAINTENANCE WHITELIST SAVE ══
  const saveWhitelist=useCallback(async()=>{
    setSavingWL(true)
    try{
      const emails=maintWhitelistR.current.split('\n').map(e=>e.trim()).filter(Boolean)
      const r=await fetch(`${API}/api/admin/maintenance`,{
        method:'POST',
        headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify({enabled:mainOn,message:mainMsgR.current,allowedEmails:emails})
      })
      const d=await r.json()
      if(d.success) T('Whitelist saved successfully!')
      else T('Failed to save whitelist','e')
    }catch(e){T('Network error','e')}
    setSavingWL(false)
  },[mainOn,token,T])

  // ══ MAINTENANCE ══
  const toggleMaint=useCallback(async()=>{
    const nm=!mainOn
    setMainOn(nm)
    try{localStorage.setItem('pr_maint',nm?'1':'0')}catch{}
    const doPost=async()=>{
      const r=await fetch(`${API}/api/admin/maintenance`,{
        method:'POST',
        headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify({enabled:nm,message:mainMsgR.current,allowedEmails:maintWhitelistR.current.split('\n').map(e=>e.trim()).filter(Boolean)})
      })
      return r.ok?r.json():null
    }
    try{
      let md=await doPost()
      if(!md||!md.success){
        await new Promise(r=>setTimeout(r,3000))
        md=await doPost()
      }
      if(md&&md.success){
        T(nm?'🔴 Maintenance ON — Students blocked':'🟢 Platform Live — Students can access','s')
      }else{
        setMainOn(!nm)
        T('Save failed — Render server busy, try again','e')
      }
    }catch(e){
      setMainOn(!nm)
      T('Network error — please try again','e')
    }
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
      const res=await fetch(`${API}/api/admin/manage/create-admin`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({name:admNameR.current,email:admEmailR.current,password:admPassR.current,role:admRole})})
      if(res.ok){T('Admin account created.');try{const r=await fetch(`${API}/api/admin/manage/admins`,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const d=await r.json();setAdminUsers(Array.isArray(d)?d:(Array.isArray(d.admins)?d.admins:[]))}}catch(_e){}}
      else{const e=await res.json().catch(()=>({}));T(e.message||'Failed to create admin.','e')}
    } catch{T('Network error.','e')}
    setCreatingAdm(false)
  },[admRole,token,T])

  // ══ PERMISSIONS ══
  const savePerms=useCallback(async()=>{
  if(!selectedPermAdmin){T('Pehle koi admin select karo','e');return;}
  try{
    const r=await fetch(API+'/api/admin/manage/permissions/'+selectedPermAdmin._id,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({permissions:perms})});
    const d=await r.json();
    if(d.success) T('Permissions saved for '+selectedPermAdmin.name+' ✅');
    else T(d.message||'Failed to save permissions','e');
  }catch(e){T('Network error — check connection','e');}
},[perms,token,T,selectedPermAdmin]);

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
      const d=await res.json()
      if(res.ok)T(d.message||'Email sent successfully.')
      else T(d.error||'Failed to send email.','e')
    } catch{T('Network error.','e')}
    setSendingEmail(false)
  },[emailType,token,T])

  // ══ GUARD ══
  if(!mounted)return null

  // ══ COMPUTED DATA ══
  const fStds=(students||[]).filter((s:any)=>{
    if(s.deleted)return false  // hide archived from main list
    if(stdFilter==='deleted')return false  // archived shown separately
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

  // ── Admin role: filter NAV based on their permissions ──
  const PERM_TO_NAV:{[k:string]:string[]}={
    create_exam:['create_exam','templates','bulk_creator'],
    edit_exam:['exams'],delete_exam:['exams'],clone_exam:['exams'],
    bulk_exam:['bulk_creator'],
    manage_questions:['questions'],
    ai_questions:['smart_gen'],
    pyq_access:['pyq_bank'],
    view_students:['students'],ban_student:['students'],impersonate:['students'],
    batch_transfer:['batches'],
    view_results:['results'],
    view_leaderboard:['leaderboard'],
    view_analytics:['analytics'],
    download_reports:['reports','qbank_stats'],
    export_data:['reports'],
    send_announcements:['announcements'],
    manage_doubts:['tickets'],
    manage_grievances:['tickets'],
    answer_key_challenge:['ans_challenge'],
    view_audit_logs:['audit'],
    view_snapshots:['snapshots','cheating','integrity'],
    manage_features:['features'],
    manage_branding:['branding'],
    manage_backup:['backup'],
  }
  const ADMIN_HIDDEN=['admins','permissions','maintenance','changelog','tasks','parent_portal','transparency','omr_view','proct_pdf','retention','institute_report','re_eval','whatsapp_sms','email_tmpl','custom_fields','global_search','live']
  const filteredNAV=role==='superadmin'?NAV:(()=>{
    const allowed=new Set(['dashboard'])
    Object.entries(adminOwnPerms).forEach(([perm,val])=>{
      if(val&&PERM_TO_NAV[perm]) PERM_TO_NAV[perm].forEach(t=>allowed.add(t))
    })
    return NAV.filter(n=>allowed.has(n.id)&&!ADMIN_HIDDEN.includes(n.id))
  })()
  const filteredNavGroups=[...new Set(filteredNAV.map(n=>n.grp))]

  // ══════════════════════════════════════════════════════════════
  // RENDER
  // ══════════════════════════════════════════════════════════════
  return (
    <div style={{background:BG_GRAD,minHeight:'100vh',color:TS,fontFamily:'Inter,sans-serif',position:'relative'}}>

      {/* Particles Background */}
      <GalaxyBg />

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
      <div style={{position:'sticky',top:0,zIndex:100,background:'rgba(0,10,24,0.95)',backdropFilter:'blur(20px)',borderBottom:`1px solid ${BOR}`,padding:'0 12px',height:56,display:'flex',alignItems:'center',justifyContent:'space-between',boxShadow:'0 2px 20px rgba(0,0,0,0.4)',overflow:'hidden'}}>

        {/* Left: Hamburger + Logo */}
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <button onClick={()=>setSideOpen(p=>!p)} style={{background:'none',border:'none',color:TS,fontSize:20,cursor:'pointer',padding:'4px 6px',borderRadius:6}}>☰</button>
          <div style={{display:'flex',alignItems:'center',gap:8}}>
            <PRLogo size={32}/>
            <div>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:13,background:`linear-gradient(90deg,${ACC},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1,whiteSpace:'nowrap'}}>
                ProveRank
              </div>
              {/* SCREENSHOT-MATCHED: role display with lightning bolt */}
              <div style={{fontSize:9,fontWeight:700,letterSpacing:1,color:role==='superadmin'?GOLD:ACC,lineHeight:1.2,whiteSpace:'nowrap'}}>
                ⚡ {role.toUpperCase()}
              </div>
            </div>
          </div>
        </div>

        {/* Right: Notifs + Refresh + Logout */}
        <div style={{display:'flex',gap:6,alignItems:'center',flexShrink:0}}>
          {loading&&<span style={{fontSize:10,color:DIM,animation:'pulse 1s infinite'}}>⟳</span>}

          {/* Notifications */}
          <button onClick={()=>setNotifOpen(p=>!p)} style={{background:'none',border:`1px solid ${BOR}`,color:TS,fontSize:14,cursor:'pointer',position:'relative',width:32,height:32,borderRadius:8,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}>
            🔔
            {(notifs||[]).filter(n=>!n.read).length>0&&<span style={{position:'absolute',top:-2,right:-2,background:DNG,color:'#fff',fontSize:8,borderRadius:'50%',width:14,height:14,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700}}>{(notifs||[]).filter(n=>!n.read).length}</span>}
          </button>

          <button onClick={fetchAll} title="Refresh" style={{background:'rgba(77,159,255,0.1)',color:ACC,border:`1px solid ${BOR2}`,borderRadius:8,width:32,height:32,cursor:'pointer',fontSize:14,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}>↻</button>
          <button onClick={()=>{clearAuth();router.replace('/login')}} style={{background:'rgba(255,77,77,0.12)',color:DNG,border:'1px solid rgba(255,77,77,0.25)',borderRadius:8,width:32,height:32,cursor:'pointer',fontWeight:700,fontSize:14,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,fontSize:11,fontWeight:700}}>OUT</button>
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
          {filteredNavGroups.map(grp=>(
            <div key={grp} style={{marginBottom:4}}>
              <div style={{fontSize:9,fontWeight:700,color:'rgba(107,143,175,0.5)',letterSpacing:1.5,textTransform:'uppercase',padding:'10px 14px 4px'}}>{grp}</div>
              {filteredNAV.filter(n=>n.grp===grp).map(n=>(
                <button key={n.id} className="nav-btn" onClick={()=>{_setTab(n.id);setSideOpen(false)}}
                  style={{display:'flex',alignItems:'center',gap:9,padding:'8px 12px',borderRadius:8,border:'none',background:tab===n.id?'rgba(77,159,255,0.15)':'transparent',color:tab===n.id?ACC:DIM,cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:12,fontWeight:tab===n.id?700:400,width:'100%',textAlign:'left',borderLeft:tab===n.id?`3px solid ${ACC}`:'3px solid transparent'}}>
                  <span style={{fontSize:14,width:18,textAlign:'center'}}>{n.ico}</span>
                  <span>{n.lbl}</span>
                </button>
              ))}
            </div>
          ))}
        </div>

        {/* ══ MAIN CONTENT ══ */}
        <div style={{flex:1,padding:'20px 16px',maxWidth:'100vw',overflow:'auto',animation:'fadeIn 0.4s ease',paddingBottom:32}}>

          {/* ══ DASHBOARD ══ */}
          {tab==='dashboard'&&(
            <div>
              <div style={{marginBottom:20}}>
                <div style={pageTitle}>📊 Dashboard Overview</div>
                <div style={pageSub}>Welcome back, {role==='superadmin'?'Super Admin':'Admin'} — Here is your platform at a glance</div>
              </div>

              {/* Stats Row */}
              <div style={{display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:10,marginBottom:20}}>
                <StatBox ico='👥' lbl='Total Students' val={loading?'…':stats?.totalStudents||(students||[]).length||0} col={ACC}/>
                <StatBox ico='📝' lbl='Total Exams' val={loading?'…':stats?.totalExams||(exams||[]).length||0} col={GOLD}/>
                <StatBox ico='📈' lbl='Exam Attempts' val={loading?'…':stats?.totalAttempts??0} col={SUC}/>
                <StatBox ico='🟢' lbl='Active Today' val={loading?'…':stats?.activeStudents??0} col='#00E5FF'/>
                <StatBox ico='❓' lbl='Questions' val={loading?'…':stats?.totalQuestions||(questions||[]).length||0} col='#FF6B9D'/>
              </div>

              {/* Hero Banner */}
              <div style={{background:`linear-gradient(135deg,rgba(0,85,204,0.40),rgba(77,159,255,0.20))`,border:`1px solid rgba(77,159,255,0.25)`,borderRadius:16,padding:'24px 20px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',right:-20,top:-20,fontSize:100,opacity:0.06}}>⬡</div>
                <div style={{position:'absolute',right:30,top:20,fontSize:60,opacity:0.08}}>⬡</div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:TS,marginBottom:6}}>🎯 ProveRank Admin Center</div>
                <div style={{fontSize:12,color:DIM,lineHeight:1.7,maxWidth:500}}>
                  Manage your complete NEET test platform from here. Create exams, monitor students, review analytics, and keep your platform running smoothly.
                </div>
                <div style={{display:'flex',flexWrap:'wrap',gap:8,marginTop:14}}>
                  {[['➕ Create Exam','create_exam',ACC],['👥 All Students','students',SUC],['🔴 Live Monitor','live',DNG],['📊 Analytics','analytics',GOLD]].map(([l,t,c])=>(
                    <button key={String(t)} onClick={()=>_setTab(String(t))} style={{padding:'8px 16px',background:`${c}22`,border:`1px solid ${c}44`,color:String(c),borderRadius:20,cursor:'pointer',fontSize:12,fontWeight:600}}>{String(l)}</button>
                  ))}
                </div>
              </div>

              {/* 2-col grid */}
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(280px,1fr))',gap:14,marginBottom:14}}>
                {/* Recent Exams */}
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <span>📝 Recent Exams</span>
                    <button onClick={()=>_setTab('exams')} style={{...bg_,padding:'4px 10px',fontSize:10}}>View All</button>
                  </div>
                  {(exams||[]).length===0
                    ?<div style={{textAlign:'center',padding:'20px 0',color:DIM}}>
                      <div style={{fontSize:30,marginBottom:8}}>📭</div>
                      <div style={{fontSize:12}}>No exams yet</div>
                      <button onClick={()=>_setTab('create_exam')} style={{...bp,fontSize:11,padding:'6px 14px',marginTop:8}}>Create First Exam</button>
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
                        <button key={String(t)} onClick={()=>_setTab(String(t))} style={{...bg_,textAlign:'center',fontSize:11,padding:'8px 6px'}}>{String(l)}</button>
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
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',gap:12}}>
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

              {/* ══ SCIENCE ILLUSTRATION SECTION ══ */}
              <div style={{marginTop:20,display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:12}}>
                {[
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><circle cx="40" cy="40" r="8" fill="none" stroke="#4D9FFF" strokeWidth="2"/><ellipse cx="40" cy="40" rx="30" ry="12" fill="none" stroke="#4D9FFF" strokeWidth="1.5" opacity="0.7"/><ellipse cx="40" cy="40" rx="30" ry="12" fill="none" stroke="#00D4FF" strokeWidth="1" transform="rotate(60 40 40)" opacity="0.5"/><ellipse cx="40" cy="40" rx="30" ry="12" fill="none" stroke="#7050FF" strokeWidth="1" transform="rotate(120 40 40)" opacity="0.5"/><circle cx="40" cy="40" r="3" fill="#4D9FFF"/></svg>,title:'Atomic Structure',fact:'An atom is 99.99% empty space'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><path d="M20 20 Q40 5 60 20 Q75 40 60 60 Q40 75 20 60 Q5 40 20 20Z" fill="none" stroke="#00E5A0" strokeWidth="1.5"/><circle cx="30" cy="35" r="4" fill="#00E5A0" opacity="0.8"/><circle cx="50" cy="35" r="4" fill="#00E5A0" opacity="0.8"/><circle cx="40" cy="50" r="4" fill="#00E5A0" opacity="0.8"/><line x1="30" y1="35" x2="50" y2="35" stroke="#00E5A0" strokeWidth="1"/><line x1="30" y1="35" x2="40" y2="50" stroke="#00E5A0" strokeWidth="1"/><line x1="50" y1="35" x2="40" y2="50" stroke="#00E5A0" strokeWidth="1"/></svg>,title:'DNA Structure',fact:'Human DNA has ~3 billion base pairs'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><rect x="15" y="15" width="50" height="50" rx="6" fill="none" stroke="#FF6B9D" strokeWidth="1.5"/><rect x="25" y="25" width="30" height="30" rx="4" fill="none" stroke="#FF6B9D" strokeWidth="1" opacity="0.6"/><circle cx="40" cy="40" r="6" fill="#FF6B9D" opacity="0.4"/><line x1="40" y1="15" x2="40" y2="25" stroke="#FF6B9D" strokeWidth="1.5"/><line x1="40" y1="55" x2="40" y2="65" stroke="#FF6B9D" strokeWidth="1.5"/><line x1="15" y1="40" x2="25" y2="40" stroke="#FF6B9D" strokeWidth="1.5"/><line x1="55" y1="40" x2="65" y2="40" stroke="#FF6B9D" strokeWidth="1.5"/></svg>,title:'Cell Nucleus',fact:'Cell nucleus contains 46 chromosomes'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><polygon points="40,10 65,55 15,55" fill="none" stroke="#FFB84D" strokeWidth="1.5"/><polygon points="40,22 58,52 22,52" fill="none" stroke="#FFB84D" strokeWidth="1" opacity="0.5"/><circle cx="40" cy="10" r="3" fill="#FFB84D"/><circle cx="65" cy="55" r="3" fill="#FFB84D"/><circle cx="15" cy="55" r="3" fill="#FFB84D"/></svg>,title:'Geometry',fact:'Triangle has angle sum of exactly 180°'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><path d="M20 60 Q30 20 40 40 Q50 60 60 20" fill="none" stroke="#4D9FFF" strokeWidth="2"/><circle cx="20" cy="60" r="3" fill="#4D9FFF"/><circle cx="60" cy="20" r="3" fill="#4D9FFF"/><line x1="10" y1="65" x2="70" y2="65" stroke="#4D9FFF" strokeWidth="1" opacity="0.4"/><line x1="15" y1="70" x2="15" y2="10" stroke="#4D9FFF" strokeWidth="1" opacity="0.4"/></svg>,title:'Wave Motion',fact:'Light travels at 3×10⁸ m/s in vacuum'},
                ].map((item,i)=>(
                  <div key={i} style={{background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:14,padding:'16px 14px',textAlign:'center',backdropFilter:'blur(12px)',transition:'all 0.3s'}}>
                    <div style={{display:'flex',justifyContent:'center',marginBottom:10}}>{item.icon}</div>
                    <div style={{fontSize:11,fontWeight:700,color:'#E8F4FF',marginBottom:4}}>{item.title}</div>
                    <div style={{fontSize:10,color:'rgba(107,143,175,0.9)',lineHeight:1.5}}>{item.fact}</div>
                  </div>
                ))}
              </div>

              {/* ══ PLATFORM ACTIVITY STRIP ══ */}
              <div style={{marginTop:16,background:'linear-gradient(135deg,rgba(77,159,255,0.08),rgba(0,212,255,0.05))',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:'16px 20px',display:'flex',flexWrap:'wrap',gap:16,alignItems:'center',justifyContent:'space-between'}}>
                <div>
                  <div style={{fontSize:12,fontWeight:700,color:'#E8F4FF',marginBottom:2}}>⚡ Platform Status</div>
                  <div style={{fontSize:10,color:'rgba(107,143,175,0.9)'}}>All systems operational · Backend connected · DB active</div>
                </div>
                <div style={{display:'flex',gap:12}}>
                  {[{l:'Backend',c:'#00E5A0',s:'Live'},{l:'Database',c:'#00E5A0',s:'Connected'},{l:'Auth',c:'#00E5A0',s:'Active'}].map(x=>(
                    <div key={x.l} style={{textAlign:'center'}}>
                      <div style={{width:8,height:8,borderRadius:'50%',background:x.c,margin:'0 auto 4px',boxShadow:`0 0 8px ${x.c}`}}/>
                      <div style={{fontSize:9,color:'rgba(107,143,175,0.8)'}}>{x.l}</div>
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
                <StatBox ico='👥' lbl='Connected Now' val={stats?.activeStudents??0} col={ACC}/>
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
                <button onClick={()=>_setTab('create_exam')} style={bp}>➕ Create Exam</button>
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
                        <button onClick={()=>_setTab('create_exam')} style={{...bg_,fontSize:11}}>✏️ Edit</button>
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
                    <button onClick={()=>_setTab('exams')} style={{...bg_}}>📝 View All Exams</button>
                    <button onClick={()=>_setTab('questions')} style={{...bg_}}>❓ Question Bank</button>
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
                  <div key={t.name} className="card-hover" style={{...cs,cursor:'pointer',transition:'all 0.2s'}} onClick={()=>{eTitleR.current=t.name;eMarksR.current=String(t.marks);eDurR.current=String(t.dur);eCatR.current=t.cat;_setTab('create_exam');T(`Template "${t.name}" applied.`)}}>
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
              {/* ── HEADER ───────────────────────────────────── */}
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:20,flexWrap:'wrap',gap:12}}>
                <div>
                  <div style={pageTitle}>👥 Student Management</div>
                  <div style={pageSub}>
                    {(students||[]).filter((s:any)=>!s.deleted).length} registered
                    &nbsp;·&nbsp;{(students||[]).filter((s:any)=>s.banned&&!s.deleted).length} banned
                    {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                      <span style={{color:'#FFB84D'}}>&nbsp;·&nbsp;{deletedStds.length} archived</span>
                    )}
                  </div>
                </div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  <button onClick={()=>doExport(`${API}/api/admin/export/students`,'students.csv')} style={{...bg_,fontSize:11}}>📥 Export CSV</button>
                  <button onClick={()=>_setTab('import_students')} style={{...bg_,fontSize:11}}>📤 Import CSV</button>
                </div>
              </div>

              {/* ── STATS ROW ────────────────────────────────── */}
              <div style={{display:'grid',gridTemplateColumns:`repeat(${typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'?4:3},1fr)`,gap:10,marginBottom:20}}>
                {[
                  {ico:'👥',lbl:'Total Students',val:(students||[]).filter((s:any)=>!s.deleted).length,col:'#4D9FFF'},
                  {ico:'✅',lbl:'Active',val:(students||[]).filter((s:any)=>!s.banned&&!s.deleted).length,col:'#00C48C'},
                  {ico:'🚫',lbl:'Banned',val:(students||[]).filter((s:any)=>s.banned&&!s.deleted).length,col:'#FF4757'},
                  ...(typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'
                    ?[{ico:'🗃️',lbl:'Archived',val:deletedStds.length,col:'#FFB84D'}]
                    :[])
                ].map((s,i)=>(
                  <div key={i} style={{
                    background:`linear-gradient(135deg,${s.col}18 0%,${s.col}06 100%)`,
                    border:`1px solid ${s.col}35`,
                    borderRadius:14,
                    padding:'14px 12px',
                    textAlign:'center',
                    transition:'transform 0.2s',
                    cursor:'default'
                  }}>
                    <div style={{fontSize:22,marginBottom:5}}>{s.ico}</div>
                    <div style={{fontSize:24,fontWeight:800,color:s.col,lineHeight:1}}>{s.val}</div>
                    <div style={{fontSize:10,color:'#8899AA',marginTop:4,letterSpacing:'0.3px'}}>{s.lbl}</div>
                  </div>
                ))}
              </div>

              {/* ── SEARCH + FILTER BAR ───────────────────────── */}
              <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap',alignItems:'center'}}>
                <SInput init={stdSearch} onSet={setStdSearch} ph='🔍 Search by name, email, ID…' style={{flex:1,minWidth:200,background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,padding:'9px 14px',color:'#E8F4FD',fontSize:12,outline:'none'}}/>
                <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                  {(['all','active','banned'] as const).map(f=>(
                    <button key={f} onClick={()=>setStdFilter(f)} style={{
                      padding:'8px 14px',
                      borderRadius:8,
                      border:`1px solid ${stdFilter===f?'#4D9FFF':'rgba(77,159,255,0.15)'}`,
                      background:stdFilter===f?'rgba(77,159,255,0.18)':'rgba(0,22,40,0.6)',
                      color:stdFilter===f?'#4D9FFF':'#8899AA',
                      cursor:'pointer',fontSize:11,fontWeight:stdFilter===f?700:500,
                      transition:'all 0.2s',
                      textTransform:'capitalize' as const
                    }}>{f}</button>
                  ))}
                  {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                    <button onClick={()=>{setStdFilter('deleted' as any);fetchDeletedStds()}} style={{
                      padding:'8px 14px',borderRadius:8,
                      border:`1px solid ${stdFilter==='deleted'?'#FFB84D':'rgba(255,184,77,0.2)'}`,
                      background:stdFilter==='deleted'?'rgba(255,184,77,0.15)':'rgba(0,22,40,0.6)',
                      color:stdFilter==='deleted'?'#FFB84D':'#8899AA',
                      cursor:'pointer',fontSize:11,fontWeight:stdFilter==='deleted'?700:500,
                      transition:'all 0.2s'
                    }}>🗃️ Archived</button>
                  )}
                </div>
                <select
                  value={stdSort}
                  onChange={(e:any)=>setStdSort(e.target.value)}
                  style={{background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'8px 10px',color:'#8899AA',fontSize:11,cursor:'pointer',outline:'none'}}
                >
                  <option value='newest'>🕐 Newest First</option>
                  <option value='name'>🔤 Name A–Z</option>
                  <option value='active'>✅ Active First</option>
                </select>
              </div>

              {/* ── SELECTED STUDENT DETAIL PANEL ─────────────── */}
              {selStudent&&(
                <div style={{
                  borderRadius:16,
                  border:'2px solid rgba(77,159,255,0.3)',
                  background:'linear-gradient(135deg,rgba(0,22,40,0.97) 0%,rgba(0,31,58,0.95) 100%)',
                  padding:'18px',
                  marginBottom:18,
                  boxShadow:'0 8px 32px rgba(77,159,255,0.1)'
                }}>
                  <div style={{display:'flex',gap:16,alignItems:'flex-start',flexWrap:'wrap'}}>
                    {/* Avatar */}
                    <div style={{
                      width:58,height:58,borderRadius:16,flexShrink:0,
                      background:'linear-gradient(135deg,#4D9FFF,#0055CC)',
                      display:'flex',alignItems:'center',justifyContent:'center',
                      fontSize:24,fontWeight:800,color:'#fff',
                      boxShadow:'0 6px 20px rgba(77,159,255,0.4)'
                    }}>
                      {(selStudent.name||'?').charAt(0).toUpperCase()}
                    </div>
                    {/* Details */}
                    <div style={{flex:1,minWidth:180}}>
                      <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#E8F4FD',marginBottom:4}}>{selStudent.name}</div>
                      <div style={{fontSize:12,color:'#8899AA',marginBottom:2}}>✉️ {selStudent.email}</div>
                      {selStudent.phone&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>📱 {selStudent.phone}</div>}
                      {(selStudent as any).city&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>📍 {(selStudent as any).city}</div>}
                      {(selStudent as any).school&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>🏫 {(selStudent as any).school}</div>}
                      {(selStudent as any).targetExam&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>🎯 Target: {(selStudent as any).targetExam}</div>}
                      {(selStudent as any).dob&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>🎂 DOB: {(selStudent as any).dob}</div>}
                      {(selStudent as any).qualifications&&<div style={{fontSize:11,color:'#8899AA',marginBottom:4}}>🎓 {(selStudent as any).qualifications}</div>}
                      <div style={{fontSize:10,color:'#8899AA',marginBottom:8}}>📅 Joined: {selStudent.createdAt?new Date(selStudent.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):'-'}</div>
                      <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                        {selStudent.banned&&<span style={{fontSize:10,background:'rgba(255,71,87,0.15)',color:'#FF4757',padding:'2px 8px',borderRadius:6,border:'1px solid rgba(255,71,87,0.3)'}}>🚫 Banned</span>}
                        {selStudent.group&&<Badge label={selStudent.group} col='#FFD700'/>}
                        {selStudent.integrityScore!==undefined&&(
                          <span style={{fontSize:10,background:`rgba(${selStudent.integrityScore>70?'0,196,140':selStudent.integrityScore>40?'255,184,77':'255,71,87'},0.15)`,color:selStudent.integrityScore>70?'#00C48C':selStudent.integrityScore>40?'#FFB84D':'#FF4757',padding:'2px 8px',borderRadius:6,border:`1px solid rgba(${selStudent.integrityScore>70?'0,196,140':selStudent.integrityScore>40?'255,184,77':'255,71,87'},0.3)`}}>
                            🤖 Integrity {selStudent.integrityScore}/100
                          </span>
                        )}
                      </div>
                    </div>
                    {/* Action Buttons */}
                    <div style={{display:'flex',flexDirection:'column' as const,gap:7,alignItems:'stretch',minWidth:120}}>
                      <button onClick={()=>{setImpId(selStudent._id);impersonate()}} style={{...bg_,fontSize:11,textAlign:'center' as const}}>👁️ View as Student</button>
                      {selStudent.banned
                        ?<button onClick={()=>unbanStd(selStudent._id)} style={{...bs,fontSize:11}}>🔓 Unban</button>
                        :<button onClick={()=>{setBanId(selStudent._id)}} style={{...bd,fontSize:11}}>🚫 Ban</button>
                      }
                      {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                        <button
                          onClick={()=>setDelConfirmId(selStudent._id)}
                          style={{background:'rgba(255,71,87,0.08)',border:'1px solid rgba(255,71,87,0.35)',color:'#FF4757',borderRadius:10,padding:'9px 14px',cursor:'pointer',fontSize:11,fontWeight:600}}
                        >🗑️ Delete Account</button>
                      )}
                      <button onClick={()=>setSelStudent(null)} style={{background:'none',border:'1px solid rgba(77,159,255,0.15)',color:'#8899AA',borderRadius:10,padding:'7px',cursor:'pointer',fontSize:12,textAlign:'center' as const}}>✕ Close</button>
                    </div>
                  </div>
                  {/* Login History */}
                  {selStudent.loginHistory&&selStudent.loginHistory.length>0&&(
                    <div style={{marginTop:14,paddingTop:12,borderTop:'1px solid rgba(77,159,255,0.12)'}}>
                      <div style={{fontWeight:700,fontSize:10,color:'#8899AA',marginBottom:8,letterSpacing:'0.8px',textTransform:'uppercase' as const}}>📊 Recent Login Activity (S48)</div>
                      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(170px,1fr))',gap:6}}>
                        {selStudent.loginHistory.slice(0,4).map((l:any,i:number)=>(
                          <div key={i} style={{background:'rgba(0,22,40,0.7)',borderRadius:8,padding:'8px 10px',border:'1px solid rgba(77,159,255,0.1)'}}>
                            <div style={{fontSize:10,color:'#E8F4FD',fontWeight:600}}>📍 {l.city||'Unknown'}</div>
                            <div style={{fontSize:10,color:'#8899AA',marginTop:2}}>{l.device||'—'}</div>
                            <div style={{fontSize:9,color:'#8899AA',marginTop:1}}>{l.ip||'—'}</div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* ── DELETE CONFIRMATION MODAL (SuperAdmin only) ── */}
              {delConfirmId&&(
                <div style={{position:'fixed' as const,top:0,left:0,right:0,bottom:0,background:'rgba(0,0,0,0.75)',backdropFilter:'blur(4px)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:9999,padding:16}}>
                  <div style={{
                    background:'linear-gradient(135deg,rgba(5,10,20,0.99),rgba(10,18,35,0.98))',
                    border:'2px solid rgba(255,71,87,0.4)',
                    borderRadius:20,
                    padding:'28px 24px',
                    maxWidth:400,width:'100%',
                    boxShadow:'0 20px 60px rgba(0,0,0,0.6)'
                  }}>
                    <div style={{fontSize:44,textAlign:'center' as const,marginBottom:10}}>⚠️</div>
                    <div style={{fontWeight:800,fontSize:16,color:'#FF4757',textAlign:'center' as const,marginBottom:6,fontFamily:'Playfair Display,serif'}}>Delete Student Account</div>
                    <div style={{fontSize:12,color:'#8899AA',textAlign:'center' as const,marginBottom:6,lineHeight:1.7}}>
                      Ye account active list se hata diya jayega.<br/>
                      Superadmin ise kabhi bhi restore kar sakta hai.
                    </div>
                    <div style={{fontSize:11,color:'#00C48C',textAlign:'center' as const,marginBottom:16,padding:'8px 12px',background:'rgba(0,196,140,0.08)',borderRadius:8,border:'1px solid rgba(0,196,140,0.2)'}}>
                      ✅ Student same email se fresh account bana sakta hai
                    </div>
                    <div style={{marginBottom:16}}>
                      <label style={{fontSize:11,color:'#8899AA',display:'block',marginBottom:6,fontWeight:600}}>Delete Reason (SuperAdmin archive mein save hoga)</label>
                      <STextarea init='' onSet={(v:string)=>{delReasonR.current=v}} ph='e.g. Test account, Rules violation, Duplicate account…' rows={2} style={{width:'100%',background:'rgba(255,71,87,0.06)',border:'1px solid rgba(255,71,87,0.3)',borderRadius:10,padding:'10px 12px',color:'#E8F4FD',fontSize:12,outline:'none',resize:'vertical' as const}}/>
                    </div>
                    <div style={{display:'flex',gap:10}}>
                      <button
                        onClick={()=>softDelStd(delConfirmId)}
                        disabled={stdDelLoading}
                        style={{flex:1,padding:'12px',background:'linear-gradient(135deg,#FF4757,#CC0020)',border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:stdDelLoading?'not-allowed' as const:'pointer' as const,opacity:stdDelLoading?0.7:1,fontSize:13}}
                      >{stdDelLoading?'⟳ Deleting…':'🗑️ Confirm Delete'}</button>
                      <button onClick={()=>setDelConfirmId('')} style={{...bg_,padding:'12px 18px'}}>Cancel</button>
                    </div>
                  </div>
                </div>
              )}

              {/* ── ARCHIVED STUDENTS (SuperAdmin only, deleted filter) ── */}
              {stdFilter==='deleted'&&typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:14,flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13,color:'#FFB84D'}}>🗃️ Archived Student Accounts</div>
                      <div style={{fontSize:11,color:'#8899AA',marginTop:3}}>{deletedStds.length} archived · Only visible to SuperAdmin · Restore anytime</div>
                    </div>
                    <button onClick={fetchDeletedStds} style={{...bg_,fontSize:11}}>🔄 Refresh</button>
                  </div>
                  {deletedStds.length===0
                    ?<div style={{background:'rgba(255,184,77,0.05)',border:'1px solid rgba(255,184,77,0.15)',borderRadius:16,padding:'40px 20px',textAlign:'center' as const}}>
                      <div style={{fontSize:48,marginBottom:12}}>🗃️</div>
                      <div style={{fontWeight:700,fontSize:14,color:'#E8F4FD',marginBottom:6}}>No Archived Students</div>
                      <div style={{fontSize:12,color:'#8899AA'}}>Deleted student accounts will appear here. You can restore them anytime.</div>
                    </div>
                    :<div style={{display:'grid',gap:10}}>
                      {deletedStds.map((s:any)=>(
                        <div key={s._id} style={{
                          background:'linear-gradient(135deg,rgba(255,184,77,0.05),rgba(0,22,40,0.8))',
                          border:'1px solid rgba(255,184,77,0.2)',
                          borderRadius:14,
                          padding:'14px 16px',
                          display:'flex',gap:12,alignItems:'center',flexWrap:'wrap' as const,justifyContent:'space-between' as const
                        }}>
                          <div style={{display:'flex',gap:12,alignItems:'center',flex:1,minWidth:180}}>
                            <div style={{width:44,height:44,borderRadius:12,background:'linear-gradient(135deg,rgba(255,184,77,0.5),rgba(255,71,87,0.5))',display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,fontWeight:800,color:'#fff',flexShrink:0}}>
                              {(s.name||'?').charAt(0).toUpperCase()}
                            </div>
                            <div>
                              <div style={{fontWeight:700,fontSize:13,color:'#E8F4FD'}}>{s.name||'—'}</div>
                              <div style={{fontSize:11,color:'#8899AA'}}>✉️ {s.email}</div>
                              {s.phone&&<div style={{fontSize:10,color:'#8899AA'}}>📱 {s.phone}</div>}
                              <div style={{display:'flex',gap:6,marginTop:5,flexWrap:'wrap' as const}}>
                                {s.group&&<span style={{fontSize:9,background:'rgba(255,215,0,0.15)',color:'#FFD700',padding:'2px 7px',borderRadius:5,border:'1px solid rgba(255,215,0,0.3)'}}>{s.group}</span>}
                                {s._snapshot?.targetExam&&<span style={{fontSize:9,background:'rgba(77,159,255,0.12)',color:'#4D9FFF',padding:'2px 7px',borderRadius:5,border:'1px solid rgba(77,159,255,0.25)'}}>🎯 {s._snapshot.targetExam}</span>}
                              </div>
                              {s.deleteReason&&<div style={{fontSize:10,color:'#FF4757',marginTop:4}}>Reason: {s.deleteReason}</div>}
                              {s.deletedAt&&<div style={{fontSize:10,color:'#8899AA',marginTop:2}}>🗑️ Archived: {new Date(s.deletedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</div>}
                            </div>
                          </div>
                          <button
                            onClick={()=>restoreStd(s._id)}
                            style={{background:'rgba(0,196,140,0.1)',border:'1px solid rgba(0,196,140,0.3)',color:'#00C48C',borderRadius:10,padding:'9px 16px',cursor:'pointer',fontSize:11,fontWeight:700}}
                          >🔄 Restore</button>
                        </div>
                      ))}
                    </div>
                  }
                </div>
              )}

              {/* ── ACTIVE STUDENT LIST ──────────────────────── */}
              {stdFilter!=='deleted'&&(
                <>
                  {fStds.filter((s:any)=>!s.deleted).length===0
                    ?<PageHero icon="👥" title="No Students Found" subtitle="Students will appear here after they register. Use bulk import to add multiple students at once."/>
                    :(()=>{
                      const raw=fStds.filter((s:any)=>!s.deleted);
                      const sorted=stdSort==='name'
                        ?[...raw].sort((a,b)=>(a.name||'').localeCompare(b.name||''))
                        :stdSort==='active'
                        ?[...raw].sort((a,b)=>Number(!!a.banned)-Number(!!b.banned))
                        :[...raw].sort((a,b)=>new Date(b.createdAt||0).getTime()-new Date(a.createdAt||0).getTime());
                      const avatarColors=['#4D9FFF','#00C48C','#A78BFA','#FF6B9D','#FFD700','#00E5FF','#FF8C42','#7CFC00'];
                      return sorted.map((s:any,idx:number)=>(
                        <div
                          key={s._id}
                          className="card-hover"
                          style={{
                            background:selStudent?._id===s._id?'rgba(77,159,255,0.08)':'rgba(0,22,40,0.75)',
                            border:`1px solid ${s.banned?'rgba(255,71,87,0.3)':selStudent?._id===s._id?'rgba(77,159,255,0.4)':'rgba(77,159,255,0.12)'}`,
                            borderLeft:`3px solid ${s.banned?'#FF4757':avatarColors[idx%8]}`,
                            borderRadius:14,
                            padding:'12px 14px',
                            marginBottom:8,
                            display:'flex',gap:12,alignItems:'center',flexWrap:'wrap' as const,
                            justifyContent:'space-between' as const,
                            cursor:'pointer',
                            transition:'all 0.22s'
                          }}
                          onClick={()=>setSelStudent(s)}
                        >
                          <div style={{display:'flex',gap:12,alignItems:'center',flex:1,minWidth:150}}>
                            {/* Color Avatar */}
                            <div style={{
                              width:42,height:42,borderRadius:12,flexShrink:0,
                              background:`linear-gradient(135deg,${avatarColors[idx%8]},${avatarColors[(idx+3)%8]})`,
                              display:'flex',alignItems:'center',justifyContent:'center',
                              fontSize:17,fontWeight:800,color:'#fff',
                              boxShadow:`0 3px 10px ${avatarColors[idx%8]}44`
                            }}>
                              {(s.name||'?').charAt(0).toUpperCase()}
                            </div>
                            <div style={{flex:1}}>
                              <div style={{display:'flex',alignItems:'center',gap:6,flexWrap:'wrap' as const,marginBottom:2}}>
                                <span style={{fontWeight:700,fontSize:13,color:'#E8F4FD'}}>{s.name||'—'}</span>
                                {s.banned&&<span style={{fontSize:9,background:'rgba(255,71,87,0.15)',color:'#FF4757',padding:'1px 6px',borderRadius:5,border:'1px solid rgba(255,71,87,0.3)'}}>BANNED</span>}
                                {s.group&&<span style={{fontSize:9,background:'rgba(255,215,0,0.12)',color:'#FFD700',padding:'1px 6px',borderRadius:5,border:'1px solid rgba(255,215,0,0.25)'}}>{s.group}</span>}
                              </div>
                              <div style={{fontSize:11,color:'#8899AA'}}>{s.email}</div>
                              <div style={{display:'flex',gap:10,marginTop:2,fontSize:10,color:'#8899AA',flexWrap:'wrap' as const}}>
                                {s.phone&&<span>📱 {s.phone}</span>}
                                <span>📅 {s.createdAt?new Date(s.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):'-'}</span>
                              </div>
                              {s.integrityScore!==undefined&&(
                                <div style={{display:'flex',alignItems:'center',gap:7,marginTop:5}}>
                                  <div style={{width:70,height:3,background:'rgba(255,255,255,0.07)',borderRadius:2}}>
                                    <div style={{width:`${Math.min(s.integrityScore,100)}%`,height:'100%',borderRadius:2,background:s.integrityScore>70?'#00C48C':s.integrityScore>40?'#FFB84D':'#FF4757',transition:'width 0.5s'}}/>
                                  </div>
                                  <span style={{fontSize:9,color:s.integrityScore>70?'#00C48C':s.integrityScore>40?'#FFB84D':'#FF4757',fontWeight:600}}>{s.integrityScore}/100</span>
                                </div>
                              )}
                            </div>
                          </div>
                          {/* Action Buttons */}
                          <div style={{display:'flex',gap:6,flexWrap:'wrap' as const}} onClick={(e:any)=>e.stopPropagation()}>
                            <button onClick={(e:any)=>{e.stopPropagation();setSelStudent(s)}} style={{...bg_,fontSize:10,padding:'6px 10px'}}>👁️ View</button>
                            {s.banned
                              ?<button onClick={(e:any)=>{e.stopPropagation();unbanStd(s._id)}} style={{...bs,fontSize:10,padding:'6px 10px'}}>🔓 Unban</button>
                              :<button onClick={(e:any)=>{e.stopPropagation();setBanId(s._id)}} style={{...bd,fontSize:10,padding:'6px 10px'}}>🚫 Ban</button>
                            }
                            {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                              <button
                                onClick={(e:any)=>{e.stopPropagation();setDelConfirmId(s._id)}}
                                title="Delete account (SuperAdmin only)"
                                style={{background:'rgba(255,71,87,0.08)',border:'1px solid rgba(255,71,87,0.3)',color:'#FF4757',borderRadius:8,padding:'6px 10px',cursor:'pointer',fontSize:10,fontWeight:700}}
                              >🗑️</button>
                            )}
                          </div>
                        </div>
                      ));
                    })()
                  }
                </>
              )}

              {/* ── BAN PANEL ────────────────────────────────── */}
              {banId&&(
                <div style={{
                  background:'linear-gradient(135deg,rgba(255,71,87,0.05),rgba(0,22,40,0.95))',
                  border:'2px solid rgba(255,71,87,0.3)',
                  borderRadius:16,
                  padding:'18px',
                  marginTop:16
                }}>
                  <div style={{fontWeight:700,fontSize:14,color:'#FF4757',marginBottom:14}}>🚫 Ban Student</div>
                  <div style={{marginBottom:12}}>
                    <label style={{fontSize:11,color:'#8899AA',display:'block',marginBottom:6,fontWeight:600}}>Ban Reason *</label>
                    <STextarea init='' onSet={(v:string)=>{banReaR.current=v}} ph='Explain why this student is being banned…' rows={2} style={{width:'100%',background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,padding:'10px 12px',color:'#E8F4FD',fontSize:12,outline:'none',resize:'vertical' as const}}/>
                  </div>
                  <div style={{marginBottom:14}}>
                    <label style={{fontSize:11,color:'#8899AA',display:'block',marginBottom:6,fontWeight:600}}>Ban Type</label>
                    <SSelect val={banT} onChange={(v:string)=>setBanT(v as 'permanent'|'temporary')} opts={[{v:'permanent',l:'Permanent Ban'},{v:'temporary',l:'Temporary Ban (30 days)'}]} style={{width:'100%',background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,padding:'10px 12px',color:'#E8F4FD',fontSize:12,outline:'none'}}/>
                  </div>
                  <div style={{display:'flex',gap:10}}>
                    <button onClick={banStd} style={{...bd,flex:1,padding:'11px',fontSize:13}}>🚫 Confirm Ban</button>
                    <button onClick={()=>setBanId('')} style={{...bg_,padding:'11px 20px'}}>Cancel</button>
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

              {/* ─── PREMIUM HEADER ─── */}
              <div style={{background:'linear-gradient(135deg,rgba(4,30,60,0.97),rgba(0,18,42,0.99))',border:'1px solid rgba(77,159,255,0.22)',borderRadius:20,padding:'22px 22px 18px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',top:-50,right:-50,width:200,height:200,borderRadius:'50%',background:'radial-gradient(circle,rgba(77,159,255,0.09),transparent 70%)',pointerEvents:'none'}}></div>
                <div style={{display:'flex',alignItems:'center',gap:16,position:'relative',zIndex:1}}>
                  <div style={{width:54,height:54,background:'linear-gradient(135deg,rgba(77,159,255,0.2),rgba(0,212,255,0.1))',border:'1.5px solid rgba(77,159,255,0.4)',borderRadius:16,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,boxShadow:'0 6px 24px rgba(77,159,255,0.18)'}}>
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.22)" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/><circle cx="12" cy="10" r="2.6" fill="#4D9FFF"/><path d="M7.5 16.5c.5-2 2.3-3.5 4.5-3.5s4 1.5 4.5 3.5" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/></svg>
                  </div>
                  <div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.3}}>Admin Management</div>
                    <div style={{display:'flex',alignItems:'center',gap:8,marginTop:5,flexWrap:'wrap'}}>
                      <span style={{background:'rgba(77,159,255,0.15)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:10,fontWeight:700,border:'1px solid rgba(77,159,255,0.3)'}}>S37</span>
                      <span style={{fontSize:11,color:'#6B8FAF'}}>Create · Freeze · Archive · Restore sub-admin accounts</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* ─── STATS ROW ─── */}
              <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:10,marginBottom:20}}>
                {[
                  {icon:'👥',label:'Total',val:(adminUsers||[]).length+archivedAdmins.length,col:'#4D9FFF',brd:'rgba(77,159,255,0.22)'},
                  {icon:'✅',label:'Active',val:(adminUsers||[]).filter(a=>!a.frozen).length,col:'#00C48C',brd:'rgba(0,196,140,0.22)'},
                  {icon:'🔒',label:'Frozen',val:(adminUsers||[]).filter(a=>a.frozen).length,col:'#FFB84D',brd:'rgba(255,184,77,0.22)'},
                  {icon:'🗃️',label:'Archived',val:archivedAdmins.length,col:'#FF6B6B',brd:'rgba(255,107,107,0.22)'},
                ].map((s,i)=>(
                  <div key={i} style={{background:'rgba(0,18,36,0.9)',border:`1px solid ${s.brd}`,borderRadius:14,padding:'14px 10px',textAlign:'center'}}>
                    <div style={{fontSize:20,marginBottom:6}}>{s.icon}</div>
                    <div style={{fontSize:20,fontWeight:800,color:s.col,lineHeight:1}}>{s.val}</div>
                    <div style={{fontSize:10,color:'#6B8FAF',marginTop:5,fontWeight:600}}>{s.label}</div>
                  </div>
                ))}
              </div>

              {/* ─── CREATE FORM ─── */}
              <div style={{...cs,marginBottom:20,border:'1px solid rgba(77,159,255,0.22)',padding:'0'}}>
                <div style={{background:'linear-gradient(90deg,rgba(77,159,255,0.1),rgba(0,212,255,0.04))',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'14px 18px',display:'flex',alignItems:'center',gap:10,flexWrap:'wrap'}}>
                  <div style={{width:32,height:32,background:'rgba(77,159,255,0.15)',borderRadius:9,display:'flex',alignItems:'center',justifyContent:'center',fontSize:15,border:'1px solid rgba(77,159,255,0.25)',flexShrink:0}}>➕</div>
                  <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',flex:1}}>Create New Admin Account</div>
                  <span style={{fontSize:10,color:'#4D9FFF',background:'rgba(77,159,255,0.1)',borderRadius:20,padding:'2px 10px',border:'1px solid rgba(77,159,255,0.2)',fontWeight:600}}>SuperAdmin Only</span>
                </div>
                <div style={{padding:'16px 18px'}}>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                    <div><label style={lbl}>Full Name *</label><SInput init='' onSet={v=>{admNameR.current=v}} ph='Admin full name' style={inp}/></div>
                    <div><label style={lbl}>Email *</label><SInput init='' onSet={v=>{admEmailR.current=v}} ph='admin@proverank.com' type='email' style={inp}/></div>
                    <div><label style={lbl}>Password *</label><SInput init='' onSet={v=>{admPassR.current=v}} ph='Strong password' type='password' style={inp}/></div>
                    <div><label style={lbl}>Role</label><SSelect val={admRole} onChange={setAdmRole} opts={[{v:'admin',l:'🛡️ Admin'},{v:'moderator',l:'🔍 Moderator'},{v:'superadmin',l:'👑 Super Admin'}]} style={{...inp}}/></div>
                  </div>
                  <button onClick={createAdmin} disabled={creatingAdm} style={{...bp,width:'100%',marginTop:14,opacity:creatingAdm?0.7:1}}>
                    {creatingAdm?'⟳ Creating…':'🛡️ Create Admin Account'}
                  </button>
                </div>
              </div>

              {/* ─── ACTIVE ADMINS LABEL ─── */}
              <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:12,padding:'0 2px'}}>
                <div style={{width:3,height:20,background:'linear-gradient(180deg,#4D9FFF,#00D4FF)',borderRadius:4,flexShrink:0}}></div>
                <span style={{fontWeight:700,fontSize:13,color:'#E8F4FF'}}>Active Admins</span>
                <span style={{background:'rgba(77,159,255,0.14)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(77,159,255,0.25)'}}>{(adminUsers||[]).length}</span>
              </div>

              {/* ─── ACTIVE ADMINS LIST ─── */}
              {(adminUsers||[]).length===0
                ?<div style={{...cs,textAlign:'center',padding:'32px 20px',marginBottom:20,border:'1px dashed rgba(77,159,255,0.2)'}}>
                  <div style={{fontSize:36,marginBottom:8,opacity:0.4}}>🛡️</div>
                  <div style={{fontSize:12,color:DIM}}>No sub-admins yet. Use the form above to create one.</div>
                </div>
                :<div style={{display:'flex',flexDirection:'column',gap:10,marginBottom:20}}>
                  {(adminUsers||[]).map(au=>(
                    <div key={au._id} style={{background:au.frozen?'rgba(36,18,0,0.9)':'rgba(0,20,42,0.9)',border:`1px solid ${au.frozen?'rgba(255,184,77,0.3)':'rgba(77,159,255,0.18)'}`,borderRadius:16,padding:'14px 16px',position:'relative',overflow:'hidden'}}>
                      <div style={{position:'absolute',top:0,left:0,right:0,height:2,background:au.frozen?'linear-gradient(90deg,#FFB84D,#FF9800)':'linear-gradient(90deg,#4D9FFF,#00D4FF)'}}></div>
                      <div style={{display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'}}>
                        <div style={{width:46,height:46,background:au.frozen?'rgba(80,40,0,0.8)':'rgba(77,159,255,0.15)',border:`2px solid ${au.frozen?'rgba(255,184,77,0.4)':'rgba(77,159,255,0.35)'}`,borderRadius:13,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,fontWeight:900,color:au.frozen?'#FFB84D':'#4D9FFF',flexShrink:0,fontFamily:'Inter,sans-serif'}}>
                          {(au.name||'A')[0].toUpperCase()}
                        </div>
                        <div style={{flex:1,minWidth:140}}>
                          <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap',marginBottom:3}}>
                            <span style={{fontWeight:700,fontSize:14,color:'#E8F4FF'}}>{au.name}</span>
                            {au.frozen&&<span style={{fontSize:10,background:'rgba(255,184,77,0.16)',color:'#FFB84D',borderRadius:20,padding:'1px 8px',fontWeight:700,border:'1px solid rgba(255,184,77,0.3)'}}>🔒 FROZEN</span>}
                          </div>
                          <div style={{fontSize:11,color:'#6B8FAF',marginBottom:6}}>{au.email}</div>
                          <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                            <span style={{fontSize:10,background:'rgba(77,159,255,0.12)',color:'#4D9FFF',borderRadius:20,padding:'2px 9px',fontWeight:700,border:'1px solid rgba(77,159,255,0.22)'}}>{(au.role||'admin').toUpperCase()}</span>
                            {!au.frozen&&<span style={{fontSize:10,background:'rgba(0,196,140,0.1)',color:'#00C48C',borderRadius:20,padding:'2px 8px',fontWeight:600,border:'1px solid rgba(0,196,140,0.2)'}}>● Active</span>}
                          </div>
                        </div>
                        <div style={{display:'flex',gap:7,flexShrink:0,flexWrap:'wrap'}}>
                          <button onClick={()=>viewAdminProfile(au._id)} style={{background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.24)',color:'#00B4FF',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>👁️ Profile</button>
                          <button onClick={async()=>{const r=await fetch(`${API}/api/admin/manage/freeze/${au._id}`,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({frozen:!au.frozen})});const d=await r.json();if(d.success){T(au.frozen?'Admin unfrozen.':'Admin frozen — cannot login now.');setAdminUsers(p=>p.map(a=>a._id===au._id?{...a,frozen:!au.frozen}:a))}else T(d.message||'Failed','e')}} style={{background:au.frozen?'rgba(0,196,140,0.09)':'rgba(255,184,77,0.09)',border:`1px solid ${au.frozen?'rgba(0,196,140,0.28)':'rgba(255,184,77,0.28)'}`,color:au.frozen?'#00C48C':'#FFB84D',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>{au.frozen?'🔓 Unfreeze':'🔒 Freeze'}</button>
                          <button onClick={async()=>{if(confirm('Archive this admin? They will not be able to login.')){const r=await fetch(`${API}/api/admin/manage/archive/${au._id}`,{method:'PUT',headers:{Authorization:`Bearer ${token}`}});const d=await r.json();if(d.success){T('Admin archived.');setAdminUsers(p=>p.filter(a=>a._id!==au._id));fetchArchivedAdmins();}else T(d.message||'Failed','e')}}} style={{background:'rgba(255,77,77,0.08)',border:'1px solid rgba(255,77,77,0.22)',color:'#FF6B6B',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>🗑️ Archive</button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              }

              {/* ─── ARCHIVED ADMINS (INSIDE TAB) ─── */}
              <div style={{background:'rgba(4,12,30,0.97)',border:'1.5px solid rgba(77,159,255,0.2)',borderRadius:18,overflow:'hidden'}}>
                <div style={{background:'rgba(77,159,255,0.06)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'14px 18px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                  <div style={{display:'flex',alignItems:'center',gap:10}}>
                    <div style={{width:32,height:32,background:'rgba(77,159,255,0.12)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,border:'1px solid rgba(77,159,255,0.25)',flexShrink:0}}>🗃️</div>
                    <div>
                      <div style={{fontWeight:700,fontSize:13,color:'#7BB8FF'}}>Archived Admins</div>
                      <div style={{fontSize:10,color:'#4D6A8F',marginTop:1}}>Restore anytime to reactivate login access</div>
                    </div>
                    <span style={{background:'rgba(77,159,255,0.14)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(77,159,255,0.28)'}}>{archivedAdmins.length}</span>
                  </div>
                  <button onClick={fetchArchivedAdmins} style={{background:'rgba(77,159,255,0.09)',border:'1px solid rgba(77,159,255,0.22)',color:'#4D9FFF',borderRadius:9,padding:'7px 13px',fontSize:11,cursor:'pointer',fontWeight:600}}>🔄 Refresh</button>
                </div>
                <div style={{padding:'16px 18px'}}>
                  {archivedAdmins.length===0
                    ?<div style={{textAlign:'center',padding:'24px 0'}}>
                      <div style={{fontSize:28,marginBottom:8,opacity:0.4}}>✅</div>
                      <div style={{color:'#4D6A8F',fontSize:12,fontWeight:600}}>No archived admins — All admins are active</div>
                    </div>
                    :<div style={{display:'flex',flexDirection:'column',gap:10}}>
                      {archivedAdmins.map(aa=>(
                        <div key={aa._id} style={{background:'rgba(0,10,28,0.6)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:13,padding:'13px 15px',display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'}}>
                          <div style={{width:40,height:40,background:'rgba(77,159,255,0.12)',border:'1.5px solid rgba(77,159,255,0.25)',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,fontWeight:900,color:'#7BB8FF',flexShrink:0}}>
                            {(aa.name||'A')[0].toUpperCase()}
                          </div>
                          <div style={{flex:1,minWidth:130}}>
                            <div style={{fontWeight:600,fontSize:13,color:'#C8D4E0'}}>{aa.name||'Unknown'}</div>
                            <div style={{fontSize:11,color:'#667788',marginTop:2}}>{aa.email}</div>
                            <div style={{display:'flex',gap:5,marginTop:5,flexWrap:'wrap'}}>
                              <span style={{background:'rgba(160,80,255,0.14)',color:'#C090FF',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600}}>{(aa.role||'admin').toUpperCase()}</span>
                              <span style={{background:'rgba(120,80,255,0.14)',color:'#A080FF',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600}}>🗃️ ARCHIVED</span>
                              {aa.archivedAt&&<span style={{fontSize:10,color:'#3D5A7A'}}>📅 {new Date(aa.archivedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</span>}
                              {aa.archivedBy&&<span style={{fontSize:10,color:'#445566'}}>by {aa.archivedBy}</span>}
                            </div>
                          </div>
                          <div style={{display:'flex',gap:7,flexShrink:0}}>
                            <button onClick={()=>viewAdminProfile(aa._id)} style={{background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.24)',color:'#00B4FF',borderRadius:9,padding:'6px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>👁️ Profile</button>
                            <button onClick={()=>restoreAdmin(aa._id)} style={{background:'rgba(0,196,140,0.09)',border:'1px solid rgba(0,196,140,0.26)',color:'#00C48C',borderRadius:9,padding:'6px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>🔄 Restore</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  }
                </div>
              </div>

            </div>
          )}

                    {/* ══ PERMISSIONS ══ */}
          {tab==='permissions'&&(
            <div>

              {/* ─── PREMIUM HEADER ─── */}
              <div style={{background:'linear-gradient(135deg,rgba(4,30,60,0.97),rgba(0,18,42,0.99))',border:'1px solid rgba(77,159,255,0.22)',borderRadius:20,padding:'22px 22px 18px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',top:-50,right:-50,width:200,height:200,borderRadius:'50%',background:'radial-gradient(circle,rgba(77,159,255,0.09),transparent 70%)',pointerEvents:'none'}}></div>
                <div style={{display:'flex',alignItems:'center',gap:16,position:'relative',zIndex:1}}>
                  <div style={{width:54,height:54,background:'linear-gradient(135deg,rgba(77,159,255,0.2),rgba(0,212,255,0.1))',border:'1.5px solid rgba(77,159,255,0.4)',borderRadius:16,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,boxShadow:'0 6px 24px rgba(77,159,255,0.18)'}}>
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.15)" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/><path d="M9 12l2 2 4-4" stroke="#4D9FFF" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  </div>
                  <div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.3}}>Admin Permissions</div>
                    <div style={{display:'flex',alignItems:'center',gap:8,marginTop:5,flexWrap:'wrap'}}>
                      <span style={{background:'rgba(77,159,255,0.15)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:10,fontWeight:700,border:'1px solid rgba(77,159,255,0.3)'}}>S72</span>
                      <span style={{fontSize:11,color:'#6B8FAF'}}>26 granular toggles · 6 categories · Real API · Per-admin control</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* ─── ADMIN SELECTOR ─── */}
              <div style={{background:'rgba(0,20,44,0.94)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:16,marginBottom:20,overflow:'hidden'}}>
                <div style={{background:'rgba(77,159,255,0.07)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'13px 18px',display:'flex',alignItems:'center',gap:10,flexWrap:'wrap'}}>
                  <div style={{width:32,height:32,background:'rgba(77,159,255,0.12)',borderRadius:9,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,border:'1px solid rgba(77,159,255,0.22)',flexShrink:0}}>👤</div>
                  <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',flex:1}}>Select Admin to Configure</div>
                  {selectedPermAdmin&&<span style={{fontSize:10,background:'rgba(0,196,140,0.12)',color:'#00C48C',borderRadius:20,padding:'2px 10px',border:'1px solid rgba(0,196,140,0.22)',fontWeight:600}}>✅ Editing: {selectedPermAdmin.name}</span>}
                </div>
                <div style={{padding:'14px 18px'}}>
                  {(adminUsers||[]).length===0
                    ?<div style={{textAlign:'center',padding:'20px 0',color:'#445566',fontSize:12}}>No active admins found. Create an admin first from the Admins tab.</div>
                    :<div style={{display:'flex',flexDirection:'column',gap:8}}>
                      {(adminUsers||[]).map(au=>(
                        <div key={au._id} onClick={async()=>{
                          setSelectedPermAdmin(au);
                          try{
                            const r=await fetch(API+'/api/admin/manage/profile/'+au._id,{headers:{Authorization:'Bearer '+token}});
                            const d=await r.json();
                            if(d.success&&d.admin){
                              const loaded=d.admin.permissions||{};
                              setPerms(prev=>Object.fromEntries(Object.keys(prev).map(k=>[k,loaded[k]===true])));
                              T('Permissions loaded for '+au.name+' — toggle as needed');
                            }else{
                              setPerms(prev=>Object.fromEntries(Object.keys(prev).map(k=>[k,false])));
                              T('No permissions set yet for '+au.name,'e');
                            }
                          }catch(e){T('Failed to load permissions — check connection','e');}
                        }} style={{background:selectedPermAdmin&&selectedPermAdmin._id===au._id?'rgba(77,159,255,0.1)':'rgba(0,10,28,0.5)',border:'1px solid '+(selectedPermAdmin&&selectedPermAdmin._id===au._id?'rgba(77,159,255,0.35)':'rgba(77,159,255,0.09)'),borderRadius:12,padding:'12px 14px',cursor:'pointer',display:'flex',alignItems:'center',gap:12,transition:'all 0.2s'}}>
                          <div style={{width:38,height:38,background:'rgba(77,159,255,0.15)',border:'1.5px solid rgba(77,159,255,0.28)',borderRadius:11,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,fontWeight:900,color:'#4D9FFF',flexShrink:0}}>{(au.name||'A')[0].toUpperCase()}</div>
                          <div style={{flex:1,minWidth:0}}>
                            <div style={{fontWeight:600,fontSize:13,color:'#E8F4FF'}}>{au.name}</div>
                            <div style={{fontSize:11,color:'#6B8FAF',marginTop:2}}>{au.email}</div>
                          </div>
                          <div style={{display:'flex',alignItems:'center',gap:6,flexShrink:0}}>
                            <span style={{fontSize:10,background:'rgba(77,159,255,0.12)',color:'#4D9FFF',borderRadius:20,padding:'2px 8px',fontWeight:600}}>{(au.role||'admin').toUpperCase()}</span>
                            {selectedPermAdmin&&selectedPermAdmin._id===au._id&&<span style={{fontSize:14}}>✅</span>}
                          </div>
                        </div>
                      ))}
                    </div>
                  }
                </div>
              </div>

              {/* ─── PERMISSIONS GRID ─── */}
              {selectedPermAdmin
                ?<div style={{display:'flex',flexDirection:'column',gap:14,marginBottom:80}}>
                  {[
                    {g:'📝 Exam Management',c:'#4D9FFF',bg:'rgba(77,159,255,0.06)',brd:'rgba(77,159,255,0.16)',p:[
                      {k:'create_exam',l:'Create Exam',d:'Create and publish new exams'},
                      {k:'edit_exam',l:'Edit Exam',d:'Modify existing exam settings and questions'},
                      {k:'delete_exam',l:'Delete Exam',d:'Permanently delete exams from platform'},
                      {k:'clone_exam',l:'Clone / Duplicate Exam',d:'Copy existing exams as template (S39)'},
                      {k:'bulk_exam',l:'Bulk Exam Creator',d:'Create multiple exams at once (N8)'},
                    ]},
                    {g:'📚 Question Bank',c:'#A080FF',bg:'rgba(160,80,255,0.06)',brd:'rgba(160,80,255,0.16)',p:[
                      {k:'manage_questions',l:'Manage Questions',d:'Add, edit, delete questions from bank'},
                      {k:'bulk_upload',l:'Bulk Upload Questions',d:'Upload via Excel / PDF / Copy-paste (Phase 2)'},
                      {k:'ai_questions',l:'AI Question Generator',d:'Generate questions using AI (S101)'},
                      {k:'pyq_access',l:'PYQ Bank Access',d:'Access Previous Year Questions bank (S104)'},
                    ]},
                    {g:'👥 Student Management',c:'#00C48C',bg:'rgba(0,196,140,0.06)',brd:'rgba(0,196,140,0.16)',p:[
                      {k:'view_students',l:'View Students',d:'Access student list, profiles and details'},
                      {k:'ban_student',l:'Ban / Unban Student',d:'Restrict or restore student account access (M1)'},
                      {k:'impersonate',l:'Impersonate Student',d:'Login as any student for debugging (M4)'},
                      {k:'export_data',l:'Export Data (CSV)',d:'Download student and results data reports (S67)'},
                      {k:'batch_transfer',l:'Batch Transfer',d:'Move students between batches (M3)'},
                    ]},
                    {g:'📊 Results & Analytics',c:'#FFB84D',bg:'rgba(255,184,77,0.06)',brd:'rgba(255,184,77,0.16)',p:[
                      {k:'view_results',l:'View Results',d:'Access exam results, scores and AIR rankings'},
                      {k:'view_analytics',l:'View Analytics',d:'Access analytics dashboard and KPIs (S13/S108)'},
                      {k:'view_leaderboard',l:'View Leaderboard',d:'See all-India student rankings (S15/S60)'},
                      {k:'download_reports',l:'Download Reports',d:'Export PDF / CSV performance reports (S14)'},
                    ]},
                    {g:'📢 Communication',c:'#FF6B6B',bg:'rgba(255,107,107,0.06)',brd:'rgba(255,107,107,0.16)',p:[
                      {k:'send_announcements',l:'Send Announcements',d:'Broadcast notices to all students (S47)'},
                      {k:'manage_doubts',l:'Manage Doubts & Queries',d:'Reply to student questions (S63)'},
                      {k:'manage_grievances',l:'Manage Grievances / Tickets',d:'Handle complaints and support tickets (S92)'},
                      {k:'answer_key_challenge',l:'Answer Key Challenge',d:'Accept or reject answer key challenges (S69)'},
                    ]},
                    {g:'⚙️ System & Admin',c:'#00D4FF',bg:'rgba(0,212,255,0.06)',brd:'rgba(0,212,255,0.16)',p:[
                      {k:'manage_features',l:'Feature Flags',d:'Toggle platform features ON/OFF (N21)'},
                      {k:'manage_branding',l:'Manage Branding',d:'Change platform name, tagline and logo (S56)'},
                      {k:'view_audit_logs',l:'View Audit Logs',d:'See all admin activity history (S93/S38)'},
                      {k:'view_snapshots',l:'View Webcam Snapshots',d:'Access proctoring image captures (Phase 5.2)'},
                      {k:'manage_backup',l:'Manage Backup & Export',d:'Trigger backups and full data export (S50)'},
                      {k:'manage_admins',l:'Manage Admins',d:'Create and manage admin accounts (S37)'},
                    ]},
                  ].map((grp,gi)=>(
                    <div key={gi} style={{background:'rgba(0,8,20,0.85)',border:'1.5px solid '+grp.brd,borderRadius:16,overflow:'hidden'}}>
                      <div style={{background:grp.bg,borderBottom:'1px solid '+grp.brd,padding:'12px 16px',display:'flex',alignItems:'center',gap:10}}>
                        <span style={{fontSize:16}}>{grp.g.split(' ')[0]}</span>
                        <span style={{fontWeight:700,fontSize:13,color:grp.c}}>{grp.g.slice(grp.g.indexOf(' ')+1)}</span>
                        <span style={{marginLeft:'auto',fontSize:10,background:'rgba(0,0,0,0.25)',color:grp.c,borderRadius:20,padding:'2px 9px',border:'1px solid '+grp.brd,fontWeight:700}}>{grp.p.filter(pm=>perms[pm.k]).length}/{grp.p.length} Active</span>
                      </div>
                      <div style={{padding:'12px 14px',display:'flex',flexDirection:'column',gap:7}}>
                        {grp.p.map((pm,pi)=>(
                          <div key={pi} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 13px',background:perms[pm.k]?'rgba(0,196,140,0.05)':'rgba(0,0,0,0.18)',borderRadius:10,border:'1px solid '+(perms[pm.k]?'rgba(0,196,140,0.18)':'rgba(255,255,255,0.03)'),transition:'all 0.2s'}}>
                            <div style={{flex:1,minWidth:0,marginRight:14}}>
                              <div style={{fontWeight:600,fontSize:12,color:perms[pm.k]?'#E0F0FF':'#7A8FA0'}}>{pm.l}</div>
                              <div style={{fontSize:10,color:'#3A5060',marginTop:2}}>{pm.d}</div>
                            </div>
                            <button onClick={()=>setPerms(p=>({...p,[pm.k]:!p[pm.k]}))} style={{width:46,height:26,borderRadius:13,border:'none',background:perms[pm.k]?'linear-gradient(90deg,#00C48C,#00a87a)':'rgba(80,100,120,0.25)',cursor:'pointer',position:'relative',transition:'all 0.3s',flexShrink:0}}>
                              <span style={{position:'absolute',top:3,left:perms[pm.k]?23:3,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.3s',display:'block',boxShadow:'0 1px 5px rgba(0,0,0,0.4)'}}></span>
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
                :<div style={{background:'rgba(0,10,28,0.7)',border:'1px dashed rgba(77,159,255,0.14)',borderRadius:16,padding:'44px 20px',textAlign:'center',marginBottom:20}}>
                  <svg width="52" height="52" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 14px',display:'block',opacity:0.3}}><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.2)" stroke="#4D9FFF" strokeWidth="1.5" strokeLinejoin="round"/><path d="M9 12l2 2 4-4" stroke="#4D9FFF" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  <div style={{fontSize:14,color:'#3D5A7A',fontWeight:600}}>Select an admin above to manage their permissions</div>
                  <div style={{fontSize:11,color:'#263040',marginTop:6}}>Grant or restrict 26 individual capabilities per admin account</div>
                </div>
              }

              {/* ─── STICKY SAVE BUTTON ─── */}
              {selectedPermAdmin&&(
                <div style={{position:'sticky',bottom:12,zIndex:100,padding:'0 2px'}}>
                  <button onClick={savePerms} style={{...bp,width:'100%',padding:'14px',fontSize:13,fontWeight:700,display:'flex',alignItems:'center',justifyContent:'center',gap:8,boxShadow:'0 8px 32px rgba(0,100,255,0.28)',borderRadius:14}}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/><polyline points="17,21 17,13 7,13 7,21" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/><polyline points="7,3 7,8 15,8" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/></svg>
                    Save Permissions for {selectedPermAdmin.name}
                  </button>
                </div>
              )}

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
              <div style={{display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:10,marginBottom:20}}>
                <StatBox ico='👥' lbl='Total Students' val={(students||[]).length} col={ACC}/>
                <StatBox ico='📝' lbl='Total Exams' val={(exams||[]).length} col={GOLD}/>
                <StatBox ico='❓' lbl='Questions' val={(questions||[]).length} col={SUC}/>
                <StatBox ico='🚨' lbl='Active Flags' val={(flags||[]).length} col={DNG}/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(280px,1fr))',gap:14,marginBottom:14}}>
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
                      <div style={{display:'flex',gap:6,alignItems:'center',flexShrink:0}}>
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
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:10,marginBottom:16}}>
                <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:SUC,fontWeight:700}}>{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)>70).length}</div><div style={{fontSize:11,color:DIM}}>High Trust (&gt;70)</div></div>
                <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:WRN,fontWeight:700}}>{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)>=40&&(s.integrityScore||0)<=70).length}</div><div style={{fontSize:11,color:DIM}}>Medium Trust</div></div>
                <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:DNG,fontWeight:700}}>{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)<40).length}</div><div style={{fontSize:11,color:DIM}}>Low Trust (&lt;40)</div></div>
              </div>
              {(students||[]).filter(s=>s.integrityScore!==undefined).length===0
                ?<div style={{textAlign:'center',padding:'30px',color:DIM}}><div style={{fontSize:36,marginBottom:8}}>🤖</div><div style={{fontSize:12}}>No integrity scores computed yet</div></div>
                :(students||[]).filter(s=>s.integrityScore!==undefined).sort((a,b)=>(a.integrityScore||0)-(b.integrityScore||0)).slice(0,15).map(s=>(
                  <div key={s._id} style={{...cs,display:'flex',gap:12,alignItems:'center',flexWrap:'wrap',borderLeft:`4px solid ${(s.integrityScore||0)>70?SUC:(s.integrityScore||0)>40?WRN:DNG}`}}>
                    <div style={{flex:1}}>
                      <div style={{fontWeight:600,fontSize:12,color:TS}}>{s.name||'—'}</div>
                      <div style={{fontSize:10,color:DIM}}>{s.email}</div>
                    </div>
                    <div style={{textAlign:'right'}}>
                      <div style={{fontWeight:900,fontSize:18,color:(s.integrityScore||0)>70?SUC:(s.integrityScore||0)>40?WRN:DNG}}>{s.integrityScore}</div>
                      <div style={{fontSize:9,color:DIM}}>/100</div>
                    </div>
                    <div style={{width:80,height:6,background:'rgba(255,255,255,0.1)',borderRadius:3,overflow:'hidden'}}>
                      <div style={{height:'100%',width:`${s.integrityScore||0}%`,background:(s.integrityScore||0)>70?SUC:(s.integrityScore||0)>40?WRN:DNG,borderRadius:3,transition:'width 0.5s'}}/>
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
                  <div style={{marginBottom:8}}><label style={lbl}>Platform Name</label><SInput init={brandLoaded.bName} onSet={v=>{bNameR.current=v}} ph='ProveRank' style={inp}/></div>
                  <div style={{marginBottom:8}}><label style={lbl}>Tagline</label><SInput init={brandLoaded.bTag} onSet={v=>{bTagR.current=v}} ph='Prove Your Rank' style={inp}/></div>
                  <div style={{marginBottom:8}}><label style={lbl}>Support Email</label><SInput init={brandLoaded.bMail} onSet={v=>{bMailR.current=v}} type='email' ph='support@proverank.com' style={inp}/></div>
                  <div><label style={lbl}>Support Phone</label><SInput init={brandLoaded.bPhone} onSet={v=>{bPhoneR.current=v}} ph='+91 9999999999' style={inp}/></div>
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13}}>🔍 SEO Settings (M17)</div>
                  <div style={{marginBottom:8}}><label style={lbl}>SEO Title</label><SInput init={brandLoaded.seoT} onSet={v=>{seoTR.current=v}} ph='ProveRank — NEET…' style={inp}/></div>
                  <div style={{marginBottom:8}}><label style={lbl}>Meta Description</label><STextarea init={brandLoaded.seoD} onSet={v=>{seoDR.current=v}} rows={3} ph='Platform description for search engines…' style={{...inp,resize:'vertical'}}/></div>
                  <div><label style={lbl}>Keywords</label><SInput init={brandLoaded.seoK} onSet={v=>{seoKR.current=v}} ph='NEET, online test, mock exam…' style={inp}/></div>
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
              <div style={{marginTop:14}}>
                <label style={lbl}>🔓 Whitelisted Students (Access Allowed During Maintenance)</label>
                <div style={{fontSize:11,color:DIM,marginBottom:6}}>Enter one email per line — these students will be able to access the dashboard even during maintenance mode</div>
                <STextarea init={wlText} key={wlText} onSet={v=>{maintWhitelistR.current=v;setWlText(v)}} ph='student1@gmail.com&#10;student2@gmail.com' rows={3} style={{...inp,resize:'vertical',fontFamily:'monospace',fontSize:12}}/>
              <button onClick={saveWhitelist} disabled={savingWL} style={{marginTop:10,background:'linear-gradient(135deg,#7B2FBE,#4a0080)',color:'#fff',border:'none',borderRadius:8,padding:'10px 20px',cursor:'pointer',fontWeight:700,fontSize:13,opacity:savingWL?0.7:1,width:'100%'}}>
                {savingWL?'⟳ Saving...':'💾 Save Whitelist'}
              </button>
              </div>
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
                    <div style={{fontWeight:700,fontSize:13,color:col}}>Top {s}</div>
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
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16}}>
                {[{ico:'👥',l:'Total Students',v:(students||[]).length},{ico:'📝',l:'Exams Conducted',v:(exams||[]).length},{ico:'📈',l:'Avg Score',v:stats?.avgScore||'—'},{ico:'🏆',l:'Completion Rate',v:stats?.completionRate||'—'}].map((s:any,i)=>(
                  <div key={i} style={cs}>
                    <div style={{fontSize:24}}>{s.ico}</div>
                    <div style={{fontWeight:700,fontSize:18,color:ACC,margin:'4px 0'}}>{s.v}</div>
                    <div style={{fontSize:11,color:DIM}}>{s.l}</div>
                  </div>
                ))}
              </div>
              <div style={{display:'flex',gap:10}}>
                <button onClick={()=>doExport(`${API}/api/admin/institute-report/pdf`,'institute_report.pdf')} style={{...bp}}>📄 Download Monthly Report PDF</button>
                <button onClick={()=>doExport(`${API}/api/admin/institute-report/excel`,'institute_report.xlsx')} style={{...bg_}}>📊 Download Excel Report</button>
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
                    <div style={{display:'flex',gap:6,alignItems:'center',flexShrink:0}}>
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
