'use client'
import { useState, useEffect, ReactNode } from 'react'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useAuth } from '@/lib/useAuth'

interface Props { children: ReactNode; title?: string; subtitle?: string }

export default function DashLayout({ children, title, subtitle }: Props) {
  const { user, logout } = useAuth('student')
  const pathname = usePathname()
  const router = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [sideOpen, setSideOpen] = useState(false)
  const [mounted, setMounted] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
  },[])

  const toggleLang = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark = ()=>{ const n=!dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }

  const v = {
    bg:       dark ? '#000A18' : '#F0F7FF',
    sidebar:  dark ? 'rgba(0,8,20,0.97)'   : 'rgba(248,252,255,0.98)',
    card:     dark ? 'rgba(0,18,36,0.9)'   : 'rgba(255,255,255,0.95)',
    bord:     dark ? 'rgba(77,159,255,0.14)': 'rgba(77,159,255,0.25)',
    tm:       dark ? '#E8F4FF' : '#0F172A',
    ts:       dark ? '#6B8BAF' : '#64748B',
    topbar:   dark ? 'rgba(0,6,18,0.96)'   : 'rgba(248,252,255,0.96)',
    muted:    dark ? '#2A4A6A' : '#CBD5E1',
    hover:    dark ? 'rgba(77,159,255,0.08)': 'rgba(77,159,255,0.06)',
    activeLink: dark ? 'rgba(77,159,255,0.15)' : 'rgba(77,159,255,0.1)',
  }

  const nav = [
    { href:'/dashboard',              icon:'⊞', en:'Dashboard',    hi:'डैशबोर्ड' },
    { href:'/dashboard/profile',      icon:'👤', en:'Profile',      hi:'प्रोफाइल' },
    { href:'/dashboard/exams',        icon:'📝', en:'My Exams',     hi:'मेरी परीक्षाएं' },
    { href:'/dashboard/results',      icon:'📊', en:'Results',      hi:'परिणाम' },
    { href:'/dashboard/analytics',    icon:'📈', en:'Analytics',    hi:'विश्लेषण' },
    { href:'/dashboard/leaderboard',  icon:'🏆', en:'Leaderboard',  hi:'लीडरबोर्ड' },
    { href:'/dashboard/certificate',  icon:'🎓', en:'Certificate',  hi:'प्रमाण पत्र' },
    { href:'/dashboard/admit-card',   icon:'🎫', en:'Admit Card',   hi:'प्रवेश पत्र' },
    { href:'/support',                icon:'💬', en:'Support',      hi:'सहायता' },
  ]

  if (!mounted) return null

  return (
    <div style={{minHeight:'100vh',background:v.bg,fontFamily:'Inter,sans-serif',color:v.tm,display:'flex'}}>
      <style>{`
        @keyframes fadeIn{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
        @keyframes slideIn{from{transform:translateX(-100%)}to{transform:translateX(0)}}
        .dl-link{display:flex;align-items:center;gap:12px;padding:11px 14px;border-radius:12px;text-decoration:none;font-weight:500;font-size:14px;transition:all 0.2s;margin-bottom:3px;color:${v.ts};}
        .dl-link:hover{background:${v.hover};color:${v.tm};}
        .dl-link.active{background:${v.activeLink};color:#4D9FFF;font-weight:700;border-left:3px solid #4D9FFF;padding-left:11px;}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.35);background:rgba(77,159,255,0.06);color:${v.ts};font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;font-family:Inter,sans-serif;}
        .tbtn:hover{border-color:#4D9FFF;color:#4D9FFF;background:rgba(77,159,255,0.12);}
        .lb{padding:11px 22px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:14px;font-weight:700;cursor:pointer;transition:all 0.3s;font-family:Inter,sans-serif;}
        .lb:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(77,159,255,0.4);}
        .overlay{position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:49;backdrop-filter:blur(2px);}
        @media(max-width:768px){.sidebar-desk{display:none!important;}.mob-header{display:flex!important;}}
        @media(min-width:769px){.mob-header{display:none!important;}}
      `}</style>

      {/* ── DESKTOP SIDEBAR ─────────────────────────────── */}
      <aside className="sidebar-desk" style={{width:256,flexShrink:0,background:v.sidebar,borderRight:`1px solid ${v.bord}`,height:'100vh',position:'sticky',top:0,display:'flex',flexDirection:'column',padding:'20px 12px',overflowY:'auto',zIndex:50}}>
        {/* Logo */}
        <Link href="/" style={{textDecoration:'none',display:'flex',alignItems:'center',gap:10,padding:'6px 8px',marginBottom:24}}>
          <svg width={34} height={34} viewBox="0 0 64 64">
            <defs><filter id="sg"><feGaussianBlur stdDeviation="2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
            <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+27*Math.cos(a)},${32+27*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2" filter="url(#sg)"/>
            <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+21*Math.cos(a)},${32+21*Math.sin(a)}`}).join(' ')} fill="rgba(77,159,255,0.1)" stroke="#4D9FFF" strokeWidth="1"/>
            <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF" filter="url(#sg)">PR</text>
          </svg>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#FFFFFF,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1}}>ProveRank</div>
            <div style={{fontSize:9,color:v.ts,letterSpacing:'0.12em',textTransform:'uppercase',fontWeight:600}}>Student Portal</div>
          </div>
        </Link>

        {/* Nav */}
        <div style={{flex:1}}>
          <div style={{fontSize:9,fontWeight:700,color:v.muted,letterSpacing:'0.12em',textTransform:'uppercase',padding:'0 8px',marginBottom:8}}>
            {lang==='en'?'NAVIGATION':'नेविगेशन'}
          </div>
          {nav.map(n=>(
            <Link key={n.href} href={n.href} className={`dl-link ${pathname===n.href?'active':''}`}>
              <span style={{fontSize:16,width:20,textAlign:'center',flexShrink:0}}>{n.icon}</span>
              <span>{lang==='en'?n.en:n.hi}</span>
            </Link>
          ))}
        </div>

        {/* Bottom Section */}
        <div style={{borderTop:`1px solid ${v.bord}`,paddingTop:16,display:'flex',flexDirection:'column',gap:6}}>
          <div style={{padding:'8px 14px',borderRadius:12,background:`rgba(77,159,255,0.06)`,border:`1px solid ${v.bord}`,marginBottom:4}}>
            <div style={{fontSize:11,color:v.ts,marginBottom:2}}>{lang==='en'?'Logged in as':'लॉग इन किया है'}</div>
            <div style={{fontWeight:700,fontSize:13,color:v.tm,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>
              {user?.role === 'superadmin' ? '⚡ SuperAdmin' : user?.role === 'admin' ? '🛡 Admin' : '🎓 Student'}
            </div>
          </div>
          <div style={{display:'flex',gap:6}}>
            <button className="tbtn" onClick={toggleLang} style={{flex:1,fontSize:11}}>{lang==='en'?'🇮🇳 हिं':'🌐 EN'}</button>
            <button className="tbtn" onClick={toggleDark} style={{flex:1,fontSize:11}}>{dark?'☀️':'🌙'}</button>
          </div>
          <button onClick={logout} style={{display:'flex',alignItems:'center',gap:10,padding:'11px 14px',borderRadius:12,border:'1px solid rgba(255,71,87,0.25)',background:'rgba(255,71,87,0.06)',color:'#FF6B7A',cursor:'pointer',fontWeight:600,fontSize:13,fontFamily:'Inter,sans-serif',transition:'all 0.2s',textAlign:'left',width:'100%'}}
            onMouseEnter={e=>{e.currentTarget.style.background='rgba(255,71,87,0.12)';e.currentTarget.style.borderColor='rgba(255,71,87,0.4)'}}
            onMouseLeave={e=>{e.currentTarget.style.background='rgba(255,71,87,0.06)';e.currentTarget.style.borderColor='rgba(255,71,87,0.25)'}}>
            <span>🚪</span> {lang==='en'?'Sign Out':'साइन आउट'}
          </button>
        </div>
      </aside>

      {/* ── MOBILE SIDEBAR OVERLAY ───────────────────────── */}
      {sideOpen && <div className="overlay" onClick={()=>setSideOpen(false)}/>}
      {sideOpen && (
        <aside style={{position:'fixed',top:0,left:0,width:270,height:'100vh',background:v.sidebar,borderRight:`1px solid ${v.bord}`,zIndex:100,display:'flex',flexDirection:'column',padding:'20px 12px',overflowY:'auto',animation:'slideIn 0.3s ease'}}>
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:24}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,color:'#4D9FFF'}}>ProveRank</div>
            <button onClick={()=>setSideOpen(false)} style={{background:'none',border:'none',color:v.ts,fontSize:22,cursor:'pointer'}}>✕</button>
          </div>
          {nav.map(n=>(
            <Link key={n.href} href={n.href} className={`dl-link ${pathname===n.href?'active':''}`} onClick={()=>setSideOpen(false)}>
              <span style={{fontSize:16,width:20,textAlign:'center'}}>{n.icon}</span>
              <span>{lang==='en'?n.en:n.hi}</span>
            </Link>
          ))}
          <div style={{marginTop:'auto',borderTop:`1px solid ${v.bord}`,paddingTop:16}}>
            <button onClick={logout} style={{width:'100%',padding:'12px',borderRadius:12,border:'1px solid rgba(255,71,87,0.25)',background:'rgba(255,71,87,0.06)',color:'#FF6B7A',cursor:'pointer',fontWeight:600,fontSize:13,fontFamily:'Inter,sans-serif'}}>
              🚪 {lang==='en'?'Sign Out':'साइन आउट'}
            </button>
          </div>
        </aside>
      )}

      {/* ── MAIN AREA ─────────────────────────────────────── */}
      <div style={{flex:1,display:'flex',flexDirection:'column',minHeight:'100vh',overflow:'hidden'}}>
        {/* Mobile Header */}
        <header className="mob-header" style={{height:56,background:v.topbar,borderBottom:`1px solid ${v.bord}`,padding:'0 16px',alignItems:'center',justifyContent:'space-between',position:'sticky',top:0,zIndex:40,backdropFilter:'blur(20px)'}}>
          <button onClick={()=>setSideOpen(true)} style={{background:'none',border:'none',color:v.tm,fontSize:22,cursor:'pointer'}}>☰</button>
          <span style={{fontFamily:'Playfair Display,serif',fontWeight:800,color:'#4D9FFF',fontSize:17}}>ProveRank</span>
          <div style={{display:'flex',gap:6}}>
            <button className="tbtn" onClick={toggleLang} style={{fontSize:11,padding:'4px 8px'}}>{lang==='en'?'🇮🇳':'🌐'}</button>
            <button className="tbtn" onClick={toggleDark} style={{padding:'4px 8px'}}>{dark?'☀️':'🌙'}</button>
          </div>
        </header>

        {/* Desktop Top Bar */}
        <header className="sidebar-desk" style={{height:60,background:v.topbar,borderBottom:`1px solid ${v.bord}`,padding:'0 28px',display:'flex',alignItems:'center',justifyContent:'space-between',position:'sticky',top:0,zIndex:40,backdropFilter:'blur(20px)'}}>
          <div>
            {title && <h1 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:v.tm,lineHeight:1}}>{title}</h1>}
            {subtitle && <p style={{color:v.ts,fontSize:12,marginTop:2}}>{subtitle}</p>}
          </div>
          <div style={{display:'flex',gap:8,alignItems:'center'}}>
            <button className="tbtn" onClick={toggleLang}>{lang==='en'?'🇮🇳 EN':'🌐 हिंदी'}</button>
            <button className="tbtn" onClick={toggleDark}>{dark?'☀️':'🌙'}</button>
            <div style={{width:36,height:36,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,color:'#fff',fontSize:14,cursor:'pointer'}}
              onClick={()=>router.push('/dashboard/profile')}>S</div>
          </div>
        </header>

        {/* Page Content */}
        <main style={{flex:1,padding:'28px',animation:'fadeIn 0.4s ease forwards',overflowY:'auto'}}>
          {title && (
            <div className="mob-header" style={{display:'block',marginBottom:20}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:v.tm}}>{title}</h1>
              {subtitle && <p style={{color:v.ts,fontSize:13,marginTop:4}}>{subtitle}</p>}
            </div>
          )}
          {children}
        </main>
      </div>
    </div>
  )
}
