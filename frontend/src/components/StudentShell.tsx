'use client'
import React, {
  createContext, useContext, useState, useEffect,
  useCallback, useRef, ReactNode
} from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const _gt = ():string => { try{return localStorage.getItem('pr_token')||''}catch{return''} }
const _gr = ():string => { try{return localStorage.getItem('pr_role')||'student'}catch{return'student'} }
const _ca = ():void   => { try{localStorage.removeItem('pr_token');localStorage.removeItem('pr_role')}catch{} }

export const C = {
  primary:'#4D9FFF', card:'rgba(0,22,40,0.82)', cardL:'rgba(255,255,255,0.92)',
  border:'rgba(77,159,255,0.22)', borderL:'rgba(77,159,255,0.4)',
  text:'#E8F4FF', textL:'#0F172A', sub:'#6B8FAF', subL:'#475569',
  success:'#00C48C', danger:'#FF4D4D', gold:'#FFD700',
  warn:'#FFB84D', purple:'#A78BFA', pink:'#FF6B9D',
}

export interface ShellCtx {
  lang:'en'|'hi'; darkMode:boolean; user:any
  toast:(m:string,t?:'s'|'e'|'w')=>void; token:string; role:string
}
const ShellCtx = createContext<ShellCtx>({
  lang:'en',darkMode:true,user:null,toast:()=>{},token:'',role:'student'
})
export const useShell = () => useContext(ShellCtx)

export function PRLogo({size=40}:{size?:number}) {
  const r=size/2,cx=size/2,cy=size/2
  const pts=(sc:number)=>Array.from({length:6},(_,i)=>{
    const a=(Math.PI/180)*(60*i-30)
    return `${cx+r*sc*Math.cos(a)},${cy+r*sc*Math.sin(a)}`
  }).join(' ')
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <defs><filter id="pr-glow"><feGaussianBlur stdDeviation="1.5" result="b"/>
        <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
      </filter></defs>
      <polygon points={pts(0.88)} fill="none" stroke="rgba(77,159,255,0.3)" strokeWidth="1" filter="url(#pr-glow)"/>
      <polygon points={pts(0.72)} fill="none" stroke="#4D9FFF" strokeWidth="1.5" filter="url(#pr-glow)"/>
      {Array.from({length:6},(_,i)=>{
        const a=(Math.PI/180)*(60*i-30)
        return <circle key={i} cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)} r={size*0.05} fill="#4D9FFF" filter="url(#pr-glow)"/>
      })}
      <text x={cx} y={cy+size*0.16} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize={size*0.3} fontWeight="700" fill="#4D9FFF" filter="url(#pr-glow)">PR</text>
    </svg>
  )
}

function GalaxyBg() {
  const ref = useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas = ref.current; if(!canvas) return
    const ctx = canvas.getContext('2d'); if(!ctx) return
    const resize = ()=>{ canvas.width=window.innerWidth; canvas.height=window.innerHeight }
    resize()
    const stars = Array.from({length:220},()=>({
      x:Math.random()*canvas.width, y:Math.random()*canvas.height,
      r:Math.random()*1.6+0.2, op:Math.random()*0.7+0.1,
      tw:Math.random()*0.018+0.004, ph:Math.random()*Math.PI*2,
      col: Math.random()>0.85?`rgba(255,215,100,`:`rgba(200,218,255,`
    }))
    const parts = Array.from({length:65},()=>({
      x:Math.random()*canvas.width, y:Math.random()*canvas.height,
      vx:(Math.random()-.5)*.3, vy:(Math.random()-.5)*.3,
      r:Math.random()*1.8+0.4, op:Math.random()*.25+.04
    }))
    const spiral:any[] = []
    for(let arm=0;arm<2;arm++){
      for(let i=0;i<80;i++){
        const t=i/80; const angle=arm*Math.PI+t*Math.PI*3
        const rad=t*Math.min(canvas.width,canvas.height)*0.22
        spiral.push({
          x:canvas.width/2+rad*Math.cos(angle)+(Math.random()-.5)*30,
          y:canvas.height/2+rad*Math.sin(angle)+(Math.random()-.5)*30,
          r:Math.random()*1.2+0.3, op:Math.random()*0.3+0.05
        })
      }
    }
    let sx=-100,sy=-100,sActive=false,sT=0,sVx=0,sVy=0
    const triggerShoot=()=>{
      sx=Math.random()*canvas.width*.6; sy=Math.random()*canvas.height*.25
      sVx=3+Math.random()*4; sVy=1+Math.random()*2
      sActive=true; sT=0
      setTimeout(triggerShoot,3000+Math.random()*7000)
    }
    setTimeout(triggerShoot,2500)
    let animId:number
    const draw=()=>{
      ctx.clearRect(0,0,canvas.width,canvas.height)
      ;[
        {x:canvas.width*.08,y:canvas.height*.18,r:220,c:'rgba(77,159,255,0.05)'},
        {x:canvas.width*.88,y:canvas.height*.72,r:280,c:'rgba(167,139,250,0.04)'},
        {x:canvas.width*.5, y:canvas.height*.5, r:180,c:'rgba(255,100,157,0.02)'},
        {x:canvas.width*.4, y:canvas.height*.85,r:200,c:'rgba(0,196,140,0.03)'},
      ].forEach(n=>{
        const g=ctx.createRadialGradient(n.x,n.y,0,n.x,n.y,n.r)
        g.addColorStop(0,n.c); g.addColorStop(1,'transparent')
        ctx.fillStyle=g; ctx.beginPath(); ctx.arc(n.x,n.y,n.r,0,Math.PI*2); ctx.fill()
      })
      spiral.forEach(s=>{
        ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(180,210,255,${s.op})`; ctx.fill()
      })
      stars.forEach(s=>{
        s.ph+=s.tw
        const op=s.op*(0.55+0.45*Math.sin(s.ph))
        ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,Math.PI*2)
        ctx.fillStyle=s.col+op+')'; ctx.fill()
      })
      if(sActive){
        sT+=0.05; sx+=sVx; sy+=sVy
        if(sT<1){
          const tail=80
          const grd=ctx.createLinearGradient(sx-tail*sVx/5,sy-tail*sVy/5,sx,sy)
          grd.addColorStop(0,'rgba(255,255,255,0)'); grd.addColorStop(1,'rgba(255,255,255,0.85)')
          ctx.strokeStyle=grd; ctx.lineWidth=1.5
          ctx.beginPath(); ctx.moveTo(sx-tail*sVx/5,sy-tail*sVy/5); ctx.lineTo(sx,sy); ctx.stroke()
          const gl=ctx.createRadialGradient(sx,sy,0,sx,sy,4)
          gl.addColorStop(0,'rgba(255,255,255,0.6)'); gl.addColorStop(1,'transparent')
          ctx.fillStyle=gl; ctx.beginPath(); ctx.arc(sx,sy,4,0,Math.PI*2); ctx.fill()
        } else { sActive=false }
        if(sx>canvas.width+100||sy>canvas.height+100) sActive=false
      }
      parts.forEach(p=>{
        p.x+=p.vx; p.y+=p.vy
        if(p.x<0)p.x=canvas.width; if(p.x>canvas.width)p.x=0
        if(p.y<0)p.y=canvas.height; if(p.y>canvas.height)p.y=0
        ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(77,159,255,${p.op})`; ctx.fill()
      })
      for(let i=0;i<parts.length;i++) for(let j=i+1;j<parts.length;j++){
        const dx=parts[i].x-parts[j].x,dy=parts[i].y-parts[j].y,d=Math.sqrt(dx*dx+dy*dy)
        if(d<110){
          ctx.beginPath(); ctx.moveTo(parts[i].x,parts[i].y); ctx.lineTo(parts[j].x,parts[j].y)
          ctx.strokeStyle=`rgba(77,159,255,${.07*(1-d/110)})`; ctx.lineWidth=.5; ctx.stroke()
        }
      }
      animId=requestAnimationFrame(draw)
    }
    draw()
    window.addEventListener('resize',resize)
    return()=>{ cancelAnimationFrame(animId); window.removeEventListener('resize',resize) }
  },[])
  return <canvas ref={ref} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}

const NAV=[
  {id:'dashboard',      icon:'📊',en:'Dashboard',        hi:'डैशबोर्ड',             href:'/dashboard'},
  {id:'my-exams',       icon:'📝',en:'My Exams',          hi:'मेरी परीक्षाएं',        href:'/my-exams'},
  {id:'results',        icon:'📈',en:'Results',           hi:'परिणाम',               href:'/results'},
  {id:'analytics',      icon:'📉',en:'Analytics',         hi:'विश्लेषण',              href:'/analytics'},
  {id:'leaderboard',    icon:'🏆',en:'Leaderboard',       hi:'लीडरबोर्ड',             href:'/leaderboard'},
  {id:'certificate',    icon:'🎖️',en:'Certificates',      hi:'प्रमाणपत्र',            href:'/certificate'},
  {id:'admit-card',     icon:'🪪',en:'Admit Card',        hi:'प्रवेश पत्र',           href:'/admit-card'},
  {id:'pyq-bank',       icon:'📚',en:'PYQ Bank',          hi:'पिछले वर्ष के प्रश्न', href:'/pyq-bank'},
  {id:'mini-tests',     icon:'⚡',en:'Mini Tests',        hi:'मिनी टेस्ट',            href:'/mini-tests'},
  {id:'attempt-history',icon:'🕐',en:'Attempt History',   hi:'परीक्षा इतिहास',        href:'/attempt-history'},
  {id:'revision',       icon:'🧠',en:'Smart Revision',    hi:'स्मार्ट रिवीजन',        href:'/revision'},
  {id:'goals',          icon:'🎯',en:'My Goals',          hi:'मेरे लक्ष्य',           href:'/goals'},
  {id:'compare',        icon:'⚖️',en:'Compare',           hi:'तुलना करें',            href:'/compare'},
  {id:'announcements',  icon:'📢',en:'Announcements',     hi:'घोषणाएं',              href:'/announcements'},
  {id:'doubt',          icon:'💬',en:'Doubt & Query',     hi:'संदेह और प्रश्न',        href:'/doubt'},
  {id:'parent-portal',  icon:'👨‍👩‍👧',en:'Parent Portal', hi:'अभिभावक पोर्टल',        href:'/parent-portal'},
  {id:'support',        icon:'🛟',en:'Support',           hi:'सहायता',               href:'/support'},
  {id:'profile',        icon:'👤',en:'Profile',           hi:'प्रोफ़ाइल',             href:'/profile'},
]

export default function StudentShell({pageKey,children}:{pageKey:string;children:ReactNode}) {
  const router = useRouter()
  const [mounted,  setMounted] = useState(false)
  const [lang,     setLang]    = useState<'en'|'hi'>('en')
  const [dm,       setDm]      = useState(true)
  const [side,     setSide]    = useState(false)
  const [user,     setUser]    = useState<any>(null)
  const [token,    setToken]   = useState('')
  const [role,     setRole]    = useState('student')
  const [toastSt,  setToastSt] = useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)

  const toast = useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{
    setToastSt({msg,tp}); setTimeout(()=>setToastSt(null),4000)
  },[])

  useEffect(()=>{
    // Check if this is an impersonate session (admin viewing as student)
    const urlParams = typeof window !== 'undefined' ? new URLSearchParams(window.location.search) : null
    const impToken = urlParams?.get('imp_token')
    const impId    = urlParams?.get('imp_id')
    const impName  = urlParams?.get('imp_name')

    if(impToken && impId) {
      // Impersonate mode — use student token, show student dashboard
      setToken(impToken)
      setRole('student')
      setUser({ _id: impId, name: decodeURIComponent(impName||'Student'), role: 'student' })
      try { localStorage.setItem('imp_mode','1') } catch{}
      setMounted(true)
      return
    }

    const tk=_gt()
    if(!tk){ router.replace('/login'); return }

    const r=_gr()

    // ── IMPERSONATE MODE: check sessionStorage (set by /impersonate page) ──
    try {
      const impToken = sessionStorage.getItem('imp_token')
      const impId    = sessionStorage.getItem('imp_id')
      const impName  = sessionStorage.getItem('imp_name')
      if (impToken && impId) {
        setToken(impToken)
        setRole('student')
        setUser({ _id: impId, name: impName||'Student', role:'student', email:'' })
        setMounted(true)
        return
      }
    } catch(e) {}

    // ── ROLE GUARD: Admin/Superadmin must go to Admin Panel ──
    if(r==='admin'||r==='superadmin'){
      router.replace('/admin/x7k2p')
      return
    }

    setToken(tk); setRole(r)
    try{
      const sl=localStorage.getItem('pr_lang') as 'en'|'hi'|null; if(sl) setLang(sl)
      if(localStorage.getItem('pr_theme')==='light') setDm(false)
    }catch{}
    fetch(`${API}/api/auth/me`,{headers:{Authorization:`Bearer ${tk}`}})
      .then(r=>r.ok?r.json():null)
      .then(d=>{
        if(d?._id){
          setUser(d)
          // Double-check role from API response
          const apiRole=d.role||d.userType||''
          if(apiRole==='admin'||apiRole==='superadmin'){
            router.replace('/admin/x7k2p')
            return
          }
        }
      })
      .catch(()=>{})
    setMounted(true)
  },[router])

  if(!mounted) return null

  const bg  = dm?'radial-gradient(ellipse at 15% 55%,#001020 0%,#000A18 50%,#000308 100%)':'radial-gradient(ellipse at 15% 55%,#E0EFFF 0%,#C5DFFF 50%,#A5C8FF 100%)'
  const bdr = dm?C.border:C.borderL
  const txt = dm?C.text:C.textL
  const sub = dm?C.sub:C.subL

  const toggleLang  = ()=>{ const n=lang==='en'?'hi':'en'; setLang(n); try{localStorage.setItem('pr_lang',n)}catch{} }
  const toggleTheme = ()=>{ const n=!dm; setDm(n); try{localStorage.setItem('pr_theme',n?'dark':'light')}catch{} }
  const logout      = ()=>{ _ca(); router.replace('/login') }

  return (
    <ShellCtx.Provider value={{lang,darkMode:dm,user,toast,token,role}}>
      <div style={{minHeight:'100vh',background:bg,color:txt,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden'}}>
        <style>{`
          @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
          @keyframes fadeIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}
          @keyframes pulse{0%,100%{opacity:.4}50%{opacity:.9}}
          @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
          @keyframes floatR{0%,100%{transform:translateY(0) rotate(0deg)}50%{transform:translateY(-6px) rotate(5deg)}}
          @keyframes glow{0%,100%{box-shadow:0 0 8px rgba(77,159,255,.3)}50%{box-shadow:0 0 24px rgba(77,159,255,.7)}}
          @keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
          @keyframes spinSlow{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
          @keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
          @keyframes shimmer{0%,100%{opacity:.6}50%{opacity:1}}
          @keyframes gradMove{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
          *{box-sizing:border-box}
          ::-webkit-scrollbar{width:4px}::-webkit-scrollbar-thumb{background:rgba(77,159,255,.4);border-radius:4px}
          .card-h:hover{border-color:rgba(77,159,255,.55)!important;transform:translateY(-3px);box-shadow:0 8px 24px rgba(0,0,0,.35)!important;transition:all .25s}
          .nav-lnk:hover{background:rgba(77,159,255,.16)!important;color:#4D9FFF!important;padding-left:16px!important}
          .btn-p{background:linear-gradient(135deg,#4D9FFF,#0055CC);color:#fff;border:none;border-radius:10px;padding:11px 22px;cursor:pointer;font-weight:700;font-size:13px;font-family:Inter,sans-serif;box-shadow:0 4px 16px rgba(77,159,255,.35);transition:all .2s}
          .btn-p:hover{opacity:.9;transform:translateY(-1px);box-shadow:0 6px 24px rgba(77,159,255,.5)}
          .btn-g{background:rgba(77,159,255,.12);color:#4D9FFF;border:1px solid rgba(77,159,255,.3);border-radius:10px;padding:9px 18px;cursor:pointer;font-weight:600;font-size:12px;font-family:Inter,sans-serif;transition:all .2s}
          .btn-g:hover{background:rgba(77,159,255,.22);border-color:rgba(77,159,255,.5)}
          .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,.4);background:rgba(0,22,40,.55);color:#E8F4FF;font-size:12px;font-weight:600;cursor:pointer;font-family:Inter,sans-serif;backdrop-filter:blur(8px);transition:all .2s}
          .tbtn:hover{border-color:#4D9FFF;background:rgba(77,159,255,.18)}
          input,select,textarea{color-scheme:dark}
          details summary::-webkit-details-marker{display:none}
        `}</style>

        <GalaxyBg/>
        <div aria-hidden style={{position:'fixed',top:-70,left:-70,fontSize:320,color:'rgba(77,159,255,.022)',pointerEvents:'none',zIndex:0,lineHeight:1,userSelect:'none'}}>⬡</div>
        <div aria-hidden style={{position:'fixed',bottom:-70,right:-70,fontSize:320,color:'rgba(77,159,255,.022)',pointerEvents:'none',zIndex:0,lineHeight:1,userSelect:'none'}}>⬡</div>

        {typeof window!=='undefined'&&new URLSearchParams(window.location.search).get('imp_id')&&(
          <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9998,padding:'8px 16px',background:'linear-gradient(90deg,#FF6B00,#FF8C00)',color:'#fff',textAlign:'center',fontSize:12,fontWeight:700,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
            <span>👁️ Impersonate Mode — Viewing as Student</span>
            <button onClick={()=>window.close()} style={{background:'rgba(0,0,0,.3)',border:'none',color:'#fff',borderRadius:6,padding:'3px 10px',cursor:'pointer',fontFamily:'Inter,sans-serif',fontSize:11,fontWeight:700}}>✕ Close</button>
          </div>
        )}
        {toastSt&&(
          <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9999,padding:'14px 24px',fontWeight:700,fontSize:13,textAlign:'center',boxShadow:'0 4px 30px rgba(0,0,0,.55)',animation:'fadeIn .3s ease',background:toastSt.tp==='s'?'linear-gradient(90deg,#00C48C,#00a87a)':toastSt.tp==='w'?'linear-gradient(90deg,#FFB84D,#e6a200)':'linear-gradient(90deg,#FF4D4D,#cc0000)',color:toastSt.tp==='w'?'#000':'#fff'}}>
            {toastSt.tp==='e'?'❌':toastSt.tp==='w'?'⚠️':'✅'} {toastSt.msg}
          </div>
        )}

        {side&&<div onClick={()=>setSide(false)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,.55)',zIndex:49,backdropFilter:'blur(3px)'}}/>}

        <div style={{position:'fixed',top:0,left:0,width:272,height:'100vh',background:'rgba(0,5,18,.97)',borderRight:`1px solid ${bdr}`,zIndex:50,overflowY:'auto',display:'flex',flexDirection:'column',transform:side?'translateX(0)':'translateX(-100%)',transition:'transform .28s cubic-bezier(.4,0,.2,1)',backdropFilter:'blur(24px)',boxShadow:'5px 0 32px rgba(0,0,0,.6)'}}>
          <div style={{padding:'18px 18px 14px',borderBottom:`1px solid ${bdr}`,position:'sticky',top:0,background:'rgba(0,5,18,.97)',flexShrink:0}}>
            <div style={{display:'flex',alignItems:'center',gap:10}}>
              <PRLogo size={38}/>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF 0%,#fff 60%,#4D9FFF 100%)',backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'gradMove 4s ease infinite'}}>ProveRank</div>
                <div style={{fontSize:10,color:'#B8C8D8',fontWeight:600,display:'flex',alignItems:'center',gap:4,marginTop:1}}>
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none"><path d="M12 2a5 5 0 110 10A5 5 0 0112 2zm0 12c-5.33 0-8 2.67-8 4v1h16v-1c0-1.33-2.67-4-8-4z" fill="#B8C8D8"/></svg>
                  <span>{lang==='en'?'Student':'छात्र'}</span>
                </div>
              </div>
            </div>
            <button onClick={()=>setSide(false)} style={{position:'absolute',top:14,right:12,background:'none',border:'none',color:sub,cursor:'pointer',fontSize:18,lineHeight:1,padding:4}}>✕</button>
          </div>
          <div style={{padding:'8px 8px',flex:1,overflowY:'auto'}}>
            {NAV.map(n=>(
              <a key={n.id} href={n.href} className="nav-lnk" onClick={()=>setSide(false)} style={{display:'flex',alignItems:'center',gap:10,padding:'9px 12px',borderRadius:9,textDecoration:'none',color:pageKey===n.id?'#4D9FFF':sub,background:pageKey===n.id?'rgba(77,159,255,.16)':'transparent',fontWeight:pageKey===n.id?700:400,fontSize:13,borderLeft:pageKey===n.id?`3px solid #4D9FFF`:'3px solid transparent',marginBottom:1,transition:'all .2s'}}>
                <span style={{fontSize:15,width:20,textAlign:'center'}}>{n.icon}</span>
                <span>{lang==='en'?n.en:n.hi}</span>
                {pageKey===n.id&&<span style={{marginLeft:'auto',width:6,height:6,borderRadius:'50%',background:'#4D9FFF',flexShrink:0}}/>}
              </a>
            ))}
          </div>
          <div style={{padding:'12px 14px',borderTop:`1px solid ${bdr}`,flexShrink:0}}>
            <div style={{padding:'12px',background:'rgba(77,159,255,.06)',borderRadius:12,border:`1px solid ${bdr}`,marginBottom:10,textAlign:'center'}}>
              <div style={{fontSize:11,color:sub,marginBottom:4}}>{lang==='en'?'Powered by AI Proctoring':'AI प्रॉक्टरिंग द्वारा संचालित'}</div>
              <div style={{fontSize:10,color:C.success,fontWeight:600}}>🟢 {lang==='en'?'All Systems Live':'सभी सिस्टम लाइव'}</div>
            </div>
            <button onClick={logout} style={{width:'100%',padding:'11px',background:'rgba(255,77,77,.1)',color:'#FF4D4D',border:'1px solid rgba(255,77,77,.28)',borderRadius:10,cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',display:'flex',alignItems:'center',justifyContent:'center',gap:8,transition:'all .2s'}}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke="#FF4D4D" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
              {lang==='en'?'Logout':'लॉगआउट'}
            </button>
          </div>
        </div>

        <div style={{position:'sticky',top:0,zIndex:40,background:dm?'rgba(0,5,18,.95)':'rgba(224,239,255,.96)',backdropFilter:'blur(22px)',borderBottom:`1px solid ${bdr}`,height:58,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 16px',boxShadow:'0 2px 24px rgba(0,0,0,.3)'}}>
          <div style={{display:'flex',alignItems:'center',gap:10}}>
            <button onClick={()=>setSide(true)} style={{background:'none',border:'none',color:txt,fontSize:22,cursor:'pointer',padding:'4px 6px',borderRadius:7,lineHeight:1}} title="Menu">☰</button>
            <div style={{display:'flex',alignItems:'center',gap:8}}>
              <PRLogo size={30}/>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,background:`linear-gradient(90deg,${C.primary},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1}}>ProveRank</div>
                <div style={{fontSize:9,color:'#B8C8D8',fontWeight:600,letterSpacing:.6}}>{lang==='en'?'STUDENT':'छात्र'}</div>
              </div>
            </div>
          </div>
          <div style={{display:'flex',alignItems:'center',gap:7}}>
            <button className="tbtn" onClick={toggleLang}>{lang==='en'?'हि':'EN'}</button>
            <button className="tbtn" onClick={toggleTheme}>{dm?'☀️':'🌙'}</button>
            <a href="/announcements" style={{background:'none',border:`1px solid ${bdr}`,borderRadius:8,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',textDecoration:'none',fontSize:15,color:txt}}>🔔</a>
          </div>
        </div>

        <div style={{position:'relative',zIndex:1,padding:'24px 16px 56px',maxWidth:1100,margin:'0 auto',animation:'fadeIn .4s ease'}}>
          {children}
        </div>
      </div>
    </ShellCtx.Provider>
  )
}
