'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

export default function Home() {
  const router = useRouter();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 50);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const features = [
    { icon: '🧪', title: 'NEET Pattern', desc: '180 questions, 720 marks — exact NEET format with Physics, Chemistry & Biology sections.' },
    { icon: '📊', title: 'Live Rank', desc: 'Real-time leaderboard updates as students submit — see your rank instantly.' },
    { icon: '🛡️', title: 'Anti-Cheat AI', desc: 'AI proctoring with webcam, tab-switch detection and IP locking.' },
    { icon: '⏱️', title: 'Smart Timer', desc: 'Section-wise countdown timer with auto-submit on timeout.' },
    { icon: '📈', title: 'Deep Analytics', desc: 'Subject-wise breakdown, percentile, topper comparison and trend graphs.' },
    { icon: '📱', title: 'Mobile Ready', desc: 'Fully responsive — attempt exams on any device, anywhere.' },
  ];

  const testimonials = [
    { name: 'Arjun S.', rank: 'AIR 34', quote: 'ProveRank helped me track my weak areas perfectly!', stars: 5 },
    { name: 'Priya K.', rank: 'AIR 112', quote: 'The live leaderboard kept me motivated every day.', stars: 5 },
    { name: 'Rahul M.', rank: 'AIR 67', quote: 'Best mock test platform for NEET preparation.', stars: 5 },
    { name: 'Sneha T.', rank: 'AIR 203', quote: 'Anti-cheat system made every test feel like the real exam.', stars: 5 },
    { name: 'Karan P.', rank: 'AIR 89', quote: 'Analytics feature is a game changer for revision!', stars: 5 },
    { name: 'Anjali R.', rank: 'AIR 156', quote: 'ProveRank is the only platform I used for mocks.', stars: 5 },
  ];

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',overflowX:'hidden'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        *{box-sizing:border-box;margin:0;padding:0}
        @keyframes fadeUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-18px)}}
        @keyframes marquee{0%{transform:translateX(0)}100%{transform:translateX(-50%)}}
        @keyframes gradientShift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
        .hero-hex{animation:float 4s ease-in-out infinite;opacity:0.08}
        .feature-card:hover{border-color:#4D9FFF!important;box-shadow:0 0 20px rgba(77,159,255,0.15)!important;transform:translateY(-4px)}
        .feature-card{transition:all 0.3s ease}
        .nav-link:hover{color:#E8F4FF!important}
        .cta-btn:hover{background:#3d8fe8!important;transform:scale(1.03)}
      `}</style>

      {/* Sticky Nav — NV1 */}
      <nav style={{position:'fixed',top:0,left:0,right:0,zIndex:100,
        background: scrolled ? 'rgba(0,10,24,0.95)' : 'transparent',
        backdropFilter: scrolled ? 'blur(12px)' : 'none',
        borderBottom: scrolled ? '1px solid #002D55' : 'none',
        transition:'all 0.3s ease',padding:'16px 40px',
        display:'flex',alignItems:'center',justifyContent:'space-between'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:'20px',
          fontWeight:700,color:'#E8F4FF'}}>
          <span style={{color:'#4D9FFF'}}>⬡</span> ProveRank
        </div>
        <div style={{display:'flex',gap:'32px',alignItems:'center'}}>
          {['Features','Results','Pricing'].map(l=>(
            <span key={l} className="nav-link" style={{color:'#6B8BAF',fontSize:'14px',
              cursor:'pointer',transition:'color 0.2s'}}>{l}</span>
          ))}
          <button onClick={()=>router.push('/login')}
            className="cta-btn"
            style={{padding:'8px 20px',background:'#4D9FFF',border:'none',
              borderRadius:'8px',color:'#000',fontSize:'14px',fontWeight:600,
              cursor:'pointer',transition:'all 0.2s'}}>
            Login →
          </button>
        </div>
      </nav>

      {/* Hero Section — H1 */}
      <div style={{minHeight:'100vh',display:'flex',alignItems:'center',
        justifyContent:'center',textAlign:'center',padding:'100px 20px 60px',
        position:'relative',overflow:'hidden',
        background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)'}}>

        {/* Floating Hexagons BG */}
        {[...Array(6)].map((_,i)=>(
          <div key={i} className="hero-hex" style={{
            position:'absolute',
            fontSize:`${40+i*20}px`,
            left:`${10+i*15}%`,
            top:`${20+i*10}%`,
            animationDelay:`${i*0.7}s`,
            color:'#4D9FFF'}}>⬡</div>
        ))}

        <div style={{position:'relative',zIndex:2,animation:'fadeUp 0.8s ease'}}>
          <div style={{display:'inline-block',padding:'6px 16px',
            background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.3)',
            borderRadius:'20px',color:'#4D9FFF',fontSize:'12px',
            fontWeight:600,marginBottom:'24px',letterSpacing:'1px'}}>
            🚀 INDIA'S SMARTEST NEET TEST PLATFORM
          </div>

          <h1 style={{
            fontFamily:'Playfair Display,serif',
            fontSize:'clamp(36px,7vw,72px)',
            fontWeight:700,lineHeight:1.15,marginBottom:'20px',
            background:'linear-gradient(135deg,#E8F4FF 0%,#4D9FFF 50%,#00CFFF 100%)',
            backgroundSize:'200% 200%',
            WebkitBackgroundClip:'text',
            WebkitTextFillColor:'transparent',
            animation:'gradientShift 4s ease infinite'}}>
            Prove Yourself.<br/>Rise to the Top.
          </h1>

          <p style={{fontSize:'18px',color:'#6B8BAF',maxWidth:'520px',
            margin:'0 auto 40px',lineHeight:1.7}}>
            NEET pattern mock tests with live rankings, AI proctoring, and deep analytics — all free.
          </p>

          <div style={{display:'flex',gap:'16px',justifyContent:'center',flexWrap:'wrap'}}>
            <button onClick={()=>router.push('/register')}
              style={{padding:'14px 32px',background:'#4D9FFF',border:'none',
                borderRadius:'10px',color:'#000',fontSize:'16px',fontWeight:700,
                cursor:'pointer',transition:'all 0.2s',fontFamily:'Inter,sans-serif'}}>
              Register Free →
            </button>
            <button onClick={()=>router.push('/login')}
              style={{padding:'14px 32px',background:'transparent',
                border:'1px solid #4D9FFF',borderRadius:'10px',color:'#4D9FFF',
                fontSize:'16px',fontWeight:600,cursor:'pointer',
                fontFamily:'Inter,sans-serif'}}>
              Login
            </button>
          </div>
        </div>
      </div>

      {/* Features — FT1 */}
      <div style={{padding:'80px 40px',background:'#000A18'}}>
        <div style={{textAlign:'center',marginBottom:'48px'}}>
          <h2 style={{fontFamily:'Playfair Display,serif',fontSize:'36px',
            fontWeight:700,color:'#E8F4FF',marginBottom:'12px'}}>
            Everything You Need to Crack NEET
          </h2>
          <p style={{color:'#6B8BAF',fontSize:'15px'}}>110+ features built for serious aspirants</p>
        </div>
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',
          gap:'20px',maxWidth:'1100px',margin:'0 auto'}}>
          {features.map(f=>(
            <div key={f.title} className="feature-card"
              style={{background:'#001628',border:'1px solid #002D55',borderRadius:'14px',
                padding:'28px 24px',cursor:'default'}}>
              <div style={{fontSize:'32px',marginBottom:'14px'}}>{f.icon}</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:'16px',
                fontWeight:700,color:'#E8F4FF',marginBottom:'8px'}}>{f.title}</div>
              <div style={{fontSize:'13px',color:'#6B8BAF',lineHeight:1.6}}>{f.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Stats Banner — ST2 */}
      <div style={{padding:'40px',background:'linear-gradient(90deg,#001628,#002D55,#001628)',
        display:'flex',justifyContent:'center',gap:'80px',flexWrap:'wrap',
        borderTop:'1px solid #002D55',borderBottom:'1px solid #002D55'}}>
        {[
          {v:'50,000+',l:'Students'},
          {v:'1,20,000+',l:'Tests Taken'},
          {v:'99.9%',l:'Uptime'},
        ].map(({v,l})=>(
          <div key={l} style={{textAlign:'center'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:'36px',
              fontWeight:700,color:'#4D9FFF'}}>{v}</div>
            <div style={{fontSize:'13px',color:'#6B8BAF',marginTop:'4px'}}>{l}</div>
          </div>
        ))}
      </div>

      {/* Testimonials — TS1 */}
      <div style={{padding:'80px 0',background:'#000A18',overflow:'hidden'}}>
        <h2 style={{textAlign:'center',fontFamily:'Playfair Display,serif',
          fontSize:'32px',fontWeight:700,color:'#E8F4FF',marginBottom:'40px'}}>
          What Our Students Say
        </h2>
        <div style={{overflow:'hidden',whiteSpace:'nowrap'}}>
          <div style={{display:'inline-flex',gap:'20px',animation:'marquee 20s linear infinite'}}>
            {[...testimonials,...testimonials].map((t,i)=>(
              <div key={i} style={{display:'inline-block',minWidth:'280px',
                background:'#001628',border:'1px solid #002D55',borderRadius:'14px',
                padding:'20px',whiteSpace:'normal',verticalAlign:'top'}}>
                <div style={{color:'#F59E0B',fontSize:'13px',marginBottom:'8px'}}>
                  {'★'.repeat(t.stars)}
                </div>
                <div style={{fontSize:'13px',color:'#E8F4FF',marginBottom:'12px',
                  lineHeight:1.5}}>"{t.quote}"</div>
                <div style={{fontSize:'12px',fontWeight:600,color:'#4D9FFF'}}>{t.name}</div>
                <div style={{fontSize:'11px',color:'#6B8BAF'}}>{t.rank}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* CTA — CT2 */}
      <div style={{padding:'40px',background:'#001628',
        borderTop:'1px solid #002D55',
        display:'flex',justifyContent:'space-between',
        alignItems:'center',flexWrap:'wrap',gap:'20px'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:'20px',
          fontWeight:700,color:'#E8F4FF'}}>
          Start your NEET journey today.
        </div>
        <button onClick={()=>router.push('/register')}
          style={{padding:'12px 28px',background:'#4D9FFF',border:'none',
            borderRadius:'10px',color:'#000',fontSize:'15px',fontWeight:700,
            cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
          Register Free →
        </button>
      </div>

      {/* Footer */}
      <div style={{padding:'24px 40px',background:'#000510',
        display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:'10px',
        borderTop:'1px solid #002D55'}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:'14px',color:'#4D9FFF'}}>
          ⬡ ProveRank
        </div>
        <div style={{fontSize:'12px',color:'#6B8BAF'}}>
          NEET · NEET PG · JEE · CUET
        </div>
      </div>
    </div>
  );
}
