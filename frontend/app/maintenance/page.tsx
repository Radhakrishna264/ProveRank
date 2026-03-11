'use client'
import { useState, useEffect } from 'react'

export default function Maintenance() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [time, setTime] = useState(3600)
  const [mounted, setMounted] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const iv = setInterval(()=>setTime(t=>t>0?t-1:0),1000)
    return ()=>clearInterval(iv)
  },[])

  if (!mounted) return null
  const h=Math.floor(time/3600), m=Math.floor((time%3600)/60), s=time%60
  const fmt=(n:number)=>String(n).padStart(2,'0')

  return (
    <div style={{minHeight:'100vh',background:'linear-gradient(135deg,#000A18 0%,#001628 50%,#000A18 100%)',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',color:'#E8F4FF',textAlign:'center',padding:'5%',position:'relative',overflow:'hidden'}}>
      <style>{`@keyframes pulse{0%,100%{opacity:.3}50%{opacity:.7}}@keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}.tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}.tbtn:hover{border-color:#4D9FFF;}`}</style>
      <div style={{position:'absolute',top:'10%',left:'5%',fontSize:200,color:'rgba(77,159,255,0.03)',animation:'pulse 4s infinite',fontFamily:'monospace'}}>⬡</div>
      <div style={{position:'absolute',bottom:'10%',right:'5%',fontSize:150,color:'rgba(77,159,255,0.03)',animation:'pulse 3s infinite 1s',fontFamily:'monospace'}}>⬡</div>
      {/* Logo */}
      <div style={{marginBottom:40,animation:'fadeUp 0.6s ease forwards'}}>
        <svg width={64} height={64} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+28*Math.cos(a)},${32+28*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="16" fontWeight="700" fill="#4D9FFF">PR</text></svg>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginTop:8}}>ProveRank</div>
      </div>
      <div style={{fontSize:48,marginBottom:16}}>🔧</div>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,5vw,3rem)',fontWeight:800,marginBottom:12,animation:'fadeUp 0.6s 0.1s ease both',opacity:0}}>
        {lang==='en'?'Under Maintenance':'रखरखाव के तहत'}
      </h1>
      <p style={{color:'#6B8BAF',fontSize:16,maxWidth:450,lineHeight:1.7,marginBottom:48,animation:'fadeUp 0.6s 0.2s ease both',opacity:0}}>
        {lang==='en'
          ? "We're upgrading ProveRank to serve you better. We'll be back shortly."
          : 'हम ProveRank को बेहतर बनाने के लिए अपग्रेड कर रहे हैं। हम जल्द वापस आएंगे।'}
      </p>
      {/* Countdown */}
      <div style={{display:'flex',gap:16,marginBottom:48,animation:'fadeUp 0.6s 0.3s ease both',opacity:0}}>
        {[[fmt(h),lang==='en'?'Hours':'घंटे'],[fmt(m),lang==='en'?'Minutes':'मिनट'],[fmt(s),lang==='en'?'Seconds':'सेकंड']].map(([v,l],i)=>(
          <div key={i} style={{background:'rgba(0,22,40,0.8)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:16,padding:'24px 28px',textAlign:'center',backdropFilter:'blur(20px)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:42,fontWeight:800,color:'#4D9FFF',lineHeight:1}}>{v}</div>
            <div style={{color:'#6B8BAF',fontSize:12,marginTop:6,letterSpacing:'0.1em',textTransform:'uppercase',fontWeight:600}}>{l}</div>
          </div>
        ))}
      </div>
      <button className="tbtn" onClick={()=>{const n=lang==='en'?'hi':'en';setLang(n);localStorage.setItem('pr_lang',n)}}>{lang==='en'?'🇮🇳 हिंदी':'🌐 English'}</button>
    </div>
  )
}
