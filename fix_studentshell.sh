#!/bin/bash
G='\033[0;32m'; B='\033[0;34m'; N='\033[0m'
log(){ echo -e "${G}[✓]${N} $1"; }
step(){ echo -e "\n${B}══ $1 ══${N}"; }

FE=/home/runner/workspace/frontend

step "Fix 1 — Add missing auth functions to lib/auth.ts"
# Check current auth.ts content
echo "Current auth.ts:"
cat $FE/lib/auth.ts

step "Fix 2 — Rewrite StudentShell with safe auth (no getRole/clearAuth dependency)"
cat > $FE/src/components/StudentShell.tsx << 'ENDOFFILE'
'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Safe auth helpers (no lib/auth dependency) ──
const getToken = () => { try { return localStorage.getItem('pr_token')||'' } catch{ return '' } }
const getRole  = () => { try { return localStorage.getItem('pr_role')||'student' } catch{ return 'student' } }
const clearAuth = () => { try { localStorage.removeItem('pr_token'); localStorage.removeItem('pr_role') } catch{} }

// ── Brand Colours ──
const C = {
  bg:  'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',
  bgL: 'radial-gradient(ellipse at 20% 50%,#E8F4FF 0%,#C9E0FF 60%,#A8CCFF 100%)',
  card:'rgba(0,22,40,0.80)', cardL:'rgba(255,255,255,0.88)',
  bdr: 'rgba(77,159,255,0.22)', bdrL:'rgba(77,159,255,0.38)',
  pri: '#4D9FFF', txt:'#E8F4FF', txtL:'#0F172A',
  sub: '#6B8FAF', subL:'#475569',
  suc: '#00C48C', dng:'#FF4D4D', gld:'#FFD700', wrn:'#FFB84D',
}

// ── PR4 Logo ──
export function PRLogo({ size=40 }:{ size?:number }) {
  const r=size/2, cx=size/2, cy=size/2
  const outer=Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.88*Math.cos(a)},${cy+r*0.88*Math.sin(a)}`;}).join(' ')
  const inner=Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;}).join(' ')
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <defs><filter id="gls"><feGaussianBlur stdDeviation="1.5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
      <polygon points={outer} fill="none" stroke="rgba(77,159,255,0.35)" strokeWidth="1" filter="url(#gls)"/>
      <polygon points={inner} fill="none" stroke="#4D9FFF" strokeWidth="1.5" filter="url(#gls)"/>
      {Array.from({length:6},(_,i)=>{ const a=(Math.PI/180)*(60*i-30); return <circle key={i} cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)} r={size*0.05} fill="#4D9FFF" filter="url(#gls)"/> })}
      <text x={cx} y={cy+size*0.16} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize={size*0.3} fontWeight="700" fill="#4D9FFF" filter="url(#gls)">PR</text>
    </svg>
  )
}

// ── Universe Background ──
function UniverseBg() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current; if(!canvas) return
    const ctx=canvas.getContext('2d'); if(!ctx) return
    const resize=()=>{ canvas.width=window.innerWidth; canvas.height=window.innerHeight }
    resize()
    const stars=Array.from({length:180},()=>({ x:Math.random()*canvas.width, y:Math.random()*canvas.height, r:Math.random()*1.4+0.3, op:Math.random()*0.6+0.1, tw:Math.random()*0.02+0.005, ph:Math.random()*Math.PI*2 }))
    const parts=Array.from({length:55},()=>({ x:Math.random()*canvas.width, y:Math.random()*canvas.height, vx:(Math.random()-.5)*.35, vy:(Math.random()-.5)*.35, r:Math.random()*1.5+0.5, op:Math.random()*.25+.05 }))
    let shootX=-100,shootY=-100,shootActive=false,shootT=0
    const triggerShoot=()=>{ shootX=Math.random()*canvas.width*.5; shootY=Math.random()*canvas.height*.3; shootActive=true; shootT=0; setTimeout(triggerShoot,4000+Math.random()*6000) }
    setTimeout(triggerShoot,2000)
    let animId:number
    const draw=()=>{
      ctx.clearRect(0,0,canvas.width,canvas.height)
      // Nebula
      ;[{x:canvas.width*.1,y:canvas.height*.2,r:200,c:'rgba(77,159,255,0.04)'},{x:canvas.width*.85,y:canvas.height*.7,r:250,c:'rgba(167,139,250,0.03)'},{x:canvas.width*.5,y:canvas.height*.9,r:180,c:'rgba(0,196,140,0.025)'}].forEach(n=>{
        const g=ctx.createRadialGradient(n.x,n.y,0,n.x,n.y,n.r); g.addColorStop(0,n.c); g.addColorStop(1,'transparent')
        ctx.fillStyle=g; ctx.beginPath(); ctx.arc(n.x,n.y,n.r,0,Math.PI*2); ctx.fill()
      })
      // Stars
      stars.forEach(s=>{ s.ph+=s.tw; const op=s.op*(0.6+0.4*Math.sin(s.ph)); ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,Math.PI*2); ctx.fillStyle=`rgba(200,220,255,${op})`; ctx.fill() })
      // Shooting star
      if(shootActive){ shootT+=0.04; const sx=shootX+shootT*300,sy=shootY+shootT*120; if(shootT<1){ const tail=60; const grd=ctx.createLinearGradient(sx-tail,sy-tail*.4,sx,sy); grd.addColorStop(0,'rgba(77,159,255,0)'); grd.addColorStop(1,'rgba(255,255,255,0.8)'); ctx.strokeStyle=grd; ctx.lineWidth=1.5; ctx.beginPath(); ctx.moveTo(sx-tail,sy-tail*.4); ctx.lineTo(sx,sy); ctx.stroke() } else { shootActive=false } }
      // Particles + connections
      parts.forEach(p=>{ p.x+=p.vx; p.y+=p.vy; if(p.x<0)p.x=canvas.width; if(p.x>canvas.width)p.x=0; if(p.y<0)p.y=canvas.height; if(p.y>canvas.height)p.y=0; ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2); ctx.fillStyle=`rgba(77,159,255,${p.op})`; ctx.fill() })
      for(let i=0;i<parts.length;i++) for(let j=i+1;j<parts.length;j++){ const dx=parts[i].x-parts[j].x,dy=parts[i].y-parts[j].y,d=Math.sqrt(dx*dx+dy*dy); if(d<100){ ctx.beginPath(); ctx.moveTo(parts[i].x,parts[i].y); ctx.lineTo(parts[j].x,parts[j].y); ctx.strokeStyle=`rgba(77,159,255,${.07*(1-d/100)})`; ctx.lineWidth=.5; ctx.stroke() } }
      animId=requestAnimationFrame(draw)
    }
    draw()
    window.addEventListener('resize',resize)
    return()=>{ cancelAnimationFrame(animId); window.removeEventListener('resize',resize) }
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}

// ── Nav Items ──
const NAV = [
  {id:'dashboard',   icon:'📊', en:'Dashboard',         hi:'डैशबोर्ड',              href:'/dashboard'},
  {id:'my-exams',    icon:'📝', en:'My Exams',           hi:'मेरी परीक्षाएं',         href:'/my-exams'},
  {id:'results',     icon:'📈', en:'Results',            hi:'परिणाम',                href:'/results'},
  {id:'analytics',   icon:'📉', en:'Analytics',          hi:'विश्लेषण',               href:'/analytics'},
  {id:'leaderboard', icon:'🏆', en:'Leaderboard',        hi:'लीडरबोर्ड',              href:'/leaderboard'},
  {id:'certificate', icon:'🎖️', en:'Certificates',       hi:'प्रमाणपत्र',             href:'/certificate'},
  {id:'admit-card',  icon:'🪪', en:'Admit Card',         hi:'प्रवेश पत्र',            href:'/admit-card'},
  {id:'pyq-bank',    icon:'📚', en:'PYQ Bank',           hi:'पिछले वर्ष के प्रश्न',  href:'/pyq-bank'},
  {id:'mini-tests',  icon:'⚡', en:'Mini Tests',         hi:'मिनी टेस्ट',             href:'/mini-tests'},
  {id:'attempt-history',icon:'🕐',en:'Attempt History', hi:'परीक्षा इतिहास',         href:'/attempt-history'},
  {id:'revision',    icon:'🧠', en:'Smart Revision',     hi:'स्मार्ट रिवीजन',         href:'/revision'},
  {id:'goals',       icon:'🎯', en:'My Goals',           hi:'मेरे लक्ष्य',            href:'/goals'},
  {id:'compare',     icon:'⚖️', en:'Compare',            hi:'तुलना करें',             href:'/compare'},
  {id:'announcements',icon:'📢',en:'Announcements',      hi:'घोषणाएं',               href:'/announcements'},
  {id:'doubt',       icon:'💬', en:'Doubt & Query',      hi:'संदेह और प्रश्न',         href:'/doubt'},
  {id:'parent-portal',icon:'👨‍👩‍👧',en:'Parent Portal',   hi:'अभिभावक पोर्टल',         href:'/parent-portal'},
  {id:'support',     icon:'🛟', en:'Support',            hi:'सहायता',                href:'/support'},
  {id:'profile',     icon:'👤', en:'Profile',            hi:'प्रोफ़ाइल',              href:'/profile'},
]

export interface ShellCtx { lang:'en'|'hi'; darkMode:boolean; user:any; toast:(msg:string,t?:'s'|'e'|'w')=>void; token:string }

interface StudentShellProps { pageKey:string; children:(ctx:ShellCtx)=>React.ReactNode }

export default function StudentShell({ pageKey, children }:StudentShellProps) {
  const router = useRouter()
  const [mounted,  setMounted]   = useState(false)
  const [lang,     setLang]      = useState<'en'|'hi'>('en')
  const [darkMode, setDarkMode]  = useState(true)
  const [sideOpen, setSideOpen]  = useState(false)
  const [user,     setUser]      = useState<any>(null)
  const [token,    setTokenSt]   = useState('')
  const [toastMsg, setToastMsg]  = useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)

  const toast = useCallback((msg:string, tp:'s'|'e'|'w'='s')=>{
    setToastMsg({msg,tp}); setTimeout(()=>setToastMsg(null),4000)
  },[])

  useEffect(()=>{
    // Read from localStorage safely
    const tk  = getToken()
    const role= getRole()
    if(!tk){ router.replace('/login'); return }
    setTokenSt(tk)
    try {
      const savedLang = localStorage.getItem('pr_lang') as 'en'|'hi'|null
      if(savedLang) setLang(savedLang)
      const savedTheme = localStorage.getItem('pr_theme')
      if(savedTheme==='light') setDarkMode(false)
    } catch{}
    // Fetch user profile
    fetch(`${API}/api/auth/me`,{headers:{Authorization:`Bearer ${tk}`}})
      .then(r=>r.ok?r.json():null).then(d=>{ if(d&&d._id) setUser(d) }).catch(()=>{})
    setMounted(true)
  },[router])

  const toggleLang = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); try{localStorage.setItem('pr_lang',n)}catch{} }
  const toggleTheme= ()=>{ const n=!darkMode; setDarkMode(n); try{localStorage.setItem('pr_theme',n?'dark':'light')}catch{} }
  const logout     = ()=>{ clearAuth(); router.replace('/login') }

  if(!mounted) return null

  const dm  = darkMode
  const role= getRole()
  const bg  = dm?C.bg:C.bgL
  const cardBg  = dm?C.card:C.cardL
  const textMain= dm?C.txt:C.txtL
  const textSub = dm?C.sub:C.subL
  const bdr     = dm?C.bdr:C.bdrL

  return (
    <div style={{minHeight:'100vh',background:bg,color:textMain,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',transition:'background 0.4s'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
        @keyframes pulse{0%,100%{opacity:.5}50%{opacity:1}}
        @keyframes glow{0%,100%{box-shadow:0 0 8px rgba(77,159,255,.3)}50%{box-shadow:0 0 20px rgba(77,159,255,.6)}}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-6px)}}
        @keyframes shimmer{0%{background-position:-200% 0}100%{background-position:200% 0}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:4px}::-webkit-scrollbar-track{background:rgba(0,22,40,0.3)}::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.4);border-radius:4px}
        .nav-link:hover{background:rgba(77,159,255,0.14)!important;color:#4D9FFF!important;transform:translateX(2px)}
        .card-h:hover{border-color:rgba(77,159,255,0.5)!important;transform:translateY(-2px);transition:all .2s}
        .btn-p{background:linear-gradient(135deg,#4D9FFF,#0055CC);color:#fff;border:none;border-radius:10px;padding:11px 22px;cursor:pointer;font-weight:700;font-size:13px;font-family:Inter,sans-serif;box-shadow:0 4px 16px rgba(77,159,255,0.35);transition:all .2s}
        .btn-p:hover{opacity:.88;transform:translateY(-1px)}
        .btn-g{background:rgba(77,159,255,0.12);color:#4D9FFF;border:1px solid rgba(77,159,255,0.3);border-radius:10px;padding:9px 18px;cursor:pointer;font-weight:600;font-size:12px;font-family:Inter,sans-serif;transition:all .2s}
        .btn-g:hover{background:rgba(77,159,255,0.2)}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:12px;font-weight:600;cursor:pointer;font-family:Inter,sans-serif;backdrop-filter:blur(8px);transition:all .2s}
        .tbtn:hover{border-color:#4D9FFF;background:rgba(77,159,255,0.15)}
        input,textarea,select{color-scheme:dark}
      `}</style>

      <UniverseBg/>

      {/* Decorative hexagons */}
      <div style={{position:'fixed',top:-60,left:-60,fontSize:300,color:'rgba(77,159,255,0.025)',pointerEvents:'none',zIndex:0,lineHeight:1}}>⬡</div>
      <div style={{position:'fixed',bottom:-60,right:-60,fontSize:300,color:'rgba(77,159,255,0.025)',pointerEvents:'none',zIndex:0,lineHeight:1}}>⬡</div>

      {/* ── TOAST ── */}
      {toastMsg&&(
        <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9999,padding:'14px 24px',fontWeight:700,fontSize:13,background:toastMsg.tp==='s'?`linear-gradient(90deg,${C.suc},#00a87a)`:toastMsg.tp==='w'?`linear-gradient(90deg,${C.wrn},#e6a200)`:`linear-gradient(90deg,${C.dng},#cc0000)`,color:toastMsg.tp==='w'?'#000':'#fff',textAlign:'center',boxShadow:'0 4px 30px rgba(0,0,0,.5)',animation:'fadeIn .3s ease'}}>
          {toastMsg.tp==='e'?'❌':toastMsg.tp==='w'?'⚠️':'✅'} {toastMsg.msg}
        </div>
      )}

      {/* ── SIDEBAR OVERLAY ── */}
      {sideOpen&&<div onClick={()=>setSideOpen(false)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.5)',zIndex:49,backdropFilter:'blur(2px)'}}/>}

      {/* ── SIDEBAR ── */}
      <div style={{position:'fixed',top:0,left:0,width:264,height:'100vh',background:'rgba(0,6,18,0.97)',borderRight:`1px solid ${bdr}`,zIndex:50,overflowY:'auto',padding:'0 0 24px',transform:sideOpen?'translateX(0)':'translateX(-100%)',transition:'transform .28s cubic-bezier(.4,0,.2,1)',backdropFilter:'blur(20px)',boxShadow:'4px 0 30px rgba(0,0,0,.5)'}}>

        {/* Sidebar Header */}
        <div style={{padding:'20px 20px 16px',borderBottom:`1px solid ${bdr}`,position:'sticky',top:0,background:'rgba(0,6,18,0.97)',backdropFilter:'blur(10px)'}}>
          <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:6}}>
            <PRLogo size={36}/>
            <div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#fff)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</div>
              {/* Silver/White role label */}
              <div style={{fontSize:11,color:'#C0C8D8',fontWeight:600,display:'flex',alignItems:'center',gap:4,marginTop:1}}>
                {role==='parent'
                  ?<><svg width="12" height="12" viewBox="0 0 24 24" fill="none"><path d="M17 20H7M12 4a4 4 0 100 8 4 4 0 000-8zM5 20a7 7 0 0114 0" stroke="#C0C8D8" strokeWidth="2" strokeLinecap="round"/></svg><span>{lang==='en'?'Parent':'अभिभावक'}</span></>
                  :<><svg width="12" height="12" viewBox="0 0 24 24" fill="none"><path d="M12 2a5 5 0 110 10A5 5 0 0112 2zm0 12c-5.33 0-8 2.67-8 4v1h16v-1c0-1.33-2.67-4-8-4z" fill="#C0C8D8"/></svg><span>{lang==='en'?'Student':'छात्र'}</span></>
                }
              </div>
            </div>
          </div>
          <button onClick={()=>setSideOpen(false)} style={{position:'absolute',top:16,right:14,background:'none',border:'none',color:textSub,cursor:'pointer',fontSize:18,lineHeight:1}}>✕</button>
        </div>

        {/* Nav Links */}
        <div style={{padding:'8px 10px'}}>
          {NAV.map(n=>(
            <a key={n.id} href={n.href} className="nav-link" onClick={()=>setSideOpen(false)} style={{display:'flex',alignItems:'center',gap:10,padding:'9px 12px',borderRadius:9,textDecoration:'none',color:pageKey===n.id?C.pri:textSub,background:pageKey===n.id?'rgba(77,159,255,0.14)':'transparent',fontWeight:pageKey===n.id?700:400,fontSize:13,borderLeft:pageKey===n.id?`3px solid ${C.pri}`:'3px solid transparent',transition:'all .2s',marginBottom:2}}>
              <span style={{fontSize:15,width:20,textAlign:'center'}}>{n.icon}</span>
              <span>{lang==='en'?n.en:n.hi}</span>
            </a>
          ))}
        </div>

        {/* Sidebar Footer */}
        <div style={{margin:'16px 14px 0',padding:'14px',background:'rgba(77,159,255,0.06)',borderRadius:12,border:`1px solid ${bdr}`,textAlign:'center'}}>
          <div style={{fontSize:11,color:textSub,marginBottom:6}}>{lang==='en'?'Powered by AI Proctoring':'AI प्रॉक्टरिंग द्वारा संचालित'}</div>
          <div style={{fontSize:10,color:C.suc,fontWeight:600}}>🟢 {lang==='en'?'All Systems Live':'सभी सिस्टम लाइव'}</div>
        </div>
      </div>

      {/* ── TOPBAR ── */}
      <div style={{position:'sticky',top:0,zIndex:40,background:dm?'rgba(0,6,18,0.95)':'rgba(232,244,255,0.95)',backdropFilter:'blur(20px)',borderBottom:`1px solid ${bdr}`,height:58,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 16px',boxShadow:'0 2px 20px rgba(0,0,0,.3)'}}>
        {/* Left */}
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <button onClick={()=>setSideOpen(true)} style={{background:'none',border:'none',color:textMain,fontSize:22,cursor:'pointer',padding:'4px 6px',borderRadius:6,lineHeight:1}}>☰</button>
          <div style={{display:'flex',alignItems:'center',gap:8}}>
            <PRLogo size={30}/>
            <div>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,background:`linear-gradient(90deg,${C.pri},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1}}>ProveRank</div>
              <div style={{fontSize:9,color:'#C0C8D8',fontWeight:600,letterSpacing:.5}}>{role==='parent'?(lang==='en'?'PARENT':'अभिभावक'):(lang==='en'?'STUDENT':'छात्र')}</div>
            </div>
          </div>
        </div>
        {/* Right */}
        <div style={{display:'flex',alignItems:'center',gap:7}}>
          <button className="tbtn" onClick={toggleLang}>{lang==='en'?'हि':'EN'}</button>
          <button className="tbtn" onClick={toggleTheme}>{dm?'☀️':'🌙'}</button>
          <a href="/announcements" style={{background:'none',border:`1px solid ${bdr}`,borderRadius:8,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',textDecoration:'none',fontSize:15,color:textMain}}>🔔</a>
          <button onClick={logout} style={{background:'rgba(255,77,77,0.12)',color:C.dng,border:'1px solid rgba(255,77,77,0.25)',borderRadius:8,padding:'6px 11px',cursor:'pointer',fontWeight:700,fontSize:11,fontFamily:'Inter,sans-serif'}}>
            {lang==='en'?'Logout':'लॉगआउट'}
          </button>
        </div>
      </div>

      {/* ── PAGE CONTENT ── */}
      <div style={{position:'relative',zIndex:1,padding:'24px 16px 48px',maxWidth:1100,margin:'0 auto',animation:'fadeIn .4s ease'}}>
        {children({ lang, darkMode:dm, user, toast, token })}
      </div>
    </div>
  )
}
ENDOFFILE
log "StudentShell fixed — no getRole/clearAuth dependency"

step "Fix 3 — Fix Exam Attempt page auth import"
sed -i "s/import { getToken, clearAuth } from '@\/lib\/auth'/const getToken=()=>{try{return localStorage.getItem('pr_token')||''}catch{return ''}}\nconst clearAuth=()=>{try{localStorage.removeItem('pr_token');localStorage.removeItem('pr_role')}catch{}}/" $FE/app/exam/\[id\]/page.tsx
log "Exam page auth fixed"

step "Fix 4 — Fix Onboarding page auth import"
sed -i "s/import { getToken } from '@\/lib\/auth'/const getToken=()=>{try{return localStorage.getItem('pr_token')||''}catch{return ''}}/" $FE/app/onboarding/page.tsx 2>/dev/null || true
log "Onboarding auth fixed"

step "Fix 5 — Git push"
cd /home/runner/workspace && git add -A && git commit -m "fix: StudentShell crash — remove getRole/clearAuth dependency, use localStorage directly" && git push origin main

echo ""
echo -e "\033[0;32m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[0;32m║  Fix Applied ✅ Dashboard should work now ║\033[0m"
echo -e "\033[0;32m╚══════════════════════════════════════════╝\033[0m"
