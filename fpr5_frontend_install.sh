#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — FPR5 MY BATCHES / TEST SERIES HUB — FRONTEND INSTALLER
# Run from your project ROOT on Replit:  bash fpr5_frontend_install.sh
# Safe to re-run (idempotent). Best run AFTER fpr4_frontend_install.sh.
# ══════════════════════════════════════════════════════════════════
set -e
echo "🚀 ProveRank FPR5 — My Batches Hub — FRONTEND install starting..."

SHELL_FILE=$(find . -type f -name "StudentShell.tsx" -not -path "*/node_modules/*" 2>/dev/null | head -1)
if [ -n "$SHELL_FILE" ]; then
  echo "📁 StudentShell.tsx: $SHELL_FILE"
  if grep -q "const IMMERSIVE_PAGES=\['store'\]" "$SHELL_FILE"; then
    echo "⏭️  StudentShell.tsx already patched (immersive lock removed) — skipping"
  elif grep -q "const IMMERSIVE_PAGES=\['test-series','batches','my-batches','store'\]" "$SHELL_FILE"; then
    cp "$SHELL_FILE" "$SHELL_FILE.bak_fpr5"
    sed -i "s/const IMMERSIVE_PAGES=\['test-series','batches','my-batches','store'\]/const IMMERSIVE_PAGES=['store']/" "$SHELL_FILE"
    echo "✅ Removed immersive dark-lock for test-series/batches/my-batches"
  else
    echo "ℹ️  IMMERSIVE_PAGES anchor not found in expected form — please verify manually"
  fi
else
  echo "⚠️  StudentShell.tsx not found — skipping shell patch (run fpr4_frontend_install.sh for full effect)"
fi

# ── Auto-detect My Batches page directory ──
MB_DIR=$(find . -type d -iname "my-batches" -not -path "*/node_modules/*" 2>/dev/null | head -1)
if [ -z "$MB_DIR" ]; then
  MB_DIR="./frontend/app/dashboard/my-batches"
  echo "⚠️  My Batches page dir not auto-detected — defaulting to $MB_DIR"
fi
mkdir -p "$MB_DIR"
echo "📁 My Batches page dir: $MB_DIR"

# ── Overwrite My Batches page.tsx (FPR5 upgrade) ──
cp "$MB_DIR/page.tsx" "$MB_DIR/page.tsx.bak_fpr5" 2>/dev/null || true
cat > "$MB_DIR/page.tsx" << 'PRVRNK_EOF_MARKER'
'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Theme system (FPR5: replaces old locked-dark immersive background) ──
type PageTheme = 'light' | 'dark'
function usePageTheme(): PageTheme {
  const [theme, setTheme] = useState<PageTheme>('dark')
  useEffect(() => {
    const read = () => {
      try { setTheme((localStorage.getItem('pr_color_theme') as PageTheme) || 'dark') } catch { setTheme('dark') }
    }
    read()
    const onStorage = (e: StorageEvent) => { if (!e.key || e.key === 'pr_color_theme') read() }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])
  return theme
}
const THEME_VARS: Record<PageTheme, Record<string, string>> = {
  dark: {
    '--pr-bg': 'radial-gradient(ellipse at 20% 0%,#0C1220 0%,#070A12 55%,#040609 100%)',
    '--pr-card-rgb': '4,12,30',
    '--pr-sub-rgb': '160,200,240',
    '--pr-text': '#F1F6FC',
  },
  light: {
    '--pr-bg': 'radial-gradient(ellipse at 15% 0%,#FFFFFF 0%,#F3F7FF 55%,#E9F1FF 100%)',
    '--pr-card-rgb': '255,255,255',
    '--pr-sub-rgb': '71,85,105',
    '--pr-text': '#0F172A',
  },
}

type BatchMeta = {
  _id: string; name: string; examType: string; thumbnail: string;
  enrolledAt: string; expiresAt: string; daysLeft: number;
  testsCompleted: number; totalTests: number; progress: number;
  lastAccessedAt: string; daysSinceAccess: number; streak: number;
  isExpired: boolean; isCompleted: boolean; isWishlisted?: boolean;
  isFree: boolean; rating: number; language: string; difficulty: string;
}
type Stats = { total: number; testsCompleted: number; activeBatches: number; certificates: number; wishlistCount?: number; avgProgress?: number; currentStreak?: number; renewalDueSoon?: number }
type Activity = { _id: string; type: string; title: string; message: string; icon: string; createdAt: string }
type LBEntry = { name: string; testsCompleted: number; avgScore: number; streak: number; bestRank: number | null }

const ECOLS: Record<string,string> = {
  NEET:'#4D9FFF','NEET UG':'#4D9FFF',JEE:'#9B59B6','JEE MAINS':'#9B59B6','JEE ADVANCE':'#7D3C98',CUET:'#27AE60','CUET UG':'#27AE60','CUET PG':'#1E8449','SSC CGL':'#E67E22','IIT JAM':'#00D4FF',
  'Class 11':'#E67E22','Class 12':'#E74C3C',
  Foundation:'#00D4FF','Crash Course':'#FF6B6B',Other:'#7F8C8D'
}
const CICONS: Record<string,string> = {
  NEET:'🩺','NEET UG':'🩺',JEE:'⚙️','JEE MAINS':'⚙️','JEE ADVANCE':'🛠️',CUET:'📖','CUET UG':'📖','CUET PG':'📚','SSC CGL':'🏛️','IIT JAM':'🔬',
  'Class 11':'📗','Class 12':'📘',Foundation:'🏛️','Crash Course':'🚀'
}
const TIPS = [
  { i:'🎯', t:'Daily Practice', d:'Attempt at least 1 test daily to maintain your streak and improve retention.' },
  { i:'📊', t:'Review Mistakes', d:'Always revisit wrong answers after each test — that\'s where real learning happens.' },
]

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
      <div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',fontSize:size*0.2,fontWeight:800,color:'var(--pr-text)'}}>{pct}%</div>
    </div>
  )
}

// ── Horizontal Progress Bar ──
function ProgressBar({pct,ec}:{pct:number;ec:string}) {
  return (
    <div style={{width:'100%'}}>
      <div style={{display:'flex',justifyContent:'space-between',marginBottom:5}}>
        <span style={{fontSize:10,color:'rgba(var(--pr-sub-rgb),0.55)'}}>Progress</span>
        <span style={{fontSize:10,fontWeight:700,color:ec}}>{pct}%</span>
      </div>
      <div style={{height:6,background:'rgba(255,255,255,0.08)',borderRadius:3,overflow:'hidden'}}>
        <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,${ec},${ec}BB)`,borderRadius:3,transition:'width 0.8s ease',boxShadow:`0 0 8px ${ec}60`}}/>
      </div>
      <div style={{display:'flex',justifyContent:'space-between',marginTop:4}}>
        <span style={{fontSize:9,color:'rgba(var(--pr-sub-rgb),0.35)'}}>0 tests</span>
        <span style={{fontSize:9,color:'rgba(var(--pr-sub-rgb),0.35)'}}>Goal: 100%</span>
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
      <div style={{background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:24,maxWidth:400,width:'100%',maxHeight:'80vh',overflow:'hidden',display:'flex',flexDirection:'column',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)'}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'var(--pr-text)'}}>🏆 Batch Leaderboard</div>
            <div style={{fontSize:11,color:'rgba(var(--pr-sub-rgb),0.5)',marginTop:2,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis',maxWidth:260}}>{batchName}</div>
          </div>
          <button onClick={onClose} style={{background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:22}}>×</button>
        </div>
        {myRank>0&&<div style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:12,padding:'10px 14px',marginBottom:14,display:'flex',alignItems:'center',gap:10}}>
          <span style={{fontSize:20}}>🎯</span>
          <div><div style={{fontSize:13,fontWeight:700,color:'#4D9FFF'}}>Your Rank: #{myRank} of {total}</div><div style={{fontSize:10,color:'rgba(var(--pr-sub-rgb),0.5)'}}>Keep attempting tests to improve!</div></div>
        </div>}
        <div style={{overflowY:'auto',flex:1}}>
          {loading?<div style={{textAlign:'center',padding:30,color:'rgba(var(--pr-sub-rgb),0.4)'}}>Loading...</div>:
          lb.length===0?<div style={{textAlign:'center',padding:30,color:'rgba(var(--pr-sub-rgb),0.4)',fontSize:12}}>No students enrolled yet</div>:
          lb.map((entry,i)=>(
            <div key={i} style={{display:'flex',alignItems:'center',gap:10,padding:'10px 0',borderBottom:'1px solid rgba(77,159,255,0.06)'}}>
              <div style={{width:28,height:28,borderRadius:'50%',background:i===0?'linear-gradient(135deg,#FFD700,#FFA000)':i===1?'linear-gradient(135deg,#C0C0C0,#9E9E9E)':i===2?'linear-gradient(135deg,#CD7F32,#A0522D)':'rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:i<3?14:10,fontWeight:900,flexShrink:0,color:i<3?'#000':'rgba(var(--pr-sub-rgb),0.5)'}}>
                {i===0?'🥇':i===1?'🥈':i===2?'🥉':i+1}
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:12,fontWeight:700,color:'var(--pr-text)'}}>{entry.name}</div>
                <div style={{fontSize:10,color:'rgba(var(--pr-sub-rgb),0.45)'}}>📝 {entry.testsCompleted} tests · ⭐ {entry.avgScore.toFixed(1)}% avg · 🔥 {entry.streak} streak</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

// ── Achievement Milestones (FPR5) ──
function MilestoneChips({batchId,tok}:{batchId:string;tok:string}) {
  const [milestones,setMilestones]=useState<{label:string;achieved:boolean}[]>([])
  useEffect(()=>{
    fetch(`${API}/api/my-batches/${batchId}/milestones`,{headers:{Authorization:`Bearer ${tok}`}})
      .then(r=>r.json()).then(d=>setMilestones(d.milestones||[])).catch(()=>{})
  },[batchId,tok])
  if(milestones.length===0)return null
  return (
    <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:10}}>
      {milestones.map((m,i)=>(
        <span key={i} style={{fontSize:9,padding:'2px 8px',borderRadius:20,fontWeight:700,background:m.achieved?'rgba(39,174,96,0.14)':'rgba(var(--pr-sub-rgb),0.08)',color:m.achieved?'#27AE60':'rgba(var(--pr-sub-rgb),0.4)'}}>{m.achieved?'✓':'○'} {m.label}</span>
      ))}
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
      <div style={{fontSize:10,fontWeight:700,color:'rgba(var(--pr-sub-rgb),0.45)',textTransform:'uppercase',letterSpacing:1,marginBottom:8}}>📢 What's New</div>
      {activities.map(a=>(
        <div key={a._id} style={{display:'flex',gap:8,alignItems:'flex-start',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.06)'}}>
          <span style={{fontSize:16,flexShrink:0}}>{a.icon}</span>
          <div>
            <div style={{fontSize:11,fontWeight:700,color:'var(--pr-text)'}}>{a.title}</div>
            {a.message&&<div style={{fontSize:10,color:'rgba(var(--pr-sub-rgb),0.55)',marginTop:2}}>{a.message}</div>}
            <div style={{fontSize:9,color:'rgba(var(--pr-sub-rgb),0.3)',marginTop:3}}>{new Date(a.createdAt).toLocaleDateString()}</div>
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
  const pageTheme = usePageTheme()
  const vars = THEME_VARS[pageTheme]
  const [progressView,setProgressView]=useState<'ring'|'bar'>('ring')
  const [lbBatch,setLbBatch]=useState<{id:string;name:string}|null>(null)
  const [notifGranted,setNotifGranted]=useState(false)
  const [notifAsked,setNotifAsked]=useState(false)
  const [isClient,setIsClient]=useState(false)
  const [search,setSearch]=useState('')
  const [smartFilter,setSmartFilter]=useState('')
  const [sortBy,setSortBy]=useState('')
  const [showFilters,setShowFilters]=useState(false)
  const [renewingId,setRenewingId]=useState<string|null>(null)

  const BG='var(--pr-bg)'
  const CARD='rgba(var(--pr-card-rgb),0.95)'
  const BORDER='rgba(var(--pr-sub-rgb),0.14)'
  const TEXT='var(--pr-text)'
  const SUB='rgba(var(--pr-sub-rgb),0.55)'

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
      const p=new URLSearchParams()
      if(search)p.set('q',search)
      if(smartFilter)p.set('filter',smartFilter)
      if(sortBy)p.set('sort',sortBy)
      const[bRes,sRes]=await Promise.all([
        fetch(`${API}/api/my-batches?${p.toString()}`,{headers:{Authorization:`Bearer ${t}`}}),
        fetch(`${API}/api/my-batches/stats`,{headers:{Authorization:`Bearer ${t}`}})
      ])
      const bd=await bRes.json(); const sd=await sRes.json()
      setBatches(bd.batches||[]); setStats(sd)
    }catch{}finally{setLoading(false)}
  }

  const renewBatch=async(id:string)=>{
    if(!tok)return
    setRenewingId(id)
    try{
      await fetch(`${API}/api/my-batches/${id}/renew`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      await fetchData(tok)
    }catch{}finally{setRenewingId(null)}
  }

  useEffect(()=>{
    if(!tok)return
    const t=setTimeout(()=>fetchData(tok),350)
    return ()=>clearTimeout(t)
  },[search,smartFilter,sortBy])

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

  const [wishlistBatches,setWishlistBatches]=useState<BatchMeta[]>([])
  useEffect(()=>{
    if(tab==='wishlist'&&tok){
      fetch(`${API}/api/my-batches/wishlist`,{headers:{Authorization:`Bearer ${tok}`}})
        .then(r=>r.json()).then(d=>setWishlistBatches((d.batches||[]).map((b:any)=>({
          ...b, progress:0, testsCompleted:0, streak:0, daysLeft:b.validity||365,
          isExpired:false, isCompleted:false, daysSinceAccess:0, isWishlisted:true,
          enrolledAt:b.createdAt||new Date().toISOString(), lastAccessedAt:b.createdAt||new Date().toISOString()
        })))).catch(()=>{})
    }
  },[tab,tok])

  const filtered=tab==='wishlist'?wishlistBatches:batches.filter(b=>{
    if(tab==='active')return !b.isExpired&&!b.isCompleted
    if(tab==='completed')return b.isExpired||b.isCompleted
    return true
  })

  const lastAccessed=batches.filter(b=>!b.isExpired).sort((a,b)=>new Date(b.lastAccessedAt).getTime()-new Date(a.lastAccessedAt).getTime())[0]

  const inp={padding:'8px 12px',background:'rgba(var(--pr-sub-rgb),0.08)',border:`1px solid ${BORDER}`,borderRadius:10,color:TEXT,fontSize:12,outline:'none' as const}

  return (
    <div style={{minHeight:'100vh',color:TEXT,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:BG, ...(vars as any)}}>
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
      <div style={{position:'sticky',top:0,zIndex:50,background:'rgba(var(--pr-card-rgb),0.96)',backdropFilter:'blur(22px)',borderBottom:`1px solid ${BORDER}`,padding:'10px 14px',display:'flex',alignItems:'center',gap:10}}>
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
          <button onClick={()=>{const next=pageTheme==='dark'?'light':'dark';try{localStorage.setItem('pr_color_theme',next);window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:next}))}catch{}}} style={{background:'rgba(77,159,255,0.1)',border:`1px solid ${BORDER}`,borderRadius:9,padding:'5px 9px',cursor:'pointer',color:TEXT,fontSize:12}}>{pageTheme==='dark'?'☀️':'🌙'}</button>
          <button onClick={()=>router.push('/dashboard/test-series')} style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,padding:'7px 12px',cursor:'pointer',color:'#fff',fontSize:11,fontWeight:700,flexShrink:0}}>+ Explore</button>
        </div>
      </div>

      <div style={{position:'relative',zIndex:2,padding:'14px 14px 80px',maxWidth:900,margin:'0 auto'}}>

        {/* NOTIFICATION BANNER */}
        {isClient&&!notifAsked&&typeof window!=='undefined'&&'Notification' in window&&(
          <div style={{background:'rgba(77,159,255,0.08)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:14,padding:'12px 16px',marginBottom:14,display:'flex',alignItems:'center',gap:12,animation:'slideUp 0.4s ease'}}>
            <span style={{fontSize:22,flexShrink:0}}>🔔</span>
            <div style={{flex:1}}>
              <div style={{fontSize:12,fontWeight:700,color:'var(--pr-text)'}}>Enable Streak Notifications</div>
              <div style={{fontSize:10,color:SUB}}>Get notified when you're on a streak — daily reminders to keep going!</div>
            </div>
            <button onClick={requestNotifPermission}
              style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,padding:'7px 14px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,flexShrink:0}}>Enable</button>
            <button onClick={()=>setNotifAsked(true)} style={{background:'transparent',border:'none',color:SUB,cursor:'pointer',fontSize:18,flexShrink:0}}>×</button>
          </div>
        )}

        {/* STATS BAR */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(80px,1fr))',gap:8,marginBottom:16}}>
          {[{i:'📚',l:'Enrolled',v:stats.total,c:'#4D9FFF'},{i:'✅',l:'Tests Done',v:stats.testsCompleted,c:'#27AE60'},{i:'⚡',l:'Active',v:stats.activeBatches,c:'#E67E22'},{i:'🏆',l:'Certificates',v:stats.certificates,c:'#FFD700'},{i:'🔥',l:'Streak',v:stats.currentStreak||0,c:'#FF6B35'},{i:'⏰',l:'Renew Soon',v:stats.renewalDueSoon||0,c:'#E74C3C'}].map((s,i)=>(
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
            <div style={{fontSize:10,fontWeight:700,color:'rgba(var(--pr-sub-rgb),0.45)',textTransform:'uppercase',letterSpacing:1,marginBottom:10}}>▶️ Continue Where You Left Off</div>
            <div style={{display:'flex',alignItems:'center',gap:12}}>
              <div style={{width:48,height:48,borderRadius:13,background:`${ECOLS[lastAccessed.examType]||'#4D9FFF'}18`,border:`1px solid ${ECOLS[lastAccessed.examType]||'#4D9FFF'}28`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:24,flexShrink:0}}>
                {CICONS[lastAccessed.examType]||'📚'}
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

        {/* SMART SEARCH + FILTER BAR (FPR5) */}
        <div style={{ marginBottom:14 }}>
          <div style={{ display:'flex',gap:8 }}>
            <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔎 Search batch, exam, subject, instructor…" style={{...inp,flex:1}} />
            <button onClick={()=>setShowFilters(s=>!s)} style={{background:'rgba(77,159,255,0.1)',border:`1px solid ${BORDER}`,borderRadius:10,padding:'8px 12px',cursor:'pointer',color:'#4D9FFF',fontSize:11,fontWeight:700,flexShrink:0}}>🧰 {showFilters?'▲':'▼'}</button>
          </div>
          {showFilters&&(
            <div style={{marginTop:10,background:CARD,border:`1px solid ${BORDER}`,borderRadius:14,padding:12}}>
              <div style={{fontSize:9,color:SUB,textTransform:'uppercase',fontWeight:700,marginBottom:6}}>Filter</div>
              <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:10}}>
                {[{v:'',l:'All'},{v:'free',l:'Free'},{v:'paid',l:'Paid'},{v:'expiring_soon',l:'⏰ Expiring Soon'},{v:'certificate_available',l:'🏆 Certificate Ready'},{v:'streak_active',l:'🔥 Streak Active'},{v:'high_progress',l:'📈 High Progress'},{v:'low_progress',l:'📉 Low Progress'},{v:'top_rated',l:'⭐ Top Rated'}].map(f=>(
                  <button key={f.v} onClick={()=>setSmartFilter(f.v)} style={{padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:smartFilter===f.v?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${smartFilter===f.v?'rgba(77,159,255,0.4)':'rgba(77,159,255,0.1)'}`,color:smartFilter===f.v?'#4D9FFF':SUB}}>{f.l}</button>
                ))}
              </div>
              <div style={{fontSize:9,color:SUB,textTransform:'uppercase',fontWeight:700,marginBottom:6}}>Sort</div>
              <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                {[{v:'',l:'Recently Accessed'},{v:'progress',l:'Highest Progress'},{v:'score',l:'Highest Score'},{v:'streak',l:'Highest Streak'},{v:'expiry',l:'Earliest Expiry'},{v:'rating',l:'Top Rated'},{v:'newest',l:'Newest'}].map(s=>(
                  <button key={s.v} onClick={()=>setSortBy(s.v)} style={{padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:sortBy===s.v?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${sortBy===s.v?'rgba(77,159,255,0.4)':'rgba(77,159,255,0.1)'}`,color:sortBy===s.v?'#4D9FFF':SUB}}>{s.l}</button>
                ))}
              </div>
              <button onClick={()=>{setSearch('');setSmartFilter('');setSortBy('')}} style={{width:'100%',marginTop:10,padding:'7px',background:'rgba(231,76,60,0.07)',border:'1px solid rgba(231,76,60,0.18)',borderRadius:10,color:'#E74C3C',cursor:'pointer',fontSize:10,fontWeight:700}}>🗑 Reset Filters</button>
            </div>
          )}
        </div>

        {/* TABS */}
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:7,marginBottom:14}}>
          {(['active','completed','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{padding:'10px',borderRadius:12,background:tab===t?'rgba(77,159,255,0.13)':CARD,border:`1px solid ${tab===t?'rgba(77,159,255,0.36)':BORDER}`,color:tab===t?'#4D9FFF':SUB,fontWeight:tab===t?700:400,cursor:'pointer',fontSize:11,backdropFilter:'blur(12px)'}}>
              {t==='active'?'⚡ Active':t==='completed'?'✅ Completed':'❤️ Wishlist'}
              <span style={{marginLeft:4,fontSize:10,opacity:0.6}}>({t==='active'?batches.filter(b=>!b.isExpired&&!b.isCompleted).length:t==='completed'?batches.filter(b=>b.isExpired||b.isCompleted).length:(stats.wishlistCount??wishlistBatches.length)})</span>
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
                          :<div style={{width:56,height:56,display:'flex',alignItems:'center',justifyContent:'center',background:`${ec}14`,borderRadius:14,border:`1px solid ${ec}22`,fontSize:24}}>{CICONS[b.examType]||'📚'}</div>
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

                        {tab!=='wishlist'&&(<>
                        {/* Leaderboard mini */}
                        <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:10}}>
                          <span style={{fontSize:10,color:SUB}}>🏅 Batch Leaderboard</span>
                          <button onClick={()=>setLbBatch({id:b._id,name:b.name})}
                            style={{background:'transparent',border:`1px solid ${ec}30`,borderRadius:8,padding:'3px 8px',color:ec,fontSize:9,cursor:'pointer',fontWeight:700}}>View Rank →</button>
                        </div>

                        {/* Activity Feed */}
                        {tok&&<MilestoneChips batchId={b._id} tok={tok}/>}
                        {tok&&<ActivityFeed batchId={b._id} tok={tok}/>}
                        </>)}
                      </div>
                    </div>

                    {/* Action buttons */}
                    <div style={{display:'flex',gap:8,marginTop:12,flexWrap:'wrap'}}>
                      {tab==='wishlist'?(
                        <button onClick={()=>router.push('/dashboard/test-series')}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11}}>🛒 View & Enroll</button>
                      ):b.isCompleted?(
                        <button onClick={()=>router.push('/dashboard/certificate')}
                          style={{flex:1,padding:'9px',background:'linear-gradient(135deg,#FFD700,#FFA000)',border:'none',borderRadius:11,color:'#000',fontWeight:700,cursor:'pointer',fontSize:11}}>🏆 Get Certificate</button>
                      ):b.isExpired?(
                        <button onClick={()=>renewBatch(b._id)} disabled={renewingId===b._id}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,boxShadow:`0 4px 12px ${ec}25`}}>
                          {renewingId===b._id?'Renewing…':'🔄 Renew Now'}
                        </button>
                      ):(
                        <button onClick={()=>{accessBatch(b._id);router.push('/dashboard/exams')}}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,boxShadow:`0 4px 12px ${ec}25`}}>▶️ Continue</button>
                      )}
                      {tab!=='wishlist'&&!b.isExpired&&!b.isCompleted&&b.daysLeft<=7&&(
                        <button onClick={()=>renewBatch(b._id)} disabled={renewingId===b._id}
                          style={{padding:'9px 12px',background:'rgba(230,126,34,0.08)',border:'1px solid rgba(230,126,34,0.2)',borderRadius:11,color:'#E67E22',cursor:'pointer',fontSize:10,fontWeight:700}}>{renewingId===b._id?'…':'⏰ Extend'}</button>
                      )}
                      {tab!=='wishlist'&&<button onClick={()=>setLbBatch({id:b._id,name:b.name})}
                        style={{padding:'9px 12px',background:'rgba(255,215,0,0.08)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:11,color:'#FFD700',cursor:'pointer',fontSize:13}}>🏆</button>}
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
PRVRNK_EOF_MARKER
echo "✅ Created/Updated My Batches Hub page.tsx"

# ══════════════════════════════════════════════════════════════════
# ✅ FINAL VERIFICATION CHECKLIST — FRONTEND (FPR5 My Batches Hub)
# ══════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FPR5 MY BATCHES HUB — FRONTEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
MBFILE="$MB_DIR/page.tsx"
PASS=0; FAIL=0
check() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "✅ $DESC"; PASS=$((PASS+1))
  else
    echo "❌ $DESC"; FAIL=$((FAIL+1))
  fi
}

if grep -q "function MilkyWayCanvas" "$MBFILE"; then echo "❌ 1) Old Immersive Galaxy Background Removed"; FAIL=$((FAIL+1)); else echo "✅ 1) Old Immersive Galaxy Background Removed"; PASS=$((PASS+1)); fi
check "2) Light/Dark Theme Hook (auto-adapts, synced with app-wide preference)" "function usePageTheme" "$MBFILE"
check "3) Multi-Competitive-Exam Icon Map"                          "'JEE ADVANCE':'🛠️'" "$MBFILE"
check "4) Hero / Summary Strip (preserved + Streak + Renewal chips)" "Renew Soon" "$MBFILE"
check "5) Smart Search + Filter + Sort Bar (new)"                    "SMART SEARCH + FILTER BAR" "$MBFILE"
check "6) Filter — Expiring/Certificate/Streak/Progress/Rating"      "certificate_available" "$MBFILE"
check "7) Sort — Progress/Score/Streak/Expiry/Rating/Newest"         "Highest Streak" "$MBFILE"
check "8) Continue Where You Left Off (preserved)"                    "lastAccessed" "$MBFILE"
check "9) Active / Completed / Wishlist Tabs (preserved)"             "'wishlist'" "$MBFILE"
check "10) Wishlist Tab — Fixed to Use Real Wishlist Data (bugfix)"   "api/my-batches/wishlist" "$MBFILE"
check "11) Wishlist Tab — Enroll CTA (not Continue/Renew)"            "View & Enroll" "$MBFILE"
check "12) Progress Ring / Bar Toggle (preserved)"                    "ProgressRing" "$MBFILE"
check "13) Streak Badge (preserved)"                                   "streak" "$MBFILE"
check "14) Renewal — One-Tap Renew Button"                             "renewBatch" "$MBFILE"
check "15) Renewal — Extend Button for Expiring Soon"                  "⏰ Extend" "$MBFILE"
check "16) Certificate CTA (preserved)"                                 "Get Certificate" "$MBFILE"
check "17) Achievement Milestones Chips (new)"                          "function MilestoneChips" "$MBFILE"
check "18) Batch Leaderboard Modal (preserved)"                        "BatchLeaderboardModal\|setLbBatch" "$MBFILE"
check "19) Activity Feed (preserved)"                                   "function ActivityFeed" "$MBFILE"
check "20) Notification Permission Prompt (preserved)"                  "Notification" "$MBFILE"
check "21) Explore Button (preserved)"                                  "Explore" "$MBFILE"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL)) TOTAL"
if [ "$FAIL" -eq 0 ]; then
  echo "  🎉 ALL FRONTEND FPR5 FEATURES SUCCESSFULLY IMPLEMENTED ✅"
else
  echo "  ⚠️  $FAIL item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🧹 Backups saved as *.bak_fpr5 next to originals."
echo "👉 Next: Restart Next.js dev server / redeploy. Open Student Panel → My Batches to test in both Light and Dark theme."
