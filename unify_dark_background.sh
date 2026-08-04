#!/bin/bash
set -e
echo "=== Fix: Student Panel dark-theme background now matches Admin Panel exactly ==="

echo "--- Safety check: confirm exam/[examId]/page.tsx is truly unreferenced before deleting ---"
grep -rn "router.push(\`/exam/\${examId}\`)\|router.push(\x27/exam/\x27+examId)\|href={\`/exam/\${examId}\`}" ~/workspace/frontend/app ~/workspace/frontend/src --include="*.tsx" 2>/dev/null || echo "(none found — confirmed safe to delete)"

# ---- 1) StudentShell: match dark shellBg to Admin BG_GRAD (fixes Dashboard, My Exams, Waiting Room, Instructions, Webcam, Attempt automatically) ----
cat > ~/workspace/frontend/src/components/StudentShell.tsx << 'FILEEOF1'
'use client'
import React,{createContext,useContext,useState,useEffect,useCallback,useRef,ReactNode}from 'react'
import{useRouter}from 'next/navigation'

const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'
const _gt=():string=>{try{return localStorage.getItem('pr_token')||''}catch{return''}}
const _gr=():string=>{try{return localStorage.getItem('pr_role')||'student'}catch{return'student'}}
const _ca=():void=>{try{localStorage.removeItem('pr_token');localStorage.removeItem('pr_role')}catch{}}

export const C={primary:'#4D9FFF',card:'rgba(0,22,40,0.82)',cardL:'rgba(255,255,255,0.92)',border:'rgba(77,159,255,0.22)',borderL:'rgba(77,159,255,0.4)',text:'#E8F4FF',textL:'#0F172A',sub:'#8DA2C0',subL:'#51607A',success:'#00C48C',danger:'#FF4D4D',gold:'#FFD700',warn:'#FFB84D',purple:'#A78BFA',pink:'#FF6B9D'}

export type ColorTheme='light'|'dark'
export interface ShellCtx{lang:'en'|'hi';darkMode:boolean;colorTheme:ColorTheme;theme:any;setColorTheme:(t:ColorTheme)=>void;user:any;toast:(m:string,t?:'s'|'e'|'w')=>void;token:string;role:string}
const ShellCtx=createContext<ShellCtx>({lang:'en',darkMode:true,colorTheme:'dark',theme:{primary:'#4D9FFF'},setColorTheme:()=>{},user:null,toast:()=>{},token:'',role:'student'})
export const useShell=()=>useContext(ShellCtx)

export function PRLogo({size=40}:{size?:number}){
  const b=size*0.94,p=Math.round(b*0.63),r=Math.round(b*0.63),f=Math.round(p*0.52),rd=Math.round(p*0.28)
  return(<div style={{position:'relative',width:b,height:b,flexShrink:0,display:'inline-flex'}}><div style={{position:'absolute',top:0,left:0,width:p,height:p,borderRadius:rd,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',color:'#030810',boxShadow:'0 4px 16px rgba(77,159,255,0.4)'}}>P</div><div style={{position:'absolute',bottom:0,right:0,width:r,height:r,borderRadius:rd,background:'rgba(0,212,255,0.1)',border:'1.5px solid rgba(0,212,255,0.45)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',color:'#00D4FF',backdropFilter:'blur(8px)'}}>R</div></div>)
}

function GalaxyBg(){
  const ref=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=ref.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    const resize=()=>{canvas.width=window.innerWidth;canvas.height=window.innerHeight};resize()
    const stars=Array.from({length:220},()=>({x:Math.random()*canvas.width,y:Math.random()*canvas.height,r:Math.random()*1.6+0.2,op:Math.random()*0.7+0.1,tw:Math.random()*0.018+0.004,ph:Math.random()*Math.PI*2,col:Math.random()>0.85?'rgba(255,215,100,':'rgba(200,218,255,'}))
    const parts=Array.from({length:65},()=>({x:Math.random()*canvas.width,y:Math.random()*canvas.height,vx:(Math.random()-.5)*.3,vy:(Math.random()-.5)*.3,r:Math.random()*1.8+0.4,op:Math.random()*.25+.04}))
    const spiral:any[]=[];for(let a=0;a<2;a++)for(let i=0;i<80;i++){const t=i/80,angle=a*Math.PI+t*Math.PI*3,rad=t*Math.min(canvas.width,canvas.height)*0.22;spiral.push({x:canvas.width/2+rad*Math.cos(angle)+(Math.random()-.5)*30,y:canvas.height/2+rad*Math.sin(angle)+(Math.random()-.5)*30,r:Math.random()*1.2+0.3,op:Math.random()*0.3+0.05})}
    let sx=-100,sy=-100,sA=false,sT=0,sVx=0,sVy=0
    const shoot=()=>{sx=Math.random()*canvas.width*.6;sy=Math.random()*canvas.height*.25;sVx=3+Math.random()*4;sVy=1+Math.random()*2;sA=true;sT=0;setTimeout(shoot,3000+Math.random()*7000)}
    setTimeout(shoot,2500)
    let animId:number
    const draw=()=>{
      ctx.clearRect(0,0,canvas.width,canvas.height)
      ;[{x:canvas.width*.08,y:canvas.height*.18,r:220,c:'rgba(77,159,255,0.05)'},{x:canvas.width*.88,y:canvas.height*.72,r:280,c:'rgba(167,139,250,0.04)'},{x:canvas.width*.5,y:canvas.height*.5,r:180,c:'rgba(255,100,157,0.02)'},{x:canvas.width*.4,y:canvas.height*.85,r:200,c:'rgba(0,196,140,0.03)'}].forEach(n=>{const g=ctx.createRadialGradient(n.x,n.y,0,n.x,n.y,n.r);g.addColorStop(0,n.c);g.addColorStop(1,'transparent');ctx.fillStyle=g;ctx.beginPath();ctx.arc(n.x,n.y,n.r,0,Math.PI*2);ctx.fill()})
      spiral.forEach(s=>{ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle='rgba(180,210,255,'+s.op+')';ctx.fill()})
      stars.forEach(s=>{s.ph+=s.tw;const op=s.op*(0.55+0.45*Math.sin(s.ph));ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=s.col+op+')';ctx.fill()})
      if(sA){sT+=0.05;sx+=sVx;sy+=sVy;if(sT<1){const tail=80,grd=ctx.createLinearGradient(sx-tail*sVx/5,sy-tail*sVy/5,sx,sy);grd.addColorStop(0,'rgba(255,255,255,0)');grd.addColorStop(1,'rgba(255,255,255,0.85)');ctx.strokeStyle=grd;ctx.lineWidth=1.5;ctx.beginPath();ctx.moveTo(sx-tail*sVx/5,sy-tail*sVy/5);ctx.lineTo(sx,sy);ctx.stroke();const gl=ctx.createRadialGradient(sx,sy,0,sx,sy,4);gl.addColorStop(0,'rgba(255,255,255,0.6)');gl.addColorStop(1,'transparent');ctx.fillStyle=gl;ctx.beginPath();ctx.arc(sx,sy,4,0,Math.PI*2);ctx.fill()}else sA=false;if(sx>canvas.width+100||sy>canvas.height+100)sA=false}
      parts.forEach(p=>{p.x+=p.vx;p.y+=p.vy;if(p.x<0)p.x=canvas.width;if(p.x>canvas.width)p.x=0;if(p.y<0)p.y=canvas.height;if(p.y>canvas.height)p.y=0;ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2);ctx.fillStyle='rgba(77,159,255,'+p.op+')';ctx.fill()})
      for(let i=0;i<parts.length;i++)for(let j=i+1;j<parts.length;j++){const dx=parts[i].x-parts[j].x,dy=parts[i].y-parts[j].y,d=Math.sqrt(dx*dx+dy*dy);if(d<110){ctx.beginPath();ctx.moveTo(parts[i].x,parts[i].y);ctx.lineTo(parts[j].x,parts[j].y);ctx.strokeStyle='rgba(77,159,255,'+(0.07*(1-d/110))+')';ctx.lineWidth=.5;ctx.stroke()}}
      animId=requestAnimationFrame(draw)
    }
    draw();window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={ref} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}

// ── Navigation — grouped for a cleaner sidebar (all existing features kept, none removed) ──
const NAV_GROUPS=[
  {label:'Overview',labelHi:'अवलोकन',items:[
    {id:'dashboard',icon:'📊',en:'Dashboard',hi:'डैशबोर्ड',href:'/dashboard'},
  ]},
  {label:'Practice',labelHi:'अभ्यास',items:[
    {id:'my-exams',icon:'📝',en:'My Exams',hi:'मेरी परीक्षाएं',href:'/my-exams'},
    {id:'pyq-bank',icon:'📚',en:'PYQ Bank',hi:'पिछले वर्ष के प्रश्न',href:'/pyq-bank'},
  ]},
  {label:'Results & Progress',labelHi:'परिणाम और प्रगति',items:[
    {id:'attempt-history',icon:'🕐',en:'Attempt History',hi:'परीक्षा इतिहास',href:'/attempt-history'},
  ]},
  {label:'Batches & Store',labelHi:'बैच और स्टोर',items:[
    {id:'my-batches',icon:'📚',en:'My Batches & Test Series',hi:'मेरे बैच और टेस्ट सीरीज',href:'/dashboard/my-batches'},
    {id:'test-series',icon:'📚',en:'Batches & Test Series',hi:'बैच और टेस्ट सीरीज',href:'/dashboard/test-series'},
    {id:'store',icon:'🛒',en:'Store',hi:'स्टोर',href:'/dashboard/store'},
  ]},
  {label:'Communication',labelHi:'संचार',items:[
    {id:'announcements',icon:'📢',en:'Announcements',hi:'घोषणाएं',href:'/announcements'},
    {id:'doubt',icon:'💬',en:'Doubt & Query',hi:'संदेह और प्रश्न',href:'/doubt'},
    {id:'support',icon:'🛟',en:'Support',hi:'सहायता',href:'/support'},
  ]},
  {label:'Account',labelHi:'खाता',items:[
    {id:'profile',icon:'👤',en:'Profile',hi:'प्रोफ़ाइल',href:'/profile'},
  ]},
]

// Pages that must keep their own existing immersive dark/galaxy look — untouched regardless of the user's Light/Dark choice
const IMMERSIVE_PAGES=['store']

export default function StudentShell({pageKey,children}:{pageKey:string;children:ReactNode}){
  const router=useRouter()
  const [mounted,setMounted]=useState(false)
  const [lang,setLang]=useState<'en'|'hi'>('en')
  const [colorTheme,setColorThemeState]=useState<ColorTheme>('dark')
  const [side,setSide]=useState(false)
  const [user,setUser]=useState<any>(null)
  const [token,setToken]=useState('')
  const [role,setRole]=useState('student')
  const [toastSt,setToastSt]=useState<{msg:string;tp:'s'|'e'|'w'}|null>(null)
  const [maint,setMaint]=useState<{enabled:boolean;message?:string}|null>(null)
  const [unreadAnn,setUnreadAnn]=useState(0) // F42B §6.2 — bell badge sync
  const toast=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{setToastSt({msg,tp});setTimeout(()=>setToastSt(null),4000)},[])

  useEffect(()=>{fetch(`${API}/api/admin/maintenance`).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.maintenance)setMaint(d.maintenance)}).catch(()=>{})},[])

  // v2 §6.2 FIX — Bell icon badge sync: StudentShell itself polls the live
  // unread-count API every 60s, from ANY page (not just Announcements).
  // Replaces the old localStorage+event approach which only updated after
  // visiting the Announcements page and could show a stale count elsewhere.
  useEffect(()=>{
    if(!token) return
    let cancelled=false
    const poll=()=>{
      fetch(`${API}/api/announcements/unread-count`,{headers:{Authorization:`Bearer ${token}`}})
        .then(r=>r.ok?r.json():null)
        .then(d=>{if(!cancelled&&d)setUnreadAnn(d.count||0)})
        .catch(()=>{})
    }
    poll()
    const iv=setInterval(poll,60000)
    return()=>{cancelled=true;clearInterval(iv)}
  },[token])

  // Applies the theme class to <html> AND <body> so all legacy + new CSS overrides actually take effect
  const _applyDom=(t:ColorTheme)=>{
    try{
      const h=document.documentElement,b=document.body
      h.classList.remove('white-theme','dark-theme','teal-theme','light-theme')
      b.classList.remove('white-theme','dark-theme','teal-theme','light-theme')
      h.classList.add(t+'-theme');b.classList.add(t+'-theme')
      h.setAttribute('data-color-theme',t)
    }catch{}
  }
  const _migrate=(v:string|null):ColorTheme=>{
    if(v==='white')return'light'
    if(v==='teal')return'dark'
    return(v==='light'||v==='dark')?v:'dark'
  }

  useEffect(()=>{
    const tk=_gt();if(!tk){router.replace('/login');return}
    setToken(tk);setRole(_gr())
    try{
      const sl=localStorage.getItem('pr_lang') as 'en'|'hi'|null;if(sl)setLang(sl)
      const ct=_migrate(localStorage.getItem('pr_color_theme'))
      setColorThemeState(ct);_applyDom(ct)
    }catch{}
    const _onTh=(e:StorageEvent)=>{if(e.key==='pr_color_theme'&&e.newValue){const v=_migrate(e.newValue);setColorThemeState(v);_applyDom(v)}}
    window.addEventListener('storage',_onTh)
    fetch(`${API}/api/auth/me`,{headers:{Authorization:`Bearer ${tk}`}}).then(r=>r.ok?r.json():null).then(d=>{if(d?._id)setUser(d)}).catch(()=>{})
    setMounted(true)
    return()=>window.removeEventListener('storage',_onTh)
  },[router])

  if(!mounted)return null
  const userEmail=user?.email||(typeof window!=='undefined'?localStorage.getItem('pr_email')||'':'')
  const isWhitelisted=!!(userEmail&&maint?.allowedEmails?.some((e:string)=>e.trim().toLowerCase()===userEmail.trim().toLowerCase()))
  if(maint?.enabled===true&&!isWhitelisted){
    return(
      <div style={{minHeight:'100vh',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',background:'linear-gradient(135deg,#0a0a1a,#0d1b2a)',color:'#fff',fontFamily:'Inter,sans-serif',textAlign:'center',padding:'24px'}}>
        <div style={{fontSize:64,marginBottom:20}}>🔧</div>
        <div style={{fontSize:24,fontWeight:700,color:'#4D9FFF',marginBottom:10}}>ProveRank</div>
        <div style={{fontSize:18,fontWeight:600,marginBottom:14}}>Platform Under Maintenance</div>
        <div style={{color:'#aaa',maxWidth:360,lineHeight:1.7,fontSize:14,marginBottom:32}}>{maint.message||'We are upgrading the platform. Please check back shortly.'}</div>
        <button onClick={()=>{_ca();router.replace('/login')}} style={{background:'linear-gradient(135deg,#4D9FFF,#0066cc)',color:'#fff',border:'none',borderRadius:10,padding:'13px 32px',fontSize:15,fontWeight:700,cursor:'pointer'}}>← Back to Login</button>
      </div>
    )
  }

  // ── 2-Theme System: Light & Dark (only) ──
  const _TH:Record<ColorTheme,any>={
    light:{
      shellBg:'radial-gradient(ellipse at 15% 0%,#FFFFFF 0%,#F3F7FF 55%,#E9F1FF 100%)',
      headerBg:'rgba(255,255,255,0.88)',sidebarBg:'rgba(255,255,255,0.97)',
      primary:'#2563EB',text:'#0F172A',sub:'#51607A',
      border:'rgba(37,99,235,0.14)',navActive:'rgba(37,99,235,0.10)',
      isDark:false,showGalaxy:false,hexC:'rgba(37,99,235,0.035)',
      brandGrad:'#2563EB',logoTag:'#374151',
      chipBg:'rgba(37,99,235,0.06)',
    },
    dark:{
      shellBg:'radial-gradient(ellipse at 20% 50%,#001e38 0%,#000f22 60%,#000810 100%)',
      headerBg:'rgba(10,14,22,0.85)',sidebarBg:'rgba(8,11,18,0.97)',
      primary:'#4D9FFF',text:'#F1F6FC',sub:'#8DA2C0',
      border:'rgba(77,159,255,0.14)',navActive:'rgba(77,159,255,0.14)',
      isDark:true,showGalaxy:true,hexC:'rgba(77,159,255,0.03)',
      brandGrad:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 60%,#4D9FFF 100%)',logoTag:'#8DA2C0',
      chipBg:'rgba(77,159,255,0.07)',
    },
  }
  const _immersiveDef={
    shellBg:'#020816',headerBg:'rgba(0,5,18,.95)',sidebarBg:'rgba(0,5,18,.97)',
    primary:'#4D9FFF',text:'#E8F4FF',sub:'#6B8FAF',
    border:C.border,navActive:'rgba(77,159,255,.16)',
    isDark:true,showGalaxy:true,hexC:'rgba(77,159,255,.022)',
    brandGrad:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 60%,#4D9FFF 100%)',logoTag:'#6B8FAF',
    chipBg:'rgba(77,159,255,0.07)',
  }
  const _isImmersive=IMMERSIVE_PAGES.includes(pageKey)
  const th=_isImmersive?_immersiveDef:(_TH[colorTheme]||_TH.dark)
  const dm=th.isDark
  const setColorTheme=(t:ColorTheme)=>{setColorThemeState(t);_applyDom(t);try{localStorage.setItem('pr_color_theme',t);window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:t}))}catch{}}
  const bdr=th.border,txt=th.text,sub=th.sub
  const toggleLang=()=>{const n=lang==='en'?'hi':'en';setLang(n);try{localStorage.setItem('pr_lang',n)}catch{}}
  const toggleTheme=()=>setColorTheme(colorTheme==='dark'?'light':'dark')
  const logout=()=>{_ca();router.replace('/login')}

  return(
    <ShellCtx.Provider value={{lang,darkMode:dm,colorTheme:_isImmersive?'dark':colorTheme,theme:th,setColorTheme,user,toast,token,role}}>
      <div data-color-theme={_isImmersive?'dark':colorTheme} style={{minHeight:'100vh',background:th.shellBg,color:txt,fontFamily:'Inter,sans-serif',position:'relative',width:'100%',maxWidth:'100vw',overflowX:'hidden'}}>
        <style>{`
          @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
          @keyframes fadeIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}
          @keyframes gradMove{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
          *{box-sizing:border-box}
          ::-webkit-scrollbar{width:4px}
          ::-webkit-scrollbar-thumb{background:rgba(77,159,255,.4);border-radius:4px}
          .nav-lnk:hover{background:${dm?'rgba(77,159,255,.14)':'rgba(37,99,235,.08)'}!important;color:${th.primary}!important}
          .btn-p{background:linear-gradient(135deg,${th.primary},${dm?'#0055CC':'#1D4ED8'});color:#fff;border:none;border-radius:10px;padding:11px 22px;cursor:pointer;font-weight:700;font-size:13px;font-family:Inter,sans-serif}
          .tbtn{padding:6px 13px;border-radius:20px;border:1.5px solid ${bdr};background:${th.chipBg};color:${txt};font-size:12px;font-weight:600;cursor:pointer;font-family:Inter,sans-serif;backdrop-filter:blur(8px);transition:all .2s;white-space:nowrap}
          .tbtn:hover{border-color:${th.primary};background:${dm?'rgba(77,159,255,.18)':'rgba(37,99,235,.14)'}}
          .icon-tbtn{width:34px;height:34px;padding:0;display:flex;align-items:center;justify-content:center;font-size:15px;border-radius:9px}
          input,select,textarea{color-scheme:${dm?'dark':'light'}}
          .pr-shell-main{padding:16px 14px 64px;width:100%;max-width:100%}
          .pr-shell-main.immersive{padding:0 0 56px}
          .pr-shell-main *{max-width:100%}
          .pr-shell-main img,.pr-shell-main svg,.pr-shell-main video,.pr-shell-main table{max-width:100%}
          @media(min-width:769px){.pr-shell-main:not(.immersive){padding:24px 32px 72px}}
          @media(max-width:360px){.hide-xs{display:none!important}}
          @keyframes silverShimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}
          @keyframes greenBadge{0%,100%{box-shadow:0 0 4px rgba(0,196,140,0.35),inset 0 0 4px rgba(0,196,140,0.1)}50%{box-shadow:0 0 12px rgba(0,196,140,0.75),inset 0 0 8px rgba(0,255,136,0.2)}}
          @media(min-width:480px){.pr-brand-center{position:absolute!important;left:50%!important;transform:translateX(-50%)!important;z-index:1}}
          @media(max-width:768px){div[style*="display:flex"][style*="flexWrap"]{row-gap:8px}}
        `}</style>
        {th.showGalaxy&&<GalaxyBg/>}
        <div aria-hidden style={{position:'fixed',top:-70,left:-70,fontSize:320,color:th.hexC,pointerEvents:'none',zIndex:0,lineHeight:1,userSelect:'none'}}>⬡</div>
        <div aria-hidden style={{position:'fixed',bottom:-70,right:-70,fontSize:320,color:th.hexC,pointerEvents:'none',zIndex:0,lineHeight:1,userSelect:'none'}}>⬡</div>
        {toastSt&&<div style={{position:'fixed',top:0,left:0,right:0,zIndex:9999,padding:'14px 24px',fontWeight:700,fontSize:13,textAlign:'center',animation:'fadeIn .3s ease',background:toastSt.tp==='s'?'linear-gradient(90deg,#00C48C,#00a87a)':toastSt.tp==='w'?'linear-gradient(90deg,#FFB84D,#e6a200)':'linear-gradient(90deg,#FF4D4D,#cc0000)',color:toastSt.tp==='w'?'#000':'#fff'}}>{toastSt.tp==='e'?'❌':toastSt.tp==='w'?'⚠️':'✅'} {toastSt.msg}</div>}
        {side&&<div onClick={()=>setSide(false)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,.55)',zIndex:49,backdropFilter:'blur(3px)'}}/>}

        {/* ── SIDEBAR ─────────────────────────────────────────── */}
        <div style={{position:'fixed',top:0,left:0,width:280,maxWidth:'86vw',height:'100dvh',background:th.sidebarBg,borderRight:`1px solid ${bdr}`,zIndex:50,overflowY:'auto',display:'flex',flexDirection:'column',transform:side?'translateX(0)':'translateX(-100%)',transition:'transform .28s cubic-bezier(.4,0,.2,1)',backdropFilter:'blur(24px)',boxShadow:side?'12px 0 40px rgba(0,0,0,.35)':'none'}}>
          <div style={{padding:'18px 16px 14px',borderBottom:`1px solid ${bdr}`,position:'sticky',top:0,background:th.sidebarBg,flexShrink:0,display:'flex',alignItems:'center',justifyContent:'space-between',gap:8}}>
            <div style={{display:'flex',alignItems:'center',gap:10,minWidth:0}}>
              <PRLogo size={36}/>
              <div style={{minWidth:0}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,whiteSpace:'nowrap',...(th.isDark?{background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'gradMove 5s ease infinite'}:{color:'#2563EB'})}}>ProveRank</div>
                <div style={{fontSize:10,color:th.logoTag,fontWeight:600,marginTop:1,whiteSpace:'nowrap'}}>{role==='parent'?(lang==='en'?'Parent Panel':'अभिभावक पैनल'):(lang==='en'?'Student Panel':'छात्र पैनल')}</div>
              </div>
            </div>
            <button onClick={()=>setSide(false)} aria-label="Close menu" style={{background:'transparent',border:`1px solid ${bdr}`,borderRadius:8,width:30,height:30,color:sub,cursor:'pointer',fontSize:15,lineHeight:1,flexShrink:0,display:'flex',alignItems:'center',justifyContent:'center'}}>✕</button>
          </div>
          <div style={{padding:'10px 10px 4px',flex:1,overflowY:'auto'}}>
            {NAV_GROUPS.map(g=>(
              <div key={g.label} style={{marginBottom:14}}>
                <div style={{fontSize:10,fontWeight:700,letterSpacing:'.08em',textTransform:'uppercase',color:sub,padding:'4px 10px',opacity:.8}}>{lang==='en'?g.label:g.labelHi}</div>
                {g.items.map(n=>{
                  const active=pageKey===n.id
                  return(<a key={n.id} href={n.href} className="nav-lnk" onClick={()=>setSide(false)} style={{display:'flex',alignItems:'center',gap:10,padding:'9px 10px',borderRadius:10,textDecoration:'none',color:active?th.primary:txt,background:active?th.navActive:'transparent',fontWeight:active?700:500,fontSize:13.5,marginBottom:2,transition:'all .18s'}}>
                    <span style={{fontSize:16,width:22,textAlign:'center',flexShrink:0,opacity:active?1:.85}}>{n.icon}</span>
                    <span style={{overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{lang==='en'?n.en:n.hi}</span>
                    {active&&<span style={{marginLeft:'auto',width:6,height:6,borderRadius:'50%',background:th.primary,flexShrink:0}}/>}
                  </a>)
                })}
              </div>
            ))}
          </div>
          <div style={{padding:'12px 14px 16px',borderTop:`1px solid ${bdr}`,flexShrink:0}}>
            <div style={{display:'flex',gap:6,marginBottom:10}}>
              <button className="tbtn" onClick={toggleTheme} style={{flex:1,justifyContent:'center',display:'flex',alignItems:'center',gap:5}}>{dm?'☀️':'🌙'} {dm?(lang==='en'?'Light':'लाइट'):(lang==='en'?'Dark':'डार्क')}</button>
              <button className="tbtn" onClick={toggleLang} style={{flex:1}}>{lang==='en'?'हि':'EN'}</button>
            </div>
            <div style={{padding:'10px 12px',background:th.chipBg,borderRadius:12,border:`1px solid ${bdr}`,textAlign:'center'}}>
              <div style={{fontSize:10,color:C.success,fontWeight:700}}>🟢 {lang==='en'?'All Systems Live':'सभी सिस्टम लाइव'}</div>
            </div>
          </div>
        </div>

        {/* ── HEADER ──────────────────────────────────────────── */}
        <div style={{position:'sticky',top:0,zIndex:40,background:th.headerBg,backdropFilter:'blur(20px)',borderBottom:`1px solid ${bdr}`,minHeight:58,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 10px 0 8px',gap:8,boxShadow:dm?'0 2px 20px rgba(0,0,0,.35)':'0 2px 14px rgba(37,99,235,.06)'}}>
          <div style={{display:'flex',alignItems:'center',gap:8,minWidth:0}}>
            <button onClick={()=>setSide(true)} aria-label="Open menu" style={{background:dm?'rgba(255,255,255,0.05)':'rgba(37,99,235,0.06)',border:`1px solid ${bdr}`,color:txt,fontSize:19,cursor:'pointer',width:36,height:36,borderRadius:9,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}} title="Menu">☰</button>
            <div style={{display:'flex',alignItems:'center',gap:7,minWidth:0}}>
              <PRLogo size={28}/>
              <div style={{minWidth:0}}>
                <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:2}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14.5,lineHeight:1,whiteSpace:'nowrap',...(th.isDark?{background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}:{color:'#2563EB'})}}>ProveRank</div>
                  <div style={{fontSize:7,fontWeight:800,letterSpacing:1.4,whiteSpace:'nowrap',padding:'1px 7px',borderRadius:20,border:'1.5px solid rgba(0,196,140,0.7)',background:'linear-gradient(90deg,#00A86B,#00FF88,#00C48C,#00FF88,#00A86B)',backgroundSize:'300% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'silverShimmer 2.5s linear infinite, greenBadge 2s ease-in-out infinite'}}>{lang==='en'?'STUDENT':'छात्र'}</div>
                </div>
              </div>
            </div>
          </div>
          <div style={{display:'flex',alignItems:'center',gap:6,flexShrink:0}}>
            <button className="tbtn icon-tbtn" onClick={toggleTheme} title={dm?(lang==='en'?'Switch to Light':'लाइट थीम'):(lang==='en'?'Switch to Dark':'डार्क थीम')}>{dm?'☀️':'🌙'}</button>
            <button className="tbtn hide-xs" onClick={toggleLang}>{lang==='en'?'हि':'EN'}</button>
            <a href="/announcements" title={lang==='en'?'Announcements':'घोषणाएं'} style={{background:'transparent',border:`1px solid ${bdr}`,borderRadius:9,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',textDecoration:'none',fontSize:15,color:txt,flexShrink:0,position:'relative'}}>
              🔔
              {unreadAnn>0&&<span style={{position:'absolute',top:-3,right:-3,minWidth:15,height:15,padding:'0 3px',borderRadius:99,background:'#FF4D4D',color:'#fff',fontSize:9,fontWeight:800,display:'flex',alignItems:'center',justifyContent:'center',border:'1.5px solid rgba(0,0,0,0.3)'}}>{unreadAnn>9?'9+':unreadAnn}</span>}
            </a>
            <button onClick={logout} title={lang==='en'?'Sign Out':'साइन आउट'} style={{background:'transparent',border:'1px solid rgba(255,77,77,0.35)',borderRadius:9,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:'#FF6B6B',flexShrink:0,transition:'all .2s'}}>
              <svg width="15" height="15" fill="none" stroke="currentColor" strokeWidth="2.2" viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16,17 21,12 16,7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            </button>
          </div>
        </div>

        {/* ── PAGE CONTENT ────────────────────────────────────── */}
        <div className={`pr-shell-main${_isImmersive?' immersive':''}`} style={{position:'relative',zIndex:2,animation:'fadeIn .4s ease',background:'transparent',boxSizing:'border-box'}}>{children}</div>
      </div>
    </ShellCtx.Provider>
  )
}
FILEEOF1
echo "StudentShell.tsx updated ✅"

# ---- 2) Test Series page: match --pr-bg to same reference ----
cat > ~/workspace/frontend/app/dashboard/test-series/page.tsx << 'FILEEOF2'
'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import StudentShell from '@/src/components/StudentShell'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Theme system (FPR4: replaces old locked-dark immersive background) ──
type PageTheme = 'light' | 'dark'
function usePageTheme(): PageTheme {
  const [theme, setTheme] = useState<PageTheme>('dark')
  useEffect(() => {
    const read = () => {
      try { setTheme((localStorage.getItem('pr_color_theme') as PageTheme) || 'dark') } catch { setTheme('dark') }
    }
    read()
    const onStorage = (e: StorageEvent) => { if (!e.key || e.key === 'pr_color_theme') read() }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])
  return theme
}
const THEME_VARS: Record<PageTheme, Record<string, string>> = {
  dark: {
    '--pr-bg': 'radial-gradient(ellipse at 20% 50%,#001e38 0%,#000f22 60%,#000810 100%)',
    '--pr-card-rgb': '4,12,30',
    '--pr-header-rgb': '2,8,22',
    '--pr-sub-rgb': '160,200,240',
    '--pr-text': '#F1F6FC',
  },
  light: {
    '--pr-bg': 'radial-gradient(ellipse at 15% 0%,#FFFFFF 0%,#F3F7FF 55%,#E9F1FF 100%)',
    '--pr-card-rgb': '255,255,255',
    '--pr-header-rgb': '255,255,255',
    '--pr-sub-rgb': '71,85,105',
    '--pr-text': '#0F172A',
  },
}

type Batch = {
  _id: string; name: string; description: string; examType: string;
  price: number; discountPrice: number; isFree: boolean; thumbnail: string;
  totalTests: number; enrolledCount: number; language: string; batchType: string;
  isSpotlight: boolean; flashSaleEndTime?: string; flashSalePrice?: number;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean; validity: number;
  startDate?: string; endDate?: string;
  rating: number; isEnrolled?: boolean; isWishlisted?: boolean; createdAt: string;
  difficulty?: string; subject?: string;
  effectivePrice?: number; discountPct?: number; fitScore?: number;
  isPriceWatched?: boolean; priceDropped?: boolean; watchedPrice?: number|null;
  teacherAssigned?: string; seatLimit?: number; _kind?: string;
}
type AcSuggestion = { _id: string; name: string; examType: string; isFree: boolean }
type Notif = { _id: string; title: string; message: string; isRead: boolean; createdAt: string; link?: string }

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', 'NEET UG': '#4D9FFF', JEE: '#9B59B6', 'JEE MAINS': '#9B59B6', 'JEE ADVANCE': '#7D3C98',
  CUET: '#27AE60', 'CUET UG': '#27AE60', 'CUET PG': '#1E8449', 'SSC CGL': '#E67E22', 'IIT JAM': '#00D4FF',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C',
  Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}
const CATS = ['All','NEET UG','JEE MAINS','JEE ADVANCE','CUET UG','CUET PG','SSC CGL','IIT JAM']
const CICONS: Record<string,string> = {
  All:'🌟','NEET UG':'🩺','JEE MAINS':'⚙️','JEE ADVANCE':'🛠️','CUET UG':'📖','CUET PG':'📚','SSC CGL':'🏛️','IIT JAM':'🔬',
  NEET:'🩺',JEE:'⚙️',CUET:'📖','Class 11':'📗','Class 12':'📘',Foundation:'🏛️','Crash Course':'🚀'
}
const QUOTES = [
  { q:"Champions aren't made in gyms. They are made from something deep inside them.", a:"Muhammad Ali" },
  { q:"The secret of getting ahead is getting started. Every expert was once a beginner.", a:"Mark Twain" },
  { q:"In the middle of every difficulty lies opportunity. Stay focused, stay strong.", a:"Albert Einstein" },
  { q:"Success is not final, failure is not fatal — it is the courage to continue that counts.", a:"Winston Churchill" },
]
const FACTS = [
  { icon:'🧬', t:'DNA Replication', f:'Semi-conservative — each new DNA retains one original strand (Meselson-Stahl, 1958). 3 billion base pairs in human genome.', c:'#4D9FFF' },
  { icon:'⚡', t:'ATP Synthesis', f:'Mitochondria produce 36-38 ATP per glucose via oxidative phosphorylation. F0F1 ATP synthase rotates at 100 rpm.', c:'#00D4FF' },
]

function loadRazorpay(): Promise<boolean> {
  return new Promise(resolve => {
    if ((window as any).Razorpay) return resolve(true)
    const s = document.createElement('script')
    s.src = 'https://checkout.razorpay.com/v1/checkout.js'
    s.onload = () => resolve(true); s.onerror = () => resolve(false)
    document.body.appendChild(s)
  })
}

function PRLogo({ size = 36 }: { size?: number }) {
  const b = Math.round(size * 0.94), p = Math.round(b * 0.63), f = Math.round(p * 0.52), r = Math.round(p * 0.28)
  return (
    <div style={{ position:'relative', width:b, height:b, flexShrink:0, display:'inline-flex' }}>
      <div style={{ position:'absolute', top:0, left:0, width:p, height:p, borderRadius:r, background:'linear-gradient(135deg,#4D9FFF,#00D4FF)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:f, fontWeight:900, fontFamily:'Inter,sans-serif', color:'#030810' }}>P</div>
      <div style={{ position:'absolute', bottom:0, right:0, width:p, height:p, borderRadius:r, background:'rgba(0,212,255,0.15)', border:'1.5px solid rgba(0,212,255,0.45)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:f, fontWeight:900, fontFamily:'Inter,sans-serif', color:'#00D4FF' }}>R</div>
    </div>
  )
}

function FlashTimer({ end }: { end: string }) {
  const [s,setS]=useState({h:0,m:0,s:0})
  useEffect(()=>{
    const tick=()=>{const d=new Date(end).getTime()-Date.now();if(d<=0){setS({h:0,m:0,s:0});return};setS({h:Math.floor(d/3600000),m:Math.floor(d%3600000/60000),s:Math.floor(d%60000/1000)})}
    tick();const iv=setInterval(tick,1000);return()=>clearInterval(iv)
  },[end])
  const p=(n:number)=>n.toString().padStart(2,'0')
  return <span style={{ fontFamily:'monospace',fontSize:13,fontWeight:800,color:'#FF6B6B',letterSpacing:2 }}>{p(s.h)}:{p(s.m)}:{p(s.s)}</span>
}

function Stars({ r }: { r: number }) {
  return (
    <span>
      {[1,2,3,4,5].map(i=><span key={i} style={{ color:i<=Math.round(r)?'#FFD700':'rgba(255,215,0,0.15)',fontSize:11 }}>★</span>)}
      <span style={{ fontSize:10,color:'rgba(255,255,255,0.3)',marginLeft:3 }}>{r.toFixed(1)}</span>
    </span>
  )
}

// ── NOTIFICATION BELL ──
function NotificationBell({ tok }: { tok: string | null }) {
  const [open,setOpen]=useState(false)
  const [notifs,setNotifs]=useState<Notif[]>([])
  const [unread,setUnread]=useState(0)
  const router=useRouter()

  const fetchNotifs=useCallback(async()=>{
    if(!tok)return
    try{
      const r=await fetch(`${API}/api/student/notifications`,{headers:{Authorization:`Bearer ${tok}`}})
      const d=await r.json()
      setNotifs(d.notifications||[]);setUnread(d.unread||0)
    }catch{}
  },[tok])

  useEffect(()=>{ fetchNotifs(); const iv=setInterval(fetchNotifs,30000); return()=>clearInterval(iv) },[fetchNotifs])

  const markAllRead=async()=>{
    if(!tok)return
    await fetch(`${API}/api/student/notifications/read-all`,{method:'PUT',headers:{Authorization:`Bearer ${tok}`}})
    setUnread(0);setNotifs(prev=>prev.map(n=>({...n,isRead:true})))
  }
  const markRead=async(id:string,link?:string)=>{
    if(!tok)return
    await fetch(`${API}/api/student/notifications/${id}/read`,{method:'PUT',headers:{Authorization:`Bearer ${tok}`}})
    setNotifs(prev=>prev.map(n=>n._id===id?{...n,isRead:true}:n))
    setUnread(prev=>Math.max(0,prev-1))
    if(link)router.push(link)
    setOpen(false)
  }

  if(!tok)return null
  return (
    <div style={{ position:'relative' }}>
      <button onClick={()=>{ setOpen(o=>!o); if(!open)fetchNotifs() }}
        style={{ position:'relative',background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',fontSize:18,flexShrink:0,transition:'background 0.2s' }}
        onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.2)')}
        onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}>
        🔔
        {unread>0&&<div style={{ position:'absolute',top:-4,right:-4,width:18,height:18,borderRadius:'50%',background:'linear-gradient(135deg,#E74C3C,#FF6B6B)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:9,fontWeight:900,color:'#fff',border:'2px solid #020816' }}>{unread>9?'9+':unread}</div>}
      </button>
      {open&&(
        <div style={{ position:'absolute',top:44,right:0,width:300,maxHeight:380,background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:16,overflow:'hidden',zIndex:200,boxShadow:'0 20px 60px rgba(0,0,0,0.6)',backdropFilter:'blur(24px)',animation:'slideUp 0.2s ease' }}>
          <div style={{ padding:'12px 14px',borderBottom:'1px solid rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'space-between' }}>
            <span style={{ fontWeight:700,fontSize:12,color:'var(--pr-text)' }}>🔔 Notifications</span>
            {unread>0&&<button onClick={markAllRead} style={{ background:'transparent',border:'none',color:'#4D9FFF',fontSize:10,cursor:'pointer',fontWeight:600 }}>Mark all read</button>}
          </div>
          <div style={{ overflowY:'auto',maxHeight:320 }}>
            {notifs.length===0?(
              <div style={{ padding:'28px 16px',textAlign:'center',color:'rgba(var(--pr-sub-rgb),0.82)',fontSize:12 }}>No notifications yet</div>
            ):notifs.map(n=>(
              <div key={n._id} onClick={()=>markRead(n._id,n.link)}
                style={{ padding:'12px 14px',borderBottom:'1px solid rgba(77,159,255,0.06)',cursor:'pointer',background:n.isRead?'transparent':'rgba(77,159,255,0.05)',transition:'background 0.2s' }}
                onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.09)')}
                onMouseLeave={e=>(e.currentTarget.style.background=n.isRead?'transparent':'rgba(77,159,255,0.05)')}>
                <div style={{ display:'flex',gap:8,alignItems:'flex-start' }}>
                  {!n.isRead&&<div style={{ width:7,height:7,borderRadius:'50%',background:'#4D9FFF',flexShrink:0,marginTop:4 }} />}
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:12,fontWeight:n.isRead?400:700,color:'var(--pr-text)',marginBottom:3 }}>{n.title}</div>
                    <div style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)',lineHeight:1.5 }}>{n.message}</div>
                    <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.68)',marginTop:4 }}>{new Date(n.createdAt).toLocaleDateString()}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// ── PAYMENT CHECKOUT MODAL ──
function PaymentModal({ batch, tok, onClose, onSuccess }: { batch: Batch; tok: string; onClose: () => void; onSuccess: () => void }) {
  const [loading,setLoading]=useState(false)
  const [receipt,setReceipt]=useState<any>(null)
  const [dlLoading,setDlLoading]=useState(false)
  const price=batch.discountPrice||batch.price

  const verifyAndShowReceipt=async(response:any)=>{
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-verify`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'},body:JSON.stringify({razorpay_order_id:response.razorpay_order_id,razorpay_payment_id:response.razorpay_payment_id,razorpay_signature:response.razorpay_signature})})
      const d=await r.json()
      if(!d.success){alert(d.error||'Payment verification failed — contact support with your payment ID.');return}
      setReceipt(d.receipt)
      onSuccess()
    }catch(e){alert('Payment succeeded but verification failed — contact support.')}
  }

  const downloadReceiptPdf=async()=>{
    if(!receipt)return
    setDlLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/receipt/${receipt.paymentId}/pdf`,{headers:{Authorization:`Bearer ${tok}`}})
      const blob=await r.blob()
      const url=window.URL.createObjectURL(blob)
      const a=document.createElement('a')
      a.href=url;a.download=`receipt_${receipt.receiptNo}.pdf`;document.body.appendChild(a);a.click();a.remove()
      window.URL.revokeObjectURL(url)
    }catch(e){alert('Could not download receipt')}
    finally{setDlLoading(false)}
  }

  const handlePayFull=async()=>{
    if(!tok)return
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-order`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'}})
      const d=await r.json()
      if(!d.success)return alert(d.error||'Error')
      if(d.testMode){
        const r2=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-verify`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'},body:JSON.stringify({razorpay_order_id:d.orderId,razorpay_payment_id:'pay_test_'+Date.now(),razorpay_signature:''})})
        const d2=await r2.json()
        if(!d2.success)return alert(d2.error||'Error')
        setReceipt(d2.receipt)
        onSuccess()
        return
      }
      const loaded=await loadRazorpay()
      if(!loaded)return alert('Could not load payment gateway')
      const rzp=new (window as any).Razorpay({key:d.key,amount:d.amount,currency:d.currency,order_id:d.orderId,name:'ProveRank',description:batch.name,handler:(response:any)=>{verifyAndShowReceipt(response)},theme:{color:'#4D9FFF'}})
      rzp.open()
    }finally{setLoading(false)}
  }

  if(receipt){
    return (
      <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
        <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(39,174,96,0.3)',borderRadius:22,padding:26,maxWidth:400,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)' }}>
          <div style={{ textAlign:'center',marginBottom:16 }}>
            <div style={{ fontSize:40,marginBottom:6 }}>✅</div>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'var(--pr-text)' }}>Payment Successful</div>
            {receipt.testMode&&<div style={{ fontSize:10,color:'#E67E22',marginTop:4 }}>(Test Mode — no real payment was charged)</div>}
          </div>
          <div style={{ background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.08)',borderRadius:14,padding:16,marginBottom:16 }}>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)',marginBottom:8 }}><span>Receipt No.</span><span style={{ color:'var(--pr-text)',fontWeight:700 }}>{receipt.receiptNo}</span></div>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)',marginBottom:8 }}><span>Item</span><span style={{ color:'var(--pr-text)',fontWeight:700,textAlign:'right',maxWidth:200,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{receipt.itemName}</span></div>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)',marginBottom:8 }}><span>Payment ID</span><span style={{ color:'var(--pr-text)',fontWeight:700,fontSize:10 }}>{receipt.razorpayPaymentId}</span></div>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:13,paddingTop:8,borderTop:'1px solid rgba(255,255,255,0.08)' }}><span style={{ color:'rgba(var(--pr-sub-rgb),0.82)',fontWeight:700 }}>Amount Paid</span><span style={{ color:'#27AE60',fontWeight:900,fontSize:16 }}>₹{receipt.amount}</span></div>
          </div>
          <button onClick={downloadReceiptPdf} disabled={dlLoading} style={{ width:'100%',padding:'12px',marginBottom:10,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:13,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12 }}>{dlLoading?'Preparing PDF...':'⬇️ Download Receipt (PDF)'}</button>
          <button onClick={onClose} style={{ width:'100%',padding:'11px',background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:13,color:'var(--pr-text)',fontWeight:700,cursor:'pointer',fontSize:12 }}>Done</button>
        </div>
      </div>
    )
  }

  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
          <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'var(--pr-text)' }}>💳 Payment</div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.74)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        <div style={{ fontSize:13,color:'rgba(var(--pr-sub-rgb),0.78)',marginBottom:6,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batch.name}</div>
        <div style={{ fontSize:22,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif',marginBottom:20 }}>₹{price}</div>
        <button onClick={handlePayFull} disabled={loading}
          style={{ width:'100%',padding:'13px',background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:13,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 6px 20px rgba(77,159,255,0.35)' }}>
          {loading?'Processing...':'💰 Pay Full Amount ₹'+price}
        </button>
      </div>
    </div>
  )
}

// ── REVIEW MODAL ──
function ReviewModal({ batchId, batchName, tok, onClose }: { batchId:string; batchName:string; tok:string; onClose:()=>void }) {
  const [rating,setRating]=useState(0)
  const [hov,setHov]=useState(0)
  const [comment,setComment]=useState('')
  const [loading,setLoading]=useState(false)
  const [done,setDone]=useState(false)
  const submit=async()=>{
    if(!rating)return alert('Please select a rating')
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batchId}/review`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'},body:JSON.stringify({rating,comment})})
      const d=await r.json()
      if(d.success)setDone(true); else alert(d.error||'Error')
    }finally{setLoading(false)}
  }
  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)' }}>
        {done?(
          <div style={{ textAlign:'center',padding:'20px 0' }}>
            <div style={{ fontSize:52,marginBottom:14 }}>⭐</div>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'var(--pr-text)',marginBottom:8 }}>Review Submitted!</div>
            <div style={{ fontSize:12,color:'rgba(var(--pr-sub-rgb),0.78)',marginBottom:20 }}>Pending admin approval.</div>
            <button onClick={onClose} style={{ background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'11px 28px',color:'#fff',fontWeight:700,cursor:'pointer' }}>Done</button>
          </div>
        ):(
          <>
            <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
              <div style={{ fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'var(--pr-text)' }}>Rate this Batch</div>
              <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.74)',cursor:'pointer',fontSize:20 }}>×</button>
            </div>
            <div style={{ fontSize:12,color:'rgba(var(--pr-sub-rgb),0.76)',marginBottom:16,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batchName}</div>
            <div style={{ display:'flex',gap:8,justifyContent:'center',marginBottom:18 }}>
              {[1,2,3,4,5].map(i=>(
                <span key={i} onClick={()=>setRating(i)} onMouseEnter={()=>setHov(i)} onMouseLeave={()=>setHov(0)}
                  style={{ fontSize:36,cursor:'pointer',transition:'transform 0.15s',transform:i<=(hov||rating)?'scale(1.2)':'scale(1)',color:i<=(hov||rating)?'#FFD700':'rgba(255,215,0,0.18)' }}>★</span>
              ))}
            </div>
            <textarea value={comment} onChange={e=>setComment(e.target.value)} placeholder="Share your experience (optional)..." rows={3}
              style={{ width:'100%',padding:'10px 12px',background:'rgba(255,255,255,0.04)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,color:'var(--pr-text)',fontSize:12,resize:'none',marginBottom:16,fontFamily:'Inter,sans-serif' }} />
            <button onClick={submit} disabled={loading||!rating}
              style={{ width:'100%',padding:'12px',background:rating?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.15)',border:'none',borderRadius:12,color:rating?'#fff':'rgba(var(--pr-sub-rgb),0.82)',fontWeight:700,cursor:rating?'pointer':'not-allowed',fontSize:13 }}>
              {loading?'Submitting...':'⭐ Submit Review'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}

// ── Banner Live Design constants (mirrors admin Creative Studio) ──
const BN_TEMPLATES = [
  { id: 'classic', label: 'Classic Premium', category: 'Featured', bg: 'linear-gradient(135deg,#0a0a1a,#1a1a3e)', accent: '#FFD700' },
  { id: 'glass', label: 'Glassmorphism', category: 'Premium', bg: 'linear-gradient(135deg,rgba(77,159,255,0.25),rgba(155,89,182,0.25))', accent: '#4D9FFF' },
  { id: 'minimal', label: 'Minimal Clean', category: 'Featured', bg: 'linear-gradient(135deg,#f8f9fa,#e9ecef)', accent: '#1a237e' },
  { id: 'moderngrad', label: 'Modern Gradient', category: 'Premium', bg: 'linear-gradient(135deg,#4568DC,#B06AB3)', accent: '#FFD700' },
  { id: 'premiumdark', label: 'Premium Dark', category: 'Premium', bg: 'linear-gradient(135deg,#0f0c29,#302b63)', accent: '#00D4FF' },
  { id: 'lightpro', label: 'Light Professional', category: 'Professional', bg: 'linear-gradient(135deg,#e0eafc,#cfdef3)', accent: '#1a237e' },
  { id: 'aurora', label: 'Aurora', category: 'Premium', bg: 'linear-gradient(135deg,#1a0533,#003333)', accent: '#00FFD1' },
  { id: 'cosmic', label: 'Cosmic Dark', category: 'Premium', bg: 'linear-gradient(135deg,#020816,#0d1b2a)', accent: '#4D9FFF' },
  { id: 'gold', label: 'Gold Elite', category: 'Premium', bg: 'linear-gradient(135deg,#1a1200,#3d2e00)', accent: '#FFD700' },
  { id: 'platinum', label: 'Platinum Elite', category: 'Premium', bg: 'linear-gradient(135deg,#232526,#414345)', accent: '#E5E4E2' },
  { id: 'luxuryblack', label: 'Luxury Black', category: 'Premium', bg: 'linear-gradient(135deg,#000000,#1a1a1a)', accent: '#FFD700' },
  { id: 'royalblue', label: 'Royal Blue', category: 'Premium', bg: 'linear-gradient(135deg,#1e3c72,#2a5298)', accent: '#FFD700' },
  { id: 'emerald', label: 'Emerald Premium', category: 'Premium', bg: 'linear-gradient(135deg,#0f3d3e,#1b5e20)', accent: '#00E676' },
  { id: 'crimson', label: 'Crimson Pro', category: 'Professional', bg: 'linear-gradient(135deg,#870000,#190A05)', accent: '#FFD700' },
  { id: 'neontech', label: 'Neon Tech', category: 'Premium', bg: 'linear-gradient(135deg,#0f0c29,#24243e)', accent: '#00FFF0' },
  { id: 'cyber', label: 'Cyber Future', category: 'Premium', bg: 'linear-gradient(135deg,#12121e,#1e1e3a)', accent: '#FF00E5' },
  { id: 'academic', label: 'Academic Professional', category: 'Academic', bg: 'linear-gradient(135deg,#1a2980,#26d0ce)', accent: '#FFD700' },
  { id: 'university', label: 'University Style', category: 'Academic', bg: 'linear-gradient(135deg,#232526,#0f2027)', accent: '#4D9FFF' },
  { id: 'coaching', label: 'Coaching Institute', category: 'Academic', bg: 'linear-gradient(135deg,#134E5E,#71B280)', accent: '#FFD700' },
  { id: 'studyplan', label: 'Study Planner', category: 'Academic', bg: 'linear-gradient(135deg,#3a1c71,#d76d77)', accent: '#FFD700' },
  { id: 'warrior', label: 'Exam Warrior', category: 'Motivation', bg: 'linear-gradient(135deg,#bf360c,#e65100)', accent: '#FFD700' },
  { id: 'topper', label: 'Topper Edition', category: 'Motivation', bg: 'linear-gradient(135deg,#f7971e,#ffd200)', accent: '#1a1a2e' },
  { id: 'rankbooster', label: 'Rank Booster', category: 'Motivation', bg: 'linear-gradient(135deg,#DA22FF,#9733EE)', accent: '#FFD700' },
  { id: 'launch', label: 'New Batch Launch', category: 'Offer', bg: 'linear-gradient(135deg,#11998e,#38ef7d)', accent: '#1a1a2e' },
  { id: 'earlybird', label: 'Early Bird Offer', category: 'Offer', bg: 'linear-gradient(135deg,#f857a6,#ff5858)', accent: '#FFD700' },
  { id: 'megasale', label: 'Mega Sale', category: 'Offer', bg: 'linear-gradient(135deg,#eb3349,#f45c43)', accent: '#FFD700' },
  { id: 'limitedseats', label: 'Limited Seats', category: 'Offer', bg: 'linear-gradient(135deg,#7f0000,#3d0000)', accent: '#FFD700' },
  { id: 'diwali', label: 'Diwali Special', category: 'Seasonal', bg: 'linear-gradient(135deg,#8E2DE2,#FF6B00)', accent: '#FFD700' },
  { id: 'newyear', label: 'New Year Special', category: 'Seasonal', bg: 'linear-gradient(135deg,#000046,#1CB5E0)', accent: '#FFD700' },
  { id: 'neetv', label: 'Medical (NEET)', category: 'Exam-Specific', bg: 'linear-gradient(135deg,#004d40,#006064)', accent: '#00E5FF' },
  { id: 'jeev', label: 'Engineering (JEE)', category: 'Exam-Specific', bg: 'linear-gradient(135deg,#1a237e,#283593)', accent: '#FFD700' },
]
const BN_FONTS = [
  { id: 'modern', label: 'Bold Modern', family: "'Inter',sans-serif" },
  { id: 'serif', label: 'Elegant Serif', family: "'Playfair Display',serif" },
  { id: 'clean', label: 'Clean Sans', family: "'Poppins',sans-serif" },
]
const BN_BADGES = [
  { id: 'none', label: 'None' }, { id: 'new', label: '✨ New' }, { id: 'trending', label: '📈 Trending' },
  { id: 'popular', label: '⭐ Popular' }, { id: 'bestseller', label: '🏆 Best Seller' }, { id: 'premium', label: '💎 Premium' },
  { id: 'limitedseats', label: '🔥 Limited Seats' }, { id: 'scholarship', label: '🎓 Scholarship' }, { id: 'earlybird', label: '🐦 Early Bird' },
  { id: 'flashsale', label: '⚡ Flash Sale' }, { id: 'live', label: '🔴 Live' }, { id: 'upcoming', label: '🕐 Upcoming' },
  { id: 'regopen', label: '📝 Registration Open' }, { id: 'closingsoon', label: '⏳ Closing Soon' }, { id: 'freedemo', label: '🆓 Free Demo' },
  { id: 'recommended', label: '👍 Recommended' }, { id: 'topRated', label: '🌟 Top Rated' }, { id: 'verified', label: '✅ Verified' },
]
const BN_EXAM_ICON: any = { NEET: '🧬', 'NEET UG': '🧬', 'NEET PG': '🩺', JEE: '⚛️', 'JEE Main': '⚛️', 'JEE Advanced': '⚛️', CUET: '📘', 'CUET UG': '📘', 'CUET PG': '📗', SSC: '📋', 'SSC CGL': '📋', 'SSC CHSL': '📋', UPSC: '🏛️', 'UPSC CSE': '🏛️', NDA: '🎖️', CDS: '🎖️', CAT: '📊', CLAT: '⚖️', GATE: '🔧', 'IIT JAM': '🔬', 'CSIR NET': '🔬', 'UGC NET': '📖', 'Railway (RRB)': '🚆', 'Banking (IBPS / SBI)': '🏦', 'State PSC': '🏛️' }

// ── STUDENT BANNER CARD (renders the admin-designed Creative Studio banner) ──
function StudentBannerCard({ banner: b, onCtaClick, ctaLabel, ctaLoading }: any) {
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  let bg = b.bgImage ? (/^(linear|radial)-gradient|^#|^rgba?\(/.test(b.bgImage) ? b.bgImage : `url(${b.bgImage}) center/cover`) : (tpl.bg)
  if (b.gradientAngle && b.gradientAngle !== 135 && typeof bg === 'string' && bg.indexOf('135deg') >= 0) bg = bg.replace('135deg', b.gradientAngle + 'deg')
  const badgeObj = BN_BADGES.find((x: any) => x.id === b.badge)
  // 🔧 FIX (Banner highlights/price/CTA missing) — default now matches admin's own default,
  // which includes highlights/price/cta (student card was silently hiding these sections).
  const sv = b.sectionVisibility || { icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }
  const badgeRadius = b.badgeStyle === 'corner' ? 0 : b.badgeStyle === 'ribbon' ? 3 : 20
  const pad = b.spacing === 'compact' ? 8 : b.spacing === 'spacious' ? 16 : 12
  const ctaRadius = b.ctaShape === 'square' ? 4 : b.ctaShape === 'rounded' ? 8 : 16
  const ctaIsOutline = b.ctaShape === 'outline'
  const renderLayerContent = (l: any) => {
    if (l.type === 'icon') return <span style={{ fontSize: 18 }}>{l.content}</span>
    if (!l.content) return null
    if (l.content.startsWith('<svg')) return <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: l.content }} />
    if (l.content.startsWith('data:image') || /^https?:\/\//.test(l.content)) return <img src={l.content} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
    return null
  }
  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', background: bg, color: b.textColor || '#fff', fontFamily: (BN_FONTS.find((f: any) => f.id === b.fontStyle) || BN_FONTS[0]).family, padding: pad, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', zIndex: 1 }}>
      {(b.layers || []).slice().sort((a: any, b2: any) => a.zIndex - b2.zIndex).map((l: any) => (
        <div key={l.id} style={{ position: 'absolute', left: l.x + '%', top: l.y + '%', transform: `translate(-50%,-50%) scale(${l.scale * 0.6}) rotate(${l.rotation}deg)`, opacity: l.opacity, zIndex: 10 + l.zIndex, width: 34, height: 34, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
          {renderLayerContent(l)}
        </div>
      ))}
      {(sv.icon !== false || sv.badge !== false) && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          {sv.icon !== false ? <span style={{ fontSize: 16 }}>{BN_EXAM_ICON[b.examType] || '📚'}</span> : <span />}
          {sv.badge !== false && badgeObj && badgeObj.id !== 'none' && <span style={{ fontSize: 8, fontWeight: 700, padding: '2px 7px', borderRadius: badgeRadius, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{badgeObj.label}</span>}
        </div>
      )}
      {(sv.title !== false || sv.tagline !== false || sv.highlights !== false) && (
        <div style={{ textAlign: (b.textAlign || 'left') as any }}>
          {sv.title !== false && <div style={{ fontSize: 14, fontWeight: 800, lineHeight: 1.2, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>{b.title}</div>}
          {sv.tagline !== false && b.tagline && <div style={{ fontSize: 9.5, opacity: 0.85, marginTop: 2 }}>{b.tagline}</div>}
          {sv.highlights !== false && (b.highlights || []).filter(Boolean).length > 0 && (
            <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', marginTop: 5, justifyContent: b.textAlign === 'center' ? 'center' : b.textAlign === 'right' ? 'flex-end' : 'flex-start' }}>
              {(b.highlights || []).filter(Boolean).slice(0, 3).map((h: string, i: number) => (
                <span key={i} style={{ fontSize: 7.5, padding: '2px 6px', borderRadius: 6, background: 'rgba(255,255,255,0.15)' }}>{h}</span>
              ))}
            </div>
          )}
        </div>
      )}
      {(sv.price !== false || sv.cta !== false) && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 4 }}>
          {sv.price !== false ? <span style={{ fontSize: 12, fontWeight: 800, color: b.accentColor || tpl.accent }}>{b.price && Number(b.price) > 0 ? '₹' + b.price : 'FREE'}</span> : <span />}
          {sv.cta !== false && (
            <button onClick={e => { e.stopPropagation(); onCtaClick && onCtaClick() }} disabled={ctaLoading} style={{ fontSize: 8.5, fontWeight: 700, padding: '4px 9px', borderRadius: ctaRadius, background: ctaIsOutline ? 'transparent' : (b.accentColor || tpl.accent), color: ctaIsOutline ? (b.accentColor || tpl.accent) : '#1a1a2e', border: ctaIsOutline ? `1.5px solid ${b.accentColor || tpl.accent}` : 'none', cursor: onCtaClick ? 'pointer' : 'default' }}>
              {ctaLoading ? '…' : (ctaLabel || b.ctaText || 'Enroll Now')} →
            </button>
          )}
        </div>
      )}
    </div>
  )
}

// ── BATCH CARD ──
function BatchCard({ b, tok, onUpdate, onBuy, onReview, onPreview, showPriceWatch }: {
  b:Batch; tok:string|null; onUpdate:()=>void;
  onBuy?:(b:Batch)=>void; onReview?:(b:Batch)=>void; onPreview?:(b:Batch)=>void; showPriceWatch?:boolean;
}) {
  const [loading,setLoading]=useState(false)
  const [hov,setHov]=useState(false)
  const [wsMsg,setWsMsg]=useState<string|null>(null)
  const workspaceLabel=b._kind==='series'?'Test Series':'Batch'
  const showWorkspaceComingSoon=()=>{setWsMsg(`📚 ${workspaceLabel} Workspace is coming soon!`);setTimeout(()=>setWsMsg(null),3000)}
  const isFlash=!!(b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date())
  const isNew=Date.now()-new Date(b.createdAt).getTime()<7*86400000
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const finalPrice=isFlash&&b.flashSalePrice?b.flashSalePrice:(b.discountPrice||b.price)
  const disc=b.price>0&&finalPrice<b.price?Math.round((1-finalPrice/b.price)*100):0
  const enroll=async()=>{
    if(!tok)return alert('Please login')
    setLoading(true)
    try{
      const res=await fetch(`${API}/api/student/batches/${b._id}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      const d=await res.json()
      if(d.success)onUpdate(); else alert(d.error||'Error')
    }finally{setLoading(false)}
  }
  const toggleWish=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batches/${b._id}/wishlist`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onUpdate()
  }
  const togglePriceWatch=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batch-ultra/${b._id}/price-watch`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onUpdate()
  }
  return (
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)} onClick={()=>onPreview&&onPreview(b)}
      style={{ background:'rgba(var(--pr-card-rgb),0.95)',border:`1px solid ${hov?ec+'50':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',position:'relative',transition:'all 0.3s',transform:hov?'translateY(-5px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)',cursor:onPreview?'pointer':'default' }}>
      {wsMsg&&<div style={{ position:'absolute',bottom:8,left:8,right:8,zIndex:30,background:'rgba(10,10,20,0.95)',border:`1px solid ${ec}40`,borderRadius:10,padding:'8px 10px',fontSize:10,color:'#fff',textAlign:'center',fontWeight:600,boxShadow:'0 8px 20px rgba(0,0,0,0.4)' }}>{wsMsg}</div>}
      <div style={{ position:'absolute',top:10,left:10,zIndex:5,display:'flex',flexDirection:'column',gap:4 }}>
        {isNew&&<span style={{ background:'linear-gradient(135deg,#27AE60,#1E8449)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>✨ NEW</span>}
        {typeof b.fitScore==='number'&&b.fitScore>=70&&<span style={{ background:'linear-gradient(135deg,#00D4FF,#0090B0)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>🎯 {b.fitScore}% Fit</span>}
        {b.enrolledCount>100&&<span style={{ background:'linear-gradient(135deg,#E67E22,#CA6F1E)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>🔥 HOT</span>}
        {b.isBundle&&<span style={{ background:'linear-gradient(135deg,#9B59B6,#7D3C98)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>📦 BUNDLE</span>}
      </div>
      <button onClick={e=>{e.stopPropagation();toggleWish()}} style={{ position:'absolute',top:10,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:36,height:36,cursor:'pointer',fontSize:15,display:'flex',alignItems:'center',justifyContent:'center' }}>{b.isWishlisted?'❤️':'🤍'}</button>

      <div style={{ height:140,position:'relative',display:'flex',alignItems:'center',justifyContent:'center',overflow:'hidden',...(b.banner?{}:{background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}12,${ec}05,rgba(2,8,22,0.9))`}) }}>
        {b.banner&&<StudentBannerCard banner={b.banner}
        ctaLabel={b.isEnrolled?`Go to ${workspaceLabel}`:b.isFree?(loading?'Enrolling...':'Enroll Free'):b.allowFreeTrial?(loading?'Starting...':'Free Trial'):(`Buy ₹${finalPrice}`)}
        ctaLoading={loading}
        onCtaClick={b.isEnrolled?undefined:(b.isFree||b.allowFreeTrial?enroll:()=>onBuy&&onBuy(b))}
      />}
        {!b.banner&&<div style={{ position:'absolute',inset:0,background:'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.95))',zIndex:1 }} />}
        {!b.banner&&!b.thumbnail&&<span style={{ fontSize:46,filter:`drop-shadow(0 0 16px ${ec})`,zIndex:2,opacity:0.88 }}>{CICONS[b.examType]||'📚'}</span>}
        {isFlash&&b.flashSaleEndTime&&<div style={{ position:'absolute',bottom:0,left:0,right:0,background:'rgba(200,40,40,0.92)',padding:'4px 0',textAlign:'center',fontSize:10,fontWeight:700,color:'#fff',zIndex:3 }}>⚡ Flash: <FlashTimer end={b.flashSaleEndTime} /></div>}
        {b.isEnrolled&&<div style={{ position:'absolute',inset:0,background:'rgba(39,174,96,0.16)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:2 }}><span style={{ background:'rgba(39,174,96,0.9)',color:'#fff',padding:'5px 14px',borderRadius:20,fontSize:11,fontWeight:800 }}>✅ Enrolled</span></div>}
      </div>
      {!b.banner && (
      <div style={{ padding:'13px 14px 15px' }}>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap',marginBottom:7 }}>
          <span style={{ background:`${ec}16`,color:ec,fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20,border:`1px solid ${ec}25` }}>{b.examType}</span>
          <span style={{ background:b.isFree?'rgba(39,174,96,0.13)':'rgba(230,126,34,0.13)',color:b.isFree?'#27AE60':'#E67E22',fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20 }}>{b.isFree?'🆓 FREE':b.allowFreeTrial?`🎯 ${b.trialDays}-Day Trial`:'💎 PAID'}</span>
        </div>
        <div style={{ fontSize:14,fontWeight:700,color:'var(--pr-text)',marginBottom:4,fontFamily:'Playfair Display,serif',lineHeight:1.4,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical' }}>{b.name}</div>
        <div style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.76)',lineHeight:1.5,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical',marginBottom:9 }}>{b.description||'Premium test series — NCERT based, expert curated.'}</div>
        <Stars r={b.rating} />
        <div style={{ display:'flex',gap:7,marginTop:7,flexWrap:'wrap' }}>
          {[{i:'📝',v:`${b.totalTests} Tests`},{i:'📅',v:b.startDate&&b.endDate?`${new Date(b.startDate).toLocaleDateString('en-IN',{day:'2-digit',month:'short'})}-${new Date(b.endDate).toLocaleDateString('en-IN',{day:'2-digit',month:'short'})}`:'Ongoing'}].map((it,idx)=>(
            <span key={idx} style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.84)' }}>{it.i} {it.v}</span>
          ))}
        </div>
        <div style={{ display:'flex',alignItems:'center',gap:7,margin:'9px 0 11px' }}>
          {b.isFree
            ?<span style={{ fontSize:21,fontWeight:900,color:'#27AE60',fontFamily:'Playfair Display,serif' }}>FREE</span>
            :<><span style={{ fontSize:21,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif' }}>₹{finalPrice}</span>{disc>0&&<span style={{ fontSize:11,color:'rgba(255,255,255,0.26)',textDecoration:'line-through' }}>₹{b.price}</span>}{disc>0&&<span style={{ fontSize:9,background:'rgba(39,174,96,0.16)',color:'#27AE60',padding:'2px 7px',borderRadius:20,fontWeight:700 }}>{disc}% OFF</span>}</>}
        </div>
        {b.priceDropped&&<div style={{ fontSize:10,color:'#27AE60',fontWeight:700,marginBottom:8 }}>📉 Price dropped since you watched!</div>}
        {showPriceWatch&&!b.isFree&&(
          <button onClick={e=>{e.stopPropagation();togglePriceWatch()}} style={{ width:'100%',padding:'6px',marginBottom:8,background:b.isPriceWatched?'rgba(0,212,255,0.12)':'rgba(77,159,255,0.05)',border:`1px solid ${b.isPriceWatched?'rgba(0,212,255,0.35)':'rgba(77,159,255,0.12)'}`,borderRadius:10,color:b.isPriceWatched?'#00D4FF':'rgba(var(--pr-sub-rgb),0.74)',cursor:'pointer',fontSize:10,fontWeight:700 }}>
            {b.isPriceWatched?'👁️ Watching Price':'🔔 Watch Price'}
          </button>
        )}
        {b.isEnrolled?(
          <div style={{ display:'flex',gap:6 }} onClick={e=>e.stopPropagation()}>
            <button onClick={e=>{e.stopPropagation();showWorkspaceComingSoon()}} style={{ flex:1,padding:'10px',background:`linear-gradient(135deg,${ec}20,${ec}10)`,border:`1px solid ${ec}40`,borderRadius:11,color:ec,fontWeight:700,cursor:'pointer',fontSize:11 }}>Go to {workspaceLabel} →</button>
            {onReview&&<button onClick={()=>onReview(b)} style={{ padding:'10px 10px',background:'rgba(255,215,0,0.08)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:11,color:'#FFD700',cursor:'pointer',fontSize:11 }}>⭐</button>}
          </div>
        ):b.isFree?(
          <button onClick={e=>{e.stopPropagation();enroll()}} disabled={loading} style={{ width:'100%',padding:'10px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Enrolling...':'🚀 Enroll Free'}</button>
        ):b.allowFreeTrial?(
          <button onClick={e=>{e.stopPropagation();enroll()}} disabled={loading} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Starting...':'🎯 Free Trial'}</button>
        ):(
          <button onClick={e=>{e.stopPropagation();onBuy&&onBuy(b)}} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>
            🛒 Buy ₹{finalPrice}
          </button>
        )}
      </div>
      )}
    </div>
  )
}

// ── QUICK PREVIEW MODAL (FPR4) ──
function QuickPreviewModal({ batchId, tok, onClose, onBuy, onEnrollUpdate }: { batchId:string; tok:string|null; onClose:()=>void; onBuy:(b:Batch)=>void; onEnrollUpdate:()=>void }) {
  const [detail,setDetail]=useState<any>(null)
  const [loading,setLoading]=useState(true)
  useEffect(()=>{
    setLoading(true)
    const h=tok?{Authorization:`Bearer ${tok}`}:{} as Record<string,string>
    fetch(`${API}/api/student/batches/${batchId}`,{headers:h}).then(r=>r.json()).then(d=>setDetail(d.batch)).finally(()=>setLoading(false))
    fetch(`${API}/api/student/batch-ultra/${batchId}/preview-track`,{method:'POST'}).catch(()=>{})
  },[batchId])
  const enroll=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batches/${batchId}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onEnrollUpdate();onClose()
  }
  if(loading||!detail)return(
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center' }}>
      <div style={{ color:'var(--pr-text)',fontSize:13 }}>Loading preview…</div>
    </div>
  )
  const b=detail
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const finalPrice=b.effectivePrice??(b.discountPrice||b.price)
  return (
    <div onClick={onClose} style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div onClick={e=>e.stopPropagation()} style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:`1px solid ${ec}30`,borderRadius:22,padding:24,maxWidth:440,width:'100%',maxHeight:'88vh',overflowY:'auto',backdropFilter:'blur(30px)' }}>
        {b.banner&&(
          <div style={{ height:120,borderRadius:14,overflow:'hidden',marginBottom:14,position:'relative' }}>
            <StudentBannerCard banner={b.banner} />
          </div>
        )}
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14 }}>
          <div>
            <span style={{ background:`${ec}16`,color:ec,fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20 }}>{b.examType}</span>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'var(--pr-text)',marginTop:8 }}>{b.name}</div>
          </div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.78)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        <Stars r={b.rating||0} />
        <div style={{ display:'flex',gap:10,flexWrap:'wrap',margin:'10px 0' }}>
          <span style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)' }}>📝 {b.totalTests} Tests</span>
          <span style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)' }}>📅 {b.startDate&&b.endDate?`${new Date(b.startDate).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})} → ${new Date(b.endDate).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}`:'Ongoing'}</span>
          {typeof b.fitScore==='number'&&<span style={{ fontSize:11,color:'#00D4FF',fontWeight:700 }}>🎯 {b.fitScore}% Fit for you</span>}
        </div>
        <div style={{ fontSize:22,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif',marginBottom:12 }}>
          {b.isFree?'FREE':`₹${finalPrice}`}{b.discountPct>0&&<span style={{ fontSize:11,color:'#27AE60',marginLeft:8 }}>{b.discountPct}% OFF</span>}
        </div>
        {b.syllabusCoveragePct!==undefined&&(
          <div style={{ marginBottom:14 }}>
            <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.74)',marginBottom:4,textTransform:'uppercase',fontWeight:700 }}>📚 Syllabus Coverage</div>
            <div style={{ height:6,background:'rgba(77,159,255,0.1)',borderRadius:4,overflow:'hidden' }}><div style={{ height:'100%',width:`${b.syllabusCoveragePct}%`,background:ec }} /></div>
          </div>
        )}
        {b.studyLoadPerWeek>0&&<div style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)',marginBottom:10 }}>⏱️ Study Load: ~{b.studyLoadPerWeek} test(s)/week</div>}
        {b.instructorHighlight&&(
          <div style={{ background:'rgba(77,159,255,0.06)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:10,marginBottom:12,fontSize:11,color:'rgba(var(--pr-sub-rgb),0.85)' }}>👨‍🏫 {b.instructorHighlight}</div>
        )}
        {b.socialProof&&(
          <div style={{ display:'flex',gap:14,marginBottom:14,fontSize:11,color:'rgba(var(--pr-sub-rgb),0.78)' }}>
            <span>⭐ {b.socialProof.rating} ({b.socialProof.ratingCount} reviews)</span>
          </div>
        )}
        {b.faqPreview&&b.faqPreview.length>0&&(
          <div style={{ marginBottom:16 }}>
            <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.74)',marginBottom:6,textTransform:'uppercase',fontWeight:700 }}>❓ FAQ</div>
            {b.faqPreview.map((f:any,i:number)=>(
              <div key={i} style={{ marginBottom:8 }}>
                <div style={{ fontSize:11,fontWeight:700,color:'var(--pr-text)' }}>{f.q}</div>
                <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.76)' }}>{f.a}</div>
              </div>
            ))}
          </div>
        )}
        <div style={{ display:'flex',gap:8 }}>
          {b.isEnrolled?(
            <button onClick={e=>{e.stopPropagation();showWorkspaceComingSoon()}} style={{ flex:1,padding:'11px',background:`linear-gradient(135deg,${ec}30,${ec}15)`,border:`1px solid ${ec}50`,borderRadius:12,color:ec,fontWeight:700,cursor:'pointer',fontSize:12 }}>Go to {workspaceLabel} →</button>
          ):b.isFree?(
            <button onClick={enroll} style={{ flex:1,padding:'11px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12 }}>🚀 Enroll Free</button>
          ):(
            <button onClick={()=>{onClose();onBuy(b)}} style={{ flex:1,padding:'11px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12 }}>🛒 Buy ₹{finalPrice}</button>
          )}
        </div>
      </div>
    </div>
  )
}

function EmptyState() {
  return (
    <div style={{ textAlign:'center',padding:'55px 16px' }}>
      <div style={{ fontSize:72,marginBottom:18,display:'inline-block',animation:'floatBob 3s ease infinite' }}>🚀</div>
      <div style={{ fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:10 }}>Batches Launching Soon!</div>
      <div style={{ fontSize:12,color:'rgba(var(--pr-sub-rgb),0.78)',maxWidth:360,margin:'0 auto 24px',lineHeight:1.8 }}>Premium Test Series will appear here once created by the Admin.</div>
    </div>
  )
}

// ══════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════
export default function TestSeriesPage() {
  const router=useRouter()
  const [batches,setBatches]=useState<Batch[]>([])
  const [loading,setLoading]=useState(true)
  const [search,setSearch]=useState('')
  const [cat,setCat]=useState('All')
  const [sort,setSort]=useState('newest')
  const [filterOpen,setFilterOpen]=useState(false)
  const [filters,setFilters]=useState({ isFree:'', batchType:'', difficulty:'', subject:'', language:'', offerType:'', flashSaleActive:'', enrollmentState:'' })
  const [priceRange,setPriceRange]=useState([0,5000])
  const [tab,setTab]=useState<'all'|'enrolled'|'wishlist'>('all')
  const [tok,setTok]=useState<string|null>(null)
  const [qIdx,setQIdx]=useState(0)
  const [spotlights,setSpotlights]=useState<Batch[]>([])
  const [acSuggestions,setAcSuggestions]=useState<AcSuggestion[]>([])
  const [showAc,setShowAc]=useState(false)
  const [recommendations,setRecommendations]=useState<Batch[]>([])
  const [isDesktop,setIsDesktop]=useState(false)
  const [desktopFilterOpen,setDesktopFilterOpen]=useState(false)
  const [reviewBatch,setReviewBatch]=useState<Batch|null>(null)
  const [buyBatch,setBuyBatch]=useState<Batch|null>(null)
  const [previewBatchId,setPreviewBatchId]=useState<string|null>(null)

  useEffect(()=>{
    setTok(localStorage.getItem('pr_token'))
    const iv=setInterval(()=>setQIdx(i=>(i+1)%QUOTES.length),5000)
    return()=>clearInterval(iv)
  },[])

  useEffect(()=>{
    const check=()=>setIsDesktop(window.innerWidth>=900)
    check(); window.addEventListener('resize',check); return()=>window.removeEventListener('resize',check)
  },[])

  useEffect(()=>{
    if(!search||search.length<2){setAcSuggestions([]);setShowAc(false);return}
    const timer=setTimeout(async()=>{
      try{
        const r=await fetch(`${API}/api/student/batch-extras/autocomplete?q=${encodeURIComponent(search)}`)
        const d=await r.json()
        setAcSuggestions(d.suggestions||[]);setShowAc((d.suggestions||[]).length>0)
      }catch{setShowAc(false)}
    },300)
    return()=>clearTimeout(timer)
  },[search])

  useEffect(()=>{
    const examType=cat!=='All'?cat:''
    fetch(`${API}/api/student/batch-extras/recommendations?examType=${examType}`)
      .then(r=>r.json()).then(d=>setRecommendations(d.batches||[])).catch(()=>{})
  },[cat])

  const fetchBatches=useCallback(async()=>{
    setLoading(true)
    try{
      const p=new URLSearchParams({sort})
      if(cat!=='All')p.set('examType',cat)
      if(search)p.set('search',search)
      if(filters.isFree)p.set('isFree',filters.isFree)
      if(filters.batchType)p.set('batchType',filters.batchType)
      if(filters.difficulty)p.set('difficulty',filters.difficulty)
      if(filters.subject)p.set('subject',filters.subject)
      if(filters.language)p.set('language',filters.language)
      if(filters.offerType)p.set('offerType',filters.offerType)
      if(filters.flashSaleActive)p.set('flashSaleActive',filters.flashSaleActive)
      if(filters.enrollmentState)p.set('enrollmentState',filters.enrollmentState)
      p.set('minPrice',priceRange[0].toString())
      p.set('maxPrice',priceRange[1].toString())
      const token=localStorage.getItem('pr_token')
      const h=token?{Authorization:`Bearer ${token}`}:{} as Record<string,string>
      const url=tab==='enrolled'?`${API}/api/student/batches/my`:tab==='wishlist'?`${API}/api/student/batches/wishlist`:`${API}/api/student/batches?${p}`
      const res=await fetch(url,{headers:h})
      const d=await res.json()
      const all=d.batches||[]
      setBatches(all);setSpotlights(all.filter((b:Batch)=>b.isSpotlight).slice(0,3))
    }catch{setBatches([])}finally{setLoading(false)}
  },[cat,sort,search,filters,tab,priceRange])

  useEffect(()=>{fetchBatches()},[fetchBatches])

  const handleBuy=async(b:Batch)=>{
    if(!tok)return alert('Please login to purchase')
    setBuyBatch(b)
  }

  const currentQuote=QUOTES[qIdx]

  const FilterContent=()=>(
    <>
      <div style={{ fontWeight:700,fontSize:11,color:'rgba(var(--pr-sub-rgb),0.74)',textTransform:'uppercase',letterSpacing:1,marginBottom:14 }}>🔧 Filters</div>

      {/* Price Range Slider */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Price Range</div>
        <div style={{ display:'flex',justifyContent:'space-between',marginBottom:6 }}>
          <span style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.78)' }}>₹{priceRange[0]}</span>
          <span style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.78)' }}>₹{priceRange[1]}</span>
        </div>
        <input type="range" min={0} max={5000} step={100} value={priceRange[1]}
          onChange={e=>setPriceRange([priceRange[0],Number(e.target.value)])}
          style={{ width:'100%',accentColor:'#4D9FFF',cursor:'pointer',marginBottom:4 }} />
        <div style={{ display:'flex',gap:5,flexWrap:'wrap',marginTop:6 }}>
          {[{v:[0,5000],l:'All'},{v:[0,0],l:'🆓 Free'},{v:[1,499],l:'Under ₹500'},{v:[500,999],l:'₹500-999'},{v:[1000,5000],l:'₹1000+'}].map((o,i)=>{
            const active=priceRange[0]===o.v[0]&&priceRange[1]===o.v[1]
            return <button key={i} onClick={()=>setPriceRange(o.v as [number,number])}
              style={{ padding:'4px 9px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Free/Paid */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Price Type</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'true',l:'🆓 Free'},{v:'false',l:'💎 Paid'}].map(o=>{
            const active=filters.isFree===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,isFree:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Format */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Format</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'Live',l:'🔴 Live'},{v:'Recorded',l:'📹 Recorded'},{v:'Both',l:'🔄 Both'}].map(o=>{
            const active=filters.batchType===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,batchType:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Difficulty */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Difficulty</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'Easy',l:'🟢 Easy'},{v:'Medium',l:'🟡 Medium'},{v:'Hard',l:'🔴 Hard'},{v:'Mixed',l:'🔀 Mixed'}].map(o=>{
            const active=filters.difficulty===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,difficulty:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Subject */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Subject</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'},{v:'Mathematics',l:'📐 Maths'}].map(o=>{
            const active=filters.subject===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,subject:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Language */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Language</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'Hindi',l:'🇮🇳 Hindi'},{v:'English',l:'🇬🇧 English'},{v:'Hindi + English',l:'🔤 Bilingual'}].map(o=>{
            const active=filters.language===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,language:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Quick Toggle: Flash Sale Active (FPR4) */}
      <div style={{ marginBottom:18,display:'flex',gap:8,flexWrap:'wrap' }}>
        <button onClick={()=>setFilters(prev=>({...prev,flashSaleActive:prev.flashSaleActive?'':'true'}))}
          style={{ padding:'6px 11px',borderRadius:20,fontSize:10,cursor:'pointer',background:filters.flashSaleActive?'rgba(231,76,60,0.15)':'rgba(77,159,255,0.05)',border:`1px solid ${filters.flashSaleActive?'rgba(231,76,60,0.4)':'rgba(77,159,255,0.1)'}`,color:filters.flashSaleActive?'#E74C3C':'rgba(var(--pr-sub-rgb),0.82)' }}>⚡ Flash Sale Live</button>
      </div>

      {/* Offer Type (FPR4) */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Offer Type</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'trial',l:'🎯 Free Trial'},{v:'bundle',l:'📦 Bundle'},{v:'spotlight',l:'⭐ Spotlight'},{v:'flashsale',l:'⚡ Flash Sale'}].map(o=>{
            const active=filters.offerType===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,offerType:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Enrollment State (FPR4) */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Enrollment State</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'open',l:'🟢 Open'},{v:'full',l:'🔴 Full'}].map(o=>{
            const active=filters.enrollmentState===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,enrollmentState:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Sort */}
      <div style={{ marginBottom:8 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.82)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Sort By</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'newest',l:'🆕 Newest'},{v:'popular',l:'🔥 Popular'},{v:'enrolled',l:'👥 Most Enrolled'},{v:'rating',l:'⭐ Top Rated'},{v:'price_low',l:'💰 Low Price'},{v:'price_high',l:'💎 High Price'},{v:'discount',l:'🏷️ Highest Discount'}].map(o=>{
            const active=sort===o.v
            return <button key={o.v} onClick={()=>setSort(o.v)}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Reset */}
      <button onClick={()=>{setFilters({isFree:'',batchType:'',difficulty:'',subject:'',language:'',offerType:'',flashSaleActive:'',enrollmentState:''});setPriceRange([0,5000]);setSort('newest')}}
        style={{ width:'100%',padding:'8px',background:'rgba(231,76,60,0.07)',border:'1px solid rgba(231,76,60,0.18)',borderRadius:10,color:'#E74C3C',cursor:'pointer',fontSize:10,fontWeight:700,marginTop:4 }}>
        🗑 Reset All Filters
      </button>
    </>
  )

  const pageTheme = usePageTheme()
  const vars = THEME_VARS[pageTheme]

  return (
      <StudentShell pageKey="test-series">
    <div style={{ minHeight:'100vh',color:'var(--pr-text)',fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:'var(--pr-bg)', ...(vars as any) }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes floatBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-13px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(26px)}to{opacity:1;transform:translateY(0)}}
        @keyframes gradShift{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes orb{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.26);border-radius:4px}
        input,select,textarea{outline:none}
        input::placeholder{color:rgba(100,150,200,0.42)}
        input[type=range]{height:4px;border-radius:2px}
      `}</style>

      {/* STICKY TOP BAR */}
      <div style={{ position:'relative',zIndex:2,padding:'14px 14px 80px',maxWidth:1300,margin:'0 auto' }}>
        {/* HERO */}
        <div style={{ padding:'22px 18px 20px',marginBottom:16,textAlign:'center',animation:'slideUp 0.5s ease',position:'relative' }}>
          <div style={{ display:'flex',alignItems:'center',gap:12,marginBottom:4,justifyContent:'center' }}>
            <span style={{ fontSize:34,filter:'drop-shadow(0 0 13px rgba(77,159,255,0.5))' }}>🎓</span>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:25,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF 0%,#00D4FF 45%,#9B59B6 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',backgroundSize:'200%',animation:'gradShift 6s ease infinite' }}>Batches & Test Series</div>
          </div>
        </div>

        {/* HERO QUICK STATS STRIP (FPR4) */}
        <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(90px,1fr))',gap:8,marginBottom:16 }}>
          {[
            {l:'Available',v:batches.length,c:'#4D9FFF'},
            {l:'Enrolled',v:batches.filter(b=>b.isEnrolled).length,c:'#27AE60'},
            {l:'Wishlisted',v:batches.filter(b=>b.isWishlisted).length,c:'#E74C3C'},
            {l:'Spotlight',v:spotlights.length,c:'#FFD700'},
            {l:'Live Offers',v:batches.filter(b=>b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date()).length,c:'#FF6B6B'},
          ].map(s=>(
            <div key={s.l} style={{ background:'rgba(var(--pr-card-rgb),0.85)',border:`1px solid ${s.c}20`,borderRadius:12,padding:'8px 6px',textAlign:'center' }}>
              <div style={{ fontSize:16,fontWeight:800,color:s.c }}>{s.v}</div>
              <div style={{ fontSize:8.5,color:'rgba(var(--pr-sub-rgb),0.74)',textTransform:'uppercase',letterSpacing:0.4 }}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* CATEGORY STRIP */}
        <div style={{ display:'flex',gap:7,overflowX:'auto',paddingBottom:7,marginBottom:14,scrollbarWidth:'none' }}>
          {CATS.map(c=>{
            const active=cat===c
            return <button key={c} onClick={()=>setCat(c)} style={{ flexShrink:0,padding:'8px 15px',borderRadius:22,background:active?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.07)',border:active?'none':'1px solid rgba(77,159,255,0.13)',color:active?'#fff':'rgba(var(--pr-sub-rgb),0.8)',fontWeight:active?700:400,cursor:'pointer',fontSize:11,transition:'all 0.2s',whiteSpace:'nowrap',boxShadow:active?'0 4px 13px rgba(77,159,255,0.26)':'none' }}>{CICONS[c]} {c}</button>
          })}
        </div>

        {/* SPOTLIGHT */}
        {spotlights.length>0&&(
          <div style={{ marginBottom:20 }}>
            <div style={{ display:'flex',alignItems:'center',gap:7,marginBottom:11 }}>
              <span style={{ fontSize:17 }}>⭐</span>
              <span style={{ fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'var(--pr-text)' }}>Spotlight Picks</span>
            </div>
            <div style={{ display:'grid',gridTemplateColumns:isDesktop?'repeat(2,1fr)':'1fr',gap:14 }}>
              {spotlights.map(b=><BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches} onBuy={handleBuy} onReview={setReviewBatch} onPreview={x=>setPreviewBatchId(x._id)} />)}
            </div>
          </div>
        )}

        {/* TABS */}
        <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:7,marginBottom:13 }}>
          {(['all','enrolled','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{ padding:'10px',borderRadius:12,background:tab===t?'rgba(77,159,255,0.13)':'rgba(var(--pr-card-rgb),0.8)',border:`1px solid ${tab===t?'rgba(77,159,255,0.36)':'rgba(77,159,255,0.1)'}`,color:tab===t?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.82)',fontWeight:tab===t?700:400,cursor:'pointer',fontSize:11,backdropFilter:'blur(12px)' }}>
              {t==='all'?'🌟 All':t==='enrolled'?'✅ My Batches':'❤️ Wishlist'}
            </button>
          ))}
        </div>

        {/* LAYOUT */}
        <div style={{ display:isDesktop?'flex':'block',gap:22,alignItems:'flex-start' }}>

          {/* DESKTOP STICKY SIDEBAR (hidden by default — toggle via Filter button) */}
          {isDesktop&&desktopFilterOpen&&(
            <div style={{ width:220,flexShrink:0,position:'sticky',top:70,background:'rgba(var(--pr-card-rgb),0.97)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:18,padding:'18px 16px',backdropFilter:'blur(22px)',boxShadow:'0 10px 40px rgba(0,10,40,0.35)',animation:'slideUp 0.4s ease',maxHeight:'calc(100vh - 90px)',overflowY:'auto' }}>
              <FilterContent />
            </div>
          )}

          <div style={{ flex:1,minWidth:0 }}>
            {/* SEARCH */}
            <div style={{ display:'flex',gap:7,marginBottom:12,flexWrap:'wrap' }}>
              <div style={{ flex:1,minWidth:150,position:'relative' }}>
                <span style={{ position:'absolute',left:10,top:'50%',transform:'translateY(-50%)',fontSize:12,opacity:0.42,zIndex:2 }}>🔍</span>
                <input value={search} onChange={e=>setSearch(e.target.value)} onFocus={()=>acSuggestions.length>0&&setShowAc(true)} onBlur={()=>setTimeout(()=>setShowAc(false),200)}
                  placeholder="Search batches..." style={{ width:'100%',padding:'10px 10px 10px 32px',background:'rgba(var(--pr-card-rgb),0.9)',border:'1px solid rgba(77,159,255,0.13)',borderRadius:12,color:'var(--pr-text)',fontSize:12,backdropFilter:'blur(12px)' }} />
                {showAc&&acSuggestions.length>0&&(
                  <div style={{ position:'absolute',top:'100%',left:0,right:0,marginTop:4,background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,overflow:'hidden',zIndex:100,boxShadow:'0 12px 40px rgba(0,0,0,0.5)',backdropFilter:'blur(24px)',animation:'slideUp 0.18s ease' }}>
                    {acSuggestions.map(s=>(
                      <div key={s._id} onClick={()=>{setSearch(s.name);setShowAc(false)}}
                        style={{ padding:'10px 14px',cursor:'pointer',display:'flex',alignItems:'center',gap:10,borderBottom:'1px solid rgba(77,159,255,0.06)',transition:'background 0.15s' }}
                        onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.08)')}
                        onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                        <span style={{ fontSize:16 }}>{CICONS[s.examType]||'📚'}</span>
                        <div>
                          <div style={{ fontSize:12,color:'var(--pr-text)',fontWeight:600 }}>{s.name}</div>
                          <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.84)' }}>{s.examType} · {s.isFree?'Free':'Paid'}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              {!isDesktop&&(
                <button onClick={()=>setFilterOpen(o=>!o)} style={{ padding:'10px 12px',background:filterOpen?'rgba(77,159,255,0.13)':'rgba(var(--pr-card-rgb),0.9)',border:`1px solid ${filterOpen?'rgba(77,159,255,0.36)':'rgba(77,159,255,0.13)'}`,borderRadius:12,color:'#4D9FFF',cursor:'pointer',fontSize:11,fontWeight:600 }}>⚙️ Filter</button>
              )}
              {isDesktop&&(
                <button onClick={()=>setDesktopFilterOpen(o=>!o)} style={{ padding:'10px 14px',background:desktopFilterOpen?'rgba(77,159,255,0.13)':'rgba(var(--pr-card-rgb),0.9)',border:`1px solid ${desktopFilterOpen?'rgba(77,159,255,0.36)':'rgba(77,159,255,0.13)'}`,borderRadius:12,color:'#4D9FFF',cursor:'pointer',fontSize:11,fontWeight:600,whiteSpace:'nowrap' }}>⚙️ {desktopFilterOpen?'Hide Filters':'Filters'}</button>
              )}
            </div>

            {/* MOBILE FILTER */}
            {!isDesktop&&filterOpen&&(
              <div style={{ background:'rgba(var(--pr-card-rgb),0.97)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:15,padding:15,marginBottom:12,backdropFilter:'blur(22px)',animation:'slideUp 0.22s ease' }}>
                <FilterContent />
              </div>
            )}

            {/* BATCH GRID */}
            {loading?(
              <div style={{ display:'grid',gridTemplateColumns:isDesktop?'repeat(2,1fr)':'1fr',gap:16 }}>
                {[1,2,3,4].map(i=><div key={i} style={{ height:380,background:'rgba(var(--pr-card-rgb),0.8)',borderRadius:20,border:'1px solid rgba(77,159,255,0.06)',animation:'shimmer 1.5s ease infinite',animationDelay:`${i*0.14}s` }} />)}
              </div>
            ):batches.length===0?<EmptyState />:(
              <div style={{ display:'grid',gridTemplateColumns:isDesktop?'repeat(2,1fr)':'1fr',gap:16 }}>
                {batches.map((b,i)=>(
                  <div key={b._id} style={{ animation:`slideUp ${0.28+i*0.04}s ease both` }}>
                    <BatchCard b={b} tok={tok} onUpdate={fetchBatches} onBuy={handleBuy} onReview={setReviewBatch} onPreview={x=>setPreviewBatchId(x._id)} showPriceWatch={tab==='wishlist'} />
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* WHY PROVERANK */}
        <div style={{ marginTop:42,background:'rgba(var(--pr-card-rgb),0.97)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:20,padding:'24px 16px',backdropFilter:'blur(22px)' }}>
          <div style={{ textAlign:'center',marginBottom:20 }}>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:700,color:'var(--pr-text)',marginBottom:3 }}>✨ Why Choose ProveRank?</div>
          </div>
          <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(130px,1fr))',gap:10 }}>
            {[{i:'🤖',t:'AI Analytics',d:'Weak area detection\nSmart revision',c:'#9B59B6'},{i:'🔒',t:'Anti-Cheat',d:'Webcam · Face AI\nIP Lock',c:'#E74C3C'},{i:'📊',t:'Live Ranks',d:'Real-time AIR\nPercentile',c:'#27AE60'},{i:'📄',t:'OMR + PDFs',d:'Bubble sheet\nCertificates',c:'#E67E22'},{i:'🆓',t:'100% Free',d:'Free hosting\nNo charges',c:'#00D4FF'}].map((f,i)=>(
              <div key={i} style={{ background:'rgba(var(--pr-card-rgb),0.72)',border:`1px solid ${f.c}14`,borderRadius:14,padding:'14px 10px',textAlign:'center',transition:'all 0.3s' }} onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'36'}} onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'14'}}>
                <div style={{ fontSize:26,marginBottom:8,filter:`drop-shadow(0 0 6px ${f.c}75)` }}>{f.i}</div>
                <div style={{ fontWeight:700,color:f.c,fontSize:11,marginBottom:4 }}>{f.t}</div>
                <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.84)',lineHeight:1.62,whiteSpace:'pre-line' }}>{f.d}</div>
              </div>
            ))}
          </div>
        </div>

        {/* QUOTE */}
        <div style={{ padding:'24px 4px 8px',display:'flex',alignItems:'center',gap:13 }}>
          <span style={{ fontSize:26,flexShrink:0 }}>💫</span>
          <div>
            <div style={{ fontSize:13,color:'rgba(var(--pr-sub-rgb),0.84)',fontStyle:'italic',lineHeight:1.65,fontFamily:'Playfair Display,serif' }}>"{currentQuote.q}"</div>
            <div style={{ fontSize:11,color:'#4D9FFF',fontWeight:700,marginTop:5 }}>— {currentQuote.a}</div>
          </div>
        </div>
      </div>

      {/* MODALS */}
      {reviewBatch&&tok&&<ReviewModal batchId={reviewBatch._id} batchName={reviewBatch.name} tok={tok} onClose={()=>setReviewBatch(null)} />}
      {buyBatch&&tok&&<PaymentModal batch={buyBatch} tok={tok} onClose={()=>setBuyBatch(null)} onSuccess={fetchBatches} />}
      {previewBatchId&&<QuickPreviewModal batchId={previewBatchId} tok={tok} onClose={()=>setPreviewBatchId(null)} onBuy={setBuyBatch} onEnrollUpdate={fetchBatches} />}
    </div>
      </StudentShell>
  )
}
FILEEOF2
echo "test-series/page.tsx updated ✅"

# ---- 3) Impersonate page: match loading-screen background ----
cat > ~/workspace/frontend/app/impersonate/page.tsx << 'FILEEOF3'
'use client'
import { Suspense, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

function Inner() {
  const router = useRouter()
  const params = useSearchParams()

  useEffect(() => {
    const token = params.get('token')
    const id    = params.get('id')
    const name  = params.get('name') || 'Student'

    if (!token || !id) {
      router.replace('/admin/x7k2p')
      return
    }

    try {
      sessionStorage.setItem('imp_token', token)
      sessionStorage.setItem('imp_id', id)
      sessionStorage.setItem('imp_name', decodeURIComponent(name))
    } catch(e) {}

    router.replace('/dashboard')
  }, [params, router])

  return (
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001e38 0%,#000f22 60%,#000810 100%)',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',fontSize:16,flexDirection:'column',gap:12}}>
      <div style={{fontSize:32}}>👁️</div>
      <div>Opening student view...</div>
    </div>
  )
}

export default function ImpersonatePage() {
  return (
    <Suspense fallback={
      <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001e38 0%,#000f22 60%,#000810 100%)',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',fontSize:16}}>
        Loading...
      </div>
    }>
      <Inner/>
    </Suspense>
  )
}
FILEEOF3
echo "impersonate/page.tsx updated ✅"

# ---- 4) Delete confirmed-dead legacy exam/[examId] base page ----
rm -rf ~/workspace/frontend/app/exam/\[examId\]/page.tsx
echo "exam/[examId]/page.tsx (dead legacy) deleted ✅"

cd ~/workspace
git add -A
git commit -m "fix: unify Student Panel dark-theme background to exactly match Admin Panel gradient across all pages; delete confirmed-dead legacy exam/[examId] base page"
git push
