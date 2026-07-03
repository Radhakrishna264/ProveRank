'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── 36.4 — Per-step color theme ──────────────────────────────
const STEP_COLORS = [
  { pri:'#4D9FFF', sec:'#0055CC', grd:'linear-gradient(135deg,#4D9FFF,#0055CC)' }, // blue — Welcome
  { pri:'#7B4DFF', sec:'#4B0082', grd:'linear-gradient(135deg,#7B4DFF,#4B0082)' }, // purple — Mock Tests
  { pri:'#00C48C', sec:'#007755', grd:'linear-gradient(135deg,#00C48C,#007755)' }, // green — Analytics
  { pri:'#FFD700', sec:'#FF8C00', grd:'linear-gradient(135deg,#FFD700,#FF8C00)' }, // gold — Rankings
  { pri:'#FF6B9D', sec:'#CC3366', grd:'linear-gradient(135deg,#FF6B9D,#CC3366)' }, // pink — Smart Rev
  { pri:'#00C48C', sec:'#007755', grd:'linear-gradient(135deg,#00C48C,#4D9FFF)' }, // green — All Set
]

// ── 36.3 — Per-step SVG animations ───────────────────────────
function StepSVG({ step }: { step: number }) {
  const s = { animation:'float 3s ease-in-out infinite', display:'block', margin:'0 auto' }
  if (step===0) return ( // Rocket
    <svg style={s} width="90" height="90" viewBox="0 0 90 90">
      <defs><linearGradient id="rg" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#4D9FFF"/><stop offset="100%" stopColor="#7B4DFF"/></linearGradient></defs>
      <ellipse cx="45" cy="35" rx="18" ry="28" fill="url(#rg)" opacity=".9"/>
      <polygon points="45,5 57,35 33,35" fill="#00D4FF" opacity=".85"/>
      <polygon points="30,55 22,72 38,62" fill="#FF6B9D" opacity=".8"/>
      <polygon points="60,55 68,72 52,62" fill="#FF6B9D" opacity=".8"/>
      <circle cx="45" cy="38" r="7" fill="#fff" opacity=".25"/>
      <ellipse cx="45" cy="70" rx="8" ry="14" fill="#FF8C00" opacity=".6"/>
      <ellipse cx="45" cy="75" rx="5" ry="9" fill="#FFD700" opacity=".8"/>
    </svg>
  )
  if (step===1) return ( // Checklist
    <svg style={s} width="90" height="90" viewBox="0 0 90 90">
      <rect x="15" y="10" width="60" height="70" rx="8" fill="rgba(123,77,255,0.15)" stroke="#7B4DFF" strokeWidth="1.5"/>
      <line x1="28" y1="30" x2="62" y2="30" stroke="#7B4DFF" strokeWidth="2" opacity=".7"/>
      <line x1="28" y1="45" x2="62" y2="45" stroke="#7B4DFF" strokeWidth="2" opacity=".7"/>
      <line x1="28" y1="60" x2="50" y2="60" stroke="#7B4DFF" strokeWidth="2" opacity=".7"/>
      <polyline points="20,30 24,34 32,26" fill="none" stroke="#00C48C" strokeWidth="2.5" strokeLinecap="round"/>
      <polyline points="20,45 24,49 32,41" fill="none" stroke="#00C48C" strokeWidth="2.5" strokeLinecap="round"/>
      <circle cx="23" cy="60" r="4" fill="none" stroke="#7B4DFF" strokeWidth="1.5"/>
    </svg>
  )
  if (step===2) return ( // Bar Chart
    <svg style={s} width="90" height="90" viewBox="0 0 90 90">
      <defs><linearGradient id="bg1" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#00C48C"/><stop offset="100%" stopColor="#007755"/></linearGradient></defs>
      <rect x="12" y="50" width="14" height="30" rx="3" fill="url(#bg1)" opacity=".8"/>
      <rect x="32" y="30" width="14" height="50" rx="3" fill="url(#bg1)"/>
      <rect x="52" y="15" width="14" height="65" rx="3" fill="url(#bg1)"/>
      <rect x="72" y="38" width="8"  height="42" rx="3" fill="url(#bg1)" opacity=".7"/>
      <polyline points="12,48 32,28 52,13 72,36" fill="none" stroke="#4D9FFF" strokeWidth="2" strokeDasharray="4 2"/>
      <circle cx="52" cy="13" r="4" fill="#FFD700"/>
    </svg>
  )
  if (step===3) return ( // Trophy
    <svg style={s} width="90" height="90" viewBox="0 0 90 90">
      <defs><linearGradient id="tg" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#FFD700"/><stop offset="100%" stopColor="#FF8C00"/></linearGradient></defs>
      <path d="M25 15 h40 v30 a20 20 0 0 1 -40 0 Z" fill="url(#tg)"/>
      <rect x="38" y="55" width="14" height="16" rx="2" fill="#FF8C00"/>
      <rect x="28" y="71" width="34" height="8" rx="4" fill="url(#tg)"/>
      <path d="M25 20 Q8 20 8 38 Q8 52 25 45" fill="none" stroke="#FFD700" strokeWidth="3"/>
      <path d="M65 20 Q82 20 82 38 Q82 52 65 45" fill="none" stroke="#FFD700" strokeWidth="3"/>
      <circle cx="45" cy="32" r="8" fill="rgba(255,255,255,0.3)"/>
      <text x="45" y="37" textAnchor="middle" fontSize="10" fill="#fff" fontWeight="900">1</text>
    </svg>
  )
  if (step===4) return ( // Neural Network
    <svg style={s} width="90" height="90" viewBox="0 0 90 90">
      {[[15,20],[15,45],[15,70]].map(([x,y],i)=><circle key={'l'+i} cx={x} cy={y} r="7" fill="none" stroke="#FF6B9D" strokeWidth="2"/>)}
      {[[45,15],[45,38],[45,60],[45,78]].map(([x,y],i)=><circle key={'m'+i} cx={x} cy={y} r="7" fill="none" stroke="#7B4DFF" strokeWidth="2"/>)}
      {[[75,25],[75,65]].map(([x,y],i)=><circle key={'r'+i} cx={x} cy={y} r="7" fill="none" stroke="#4D9FFF" strokeWidth="2"/>)}
      {[[15,20],[45,15],[15,20],[45,38],[15,45],[45,38],[15,45],[45,60],[15,70],[45,60],[15,70],[45,78]].reduce((acc,_,i,arr)=>i%2===0?[...acc,[arr[i],arr[i+1]]]:acc,[]).map(([a,b]:any,i)=>
        <line key={'c'+i} x1={a[0]} y1={a[1]} x2={b[0]} y2={b[1]} stroke="rgba(255,107,157,0.3)" strokeWidth="1"/>
      )}
      {[[45,15],[75,25],[45,38],[75,25],[45,38],[75,65],[45,60],[75,65],[45,78],[75,65]].reduce((acc,_,i,arr)=>i%2===0?[...acc,[arr[i],arr[i+1]]]:acc,[]).map(([a,b]:any,i)=>
        <line key={'r'+i} x1={a[0]} y1={a[1]} x2={b[0]} y2={b[1]} stroke="rgba(77,159,255,0.3)" strokeWidth="1"/>
      )}
    </svg>
  )
  // step 5 — Checkmark
  return (
    <svg style={s} width="90" height="90" viewBox="0 0 90 90">
      <circle cx="45" cy="45" r="38" fill="none" stroke="#00C48C" strokeWidth="3" opacity=".5"/>
      <circle cx="45" cy="45" r="30" fill="rgba(0,196,140,0.15)" stroke="#00C48C" strokeWidth="2"/>
      <polyline points="28,45 40,57 62,33" fill="none" stroke="#00C48C" strokeWidth="4.5" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  )
}

// ── 36.18 — Mini mock question for Step 2 ────────────────────
function MiniMock({ lang }: { lang: 'en'|'hi' }) {
  const [sel, setSel] = useState<number|null>(null)
  const q = lang==='en' ? 'Which organelle is called the powerhouse of the cell?' : 'कोशिका का पावरहाउस किसे कहते हैं?'
  const opts = lang==='en'
    ? ['Nucleus','Mitochondria','Ribosome','Golgi Body']
    : ['केंद्रक','माइटोकॉन्ड्रिया','राइबोसोम','गॉल्जी बॉडी']
  return (
    <div style={{marginTop:14,background:'rgba(123,77,255,0.08)',borderRadius:12,padding:'14px 16px',border:'1px solid rgba(123,77,255,0.2)'}}>
      <div style={{fontSize:11,color:'#7B4DFF',fontWeight:700,marginBottom:8,textTransform:'uppercase',letterSpacing:.5}}>
        {lang==='en' ? '🧠 Try a Sample Question' : '🧠 एक सैंपल प्रश्न आज़माएं'}
      </div>
      <div style={{fontSize:13,color:'#CCFBF1',marginBottom:10,lineHeight:1.5}}>{q}</div>
      {opts.map((o,i) => (
        <button key={i} onClick={()=>setSel(i)}
          style={{display:'block',width:'100%',textAlign:'left',padding:'8px 12px',marginBottom:6,borderRadius:8,border:`1px solid ${sel===i?(i===1?'#00C48C':'#FF4D4D'):' rgba(255,255,255,0.1)'}`,background:sel===i?(i===1?'rgba(0,196,140,0.15)':'rgba(255,77,77,0.1)'):'transparent',color:sel===i?(i===1?'#00C48C':'#FF4D4D'):'#CCFBF1',cursor:'pointer',fontSize:12,transition:'all .2s'}}>
          {String.fromCharCode(65+i)}. {o} {sel===i&&(i===1?'✅':'❌')}
        </button>
      ))}
      {sel!==null&&<div style={{fontSize:11,color:sel===1?'#00C48C':'#5EEAD4',marginTop:6,textAlign:'center'}}>{sel===1?(lang==='en'?'Correct! 🎉':'सही! 🎉'):(lang==='en'?'Mitochondria is correct!':'माइटोकॉन्ड्रिया सही उत्तर है!')}</div>}
    </div>
  )
}

// ── 36.21 — Confetti ─────────────────────────────────────────
function Confetti() {
  const colors = ['#4D9FFF','#00C48C','#FFD700','#FF6B9D','#7B4DFF','#00D4FF']
  return (
    <div style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:999,overflow:'hidden'}}>
      {Array.from({length:60}).map((_,i)=>(
        <div key={i} style={{
          position:'absolute', top:'-10px',
          left:`${Math.random()*100}%`,
          width: i%3===0?8:5, height: i%3===0?8:5,
          borderRadius: i%2===0?'50%':2,
          background: colors[i%colors.length],
          animation:`confettiFall ${1.2+Math.random()*1.5}s ease-in forwards`,
          animationDelay:`${Math.random()*0.6}s`
        }}/>
      ))}
      <style>{`@keyframes confettiFall{from{transform:translateY(-10px) rotate(0deg);opacity:1}to{transform:translateY(100vh) rotate(720deg);opacity:0}}`}</style>
    </div>
  )
}

// ════════════════════════════════════════════════════════════════
//  MAIN COMPONENT
// ════════════════════════════════════════════════════════════════
export default function OnboardingPage() {
  const router  = useRouter()
  const [step, setStep]         = useState(0)
  const [lang, setLang]         = useState<'en'|'hi'>('en')
  const [dir,  setDir]          = useState<'left'|'right'>('left')
  const [anim, setAnim]         = useState(false)
  const [done, setDone]         = useState(false)
  const [showBanner, setShowBanner] = useState(false)
  const [userName, setUserName] = useState('')
  const [showWhatsApp, setShowWhatsApp] = useState(false)
  const token = useRef('')

  const TOTAL = 6

  // ── 36.12 — Auth check ────────────────────────────────────
  useEffect(() => {
    try {
      const tk = localStorage.getItem('pr_token')
      const role = localStorage.getItem('pr_role')
      if (!tk) { router.replace('/login'); return }
      if (role === 'admin' || role === 'superadmin') { router.replace('/admin/x7k2p'); return }
      token.current = tk
      // Already onboarded → skip to dashboard
      if (localStorage.getItem('pr_onboarded') === '1') { router.replace('/dashboard'); return }
      const n = localStorage.getItem('pr_name') || ''
      setUserName(n)
      const l = localStorage.getItem('pr_lang') as 'en'|'hi' | null
      if (l) setLang(l)
    } catch {}
  }, [router])

  // ── Step content (36.1, 36.5) ────────────────────────────
  const STEPS = [
    {
      en: { h: `Welcome to ProveRank${userName ? ', '+userName : ''}! 🚀`, b: 'Your exam preparation journey starts here. Whether it\'s NEET, IIT-JEE, CUET, SSC, RPSC or DSSSB — we\'ll help you succeed with smart tools, AI analytics, and curated content.' },
      hi: { h: `ProveRank में आपका स्वागत है${userName ? ', '+userName : ''}! 🚀`, b: 'आपकी परीक्षा तैयारी की यात्रा यहाँ से शुरू होती है। NEET, IIT-JEE, CUET, SSC, RPSC या DSSSB — हम आपको सफलता दिलाएंगे।' }
    },
    {
      en: { h: '📝 Full Mock Tests', b: 'Attempt full-length & chapter-wise mock tests tailored to your exam — NEET, JEE, CUET, SSC, and more. Track your progress and improve with every attempt.' },
      hi: { h: '📝 मॉक टेस्ट', b: 'NEET, JEE, CUET, SSC जैसे परीक्षाओं के लिए फुल-लेंथ और चैप्टर-वाइज मॉक टेस्ट दें। हर प्रयास से बेहतर बनें।' }
    },
    {
      en: { h: '📊 AI-Powered Analytics', b: 'Get deep insights into your performance — subject-wise accuracy, time spent per question, weak topics, and personalized study suggestions.' },
      hi: { h: '📊 AI एनालिटिक्स', b: 'अपने प्रदर्शन की गहरी जानकारी पाएं — विषयवार सटीकता, कमज़ोर टॉपिक्स और व्यक्तिगत अध्ययन सुझाव।' }
    },
    {
      en: { h: '🏆 Rankings & Leaderboard', b: 'See where you rank among thousands of competitive exam aspirants. Batch rankings, national rankings, and exam-wise standings — compete and rise to the top!' },
      hi: { h: '🏆 रैंकिंग और लीडरबोर्ड', b: 'हजारों प्रतियोगी परीक्षा aspirants में अपनी रैंक देखें। बैच रैंकिंग, नेशनल रैंकिंग — प्रतिस्पर्धा करें और शीर्ष पर पहुंचें!' }
    },
    {
      en: { h: '🧠 Smart Revision System', b: 'Our AI identifies your weak areas and creates a personalized revision plan. Spaced repetition ensures you remember what you study.' },
      hi: { h: '🧠 स्मार्ट रिवीजन', b: 'हमारा AI आपके कमज़ोर क्षेत्रों को पहचानता है और व्यक्तिगत रिवीजन प्लान बनाता है। स्पेस्ड रिपीटिशन से आप जो पढ़ते हैं वो याद रहता है।' }
    },
    {
      en: { h: "🎉 You're All Set!", b: 'Your ProveRank journey begins now! Your account is ready, your first mock test awaits, and the leaderboard is waiting for you. Rise to the Top! 🚀' },
      hi: { h: '🎉 आप तैयार हैं!', b: 'आपकी ProveRank यात्रा अब शुरू होती है! आपका पहला मॉक टेस्ट इंतज़ार कर रहा है। Rise to the Top! 🚀' }
    },
  ]

  const sc  = STEP_COLORS[step]
  const cur = STEPS[step][lang]
  const pct = Math.round(((step+1)/TOTAL)*100)

  // ── Navigate steps (36.23 — slide animation) ─────────────
  const goNext = useCallback(() => {
    if (step < TOTAL-1) {
      setDir('left'); setAnim(true)
      setTimeout(() => { setStep(s => s+1); setAnim(false) }, 280)
    }
  }, [step])

  const goBack = useCallback(() => {
    if (step > 0) {
      setDir('right'); setAnim(true)
      setTimeout(() => { setStep(s => s-1); setAnim(false) }, 280)
    }
  }, [step])

  // ── Complete / Skip (36.10, 36.11, 36.17) ────────────────
  const complete = async (skip=false) => {
    try { localStorage.setItem('pr_onboarded', '1') } catch {}
    // API call to mark onboarded + give badge
    try {
      await fetch(`${API}/api/auth/complete-onboarding`, {
        method:'POST', headers:{ Authorization:`Bearer ${token.current}` }
      })
    } catch {}
    if (!skip) setDone(true)  // confetti
    // Show welcome banner (36.8, 36.9)
    setShowBanner(true)
    setTimeout(() => {
      setShowBanner(false)
      router.replace('/dashboard')
    }, skip ? 1800 : 3200)
  }

  // ── Dark/light mode support (36.19) ──────────────────────
  const [isDark] = useState(true) // reads pr_color_theme but onboarding always dark teal
  const bg = 'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)'
  const cardBg = 'rgba(0,35,30,0.88)'
  const TXT = '#CCFBF1', SUB = '#5EEAD4'

  return (
    <div style={{minHeight:'100vh',background:bg,fontFamily:'Inter,sans-serif',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:'20px',overflowX:'hidden'}}>

      {/* ── Animations CSS ────────────────────────────────── */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;600;700&display=swap');
        *{box-sizing:border-box}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-14px)}}
        @keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        @keyframes fadeIn{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:1}50%{opacity:.6}}
        @keyframes shimmer{0%{background-position:-200% 0}100%{background-position:200% 0}}
        @keyframes slideLeft{from{opacity:0;transform:translateX(40px)}to{opacity:1;transform:translateX(0)}}
        @keyframes slideRight{from{opacity:0;transform:translateX(-40px)}to{opacity:1;transform:translateX(0)}}
        @keyframes glowBlue{0%,100%{filter:drop-shadow(0 0 6px #2DD4BF66)}50%{filter:drop-shadow(0 0 20px #2DD4BFaa)}}
        @keyframes progressShimmer{0%{opacity:.7}100%{opacity:1}}
        @keyframes bannerIn{from{opacity:0;transform:translateY(-30px)}to{opacity:1;transform:translateY(0)}}
        @keyframes ringRotate{from{stroke-dashoffset:220}to{stroke-dashoffset:0}}
      `}</style>

      {/* ── 36.21 — Confetti on last step ────────────────── */}
      {done && <Confetti/>}

      {/* ── 36.8/36.9 — Welcome Banner (after complete/skip) */}
      {showBanner && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',animation:'fadeIn .4s ease'}}>
          <div style={{background:cardBg,border:'1px solid rgba(45,212,191,0.4)',borderRadius:20,padding:'40px 32px',textAlign:'center',maxWidth:380,boxShadow:'0 0 60px rgba(45,212,191,0.2)',animation:'bannerIn .5s ease'}}>
            <div style={{fontSize:56,marginBottom:12}}>🎉</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,marginBottom:8}}>
              {lang==='en'?'Welcome to ProveRank!':'ProveRank में आपका स्वागत है!'}
            </div>
            <div style={{fontSize:13,color:SUB,lineHeight:1.6}}>
              {lang==='en'?'Your account is set up. Let\'s start your exam journey! 🚀':'आपका अकाउंट तैयार है। NEET यात्रा शुरू करें! 🚀'}
            </div>
            <div style={{marginTop:16,fontSize:12,color:'rgba(45,212,191,0.6)',animation:'pulse 1.5s ease-in-out infinite'}}>
              {lang==='en'?'Taking you to dashboard...':'डैशबोर्ड पर ले जा रहे हैं...'}
            </div>
          </div>
        </div>
      )}

      {/* ── MAIN CARD ─────────────────────────────────────── */}
      <div style={{width:'100%',maxWidth:480,animation:'fadeIn .5s ease'}}>

        {/* ── Top: Logo + Step counter (36.16) ─────────── */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20}}>
          <div style={{display:'flex',alignItems:'center',gap:10,animation:'glowBlue 3s ease-in-out infinite'}}>
            <div style={{width:36,height:36,borderRadius:10,background:'linear-gradient(135deg,#2DD4BF,#0D9488)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:18}}>⚡</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,background:'linear-gradient(90deg,#2DD4BF,#00F0D4)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</div>
          </div>
          <div style={{fontSize:12,color:SUB,fontWeight:600}}>
            {lang==='en'?`Step ${step+1} of ${TOTAL} · ${pct}%`:`चरण ${step+1}/${TOTAL} · ${pct}%`}
          </div>
        </div>

        {/* ── 36.2/36.22/36.25 — Progress bar + dots ──── */}
        <div style={{marginBottom:20}}>
          <div style={{height:4,background:'rgba(255,255,255,0.08)',borderRadius:4,overflow:'hidden',marginBottom:10}}>
            <div style={{height:'100%',width:`${pct}%`,background:`linear-gradient(90deg,#7B4DFF,#4D9FFF,#00C48C)`,borderRadius:4,transition:'width .4s ease',animation:'progressShimmer 1.5s ease-in-out infinite alternate'}}/>
          </div>
          <div style={{display:'flex',gap:6,justifyContent:'center'}}>
            {Array.from({length:TOTAL}).map((_,i) => (
              <div key={i} style={{width:i===step?28:8,height:8,borderRadius:4,background:i<=step?STEP_COLORS[i].pri:'rgba(255,255,255,0.12)',transition:'all .35s ease',boxShadow:i===step?`0 0 10px ${STEP_COLORS[i].pri}88`:undefined}}/>
            ))}
          </div>
        </div>

        {/* ── Card ──────────────────────────────────────── */}
        <div style={{background:cardBg,border:`1px solid ${sc.pri}33`,borderRadius:22,padding:'28px 26px',backdropFilter:'blur(22px)',boxShadow:`0 8px 48px rgba(0,0,0,.5),0 0 40px ${sc.pri}11`,animation:anim?(dir==='left'?'slideLeft .28s ease':'slideRight .28s ease'):'fadeIn .3s ease'}}>

          {/* SVG + heading + body (36.3) */}
          <div style={{textAlign:'center',marginBottom:20}}>
            <StepSVG step={step}/>
          </div>

          <div style={{textAlign:'center',marginBottom:16}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TXT,marginBottom:10,lineHeight:1.3}}>{cur.h}</div>
            <div style={{fontSize:13,color:SUB,lineHeight:1.7}}>{cur.b}</div>
          </div>

          {/* 36.18 — Mini mock on step 2 */}
          {step===1 && <MiniMock lang={lang}/>}

          {/* 36.17 — Badge preview on last step */}
          {step===5 && (
            <div style={{background:`rgba(0,196,140,0.1)`,border:'1px solid rgba(0,196,140,0.3)',borderRadius:12,padding:'12px 16px',marginBottom:16,display:'flex',alignItems:'center',gap:12}}>
              <div style={{fontSize:28}}>🏅</div>
              <div>
                <div style={{fontSize:12,fontWeight:700,color:'#00C48C'}}>{lang==='en'?'Achievement Unlocked!':'उपलब्धि अनलॉक!'}</div>
                <div style={{fontSize:11,color:SUB}}>{lang==='en'?'"Explorer" Badge — Completed Onboarding Tour':'"एक्सप्लोरर" बैज — ऑनबोर्डिंग पूरी की'}</div>
              </div>
            </div>
          )}

          {/* ── Nav buttons (36.6, 36.7) ──────────────── */}
          <div style={{display:'flex',gap:10,marginTop:8}}>
            {step>0 && (
              <button onClick={goBack} style={{flex:1,padding:'12px',background:'rgba(255,255,255,0.05)',border:`1px solid rgba(255,255,255,0.1)`,color:SUB,borderRadius:12,cursor:'pointer',fontSize:13,fontWeight:600}}>
                ← {lang==='en'?'Back':'वापस'}
              </button>
            )}
            {step<TOTAL-1 ? (
              <button onClick={goNext} style={{flex:2,padding:'12px',background:sc.grd,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,boxShadow:`0 4px 16px ${sc.pri}44`}}>
                {lang==='en'?'Next →':'आगे →'}
              </button>
            ) : (
              <button onClick={()=>complete(false)} style={{flex:2,padding:'12px',background:sc.grd,color:'#fff',border:'none',borderRadius:12,cursor:'pointer',fontWeight:700,fontSize:14,boxShadow:`0 4px 16px ${sc.pri}44`,animation:'bounce 1s ease-in-out infinite'}}>
                🚀 {lang==='en'?'Start My Journey!':'मेरी यात्रा शुरू करें!'}
              </button>
            )}
          </div>
        </div>

        {/* ── Skip + WhatsApp (36.9, 36.20) ────────────── */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginTop:16,padding:'0 4px'}}>
          <button onClick={()=>complete(true)} style={{background:'none',border:'none',color:'rgba(94,234,212,0.5)',fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',padding:0}}>
            {lang==='en'?'Skip Tour →':'टूर छोड़ें →'}
          </button>
          {step===5 && (
            <button onClick={()=>{
              const txt = encodeURIComponent(lang==='en'?'🚀 I just joined ProveRank — the ultimate competitive exam platform! Join me at prove-rank.vercel.app':'🚀 मैं अभी ProveRank से जुड़ गया — प्रतियोगी परीक्षाओं की सबसे बेहतरीन तैयारी! prove-rank.vercel.app पर जुड़ें')
              window.open(`https://wa.me/?text=${txt}`,'_blank')
            }} style={{background:'rgba(37,211,102,0.12)',border:'1px solid rgba(37,211,102,0.3)',borderRadius:20,padding:'6px 14px',color:'#25D366',fontSize:11,cursor:'pointer',fontWeight:600,display:'flex',alignItems:'center',gap:6}}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="#25D366"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/></svg>
              {lang==='en'?'Share':'शेयर करें'}
            </button>
          )}
        </div>

        {/* ── 36.5 — Language hint ─────────────────────── */}
        <div style={{textAlign:'center',marginTop:12}}>
          <button onClick={()=>setLang((l)=>l==='en'?'hi':'en')} style={{background:'none',border:'none',color:'rgba(94,234,212,0.4)',fontSize:11,cursor:'pointer'}}>
            {lang==='en'?'हिन्दी में देखें':'View in English'}
          </button>
        </div>

      </div>
    </div>
  )
}
