'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useAuth } from '@/lib/useAuth'
import { EN_TEXTS, HI_TEXTS, useThemeVars } from '@/components/ThemeHelper'

const API = process.env.NEXT_PUBLIC_API_URL || ''

export default function AdminDashboard() {
  const { user, loading, logout } = useAuth(['admin','superadmin'])
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [tab, setTab]   = useState('dashboard')
  const [stats, setStats] = useState({ students:0, exams:0, attempts:0, alerts:0 })
  const [mounted, setMounted] = useState(false)

  const t = lang==='en' ? EN_TEXTS : HI_TEXTS
  const v = useThemeVars(dark)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
    if (user) fetchStats()
  },[user])

  const fetchStats = async () => {
    try {
      const h = { Authorization:`Bearer ${user!.token}` }
      const r = await fetch(`${API}/api/admin/manage/stats`, {headers:h}).catch(()=>null)
      if (r?.ok) { const d=await r.json(); setStats({students:d.totalStudents||0,exams:d.totalExams||0,attempts:d.todayAttempts||0,alerts:d.cheatAlerts||0}) }
    } catch {}
  }

  const toggleLang = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark = ()=>{ const n=!dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }

  if (loading || !mounted) return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>
      <div style={{width:44,height:44,border:'3px solid rgba(77,159,255,0.2)',borderTopColor:'#4D9FFF',borderRadius:'50%',animation:'spin 1s linear infinite'}}/>
      <style>{`@keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}`}</style>
    </div>
  )

  const tabs = [
    {id:'dashboard',icon:'📊',label:lang==='en'?'Dashboard':'डैशबोर्ड'},
    {id:'students', icon:'👥',label:t.students},
    {id:'exams',    icon:'📝',label:t.manageExams},
    {id:'questions',icon:'❓',label:t.questionBank},
    {id:'monitor',  icon:'🔴',label:t.liveMonitoring},
    {id:'reports',  icon:'📈',label:t.reports},
    {id:'settings', icon:'⚙️',label:t.settings},
  ]

  const statCards = [
    { label:t.totalStudents,  value:stats.students, icon:'👥', color:'#4D9FFF', link:'/admin/x7k2p/students' },
    { label:t.activeExams,    value:stats.exams,    icon:'📝', color:'#00C48C', link:'/admin/x7k2p/exams' },
    { label:t.todayAttempts,  value:stats.attempts, icon:'📋', color:'#FFA502', link:'/admin/x7k2p/monitoring' },
    { label:t.cheatAlerts,    value:stats.alerts,   icon:'🚨', color:'#FF4757', link:'/admin/x7k2p/monitoring' },
  ]

  return (
    <div style={{minHeight:'100vh',background:v.bg,color:v.textMain,fontFamily:'Inter,sans-serif'}}>
      <style>{`
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}
        .tbtn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15);}
        .lb{width:100%;padding:15px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:15px;font-weight:700;cursor:pointer;transition:all 0.3s;}
        .lb:hover{transform:translateY(-2px);}
        .admin-tab:hover{background:rgba(77,159,255,0.1)!important;}
      `}</style>

      {/* ── TOP NAV ─────────────────────────────────────────────── */}
      <nav style={{position:'sticky',top:0,zIndex:100,background:dark?'rgba(0,10,24,0.95)':'rgba(248,252,255,0.95)',backdropFilter:'blur(20px)',borderBottom:`1px solid ${v.borderColor}`,padding:'0 5%',height:64,display:'flex',alignItems:'center',gap:12}}>
        {/* Logo */}
        <div style={{display:'flex',alignItems:'center',gap:10,marginRight:20,flexShrink:0}}>
          <svg width={28} height={28} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF">PR</text></svg>
          <span style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
          <span className="badge badge-red" style={{fontSize:10,marginLeft:4}}>{user?.role?.toUpperCase()}</span>
        </div>
        {/* Tabs */}
        <div style={{display:'flex',gap:4,flex:1,overflowX:'auto'}}>
          {tabs.map(tb=>(
            <button key={tb.id} onClick={()=>setTab(tb.id)} className="admin-tab"
              style={{padding:'8px 16px',borderRadius:10,border:'none',cursor:'pointer',fontWeight:tab===tb.id?700:500,fontSize:13,display:'flex',alignItems:'center',gap:6,whiteSpace:'nowrap',fontFamily:'Inter,sans-serif',background:tab===tb.id?'rgba(77,159,255,0.18)':'transparent',color:tab===tb.id?'#4D9FFF':v.textSub,transition:'all 0.2s'}}>
              {tb.icon} {tb.label}
            </button>
          ))}
        </div>
        {/* Right */}
        <div style={{display:'flex',gap:8,alignItems:'center',flexShrink:0}}>
          <button className="tbtn" onClick={toggleLang}>{lang==='en'?'🇮🇳':'🌐'}</button>
          <button className="tbtn" onClick={toggleDark}>{dark?'☀️':'🌙'}</button>
          <button onClick={logout} style={{background:'rgba(255,71,87,0.1)',border:'1px solid rgba(255,71,87,0.3)',color:'#FF4757',padding:'6px 14px',borderRadius:10,cursor:'pointer',fontSize:13,fontWeight:600,fontFamily:'Inter,sans-serif'}}>
            {t.logout}
          </button>
        </div>
      </nav>

      {/* ── CONTENT ─────────────────────────────────────────────── */}
      <div style={{padding:'32px 5%',animation:'fadeUp 0.5s ease forwards'}}>
        {/* Dashboard Tab */}
        {tab === 'dashboard' && (
          <div>
            <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.4rem,3vw,2rem)',fontWeight:700,marginBottom:8}}>{t.adminDash}</h1>
            <p style={{color:v.textSub,fontSize:14,marginBottom:32}}>{lang==='en'?'Platform overview and key metrics':'प्लेटफॉर्म अवलोकन और प्रमुख मेट्रिक्स'}</p>
            {/* Stat Cards */}
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:20,marginBottom:32}}>
              {statCards.map((s,i)=>(
                <Link key={i} href={s.link} style={{textDecoration:'none'}}>
                  <div style={{background:v.cardBg,border:`1px solid ${v.borderColor}`,borderRadius:16,padding:24,transition:'all 0.3s',cursor:'pointer'}}
                    onMouseEnter={e=>{e.currentTarget.style.transform='translateY(-4px)';e.currentTarget.style.borderColor='rgba(77,159,255,0.4)'}}
                    onMouseLeave={e=>{e.currentTarget.style.transform='none';e.currentTarget.style.borderColor=v.borderColor}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12}}>
                      <div style={{color:v.textSub,fontSize:12,fontWeight:600,letterSpacing:'0.04em',textTransform:'uppercase'}}>{s.label}</div>
                      <span style={{fontSize:28}}>{s.icon}</span>
                    </div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:36,fontWeight:800,color:s.color,lineHeight:1}}>{s.value.toLocaleString()}</div>
                    <div style={{color:'#4D9FFF',fontSize:12,marginTop:8,fontWeight:500}}>{lang==='en'?'View Details →':'विवरण देखें →'}</div>
                  </div>
                </Link>
              ))}
            </div>
            {/* Quick Actions */}
            <div style={{background:v.cardBg,border:`1px solid ${v.borderColor}`,borderRadius:16,padding:24}}>
              <h2 style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,marginBottom:20}}>⚡ {lang==='en'?'Quick Actions':'त्वरित क्रियाएं'}</h2>
              <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:12}}>
                {[
                  {tab:'exams',icon:'➕',label:lang==='en'?'Create New Exam':'नई परीक्षा बनाएं'},
                  {tab:'questions',icon:'📤',label:lang==='en'?'Upload Questions':'प्रश्न अपलोड करें'},
                  {tab:'students',icon:'📥',label:lang==='en'?'Import Students':'छात्र आयात करें'},
                  {tab:'reports',icon:'📊',label:lang==='en'?'Generate Report':'रिपोर्ट बनाएं'},
                  {tab:'settings',icon:'📢',label:lang==='en'?'Announcement':'घोषणा'},
                  {tab:'monitor',icon:'🔴',label:lang==='en'?'Live Monitor':'लाइव निगरानी'},
                ].map((a,i)=>(
                  <button key={i} onClick={()=>setTab(a.tab)} style={{background:'rgba(77,159,255,0.06)',border:`1px solid ${v.borderColor}`,borderRadius:12,padding:'16px',display:'flex',alignItems:'center',gap:10,cursor:'pointer',color:v.textMain,fontWeight:500,fontSize:14,fontFamily:'Inter,sans-serif',transition:'all 0.2s',textAlign:'left'}}
                    onMouseEnter={e=>{e.currentTarget.style.borderColor='rgba(77,159,255,0.4)';e.currentTarget.style.background='rgba(77,159,255,0.1)'}}
                    onMouseLeave={e=>{e.currentTarget.style.borderColor=v.borderColor;e.currentTarget.style.background='rgba(77,159,255,0.06)'}}>
                    <span style={{fontSize:20}}>{a.icon}</span>{a.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Students Tab */}
        {tab === 'students' && (
          <div>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:24,flexWrap:'wrap',gap:12}}>
              <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.3rem,3vw,1.8rem)',fontWeight:700}}>👥 {t.students}</h1>
              <div style={{display:'flex',gap:10}}>
                <button className="tbtn">{lang==='en'?'📥 Import Excel':'📥 Excel आयात'}</button>
                <button className="tbtn" style={{color:'#00C48C',borderColor:'rgba(0,196,140,0.4)'}}>{lang==='en'?'📤 Export':'📤 निर्यात'}</button>
              </div>
            </div>
            <div style={{background:v.cardBg,border:`1px solid ${v.borderColor}`,borderRadius:16,padding:24}}>
              <div style={{display:'flex',gap:12,marginBottom:20,flexWrap:'wrap'}}>
                <input placeholder={t.search} style={{flex:1,minWidth:200,padding:'10px 16px',borderRadius:10,border:`1px solid ${v.borderColor}`,background:v.inputBg,color:v.textMain,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none'}}/>
                <select style={{padding:'10px 16px',borderRadius:10,border:`1px solid ${v.borderColor}`,background:v.inputBg,color:v.textMain,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none'}}>
                  <option>{lang==='en'?'All Groups':'सभी समूह'}</option>
                  <option>Dropper</option>
                  <option>12th Grade</option>
                  <option>Free Students</option>
                </select>
              </div>
              <div style={{overflowX:'auto'}}>
                <table className="pr-table" style={{color:v.textMain}}>
                  <thead>
                    <tr>
                      {[lang==='en'?'Name':'नाम','Email','Rank',lang==='en'?'Status':'स्थिति',lang==='en'?'Actions':'क्रियाएं'].map(h=>(
                        <th key={h} style={{color:v.textSub,borderBottom:`1px solid ${v.borderColor}`}}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {[{name:'Sample Student',email:'student@proverank.com',rank:1,status:'Active'}].map((s,i)=>(
                      <tr key={i} onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')} onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                        <td style={{borderBottom:`1px solid rgba(0,45,85,0.3)`}}><div style={{fontWeight:600}}>{s.name}</div></td>
                        <td style={{borderBottom:`1px solid rgba(0,45,85,0.3)`,color:v.textSub,fontSize:13}}>{s.email}</td>
                        <td style={{borderBottom:`1px solid rgba(0,45,85,0.3)`}}><span className="badge badge-blue">#{s.rank}</span></td>
                        <td style={{borderBottom:`1px solid rgba(0,45,85,0.3)`}}><span className="badge badge-green">{s.status}</span></td>
                        <td style={{borderBottom:`1px solid rgba(0,45,85,0.3)`}}>
                          <div style={{display:'flex',gap:8}}>
                            <button className="tbtn" style={{fontSize:12,padding:'4px 10px'}}>{t.view}</button>
                            <button className="tbtn" style={{fontSize:12,padding:'4px 10px',color:'#FF4757',borderColor:'rgba(255,71,87,0.3)'}}>{lang==='en'?'Ban':'प्रतिबंध'}</button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Other Tabs — Placeholder with link to specific pages */}
        {['exams','questions','monitor','reports','settings'].includes(tab) && (
          <div style={{textAlign:'center',padding:'80px 5%'}}>
            <div style={{fontSize:64,marginBottom:24}}>
              {tab==='exams'?'📝':tab==='questions'?'❓':tab==='monitor'?'🔴':tab==='reports'?'📈':'⚙️'}
            </div>
            <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.4rem,3vw,2rem)',fontWeight:700,marginBottom:12}}>
              {tabs.find(tb=>tb.id===tab)?.label}
            </h2>
            <p style={{color:v.textSub,fontSize:15,marginBottom:32,maxWidth:400,margin:'0 auto 32px'}}>
              {lang==='en'?'This section is fully functional. Navigate to manage.':'यह अनुभाग पूरी तरह कार्यात्मक है।'}
            </p>
            <Link href={`/admin/x7k2p/${tab==='monitor'?'monitoring':tab}`}>
              <button className="lb" style={{width:'auto',padding:'14px 32px',fontSize:15,borderRadius:12}}>
                {lang==='en'?`Open ${tabs.find(tb=>tb.id===tab)?.label} →`:`खोलें →`}
              </button>
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}
