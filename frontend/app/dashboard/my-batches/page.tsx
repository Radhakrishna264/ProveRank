'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'
import StudentShell from '@/src/components/StudentShell'

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
  _kind?: string;
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

// ── Batch Leaderboard Modal ──
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
      <div style={{fontSize:10,fontWeight:700,color:'rgba(var(--pr-sub-rgb),0.84)',textTransform:'uppercase',letterSpacing:1,marginBottom:8}}>📢 What's New</div>
      {activities.map(a=>(
        <div key={a._id} style={{display:'flex',gap:8,alignItems:'flex-start',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.06)'}}>
          <span style={{fontSize:16,flexShrink:0}}>{a.icon}</span>
          <div>
            <div style={{fontSize:11,fontWeight:700,color:'var(--pr-text)'}}>{a.title}</div>
            {a.message&&<div style={{fontSize:10,color:'rgba(var(--pr-sub-rgb),0.76)',marginTop:2}}>{a.message}</div>}
            <div style={{fontSize:9,color:'rgba(var(--pr-sub-rgb),0.68)',marginTop:3}}>{new Date(a.createdAt).toLocaleDateString()}</div>
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
  const [wsMsg,setWsMsg]=useState<string|null>(null)
  const pageTheme = usePageTheme()
  const vars = THEME_VARS[pageTheme]
  const [notifGranted,setNotifGranted]=useState(false)
  const [notifAsked,setNotifAsked]=useState(false)
  const [isClient,setIsClient]=useState(false)
  const [search,setSearch]=useState('')
  const [smartFilter,setSmartFilter]=useState('')
  const [sortBy,setSortBy]=useState('')
  const [showFilters,setShowFilters]=useState(false)
  const [renewingId,setRenewingId]=useState<string|null>(null)

  const CARD='rgba(var(--pr-card-rgb),0.95)'
  const BORDER='rgba(var(--pr-sub-rgb),0.14)'
  const TEXT='var(--pr-text)'
  const SUB='rgba(var(--pr-sub-rgb),0.76)'

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
      const r=await fetch(`${API}/api/my-batches/${id}/renew`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      const d=await r.json()
      if(!r.ok){alert(d.error||'Renewal failed');return}
      await fetchData(tok)
    }catch{alert('Renewal failed. Please try again.')}finally{setRenewingId(null)}
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

  const inp={padding:'10px 14px',background:'rgba(var(--pr-sub-rgb),0.06)',border:`1px solid ${BORDER}`,borderRadius:12,color:TEXT,fontSize:12,outline:'none' as const}

  return (
    <StudentShell pageKey="my-batches">
    <div style={{minHeight:'100vh',color:TEXT,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden', ...(vars as any)}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;800&family=Inter:wght@400;500;600;700;800&display=swap');
        *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
        @keyframes slideUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
      `}</style>

      <div style={{position:'relative',zIndex:2,padding:'20px 16px 80px',maxWidth:880,margin:'0 auto'}}>

        {/* ── PAGE HEADER ── */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-end',gap:16,marginBottom:28,animation:'fadeIn 0.5s ease'}}>
          <div>
            <div style={{fontSize:10,fontWeight:700,color:'#4D9FFF',textTransform:'uppercase',letterSpacing:2.5,marginBottom:6}}>Your Learning Journey</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(24px,6vw,32px)',fontWeight:800,color:TEXT,lineHeight:1.1}}>My Batches</div>
          </div>
          <button onClick={()=>router.push('/dashboard/test-series')} style={{background:'transparent',border:`1.5px solid rgba(77,159,255,0.35)`,borderRadius:12,padding:'9px 18px',cursor:'pointer',color:'#4D9FFF',fontSize:12,fontWeight:700,flexShrink:0,transition:'all 0.2s'}}>
            Explore →
          </button>
        </div>

        {/* NOTIFICATION BANNER */}
        {isClient&&!notifAsked&&typeof window!=='undefined'&&'Notification' in window&&(
          <div style={{background:'rgba(77,159,255,0.07)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:16,padding:'14px 16px',marginBottom:18,display:'flex',alignItems:'center',gap:12,animation:'slideUp 0.4s ease'}}>
            <span style={{fontSize:20,flexShrink:0}}>🔔</span>
            <div style={{flex:1}}>
              <div style={{fontSize:12,fontWeight:700,color:TEXT}}>Enable streak notifications</div>
              <div style={{fontSize:10.5,color:SUB,marginTop:1}}>Get a gentle nudge when your streak needs you.</div>
            </div>
            <button onClick={requestNotifPermission}
              style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,padding:'7px 16px',color:'#031018',fontWeight:800,cursor:'pointer',fontSize:11,flexShrink:0}}>Enable</button>
            <button onClick={()=>setNotifAsked(true)} style={{background:'transparent',border:'none',color:SUB,cursor:'pointer',fontSize:18,flexShrink:0}}>×</button>
          </div>
        )}

        {/* ── STATS STRIP ── */}
        <div style={{
          display:'flex',background:CARD,border:`1px solid ${BORDER}`,borderRadius:18,
          marginBottom:22,backdropFilter:'blur(16px)',animation:'slideUp 0.3s ease',overflow:'hidden'
        }}>
          {[
            {l:'Enrolled',v:stats.total,c:'#4D9FFF'},
            {l:'Tests Done',v:stats.testsCompleted,c:'#27AE60'},
            {l:'Certificates',v:stats.certificates,c:'#FFD700'},
            {l:'Streak',v:stats.currentStreak||0,c:'#FF6B35'},
          ].map((s,i)=>(
            <div key={i} style={{flex:1,textAlign:'center',padding:'16px 6px',borderRight:i<3?`1px solid ${BORDER}`:'none'}}>
              <div style={{fontSize:22,fontWeight:800,color:s.c,fontFamily:'Playfair Display,serif'}}>{s.v}</div>
              <div style={{fontSize:9,color:SUB,textTransform:'uppercase',letterSpacing:0.6,marginTop:3}}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* ── SEARCH + FILTER ── */}
        <div style={{marginBottom:18}}>
          <div style={{display:'flex',gap:8}}>
            <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search batch, exam, subject…" style={{...inp,flex:1}} />
            <button onClick={()=>setShowFilters(s=>!s)} style={{background:showFilters?'rgba(77,159,255,0.14)':'rgba(var(--pr-sub-rgb),0.06)',border:`1px solid ${showFilters?'rgba(77,159,255,0.35)':BORDER}`,borderRadius:12,padding:'0 16px',cursor:'pointer',color:showFilters?'#4D9FFF':SUB,fontSize:11,fontWeight:700,flexShrink:0}}>Filter {showFilters?'▲':'▼'}</button>
          </div>
          {showFilters&&(
            <div style={{marginTop:10,background:CARD,border:`1px solid ${BORDER}`,borderRadius:16,padding:16,animation:'slideUp 0.25s ease'}}>
              <div style={{fontSize:9,color:SUB,textTransform:'uppercase',fontWeight:700,letterSpacing:1,marginBottom:8}}>Filter</div>
              <div style={{display:'flex',gap:6,flexWrap:'wrap',marginBottom:14}}>
                {[{v:'',l:'All'},{v:'free',l:'Free'},{v:'paid',l:'Paid'},{v:'expiring_soon',l:'Expiring Soon'},{v:'certificate_available',l:'Certificate Ready'},{v:'streak_active',l:'Streak Active'},{v:'high_progress',l:'High Progress'},{v:'low_progress',l:'Low Progress'},{v:'top_rated',l:'Top Rated'}].map(f=>(
                  <button key={f.v} onClick={()=>setSmartFilter(f.v)} style={{padding:'6px 12px',borderRadius:20,fontSize:10.5,cursor:'pointer',background:smartFilter===f.v?'rgba(77,159,255,0.16)':'transparent',border:`1px solid ${smartFilter===f.v?'rgba(77,159,255,0.4)':BORDER}`,color:smartFilter===f.v?'#4D9FFF':SUB}}>{f.l}</button>
                ))}
              </div>
              <div style={{fontSize:9,color:SUB,textTransform:'uppercase',fontWeight:700,letterSpacing:1,marginBottom:8}}>Sort</div>
              <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                {[{v:'',l:'Recently Accessed'},{v:'progress',l:'Highest Progress'},{v:'score',l:'Highest Score'},{v:'streak',l:'Highest Streak'},{v:'expiry',l:'Earliest Expiry'},{v:'rating',l:'Top Rated'},{v:'newest',l:'Newest'}].map(s=>(
                  <button key={s.v} onClick={()=>setSortBy(s.v)} style={{padding:'6px 12px',borderRadius:20,fontSize:10.5,cursor:'pointer',background:sortBy===s.v?'rgba(77,159,255,0.16)':'transparent',border:`1px solid ${sortBy===s.v?'rgba(77,159,255,0.4)':BORDER}`,color:sortBy===s.v?'#4D9FFF':SUB}}>{s.l}</button>
                ))}
              </div>
              <button onClick={()=>{setSearch('');setSmartFilter('');setSortBy('')}} style={{width:'100%',marginTop:14,padding:'9px',background:'transparent',border:`1px solid rgba(231,76,60,0.25)`,borderRadius:11,color:'#E74C3C',cursor:'pointer',fontSize:10.5,fontWeight:700}}>Reset Filters</button>
            </div>
          )}
        </div>

        {/* ── TABS ── */}
        <div style={{display:'flex',gap:4,marginBottom:20,background:CARD,border:`1px solid ${BORDER}`,borderRadius:14,padding:4}}>
          {(['active','completed','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{
              flex:1,padding:'9px 4px',borderRadius:10,
              background:tab===t?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'transparent',
              border:'none',color:tab===t?'#031018':SUB,fontWeight:tab===t?800:600,cursor:'pointer',fontSize:11.5,
              transition:'all 0.25s'
            }}>
              {t==='active'?'Active':t==='completed'?'Completed':'Wishlist'}
              <span style={{marginLeft:5,fontSize:9.5,opacity:0.75}}>({t==='active'?batches.filter(b=>!b.isExpired&&!b.isCompleted).length:t==='completed'?batches.filter(b=>b.isExpired||b.isCompleted).length:(stats.wishlistCount??wishlistBatches.length)})</span>
            </button>
          ))}
        </div>

        {/* ── BATCH CARDS ── */}
        {loading?(
          <div style={{display:'flex',flexDirection:'column',gap:14}}>
            {[1,2,3].map(i=><div key={i} style={{height:170,background:CARD,borderRadius:20,animation:'shimmer 1.5s ease infinite',animationDelay:`${i*0.15}s`}}/>)}
          </div>
        ):filtered.length===0?(
          <div style={{textAlign:'center',padding:'56px 16px',background:CARD,border:`1px solid ${BORDER}`,borderRadius:20}}>
            <div style={{fontSize:48,marginBottom:14,opacity:0.7}}>{tab==='wishlist'?'♡':tab==='completed'?'◈':'○'}</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:700,color:TEXT,marginBottom:8}}>{tab==='wishlist'?'No saved batches yet':tab==='completed'?'No completed batches yet':'No active batches yet'}</div>
            <div style={{fontSize:12,color:SUB,marginBottom:24}}>{tab==='wishlist'?'Save batches you like from Test Series':'Enroll in a batch to start your journey'}</div>
            <button onClick={()=>router.push('/dashboard/test-series')} style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'12px 28px',color:'#031018',fontWeight:800,cursor:'pointer',fontSize:13}}>Explore Batches →</button>
          </div>
        ):(
          <div style={{display:'flex',flexDirection:'column',gap:14}}>
            {filtered.map((b,i)=>{
              const ec=ECOLS[b.examType]||'#4D9FFF'
              const statusColor = b.isExpired?'#E74C3C':b.isCompleted?'#FFD700':null
              return (
                <div key={b._id} style={{
                  background:CARD,border:`1px solid ${statusColor?statusColor+'30':ec+'20'}`,borderRadius:22,
                  padding:'20px',backdropFilter:'blur(18px)',animation:`slideUp ${0.3+i*0.05}s ease`,
                  position:'relative',overflow:'hidden',transition:'border-color 0.2s'
                }}>

                  {b.isExpired&&<div style={{position:'absolute',top:0,left:0,right:0,background:'rgba(231,76,60,0.15)',padding:'6px 14px',fontSize:10,fontWeight:700,color:'#E74C3C',textAlign:'center',letterSpacing:0.3}}>Batch expired — renew to continue</div>}
                  {!b.isExpired&&b.daysLeft<=7&&<div style={{position:'absolute',top:0,left:0,right:0,background:'rgba(230,126,34,0.15)',padding:'6px 14px',fontSize:10,fontWeight:700,color:'#E67E22',textAlign:'center',letterSpacing:0.3}}>Expiring in {b.daysLeft} days</div>}
                  {b.isCompleted&&<div style={{position:'absolute',top:0,left:0,right:0,background:'rgba(255,215,0,0.12)',padding:'6px 14px',fontSize:10,fontWeight:700,color:'#FFD700',textAlign:'center',letterSpacing:0.3}}>Batch completed</div>}

                  <div style={{marginTop:(b.isExpired||b.daysLeft<=7||b.isCompleted)?20:0}}>
                    <div style={{display:'flex',gap:16,alignItems:'flex-start'}}>
                      <div style={{flexShrink:0}}><ProgressRing pct={b.progress} ec={ec}/></div>

                      <div style={{flex:1,minWidth:0}}>
                        <div style={{display:'flex',alignItems:'center',gap:6,marginBottom:6,flexWrap:'wrap'}}>
                          <span style={{fontSize:9.5,background:`${ec}14`,color:ec,padding:'3px 9px',borderRadius:20,fontWeight:700,letterSpacing:0.3}}>{b.examType}</span>
                          {b.streak>0&&<span style={{fontSize:9.5,color:'#FF6B35',fontWeight:700}}>🔥 {b.streak}d</span>}
                        </div>
                        <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:TEXT,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis',marginBottom:6}}>{b.name}</div>
                        <div style={{fontSize:11,color:SUB}}>{b.testsCompleted}/{b.totalTests} tests · {b.daysLeft}d left · {b.daysSinceAccess===0?'Active today':b.daysSinceAccess+'d ago'}</div>

                        {tab!=='wishlist'&&<>
                          {tok&&<ActivityFeed batchId={b._id} tok={tok}/>}
                        </>}
                      </div>
                    </div>

                    <div style={{display:'flex',gap:8,marginTop:16}}>
                      {tab==='wishlist'?(
                        <button onClick={()=>router.push('/dashboard/test-series')}
                          style={{flex:1,padding:'11px',background:`linear-gradient(135deg,${ec},${ec}CC)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12}}>View & Enroll</button>
                      ):b.isCompleted?(
                        <button disabled
                          style={{flex:1,padding:'11px',background:'linear-gradient(135deg,#FFD700,#FFA000)',border:'none',borderRadius:12,color:'#031018',fontWeight:700,cursor:'default',fontSize:12,opacity:0.9}}>Completed</button>
                      ):b.isExpired?(
                        <button onClick={()=>renewBatch(b._id)} disabled={renewingId===b._id}
                          style={{flex:1,padding:'11px',background:`linear-gradient(135deg,${ec},${ec}CC)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12}}>
                          {renewingId===b._id?'Renewing…':'Renew Now'}
                        </button>
                      ):(
                        <button onClick={()=>{accessBatch(b._id);router.push(`/dashboard/my-batches/${b._id}`)}}
                          style={{flex:1,padding:'11px',background:`linear-gradient(135deg,${ec},${ec}CC)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12}}>Continue</button>
                      )}
                      {tab!=='wishlist'&&!b.isExpired&&!b.isCompleted&&b.daysLeft<=7&&(
                        <button onClick={()=>renewBatch(b._id)} disabled={renewingId===b._id}
                          style={{padding:'11px 14px',background:'transparent',border:'1px solid rgba(230,126,34,0.3)',borderRadius:12,color:'#E67E22',cursor:'pointer',fontSize:11,fontWeight:700}}>{renewingId===b._id?'…':'Extend'}</button>
                      )}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {/* ── STUDY TIPS ── */}
        <div style={{marginTop:44,padding:'0 4px'}}>
          <div style={{fontSize:9.5,fontWeight:700,color:SUB,textTransform:'uppercase',letterSpacing:2,marginBottom:16}}>Study Tips</div>
          {TIPS.map((tip,i)=>(
            <div key={i} style={{display:'flex',gap:14,alignItems:'flex-start',marginBottom:18,animation:`slideUp ${1+i*0.1}s ease`}}>
              <span style={{fontSize:22,flexShrink:0}}>{tip.i}</span>
              <div>
                <div style={{fontWeight:700,color:'#4D9FFF',fontSize:12.5,marginBottom:3,fontFamily:'Playfair Display,serif'}}>{tip.t}</div>
                <div style={{fontSize:11.5,color:SUB,lineHeight:1.7}}>{tip.d}</div>
              </div>
            </div>
          ))}
        </div>

      </div>
    </div>
    {wsMsg&&<div style={{position:'fixed',bottom:24,left:'50%',transform:'translateX(-50%)',zIndex:2000,background:'rgba(20,20,35,0.96)',border:'1px solid rgba(77,159,255,0.35)',borderRadius:12,padding:'10px 18px',fontSize:12,color:'#fff',fontWeight:600,boxShadow:'0 10px 30px rgba(0,0,0,0.4)',whiteSpace:'nowrap'}}>{wsMsg}</div>}
    </StudentShell>
  )
}
