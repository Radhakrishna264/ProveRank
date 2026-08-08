#!/bin/bash
# ProveRank — "ProveRank" wordmark color fix:
#   1) Student Panel LIGHT theme: was a flat solid '#2563EB' (looked dull/
#      off vs Dark theme's nice moving gradient). Now gets its own proper
#      blue→violet→blue gradient shimmer, same animation as Dark theme.
#   2) Auth pages (Login/Register/Forgot Password — AuthShell.tsx): both
#      mobile top bar AND desktop left panel wordmark were flat solid
#      colors (no gradient at all). Now match the same premium blue→cyan
#      gradient shimmer used elsewhere in the app.
# Admin Panel + Student Panel Dark theme were already correct — untouched.
set -e

cd ~/workspace 2>/dev/null || { echo "❌ ~/workspace not found"; exit 1; }

echo "🔎 Locating files via grep..."
SHELLFILE=$(grep -rl "export default function StudentShell" --include="*.tsx" . 2>/dev/null | grep -v node_modules | head -1)
AUTHSHELL=$(grep -rl "export default function AuthShell" --include="*.tsx" . 2>/dev/null | grep -v node_modules | head -1)

echo "StudentShell.tsx : ${SHELLFILE:-NOT FOUND}"
echo "AuthShell.tsx     : ${AUTHSHELL:-NOT FOUND}"

if [ -z "$SHELLFILE" ] || [ -z "$AUTHSHELL" ]; then
  echo "❌ One or more files not found. Aborting — no changes made."
  exit 1
fi

TS=$(date +%s)
cp "$SHELLFILE" "${SHELLFILE}.bak_${TS}"
cp "$AUTHSHELL" "${AUTHSHELL}.bak_${TS}"
echo "✅ Backups created (.bak_${TS})"

cat > "$SHELLFILE" << 'EOF_STUDENTSHELL8'
'use client'
import React,{createContext,useContext,useState,useEffect,useCallback,ReactNode}from 'react'
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
  return(<div className="pr-logo-glowpulse" style={{position:'relative',width:b,height:b,flexShrink:0,display:'inline-flex'}}><style>{`@keyframes prLogoGlowPulse{0%,100%{filter:drop-shadow(0 0 4px rgba(77,159,255,0.35)) drop-shadow(0 0 2px rgba(0,212,255,0.2))}50%{filter:drop-shadow(0 0 16px rgba(77,159,255,0.85)) drop-shadow(0 0 8px rgba(0,212,255,0.55))}}.pr-logo-glowpulse{animation:prLogoGlowPulse 2.6s ease-in-out infinite}@media (prefers-reduced-motion: reduce){.pr-logo-glowpulse{animation:none}}`}</style><div style={{position:'absolute',top:0,left:0,width:p,height:p,borderRadius:rd,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',color:'#030810',boxShadow:'0 4px 16px rgba(77,159,255,0.4)'}}>P</div><div style={{position:'absolute',bottom:0,right:0,width:r,height:r,borderRadius:rd,background:'rgba(0,212,255,0.1)',border:'1.5px solid rgba(0,212,255,0.45)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',color:'#00D4FF',backdropFilter:'blur(8px)'}}>R</div></div>)
}

// Ultra Premium ambient background — CSS-only aurora glow + fine mesh grid.
// Replaces the old canvas particle/star/connecting-line animation: no moving
// dots, no requestAnimationFrame loop, no resize listener — just a few soft
// brand-colour glow orbs that slowly breathe/drift, plus a faint grid
// texture. Same component name (GalaxyBg) so the existing render call
// ({th.showGalaxy&&<GalaxyBg/>}) and both theme configs need no changes.
function GalaxyBg(){
  return(
    <div aria-hidden style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0,overflow:'hidden'}}>
      <div style={{position:'absolute',inset:0,backgroundImage:'linear-gradient(rgba(77,159,255,0.035) 1px, transparent 1px),linear-gradient(90deg, rgba(77,159,255,0.035) 1px, transparent 1px)',backgroundSize:'44px 44px'}}/>
      <div style={{position:'absolute',top:'6%',left:'4%',width:360,height:360,borderRadius:'50%',background:'radial-gradient(circle, rgba(77,159,255,0.11), transparent 70%)',filter:'blur(55px)',animation:'prOrbPulse 10s ease-in-out infinite, prOrbDrift 17s ease-in-out infinite'}}/>
      <div style={{position:'absolute',bottom:'8%',right:'5%',width:400,height:400,borderRadius:'50%',background:'radial-gradient(circle, rgba(167,139,250,0.09), transparent 70%)',filter:'blur(65px)',animation:'prOrbPulse 12s ease-in-out infinite 2.2s, prOrbDrift 21s ease-in-out infinite 3s'}}/>
      <div style={{position:'absolute',top:'52%',left:'46%',width:270,height:270,borderRadius:'50%',background:'radial-gradient(circle, rgba(255,100,157,0.05), transparent 70%)',filter:'blur(60px)',animation:'prOrbPulse 14s ease-in-out infinite 4.4s, prOrbDrift 19s ease-in-out infinite 1.5s'}}/>
      <div style={{position:'absolute',bottom:'16%',left:'36%',width:310,height:310,borderRadius:'50%',background:'radial-gradient(circle, rgba(0,196,140,0.06), transparent 70%)',filter:'blur(58px)',animation:'prOrbPulse 11s ease-in-out infinite 1.1s, prOrbDrift 15s ease-in-out infinite 6s'}}/>
    </div>
  )
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
      brandGrad:'linear-gradient(90deg,#1D4ED8 0%,#7C3AED 50%,#1D4ED8 100%)',logoTag:'#374151',
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
          @keyframes prOrbPulse{0%,100%{opacity:.6;transform:scale(1)}50%{opacity:1;transform:scale(1.1)}}
          @keyframes prOrbDrift{0%,100%{transform:translate(0,0)}50%{transform:translate(16px,-12px)}}
          @media (prefers-reduced-motion: reduce){*{animation:none!important;transition:none!important}}
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
          @keyframes chipPulse{0%,100%{box-shadow:0 0 6px rgba(77,159,255,.32),inset 0 0 5px rgba(167,139,250,.14)}50%{box-shadow:0 0 15px rgba(77,159,255,.75),inset 0 0 9px rgba(167,139,250,.28)}}
          @media(min-width:769px){.pr-brand{position:absolute!important;left:50%!important;top:50%!important;transform:translate(-50%,-50%)!important;z-index:1;gap:12px!important}}
          @media(min-width:769px){
            .pr-brand-logo{transform:scale(1.3)}
            .pr-brand-textcol{gap:6px!important}
            .pr-brand-name{font-size:20px!important}
            .pr-brand-badge{padding:4px 13px 4px 9px!important}
            .pr-badge-text{font-size:9.5px!important}
            .pr-badge-dot{width:6px!important;height:6px!important}
          }
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
                <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,whiteSpace:'nowrap',background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'gradMove 5s ease infinite'}}>ProveRank</div>
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
        <div style={{position:'sticky',top:0,zIndex:40,background:th.headerBg,backdropFilter:'blur(22px)',borderBottom:`1px solid ${bdr}`,minHeight:60,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 12px 0 10px',gap:8,boxShadow:dm?'0 2px 24px rgba(0,0,0,.4)':'0 2px 16px rgba(37,99,235,.08)'}}>
          {/* premium gradient accent hairline */}
          <div aria-hidden style={{position:'absolute',left:0,right:0,bottom:-1,height:2,background:`linear-gradient(90deg,transparent,${th.primary},#00D4FF,transparent)`,opacity:dm?.6:.4,pointerEvents:'none'}}/>

          <div style={{display:'flex',alignItems:'center',gap:10,minWidth:0}}>
            <button onClick={()=>setSide(true)} aria-label="Open menu" style={{background:dm?'linear-gradient(135deg,rgba(77,159,255,0.16),rgba(0,212,255,0.06))':'linear-gradient(135deg,rgba(37,99,235,0.12),rgba(0,180,255,0.05))',border:`1px solid ${bdr}`,color:th.primary,cursor:'pointer',width:38,height:38,borderRadius:11,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,transition:'all .2s',boxShadow:dm?'0 2px 10px rgba(77,159,255,.12)':'0 2px 8px rgba(37,99,235,.08)'}} title="Menu">
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
            </button>
            <div className="pr-brand" style={{display:'flex',alignItems:'center',gap:8,minWidth:0,background:dm?'transparent':'transparent'}}>
              <div className="pr-brand-logo" style={{filter:dm?'drop-shadow(0 0 8px rgba(77,159,255,0.5))':'none',flexShrink:0,transformOrigin:'left center'}}><PRLogo size={30}/></div>
              <div className="pr-brand-textcol" style={{minWidth:0,display:'flex',flexDirection:'column',alignItems:'flex-start',gap:4}}>
                <div className="pr-brand-name" style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:15,lineHeight:1,whiteSpace:'nowrap',background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'gradMove 5s ease infinite'}}>ProveRank</div>
                {/* Premium role chip — solid surface, always legible in Light/Dark, no gold (reserved for future Premium tier) */}
                <div className="pr-brand-badge" style={{position:'relative',display:'inline-flex',alignItems:'center',gap:5,padding:'3px 10px 3px 7px',borderRadius:20,whiteSpace:'nowrap',background:'linear-gradient(135deg,#3D7FE0,#6D5FD8)',boxShadow:dm?'0 2px 10px rgba(77,159,255,.4)':'0 2px 8px rgba(61,127,224,.35)',animation:'chipPulse 2.4s ease-in-out infinite'}}>
                  <span className="pr-badge-dot" style={{width:5,height:5,borderRadius:'50%',flexShrink:0,background:'#fff',boxShadow:'0 0 4px rgba(255,255,255,.9)'}}/>
                  <span className="pr-badge-text" style={{fontSize:7.5,fontWeight:800,letterSpacing:1.3,color:'#fff'}}>{lang==='en'?'STUDENT':'छात्र'}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Grouped premium action capsule */}
          <div style={{display:'flex',alignItems:'center',gap:2,flexShrink:0,padding:3,borderRadius:14,background:dm?'rgba(255,255,255,0.035)':'rgba(37,99,235,0.045)',border:`1px solid ${bdr}`,backdropFilter:'blur(10px)'}}>
            <button className="tbtn icon-tbtn" onClick={toggleTheme} title={dm?(lang==='en'?'Switch to Light':'लाइट थीम'):(lang==='en'?'Switch to Dark':'डार्क थीम')} style={{border:'none',background:'transparent'}}>{dm?'☀️':'🌙'}</button>
            <button className="tbtn icon-tbtn hide-xs" onClick={toggleLang} style={{border:'none',background:'transparent',fontSize:11,fontWeight:800}}>{lang==='en'?'हि':'EN'}</button>
            <a href="/announcements" title={lang==='en'?'Announcements':'घोषणाएं'} className="tbtn icon-tbtn" style={{border:'none',background:'transparent',textDecoration:'none',color:txt,position:'relative'}}>
              🔔
              {unreadAnn>0&&<span style={{position:'absolute',top:2,right:2,minWidth:15,height:15,padding:'0 3px',borderRadius:99,background:'#FF4D4D',color:'#fff',fontSize:9,fontWeight:800,display:'flex',alignItems:'center',justifyContent:'center',border:`1.5px solid ${th.headerBg}`,boxShadow:'0 0 6px rgba(255,77,77,.6)'}}>{unreadAnn>9?'9+':unreadAnn}</span>}
            </a>
            <div aria-hidden style={{width:1,height:20,background:bdr,margin:'0 3px',flexShrink:0}}/>
            <button onClick={logout} title={lang==='en'?'Sign Out':'साइन आउट'} className="icon-tbtn" style={{background:'rgba(255,77,77,0.1)',border:'1px solid rgba(255,77,77,0.3)',cursor:'pointer',color:'#FF6B6B',transition:'all .2s'}}>
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
EOF_STUDENTSHELL8
echo "✅ StudentShell.tsx updated: $SHELLFILE"

cat > "$AUTHSHELL" << 'EOF_AUTHSHELL5'
'use client'
import PRLogo from '@/components/PRLogo'
import { ReactNode } from 'react'

// ── Design Tokens — Ultra Premium Neon Blue (matches globals.css --primary #4D9FFF / --bg-dark #000A18) ──
export const T = {
  bg: 'linear-gradient(165deg,#000A18 0%,#020F22 45%,#00050D 100%)',
  panel: 'linear-gradient(180deg, rgba(0,20,38,0.95), rgba(0,8,18,0.98))',
  pri: '#4D9FFF',
  priDark: '#0066CC',
  cyan: '#00D4FF',
  card: 'rgba(0,20,38,0.72)',
  cardBorder: 'rgba(77,159,255,0.22)',
  txt: '#E8F4FF',
  sub: '#6B8BAF',
  dark: '#031320',
  success: '#00C48C',
  danger: '#FF4757',
  inputBg: 'rgba(0,14,28,0.85)',
  inputBorder: '#002D55',
}

export const inp: any = {
  width: '100%', padding: '12px 14px', background: T.inputBg,
  border: `1.5px solid ${T.inputBorder}`, borderRadius: 10, color: T.txt,
  fontSize: 14, fontFamily: 'Inter,sans-serif', outline: 'none',
  boxSizing: 'border-box', transition: 'border-color .2s, box-shadow .2s',
}

export function inpErr(hasError: boolean): any {
  return { ...inp, border: hasError ? `1.5px solid ${T.danger}` : inp.border }
}

const EXAM_BADGES = ['NEET', 'JEE', 'CUET', 'SSC', 'CLAT', 'BANK']

interface Step { label: string }
interface Props { steps?: Step[]; current?: number; children: ReactNode }

export default function AuthShell({ steps = [], current = 0, children }: Props) {
  const hasSteps = steps.length > 1
  return (
    <div style={{ minHeight: '100vh', background: T.bg, fontFamily: 'Inter,sans-serif', position: 'relative', overflowX: 'hidden' }}>
      <style>{`
        @keyframes glowPulse{0%,100%{filter:drop-shadow(0 0 6px #4D9FFF66)}50%{filter:drop-shadow(0 0 18px #00D4FFaa)}}
        @keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @keyframes confettiFall{0%{transform:translateY(-20px) rotate(0deg);opacity:1}100%{transform:translateY(420px) rotate(360deg);opacity:0}}
        @keyframes radarSpin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes bgPulse{0%,100%{opacity:.55;transform:scale(1)}50%{opacity:.85;transform:scale(1.08)}}
        @keyframes badgeFade{from{opacity:0;transform:scale(.6)}to{opacity:1;transform:scale(1)}}
        @keyframes gradMove{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
        *{box-sizing:border-box}
        .pr-input:focus{border-color:${T.pri} !important;box-shadow:0 0 0 3px rgba(77,159,255,0.16)}
        .pr-btn{transition:transform .18s ease, box-shadow .18s ease, filter .18s ease}
        .pr-btn:hover:not(:disabled){transform:translateY(-1px);filter:brightness(1.07)}
        .pr-btn:active:not(:disabled){transform:translateY(0)}
        a:focus-visible, button:focus-visible{outline:2px solid ${T.cyan};outline-offset:2px}
        .auth-mobile-bar{display:none}
        @media (max-width: 860px){
          .auth-left-panel, .auth-step-rail{display:none !important}
          .auth-mobile-bar{display:flex !important}
          .auth-row{flex-direction:column !important}
          .auth-form-area{padding:20px 16px 48px !important}
        }
        @media (prefers-reduced-motion: reduce){
          *{animation:none !important;transition:none !important}
        }
      `}</style>

      {/* ── Ambient background: OMR bubble-grid texture + soft glow blobs (fixed, decorative) ── */}
      <div aria-hidden style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none', opacity: 0.55, backgroundImage: 'radial-gradient(rgba(77,159,255,0.14) 1px, transparent 1.5px)', backgroundSize: '26px 26px' }} />
      <div aria-hidden style={{ position: 'fixed', top: '-12%', left: '-10%', width: '48%', height: '48%', borderRadius: '50%', background: 'radial-gradient(circle, rgba(77,159,255,0.20), transparent 70%)', filter: 'blur(60px)', zIndex: 0, pointerEvents: 'none', animation: 'bgPulse 9s ease-in-out infinite' }} />
      <div aria-hidden style={{ position: 'fixed', bottom: '-16%', right: '-10%', width: '52%', height: '52%', borderRadius: '50%', background: 'radial-gradient(circle, rgba(0,212,255,0.16), transparent 70%)', filter: 'blur(70px)', zIndex: 0, pointerEvents: 'none', animation: 'bgPulse 9s ease-in-out infinite 3s' }} />

      {/* Mobile sticky top bar — logo + step dots */}
      <div className="auth-mobile-bar" style={{ position: 'sticky', top: 0, zIndex: 30, height: 54, alignItems: 'center', justifyContent: 'space-between', padding: '0 16px', background: 'rgba(0,8,16,0.92)', backdropFilter: 'blur(16px)', borderBottom: `1px solid ${T.cardBorder}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ animation: 'glowPulse 3s ease-in-out infinite' }}><PRLogo size={24} /></div>
          <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 14, fontWeight: 700, background: `linear-gradient(90deg,${T.pri} 0%,${T.cyan} 50%,${T.pri} 100%)`, backgroundSize: '200% 100%', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', animation: 'gradMove 5s ease infinite' }}>ProveRank</span>
        </div>
        {hasSteps && (
          <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
            {steps.map((_, i) => (
              <div key={i} style={{ width: i === current ? 16 : 6, height: 6, borderRadius: 3, background: i <= current ? `linear-gradient(90deg,${T.pri},${T.cyan})` : 'rgba(107,139,175,0.28)', transition: 'all .3s' }} />
            ))}
          </div>
        )}
      </div>

      {/* Desktop: 3-column row — branding | step rail | form */}
      <div className="auth-row" style={{ display: 'flex', minHeight: '100vh', position: 'relative', zIndex: 1 }}>

        <div className="auth-left-panel" style={{ width: 236, flexShrink: 0, background: T.panel, borderRight: `1px solid ${T.cardBorder}`, padding: '38px 22px', display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div style={{ animation: 'glowPulse 3s ease-in-out infinite', width: 'fit-content' }}>
            <PRLogo size={38} />
          </div>
          <div>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 21, fontWeight: 700, background: `linear-gradient(90deg,${T.pri} 0%,${T.cyan} 50%,${T.pri} 100%)`, backgroundSize: '200% 100%', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', animation: 'gradMove 5s ease infinite', lineHeight: 1.25, letterSpacing: 0.2 }}>ProveRank</div>
            <div style={{ fontSize: 11, color: T.pri, marginTop: 3, fontWeight: 600, letterSpacing: 0.5 }}>Rise to the Top</div>
          </div>

          {/* Eyebrow — multi-exam positioning */}
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, width: 'fit-content', padding: '4px 10px', borderRadius: 20, background: 'rgba(0,212,255,0.08)', border: '1px solid rgba(0,212,255,0.3)' }}>
            <span style={{ width: 5, height: 5, borderRadius: '50%', background: T.cyan, boxShadow: `0 0 6px ${T.cyan}` }} />
            <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: 0.8, color: T.cyan, textTransform: 'uppercase' }}>Multi-Exam Platform</span>
          </div>

          {/* Signature — radar ring of competitive exams */}
          <div style={{ position: 'relative', width: 132, height: 132, margin: '6px auto 2px' }}>
            <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'conic-gradient(from 0deg, rgba(0,212,255,0.4), transparent 28%, transparent 100%)', animation: 'radarSpin 7s linear infinite', filter: 'blur(1px)' }} />
            <div style={{ position: 'absolute', inset: 14, borderRadius: '50%', border: '1px dashed rgba(77,159,255,0.3)' }} />
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', animation: 'glowPulse 3s ease-in-out infinite' }}>
              <PRLogo size={26} />
            </div>
            {EXAM_BADGES.map((b, i) => {
              const angle = -90 + i * 60
              return (
                <div key={b} style={{
                  position: 'absolute', top: '50%', left: '50%',
                  transform: `rotate(${angle}deg) translate(52px) rotate(${-angle}deg) translate(-50%,-50%)`,
                  fontSize: 8.5, fontWeight: 800, letterSpacing: 0.3, padding: '3px 6px', borderRadius: 20,
                  background: 'rgba(0,10,22,0.92)', border: '1px solid rgba(77,159,255,0.4)', color: '#8FC3FF',
                  whiteSpace: 'nowrap', animation: `badgeFade .5s ease ${i * 0.08}s backwards`,
                }}>{b}</div>
              )
            })}
          </div>

          <div style={{ height: 1, background: T.cardBorder, margin: '2px 0' }} />
          {[
            ['🎯', 'Multi Exam Platform'],
            ['🤖', 'AI Proctoring'],
            ['👨‍🏫', 'Designed By Experts'],
            ['📊', 'Deep AI Analytics'],
            ['🏆', 'All India Ranking'],
            ['⚡', 'Instant Results'],
            ['📱', 'Mobile Friendly'],
          ].map(([ic, l]) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ width: 24, height: 24, borderRadius: 7, background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.22)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, flexShrink: 0 }}>{ic}</span>
              <span style={{ fontSize: 11, color: T.txt, fontWeight: 500 }}>{l}</span>
            </div>
          ))}
        </div>

        {hasSteps && (
          <div className="auth-step-rail" style={{ width: 168, flexShrink: 0, padding: '38px 16px', display: 'flex', flexDirection: 'column', gap: 4, borderRight: `1px solid ${T.cardBorder}` }}>
            {steps.map((s, i) => {
              const active = i === current, done = i < current
              return (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '9px 8px', borderRadius: 10, background: active ? 'rgba(77,159,255,0.1)' : 'transparent' }}>
                  <div style={{
                    width: 22, height: 22, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, flexShrink: 0,
                    background: done ? `linear-gradient(135deg,${T.pri},${T.cyan})` : active ? 'rgba(77,159,255,0.2)' : 'rgba(107,139,175,0.1)',
                    color: done ? T.dark : active ? T.pri : T.sub,
                    border: active ? `1.5px solid ${T.pri}` : '1px solid rgba(107,139,175,0.25)',
                  }}>
                    {done ? '✓' : i + 1}
                  </div>
                  <span style={{ fontSize: 11, color: active ? T.txt : T.sub, fontWeight: active ? 700 : 400 }}>{s.label}</span>
                </div>
              )
            })}
          </div>
        )}

        <div className="auth-form-area" style={{ flex: 1, display: 'flex', justifyContent: 'center', padding: '44px 20px', overflowY: 'auto' }}>
          <div style={{ width: '100%', maxWidth: 420, animation: 'fadeIn .5s ease' }}>
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
EOF_AUTHSHELL5
echo "✅ AuthShell.tsx updated: $AUTHSHELL"

echo ""
echo "🎨 'ProveRank' wordmark now has a matching premium gradient shimmer"
echo "   everywhere: Auth pages, Student Panel (Light + Dark), Admin Panel."
echo ""
echo "▶ Next: cd ~/workspace/frontend && npm run dev   (check /login, /register, and Student Panel light mode)"
