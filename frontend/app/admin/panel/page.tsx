'use client'
import { useState, useEffect, useRef, useCallback, memo } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Design Tokens ──
const ACC='#4D9FFF', DARK='#020B14', CARD='rgba(0,18,36,0.86)'
const BOR='rgba(77,159,255,0.20)', DIM='#4A7090'
const SUC='#00C48C', DNG='#FF4D4D', WRN='#FFB84D', GOLD='#FFD700'
const TS='#E8F4FF', BG='linear-gradient(160deg,#020B14 0%,#010810 60%,#000508 100%)'

// ── Auth helpers (no lib/auth dependency) ──
const _gt=():string=>{try{return localStorage.getItem('pr_token')||''}catch{return''}}
const _gr=():string=>{try{return localStorage.getItem('pr_role')||''}catch{return''}}
const _ca=():void=>{try{localStorage.removeItem('pr_token');localStorage.removeItem('pr_role')}catch{}}

// ── Permission → Feature mapping ──
// Each permission key maps to which nav sections it unlocks
const PERM_NAV: Record<string,string[]> = {
  create_exam:       ['exams','create_exam','templates','bulk_creator'],
  edit_exam:         ['exams'],
  delete_exam:       ['exams'],
  manage_questions:  ['questions','smart_gen','pyq_bank'],
  ban_student:       ['students','batches','custom_fields'],
  view_results:      ['results','leaderboard','analytics'],
  export_data:       ['reports','qbank_stats','subj_rank'],
  send_announcements:['announcements','email_tmpl'],
  view_audit_logs:   ['audit'],
  manage_features:   ['features'],
  manage_branding:   ['branding','maintenance'],
  view_snapshots:    ['cheating','snapshots','integrity','proct_pdf'],
  impersonate:       ['students'],
}

// ── All possible nav items ──
const ALL_NAV = [
  {id:'dashboard',    ico:'📊', lbl:'Dashboard',          grp:'Overview',       always:true},
  {id:'exams',        ico:'📝', lbl:'All Exams',           grp:'Exams',          always:false},
  {id:'create_exam',  ico:'➕', lbl:'Create Exam',         grp:'Exams',          always:false},
  {id:'templates',    ico:'📋', lbl:'Exam Templates',      grp:'Exams',          always:false},
  {id:'bulk_creator', ico:'⚡', lbl:'Bulk Creator',        grp:'Exams',          always:false},
  {id:'questions',    ico:'❓', lbl:'Question Bank',       grp:'Questions',      always:false},
  {id:'smart_gen',    ico:'🤖', lbl:'Smart Generator',     grp:'Questions',      always:false},
  {id:'pyq_bank',     ico:'📚', lbl:'PYQ Bank',            grp:'Questions',      always:false},
  {id:'students',     ico:'👥', lbl:'Students',            grp:'Students',       always:false},
  {id:'batches',      ico:'📦', lbl:'Batches',             grp:'Students',       always:false},
  {id:'custom_fields',ico:'📋', lbl:'Reg Fields',          grp:'Students',       always:false},
  {id:'results',      ico:'📈', lbl:'Results',             grp:'Results',        always:false},
  {id:'leaderboard',  ico:'🏆', lbl:'Leaderboard',         grp:'Results',        always:false},
  {id:'analytics',    ico:'📉', lbl:'Analytics',           grp:'Results',        always:false},
  {id:'reports',      ico:'📊', lbl:'Reports & Export',    grp:'Results',        always:false},
  {id:'cheating',     ico:'🚨', lbl:'Anti-Cheat Logs',     grp:'Proctoring',     always:false},
  {id:'snapshots',    ico:'📷', lbl:'Snapshots',           grp:'Proctoring',     always:false},
  {id:'integrity',    ico:'🤖', lbl:'AI Integrity',        grp:'Proctoring',     always:false},
  {id:'proct_pdf',    ico:'📄', lbl:'Proctoring PDF',      grp:'Proctoring',     always:false},
  {id:'announcements',ico:'📢', lbl:'Announcements',       grp:'Communication',  always:false},
  {id:'email_tmpl',   ico:'📧', lbl:'Email Templates',     grp:'Communication',  always:false},
  {id:'audit',        ico:'📋', lbl:'Audit Logs',          grp:'Logs',           always:false},
  {id:'features',     ico:'🚩', lbl:'Feature Flags',       grp:'Settings',       always:false},
  {id:'branding',     ico:'🎨', lbl:'Branding',            grp:'Settings',       always:false},
  {id:'maintenance',  ico:'🔧', lbl:'Maintenance',         grp:'Settings',       always:false},
  {id:'qbank_stats',  ico:'📊', lbl:'QB Statistics',       grp:'Reports',        always:false},
  {id:'subj_rank',    ico:'🏅', lbl:'Subject Rankings',    grp:'Reports',        always:false},
]

// ── PR4 Split Block Logo — Blue+Cyan T1 (CORRECT LOGO) ──
function PRLogo({size=36}:{size?:number}) {
  const b=Math.round(size*0.94)
  const p=Math.round(b*0.63)
  const f=Math.round(p*0.52)
  const r=Math.round(p*0.28)
  return (
    <div style={{position:'relative',width:b,height:b,flexShrink:0,display:'inline-flex'}}>
      <div style={{
        position:'absolute',top:0,left:0,width:p,height:p,borderRadius:r,
        background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#030810',boxShadow:'0 4px 16px rgba(77,159,255,0.45)'
      }}>P</div>
      <div style={{
        position:'absolute',bottom:0,right:0,width:p,height:p,borderRadius:r,
        background:'linear-gradient(135deg,#0A2540,#0D3560)',
        border:'2px solid rgba(77,159,255,0.7)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#4D9FFF',boxShadow:'0 4px 16px rgba(77,159,255,0.22)'
      }}>R</div>
    </div>
  )
}

// ── Galaxy Canvas Background ──
function GalaxyBg() {
  const ref=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const c=ref.current;if(!c)return
    const ctx=c.getContext('2d')!
    let raf:number,W=0,H=0
    const resize=()=>{W=c.width=window.innerWidth;H=c.height=window.innerHeight}
    resize();window.addEventListener('resize',resize)
    const stars=Array.from({length:240},()=>({
      x:Math.random()*window.innerWidth,y:Math.random()*window.innerHeight,
      r:Math.random()*1.5+0.2,o:Math.random()*0.7+0.15,
      s:Math.random()*0.006+0.002,d:Math.random()>0.5?1:-1
    }))
    const draw=()=>{
      ctx.clearRect(0,0,W,H)
      const g=ctx.createRadialGradient(W/2,H/2,0,W/2,H/2,W*0.85)
      g.addColorStop(0,'#021222');g.addColorStop(0.5,'#010C18');g.addColorStop(1,'#000508')
      ctx.fillStyle=g;ctx.fillRect(0,0,W,H)
      // Nebula 1
      const n1=ctx.createRadialGradient(W*0.2,H*0.3,0,W*0.2,H*0.3,W*0.38)
      n1.addColorStop(0,'rgba(77,159,255,0.055)');n1.addColorStop(1,'transparent')
      ctx.fillStyle=n1;ctx.fillRect(0,0,W,H)
      // Nebula 2
      const n2=ctx.createRadialGradient(W*0.78,H*0.65,0,W*0.78,H*0.65,W*0.32)
      n2.addColorStop(0,'rgba(90,50,200,0.04)');n2.addColorStop(1,'transparent')
      ctx.fillStyle=n2;ctx.fillRect(0,0,W,H)
      // Stars
      stars.forEach(s=>{
        s.o+=s.s*s.d;if(s.o>0.9||s.o<0.1)s.d*=-1
        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(190,225,255,${s.o})`;ctx.fill()
      })
      raf=requestAnimationFrame(draw)
    }
    draw()
    return()=>{cancelAnimationFrame(raf);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={ref} style={{position:'fixed',inset:0,zIndex:0,pointerEvents:'none'}}/>
}

// ── Mobile-keyboard-safe Input (memo) ──
const SInput=memo(function SInput({init='',onSet,style,ph,type='text',disabled=false}:{init?:string;onSet:(v:string)=>void;style?:any;ph?:string;type?:string;disabled?:boolean}){
  const [v,setV]=useState(init)
  useEffect(()=>{setV(init)},[init])
  return <input type={type} value={v} disabled={disabled} placeholder={ph} style={style} onChange={e=>{const x=e.target.value;setV(x);onSet(x)}}/>
})
const STextarea=memo(function STextarea({init='',onSet,style,ph,rows=4}:{init?:string;onSet:(v:string)=>void;style?:any;ph?:string;rows?:number}){
  const [v,setV]=useState(init)
  useEffect(()=>{setV(init)},[init])
  return <textarea value={v} rows={rows} placeholder={ph} style={style} onChange={e=>{const x=e.target.value;setV(x);onSet(x)}}/>
})
const SSelect=memo(function SSelect({val,onChange,opts,style}:{val:string;onChange:(v:string)=>void;opts:{v:string;l:string}[];style?:any}){
  return <select value={val} onChange={e=>onChange(e.target.value)} style={style}>{opts.map(o=><option key={o.v} value={o.v}>{o.l}</option>)}</select>
})

// ── Badge Component ──
function Badge({label,col}:{label:string;col:string}) {
  return <span style={{fontSize:10,fontWeight:700,padding:'2px 8px',borderRadius:20,background:`${col}22`,color:col,border:`1px solid ${col}44`,letterSpacing:0.5}}>{label}</span>
}

// ── Shared styles ──
const cs:any={background:CARD,border:`1px solid ${BOR}`,borderRadius:12,padding:16,marginBottom:12,backdropFilter:'blur(12px)'}
const inp:any={background:'rgba(0,30,60,0.6)',border:`1px solid ${BOR}`,borderRadius:8,padding:'10px 12px',color:TS,fontSize:13,fontFamily:'Inter,sans-serif',width:'100%',outline:'none'}
const bp:any={background:`linear-gradient(135deg,${ACC},#0099FF)`,border:'none',borderRadius:8,padding:'10px 18px',color:'#030810',fontWeight:700,fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif'}
const bg_:any={background:'rgba(77,159,255,0.10)',border:`1px solid ${BOR}`,borderRadius:8,padding:'9px 14px',color:ACC,fontWeight:600,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif'}
const lbl:any={display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,letterSpacing:0.5,textTransform:'uppercase' as const}
const pageTitle:any={fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:22,color:TS,marginBottom:4}
const pageSub:any={fontSize:12,color:DIM}

// ── Main Component ──
export default function AdminPanel() {
  const router=useRouter()
  const [token,setToken]=useState('')
  const [role,setRole]=useState('')
  const [mounted,setMounted]=useState(false)
  const [authReady,setAuthReady]=useState(false)
  const [tab,setTab]=useState('dashboard')
  const [sideOpen,setSideOpen]=useState(false)
  const [loading,setLoading]=useState(true)
  const [toast,setToast]=useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)

  // ── User data & permissions ──
  const [adminUser,setAdminUser]=useState<any>(null)
  const [permissions,setPermissions]=useState<Record<string,boolean>>({})
  const [allowedNav,setAllowedNav]=useState<typeof ALL_NAV>([])

  // ── Data states ──
  const [students,setStudents]=useState<any[]>([])
  const [exams,setExams]=useState<any[]>([])
  const [questions,setQuestions]=useState<any[]>([])
  const [results,setResults]=useState<any[]>([])
  const [announcements,setAnnouncements]=useState<any[]>([])
  const [stats,setStats]=useState<any>(null)
  const [dataLoading,setDataLoading]=useState(false)

  // Refs for forms
  const eTitleR=useRef(''),eDateR=useRef(''),eDurR=useRef('200'),eMarksR=useRef('720')
  const [creatingE,setCreatingE]=useState(false)
  const qTxtR=useRef(''),qAnsR=useRef('A')
  const [qSubj,setQSubj]=useState('Physics'),[qDiff,setQDiff]=useState('medium'),[qType,setQType]=useState('SCQ')
  const qChapR=useRef(''),qTopicR=useRef(''),qA=useRef(''),qB=useRef(''),qC=useRef(''),qD=useRef(''),qExpR=useRef('')
  const [savingQ,setSavingQ]=useState(false)
  const [annTxt,setAnnTxt]=useState(''),annTitleR=useRef('')
  const [sendingAnn,setSendingAnn]=useState(false)

  // Toast helper
  const T=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{
    setToast({msg,tp});setTimeout(()=>setToast(null),4500)
  },[])

  // ── AUTH CHECK ──
  useEffect(()=>{
    const t=_gt(),r=_gr()
    if(!t||!['admin','superadmin'].includes(r)){router.replace('/login');return}
    setToken(t);setRole(r);setMounted(true)
  },[router])

  // ── FETCH USER + PERMISSIONS ──
  useEffect(()=>{
    if(!token||!mounted)return
    const init=async()=>{
      try{
        const res=await fetch(`${API}/api/auth/me`,{headers:{Authorization:`Bearer ${token}`}})
        if(res.ok){
          const d=await res.json()
          const u=d.user||d
          setAdminUser(u)
          // Read permissions from user object
          const rawPerms: Record<string,boolean> = u.permissions||{}
          setPermissions(rawPerms)
          // Build allowed nav from permissions
          const unlockedIds=new Set<string>(['dashboard']) // dashboard always visible
          Object.entries(rawPerms).forEach(([key,val])=>{
            if(val&&PERM_NAV[key])PERM_NAV[key].forEach(id=>unlockedIds.add(id))
          })
          const filtered=ALL_NAV.filter(n=>n.always||unlockedIds.has(n.id))
          setAllowedNav(filtered)
        }
      }catch{}
      setAuthReady(true)
    }
    init()
  },[token,mounted])

  // ── FETCH DATA ──
  const fetchData=useCallback(async()=>{
    if(!token)return
    setDataLoading(true)
    const get=async(url:string)=>{
      try{const r=await fetch(url,{headers:{Authorization:`Bearer ${token}`}});return r.ok?r.json():null}catch{return null}
    }
    const getFirst=async(...urls:string[])=>{
      for(const u of urls){try{const r=await fetch(u,{headers:{Authorization:`Bearer ${token}`}});if(r.ok){const d=await r.json();if(d)return d}}catch{}}
      return null
    }
    const [us,ex,qs,rs,an,st]=await Promise.all([
      getFirst(`${API}/api/admin/users`,`${API}/api/admin/students`),
      get(`${API}/api/exams`),
      get(`${API}/api/questions`),
      getFirst(`${API}/api/results`,`${API}/api/admin/results`),
      getFirst(`${API}/api/admin/announcements`,`${API}/api/announcements`),
      getFirst(`${API}/api/admin/stats`,`${API}/api/admin/dashboard`),
    ])
    if(Array.isArray(us))setStudents(us)
    else if(us?.students)setStudents(us.students)
    if(Array.isArray(ex))setExams(ex)
    if(Array.isArray(qs))setQuestions(qs)
    if(Array.isArray(rs))setResults(rs)
    if(Array.isArray(an))setAnnouncements(an)
    if(st)setStats(st)
    setDataLoading(false);setLoading(false)
  },[token])

  useEffect(()=>{if(authReady&&token)fetchData()},[authReady,token])

  // ── LOGOUT ──
  const logout=useCallback(()=>{_ca();router.replace('/login')},[router])

  // ── CREATE EXAM ──
  const createExam=useCallback(async()=>{
    const title=eTitleR.current,date=eDateR.current
    if(!title||!date){T('Exam title and date required','e');return}
    setCreatingE(true)
    try{
      const body={title,scheduledAt:new Date(date).toISOString(),totalMarks:parseInt(eMarksR.current)||720,duration:parseInt(eDurR.current)||200,subject:'NEET',type:'NEET',difficulty:'Mixed'}
      const res=await fetch(`${API}/api/exams`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(body)})
      const d=await res.json()
      if(res.ok||res.status===201){T('Exam created successfully!','s');setTimeout(()=>fetchData(),600)}
      else T(d?.message||'Failed to create exam','e')
    }catch{T('Network error','e')}
    setCreatingE(false)
  },[token,T,fetchData])

  // ── ADD QUESTION ──
  const addQ=useCallback(async()=>{
    if(!qTxtR.current){T('Question text required','e');return}
    setSavingQ(true)
    try{
      const body={text:qTxtR.current,subject:qSubj,difficulty:qDiff,type:qType,chapter:qChapR.current||undefined,topic:qTopicR.current||undefined,options:['SCQ','MSQ'].includes(qType)?[qA.current,qB.current,qC.current,qD.current].filter(Boolean):undefined,correctAnswer:qAnsR.current,explanation:qExpR.current||undefined}
      const res=await fetch(`${API}/api/questions`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(body)})
      const d=await res.json()
      if(res.ok||res.status===201){T('Question added!','s');setTimeout(()=>fetchData(),600)}
      else T(d?.message||'Failed to add question','e')
    }catch{T('Network error','e')}
    setSavingQ(false)
  },[token,qSubj,qDiff,qType,T,fetchData])

  // ── SEND ANNOUNCEMENT ──
  const sendAnn=useCallback(async()=>{
    if(!annTitleR.current||!annTxt){T('Title and message required','e');return}
    setSendingAnn(true)
    try{
      const body={title:annTitleR.current,message:annTxt,type:'general'}
      const res=await fetch(`${API}/api/admin/announcements`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(body)})
      if(res.ok){T('Announcement sent!','s');setAnnTxt('');annTitleR.current='';fetchData()}
      else T('Failed to send','e')
    }catch{T('Network error','e')}
    setSendingAnn(false)
  },[token,annTxt,T,fetchData])

  // ── BAN/UNBAN STUDENT ──
  const banStudent=useCallback(async(id:string,reason:string)=>{
    try{
      await fetch(`${API}/api/admin/ban/${id}`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({reason,banType:'permanent'})})
      T('Student banned','s');fetchData()
    }catch{T('Failed','e')}
  },[token,T,fetchData])

  // ── NAV GROUPS ──
  const navGroups=[...new Set(allowedNav.map(n=>n.grp))]
  const hasPermission=(key:string)=>permissions[key]===true

  // ── LOADING SPLASH (correct PR Split Block logo) ──
  if(!mounted||!authReady){
    return (
      <div style={{minHeight:'100vh',background:BG,display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',gap:20,fontFamily:'Inter,sans-serif'}}>
        <GalaxyBg/>
        <div style={{position:'relative',zIndex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:16}}>
          <PRLogo size={72}/>
          <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:20,background:`linear-gradient(90deg,${ACC},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',letterSpacing:0.5}}>
            ProveRank
          </div>
          <div style={{fontSize:13,color:DIM,animation:'pulse 1s infinite'}}>Loading your panel…</div>
        </div>
        <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');@keyframes pulse{0%,100%{opacity:0.4}50%{opacity:1}}`}</style>
      </div>
    )
  }

  // ── MAIN RENDER ──
  return (
    <div style={{background:BG,minHeight:'100vh',color:TS,fontFamily:'Inter,sans-serif',position:'relative'}}>
      <GalaxyBg/>

      {/* Decorative hexagons */}
      <div style={{position:'fixed',top:-60,left:-60,fontSize:300,color:'rgba(77,159,255,0.025)',pointerEvents:'none',zIndex:0,lineHeight:1}}>⬡</div>
      <div style={{position:'fixed',bottom:-60,right:-60,fontSize:300,color:'rgba(77,159,255,0.025)',pointerEvents:'none',zIndex:0,lineHeight:1}}>⬡</div>

      {/* Global Styles */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:0.5}50%{opacity:1}}
        @keyframes slideIn{from{transform:translateX(-100%)}to{transform:translateX(0)}}
        @keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:4px;height:4px}
        ::-webkit-scrollbar-track{background:rgba(0,22,40,0.4)}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.28);border-radius:4px}
        input,textarea,select{color-scheme:dark}
        .nav-btn:hover{background:rgba(77,159,255,0.12) !important;color:#4D9FFF !important}
        .card-hover:hover{border-color:rgba(77,159,255,0.38) !important;transform:translateY(-1px);transition:all 0.2s}
      `}</style>

      {/* TOAST */}
      {toast&&(
        <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9999,padding:'14px 24px',fontWeight:700,fontSize:13,background:toast.tp==='s'?`linear-gradient(90deg,${SUC},#00a87a)`:toast.tp==='w'?`linear-gradient(90deg,${WRN},#e6a200)`:`linear-gradient(90deg,${DNG},#cc0000)`,color:toast.tp==='w'?'#000':'#fff',textAlign:'center',boxShadow:'0 4px 30px rgba(0,0,0,0.5)',animation:'fadeIn 0.3s ease'}}>
          {toast.tp==='e'?'❌':toast.tp==='w'?'⚠️':'✅'} {toast.msg}
        </div>
      )}

      {/* TOP NAVBAR */}
      <div style={{position:'sticky',top:0,zIndex:100,background:'rgba(0,10,24,0.95)',backdropFilter:'blur(20px)',borderBottom:`1px solid ${BOR}`,padding:'0 16px',height:58,display:'flex',alignItems:'center',justifyContent:'space-between',boxShadow:'0 2px 20px rgba(0,0,0,0.35)'}}>
        {/* Left */}
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <button onClick={()=>setSideOpen(p=>!p)} style={{background:'none',border:'none',color:TS,fontSize:20,cursor:'pointer',padding:'4px 6px',borderRadius:6}}>☰</button>
          <div style={{display:'flex',alignItems:'center',gap:8}}>
            <PRLogo size={32}/>
            <div>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,background:`linear-gradient(90deg,${ACC},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1}}>
                ProveRank
              </div>
              <div style={{fontSize:10,fontWeight:700,letterSpacing:1.5,color:ACC,lineHeight:1.2}}>
                ⚡ ADMIN
              </div>
            </div>
          </div>
        </div>
        {/* Right */}
        <div style={{display:'flex',gap:8,alignItems:'center'}}>
          {dataLoading&&<span style={{fontSize:11,color:DIM,animation:'pulse 1s infinite'}}>⟳</span>}
          <span style={{fontSize:12,color:DIM}}>{adminUser?.name||adminUser?.email||'Admin'}</span>
          <button onClick={logout} style={{background:DNG,border:'none',borderRadius:6,padding:'6px 14px',color:'#fff',fontWeight:700,fontSize:12,cursor:'pointer'}}>Logout</button>
        </div>
      </div>

      {/* SIDEBAR */}
      {sideOpen&&(
        <div onClick={()=>setSideOpen(false)} style={{position:'fixed',inset:0,zIndex:200,background:'rgba(0,0,0,0.5)',backdropFilter:'blur(4px)'}}/>
      )}
      <div style={{position:'fixed',top:0,left:0,height:'100vh',width:240,zIndex:201,transform:sideOpen?'translateX(0)':'translateX(-100%)',transition:'transform 0.3s ease',background:'rgba(0,10,22,0.97)',backdropFilter:'blur(20px)',borderRight:`1px solid ${BOR}`,display:'flex',flexDirection:'column',paddingTop:58,overflowY:'auto'}}>
        {/* Admin info */}
        <div style={{padding:'16px 14px',borderBottom:`1px solid ${BOR}`}}>
          <div style={{display:'flex',alignItems:'center',gap:10}}>
            <div style={{width:36,height:36,borderRadius:'50%',background:`linear-gradient(135deg,${ACC},#0099FF)`,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:900,fontSize:14,color:'#030810'}}>
              {(adminUser?.name||'A')[0].toUpperCase()}
            </div>
            <div>
              <div style={{fontSize:13,fontWeight:600,color:TS}}>{adminUser?.name||'Admin'}</div>
              <div style={{fontSize:10,color:DIM}}>{adminUser?.email||''}</div>
            </div>
          </div>
          <div style={{marginTop:10,padding:'6px 10px',background:'rgba(77,159,255,0.08)',borderRadius:8,border:`1px solid ${BOR}`,fontSize:11,color:DIM}}>
            ⚡ Your Role: <span style={{color:ACC,fontWeight:700}}>Admin</span>
            <br/>
            <span style={{color:'rgba(77,159,255,0.5)',fontSize:10}}>Permissions set by SuperAdmin</span>
          </div>
        </div>

        {/* Nav Items — only permitted ones */}
        <div style={{flex:1,padding:'8px 0',overflowY:'auto'}}>
          {allowedNav.length<=1?(
            <div style={{padding:'20px 14px',textAlign:'center'}}>
              <div style={{fontSize:28,marginBottom:8}}>🔒</div>
              <div style={{fontSize:12,color:DIM,lineHeight:1.6}}>No features enabled.<br/>Contact SuperAdmin to<br/>enable permissions.</div>
            </div>
          ):(
            navGroups.map(grp=>{
              const items=allowedNav.filter(n=>n.grp===grp)
              if(!items.length)return null
              return (
                <div key={grp}>
                  <div style={{fontSize:9,fontWeight:700,color:'rgba(107,143,175,0.45)',letterSpacing:1.5,textTransform:'uppercase' as const,padding:'10px 14px 4px'}}>{grp}</div>
                  {items.map(n=>(
                    <button key={n.id} className="nav-btn" onClick={()=>{setTab(n.id);setSideOpen(false)}} style={{width:'100%',textAlign:'left' as const,background:tab===n.id?'rgba(77,159,255,0.15)':'transparent',border:'none',borderLeft:tab===n.id?`3px solid ${ACC}`:'3px solid transparent',padding:'10px 14px',color:tab===n.id?ACC:TS,fontSize:13,cursor:'pointer',display:'flex',alignItems:'center',gap:10,fontFamily:'Inter,sans-serif',fontWeight:tab===n.id?600:400,transition:'all 0.15s'}}>
                      <span style={{fontSize:15}}>{n.ico}</span>
                      {n.lbl}
                    </button>
                  ))}
                </div>
              )
            })
          )}
        </div>

        {/* Bottom */}
        <div style={{padding:14,borderTop:`1px solid ${BOR}`}}>
          <div style={{fontSize:11,color:'rgba(0,196,140,0.6)',fontWeight:600,marginBottom:8}}>● All Systems Live</div>
          <button onClick={logout} style={{width:'100%',background:'rgba(255,77,77,0.12)',border:`1px solid rgba(255,77,77,0.3)`,borderRadius:8,padding:'9px 14px',color:DNG,fontWeight:700,fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>🚪 Logout</button>
        </div>
      </div>

      {/* MAIN CONTENT */}
      <div style={{padding:'20px 16px',maxWidth:1000,margin:'0 auto',position:'relative',zIndex:1,animation:'fadeIn 0.4s ease'}}>

        {/* ══ DASHBOARD ══ */}
        {tab==='dashboard'&&(
          <div>
            <div style={{marginBottom:20}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:26,color:TS,lineHeight:1.2}}>
                Welcome, {adminUser?.name||'Admin'} 👋
              </div>
              <div style={{fontSize:13,color:DIM,marginTop:4}}>ProveRank Admin Panel · {adminUser?.email}</div>
            </div>

            {/* Dashboard Stats — Always visible for observation */}
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:12,marginBottom:20}}>
              <div className="card-hover" style={{...cs,textAlign:'center' as const}}>
                <div style={{fontSize:28}}>👥</div>
                <div style={{fontSize:22,fontWeight:700,color:ACC,margin:'4px 0'}}>{dataLoading?'…':students.length||stats?.totalStudents||0}</div>
                <div style={{fontSize:11,color:DIM}}>Total Students</div>
              </div>
              <div className="card-hover" style={{...cs,textAlign:'center' as const}}>
                <div style={{fontSize:28}}>📝</div>
                <div style={{fontSize:22,fontWeight:700,color:'#A78BFA',margin:'4px 0'}}>{dataLoading?'…':exams.length||stats?.totalExams||0}</div>
                <div style={{fontSize:11,color:DIM}}>Total Exams</div>
              </div>
              <div className="card-hover" style={{...cs,textAlign:'center' as const}}>
                <div style={{fontSize:28}}>❓</div>
                <div style={{fontSize:22,fontWeight:700,color:'#00E5A0',margin:'4px 0'}}>{dataLoading?'…':questions.length||stats?.totalQuestions||0}</div>
                <div style={{fontSize:11,color:DIM}}>Questions</div>
              </div>
              <div className="card-hover" style={{...cs,textAlign:'center' as const}}>
                <div style={{fontSize:28}}>✅</div>
                <div style={{fontSize:22,fontWeight:700,color:GOLD,margin:'4px 0'}}>{dataLoading?'…':results.length||stats?.totalAttempts||0}</div>
                <div style={{fontSize:11,color:DIM}}>Attempts</div>
              </div>
              <div className="card-hover" style={{...cs,textAlign:'center' as const}}>
                <div style={{fontSize:28}}>🟢</div>
                <div style={{fontSize:22,fontWeight:700,color:SUC,margin:'4px 0'}}>{dataLoading?'…':stats?.activeStudents||'—'}</div>
                <div style={{fontSize:11,color:DIM}}>Active Today</div>
              </div>
            </div>

            {/* Role info card */}
            <div style={{...cs,border:`1px solid rgba(77,159,255,0.3)`}}>
              <div style={{fontSize:14,fontWeight:700,color:ACC,marginBottom:8}}>⚡ Your Permissions</div>
              <div style={{display:'flex',flexWrap:'wrap' as const,gap:6}}>
                {Object.entries(permissions).filter(([,v])=>v).length===0
                  ?<div style={{fontSize:12,color:DIM}}>No permissions assigned yet. Ask SuperAdmin.</div>
                  :Object.entries(permissions).filter(([,v])=>v).map(([key])=>(
                    <Badge key={key} label={key.replace(/_/g,' ')} col={ACC}/>
                  ))
                }
              </div>
            </div>

            {/* Quick shortcuts for allowed features */}
            {allowedNav.length>1&&(
              <div>
                <div style={{fontSize:12,color:DIM,marginBottom:10,marginTop:4}}>Quick Access</div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(120px,1fr))',gap:10}}>
                  {allowedNav.filter(n=>n.id!=='dashboard').slice(0,6).map(n=>(
                    <button key={n.id} className="card-hover" onClick={()=>setTab(n.id)} style={{...cs,border:`1px solid ${BOR}`,textAlign:'center' as const,cursor:'pointer',background:CARD,padding:'16px 10px'}}>
                      <div style={{fontSize:24,marginBottom:6}}>{n.ico}</div>
                      <div style={{fontSize:11,color:TS,fontWeight:600}}>{n.lbl}</div>
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* ══ ALL EXAMS ══ */}
        {(tab==='exams'||tab==='create_exam'||tab==='templates'||tab==='bulk_creator')&&(hasPermission('create_exam')||hasPermission('edit_exam')||hasPermission('delete_exam'))&&(
          <div>
            <div style={pageTitle}>📝 Exam Management</div>
            <div style={pageSub}>{exams.length} exams in system</div>

            {tab==='create_exam'&&(
              <div style={{...cs,marginTop:16}}>
                <div style={{fontSize:15,fontWeight:700,color:TS,marginBottom:14}}>➕ Create New Exam</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Exam Title *</label><SInput init='' onSet={v=>{eTitleR.current=v}} ph='e.g. NEET Full Mock Test 1' style={inp}/></div>
                  <div><label style={lbl}>Schedule Date & Time *</label><SInput init='' onSet={v=>{eDateR.current=v}} type='datetime-local' style={inp}/></div>
                  <div><label style={lbl}>Duration (minutes)</label><SInput init='200' onSet={v=>{eDurR.current=v}} type='number' style={inp}/></div>
                  <div><label style={lbl}>Total Marks</label><SInput init='720' onSet={v=>{eMarksR.current=v}} type='number' style={inp}/></div>
                </div>
                <button onClick={createExam} disabled={creatingE} style={{...bp,marginTop:14,width:'100%',opacity:creatingE?0.7:1}}>
                  {creatingE?'⟳ Creating…':'➕ Create Exam'}
                </button>
              </div>
            )}

            <div style={{marginTop:16}}>
              {exams.length===0
                ?<div style={{...cs,textAlign:'center' as const,padding:32}}><div style={{fontSize:36}}>📝</div><div style={{color:DIM,marginTop:8}}>No exams yet</div></div>
                :exams.map((e:any)=>(
                  <div key={e._id} className="card-hover" style={{...cs,marginBottom:8}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap' as const,gap:8}}>
                      <div>
                        <div style={{fontWeight:600,fontSize:14,color:TS}}>{e.title}</div>
                        <div style={{fontSize:11,color:DIM,marginTop:2}}>{e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():''} · {e.duration||200} min · {e.totalMarks||720} marks</div>
                      </div>
                      <Badge label={e.status||'draft'} col={e.status==='active'?SUC:e.status==='completed'?DIM:WRN}/>
                    </div>
                  </div>
                ))
              }
            </div>
          </div>
        )}

        {/* ══ QUESTION BANK ══ */}
        {tab==='questions'&&hasPermission('manage_questions')&&(
          <div>
            <div style={pageTitle}>❓ Question Bank</div>
            <div style={pageSub}>{questions.length} questions in bank</div>
            <div style={{...cs,marginTop:16}}>
              <div style={{fontSize:15,fontWeight:700,color:TS,marginBottom:14}}>➕ Add Question</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                <div style={{gridColumn:'1/-1'}}><label style={lbl}>Question Text *</label><STextarea init='' onSet={v=>{qTxtR.current=v}} ph='Type the full question text…' rows={3} style={{...inp,resize:'vertical' as const}}/></div>
                <div><label style={lbl}>Subject</label><SSelect val={qSubj} onChange={setQSubj} opts={[{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'}]} style={inp}/></div>
                <div><label style={lbl}>Difficulty</label><SSelect val={qDiff} onChange={setQDiff} opts={[{v:'easy',l:'🟢 Easy'},{v:'medium',l:'🟡 Medium'},{v:'hard',l:'🔴 Hard'}]} style={inp}/></div>
                <div><label style={lbl}>Type</label><SSelect val={qType} onChange={setQType} opts={[{v:'SCQ',l:'SCQ — Single Correct'},{v:'MSQ',l:'MSQ — Multiple Correct'},{v:'Integer',l:'Integer Type'}]} style={inp}/></div>
                <div><label style={lbl}>Correct Answer</label><SSelect val={qAnsR.current||'A'} onChange={v=>{qAnsR.current=v}} opts={[{v:'A',l:'A'},{v:'B',l:'B'},{v:'C',l:'C'},{v:'D',l:'D'}]} style={inp}/></div>
                <div><label style={lbl}>Chapter</label><SInput init='' onSet={v=>{qChapR.current=v}} ph='e.g. Electrostatics' style={inp}/></div>
                <div><label style={lbl}>Topic</label><SInput init='' onSet={v=>{qTopicR.current=v}} ph='e.g. Coulombs Law' style={inp}/></div>
                {['SCQ','MSQ'].includes(qType)&&<>
                  <div><label style={lbl}>Option A</label><SInput init='' onSet={v=>{qA.current=v}} ph='Option A' style={inp}/></div>
                  <div><label style={lbl}>Option B</label><SInput init='' onSet={v=>{qB.current=v}} ph='Option B' style={inp}/></div>
                  <div><label style={lbl}>Option C</label><SInput init='' onSet={v=>{qC.current=v}} ph='Option C' style={inp}/></div>
                  <div><label style={lbl}>Option D</label><SInput init='' onSet={v=>{qD.current=v}} ph='Option D' style={inp}/></div>
                </>}
                <div style={{gridColumn:'1/-1'}}><label style={lbl}>Explanation (optional)</label><STextarea init='' onSet={v=>{qExpR.current=v}} ph='Explain the correct answer…' rows={2} style={{...inp,resize:'vertical' as const}}/></div>
              </div>
              <button onClick={addQ} disabled={savingQ} style={{...bp,width:'100%',marginTop:14,opacity:savingQ?0.7:1}}>
                {savingQ?'⟳ Saving…':'➕ Add to Bank'}
              </button>
            </div>
            <div style={{marginTop:16}}>
              {questions.slice(0,15).map((q:any,i:number)=>(
                <div key={q._id||i} className="card-hover" style={{...cs,marginBottom:8}}>
                  <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:4}}>{q.text?.substring(0,120)}{(q.text?.length||0)>120?'…':''}</div>
                  <div style={{display:'flex',gap:6,flexWrap:'wrap' as const}}>
                    <Badge label={q.subject} col={q.subject==='Physics'?ACC:q.subject==='Chemistry'?'#FF6B9D':SUC}/>
                    <Badge label={q.difficulty||'medium'} col={q.difficulty==='hard'?DNG:q.difficulty==='easy'?SUC:WRN}/>
                    <Badge label={q.type||'SCQ'} col={ACC}/>
                  </div>
                </div>
              ))}
              {questions.length===0&&<div style={{...cs,textAlign:'center' as const,padding:32,color:DIM}}>No questions yet. Add your first question above.</div>}
            </div>
          </div>
        )}

        {/* ══ STUDENTS ══ */}
        {tab==='students'&&hasPermission('ban_student')&&(
          <div>
            <div style={pageTitle}>👥 Students</div>
            <div style={pageSub}>{students.length} registered students</div>
            <div style={{marginTop:16}}>
              {students.slice(0,20).map((s:any)=>(
                <div key={s._id} className="card-hover" style={{...cs,marginBottom:8}}>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap' as const,gap:8}}>
                    <div>
                      <div style={{fontWeight:600,fontSize:13,color:TS}}>{s.name}</div>
                      <div style={{fontSize:11,color:DIM}}>{s.email} · {s.phone||'—'}</div>
                    </div>
                    <div style={{display:'flex',gap:6,alignItems:'center'}}>
                      {s.banned?<Badge label='Banned' col={DNG}/>:<Badge label='Active' col={SUC}/>}
                      {!s.banned&&hasPermission('ban_student')&&(
                        <button onClick={()=>banStudent(s._id,'Admin action')} style={{...bg_,fontSize:11,padding:'4px 10px',color:DNG,border:`1px solid rgba(255,77,77,0.3)`}}>Ban</button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
              {students.length===0&&<div style={{...cs,textAlign:'center' as const,padding:32,color:DIM}}>No students registered yet.</div>}
            </div>
          </div>
        )}

        {/* ══ RESULTS ══ */}
        {tab==='results'&&hasPermission('view_results')&&(
          <div>
            <div style={pageTitle}>📈 Results</div>
            <div style={pageSub}>{results.length} total results</div>
            <div style={{marginTop:16}}>
              {results.slice(0,20).map((r:any,i:number)=>(
                <div key={r._id||i} className="card-hover" style={{...cs,marginBottom:8}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap' as const,gap:8}}>
                    <div>
                      <div style={{fontWeight:600,fontSize:13,color:TS}}>{r.studentName||r.student?.name||'Student'}</div>
                      <div style={{fontSize:11,color:DIM}}>{r.examTitle||r.exam?.title||'Exam'}</div>
                    </div>
                    <div style={{textAlign:'right' as const}}>
                      <div style={{fontWeight:700,fontSize:14,color:ACC}}>{r.score||0}/{r.totalMarks||720}</div>
                      <div style={{fontSize:11,color:DIM}}>Rank #{r.rank||'—'}</div>
                    </div>
                  </div>
                </div>
              ))}
              {results.length===0&&<div style={{...cs,textAlign:'center' as const,padding:32,color:DIM}}>No results yet.</div>}
            </div>
          </div>
        )}

        {/* ══ ANNOUNCEMENTS ══ */}
        {tab==='announcements'&&hasPermission('send_announcements')&&(
          <div>
            <div style={pageTitle}>📢 Announcements</div>
            <div style={pageSub}>Send notices to all students</div>
            <div style={{...cs,marginTop:16}}>
              <div style={{fontSize:15,fontWeight:700,color:TS,marginBottom:14}}>📤 New Announcement</div>
              <div style={{marginBottom:12}}><label style={lbl}>Title *</label><SInput init='' onSet={v=>{annTitleR.current=v}} ph='Announcement title…' style={inp}/></div>
              <div style={{marginBottom:12}}><label style={lbl}>Message *</label><STextarea init={annTxt} onSet={setAnnTxt} ph='Type your announcement…' rows={4} style={{...inp,resize:'vertical' as const}}/></div>
              <button onClick={sendAnn} disabled={sendingAnn} style={{...bp,width:'100%',opacity:sendingAnn?0.7:1}}>
                {sendingAnn?'⟳ Sending…':'📢 Send to All Students'}
              </button>
            </div>
            <div style={{marginTop:16}}>
              {announcements.slice(0,10).map((a:any,i:number)=>(
                <div key={a._id||i} style={{...cs,marginBottom:8}}>
                  <div style={{fontWeight:600,fontSize:13,color:TS}}>{a.title}</div>
                  <div style={{fontSize:12,color:DIM,marginTop:4}}>{a.message?.substring(0,120)}</div>
                  <div style={{fontSize:10,color:'rgba(77,159,255,0.4)',marginTop:4}}>{a.createdAt?new Date(a.createdAt).toLocaleDateString():''}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ══ NO PERMISSION FALLBACK ══ */}
        {!['dashboard','exams','create_exam','templates','bulk_creator','questions','students','batches','custom_fields','results','leaderboard','analytics','reports','cheating','snapshots','integrity','proct_pdf','announcements','email_tmpl','audit','features','branding','maintenance','qbank_stats','subj_rank'].includes(tab)&&(
          <div style={{...cs,textAlign:'center' as const,padding:40}}>
            <div style={{fontSize:40,marginBottom:12}}>🔒</div>
            <div style={{fontSize:16,fontWeight:700,color:TS,marginBottom:8}}>Feature Not Accessible</div>
            <div style={{fontSize:13,color:DIM}}>This section is not enabled for your account.<br/>Contact your SuperAdmin to enable access.</div>
          </div>
        )}

        {/* Sections that need permission but not granted */}
        {tab==='students'&&!hasPermission('ban_student')&&(
          <div style={{...cs,textAlign:'center' as const,padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Student management permission not granted.</div></div>
        )}
        {tab==='questions'&&!hasPermission('manage_questions')&&(
          <div style={{...cs,textAlign:'center' as const,padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Question bank permission not granted.</div></div>
        )}
        {(tab==='exams'||tab==='create_exam')&&!hasPermission('create_exam')&&!hasPermission('edit_exam')&&(
          <div style={{...cs,textAlign:'center' as const,padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Exam management permission not granted.</div></div>
        )}
        {tab==='results'&&!hasPermission('view_results')&&(
          <div style={{...cs,textAlign:'center' as const,padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Results view permission not granted.</div></div>
        )}
        {tab==='announcements'&&!hasPermission('send_announcements')&&(
          <div style={{...cs,textAlign:'center' as const,padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Announcements permission not granted.</div></div>
        )}

      </div>
    </div>
  )
}
