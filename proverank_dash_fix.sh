#!/bin/bash
# ProveRank — Dashboard Premium Redesign + Sidebar Toggle
set -e
G='\033[0;32m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'
log()  { echo -e "${G}[✓]${N} $1"; }
step() { echo -e "\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n${C}  $1${N}\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }

FE=~/workspace/frontend

# =============================================================================
# DASHBOARD — Ultra Premium SaaS + Sidebar hidden by default (logo click toggle)
# =============================================================================
step "Dashboard — Ultra Premium SaaS Redesign"
cat > $FE/app/dashboard/page.tsx << 'DASHEOF'
'use client'
import { useState, useEffect, useRef } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/useAuth'

const API = process.env.NEXT_PUBLIC_API_URL || ''

export default function Dashboard() {
  const { user, logout } = useAuth('student')
  const router = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [sideOpen, setSideOpen] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [time, setTime] = useState(new Date())
  const [stats, setStats] = useState({ rank: 0, score: 0, streak: 0, percentile: 0 })
  const [exams, setExams] = useState<any[]>([])
  const [results, setResults] = useState<any[]>([])
  const sideRef = useRef<HTMLDivElement>(null)

  const T = {
    en: {
      welcome: 'Welcome back,', dash: 'Dashboard', profile: 'Profile',
      exams: 'My Exams', results: 'Results', analytics: 'Analytics',
      leaderboard: 'Leaderboard', cert: 'Certificate', admit: 'Admit Card',
      support: 'Support', logout: 'Sign Out',
      rank: 'All India Rank', score: 'Best Score', streak: 'Day Streak', pct: 'Percentile',
      upcoming: 'Upcoming Exams', recent: 'Recent Results',
      noExam: 'No upcoming exams scheduled.', noResult: 'No results yet. Give your first exam!',
      start: 'Start →', view: 'View →', viewAll: 'View All →',
      quick: 'Quick Access', activity: 'Recent Activity',
      tip: '💡 Pro Tip', tipText: 'Revise your weak chapters before the next test for best results.',
      targetDays: 'Days to Target', nextExam: 'Next Exam',
      studyGoal: 'Weekly Study Goal', accuracy: 'Accuracy',
      today: 'Today', good: 'Great job!', keepGoing: 'Keep pushing forward!',
      portal: 'STUDENT PORTAL', nav: 'NAVIGATION', account: 'ACCOUNT',
    },
    hi: {
      welcome: 'वापस स्वागत है,', dash: 'डैशबोर्ड', profile: 'प्रोफाइल',
      exams: 'मेरी परीक्षाएं', results: 'परिणाम', analytics: 'विश्लेषण',
      leaderboard: 'लीडरबोर्ड', cert: 'प्रमाण पत्र', admit: 'प्रवेश पत्र',
      support: 'सहायता', logout: 'साइन आउट',
      rank: 'अखिल भारत रैंक', score: 'सर्वश्रेष्ठ स्कोर', streak: 'दिन की लकीर', pct: 'प्रतिशतक',
      upcoming: 'आगामी परीक्षाएं', recent: 'हाल के परिणाम',
      noExam: 'कोई आगामी परीक्षा नहीं।', noResult: 'कोई परिणाम नहीं। पहली परीक्षा दें!',
      start: 'शुरू →', view: 'देखें →', viewAll: 'सभी →',
      quick: 'त्वरित पहुंच', activity: 'हाल की गतिविधि',
      tip: '💡 प्रो टिप', tipText: 'अगली परीक्षा से पहले कमजोर अध्यायों को दोहराएं।',
      targetDays: 'लक्ष्य तक दिन', nextExam: 'अगली परीक्षा',
      studyGoal: 'साप्ताहिक लक्ष्य', accuracy: 'सटीकता',
      today: 'आज', good: 'शाबाश!', keepGoing: 'आगे बढ़ते रहें!',
      portal: 'छात्र पोर्टल', nav: 'नेविगेशन', account: 'खाता',
    }
  }
  const t = T[lang]

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if (sl) setLang(sl)
    const st = localStorage.getItem('pr_theme'); if (st === 'light') setDark(false)
    const iv = setInterval(() => setTime(new Date()), 1000)

    // Close sidebar on outside click
    const onClickOutside = (e: MouseEvent) => {
      if (sideRef.current && !sideRef.current.contains(e.target as Node)) {
        setSideOpen(false)
      }
    }
    document.addEventListener('mousedown', onClickOutside)
    return () => { clearInterval(iv); document.removeEventListener('mousedown', onClickOutside) }
  }, [])

  useEffect(() => {
    if (user) fetchData()
  }, [user])

  const fetchData = async () => {
    try {
      const h = { Authorization: `Bearer ${user!.token}` }
      const me = await fetch(`${API}/api/auth/me`, { headers: h }).then(r => r.json()).catch(() => ({}))
      if (me?.name) setStats({ rank: me.rank||0, score: me.bestScore||0, streak: me.streak||0, percentile: me.percentile||0 })
      const ex = await fetch(`${API}/api/exams`, { headers: h }).then(r => r.json()).catch(() => [])
      if (Array.isArray(ex)) setExams(ex.slice(0, 3))
      const rs = await fetch(`${API}/api/results/my`, { headers: h }).then(r => r.json()).catch(() => [])
      if (Array.isArray(rs)) setResults(rs.slice(0, 3))
    } catch {}
  }

  const toggleLang = () => { const n = lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang', n) }
  const toggleDark = () => { const n = !dark; setDark(n); localStorage.setItem('pr_theme', n?'dark':'light') }

  if (!mounted) return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',flexDirection:'column',gap:14}}>
      <div style={{width:40,height:40,border:'3px solid rgba(77,159,255,0.15)',borderTopColor:'#4D9FFF',borderRadius:'50%',animation:'spin 1s linear infinite'}}/>
      <style>{`@keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}`}</style>
    </div>
  )

  /* ─── Theme vars ─────────────────────────────────────────── */
  const bg      = dark ? '#000A18' : '#F0F7FF'
  const sideBg  = dark ? 'rgba(0,6,18,0.98)' : 'rgba(248,252,255,0.98)'
  const card    = dark ? 'rgba(0,16,32,0.85)' : 'rgba(255,255,255,0.92)'
  const card2   = dark ? 'rgba(0,22,44,0.7)'  : 'rgba(240,247,255,0.8)'
  const bord    = dark ? 'rgba(77,159,255,0.13)' : 'rgba(77,159,255,0.22)'
  const bord2   = dark ? 'rgba(77,159,255,0.22)' : 'rgba(77,159,255,0.35)'
  const tm      = dark ? '#E8F4FF' : '#0F172A'
  const ts      = dark ? '#5A7A9A' : '#64748B'
  const topBg   = dark ? 'rgba(0,4,14,0.94)' : 'rgba(248,252,255,0.94)'
  const mutedL  = dark ? '#1E3A5A' : '#CBD5E1'

  const navLinks = [
    { href:'/dashboard',             icon:'⊞', label:t.dash },
    { href:'/dashboard/exams',       icon:'📝', label:t.exams },
    { href:'/dashboard/results',     icon:'📊', label:t.results },
    { href:'/dashboard/analytics',   icon:'📈', label:t.analytics },
    { href:'/dashboard/leaderboard', icon:'🏆', label:t.leaderboard },
    { href:'/dashboard/certificate', icon:'🎓', label:t.cert },
    { href:'/dashboard/admit-card',  icon:'🎫', label:t.admit },
    { href:'/dashboard/profile',     icon:'👤', label:t.profile },
    { href:'/support',               icon:'💬', label:t.support },
  ]

  const greetHour = time.getHours()
  const greeting = greetHour < 12
    ? (lang==='en'?'Good Morning ☀️':'शुभ प्रभात ☀️')
    : greetHour < 17
    ? (lang==='en'?'Good Afternoon 🌤️':'शुभ दोपहर 🌤️')
    : (lang==='en'?'Good Evening 🌙':'शुभ संध्या 🌙')

  const timeStr = time.toLocaleTimeString(lang==='en'?'en-IN':'hi-IN', { hour:'2-digit', minute:'2-digit' })
  const dateStr = time.toLocaleDateString(lang==='en'?'en-IN':'hi-IN', { weekday:'long', day:'numeric', month:'long' })

  return (
    <div style={{ minHeight:'100vh', background:bg, fontFamily:'Inter,sans-serif', color:tm }}>
      <style>{`
        @keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}
        @keyframes slideLeft{from{transform:translateX(-100%);opacity:0}to{transform:translateX(0);opacity:1}}
        @keyframes pulse2{0%,100%{box-shadow:0 0 0 0 rgba(77,159,255,0.4)}50%{box-shadow:0 0 0 8px rgba(77,159,255,0)}}
        @keyframes gradMove{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%{transform:translateX(-100%)}100%{transform:translateX(200%)}}
        .dash-card{transition:all 0.3s;cursor:default;}
        .dash-card:hover{transform:translateY(-4px);}
        .side-link{display:flex;align-items:center;gap:11px;padding:11px 14px;border-radius:12px;text-decoration:none;font-weight:500;font-size:13.5px;transition:all 0.2s;margin-bottom:2px;color:${ts};}
        .side-link:hover{background:rgba(77,159,255,0.1);color:${tm};}
        .side-link.active{background:rgba(77,159,255,0.15);color:#4D9FFF;font-weight:700;border-left:3px solid #4D9FFF;padding-left:11px;}
        .tbtn{padding:7px 15px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.3);background:rgba(77,159,255,0.06);color:${ts};font-size:12px;font-weight:600;cursor:pointer;transition:all 0.2s;font-family:Inter,sans-serif;}
        .tbtn:hover{border-color:#4D9FFF;color:#4D9FFF;background:rgba(77,159,255,0.1);}
        .stat-glow{position:relative;overflow:hidden;}
        .stat-glow::after{content:'';position:absolute;top:0;left:-100%;width:50%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,0.04),transparent);animation:shimmer 3s infinite;}
        .quick-btn{display:flex;flex-direction:column;align-items:center;gap:8px;padding:18px 12px;border-radius:14px;text-decoration:none;transition:all 0.25s;border:1px solid ${bord};color:${ts};font-size:12px;font-weight:600;}
        .quick-btn:hover{border-color:rgba(77,159,255,0.4);color:#4D9FFF;transform:translateY(-4px);background:rgba(77,159,255,0.06);}
        .exam-row:hover{background:rgba(77,159,255,0.04)!important;}
        .overlay-bg{position:fixed;inset:0;background:rgba(0,0,0,0.55);z-index:98;backdrop-filter:blur(3px);}
      `}</style>

      {/* ── SIDEBAR (hidden by default, slides in on logo click) ── */}
      {sideOpen && <div className="overlay-bg" onClick={() => setSideOpen(false)}/>}
      <aside ref={sideRef} style={{
        position:'fixed', top:0, left:0, height:'100vh', width:260,
        background:sideBg, borderRight:`1px solid ${bord2}`,
        zIndex:99, display:'flex', flexDirection:'column', padding:'20px 12px',
        overflowY:'auto',
        transform: sideOpen ? 'translateX(0)' : 'translateX(-100%)',
        transition: 'transform 0.3s cubic-bezier(0.4,0,0.2,1)',
        boxShadow: sideOpen ? '8px 0 40px rgba(0,0,0,0.5)' : 'none',
      }}>
        {/* Close button */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:24,padding:'0 4px'}}>
          <div style={{display:'flex',alignItems:'center',gap:10}}>
            <svg width={30} height={30} viewBox="0 0 64 64">
              <defs><filter id="sg2"><feGaussianBlur stdDeviation="2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
              <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2" filter="url(#sg2)"/>
              <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="13" fontWeight="700" fill="#4D9FFF">PR</text>
            </svg>
            <span style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
          </div>
          <button onClick={()=>setSideOpen(false)} style={{background:'none',border:'none',color:ts,fontSize:20,cursor:'pointer',lineHeight:1,padding:4}}>✕</button>
        </div>

        {/* Student badge */}
        <div style={{background:`rgba(77,159,255,0.07)`,border:`1px solid ${bord}`,borderRadius:12,padding:'10px 14px',marginBottom:20,display:'flex',alignItems:'center',gap:10}}>
          <div style={{width:34,height:34,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,fontSize:14,color:'#fff',flexShrink:0}}>S</div>
          <div>
            <div style={{fontWeight:700,fontSize:13,color:tm}}>Student</div>
            <div style={{fontSize:10,color:'#00C48C',fontWeight:600}}>● {lang==='en'?'Online':'ऑनलाइन'}</div>
          </div>
        </div>

        {/* Nav links */}
        <div style={{fontSize:9,fontWeight:700,color:mutedL,letterSpacing:'0.12em',textTransform:'uppercase',padding:'0 6px',marginBottom:8}}>{t.nav}</div>
        <div style={{flex:1}}>
          {navLinks.map(n => (
            <Link key={n.href} href={n.href} className={`side-link ${n.href==='/dashboard'?'active':''}`} onClick={()=>setSideOpen(false)}>
              <span style={{fontSize:15,width:20,textAlign:'center',flexShrink:0}}>{n.icon}</span>
              <span>{n.label}</span>
            </Link>
          ))}
        </div>

        {/* Bottom */}
        <div style={{borderTop:`1px solid ${bord}`,paddingTop:14,marginTop:14}}>
          <div style={{fontSize:9,fontWeight:700,color:mutedL,letterSpacing:'0.12em',textTransform:'uppercase',padding:'0 6px',marginBottom:8}}>{t.account}</div>
          <div style={{display:'flex',gap:6,marginBottom:8}}>
            <button className="tbtn" onClick={toggleLang} style={{flex:1,justifyContent:'center',display:'flex'}}>{lang==='en'?'🇮🇳 हिं':'🌐 EN'}</button>
            <button className="tbtn" onClick={toggleDark} style={{flex:1,justifyContent:'center',display:'flex'}}>{dark?'☀️':'🌙'}</button>
          </div>
          <button onClick={logout} style={{width:'100%',display:'flex',alignItems:'center',gap:10,padding:'11px 14px',borderRadius:12,border:'1px solid rgba(255,71,87,0.22)',background:'rgba(255,71,87,0.05)',color:'#FF6B7A',cursor:'pointer',fontWeight:600,fontSize:13,fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}
            onMouseEnter={e=>{e.currentTarget.style.background='rgba(255,71,87,0.12)';e.currentTarget.style.borderColor='rgba(255,71,87,0.4)'}}
            onMouseLeave={e=>{e.currentTarget.style.background='rgba(255,71,87,0.05)';e.currentTarget.style.borderColor='rgba(255,71,87,0.22)'}}>
            <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="#FF6B7A" strokeWidth="2.5" strokeLinecap="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></svg>
            {t.logout}
          </button>
        </div>
      </aside>

      {/* ── TOPBAR ─────────────────────────────────────────────── */}
      <header style={{position:'sticky',top:0,zIndex:50,background:topBg,backdropFilter:'blur(20px)',borderBottom:`1px solid ${bord}`,padding:'0 20px',height:60,display:'flex',alignItems:'center',justifyContent:'space-between',gap:12}}>
        {/* Logo — click to open sidebar */}
        <button onClick={()=>setSideOpen(s=>!s)} style={{display:'flex',alignItems:'center',gap:10,background:'none',border:'none',cursor:'pointer',padding:'6px 10px',borderRadius:12,transition:'background 0.2s'}}
          onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.08)')}
          onMouseLeave={e=>(e.currentTarget.style.background='none')}>
          <svg width={28} height={28} viewBox="0 0 64 64">
            <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/>
            <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="13" fontWeight="700" fill="#4D9FFF">PR</text>
          </svg>
          <span style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
          <span style={{fontSize:11,color:ts,opacity:.6,marginLeft:2}}>☰</span>
        </button>

        {/* Center — date & time */}
        <div style={{textAlign:'center',display:'flex',flexDirection:'column',gap:1}}>
          <div style={{fontSize:14,fontWeight:700,color:'#4D9FFF',fontFamily:'Playfair Display,serif'}}>{timeStr}</div>
          <div style={{fontSize:10,color:ts}}>{dateStr}</div>
        </div>

        {/* Right */}
        <div style={{display:'flex',alignItems:'center',gap:8}}>
          <button className="tbtn" onClick={toggleLang}>{lang==='en'?'🇮🇳':'🌐'}</button>
          <button className="tbtn" onClick={toggleDark}>{dark?'☀️':'🌙'}</button>
          <div style={{position:'relative',cursor:'pointer'}} onClick={()=>router.push('/support')}>
            <div style={{width:36,height:36,borderRadius:'50%',background:card2,border:`1px solid ${bord}`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16}}>🔔</div>
            <div style={{position:'absolute',top:-2,right:-2,width:14,height:14,borderRadius:'50%',background:'#FF4757',border:`2px solid ${dark?'#000A18':'#F0F7FF'}`,fontSize:8,color:'#fff',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800}}>3</div>
          </div>
          <div style={{width:36,height:36,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,fontSize:14,color:'#fff',cursor:'pointer',boxShadow:'0 2px 10px rgba(77,159,255,0.4)'}}
            onClick={()=>router.push('/dashboard/profile')}>S</div>
        </div>
      </header>

      {/* ── MAIN CONTENT ────────────────────────────────────────── */}
      <main style={{padding:'28px 20px',maxWidth:1200,margin:'0 auto',animation:'fadeUp 0.5s ease forwards'}}>

        {/* ── ROW 1: Greeting + Overview ── */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:16,marginBottom:28}}>
          <div>
            <div style={{fontSize:12,color:ts,fontWeight:600,letterSpacing:'0.06em',textTransform:'uppercase',marginBottom:4}}>{greeting}</div>
            <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.4rem,3vw,2rem)',fontWeight:800,color:tm,lineHeight:1.2,marginBottom:4}}>
              {t.welcome} <span style={{color:'#4D9FFF'}}>Student 👋</span>
            </h1>
            <p style={{color:ts,fontSize:13}}>{lang==='en'?'Your NEET preparation dashboard — Stay focused, stay ranked.':'आपका NEET तैयारी डैशबोर्ड — केंद्रित रहें, रैंक में रहें।'}</p>
          </div>
          {/* Tip card */}
          <div style={{background:'linear-gradient(135deg,rgba(168,85,247,0.12),rgba(77,159,255,0.08))',border:'1px solid rgba(168,85,247,0.2)',borderRadius:14,padding:'14px 18px',maxWidth:280,flexShrink:0}}>
            <div style={{fontWeight:700,fontSize:12,color:'#A855F7',marginBottom:4}}>{t.tip}</div>
            <div style={{color:ts,fontSize:12,lineHeight:1.6}}>{t.tipText}</div>
          </div>
        </div>

        {/* ── ROW 2: 4 Big Stat Cards ── */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(200px,1fr))',gap:16,marginBottom:20}}>
          {[
            { label:t.rank,   value:stats.rank?`#${stats.rank}`:'#—',     icon:'🏆', color:'#4D9FFF',  bg:'rgba(77,159,255,0.08)',   grad:'135deg,#4D9FFF22,#4D9FFF08', sub:lang==='en'?'All India Rank':'अखिल भारत रैंक' },
            { label:t.score,  value:stats.score?`${stats.score}/720`:'—/720',icon:'📊', color:'#00C48C',  bg:'rgba(0,196,140,0.08)',    grad:'135deg,#00C48C22,#00C48C08', sub:lang==='en'?'Best performance':'सर्वश्रेष्ठ प्रदर्शन' },
            { label:t.streak, value:`${stats.streak||0}`,                   icon:'🔥', color:'#FFA502',  bg:'rgba(255,165,2,0.08)',    grad:'135deg,#FFA50222,#FFA50208', sub:lang==='en'?'Days active':'दिन सक्रिय' },
            { label:t.pct,    value:stats.percentile?`${stats.percentile}%`:'—%', icon:'📈', color:'#A855F7', bg:'rgba(168,85,247,0.08)', grad:'135deg,#A855F722,#A855F708', sub:lang==='en'?'Top percentile':'शीर्ष प्रतिशतक' },
          ].map((s,i)=>(
            <div key={i} className="dash-card stat-glow" style={{background:`linear-gradient(${s.grad})`,border:`1px solid ${s.color}22`,borderRadius:18,padding:'22px 20px',position:'relative',overflow:'hidden'}}>
              {/* BG icon */}
              <div style={{position:'absolute',top:-10,right:-10,fontSize:60,opacity:.06,pointerEvents:'none'}}>{s.icon}</div>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14}}>
                <div style={{width:42,height:42,borderRadius:12,background:`${s.color}18`,border:`1px solid ${s.color}33`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20}}>
                  {s.icon}
                </div>
                <div style={{background:`${s.color}15`,color:s.color,fontSize:9,fontWeight:700,padding:'3px 8px',borderRadius:99,letterSpacing:'0.06em',textTransform:'uppercase'}}>
                  {lang==='en'?'Live':'लाइव'}
                </div>
              </div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.6rem,3vw,2.2rem)',fontWeight:800,color:s.color,lineHeight:1,marginBottom:4}}>{s.value}</div>
              <div style={{fontWeight:600,fontSize:12,color:tm,marginBottom:2}}>{s.label}</div>
              <div style={{fontSize:11,color:ts}}>{s.sub}</div>
              {/* Bottom bar */}
              <div style={{position:'absolute',bottom:0,left:0,right:0,height:3,background:`linear-gradient(90deg,${s.color}33,${s.color}88,${s.color}33)`,borderRadius:'0 0 18px 18px'}}/>
            </div>
          ))}
        </div>

        {/* ── ROW 3: Mini info cards ── */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:12,marginBottom:24}}>
          {[
            { icon:'🎯', label:t.targetDays, value:'89 days', color:'#FF4757', sub:'NEET 2026' },
            { icon:'📅', label:t.nextExam,   value:lang==='en'?'Mar 15':'15 मार्च', color:'#00C48C', sub:lang==='en'?'Mock Test #13':'मॉक #13' },
            { icon:'✅', label:t.accuracy,   value:'84.2%',  color:'#4D9FFF', sub:lang==='en'?'Last 5 tests':'पिछले 5 परीक्षा' },
            { icon:'📚', label:t.studyGoal,  value:'4/7',    color:'#A855F7', sub:lang==='en'?'Days studied':'दिन पढ़ा' },
            { icon:'🏅', label:lang==='en'?'Badges Earned':'बैज',  value:'3',  color:'#FFD700', sub:lang==='en'?'Total earned':'कुल बैज' },
            { icon:'🔥', label:lang==='en'?'Tests Given':'परीक्षाएं',value:'12', color:'#FFA502', sub:lang==='en'?'This month':'इस महीने' },
          ].map((m,i)=>(
            <div key={i} className="dash-card" style={{background:card,border:`1px solid ${bord}`,borderRadius:14,padding:'14px 16px',display:'flex',alignItems:'center',gap:12}}>
              <div style={{width:36,height:36,borderRadius:10,background:`${m.color}15`,border:`1px solid ${m.color}25`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,flexShrink:0}}>{m.icon}</div>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,color:m.color,lineHeight:1}}>{m.value}</div>
                <div style={{fontSize:11,fontWeight:600,color:tm}}>{m.label}</div>
                <div style={{fontSize:10,color:ts}}>{m.sub}</div>
              </div>
            </div>
          ))}
        </div>

        {/* ── ROW 4: Upcoming Exams + Recent Results ── */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(340px,1fr))',gap:20,marginBottom:20}}>

          {/* Upcoming Exams */}
          <div style={{background:card,border:`1px solid ${bord}`,borderRadius:18,overflow:'hidden'}}>
            <div style={{padding:'18px 20px',borderBottom:`1px solid ${bord}`,display:'flex',justifyContent:'space-between',alignItems:'center',background:`linear-gradient(135deg,rgba(77,159,255,0.05),transparent)`}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:tm}}>📝 {t.upcoming}</div>
              <Link href="/dashboard/exams" style={{color:'#4D9FFF',fontSize:12,fontWeight:700,textDecoration:'none'}}>{t.viewAll}</Link>
            </div>
            <div style={{padding:'12px'}}>
              {exams.length === 0 ? (
                <div style={{textAlign:'center',padding:'32px 0',color:ts,fontSize:13}}>
                  <div style={{fontSize:40,marginBottom:8}}>📋</div>
                  {t.noExam}
                </div>
              ) : exams.map((ex,i)=>(
                <div key={i} className="exam-row" style={{padding:'14px 12px',borderRadius:12,marginBottom:6,display:'flex',justifyContent:'space-between',alignItems:'center',background:`rgba(77,159,255,0.03)`,border:`1px solid ${bord}`,transition:'all 0.2s'}}>
                  <div>
                    <div style={{fontWeight:600,fontSize:14,color:tm,marginBottom:3}}>{ex.title||'NEET Mock Test'}</div>
                    <div style={{fontSize:11,color:ts}}>📅 {ex.scheduledAt?new Date(ex.scheduledAt).toLocaleDateString():lang==='en'?'TBA':'जल्द'} · ⏱ {ex.totalDurationSec?`${Math.round(ex.totalDurationSec/60)}m`:'200m'}</div>
                  </div>
                  <Link href={`/exam/${ex._id||'demo'}/waiting`}><button style={{padding:'8px 14px',borderRadius:9,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>{t.start}</button></Link>
                </div>
              ))}
              {/* Placeholder exam if none */}
              {exams.length === 0 && (
                <div style={{padding:'14px 12px',borderRadius:12,background:'rgba(77,159,255,0.04)',border:`1px dashed rgba(77,159,255,0.2)`}}>
                  <div style={{fontWeight:600,fontSize:13,color:ts,marginBottom:4}}>{lang==='en'?'NEET Full Mock #13 — Coming soon':'NEET मॉक #13 — जल्द आ रहा है'}</div>
                  <div style={{fontSize:11,color:mutedL}}>📅 March 15, 2026 · ⏱ 200 min · 720 marks</div>
                </div>
              )}
            </div>
          </div>

          {/* Recent Results */}
          <div style={{background:card,border:`1px solid ${bord}`,borderRadius:18,overflow:'hidden'}}>
            <div style={{padding:'18px 20px',borderBottom:`1px solid ${bord}`,display:'flex',justifyContent:'space-between',alignItems:'center',background:`linear-gradient(135deg,rgba(0,196,140,0.05),transparent)`}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:tm}}>📊 {t.recent}</div>
              <Link href="/dashboard/results" style={{color:'#4D9FFF',fontSize:12,fontWeight:700,textDecoration:'none'}}>{t.viewAll}</Link>
            </div>
            <div style={{padding:'12px'}}>
              {results.length === 0 ? (
                <div style={{textAlign:'center',padding:'32px 0',color:ts,fontSize:13}}>
                  <div style={{fontSize:40,marginBottom:8}}>📭</div>
                  {t.noResult}
                </div>
              ) : results.map((r,i)=>(
                <div key={i} style={{padding:'12px',borderRadius:12,marginBottom:6,background:'rgba(0,196,140,0.03)',border:`1px solid ${bord}`,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                  <div>
                    <div style={{fontWeight:600,fontSize:13,color:tm,marginBottom:3}}>{r.examTitle||'Mock Test'}</div>
                    <div style={{display:'flex',gap:10,fontSize:11,color:ts}}>
                      <span>✓ {r.totalCorrect||0}</span><span>✗ {r.totalIncorrect||0}</span><span>#{r.rank||'—'}</span>
                    </div>
                  </div>
                  <div style={{textAlign:'right'}}>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:800,color:'#4D9FFF'}}>{r.score||0}</div>
                    <div style={{fontSize:10,color:ts}}>/720</div>
                  </div>
                </div>
              ))}
              {/* Placeholder results */}
              {results.length === 0 && [
                {name:lang==='en'?'NEET Mock #12':'NEET मॉक #12', score:610, rank:234, pct:'96.8'},
                {name:lang==='en'?'NEET Mock #11':'NEET मॉक #11', score:587, rank:412, pct:'94.1'},
              ].map((r,i)=>(
                <div key={i} style={{padding:'12px',borderRadius:12,marginBottom:6,background:'rgba(77,159,255,0.03)',border:`1px solid ${bord}`,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                  <div>
                    <div style={{fontWeight:600,fontSize:13,color:tm,marginBottom:3}}>{r.name}</div>
                    <div style={{fontSize:11,color:ts}}>#{r.rank} AIR · {r.pct}%ile</div>
                  </div>
                  <div style={{textAlign:'right'}}>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:800,color:'#00C48C'}}>{r.score}</div>
                    <div style={{fontSize:10,color:ts}}>/720</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* ── ROW 5: Subject Performance Bar ── */}
        <div style={{background:card,border:`1px solid ${bord}`,borderRadius:18,padding:'20px',marginBottom:20}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:tm}}>🧪 {lang==='en'?'Subject Performance (Last Test)':'विषय प्रदर्शन (अंतिम परीक्षा)'}</div>
            <Link href="/dashboard/analytics" style={{color:'#4D9FFF',fontSize:12,fontWeight:700,textDecoration:'none'}}>{lang==='en'?'Full Analysis →':'पूरा विश्लेषण →'}</Link>
          </div>
          {[
            {sub:lang==='en'?'Physics':'भौतिकी',       s:148,m:180,c:'#4D9FFF',  acc:82},
            {sub:lang==='en'?'Chemistry':'रसायन',       s:152,m:180,c:'#00C48C',  acc:84},
            {sub:lang==='en'?'Biology (Bot+Zoo)':'जीव विज्ञान', s:310,m:360,c:'#A855F7', acc:86},
          ].map((sb,i)=>(
            <div key={i} style={{marginBottom:14}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:6}}>
                <div style={{display:'flex',alignItems:'center',gap:8}}>
                  <div style={{width:8,height:8,borderRadius:'50%',background:sb.c,boxShadow:`0 0 6px ${sb.c}`}}/>
                  <span style={{fontWeight:600,fontSize:13,color:tm}}>{sb.sub}</span>
                  <span style={{fontSize:11,color:ts}}>({sb.acc}% acc)</span>
                </div>
                <span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:15,color:sb.c}}>{sb.s}<span style={{fontSize:11,color:ts}}>/{sb.m}</span></span>
              </div>
              <div style={{background:`rgba(77,159,255,0.08)`,borderRadius:99,height:8,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${(sb.s/sb.m)*100}%`,background:`linear-gradient(90deg,${sb.c}88,${sb.c})`,borderRadius:99,transition:'width 1.2s ease',boxShadow:`0 0 8px ${sb.c}44`}}/>
              </div>
            </div>
          ))}
        </div>

        {/* ── ROW 6: Quick Access ── */}
        <div style={{background:card,border:`1px solid ${bord}`,borderRadius:18,padding:'20px',marginBottom:20}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:tm,marginBottom:16}}>⚡ {t.quick}</div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(110px,1fr))',gap:10}}>
            {[
              {href:'/dashboard/analytics',   icon:'📈', label:t.analytics,   color:'#4D9FFF'},
              {href:'/dashboard/leaderboard', icon:'🏆', label:t.leaderboard, color:'#FFD700'},
              {href:'/dashboard/certificate', icon:'🎓', label:t.cert,        color:'#00C48C'},
              {href:'/dashboard/admit-card',  icon:'🎫', label:t.admit,       color:'#A855F7'},
              {href:'/dashboard/results',     icon:'📊', label:t.results,     color:'#4D9FFF'},
              {href:'/support',               icon:'💬', label:t.support,     color:'#FFA502'},
            ].map(q=>(
              <Link key={q.href} href={q.href} className="quick-btn" style={{background:card2}}>
                <div style={{width:44,height:44,borderRadius:12,background:`${q.color}15`,border:`1px solid ${q.color}25`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,transition:'transform 0.2s'}}
                  onMouseEnter={e=>(e.currentTarget.style.transform='scale(1.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.transform='none')}>{q.icon}</div>
                <span style={{color:tm}}>{q.label}</span>
              </Link>
            ))}
          </div>
        </div>

        {/* ── ROW 7: Activity Feed ── */}
        <div style={{background:card,border:`1px solid ${bord}`,borderRadius:18,padding:'20px'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:tm,marginBottom:16}}>🕐 {t.activity}</div>
          {[
            {icon:'📝',text:lang==='en'?'Attempted NEET Mock #12 — Score: 610/720':'NEET मॉक #12 दिया — स्कोर: 610/720', time:lang==='en'?'2 days ago':'2 दिन पहले', color:'#4D9FFF'},
            {icon:'🏆',text:lang==='en'?'Achieved AIR #234 in Mock #12':'मॉक #12 में AIR #234 प्राप्त की', time:lang==='en'?'2 days ago':'2 दिन पहले', color:'#FFD700'},
            {icon:'🎓',text:lang==='en'?'Earned "NEET Excellence" Certificate':'NEET एक्सीलेंस प्रमाण पत्र मिला', time:lang==='en'?'5 days ago':'5 दिन पहले', color:'#00C48C'},
            {icon:'🔥',text:lang==='en'?'Maintained 7-day study streak':'7-दिन की अध्ययन लकीर बनाए रखी', time:lang==='en'?'1 week ago':'1 सप्ताह पहले', color:'#FFA502'},
          ].map((a,i)=>(
            <div key={i} style={{display:'flex',gap:12,alignItems:'flex-start',paddingBottom:i<3?14:0,marginBottom:i<3?14:0,borderBottom:i<3?`1px solid ${bord}`:'none'}}>
              <div style={{width:36,height:36,borderRadius:10,background:`${a.color}15`,border:`1px solid ${a.color}22`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,flexShrink:0}}>{a.icon}</div>
              <div style={{flex:1}}>
                <div style={{fontSize:13,color:tm,fontWeight:500,lineHeight:1.5}}>{a.text}</div>
                <div style={{fontSize:11,color:ts,marginTop:2}}>{a.time}</div>
              </div>
            </div>
          ))}
        </div>

      </main>
    </div>
  )
}
DASHEOF
log "Dashboard ultra premium ✓"

# =============================================================================
# GIT PUSH
# =============================================================================
step "GIT PUSH"
cd $FE
git add -A
git commit -m "Dashboard: Ultra Premium SaaS redesign + Sidebar hidden (logo click toggle)"
git push origin main

echo -e "\n${G}╔═════════════════════════════════════════════════════╗"
echo -e "║  ✅ Dashboard Premium + Sidebar Fix PUSHED!         ║"
echo -e "║                                                     ║"
echo -e "║  ✓ Sidebar — Hidden by default                     ║"
echo -e "║  ✓ Sidebar — Opens on Logo click in header         ║"
echo -e "║  ✓ Sidebar — Closes on outside click / ✕ button   ║"
echo -e "║  ✓ 4 Big animated stat cards with glow             ║"
echo -e "║  ✓ 6 Mini info cards (Target days, Accuracy etc.)  ║"
echo -e "║  ✓ Subject performance bars                        ║"
echo -e "║  ✓ Live clock in header                            ║"
echo -e "║  ✓ Activity feed                                   ║"
echo -e "║  ✓ Quick access grid                               ║"
echo -e "║  ✓ NO other pages touched                          ║"
echo -e "╚═════════════════════════════════════════════════════╝${N}"
