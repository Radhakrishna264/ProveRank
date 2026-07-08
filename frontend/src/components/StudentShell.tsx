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
      brandGrad:'#2563EB',logoTag:'#374151',
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
          @keyframes silverShimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}
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
                <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14.5,lineHeight:1,whiteSpace:'nowrap',...(th.isDark?{background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}:{color:'#2563EB'})}}>ProveRank</div>
                <div style={{fontSize:8.5,fontWeight:700,letterSpacing:.6,whiteSpace:'nowrap',background:'linear-gradient(90deg,#909090,#E8E8E8,#C0C0C0,#FFFFFF,#C0C0C0,#909090)',backgroundSize:'300% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'silverShimmer 3s linear infinite'}}>{lang==='en'?'STUDENT':'छात्र'}</div>
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
