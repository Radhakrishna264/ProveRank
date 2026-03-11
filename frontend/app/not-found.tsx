'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'

export default function NotFound() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [dark, setDark] = useState(true)
  const [mounted, setMounted] = useState(false)

  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const st=localStorage.getItem('pr_theme'); if(st==='light') setDark(false)
  },[])

  if (!mounted) return null
  const bg = dark ? '#000A18' : '#F0F7FF'
  const tm = dark ? '#E8F4FF' : '#0F172A'
  const ts = dark ? '#6B8BAF' : '#475569'

  return (
    <div style={{minHeight:'100vh',background:bg,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',fontFamily:'Inter,sans-serif',textAlign:'center',padding:'5%',color:tm}}>
      <style>{`
        @keyframes spin-hex{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes fadeUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;backdrop-filter:blur(8px);}
        .lb{padding:14px 32px;border-radius:12px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:15px;font-weight:700;cursor:pointer;box-shadow:0 4px 20px rgba(77,159,255,0.4);transition:all 0.3s;}
        .lb:hover{transform:translateY(-2px);}
      `}</style>
      {/* Animated Hexagon 404 */}
      <div style={{position:'relative',marginBottom:32,animation:'fadeUp 0.6s ease forwards'}}>
        <svg width={160} height={160} viewBox="0 0 64 64" style={{animation:'spin-hex 20s linear infinite'}}>
          <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+30*Math.cos(a)},${32+30*Math.sin(a)}`}).join(' ')} fill="none" stroke="rgba(77,159,255,0.3)" strokeWidth="1"/>
          <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+24*Math.cos(a)},${32+24*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/>
        </svg>
        <div style={{position:'absolute',top:'50%',left:'50%',transform:'translate(-50%,-50%)',fontFamily:'Playfair Display,serif',fontSize:40,fontWeight:800,color:'#4D9FFF'}}>404</div>
      </div>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(1.8rem,5vw,3rem)',fontWeight:800,marginBottom:12,animation:'fadeUp 0.6s 0.1s ease both',opacity:0}}>
        {lang==='en' ? 'Page Not Found' : 'पृष्ठ नहीं मिला'}
      </h1>
      <p style={{color:ts,fontSize:16,maxWidth:420,lineHeight:1.7,marginBottom:36,animation:'fadeUp 0.6s 0.2s ease both',opacity:0}}>
        {lang==='en'
          ? "The page you're looking for doesn't exist or has been moved."
          : 'आप जिस पृष्ठ को ढूंढ रहे हैं वह मौजूद नहीं है या हटा दिया गया है।'}
      </p>
      <div style={{display:'flex',gap:12,flexWrap:'wrap',justifyContent:'center',animation:'fadeUp 0.6s 0.3s ease both',opacity:0}}>
        <Link href="/"><button className="lb">{lang==='en'?'Go to Home →':'होम पर जाएं →'}</button></Link>
        <Link href="/dashboard"><button className="tbtn" style={{padding:'13px 24px',fontSize:15}}>{lang==='en'?'Dashboard':'डैशबोर्ड'}</button></Link>
      </div>
      {/* Footer brand */}
      <div style={{marginTop:60,display:'flex',alignItems:'center',gap:8,color:ts,fontSize:13}}>
        <svg width={20} height={20} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
        <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,color:'#4D9FFF'}}>ProveRank</span>
      </div>
      <div style={{marginTop:8,display:'flex',gap:8}}>
        <button className="tbtn" onClick={()=>{const n=lang==='en'?'hi':'en';setLang(n);localStorage.setItem('pr_lang',n)}}>{lang==='en'?'🇮🇳 हिंदी':'🌐 EN'}</button>
        <button className="tbtn" onClick={()=>{const n=!dark;setDark(n);localStorage.setItem('pr_theme',n?'dark':'light')}}>{dark?'☀️':'🌙'}</button>
      </div>
    </div>
  )
}
