'use client'
import { useState, useEffect } from 'react'
import DashLayout from '@/components/DashLayout'

const mockExams = [
  { id:1, name:'NEET Full Mock Test #13', date:'March 15, 2026', time:'10:00 AM – 1:20 PM', center:'Online (ProveRank Platform)', rollNo:'PR2026-00847', instructions:['Webcam required','Stable internet connection','Quiet environment','Valid ID ready'] },
  { id:2, name:'NEET Chapter Test — Biology', date:'March 18, 2026', time:'2:00 PM – 4:00 PM', center:'Online (ProveRank Platform)', rollNo:'PR2026-00848', instructions:['Webcam required','Stable internet connection'] },
]

export default function AdmitCard() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [selected, setSelected] = useState(0)
  const [mounted, setMounted] = useState(false)
  useEffect(()=>{ setMounted(true); const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl) },[])
  const dark = mounted ? localStorage.getItem('pr_theme')!=='light' : true

  const v = {
    card: dark ? 'rgba(0,18,36,0.9)' : 'rgba(255,255,255,0.95)',
    bord: dark ? 'rgba(77,159,255,0.14)' : 'rgba(77,159,255,0.25)',
    tm: dark ? '#E8F4FF' : '#0F172A',
    ts: dark ? '#6B8BAF' : '#64748B',
  }

  const ex = mockExams[selected]

  return (
    <DashLayout title={lang==='en'?'Admit Card':'प्रवेश पत्र'} subtitle={lang==='en'?'Download admit cards for upcoming exams':'आगामी परीक्षाओं के लिए प्रवेश पत्र'}>
      {/* Exam selector */}
      <div style={{display:'flex',gap:12,marginBottom:24,flexWrap:'wrap'}}>
        {mockExams.map((e,i)=>(
          <button key={e.id} onClick={()=>setSelected(i)} style={{padding:'10px 18px',borderRadius:12,border:`2px solid ${selected===i?'#4D9FFF':v.bord}`,background:selected===i?'rgba(77,159,255,0.1)':'transparent',color:selected===i?'#4D9FFF':v.ts,fontWeight:selected===i?700:500,fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>
            {e.name}
          </button>
        ))}
      </div>

      {/* Admit Card Preview */}
      <div style={{background:dark?'linear-gradient(135deg,#000A18,#001E3A,#000A18)':'linear-gradient(135deg,#EFF6FF,#DBEAFE)',border:`2px solid rgba(77,159,255,0.35)`,borderRadius:20,overflow:'hidden',marginBottom:20}}>
        {/* Header */}
        <div style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',padding:'20px 28px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <div style={{display:'flex',alignItems:'center',gap:12}}>
            <svg width={40} height={40} viewBox="0 0 64 64">
              <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+27*Math.cos(a)},${32+27*Math.sin(a)}`}).join(' ')} fill="none" stroke="rgba(255,255,255,0.8)" strokeWidth="2"/>
              <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="14" fontWeight="700" fill="white">PR</text>
            </svg>
            <div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:800,color:'#fff'}}>ProveRank</div>
              <div style={{fontSize:10,color:'rgba(255,255,255,0.7)',letterSpacing:'0.12em',textTransform:'uppercase'}}>{lang==='en'?'ADMIT CARD':'प्रवेश पत्र'}</div>
            </div>
          </div>
          <div style={{background:'rgba(255,255,255,0.15)',padding:'6px 16px',borderRadius:99,fontSize:12,fontWeight:700,color:'#fff',border:'1px solid rgba(255,255,255,0.3)'}}>{lang==='en'?'VALID':'मान्य'}</div>
        </div>

        {/* Body */}
        <div style={{padding:'28px'}}>
          {/* QR Code SVG */}
          <div style={{display:'flex',gap:28,flexWrap:'wrap'}}>
            <div style={{flex:'1 1 280px',display:'flex',flexDirection:'column',gap:16}}>
              {[
                [lang==='en'?'Exam Name':'परीक्षा नाम', ex.name],
                [lang==='en'?'Date':'तिथि', ex.date],
                [lang==='en'?'Time':'समय', ex.time],
                [lang==='en'?'Mode':'माध्यम', ex.center],
                [lang==='en'?'Roll Number':'रोल नंबर', ex.rollNo],
              ].map(([label,value])=>(
                <div key={label} style={{borderBottom:`1px solid ${v.bord}`,paddingBottom:12}}>
                  <div style={{fontSize:11,color:'#4D9FFF',fontWeight:700,letterSpacing:'0.06em',textTransform:'uppercase',marginBottom:4}}>{label}</div>
                  <div style={{fontWeight:600,fontSize:14,color:v.tm}}>{value}</div>
                </div>
              ))}
            </div>
            {/* QR Placeholder */}
            <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:12}}>
              <div style={{width:120,height:120,background:'rgba(77,159,255,0.08)',border:`2px solid rgba(77,159,255,0.3)`,borderRadius:12,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',gap:6}}>
                <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:3,padding:12}}>
                  {Array.from({length:25},(_,i)=>(
                    <div key={i} style={{width:8,height:8,background:[0,1,5,6,8,9,12,15,16,18,19,23,24].includes(i)?'#4D9FFF':'transparent',borderRadius:1}}/>
                  ))}
                </div>
              </div>
              <div style={{fontSize:10,color:v.ts,textAlign:'center'}}>Scan to verify</div>
            </div>
          </div>

          {/* Instructions */}
          <div style={{background:'rgba(255,165,2,0.06)',border:'1px solid rgba(255,165,2,0.2)',borderRadius:12,padding:'14px 18px',marginTop:20}}>
            <div style={{fontWeight:700,fontSize:13,color:'#FFA502',marginBottom:8}}>⚠️ {lang==='en'?'Instructions':'निर्देश'}</div>
            {ex.instructions.map((ins,i)=>(
              <div key={i} style={{fontSize:12,color:v.ts,marginBottom:4}}>• {ins}</div>
            ))}
          </div>
        </div>
      </div>

      <button style={{padding:'13px 30px',borderRadius:12,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:15,cursor:'pointer',fontFamily:'Inter,sans-serif',boxShadow:'0 4px 20px rgba(77,159,255,0.4)'}}>
        📥 {lang==='en'?'Download Admit Card':'प्रवेश पत्र डाउनलोड करें'}
      </button>
    </DashLayout>
  )
}
