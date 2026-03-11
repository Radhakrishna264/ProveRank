'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import PRLogo from '@/components/PRLogo'
import ParticlesBg from '@/components/ParticlesBg'
import { EN_TEXTS, HI_TEXTS } from '@/components/ThemeHelper'

/* ─── SVG Illustrations ───────────────────────────────────────────────── */
const StudentSVG = () => (
  <svg width="180" height="180" viewBox="0 0 180 180" fill="none">
    {/* Graduation cap */}
    <ellipse cx="90" cy="68" rx="38" ry="6" fill="rgba(77,159,255,0.3)" stroke="#4D9FFF" strokeWidth="1.5"/>
    <rect x="68" y="50" width="44" height="20" rx="4" fill="rgba(77,159,255,0.15)" stroke="#4D9FFF" strokeWidth="1.5"/>
    <line x1="90" y1="62" x2="90" y2="58" stroke="#4D9FFF" strokeWidth="1.5"/>
    <polygon points="90,50 120,64 90,68 60,64" fill="rgba(77,159,255,0.4)" stroke="#4D9FFF" strokeWidth="1.5"/>
    {/* Head */}
    <circle cx="90" cy="95" r="18" fill="rgba(77,159,255,0.1)" stroke="#4D9FFF" strokeWidth="1.5"/>
    <circle cx="84" cy="93" r="2" fill="#4D9FFF"/>
    <circle cx="96" cy="93" r="2" fill="#4D9FFF"/>
    <path d="M84 101 Q90 106 96 101" stroke="#4D9FFF" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
    {/* Body */}
    <path d="M65 140 Q68 115 90 113 Q112 115 115 140" fill="rgba(77,159,255,0.08)" stroke="#4D9FFF" strokeWidth="1.5"/>
    {/* Book */}
    <rect x="100" y="118" width="22" height="16" rx="3" fill="rgba(0,196,140,0.2)" stroke="#00C48C" strokeWidth="1.5"/>
    <line x1="111" y1="118" x2="111" y2="134" stroke="#00C48C" strokeWidth="1"/>
    {/* Tassel */}
    <line x1="120" y1="64" x2="128" y2="80" stroke="#4D9FFF" strokeWidth="1.5"/>
    <circle cx="128" cy="82" r="3" fill="#4D9FFF"/>
    {/* Glow */}
    <circle cx="90" cy="90" r="80" fill="none" stroke="rgba(77,159,255,0.06)" strokeWidth="1"/>
    <circle cx="90" cy="90" r="60" fill="none" stroke="rgba(77,159,255,0.05)" strokeWidth="1"/>
  </svg>
)

const StethoscopeSVG = () => (
  <svg width="160" height="160" viewBox="0 0 160 160" fill="none">
    {/* Stethoscope tube */}
    <path d="M40 30 Q40 70 80 80 Q120 90 120 130" stroke="#4D9FFF" strokeWidth="4" fill="none" strokeLinecap="round"/>
    <path d="M60 30 Q60 70 80 80" stroke="#4D9FFF" strokeWidth="4" fill="none" strokeLinecap="round"/>
    {/* Earpieces */}
    <circle cx="40" cy="28" r="7" fill="rgba(77,159,255,0.3)" stroke="#4D9FFF" strokeWidth="2"/>
    <circle cx="60" cy="28" r="7" fill="rgba(77,159,255,0.3)" stroke="#4D9FFF" strokeWidth="2"/>
    {/* Chest piece */}
    <circle cx="120" cy="130" r="18" fill="rgba(77,159,255,0.15)" stroke="#4D9FFF" strokeWidth="2.5"/>
    <circle cx="120" cy="130" r="10" fill="rgba(77,159,255,0.3)" stroke="#4D9FFF" strokeWidth="1.5"/>
    <circle cx="120" cy="130" r="4" fill="#4D9FFF"/>
    {/* Cross (medical) */}
    <rect x="116" y="124" width="8" height="12" rx="2" fill="rgba(255,255,255,0.15)"/>
    <rect x="113" y="127" width="14" height="6" rx="2" fill="rgba(255,255,255,0.15)"/>
    {/* Glow ring */}
    <circle cx="80" cy="80" r="72" fill="none" stroke="rgba(77,159,255,0.05)" strokeWidth="2"/>
  </svg>
)

const RankSVG = () => (
  <svg width="150" height="150" viewBox="0 0 150 150" fill="none">
    {/* Trophy */}
    <path d="M45 40 Q45 90 75 95 Q105 90 105 40 Z" fill="rgba(255,215,0,0.15)" stroke="#FFD700" strokeWidth="2"/>
    <rect x="60" y="95" width="30" height="15" fill="rgba(255,215,0,0.2)" stroke="#FFD700" strokeWidth="1.5"/>
    <rect x="48" y="110" width="54" height="8" rx="4" fill="rgba(255,215,0,0.3)" stroke="#FFD700" strokeWidth="1.5"/>
    {/* Handles */}
    <path d="M45 55 Q30 55 30 70 Q30 85 45 85" fill="none" stroke="#FFD700" strokeWidth="2.5"/>
    <path d="M105 55 Q120 55 120 70 Q120 85 105 85" fill="none" stroke="#FFD700" strokeWidth="2.5"/>
    {/* Star */}
    <text x="75" y="78" textAnchor="middle" fontSize="28" fill="#FFD700" fontWeight="bold">★</text>
    {/* Rank #1 */}
    <text x="75" y="100" textAnchor="middle" fontSize="9" fill="#FFD700" fontWeight="700" letterSpacing="2">#1 RANK</text>
    {/* Glow */}
    <circle cx="75" cy="70" r="65" fill="none" stroke="rgba(255,215,0,0.06)" strokeWidth="2"/>
  </svg>
)

const features = [
  { icon:'🧪', en:'NEET Pattern Tests',    hi:'NEET पैटर्न परीक्षाएं',   desc_en:'180Q, +4/-1, exact NTA pattern with section-wise timing.',    desc_hi:'180 प्रश्न, +4/-1, NTA पैटर्न के साथ सेक्शन-वार टाइमिंग।', svg:null },
  { icon:'📊', en:'Live All India Rank',   hi:'लाइव अखिल भारत रैंक',    desc_en:'Real-time AIR updates seconds after submission.',              desc_hi:'सबमिशन के बाद सेकंड में रियल-टाइम AIR अपडेट।', svg:null },
  { icon:'🛡️', en:'AI Anti-Cheat',         hi:'AI एंटी-चीट प्रणाली',    desc_en:'Face detection, tab monitoring, IP lock — exam integrity.',   desc_hi:'चेहरा पहचान, टैब निगरानी, IP लॉक — परीक्षा की सच्चाई।', svg:null },
  { icon:'📈', en:'Deep Analytics',        hi:'गहन विश्लेषण',            desc_en:'Chapter-wise accuracy, speed & weak area AI predictions.',    desc_hi:'अध्याय-वार सटीकता, गति और कमजोर क्षेत्र AI भविष्यवाणियां।', svg:null },
  { icon:'🏆', en:'Leaderboard & Badges',  hi:'लीडरबोर्ड और बैज',       desc_en:'Compete, earn badges, share your rank with proof.',           desc_hi:'प्रतिस्पर्धा करें, बैज अर्जित करें, रैंक साझा करें।', svg:null },
  { icon:'🎓', en:'Digital Certificates',  hi:'डिजिटल प्रमाण पत्र',     desc_en:'Verified certificates for top performances, shareable.',       desc_hi:'शीर्ष प्रदर्शन के लिए सत्यापित प्रमाण पत्र, साझा करें।', svg:null },
]

export default function LandingPage() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [scrolled, setScrolled] = useState(false)
  const [mounted, setMounted] = useState(false)
  // Animated counters
  const [counts, setCounts] = useState({users:0,tests:0,rank:0,up:0})

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
    const onScroll=()=>setScrolled(window.scrollY>40)
    window.addEventListener('scroll',onScroll)
    // Count up animation
    const targets = {users:52400,tests:128000,rank:234,up:99}
    const dur = 2000; const steps = 60
    let step = 0
    const iv = setInterval(()=>{
      step++; const p = step/steps
      setCounts({users:Math.round(targets.users*p),tests:Math.round(targets.tests*p),rank:Math.round(targets.rank*p),up:Math.round(targets.up*p)})
      if(step>=steps){ clearInterval(iv); setCounts(targets) }
    },dur/steps)
    return ()=>{ window.removeEventListener('scroll',onScroll); clearInterval(iv) }
  },[])

  const toggleLang=()=>{ const n=lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark=()=>{ const n=!dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }
  const t = lang==='en' ? EN_TEXTS : HI_TEXTS

  const bg   = dark ? '#000A18' : '#F0F7FF'
  const card = dark ? 'rgba(0,18,36,0.85)' : 'rgba(255,255,255,0.88)'
  const bord = dark ? 'rgba(77,159,255,0.18)' : 'rgba(77,159,255,0.28)'
  const tm   = dark ? '#E8F4FF' : '#0F172A'
  const ts   = dark ? '#6B8BAF' : '#64748B'

  if (!mounted) return null

  return (
    <div style={{minHeight:'100vh',background:bg,color:tm,fontFamily:'Inter,sans-serif',transition:'background 0.4s'}}>
      <ParticlesBg/>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;800&family=Inter:wght@300;400;500;600;700;800&display=swap');
        @keyframes marquee{0%{transform:translateX(0)}100%{transform:translateX(-50%)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(32px)}to{opacity:1;transform:translateY(0)}}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
        @keyframes grad{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes pulse{0%,100%{opacity:.3}50%{opacity:.7}}
        .hero-title{font-family:'Playfair Display',serif;font-size:clamp(2rem,5.5vw,4rem);font-weight:800;line-height:1.1;background:linear-gradient(135deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%);background-size:300% 300%;-webkit-background-clip:text;-webkit-text-fill-color:transparent;animation:grad 6s ease infinite,fadeUp 0.8s ease forwards;}
        .feat-card:hover{transform:translateY(-7px)!important;border-color:rgba(77,159,255,0.45)!important;box-shadow:0 20px 50px rgba(77,159,255,0.12)!important;}
        .cta-btn:hover{transform:translateY(-3px);box-shadow:0 12px 35px rgba(77,159,255,0.5)!important;}
        .nav-link{color:${ts};text-decoration:none;font-size:14px;font-weight:500;padding:6px 14px;border-radius:8px;transition:all .2s;}
        .nav-link:hover{color:#4D9FFF;}
        .tbtn{padding:7px 16px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.35);background:rgba(77,159,255,0.06);color:${ts};font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;font-family:Inter,sans-serif;}
        .tbtn:hover{border-color:#4D9FFF;color:#4D9FFF;}
        .lb{padding:14px 30px;border-radius:12px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:16px;font-weight:700;cursor:pointer;transition:all 0.3s;font-family:Inter,sans-serif;box-shadow:0 4px 20px rgba(77,159,255,0.35);}
      `}</style>

      {/* ── STICKY NAV ────────────────────────────────────────── */}
      <nav style={{position:'fixed',top:0,left:0,right:0,zIndex:100,padding:'0 5%',height:64,display:'flex',alignItems:'center',justifyContent:'space-between',background:scrolled?(dark?'rgba(0,6,18,0.94)':'rgba(248,252,255,0.94)'):'transparent',backdropFilter:scrolled?'blur(20px)':'none',borderBottom:scrolled?`1px solid ${bord}`:'none',transition:'all 0.3s'}}>
        <Link href="/" style={{textDecoration:'none',display:'flex',alignItems:'center',gap:10}}>
          <svg width={30} height={30} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
          <span style={{fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
        </Link>
        <div style={{display:'flex',gap:6,alignItems:'center',flexWrap:'wrap'}}>
          <a href="#features" className="nav-link">{t.features}</a>
          <a href="#about" className="nav-link">{lang==='en'?'About':'हमारे बारे में'}</a>
          <a href="#support" className="nav-link">{lang==='en'?'Support':'सहायता'}</a>
          <button className="tbtn" onClick={toggleLang}>{lang==='en'?'🇮🇳 हिंदी':'🌐 EN'}</button>
          <button className="tbtn" onClick={toggleDark}>{dark?'☀️':'🌙'}</button>
          <Link href="/login"><button className="lb" style={{padding:'9px 22px',fontSize:14,borderRadius:10}}>{t.login} →</button></Link>
        </div>
      </nav>

      {/* ── HERO ────────────────────────────────────────────────── */}
      <section style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',textAlign:'center',padding:'100px 5% 60px',position:'relative'}}>
        {/* BG decorations */}
        <div style={{position:'absolute',top:'15%',left:'5%',opacity:.05,animation:'float 8s ease-in-out infinite',fontSize:160,color:'#4D9FFF'}}>⬡</div>
        <div style={{position:'absolute',bottom:'20%',right:'4%',opacity:.04,animation:'float 10s ease-in-out infinite 2s',fontSize:220,color:'#4D9FFF'}}>⬡</div>
        <div style={{position:'absolute',top:'45%',right:'14%',opacity:.04,animation:'float 6s ease-in-out infinite 1s',fontSize:80,color:'#4D9FFF'}}>⬡</div>

        <div style={{animation:'fadeUp 0.6s ease forwards',marginBottom:28,position:'relative',zIndex:2}}>
          <PRLogo/>
        </div>
        <h1 className="hero-title" style={{marginBottom:22,maxWidth:720,whiteSpace:'pre-line',position:'relative',zIndex:2}}>
          {t.heroTitle}
        </h1>
        <p style={{color:ts,fontSize:'clamp(15px,2vw,18px)',maxWidth:580,lineHeight:1.8,marginBottom:40,animation:'fadeUp 0.8s 0.2s ease forwards',opacity:0,position:'relative',zIndex:2}}>
          {t.heroSub}
        </p>
        <div style={{display:'flex',gap:14,flexWrap:'wrap',justifyContent:'center',animation:'fadeUp 0.8s 0.4s ease forwards',opacity:0,position:'relative',zIndex:2}}>
          <Link href="/register"><button className="lb cta-btn">{t.startFree}</button></Link>
          <button className="tbtn" style={{padding:'13px 26px',fontSize:15,borderRadius:12}} onClick={()=>document.getElementById('features')?.scrollIntoView({behavior:'smooth'})}>{t.viewDemo}</button>
        </div>

        {/* Hero Illustrations — non-clickable */}
        <div style={{display:'flex',gap:48,justifyContent:'center',flexWrap:'wrap',marginTop:60,position:'relative',zIndex:1}}>
          <div style={{animation:'float 7s ease-in-out infinite',opacity:.7,pointerEvents:'none',userSelect:'none'}}>
            <StudentSVG/>
          </div>
          <div style={{animation:'float 9s ease-in-out infinite 1.5s',opacity:.7,pointerEvents:'none',userSelect:'none'}}>
            <StethoscopeSVG/>
          </div>
          <div style={{animation:'float 6s ease-in-out infinite 0.8s',opacity:.7,pointerEvents:'none',userSelect:'none'}}>
            <RankSVG/>
          </div>
        </div>
        <div style={{marginTop:32,color:'#4D9FFF',opacity:.4,animation:'float 2s ease-in-out infinite',fontSize:22,position:'relative',zIndex:2}}>↓</div>
      </section>

      {/* ── ANIMATED STATS BANNER ───────────────────────────────── */}
      <section style={{background:'linear-gradient(90deg,rgba(0,30,70,0.95),rgba(0,18,45,0.95))',borderTop:`1px solid ${bord}`,borderBottom:`1px solid ${bord}`,padding:'44px 5%'}}>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(180px,1fr))',gap:32,maxWidth:1000,margin:'0 auto',textAlign:'center'}}>
          {[
            {val:`${(counts.users/1000).toFixed(1)}K+`, label:lang==='en'?'Registered Students':'पंजीकृत छात्र', icon:'👨‍🎓', color:'#4D9FFF'},
            {val:`${(counts.tests/1000).toFixed(0)}K+`, label:lang==='en'?'Tests Completed':'परीक्षाएं दी गईं', icon:'📝', color:'#00C48C'},
            {val:`#${counts.rank}`,                      label:lang==='en'?'Best AIR Achieved':'सर्वश्रेष्ठ AIR',   icon:'🏆', color:'#FFD700'},
            {val:`${counts.up}%`,                        label:lang==='en'?'Uptime Guarantee':'अपटाइम गारंटी',    icon:'⚡', color:'#A855F7'},
          ].map((s,i)=>(
            <div key={i}>
              <div style={{fontSize:28,marginBottom:6}}>{s.icon}</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(2rem,5vw,3rem)',fontWeight:800,color:s.color,lineHeight:1}}>{s.val}</div>
              <div style={{color:ts,fontSize:13,marginTop:6,fontWeight:500}}>{s.label}</div>
            </div>
          ))}
        </div>
        <div style={{textAlign:'center',marginTop:20,fontSize:11,color:'rgba(77,159,255,0.4)',letterSpacing:'0.1em',textTransform:'uppercase'}}>
          {lang==='en'?'* Stats updated in real-time by SuperAdmin':'* आंकड़े SuperAdmin द्वारा रियल-टाइम में अपडेट किए जाते हैं'}
        </div>
      </section>

      {/* ── FEATURES WITH ILLUSTRATIONS ────────────────────────── */}
      <section id="features" style={{padding:'80px 5%',maxWidth:1200,margin:'0 auto'}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,4vw,2.8rem)',fontWeight:800,textAlign:'center',marginBottom:10,color:tm}}>
          {t.featuresTitle}
        </h2>
        <p style={{color:ts,textAlign:'center',fontSize:15,marginBottom:60,maxWidth:500,margin:'0 auto 60px'}}>
          {lang==='en'?'Everything you need to crack NEET — all in one platform.':'NEET क्रैक करने के लिए सब कुछ — एक प्लेटफॉर्म में।'}
        </p>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:22}}>
          {features.map((f,i)=>(
            <div key={i} className="feat-card" style={{background:card,border:`1px solid ${bord}`,borderRadius:18,padding:'28px 24px',transition:'all 0.3s',cursor:'default',pointerEvents:'none'}}>
              <div style={{fontSize:38,marginBottom:14}}>{f.icon}</div>
              <h3 style={{fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:700,color:tm,marginBottom:8}}>
                {lang==='en'?f.en:f.hi}
              </h3>
              <p style={{color:ts,fontSize:13,lineHeight:1.8}}>
                {lang==='en'?f.desc_en:f.desc_hi}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* ── ABOUT / HOW IT WORKS ────────────────────────────────── */}
      <section id="about" style={{padding:'70px 5%',borderTop:`1px solid ${bord}`}}>
        <div style={{maxWidth:1100,margin:'0 auto',display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:48,alignItems:'center'}}>
          <div>
            <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.6rem,3.5vw,2.4rem)',fontWeight:800,marginBottom:16,color:tm}}>
              {lang==='en'?'How ProveRank Works':'ProveRank कैसे काम करता है'}
            </h2>
            <p style={{color:ts,fontSize:15,lineHeight:1.9,marginBottom:24}}>
              {lang==='en'
                ? 'ProveRank simulates the real NEET exam environment — from the exam UI to the grading system. Students compete against each other in a fair, AI-monitored environment.'
                : 'ProveRank असली NEET परीक्षा वातावरण का अनुकरण करता है — परीक्षा UI से ग्रेडिंग सिस्टम तक। छात्र एक निष्पक्ष, AI-निगरानी वाले वातावरण में प्रतिस्पर्धा करते हैं।'}
            </p>
            {[
              [lang==='en'?'Register & Set Up Profile':'पंजीकरण और प्रोफाइल सेटअप', '1'],
              [lang==='en'?'Attempt NEET Pattern Tests':'NEET पैटर्न परीक्षा दें', '2'],
              [lang==='en'?'Get Instant AIR & Analysis':'तुरंत AIR और विश्लेषण प्राप्त करें', '3'],
              [lang==='en'?'Improve with AI Suggestions':'AI सुझावों से सुधार करें', '4'],
            ].map(([step,num])=>(
              <div key={num} style={{display:'flex',gap:14,alignItems:'flex-start',marginBottom:14}}>
                <div style={{width:32,height:32,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,fontSize:13,color:'#fff',flexShrink:0}}>{num}</div>
                <div style={{color:ts,fontSize:14,lineHeight:1.6,paddingTop:5}}>{step}</div>
              </div>
            ))}
          </div>
          <div style={{display:'flex',flexDirection:'column',gap:16}}>
            {/* Fake exam screenshot card */}
            <div style={{background:card,border:`1px solid ${bord}`,borderRadius:18,padding:20,pointerEvents:'none',userSelect:'none'}}>
              <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:14}}>
                <div style={{width:8,height:8,borderRadius:'50%',background:'#FF4757'}}/>
                <div style={{width:8,height:8,borderRadius:'50%',background:'#FFA502'}}/>
                <div style={{width:8,height:8,borderRadius:'50%',background:'#00C48C'}}/>
                <div style={{flex:1,height:1,background:bord}}/>
                <span style={{fontSize:10,color:ts,fontFamily:'monospace'}}>⏱ 2:58:44</span>
              </div>
              <div style={{background:`rgba(77,159,255,0.06)`,borderRadius:10,padding:'12px',marginBottom:10,fontSize:12,color:tm,lineHeight:1.7}}>
                Q14. Which of the following is the correct sequence in the lytic cycle of bacteriophage?
              </div>
              {['A. Attachment → Replication → Lysis','B. Lysis → Assembly → Attachment','C. Replication → Lysis → Entry','D. Entry → Assembly → Replication'].map((opt,i)=>(
                <div key={i} style={{display:'flex',alignItems:'center',gap:10,padding:'8px 12px',borderRadius:8,marginBottom:6,border:`1px solid ${i===0?'#4D9FFF':bord}`,background:i===0?'rgba(77,159,255,0.1)':'transparent'}}>
                  <div style={{width:22,height:22,borderRadius:'50%',border:`1.5px solid ${i===0?'#4D9FFF':bord}`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:i===0?'#fff':'#6B8BAF',background:i===0?'#4D9FFF':'transparent',flexShrink:0}}>{'ABCD'[i]}</div>
                  <span style={{fontSize:11,color:i===0?tm:ts}}>{opt.slice(3)}</span>
                </div>
              ))}
            </div>
            {/* Rank card */}
            <div style={{background:'linear-gradient(135deg,rgba(0,50,120,0.5),rgba(0,30,70,0.5))',border:`1px solid rgba(77,159,255,0.3)`,borderRadius:14,padding:'14px 18px',display:'flex',justifyContent:'space-between',alignItems:'center',pointerEvents:'none',userSelect:'none'}}>
              <div>
                <div style={{fontSize:11,color:ts,fontWeight:600,letterSpacing:'0.06em',textTransform:'uppercase',marginBottom:4}}>All India Rank</div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:36,fontWeight:800,color:'#4D9FFF',lineHeight:1}}>#234</div>
              </div>
              <div style={{textAlign:'right'}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#FFD700'}}>632</div>
                <div style={{color:ts,fontSize:11}}>/ 720 • 97.3%ile</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── TESTIMONIALS MARQUEE ─────────────────────────────────── */}
      <section style={{padding:'60px 0',overflow:'hidden',borderTop:`1px solid ${bord}`}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.5rem,3vw,2.2rem)',fontWeight:800,textAlign:'center',color:tm,marginBottom:40,padding:'0 5%'}}>
          {lang==='en'?'What Our Toppers Say':'हमारे टॉपर्स क्या कहते हैं'}
        </h2>
        <div style={{display:'flex',width:'max-content',animation:'marquee 45s linear infinite'}}>
          {[...Array(2)].flatMap(()=>[
            {n:'Arjun Sharma',r:'AIR 34',s:'692/720',q_en:"ProveRank's analytics identified my weak chapters in days.",q_hi:"ProveRank ने दिनों में मेरी कमजोरियां पकड़ीं।"},
            {n:'Priya Kapoor', r:'AIR 112',s:'681/720',q_en:"The live ranking system kept me consistently motivated.",q_hi:"लाइव रैंकिंग ने मुझे हमेशा प्रेरित रखा।"},
            {n:'Rohit Verma',  r:'AIR 67', s:'688/720',q_en:"Best NEET mock platform. Feels exactly like real exam.",q_hi:"सबसे अच्छा NEET मॉक। बिल्कुल असली परीक्षा जैसा।"},
            {n:'Sneha Patel',  r:'AIR 201',s:'672/720',q_en:"AI weak area suggestions changed my Chemistry score.",q_hi:"AI सुझावों ने मेरा Chemistry बदल दिया।"},
          ]).map((tm2,i)=>(
            <div key={i} style={{background:card,border:`1px solid ${bord}`,borderRadius:16,padding:'20px',margin:'0 10px',width:280,flexShrink:0}}>
              <div style={{color:'#FFD700',marginBottom:8,fontSize:13}}>★★★★★</div>
              <p style={{color:ts,fontSize:13,lineHeight:1.6,fontStyle:'italic',marginBottom:14}}>"{lang==='en'?tm2.q_en:tm2.q_hi}"</p>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <div>
                  <div style={{fontWeight:700,fontSize:13,color:tm}}>{tm2.n}</div>
                  <div style={{color:'#4D9FFF',fontSize:11,fontWeight:700}}>{tm2.r}</div>
                </div>
                <span style={{background:'rgba(0,196,140,0.12)',color:'#00C48C',padding:'3px 10px',borderRadius:99,fontSize:11,fontWeight:700}}>{tm2.s}</span>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── SUPPORT CTA ─────────────────────────────────────────── */}
      <section id="support" style={{padding:'60px 5%',borderTop:`1px solid ${bord}`,textAlign:'center'}}>
        <div style={{maxWidth:600,margin:'0 auto'}}>
          <div style={{fontSize:36,marginBottom:12}}>💬</div>
          <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.4rem,3vw,2rem)',fontWeight:800,color:tm,marginBottom:10}}>
            {lang==='en'?'Need Help?':'सहायता चाहिए?'}
          </h2>
          <p style={{color:ts,fontSize:14,lineHeight:1.7,marginBottom:24}}>
            {lang==='en'
              ? `Reach us at Praveenkumar100806@gmail.com or use the support portal for quick help.`
              : `हमें Praveenkumar100806@gmail.com पर पहुंचें या त्वरित सहायता के लिए पोर्टल का उपयोग करें।`}
          </p>
          <Link href="/support"><button className="lb">{lang==='en'?'Visit Support Portal →':'सहायता पोर्टल →'}</button></Link>
        </div>
      </section>

      {/* ── FINAL CTA ───────────────────────────────────────────── */}
      <section style={{padding:'80px 5%',textAlign:'center',background:`linear-gradient(135deg,rgba(0,40,100,0.35),rgba(0,22,50,0.35))`,borderTop:`1px solid ${bord}`}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,4vw,2.8rem)',fontWeight:800,color:tm,marginBottom:12}}>{t.ctaLine}</h2>
        <p style={{color:ts,fontSize:15,marginBottom:36}}>
          {lang==='en'?'Join 52,000+ NEET aspirants who trust ProveRank.':'52,000+ NEET छात्रों से जुड़ें जो ProveRank पर भरोसा करते हैं।'}
        </p>
        <Link href="/register"><button className="lb cta-btn" style={{fontSize:17,padding:'16px 44px',borderRadius:14}}>{t.regFree}</button></Link>
      </section>

      {/* ── PREMIUM FOOTER ──────────────────────────────────────── */}
      <footer style={{borderTop:`1px solid ${bord}`,background:dark?'rgba(0,4,12,0.98)':'rgba(248,252,255,0.98)',padding:'48px 5% 28px'}}>
        <div style={{maxWidth:1100,margin:'0 auto'}}>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:36,marginBottom:40}}>
            {/* Brand */}
            <div>
              <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:14}}>
                <svg width={32} height={32} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
                <span style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
              </div>
              <p style={{color:ts,fontSize:13,lineHeight:1.8,marginBottom:14}}>
                {lang==='en'
                  ? "India's most advanced NEET test platform. Real rankings, real results."
                  : 'भारत का सबसे उन्नत NEET परीक्षा मंच। वास्तविक रैंकिंग, वास्तविक परिणाम।'}
              </p>
              <div style={{display:'flex',gap:8}}>
                <button className="tbtn" onClick={toggleLang} style={{fontSize:12}}>{lang==='en'?'🇮🇳 हिंदी':'🌐 EN'}</button>
                <button className="tbtn" onClick={toggleDark} style={{fontSize:12}}>{dark?'☀️':'🌙'}</button>
              </div>
            </div>
            {/* Links */}
            <div>
              <div style={{fontSize:12,fontWeight:700,color:'#4D9FFF',letterSpacing:'0.1em',textTransform:'uppercase',marginBottom:14}}>{lang==='en'?'Platform':'प्लेटफॉर्म'}</div>
              {[[lang==='en'?'Login':'लॉगिन','/login'],[lang==='en'?'Register':'पंजीकरण','/register'],[lang==='en'?'Terms':'नियम','/terms'],[lang==='en'?'Support':'सहायता','/support']].map(([label,href])=>(
                <Link key={href} href={href} style={{display:'block',color:ts,textDecoration:'none',fontSize:13,marginBottom:8,transition:'color 0.2s'}}
                  onMouseEnter={e=>(e.currentTarget.style.color='#4D9FFF')}
                  onMouseLeave={e=>(e.currentTarget.style.color=ts)}>{label}</Link>
              ))}
            </div>
            {/* Creator */}
            <div>
              <div style={{fontSize:12,fontWeight:700,color:'#4D9FFF',letterSpacing:'0.1em',textTransform:'uppercase',marginBottom:14}}>{lang==='en'?'Creator':'निर्माता'}</div>
              <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:14}}>
                <div style={{width:44,height:44,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#A855F7)',display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,color:'#fff',flexShrink:0}}>P</div>
                <div>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:800,color:tm}}>Praveen Rajput</div>
                  <div style={{color:ts,fontSize:12}}>{lang==='en'?'Founder & Developer':'संस्थापक और डेवलपर'}</div>
                </div>
              </div>
              <a href="mailto:Praveenkumar100806@gmail.com" style={{color:'#4D9FFF',fontSize:12,textDecoration:'none',fontWeight:500,display:'block',marginBottom:6}}>
                📧 Praveenkumar100806@gmail.com
              </a>
              <div style={{color:ts,fontSize:12}}>{lang==='en'?'ProveRank — Empowering NEET aspirants':'ProveRank — NEET छात्रों को सशक्त बनाना'}</div>
            </div>
          </div>

          {/* Divider */}
          <div style={{borderTop:`1px solid ${bord}`,paddingTop:20,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:12}}>
            <div style={{color:ts,fontSize:12}}>
              © 2026 ProveRank. {lang==='en'?'Crafted with ❤️ by':'❤️ के साथ बनाया गया'}{' '}
              <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,color:'#4D9FFF'}}>Praveen Rajput</span>.{' '}
              {lang==='en'?'All rights reserved.':'सर्वाधिकार सुरक्षित।'}
            </div>
            <div style={{display:'flex',gap:6,alignItems:'center'}}>
              <span style={{fontSize:11,color:ts,letterSpacing:'0.08em'}}>NEET</span>
              <span style={{color:bord}}>·</span>
              <span style={{fontSize:11,color:ts,letterSpacing:'0.08em'}}>NEET PG</span>
              <span style={{color:bord}}>·</span>
              <span style={{fontSize:11,color:ts,letterSpacing:'0.08em'}}>JEE</span>
              <span style={{color:bord}}>·</span>
              <span style={{fontSize:11,color:ts,letterSpacing:'0.08em'}}>CUET</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
