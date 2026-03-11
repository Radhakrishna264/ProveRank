'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import PRLogo from '@/components/PRLogo'
import ParticlesBg from '@/components/ParticlesBg'
import { EN_TEXTS, HI_TEXTS } from '@/components/ThemeHelper'

const features = [
  { icon:'🧪', enTitle:'NEET Pattern',    hiTitle:'NEET पैटर्न',    enDesc:'180 questions, 720 marks, +4/-1 marking — exact NEET format.', hiDesc:'180 प्रश्न, 720 अंक, +4/-1 — बिल्कुल NEET पैटर्न।' },
  { icon:'📊', enTitle:'Live Rankings',   hiTitle:'लाइव रैंकिंग',   enDesc:'Real-time All India Rank updates as students submit exams.', hiDesc:'परीक्षा जमा होते ही वास्तविक समय में अखिल भारत रैंक।' },
  { icon:'🛡️', enTitle:'Anti-Cheat AI',   hiTitle:'एंटी-चीट AI',   enDesc:'AI-powered face detection, tab monitoring and IP locking.', hiDesc:'AI से चेहरा पहचान, टैब निगरानी और IP लॉकिंग।' },
  { icon:'📈', enTitle:'Deep Analytics',  hiTitle:'गहन विश्लेषण',  enDesc:'Chapter-wise accuracy, speed analysis and weak area detection.', hiDesc:'अध्याय-वार सटीकता, गति विश्लेषण और कमजोर क्षेत्र।' },
  { icon:'🏆', enTitle:'Leaderboard',     hiTitle:'लीडरबोर्ड',     enDesc:'Compete with 50,000+ students across India. Prove your rank.', hiDesc:'भारत भर के 50,000+ छात्रों से प्रतिस्पर्धा करें।' },
  { icon:'📱', enTitle:'Mobile Ready',    hiTitle:'मोबाइल तैयार',   enDesc:'Fully responsive — attempt exams from any device, anytime.', hiDesc:'किसी भी डिवाइस से कभी भी परीक्षा दें।' },
]

const testimonials = [
  { name:'Arjun Sharma', rank:'AIR 34', score:'692/720', quote:'ProveRank analytics helped me identify my weak chapters in Biology.', quoteHi:'ProveRank ने मेरी Biology की कमजोरियां पकड़ने में मदद की।' },
  { name:'Priya Kapoor',  rank:'AIR 112', score:'681/720', quote:'The live ranking system kept me motivated throughout preparation.', quoteHi:'लाइव रैंकिंग ने मुझे पूरी तैयारी में प्रेरित रखा।' },
  { name:'Rohit Verma',  rank:'AIR 67',  score:'688/720', quote:'Best NEET mock test platform. The anti-cheat system is very fair.', quoteHi:'सबसे अच्छा NEET मॉक टेस्ट। एंटी-चीट सिस्टम बहुत निष्पक्ष है।' },
  { name:'Sneha Patel',  rank:'AIR 201', score:'672/720', quote:'Weak area suggestions and revision AI changed my Chemistry score.', quoteHi:'कमजोर क्षेत्र सुझाव ने मेरा Chemistry स्कोर बदल दिया।' },
  { name:'Karan Singh',  rank:'AIR 89',  score:'684/720', quote:'The exam UI is exactly like real NEET. No surprises on exam day.', quoteHi:'परीक्षा UI बिल्कुल real NEET जैसा है। परीक्षा के दिन कोई आश्चर्य नहीं।' },
]

export default function LandingPage() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [scrolled, setScrolled] = useState(false)
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st = localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  },[])

  const toggleLang = () => { const n = lang==='en'?'hi':'en'; setLang(n); localStorage.setItem('pr_lang',n) }
  const toggleDark = () => { const n = !dark; setDark(n); localStorage.setItem('pr_theme',n?'dark':'light') }

  const t = lang==='en' ? EN_TEXTS : HI_TEXTS

  const bg    = dark ? '#000A18' : '#F0F7FF'
  const card  = dark ? 'rgba(0,22,40,0.7)' : 'rgba(255,255,255,0.8)'
  const bord  = dark ? 'rgba(77,159,255,0.2)' : 'rgba(77,159,255,0.3)'
  const tm    = dark ? '#E8F4FF' : '#0F172A'
  const ts    = dark ? '#6B8BAF' : '#475569'

  if (!mounted) return null

  return (
    <div style={{minHeight:'100vh',background:bg,color:tm,fontFamily:'Inter,sans-serif',transition:'background 0.4s'}}>
      <ParticlesBg />
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;800&family=Inter:wght@300;400;500;600;700;800&display=swap');
        @keyframes marquee { 0%{transform:translateX(0)} 100%{transform:translateX(-50%)} }
        @keyframes fadeUp  { from{opacity:0;transform:translateY(30px)} to{opacity:1;transform:translateY(0)} }
        @keyframes float   { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-14px)} }
        @keyframes grad    { 0%,100%{background-position:0% 50%} 50%{background-position:100% 50%} }
        .hero-title { font-family:'Playfair Display',serif; font-size:clamp(2.2rem,6vw,4rem); font-weight:800; line-height:1.1; background:linear-gradient(135deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%); background-size:300% 300%; -webkit-background-clip:text; -webkit-text-fill-color:transparent; animation:grad 6s ease infinite,fadeUp 0.8s ease forwards; }
        .feature-card:hover { transform:translateY(-6px) !important; border-color:rgba(77,159,255,0.5) !important; box-shadow:0 20px 50px rgba(77,159,255,0.15) !important; }
        .testimonial-card { flex-shrink:0; width:320px; }
        .cta-btn:hover { transform:translateY(-2px); box-shadow:0 12px 35px rgba(77,159,255,0.5) !important; }
      `}</style>

      {/* ── STICKY NAV ─────────────────────────────────────────── */}
      <nav style={{
        position:'fixed',top:0,left:0,right:0,zIndex:100,
        padding:'0 5%',height:64,display:'flex',alignItems:'center',
        justifyContent:'space-between',
        background: scrolled
          ? (dark?'rgba(0,10,24,0.92)':'rgba(248,252,255,0.92)')
          : 'transparent',
        backdropFilter: scrolled ? 'blur(20px)' : 'none',
        borderBottom: scrolled ? `1px solid ${bord}` : 'none',
        transition:'all 0.3s'
      }}>
        {/* Logo */}
        <Link href="/" style={{textDecoration:'none'}}>
          <div style={{display:'flex',alignItems:'center',gap:10}}>
            <svg width={32} height={32} viewBox="0 0 64 64">
              <defs><filter id="ng"><feGaussianBlur stdDeviation="2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
              {[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return<circle key={i} cx={32+28*Math.cos(a)} cy={32+28*Math.sin(a)} r={3} fill="#4D9FFF" filter="url(#ng)"/>})}
              <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+23*Math.cos(a)},${32+23*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2" filter="url(#ng)"/>
              <text x="32" y="38" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="16" fontWeight="700" fill="#4D9FFF" filter="url(#ng)">PR</text>
            </svg>
            <span style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#FFFFFF,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
          </div>
        </Link>
        {/* Nav Links */}
        <div style={{display:'flex',gap:8,alignItems:'center'}}>
          {[['#features',t.features],['#results',t.results]].map(([href,label])=>(
            <a key={href} href={href} style={{color:ts,textDecoration:'none',fontSize:14,fontWeight:500,padding:'6px 14px',borderRadius:8,transition:'all .2s'}}
              onMouseEnter={e=>(e.currentTarget.style.color='#4D9FFF')}
              onMouseLeave={e=>(e.currentTarget.style.color=ts)}>{label}</a>
          ))}
          <button onClick={toggleLang} className="tbtn" style={{marginLeft:4}}>{lang==='en'?'🇮🇳 हिंदी':'🌐 EN'}</button>
          <button onClick={toggleDark} className="tbtn">{dark?'☀️':'🌙'}</button>
          <Link href="/login">
            <button className="lb" style={{width:'auto',padding:'9px 22px',fontSize:14,borderRadius:10}}>
              {t.login} →
            </button>
          </Link>
        </div>
      </nav>

      {/* ── HERO ───────────────────────────────────────────────── */}
      <section style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',textAlign:'center',padding:'80px 5% 60px',position:'relative'}}>
        {/* Floating hexagons bg */}
        <div style={{position:'absolute',top:'15%',left:'8%',opacity:.06,animation:'float 7s ease-in-out infinite',fontSize:120,color:'#4D9FFF',fontFamily:'monospace'}}>⬡</div>
        <div style={{position:'absolute',bottom:'20%',right:'6%',opacity:.04,animation:'float 9s ease-in-out infinite 2s',fontSize:180,color:'#4D9FFF',fontFamily:'monospace'}}>⬡</div>
        <div style={{position:'absolute',top:'40%',right:'12%',opacity:.05,animation:'float 5s ease-in-out infinite 1s',fontSize:80,color:'#4D9FFF',fontFamily:'monospace'}}>⬡</div>

        <div style={{animation:'fadeUp 0.6s ease forwards',marginBottom:32}}>
          <PRLogo />
        </div>
        <h1 className="hero-title" style={{marginBottom:24,maxWidth:700,whiteSpace:'pre-line'}}>
          {t.heroTitle}
        </h1>
        <p style={{color:ts,fontSize:'clamp(15px,2vw,19px)',maxWidth:600,lineHeight:1.7,marginBottom:40,animation:'fadeUp 0.8s 0.2s ease forwards',opacity:0}}>
          {t.heroSub}
        </p>
        <div style={{display:'flex',gap:16,flexWrap:'wrap',justifyContent:'center',animation:'fadeUp 0.8s 0.4s ease forwards',opacity:0}}>
          <Link href="/register">
            <button className="lb cta-btn" style={{width:'auto',padding:'15px 36px',fontSize:17,borderRadius:12}}>
              {t.startFree}
            </button>
          </Link>
          <button className="tbtn" style={{padding:'14px 30px',fontSize:16,borderRadius:12}}
            onClick={()=>document.getElementById('features')?.scrollIntoView({behavior:'smooth'})}>
            {t.viewDemo}
          </button>
        </div>
        {/* Scroll arrow */}
        <div style={{marginTop:60,color:'#4D9FFF',opacity:.5,animation:'float 2s ease-in-out infinite',fontSize:24}}>↓</div>
      </section>

      {/* ── STATS BANNER ───────────────────────────────────────── */}
      <section style={{background:'linear-gradient(90deg,rgba(0,40,80,0.9),rgba(0,22,50,0.9))',borderTop:`1px solid ${bord}`,borderBottom:`1px solid ${bord}`,padding:'40px 5%'}}>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:32,maxWidth:1000,margin:'0 auto',textAlign:'center'}}>
          {[
            [t.stat1v,t.stat1l],[t.stat2v,t.stat2l],[t.stat3v,t.stat3l],[t.stat4v,t.stat4l]
          ].map(([v,l],i)=>(
            <div key={i}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(28px,5vw,42px)',fontWeight:800,color:'#4D9FFF',lineHeight:1}}>{v}</div>
              <div style={{color:ts,fontSize:14,marginTop:6,fontWeight:500}}>{l}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ── FEATURES ───────────────────────────────────────────── */}
      <section id="features" style={{padding:'80px 5%',maxWidth:1200,margin:'0 auto'}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,4vw,2.8rem)',fontWeight:700,textAlign:'center',marginBottom:12,color:tm}}>{t.featuresTitle}</h2>
        <p style={{color:ts,textAlign:'center',fontSize:16,marginBottom:56}}>
          {lang==='en' ? 'Built specifically for NEET aspirants by educators and engineers.' : 'शिक्षकों और इंजीनियरों द्वारा विशेष रूप से NEET छात्रों के लिए बनाया गया।'}
        </p>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(300px,1fr))',gap:24}}>
          {features.map((f,i)=>(
            <div key={i} className="feature-card" style={{
              background:card, border:`1px solid ${bord}`,
              borderRadius:18, padding:'32px 28px',
              transition:'all 0.3s', cursor:'default'
            }}>
              <div style={{fontSize:36,marginBottom:16}}>{f.icon}</div>
              <h3 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:tm,marginBottom:10}}>
                {lang==='en'?f.enTitle:f.hiTitle}
              </h3>
              <p style={{color:ts,fontSize:14,lineHeight:1.7}}>
                {lang==='en'?f.enDesc:f.hiDesc}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* ── TESTIMONIALS (scrolling marquee) ───────────────────── */}
      <section id="results" style={{padding:'60px 0',overflow:'hidden',borderTop:`1px solid ${bord}`}}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.6rem,3vw,2.4rem)',fontWeight:700,textAlign:'center',color:tm,marginBottom:40,padding:'0 5%'}}>
          {lang==='en' ? 'What Our Toppers Say' : 'हमारे टॉपर्स क्या कहते हैं'}
        </h2>
        <div style={{display:'flex',width:'max-content',animation:'marquee 40s linear infinite'}}>
          {[...testimonials,...testimonials].map((tm2,i)=>(
            <div key={i} className="testimonial-card" style={{
              background:card, border:`1px solid ${bord}`,
              borderRadius:16, padding:'24px', margin:'0 12px',
              width:300
            }}>
              <div style={{color:'#FFD700',fontSize:14,marginBottom:8}}>★★★★★</div>
              <p style={{color:ts,fontSize:13,lineHeight:1.6,marginBottom:16,fontStyle:'italic'}}>
                "{lang==='en'?tm2.quote:tm2.quoteHi}"
              </p>
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <div>
                  <div style={{fontWeight:600,fontSize:14,color:tm}}>{tm2.name}</div>
                  <div style={{color:'#4D9FFF',fontSize:12,fontWeight:600}}>{tm2.rank}</div>
                </div>
                <span className="badge badge-green" style={{fontSize:12}}>{tm2.score}</span>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── CTA SECTION ────────────────────────────────────────── */}
      <section style={{
        padding:'80px 5%',textAlign:'center',
        background:'linear-gradient(135deg,rgba(0,40,100,0.4),rgba(0,22,50,0.4))',
        borderTop:`1px solid ${bord}`
      }}>
        <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,4vw,2.8rem)',fontWeight:700,color:tm,marginBottom:16}}>{t.ctaLine}</h2>
        <p style={{color:ts,fontSize:16,marginBottom:36}}>
          {lang==='en'
            ? 'Join 50,000+ NEET aspirants who trust ProveRank for their preparation.'
            : '50,000+ NEET छात्रों से जुड़ें जो अपनी तैयारी के लिए ProveRank पर भरोसा करते हैं।'}
        </p>
        <Link href="/register">
          <button className="lb cta-btn" style={{width:'auto',padding:'16px 44px',fontSize:18,borderRadius:12}}>
            {t.regFree}
          </button>
        </Link>
      </section>

      {/* ── FOOTER ─────────────────────────────────────────────── */}
      <footer style={{borderTop:`1px solid ${bord}`,padding:'32px 5%',textAlign:'center',color:ts,fontSize:13}}>
        <div style={{display:'flex',justifyContent:'center',gap:10,marginBottom:12,alignItems:'center'}}>
          <svg width={24} height={24} viewBox="0 0 64 64">
            <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/>
            <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="#4D9FFF">PR</text>
          </svg>
          <span style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#4D9FFF'}}>ProveRank</span>
        </div>
        <p style={{marginBottom:8}}>{t.footer}</p>
        <p>© 2026 ProveRank. {lang==='en'?'All rights reserved.':'सर्वाधिकार सुरक्षित।'}</p>
      </footer>
    </div>
  )
}
