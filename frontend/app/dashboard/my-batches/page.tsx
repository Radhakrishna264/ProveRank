'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type BatchMeta = {
  _id: string; name: string; examType: string; thumbnail: string;
  enrolledAt: string; expiresAt: string; daysLeft: number;
  testsCompleted: number; totalTests: number; progress: number;
  lastAccessedAt: string; daysSinceAccess: number; streak: number;
  isExpired: boolean; isCompleted: boolean; isWishlisted?: boolean;
  isFree: boolean; rating: number; language: string; difficulty: string;
}
type Stats = { total: number; testsCompleted: number; activeBatches: number; certificates: number }
type Activity = { _id: string; type: string; title: string; message: string; icon: string; createdAt: string }
type LBEntry = { name: string; testsCompleted: number; avgScore: number; streak: number; bestRank: number | null }

const ECOLS: Record<string,string> = {
  NEET:'#4D9FFF',JEE:'#9B59B6',CUET:'#27AE60',
  'Class 11':'#E67E22','Class 12':'#E74C3C',
  Foundation:'#00D4FF','Crash Course':'#FF6B6B',Other:'#7F8C8D'
}
const TIPS = [
  { i:'🎯', t:'Daily Practice', d:'Attempt at least 1 test daily to maintain your streak and improve retention.' },
  { i:'📊', t:'Review Mistakes', d:'Always revisit wrong answers after each test — that\'s where real learning happens.' },
]

function MilkyWayCanvas() {
  const r = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const cv = r.current; if(!cv)return
    const ctx = cv.getContext('2d'); if(!ctx)return
    let af: number, t = 0
    const resize = () => { cv.width=window.innerWidth; cv.height=window.innerHeight }
    resize(); window.addEventListener('resize', resize)
    const stars = Array.from({length:900},()=>({
      x:Math.random(),y:Math.random(),
      r:Math.random()<0.02?1.5:Math.random()<0.08?0.9:0.42,
      phase:Math.random()*Math.PI*2,spd:0.3+Math.random()*3,
      col:Math.random()<0.015?'#CAD7FF':Math.random()<0.06?'#F8F7FF':'#FFF4EA',
      inArm:Math.random()<0.55
    }))
    const draw = () => {
      t+=0.003; const W=cv.width,H=cv.height
      ctx.clearRect(0,0,W,H); ctx.fillStyle='#020816'; ctx.fillRect(0,0,W,H)
      stars.forEach(s => {
        const x=s.x*W,y=s.y*H,tw=0.3+0.7*Math.abs(Math.sin(t*s.spd+s.phase))
        const alpha=s.inArm?tw*0.7:tw*0.45
        ctx.beginPath(); ctx.arc(x,y,s.r,0,Math.PI*2)
        ctx.fillStyle=s.col+Math.round(alpha*255).toString(16).padStart(2,'0')
        ctx.fill()
      })
      af=requestAnimationFrame(draw)
    }
    draw(); return()=>{cancelAnimationFrame(af);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={r} style={{position:'fixed',inset:0,zIndex:0,pointerEvents:'none'}} />
}

// ── Circular Progress Ring ──
function ProgressRing({pct,ec,size=56}:{pct:number;ec:string;size?:number}) {
  const R=size*0.4, C=2*Math.PI*R, dash=(pct/100)*C
  return (
    <div style={{position:'relative',width:size,height:size,flexShrink:0}}>
      <svg width={size} height={size} style={{transform:'rotate(-90deg)'}}>
        <circle cx={size/2} cy={size/2} r={R} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={size*0.1}/>
        <circle cx={size/2} cy={size/2} r={R} fill="none" stroke={ec} strokeWidth={size*0.1}
          strokeDasharray={`${dash} ${C}`} strokeLinecap="round"
          style={{transition:'stroke-dasharray 0.8s ease'}}/>
      </svg>
      <div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',fontSize:size*0.2,fontWeight:800,color:'#F0F8FF'}}>{pct}%</div>
    </div>
  )
}

// ── Horizontal Progress Bar ──
function ProgressBar({pct,ec}:{pct:number;ec:string}) {
  return (
    <div style={{width:'100%'}}>
      <div style={{display:'flex',justifyContent:'space-between',marginBottom:5}}>
        <span style={{fontSize:10,color:'rgba(160,200,240,0.55)'}}>Progress</span>
        <span style={{fontSize:10,fontWeight:700,color:ec}}>{pct}%</span>
      </div>
      <div style={{height:6,background:'rgba(255,255,255,0.08)',borderRadius:3,overflow:'hidden'}}>
        <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${ec},${ec}BB)`,borderRadius:3,transition:'width 0.8s ease',boxShadow:`0 0 8px ${ec}60`}}/>
      </div>
      <div style={{display:'flex',justifyContent:'space-between',marginTop:4}}>
        <span style={{fontSize:9,color:'rgba(160,200,240,0.35)'}}>0 tests</span>
        <span style={{fontSize:9,color:'rgba(160,200,240,0.35)'}}>Goal: 100%</span>
      </div>
    </div>
  )
}

// ── Batch Leaderboard Modal ──
function BatchLeaderboardModal({batchId,batchName,tok,onClose}:{batchId:string;batchName:string;tok:string;onClose:()=>void}) {
  const [lb,setLb]=useState<LBEntry[]>([])
  const [myRank,setMyRank]=useState(0)
  const [total,setTotal]=useState(0)
  const [loading,setLoading]=useState(true)
  useEffect(()=>{
    fetch(`${API}/api/my-batches/${batchId}/leaderboard`,{headers:{Authorization:`Bearer ${tok}`}})
      .then(r=>r.json()).then(d=>{setLb(d.leaderboard||[]);setMyRank(d.myRank||0);setTotal(d.total||0)})
      .catch(()=>{}).finally(()=>setLoading(false))
  },[batchId,tok])
  return (
    <div style={{position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
      <div style={{background:'rgba(4,12,30,0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:24,maxWidth:400,width:'100%',maxHeight:'80vh',overflow:'hidden',display:'flex',flexDirection:'column',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)'}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#F0F8FF'}}>🏆 Batch Leaderboard</div>
            <div style={{fontSize:11,color:'rgba(160,200,240,0.5)',marginTop:2,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis',maxWidth:260}}>{batchName}</div>
          </div>
          <button onClick={onClose} style={{background:'transparent',border:'none',color:'rgba(160,200,240,0.5)',cursor:'pointer',fontSize:22}}>×</button>
        </div>
        {myRank>0&&<div style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:12,padding:'10px 14px',marginBottom:14,display:'flex',alignItems:'center',gap:10}}>
          <span style={{fontSize:20}}>🎯</span>
          <div><div style={{fontSize:13,fontWeight:700,color:'#4D9FFF'}}>Your Rank: #{myRank} of {total}</div><div style={{fontSize:10,color:'rgba(160,200,240,0.5)'}}>Keep attempting tests to improve!</div></div>
        </div>}
        <div style={{overflowY:'auto',flex:1}}>
          {loading?<div style={{textAlign:'center',padding:30,color:'rgba(160,200,240,0.4)'}}>Loading...</div>:
          lb.length===0?<div style={{textAlign:'center',padding:30,color:'rgba(160,200,240,0.4)',fontSize:12}}>No students enrolled yet</div>:
          lb.map((entry,i)=>(
            <div key={i} style={{display:'flex',alignItems:'center',gap:10,padding:'10px 0',borderBottom:'1px solid rgba(77,159,255,0.06)'}}>
              <div style={{width:28,height:28,borderRadius:'50%',background:i===0?'linear-gradient(135deg,#FFD700,#FFA000)':i===1?'linear-gradient(135deg,#C0C0C0,#9E9E9E)':i===2?'linear-gradient(135deg,#CD7F32,#A0522D)':'rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:i<3?14:10,fontWeight:900,flexShrink:0,color:i<3?'#000':'rgba(160,200,240,0.5)'}}>
                {i===0?'🥇':i===1?'🥈':i===2?'🥉':i+1}
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:12,fontWeight:700,color:'#F0F8FF'}}>{entry.name}</div>
                <div style={{fontSize:10,color:'rgba(160,200,240,0.45)'}}>📝 {entry.testsCompleted} tests · ⭐ {entry.avgScore.toFixed(1)}% avg · 🔥 {entry.streak} streak</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

// ── Activity Feed Section ──
function ActivityFeed({batchId,tok}:{batchId:string;tok:string}) {
  const [activities,setActivities]=useState<Activity[]>([])
  useEffect(()=>{
    fetch(`${API}/api/batch-activity/${batchId}`,{headers:{Authorization:`Bearer ${tok}`}})
      .then(r=>r.json()).then(d=>setActivities(d.activities||[])).catch(()=>{})
  },[batchId,tok])
  if(activities.length===0)return null
  return (
    <div style={{marginTop:14}}>
      <div style={{fontSize:10,fontWeight:700,color:'rgba(160,200,240,0.45)',textTransform:'uppercase',letterSpacing:1,marginBottom:8}}>📢 What's New</div>
      {activities.map(a=>(
        <div key={a._id} style={{display:'flex',gap:8,alignItems:'flex-start',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.06)'}}>
          <span style={{fontSize:16,flexShrink:0}}>{a.icon}</span>
          <div>
            <div style={{fontSize:11,fontWeight:700,color:'#F0F8FF'}}>{a.title}</div>
            {a.message&&<div style={{fontSize:10,color:'rgba(160,200,240,0.55)',marginTop:2}}>{a.message}</div>}
            <div style={{fontSize:9,color:'rgba(160,200,240,0.3)',marginTop:3}}>{new Date(a.createdAt).toLocaleDateString()}</div>
          </div>
        </div>
      ))}
    </div>
  )
}

// ── Main Page ──
export default function MyBatchesPage() {
  const router=useRouter()
  const [batches,setBatches]=useState<BatchMeta[]>([])
  const [stats,setStats]=useState<Stats>({total:0,testsCompleted:0,activeBatches:0,certificates:0})
  const [tab,setTab]=useState<'active'|'completed'|'wishlist'>('active')
  const [tok,setTok]=useState('')
  const [loading,setLoading]=useState(true)
  const [darkMode,setDarkMode]=useState(true)
  const [progressView,setProgressView]=useState<'ring'|'bar'>('ring')
  const [lbBatch,setLbBatch]=useState<{id:string;name:string}|null>(null)
  const [notifGranted,setNotifGranted]=useState(false)
  const [notifAsked,setNotifAsked]=useState(false)
  const [isClient,setIsClient]=useState(false)

  const BG=darkMode?'transparent':'rgba(240,244,248,0.95)'
  const CARD=darkMode?'rgba(4,12,30,0.95)':'rgba(255,255,255,0.95)'
  const BORDER=darkMode?'rgba(255,255,255,0.08)':'rgba(0,0,0,0.1)'
  const TEXT=darkMode?'#F0F8FF':'#1a1a2e'
  const SUB=darkMode?'rgba(180,200,220,0.55)':'rgba(0,0,0,0.5)'

  useEffect(()=>{
    setIsClient(true)
    const t=localStorage.getItem('pr_token')||''
    setTok(t); fetchData(t)
    // Check notification permission
    if(typeof window !== 'undefined' && 'Notification' in window){
      setNotifGranted(Notification.permission==='granted')
      setNotifAsked(Notification.permission!=='default')
    }
  },[])

  const fetchData=async(t:string)=>{
    setLoading(true)
    try{
      const[bRes,sRes]=await Promise.all([
        fetch(`${API}/api/my-batches`,{headers:{Authorization:`Bearer ${t}`}}),
        fetch(`${API}/api/my-batches/stats`,{headers:{Authorization:`Bearer ${t}`}})
      ])
      const bd=await bRes.json(); const sd=await sRes.json()
      setBatches(bd.batches||[]); setStats(sd)
    }catch{}finally{setLoading(false)}
  }

  const accessBatch=async(id:string)=>{
    if(!tok)return
    try{
      const r=await fetch(`${API}/api/my-batches/${id}/access`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      const d=await r.json()
      if(d.streak&&d.streak>0){
        // Browser push notification for streak
        if(notifGranted&&typeof window!=='undefined'&&'Notification' in window){
          new Notification('🔥 ProveRank Streak!',{
            body:`You're on a ${d.streak}-day streak! Keep it up!`,
            icon:'/favicon.ico'
          })
        }
      }
    }catch{}
  }

  const requestNotifPermission=async()=>{
    if(typeof window==='undefined'||!('Notification' in window))return
    const perm=await Notification.requestPermission()
    setNotifGranted(perm==='granted')
    setNotifAsked(true)
    if(perm==='granted'){
      new Notification('✅ ProveRank Notifications Enabled!',{
        body:'You will now receive streak reminders and batch updates.',
        icon:'/favicon.ico'
      })
    }
  }

  const filtered=batches.filter(b=>{
    if(tab==='active')return !b.isExpired&&!b.isCompleted
    if(tab==='completed')return b.isExpired||b.isCompleted
    if(tab==='wishlist')return b.isWishlisted
    return true
  })

  const lastAccessed=batches.filter(b=>!b.isExpired).sort((a,b)=>new Date(b.lastAccessedAt).getTime()-new Date(a.lastAccessedAt).getTime())[0]

  const inp={padding:'8px 12px',background:darkMode?'rgba(255,255,255,0.06)':'rgba(0,0,0,0.05)',border:`1px solid ${BORDER}`,borderRadius:10,color:TEXT,fontSize:12,outline:'none' as const}

  return (
    <div style={{minHeight:'100vh',color:TEXT,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden'}}>
      {darkMode&&<MilkyWayCanvas/>}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700;800&display=swap');
        *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
        @keyframes slideUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes pulse{0%,100%{opacity:1}50%{opacity:0.6}}
      `}</style>

      {/* Batch Leaderboard Modal */}
      {lbBatch&&tok&&<BatchLeaderboardModal batchId={lbBatch.id} batchName={lbBatch.name} tok={tok} onClose={()=>setLbBatch(null)}/>}

      {/* STICKY TOP BAR */}
      <div style={{position:'sticky',top:0,zIndex:50,background:darkMode?'rgba(2,8,22,0.96)':'rgba(255,255,255,0.96)',backdropFilter:'blur(22px)',borderBottom:`1px solid ${BORDER}`,padding:'10px 14px',display:'flex',alignItems:'center',gap:10}}>
        <button onClick={()=>router.back()} style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:'#4D9FFF',fontSize:20,flexShrink:0}}>←</button>
        <div style={{flex:1}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>My Batches</div>
          <div style={{fontSize:10,color:SUB}}>Your enrolled test series</div>
        </div>
        <div style={{display:'flex',gap:7,alignItems:'center'}}>
          {/* Progress View Toggle */}
          <button onClick={()=>setProgressView(v=>v==='ring'?'bar':'ring')}
            style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:9,padding:'5px 10px',cursor:'pointer',color:'#4D9FFF',fontSize:10,fontWeight:700}}>
            {progressView==='ring'?'📊 Bar':'⭕ Ring'}
          </button>
          <button onClick={()=>setDarkMode(d=>!d)} style={{background:'rgba(77,159,255,0.1)',border:`1px solid ${BORDER}`,borderRadius:9,padding:'5px 9px',cursor:'pointer',color:TEXT,fontSize:12}}>{darkMode?'☀️':'🌙'}</button>
          <button onClick={()=>router.push('/dashboard/test-series')} style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,padding:'7px 12px',cursor:'pointer',color:'#fff',fontSize:11,fontWeight:700,flexShrink:0}}>+ Explore</button>
        </div>
      </div>

      <div style={{position:'relative',zIndex:2,padding:'14px 14px 80px',maxWidth:900,margin:'0 auto'}}>

        {/* NOTIFICATION BANNER */}
        {!notifAsked&&'Notification' in window&&(
          <div style={{background:'rgba(77,159,255,0.08)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:14,padding:'12px 16px',marginBottom:14,display:'flex',alignItems:'center',gap:12,animation:'slideUp 0.4s ease'}}>
            <span style={{fontSize:22,flexShrink:0}}>🔔</span>
            <div style={{flex:1}}>
              <div style={{fontSize:12,fontWeight:700,color:'#F0F8FF'}}>Enable Streak Notifications</div>
              <div style={{fontSize:10,color:SUB}}>Get notified when you're on a streak — daily reminders to keep going!</div>
            </div>
            <button onClick={requestNotifPermission}
              style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,padding:'7px 14px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,flexShrink:0}}>Enable</button>
            <button onClick={()=>setNotifAsked(true)} style={{background:'transparent',border:'none',color:SUB,cursor:'pointer',fontSize:18,flexShrink:0}}>×</button>
          </div>
        )}

        {/* STATS BAR */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8,marginBottom:16}}>
          {[{i:'📚',l:'Enrolled',v:stats.total,c:'#4D9FFF'},{i:'✅',l:'Tests Done',v:stats.testsCompleted,c:'#27AE60'},{i:'⚡',l:'Active',v:stats.activeBatches,c:'#E67E22'},{i:'🏆',l:'Certificates',v:stats.certificates,c:'#FFD700'}].map((s,i)=>(
            <div key={i} style={{background:CARD,border:`1px solid ${s.c}18`,borderRadius:14,padding:'10px 8px',textAlign:'center',backdropFilter:'blur(16px)',animation:`slideUp ${0.2+i*0.08}s ease`}}>
              <div style={{fontSize:18,marginBottom:3}}>{s.i}</div>
              <div style={{fontSize:20,fontWeight:900,color:s.c}}>{s.v}</div>
              <div style={{fontSize:9,color:SUB}}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* CONTINUE WHERE YOU LEFT OFF */}
        {lastAccessed&&(
          <div style={{background:CARD,border:`1px solid ${ECOLS[lastAccessed.examType]||'#4D9FFF'}28`,borderRadius:18,padding:'16px',marginBottom:14,backdropFilter:'blur(16px)',animation:'slideUp 0.35s ease'}}>
            <div style={{fontSize:10,fontWeight:700,color:'rgba(160,200,240,0.45)',textTransform:'uppercase',letterSpacing:1,marginBottom:10}}>▶️ Continue Where You Left Off</div>
            <div style={{display:'flex',alignItems:'center',gap:12}}>
              <div style={{width:48,height:48,borderRadius:13,background:`${ECOLS[lastAccessed.examType]||'#4D9FFF'}18`,border:`1px solid ${ECOLS[lastAccessed.examType]||'#4D9FFF'}28`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:24,flexShrink:0}}>
                {lastAccessed.examType==='NEET'?'🩺':lastAccessed.examType==='JEE'?'⚙️':'📚'}
              </div>
              <div style={{flex:1,minWidth:0}}>
                <div style={{fontSize:13,fontWeight:700,color:TEXT,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis'}}>{lastAccessed.name}</div>
                <div style={{fontSize:10,color:SUB,marginTop:2}}>🔥 {lastAccessed.streak}-day streak · Last: {lastAccessed.daysSinceAccess===0?'Today':lastAccessed.daysSinceAccess+' days ago'}</div>
                <div style={{marginTop:8}}>
                  {progressView==='ring'
                    ?<div style={{display:'flex',alignItems:'center',gap:8}}><ProgressRing pct={lastAccessed.progress} ec={ECOLS[lastAccessed.examType]||'#4D9FFF'} size={44}/><span style={{fontSize:11,color:SUB}}>{lastAccessed.testsCompleted}/{lastAccessed.totalTests} tests</span></div>
                    :<ProgressBar pct={lastAccessed.progress} ec={ECOLS[lastAccessed.examType]||'#4D9FFF'}/>
                  }
                </div>
              </div>
              <button onClick={()=>{accessBatch(lastAccessed._id);router.push('/dashboard/exams')}}
                style={{background:`linear-gradient(135deg,${ECOLS[lastAccessed.examType]||'#4D9FFF'},${ECOLS[lastAccessed.examType]||'#4D9FFF'}BB)`,border:'none',borderRadius:12,padding:'10px 16px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,flexShrink:0,boxShadow:`0 4px 14px ${ECOLS[lastAccessed.examType]||'#4D9FFF'}30`}}>Resume →</button>
            </div>
          </div>
        )}

        {/* TABS */}
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:7,marginBottom:14}}>
          {(['active','completed','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{padding:'10px',borderRadius:12,background:tab===t?'rgba(77,159,255,0.13)':CARD,border:`1px solid ${tab===t?'rgba(77,159,255,0.36)':BORDER}`,color:tab===t?'#4D9FFF':SUB,fontWeight:tab===t?700:400,cursor:'pointer',fontSize:11,backdropFilter:'blur(12px)'}}>
              {t==='active'?'⚡ Active':t==='completed'?'✅ Completed':'❤️ Wishlist'}
              <span style={{marginLeft:4,fontSize:10,opacity:0.6}}>({t==='active'?batches.filter(b=>!b.isExpired&&!b.isCompleted).length:t==='completed'?batches.filter(b=>b.isExpired||b.isCompleted).length:batches.filter(b=>b.isWishlisted).length})</span>
            </button>
          ))}
        </div>

        {/* BATCH CARDS */}
        {loading?(
          <div style={{display:'flex',flexDirection:'column',gap:14}}>
            {[1,2,3].map(i=><div key={i} style={{height:180,background:CARD,borderRadius:18,animation:'shimmer 1.5s ease infinite',animationDelay:`${i*0.15}s`}}/>)}
          </div>
        ):filtered.length===0?(
          <div style={{textAlign:'center',padding:'50px 16px'}}>
            <div style={{fontSize:56,marginBottom:14}}>{tab==='wishlist'?'❤️':tab==='completed'?'🎓':'📚'}</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:TEXT,marginBottom:8}}>{tab==='wishlist'?'No Saved Batches':tab==='completed'?'No Completed Batches Yet':'No Active Batches'}</div>
            <div style={{fontSize:12,color:SUB,marginBottom:22}}>{tab==='wishlist'?'Wishlist batches from Test Series page':'Complete tests to see them here'}</div>
            <button onClick={()=>router.push('/dashboard/test-series')} style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'12px 28px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13}}>Explore Batches →</button>
          </div>
        ):(
          <div style={{display:'flex',flexDirection:'column',gap:14}}>
            {filtered.map((b,i)=>{
              const ec=ECOLS[b.examType]||'#4D9FFF'
              return (
                <div key={b._id} style={{background:CARD,border:`1px solid ${b.isExpired?'rgba(231,76,60,0.25)':b.isCompleted?'rgba(255,215,0,0.2)':ec+'22'}`,borderRadius:20,padding:'16px',backdropFilter:'blur(18px)',animation:`slideUp ${0.3+i*0.06}s ease`,position:'relative',overflow:'hidden'}}>

                  {/* Status banners */}
                  {b.isExpired&&<div style={{position:'absolute',top:0,left:0,right:0,background:'rgba(231,76,60,0.18)',padding:'4px 14px',fontSize:10,fontWeight:700,color:'#E74C3C',textAlign:'center'}}>🔴 Batch Expired — Renew to Continue</div>}
                  {!b.isExpired&&b.daysLeft<=7&&<div style={{position:'absolute',top:0,left:0,right:0,background:'rgba(230,126,34,0.18)',padding:'4px 14px',fontSize:10,fontWeight:700,color:'#E67E22',textAlign:'center'}}>⚠️ Expiring in {b.daysLeft} days — Renew Soon</div>}
                  {b.isCompleted&&<div style={{position:'absolute',top:0,left:0,right:0,background:'rgba(255,215,0,0.14)',padding:'4px 14px',fontSize:10,fontWeight:700,color:'#FFD700',textAlign:'center'}}>🎓 Batch Completed!</div>}

                  <div style={{marginTop:(b.isExpired||b.daysLeft<=7||b.isCompleted)?22:0}}>
                    <div style={{display:'flex',gap:12,alignItems:'flex-start'}}>

                      {/* Progress indicator */}
                      <div style={{flexShrink:0}}>
                        {progressView==='ring'
                          ?<ProgressRing pct={b.progress} ec={ec}/>
                          :<div style={{width:56,height:56,display:'flex',alignItems:'center',justifyContent:'center',background:`${ec}14`,borderRadius:14,border:`1px solid ${ec}22`,fontSize:24}}>{b.examType==='NEET'?'🩺':b.examType==='JEE'?'⚙️':'📚'}</div>
                        }
                      </div>

                      {/* Content */}
                      <div style={{flex:1,minWidth:0}}>
                        <div style={{display:'flex',alignItems:'center',gap:6,marginBottom:5,flexWrap:'wrap'}}>
                          <span style={{fontSize:9,background:`${ec}16`,color:ec,padding:'2px 8px',borderRadius:20,fontWeight:700,border:`1px solid ${ec}25`}}>{b.examType}</span>
                          {b.streak>0&&<span style={{fontSize:9,background:'rgba(255,100,0,0.12)',color:'#FF6B35',padding:'2px 8px',borderRadius:20,fontWeight:700}}>🔥 {b.streak}-day streak</span>}
                          {b.isCompleted&&<span style={{fontSize:9,background:'rgba(255,215,0,0.12)',color:'#FFD700',padding:'2px 8px',borderRadius:20,fontWeight:700}}>🏆 Completed</span>}
                        </div>
                        <div style={{fontSize:14,fontWeight:700,color:TEXT,fontFamily:'Playfair Display,serif',overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis',marginBottom:4}}>{b.name}</div>

                        {/* Horizontal bar if bar mode */}
                        {progressView==='bar'&&<div style={{marginBottom:8}}><ProgressBar pct={b.progress} ec={ec}/></div>}

                        <div style={{display:'flex',gap:12,flexWrap:'wrap',marginBottom:8}}>
                          <span style={{fontSize:10,color:SUB}}>📝 {b.testsCompleted}/{b.totalTests} tests</span>
                          <span style={{fontSize:10,color:SUB}}>📅 {b.daysLeft}d left</span>
                          <span style={{fontSize:10,color:SUB}}>🕐 {b.daysSinceAccess===0?'Today':b.daysSinceAccess+'d ago'}</span>
                        </div>

                        {/* Leaderboard mini */}
                        <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:10}}>
                          <span style={{fontSize:10,color:SUB}}>🏅 Batch Leaderboard</span>
                          <button onClick={()=>setLbBatch({id:b._id,name:b.name})}
                            style={{background:'transparent',border:`1px solid ${ec}30`,borderRadius:8,padding:'3px 8px',color:ec,fontSize:9,cursor:'pointer',fontWeight:700}}>View Rank →</button>
                        </div>

                        {/* Activity Feed */}
                        {tok&&<ActivityFeed batchId={b._id} tok={tok}/>}
                      </div>
                    </div>

                    {/* Action buttons */}
                    <div style={{display:'flex',gap:8,marginTop:12,flexWrap:'wrap'}}>
                      {b.isCompleted?(
                        <button onClick={()=>router.push('/dashboard/certificate')}
                          style={{flex:1,padding:'9px',background:'linear-gradient(135deg,#FFD700,#FFA000)',border:'none',borderRadius:11,color:'#000',fontWeight:700,cursor:'pointer',fontSize:11}}>🏆 Get Certificate</button>
                      ):(
                        <button onClick={()=>{accessBatch(b._id);router.push('/dashboard/exams')}}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,boxShadow:`0 4px 12px ${ec}25`}}>
                          {b.isExpired?'🔄 Renew':'▶️ Continue'}
                        </button>
                      )}
                      <button onClick={()=>setLbBatch({id:b._id,name:b.name})}
                        style={{padding:'9px 12px',background:'rgba(255,215,0,0.08)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:11,color:'#FFD700',cursor:'pointer',fontSize:13}}>🏆</button>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {/* STUDY TIPS */}
        <div style={{marginTop:40,padding:'0 4px'}}>
          {TIPS.map((tip,i)=>(
            <div key={i} style={{display:'flex',gap:13,alignItems:'flex-start',marginBottom:18,animation:`slideUp ${1+i*0.12}s ease`}}>
              <span style={{fontSize:24,flexShrink:0}}>{tip.i}</span>
              <div>
                <div style={{fontWeight:700,color:'#4D9FFF',fontSize:12,marginBottom:3,fontFamily:'Playfair Display,serif'}}>{tip.t}</div>
                <div style={{fontSize:11,color:SUB,lineHeight:1.7}}>{tip.d}</div>
              </div>
            </div>
          ))}
        </div>

      </div>
    </div>
  )
}
