#!/bin/bash
# ProveRank — Student Panel Theme/Layout Redesign (Light/Dark only)
# Run from your project ROOT in Replit shell: bash proverank_student_theme_redesign.sh
# Edit the two dir names below first if your folder structure differs.
set -e

APP_DIR="app"
COMPONENTS_DIR="src/components"

mkdir -p "$COMPONENTS_DIR"
mkdir -p "$APP_DIR/settings"

echo '-> Writing $COMPONENTS_DIR/StudentShell.tsx'
cat > "$COMPONENTS_DIR/StudentShell.tsx" << 'PRSHEOF'
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
    {id:'mini-tests',icon:'⚡',en:'Mini Tests',hi:'मिनी टेस्ट',href:'/mini-tests'},
    {id:'pyq-bank',icon:'📚',en:'PYQ Bank',hi:'पिछले वर्ष के प्रश्न',href:'/pyq-bank'},
    {id:'revision',icon:'🧠',en:'Smart Revision',hi:'स्मार्ट रिवीजन',href:'/revision'},
  ]},
  {label:'Results & Progress',labelHi:'परिणाम और प्रगति',items:[
    {id:'results',icon:'📈',en:'Results',hi:'परिणाम',href:'/results'},
    {id:'analytics',icon:'📉',en:'Analytics',hi:'विश्लेषण',href:'/analytics'},
    {id:'attempt-history',icon:'🕐',en:'Attempt History',hi:'परीक्षा इतिहास',href:'/attempt-history'},
    {id:'goals',icon:'🎯',en:'My Goals',hi:'मेरे लक्ष्य',href:'/goals'},
    {id:'compare',icon:'⚖️',en:'Compare',hi:'तुलना करें',href:'/dashboard/compare'},
    {id:'batch-compare',icon:'📊',en:'Batch Compare',hi:'बैच तुलना',href:'/dashboard/batch-compare'},
    {id:'leaderboard',icon:'🏆',en:'Leaderboard',hi:'लीडरबोर्ड',href:'/leaderboard'},
    {id:'certificate',icon:'🎖️',en:'Certificates',hi:'प्रमाणपत्र',href:'/certificate'},
  ]},
  {label:'Batches & Store',labelHi:'बैच और स्टोर',items:[
    {id:'my-batches',icon:'📚',en:'My Batches',hi:'मेरे बैच',href:'/dashboard/my-batches'},
    {id:'test-series',icon:'📚',en:'Test Series',hi:'टेस्ट सीरीज',href:'/dashboard/test-series'},
    {id:'store',icon:'🛒',en:'Store',hi:'स्टोर',href:'/dashboard/store'},
  ]},
  {label:'Communication',labelHi:'संचार',items:[
    {id:'announcements',icon:'📢',en:'Announcements',hi:'घोषणाएं',href:'/announcements'},
    {id:'doubt',icon:'💬',en:'Doubt & Query',hi:'संदेह और प्रश्न',href:'/doubt'},
    {id:'parent-portal',icon:'👨‍👩‍👧',en:'Parent Portal',hi:'अभिभावक पोर्टल',href:'/parent-portal'},
    {id:'support',icon:'🛟',en:'Support',hi:'सहायता',href:'/support'},
  ]},
  {label:'Account',labelHi:'खाता',items:[
    {id:'admit-card',icon:'🪪',en:'Admit Card',hi:'प्रवेश पत्र',href:'/admit-card'},
    {id:'settings',icon:'⚙️',en:'Settings',hi:'सेटिंग्स',href:'/settings'},
    {id:'profile',icon:'👤',en:'Profile',hi:'प्रोफ़ाइल',href:'/profile'},
  ]},
]

// Pages that must keep their own existing immersive dark/galaxy look — untouched regardless of the user's Light/Dark choice
const IMMERSIVE_PAGES=['test-series','batches','my-batches','store']

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
  const toast=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{setToastSt({msg,tp});setTimeout(()=>setToastSt(null),4000)},[])

  useEffect(()=>{fetch(`${API}/api/admin/maintenance`).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.maintenance)setMaint(d.maintenance)}).catch(()=>{})},[])

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
      brandGrad:'linear-gradient(90deg,#2563EB 0%,#0F172A 55%,#2563EB 100%)',logoTag:'#51607A',
      chipBg:'rgba(37,99,235,0.06)',
    },
    dark:{
      shellBg:'radial-gradient(ellipse at 20% 0%,#0C1220 0%,#070A12 55%,#040609 100%)',
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
                <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'gradMove 5s ease infinite',whiteSpace:'nowrap'}}>ProveRank</div>
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
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14.5,background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1,whiteSpace:'nowrap'}}>ProveRank</div>
                <div className="hide-xs" style={{fontSize:8.5,color:th.logoTag,fontWeight:700,letterSpacing:.6,whiteSpace:'nowrap'}}>{lang==='en'?'STUDENT':'छात्र'}</div>
              </div>
            </div>
          </div>
          <div style={{display:'flex',alignItems:'center',gap:6,flexShrink:0}}>
            <button className="tbtn icon-tbtn" onClick={toggleTheme} title={dm?(lang==='en'?'Switch to Light':'लाइट थीम'):(lang==='en'?'Switch to Dark':'डार्क थीम')}>{dm?'☀️':'🌙'}</button>
            <button className="tbtn hide-xs" onClick={toggleLang}>{lang==='en'?'हि':'EN'}</button>
            <a href="/announcements" title={lang==='en'?'Announcements':'घोषणाएं'} style={{background:'transparent',border:`1px solid ${bdr}`,borderRadius:9,width:34,height:34,display:'flex',alignItems:'center',justifyContent:'center',textDecoration:'none',fontSize:15,color:txt,flexShrink:0}}>🔔</a>
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
PRSHEOF

echo '-> Writing $COMPONENTS_DIR/ThemeHelper.tsx'
cat > "$COMPONENTS_DIR/ThemeHelper.tsx" << 'PRSHEOF'
'use client'
import { useState, useEffect } from 'react'

// darkMode:true => Dark theme, darkMode:false => Light theme
export function useThemeVars(darkMode: boolean) {
  return {
    bg:          darkMode ? 'radial-gradient(ellipse at 20% 0%,#0C1220 0%,#070A12 55%,#040609 100%)'
                          : 'radial-gradient(ellipse at 15% 0%,#FFFFFF 0%,#F3F7FF 55%,#E9F1FF 100%)',
    cardBg:      darkMode ? 'rgba(0,22,40,0.78)'       : 'rgba(255,255,255,0.94)',
    cardBorder:  darkMode ? 'rgba(77,159,255,0.18)'    : 'rgba(37,99,235,0.14)',
    textMain:    darkMode ? '#F1F6FC'                  : '#0F172A',
    textSub:     darkMode ? '#8DA2C0'                  : '#51607A',
    inputBg:     darkMode ? 'rgba(0,22,40,0.85)'       : 'rgba(255,255,255,0.96)',
    inputBorder: darkMode ? '#1B3A5C'                  : '#CBD5E1',
    inputColor:  darkMode ? '#F1F6FC'                  : '#0F172A',
    sidebarBg:   darkMode ? 'rgba(8,11,18,0.97)'       : 'rgba(255,255,255,0.97)',
    tableRowHover:darkMode? 'rgba(77,159,255,0.06)'    : 'rgba(37,99,235,0.05)',
    borderColor: darkMode ? 'rgba(77,159,255,0.14)'    : 'rgba(37,99,235,0.14)',
    mutedText:   darkMode ? '#4A6280'                  : '#94A3B8',
    primary:     darkMode ? '#4D9FFF'                  : '#2563EB',
  }
}

export const EN_TEXTS = {
  // Nav
  home:'Home', features:'Features', results:'Results', pricing:'Pricing',
  login:'Login', logout:'Logout', register:'Register', dashboard:'Dashboard',
  profile:'Profile', exams:'Exams', leaderboard:'Leaderboard',
  analytics:'Analytics', certificate:'Certificate', settings:'Settings',
  notifications:'Notifications', admitCard:'Admit Card',
  // Landing
  heroTitle:"India's Most Advanced\nNEET Test Platform",
  heroSub:'Real rankings. Real results. No compromise on performance or integrity.',
  startFree:'Start Free Test', viewDemo:'Watch Demo',
  stat1v:'50,000+', stat1l:'Students',
  stat2v:'1,20,000+', stat2l:'Tests Taken',
  stat3v:'99.9%', stat3l:'Uptime',
  stat4v:'#1', stat4l:'NEET Platform',
  featuresTitle:'Everything You Need to Crack NEET',
  ctaLine:'Start your NEET journey today.',
  regFree:'Register Free →',
  // Auth
  loginTitle:'Welcome Back', loginSub:'Login to your account',
  emailLabel:'EMAIL / ROLL NUMBER', emailPlaceholder:'student@proverank.com',
  passLabel:'PASSWORD', passPlaceholder:'Enter your password',
  forgot:'Forgot password?', loginBtn:'Login →',
  loading:'Logging in...', noAcc:"Don't have an account?",
  regTitle:'Create Your Account', regSub:'Join ProveRank today',
  nameLabel:'FULL NAME', phoneLabel:'MOBILE NUMBER',
  otpLabel:'OTP (6 digits)', otpSent:'OTP sent to your number',
  regBtn:'Create Account →', haveAcc:'Already have an account?',
  // Dashboard
  welcomeBack:'Welcome back,', currentRank:'Current Rank',
  bestScore:'Best Score', streak:'Day Streak', percentile:'Percentile',
  upcomingExams:'Upcoming Exams', recentResults:'Recent Results',
  noExams:'No upcoming exams', startExam:'Start Exam',
  viewResult:'View Result', myPerf:'My Performance', achievements:'Achievements',
  // Exam
  examInstr:'Exam Instructions', startNow:'Start Exam Now',
  submitExam:'Submit Exam', timeLeft:'Time Remaining',
  answered:'Answered', unanswered:'Not Answered', flagged:'Marked for Review',
  notVisited:'Not Visited', question:'Question', saveNext:'Save & Next',
  markReview:'Mark for Review', clearResp:'Clear Response',
  confirmSub:'Confirm Submission',
  subWarn:'You have unanswered questions. Are you sure you want to submit?',
  // Result
  yourResult:'Your Result', score:'Score', allIndiaRank:'All India Rank',
  accuracy:'Accuracy', correct:'Correct', incorrect:'Incorrect', skipped:'Skipped',
  downloadPDF:'Download PDF', shareResult:'Share Result',
  viewAnalysis:'View Analysis', viewLeaderboard:'View Leaderboard',
  // Terms
  termsTitle:'Terms & Conditions', acceptAll:'I Accept All Terms',
  decline:'Decline', lastUpdated:'Last Updated: March 2026',
  // Admin
  adminDash:'Admin Dashboard', students:'Students', manageExams:'Manage Exams',
  questionBank:'Question Bank', liveMonitoring:'Live Monitoring',
  reports:'Reports', totalStudents:'Total Students', activeExams:'Active Exams',
  todayAttempts:"Today's Attempts", cheatAlerts:'Cheat Alerts',
  // Common
  loading2:'Loading...', error:'Error', save:'Save', cancel:'Cancel',
  back:'← Back', next:'Next →', search:'Search...', filter:'Filter',
  export:'Export', actions:'Actions', status:'Status', active:'Active',
  inactive:'Inactive', view:'View', edit:'Edit', delete:'Delete',
  submit:'Submit', goHome:'Go to Home', pageNotFound:'Page Not Found',
  strongTopics:'Strong Topics', weakTopics:'Weak Topics', reviseNow:'Revise Now',
  downloadAdmit:'Download Admit Card',
  footer:'NEET · NEET PG · JEE · CUET',
}

export const HI_TEXTS = {
  home:'होम', features:'सुविधाएं', results:'परिणाम', pricing:'मूल्य',
  login:'लॉगिन', logout:'लॉगआउट', register:'पंजीकरण', dashboard:'डैशबोर्ड',
  profile:'प्रोफाइल', exams:'परीक्षाएं', leaderboard:'लीडरबोर्ड',
  analytics:'विश्लेषण', certificate:'प्रमाण पत्र', settings:'सेटिंग्स',
  notifications:'सूचनाएं', admitCard:'प्रवेश पत्र',
  heroTitle:'भारत का सबसे उन्नत\nNEET परीक्षा मंच',
  heroSub:'वास्तविक रैंकिंग। वास्तविक परिणाम। प्रदर्शन या ईमानदारी में कोई समझौता नहीं।',
  startFree:'नि:शुल्क परीक्षा शुरू करें', viewDemo:'डेमो देखें',
  stat1v:'50,000+', stat1l:'छात्र',
  stat2v:'1,20,000+', stat2l:'परीक्षाएं दी गईं',
  stat3v:'99.9%', stat3l:'अपटाइम',
  stat4v:'#1', stat4l:'NEET मंच',
  featuresTitle:'NEET क्रैक करने के लिए सब कुछ',
  ctaLine:'आज अपनी NEET यात्रा शुरू करें।',
  regFree:'नि:शुल्क पंजीकरण करें →',
  loginTitle:'वापस आपका स्वागत है', loginSub:'अपने अकाउंट में लॉगिन करें',
  emailLabel:'ईमेल / रोल नंबर', emailPlaceholder:'student@proverank.com',
  passLabel:'पासवर्ड', passPlaceholder:'पासवर्ड दर्ज करें',
  forgot:'पासवर्ड भूल गए?', loginBtn:'लॉगिन करें →',
  loading:'लॉगिन हो रहा है...', noAcc:'अकाउंट नहीं है?',
  regTitle:'अपना खाता बनाएं', regSub:'आज ProveRank से जुड़ें',
  nameLabel:'पूरा नाम', phoneLabel:'मोबाइल नंबर',
  otpLabel:'OTP (6 अंक)', otpSent:'आपके नंबर पर OTP भेजा गया',
  regBtn:'खाता बनाएं →', haveAcc:'पहले से खाता है?',
  welcomeBack:'वापस आपका स्वागत है,', currentRank:'वर्तमान रैंक',
  bestScore:'सर्वश्रेष्ठ स्कोर', streak:'दिन की लकीर', percentile:'प्रतिशतक',
  upcomingExams:'आगामी परीक्षाएं', recentResults:'हाल के परिणाम',
  noExams:'कोई आगामी परीक्षा नहीं', startExam:'परीक्षा शुरू करें',
  viewResult:'परिणाम देखें', myPerf:'मेरा प्रदर्शन', achievements:'उपलब्धियां',
  examInstr:'परीक्षा निर्देश', startNow:'अभी परीक्षा शुरू करें',
  submitExam:'परीक्षा जमा करें', timeLeft:'शेष समय',
  answered:'उत्तर दिया', unanswered:'उत्तर नहीं दिया', flagged:'समीक्षा के लिए चिह्नित',
  notVisited:'नहीं देखा', question:'प्रश्न', saveNext:'सहेजें और आगे बढ़ें',
  markReview:'समीक्षा के लिए चिह्नित करें', clearResp:'उत्तर साफ करें',
  confirmSub:'जमा करने की पुष्टि',
  subWarn:'आपके पास अनुत्तरित प्रश्न हैं। क्या आप जमा करना चाहते हैं?',
  yourResult:'आपका परिणाम', score:'स्कोर', allIndiaRank:'अखिल भारत रैंक',
  accuracy:'सटीकता', correct:'सही', incorrect:'गलत', skipped:'छोड़े',
  downloadPDF:'PDF डाउनलोड करें', shareResult:'परिणाम साझा करें',
  viewAnalysis:'विश्लेषण देखें', viewLeaderboard:'लीडरबोर्ड देखें',
  termsTitle:'नियम और शर्तें', acceptAll:'मैं सभी शर्तें स्वीकार करता/करती हूं',
  decline:'अस्वीकार करें', lastUpdated:'अंतिम अपडेट: मार्च 2026',
  adminDash:'व्यवस्थापक डैशबोर्ड', students:'छात्र', manageExams:'परीक्षाएं प्रबंधित करें',
  questionBank:'प्रश्न बैंक', liveMonitoring:'लाइव निगरानी',
  reports:'रिपोर्ट', totalStudents:'कुल छात्र', activeExams:'सक्रिय परीक्षाएं',
  todayAttempts:'आज के प्रयास', cheatAlerts:'धोखाधड़ी अलर्ट',
  loading2:'लोड हो रहा है...', error:'त्रुटि', save:'सहेजें', cancel:'रद्द करें',
  back:'← वापस', next:'आगे →', search:'खोजें...', filter:'फ़िल्टर',
  export:'निर्यात', actions:'क्रियाएं', status:'स्थिति', active:'सक्रिय',
  inactive:'निष्क्रिय', view:'देखें', edit:'संपादित करें', delete:'हटाएं',
  submit:'जमा करें', goHome:'होम पर जाएं', pageNotFound:'पृष्ठ नहीं मिला',
  strongTopics:'मजबूत विषय', weakTopics:'कमजोर विषय', reviseNow:'अभी दोहराएं',
  downloadAdmit:'प्रवेश पत्र डाउनलोड करें',
  footer:'NEET · NEET PG · JEE · CUET',
}
PRSHEOF

echo '-> Writing $APP_DIR/ThemeWatcher.tsx'
cat > "$APP_DIR/ThemeWatcher.tsx" << 'PRSHEOF'
'use client'
import { useEffect } from 'react'

const migrate = (v: string | null): 'light' | 'dark' => {
  if (v === 'white') return 'light'
  if (v === 'teal') return 'dark'
  return (v === 'light' || v === 'dark') ? v : 'dark'
}

export default function ThemeWatcher() {
  useEffect(() => {
    // Apply theme class to BOTH <html> and <body> so all theme-based CSS
    // overrides (old + new) actually take effect across every page.
    const applyColorTheme = (raw: string) => {
      const t = migrate(raw)
      const h = document.documentElement
      const b = document.body
      h.classList.remove('white-theme', 'dark-theme', 'teal-theme', 'light-theme')
      b.classList.remove('white-theme', 'dark-theme', 'teal-theme', 'light-theme')
      h.classList.add(t + '-theme')
      b.classList.add(t + '-theme')
      h.setAttribute('data-color-theme', t)
    }

    // On mount — read saved theme (migrating legacy white/teal values)
    try {
      const ct = localStorage.getItem('pr_color_theme') || 'dark'
      applyColorTheme(ct)
    } catch {}

    // Intercept localStorage.setItem — catch theme changes in same tab
    const orig = Storage.prototype.setItem
    Storage.prototype.setItem = function (key: string, value: string) {
      orig.call(this, key, value)
      if (key === 'pr_color_theme') applyColorTheme(value)
    }

    // Cross-tab sync
    const onStorage = (e: StorageEvent) => {
      if (e.key === 'pr_color_theme' && e.newValue) applyColorTheme(e.newValue)
    }
    window.addEventListener('storage', onStorage)

    return () => {
      Storage.prototype.setItem = orig
      window.removeEventListener('storage', onStorage)
    }
  }, [])

  return null
}
PRSHEOF

echo '-> Writing $APP_DIR/layout.tsx'
cat > "$APP_DIR/layout.tsx" << 'PRSHEOF'
import 'katex/dist/katex.min.css'
import type { Metadata } from 'next'
import './globals.css'
import ThemeWatcher from './ThemeWatcher'

export const metadata: Metadata = {
  title: 'ProveRank – India\'s Most Advanced NEET Test Platform',
  description: 'ProveRank: NEET pattern online test platform with live rankings, AI analytics, anti-cheat monitoring and detailed performance analysis.',
  keywords: 'NEET online test, ProveRank, mock test, NEET preparation, ranking',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet" />
        {/* Theme init — runs before paint to prevent flash. Only 2 themes now: light / dark (legacy white/teal values are migrated). */}
        <script dangerouslySetInnerHTML={{__html:`
          (function(){
            try {
              var raw = localStorage.getItem('pr_color_theme') || 'dark';
              var ct = raw;
              if (raw === 'white') ct = 'light';
              else if (raw === 'teal') ct = 'dark';
              if (ct !== 'light' && ct !== 'dark') ct = 'dark';
              var h = document.documentElement;
              h.classList.remove('white-theme','dark-theme','teal-theme','light-theme');
              h.classList.add(ct + '-theme');
              h.setAttribute('data-color-theme', ct);
            } catch(e) {
              document.documentElement.classList.add('dark-theme');
            }
          })();
        `}}/>
      </head>
      <body suppressHydrationWarning>
        <ThemeWatcher />
        {children}
      </body>
    </html>
  )
}
// deploy trigger Sun May 17 02:43:34 PM UTC 2026
// deploy Sun May 17 03:55:06 PM UTC 2026
// deploy
// deploy Sat May 23 11:33:23 AM UTC 2026
PRSHEOF

echo '-> Writing $APP_DIR/globals.css'
cat > "$APP_DIR/globals.css" << 'PRSHEOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* ═══════════════════════════════════════════════════════════════
   PROVERANK — CSS VARIABLES & THEME SYSTEM
   ═══════════════════════════════════════════════════════════════ */
:root {
  --bg-dark:          #000A18;
  --card-dark:        rgba(0,22,40,0.78);
  --border-dark:      rgba(77,159,255,0.22);
  --text-main-dark:   #E8F4FF;
  --text-sub-dark:    #6B8BAF;
  --input-bg-dark:    rgba(0,22,40,0.85);
  --input-border-dark:#002D55;
  --input-color-dark: #E8F4FF;

  --bg-light:          #EEF4FF;
  --card-light:        rgba(255,255,255,0.92);
  --border-light:      rgba(77,159,255,0.30);
  --text-main-light:   #0D1B2E;
  --text-sub-light:    #3D5068;
  --input-bg-light:    rgba(255,255,255,0.95);
  --input-border-light:#BDD0E8;
  --input-color-light: #0D1B2E;

  --primary:       #4D9FFF;
  --primary-dark:  #0055CC;
  --primary-mid:   #0066CC;
  --success:       #00C48C;
  --danger:        #FF4757;
  --warning:       #FFA502;
  --purple:        #A855F7;
}

/* ─── Reset ─────────────────────────────────────────────────── */
* { box-sizing: border-box; margin: 0; padding: 0; }
html { scroll-behavior: smooth; }

/* ═══════════════════════════════════════════════════════════════
   DARK THEME (default) — Deep Space
   ═══════════════════════════════════════════════════════════════ */
body,
body.dark-theme,
html.dark-theme body {
  font-family: 'Inter', 'Calibri', system-ui, sans-serif;
  -webkit-font-smoothing: antialiased;
  background-color: #000A18 !important;
  background-image:
    radial-gradient(ellipse at 20% 20%, rgba(0,85,204,0.18) 0%, transparent 60%),
    radial-gradient(ellipse at 80% 80%, rgba(77,159,255,0.10) 0%, transparent 55%),
    radial-gradient(ellipse at 50% 50%, rgba(0,0,0,0) 0%, #000A18 100%);
  color: #E8F4FF;
  min-height: 100vh;
}

/* ═══════════════════════════════════════════════════════════════
   LIGHT THEME — Aurora Blue-White
   (both class names supported: .light-theme is current, .light-theme
    also matches new StudentShell body class so overrides below apply)
   ═══════════════════════════════════════════════════════════════ */
body.light-theme,
html.light-theme body {
  background-color: #F6F9FF !important;
  background-image:
    radial-gradient(ellipse at 15% 15%, rgba(37,99,235,0.10) 0%, transparent 55%),
    radial-gradient(ellipse at 85% 85%, rgba(168,85,247,0.06) 0%, transparent 50%),
    radial-gradient(ellipse at 50% 0%, rgba(255,255,255,0.7) 0%, transparent 60%),
    linear-gradient(160deg, #FFFFFF 0%, #F3F7FF 45%, #E9F1FF 100%);
  color: #0F172A !important;
  min-height: 100vh;
}

/* Light theme text overrides — force readable text where components hardcode
   dark-theme text colors (fixes "white theme text invisible" bug) */
body.light-theme *[style*="color:#E8F4FF"],
body.light-theme *[style*="color: #E8F4FF"],
body.light-theme *[style*="color:#F1F6FC"],
body.light-theme *[style*="color: #F1F6FC"] {
  color: #0F172A !important;
}
body.light-theme *[style*="color:#6B8BAF"],
body.light-theme *[style*="color: #6B8BAF"],
body.light-theme *[style*="color:#6B8FAF"],
body.light-theme *[style*="color: #6B8FAF"],
body.light-theme *[style*="color:#8DA2C0"],
body.light-theme *[style*="color: #8DA2C0"],
body.light-theme *[style*="color:#B8C8D8"],
body.light-theme *[style*="color: #B8C8D8"],
body.light-theme *[style*="color:#9CA3AF"],
body.light-theme *[style*="color: #9CA3AF"] {
  color: #51607A !important;
}

/* Light theme — card surfaces */
body.light-theme .pr-card,
body.light-theme .stat-card {
  background: rgba(255,255,255,0.94) !important;
  border-color: rgba(37,99,235,0.16) !important;
  box-shadow: 0 2px 16px rgba(20,50,110,0.08) !important;
}

/* ═══════════════════════════════════════════════════════════════
   AURORA THEME — legacy/special theme (kept for any page still using it)
   ═══════════════════════════════════════════════════════════════ */
body.aurora-theme,
html.aurora-theme body {
  background-color: #09001F !important;
  background-image:
    radial-gradient(ellipse at 10% 10%, rgba(168,85,247,0.28) 0%, transparent 55%),
    radial-gradient(ellipse at 90% 85%, rgba(77,159,255,0.22) 0%, transparent 55%),
    radial-gradient(ellipse at 50% 50%, rgba(0,196,140,0.08) 0%, transparent 60%),
    linear-gradient(135deg, #09001F 0%, #0D0030 50%, #000A18 100%);
  color: #F0EAFF !important;
  min-height: 100vh;
}
body.aurora-theme .pr-card,
body.aurora-theme .stat-card {
  background: rgba(30,10,60,0.80) !important;
  border-color: rgba(168,85,247,0.25) !important;
}

/* Scrollbar for all themes */
::-webkit-scrollbar { width: 5px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: rgba(77,159,255,0.3); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: #4D9FFF; }

/* ─── Keyframes ──────────────────────────────────────────────── */
@keyframes float     { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-10px); } }
@keyframes floatR    { 0%,100% { transform: translateY(0) rotate(0deg); } 50% { transform: translateY(-8px) rotate(3deg); } }
@keyframes fadeUp    { from { opacity:0; transform:translateY(24px); } to { opacity:1; transform:translateY(0); } }
@keyframes pulse     { 0%,100% { opacity:0.4; } 50% { opacity:0.8; } }
@keyframes marquee   { 0% { transform: translateX(0); } 100% { transform: translateX(-50%); } }
@keyframes gradShift { 0%,100% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } }
@keyframes spin      { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
@keyframes spinSlow  { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
@keyframes fadeIn    { from { opacity:0; } to { opacity:1; } }
@keyframes shimmer   { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
@keyframes slideDown { from { opacity:0; transform:translateY(-10px); } to { opacity:1; transform:translateY(0); } }
@keyframes scaleIn   { from { opacity:0; transform:scale(0.92); } to { opacity:1; transform:scale(1); } }

/* ─── Input Styles ───────────────────────────────────────────── */
.li {
  width: 100%;
  padding: 14px 16px;
  border-radius: 10px;
  font-size: 15px;
  outline: none;
  transition: border 0.2s;
  font-family: 'Inter', sans-serif;
}
.li:focus {
  border-color: #4D9FFF !important;
  box-shadow: 0 0 0 3px rgba(77,159,255,0.15);
}

/* ─── Login Button ───────────────────────────────────────────── */
.lb {
  width: 100%;
  padding: 15px;
  border-radius: 10px;
  border: none;
  background: linear-gradient(135deg, #4D9FFF, #0055CC);
  color: white;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 4px 20px rgba(77,159,255,0.4);
  transition: all 0.3s;
  font-family: 'Inter', sans-serif;
}
.lb:hover  { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(77,159,255,0.55); }
.lb:disabled { opacity: 0.6; cursor: not-allowed; }

/* ─── Toggle Buttons ─────────────────────────────────────────── */
.tbtn {
  padding: 6px 14px;
  border-radius: 20px;
  border: 1.5px solid rgba(77,159,255,0.4);
  background: rgba(0,22,40,0.5);
  color: #E8F4FF;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  font-family: 'Inter', sans-serif;
  backdrop-filter: blur(8px);
}
.tbtn:hover { border-color: #4D9FFF; background: rgba(77,159,255,0.15); }
body.light-theme .tbtn { background: rgba(37,99,235,0.06); color: #0F172A; border-color: rgba(37,99,235,0.35); }

/* ─── Glass Card ─────────────────────────────────────────────── */
.glass-card {
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: 20px;
  box-shadow: 0 8px 40px rgba(0,0,0,0.4);
  animation: fadeUp 0.7s ease 0.15s both;
}
body.light-theme .glass-card { box-shadow: 0 4px 24px rgba(0,40,100,0.12); }

/* ─── Sidebar ────────────────────────────────────────────────── */
.sidebar {
  width: 260px;
  height: 100vh;
  position: fixed;
  top: 0; left: 0;
  overflow-y: auto;
  z-index: 50;
  padding: 24px 16px;
  border-right: 1px solid rgba(77,159,255,0.15);
}
.sidebar-link {
  display: flex; align-items: center; gap: 12px;
  padding: 12px 16px; border-radius: 12px;
  text-decoration: none; font-weight: 500; font-size: 14px;
  transition: all 0.2s; margin-bottom: 4px;
}
.sidebar-link:hover { background: rgba(77,159,255,0.1); }
.sidebar-link.active {
  background: rgba(77,159,255,0.15);
  border-left: 3px solid #4D9FFF;
  font-weight: 600;
}
body.light-theme .sidebar-link:hover  { background: rgba(37,99,235,0.10); }
body.light-theme .sidebar-link.active { background: rgba(37,99,235,0.14); }

/* ─── Main content ───────────────────────────────────────────── */
.main-with-sidebar { margin-left: 260px; }
@media (max-width: 768px) {
  .sidebar { transform: translateX(-100%); transition: transform 0.3s; }
  .sidebar.open { transform: translateX(0); }
  .main-with-sidebar { margin-left: 0; }
}

/* ─── Cards ──────────────────────────────────────────────────── */
.pr-card {
  border-radius: 16px;
  padding: 24px;
  border: 1px solid;
  transition: all 0.3s;
}
.pr-card:hover { transform: translateY(-2px); }
.stat-card {
  border-radius: 14px;
  padding: 20px 16px;
  border: 1px solid;
  transition: all 0.3s;
}
.stat-card:hover { transform: translateY(-3px); }

/* ─── Card hover fix (light theme) ──────────────────────────── */
body.light-theme .card-h:hover {
  box-shadow: 0 6px 24px rgba(0,40,100,0.14) !important;
}

/* ─── Table ──────────────────────────────────────────────────── */
.pr-table { width: 100%; border-collapse: collapse; }
.pr-table th { padding: 12px 16px; text-align: left; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em; }
.pr-table td { padding: 14px 16px; font-size: 14px; }
body.light-theme .pr-table th { color: #51607A !important; }
body.light-theme .pr-table td { color: #0F172A !important; }

/* ─── Badge ──────────────────────────────────────────────────── */
.badge { display:inline-flex;align-items:center;gap:4px;padding:4px 12px;border-radius:99px;font-size:12px;font-weight:600; }
.badge-blue   { background:rgba(77,159,255,.15); color:#4D9FFF; }
.badge-green  { background:rgba(0,196,140,.12);  color:#00C48C; }
.badge-red    { background:rgba(255,71,87,.12);   color:#FF4757; }
.badge-gold   { background:rgba(255,215,0,.12);   color:#FFD700; }
.badge-purple { background:rgba(168,85,247,.12);  color:#A855F7; }
body.light-theme .badge-blue  { background: rgba(37,99,235,0.12); }
body.light-theme .badge-green { background: rgba(0,196,140,0.12); }

/* ─── OMR Bubbles ────────────────────────────────────────────── */
.omr-bubble {
  width:46px; height:46px; border-radius:50%; border:2px solid;
  display:flex; align-items:center; justify-content:center; cursor:pointer;
  font-weight:700; font-size:15px; transition:all .2s;
}
.omr-bubble.selected { background:#4D9FFF; border-color:#4D9FFF; color:#fff; box-shadow:0 0 15px rgba(77,159,255,.4); }

/* ─── Question Nav ───────────────────────────────────────────── */
.qnum { width:34px;height:34px;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:600;cursor:pointer;transition:.2s; }
.qnum.answered   { background:#00C48C; color:#fff; }
.qnum.unanswered { background:#FF4757; color:#fff; }
.qnum.flagged    { background:#A855F7; color:#fff; }
.qnum.current    { background:#4D9FFF; color:#fff; box-shadow:0 0 12px rgba(77,159,255,.5); }
.qnum.unvisited  { background:rgba(77,159,255,0.1); color:#6B8BAF; }
.qnum:hover      { transform:scale(1.1); }

/* ─── Progress / Timer Bars ──────────────────────────────────── */
.progress-bar  { width:100%; background:rgba(77,159,255,0.1); border-radius:99px; height:8px; overflow:hidden; }
.progress-fill { height:100%; background:linear-gradient(90deg,#4D9FFF,#00C48C); border-radius:99px; transition:width .8s ease; }
.timer-bar     { height:6px; width:100%; border-radius:3px; transition:all 1s linear; }
.timer-safe    { background:linear-gradient(90deg,#00C48C,#4D9FFF); }
.timer-warning { background:linear-gradient(90deg,#FFA502,#FF6B35); }
.timer-danger  { background:linear-gradient(90deg,#FF4757,#CC2233); animation: pulse 1s infinite; }

/* ─── Admin Nav ──────────────────────────────────────────────── */
.admin-nav-tab {
  padding: 10px 20px; border-radius: 10px; font-weight: 500;
  font-size: 14px; cursor: pointer; transition: all 0.2s;
  border: none; display: flex; align-items: center; gap: 8px; text-decoration: none;
}
.admin-nav-tab.active { background: rgba(77,159,255,0.18); font-weight: 600; }
.admin-nav-tab:hover  { background: rgba(77,159,255,0.1); }

/* ─── Certificate ────────────────────────────────────────────── */
.cert-frame {
  border: 2px solid rgba(77,159,255,0.4);
  border-radius: 20px;
  background: linear-gradient(135deg, #000A18 0%, #001E3A 50%, #000A18 100%);
  position: relative; overflow: hidden;
}

/* ─── Notification Drawer ────────────────────────────────────── */
.notif-drawer {
  position: fixed; top:0; right:0; height:100vh; width:380px;
  z-index:200; transform:translateX(100%); transition:transform 0.3s ease; overflow-y:auto;
}
.notif-drawer.open { transform:translateX(0); }
@media (max-width: 480px) { .notif-drawer { width:100%; } }

/* ─── Watermark ──────────────────────────────────────────────── */
.exam-watermark {
  position: fixed; inset:0; pointer-events:none; z-index:999;
  font-size:14px; color:rgba(77,159,255,0.08); font-weight:600;
  display:flex; align-items:center; justify-content:center;
  transform:rotate(-25deg); font-size:clamp(10px,2vw,16px);
  white-space:nowrap; user-select:none;
}

/* ─── Marquee ────────────────────────────────────────────────── */
.marquee-track { display:flex; animation:marquee 40s linear infinite; width:max-content; }
.marquee-track:hover { animation-play-state:paused; }

/* ═══════════════════════════════════════════════════════════════
   MOBILE RESPONSIVE — All pages
   ═══════════════════════════════════════════════════════════════ */
@media (max-width: 768px) {

  html, body { overflow-x: hidden !important; max-width: 100vw !important; }

  /* ── FIX: All pages — safe horizontal padding ── */
  main {
    padding-left: 16px !important;
    padding-right: 16px !important;
    width: 100% !important;
    max-width: 100% !important;
    box-sizing: border-box !important;
  }

  /* All containers — full width */
  main, section, div[style*="max-width"] {
    max-width: 100% !important;
    box-sizing: border-box !important;
  }

  /* ── Stat cards — 2 per row ── */
  div[style*="repeat(auto-fit, minmax(200px"],
  div[style*="repeat(auto-fit,minmax(200px"] {
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 10px !important;
  }

  div[style*="repeat(auto-fit, minmax(180px"],
  div[style*="repeat(auto-fit,minmax(180px"] {
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 10px !important;
  }

  /* Stack 2-col grid sections */
  div[style*="repeat(auto-fit, minmax(340px"],
  div[style*="repeat(auto-fit,minmax(340px"] {
    grid-template-columns: 1fr !important;
    gap: 14px !important;
  }

  /* Quick access — 3 per row */
  div[style*="repeat(auto-fit, minmax(110px"],
  div[style*="repeat(auto-fit,minmax(110px"],
  div[style*="repeat(auto-fill, minmax(120px"],
  div[style*="repeat(auto-fill,minmax(120px"] {
    grid-template-columns: repeat(3, 1fr) !important;
    gap: 8px !important;
  }

  /* Feature/content cards — 1 col */
  div[style*="repeat(auto-fit, minmax(300px"],
  div[style*="repeat(auto-fit,minmax(300px"],
  div[style*="repeat(auto-fit, minmax(280px"],
  div[style*="repeat(auto-fit,minmax(280px"],
  div[style*="repeat(auto-fit, minmax(260px"],
  div[style*="repeat(auto-fit,minmax(260px"] {
    grid-template-columns: 1fr !important;
    gap: 14px !important;
  }

  /* Footer grid */
  div[style*="repeat(auto-fit, minmax(220px"],
  div[style*="repeat(auto-fit,minmax(220px"] {
    grid-template-columns: 1fr !important;
    gap: 24px !important;
  }

  /* ── GENERIC SAFETY NET — catches ANY auto-fit/auto-fill grid we
     don't explicitly know the minmax px value of, so it never
     overflows/gets clipped on small screens ── */
  div[style*="repeat(auto-fit"] { grid-template-columns: repeat(auto-fit, minmax(130px,1fr)) !important; }
  div[style*="repeat(auto-fill"] { grid-template-columns: repeat(auto-fill, minmax(130px,1fr)) !important; }

  /* Nav links hidden on mobile */
  nav a.nav-link { display: none !important; }

  /* Tables — scroll */
  table { display: block !important; overflow-x: auto !important; white-space: nowrap !important; -webkit-overflow-scrolling: touch !important; }

  /* Topbar */
  header[style*="height:60"], header[style*="height: 60"] { padding: 0 12px !important; }
}

/* ── Small phone (< 420px) ──────────────────────────────────── */
@media (max-width: 420px) {

  main { padding: 16px !important; }

  h1 { font-size: clamp(1.3rem, 6vw, 2rem) !important; }
  h2 { font-size: clamp(1.1rem, 5vw, 1.6rem) !important; }

  div[style*="repeat(auto-fit, minmax(200px"],
  div[style*="repeat(auto-fit,minmax(200px"] {
    grid-template-columns: repeat(2, 1fr) !important;
  }

  div[style*="repeat(auto-fit, minmax(110px"],
  div[style*="repeat(auto-fit,minmax(110px"],
  div[style*="repeat(auto-fill, minmax(120px"],
  div[style*="repeat(auto-fill,minmax(120px"] {
    grid-template-columns: repeat(3, 1fr) !important;
    gap: 6px !important;
  }

  div[style*="repeat(auto-fit"] { grid-template-columns: repeat(auto-fit, minmax(110px,1fr)) !important; }
  div[style*="repeat(auto-fill"] { grid-template-columns: repeat(auto-fill, minmax(110px,1fr)) !important; }

  div[style*="justifyContent:'space-between'"][style*="flexWrap:'wrap'"] {
    flex-direction: column !important;
    gap: 8px !important;
    align-items: flex-start !important;
  }

  div[style*="padding:48px"]   { padding: 24px 16px !important; }
  div[style*="padding:'28px'"] { padding: 16px !important; }

  td:last-child, th:last-child { display: none !important; }
}

/* ── Touch improvements ─────────────────────────────────────── */
@media (hover: none) and (pointer: coarse) {
  button, a { min-height: 40px !important; min-width: 40px !important; }
  .dash-card:hover, .feat-card:hover, .quick-btn:hover { transform: none !important; }
  * { -webkit-tap-highlight-color: rgba(77,159,255,0.15) !important; scroll-behavior: smooth !important; }
}

/* ── Tablet ─────────────────────────────────────────────────── */
@media (min-width: 769px) and (max-width: 1024px) {
  div[style*="repeat(auto-fit, minmax(200px"],
  div[style*="repeat(auto-fit,minmax(200px"] { grid-template-columns: repeat(2, 1fr) !important; }
  div[style*="repeat(auto-fit, minmax(300px"],
  div[style*="repeat(auto-fit,minmax(300px"] { grid-template-columns: repeat(2, 1fr) !important; }
  div[style*="repeat(auto-fit, minmax(220px"],
  div[style*="repeat(auto-fit,minmax(220px"] { grid-template-columns: repeat(2, 1fr) !important; }
  main { padding: 20px 16px !important; }
}

/* ── Dashboard header clock hide ────────────────────────────── */
@media (max-width: 480px) {
  header > div:nth-child(2) { display: none !important; }
  header { height: 52px !important; }
}

/* ─── Full width enforce ─────────────────────────────────────── */
html, body {
  width: 100%;
  max-width: 100%;
  overflow-x: hidden;
  margin: 0;
  padding: 0;
}
#__next, main { width: 100%; max-width: 100%; }

/* ── PROVERANK: Side cut fix — safe horizontal padding ── */
@media (max-width: 768px) {
  main {
    padding-left: 14px !important;
    padding-right: 14px !important;
  }
  /* Prevent any element from overflowing */
  .main-content, [data-page-wrapper] {
    padding-left: 14px !important;
    padding-right: 14px !important;
    width: 100% !important;
    box-sizing: border-box !important;
  }
}

/* ── PROVERANK: universal anti-overflow safety (all screen sizes) ── */
img, svg, canvas, video, iframe { max-width: 100%; height: auto; }
pre, code { max-width: 100%; }
table { max-width: 100%; }
input, select, textarea, button { max-width: 100%; }

/* ═══════════════════════════════════════════════════
   PROVERANK 2-THEME SYSTEM (student pages)
   Controlled via [data-color-theme] on container — light | dark
   ═══════════════════════════════════════════════════ */

[data-color-theme='dark'] ::-webkit-scrollbar-thumb { background: rgba(77,159,255,0.35) !important; }
[data-color-theme='dark'] input,
[data-color-theme='dark'] select,
[data-color-theme='dark'] textarea { color-scheme: dark; accent-color: #4D9FFF; }

[data-color-theme='light'] ::-webkit-scrollbar-thumb { background: rgba(37,99,235,0.3) !important; }
[data-color-theme='light'] input,
[data-color-theme='light'] select,
[data-color-theme='light'] textarea { color-scheme: light; accent-color: #2563EB; }
[data-color-theme='light'] .nav-lnk:hover  { background: rgba(37,99,235,0.1) !important; color: #2563EB !important; }
[data-color-theme='light'] .btn-p { background: linear-gradient(135deg,#2563EB,#1D4ED8) !important; }
[data-color-theme='light'] .tbtn  { border-color: rgba(37,99,235,0.35) !important; color: #0F172A !important; }
[data-color-theme='light'] .tbtn:hover { border-color: #2563EB !important; background: rgba(37,99,235,0.1) !important; }
[data-color-theme='light'] .pr-card,
[data-color-theme='light'] .stat-card { background: rgba(255,255,255,0.97) !important; border-color: rgba(0,0,0,0.06) !important; box-shadow: 0 4px 24px rgba(0,0,0,0.07) !important; }

/* Legacy attribute values kept mapped for any cached component still using them */
[data-color-theme='white'] ::-webkit-scrollbar-thumb { background: rgba(37,99,235,0.3) !important; }
[data-color-theme='white'] input,
[data-color-theme='white'] select,
[data-color-theme='white'] textarea { color-scheme: light; accent-color: #2563EB; }
[data-color-theme='white'] .nav-lnk:hover  { background: rgba(37,99,235,0.1) !important; color: #2563EB !important; }
[data-color-theme='white'] .btn-p { background: linear-gradient(135deg,#2563EB,#1D4ED8) !important; }
[data-color-theme='white'] .tbtn  { border-color: rgba(37,99,235,0.35) !important; color: #0F172A !important; }
[data-color-theme='white'] .tbtn:hover { border-color: #2563EB !important; background: rgba(37,99,235,0.1) !important; }
[data-color-theme='white'] .pr-card,
[data-color-theme='white'] .stat-card { background: rgba(255,255,255,0.97) !important; border-color: rgba(0,0,0,0.06) !important; box-shadow: 0 4px 24px rgba(0,0,0,0.07) !important; }

[data-color-theme='teal'] ::-webkit-scrollbar-thumb { background: rgba(45,212,191,0.4) !important; }
[data-color-theme='teal'] input,
[data-color-theme='teal'] select,
[data-color-theme='teal'] textarea { color-scheme: dark; accent-color: #2DD4BF; }
[data-color-theme='teal'] .nav-lnk:hover  { background: rgba(45,212,191,0.14) !important; color: #2DD4BF !important; }
[data-color-theme='teal'] .btn-p { background: linear-gradient(135deg,#2DD4BF,#0D9488) !important; }
[data-color-theme='teal'] .tbtn  { border-color: rgba(45,212,191,0.35) !important; color: #CCFBF1 !important; }
[data-color-theme='teal'] .tbtn:hover { border-color: #2DD4BF !important; background: rgba(45,212,191,0.14) !important; }

/* ═══════════════════════════════════════════════════════════════
   THEME SYSTEM — html.light-theme / html.dark-theme
   (legacy html.white-theme / html.teal-theme kept for safety)
   ═══════════════════════════════════════════════════════════════ */

/* ── DARK THEME (default) ─────────────────────────────────── */
html.dark-theme,
html.dark-theme body {
  background-color: #070A12 !important;
  color: #F1F6FC !important;
}
html.dark-theme body {
  background-image:
    radial-gradient(ellipse at 20% 0%, rgba(0,85,204,0.14) 0%, transparent 60%),
    radial-gradient(ellipse at 80% 80%, rgba(77,159,255,0.08) 0%, transparent 55%);
}

/* ── LIGHT THEME (new) ────────────────────────────────────── */
html.light-theme,
html.light-theme body {
  background-color: #FFFFFF !important;
  color: #0F172A !important;
}
html.light-theme body {
  background-image:
    radial-gradient(ellipse at 15% 10%, rgba(37,99,235,0.08) 0%, transparent 50%),
    radial-gradient(ellipse at 85% 90%, rgba(37,99,235,0.05) 0%, transparent 50%);
}

/* ── legacy WHITE THEME class (mapped to same look as light) ── */
html.white-theme,
html.white-theme body {
  background-color: #FFFFFF !important;
  color: #0F172A !important;
}
html.white-theme body {
  background-image:
    radial-gradient(ellipse at 15% 10%, rgba(37,99,235,0.07) 0%, transparent 50%),
    radial-gradient(ellipse at 85% 90%, rgba(37,99,235,0.05) 0%, transparent 50%);
}

/* ── legacy TEAL THEME class (kept, unused by picker now) ──── */
html.teal-theme,
html.teal-theme body {
  background-color: #001A1A !important;
  color: #CCFBF1 !important;
}
html.teal-theme body {
  background-image: linear-gradient(145deg, #001A1A 0%, #002E2E 50%, #000D0D 100%) !important;
}

/* Default fallback */
html:not(.light-theme):not(.white-theme):not(.teal-theme) body {
  background-color: #070A12;
}
PRSHEOF

echo '-> Writing $APP_DIR/settings/page.tsx'
cat > "$APP_DIR/settings/page.tsx" << 'PRSHEOF'
'use client'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
import { useState, useEffect } from 'react'

type ColorTheme = 'light' | 'dark'

const migrate = (v: string | null): ColorTheme => {
  if (v === 'white') return 'light'
  if (v === 'teal') return 'dark'
  return (v === 'light' || v === 'dark') ? v : 'dark'
}

function SettingsContent() {
  const { lang, toast, theme } = useShell()
  const [activeTheme, setActiveTheme] = useState<ColorTheme>('dark')
  const t = (en: string, hi: string) => lang === 'en' ? en : hi

  useEffect(() => {
    try { setActiveTheme(migrate(localStorage.getItem('pr_color_theme'))) } catch {}
  }, [])

  const applyTheme = (th: ColorTheme) => {
    setActiveTheme(th)
    try {
      localStorage.setItem('pr_color_theme', th)
      window.dispatchEvent(new StorageEvent('storage', { key: 'pr_color_theme', newValue: th }))
      toast?.(t('Theme updated!', 'थीम अपडेट हो गई!'), 's')
    } catch {}
  }

  const cardBg = theme?.isDark ? 'rgba(255,255,255,0.03)' : 'rgba(37,99,235,0.03)'
  const cardBorder = theme?.border || 'rgba(77,159,255,0.14)'

  return (
    <div style={{ maxWidth: 720, margin: '0 auto' }}>
      <div style={{ fontSize: 20, fontWeight: 800, marginBottom: 4 }}>⚙️ {t('Settings', 'सेटिंग्स')}</div>
      <div style={{ fontSize: 13, color: theme?.sub, marginBottom: 24 }}>
        {t('Manage your app preferences', 'अपनी ऐप प्राथमिकताएं प्रबंधित करें')}
      </div>

      {/* 🎨 Theme Picker — Light / Dark only */}
      <div style={{ background: cardBg, border: `1px solid ${cardBorder}`, borderRadius: 16, padding: 20 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: theme?.primary, marginBottom: 4 }}>
          🎨 {t('App Theme', 'ऐप थीम')}
        </div>
        <div style={{ fontSize: 11, color: theme?.sub, marginBottom: 16 }}>
          {t('Choose how ProveRank looks across all your pages', 'चुनें कि ProveRank सभी पेजों पर कैसा दिखे')}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 12 }}>
          {([
            { id: 'light' as ColorTheme, lbl: t('Light', 'लाइट'), sub: t('Bright & Clean', 'चमकीला'), bg: '#FFFFFF', acc: '#2563EB', ico: '☀️', tcl: '#0F172A' },
            { id: 'dark'  as ColorTheme, lbl: t('Dark', 'डार्क'),  sub: t('Bold & Easy on eyes', 'आंखों के लिए आरामदायक'), bg: '#0A0E17', acc: '#4D9FFF', ico: '🌙', tcl: '#FFFFFF' },
          ]).map(th => {
            const active = activeTheme === th.id
            return (
              <button key={th.id} onClick={() => applyTheme(th.id)}
                style={{
                  background: th.bg,
                  border: `2px solid ${active ? th.acc : 'rgba(120,140,170,0.25)'}`,
                  borderRadius: 14, padding: '18px 8px', cursor: 'pointer', textAlign: 'center',
                  boxShadow: active ? `0 0 22px ${th.acc}55` : 'none',
                  transition: 'all .25s', position: 'relative', minHeight: 108,
                }}>
                {active && <span style={{ position: 'absolute', top: 8, right: 10, fontSize: 12, color: th.acc, fontWeight: 800 }}>✓</span>}
                <div style={{ fontSize: 28, marginBottom: 8 }}>{th.ico}</div>
                <div style={{ fontSize: 13, fontWeight: 700, color: th.acc }}>{th.lbl}</div>
                <div style={{ fontSize: 10, marginTop: 4, color: th.tcl === '#FFFFFF' ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.45)' }}>{th.sub}</div>
              </button>
            )
          })}
        </div>

        <div style={{ fontSize: 10, color: theme?.sub, textAlign: 'center', marginTop: 14 }}>
          {t('Applies instantly to all student pages. Test Series & Store keep their own look.', 'सभी पेजों पर तुरंत लागू होता है। टेस्ट सीरीज और स्टोर अपना लुक रखते हैं।')}
        </div>
      </div>
    </div>
  )
}

export default function SettingsPage() {
  return <StudentShell pageKey="settings"><SettingsContent /></StudentShell>
}
PRSHEOF

echo "Done - all 6 files written. Now commit & redeploy (git add -A && git commit -m theme-redesign && git push)."
