'use client'
import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const gt  = () => { try { return localStorage.getItem('pr_token')||'' } catch { return '' } }
const gr  = () => { try { return localStorage.getItem('pr_role')||'student' } catch { return 'student' } }
const ca  = () => { try { localStorage.removeItem('pr_token');localStorage.removeItem('pr_role') } catch {} }

export const C = {
  primary:'#4D9FFF', card:'rgba(0,22,40,0.80)', cardL:'rgba(255,255,255,0.88)',
  border:'rgba(77,159,255,0.22)', borderL:'rgba(77,159,255,0.38)',
  text:'#E8F4FF', textL:'#0F172A', sub:'#6B8FAF', subL:'#475569',
  success:'#00C48C', danger:'#FF4D4D', gold:'#FFD700', warn:'#FFB84D',
}

export interface ShellCtx {
  lang:'en'|'hi'; darkMode:boolean; user:any
  toast:(m:string,t?:'s'|'e'|'w')=>void; token:string; role:string
}
const Ctx = createContext<ShellCtx>({lang:'en',darkMode:true,user:null,toast:()=>{},token:'',role:'student'})
export const useShell = () => useContext(Ctx)

export function PRLogo({ size=40 }:{ size?:number }) {
  const r=size/2,cx=size/2,cy=size/2
  const o=Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*.88*Math.cos(a)},${cy+r*.88*Math.sin(a)}`}).join(' ')
  const inn=Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return `${cx+r*.72*Math.cos(a)},${cy+r*.72*Math.sin(a)}`}).join(' ')
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <defs><filter id="gls"><feGaussianBlur stdDeviation="1.5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
      <polygon points={o}   fill="none" stroke="rgba(77,159,255,0.3)"  strokeWidth="1"   filter="url(#gls)"/>
      <polygon points={inn} fill="none" stroke="#4D9FFF"               strokeWidth="1.5" filter="url(#gls)"/>
      {Array.from({length:6},(_,i)=>{const a=(Math.PI/180)*(60*i-30);return <circle key={i} cx={cx+r*.88*Math.cos(a)} cy={cy+r*.88*Math.sin(a)} r={size*.05} fill="#4D9FFF" filter="url(#gls)"/>})}
      <text x={cx} y={cy+size*.16} textAnchor="middle" fontFamily="Playfair Display,serif" fontSize={size*.3} fontWeight="700" fill="#4D9FFF" filter="url(#gls)">PR</text>
    </svg>
  )
}

const NAV=[
  {id:'dashboard',icon:'📊',en:'Dashboard',hi:'डैशबोर्ड',href:'/dashboard'},
  {id:'my-exams',icon:'📝',en:'My Exams',hi:'मेरी परीक्षाएं',href:'/my-exams'},
  {id:'results',icon:'📈',en:'Results',hi:'परिणाम',href:'/results'},
  {id:'analytics',icon:'📉',en:'Analytics',hi:'विश्लेषण',href:'/analytics'},
  {id:'leaderboard',icon:'🏆',en:'Leaderboard',hi:'लीडरबोर्ड',href:'/leaderboard'},
  {id:'certificate',icon:'🎖️',en:'Certificates',hi:'प्रमाणपत्र',href:'/certificate'},
  {id:'admit-card',icon:'🪪',en:'Admit Card',hi:'प्रवेश पत्र',href:'/admit-card'},
  {id:'pyq-bank',icon:'📚',en:'PYQ Bank',hi:'पिछले वर्ष के प्रश्न',href:'/pyq-bank'},
  {id:'mini-tests',icon:'⚡',en:'Mini Tests',hi:'मिनी टेस्ट',href:'/mini-tests'},
  {id:'attempt-history',icon:'🕐',en:'Attempt History',hi:'परीक्षा इतिहास',href:'/attempt-history'},
  {id:'revision',icon:'🧠',en:'Smart Revision',hi:'स्मार्ट रिवीजन',href:'/revision'},
  {id:'goals',icon:'🎯',en:'My Goals',hi:'मेरे लक्ष्य',href:'/goals'},
  {id:'compare',icon:'⚖️',en:'Compare',hi:'तुलना करें',href:'/compare'},
  {id:'announcements',icon:'📢',en:'Announcements',hi:'घोषणाएं',href:'/announcements'},
  {id:'doubt',icon:'💬',en:'Doubt & Query',hi:'संदेह और प्रश्न',href:'/doubt'},
  {id:'parent-portal',icon:'👨‍👩‍👧',en:'Parent Portal',hi:'अभिभावक पोर्टल',href:'/parent-portal'},
  {id:'support',icon:'🛟',en:'Support',hi:'सहायता',href:'/support'},
  {id:'profile',icon:'👤',en:'Profile',hi:'प्रोफ़ाइल',href:'/profile'},
]

export default function StudentShell({ pageKey, children }:{ pageKey:string; children:ReactNode }) {
  const router = useRouter()
  const [mounted,  setMounted]  = useState(false)
  const [lang,     setLang]     = useState<'en'|'hi'>('en')
  const [dm,       setDm]       = useState(true)
  const [sideOpen, setSide]     = useState(false)
  const [user,     setUser]     = useState<any>(null)
  const [token,    setTok]      = useState('')
  const [role,     setRole]     = useState('student')
  const [toast2,   setToast2]   = useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)

  const toast = useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{
    setToast2({msg,tp}); setTimeout(()=>setToast2(null),4000)
  },[])

  useEffect(()=>{
    const tk=gt(); if(!tk){router.replace('/login');return}
    setTok(tk); setRole(gr())
    try {
      const sl=localStorage.getItem('pr_lang') as 'en'|'hi'|null
      if(sl) setLang(sl)
      if(localStorage.getItem('pr_theme')==='light') setDm(false)
    } catch {}
    fetch(`${API}/api/auth/me`,{headers:{Authorization:`Bearer ${tk}`}})
      .then(r=>r.ok?r.json():null).then(d=>{ if(d?._id) setUser(d) }).catch(()=>{})
    setMounted(true)
  },[router])

  if(!mounted) return null

  const bg  = dm?'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)':'radial-gradient(ellipse at 20% 50%,#E8F4FF 0%,#C9E0FF 60%,#A8CCFF 100%)'
  const bdr = dm?C.border:C.borderL
  const txt = dm?C.text:C.textL
  const sub = dm?C.sub:C.subL

  return (
    <Ctx.Provider value={{ lang, darkMode:dm, user, toast, token, role }}>
      <div style={{minHeight:'100vh',background:bg,color:txt,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden'}}>
        <style>{`
          @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
          @keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
          @keyframes pulse{0%,100%{opacity:.5}50%{opacity:1}}
          @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-6px)}}
          @keyframes glow{0%,100%{box-shadow:0 0 8px rgba(77,159,255,.3)}50%{box-shadow:0 0 20px rgba(77,159,255,.6)}}
          *{box-sizing:border-box}
          ::-webkit-scrollbar{width:4px}::-webkit-scrollbar-thumb{background:rgba(77,159,255,.4);border-radius:4px}
          .nav-link:hover{background:rgba(77,159,255,.14)!important;color:#4D9FFF!important}
          .card-h:hover{border-color:rgba(77,159,255,.5)!important;transform:translateY(-2px);transition:all .2s}
          .btn-p{background:linear-gradient(135deg,#4D9FFF,#0055CC);color:#fff;border:none;border-radius:10px;padding:11px 22px;cursor:pointer;font-weight:700;font-size:13px;font-family:Inter,sans-serif;transition:all .2s}
          .btn-p:hover{opacity:.88;transform:translateY(-1px)}
          .btn-g{background:rgba(77,159,255,.12);color:#4D9FFF;border:1px solid rgba(77,159,255,.3);border-radius:10px;padding:9px 18px;cursor:pointer;font-weight:600;font-size:12px;font-family:Inter,sans-serif}
          .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,.4);background:rgba(0,22,40,.5);color:#E8F4FF;font-size:12px;font-weight:600;cursor:pointer;font-family:Inter,sans-serif}
          input,textarea,select{color-scheme:dark}
        `}</style>

        {/* Universe BG */}
        <div style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0,overflow:'hidden'}}>
          {Array.from({length:100},(_,i)=>(
            <div key={i} style={{position:'absolute',left:`${(i*137.5)%100}%`,top:`${(i*97.3)%100}%`,width:`${i%3===0?2:1.2}px`,height:`${i%3===0?2:1.2}px`,borderRadius:'50%',background:`rgba(200,215,255,${.1+i%8*.06})`,animation:`pulse ${2+i%4}s ${(i%20)/10}s infinite`}}/>
          ))}
          <div style={{position:'absolute',left:'5%',top:'15%',width:400,height:400,borderRadius:'50%',background:'radial-gradient(circle,rgba(77,159,255,.04),transparent 70%)'}}/>
          <div style={{position:'absolute',right:'10%',bottom:'20%',width:350,height:350,borderRadius:'50%',background:'radial-gradient(circle,rgba(167,139,250,.03),transparent 70%)'}}/>
          <div style={{position:'absolute',top:-60,left:-60,fontSize:300,color:'rgba(77,159,255,.025)',lineHeight:1,userSelect:'none'}}>⬡</div>
          <div style={{position:'absolute',bottom:-60,right:-60,fontSize:300,color:'rgba(77,159,255,.025)',lineHeight:1,userSelect:'none'}}>⬡</div>
        </div>

        {/* Toast */}
        {toast2&&(
          <div style={{position:'fixed',top:0,left:0,right:0,zIndex:9999,padding:'14px 24px',fontWeight:700,fontSize:13,background:toast2.tp==='s'?'linear-gradient(90deg,#00C48C,#00a87a)':toast2.tp==='w'?'linear-gradient(90deg,#FFB84D,#e6a200)':'linear-gradient(90deg,#FF4D4D,#cc0000)',color:toast2.tp==='w'?'#000':'#fff',textAlign:'center',boxShadow:'0 4px 30px rgba(0,0,0,.5)',animation:'fadeIn .3s ease'}}>
            {toast2.tp==='e'?'❌':toast2.tp==='w'?'⚠️':'✅'} {toast2.msg}
          </div>
        )}

        {/* Sidebar Overlay */}
        {sideOpen&&<div onClick={()=>setSide(false)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,.5)',zIndex:49,backdropFilter:'blur(2px)'}}/>}

        {/* Sidebar */}
        <div style={{position:'fixed',top:0,left:0,width:264,height:'100vh',background:'rgba(0,6,18,.97)',borderRight:`1px solid ${bdr}`,zIndex:50,overflowY:'auto',padding:'0 0 24px',transform:sideOpen?'translateX(0)':'translateX(-100%)',transition:'transform .28s cubic-bezier(.4,0,.2,1)',backdropFilter:'blur(20px)',boxShadow:'4px 0 30px rgba(0,0,0,.5)'}}>
          <div style={{padding:'20px 20px 16px',borderBottom:`1px solid ${bdr}`,position:'sticky',top:0,background:'rgba(0,6,18,.97)'}}>
            <div style={{display:'flex',alignItems:'center',gap:10}}>
              <PRLogo size={36}/>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#fff)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</div>
                <div style={{fontSize:11,color:'#C0C8D8',fontWeight:600,display:'flex',alignItems:'center',gap:4,marginTop:1}}>
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none"><path d="M12 2a5 5 0 110 10A5 5 0 0112 2zm0 12c-5.33 0-8 2.67-8 4v1h16v-1c0-1.33-2.67-4-8-4z" fill="#C0C8D8"/></svg>
                  <span>{role==='parent'?(lang==='en'?'Parent':'अभिभावक'):(lang==='en'?'Student':'छात्र')}</span>
                </div>
              </div>
            </div>
            <button onClick={()=>setSide(false)} style={{position:'absolute',top:16,right:14,background:'none',border:'none',color:sub,cursor:'pointer',fontSize:18}}>✕</button>
          </div>
          <div style={{padding:'8px 10px'}}>
            {NAV.map(n=>(
              <a key={n.id} href={n.href} className="nav-link" onClick={()=>setSide(false)} style={{display:'flex',alignItems:'center',gap:10,padding:'9px 12px',borderRadius:9,textDecoration:'none',color:pageKey===n.id?'#4D9FFF':sub,background:pageKey===n.id?'rgba(77,159,255,.14)':'transparent',fontWeight:pageKey===n.id?700:400,fontSize:13,borderLeft:pageKey===n.id?'3px solid #4D9FFF':'3px solid transparent',marginBottom:2,transition:'all .2s'}}>
                <span style={{fontSize:15,width:20,textAlign:'center'}}>{n.icon}</span>
                <span>{lang==='en'?n.en:n.hi}</span>
              </a>
            ))}
          </div>
          <div style={{margin:'16px 14px 0',padding:'14px',background:'rgba(77,159,255,.06)',borderRadius:12,border:`1px solid ${bdr}`,textAlign:'center'}}>
            <div style={{fontSize:10,color:'#00C48C',fontWeight:600}}>🟢 {lang==='en'?'All Systems Live':'सभी सिस्टम लाइव'}</div>
          </div>
        </div>

        {/* Topbar */}
        <div style={{position:'sticky',top:0,zIndex:40,background:dm?'rgba(0,6,18,.95)':'rgba(232,244,255,.95)',backdropFilter:'blur(20px)',borderBottom:`1px solid ${bdr}`,height:58,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 16px',boxShadow:'0 2px 20px rgba(0,0,0,.3)'}}>
          <div style={{display:'flex',alignItems:'center',gap:10}}>
            <button onClick={()=>setSide(true)} style={{background:'none',border:'none',color:txt,fontSize:22,cursor:'pointer',padding:'4px 6px',borderRadius:6}}>☰</button>
            <div style={{display:'flex',alignItems:'center',gap:8}}>
              <PRLogo size={30}/>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,background:'linear-gradient(90deg,#4D9FFF,#fff)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1}}>ProveRank</div>
                <div style={{fontSize:9,color:'#C0C8D8',fontWeight:600,letterSpacing:.5}}>{role==='parent'?(lang==='en'?'PARENT':'अभिभावक'):(lang==='en'?'STUDENT':'छात्र')}</div>
              </div>
            </div>
          </div>
          <div style={{display:'flex',alignItems:'center',gap:7}}>
            <button className="tbtn" onClick={()=>{ const n=lang==='en'?'hi':'en'; setLang(n); try{localStorage.setItem('pr_lang',n)}catch{} }}>{lang==='en'?'हि':'EN'}</button>
            <button className="tbtn" onClick={()=>{ const n=!dm; setDm(n); try{localStorage.setItem('pr_theme',n?'dark':'light')}catch{} }}>{dm?'☀️':'🌙'}</button>
            <a href="/announcements" style={{background:'none',border:`1px solid ${bdr}`,borderRadius:8,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',textDecoration:'none',fontSize:15,color:txt}}>🔔</a>
            <button onClick={()=>{ca();router.replace('/login')}} style={{background:'rgba(255,77,77,.12)',color:'#FF4D4D',border:'1px solid rgba(255,77,77,.25)',borderRadius:8,padding:'6px 11px',cursor:'pointer',fontWeight:700,fontSize:11,fontFamily:'Inter,sans-serif'}}>
              {lang==='en'?'Logout':'लॉगआउट'}
            </button>
          </div>
        </div>

        {/* Page Content */}
        <div style={{position:'relative',zIndex:1,padding:'24px 16px 48px',maxWidth:1100,margin:'0 auto',animation:'fadeIn .4s ease'}}>
          {children}
        </div>
      </div>
    </Ctx.Provider>
  )
}
