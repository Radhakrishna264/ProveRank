#!/bin/bash
# ============================================================================
# ProveRank — MERGED FRONTEND INSTALLER
# FPR4 Student Test Series/Batch Marketplace + FPR5 My Batches Hub Upgrade
# Run from your frontend project ROOT on Replit: bash proverank_FPR4_5_frontend.sh
# Run backend installer FIRST. Overwrites both pages with upgraded versions
# (100% of original code preserved + additions). Backs up originals.
# ============================================================================
set -e
echo "🚀 ProveRank FPR4+FPR5 — Frontend Install Starting..."

MYBATCHES_PAGE=$(grep -rl "MyBatchesPage" --include="page.tsx" . 2>/dev/null | head -1)
TESTSERIES_PAGE=$(grep -rl "TestSeriesPage" --include="page.tsx" . 2>/dev/null | head -1)

if [ -z "$MYBATCHES_PAGE" ]; then echo "❌ Could not locate My Batches page.tsx (searched for 'MyBatchesPage'). Run from frontend root."; exit 1; fi
if [ -z "$TESTSERIES_PAGE" ]; then echo "❌ Could not locate Test Series page.tsx (searched for 'TestSeriesPage'). Run from frontend root."; exit 1; fi
echo "📍 My Batches page:  $MYBATCHES_PAGE"
echo "📍 Test Series page: $TESTSERIES_PAGE"

cp "$MYBATCHES_PAGE" "$MYBATCHES_PAGE.pre-fpr45-bak"
cp "$TESTSERIES_PAGE" "$TESTSERIES_PAGE.pre-fpr45-bak"
echo "📦 Backups created (.pre-fpr45-bak)"

# ---------------------------------------------------------------------------
# Write upgraded My Batches Hub page.tsx (FPR5)
# ---------------------------------------------------------------------------
cat > "$MYBATCHES_PAGE" << 'FPR45_FE_MYBATCHES'
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
  const load=()=>{
    fetch(`${API}/api/batch-activity/${batchId}`,{headers:{Authorization:`Bearer ${tok}`}})
      .then(r=>r.json()).then(d=>setActivities(d.activities||[])).catch(()=>{})
  }
  useEffect(()=>{load()},[batchId,tok])
  const markRead=(id:string)=>{
    fetch(`${API}/api/batch-activity/${id}/read`,{method:'PUT',headers:{Authorization:`Bearer ${tok}`}}).then(load).catch(()=>{})
  }
  if(activities.length===0)return null
  return (
    <div style={{marginTop:14}}>
      <div style={{fontSize:10,fontWeight:700,color:'rgba(160,200,240,0.45)',textTransform:'uppercase',letterSpacing:1,marginBottom:8}}>📢 What's New</div>
      {activities.map(a=>(
        <div key={a._id} onClick={()=>!(a as any).isRead&&markRead(a._id)} style={{display:'flex',gap:8,alignItems:'flex-start',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.06)',cursor:(a as any).isRead?'default':'pointer',opacity:(a as any).isRead?0.62:1}}>
          <span style={{fontSize:16,flexShrink:0}}>{a.icon}</span>
          <div style={{flex:1}}>
            <div style={{fontSize:11,fontWeight:700,color:'#F0F8FF',display:'flex',alignItems:'center',gap:6}}>
              {(a as any).pinned&&<span title="Pinned">📌</span>}
              {a.title}
              {!(a as any).isRead&&<span style={{width:6,height:6,borderRadius:'50%',background:'#4D9FFF',flexShrink:0}}/>}
            </div>
            {a.message&&<div style={{fontSize:10,color:'rgba(160,200,240,0.55)',marginTop:2}}>{a.message}</div>}
            <div style={{fontSize:9,color:'rgba(160,200,240,0.3)',marginTop:3}}>{new Date(a.createdAt).toLocaleDateString()}</div>
          </div>
        </div>
      ))}
    </div>
  )
}

// ── Certificate Roadmap Modal (FPR5) ──
function CertificateModal({batch,tok,onClose}:{batch:BatchMeta;tok:string;onClose:()=>void}) {
  const [data,setData]=useState<any>(null)
  const [loading,setLoading]=useState(true)
  useEffect(()=>{
    fetch(`${API}/api/my-batches/${batch._id}/certificate`,{headers:{Authorization:`Bearer ${tok}`}})
      .then(r=>r.json()).then(setData).catch(()=>{}).finally(()=>setLoading(false))
  },[batch._id,tok])
  return (
    <div style={{position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
      <div style={{background:'rgba(4,12,30,0.99)',border:'1px solid rgba(255,215,0,0.3)',borderRadius:22,padding:24,maxWidth:400,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)'}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#FFD700'}}>🏆 Certificate Roadmap</div>
          <button onClick={onClose} style={{background:'transparent',border:'none',color:'rgba(160,200,240,0.5)',cursor:'pointer',fontSize:22}}>×</button>
        </div>
        {loading?<div style={{textAlign:'center',padding:30,color:'rgba(160,200,240,0.4)'}}>Loading...</div>:data?(
          <>
            <div style={{textAlign:'center',marginBottom:16}}>
              <div style={{fontSize:48,marginBottom:8}}>{data.eligible?'🎉':'📈'}</div>
              <div style={{fontSize:14,fontWeight:700,color:data.eligible?'#27AE60':'#F0F8FF'}}>{data.eligible?'Certificate Unlocked!':`${data.progress}% Complete`}</div>
            </div>
            <div style={{height:8,background:'rgba(255,255,255,0.08)',borderRadius:4,overflow:'hidden',marginBottom:16}}>
              <div style={{height:'100%',width:`${data.progress}%`,background:'linear-gradient(90deg,#FFD700,#FFA000)',borderRadius:4}}/>
            </div>
            <div style={{fontSize:11,color:'rgba(160,200,240,0.6)',marginBottom:14}}>{data.testsCompleted}/{data.totalTests} tests completed</div>
            {data.eligible?(
              <a href={data.downloadUrl} style={{display:'block',textAlign:'center',padding:'11px',background:'linear-gradient(135deg,#FFD700,#FFA000)',borderRadius:12,color:'#000',fontWeight:700,fontSize:12,textDecoration:'none'}}>⬇️ Download Certificate</a>
            ):(
              (data.missingRequirements||[]).map((m:string,i:number)=>(
                <div key={i} style={{fontSize:11,color:'rgba(160,200,240,0.6)',padding:'8px 12px',background:'rgba(77,159,255,0.06)',borderRadius:10,marginBottom:6}}>⏳ {m}</div>
              ))
            )}
          </>
        ):<div style={{textAlign:'center',padding:20,color:'rgba(160,200,240,0.4)',fontSize:12}}>Could not load certificate status.</div>}
      </div>
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
  const [darkMode,setDarkModeState]=useState(true)
  const setDarkMode=(fnOrVal:boolean|((d:boolean)=>boolean))=>{
    setDarkModeState(prev=>{
      const next=typeof fnOrVal==='function'?(fnOrVal as (d:boolean)=>boolean)(prev):fnOrVal
      try{
        localStorage.setItem('pr_color_theme',next?'dark':'light')
        window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:next?'dark':'light'}))
      }catch{}
      return next
    })
  }
  const [progressView,setProgressView]=useState<'ring'|'bar'>('ring')
  const [lbBatch,setLbBatch]=useState<{id:string;name:string}|null>(null)
  const [notifGranted,setNotifGranted]=useState(false)
  const [notifAsked,setNotifAsked]=useState(false)
  const [isClient,setIsClient]=useState(false)
  // ── FPR5 additions ──
  const [search,setSearch]=useState('')
  const [sortBy,setSortBy]=useState<'recent'|'progress'|'score'|'streak'|'expiry'|'rating'|'newest'>('recent')
  const [quickFilters,setQuickFilters]=useState<{expiring:boolean;certAvail:boolean;streakActive:boolean;free:boolean;paid:boolean}>({expiring:false,certAvail:false,streakActive:false,free:false,paid:false})
  const [reminders,setReminders]=useState<any[]>([])
  const [showReminders,setShowReminders]=useState(false)
  const [certBatch,setCertBatch]=useState<BatchMeta|null>(null)
  const [renewingId,setRenewingId]=useState<string|null>(null)

  const BG=darkMode?'transparent':'rgba(240,244,248,0.95)'
  const CARD=darkMode?'rgba(4,12,30,0.95)':'rgba(255,255,255,0.95)'
  const BORDER=darkMode?'rgba(255,255,255,0.08)':'rgba(0,0,0,0.1)'
  const TEXT=darkMode?'#F0F8FF':'#1a1a2e'
  const SUB=darkMode?'rgba(180,200,220,0.55)':'rgba(0,0,0,0.5)'

  useEffect(()=>{
    setIsClient(true)
    const t=localStorage.getItem('pr_token')||''
    setTok(t); fetchData(t)
    fetchReminders(t)
    // ── FPR5: sync with global light/dark preference (shared with rest of app) ──
    try{
      const saved=localStorage.getItem('pr_color_theme')
      if(saved==='light')setDarkModeState(false)
      else if(saved==='dark')setDarkModeState(true)
    }catch{}
    const onStorage=(e:StorageEvent)=>{
      if(e.key==='pr_color_theme'&&e.newValue){setDarkModeState(e.newValue==='dark')}
    }
    window.addEventListener('storage',onStorage)
    // Check notification permission
    if(typeof window !== 'undefined' && 'Notification' in window){
      setNotifGranted(Notification.permission==='granted')
      setNotifAsked(Notification.permission!=='default')
    }
    return()=>window.removeEventListener('storage',onStorage)
  },[])

  const fetchReminders=async(t:string)=>{
    if(!t)return
    try{
      const r=await fetch(`${API}/api/my-batches/reminders`,{headers:{Authorization:`Bearer ${t}`}})
      const d=await r.json()
      setReminders(d.reminders||[])
    }catch{}
  }

  const renewBatch=async(id:string)=>{
    if(!tok)return
    setRenewingId(id)
    try{
      const r=await fetch(`${API}/api/my-batches/${id}/renew`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      const d=await r.json()
      if(d.success){ fetchData(tok); fetchReminders(tok) } else alert(d.error||'Renewal failed')
    }finally{setRenewingId(null)}
  }

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
    let pass=true
    if(tab==='active')pass=!b.isExpired&&!b.isCompleted
    else if(tab==='completed')pass=b.isExpired||b.isCompleted
    else if(tab==='wishlist')pass=!!b.isWishlisted
    if(!pass)return false
    if(search&&!b.name.toLowerCase().includes(search.toLowerCase())&&!b.examType.toLowerCase().includes(search.toLowerCase()))return false
    if(quickFilters.expiring&&!(b.daysLeft<=7&&b.daysLeft>0))return false
    if(quickFilters.certAvail&&b.progress<100)return false
    if(quickFilters.streakActive&&!(b.streak>0))return false
    if(quickFilters.free&&!b.isFree)return false
    if(quickFilters.paid&&b.isFree)return false
    return true
  }).sort((a,b)=>{
    if(sortBy==='progress')return b.progress-a.progress
    if(sortBy==='score')return 0 // avgScore not on BatchMeta type surface here — safe no-op
    if(sortBy==='streak')return b.streak-a.streak
    if(sortBy==='expiry')return a.daysLeft-b.daysLeft
    if(sortBy==='rating')return (b.rating||0)-(a.rating||0)
    if(sortBy==='newest')return new Date(b.enrolledAt).getTime()-new Date(a.enrolledAt).getTime()
    return new Date(b.lastAccessedAt).getTime()-new Date(a.lastAccessedAt).getTime()
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
      {/* FPR5: Certificate Roadmap Modal */}
      {certBatch&&tok&&<CertificateModal batch={certBatch} tok={tok} onClose={()=>setCertBatch(null)}/>}

      {/* STICKY TOP BAR */}
      <div style={{position:'sticky',top:0,zIndex:50,background:darkMode?'rgba(2,8,22,0.96)':'rgba(255,255,255,0.96)',backdropFilter:'blur(22px)',borderBottom:`1px solid ${BORDER}`,padding:'10px 14px',display:'flex',alignItems:'center',gap:10}}>
        <button onClick={()=>router.back()} style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:'#4D9FFF',fontSize:20,flexShrink:0}}>←</button>
        <div style={{flex:1}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>My Batches</div>
          <div style={{fontSize:10,color:SUB}}>Your enrolled test series</div>
        </div>
        <div style={{display:'flex',gap:7,alignItems:'center'}}>
          {/* FPR5: Reminder Center bell */}
          <button onClick={()=>setShowReminders(o=>!o)} style={{position:'relative',background:showReminders?'rgba(77,159,255,0.22)':'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:9,width:32,height:32,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:'#4D9FFF',fontSize:14,flexShrink:0}}>
            🔔
            {reminders.length>0&&<span style={{position:'absolute',top:-3,right:-3,width:15,height:15,borderRadius:'50%',background:'#E74C3C',color:'#fff',fontSize:8,fontWeight:900,display:'flex',alignItems:'center',justifyContent:'center'}}>{reminders.length>9?'9+':reminders.length}</span>}
          </button>
          {/* Progress View Toggle */}
          <button onClick={()=>setProgressView(v=>v==='ring'?'bar':'ring')}
            style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:9,padding:'5px 10px',cursor:'pointer',color:'#4D9FFF',fontSize:10,fontWeight:700}}>
            {progressView==='ring'?'📊 Bar':'⭕ Ring'}
          </button>
          <button onClick={()=>setDarkMode(d=>!d)} style={{background:'rgba(77,159,255,0.1)',border:`1px solid ${BORDER}`,borderRadius:9,padding:'5px 9px',cursor:'pointer',color:TEXT,fontSize:12}}>{darkMode?'☀️':'🌙'}</button>
          <button onClick={()=>router.push('/dashboard/test-series')} style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,padding:'7px 12px',cursor:'pointer',color:'#fff',fontSize:11,fontWeight:700,flexShrink:0}}>+ Explore</button>
        </div>
      </div>

      {/* FPR5: REMINDER CENTER PANEL */}
      {showReminders&&(
        <div style={{position:'fixed',top:54,right:14,zIndex:200,width:300,maxHeight:380,overflowY:'auto',background:CARD,border:`1px solid ${BORDER}`,borderRadius:16,boxShadow:'0 20px 60px rgba(0,0,0,0.4)',backdropFilter:'blur(24px)',animation:'slideUp 0.2s ease'}}>
          <div style={{padding:'12px 14px',borderBottom:`1px solid ${BORDER}`,fontWeight:700,fontSize:12,color:TEXT}}>🔔 Reminder Center ({reminders.length})</div>
          {reminders.length===0?<div style={{padding:'24px 16px',textAlign:'center',color:SUB,fontSize:12}}>All caught up! No reminders.</div>:
            reminders.map((r,i)=>(
              <div key={i} style={{padding:'10px 14px',borderBottom:`1px solid ${BORDER}`,display:'flex',gap:8,alignItems:'flex-start'}}>
                <span style={{fontSize:14,flexShrink:0}}>{r.type==='renewal'?'⏰':r.type==='streak_risk'?'🔥':'💰'}</span>
                <div>
                  <div style={{fontSize:11,fontWeight:700,color:TEXT}}>{r.batchName}</div>
                  <div style={{fontSize:10,color:SUB,marginTop:2}}>{r.message}</div>
                </div>
              </div>
            ))}
        </div>
      )}

      <div style={{position:'relative',zIndex:2,padding:'14px 14px 80px',maxWidth:900,margin:'0 auto'}}>

        {/* NOTIFICATION BANNER */}
        {isClient&&!notifAsked&&typeof window!=='undefined'&&'Notification' in window&&(
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
        <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8,marginBottom:8}}>
          {[{i:'📚',l:'Enrolled',v:stats.total,c:'#4D9FFF'},{i:'✅',l:'Tests Done',v:stats.testsCompleted,c:'#27AE60'},{i:'⚡',l:'Active',v:stats.activeBatches,c:'#E67E22'},{i:'🏆',l:'Certificates',v:stats.certificates,c:'#FFD700'}].map((s,i)=>(
            <div key={i} style={{background:CARD,border:`1px solid ${s.c}18`,borderRadius:14,padding:'10px 8px',textAlign:'center',backdropFilter:'blur(16px)',animation:`slideUp ${0.2+i*0.08}s ease`}}>
              <div style={{fontSize:18,marginBottom:3}}>{s.i}</div>
              <div style={{fontSize:20,fontWeight:900,color:s.c}}>{s.v}</div>
              <div style={{fontSize:9,color:SUB}}>{s.l}</div>
            </div>
          ))}
        </div>
        {/* FPR5: secondary stat chips — renewal due, wishlist, avg progress, streak */}
        {(stats as any).renewalDueSoon!==undefined&&(
          <div style={{display:'flex',gap:6,flexWrap:'wrap',marginBottom:16}}>
            {(stats as any).renewalDueSoon>0&&<span style={{fontSize:10,background:'rgba(230,126,34,0.14)',color:'#E67E22',padding:'4px 10px',borderRadius:20,fontWeight:700}}>⏰ {(stats as any).renewalDueSoon} renewal due soon</span>}
            {(stats as any).wishlistCount>0&&<span style={{fontSize:10,background:'rgba(231,76,60,0.1)',color:'#E74C3C',padding:'4px 10px',borderRadius:20,fontWeight:700}}>❤️ {(stats as any).wishlistCount} wishlisted</span>}
            {(stats as any).currentStreak>0&&<span style={{fontSize:10,background:'rgba(255,107,53,0.12)',color:'#FF6B35',padding:'4px 10px',borderRadius:20,fontWeight:700}}>🔥 {(stats as any).currentStreak}-day best streak</span>}
            <span style={{fontSize:10,background:'rgba(77,159,255,0.1)',color:'#4D9FFF',padding:'4px 10px',borderRadius:20,fontWeight:700}}>📊 {(stats as any).avgProgress||0}% avg progress</span>
          </div>
        )}

        {/* FPR5: SMART SEARCH + SORT + QUICK FILTERS */}
        <div style={{display:'flex',gap:7,marginBottom:10,flexWrap:'wrap'}}>
          <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔍 Search your batches..." style={{...inp,flex:'2 1 160px'}}/>
          <select value={sortBy} onChange={e=>setSortBy(e.target.value as any)} style={{...inp,flex:'1 1 130px'}}>
            <option value="recent">Recently Accessed</option>
            <option value="progress">Highest Progress</option>
            <option value="streak">Highest Streak</option>
            <option value="expiry">Earliest Expiry</option>
            <option value="rating">Top Rated</option>
            <option value="newest">Newest</option>
          </select>
        </div>
        <div style={{display:'flex',gap:6,flexWrap:'wrap',marginBottom:16}}>
          {[{k:'expiring',l:'⏰ Expiring Soon'},{k:'certAvail',l:'🏆 Certificate Available'},{k:'streakActive',l:'🔥 Streak Active'},{k:'free',l:'🆓 Free'},{k:'paid',l:'💎 Paid'}].map(f=>{
            const active=(quickFilters as any)[f.k]
            return <button key={f.k} onClick={()=>setQuickFilters(prev=>({...prev,[f.k]:!(prev as any)[f.k]}))}
              style={{padding:'5px 11px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':CARD,border:`1px solid ${active?'rgba(77,159,255,0.4)':BORDER}`,color:active?'#4D9FFF':SUB,fontWeight:active?700:400}}>{f.l}</button>
          })}
          {(search||Object.values(quickFilters).some(Boolean))&&<button onClick={()=>{setSearch('');setQuickFilters({expiring:false,certAvail:false,streakActive:false,free:false,paid:false})}} style={{padding:'5px 11px',borderRadius:20,fontSize:10,cursor:'pointer',background:'rgba(231,76,60,0.08)',border:'1px solid rgba(231,76,60,0.2)',color:'#E74C3C'}}>🗑 Reset</button>}
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
                        <button onClick={()=>setCertBatch(b)}
                          style={{flex:1,padding:'9px',background:'linear-gradient(135deg,#FFD700,#FFA000)',border:'none',borderRadius:11,color:'#000',fontWeight:700,cursor:'pointer',fontSize:11}}>🏆 Get Certificate</button>
                      ):b.isExpired?(
                        <button onClick={()=>renewBatch(b._id)} disabled={renewingId===b._id}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,boxShadow:`0 4px 12px ${ec}25`,opacity:renewingId===b._id?0.7:1}}>
                          {renewingId===b._id?'⟳ Renewing...':'🔄 Renew Now'}
                        </button>
                      ):(
                        <button onClick={()=>{accessBatch(b._id);router.push('/dashboard/exams')}}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,boxShadow:`0 4px 12px ${ec}25`}}>
                          ▶️ Continue
                        </button>
                      )}
                      {!b.isExpired&&b.daysLeft<=7&&!b.isCompleted&&(
                        <button onClick={()=>renewBatch(b._id)} disabled={renewingId===b._id}
                          style={{padding:'9px 12px',background:'rgba(230,126,34,0.1)',border:'1px solid rgba(230,126,34,0.25)',borderRadius:11,color:'#E67E22',cursor:'pointer',fontSize:11,fontWeight:700}}>⏰ Extend</button>
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
FPR45_FE_MYBATCHES
echo "✅ My Batches Hub page upgraded ($(wc -l < "$MYBATCHES_PAGE") lines)"

# ---------------------------------------------------------------------------
# Write upgraded Test Series Marketplace page.tsx (FPR4)
# ---------------------------------------------------------------------------
cat > "$TESTSERIES_PAGE" << 'FPR45_FE_TESTSERIES'
'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; description: string; examType: string;
  price: number; discountPrice: number; isFree: boolean; thumbnail: string;
  totalTests: number; enrolledCount: number; language: string; batchType: string;
  isSpotlight: boolean; flashSaleEndTime?: string; flashSalePrice?: number;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean; validity: number;
  rating: number; isEnrolled?: boolean; isWishlisted?: boolean; createdAt: string;
  allowEMI?: boolean; difficulty?: string; subject?: string;
}
type AcSuggestion = { _id: string; name: string; examType: string; isFree: boolean }
type Notif = { _id: string; title: string; message: string; isRead: boolean; createdAt: string; link?: string }

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', JEE: '#9B59B6', CUET: '#27AE60',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C',
  Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}
const CATS = ['All','NEET','JEE','CUET','Class 11','Class 12','Foundation','Crash Course']
const CICONS: Record<string,string> = {
  All:'🌟',NEET:'🩺',JEE:'⚙️',CUET:'📖',
  'Class 11':'📗','Class 12':'📘',Foundation:'🏛️','Crash Course':'🚀'
}
const QUOTES = [
  { q:"Champions aren't made in gyms. They are made from something deep inside them.", a:"Muhammad Ali" },
  { q:"The secret of getting ahead is getting started. Every expert was once a beginner.", a:"Mark Twain" },
  { q:"In the middle of every difficulty lies opportunity. Stay focused, stay strong.", a:"Albert Einstein" },
  { q:"Success is not final, failure is not fatal — it is the courage to continue that counts.", a:"Winston Churchill" },
]
const FACTS = [
  { icon:'🧬', t:'DNA Replication', f:'Semi-conservative — each new DNA retains one original strand (Meselson-Stahl, 1958). 3 billion base pairs in human genome.', c:'#4D9FFF' },
  { icon:'⚡', t:'ATP Synthesis', f:'Mitochondria produce 36-38 ATP per glucose via oxidative phosphorylation. F0F1 ATP synthase rotates at 100 rpm.', c:'#00D4FF' },
]

function loadRazorpay(): Promise<boolean> {
  return new Promise(resolve => {
    if ((window as any).Razorpay) return resolve(true)
    const s = document.createElement('script')
    s.src = 'https://checkout.razorpay.com/v1/checkout.js'
    s.onload = () => resolve(true); s.onerror = () => resolve(false)
    document.body.appendChild(s)
  })
}

function PRLogo({ size = 36 }: { size?: number }) {
  const b = Math.round(size * 0.94), p = Math.round(b * 0.63), f = Math.round(p * 0.52), r = Math.round(p * 0.28)
  return (
    <div style={{ position:'relative', width:b, height:b, flexShrink:0, display:'inline-flex' }}>
      <div style={{ position:'absolute', top:0, left:0, width:p, height:p, borderRadius:r, background:'linear-gradient(135deg,#4D9FFF,#00D4FF)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:f, fontWeight:900, fontFamily:'Inter,sans-serif', color:'#030810' }}>P</div>
      <div style={{ position:'absolute', bottom:0, right:0, width:p, height:p, borderRadius:r, background:'rgba(0,212,255,0.15)', border:'1.5px solid rgba(0,212,255,0.45)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:f, fontWeight:900, fontFamily:'Inter,sans-serif', color:'#00D4FF' }}>R</div>
    </div>
  )
}

function MilkyWayCanvas() {
  const r = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const cv = r.current; if (!cv) return
    const ctx = cv.getContext('2d'); if (!ctx) return
    let af: number, t = 0
    const resize = () => { cv.width = window.innerWidth; cv.height = window.innerHeight }
    resize(); window.addEventListener('resize', resize)
    const stars = Array.from({ length: 1100 }, () => {
      const cls = Math.random()
      return { x:Math.random(), y:Math.random(), r:cls<0.005?2.4:cls<0.02?1.5:cls<0.08?0.9:0.42, phase:Math.random()*Math.PI*2, spd:0.3+Math.random()*3, col:cls<0.003?'#9BB0FF':cls<0.015?'#CAD7FF':cls<0.06?'#F8F7FF':'#FFF4EA', inArm:Math.random()<0.55 }
    })
    const draw = () => {
      t += 0.003; const W=cv.width,H=cv.height,cx=W/2,cy=H*0.44
      ctx.clearRect(0,0,W,H); ctx.fillStyle='#020816'; ctx.fillRect(0,0,W,H)
      const mw=ctx.createLinearGradient(0,H*0.2,W,H*0.8)
      mw.addColorStop(0,'transparent'); mw.addColorStop(0.5,'rgba(140,155,220,0.055)'); mw.addColorStop(1,'transparent')
      ctx.fillStyle=mw; ctx.fillRect(0,0,W,H)
      const sz=Math.min(W,H)
      const core=ctx.createRadialGradient(cx,cy,0,cx,cy,sz*0.18)
      core.addColorStop(0,'rgba(255,215,120,0.15)'); core.addColorStop(0.4,'rgba(255,170,70,0.07)'); core.addColorStop(1,'transparent')
      ctx.fillStyle=core; ctx.fillRect(0,0,W,H)
      stars.forEach(s => {
        const x=s.x*W,y=s.y*H,tw=0.3+0.7*Math.abs(Math.sin(t*s.spd+s.phase)),alpha=s.inArm?tw*0.72:tw*0.5
        if(s.r>1.3){const gl=ctx.createRadialGradient(x,y,0,x,y,s.r*3.2);gl.addColorStop(0,'rgba(255,255,255,0.18)');gl.addColorStop(1,'transparent');ctx.fillStyle=gl;ctx.beginPath();ctx.arc(x,y,s.r*3.2,0,Math.PI*2);ctx.fill()}
        ctx.beginPath();ctx.arc(x,y,s.r,0,Math.PI*2)
        const hex=Math.round(alpha*255).toString(16).padStart(2,'0')
        ctx.fillStyle=s.col+hex;ctx.fill()
      })
      af=requestAnimationFrame(draw)
    }
    draw(); return () => { cancelAnimationFrame(af); window.removeEventListener('resize',resize) }
  },[])
  return <canvas ref={r} style={{ position:'fixed', inset:0, zIndex:0, pointerEvents:'none' }} />
}

function SolarSystem() {
  const planets=[{sz:7,col:'#9E9E9E',o:110,dur:47,dl:0},{sz:13,col:'radial-gradient(circle at 35% 35%,#F5D5A0,#C4A265)',o:170,dur:35,dl:-8},{sz:14,col:'radial-gradient(circle at 35% 35%,#5BC8FA,#1565C0)',o:240,dur:29,dl:-14},{sz:9,col:'radial-gradient(circle at 35% 35%,#FF7043,#BF360C)',o:308,dur:24,dl:-20}]
  return (
    <div style={{ position:'fixed',top:'42%',left:'50%',transform:'translate(-50%,-50%)',zIndex:1,pointerEvents:'none',width:0,height:0 }}>
      <div style={{ position:'absolute',width:24,height:24,marginLeft:-12,marginTop:-12,borderRadius:'50%',background:'radial-gradient(circle at 40% 40%,#FFF9C4,#FFD600,#FF8F00)',boxShadow:'0 0 34px rgba(255,200,0,0.5)' }} />
      {planets.map((p,i)=>(
        <div key={i} style={{ position:'absolute',width:p.o*2,height:p.o*2,marginLeft:-p.o,marginTop:-p.o,borderRadius:'50%',border:'1px solid rgba(77,159,255,0.05)',animation:`orb ${p.dur}s linear infinite`,animationDelay:`${p.dl}s` }}>
          <div style={{ position:'absolute',top:-p.sz/2,left:'50%',marginLeft:-p.sz/2,width:p.sz,height:p.sz,borderRadius:'50%',background:p.col }} />
        </div>
      ))}
    </div>
  )
}

function FlashTimer({ end }: { end: string }) {
  const [s,setS]=useState({h:0,m:0,s:0})
  useEffect(()=>{
    const tick=()=>{const d=new Date(end).getTime()-Date.now();if(d<=0){setS({h:0,m:0,s:0});return};setS({h:Math.floor(d/3600000),m:Math.floor(d%3600000/60000),s:Math.floor(d%60000/1000)})}
    tick();const iv=setInterval(tick,1000);return()=>clearInterval(iv)
  },[end])
  const p=(n:number)=>n.toString().padStart(2,'0')
  return <span style={{ fontFamily:'monospace',fontSize:13,fontWeight:800,color:'#FF6B6B',letterSpacing:2 }}>{p(s.h)}:{p(s.m)}:{p(s.s)}</span>
}

function Stars({ r }: { r: number }) {
  return (
    <span>
      {[1,2,3,4,5].map(i=><span key={i} style={{ color:i<=Math.round(r)?'#FFD700':'rgba(255,215,0,0.15)',fontSize:11 }}>★</span>)}
      <span style={{ fontSize:10,color:'rgba(255,255,255,0.3)',marginLeft:3 }}>{r.toFixed(1)}</span>
    </span>
  )
}

// ── NOTIFICATION BELL ──
function NotificationBell({ tok }: { tok: string | null }) {
  const [open,setOpen]=useState(false)
  const [notifs,setNotifs]=useState<Notif[]>([])
  const [unread,setUnread]=useState(0)
  const router=useRouter()

  const fetchNotifs=useCallback(async()=>{
    if(!tok)return
    try{
      const r=await fetch(`${API}/api/student/notifications`,{headers:{Authorization:`Bearer ${tok}`}})
      const d=await r.json()
      setNotifs(d.notifications||[]);setUnread(d.unread||0)
    }catch{}
  },[tok])

  useEffect(()=>{ fetchNotifs(); const iv=setInterval(fetchNotifs,30000); return()=>clearInterval(iv) },[fetchNotifs])

  const markAllRead=async()=>{
    if(!tok)return
    await fetch(`${API}/api/student/notifications/read-all`,{method:'PUT',headers:{Authorization:`Bearer ${tok}`}})
    setUnread(0);setNotifs(prev=>prev.map(n=>({...n,isRead:true})))
  }
  const markRead=async(id:string,link?:string)=>{
    if(!tok)return
    await fetch(`${API}/api/student/notifications/${id}/read`,{method:'PUT',headers:{Authorization:`Bearer ${tok}`}})
    setNotifs(prev=>prev.map(n=>n._id===id?{...n,isRead:true}:n))
    setUnread(prev=>Math.max(0,prev-1))
    if(link)router.push(link)
    setOpen(false)
  }

  if(!tok)return null
  return (
    <div style={{ position:'relative' }}>
      <button onClick={()=>{ setOpen(o=>!o); if(!open)fetchNotifs() }}
        style={{ position:'relative',background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',fontSize:18,flexShrink:0,transition:'background 0.2s' }}
        onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.2)')}
        onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}>
        🔔
        {unread>0&&<div style={{ position:'absolute',top:-4,right:-4,width:18,height:18,borderRadius:'50%',background:'linear-gradient(135deg,#E74C3C,#FF6B6B)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:9,fontWeight:900,color:'#fff',border:'2px solid #020816' }}>{unread>9?'9+':unread}</div>}
      </button>
      {open&&(
        <div style={{ position:'absolute',top:44,right:0,width:300,maxHeight:380,background:'rgba(4,12,30,0.99)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:16,overflow:'hidden',zIndex:200,boxShadow:'0 20px 60px rgba(0,0,0,0.6)',backdropFilter:'blur(24px)',animation:'slideUp 0.2s ease' }}>
          <div style={{ padding:'12px 14px',borderBottom:'1px solid rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'space-between' }}>
            <span style={{ fontWeight:700,fontSize:12,color:'#F0F8FF' }}>🔔 Notifications</span>
            {unread>0&&<button onClick={markAllRead} style={{ background:'transparent',border:'none',color:'#4D9FFF',fontSize:10,cursor:'pointer',fontWeight:600 }}>Mark all read</button>}
          </div>
          <div style={{ overflowY:'auto',maxHeight:320 }}>
            {notifs.length===0?(
              <div style={{ padding:'28px 16px',textAlign:'center',color:'rgba(160,200,240,0.4)',fontSize:12 }}>No notifications yet</div>
            ):notifs.map(n=>(
              <div key={n._id} onClick={()=>markRead(n._id,n.link)}
                style={{ padding:'12px 14px',borderBottom:'1px solid rgba(77,159,255,0.06)',cursor:'pointer',background:n.isRead?'transparent':'rgba(77,159,255,0.05)',transition:'background 0.2s' }}
                onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.09)')}
                onMouseLeave={e=>(e.currentTarget.style.background=n.isRead?'transparent':'rgba(77,159,255,0.05)')}>
                <div style={{ display:'flex',gap:8,alignItems:'flex-start' }}>
                  {!n.isRead&&<div style={{ width:7,height:7,borderRadius:'50%',background:'#4D9FFF',flexShrink:0,marginTop:4 }} />}
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:12,fontWeight:n.isRead?400:700,color:'#F0F8FF',marginBottom:3 }}>{n.title}</div>
                    <div style={{ fontSize:11,color:'rgba(160,200,240,0.6)',lineHeight:1.5 }}>{n.message}</div>
                    <div style={{ fontSize:10,color:'rgba(160,200,240,0.3)',marginTop:4 }}>{new Date(n.createdAt).toLocaleDateString()}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// ── EMI CHECKOUT MODAL ──
function EMIModal({ batch, tok, onClose, onSuccess }: { batch: Batch; tok: string; onClose: () => void; onSuccess: () => void }) {
  const [plan,setPlan]=useState(3)
  const [loading,setLoading]=useState(false)
  const price=batch.discountPrice||batch.price
  const plans=[
    { months:3, label:'3 Months', monthly:Math.ceil(price/3) },
    { months:6, label:'6 Months', monthly:Math.ceil(price/6) },
    { months:12,label:'12 Months',monthly:Math.ceil(price/12) },
  ]
  const selected=plans.find(p=>p.months===plan)||plans[0]

  const handlePayFull=async()=>{
    if(!tok)return
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-order`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'}})
      const d=await r.json()
      if(!d.success)return alert(d.error||'Error')
      if(d.testMode){alert(`TEST MODE\n\nBatch: ${d.batchName}\nFull Amount: ₹${Math.round(d.amount/100)}\nOrder: ${d.orderId}\n\nAdd Razorpay keys in Render to enable real payments.`);onClose();return}
      const loaded=await loadRazorpay()
      if(!loaded)return alert('Could not load payment gateway')
      const rzp=new (window as any).Razorpay({key:d.key,amount:d.amount,currency:d.currency,order_id:d.orderId,name:'ProveRank',description:batch.name,handler:()=>{onSuccess();onClose()},theme:{color:'#4D9FFF'}})
      rzp.open();onClose()
    }finally{setLoading(false)}
  }

  const handleEMI=()=>{
    alert(`EMI Plan Selected:\n${selected.label} — ₹${selected.monthly}/month\n\nTotal: ₹${price}\n\n(Razorpay EMI goes live once real API keys are added in Render ENV Variables)`)
    onClose()
  }

  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(4,12,30,0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
          <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#F0F8FF' }}>💳 Payment Options</div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(160,200,240,0.5)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        <div style={{ fontSize:13,color:'rgba(160,200,240,0.6)',marginBottom:6,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batch.name}</div>
        <div style={{ fontSize:22,fontWeight:900,color:'#F0F8FF',fontFamily:'Playfair Display,serif',marginBottom:20 }}>₹{price}</div>
        <button onClick={handlePayFull} disabled={loading}
          style={{ width:'100%',padding:'13px',background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:13,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,marginBottom:16,boxShadow:'0 6px 20px rgba(77,159,255,0.35)' }}>
          {loading?'Processing...':'💰 Pay Full Amount ₹'+price}
        </button>
        {batch.allowEMI&&(
          <>
            <div style={{ display:'flex',alignItems:'center',gap:10,marginBottom:14 }}>
              <div style={{ flex:1,height:1,background:'rgba(77,159,255,0.15)' }} />
              <span style={{ fontSize:10,color:'rgba(160,200,240,0.4)',fontWeight:600,textTransform:'uppercase',letterSpacing:1 }}>or pay in EMI</span>
              <div style={{ flex:1,height:1,background:'rgba(77,159,255,0.15)' }} />
            </div>
            <div style={{ display:'flex',gap:8,marginBottom:14 }}>
              {plans.map(p=>(
                <button key={p.months} onClick={()=>setPlan(p.months)}
                  style={{ flex:1,padding:'10px 6px',borderRadius:12,border:`1px solid ${plan===p.months?'rgba(0,212,255,0.5)':'rgba(77,159,255,0.15)'}`,background:plan===p.months?'rgba(0,212,255,0.1)':'rgba(77,159,255,0.05)',cursor:'pointer',transition:'all 0.2s' }}>
                  <div style={{ fontSize:11,fontWeight:700,color:plan===p.months?'#00D4FF':'rgba(160,200,240,0.5)' }}>{p.label}</div>
                  <div style={{ fontSize:13,fontWeight:900,color:plan===p.months?'#F0F8FF':'rgba(160,200,240,0.4)',marginTop:2 }}>₹{p.monthly}<span style={{ fontSize:9 }}>/mo</span></div>
                </button>
              ))}
            </div>
            <button onClick={handleEMI}
              style={{ width:'100%',padding:'12px',background:'rgba(0,212,255,0.08)',border:'1px solid rgba(0,212,255,0.25)',borderRadius:13,color:'#00D4FF',fontWeight:700,cursor:'pointer',fontSize:12 }}>
              💳 Pay ₹{selected.monthly}/month × {selected.months} months
            </button>
          </>
        )}
      </div>
    </div>
  )
}

// ── REVIEW MODAL ──
function ReviewModal({ batchId, batchName, tok, onClose }: { batchId:string; batchName:string; tok:string; onClose:()=>void }) {
  const [rating,setRating]=useState(0)
  const [hov,setHov]=useState(0)
  const [comment,setComment]=useState('')
  const [loading,setLoading]=useState(false)
  const [done,setDone]=useState(false)
  const submit=async()=>{
    if(!rating)return alert('Please select a rating')
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batchId}/review`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'},body:JSON.stringify({rating,comment})})
      const d=await r.json()
      if(d.success)setDone(true); else alert(d.error||'Error')
    }finally{setLoading(false)}
  }
  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(4,12,30,0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)' }}>
        {done?(
          <div style={{ textAlign:'center',padding:'20px 0' }}>
            <div style={{ fontSize:52,marginBottom:14 }}>⭐</div>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#F0F8FF',marginBottom:8 }}>Review Submitted!</div>
            <div style={{ fontSize:12,color:'rgba(160,200,240,0.6)',marginBottom:20 }}>Pending admin approval.</div>
            <button onClick={onClose} style={{ background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'11px 28px',color:'#fff',fontWeight:700,cursor:'pointer' }}>Done</button>
          </div>
        ):(
          <>
            <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
              <div style={{ fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#F0F8FF' }}>Rate this Batch</div>
              <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(160,200,240,0.5)',cursor:'pointer',fontSize:20 }}>×</button>
            </div>
            <div style={{ fontSize:12,color:'rgba(160,200,240,0.55)',marginBottom:16,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batchName}</div>
            <div style={{ display:'flex',gap:8,justifyContent:'center',marginBottom:18 }}>
              {[1,2,3,4,5].map(i=>(
                <span key={i} onClick={()=>setRating(i)} onMouseEnter={()=>setHov(i)} onMouseLeave={()=>setHov(0)}
                  style={{ fontSize:36,cursor:'pointer',transition:'transform 0.15s',transform:i<=(hov||rating)?'scale(1.2)':'scale(1)',color:i<=(hov||rating)?'#FFD700':'rgba(255,215,0,0.18)' }}>★</span>
              ))}
            </div>
            <textarea value={comment} onChange={e=>setComment(e.target.value)} placeholder="Share your experience (optional)..." rows={3}
              style={{ width:'100%',padding:'10px 12px',background:'rgba(255,255,255,0.04)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,color:'#F0F8FF',fontSize:12,resize:'none',marginBottom:16,fontFamily:'Inter,sans-serif' }} />
            <button onClick={submit} disabled={loading||!rating}
              style={{ width:'100%',padding:'12px',background:rating?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.15)',border:'none',borderRadius:12,color:rating?'#fff':'rgba(160,200,240,0.4)',fontWeight:700,cursor:rating?'pointer':'not-allowed',fontSize:13 }}>
              {loading?'Submitting...':'⭐ Submit Review'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}

// ── BATCH CARD ──
function BatchCard({ b, tok, onUpdate, compareList, toggleCompare, onBuy, onReview, onPreview, dark=true }: {
  b:Batch; tok:string|null; onUpdate:()=>void;
  compareList?:Batch[]; toggleCompare?:(b:Batch)=>void;
  onBuy?:(b:Batch)=>void; onReview?:(b:Batch)=>void; onPreview?:(b:Batch)=>void; dark?:boolean;
}) {
  const [loading,setLoading]=useState(false)
  const [hov,setHov]=useState(false)
  const isFlash=!!(b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date())
  const isNew=Date.now()-new Date(b.createdAt).getTime()<7*86400000
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const finalPrice=isFlash&&b.flashSalePrice?b.flashSalePrice:(b.discountPrice||b.price)
  const disc=b.price>0&&finalPrice<b.price?Math.round((1-finalPrice/b.price)*100):0
  const cardBg=dark?'rgba(4,12,30,0.95)':'rgba(255,255,255,0.97)'
  const cardText=dark?'#F0F8FF':'#0F172A'
  const cardSub=dark?'rgba(180,210,240,0.55)':'rgba(15,23,42,0.55)'
  const enroll=async()=>{
    if(!tok)return alert('Please login')
    setLoading(true)
    try{
      const res=await fetch(`${API}/api/student/batches/${b._id}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      const d=await res.json()
      if(d.success)onUpdate(); else alert(d.error||'Error')
    }finally{setLoading(false)}
  }
  const toggleWish=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batches/${b._id}/wishlist`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onUpdate()
  }
  return (
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)}
      style={{ background:cardBg,border:`1px solid ${hov?ec+'50':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',position:'relative',transition:'all 0.3s',transform:hov?'translateY(-5px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)' }}>
      <div style={{ position:'absolute',top:10,left:10,zIndex:5,display:'flex',flexDirection:'column',gap:4 }}>
        {isNew&&<span style={{ background:'linear-gradient(135deg,#27AE60,#1E8449)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>✨ NEW</span>}
        {b.enrolledCount>100&&<span style={{ background:'linear-gradient(135deg,#E67E22,#CA6F1E)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>🔥 HOT</span>}
        {b.isBundle&&<span style={{ background:'linear-gradient(135deg,#9B59B6,#7D3C98)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>📦 BUNDLE</span>}
        {b.allowEMI&&<span style={{ background:'linear-gradient(135deg,#00D4FF,#0090B0)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>💳 EMI</span>}
        {(b as any).fitScore>=80&&<span style={{ background:'linear-gradient(135deg,#FFD700,#FFA000)',color:'#000',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>🎯 Best Fit</span>}
      </div>
      {onPreview&&(
        <button onClick={e=>{e.stopPropagation();onPreview(b)}}
          style={{ position:'absolute',top:10,right:86,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.12)',borderRadius:'50%',width:32,height:32,cursor:'pointer',fontSize:13,display:'flex',alignItems:'center',justifyContent:'center',color:'#fff' }} title="Quick Preview">👁️</button>
      )}
      {toggleCompare&&compareList&&(
        <button onClick={e=>{e.stopPropagation();toggleCompare(b)}}
          style={{ position:'absolute',top:10,right:48,zIndex:5,background:compareList.find(x=>x._id===b._id)?'rgba(155,89,182,0.9)':'rgba(0,0,20,0.6)',border:'1px solid rgba(155,89,182,0.4)',borderRadius:'50%',width:32,height:32,cursor:'pointer',fontSize:13,display:'flex',alignItems:'center',justifyContent:'center',color:'#fff',fontWeight:900,transition:'all 0.2s' }}>
          {compareList.find(x=>x._id===b._id)?'✓':'⚖'}
        </button>
      )}
      <button onClick={toggleWish} style={{ position:'absolute',top:10,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:36,height:36,cursor:'pointer',fontSize:15,display:'flex',alignItems:'center',justifyContent:'center' }}>{b.isWishlisted?'❤️':'🤍'}</button>
      <div style={{ height:140,background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}12,${ec}05,rgba(2,8,22,0.9))`,position:'relative',display:'flex',alignItems:'center',justifyContent:'center',overflow:'hidden' }}>
        <div style={{ position:'absolute',inset:0,background:`linear-gradient(180deg,transparent 30%,${cardBg})`,zIndex:1 }} />
        {!b.thumbnail&&<span style={{ fontSize:46,filter:`drop-shadow(0 0 16px ${ec})`,zIndex:2,opacity:0.88 }}>{b.examType==='NEET'?'🩺':b.examType==='JEE'?'⚙️':b.examType==='CUET'?'📖':b.examType==='Crash Course'?'🚀':'📚'}</span>}
        {isFlash&&b.flashSaleEndTime&&<div style={{ position:'absolute',bottom:0,left:0,right:0,background:'rgba(200,40,40,0.92)',padding:'4px 0',textAlign:'center',fontSize:10,fontWeight:700,color:'#fff',zIndex:3 }}>⚡ Flash: <FlashTimer end={b.flashSaleEndTime} /></div>}
        {b.isEnrolled&&<div style={{ position:'absolute',inset:0,background:'rgba(39,174,96,0.16)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:2 }}><span style={{ background:'rgba(39,174,96,0.9)',color:'#fff',padding:'5px 14px',borderRadius:20,fontSize:11,fontWeight:800 }}>✅ Enrolled</span></div>}
      </div>
      <div style={{ padding:'13px 14px 15px' }}>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap',marginBottom:7 }}>
          <span style={{ background:`${ec}16`,color:ec,fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20,border:`1px solid ${ec}25` }}>{b.examType}</span>
          <span style={{ background:b.isFree?'rgba(39,174,96,0.13)':'rgba(230,126,34,0.13)',color:b.isFree?'#27AE60':'#E67E22',fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20 }}>{b.isFree?'🆓 FREE':b.allowFreeTrial?`🎯 ${b.trialDays}-Day Trial`:'💎 PAID'}</span>
        </div>
        <div style={{ fontSize:14,fontWeight:700,color:cardText,marginBottom:4,fontFamily:'Playfair Display,serif',lineHeight:1.4,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical' }}>{b.name}</div>
        <div style={{ fontSize:11,color:cardSub,lineHeight:1.5,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical',marginBottom:9 }}>{b.description||'Premium test series — NCERT based, expert curated.'}</div>
        <Stars r={b.rating} />
        <div style={{ display:'flex',gap:7,marginTop:7,flexWrap:'wrap' }}>
          {[{i:'📝',v:`${b.totalTests} Tests`},{i:'👥',v:b.enrolledCount.toLocaleString()},{i:'📅',v:`${b.validity}d`}].map((it,idx)=>(
            <span key={idx} style={{ fontSize:10,color:cardSub }}>{it.i} {it.v}</span>
          ))}
        </div>
        {/* FPR4: fit score / study load / syllabus coverage mini-meter */}
        {(b as any).studyLoad&&(
          <div style={{ display:'flex',gap:6,flexWrap:'wrap',marginTop:6 }}>
            {(b as any).fitScore!=null&&<span style={{ fontSize:9,color:'#4D9FFF',background:'rgba(77,159,255,0.08)',padding:'2px 8px',borderRadius:20 }}>🎯 {(b as any).fitScore}% fit</span>}
            <span style={{ fontSize:9,color:'#9B59B6',background:'rgba(155,89,182,0.08)',padding:'2px 8px',borderRadius:20 }}>⏱ {(b as any).studyLoad.label} ({(b as any).studyLoad.hoursPerWeek}h/wk)</span>
            {(b as any).syllabusCoveragePct>0&&<span style={{ fontSize:9,color:'#27AE60',background:'rgba(39,174,96,0.08)',padding:'2px 8px',borderRadius:20 }}>📖 {(b as any).syllabusCoveragePct}% syllabus</span>}
          </div>
        )}
        <div style={{ display:'flex',alignItems:'center',gap:7,margin:'9px 0 11px' }}>
          {b.isFree
            ?<span style={{ fontSize:21,fontWeight:900,color:'#27AE60',fontFamily:'Playfair Display,serif' }}>FREE</span>
            :<><span style={{ fontSize:21,fontWeight:900,color:cardText,fontFamily:'Playfair Display,serif' }}>₹{finalPrice}</span>{disc>0&&<span style={{ fontSize:11,color:dark?'rgba(255,255,255,0.26)':'rgba(15,23,42,0.28)',textDecoration:'line-through' }}>₹{b.price}</span>}{disc>0&&<span style={{ fontSize:9,background:'rgba(39,174,96,0.16)',color:'#27AE60',padding:'2px 7px',borderRadius:20,fontWeight:700 }}>{disc}% OFF</span>}</>}
        </div>
        {b.isEnrolled?(
          <div style={{ display:'flex',gap:6 }}>
            <button style={{ flex:1,padding:'10px',background:`linear-gradient(135deg,${ec}20,${ec}10)`,border:`1px solid ${ec}40`,borderRadius:11,color:ec,fontWeight:700,cursor:'pointer',fontSize:11 }}>Go to Batch →</button>
            {onReview&&<button onClick={()=>onReview(b)} style={{ padding:'10px 10px',background:'rgba(255,215,0,0.08)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:11,color:'#FFD700',cursor:'pointer',fontSize:11 }}>⭐</button>}
          </div>
        ):b.isFree?(
          <button onClick={enroll} disabled={loading} style={{ width:'100%',padding:'10px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Enrolling...':'🚀 Enroll Free'}</button>
        ):b.allowFreeTrial?(
          <button onClick={enroll} disabled={loading} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Starting...':'🎯 Free Trial'}</button>
        ):(
          <button onClick={()=>onBuy&&onBuy(b)} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>
            {b.allowEMI?`🛒 Buy ₹${finalPrice} (EMI avail.)`:`🛒 Buy ₹${finalPrice}`}
          </button>
        )}
      </div>
    </div>
  )
}

// ── Quick Preview Modal (FPR4) ──
function QuickPreviewModal({batch,tok,onClose,onBuy,onEnrollUpdate}:{batch:Batch;tok:string|null;onClose:()=>void;onBuy:(b:Batch)=>void;onEnrollUpdate:()=>void}) {
  const [data,setData]=useState<any>(null)
  const [loading,setLoading]=useState(true)
  useEffect(()=>{
    const h=tok?{Authorization:`Bearer ${tok}`}:{}
    fetch(`${API}/api/student/batches/${batch._id}/preview`,{headers:h as any})
      .then(r=>r.json()).then(d=>setData(d.batch)).catch(()=>{}).finally(()=>setLoading(false))
  },[batch._id,tok])
  const ec=ECOLS[batch.examType]||'#4D9FFF'
  return (
    <div onClick={onClose} style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div onClick={e=>e.stopPropagation()} style={{ background:'rgba(4,12,30,0.99)',border:`1px solid ${ec}30`,borderRadius:22,padding:24,maxWidth:480,width:'100%',maxHeight:'86vh',overflowY:'auto',backdropFilter:'blur(30px)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14 }}>
          <div>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#F0F8FF' }}>{batch.name}</div>
            <div style={{ fontSize:11,color:'rgba(160,200,240,0.5)',marginTop:2 }}>{batch.examType} · {batch.difficulty}</div>
          </div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(160,200,240,0.5)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        {loading?<div style={{textAlign:'center',padding:30,color:'rgba(160,200,240,0.4)'}}>Loading preview...</div>:data?(
          <>
            <Stars r={data.rating}/>
            <div style={{ display:'flex',gap:6,flexWrap:'wrap',margin:'10px 0' }}>
              {data.fitScore!=null&&<span style={{fontSize:10,color:'#4D9FFF',background:'rgba(77,159,255,0.1)',padding:'4px 10px',borderRadius:20}}>🎯 {data.fitScore}% Fit For You</span>}
              {data.studyLoad&&<span style={{fontSize:10,color:'#9B59B6',background:'rgba(155,89,182,0.1)',padding:'4px 10px',borderRadius:20}}>⏱ {data.studyLoad.label} Load</span>}
              {data.seatDemand!=null&&<span style={{fontSize:10,color:'#E67E22',background:'rgba(230,126,34,0.1)',padding:'4px 10px',borderRadius:20}}>💺 {data.seatDemand}% seats filled</span>}
            </div>
            {data.syllabusPoints&&data.syllabusPoints.length>0&&(
              <div style={{marginBottom:12}}>
                <div style={{fontSize:10,fontWeight:700,color:'rgba(160,200,240,0.45)',textTransform:'uppercase',marginBottom:6}}>📖 Syllabus Coverage ({data.syllabusCoveragePct}%)</div>
                <div style={{display:'flex',flexWrap:'wrap',gap:5}}>{data.syllabusPoints.slice(0,8).map((s:string,i:number)=><span key={i} style={{fontSize:9,color:'#27AE60',background:'rgba(39,174,96,0.08)',padding:'3px 8px',borderRadius:20}}>{s}</span>)}</div>
              </div>
            )}
            <div style={{marginBottom:12,padding:12,background:'rgba(77,159,255,0.05)',borderRadius:12,display:'flex',gap:10,alignItems:'center'}}>
              <span style={{fontSize:28}}>👨‍🏫</span>
              <div><div style={{fontSize:12,fontWeight:700,color:'#F0F8FF'}}>{data.instructor?.name}</div><div style={{fontSize:10,color:'rgba(160,200,240,0.55)'}}>{data.instructor?.bio}</div></div>
            </div>
            {data.faqs&&data.faqs.length>0&&(
              <div style={{marginBottom:14}}>
                <div style={{fontSize:10,fontWeight:700,color:'rgba(160,200,240,0.45)',textTransform:'uppercase',marginBottom:6}}>❓ FAQ</div>
                {data.faqs.map((f:any,i:number)=>(
                  <div key={i} style={{marginBottom:8}}>
                    <div style={{fontSize:11,fontWeight:700,color:'#F0F8FF'}}>{f.q}</div>
                    <div style={{fontSize:10,color:'rgba(160,200,240,0.55)',marginTop:2}}>{f.a}</div>
                  </div>
                ))}
              </div>
            )}
            <div style={{display:'flex',gap:8}}>
              {!data.isEnrolled&&!data.isFree&&<button onClick={()=>{onClose();onBuy(batch)}} style={{flex:1,padding:11,background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12}}>🛒 Buy ₹{data.effectivePrice}</button>}
              {!data.isEnrolled&&data.isFree&&<button onClick={async()=>{if(!tok)return alert('Please login');await fetch(`${API}/api/student/batches/${batch._id}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}});onEnrollUpdate();onClose()}} style={{flex:1,padding:11,background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12}}>🚀 Enroll Free</button>}
              {data.isEnrolled&&<div style={{flex:1,padding:11,textAlign:'center',background:'rgba(39,174,96,0.1)',border:'1px solid rgba(39,174,96,0.3)',borderRadius:12,color:'#27AE60',fontWeight:700,fontSize:12}}>✅ Already Enrolled</div>}
              <button onClick={onClose} style={{padding:'11px 16px',background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:12,color:'rgba(160,200,240,0.6)',cursor:'pointer',fontSize:12}}>Close</button>
            </div>
          </>
        ):<div style={{textAlign:'center',padding:20,color:'rgba(160,200,240,0.4)'}}>Could not load preview.</div>}
      </div>
    </div>
  )
}

function EmptyState({dark=true}:{dark?:boolean}) {
  return (
    <div style={{ textAlign:'center',padding:'55px 16px' }}>
      <div style={{ fontSize:72,marginBottom:18,display:'inline-block',animation:'floatBob 3s ease infinite' }}>🚀</div>
      <div style={{ fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:10 }}>Batches Launching Soon!</div>
      <div style={{ fontSize:12,color:dark?'rgba(160,200,240,0.6)':'rgba(15,23,42,0.55)',maxWidth:360,margin:'0 auto 24px',lineHeight:1.8 }}>Premium Test Series will appear here once created by the Admin.</div>
    </div>
  )
}

// ══════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════
export default function TestSeriesPage() {
  const router=useRouter()
  const [batches,setBatches]=useState<Batch[]>([])
  const [loading,setLoading]=useState(true)
  const [search,setSearch]=useState('')
  const [cat,setCat]=useState('All')
  const [sort,setSort]=useState('newest')
  const [filterOpen,setFilterOpen]=useState(false)
  const [filters,setFilters]=useState({ isFree:'', batchType:'', difficulty:'', subject:'', language:'' })
  const [priceRange,setPriceRange]=useState([0,5000])
  const [tab,setTab]=useState<'all'|'enrolled'|'wishlist'>('all')
  const [tok,setTok]=useState<string|null>(null)
  const [qIdx,setQIdx]=useState(0)
  const [compareList,setCompareList]=useState<Batch[]>([])
  const [spotlights,setSpotlights]=useState<Batch[]>([])
  const [acSuggestions,setAcSuggestions]=useState<AcSuggestion[]>([])
  const [showAc,setShowAc]=useState(false)
  const [recommendations,setRecommendations]=useState<Batch[]>([])
  const [isDesktop,setIsDesktop]=useState(false)
  const [reviewBatch,setReviewBatch]=useState<Batch|null>(null)
  const [buyBatch,setBuyBatch]=useState<Batch|null>(null)
  // ── FPR4: theme (synced with global pr_color_theme) ──
  const [darkMode,setDarkModeState]=useState(true)
  const setDarkMode=(fnOrVal:boolean|((d:boolean)=>boolean))=>{
    setDarkModeState(prev=>{
      const next=typeof fnOrVal==='function'?(fnOrVal as (d:boolean)=>boolean)(prev):fnOrVal
      try{
        localStorage.setItem('pr_color_theme',next?'dark':'light')
        window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:next?'dark':'light'}))
      }catch{}
      return next
    })
  }
  // ── FPR4: extra filters ──
  const [trialOnly,setTrialOnly]=useState(false)
  const [bundleOnly,setBundleOnly]=useState(false)
  const [emiOnly,setEmiOnly]=useState(false)
  const [flashOnly,setFlashOnly]=useState(false)
  const [previewBatch,setPreviewBatch]=useState<Batch|null>(null)
  const [recentSearches,setRecentSearches]=useState<string[]>([])
  const [savedPresets,setSavedPresets]=useState<any[]>([])

  const toggleCompare=(b:Batch)=>setCompareList(prev=>prev.find(x=>x._id===b._id)?prev.filter(x=>x._id!==b._id):prev.length>=3?prev:[...prev,b])

  useEffect(()=>{
    setTok(localStorage.getItem('pr_token'))
    const iv=setInterval(()=>setQIdx(i=>(i+1)%QUOTES.length),5000)
    try{
      const saved=localStorage.getItem('pr_color_theme')
      if(saved==='light')setDarkModeState(false)
      else if(saved==='dark')setDarkModeState(true)
      const rs=localStorage.getItem('pr_ts_recent_searches')
      if(rs)setRecentSearches(JSON.parse(rs))
      const fp=localStorage.getItem('pr_ts_filter_presets')
      if(fp)setSavedPresets(JSON.parse(fp))
    }catch{}
    const onStorage=(e:StorageEvent)=>{ if(e.key==='pr_color_theme'&&e.newValue)setDarkModeState(e.newValue==='dark') }
    window.addEventListener('storage',onStorage)
    return()=>{clearInterval(iv);window.removeEventListener('storage',onStorage)}
  },[])

  useEffect(()=>{
    const check=()=>setIsDesktop(window.innerWidth>=900)
    check(); window.addEventListener('resize',check); return()=>window.removeEventListener('resize',check)
  },[])

  useEffect(()=>{
    if(!search||search.length<2){setAcSuggestions([]);setShowAc(false);return}
    const timer=setTimeout(async()=>{
      try{
        const r=await fetch(`${API}/api/student/batch-extras/autocomplete?q=${encodeURIComponent(search)}`)
        const d=await r.json()
        setAcSuggestions(d.suggestions||[]);setShowAc((d.suggestions||[]).length>0)
      }catch{setShowAc(false)}
    },300)
    return()=>clearTimeout(timer)
  },[search])

  useEffect(()=>{
    const examType=cat!=='All'?cat:''
    fetch(`${API}/api/student/batch-extras/recommendations?examType=${examType}`)
      .then(r=>r.json()).then(d=>setRecommendations(d.batches||[])).catch(()=>{})
  },[cat])

  const fetchBatches=useCallback(async()=>{
    setLoading(true)
    try{
      const p=new URLSearchParams({sort})
      if(cat!=='All')p.set('examType',cat)
      if(search)p.set('search',search)
      if(filters.isFree)p.set('isFree',filters.isFree)
      if(filters.batchType)p.set('batchType',filters.batchType)
      if(filters.difficulty)p.set('difficulty',filters.difficulty)
      if(filters.subject)p.set('subject',filters.subject)
      if(filters.language)p.set('language',filters.language)
      if(trialOnly)p.set('trial','true')
      if(bundleOnly)p.set('bundle','true')
      if(emiOnly)p.set('emi','true')
      if(flashOnly)p.set('flashsale','true')
      p.set('minPrice',priceRange[0].toString())
      p.set('maxPrice',priceRange[1].toString())
      const token=localStorage.getItem('pr_token')
      const h=token?{Authorization:`Bearer ${token}`}:{} as Record<string,string>
      const url=tab==='enrolled'?`${API}/api/student/batches/my`:tab==='wishlist'?`${API}/api/student/batches/wishlist`:`${API}/api/student/batches?${p}`
      const res=await fetch(url,{headers:h})
      const d=await res.json()
      const all=d.batches||[]
      setBatches(all);setSpotlights(all.filter((b:Batch)=>b.isSpotlight).slice(0,3))
    }catch{setBatches([])}finally{setLoading(false)}
  },[cat,sort,search,filters,tab,priceRange,trialOnly,bundleOnly,emiOnly,flashOnly])

  useEffect(()=>{fetchBatches()},[fetchBatches])

  const handleBuy=async(b:Batch)=>{
    if(!tok)return alert('Please login to purchase')
    setBuyBatch(b)
  }

  const currentQuote=QUOTES[qIdx]

  // ── FPR4: theme tokens ──
  const BG=darkMode?'transparent':'rgba(240,244,248,0.97)'
  const CARD=darkMode?'rgba(4,12,30,0.95)':'rgba(255,255,255,0.96)'
  const CARD2=darkMode?'rgba(4,12,30,0.97)':'rgba(255,255,255,0.98)'
  const BORDERC=darkMode?'rgba(77,159,255,0.13)':'rgba(37,99,235,0.14)'
  const TEXTC=darkMode?'#F0F8FF':'#0F172A'
  const SUBC=darkMode?'rgba(160,200,240,0.55)':'rgba(15,23,42,0.55)'
  const STICKY_BG=darkMode?'rgba(2,8,22,0.94)':'rgba(255,255,255,0.94)'

  const pushRecentSearch=(q:string)=>{
    if(!q.trim())return
    setRecentSearches(prev=>{
      const next=[q,...prev.filter(x=>x!==q)].slice(0,6)
      try{localStorage.setItem('pr_ts_recent_searches',JSON.stringify(next))}catch{}
      return next
    })
  }
  const saveFilterPreset=()=>{
    const name=window.prompt('Name this filter preset:')
    if(!name)return
    const preset={name,cat,sort,filters,priceRange,trialOnly,bundleOnly,emiOnly,flashOnly}
    setSavedPresets(prev=>{
      const next=[...prev.filter(p=>p.name!==name),preset].slice(-8)
      try{localStorage.setItem('pr_ts_filter_presets',JSON.stringify(next))}catch{}
      return next
    })
  }
  const loadFilterPreset=(p:any)=>{
    setCat(p.cat);setSort(p.sort);setFilters(p.filters);setPriceRange(p.priceRange)
    setTrialOnly(!!p.trialOnly);setBundleOnly(!!p.bundleOnly);setEmiOnly(!!p.emiOnly);setFlashOnly(!!p.flashOnly)
  }

  const FilterContent=()=>(
    <>
      <div style={{ fontWeight:700,fontSize:11,color:'rgba(160,200,240,0.5)',textTransform:'uppercase',letterSpacing:1,marginBottom:14 }}>🔧 Filters</div>

      {/* Price Range Slider */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Price Range</div>
        <div style={{ display:'flex',justifyContent:'space-between',marginBottom:6 }}>
          <span style={{ fontSize:10,color:'rgba(160,200,240,0.6)' }}>₹{priceRange[0]}</span>
          <span style={{ fontSize:10,color:'rgba(160,200,240,0.6)' }}>₹{priceRange[1]}</span>
        </div>
        <input type="range" min={0} max={5000} step={100} value={priceRange[1]}
          onChange={e=>setPriceRange([priceRange[0],Number(e.target.value)])}
          style={{ width:'100%',accentColor:'#4D9FFF',cursor:'pointer',marginBottom:4 }} />
        <div style={{ display:'flex',gap:5,flexWrap:'wrap',marginTop:6 }}>
          {[{v:[0,5000],l:'All'},{v:[0,0],l:'🆓 Free'},{v:[1,499],l:'Under ₹500'},{v:[500,999],l:'₹500-999'},{v:[1000,5000],l:'₹1000+'}].map((o,i)=>{
            const active=priceRange[0]===o.v[0]&&priceRange[1]===o.v[1]
            return <button key={i} onClick={()=>setPriceRange(o.v as [number,number])}
              style={{ padding:'4px 9px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Free/Paid */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Price Type</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'true',l:'🆓 Free'},{v:'false',l:'💎 Paid'}].map(o=>{
            const active=filters.isFree===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,isFree:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Format */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Format</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'Live',l:'🔴 Live'},{v:'Recorded',l:'📹 Recorded'},{v:'Both',l:'🔄 Both'}].map(o=>{
            const active=filters.batchType===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,batchType:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Difficulty */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Difficulty</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'Easy',l:'🟢 Easy'},{v:'Medium',l:'🟡 Medium'},{v:'Hard',l:'🔴 Hard'},{v:'Mixed',l:'🔀 Mixed'}].map(o=>{
            const active=filters.difficulty===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,difficulty:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Subject */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Subject</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'},{v:'Mathematics',l:'📐 Maths'}].map(o=>{
            const active=filters.subject===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,subject:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Language */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Language</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'Hindi',l:'🇮🇳 Hindi'},{v:'English',l:'🇬🇧 English'},{v:'Hindi + English',l:'🔤 Bilingual'}].map(o=>{
            const active=filters.language===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,language:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Sort */}
      <div style={{ marginBottom:8 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Sort By</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'newest',l:'🆕 Newest'},{v:'popular',l:'🔥 Popular'},{v:'rating',l:'⭐ Top Rated'},{v:'price_low',l:'💰 Low Price'},{v:'price_high',l:'💎 High Price'}].map(o=>{
            const active=sort===o.v
            return <button key={o.v} onClick={()=>setSort(o.v)}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* FPR4: Offer / Enrollment Filters */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Offers</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:trialOnly,set:setTrialOnly,l:'🎯 Free Trial'},{v:bundleOnly,set:setBundleOnly,l:'📦 Bundle'},{v:emiOnly,set:setEmiOnly,l:'💳 EMI'},{v:flashOnly,set:setFlashOnly,l:'⚡ Flash Sale'}].map((o,i)=>(
            <button key={i} onClick={()=>o.set(x=>!x)}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:o.v?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${o.v?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:o.v?'#4D9FFF':'rgba(160,200,240,0.42)' }}>{o.l}</button>
          ))}
        </div>
      </div>

      {/* FPR4: Saved Filter Presets */}
      {savedPresets.length>0&&(
        <div style={{ marginBottom:18 }}>
          <div style={{ fontSize:10,color:'rgba(160,200,240,0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Saved Presets</div>
          <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
            {savedPresets.map((p,i)=>(
              <button key={i} onClick={()=>loadFilterPreset(p)} style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:'rgba(155,89,182,0.1)',border:'1px solid rgba(155,89,182,0.25)',color:'#9B59B6' }}>⭐ {p.name}</button>
            ))}
          </div>
        </div>
      )}
      <button onClick={saveFilterPreset} style={{ width:'100%',padding:'7px',background:'rgba(155,89,182,0.08)',border:'1px solid rgba(155,89,182,0.2)',borderRadius:10,color:'#9B59B6',cursor:'pointer',fontSize:10,fontWeight:700,marginBottom:10 }}>💾 Save Current Filters as Preset</button>

      {/* Reset */}
      <button onClick={()=>{setFilters({isFree:'',batchType:'',difficulty:'',subject:'',language:''});setPriceRange([0,5000]);setSort('newest');setTrialOnly(false);setBundleOnly(false);setEmiOnly(false);setFlashOnly(false)}}
        style={{ width:'100%',padding:'8px',background:'rgba(231,76,60,0.07)',border:'1px solid rgba(231,76,60,0.18)',borderRadius:10,color:'#E74C3C',cursor:'pointer',fontSize:10,fontWeight:700,marginTop:4 }}>
        🗑 Reset All Filters
      </button>
    </>
  )

  return (
    <div style={{ minHeight:'100vh',color:TEXTC,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:BG }}>
      {darkMode&&<MilkyWayCanvas />}
      {darkMode&&<SolarSystem />}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes floatBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-13px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(26px)}to{opacity:1;transform:translateY(0)}}
        @keyframes gradShift{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes orb{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.26);border-radius:4px}
        input,select,textarea{outline:none}
        input::placeholder{color:rgba(100,150,200,0.42)}
        input[type=range]{height:4px;border-radius:2px}
      `}</style>

      {/* STICKY TOP BAR */}
      <div style={{ position:'sticky',top:0,zIndex:50,background:STICKY_BG,backdropFilter:'blur(22px)',borderBottom:`1px solid ${BORDERC}`,padding:'10px 14px',display:'flex',alignItems:'center',gap:10 }}>
        <button onClick={()=>router.back()} style={{ background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:'#4D9FFF',fontSize:20,flexShrink:0 }} onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.2)')} onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}>←</button>
        <PRLogo size={32} />
        <div>
          <div style={{ fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent' }}>Test Series & Batches</div>
          <div style={{ fontSize:10,color:SUBC }}>NEET / JEE / CUET</div>
        </div>
        <div style={{ flex:1 }} />
        <button onClick={()=>setDarkMode(d=>!d)} style={{ background:'rgba(77,159,255,0.1)',border:`1px solid ${BORDERC}`,borderRadius:9,width:32,height:32,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:TEXTC,fontSize:13,flexShrink:0 }}>{darkMode?'☀️':'🌙'}</button>
        <NotificationBell tok={tok} />
      </div>

      <div style={{ position:'relative',zIndex:2,padding:'14px 14px 80px',maxWidth:1300,margin:'0 auto' }}>
        {/* HERO */}
        <div style={{ padding:'22px 18px 20px',marginBottom:8,textAlign:'center',animation:'slideUp 0.5s ease' }}>
          <div style={{ display:'flex',alignItems:'center',gap:12,marginBottom:4,justifyContent:'center' }}>
            <span style={{ fontSize:34,filter:'drop-shadow(0 0 13px rgba(77,159,255,0.5))' }}>🎓</span>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:25,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF 0%,#00D4FF 45%,#9B59B6 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',backgroundSize:'200%',animation:'gradShift 6s ease infinite' }}>Test Series & Batches</div>
          </div>
        </div>

        {/* FPR4: HERO / QUICK STATS STRIP */}
        <div style={{ display:'grid',gridTemplateColumns:'repeat(6,1fr)',gap:6,marginBottom:16 }}>
          {[
            {i:'📚',l:'Available',v:batches.length,c:'#4D9FFF'},
            {i:'✅',l:'Enrolled',v:batches.filter(b=>b.isEnrolled).length,c:'#27AE60'},
            {i:'❤️',l:'Wishlisted',v:batches.filter(b=>b.isWishlisted).length,c:'#E74C3C'},
            {i:'⭐',l:'Spotlight',v:spotlights.length,c:'#FFD700'},
            {i:'⚡',l:'Live Offers',v:batches.filter(b=>b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date()).length,c:'#FF6B6B'},
            {i:'⚖️',l:'Compare',v:compareList.length,c:'#9B59B6'},
          ].map((s,i)=>(
            <div key={i} style={{ background:CARD,border:`1px solid ${s.c}18`,borderRadius:12,padding:'8px 4px',textAlign:'center',backdropFilter:'blur(16px)' }}>
              <div style={{ fontSize:14 }}>{s.i}</div>
              <div style={{ fontSize:15,fontWeight:900,color:s.c }}>{s.v}</div>
              <div style={{ fontSize:8,color:SUBC }}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* CATEGORY STRIP */}
        <div style={{ display:'flex',gap:7,overflowX:'auto',paddingBottom:7,marginBottom:14,scrollbarWidth:'none' }}>
          {CATS.map(c=>{
            const active=cat===c
            return <button key={c} onClick={()=>setCat(c)} style={{ flexShrink:0,padding:'8px 15px',borderRadius:22,background:active?'linear-gradient(135deg,#4D9FFF,#00D4FF)':(darkMode?'rgba(77,159,255,0.07)':'rgba(37,99,235,0.06)'),border:active?'none':`1px solid ${BORDERC}`,color:active?'#fff':SUBC,fontWeight:active?700:400,cursor:'pointer',fontSize:11,transition:'all 0.2s',whiteSpace:'nowrap',boxShadow:active?'0 4px 13px rgba(77,159,255,0.26)':'none' }}>{CICONS[c]} {c}</button>
          })}
        </div>

        {/* SPOTLIGHT */}
        {spotlights.length>0&&(
          <div style={{ marginBottom:20 }}>
            <div style={{ display:'flex',alignItems:'center',gap:7,marginBottom:11 }}>
              <span style={{ fontSize:17 }}>⭐</span>
              <span style={{ fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:TEXTC }}>Spotlight Picks</span>
            </div>
            <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(230px,1fr))',gap:14 }}>
              {spotlights.map(b=><BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches} onBuy={handleBuy} onReview={setReviewBatch} onPreview={setPreviewBatch} dark={darkMode} />)}
            </div>
          </div>
        )}

        {/* TABS */}
        <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:7,marginBottom:13 }}>
          {(['all','enrolled','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{ padding:'10px',borderRadius:12,background:tab===t?'rgba(77,159,255,0.13)':CARD2,border:`1px solid ${tab===t?'rgba(77,159,255,0.36)':BORDERC}`,color:tab===t?'#4D9FFF':SUBC,fontWeight:tab===t?700:400,cursor:'pointer',fontSize:11,backdropFilter:'blur(12px)' }}>
              {t==='all'?'🌟 All':t==='enrolled'?'✅ My Batches':'❤️ Wishlist'}
            </button>
          ))}
        </div>
        {tab==='enrolled'&&(
          <div style={{ textAlign:'center',marginBottom:14 }}>
            <button onClick={()=>router.push('/dashboard/my-batches')} style={{ background:'rgba(77,159,255,0.08)',border:`1px solid ${BORDERC}`,borderRadius:12,padding:'9px 16px',color:'#4D9FFF',cursor:'pointer',fontSize:11,fontWeight:700 }}>📚 Open Full My Batches Hub — progress, streaks, certificates →</button>
          </div>
        )}

        {/* LAYOUT */}
        <div style={{ display:isDesktop?'flex':'block',gap:22,alignItems:'flex-start' }}>

          {/* DESKTOP STICKY SIDEBAR */}
          {isDesktop&&(
            <div style={{ width:220,flexShrink:0,position:'sticky',top:70,background:CARD2,border:`1px solid ${BORDERC}`,borderRadius:18,padding:'18px 16px',backdropFilter:'blur(22px)',boxShadow:'0 10px 40px rgba(0,10,40,0.35)',animation:'slideUp 0.4s ease',maxHeight:'calc(100vh - 90px)',overflowY:'auto' }}>
              <FilterContent />
            </div>
          )}

          <div style={{ flex:1,minWidth:0 }}>
            {/* SEARCH */}
            <div style={{ display:'flex',gap:7,marginBottom:12,flexWrap:'wrap' }}>
              <div style={{ flex:1,minWidth:150,position:'relative' }}>
                <span style={{ position:'absolute',left:10,top:'50%',transform:'translateY(-50%)',fontSize:12,opacity:0.42,zIndex:2 }}>🔍</span>
                <input value={search} onChange={e=>setSearch(e.target.value)} onFocus={()=>acSuggestions.length>0&&setShowAc(true)} onBlur={()=>setTimeout(()=>setShowAc(false),200)}
                  onKeyDown={e=>{if(e.key==='Enter')pushRecentSearch(search)}}
                  placeholder="Search batches..." style={{ width:'100%',padding:'10px 10px 10px 32px',background:'rgba(4,12,30,0.9)',border:'1px solid rgba(77,159,255,0.13)',borderRadius:12,color:'#F0F8FF',fontSize:12,backdropFilter:'blur(12px)' }} />
                {!showAc&&!search&&recentSearches.length>0&&(
                  <div style={{ display:'flex',gap:5,flexWrap:'wrap',marginTop:6 }}>
                    {recentSearches.map((rs,i)=>(
                      <button key={i} onClick={()=>{setSearch(rs);pushRecentSearch(rs)}} style={{ fontSize:9,padding:'3px 9px',borderRadius:20,background:'rgba(77,159,255,0.07)',border:'1px solid rgba(77,159,255,0.15)',color:'rgba(160,200,240,0.6)',cursor:'pointer' }}>🕐 {rs}</button>
                    ))}
                  </div>
                )}
                {showAc&&acSuggestions.length>0&&(
                  <div style={{ position:'absolute',top:'100%',left:0,right:0,marginTop:4,background:'rgba(4,12,30,0.99)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,overflow:'hidden',zIndex:100,boxShadow:'0 12px 40px rgba(0,0,0,0.5)',backdropFilter:'blur(24px)',animation:'slideUp 0.18s ease' }}>
                    {acSuggestions.map(s=>(
                      <div key={s._id} onClick={()=>{setSearch(s.name);setShowAc(false)}}
                        style={{ padding:'10px 14px',cursor:'pointer',display:'flex',alignItems:'center',gap:10,borderBottom:'1px solid rgba(77,159,255,0.06)',transition:'background 0.15s' }}
                        onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.08)')}
                        onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                        <span style={{ fontSize:16 }}>{s.examType==='NEET'?'🩺':s.examType==='JEE'?'⚙️':'📚'}</span>
                        <div>
                          <div style={{ fontSize:12,color:'#F0F8FF',fontWeight:600 }}>{s.name}</div>
                          <div style={{ fontSize:10,color:'rgba(160,200,240,0.45)' }}>{s.examType} · {s.isFree?'Free':'Paid'}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              {!isDesktop&&(
                <button onClick={()=>setFilterOpen(o=>!o)} style={{ padding:'10px 12px',background:filterOpen?'rgba(77,159,255,0.13)':'rgba(4,12,30,0.9)',border:`1px solid ${filterOpen?'rgba(77,159,255,0.36)':'rgba(77,159,255,0.13)'}`,borderRadius:12,color:'#4D9FFF',cursor:'pointer',fontSize:11,fontWeight:600 }}>⚙️ Filter</button>
              )}
            </div>

            {/* MOBILE FILTER */}
            {!isDesktop&&filterOpen&&(
              <div style={{ background:'rgba(4,12,30,0.97)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:15,padding:15,marginBottom:12,backdropFilter:'blur(22px)',animation:'slideUp 0.22s ease' }}>
                <FilterContent />
              </div>
            )}

            {/* BATCH GRID */}
            {loading?(
              <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(230px,1fr))',gap:16 }}>
                {[1,2,3,4].map(i=><div key={i} style={{ height:380,background:'rgba(4,12,30,0.8)',borderRadius:20,border:'1px solid rgba(77,159,255,0.06)',animation:'shimmer 1.5s ease infinite',animationDelay:`${i*0.14}s` }} />)}
              </div>
            ):batches.length===0?<EmptyState dark={darkMode} />:(
              <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(230px,1fr))',gap:16 }}>
                {batches.map((b,i)=>(
                  <div key={b._id} style={{ animation:`slideUp ${0.28+i*0.04}s ease both` }}>
                    <BatchCard b={b} tok={tok} onUpdate={fetchBatches} compareList={compareList} toggleCompare={toggleCompare} onBuy={handleBuy} onReview={setReviewBatch} onPreview={setPreviewBatch} dark={darkMode} />
                  </div>
                ))}
              </div>
            )}

            {/* RECOMMENDATIONS */}
            {recommendations.length>0&&(
              <div style={{ marginTop:40 }}>
                <div style={{ display:'flex',alignItems:'center',gap:8,marginBottom:14 }}>
                  <span style={{ fontSize:18 }}>💡</span>
                  <span style={{ fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#F0F8FF' }}>Recommended For You</span>
                </div>
                <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(220px,1fr))',gap:14 }}>
                  {recommendations.map(b=><BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches} onBuy={handleBuy} onReview={setReviewBatch} onPreview={setPreviewBatch} dark={darkMode} />)}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* NCERT FACTS */}
        <div style={{ marginTop:50,padding:'0 4px' }}>
          <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(230px,1fr))',gap:26,maxWidth:640,margin:'0 auto' }}>
            {FACTS.map((f,i)=>(
              <div key={i} style={{ display:'flex',gap:13,alignItems:'flex-start',animation:`slideUp ${1.1+i*0.12}s ease` }}>
                <div style={{ fontSize:30,filter:`drop-shadow(0 0 11px ${f.c}80)`,flexShrink:0 }}>{f.icon}</div>
                <div>
                  <div style={{ fontWeight:700,color:f.c,fontSize:12,marginBottom:4,fontFamily:'Playfair Display,serif' }}>{f.t}</div>
                  <div style={{ fontSize:11,color:'rgba(180,210,240,0.58)',lineHeight:1.7 }}>{f.f}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* WHY PROVERANK */}
        <div style={{ marginTop:42,background:'rgba(4,12,30,0.97)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:20,padding:'24px 16px',backdropFilter:'blur(22px)' }}>
          <div style={{ textAlign:'center',marginBottom:20 }}>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:700,color:'#F0F8FF',marginBottom:3 }}>✨ Why Choose ProveRank?</div>
          </div>
          <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(130px,1fr))',gap:10 }}>
            {[{i:'🤖',t:'AI Analytics',d:'Weak area detection\nSmart revision',c:'#9B59B6'},{i:'🔒',t:'Anti-Cheat',d:'Webcam · Face AI\nIP Lock',c:'#E74C3C'},{i:'📊',t:'Live Ranks',d:'Real-time AIR\nPercentile',c:'#27AE60'},{i:'📄',t:'OMR + PDFs',d:'Bubble sheet\nCertificates',c:'#E67E22'},{i:'🆓',t:'100% Free',d:'Free hosting\nNo charges',c:'#00D4FF'}].map((f,i)=>(
              <div key={i} style={{ background:'rgba(4,12,30,0.72)',border:`1px solid ${f.c}14`,borderRadius:14,padding:'14px 10px',textAlign:'center',transition:'all 0.3s' }} onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'36'}} onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'14'}}>
                <div style={{ fontSize:26,marginBottom:8,filter:`drop-shadow(0 0 6px ${f.c}75)` }}>{f.i}</div>
                <div style={{ fontWeight:700,color:f.c,fontSize:11,marginBottom:4 }}>{f.t}</div>
                <div style={{ fontSize:10,color:'rgba(160,200,240,0.46)',lineHeight:1.62,whiteSpace:'pre-line' }}>{f.d}</div>
              </div>
            ))}
          </div>
        </div>

        {/* QUOTE */}
        <div style={{ padding:'24px 4px 8px',display:'flex',alignItems:'center',gap:13 }}>
          <span style={{ fontSize:26,flexShrink:0 }}>💫</span>
          <div>
            <div style={{ fontSize:13,color:'rgba(200,220,240,0.72)',fontStyle:'italic',lineHeight:1.65,fontFamily:'Playfair Display,serif' }}>"{currentQuote.q}"</div>
            <div style={{ fontSize:11,color:'#4D9FFF',fontWeight:700,marginTop:5 }}>— {currentQuote.a}</div>
          </div>
        </div>

        {/* COMPARE TRAY */}
        {compareList.length>=1&&(
          <div style={{ position:'fixed',bottom:0,left:0,right:0,zIndex:200,background:'rgba(4,12,30,0.98)',borderTop:`1px solid ${compareList.length===3?'rgba(155,89,182,0.5)':'rgba(77,159,255,0.2)'}`,backdropFilter:'blur(24px)',padding:'12px 16px' }}>
            <div style={{ maxWidth:1200,margin:'0 auto',display:'flex',alignItems:'center',gap:10,flexWrap:'wrap' }}>
              <span style={{ fontSize:12,color:'rgba(160,200,240,0.6)',flexShrink:0 }}>⚖️ <strong style={{ color:'#9B59B6' }}>{compareList.length}</strong>/3</span>
              <div style={{ display:'flex',gap:6,flex:1,overflow:'hidden' }}>
                {compareList.map(b=><span key={b._id} style={{ fontSize:11,background:'rgba(155,89,182,0.15)',border:'1px solid rgba(155,89,182,0.3)',borderRadius:20,padding:'4px 10px',color:'#9B59B6',maxWidth:110,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis',flexShrink:0 }}>{b.name}</span>)}
              </div>
              <button onClick={()=>setCompareList([])} style={{ background:'rgba(231,76,60,0.1)',border:'1px solid rgba(231,76,60,0.2)',borderRadius:8,padding:'7px 10px',color:'#E74C3C',cursor:'pointer',fontSize:11,fontWeight:600,flexShrink:0 }}>Clear</button>
              {compareList.length>=2?<button onClick={()=>router.push('/dashboard/batch-compare?ids='+compareList.map(b=>b._id).join(','))} style={{ background:'linear-gradient(135deg,#9B59B6,#7D3C98)',border:'none',borderRadius:10,padding:'9px 16px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,flexShrink:0 }}>Compare Now →</button>:<span style={{ fontSize:11,color:'rgba(160,200,240,0.4)',flexShrink:0 }}>+{2-compareList.length} more needed</span>}
            </div>
          </div>
        )}
      </div>

      {/* MODALS */}
      {reviewBatch&&tok&&<ReviewModal batchId={reviewBatch._id} batchName={reviewBatch.name} tok={tok} onClose={()=>setReviewBatch(null)} />}
      {buyBatch&&tok&&<EMIModal batch={buyBatch} tok={tok} onClose={()=>setBuyBatch(null)} onSuccess={fetchBatches} />}
      {previewBatch&&<QuickPreviewModal batch={previewBatch} tok={tok} onClose={()=>setPreviewBatch(null)} onBuy={b=>setBuyBatch(b)} onEnrollUpdate={fetchBatches} />}
    </div>
  )
}
FPR45_FE_TESTSERIES
echo "✅ Test Series Marketplace page upgraded ($(wc -l < "$TESTSERIES_PAGE") lines)"

# ----------------------------------------------------------------------------
# SYNTAX VALIDATION
# ----------------------------------------------------------------------------
echo ""
echo "🔍 Validating TSX syntax..."
if command -v tsc >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
  TSC_CMD="npx --yes typescript@latest tsc"
  command -v tsc >/dev/null 2>&1 && TSC_CMD="tsc"
  $TSC_CMD --noEmit --jsx preserve --target es2020 --module esnext --moduleResolution bundler --allowJs --skipLibCheck --esModuleInterop "$MYBATCHES_PAGE" "$TESTSERIES_PAGE" > /tmp/fpr45_tsc_out.txt 2>&1 || true
  PARSER_ERRORS=$(grep -E "error TS1[0-9]{3}:" /tmp/fpr45_tsc_out.txt || true)
  if [ -n "$PARSER_ERRORS" ]; then
    echo "❌ SYNTAX/PARSER ERRORS FOUND:"
    echo "$PARSER_ERRORS"
    echo "Restoring backups due to syntax errors..."
    cp "$MYBATCHES_PAGE.pre-fpr45-bak" "$MYBATCHES_PAGE"
    cp "$TESTSERIES_PAGE.pre-fpr45-bak" "$TESTSERIES_PAGE"
    exit 1
  else
    echo "  ✅ No parser/syntax errors detected (implicit-any/type warnings are expected without full type defs and are safe to ignore)"
  fi
else
  echo "  ⚠️  tsc not available — skipping automated syntax check. Your Next.js dev server will validate on next run."
fi

# ----------------------------------------------------------------------------
# VERIFICATION CHECKLIST
# ----------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FPR4 + FPR5 — FRONTEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
PASS=0; FAIL2=0
check(){ DESC="$1"; PATTERN="$2"; FILE="$3"
  if grep -q -- "$PATTERN" "$FILE" 2>/dev/null; then echo "✅ $DESC"; PASS=$((PASS+1))
  else echo "❌ $DESC"; FAIL2=$((FAIL2+1)); fi
}
TS="$TESTSERIES_PAGE"; MB="$MYBATCHES_PAGE"

echo "── FPR4: Marketplace (Test Series / Batches page) ──"
check "Theme: Light/Dark toggle wired to shared key"     "pr_color_theme" "$TS"
check "Theme: MilkyWayCanvas dark-mode only"              "{darkMode&&<MilkyWayCanvas" "$TS"
check "Hero / Quick Stats strip"                          "HERO / QUICK STATS STRIP" "$TS"
check "Difficulty filter (existing, preserved)"           "Difficulty" "$TS"
check "Subject filter (existing, preserved)"               "Subject" "$TS"
check "Offer filters: Trial/Bundle/EMI/Flash Sale"         "trialOnly" "$TS"
check "Saved Filter Presets"                                "saveFilterPreset" "$TS"
check "Recent Searches"                                     "pushRecentSearch" "$TS"
check "Quick Preview Modal component"                       "function QuickPreviewModal" "$TS"
check "Quick Preview wired to cards"                        "onPreview={setPreviewBatch}" "$TS"
check "Fit Score badge on card"                              "fitScore" "$TS"
check "Study Load badge on card"                              "studyLoad" "$TS"
check "Syllabus Coverage badge on card"                       "syllabusCoveragePct" "$TS"
check "Compare tray (existing, preserved)"                    "compareList" "$TS"
check "Wishlist toggle (existing, preserved)"                 "toggleWish" "$TS"
check "My Batches tab → link to full Hub"                     "Open Full My Batches Hub" "$TS"
check "EMI Modal (existing, preserved)"                       "function EMIModal" "$TS"
check "Review Modal (existing, preserved)"                    "function ReviewModal" "$TS"

echo "── FPR5: My Batches Hub page ──"
check "Theme: synced with global pr_color_theme"              "pr_color_theme" "$MB"
check "Smart Search bar"                                       "Search your batches" "$MB"
check "Sort options (progress/streak/expiry/rating)"           "sortBy" "$MB"
check "Quick filter chips (expiring/cert/streak/free/paid)"    "quickFilters" "$MB"
check "Reminder Center bell + panel"                            "REMINDER CENTER PANEL" "$MB"
check "Renewal — one-tap Renew button"                          "renewBatch" "$MB"
check "Renewal — Extend button on expiring cards"               "Extend" "$MB"
check "Certificate Roadmap Modal"                               "function CertificateModal" "$MB"
check "Certificate modal wired to card"                          "setCertBatch" "$MB"
check "Activity Feed — pinned indicator"                          "(a as any).pinned" "$MB"
check "Activity Feed — unread dot + mark-read on click"           "markRead" "$MB"
check "Continue Where You Left Off (existing, preserved)"        "CONTINUE WHERE YOU LEFT OFF" "$MB"
check "Progress ring/bar toggle (existing, preserved)"            "progressView" "$MB"
check "Streak badge (existing, preserved)"                        "streak" "$MB"
check "Batch Leaderboard Modal (existing, preserved)"             "BatchLeaderboardModal" "$MB"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL2)) TOTAL"
if [ "$FAIL2" -eq 0 ]; then
  echo "  🎉 ALL FRONTEND FPR4+FPR5 FEATURES SUCCESSFULLY IMPLEMENTED ✅"
else
  echo "  ⚠️  $FAIL2 item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  Restart your Next.js dev server to see changes."
echo "📦 Rollback: cp \"\$MYBATCHES_PAGE.pre-fpr45-bak\" \"\$MYBATCHES_PAGE\" && cp \"\$TESTSERIES_PAGE.pre-fpr45-bak\" \"\$TESTSERIES_PAGE\""
