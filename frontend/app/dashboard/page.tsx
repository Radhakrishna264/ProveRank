'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useAuth } from '@/lib/useAuth'
import { EN_TEXTS, HI_TEXTS, useThemeVars } from '@/components/ThemeHelper'

const API = process.env.NEXT_PUBLIC_API_URL || ''

export default function Dashboard() {
  const { user, loading, logout } = useAuth('student')
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [stats, setStats] = useState({ rank:0, score:0, streak:0, percentile:0 })
  const [exams, setExams] = useState<any[]>([])
  const [results, setResults] = useState<any[]>([])
  const [notifications, setNotifications] = useState<any[]>([])
  const [sideOpen, setSideOpen] = useState(false)
  const [notifOpen, setNotifOpen] = useState(false)
  const [mounted, setMounted] = useState(false)

  const t = lang==='en' ? EN_TEXTS : HI_TEXTS
  const v = useThemeVars(dark)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
    if (user) fetchData()
  },[user])

  const fetchData = async () => {
    try {
      const headers = { Authorization:`Bearer ${user!.token}` }
      const [me] = await Promise.all([
        fetch(`${API}/api/auth/me`,{headers}).then(r=>r.json()),
      ])
      if (me.name) setStats({ rank:me.rank||0, score:me.bestScore||0, streak:me.streak||0, percentile:me.percentile||0 })
      const exRes = await fetch(`${API}/api/exams`,{headers})
      const exData = await exRes.json()
      if (Array.isArray(exData)) setExams(exData.slice(0,4))
      const resRes = await fetch(`${API}/api/results/my`,{headers}).catch(()=>null)
      if (resRes?.ok) { const rd=await resRes.json(); if(Array.isArray(rd)) setResults(rd.slice(0,4)) }
    } catch {}
  }

  const toggleLang = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark = ()=>{ const n=!dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }

  if (loading || !mounted) return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',flexDirection:'column',gap:16}}>
      <div style={{width:44,height:44,border:'3px solid rgba(77,159,255,0.2)',borderTopColor:'#4D9FFF',borderRadius:'50%',animation:'spin 1s linear infinite'}}/>
      <style>{`@keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}`}</style>
      <span style={{fontSize:14,opacity:0.7}}>{lang==='en'?'Loading...':'लोड हो रहा है...'}</span>
    </div>
  )

  const navLinks = [
    { href:'/dashboard', icon:'⊞', label:t.dashboard },
    { href:'/dashboard/profile', icon:'👤', label:t.profile },
    { href:'/dashboard/exams', icon:'📝', label:t.exams },
    { href:'/dashboard/results', icon:'📊', label:t.results },
    { href:'/dashboard/analytics', icon:'📈', label:t.analytics },
    { href:'/dashboard/leaderboard', icon:'🏆', label:t.leaderboard },
    { href:'/dashboard/certificate', icon:'🎓', label:t.certificate },
    { href:'/dashboard/admit-card', icon:'🎫', label:t.admitCard },
  ]

  const statCards = [
    { label:t.currentRank, value:`#${stats.rank||'—'}`, icon:'🏆', color:'#4D9FFF' },
    { label:t.bestScore,   value:stats.score?`${stats.score}/720`:'—/720', icon:'📊', color:'#00C48C' },
    { label:t.streak,      value:`${stats.streak||0} ${lang==='en'?'days':'दिन'}`, icon:'🔥', color:'#FFA502' },
    { label:t.percentile,  value:stats.percentile?`${stats.percentile}%`:'—%', icon:'📈', color:'#A855F7' },
  ]

  return (
    <div style={{minHeight:'100vh',background:v.bg,color:v.textMain,fontFamily:'Inter,sans-serif',display:'flex'}}>
      <style>{`
        @keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}
        .tbtn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15);}
        .exam-card:hover{transform:translateY(-3px)!important;border-color:rgba(77,159,255,0.4)!important;}
        .stat-hover:hover{transform:translateY(-4px)!important;box-shadow:0 12px 30px rgba(77,159,255,0.12)!important;}
      `}</style>

      {/* ── SIDEBAR ─────────────────────────────────────────────── */}
      <aside className="sidebar" style={{background:v.sidebarBg,borderRight:`1px solid ${v.borderColor}`,display:'flex',flexDirection:'column',gap:4}}>
        {/* Logo */}
        <div style={{padding:'8px 8px 24px',borderBottom:`1px solid ${v.borderColor}`,marginBottom:8}}>
          <div style={{display:'flex',alignItems:'center',gap:10}}>
            <svg width={32} height={32} viewBox="0 0 64 64">
              <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/>
              <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF">PR</text>
            </svg>
            <span style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
          </div>
        </div>
        {/* Nav */}
        <div style={{flex:1,overflowY:'auto'}}>
          <div style={{fontSize:10,fontWeight:700,color:v.mutedText,letterSpacing:'0.1em',textTransform:'uppercase',padding:'8px 16px',marginBottom:4}}>{lang==='en'?'STUDENT PORTAL':'छात्र पोर्टल'}</div>
          {navLinks.map(n=>(
            <Link key={n.href} href={n.href} className="sidebar-link" style={{color:v.textSub}}>
              <span>{n.icon}</span><span>{n.label}</span>
            </Link>
          ))}
        </div>
        {/* Bottom */}
        <div style={{borderTop:`1px solid ${v.borderColor}`,paddingTop:16,marginTop:16,display:'flex',flexDirection:'column',gap:8}}>
          <button className="tbtn" onClick={toggleLang} style={{width:'100%',textAlign:'left'}}>{lang==='en'?'🇮🇳 English':'🌐 हिंदी'}</button>
          <button className="tbtn" onClick={toggleDark} style={{width:'100%',textAlign:'left'}}>{dark?'☀️ Light Mode':'🌙 Dark Mode'}</button>
          <button onClick={logout} style={{padding:'10px 16px',borderRadius:10,border:'1px solid rgba(255,71,87,0.3)',background:'rgba(255,71,87,0.08)',color:'#FF4757',cursor:'pointer',fontSize:13,fontWeight:500,width:'100%',textAlign:'left'}}>
            🚪 {t.logout}
          </button>
        </div>
      </aside>

      {/* ── MAIN ────────────────────────────────────────────────── */}
      <main className="main-with-sidebar" style={{flex:1,padding:'32px',minHeight:'100vh',animation:'fadeUp 0.5s ease forwards'}}>
        {/* Top Bar */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:32,flexWrap:'wrap',gap:12}}>
          <div>
            <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.3rem,3vw,1.8rem)',fontWeight:700,marginBottom:4}}>
              {t.welcomeBack} <span style={{color:'#4D9FFF'}}>{lang==='en'?'Student':'छात्र'} 👋</span>
            </h1>
            <p style={{color:v.textSub,fontSize:14}}>{lang==='en'?'Your NEET preparation dashboard':'आपका NEET तैयारी डैशबोर्ड'}</p>
          </div>
          <div style={{display:'flex',gap:10,alignItems:'center'}}>
            <div style={{position:'relative',cursor:'pointer'}} onClick={()=>setNotifOpen(!notifOpen)}>
              <span style={{fontSize:22}}>🔔</span>
              <span style={{position:'absolute',top:-4,right:-4,background:'#FF4757',borderRadius:'50%',width:16,height:16,fontSize:10,fontWeight:700,color:'#fff',display:'flex',alignItems:'center',justifyContent:'center'}}>3</span>
            </div>
            <Link href="/dashboard/profile">
              <div style={{width:40,height:40,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0066CC)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,cursor:'pointer',fontWeight:700,color:'#fff'}}>S</div>
            </Link>
          </div>
        </div>

        {/* ── Stat Cards ── */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(200px,1fr))',gap:20,marginBottom:32}}>
          {statCards.map((s,i)=>(
            <div key={i} className="stat-hover" style={{background:v.cardBg,border:`1px solid ${v.borderColor}`,borderRadius:16,padding:'24px',transition:'all 0.3s',cursor:'default'}}>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12}}>
                <div>
                  <div style={{color:v.textSub,fontSize:12,fontWeight:600,letterSpacing:'0.04em',textTransform:'uppercase',marginBottom:8}}>{s.label}</div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:32,fontWeight:700,color:s.color,lineHeight:1}}>{s.value}</div>
                </div>
                <span style={{fontSize:28}}>{s.icon}</span>
              </div>
              <div className="progress-bar" style={{height:4}}>
                <div className="progress-fill" style={{width:`${Math.min((stats.score/720)*100,100)||20}%`}}/>
              </div>
            </div>
          ))}
        </div>

        {/* ── Upcoming Exams ── */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(340px,1fr))',gap:24,marginBottom:32}}>
          <div style={{background:v.cardBg,border:`1px solid ${v.borderColor}`,borderRadius:16,padding:24}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20}}>
              <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700}}>📝 {t.upcomingExams}</h2>
              <Link href="/dashboard/exams" style={{color:'#4D9FFF',fontSize:13,fontWeight:600,textDecoration:'none'}}>{lang==='en'?'View All →':'सभी देखें →'}</Link>
            </div>
            {exams.length === 0 ? (
              <div style={{color:v.textSub,textAlign:'center',padding:'32px 0',fontSize:14}}>
                <div style={{fontSize:40,marginBottom:8}}>📋</div>
                {t.noExams}
              </div>
            ) : exams.map((ex,i)=>(
              <div key={i} className="exam-card" style={{background:`rgba(77,159,255,0.05)`,border:`1px solid ${v.borderColor}`,borderRadius:12,padding:16,marginBottom:12,transition:'all 0.3s'}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:8}}>
                  <div style={{fontWeight:600,fontSize:15}}>{ex.title||'NEET Mock Test'}</div>
                  <span className="badge badge-blue">{lang==='en'?'Upcoming':'आगामी'}</span>
                </div>
                <div style={{color:v.textSub,fontSize:12,marginBottom:12}}>
                  📅 {ex.scheduledAt ? new Date(ex.scheduledAt).toLocaleDateString(lang==='en'?'en-IN':'hi-IN') : (lang==='en'?'Date TBA':'तिथि जल्द')}{' '}
                  · ⏱ {ex.totalDurationSec ? `${Math.round(ex.totalDurationSec/60)} ${lang==='en'?'min':'मिनट'}` : (lang==='en'?'200 min':'200 मिनट')}
                </div>
                <Link href={`/exam/${ex._id||'demo'}/waiting`}>
                  <button className="lb" style={{fontSize:13,padding:'10px 16px',borderRadius:8}}>{t.startExam}</button>
                </Link>
              </div>
            ))}
          </div>

          {/* ── Recent Results ── */}
          <div style={{background:v.cardBg,border:`1px solid ${v.borderColor}`,borderRadius:16,padding:24}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20}}>
              <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700}}>📊 {t.recentResults}</h2>
              <Link href="/dashboard/results" style={{color:'#4D9FFF',fontSize:13,fontWeight:600,textDecoration:'none'}}>{lang==='en'?'View All →':'सभी देखें →'}</Link>
            </div>
            {results.length === 0 ? (
              <div style={{color:v.textSub,textAlign:'center',padding:'32px 0',fontSize:14}}>
                <div style={{fontSize:40,marginBottom:8}}>📭</div>
                {lang==='en'?'No results yet. Give your first exam!':'अभी कोई परिणाम नहीं। पहली परीक्षा दें!'}
              </div>
            ) : results.map((r,i)=>(
              <div key={i} style={{borderBottom:`1px solid ${v.borderColor}`,paddingBottom:12,marginBottom:12}}>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:6}}>
                  <div style={{fontWeight:600,fontSize:14}}>{r.examTitle||'Mock Test'}</div>
                  <span className="badge badge-green">{r.score||0}/720</span>
                </div>
                <div style={{display:'flex',gap:12,color:v.textSub,fontSize:12}}>
                  <span>🏆 Rank #{r.rank||'—'}</span>
                  <span>📊 {r.percentile||0}%ile</span>
                  <span>✓ {r.totalCorrect||0} correct</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* ── Quick Links ── */}
        <div style={{background:v.cardBg,border:`1px solid ${v.borderColor}`,borderRadius:16,padding:24}}>
          <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:20}}>⚡ {lang==='en'?'Quick Access':'त्वरित पहुंच'}</h2>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:12}}>
            {[
              {href:'/dashboard/analytics',icon:'📈',label:lang==='en'?'Analytics':'विश्लेषण'},
              {href:'/dashboard/leaderboard',icon:'🏆',label:lang==='en'?'Leaderboard':'लीडरबोर्ड'},
              {href:'/dashboard/certificate',icon:'🎓',label:lang==='en'?'Certificates':'प्रमाण पत्र'},
              {href:'/dashboard/admit-card',icon:'🎫',label:lang==='en'?'Admit Card':'प्रवेश पत्र'},
            ].map(l=>(
              <Link key={l.href} href={l.href} style={{textDecoration:'none'}}>
                <div style={{background:`rgba(77,159,255,0.06)`,border:`1px solid ${v.borderColor}`,borderRadius:12,padding:'16px 12px',textAlign:'center',cursor:'pointer',transition:'all 0.3s',color:v.textMain}}
                  onMouseEnter={e=>{e.currentTarget.style.borderColor='rgba(77,159,255,0.4)';e.currentTarget.style.transform='translateY(-3px)'}}
                  onMouseLeave={e=>{e.currentTarget.style.borderColor=v.borderColor;e.currentTarget.style.transform='none'}}>
                  <div style={{fontSize:28,marginBottom:8}}>{l.icon}</div>
                  <div style={{fontSize:13,fontWeight:600}}>{l.label}</div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </main>
    </div>
  )
}
