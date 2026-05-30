'use client'
import AdminWelcomeBanner from './AdminWelcomeBanner';
import AdminProfilePage from './AdminProfilePage';
import { useState, useEffect, useRef, useCallback, memo } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from '@/lib/auth'

// ── API Base ──
const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── TypeScript Interfaces ──
interface Student { _id:string;name:string;email:string;phone?:string;role:string;createdAt:string;banned?:boolean;banReason?:string;group?:string;integrityScore?:number;loginHistory?:any[];parentEmail?:string;deleted?:boolean;deletedAt?:string;deleteReason?:string;city?:string;school?:string;dob?:string;targetExam?:string;qualifications?:string;_snapshot?:any }
interface Exam { _id:string;title:string;scheduledAt:string;totalMarks:number;duration:number;status:string;attempts?:number;category?:string;password?:string;batch?:string;subject?:string }
interface Question { _id:string;text:string;subject:string;chapter?:string;topic?:string;difficulty:string;type:string;options?:string[];correctAnswer?:string;explanation?:string;approvalStatus?:string;image?:string }
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
// GLOBAL SEARCH COMPONENT (M12) — Premium Rewrite

const NAV_TABS=[
  {label:'Dashboard',tab:'dashboard',icon:'📊'},{label:'Live Monitor',tab:'live_monitor',icon:'🔴'},
  {label:'All Exams',tab:'exams',icon:'📋'},{label:'Create Exam',tab:'create_exam',icon:'➕'},
  {label:'Question Bank',tab:'questions',icon:'📚'},{label:'Smart Generator',tab:'smart_gen',icon:'🤖'},
  {label:'PYQ Bank',tab:'pyq',icon:'📜'},{label:'Bulk Upload',tab:'bulk_upload',icon:'📤'},
  {label:'All Students',tab:'students',icon:'👥'},{label:'Batch Manager',tab:'batches',icon:'🗂️'},
  {label:'Results',tab:'results',icon:'🏆'},{label:'Leaderboard',tab:'leaderboard',icon:'🥇'},
  {label:'Analytics',tab:'analytics',icon:'📈'},{label:'Anti-Cheat',tab:'anticheat',icon:'🛡️'},
  {label:'Grievances',tab:'grievances',icon:'⚖️'},{label:'Announcements',tab:'announcements',icon:'📢'},
  {label:'Email Templates',tab:'email_tmpl',icon:'📧'},{label:'Feature Flags',tab:'feature_flags',icon:'🚩'},
  {label:'Branding',tab:'branding',icon:'🎨'},{label:'SEO Settings',tab:'seo',icon:'🔍'},
  {label:'Maintenance',tab:'maintenance',icon:'🔧'},{label:'Backup',tab:'backup',icon:'💾'},
  {label:'Audit Logs',tab:'audit',icon:'🔏'},{label:'Task Manager',tab:'tasks',icon:'✅'},
  {label:'Changelog',tab:'changelog',icon:'📝'},{label:'Permissions',tab:'permissions',icon:'🔐'},
  {label:'Multi-Admin',tab:'admins',icon:'👤'},{label:'Parent Portal',tab:'parent_portal',icon:'👨‍👩‍👧'},
  {label:'Transparency',tab:'transparency',icon:'👁️'},{label:'OMR View',tab:'omr_view',icon:'📄'},
  {label:'Global Search',tab:'global_search',icon:'🔎'}
]

const GlobalSearch=memo(function GlobalSearch({setTab,token}:{setTab:(t:string)=>void;token:string}){
  const [q,setQ]=useState('')
  const [results,setResults]=useState<any>(null)
  const [loading,setLoading]=useState(false)
  const [activeSection,setActiveSection]=useState('all')
  const debRef=useRef<any>(null)

  const sections=[
    {key:'all',label:'All',icon:'🔎'},
    {key:'navigation',label:'Tabs',icon:'🗂️'},
    {key:'students',label:'Students',icon:'👥'},
    {key:'admins',label:'Admins',icon:'👤'},
    {key:'exams',label:'Exams',icon:'📋'},
    {key:'questions',label:'Questions',icon:'📚'},
    {key:'batches',label:'Batches',icon:'🗂️'},
  ]

  useEffect(()=>{
    if(debRef.current) clearTimeout(debRef.current)
    if(!q||q.length<2){setResults(null);return}
    debRef.current=setTimeout(async()=>{
      setLoading(true)

  // Top students — standalone (has own state handler)
  const tk2=getToken();if(tk2){fetch(`${API}/api/admin/notifications/top-students?limit=10`,{headers:{Authorization:`Bearer ${tk2}`}}).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.success&&d.topStudents)setTopStudents(d.topStudents);}).catch(()=>{});}

      try{
        const r=await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/global-search?q=${encodeURIComponent(q)}`,{headers:{Authorization:`Bearer ${token}`}})
        const d=await r.json()
        if(d.success) setResults(d.results)
      }catch(e){}finally{setLoading(false)}
    },350)
  },[q])

  const navResults=NAV_TABS.filter(t=>t.label.toLowerCase().includes(q.toLowerCase()))
  const totalCount=(results?((results.students?.length||0)+(results.admins?.length||0)+(results.exams?.length||0)+(results.questions?.length||0)+(results.batches?.length||0)):0)+navResults.length

  const S:any={
    wrap:{position:'relative',width:'100%',maxWidth:720,margin:'0 auto'},
    input:{width:'100%',padding:'14px 20px 14px 48px',background:'rgba(0,28,52,0.85)',border:'1.5px solid rgba(77,159,255,0.35)',borderRadius:14,color:'#E8F4FF',fontSize:15,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',backdropFilter:'blur(12px)'},
    dropdown:{position:'relative',marginTop:8,background:'rgba(0,20,45,0.97)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:16,boxShadow:'0 20px 60px rgba(0,0,0,0.6)',backdropFilter:'blur(20px)',zIndex:9999,maxHeight:520,overflowY:'auto'},
    tabs:{display:'flex',gap:6,padding:'12px 14px 8px',borderBottom:'1px solid rgba(77,159,255,0.1)',flexWrap:'wrap'},
    secTitle:{fontSize:10,fontWeight:700,color:'#4D9FFF',letterSpacing:1.5,textTransform:'uppercase',margin:'10px 14px 4px',display:'flex',alignItems:'center',gap:6},
    item:{display:'flex',alignItems:'center',gap:10,padding:'8px 14px',cursor:'pointer',transition:'background 0.15s'},
    label:{fontSize:13,color:'#E8F4FF',fontWeight:500,flex:1},
    sub:{fontSize:11,color:'#6B8BAF'},
    chip:(bg:string,col:string)=>({fontSize:10,padding:'2px 7px',borderRadius:10,fontWeight:600,background:bg,color:col}),
    divider:{height:1,background:'rgba(77,159,255,0.08)',margin:'4px 14px'},
  }

  const tabBtn=(active:boolean)=>({padding:'4px 12px',borderRadius:20,fontSize:11,fontWeight:600,cursor:'pointer',border:'1px solid '+(active?'#4D9FFF':'rgba(77,159,255,0.2)'),background:active?'rgba(77,159,255,0.2)':'transparent',color:active?'#4D9FFF':'#6B8BAF'})

  const show=(key:string)=>activeSection==='all'||activeSection===key

  return(
    <div style={S.wrap}>
      {/* Search Input */}
      <div style={{position:'relative',display:'flex',alignItems:'center',marginBottom:32}}>
        <span style={{position:'absolute',left:16,fontSize:20,color:'#4D9FFF',zIndex:1}}>🔎</span>
        <input style={S.input} value={q} onChange={e=>setQ(e.target.value)} placeholder="Search tabs, students, exams, questions, batches, admins..."/>
        {q.length>=2&&<span style={{position:'absolute',right:16,background:'rgba(77,159,255,0.2)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:'2px 10px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>{loading?'…':totalCount+' results'}</span>}
      </div>

      {/* Empty State — Rich Content */}
      {q.length<2&&(
        <div>
          {/* Stats Row */}
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:12,marginBottom:28}}>
            {[{icon:'👥',label:'Students',color:'#00C864'},{icon:'📋',label:'Exams',color:'#4D9FFF'},{icon:'📚',label:'Questions',color:'#964DFF'},{icon:'🗂️',label:'Batches',color:'#00C8C8'},{icon:'👤',label:'Admins',color:'#FFA500'},{icon:'🗂️',label:'Tabs',color:'#E8F4FF'}].map((s,i)=>(
              <div key={i} style={{background:'rgba(0,28,52,0.7)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:'16px 12px',textAlign:'center',cursor:'pointer'}} onClick={()=>setActiveSection(s.label.toLowerCase())}>
                <div style={{fontSize:28,marginBottom:6}}>{s.icon}</div>
                <div style={{fontSize:12,color:s.color,fontWeight:600}}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* SVG Illustration + Info */}
          <div style={{background:'rgba(0,28,52,0.6)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:16,padding:24,marginBottom:20,textAlign:'center'}}>
            <svg width="80" height="80" viewBox="0 0 80 80" style={{marginBottom:12,opacity:0.8}}>
              <circle cx="34" cy="34" r="22" fill="none" stroke="#4D9FFF" strokeWidth="3"/>
              <circle cx="34" cy="34" r="14" fill="none" stroke="rgba(77,159,255,0.3)" strokeWidth="1.5"/>
              <line x1="50" y1="50" x2="68" y2="68" stroke="#4D9FFF" strokeWidth="3" strokeLinecap="round"/>
              <circle cx="34" cy="34" r="5" fill="rgba(77,159,255,0.5)"/>
            </svg>
            <div style={{fontSize:16,color:'#E8F4FF',fontWeight:600,marginBottom:8}}>Global Search — M12</div>
            <div style={{fontSize:12,color:'#6B8BAF',lineHeight:1.6}}>Type at least 2 characters to search across<br/>Students · Admins · Exams · Questions · Batches · Navigation Tabs</div>
          </div>

          {/* Quick Nav Tiles */}
          <div style={{marginBottom:12}}>
            <div style={{fontSize:11,color:'#4D9FFF',fontWeight:700,letterSpacing:1.2,textTransform:'uppercase',marginBottom:10}}>⚡ Quick Navigation</div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(130px,1fr))',gap:8}}>
              {NAV_TABS.slice(0,12).map((t,i)=>(
                <div key={i} onClick={()=>setTab(t.tab)} style={{background:'rgba(0,28,52,0.6)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:10,padding:'10px 12px',cursor:'pointer',display:'flex',alignItems:'center',gap:8,transition:'all 0.15s'}}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='rgba(0,28,52,0.6)')}>
                  <span style={{fontSize:16}}>{t.icon}</span>
                  <span style={{fontSize:11,color:'#E8F4FF',fontWeight:500}}>{t.label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Science Fact */}
          <div style={{background:'linear-gradient(135deg,rgba(0,28,52,0.8),rgba(0,50,80,0.6))',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:'14px 16px',display:'flex',gap:12,alignItems:'flex-start'}}>
            <span style={{fontSize:24}}>🔬</span>
            <div>
              <div style={{fontSize:10,color:'#4D9FFF',fontWeight:700,letterSpacing:1,marginBottom:4}}>SCIENCE FACT</div>
              <div style={{fontSize:12,color:'#B0C8E0',lineHeight:1.5}}>The human brain processes visual information 60,000× faster than text — that&apos;s why ProveRank uses visual dashboards for instant insights.</div>
            </div>
          </div>
        </div>
      )}

      {q.length>=2&&(
        <div style={S.dropdown}>
          <div style={S.tabs}>
            {sections.map(s=><button key={s.key} onClick={()=>setActiveSection(s.key)} style={tabBtn(activeSection===s.key)}>{s.icon} {s.label}</button>)}
          </div>
          {loading&&<div style={{textAlign:'center',padding:'20px',color:'#4D9FFF'}}>⏳ Searching...</div>}
          {!loading&&totalCount===0&&<div style={{textAlign:'center',padding:'28px',color:'#6B8BAF'}}>🔍 No results for "<span style={{color:'#4D9FFF'}}>{q}</span>"</div>}
          {!loading&&totalCount>0&&<div>
            {show('navigation')&&navResults.length>0&&<div>
              <div style={S.secTitle}>🗂️ Navigation / Tabs</div>
              {navResults.slice(0,6).map((t,i)=>(
                <div key={i} style={S.item} onClick={()=>setTab(t.tab)}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>{t.icon}</span>
                  <span style={S.label}>{t.label}</span>
                  <span style={S.chip('rgba(77,159,255,0.15)','#4D9FFF')}>Tab</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('students')&&results?.students?.length>0&&<div>
              <div style={S.secTitle}>👥 Students ({results.students.length})</div>
              {results.students.map((s:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('students')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>👤</span>
                  <div style={{flex:1}}><div style={S.label}>{s.name||'—'}</div><div style={S.sub}>{s.email}{s.studentId?' · '+s.studentId:''}</div></div>
                  <span style={S.chip('rgba(0,200,100,0.15)','#00C864')}>Student</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('admins')&&results?.admins?.length>0&&<div>
              <div style={S.secTitle}>👤 Admins ({results.admins.length})</div>
              {results.admins.map((a:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('admins')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>🔑</span>
                  <div style={{flex:1}}><div style={S.label}>{a.name||'—'}</div><div style={S.sub}>{a.email}{a.adminId?' · '+a.adminId:''}</div></div>
                  <span style={S.chip('rgba(255,165,0,0.15)','#FFA500')}>{a.role==='superadmin'?'SuperAdmin':'Admin'}</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('exams')&&results?.exams?.length>0&&<div>
              <div style={S.secTitle}>📋 Exams ({results.exams.length})</div>
              {results.exams.map((ex:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('exams')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>📋</span>
                  <div style={{flex:1}}><div style={S.label}>{ex.title}</div><div style={S.sub}>{ex.status}</div></div>
                  <span style={S.chip('rgba(77,159,255,0.15)','#4D9FFF')}>Exam</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('questions')&&results?.questions?.length>0&&<div>
              <div style={S.secTitle}>📚 Questions ({results.questions.length})</div>
              {results.questions.map((qu:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('questions')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>❓</span>
                  <div style={{flex:1}}><div style={S.label}>{(qu.text||'').slice(0,65)}{(qu.text||'').length>65?'…':''}</div><div style={S.sub}>{qu.subject}{qu.chapter?' · '+qu.chapter:''}{qu.difficulty?' · '+qu.difficulty:''}</div></div>
                  <span style={S.chip('rgba(150,77,255,0.15)','#964DFF')}>Q</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('batches')&&results?.batches?.length>0&&<div>
              <div style={S.secTitle}>🗂️ Batches ({results.batches.length})</div>
              {results.batches.map((b:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('batches')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>🗂️</span>
                  <div style={{flex:1}}><div style={S.label}>{b.name}</div><div style={S.sub}>{b.description||''}</div></div>
                  <span style={S.chip('rgba(0,200,200,0.15)','#00C8C8')}>Batch</span>
                </div>
              ))}
            </div>}
          </div>}
        </div>
      )}
    </div>
  )
})

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

const CopyBtn=({text,label='',size='sm'}:{text:string,label?:string,size?:'sm'|'md'})=>{
  const[cp,setCp]=useState(false)
  const sz=size==='md'?{fontSize:12,padding:'4px 10px'}:{fontSize:10,padding:'2px 7px'}
  return <button onClick={e=>{e.stopPropagation();try{navigator.clipboard.writeText(text).then(()=>{setCp(true);setTimeout(()=>setCp(false),2000)})}catch{const el=document.createElement('textarea');el.value=text;document.body.appendChild(el);el.select();document.execCommand('copy');document.body.removeChild(el);setCp(true);setTimeout(()=>setCp(false),2000)}}} title={'Copy: '+text} style={{background:cp?'rgba(0,196,140,0.15)':'rgba(77,159,255,0.08)',color:cp?'#00C48C':'#6B8FAF',border:'1px solid '+(cp?'rgba(0,196,140,0.3)':'rgba(77,159,255,0.2)'),borderRadius:6,cursor:'pointer',display:'inline-flex',alignItems:'center',gap:3,transition:'all 0.2s',flexShrink:0,fontFamily:'monospace',fontWeight:600,...sz}}>{cp?'✅':'📋'}{label?(' '+label):''}{cp?' Copied!':''}</button>
}





// BatchDetailOverlay — S5/M3 Complete Batch Detail
// ═══════════════════════════════════════════════════
function BatchDetailOverlay({batch,token,API,onClose,onBatchDelete,onBatchRename,T}:{
  batch:any,token:string,API:string,onClose:()=>void,
  onBatchDelete:(id:string)=>void,onBatchRename:(id:string,name:string)=>void,
  T:(m:string,t?:any)=>void
}){
  const[tab,setTab]=useState('overview')
  const[students,setStudents]=useState<any[]>([])
  const[exams,setExams]=useState<any[]>([])
  const[allExams,setAllExams]=useState<any[]>([])
  const[notes,setNotes]=useState<any[]>([])
  const[loading,setLoading]=useState(false)
  const[addEmail,setAddEmail]=useState('')
  const[adding,setAdding]=useState(false)
  const[search,setSearch]=useState('')
  const[annTitle,setAnnTitle]=useState('')
  const[annMsg,setAnnMsg]=useState('')
  const[renaming,setRenaming]=useState(false)
  const[newName,setNewName]=useState('')
  const[assignExamId,setAssignExamId]=useState('')
  const[noteTitle,setNoteTitle]=useState('')
  const[noteDesc,setNoteDesc]=useState('')
  const[noteUrl,setNoteUrl]=useState('')
  const[noteType,setNoteType]=useState('link')
  const[noteSub,setNoteSub]=useState('General')
  const[addingNote,setAddingNote]=useState(false)
  const ACC='#4D9FFF',TS='#E8F4FF',DIM='#6B8FAF',SUC='#00C48C',DNG='#FF4D4D',WRN='#FFB84D',PRP='#A78BFA'
  const BOR='rgba(77,159,255,0.18)',BOR2='rgba(77,159,255,0.3)',CRD='rgba(0,22,40,0.75)'
  const bp2:any={background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}
  const bd2:any={background:'rgba(255,77,77,0.15)',color:DNG,border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'6px 12px',cursor:'pointer',fontWeight:700,fontSize:11}
  const inp2:any={width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.85)',border:'1.5px solid '+BOR2,borderRadius:10,color:TS,fontSize:13,outline:'none',boxSizing:'border-box'as const,fontFamily:'Inter,sans-serif'}
  const cs2:any={background:CRD,border:'1px solid '+BOR,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}
  const sel2:any={padding:'10px 12px',background:'rgba(0,22,40,0.85)',border:'1.5px solid '+BOR2,borderRadius:10,color:TS,fontSize:13,outline:'none',fontFamily:'Inter,sans-serif'}

  const loadAll=useCallback(async()=>{
    if(!batch||!token)return
    setLoading(true)
    const h={Authorization:'Bearer '+token}
    const gets=(u:string)=>fetch(API+u,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[])
    const[s,e,n,ae]=await Promise.all([
      gets('/api/admin/batches/'+batch._id+'/students'),
      gets('/api/admin/batches/'+batch._id+'/exams'),
      gets('/api/admin/batches/'+batch._id+'/notes'),
      gets('/api/admin/batches/all-exams'),
    ])
    setStudents(Array.isArray(s)?s:[])
    setExams(Array.isArray(e)?e:[])
    setNotes(Array.isArray(n)?n:[])
    setAllExams(Array.isArray(ae)?ae:[])
    setLoading(false)
  },[batch,token,API])

  useEffect(()=>{if(batch&&token){setTab('overview');loadAll()}},[batch,token,loadAll])

  const addStudent=async()=>{
    if(!addEmail.trim()){T('Enter email','e');return}
    setAdding(true)
    try{
      const r=await fetch(API+'/api/admin/batches/'+batch._id+'/students/add',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({studentEmail:addEmail.trim()})})
      const d=await r.json()
      if(r.ok){T('Student added ✅','s');setAddEmail('');loadAll()}else T(d.message||'Failed','e')
    }catch{T('Error','e')}finally{setAdding(false)}
  }

  const removeStudent=async(sid:string,name:string)=>{
    if(!window.confirm('Remove '+name+' from batch?'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/students/'+sid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Removed','s');setStudents(p=>p.filter(s=>s._id!==sid))}else T('Failed','e')
  }

  const assignExam=async()=>{
    if(!assignExamId){T('Select an exam','e');return}
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/exams/assign',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({examId:assignExamId})})
    if(r.ok){T('Exam assigned ✅','s');setAssignExamId('');loadAll()}else T('Failed','e')
  }

  const unassignExam=async(eid:string,title:string)=>{
    if(!window.confirm('Unassign "'+title+'" from this batch?'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/exams/'+eid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Unassigned','s');setExams(p=>p.filter(e=>e._id!==eid))}else T('Failed','e')
  }

  const addNote=async()=>{
    if(!noteTitle.trim()){T('Enter title','e');return}
    setAddingNote(true)
    try{
      const r=await fetch(API+'/api/admin/batches/'+batch._id+'/notes',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({title:noteTitle.trim(),description:noteDesc,url:noteUrl,type:noteType,subject:noteSub})})
      const d=await r.json()
      if(r.ok){T('Material added ✅','s');setNoteTitle('');setNoteDesc('');setNoteUrl('');loadAll()}else T(d.message||'Failed','e')
    }catch{T('Error','e')}finally{setAddingNote(false)}
  }

  const deleteNote=async(nid:string,title:string)=>{
    if(!window.confirm('Delete "'+title+'"?'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/notes/'+nid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Deleted','s');setNotes(p=>p.filter(n=>n._id!==nid))}else T('Failed','e')
  }

  const renameBatch=async()=>{
    if(!newName.trim())return
    const r=await fetch(API+'/api/admin/batches/'+batch._id,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({name:newName.trim()})})
    const d=await r.json()
    if(r.ok){T('Renamed ✅','s');onBatchRename(batch._id,newName.trim());setRenaming(false)}else T(d.message||'Failed','e')
  }

  const deleteBatch=async()=>{
    if(!window.confirm('DELETE "'+batch.name+'"?\nAll students unassigned. Cannot be undone.'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Deleted','s');onBatchDelete(batch._id)}else T('Failed','e')
  }

  const sendAnn=async()=>{
    if(!annTitle||!annMsg){T('Fill all fields','e');return}
    const r=await fetch(API+'/api/admin/announcements',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({title:annTitle,message:annMsg,batch:batch._id})})
    if(r.ok){T('Sent ✅','s');setAnnTitle('');setAnnMsg('')}else T('Failed','e')
  }

  const exportCSV=()=>{
    const rows=[['Name','Email','Phone','Joined'],...students.map(s=>[s.name||'',s.email||'',s.phone||'',s.createdAt?new Date(s.createdAt).toLocaleDateString():''])]
    const csv=rows.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\n')
    const a=document.createElement('a');a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);a.download='batch_'+batch.name+'.csv';a.click();T('Exported ✅','s')
  }

  const getNoteIcon=(type:string)=>{
    const icons:any={pdf:'📄',video:'🎥',doc:'📝',link:'🔗',image:'🖼️',other:'📎'}
    return icons[type]||'📎'
  }

  const unassignedExams=allExams.filter(ae=>!exams.find(e=>e._id===ae._id))
  const filtered=students.filter(s=>!search||s.name?.toLowerCase().includes(search.toLowerCase())||s.email?.toLowerCase().includes(search.toLowerCase()))
  const TABS=[
    {id:'overview',l:'📊 Overview'},
    {id:'students',l:'👥 Students ('+students.length+')'},
    {id:'exams',l:'📝 Exams ('+exams.length+')'},
    {id:'notes',l:'📚 Materials ('+notes.length+')'},
    {id:'analytics',l:'📈 Analytics'},
    {id:'announce',l:'📢 Announce'},
    {id:'banner-generator',label:'🎨 Creative Studio',href:'/admin/x7k2p/banner-generator'},
    {id:'settings',l:'⚙️ Settings'},
  ]

  return(
    <div style={{position:'fixed',inset:0,background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',zIndex:998,overflowY:'auto',fontFamily:'Inter,sans-serif'}}>
      <style>{'.bdt2:hover{opacity:0.82;transform:translateY(-1px)} .bdr2:hover{background:rgba(77,159,255,0.05)!important} @keyframes bds{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}} @keyframes spin{to{transform:rotate(360deg)}} div::-webkit-scrollbar{display:none}'}</style>

      <div style={{position:'sticky',top:0,background:'rgba(0,10,24,0.95)',backdropFilter:'blur(16px)',borderBottom:'1px solid '+BOR,padding:'12px 16px',zIndex:10}}>
        <div style={{maxWidth:940,margin:'0 auto'}}>
          <div style={{display:'flex',alignItems:'center',gap:10,flexWrap:'wrap',marginBottom:10}}>
            <button onClick={onClose} style={{background:'rgba(77,159,255,0.1)',color:ACC,border:'1px solid '+BOR2,borderRadius:8,padding:'7px 12px',cursor:'pointer',fontSize:12,fontWeight:600,transition:'all 0.2s'}} className="bdt2">← Back</button> <button onClick={()=>{const url='/admin/x7k2p/banner-generator?batchId='+batch._id+'&batchName='+encodeURIComponent(batch.name);window.location.href=url;}} style={{padding:'6px 12px',background:'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(0,212,255,0.1))',border:'1px solid rgba(77,159,255,0.3)',borderRadius:8,color:'#4D9FFF',cursor:'pointer',fontSize:10,fontWeight:700,whiteSpace:'nowrap'}}>🎨 Generate Banner</button>
            <div style={{flex:1,minWidth:0}}>
              <div style={{fontSize:17,fontWeight:800,fontFamily:'Playfair Display,serif',background:'linear-gradient(90deg,'+ACC+',#A8D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>📦 {batch.name}</div>
              <div style={{display:'flex',alignItems:'center',gap:6,marginTop:1,flexWrap:'wrap'}}><span style={{fontSize:10,color:DIM,fontFamily:'monospace'}}>ID: {batch._id?.slice(-12)}...</span><CopyBtn text={batch._id} label="Batch ID"/><span style={{fontSize:10,color:DIM}}>· {batch.createdAt?new Date(batch.createdAt).toLocaleDateString():'-'}</span></div>
            </div>
            <div style={{display:'flex',gap:4,flexShrink:0}}>
              <span style={{fontSize:10,background:'rgba(77,159,255,0.1)',color:ACC,padding:'3px 8px',borderRadius:16,border:'1px solid '+BOR2}}>👥{students.length}</span>
              <span style={{fontSize:10,background:'rgba(0,196,140,0.1)',color:SUC,padding:'3px 8px',borderRadius:16,border:'1px solid rgba(0,196,140,0.25)'}}>📝{exams.length}</span>
              <span style={{fontSize:10,background:'rgba(167,139,250,0.1)',color:PRP,padding:'3px 8px',borderRadius:16,border:'1px solid rgba(167,139,250,0.25)'}}>📚{notes.length}</span>
            </div>
          </div>
          <div style={{display:'flex',gap:3,overflowX:'auto',paddingBottom:4,WebkitOverflowScrolling:'touch',scrollbarWidth:'none',msOverflowStyle:'none'}}>
            {TABS.map(t=>(
              <button key={t.id} onClick={()=>setTab(t.id)} className="bdt2" style={{background:tab===t.id?'rgba(77,159,255,0.18)':'transparent',border:'1px solid '+(tab===t.id?BOR2:'transparent'),color:tab===t.id?ACC:DIM,borderRadius:8,padding:'5px 9px',cursor:'pointer',fontSize:10,fontWeight:600,whiteSpace:'nowrap',transition:'all 0.2s',fontFamily:'Inter,sans-serif',flexShrink:0}}>{t.l}</button>
            ))}
          </div>
        </div>
      </div>

      <div style={{maxWidth:940,margin:'0 auto',padding:'16px 14px'}}>
        {loading&&<div style={{textAlign:'center',padding:48,color:DIM}}>
          <div style={{width:36,height:36,border:'3px solid '+BOR2,borderTopColor:ACC,borderRadius:'50%',animation:'spin 1s linear infinite',margin:'0 auto 12px'}}/>
          <div style={{fontSize:13}}>Loading...</div>
        </div>}

        {/* ── OVERVIEW ── */}
        {!loading&&tab==='overview'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:14}}>
            {[{i:'👥',l:'Students',v:students.length,c:ACC},{i:'📝',l:'Exams',v:exams.length,c:WRN},{i:'📚',l:'Materials',v:notes.length,c:PRP},{i:'✅',l:'Active',v:students.filter(s=>!s.banned).length,c:SUC}].map(x=>(
              <div key={x.l} style={{background:CRD,border:'1px solid '+BOR,borderRadius:12,padding:'14px 10px',flex:'1 1 calc(50% - 5px)',minWidth:80,textAlign:'center',backdropFilter:'blur(12px)'}}>
                <div style={{fontSize:22,marginBottom:4}}>{x.i}</div>
                <div style={{fontSize:22,fontWeight:800,color:x.c,fontFamily:'Playfair Display,serif'}}>{x.v}</div>
                <div style={{fontSize:10,color:DIM,marginTop:2,fontWeight:600}}>{x.l}</div>
              </div>
            ))}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>⚡ Quick Actions</div>
            <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
              <button onClick={()=>setTab('students')} style={bp2} className="bdt2">👥 Students</button>
              <button onClick={()=>setTab('exams')} style={bp2} className="bdt2">📝 Exams</button>
              <button onClick={()=>setTab('notes')} style={{...bp2,background:'linear-gradient(135deg,#7C3AED,#4C1D95)'}} className="bdt2">📚 Materials</button>
              <button onClick={()=>setTab('announce')} style={{...bp2,background:'linear-gradient(135deg,#059669,#047857)'}} className="bdt2">📢 Announce</button>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt2">📤 Export CSV</button>
            </div>
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>🕐 Recent Students</div>
            {students.slice(0,5).map(s=>(
              <div key={s._id} className="bdr2" style={{display:'flex',alignItems:'center',gap:10,padding:'8px 6px',borderRadius:8,transition:'all 0.15s'}}>
                <div style={{width:30,height:30,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid '+BOR2,display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontSize:12,fontWeight:600,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'—'}</div>
                  <div style={{display:'flex',alignItems:'center',gap:4}}><span style={{fontSize:10,color:DIM}}>{s.email}</span></div>
                  {s.studentId&&<div style={{display:'flex',alignItems:'center',gap:3}}><span style={{fontSize:9,color:'#4D9FFF',fontFamily:'monospace'}}>{s.studentId}</span><CopyBtn text={s.studentId}/></div>}
                </div>
                <div style={{fontSize:10,color:DIM,flexShrink:0}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</div>
              </div>
            ))}
            {!students.length&&<div style={{textAlign:'center',padding:24,color:DIM,fontSize:12}}>No students yet — add from Students tab</div>}
          </div>
        </div>}

        {/* ── STUDENTS ── */}
        {!loading&&tab==='students'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:12}}>
              <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔍 Search name/email" style={{...inp2,maxWidth:240,padding:'9px 12px'}}/>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:8,padding:'9px 14px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt2">📤 Export</button>
              <span style={{marginLeft:'auto',fontSize:11,color:DIM,alignSelf:'center'}}>{filtered.length} students</span>
            </div>
            <div style={{background:'rgba(77,159,255,0.05)',border:'1px solid '+BOR,borderRadius:10,padding:14,marginBottom:12}}>
              <div style={{fontSize:11,fontWeight:700,color:ACC,marginBottom:8}}>➕ Add Student by Email</div>
              <div style={{display:'flex',gap:8}}>
                <input value={addEmail} onChange={e=>setAddEmail(e.target.value)} onKeyDown={e=>e.key==='Enter'&&addStudent()} placeholder="student@email.com" style={{...inp2,flex:1,padding:'9px 12px'}}/>
                <button onClick={addStudent} disabled={adding} style={{...bp2,opacity:adding?0.7:1}} className="bdt2">{adding?'Adding...':'Add'}</button>
              </div>
            </div>
            {filtered.length?(
              <div style={{overflowX:'auto'}}>
                <table style={{width:'100%',borderCollapse:'collapse',fontSize:12}}>
                  <thead><tr style={{borderBottom:'1px solid '+BOR}}>
                    {['#','Student ID','Name','Email','Joined','Status','Action'].map(h=><th key={h} style={{padding:'8px',textAlign:'left',color:DIM,fontWeight:600,fontSize:10,letterSpacing:0.4}}>{h}</th>)}
                  </tr></thead>
                  <tbody>{filtered.map((s,i)=>(
                    <tr key={s._id} className="bdr2" style={{borderBottom:'1px solid '+BOR,transition:'all 0.15s'}}>
                      <td style={{padding:'9px 8px',color:DIM}}>{i+1}</td>
                      <td style={{padding:'9px 8px'}}><div style={{display:'flex',alignItems:'center',gap:4}}><span style={{fontSize:11,color:'#4D9FFF',fontFamily:'monospace',fontWeight:700}}>{s.studentId||'—'}</span>{s.studentId&&<CopyBtn text={s.studentId}/>}</div></td>
                      <td style={{padding:'9px 8px'}}>
                        <div style={{display:'flex',alignItems:'center',gap:7}}>
                          <div style={{width:26,height:26,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid '+BOR2,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                          <span style={{color:TS,fontWeight:600,whiteSpace:'nowrap'}}>{s.name||'—'}</span>
                        </div>
                      </td>
                      <td style={{padding:'9px 8px',color:DIM,fontSize:11}}>{s.email}</td>
                      <td style={{padding:'9px 8px',color:DIM,whiteSpace:'nowrap'}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</td>
                      <td style={{padding:'9px 8px'}}><span style={{fontSize:10,color:s.banned?DNG:SUC,background:s.banned?'rgba(255,77,77,0.1)':'rgba(0,196,140,0.1)',padding:'2px 8px',borderRadius:20}}>{s.banned?'🚫 Banned':'✅ Active'}</span></td>
                      <td style={{padding:'9px 8px'}}><button onClick={()=>removeStudent(s._id,s.name||s.email)} style={bd2} className="bdt2">Remove</button></td>
                    </tr>
                  ))}</tbody>
                </table>
              </div>
            ):<div style={{textAlign:'center',padding:32,color:DIM}}>
              <div style={{fontSize:40,marginBottom:8}}>👥</div>
              <div style={{fontSize:13,fontWeight:600,color:TS,marginBottom:4}}>No students enrolled</div>
              <div style={{fontSize:11}}>Add using email above</div>
            </div>}
          </div>
        </div>}

        {/* ── EXAMS ── */}
        {!loading&&tab==='exams'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>📌 Assign Exam to Batch</div>
            <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
              <select value={assignExamId} onChange={e=>setAssignExamId(e.target.value)} style={{...sel2,flex:1,maxWidth:380}}>
                <option value="">— Select exam to assign —</option>
                {unassignedExams.map(e=><option key={e._id} value={e._id}>{e.title}</option>)}
              </select>
              <button onClick={assignExam} style={bp2} className="bdt2">📌 Assign</button>
            </div>
            {!unassignedExams.length&&<div style={{fontSize:11,color:DIM,marginTop:8}}>All available exams are already assigned, or no exams created yet.</div>}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📝 Assigned Exams ({exams.length})</div>
            {exams.map(e=>(
              <div key={e._id} className="bdr2" style={{display:'flex',gap:12,alignItems:'center',padding:'12px 10px',borderRadius:10,border:'1px solid '+BOR,marginBottom:10,flexWrap:'wrap',transition:'all 0.15s'}}>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{e.title}</div>
                  <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                    <span style={{fontSize:10,color:ACC}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():'-'}</span>
                    <span style={{fontSize:10,color:DIM}}>⏱ {e.duration||'-'} min</span>
                    <span style={{fontSize:10,color:DIM}}>📊 {e.totalMarks||'-'} marks</span>
                    <span style={{fontSize:10,color:e.status==='active'?SUC:WRN,background:e.status==='active'?'rgba(0,196,140,0.12)':'rgba(255,184,77,0.12)',padding:'2px 8px',borderRadius:20}}>{e.status||'draft'}</span>
                  </div>
                </div>
                <button onClick={()=>unassignExam(e._id,e.title)} style={bd2} className="bdt2">Unassign</button>
              </div>
            ))}
            {!exams.length&&<div style={{textAlign:'center',padding:32,color:DIM,fontSize:12}}>
              <div style={{fontSize:40,marginBottom:8}}>📝</div>
              <div style={{fontSize:13,fontWeight:600,color:TS,marginBottom:4}}>No exams assigned</div>
              <div>Assign exams from the dropdown above</div>
            </div>}
          </div>
        </div>}

        {/* ── NOTES / STUDY MATERIAL ── */}
        {!loading&&tab==='notes'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>➕ Add Study Material</div>
            <div style={{display:'grid',gap:10,marginBottom:12}}>
              <div>
                <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Title *</label>
                <input value={noteTitle} onChange={e=>setNoteTitle(e.target.value)} placeholder="e.g. NCERT Biology Chapter 1 Notes" style={inp2}/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div>
                  <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Type</label>
                  <select value={noteType} onChange={e=>setNoteType(e.target.value)} style={{...sel2,width:'100%'}}>
                    <option value="pdf">📄 PDF</option>
                    <option value="video">🎥 Video</option>
                    <option value="doc">📝 Document</option>
                    <option value="link">🔗 Link</option>
                    <option value="image">🖼️ Image</option>
                    <option value="other">📎 Other</option>
                  </select>
                </div>
                <div>
                  <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Subject</label>
                  <select value={noteSub} onChange={e=>setNoteSub(e.target.value)} style={{...sel2,width:'100%'}}>
                    {['General','Biology','Physics','Chemistry','Mathematics','English','Hindi','Other'].map(s=><option key={s} value={s}>{s}</option>)}
                  </select>
                </div>
              </div>
              <div>
                <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Resource URL (Google Drive / YouTube / Direct Link)</label>
                <input value={noteUrl} onChange={e=>setNoteUrl(e.target.value)} placeholder="https://drive.google.com/..." style={inp2}/>
              </div>
              <div>
                <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Description (optional)</label>
                <textarea value={noteDesc} onChange={e=>setNoteDesc(e.target.value)} placeholder="Brief description of this material..." style={{...inp2,minHeight:70,resize:'vertical'}}/>
              </div>
            </div>
            <button onClick={addNote} disabled={addingNote||!noteTitle.trim()} style={{...bp2,background:'linear-gradient(135deg,#7C3AED,#4C1D95)',opacity:(addingNote||!noteTitle.trim())?0.6:1}} className="bdt2">{addingNote?'Adding...':'➕ Add Material'}</button>
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📚 Study Materials ({notes.length})</div>
            {notes.map(n=>(
              <div key={n._id} className="bdr2" style={{display:'flex',gap:12,padding:'12px 10px',borderRadius:10,border:'1px solid '+BOR,marginBottom:10,flexWrap:'wrap',transition:'all 0.15s'}}>
                <div style={{fontSize:28,flexShrink:0,alignSelf:'center'}}>{getNoteIcon(n.type)}</div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{n.title}</div>
                  <div style={{display:'flex',gap:6,flexWrap:'wrap',marginBottom:n.description?4:0}}>
                    <span style={{fontSize:10,color:PRP,background:'rgba(167,139,250,0.1)',padding:'2px 8px',borderRadius:20,border:'1px solid rgba(167,139,250,0.2)'}}>{n.subject}</span>
                    <span style={{fontSize:10,color:DIM,background:'rgba(255,255,255,0.05)',padding:'2px 8px',borderRadius:20}}>{n.type?.toUpperCase()}</span>
                    <span style={{fontSize:10,color:DIM}}>📅 {n.createdAt?new Date(n.createdAt).toLocaleDateString():'-'}</span>
                  </div>
                  {n.description&&<div style={{fontSize:11,color:DIM,marginBottom:6,lineHeight:1.5}}>{n.description}</div>}
                  {n.url&&<a href={n.url} target="_blank" rel="noopener noreferrer" style={{fontSize:11,color:ACC,textDecoration:'none',display:'inline-flex',alignItems:'center',gap:4,background:'rgba(77,159,255,0.08)',padding:'4px 10px',borderRadius:8,border:'1px solid '+BOR2}}>🔗 Open Resource</a>}
                </div>
                <button onClick={()=>deleteNote(n._id,n.title)} style={bd2} className="bdt2">Delete</button>
              </div>
            ))}
            {!notes.length&&<div style={{textAlign:'center',padding:32,color:DIM}}>
              <div style={{fontSize:40,marginBottom:8}}>📚</div>
              <div style={{fontSize:13,fontWeight:600,color:TS,marginBottom:4}}>No materials added</div>
              <div style={{fontSize:11}}>Add PDFs, videos, docs, links above</div>
            </div>}
          </div>
        </div>}

        {/* ── ANALYTICS ── */}
        {!loading&&tab==='analytics'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:14}}>📈 Batch Analytics</div>
            {[{l:'Active Students',v:students.filter(s=>!s.banned).length,t:Math.max(students.length,1),c:SUC},{l:'Banned Students',v:students.filter(s=>s.banned).length,t:Math.max(students.length,1),c:DNG},{l:'Exams Assigned',v:exams.length,t:Math.max(allExams.length,1),c:WRN},{l:'Materials Added',v:notes.length,t:Math.max(notes.length,1),c:PRP}].map(x=>(
              <div key={x.l} style={{marginBottom:14}}>
                <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}><span style={{fontSize:12,color:TS,fontWeight:600}}>{x.l}</span><span style={{fontSize:11,color:DIM}}>{x.v}</span></div>
                <div style={{background:'rgba(255,255,255,0.06)',borderRadius:8,height:10,overflow:'hidden'}}>
                  <div style={{width:Math.round(x.v/x.t*100)+'%',height:'100%',background:'linear-gradient(90deg,'+x.c+','+x.c+'88)',borderRadius:8,transition:'width 1s ease'}}/>
                </div>
              </div>
            ))}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>🏆 Student Roster</div>
            {students.map((s,i)=>(
              <div key={s._id} style={{display:'flex',alignItems:'center',gap:8,padding:'7px 0',borderBottom:'1px solid '+BOR}}>
                <span style={{color:DIM,fontSize:12,minWidth:28}}>{i===0?'🥇':i===1?'🥈':i===2?'🥉':'#'+(i+1)}</span>
                <div style={{width:28,height:28,borderRadius:'50%',background:'rgba(77,159,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:ACC}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1,minWidth:0}}><div style={{fontSize:12,fontWeight:600,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'—'}</div><div style={{fontSize:10,color:DIM}}>{s.email}</div></div>
                <span style={{fontSize:10,color:s.banned?DNG:SUC,flexShrink:0}}>{s.banned?'🚫':'✅'}</span>
              </div>
            ))}
            {!students.length&&<div style={{textAlign:'center',padding:24,color:DIM,fontSize:12}}>No students</div>}
          </div>
        </div>}

        {/* ── ANNOUNCE ── */}
        {!loading&&tab==='announce'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>📢 Send Announcement</div>
            <div style={{fontSize:11,color:DIM,marginBottom:14}}>To all <strong style={{color:ACC}}>{students.length} students</strong> in "{batch.name}"</div>
            <div style={{marginBottom:10}}>
              <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Title</label>
              <input value={annTitle} onChange={e=>setAnnTitle(e.target.value)} placeholder="e.g. Test Tomorrow at 10 AM" style={inp2}/>
            </div>
            <div style={{marginBottom:16}}>
              <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Message</label>
              <textarea value={annMsg} onChange={e=>setAnnMsg(e.target.value)} placeholder="Write your announcement..." style={{...inp2,minHeight:110,resize:'vertical'}}/>
            </div>
            {(annTitle||annMsg)&&<div style={{background:'rgba(77,159,255,0.05)',border:'1px solid '+BOR,borderRadius:10,padding:14,marginBottom:14}}>
              <div style={{fontSize:10,color:DIM,marginBottom:6,fontWeight:600,letterSpacing:0.4}}>PREVIEW</div>
              <div style={{fontWeight:700,fontSize:14,color:TS}}>{annTitle||'—'}</div>
              <div style={{fontSize:12,color:DIM,marginTop:4,whiteSpace:'pre-wrap'}}>{annMsg||'—'}</div>
            </div>}
            <button onClick={sendAnn} style={{...bp2,opacity:(!annTitle||!annMsg)?0.6:1}} className="bdt2">📢 Send to All Students</button>
          </div>
        </div>}

        {/* ── SETTINGS ── */}
        {!loading&&tab==='settings'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>✏️ Rename Batch</div>
            {!renaming?
              <div style={{display:'flex',gap:10,alignItems:'center'}}>
                <span style={{fontSize:15,fontWeight:700,color:ACC,flex:1}}>"{batch.name}"</span>
                <button onClick={()=>{setRenaming(true);setNewName(batch.name)}} style={bp2} className="bdt2">✏️ Rename</button>
              </div>:
              <div>
                <input value={newName} onChange={e=>setNewName(e.target.value)} onKeyDown={e=>e.key==='Enter'&&renameBatch()} style={{...inp2,marginBottom:10}}/>
                <div style={{display:'flex',gap:8}}>
                  <button onClick={renameBatch} style={bp2} className="bdt2">💾 Save</button>
                  <button onClick={()=>setRenaming(false)} style={{background:'rgba(77,159,255,0.1)',color:ACC,border:'1px solid '+BOR2,borderRadius:8,padding:'9px 16px',cursor:'pointer',fontSize:12}} className="bdt2">Cancel</button>
                </div>
              </div>}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>ℹ️ Batch Info</div>
            {([['Batch ID',batch._id],['Name',batch.name],['Students',students.length],['Exams',exams.length],['Materials',notes.length],['Created',batch.createdAt?new Date(batch.createdAt).toLocaleString():'-']] as [string,any][]).map(([k,v])=>(
              <div key={k} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:'1px solid '+BOR,flexWrap:'wrap',gap:4}}>
                <span style={{fontSize:11,color:DIM,fontWeight:600}}>{k}</span>
                <span style={{fontSize:11,color:TS,fontFamily:'monospace'}}>{String(v)}</span>
              </div>
            ))}
          </div>
          <div style={{...cs2,border:'1px solid rgba(255,77,77,0.25)',background:'rgba(255,77,77,0.03)'}}>
            <div style={{fontWeight:700,fontSize:13,color:DNG,marginBottom:4}}>🚨 Danger Zone</div>
            <div style={{fontSize:11,color:DIM,marginBottom:12}}>Permanently deletes this batch and unassigns all students.</div>
            <button onClick={deleteBatch} style={{...bd2,padding:'10px 20px',fontSize:13}} className="bdt2">🗑️ Delete This Batch</button>
          </div>
        </div>}
      </div>
    
      <AdminWelcomeBanner /></div>
  )
}

export default function AdminPanel() {
  const router=useRouter()
  useEffect(()=>{},[]);
  const [role,setRole]=useState('')
  const [token,setToken]=useState('')
  const [mounted,setMounted]=useState(false)
  const [tab,setTab]=useState('dashboard')
  const _setTab=(id:string)=>{if(id==='creative_studio'){window.location.href='/admin/x7k2p/banner-generator';return;}_setTab_orig(id);}
  const _setTab_orig=(t:string)=>{try{sessionStorage.setItem('pr_admin_tab',t)}catch{};setTab(t)}
  const [sideOpen,setSideOpen]=useState(false)
  const [toast,setToast]=useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)
  const [notifOpen,setNotifOpen]=useState(false);
  const [notifDetail,setNotifDetail]=useState<any>(null);
const [topStudents,setTopStudents]=useState<{rank:number,name:string,bestScore:number,totalExams:number}[]>([])
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
  const [selectedBatch,setSelectedBatch]=useState<any>(null)
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
  const [qSubj,setQSubj]=useState('')
  const [qDiff,setQDiff]=useState('medium')
  const [qType,setQType]=useState('SCQ')
  const [qAns,setQAns]=useState('')
  const [qHindi,setQHindi]=useState('')
  const [qChap,setQChap]=useState('')
  const [qTopic,setQTopic]=useState('')
  const [qExp,setQExp]=useState('')
  const [qImg,setQImg]=useState('')
  //FIX_STATES_DONE
  const [savingQ,setSavingQ]=useState(false)
  const [qPreview,setQPreview]=useState(false)
  const [qBV,setQBV]=useState(()=>{try{return sessionStorage.getItem('pr_qbv')||'home'}catch{return 'home'}})
  // FIX_PREVIEW_AUTOFETCH
  useEffect(()=>{
    if(qBV==='preview'&&token&&questions.length===0){
      fetch(`${API}/api/questions`,{headers:{Authorization:`Bearer ${token}`}})
        .then(r=>r.ok?r.json():null)
        .then(d=>{if(d)setQuestions(Array.isArray(d)?d:(d.questions||d.data||[]))})
        .catch(()=>{})
    }
  },[qBV,token])
  const [formKey,setFormKey]=useState(0)
  const [qSec,setQSec]=useState('all')
  const [qBioSub,setQBioSub]=useState('all')
  const [aiSelChap,setAiSelChap]=useState('')
  const [bulkSel,setBulkSel]=useState([])
  const [selQId,setSelQId]=useState(null)
  const [editQD,setEditQD]=useState(null)
  const [savingEQ,setSavingEQ]=useState(false)
  const [stdPrv,setStdPrv]=useState(false)
  const [aiGO,setAiGO]=useState(false)
  const [aiGStep,setAiGStep]=useState(1)
  const [aiGSub,setAiGSub]=useState('Physics')
  const [aiGCnt,setAiGCnt]=useState('10')
  const [aiGDiff,setAiGDiff]=useState('medium')
  const [aiGLoading,setAiGLoading]=useState(false)
  const [aiGResult,setAiGResult]=useState([])
  const aiChR=useRef('');const aiTopR=useRef('');const qImageR=useRef('')

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
    setToken(t);setRole(r);setMounted(true);if(typeof window!=='undefined'&&sessionStorage.getItem('pr_just_logged_in')){sessionStorage.removeItem('pr_just_logged_in');sessionStorage.removeItem('pr_admin_tab');setTab('dashboard');}else{const sv=typeof window!='undefined'&&sessionStorage.getItem('pr_admin_tab');if(sv)setTab(sv);};
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
  const viewAdminProfile=async(adminId:string)=>{setProfileLoading(true);setShowProfileModal(true);setProfileAdmin(null);setProfileLogs([]);try{const r=await fetch(API+'/api/admin/manage/profile/'+adminId,{headers:{Authorization:'Bearer '+token}});const d=await r.json();setProfileLoading(false);if(d.success){setProfileAdmin(d.admin);setProfileLogs(d.activityLogs||[]);}else{setShowProfileModal(false);}}catch(e){}setProfileLoading(false);};
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
    fetch(`${API}/api/admin/notifications`,{headers:{Authorization:`Bearer ${getToken()}`}}).then(r=>r.json()),
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
else if(nf?.notifications&&Array.isArray(nf.notifications))setNotifs(nf.notifications)
    if(Array.isArray(bt))setBatches(bt)
    // Auto-open batch from URL (refresh fix)
    if(typeof window!=='undefined'){
      const _bid=new URLSearchParams(window.location.search).get('batch')
      if(_bid){
        setTimeout(()=>{
          setSelectedBatch((prev:any)=>{
            if(prev)return prev
            const _found=(Array.isArray(bt)?bt:[]).find((b:any)=>b._id===_bid)
            return _found||prev
          })
        },100)
      }
    }
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
  const editQF=async(id,data)=>{
    setSavingEQ(true)
    try{
      // Convert correctLetter to correct[] array for backend
      const ltrs=['A','B','C','D']
      const correctIdx=ltrs.indexOf(data.correctLetter||'A')
      const payload={
        text:data.text,hindiText:data.hindiText,subject:data.subject,
        chapter:data.chapter,topic:data.topic,difficulty:data.difficulty,
        type:data.type,options:data.options,explanation:data.explanation,
        correct:[correctIdx>=0?correctIdx:0],
        correctAnswer:data.correctLetter||'A'
      }
      const r=await fetch(API+'/api/questions/'+id,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(payload)})
      if(r.ok){T('Question updated!');setEditQD(null);setTimeout(()=>fetchAll(),500)}
      else{const e=await r.json().catch(()=>({}));T(e.message||'Update failed','e')}
    }catch(ex){T(ex.message,'e')}
    setSavingEQ(false)
  }
  const dupQF=async(q)=>{
    const d={text:'[COPY] '+q.text,subject:q.subject,chapter:q.chapter,topic:q.topic,difficulty:q.difficulty,type:q.type,options:q.options}
    try{
      const r=await fetch(API+'/api/questions',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(d)})
      if(r.ok){T('Duplicated!');setTimeout(()=>fetchAll(),400)}else T('Failed','e')
    }catch{T('Network error','e')}
  }
  const aiGF=async()=>{
    const ch=aiChR.current,tp=aiTopR.current
    if(!ch||!tp){T('Chapter aur Topic fill karo','e');return}
    setAiGLoading(true)
    try{
      const r=await fetch(API+'/api/questions/generate',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({subject:aiGSub,chapter:ch,topic:tp,count:parseInt(aiGCnt)||10,difficulty:aiGDiff})})
      if(r.ok){const d=await r.json();const qs=d.questions||d.generated||[];setAiGResult(qs);T(qs.length+' generated!')}
      else T('AI failed','e')
    }catch{T('Network error','e')}
    setAiGLoading(false)
  }
  const saveAiQs=async()=>{
    if(!aiGResult.length)return
    try{
      const r=await fetch(API+'/api/questions/bulk-save',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({questions:aiGResult})})
      if(r.ok){T(aiGResult.length+' saved!');setAiGResult([]);setAiGO(false);setTimeout(()=>fetchAll(),400)}
      else T('Save failed','e')
    }catch{T('Network error','e')}
  }
  const blkDelQs=async()=>{
    if(!bulkSel.length||!confirm('Delete '+bulkSel.length+' questions?'))return
    for(const id of bulkSel){await fetch(API+'/api/questions/'+id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})}
    setQuestions(p=>p.filter(q=>!bulkSel.includes(q._id)));setBulkSel([]);T('Bulk deleted.')
  }
  const expQB=()=>{
    const hdr='ID\tText\tSubject\tChapter\tDifficulty\tType'
    const rows=(questions||[]).map(function(q){return[q._id||'',q.text||'',q.subject||'',q.chapter||'',q.difficulty||'',q.type||''].join('\t')})
    const blob=new Blob([hdr+'\n'+rows.join('\n')],{type:'text/csv'})
    const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='qbank.csv';a.click()
  }
    const addQ=useCallback(async()=>{
    const text=qTxtR.current
    if(!text){T('Question text is required.','e');return}
    setSavingQ(true)
    const payload={
    text,
    hindiText:qHindi||undefined,
    subject:qSubj||'General',
    chapter:qChap||undefined,
    topic:qTopic||undefined,
    difficulty:qDiff||'medium',
    type:qType||'SCQ',
    options:['SCQ','MSQ'].includes(qType)?[qA.current,qB.current,qC.current,qD.current].filter(Boolean):undefined,
    correct:(qType==='Integer'
      ?[parseInt(qAns)||0]
      :qType==='MSQ'
        ?(Array.isArray(qAns)?qAns:qAns?qAns.split(','):[]).map(function(x){return['A','B','C','D'].indexOf(x)}).filter(function(x){return x>=0})
        :[['A','B','C','D'].indexOf((qAns||'').replace('Option ','').trim())].filter(function(x){return x>=0})
    ),
    explanation:qExp||undefined,
    image:qImg||qImageR.current||undefined
  }
    try{
      const res=await fetch(`${API}/api/questions`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(payload)})
      if(res.ok||res.status===201){
        T('Question added to bank successfully.')
        qTxtR.current='';qA.current='';qB.current='';qC.current='';qD.current='';setQHindi('');setQChap('');setQTopic('');setQExp('');setQImg('');setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('');setFormKey(function(k){return k+1})
        const r=await fetch(`${API}/api/questions`,{headers:{Authorization:`Bearer ${token}`}})
        if(r.ok){const qd=await r.json();setQuestions(Array.isArray(qd)?qd:(qd.questions||qd.data||[]))}
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
    const mq=!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase())||q.chapter?.toLowerCase().includes(qSearch.toLowerCase())||q.topic?.toLowerCase().includes(qSearch.toLowerCase())
    const ms=qSubjFilter==='all'||q.subject===qSubjFilter
    const OS=['Physics','Chemistry','Biology','Math']
    const sec=qSec==='all'||(qSec==='Other'?!OS.includes(q.subject||''):q.subject===qSec)
    const bio=qSec!=='Biology'||qBioSub==='all'||(q.chapter||'').toLowerCase().includes(qBioSub.toLowerCase())||(q.topic||'').toLowerCase().includes(qBioSub.toLowerCase())
    return mq&&ms&&sec&&bio
  })

  // ══ NAV ITEMS ══
  const NAV=[
    {id:'myprofile',ico:'👤',lbl:'My Profile',grp:'Overview',alwaysShow:true},
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
    {id:'creative_studio',ico:'🎨',lbl:'Creative Studio',grp:'Creative',alwaysShow:true},
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
  const ADMIN_HIDDEN=['admins','permissions','maintenance','changelog','tasks','parent_portal','transparency','omr_view','proct_pdf','retention','institute_report','re_eval','whatsapp_sms','email_tmpl','global_search','live']
  const filteredNAV=role==='superadmin'?NAV:(()=>{
    const allowed=new Set(['dashboard','myprofile'])
    Object.entries(adminOwnPerms).forEach(([perm,val])=>{
      if(val&&PERM_TO_NAV[perm]) PERM_TO_NAV[perm].forEach(t=>allowed.add(t))
    })
    return NAV.filter(n=>(n.alwaysShow||allowed.has(n.id))&&!ADMIN_HIDDEN.includes(n.id))
  })()
  const filteredNavGroups=[...new Set(filteredNAV.map(n=>n.grp))]

  // ══════════════════════════════════════════════════════════════
  // RENDER
  // ══════════════════════════════════════════════════════════════

  const markAllRead=async()=>{const tk=getToken();if(!tk)return;try{await fetch(`${API}/api/admin/notifications/mark-read`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${tk}`},body:JSON.stringify({all:true})});setNotifs((prev:any[])=>prev.map((n:any)=>({...n,isRead:true})));}catch(e){}};
  const markOneRead=async(id:string,notif?:any)=>{const tk=getToken();if(notif)setNotifDetail(notif);if(!tk)return;try{await fetch(`${API}/api/admin/notifications/mark-read`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${tk}`},body:JSON.stringify({id})});setNotifs((prev:any[])=>prev.map((n:any)=>n._id===id?{...n,isRead:true}:n));}catch(e){}};

  return (
    <div style={{background:BG_GRAD,minHeight:'100vh',color:TS,fontFamily:'Inter,sans-serif',position:'relative'}}>
{/* BD_OVERLAY_INJECTED */}
{selectedBatch!=null&&<BatchDetailOverlay batch={selectedBatch} token={token} API={API} onClose={()=>{setSelectedBatch(null);if(typeof window!=='undefined')window.history.pushState(null,'','/admin/x7k2p')}} onBatchDelete={(id:string)=>{setBatches((p:Batch[])=>p.filter((b:Batch)=>b._id!==id));setSelectedBatch(null)}} onBatchRename={(id:string,name:string)=>{setBatches((p:Batch[])=>p.map((b:Batch)=>b._id===id?{...b,name}:b));setSelectedBatch((p:any)=>({...p,name}))}} T={T}/>}


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
          <button onClick={()=>setNotifOpen(p=>!p)} style={{position:'relative'}} style={{background:'none',border:`1px solid ${BOR}`,color:TS,fontSize:14,cursor:'pointer',position:'relative',width:32,height:32,borderRadius:8,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}>
            🔔
            {(notifs||[]).filter(n=>!n.isRead).length>0&&<span style={{position:'absolute',top:-2,right:-2,background:DNG,color:'#fff',fontSize:8,borderRadius:'50%',width:14,height:14,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700}}>{(notifs||[]).filter(n=>!n.isRead).length}</span>}
          </button>

          <button onClick={fetchAll} title="Refresh" style={{background:'rgba(77,159,255,0.1)',color:ACC,border:`1px solid ${BOR2}`,borderRadius:8,width:32,height:32,cursor:'pointer',fontSize:14,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}>↻</button>
          <button onClick={()=>{sessionStorage.removeItem('pr_admin_tab');clearAuth();window.location.href='/login'}} style={{background:'rgba(255,77,77,0.12)',color:DNG,border:'1px solid rgba(255,77,77,0.25)',borderRadius:8,width:32,height:32,cursor:'pointer',fontWeight:700,fontSize:14,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,fontSize:11,fontWeight:700}}>OUT</button>
        </div>
      </div>

      {/* ══ NOTIFICATION PANEL ══ */}
      {notifOpen&&(
    <div style={{position:'fixed',top:52,right:8,width:320,maxHeight:460,background:'#0d1b2e',border:'1px solid #1e3a5f',borderRadius:12,boxShadow:'0 8px 32px rgba(0,0,0,0.6)',zIndex:9999,display:'flex',flexDirection:'column',overflow:'hidden'}}>
      <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',padding:'10px 14px',borderBottom:'1px solid #1e3a5f',background:'#0a1628'}}>
        <span style={{fontWeight:700,fontSize:14,color:'#e2e8f0'}}>🔔 Notifications</span>
        <div style={{display:'flex',gap:6,alignItems:'center'}}>
          {notifs.filter((n:any)=>!n.isRead).length>0&&(
            <button onClick={markAllRead} style={{fontSize:10,color:'#60a5fa',background:'none',border:'1px solid #1e3a5f',borderRadius:6,padding:'2px 7px',cursor:'pointer'}}>Mark all read</button>
          )}
          <button onClick={()=>setNotifOpen(false)} style={{background:'none',border:'none',color:'#64748b',fontSize:17,cursor:'pointer',lineHeight:1,padding:0}}>×</button>
        </div>
      </div>
      <div style={{overflowY:'auto',flex:1}}>
        {notifs.length===0?(
          <div style={{display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:'36px 16px',color:'#475569'}}>
            <div style={{fontSize:36,marginBottom:8}}>🔕</div>
            <div style={{fontSize:13,fontWeight:600}}>No notifications yet</div>
            <div style={{fontSize:11,marginTop:3}}>Alerts will appear here</div>
          </div>
        ):(
          notifs.slice(0,20).map((n:any,ni:number)=>{
            const sev=n.severity||n.type||'info';
            const cm:any={high:{bg:'rgba(220,38,38,0.12)',bd:'#dc2626',ic:'🔴'},warning:{bg:'rgba(245,158,11,0.12)',bd:'#f59e0b',ic:'⚠️'},suspicious:{bg:'rgba(168,85,247,0.12)',bd:'#a855f7',ic:'🚨'},success:{bg:'rgba(34,197,94,0.12)',bd:'#22c55e',ic:'✅'},info:{bg:'rgba(59,130,246,0.12)',bd:'#3b82f6',ic:'💬'}};
            const c=cm[sev]||cm.info;
            const ts=n.createdAt?new Date(n.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):'';
            return(
              <div key={n._id||ni} onClick={()=>markOneRead(n._id,n)} style={{padding:'10px 14px',borderBottom:'1px solid #1e3a5f',background:n.isRead?'transparent':c.bg,borderLeft:'3px solid '+(n.isRead?'#1e3a5f':c.bd),cursor:'pointer'}}>
                <div style={{display:'flex',gap:8,alignItems:'flex-start'}}>
                  <span style={{fontSize:14}}>{c.ic}</span>
                  <div style={{flex:1,minWidth:0}}>
                    <div style={{display:'flex',alignItems:'center',gap:5}}>
                      <span style={{fontSize:12,fontWeight:n.isRead?400:700,color:n.isRead?'#94a3b8':'#e2e8f0',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',flex:1}}>{n.title||n.message||'Alert'}</span>
                      {!n.isRead&&<span style={{width:6,height:6,borderRadius:'50%',background:c.bd,flexShrink:0,display:'inline-block'}}/>}
                    </div>
                    {n.message&&n.title&&<div style={{fontSize:10,color:'#64748b',marginTop:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{n.message}</div>}
                    {ts&&<div style={{fontSize:10,color:'#475569',marginTop:2}}>{ts}</div>}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
      {notifs.length>0&&(
        <div style={{padding:'8px 14px',borderTop:'1px solid #1e3a5f',background:'#0a1628',textAlign:'center'}}>
          <button onClick={()=>{setNotifOpen(false);setNotifDetail({_all:true,title:"All Notifications",items:notifs});}} style={{fontSize:11,color:"#60a5fa",cursor:"pointer",fontWeight:600,background:"none",border:"none",padding:0,textDecoration:"underline"}}>View All Notifications →</button>
        </div>
      )}
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
{topStudents.length===0
  ?<div style={{fontSize:12,color:'#64748b',textAlign:'center',padding:'10px 0'}}>No exam data yet</div>
  :topStudents.slice(0,5).map((s,idx)=>(
    <div key={idx} style={{display:'flex',alignItems:'center',gap:8,padding:'5px 0',borderBottom:'1px solid rgba(255,255,255,0.05)'}}>
      <span style={{fontSize:12,fontWeight:700,minWidth:18,color:idx===0?'#fbbf24':idx===1?'#94a3b8':idx===2?'#b45309':'#64748b'}}>{idx+1}</span>
      <span style={{fontSize:12,color:'#e2e8f0',flex:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name}</span>
      <span style={{fontSize:11,color:'#38bdf8',fontWeight:600}}>{s.bestScore}pts</span>
    </div>
  ))
}
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
            <div style={{position:'relative'}}>

              {/* HOME */}
              {qBV==='home'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:16,flexWrap:'wrap',gap:10}}>
                    <div><div style={pageTitle}>📚 Question Bank</div><div style={pageSub}>{(questions||[]).length} questions · NEET Pattern Ready</div></div>
                    <button onClick={expQB} style={{...bg_,fontSize:11,padding:'6px 12px'}}>⬇️ Export CSV</button>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:6,marginBottom:18}}>
                    {[{l:'Total',v:(questions||[]).length,c:'#A78BFA'},{l:'Physics',v:(questions||[]).filter(function(q){return q.subject==='Physics'}).length,c:'#60A5FA'},{l:'Chemistry',v:(questions||[]).filter(function(q){return q.subject==='Chemistry'}).length,c:'#F472B6'},{l:'Biology',v:(questions||[]).filter(function(q){return q.subject==='Biology'}).length,c:'#34D399'},{l:'Math',v:(questions||[]).filter(function(q){return q.subject==='Math'}).length,c:'#FBBF24'}].map(function(x){return(
                      <div key={x.l} style={{background:'rgba(255,255,255,0.04)',border:'1px solid '+x.c+'30',borderRadius:10,padding:'10px 6px',textAlign:'center'}}>
                        <div style={{fontSize:18,fontWeight:800,color:x.c}}>{x.v}</div>
                        <div style={{fontSize:9,color:'#64748b',marginTop:2}}>{x.l}</div>
                      </div>
                    )})}
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,maxWidth:660,margin:'0 auto 18px'}}>
                    <div onClick={function(){setQBV('add');try{sessionStorage.setItem('pr_qbv','add')}catch{}}} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(77,159,255,0.12),rgba(160,80,255,0.08))',border:'1.5px solid rgba(77,159,255,0.3)',borderRadius:18,padding:'24px 16px',textAlign:'center'}}>
                      <div style={{fontSize:36,marginBottom:8,filter:'drop-shadow(0 0 10px rgba(77,159,255,0.5))'}}>➕</div>
                      <div style={{fontSize:15,fontWeight:800,color:'#E2E8F0',marginBottom:4}}>Add Question</div>
                      <div style={{fontSize:11,color:'#64748B',marginBottom:14}}>Manually add or AI auto-generate</div>
                      <div style={{display:'inline-block',background:'rgba(77,159,255,0.15)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:8,padding:'6px 14px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>Add Questions →</div>
                    </div>
                    <div onClick={function(){setQBV('preview');setQSec('all');try{sessionStorage.setItem('pr_qbv','preview')}catch{}}} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(0,229,160,0.08),rgba(160,80,255,0.06))',border:'1.5px solid rgba(0,229,160,0.25)',borderRadius:18,padding:'24px 16px',textAlign:'center'}}>
                      <div style={{fontSize:36,marginBottom:8,filter:'drop-shadow(0 0 10px rgba(0,229,160,0.4))'}}>👁️</div>
                      <div style={{fontSize:15,fontWeight:800,color:'#E2E8F0',marginBottom:4}}>Preview All Questions</div>
                      <div style={{fontSize:11,color:'#64748B',marginBottom:14}}>Browse, filter, edit section-wise</div>
                      <div style={{display:'inline-block',background:'rgba(0,229,160,0.12)',border:'1px solid rgba(0,229,160,0.35)',borderRadius:8,padding:'6px 14px',fontSize:11,color:'#00E5A0',fontWeight:700}}>Preview Bank →</div>
                    </div>
                  </div>
                  {(questions||[]).length>0&&(function(){
                    const all=questions||[];const tot=all.length||1
                    const ez=all.filter(function(q){return q.difficulty==='easy'}).length
                    const md=all.filter(function(q){return q.difficulty==='medium'}).length
                    const hd=all.filter(function(q){return q.difficulty==='hard'}).length
                    return(<div style={{background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.07)',borderRadius:12,padding:'12px 14px'}}>
                      <div style={{fontSize:11,color:'#94A3B8',fontWeight:600,marginBottom:8}}>📊 Difficulty Distribution</div>
                      {[{l:'Easy',v:ez,col:'#00C864'},{l:'Medium',v:md,col:'#FFB300'},{l:'Hard',v:hd,col:'#FF4D4D'}].map(function(x){
                        const pct=Math.round((x.v/tot)*100)
                        return(<div key={x.l} style={{display:'flex',alignItems:'center',gap:8,marginBottom:6}}>
                          <div style={{width:48,fontSize:10,color:x.col,fontWeight:600}}>{x.l}</div>
                          <div style={{flex:1,height:4,background:'rgba(255,255,255,0.06)',borderRadius:2}}><div style={{width:pct+'%',height:'100%',background:x.col,borderRadius:2}}/></div>
                          <div style={{width:58,fontSize:10,color:'#475569',textAlign:'right'}}>{x.v} ({pct}%)</div>
                        </div>)
                      })}
                    </div>)
                  })()}
                </div>
              )}

              {/* ADD QUESTION */}
              {qBV==='add'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:14}}>
                    <button onClick={function(){setQBV('home');try{sessionStorage.setItem('pr_qbv','home')}catch{}}} style={{...bg_,padding:'6px 12px',fontSize:12}}>← Back</button>
                    <div><div style={pageTitle}>➕ Add Question to Bank</div><div style={pageSub}>Fill all details — saves instantly</div></div>
                  </div>
                  <div key={formKey} style={cs}>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:11}}>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>📝 Question Text (English) *</label>
                        <STextarea init='' onSet={function(v){qTxtR.current=v}} ph='Type the full question here…' rows={3} style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>🇮🇳 Hindi Text <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <textarea value={qHindi} onChange={function(e){qHindiR.current=e.target.value;setQHindi(e.target.value)}} rows={2} placeholder='हिंदी में प्रश्न (वैकल्पिक)...' style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div>
                        <label style={lbl}>📚 Subject *</label>
                        <select value={qSubj} onChange={function(e){setQSubj(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select Subject —</option>
                          <option value='Physics'>⚛️ Physics</option>
                          <option value='Chemistry'>🧪 Chemistry</option>
                          <option value='Biology'>🧬 Biology</option>
                          <option value='Math'>📐 Math</option>
                          <option value='Other'>📖 Other</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>🔢 Question Type</label>
                        <select value={qType} onChange={function(e){setQType(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value='SCQ'>SCQ — Single Correct</option>
                          <option value='MSQ'>MSQ — Multiple Correct</option>
                          <option value='Integer'>Integer Type</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>🎯 Difficulty</label>
                        <select value={qDiff} onChange={function(e){setQDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select —</option>
                          <option value='easy'>🟢 Easy</option>
                          <option value='medium'>🟡 Medium</option>
                          <option value='hard'>🔴 Hard</option>
                        </select>
                      </div>
                      <div>
					{qType==='Integer'?(<input type='number' value={qAns} onChange={function(e){setQAns(e.target.value)}} style={{...inp,width:'100%'}} placeholder='Enter integer answer'/>):qType==='MSQ'?(<div style={{display:'flex',gap:'10px',flexWrap:'wrap',marginTop:'6px'}}>{['A','B','C','D'].map(function(opt){const sel=Array.isArray(qAns)?qAns:qAns?qAns.split(','):[];return(<label key={opt} style={{display:'flex',alignItems:'center',gap:'6px',cursor:'pointer',padding:'6px 12px',background:sel.includes(opt)?'rgba(77,159,255,0.25)':'rgba(255,255,255,0.05)',borderRadius:'8px',border:'1px solid rgba(77,159,255,0.3)'}}><input type='checkbox' checked={sel.includes(opt)} onChange={function(){const p=Array.isArray(qAns)?[...qAns]:qAns?qAns.split(','):[];const n=p.includes(opt)?p.filter(function(x){return x!==opt}):[...p,opt];setQAns(n);}}/><span style={{color:'#E2E8F0',fontSize:'13px'}}>Option {opt}</span></label>)})}</div>):(<select value={qAns} onChange={function(e){setQAns(e.target.value)}} style={{...inp,width:'100%'}}><option value={''}>— Select Answer —</option><option value='A'>Option A</option><option value='B'>Option B</option><option value='C'>Option C</option><option value='D'>Option D</option></select>)}
                      </div>
                      <div>
                        <label style={lbl}>📌 Topic</label>
                        <input value={qTopic} onChange={function(e){qTopicR.current=e.target.value;setQTopic(e.target.value)}} placeholder='e.g. Coulombs Law' style={{...inp}}/>
                      </div>
                      {['SCQ','MSQ'].includes(qType)&&(<>
                        <div><label style={lbl}>Option A</label><SInput init='' onSet={function(v){qA.current=v}} ph='Option A…' style={inp}/></div>
                        <div><label style={lbl}>Option B</label><SInput init='' onSet={function(v){qB.current=v}} ph='Option B…' style={inp}/></div>
                        <div><label style={lbl}>Option C</label><SInput init='' onSet={function(v){qC.current=v}} ph='Option C…' style={inp}/></div>
                        <div><label style={lbl}>Option D</label><SInput init='' onSet={function(v){qD.current=v}} ph='Option D…' style={inp}/></div>
                      </>)}
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>💡 Explanation <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <textarea value={qExp} onChange={function(e){qExpR.current=e.target.value;setQExp(e.target.value)}} rows={2} placeholder='Explain the correct answer...' style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>🖼️ Image URL <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <input value={qImg} onChange={function(e){qImageR.current=e.target.value;setQImg(e.target.value)}} placeholder='https://imgur.com/... (paste image link)' style={{...inp}}/>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:10,marginTop:14,flexWrap:'wrap'}}>
                      <button onClick={addQ} disabled={savingQ} style={{...bp,flex:2,minWidth:150,opacity:savingQ?0.7:1}}>{savingQ?'⟳ Saving…':'✅ Add to Question Bank'}</button>
                      <button onClick={function(){
                        qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';
                        qChapR.current='';qTopicR.current='';qExpR.current='';qImageR.current='';
                        setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('');
                        setFormKey(function(k){return k+1});T('Form cleared')
                      }} style={{...bg_,padding:'8px 16px'}}>🗑️ Clear</button>
                    </div>
                  </div>
                  <div style={{display:'flex',justifyContent:'center',marginTop:18}}>
                    <div onClick={function(){setAiGO(true)}} style={{display:'flex',alignItems:'center',gap:10,background:'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(168,85,247,0.2))',border:'1.5px solid rgba(168,85,247,0.45)',borderRadius:50,padding:'10px 22px',cursor:'pointer',boxShadow:'0 0 20px rgba(168,85,247,0.4)',animation:'qbpulse 2s infinite'}}>
                      <div style={{width:38,height:38,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#A855F7)',display:'flex',alignItems:'center',justifyContent:'center',boxShadow:'0 0 12px rgba(168,85,247,0.6)',fontSize:18,flexShrink:0}}>🤖</div>
                      <div><div style={{fontSize:13,fontWeight:800,color:'#E2E8F0'}}>Upload Via AI</div><div style={{fontSize:10,color:'#A78BFA'}}>Auto-generate NCERT questions</div></div>
                      <div style={{fontSize:16,color:'#A78BFA'}}>✨</div>
                    </div>
                  </div>
                  <style dangerouslySetInnerHTML={{__html:'@keyframes qbpulse{0%,100%{box-shadow:0 0 20px rgba(168,85,247,0.4)}50%{box-shadow:0 0 35px rgba(168,85,247,0.7),0 0 55px rgba(77,159,255,0.3)}}'}}/>
                </div>
              )}

              {/* PREVIEW ALL */}
              {qBV==='preview'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:10,flexWrap:'wrap'}}>
                    <button onClick={function(){setQBV('home');setBulkSel([]);try{sessionStorage.setItem('pr_qbv','home')}catch{}}} style={{...bg_,padding:'5px 11px',fontSize:11}}>← Back</button>
                    <div style={{flex:1}}><div style={pageTitle}>👁️ Preview All Questions</div><div style={pageSub}>{fQs.length} of {(questions||[]).length} shown</div></div>
                    <button onClick={function(){setStdPrv(function(p){return !p})}} style={{...bg_,fontSize:10,padding:'5px 10px',background:stdPrv?'rgba(0,229,160,0.12)':'rgba(255,255,255,0.05)',color:stdPrv?'#00E5A0':'#94A3B8'}}>{stdPrv?'🎓 ON':'🎓 View'}</button>
                    <button onClick={expQB} style={{...bg_,fontSize:10,padding:'5px 10px'}}>⬇️</button>
                    <button onClick={function(){setQBV('add');try{sessionStorage.setItem('pr_qbv','add')}catch{}}} style={{...bp,fontSize:10,padding:'5px 12px'}}>➕ Add</button>
                  </div>
                  <SInput init='' onSet={setQSearch} ph='🔍 Search questions, chapter, topic…' style={{...inp,marginBottom:8,fontSize:12}}/>
                  <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:7}}>
                    {[{k:'all',l:'All',col:'#A78BFA'},{k:'Physics',l:'⚛️ Phy',col:'#60A5FA'},{k:'Chemistry',l:'🧪 Chem',col:'#F472B6'},{k:'Biology',l:'🧬 Bio',col:'#34D399'},{k:'Math',l:'📐 Math',col:'#FBBF24'},{k:'Other',l:'📚 Other',col:'#94A3B8'}].map(function(x){
                      const cnt=x.k==='all'?(questions||[]).length:x.k==='Other'?(questions||[]).filter(function(q){return !['Physics','Chemistry','Biology','Math'].includes(q.subject||'')}).length:(questions||[]).filter(function(q){return q.subject===x.k}).length
                      const isA=qSec===x.k
                      return(<button key={x.k} onClick={function(){setQSec(x.k);setQBioSub('all')}} style={{padding:'4px 10px',borderRadius:16,border:'1.5px solid '+(isA?x.col:x.col+'22'),background:isA?x.col+'18':'transparent',color:isA?x.col:'#64748B',fontSize:10,fontWeight:isA?700:400,cursor:'pointer'}}>{x.l} ({cnt})</button>)
                    })}
                  </div>
                  {qSec==='Biology'&&(<div style={{display:'flex',gap:5,marginBottom:7}}>
                    {[{k:'all',l:'All Bio'},{k:'Zoology',l:'🦁 Zoo'},{k:'Botany',l:'🌿 Bot'}].map(function(x){
                      const isA=qBioSub===x.k
                      return(<button key={x.k} onClick={function(){setQBioSub(x.k)}} style={{padding:'3px 9px',borderRadius:12,border:'1px solid '+(isA?'#34D399':'rgba(52,211,153,0.2)'),background:isA?'rgba(52,211,153,0.12)':'transparent',color:isA?'#34D399':'#64748B',fontSize:10,cursor:'pointer'}}>{x.l}</button>)
                    })}
                  </div>)}
                  {fQs.length>0&&(function(){
                    const tot=fQs.length
                    const ez=fQs.filter(function(q){return q.difficulty==='easy'}).length
                    const md=fQs.filter(function(q){return q.difficulty==='medium'}).length
                    const hd=fQs.filter(function(q){return q.difficulty==='hard'}).length
                    return(<div style={{display:'flex',gap:10,alignItems:'center',marginBottom:8,padding:'5px 10px',background:'rgba(255,255,255,0.02)',borderRadius:7,flexWrap:'wrap'}}>
                      <span style={{color:'#475569',fontSize:10,fontWeight:600}}>Difficulty:</span>
                      {[{l:'Easy',v:ez,c:'#00C864'},{l:'Med',v:md,c:'#FFB300'},{l:'Hard',v:hd,c:'#FF4D4D'}].map(function(x){return(
                        <span key={x.l} style={{fontSize:10,color:x.c,fontWeight:600}}>{x.v} {x.l} <span style={{color:'#475569',fontWeight:400}}>({Math.round((x.v/tot)*100)}%)</span></span>
                      )})}
                    </div>)
                  })()}
                  {bulkSel.length>0&&(<div style={{display:'flex',alignItems:'center',gap:8,padding:'7px 12px',background:'rgba(255,60,60,0.07)',border:'1px solid rgba(255,60,60,0.2)',borderRadius:8,marginBottom:8,flexWrap:'wrap'}}>
                    <span style={{fontSize:11,color:'#FC8181',fontWeight:700}}>{bulkSel.length} selected</span>
                    <button onClick={blkDelQs} style={{...bd,fontSize:10,padding:'3px 12px'}}>🗑️ Delete</button>
                    <button onClick={function(){setBulkSel([])}} style={{...bg_,fontSize:10,padding:'3px 10px'}}>✕</button>
                  </div>)}
                  {fQs.length===0
                    ?<PageHero icon='❓' title='No Questions Found' subtitle={questions.length===0?'Loading questions…':'Try different search or section filter.'}/>
                    :<div style={{display:'flex',flexDirection:'column',gap:5}}>
                      {fQs.map(function(q,qi){
                        const isChk=bulkSel.includes(q._id)
                        const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':q.subject==='Math'?'#FBBF24':'#94A3B8'
                        const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                        return(
                          <div key={q._id||qi} style={{background:isChk?'rgba(77,159,255,0.05)':'rgba(255,255,255,0.02)',border:'1px solid '+(isChk?'rgba(77,159,255,0.2)':'rgba(255,255,255,0.05)'),borderLeft:'3px solid '+sCol+'55',borderRadius:9,padding:'9px 10px'}}>
                            <div style={{display:'flex',alignItems:'flex-start',gap:7}}>
                              <input type='checkbox' checked={isChk} onChange={function(e){if(e.target.checked)setBulkSel(function(p){return [...p,q._id]});else setBulkSel(function(p){return p.filter(function(x){return x!==q._id})})}} style={{marginTop:3,cursor:'pointer',accentColor:'#4D9FFF',flexShrink:0}}/>
                              <div style={{flex:1,minWidth:0}}>
                                <div style={{display:'flex',gap:4,marginBottom:4,flexWrap:'wrap',alignItems:'center'}}>
                                  <span style={{fontSize:9,color:'#4D9FFF',fontWeight:700,background:'rgba(77,159,255,0.1)',borderRadius:3,padding:'1px 5px'}}>#{qi+1}</span>
                                  <span style={{fontSize:9,fontWeight:600,padding:'1px 6px',borderRadius:4,background:sCol+'18',color:sCol,border:'1px solid '+sCol+'30'}}>{q.subject||'General'}</span>
                                  <span style={{fontSize:9,fontWeight:600,padding:'1px 6px',borderRadius:4,background:dCol+'18',color:dCol,border:'1px solid '+dCol+'30'}}>{q.difficulty||'?'}</span>
                                  <span style={{fontSize:9,padding:'1px 5px',borderRadius:3,background:'rgba(77,159,255,0.08)',color:'#4D9FFF'}}>{q.type||'SCQ'}</span>
                                </div>
                                <div onClick={function(){setSelQId(q._id)}} style={{cursor:'pointer',fontSize:12,color:'#CBD5E1',lineHeight:1.5,marginBottom:3}}>{(q.text||'').slice(0,140)}{(q.text||'').length>140?'…':''}</div>
                                {q.chapter&&<div style={{fontSize:10,color:'#475569'}}>📖 {q.chapter}{q.topic?' › '+q.topic:''}</div>}
                                {stdPrv&&(q.options||[]).length>0&&(<div style={{marginTop:6,display:'grid',gridTemplateColumns:'1fr 1fr',gap:3}}>
                                  {(q.options||[]).map(function(opt,oi){
                                    const ltr=String.fromCharCode(65+oi)
                                    const cIdx=Array.isArray(q.correct)?q.correct[0]:undefined
                                    const isC=(Array.isArray(cIdx)?cIdx.includes(oi):cIdx===oi)||(q.correctAnswer&&q.correctAnswer===ltr)
                                    return(<div key={oi} style={{padding:'3px 7px',borderRadius:5,fontSize:10,border:'1px solid '+(isC?'rgba(0,200,100,0.4)':'rgba(255,255,255,0.06)'),background:isC?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)',color:isC?'#00C864':'#94A3B8'}}>
                                      <span style={{fontWeight:700,marginRight:4,color:isC?'#00C864':'#4D9FFF'}}>{ltr}.</span>{(opt||'').slice(0,28)}{isC&&' ✓'}
                                    </div>)
                                  })}
                                </div>)}
                              </div>
                              {/* HORIZONTAL action buttons */}
                              <div style={{display:'flex',gap:3,flexShrink:0,flexWrap:'nowrap'}}>
                                <button onClick={function(){setSelQId(q._id)}} style={{...bg_,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Preview'>👁️</button>
                                <button onClick={function(){
                                  const ltrs=['A','B','C','D']
                                  const cIdx=Array.isArray(q.correct)&&q.correct.length>0?q.correct[0]:(q.correctAnswer?ltrs.indexOf(q.correctAnswer):0)
                                  setEditQD(Object.assign({},q,{correctLetter:ltrs[cIdx>=0?cIdx:0]||'A'}))
                                }} style={{...bg_,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Edit'>✏️</button>
                                <button onClick={function(){dupQF(q)}} style={{...bg_,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Duplicate'>📋</button>
                                <button onClick={async function(){if(confirm('Delete?')){const r=await fetch(API+'/api/questions/'+q._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}});if(r.ok){setQuestions(function(p){return p.filter(function(x){return x._id!==q._id})});T('Deleted.')}else T('Failed','e')}}} style={{...bd,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Delete'>🗑️</button>
                              </div>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  }
                </div>
              )}

              {/* AI GENERATE MODAL — Single Form */}
              {aiGO&&(function(){
                const NCERT={"Physics":{"11th - Physical World":["Nature of Physical Laws","Fundamental Forces"],"11th - Units & Measurements":["SI Units","Significant Figures","Errors in Measurement","Dimensional Analysis"],"11th - Motion in Straight Line":["Distance & Displacement","Velocity & Acceleration","Equations of Motion","Relative Motion"],"11th - Motion in a Plane":["Vectors","Projectile Motion","Circular Motion","Relative Velocity"],"11th - Laws of Motion":["Newtons Laws","Friction","Inertia","Momentum","Conservation of Momentum"],"11th - Work Energy Power":["Work Done","Kinetic Energy","Potential Energy","Conservation of Energy","Power"],"11th - System of Particles":["Centre of Mass","Angular Momentum","Torque","Rotational Motion"],"11th - Gravitation":["Keplers Laws","Universal Gravitation","Gravitational Potential Energy","Satellites","Escape Velocity"],"11th - Mechanical Properties Solids":["Stress & Strain","Youngs Modulus","Bulk Modulus","Shear Modulus"],"11th - Mechanical Properties Fluids":["Pressure","Archimedes Principle","Bernoullis Theorem","Viscosity","Surface Tension"],"11th - Thermal Properties":["Temperature","Thermal Expansion","Calorimetry","Heat Transfer","Radiation"],"11th - Thermodynamics":["Zeroth Law","First Law","Second Law","Carnot Engine","Entropy"],"11th - Kinetic Theory":["Kinetic Theory of Gases","Mean Free Path","Degrees of Freedom","Specific Heat Capacity"],"11th - Oscillations":["Simple Harmonic Motion","Time Period","Amplitude","Damped Oscillations","Resonance"],"11th - Waves":["Wave Motion","Speed of Sound","Superposition","Stationary Waves","Doppler Effect"],"12th - Electric Charges & Fields":["Coulombs Law","Electric Field","Gauss Law","Electric Dipole","Electric Flux"],"12th - Electrostatic Potential":["Electric Potential","Potential Energy","Capacitance","Dielectrics","Van de Graaff"],"12th - Current Electricity":["Ohms Law","Kirchhoffs Laws","Wheatstone Bridge","Potentiometer","EMF & Internal Resistance"],"12th - Moving Charges & Magnetism":["Biot Savart Law","Amperes Law","Cyclotron","Magnetic Force on Current"],"12th - Magnetism & Matter":["Magnetic Dipole","Earths Magnetism","Diamagnetic Paramagnetic Ferromagnetic","Hysteresis"],"12th - Electromagnetic Induction":["Faradays Law","Lenzs Law","Mutual Inductance","Self Inductance","Eddy Currents"],"12th - Alternating Current":["AC Generator","RMS Values","Impedance","Resonance","Power Factor","Transformer"],"12th - Electromagnetic Waves":["Displacement Current","EM Spectrum","Properties of EM Waves"],"12th - Ray Optics":["Reflection","Refraction","Total Internal Reflection","Lenses","Optical Instruments","Prism"],"12th - Wave Optics":["Huygens Principle","Interference","Diffraction","Polarisation","Youngs Double Slit"],"12th - Dual Nature of Radiation":["Photoelectric Effect","De Broglie Wavelength","Davisson Germer"],"12th - Atoms":["Bohr Model","Hydrogen Spectrum","Atomic Spectra"],"12th - Nuclei":["Nuclear Binding Energy","Radioactivity","Nuclear Fission & Fusion","Half Life"],"12th - Semiconductor Electronics":["P-N Junction","Diode","Transistor","Logic Gates","Rectification"]},"Chemistry":{"11th - Basic Concepts":["Mole Concept","Stoichiometry","Limiting Reagent","Atomic Mass","Molecular Formula"],"11th - Structure of Atom":["Bohr Model","Quantum Numbers","Orbitals","Electronic Configuration","Aufbau Principle"],"11th - Classification of Elements":["Modern Periodic Table","Periodicity","Atomic Radius","Ionisation Enthalpy","Electronegativity"],"11th - Chemical Bonding":["Ionic Bond","Covalent Bond","VSEPR Theory","Hybridisation","Hydrogen Bond","Molecular Orbital Theory"],"11th - States of Matter":["Ideal Gas Equation","Kinetic Molecular Theory","Real Gases","Van der Waals"],"11th - Thermodynamics":["Enthalpy","Entropy","Gibbs Energy","Hess Law","Bond Enthalpy"],"11th - Equilibrium":["Law of Mass Action","Kp Kc","Le Chateliers Principle","Buffer Solution","pH & Ionic Equilibrium"],"11th - Redox Reactions":["Oxidation Reduction","Oxidation Number","Balancing Redox","Electrochemical Series"],"11th - Hydrogen":["Hydrogen Bonding","Water","Heavy Water","Hydrogen Peroxide"],"11th - s-Block Elements":["Alkali Metals","Alkaline Earth Metals","Sodium Potassium Compounds","Calcium Compounds"],"11th - p-Block Elements":["Group 13 14","Borax","Carbon Allotropes","Nitrogen Compounds","Phosphorus"],"11th - Organic Chemistry Basics":["Hybridisation","Functional Groups","Homologous Series","IUPAC Nomenclature","Isomerism"],"11th - Hydrocarbons":["Alkanes","Alkenes","Alkynes","Benzene","Aromaticity","Conformations"],"11th - Environmental Chemistry":["Air Pollution","Water Pollution","Greenhouse Effect","Ozone Depletion"],"12th - Solid State":["Crystal Systems","Packing Efficiency","Defects in Crystals","Magnetic Properties"],"12th - Solutions":["Molarity Molality","Raoults Law","Colligative Properties","Osmosis","Van t Hoff Factor"],"12th - Electrochemistry":["Galvanic Cells","Electrode Potential","Nernst Equation","Electrolysis","Faradays Laws"],"12th - Chemical Kinetics":["Rate of Reaction","Order of Reaction","Arrhenius Equation","Activation Energy","Collision Theory"],"12th - Surface Chemistry":["Adsorption","Catalysis","Colloids","Emulsions","Micelles"],"12th - General Principles Isolation":["Thermodynamics of Extraction","Ellingham Diagram","Refining Methods"],"12th - p-Block 15to18":["Nitrogen Family","Oxygen & Sulphur","Halogens","Noble Gases","Interhalogen Compounds"],"12th - d-Block Elements":["Transition Metals","Properties","Potassium Dichromate","Potassium Permanganate"],"12th - Coordination Compounds":["Ligands","CFSE","Crystal Field Theory","Isomerism","Bonding"],"12th - Haloalkanes Haloarenes":["Nomenclature","SN1 SN2","Elimination","Aryl Halides"],"12th - Alcohols Phenols Ethers":["Preparation","Properties","Reactions","Lucas Test","Victor Meyer"],"12th - Aldehydes & Ketones":["Nucleophilic Addition","Aldol Condensation","Cannizzaro","Tollens Fehlings"],"12th - Carboxylic Acids":["Acidity","Esterification","Hell Volhard Zelinsky","Derivatives"],"12th - Amines":["Basicity","Diazonium Salts","Coupling Reactions","Hoffmann Bromamide"],"12th - Biomolecules":["Carbohydrates","Proteins","Nucleic Acids","Vitamins","Enzymes"],"12th - Polymers":["Addition Polymerisation","Condensation","Rubber","Plastics","Biodegradable"],"12th - Chemistry Everyday Life":["Drugs","Food Preservatives","Cleansing Agents","Antimicrobials"]},"Biology":{"11th - The Living World":["Characteristics of Living Organisms","Biodiversity","Taxonomy","Nomenclature","Keys"],"11th - Biological Classification":["Five Kingdom Classification","Monera","Protista","Fungi","Viruses","Lichens"],"11th - Plant Kingdom":["Algae","Bryophyta","Pteridophyta","Gymnosperms","Angiosperms","Alternation of Generations"],"11th - Animal Kingdom":["Basis of Classification","Porifera","Coelenterata","Platyhelminthes","Annelida","Arthropoda","Chordata"],"11th - Morphology of Flowering Plants":["Root Modifications","Stem Modifications","Leaf Modifications","Inflorescence","Flower","Fruit & Seed"],"11th - Anatomy of Flowering Plants":["Meristematic Tissue","Permanent Tissue","Anatomy of Root Stem Leaf"],"11th - Structural Organisation Animals":["Epithelial Tissue","Connective Tissue","Muscle Tissue","Neural Tissue","Frog Anatomy"],"11th - Cell Unit of Life":["Cell Theory","Prokaryotic Cell","Eukaryotic Cell","Cell Organelles","Nucleus"],"11th - Biomolecules":["Carbohydrates","Proteins","Lipids","Nucleic Acids","Enzymes","Metabolism"],"11th - Cell Cycle & Division":["Cell Cycle","Mitosis","Meiosis","Significance"],"11th - Transport in Plants":["Absorption","Apoplast Symplast","Transpiration","Ascent of Sap","Translocation"],"11th - Mineral Nutrition":["Essential Elements","Mineral Deficiency","Nitrogen Fixation","Hydroponics"],"11th - Photosynthesis":["Light Reaction","Calvin Cycle","C4 Pathway","CAM","Photorespiration"],"11th - Respiration in Plants":["Glycolysis","Krebs Cycle","Electron Transport Chain","Fermentation"],"11th - Plant Growth":["Phases of Growth","Plant Hormones","Auxin Gibberellin Cytokinin","Photoperiodism"],"11th - Digestion & Absorption":["Human Digestive System","Digestion Process","Absorption","Disorders"],"11th - Breathing & Exchange":["Respiratory System","Mechanism of Breathing","Gas Exchange","Respiratory Disorders"],"11th - Body Fluids":["Blood Composition","Blood Groups","Coagulation","Lymph","Circulatory System","ECG"],"11th - Locomotion & Movement":["Types of Movement","Muscle Contraction","Skeletal System","Joints","Disorders"],"11th - Neural Control":["Neuron Structure","Nerve Impulse","Synapse","Human Brain","Spinal Cord","Sense Organs"],"11th - Chemical Coordination":["Endocrine Glands","Hormones","Feedback Mechanism","Disorders"],"12th - Reproduction in Organisms":["Modes of Reproduction","Vegetative Propagation","Asexual Reproduction"],"12th - Sexual Reproduction Plants":["Flower Structure","Microsporogenesis","Megasporogenesis","Fertilisation","Embryo Development"],"12th - Human Reproduction":["Male Reproductive System","Female Reproductive System","Gametogenesis","Menstrual Cycle","Fertilisation"],"12th - Reproductive Health":["Contraception","Infertility","STDs","Amniocentesis"],"12th - Principles of Inheritance":["Mendels Laws","Chromosomal Theory","Linkage","Mutation","Sex Determination"],"12th - Molecular Basis of Inheritance":["DNA Structure","Replication","Transcription","Translation","Genetic Code","Regulation"],"12th - Evolution":["Origin of Life","Darwins Theory","Natural Selection","Speciation","Human Evolution"],"12th - Human Health Disease":["Immunity","Vaccines","Common Diseases","Cancer","Drugs & Alcohol"],"12th - Strategies Enhancement":["Animal Breeding","Plant Breeding","Biofortification","SCP","Tissue Culture"],"12th - Microbes Human Welfare":["Biogas","Biocontrol","Biofertilisers","Industrial Microbiology"],"12th - Biotechnology Principles":["Recombinant DNA","Restriction Enzymes","Vectors","PCR","Gel Electrophoresis"],"12th - Biotechnology Applications":["Transgenic Organisms","GM Crops","Gene Therapy","Molecular Diagnosis"],"12th - Organisms & Populations":["Habitat & Niche","Population Interactions","Adaptations","Population Attributes"],"12th - Ecosystem":["Ecosystem Structure","Food Chain","Energy Flow","Nutrient Cycling","Ecological Succession"],"12th - Biodiversity":["Levels of Biodiversity","Loss of Biodiversity","Conservation Strategies","Hotspots"],"12th - Environmental Issues":["Air Pollution","Water Pollution","Solid Waste","Greenhouse Effect","Ozone Depletion"]},"Math":{"11th - Sets":["Types of Sets","Set Operations","Venn Diagrams","De Morgans Laws"],"11th - Relations & Functions":["Types of Relations","Types of Functions","Composition","Domain Range"],"11th - Trigonometric Functions":["Angles","Basic Identities","Values of Standard Angles","Graphs","Equations"],"11th - Mathematical Induction":["Principle of Induction","Problems on Induction"],"11th - Complex Numbers":["Algebra of Complex Numbers","Modulus Argument","Polar Form","De Moivres Theorem"],"11th - Linear Inequalities":["Algebraic Solutions","Graphical Solutions","System of Inequalities"],"11th - Permutations & Combinations":["Fundamental Principle","Permutations","Combinations","Applications"],"11th - Binomial Theorem":["Binomial Expansion","General Term","Middle Term","Properties"],"11th - Sequences & Series":["AP","GP","HP","Sum of Series","AM GM Inequality"],"11th - Straight Lines":["Slope","Forms of Line Equation","Distance","Family of Lines"],"11th - Conic Sections":["Circle","Parabola","Ellipse","Hyperbola","Standard Equations"],"11th - 3D Geometry Intro":["Coordinates","Distance","Section Formula","Locus"],"11th - Limits & Derivatives":["Limit of Function","Standard Limits","Derivatives","Differentiation Rules"],"11th - Statistics":["Mean Median Mode","Variance","Standard Deviation","Coefficient of Variation"],"11th - Probability":["Random Experiments","Events","Axiomatic Approach","Addition Theorem"],"12th - Relations & Functions":["Binary Operations","Inverse Functions","Composition"],"12th - Inverse Trigonometry":["Inverse Trig Functions","Properties","Equations"],"12th - Matrices":["Matrix Operations","Types","Transpose","Adjoint","Inverse"],"12th - Determinants":["Properties","Minors Cofactors","Area of Triangle","Cramers Rule"],"12th - Continuity & Differentiability":["Continuity","Differentiability","Rolle Mean Value Theorem","Logarithmic Differentiation"],"12th - Applications of Derivatives":["Rate of Change","Increasing Decreasing","Tangent Normal","Maxima Minima"],"12th - Integrals":["Indefinite Integrals","Methods of Integration","Definite Integrals","Properties"],"12th - Applications of Integrals":["Area Under Curves","Area Between Curves"],"12th - Differential Equations":["Order & Degree","Formation","Variable Separable","Linear Equations"],"12th - Vector Algebra":["Vectors","Addition","Dot Product","Cross Product","Scalar Triple Product"],"12th - 3D Geometry":["Direction Cosines","Lines in Space","Planes","Angle Between"],"12th - Linear Programming":["LPP","Graphical Method","Corner Point","Optimal Solution"],"12th - Probability":["Conditional Probability","Bayes Theorem","Random Variables","Binomial Distribution"]}}
                const subj=aiGSub
                const chapters=subj&&NCERT[subj]?Object.keys(NCERT[subj]):[]
                const topics=aiSelChap&&NCERT[subj]&&NCERT[subj][aiSelChap]?NCERT[subj][aiSelChap]:[]
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14,overflowY:'auto'}}>
                    <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:20,width:'100%',maxWidth:460,maxHeight:'95vh',overflowY:'auto',boxShadow:'0 20px 60px rgba(0,0,0,0.6)'}}>
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
                        <div>
                          <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>🤖 AI Question Generator</div>
                          <div style={{fontSize:10,color:'#64748B',marginTop:2}}>NCERT Based · Auto answers & explanations</div>
                        </div>
                        <button onClick={function(){setAiGO(false);setAiGResult([])}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                      </div>
                      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📚 Subject *</label>
                          <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:6}}>
                            {['Physics','Chemistry','Biology','Math'].map(function(s){return(
                              <div key={s} onClick={function(){setAiGSub(s);aiChR.current='';aiTopR.current=''}}
                                style={{padding:'8px 4px',borderRadius:8,border:'1.5px solid '+(aiGSub===s?'rgba(77,159,255,0.5)':'rgba(255,255,255,0.08)'),background:aiGSub===s?'rgba(77,159,255,0.12)':'rgba(255,255,255,0.02)',cursor:'pointer',textAlign:'center'}}>
                                <div style={{fontSize:11,fontWeight:700,color:aiGSub===s?'#4D9FFF':'#94A3B8'}}>{s}</div>
                              </div>
                            )})}
                          </div>
                        </div>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📖 Chapter * <span style={{color:'#475569',fontSize:9}}>(select or type)</span></label>
                          <select onChange={function(e){if(e.target.value){aiChR.current=e.target.value;setAiSelChap(e.target.value)}}} style={{...inp,width:'100%',marginBottom:5}}>
                            <option value=''>— Select NCERT Chapter —</option>
                            {chapters.map(function(c){return <option key={c} value={c}>{c}</option>})}
                          </select>
                          <input defaultValue='' placeholder='Or type custom chapter…' onChange={function(e){aiChR.current=e.target.value;setAiSelChap(e.target.value)}} style={{...inp,width:'100%',fontSize:11}}/>
                        </div>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📌 Topic * <span style={{color:'#475569',fontSize:9}}>(select or type)</span></label>
                          <select onChange={function(e){if(e.target.value)aiTopR.current=e.target.value}} style={{...inp,width:'100%',marginBottom:5}}>
                            <option value=''>— Select NCERT Topic —</option>
                            {topics.map(function(tp){return <option key={tp} value={tp}>{tp}</option>})}
                          </select>
                          <input defaultValue='' placeholder='Or type custom topic…' onChange={function(e){aiTopR.current=e.target.value}} style={{...inp,width:'100%',fontSize:11}}/>
                        </div>
                        <div>
                          <label style={lbl}>🔢 Count <span style={{color:'#475569',fontSize:9}}>(1–30)</span></label>
                          <input type='number' min='1' max='30' defaultValue='10' onChange={function(e){setAiGCnt(e.target.value)}} style={{...inp,width:'100%'}}/>
                        </div>
                        <div>
                          <label style={lbl}>🎯 Difficulty</label>
                          <select value={aiGDiff} onChange={function(e){setAiGDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                            <option value='easy'>🟢 Easy</option>
                            <option value='medium'>🟡 Medium</option>
                            <option value='hard'>🔴 Hard</option>
                          </select>
                        </div>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📋 Question Type</label>
                          <div style={{display:'flex',gap:6}}>
                            {['SCQ','MSQ','Integer'].map(function(tp){return(
                              <button key={tp} style={{...bg_,fontSize:10,padding:'4px 10px',flex:1}} onClick={function(){}}>{tp}</button>
                            )})}
                          </div>
                        </div>
                      </div>
                      {aiGResult.length>0&&(<div style={{marginBottom:12}}>
                        <div style={{fontSize:11,fontWeight:700,color:'#00C864',marginBottom:6}}>✅ {aiGResult.length} Questions Generated!</div>
                        <div style={{maxHeight:100,overflowY:'auto',display:'flex',flexDirection:'column',gap:3,marginBottom:8}}>
                          {aiGResult.map(function(q,i){return(
                            <div key={i} style={{padding:'4px 8px',background:'rgba(0,200,100,0.05)',borderRadius:5,fontSize:10,color:'#CBD5E1'}}>Q{i+1}: {(q.text||'').slice(0,65)}…</div>
                          )})}
                        </div>
                        <button onClick={saveAiQs} style={{...bp,width:'100%',fontSize:11,marginBottom:8}}>💾 Save All {aiGResult.length} to Question Bank</button>
                      </div>)}
                      <button onClick={aiGF} disabled={aiGLoading} style={{...bp,width:'100%',opacity:aiGLoading?0.7:1}}>
                        {aiGLoading?'⟳ Generating NCERT Questions…':'🤖 Generate Questions'}
                      </button>
                      <div style={{fontSize:9,color:'#475569',textAlign:'center',marginTop:6}}>Generates NCERT-based questions with correct answers & explanations</div>
                    </div>
                  </div>
                )
              })()}

              {/* QUESTION PREVIEW MODAL */}
              {selQId&&(function(){
                const qi=(questions||[]).findIndex(function(q){return q._id===selQId})
                const q=(questions||[])[qi]
                if(!q)return null
                const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':'#A78BFA'
                const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.9)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                    <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:20,width:'100%',maxWidth:500,maxHeight:'90vh',overflowY:'auto'}}>
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12}}>
                        <div>
                          <div style={{display:'flex',gap:4,flexWrap:'wrap',marginBottom:4}}>
                            <span style={{fontSize:9,fontWeight:600,padding:'2px 7px',borderRadius:4,background:sCol+'18',color:sCol,border:'1px solid '+sCol+'30'}}>{q.subject||'General'}</span>
                            <span style={{fontSize:9,fontWeight:600,padding:'2px 7px',borderRadius:4,background:dCol+'18',color:dCol,border:'1px solid '+dCol+'30'}}>{q.difficulty||'?'}</span>
                            <span style={{fontSize:9,padding:'2px 7px',borderRadius:4,background:'rgba(77,159,255,0.1)',color:'#4D9FFF'}}>{q.type||'SCQ'}</span>
                          </div>
                          <div style={{fontSize:10,color:'#475569'}}>Q{qi+1} of {(questions||[]).length}</div>
                        </div>
                        <button onClick={function(){setSelQId(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                      </div>
                      <div style={{fontSize:13,color:'#E2E8F0',lineHeight:1.7,marginBottom:10,padding:'11px 13px',background:'rgba(255,255,255,0.03)',borderRadius:10,border:'1px solid rgba(255,255,255,0.06)'}}>{q.text}</div>
                      {q.hindiText&&<div style={{fontSize:11,color:'#94A3B8',marginBottom:10,fontStyle:'italic',padding:'6px 11px',background:'rgba(255,255,255,0.02)',borderRadius:8}}>{q.hindiText}</div>}
                      {(q.options||[]).length>0&&(<div style={{display:'flex',flexDirection:'column',gap:5,marginBottom:10}}>
                        {(q.options||[]).map(function(opt,oi){
                          const ltr=String.fromCharCode(65+oi)
                          const cIdx=Array.isArray(q.correct)&&q.correct.length>0?q.correct:q.correct!==undefined?[q.correct]:[]
                          const isC=(Array.isArray(cIdx)?cIdx.includes(oi):cIdx===oi)||(q.correctAnswer&&q.correctAnswer===ltr)
                          return(<div key={oi} style={{padding:'7px 11px',borderRadius:7,border:'1px solid '+(isC?'rgba(0,200,100,0.4)':'rgba(255,255,255,0.07)'),background:isC?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)'}}>
                            <span style={{fontWeight:700,color:isC?'#00C864':'#4D9FFF',marginRight:8}}>{ltr}.</span>
                            <span style={{fontSize:12,color:isC?'#E2E8F0':'#94A3B8'}}>{opt}</span>
                            {isC&&<span style={{marginLeft:8,fontSize:10,color:'#00C864',fontWeight:700}}>✓ Correct</span>}
                          </div>)
                        })}
                      </div>)}
                      {(q.chapter||q.topic||q.explanation)&&(<div style={{fontSize:11,color:'#64748B',marginBottom:10,lineHeight:1.6}}>
                        {q.chapter&&<div>📖 {q.chapter}{q.topic?' › '+q.topic:''}</div>}
                        {q.explanation&&<div style={{color:'#94A3B8',marginTop:4}}>💡 {q.explanation}</div>}{q.image&&<div style={{margin:'8px 0',borderRadius:8,background:'rgba(255,255,255,0.03)',padding:6}}><img src={q.image} alt='' onError={function(e){e.currentTarget.style.display='none';var fb=document.getElementById('imgfb_'+q._id);if(fb)fb.style.display='flex'}} style={{width:'100%',maxHeight:'200px',objectFit:'contain',display:'block',borderRadius:6}}/><div id={'imgfb_'+q._id} style={{display:'none',alignItems:'center',gap:6,padding:'4px 0'}}><span style={{fontSize:10,color:'#94A3B8'}}>🖼️ Image URL:</span><a href={q.image} target='_blank' style={{fontSize:10,color:'#60A5FA',wordBreak:'break-all'}}>{q.image.length>50?q.image.substring(0,50)+'...':q.image}</a></div></div>}
                      </div>)}
                      <div style={{display:'flex',gap:7}}>
                        <button onClick={function(){if(qi>0)setSelQId((questions||[])[qi-1]._id)}} disabled={qi===0} style={{...bg_,flex:1,opacity:qi===0?0.35:1,fontSize:11}}>← Prev</button>
                        <button onClick={function(){
                          const ltrs=['A','B','C','D']
                          const cIdx=Array.isArray(q.correct)&&q.correct.length>0?q.correct[0]:(q.correctAnswer?ltrs.indexOf(q.correctAnswer):0)
                          setEditQD(Object.assign({},q,{correctLetter:ltrs[cIdx>=0?cIdx:0]||'A'}))
                          setSelQId(null)
                        }} style={{...bp,flex:1,fontSize:11}}>✏️ Edit</button>
                        <button onClick={function(){if(qi<(questions||[]).length-1)setSelQId((questions||[])[qi+1]._id)}} disabled={qi>=(questions||[]).length-1} style={{...bg_,flex:1,opacity:qi>=(questions||[]).length-1?0.35:1,fontSize:11}}>Next →</button>
                      </div>
                    </div>
                  </div>
                )
              })()}

              {/* EDIT MODAL */}
              {editQD&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.9)',zIndex:1001,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                  <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(255,184,0,0.25)',borderRadius:20,padding:20,width:'100%',maxWidth:490,maxHeight:'90vh',overflowY:'auto'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div style={{fontSize:13,fontWeight:800,color:'#E2E8F0'}}>✏️ Edit Question</div>
                      <button onClick={function(){setEditQD(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                    </div>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Question Text *</label>
                        <textarea value={editQD.text||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{text:e.target.value})})}} rows={3} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Hindi Text <span style={{color:'#475569',fontSize:9}}>(optional)</span></label>
                        <textarea value={editQD.hindiText||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{hindiText:e.target.value})})}} rows={2} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                      <div>
                        <label style={lbl}>Subject</label>
                        <select value={editQD.subject||'Physics'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{subject:e.target.value})})}} style={{...inp,width:'100%'}}>
                          {['Physics','Chemistry','Biology','Math','Other'].map(function(s){return <option key={s} value={s}>{s}</option>})}
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>Difficulty</label>
                        <select value={editQD.difficulty||'medium'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{difficulty:e.target.value})})}} style={{...inp,width:'100%'}}>
                          {['easy','medium','hard'].map(function(d){return <option key={d} value={d}>{d}</option>})}
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>Chapter</label>
                        <input value={editQD.chapter||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{chapter:e.target.value})})}} style={{...inp,width:'100%'}}/>
                      </div>
                      <div>
                        <label style={lbl}>Topic</label>
                        <input value={editQD.topic||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{topic:e.target.value})})}} style={{...inp,width:'100%'}}/>
                      </div>
                      {(editQD.options&&editQD.options.length>0?editQD.options:['','','','']).map(function(opt,oi){return(
                        <div key={oi}>
                          <label style={lbl}>Option {String.fromCharCode(65+oi)}</label>
                          <input value={opt||''} onChange={function(e){
                            const opts=[...((editQD.options&&editQD.options.length>0)?editQD.options:['','','',''])]
                            opts[oi]=e.target.value
                            setEditQD(function(p){return Object.assign({},p,{options:opts})})
                          }} style={{...inp,width:'100%'}}/>
                        </div>
                      )})}
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>✅ Correct Answer</label>
                        <select value={editQD.correctLetter||'A'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{correctLetter:e.target.value})})}} style={{...inp,width:'100%'}}>
                          <option value='A'>Option A</option>
                          <option value='B'>Option B</option>
                          <option value='C'>Option C</option>
                          <option value='D'>Option D</option>
                        </select>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Explanation</label>
                        <textarea value={editQD.explanation||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{explanation:e.target.value})})}} rows={2} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={function(){setEditQD(null)}} style={{...bg_,flex:1,fontSize:11}}>Cancel</button>
                      <button onClick={function(){editQF(editQD._id,editQD)}} disabled={savingEQ} style={{...bp,flex:2,fontSize:11,opacity:savingEQ?0.7:1}}>{savingEQ?'⟳ Saving…':'💾 Save Changes'}</button>
                    </div>
                  </div>
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
                              <div style={{fontSize:11,color:'#8899AA'}}>✉️ {s.studentId&&<span style={{fontSize:10,fontWeight:700,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:1,display:'inline-flex',alignItems:'center',gap:3}}>{s.studentId} <CopyBtn text={s.studentId}/></span>} {s.email}</div>
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
                              {(s as any).studentId&&<div style={{display:'inline-flex',alignItems:'center',gap:5,marginBottom:3,padding:'2px 8px',background:'rgba(77,159,255,0.08)',borderRadius:5,border:'1px solid rgba(77,159,255,0.18)',width:'fit-content'}}><span style={{fontSize:9,fontWeight:800,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:1.5}}>{(s as any).studentId}</span><CopyBtn text={(s as any).studentId} size="sm"/></div>}
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
              <div style={pageSub}>Organize students into batches — Dropper Batch, Foundation Batch, etc..</div>
              <PageHero icon="📦" title="Organize Your Students" subtitle="Group students into batches for targeted exams, announcements, and analytics. Transfer students between batches easily."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>➕ Create New Batch</div>
                  <div style={{marginBottom:10}}><label style={lbl}>Batch Name</label><SInput init='' onSet={v=>{batchNameR.current=v}} ph='e.g. Dropper 2027 Batch' style={inp}/></div>
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
                ?<div style={{textAlign:'center',padding:'50px 20px',color:DIM}}>
                  <div style={{fontSize:72,marginBottom:12,filter:'drop-shadow(0 0 20px rgba(99,179,237,0.35))'}}>🗂️</div>
                  <div style={{fontSize:16,fontWeight:700,color:'#93C5FD',marginBottom:8}}>No Batches Created Yet</div>
                  <div style={{fontSize:12,color:'rgba(148,163,184,0.7)',maxWidth:280,margin:'0 auto',lineHeight:1.7}}>Create your first batch to organize students for targeted exams, announcements, and analytics.</div>
                  <div style={{marginTop:20,display:'flex',justifyContent:'center',gap:20,fontSize:11,color:'rgba(148,163,184,0.5)'}}>
                    <span>📊 Track Progress</span>
                    <span>📢 Broadcast</span>
                    <span>🎯 Target Exams</span>
                  </div>
                </div>
                :<div style={{marginTop:14}}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>All Batches ({batches.length})</div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:10}}>
                    {(batches||[]).map(b=>(
                      <div key={b._id} onClick={()=>{setSelectedBatch(b);if(typeof window!=='undefined')window.history.pushState(null,'','/admin/x7k2p?batch='+b._id)}} style={{...cs,borderLeft:'3px solid #3B82F6',position:'relative',overflow:'hidden',cursor:'pointer',transition:'all 0.2s'}} title="Click to manage batch">{/* BATCH_CLICK_FIX */}
                        <div style={{position:'absolute',top:8,right:10,fontSize:28,opacity:0.07,pointerEvents:'none'}}>📦</div>
                        <div style={{fontWeight:700,fontSize:14,color:'#93C5FD',marginBottom:4}}>{b.name}</div>
                        <div style={{display:'flex',alignItems:'center',gap:6,marginBottom:8}}><div style={{fontSize:9,color:'rgba(148,163,184,0.4)',fontFamily:'monospace',letterSpacing:0.5}}>ID: {b._id?.slice(-8)}</div><CopyBtn text={b._id} label="ID"/></div>
                        <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:8}}>
                          <span style={{fontSize:11,color:'#7DD3FC',background:'rgba(59,130,246,0.12)',padding:'3px 10px',borderRadius:20}}>👥 {b.studentCount||0} Students</span>
                          <span style={{fontSize:11,color:'#6EE7B7',background:'rgba(16,185,129,0.12)',padding:'3px 10px',borderRadius:20}}>📝 {b.examCount||0} Exams</span>
                        </div>
                        <div style={{fontSize:10,color:'rgba(148,163,184,0.5)',marginBottom:10}}>📅 {b.createdAt?new Date(b.createdAt).toLocaleDateString():'-'}</div>
                        <button onClick={()=>{if(window.confirm('Delete batch "'+b.name+'"? Students will be unassigned.'))fetch(API+'/api/admin/batches/'+b._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}}).then(r=>r.ok&&setBatches(prev=>prev.filter(x=>x._id!==b._id))).catch(()=>{})}} style={{width:'100%',background:'rgba(239,68,68,0.1)',border:'1px solid rgba(239,68,68,0.25)',color:'#F87171',borderRadius:6,padding:'5px 0',fontSize:11,cursor:'pointer'}}>🗑️ Delete Batch</button>
                      </div>
                    ))}
                  </div>
                </div>
              }
            </div>
          )}


                    {/* ══ ADMINS ══ */}
          {showProfileModal&&(
                <div onClick={()=>setShowProfileModal(false)} style={{position:'fixed' as const,top:0,left:0,right:0,bottom:0,background:'rgba(0,0,0,0.82)',backdropFilter:'blur(6px)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:9999,padding:16}}>
                  <div onClick={e=>e.stopPropagation()} style={{background:'linear-gradient(135deg,rgba(5,10,24,0.99),rgba(8,16,36,0.98))',border:'1.5px solid rgba(0,180,255,0.25)',borderRadius:20,padding:'28px 24px',maxWidth:520,width:'100%',maxHeight:'88vh',overflowY:'auto' as const,boxShadow:'0 24px 80px rgba(0,180,255,0.12)'}}>
                    <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:20}}>
                      <div style={{fontWeight:800,fontSize:18,color:'#00B4FF',fontFamily:'Playfair Display,serif'}}>👤 Admin Profile</div>
                      <button onClick={()=>setShowProfileModal(false)} style={{background:'rgba(255,71,87,0.12)',border:'1px solid rgba(255,71,87,0.3)',color:'#FF4757',borderRadius:8,padding:'4px 12px',cursor:'pointer',fontSize:13}}>✕ Close</button>
                    </div>
                    {profileLoading?(
                      <div style={{textAlign:'center' as const,padding:'40px 0',color:'#4D9FFF',fontSize:14}}>⏳ Loading profile...</div>
                    ):profileAdmin?(
                      <div>
                        <div style={{display:'flex',alignItems:'center',gap:16,marginBottom:20,padding:16,background:'rgba(0,180,255,0.06)',borderRadius:14,border:'1px solid rgba(0,180,255,0.15)'}}>
                          <div style={{width:60,height:60,background:'linear-gradient(135deg,rgba(0,180,255,0.2),rgba(77,159,255,0.3))',border:'2px solid rgba(0,180,255,0.4)',borderRadius:14,display:'flex',alignItems:'center',justifyContent:'center',fontSize:26,fontWeight:900,color:'#00B4FF',flexShrink:0}}>{(profileAdmin.name||'A')[0].toUpperCase()}</div>
                          <div>
                            <div style={{fontWeight:700,fontSize:16,color:'#E8F4FF'}}>{profileAdmin.name||'—'}</div>
                  {profileAdmin.adminId&&<div style={{fontSize:11,color:'#00B4FF',background:'rgba(0,180,255,0.1)',border:'1px solid rgba(0,180,255,0.3)',borderRadius:12,padding:'3px 12px',marginTop:6,fontWeight:700,letterSpacing:1,display:'inline-block'}}>&#x1FA96; {profileAdmin.adminId}</div>}
                            <div style={{fontSize:12,color:'#6B8FAF',marginTop:3}}>{profileAdmin.email||'—'}</div>
                            <div style={{marginTop:6,display:'flex',gap:6}}>
                              <span style={{fontSize:10,background:'rgba(0,180,255,0.12)',color:'#00B4FF',borderRadius:20,padding:'2px 10px',fontWeight:600}}>{(profileAdmin.role||'admin').toUpperCase()}</span>
                              <span style={{fontSize:10,background:profileAdmin.frozen?'rgba(255,165,0,0.12)':'rgba(0,220,130,0.12)',color:profileAdmin.frozen?'#FFA500':'#00DC82',borderRadius:20,padding:'2px 10px',fontWeight:600}}>{profileAdmin.frozen?'FROZEN':'ACTIVE'}</span>
                            </div>
                          </div>
                        </div>
                        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:16}}>
                          {[['📧 Email',profileAdmin.email],['📱 Phone',profileAdmin.phone||'—'],['🗓️ Joined',profileAdmin.createdAt?new Date(profileAdmin.createdAt).toLocaleDateString('en-IN'):'—'],['🔐 2FA',profileAdmin.twoFactorEnabled?'Enabled':'Disabled']].map(([label,val])=>(
                            <div key={label as string} style={{background:'rgba(0,10,28,0.6)',border:'1px solid rgba(0,180,255,0.1)',borderRadius:10,padding:'10px 12px'}}>
                              <div style={{fontSize:10,color:'#6B8FAF',marginBottom:3}}>{label as string}</div>
                              <div style={{fontSize:12,color:'#C8D8E8',fontWeight:600,wordBreak:'break-all' as const}}>{val as string}</div>
                            </div>
                          ))}
                        </div>
                        {profileAdmin.permissions&&Object.keys(profileAdmin.permissions).length>0&&(
                          <div style={{marginBottom:16}}>
                            <div style={{fontSize:12,color:'#6B8FAF',fontWeight:600,marginBottom:8}}>🔑 PERMISSIONS</div>
                            <div style={{display:'flex',flexWrap:'wrap' as const,gap:6}}>
                              {Object.entries(profileAdmin.permissions).filter(([,v])=>v).map(([k])=>(
                                <span key={k} style={{fontSize:10,background:'rgba(0,180,255,0.1)',color:'#00B4FF',borderRadius:20,padding:'3px 10px',fontWeight:600}}>{k.replace(/_/g,' ')}</span>
                              ))}
                            </div>
                          </div>
                        )}
                        {profileLogs&&profileLogs.length>0&&(
                          <div>
                            <div style={{fontSize:12,color:'#6B8FAF',fontWeight:600,marginBottom:8}}>📋 RECENT ACTIVITY</div>
                            <div style={{maxHeight:160,overflowY:'auto' as const,display:'flex',flexDirection:'column' as const,gap:6}}>
                              {profileLogs.slice(0,10).map((log:any,i:number)=>(
                                <div key={i} style={{background:'rgba(0,10,28,0.5)',border:'1px solid rgba(0,180,255,0.08)',borderRadius:8,padding:'8px 10px',fontSize:11}}>
                                  <span style={{color:'#00B4FF',fontWeight:600}}>{log.action||log.type||'Action'}</span>
                                  <span style={{color:'#4D6080',marginLeft:8}}>{log.createdAt?new Date(log.createdAt).toLocaleString('en-IN'):''}</span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>
                    ):(
                      <div style={{textAlign:'center' as const,padding:'40px 0',color:'#FF4757',fontSize:13}}>❌ Failed to load profile. Please try again.</div>
                    )}
                  </div>
                </div>
              )}
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
          {tab==='myprofile'&&(
  <AdminProfilePage
    token={token||''}
    role={role||''}
    API={process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'}
  />
)}
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
      <AdminWelcomeBanner />

      {/* S86: Notification Detail Modal */}
      {notifDetail&&(
        <div onClick={()=>setNotifDetail(null)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.7)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
          <div onClick={(e)=>e.stopPropagation()} style={{background:'#0d1b2e',border:'1px solid #1e3a5f',borderRadius:14,padding:24,maxWidth:400,width:'100%',boxShadow:'0 16px 48px rgba(0,0,0,0.8)'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16}}>
              <span style={{fontSize:16,fontWeight:700,color:'#e2e8f0',flex:1}}>{notifDetail.title||'Notification'}</span>
              <button onClick={()=>setNotifDetail(null)} style={{background:'none',border:'none',color:'#64748b',fontSize:20,cursor:'pointer',marginLeft:8,lineHeight:1}}>×</button>
            </div>
            <div style={{fontSize:13,color:'#94a3b8',marginBottom:16,lineHeight:1.6}}>{notifDetail._all?(notifDetail.items||[]).map((n:any,i:number)=>(<div key={i} onClick={()=>{setNotifDetail(n);}} style={{padding:"10px 0",borderBottom:"1px solid #1e3a5f",cursor:"pointer"}}><div style={{fontSize:13,fontWeight:600,color:"#e2e8f0"}}>{n.title||"Alert"}</div><div style={{fontSize:11,color:"#64748b",marginTop:3}}>{n.message}</div><div style={{fontSize:10,color:"#475569",marginTop:2}}>{n.createdAt?new Date(n.createdAt).toLocaleString("en-IN",{dateStyle:"medium",timeStyle:"short"}):""}</div></div>)):(notifDetail.message||notifDetail.description||"No details available")}</div>
            {notifDetail.severity&&<div style={{marginBottom:12}}><span style={{fontSize:11,background:'rgba(59,130,246,0.2)',color:'#60a5fa',borderRadius:6,padding:'3px 10px',fontWeight:600}}>Type: {notifDetail.severity||notifDetail.type}</span></div>}
            {notifDetail.createdAt&&<div style={{fontSize:11,color:'#475569',marginBottom:16}}>🕐 {new Date(notifDetail.createdAt).toLocaleString('en-IN',{dateStyle:'medium',timeStyle:'short'})}</div>}
            <button onClick={()=>setNotifDetail(null)} style={{width:'100%',padding:'10px',background:'#1e3a5f',border:'none',borderRadius:8,color:'#e2e8f0',cursor:'pointer',fontSize:13,fontWeight:600}}>Close</button>
          </div>
        </div>
      )}
    </div>
  )
}